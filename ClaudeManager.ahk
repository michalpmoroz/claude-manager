#Requires AutoHotkey v2.0
SetTitleMatchMode 2
CoordMode "ToolTip", "Screen"

; =========================================================================
; 1. DECLARATIONS
; =========================================================================

global TARGET_WIN := "ahk_exe Claude.exe"
global FAVICON_PATH := A_ScriptDir "\favicon.ico"
global LOG_FILE := A_ScriptDir "\claude_log.txt"

global TX := Map(
    "Title", "Claude Manager",
    "DelayGroup", "1. Initial delay (HH:MM:SS)",
    "FreqGroup", "2. Check frequency (HH:MM:SS)",
    "PostGroup", "3. Post-reset delay (HH:MM:SS)",
    "RepeatGroup", "4. Message Repetition Mode",
    "ChatGroup", "5. Target Chat Selection",
    "MsgGroup", "6. Multiline message templates to send",
    "BtnStart", "Start",
    "BtnStop", "Stop",
    "BtnOptions", "⚙ Options",
    "BtnScan", "📡 Scan chats",
    "HintStart", "Start automation (Ctrl+``)",
    "HintStop", "Stop automation (Shift+Esc)",
    "HintOptions", "Open options (Ctrl+O)",
    "HintScan", "Scan Claude chats (Ctrl+Shift+S)",
    "HintTplAdd", "New message (Ctrl+N)",
    "HintTplSave", "Save message (Ctrl+S)",
    "HintTplDelete", "Delete message (Ctrl+Delete; Ctrl+Shift+Delete skips confirmation)",
    "HintOk", "Confirm (Enter)",
    "HintCancel", "Cancel without saving",
    "HintSave", "Save options",
    "HintDefault", "Restore default options",
    "ConfirmDelete", "Delete message template '{1}'?",
    "OptCont", "Continuous",
    "OptMax", "Max times:",
    "OptUntil", "Until time (HH:MM:SS):",
    "OptFor", "For duration (HH:MM:SS):",
    "MsgErrClaude", "Claude Desktop window not found! Please open the app.",
    "MsgErrFreq", "Checking frequency must be greater than 0!",
    "MsgStop", "Automation has been stopped.",
    "StatusInit", "Status: Waiting for initial check`nRemaining: ",
    "StatusCheck", "Status: Monitoring Claude (No limit)`nNext check: ",
    "StatusLimit", "Status: LIMIT DETECTED!`nReset date: ",
    "StatusLimitUntil", "Status: LIMIT UNTIL ",
    "StatusPost", "Status: Limit expired! Final delay active`nSending in: ",
    "Remaining", "Remaining: ",
    "RepsInfo", "`nRepetition: ",
    "RepsLeft", " repetitions left",
    "WeeklyWarning", "`n[⚠️ WARNING: 75% of limit used!]",
    "HintClose", "Ctrl+Shift+Esc - Close application",
    "HintWeekly", "Weekly limit resets: ",
    "HintWeeklyNone", "Weekly limit reset: not recorded yet",
    "Days", ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
    "SetTitle", "Claude Manager Options",
    "SetLog", "Enable Event Logging to file (claude_log.txt)",
    "SetReturn", "Return to previous screen after scanning chats",
    "SetAudio", "Audio Notifications Mode:",
    "SetAudioNone", "None",
    "SetAudioBeep", "Standard Sounds",
    "SetAudioSpeech", "Voice TTS (Text-to-Speech)",
    "SetTooltip", "Status Tooltip Display Configuration:",
    "SetTtNever", "Never",
    "SetTtTimed", "Show for",
    "SetTtAlways", "Always",
    "SetTtSeconds", "sec.",
    "SetTtOntop", "Always on top",
    "SetTtLock", "Lock position",
    "SetTtTrans", "Opacity:",
    "BtnSave", "Save",
    "BtnCancel", "Cancel",
    "BtnDefault", "Defaults",
    "TplTitle", "New Template",
    "TplPrompt", "Enter template name:"
)

; Persistent settings, mirrored in settings.ini
class Cfg {
    static File := A_ScriptDir "\settings.ini"
    static LogEnabled := "0"
    static ReturnEnabled := "1"
    static AudioMode := "Standard"
    static TooltipMode := "Always"
    static TooltipTime := "5"
    static TtOnTop := "1"
    static TtLock := "0"
    static TtOpacity := "225"
    static TtPosX := ""
    static TtPosY := ""
    static WindowWidth := 510
    static WindowHeight := 460
    static WeeklyDay := ""     ; 1=Sunday..7=Saturday
    static WeeklyTime := ""    ; HH:mm
    static Chats := ["(Active)", "(New)"]
    static SelectedChat := "(Active)"

    static Load() {
        Cfg.LogEnabled := TimeUtils.Ini("General", "Logging", "0")
        Cfg.ReturnEnabled := TimeUtils.Ini("General", "ReturnAfterScan", "1")
        Cfg.AudioMode := TimeUtils.Ini("General", "AudioMode", "Standard")
        Cfg.TooltipMode := TimeUtils.Ini("General", "TooltipMode", "Always")
        Cfg.TooltipTime := TimeUtils.Ini("General", "TooltipTime", "5")
        Cfg.TtOnTop := TimeUtils.Ini("Tooltip", "AlwaysOnTop", "1")
        Cfg.TtLock := TimeUtils.Ini("Tooltip", "LockPosition", "0")
        Cfg.TtOpacity := TimeUtils.Ini("Tooltip", "Opacity", "225")
        Cfg.TtPosX := TimeUtils.Ini("Tooltip", "PosX", String(A_ScreenWidth - 390))
        Cfg.TtPosY := TimeUtils.Ini("Tooltip", "PosY", String(A_ScreenHeight - 140))
        WindowWidth := TimeUtils.Ini("Window", "Width", "510")
        WindowHeight := TimeUtils.Ini("Window", "Height", "460")
        Cfg.WindowWidth := Max(510, IsNumber(WindowWidth) ? Number(WindowWidth) : 510)
        Cfg.WindowHeight := Max(460, IsNumber(WindowHeight) ? Number(WindowHeight) : 460)
        Cfg.WeeklyDay := TimeUtils.Ini("Weekly", "ResetDay", "")
        Cfg.WeeklyTime := TimeUtils.Ini("Weekly", "ResetTime", "")
        Cfg.SelectedChat := TimeUtils.Ini("Chats", "Selected", "(Active)")
        Cfg.Chats := StrSplit(TimeUtils.Ini("Chats", "ListData", "(Active)|(New)"), "|")
        if (Cfg.Chats.Length < 2 || Cfg.Chats[2] != "(New)")
            Cfg.Chats := ["(Active)", "(New)"]
    }

    static SaveGeneral() {
        TimeUtils.IniSet(Cfg.LogEnabled, "General", "Logging")
        TimeUtils.IniSet(Cfg.ReturnEnabled, "General", "ReturnAfterScan")
        TimeUtils.IniSet(Cfg.AudioMode, "General", "AudioMode")
        TimeUtils.IniSet(Cfg.TooltipMode, "General", "TooltipMode")
        TimeUtils.IniSet(Cfg.TooltipTime, "General", "TooltipTime")
        TimeUtils.IniSet(Cfg.TtOnTop, "Tooltip", "AlwaysOnTop")
        TimeUtils.IniSet(Cfg.TtLock, "Tooltip", "LockPosition")
        TimeUtils.IniSet(Cfg.TtOpacity, "Tooltip", "Opacity")
    }

    static SaveTooltipPos() {
        TimeUtils.IniSet(Cfg.TtPosX, "Tooltip", "PosX")
        TimeUtils.IniSet(Cfg.TtPosY, "Tooltip", "PosY")
    }

    static SaveWeekly() {
        TimeUtils.IniSet(Cfg.WeeklyDay, "Weekly", "ResetDay")
        TimeUtils.IniSet(Cfg.WeeklyTime, "Weekly", "ResetTime")
    }

    static SaveChats() {
        TimeUtils.IniSet(TimeUtils.JoinArray(Cfg.Chats, "|"), "Chats", "ListData")
    }

    static SaveWindowSize(*) {
        TimeUtils.IniSet(Cfg.WindowWidth, "Window", "Width")
        TimeUtils.IniSet(Cfg.WindowHeight, "Window", "Height")
    }
}

; Runtime state of the automation loop
class State {
    static Mode := "Stopped"   ; Stopped | InitialWait | Checking | LimitWait | PostLimitWait
    static TimeLeft := 0
    static TargetResetTime := ""
    static LoopType := "Continuous"   ; Continuous | MaxTimes | UntilTime | ForDuration
    static LoopCounter := 0
    static LoopMax := 5
    static LoopUntil := ""
    static LoopDurationEnd := ""
    static TtKillTime := ""
    static WeeklyWarning := false
}

; =========================================================================
; 2. GENERAL HELPERS
; =========================================================================

class TimeUtils {
    static Ini(Section, Key, Default := "") => IniRead(Cfg.File, Section, Key, Default)

    static IniSet(Value, Section, Key) => IniWrite(Value, Cfg.File, Section, Key)

    static FormatSeconds(Sec) => Format("{:02d}:{:02d}:{:02d}", Floor(Sec / 3600), Floor(Mod(Sec, 3600) / 60), Mod(Sec, 60))

    ; Reads an [H, M, S] array of Edit controls and returns the total seconds
    static GetSeconds(Fields) {
        Total := 0
        for Index, Multiplier in [3600, 60, 1]
            Total += (IsDigit(Fields[Index].Value) ? Number(Fields[Index].Value) : 0) * Multiplier
        return Total
    }

    ; Parses "HH:MM:SS" text into seconds (missing or invalid parts count as 0)
    static ParseDurationSeconds(Text) {
        Parts := StrSplit(Text, ":"), Total := 0
        for Index, Multiplier in [3600, 60, 1]
            if (Index <= Parts.Length && IsDigit(Parts[Index]))
                Total += Number(Parts[Index]) * Multiplier
        return Total
    }

    static JoinArray(Items, Separator) {
        Result := ""
        for Index, Item in Items
            Result .= (Index == 1 ? "" : Separator) Item
        return Result
    }

    static ArrayContains(Items, Value) {
        for Item in Items
            if (Item == Value)
                return true
        return false
    }

    static To24Hour(Hour, AmPm) {
        if (InStr(AmPm, "PM") && Hour < 12)
            return Hour + 12
        if (InStr(AmPm, "AM") && Hour == 12)
            return 0
        return Hour
    }
}

class App {
    static WriteLog(Message) {
        if (Cfg.LogEnabled == "1")
            FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " - " Message "`n", LOG_FILE)
    }

    static TriggerAlert(Message, StandardSound) {
        if (Cfg.AudioMode == "None")
            return
        if (Cfg.AudioMode == "TTS")
            ComObject("SAPI.SpVoice").Speak(Message)
        else
            SoundPlay(StandardSound)
    }

    static CleanExit() {
        ExitApp()
    }

    static Start() {
        Cfg.Load()
        OnExit((ExitReason, ExitCode) => Cfg.SaveWindowSize())
        MainWindow.BuildMainGui()
        MainWindow.LoadTemplates()
        OnMessage(0x0201, StatusTooltip.OnLeftButtonDown.Bind(StatusTooltip))
        MainWindow.Ui.Main.Show("w" Cfg.WindowWidth " h" Cfg.WindowHeight)
    }
}

; =========================================================================
; 3. STATUS TOOLTIP
; =========================================================================

class StatusTooltip {
    static Gui := 0
    static Label := 0
    static LastText := ""

    static Update(Text) {
        Mode := Cfg.TooltipMode
        Expired := (Mode == "Timed" && State.TtKillTime != "" && A_Now >= State.TtKillTime)
        if (Mode == "Never" || Text == "" || Expired)
            return StatusTooltip.Clear()
        if (Mode == "Timed" && Text != StatusTooltip.LastText)
            State.TtKillTime := DateAdd(A_Now, Number(Cfg.TooltipTime), "Seconds")
        if (!StatusTooltip.Gui || Text != StatusTooltip.LastText)
            StatusTooltip.Render(Text)
        StatusTooltip.LastText := Text
    }

    static Clear() {
        if (StatusTooltip.Gui)
            StatusTooltip.Gui.Destroy()
        StatusTooltip.Gui := 0
        StatusTooltip.Label := 0
        StatusTooltip.LastText := ""
    }

    ; Text controls do not resize themselves, so the label is measured and resized by hand
    static Render(Text) {
        ShowOptions := "AutoSize NoActivate"
        if (!StatusTooltip.Gui) {
            StatusTooltip.Create()
            StatusTooltip.Label := StatusTooltip.Gui.Add("Text", , Text)
            ShowOptions := "x" Number(Cfg.TtPosX) " y" Number(Cfg.TtPosY) " " ShowOptions
        } else
            StatusTooltip.Label.Text := Text
        Size := StatusTooltip.MeasureText(StatusTooltip.Label, Text)
        StatusTooltip.Label.Move(, , Size[1], Size[2])
        StatusTooltip.Gui.Show(ShowOptions)
        WinSetTransparent(Number(Cfg.TtOpacity), StatusTooltip.Gui.Hwnd)
    }

    ; Returns [width, height] in DPI-unscaled units, as expected by Control.Move (DT_CALCRECT)
    static MeasureText(Ctrl, Text) {
        DC := DllCall("GetDC", "Ptr", Ctrl.Hwnd, "Ptr")
        OldFont := DllCall("SelectObject", "Ptr", DC, "Ptr", SendMessage(0x31, 0, 0, Ctrl), "Ptr")
        Rect := Buffer(16, 0)
        DllCall("DrawText", "Ptr", DC, "Str", Text, "Int", -1, "Ptr", Rect, "UInt", 0x400 | 0x800)
        DllCall("SelectObject", "Ptr", DC, "Ptr", OldFont)
        DllCall("ReleaseDC", "Ptr", Ctrl.Hwnd, "Ptr", DC)
        Scale := A_ScreenDPI / 96
        return [Ceil(NumGet(Rect, 8, "Int") / Scale), Ceil(NumGet(Rect, 12, "Int") / Scale)]
    }

    static Create() {
        Options := "-Caption +ToolWindow" (Cfg.TtOnTop == "1" ? " +AlwaysOnTop" : "")
        TipGui := Gui(Options)
        TipGui.MarginX := 6, TipGui.MarginY := 6
        TipGui.BackColor := "1E1E1E"
        TipGui.SetFont("s9 cE5E5E0", "Segoe UI")
        StatusTooltip.Gui := TipGui
    }

    static OnLeftButtonDown(WParam, LParam, Msg, Hwnd) {
        if (Cfg.TtLock == "1" || !StatusTooltip.Gui || Hwnd != StatusTooltip.Gui.Hwnd)
            return
        PostMessage(0xA1, 2, , StatusTooltip.Gui.Hwnd)   ; WM_NCLBUTTONDOWN on caption = drag
        KeyWait("LButton")
        if (StatusTooltip.Gui) {
            WinGetPos(&NewX, &NewY, , , StatusTooltip.Gui.Hwnd)
            Cfg.TtPosX := String(NewX), Cfg.TtPosY := String(NewY)
            Cfg.SaveTooltipPos()
        }
    }
}

; =========================================================================
; 4. CLAUDE DESKTOP UI AUTOMATION
; =========================================================================

; --- Window session: activate Claude, then give focus back to the previous window ---
class ClaudeWindow {
    static BeginClaudeSession(PreDelay) {
        Session := {Prev: WinExist("A"), Minimized: (WinGetMinMax(MainWindow.Ui.Main.Hwnd) == -1), Active: false}
        Sleep(PreDelay)
        WinActivate(TARGET_WIN)
        Session.Active := WinWaitActive(TARGET_WIN, , 5) ? true : false
        return Session
    }

    ; The bot window itself is never hidden or forced on top; only the previous window is reactivated
    static EndClaudeSession(Session) {
        Prev := Session.Prev
        if (!Prev || !WinExist("ahk_id " Prev) || Prev == WinExist(TARGET_WIN))
            return
        if (Prev == MainWindow.Ui.Main.Hwnd && Session.Minimized)
            return
        WinActivate(Prev)
    }

    ; --- Basic actions ---
    static ClaudeResetFocus() {
        CoordMode "Mouse", "Window"
        Click(45, 55)
        Sleep(150)
    }

    static ClaudeCopyAllText() {
        SavedClip := ClipboardAll()
        A_Clipboard := ""
        Send("^a")
        Sleep(150)
        Send("^c")
        Text := ClipWait(1.5, 1) ? Trim(A_Clipboard) : ""
        A_Clipboard := SavedClip
        return Text
    }

    static ClaudePasteText(Text) {
        SavedClip := ClipboardAll()
        A_Clipboard := Text
        ClipWait(1)
        Send("^v")
        Sleep(500)
        A_Clipboard := SavedClip
    }

    ; Types the text into the message box of the active chat and sends it
    static ClaudePasteAndSend(Text) {
        CoordMode "Mouse", "Window"
        WinGetPos , , &W, &H, TARGET_WIN
        Click(W / 2, H - 60)
        Sleep(200)
        Send("^a")
        Sleep(100)
        ClaudeWindow.ClaudePasteText(Text)
        Send("{Enter}")
    }

    ; --- Navigation ---
    static ClaudeOpenNewChat() {
        ClaudeWindow.ClaudeResetFocus()
        Send("^n")
        Sleep(250)
    }

    static ClaudeOpenQuickChat() {
        ClaudeWindow.ClaudeResetFocus()
        Send("^k")
        Sleep(250)
    }

    static ClaudeOpenActionWindow() {
        ClaudeWindow.ClaudeOpenQuickChat()
        Send("{Tab}")
        Sleep(150)
    }

    static ClaudeOpenChatListScreen() {
        ClaudeWindow.ClaudeOpenActionWindow()
        Send("{Enter}")
        Sleep(300)
    }

    static ClaudeOpenSpecificChat(ChatName) {
        ClaudeWindow.ClaudeOpenChatListScreen()
        ClaudeWindow.ClaudeResetFocus()
        Loop 4
            Sleep(100), Send("{Tab}")
        A_Clipboard := ""
        A_Clipboard := ChatName
        ClipWait(1)
        Send("^v")
        Sleep(500)
        Send("{Tab}"), Sleep(100), Send("{Tab}"), Sleep(100), Send("{Enter}")
        Sleep(450)
    }

    static ClaudeOpenProjectsListScreen() {
        ClaudeWindow.ClaudeOpenQuickChat()
        Send("{End}")
        Sleep(100)
        Send("{Enter}")
        Sleep(300)
    }

    static ClaudeOpenSpecificProject(ProjectName) {
        ClaudeWindow.ClaudeOpenProjectsListScreen()
        A_Clipboard := ""
        A_Clipboard := ProjectName
        ClipWait(1)
        Send("^v")
        Sleep(350)
        Send("{Tab}"), Sleep(100), Send("{Tab}"), Sleep(100), Send("{Enter}")
        Sleep(450)
    }

    static ClaudeSelectChat(ChatName) {
        if (ChatName == "(New)")
            ClaudeWindow.ClaudeOpenNewChat()
        else if (ChatName != "" && ChatName != "(Active)")
            ClaudeWindow.ClaudeOpenSpecificChat(ChatName)
    }

    ; --- Screen type detection ---
    ; Returns the index of the first/last non-empty line, or 0
    static FirstNonEmptyIndex(Lines) {
        for Index, Line in Lines
            if (Trim(Line) != "")
                return Index
        return 0
    }

    static LastNonEmptyIndex(Lines) {
        Index := Lines.Length
        while (Index > 0) {
            if (Trim(Lines[Index]) != "")
                return Index
            Index--
        }
        return 0
    }

    static ClaudeGetScreenType() {
        ClaudeWindow.ClaudeResetFocus()
        Content := ClaudeWindow.ClaudeCopyAllText()
        if (Content == "")
            return "Unidentified"
        Lines := StrSplit(Content, "`n", "`r")
        ScreenType := ClaudeWindow.ClassifyByFooter(Lines)
        if (ScreenType == "")
            ScreenType := ClaudeWindow.ClassifyByHeader(Lines)
        ClaudeWindow.ClaudeResetFocus()
        return (ScreenType != "") ? ScreenType : "Unidentified"
    }

    static ClassifyByFooter(Lines) {
        Index := ClaudeWindow.LastNonEmptyIndex(Lines)
        if (!Index)
            return ""
        Footer := Trim(Lines[Index])
        if InStr(Footer, "How can I help you today?") || InStr(Footer, "Type / for skills")
            return "NewChat"
        if InStr(Footer, "Claude is AI and can make mistakes") || InStr(Footer, "Please double-check responses")
            return "SpecificChat|" ClaudeWindow.ClaudeGetOpenChatName()
        return ""
    }

    static ClassifyByHeader(Lines) {
        Index := ClaudeWindow.FirstNonEmptyIndex(Lines)
        if (!Index)
            return ""
        Header := Trim(Lines[Index])
        if (Header == "Chats")
            return "ChatsList"
        if (Header == "Projects")
            return "ProjectsList"
        if (Header == "/") {
            NextIndex := Index + 1
            while (NextIndex <= Lines.Length && Trim(Lines[NextIndex]) == "")
                NextIndex++
            return "SpecificProject|" (NextIndex <= Lines.Length ? Trim(Lines[NextIndex]) : "")
        }
        return ""
    }

    static ClaudeGetOpenChatName() {
        ClaudeWindow.ClaudeOpenActionWindow()
        Send("{Tab}")
        if RegExMatch(ClaudeWindow.ClaudeCopyAllText(), "i)Delete\s+“([^”]+)”", &Match)
            return Trim(Match[1])
        return ""
    }

    static ClaudeReturnToPreviousScreen(PreviousState) {
        ClaudeWindow.ClaudeResetFocus()
        if (PreviousState == "NewChat")
            return ClaudeWindow.ClaudeOpenNewChat()
        if (PreviousState == "ChatsList")
            return ClaudeWindow.ClaudeOpenChatListScreen()
        if (PreviousState == "ProjectsList")
            return ClaudeWindow.ClaudeOpenProjectsListScreen()
        if !InStr(PreviousState, "|")
            return
        Parts := StrSplit(PreviousState, "|")
        if (Parts[2] == "")
            return
        if (Parts[1] == "SpecificChat")
            ClaudeWindow.ClaudeOpenSpecificChat(Parts[2])
        else if (Parts[1] == "SpecificProject")
            ClaudeWindow.ClaudeOpenSpecificProject(Parts[2])
    }

    ; --- Chat list scanning ---
    static ParseChatNames(WindowContent) {
        Chats := ["(Active)", "(New)"]
        LineIndex := 0
        Loop Parse, WindowContent, "`n", "`r" {
            Line := Trim(A_LoopField)
            if (Line == "")
                continue
            LineIndex++
            if (LineIndex <= 2 || Line == "Chats" || Line == "Search chats..." || Mod(LineIndex, 2) == 0)
                continue
            if RegExMatch(Line, "i)(You\s+are\s+out|free\s+messages|Star|Settings|Help|Claude|View\s+all|Recents)")
                continue
            if (!TimeUtils.ArrayContains(Chats, Line) && StrLen(Line) < 60)
                Chats.Push(Line)
        }
        return Chats
    }

    static ClaudeFetchChatsToDropDownList() {
        ClaudeWindow.ClaudeOpenChatListScreen()
        ClaudeWindow.ClaudeResetFocus()
        WindowContent := ClaudeWindow.ClaudeCopyAllText()
        if (WindowContent == "")
            return
        Cfg.Chats := ClaudeWindow.ParseChatNames(WindowContent)
        Cfg.SaveChats()
        MainWindow.Ui.Chats.Delete(), MainWindow.Ui.Chats.Add(Cfg.Chats), MainWindow.Ui.Chats.Choose(1)
    }

    static ScanClaudeChats(*) {
        if !WinExist(TARGET_WIN) {
            MsgBox(TX["MsgErrClaude"], "Error", "Icon!")
            return
        }
        Session := ClaudeWindow.BeginClaudeSession(150)
        if (Session.Active) {
            Sleep(200)
            ClaudeWindow.ScanChatsInActiveWindow()
        }
        ClaudeWindow.EndClaudeSession(Session)
    }

    static ScanChatsInActiveWindow() {
        PreviousScreen := (Cfg.ReturnEnabled == "1") ? ClaudeWindow.ClaudeGetScreenType() : ""
        ClaudeWindow.ClaudeFetchChatsToDropDownList()
        if (Cfg.ReturnEnabled == "1")
            ClaudeWindow.ClaudeReturnToPreviousScreen(PreviousScreen)
        else
            ClaudeWindow.ClaudeResetFocus()
    }
}

; =========================================================================
; 5. LIMIT DETECTION
; =========================================================================

; Reads the conversation text of the active Claude window, reduced to plain ASCII
class ClaudeChecker {
    static ReadConversationText() {
        ClaudeWindow.ClaudeResetFocus()
        WinGetPos , , &W, &H, TARGET_WIN
        Click(W / 2, H / 2)
        Sleep(300)
        Raw := ClaudeWindow.ClaudeCopyAllText()
        Sleep(250)
        if (Raw == "")
            return ""
        return RegExReplace(RegExReplace(Raw, "[^\x00-\x7F]+", " "), "\s+", " ")
    }

    ; "out of free messages ... until Mar 5 at 6:00 AM" -> yyyyMMddHHmmss, or "" when absent
    static ParseWeeklyLimit(Text) {
        ; Every pattern captures: 1 month, 2 day, 3 time, 4 AM/PM. Add new message wordings here.
        Patterns := [
            "i)out\s+of\s+free\s+messages.{1,200}?until\s+([a-z]{3})\s+([0-9]{1,2})\s+at\s+([0-9]{1,2}:[0-9]{2})(\s*[AP]M)?",
            "i)free\s+usage\s+returns\s+([a-z]{3})[a-z]*\.?\s+([0-9]{1,2})(?:st|nd|rd|th)?,?\s+at\s+([0-9]{1,2}:[0-9]{2})(\s*[AP]M)?"
        ]
        Match := ""
        for Pattern in Patterns {
            if RegExMatch(Text, Pattern, &Match)
                break
            Match := ""
        }
        if (Match == "")
            return ""
        Months := Map("jan", "01", "feb", "02", "mar", "03", "apr", "04", "may", "05", "jun", "06"
            , "jul", "07", "aug", "08", "sep", "09", "oct", "10", "nov", "11", "dec", "12")
        MonthKey := Format("{:L}", Match[1])
        MonthNum := Months.Has(MonthKey) ? Months[MonthKey] : FormatTime(, "MM")
        TimeParts := StrSplit(Match[3], ":")
        HourNum := Format("{:02d}", TimeUtils.To24Hour(Number(TimeParts[1]), Match[4]))
        Suffix := MonthNum Format("{:02d}", Number(Match[2])) HourNum TimeParts[2] "00"
        Stamp := FormatTime(, "yyyy") Suffix
        if (Stamp < FormatTime(, "yyyyMMddHHmmss"))
            Stamp := (Number(FormatTime(, "yyyy")) + 1) Suffix
        return Stamp
    }

    ; "out of free messages ... until 6:00 AM" -> "HH:mm", or "" when absent
    static ParseHourlyLimit(Text) {
        ; Every pattern captures: 1 time, 2 AM/PM. Add new message wordings here.
        Patterns := [
            "i)out\s+of\s+free\s+messages.{1,200}?until\s+([0-9]{1,2}:[0-9]{2})(\s*[AP]M)?",
            "i)out\s+of\s+free\s+messages.{1,200}?until\s+tomorrow\s+at\s+([0-9]{1,2}:[0-9]{2})(\s*[AP]M)?",
            "i)free\s+usage\s+returns\s+(?:tomorrow\s+)?(?:at\s+)?([0-9]{1,2}:[0-9]{2})(\s*[AP]M)?"
        ]
        Match := ""
        for Pattern in Patterns {
            if RegExMatch(Text, Pattern, &Match)
                break
            Match := ""
        }
        if (Match == "")
            return ""
        if (Match[2] == "")
            return Match[1]
        TimeParts := StrSplit(Match[1], ":")
        return Format("{:02d}:{}", TimeUtils.To24Hour(Number(TimeParts[1]), Match[2]), TimeParts[2])
    }

    static CheckClaude() {
        if !WinExist(TARGET_WIN)
            return
        Session := ClaudeWindow.BeginClaudeSession(250)
        if (Session.Active) {
            Sleep(350)
            Text := ClaudeChecker.ReadConversationText()
            if (Text != "")
                ClaudeChecker.ProcessLimitText(Text)
        }
        ClaudeWindow.EndClaudeSession(Session)
    }

    static ProcessLimitText(Text) {
        State.WeeklyWarning := RegExMatch(Text, "i)used\s+75%\s+of\s+your\s+weekly\s+limit") > 0
        if (State.WeeklyWarning)
            App.WriteLog("Warning detected: You have used 75% of your weekly limit.")

        if ((Stamp := ClaudeChecker.ParseWeeklyLimit(Text)) != "")
            ClaudeChecker.OnWeeklyLimit(Stamp)
        else if ((Clock := ClaudeChecker.ParseHourlyLimit(Text)) != "")
            ClaudeChecker.OnHourlyLimit(Clock)
        else if RegExMatch(Text, "i)Claude\s+reached\s+its\s+tool-use\s+limit\s+for\s+this\s+turn\.")
            ClaudeChecker.OnToolUseLimit()
    }

    static OnWeeklyLimit(Stamp) {
        State.TargetResetTime := Stamp
        if (DateDiff(Stamp, A_Now, "Seconds") > 5 * 3600)
            ClaudeChecker.RecordWeeklyReset(Stamp)
        State.Mode := "LimitWait"
        App.WriteLog("Long-term Limit detected: " Stamp)
        App.TriggerAlert("Claude weekly limit reached!", "*48")
    }

    static OnHourlyLimit(Clock) {
        State.TargetResetTime := Clock
        State.Mode := "LimitWait"
        App.WriteLog("Short-term Limit detected: " Clock)
        App.TriggerAlert("Claude limit reached!", "*48")
    }

    ; The 30-minute per-turn limit message disappears once "Continue" is sent
    static OnToolUseLimit() {
        App.WriteLog("Tool-use limit for this turn detected. Sending 'Continue'.")
        ClaudeWindow.ClaudePasteAndSend("Continue")
        Sleep(400)
        App.TriggerAlert("Claude turn limit reached - sent Continue.", "*64")
    }

    ; --- Weekly reset hint ---
    static WeeklyHintText() {
        Day := Cfg.WeeklyDay
        if (!IsInteger(Day) || Day < 1 || Day > 7 || Cfg.WeeklyTime == "")
            return TX["HintWeeklyNone"]
        return TX["HintWeekly"] TX["Days"][Integer(Day)] " " Cfg.WeeklyTime
    }

    static RecordWeeklyReset(Stamp) {
        NewDay := FormatTime(Stamp, "WDay")
        NewTime := FormatTime(Stamp, "HH:mm")
        if (NewDay == Cfg.WeeklyDay && NewTime == Cfg.WeeklyTime)
            return
        Previous := (Cfg.WeeklyDay == "") ? "recorded" : "changed (" Cfg.WeeklyDay " " Cfg.WeeklyTime ")"
        App.WriteLog("Weekly reset schedule " Previous ": " NewDay " " NewTime)
        Cfg.WeeklyDay := NewDay, Cfg.WeeklyTime := NewTime
        Cfg.SaveWeekly()
        if HasProp(MainWindow.Ui, "WeeklyHint")
            MainWindow.Ui.WeeklyHint.Text := ClaudeChecker.WeeklyHintText()
    }
}

; =========================================================================
; 6. AUTOMATION LOOP
; =========================================================================

class TickLoop {
    static TimerCallback := (*) => TickLoop.MainTick()

    static SetActionButton(Running) {
        ControlSetText(Running ? "◼ " TX["BtnStop"] : "▶ " TX["BtnStart"], MainWindow.Ui.Action.Hwnd)
    }

    static SaveInputCache() {
        for Prefix, Fields in Map("Init", MainWindow.Ui.Init, "Check", MainWindow.Ui.Check, "Post", MainWindow.Ui.Post)
            for Index, Letter in ["H", "M", "S"]
                TimeUtils.IniSet(Fields[Index].Value, "Cache", Prefix Letter)
        TimeUtils.IniSet(MainWindow.Ui.Message.Value, "Cache", "MsgText")
        TimeUtils.IniSet(MainWindow.Ui.Chats.Text, "Chats", "Selected")
    }

    static ConfigureLoopMode() {
        if (MainWindow.Ui.OptMax.Value) {
            State.LoopType := "MaxTimes", State.LoopCounter := 0
            State.LoopMax := IsDigit(MainWindow.Ui.MaxTimes.Value) ? Number(MainWindow.Ui.MaxTimes.Value) : 5
        } else if (MainWindow.Ui.OptUntil.Value) {
            State.LoopType := "UntilTime", State.LoopUntil := MainWindow.Ui.UntilTime.Value
        } else if (MainWindow.Ui.OptFor.Value) {
            State.LoopType := "ForDuration"
            State.LoopDurationEnd := DateAdd(A_Now, TimeUtils.ParseDurationSeconds(MainWindow.Ui.ForDuration.Value), "Seconds")
        } else
            State.LoopType := "Continuous"
    }

    static StartAutomation(*) {
        if !WinExist(TARGET_WIN) {
            MsgBox(TX["MsgErrClaude"], "Error", "Icon!")
            return
        }
        CheckSec := TimeUtils.GetSeconds(MainWindow.Ui.Check)
        if (CheckSec <= 0) {
            MsgBox(TX["MsgErrFreq"], "Error", 16)
            return
        }
        TickLoop.SetActionButton(true)
        TickLoop.SaveInputCache()
        TickLoop.ConfigureLoopMode()

        InitSec := TimeUtils.GetSeconds(MainWindow.Ui.Init)
        State.TargetResetTime := ""
        State.TtKillTime := DateAdd(A_Now, Number(Cfg.TooltipTime), "Seconds")
        State.Mode := (InitSec > 0) ? "InitialWait" : "Checking"
        State.TimeLeft := (InitSec > 0) ? InitSec : CheckSec
        if (State.Mode == "Checking")
            ClaudeChecker.CheckClaude()
        SetTimer(TickLoop.TimerCallback, 1000)
        App.WriteLog("Automation Started. Mode: " State.LoopType)
    }

    static StopAutomation(*) {
        State.Mode := "Stopped"
        SetTimer(TickLoop.TimerCallback, 0)
        StatusTooltip.Clear()
        TickLoop.SetActionButton(false)
        App.WriteLog("Automation Stopped.")
    }

    static ActionButtonHandler(*) {
        if (State.Mode == "Stopped")
            TickLoop.StartAutomation()
        else {
            TickLoop.StopAutomation()
            MsgBox(TX["MsgStop"], "Stop", 48)
        }
    }

    ; Returns true (and logs the reason) when the configured repetition boundary was reached
    static LoopBoundaryReached() {
        if (State.LoopType == "UntilTime" && FormatTime(, "HH:mm:ss") >= State.LoopUntil) {
            App.WriteLog("Boundary Hour Target reached.")
            return true
        }
        if (State.LoopType == "ForDuration" && A_Now >= State.LoopDurationEnd) {
            App.WriteLog("Boundary Duration Constraint elapsed.")
            return true
        }
        return false
    }

    static BuildRepetitionInfo() {
        Info := ""
        if (State.LoopType == "MaxTimes")
            Info := TX["RepsInfo"] (State.LoopMax - State.LoopCounter) TX["RepsLeft"]
        if (State.WeeklyWarning)
            Info .= TX["WeeklyWarning"]
        return Info
    }

    static MainTick() {
        if (State.Mode == "Stopped")
            return
        if !WinExist(TARGET_WIN) {
            App.WriteLog("Watchdog trigger: Claude window closed.")
            return TickLoop.StopAutomation()
        }
        if (TickLoop.LoopBoundaryReached())
            return TickLoop.StopAutomation()

        Info := TickLoop.BuildRepetitionInfo()
        switch State.Mode {
            case "InitialWait": TickLoop.TickInitialWait(Info)
            case "Checking": TickLoop.TickChecking(Info)
            case "LimitWait": TickLoop.TickLimitWait(Info)
            case "PostLimitWait": TickLoop.TickPostLimitWait(Info)
        }
    }

    static TickInitialWait(Info) {
        State.TimeLeft--
        StatusTooltip.Update(TX["StatusInit"] TimeUtils.FormatSeconds(State.TimeLeft) Info)
        if (State.TimeLeft <= 0) {
            State.Mode := "Checking"
            State.TimeLeft := TimeUtils.GetSeconds(MainWindow.Ui.Check)
            ClaudeChecker.CheckClaude()
        }
    }

    static TickChecking(Info) {
        State.TimeLeft--
        NextCheck := FormatTime(DateAdd(A_Now, State.TimeLeft, "Seconds"), "HH:mm:ss")
        StatusTooltip.Update(TX["StatusCheck"] NextCheck " (in " TimeUtils.FormatSeconds(State.TimeLeft) ")" Info)
        if (State.TimeLeft <= 0) {
            State.TimeLeft := TimeUtils.GetSeconds(MainWindow.Ui.Check)
            ClaudeChecker.CheckClaude()
        }
    }

    static TickLimitWait(Info) {
        Remaining := TickLoop.SecondsUntilReset()
        if (Remaining <= 0)
            return TickLoop.BeginPostLimitWait()
        StatusTooltip.Update(TickLoop.LimitStatusText(Remaining) Info)
    }

    static TickPostLimitWait(Info) {
        State.TimeLeft--
        StatusTooltip.Update(TX["StatusPost"] TimeUtils.FormatSeconds(State.TimeLeft) Info)
        if (State.TimeLeft <= 0)
            TickLoop.SendMessageToClaude()
    }

    ; Reset time is either a full 14-digit timestamp (weekly limit) or "HH:mm" (hourly limit)
    static SecondsUntilReset() {
        Target := State.TargetResetTime
        if (StrLen(Target) == 14)
            return DateDiff(Target, A_Now, "Seconds")
        Now := (A_Hour * 3600) + (A_Min * 60) + A_Sec
        Parts := StrSplit(Target, ":")
        TargetSec := (Number(Parts[1]) * 3600) + (Number(Parts[2]) * 60)
        if (TargetSec < Now)
            TargetSec += 86400
        return TargetSec - Now
    }

    static LimitStatusText(Remaining) {
        Target := State.TargetResetTime
        if (StrLen(Target) != 14)
            return TX["StatusLimitUntil"] Target "`n" TX["Remaining"] TimeUtils.FormatSeconds(Remaining)
        if (Remaining <= 86400)
            return TX["StatusLimitUntil"] FormatTime(Target, "HH:mm") "`n" TX["Remaining"] TimeUtils.FormatSeconds(Remaining)
        DaysText := Floor(Remaining / 86400) " days, "
        return TX["StatusLimit"] FormatTime(Target, "yyyy-MM-dd HH:mm") "`n" TX["Remaining"] DaysText TimeUtils.FormatSeconds(Mod(Remaining, 86400))
    }

    static BeginPostLimitWait() {
        PostSec := TimeUtils.GetSeconds(MainWindow.Ui.Post)
        if (PostSec > 0) {
            State.Mode := "PostLimitWait"
            State.TimeLeft := PostSec
        } else
            TickLoop.SendMessageToClaude()
    }

    ; Sends the configured message once the limit is lifted, then restarts the monitoring cycle
    static SendMessageToClaude() {
        if WinExist(TARGET_WIN)
            TickLoop.DeliverMessage()
        if (State.LoopType == "MaxTimes") {
            State.LoopCounter++
            if (State.LoopCounter >= State.LoopMax) {
                App.WriteLog("Counter Boundary Reached.")
                return TickLoop.StopAutomation()
            }
        }
        TickLoop.RestartCycle()
        App.TriggerAlert("Claude unlocked.", "*64")
    }

    static DeliverMessage() {
        Session := ClaudeWindow.BeginClaudeSession(150)
        if (Session.Active) {
            Sleep(300)
            ChatName := MainWindow.Ui.Chats.Text
            ClaudeWindow.ClaudeSelectChat(ChatName)
            ClaudeWindow.ClaudePasteAndSend(MainWindow.Ui.Message.Value)
            App.WriteLog("Message sent to chat: " ChatName)
            SoundBeep(500, 200)
            Sleep(400)
        }
        ClaudeWindow.EndClaudeSession(Session)
    }

    static RestartCycle() {
        InitSec := TimeUtils.GetSeconds(MainWindow.Ui.Init)
        State.Mode := (InitSec > 0) ? "InitialWait" : "Checking"
        State.TimeLeft := (InitSec > 0) ? InitSec : TimeUtils.GetSeconds(MainWindow.Ui.Check)
        State.TtKillTime := DateAdd(A_Now, Number(Cfg.TooltipTime), "Seconds")
    }
}

; =========================================================================
; 7. MAIN WINDOW
; =========================================================================

; Delayed hover hints for buttons (text or a function returning text)
class Hints {
    static Items := Map()
    static LastHwnd := 0
    static ShowCallback := (*) => Hints.Show()

    static Add(Ctrl, Text) {
        Hints.Items[Ctrl.Hwnd] := Text
    }

    static OnMouseMove(*) {
        MouseGetPos(, , , &Ctl, 2)
        if (Ctl == Hints.LastHwnd)
            return
        Hints.Hide()
        Hints.LastHwnd := Ctl
        if Hints.Items.Has(Ctl)
            SetTimer(Hints.ShowCallback, -500)
    }

    static Show() {
        if !Hints.Items.Has(Hints.LastHwnd)
            return
        Text := Hints.Items[Hints.LastHwnd]
        ToolTip(Text is Func ? Text() : Text, , , 20)
    }

    static Hide(*) {
        SetTimer(Hints.ShowCallback, 0)
        ToolTip(, , , 20)
        Hints.LastHwnd := 0
    }
}

class MainWindow {
    static Ui := {}
    
    static BuildMainGui() {
        MainWindow.Ui.Main := Gui("+Resize +MinSize510x460", TX["Title"])
        MainWindow.Ui.Main.OnEvent("Close", (*) => App.CleanExit())
        MainWindow.Ui.Main.OnEvent("Size", (GuiObj, MinMax, Width, Height) => MainWindow.OnMainResize(GuiObj, MinMax, Width, Height))
        if FileExist(FAVICON_PATH)
            MainWindow.Ui.Main.SetIcon(FAVICON_PATH)
        MainWindow.Ui.Main.SetFont("s9", "Segoe UI")
    
        MainWindow.Ui.Init := MainWindow.AddTimeGroup(TX["DelayGroup"], 10, "Init", ["00", "00", "5"])
        MainWindow.Ui.Check := MainWindow.AddTimeGroup(TX["FreqGroup"], 65, "Check", ["00", "00", "30"])
        MainWindow.Ui.Post := MainWindow.AddTimeGroup(TX["PostGroup"], 120, "Post", ["00", "00", "5"])
        MainWindow.AddRepeatGroup()
        MainWindow.AddChatGroup()
        MainWindow.AddTemplateGroup()
        MainWindow.AddActionRow()
        MainWindow.BindMainEvents()
    }
    
    ; Adds a group box with HH:MM:SS fields; returns the [H, M, S] Edit controls
    static AddTimeGroup(Title, Y, Prefix, Defaults) {
        MainWindow.Ui.Main.Add("GroupBox", "x10 y" Y " w235 h50", Title)
        Fields := []
        for Index, Letter in ["H", "M", "S"] {
            X := 20 + (Index - 1) * 55
            Value := TimeUtils.Ini("Cache", Prefix Letter, Defaults[Index])
            Fields.Push(MainWindow.Ui.Main.Add("Edit", "x" X " y" (Y + 20) " w40 h20 Limit2 Center", Value))
            if (Index < 3)
                MainWindow.Ui.Main.Add("Text", "x" (X + 45) " y" (Y + 23) " w10 h20", ":")
        }
        return Fields
    }
    
    static AddRepeatGroup() {
        MainWindow.Ui.Main.Add("GroupBox", "x255 y10 w245 h160", TX["RepeatGroup"])
        MainWindow.Ui.OptCont := MainWindow.Ui.Main.Add("Radio", "x265 y30 w155 h20", TX["OptCont"])
        MainWindow.Ui.OptMax := MainWindow.Ui.Main.Add("Radio", "x265 y55 w155 h20", TX["OptMax"])
        MainWindow.Ui.MaxTimes := MainWindow.Ui.Main.Add("Edit", "x425 y53 w65 h20 Number Center", TimeUtils.Ini("Cache", "MaxReps", "5"))
        MainWindow.Ui.OptUntil := MainWindow.Ui.Main.Add("Radio", "x265 y80 w155 h20", TX["OptUntil"])
        MainWindow.Ui.UntilTime := MainWindow.Ui.Main.Add("Edit", "x425 y78 w65 h20 Center", TimeUtils.Ini("Cache", "UntilT", "12:00:00"))
        MainWindow.Ui.OptFor := MainWindow.Ui.Main.Add("Radio", "x265 y105 w155 h20", TX["OptFor"])
        MainWindow.Ui.ForDuration := MainWindow.Ui.Main.Add("Edit", "x425 y103 w65 h20 Center", TimeUtils.Ini("Cache", "ForD", "01:00:00"))
    
        switch TimeUtils.Ini("Cache", "RepeatType", "Continuous") {
            case "MaxTimes": MainWindow.Ui.OptMax.Value := 1
            case "UntilTime": MainWindow.Ui.OptUntil.Value := 1
            case "ForDuration": MainWindow.Ui.OptFor.Value := 1
            default: MainWindow.Ui.OptCont.Value := 1
        }
    }
    
    static AddChatGroup() {
        MainWindow.Ui.ChatGroup := MainWindow.Ui.Main.Add("GroupBox", "x10 y180 w490 h60", TX["ChatGroup"])
        MainWindow.Ui.Chats := MainWindow.Ui.Main.Add("DropDownList", "x20 y203 w350 Choose1", Cfg.Chats)
        for Index, ChatName in Cfg.Chats {
            if (ChatName == Cfg.SelectedChat) {
                MainWindow.Ui.Chats.Choose(Index)
                break
            }
        }
        MainWindow.Ui.Scan := MainWindow.Ui.Main.Add("Button", "x380 y201 w110 h24", TX["BtnScan"])
        Hints.Add(MainWindow.Ui.Scan, TX["HintScan"])
    }
    
    static AddTemplateGroup() {
        MainWindow.Ui.TemplateGroup := MainWindow.Ui.Main.Add("GroupBox", "x10 y250 w490 h130", TX["MsgGroup"])
        MainWindow.Ui.Templates := MainWindow.Ui.Main.Add("DropDownList", "x20 y272 w250 Choose1", ["Default"])
        MainWindow.Ui.TplAdd := MainWindow.Ui.Main.Add("Button", "x280 y271 w35 h24", "➕")
        MainWindow.Ui.TplSave := MainWindow.Ui.Main.Add("Button", "x320 y271 w35 h24 Disabled", "💾")
        MainWindow.Ui.TplDelete := MainWindow.Ui.Main.Add("Button", "x360 y271 w35 h24 Disabled", "❌")
                Hints.Add(MainWindow.Ui.TplAdd, TX["HintTplAdd"])
                Hints.Add(MainWindow.Ui.TplSave, TX["HintTplSave"])
                Hints.Add(MainWindow.Ui.TplDelete, TX["HintTplDelete"])
                MainWindow.Ui.Message := MainWindow.Ui.Main.Add("Edit", "x20 y303 w470 h65 Multi WantReturn", TimeUtils.Ini("Cache", "MsgText", "Continue"))
    }
    
    static AddActionRow() {
        MainWindow.Ui.Action := MainWindow.Ui.Main.Add("Button", "x10 y390 w320 h40 Default", "▶ " TX["BtnStart"])
        MainWindow.Ui.Options := MainWindow.Ui.Main.Add("Button", "x350 y390 w150 h40", TX["BtnOptions"])
        Hints.Add(MainWindow.Ui.Action, (*) => State.Mode == "Stopped" ? TX["HintStart"] : TX["HintStop"])
        Hints.Add(MainWindow.Ui.Options, TX["HintOptions"])
        MainWindow.Ui.CloseHint := MainWindow.Ui.Main.Add("Text", "x10 y435 w250 h18", TX["HintClose"])
        MainWindow.Ui.WeeklyHint := MainWindow.Ui.Main.Add("Text", "x260 y435 w240 h18 Right", ClaudeChecker.WeeklyHintText())
    }

    static OnMainResize(GuiObj, MinMax, Width, Height) {
        if (MinMax == -1)
            return

        if (MinMax == 0) {
            Cfg.WindowWidth := Max(510, Width)
            Cfg.WindowHeight := Max(460, Height)
        }

        MainWindow.Ui.ChatGroup.Move(, , Width - 20)
        MainWindow.Ui.Chats.Move(, , Width - 160)
        MainWindow.Ui.Scan.Move(Width - 130)
        MainWindow.Ui.TemplateGroup.Move(, , Width - 20, Height - 330)
        MainWindow.Ui.Message.Move(, , Width - 40, Height - 395)
        MainWindow.Ui.Action.Move(, Height - 70)
        MainWindow.Ui.Options.Move(Width - 160, Height - 70)
        MainWindow.Ui.CloseHint.Move(, Height - 25)
        MainWindow.Ui.WeeklyHint.Move(Width - 250, Height - 25)
    }
    
    static BindMainEvents() {
        MainWindow.Ui.Message.OnEvent("Change", (*) => MainWindow.Ui.TplSave.Enabled := true)
        MainWindow.Ui.Templates.OnEvent("Change", (*) => MainWindow.OnTemplateSelected())
        MainWindow.Ui.TplAdd.OnEvent("Click", (*) => MainWindow.AddTemplateHandler())
        MainWindow.Ui.TplSave.OnEvent("Click", (*) => MainWindow.SaveTemplateHandler())
        MainWindow.Ui.TplDelete.OnEvent("Click", (*) => MainWindow.DeleteTemplateHandler(true))
        OnMessage(0x0200, Hints.OnMouseMove.Bind(Hints))
        OnMessage(0x0201, Hints.Hide.Bind(Hints))
        MainWindow.Ui.Action.OnEvent("Click", (*) => TickLoop.ActionButtonHandler())
        MainWindow.Ui.Options.OnEvent("Click", (*) => SettingsWindow.OpenSettingsWindow())
        MainWindow.Ui.Scan.OnEvent("Click", (*) => ClaudeWindow.ScanClaudeChats())

        HotIfWinActive("ahk_id " MainWindow.Ui.Main.Hwnd)
        Hotkey("^s", (*) => MainWindow.Ui.TplSave.Enabled ? MainWindow.SaveTemplateHandler() : 0)
        Hotkey("^n", (*) => MainWindow.AddTemplateHandler())
        Hotkey("^Delete", (*) => MainWindow.DeleteTemplateHandler(true))
        Hotkey("^+Delete", (*) => MainWindow.DeleteTemplateHandler(false))
        Hotkey("^o", (*) => SettingsWindow.OpenSettingsWindow())
        Hotkey("^+s", (*) => ClaudeWindow.ScanClaudeChats())
        HotIfWinActive()
    }
    
    ; =========================================================================
    ; 8. MESSAGE TEMPLATES
    ; =========================================================================
    
    static ReadTemplateNames() {
        Names := []
        Loop Parse, IniRead(Cfg.File, "Templates", , ""), "`n", "`r" {
            if (A_LoopField == "")
                continue
            Name := Trim(StrSplit(A_LoopField, "=")[1])
            if (Name != "")
                Names.Push(Name)
        }
        return Names
    }
    
    static LoadTemplates() {
        MainWindow.Ui.Templates.Delete()
        Names := MainWindow.ReadTemplateNames()
        if (Names.Length == 0) {
            TimeUtils.IniSet("Continue", "Templates", "(Default)")
            MainWindow.Ui.Templates.Add(["(Default)"]), MainWindow.Ui.Templates.Choose(1)
            return
        }
        MainWindow.Ui.Templates.Add(Names), MainWindow.Ui.Templates.Choose(1)
        MainWindow.OnTemplateSelected()
    }
    
    static OnTemplateSelected(*) {
        Name := MainWindow.Ui.Templates.Text
        if (Name == "")
            return
        ; Newlines are stored as [NL] because INI values are single-line
        MainWindow.Ui.Message.Value := StrReplace(TimeUtils.Ini("Templates", Name, "Continue"), "[NL]", "`n")
        MainWindow.Ui.TplDelete.Enabled := (Name != "(Default)")
        MainWindow.Ui.TplSave.Enabled := false
    }
    
    static SaveTemplateHandler(*) {
        Text := StrReplace(MainWindow.Ui.Message.Value, "`r`n", "[NL]")
        Text := StrReplace(StrReplace(Text, "`n", "[NL]"), "`r", "[NL]")
        TimeUtils.IniSet(Text, "Templates", MainWindow.Ui.Templates.Text)
        SoundBeep(400, 100)
        MainWindow.Ui.TplSave.Enabled := false
    }
    
    static DeleteTemplateHandler(Confirm := false) {
        Name := MainWindow.Ui.Templates.Text
        if (Name == "(Default)" || !MainWindow.Ui.TplDelete.Enabled)
            return
        if (Confirm is Integer && Confirm && MsgBox(Format(TX["ConfirmDelete"], Name), TX["Title"], "YesNo Icon?") != "Yes")
            return
        IniDelete(Cfg.File, "Templates", MainWindow.Ui.Templates.Text)
        MainWindow.LoadTemplates()
    }
    
    static AddTemplateHandler(*) {
        Name := MainWindow.PromptTemplateName()
        if (Name == "")
            return
        MainWindow.SetMainRedraw(false)
        TimeUtils.IniSet("", "Templates", Name)
        MainWindow.LoadTemplates()
        for Index, ItemText in ControlGetItems(MainWindow.Ui.Templates.Hwnd) {
            if (ItemText == Name) {
                MainWindow.Ui.Templates.Choose(Index)
                break
            }
        }
        MainWindow.Ui.Message.Value := ""
        MainWindow.Ui.TplSave.Enabled := false
        MainWindow.Ui.TplDelete.Enabled := (Name != "Default")
        MainWindow.SetMainRedraw(true)
        WinRedraw(MainWindow.Ui.Main.Hwnd)
    }
    
    static SetMainRedraw(Enabled) {
        DllCall("user32\SendMessage", "Ptr", MainWindow.Ui.Main.Hwnd, "UInt", 11, "Ptr", Enabled ? 1 : 0, "Ptr", 0)
    }
    
    ; Modal dialog; returns the trimmed name or "" when cancelled
    static PromptTemplateName() {
        Result := {Name: ""}
        Dlg := Gui("+Owner" MainWindow.Ui.Main.Hwnd " -MinimizeBox -MaximizeBox +ToolWindow", TX["TplTitle"])
        if FileExist(FAVICON_PATH)
            Dlg.SetIcon(FAVICON_PATH)
        Dlg.SetFont("s9", "Segoe UI")
        Dlg.Add("Text", "x15 y15 w220 h20", TX["TplPrompt"])
        NameEdit := Dlg.Add("Edit", "x15 y35 w220 h23")
        OkButton := Dlg.Add("Button", "x45 y70 w75 h28 Default", "OK")
        CancelButton := Dlg.Add("Button", "x130 y70 w75 h28", TX["BtnCancel"])
        Hints.Add(OkButton, TX["HintOk"])
        Hints.Add(CancelButton, TX["HintCancel"])
    
        OkButton.OnEvent("Click", (*) => (Result.Name := Trim(NameEdit.Value), Dlg.Destroy()))
        CancelButton.OnEvent("Click", (*) => Dlg.Destroy())
        Dlg.OnEvent("Close", (*) => Dlg.Destroy())
        Dlg.Show("w250 h115")
        WinWaitClose(Dlg.Hwnd)
        return Result.Name
    }
    
}
; =========================================================================
; 9. SETTINGS WINDOW
; =========================================================================
; =========================================================================

class SettingsWindow {
    static OpenSettingsWindow(*) {
        MainWindow.Ui.Set := {}
        MainWindow.Ui.Set.Gui := Gui("+Owner" MainWindow.Ui.Main.Hwnd " +MinSize440x315 +MaxSize440x315", TX["SetTitle"])
        MainWindow.Ui.Set.Gui.OnEvent("Close", (*) => SettingsWindow.CloseSettingsWindow())
        if FileExist(FAVICON_PATH)
            MainWindow.Ui.Set.Gui.SetIcon(FAVICON_PATH)
        MainWindow.Ui.Set.Gui.SetFont("s9", "Segoe UI")

        SettingsWindow.AddGeneralSettings()
        SettingsWindow.AddAudioSettings()
        SettingsWindow.AddTooltipSettings()
        SettingsWindow.AddSettingsButtons()

        MainWindow.Ui.Main.Opt("+Disabled")
        MainWindow.Ui.Set.Gui.Show("w440 h315")
    }

    static CloseSettingsWindow() {
        MainWindow.Ui.Main.Opt("-Disabled")
        MainWindow.Ui.Set.Gui.Destroy()
    }

    static AddGeneralSettings() {
        S := MainWindow.Ui.Set
        S.Log := S.Gui.Add("Checkbox", "x20 y15 w400 h20", TX["SetLog"])
        S.Log.Value := Number(Cfg.LogEnabled)
        S.Return := S.Gui.Add("Checkbox", "x20 y40 w400 h20", TX["SetReturn"])
        S.Return.Value := Number(Cfg.ReturnEnabled)
    }

    static AddAudioSettings() {
        S := MainWindow.Ui.Set
        S.Gui.Add("GroupBox", "x15 y70 w410 h60", TX["SetAudio"])
        S.AudioNone := S.Gui.Add("Radio", "x28 y95 w75 h20", TX["SetAudioNone"])
        S.AudioBeep := S.Gui.Add("Radio", "x110 y95 w120 h20", TX["SetAudioBeep"])
        S.AudioTts := S.Gui.Add("Radio", "x235 y95 w185 h20", TX["SetAudioSpeech"])
        S.AudioNone.Value := (Cfg.AudioMode == "None")
        S.AudioTts.Value := (Cfg.AudioMode == "TTS")
        S.AudioBeep.Value := (Cfg.AudioMode != "None" && Cfg.AudioMode != "TTS")
    }

    static AddTooltipSettings() {
        S := MainWindow.Ui.Set
        S.Gui.Add("GroupBox", "x15 y140 w410 h115", TX["SetTooltip"])
        S.TtAlways := S.Gui.Add("Radio", "x28 y165 w75 h20 Group", TX["SetTtAlways"])
        S.TtTimed := S.Gui.Add("Radio", "x28 y190 w75 h20", TX["SetTtTimed"])
        S.TtNever := S.Gui.Add("Radio", "x28 y215 w75 h20", TX["SetTtNever"])
        S.TtSeconds := S.Gui.Add("Edit", "x110 y188 w35 h22 Number Center", Cfg.TooltipTime)
        S.Gui.Add("Text", "x150 y192 w40 h20", TX["SetTtSeconds"])
        S.TtNever.Value := (Cfg.TooltipMode == "Never")
        S.TtTimed.Value := (Cfg.TooltipMode == "Timed")
        S.TtAlways.Value := (Cfg.TooltipMode == "Always")

        S.TtOnTop := S.Gui.Add("Checkbox", "x215 y165 w200 h20", TX["SetTtOntop"])
        S.TtOnTop.Value := Number(Cfg.TtOnTop)
        S.TtLock := S.Gui.Add("Checkbox", "x215 y190 w200 h20", TX["SetTtLock"])
        S.TtLock.Value := Number(Cfg.TtLock)

        S.Gui.Add("Text", "x215 y218 w55 h20", TX["SetTtTrans"])
        S.Gui.Add("Edit", "x270 y215 w52 h23 Number Center")
        S.Opacity := S.Gui.Add("UpDown", "Range20-100", Round((Number(Cfg.TtOpacity) / 255) * 100))
        S.Gui.Add("Text", "x327 y219 w20 h20", "%")
    }

    static AddSettingsButtons() {
        S := MainWindow.Ui.Set
        Btn := S.Gui.Add("Button", "x45 y270 w100 h32", TX["BtnSave"])
        Btn.OnEvent("Click", (*) => SettingsWindow.SaveSettings())
        Hints.Add(Btn, TX["HintSave"])
        Btn := S.Gui.Add("Button", "x170 y270 w100 h32", TX["BtnCancel"])
        Btn.OnEvent("Click", (*) => SettingsWindow.CloseSettingsWindow())
        Hints.Add(Btn, TX["HintCancel"])
        Btn := S.Gui.Add("Button", "x295 y270 w100 h32", TX["BtnDefault"])
        Btn.OnEvent("Click", (*) => SettingsWindow.ResetSettingsToDefaults())
        Hints.Add(Btn, TX["HintDefault"])
    }

    static ResetSettingsToDefaults(*) {
        S := MainWindow.Ui.Set
        S.Log.Value := 0, S.Return.Value := 1
        S.AudioBeep.Value := 1, S.TtAlways.Value := 1, S.TtSeconds.Value := "5"
        S.TtOnTop.Value := 1, S.TtLock.Value := 0, S.Opacity.Value := 90
    }

    static SaveSettings(*) {
        S := MainWindow.Ui.Set
        Cfg.LogEnabled := String(S.Log.Value)
        Cfg.ReturnEnabled := String(S.Return.Value)
        Cfg.AudioMode := S.AudioNone.Value ? "None" : (S.AudioTts.Value ? "TTS" : "Standard")
        Cfg.TooltipMode := S.TtNever.Value ? "Never" : (S.TtTimed.Value ? "Timed" : "Always")
        Cfg.TooltipTime := S.TtSeconds.Value
        Cfg.TtOnTop := String(S.TtOnTop.Value)
        Cfg.TtLock := String(S.TtLock.Value)
        Cfg.TtOpacity := String(Max(50, Round((S.Opacity.Value / 100) * 255)))
        Cfg.SaveGeneral()
        SettingsWindow.CloseSettingsWindow()
        StatusTooltip.Clear()   ; rebuilt with the new look on the next tick
    }
}

; =========================================================================
; 10. STARTUP
; =========================================================================

App.Start()

; =========================================================================
; 11. GLOBAL HOTKEYS
; =========================================================================

; Ctrl+` (SC029 is the key below Esc on any keyboard layout)
^SC029:: {
    if (State.Mode == "Stopped")
        TickLoop.StartAutomation()
}

+Esc:: TickLoop.StopAutomation()

^+Esc:: {
    TickLoop.StopAutomation()
    App.WriteLog("Application Killed.")
    ExitApp()
}
