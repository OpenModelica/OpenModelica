
#include <stdio.h>
#include "rml.h"
#include "../ast/yacclib.h"
#include <errno.h>
#include <assert.h>

static int type_info;
static int split_arrays;
static int modelica_output;
static int debug_flag_info;
static int params_struct;

static char **debug_flags;
static char *debug_flagstr;
static int debug_flagc;
static int debug_all;

void RTOpts_5finit(void)
{
  type_info = 0;
  split_arrays = 1;
  modelica_output = 0;
  debug_flag_info = 0;
  params_struct = 0;
  debug_all = 0;
}

static int set_debug_flags(char *flagstr)
{
  int i;
  int len=strlen(flagstr);
  int flagc=1;
  int flag;

  if (len==0) {
    debug_flagc = 0;
    debug_flagstr = (char*)malloc(sizeof(char));
    debug_flagstr = '\0';
    debug_all = 0;
    debug_flags = 0;
    return 0;
  }

  debug_flagstr=(char*)malloc((len+1)*sizeof(char));
  strcpy(debug_flagstr, flagstr);

  for (i=0;i<len;i++)
    if (debug_flagstr[i]==',')
      flagc++;
  debug_flags = (char**)malloc(flagc * sizeof(char*));
  debug_flags[0]=debug_flagstr;
  flag=1;
  for (i=1; i<len; i++) {
    if (debug_flagstr[i-1]==',') {
      debug_flags[flag]=&(debug_flagstr[i]);
      debug_flagstr[i-1]=0;
      if (strcmp("all", debug_flags[flag-1])==0) {
	debug_all=1;
      }
      flag++;
    }
  }
  if (strcmp("all", debug_flags[flag-1])==0) {
    debug_all=1;
  }
  if (flag!=flagc) {
    fprintf(stderr, "--Warning: Internal error flag=%d, flagc=%d",flag,flagc);
    assert(1);
  }
  
  debug_flagc=flagc;

  /*
  for (i=0; i<debug_flagc; i++) {
    printf("\n%d=%s\n",i,debug_flags[i]);
  }
  */
  return 0;
}

int check_debug_flag(char const* strdata)
{
  int flg=0;
  int i;
  if (debug_all==1) {
    flg=1;
  }
  for (i=0; i<debug_flagc; i++) {
    if (strcmp(debug_flags[i], strdata)==0) {
      flg=1;
      break;
    }
    else if (debug_flags[i][0]=='-' &&
	     strcmp(debug_flags[i]+1, strdata)==0) {
      flg=0;
      break;
    }
  }
  if (flg==1 && debug_flag_info==1)
    fprintf(stdout, "--------- %s ---------\n", strdata);	

  return flg;
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
      case 'p':
	params_struct = 1;
	break;
      case 'q':
	debug_flag_info = 1;
	break;
      case 'd':
	if (arg[2]!='=' ||
	    set_debug_flags(&(arg[3])) != 0) {
	  fprintf(stderr, "# Flag Usage:  -d=flg1,flg2,...") ;
	  RML_TAILCALLK(rmlFC);
	}
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

RML_BEGIN_LABEL(RTOpts__debug_5fflag_5finfo)
{
  rmlA0 = RML_PRIM_MKBOOL(debug_flag_info);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(RTOpts__params_5fstruct)
{
  rmlA0 = RML_PRIM_MKBOOL(params_struct);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(RTOpts__debug_5fflag)
{
    void *str = rmlA0;
    char *strdata = RML_STRINGDATA(str);
    int flg=0;
    int i;
    if (debug_all==1) {
      flg=1;
    }
    for (i=0; i<debug_flagc; i++) {
      if (strcmp(debug_flags[i], strdata)==0) {
	flg=1;
	break;
      }
      else if (debug_flags[i][0]=='-' &&
	       strcmp(debug_flags[i]+1, strdata)==0) {
	flg=0;
	break;
      }
    }
    if (flg==1 && debug_flag_info==1)
      fprintf(stdout, "--------- %s ---------\n", strdata);	

    rmlA0 = RML_PRIM_MKBOOL(flg);
    RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


