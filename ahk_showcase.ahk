; Easy Window Dragging(Like KDE) -- alt(double)+mouseL/R/M
; refer: https://wyagd001.github.io/v2/docs/scripts/index.htm#EasyWindowDrag_(KDE)
SetWinDelay 2
CoordMode "Mouse"

g_DoubleAlt := false

!LButton::
{
    global g_DoubleAlt  ; Declare it since this hotkey function must modify it.
    if g_DoubleAlt
    {
        MouseGetPos ,, &KDE_id
        ; This message is mostly equivalent to WinMinimize,
        ; but it avoids a bug with PSPad.
        PostMessage 0x0112, 0xf020,,, KDE_id
        g_DoubleAlt := false
        return
    }
    ; Get the initial mouse position and window id, and
    ; abort if the window is maximized.
    MouseGetPos &KDE_X1, &KDE_Y1, &KDE_id
    if WinGetMinMax(KDE_id)
        return
    ; Get the initial window position.
    WinGetPos &KDE_WinX1, &KDE_WinY1,,, KDE_id
    Loop
    {
        if !GetKeyState("LButton", "P") ; Break if button has been released.
            break
        MouseGetPos &KDE_X2, &KDE_Y2 ; Get the current mouse position.
        KDE_X2 -= KDE_X1 ; Obtain an offset from the initial mouse position.
        KDE_Y2 -= KDE_Y1
        KDE_WinX2 := (KDE_WinX1 + KDE_X2) ; Apply this offset to the window position.
        KDE_WinY2 := (KDE_WinY1 + KDE_Y2)
        WinMove KDE_WinX2, KDE_WinY2,,, KDE_id ; Move the window to the new position.
    }
}

!RButton::
{
    global g_DoubleAlt
    if g_DoubleAlt
    {
        MouseGetPos ,, &KDE_id
        ; Toggle between maximized and restored state.
        if WinGetMinMax(KDE_id)
            WinRestore KDE_id
        Else
            WinMaximize KDE_id
        g_DoubleAlt := false
        return
    }
    ; Get the initial mouse position and window id, and
    ; abort if the window is maximized.
    MouseGetPos &KDE_X1, &KDE_Y1, &KDE_id
    if WinGetMinMax(KDE_id)
        return
    ; Get the initial window position and size.
    WinGetPos &KDE_WinX1, &KDE_WinY1, &KDE_WinW, &KDE_WinH, KDE_id
    ; Define the window region the mouse is currently in.
    ; The four regions are Up and Left, Up and Right, Down and Left, Down and Right.
    if (KDE_X1 < KDE_WinX1 + KDE_WinW / 2)
        KDE_WinLeft := 1
    else
        KDE_WinLeft := -1
    if (KDE_Y1 < KDE_WinY1 + KDE_WinH / 2)
        KDE_WinUp := 1
    else
        KDE_WinUp := -1
    Loop
    {
        if !GetKeyState("RButton", "P") ; Break if button has been released.
            break
        MouseGetPos &KDE_X2, &KDE_Y2 ; Get the current mouse position.
        ; Get the current window position and size.
        WinGetPos &KDE_WinX1, &KDE_WinY1, &KDE_WinW, &KDE_WinH, KDE_id
        KDE_X2 -= KDE_X1 ; Obtain an offset from the initial mouse position.
        KDE_Y2 -= KDE_Y1
        ; Then, act according to the defined region.
        WinMove KDE_WinX1 + (KDE_WinLeft+1)/2*KDE_X2  ; X of resized window
              , KDE_WinY1 +   (KDE_WinUp+1)/2*KDE_Y2  ; Y of resized window
              , KDE_WinW  -     KDE_WinLeft  *KDE_X2  ; W of resized window
              , KDE_WinH  -       KDE_WinUp  *KDE_Y2  ; H of resized window
              , KDE_id
        KDE_X1 := (KDE_X2 + KDE_X1) ; Reset the initial position for the next iteration.
        KDE_Y1 := (KDE_Y2 + KDE_Y1)
    }
}

; "Alt + MButton" may be simpler, but I like an extra measure of security for
; an operation like this.
!MButton::
{
    global g_DoubleAlt
    if g_DoubleAlt
    {
        MouseGetPos ,, &KDE_id
        WinClose KDE_id
        g_DoubleAlt := false
        return
    }
}

; This detects "double-clicks" of the alt key.
~Alt::
{
    global g_DoubleAlt := (A_PriorHotkey = "~Alt" and A_TimeSincePriorHotkey < 400)
    Sleep 0
    KeyWait "Alt"  ; This prevents the keyboard's auto-repeat feature from interfering.
}

; ---------------------------------------------------------------------------------------
; Minimize Window to Tray Menu -- win+h/u
g_MaxWindows := 50

; This is the hotkey used to hide the active window:
g_Hotkey := "#h"  ; Win+H

; This is the hotkey used to unhide the last hidden window:
g_UnHotkey := "#u"  ; Win+U

; If you prefer to have the tray menu empty of all the standard items,
; such as Help and Pause, use False. Otherwise, use True:
g_StandardMenu := false

; These next few performance settings help to keep the action within the
; A_HotkeyModifierTimeout period, and thus avoid the need to release and
; press down the hotkey's modifier if you want to hide more than one
; window in a row. These settings are not needed if you choose to have
; the script use the keyboard hook via InstallKeybdHook or other means:
A_HotkeyModifierTimeout := 100
SetWinDelay 10
SetKeyDelay 0

#SingleInstance  ; Allow only one instance of this script to be running.
Persistent

; END OF CONFIGURATION SECTION (do not make changes below this point
; unless you want to change the basic functionality of the script).

g_WindowIDs := []
g_WindowTitles := []

Hotkey g_Hotkey, Minimize
Hotkey g_UnHotkey, UnMinimize

; If the user terminates the script by any means, unhide all the
; windows first:
OnExit RestoreAllThenExit

if g_StandardMenu = true
    A_TrayMenu.Add
else
{
    ;A_TrayMenu.Delete ; 这一行如果不注释脚本右键只会显示`Add`添加的内容
    A_TrayMenu.Add "E&xit and Unhide All", RestoreAllThenExit
}
A_TrayMenu.Add "&Unhide All Hidden Windows", RestoreAll
;A_TrayMenu.Add  ; Another separator line to make the above more special.
A_TrayMenu.Add  ; Another separator line to make the above more special.

g_MaxLength := 260  ; Reduce this to restrict the width of the menu.

Minimize(*)
{
    if g_WindowIDs.Length >= g_MaxWindows
    {
        MsgBox "No more than " g_MaxWindows " may be hidden simultaneously."
        return
    }

    ; Set the "last found window" to simplify and help performance.
    ; Since in certain cases it is possible for there to be no active window,
    ; a timeout has been added:
    if !WinWait("A",, 2)  ; It timed out, so do nothing.
        return

    ; Otherwise, the "last found window" has been set and can now be used:
    ActiveID := WinGetID()
    ActiveTitle := WinGetTitle()
    ActiveClass := WinGetClass()
    if ActiveClass ~= "Shell_TrayWnd|Progman"
    {
        MsgBox "The desktop and taskbar cannot be hidden."
        return
    }
    ; Because hiding the window won't deactivate it, activate the window
    ; beneath this one (if any). I tried other ways, but they wound up
    ; activating the task bar. This way sends the active window (which is
    ; about to be hidden) to the back of the stack, which seems best:
    Send "!{esc}"
    ; Hide it only now that WinGetTitle/WinGetClass above have been run (since
    ; by default, those functions cannot detect hidden windows):
    WinHide

    ; If the title is blank, use the class instead. This serves two purposes:
    ; 1) A more meaningful name is used as the menu name.
    ; 2) Allows the menu item to be created (otherwise, blank items wouldn't
    ;    be handled correctly by the various routines below).
    if ActiveTitle = ""
        ActiveTitle := "ahk_class " ActiveClass
    ; Ensure the title is short enough to fit. ActiveTitle also serves to
    ; uniquely identify this particular menu item.
    ActiveTitle := SubStr(ActiveTitle, 1, g_MaxLength)

    ; In addition to the tray menu requiring that each menu item name be
    ; unique, it must also be unique so that we can reliably look it up in
    ; the array when the window is later unhidden. So make it unique if it
    ; isn't already:
    for WindowTitle in g_WindowTitles
    {
        if WindowTitle = ActiveTitle
        {
            ; Match found, so it's not unique.
            ActiveIDShort := Format("{:X}" ,ActiveID)
            ActiveIDShortLength := StrLen(ActiveIDShort)
            ActiveTitleLength := StrLen(ActiveTitle)
            ActiveTitleLength += ActiveIDShortLength
            ActiveTitleLength += 1 ; +1 the 1 space between title & ID.
            if ActiveTitleLength > g_MaxLength
            {
                ; Since menu item names are limted in length, trim the title
                ; down to allow just enough room for the Window's Short ID at
                ; the end of its name:
                TrimCount := ActiveTitleLength
                TrimCount -= g_MaxLength
                ActiveTitle := SubStr(ActiveTitle, 1, -TrimCount)
            }
            ; Build unique title:
            ActiveTitle .= " " ActiveIDShort
            break
        }
    }

    ; First, ensure that this ID doesn't already exist in the list, which can
    ; happen if a particular window was externally unhidden (or its app unhid
    ; it) and now it's about to be re-hidden:
    AlreadyExists := false
    for WindowID in g_WindowIDs
    {
        if WindowID = ActiveID
        {
            AlreadyExists := true
            break
        }
    }

    ; Add the item to the array and to the menu:
    if AlreadyExists = false
    {
        A_TrayMenu.Add ActiveTitle, RestoreFromTrayMenu
        g_WindowIDs.Push(ActiveID)
        g_WindowTitles.Push(ActiveTitle)
    }
}


RestoreFromTrayMenu(ThisMenuItem, *)
{
    A_TrayMenu.Delete ThisMenuItem
    ; Find window based on its unique title stored as the menu item name:
    for WindowTitle in g_WindowTitles
    {
        if WindowTitle = ThisMenuItem  ; Match found.
        {
            IDToRestore := g_WindowIDs[A_Index]
            WinShow IDToRestore
            WinActivate IDToRestore  ; Sometimes needed.
            g_WindowIDs.RemoveAt(A_Index)  ; Remove it to free up a slot.
            g_WindowTitles.RemoveAt(A_Index)
            break
        }
    }
}


; This will pop the last minimized window off the stack and unhide it.
UnMinimize(*)
{
    ; Make sure there's something to unhide.
    if g_WindowIDs.Length > 0 
    {
        ; Get the id of the last window minimized and unhide it
        IDToRestore := g_WindowIDs.Pop()
        WinShow IDToRestore
        WinActivate IDToRestore
        
        ; Get the menu name of the last window minimized and remove it
        MenuToRemove := g_WindowTitles.Pop()
        A_TrayMenu.Delete MenuToRemove
    }
}


RestoreAllThenExit(*)
{
    RestoreAll()
    ExitApp  ; Do a true exit.
}


RestoreAll(*)
{
    for WindowID in g_WindowIDs
    {
        IDToRestore := WindowID
        WinShow IDToRestore
        WinActivate IDToRestore  ; Sometimes needed.
        ; Do it this way vs. DeleteAll so that the sep. line and first
        ; item are retained:
        MenuToRemove := g_WindowTitles[A_Index]
        A_TrayMenu.Delete MenuToRemove
    }
    ; Free up all slots:
    global g_WindowIDs := []
    global g_WindowTitles := []
}

; ---------------------------------------------------------------------------------------
; Window Shading -- win+z
g_MinHeight := 25

; This line will unroll any rolled up windows if the script exits
; for any reason:
OnExit ExitSub

IDs := Array()
Windows := Map()

#z::  ; Change this line to pick a different hotkey.
; Below this point, no changes should be made unless you want to
; alter the script's basic functionality.
{
    ; Uncomment this next line if this subroutine is to be converted
    ; into a custom menu item rather than a hotkey. The delay allows
    ; the active window that was deactivated by the displayed menu to
    ; become active again:
    ;Sleep 200
    ActiveID := WinGetID("A")
    for ID in IDs
    {
        if ID = ActiveID
        {
            ; Match found, so this window should be restored (unrolled):
            Height := Windows[ActiveID]
            WinMove ,,, Height, ActiveID
            IDs.RemoveAt(A_Index)
            return
        }
    }
    WinGetPos ,,, &Height, "A"
    Windows.Set(ActiveID, Height)
    WinMove ,,, g_MinHeight, ActiveID
    IDs.Push(ActiveID)
}

ExitSub(*)
{
    for ID in IDs
    {
        Height := Windows[ID]
        WinMove ,,, Height, ID
    }
    ExitApp  ; Must do this for the OnExit subroutine to actually Exit the script.
}

; ---------------------------------------------------------------------------------------

