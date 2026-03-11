#!/usr/bin/env bash
# Top 10 process groups by combined PSS (Proportional Set Size).
# Process grouping is derived from the live ppid tree, cached for 30s.
# Output: JSON array [{"name":"...","mb":N,"pct":N.N}, ...]

total_kb=$(awk '/^MemTotal:/ { print $2 }' /proc/meminfo)

python3 - "$total_kb" <<'EOF'
import os, sys, json, time

total_kb   = int(sys.argv[1])
CACHE_FILE = '/tmp/mybar-procgroups.cache'
CACHE_TTL  = 30  # seconds between tree rebuilds

# Processes that act as session boundaries — stop walking up at their parent
BOUNDARIES = {
    'systemd', 'init',                                          # init systems
    'bash', 'zsh', 'sh', 'fish', 'nu', 'dash',                 # shells
    'login', 'sddm', 'sddm-helper', 'gdm', 'greetd', 'ly',    # session starters
    'start-hyprland',                                          # Hyprland launch wrapper
    'Hyprland', 'sway', 'niri', 'river', 'kwin_wayland',       # compositors
}

def build_group_map():
    """Walk /proc to build {pid: group_root_name} via ppid chains."""
    pid_info = {}  # pid -> (ppid, comm)
    for entry in os.listdir('/proc'):
        if not entry.isdigit():
            continue
        pid = int(entry)
        try:
            with open(f'/proc/{pid}/comm') as f:
                comm = f.read().strip()
            with open(f'/proc/{pid}/status') as f:
                for line in f:
                    if line.startswith('PPid:'):
                        ppid = int(line.split()[1])
                        break
                else:
                    continue
            pid_info[pid] = (ppid, comm)
        except (FileNotFoundError, PermissionError, ProcessLookupError):
            continue

    group_map = {}

    def root_of(pid, visited=None):
        if pid in group_map:
            return group_map[pid]
        if visited is None:
            visited = set()
        if pid not in pid_info or pid in visited:
            return pid_info.get(pid, (0, str(pid)))[1]
        visited.add(pid)
        ppid, comm = pid_info[pid]
        # Stop if: no parent, parent is pid 1, cycle, or parent is a boundary
        parent_comm = pid_info.get(ppid, (0, 'systemd'))[1]
        if ppid <= 1 or ppid == pid or parent_comm in BOUNDARIES:
            return comm
        return root_of(ppid, visited)

    for pid in pid_info:
        group_map[pid] = root_of(pid)

    return group_map

# Load or rebuild the group map
try:
    if time.time() - os.path.getmtime(CACHE_FILE) < CACHE_TTL:
        with open(CACHE_FILE) as f:
            group_map = {int(k): v for k, v in json.load(f).items()}
    else:
        raise FileNotFoundError
except (FileNotFoundError, ValueError, KeyError):
    group_map = build_group_map()
    try:
        with open(CACHE_FILE, 'w') as f:
            json.dump({str(k): v for k, v in group_map.items()}, f)
    except PermissionError:
        pass

# Accumulate PSS per group
acc = {}
for entry in os.listdir('/proc'):
    if not entry.isdigit():
        continue
    pid = int(entry)
    try:
        name = group_map.get(pid)
        if name is None:
            # Process appeared after cache was built — look up live
            with open(f'/proc/{pid}/comm') as f:
                name = f.read().strip()
        with open(f'/proc/{pid}/smaps_rollup') as f:
            for line in f:
                if line.startswith('Pss:'):
                    acc[name] = acc.get(name, 0) + int(line.split()[1])
                    break
    except (FileNotFoundError, PermissionError, ProcessLookupError):
        continue

top = sorted(acc.items(), key=lambda x: -x[1])[:10]
out = [{"name": n[:20], "mb": round(kb/1024), "pct": round(kb/total_kb*100, 1)}
       for n, kb in top]
print(json.dumps(out, separators=(',', ':')))
EOF
