/* This file is part of the Scope::Upper Perl module.
 * See http://search.cpan.org/dist/Scope-Upper/ */
   
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h" 
#include "XSUB.h"

#define __PACKAGE__     "Thread::Cleanup"
#define __PACKAGE_LEN__ (sizeof(__PACKAGE__)-1)

STATIC void tc_callback(pTHX_ void *);

STATIC void tc_callback(pTHX_ void *ud) {
 int *level = ud;
 SV *id;

 if (*level) {
  *level = 0;
  LEAVE;
  SAVEDESTRUCTOR_X(tc_callback, level);
  ENTER;
 } else {
  dSP;

  PerlMemShared_free(level);

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  PUTBACK;

  call_pv(__PACKAGE__ "::_CLEANUP", G_VOID);

  SPAGAIN;

  FREETMPS;
  LEAVE;
 }
}

MODULE = Thread::Cleanup            PACKAGE = Thread::Cleanup

PROTOTYPES: DISABLE

void
CLONE(...)
PREINIT:
 int *level;
CODE:
 {
  level = PerlMemShared_malloc(sizeof *level);
  *level = 1;
  LEAVE;
  SAVEDESTRUCTOR_X(tc_callback, level);
  ENTER;
 }
