#!/usr/bin/env bash
# Mac Studio AI Agent — installer for macOS (Apple silicon and Intel Macs).
#
#   curl -fsSL https://raw.githubusercontent.com/Graphene-Lab/Mac-Studio-AI-Agent/main/install.sh | bash
#
# Downloads the latest AgentBridge macOS release from GitHub (osx-arm64 on Apple
# silicon, osx-x64 on Intel), unpacks it into /opt/agentbridge and installs it as
# a launchd daemon that auto-starts at boot. The archive is self-contained
# (~700 MB): no .NET runtime needed, Kokoro TTS voices and the speech model are
# included. On macOS, curl and tar ship with the system, so no packages to install.
#
# Environment overrides:
#   MAC_AGENT_VERSION       release tag to install, e.g. v1.26.08.30 (default: latest)
#   MAC_AGENT_HOME          install directory (default: /opt/agentbridge)
#   MAC_AGENT_ARCH          force the build: arm64 (Apple silicon) or x64 (Intel);
#                           default: detected from the CPU
#   MAC_AGENT_NO_SERVICE=1  unpack only, no launchd daemon
set -euo pipefail

AGENT_REPO="Graphene-Lab/AgentBridge"
VERSION="${MAC_AGENT_VERSION:-latest}"
DEST="${MAC_AGENT_HOME:-/opt/agentbridge}"
NO_SERVICE="${MAC_AGENT_NO_SERVICE:-0}"

# --- platform check (macOS only) ---
if [ "$(uname -s)" != "Darwin" ]; then
  echo "This installer targets macOS. On Linux, use the device-specific installer of your board; on Windows run in PowerShell." >&2
  exit 1
fi

# --- architecture: Apple silicon (arm64) or Intel (x64) ---
if [ -n "${MAC_AGENT_ARCH:-}" ]; then
  ARCH="$MAC_AGENT_ARCH"
else
  ARCH="$(uname -m | tr '[:upper:]' '[:lower:]')"
fi
case "$ARCH" in
  arm64) ASSET_ARCH="arm64" ;;
  x86_64|x64|amd64) ASSET_ARCH="x64" ;;
  *)
    echo "Unsupported architecture: $ARCH (Apple silicon arm64 and Intel x64 only)." >&2
    exit 1
    ;;
esac

# --- download the latest (or pinned) AgentBridge macOS release ---
if [ "$VERSION" = "latest" ]; then
  BASE="https://github.com/$AGENT_REPO/releases/latest/download"
else
  BASE="https://github.com/$AGENT_REPO/releases/download/$VERSION"
fi
ASSET="agentbridge-osx-$ASSET_ARCH.tar.gz"
echo "Downloading $BASE/$ASSET ..."

sudo mkdir -p "$DEST"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl -fL --retry 3 -o "$tmp/$ASSET" "$BASE/$ASSET"

# --- unpack directly into the destination ---
echo "Unpacking into $DEST ..."
sudo tar -xzf "$tmp/$ASSET" -C "$DEST"
rm -f "$tmp/$ASSET"

# The archive files carry the CI build uid; force a sane owner so the app can write
# its runtime state (logs/) without permission errors. Drop the quarantine attribute
# in case the archive was saved by a browser instead of curl.
sudo chown -R root:wheel "$DEST"
sudo chmod +x "$DEST/agent"
sudo xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true

# --- launchd daemon (auto-start at boot, always-on) ---
if [ "$NO_SERVICE" = "0" ]; then
  sudo mkdir -p "$DEST/logs"
  sudo chown root:wheel "$DEST/logs"
  LABEL="com.graphene-lab.agentbridge"
  PLIST="/Library/LaunchDaemons/$LABEL.plist"
  echo "Installing launchd daemon ($LABEL, auto-start at boot)..."
  sudo tee "$PLIST" >/dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$DEST/agent</string>
        <string>--headless</string>
        <string>--environment</string>
        <string>Production</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$DEST</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$DEST/logs/agentbridge.log</string>
    <key>StandardErrorPath</key>
    <string>$DEST/logs/agentbridge.log</string>
</dict>
</plist>
EOF
  # Reload the daemon (bootstrap fails if it is already loaded from a previous run).
  sudo launchctl bootout "system/$LABEL" 2>/dev/null || true
  sudo launchctl bootstrap system "$PLIST"
  sleep 3
  if sudo launchctl print "system/$LABEL" >/dev/null 2>&1; then
    echo "Mac Studio AI Agent daemon is active."
  else
    echo "WARNING: the daemon did not start - check: sudo launchctl print system/$LABEL" >&2
    sudo tail -n 10 "$DEST/logs/agentbridge.log" >&2 || true
  fi
fi

echo
echo "Mac Studio AI Agent installed to $DEST."
echo "HTTP API: http://localhost:5290  (health: /health, models: /v1/models)"
if [ "$NO_SERVICE" = "1" ]; then
  echo "Start the assistant with: $DEST/agent"
else
  echo "The assistant is always on; for the terminal chat run:"
  echo "  sudo launchctl bootout system/com.graphene-lab.agentbridge && $DEST/agent"
  echo "then restart it with: sudo launchctl bootstrap system /Library/LaunchDaemons/com.graphene-lab.agentbridge.plist"
fi
echo "Next: type /modelsetup in the chat to choose your AI provider."
