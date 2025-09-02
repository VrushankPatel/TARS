import { useState, useEffect, useMemo, useRef, useCallback } from 'react';
import { Moon, Sun, Server, Activity, HardDrive, Cpu, MemoryStick, Power, PowerOff, RotateCcw, Trash2, Play, Pause, Wifi, Download, Upload, Eye } from 'lucide-react';
import { useTheme } from './components/ui/theme-provider';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { useToast } from '@/hooks/use-toast';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Toaster } from '@/components/ui/sonner';
import { Textarea } from '@/components/ui/textarea';
import { Switch } from '@/components/ui/switch';
import { Label } from '@/components/ui/label';

interface SystemInfo {
  hostname: string;
  os: string;
  uptime_seconds: number;
  cpu_count: number;
  total_memory_bytes: number;
  kernel: string;
}

interface SystemMetrics {
  cpu_percent: number;
  memory: {
    total: number;
    used: number;
  };
  disk: {
    total: number;
    used: number;
  };
}

interface Process {
  pid: number;
  user: string;
  cmd: string;
  cpu_percent: number;
  mem_bytes: number;
}

interface Container {
  id: string;
  name: string;
  image: string;
  status: string;
  ports: any;
  created: string;
}

interface NetworkStats {
  total_bytes_sent: number;
  total_bytes_recv: number;
  process_network: Record<number, {
    connections: number;
    bytes_sent: number;
    bytes_recv: number;
  }>;
}

interface WebSocketMessage {
  type: string;
  data?: any;
  message?: string;
  container_id?: string;
  action?: string;
  status?: string;
  pid?: number;
  success?: boolean;
  logs?: string;
  log_line?: string;
  error?: string;
  tail?: number;
  follow?: boolean;
}

function App() {
  const { theme, setTheme } = useTheme();
  const { toast } = useToast();
  
  // WebSocket connection
  const wsRef = useRef<WebSocket | null>(null);
  const connectionId = useRef<string>(`client_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`);
  
  // State management
  const [systemInfo, setSystemInfo] = useState<SystemInfo | null>(null);
  const [metrics, setMetrics] = useState<SystemMetrics | null>(null);
  const [processes, setProcesses] = useState<Process[]>([]);
  const [containers, setContainers] = useState<Container[]>([]);
  const [networkStats, setNetworkStats] = useState<NetworkStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [processLimit, setProcessLimit] = useState(20);
  const [sortField, setSortField] = useState<'cpu_percent' | 'mem_bytes' | 'pid'>('cpu_percent');
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('desc');
  const [activeTab, setActiveTab] = useState('processes');
  const activeTabRef = useRef<string>('processes');
  const [selectedContainer, setSelectedContainer] = useState<string | null>(null);
  const [containerLogs, setContainerLogs] = useState<string>('');
  const [showLogsModal, setShowLogsModal] = useState(false);
  const [logsTail, setLogsTail] = useState(100);
  const [logsFollow, setLogsFollow] = useState(false);
  const [showFullLogs, setShowFullLogs] = useState(false);
  const [refreshingProcesses, setRefreshingProcesses] = useState(false);
  const [refreshingContainers, setRefreshingContainers] = useState(false);
  const [refreshingNetwork, setRefreshingNetwork] = useState(false);
  const [wsConnected, setWsConnected] = useState(false);
  const [pendingRequests, setPendingRequests] = useState<Set<string>>(new Set());
  const lastProcessUpdateRef = useRef<number>(0);
  const lastProcessFetchRef = useRef<number>(0);
  const lastNetworkFetchRef = useRef<number>(0);
  const networkInFlightRef = useRef<boolean>(false);

  const toggleTheme = () => {
    const newTheme = theme === 'dark' ? 'light' : 'dark';
    setTheme(newTheme);
  };

  // WebSocket connection management
  const connectWebSocket = useCallback(() => {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const wsUrl = `${protocol}//${window.location.host}/api/ws/${connectionId.current}`;
    
    wsRef.current = new WebSocket(wsUrl);
    
    wsRef.current.onopen = () => {
      setWsConnected(true);
      console.log('WebSocket connected');
      toast({
        title: "Connected",
        description: "Real-time connection established",
      });
    };
    
    wsRef.current.onmessage = (event) => {
      const message: WebSocketMessage = JSON.parse(event.data);
      handleWebSocketMessage(message);
    };
    
    wsRef.current.onclose = () => {
      setWsConnected(false);
      console.log('WebSocket disconnected');
      toast({
        title: "Disconnected",
        description: "Connection lost. Reconnecting...",
        variant: "destructive"
      });
      // Reconnect after 3 seconds
      setTimeout(connectWebSocket, 3000);
    };
    
    wsRef.current.onerror = (error) => {
      console.error('WebSocket error:', error);
      setWsConnected(false);
    };
  }, [toast]);

  const handleWebSocketMessage = useCallback((message: WebSocketMessage) => {
    switch (message.type) {
      case 'system_info':
        setSystemInfo(message.data);
        setLoading(false);
        break;
      case 'metrics':
        setMetrics(message.data);
        break;
      case 'processes_data':
        {
          // Ignore process updates if Processes tab is not active
          if (activeTabRef.current !== 'processes') {
            setPendingRequests(prev => {
              const newSet = new Set(prev);
              newSet.delete('processes');
              return newSet;
            });
            setRefreshingProcesses(false);
            return;
          }
          const now = Date.now();
          // Throttle UI updates to at most once every 0.9 seconds
          if (now - lastProcessUpdateRef.current < 900) {
            return;
          }
          lastProcessUpdateRef.current = now;
          setProcesses(message.data || []);
        }
        setRefreshingProcesses(false);
        setPendingRequests(prev => {
          const newSet = new Set(prev);
          newSet.delete('processes');
          return newSet;
        });
        break;
        
      case 'containers_data':
        setContainers(message.data || []);
        setRefreshingContainers(false);
        setPendingRequests(prev => {
          const newSet = new Set(prev);
          newSet.delete('containers');
          return newSet;
        });
        break;
        
      case 'network_stats':
        setNetworkStats(message.data);
        setRefreshingNetwork(false);
        networkInFlightRef.current = false;
        lastNetworkFetchRef.current = Date.now();
        setPendingRequests(prev => {
          const newSet = new Set(prev);
          newSet.delete('network');
          return newSet;
        });
        break;
        
      case 'container_action_result':
        toast({
          title: message.status === 'success' ? 'Success' : 'Error',
          description: message.message,
          variant: message.status === 'success' ? 'default' : 'destructive'
        });
        // Refresh containers after action
        if (message.status === 'success') {
          fetchContainers();
        }
        break;
        
      case 'container_logs':
        setContainerLogs(message.logs || '');
        setShowLogsModal(true);
        break;
        
      case 'container_logs_update':
        if (logsFollow) {
          setContainerLogs(prev => prev + '\n' + (message.log_line || ''));
        }
        break;
        
      case 'container_logs_error':
        toast({
          title: "Error",
          description: message.error || 'Failed to fetch logs',
          variant: "destructive"
        });
        break;
        
      case 'process_kill_result':
        toast({
          title: message.success ? 'Success' : 'Error',
          description: message.message,
          variant: message.success ? 'default' : 'destructive'
        });
        if (message.success) {
          fetchProcesses();
        }
        break;
        
      case 'error':
        toast({
          title: "Error",
          description: message.message,
          variant: "destructive"
        });
        break;
    }
  }, [toast, logsFollow]);

  const sendWebSocketMessage = useCallback((message: any) => {
    if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify(message));
    }
  }, []);

  // Data fetching functions
  const fetchSystemInfo = useCallback(() => {
    sendWebSocketMessage({
      type: 'get_system_info'
    });
  }, [sendWebSocketMessage]);

  const fetchMetrics = useCallback(() => {
    sendWebSocketMessage({
      type: 'get_metrics'
    });
  }, [sendWebSocketMessage]);

  const fetchProcesses = useCallback(() => {
    // Do not request when not on the processes tab
    if (activeTabRef.current !== 'processes') return;
    if (pendingRequests.has('processes')) return;
    // Debounce fetch to at most once every 0.9 seconds
    const now = Date.now();
    if (now - lastProcessFetchRef.current < 900) {
      return;
    }
    lastProcessFetchRef.current = now;

    setRefreshingProcesses(true);
    setPendingRequests(prev => new Set(prev).add('processes'));
    sendWebSocketMessage({
      type: 'get_processes',
      limit: processLimit
    });
  }, [processLimit, pendingRequests, sendWebSocketMessage]);

  const fetchContainers = useCallback(() => {
    if (pendingRequests.has('containers')) return;
    
    setRefreshingContainers(true);
    setPendingRequests(prev => new Set(prev).add('containers'));
    sendWebSocketMessage({
      type: 'get_containers'
    });
  }, [pendingRequests, sendWebSocketMessage]);

  const fetchNetworkStats = useCallback(() => {
    // Enforce at most one request per second
    const now = Date.now();
    if (now - lastNetworkFetchRef.current < 1000) return;
    if (networkInFlightRef.current) return;
    networkInFlightRef.current = true;

    setRefreshingNetwork(true);
    setPendingRequests(prev => new Set(prev).add('network'));
    sendWebSocketMessage({ type: 'get_network_stats' });
  }, [sendWebSocketMessage]);

  const fetchContainerLogs = useCallback((containerId: string) => {
    setSelectedContainer(containerId);
    setShowLogsModal(true);
    setContainerLogs('Loading logs...');
    sendWebSocketMessage({
      type: 'get_container_logs',
      container_id: containerId,
      tail: logsTail,
      follow: logsFollow
    });
  }, [logsTail, logsFollow, sendWebSocketMessage]);

  const executeContainerAction = useCallback((containerId: string, action: string) => {
    sendWebSocketMessage({
      type: 'container_action',
      container_id: containerId,
      action: action
    });
  }, [sendWebSocketMessage]);

  const killProcess = useCallback((pid: number) => {
    sendWebSocketMessage({
      type: 'kill_process',
      pid: pid
    });
  }, [sendWebSocketMessage]);

  const systemPowerAction = async (action: 'shutdown' | 'reboot') => {
    try {
      const response = await fetch('/api/power/power', { 
        method: 'POST', 
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action }) 
      });
      if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
      const result = await response.json();
      toast({
        title: "System Action",
        description: result.message || `System ${action} initiated`,
        variant: action === 'shutdown' ? 'destructive' : 'default'
      });
    } catch (error) {
      toast({
        title: "Error",
        description: `Failed to ${action} system`,
        variant: "destructive"
      });
    }
  };

  // Sort processes based on current sort field and direction
  const sortedProcesses = useMemo(() => {
    return [...processes].sort((a, b) => {
      const aValue = a[sortField];
      const bValue = b[sortField];
      
      if (sortDirection === 'asc') {
        return aValue > bValue ? 1 : -1;
      } else {
        return aValue < bValue ? 1 : -1;
      }
    });
  }, [processes, sortField, sortDirection]);

  // Handle column sorting
  const handleSort = (field: 'cpu_percent' | 'mem_bytes' | 'pid') => {
    if (sortField === field) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortDirection('desc');
    }
  };

  // Utility functions
  const formatBytes = (bytes: number) => {
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    if (bytes === 0) return '0 B';
    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
  };

  const formatUptime = (seconds: number) => {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return `${days}d ${hours}h ${minutes}m`;
  };

  const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
      case 'running': return 'bg-green-500';
      case 'stopped': return 'bg-red-500';
      case 'paused': return 'bg-yellow-500';
      default: return 'bg-gray-500';
    }
  };

  // Effects - Fixed to prevent infinite re-renders
  useEffect(() => {
    connectWebSocket();
    return () => {
      if (wsRef.current) {
        wsRef.current.close();
      }
    };
  }, []); // Only run once on mount

  useEffect(() => {
    activeTabRef.current = activeTab;
  }, [activeTab]);

  useEffect(() => {
    if (wsConnected) {
      // Load initial data when WebSocket connects
      fetchSystemInfo();
      fetchMetrics();
    }
  }, [wsConnected, fetchSystemInfo, fetchMetrics]);

  useEffect(() => {
    if (!wsConnected) return;

    const intervalMs = activeTab === 'processes' ? 1000 : 5000;
    const interval = setInterval(() => {
      if (activeTab === 'processes') {
        fetchProcesses();
      } else if (activeTab === 'containers') {
        fetchContainers();
      } else if (activeTab === 'network') {
        fetchNetworkStats();
      }
      // Refresh metrics on each tick as well
      fetchMetrics();
    }, intervalMs);

    return () => clearInterval(interval);
  }, [wsConnected, activeTab, fetchMetrics, fetchProcesses, fetchContainers, fetchNetworkStats]);

  useEffect(() => {
    // When tab changes, immediately fetch data for that tab
    if (!wsConnected) return;
    
    if (activeTab === 'processes') {
      fetchProcesses();
    } else if (activeTab === 'containers') {
      fetchContainers();
    } else if (activeTab === 'network') {
      fetchNetworkStats();
    }
  }, [activeTab, wsConnected, fetchProcesses, fetchContainers, fetchNetworkStats]);

  // Refetch processes when limit changes while on processes tab
  useEffect(() => {
    if (!wsConnected) return;
    if (activeTab !== 'processes') return;
    fetchProcesses();
  }, [processLimit, activeTab, wsConnected, fetchProcesses]);

  if (loading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="flex flex-col items-center space-y-4">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
          <p className="text-muted-foreground">Loading TARS...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background transition-colors duration-300">
      <Toaster />
      
      {/* Header */}
      <header className="border-b bg-card/50 backdrop-blur supports-[backdrop-filter]:bg-card/50">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="p-2 bg-primary rounded-lg">
                <Server className="h-6 w-6 text-primary-foreground" />
              </div>
              <div>
                <h1 className="text-xl font-bold">TARS</h1>
                <p className="text-sm text-muted-foreground">Tooling and Application Runtime System</p>
              </div>
            </div>
            
            <div className="flex items-center space-x-2">
              <Badge variant={wsConnected ? "default" : "destructive"}>
                {wsConnected ? "Connected" : "Disconnected"}
              </Badge>
              
              <Button
                variant="outline"
                size="icon"
                onClick={toggleTheme}
                className="transition-all duration-200 w-12 h-12"
              >
                {theme === 'dark' ? <Moon className="h-6 w-6" /> : <Sun className="h-6 w-6" />}
              </Button>
            </div>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-6 space-y-6">
        {/* System Info Banner */}
        {systemInfo && (
          <Alert className="bg-card border transition-colors duration-200">
            <Server className="h-4 w-4" />
            <AlertDescription className="flex flex-wrap items-center gap-4 text-sm">
              <span><strong>{systemInfo.hostname}</strong></span>
              <span>{systemInfo.os}</span>
              <span>Kernel: {systemInfo.kernel}</span>
              <span>CPUs: {systemInfo.cpu_count}</span>
              <span>Uptime: {formatUptime(systemInfo.uptime_seconds)}</span>
            </AlertDescription>
          </Alert>
        )}

        {/* Metrics Cards */}
        {metrics && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">CPU Usage</CardTitle>
                <Cpu className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{metrics.cpu_percent.toFixed(1)}%</div>
                <Progress value={metrics.cpu_percent} className="mt-2" />
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Memory Usage</CardTitle>
                <MemoryStick className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {formatBytes(metrics.memory.used)} / {formatBytes(metrics.memory.total)}
                </div>
                <Progress 
                  value={(metrics.memory.used / metrics.memory.total) * 100} 
                  className="mt-2" 
                />
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Disk Usage</CardTitle>
                <HardDrive className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {formatBytes(metrics.disk.used)} / {formatBytes(metrics.disk.total)}
                </div>
                <Progress 
                  value={(metrics.disk.used / metrics.disk.total) * 100} 
                  className="mt-2" 
                />
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Network</CardTitle>
                <Wifi className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-sm space-y-1">
                  <div className="flex items-center gap-2">
                    <Upload className="h-3 w-3" />
                    <span>{networkStats ? formatBytes(networkStats.total_bytes_sent) : '0 B'}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Download className="h-3 w-3" />
                    <span>{networkStats ? formatBytes(networkStats.total_bytes_recv) : '0 B'}</span>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        )}

        {/* Power Controls */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Power className="h-5 w-5" />
              System Controls
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex gap-2">
              <Button
                variant="outline"
                onClick={() => systemPowerAction('reboot')}
                className="flex items-center gap-2"
              >
                <RotateCcw className="h-4 w-4" />
                Reboot
              </Button>
              <Button
                variant="destructive"
                onClick={() => systemPowerAction('shutdown')}
                className="flex items-center gap-2"
              >
                <PowerOff className="h-4 w-4" />
                Shutdown
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Main Content Tabs */}
        <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-4">
          <TabsList className="grid w-full grid-cols-4">
            <TabsTrigger value="processes" className="flex items-center gap-2">
              <Activity className="h-4 w-4" />
              Processes
            </TabsTrigger>
            <TabsTrigger value="containers" className="flex items-center gap-2">
              <Server className="h-4 w-4" />
              Containers
            </TabsTrigger>
            <TabsTrigger value="apps" className="flex items-center gap-2">
              <Cpu className="h-4 w-4" />
              Apps
            </TabsTrigger>
            <TabsTrigger value="network" className="flex items-center gap-2">
              <Wifi className="h-4 w-4" />
              Network
            </TabsTrigger>
          </TabsList>

          {/* Processes Tab */}
          <TabsContent value="processes" className="space-y-4">
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle>Running Processes</CardTitle>
                  <div className="flex items-center gap-2">
                    <Select value={processLimit.toString()} onValueChange={(value) => setProcessLimit(parseInt(value))}>
                      <SelectTrigger className="w-32">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="10">10</SelectItem>
                        <SelectItem value="20">20</SelectItem>
                        <SelectItem value="50">50</SelectItem>
                        <SelectItem value="100">100</SelectItem>
                      </SelectContent>
                    </Select>
                    <Button
                      variant="outline"
                      size="icon"
                      onClick={fetchProcesses}
                      disabled={refreshingProcesses}
                    >
                      <RotateCcw className={`h-4 w-4 ${refreshingProcesses ? 'animate-spin' : ''}`} />
                    </Button>
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead 
                        className="cursor-pointer"
                        onClick={() => handleSort('pid')}
                      >
                        PID {sortField === 'pid' && (sortDirection === 'asc' ? '↑' : '↓')}
                      </TableHead>
                      <TableHead>User</TableHead>
                      <TableHead>Command</TableHead>
                      <TableHead 
                        className="cursor-pointer"
                        onClick={() => handleSort('cpu_percent')}
                      >
                        CPU % {sortField === 'cpu_percent' && (sortDirection === 'asc' ? '↑' : '↓')}
                      </TableHead>
                      <TableHead 
                        className="cursor-pointer"
                        onClick={() => handleSort('mem_bytes')}
                      >
                        Memory {sortField === 'mem_bytes' && (sortDirection === 'asc' ? '↑' : '↓')}
                      </TableHead>
                      <TableHead>Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {sortedProcesses.map((process) => (
                      <TableRow key={process.pid}>
                        <TableCell className="font-mono">{process.pid}</TableCell>
                        <TableCell>{process.user}</TableCell>
                        <TableCell className="max-w-xs truncate">{process.cmd}</TableCell>
                        <TableCell>{process.cpu_percent.toFixed(1)}%</TableCell>
                        <TableCell>{formatBytes(process.mem_bytes)}</TableCell>
                        <TableCell>
                          <Button
                            variant="destructive"
                            size="sm"
                            onClick={() => killProcess(process.pid)}
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          </TabsContent>

          {/* Containers Tab */}
          <TabsContent value="containers" className="space-y-4">
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle>Docker Containers</CardTitle>
                  <Button
                    variant="outline"
                    size="icon"
                    onClick={fetchContainers}
                    disabled={refreshingContainers}
                  >
                    <RotateCcw className={`h-4 w-4 ${refreshingContainers ? 'animate-spin' : ''}`} />
                  </Button>
                </div>
              </CardHeader>
              <CardContent>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Name</TableHead>
                      <TableHead>Image</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Ports</TableHead>
                      <TableHead>Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {containers.map((container) => (
                      <TableRow key={container.id}>
                        <TableCell className="font-medium">{container.name}</TableCell>
                        <TableCell className="max-w-xs truncate">{container.image}</TableCell>
                        <TableCell>
                          <Badge className={getStatusColor(container.status)}>
                            {container.status}
                          </Badge>
                        </TableCell>
                        <TableCell className="max-w-xs truncate">
                          {container.ports ? JSON.stringify(container.ports) : 'N/A'}
                        </TableCell>
                        <TableCell>
                          <div className="flex gap-2">
                            {container.status === 'running' ? (
                              <>
                                <Button
                                  variant="outline"
                                  size="sm"
                                  onClick={() => executeContainerAction(container.id, 'stop')}
                                >
                                  <Pause className="h-4 w-4" />
                                </Button>
                                <Button
                                  variant="outline"
                                  size="sm"
                                  onClick={() => executeContainerAction(container.id, 'restart')}
                                >
                                  <RotateCcw className="h-4 w-4" />
                                </Button>
                              </>
                            ) : (
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={() => executeContainerAction(container.id, 'start')}
                              >
                                <Play className="h-4 w-4" />
                              </Button>
                            )}
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => fetchContainerLogs(container.id)}
                            >
                              <Eye className="h-4 w-4" />
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          </TabsContent>

          {/* Apps Tab */}
          <TabsContent value="apps" className="space-y-4">
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle>TARS Applications</CardTitle>
                </div>
              </CardHeader>
              <CardContent>
                <div className="text-center text-muted-foreground py-8">
                  <Cpu className="h-12 w-12 mx-auto mb-4 opacity-50" />
                  <p>Apps management coming soon...</p>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          {/* Network Tab */}
          <TabsContent value="network" className="space-y-4">
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle>Network Statistics</CardTitle>
                  <Button
                    variant="outline"
                    size="icon"
                    onClick={fetchNetworkStats}
                    disabled={refreshingNetwork}
                  >
                    <RotateCcw className={`h-4 w-4 ${refreshingNetwork ? 'animate-spin' : ''}`} />
                  </Button>
                </div>
              </CardHeader>
              <CardContent>
                {networkStats ? (
                  <div className="space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                      <Card>
                        <CardHeader>
                          <CardTitle className="text-sm">Total Data Sent</CardTitle>
                        </CardHeader>
                        <CardContent>
                          <div className="text-2xl font-bold text-green-600">
                            {formatBytes(networkStats.total_bytes_sent)}
                          </div>
                        </CardContent>
                      </Card>
                      <Card>
                        <CardHeader>
                          <CardTitle className="text-sm">Total Data Received</CardTitle>
                        </CardHeader>
                        <CardContent>
                          <div className="text-2xl font-bold text-blue-600">
                            {formatBytes(networkStats.total_bytes_recv)}
                          </div>
                        </CardContent>
                      </Card>
                    </div>
                    
                    <div>
                      <h3 className="text-lg font-semibold mb-4">Process Network Usage</h3>
                      <Table>
                        <TableHeader>
                          <TableRow>
                            <TableHead>PID</TableHead>
                            <TableHead>Connections</TableHead>
                            <TableHead>Data Sent</TableHead>
                            <TableHead>Data Received</TableHead>
                          </TableRow>
                        </TableHeader>
                        <TableBody>
                          {Object.entries(networkStats.process_network).map(([pid, stats]) => (
                            <TableRow key={pid}>
                              <TableCell className="font-mono">{pid}</TableCell>
                              <TableCell>{stats.connections}</TableCell>
                              <TableCell>{formatBytes(stats.bytes_sent)}</TableCell>
                              <TableCell>{formatBytes(stats.bytes_recv)}</TableCell>
                            </TableRow>
                          ))}
                        </TableBody>
                      </Table>
                    </div>
                  </div>
                ) : (
                  <div className="text-center text-muted-foreground py-8">
                    <Wifi className="h-12 w-12 mx-auto mb-4 opacity-50" />
                    <p>No network data available</p>
                  </div>
                )}
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </main>

      {/* Container Logs Modal */}
      <Dialog open={showLogsModal} onOpenChange={setShowLogsModal}>
        <DialogContent className="max-w-4xl max-h-[80vh]">
          <DialogHeader>
            <DialogTitle className="flex items-center justify-between">
              <span>Container Logs - {selectedContainer}</span>
              <div className="flex items-center gap-4">
                <div className="flex items-center gap-2">
                  <Label htmlFor="logs-tail">Tail:</Label>
                  <Select value={logsTail.toString()} onValueChange={(value) => setLogsTail(parseInt(value))}>
                    <SelectTrigger className="w-20">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="50">50</SelectItem>
                      <SelectItem value="100">100</SelectItem>
                      <SelectItem value="500">500</SelectItem>
                      <SelectItem value="1000">1000</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="flex items-center gap-2">
                  <Switch
                    id="logs-follow"
                    checked={logsFollow}
                    onCheckedChange={setLogsFollow}
                  />
                  <Label htmlFor="logs-follow">Follow</Label>
                </div>
                <div className="flex items-center gap-2">
                  <Switch
                    id="show-full-logs"
                    checked={showFullLogs}
                    onCheckedChange={setShowFullLogs}
                  />
                  <Label htmlFor="show-full-logs">Full Logs</Label>
                </div>
              </div>
            </DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <Textarea
              value={showFullLogs ? containerLogs : containerLogs.split('\n').slice(-logsTail).join('\n')}
              readOnly
              className="font-mono text-sm h-96"
              placeholder="No logs available..."
            />
            <div className="flex justify-end gap-2">
              <Button
                variant="outline"
                onClick={() => {
                  setContainerLogs('');
                  setShowLogsModal(false);
                }}
              >
                Close
              </Button>
              <Button
                onClick={() => selectedContainer && fetchContainerLogs(selectedContainer)}
              >
                Refresh
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}

export default App;