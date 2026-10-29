# AGENTS.md

Guidance for working on Claude Manager (AutoHotkey v2).

## Project
- Script: `ClaudeManager.ahk`.
- Purpose: monitors the Claude Desktop window (`ahk_exe Claude.exe`), detects usage limits, waits for the reset, then sends a configurable message.
- Options/cache live in `settings.ini` next to the script (git-ignored); optional log in `claude_log.txt`.

## Rules
- AutoHotkey **v2** syntax only. No v1 syntax.
- UI and code comments are in **English only**. Do not reintroduce Polish text or a language switch.
- Keep the file organised in the numbered sections (Declarations, Helpers, Tooltip, Claude UI automation, Limit detection, Automation loop, Main window, Templates, Options, Startup, Hotkeys).
- Prefer small functions (about 20-50 lines). Group shared state in `Cfg` (persisted options), `State` (loop runtime) and `Ui` (GUI controls).
- Comment only non-obvious code.
- Remove dead code instead of keeping it. Check with grep that a function is unused first.
- Validate after every change: `& "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" /Validate "ClaudeManager.ahk"`.
  Then smoke-run it for a few seconds and stop it with `Stop-Process -Id <PID>`.

## Hotkeys
- Global: `Ctrl+`` (physical key `SC029`, layout independent) Start; `Shift+Esc` Stop; `Ctrl+Shift+Esc` Stop and exit.
- Main window only: `Ctrl+N` new message, `Ctrl+S` save message, `Ctrl+Delete` delete message (with confirmation), `Ctrl+Shift+Delete` delete without confirmation, `Ctrl+O` Options, `Ctrl+Shift+S` Scan chats.
- Hotkeys are shown as hover hints (`Hints` class, `TX["Hint*"]` strings), not in button labels. Update the hint when changing a hotkey. The close hint and weekly-reset hint are below the buttons.

## Findings / gotchas
- A single backtick in an AHK string is an escape character. Write a literal backtick as ` `` `.
- GUI Text controls do not grow when their text changes. The status tooltip recreates its label on each text change so the window auto-sizes (otherwise the second line is clipped).
- Register `OnMessage` handlers once, not on every update (they pile up).
- Saving options must not replace the 1-second `MainTick` timer.
- Every repetition mode (including `ForDuration`) must set `State.LoopType`.
- Window handling around Claude actions: `BeginClaudeSession` / `EndClaudeSession` activate Claude and restore the previous window. The bot window is never hidden or forced on top.
- Reset time is either a 14-digit timestamp (weekly limit, `yyyyMMddHHmmss`) or `HH:mm` (hourly limit).
- Claude UI automation depends on fixed coordinates, keyboard shortcuts and window text. Changes in the Claude app can break it.
