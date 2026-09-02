# Voice: speak to your assistant and hear it answer

AgentBridge can speak on every platform, and listen on some. On your Mac the assistant answers by voice as well as in writing out of the box; dictating from the microphone is currently available on Windows only and is on the roadmap for macOS (see the [technical notes](TECHNICAL-NOTES.md)).

## Two voices inside the program

The assistant speaks with two local voice engines. The first, Kokoro, is always ready: its voices and model are included with AgentBridge, so speech works the moment you run the program, on any machine, with nothing to install. The second engine, Qwen3-TTS, offers richer and more natural voices, including Italian, but it needs a powerful computer. In normal releases it is offered only on machines with a modern NVIDIA graphics card with enough memory, and its model downloads automatically the first time you use it.

## How to use it

Type /voice in the chat to dictate from the microphone (Windows), and /tts to hear the assistant speak the last answer aloud. If you want to know which voices your machine supports, or switch between the two engines, type /ttsengine and the program will tell you what is available and let you choose. The same voice engine also speaks on the phone and in the podcast tool, so your assistant sounds the same everywhere.

## Speech that never blocks you

Everything runs on your machine. If the more powerful engine is not available, the assistant simply stays on the default voice, so you are never left without an answer. The Mac Studio AI Agent ships the Kokoro voice engine for macOS out of the box — hearing your assistant speak works from the moment you install it.

The next guide explains how to reach your assistant by telephone, so it can help you even when you are away from the computer.
