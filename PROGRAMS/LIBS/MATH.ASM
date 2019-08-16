                .MODEL  small
                .386
                .CODE
                LOCALS  @@

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

                PUBLIC  init_stack
init_stack      PROC
                xor     ax, ax
                mov     stk_top, al
                mov     stk_amount, ax
                ret
init_stack      ENDP



                PUBLIC  make_mthproc
make_mthproc    PROC; Компилирует математическое выражение из ASCIIZ строки
; Вход: FS:BP - указатель на будущую подпрограмму, SI - указатель на строку,
;       DI - указатель на буфер для констант
; Выход: если есть ошибки, то CF = 1, AX = код ошибки
                mov     const_buffer, di
                mov     di, si
; Найдем длину строки
                xor     al, al
                xor     cx, cx
                mov     const_num, cx   ; количество констант = 0
                dec     cx
                repne   scasb
                neg     cx
                dec     cx              ; длина строки в CX
                mov     ax, 11
                stc
                jz      exit            ; выход, если пустая строка
                mov     str_len, cx
; Удалим пробелы и заменим буквы строчными, проверим расстановку скобок
                mov     y_flag, 0       ; присутствует ли 2ая переменная - y
                push    si
                xor     dx, dx          ; DX - уровень вложенности
@@loop_0:
                lodsb
                dec     cx              ; уменьшим длину строки
                jz      @@next_0        ; переход, если строка закончилась
                cmp     al, ' '
                jne     @@cont_0
                lea     di, [si-1]      ; DI = SI-1
                push    cx
                push    di
                rep     movsb           ; удалим пробел
                pop     si
                pop     cx
                dec     str_len
                jmp     @@loop_0
@@cont_0:
                cmp     al, 'A'
                jb      @@cont_1
                cmp     al, 'Z'
                ja      @@cont_1
                add     al, 20h         ; 'a' = 'A' + 20h
                mov     [si-1], al
@@cont_1:
                call    is_correct      ; недопустимый символ?
                jnz     @@error_2       ; если да, то на выход
                cmp     al, 'y'
                jne     @@cont
                mov     y_flag, 0FFh    ; нашли y
@@cont:
                cmp     al, '('
                jne     @@cont_2
                inc     dx              ; увеличим уровень вложенности
@@cont_2:
                cmp     al, ')'
                jne     @@loop_0
                dec     dx              ; уменьшим уровень вложенности
                jns     @@loop_0
                pop     si
@@error_0:
                mov     ax, 8           ; выход, если ')' перед '(',
                stc                     ;              или '(' больше чем ')'
                jmp     exit
@@next_0:
                pop     si
                and     dx, dx
                jnz     @@error_0
                cmp     str_len, 1
                mov     ax, 11
                stc
                je      exit            ; выход, если пустая строка
; Проверим функции
                push    si
@@loop_1:
                lodsb
                and     al, al          ; строка заканчивается нулем
                jz      @@next_2        ; перейти, если 0
                call    is_alpha        ; буква ли это?
                jnc     @@loop_1        ; цикл, если нет
                cmp     al, 'e'         ; проверим - не число ли это (1e-10)
                jne     @@no_number
                mov     al, [si-2]      ; перед e должна быть цифра
                call    is_number
                jnc     @@no_number
                lodsb                   ; после e должна быть цифра или +, -
                dec     si
                call    is_number
                jc      @@loop_1
                cmp     al, '+'
                je      @@loop_1
                cmp     al, '-'
                je      @@loop_1
@@no_number:
                dec     si
                mov     di, offset functions
                mov     dx, func_num
@@loop_2:
                push    si
                stc
                sbb     cx, cx
                repe    cmpsb           ; сравниваем строки
                dec     di
                dec     si              ; DI и SI - несовпавшие байты
                mov     al, 20h
                cmp     [di], al        ; название в таблице кончается 20h
                je      @@cont_3
                repne   scasb           ; перейдем к следующей функции
                jmp     @@cont_4
@@cont_3:
                lodsb
                dec     si
                call    is_alpha        ; закончилось ли название в строке?
                jc      @@cont_4        ; продолжить, если нет
@@next_1:
                cmp     dx, func_num    ; названия функций совпали
                je      @@found_x       ; DX = func_num, значит функция - X
                cmp     dx, 1
                je      @@found_x       ; DX = 1, значит функция - Y
                cmp     byte ptr [si], '('
                pop     di
                jne     @@error_2       ; после функции должна быть скобка
                inc     si
                jmp     @@loop_1        ; идем дальше...
@@found_x:
                lodsb
                pop     di
                mov     di, offset operations
                mov     cx, oper_num+2  ; после X должна быть либо ')',
                repne   scasb           ; либо знак операции: +, -, *, /, ^
                je      @@loop_1        ; если что-то другое, то на выход
@@error_2:
                mov     ax, 10          ; ошибка в выражении
                pop     si
                stc
                jmp     exit
@@cont_4:
                pop     si              ; функции не совпали
                dec     dx              ; попробуем следующую...
                jnz     @@loop_2
@@error_1:
                mov     ax, 9           ; такой функции в таблице нет
                pop     si
                stc
                jmp     exit
@@next_2:
                pop     si
; Проверим расстановку знаков операций и '.'
                push    si
                xor     dx, dx          ; DX - номер текущего символа
@@loop_3:
                lodsb
                inc     dx              ; увеличим номер
                and     al, al          ; строка заканчивается нулем
                jz      @@next_3        ; перейти, если 0
                call    is_oper         ; это знак операции?
                jz      @@found_oper
                cmp     al, '('
                je      @@open_bracket
                cmp     al, ')'
                je      @@close_bracket
                cmp     al, '.'
                jne     @@loop_3
                lodsb
                dec     si
                call    is_number       ; после точки должно быть число
                jc      @@loop_3
                jmp     @@error_2       ; если что-то другое, то ошибка
@@open_bracket:
                cmp     dx, 1
                je      @@loop_3
                mov     al, [si-2]      ; AL - предыдущий символ
                call    is_oper         ; перед '(' должен быть знак операции,
                jz      @@loop_3        ;                или функция, или '('
                call    is_alpha
                jc      @@loop_3
                cmp     al, '('
                je      @@loop_3
                jmp     @@error_2
@@close_bracket:
                lodsb                   ; AL - следующий символ
                dec     si
                and     al, al
                jz      @@loop_3
                call    is_oper         ; после ')' должен быть знак операции
                jz      @@loop_3        ;                    или еще одна ')'
                cmp     al, ')'
                je      @@loop_3
                jmp     @@error_2
@@found_oper:
                cmp     dx, 1
                jne     @@pass
                cmp     al, '+'
                je      @@pass
                cmp     al, '-'         ; если первый символ '*', '/', '^',
                jne     @@error_2       ;            то ошибка, идем на выход
                jmp     @@pass_0
@@pass:
                mov     al, [si-2]      ; AL - предыдущий символ
                call    is_alpha        ; это может быть 'x', ')' или число
                jc      @@pass_0
                cmp     al, ')'
                je      @@pass_0
                call    is_number
                jc      @@pass_0
                cmp     al, '('         ; перед унарными + и - может быть '('
                jne     @@error_2
                mov     al, [si-1]
                cmp     al, '+'
                je      @@pass_0
                cmp     al, '-'
                jne     @@error_2
@@pass_0:
                lodsb
                dec     si              ; AL - следующий символ
                cmp     al, '('         ; это может быть '(', буква или число
                je      @@loop_3        ;         или '.' (например: 1.5*.45)
                cmp     al, '.'
                je      @@loop_3
                call    is_alpha
                jc      @@loop_3
                call    is_number
                jc      @@loop_3
                jmp     @@error_2
@@next_3:
; Ошибок нет. Начнем разбор строки
                cmp     y_flag, 0
                je      @@next_4
                mov     bx, const_buffer; BX - адрес для сохранения y
                mov     word ptr y_offset, bx
                mov     word ptr y_offset2, bx
                add     const_buffer, 20; следующий адрес
                push    es
                push    fs
                pop     es
                mov     di, bp
                mov     si, offset store_y
                mov     cx, sy_len
                rep     movsb
                pop     es
                mov     bp, di
@@next_4:
                pop     si
                mov     cx, str_len
                dec     cx
                call    make_main
                mov     byte ptr fs:[bp], 0F8h
                mov     byte ptr fs:[bp+1], 0C3h
                ret
make_main:
; FS:BP - подпрограмма, SI - строка ASCII, CX - длина строки
; Сначала ищем знаки операций на нулевом уровне вложенности скобок
;                                               по приоритету: ^, *, /, +, -
                push    si              ; пробуем найти последнюю операцию +
                add     si, cx
                xor     dx, dx          ; DX - уровень вложенности
                push    cx
@@mloop_0:
                dec     si
                lodsb
                cmp     al, ')'
                jne     @@mpass_0       ; т.к. идем с конца, то ) увеличивает
                inc     dx              ;                 уровень вложенности
@@mpass_0:
                cmp     al, '('
                jne     @@mpass_1
                dec     dx
@@mpass_1:
                and     dx, dx          ; если уровень вложенности не 0, то
                jnz     @@mnext_0       ;     перейдем к следующему символу
                cmp     al, '+'
                je      @@add           ; если нашли плюс
                cmp     al, '-'
                je      @@sub           ; если нашли минус
@@mnext_0:
                dec     si
                loop    @@mloop_0
                pop     cx              ; + и - не нашли
                pop     si
                push    si              ; попробуем поискать * и /
                add     si, cx          ;            также с конца
                xor     dx, dx          ; DX - уровень вложенности
                push    cx
@@mloop_1:
                dec     si
                lodsb
                cmp     al, ')'
                jne     @@mpass_2       ; т.к. идем с конца, то ) увеличивает
                inc     dx              ;                 уровень вложенности
@@mpass_2:
                cmp     al, '('
                jne     @@mpass_3
                dec     dx
@@mpass_3:
                and     dx, dx          ; если уровень вложенности не 0, то
                jnz     @@mnext_1       ;     перейдем к следующему символу
                cmp     al, '*'
                je      @@mul           ; если нашли *
                cmp     al, '/'
                je      @@div           ; если нашли /
@@mnext_1:
                dec     si
                loop    @@mloop_1
                pop     cx              ; * и / не нашли
                pop     si
                push    si              ; пробуем найти первую операцию ^
                xor     dx, dx          ; DX - уровень вложенности
                push    cx
@@mloop_2:
                lodsb
                cmp     al, '('
                jne     @@mpass_4
                inc     dx              ; увеличим уровень вложенности
@@mpass_4:
                cmp     al, ')'
                jne     @@mpass_5
                dec     dx              ; уменьшим уровень вложенности
@@mpass_5:
                and     dx, dx          ; если уровень вложенности не 0, то
                jnz     @@mnext_2       ;     перейдем к следующему символу
                cmp     al, '^'
                je      @@power         ; если нашли ^
@@mnext_2:
                loop    @@mloop_2
                pop     cx
                pop     si
; Знаки операций не найдены - или функция, или число, или ()
                lodsb
                cmp     al, '('
                jne     @@mcont_0
                dec     cx
                dec     cx
                jmp     make_main       ; убрали внешние скобки, рекурсия
@@mcont_0:
                dec     si
                call    is_alpha
                jc      @@function      ; переход, если функция
; в строке записано число
                mov     bx, const_buffer; BX - адрес для константы
                mov     word ptr num_offset, bx
                add     const_buffer, 10; следующий адрес
                lea     di, [esi+ecx]
                xor     al, al
                xchg    al, [di]        ; поместили 00h в конец строки
                push    di
                push    ax
                call    val_func        ; поместили по адресу в BX
                pop     ax
                pop     di
                mov     [di], al        ; восстановили прежнее значение
                jc      @@error_3       ; если число записано неправильно
                mov     si, offset put_const
                mov     cx, pc_len      ; поместить на стек константу
@@copy_block:
                mov     di, bp
                push    es
                push    fs
                pop     es
                rep     movsb           ; скопировали блок в подпрограмму
                mov     bp, di
                pop     es
                ret                     ; возврат в вызывающую процедуру
@@error_3:
                mov     ax, 12
                stc
                ret
@@function:
                cmp     al, 'x'
                jne     @@mcont_1
                cmp     cx, 1
; если функция - X, то ничего делать не надо, т.к. X уже вершине на стека
                je      exit
@@mcont_1:
                cmp     al, 'y'
                jne     @@mcont
                cmp     cx, 1
                jne     @@mcont
                mov     si, offset put_y; функция Y
                mov     cx, py_len
                jmp     @@copy_block    ; скопируем подпрограммку, и на выход
@@mcont:
                push    si
@@mloop_3:
                lodsb                   ; ищем аргумент
                dec     cx
                cmp     al, '('
                jne     @@mloop_3
                dec     cx
                call    make_main       ; рекурсивное вычисление скобок
                pop     si
                jc      exit            ; выход, если ошибка
                mov     di, offset functions
                xor     dx, dx          ; DX - номер функции
                mov     al, 20h
@@mloop_4:
                inc     dx
                push    si
                stc
                sbb     cx, cx
                repe    cmpsb           ; сравниваем функции
                cmp     byte ptr [di-1], al
                je      @@mcont_2       ; если совпали, то в [DI-1] - 20h
                repne   scasb           ; иначе ищем 20h, чтобы перейти к
                pop     si              ;                   следующей функции
                jmp     @@mloop_4
@@mcont_2:
                cmp     byte ptr [si-1], '('
                pop     si              ; если совпали, то в [SI-1] - '('
                jne     @@mloop_4
                mov     si, offset put_func
                mov     cx, func_len    ; нашли функцию, ее номер в DX
                dec     dx
                dec     dx
                imul    dx, cx
                add     si, dx          ; SI - адрес подпрограмки для функции
                jmp     @@copy_block    ; скопируем его, и на выход
; Найдена операция сложения или унарный плюс
@@add:
                loop    @@mcont_3       ; в CX - длина оставшейся части строки
                pop     cx              ; если унарный плюс, то его надо
                pop     si              ;                        игнорировать
                inc     si
                dec     cx
                jmp     make_main
@@mcont_3:
                inc     cx              ; может это знак в числе (2.34e+4),
                cmp     byte ptr [si-2], 'e'
                je      @@mnext_0       ;                  тогда ложный вызов
                pop     bx              ; BX - длина всей строки
                sub     bx, cx          ; длина второй части строки
                dec     cx
                push    cx
                push    si
                mov     si, offset dupl
                mov     cx, dupl_len
                call    @@copy_block    ; дублирование аргумента
                pop     si
                mov     cx, bx
                call    make_main       ; рекурсивное вычисление слагаемого
                pushf
                mov     si, offset exch
                mov     cx, exch_len
                call    @@copy_block    ; поменяли слагаемое и аргумент
                popf
                pop     cx
                pop     si              ; SI - начало строки
                jc      exit            ; выход, если ошибка
                call    make_main       ; рекурсивное вычисление слагаемого
                jc      exit            ; выход, если ошибка
                mov     si, offset put_add
                mov     cx, pa_len
                jmp     @@copy_block    ; скопировали вызов процедуры сложения
; Найдена операция вычитания или унарный минус
@@sub:
                loop    @@mcont_4       ; в CX - длина оставшейся части строки
                pop     cx              ; если унарный минус, то надо
                pop     si              ;        вычислить оставшуюся часть и
                dec     cx              ;                    инвертировать ее
                inc     si
                call    make_main
                jc      exit            ; выход, если ошибка
                mov     si, offset put_negative
                mov     cx, pn_len
                jmp     @@copy_block
@@mcont_4:
                inc     cx              ; может это знак в числе (3.71e-20),
                cmp     byte ptr [si-2], 'e'
                je      @@mnext_0       ;                  тогда ложный вызов
                dec     cx
                push    cx
                mov     si, offset dupl
                mov     cx, dupl_len
                call    @@copy_block    ; дублирование аргумента
                pop     cx
                pop     bx              ; BX - длина всей строки
                pop     si              ; SI - начало строки
                stc
                sbb     bx, cx          ; BX - длина второй части строки
                push    bx
                push    si
                push    cx
                call    make_main       ; рекурсивное вычисление уменьшаемого
                pushf
                mov     si, offset exch
                mov     cx, exch_len
                call    @@copy_block    ; поменяли уменьшаемое и аргумент
                popf
                pop     bx              ; BX - длина первой части строки
                pop     si              ; SI - начало строки
                pop     cx              ; CX - длина второй части строки
                jc      exit            ; выход, если ошибка
                stc
                adc     si, bx          ; SI - начало второй части строки
                call    make_main       ; рекурсивное вычисление вычитаемого
                jc      exit            ; выход, если ошибка
                mov     si, offset put_sub
                mov     cx, ps_len
                jmp     @@copy_block    ; копируем вызов процедуры вычитания
; Найдена операция умножения
@@mul:
                pop     bx              ; BX - длина всей строки
                push    cx
                sub     bx, cx          ; длина второй части строки
                push    si
                mov     si, offset dupl
                mov     cx, dupl_len
                call    @@copy_block    ; дублирование аргумента
                pop     si
                mov     cx, bx
                call    make_main       ; рекурсивное вычисление множителя
                pushf
                mov     si, offset exch
                mov     cx, exch_len
                call    @@copy_block    ; поменяли множитель и аргумент
                popf
                pop     cx
                pop     si              ; SI - начало строки
                jc      exit            ; выход, если ошибка
                dec     cx
                call    make_main       ; рекурсивное вычисление множителя
                jc      exit            ; выход, если ошибка
                mov     si, offset put_mul
                mov     cx, pm_len
                jmp     @@copy_block    ; копируем вызов процедуры умножения
; Найдена операция деления
@@div:
                push    cx
                mov     si, offset dupl
                mov     cx, dupl_len
                call    @@copy_block    ; дублирование аргумента
                pop     cx
                pop     bx              ; BX - длина всей строки
                pop     si              ; SI - начало строки
                sub     bx, cx          ; BX - длина второй части строки
                push    bx
                push    si
                push    cx
                dec     cx
                call    make_main       ; рекурсивное вычисление делимого
                pushf
                mov     si, offset exch
                mov     cx, exch_len
                call    @@copy_block    ; поменяли делимое и аргумент
                popf
                pop     bx              ; BX - длина первой части строки+1
                pop     si              ; SI - начало строки
                pop     cx              ; CX - длина второй части строки
                jc      exit            ; выход, если ошибка
                add     si, bx          ; SI - начало второй части строки
                call    make_main       ; рекурсивное вычисление делителя
                jc      exit            ; выход, если ошибка
                mov     si, offset put_div
                mov     cx, pd_len
                jmp     @@copy_block    ; копируем вызов процедуры деления
; Найдена операция возведения в степень
@@power:
                dec     cx
                mov     di, si
                push    cx              ; пробуем найти еще операции '^'
                repne   scasb
                pop     cx
                je      @@mcont_5       ; если нашли, то основной алгоритм
                lodsb
                dec     si
                call    is_number       ; число это или нет?
                jnc     @@mcont_5       ; переход, если функция
                push    si
                push    cx              ; проверим целое число или нет
                mov     bx, offset i_buff
                add     si, cx
                push    si
                xor     al, al
                xchg    al, [si]
                push    ax
                sub     si, cx
                call    val_func        ; преобразовали число (в [BX])
                pop     ax
                pop     si
                jnc     @@no_error
                pop     cx              ; если нашли ошибку
                pop     si
                jmp     @@error_3
@@no_error:
                xchg    al, [si]
                call    get_int         ; в AX - целая часть, в [BX] - дробная
                pop     cx
                pop     si
                jc      @@mcont_5       ; если число слишком велико
                cmp     word ptr [bx+8], 0000h
                jne     @@mcont_5       ; если дробная часть не равна 0
                pop     bx
                pop     si              ; итак, число целое - используем
                stc                     ;               специальную процедуру
                sbb     bx, cx          ; BX - длина основания (в строке)
                mov     cx, bx
                push    ax
                call    make_main       ; вычислили основание
                pop     ax
                jc      exit
                mov     word ptr power_offset, ax
                mov     si, offset put_i_power
                mov     cx, pip_len
                jmp     @@copy_block
@@mcont_5:
                push    si
                push    cx
                mov     si, offset dupl
                mov     cx, dupl_len
                call    @@copy_block    ; дублирование аргумента
                pop     cx
                pop     si
                push    cx
                call    make_main       ; вычислили степень
                pushf
                mov     si, offset exch
                mov     cx, exch_len
                call    @@copy_block    ; поменяли делимое и аргумент
                popf
                pop     bx              ; BX - длина степени
                pop     cx              ; CX - длина всей строки
                pop     si              ; SI - начало строки
                jc      exit
                stc
                sbb     cx, bx          ; CX - длина основания
                call    make_main       ; вычислили основание
                jc      exit
                mov     si, offset put_func + 2*func_len
                mov     cx, func_len
                call    @@copy_block    ; логарифм основания
                mov     si, offset put_mul
                mov     cx, pm_len
                call    @@copy_block    ; степень * логарифм основания
                mov     si, offset put_func + func_len
                mov     cx, func_len
                jmp     @@copy_block    ; экспонента
make_mthproc    ENDP



is_alpha        PROC; Возвращает CF=1, если в AL буква ('a'..'z'), иначе CF=0
                cmp     al, 'z'+1
                jnc     @@exit
                cmp     al, 'a'
                cmc
@@exit:
                ret
is_alpha        ENDP



is_number       PROC; Возвращает CF=1, если в AL цифра ('0'..'9'), иначе CF=0
                cmp     al, '9'+1
                jnc     @@exit
                cmp     al, '0'
                cmc
@@exit:
                ret
is_number       ENDP



is_oper         PROC; Возвращает ZF=1, если в AL знак операции, иначе ZF=0
                mov     di, offset operations
                mov     cx, oper_num
                repne   scasb
                ret
is_oper         ENDP



is_correct      PROC; Возвращает ZF=0, если в AL недопустимый символ
                mov     di, offset symbols
                push    cx
                mov     cx, sym_num
                repne   scasb
                pop     cx
                ret
is_correct      ENDP



                PUBLIC  empty_load
empty_load      PROC
                inc     stk_amount
                inc     stk_top
                ret
empty_load      ENDP



                PUBLIC  empty_store
empty_store     PROC
                dec     stk_amount
                dec     stk_top
                ret
empty_store     ENDP



                PUBLIC  i_load
i_load          PROC; Загружает интервал на вершину стека
; Вход: BX - указатель на интервал (20 байт)
; Выход: если CF=0, то ST(0) - интервал, иначе AX = код ошибки
                cmp     stk_amount, 100h
                jb      @@continue
                mov     ax, 2           ; переполнение стека
                stc
                ret
@@continue:
                inc     stk_amount
                inc     stk_top
                movzx   di, stk_top
                lea     di, [edi+4*edi]
                shl     di, 2           ; умножили DI на 20
                add     di, offset internal_stack
                mov     si, bx
                cld                     ; направление - прямое
                mov     cx, 5
                rep     movsd
                clc                     ; нет ошибок
                ret
i_load          ENDP



                PUBLIC  duplicate
duplicate       PROC; Дублирует вершину стека
; Вход: ST(0) = x
; Выход: ST(0) = x, ST(1) = x
                cmp     stk_amount, 100h
                jb      @@continue
                mov     ax, 2           ; переполнение стека
                stc
                ret
@@continue:
                inc     stk_amount
                inc     stk_top
                movzx   ax, stk_top
                lea     ax, [eax+4*eax] ; умножить AX на 5
                shl     ax, 2           ; каждый интервал занимает 20 байт
                mov     di, offset internal_stack
                mov     si, 13ECh       ; 13ECh = FFh*20 - макс. смещение
                and     ax, ax
                jz      @@cont_0
                lea     si, [eax-20]
@@cont_0:
                add     si, di          ; SI - указатель ST(1).low
                add     di, ax          ; DI - указатель ST(0).low
                cld                     ; направление - прямое
                mov     cx, 5
                rep     movsd
                clc                     ; нет ошибок
                ret
duplicate       ENDP



                PUBLIC  exchange
exchange        PROC; Меняет ST(0) и ST(1)
; Вход: ST(0) = x, ST(1) = y
; Выход: ST(0) = y, ST(1) = x
                mov     ax, 1
                cmp     stk_amount, 2
                jb      @@exit
                movzx   ax, stk_top
                lea     ax, [eax+4*eax] ; умножить AX на 5
                shl     ax, 2           ; каждый интервал занимает 20 байт
                mov     di, offset internal_stack
                mov     si, 13ECh       ; 13ECh = FFh*20 - макс. смещение
                and     ax, ax
                jz      @@cont_0
                lea     si, [eax-20]
@@cont_0:
                add     si, di          ; SI - указатель ST(1).low
                add     di, ax          ; DI - указатель ST(0).low
                call    md_change
                add     di, 10
                add     si, 10
                call    md_change
                clc                     ; нет ошибок
@@exit:
                ret
exchange        ENDP



                PUBLIC  i_store
i_store         PROC; Снимает интервал с вершины стека
; Вход: BX - указатель на 20 байт
; Выход: если CF=0, то [BX] = ST(0), иначе AX = код ошибки
                mov     ax, 1
                cmp     stk_amount, ax
                jb      @@exit          ; выход, если стек пуст
                movzx   si, stk_top
                lea     si, [esi+4*esi]
                shl     si, 2           ; умножили SI на 20
                add     si, offset internal_stack
                mov     di, bx
                cld                     ; направление - прямое
                mov     cx, 5
                rep     movsd
                dec     stk_amount
                dec     stk_top
                clc                     ; нет ошибок
@@exit:
                ret
i_store         ENDP



                PUBLIC  get_width
get_width       PROC; Возвращает ширину интервала
; Вход: ST(0) - X, BX - указатель на 10 байт
; Выход: [BX] - w(X)
                mov     ax, 1
                cmp     stk_amount, ax
                jb      @@exit
                push    bx
                call    get_top
                lea     si, [bx+10]
                pop     di
                mov     dx, bx
                mov     bx, di
                mov     cx, 5
                rep     movsw
                xor     byte ptr [si-11], 80h
                push    si
                push    bx
                call    n_add
                pop     bx
                pop     si
                pushf
                xor     byte ptr [si-11], 80h
                popf
@@exit:
                ret
get_width       ENDP



                PUBLIC  get_middle
get_middle      PROC; Возвращает среднюю точку
; Вход: ST(0) - X, BX - указатель на 10 байт
; Выход: [BX] - m(X)
                mov     ax, 1
                cmp     stk_amount, ax
                jb      exit
                push    bx
                call    get_top
                pop     di
                lea     si, [bx+10]
                mov     dx, bx
                mov     bx, di
                mov     cx, 5
                rep     movsw
                push    bx
                call    n_add
                pop     bx
                mov     di, offset i_buff
                mov     dx, di
                xor     eax, eax
                stosd
                stosd
                stosw
                mov     byte ptr [di-3], 20h
                jmp     n_div
get_middle      ENDP



                PUBLIC  majorise
majorise        PROC; Мажоризация интервала на вершине стека
; Вход: ST(0)
; Выход: ST(0) - мажоризированный интервал; если CF=1, то AX = код ошибки
                call    major
                pushf
                movzx   bx, stk_top
                imul    bx, 20
                lea     di, [bx+offset internal_stack]
                cmp     byte ptr [di], 0FFh
                jne     @@next
                test    byte ptr [di+9], 80h
                jnz     @@next
                mov     si, offset MMN  ; нижняя граница - +бесконечность
                cld
                mov     cx, 4
                rep     movsw           ; заменим ее на +НБЧ
                jmp     @@exit
@@next:
                add     di, 10
                cmp     byte ptr [di], 0FFh
                jne     @@exit
                test    byte ptr [di+9], 80h
                jz      @@exit
                mov     si, offset MMN  ; верхняя граница - -бесконечность
                cld
                mov     cx, 4
                rep     movsw           ; заменим ее на -НБЧ
@@exit:
                popf
                ret
majorise        ENDP



major           PROC; Мажоризация интервала на вершине стека
; Вход: ST(0)
; Выход: ST(0) - мажоризированный интервал; если CF=1, то AX = код ошибки
                mov     ax, 1
                cmp     stk_amount, ax
                jb      @@exit          ; выход, если стек пуст
                movzx   ax, stk_top
                lea     ax, [eax+4*eax]
                shl     ax, 2           ; AX - смещение вершины стека
                mov     bx, offset internal_stack
                add     bx, ax
                xor     eax, eax
                cmp     [bx], eax
                jne     @@cont_0
                cmp     [bx+4], eax
                je      @@next          ; нижняя граница - 0, не надо мажор.
@@cont_0:
                push    bx
                test    byte ptr [bx+9], 80h
                jnz     @@negative
                call    dec_man
                jmp     @@cont_1
@@negative:
                call    inc_man
@@cont_1:
                pop     bx
@@next:
                add     bx, 10
                xor     eax, eax
                cmp     [bx], eax
                jne     @@cont_2
                cmp     [bx+4], eax
                je      @@exit          ; верхняя граница - 0, не надо мажор.
@@cont_2:
                push    bx
                test    byte ptr [bx+9], 80h
                jz      @@positive
                call    dec_man
                pop     bx
@@end:
                cmp     byte ptr [bx-10], 0FFh
                cmc
                mov     ax, 3           ; нижняя граница - минус бесконечность
@@exit:
                ret
@@positive:
                call    inc_man
                pop     bx
                mov     ax, 3
                cmp     byte ptr [bx], 0FFh
                jne     @@end
                stc                     ; верхняя граница - бесконечность
                ret
major           ENDP



                PUBLIC  crossing
crossing        PROC; Пересечение интервалов
; Вход: ST(0) - первый интервал, BX - указатель на второй интервал (20 байт)
; Выход: если CF=0, то ST(0) - результат, иначе AX = код ошибки
                mov     ax, 1
                cmp     stk_amount, ax
                jb      @@exit          ; выход, если стек пуст
                cld
                movzx   ax, stk_top
                lea     ax, [eax+4*eax] ; умножить AX на 5
                shl     ax, 2           ; каждый интервал занимает 20 байт
                add     ax, offset internal_stack
                mov     si, ax
                lea     di, [bx+10]
                call    compare         ; сравнить [BX].high и ST(0).low
                mov     ax, 4
                jb      @@exit          ; выход, если ST(0).low больше
                xchg    di, si
                add     di, 10
                sub     si, 10
                call    compare         ; сравнить ST(0).high и [BX].low
                mov     ax, 4
                jb      @@exit          ; выход, если [BX].low больше
                sub     di, 10
                call    compare         ; сравнить ST(0).low и [BX].low
                jae     @@next          ; переход, если ST(0).low больше
                mov     cx, 5
                rep     movsw           ; ST(0).low = [BX].low
                jmp     @@pass
@@next:
                add     si, 10
                add     di, 10
@@pass:
                call    compare         ; сравнить ST(0).high и [BX].high
                jb      @@cancel        ; выход, если ST(0).high меньше
                mov     cx, 5
                rep     movsw           ; ST(0).high = [BX].high
@@cancel:
                clc
@@exit:
                ret
crossing        ENDP



                PUBLIC  i_hull
i_hull          PROC; Интервальное объединение
; Вход: ST(0), ST(1) - интервалы
; Выход: если CF=0, то результат в ST(0), иначе AX = код ошибки
                mov     ax, 1
                cmp     stk_amount, ax
                jb      exit
                movzx   ax, stk_top
                dec     stk_top
                dec     stk_amount
                lea     ax, [eax+4*eax] ; умножить AX на 5
                shl     ax, 2           ; каждый интервал занимает 20 байт
                mov     si, offset internal_stack
                mov     di, 13ECh       ; 13ECh = FFh*20 - макс. смещение
                and     ax, ax
                jz      @@cont_0
                lea     di, [eax-20]
@@cont_0:
                add     di, si          ; DI - указатель ST(1).low
                add     si, ax          ; SI - указатель ST(0).low
i_hull_main:
                call    compare
                jb      @@cont_1        ; переход, если ST(1).low меньше
                mov     cx, 5
                rep     movsw
                jmp     @@pass
@@cont_1:
                add     di, 10          ; DI - указатель ST(1).high
                add     si, 10          ; SI - указатель ST(0).high
@@pass:
                call    compare
                jae     exit            ; переход, если ST(1).high больше
                mov     cx, 5
                rep     movsw
                clc
exit:
                ret
i_hull          ENDP



                PUBLIC  im_hull
im_hull         PROC; Интервальное объединение
; Вход: ST(0) - первый интервал, BX - указатель на второй интервал
; Выход: если CF=0, то ST(0) - результат, иначе AX = код ошибки
                mov     ax, 1
                cmp     stk_amount, ax
                jb      exit            ; выход, если стек пуст
                movzx   di, stk_top
                lea     di, [edi+4*edi] ; умножить DI на 5
                shl     di, 2           ; каждый интервал занимает 20 байт
                add     di, offset internal_stack
                mov     si, bx
                jmp     i_hull_main
im_hull         ENDP



                PUBLIC  c_add
c_add           PROC; Сложение с константой
; Вход: ST(0), BX - слагаемые
; Выход: если CF=0, то ST(0) = ST(0)+[BX], иначе AX = код ошибки
                mov     ax, 1
                cmp     stk_amount, ax
                jb      exit            ; выход, если нет аргументов
                mov     dx, bx
                call    get_top         ; в BX - вершина стека
                push    dx
                push    bx
                call    n_add           ; прибавим число к нижней границе
                pop     bx
                pop     dx
                add     bx, 10
                call    n_add           ; прибавим число к верхней границе
                jmp     majorise        ; мажоризация
c_add           ENDP



                PUBLIC  cm_add
cm_add          PROC; Сложение с целочисленной константой
; Вход: ST(0), AX - слагаемые
; Выход: если CF=0, то ST(0) = ST(0)+AX, иначе AX = код ошибки
                call    load_int        ; AX на стек
                jc      exit
                jmp     i_add
cm_add          ENDP



                PUBLIC  i_add
i_add           PROC; Сложение интервалов
; Вход: ST(0), ST(1) - слагаемые
; Выход: если CF=0, то ST(0) = ST(0)+ST(1), иначе AX = код ошибки
                mov     ax, 1
                cmp     stk_amount, 2
                jb      exit            ; выход, если нет аргументов
                movzx   ax, stk_top
                dec     stk_top
                dec     stk_amount
                lea     ax, [eax+4*eax] ; умножить AX на 5
                shl     ax, 2           ; каждый интервал занимает 20 байт
                mov     dx, offset internal_stack
                mov     bx, 13ECh       ; 13ECh = FFh*20 - макс. смещение
                and     ax, ax
                jz      @@cont_0
                lea     bx, [eax-20]
@@cont_0:
                add     bx, dx          ; BX - указатель ST(1).low
                add     dx, ax          ; DX - указатель ST(0).low
i_add_main:
                push    dx
                push    bx
                call    n_add           ; сложим нижние границы интервалов
                pop     bx
                pop     dx
                add     bx, 10          ; BX - указатель ST(1).high
                add     dx, 10          ; DX - указатель ST(0).high
                call    n_add           ; сложим верхние границы интервалов
                jmp     majorise        ; мажоризация
i_add           ENDP



                PUBLIC  im_add
im_add          PROC; Сложение интервалов
; Вход: ST(0) - первое слагаемое, BX - указатель на второе слагаемое
; Выход: если CF=0, то ST(0) = ST(0)+[BX], иначе AX = код ошибки
                mov     ax, 1
                cmp     stk_amount, ax
                jb      exit            ; выход, если стек пуст
                mov     dx, bx
                movzx   bx, stk_top     ; BX будет указывать на ST(0).low
                lea     bx, [ebx+4*ebx] ; умножить BX на 5
                shl     bx, 2           ; каждый интервал занимает 20 байт
                add     bx, offset internal_stack
                jmp     i_add_main
im_add          ENDP



                PUBLIC  c_sub
c_sub           PROC; Вычитание с константой
; Вход: ST(0) - уменьшаемое, BX - вычитаемое
; Выход: если CF=0, то ST(0) = ST(0)-[BX], иначе AX = код ошибки
                mov     ax, 1
                cmp     stk_amount, ax
                jb      exit            ; выход, если нет аргументов
                mov     dx, bx          ; изменим знак вычитаемого
                xor     byte ptr [bx+9], 80h
                call    get_top         ; в BX - вершина стека
                push    dx
                push    bx
                call    n_add           ; вычтем число из нижней границы
                pop     bx
                pop     dx
                add     bx, 10
                push    dx
                call    n_add           ; вычтем число из верхней границы
                pop     bx
                xor     byte ptr [bx+9], 80h
                jmp     majorise        ; мажоризация
c_sub           ENDP



                PUBLIC  cm_sub
cm_sub          PROC; Вычитание целочисленной константы
; Вход: ST(0) - уменьшаемое, AX - вычитаемое
; Выход: если CF=0, то ST(0) = ST(0)-AX, иначе AX = код ошибки
                call    load_int        ; AX на стек
                jc      exit
                jmp     i_sub
cm_sub          ENDP



                PUBLIC  i_sub
i_sub           PROC; Вычитание интервалов
; Вход: ST(0), ST(1) - вычитаемое, уменьшаемое
; Выход: если CF=0, то ST(0) = ST(1)-ST(0), иначе AX = код ошибки
                mov     ax, 1
                cmp     stk_amount, 2
                jb      exit            ; выход, если нет аргументов
                movzx   ax, stk_top
                dec     stk_top
                dec     stk_amount
                lea     ax, [eax+4*eax] ; умножить AX на 5
                shl     ax, 2           ; каждый интервал занимает 20 байт
                mov     dx, offset internal_stack
                mov     bx, 13F6h       ; 13F6h = FFh*20+10
                and     ax, ax
                jz      @@cont_0
                lea     bx, [eax-10]
@@cont_0:
                add     bx, dx          ; BX - указатель ST(1).high
                add     dx, ax          ; DX - указатель ST(0).low
i_sub_main:
                mov     si, dx          ; изменим знак вычитаемого
                xor     byte ptr [si+9], 80h
                push    dx
                push    bx
                call    n_add           ; вычислим верхнюю границу интервала
                pop     bx
                pop     dx
                sub     bx, 10          ; BX - указатель ST(1).low
                add     dx, 10          ; DX - указатель ST(0).high
                mov     si, dx          ; изменим знак вычитаемого
                xor     byte ptr [si+9], 80h
                xor     byte ptr [si-1], 80h
                push    si
                call    n_add           ; вычислим нижнюю границу интервала
                pop     si
                xor     byte ptr [si+9], 80h
                jmp     majorise        ; мажоризация
i_sub           ENDP



                PUBLIC  im_sub
im_sub          PROC; Вычитание интервалов
; Вход: ST(0) - вычитаемое, BX - указатель на уменьшаемое
; Выход: если CF=0, то ST(0) = ST(0)-[BX], иначе AX = код ошибки
                mov     ax, 1
                cmp     stk_amount, ax
                jb      exit            ; выход, если стек пуст
                mov     dx, bx
                movzx   bx, stk_top     ; BX будет указывать на ST(0).high
                lea     bx, [ebx+4*ebx] ; умножить BX на 5
                shl     bx, 2           ; каждый интервал занимает 20 байт
                add     bx, offset internal_stack+10
                jmp     i_sub_main
im_sub          ENDP



                PUBLIC  i_negative
i_negative      PROC; Функция -x
; Вход: ST(0) - x
; Выход: если CF=0, то ST(0) = -x, иначе AX = код ошибки
                mov     ax, 1
                cmp     stk_amount, ax
                jb      @@exit          ; выход, если стек пуст
                movzx   di, stk_top     ; DI будет указывать на ST(0)
                lea     di, [edi+4*edi] ; умножить DI на 5
                shl     di, 2           ; каждый интервал занимает 20 байт
                add     di, offset internal_stack
                mov     al, 80h
                xor     [di+9], al
                xor     [di+19], al
                lea     si, [di+10]
                call    md_change
                clc
@@exit:
                ret
i_negative      ENDP



                PUBLIC  i_abs
i_abs           PROC; Абсолютная величина
; Вход: ST(0) - X
; Выход: ST(0) - |X|
                mov     ax, 1
                cmp     stk_amount, ax
                jb      exit
                call    get_top         ; BX - указывает на ST(0)
                mov     si, bx
                lea     di, [bx+10]
                call    compare_abs     ; CMP [DI], [SI]
                jnb     @@cont_0
                call    md_change
@@cont_0:
                mov     ax, [si+8]
                xor     ax, [di+8]
                jns     @@cont_1
                xor     eax, eax        ; 0 содержится в X, значит
                mov     [si], eax       ;             нижняя граница будет 0
                mov     [si+4], eax
                mov     [si+8], ax
@@cont_1:
                and     byte ptr [si+9], 7Fh
                and     byte ptr [di+9], 7Fh
                ret
i_abs           ENDP



                PUBLIC  c_mul
c_mul           PROC; Умножение на константу
; Вход: ST(0), BX - множители
; Выход: если CF=0, то ST(0) = ST(0)*[BX], иначе AX = код ошибки
                mov     ax, 1
                cmp     stk_amount, ax
                jb      exit            ; выход, если нет аргументов
                mov     dx, bx
                call    get_top         ; BX - указатель вершины стека
                mov     si, dx
                test    byte ptr [si+9], 80h
                jz      @@cont_0
                mov     si, bx          ; если число < 0, то меняем верхнюю
                lea     di, [bx+10]     ;          и нижнюю границу местами
                call    md_change
@@cont_0:
                push    bx
                push    dx
                call    n_mul           ; ST(0).low = ST(0).low * C
                pop     dx
                pop     bx
                add     bx, 10
                call    n_mul           ; ST(0).high = ST(0).high * C
                jmp     majorise        ; мажоризация
c_mul           ENDP



                PUBLIC  cm_mul
cm_mul          PROC; Умножение на целочисленную константу
; Вход: ST(0), AX - множители
; Выход: если CF=0, то ST(0) = ST(0)*AX, иначе AX = код ошибки
                call    load_int        ; AX на стек
                jc      exit
                call    get_top         ; BX - вершина стека (там AX)
                dec     stk_top
                dec     stk_amount      ; вернули стек на прежнее место
                jmp     c_mul
cm_mul          ENDP



                PUBLIC  i_mul
i_mul           PROC; Умножение интервалов
; Вход: ST(0), ST(1) - множители
; Выход: если CF=0, то ST(0) = ST(0)*ST(1), иначе AX = код ошибки
                mov     ax, 1
                cmp     stk_amount, 2
                jb      @@exit          ; выход, если нет аргументов
                movzx   ax, stk_top
                dec     stk_top
                dec     stk_amount
                lea     ax, [eax+4*eax] ; умножить AX на 5
                shl     ax, 2           ; каждый интервал занимает 20 байт
                mov     dx, offset internal_stack
                mov     bx, 13ECh       ; 13ECh = FFh*20
                and     ax, ax
                jz      @@cont
                lea     bx, [eax-20]
@@cont:
                add     bx, dx          ; BX - указатель ST(1).low
                add     dx, ax          ; DX - указатель ST(0).low
i_mul_main:
                mov     di, offset i_buff
                mov     si, bx
                mov     cx, 5
                rep     movsd           ; сохраним ST(1)
                push    bx
                push    dx
                call    n_mul           ; ST(1).low = ST(0).low * ST(1).low
                pop     dx
                pop     bx
                push    bx
                add     bx, 10
                add     dx, 10
                push    dx
                call    n_mul           ; ST(1).high = ST(0).high * ST(1).high
                pop     dx
                mov     bx, offset i_buff
                push    bx
                push    dx
                call    n_mul           ; buff.high = ST(0).high * ST(1).low
                pop     dx
                sub     dx, 10
                mov     bx, offset i_buff+10
                call    n_mul           ; buff.low = ST(0).low * ST(1).high
                pop     bx              ; BX - указывает на buff.low
                pop     dx              ; DX - указывает на ST(1).low
                mov     si, bx
                mov     di, dx
                call    compare
                jb      @@cont_0        ; переход, если ST(1).low меньше
                call    md_change
@@cont_0:
                add     si, 10          ; SI - ST(0).high
                call    compare
                jb      @@cont_1        ; переход, если ST(1).low меньше
                call    md_change
@@cont_1:
                lea     si, [di+10]     ; SI - ST(1).high
                call    compare
                jb      @@cont_2        ; переход, если ST(1).low меньше
                call    md_change
@@cont_2:
                mov     di, si          ; DI - ST(1).high
                mov     si, bx          ; SI - ST(0).low
                call    compare
                jae     @@cont_3        ; переход, если ST(1).high больше
                call    md_change
@@cont_3:
                add     si, 10          ; SI - ST(0).high
                call    compare
                jae     @@cont_4        ; переход, если ST(1).high больше
                call    md_change
@@cont_4:
                jmp     majorise        ; мажоризация
md_change:
                mov     eax, [di]
                xchg    eax, [si]
                mov     [di], eax
                mov     eax, [di+4]
                xchg    eax, [si+4]
                mov     [di+4], eax
                mov     ax, [di+8]
                xchg    ax, [si+8]
                mov     [di+8], ax
@@exit:
                ret
i_mul           ENDP



                PUBLIC  im_mul
im_mul          PROC; Умножение интервалов
; Вход: ST(0) - первый множитель, BX - указатель на второй множитель
; Выход: если CF=0, то ST(0) = ST(0)*[BX], иначе AX = код ошибки
                mov     ax, 1
                cmp     stk_amount, ax
                jb      exit            ; выход, если стек пуст
                mov     dx, bx
                movzx   bx, stk_top     ; BX будет указывать на ST(0).low
                lea     bx, [ebx+4*ebx] ; умножить BX на 5
                shl     bx, 2           ; каждый интервал занимает 20 байт
                add     bx, offset internal_stack
                jmp     i_mul_main
im_mul          ENDP



                PUBLIC  c_div
c_div           PROC; Деление на константу
; Вход: ST(0), BX - делитель, делимое
; Выход: если CF=0, то ST(0) = ST(1)/[BX], иначе AX = код ошибки
                mov     ax, 1
                cmp     stk_amount, ax
                jb      exit            ; выход, если нет аргументов
                mov     si, bx
                call    get_top         ; BX - указатель на вершину стека
                xor     eax, eax
                cmp     [si], eax
                jne     @@next_0        ; переход, если делитель <> 0
                cmp     [si+4], eax
                jne     @@next_0
                dec     eax             ; деление на 0
                mov     [bx], eax       ; запишем бесконечность
                mov     [bx+4], eax
                mov     [bx+10], eax
                mov     [bx+14], eax
                mov     ah, [bx+9]
                and     ah, 80h
                or      ah, 3Fh
                mov     [bx+9], ah
                mov     ah, [bx+19]
                and     ah, 80h
                or      ah, 3Fh
                mov     [bx+19], ah
                stc
                mov     ax, 3
                ret
@@next_0:
                mov     dx, si
                test    byte ptr [si+9], 80h
                jz      @@cont_0
                mov     si, bx          ; если число < 0, то меняем верхнюю
                lea     di, [bx+10]     ;          и нижнюю границу местами
                call    md_change
@@cont_0:
                push    bx
                push    dx
                call    n_div           ; ST(0).low = ST(0).low / C
                pop     dx
                pop     bx
                add     bx, 10
                call    n_div           ; ST(0).high = ST(0).high / C
                jmp     majorise        ; мажоризация
c_div           ENDP



                PUBLIC  cm_div
cm_div          PROC; Деление на целочисленную константу
; Вход: ST(0), AX - делитель, делимое
; Выход: если CF=0, то ST(0) = ST(1)/AX, иначе AX = код ошибки
                call    load_int        ; AX на стек
                jc      exit
                call    get_top         ; BX - вершина стека (там AX)
                dec     stk_top
                dec     stk_amount      ; вернули стек на прежнее место
                jmp     c_div
cm_div          ENDP



                PUBLIC  i_div
i_div           PROC; Деление интервалов
; Вход: ST(0), ST(1) - делитель, делимое
; Выход: если CF=0, то ST(0) = ST(1)/ST(0), иначе AX = код ошибки
                mov     ax, 1
                cmp     stk_amount, 2
                jb      @@exit          ; выход, если нет аргументов
                movzx   ax, stk_top
                dec     stk_top
                dec     stk_amount
                lea     ax, [eax+4*eax] ; умножить AX на 5
                shl     ax, 2           ; каждый интервал занимает 20 байт
                mov     dx, offset internal_stack
                mov     bx, 13ECh       ; 13ECh = FFh*20
                and     ax, ax
                jz      @@cont
                lea     bx, [eax-20]
@@cont:
                add     bx, dx          ; BX - указатель ST(1).low
                add     dx, ax          ; DX - указатель ST(0).low
i_div_main:
                mov     si, dx
                xor     eax, eax
                cmp     [si], eax
                jne     @@next_0        ; переход, если нижняя граница <> 0
                cmp     [si+4], eax
                jne     @@next_0
@@infinity:
                stc
                sbb     eax, eax
                mov     [bx], eax
                mov     [bx+4], eax
                mov     [bx+10], eax
                mov     [bx+14], eax
                mov     ah, 3Fh
                mov     [bx+8], ax
                mov     [bx+18], ax
                mov     ax, 3           ; флаг CF=1 (из-за SBB - см. выше)
@@exit:
                ret
@@next_0:
                cmp     [si+10], eax
                jne     @@next_1        ; переход, если верхняя граница <> 0
                cmp     [si+14], eax
                je      @@infinity
@@next_1:
                mov     ax, [si+8]
                xor     ax, [si+18]
                js      @@infinity      ; выход, если 0 содержится в делителе
                mov     di, offset i_buff
                mov     si, bx
                mov     cx, 5
                rep     movsd           ; сохраним ST(1)
                push    bx
                push    dx
                call    n_div           ; ST(1).low = ST(1).low / ST(0).low
                pop     dx
                pop     bx
                push    bx
                add     bx, 10
                add     dx, 10
                push    dx
                call    n_div           ; ST(1).high = ST(1).high / ST(0).high
                pop     dx
                mov     bx, offset i_buff
                push    dx
                call    n_div           ; [BX].low = ST(1).low / ST(0).high
                pop     dx
                sub     dx, 10
                mov     bx, offset i_buff+10
                call    n_div           ; [BX].high = ST(1).high / ST(0).low
                pop     dx              ; DX - указывает на ST(1).low
                mov     si, offset i_buff
                mov     di, dx
                call    compare
                jb      @@cont_0        ; переход, если ST(1).low меньше
                call    md_change
@@cont_0:
                add     si, 10
                call    compare
                jb      @@cont_1        ; переход, если ST(1).low меньше
                call    md_change
@@cont_1:
                lea     si, [di+10]     ; SI - ST(1).high
                call    compare
                jb      @@cont_2        ; переход, если ST(1).low меньше
                call    md_change
@@cont_2:
                mov     di, si          ; DI - ST(1).high
                mov     si, offset i_buff
                call    compare
                jae     @@cont_3        ; переход, если ST(1).high больше
                call    md_change
@@cont_3:
                add     si, 10
                call    compare
                jae     @@cont_4        ; переход, если ST(1).high больше
                call    md_change
@@cont_4:
                jmp     majorise        ; мажоризация
i_div           ENDP



                PUBLIC  im_div
im_div          PROC; Деление интервалов
; Вход: ST(0) - делимое, BX - указатель на делитель
; Выход: если CF=0, то ST(0) = ST(0)/[BX], иначе AX = код ошибки
                mov     ax, 1
                cmp     stk_amount, ax
                jb      exit            ; выход, если стек пуст
                mov     dx, bx
                movzx   bx, stk_top     ; BX будет указывать на ST(0).low
                lea     bx, [ebx+4*ebx] ; умножить BX на 5
                shl     bx, 2           ; каждый интервал занимает 20 байт
                add     bx, offset internal_stack
                jmp     i_div_main
im_div          ENDP



                PUBLIC  i_inverse
i_inverse       PROC; Обратная величина
; Вход: ST(0) - X
; Выход: если CF=0, то ST(0) - 1/X, иначе AX = код ошибки
                mov     ax, 1
                cmp     stk_amount, ax
                jb      exit            ; выход, если нет аргументов
                mov     dx, bx
                call    get_top         ; BX - указатель на вершину стека
                xor     eax, eax
                cmp     [bx], eax
                jne     @@next_0        ; переход, если нижняя граница <> 0
                cmp     [bx+4], eax
                jne     @@next_0
@@infinity:
                stc
                sbb     eax, eax
                mov     [bx], eax
                mov     [bx+4], eax
                mov     [bx+10], eax
                mov     [bx+14], eax
                mov     ah, 3Fh
                mov     [bx+8], ax
                mov     [bx+18], ax
                mov     ax, 3           ; флаг CF=1 (из-за SBB - см. выше)
@@exit:
                ret
@@next_0:
                cmp     [bx+10], eax
                jne     @@next_1        ; переход, если верхняя граница <> 0
                cmp     [bx+14], eax
                je      @@infinity
@@next_1:
                mov     ax, [bx+8]
                xor     ax, [bx+18]
                js      @@infinity      ; выход, если 0 содержится в делителе
                mov     si, bx
                mov     di, offset i_buff
                mov     cx, 5
                rep     movsd
                dec     stk_top
                dec     stk_amount
                push    bx
                mov     bx, offset one
                call    load_num
                pop     bx
                mov     dx, offset i_buff+10
                push    bx
                call    n_div           ; ST(0).low = 1 / ST(0).high
                pop     bx
                add     bx, 10
                mov     dx, offset i_buff
                call    n_div           ; ST(0).high = 1 / ST(0).low
                jmp     majorise        ; мажоризация
i_inverse       ENDP



                PUBLIC  i_power_n
i_power_n       PROC; Возведение интервала в натуральную степень (или в 0)
; Вход: ST(0) - X, AX - n
; Выход: если CF=0, то ST(0) = X^n, иначе AX = код ошибки
                mov     cx, ax
                mov     ax, 1
                cmp     stk_amount, ax
                jb      @@exit          ; выход, если стек пуст
                cld
                movzx   bx, stk_top
                lea     bx, [ebx+4*ebx]
                shl     bx, 2           ; умножили BX на 20
                add     bx, offset internal_stack
                jcxz    @@put_one
                mov     ax, cx
                mov     cx, [bx+8]
                xor     cx, [bx+18]
                push    cx              ; сохраним знаки
                call    @@power_it      ; возведем нижнюю границу в степень AX
                add     bx, 10
                call    @@power_it      ; то же с верхней границей
                pop     dx
                test    al, 1
                jnz     @@end           ; выход, если степень нечетная
                lea     di, [bx-10]
                mov     si, bx
                call    compare_abs
                jb      @@cont_0
                call    md_change       ; нижняя граница больше верхней
@@cont_0:
                and     dx, dx
                jns     @@end           ; выход, если нет нуля
                xor     eax, eax
                stosd
                stosd
                stosw                   ; нижняя граница - ноль
@@end:
                jmp     majorise        ; мажоризация
@@put_one:
                mov     si, offset one
                mov     di, bx
                mov     cx, 5
                push    cx
                push    si
                rep     movsw
                pop     si
                pop     cx
                rep     movsw
                clc
@@exit:
                ret
@@power_it:
                push    bx
                push    ax
                dec     ax
                jz      @@cancel
                mov     di, offset i_buff
                mov     dx, di
                mov     si, bx
                mov     cx, 5
                push    cx
                rep     movsw
                pop     cx
                mov     di, bx
                mov     si, offset one
                rep     movsw
                mov     cx, ax
                inc     cx
@@loop:
                push    bx
                shr     cx, 1
                jnb     @@cont_1
                push    dx
                push    cx
                call    n_mul
                pop     cx
                pop     dx
@@cont_1:
                jcxz    @@stop
                push    cx
                push    dx
                mov     bx, dx
                call    n_mul
                pop     dx
                pop     cx
                pop     bx
                jmp     @@loop
@@stop:
                pop     bx
@@cancel:
                pop     ax
                pop     bx
                ret
i_power_n       ENDP



                PUBLIC  factorial
factorial       PROC; Заносит на стек N! (N факториал)
; Вход: AX = N
; Выход: если CF=0, то ST(0) = N!, иначе AX = код ошибки
                cmp     stk_amount, 100h
                jb      @@cont_0
@@overflow:
                mov     ax, 2           ; переполнение стека
                stc
                ret
@@cont_0:
                cmp     ax, 22          ; 21! самое большое точное число
                jae     @@large         ; если больше, то результат неточен
                cmp     ax, 8           ; 7! = 5040, 8! = 40320 > 32767
                jae     @@medium
                mov     cx, ax
                test    ax, ax
                jnz     @@loop_0
                inc     ax              ; 0! = 1
                jmp     load_int
@@loop_0:
                dec     cx
                jz      load_int        ; если конец, то результат на стек
                mul     cx
                jmp     @@loop_0
@@medium:
                sub     ax, 7
                push    ax
                mov     ax, 5040        ; AX = 7!
                call    load_int
                mov     bx, offset i_buff
                call    i_store         ; сохраним в буфере
                pop     cx              ; CX - количество циклов
                mov     ax, 8
@@loop_1:
                push    cx
                push    ax
                call    load_int        ; очередное число на стек
                mov     bx, offset i_buff
                movzx   dx, stk_top
                lea     dx, [edx+4*edx]
                shl     dx, 2           ; DX = DX*20
                add     dx, offset internal_stack
                call    n_mul           ; умножаем ЧИСЛА
                dec     stk_top         ; "снимаем" число со стека
                dec     stk_amount
                pop     ax
                pop     cx
                inc     ax              ; следующее число
                loop    @@loop_1
@@end:
                mov     bx, offset i_buff
                jmp     load_num        ; поместим результат на стек
@@large:
                cmp     stk_amount, 0FFh; необходимо место в стеке
                jnb     @@overflow
                mov     bx, offset fact21
                sub     ax, 21
                push    ax
                call    load_num        ; занесем 21! на стек
                pop     cx              ; CX - число итераций
                mov     ax, 22
@@loop_2:
                push    cx
                push    ax
                call    cm_mul          ; умножить ST(0) на AX
                jb      @@error         ; если произошла ошибка - выход
                pop     ax
                pop     cx
                inc     ax
                loop    @@loop_2
                ret
@@error:
                pop     cx
                pop     cx              ; очистить стек
                ret
factorial       ENDP



                PUBLIC  exponential
exponential     PROC; Функция exp(x) = e^x
; Вход: ST(0) - x
; Выход: ST(0) - exp(x)
                mov     ax, 1
                cmp     stk_amount, ax
                jb      exit            ; выход, если стек пуст
                mov     bx, offset i_buff+40
                push    bx
                call    i_store         ; сохранили X в буфере
                pop     bx
                call    load_num        ; поместили на стек нижнюю границу
                call    @@exp_main      ; вычислили e^НГ
                mov     bx, offset i_buff+60
                push    bx
                call    i_store         ; сохранили результат
                mov     bx, offset i_buff+50
                call    load_num        ; поместили на стек верхнюю границу
                call    @@exp_main      ; вычислили e^ВГ
                pop     bx
                jmp     im_hull         ; интервальное объединение и конец

X               EQU     offset i_buff+80; адрес переменной X
IntegerPart     EQU     offset i_buff+90; хранит exp([x])
Sum             EQU     offset i_buff+110;частичная сумма
Xn              EQU     offset i_buff+130;хранит X^n/n!
@@exp_main:
                mov     bx, X
                push    bx
                call    i_store         ; сохранили X
                mov     bx, offset e
                call    load_num        ; e на стек
                call    majorise
                pop     bx
                call    get_int         ; в AX - целая часть X, осталась дробная часть
                jc      @@overflow      ; X >= 65536
                call    i_power_n       ; exp([x])
                jc      @@overflow2
                xor     dx, dx
                test    byte ptr X+9, 80h
                jz      @@cont_0
                call    i_inverse       ; если x<0, надо 1/exp(|x|)
                mov     dx, 1           ; в DX знак числа
                and     byte ptr X+9, 7Fh
@@cont_0:
                push    dx
                mov     bx, IntegerPart
                call    i_store         ; сохранили e^[x]
                mov     di, Sum         ; запишем 1 в частичную сумму
                mov     si, offset one  ; это будет нулевой член ряда Тейлора
                mov     cx, 5
                push    si
                push    cx
                rep     movsw
                pop     cx
                pop     si
                push    si
                push    cx
                rep     movsw
                pop     cx
                pop     si
                push    si              ; запишем также 1 в Xn
                push    cx
                rep     movsw
                pop     cx
                pop     si
                rep     movsw
                cmp     word ptr X+8, cx
                je      @@cancel
                mov     ax, 1           ; сумма ряда Тейлора от 0 до 17
@@loop:                                 ; погрешность порядка 1E-16
                push    ax
                mov     bx, X
                call    load_num        ; ST(0) = x
                pop     ax
                push    ax
                call    cm_div          ; ST(0) = x/n
                mov     bx, Xn
                push    bx
                call    im_mul          ; ST(0) = X^(n+1)/(n+1)!
                pop     bx
                call    i_store         ; сохраним новый член ряда
                inc     stk_top
                inc     stk_amount      ; 'восстановим' его на стеке
                call    get_top
                mov     ax, [bx+18]
                mov     bx, Sum
                mov     cx, [bx+8]
                shl     ax, 1
                shl     cx, 1
                sub     cx, ax          ; CX = expSum - expX
                push    cx
                push    bx
                call    im_add          ; ST(0) = Sum+X^(n+1)/(n+1)!
                pop     bx
                call    i_store         ; сохранили частичную сумму
                pop     cx
                pop     ax
                inc     ax
                cmp     cx, 20h
                jl      @@loop
@@cancel:
                mov     bx, Sum
                call    i_load          ; восстановили частичную сумму
                pop     dx              ; восстановили знак x
                dec     dx
                jnz     @@cont_1
                call    i_inverse       ; если x<0, то e^x = 1/e^|x|
@@cont_1:
                mov     bx, IntegerPart ; ST(0) = e^{x}
                jmp     im_mul          ; ST(0) = e^[x]*e^{x} = e^x
@@overflow2:
                dec     stk_top
                dec     stk_amount
@@overflow:
                mov     bx, offset MMN  ; НБЧ
                test    byte ptr X+9, 80h
                jz      @@cont_2
                mov     bx, offset MNN  ; НМЧ
@@cont_2:
                call    load_num
                jmp     majorise
exponential     ENDP



                PUBLIC  logarithm
logarithm       PROC; Функция ln(x) - натуральный логарифм
; Вход: ST(0) - x
; Выход: ST(0) - ln(x)
                mov     ax, 1
                cmp     stk_amount, ax
                jb      exit            ; выход, если стек пуст
                mov     bx, offset i_buff+40
                push    bx
                call    i_store         ; сохранили X в буфере
                pop     bx
                mov     di, bx
                mov     si, offset null
                call    compare
                mov     ax, 5
                jb      exit
                je      @@n_inf
                call    load_num        ; поместили на стек нижнюю границу
                call    @@log_main      ; вычислили ln(НГ)
                jmp     @@cont_0
@@n_inf:
                mov     bx, offset n_inf; логарифм нуля - минус бесконечность
                call    load_num
@@cont_0:
                mov     bx, offset i_buff+60
                push    bx
                call    i_store         ; сохранили результат
                mov     bx, offset i_buff+50
                mov     di, bx
                mov     si, offset null
                call    compare
                je      @@inf
                call    load_num        ; поместили на стек верхнюю границу
                call    @@log_main      ; вычислили ln(ВГ)
                jmp     @@cont_1
@@inf:
                mov     bx, offset n_inf; логарифм нуля - минус бесконечность
                call    load_num
@@cont_1:
                pop     bx
                call    im_hull         ; интервальное объединение
                jmp     majorise        ; мажоризация и конец

X               EQU     offset i_buff+80; адрес переменной X
ConstPart       EQU     offset i_buff+100;хранит exp*ln(10)+ln(a)
Summ            EQU     offset i_buff+120;частичная сумма
X_n             EQU     offset i_buff+140;хранит X^n
@@log_main:
                call    cmp_inf
                je      exit            ; ln(inf) = inf
                mov     bx, X
                push    bx
                call    i_store         ; сохранили x
                mov     bx, offset ln10
                call    load_num        ; ST(0) = ln(10)
                call    majorise        ; мажоризация
                mov     bx, ConstPart
                call    i_store
                pop     bx              ; BX - x
                mov     ax, [bx+8]
                shl     ax, 1
                bt      ax, 15
                rcr     ax, 1           ; AX - экспонента x (exp)
                xor     cx, cx
                mov     [bx+8], cx
                mov     [bx+18], cx     ; вместо x его мантисса
                inc     stk_top
                inc     stk_amount      ; ST(0) = ln(10)
                call    cm_mul          ; ST(0) = exp*ln(10)
                mov     bx, ConstPart
                call    i_store
                mov     bx, X
                movzx   ax, [bx+7]
                shr     ax, 4           ; AX - первая цифра мантиссы x (a)
                mov     bx, ax
                dec     bx
                push    ax
                lea     bx, [ebx+4*ebx]
                shl     bx, 1           ; BX = (AX-1)*10
                add     bx, offset ln1  ; BX указывает на ln(a)
                inc     stk_top
                inc     stk_amount      ; ST(0) = exp*ln(10)
                call    c_add           ; ST(0) = exp*ln(10)+ln(a)
                mov     bx, ConstPart
                call    i_store
                pop     ax
                call    load_int        ; ST(0) = a (первая цифра мантиссы x)
                mov     bx, X
                push    bx
                call    im_div          ; ST(0) = a/m (лежит в ]0.5, 1])
                call    i_negative      ; ST(0) = -a/m
                mov     bx, offset one
                call    c_add           ; ST(0) = 1-a/m
                pop     bx
                call    i_store
                xor     eax, eax
                mov     di, Summ
                mov     cx, 5
                rep     stosd           ; частичная сумма = 0
                mov     di, X_n         ; запишем 1 в X_n (X^0)
                mov     si, offset one
                mov     cx, 5
                push    si
                push    cx
                rep     movsw
                pop     cx
                pop     si
                rep     movsw
                cmp     word ptr X+8, cx
                je      @@cancel
                mov     ax, 1           ; сумма ряда Тейлора от 1 до 50
@@loop:
                push    ax
                mov     bx, X
                call    i_load          ; ST(0) = X
                mov     bx, X_n
                push    bx
                call    im_mul          ; ST(0) = X^(n+1)
                pop     bx
                call    i_store
                inc     stk_top
                inc     stk_amount      ; ST(0) = X^(n+1)
                pop     ax
                push    ax
                call    cm_div          ; ST(0) = X^(n+1)/(n+1)
                call    get_top
                mov     ax, [bx+18]
                mov     bx, Summ
                mov     cx, [bx+8]
                shl     ax, 1
                shl     cx, 1
                sub     cx, ax
                push    cx              ; CX = expSumm - expX
                push    bx
                call    im_add          ; ST(0) = Summ+X^(n+1)/(n+1)
                pop     bx
                call    i_store         ; сохранили частичную сумму
                pop     cx
                pop     ax
                inc     ax
                cmp     cx, 20h
                jl      @@loop
@@cancel:
                mov     bx, Summ
                call    i_load          ; частичную сумму на стек
                mov     bx, ConstPart
                jmp     im_add          ; ST(0) = exp*ln(10)+ln(a)-ln(a/m)
logarithm       ENDP



                PUBLIC  sqrt
sqrt            PROC; Функция √x
; Вход: ST(0) - x
; Выход: ST(0) - √x
                mov     bx, offset i_buff
                push    bx
                call    i_store         ; поместим x в буфер
                pop     bx
                jc      @@exit
                push    bx
                call    load_num        ; поместили нижнюю границу на стек
                call    @@sqrt_main     ; ST(0) = √НГ
                pop     bx
                jnc     @@next
                call    @@error         ; обработать ошибку
@@next:
                add     bx, 10
                push    bx
                mov     bx, offset i_buff+20
                call    i_store
                pop     bx
                call    load_num        ; поместили верхнюю границу на стек
                call    @@sqrt_main     ; ST(0) = √ВГ
                jnc     @@end
                call    @@error         ; обработать ошибку
@@end:
                mov     bx, offset i_buff+20
                jmp     im_hull
@@error:
                cmp     ax, 3
                je      @@exit
                pop     bx              ; очистили стек
                stc
                ret
@@on_error:
                mov     ax, 5
@@stop1:
                stc
@@stop:
                inc     stk_top
                inc     stk_amount
@@exit:
                ret

X0              EQU     offset i_buff+40
Xk              EQU     offset i_buff+50
Xk1             EQU     offset i_buff+60
var             EQU     offset i_buff+70
@@sqrt_main:
                mov     bx, X0
                push    bx
                call    i_store         ; x - в буфер
                pop     si
                mov     ax, 3
                cmp     byte ptr [si], 0FFh
                je      @@stop1         ; √inf = inf
                xor     eax, eax
                cmp     [si], eax
                jne     @@cont_1
                cmp     [si+4], eax
                je      @@stop          ; √0 = 0
@@cont_1:
                mov     ax, [si+18]
                and     ax, ax
                js      @@on_error      ; если отрицательное число
                shl     ax, 1
                bt      ax, 15
                pushf
                rcr     ax, 1
                popf
                rcr     ax, 1           ; AX = exp/2
                and     ah, 7Fh
                mov     [si+18], ax     ; теперь в Xk начальное приближение
                xor     eax, eax        ; занесем в var 2
                mov     dword ptr var, eax
                mov     dword ptr var+4, 20000000h
                mov     word ptr var+8, ax
                mov     cx, 10h         ; CX - максимальное кол-во итераций
@@loop:
                push    cx
                mov     di, Xk1
                mov     bx, di
                mov     si, X0
                mov     cx, 5
                rep     movsw           ; xk1 = x
                mov     dx, Xk
                push    bx
                push    dx
                call    n_div           ; xk1 = x/xk
                pop     dx
                pop     bx
                push    bx
                call    n_add           ; xk1 = xk+x/xk
                pop     bx
                mov     dx, offset var
                push    bx
                call    n_div           ; xk1 = (xk+x/xk)/2
                pop     si
                mov     di, offset Xk
                call    compare_abs     ; сравнить xk и xk1
                pushf
                mov     cx, 5
                rep     movsw           ; xk = xk1
                popf
                pop     cx
                je      @@cancel        ; выход, если xk=xk1
                loop    @@loop
@@cancel:
                mov     bx, offset Xk
                call    load_num        ; результат на стек
                jmp     majorise        ; мажоризация
sqrt            ENDP



                PUBLIC  get_int
get_int         PROC; Выделяет целую часть числа
; Вход: BX - указатель на число (10 байт)
; Выход: AX - целая часть (модуль), [BX] - дробная часть (знак сохраняется)
                xor     esi, esi
                mov     ax, [bx+8]
                shl     ax, 1
                js      @@exit          ; если экспонента отрицательна
                cmp     ax, 8           ; exp =< 4 , иначе не поместится в AX
                ja      @@overflow
                shr     ax, 1
                xor     ecx, ecx
                mov     cx, ax
                xor     edx, edx
                inc     dx
                jcxz    @@cont_0
@@loop_0:
                lea     dx, [edx+4*edx]
                shl     dx, 1           ; DX = DX*10
                loop    @@loop_0
@@cont_0:
                push    ax
                mov     di, ax
                mov     eax, edx
                mov     cl, [bx+7]
                shr     cl, 4
                imul    ecx, eax
                add     esi, ecx
                xor     dx, dx
                mov     cx, 000Ah
                div     cx
                dec     di
                js      @@cancel
                mov     cl, [bx+7]
                and     cl, 0Fh
                imul    ecx, eax
                add     esi, ecx
                mov     cx, 000Ah
                div     cx
                dec     di
                js      @@cancel
                mov     cl, [bx+6]
                shr     cl, 4
                imul    ecx, eax
                add     esi, ecx
                mov     cx, 000Ah
                div     cx
                dec     di
                js      @@cancel
                mov     cl, [bx+6]
                and     cl, 0Fh
                imul    ecx, eax
                add     esi, ecx
                mov     cx, 000Ah
                div     cx
                dec     di
                js      @@cancel
                mov     cl, [bx+5]
                shr     cl, 4
                imul    ecx, eax
                add     esi, ecx
@@cancel:
                pop     cx
                inc     cx
                cmp     esi, 10000h
                jae     @@overflow
                shl     cl, 2
                mov     eax, [bx]
                shld    [bx+4], eax, cl
                shl     dword ptr [bx], cl
                xor     eax, eax
                cmp     [bx], eax
                jnz     @@cont_1
                cmp     [bx+4], eax
                jz      @@cont_2
@@cont_1:
                mov     ax, 7FFFh       ; AX = -1
@@cont_2:
                and     word ptr [bx+8], 8000h
                or      [bx+8], ax
@@exit:
                mov     ax, si
                clc
                ret
@@overflow:
                stc
                ret
get_int         ENDP



                PUBLIC  val_func
val_func        PROC; Преобразует число из символьной формы в экспоненциальную
; SI - указатель на ASCII строку (в конце 00h), BX - указатель на 10 байт
                mov     eax, [si]
                cmp     eax, 00666E69h
                jne     @@cont_1
@@p_inf:
                mov     word ptr [bx+8], 3FFFh
                jmp     @@cont_0
@@n_inf:
                mov     word ptr [bx+8], 0BFFFh
@@cont_0:
                stc
                sbb     eax, eax
                mov     [bx], eax
                mov     [bx+4], eax
                jmp     @@exit
@@p_pi:
                xor     ax, ax
                jmp     @@pi
@@n_pi:
                mov     ax, 8000h
@@pi:
                mov     [bx+8], ax
                mov     eax, dword ptr [pi]
                mov     [bx], eax
                mov     eax, dword ptr [pi+4]
                mov     [bx+4], eax
                jmp     @@exit
@@cont_1:
                cmp     eax, 666E692Bh
                je      @@p_inf
                cmp     eax, 666E692Dh
                je      @@n_inf
                cmp     eax, 0069702Bh
                je      @@p_pi
                cmp     eax, 0069702Dh
                je      @@n_pi
                cmp     ax, 6970h
                je      @@p_pi
                xor     eax, eax
                mov     [bx], eax
                mov     [bx+4], eax
                mov     [bx+8], ax
                mov     c_digit, 15     ; текущая цифра
                mov     sign, al        ; знак по умолчанию
                mov     sign_e, al
                mov     inc_m, al       ; необходимо ли увеличить мантиссу
                xor     ecx, ecx        ; ECX - текущая экспонента
                xor     edx, edx        ; EDX - дополнительная экспонента
                lodsb
                cmp     al, '+'
                je      @@next
                cmp     al, '-'
                jne     @@pass
                mov     sign, 80h
@@next:
                lodsb
@@pass:
                cmp     al, 30h
                je      @@next
                cmp     al, '.'
                jne     @@more_1
                cmp     byte ptr [si], 00h
                je      @@error
                cmp     byte ptr [si], 'e'
                je      @@error
@@loop_0:
                dec     ecx
                lodsb
                cmp     al, 30h
                je      @@loop_0
                and     al, al
                jz      @@exit
                cmp     al, 'e'
                jne     @@loop_1
@@verify1:
                cmp     byte ptr [si], 00h
                je      @@error
@@verify:
                lodsb
                and     al, al
                jz      @@exit
                cmp     al, 30h
                jb      @@error
                cmp     al, 3Ah
                jb      @@verify
                cmp     al, '+'
                je      @@ext_verify
                cmp     al, '-'
                jne     @@error
@@ext_verify:
                cmp     byte ptr [si-2], 'e'
                je      @@verify
                jmp     @@error
@@fractal:
                lodsb
                and     al, al
                jz      @@error
@@loop_1:
                cmp     al, 30h
                jb      @@cont_2
                cmp     al, 3Ah
                jae     @@cont_2
                sub     al, 30h
                call    @@store_digit
                lodsb
                jnc     @@loop_1
                cmp     al, 30h
                jb      @@cont_2
                cmp     al, 3Ah
                jae     @@cont_2
                cmp     al, 35h
                cmc
                adc     inc_m, 0
@@loop:
                lodsb
                cmp     al, 30h
                jb      @@cont_2
                cmp     al, 3Ah
                jb      @@loop
@@cont_2:
                and     al, al
                jz      @@positive
                cmp     al, 'e'
                jne     @@error
@@exp1:
                cmp     byte ptr [si], 00h
                je      @@error
@@exponent:
                mov     di, bx
                xor     bx, bx
                lodsb
                cmp     al, '+'
                je      @@next_e
                cmp     al, '-'
                jne     @@pass_e
                mov     sign_e, 80h
                jmp     @@next_e
@@pass_e:
                dec     si
@@next_e:
                mov     al, [bx][si]
                inc     bx
                cmp     al, 30h
                jb      @@cont_3
                cmp     al, 3Ah
                jb      @@next_e
@@cont_3:
                and     al, al
                jnz     @@error
                dec     bx
                dec     bx
                js      @@cont_e
                push    di
                mov     edi, 1
@@loop_e:
                mov     al, [bx][si]
                dec     bx
                sub     al, 30h
                jb      @@cont_4
                cmp     al, 0Ah
                jae     @@cont_4
                cbw
                cwde
                imul    eax, edi
                jc      @@error_pop
                add     edx, eax
                jc      @@error_pop
                imul    edi, 0Ah
                jnc     @@loop_e
@@error_pop:
                pop     bx
@@error:
                stc
                ret
@@cont_4:
                pop     bx
@@cont_e:
                test    sign_e, 0FFh
                jz      @@positive
                neg     edx
@@positive:
                add     ecx, edx
                cmp     ecx, 3FFFh
                jg      @@error
                cmp     ecx, -4000h
                jl      @@error
                and     cx, 7FFFh
                or      ch, sign
                mov     [bx+8], cx
                test    inc_m, 0FFh
                jz      @@exit
                call    inc_man
@@exit:
                clc
                ret
@@more_1:
                and     al, al
                jz      @@exit
                cmp     al, 'e'
                je      @@verify1
                jmp     @@pass_2
@@loop_2:
                lodsb
@@pass_2:
                cmp     al, 30h
                jb      @@cont_5
                cmp     al, 3Ah
                jae     @@cont_5
                inc     ecx
                sub     al, 30h
                call    @@store_digit
                jnc     @@loop_2
                lodsb
                cmp     al, 30h
                jb      @@cont_5
                cmp     al, 3Ah
                jae     @@cont_5
                inc     ecx
                cmp     al, 35h
                cmc
                adc     inc_m, 0
@@loop_3:
                lodsb
                cmp     al, 30h
                jb      @@cont_6
                cmp     al, 3Ah
                jae     @@cont_6
                inc     ecx
                jmp     @@loop_3
@@cont_5:
                dec     ecx
                js      @@error
                cmp     al, '.'
                je      @@fractal
                inc     ecx
@@cont_6:
                dec     ecx
                js      @@error
                cmp     al, 'e'
                je      @@exp1
                and     al, al
                jz      @@positive
                jmp     @@error
@@store_digit:
                push    si
                mov     si, c_digit
                test    si, 1
                je      @@even
                shl     al, 4
@@even:
                shr     si, 1
                or      [bx][si], al
                pop     si
                sub     c_digit, 1
                ret
val_func        ENDP



                PUBLIC  asc_func
asc_func        PROC; Переводит число в символьную форму
; BX - указатель на число, DI - указатель на 25 байт для строки ASCII
                cmp     byte ptr [bx], 0FFh
                jne     @@non_inf
                xor     al, al
                bt      word ptr [bx+8], 15
                rcl     al, 2
                add     al, '+'
                stosb
                mov     si, offset infinity
                mov     cx, 24
                rep     movsb
                ret
@@non_inf:
                mov     al, [bx+9]
                and     al, 80h
                shr     al, 6
                add     al, '+'
                stosb
                mov     al, [bx+7]
                push    ax
                shr     al, 4
                add     al, 30h
                stosb
                mov     al, '.'
                stosb
                pop     ax
                and     al, 0Fh
                add     al, 30h
                stosb
                mov     si, 6
@@loop:
                mov     al, [bx][si]
                push    ax
                shr     al, 4
                add     al, 30h
                stosb
                pop     ax
                and     al, 0Fh
                add     al, 30h
                stosb
                dec     si
                jns     @@loop
                mov     al, 'e'
                stosb
                mov     cx, [bx+8]
                shl     cx, 1
                bt      cx, 15
                rcr     cx, 1
                mov     al, '+'
                jns     @@cont
                mov     al, '-'
                neg     cx
@@cont:
                stosb
                mov     ax, cx
                mov     cl, 30h
                cwd
                mov     bx, 000Ah
                div     bx
                add     dl, cl
                mov     [di+4], dl
                cwd
                div     bx
                add     dl, cl
                mov     [di+3], dl
                cwd
                div     bx
                add     dl, cl
                mov     [di+2], dl
                cwd
                div     bx
                add     dl, cl
                mov     [di+1], dl
                add     al, cl
                stosb
                ret
asc_func        ENDP



                PUBLIC  load_num
load_num        PROC; Загружает вещественное число на стек
; BX - ближний указатель на число (10 байт)
                cmp     stk_amount, 100h
                jb      @@continue
                mov     ax, 2           ; переполнение стека
                stc
                ret
@@continue:
                inc     stk_amount
                inc     stk_top
                movzx   di, stk_top
                imul    di, 20
                add     di, offset internal_stack
                mov     si, bx
                cld                     ; направление - прямое
                push    si
                mov     cx, 5
                rep     movsw
                pop     si
                mov     cx, 5
                rep     movsw
                clc                     ; нет ошибок
                ret
load_num        ENDP



                PUBLIC  load_int
load_int        PROC; Эагружает целое число -32768..+32767 на стек
; AX - число
                cmp     stk_amount, 100h
                jb      @@continue
                mov     ax, 2           ; переполнение стека
                stc
                ret
@@continue:
                inc     stk_amount
                inc     stk_top
                movzx   di, stk_top
                imul    di, 20
                add     di, offset internal_stack
                mov     bx, ax
                and     ah, 80h
                mov     [di+9], ah      ; знак
                jz      @@positive
                neg     bx
@@positive:
                mov     ax, bx
                xor     ebx, ebx        ; в EBX будет мантисса в BCD
                xor     cx, cx          ; CL - порядок числа
                mov     si, 000Ah
                cmp     ax, si
                jnb     @@cont0
                mov     bl, al
                jmp     @@cancel
@@cont0:
                inc     cl
                cwd
                div     si
                mov     bl, dl
                cmp     ax, si
                jnb     @@cont1
                shl     al, 4
                or      bl, al
                jmp     @@cancel
@@cont1:
                inc     cl
                cwd
                div     si
                shl     dl, 4
                or      bl, dl
                cmp     ax, si
                jnb     @@cont2
                mov     bh, al
                jmp     @@cancel
@@cont2:
                inc     cl
                cwd
                div     si
                mov     bh, dl
                cmp     ax, si
                jnb     @@cont3
                shl     al, 4
                or      bh, al
                jmp     @@cancel
@@cont3:
                inc     cl
                cwd
                div     si
                shl     dl, 4
                or      bh, dl
                shl     ebx, 16
                mov     bl, al
                rol     ebx, 16
@@cancel:
                mov     [di+8], cl      ; экспонента
                mov     si, di
                xor     eax, eax
                cld                     ; направление - прямое
                stosd
                bsr     ecx, ebx
                neg     cl
                add     cl, 1Fh
                and     cl, 0FCh
                shl     ebx, cl
                mov     eax, ebx
                stosd                   ; записали мантиссу
                inc     di
                inc     di
                mov     cx, 5
                rep     movsw
                clc                     ; ошибок нет
                ret
load_int        ENDP



                PUBLIC  n_add
n_add           PROC; Складывает 2 числа
; BX - указатель на Num1, DX - на Num2, результат - в Num1
                mov     si, dx
                mov     di, offset muldiv_buffer
                push    di
                mov     cx, 5
                rep     movsw
                pop     si
                mov     di, bx
                call    compare_abs
                jnc     @@cont_0
                call    md_change       ; если |Num2| > |Num1|, поменять их
@@cont_0:
                mov     cx, [di+8]      ; приведем Num2 к экспоненте от Num1
                mov     ax, [si+8]      ; для этого сдвинем его мантиссу
                shl     cx, 1           ;                на нужное число цифр
                shl     ax, 1
                sub     cx, ax          ; CX = (Exp(Num1)-Exp(Num2))*2
                shr     cx, 1
                xor     edx, edx        ; EDX - непоместившиеся младшие цифры
                mov     eax, [si]       ; EAX - младшие цифры
                mov     ebx, [si+4]     ; EBX - старшие цифры
                cmp     cx, 08h
                jb      @@cont_2
                cmp     cx, 10h
                jb      @@cont_1
                jne     @@pass
                mov     edx, ebx
@@pass:
                xor     eax, eax        ; если разница более 16 порядков, то
                xor     ebx, ebx        ;   сдвиг должен привести к обнулению
                jmp     @@cont_3
@@cont_1:
                sub     cl, 08h
                mov     edx, eax
                mov     eax, ebx
                xor     ebx, ebx
@@cont_2:
                shl     cl, 2           ; 1 цифра = 4 бита
                shrd    edx, eax, cl
                shrd    eax, ebx, cl
                shr     ebx, cl
@@cont_3:
                mov     [si], eax
                mov     [si+4], ebx
                shr     edx, 28
                cmp     dl, 05h         ; DL - старшая непоместившаяся цифра
                jb      @@cont_4
                mov     bx, si          ; округлим Num2
                call    inc_man
@@cont_4:
                mov     ax, [si+8]
                xor     ax, [di+8]
                test    ah, 80h
                jnz     @@sub
                mov     cx, 08h         ; знаки Num1 и Num2 совпали
                clc
@@loop_0:
                lodsb
                adc     al, [di]
                daa
                stosb
                loop    @@loop_0
                jnc     @@exit
                mov     dl, [di-8]
                mov     eax, [di-4]
                shrd    [di-8], eax, 4
                shr     dword ptr [di-4], 4
                mov     ax, [di]
                shl     ax, 1
                bt      ax, 15
                rcr     ax, 1
                cmp     ax, 3FFFh
                jl      @@non_inf
                stc
                sbb     eax, eax
                mov     [di-8], eax
                mov     [di-4], eax
                ret
@@non_inf:
                or      byte ptr [di-1], 10h
                inc     ax
                xor     ax, [di]
                and     ah, 7Fh
                xor     ax, [di]
                stosw
                lea     bx, [di-0Ah]
                cmp     dl, 05h
                jb      @@exit
                jmp     inc_man
@@sub:
                mov     cx, 08h         ; знаки Num1 и Num2 различны
                clc
@@loop_1:
                mov     al, [di]
                sbb     al, [si]
                das
                inc     si
                stosb
                loop    @@loop_1
@@repeat:
                test    al, 0F0h        ; нормализуем (старшая цифра не 0)
                jnz     @@cont_5
                mov     eax, [di-8]
                shld    [di-4], eax, 4
                shl     dword ptr [di-8], 4
                mov     al, [di-1]
                inc     cl
                cmp     cl, 10h
                jb      @@repeat
                mov     ax, [di]        ; результат - 0 => экспонента - +-0
                and     ax, 8000h
                stosw
                ret
@@cont_5:
                jcxz    @@exit
                mov     ax, [di]
                shl     ax, 1
                bt      ax, 15
                rcr     ax, 1
                sub     ax, cx
                cmp     ax, -4000h
                jnl     @@non_zero
                xor     eax, eax        ; запишем минимальное число: 1E-16384
                mov     [di-8], eax
                mov     [di-4], eax
                mov     byte ptr [di-1], 10h
                mov     ax, -4000h
@@non_zero:
                xor     ax, [di]
                and     ah, 7Fh
                xor     ax, [di]
                stosw
@@exit:
                ret
n_add           ENDP



                PUBLIC  n_sub
n_sub           PROC
                mov     si, dx
                xor     byte ptr [si+9], 80h
                push    si
                call    n_add
                pop     si
                xor     byte ptr [si+9], 80h
                ret
n_sub           ENDP



                PUBLIC  n_mul
n_mul           PROC; Умножает два числа
; BX - указатель на Num1, DX - на Num2, результат - в Num1
                mov     di, offset muldiv_buffer
                mov     cx, 11h
                xor     ax, ax
                rep     stosw           ; очистим буфер
                mov     di, bx
                mov     si, dx
                cmp     byte ptr [di], 0FFh
                jne     @@continue
@@infinity:
                stc                     ; одно из чисел - бесконечность
                sbb     eax, eax
                stosd
                stosd
                mov     ax, [si+8]
                xor     ax, [di]
                and     ax, 8000h
                or      ax, 3FFFh
                stosw
                ret
@@continue:
                cmp     byte ptr [si], 0FFh
                je      @@infinity
                xor     bx, bx          ; BX - счетчик цифр Num1
@@loop_0:
                xor     cl, cl
                shr     bx, 1
                mov     al, [di][bx]
                rcl     bx, 1
                test    bl, 1
                jz      @@cont_0
                shr     al, 4
                jmp     @@cont_1
@@cont_0:
                and     al, 0Fh
@@cont_1:
                jz      @@pass_0
                mov     ch, al          ; CH - текущая цифра из Num1
                xor     dx, dx          ; будем умножать ее на Num2
@@loop_1:
                xchg    bx, dx
                shr     bx, 1
                mov     al, [si][bx]
                rcl     bx, 1
                xchg    bx, dx
                test    dl, 1
                jz      @@cont_2
                shr     al, 4
                jmp     @@cont_3
@@cont_2:
                and     al, 0Fh
@@cont_3:
                mul     ch
                aam
                add     al, cl
                aaa
                push    bx
                add     bx, dx
                add     al, [bx+offset muldiv_buffer]
                aaa
                mov     [bx+offset muldiv_buffer], al
                mov     cl, ah
                pop     bx
                inc     dx
                cmp     dl, 10h
                jb      @@loop_1
                mov     [bx+offset muldiv_buffer+10h], cl
@@pass_0:
                inc     bx
                cmp     bl, 10h
                jb      @@loop_0
                mov     bx, offset muldiv_buffer+1Fh
                cmp     byte ptr [bx], 1
                pushf
                sbb     bx, 0
                add     di, 7
                mov     cx, 8
@@loop_2:
                mov     al, [bx]
                dec     bx
                shl     al, 4
                mov     [di], al
                mov     al, [bx]
                dec     bx
                or      [di], al
                dec     di
                loop    @@loop_2
                mov     ah, [si+9]      ; запишем знак
                and     ah, 80h
                xor     [di+10], ah
                xor     eax, eax
                cmp     [di+1], eax
                jne     @@cont_4
                cmp     [di+5], eax
                jne     @@cont_4
                popf
                mov     ax, [di+9]      ; если число - 0
                and     ax, 8000h
                mov     [di+9], ax
                ret
@@cont_4:
                mov     ax, [si+8]
                mov     cx, [di+9]
                shl     ax, 1
                bt      ax, 15
                rcr     ax, 1
                shl     cx, 1
                bt      cx, 15
                rcr     cx, 1
                popf
                cmc
                adc     ax, cx          ; AX - экспонента1+экспонента2+CF
                cmp     ax, 3FFFh
                jng     @@non_inf
                mov     ax, 3FFFh       ; запишем бесконечность
                xor     ax, [di+9]
                and     ah, 7Fh
                xor     [di+9], ax
                stc
                sbb     eax, eax
                inc     di
                stosd
                stosd
                ret
@@non_inf:
                cmp     ax, -4000h
                jnl     @@non_zero
                xor     eax, eax        ; запишем 1E-16384
                inc     di
                stosd
                stosd
                mov     byte ptr [di-1], 10h
                mov     ax, -4000h
                xor     ax, [di]
                and     ah, 7Fh
                xor     [di], ax
                ret
@@non_zero:
                xor     ax, [di+9]
                and     ah, 7Fh
                xor     [di+9], ax
                cmp     byte ptr [bx], 05h
                lea     bx, [di+1]
                jae     inc_man
                ret
n_mul           ENDP



                PUBLIC  n_div
n_div           PROC; Деление чисел
; BX - указатель Num1, DX - указатель Num2, результат в Num1
                mov     si, bx
                mov     di, offset muldiv_buffer
                call    @@depack_num
                mov     si, dx
                call    @@depack_num
                xor     eax, eax
                cmp     [si-8], eax
                jne     @@continue_0
                cmp     [si-4], eax
                jne     @@continue_0
@@inf:
                lodsw                   ; деление на 0
                xor     ax, [bx+8]
                and     ah, 80h
                or      ax, 3FFFh
                mov     [bx+8], ax
@@infinity:
                stc                     ; деление на малое число
                sbb     eax, eax        ; результат - +-бесконечность
                mov     [bx], eax
                mov     [bx+4], eax
                ret
@@very_small:
                xor     eax, eax        ; результат - +-1E-16384
                mov     [bx], eax
                mov     [bx+4], eax
                mov     byte ptr [bx+7], 10h
                mov     ax, -4000h
                xor     ax, [bx+8]
                and     ah, 7Fh
                xor     [bx+8], ax
@@exit:
                ret
@@continue_0:
                cmp     [bx], eax
                jne     @@pass
                cmp     [bx+4], eax
                je      @@exit
@@pass:
                cmp     byte ptr [si-8], 0FFh
                jne     @@continue_1
                mov     [bx], eax       ; деление на бесконечность
                mov     [bx+4], eax     ; результат - +-0
                lodsw
                xor     ax, [bx+8]
                and     ax, 8000h
                mov     [bx+8], ax
                ret
@@continue_1:
                cmp     byte ptr [bx], 0FFh
                je      @@inf           ; если делимое бесконечность...
                mov     cx, [bx+8]      ; вычислим экспоненту частного
                lodsw
                xor     [bx+8], ax
                shl     cx, 1
                bt      cx, 15
                rcr     cx, 1           ; CX - Exp1
                shl     ax, 1
                bt      ax, 15
                rcr     ax, 1           ; AX - Exp2
                sub     cx, ax
                cmp     cx, 3FFFh
                jg      @@infinity      ; если результат слишком велик...
                cmp     cx, -4000h
                jl      @@very_small    ; если слишком мал...
                xor     cx, [bx+8]
                and     ch, 7Fh
                xor     [bx+8], cx      ; записали экспоненту
                xor     eax, eax
                mov     [bx], eax       ; обнулим результат
                mov     [bx+4], eax
                mov     di, offset muldiv_buffer
                lea     si, [di+17]
                mov     dx, 10h         ; DX - номер текущей цифры результата
@@loop_1:
                xor     cl, cl          ; текущая цифра результата
                push    bx
@@loop_2:
                mov     bx, 10h
@@loop_3:
                mov     al, [di][bx]    ; сравниваем делимое (DI) и делитель
                cmp     al, [si][bx]
                ja      @@cont_0        ; если делимое больше, то продолжим
                jb      @@cancel        ; если больше делитель - цифра готова
                dec     bx
                jns     @@loop_3
@@cont_0:
                inc     cl              ; увеличим цифру
                xor     bx, bx
                pushf
@@loop_4:
                mov     al, [di][bx]
                popf
                sbb     al, [si][bx]    ; вычитаем из делимого делитель
                aas                     ; двоично-десятичная коррекция
                pushf
                mov     [di][bx], al
                inc     bx              ; следующая цифра
                cmp     bl, 11h
                jb      @@loop_4
                popf
                jmp     @@loop_2        ; продолжаем, пока делитель меньше
@@cancel:
                test    dl, 1           ; четная ли цифра?
                jnz     @@cont_1
                shl     cl, 4
                and     dx, dx
                jz      @@end           ; если цифра последняя, закончить
@@cont_1:
                cmp     dx, 10h
                jb      @@cont_2
                and     cl, cl
                jnz     @@cont_2
                pop     bx              ; первая цифра - 0
                mov     ax, [bx+8]      ; необходимо уменьшить экспоненту
                shl     ax, 1
                bt      ax, 15
                rcr     ax, 1
                dec     ax
                cmp     ax, -4000h
                jl      @@very_small
                xor     ax, [bx+8]
                and     ah, 7Fh
                xor     [bx+8], ax
                jmp     @@cont_3
@@cont_2:
                dec     dx
                mov     ax, dx
                shr     ax, 1
                mov     bx, ax
                pop     ax
                add     bx, ax          ; BX = ofs Num1 + (DX-1)/2
                or      [bx], cl        ; сохраним цифру результата
                mov     bx, ax
@@cont_3:
                mov     eax, [di+12]    ; сдвинем остаток делимого на 1 цифру,
                mov     [di+13], eax    ; т. е. умножим его на 10
                mov     eax, [di+8]
                mov     [di+9], eax
                mov     eax, [di+4]
                mov     [di+5], eax
                mov     eax, [di]
                mov     [di+1], eax
                mov     byte ptr [di], 0
                jmp     @@loop_1        ; ищем следующую цифру...
@@end:
                pop     bx              ; BX = ofs Num1
                cmp     cl, 50h
                jae     inc_man
                ret
@@depack_num:
                mov     cx, 8           ; записывает число в буфер
@@loop_0:                               ;           в неупакованной BCD форме
                lodsb
                push    ax
                and     al, 0Fh
                stosb
                pop     ax
                shr     al, 4
                stosb
                loop    @@loop_0
                xor     al, al          ; буфер для 17 цифр, последняя пока 0
                stosb
                ret
n_div           ENDP



                PUBLIC  cmp_inf
cmp_inf         PROC; Проверяет вершину стека на бесконечность
; Выход: ZF=1, если одна из границ ST(0) - бесконечность, иначе ZF=0
                movzx   bx, stk_top
                lea     bx, [ebx+4*ebx]
                shl     bx, 2
                add     bx, offset internal_stack
                cmp     byte ptr [bx], 0FFh
                je      @@exit
                cmp     byte ptr [bx+10], 0FFh
@@exit:
                ret
cmp_inf         ENDP



                PUBLIC  compare
compare         PROC; Сравнивает два числа
; DI - указатель Num1, SI - указатель Num2
; Выход: CF=1, если Num2 > Num1, иначе CF=0; Z=1, если Num1 = Num2
                mov     ax, [di+8]
                xor     ax, [si+8]
                js      @@differ_signs  ; если числа разных знаков, перейти
                call    compare_abs
                je      @@exit          ; если равны - на выход
                rcr     ax, 1           ; CF в 15 бит AX
                xor     ax, [di+8]      ; если знак минус, инвертировать
                or      ax, 1           ; чтобы в AX был не 0 (ZF=0)
                rcl     ax, 1           ; 15 бит в CF
@@exit:
                ret
@@differ_signs:
                mov     ax, [si+8]      ; AX = Num2
                cmp     ah, 80h         ; если Num2 > 0, то CF=1 (AX < 8000h)
                jne     @@exit
                and     ah, ah
                ret
compare         ENDP



                PUBLIC  compare_abs
compare_abs     PROC; Сравнивает модули чисел
; DI - указатель Num1, SI - указатель Num2
; Выход: CF=1, если Num2 > Num1, иначе CF=0; Z=1, если Num1 = Num2
                xor     eax, eax
                cmp     [si], eax
                jne     @@not_zero2
                cmp     [si+4], eax
                je      @@cont_1
@@not_zero2:
                cmp     [di], eax
                jne     @@not_zero1
                cmp     [di+4], eax
                je      @@to_stc        ; если Num2<>0, а Num1=0, то выход
@@not_zero1:
                mov     ax, [di+8]
                mov     cx, [si+8]
                shl     ax, 1
                shl     cx, 1
                cmp     ax, cx
                jnl     @@cont_0
                stc
                ret
@@cont_0:
                je      @@cont_1
                clc
                ret
@@to_stc:
                sub     al, 1
                ret
@@cont_1:
                mov     eax, [di+4]
                cmp     eax, [si+4]
                jne     @@exit
                mov     eax, [di]
                cmp     eax, [si]
@@exit:
                ret
compare_abs     ENDP



inc_man         PROC; Увеличивает мантиссу числа на младший разряд
; BX - указатель на число
                cmp     byte ptr [bx], 0FFh
                je      @@exit
                mov     cx, 8           ; флаг CF=1 (из-за CMP)
@@loop:
                mov     al, [bx]
                adc     al, 0
                daa
                mov     [bx], al
                inc     bx
                loop    @@loop
                jnc     @@exit
                mov     eax, [bx-4]
                shrd    [bx-8], eax, 4
                shr     dword ptr [bx-4], 4
                or      byte ptr [bx-1], 10h
                mov     ax, [bx]
                shl     ax, 1
                bt      ax, 15
                rcr     ax, 1
                inc     ax
                cmp     ax, 4000h
                jne     @@non_inf
                stc
                sbb     eax, eax
                mov     [bx-8], eax
                mov     [bx-4], eax
                ret
@@non_inf:
                and     ah, 7Fh
                and     word ptr [bx], 8000h
                or      [bx], ax
@@exit:
                ret
inc_man         ENDP



dec_man         PROC; Уменьшает мантиссу числа на младший разряд
; BX - указатель на число
                test    byte ptr [bx+7], 0F0h
                jz      @@exit
                cmp     byte ptr [bx], 0FFh
                je      @@exit
                mov     cx, 8           ; флаг CF=1 (из-за CMP)
@@loop:
                mov     al, [bx]
                sbb     al, 0
                das
                mov     [bx], al
                inc     bx
                loop    @@loop
                test    al, 0F0h
                jnz     @@exit
                mov     eax, [bx-8]
                shld    [bx-4], eax, 4
                shl     dword ptr [bx-8], 4
                mov     ax, [bx]
                shl     ax, 1
                bt      ax, 15
                rcr     ax, 1
                dec     ax
                cmp     ax, 0BFFFh
                jne     @@non_zero
                xor     eax, eax
                mov     [bx-8], eax
                mov     [bx-4], eax
                mov     [bx], ax
                ret
@@non_zero:
                and     ah, 7Fh
                and     word ptr [bx], 8000h
                or      [bx], ax
@@exit:
                ret
dec_man         ENDP



                PUBLIC  get_top
get_top         PROC; Возвращает в BX указатель на вершину стека
                movzx   bx, stk_top
                lea     bx, [ebx+4*ebx]
                shl     bx, 2
                add     bx, offset internal_stack
                ret
get_top         ENDP



@empty_store    PROC    far
                call    empty_store
                ret
@empty_store    ENDP

@i_store        PROC    far
                call    i_store
                ret
@i_store        ENDP

@i_load         PROC    far
                call    i_load
                ret
@i_load         ENDP

@load_num       PROC    far
                call    load_num
                ret
@load_num       ENDP

@sqrt           PROC    far
                call    sqrt
                ret
@sqrt           ENDP

@exponential    PROC    far
                call    exponential
                ret
@exponential    ENDP

@logarithm      PROC    far
                call    logarithm
                ret
@logarithm      ENDP

@duplicate      PROC    far
                call    duplicate
                ret
@duplicate      ENDP

@exchange       PROC    far
                call    exchange
                ret
@exchange       ENDP

@i_add          PROC    far
                call    i_add
                ret
@i_add          ENDP

@i_sub          PROC    far
                call    i_sub
                ret
@i_sub          ENDP

@i_mul          PROC    far
                call    i_mul
                ret
@i_mul          ENDP

@i_div          PROC    far
                call    i_div
                ret
@i_div          ENDP

@i_negative     PROC    far
                call    i_negative
                ret
@i_negative     ENDP

@i_power_n      PROC    far
                call    i_power_n
                ret
@i_power_n      ENDP






                .DATA
infinity        DB      'infinity                '
functions       DB      'x sqrt exp ln y '
func_num        =       5               ; количество функций
operations      DB      '+-*/^', ')', 00h
oper_num        =       5               ; количество операций
symbols         DB      'qwertyuiopasdfghjklzxcvbnm()+-*/^1234567890.'
sym_num         =       $-symbols

; Константы
                PUBLIC  pi, e, one, null, fact21, ln1, ln2, ln3, ln4, ln5
                PUBLIC  ln6, ln7, ln8, ln9, ln10, MMN, MNN, p_inf, n_inf
pi              DD      53589793h, 31415926h
                DW      0               ; 3.141592653589793
e               DD      28459045h, 27182818h
                DW      0               ; 2.718281828459045
one             DD      00000000h, 10000000h
                DW      0               ; 1.000000000000000
fact21          DD      17170944h, 51090942h
                DW      0013h           ; 21! = 51090942171709440000
ln1             =       $
null            DD      00000000h, 00000000h
                DW      0               ; 0.000000000000000
ln2             DD      05599453h, 69314718h
                DW      7FFFh           ; ln(2) = 0.6931471805599453
ln3             DD      88668110h, 10986122h
                DW      0               ; ln(3) = 1.098612288668110
ln4             DD      61119891h, 13862943h
                DW      0               ; ln(4) = 1.386294361119891
ln5             DD      12434100h, 16094379h
                DW      0               ; ln(5) = 1.609437912434100
ln6             DD      69228055h, 17917594h
                DW      0               ; ln(6) = 1.791759469228055
ln7             DD      49055313h, 19459101h
                DW      0               ; ln(7) = 1.945910149055313
ln8             DD      41679836h, 20794415h
                DW      0               ; ln(8) = 2.079441541679836
ln9             DD      77336219h, 21972245h
                DW      0               ; ln(9) = 2.197224577336219
ln10            DD      92994046h, 23025850h
                DW      0               ; ln(10) = 2.302585092994046
; Maximum Machine Number - НаиБольшее машинное Число (НБЧ)
MMN             DD      99999999h, 99999999h
                DW      3FFFh           ; 9.999999999999999E+16383
; MiNimum machine Number - НаиМеньшее машинное Число (НМЧ)
MNN             DD      10000000h, 00000000h
                DW      4000h           ; 1.000000000000000E-16384
p_inf           DD      0FFFFFFFFh, 0FFFFFFFFh
                DW      3FFFh           ; плюс бесконечность
n_inf           DD      0FFFFFFFFh, 0FFFFFFFFh
                DW      0BFFFh          ; минус бесконечность

; Блоки подпрограмм для компиляции математических выражений
                ASSUME  cs : _DATA
store_y         LABEL                   ; сохраняет y
y_offset        =       $+1
                mov     bx, 0000h
                call    @i_store
                jnc     $+3
                ret
sy_len          =       $-store_y

put_y           LABEL                   ; помещает y на стек
                call    @empty_store
y_offset2       =       $+1
                mov     bx, 0000h
                call    @i_load
                jnc     $+3
                ret
py_len          =       $-put_y

put_const       LABEL                   ; помещает константу на вершину стека
                call    @empty_store
num_offset      =       $+1
                mov     bx, 0000h
                call    @load_num
                jnc     $+3
                ret
pc_len          =       $-put_const

put_func        LABEL                   ; вычисляет функции
                call    @sqrt
                jnc     $+3
                ret
func_len        =       $-put_func
                call    @exponential
                jnc     $+3
                ret
                call    @logarithm
                jnc     $+3
                ret

dupl            LABEL                   ; дублирование вершины стека
                call    @duplicate
                jnc     $+3
                ret
dupl_len        =       $-dupl

exch            LABEL                   ; меняет местами ST(0) и ST(1)
                call    @exchange
exch_len        =       $-exch

put_add         LABEL                   ; операция сложения
                call    @i_add
                jnc     $+3
                ret
pa_len          =       $-put_add

put_sub         LABEL                   ; операция вычитания
                call    @i_sub
                jnc     $+3
                ret
ps_len          =       $-put_sub

put_mul         LABEL                   ; операция умножения
                call    @i_mul
                jnc     $+3
                ret
pm_len          =       $-put_mul

put_div         LABEL                   ; операция деления
                call    @i_div
                jnc     $+3
                ret
pd_len          =       $-put_div

put_negative    LABEL                   ; перемена знака
                call    @i_negative
                jnc     $+3
                ret
pn_len          =       $-put_negative

put_i_power     LABEL                   ; возведение в целую степень
power_offset    =       $+1
                mov     ax, 0000h
                call    @i_power_n
                jnc     $+3
                ret
pip_len         =       $-put_i_power




                .DATA?
sign            DB      ?
sign_e          DB      ?
inc_m           DB      ?
y_flag          DB      ?
c_digit         DW      ?
str_len         DW      ?
const_buffer    DW      ?
const_num       DW      ?

i_buff          DB      160 dup (?)     ; буфер для интервальных операций
muldiv_buffer   DB      22h dup (?)     ; буфер для операций умножения и
                                        ;                             деления
stk_top         DB      ?               ; вершина стека
stk_amount      DW      ?               ; количество чисел на стеке
internal_stack  DT      256*2 dup (?)   ; 256 пар


                END
