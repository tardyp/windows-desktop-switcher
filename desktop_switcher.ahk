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
    ; hack to avoid systray icon flickering
    focusSysTray()
    DllCall(GoToDesktopNumberProc, "Int", num, "Int")
    ; Makes the WinActivate fix less intrusive
    Sleep 50
    focusTheForemostWindow()
    return
}

MoveOrGotoDesktopNumber(num) {
    ; If user is holding down Mouse left button, move the current window also
    if (GetKeyState("LButton")) {
        MoveCurrentWindowToDesktop(num)
    } else {
        GoToDesktopNumber(num)
    }
    return
}


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

#1:: MoveOrGotoDesktopNumber(0)
#2:: MoveOrGotoDesktopNumber(1)
#3:: MoveOrGotoDesktopNumber(2)
#4:: MoveOrGotoDesktopNumber(3)
#5:: MoveOrGotoDesktopNumber(4)
#6:: MoveOrGotoDesktopNumber(5)
#7:: MoveOrGotoDesktopNumber(6)
#8:: MoveOrGotoDesktopNumber(7)
; same in french layout
#&:: MoveOrGotoDesktopNumber(0)
#é:: MoveOrGotoDesktopNumber(1)
#":: MoveOrGotoDesktopNumber(2)
#':: MoveOrGotoDesktopNumber(3)
#(:: MoveOrGotoDesktopNumber(4)
#-:: MoveOrGotoDesktopNumber(5)
#è:: MoveOrGotoDesktopNumber(6)
#_:: MoveOrGotoDesktopNumber(7)

; move with shift
#+1:: MoveCurrentWindowToDesktop(0)
#+2:: MoveCurrentWindowToDesktop(1)
#+3:: MoveCurrentWindowToDesktop(2)
#+4:: MoveCurrentWindowToDesktop(3)
#+5:: MoveCurrentWindowToDesktop(4)
#+6:: MoveCurrentWindowToDesktop(5)
#+7:: MoveCurrentWindowToDesktop(6)
#+8:: MoveCurrentWindowToDesktop(7)
; same in french layout
#+&:: MoveCurrentWindowToDesktop(0)
#+é:: MoveCurrentWindowToDesktop(1)
#+":: MoveCurrentWindowToDesktop(2)
#+':: MoveCurrentWindowToDesktop(3)
#+(:: MoveCurrentWindowToDesktop(4)
#+-:: MoveCurrentWindowToDesktop(5)
#+è:: MoveCurrentWindowToDesktop(6)
#+_:: MoveCurrentWindowToDesktop(7)
#^Left:: GoToPrevDesktop()
#^Right:: GoToNextDesktop()