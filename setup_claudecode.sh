#!/usr/bin/env bash
set -euo pipefail

echo "🤖 Claude Code Podman Setup (macOS) - Maximum Security Edition"
echo

MACHINE_NAME="podman-machine-default"
IMAGE_NAME="claude-code-dev"

# 1. Create a bulletproof .gitignore
# We ignore .claude-local/ to ensure your OAuth tokens stay off GitHub
cat << 'EOF' > .gitignore
.env
*.token
.claude-local/
claude.log
.podman/
.DS_Store
EOF

# 2. Ensure Podman Machine is running
if ! command -v podman >/dev/null 2>&1; then
  echo "❌ Podman is not installed. Run ./setup_podman.sh first."
  exit 1
fi

if ! podman machine inspect "$MACHINE_NAME" >/dev/null 2>&1; then
  podman machine init --memory 8192 --cpus 4 --disk-size 50 "$MACHINE_NAME" || true
fi

if [ "$(podman machine inspect "$MACHINE_NAME" --format '{{.State}}')" != "running" ]; then
  podman machine start "$MACHINE_NAME"
fi

# 3. Write Containerfile (Debian Slim)
echo "📝 Writing Containerfile..."
cat > Containerfile <<'EOF'
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    git \
    ca-certificates \
    ripgrep \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code natively as root to prevent permission errors
ENV USE_BUILTIN_RIPGREP=0
RUN curl -fsSL https://claude.ai/install.sh | bash

ENV PATH="/root/.local/bin:$PATH"
ENV HISTFILE=/dev/null

WORKDIR /workspace
CMD ["bash"]
EOF

# 4. Build image
echo "🐳 Building completely isolated Claude Code image..."
podman build --no-cache -t "$IMAGE_NAME" .

echo
echo "✅ Setup complete. Run ./enter-claude.sh to begin."
