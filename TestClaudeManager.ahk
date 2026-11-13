#Requires AutoHotkey v2.0
#SingleInstance Off

try {
    Dump1 := "Claude`nPaused: Your free usage returns at 6:00 PM. Continue then.`n"
        . "You are out of free messages until 6:00 PM`nClaude is AI and can make mistakes. Please double-check responses."
    Dump2 := "Claude`nPaused: Your free usage returns at 6:00 AM. Continue then.`n"
        . "You are out of free messages until 6:00 AM`nClaude is AI and can make mistakes. Please double-check responses.`n"
        . "Test backlog exporters - PY`n" StrRepeat("file contents ", 500)

    Assert(ClaudeChecker.IsConversationText(Dump1), "ordinary conversation recognized")
    Assert(ClaudeChecker.IsConversationText(Dump2), "conversation with open file recognized")
    Assert(!ClaudeChecker.IsConversationText("file contents only"), "file-only selection rejected")
    AssertEqual(ClaudeChecker.ParseHourlyLimit(Dump1), "18:00", "6 PM dump")
    AssertEqual(ClaudeChecker.ParseHourlyLimit(Dump2), "06:00", "6 AM dump")
    AssertEqual(ClaudeChecker.ParseHourlyLimit("You are out of free messages until tomorrow at 6:00 AM", &Tomorrow), "06:00", "tomorrow wording")
    Assert(Tomorrow, "tomorrow flag")
    AssertEqual(ClaudeChecker.ParseHourlyLimit("Paused: Your free usage returns at 12:05 AM."), "00:05", "midnight")
    AssertEqual(ClaudeChecker.ParseHourlyLimit("No usage limit here"), "", "no limit")
    AssertEqual(SubStr(ClaudeChecker.ParseWeeklyLimit("Your free usage returns December 31 at 11:59 PM"), 5), "1231235900", "weekly wording")
    AssertEqual(ClaudeChecker.HourlyResetStamp("18:00", false, "20261109170000"), "20261109180000", "same-day reset")
    AssertEqual(ClaudeChecker.HourlyResetStamp("06:00", false, "20261109230000"), "20261110060000", "overnight reset")
    AssertEqual(ClaudeChecker.HourlyResetStamp("18:00", true, "20261109170000"), "20261110180000", "explicit tomorrow")
    State.TargetResetTime := DateAdd(A_Now, -1, "Seconds")
    Assert(TickLoop.SecondsUntilReset() <= 0, "expired timestamp does not roll forward")
    if (A_Args.Length != 0 && A_Args.Length != 2)
        throw Error("Provide either no dump paths or two dump paths.")
    if (A_Args.Length == 2) {
        for Index, Expected in ["06:00", "18:00"] {
            Text := ClaudeChecker.NormalizeConversationText(FileRead(A_Args[Index], "UTF-8"))
            Assert(ClaudeChecker.IsConversationText(Text), "dump " Index " recognized")
            AssertEqual(ClaudeChecker.ParseHourlyLimit(Text), Expected, "dump " Index " reset")
        }
    }
    FileAppend("All Claude Manager tests passed.`n", "*")
    ExitApp(0)
} catch as Err {
    FileAppend("Test failed: " Err.Message "`n", "*")
    ExitApp(1)
}

Assert(Condition, Description) {
    if !Condition
        throw Error(Description)
}

AssertEqual(Actual, Expected, Description) {
    if (Actual != Expected)
        throw Error(Description ": expected " Expected ", got " Actual)
}

StrRepeat(Text, Count) {
    Result := ""
    Loop Count
        Result .= Text
    return Result
}

#Include ClaudeManager.ahk
