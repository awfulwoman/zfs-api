# zfs-api

A read-only REST API for monitoring ZFS — pools, datasets, snapshots, and backups. Designed for homelab and small-fleet use, with built-in Prometheus metrics and an OpenAPI/Swagger UI.

## What it gives you

- Pool health, capacity, and fragmentation
- Dataset space usage and properties
- Snapshot listings
- Backup log inspection
- A `/metrics` endpoint scrapeable by Prometheus or VictoriaMetrics
- Interactive Swagger UI at `/api/docs`

All endpoints are **read-only**. The container cannot modify pools, datasets, or snapshots.

## Running it

The image is published as `ghcr.io/awfulwoman/zfs-api:latest` for `linux/amd64` and `linux/arm64`.

```yaml
# docker-compose.yaml
services:
  zfs-api:
    image: ghcr.io/awfulwoman/zfs-api:latest
    container_name: zfs-api
    restart: unless-stopped
    privileged: true                 # required for ZFS device access
    ports:
      - "8000:8000"
    volumes:
      - /dev/zfs:/dev/zfs:ro
```

`privileged: true` and mounting `/dev/zfs` are required — the container shells out to `zpool` and `zfs` commands, which need device access.

That's it. `docker compose up -d` and you're done. The API is now at `http://localhost:8000`.

## Example queries

```bash
# Pool health summary
curl -s http://localhost:8000/api/v1/pools | jq

# A specific pool
curl -s http://localhost:8000/api/v1/pools/tank | jq

# All datasets
curl -s http://localhost:8000/api/v1/datasets | jq

# Prometheus metrics
curl -s http://localhost:8000/metrics
```

Full endpoint reference is auto-rendered at `http://localhost:8000/api/docs`.

## Prometheus / VictoriaMetrics

Scrape `/metrics` for pool, dataset, and snapshot metrics:

```yaml
scrape_configs:
  - job_name: 'zfs'
    scrape_interval: 60s
    static_configs:
      - targets: ['zfs-host-1:8000', 'zfs-host-2:8000']
```

Exposed metrics include `zfs_pool_health`, `zfs_pool_capacity_percent`, `zfs_pool_fragmentation_percent`, `zfs_dataset_used_bytes`, and `zfs_snapshot_count`.

## Home Assistant

Use the REST sensor platform to surface pool health or compliance in your dashboard:

```yaml
sensor:
  - platform: rest
    name: "ZFS Storage Health"
    resource: http://zfs-host:8000/api/v1/pools/tank
    value_template: "{{ value_json.health }}"
    json_attributes:
      - capacity_percent
      - free_human
```

## Security

This API has **no built-in authentication**. Don't expose it directly to the public internet. Put it behind a reverse proxy with TLS + auth, or restrict it to a private network / VPN (Tailscale, WireGuard, etc.).

All operations are read-only, so the blast radius of a leaked endpoint is limited to information disclosure — but ZFS layout, capacity, and snapshot timing are still data you probably don't want strangers reading.

## License

MIT.
