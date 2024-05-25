;!1::opencmdhere()
;opencmdhere() {
;    If WinActive("ahk_class CabinetWClass") || WinActive("ahk_class ExploreWClass") {
;        WinHWND := WinActive()
;        For win in ComObjCreate("Shell.Application").Windows
;            If (win.HWND = WinHWND) {
;        currdir := SubStr(win.LocationURL, 9)
;        currdir := RegExReplace(currdir, "%20", " ")
;                Break
;            }
;    }
;    Run, cmd, % currdir ? currdir : "C:\Users\xxx"
;}

SetNumLockState "AlwaysOn"
SetCapsLockState "AlwaysOff"

#n::
{
  if WinExist("ahk_class notepad++")
    WinActivate
  else
    Run "D:/Applications/Scoop/apps/notepadplusplus/current/notepad++.exe"
}
^!t::
{
  Run "wt"
}
; wezterm start --cwd /some/path
#w:: Run "D:/Applications/Scoop/apps/wezterm/current/wezterm-gui.exe"
