
#include <stdio.h>
#include "rml.h"
#include "../ast/yacclib.h"
#include <errno.h>

static int type_info;

void RTOpts_5finit(void)
{
  type_info = 0;
}

RML_BEGIN_LABEL(RTOpts__args)
{
  void *args = rmlA0;
  void *res = mk_nil();
  
  while (RML_GETHDR(args) != RML_NILHDR)
  {
    char *arg = RML_STRINGDATA(RML_CAR(args));
    printf("Arg: %s\n", arg);
    if (arg[0] == '+')
    {
      printf("Option %s\n", arg+1);
      if (strlen(arg) < 2)
      {
	fprintf(stderr, "# Unknown option: -\n");
	RML_TAILCALLK(rmlFC);
      }
      switch (arg[1]) {
      case 't':
	type_info = 1;
	break;
      default:
	fprintf(stderr, "# Unknown option: %s\n", arg);
	RML_TAILCALLK(rmlFC);
      }
    }
    else
      res = mk_cons(RML_CAR(args), res);
    args = RML_CDR(args);
  }

  rmlA0 = res;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(RTOpts__typeinfo)
{
  rmlA0 = RML_PRIM_MKBOOL(type_info);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
