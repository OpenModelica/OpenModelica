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

#include "rtoptsimpl.c"
#include "rml.h"

void RTOpts_5finit(void)
{
}

RML_BEGIN_LABEL(RTOpts__args)
{
  void *args = rmlA0;
  void *res = (void*)mk_nil();

  rmlA0 = mk_nil();  /* set to nil! */
  while (RML_GETHDR(args) != RML_NILHDR)
  {
    char *arg = RML_STRINGDATA(RML_CAR(args));
    switch (RTOptsImpl__arg(arg)) {
    case ARG_FAILURE:
      RML_TAILCALLK(rmlFC);
      break;
    case ARG_CONSUME:
      break;
    case ARG_SUCCESS:
      res = (void*)mk_cons(RML_CAR(args), res);
      break;
    }
    args = RML_CDR(args);
  }
  rmlA0 = res;
  RML_TAILCALLQ(RML__listReverse,1);
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
	long level = (long)RML_IMMEDIATE(RML_UNTAGFIXNUM(rmlA0));
	elimination_level = level;
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(RTOpts__setDebugFlag)
{
  void *str = rmlA0;
  //int level = 1;
  long level = (long)RML_IMMEDIATE(RML_UNTAGFIXNUM(rmlA1));
  char *strdata = RML_STRINGDATA(str);
  level = set_debug_flag(strdata,level);
  rmlA0 = RML_PRIM_MKBOOL(level);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(RTOpts__debugFlag)
{
    void *str = rmlA0;
    char *strdata = RML_STRINGDATA(str);
    int flg = check_debug_flag(strdata);
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

RML_BEGIN_LABEL(RTOpts__simulationCodeTarget)
{
  rmlA0 = mk_scon(simulation_code_target);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(RTOpts__classToInstantiate)
{
  rmlA0 = mk_scon(class_to_instantiate);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(RTOpts__versionRequest)
{
  rmlA0 = RML_PRIM_MKBOOL(version_request);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

int accept_meta_modelica_grammar()
{
  return acceptedGrammar == GRAMMAR_METAMODELICA;
}

/*
 * adrpo 2007-06-11
 * flag for accepting only Modelica grammar or also MetaModelica grammar
 */
RML_BEGIN_LABEL(RTOpts__acceptMetaModelicaGrammar)
{
    if (accept_meta_modelica_grammar())
        rmlA0 = RML_PRIM_MKBOOL(RML_TRUE);
    else
        rmlA0 = RML_PRIM_MKBOOL(RML_FALSE);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/*
 * adrpo 2008-11-28
 */
RML_BEGIN_LABEL(RTOpts__getAnnotationVersion)
{
  rmlA0 = mk_scon(annotation_version);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

/*
 * adrpo 2008-11-28
 */
RML_BEGIN_LABEL(RTOpts__setAnnotationVersion)
{
  char* str = strdup(RML_STRINGDATA(rmlA0));
  if (strcmp(annotation_version, "1.x") == 0 ||
      strcmp(annotation_version, "2.x") == 0 ||
      strcmp(annotation_version, "3.x") == 0)
  {
    annotation_version = str;
    RML_TAILCALLK(rmlSC);
  }
  RML_TAILCALLK(rmlFC);
}
RML_END_LABEL


/*
 * adrpo 2008-12-13
 */
RML_BEGIN_LABEL(RTOpts__setNoSimplify)
{
  noSimplify = RML_UNTAGFIXNUM(rmlA0);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL


/*
 * adrpo 2008-12-13
 */
RML_BEGIN_LABEL(RTOpts__getNoSimplify)
{
  rmlA0 = noSimplify?RML_TRUE:RML_FALSE;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(RTOpts__getRunningTestsuite)
{
  rmlA0 = running_testsuite?RML_TRUE:RML_FALSE;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(RTOpts__vectorizationLimit)
{
  rmlA0 = mk_icon(vectorization_limit);
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(RTOpts__setVectorizationLimit)
{
  long limit = (long)RML_IMMEDIATE(RML_UNTAGFIXNUM(rmlA0));
  set_vectorization_limit(limit);
	RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(RTOpts__showAnnotations)
{
  rmlA0 = showAnnotations ? RML_TRUE : RML_FALSE;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(RTOpts__setShowAnnotations)
{
  showAnnotations = RML_UNTAGFIXNUM(rmlA0);
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
