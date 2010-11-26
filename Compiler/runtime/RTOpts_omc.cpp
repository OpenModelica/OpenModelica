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

#include "modelica.h"

extern "C" {
#include "rtoptsimpl.c"

extern int showErrorMessages;

extern const char* corbaSessionName;

extern int RTOpts_debugFlag(const char* flag) {
  return check_debug_flag(flag)!=0;
}

extern modelica_metatype RTOpts_args(modelica_metatype args) {
  modelica_metatype res = mmc_mk_nil();

  while (MMC_GETHDR(args) != MMC_NILHDR)
  {
    modelica_metatype head = MMC_CAR(args);
    const char *arg = MMC_STRINGDATA(head);
    switch (RTOptsImpl__arg(arg)) {
    case ARG_FAILURE:
      MMC_THROW();
      break;
    case ARG_CONSUME:
      break;
    case ARG_SUCCESS:
      res = mmc_mk_cons(head, res);
      break;
    }
    args = MMC_CDR(args);
  }
  return listReverse(res);
}

extern int RTOpts_typeinfo() {
  return type_info;
}

extern int RTOpts_modelicaOutput() {
  return modelica_output;
}

extern int RTOpts_showAnnotations() {
  return showAnnotations;
}

extern void RTOpts_setShowAnnotations(int show) {
  showAnnotations = show;
}

extern int RTOpts_getNoSimplify() {
  return noSimplify;
}

extern void RTOpts_setNoSimplify(int val) {
  noSimplify = val;
}

extern int RTOpts_noProc() {
  return nproc;
}

extern double RTOpts_latency() {
  return latency;
}

extern int RTOpts_getRunningTestsuite() {
  return running_testsuite;
}

extern int RTOpts_level() {
  return elimination_level;
}

extern void RTOpts_setEliminationLevel(int level) {
  elimination_level = level;
}

extern const char* RTOpts_classToInstantiate() {
  return class_to_instantiate;
}

extern double RTOpts_bandwidth() {
  return bandwidth;
}

extern int RTOpts_getEvaluateParametersInAnnotations() {
  return evaluateParametersInAnnotations;
}

extern void RTOpts_setEvaluateParametersInAnnotations(int eval) {
  evaluateParametersInAnnotations = eval;
}

extern const char* RTOpts_getAnnotationVersion() {
  return annotation_version;
}

extern void RTOpts_setAnnotationVersion(const char* version) {
  annotation_version = version;
}

extern int RTOpts_vectorizationLimit() {
  return vectorization_limit;
}

extern void RTOpts_setVectorizationLimit(int limit) {
  vectorization_limit = limit;
}

extern int RTOpts_simulationCg() {
  return simulation_cg;
}

extern int RTOpts_silent() {
  return silent;
}

extern int RTOpts_splitArrays() {
  return split_arrays;
}

extern int RTOpts_versionRequest() {
  return version_request;
}

extern void RTOpts_setOrderConnections(int order) {
  orderConnections = order;
}

extern int RTOpts_orderConnections() {
  return orderConnections;
}
}
