"""
Pydantic schemas for TARS Backend API
"""
from pydantic import BaseModel
from typing import List, Optional


# System Information Schemas
class SystemInfo(BaseModel):
    hostname: str
    os: str
    uptime_seconds: int
    cpu_count: int
    total_memory_bytes: int
    kernel: str


class MemoryInfo(BaseModel):
    total: int
    used: int


class DiskInfo(BaseModel):
    total: int
    used: int


class SystemMetrics(BaseModel):
    cpu_percent: float
    memory: MemoryInfo
    disk: DiskInfo


# Process Management Schemas
class ProcessInfo(BaseModel):
    pid: int
    user: str
    cmd: str
    cpu_percent: float
    mem_bytes: int


class ProcessKillResponse(BaseModel):
    status: str
    message: str


# Docker Container Schemas
class ContainerInfo(BaseModel):
    id: str
    name: str
    image: str
    status: str


class ContainerStats(BaseModel):
    cpu_percent: float
    memory_bytes: int


# Power Management Schemas
class PowerAction(BaseModel):
    action: str  # "reboot" or "shutdown"


class PowerResponse(BaseModel):
    status: str
    message: str


# Error Response Schema
class ErrorResponse(BaseModel):
    status: str
    message: str
