#!/usr/bin/env bash
# Top 5 processes by RSS, output as JSON array: [{"name":"...","mb":N,"pct":N.N}, ...]

ps -eo comm=,rss=,pmem= 2>/dev/null \
| awk '$2 > 0' \
| sort -k2 -rn \
| head -5 \
| awk 'BEGIN { printf "[" }
       NR > 1 { printf "," }
       {
           name = substr($1, 1, 20)
           gsub(/"/, "\\\"", name)
           printf "{\"name\":\"%s\",\"mb\":%.0f,\"pct\":%.1f}", name, $2/1024, $3
       }
       END { printf "]" }'
