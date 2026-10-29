# Claude Manager

An AutoHotkey v2 tool that watches the Claude Desktop app, detects usage limits, waits for the reset and then automatically sends a message of your choice to a selected chat.

## Features

- Detects hourly and weekly usage limits in Claude Desktop and waits for the reset time.
- Sends a configurable, multiline message when the limit expires, after a final delay.
- Configurable initial delay, check frequency and post-reset delay (HH:MM:SS).
- Repetition modes: continuous, max times, until a given time, or for a given duration.
- Scans Claude chats and lets you pick the target chat.
- Reusable message templates.
- Status tooltip, optional audio notifications (beeps or text-to-speech) and optional event logging.
- Hover hints on every button showing its hotkey.

## Requirements

- Windows
- [AutoHotkey v2](https://www.autohotkey.com/)
- Claude Desktop (`Claude.exe`)

## Usage

1. Install AutoHotkey v2 and open Claude Desktop.
2. Run `ClaudeManager.ahk`.
3. Set the delays, repetition mode, target chat and message, then press **Start**.

Claude UI automation relies on fixed coordinates, keyboard shortcuts and window text, so changes in the Claude app may break it.

## Hotkeys

Global:

| Hotkey | Action |
|---|---|
| `Ctrl+`` | Start |
| `Shift+Esc` | Stop |
| `Ctrl+Shift+Esc` | Stop and exit |

Main window:

| Hotkey | Action |
|---|---|
| `Ctrl+N` | New message |
| `Ctrl+S` | Save message |
| `Ctrl+Delete` | Delete message (with confirmation) |
| `Ctrl+Shift+Delete` | Delete message (no confirmation) |
| `Ctrl+O` | Options |
| `Ctrl+Shift+S` | Scan chats |

## Files

- `settings.ini` - options, cache and templates, created next to the script (git-ignored).
- `claude_log.txt` - optional event log (git-ignored).
- `favicon.ico` - optional window icon.

## Contributing

See [AGENTS.md](AGENTS.md) for coding guidelines.
