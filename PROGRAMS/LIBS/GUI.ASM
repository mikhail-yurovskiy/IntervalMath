                .MODEL  small
                .386
                LOCALS  @@
                .CODE

; Список возможных внештатных ситуаций при работе:
;
;   01h         стек пуст (не хватает аргументов для операции)
;   02h         переполнение стека
;   03h         результат операции - бесконечность
;   04h         результат операции - пустое множество
;   05h         аргумент функции не из области определения
;   06h         ранг дробления равен 0
;   07h         производная данного порядка не поддерживается
;   08h         скобки расставлены не верно
;   09h         неизвестная функция
;   0Ah         ошибка в выражении
;   0Bh         выражение - пустая строка
;   0Ch         ошибка в записи константы
;   0Dh         отсутствует мышь
;   0Eh         нажат <Esc>
;   0Fh         практическое зависание при предварительной локализации

                PUBLIC  init_gui
init_gui        PROC; Инициализация
                mov     ax, 0092h
                int     10h             ; установить видеорежим 640x480x16
                call    cls             ; очистили экран
                mov     ax, 0021h
                int     33h             ; инициализация мыши
                cmp     ax, 0FFFFh
                mov     ax, 13
                cmc
                ret
init_gui        ENDP



                PUBLIC  deinit_gui
deinit_gui      PROC; Деинициализация
                mov     ax, 0003h
                int     10h             ; текстовый режим
                mov     ax, 0021h
                int     33h             ; инициализация мыши
                ret
deinit_gui      ENDP



                PUBLIC  wait_retrace, wait_retrace2
wait_retrace    PROC; Ждет обратного хода луча
                mov     dx, 03DAh
@@loop_0:
                in      al, dx
                test    al, 08h
                jnz     @@loop_0
wait_retrace2   LABEL
@@loop_1:
                in      al, dx
                test    al, 08h
                jz      @@loop_1
                ret
wait_retrace    ENDP



                PUBLIC  cls
cls             PROC; Очистка экрана
                push    es
                mov     dx, 03CEh
                mov     ax, 0205h
                out     dx, ax          ; режим записи 2
                push    0A000h
                pop     es
                xor     di, di
                mov     eax, 01010101h  ; синий фон
                mov     cx, 9600
                rep     stosd
                mov     ax, 0005h
                out     dx, ax          ; восстановили режим записи 0
                pop     es
                ret
cls             ENDP



                PUBLIC  beep
beep            PROC
                mov     al, 10110110b
                out     43h, al
                mov     al, 0Dh
                out     42h, al
                mov     al, 11h
                out     42h, al
                in      al, 61h
                or      al, 03h
                out     61h, al
                xor     cx, cx
                mov     dx, 8000h
                mov     ah, 86h
                int     15h
                in      al, 61h
                and     al, 0FCh
                out     61h, al
                ret
beep            ENDP



                PUBLIC  show_mouse
show_mouse      PROC; Сделать видимым указатель мыши
                mov     ax, 0005h
                xor     bx, bx
                int     33h
                mov     ax, 0001h
                int     33h
                ret
show_mouse      ENDP



                PUBLIC  hide_mouse
hide_mouse      PROC; Сделать невидимым указатель мыши
                mov     ax, 0002h
                int     33h
                ret
hide_mouse      ENDP



                PUBLIC  vert_line
vert_line       PROC; Рисует вертикальную линию
; Вход: AX - цвет, BX - X, DX - Y0, CX - Y1
                push    es
                push    0A000h
                pop     es
                sub     cx, dx
                inc     cx
                push    ax
                mov     ax, 80
                mul     dx
                mov     dx, bx
                shr     dx, 3
                lea     di, [eax+edx]   ; DI - адрес в видеопамяти
                xchg    cx, bx          ; BX - длина линии
                and     cl, 07h         ; CL - смещение пиксела в байте
                mov     dx, 03CEh
                mov     ax, 0205h
                out     dx, ax          ; режим записи 2
                mov     ah, 80h
                shr     ah, cl
                mov     al, 08h
                out     dx, ax          ; битовая маска
                pop     ax              ; AL - цвет
@@loop:
                mov     ah, es:[di]     ; обновим регистры-защелки
                stosb                   ; сохраним пиксел
                add     di, 79          ; адрес следующего пиксела
                dec     bx
                jnz     @@loop
                mov     ax, 0FF08h
                out     dx, ax          ; восстановим значения по умолчанию
                mov     ax, 0005h
                out     dx, ax
                pop     es
                ret
vert_line       ENDP



                PUBLIC  horiz_line
horiz_line      PROC; Рисует горизонтальную линию
; Вход: AX - цвет, BX - Y, DX - X0, CX - X1
                push    es
                push    0A000h
                pop     es
                imul    bx, 80
                mov     di, bx
                mov     bx, dx
                mov     dx, 03CEh
                xchg    ah, al
                out     dx, ax          ; цвет в регистр установки-сброса
                mov     ax, 0F01h
                out     dx, ax          ; регистр разрешения установки-сброса
                mov     ax, bx          ; AX - X0
                shr     ax, 3
                add     di, ax          ; DI - начальный адрес
                mov     si, cx          ; SI - X1
                shr     si, 3
                and     cl, 07h         ; CL - смещение пиксела в байте
                mov     ch, 0FFh
                mov     bh, ch
                sub     cl, 07h
                neg     cl
                shl     ch, cl          ; CH - битовая маска конца линии
                mov     cl, bl
                and     cl, 07h         ; CL - смещение пиксела в байте
                shr     bh, cl          ; BH - битовая маска начала линии
                mov     bl, ch          ; BL - битовая маска конца линии
                sub     si, ax
                mov     al, 08h
                jne     @@cont_0
                and     bl, bh          ; если вся линия в одном байте, то
                jmp     @@cont_1        ;                     объединим маски
@@cont_0:
                mov     ah, bh
                out     dx, ax          ; занесем битовую маску начала линии
                mov     ah, es:[di]     ; обновим регистры-защелки
                stosb
                dec     si
                jz      @@cont_1        ; если линия состоит из двух байт
                mov     ah, 0FFh
                out     dx, ax          ; восстановим битовую маску
                mov     cx, si
                rep     stosb           ; нарисовали основную часть линии
@@cont_1:
                mov     ah, bl
                out     dx, ax          ; занесем битовую маску конца линии
                mov     ah, es:[di]     ; обновим регистры-защелки
                stosb
                mov     ah, 0FFh
                out     dx, ax          ; восстановим первоначальные значения
                xor     ax, ax
                out     dx, ax
                inc     ax
                out     dx, ax
                pop     es
                ret
horiz_line      ENDP



                PUBLIC  box
box             PROC; Рисует прямоугольник
; Вход: AX - цвет, BX - X0, CX - Y0, DX - X1, SI - Y1
                pusha
                xchg    bx, cx
                xchg    cx, dx
                call    horiz_line
                popa
                pusha
                mov     cx, bx
                mov     bx, si
                xchg    cx, dx
                call    horiz_line
                popa
                pusha
                mov     dx, cx
                mov     cx, si
                call    vert_line
                popa
                mov     bx, dx
                mov     dx, cx
                mov     cx, si
                jmp     vert_line
box             ENDP



                PUBLIC  box2
box2            PROC; Рисует прямоугольник двумя цветами
; Вход: AL - цвет1, AH - цвет2, BX - X0, CX - Y0, DX - X1, SI - Y1
                pusha
                mov     ah, 00h
                xchg    bx, cx
                xchg    cx, dx
                call    horiz_line
                popa
                pusha
                mov     al, ah
                mov     ah, 00h
                mov     cx, bx
                mov     bx, si
                xchg    cx, dx
                call    horiz_line
                popa
                pusha
                mov     ah, 00h
                mov     dx, cx
                mov     cx, si
                call    vert_line
                popa
                mov     al, ah
                mov     ah, 00h
                mov     bx, dx
                mov     dx, cx
                mov     cx, si
                jmp     vert_line
box2            ENDP



                PUBLIC  filled_box
filled_box      PROC; Рисует закрашенный прямоугольник
; Вход: AX - цвет, BX - X0, CX - Y0, DX - X1, SI - Y1
                xchg    bx, cx
                sub     si, bx
                inc     si
                xchg    cx, dx
@@loop:
                pusha
                call    horiz_line
                popa
                inc     bx
                dec     si
                jnz     @@loop
                ret
filled_box      ENDP



                PUBLIC  draw_window1
draw_window1    PROC; Рисует стандартное окошко первого типа
; Вход: AX,BX - X0,Y0; CX,DX - X1,Y1
                mov     si, dx
                mov     dx, cx
                mov     cx, bx
                mov     bx, ax
                mov     ax, 0007h
                pusha
                call    filled_box
                popa
                mov     ax, 080Fh
                pusha
                call    box2
                popa
                inc     bx
                inc     cx
                dec     dx
                dec     si
                jmp     box2
draw_window1    ENDP



                PUBLIC  draw_window2
draw_window2    PROC; Рисует стандартное окошко второго типа
; Вход: AX,BX - X0,Y0; CX,DX - X1,Y1
                mov     si, dx
                mov     dx, cx
                mov     cx, bx
                mov     bx, ax
                mov     ax, 000Fh
                pusha
                call    filled_box
                popa
                dec     bx
                dec     cx
                mov     ax, 0F08h
                jmp     box2
draw_window2    ENDP



                PUBLIC  print_sym
print_sym       PROC; Печатает символ
; Вход: AL - ASCII код символа; AH - цвет; BX,CX - X,Y
                push    es
                push    bx
                push    cx
                push    ax
                mov     ax, 1130h       ; выясним адрес шрифта
                mov     bh, 06h         ; размер символов - 8x16
                int     10h             ; адрес - в ES:BP
                pop     ax
                mov     bl, al
                mov     bh, 00h
                shl     bx, 4           ; BX - смещение символа от начала
                add     bp, bx
@@prn_sym:
                push    0A000h
                pop     fs
                mov     dx, 03CEh
                mov     al, 00h
                out     dx, ax          ; цвет в регистр установки-сброса
                mov     ax, 0F01h
                out     dx, ax          ; регистр разрешения установки-сброса
                pop     bx
                mov     ax, 80
                imul    ax, bx
                pop     bx
                mov     cx, bx
                shr     bx, 3
                add     ax, bx
                mov     di, ax          ; DI - адрес в видеопамяти
                and     cl, 07h         ; CL - смещение пиксела в байте
                mov     ch, 16
                mov     al, 08h
@@loop:
                mov     bh, es:[bp]     ; очередная линия символа
                inc     bp
                mov     bl, 00h
                shr     bx, cl
                mov     ah, bh
                out     dx, ax          ; маска для правого байта
                mov     bh, fs:[di]     ; обновили регистры-защелки
                mov     fs:[di], bh     ; записали правую половинку символа
                inc     di
                mov     ah, bl
                out     dx, ax          ; маска для левого байта
                mov     bh, fs:[di]     ; обновили регистры-защелки
                mov     fs:[di], bh     ; записали левую половинку символа
                add     di, 79          ; адрес следующей линии
                dec     ch
                jnz     @@loop
                mov     ah, 0FFh
                out     dx, ax          ; восстановим первоначальные значения
                xor     ax, ax
                out     dx, ax
                inc     ax
                out     dx, ax
                pop     es
                ret
print_spr:
                push    es              ; точка входа для печати произвольного
                push    bx              ;                              символа
                push    cx              ; в DI - адрес bitmap'а
                jmp     @@prn_sym
print_sym       ENDP



                PUBLIC  set_window1
set_window1     PROC; Устанавливает окно первого типа для дальнейшей работы
; Вход: AX,BX - X0,Y0; CX,DX - X1,Y1
                pusha
                call    draw_window1
                popa
                sub     cx, ax
                sub     cx, 6
                mov     di, cx
                and     cx, 0007h
                shr     cx, 1
                lea     ax, [eax+ecx+3]
                mov     win_x, ax
                shr     di, 3
                mov     win_len, di
                sub     dx, bx
                sub     dx, 6
                mov     di, dx
                and     dx, 000Fh
                shr     dx, 1
                lea     ax, [ebx+edx+3]
                mov     win_y, ax
                shr     di, 4
                mov     win_high, di
                ret
set_window1     ENDP



                PUBLIC  set_window2
set_window2     PROC; Устанавливает окно второго типа для дальнейшей работы
; Вход: AX,BX - X0,Y0; CX,DX - X1,Y1
                pusha
                call    draw_window2
                popa
                sub     cx, ax
                dec     cx
                mov     di, cx
                and     cx, 0007h
                shr     cx, 1
                lea     ax, [eax+ecx+1]
                mov     win_x, ax
                shr     di, 3
                mov     win_len, di
                sub     dx, bx
                dec     dx
                mov     di, dx
                and     dx, 000Fh
                shr     dx, 1
                lea     ax, [ebx+edx+1]
                mov     win_y, ax
                shr     di, 4
                mov     win_high, di
                ret
set_window2     ENDP



                PUBLIC  clear_window1
clear_window1   PROC; Чистит текущее окно первого типа
                mov     bx, win_x
                mov     cx, win_y
                mov     dx, win_len
                shl     dx, 3
                add     dx, bx
                mov     si, win_high
                shl     si, 4
                add     si, cx
                mov     ax, 0007h
                jmp     filled_box
clear_window1   ENDP



                PUBLIC  print
print           PROC; Печать текста в текущем окне
; Вход: DS:SI - строка ASCIIZ, AH - цвет
                mov     bx, win_x
                mov     cx, win_y
                mov     dx, win_len
                mov     di, win_high
@@loop:
                lodsb
                and     al, al
                jz      @@exit
                pusha
                call    print_sym
                popa
                add     bx, 0008h
                dec     dx
                jnz     @@loop
                mov     bx, win_x
                mov     dx, win_len
                add     cx, 0010h
                dec     di
                jnz     @@loop
@@exit:
                ret
print           ENDP



                PUBLIC  print_xy
print_xy        PROC; Печать текста
; Вход: DS:SI - строка ASCIIZ, AH - цвет, BX,CX - X,Y
@@loop:
                lodsb
                and     al, al
                jz      @@exit
                pusha
                call    print_sym
                popa
                add     bx, 0008h
                jmp     @@loop
@@exit:
                ret
print_xy        ENDP



                PUBLIC  print_center
print_center    PROC; Печать текста по центру строки
; Вход: DS:SI - строка ASCIIZ, AH - цвет, BX - Y
                mov     di, si
                mov     cx, 0FFFFh
                xor     al, al
                repne   scasb
                not     cx
                dec     cx
                shl     cx, 2
                sub     cx, 320
                neg     cx
                xchg    cx, bx
                jmp     print_xy
print_center    ENDP



                PUBLIC  set_button
set_button      PROC; Рисует ненажатую кнопку
; Вход: DS:SI - указатель на кнопку
; Выход: DS:SI - указатель на следующий за последним байт
                lodsw                   ; X0
                mov     bx, ax
                lodsw                   ; Y0
                mov     cx, ax
                lodsw                   ; количество символов в надписи
                shl     ax, 3
                add     ax, 6
                add     ax, bx          ; X1
                mov     dx, ax
                push    si
                lea     si, [ecx+22]    ; Y1
                mov     ax, 0007h
                pusha
                call    filled_box
                popa
                mov     ax, 080Fh
                pusha
                call    box2
                popa
                pusha
                inc     bx
                inc     cx
                dec     dx
                dec     si
                call    box2
                popa
                add     bx, 4
                add     cx, 4
                mov     ah, 08h
                pop     si
@@loop:
                lodsb
                and     al, al
                jz      @@exit
                pusha
                call    print_sym
                popa
                add     bx, 0008h
                jmp     @@loop
@@exit:
                ret
set_button      ENDP



                PUBLIC  push_button
push_button     PROC; Рисует нажатую кнопку
; Вход: DS:SI - указатель на кнопку
; Выход: DS:SI - указатель на следующий за последним байт
                lodsw                   ; X0
                mov     bx, ax
                lodsw                   ; Y0
                mov     cx, ax
                lodsw                   ; количество символов в надписи
                shl     ax, 3
                add     ax, 6
                add     ax, bx          ; X1
                mov     dx, ax
                push    si
                lea     si, [ecx+22]    ; Y1
                mov     ax, 0007h
                pusha
                call    filled_box
                popa
                mov     ax, 0708h
                pusha
                call    box2
                popa
                pusha
                inc     bx
                inc     cx
                call    box2
                popa
                add     bx, 6
                add     cx, 6
                mov     ah, 08h
                pop     si
@@loop:
                lodsb
                and     al, al
                jz      @@exit
                pusha
                call    print_sym
                popa
                add     bx, 0008h
                jmp     @@loop
@@exit:
                ret
push_button     ENDP



                PUBLIC  if_click
if_click        PROC; Проверяет лежит ли точка с координатами CX,DX на кнопке
; Вход: CX,DX - X,Y, DS:SI - указатель на кнопку
; Выход: CF=0, если точка на кнопке, иначе CF=1
                cmp     cx, [si]
                jb      @@exit
                mov     bx, [si+4]
                shl     bx, 3
                add     bx, 6
                add     bx, [si]
                cmp     cx, bx
                jae     @@exit1
                cmp     dx, [si+2]
                jb      @@exit
                mov     bx, dx
                sub     bx, [si+2]
                cmp     bx, 22
@@exit1:
                cmc
@@exit:
                ret
if_click        ENDP



                PUBLIC  press_button
press_button    PROC; Нажимает кнопку
; Вход: DS:SI - указатель на кнопку
                push    si
                call    wait_retrace
                call    hide_mouse
                pop     si
                push    si
                call    push_button     ; нажмем кнопку
                call    show_mouse
@@loop:
                mov     ax, 0005h       ; подождем отпускания клавиши мыши
                xor     bx, bx
                int     33h
                test    al, 1
                jnz     @@loop
                call    wait_retrace
                call    hide_mouse
                pop     si
                call    set_button
                jmp     show_mouse
press_button    ENDP



                PUBLIC  buttons
buttons         PROC; Рисует кнопки, возвращает номер нажатой кнопки
; Вход: DS:SI - указатель на кнопки, AX - количество кнопок
; Выход: если CF = 0, то в AX - номер нажатой кнопки, иначе нажат <Esc>
                mov     butt_ofs, si
                mov     butt_num, ax
                push    ax
                call    wait_retrace
                call    hide_mouse
                pop     ax
@@loop_0:
                push    ax
                call    set_button      ; нарисуем кнопки
                pop     ax
                dec     ax
                jnz     @@loop_0
                call    show_mouse
@@loop_1:
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
                jz      @@loop_1        ;                         то зациклим
                mov     si, butt_ofs
                xor     ax, ax          ; проверим координаты нажатия
@@loop_2:
                call    if_click        ; в CX - X, в DX - Y
                jnc     @@push          ; переход, если нажата кнопка
                inc     ax              ; увеличим номер кнопки
                cmp     ax, butt_num
                jae     @@loop_1        ; если кнопки кончились, то повторим
                add     si, 6           ; SI указывает на надпись на кнопке
@@loop_3:
                inc     si              ; ищем конец надписи
                cmp     byte ptr [si-1], 00h
                jne     @@loop_3
                jmp     @@loop_2
@@push:
                push    ax
                call    press_button
                pop     ax
                stc
@@exit:
                cmc
                ret
buttons         ENDP



                PUBLIC  input
input           PROC; Ввод с клавиатуры
; Вход: DS:DI - адрес буфера ввода; AX,BX - X,Y,
;       CX - длина строки на экране (в знакоместах), DX - максимальная длина,
;       CF=0 - ввод с инициализацией буфера, CF=1 - редактирование строки
; Выход: если CF=0, то DS:DI - строка ASCIIZ, AX - длина строки, иначе - <Esc>
                pushf
                mov     inp_x, ax
                mov     inp_y, bx
                dec     cx
                mov     inp_slen, cx
                mov     inp_mlen, dx
                xor     dx, dx          ; DX - смещение курсора на экране
                xor     bx, bx          ; BX - смещение курсора в буфере
                mov     inp_flag, 01h   ; для input_sym (нарисовать курсор)
                mov     inp_cvisible, 01h
                popf
                jc      @@prepare_edit
                mov     inp_clen, bx
                mov     [di], bl
                jmp     @@start
@@prepare_edit:
                push    di
                xor     al, al
                mov     cx, 0FFFFh
                repne   scasb           ; ищем 00h
                not     cx
                dec     cx              ; длина строки в CX
                mov     inp_clen, cx
                pop     di
@@start:
                call    @@view_string
@@loop:
                call    @@input_sym     ; AL - введенный символ
                jc      @@exit          ; выход, если нажат <Esc>
                cmp     al, 01h
                je      @@backspace
                cmp     al, 02h
                je      @@left
                cmp     al, 03h
                je      @@right
                cmp     al, 04h
                je      @@enter
                cmp     al, 05h
                je      @@delete
                cmp     al, 06h
                je      @@home
                cmp     al, 07h
                je      @@end
                mov     cx, inp_clen
                cmp     cx, inp_mlen
                jae     @@loop          ; если буфер заполнен, то зациклить
                inc     inp_clen        ; увеличим длину строки
                cmp     bx, cx          ; если курсор не в конце строки, то
                jne     @@insert        ;              надо раздвигать строку
                mov     ah, 00h         ; 00h будет последним символом
                mov     [di][bx], ax    ; сохраним символ в буфере
@@continue:
                inc     bx              ; увеличим смещение
                cmp     dx, inp_slen    ; если нужно, увеличим смещение
                adc     dx, 0           ;                           на экране
@@refresh:
                call    @@view_string   ; выведем на экран
                jmp     @@loop
@@insert:
                push    di
                inc     cx
                add     di, cx
                lea     si, [di-1]      ; смещение последнего символа (00h)
                sub     cx, bx          ; длина сдвигаемого фрагмента
                std                     ; направление обратное
                rep     movsb
                pop     di
                cld
                mov     [di][bx], al    ; сохраним символ в буфере
                jmp     @@continue
@@delete:
                mov     cx, inp_clen
                sub     cx, bx          ; если курсор в конце строки, то
                jna     @@loop          ;                      удалять нечего
@@del_cont:
                inc     cx              ; длина сдвигаемого фрагмента (с 00h)
                push    di
                add     di, bx
                lea     si, [di+1]
                rep     movsb
                pop     di
                dec     inp_clen
                jmp     @@refresh
@@backspace:
                and     bx, bx          ; если курсор в начале строки, то
                jz      @@loop          ;                      удалять нечего
                dec     bx              ; уменьшим смещение в буфере
                sub     dx, 1           ; если нужно, то уменьшим экранное
                adc     dx, 0           ;                            смещение
                mov     cx, inp_clen
                sub     cx, bx
                jmp     @@del_cont
@@left:
                and     bx, bx          ; если курсор в начале строки, то
                jz      @@loop          ;                    двигаться некуда
                dec     bx              ; уменьшим смещение в буфере
                sub     dx, 1           ; если нужно, то уменьшим экранное
                adc     dx, 0           ;                            смещение
                jmp     @@refresh
@@right:
                cmp     bx, inp_clen    ; если курсор в конце строки, то
                jae     @@loop          ;                    двигаться некуда
                jmp     @@continue
@@enter:
                mov     ax, inp_clen    ; выход: AX - длина строки
                jmp     @@exit          ; CF уже = 0 (cmp al, 4; je @@enter)
@@home:
                xor     bx, bx          ; в начало строки
                xor     dx, dx
                jmp     @@refresh
@@end:
                sub     dx, bx
                mov     bx, inp_clen    ; в конец строки
                add     dx, bx
                cmp     dx, inp_slen
                jbe     @@refresh
                mov     dx, inp_slen
                jmp     @@refresh
@@view_string:
                pusha
                push    dx
                call    wait_retrace    ; синхронизация с разверткой
                pop     dx
                inc     inp_count       ; увеличим счетчик retrace'ов
                and     inp_count, 07h
                jnz     @@cont_2
                call    @@redraw_cursor ; обеспечим мерцание курсора
@@cont_2:
                mov     cx, inp_slen
                inc     cx
                shl     cx, 3
                inc     cx
                mov     ax, inp_x
                add     cx, ax
                mov     bx, inp_y
                lea     dx, [bx+17]
                call    draw_window2    ; стерли старую информацию
                popa
                pusha
                sub     bx, dx          ; найдем смещение первого печатаемого
                lea     si, [di][bx]    ;                             символа
                mov     dx, inp_slen
                inc     dx
                sub     bx, inp_clen
                neg     bx
                cmp     dx, bx
                jb      @@cont_0
                mov     dx, bx
                and     dx, dx
                je      @@exit_vs
@@cont_0:
                mov     bx, inp_x
                mov     cx, inp_y
                inc     bx
                inc     cx
                mov     ah, 00h         ; цвет черный
@@loop_0:
                lodsb
                pusha
                call    print_sym
                popa
                add     bx, 0008h
                dec     dx
                jnz     @@loop_0
@@exit_vs:
                or      inp_flag, 01h   ; установим флаг обновления экрана
                popa
                ret
@@exit:
                pushf
                pusha
                test    inp_cvisible, 01h
                jz      @@cancel
                call    @@redraw_cursor
@@cancel:
                popa
                popf
                ret
@@input_sym:
                test    inp_flag, 01h   ; подпрограмма ввода символа с
                jz      @@cont_1        ;                          клавиатуры
                and     inp_flag, 0FEh
                cmp     inp_cvisible, 0
                je      @@cont_1
                call    @@set_cursor
@@cont_1:
                pusha
                mov     ah, 01h
                int     16h             ; проверить, нажата ли клавиша
                popa
                jnz     @@pressed
                push    dx
                call    wait_retrace    ; синхронизация с разверткой
                pop     dx
                inc     inp_count       ; увеличим счетчик retrace'ов
                and     inp_count, 07h
                jnz     @@cont_1
                call    @@redraw_cursor ; обеспечим мерцание курсора
                jmp     @@cont_1
@@pressed:
                pusha
                mov     ah, 00h
                int     16h             ; прочитаем код клавиши
                cmp     ah, 01h
                je      @@escape
                cmp     ah, 4Bh
                jne     @@cont_3
                mov     al, 02h         ; стрелка влево
@@cont_3:
                cmp     ah, 4Dh
                jne     @@cont_4
                mov     al, 03h         ; стрелка вправо
@@cont_4:
                cmp     ah, 53h
                jne     @@cont_5
                mov     al, 05h         ; <Del>
@@cont_5:
                cmp     ah, 1Ch
                jne     @@cont_6
                mov     al, 04h         ; <Enter>
@@cont_6:
                cmp     ah, 0Eh
                jne     @@cont_7
                mov     al, 01h         ; <Backspace>
@@cont_7:
                cmp     ah, 47h
                jne     @@cont_8
                mov     al, 06h         ; <Home>
@@cont_8:
                cmp     ah, 4Fh
                jne     @@cont_9
                mov     al, 07h         ; <End>
@@cont_9:
                mov     inp_ax, ax
                and     al, al
                popa
                jz      @@cont_1
                mov     ax, inp_ax
                ret
@@escape:
                popa
                stc
                ret
@@redraw_cursor:
                xor     inp_cvisible, 1
                jz      @@del_cursor
@@set_cursor:
                pusha
                shl     dx, 3
                add     dx, inp_x       ; координата X
                inc     dx
                mov     cx, dx
                and     cl, 07h
                shr     dx, 3
                mov     ax, inp_y
                add     ax, 15
                imul    ax, 80
                lea     di, [eax+edx]   ; смещение в видеобуфере
                mov     inp_oldofs, di
                mov     dx, 03CEh
                push    es
                push    0A000h
                pop     es
                mov     ax, 0304h       ; сохраним изображение под курсором
                mov     bx, offset inp_sbuff
@@loop_2:
                out     dx, ax          ; читаемая плоскость
                mov     bp, es:[di]     ; 2 байта из AHтой плоскости
                mov     [bx], bp
                inc     bx
                inc     bx
                mov     bp, es:[di+80]  ; нижние 2 байта
                mov     [bx], bp
                inc     bx
                inc     bx
                dec     ah              ; следующая плоскость
                jns     @@loop_2
                mov     ax, 0803h
                out     dx, ax          ; операция AND
                mov     ax, 00FFh
                ror     ax, cl
                mov     ch, es:[di]     ; обновим регистры-защелки
                mov     es:[di], ah
                mov     ch, es:[di+80]  ; обновим регистры-защелки
                mov     es:[di+80], ah
                inc     di
                mov     ch, es:[di]     ; обновим регистры-защелки
                stosb
                add     di, 79
                mov     ch, es:[di]     ; обновим регистры-защелки
                stosb
                pop     es
                mov     ax, 0003h
                out     dx, ax          ; восстановим значения по умолчанию
                popa
                ret
@@del_cursor:
                pusha
                mov     di, inp_oldofs  ; смещение в видеобуфере
                mov     dx, 03C4h
                push    es
                push    0A000h
                pop     es
                mov     ax, 0802h       ; восстановим изображение под курсором
                mov     bx, offset inp_sbuff
@@loop_3:
                out     dx, ax          ; записываемая плоскость
                mov     bp, [bx]
                mov     es:[di], bp
                inc     bx
                inc     bx
                mov     bp, [bx]
                mov     es:[di+80], bp
                inc     bx
                inc     bx
                shr     ah, 1           ; следующая плоскость
                jnc     @@loop_3
                pop     es
                mov     ah, 0Fh         ; восстановим значение по умолчанию
                out     dx, ax
                popa
                ret
input           ENDP



                PUBLIC  help_page
help_page       PROC; Выводит на экран текст подсказки
; Вход: DS:SI - указатель на текст, первое слово - количество страниц, каждая
;               страница заканчивается нулем (00h)
                push    si
                call    wait_retrace
                call    hide_mouse
                mov     ax, 120         ; 49x14 символов
                mov     bx, 104
                mov     cx, 520
                mov     dx, 376
                call    set_window1     ; установили окно для работы
                mov     ax, 2
                sub     win_high, ax    ; зарезервировали место для кнопок
                mov     hlp_page, 0     ; номер текущей страницы
                pop     si
                lodsw                   ; количество страниц
                dec     ax
                mov     hlp_num, ax
                mov     hlp_text, si
                mov     ah, 01h         ; синий цвет
                call    print
                call    show_mouse
@@loop:
                mov     ax, 3           ; 3 кнопки
                mov     si, offset hlp_buttons
                call    buttons
                jc      @@esc_pressed
                and     al, al
                je      @@prev_pressed
                dec     al
                jne     @@esc_pressed
@@next_pressed:
                mov     ax, hlp_page
                cmp     ax, hlp_num
                adc     ax, 0
                mov     hlp_page, ax
@@prn_page:
                call    wait_retrace
                call    hide_mouse
                call    clear_window1
                mov     di, hlp_text
                mov     bx, hlp_page
                and     bx, bx
                jz      @@pass
                xor     al, al
@@loop_0:
                mov     cx, 0FFFFh
                repne   scasb
                dec     bx
                jnz     @@loop_0
@@pass:
                mov     si, di
                mov     ah, 01h
                call    print
                call    show_mouse
                jmp     @@loop
@@prev_pressed:
                sub     hlp_page, 1     ; уменьшили номер страницы
                adc     hlp_page, 0
                jmp     @@prn_page
@@esc_pressed:
                ret
help_page       ENDP



                PUBLIC  multichoise
multichoise     PROC; Выбор нескольких опций из предложенных
; Вход: DS:DI - указатель на названия пунктов, DX - количество пунктов (=< 8),
;       BX,CX - X,Y, DS:SI - указатель на текст подсказки, AL - состояние
; Выход: AL - бит включен, если соответствующий пункт выбран,
;        CF = 0, если нажат <OK>, CF = 1, если нажат <Esc> или <ОТМЕНА>
                mov     mc_x, bx
                mov     mc_y, cx
                mov     mc_num, dx
                mov     mc_help, si
                mov     mc_names, di
                mov     mc_flag, al
                mov     mc_header, bp
                pusha
                call    wait_retrace
                call    hide_mouse
                popa
                xor     ax, ax          ; будем искать максимальную длину
                push    di              ;                    названий пунктов
@@loop_0:
                mov     cx, 0FFFFh
                repne   scasb
                not     cx
                dec     cx              ; CX - длина очередного названия
                cmp     ah, cl
                jae     @@pass_0
                mov     ah, cl          ; AH - максимальная длина
@@pass_0:
                dec     dx
                jnz     @@loop_0
                xchg    ah, al
                add     ax, 4
                shl     ax, 3           ; длина окошка
                cmp     ax, 258
                jae     @@cont_0
                mov     ax, 258
@@cont_0:
                mov     mc_len, ax
                add     ax, bx
                dec     ax              ; X1
                mov     cx, ax
                mov     ax, bx          ; X0
                mov     bx, mc_y        ; Y0
                mov     dx, mc_num
                add     dx, dx
                add     dx, 3
                shl     dx, 4           ; высота окошка
                add     dx, bx
                dec     dx              ; Y1
                push    bx
                call    draw_window1
                call    @@view_state
                mov     di, mc_header
                mov     si, di
                xor     al, al
                mov     cx, 0FFFFh
                repne   scasb
                not     cx
                dec     cx
                shl     cx, 2
                sub     cx, 320
                neg     cx
                mov     bx, cx
                pop     cx
                sub     cx, 24
                mov     ah, 0Fh
                call    print_xy
                pop     di
                mov     si, di
                mov     dx, mc_num
                mov     bx, mc_x
                mov     cx, mc_y
                add     bx, 26
                add     cx, 16
                xor     ah, ah
@@loop_2:
                push    bx
                call    print_xy
                pop     bx
                add     cx, 32
                dec     dx
                jnz     @@loop_2
                mov     ok_button+2, cx
                mov     esc_button+2, cx
                mov     help_button+2, cx
                mov     ax, mc_len
                sub     ax, 222
                rcr     ax, 1
                add     ax, mc_x
                mov     ok_button, ax
                add     ax, 80
                mov     esc_button, ax
                add     ax, 88
                mov     help_button, ax
                mov     si, offset ok_button
                call    set_button
                call    set_button
                call    set_button
                call    show_mouse
@@loop_3:
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
                jz      @@loop_3        ;                         то зациклим
                mov     di, mc_x        ; проверим координаты нажатия
                mov     si, mc_y        ;                       (они в CX,DX)
                add     di, 9           ; X0 квадратика
                lea     ax, [di+10]     ; X1 квадратика
                add     si, 18
                mov     bp, mc_num      ; количество квадратиков
@@loop_4:
                lea     bx, [si+12]     ; Y1
                cmp     cx, di
                jb      @@next_0
                cmp     cx, ax
                jae     @@next_0
                cmp     dx, si
                jb      @@next_0
                cmp     dx, bx
                jb      @@found_sq
@@next_0:
                add     si, 32
                dec     bp
                jnz     @@loop_4
                mov     si, offset ok_button
                call    if_click        ; проверим нажаты ли кнопки
                jnc     @@ok_pressed
                mov     si, offset esc_button
                call    if_click
                jnc     @@esc_pressed
                mov     si, offset help_button
                call    if_click
                jc      @@loop_3
@@help_pressed:
                call    @@push          ; нажали кнопку
                mov     si, mc_help
                call    help_page
                call    wait_retrace
                call    hide_mouse
                call    cls
                call    show_mouse
                mov     bx, mc_x
                mov     cx, mc_y
                mov     dx, mc_num
                mov     si, mc_help
                mov     di, mc_names
                mov     bp, mc_header
                mov     al, mc_flag
                jmp     multichoise
@@ok_pressed:
                call    @@push          ; нажали кнопку
                mov     al, mc_flag     ; в AL - состояние пунктов
                clc
                ret
@@esc_pressed:
                call    @@push          ; нажали кнопку
                mov     al, mc_flag     ; в AL - состояние пунктов
@@esc_exit:
                stc
                ret
@@found_sq:
                mov     cx, mc_num
                sub     cx, bp
                inc     cx              ; номер указанного квадратика
                xor     ax, ax
                stc
                rcl     ax, cl          ; маска для флага состояния
                xor     mc_flag, al
                call    wait_retrace
                call    hide_mouse
                call    @@view_state
                call    show_mouse
                jmp     @@loop_3
@@push:
                push    si
                call    wait_retrace
                call    hide_mouse
                pop     si
                push    si
                call    push_button     ; нажмем кнопку
                call    show_mouse
@@loop_5:
                mov     ax, 0005h       ; подождем отпускания клавиши мыши
                xor     bx, bx
                int     33h
                test    al, 1
                jnz     @@loop_5
                call    wait_retrace
                call    hide_mouse
                pop     si
                call    set_button
                jmp     show_mouse
@@view_state:
                mov     si, mc_num      ; выводит квадратики просто и
                mov     cx, mc_x        ;   квадратики с галочками,
                mov     dx, mc_y        ;   в зависимости от состояния пункта
                add     cx, 9
                add     dx, 18
@@loop_1:
                pusha
                mov     ax, cx
                mov     bx, dx
                add     cx, 10
                add     dx, 12
                pusha
                call    draw_window2
                popa
                push    cx
                push    ax
                mov     cx, mc_num      ; проверим, не выбран ли пункт
                sub     cx, si
                inc     cx
                mov     al, mc_flag
                shr     al, cl
                pop     ax
                pop     cx
                jnc     @@pass_1
                mov     cx, bx          ; если выбран, то отметим его
                mov     bx, ax
                inc     bx
                mov     ah, 00h
                mov     bp, offset mc_buff
                call    print_spr
@@pass_1:
                popa
                add     dx, 32
                dec     si
                jnz     @@loop_1
                ret
multichoise     ENDP




                .DATA
mc_buff         DB      00h, 01h, 03h, 03h, 06h, 86h, 0CCh, 0CCh, 78h
                DB      78h, 30h, 10h, 00h, 00h, 00h, 00h
ok_button       DW      ?, ?, 7
                DB      'Принять', 00h
esc_button      DW      ?, ?, 8
                DB      'Отменить', 00h
help_button     DW      ?, ?, 6
                DB      'Помощь', 00h
hlp_buttons     DW      225, 348, 5
                DB      'Назад', 00h
                DW      289, 348, 5
                DB      'Далее', 00h
                DW      353, 348, 7
                DB      'Возврат', 00h

                .DATA?

win_x           DW      ?               ; начальная позиция для печати в окне
win_y           DW      ?
win_len         DW      ?               ; ширина окна в знакоместах
win_high        DW      ?               ; высота окна в знакоместах

butt_ofs        DW      ?
butt_num        DW      ?

inp_oldofs      DW      ?
inp_x           DW      ?
inp_y           DW      ?
inp_slen        DW      ?
inp_mlen        DW      ?
inp_clen        DW      ?
inp_ax          DW      ?
                DW      ?
inp_flag        DB      ?
inp_cvisible    DB      ?
inp_count       DB      ?
inp_sbuff       DB      8 dup (?)

mc_x            DW      ?
mc_y            DW      ?
mc_num          DW      ?
mc_len          DW      ?
mc_help         DW      ?
mc_names        DW      ?
mc_header       DW      ?
mc_flag         DB      ?

hlp_page        DW      ?
hlp_num         DW      ?
hlp_text        DW      ?




                END
