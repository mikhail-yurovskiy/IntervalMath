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
                mov     si, offset fxy
                mov     ah, 00h
                mov     bx, 81
                mov     cx, 80
                call    print_xy
                mov     ax, 117
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
                mov     si, offset gxy
                mov     ah, 00h
                mov     bx, 81
                mov     cx, 140
                call    print_xy
                mov     ax, 117
                mov     cx, 558
                mov     bx, 140
                mov     dx, 157
                call    set_window2
                mov     si, offset str_deriv
                mov     ah, 00h
                call    print

                mov     si, offset xy_message
                mov     ah, 08h
                mov     bx, 180
                call    print_center
                mov     si, offset sx0
                mov     ah, 00h
                mov     bx, 76
                mov     cx, 200
                call    print_xy
                mov     ax, 104
                mov     cx, 305
                mov     bx, 200
                mov     dx, 217
                call    set_window2
                mov     si, offset str_x0
                mov     ah, 00h
                call    print

                mov     si, offset sy0
                mov     ah, 00h
                mov     bx, 338
                mov     cx, 200
                call    print_xy
                mov     ax, 366
                mov     cx, 567
                mov     bx, 200
                mov     dx, 217
                call    set_window2
                mov     si, offset str_y0
                mov     ah, 00h
                call    print

                mov     si, offset x_message
                mov     ah, 08h
                mov     bx, 240
                call    print_center
                mov     si, offset sx1
                mov     ah, 00h
                mov     bx, 76
                mov     cx, 260
                call    print_xy
                mov     ax, 104
                mov     cx, 305
                mov     bx, 260
                mov     dx, 277
                call    set_window2
                mov     si, offset str_x1
                mov     ah, 00h
                call    print

                mov     si, offset sx2
                mov     ah, 00h
                mov     bx, 338
                mov     cx, 260
                call    print_xy
                mov     ax, 366
                mov     cx, 567
                mov     bx, 260
                mov     dx, 277
                call    set_window2
                mov     si, offset str_x2
                mov     ah, 00h
                call    print

                mov     si, offset n_message
                mov     ah, 08h
                mov     bx, 310
                call    print_center
                mov     si, offset sn
                mov     ah, 00h
                mov     bx, 285
                mov     cx, 330
                call    print_xy
                mov     ax, 305
                mov     cx, 354
                mov     bx, 330
                mov     dx, 347
                call    set_window2
                mov     si, offset str_rang
                mov     ah, 00h
                call    print

                mov     si, offset ent_buttons
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
                mov     si, offset ok_ebutton
                call    if_click
                jnc     to_grafic
                mov     si, offset esc_ebutton
                call    if_click
                jnc     asc_exit
                mov     si, offset help_ebutton
                call    if_click
                jnc     help
                cmp     cx, 117
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
                mov     ax, 117
                mov     bx, 80
                mov     cx, 55
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
                mov     ax, 117
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
                cmp     cx, 117
                jb      next_1
                cmp     cx, 559
                jae     next_1
                cmp     dx, 140
                jb      next_1
                cmp     dx, 157
                jae     next_1
                call    hide_mouse
                mov     si, offset str_deriv
                mov     di, offset edit_buffer
                mov     cx, 0200h
                rep     movsb
enter_gx:
                mov     di, offset edit_buffer
                mov     ax, 117
                mov     bx, 140
                mov     cx, 55
                mov     dx, 01FFh
                stc
                call    input
                jc      no_change1
                push    cs
                pop     fs
                mov     bp, offset deriv
                mov     si, offset edit_buffer
                mov     di, offset deriv_consts
                call    make_mthproc
                jnc     cont_1
                call    beep
                mov     bp, offset deriv
                mov     si, offset str_deriv
                mov     di, offset deriv_consts
                call    make_mthproc
                jmp     enter_gx
cont_1:
                mov     si, offset edit_buffer
                mov     di, offset str_deriv
                mov     cx, 0200h
                rep     movsb
no_change1:
                mov     ax, 117
                mov     cx, 558
                mov     bx, 140
                mov     dx, 157
                call    set_window2
                mov     si, offset str_deriv
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     loop_0
next_1:
                cmp     cx, 104
                jb      next_2
                cmp     cx, 306
                jae     next_2
                cmp     dx, 200
                jb      next_2
                cmp     dx, 217
                jae     next_2
                call    hide_mouse
                mov     si, offset str_x0
                mov     di, offset edit_buffer
                mov     cx, 001Ah
                rep     movsb
enter_x0:
                mov     di, offset edit_buffer
                mov     ax, 104
                mov     bx, 200
                mov     cx, 25
                mov     dx, 25
                stc
                call    input
                jc      no_change2
                and     ax, ax
                jz      err_2
                call    del_spaces
                cmp     [si], cl
                je      err_2
                mov     bx, offset x0
                call    val_func
                jnc     cont_2
                mov     si, offset str_x0
                mov     bx, offset x0
                call    val_func
err_2:
                call    beep
                jmp     enter_x0
cont_2:
                mov     si, offset edit_buffer
                mov     di, offset str_x0
                mov     cx, 001Ah
                rep     movsb
no_change2:
                mov     ax, 104
                mov     cx, 305
                mov     bx, 200
                mov     dx, 217
                call    set_window2
                mov     si, offset str_x0
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     loop_0
next_2:
                cmp     cx, 366
                jb      next_3
                cmp     cx, 568
                jae     next_3
                cmp     dx, 260
                jb      next_3
                cmp     dx, 277
                jae     next_3
                call    hide_mouse
                mov     si, offset str_x2
                mov     di, offset edit_buffer
                mov     cx, 001Ah
                rep     movsb
enter_x2:
                mov     di, offset edit_buffer
                mov     ax, 366
                mov     bx, 260
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
                mov     bx, 260
                mov     dx, 277
                call    set_window2
                mov     si, offset str_x2
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     loop_0
next_3:
                cmp     cx, 104
                jb      next_4
                cmp     cx, 306
                jae     next_4
                cmp     dx, 260
                jb      next_4
                cmp     dx, 277
                jae     next_4
                call    hide_mouse
                mov     si, offset str_x1
                mov     di, offset edit_buffer
                mov     cx, 001Ah
                rep     movsb
enter_x1:
                mov     di, offset edit_buffer
                mov     ax, 104
                mov     bx, 260
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
                mov     bx, 260
                mov     dx, 277
                call    set_window2
                mov     si, offset str_x1
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     loop_0
next_4:
                cmp     cx, 366
                jb      next_5
                cmp     cx, 568
                jae     next_5
                cmp     dx, 200
                jb      next_5
                cmp     dx, 218
                jae     next_5
                call    hide_mouse
                mov     si, offset str_y0
                mov     di, offset edit_buffer
                mov     cx, 001Ah
                rep     movsb
enter_y0:
                mov     di, offset edit_buffer
                mov     ax, 366
                mov     bx, 200
                mov     cx, 25
                mov     dx, 25
                stc
                call    input
                jc      no_change5
                and     ax, ax
                jz      err_5
                call    del_spaces
                cmp     [si], cl
                je      err_5
                mov     bx, offset y0
                call    val_func
                jnc     cont_5
                mov     si, offset str_y0
                mov     bx, offset y0
                call    val_func
err_5:
                call    beep
                jmp     enter_y0
cont_5:
                mov     si, offset edit_buffer
                mov     di, offset str_y0
                mov     cx, 001Ah
                rep     movsb
no_change5:
                mov     ax, 366
                mov     cx, 567
                mov     bx, 200
                mov     dx, 217
                call    set_window2
                mov     si, offset str_y0
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     loop_0
next_5:
                cmp     cx, 305
                jb      loop_0
                cmp     cx, 355
                jae     loop_0
                cmp     dx, 330
                jb      loop_0
                cmp     dx, 348
                jae     loop_0
                call    hide_mouse
                mov     si, offset str_rang
                mov     di, offset edit_buffer
                mov     cx, 0006h
                rep     movsb
enter_rang:
                mov     di, offset edit_buffer
                mov     ax, 305
                mov     bx, 330
                mov     cx, 6
                mov     dx, 5
                stc
                call    input
                jc      no_change6
                and     ax, ax
                jz      err_6
                call    del_spaces
                cmp     [si], al
                je      err_6
                mov     bx, offset rang_d
                call    val_func
                jnc     cont_6
err_6:
                call    beep
                jmp     enter_rang
cont_6:
                mov     bx, offset rang_d
                call    get_int
                jc      err_6
                and     ax, ax
                jz      err_6
                mov     rang, ax
                mov     si, offset edit_buffer
                mov     di, offset str_rang
                mov     cx, 0006h
                rep     movsb
no_change6:
                mov     ax, 305
                mov     cx, 354
                mov     bx, 330
                mov     dx, 347
                call    set_window2
                mov     si, offset str_rang
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
                call    hide_mouse
                call    cls
                mov     ax, 180
                mov     bx, 202
                mov     cx, 460
                mov     dx, 278
                call    draw_window1
                mov     si, offset met_message
                mov     ah, 0Fh
                mov     bx, 178
                call    print_center
                mov     si, offset meth_message
                mov     ah, 08h
                mov     bx, 212
                call    print_center
                call    show_mouse
                mov     si, offset meth_buttons
                mov     ax, 2
                call    buttons
                jc      main_loop
                mov     method, al
                call    grafic
                push    ds
                mov     ax, 251Ch
                lds     dx, cs:old_int_vec
                int     21h
                pop     ds
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
                mov     si, offset my_deriv
                mov     di, offset str_deriv
                push    di
                mov     cx, my_deriv_len
                rep     movsb
                pop     si
                mov     di, offset deriv_consts
                mov     bp, offset deriv
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
                mov     si, offset my_x0
                mov     di, offset str_x0
                push    di
                mov     cx, my_x0_len
                rep     movsb
                pop     si
                mov     bx, offset x0
                call    val_func
                mov     si, offset my_y0
                mov     di, offset str_y0
                push    di
                mov     cx, my_y0_len
                rep     movsb
                pop     si
                mov     bx, offset y0
                call    val_func
                mov     si, offset my_rang
                mov     di, offset str_rang
                push    di
                mov     cx, my_rang_len
                rep     movsb
                pop     si
                mov     bx, offset rang_d
                push    bx
                call    val_func
                pop     bx
                call    get_int
                mov     rang, ax
                ret
init_task       ENDP



intro           PROC
                call    hide_mouse
                call    cls
                mov     ax, 190
                mov     cx, 450
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



found_dy        PROC
                mov     bx, offset Xk
                call    i_load          ; Xk
                mov     bx, offset Yk
                call    i_load          ; Yk, Xk
                call    func            ; F(Xk, Yk)
                jc      @@exit
                mov     bx, offset hx
                call    c_mul           ; x*F(Xk, Yk)
                mov     bx, offset Yk
                call    im_add          ; Yk + x*F(Xk, Yk)
                mov     bx, offset dY
                push    bx
                call    i_store
                pop     bx
                mov     ax, [bx+8]
                mov     cx, [bx+18]
                shl     ax, 1
                shl     cx, 1
                add     ax, cx
                clc
                js      @@exit
                cmp     ax, 100
                mov     ax, 15
                cmc
@@exit:
                ret
found_dy        ENDP



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
                movzx   ecx, rang
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



get_int2        PROC
                mov     si, bx
                mov     di, offset variable
                push    bx
                mov     bx, di
                mov     cx, 5
                rep     movsw
                call    get_int
                pop     bx
                ret
get_int2        ENDP



grafic          PROC
                call    hide_mouse
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

                mov     di, offset array
                xor     eax, eax
                mov     cx, 3200
                rep     stosd

                mov     bx, offset x1
                call    load_num
                mov     bx, offset x2
                call    load_num
                call    i_hull
                mov     bx, offset scr_hx
                push    bx
                call    get_width
                mov     dx, offset n640
                call    n_div
                mov     bx, offset x0
                call    load_num
                call    i_hull
                mov     bx, offset hx
                push    bx
                call    get_width
                call    empty_store
                call    load_num
                mov     ax, rang
                call    cm_div
                pop     bx
                push    bx
                call    get_middle
                call    empty_store
                pop     si
                mov     di, offset pix_in_hx
                mov     bx, di
                mov     cx, 5
                rep     movsw
                pop     dx
                call    n_div
                mov     di, offset x0
                mov     si, offset x1
                call    compare
                jb      @@to_search_y1
                mov     si, offset x2
                call    compare
                ja      @@to_search_y2
; x0 принадлежит отрезку [x1,x2]
                mov     si, offset x1
                call    compare
                je      @@no_back_move
; x0 больше x1, т.е. идем в обратном направлении
                mov     bx, offset y0
                call    load_num
                mov     bx, offset Yk
                call    i_store         ; инициализация Yk
@@to_cont_y2:
                mov     bx, offset x0
                call    load_num
                mov     bx, offset x1
                call    load_num
                call    i_hull
                mov     bx, offset pix_shift
                call    get_width
                call    empty_store
                mov     dx, offset hx
                push    bx
                call    n_div
                pop     bx
                mov     dx, offset pix_in_hx
                call    n_mul
                mov     si, offset x0
                mov     di, offset xk
                mov     cx, 5
                rep     movsw           ; инициализация xk
                or      byte ptr hx+9, 80h
@@loop_0:
                mov     bx, offset pix_shift
                call    get_int2
                imul    ax, 20
                add     ax, offset array
                mov     di, ax
                mov     si, offset Yk
                mov     cx, 5
                rep     movsd
                mov     bx, offset xk
                call    load_num        ; xk
                call    duplicate       ; xk, xk
                mov     bx, offset hx
                call    c_add           ; xk+1, xk
                call    i_hull          ; Xk
                mov     bx, offset Xk
                call    i_store
                call    found_dy
                jnc     @@cont_0
                cmp     ax, 15
                jne     @@errors
@@lp_0:
                mov     bx, offset pix_shift
                mov     dx, offset pix_in_hx
                call    n_sub
                mov     bx, offset xk
                push    bx
                mov     dx, offset hx
                call    n_add
                mov     bx, offset pix_shift
                call    get_int2
                imul    ax, 20
                add     ax, offset array
                mov     di, ax
                mov     si, offset Yk
                mov     cx, 5
                rep     movsd
                pop     di
                mov     si, offset x1
                inc     c_rang
                call    compare
                jae     @@lp_0
                jmp     @@no_back_move
@@cont_0:
                mov     bx, offset Xk   ; Xk
                call    i_load
                mov     bx, offset dY
                call    i_load          ; Yk, Xk
                call    func            ; F(Xk, Yk)
                jc      @@errors
                mov     bx, offset hx
                call    c_mul           ; x*F(Xk, Yk)
                mov     bx, offset Yk
                push    bx
                call    im_add          ; Yk+1 = Yk + x*F(Xk, Yk)
                pop     bx
                call    i_store
                mov     ah, 01h
                int     16h
                jz      @@pass_0
                mov     ah, 00h
                int     16h
                cmp     ah, 01h
                je      @@esc_err
@@pass_0:
                mov     bx, offset pix_shift
                mov     dx, offset pix_in_hx
                call    n_sub
                mov     bx, offset xk
                push    bx
                mov     dx, offset hx
                call    n_add
                pop     di
                mov     si, offset x1
                inc     c_rang
                call    compare
                jae     @@loop_0
@@no_back_move:
                and     byte ptr hx+9, 7Fh
                mov     si, offset x2
                mov     di, offset x0
                call    compare
                je      @@no_forw_move
; x0 меньше x2, т.е. идем в прямом направлении
                mov     bx, offset y0
                call    load_num
                mov     bx, offset Yk
                call    i_store         ; инициализация Yk
@@to_cont_y1:
                mov     bx, offset x0
                call    load_num
                mov     bx, offset x1
                call    load_num
                call    i_hull
                mov     bx, offset pix_shift
                call    get_width
                call    empty_store
                mov     dx, offset hx
                push    bx
                call    n_div
                pop     bx
                mov     dx, offset pix_in_hx
                call    n_mul
                mov     si, offset x0
                mov     di, offset xk
                mov     cx, 5
                rep     movsw           ; инициализация xk
@@loop_1:
                mov     bx, offset pix_shift
                call    get_int2
                imul    ax, 20
                add     ax, offset array
                mov     di, ax
                mov     si, offset Yk
                mov     cx, 5
                rep     movsd
                mov     bx, offset xk
                call    load_num        ; xk
                call    duplicate       ; xk, xk
                mov     bx, offset hx
                call    c_add           ; xk+1, xk
                call    i_hull          ; Xk
                mov     bx, offset Xk
                call    i_store
                call    found_dy
                jnc     @@cont_1
                cmp     ax, 15
                jne     @@errors
@@lp_1:
                mov     bx, offset pix_shift
                mov     dx, offset pix_in_hx
                call    n_add
                mov     bx, offset xk
                push    bx
                mov     dx, offset hx
                call    n_add
                mov     bx, offset pix_shift
                call    get_int2
                imul    ax, 20
                add     ax, offset array
                mov     di, ax
                mov     si, offset Yk
                mov     cx, 5
                rep     movsd
                pop     si
                mov     di, offset x2
                inc     c_rang
                call    compare
                jae     @@lp_1
                jmp     @@no_forw_move
@@cont_1:
                mov     bx, offset Xk   ; Xk
                call    i_load
                mov     bx, offset dY
                call    i_load          ; Yk, Xk
                call    func            ; F(Xk, Yk)
                jc      @@errors
                mov     bx, offset hx
                call    c_mul           ; x*F(Xk, Yk)
                mov     bx, offset Yk
                push    bx
                call    im_add          ; Yk+1 = Yk + x*F(Xk, Yk)
                pop     bx
                call    i_store
                mov     ah, 01h
                int     16h
                jz      @@pass_1
                mov     ah, 00h
                int     16h
                cmp     ah, 01h
                je      @@esc_err
@@pass_1:
                mov     bx, offset pix_shift
                mov     dx, offset pix_in_hx
                call    n_add
                mov     si, offset xk
                mov     di, offset x2
                call    compare
                jb      @@no_forw_move
                mov     bx, si
                mov     dx, offset hx
                call    n_add
                inc     c_rang
                jmp     @@loop_1
@@no_forw_move:
; соединить линии; найти min, max; (max-min)/480 = h; scr_y = (real_y-min)/h
                push    ds
                mov     ax, 251Ch
                lds     dx, cs:old_int_vec
                int     21h
                pop     ds
                call    cls
                mov     bx, offset pix_in_hx
                call    get_int2
                and     ax, ax
                jz      @@no_lines
                mov     pixels, ax
                mov     bx, offset x0
                call    load_num
                mov     bx, offset x1
                call    load_num
                call    i_hull
                mov     bx, offset pix_shift
                call    get_width
                call    empty_store
                mov     dx, offset hx
                push    bx
                call    n_div
                pop     bx
                mov     dx, offset pix_in_hx
                call    n_mul
@@loop_4:
                mov     bx, offset pix_shift
                call    get_int2
                cmp     ax, pixels
                jb      @@next_0
                push    ax
                push    bx
                mov     dx, offset pix_in_hx
                call    n_sub
                pop     bx
                call    get_int2
                pop     si              ; AX - x1, SI - x2
                mov     bx, si
                sub     bx, ax          ; x
                imul    ax, 20
                imul    si, 20
                add     si, offset array
                add     ax, offset array
                mov     di, offset variable
                mov     cx, 5
                push    bx
                mov     bx, di
                rep     movsd
                mov     dx, ax
                push    ax
                push    bx
                push    dx
                call    n_sub
                pop     dx
                pop     bx
                push    bx
                add     dx, 10
                add     bx, 10
                call    n_sub
                pop     bx
                mov     dx, offset pix_in_hx
                push    dx
                push    bx
                call    n_div
                pop     bx
                pop     dx
                push    bx
                add     bx, 10
                call    n_div
                pop     dx              ; dy/dx
                pop     bx              ; y1
                pop     cx
@@loop_5:
                add     bx, 20
                dec     cx
                jz      @@loop_4
                push    cx
                lea     si, [bx-20]
                mov     di, bx
                mov     cx, 5
                rep     movsd
                push    bx
                push    dx
                call    n_add
                pop     dx
                pop     bx
                push    bx
                push    dx
                add     bx, 10
                add     dx, 10
                call    n_add
                pop     dx
                pop     bx
                pop     cx
                jmp     @@loop_5
@@next_0:
                mov     bx, ax
                imul    ax, 20
                add     ax, offset array
                mov     si, ax
                lea     di, [si-20]
@@small:
                and     bx, bx
                jz      @@no_small
                dec     bx
                push    di
                push    si
                mov     cx, 5
                rep     movsd
                pop     si
                pop     di
                sub     di, 20
                jmp     @@small
@@no_small:
                mov     bx, offset x0
                call    load_num
                mov     bx, offset x1
                call    load_num
                call    i_hull
                mov     bx, offset pix_shift
                call    get_width
                call    empty_store
                mov     dx, offset hx
                push    bx
                call    n_div
                pop     bx
                mov     dx, offset pix_in_hx
                call    n_mul
@@loop_6:
                mov     bx, offset pix_shift
                call    get_int2
                cmp     ax, 641
                jae     @@no_lines
                push    ax
                push    bx
                mov     dx, offset pix_in_hx
                call    n_add
                pop     bx
                call    get_int2
                pop     si              ; AX - x2, SI - x1
                mov     bx, ax
                sub     bx, si          ; x
                xchg    ax, si
                imul    ax, 20
                imul    si, 20
                add     si, offset array
                add     ax, offset array
                mov     di, offset variable
                mov     cx, 5
                push    bx
                mov     bx, di
                rep     movsd
                mov     dx, ax
                push    ax
                push    bx
                push    dx
                call    n_sub
                pop     dx
                pop     bx
                push    bx
                add     dx, 10
                add     bx, 10
                call    n_sub
                pop     bx
                mov     dx, offset pix_in_hx
                push    dx
                push    bx
                call    n_div
                pop     bx
                pop     dx
                push    bx
                add     bx, 10
                call    n_div
                pop     dx              ; dy/dx
                pop     bx              ; y1
                pop     cx
@@loop_7:
                add     bx, 20
                dec     cx
                jz      @@loop_6
                push    cx
                lea     si, [bx-20]
                mov     di, bx
                mov     cx, 5
                rep     movsd
                push    bx
                push    dx
                call    n_add
                pop     dx
                pop     bx
                push    bx
                push    dx
                add     bx, 10
                add     dx, 10
                call    n_add
                pop     dx
                pop     bx
                pop     cx
                jmp     @@loop_7
@@no_lines:
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
@@to_search_y1:
; x0 не лежит на экране, т.е. надо найти y(x1)=y1 и принять новые нач. данные
                mov     bx, offset y0
                call    load_num
                mov     bx, offset Yk
                call    i_store         ; инициализация Yk
                mov     si, offset x0
                mov     di, offset xk
                mov     cx, 5
                rep     movsw           ; инициализация xk
@@loop_2:
                mov     bx, offset xk
                call    load_num        ; xk
                call    duplicate       ; xk, xk
                mov     bx, offset hx
                call    c_add           ; xk+1, xk
                call    i_hull          ; Xk
                mov     bx, offset Xk
                call    i_store
                call    found_dy
                jc      @@errors
                mov     bx, offset Xk   ; Xk
                call    i_load
                mov     bx, offset dY
                call    i_load          ; Yk, Xk
                call    func            ; F(Xk, Yk)
                jc      @@errors
                mov     bx, offset hx
                call    c_mul           ; x*F(Xk, Yk)
                mov     bx, offset Yk
                push    bx
                call    im_add          ; Yk+1 = Yk + x*F(Xk, Yk)
                pop     bx
                call    i_store
                mov     ah, 01h
                int     16h
                jz      @@pass_2
                mov     ah, 00h
                int     16h
                cmp     ah, 01h
                je      @@esc_err
@@pass_2:
                mov     bx, offset xk
                push    bx
                mov     dx, offset hx
                call    n_add
                pop     di
                mov     si, offset x1
                inc     c_rang
                call    compare
                jb      @@loop_2
                mov     di, offset x0
                mov     cx, 5
                rep     movsw
                jmp     @@to_cont_y1
@@to_search_y2:
; x0 не лежит на экране, т.е. надо найти y(x2)=y2 и принять новые нач. данные
                mov     bx, offset y0
                call    load_num
                mov     bx, offset Yk
                call    i_store         ; инициализация Yk
                mov     si, offset x0
                mov     di, offset xk
                mov     cx, 5
                rep     movsw           ; инициализация xk
                xor     byte ptr hx+9, 80h
@@loop_3:
                mov     bx, offset xk
                call    load_num        ; xk
                call    duplicate       ; xk, xk
                mov     bx, offset hx
                call    c_add           ; xk+1, xk
                call    i_hull          ; Xk
                mov     bx, offset Xk
                call    i_store
                call    found_dy
                jc      @@errors
                mov     bx, offset Xk   ; Xk
                call    i_load
                mov     bx, offset dY
                call    i_load          ; Yk, Xk
                call    func            ; F(Xk, Yk)
                jc      @@errors
                mov     bx, offset hx
                call    c_mul           ; x*F(Xk, Yk)
                mov     bx, offset Yk
                push    bx
                call    im_add          ; Yk+1 = Yk + x*F(Xk, Yk)
                pop     bx
                call    i_store
                mov     ah, 01h
                int     16h
                jz      @@pass_3
                mov     ah, 00h
                int     16h
                cmp     ah, 01h
                je      @@esc_err
@@pass_3:
                mov     bx, offset xk
                push    bx
                mov     dx, offset hx
                call    n_add
                pop     si
                mov     di, offset x2
                inc     c_rang
                call    compare
                jb      @@loop_3
                mov     si, di
                mov     di, offset x0
                mov     cx, 5
                rep     movsw
                xor     byte ptr hx+9, 80h
                jmp     @@to_cont_y2
@@errors:
                cmp     ax, 3
                je      @@ok_err
                cmp     ax, 5
                je      @@ok_err
                cmp     ax, 14
                je      @@esc_err
                mov     si, offset error_2
                cmp     ax, 15
                je      error
                mov     si, offset error_1
                jmp     error
@@esc_err:
                mov     bx, offset x0
                mov     si, offset str_x0
                call    val_func
                mov     bx, offset y0
                mov     si, offset str_y0
                call    val_func
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



deriv           PROC
                DB      1000h dup (90h) ; килобайт NOP'ов
deriv           ENDP





old_int_vec     DD      ?

                .DATA
message_0       DB      'Численное решение', 00h
                DB      'дифференциальных уравнений.', 00h
                DB      'Автор: Юровский М.B.', 00h
                DB      'СПбГУ, ПМ-ПУ, 24 группа', 00h
                DB      '27 мая 2000 года', 00h
asc_for_exit    DB      'Вы действительно хотите выйти?', 00h
message_1       DB      'Численное решение дифференциальных уравнений.', 00h
met_message     DB      'Метод интегрирования', 00h
meth_message    DB      'Выберите метод построения решения', 00h

ok_button       DW      297, 325, 5
                DB      'Далее', 00h
exit_buttons    DW      269, 240, 4
                DB      ' Да ', 00h
                DW      325, 240, 5
                DB      ' Нет ', 00h
ent_buttons     LABEL
ok_ebutton      DW      161, 380, 16
                DB      'Построить график', 00h
help_ebutton    DW      313, 380, 6
                DB      'Помощь', 00h
esc_ebutton     DW      385, 380, 11
exit_to_dos     DB      'Выход в DOS', 00h
meth_buttons    DW      201, 246, 13
                DB      'Метод ломаных', 00h
                DW      329, 246, 13
                DB      'Метод парабол', 00h
error_button    DW      297, 270, 5
                DB      'Далее', 00h
end_button      DW      289, 449, 7
                DB      'Возврат', 00h

f_message       DB      'Дифференциальное уравнение в нормальном виде', 00h
fxy             DB      'y', 27h, ' =', 00h
g_message       DB      'Производная по x от правой части ОДУ', 00h
gxy             DB      'y', 27h, 27h, '=', 00h
xy_message      DB      'Начальные данные', 00h
sx0             DB      'x0=', 00h
sy0             DB      'y0=', 00h
x_message       DB      'Границы изменения x', 00h
sx1             DB      'x1=', 00h
sx2             DB      'x2=', 00h
n_message       DB      'Количество шагов интегрирования', 00h
sn              DB      'n=', 00h

message_2       DB      'Идет расчет координат.', 00h
message_3       DB      'Ждите...', 00h
message_4       DB      'Прошло времени:', 00h
message_5       DB      'Оценка времени:', 00h
message_esc     DB      'Нажмите <Esc> для прерывания.', 00h
message_time    LABEL
hours           DB      '**:'
mins            DB      '**:'
secs            DB      '**', 00h

x               DB      'x: '
x_str           DB      '*************************', 00h
y               DB      'y: '
y_str           DB      '*************************', 00h

error_0         DB      '              Ошибка!              '
                DB      '    Аргумент функции вне области   '
                DB      '            определения.           ', 00h
error_1         DB      '              Ошибка!              '
                DB      '   Произошла неизвестная ошибка.   '
                DB      '    Возможно, это сбой в работе    '
                DB      '             программы.            ', 00h
error_2         DB      '              Ошибка!              '
                DB      '  Между отрезком [x1,x2] и точкой  '
                DB      ' x0 найдена вертикальная асимптота.', 00h
error_4         DB      '                                   '
                DB      '           Нажат <Esc>.            '
                DB      '      Вычисления остановлены.      ', 00h

help_main       DW      1
                DB      '                   Ввод данных.                  '
                DB      '                                                 '
                DB      '  Введите  функцию y', 27h, '=f(x,y), а также производную'
                DB      'f(x,y)  по x, считая y функцией от x. Производная'
                DB      'должна явно выражаться через x и y, для этого не-'
                DB      'обходимо   воспользоваться  выражением  y', 27h, '  через'
                DB      'f(x,y).  Поддерживаемые  элементарные  функции  -'
                DB      '-  exp (экспонента), ln (натуральный логарифм) и '
                DB      'sqrt (квадратный корень), а также операции: +, -,'
                DB      '*, /, ^.                                         '
                DB      '  Границы  изменения x - минимальный и максималь-'
                DB      'ный x, изображаемые на графике.                  '
                DB      00h

;my_func         DB      'ln(x^2+y^2)-y', 00h
;my_func_len     =       $-my_func
;my_deriv        DB      '(2*x+2*y*(ln(x^2+y^2)-y))/(x^2+y^2)+ln(x^2+y^2)-y', 00h
;my_deriv_len    =       $-my_deriv
my_func         DB      'exp(y)-2*y-1', 00h
my_func_len     =       $-my_func
my_deriv        DB      'exp(2*y)-exp(y)*(2*y-3)+4*y+2', 00h
my_deriv_len    =       $-my_deriv
my_x1           DB      '-3', 00h
my_x1_len       =       $-my_x1
my_x2           DB      '3', 00h
my_x2_len       =       $-my_x2
my_rang         DB      '100', 00h
my_rang_len     =       $-my_rang
my_x0           DB      '0', 00h
my_x0_len       =       $-my_x0
my_y0           DB      '1', 00h
my_y0_len       =       $-my_y0

n640            DD      00000000h, 64000000h
                DW      0002h

                .DATA?
str_buffers     LABEL
str_func        DB      200h dup (?)
str_deriv       DB      200h dup (?)
str_x1          DB      26 dup (?)
str_x2          DB      26 dup (?)
str_x0          DB      26 dup (?)
str_y0          DB      26 dup (?)
str_rang        DB      6 dup (?)
edit_buffer     DB      200h dup (?)

rang_d          DT      ?               ; ранг разбиения
x1              DT      ?               ; левая граница
x2              DT      ?               ; правая граница
x0              DT      ?               ; начальные данные (задача Коши)
y0              DT      ?               ; начальные данные (задача Коши)
hx              DT      ?               ; длина шага (X)
scr_hx          DT      ?               ; длина 1 пиксела
xk              DT      ?               ; текущая координата X
Xk              DT      2 dup (?)       ; текущий отрезок X
Yk              DT      2 dup (?)       ; текущая координата Y
dY              DT      2 dup (?)       ; текущая грубая оценка Y
pix_in_hx       DT      ?               ; кол-во пикселей в одном шаге
pix_shift       DT      ?               ; текущее смещение в пикселах от x0
min             DT      ?
max             DT      ?
h_x             DT      ?
variable        DT      2 dup (?)

method          DB      ?
sec0            DB      ?
rang            DW      ?
c_rang          DW      ?
old_x           DW      ?
old_y           DW      ?
pixels          DW      ?
time            DD      ?

                DT      200 dup (?)
array           DT      1280 dup (?)    ; 640*20 - массив вещ. координат точек
                DT      200 dup (?)
func_consts     DB      1000 dup (?)    ; буфер на 100 констант
deriv_consts    DB      1000 dup (?)


                .STACK  4000h

                END     begin
