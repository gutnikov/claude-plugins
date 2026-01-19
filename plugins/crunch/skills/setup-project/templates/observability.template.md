## Observability

**Platform**: {observability_platform}
**Dashboard**: {dashboard_url}

### Configuration

| Component | Tool | Endpoint |
|-----------|------|----------|
| Metrics | {metrics_tool} | {metrics_endpoint} |
| Logs | {logs_tool} | {logs_endpoint} |
| Traces | {traces_tool} | {traces_endpoint} |
| Alerts | {alerts_tool} | {alerts_endpoint} |

### Key Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `request.latency` | API response time | P95 > {latency_threshold} |
| `error.rate` | Error percentage | > {error_threshold}% |
| `cpu.usage` | CPU utilization | > {cpu_threshold}% |
| `memory.usage` | Memory utilization | > {memory_threshold}% |
| `request.rate` | Requests per second | Info only |

### Alerts

| Alert | Condition | Severity | Notify |
|-------|-----------|----------|--------|
| High latency | P50 > {threshold} for 5m | Warning | #{channel} |
| Error spike | Error rate > {threshold}% for 2m | Critical | PagerDuty |
| Service down | No heartbeat for 1m | Critical | PagerDuty |

### Dashboards

| Dashboard | URL | Description |
|-----------|-----|-------------|
| Overview | {overview_url} | Service health summary |
| Performance | {perf_url} | Latency and throughput |
| Errors | {errors_url} | Error analysis |

### Log Queries

```
# Find errors
{error_log_query}

# Trace request
{trace_log_query}

# Performance issues
{perf_log_query}
```

### Instrumentation

```{language}
{instrumentation_example}
```
