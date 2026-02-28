mkdir -p antigravity-dev && cd antigravity-dev

# 1. Create .gitignore
cat > .gitignore <<'EOF'
.env
.env.*
*.key
*.secret
*.token
Containerfile
Dockerfile
*.log
.gemini/
gemini-cache/
gemini.log
.podman/
podman-compose.yaml
tmp/
temp/
*.tmp
*.swp
.DS_Store
node_modules/
__pycache__/
EOF

# 2. Create setup_antigravity.sh
cat > setup_antigravity.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "🌌 Google Antigravity (Gemini CLI) Podman Setup"
echo

MACHINE_NAME="podman-machine-default"
IMAGE_NAME="gemini-cli-dev"
MIN_MEMORY_MB=8192
MIN_CPUS=4
MIN_DISK_GB=50

if ! command -v podman >/dev/null 2>&1; then
  echo "📦 Installing Podman via Homebrew..."
  brew install podman
fi

if ! podman machine inspect "$MACHINE_NAME" >/dev/null 2>&1; then
  echo "⚙️  Initializing Podman VM..."
  podman machine init --memory "$MIN_MEMORY_MB" --cpus "$MIN_CPUS" --disk-size "$MIN_DISK_GB" "$MACHINE_NAME"
fi

STATE="$(podman machine inspect "$MACHINE_NAME" --format '{{.State}}')"
if [ "$STATE" != "running" ]; then
  echo "▶️  Starting Podman VM..."
  podman machine start "$MACHINE_NAME"
fi

cat > Containerfile <<'CF'
FROM node:20-alpine
RUN apk add --no-cache bash curl git ca-certificates libgcc libstdc++ ripgrep
RUN adduser -D developer
USER developer
WORKDIR /home/developer
RUN npm install -g @google/gemini-cli
ENV PATH="/home/developer/.npm-global/bin:$PATH"
ENV HISTFILE=/dev/null
WORKDIR /workspace
VOLUME /workspace
CMD ["bash"]
CF

echo "🐳 Building Gemini CLI image..."
podman build -t "$IMAGE_NAME" .
echo "✅ Setup complete."
EOF

# 3. Create enter-antigravity.sh
cat > enter-antigravity.sh <<'EOF'
#!/usr/bin/env bash
set -e

IMAGE_NAME="gemini-cli-dev"
WORKDIR="/workspace"
HOST_GEMINI_DIR="$HOME/.gemini"

echo "🤖 Gemini CLI – Session Manager"

RUNNING_CONTAINERS="$(podman ps --filter "ancestor=$IMAGE_NAME" --format "{{.Names}}")"

if [ -n "$RUNNING_CONTAINERS" ]; then
  echo "🟢 Active session found. Re-entering..."
  CONTAINER_ID=$(echo "$RUNNING_CONTAINERS" | head -n 1)
  podman exec -it "$CONTAINER_ID" bash
  exit 0
fi

echo "🚀 No active session. Starting new container and triggering login..."
mkdir -p "$HOST_GEMINI_DIR"

podman run --rm -it \
  -v "$HOST_GEMINI_DIR:/home/developer/.gemini:Z" \
  -v "$(pwd):$WORKDIR:Z" \
  -w "$WORKDIR" \
  "$IMAGE_NAME" \
  bash -c "gemini login && exec bash"
EOF

# 4. Create README.md
cat > README.md <<'EOF'
# Antigravity Dev Environment (Podman · macOS)

A containerized environment for the **Gemini CLI**, the terminal-based agent for Google Antigravity.

## 🚀 Quick Start

### 1. Initial Setup
Run once to install Podman and build the image:
```bash
chmod +x setup_antigravity.sh
./setup_antigravity.sh
