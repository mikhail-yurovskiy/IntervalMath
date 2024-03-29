                .MODEL  small
                .386
                LOCALS  @@
                INCLUDE math.inc
                .CODE

; ���᮪ ��������� �������� ���権 �� ࠡ��:
;
;   01h         �⥪ ���� (�� 墠⠥� ��㬥�⮢ ��� ����樨)
;   02h         ��९������� �⥪�
;   03h         १���� ����樨 - ��᪮��筮���
;   04h         १���� ����樨 - ���⮥ ������⢮
;   05h         ��㬥�� �㭪樨 �� �� ������ ��।������
;   06h         ࠭� �஡����� ࠢ�� 0
;   07h         �ந������� ������� ���浪� �� �����ন������
;   08h         ᪮��� ���⠢���� �� ��୮
;   09h         �������⭠� �㭪��
;   0Ah         �訡�� � ��ࠦ����
;   0Bh         ��ࠦ���� - ����� ��ப�
;   0Ch         �訡�� � ����� ����⠭��
;   0Dh         ��������� ����
;   0Eh         ����� <Esc>
;   0Fh         �ࠪ��᪮� ����ᠭ�� �� �।���⥫쭮� ��������樨

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
esc_exit:
                mov     ax, 000Eh
                ret
check_esc       ENDP



                PUBLIC  primitive
primitive       PROC; �ਬ�⨢��� ��⥣�஢����
; �室: ST(0) - ���孨� �।��, ST(1) - ������ �।��; rang � function
; ��室: �᫨ CF=0, � ST(0) = ���������� ��⥣ࠫ�, ���� AX = ��� �訡��
@@A             EQU     offset int_buffer
@@B             EQU     offset int_buffer+20
@@Sum           EQU     offset int_buffer+40
                mov     c_rang, 0
                mov     time, 0
                mov     bx, @@B         ; ��࠭�� �।��� ��⥣�஢����
                call    i_store
                jc      exit
                mov     bx, @@A
                call    i_store
                jc      exit
                mov     di, @@Sum       ; ���㫨� ������ �㬬�
                xor     eax, eax
                mov     cx, 5
                rep     stosd
                mov     bx, @@B         ; ���᫨� 蠣 ��⥣�஢���� (h)
                call    i_load          ; ST(0) = B
                mov     bx, @@A
                call    im_sub          ; ST(0) = B-A
                jc      exit
                mov     ax, rang
                and     ax, ax
                jz      error         ; �᫨ ࠭� �஡����� ࠢ�� 0
                cmp     ax, 8000h
                jae     @@cont_0
                call    load_int
                jmp     @@cont_1
@@cont_0:
                shr     ax, 1
                call    load_int        ; ST(0) = rang/2
                mov     ax, 2
                call    load_int        ; ST(0) = 2, ST(1) = rang/2
                call    i_mul
@@cont_1:                               ; ST(0) = rang, ST(1) = B-A
                call    i_div           ; ST(0) = (B-A)/rang
                jc      exit
                mov     bx, @@B         ; ��࠭�� ��� 蠣 � B
                call    i_store
                mov     cx, rang        ; rang = ��� ᫠������
@@loop:
                call    check_esc
                jc      esc_exit
                push    cx
                mov     bx, @@A
                call    i_load          ; ST(0) = xk
                call    duplicate       ; ST(0) = xk, ST(1) = xk
                mov     bx, @@B
                call    im_add          ; ST(0) = xk + h, ST(1) = xk
                jc      exit1
                mov     bx, @@A
                push    bx
                call    i_store         ; ��࠭�� xk+1 = xk + h
                pop     bx
                call    im_hull         ; ST(0) = Xk - ��१�� ��⥣�஢����
                jc      exit1
                call    function        ; ST(0) = F(Xk)
                jc      exit1
                mov     bx, @@Sum
                push    bx
                call    im_add          ; ST(0) = Sum + F(Xk)
                pop     bx
                jc      exit1
                call    i_store         ; ��࠭�� ������ �㬬�
                pop     cx
                inc     c_rang
                loop    @@loop
                mov     bx, @@Sum
                call    i_load          ; �����⨬ �㬬� ��� F(Xk) �� �⥪
                mov     bx, @@B         ; � 㬭���� �� h
                jmp     im_mul          ; ST(0) = Sum*h. ����� ���᫥���
error:
                mov     ax, 6           ; ����� �訡��
                stc
                ret
exit2:
                pop     cx              ; ���⪠ �⥪�
exit1:
                pop     cx              ; ���⪠ �⥪�
exit:
                ret
primitive       ENDP



                PUBLIC  primitive_grf
primitive_grf   PROC; �ਬ�⨢��� ��⥣�஢����
; �室: [SI] - ����� �࠭��, [DI] - �ࠢ�� �࠭��, [BX] - ��砫쭠� �窠,
;       DX - 㪠��⥫� �� ���ᨢ �祪; rang � function
; ��室: �᫨ CF=0, � ST(0) = ���������� ��⥣ࠫ�, ���� AX = ��� �訡��
@@Sum           EQU     offset int_buffer+60
@@H             EQU     offset int_buffer+80
                mov     dots_array, dx
                push    di
                push    si
                mov     di, bx
                call    compare
                je      @@var_0
                jb      @@var_1
                push    bx
                mov     bx, si
                call    load_num        ; ST(0) = X1
                pop     bx
                call    load_num        ; ST(0) = X0, ST(1) = X1
                call    primitive
                jc      exit2
                call    i_negative
                jmp     @@continue
@@var_0:
                mov     bx, offset null
                call    load_num
                jmp     @@continue
@@var_1:
                push    si
                call    load_num        ; ST(0) = X0
                pop     bx
                call    load_num        ; ST(0) = X1, ST(1) = X0
                call    primitive
                jc      exit2
@@continue:
                mov     time, 0
                mov     c_rang, 0
                mov     flag, 1
                mov     bx, @@Sum
                call    i_store         ; ��࠭��� १����
                pop     bx              ; ����� �࠭��
                push    bx
                call    load_num
                pop     bx
                pop     dx              ; �ࠢ�� �࠭��
                xor     byte ptr [bx+9], 80h
                push    bx
                call    n_add           ; [BX] - ����� ��१�� d
                pop     bx
                call    load_num        ; ���᫨� 蠣 ��⥣�஢���� h
                mov     ax, 640
                call    cm_div          ; ST(0) = d/640 = h
                mov     bx, @@H
                call    get_middle      ; ��࠭��� h
                call    empty_store
                mov     bx, 0           ; ⥪�騩 ���ᥫ
@@loop:
                call    check_esc
                jc      esc_exit
                push    bx
                lea     di, [ebx+4*ebx]
                shl     di, 2
                add     di, dots_array
                mov     si, @@Sum
                mov     cx, 5
                rep     movsd           ; ��࠭��� ���न���� ⥪�饣� ���ᥫ�
                call    duplicate       ; ST(0) = xk, ST(1) = xk
                call    duplicate       ; ST(0) = xk, ST(1) = xk, ST(2) = xk
                mov     bx, @@H
                call    c_add           ; ST(0) = xk + h
                jc      exit1
                call    i_hull          ; ST(0) = Xk
                jc      exit1
                call    function        ; ST(0) = F(Xk), ST(1) = xk
                jc      exit1
                mov     bx, @@H
                call    c_mul           ; ST(0) = F(Xk)*h, ST(1) = xk
                jc      exit1
                mov     bx, @@Sum
                push    bx
                call    im_add          ; ST(0) = Sum + F(Xk)*h
                pop     bx
                jc      exit1
                call    i_store         ; ��࠭�� ������ �㬬�
                mov     bx, @@H
                call    c_add           ; ST(0) = xk + h = xk+1
                jc      exit1
                pop     bx
                inc     c_rang
                inc     bx
                cmp     bx, 640
                jb      @@loop
                jmp     empty_store     ; ���⨬ �⥪. �����.
primitive_grf   ENDP



                PUBLIC  rectangle
rectangle       PROC; ��⥣�஢���� �� ��㫥 業�ࠫ��� ��אַ㣮�쭨���
; �室: ST(0), ST(1) - ���孨� � ������ �।���; rang, function
; ��室: �᫨ CF=0, � ST(0) = ���������� ��⥣ࠫ�, ���� AX = ��� �訡��
@@A             EQU     offset int_buffer
@@B             EQU     offset int_buffer+20
@@C             EQU     offset int_buffer+40
@@SumQ          EQU     offset int_buffer+60
@@SumR          EQU     offset int_buffer+80
                mov     c_rang, 0
                mov     time, 0
                mov     bx, @@B         ; ��࠭�� �।��� ��⥣�஢����
                call    i_store
                jc      exit
                mov     bx, @@A
                call    i_store
                jc      exit
                mov     di, @@SumQ      ; ���㫨� ����� �㬬�
                xor     eax, eax
                mov     cx, 10
                rep     stosd
                mov     bx, @@B         ; ���᫨� 蠣 ��⥣�஢���� (h)
                call    i_load          ; ST(0) = B
                mov     bx, @@A
                call    im_sub          ; ST(0) = B-A
                jc      exit
                mov     ax, rang
                and     ax, ax
                jz      error           ; �᫨ ࠭� �஡����� ࠢ�� 0
                cmp     ax, 8000h
                jae     @@cont_0
                call    load_int
                jmp     @@cont_1
@@cont_0:
                shr     ax, 1
                call    load_int        ; ST(0) = rang/2, ST(1) = B-A
                mov     ax, 2
                call    cm_mul          ; ST(0) = rang, ST(1) = B-A
                jc      exit
@@cont_1:
                call    i_div           ; ST(0) = (B-A)/rang (= h)
                call    duplicate
                mov     bx, @@B         ; ��࠭�� ��� 蠣 � B
                call    i_store
                mov     ax, 2
                call    cm_div          ; ST(0) = h/2
                call    duplicate
                mov     bx, @@C
                call    i_store
                mov     bx, @@A
                push    bx
                call    im_add          ; ST(0) = A+h/2 (= x0)
                pop     bx
                call    i_store
                mov     cx, rang        ; rang = ��� ᫠������
@@loop:
                call    check_esc
                jc      esc_exit
                push    cx
                mov     bx, @@A
                call    i_load          ; Xk
                call    function        ; F(Xk)
                jc      exit1
                mov     bx, @@SumQ
                push    bx
                call    im_add          ; SumQ + F(Xk)
                pop     bx
                jc      exit1
                call    i_store
                mov     bx, @@C         ; 㪠�뢠�� �� h/2
                mov     dx, @@A         ; 㪠�뢠�� �� Xk
                call    rec_remainder   ; Rk
                jc      exit1
                mov     bx, @@SumR
                push    bx
                call    im_add          ; SumR + Rk
                pop     bx
                jc      exit1
                call    i_store
                mov     bx, @@A
                push    bx
                call    i_load          ; Xk
                mov     bx, @@B
                call    im_add          ; Xk + h = Xk+1
                pop     bx
                jc      exit1
                call    i_store         ; ��࠭�� ���� Xk � A
                pop     cx
                inc     c_rang
                loop    @@loop
                mov     bx, @@SumQ
                call    i_load          ; SumQ
                mov     bx, @@B
                call    im_mul          ; h*SumQ
                mov     bx, @@SumR
                call    i_load          ; SumR, h*SumQ
                mov     bx, @@C
                call    rr_mul_const    ; c*SumR, h*SumQ
                jmp     i_add           ; c*SumR + h*SumQ. ����� ���᫥���.
rectangle       ENDP



rec_remainder   PROC; ������ ���⮪ �� 業�ࠫ��� ��אַ㣮�쭨���
; �室: BX - h/2, DX - Xk, d_order, derivative
; ��室: ST(0) = Rk
                cmp     d_order, 1
                je      @@first
                cmp     d_order, 2
                je      @@second
                mov     ax, 7
                stc
@@exit:
                ret
rr_mul_const:
                call    i_load          ; h/2, SumR
                mov     ax, 2
                cmp     d_order, 2
                jne     @@non_second
                mov     ax, 3
@@non_second:
                push    ax
                call    i_power_n       ; (h/2)^2(3), SumR
                pop     ax
                call    cm_div          ; (h/2)^2(3)/2(3), SumR
                jmp     i_mul           ; SumR*(h/2)^2(3)/2(3)
@@first:
                push    bx
                mov     bx, dx
                call    i_load          ; Xk
                call    duplicate       ; Xk, Xk
                call    duplicate       ; Xk, Xk, Xk
                pop     bx
                push    bx
                call    im_add          ; Xk+h/2, Xk, Xk
                call    i_hull          ; [Xk, Xk+h/2] = T2, Xk
                call    derivative      ; F'(T2), Xk
                jc      exit1
                call    exchange        ; Xk, F'(T2)
                call    duplicate       ; Xk, Xk, F'(T2)
                pop     bx
                call    im_sub          ; Xk-h/2, Xk, F'(T2)
                call    i_hull          ; [Xk-h/2, Xk] = T1, F'(T2)
                call    derivative      ; F'(T1), F'(T2)
                jnc     i_sub           ; F'(T2) - F'(T1). �����
                ret
@@second:
                push    bx
                mov     bx, dx
                call    i_load          ; Xk
                call    duplicate       ; Xk, Xk
                pop     bx
                push    bx
                call    i_load          ; h/2, Xk, Xk
                call    i_add           ; Xk+h/2, Xk
                call    exchange        ; Xk, Xk+h/2
                pop     bx
                call    i_load          ; h/2, Xk, Xk+h/2
                call    i_sub           ; Xk-h/2, Xk+h/2
                call    i_hull          ; [Xk-h/2, Xk+h/2] = T
                jmp     derivative      ; F''(T)
rec_remainder   ENDP



                PUBLIC  trapezium
trapezium       PROC; ��⥣�஢���� �� ��㫥 �࠯�権
; �室: ST(0), ST(1) - ���孨� � ������ �।���; rang, function
; ��室: �᫨ CF=0, � ST(0) = ���������� ��⥣ࠫ�, ���� AX = ��� �訡��
@@A             EQU     offset int_buffer
@@B             EQU     offset int_buffer+20
@@C             EQU     offset int_buffer+40
@@SumQ          EQU     offset int_buffer+60
@@SumR          EQU     offset int_buffer+80
                mov     c_rang, 0
                mov     time, 0
                mov     bx, @@B         ; ��࠭�� �।��� ��⥣�஢����
                call    i_store
                jc      exit
                mov     bx, @@A
                call    i_store
                jc      exit
                mov     bx, @@A
                call    i_load          ; A
                call    function        ; F(A)
                jc      exit
                mov     bx, @@B
                call    i_load          ; B, F(A)
                call    function        ; F(B), F(A)
                jc      exit
                call    i_add           ; F(B)+F(A)
                jc      exit
                mov     ax, 2
                call    cm_div          ; (F(B)+F(A))/2
                mov     bx, @@SumQ
                call    i_store
                mov     bx, @@B         ; ���᫨� 蠣 ��⥣�஢���� (h)
                call    i_load          ; ST(0) = B
                mov     bx, @@A
                call    im_sub          ; ST(0) = B-A
                jc      exit
                mov     ax, rang
                and     ax, ax
                jz      error           ; �᫨ ࠭� �஡����� ࠢ�� 0
                cmp     ax, 8000h
                jae     @@cont_0
                call    load_int
                jmp     @@cont_1
@@cont_0:
                shr     ax, 1
                call    load_int        ; ST(0) = rang/2, ST(1) = B-A
                mov     ax, 2
                call    cm_mul          ; ST(0) = rang, ST(1) = B-A
                jc      exit
@@cont_1:
                call    i_div           ; ST(0) = (B-A)/rang (= h)
                call    duplicate
                mov     bx, @@B         ; ��࠭�� ��� 蠣 � B
                call    i_store
                mov     ax, 2
                call    cm_div          ; ST(0) = h/2
                mov     bx, @@C
                call    i_store
                mov     bx, @@B
                mov     cx, @@C
                mov     dx, @@A
                push    dx
                call    trap_remainder  ; R0
                jc      exit1
                mov     bx, @@SumR
                call    i_store
                pop     bx
                push    bx
                call    i_load          ; A = X0
                mov     bx, @@B
                call    im_add          ; A+h = X1
                pop     bx
                call    i_store
                mov     cx, rang        ; rang = ��� ᫠������-1
                dec     cx
                jz      @@cancel
@@loop:
                call    check_esc
                jc      esc_exit
                push    cx
                mov     bx, @@A
                call    i_load          ; Xk
                call    function        ; F(Xk)
                jc      exit1
                mov     bx, @@SumQ
                push    bx
                call    im_add          ; SumQ + F(Xk)
                pop     bx
                jc      exit1
                call    i_store
                mov     bx, @@B         ; 㪠�뢠�� �� h
                mov     cx, @@C         ; 㪠�뢠�� �� h/2
                mov     dx, @@A         ; 㪠�뢠�� �� Xk
                call    trap_remainder  ; Rk
                jc      exit1
                mov     bx, @@SumR
                push    bx
                call    im_add          ; SumR + Rk
                pop     bx
                jc      exit1
                call    i_store
                mov     bx, @@A
                push    bx
                call    i_load          ; Xk
                mov     bx, @@B
                call    im_add          ; Xk + h = Xk+1
                pop     bx
                jc      exit1
                call    i_store         ; ��࠭�� ���� Xk � A
                pop     cx
                inc     c_rang
                loop    @@loop
@@cancel:
                mov     bx, @@SumQ
                call    i_load          ; SumQ
                mov     bx, @@B
                call    im_mul          ; h*SumQ
                mov     bx, @@SumR
                call    i_load          ; SumR, h*SumQ
                mov     bx, @@C
                call    tr_mul_const    ; c*SumR, h*SumQ
                jmp     i_add           ; c*SumR + h*SumQ. ����� ���᫥���.
trapezium       ENDP



trap_remainder  PROC; ������ ���⮪ �� �࠯�権
; �室: BX - h, CX - h/2, DX - Xk, d_order, derivative
; ��室: ST(0) = Rk
                cmp     d_order, 1
                je      @@first
                cmp     d_order, 2
                je      @@second
                mov     ax, 7
                stc
@@exit:
                ret
tr_mul_const:
                call    i_load          ; h/2, SumR
                cmp     d_order, 2
                jne     @@non_second
                mov     ax, 3
                push    ax
                call    i_power_n       ; (h/2)^3, SumR
                pop     ax
                call    cm_div          ; (h/2)^3/3, SumR
                mov     ax, -2
                call    cm_mul          ; -2*(h/2)^3/3, SumR
                jmp     i_mul           ; -2*SumR*(h/2)^3/3
@@non_second:
                mov     ax, 2
                push    ax
                call    i_power_n       ; (h/2)^2, SumR
                pop     ax
                call    cm_div          ; (h/2)^2/2, SumR
                jmp     i_mul           ; SumR*(h/2)^2/2
@@first:
                push    bx
                push    cx
                mov     bx, dx
                call    i_load          ; Xk
                call    duplicate       ; Xk, Xk
                call    duplicate       ; Xk, Xk, Xk
                pop     bx
                push    bx
                call    im_add          ; Xk+h/2, Xk, Xk
                call    i_hull          ; [Xk, Xk+h/2] = T1, Xk
                call    derivative      ; F'(T1), Xk
                jc      exit2
                call    exchange        ; Xk, F'(T1)
                call    duplicate       ; Xk, Xk, F'(T1)
                pop     bx
                call    im_add          ; Xk+h/2, Xk, F'(T1)
                call    exchange        ; Xk, Xk+h/2, F'(T1)
                pop     bx
                call    im_add          ; Xk+h, Xk+h/2, F'(T1)
                call    i_hull          ; [Xk+h/2, Xk+h] = T2, F'(T1)
                call    derivative      ; F'(T2), F'(T1)
                jnc     i_sub           ; F'(T1) - F'(T2). �����
                ret
@@second:
                push    bx
                mov     bx, dx
                call    i_load          ; Xk
                call    duplicate       ; Xk, Xk
                pop     bx
                call    i_load          ; h, Xk, Xk
                call    i_add           ; Xk+h, Xk
                call    i_hull          ; [Xk, Xk+h] = T
                jmp     derivative      ; F''(T)
trap_remainder  ENDP



                PUBLIC  simpson
simpson         PROC; ��⥣�஢���� �� ��㫥 ����ᮭ�
; �室: ST(0), ST(1) - ���孨� � ������ �।���; rang, function
; ��室: �᫨ CF=0, � ST(0) = ���������� ��⥣ࠫ�, ���� AX = ��� �訡��
@@A             EQU     offset int_buffer
@@B             EQU     offset int_buffer+20
@@C             EQU     offset int_buffer+40
@@SumQ          EQU     offset int_buffer+60
@@SumR          EQU     offset int_buffer+80
                mov     c_rang, 0
                mov     time, 0
                mov     bx, @@B         ; ��࠭�� �।��� ��⥣�஢����
                call    i_store
                jc      exit
                mov     bx, @@A
                call    i_store
                jc      exit
                mov     bx, @@A
                call    i_load          ; A
                call    function        ; F(A)
                jc      exit
                mov     bx, @@B
                call    i_load          ; B, F(A)
                call    function        ; F(B), F(A)
                jc      exit
                call    i_add           ; F(B)+F(A)
                jc      exit
                mov     ax, 2
                call    cm_div          ; (F(B)+F(A))/2
                mov     bx, @@SumQ
                call    i_store
                mov     bx, @@B         ; ���᫨� 蠣 ��⥣�஢���� (h)
                call    i_load          ; ST(0) = B
                mov     bx, @@A
                call    im_sub          ; ST(0) = B-A
                jc      exit
                mov     ax, rang
                and     ax, ax
                jz      error           ; �᫨ ࠭� �஡����� ࠢ�� 0
                cmp     ax, 8000h
                jae     @@cont_0
                call    load_int
                jmp     @@cont_1
@@cont_0:
                shr     ax, 1
                call    load_int        ; ST(0) = rang/2, ST(1) = B-A
                mov     ax, 2
                call    cm_mul          ; ST(0) = rang, ST(1) = B-A
                jc      exit
@@cont_1:
                call    i_div           ; ST(0) = (B-A)/rang (= h)
                call    duplicate
                mov     bx, @@B         ; ��࠭�� ��� 蠣 � B
                call    i_store
                mov     ax, 2
                push    ax
                call    cm_div          ; ST(0) = h/2
                call    duplicate
                mov     bx, @@C
                call    i_store         ; ST(0) = h/2
                mov     bx, @@A
                call    im_add          ; ST(0) = A+h/2
                call    function        ; ST(0) = F(A+h/2)
                pop     ax
                jc      exit
                call    cm_mul          ; ST(0) = 2*F(A+h/2)
                jc      exit
                mov     bx, @@SumQ
                push    bx
                call    im_add          ; ST(0) = F(A) + 2*F(A+h/2) + F(B)
                pop     bx
                jc      exit
                call    i_store
                mov     bx, @@B
                mov     cx, @@C
                mov     dx, @@A
                push    dx
                call    simp_remainder  ; R0
                jc      exit1
                mov     bx, @@SumR
                call    i_store
                pop     bx
                push    bx
                call    i_load          ; ST(0) = A=X0
                mov     bx, @@B
                call    im_add          ; A + h = X1
                pop     bx
                call    i_store
                mov     cx, rang        ; rang = ��� ᫠������-1
                dec     cx
                jz      @@cancel
@@loop:
                call    check_esc
                jc      esc_exit
                push    cx
                mov     bx, @@A
                push    bx
                call    i_load          ; Xk
                call    function        ; F(Xk)
                pop     bx
                jc      exit1
                call    i_load          ; Xk, F(Xk)
                mov     bx, @@C
                call    im_add          ; Xk+h/2, F(Xk)
                call    function        ; F(Xk+h/2), F(Xk)
                jc      exit1
                mov     ax, 2
                call    cm_mul          ; 2*F(Xk+h/2), F(Xk)
                jc      exit1
                call    i_add           ; 2*F(Xk+h/2) + F(Xk)
                jc      exit1
                mov     bx, @@SumQ
                push    bx
                call    im_add          ; SumQ + 2*F(Xk+h/2) + F(Xk)
                pop     bx
                jc      exit1
                call    i_store
                mov     bx, @@B         ; 㪠�뢠�� �� h
                mov     cx, @@C         ; 㪠�뢠�� �� h/2
                mov     dx, @@A         ; 㪠�뢠�� �� Xk
                call    simp_remainder  ; Rk
                jc      exit1
                mov     bx, @@SumR
                push    bx
                call    im_add          ; SumR + Rk
                pop     bx
                jc      exit1
                call    i_store
                mov     bx, @@A
                push    bx
                call    i_load          ; Xk
                mov     bx, @@B
                call    im_add          ; Xk + h = Xk+1
                pop     bx
                jc      exit1
                call    i_store         ; ��࠭�� ���� Xk � A
                pop     cx
                inc     c_rang
                dec     cx
                jnz     @@loop
@@cancel:
                mov     bx, @@SumQ
                call    i_load          ; SumQ
                mov     ax, 3
                call    cm_div          ; SumQ/3
                mov     bx, @@B
                call    im_mul          ; h*SumQ/3
                mov     bx, @@SumR
                call    i_load          ; SumR, h*SumQ/3
                mov     bx, @@C
                call    sr_mul_const    ; c*SumR, h*SumQ/3
                jmp     i_add           ; c*SumR + h*SumQ/3. �����.
simpson         ENDP



simp_remainder  PROC; ������ ���⮪ �� ����ᮭ�
; �室: BX - h, CX - h/2, DX - Xk, d_order, derivative
; ��室: ST(0) = Rk
                cmp     d_order, 1
                je      @@first
                cmp     d_order, 2
                je      @@second
                cmp     d_order, 3
                je      @@third
                cmp     d_order, 4
                je      @@fourth
                mov     ax, 7
                stc
@@exit:
                ret
sr_mul_const:
                call    i_load          ; h/2, SumR
                cmp     d_order, 1
                je      @@one
                cmp     d_order, 2
                je      @@two
                cmp     d_order, 3
                jne     @@four
@@three:
                mov     ax, 4
                call    i_power_n       ; (h/2)^4, SumR
                mov     ax, 72
                call    cm_div          ; (h/2)^4/72, SumR
                jmp     i_mul           ; SumR*(h/2)^4/72
@@four:
                mov     ax, 5
                call    i_power_n       ; (h/2)^5, SumR
                mov     ax, -90
                call    cm_div          ; -(h/2)^5/90, SumR
                jmp     i_mul           ; -SumR*(h/2)^5/90
@@two:
                mov     ax, 3
                call    i_power_n       ; (h/2)^3, SumR
                mov     ax, 2
                call    cm_mul          ; 2*(h/2)^3, SumR
                mov     ax, 81
                call    cm_div          ; 2*(h/2)^3/81, SumR
                jmp     i_mul           ; 2*SumR*(h/2)^3/81
@@one:
                mov     ax, 2
                call    i_power_n       ; (h/2)^2, SumR
                mov     ax, 18
                call    cm_div          ; (h/2)^2/18, SumR
                jmp     i_mul           ; SumR*(h/2)^2/18
@@first:
                push    bx
                mov     bx, dx
                call    i_load          ; Xk
                call    duplicate       ; Xk, Xk
                pop     bx
                push    bx
                call    i_load          ; h, Xk, Xk
                mov     ax, 6
                call    cm_div          ; h/6, Xk, Xk
                call    i_add           ; Xk+h/6, Xk
                call    i_hull          ; [Xk, Xk+h/6] = T1
                call    empty_load      ; Xk+h/6, T1
                call    exchange        ; T1, Xk+h/6
                call    derivative      ; F'(T1), Xk+h/6
                jc      exit1
                call    exchange        ; Xk+h/6, F'(T1)
                call    duplicate       ; Xk+h/6, Xk+h/6, F'(T1)
                pop     bx
                push    bx
                call    i_load          ; h, Xk+h/6, Xk+h/6, F'(T1)
                mov     ax, 3
                call    cm_div          ; h/3, Xk+h/6, Xk+h/6, F'(T1)
                call    i_add           ; Xk+h/2, Xk+h/6, F'(T1)
                call    i_hull          ; [Xk+h/6, Xk+h/2] = T2, F'(T1)
                call    empty_load      ; Xk+h/2, T2, F'(T1)
                call    exchange        ; T2, Xk+h/2, F'(T1)
                call    derivative      ; F'(T2), Xk+h/2, F'(T1)
                jc      exit1
                mov     ax, -4
                call    cm_mul          ; -4*F'(T2), Xk+h/2, F'(T1)
                call    exchange        ; Xk+h/2, -4*F'(T2), F'(T1)
                call    duplicate       ; Xk+h/2, Xk+h/2, -4*F'(T2), F'(T1)
                pop     bx
                push    bx
                call    i_load          ; h, Xk+h/2, Xk+h/2, -4*F'(T2), F'(T1)
                mov     ax, 3
                call    cm_div          ; h/3, Xk+h/2, Xk+h/2, -4*F'(T2), F'(T1)
                call    i_add           ; Xk+5*h/6, Xk+h/2, -4*F'(T2), F'(T1)
                call    i_hull          ; [Xk+h/2, Xk+5*h/6] = T3, -4*F'(T2), F'(T1)
                call    empty_load      ; Xk+5*h/6, T3, -4*F'(T2), F'(T1)
                call    exchange        ; T3, Xk+5*h/6, -4*F'(T2), F'(T1)
                call    derivative      ; F'(T3), Xk+5*h/6, -4*F'(T2), F'(T1)
                jc      exit1
                mov     ax, 4
                call    cm_mul          ; 4*F'(T3), Xk+5*h/6, -4*F'(T2), F'(T1)
                call    exchange        ; Xk+5*h/6, 4*F'(T3), -4*F'(T2), F'(T1)
                call    duplicate       ; Xk+5*h/6, Xk+5*h/6, ...
                pop     bx
                call    i_load          ; h, Xk+5*h/6, Xk+5*h/6, ...
                mov     ax, 6
                call    cm_div          ; h/6, Xk+5*h/6, Xk+5*h/6, ...
                call    i_add           ; Xk+h, Xk+5*h/6, ...
                call    i_hull          ; [Xk+5*h/6, Xk+h] = T4, ...
                call    derivative      ; F'(T4), 4*F'(T3), -4*F'(T2), F'(T1)
                jc      exit
                call    i_sub           ; 4*F'(T3)-F'(T4), -4*F'(T2), F'(T1)
                call    i_add           ; -4*F'(T2)+4*F'(T3)-F'(T4), F'(T1)
                jmp     i_add           ; F'(T1)-4*F'(T2)+4*F'(T3)-F'(T4)
@@second:
                push    bx
                mov     bx, dx
                call    i_load          ; Xk
                call    duplicate       ; Xk, Xk
                pop     bx
                push    bx
                call    i_load          ; h, Xk, Xk
                mov     ax, 3
                call    cm_div          ; h/3, Xk, Xk
                call    i_add           ; Xk+h/3, Xk
                call    i_hull          ; [Xk, Xk+h/3] = T1
                call    empty_load      ; Xk+h/3, T1
                call    exchange        ; T1, Xk+h/3
                call    derivative      ; F''(T1), Xk+h/3
                jc      exit1
                call    i_negative      ; -F''(T1), Xk+h/3
                call    exchange        ; Xk+h/3, -F''(T1)
                call    duplicate       ; Xk+h/3, Xk+h/3, -F''(T1)
                pop     bx
                push    bx
                call    i_load          ; h, Xk+h/3, Xk+h/3, -F''(T1)
                mov     ax, 6
                call    cm_div          ; h/6, Xk+h/3, Xk+h/3, -F''(T1)
                call    i_add           ; Xk+h/2, Xk+h/3, -F''(T1)
                call    i_hull          ; [Xk+h/3, Xk+h/6] = T2, -F''(T1)
                call    empty_load      ; Xk+h/2, T2, -F''(T1)
                call    exchange        ; T2, Xk+h/2, -F''(T1)
                call    derivative      ; F''(T2), Xk+h/2, -F''(T1)
                jc      exit1
                call    exchange        ; Xk+h/2, F''(T2), -F''(T1)
                call    duplicate       ; Xk+h/2, Xk+h/2, F''(T2), -F''(T1)
                pop     bx
                push    bx
                call    i_load          ; h, Xk+h/2, Xk+h/2, F''(T2), -F''(T1)
                mov     ax, 6
                call    cm_div          ; h/6, Xk+h/2, Xk+h/2, F''(T2), -F''(T1)
                call    i_add           ; Xk+2*h/3, Xk+h/2, F''(T2), -F''(T1)
                call    i_hull          ; [Xk+h/2, Xk+2*h/3] = T3, F''(T2), -F''(T1)
                call    empty_load      ; Xk+2*h/3, T3, F''(T2), -F''(T1)
                call    exchange        ; T3, Xk+2*h/3, F''(T2), -F''(T1)
                call    derivative      ; F''(T3), Xk+2*h/3, F''(T2), -F''(T1)
                jc      exit1
                call    exchange        ; Xk+2*h/3, F''(T3), F''(T2), -F''(T1)
                call    duplicate       ; Xk+2*h/3, Xk+2*h/3, ...
                pop     bx
                call    i_load          ; h, Xk+2*h/3, Xk+2*h/3, ...
                mov     ax, 3
                call    cm_div          ; h/3, Xk+2*h/3, Xk+2*h/3, ...
                call    i_add           ; Xk+h, Xk+2*h/3, ...
                call    i_hull          ; [Xk+2*h/3, Xk+h] = T4, ...
                call    derivative      ; F''(T4), F''(T3), F''(T2), -F''(T1)
                jc      exit
                call    i_sub           ; F''(T3)-F''(T4), F''(T2), -F''(T1)
                call    i_add           ; F''(T2)+F''(T3)-F''(T4), -F''(T1)
                jmp     i_add           ; -F''(T1)+F''(T2)+F''(T3)-F''(T4)
@@third:
                push    bx
                push    cx
                mov     bx, dx
                call    i_load          ; Xk
                call    duplicate       ; Xk, Xk
                call    duplicate       ; Xk, Xk, Xk
                pop     bx
                push    bx
                call    im_add          ; Xk+h/2, Xk, Xk
                call    i_hull          ; [Xk, Xk+h/2] = T1, Xk
                call    derivative      ; F'''(T1), Xk
                jc      exit2
                call    exchange        ; Xk, F'''(T1)
                call    duplicate       ; Xk, Xk, F'''(T1)
                pop     bx
                call    im_add          ; Xk+h/2, Xk, F'''(T1)
                call    exchange        ; Xk, Xk+h/2, F'''(T1)
                pop     bx
                call    im_add          ; Xk+h, Xk+h/2, F'''(T1)
                call    i_hull          ; [Xk+h/2, Xk+h] = T2, F'''(T1)
                call    derivative      ; F'''(T2), F'''(T1)
                jnc     i_sub           ; F'''(T1) - F'''(T2). �����
                ret
@@fourth:
                push    bx
                mov     bx, dx
                call    i_load          ; Xk
                call    duplicate       ; Xk, Xk
                pop     bx
                call    i_load          ; h, Xk, Xk
                call    i_add           ; Xk+h, Xk
                call    i_hull          ; [Xk, Xk+h] = T
                jmp     derivative      ; F''''(T)
simp_remainder  ENDP





                .DATA?

                PUBLIC  rang
rang            DW      ?               ; ࠭� �஡����� (1..65535)

                PUBLIC  c_rang
c_rang          DW      ?               ; ⥪�騩 ��१�� ��⥣�஢����

                PUBLIC  flag
flag            DB      ?

                PUBLIC  time
time            DD      ?               ; ������⢮ ᥪ㭤

                PUBLIC  d_order
d_order         DB      ?               ; ���冷� �ந�������

                PUBLIC  function
function        DW      ?               ; ���� ��楤��� ���᫥��� �㭪樨

                PUBLIC  derivative
derivative      DW      ?               ; ���� ��楤��� ��� �ந�������


num             DB      ?
dots_array      DW      ?
int_buffer      DB      130 dup (?)     ; ���� ��� ��楤�� ��⥣�஢����

                END
