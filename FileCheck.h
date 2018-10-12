/*
 * FileCheck.h
 */

#ifndef XS_FILE_CHECK_H
#  define XS_FILE_CHECK_H 1

#include <perl.h>

/* TODO reduce that value and add a macro to define them */
#define OP_MAX	1024

/* informations for a single overload mock */
typedef struct {
	int is_mocked; /* int for now.. could use function later */
	OP *(*real_pp)(pTHX);
} OPMocked;

/* this could be an array but for now let's keep it as a struct */
typedef struct {
	OPMocked op[OP_MAX]; /* int for now.. could use function later */
	int offset;
} OverloadFTOps;

/* function prototypes */

/* TODO move somewhere else... */
/*** helpers stolen from pp_sys.c ****/

/* If the next filetest is stacked up with this one
   (PL_op->op_private & OPpFT_STACKING), we leave
   the original argument on the stack for success,
   and skip the stacked operators on failure.
   The next few macros/functions take care of this.
*/

/* yes.... this is c code in a .h file... */
static OP *
S_ft_return_false(pTHX_ SV *ret) {
    OP *next = NORMAL;
    dSP;

    if (PL_op->op_flags & OPf_REF) XPUSHs(ret);
    else         SETs(ret);
    PUTBACK;

    if (PL_op->op_private & OPpFT_STACKING) {
        while (next && OP_IS_FILETEST(next->op_type)
               && next->op_private & OPpFT_STACKED)
            next = next->op_next;
    }
    return next;
}

PERL_STATIC_INLINE OP *
S_ft_return_true(pTHX_ SV *ret) {
    dSP;
    if (PL_op->op_flags & OPf_REF)
        XPUSHs(PL_op->op_private & OPpFT_STACKING ? (SV *)cGVOP_gv : (ret));
    else if (!(PL_op->op_private & OPpFT_STACKING))
        SETs(ret);
    PUTBACK;
    return NORMAL;
}

#define FT_RETURNNO     return S_ft_return_false(aTHX_ &PL_sv_no)
#define FT_RETURNUNDEF  return S_ft_return_false(aTHX_ &PL_sv_undef)
#define FT_RETURNYES    return S_ft_return_true(aTHX_ &PL_sv_yes)

/*** end of helpers from pp_sys.c ****/

#endif /* XS_FILE_CHECK_H */