
#include <stdio.h>
#include "rml.h"
#include "../ast/yacclib.h"
#include <errno.h>

static int type_info;
static int split_arrays;
static int modelica_output;

void RTOpts_5finit(void)
{
  type_info = 0;
  split_arrays = 1;
  modelica_output = 0;
}

RML_BEGIN_LABEL(RTOpts__args)
{
  void *args = rmlA0;
  void *res = mk_nil();
  
  while (RML_GETHDR(args) != RML_NILHDR)
  {
    char *arg = RML_STRINGDATA(RML_CAR(args));
    if (arg[0] == '+')
    {
      if (strlen(arg) < 2)
      {
	fprintf(stderr, "# Unknown option: -\n");
	RML_TAILCALLK(rmlFC);
      }
      switch (arg[1]) {
      case 't':
	type_info = 1;
	break;
      case 'a':
	split_arrays = 0;
	type_info = 0;
	break;
      case 'm':
	modelica_output = 1;
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

RML_BEGIN_LABEL(RTOpts__split_5farrays)
{
  rmlA0 = RML_PRIM_MKBOOL(split_arrays);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(RTOpts__modelica_5foutput)
{
  rmlA0 = RML_PRIM_MKBOOL(modelica_output);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
