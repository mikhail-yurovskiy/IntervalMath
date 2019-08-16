                .MODEL  small
                .386
                LOCALS  @@
                INCLUDE math.inc
                INCLUDE gui.inc
                .CODE

begin:
                mov     ax, @data
                mov     ds, ax
                mov     es, ax
                push    es
                mov     ax, 351Ch
                int     21h
                mov     word ptr cs:old_int_vec, bx
                mov     word ptr cs:old_int_vec+2, es
                pop     es
                call    init_stack
                call    init_gui
                call    show_mouse
                call    init_task
                call    intro
main_loop:
                call    hide_mouse
                call    cls
                mov     ax, 50
                mov     bx, 50
                mov     cx, 590
                mov     dx, 430
                call    draw_window1
                mov     si, offset message_1
                mov     ah, 0Fh
                mov     bx, 31
                call    print_center

                mov     si, offset f_message
                mov     ah, 08h
                mov     bx, 60
                call    print_center
                mov     si, offset fx
                mov     ah, 00h
                mov     bx, 81
                mov     cx, 80
                call    print_xy
                mov     ax, 141
                mov     cx, 558
                mov     bx, 80
                mov     dx, 97
                call    set_window2
                mov     si, offset str_func
                mov     ah, 00h
                call    print

                mov     si, offset g_message
                mov     ah, 08h
                mov     bx, 120
                call    print_center
                mov     si, offset gx
                mov     ah, 00h
                mov     bx, 81
                mov     cx, 140
                call    print_xy
                mov     ax, 141
                mov     cx, 558
                mov     bx, 140
                mov     dx, 157
                call    set_window2
                mov     si, offset str_deriv1
                mov     ah, 00h
                call    print

                mov     si, offset h_message
                mov     ah, 08h
                mov     bx, 180
                call    print_center
                mov     si, offset hx
                mov     ah, 00h
                mov     bx, 81
                mov     cx, 200
                call    print_xy
                mov     ax, 141
                mov     cx, 558
                mov     bx, 200
                mov     dx, 217
                call    set_window2
                mov     si, offset str_deriv2
                mov     ah, 00h
                call    print

                mov     si, offset x_message
                mov     ah, 08h
                mov     bx, 270
                call    print_center
                mov     si, offset sx1
                mov     ah, 00h
                mov     bx, 76
                mov     cx, 290
                call    print_xy
                mov     ax, 104
                mov     cx, 305
                mov     bx, 290
                mov     dx, 307
                call    set_window2
                mov     si, offset str_x1
                mov     ah, 00h
                call    print
                mov     si, offset sx2
                mov     ah, 00h
                mov     bx, 338
                mov     cx, 290
                call    print_xy
                mov     ax, 366
                mov     cx, 567
                mov     bx, 290
                mov     dx, 307
                call    set_window2
                mov     si, offset str_x2
                mov     ah, 00h
                call    print

                mov     si, offset ent_buttons
                call    set_button
                call    set_button
                call    set_button
                call    set_button
                call    show_mouse
loop_0:
                mov     ah, 01h
                int     16h
                jz      continue
                mov     ah, 00h         ; нажата какая-то клавиша
                int     16h
                cmp     ah, 01h         ; проверить сканируемый код
                je      esc_exit        ; если <Esc>, то на выход
continue:
                mov     ax, 0005h
                xor     bx, bx          ; проверим левую клавишу мыши
                int     33h
                and     bx, bx          ; если левая клавиша не нажималась,
                jz      loop_0          ;                         то зациклим
                mov     si, offset gr_ebutton
                call    if_click
                jnc     to_grafic
                mov     si, offset comp_ebutton
                call    if_click
                jnc     to_compute
                mov     si, offset esc_ebutton
                call    if_click
                jnc     asc_exit
                mov     si, offset help_ebutton
                call    if_click
                jnc     help
                cmp     cx, 141
                jb      next_0
                cmp     cx, 559
                jae     next_0
                cmp     dx, 80
                jb      next_0
                cmp     dx, 98
                jae     next_0
                call    hide_mouse
                mov     si, offset str_func
                mov     di, offset edit_buffer
                mov     cx, 0200h
                rep     movsb
enter_fx:
                mov     di, offset edit_buffer
                mov     ax, 141
                mov     bx, 80
                mov     cx, 52
                mov     dx, 01FFh
                stc
                call    input
                jc      no_change0
                and     ax, ax
                jz      err_0
                push    cs
                pop     fs
                mov     bp, offset func
                mov     si, offset edit_buffer
                mov     di, offset func_consts
                call    make_mthproc
                jnc     cont_0
                mov     bp, offset func
                mov     si, offset str_func
                mov     di, offset func_consts
                call    make_mthproc
err_0:
                call    beep
                jmp     enter_fx
cont_0:
                mov     si, offset edit_buffer
                mov     di, offset str_func
                mov     cx, 0200h
                rep     movsb
no_change0:
                mov     ax, 141
                mov     cx, 558
                mov     bx, 80
                mov     dx, 97
                call    set_window2
                mov     si, offset str_func
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     loop_0
next_0:
                cmp     cx, 141
                jb      next_1
                cmp     cx, 559
                jae     next_1
                cmp     dx, 140
                jb      next_1
                cmp     dx, 157
                jae     next_1
                call    hide_mouse
                mov     si, offset str_deriv1
                mov     di, offset edit_buffer
                mov     cx, 0200h
                rep     movsb
enter_gx:
                mov     di, offset edit_buffer
                mov     ax, 141
                mov     bx, 140
                mov     cx, 52
                mov     dx, 01FFh
                stc
                call    input
                jc      no_change1
                push    cs
                pop     fs
                mov     bp, offset deriv1
                mov     si, offset edit_buffer
                mov     di, offset deriv1_consts
                call    make_mthproc
                jnc     cont_1
                call    beep
                mov     bp, offset deriv1
                mov     si, offset str_deriv1
                mov     di, offset deriv1_consts
                call    make_mthproc
                jmp     enter_gx
cont_1:
                mov     si, offset edit_buffer
                mov     di, offset str_deriv1
                mov     cx, 0200h
                rep     movsb
no_change1:
                mov     ax, 141
                mov     cx, 558
                mov     bx, 140
                mov     dx, 157
                call    set_window2
                mov     si, offset str_deriv1
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     loop_0
next_1:
                cmp     cx, 141
                jb      next_2
                cmp     cx, 559
                jae     next_2
                cmp     dx, 200
                jb      next_2
                cmp     dx, 217
                jae     next_2
                call    hide_mouse
                mov     si, offset str_deriv2
                mov     di, offset edit_buffer
                mov     cx, 0200h
                rep     movsb
enter_hx:
                mov     di, offset edit_buffer
                mov     ax, 141
                mov     bx, 200
                mov     cx, 52
                mov     dx, 01FFh
                stc
                call    input
                jc      no_change2
                push    cs
                pop     fs
                mov     bp, offset deriv2
                mov     si, offset edit_buffer
                mov     di, offset deriv2_consts
                call    make_mthproc
                jnc     cont_2
                call    beep
                mov     bp, offset deriv2
                mov     si, offset str_deriv2
                mov     di, offset deriv2_consts
                call    make_mthproc
                jmp     enter_hx
cont_2:
                mov     si, offset edit_buffer
                mov     di, offset str_deriv2
                mov     cx, 0200h
                rep     movsb
no_change2:
                mov     ax, 141
                mov     cx, 558
                mov     bx, 200
                mov     dx, 217
                call    set_window2
                mov     si, offset str_deriv2
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     loop_0
next_2:
                cmp     cx, 366
                jb      next_3
                cmp     cx, 568
                jae     next_3
                cmp     dx, 290
                jb      next_3
                cmp     dx, 307
                jae     next_3
                call    hide_mouse
                mov     si, offset str_x2
                mov     di, offset edit_buffer
                mov     cx, 001Ah
                rep     movsb
enter_x2:
                mov     di, offset edit_buffer
                mov     ax, 366
                mov     bx, 290
                mov     cx, 25
                mov     dx, 25
                stc
                call    input
                jc      no_change3
                and     ax, ax
                jz      err_3
                call    del_spaces
                cmp     [si], cl
                je      err_3
                mov     bx, offset x2
                call    val_func
                jnc     cont_3
                mov     si, offset str_x2
                mov     bx, offset x2
                call    val_func
err_3:
                call    beep
                jmp     enter_x2
cont_3:
                mov     si, offset edit_buffer
                mov     di, offset str_x2
                mov     cx, 001Ah
                rep     movsb
no_change3:
                mov     ax, 366
                mov     cx, 567
                mov     bx, 290
                mov     dx, 307
                call    set_window2
                mov     si, offset str_x2
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     loop_0
next_3:
                cmp     cx, 104
                jb      loop_0
                cmp     cx, 306
                jae     loop_0
                cmp     dx, 290
                jb      loop_0
                cmp     dx, 307
                jae     loop_0
                call    hide_mouse
                mov     si, offset str_x1
                mov     di, offset edit_buffer
                mov     cx, 001Ah
                rep     movsb
enter_x1:
                mov     di, offset edit_buffer
                mov     ax, 104
                mov     bx, 290
                mov     cx, 25
                mov     dx, 25
                stc
                call    input
                jc      no_change4
                and     ax, ax
                jz      err_4
                call    del_spaces
                cmp     [si], cl
                je      err_4
                mov     bx, offset x1
                call    val_func
                jnc     cont_4
                mov     si, offset str_x1
                mov     bx, offset x1
                call    val_func
err_4:
                call    beep
                jmp     enter_x1
cont_4:
                mov     si, offset edit_buffer
                mov     di, offset str_x1
                mov     cx, 001Ah
                rep     movsb
no_change4:
                mov     ax, 104
                mov     cx, 305
                mov     bx, 290
                mov     dx, 307
                call    set_window2
                mov     si, offset str_x1
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     loop_0
help:
                call    press_button
                call    hide_mouse
                call    cls
                call    show_mouse
                mov     si, offset help_main
                call    help_page
                jmp     main_loop
to_grafic:
                call    press_button
                call    elect_func
                jc      main_loop
                call    grafic
                push    ds
                mov     ax, 251Ch
                lds     dx, cs:old_int_vec
                int     21h
                pop     ds
                jmp     main_loop
to_compute:
                call    press_button
                call    elect_func
                jc      main_loop
                call    compute
                jmp     main_loop
asc_exit:
                call    press_button
esc_exit:
                call    hide_mouse
                call    cls
                mov     ax, 180
                mov     cx, 460
                mov     bx, 210
                mov     dx, 270
                call    draw_window1
                mov     si, offset asc_for_exit
                mov     ah, 04h
                mov     bx, 200
                mov     cx, 220
                call    print_xy
                mov     si, offset exit_to_dos
                mov     ah, 0Fh
                mov     bx, 191
                call    print_center
                call    show_mouse
                mov     si, offset exit_buttons
                mov     ax, 2
                call    buttons
                jc      exit
                and     ax, ax
                jnz     main_loop
exit:
                call    deinit_gui
                mov     ax, 4C00h
                int     21h




del_spaces      PROC
                mov     cx, ax          ; удалим пробелы
                inc     cx
                mov     si, di
                push    si
@@loop_0:
                lodsb
                dec     cx
                jz      @@cont_0
                cmp     al, ' '
                je      @@space
                cmp     al, 'A'
                jb      @@loop_0
                cmp     al, 'Z'
                ja      @@loop_0
                add     al, 20h
                mov     [si-1], al
                jmp     @@loop_0
@@space:
                lea     di, [si-1]      ; DI = SI-1
                push    cx
                push    di
                rep     movsb           ; удалим пробел
                pop     si
                pop     cx
                jmp     @@loop_0
@@cont_0:
                pop     si
                ret
del_spaces      ENDP



init_task       PROC
                push    cs
                pop     fs
                mov     si, offset my_func
                mov     di, offset str_func
                push    di
                mov     cx, my_func_len
                rep     movsb
                pop     si
                mov     di, offset func_consts
                mov     bp, offset func
                call    make_mthproc
                mov     si, offset my_deriv1
                mov     di, offset str_deriv1
                push    di
                mov     cx, my_deriv1_len
                rep     movsb
                pop     si
                mov     di, offset deriv1_consts
                mov     bp, offset deriv1
                call    make_mthproc
                mov     si, offset my_deriv2
                mov     di, offset str_deriv2
                push    di
                mov     cx, my_deriv2_len
                rep     movsb
                pop     si
                mov     di, offset deriv2_consts
                mov     bp, offset deriv2
                call    make_mthproc
                mov     si, offset my_x1
                mov     di, offset str_x1
                push    di
                mov     cx, my_x1_len
                rep     movsb
                pop     si
                mov     bx, offset x1
                call    val_func
                mov     si, offset my_x2
                mov     di, offset str_x2
                push    di
                mov     cx, my_x2_len
                rep     movsb
                pop     si
                mov     bx, offset x2
                call    val_func
                ret
init_task       ENDP



intro           PROC
                call    hide_mouse
                call    cls
                mov     ax, 210
                mov     cx, 430
                mov     bx, 120
                mov     dx, 360
                call    draw_window1
                mov     si, offset message_0
                mov     ah, 04h
                mov     bx, 140
                call    print_center
                mov     ah, 04h
                mov     bx, 160
                call    print_center
                mov     ah, 01h
                mov     bx, 240
                call    print_center
                mov     ah, 01h
                mov     bx, 260
                call    print_center
                mov     ah, 08h
                mov     bx, 290
                call    print_center
                call    show_mouse
                mov     si, offset ok_button
                mov     ax, 1
                jmp     buttons
intro           ENDP



elect_func      PROC
                call    hide_mouse
                call    cls
                mov     ax, 180
                mov     bx, 202
                mov     cx, 460
                mov     dx, 278
                call    draw_window1
                mov     si, offset el_message
                mov     ah, 0Fh
                mov     bx, 178
                call    print_center
                mov     si, offset elect_message
                mov     ah, 08h
                mov     bx, 212
                call    print_center
                call    show_mouse
                mov     si, offset el_buttons
                mov     ax, 3
                call    buttons
                jc      @@exit
                mov     bx, offset func
                and     al, al
                jz      @@cont
                mov     bx, offset deriv1
                dec     al
                jz      @@cont
                mov     bx, offset deriv2
@@cont:
                mov     function, bx
@@exit:
                ret
elect_func      ENDP



init_time       PROC
                mov     al, 00h
                out     70h, al
                in      al, 71h
                mov     sec0, al
                mov     time, 0
                ret
init_time       ENDP



my_int          PROC
                pushad
                push    ds
                push    es
                push    fs
                push    gs
                mov     ax, @data
                mov     ds, ax
                mov     es, ax
                mov     al, 00h
                out     70h, al
                in      al, 71h
                cmp     al, sec0
                mov     sec0, al
                je      @@exit_int
                inc     time
                call    wait_retrace
                mov     ax, 0007h
                mov     bx, 356
                mov     cx, 240
                mov     dx, 420
                mov     si, 304
                call    filled_box
                mov     eax, time
                call    @@decode_time
                mov     si, offset message_time
                mov     ah, 00h
                mov     bx, 356
                mov     cx, 240
                call    print_xy
                mov     eax, time
                mov     ecx, 640
                mul     ecx
                movzx   ecx, c_rang
                jecxz   @@exit_int
                div     ecx
                call    @@decode_time
                mov     si, offset message_time
                mov     ah, 00h
                mov     bx, 356
                mov     cx, 256
                call    print_xy
@@exit_int:
                pop     gs
                pop     fs
                pop     es
                pop     ds
                popad
                jmp     cs:[old_int_vec]
@@decode_time:
                mov     ecx, 3600
                cdq
                div     ecx
                mov     di, offset hours
                call    @@decimal
                mov     ax, dx
                mov     cx, 60
                cwd
                div     cx
                mov     di, offset mins
                call    @@decimal
                mov     ax, dx
                mov     di, offset secs
@@decimal:
                aam
                add     ax, 3030h
                xchg    al, ah
                stosw
                ret
my_int          ENDP



grafic          PROC
                call    hide_mouse
                call    init_stack
                call    cls
                mov     c_rang, 0
                mov     ax, 148
                mov     cx, 491
                mov     bx, 160
                mov     dx, 319
                call    draw_window1
                mov     si, offset message_2
                mov     ah, 04h
                mov     bx, 176
                call    print_center
                mov     si, offset message_3
                mov     ah, 04h
                mov     bx, 288
                mov     cx, 208
                call    print_xy
                mov     si, offset message_4
                mov     ah, 01h
                mov     bx, 220
                mov     cx, 240
                call    print_xy
                mov     si, offset message_5
                mov     ah, 01h
                mov     bx, 220
                mov     cx, 256
                call    print_xy
                mov     si, offset message_esc
                mov     ah, 0Fh
                mov     bx, 204
                mov     cx, 448
                call    print_xy

                call    init_time
                push    ds
                mov     ax, 251Ch
                push    cs
                pop     ds
                mov     dx, offset my_int
                int     21h
                pop     ds

                mov     si, offset x1
                push    si
                mov     di, offset xk
                mov     cx, 5
                rep     movsw
                mov     bx, offset x2
                call    load_num
                pop     bx
                call    c_sub
                mov     ax, 640
                call    cm_div
                mov     bx, offset d_x
                call    get_middle
                mov     di, offset array
@@loop_0:
                push    di
                mov     bx, offset xk
                push    bx
                call    load_num
                call    function
                jc      @@errors
                mov     ah, 01h
                int     16h
                jz      @@pass_0
                mov     ah, 00h
                int     16h
                cmp     ah, 01h
                je      @@esc_err
@@pass_0:
                call    get_top
                call    empty_store
                mov     si, bx
                pop     bx
                pop     di
                mov     cx, 5
                rep     movsd
                push    di
                push    bx
                mov     dx, offset d_x
                call    n_add
                pop     si
                inc     c_rang
                mov     di, offset x2
                call    compare
                pop     di
                jae     @@loop_0

                push    ds
                mov     ax, 251Ch
                lds     dx, cs:old_int_vec
                int     21h
                pop     ds
                call    cls
; найти min, max; (max-min)/480 = h; scr_y = (real_y-min)/h
                mov     si, offset array
                mov     di, offset max
                mov     bx, offset min
                push    di
                mov     cx, 5
                rep     movsw
                mov     di, bx
                mov     cl, 5
                rep     movsw
                sub     si, 20
                pop     di
                mov     cx, 1280
@@gloop_0:
                push    cx
                call    compare
                jae     @@gpass_2
                push    di
                mov     cx, 5
                rep     movsw
                pop     di
                sub     si, 10
@@gpass_2:
                xchg    di, bx
                call    compare
                jbe     @@gpass_3
                push    di
                mov     cx, 5
                rep     movsw
                pop     di
                sub     si, 10
@@gpass_3:
                xchg    di, bx
                add     si, 10
                pop     cx
                loop    @@gloop_0
; (max-min)/460 = h; scr_y = (real_y-min)/h
                mov     dx, bx
                xor     byte ptr [bx+9], 80h
                mov     bx, di
                push    bx
                call    n_add
                pop     bx
                call    load_num
                mov     ax, 440
                call    cm_div
                mov     bx, offset max
                call    get_middle      ; в max запишем h
                call    empty_store
; scr_y = (real_y-min)/h
                mov     cx, 1280
                mov     bx, offset array
                mov     di, bx
@@gloop_1:
                push    cx
                push    di
                mov     dx, offset min
                push    bx
                call    n_add
                pop     bx
                mov     dx, offset max
                push    bx
                call    n_div
                pop     bx
                call    get_int
                sub     ax, 440
                neg     ax
                pop     di
                stosw
                add     bx, 10
                pop     cx
                loop    @@gloop_1
                xor     byte ptr min+9, 80h

                mov     si, offset x1
                mov     di, offset h_x
                push    di
                mov     cx, 5
                rep     movsw
                pop     bx
                xor     byte ptr [bx+9], 80h
                mov     dx, offset x2
                push    bx
                call    n_add
                pop     bx
                push    bx
                call    load_num
                mov     ax, 639
                call    cm_div
                pop     bx
                call    get_middle

                mov     bx, 0
@@gloop_3:
                xor     dx, dx
                mov     cx, 439
                mov     ax, 0008h
                push    bx
                call    vert_line
                pop     bx
                add     bx, 20
                cmp     bx, 640
                jb      @@gloop_3
                mov     bx, 439
@@gloop_4:
                xor     dx, dx
                mov     cx, 639
                mov     ax, 0008h
                push    bx
                call    horiz_line
                pop     bx
                sub     bx, 20
                jae     @@gloop_4

                mov     bx, 0
                mov     si, offset array
@@gloop_2:
                push    bx
                lodsw
                mov     cx, ax
                lodsw
                mov     dx, ax
                mov     ax, 000Ah
                push    si
                call    cvert_line
                pop     si
                pop     bx
                cmp     bx, 639
                jae     @@gpass_5
                push    bx
                push    si
                dec     si
                dec     si
                lodsw
                mov     cx, ax
                lodsw
                mov     dx, ax
                mov     ax, 000Ah
                cmp     cx, dx
                jge     @@gpass_4
                xchg    cx, dx
@@gpass_4:
                call    cvert_line
                pop     si
                pop     bx
                inc     bx
                jmp     @@gloop_2
@@gpass_5:
                mov     si, offset end_button
                call    set_button
                mov     old_x, -1
                mov     old_y, -1
                call    show_mouse
@@gloop_5:
                mov     ah, 01h
                int     16h
                jz      @@continue
                mov     ah, 00h         ; нажата какая-то клавиша
                int     16h
                cmp     ah, 01h         ; проверить сканируемый код
                je      @@exit          ; если <Esc>, то на выход
@@continue:
                mov     ax, 0005h
                xor     bx, bx          ; проверим левую клавишу мыши
                int     33h
                and     bx, bx          ; если левая клавиша не нажималась,
                jnz     @@left_key_press;                         то зациклим
                mov     ax, 0003h
                int     33h
                cmp     old_x, cx
                jne     @@shift_located
                cmp     old_y, dx
                je      @@gloop_5
@@shift_located:
                mov     old_x, cx
                mov     old_y, dx
                push    dx
                mov     ax, cx
                call    load_int
                mov     bx, offset h_x
                call    c_mul
                mov     bx, offset variable
                call    get_middle
                call    empty_store
                mov     dx, offset x1
                push    bx
                call    n_add
                pop     bx
                mov     di, offset x_str
                call    asc_func
                pop     ax
                sub     ax, 440
                neg     ax
                call    load_int
                mov     bx, offset max
                call    c_mul
                mov     bx, offset variable
                call    get_middle
                call    empty_store
                mov     dx, offset min
                push    bx
                call    n_add
                pop     bx
                mov     di, offset y_str
                call    asc_func
                call    wait_retrace
                cmp     old_y, 400
                jb      @@gpass_6
                call    hide_mouse
@@gpass_6:
                mov     ax, 0001h
                xor     bx, bx
                mov     cx, 452
                mov     dx, 223
                mov     si, 469
                call    filled_box
                mov     ax, 0001h
                mov     bx, 416
                mov     cx, 452
                mov     dx, 639
                mov     si, 469
                call    filled_box
                mov     si, offset x
                mov     ah, 0Eh
                xor     bx, bx
                mov     cx, 452
                call    print_xy
                mov     si, offset y
                mov     ah, 0Eh
                mov     bx, 416
                mov     cx, 452
                call    print_xy
                cmp     old_y, 400
                jb      @@gloop_5
                call    show_mouse
                jmp     @@gloop_5
@@left_key_press:
                mov     si, offset end_button
                call    if_click
                jc      @@gloop_5
                call    press_button
@@exit:
                ret
@@errors:
                pop     si
                pop     si
                cmp     ax, 3
                je      @@ok_err
                cmp     ax, 5
                je      @@ok_err
                cmp     ax, 14
                je      @@esc_err2
                mov     si, offset error_1
                jmp     error
@@esc_err:
                pop     si
                pop     si
@@esc_err2:
                mov     si, offset error_4
                jmp     error
@@ok_err:
                mov     si, offset error_0
error:
                push    si
                push    ds
                mov     ax, 251Ch
                lds     dx, cs:old_int_vec
                int     21h
                pop     ds
                call    cls
                mov     ax, 176
                mov     cx, 464
                mov     bx, 176
                mov     dx, 304
                call    set_window1
                pop     si
                mov     ah, 04h
                call    print
                call    show_mouse
                mov     si, offset error_button
                mov     ax, 1
                jmp     buttons
grafic          ENDP



test_zero       PROC
                call    get_top
                cmp     byte ptr [bx+7], 00h
                je      @@exit
                cmp     byte ptr [bx+17], 00h
                je      @@exit
                mov     ax, [bx+8]
                xor     ax, [bx+18]
                and     ah, 80h
                xor     ah, 80h
@@exit:
                ret
test_zero       ENDP



print_progress  PROC
                mov     di, offset num
                push    di
                xor     ch, ch
                xor     ah, ah
                mov     cl, 100
                div     cl
                and     al, al
                jz      @@cont_0
                inc     ch
                add     al, 30h
                stosb
@@cont_0:
                mov     cl, 10
                mov     al, ah
                xor     ah, ah
                div     cl
                and     al, al
                jnz     @@okay
                and     ch, ch
                jz      @@cont_1
@@okay:
                add     al, 30h
                stosb
@@cont_1:
                mov     al, ah
                add     al, 30h
                stosb
                mov     al, '%'
                stosb
                xor     al, al
                stosb
                call    wait_retrace
                mov     bx, 344
                mov     cx, 264
                mov     dx, 376
                mov     si, 280
                mov     ax, 0007h
                call    filled_box
                pop     si
                mov     ah, 00h
                mov     bx, 344
                mov     cx, 264
                jmp     print_xy
print_progress  ENDP



compute         PROC
                call    hide_mouse
                call    init_stack
                call    cls
                mov     ax, 148
                mov     cx, 491
                mov     bx, 160
                mov     dx, 319
                call    draw_window1
                mov     si, offset message_6
                mov     ah, 04h
                mov     bx, 176
                call    print_center
                mov     si, offset message_3
                mov     ah, 04h
                mov     bx, 288
                mov     cx, 208
                call    print_xy
                mov     si, offset message_7
                mov     ah, 01h
                mov     bx, 264
                mov     cx, 264
                call    print_xy
                mov     si, offset message_esc
                mov     ah, 0Fh
                mov     bx, 204
                mov     cx, 448
                call    print_xy

                mov     bx, offset x2
                call    load_num
                mov     bx, offset x1
                call    c_sub
                mov     bx, offset len
                call    get_middle
                call    empty_store
                mov     di, offset curr_len
                xor     eax, eax
                stosd
                stosd
                stosw
                mov     si, bx
                mov     di, offset d_x
                mov     cx, 5
                rep     movsw
                mov     bx, offset x1
                call    load_num
                mov     bx, offset xk
                call    get_middle
                mov     bx, offset int_buffer-20
                call    i_store
                mov     byte ptr int_signs-1, 80h
                mov     int_num, -1
@@loop_0:
                mov     ah, 01h
                int     16h
                jz      @@pass
                mov     ah, 00h
                int     16h
                cmp     ah, 01h
                je      @@esc_err
@@pass:
                mov     bx, offset xk
                call    load_num
                call    duplicate
                mov     bx, offset d_x
                call    c_add
                call    i_hull
                call    function
                jc      @@errors
                call    test_zero
                pushf
                call    empty_store
                popf
                jnz     @@no_zero
                mov     si, offset d_x
                mov     di, offset variable
                mov     bx, di
                mov     cx, 5
                rep     movsw
                mov     dx, offset two
                call    n_div
                mov     ax, 7FF8h
                cmp     byte ptr xk+7, 0
                je      @@zero
                mov     ax, word ptr xk+8
                shl     ax, 1
                sub     ax, 20
                shr     ax, 1
@@zero:
                mov     di, offset variable+10
                mov     [di+8], ax
                xor     eax, eax
                stosd
                stosd
                mov     byte ptr [di-1], 10h
                mov     si, offset variable
                mov     di, offset variable+10
                call    compare
                jae     @@cont_0
                mov     di, offset d_x
                mov     cx, 5
                rep     movsw
                jmp     @@loop_0
@@cont_0:
                mov     al, 00h
                jmp     @@add_int
@@no_zero:
                mov     al, [bx+9]
                shr     al, 7
                xor     al, 1
                shl     al, 1
                dec     al
@@add_int:
                mov     di, int_num
                add     di, offset int_signs
                scasb
                je      @@cont_1
                stosb
                inc     int_num
                mov     di, int_num
                imul    di, 20
                add     di, offset int_buffer
                lea     si, [di-10]
                mov     cx, 5
                rep     movsd
                jmp     @@cont_2
@@cont_1:
                mov     si, offset curr_len
                mov     di, offset variable
                push    di
                mov     cx, 5
                rep     movsw
                pop     bx
                mov     dx, offset d_x
                push    dx
                push    bx
                call    n_add
                mov     bx, offset xk
                mov     dx, offset d_x
                call    n_add
                pop     bx
                xor     byte ptr [bx+9], 80h
                mov     dx, offset len
                call    n_add
                pop     si
                mov     di, offset variable+10
                push    di
                mov     cx, 5
                rep     movsw
                pop     bx
                mov     dx, offset two
                push    bx
                call    n_mul
                pop     si
                mov     di, offset variable
                call    compare
                jae     @@pass_0
                mov     si, di
@@pass_0:
                mov     di, offset d_x
                mov     cx, 5
                rep     movsw
@@cont_2:
                mov     bx, offset xk
                call    load_num
                mov     bx, int_num
                imul    bx, 20
                add     bx, offset int_buffer
                push    bx
                call    im_hull
                pop     bx
                call    i_store
                call    empty_load
                mov     bx, offset x1
                call    load_num
                call    i_hull
                mov     bx, offset curr_len
                call    get_width
                call    empty_store
                call    load_num
                mov     bx, offset len
                call    c_div
                mov     ax, 100
                call    cm_mul
                call    get_top
                add     bx, 10
                call    get_int
                call    print_progress
                call    empty_store
                mov     di, offset curr_len
                mov     si, offset len
                call    compare
                jb      @@loop_0

                call    cls
                mov     ax, 50
                mov     bx, 50
                mov     cx, 590
                mov     dx, 430
                call    draw_window1
                mov     si, offset message_res
                mov     ah, 0Fh
                mov     bx, 31
                call    print_center
                mov     si, offset message_res2
                mov     ah, 08h
                mov     bx, 80
                mov     cx, 60
                call    print_xy
                mov     ax, 0
@@loop_1:
                push    ax
                mov     si, offset int_signs
                add     si, ax
                lodsb
                mov     ah, '0'
                and     al, al
                jz      @@next_0
                mov     ah, '-'
                inc     al
                jz      @@next_0
                mov     ah, '+'
@@next_0:
                mov     al, ah
                xor     ah, ah
                pop     cx
                push    cx
                shl     cx, 4
                add     cx, 80
                mov     bx, 88
                call    print_sym
                pop     ax
                push    ax
                mov     bx, offset int_buffer
                imul    ax, 20
                add     bx, ax
                mov     di, offset low_pr
                push    bx
                call    asc_func
                pop     bx
                add     bx, 10
                mov     di, offset high_pr
                call    asc_func
                mov     si, offset interval
                mov     ah, 00h
                pop     cx
                push    cx
                shl     cx, 4
                add     cx, 80
                mov     bx, 120
                call    print_xy
                pop     ax
                inc     ax
                cmp     int_num, ax
                jae     @@loop_1
                call    show_mouse
                mov     si, offset end2_button
                mov     ax, 1
                jmp     buttons
@@errors:
                cmp     ax, 3
                je      @@ok_err
                cmp     ax, 5
                je      @@ok_err
                cmp     ax, 14
                je      @@esc_err
                mov     si, offset error_1
                jmp     error
@@ok_err:
                mov     si, offset error_0
@@esc_err:
                mov     si, offset error_4
                jmp     error
compute         ENDP



cvert_line      PROC
                cmp     cx, 440
                jbe     @@clip_0
                mov     cx, 440
                cmp     dx, 440
                jbe     @@clip_0
                ret
@@clip_0:
                and     dx, dx
                jns     vert_line
                xor     dx, dx
                and     cx, cx
                jns     vert_line
                ret
cvert_line      ENDP



func            PROC
                DB      1000h dup (90h) ; килобайт NOP'ов
func            ENDP



deriv1          PROC
                DB      1000h dup (90h) ; килобайт NOP'ов
deriv1          ENDP



deriv2          PROC
                DB      1000h dup (90h) ; килобайт NOP'ов
deriv2          ENDP






old_int_vec     DD      ?

                .DATA
message_0       DB      'Исследование функции', 00h
                DB      'одной переменной.', 00h
                DB      'Автор: Юровский М.B.', 00h
                DB      'СПбГУ, ПМ-ПУ, 24 группа', 00h
                DB      '31 мая 2000 года', 00h
message_1       DB      'Исследование функции одной переменной', 00h
asc_for_exit    DB      'Вы действительно хотите выйти?', 00h
el_message      DB      'Исследуемая функция', 00h
elect_message   DB      'Выберите исследуемую функцию', 00h

message_2       DB      'Идет расчет координат.', 00h
message_3       DB      'Ждите...', 00h
message_4       DB      'Прошло времени:', 00h
message_5       DB      'Оценка времени:', 00h
message_esc     DB      'Нажмите <Esc> для прерывания.', 00h
message_time    LABEL
hours           DB      '**:'
mins            DB      '**:'
secs            DB      '**', 00h

message_6       DB      'Идут вычисления.', 00h
message_7       DB      'Прогресс:',00h
message_res     DB      'Найденные промежутки', 00h
message_res2    DB      'Знак                       Промежуток', 00h

x               DB      'x: '
x_str           DB      '*************************', 00h
y               DB      'y: '
y_str           DB      '*************************', 00h
interval        DB      '['
low_pr          DB      '*************************, '
high_pr         DB      '*************************]', 00h

f_message       DB      'Исследуемая функция', 00h
fx              DB      'f(x)  =', 00h
g_message       DB      'Первая производная исследуемой функции', 00h
gx              DB      'f', 27h, '(x) =', 00h
h_message       DB      'Вторая производная исследуемой функции', 00h
hx              DB      'f', 27h, 27h, '(x)=', 00h
x_message       DB      'Отрезок X машинного расчета', 00h
sx1             DB      'x1=', 00h
sx2             DB      'x2=', 00h

ok_button       DW      297, 325, 5
                DB      'Далее', 00h
exit_buttons    DW      269, 240, 4
                DB      ' Да ', 00h
                DW      325, 240, 5
                DB      ' Нет ', 00h
ent_buttons     LABEL
gr_ebutton      DW      105, 380, 16
                DB      'Построить график', 00h
comp_ebutton    DW      257, 380, 11
                DB      'Поиск нулей', 00h
help_ebutton    DW      369, 380, 6
                DB      'Помощь', 00h
esc_ebutton     DW      441, 380, 11
exit_to_dos     DB      'Выход в DOS', 00h
el_buttons      DW      209, 246, 6
                DB      ' f(x) ', 00h
                DW      281, 246, 7
                DB      ' f', 27h, '(x) ', 00h
                DW      361, 246, 8
                DB      ' f', 27h, 27h, '(x) ', 00h
end_button      DW      289, 449, 7
                DB      'Возврат', 00h
error_button    DW      297, 270, 5
                DB      'Далее', 00h
end2_button     DW      289, 400, 7
                DB      'Возврат', 00h

error_0         DB      '              Ошибка!              '
                DB      '    Аргумент функции вне области   '
                DB      '            определения.           ', 00h
error_1         DB      '              Ошибка!              '
                DB      '   Произошла неизвестная ошибка.   '
                DB      '    Возможно, это сбой в работе    '
                DB      '             программы.            ', 00h
error_4         DB      '                                   '
                DB      '           Нажат <Esc>.            '
                DB      '      Вычисления остановлены.      ', 00h

help_main       DW      1
                DB      '      Исследование функции одной переменной.     '
                DB      '                                                 '
                DB      '  Введите  исследуемую функцию f(x), а также если'
                DB      'необходимо,  ее  производные.  Можно использовать'
                DB      'операции  +,  -,  *,  /,  ^, а также функции sqrt'
                DB      '(квадратный  корень), exp (экспонента), ln (нату-'
                DB      'ральный логарифм). Независимая переменная - x.   '
                DB      '  Отрезок машинного расчета - отрезок, на котором'
                DB      'будет осуществлятся поиск нулей и построение гра-'
                DB      'фика.                                            '
                DB      00h

my_func         DB      'ln(1+x^2)+1/ln(2+x^2)-5', 00h
my_func_len     =       $-my_func
my_deriv1       DB      '1/(1+x^2)-1/((2+x^2)*ln(2+x^2)^2)', 00h
my_deriv1_len   =       $-my_deriv1
my_deriv2       DB      '(2*x^2-4)/((2+x^2)^2*ln(2+x^2)^2)+8*x^2/((2+x^2)^2*ln(2+x^2)^3)+(2-2*x^2)/(1+x^2)^2', 00h
my_deriv2_len   =       $-my_deriv2
my_x1           DB      '-21', 00h
my_x1_len       =       $-my_x1
my_x2           DB      '21', 00h
my_x2_len       =       $-my_x2

two             DD      00000000h, 20000000h
                DW      0000h

                .DATA?
str_buffers     LABEL
str_func        DB      200h dup (?)
str_deriv1      DB      200h dup (?)
str_deriv2      DB      200h dup (?)
str_x1          DB      26 dup (?)
str_x2          DB      26 dup (?)
edit_buffer     DB      200h dup (?)

x1              DT      ?               ; левая граница ОМР
x2              DT      ?               ; правая граница ОМР
d_x             DT      ?               ; шаг вычислений
xk              DT      ?               ; текущий x
min             DT      ?
max             DT      ?
h_x             DT      ?
len             DT      ?
curr_len        DT      ?
variable        DT      2 dup (?)

num             DB      5 dup (?)

sec0            DB      ?
function        DW      ?               ; исследуемая функция
old_x           DW      ?
old_y           DW      ?
c_rang          DW      ?
int_num         DW      ?
time            DD      ?

array           DT      1280 dup (?)    ; 640*20 - массив вещ. координат точек
                DT      10 dup (?)
func_consts     DT      100 dup (?)     ; буфер на 100 констант
deriv1_consts   DT      100 dup (?)
deriv2_consts   DT      100 dup (?)
                DT      ?, ?
int_buffer      DT      512 dup (?)
                DB      ?
int_signs       DB      256 dup (?)


                .STACK  4000h

                END     begin
