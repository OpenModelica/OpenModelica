/*
This file is part of OpenModelica.

Copyright (c) 1998-2006, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

* Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include "rml.h"
#include "../absyn_builder/yacclib.h"

static int type_info;
static int split_arrays;
static int modelica_output;
static int debug_flag_info;
static int params_struct;
static int version_request;

/* Level of eliminations of equations. 
 * 0 - None
 * 1 - Only aliases (a=b)
 * 2 - Full (default) (a=-b, a=b, a=constant)
 * 3 - Only constants (a = constant)
 * */
static int elimination_level=2; 

static char **debug_flags;
static char *debug_flagstr;
static int debug_flagc;
static int debug_all;
static int debug_none;
int nproc;
double latency=0.0;
double bandwidth=0.0;
int simulation_cg;
int silent;

void RTOpts_5finit(void)
{
  type_info = 0;
  split_arrays = 1;
  modelica_output = 0;
  debug_flag_info = 0;
  params_struct = 0;
  debug_all = 0;
  debug_none = 1;
  nproc = 0;
  simulation_cg = 0;
  silent = 0;
  version_request = 0;
}

static int set_debug_flags(char *flagstr)
{
  int i;
  int len=strlen(flagstr);
  int flagc=1;
  int flag;

  debug_none = 0; /* -d was given, hence turn off the virtual flag "none". */

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
    fprintf(stderr, "Error in setting flags.\n",flag,flagc);
    return -1;
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
  if (strcmp(strdata,"none")==0 && debug_none == 1) {
    flg=1;
  }
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
  if (debug_flag_info == 1) {
    if (flg==1)
      fprintf(stdout, "--------- %s = 1 ---------\n", strdata);	
    else
      fprintf(stdout, "--------- %s = 0 ---------\n", strdata);	
  }

  return flg;
}


RML_BEGIN_LABEL(RTOpts__args)
{
  void *args = rmlA0;
  void *res = (void*)mk_nil();

  debug_none = 1;
  
  while (RML_GETHDR(args) != RML_NILHDR)
  {
    char *arg = RML_STRINGDATA(RML_CAR(args));
    if(strcmp(arg,"++version") == 0 || strcmp(arg,"++v") == 0) {
    	version_request = 1;
    } else if (arg[0] == '+')
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
      case 's':
	simulation_cg = 1;
	break;
      case 'm':
	modelica_output = 1;
	break;
      case 'p':
	params_struct = 1;
	break;
      case 'q':
	silent = 1;
	break;
      case 'd':
	if (arg[2]=='d') {
	  debug_flag_info = 1;
	  break;
	}
	if (arg[2]!='=' ||
	    set_debug_flags(&(arg[3])) != 0) {
	  fprintf(stderr, "# Flag Usage:  +d=flg1,flg2,...\n") ;
	  fprintf(stderr, "#              +dd for debug flag info\n");
	  RML_TAILCALLK(rmlFC);
	}
	break;
      case 'n':
	if (arg[2] != '=') {
	  fprintf(stderr, "# Flag Usage:  +n=<no. of proc>") ;
	  RML_TAILCALLK(rmlFC);
	}
	nproc = atoi(&arg[3]);
	if (nproc == 0) {
	  fprintf(stderr, "Error, integer value expected for number of processors.\n") ;
	  RML_TAILCALLK(rmlFC);
	} 
	break;
      case 'l':
	if (arg[2] != '=') {
	  fprintf(stderr, "# Flag Usage:  +l=<latency value>") ;
	  RML_TAILCALLK(rmlFC);
	}
	latency = (double)atoi(&arg[3]); /* ,NULL); */
	if (latency == 0.0) {
	  fprintf(stderr, "Error, integer expected for latency.\n") ;
	  RML_TAILCALLK(rmlFC);
	} 
	break;
      case 'b':
	if (arg[2] != '=') {
	  fprintf(stderr, "# Flag Usage:  +b=<bandwidth value>") ;
	  RML_TAILCALLK(rmlFC);
	}
	bandwidth = (double)atoi(&arg[3]);
	if (bandwidth == 0.0) {
	  fprintf(stderr, "Error, integer expected for bandwidth.\n") ;
	  RML_TAILCALLK(rmlFC);
	} 
	break;
	// Which level of algebraic elimination to use.
	  case 'e':
	if (arg[2] != '=') {
	  fprintf(stderr, "# Flag Usage:  +e=<algebraic_elimination_level 0, 1, 2(default) or 3>") ;
	  RML_TAILCALLK(rmlFC);
	}
	elimination_level = (int)atoi(&arg[3]);
	if (elimination_level < 0 || elimination_level > 3) {
		elimination_level = 2;
	  fprintf(stderr, "Warning, wrong value of elimination level, will use default = %d\n",elimination_level) ;
	} 
	break;
      default:
	fprintf(stderr, "# Unknown option: %s\n", arg);
	RML_TAILCALLK(rmlFC);
      }
    }
    else
      res = (void*)mk_cons(RML_CAR(args), res);
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

RML_BEGIN_LABEL(RTOpts__splitArrays)
{
  rmlA0 = RML_PRIM_MKBOOL(split_arrays);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(RTOpts__modelicaOutput)
{
  rmlA0 = RML_PRIM_MKBOOL(modelica_output);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(RTOpts__paramsStruct)
{
  rmlA0 = RML_PRIM_MKBOOL(params_struct);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(RTOpts__silent)
{
  rmlA0 = RML_PRIM_MKBOOL(silent);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(RTOpts__eliminationLevel)
{
	rmlA0 = mk_icon(elimination_level);
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(RTOpts__setEliminationLevel)
{
	int level = (int)RML_IMMEDIATE(RML_UNTAGFIXNUM(rmlA0));
	elimination_level = level;
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(RTOpts__debugFlag)
{
    void *str = rmlA0;
    char *strdata = RML_STRINGDATA(str);
    int flg = check_debug_flag(strdata);

    /*
    int flg=0;
    int i;
    if (strcmp(strdata,"none")==0 && debug_none == 1) {
      flg=1;
    }
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
    */

    rmlA0 = RML_PRIM_MKBOOL(flg);
    RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(RTOpts__noProc)
{
  rmlA0 = (void*)mk_icon(nproc);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(RTOpts__latency)
{
  rmlA0 = (void*)mk_rcon(latency);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(RTOpts__bandwidth)
{
  rmlA0 = (void*)mk_rcon(bandwidth);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(RTOpts__simulationCg)
{
  rmlA0 = RML_PRIM_MKBOOL(simulation_cg);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(RTOpts__versionRequest)
{
  rmlA0 = RML_PRIM_MKBOOL(version_request);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

