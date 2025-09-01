"""
System Information API endpoints
"""
from fastapi import APIRouter, HTTPException
from src.models.schemas import SystemInfo, SystemMetrics
from src.utils.linux_utils import get_system_info, get_system_metrics

router = APIRouter(prefix="/api/system", tags=["System"])


@router.get("/info", response_model=SystemInfo)
async def get_system_info_endpoint():
    """Get basic system information"""
    try:
        info = get_system_info()
        return SystemInfo(**info)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/metrics", response_model=SystemMetrics)
async def get_system_metrics_endpoint():
    """Get current system metrics"""
    try:
        metrics = get_system_metrics()
        return SystemMetrics(**metrics)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
