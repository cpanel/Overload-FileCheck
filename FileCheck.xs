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

/* ----------- start there --------------- */

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

/* lazy macro to declare a custom OP */
/* Note: can probably use the same for every OPs.. */
#define DECLARE_FTOP(pp_name) PP(pp_name) { \
  int check_status; \
  assert( gl_overload_ft ); \
  /* not currently mocked */ \
  RETURN_CALL_REAL_OP_IF_UNMOCK() \
  check_status = _overload_ft_ops(); \
  if ( check_status == 1 ) FT_RETURNYES; \
  if ( check_status == 0 ) FT_RETURNNO; \
  /* fallback */ \
  return CALL_REAL_OP(); \
}

/* a generic OP to overload the FT OPs returning yes or no */
/* FIXME also need to handle undef */
PP(pp_overload_ft_yes_no) {
  int check_status;

  assert( gl_overload_ft );
  
  /* not currently mocked */
  RETURN_CALL_REAL_OP_IF_UNMOCK()
  check_status = _overload_ft_ops();
  
  if ( check_status == 1 ) FT_RETURNYES;
  if ( check_status == 0 ) FT_RETURNNO;
  /* if ( check_status == -1 ) FT_RETURNUNDEF; */ /* TODO */
  
  /* fallback */
  return CALL_REAL_OP();
}


/* setup all our custom OPs -
* note: probably can only setup one generic function for all OPs...
*/
DECLARE_FTOP(pp_overload_ftis)
DECLARE_FTOP(pp_overload_ftrread)
DECLARE_FTOP(pp_overload_ftlink)
DECLARE_FTOP(pp_overload_fttty)
DECLARE_FTOP(pp_overload_fttext)
DECLARE_FTOP(pp_overload_ftbinary)

DECLARE_FTOP(pp_overload_ftrwrite)
DECLARE_FTOP(pp_overload_ftrexec)
DECLARE_FTOP(pp_overload_fteread)
DECLARE_FTOP(pp_overload_ftewrite)
DECLARE_FTOP(pp_overload_fteexec)

DECLARE_FTOP(pp_overload_ftsize)
DECLARE_FTOP(pp_overload_ftmtime)
DECLARE_FTOP(pp_overload_ftctime)
DECLARE_FTOP(pp_overload_ftatime)

DECLARE_FTOP(pp_overload_ftrowned)
DECLARE_FTOP(pp_overload_fteowned)
DECLARE_FTOP(pp_overload_ftzero)
DECLARE_FTOP(pp_overload_ftsock)
DECLARE_FTOP(pp_overload_ftchr)
DECLARE_FTOP(pp_overload_ftblk)
DECLARE_FTOP(pp_overload_ftfile)
DECLARE_FTOP(pp_overload_ftdir)
DECLARE_FTOP(pp_overload_ftpipe)
DECLARE_FTOP(pp_overload_ftsuid)
DECLARE_FTOP(pp_overload_ftgid)
DECLARE_FTOP(pp_overload_ftsvtx)

/*
*  extract from https://perldoc.perl.org/functions/-X.html
*
*  -r  File is readable by effective uid/gid.
*  -w  File is writable by effective uid/gid.
*  -x  File is executable by effective uid/gid.
*  -o  File is owned by effective uid.
*  -R  File is readable by real uid/gid.
*  -W  File is writable by real uid/gid.
*  -X  File is executable by real uid/gid.
*  -O  File is owned by real uid.
*  -e  File exists.
*  -z  File has zero size (is empty).
*  -s  File has nonzero size (returns size in bytes).
*  -f  File is a plain file.
*  -d  File is a directory.
*  -l  File is a symbolic link (false if symlinks aren't
*      supported by the file system).
*  -p  File is a named pipe (FIFO), or Filehandle is a pipe.
*  -S  File is a socket.
*  -b  File is a block special file.
*  -c  File is a character special file.
*  -t  Filehandle is opened to a tty.
*  -u  File has setuid bit set.
*  -g  File has setgid bit set.
*  -k  File has sticky bit set.
*  -T  File is an ASCII or UTF-8 text file (heuristic guess).
*  -B  File is a "binary" file (opposite of -T).
*  -M  Script start time minus file modification time, in days.
*  -A  Same for access time.
*  -C  Same for inode change time
*/

MODULE = Overload__FileCheck       PACKAGE = Overload::FileCheck

SV*
mock_op(optype)
     SV* optype;
 ALIAS:
      Overload::FileCheck::_xs_mock_op               = 1
      Overload::FileCheck::_xs_unmock_op             = 2
 CODE:
 {
     /* mylogger = INT2PTR(MyLogger*, SvIV(SvRV(self))); */
      int opid = 0;

      if ( ! SvIOK(optype) )
        croak("first argument to _xs_mock_op / _xs_unmock_op must be one integer");

      opid = SvIV( optype );
      if ( !opid || opid < 0 || opid >= OP_MAX )
          croak( "Invalid opid value %d", opid );

      switch (ix) {
         case 1: /* _xs_mock_op */
              gl_overload_ft->op[opid].is_mocked = 1;
          break;
         case 2: /* _xs_unmock_op */
              gl_overload_ft->op[opid].is_mocked = 0;
          break;
          default:
              croak("Unsupported function at index %d", ix);
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

     /* copy the original OP then plug our own custom OP function */
     /* view pp_sys.c for complete list */

     /* PP(pp_ftrread) - yes/no/undef */
     INIT_FILECHECK_MOCK( "OP_FTRREAD",   OP_FTRREAD,   &Perl_pp_overload_ft_yes_no);   /* -R */
     INIT_FILECHECK_MOCK( "OP_FTRWRITE",  OP_FTRWRITE,  &Perl_pp_overload_ft_yes_no);   /* -W */
     INIT_FILECHECK_MOCK( "OP_FTREXEC",   OP_FTREXEC,   &Perl_pp_overload_ft_yes_no);   /* -X */
     INIT_FILECHECK_MOCK( "OP_FTEREAD",   OP_FTEREAD,   &Perl_pp_overload_ft_yes_no);   /* -r */
     INIT_FILECHECK_MOCK( "OP_FTEWRITE",  OP_FTEWRITE,  &Perl_pp_overload_ft_yes_no);   /* -w */
     INIT_FILECHECK_MOCK( "OP_FTEEXEC",   OP_FTEEXEC,   &Perl_pp_overload_ft_yes_no);   /* -x */

     /* PP(pp_ftis) - yes/undef/true/false */
     INIT_FILECHECK_MOCK( "OP_FTIS",      OP_FTIS,      &Perl_pp_overload_ft_yes_no);   /* -e */
     INIT_FILECHECK_MOCK( "OP_FTSIZE",    OP_FTSIZE,    &Perl_pp_overload_ft_yes_no);   /* -s */
     INIT_FILECHECK_MOCK( "OP_FTMTIME",   OP_FTMTIME,   &Perl_pp_overload_ft_yes_no);   /* -M */
     INIT_FILECHECK_MOCK( "OP_FTCTIME",   OP_FTCTIME,   &Perl_pp_overload_ft_yes_no);   /* -C */
     INIT_FILECHECK_MOCK( "OP_FTATIME",   OP_FTATIME,   &Perl_pp_overload_ft_yes_no);   /* -A */

     /* PP(pp_ftrowned) yes/no/undef */
     INIT_FILECHECK_MOCK( "OP_FTROWNED",  OP_FTROWNED,  &Perl_pp_overload_ft_yes_no);   /* -O */
     INIT_FILECHECK_MOCK( "OP_FTEOWNED",  OP_FTEOWNED,  &Perl_pp_overload_ft_yes_no);   /* -o */
     INIT_FILECHECK_MOCK( "OP_FTZERO",    OP_FTZERO,    &Perl_pp_overload_ft_yes_no);   /* -z */
     INIT_FILECHECK_MOCK( "OP_FTSOCK",    OP_FTSOCK,    &Perl_pp_overload_ft_yes_no);   /* -S */
     INIT_FILECHECK_MOCK( "OP_FTCHR",     OP_FTCHR,     &Perl_pp_overload_ft_yes_no);   /* -c */
     INIT_FILECHECK_MOCK( "OP_FTBLK",     OP_FTBLK,     &Perl_pp_overload_ft_yes_no);   /* -b */
     INIT_FILECHECK_MOCK( "OP_FTFILE",    OP_FTFILE,    &Perl_pp_overload_ft_yes_no);   /* -f */
     INIT_FILECHECK_MOCK( "OP_FTDIR",     OP_FTDIR,     &Perl_pp_overload_ft_yes_no);   /* -d */
     INIT_FILECHECK_MOCK( "OP_FTPIPE",    OP_FTPIPE,    &Perl_pp_overload_ft_yes_no);   /* -p */
     INIT_FILECHECK_MOCK( "OP_FTSUID",    OP_FTSUID,    &Perl_pp_overload_ft_yes_no);   /* -u */
     INIT_FILECHECK_MOCK( "OP_FTSGID",    OP_FTSGID,    &Perl_pp_overload_ft_yes_no);   /* -g */
     INIT_FILECHECK_MOCK( "OP_FTSVTX",    OP_FTSVTX,    &Perl_pp_overload_ft_yes_no);   /* -k */

     /* PP(pp_ftlink) - yes/no/undef */
     INIT_FILECHECK_MOCK( "OP_FTLINK",    OP_FTLINK,    &Perl_pp_overload_ft_yes_no);   /* -l */

     /* PP(pp_fttty) - yes/no/undef */
     INIT_FILECHECK_MOCK( "OP_FTTTY",     OP_FTTTY,     &Perl_pp_overload_ft_yes_no);   /* -t */

    /* PP(pp_fttext) - yes/no/undef */
     INIT_FILECHECK_MOCK( "OP_FTTEXT",    OP_FTTEXT,    &Perl_pp_overload_ft_yes_no);   /* -T */
     INIT_FILECHECK_MOCK( "OP_FTBINARY",  OP_FTBINARY,  &Perl_pp_overload_ft_yes_no);   /* -B */

     1;
}
