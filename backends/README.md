# Backends

## Prerequisite

Create shared backend network

``` powershell
docker network create shared-db
docker network create shared-auth
docker network create shared-observability

```

## Database

| image                 | service name | container's port(s) | published ports |
|:---------------------:|:------------:|:-------------------:|:---------------:|
| postgres:16           | postgres     | 5432                | 5431:5432       |
| dpage/pgadmin4:9.13.0 | pgadmin      | 80                  | 5050:80         |

``` powershell
# Start backend databases
docker compose -f .\backends\docker-compose-backend-database.yml -p backends-database up -d

```

## Observability

:warning: dependency on backend database containers

| image                                       | service name | container's port(s)           | published ports                            |
|:-------------------------------------------:|:------------:|:-----------------------------:|:------------------------------------------:|
| grafana/tempo:latest                        | tempo        | 3200                          | 3200:3200                                  |
| grafana/loki:latest                         | loki         | 3100                          | 3100:3100                                  |
| prom/prometheus:latest                      | prometheus   | 9090                          | 9090:9090                                  |
| grafana/grafana:latest                      | grafana      | 3000                          | 3000:3000                                  |
| otel/opentelemetry-collector-contrib:latest | otel-collector | 13133<br />4317<br /> 4318  | 13133:13133<br />4317:4317<br /> 4318:4318 |


``` powershell
# Start backend databases
docker compose -f .\backends\docker-compose-backend-observability.yml -p backends-observability up
```

## Authentication

### Keycloak OpenTelemetry Configuration

Keycloak uses a dedicated OTel collector (`otel-keycloak`) that forwards all telemetry to the shared `otel-collector`.

#### Required Keycloak startup options

```
KC_FEATURES=opentelemetry,opentelemetry-logs,opentelemetry-metrics

# Global OTel endpoint (shared by traces, logs, metrics)
KC_TELEMETRY_ENDPOINT=http://otel-keycloak:4317
KC_TELEMETRY_SERVICE_NAME=keycloak
KC_TELEMETRY_PROTOCOL=grpc

# Tracing
KC_TRACING_ENABLED=true

# Logs — CRITICAL: --log must include "opentelemetry" handler
KC_LOG=console,opentelemetry
KC_TELEMETRY_LOGS_ENABLED=true
KC_TELEMETRY_LOGS_LEVEL=info

# Metrics
KC_METRICS_ENABLED=true
KC_TELEMETRY_METRICS_ENABLED=true
```

> **⚠️ Common pitfall**: Setting `telemetry-logs-enabled=true` alone is NOT enough.
> You **must** also add `opentelemetry` to the `--log` handlers:
> `--log=console` (or env `KC_LOG=console`).
> Without this, Keycloak never attaches the OTel log appender and no logs are exported.

> **⚠️ Feature flags**: `opentelemetry-logs` and `opentelemetry-metrics` are Preview/Experimental
> features and must be explicitly enabled via `--features`.

#### Docker Compose environment example

```yaml
environment:
  # Enable OTel features (logs = preview, metrics = experimental)
  KC_FEATURES: "opentelemetry,opentelemetry-logs,opentelemetry-metrics"

  # Log handlers — MUST include "opentelemetry" for OTel log export
  KC_LOG: "console"
  KC_LOG_LEVEL: "info"

  # Global OTel settings
  KC_TELEMETRY_ENDPOINT: "http://otel-keycloak:4317"
  KC_TELEMETRY_SERVICE_NAME: "keycloak"
  KC_TELEMETRY_PROTOCOL: "grpc"

  # Tracing
  KC_TRACING_ENABLED: "true"

  # Logs
  KC_TELEMETRY_LOGS_ENABLED: "true"
  KC_TELEMETRY_LOGS_LEVEL: "info"

  # Metrics (also requires metrics-enabled)
  KC_METRICS_ENABLED: "true"
  KC_TELEMETRY_METRICS_ENABLED: "true"
```

#### Verification checklist

| Check | How to verify |
|:------|:--------------|
| Features enabled | Container logs show `opentelemetry-logs` in enabled features list |
| Log handler active | `KC_LOG` contains `opentelemetry` |
| OTel endpoint reachable | `otel-keycloak:4317` is accessible from Keycloak container |
| Logs arriving at collector | `otel-keycloak` debug exporter shows log records |

#### References

- https://www.keycloak.org/observability/telemetry
- https://www.keycloak.org/observability/grafana-dashboards
- https://github.com/keycloak/keycloak-grafana-dashboard.git
