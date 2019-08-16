                .MODEL  small
                .386
                LOCALS  @@
                INCLUDE math.inc
                INCLUDE integr.inc
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
                mov     ax, offset func
                mov     function, ax
                mov     ax, offset deriv
                mov     derivative, ax
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
                mov     bx, 60
                mov     cx, 80
                call    print_xy
                mov     ax, 104
                mov     cx, 305
                mov     bx, 80
                mov     dx, 97
                call    set_window2
                mov     si, offset str_func
                mov     ah, 00h
                call    print

                mov     si, offset gx
                mov     ah, 00h
                mov     bx, 322
                mov     cx, 80
                call    print_xy
                mov     ax, 374
                mov     cx, 575
                mov     bx, 80
                mov     dx, 97
                call    set_window2
                mov     si, offset str_deriv
                mov     ah, 00h
                call    print

                mov     si, offset n
                mov     ah, 00h
                mov     bx, 346
                mov     cx, 104
                call    print_xy
                mov     ax, 374
                mov     cx, 391
                mov     bx, 104
                mov     dx, 121
                call    set_window2
                mov     si, offset str_num
                mov     ah, 00h
                call    print

                mov     si, offset x_message
                mov     ah, 08h
                mov     bx, 160
                call    print_center
                mov     si, offset x1
                mov     ah, 00h
                mov     bx, 68
                mov     cx, 180
                call    print_xy
                mov     ax, 104
                mov     cx, 305
                mov     bx, 180
                mov     dx, 197
                call    set_window2
                mov     si, offset str_low
                mov     ah, 00h
                call    print

                mov     si, offset x2
                mov     ah, 00h
                mov     bx, 338
                mov     cx, 180
                call    print_xy
                mov     ax, 374
                mov     cx, 575
                mov     bx, 180
                mov     dx, 197
                call    set_window2
                mov     si, offset str_high
                mov     ah, 00h
                call    print

                mov     si, offset x0_message
                mov     ah, 08h
                mov     bx, 240
                call    print_center
                mov     si, offset x0
                mov     ah, 00h
                mov     bx, 201
                mov     cx, 260
                call    print_xy
                mov     ax, 237
                mov     cx, 438
                mov     bx, 260
                mov     dx, 277
                call    set_window2
                mov     si, offset str_x0
                mov     ah, 00h
                call    print

                mov     si, offset r_message
                mov     ah, 08h
                mov     bx, 310
                call    print_center
                mov     si, offset rng
                mov     ah, 00h
                mov     bx, 281
                mov     cx, 330
                call    print_xy
                mov     ax, 309
                mov     cx, 358
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
                cmp     cx, 104
                jb      next_0
                cmp     cx, 306
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
                mov     ax, 104
                mov     bx, 80
                mov     cx, 25
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
                mov     ax, 104
                mov     cx, 305
                mov     bx, 80
                mov     dx, 97
                call    set_window2
                mov     si, offset str_func
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     loop_0
next_0:
                cmp     cx, 374
                jb      next_1
                cmp     cx, 576
                jae     next_1
                cmp     dx, 80
                jb      next_1
                cmp     dx, 98
                jae     next_1
                call    hide_mouse
                mov     si, offset str_deriv
                mov     di, offset edit_buffer
                mov     cx, 0200h
                rep     movsb
enter_gx:
                mov     di, offset edit_buffer
                mov     ax, 374
                mov     bx, 80
                mov     cx, 25
                mov     dx, 01FFh
                stc
                call    input
                jc      no_change1
                and     ax, ax
                jz      cont_1
                push    cs
                pop     fs
                mov     bp, offset deriv
                mov     si, offset edit_buffer
                mov     di, offset deriv_consts
                call    make_mthproc
                jnc     cont_1
                cmp     ax, 11
                je      cont_1
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
                mov     ax, 374
                mov     cx, 575
                mov     bx, 80
                mov     dx, 97
                call    set_window2
                mov     si, offset str_deriv
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     loop_0
next_1:
                cmp     cx, 374
                jb      next_2
                cmp     cx, 392
                jae     next_2
                cmp     dx, 104
                jb      next_2
                cmp     dx, 122
                jae     next_2
enter_num:
                call    hide_mouse
                mov     si, offset str_num
                mov     di, offset edit_buffer
                mov     cx, 0002h
                rep     movsb
enter_n:
                mov     di, offset edit_buffer
                mov     ax, 374
                mov     bx, 104
                mov     cx, 2
                mov     dx, 1
                stc
                call    input
                jc      no_change2
                and     ax, ax
                jz      cont_2
                mov     al, [di]
                sub     al, 20h
                jb      err_2
                jne     pass_0
                mov     [di], al
                jmp     cont_2
pass_0:
                sub     al, 10h
                jbe     err_2
                cmp     al, 5
                jb      cont_2
err_2:
                call    beep
                jmp     enter_n
cont_2:
                mov     d_order, al
                mov     si, offset edit_buffer
                mov     di, offset str_num
                mov     cx, 0002h
                rep     movsb
no_change2:
                mov     ax, 374
                mov     cx, 391
                mov     bx, 104
                mov     dx, 121
                call    set_window2
                mov     si, offset str_num
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     loop_0
next_2:
                cmp     cx, 374
                jb      next_3
                cmp     cx, 576
                jae     next_3
                cmp     dx, 180
                jb      next_3
                cmp     dx, 198
                jae     next_3
                call    hide_mouse
                mov     si, offset str_high
                mov     di, offset edit_buffer
                mov     cx, 001Ah
                rep     movsb
enter_high:
                mov     di, offset edit_buffer
                mov     ax, 374
                mov     bx, 180
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
                mov     bx, offset high_pr
                call    val_func
                jnc     cont_3
                mov     si, offset str_high
                mov     bx, offset high_pr
                call    val_func
err_3:
                call    beep
                jmp     enter_high
cont_3:
                mov     si, offset edit_buffer
                mov     di, offset str_high
                mov     cx, 001Ah
                rep     movsb
no_change3:
                mov     ax, 374
                mov     cx, 575
                mov     bx, 180
                mov     dx, 197
                call    set_window2
                mov     si, offset str_high
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     loop_0
next_3:
                cmp     cx, 104
                jb      next_4
                cmp     cx, 306
                jae     next_4
                cmp     dx, 180
                jb      next_4
                cmp     dx, 198
                jae     next_4
                call    hide_mouse
                mov     si, offset str_low
                mov     di, offset edit_buffer
                mov     cx, 001Ah
                rep     movsb
enter_low:
                mov     di, offset edit_buffer
                mov     ax, 104
                mov     bx, 180
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
                mov     bx, offset low_pr
                call    val_func
                jnc     cont_4
                mov     si, offset str_low
                mov     bx, offset low_pr
                call    val_func
err_4:
                call    beep
                jmp     enter_low
cont_4:
                mov     si, offset edit_buffer
                mov     di, offset str_low
                mov     cx, 001Ah
                rep     movsb
no_change4:
                mov     ax, 104
                mov     cx, 305
                mov     bx, 180
                mov     dx, 197
                call    set_window2
                mov     si, offset str_low
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     loop_0
next_4:
                cmp     cx, 237
                jb      next_5
                cmp     cx, 439
                jae     next_5
                cmp     dx, 260
                jb      next_5
                cmp     dx, 278
                jae     next_5
                call    hide_mouse
                mov     si, offset str_x0
                mov     di, offset edit_buffer
                mov     cx, 001Ah
                rep     movsb
enter_x0:
                mov     di, offset edit_buffer
                mov     ax, 237
                mov     bx, 260
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
                mov     bx, offset x_low
                call    val_func
                jnc     cont_5
                mov     si, offset str_x0
                mov     bx, offset x_low
                call    val_func
err_5:
                call    beep
                jmp     enter_x0
cont_5:
                mov     si, offset edit_buffer
                mov     di, offset str_x0
                mov     cx, 001Ah
                rep     movsb
no_change5:
                mov     ax, 237
                mov     cx, 438
                mov     bx, 260
                mov     dx, 277
                call    set_window2
                mov     si, offset str_x0
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     loop_0
next_5:
                cmp     cx, 309
                jb      loop_0
                cmp     cx, 359
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
                mov     ax, 309
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
                mov     ax, 309
                mov     cx, 358
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
                mov     si, offset my_num
                mov     di, offset str_num
                lodsb
                dec     si
                sub     al, 30h
                mov     d_order, al
                mov     cx, my_num_len
                rep     movsb
                mov     si, offset my_low
                mov     di, offset str_low
                push    di
                mov     cx, my_low_len
                rep     movsb
                pop     si
                mov     bx, offset low_pr
                call    val_func
                mov     si, offset my_high
                mov     di, offset str_high
                push    di
                mov     cx, my_high_len
                rep     movsb
                pop     si
                mov     bx, offset high_pr
                call    val_func
                mov     si, offset my_x0
                mov     di, offset str_x0
                push    di
                mov     cx, my_x0_len
                rep     movsb
                pop     si
                mov     bx, offset x_low
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
                mov     formuls, 0Fh
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



init_time       PROC
                mov     al, 00h
                out     70h, al
                in      al, 71h
                mov     sec0, al
                mov     time0, 0
                mov     flag, 0
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
                inc     time0
                call    wait_retrace
                mov     ax, 0007h
                mov     bx, 356
                mov     cx, 240
                mov     dx, 420
                mov     si, 304
                call    filled_box
                mov     eax, time0
                call    @@decode_time
                mov     si, offset message_time
                mov     ah, 00h
                mov     bx, 356
                mov     cx, 240
                call    print_xy
                cmp     flag, 0
                je      @@exit_int
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
                call    cls
                call    init_stack
                cmp     d_order, 3
                jb      @@pass_0
                mov     si, offset error_2
                test    formuls, 06h
                jnz     error
@@pass_0:
                mov     si, offset error_3
                xor     ax, ax
                cmp     d_order, al
                je      @@test
                cmp     str_deriv, al
                jne     @@pass_1
@@test:
                test    formuls, 0Eh
                jnz     error
@@pass_1:
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
                mov     si, offset low_pr
                push    si
                mov     di, offset buffer
                mov     cx, 15
                rep     movsw
                pop     si
                mov     di, offset high_pr
                mov     bx, offset x_low
                mov     dx, offset array
                call    primitive_grf
                pushf
                push    ax
                push    ds
                mov     ax, 251Ch
                lds     dx, cs:old_int_vec
                int     21h
                pop     ds
                call    cls
                mov     si, offset buffer
                mov     di, offset low_pr
                mov     cx, 15
                rep     movsw
                pop     ax
                popf
                jc      @@errors
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
@@loop_0:
                push    cx
                call    compare
                jae     @@pass_2
                push    di
                mov     cx, 5
                rep     movsw
                pop     di
                sub     si, 10
@@pass_2:
                xchg    di, bx
                call    compare
                jbe     @@pass_3
                push    di
                mov     cx, 5
                rep     movsw
                pop     di
                sub     si, 10
@@pass_3:
                xchg    di, bx
                add     si, 10
                pop     cx
                loop    @@loop_0
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
@@loop_1:
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
                loop    @@loop_1
                xor     byte ptr min+9, 80h

                mov     si, offset low_pr
                mov     di, offset hx
                push    di
                mov     cx, 5
                rep     movsw
                pop     bx
                xor     byte ptr [bx+9], 80h
                mov     dx, offset high_pr
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
@@loop_3:
                xor     dx, dx
                mov     cx, 439
                mov     ax, 0008h
                push    bx
                call    vert_line
                pop     bx
                add     bx, 20
                cmp     bx, 640
                jb      @@loop_3
                mov     bx, 439
@@loop_4:
                xor     dx, dx
                mov     cx, 639
                mov     ax, 0008h
                push    bx
                call    horiz_line
                pop     bx
                sub     bx, 20
                jae     @@loop_4

                mov     bx, 0
                mov     si, offset array
@@loop_2:
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
                jae     @@pass_5
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
                jge     @@pass_4
                xchg    cx, dx
@@pass_4:
                call    cvert_line
                pop     si
                pop     bx
                inc     bx
                jmp     @@loop_2
@@pass_5:
                mov     si, offset end_button
                call    set_button
                mov     old_x, -1
                mov     old_y, -1
                call    show_mouse
@@loop_5:
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
                je      @@loop_5
@@shift_located:
                mov     old_x, cx
                mov     old_y, dx
                push    dx
                mov     ax, cx
                call    load_int
                mov     bx, offset hx
                call    c_mul
                mov     bx, offset variable
                call    get_middle
                call    empty_store
                mov     dx, offset low_pr
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
                jb      @@pass_6
                call    hide_mouse
@@pass_6:
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
                jb      @@loop_5
                call    show_mouse
                jmp     @@loop_5
@@left_key_press:
                mov     si, offset end_button
                call    if_click
                jc      @@loop_5
                call    press_button
@@exit:
                ret
@@errors:
                cmp     ax, 3
                je      @@ok_err
                cmp     ax, 5
                je      @@ok_err
                cmp     ax, 14
                je      @@esc_err
                mov     si, offset error_1
                jmp     error
@@esc_err:
                mov     si, offset str_low
                mov     bx, offset low_pr
                call    val_func
                mov     si, offset str_high
                mov     bx, offset high_pr
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
message_0       DB      'График интеграла с переменным', 00h
                DB      'верхним пределом.', 00h
                DB      'Автор: Юровский М.B.', 00h
                DB      'СПбГУ, ПМ-ПУ, 24 группа', 00h
                DB      '23 мая 2000 года', 00h
asc_for_exit    DB      'Вы действительно хотите выйти?', 00h
message_1       DB      'График интеграла с переменным верхним пределом.', 00h

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
error_button    DW      297, 270, 5
                DB      'Далее', 00h
end_button      DW      289, 449, 7
                DB      'Возврат', 00h

f_message       DB      'Интегрируемая функция', 00h
fx              DB      'f(x)=', 00h
gx              DB      'f', 27h, '(x)=', 00h
n               DB      'n =', 00h
x_message       DB      'Границы изменения x', 00h
x1              DB      'x1 =', 00h
x2              DB      'x2 =', 00h
x0_message      DB      'Нижний предел интеграла', 00h
x0              DB      'x0 = ', 00h
r_message       DB      'Ранг разбиения', 00h
rng             DB      'r =', 00h

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
                DB      'Формулы центральных прямоугольников'
                DB      '    и трапеций НЕ поддерживают     '
                DB      '    производных 3 и 4 порядков.    ', 00h
error_3         DB      '              Ошибка!              '
                DB      '    Отсутствует производная для    '
                DB      '        квадратурных формул.       ', 00h
error_4         DB      '                                   '
                DB      '           Нажат <Esc>.            '
                DB      '      Вычисления остановлены.      ', 00h

help_main       DW      1
                DB      '                   Ввод данных.                  '
                DB      '                                                 '
                DB      '  Введите интегрируемую функцию f(x). Независимая'
                DB      'переменная  x,  поддерживаемые элементарные функ-'
                DB      'ции - exp (экспонента), ln (натуральный логарифм)'
                DB      'и  sqrt (квадратный корень), а также операции: +,'
                DB      '-, *, /, ^.                                      '
                DB      '  f', 27h, '(x) - производная f(x).                      '
                DB      '  n - порядок производной.                       '
                DB      '  Границы  изменения x - минимальный и максималь-'
                DB      'ный x, изображаемые на графике.                  '
                DB      00h

my_func         DB      'exp(-ln(x)^2)*ln(1+x^2)', 00h
my_func_len     =       $-my_func
my_deriv        DB      '((1+x^2)^2*ln(1+x^2)*(2*ln(x)^2+ln(x)-1)-'
                DB      'x^2*(4*(1+x^2)*ln(x)+x^2-1))*2*exp(-ln(x)^2)/'
                DB      '(x^2*(1+x^2)^2)', 00h
my_deriv_len    =       $-my_deriv
my_num          DB      '2', 00h
my_num_len      =       $-my_num
my_low          DB      '1', 00h
my_low_len      =       $-my_low
my_high         DB      '10', 00h
my_high_len     =       $-my_high
my_rang         DB      '100', 00h
my_rang_len     =       $-my_rang
my_x0           DB      '1', 00h
my_x0_len       =       $-my_x0

                .DATA?
str_buffers     LABEL
str_func        DB      200h dup (?)
str_deriv       DB      200h dup (?)
str_num         DB      2 dup (?)
str_low         DB      26 dup (?)
str_high        DB      26 dup (?)
str_x0          DB      26 dup (?)
str_rang        DB      6 dup (?)
edit_buffer     DB      200h dup (?)

rang_d          DT      ?               ; ранг разбиения
low_pr          DT      ?               ; нижний предел интегрирования
high_pr         DT      ?               ; верхний предел интегрирования
x_low           DT      ?               ; начальная точка интегрирования
min             DT      ?
max             DT      ?
hx              DT      ?
variable        DT      ?
buffer          DT      3 dup (?)

formuls         DB      ?
sec0            DB      ?
old_x           DW      ?
old_y           DW      ?
time0           DD      ?

array           DB      12800 dup (?)   ; 640*20 - массив вещ. координат точек
func_consts     DB      1000 dup (?)    ; буфер на 100 констант
deriv_consts    DB      1000 dup (?)


                .STACK  4000h

                END     begin
