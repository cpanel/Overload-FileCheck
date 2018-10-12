/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 * copyright@cpanel.net                                         http://cpanel.net
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_sv_2pv_flags

#include "ppport.h"
#include "FileCheck.h"

/*
*  Macro to make the moking process easier
*     for now keep them there, so we can hack them in the same file
*.

/* generic macro with args */
#define _CALL_REAL_PP(zOP) (* ( gl_overload_ft->op[zOP].real_pp ) )(aTHX)
#define _RETURN_CALL_REAL_PP_IF_UNMOCK(zOP) if (!gl_overload_ft->op[zOP].is_mocked) return _CALL_REAL_PP(zOP);

/* simplified versions for our custom usage */
#define CALL_REAL_OP()            _CALL_REAL_PP(PL_op->op_type)
#define RETURN_CALL_REAL_OP_IF_UNMOCK() _RETURN_CALL_REAL_PP_IF_UNMOCK(PL_op->op_type)

#define INIT_FILECHECK_MOCK(op_name, op_type, f) \
  newCONSTSUB(stash, op_name,    newSViv(op_type) ); \
  gl_overload_ft->op[op_type].real_pp = PL_ppaddr[op_type]; \
  PL_ppaddr[op_type] = f;

OverloadFTOps  *gl_overload_ft = 0;

int _overload_ft_ops() {
  SV *const arg = *PL_stack_sp;
  int optype = PL_op->op_type;  /* this is the current op_type we are mocking */
  int check_status = -1;        /* 1 -> YES ; 0 -> FALSE ; -1 -> delegate */

  dSP;
  int count;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  PUSHs(sv_2mortal(newSViv(optype)));
  PUSHs(arg);
  PUTBACK;

  count = call_pv("Overload::FileCheck::_check", G_SCALAR);

  SPAGAIN;

  if (count != 1)
    croak("No return value from Overload::FileCheck::_check for OP #%d\n", optype);

  check_status = POPi;

  /* printf ("######## The result is %d /// OPTYPE is %d\n", check_status, optype); */

  PUTBACK;
  FREETMPS;
  LEAVE;

  return check_status;
}

/* TODO maybe a meta macro for this one too... */
PP(pp_overload_ftis) {
  int check_status;

  assert( gl_overload_ft );

  /* not currently mocked */
  RETURN_CALL_REAL_OP_IF_UNMOCK()

  check_status = _overload_ft_ops();

  if ( check_status == 1 ) FT_RETURNYES;
  if ( check_status == 0 ) FT_RETURNNO;

  /* fallback */
  return CALL_REAL_OP();
}

MODULE = Overload__FileCheck       PACKAGE = Overload::FileCheck

SV*
mock_op(self)
     SV* self;
 ALIAS:
      Overload::FileCheck::_mock_ftOP               = 1
      Overload::FileCheck::_unmock_ftOP             = 2
 CODE:
 {
     /* mylogger = INT2PTR(MyLogger*, SvIV(SvRV(self))); */
      int i = 0;

      switch (ix) {
         case 1: /* _mock_ftOP */
              gl_overload_ft->op[OP_FTIS].is_mocked = 1;
          break;
         case 2: /* _unmock_ftOP */
              gl_overload_ft->op[OP_FTIS].is_mocked = 0;
          break;
          default:
              XSRETURN_EMPTY;
      }

      XSRETURN_EMPTY;
 }
 OUTPUT:
     RETVAL

BOOT:
if (!gl_overload_ft) {
     HV *stash;
     SV *sv;

     Newxz( gl_overload_ft, 1, OverloadFTOps);

     stash = gv_stashpvn("Overload::FileCheck", 19, TRUE);

     newCONSTSUB(stash, "_loaded", newSViv(1) );

     /* copy the original OP then plug our own custom function */
     INIT_FILECHECK_MOCK( "OP_FTIS",   OP_FTIS,   &Perl_pp_overload_ftis); /* -e */
     INIT_FILECHECK_MOCK( "OP_FTFILE", OP_FTFILE, &Perl_pp_overload_ftis); /* -f FIXME */

     1;
}
