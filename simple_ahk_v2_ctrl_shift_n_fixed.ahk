#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreadsPerHotkey 1

CoordMode "Mouse", "Screen"
SetTitleMatchMode 2
SendMode "Input"

try {
    DllCall("SetProcessDpiAwarenessContext", "ptr", -4, "ptr")
} catch {
    try DllCall("SetProcessDPIAware")
}

running := false
TargetUrl := "https://omegleapp.me/chat"

; ============================================================
; HOTKEYS
; ============================================================

$^j::
{
    global running, TargetUrl

    if running
        return

    running := true

    ; Important: fully release the Ctrl+J trigger keys before the workflow.
    KeyWait "j"
    KeyWait "Ctrl"

    try {
        ; ----------------------------------------------------
        ; ORIGINAL COORDINATE SEQUENCE
        ; ----------------------------------------------------

        Click 1106, 40
        if !WaitMs( 5500)
            return

        Click 800, 589
        if !WaitMs(10000)
            return

        Click 750, 503
        if !WaitMs(5500)
            return

        options := ["unit", "fr", "ni"]
        SendText options[Random(1, options.Length)]

        if !WaitMs(5500)
            return

        Click 730, 589
        if !WaitMs(5500)
            return

        Click 1200, 890
        if !WaitMs(5500)
            return

        Click 1350, 919
        if !WaitMs(7000)
            return

        ; Opens/focuses the original profile browser.
        Click 760, 136

        if !WaitMs(12000)
            return

        originalHwnd := WinGetID("A")

        ; ----------------------------------------------------
        ; OPEN URL IN ORIGINAL BROWSER — INSTANT CLIPBOARD PASTE
        ; ----------------------------------------------------

        WinActivate "ahk_id " originalHwnd
        WinWaitActive "ahk_id " originalHwnd, , 5
        Sleep 500

        PasteUrlInstant(TargetUrl)

        ; Wait for OmegleApp to load.
        if !WaitMs(8000)
            return

        ; ----------------------------------------------------
        ; CLICK PAGE TO FOCUS, THEN CTRL+SHIFT+N
        ; ----------------------------------------------------

        WinActivate "ahk_id " originalHwnd
        WinWaitActive "ahk_id " originalHwnd, , 5
        Sleep 400

        Click 606, 518
        Sleep 1000

        ; Make sure no modifier is logically held.
        SendInput "{Ctrl up}{Shift up}{Alt up}"
        Sleep 300

        ; Left Ctrl = SC01D
        ; Left Shift = SC02A
        ; N = SC031
        SendIncognitoShortcut()

        ; Give the incognito window time to open and become active.
        if !WaitMs(7000)
            return

        incognitoHwnd := WinGetID("A")

        ; Simple retry if the active window did not change.
        if incognitoHwnd = originalHwnd {
            WinActivate "ahk_id " originalHwnd
            WinWaitActive "ahk_id " originalHwnd, , 5
            Sleep 400

            Click 606, 518
            Sleep 1000

            SendInput "{Ctrl up}{Shift up}{Alt up}"
            Sleep 300

            SendIncognitoShortcut()

            if !WaitMs(7000)
                return

            incognitoHwnd := WinGetID("A")
        }

        if incognitoHwnd = originalHwnd {
            MsgBox "The browser still did not open an incognito window."
            return
        }

        ; ----------------------------------------------------
        ; OPEN URL IN INCOGNITO — INSTANT CLIPBOARD PASTE
        ; ----------------------------------------------------

        WinActivate "ahk_id " incognitoHwnd
        WinWaitActive "ahk_id " incognitoHwnd, , 5
        Sleep 500

        PasteUrlInstant(TargetUrl)

        if !WaitMs(10000)
            return

        ; ----------------------------------------------------
        ; RESIZE ONLY AFTER BOTH WINDOWS EXIST
        ; ----------------------------------------------------

        ; Incognito left.
        WinRestore "ahk_id " incognitoHwnd
        Sleep 300
        WinMove -8, 7, 768, 1032, "ahk_id " incognitoHwnd
        Sleep 700

        ; Original right.
        WinRestore "ahk_id " originalHwnd
        Sleep 300
        WinMove 1163, 9, 768, 1032, "ahk_id " originalHwnd
        Sleep 700

        ; Reapply once after Chromium settles.
        WinMove -8, 7, 768, 1032, "ahk_id " incognitoHwnd
        Sleep 500
        WinMove 1163, 9, 768, 1032, "ahk_id " originalHwnd

        ; Wait 15 seconds after final resizing.
        if !WaitMs(21000)
            return

        ; ----------------------------------------------------
        ; FOUR FINAL CLICKS — 5 SECONDS APART
        ; ----------------------------------------------------

        WinActivate "ahk_id " incognitoHwnd
        WinWaitActive "ahk_id " incognitoHwnd, , 5
        Sleep 400
        Click 337, 622

        if !WaitMs(7500)
            return

        WinActivate "ahk_id " originalHwnd
        WinWaitActive "ahk_id " originalHwnd, , 5
        Sleep 400
        Click 1450, 622

        if !WaitMs(7500)
            return

        WinActivate "ahk_id " incognitoHwnd
        WinWaitActive "ahk_id " incognitoHwnd, , 5
        Sleep 400
        Click 180, 715

        if !WaitMs(7500)
            return

        WinActivate "ahk_id " originalHwnd
        WinWaitActive "ahk_id " originalHwnd, , 5
        Sleep 400
        Click 1355, 715

        SoundBeep 950, 180
    }
    finally {
        running := false
        SendInput "{Ctrl up}{Shift up}{Alt up}"
    }
}

$^l::
{
    global running
    running := false
    SendInput "{Ctrl up}{Shift up}{Alt up}"
}

Esc::ExitApp

; ============================================================
; HELPERS
; ============================================================

PasteUrlInstant(url)
{
    oldClipboard := ClipboardAll()

    try {
        A_Clipboard := url

        if !ClipWait(1) {
            return false
        }

        SendInput "^l"
        Sleep 200
        SendInput "^v"
        Sleep 150
        SendInput "{Enter}"

        return true
    }
    finally {
        Sleep 150
        A_Clipboard := oldClipboard
    }
}

SendIncognitoShortcut()
{
    ; Use scan-code key events with deliberate timing.
    SendEvent "{sc01D down}"
    Sleep 180

    SendEvent "{sc02A down}"
    Sleep 180

    SendEvent "{sc031 down}"
    Sleep 180

    SendEvent "{sc031 up}"
    Sleep 120

    SendEvent "{sc02A up}"
    Sleep 120

    SendEvent "{sc01D up}"
    Sleep 400
}

WaitMs(milliseconds)
{
    global running

    elapsed := 0

    while running && elapsed < milliseconds {
        Sleep 50
        elapsed += 50
    }

    return running
}
