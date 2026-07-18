#Requires AutoHotkey v2.0
#SingleInstance Force

; Use real screen coordinates.
CoordMode "Mouse", "Screen"
SetTitleMatchMode 2

; Helps WinMove work correctly with Windows scaling.
try {
    DllCall("SetProcessDpiAwarenessContext", "ptr", -4, "ptr")
} catch {
    try {
        DllCall("SetProcessDPIAware")
    }
}

; ============================================================
; SETTINGS
; ============================================================

TargetUrl := "https://omegleapp.me/chat"

; Private/incognito window:
SecondWindowShortcut := "^+n"

; Change to "^n" if you want a normal second window instead.
; SecondWindowShortcut := "^n"

PageLoadWaitMs := 10000
SecondWindowTimeoutMs := 12000

; After BOTH windows have reached their saved positions:
PostResizeWaitMs := 15000

; Delay between each of the four final clicks:
FinalClickDelayMs := 5000

; Try private first, then normal second window automatically.
FallbackToNormalWindow := true

; Saved automatically beside this script.
LayoutFile := A_ScriptDir "\browser_layout.ini"

running := false
lastNormalHwnd := 0
lastSecondHwnd := 0

; ============================================================
; HOTKEYS
; ============================================================

; Ctrl+J = full click sequence + website + second window + layout.
^j::RunFullSequence()

; Ctrl+L = stop the current sequence.
^l::StopSequence()

; Save manually positioned browser windows once:
; Ctrl+Alt+1 = save active window as LEFT.
^!1::SaveActivePosition("Left")

; Ctrl+Alt+2 = save active window as RIGHT.
^!2::SaveActivePosition("Right")

; Ctrl+Alt+J = reapply saved positions to the last two windows.
^!j::ReapplySavedLayout()

; Ctrl+Shift+J = browser setup only.
^+j::BrowserSetupOnly()

Esc::ExitApp

; ============================================================
; FULL SEQUENCE
; ============================================================

RunFullSequence() {
    global running

    if running {
        return
    }

    running := true

    try {
        Click 1106, 40
        if !WaitInterruptible(7000)
            return

        Click 800, 589
        if !WaitInterruptible(10000)
            return

        Click 750, 503
        if !WaitInterruptible(7000)
            return

        options := ["unit", "fr", "ni"]
        chosenText := options[Random(1, options.Length)]

        SendText chosenText
        if !WaitInterruptible(7000)
            return

        Click 730, 589
        if !WaitInterruptible(7000)
            return

        Click 1200, 890
        if !WaitInterruptible(7000)
            return

        Click 1350, 919
        if !WaitInterruptible(7000)
            return

        ; Final click that opens/focuses the profile browser.
        Click 760, 136
        if !WaitInterruptible(10000)
            return

        ; The browser should now be the active window.
        normalHwnd := WinGetID("A")

        if !IsChromiumWindow(normalHwnd) {
            MsgBox "The active window is not a Chromium browser.`n`n"
                . "Click the opened GoLogin/Brave browser and press Ctrl+Shift+J."
            return
        }

        SetupBrowserWindows(normalHwnd)
    } finally {
        running := false
    }
}

; ============================================================
; BROWSER SETUP
; ============================================================

BrowserSetupOnly() {
    global running

    if running {
        return
    }

    hwnd := WinGetID("A")

    if !IsChromiumWindow(hwnd) {
        MsgBox "Click the open GoLogin/Brave/Chrome browser first, then press Ctrl+Shift+J."
        return
    }

    running := true

    try {
        SetupBrowserWindows(hwnd)
    } finally {
        running := false
    }
}

SetupBrowserWindows(normalHwnd) {
    global TargetUrl
    global SecondWindowShortcut
    global PageLoadWaitMs
    global SecondWindowTimeoutMs
    global PostResizeWaitMs
    global FinalClickDelayMs
    global FallbackToNormalWindow
    global lastNormalHwnd
    global lastSecondHwnd

    ShowStage("Opening website in first browser...")

    ; Open the site in the normal/profile window.
    OpenUrl(normalHwnd, TargetUrl)

    if !WaitInterruptible(PageLoadWaitMs)
        return false

    ; Try to open the private/incognito window first.
    ShowStage("Opening second browser window...")

    existingWindows := GetChromiumWindows()

    WinActivate "ahk_id " normalHwnd

    if !WaitInterruptible(500)
        return false

    Send SecondWindowShortcut

    secondHwnd := WaitForNewChromiumWindow(
        existingWindows,
        SecondWindowTimeoutMs
    )

    ; Some GoLogin/Orbita profiles do not open a detectable private window.
    ; If that happens, automatically try a normal Ctrl+N window.
    if !secondHwnd && FallbackToNormalWindow && running {
        ShowStage("Private window was not detected. Trying Ctrl+N...")

        existingWindows := GetChromiumWindows()

        WinActivate "ahk_id " normalHwnd

        if !WaitInterruptible(600)
            return false

        Send "^n"

        secondHwnd := WaitForNewChromiumWindow(
            existingWindows,
            SecondWindowTimeoutMs
        )
    }

    if !secondHwnd {
        ClearStage()
        MsgBox "The second browser window was not detected after trying both Ctrl+Shift+N and Ctrl+N.`n`n"
            . "Open the second window manually, click the first browser, and press Ctrl+Shift+J."
        return false
    }

    ShowStage("Opening website in second browser...")

    ; Open the same site in the second window.
    OpenUrl(secondHwnd, TargetUrl)

    if !WaitInterruptible(PageLoadWaitMs)
        return false

    ShowStage("Applying saved left/right layout...")

    ; Apply and verify BOTH saved positions.
    if !ApplyAndVerifyBothWindows(secondHwnd, normalHwnd)
        return false

    ; Store handles before the post-resize actions.
    lastNormalHwnd := normalHwnd
    lastSecondHwnd := secondHwnd

    ShowStage("Both windows positioned. Waiting 15 seconds...")

    ; Wait exactly 15 seconds AFTER both positions are verified.
    if !WaitInterruptible(PostResizeWaitMs)
        return false

    ; Four final coordinates, each clicked once, with 5 seconds between.
    ShowStage("Final click 1 of 4...")
    if !ClickScreenPointForWindow(secondHwnd, 337, 622)
        return false

    if !WaitInterruptible(FinalClickDelayMs)
        return false

    ShowStage("Final click 2 of 4...")
    if !ClickScreenPointForWindow(normalHwnd, 1450, 622)
        return false

    if !WaitInterruptible(FinalClickDelayMs)
        return false

    ShowStage("Final click 3 of 4...")
    if !ClickScreenPointForWindow(secondHwnd, 180, 715)
        return false

    if !WaitInterruptible(FinalClickDelayMs)
        return false

    ShowStage("Final click 4 of 4...")
    if !ClickScreenPointForWindow(normalHwnd, 1355, 715)
        return false

    ClearStage()
    SoundBeep 900, 180

    return true
}

ApplyAndVerifyBothWindows(secondHwnd, normalHwnd) {
    ; Moving one Chromium window can sometimes slightly affect the other,
    ; so verify both together and retry the pair.
    Loop 3 {
        if !MoveAndVerifyWindow(secondHwnd, "Left")
            return false

        if !MoveAndVerifyWindow(normalHwnd, "Right")
            return false

        Sleep 800

        if IsWindowAtSavedPosition(secondHwnd, "Left")
            && IsWindowAtSavedPosition(normalHwnd, "Right") {
            return true
        }
    }

    ClearStage()
    MsgBox "Both browser windows could not stay in their saved positions.`n`n"
        . "Place the left window and press Ctrl+Alt+1, then place the right window and press Ctrl+Alt+2."
    return false
}

IsWindowAtSavedPosition(hwnd, side) {
    rect := LoadPosition(side)

    try {
        WinGetPos &actualX, &actualY, &actualW, &actualH, "ahk_id " hwnd

        tolerance := 14

        return Abs(actualX - rect["X"]) <= tolerance
            && Abs(actualY - rect["Y"]) <= tolerance
            && Abs(actualW - rect["W"]) <= tolerance
            && Abs(actualH - rect["H"]) <= tolerance
    } catch {
        return false
    }
}

ClickScreenPointForWindow(hwnd, x, y) {
    global running

    if !running || !WinExist("ahk_id " hwnd)
        return false

    WinActivate "ahk_id " hwnd

    if !WaitInterruptible(400)
        return false

    Click x, y
    return true
}

ShowStage(message) {
    ToolTip message, 20, 20
}

ClearStage() {
    ToolTip
}

OpenUrl(hwnd, url) {
    if !WinExist("ahk_id " hwnd) {
        return false
    }

    WinActivate "ahk_id " hwnd
    Sleep 300

    Send "^l"
    Sleep 150

    SendText url
    Sleep 100

    Send "{Enter}"
    return true
}

IsChromiumWindow(hwnd) {
    if !hwnd {
        return false
    }

    try {
        return WinGetClass("ahk_id " hwnd) = "Chrome_WidgetWin_1"
    } catch {
        return false
    }
}

GetChromiumWindows() {
    windows := Map()

    for hwnd in WinGetList("ahk_class Chrome_WidgetWin_1") {
        try {
            style := WinGetStyle("ahk_id " hwnd)

            if (style & 0x10000000) {
                windows[hwnd] := true
            }
        } catch {
        }
    }

    return windows
}

WaitForNewChromiumWindow(existingWindows, timeoutMs) {
    global running

    deadline := A_TickCount + timeoutMs

    while running && A_TickCount < deadline {
        for hwnd in WinGetList("ahk_class Chrome_WidgetWin_1") {
            if existingWindows.Has(hwnd) {
                continue
            }

            try {
                style := WinGetStyle("ahk_id " hwnd)

                if (style & 0x10000000) {
                    return hwnd
                }
            } catch {
            }
        }

        Sleep 200
    }

    return 0
}

; ============================================================
; SAVE AND RESTORE WINDOW POSITIONS
; ============================================================

SaveActivePosition(side) {
    global LayoutFile

    hwnd := WinGetID("A")

    if !IsChromiumWindow(hwnd) {
        MsgBox "Click the browser window you want to save as " side
            . ", then press the hotkey again."
        return
    }

    try {
        WinRestore "ahk_id " hwnd
        Sleep 200

        WinGetPos &x, &y, &w, &h, "ahk_id " hwnd

        IniWrite x, LayoutFile, side, "X"
        IniWrite y, LayoutFile, side, "Y"
        IniWrite w, LayoutFile, side, "W"
        IniWrite h, LayoutFile, side, "H"

        MsgBox side " position saved.`n`n"
            . "X=" x "`nY=" y "`nW=" w "`nH=" h
    } catch as err {
        MsgBox "Could not save position.`n`n" err.Message
    }
}

MoveToSavedPosition(hwnd, side) {
    rect := LoadPosition(side)

    try {
        WinRestore "ahk_id " hwnd
        Sleep 200

        WinMove(
            rect["X"],
            rect["Y"],
            rect["W"],
            rect["H"],
            "ahk_id " hwnd
        )

        Sleep 400
        return true
    } catch as err {
        MsgBox "Could not move the " side " window.`n`n" err.Message
        return false
    }
}

MoveAndVerifyWindow(hwnd, side) {
    rect := LoadPosition(side)

    ; Chromium may resist the first resize while loading.
    ; Retry up to three times and verify the resulting position.
    Loop 3 {
        if !MoveToSavedPosition(hwnd, side) {
            return false
        }

        Sleep 500

        try {
            WinGetPos &actualX, &actualY, &actualW, &actualH, "ahk_id " hwnd

            tolerance := 12

            positionOkay :=
                Abs(actualX - rect["X"]) <= tolerance
                && Abs(actualY - rect["Y"]) <= tolerance
                && Abs(actualW - rect["W"]) <= tolerance
                && Abs(actualH - rect["H"]) <= tolerance

            if positionOkay {
                return true
            }
        } catch {
        }

        Sleep 500
    }

    MsgBox "The " side " browser window did not reach its saved layout after three attempts.`n`n"
        . "Reposition it manually and save again with Ctrl+Alt+"
        . (side = "Left" ? "1." : "2.")

    return false
}

LoadPosition(side) {
    global LayoutFile

    defaults := DefaultPosition(side)

    return Map(
        "X", Integer(IniRead(LayoutFile, side, "X", defaults["X"])),
        "Y", Integer(IniRead(LayoutFile, side, "Y", defaults["Y"])),
        "W", Integer(IniRead(LayoutFile, side, "W", defaults["W"])),
        "H", Integer(IniRead(LayoutFile, side, "H", defaults["H"]))
    )
}

DefaultPosition(side) {
    MonitorGetWorkArea(
        1,
        &screenLeft,
        &screenTop,
        &screenRight,
        &screenBottom
    )

    screenWidth := screenRight - screenLeft
    screenHeight := screenBottom - screenTop

    ; Each browser uses 40% of the screen.
    ; This leaves a 20% space in the middle.
    windowWidth := Round(screenWidth * 0.40)

    if side = "Left" {
        x := screenLeft
    } else {
        x := screenRight - windowWidth
    }

    return Map(
        "X", x,
        "Y", screenTop,
        "W", windowWidth,
        "H", screenHeight
    )
}

ReapplySavedLayout() {
    global lastNormalHwnd
    global lastSecondHwnd

    if (
        lastNormalHwnd
        && lastSecondHwnd
        && WinExist("ahk_id " lastNormalHwnd)
        && WinExist("ahk_id " lastSecondHwnd)
    ) {
        MoveToSavedPosition(lastSecondHwnd, "Left")
        MoveToSavedPosition(lastNormalHwnd, "Right")
        return
    }

    MsgBox "Run the full setup once first, or save/reopen the two browser windows."
}

; ============================================================
; STOPPABLE WAIT
; ============================================================

StopSequence() {
    global running
    running := false
    ClearStage()
}

WaitInterruptible(milliseconds) {
    global running

    elapsed := 0

    while running && elapsed < milliseconds {
        Sleep 50
        elapsed += 50
    }

    return running
}
