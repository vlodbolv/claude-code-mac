#!/usr/bin/env bash
set -euo pipefail

echo "🤖 Claude Code Podman Setup (macOS)"
echo

# -------------------------------------------------
# Configuration (Claude-safe minimums)
# -------------------------------------------------
MACHINE_NAME="podman-machine-default"
IMAGE_NAME="claude-code-dev"
CONTAINER_NAME="claude-code-dev-container"

MIN_MEMORY_MB=8192
MIN_CPUS=4
MIN_DISK_GB=50

# -------------------------------------------------
# Ensure Podman is installed
# -------------------------------------------------
if ! command -v podman >/dev/null 2>&1; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "❌ Podman is not installed and Homebrew is missing."
    echo "👉 Install Homebrew from https://brew.sh and re-run."
    exit 1
  fi
  echo "📦 Installing Podman via Homebrew..."
  brew install podman
else
  echo "✅ Podman already installed"
fi

# -------------------------------------------------
# Ensure Podman machine exists (inspect is authoritative)
# -------------------------------------------------
if podman machine inspect "$MACHINE_NAME" >/dev/null 2>&1; then
  echo "✅ Podman machine exists: $MACHINE_NAME"
else
  echo "⚙️  Creating Podman machine: $MACHINE_NAME"
  podman machine init \
    --memory "$MIN_MEMORY_MB" \
    --cpus "$MIN_CPUS" \
    --disk-size "$MIN_DISK_GB" \
    "$MACHINE_NAME" || true
fi

# -------------------------------------------------
# Inspect machine state (version-safe)
# -------------------------------------------------
STATE="$(podman machine inspect "$MACHINE_NAME" --format '{{.State}}' 2>/dev/null || echo unknown)"
MEMORY_MB="$(podman machine inspect "$MACHINE_NAME" --format '{{.Resources.Memory}}')"
CPUS="$(podman machine inspect "$MACHINE_NAME" --format '{{.Resources.CPUs}}')"
DISK_GB="$(podman machine inspect "$MACHINE_NAME" --format '{{.Resources.DiskSize}}')"

echo
echo "🔍 Podman machine status:"
echo "   • State:   $STATE"
echo "   • Memory:  ${MEMORY_MB} MB"
echo "   • CPUs:    ${CPUS}"
echo "   • Disk:    ${DISK_GB} GB"
echo

# -------------------------------------------------
# Resize machine ONLY if needed
# -------------------------------------------------
NEEDS_RESIZE=false
[ "$MEMORY_MB" -lt "$MIN_MEMORY_MB" ] && NEEDS_RESIZE=true
[ "$CPUS" -lt "$MIN_CPUS" ] && NEEDS_RESIZE=true
[ "$DISK_GB" -lt "$MIN_DISK_GB" ] && NEEDS_RESIZE=true

if [ "$NEEDS_RESIZE" = true ]; then
  echo "🔧 Podman machine does not meet Claude Code requirements."

  if [ "$STATE" = "running" ]; then
    echo "🛑 Stopping Podman machine to resize..."
    podman machine stop "$MACHINE_NAME"
  fi

  echo "➡️  Resizing Podman machine..."
  podman machine set \
    --memory "$MIN_MEMORY_MB" \
    --cpus "$MIN_CPUS" \
    --disk-size "$MIN_DISK_GB" \
    "$MACHINE_NAME"
fi

# -------------------------------------------------
# Start machine ONLY if not running
# -------------------------------------------------
STATE="$(podman machine inspect "$MACHINE_NAME" --format '{{.State}}')"
if [ "$STATE" != "running" ]; then
  echo "▶️  Starting Podman machine..."
  podman machine start "$MACHINE_NAME"
else
  echo "▶️  Podman machine already running"
fi

# -------------------------------------------------
# Prompt for Anthropic API key (TTY-safe, clear UX)
# -------------------------------------------------
echo
echo "🔐 Anthropic API Key"
echo "• Type or paste your key"
echo "• Input is hidden"
echo "• Press ENTER when finished"
echo

printf "Enter ANTHROPIC_API_KEY → " > /dev/tty
IFS= read -rs ANTHROPIC_API_KEY < /dev/tty
printf "\n" > /dev/tty

if [ -z "$ANTHROPIC_API_KEY" ]; then
  echo "❌ No API key entered. Aborting."
  exit 1
fi

echo "✅ API key received."

# -------------------------------------------------
# Write Containerfile (Claude installed as developer)
# -------------------------------------------------
echo
echo "📝 Writing Containerfile..."

cat > Containerfile <<'EOF'
FROM alpine:latest

RUN apk add --no-cache \
    bash \
    curl \
    git \
    ca-certificates \
    libgcc \
    libstdc++ \
    ripgrep

# Create user FIRST
RUN adduser -D developer
USER developer

ENV USE_BUILTIN_RIPGREP=0
RUN curl -fsSL https://claude.ai/install.sh | bash

ENV PATH="/home/developer/.local/bin:$PATH"
ENV HISTFILE=/dev/null

WORKDIR /workspace
VOLUME /workspace

CMD ["bash"]
EOF

# -------------------------------------------------
# Build image
# -------------------------------------------------
echo "🐳 Building Claude Code image..."
podman build -t "$IMAGE_NAME" .

# -------------------------------------------------
# Run container (FORCE interactive shell)
# -------------------------------------------------
echo
echo "🚀 Entering Claude Code container"
echo "👉 You are now INSIDE the container"
echo "👉 Run: claude"
echo

podman run --rm -it \
  --name "$CONTAINER_NAME" \
  -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
  -v "$(pwd):/workspace:Z" \
  -w /workspace \
  "$IMAGE_NAME" \
  bash

