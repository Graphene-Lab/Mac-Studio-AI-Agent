# Frequently asked questions

## Installation

**Do I need to install .NET or Python?**
No. The release archive is self-contained: the runtime, the speech engine, the voices and every component are already inside (~700 MB compressed). `curl` and `tar` ship with macOS, so the installer needs nothing else.

**Which Macs are supported?**
Every Apple silicon Mac — **Mac Studio** (flagship, M5 Max / M5 Ultra), **MacBook Pro**, **MacBook Air**, **iMac**, **Mac mini** and **Mac Pro** — from the M1 generation to the latest M5 chips, all with a dedicated Neural Engine. Intel Macs with macOS 12 or later are supported too through the `osx-x64` build. The installer refuses to run on any other platform.

**Can I install it without an internet connection?**
The one-line installer downloads the release from GitHub, so the Mac needs internet for the first install. After that, with a local model (Ollama on Apple silicon), the assistant works fully offline.

**Where is it installed?**
`/opt/agentbridge` (change with `MAC_AGENT_HOME`). The daemon is called `com.graphene-lab.agentbridge` and starts at boot.

**How do I update?**
The assistant checks for updates by itself (see the Updates guide). You can also re-run the installer — your documents, keys and settings are never touched.

## Usage

**How do I chat with it?**
The assistant is always on. For the full-screen terminal chat run `sudo launchctl bootout system/com.graphene-lab.agentbridge` then `/opt/agentbridge/agent`; restart the daemon when done. The HTTP API on port 5290 is available at any time to scripts and bots, and the OfficeManager web view shows the agents at work.

**How do I choose which AI powers it?**
Type `/modelsetup` in the chat: pick a local model (Ollama on Apple silicon — everything stays on your Mac) or a cloud provider (DeepSeek, Gemini, Anthropic) with anonymisation enabled by default.

**Where are my documents?**
The assistant reads the documents folder it indexes on first start and answers questions from your files. You can ask it for finished DOCX, XLSX, PPTX and PDF documents.

## Speech

**Does text-to-speech work on the Mac?**
Yes — the Kokoro neural voice, all voices and the ONNX model ship in the archive, and `/v1/audio/speech` produces WAV audio out of the box on every Mac.

**Does speech recognition (dictation / voice calls) work?**
Not yet on macOS. The speech-to-text component is currently built for Windows only; the voice endpoints report themselves unavailable on macOS until a macOS build is published. Everything else — including the assistant speaking its answers — works. The macOS speech status and roadmap are tracked in the [technical notes](TECHNICAL-NOTES.md).

**Can the assistant answer phone calls?**
On Windows, yes (SIP). On macOS, the SIP bridge requires the speech-to-text component, so phone access is planned for a future macOS release. Telegram chat, in contrast, works fully.

## Privacy

**Do my documents leave my Mac?**
With a local model, nothing leaves the machine at all. With a cloud provider, the built-in anonymisation strips names and identifiers from the requests before they are sent.

**Who can access the assistant?**
By default the HTTP API listens on localhost. Telegram has an allow-list; SIP has a PIN. Expose it to your LAN only if you need to, and read the privacy guide for the details.

## Troubleshooting

**The daemon won't start.**
`sudo launchctl print system/com.graphene-lab.agentbridge` and `/opt/agentbridge/logs/agentbridge.log` show the reason. The most common causes are a malformed `providers.json`/`appsettings.json` or an unsigned binary on Apple silicon (`Killed: 9` — fix with `sudo codesign -s - /opt/agentbridge/agent`).

**Chat answers fail with "API key is not set".**
No provider is configured. Run `/modelsetup`, or add the provider in `providers.json` next to the executable.

**The installer says the platform is unsupported.**
The installer only runs on macOS. Check with `uname -s` — it must print `Darwin`. For Linux boards and Windows, use the corresponding device repositories.

**Do I need a monitor?**
No. The Mac can run headless; the assistant is reachable through the API on port 5290 from anywhere on your network. For the interactive chat, open a Terminal on the Mac itself.
