#!/usr/bin/env bash
set -euo pipefail

echo "🤖 Claude Code Podman Setup (macOS) - Maximum Security Edition"
echo

MACHINE_NAME="podman-machine-default"
IMAGE_NAME="claude-code-dev"

MIN_MEMORY_MB=8192
MIN_CPUS=4
MIN_DISK_GB=50

# 1. Create the isolated workspace folder
mkdir -p workspace

# 2. Create a bulletproof .gitignore
cat << 'EOF' > .gitignore
.env
*.token
.claude-local/
claude.log
.podman/
.DS_Store
EOF

# 3. Ensure Podman Machine is running
if ! command -v podman >/dev/null 2>&1; then
  echo "❌ Podman is not installed. Run ./setup_podman.sh first."
  exit 1
fi

if ! podman machine inspect "$MACHINE_NAME" >/dev/null 2>&1; then
  echo "⚙️  Creating Podman machine: $MACHINE_NAME"
  podman machine init --memory "$MIN_MEMORY_MB" --cpus "$MIN_CPUS" --disk-size "$MIN_DISK_GB" "$MACHINE_NAME" || true
fi

if [ "$(podman machine inspect "$MACHINE_NAME" --format '{{.State}}')" != "running" ]; then
  echo "▶️  Starting Podman machine..."
  podman machine start "$MACHINE_NAME"
fi

# 4. Write Containerfile
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

# Install Claude Code globally. Running natively as root prevents EACCES permission errors.
ENV USE_BUILTIN_RIPGREP=0
RUN curl -fsSL https://claude.ai/install.sh | bash

ENV PATH="/root/.local/bin:$PATH"
ENV HISTFILE=/dev/null

WORKDIR /workspace
CMD ["bash"]
EOF

# 5. Build image
echo "🐳 Building completely isolated Claude Code image..."
podman build --no-cache -t "$IMAGE_NAME" .

echo
echo "✅ Setup complete. Run ./enter-claude.sh to start your isolated session."
