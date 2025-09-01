"""
Power Management API endpoints
"""
from fastapi import APIRouter, HTTPException
from src.models.schemas import PowerAction, PowerResponse
from src.utils.linux_utils import execute_power_action

router = APIRouter(prefix="/api/power", tags=["Power"])


@router.post("/power", response_model=PowerResponse)
async def execute_power_action_endpoint(action: PowerAction):
    """Execute power management actions"""
    try:
        message = execute_power_action(action.action)
        return PowerResponse(
            status="ok",
            message=message
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
