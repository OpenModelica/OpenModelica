/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>

static int type_info = 0;
static int split_arrays = 1;
static int modelica_output = 0;
static int debug_flag_info = 0;
static int params_struct = 0;
static int version_request = 0;

/* Level of eliminations of equations.
 * 0 - None
 * 1 - Only aliases (a=b) (default)
 * 2 - Full (a=-b, a=b, a=constant)
 * 3 - Only constants (a = constant)
 * */
static long elimination_level=2;

static char **debug_flags = 0;
static char *debug_flagstr = 0;
static int debug_flagc = 0;
static int debug_all = 0;
static int debug_none = 1;
static int nproc = 0;
static double latency=0.0;
static double bandwidth=0.0;
static int simulation_cg = 0;
static int silent = 0;
static const char* simulation_code_target = "gcc";
static const char* class_to_instantiate = "";
static long vectorization_limit = 20;

/*
 * adrpo 2007-06-11
 * flag for accepting only Modelica grammar or MetaModelica grammar
 */
#define GRAMMAR_MODELICA 0
#define GRAMMAR_METAMODELICA 1
static int acceptedGrammar = GRAMMAR_MODELICA;

/*
 * adrpo 2008-12-13
 * flag for turning of expression simplification!
 */
static int noSimplify = 0;
/* Flag to to disable output that is computer-dependent,
 * such as total runtime of a simulation. */
int running_testsuite = 0;

/*
 * @author adrpo
 * @date 2007-02-08
 * This variable is defined in corbaimpl.cpp and set
 * here by function setCorbaSessionName(char* name);
 */
extern const char* corbaSessionName;

/*
 * adrpo 2008-11-28
 * flag for accepting different version of Modelica annotations
 */
static const char* annotation_version = "2.x";

/*
 * adrpo 2008-12-15
 * flag +showErrorMessages for printing all messages comming to the error buffer
 */
int showErrorMessages = 0;

/* flag +showAnnotation for printing annotations when dumping the DAE as flat
 * modelica */
static int showAnnotations = 0;

static int set_debug_flags(const char *flagstr)
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

static int set_debug_flag(char const* strdata, long value)
{
	int length=strlen(strdata),i;
	for (i=0; i<debug_flagc; i++)
	{
		if (strcmp(debug_flags[i], strdata)==0)
		{
			if(value == 0 )
			{
				debug_flags[i] = (char*) "";
				// TODO: realloc memory when count(empty_entries) > _const
				return 0;
			}
			return 1;
		}
		length += strlen( debug_flags[i]);
	}
	if(value == 0)
		return 0;
	debug_flagc+=1;
	debug_flags = (char**)realloc(debug_flags, debug_flagc * sizeof(char*));
	debug_flags[debug_flagc-1] = (char*)strdata;
	return 1;
}

extern int check_debug_flag(char const* strdata)
{
  int flg=0;
  int i;
  int containFailtrace = 0;
  for (i=0; i<debug_flagc; i++) {
    if (strcmp(debug_flags[i], "failtrace")==0) {
      containFailtrace=1;
      break;
  	}
  }
  if (strcmp(strdata,"none")==0 && (debug_none == 1 || containFailtrace==0 ) ) {
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

static void set_vectorization_limit(long limit)
{
  if(limit < 0) {
    vectorization_limit = 20;
    fprintf(stderr, "Warning, invalid vectorization limit (using default limit %ld\n", vectorization_limit);
  } else {
    vectorization_limit = limit;
  }
}

/*
 * @author adrpo
 * this fuctions sets the name that should be appended to the Corba IOR file dumped by omc
 * by default the file has the name:
 * - on Windows: /tmp/openmodelica.objid
 * - on Linux  : /tmp/openmodelica.user.objid
 * To this filename a ".$corba_session_name" is appended where
 * $corba_session_name is set in this function if omc is called:
 * ./omc +c=corba_session_name +d=interactiveCorba
 * By default the corba_session_name is set to "".
 * see more into corbaimpl.cpp function Corba__initialize
 */
int setCorbaSessionName(const char *name)
{
  int i;
  int len=strlen(name);
  if (len==0) return -1;
  if (0 == strcmp("mdt",name)) /* There is no MDT release that enables MetaModelica grammar */
    acceptedGrammar = GRAMMAR_METAMODELICA;
  corbaSessionName = strdup(name);
  return 0;
}

#define VERSION_OPT1        "++v"
#define VERSION_OPT2        "+version"
#define ANNOTATION_VERSION  "+annotationVersion"
#define TARGET              "+target"
#define METAMODELICA        "+g"
#define SHOW_ERROR_MESSAGES "+showErrorMessages"
#define SHOW_ANNOTATIONS    "+showAnnotations"
#define NO_SIMPLIFY         "+noSimplify"
/* Note: RML runtime eats arguments starting with -:
 * You need to use: omc -- --running-testsuite for it to work */
#define TESTSCRIPT          "--running-testsuite"

enum RTOpts__arg__result {
  ARG_CONSUME,
  ARG_SUCCESS,
  ARG_FAILURE
};

static enum RTOpts__arg__result RTOptsImpl__arg(const char* arg)
{
  int strLen_TARGET = strlen(TARGET);
  int strLen_METAMODELICA = strlen(METAMODELICA);
  int strLen_ANNNOTATION_VERSION = strlen(ANNOTATION_VERSION);
  int strLen_SHOW_ERROR_MESSAGES = strlen(SHOW_ERROR_MESSAGES);
  int strLen_SHOW_ANNOTATIONS = strlen(SHOW_ANNOTATIONS);
  int strLen_NO_SIMPLIFY = strlen(NO_SIMPLIFY);
  char *tmp;
  debug_none = 1;

  if (strcmp(arg,TESTSCRIPT) == 0) {
    running_testsuite = 1;
  } else if (strcmp(arg,VERSION_OPT1) == 0 || strcmp(arg,VERSION_OPT2) == 0) {
    version_request = 1;
  } else if(strncmp(arg,TARGET,strLen_TARGET) == 0) {
  	if (strlen(arg) >= strLen_TARGET && strcmp(&arg[strLen_TARGET], "=gcc") == 0)
  		simulation_code_target = "gcc";
  	else if (strlen(arg) >= strLen_TARGET && strcmp(&arg[strLen_TARGET], "=msvc") == 0)
  		simulation_code_target = "msvc";
  	else {
      fprintf(stderr, "# Wrong option: usage: omc [+target=gcc|msvc], default to 'gcc'.\n");
      return ARG_FAILURE;
    }
  } else if(strncmp(arg,METAMODELICA,strLen_METAMODELICA) == 0) {
    if (strlen(arg) >= strLen_METAMODELICA && strcmp(&arg[strLen_METAMODELICA], "=MetaModelica") == 0)
      acceptedGrammar = GRAMMAR_METAMODELICA;
    else if (strlen(arg) >= strLen_METAMODELICA && strcmp(&arg[strLen_METAMODELICA], "=Modelica") == 0)
      acceptedGrammar = GRAMMAR_MODELICA;
    else {
      fprintf(stderr, "# Wrong option: usage: omc [+g=Modelica|MetaModelica], default to 'Modelica'.\n");
      return ARG_FAILURE;
    }
  } else if(strncmp(arg,ANNOTATION_VERSION,strLen_ANNNOTATION_VERSION) == 0) {
    if (strlen(arg) >= strLen_ANNNOTATION_VERSION && strcmp(&arg[strLen_ANNNOTATION_VERSION], "=1.x") == 0)
      annotation_version = "1.x";
    else if (strlen(arg) >= strLen_ANNNOTATION_VERSION && strcmp(&arg[strLen_ANNNOTATION_VERSION], "=2.x") == 0)
      annotation_version = "2.x";
    else if (strlen(arg) >= strLen_ANNNOTATION_VERSION && strcmp(&arg[strLen_ANNNOTATION_VERSION], "=3.x") == 0)
      annotation_version = "3.x";
    else {
      fprintf(stderr, "# Wrong option: usage: omc [+annotationVersion=1.x|2.x|3.x], default to '2.x'.\n");
      return ARG_FAILURE;
    }
  } else if(strncmp(arg,SHOW_ERROR_MESSAGES,strLen_SHOW_ERROR_MESSAGES) == 0) {
    if (strlen(arg) == strLen_SHOW_ERROR_MESSAGES)
      showErrorMessages = 1;
    else {
      fprintf(stderr, "# Wrong option: usage: omc [+showErrorMessages], default to not show them.\n");
      return ARG_FAILURE;
    }
  } else if(strncmp(arg,SHOW_ANNOTATIONS,strLen_SHOW_ANNOTATIONS) == 0) {
    if (strlen(arg) == strLen_SHOW_ANNOTATIONS)
      showAnnotations = 1;
    else {
      fprintf(stderr, "# Wrong option: usage omc [+showAnnotations], default to not show them.\n");
      return ARG_FAILURE;
    }
  } else if(strncmp(arg,NO_SIMPLIFY,strLen_NO_SIMPLIFY) == 0) {
    if (strlen(arg) == strLen_NO_SIMPLIFY)
      noSimplify = 1;
    else {
      fprintf(stderr, "# Wrong option: usage: omc [+noSimplify], by default is to simplify.\n");
      return ARG_FAILURE;
    }
  } else if (arg[0] == '+') {
    if (strlen(arg) < 2) {
      fprintf(stderr, "# Unknown option: %s \n", arg);
      return ARG_FAILURE;
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
      if (arg[2] != '\0')
      {
        fprintf(stderr, "# Flag Usage:  +s or +showErrorMessages\n");
        return ARG_FAILURE;
      }
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
    case 'c':
      if (arg[2]!='=' || setCorbaSessionName(&(arg[3])) != 0)
      {
        fprintf(stderr, "# Flag Usage:  +c=corbaSessionName\n");
        return ARG_FAILURE;
      }
      break;
    case 'd':
      if (arg[2]=='d') {
        debug_flag_info = 1;
        break;
      }
	    if (arg[2]!='=' ||
	        set_debug_flags(&(arg[3])) != 0) {
        fprintf(stderr, "# Flag Usage:  +d=flg1,flg2,...\n");
        fprintf(stderr, "#              +dd for debug flag info\n");
        return ARG_FAILURE;
      }
      break;
    case 'n':
      if (arg[2] != '=') {
        fprintf(stderr, "# Flag Usage:  +n=<no. of proc>");
        return ARG_FAILURE;
      }
      nproc = atoi(&arg[3]);
      if (nproc == 0) {
        fprintf(stderr, "Error, integer value expected for number of processors.\n");
        return ARG_FAILURE;
      }
      break;
    case 'l':
      if (arg[2] != '=') {
        fprintf(stderr, "# Flag Usage:  +l=<latency value>");
        return ARG_FAILURE;
      }
      latency = (double)atoi(&arg[3]); /* ,NULL); */
      if (latency == 0.0) {
        fprintf(stderr, "Error, integer expected for latency.\n");
        return ARG_FAILURE;
      }
      break;
    case 'b':
      if (arg[2] != '=') {
        fprintf(stderr, "# Flag Usage:  +b=<bandwidth value>");
        return ARG_FAILURE;
      }
      bandwidth = (double)atoi(&arg[3]);
      if (bandwidth == 0.0) {
        fprintf(stderr, "Error, integer expected for bandwidth.\n");
        return ARG_FAILURE;
      }
      break;
	  // Which level of algebraic elimination to use.
    case 'e':
      if (arg[2] != '=') {
        fprintf(stderr, "# Flag Usage:  +e=<algebraic_elimination_level 0, 1, 2(default) or 3>");
        return ARG_FAILURE;
      }
      elimination_level = (int)atoi(&arg[3]);
      if (elimination_level < 0 || elimination_level > 3) {
        elimination_level = 2;
        fprintf(stderr, "Warning, wrong value of elimination level, will use default = %ld\n",elimination_level);
      }
      break;
    case 'i':
      if (arg[2] != '=') {
        fprintf(stderr, "# Flag Usage: +i=<fully qualified path to class to instantiate>\n");
        return ARG_FAILURE;
      }
      
      tmp = (char*)malloc(strlen(arg) * sizeof(char));
      strcpy(tmp, arg + 3);
      class_to_instantiate = tmp;
      break;
    // vectorization limit used by Static.crefVectorize.
    case 'v':
      if (arg[2] != '=') {
        fprintf(stderr, "# Flag Usage:  +v=<vectorization limit>");
        return ARG_FAILURE;
      }
      set_vectorization_limit(atol(&arg[3]));
      break;
    default:
      fprintf(stderr, "# Unknown option: %s\n", arg);
      return ARG_FAILURE;
    }
  } else {
    return ARG_SUCCESS;
  }
  return ARG_CONSUME;
}
