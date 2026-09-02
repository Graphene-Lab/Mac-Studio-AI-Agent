# Installation

This page explains how to install **Mac Studio AI Agent** on a Mac, what you need before you start, and how to verify that everything works. The whole install is a single copy-paste command: no .NET runtime, no extra setup, no manual dependency handling.

## Prerequisites

| Requirement | Details |
|---|---|
| **Mac** | Any **Apple silicon** Mac — Mac Studio, MacBook Pro, MacBook Air, iMac, Mac mini, Mac Pro (M1, M2, M3, M4, M5 chips) — or an **Intel** Mac with macOS 12 or later |
| **OS** | **macOS 12 or later** (the installer picks the right build: `osx-arm64` on Apple silicon, `osx-x64` on Intel) |
| **Storage** | At least **1.5 GB free** (the release archive is ~700 MB, the installed app ~810 MB) |
| **Memory** | 8 GB or more recommended (more unified memory lets larger local models run on Apple silicon) |
| **Network** | Internet access to download the release (GitHub). The assistant itself can later run fully offline with a local model |
| **Access** | A Terminal with `sudo` rights for the always-on service (optional — see the options below) |

## One-line install

Copy and paste this into the Terminal of your Mac:

```bash
curl -fsSL https://raw.githubusercontent.com/Graphene-Lab/Mac-Studio-AI-Agent/main/install.sh | bash
```

What the installer does automatically:

1. Detects macOS (Darwin) and your architecture — **Apple silicon (`arm64`) or Intel (`x64`)**.
2. Downloads the **latest** AgentBridge macOS release from GitHub that matches your Mac (pin a version with `MAC_AGENT_VERSION=v1.26.09.02`).
3. Unpacks it into `/opt/agentbridge` and fixes the file ownership.
4. Creates and starts a **launchd daemon** (`com.graphene-lab.agentbridge`) that keeps the assistant always on and starts it at boot.
5. Prints the final status.

The archive is self-contained: the .NET runtime, the Kokoro speech engine, its voices and every component are already inside — **no .NET installation needed**.

### Options

```bash
# Install a specific version instead of latest
curl -fsSL https://raw.githubusercontent.com/Graphene-Lab/Mac-Studio-AI-Agent/main/install.sh | \
  MAC_AGENT_VERSION=v1.26.09.02 bash

# Install into a custom folder (no launchd daemon)
curl -fsSL https://raw.githubusercontent.com/Graphene-Lab/Mac-Studio-AI-Agent/main/install.sh | \
  MAC_AGENT_HOME=$HOME/agentbridge MAC_AGENT_NO_SERVICE=1 bash

# Force a specific build (Apple silicon / Intel)
curl -fsSL https://raw.githubusercontent.com/Graphene-Lab/Mac-Studio-AI-Agent/main/install.sh | \
  MAC_AGENT_ARCH=x64 bash
```

## First start

After the install the assistant is already running. Verify it:

```bash
curl -s http://localhost:5290/health
# -> {"status":"healthy",...}

curl -s http://localhost:5290/v1/models
# -> lists the agents and the configured AI providers

curl -s http://localhost:5290/v1/control
# -> platform capabilities (platform should report "macos")
```

**Terminal chat (TUI):** the launchd daemon owns port 5290, so for the interactive chat run:

```bash
sudo launchctl bootout system/com.graphene-lab.agentbridge
/opt/agentbridge/agent
```

When you are done, put the assistant back always-on:

```bash
sudo launchctl bootstrap system /Library/LaunchDaemons/com.graphene-lab.agentbridge.plist
```

**API access:** the assistant answers any OpenAI-compatible call on `http://localhost:5290` (e.g. `/v1/chat/completions`, `/v1/audio/speech`) — scripts, bots and the web client all use the same server.

**OfficeManager:** open `http://localhost:5290/OfficeManager` in Safari or any browser to watch your agents work in the 16-bit office.

## Choosing the AI that powers your Mac

Type `/modelsetup` in the chat and pick a provider:

- **Local model** (fully offline): **Ollama** — runs natively on Apple silicon with **Metal** acceleration and uses the unified memory of your Mac. Any other OpenAI-compatible local server (LM Studio, llama.cpp, …) works too.
- **Cloud provider**: DeepSeek, Gemini, Anthropic — with the built-in GDPR-ready anonymisation that strips names and identifiers before any request leaves your Mac.

You can also edit `providers.json` next to the executable directly (it is the single source of truth for API keys) — see the AgentBridge documentation.

## Speech: what works out of the box

- **Text-to-speech (TTS)** — yes, on every Mac: the Kokoro neural voice, its voices and the ONNX model are shipped in the archive. Test it:

  ```bash
  curl -s -X POST http://localhost:5290/v1/audio/speech \
    -H 'Content-Type: application/json' \
    -d '{"model":"kokoro","input":"Hello from my Mac.","voice":"af_heart"}' \
    -o /tmp/hello.wav && file /tmp/hello.wav
  # -> RIFF ... WAVE audio, 16 bit, mono 24000 Hz
  ```

- **Speech-to-text (dictation / voice calls)** — the dictation engine is currently built for Windows; macOS speech recognition is on the roadmap for a future release (see the [technical notes](TECHNICAL-NOTES.md) for the platform status). Text chat, documents, email, research, Telegram, scheduling, podcasts and TTS all work on the Mac.

## Updating

The assistant updates itself automatically in the background (see the Updates guide). To force a fresh install of a newer release:

```bash
sudo launchctl bootout system/com.graphene-lab.agentbridge
curl -fsSL https://raw.githubusercontent.com/Graphene-Lab/Mac-Studio-AI-Agent/main/install.sh | bash
```

Your documents, keys and settings are never touched.

## Uninstalling

```bash
sudo launchctl bootout system/com.graphene-lab.agentbridge
sudo rm -f /Library/LaunchDaemons/com.graphene-lab.agentbridge.plist
sudo rm -rf /opt/agentbridge
```

## Troubleshooting

| Problem | Fix |
|---|---|
| `agent` is killed immediately on Apple silicon ("Killed: 9") | An unsigned arm64 binary cannot start on macOS. Ad-hoc sign it: `sudo codesign -s - /opt/agentbridge/agent` (a future AgentBridge release will ship pre-signed). |
| `Bad CPU type in executable` | The archive architecture does not match your Mac: reinstall with `MAC_AGENT_ARCH=arm64` (Apple silicon) or `MAC_AGENT_ARCH=x64` (Intel). |
| Gatekeeper blocks a manually downloaded archive | Downloads via the one-line installer are fine (curl). If you downloaded with a browser, clear the quarantine flag: `sudo xattr -dr com.apple.quarantine /opt/agentbridge` |
| Daemon does not start | `sudo launchctl print system/com.graphene-lab.agentbridge` and check the log at `/opt/agentbridge/logs/agentbridge.log` for the error |
| Port 5290 already in use | Stop the other instance (`sudo launchctl bootout system/com.graphene-lab.agentbridge`), or change `"Urls"` in `/opt/agentbridge/appsettings.json` and restart |
| Chat answers fail with "API key is not set" | No provider is configured yet — run `/modelsetup` in the chat, or add the provider in `providers.json` |
| Chat answers fail with an error about a local bridge | Providers on the same LAN are supported since AgentBridge v1.26.08.30 (they need no API key); point `providers.json` at the machine that runs the bridge (e.g. `http://192.168.x.x:8787/`) |
