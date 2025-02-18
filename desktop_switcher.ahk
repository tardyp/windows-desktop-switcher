#Requires AutoHotkey v2.0

SetWorkingDir(A_ScriptDir)
#SingleInstance

; Path to the DLL, relative to the script
VDA_PATH := A_ScriptDir . "\VirtualDesktopAccessor.dll"
hVirtualDesktopAccessor := DllCall("LoadLibrary", "Str", VDA_PATH, "Ptr")

GetDesktopCountProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetDesktopCount", "Ptr")
GoToDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GoToDesktopNumber", "Ptr")
GetCurrentDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetCurrentDesktopNumber", "Ptr")
IsWindowOnCurrentVirtualDesktopProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "IsWindowOnCurrentVirtualDesktop", "Ptr")
IsWindowOnDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "IsWindowOnDesktopNumber", "Ptr")
MoveWindowToDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "MoveWindowToDesktopNumber", "Ptr")
IsPinnedWindowProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "IsPinnedWindow", "Ptr")
GetDesktopNameProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetDesktopName", "Ptr")
SetDesktopNameProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "SetDesktopName", "Ptr")
CreateDesktopProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "CreateDesktop", "Ptr")
RemoveDesktopProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "RemoveDesktop", "Ptr")

; On change listeners
RegisterPostMessageHookProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "RegisterPostMessageHook", "Ptr")
UnregisterPostMessageHookProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "UnregisterPostMessageHook", "Ptr")
isWindowNonMinimized(windowId) {
    MMX := WinGetMinMax(windowId)
    return MMX != -1
}
focusSysTray() {
    try {
        WinActivate "ahk_class Shell_TrayWnd"
    } catch Error {
    }
}
focusTheForemostWindow() {
    try {
        MouseGetPos(,,&foremostWindowId)
        if isWindowNonMinimized(foremostWindowId) {
            WinActivate foremostWindowId
        }
    }
    catch Error {
    }
}
GetDesktopCount() {
    global GetDesktopCountProc
    count := DllCall(GetDesktopCountProc, "Int")
    return count
}

MoveCurrentWindowToDesktop(number) {
    global MoveWindowToDesktopNumberProc
    activeHwnd := WinGetID("A")
    DllCall(MoveWindowToDesktopNumberProc, "Ptr", activeHwnd, "Int", number, "Int")
    GoToDesktopNumber(number)
}

GoToPrevDesktop() {
    global GetCurrentDesktopNumberProc
    current := DllCall(GetCurrentDesktopNumberProc, "Int")
    last_desktop := GetDesktopCount() - 1
    ; If current desktop is 0, go to last desktop
    if (current = 0) {
        MoveOrGotoDesktopNumber(last_desktop)
    } else {
        MoveOrGotoDesktopNumber(current - 1)
    }
    return
}

GoToNextDesktop() {
    global GetCurrentDesktopNumberProc
    current := DllCall(GetCurrentDesktopNumberProc, "Int")
    last_desktop := GetDesktopCount() - 1
    ; If current desktop is last, go to first desktop
    if (current = last_desktop) {
        MoveOrGotoDesktopNumber(0)
    } else {
        MoveOrGotoDesktopNumber(current + 1)
    }
    return
}

GoToDesktopNumber(num) {
    global GoToDesktopNumberProc
    current := DllCall(GetCurrentDesktopNumberProc, "Int")
    if current == num {
        AltTabSameApp()

    } Else {
        ; hack to avoid systray icon flickering
        focusSysTray()
        DllCall(GoToDesktopNumberProc, "Int", num, "Int")
        ; Makes the WinActivate fix less intrusive
        Sleep 50
        focusTheForemostWindow()
    }
    return
}

MoveOrGotoDesktopNumber(num) {
    ; If user is holding down Mouse left button, move the current window also
    if (GetKeyState("LButton")) {
        MoveCurrentWindowToDesktop(num)
    } else {
        GoToDesktopNumber(num)
        ; HideTeams()
    }
    return
}

getWindowMonitorNumber(id) {
    MonitorCount := MonitorGetCount()
    WinGetClientPos(&x, &y, &width, &height, id) ; Get position and size of active window
    title:=WinGetTitle(id)
    ; only take in account center
    x := x + width /2
    y := y + height /2
    Loop MonitorCount
    {
        MonitorGetWorkArea(A_Index, &WL, &WT, &WR, &WB)
        If (x >= WL && x <= WR && y >= WT && y <= WB)
        {
            return A_Index
        }
    }
    return 0
}
ToggleTeams() {
    ToggleOrHideTeams(true)
}
HideTeams() {
    ToggleOrHideTeams(false)
}
ToggleOrHideTeams(toggle) {
    mainmonitor := MonitorGetPrimary()
    ids := WinGetList("ahk_exe Teams.exe") ; Get a list of all Microsoft Teams windows
    for TeamsWindowID in ids
    {
        If WinGetMinMax(TeamsWindowID) > -1 {
            If getWindowMonitorNumber(TeamsWindowID) == mainmonitor {
                WinMinimize ("ahk_id " TeamsWindowID)
            }
        }
        Else ; If the Microsoft Teams window is not currently active, show it and activate it
        {
            if (toggle) {
                WinShow("ahk_id " TeamsWindowID)
                WinActivate("ahk_id " TeamsWindowID)
            }
        }
    }
    return
}

TileCurrentWindow(split) {
    try
        activeHwnd := WinGetID("A")
    Catch
        return
    MonitorCount := MonitorGetCount()
    WinGetClientPos(&x, &y, &width, &height, activeHwnd) ; Get position and size of active window
    ; only take in account center
    x := x + width /2
    y := y + height /2
    Loop MonitorCount
    {
        MonitorGetWorkArea(A_Index, &WL, &WT, &WR, &WB)
        If (x >= WL && x <= WR && y >= WT && y <= WB)
        {
            nwidth := Floor((WR-WL)/split)
            nheight := WB-WT
            tilepos := Floor(x / nwidth)
            if (nwidth == width)
            {
                tilepos += 1
            }
            If (tilepos >= split) 
            {
                 tilepos := 0
            }
            SetWinDelay(0)
            WinRestore(activeHwnd)
            WinMove(WL + (tilepos*nwidth),WT, nwidth, nheight, activeHwnd)

            return A_Index
        }
    }
    return 0
}
F1:: TileCurrentWindow(1)
F2:: TileCurrentWindow(2)
F3:: TileCurrentWindow(3)
F4:: TileCurrentWindow(4)
F5:: TileCurrentWindow(5)

DllCall(RegisterPostMessageHookProc, "Ptr", A_ScriptHwnd, "Int", 0x1400 + 30, "Int")
OnMessage(0x1400 + 30, OnChangeDesktop)
OnChangeDesktop(wParam, lParam, msg, hwnd) {
    Critical(1)
    OldDesktop := wParam + 1
    NewDesktop := lParam + 1
    Name := "unknown" ;GetDesktopName(NewDesktop - 1)

    ; Use Dbgview.exe to checkout the output debug logs
    OutputDebug("Desktop changed to " Name " from " OldDesktop " to " NewDesktop)
    ; TraySetIcon(".\Icons\icon" NewDesktop ".ico")
}
AltTabSameApp() {
    current := WinGetProcessName("A")
    l := WinGetList("ahk_exe " current)
    curi := WinGetID("A")
    switchnext := false
    for i in l {
        if switchnext {
            WinActivate(i)
            return
        }
        if i == curi {
            switchnext :=true
        }
    }
    ; do the loop
    WinActivate(l[1])
}

; send é and è when e key is long pressed (similar to macos)
$e:: {
    
    ; first send the real e. if you dont do that, the 
    ;next key may appear before the e if typed fast enough.
    send("e")
	if !keyWait("e" , "T0.2") {
        send("{BS}é")
        if !keyWait("e" , "T0.2") {
            send "{BS}è"
        }
    }
	keyWait "e"
return
}
$u:: {
    
    send("u")
	if !keyWait("u" , "T0.2") {
        send("{BS}ù")
    }
	keyWait "u"
return
}

!1:: MoveOrGotoDesktopNumber(0)
!2:: MoveOrGotoDesktopNumber(1)
!3:: MoveOrGotoDesktopNumber(2)
!4:: MoveOrGotoDesktopNumber(3)
!5:: MoveOrGotoDesktopNumber(4)
!6:: MoveOrGotoDesktopNumber(5)
!7:: MoveOrGotoDesktopNumber(6)
!8:: MoveOrGotoDesktopNumber(7)

!0:: ToggleTeams()

; move with shift
!+1:: MoveCurrentWindowToDesktop(0)
!+2:: MoveCurrentWindowToDesktop(1)
!+3:: MoveCurrentWindowToDesktop(2)
!+4:: MoveCurrentWindowToDesktop(3)
!+5:: MoveCurrentWindowToDesktop(4)
!+6:: MoveCurrentWindowToDesktop(5)
!+7:: MoveCurrentWindowToDesktop(6)
!+8:: MoveCurrentWindowToDesktop(7)

!^Left:: GoToPrevDesktop()
!^Right:: GoToNextDesktop()

!t::^t
!c::^c
!v::^v
!x::^x
!z::^z
!s::^s
!j::Left
!k::Down
!l::Right
!i::Up
#r::Reload
!Enter::Run "C:\Users\" A_UserName "\Bin\Alacritty.exe"
;#H::WinHide "A"
