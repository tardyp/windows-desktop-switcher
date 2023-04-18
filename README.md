
# windows-desktop-switcher
An AutoHotkey script for Windows that lets a user switch virtual desktops by pressing <kbd>Windows</kbd> and a number row key at the sime time (e.g. <kbd>CapsLock</kbd> + <kbd>2</kbd> to switch to Desktop 2). It also provides other features, such as customizing the key combinations, creation/deletion of desktops by hotkey, etc. (see Hotkeys section below).


## Credits

Mostly based on [Ciantic/VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor) (DLL) example.

Parent project is not used anymore, this is mostly a lightweight layer on top of VDA.dll. (only the sys_tray flickering workaround is kept) 

## Hotkeys

Action | Keys 
--- | :-:
**Switch** to virtual desktop **1, 2, etc.**<br>|<kbd>Windows</kbd> + <kbd>1</kbd><br><kbd>Windows</kbd> + <kbd>2</kbd><br>...<br><kbd>Windows</kbd> + <kbd>9</kbd>
**Switch** to the virtual desktop on the **left**<br>*(auto-cycles from the first to the last desktop)*|<kbd>Windows + Shift </kbd> + <kbd>Left</kbd><br>
**Switch** to the virtual desktop on the **right**<br>*(auto-cycles from the last to the first desktop)*|<kbd>Windows + Shift </kbd> + <kbd>Left</kbd><br>
**Move** the current window to another desktop, then switch to it| <kbd>Windows + Shift</kbd> + <kbd>1</kbd><br><kbd>Windows + Shift</kbd> + <kbd>2</kbd> <br>...<br><kbd>Windows + Shift</kbd> + <kbd>9</kbd> 

## Overview
This script creates more convenient hotkeys for switching virtual desktops in Windows 10. I built this to better mirror the mapping I use on linux (with i3), and it's always annoyed me that Windows does not have better hotkey support for this feature (for instance, there's no way to go directly to a desktop by number).

## Running
[Install AutoHotkey](https://autohotkey.com/download/) v2.0 or later, then run the `desktop_switcher.ahk` script (open with AutoHotkey if prompted). You can disable the switching animation by opening "Adjust the appearance and performance of Windows" and then unselecting the checkmark "Animate windows when minimizing and maximizing".

### Notes about Windows 1809/1903≤ Updates
This project relies partly on [VirtualDesktopAccessor.dll](https://github.com/Ciantic/VirtualDesktopAccessor) (for moving windows to other desktops). This binary is included in this repository for convenience, and was recently updated to work with the 1809/1903≤ updates. 

This may cause instability for users running older versions of Windows. If this is the case, [download the older DLL](https://github.com/pmb6tz/windows-desktop-switcher/blob/5289a0968179638f6e946a4cb69723510abd0d19/virtual-desktop-accessor.dll), rename it to `VirtualDesktopAccessor.dll`, and overwrite the previous DLL.

If a future Windows Update breaks the DLL again and updating your files from this repository doesn't work, you could try [building the DLL yourself](https://github.com/Ciantic/VirtualDesktopAccessor) (given that it was since updated by its' creators).

## Customizing Hotkeys
To change the key mappings, modify the `desktop_switcher.ahk` in the end. Note, `!` corresponds to <kbd>Alt</kbd>, `+` is <kbd>Shift</kbd>, `#` is <kbd>Win</kbd>, and `^` is <kbd>Ctrl</kbd>. A more detailed description of hotkeys can be found [here](https://autohotkey.com/docs/Hotkeys.htm). The syntax of the config file is `HOTKEY::ACTION`. Here are some examples of the customization options. 

A more detailed description of hotkeys can be found here: [AutoHotkey docs](https://autohotkey.com/docs/Hotkeys.htm).<br>
You can find the explanation for the Desktop Manager hotkey [here](https://github.com/pmb6tz/windows-desktop-switcher/issues/41).<br>
After any changes to the configuration the program needs to be closed and opened again.

## Running on boot

You can make the script run on every boot with either of these methods.

### Simple (Non-administrator method)

1. Press <kbd>Win</kbd> + <kbd>R</kbd>, enter `shell:startup`, then click <kbd>OK</kbd>
2. Create a shortcut to the `desktop_switcher.ahk` file here

### Advanced (Administrator method)

Windows prevents hotkeys from working in windows that were launched with higher elevation than the AutoHotKey script (such as CMD or Powershell terminals that were launched as Administrator). As a result, Windows Desktop Switcher hotkeys will only work within these windows if the script itself is `Run as Administrator`, due to the way Windows is designed. 

You can do this by creating a scheduled task to invoke the script at logon. You may use 'Task Scheduler', or create the task in powershell as demonstrated.
```
# Run the following commands in an Administrator powershell prompt. 
# Be sure to specify the correct path to your desktop_switcher.ahk file. 

$A = New-ScheduledTaskAction -Execute "PATH\TO\desktop_switcher.ahk"
$T = New-ScheduledTaskTrigger -AtLogon
$P = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest
$S = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0
$D = New-ScheduledTask -Action $A -Principal $P -Trigger $T -Settings $S
Register-ScheduledTask WindowsDesktopSwitcher -InputObject $D
```

The task is now registered and will run on the next logon, and can be viewed or modified in 'Task Scheduler'. 

## Other
To see debug messages, download [SysInternals DebugView](https://technet.microsoft.com/en-us/sysinternals/debugview).

