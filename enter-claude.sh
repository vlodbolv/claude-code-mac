#!/usr/bin/env bash
set -e

IMAGE_NAME="claude-code-dev"
WORKDIR="/workspace"
LOCAL_CLAUDE_DIR="$(pwd)/.claude-local"

echo "🤖 Claude Code – Enter Container (Maximum Security Mode)"
echo

confirm() {
  while true; do
    printf "%s [y/n]: " "$1"
    read -r yn
    case "$yn" in
      y|Y) return 0 ;;
      n|N) return 1 ;;
      *) echo "Please answer y or n." ;;
    esac
  done
}

# Step 1: Find running containers
RUNNING_CONTAINERS="$(podman ps --filter "ancestor=$IMAGE_NAME" --format "{{.Names}}")"

if [ -n "$RUNNING_CONTAINERS" ]; then
  echo "🟢 Running containers detected:"
  echo
  i=1
  CONTAINER_LIST=""
  for c in $RUNNING_CONTAINERS; do
    echo "  $i) $c"
    CONTAINER_LIST="$CONTAINER_LIST $c"
    i=$((i + 1))
  done
  echo "  $i) Cancel"
  printf "Select a container to enter: "
  read -r choice
  if [ "$choice" -eq "$i" ]; then exit 0; fi
  # Jumps into selected container
  podman exec -it "$(echo $CONTAINER_LIST | cut -d' ' -f$choice)" bash
  exit 0
fi

# Step 2: Start new container with Dual-Mount isolation
if ! confirm "Would you like to start a new Claude Code container?"; then exit 0; fi

mkdir -p "$LOCAL_CLAUDE_DIR"

# MOUNT 1: Mounts local .claude-local folder to the container's root config
# MOUNT 2: Mounts the current project folder to /workspace
podman run --rm -it \
  --name "claude-session-$(date +%s)" \
  -v "$LOCAL_CLAUDE_DIR:/root/.claude:Z" \
  -v "$(pwd):$WORKDIR:Z" \
  -w "$WORKDIR" \
  "$IMAGE_NAME" \
  bash
