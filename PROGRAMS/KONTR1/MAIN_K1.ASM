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
                call    main_menu
                jc      asc_exit
                and     al, al
                jz      to_integrate
                dec     al
                jz      to_sposob
                dec     al
                jz      to_enter_p
                dec     al
                jnz     asc_exit
                mov     si, offset help_main
                call    help_page
                jmp     main_loop
to_enter_p:
                call    enter_param
                jmp     main_loop
to_integrate:
                call    integrate
                push    ds
                mov     ax, 251Ch
                lds     dx, cs:old_int_vec
                int     21h
                pop     ds
                jmp     main_loop
to_sposob:
                call    sposob
                jmp     main_loop
asc_exit:
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
                mov     bx, 236
                mov     cx, 191
                call    print_xy
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
                mov     si, offset my_r1
                mov     di, offset str_r1
                push    di
                mov     cx, my_r1_len
                rep     movsb
                pop     si
                mov     di, offset r1_consts
                mov     bp, offset remainder_low
                call    make_mthproc
                mov     si, offset my_r2
                mov     di, offset str_r2
                push    di
                mov     cx, my_r2_len
                rep     movsb
                pop     si
                mov     di, offset r2_consts
                mov     bp, offset remainder_high
                call    make_mthproc
                mov     si, offset my_rnum
                mov     di, offset str_rnum
                push    di
                mov     cx, my_rnum_len
                rep     movsb
                pop     si
                mov     bx, offset x_min
                call    val_func
                mov     si, offset my_eps
                mov     di, offset str_eps
                push    di
                mov     cx, my_eps_len
                rep     movsb
                pop     si
                mov     bx, offset eps
                call    val_func
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
                mov     al, my_predel
                mov     predel, al
                mov     al, my_sobstv
                mov     sobstv, al
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
                mov     bx, 224
                mov     cx, 140
                call    print_xy
                mov     ah, 04h
                mov     bx, 224
                mov     cx, 160
                call    print_xy
                mov     ah, 01h
                mov     bx, 240
                mov     cx, 240
                call    print_xy
                mov     ah, 01h
                mov     bx, 228
                mov     cx, 260
                call    print_xy
                mov     ah, 08h
                mov     bx, 256
                mov     cx, 290
                call    print_xy
                call    show_mouse
                mov     si, offset ok_button
                mov     ax, 1
                jmp     buttons
intro           ENDP



main_menu       PROC
                call    hide_mouse
                call    cls
                mov     si, offset message_main
                mov     ah, 0Fh
                mov     bx, 272
                mov     cx, 84
                call    print_xy
                mov     ax, 200
                mov     cx, 440
                mov     bx, 108
                mov     dx, 372
                call    draw_window1
                call    show_mouse
                mov     si, offset main_buttons
                mov     ax, 5
                jmp     buttons
main_menu       ENDP



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



enter_param     PROC
                mov     si, offset str_buffers
                mov     di, offset old_params
                mov     cx, str_buffers_len
                rep     movsb
@@enter_param:
                call    hide_mouse
                call    cls
                mov     si, offset message_enter
                mov     ah, 0Fh
                mov     bx, 260
                mov     cx, 108
                call    print_xy
                mov     ax, 180
                mov     cx, 460
                mov     bx, 132
                mov     dx, 348
                call    draw_window1

                mov     si, offset fx
                mov     ah, 00h
                mov     bx, 188
                mov     cx, 141
                call    print_xy
                mov     ax, 232
                mov     cx, 449
                mov     bx, 140
                mov     dx, 157
                call    set_window2
                mov     si, offset str_func
                mov     ah, 00h
                call    print

                mov     si, offset gx
                mov     ah, 00h
                mov     bx, 188
                mov     cx, 165
                call    print_xy
                mov     ax, 232
                mov     cx, 449
                mov     bx, 164
                mov     dx, 181
                call    set_window2
                mov     si, offset str_deriv
                mov     ah, 00h
                call    print

                mov     si, offset n
                mov     ah, 00h
                mov     bx, 188
                mov     cx, 189
                call    print_xy
                mov     ax, 232
                mov     cx, 249
                mov     bx, 188
                mov     dx, 205
                call    set_window2
                mov     si, offset str_num
                mov     ah, 00h
                call    print

                mov     si, offset rng
                mov     ah, 00h
                mov     bx, 356
                mov     cx, 189
                call    print_xy
                mov     ax, 400
                mov     cx, 449
                mov     bx, 188
                mov     dx, 205
                call    set_window2
                mov     si, offset str_rang
                mov     ah, 00h
                call    print

                mov     si, offset r1
                mov     ah, 00h
                mov     bx, 188
                mov     cx, 237
                call    print_xy
                mov     ax, 232
                mov     cx, 449
                mov     bx, 236
                mov     dx, 253
                call    set_window2
                mov     si, offset str_r1
                mov     ah, 00h
                call    print

                mov     si, offset r2
                mov     ah, 00h
                mov     bx, 188
                mov     cx, 261
                call    print_xy
                mov     ax, 232
                mov     cx, 449
                mov     bx, 260
                mov     dx, 277
                call    set_window2
                mov     si, offset str_r2
                mov     ah, 00h
                call    print

                mov     si, offset rnum
                mov     ah, 00h
                mov     bx, 188
                mov     cx, 285
                call    print_xy
                mov     ax, 232
                mov     cx, 449
                mov     bx, 284
                mov     dx, 301
                call    set_window2
                mov     si, offset str_rnum
                mov     ah, 00h
                call    print

                mov     si, offset reps
                mov     ah, 00h
                mov     bx, 188
                mov     cx, 212
                call    print_xy
                mov     ax, 232
                mov     cx, 449
                mov     bx, 212
                mov     dx, 229
                call    set_window2
                mov     si, offset str_eps
                mov     ah, 00h
                call    print

                mov     si, offset ent_buttons
                call    set_button
                call    set_button
                call    set_button
                call    show_mouse
@@loop_0:
                mov     ah, 01h
                int     16h
                jz      @@continue
                mov     ah, 00h         ; нажата какая-то клавиша
                int     16h
                cmp     ah, 01h         ; проверить сканируемый код
                je      @@esc_exit      ; если <Esc>, то на выход
@@continue:
                mov     ax, 0005h
                xor     bx, bx          ; проверим левую клавишу мыши
                int     33h
                and     bx, bx          ; если левая клавиша не нажималась,
                jz      @@loop_0        ;                         то зациклим
                mov     si, offset ok_ebutton
                call    if_click
                jnc     @@ok_pressed
                mov     si, offset esc_ebutton
                call    if_click
                jnc     @@esc_pressed
                mov     si, offset help_ebutton
                call    if_click
                jnc     @@help_pressed
                cmp     cx, 232
                jb      @@loop_0
                cmp     dx, 158
                jae     @@next_0
                cmp     dx, 140
                jb      @@loop_0
                cmp     cx, 450
                jae     @@loop_0
                call    hide_mouse
                mov     si, offset str_func
                mov     di, offset edit_buffer
                mov     cx, 0200h
                rep     movsb
@@enter_fx:
                mov     di, offset edit_buffer
                mov     ax, 232
                mov     bx, 140
                mov     cx, 27
                mov     dx, 01FFh
                stc
                call    input
                jc      @@no_change0
                and     ax, ax
                jz      @@error_0
                push    cs
                pop     fs
                mov     bp, offset func
                mov     si, offset edit_buffer
                mov     di, offset func_consts
                call    make_mthproc
                jnc     @@cont_0
                mov     bp, offset func
                mov     si, offset str_func
                mov     di, offset func_consts
                call    make_mthproc
@@error_0:
                call    beep
                jmp     @@enter_fx
@@cont_0:
                mov     si, offset edit_buffer
                mov     di, offset str_func
                mov     cx, 0200h
                rep     movsb
@@no_change0:
                mov     ax, 232
                mov     cx, 449
                mov     bx, 140
                mov     dx, 157
                call    set_window2
                mov     si, offset str_func
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     @@loop_0
@@next_0:
                cmp     dx, 182
                jae     @@next_1
                cmp     dx, 164
                jb      @@loop_0
                cmp     cx, 450
                jae     @@loop_0
                call    hide_mouse
                mov     si, offset str_deriv
                mov     di, offset edit_buffer
                mov     cx, 0200h
                rep     movsb
@@enter_gx:
                mov     di, offset edit_buffer
                mov     ax, 232
                mov     bx, 164
                mov     cx, 27
                mov     dx, 01FFh
                stc
                call    input
                jc      @@no_change1
                and     ax, ax
                jz      @@cont_1
                push    cs
                pop     fs
                mov     bp, offset deriv
                mov     si, offset edit_buffer
                mov     di, offset deriv_consts
                call    make_mthproc
                jnc     @@cont_1
                cmp     ax, 11
                je      @@cont_1
                call    beep
                mov     bp, offset deriv
                mov     si, offset str_deriv
                mov     di, offset deriv_consts
                call    make_mthproc
                jmp     @@enter_gx
@@cont_1:
                mov     si, offset edit_buffer
                mov     di, offset str_deriv
                mov     cx, 0200h
                rep     movsb
@@no_change1:
                mov     ax, 232
                mov     cx, 449
                mov     bx, 164
                mov     dx, 181
                call    set_window2
                mov     si, offset str_deriv
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     @@loop_0
@@next_1:
                cmp     dx, 206
                jae     @@next_2
                cmp     dx, 188
                jb      @@loop_0
                cmp     cx, 250
                jb      @@enter_num
                cmp     cx, 400
                jb      @@loop_0
                cmp     cx, 450
                jae     @@loop_0
                call    hide_mouse
                mov     si, offset str_rang
                mov     di, offset edit_buffer
                mov     cx, 0006h
                rep     movsb
@@enter_rang:
                mov     di, offset edit_buffer
                mov     ax, 400
                mov     bx, 188
                mov     cx, 6
                mov     dx, 5
                stc
                call    input
                jc      @@no_change6
                and     ax, ax
                jz      @@error_6
                call    del_spaces
                cmp     [si], al
                je      @@error_6
                mov     bx, offset rang_d
                call    val_func
                jnc     @@cont_6
@@error_6:
                call    beep
                jmp     @@enter_rang
@@cont_6:
                mov     bx, offset rang_d
                call    get_int
                jc      @@error_6
                and     ax, ax
                jz      @@error_6
                mov     rang, ax
                mov     si, offset edit_buffer
                mov     di, offset str_rang
                mov     cx, 0006h
                rep     movsb
@@no_change6:
                mov     ax, 400
                mov     cx, 449
                mov     bx, 188
                mov     dx, 205
                call    set_window2
                mov     si, offset str_rang
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     @@loop_0
@@enter_num:
                call    hide_mouse
                mov     si, offset str_num
                mov     di, offset edit_buffer
                mov     cx, 0002h
                rep     movsb
@@enter_n:
                mov     di, offset edit_buffer
                mov     ax, 232
                mov     bx, 188
                mov     cx, 2
                mov     dx, 1
                stc
                call    input
                jc      @@no_change4
                and     ax, ax
                jz      @@cont_4
                mov     al, [di]
                sub     al, 20h
                jb      @@error_1
                jne     @@pass_0
                mov     [di], al
                jmp     @@cont_4
@@pass_0:
                sub     al, 10h
                jbe     @@error_1
                cmp     al, 5
                jb      @@cont_4
@@error_1:
                call    beep
                jmp     @@enter_n
@@cont_4:
                mov     d_order, al
                mov     si, offset edit_buffer
                mov     di, offset str_num
                mov     cx, 0002h
                rep     movsb
@@no_change4:
                mov     ax, 232
                mov     cx, 249
                mov     bx, 188
                mov     dx, 205
                call    set_window2
                mov     si, offset str_num
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     @@loop_0
@@next_2:
                cmp     dx, 230
                jae     @@next_5
                cmp     dx, 212
                jb      @@loop_0
                cmp     cx, 450
                jae     @@loop_0
                call    hide_mouse
                mov     si, offset str_eps
                mov     di, offset edit_buffer
                mov     cx, 001Ah
                rep     movsb
@@enter_eps:
                mov     di, offset edit_buffer
                mov     ax, 232
                mov     bx, 212
                mov     cx, 27
                mov     dx, 25
                stc
                call    input
                jc      @@no_change7
                and     ax, ax
                jz      @@cont_7
                call    del_spaces
                cmp     [si], cl
                je      @@cont_7
                mov     bx, offset eps
                call    val_func
                jnc     @@cont_7
                mov     si, offset str_eps
                mov     bx, offset eps
                call    val_func
@@error_7:
                call    beep
                jmp     @@enter_eps
@@cont_7:
                mov     si, offset edit_buffer
                mov     di, offset str_eps
                mov     cx, 001Ah
                rep     movsb
@@no_change7:
                mov     ax, 232
                mov     cx, 449
                mov     bx, 212
                mov     dx, 229
                call    set_window2
                mov     si, offset str_eps
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     @@loop_0
@@next_5:
                cmp     dx, 254
                jae     @@next_3
                cmp     dx, 236
                jb      @@loop_0
                cmp     cx, 450
                jae     @@loop_0
                call    hide_mouse
                mov     si, offset str_r1
                mov     di, offset edit_buffer
                mov     cx, 0200h
                rep     movsb
@@enter_r1:
                mov     di, offset edit_buffer
                mov     ax, 232
                mov     bx, 236
                mov     cx, 27
                mov     dx, 01FFh
                stc
                call    input
                jc      @@no_change2
                and     ax, ax
                jz      @@cont_2
                push    cs
                pop     fs
                mov     bp, offset remainder_low
                mov     si, offset edit_buffer
                mov     di, offset r1_consts
                call    make_mthproc
                jnc     @@cont_2
                cmp     ax, 11
                je      @@cont_2
                call    beep
                mov     bp, offset remainder_low
                mov     si, offset str_r1
                mov     di, offset r1_consts
                call    make_mthproc
                jmp     @@enter_r1
@@cont_2:
                mov     si, offset edit_buffer
                mov     di, offset str_r1
                mov     cx, 0200h
                rep     movsb
@@no_change2:
                mov     ax, 232
                mov     cx, 449
                mov     bx, 236
                mov     dx, 253
                call    set_window2
                mov     si, offset str_r1
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     @@loop_0
@@next_3:
                cmp     dx, 278
                jae     @@next_4
                cmp     dx, 260
                jb      @@loop_0
                cmp     cx, 450
                jae     @@loop_0
                call    hide_mouse
                mov     si, offset str_r2
                mov     di, offset edit_buffer
                mov     cx, 0200h
                rep     movsb
@@enter_r2:
                mov     di, offset edit_buffer
                mov     ax, 232
                mov     bx, 260
                mov     cx, 27
                mov     dx, 01FFh
                stc
                call    input
                jc      @@no_change3
                and     ax, ax
                jz      @@cont_3
                push    cs
                pop     fs
                mov     bp, offset remainder_high
                mov     si, offset edit_buffer
                mov     di, offset r2_consts
                call    make_mthproc
                jnc     @@cont_3
                cmp     ax, 11
                je      @@cont_3
                call    beep
                mov     bp, offset remainder_high
                mov     si, offset str_r2
                mov     di, offset r2_consts
                call    make_mthproc
                jmp     @@enter_r2
@@cont_3:
                mov     si, offset edit_buffer
                mov     di, offset str_r2
                mov     cx, 0200h
                rep     movsb
@@no_change3:
                mov     ax, 232
                mov     cx, 449
                mov     bx, 260
                mov     dx, 277
                call    set_window2
                mov     si, offset str_r2
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     @@loop_0
@@next_4:
                cmp     dx, 302
                jae     @@loop_0
                cmp     dx, 284
                jb      @@loop_0
                cmp     cx, 450
                jae     @@loop_0
                call    hide_mouse
                mov     si, offset str_rnum
                mov     di, offset edit_buffer
                mov     cx, 001Ah
                rep     movsb
@@enter_rn:
                mov     di, offset edit_buffer
                mov     ax, 232
                mov     bx, 284
                mov     cx, 27
                mov     dx, 25
                stc
                call    input
                jc      @@no_change5
                and     ax, ax
                jz      @@cont_5
                call    del_spaces
                cmp     [si], cl
                je      @@cont_5
                mov     bx, offset x_min
                call    val_func
                jnc     @@cont_5
                mov     si, offset str_rnum
                mov     bx, offset x_min
                call    val_func
@@error_2:
                call    beep
                jmp     @@enter_rn
@@cont_5:
                mov     si, offset edit_buffer
                mov     di, offset str_rnum
                mov     cx, 001Ah
                rep     movsb
@@no_change5:
                mov     ax, 232
                mov     cx, 449
                mov     bx, 284
                mov     dx, 301
                call    set_window2
                mov     si, offset str_rnum
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     @@loop_0
@@ok_pressed:
                jmp     press_button
@@help_pressed:
                call    press_button
                mov     si, offset help_param
                call    help_page
                call    hide_mouse
                call    cls
                call    show_mouse
                jmp     @@enter_param
@@esc_pressed:
                call    press_button
@@esc_exit:
                mov     si, offset old_params
                mov     di, offset str_buffers
                mov     cx, str_buffers_len
                rep     movsb
                push    cs
                pop     fs
                mov     si, offset str_func
                mov     di, offset func_consts
                mov     bp, offset func
                call    make_mthproc
                mov     si, offset str_deriv
                mov     di, offset deriv_consts
                mov     bp, offset deriv
                call    make_mthproc
                mov     si, offset str_r1
                mov     di, offset r1_consts
                mov     bp, offset remainder_low
                call    make_mthproc
                mov     si, offset str_r2
                mov     di, offset r2_consts
                mov     bp, offset remainder_high
                jmp     make_mthproc
enter_param     ENDP



sposob          PROC
                call    hide_mouse
                call    cls
                mov     si, offset message_int0
                mov     ah, 0Fh
                mov     bx, 268
                mov     cx, 108
                call    print_xy
                mov     ax, 230
                mov     cx, 410
                mov     bx, 132
                mov     dx, 348
                call    draw_window1
                call    show_mouse
                mov     si, offset int0_buttons
                mov     ax, 4
                call    buttons
                jc      @@exit
                and     ax, ax
                jz      @@sobstv
                dec     ax
                jz      @@nesobstv
                dec     ax
                jnz     @@exit
                mov     si, offset help_int0
                call    help_page
                jmp     sposob
@@nesobstv:
                call    hide_mouse
                call    cls
                mov     si, offset message_int1
                mov     ah, 0Fh
                mov     bx, 232
                mov     cx, 108
                call    print_xy
                mov     ax, 230
                mov     cx, 410
                mov     bx, 132
                mov     dx, 348
                call    draw_window1
                call    show_mouse
                mov     si, offset int1_buttons
                mov     ax, 4
                call    buttons
                jc      sposob
                cmp     al, 3
                je      sposob
                cmp     al, 2
                jne     @@next_0
                mov     si, offset help_int1
                call    help_page
                jmp     @@nesobstv
@@next_0:
                mov     predel, al
                mov     al, 1
@@sobstv:
                mov     sobstv, al
                call    hide_mouse
                call    cls
                mov     si, offset message_int2
                mov     ah, 0Fh
                mov     bx, 232
                mov     cx, 144
                call    print_xy
                mov     ax, 200
                mov     cx, 440
                mov     bx, 168
                mov     dx, 312
                call    draw_window1
                mov     si, offset low_a
                mov     ah, 00h
                mov     bx, 207
                mov     cx, 176
                call    print_xy
                mov     ax, 223
                mov     cx, 432
                mov     bx, 176
                mov     dx, 193
                call    set_window2
                mov     si, offset str_low
                mov     ah, 00h
                call    print
                mov     si, offset high_b
                mov     ah, 00h
                mov     bx, 207
                mov     cx, 200
                call    print_xy
                mov     ax, 223
                mov     cx, 432
                mov     bx, 200
                mov     dx, 217
                call    set_window2
                mov     si, offset str_high
                mov     ah, 00h
                call    print
                mov     si, offset int2_buttons
                call    set_button
                call    set_button
                call    set_button
                call    show_mouse
@@loop_0:
                mov     ah, 01h
                int     16h
                jz      @@continue
                mov     ah, 00h         ; нажата какая-то клавиша
                int     16h
                cmp     ah, 01h         ; проверить сканируемый код
                je      sposob          ; если <Esc>, то на выход
@@continue:
                mov     ax, 0005h
                xor     bx, bx          ; проверим левую клавишу мыши
                int     33h
                and     bx, bx          ; если левая клавиша не нажималась,
                jz      @@loop_0        ;                         то зациклим
                mov     si, offset ok_ibutton
                call    if_click
                jnc     @@ok_pressed
                mov     si, offset esc_ibutton
                call    if_click
                jnc     @@esc_pressed
                mov     si, offset help_ibutton
                call    if_click
                jnc     @@help_pressed
                cmp     cx, 223
                jb      @@loop_0
                cmp     cx, 433
                jae     @@loop_0
                cmp     dx, 176
                jb      @@loop_0
                cmp     dx, 194
                jb      @@enter_a
                cmp     dx, 200
                jb      @@loop_0
                cmp     dx, 218
                jae     @@loop_0
@@enter_b:
                call    hide_mouse
                mov     si, offset str_high
                mov     di, offset edit_buffer
                mov     cx, 001Ah
                rep     movsb
@@enter_high:
                mov     di, offset edit_buffer
                mov     ax, 223
                mov     bx, 200
                mov     cx, 26
                mov     dx, 25
                stc
                call    input
                jc      @@no_change0
                and     ax, ax
                jz      @@error_0
                call    del_spaces
                cmp     [si], cl
                je      @@error_0
                mov     bx, offset high_pr
                call    val_func
                jnc     @@cont_0
                mov     si, offset str_high
                mov     bx, offset high_pr
                call    val_func
@@error_0:
                call    beep
                jmp     @@enter_high
@@cont_0:
                mov     si, offset edit_buffer
                mov     di, offset str_high
                mov     cx, 001Ah
                rep     movsb
@@no_change0:
                mov     ax, 223
                mov     cx, 432
                mov     bx, 200
                mov     dx, 217
                call    set_window2
                mov     si, offset str_high
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     @@loop_0
@@enter_a:
                call    hide_mouse
                mov     si, offset str_low
                mov     di, offset edit_buffer
                mov     cx, 001Ah
                rep     movsb
@@enter_low:
                mov     di, offset edit_buffer
                mov     ax, 223
                mov     bx, 176
                mov     cx, 26
                mov     dx, 25
                stc
                call    input
                jc      @@no_change1
                and     ax, ax
                jz      @@error_1
                call    del_spaces
                cmp     [si], cl
                je      @@error_1
                mov     bx, offset low_pr
                call    val_func
                jnc     @@cont_1
                mov     si, offset str_low
                mov     bx, offset low_pr
                call    val_func
@@error_1:
                call    beep
                jmp     @@enter_low
@@cont_1:
                mov     si, offset edit_buffer
                mov     di, offset str_low
                mov     cx, 001Ah
                rep     movsb
@@no_change1:
                mov     ax, 223
                mov     cx, 432
                mov     bx, 176
                mov     dx, 193
                call    set_window2
                mov     si, offset str_low
                mov     ah, 00h
                call    print
                call    show_mouse
                jmp     @@loop_0
@@esc_pressed:
                call    press_button
                jmp     sposob
@@help_pressed:
                call    press_button
                mov     si, offset help_int2
                call    help_page
                jmp     @@sobstv
@@ok_pressed:
                call    press_button
@@mult_loop:
                call    hide_mouse
                call    cls
                call    show_mouse
                mov     dx, 4
                mov     bx, 164
                mov     cx, 150
                mov     al, formuls
                mov     di, offset choise_int
                mov     si, offset help_int3
                mov     bp, offset message_int3
                call    multichoise
                jc      @@exit
                and     al, al
                jnz     @@okay
                call    beep
                jmp     @@mult_loop
@@okay:
                mov     formuls, al
@@exit:
                ret
sposob          ENDP



integrate       PROC
                call    hide_mouse
                call    cls
                call    init_stack
                cmp     d_order, 3
                jb      @@pass
                mov     si, offset error_5
                test    formuls, 06h
                jnz     error
@@pass:
                mov     si, offset error_8
                xor     ax, ax
                cmp     d_order, al
                je      @@test
                cmp     str_deriv, al
                jne     @@pass1
@@test:
                test    formuls, 0Eh
                jnz     error
@@pass1:
                mov     di, offset prim_result
                mov     cx, 75
                rep     stosw
                mov     di, offset low_pr
                cmp     sobstv, 0
                jne     @@nesobstv
                cmp     byte ptr [di], 0FFh
                je      @@error_0
                add     di, 0Ah
                jmp     @@sobstv
@@nesobstv:
                movzx   ax, predel
                cmp     str_r1, ah
                je      @@error_1
                cmp     str_r2, ah
                je      @@error_1
                imul    ax, 0Ah
                add     di, ax
@@sobstv:
                cmp     byte ptr [di], 0FFh
                je      @@error_0
                cmp     sobstv, 0
                je      @@cont_0
                cmp     byte ptr str_rnum, 0
                je      @@cont
                mov     di, offset x_min
                mov     si, offset high_pr
                call    compare
                mov     si, offset error_6
                ja      error
                push    si
                mov     si, offset low_pr
                call    compare
                pop     si
                jb      error
@@cont:
                mov     si, offset error_7
                cmp     byte ptr str_eps, 0
                je      error
                call    found_xs
                jc      @@errors
@@cont_0:
                mov     di, offset high_pr
                mov     si, offset low_pr
                call    compare
                je      @@to_cancel
                mov     al, 00h
                adc     al, al
                mov     inv_int, al
                mov     ax, 148
                mov     cx, 491
                mov     bx, 160
                mov     dx, 319
                call    draw_window1
                mov     si, offset message_1
                mov     ah, 04h
                mov     bx, 244
                mov     cx, 176
                call    print_xy
                mov     si, offset message_2
                mov     ah, 04h
                mov     bx, 288
                mov     cx, 208
                call    print_xy
                mov     si, offset message_3
                mov     ah, 01h
                mov     bx, 220
                mov     cx, 240
                call    print_xy
                mov     si, offset message_4
                mov     ah, 01h
                mov     bx, 220
                mov     cx, 256
                call    print_xy
                mov     si, offset message_5
                mov     ah, 01h
                mov     bx, 220
                mov     cx, 288
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
                mov     bx, offset real_line
                call    i_load
                mov     res_flag, 0

                test    formuls, 01h
                jz      @@next_0
                call    @@clear_legend
                mov     si, offset message_6
                mov     ah, 04h
                mov     bx, 236
                mov     cx, 192
                call    print_xy
                mov     bx, offset low_pr
                mov     dx, offset high_pr
                cmp     inv_int, 0
                je      @@pass_0
                xchg    bx, dx
@@pass_0:
                push    dx
                call    load_num
                pop     bx
                call    load_num
                call    primitive
                jc      @@errors
                cmp     inv_int, 0
                je      @@pass_1
                call    i_negative
@@pass_1:
                mov     bx, offset prim_result
                push    bx
                call    i_store
                pop     bx
                mov     last_method, bx
                call    crossing
                sbb     al, al
                or      res_flag, al
@@next_0:

                test    formuls, 02h
                jz      @@next_1
                call    @@clear_legend
                mov     si, offset message_7
                mov     ah, 04h
                mov     bx, 164
                mov     cx, 192
                call    print_xy
                mov     bx, offset low_pr
                mov     dx, offset high_pr
                cmp     inv_int, 0
                je      @@pass_2
                xchg    bx, dx
@@pass_2:
                push    dx
                call    load_num
                pop     bx
                call    load_num
                call    rectangle
                jc      @@errors
                cmp     inv_int, 0
                je      @@pass_3
                call    i_negative
@@pass_3:
                mov     bx, offset fcp_result
                push    bx
                call    i_store
                pop     bx
                mov     last_method, bx
                call    crossing
                sbb     al, al
                or      res_flag, al
@@next_1:

                test    formuls, 04h
                jz      @@next_2
                call    @@clear_legend
                mov     si, offset message_8
                mov     ah, 04h
                mov     bx, 240
                mov     cx, 192
                call    print_xy
                mov     bx, offset low_pr
                mov     dx, offset high_pr
                cmp     inv_int, 0
                je      @@pass_4
                xchg    bx, dx
@@pass_4:
                push    dx
                call    load_num
                pop     bx
                call    load_num
                call    trapezium
                jc      @@errors
                cmp     inv_int, 0
                je      @@pass_5
                call    i_negative
@@pass_5:
                mov     bx, offset ftr_result
                push    bx
                call    i_store
                pop     bx
                mov     last_method, bx
                call    crossing
                sbb     al, al
                or      res_flag, al
@@next_2:

                test    formuls, 08h
                jz      @@next_3
                call    @@clear_legend
                mov     si, offset message_9
                mov     ah, 04h
                mov     bx, 240
                mov     cx, 192
                call    print_xy
                mov     bx, offset low_pr
                mov     dx, offset high_pr
                cmp     inv_int, 0
                je      @@pass_6
                xchg    bx, dx
@@pass_6:
                push    dx
                call    load_num
                pop     bx
                call    load_num
                call    simpson
                jc      @@errors
                cmp     inv_int, 0
                je      @@pass_7
                call    i_negative
@@pass_7:
                mov     bx, offset simp_result
                push    bx
                call    i_store
                pop     bx
                mov     last_method, bx
                call    crossing
                sbb     al, al
                or      res_flag, al
@@next_3:

                mov     bx, offset cross_result
                push    bx
                call    i_store
                pop     bx
                cmp     res_flag, 0
                je      @@norma
@@to_cancel:
                mov     bx, last_method
@@norma:
                call    i_load
                mov     bx, offset remainder
                call    im_add
                mov     bx, offset res_width
                call    get_width
                mov     bx, offset result
                call    i_store
@@print_result:
                push    ds
                mov     ax, 251Ch
                lds     dx, cs:old_int_vec
                int     21h
                pop     ds
                call    cls
                mov     bx, offset prim_result
                mov     di, offset prim_low
                call    asc_func
                mov     bx, offset prim_result+10
                mov     di, offset prim_high
                call    asc_func
                mov     bx, offset fcp_result
                mov     di, offset fcp_low
                call    asc_func
                mov     bx, offset fcp_result+10
                mov     di, offset fcp_high
                call    asc_func
                mov     bx, offset ftr_result
                mov     di, offset ftr_low
                call    asc_func
                mov     bx, offset ftr_result+10
                mov     di, offset ftr_high
                call    asc_func
                mov     bx, offset simp_result
                mov     di, offset simp_low
                call    asc_func
                mov     bx, offset simp_result+10
                mov     di, offset simp_high
                call    asc_func
                mov     bx, offset cross_result
                mov     di, offset cross_low
                call    asc_func
                mov     bx, offset cross_result+10
                mov     di, offset cross_high
                call    asc_func
                mov     bx, offset result
                mov     di, offset result_low
                call    asc_func
                mov     bx, offset result+10
                mov     di, offset result_high
                call    asc_func
                mov     bx, offset remainder
                mov     di, offset rmd_low
                call    asc_func
                mov     bx, offset remainder+10
                mov     di, offset rmd_high
                call    asc_func
                mov     bx, offset res_width
                mov     di, offset width_str
                call    asc_func
                mov     bx, offset high_pr
                movzx   ax, predel
                imul    ax, 0Ah
                sub     bx, ax
                mov     di, offset xs_str
                call    asc_func

                cmp     res_flag, 0
                je      @@okay
                mov     si, offset warning_message
                call    error
                call    hide_mouse
                call    cls
@@okay:
                mov     ax, 50
                mov     cx, 590
                mov     bx, 52
                mov     dx, 428
                call    draw_window1
                mov     si, offset message_result
                mov     ah, 0Fh
                mov     bx, 220
                mov     cx, 28
                call    print_xy

                mov     cx, 68
                test    formuls, 01h
                jz      @@no_prim
                mov     si, offset prim_message
                mov     ah, 08h
                mov     bx, 216
                push    cx
                call    print_xy
                mov     si, offset prim_str
                mov     ah, 00h
                mov     bx, 104
                pop     cx
                add     cx, 16
                push    cx
                call    print_xy
                pop     cx
                add     cx, 16
@@no_prim:
                test    formuls, 02h
                jz      @@no_fcp
                mov     si, offset fcp_message
                mov     ah, 08h
                mov     bx, 180
                push    cx
                call    print_xy
                mov     si, offset fcp_str
                mov     ah, 00h
                mov     bx, 104
                pop     cx
                add     cx, 16
                push    cx
                call    print_xy
                pop     cx
                add     cx, 16
@@no_fcp:
                test    formuls, 04h
                jz      @@no_ftr
                mov     si, offset ftr_message
                mov     ah, 08h
                mov     bx, 256
                push    cx
                call    print_xy
                mov     si, offset ftr_str
                mov     ah, 00h
                mov     bx, 104
                pop     cx
                add     cx, 16
                push    cx
                call    print_xy
                pop     cx
                add     cx, 16
@@no_ftr:
                test    formuls, 08h
                jz      @@no_simp
                mov     si, offset simp_message
                mov     ah, 08h
                mov     bx, 256
                push    cx
                call    print_xy
                mov     si, offset simp_str
                mov     ah, 00h
                mov     bx, 104
                pop     cx
                add     cx, 16
                push    cx
                call    print_xy
                pop     cx
                add     cx, 16
@@no_simp:
                cmp     res_flag, 0
                jne     @@no_cross
                mov     si, offset cross_message
                mov     ah, 08h
                mov     bx, 276
                push    cx
                call    print_xy
                mov     si, offset cross_str
                mov     ah, 00h
                mov     bx, 104
                pop     cx
                add     cx, 16
                push    cx
                call    print_xy
                pop     cx
                add     cx, 16
@@no_cross:
                cmp     sobstv, 0
                je      @@no_remainder
                mov     si, offset rmd_message
                mov     ah, 08h
                mov     bx, 292
                push    cx
                call    print_xy
                pop     cx
                add     cx, 16
                mov     si, offset rmd_str
                mov     ah, 00h
                mov     bx, 104
                push    cx
                call    print_xy
                pop     cx
                add     cx, 16
                mov     si, offset xs_message
                mov     ah, 08h
                mov     bx, 268
                push    cx
                call    print_xy
                mov     si, offset xs_str
                mov     ah, 00h
                mov     bx, 220
                pop     cx
                add     cx, 16
                call    print_xy
@@no_remainder:
                mov     si, offset result_message
                mov     ah, 08h
                mov     bx, 228
                mov     cx, 316
                call    print_xy
                mov     si, offset result_str
                mov     ah, 00h
                mov     bx, 104
                mov     cx, 332
                call    print_xy
                mov     si, offset width_message
                mov     ah, 08h
                mov     bx, 348
                call    print_center
                mov     si, offset width_str
                mov     ah, 00h
                mov     bx, 364
                call    print_center

                mov     si, offset str_low
                mov     bx, offset low_pr
                call    val_func
                mov     si, offset str_high
                mov     bx, offset high_pr
                call    val_func

                call    show_mouse
                mov     si, offset end_button
                mov     ax, 1
                jmp     buttons
@@clear_legend:
                mov     bx, 160
                mov     dx, 479
                mov     cx, 192
                mov     si, 207
                mov     ax, 0007h
                jmp     filled_box
@@errors:
                cmp     ax, 3
                je      @@ok_err
                cmp     ax, 5
                je      @@ok_err
                cmp     ax, 14
                je      @@esc_err
                mov     si, offset error_4
                jmp     error
@@esc_err:
                mov     si, offset str_low
                mov     bx, offset low_pr
                call    val_func
                mov     si, offset str_high
                mov     bx, offset high_pr
                call    val_func
                mov     si, offset error_9
                jmp     error
@@ok_err:
                mov     si, offset error_3
                jmp     error
@@error_0:
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
@@error_1:
                mov     si, offset error_1
                jmp     error
integrate       ENDP



check_esc       PROC
                pusha
                mov     ah, 01h
                int     16h
                clc
                jz      @@exit
                mov     ah, 00h
                int     16h
                cmp     ah, 01h
                clc
                jne     @@exit
                stc
@@exit:
                popa
                ret
check_esc       ENDP



init_time       PROC
                mov     al, 00h
                out     70h, al
                in      al, 71h
                mov     sec0, al
                xor     eax, eax
                mov     time0, eax
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
                inc     time0
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
                mov     eax, time0
                call    @@decode_time
                mov     si, offset message_time
                mov     ah, 00h
                mov     bx, 356
                mov     cx, 288
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



found_xs        PROC
                mov     ax, 210
                mov     cx, 430
                mov     bx, 215
                mov     dx, 265
                call    draw_window1
                mov     si, offset message_10
                mov     ah, 01h
                mov     bx, 220
                mov     cx, 222
                call    print_xy
                mov     si, offset message_2
                mov     ah, 00h
                mov     bx, 288
                mov     cx, 242
                call    print_xy
                mov     si, offset message_esc
                mov     ah, 0Fh
                mov     bx, 204
                mov     cx, 448
                call    print_xy
                mov     di, offset high_pr
                mov     si, offset low_pr
                xor     cl, cl
                call    compare
                adc     cl, cl
                movzx   ax, predel
                push    ax
                imul    ax, 0Ah
                sub     di, ax          ; DI - особый предел
                add     si, ax          ; SI - неособый предел
                pop     ax
                xor     al, cl
                jnz     @@to_decrease
                cmp     byte ptr [di], 0FFh
                jne     @@to_asimptote
                push    di
                cmp     byte ptr str_rnum, 0
                je      @@cont_0
                mov     si, offset x_min
@@cont_0:
                mov     cx, 5
                rep     movsw
                pop     bx
@@loop_0:
                call    check_esc
                jc      @@esc_exit
                call    @@get_remainder
                jc      @@exit
                mov     di, offset eps
                call    compare
                jae     @@exit
                mov     di, bx
                mov     si, offset one
                call    compare
                jae     @@more_than_one
                mov     cx, 5
                rep     movsw
                jmp     @@loop_0
@@more_than_one:
                mov     dx, offset two
                push    bx
                call    n_mul
                pop     bx
                cmp     byte ptr [bx], 0FFh
                je      @@error_2
                jmp     @@loop_0
@@to_asimptote:
                push    di
                cmp     byte ptr str_rnum, 0
                jne     @@cont_1
                mov     bx, si
                call    load_num
                pop     bx
                push    bx
                call    load_num
                call    i_hull
                pop     bx
                mov     si, bx
                mov     di, offset store_high
                mov     cx, 5
                rep     movsw
                call    get_middle
                jmp     @@loop_1
@@cont_1:
                mov     si, offset x_min
                mov     cx, 5
                rep     movsw
                pop     bx
@@loop_1:
                call    check_esc
                jc      @@esc_exit
                call    @@get_remainder
                jc      @@exit
                mov     di, offset eps
                call    compare
                jae     @@exit
                push    bx
                call    load_num
                mov     bx, offset store_high
                call    load_num
                call    i_hull
                pop     bx
                call    get_middle
                call    empty_store
                jmp     @@loop_1
@@to_decrease:
                cmp     byte ptr [di], 0FFh
                jne     @@to_asimptote
                push    di
                cmp     byte ptr str_rnum, 0
                je      @@cont_2
                mov     si, offset x_min
@@cont_2:
                mov     cx, 5
                rep     movsw
                pop     bx
@@loop_2:
                call    check_esc
                jc      @@esc_exit
                call    @@get_remainder
                jc      @@exit
                mov     di, offset eps
                call    compare
                jae     @@exit
                mov     di, offset min_one
                mov     si, bx
                call    compare
                jae     @@less_than_minone
                xchg    di, si
                mov     cx, 5
                rep     movsw
                jmp     @@loop_2
@@less_than_minone:
                mov     dx, offset two
                push    bx
                call    n_mul
                pop     bx
                cmp     byte ptr [bx], 0FFh
                je      @@error_2
                jmp     @@loop_2
@@get_remainder:
                push    bx
                call    load_num
                call    duplicate
                call    remainder_low
                jc      @@exit
                call    exchange
                call    remainder_high
                jc      @@exit
                call    i_hull
                mov     bx, offset width
                push    bx
                call    get_width
                mov     bx, offset remainder
                call    i_store
                pop     si
                pop     bx
@@exit:
                ret
@@esc_exit:
                mov     si, offset str_low
                mov     bx, offset low_pr
                call    val_func
                mov     si, offset str_high
                mov     bx, offset high_pr
                call    val_func
                pop     si
                mov     si, offset error_9
                jmp     error
@@error_2:
                pop     si
                mov     si, offset error_2
                jmp     error
found_xs        ENDP



func            PROC
                DB      1000h dup (90h) ; килобайт NOP'ов
func            ENDP



deriv           PROC
                DB      1000h dup (90h) ; килобайт NOP'ов
deriv           ENDP



remainder_low   PROC
                DB      1000h dup (90h) ; килобайт NOP'ов
remainder_low   ENDP



remainder_high  PROC
                DB      1000h dup (90h) ; килобайт NOP'ов
remainder_high  ENDP




old_int_vec     DD      ?

                .DATA
message_0       DB      'Вычисление собственных и', 00h
                DB      'несобственных интегралов', 00h
                DB      'Автор: Юровский М.B.', 00h
                DB      'СПбГУ, ПМ-ПУ, 24 группа', 00h
                DB      '19 мая 2000 года', 00h
message_1       DB      'Идет интегрирование', 00h
message_2       DB      'Ждите...', 00h
message_3       DB      'Прошло времени:', 00h
message_4       DB      'Оценка времени:', 00h
message_5       DB      'Общее время:', 00h
message_6       DB      'примитивным способом.', 00h
message_7       DB      'по формуле центральных прямоугольников.', 00h
message_8       DB      'по формуле трапеций.', 00h
message_9       DB      'по формуле Симпсона.', 00h
message_esc     DB      'Нажмите <Esc> для прерывания.', 00h
message_main    DB      'Главное меню', 00h
message_enter   DB      'Ввод параметров', 00h
message_int0    DB      'Вид интеграла', 00h
message_int1    DB      'Несобственный интеграл', 00h
message_int2    DB      'Пределы интегрирования', 00h
message_int3    DB      'Квадратурные формулы', 00h
asc_for_exit    DB      'Вы действительно хотите выйти?', 00h
message_10      DB      'Идет поиск точки раздела.', 00h
message_time    LABEL
hours           DB      '**:'
mins            DB      '**:'
secs            DB      '**', 00h

error_0         DB      '              Ошибка!              '
                DB      '    В качестве неособого предела   '
                DB      '       указана бесконечность.      ', 00h
error_1         DB      '              Ошибка!              '
                DB      '   Отсутствует оценка остатка для  '
                DB      '     несобственного интеграла.     ', 00h
error_2         DB      '              Ошибка!              '
                DB      '  Остаток несобственного интеграла '
                DB      '        не стремится к нулю.       ', 00h
error_3         DB      '              Ошибка!              '
                DB      '    Аргумент функции вне области   '
                DB      '            определения.           ', 00h
error_4         DB      '              Ошибка!              '
                DB      '   Произошла неизвестная ошибка.   '
                DB      '    Возможно, это сбой в работе    '
                DB      '             программы.            ', 00h
warning_message DB      '          Предупреждение!          '
                DB      '     Пересечение локализаторов,    '
                DB      'полученных разными методами, пусто.', 00h
error_5         DB      '              Ошибка!              '
                DB      'Формулы центральных прямоугольников'
                DB      '    и трапеций НЕ поддерживают     '
                DB      '    производных 3 и 4 порядков.    ', 00h
error_6         DB      '              Ошибка!              '
                DB      'Указанное значение точки раздела не'
                DB      'принадлежит отрезку интегрирования.', 00h
error_7         DB      '              Ошибка!              '
                DB      '  Отсутствует требуемая точность   '
                DB      ' остатка несобственного интеграла. ', 00h
error_8         DB      '              Ошибка!              '
                DB      '    Отсутствует производная для    '
                DB      '        квадратурных формул.       ', 00h
error_9         DB      '                                   '
                DB      '           Нажат <Esc>.            '
                DB      '      Вычисления остановлены.      ', 00h

message_result  DB      'Результаты интегрирования', 00h
prim_message    DB      'Примитивное интегрирование', 00h
prim_str        DB      '['
prim_low        DB      '*************************, '
prim_high       DB      '*************************]', 00h
fcp_message     DB      'Формула центральных прямоугольников', 00h
fcp_str         DB      '['
fcp_low         DB      '*************************, '
fcp_high        DB      '*************************]', 00h
ftr_message     DB      'Формула трапеций', 00h
ftr_str         DB      '['
ftr_low         DB      '*************************, '
ftr_high        DB      '*************************]', 00h
simp_message    DB      'Формула Симпсона', 00h
simp_str        DB      '['
simp_low        DB      '*************************, '
simp_high       DB      '*************************]', 00h
cross_message   DB      'Пересечение', 00h
cross_str       DB      '['
cross_low       DB      '*************************, '
cross_high      DB      '*************************]', 00h
rmd_message     DB      'Остаток', 00h
rmd_str         DB      '['
rmd_low         DB      '*************************, '
rmd_high        DB      '*************************]', 00h
xs_message      DB      'Точка раздела', 00h
xs_str          DB      '*************************', 00h
result_message  DB      'Окончательный результат', 00h
result_str      DB      '['
result_low      DB      '*************************, '
result_high     DB      '*************************]', 00h
width_message   DB      'Ширина', 00h
width_str       DB      '*************************', 00h

fx              DB      'f(x)=', 00h
gx              DB      'g(x)=', 00h
n               DB      'n   =', 00h
r1              DB      'r(x)=', 00h
r2              DB      'R(x)=', 00h
rnum            DB      'Xmin=', 00h
reps            DB      'eps =', 00h
rng             DB      'rang=', 00h
low_a           DB      'a', 00h
high_b          DB      'b', 00h

ok_button       DW      297, 325, 5
                DB      'Далее', 00h
main_buttons    DW      233, 132, 21
                DB      '    Интегрирование   ', 00h
                DW      233, 180, 21
                DB      'Способ интегрирования', 00h
                DW      233, 228, 21
                DB      '   Ввод параметров   ', 00h
                DW      233, 276, 21
                DB      '        Помощь       ', 00h
                DW      233, 324, 21
exit_to_dos     DB      '     Выход в DOS     ', 00h
ent_buttons     LABEL
ok_ebutton      DW      209, 314, 7
                DB      'Принять', 00h
esc_ebutton     DW      289, 314, 8
                DB      'Отменить', 00h
help_ebutton    DW      377, 314, 6
                DB      'Помощь', 00h
int0_buttons    DW      265, 156, 13
                DB      ' Собственный ', 00h
                DW      265, 204, 13
                DB      'Несобственный', 00h
                DW      265, 252, 13
                DB      '    Помощь   ', 00h
                DW      265, 300, 13
                DB      '   Возврат   ', 00h
int1_buttons    DW      261, 156, 14
                DB      'Верхний предел', 00h
                DW      261, 204, 14
                DB      'Нижний  предел', 00h
                DW      261, 252, 14
                DB      '    Помощь    ', 00h
                DW      261, 300, 14
                DB      '    Возврат   ', 00h
int2_buttons    LABEL
ok_ibutton      DW      221, 278, 5
                DB      'Далее', 00h
esc_ibutton     DW      285, 278, 7
                DB      'Возврат', 00h
help_ibutton    DW      365, 278, 6
                DB      'Помощь', 00h
error_button    DW      297, 270, 5
                DB      'Далее', 00h
end_button      DW      289, 396, 7
                DB      'Возврат', 00h
exit_buttons    DW      269, 240, 4
                DB      ' Да ', 00h
                DW      325, 240, 5
                DB      ' Нет ', 00h

choise_int      DB      'Примитивное интегрирование', 00h
                DB      'Формула центральных прямоугольников', 00h
                DB      'Формула трапеций', 00h
                DB      'Формула Симпсона', 00h

help_main       DW      2
                DB      '                  Главное меню.                  '
                DB      '                                                 '
                DB      'Выберите один из пунктов:                        '
                DB      '  1. Интегрирование.                             '
                DB      '    Переход к интегрированию введенной функции.  '
                DB      '                                                 '
                DB      '  2. Способ интегрирования.                      '
                DB      '    В этом случае Вам потребуется выбрать исполь-'
                DB      '    зуемые  квадратурные формулы или ограничиться'
                DB      '    примитивным  интегрированием,  ввести пределы'
                DB      '    интегрирования, выбрать вид интеграла (собст-'
                DB      '    венный  или несобственный).                  '
                DB      '                                                 '
                DB      '  3. Ввод параметров.                            '
                DB      00h
                DB      '    Вы  сможете  ввести интегрируемую функцию, ее'
                DB      '    производную необходимого порядка и оценку ос-'
                DB      '    татка несобственного интеграла.              '
                DB      '                                                 '
                DB      '  4. Выход в DOS.                                '
                DB      '    Возврат в операционную систему. Все введенные'
                DB      '    данные будут утеряны.                        '
                DB      00h
help_param      DW      4
                DB      '                 Ввод параметров.                '
                DB      '                                                 '
                DB      '  Чтобы ввести необходимый Вам параметр, подведи-'
                DB      'те стрелку к строке, в которой он записан, и наж-'
                DB      'мите левую кнопку мыши. Для записи выражений мож-'
                DB      'но использовать следующие функции:               '
                DB      '  - sqrt  квадратный корень,                     '
                DB      '  - ln    натуральный логарифм,                  '
                DB      '  - exp   экспонента.                            '
                DB      '                                                 '
                DB      '  Операции: +, -, *, /, ^.                       '
                DB      '                                                 '
                DB      '  Если  при  вводе была допущена ошибка, то прог-'
                DB      'рамма предупредит об этом звуковым сигналом.     '
                DB      00h
                DB      'Параметры:                                       '
                DB      '  1. f(x) - интегрируемая функция.               '
                DB      '    Введите  нужную  зависимость, используя в ка-'
                DB      '    честве независимой переменной x.             '
                DB      '                                                 '
                DB      '  2. g(x) - производная интегрируемой функции.   '
                DB      '    Производная необходима при использовании ква-'
                DB      '    дратурных формул.                            '
                DB      '                                                 '
                DB      '  3. n - порядок производной.                    '
                DB      '    Поддерживаются  производные от 1 до 4 порядка'
                DB      '    включительно.  Чем  выше порядок производной,'
                DB      '    тем точнее будут выполнены вычисления.       '
                DB      00h
                DB      '  4. r(x) - нижняя граница остатка несобственного'
                DB      '            интеграла.                           '
                DB      '    Несобственный интеграл вычисляется как собст-'
                DB      '    венный до точки раздела + этот остаток, кото-'
                DB      '    рый  является  локализатором оставшейся части'
                DB      '    интеграла.  В качестве независимой переменной'
                DB      '    используется  точка  раздела,  обозначаемая в'
                DB      '    вводимом выражении - x.                      '
                DB      '                                                 '
                DB      '  5. R(x) - верхняя граница остатка несобственно-'
                DB      '            го интеграла.                        '
                DB      '                                                 '
                DB      '  6. Xmin - минимальное  (максимальное)  значение'
                DB      '            точки раздела.                       '
                DB      00h
                DB      '    Если  оценка  остатка  действует  не для всех'
                DB      '    значений  точки  раздела, то вы можете ввести'
                DB      '    ее  минимальное значение, если особая точка -'
                DB      '    верхний предел, или максимальное, если - ниж-'
                DB      '    ний предел.                                  '
                DB      '                                                 '
                DB      '  7. rang - ранг разбиения.                      '
                DB      '    Ранг разбиения отрезка интегрирования. Чем он'
                DB      '    больше, тем точнее получаемый результат, но и'
                DB      '    времени тратится на вычисления больше.       '
                DB      '                                                 '
                DB      '  8. eps - ширина локализатора остатка           '
                DB      '    Требуемая ширина локализатора остатка несобс-'
                DB      '    венного интеграла.                           '
                DB      00h
help_int0       DW      1
                DB      '                  Вид интеграла.                 '
                DB      '                                                 '
                DB      '  Нажмите  кнопку <Собственный>, если пределы ин-'
                DB      'тегрирования не являются особыми точками интегри-'
                DB      'руемой функции, или кнопку <Несобственный> в про-'
                DB      'тивном случае. Кнопка <Возврат> вернет Вас в гла-'
                DB      'вное меню.                                       '
                DB      00h
help_int1       DW      1
                DB      '             Несобственный интеграл.             '
                DB      '                                                 '
                DB      '  Выберите  предел,  который  является особым для'
                DB      'интегрируемой  функции, и нажмите соответствующую'
                DB      'кнопку. <Возврат> вернет Вас в предыдущее меню.  '
                DB      00h
help_int2       DW      1
                DB      '             Пределы интегрирования.             '
                DB      '                                                 '
                DB      '  Введите пределы интегрирования: a - нижний пре-'
                DB      'дел,  b  - верхний предел. Вместо числа можно ис-'
                DB      'пользовать  константу pi, а также inf - бесконеч-'
                DB      'ность.                                           '
                DB      '                                                 '
                DB      'Кнопки:                                          '
                DB      '  1. Далее.                                      '
                DB      '    Переход в следующее меню.                    '
                DB      '                                                 '
                DB      '  2. Возврат.                                    '
                DB      '    Возврат в меню выбора вида интеграла.        '
                DB      00h
help_int3       DW      1
                DB      '              Квадратурные формулы.              '
                DB      '                                                 '
                DB      '  Выберите  квадратурные  формулы,  которые будут'
                DB      'использоваться  при  интегрировании.  Примитивное'
                DB      'интегрирование  не  требует  производных. Формулы'
                DB      'центральных прямоугольников и трапеций используют'
                DB      'производную  первого или второго порядка. Формула'
                DB      'Симпсона может использовать производные от перво-'
                DB      'го до четвертого порядков.                       '
                DB      00h

min_one         DD      00000000h, 10000000h
                DW      8000h           ; -1.000000000000000
two             DD      00000000h, 20000000h
                DW      0               ; 2.000000000000000
; [-inf,+inf]
real_line       DD      0FFFFFFFFh, 0FFFFFFFFh
                DW      0BFFFh          ; -inf
                DD      0FFFFFFFFh, 0FFFFFFFFh
                DW      3FFFh           ; +inf

my_func         DB      'exp(-ln(x)^2)*ln(1+x^2)', 00h
my_func_len     =       $-my_func
my_deriv        DB      '((1+x^2)^2*ln(1+x^2)*(2*ln(x)^2+ln(x)-1)-'
                DB      'x^2*(4*(1+x^2)*ln(x)+x^2-1))*2*exp(-ln(x)^2)/'
                DB      '(x^2*(1+x^2)^2)', 00h
my_deriv_len    =       $-my_deriv
my_num          DB      '2', 00h
my_num_len      =       $-my_num
my_r1           DB      'exp(-ln(x)^2)', 00h
my_r1_len       =       $-my_r1
my_r2           DB      'ln(1+1/x^2)/2+ln(1+x^2)/(2*x^2)', 00h
my_r2_len       =       $-my_r2
my_rnum         DB      '27', 00h
my_rnum_len     =       $-my_rnum
my_low          DB      '1', 00h
my_low_len      =       $-my_low
my_high         DB      'inf', 00h
my_high_len     =       $-my_high
my_rang         DB      '100', 00h
my_rang_len     =       $-my_rang
my_eps          DB      '0.001', 00h
my_eps_len      =       $-my_eps
my_predel       DB      00h
my_sobstv       DB      01h

                .DATA?
str_buffers     LABEL
str_func        DB      200h dup (?)
str_deriv       DB      200h dup (?)
str_num         DB      2 dup (?)
str_r1          DB      200h dup (?)
str_r2          DB      200h dup (?)
str_rnum        DB      26 dup (?)
str_eps         DB      26 dup (?)
str_rang        DB      6 dup (?)
str_buffers_len =       $-str_buffers
old_params      DB      str_buffers_len dup (?)
edit_buffer     DB      200h dup (?)
str_low         DB      26 dup (?)
str_high        DB      26 dup (?)

x_min           DT      ?               ; минимальная точка раздела
eps             DT      ?               ; ширина локализатора остатка
rang_d          DT      ?               ; ранг разбиения
low_pr          DT      ?               ; нижний предел интегрирования
high_pr         DT      ?               ; верхний предел интегрирования
store_high      DT      ?

prim_result     DT      2 dup (?)       ; результат примитивного интегрирования
fcp_result      DT      2 dup (?)       ; результат интегрирования по ФЦП
ftr_result      DT      2 dup (?)       ; результат интегрирования по ФТр
simp_result     DT      2 dup (?)       ; результат интегрирования по Симпсону
cross_result    DT      2 dup (?)       ; результат пересечения
remainder       DT      2 dup (?)       ; остаток несобственного интеграла
result          DT      2 dup (?)       ; окончательный результат
res_width       DT      ?               ; ширина результата
width           DT      ?               ; ширина остатка

sec0            DB      ?               ; текущая секунда
formuls         DB      ?               ; используемые формулы
predel          DB      ?               ; особый предел (0 - верхний)
inv_int         DB      ?               ; = 1, если нижний предел > верхнего
sobstv          DB      ?               ; собственность интеграла
res_flag        DB      ?               ; сигнализирует о пустоте пересечения
last_method     DW      ?               ; последняя использованная квадратура
time0           DD      ?               ; общее прошедшее время

func_consts     DB      1000 dup (?)    ; буфер на 100 констант
deriv_consts    DB      1000 dup (?)
r1_consts       DB      1000 dup (?)
r2_consts       DB      1000 dup (?)


                .STACK  4000h

                END     begin
