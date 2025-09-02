"""
WebSocket API for real-time TARS communication
"""
import asyncio
import json
import logging
from typing import Dict, Set, Optional, Any
from fastapi import WebSocket, WebSocketDisconnect
from fastapi.routing import APIRouter
from src.utils.linux_utils import (
    get_processes,
    kill_process,
    get_docker_containers,
    get_container_logs as cli_get_container_logs,
    execute_container_action,
)
from src.models.schemas import ProcessInfo, ContainerInfo, ContainerStats
import docker
import threading
import time

logger = logging.getLogger(__name__)

router = APIRouter(tags=["WebSocket"])

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
        self.subscriptions: Dict[str, Set[str]] = {}  # connection_id -> set of subscribed topics
        self.background_tasks: Dict[str, asyncio.Task] = {}
        try:
            self.docker_client = docker.from_env()
            logger.info("Docker client initialized successfully")
        except Exception as e:
            logger.warning(f"Failed to initialize Docker client: {e}")
            self.docker_client = None
        
    async def connect(self, websocket: WebSocket, connection_id: str):
        await websocket.accept()
        self.active_connections[connection_id] = websocket
        self.subscriptions[connection_id] = set()
        logger.info(f"Client {connection_id} connected")
        
    def disconnect(self, connection_id: str):
        if connection_id in self.active_connections:
            del self.active_connections[connection_id]
        if connection_id in self.subscriptions:
            del self.subscriptions[connection_id]
        if connection_id in self.background_tasks:
            self.background_tasks[connection_id].cancel()
            del self.background_tasks[connection_id]
        logger.info(f"Client {connection_id} disconnected")
        
    async def send_personal_message(self, message: dict, connection_id: str):
        if connection_id in self.active_connections:
            try:
                await self.active_connections[connection_id].send_text(json.dumps(message))
            except Exception as e:
                logger.error(f"Error sending message to {connection_id}: {e}")
                self.disconnect(connection_id)
                
    async def subscribe(self, connection_id: str, topic: str):
        if connection_id in self.subscriptions:
            self.subscriptions[connection_id].add(topic)
            logger.info(f"Client {connection_id} subscribed to {topic}")
            
    async def unsubscribe(self, connection_id: str, topic: str):
        if connection_id in self.subscriptions:
            self.subscriptions[connection_id].discard(topic)
            logger.info(f"Client {connection_id} unsubscribed from {topic}")
            
    async def handle_container_action(self, connection_id: str, container_id: str, action: str):
        """Handle container actions in background using docker CLI"""
        try:
            # Notify start
            await self.send_personal_message({
                "type": "container_action_result",
                "container_id": container_id,
                "action": action,
                "status": "in_progress",
                "message": f"{action.capitalize()} requested..."
            }, connection_id)

            result_msg = execute_container_action(container_id, action)

            await self.send_personal_message({
                "type": "container_action_result",
                "container_id": container_id,
                "action": action,
                "status": "success",
                "message": result_msg
            }, connection_id)
        except Exception as e:
            await self.send_personal_message({
                "type": "container_action_result",
                "container_id": container_id,
                "action": action,
                "status": "error",
                "message": str(e)
            }, connection_id)
            
    async def stream_container_logs(self, connection_id: str, container_id: str, tail: int = 100, follow: bool = False):
        """Send container logs using docker CLI. Follow optional (best-effort)."""
        try:
            logs = cli_get_container_logs(container_id, tail)
            await self.send_personal_message({
                "type": "container_logs",
                "container_id": container_id,
                "logs": logs,
                "tail": tail,
                "follow": False
            }, connection_id)
        except Exception as e:
            await self.send_personal_message({
                "type": "container_logs_error",
                "container_id": container_id,
                "error": str(e)
            }, connection_id)

manager = ConnectionManager()

@router.get("/api/test")
async def test_websocket_router():
    """Test endpoint to verify router is working"""
    return {"message": "WebSocket router is working"}

@router.websocket("/api/ws/{connection_id}")
async def websocket_endpoint(websocket: WebSocket, connection_id: str):
    logger.info(f"WebSocket connection attempt from {connection_id}")
    try:
        await manager.connect(websocket, connection_id)
        logger.info(f"WebSocket connection established for {connection_id}")
    except Exception as e:
        logger.error(f"Failed to establish WebSocket connection for {connection_id}: {e}")
        return
    try:
        while True:
            data = await websocket.receive_text()
            message = json.loads(data)
            
            # Handle different message types
            message_type = message.get("type")
            
            if message_type == "subscribe":
                topic = message.get("topic")
                if topic:
                    await manager.subscribe(connection_id, topic)
                    
            elif message_type == "unsubscribe":
                topic = message.get("topic")
                if topic:
                    await manager.unsubscribe(connection_id, topic)
                    
            elif message_type == "get_system_info":
                try:
                    from src.utils.linux_utils import get_system_info
                    system_info = get_system_info()
                    await manager.send_personal_message({
                        "type": "system_info",
                        "data": system_info
                    }, connection_id)
                except Exception as e:
                    await manager.send_personal_message({
                        "type": "error",
                        "message": f"Failed to fetch system info: {str(e)}"
                    }, connection_id)
                    
            elif message_type == "get_metrics":
                try:
                    from src.utils.linux_utils import get_system_metrics
                    metrics = get_system_metrics()
                    await manager.send_personal_message({
                        "type": "metrics",
                        "data": metrics
                    }, connection_id)
                except Exception as e:
                    await manager.send_personal_message({
                        "type": "error",
                        "message": f"Failed to fetch metrics: {str(e)}"
                    }, connection_id)
                    
            elif message_type == "get_processes":
                try:
                    limit = message.get("limit", 20)
                    processes = get_processes(limit)
                    await manager.send_personal_message({
                        "type": "processes_data",
                        "data": processes
                    }, connection_id)
                except Exception as e:
                    await manager.send_personal_message({
                        "type": "error",
                        "message": f"Failed to fetch processes: {str(e)}"
                    }, connection_id)
                    
            elif message_type == "kill_process":
                try:
                    pid = message.get("pid")
                    success = kill_process(pid)
                    await manager.send_personal_message({
                        "type": "process_kill_result",
                        "pid": pid,
                        "success": success,
                        "message": f"Process {pid} {'killed' if success else 'failed to kill'}"
                    }, connection_id)
                except Exception as e:
                    await manager.send_personal_message({
                        "type": "error",
                        "message": f"Failed to kill process: {str(e)}"
                    }, connection_id)
                    
            elif message_type == "get_containers":
                try:
                    containers = get_docker_containers()
                    await manager.send_personal_message({
                        "type": "containers_data",
                        "data": containers
                    }, connection_id)
                except Exception as e:
                    logger.error(f"Error fetching containers: {e}")
                    await manager.send_personal_message({
                        "type": "error",
                        "message": f"Failed to fetch containers: {str(e)}"
                    }, connection_id)
                    
            elif message_type == "container_action":
                container_id = message.get("container_id")
                action = message.get("action")
                if container_id and action:
                    # Run container action in background via CLI
                    task = asyncio.create_task(
                        manager.handle_container_action(connection_id, container_id, action)
                    )
                    manager.background_tasks[connection_id] = task
                    
            elif message_type == "get_container_logs":
                container_id = message.get("container_id")
                tail = message.get("tail", 100)
                follow = message.get("follow", False)
                if container_id:
                    # Run log retrieval in background
                    task = asyncio.create_task(
                        manager.stream_container_logs(connection_id, container_id, tail, follow)
                    )
                    manager.background_tasks[connection_id] = task
                    
            elif message_type == "get_network_stats":
                try:
                    import psutil, platform, subprocess
                    net_io = psutil.net_io_counters()

                    process_network = {}

                    if platform.system().lower() == 'darwin':
                        # Use nettop for per-process bytes on macOS
                        try:
                            cmd = [
                                'nettop', '-J', 'bytes_in,bytes_out', '-P', '-x', '-l', '1'
                            ]
                            output = subprocess.check_output(cmd, text=True, timeout=3)
                            for line in output.splitlines():
                                parts = line.split(',')
                                if len(parts) >= 5:
                                    proc_name = parts[0]
                                    pid_str = parts[1]
                                    try:
                                        pid = int(pid_str)
                                    except:
                                        continue
                                    bytes_in = int(parts[-2]) if parts[-2].isdigit() else 0
                                    bytes_out = int(parts[-1]) if parts[-1].isdigit() else 0
                                    if pid not in process_network:
                                        process_network[pid] = {"connections": 0, "bytes_sent": 0, "bytes_recv": 0}
                                    process_network[pid]["bytes_recv"] += bytes_in
                                    process_network[pid]["bytes_sent"] += bytes_out
                        except Exception:
                            pass
                    else:
                        # Fallback: count connections only (Linux per-process bytes requires /proc parsing)
                        for conn in psutil.net_connections():
                            if conn.pid:
                                if conn.pid not in process_network:
                                    process_network[conn.pid] = {"connections": 0, "bytes_sent": 0, "bytes_recv": 0}
                                process_network[conn.pid]["connections"] += 1

                    await manager.send_personal_message({
                        "type": "network_stats",
                        "data": {
                            "total_bytes_sent": net_io.bytes_sent,
                            "total_bytes_recv": net_io.bytes_recv,
                            "process_network": process_network
                        }
                    }, connection_id)
                except Exception as e:
                    logger.error(f"Error fetching network stats: {e}")
                    await manager.send_personal_message({
                        "type": "error",
                        "message": f"Failed to fetch network stats: {str(e)}"
                    }, connection_id)
                    
    except WebSocketDisconnect:
        manager.disconnect(connection_id)
    except Exception as e:
        logger.error(f"WebSocket error for {connection_id}: {e}")
        manager.disconnect(connection_id)
