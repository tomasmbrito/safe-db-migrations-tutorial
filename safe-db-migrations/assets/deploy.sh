#!/usr/bin/env bash
# start/stop one version of the app (one step of a rolling deploy)
# usage: ./deploy.sh start v2  |  ./deploy.sh stop v1
set -euo pipefail
T="${TUTORIAL_DIR:-/root/tutorial}"
action="${1:?usage: deploy.sh start|stop v1|v2}"
version="${2:?usage: deploy.sh start|stop v1|v2}"
case "$version" in v1) port=8001 ;; v2) port=8002 ;; *) echo "unknown version $version"; exit 1 ;; esac
active="$T/state/active_versions"
mkdir -p "$T/state" "$T/logs"
touch "$active"

if [ "$action" = start ]; then
  if ! curl -sf "localhost:$port/health" >/dev/null; then
    APP_VERSION=$version APP_PORT=$port nohup python3 "$T/app.py" >"$T/logs/app-$version.log" 2>&1 &
    echo $! >"$T/state/$version.pid"
    for _ in $(seq 1 50); do curl -sf "localhost:$port/health" >/dev/null && break; sleep 0.2; done
  fi
  grep -qx "$version" "$active" || echo "$version" >>"$active"
  echo "$version is up on :$port and receiving traffic"
elif [ "$action" = stop ]; then
  grep -vx "$version" "$active" >"$active.tmp" || true
  mv "$active.tmp" "$active"
  sleep 1  # give requests that are already running time to finish
  if [ -f "$T/state/$version.pid" ]; then kill "$(cat "$T/state/$version.pid")" 2>/dev/null || true; rm -f "$T/state/$version.pid"; fi
  echo "$version stopped and removed from the load balancer"
fi
echo "active versions: $(paste -sd' ' "$active")"
