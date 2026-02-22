# Server_Performance_Stats
=======
# 📊 Server Performance Stats

A single Bash script that gives you a **complete snapshot** of your Linux server's health — CPU, memory, disk, network, processes, and more — in a clean, color-coded dashboard.

> Part of the [roadmap.sh DevOps Projects](https://roadmap.sh/projects/server-stats)

![Bash](https://img.shields.io/badge/Bash-5.0%2B-green?logo=gnubash&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Linux-blue?logo=linux&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-yellow)

---

## ✨ Features

| Category | Details |
|---|---|
| **CPU Usage** | Real-time sampling from `/proc/stat` (user / system / idle / iowait) |
| **Memory** | Total, used, free, buff/cache, available — with percentage & visual bar |
| **Swap** | Usage with percentage & visual bar |
| **Disk** | Per-partition breakdown (size, used, available, percentage) |
| **Top Processes** | Top 5 by CPU and top 5 by memory |
| **System Info** | OS, hostname, kernel, uptime, load average, logged-in users |
| **Network** | Listening ports, established connections, TIME_WAIT count |
| **Zombies** | Detects and lists zombie / defunct processes |
| **Failed Logins** | Last 24h failed SSH attempts (journalctl / auth.log / secure) |
| **Color Thresholds** | 🟢 < 70% · 🟡 70–89% · 🔴 ≥ 90% — with visual progress bars |

---

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/DavidBenitoCampo/Server_Performance_Stats.git
cd Server_Performance_Stats

# Make it executable
chmod +x server-stats.sh

# Run it
./server-stats.sh
```

---

## 📖 Usage

```bash
# Full color dashboard
./server-stats.sh

# Plain text output (for logging or piping to a file)
./server-stats.sh --no-color

# Save to a log file
./server-stats.sh --no-color >> /var/log/server-stats.log

# Show help
./server-stats.sh --help
```

### Options

| Flag | Description |
|---|---|
| `--no-color` | Disable ANSI colors (useful for logs and piping) |
| `--help`, `-h` | Display usage information |

---

## 📋 Sample Output

```
  📊  SERVER PERFORMANCE REPORT
  Generated: 2026-02-22 15:10:16 CET

──────────────────────────────────────────────────
  🖥  SYSTEM INFORMATION
──────────────────────────────────────────────────
  OS:        Ubuntu 24.04 LTS
  Hostname:  my-server
  Kernel:    6.19.0-3-generic
  Uptime:    up 5 days, 21 hours
  Load Avg:  0.38 (1m)  2.14 (5m)  2.58 (15m)  [16 CPUs]
  Users:     2 logged in

──────────────────────────────────────────────────
  ⚙️  CPU USAGE
──────────────────────────────────────────────────
  Total CPU Usage:  4%
  █░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  4%

──────────────────────────────────────────────────
  🧠  MEMORY USAGE
──────────────────────────────────────────────────
  Total:      14798 MB
  Used:       8338 MB  (56%)
  Free:       1405 MB
  ██████████████████████░░░░░░░░░░░░░░░░░░  56%

  ... (disk, processes, network, zombies, failed logins)
```

---

## 🛠 Requirements

- **Bash 4.0+**
- Standard Linux utilities: `awk`, `free`, `df`, `ps`, `ss`, `who`, `tput`, `nproc`
- Optional: `journalctl` (for failed login detection via systemd)

Works out of the box on Ubuntu, Debian, CentOS, RHEL, Fedora, Arch, and most Linux distributions.

---

## 🤝 Contributing

Contributions are welcome! Some ideas for improvements:

- Add `--json` output mode for integration with monitoring tools
- Add `--watch` flag for auto-refresh every N seconds
- Add temperature monitoring (CPU / GPU)
- Add service status checks (nginx, docker, etc.)
- Add email/webhook alerts when thresholds are crossed

---
