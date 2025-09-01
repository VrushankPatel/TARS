"""
Docker Container Management API endpoints
"""
from fastapi import APIRouter, HTTPException
from src.models.schemas import ContainerInfo, ContainerStats
from src.utils.linux_utils import get_container_stats
from typing import List

router = APIRouter(prefix="/api/containers", tags=["Containers"])


@router.get("/", response_model=List[ContainerInfo])
async def list_containers():
    """List Docker containers"""
    # Return sample data for now to avoid hanging
    return [
        ContainerInfo(
            id="a87ec4d5f2b1",
            name="tars-db",
            image="postgres:15",
            status="running"
        ),
        ContainerInfo(
            id="b23fd1c8e9a4",
            name="tars-redis",
            image="redis:7-alpine",
            status="running"
        )
    ]


@router.get("/{container_id}/stats", response_model=ContainerStats)
async def get_container_stats_by_id(container_id: str):
    """Get stats for a specific container"""
    try:
        stats = get_container_stats(container_id)
        return ContainerStats(**stats)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/test")
async def test_containers_endpoint():
    """Test endpoint"""
    return {"message": "Containers endpoint is working"}
