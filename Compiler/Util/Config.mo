/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package Config
" file:        Config.mo
  package:     Config
  description: Functions for configurating the compiler.


  This module contains functions which are mostly just wrappers for the Flags
  module, which makes it easier to manipulate the configuration of the compiler."

public import Flags;
protected import Error;
protected import System;

public

type LanguageStandard = enumeration('1.x', '2.x', '3.0', '3.1', '3.2', '3.3', latest)
  "Defines the various modelica language versions that OMC can use.";

public function typeinfo "+t"
  output Boolean outBoolean;
algorithm
  outBoolean := Flags.getConfigBool(Flags.TYPE_INFO);
end typeinfo;

public function splitArrays
  output Boolean outBoolean;
algorithm
  outBoolean := not Flags.getConfigBool(Flags.KEEP_ARRAYS);
end splitArrays;

public function modelicaOutput
  output Boolean outBoolean;
algorithm
  outBoolean := Flags.getConfigBool(Flags.MODELICA_OUTPUT);
end modelicaOutput;

public function noProc
  output Integer outInteger;
algorithm
  outInteger := noProcWork(Flags.getConfigInt(Flags.NUM_PROC));
end noProc;

protected function noProcWork
  input Integer inProc;
  output Integer outInteger;
algorithm
  outInteger := match inProc
    case 0  then System.numProcessors();
    else inProc;
  end match;
end noProcWork;

public function latency
  output Real outReal;
algorithm
  outReal := Flags.getConfigReal(Flags.LATENCY);
end latency;

public function bandwidth
  output Real outReal;
algorithm
  outReal := Flags.getConfigReal(Flags.BANDWIDTH);
end bandwidth;

public function simulationCg
  output Boolean outBoolean;
algorithm
  outBoolean := Flags.getConfigBool(Flags.SIMULATION_CG);
end simulationCg;

public function simulationCodeTarget
"@author: adrpo
 returns: 'gcc' or 'msvc'
 usage: omc [+target=gcc|msvc], default to 'gcc'."
  output String outCodeTarget;
algorithm
  outCodeTarget := Flags.getConfigString(Flags.TARGET);
end simulationCodeTarget;

public function classToInstantiate
  output String modelName;
algorithm
  modelName := Flags.getConfigString(Flags.INST_CLASS);
end classToInstantiate;

public function silent
  output Boolean outBoolean;
algorithm
  outBoolean := Flags.getConfigBool(Flags.SILENT);
end silent;

public function versionRequest
  output Boolean outBoolean;
algorithm
  outBoolean := Flags.getConfigBool(Flags.SHOW_VERSION);
end versionRequest;

public function helpRequest
  output Boolean outBoolean;
algorithm
  outBoolean := not stringEq(Flags.getConfigString(Flags.HELP), "");
end helpRequest;

public function acceptedGrammar
"returns: the flag number representing the accepted grammer. Instead of using
 booleans. This way more extensions can be added easily.
 usage: omc [+g=Modelica|MetaModelica|ParModelica|Optimica], default to 'Modelica'."
  output Integer outGrammer;
algorithm
  outGrammer := Flags.getConfigEnum(Flags.GRAMMAR);
end acceptedGrammar;

public function acceptMetaModelicaGrammar
"returns: true if MetaModelica grammar is accepted or false otherwise
 usage: omc [+g=Modelica|MetaModelica|ParModelica|Optimica], default to 'Modelica'."
  output Boolean outBoolean;
algorithm
  outBoolean := intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.METAMODELICA);
end acceptMetaModelicaGrammar;

public function acceptParModelicaGrammar
"returns: true if ParModelica grammar is accepted or false otherwise
 usage: omc [+g=Modelica|MetaModelica|ParModelica|Optimica], default to 'Modelica'."
  output Boolean outBoolean;
algorithm
  outBoolean := intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.PARMODELICA);
end acceptParModelicaGrammar;

public function acceptOptimicaGrammar
"returns: true if Optimica grammar is accepted or false otherwise
 usage: omc [+g=Modelica|MetaModelica|ParModelica|Optimica], default to 'Modelica'."
  output Boolean outBoolean;
algorithm
  outBoolean := intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.OPTIMICA);
end acceptOptimicaGrammar;

public function acceptPDEModelicaGrammar
"returns: true if Optimica grammar is accepted or false otherwise
 usage: omc [+g=Modelica|MetaModelica|ParModelica|Optimica], default to 'Modelica'."
  output Boolean outBoolean;
algorithm
  outBoolean := intEq(Flags.getConfigEnum(Flags.GRAMMAR), Flags.PDEMODELICA);
end acceptPDEModelicaGrammar;

public function getAnnotationVersion
"returns what flag was given at start
     omc [+annotationVersion=3.x]
   or via the API
     setAnnotationVersion(\"3.x\");
   for annotations: 1.x or 2.x or 3.x"
  output String annotationVersion;
algorithm
  annotationVersion := Flags.getConfigString(Flags.ANNOTATION_VERSION);
end getAnnotationVersion;

public function setAnnotationVersion
"setAnnotationVersion(\"3.x\");
   for annotations: 1.x or 2.x or 3.x"
  input String annotationVersion;
algorithm
  Flags.setConfigString(Flags.ANNOTATION_VERSION, annotationVersion);
end setAnnotationVersion;

public function getNoSimplify
"returns what flag was given at start
   omc [+noSimplify]
 or via the API
   setNoSimplify(true|false);"
  output Boolean noSimplify;
algorithm
  noSimplify := Flags.getConfigBool(Flags.NO_SIMPLIFY);
end getNoSimplify;

public function setNoSimplify
  input Boolean noSimplify;
algorithm
  Flags.setConfigBool(Flags.NO_SIMPLIFY, noSimplify);
end setNoSimplify;

public function vectorizationLimit
  "Returns the vectorization limit that is used to determine how large an array
  can be before it no longer is expanded by Static.crefVectorize."
  output Integer limit;
algorithm
  limit := Flags.getConfigInt(Flags.VECTORIZATION_LIMIT);
end vectorizationLimit;

public function setVectorizationLimit
  "Sets the vectorization limit, see vectorizationLimit above."
  input Integer limit;
algorithm
  Flags.setConfigInt(Flags.VECTORIZATION_LIMIT, limit);
end setVectorizationLimit;

public function getDefaultOpenCLDevice
  "Returns the id for the default OpenCL device to be used."
  output Integer defdevid;
algorithm
  defdevid := Flags.getConfigInt(Flags.DEFAULT_OPENCL_DEVICE);
end getDefaultOpenCLDevice;

public function setDefaultOpenCLDevice
  "Sets the default OpenCL device to be used."
  input Integer defdevid;
algorithm
  Flags.setConfigInt(Flags.DEFAULT_OPENCL_DEVICE, defdevid);
end setDefaultOpenCLDevice;

public function showAnnotations
  output Boolean show;
algorithm
  show := Flags.getConfigBool(Flags.SHOW_ANNOTATIONS);
end showAnnotations;

public function setShowAnnotations
  input Boolean show;
algorithm
  Flags.setConfigBool(Flags.SHOW_ANNOTATIONS, show);
end setShowAnnotations;

public function showStartOrigin
  output Boolean show;
algorithm
  show := Flags.isSet(Flags.SHOW_START_ORIGIN);
end showStartOrigin;

public function getRunningTestsuite
  output Boolean runningTestsuite;
algorithm
  runningTestsuite := not stringEq(Flags.getConfigString(Flags.RUNNING_TESTSUITE),"");
end getRunningTestsuite;

public function getRunningWSMTestsuite
  output Boolean runningTestsuite;
algorithm
  runningTestsuite := Flags.getConfigBool(Flags.RUNNING_WSM_TESTSUITE);
end getRunningWSMTestsuite;

public function getRunningTestsuiteFile
  output String tempFile "File containing a list of files created by running this test so rtest can remove them after";
algorithm
  tempFile := Flags.getConfigString(Flags.RUNNING_TESTSUITE);
end getRunningTestsuiteFile;

public function getEvaluateParametersInAnnotations
"@author: adrpo
  flag to tell us if we should evaluate parameters in annotations"
  output Boolean shouldEvaluate;
algorithm
  shouldEvaluate := Flags.getConfigBool(Flags.EVAL_PARAMS_IN_ANNOTATIONS);
end getEvaluateParametersInAnnotations;

public function setEvaluateParametersInAnnotations
"@author: adrpo
  flag to tell us if we should evaluate parameters in annotations"
  input Boolean shouldEvaluate;
algorithm
  Flags.setConfigBool(Flags.EVAL_PARAMS_IN_ANNOTATIONS, shouldEvaluate);
end setEvaluateParametersInAnnotations;

public function orderConnections
  output Boolean show;
algorithm
  show := Flags.getConfigBool(Flags.ORDER_CONNECTIONS);
end orderConnections;

public function setOrderConnections
  input Boolean show;
algorithm
  Flags.setConfigBool(Flags.ORDER_CONNECTIONS, show);
end setOrderConnections;

public function getPreOptModules
  output list<String> outStringLst;
algorithm
  outStringLst := Flags.getConfigStringList(Flags.PRE_OPT_MODULES);
end getPreOptModules;

public function getPostOptModules
  output list<String> outStringLst;
algorithm
  outStringLst := Flags.getConfigStringList(Flags.POST_OPT_MODULES);
end getPostOptModules;

public function getInitOptModules
  output list<String> outStringLst;
algorithm
  outStringLst := Flags.getConfigStringList(Flags.INIT_OPT_MODULES);
end getInitOptModules;

public function setPreOptModules
  input list<String> inStringLst;
algorithm
  Flags.setConfigStringList(Flags.PRE_OPT_MODULES, inStringLst);
end setPreOptModules;

public function setPostOptModules
  input list<String> inStringLst;
algorithm
  Flags.setConfigStringList(Flags.POST_OPT_MODULES, inStringLst);
end setPostOptModules;

public function getIndexReductionMethod
  output String outString;
algorithm
  outString := Flags.getConfigString(Flags.INDEX_REDUCTION_METHOD);
end getIndexReductionMethod;

public function setIndexReductionMethod
  input String inString;
algorithm
  Flags.setConfigString(Flags.INDEX_REDUCTION_METHOD, inString);
end setIndexReductionMethod;

public function getCheapMatchingAlgorithm
  output Integer outInteger;
algorithm
  outInteger := Flags.getConfigInt(Flags.CHEAPMATCHING_ALGORITHM);
end getCheapMatchingAlgorithm;

public function setCheapMatchingAlgorithm
  input Integer inInteger;
algorithm
  Flags.setConfigInt(Flags.CHEAPMATCHING_ALGORITHM, inInteger);
end setCheapMatchingAlgorithm;

public function getMatchingAlgorithm
  output String outString;
algorithm
  outString := Flags.getConfigString(Flags.MATCHING_ALGORITHM);
end getMatchingAlgorithm;

public function setMatchingAlgorithm
  input String inString;
algorithm
  Flags.setConfigString(Flags.MATCHING_ALGORITHM, inString);
end setMatchingAlgorithm;

public function getTearingMethod
  output String outString;
algorithm
  outString := Flags.getConfigString(Flags.TEARING_METHOD);
end getTearingMethod;

public function setTearingMethod
  input String inString;
algorithm
  Flags.setConfigString(Flags.TEARING_METHOD, inString);
end setTearingMethod;

public function getTearingHeuristic
  output String outString;
algorithm
  outString := Flags.getConfigString(Flags.TEARING_HEURISTIC);
end getTearingHeuristic;

public function setTearingHeuristic
  input String inString;
algorithm
  Flags.setConfigString(Flags.TEARING_HEURISTIC, inString);
end setTearingHeuristic;

public function simCodeTarget "Default is set by +simCodeTarget=C"
  output String target;
algorithm
  target := Flags.getConfigString(Flags.SIMCODE_TARGET);
end simCodeTarget;

public function setsimCodeTarget
  input String inString;
algorithm
  Flags.setConfigString(Flags.SIMCODE_TARGET, inString);
end setsimCodeTarget;

public function getLanguageStandard
  output LanguageStandard outStandard;
algorithm
  outStandard := intLanguageStandard(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD));
end getLanguageStandard;

public function setLanguageStandard
  input LanguageStandard inStandard;
algorithm
  Flags.setConfigEnum(Flags.LANGUAGE_STANDARD, languageStandardInt(inStandard));
end setLanguageStandard;

public function languageStandardAtLeast
  input LanguageStandard inStandard;
  output Boolean outRes;
protected
  LanguageStandard std;
algorithm
  std := getLanguageStandard();
  outRes := intGe(languageStandardInt(std), languageStandardInt(inStandard));
end languageStandardAtLeast;

public function languageStandardAtMost
  input LanguageStandard inStandard;
  output Boolean outRes;
protected
  LanguageStandard std;
algorithm
  std := getLanguageStandard();
  outRes := intLe(languageStandardInt(std), languageStandardInt(inStandard));
end languageStandardAtMost;

protected function languageStandardInt
  input LanguageStandard inStandard;
  output Integer outValue;
protected
  constant Integer lookup[LanguageStandard] = array(10, 20, 30, 31, 32, 33, 1000);
algorithm
  outValue := lookup[inStandard];
end languageStandardInt;

protected function intLanguageStandard
  input Integer inValue;
  output LanguageStandard outStandard;
algorithm
  outStandard := match(inValue)
    case 10 then LanguageStandard.'1.x';
    case 20 then LanguageStandard.'2.x';
    case 30 then LanguageStandard.'3.0';
    case 31 then LanguageStandard.'3.1';
    case 32 then LanguageStandard.'3.2';
    case 33 then LanguageStandard.'3.3';
    case 1000 then LanguageStandard.latest;
  end match;
end intLanguageStandard;

public function languageStandardString
  input LanguageStandard inStandard;
  output String outString;
protected
  constant String lookup[LanguageStandard] = array("1.x","2.x","3.0","3.1","3.2","3.3","3.3" /*Change this to latest version if you add more versions!*/);
algorithm
  outString := lookup[inStandard];
end languageStandardString;

public function setLanguageStandardFromMSL
  input String inLibraryName;
protected
  LanguageStandard current_std;
algorithm
  current_std := getLanguageStandard();
  if current_std <> LanguageStandard.latest then
    // If we selected an MSL version manually, we respect that choice.
    return;
  end if;

  _ := matchcontinue(inLibraryName)
    local
      String version, new_std_str;
      LanguageStandard new_std;
      Boolean show_warning;

    case _
      algorithm
        "Modelica" :: version :: _ := System.strtok(inLibraryName, " ");
        new_std := versionStringToStd(version);
        if new_std==current_std then
          return;
        end if;
        setLanguageStandard(new_std);
        show_warning := hasLanguageStandardChanged(current_std);
        new_std_str := languageStandardString(new_std);
        if show_warning then
          Error.addMessage(Error.CHANGED_STD_VERSION, {new_std_str, version});
        end if;
      then ();

    else ();
  end matchcontinue;
end setLanguageStandardFromMSL;

protected function hasLanguageStandardChanged
  input LanguageStandard inOldStandard;
  output Boolean outHasChanged;
algorithm
  // If the old standard wasn't set by the user, then we consider it to have
  // changed only if the new standard is 3.0 or less. This is to avoid
  // printing a notice if the user loads e.g. MSL 3.1.
  outHasChanged := languageStandardAtMost(LanguageStandard.'3.0');
end hasLanguageStandardChanged;

public function versionStringToStd
  input String inVersion;
  output LanguageStandard outStandard;
protected
  list<String> version;
algorithm
  version := System.strtok(inVersion, ".");
  outStandard := versionStringToStd2(version);
end versionStringToStd;

protected function versionStringToStd2
  input list<String> inVersion;
  output LanguageStandard outStandard;
algorithm
  outStandard := match(inVersion)
    case "1" :: _ then LanguageStandard.'1.x';
    case "2" :: _ then LanguageStandard.'2.x';
    case "3" :: "0" :: _ then LanguageStandard.'3.0';
    case "3" :: "1" :: _ then LanguageStandard.'3.1';
    case "3" :: "2" :: _ then LanguageStandard.'3.2';
    case "3" :: "3" :: _ then LanguageStandard.'3.3';
    case "3" :: _ then LanguageStandard.latest;
  end match;
end versionStringToStd2;

public function showErrorMessages
  output Boolean outShowErrorMessages;
algorithm
  outShowErrorMessages := Flags.getConfigBool(Flags.SHOW_ERROR_MESSAGES);
end showErrorMessages;

public function scalarizeMinMax
  output Boolean outScalarizeMinMax;
algorithm
  outScalarizeMinMax := Flags.getConfigBool(Flags.SCALARIZE_MINMAX);
end scalarizeMinMax;

public function scalarizeBindings
  output Boolean outScalarizeBindings;
algorithm
  outScalarizeBindings := Flags.getConfigBool(Flags.SCALARIZE_BINDINGS);
end scalarizeBindings;

public function intEnumConversion
  output Boolean outIntEnumConversion;
algorithm
  outIntEnumConversion := Flags.getConfigBool(Flags.INT_ENUM_CONVERSION);
end intEnumConversion;

public function profileSome
  output Boolean outBoolean;
algorithm
  outBoolean := 0==System.strncmp(Flags.getConfigString(Flags.PROFILING_LEVEL), "blocks", 6);
end profileSome;

public function profileAll
  output Boolean outBoolean;
algorithm
  outBoolean := stringEq(Flags.getConfigString(Flags.PROFILING_LEVEL), "all");
end profileAll;

public function profileHtml
  output Boolean outBoolean;
algorithm
  outBoolean := stringEq(Flags.getConfigString(Flags.PROFILING_LEVEL), "blocks+html");
end profileHtml;

public function profileFunctions
  output Boolean outBoolean;
algorithm
  outBoolean := not stringEq(Flags.getConfigString(Flags.PROFILING_LEVEL), "none");
end profileFunctions;

public function dynamicTearing
  output String outString;
algorithm
  outString := Flags.getConfigString(Flags.DYNAMIC_TEARING);
end dynamicTearing;

public function ignoreCommandLineOptionsAnnotation
  output Boolean outBoolean;
algorithm
  outBoolean := Flags.getConfigBool(Flags.IGNORE_COMMAND_LINE_OPTIONS_ANNOTATION);
end ignoreCommandLineOptionsAnnotation;

annotation(__OpenModelica_Interface="util");
end Config;
