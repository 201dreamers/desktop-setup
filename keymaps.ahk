#SingleInstance

; There are more keys, please chekc the docs
; # - Super key (or Win key)
; ^ - Ctrl key
; ! - Shift key


; =========================
; Disable Windows shortcuts
; =========================
*#w::return
*#1::return
*#2::return
*#3::return
*#4::return
*#5::return
*#6::return
*#7::return
*#8::return
*#9::return
*#0::return


; ============
; Applications
; ============
; Browser
#b::Run("C:\Program Files\Google\Chrome\Application\chrome.exe")

; Terminals
#Enter::Run("wsl")
#^Enter::Run("powershell")


; =======
; Actions
; =======
; Close active window
#c::WinClose("A")

; Switch to a specific workspace
#a::switch_to_desktop(0)
#s::switch_to_desktop(1)
#d::switch_to_desktop(2)
#f::switch_to_desktop(3)
#g::switch_to_desktop(4)

; Move window to a specific workspace
#^1::move_window_to_desktop(0)
#^2::move_window_to_desktop(1)
#^3::move_window_to_desktop(2)
#^4::move_window_to_desktop(3)
#^5::move_window_to_desktop(4)


; ================
; Helper functions
; ================
; https://github.com/MScholtes/VirtualDesktop
; Put this exe into any PATH folder
switch_to_desktop(idx) {
    RunWait("VirtualDesktop11-24H2.exe -q -s:" . idx, , "Hide")
}

move_window_to_desktop(idx) {
    RunWait("VirtualDesktop11-24H2.exe -gd:" . idx . " -maw", , "Hide")
}


; ===================================
; Some useful comments googled before
; ===================================
; *LWin::KeyWait "LWin"
; ~*LWin up::return

; switch_to_desktop(idx) {
;     RunWait("VirtualDesktop11-24H2.exe -q -s:" . idx, , "Hide")
;     ; For reasons unknown, *sometimes* an Alt+Escape is required to regain focus of the foremost window
; 	; Send("{Blind}{Escape}")
; }
