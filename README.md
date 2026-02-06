---

# Claude Code Dev Environment (Podman · macOS)

A lightweight, reproducible development environment for **Claude Code** using **Podman on macOS**.

This repo provides a small set of Bash scripts to:

* Set up Podman correctly on macOS (with safe resource defaults)
* Build a Claude Code–ready container image
* Enter or re-enter running containers interactively
* Keep your **workspace on the host**, not trapped in the container
* Avoid Docker Desktop entirely

No secrets are written to disk.
Your Anthropic API key is entered interactively and scoped to the container session.

---

## ✨ What you get

* 🐳 **Podman-based** dev environment (no Docker Desktop)
* 🤖 **Claude Code** installed inside the container
* 📁 **Host-mounted workspace** (`/workspace` ↔ current directory)
* 🔐 Secure, interactive API key handling
* 🔁 Scripts are **idempotent** (safe to re-run)
* 🧭 Interactive container selection when multiple containers are running
* 💻 Compatible with **macOS default Bash (3.2)**

---

## 📂 Repository structure

```text
.
├── setup_podman.sh            # One-time Podman + VM setup (macOS)
├── setup_claudecode.sh        # Build image & enter Claude container
├── enter-claude.sh            # Re-enter or start Claude containers
├── Containerfile              # Generated container definition (ignored in git)
├── setup_terminal_style.sh    # (Optional) Aurora DX terminal styling
├── .gitignore
└── README.md
```

---

## 🚀 Quick start

### 1️⃣ Prerequisites

* macOS
* Homebrew installed
  👉 [https://brew.sh](https://brew.sh)
* An Anthropic API key

---

### 2️⃣ Set up Podman (one time)

This installs Podman and configures the Podman VM with enough resources to run Claude Code reliably.

```bash
chmod +x setup_podman.sh
./setup_podman.sh
```

What this does:

* Installs Podman if needed
* Creates (or reuses) the Podman machine
* Ensures sufficient memory, CPU, and disk
* Starts the Podman VM if it isn’t running

---

### 3️⃣ Build the Claude Code container and enter it

From your project directory:

```bash
chmod +x setup_claudecode.sh
./setup_claudecode.sh
```

You will be prompted to enter your **Anthropic API key** securely.

After this completes, you will be dropped **inside the container**, in:

```text
/workspace
```

which maps directly to the directory you ran the script from.

Inside the container, run:

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
* Let you **choose which one to enter**
* Or, if none are running, offer to start a new Claude Code container

No rebuilding unless you explicitly run the setup script again.

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

---

## 🔐 Security notes

* Your Anthropic API key:

  * Is entered interactively
  * Is never written to disk
  * Is not stored in `.env` files
  * Exists only for the lifetime of the container
* Containers run as a non-root user (`developer`)
* The container filesystem is disposable

---

## 🎨 Optional: Aurora DX terminal styling

If you want a themed terminal setup (Bash + Starship + iTerm2):

```bash
chmod +x setup_terminal_style.sh
./setup_terminal_style.sh
```

This is **completely optional** and independent from Claude Code or Podman.

---

## 🧪 How to verify you’re inside the container

Inside the shell:

```bash
pwd
# /workspace

which claude
# /home/developer/.local/bin/claude

hostname
# (should NOT be your Mac hostname)
```

---

## 🧹 Cleanup

Containers started with these scripts use `--rm`, so they are removed automatically on exit.

To stop the Podman VM:

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
The container pieces do, but the Podman VM setup scripts are macOS-specific.

---
