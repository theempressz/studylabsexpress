#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode "Mouse", "Screen"
SetTitleMatchMode 2

try {
    DllCall("SetProcessDpiAwarenessContext", "ptr", -4, "ptr")
} catch {
    try DllCall("SetProcessDPIAware")
}

; ============================================================
; SETTINGS
; ============================================================

TargetUrl := "https://omegleapp.me/chat"

; Exact hard-coded layout.
LeftX := -8
LeftY := 7
LeftW := 768
LeftH := 1032

RightX := 1163
RightY := 9
RightW := 768
RightH := 1032

; Timing.
FirstPageLoadMs := 8000
IncognitoShortcutWaitMs := 7000
IncognitoLaunchWaitMs := 12000
BothPagesLoadMs := 12000
AfterBothResizeMs := 15000
BetweenFinalClicksMs := 5000

running := false
lastOriginalHwnd := 0
lastIncognitoHwnd := 0

; ============================================================
; HOTKEYS
; ============================================================

^j::RunEverything()
^l::StopEverything()

; Run only the browser part on the currently active profile browser.
^+j::RunBrowserPartOnly()

; Reapply layout to the two windows from the latest run.
^!j::ReapplyLayout()

Esc::ExitApp

; ============================================================
; FULL WORKFLOW
; ============================================================

RunEverything() {
    global running

    if running
        return

    running := true

    try {
        Click 1106, 40
        if !WaitMs(7000)
            return

        Click 800, 589
        if !WaitMs(10000)
            return

        Click 750, 503
        if !WaitMs(7000)
            return

        choices := ["unit", "fr", "ni"]
        SendText choices[Random(1, choices.Length)]

        if !WaitMs(7000)
            return

        Click 730, 589
        if !WaitMs(7000)
            return

        Click 1200, 890
        if !WaitMs(7000)
            return

        Click 1350, 919
        if !WaitMs(7000)
            return

        ; Open/focus profile browser.
        Click 760, 136

        Stage("Waiting for profile browser...")
        if !WaitMs(10000)
            return

        originalHwnd := WinGetID("A")

        if !IsChromiumWindow(originalHwnd) {
            MsgBox "The profile browser was not active.`n`n"
                . "Click the profile browser and press Ctrl+Shift+J."
            return
        }

        SetupOriginalAndIncognito(originalHwnd)
    } finally {
        running := false
        ToolTip
    }
}

; ============================================================
; BROWSER PART ONLY
; ============================================================

RunBrowserPartOnly() {
    global running

    if running
        return

    originalHwnd := WinGetID("A")

    if !IsChromiumWindow(originalHwnd) {
        MsgBox "Click the profile browser first, then press Ctrl+Shift+J."
        return
    }

    running := true

    try {
        SetupOriginalAndIncognito(originalHwnd)
    } finally {
        running := false
        ToolTip
    }
}

; ============================================================
; EXACT ORDER REQUESTED
; ============================================================

SetupOriginalAndIncognito(originalHwnd) {
    global TargetUrl
    global FirstPageLoadMs
    global IncognitoShortcutWaitMs
    global IncognitoLaunchWaitMs
    global BothPagesLoadMs
    global AfterBothResizeMs
    global BetweenFinalClicksMs
    global lastOriginalHwnd
    global lastIncognitoHwnd

    ; 1. Open OmegleApp in original browser.
    Stage("Opening OmegleApp in original browser...")

    if !OpenUrl(originalHwnd, TargetUrl)
        return false

    ; Wait until first page has loaded before Ctrl+Shift+N.
    if !WaitMs(FirstPageLoadMs)
        return false

    ; 2. Remember all windows from this exact browser executable.
    browserPath := GetBrowserPath(originalHwnd)

    if browserPath = "" {
        MsgBox "Could not read the profile browser executable path."
        return false
    }

    windowsBefore := GetBrowserWindows(browserPath)

    ; 3. Activate original browser and ALWAYS send Ctrl+Shift+N.
    Stage("Sending Ctrl+Shift+N now...")

    if !ActivateWindow(originalHwnd)
        return false

    Send "^+n"

    ; 4. Wait for the newly created incognito window.
    incognitoHwnd := WaitForNewBrowserWindow(
        browserPath,
        windowsBefore,
        originalHwnd,
        IncognitoShortcutWaitMs
    )

    ; 5. Automatic fallback: launch same browser executable in incognito.
    ; No stopping and no manual action.
    if !incognitoHwnd {
        Stage("Shortcut did not create a window. Launching incognito automatically...")

        try {
            command := Format('"{1}" --incognito "{2}"', browserPath, TargetUrl)
            Run command
        } catch as err {
            MsgBox "Could not launch incognito automatically.`n`n" err.Message
            return false
        }

        incognitoHwnd := WaitForNewBrowserWindow(
            browserPath,
            windowsBefore,
            originalHwnd,
            IncognitoLaunchWaitMs
        )
    }

    if !incognitoHwnd {
        MsgBox "The browser did not create an incognito window after both methods."
        return false
    }

    ; 6. Make sure the private window is on the requested page.
    Stage("Opening OmegleApp in incognito browser...")

    if !OpenUrl(incognitoHwnd, TargetUrl)
        return false

    ; 7. ONLY NOW, after two browser windows exist, resize both.
    Stage("Two windows found. Resizing both...")

    if !MoveToSide(incognitoHwnd, "Left")
        return false

    if !MoveToSide(originalHwnd, "Right")
        return false

    ; Let both sites load.
    Stage("Both websites loading...")

    if !WaitMs(BothPagesLoadMs)
        return false

    ; Reapply exact positions once loading settles.
    MoveToSide(incognitoHwnd, "Left")
    MoveToSide(originalHwnd, "Right")

    lastOriginalHwnd := originalHwnd
    lastIncognitoHwnd := incognitoHwnd

    ; Wait 15 seconds after final resizing.
    Stage("Both resized. Waiting 15 seconds...")

    if !WaitMs(AfterBothResizeMs)
        return false

    ; 8. Four clicks, once each, five seconds apart.
    Stage("Click 1 of 4...")

    if !ActivateAndClick(incognitoHwnd, 337, 622)
        return false

    if !WaitMs(BetweenFinalClicksMs)
        return false

    Stage("Click 2 of 4...")

    if !ActivateAndClick(originalHwnd, 1450, 622)
        return false

    if !WaitMs(BetweenFinalClicksMs)
        return false

    Stage("Click 3 of 4...")

    if !ActivateAndClick(incognitoHwnd, 180, 715)
        return false

    if !WaitMs(BetweenFinalClicksMs)
        return false

    Stage("Click 4 of 4...")

    if !ActivateAndClick(originalHwnd, 1355, 715)
        return false

    ToolTip
    SoundBeep 950, 180
    return true
}

; ============================================================
; BROWSER WINDOW HELPERS
; ============================================================

GetBrowserPath(hwnd) {
    try {
        return StrLower(WinGetProcessPath("ahk_id " hwnd))
    } catch {
        return ""
    }
}

GetBrowserWindows(browserPath) {
    windows := Map()

    for hwnd in WinGetList() {
        if IsWindowFromBrowser(hwnd, browserPath)
            windows[hwnd] := true
    }

    return windows
}

IsWindowFromBrowser(hwnd, browserPath) {
    if !IsChromiumWindow(hwnd)
        return false

    try {
        style := WinGetStyle("ahk_id " hwnd)

        if !(style & 0x10000000)
            return false

        return StrLower(WinGetProcessPath("ahk_id " hwnd)) = browserPath
    } catch {
        return false
    }
}

WaitForNewBrowserWindow(
    browserPath,
    windowsBefore,
    originalHwnd,
    timeoutMs
) {
    global running

    endTime := A_TickCount + timeoutMs

    while running && A_TickCount < endTime {
        for hwnd in WinGetList() {
            if hwnd = originalHwnd
                continue

            if windowsBefore.Has(hwnd)
                continue

            if IsWindowFromBrowser(hwnd, browserPath) {
                Sleep 800
                return hwnd
            }
        }

        ; Also accept a newly active window from the same executable.
        activeHwnd := WinGetID("A")

        if (
            activeHwnd
            && activeHwnd != originalHwnd
            && !windowsBefore.Has(activeHwnd)
            && IsWindowFromBrowser(activeHwnd, browserPath)
        ) {
            Sleep 800
            return activeHwnd
        }

        Sleep 150
    }

    return 0
}

IsChromiumWindow(hwnd) {
    if !hwnd
        return false

    try {
        return InStr(
            WinGetClass("ahk_id " hwnd),
            "Chrome_WidgetWin_"
        ) = 1
    } catch {
        return false
    }
}

; ============================================================
; WINDOW ACTIONS
; ============================================================

ActivateWindow(hwnd) {
    global running

    if !WinExist("ahk_id " hwnd)
        return false

    endTime := A_TickCount + 5000

    while running && A_TickCount < endTime {
        try {
            WinRestore "ahk_id " hwnd
            WinActivate "ahk_id " hwnd

            if WinActive("ahk_id " hwnd) {
                Sleep 350
                return true
            }
        } catch {
        }

        Sleep 150
    }

    return false
}

OpenUrl(hwnd, url) {
    if !ActivateWindow(hwnd)
        return false

    Send "^l"
    Sleep 200

    SendText url
    Sleep 150

    Send "{Enter}"
    return true
}

MoveToSide(hwnd, side) {
    global LeftX, LeftY, LeftW, LeftH
    global RightX, RightY, RightW, RightH

    if !WinExist("ahk_id " hwnd)
        return false

    try {
        WinRestore "ahk_id " hwnd
        Sleep 200

        if side = "Left"
            WinMove LeftX, LeftY, LeftW, LeftH, "ahk_id " hwnd
        else
            WinMove RightX, RightY, RightW, RightH, "ahk_id " hwnd

        Sleep 450
        return true
    } catch {
        return false
    }
}

ActivateAndClick(hwnd, x, y) {
    if !ActivateWindow(hwnd)
        return false

    Click x, y
    return true
}

ReapplyLayout() {
    global lastOriginalHwnd
    global lastIncognitoHwnd

    if (
        lastOriginalHwnd
        && lastIncognitoHwnd
        && WinExist("ahk_id " lastOriginalHwnd)
        && WinExist("ahk_id " lastIncognitoHwnd)
    ) {
        MoveToSide(lastIncognitoHwnd, "Left")
        MoveToSide(lastOriginalHwnd, "Right")
        return
    }

    MsgBox "Run the workflow once first."
}

; ============================================================
; STATUS / STOP
; ============================================================

Stage(message) {
    ToolTip message, 20, 20
}

StopEverything() {
    global running

    running := false
    ToolTip
}

WaitMs(milliseconds) {
    global running

    elapsed := 0

    while running && elapsed < milliseconds {
        Sleep 50
        elapsed += 50
    }

    return running
}
