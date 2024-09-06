#SingleInstance

; There are more keys, please chekc the docs
; # - Super key (or Win key)
; ^ - Ctrl key
; ! - Shift key


; ============
; Applications
; ============
; Browser
#b::Run("C:\Program Files\Google\Chrome\Application\chrome.exe")

; Terminals
#Enter::Run("ubuntu")
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


; ================
; Helper functions
; ================
switch_to_desktop(idx) {
    Run("VirtualDesktop11-24H2.exe -s:" . idx)
}
