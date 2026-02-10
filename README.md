---
title: "Claude Code Dev Environment"
description: "A Podman-based Claude Code development environment for macOS"
---

# Claude Code Dev Environment (Podman · macOS)

A lightweight, reproducible development environment for **Claude Code** using **Podman on macOS**.

This repository provides a small set of Bash scripts to set up Podman correctly, build a Claude Code–ready container image, and interactively enter or re-enter containers — **without Docker Desktop** and without storing secrets on disk.

---

## ✨ Features

- 🐳 **Podman-based** (no Docker Desktop required)
- 🤖 **Claude Code** installed inside a disposable container
- 📁 **Host-mounted workspace** (`/workspace` ↔ current directory)
- 🔁 Scripts are **idempotent** (safe to re-run)
- 🧭 Interactive container selection when multiple containers are running
- 💻 Compatible with **macOS default Bash (3.2)**

---

## 📂 Repository structure

```text
.
├── setup_podman.sh                    # One-time Podman + VM setup (macOS)
├── setup_claudecode.sh                # Build image & enter Claude container
├── enter-claude.sh                   # Re-enter or start Claude containers
├── run_in_host_setup_terminal_style.sh# OPTIONAL host-only terminal styling
├── Containerfile                     # Generated at build time (gitignored)
├── .gitignore
└── README.md


---

## 🚀 Quick start

### 1️⃣ Prerequisites

* macOS
* Homebrew installed
  👉 [https://brew.sh](https://brew.sh)
* An Anthropic API key

---

### 2️⃣ Set up Podman (one time)

This installs Podman and configures the Podman virtual machine with enough
resources to run Claude Code reliably.

```bash
chmod +x setup_podman.sh
./setup_podman.sh
```

What this does:

* Installs Podman (if missing)
* Creates or reuses `podman-machine-default`
* Ensures sufficient memory, CPU, and disk
* Starts the Podman machine if needed

You normally only run this once.

---

### 3️⃣ Build the Claude Code container and enter it

From your project directory:

```bash
chmod +x setup_claudecode.sh
./setup_claudecode.sh
```
After setup completes, you will be dropped **inside the container** in:

```text
/workspace
```

which maps directly to the directory you ran the script from.

Inside the container, start Claude Code:

```bash
claude
```

---

## 🔁 Re-entering containers later

Use the interactive helper:

```bash
chmod +x enter-claude.sh
./enter-claude.sh
```

This script will:

* Detect running containers
* Let you **choose which container to enter**
* If none are running, offer to start a new Claude Code container

No rebuilding unless you explicitly re-run the setup script.

---

## 📁 Workspace model (important)

The container mounts **your current directory** into `/workspace`:

```text
Host:      $(pwd)
Container: /workspace
```

This means:

* ✅ Your files persist after the container exits
* ✅ Git works normally on the host
* ❌ No code is stored inside the container image
* 🔒 The container cannot access other host directories

Only tooling lives in the container.
Your source code always stays on the host.

---

## 🎨 Optional: Aurora DX terminal styling (HOST ONLY)

The script:

```bash
run_in_host_setup_terminal_style.sh
```

is **completely optional**.

It customizes your **host terminal only**, including:

* Bash (Homebrew Bash ≥ 4)
* Starship prompt
* iTerm2 profile (Aurora DX theme, transparency, blur)

It **does NOT** affect:

* Podman
* Containers
* Claude Code
* Your workspace

The script includes a guard and will **refuse to run inside a container**.

Run it only on macOS if you want terminal aesthetics.

---

## 🧪 How to verify you’re inside the container

Inside the shell:

```bash
pwd
# /workspace

which claude
# /home/developer/.local/bin/claude

hostname
# should NOT be your Mac hostname
```

---

## 🧹 Cleanup

Containers started with these scripts use `--rm` and are removed automatically
on exit.

To stop the Podman virtual machine:

```bash
podman machine stop
```

---

## ❓ FAQ

**Why Podman instead of Docker?**
No Docker Desktop, no background daemon, fewer licensing headaches.

**Where is my code stored?**
On your host machine. The container only provides tooling.

**Can I use this with multiple projects?**
Yes. Run the scripts from different directories.

**Does this work on Linux?**
The container setup does, but the Podman VM scripts are macOS-specific.

---



```
