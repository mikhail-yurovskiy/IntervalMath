INCLUDELIB      integr.obj

.CODE
; ��楤���
EXTRN           primitive    : proc, rectangle    : proc, trapezium    : proc
EXTRN           simpson      : proc, primitive_grf: proc

.DATA
; ��६����
EXTRN           rang         : word, d_order      : byte, derivative   : word
EXTRN           function     : word, c_rang       : word, time         : dword
EXTRN           flag         : byte
