# Technical notes — macOS platform status and roadmap

This file collects the macOS-specific technical facts of the Mac Studio AI Agent (the AgentBridge engine) that are too detailed for the README. It is written for technically curious users and for the developers of future versions.

Everything listed in **Roadmap** below is already tracked as a *To Do* item for future AgentBridge releases: this page only documents the current state of each item, so the product documentation can stay honest.

## Platform support summary

| Area | Status on macOS (Apple silicon) |
|---|---|
| Headless server (Kestrel, port 5290) | ✅ works |
| Terminal chat (Terminal.Gui TUI) | ✅ works (Terminal required; auto-falls back to headless when the console is redirected) |
| OfficeManager web view (`/OfficeManager`) | ✅ works (ships with the app, no external services) |
| Documents, office files (DOCX/XLSX/PPTX/PDF), email, web research, Telegram, scheduled tasks, podcasts, memory | ✅ works |
| Text-to-speech (Kokoro neural TTS) | ✅ works — onnxruntime CPU native library for macOS is included in the release |
| Qwen3-TTS (richer voices) | ❌ requires an NVIDIA GPU (CUDA) — not available on any Mac |
| Microphone dictation (`/v1/voice/listen`) | ❌ Windows-only today — **roadmap** |
| SIP phone access | ⚠️ SIP engine is cross-platform (pure managed) but needs the speech-to-text component — **roadmap** |
| `/v1/control` platform label | ✅ reports `"macos"` (since v1.26.09.x; earlier releases reported `"other"`) |

## macOS signing and execution (why `agent` can be "Killed: 9")

macOS requires every ARM64 executable to carry a code signature. A self-contained .NET single-file binary produced by a plain publish is not signed, so on Apple silicon the system kills it at launch (`Killed: 9`) unless it is signed. Three remedies exist:

1. **Ad-hoc signature** (today, user side): `sudo codesign -s - /opt/agentbridge/agent` — no Apple developer account needed; valid for execution on the same machine.
2. **Microsoft-signed runtime** (validated pattern used by the sibling CloudClient product): install the official .NET runtime (the `dotnet` binary is signed by Microsoft and trusted by macOS) and run the app framework-dependent as `dotnet agent.dll` instead of executing the apphost. Roadmap: ship `osx-arm64`/`osx-x64` framework-dependent archives so no user-side signing is ever needed.
3. **Developer ID + notarization** (real distribution): requires an Apple Developer account; the official route for Gatekeeper-clean distribution.

The AgentBridge release pipeline currently publishes self-contained single-file archives for all five platforms. Adding **pre-signed macOS binaries in CI** (ad-hoc signing of the apphost during the release build, or the framework-dependent dotnet launch) is on the roadmap so the one-line installer works on every Mac without a manual `codesign`.

## Speech on macOS — system services and roadmap

macOS ships native speech services that could power the Mac version of dictation and voice calls:

- **System TTS**: `say` (AVSpeechSynthesizer) exposes dozens of system voices. AgentBridge does not need it for output — the bundled Kokoro neural TTS already runs on macOS — but it remains a candidate alternative engine.
- **System STT**: the Speech framework (`SFSpeechRecognizer`) and the built-in dictation provide on-device speech recognition, with microphone/recognition permission prompts handled by macOS.

**Roadmap (future AgentBridge versions):**
- macOS STT backend for `/v1/voice/listen` (dictation), either through a small Speech-framework helper or by shipping the cross-platform whisper-based STT agent for macOS (`voiceagent-stt`).
- macOS STT provisioning for the SIP phone loop (the STT component is currently not bundled in the macOS release archives).
- Optional system-voice TTS engine selection in `/ttsengine` on macOS.
- Pre-signed (ad-hoc) macOS apphost in the release pipeline, or macOS framework-dependent archives launched via the Microsoft-signed `dotnet` runtime.

## Native dependency notes (NuGet)

- The **onnxruntime** native library for macOS (`osx-arm64`, `osx-x64`) is supplied by the CPU `Microsoft.ML.OnnxRuntime` package and is verified to restore and run; there is no CUDA/GPU execution provider on macOS, so TTS runs on the CPU.
- SIP (SIPSorcery), Telegram (WTelegramClient), Terminal.Gui and the office-tool plugins are pure managed code and platform-independent.
- The archive is verified end-to-end on public macOS CI runners (see the macOS smoke workflow) for `/health`, `/v1/models`, `/v1/control`, `/OfficeManager` and `/v1/audio/speech`.

*This page is part of the documentation repository only — it does not ship inside the AgentBridge archive.*
