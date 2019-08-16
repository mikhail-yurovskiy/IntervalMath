INCLUDELIB      gui.obj

.CODE
; Процедуры
EXTRN           init_gui     : proc, show_mouse   : proc, hide_mouse   : proc
EXTRN           deinit_gui   : proc, vert_line    : proc, horiz_line   : proc
EXTRN           box          : proc, filled_box   : proc, draw_window1 : proc
EXTRN           cls          : proc, print_sym    : proc, set_window1  : proc
EXTRN           print        : proc, set_button   : proc, box2         : proc
EXTRN           push_button  : proc, buttons      : proc, wait_retrace : proc
EXTRN           input        : proc, multichoise  : proc, print_xy     : proc
EXTRN           clear_window1: proc, help_page    : proc, set_window2  : proc
EXTRN           if_click     : proc, beep         : proc, press_button : proc
EXTRN           wait_retrace2: proc, print_center : proc
