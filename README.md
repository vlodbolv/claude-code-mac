# Claude Code Dev Environment (Podman · macOS)

A highly secure, totally isolated development environment for **Claude Code** using **Podman on macOS**.

This repository provides a small set of Bash scripts to build a Claude Code–ready container image while strictly quarantining the AI agent to a dedicated sandbox folder. It ensures your Mac's host files, SSH keys, and system configurations are completely invisible and protected.

---

## ✨ Key Features

* 🔒 **Total Sandbox Isolation**: The container is blind to your Mac. It can *only* access files placed inside the designated `workspace/` subdirectory. Even the launch scripts themselves are hidden from the AI.
* 🐳 **Podman-Native**: No Docker Desktop, no root privileges, and no background daemons required.
* 🚀 **Debian-Powered Base**: Built on `debian:bookworm-slim` to ensure flawless compatibility with standard C libraries (`glibc`) and native Node.js binaries.
* 🔑 **Locally Scoped Credentials**: Claude OAuth tokens and settings are saved to a hidden, git-ignored `.claude-local/` folder inside your project.
* 🔁 **Smart Session Manager**: Interactively jump back into running containers without losing your shell state.

---

## 📂 Repository Structure

* `setup_podman.sh`: One-time Podman + VM setup (macOS).
* `setup_claudecode.sh`: Builds the Debian-based image and generates the sandbox.
* `enter-claude.sh`: Re-enter or start new Claude sessions.
* `workspace/`: The only folder visible inside the container.
* `.claude-local/`: Persistent storage for OAuth tokens (git-ignored).

---

## 🚀 Quick Start

### 1️⃣ Initial Setup

Run the setup script once to configure the Podman VM, write your `.gitignore`, generate the secure sandbox folder, and build the Debian-based image.

```bash
chmod +x setup_claudecode.sh enter-claude.sh
./setup_claudecode.sh

```

*(Note: If you do not have Podman installed yet, run `./setup_podman.sh` first).*

### 2️⃣ Prepare Your Workspace

Because of the strict isolation rules, the AI cannot see your current directory. **Move any code, files, or projects you want Claude to analyze into the newly created `workspace/` folder.**

### 3️⃣ Enter the Environment

Use the session manager to step inside the secure container.

```bash
./enter-claude.sh

```

### 4️⃣ Start the Agent

Once inside the container, launch the Claude CLI:

```bash
claude

```

Follow the URL to authenticate. The agent now has full read/write access to `/workspace` (which maps to your host's `workspace/` folder) to help you code securely.

---

## 📂 Secure Architecture Layout

```text
claude-code-mac/            <-- Host Machine (Launchpad)
├── setup_claudecode.sh     (Invisible to container)
├── enter-claude.sh         (Invisible to container)
├── .gitignore              (Protects local tokens)
├── .claude-local/          (Locally scoped OAuth tokens & config)
└── workspace/              <-- THE SANDBOX (The only folder the AI sees)

```

---

## 🧹 Cleanup

To stop the Podman virtual machine and free up your Mac's system memory when you are done working:

```bash
podman machine stop

```
