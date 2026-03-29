# Backends

## Prerequisite

Create shared backend network

``` powershell
docker network create shared-db
docker network create shared-auth
docker network create shared-observability
docker network create --subnet 172.30.0.0/24 shared-redis
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

## Redis Cluster

:warning: dependency on backend observability containers (for OTel forwarding)

3-node Redis Cluster (primaries only, no replicas) for local development.

| image                                        | service name       | container's port(s) | published ports          |
|:--------------------------------------------:|:------------------:|:-------------------:|:------------------------:|
| redis:7-alpine                               | redis-node-1       | 6379 / 16379        | 6379:6379 / 16379:16379  |
| redis:7-alpine                               | redis-node-2       | 6379 / 16379        | 6380:6379 / 16380:16379  |
| redis:7-alpine                               | redis-node-3       | 6379 / 16379        | 6381:6379 / 16381:16379  |
| redis:7-alpine                               | redis-cluster-init | N/A                 | N/A                      |
| otel/opentelemetry-collector-contrib:latest   | otel-redis         | 13133               | N/A                      |

> **ℹ️ Note**: The `redis-cluster-init` service is a one-shot container that bootstraps the cluster
> using `redis-cli --cluster create` with `--cluster-replicas 0` (no secondaries).
> It exits automatically after initialization.

> **⚠️ Static IPs**: The cluster uses a dedicated `shared-redis` network with subnet `172.30.0.0/24`
> and fixed IPs (`172.30.0.11–13`) so that `redis-cli --cluster create` can reference stable addresses.

> **🔄 Idempotent init**: The `redis-cluster-init` container runs an external script
> (`volumes/redis/cluster-init.sh`) that checks if the cluster is already formed
> (`cluster_state:ok`) before running `redis-cli --cluster create`. This makes `docker compose down/up`
> and `--force-recreate` safe — the init container exits cleanly without errors on subsequent runs.

``` powershell
# Start Redis cluster
docker compose -f .\backends\docker-compose-backend-redis.yml -p backends-redis up -d

# Full reset (destroy cluster data and start fresh)
docker compose -f .\backends\docker-compose-backend-redis.yml -p backends-redis down -v
docker compose -f .\backends\docker-compose-backend-redis.yml -p backends-redis up -d
```

### Connecting to the cluster

``` powershell
# Verify cluster status
docker exec -it backends-redis-redis-node-1-1 redis-cli -c cluster info
docker exec -it backends-redis-redis-node-1-1 redis-cli -c cluster nodes

# Connect in cluster mode from host
redis-cli -c -p 6379
```

### Client configuration

When connecting from another Docker Compose project, join the `shared-redis` network and use the internal addresses:

```
redis-node-1:6379, redis-node-2:6379, redis-node-3:6379
```

When connecting from the host machine, use:

```
localhost:6379, localhost:6380, localhost:6381
```

### Redis OpenTelemetry Configuration

Source: <https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/redisreceiver/README.md>

Redis OSS does **not** natively export OpenTelemetry data. Observability is achieved through a
dedicated `otel-redis` collector that uses the built-in **`redis` receiver** from
`opentelemetry-collector-contrib`. This receiver connects directly to each Redis node
via the `INFO` command — **no external exporter sidecar needed**.

```
redis-node-1 ←─ INFO ─┐
redis-node-2 ←─ INFO ─┤── otel-redis (redis receiver ×3) ── OTLP ──→ otel-collector (shared)
redis-node-3 ←─ INFO ─┘                                                      ↓
                                                                       prometheus → grafana
```

| Concern     | Solution                                                                              |
|:-----------:|:-------------------------------------------------------------------------------------:|
| **Metrics** | `otel-redis` with `redis` receiver (one per node) → shared `otel-collector`           |
| **Traces**  | Client-side instrumentation (`opentelemetry-instrumentation-redis`)                    |
| **Logs**    | Redis writes to stdout, collected by Docker logging driver                            |

**Grafana dashboards** for Redis:
- **Provisioned**: `Redis Cluster — OpenTelemetry` (auto-loaded at startup via `volumes/grafana/provisioning/dashboards/redis-cluster.json`)
- [Redis Dashboard for Prometheus (ID 763)](https://grafana.com/grafana/dashboards/763)
- [Redis Cluster Overview (ID 11835)](https://grafana.com/grafana/dashboards/11835)

### Redis vs Redis Enterprise — Licence note

| Produit | Licence | Métriques Prometheus natives | Coût |
|---|---|---|---|
| **Redis ≤ 7.x** (ce qu'on utilise) | BSD 3-Clause | ❌ (besoin de `redis-exporter`) | Gratuit |
| **Redis 8.0+** | RSALv2 / SSPLv1 | ❌ (toujours besoin de `redis-exporter`) | Gratuit à l'usage, mais pas BSD |
| **Redis Enterprise Software** | Commercial | ✅ endpoint `/v2` natif | Payant |
| **Valkey 8+** (fork BSD) | BSD 3-Clause | ❌ (besoin de `redis-exporter`) | Gratuit |

> **ℹ️** Les docs Redis sur `redis.io/docs/latest/operate/rs/` (endpoint `/metrics`, `/v2`,
> dashboards intégrés) concernent **Redis Enterprise Software** (payant).
> Redis OSS (`redis:7-alpine`) ne dispose pas de ces fonctionnalités. C'est pourquoi
> nous utilisons `oliver006/redis_exporter` comme sidecar pour exposer les métriques.

> **💡 Alternative BSD** : Si la licence RSALv2 de Redis 8 pose problème, vous pouvez utiliser
> `valkey/valkey:8-alpine` (fork BSD maintenu par la Linux Foundation) en remplacement drop-in.

## Observability

:warning: dependency on backend database containers

| image                                       | service name   | container's port(s)           | published ports                            |
|:-------------------------------------------:|:--------------:|:-----------------------------:|:------------------------------------------:|
| grafana/tempo:latest                        | tempo          | 3200                          | 3200:3200                                  |
| grafana/loki:latest                         | loki           | 3100                          | 3100:3100                                  |
| prom/prometheus:latest                      | prometheus     | 9090                          | 9090:9090                                  |
| grafana/grafana:latest                      | grafana        | 3000                          | 3000:3000                                  |
| otel/opentelemetry-collector-contrib:latest | otel-collector | 13133<br />4317<br /> 4318    | 13133:13133<br />4317:4317<br /> 4318:4318 |


``` powershell
# Start backend databases
docker compose -f .\backends\docker-compose-backend-observability.yml -p backends-observability up -d
```

## Authentication

:warning: dependency on backend database containers and observability containers

| image                                       | service name | container's port(s)           | published ports                            |
|:-------------------------------------------:|:------------:|:-----------------------------:|:------------------------------------------:|
| quay.io/keycloak/keycloak:26.5.6            | keycloak     | 8080<br />8443<br />9000      | 8080:8080<br />8443:8443<br />9000:9000    |
| otel/opentelemetry-collector-contrib:latest | otel-keycloak | 13133<br />4317<br /> 4318   | N/A                                        |

``` powershell
# Start
docker compose -f .\backends\docker-compose-backend-keycloak.yml -p backends-auth up -d
```

### Keycloak OpenTelemetry Configuration

Source: <https://www.keycloak.org/observability/telemetry>

Keycloak uses a dedicated OTel collector (`otel-keycloak`) that forwards all telemetry to the shared `otel-collector`.

> **⚠️ Feature flags**: `opentelemetry-logs` and `opentelemetry-metrics` are Preview/Experimental
> features and must be explicitly enabled via `--features`.

``` yaml
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

#### Keycloak grafana dashboards

- <https://www.keycloak.org/observability/grafana-dashboards>
- <https://github.com/keycloak/keycloak-grafana-dashboard.git>

