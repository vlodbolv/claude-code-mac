#!/usr/bin/env bash
set -e

IMAGE_NAME="claude-code-dev"
WORKDIR="/workspace"

echo "🤖 Claude Code – Enter Container"
echo

# --------------------------------------
# Helper: yes/no prompt
# --------------------------------------
confirm() {
  while true; do
    printf "%s [y/n]: " "$1"
    read yn
    case "$yn" in
      y|Y) return 0 ;;
      n|N) return 1 ;;
      *) echo "Please answer y or n." ;;
    esac
  done
}

# --------------------------------------
# Step 1: Find running containers
# --------------------------------------
RUNNING_CONTAINERS="$(podman ps --format "{{.Names}}")"

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
  echo

  printf "Select a container to enter: "
  read choice

  if [ "$choice" -eq "$i" ]; then
    echo "❌ Cancelled."
    exit 0
  fi

  j=1
  for c in $CONTAINER_LIST; do
    if [ "$j" -eq "$choice" ]; then
      echo
      echo "🚪 Entering container: $c"
      podman exec -it "$c" bash
      exit 0
    fi
    j=$((j + 1))
  done

  echo "❌ Invalid selection."
  exit 1
fi

# --------------------------------------
# Step 2: No running containers
# --------------------------------------
echo "⚠️  No running containers found."
echo

if ! podman image exists "$IMAGE_NAME"; then
  echo "❌ Image '$IMAGE_NAME' does not exist."
  echo "👉 Run the setup script first."
  exit 1
fi

if ! confirm "Would you like to start a new Claude Code container?"; then
  echo "❌ Aborted."
  exit 0
fi

# --------------------------------------
# Step 3: Start new container
# --------------------------------------
echo
echo "🚀 Starting new Claude Code container..."
echo "👉 You are entering the container shell"
echo

podman run --rm -it \
  -v "$(pwd):$WORKDIR:Z" \
  -w "$WORKDIR" \
  "$IMAGE_NAME" \
  bash

