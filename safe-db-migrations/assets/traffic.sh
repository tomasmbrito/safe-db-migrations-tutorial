#!/usr/bin/env bash
# fake users: one request every 0.3s, round robin over the active versions
# (our "load balancer"), every result goes to logs/traffic.log
T="${TUTORIAL_DIR:-/root/tutorial}"
log="$T/logs/traffic.log"
i=0
while true; do
  mapfile -t versions <"$T/state/active_versions"
  if [ "${#versions[@]}" -gt 0 ]; then
    v="${versions[$((i % ${#versions[@]}))]}"
    port=$([ "$v" = v1 ] && echo 8001 || echo 8002)
    if [ $((i % 2)) -eq 0 ]; then
      out=$(curl -s -m 3 -o /dev/null -w '%{http_code} %{time_total}' "localhost:$port/users")
      op=GET
    else
      out=$(curl -s -m 3 -o /dev/null -w '%{http_code} %{time_total}' -X POST -H 'Content-Type: application/json' \
            -d "{\"name\": \"user $i\"}" "localhost:$port/users")
      op=POST
    fi
    code=${out%% *}; secs=${out##* }
    [ "$code" = 000 ] && code=TIMEOUT
    echo "$(date +%s) $v $op $code ${secs}s" >>"$log"
  fi
  i=$((i + 1))
  sleep 0.3
done
