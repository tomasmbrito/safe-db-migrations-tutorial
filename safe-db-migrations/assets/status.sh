#!/usr/bin/env bash
# summary of the last 10 seconds of traffic
T="${TUTORIAL_DIR:-/root/tutorial}"
log="$T/logs/traffic.log"
now=$(date +%s)
echo "Traffic in the last 10 seconds   (active versions: $(paste -sd' ' "$T/state/active_versions"))"
echo "------------------------------------------------------------"
awk -v since=$((now - 10)) '$1 >= since {
    total[$2]++
    if ($4 ~ /^2/) ok[$2]++; else err[$2]++
    if ($5+0 > slow[$2]) slow[$2] = $5+0
  }
  END {
    n = 0
    for (v in total) {
      n++
      printf "  %s  requests: %3d   ok: %3d   failed: %3d   slowest: %.2fs\n", v, total[v], ok[v]+0, err[v]+0, slow[v]
    }
    if (n == 0) print "  no traffic yet"
  }' "$log" | sort
echo
echo "Last failures:"
awk -v since=$((now - 10)) '$1 >= since && $4 !~ /^2/' "$log" | tail -3 | sed 's/^/  /'
echo
