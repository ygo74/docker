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

