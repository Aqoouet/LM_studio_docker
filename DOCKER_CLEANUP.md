# Docker Disk Cleanup Guide

This guide helps you free Docker disk space safely and understand what each command deletes.

## Quick diagnostics

Check overall Docker usage:

```bash
docker system df
```

Detailed per-image, per-volume, and build cache usage:

```bash
docker system df -v
```

## Safe cleanup order

Start from least risky to most risky.

### 1) Remove dangling images

Deletes untagged images (`<none>:<none>`) not used by containers.

```bash
docker image prune
```

### 2) Remove stopped containers

Deletes only stopped/created containers.

```bash
docker container prune
```

### 3) Clean build cache

Removes unused build cache (recreated automatically during future builds).

```bash
docker builder prune
```

More aggressive build cache cleanup:

```bash
docker builder prune -a
```

### 4) Remove unused volumes (careful)

Default behavior removes only **anonymous** unused volumes:

```bash
docker volume prune
```

To include **named** unused volumes too:

```bash
docker volume prune -a
```

Or remove one specific volume:

```bash
docker volume rm <volume_name>
```

## Why `docker volume prune` may reclaim `0B`

If all unused space is in a **named** volume, `docker volume prune` (without `-a`) will not delete it.

Example from this server:

- `lm_studio_docker_lmstudio-models` was dangling (`LINKS=0`)
- `docker volume prune` reclaimed `0B`
- `docker volume prune -a` or `docker volume rm lm_studio_docker_lmstudio-models` is required

## Commands to inspect before deleting

List dangling (unused) volumes:

```bash
docker volume ls -qf dangling=true
```

Inspect one volume:

```bash
docker volume inspect <volume_name>
```

Check mounted path on disk:

```bash
docker volume inspect <volume_name> --format '{{ .Mountpoint }}'
```

Check size of that path (may require sudo):

```bash
sudo du -hs /var/lib/docker/volumes/<volume_name>/_data
```

## One-command aggressive cleanup

Deletes unused containers, networks, images, build cache, and optionally volumes.

```bash
docker system prune -a --volumes
```

Use only when you are sure old images/volumes are not needed.
