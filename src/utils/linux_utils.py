"""
Linux system utilities for TARS Backend
"""
import psutil
import platform
import subprocess
import os
import time
from typing import Dict, List, Tuple


def get_system_info() -> Dict:
    """Get basic system information"""
    try:
        # Get hostname
        hostname = platform.node()
        
        # Get OS info
        os_info = f"{platform.system()} {platform.release()}"
        
        # Get uptime - calculate seconds since boot
        uptime = int(time.time() - psutil.boot_time())
        
        # Get CPU count
        cpu_count = psutil.cpu_count()
        
        # Get total memory
        memory = psutil.virtual_memory()
        total_memory = memory.total
        
        # Get kernel version
        kernel = platform.release()
        
        return {
            "hostname": hostname,
            "os": os_info,
            "uptime_seconds": uptime,
            "cpu_count": cpu_count,
            "total_memory_bytes": total_memory,
            "kernel": kernel
        }
    except Exception as e:
        raise Exception(f"Failed to get system info: {str(e)}")


def get_system_metrics() -> Dict:
    """Get current system metrics"""
    try:
        # Get CPU usage - get average over 1 second
        cpu_percent = psutil.cpu_percent(interval=1)
        
        # Get memory usage - on macOS, we need to calculate differently
        memory = psutil.virtual_memory()
        
        # For macOS, calculate used memory more accurately
        if hasattr(memory, 'available'):
            # Use available memory to calculate used
            used_memory = memory.total - memory.available
        else:
            used_memory = memory.used
        
        # Get disk usage for root filesystem
        disk = psutil.disk_usage('/')
        
        return {
            "cpu_percent": cpu_percent,
            "memory": {
                "total": memory.total,
                "used": used_memory
            },
            "disk": {
                "total": disk.total,
                "used": disk.used
            }
        }
    except Exception as e:
        raise Exception(f"Failed to get system metrics: {str(e)}")


def get_processes(limit: int = 20) -> List[Dict]:
    """Get list of running processes with smart filtering"""
    try:
        all_processes = []
        # Get all processes with real data
        for proc in psutil.process_iter(['pid', 'username', 'name', 'cmdline', 'cpu_percent', 'memory_info']):
            try:
                proc_info = proc.info
                
                # Get command line or process name
                cmd = ' '.join(proc_info['cmdline']) if proc_info['cmdline'] else proc_info['name']
                
                # Get CPU and memory info
                cpu_percent = proc_info['cpu_percent'] or 0.0
                mem_bytes = proc_info['memory_info'].rss if proc_info['memory_info'] else 0
                
                all_processes.append({
                    "pid": proc_info['pid'],
                    "user": proc_info['username'] or 'unknown',
                    "cmd": cmd[:100] if cmd else 'unknown',  # Limit command length
                    "cpu_percent": cpu_percent,
                    "mem_bytes": mem_bytes
                })
                
                # Limit total processes to avoid hanging
                if len(all_processes) >= 2000:
                    break
                    
            except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                continue
            except Exception:
                continue
        
        # For default limit (20), return top 10 CPU + top 10 Memory
        if limit <= 20:
            # Sort by CPU usage (descending)
            cpu_sorted = sorted(all_processes, key=lambda x: x['cpu_percent'], reverse=True)
            # Sort by memory usage (descending)
            mem_sorted = sorted(all_processes, key=lambda x: x['mem_bytes'], reverse=True)
            
            # Get top 10 from each
            top_cpu = cpu_sorted[:10]
            top_mem = mem_sorted[:10]
            
            # Combine and remove duplicates (keep first occurrence)
            combined = []
            seen_pids = set()
            
            for proc in top_cpu + top_mem:
                if proc['pid'] not in seen_pids:
                    combined.append(proc)
                    seen_pids.add(proc['pid'])
                    if len(combined) >= limit:
                        break
            
            return combined
        else:
            # For higher limits, return top processes by CPU
            sorted_processes = sorted(all_processes, key=lambda x: x['cpu_percent'], reverse=True)
            return sorted_processes[:limit]
        
    except Exception as e:
        return []


def kill_process(pid: int) -> bool:
    """Kill a process by PID"""
    try:
        proc = psutil.Process(pid)
        proc.terminate()
        
        # Wait for process to terminate
        try:
            proc.wait(timeout=5)
        except psutil.TimeoutExpired:
            # Force kill if termination takes too long
            proc.kill()
        
        return True
    except psutil.NoSuchProcess:
        raise Exception("Process not found")
    except psutil.AccessDenied:
        raise Exception("Permission denied to kill process")
    except Exception as e:
        raise Exception(f"Failed to kill process: {str(e)}")


def get_docker_containers() -> List[Dict]:
    """Get list of Docker containers using docker command"""
    try:
        # Check if docker command exists
        try:
            subprocess.run(['docker', '--version'], capture_output=True, timeout=5)
        except (FileNotFoundError, subprocess.TimeoutExpired):
            # Return empty list if Docker is not available
            return []
        
        # Use docker ps command to get container info
        result = subprocess.run(
            ['docker', 'ps', '-a', '--format', '{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}'],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode != 0:
            # If Docker daemon is not running, return empty list
            if "Cannot connect to the Docker daemon" in result.stderr:
                return []
            raise Exception(f"Docker command failed: {result.stderr}")
        
        containers = []
        for line in result.stdout.strip().split('\n'):
            if line.strip():
                parts = line.split('\t')
                if len(parts) >= 4:
                    container_id = parts[0]
                    name = parts[1]
                    image = parts[2]
                    status = parts[3]
                    
                    # Determine if container is running
                    is_running = "Up" in status
                    status_text = "running" if is_running else "stopped"
                    
                    containers.append({
                        "id": container_id,
                        "name": name,
                        "image": image,
                        "status": status_text
                    })
        
        return containers
    except subprocess.TimeoutExpired:
        raise Exception("Docker command timed out")
    except Exception as e:
        # Return empty list on any error
        return []


def get_container_stats(container_id: str) -> Dict:
    """Get stats for a specific Docker container"""
    try:
        # Use docker stats command to get container stats
        result = subprocess.run(
            ['docker', 'stats', '--no-stream', '--format', '{{.CPUPerc}}\t{{.MemUsage}}'],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode != 0:
            raise Exception(f"Docker stats command failed: {result.stderr}")
        
        # Parse the output
        output = result.stdout.strip()
        if not output:
            raise Exception("No stats available for container")
        
        parts = output.split('\t')
        if len(parts) >= 2:
            cpu_percent = float(parts[0].replace('%', ''))
            mem_usage = parts[1]
            
            # Parse memory usage (e.g., "123.4MiB / 1.5GiB")
            mem_parts = mem_usage.split(' / ')
            if len(mem_parts) >= 1:
                mem_used = mem_parts[0]
                # Convert to bytes (simplified conversion)
                mem_bytes = int(float(mem_used.replace('MiB', '')) * 1024 * 1024)
            else:
                mem_bytes = 0
            
            return {
                "cpu_percent": cpu_percent,
                "memory_bytes": mem_bytes
            }
        
        raise Exception("Failed to parse container stats")
    except subprocess.TimeoutExpired:
        raise Exception("Docker stats command timed out")
    except FileNotFoundError:
        raise Exception("Docker command not found")
    except Exception as e:
        raise Exception(f"Failed to get container stats: {str(e)}")


def execute_power_action(action: str) -> str:
    """Execute power management actions"""
    try:
        if action not in ["reboot", "shutdown"]:
            raise Exception("Invalid power action")
        
        # First, stop all TARS containers gracefully
        print("Stopping all TARS containers...")
        try:
            tars_stop_result = subprocess.run(['/root/tars', 'stop', 'all'], capture_output=True, text=True, timeout=30)
            if tars_stop_result.returncode == 0:
                print("TARS containers stopped successfully")
            else:
                print(f"Warning: TARS stop command failed: {tars_stop_result.stderr}")
        except Exception as e:
            print(f"Warning: Could not stop TARS containers: {str(e)}")
        
        # Wait a moment for containers to stop gracefully
        import time
        time.sleep(3)
        
        if action == "reboot":
            # Schedule reboot in 10 seconds
            subprocess.run(['shutdown', '-r', '+0'], timeout=5)
            return "TARS containers stopped. System rebooting in 10 seconds"
        elif action == "shutdown":
            # Schedule shutdown in 10 seconds
            subprocess.run(['shutdown', '-h', '+0'], timeout=5)
            return "TARS containers stopped. System shutting down in 10 seconds"
    except subprocess.TimeoutExpired:
        raise Exception("Power command timed out")
    except FileNotFoundError:
        raise Exception("shutdown command not found")
    except Exception as e:
        raise Exception(f"Failed to execute power action: {str(e)}")


def get_docker_containers() -> List[Dict]:
    """Get detailed information about all Docker containers"""
    try:
        # Use docker ps to get container information
        result = subprocess.run(
            ['docker', 'ps', '-a', '--format', '{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode != 0:
            raise Exception(f"Docker ps command failed: {result.stderr}")
        
        containers = []
        lines = result.stdout.strip().split('\n')
        
        for line in lines:
            if line.strip():
                parts = line.split('\t')
                if len(parts) >= 4:
                    container_id = parts[0]
                    name = parts[1]
                    image = parts[2]
                    status = parts[3]
                    ports = parts[4] if len(parts) > 4 else ""
                    
                    # Determine health status
                    health_status = "unknown"
                    if "Up" in status:
                        if "healthy" in status:
                            health_status = "healthy"
                        elif "unhealthy" in status:
                            health_status = "unhealthy"
                        else:
                            health_status = "running"
                    elif "Exited" in status:
                        health_status = "stopped"
                    elif "Created" in status:
                        health_status = "created"
                    
                    containers.append({
                        "id": container_id,
                        "name": name,
                        "image": image,
                        "status": health_status,
                        "ports": ports,
                        "full_status": status
                    })
        
        return containers
    except subprocess.TimeoutExpired:
        raise Exception("Docker command timed out")
    except FileNotFoundError:
        raise Exception("Docker command not found")
    except Exception as e:
        raise Exception(f"Failed to get containers: {str(e)}")


def get_container_detailed_stats(container_id: str) -> Dict:
    """Get detailed stats for a specific Docker container"""
    try:
        # Get container stats
        stats_result = subprocess.run(
            ['docker', 'stats', '--no-stream', '--format', '{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}'],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if stats_result.returncode != 0:
            raise Exception(f"Docker stats command failed: {stats_result.stderr}")
        
        # Get container inspect for additional info
        inspect_result = subprocess.run(
            ['docker', 'inspect', container_id, '--format', '{{.State.Health.Status}}\t{{.Config.Env}}'],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        # Parse stats
        stats_output = stats_result.stdout.strip()
        health_status = "unknown"
        env_vars = []
        
        if inspect_result.returncode == 0:
            inspect_parts = inspect_result.stdout.strip().split('\t')
            if len(inspect_parts) >= 1:
                health_status = inspect_parts[0] if inspect_parts[0] else "unknown"
            if len(inspect_parts) >= 2:
                env_str = inspect_parts[1]
                if env_str and env_str != "<no value>":
                    env_vars = [env.split('=')[0] for env in env_str.split(' ') if '=' in env]
        
        if stats_output:
            parts = stats_output.split('\t')
            if len(parts) >= 3:
                cpu_percent = float(parts[0].replace('%', '')) if parts[0] != '--' else 0.0
                mem_usage = parts[1]
                mem_percent = float(parts[2].replace('%', '')) if parts[2] != '--' else 0.0
                
                # Parse memory usage
                mem_bytes = 0
                if mem_usage != '--':
                    mem_parts = mem_usage.split(' / ')
                    if len(mem_parts) >= 1:
                        mem_used = mem_parts[0]
                        # Convert to bytes
                        if 'MiB' in mem_used:
                            mem_bytes = int(float(mem_used.replace('MiB', '')) * 1024 * 1024)
                        elif 'GiB' in mem_used:
                            mem_bytes = int(float(mem_used.replace('GiB', '')) * 1024 * 1024 * 1024)
                        elif 'KiB' in mem_used:
                            mem_bytes = int(float(mem_used.replace('KiB', '')) * 1024)
                        else:
                            mem_bytes = int(float(mem_used.replace('B', '')))
                
                return {
                    "cpu_percent": cpu_percent,
                    "memory_bytes": mem_bytes,
                    "memory_percent": mem_percent,
                    "health_status": health_status,
                    "env_vars": env_vars[:5]  # Limit to first 5 env vars
                }
        
        return {
            "cpu_percent": 0.0,
            "memory_bytes": 0,
            "memory_percent": 0.0,
            "health_status": health_status,
            "env_vars": env_vars[:5]
        }
    except subprocess.TimeoutExpired:
        raise Exception("Docker command timed out")
    except FileNotFoundError:
        raise Exception("Docker command not found")
    except Exception as e:
        raise Exception(f"Failed to get container stats: {str(e)}")


def get_container_logs(container_id: str, tail: int = 100) -> str:
    """Get logs for a specific Docker container"""
    try:
        result = subprocess.run(
            ['docker', 'logs', '--tail', str(tail), container_id],
            capture_output=True,
            text=True,
            timeout=15
        )
        
        if result.returncode != 0:
            raise Exception(f"Docker logs command failed: {result.stderr}")
        
        return result.stdout
    except subprocess.TimeoutExpired:
        raise Exception("Docker logs command timed out")
    except FileNotFoundError:
        raise Exception("Docker command not found")
    except Exception as e:
        raise Exception(f"Failed to get container logs: {str(e)}")


def execute_container_action(container_id: str, action: str) -> str:
    """Execute actions on Docker containers (start, stop, restart)"""
    try:
        if action not in ["start", "stop", "restart"]:
            raise Exception("Invalid container action")
        
        result = subprocess.run(
            ['docker', action, container_id],
            capture_output=True,
            text=True,
            timeout=30
        )
        
        if result.returncode != 0:
            raise Exception(f"Docker {action} command failed: {result.stderr}")
        
        return f"Container {action}ed successfully"
    except subprocess.TimeoutExpired:
        raise Exception("Docker command timed out")
    except FileNotFoundError:
        raise Exception("Docker command not found")
    except Exception as e:
        raise Exception(f"Failed to {action} container: {str(e)}")


def get_tars_apps() -> List[Dict]:
    """Get all TARS applications and their status"""
    try:
        # Get the base directory (assuming this is run from the TARS root)
        base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        apps_dir = os.path.join(base_dir, "apps")
        
        if not os.path.exists(apps_dir):
            raise Exception("Apps directory not found")
        
        apps = []
        
        # Iterate through all directories in apps
        for item in os.listdir(apps_dir):
            app_dir = os.path.join(apps_dir, item)
            if os.path.isdir(app_dir):
                compose_file = os.path.join(app_dir, "docker-compose.yml")
                
                if os.path.exists(compose_file):
                    app_info = {
                        "name": item,
                        "status": "unknown",
                        "containers": [],
                        "running_containers": 0,
                        "total_containers": 0
                    }
                    
                    # Get container status using docker compose
                    try:
                        result = subprocess.run(
                            ['docker', 'compose', '-f', compose_file, 'ps', '--format', 'json'],
                            capture_output=True,
                            text=True,
                            timeout=10
                        )
                        
                        if result.returncode == 0 and result.stdout.strip():
                            containers = []
                            running_count = 0
                            
                            for line in result.stdout.strip().split('\n'):
                                if line.strip():
                                    try:
                                        container_data = json.loads(line)
                                        container_info = {
                                            "name": container_data.get("Name", ""),
                                            "status": container_data.get("State", ""),
                                            "ports": container_data.get("Ports", ""),
                                            "health": container_data.get("Health", "")
                                        }
                                        containers.append(container_info)
                                        
                                        if "Up" in container_info["status"]:
                                            running_count += 1
                                    except json.JSONDecodeError:
                                        continue
                            
                            app_info["containers"] = containers
                            app_info["running_containers"] = running_count
                            app_info["total_containers"] = len(containers)
                            
                            # Determine overall status
                            if running_count == 0:
                                app_info["status"] = "stopped"
                            elif running_count == len(containers):
                                app_info["status"] = "running"
                            else:
                                app_info["status"] = "partial"
                        else:
                            app_info["status"] = "stopped"
                            
                    except subprocess.TimeoutExpired:
                        app_info["status"] = "unknown"
                    except Exception:
                        app_info["status"] = "unknown"
                    
                    apps.append(app_info)
        
        return apps
    except Exception as e:
        raise Exception(f"Failed to get TARS apps: {str(e)}")


def execute_tars_app_action(app_name: str, action: str) -> str:
    """Execute actions on TARS applications using the tars script"""
    try:
        if action not in ["start", "stop", "restart"]:
            raise Exception("Invalid app action")
        
        # Get the base directory
        base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        tars_script = os.path.join(base_dir, "tars")
        
        if not os.path.exists(tars_script):
            raise Exception("TARS script not found")
        
        result = subprocess.run(
            [tars_script, action, app_name],
            capture_output=True,
            text=True,
            timeout=60
        )
        
        if result.returncode != 0:
            raise Exception(f"TARS {action} command failed: {result.stderr}")
        
        return f"Application {app_name} {action}ed successfully"
    except subprocess.TimeoutExpired:
        raise Exception("TARS command timed out")
    except FileNotFoundError:
        raise Exception("TARS script not found")
    except Exception as e:
        raise Exception(f"Failed to {action} application: {str(e)}")


def get_tars_app_health(app_name: str) -> Dict:
    """Get health status for a specific TARS application"""
    try:
        # Get the base directory
        base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        tars_script = os.path.join(base_dir, "tars")
        compose_file = os.path.join(base_dir, "apps", app_name, "docker-compose.yml")
        
        if not os.path.exists(tars_script):
            raise Exception("TARS script not found")
        
        if not os.path.exists(compose_file):
            raise Exception(f"Application {app_name} not found")
        
        # Get detailed health information
        health_info = {
            "app_name": app_name,
            "status": "unknown",
            "containers": [],
            "summary": {
                "total": 0,
                "running": 0,
                "stopped": 0,
                "healthy": 0,
                "unhealthy": 0
            }
        }
        
        # Get container status
        result = subprocess.run(
            ['docker', 'compose', '-f', compose_file, 'ps', '--format', 'json'],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode == 0 and result.stdout.strip():
            containers = []
            running_count = 0
            stopped_count = 0
            healthy_count = 0
            unhealthy_count = 0
            
            for line in result.stdout.strip().split('\n'):
                if line.strip():
                    try:
                        container_data = json.loads(line)
                        container_info = {
                            "name": container_data.get("Name", ""),
                            "status": container_data.get("State", ""),
                            "ports": container_data.get("Ports", ""),
                            "health": container_data.get("Health", ""),
                            "uptime": container_data.get("Uptime", "")
                        }
                        containers.append(container_info)
                        
                        if "Up" in container_info["status"]:
                            running_count += 1
                            if container_info["health"] == "healthy":
                                healthy_count += 1
                            elif container_info["health"] == "unhealthy":
                                unhealthy_count += 1
                        else:
                            stopped_count += 1
                            
                    except json.JSONDecodeError:
                        continue
            
            health_info["containers"] = containers
            health_info["summary"]["total"] = len(containers)
            health_info["summary"]["running"] = running_count
            health_info["summary"]["stopped"] = stopped_count
            health_info["summary"]["healthy"] = healthy_count
            health_info["summary"]["unhealthy"] = unhealthy_count
            
            # Determine overall status
            if running_count == 0:
                health_info["status"] = "stopped"
            elif running_count == len(containers) and unhealthy_count == 0:
                health_info["status"] = "healthy"
            elif unhealthy_count > 0:
                health_info["status"] = "unhealthy"
            else:
                health_info["status"] = "partial"
        
        return health_info
    except Exception as e:
        raise Exception(f"Failed to get app health: {str(e)}")
