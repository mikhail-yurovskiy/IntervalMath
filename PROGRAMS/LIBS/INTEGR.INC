INCLUDELIB      integr.obj

.CODE
; Процедуры
EXTRN           primitive    : proc, rectangle    : proc, trapezium    : proc
EXTRN           simpson      : proc, primitive_grf: proc

.DATA
; Переменные
EXTRN           rang         : word, d_order      : byte, derivative   : word
EXTRN           function     : word, c_rang       : word, time         : dword
EXTRN           flag         : byte
