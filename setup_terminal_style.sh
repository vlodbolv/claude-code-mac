#!/usr/bin/env bash
set -e

echo "🌌 Aurora DX Bash Terminal Setup (macOS)"
echo

# ----------------------------
# Detect architecture
# ----------------------------
ARCH="$(uname -m)"
if [ "$ARCH" = "arm64" ]; then
  BREW_PREFIX="/opt/homebrew"
else
  BREW_PREFIX="/usr/local"
fi

# ----------------------------
# Detect current shell
# ----------------------------
CURRENT_SHELL="$(basename "$SHELL")"
echo "🔍 Current shell: $CURRENT_SHELL"

# ----------------------------
# Ensure Homebrew
# ----------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo "📦 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$("$BREW_PREFIX/bin/brew" shellenv)"
else
  eval "$(brew shellenv)"
fi

brew update

# ----------------------------
# Install required tools
# ----------------------------
echo "📦 Installing terminal tools..."
brew install bash bash-completion@2 starship
brew install --cask iterm2

# Optional font
if brew search --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1; then
  brew install --cask font-jetbrains-mono-nerd-font
fi

# ----------------------------
# Verify Bash version
# ----------------------------
BREW_BASH="$BREW_PREFIX/bin/bash"
BASH_VERSION_INSTALLED="$("$BREW_BASH" -c 'echo $BASH_VERSION')"
MAJOR_VERSION="${BASH_VERSION_INSTALLED%%.*}"

if [ "$MAJOR_VERSION" -lt 4 ]; then
  echo "❌ Bash ≥ 4.2 required"
  exit 1
fi

# ----------------------------
# Register Homebrew Bash
# ----------------------------
if ! grep -q "$BREW_BASH" /etc/shells; then
  sudo sh -c "echo '$BREW_BASH' >> /etc/shells"
fi

# ----------------------------
# Switch shell if needed
# ----------------------------
if [ "$CURRENT_SHELL" != "bash" ] || [ "$SHELL" != "$BREW_BASH" ]; then
  chsh -s "$BREW_BASH"
  SHELL_CHANGED=true
else
  SHELL_CHANGED=false
fi

# ----------------------------
# Backup configs
# ----------------------------
timestamp=$(date +"%Y%m%d-%H%M%S")
for f in ~/.bashrc ~/.bash_profile ~/.config/starship.toml; do
  [ -f "$f" ] && cp "$f" "$f.backup-$timestamp"
done

# ----------------------------
# Bash config
# ----------------------------
cat > ~/.bash_profile <<'EOF'
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
EOF

cat > ~/.bashrc <<'EOF'
# Enable bash-completion@2
if command -v brew >/dev/null 2>&1; then
  COMPLETION_FILE="$(brew --prefix)/etc/profile.d/bash_completion.sh"
  [ -f "$COMPLETION_FILE" ] && . "$COMPLETION_FILE"
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

eval "$(starship init bash)"
EOF

# ----------------------------
# Starship Aurora DX theme
# ----------------------------
mkdir -p ~/.config
cat > ~/.config/starship.toml <<'EOF'
[palettes.custom]
text = "c0caf5"
purple = "9d7cd8"
cyan = "7aa2f7"
green = "9ece6a"
yellow = "e0af68"
blue = "7dcfff"
red = "f7768e"
dark = "1a1b26"

[directory]
style = "cyan"
format = "[$path]($style) "

[git_branch]
style = "purple"

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"
EOF

# ----------------------------
# iTerm2 Aurora DX profile (transparent)
# ----------------------------
echo "🎨 Setting up iTerm2 Aurora DX profile..."

PROFILE_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
mkdir -p "$PROFILE_DIR"

cat > "$PROFILE_DIR/aurora-dx.json" <<'EOF'
{
  "Profiles": [
    {
      "Name": "Aurora DX",
      "Guid": "AURORA-DX-BASH",
      "Font": "JetBrainsMono Nerd Font Mono 14",
      "UseBoldFont": true,
      "UseItalicFont": true,
      "BackgroundColor": { "Red": 0.10, "Green": 0.11, "Blue": 0.15, "Alpha": 0.85 },
      "ForegroundColor": { "Red": 0.75, "Green": 0.80, "Blue": 0.96 },
      "UseTransparency": true,
      "Blur": true,
      "BlurRadius": 20,
      "Transparency": 0.15,
      "ScrollbackLines": 10000,
      "CursorType": 2,
      "ThinStrokes": 1,
      "UnlimitedScrollback": true
    }
  ]
}
EOF

# Tell iTerm2 to reload profiles
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$HOME/Library/Application Support/iTerm2"
defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile -bool true

# Launch iTerm2 once to apply
open -a iTerm

# ----------------------------
# Final message
# ----------------------------
echo
echo "✅ Aurora DX Bash + iTerm2 setup complete!"
echo

if [ "$SHELL_CHANGED" = true ]; then
  echo "➡️  New shell will apply in new terminals"
  echo "➡️  Or run now: exec \"$BREW_BASH\""
fi

echo
echo "🪟 iTerm2:"
echo "  • Profile: Aurora DX (now default-capable)"
echo "  • Transparency + blur enabled"
echo "  • Font: JetBrains Mono Nerd Font"
echo

