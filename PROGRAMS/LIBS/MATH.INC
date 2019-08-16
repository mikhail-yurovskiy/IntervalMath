INCLUDELIB      math.obj

.CODE
; Процедуры
EXTRN           init_stack   : proc, i_load       : proc, i_store      : proc
EXTRN           majorise     : proc, crossing     : proc, i_hull       : proc
EXTRN           im_hull      : proc, i_add        : proc, im_add       : proc
EXTRN           i_sub        : proc, im_sub       : proc, i_negative   : proc
EXTRN           i_mul        : proc, im_mul       : proc, i_div        : proc
EXTRN           im_div       : proc, i_inverse    : proc, i_power_n    : proc
EXTRN           factorial    : proc, exponential  : proc, logarithm    : proc
EXTRN           sqrt         : proc, val_func     : proc, asc_func     : proc
EXTRN           load_num     : proc, load_int     : proc, get_int      : proc
EXTRN           n_add        : proc, n_mul        : proc, n_div        : proc
EXTRN           cmp_inf      : proc, compare      : proc, compare_abs  : proc
EXTRN           get_top      : proc, duplicate    : proc, exchange     : proc
EXTRN           c_add        : proc, cm_add       : proc, c_sub        : proc
EXTRN           cm_sub       : proc, c_mul        : proc, cm_mul       : proc
EXTRN           c_div        : proc, cm_div       : proc, i_abs        : proc
EXTRN           empty_load   : proc, empty_store  : proc, get_width    : proc
EXTRN           get_middle   : proc, make_mthproc : proc, n_sub        : proc

.DATA
; Константы
EXTRN           pi, e, one, null, fact21, ln1, ln2, ln3, ln4, ln5, ln6, ln7
EXTRN           ln8, ln9, ln10, MMN, MNN, p_inf, n_inf
