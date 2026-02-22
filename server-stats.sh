#!/usr/bin/env bash
# =============================================================================
# server-stats.sh — Server Performance Statistics
# =============================================================================
# Analyse and display key server performance metrics with color-coded output,
# threshold warnings, and a clean dashboard-style layout.
#
# Usage:
#   ./server-stats.sh              # full color output
#   ./server-stats.sh --no-color   # plain text (for logging / piping)
#   ./server-stats.sh --help       # show usage info
#
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Color & formatting helpers
# ---------------------------------------------------------------------------
NO_COLOR=false
for arg in "$@"; do
    case "$arg" in
        --no-color) NO_COLOR=true ;;
        --help|-h)
            echo "Usage: $0 [--no-color] [--help]"
            echo ""
            echo "Options:"
            echo "  --no-color   Disable colored output (useful for logging)"
            echo "  --help       Show this help message"
            exit 0
            ;;
    esac
done

if [[ "$NO_COLOR" == true ]]; then
    RED="" GREEN="" YELLOW="" BLUE="" CYAN="" MAGENTA="" BOLD="" DIM="" RESET=""
else
    RED="\033[0;31m"
    GREEN="\033[0;32m"
    YELLOW="\033[1;33m"
    BLUE="\033[0;34m"
    CYAN="\033[0;36m"
    MAGENTA="\033[0;35m"
    BOLD="\033[1m"
    DIM="\033[2m"
    RESET="\033[0m"
fi

# Determine the width of the terminal (default 70)
COLS=$(tput cols 2>/dev/null || echo 70)
SEP=$(printf '%*s' "$COLS" '' | tr ' ' '─')

header() {
    echo ""
    echo -e "${CYAN}${BOLD}$SEP${RESET}"
    echo -e "${CYAN}${BOLD}  $1${RESET}"
    echo -e "${CYAN}${BOLD}$SEP${RESET}"
}

sub_header() {
    echo ""
    echo -e "  ${MAGENTA}${BOLD}▸ $1${RESET}"
    echo -e "  ${DIM}$(printf '%*s' $((COLS - 4)) '' | tr ' ' '·')${RESET}"
}

# Color a percentage value based on thresholds
# Usage: color_pct <value> [warn_threshold] [crit_threshold]
color_pct() {
    local val=${1%\%}   # strip trailing % if present
    local warn=${2:-70}
    local crit=${3:-90}
    # handle non-numeric gracefully
    if ! [[ "$val" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo -e "${BOLD}${val}%${RESET}"
        return
    fi
    local int_val=${val%%.*}
    if (( int_val >= crit )); then
        echo -e "${RED}${BOLD}${val}%${RESET}"
    elif (( int_val >= warn )); then
        echo -e "${YELLOW}${BOLD}${val}%${RESET}"
    else
        echo -e "${GREEN}${BOLD}${val}%${RESET}"
    fi
}

bar() {
    # bar <used_pct> <width>
    local pct=${1%\%}
    local width=${2:-30}
    local int_pct=${pct%%.*}
    local filled=$(( int_pct * width / 100 ))
    local empty=$(( width - filled ))
    local color="$GREEN"
    (( int_pct >= 70 )) && color="$YELLOW"
    (( int_pct >= 90 )) && color="$RED"
    printf "${color}"
    printf '█%.0s' $(seq 1 "$filled" 2>/dev/null) || true
    printf "${DIM}"
    printf '░%.0s' $(seq 1 "$empty" 2>/dev/null) || true
    printf "${RESET}"
}

# ---------------------------------------------------------------------------
# Report timestamp
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}  📊  SERVER PERFORMANCE REPORT${RESET}"
echo -e "  ${DIM}Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')${RESET}"

# ========================== SYSTEM INFO ====================================
header "🖥  SYSTEM INFORMATION"

# OS version
if [[ -f /etc/os-release ]]; then
    os_name=$(. /etc/os-release && echo "${PRETTY_NAME:-$NAME $VERSION}")
else
    os_name=$(uname -srm)
fi
echo -e "  ${BOLD}OS:${RESET}        $os_name"

# Hostname
echo -e "  ${BOLD}Hostname:${RESET}  $(hostname)"

# Kernel
echo -e "  ${BOLD}Kernel:${RESET}    $(uname -r)"

# Uptime
uptime_str=$(uptime -p 2>/dev/null || uptime | sed 's/.*up /up /' | sed 's/,.*load.*//')
echo -e "  ${BOLD}Uptime:${RESET}    ${uptime_str}"

# Load average
read -r load1 load5 load15 _ < /proc/loadavg
num_cpus=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)
echo -e "  ${BOLD}Load Avg:${RESET}  ${load1} (1m)  ${load5} (5m)  ${load15} (15m)  ${DIM}[${num_cpus} CPUs]${RESET}"

# Logged-in users
user_count=$(who 2>/dev/null | wc -l)
echo -e "  ${BOLD}Users:${RESET}     ${user_count} logged in"
if (( user_count > 0 )); then
    who 2>/dev/null | awk '{printf "               %-12s %-8s %s %s\n", $1, $2, $3, $4}'
fi

# ========================== CPU USAGE ======================================
header "⚙️  CPU USAGE"

# Parse from /proc/stat for accuracy (two samples 1s apart)
read -r _ u1 n1 s1 i1 w1 q1 sq1 _ < /proc/stat
sleep 1
read -r _ u2 n2 s2 i2 w2 q2 sq2 _ < /proc/stat

idle_delta=$(( i2 - i1 ))
total_delta=$(( (u2+n2+s2+i2+w2+q2+sq2) - (u1+n1+s1+i1+w1+q1+sq1) ))
if (( total_delta > 0 )); then
    cpu_usage=$(( 100 * (total_delta - idle_delta) / total_delta ))
else
    cpu_usage=0
fi

echo -e "  Total CPU Usage:  $(color_pct "$cpu_usage" 70 90)"
echo -e "  $(bar "$cpu_usage" 40)  ${cpu_usage}%"
echo ""
echo -e "  ${DIM}User: $((u2-u1))  System: $((s2-s1))  Idle: $((i2-i1))  IOWait: $((w2-w1))${RESET}"

# ========================== MEMORY USAGE ===================================
header "🧠  MEMORY USAGE"

# Parse free output (works on most Linux distros)
read -r mem_total mem_used mem_free mem_shared mem_buff mem_avail <<< \
    "$(free -m | awk '/^Mem:/ {print $2, $3, $4, $5, $6, $7}')"

if (( mem_total > 0 )); then
    mem_pct=$(( 100 * mem_used / mem_total ))
else
    mem_pct=0
fi

echo -e "  Total:      ${BOLD}${mem_total} MB${RESET}"
echo -e "  Used:       ${BOLD}${mem_used} MB${RESET}  ($(color_pct "$mem_pct"))"
echo -e "  Free:       ${BOLD}${mem_free} MB${RESET}"
echo -e "  Buff/Cache: ${BOLD}${mem_buff} MB${RESET}"
echo -e "  Available:  ${BOLD}${mem_avail} MB${RESET}"
echo ""
echo -e "  $(bar "$mem_pct" 40)  ${mem_pct}%"

# --- Swap ---
sub_header "Swap Usage"
read -r swap_total swap_used swap_free <<< \
    "$(free -m | awk '/^Swap:/ {print $2, $3, $4}')"

if (( swap_total > 0 )); then
    swap_pct=$(( 100 * swap_used / swap_total ))
    echo -e "  Total: ${swap_total} MB | Used: ${swap_used} MB ($(color_pct "$swap_pct")) | Free: ${swap_free} MB"
    echo -e "  $(bar "$swap_pct" 40)  ${swap_pct}%"
else
    echo -e "  ${DIM}No swap configured${RESET}"
fi

# ========================== DISK USAGE =====================================
header "💾  DISK USAGE"

# Show each mounted partition (exclude tmpfs, devtmpfs, etc.)
printf "  ${BOLD}%-25s %8s %8s %8s %6s${RESET}\n" "Filesystem" "Size" "Used" "Avail" "Use%"
echo -e "  ${DIM}$(printf '%*s' $((COLS - 4)) '' | tr ' ' '·')${RESET}"

while IFS= read -r line; do
    fs=$(echo "$line"   | awk '{print $1}')
    size=$(echo "$line" | awk '{print $2}')
    used=$(echo "$line" | awk '{print $3}')
    avail=$(echo "$line" | awk '{print $4}')
    pct=$(echo "$line"  | awk '{print $5}')
    mount=$(echo "$line" | awk '{print $6}')

    pct_num=${pct%\%}
    pct_colored=$(color_pct "$pct_num" 70 90)

    # Truncate long filesystem names
    display_fs="$mount ($fs)"
    if (( ${#display_fs} > 25 )); then
        display_fs="${display_fs:0:22}..."
    fi

    printf "  %-25s %8s %8s %8s  " "$display_fs" "$size" "$used" "$avail"
    echo -e "$pct_colored"
done < <(df -h --output=source,size,used,avail,pcent,target -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null \
         | tail -n +2 | sort -k5 -t'%' -rn)

# ========================== TOP PROCESSES ==================================
header "🏆  TOP 5 PROCESSES BY CPU"

printf "  ${BOLD}%-8s %-12s %6s %6s  %-s${RESET}\n" "PID" "USER" "CPU%" "MEM%" "COMMAND"
echo -e "  ${DIM}$(printf '%*s' $((COLS - 4)) '' | tr ' ' '·')${RESET}"
ps aux --sort=-%cpu | awk 'NR>1 && NR<=6 {printf "  %-8s %-12s %6s %6s  %-s\n", $2, $1, $3, $4, $11}'

header "🏆  TOP 5 PROCESSES BY MEMORY"

printf "  ${BOLD}%-8s %-12s %6s %6s  %-s${RESET}\n" "PID" "USER" "MEM%" "CPU%" "COMMAND"
echo -e "  ${DIM}$(printf '%*s' $((COLS - 4)) '' | tr ' ' '·')${RESET}"
ps aux --sort=-%mem | awk 'NR>1 && NR<=6 {printf "  %-8s %-12s %6s %6s  %-s\n", $2, $1, $4, $3, $11}'

# ========================== NETWORK ========================================
header "🌐  NETWORK"

# Listening ports
listen_count=$(ss -tuln 2>/dev/null | grep -c LISTEN || echo 0)
echo -e "  ${BOLD}Listening ports:${RESET} ${listen_count}"

# Connection summary
established=$(ss -tun state established 2>/dev/null | tail -n +2 | wc -l)
time_wait=$(ss -tun state time-wait 2>/dev/null | tail -n +2 | wc -l)
echo -e "  ${BOLD}Established:${RESET}    ${established}"
echo -e "  ${BOLD}TIME_WAIT:${RESET}      ${time_wait}"

# ========================== ZOMBIE PROCESSES ===============================
header "🧟  ZOMBIE / DEFUNCT PROCESSES"

zombie_count=$(ps aux 2>/dev/null | awk '$8 ~ /^Z/ {count++} END {print count+0}')
if (( zombie_count > 0 )); then
    echo -e "  ${RED}${BOLD}⚠  ${zombie_count} zombie process(es) detected!${RESET}"
    ps aux | awk '$8 ~ /^Z/ {printf "     PID %-8s  PPID %-8s  %s\n", $2, $3, $11}' | head -10
else
    echo -e "  ${GREEN}✔  No zombie processes${RESET}"
fi

# ========================== FAILED LOGINS ==================================
header "🔒  FAILED LOGIN ATTEMPTS (last 24h)"

failed_count=0
if command -v journalctl &>/dev/null; then
    failed_count=$(journalctl _SYSTEMD_UNIT=sshd.service --since "24 hours ago" 2>/dev/null \
                   | grep -ci "failed\|invalid" 2>/dev/null || true)
elif [[ -r /var/log/auth.log ]]; then
    failed_count=$(grep -ci "failed\|invalid" /var/log/auth.log 2>/dev/null || true)
elif [[ -r /var/log/secure ]]; then
    failed_count=$(grep -ci "failed\|invalid" /var/log/secure 2>/dev/null || true)
fi
# Sanitize: keep only the first numeric value
failed_count=$(echo "$failed_count" | tr -d '[:space:]' | grep -oE '^[0-9]+' || echo 0)
failed_count=${failed_count:-0}

if (( failed_count > 20 )); then
    echo -e "  ${RED}${BOLD}⚠  ${failed_count} failed attempt(s) — investigate immediately!${RESET}"
elif (( failed_count > 0 )); then
    echo -e "  ${YELLOW}${failed_count} failed attempt(s) in the last 24 hours${RESET}"
else
    echo -e "  ${GREEN}✔  No failed login attempts detected${RESET}"
fi

# ========================== FOOTER =========================================
echo ""
echo -e "${CYAN}${BOLD}$SEP${RESET}"
echo -e "${DIM}  End of report · $(hostname) · $(date '+%H:%M:%S %Z')${RESET}"
echo -e "${CYAN}${BOLD}$SEP${RESET}"
echo ""