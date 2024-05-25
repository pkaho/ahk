; 修饰符
; 使用<和>可以作为下面四个修饰符任意一个的前缀，来指定改键的左右变体
;   ^ | Ctrl
;   + | Shift
;   ! | Alt
;   # | Win
;   * | 允许热键激活，及时按住的修饰符不在热键符号中
;   ~ | 防止热键阻塞该键的原生功能
;   $ | 防止在发送按键时出现无意义的循环，并且在某些情况下使热键更可靠
; --------------------------------------------------------------------
; 窗口状态函数
; WinMaximize | 最大化窗口
; WinActive   | 窗口激活
; WinExist    | 窗口已存在


; `ctrl+1` 最大化窗口
^1::WinMaximize "A"

; 使用`#HotIf`来限定激活热键必须要满足的条件
#HotIf WinActive("ahk_class Notepad")
#c::MsgBox "我是notepad中的win+c"

#HotIf
#c::MsgBox "我是win+c"

