#!/usr/bin/env bash
set -e

echo "🐳 Podman macOS Setup (Claude Code Safe)"
echo

# ----------------------------
# Configuration (Claude-safe)
# ----------------------------
MACHINE_NAME="podman-machine-default"
MIN_MEMORY_MB=8192
MIN_CPUS=4
MIN_DISK_GB=50

# ----------------------------
# Ensure Homebrew
# ----------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo "❌ Homebrew is required."
  echo "👉 Install from https://brew.sh and re-run."
  exit 1
fi

# ----------------------------
# Install Podman
# ----------------------------
if ! command -v podman >/dev/null 2>&1; then
  echo "📦 Installing Podman..."
  brew install podman
else
  echo "✅ Podman already installed"
fi

# ----------------------------
# Ensure Podman machine exists
# ----------------------------
if ! podman machine list --format "{{.Name}}" | grep -q "^${MACHINE_NAME}$"; then
  echo "⚙️  Creating Podman machine: ${MACHINE_NAME}"
  podman machine init \
    --memory "$MIN_MEMORY_MB" \
    --cpus "$MIN_CPUS" \
    --disk-size "$MIN_DISK_GB" \
    "$MACHINE_NAME"
else
  echo "✅ Podman machine exists: ${MACHINE_NAME}"
fi

# ----------------------------
# Stop machine before resize
# ----------------------------
if podman machine list --format "{{.Name}} {{.Running}}" | grep -q "^${MACHINE_NAME} true"; then
  echo "🛑 Stopping Podman machine for configuration..."
  podman machine stop "$MACHINE_NAME"
fi

# ----------------------------
# Inspect current resources
# ----------------------------
MEMORY_MB=$(podman machine inspect "$MACHINE_NAME" --format '{{.Resources.Memory}}')
CPUS=$(podman machine inspect "$MACHINE_NAME" --format '{{.Resources.CPUs}}')
DISK_GB=$(podman machine inspect "$MACHINE_NAME" --format '{{.Resources.DiskSize}}')

echo "🔍 Current Podman machine resources:"
echo "   • Memory: ${MEMORY_MB} MB"
echo "   • CPUs:   ${CPUS}"
echo "   • Disk:   ${DISK_GB} GB"

# ----------------------------
# Resize if needed
# ----------------------------
NEEDS_RESIZE=false

[ "$MEMORY_MB" -lt "$MIN_MEMORY_MB" ] && NEEDS_RESIZE=true
[ "$CPUS" -lt "$MIN_CPUS" ] && NEEDS_RESIZE=true
[ "$DISK_GB" -lt "$MIN_DISK_GB" ] && NEEDS_RESIZE=true

if [ "$NEEDS_RESIZE" = true ]; then
  echo "🔧 Resizing Podman machine for Claude Code..."
  podman machine set \
    --memory "$MIN_MEMORY_MB" \
    --cpus "$MIN_CPUS" \
    --disk-size "$MIN_DISK_GB" \
    "$MACHINE_NAME"
else
  echo "✅ Podman machine resources already sufficient"
fi

# ----------------------------
# Start machine
# ----------------------------
echo "▶️  Starting Podman machine..."
podman machine start "$MACHINE_NAME"

# ----------------------------
# Final validation
# ----------------------------
echo

