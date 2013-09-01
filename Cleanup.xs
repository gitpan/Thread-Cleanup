/* This file is part of the Thread::Cleanup Perl module.
 * See http://search.cpan.org/dist/Thread-Cleanup/ */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define __PACKAGE__     "Thread::Cleanup"
#define __PACKAGE_LEN__ (sizeof(__PACKAGE__)-1)

#define TC_HAS_PERL(R, V, S) (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#include "reap.h"

STATIC void tc_callback(pTHX_ void *ud) {
 dSP;

 ENTER;
 SAVETMPS;

 PUSHMARK(SP);
 PUTBACK;

 call_pv(__PACKAGE__ "::_CLEANUP", G_VOID | G_EVAL);

 PUTBACK;

 FREETMPS;
 LEAVE;
}

MODULE = Thread::Cleanup            PACKAGE = Thread::Cleanup

PROTOTYPES: DISABLE

void
CLONE(...)
PREINIT:
PPCODE:
 reap(3, tc_callback, NULL);
 XSRETURN(0);
