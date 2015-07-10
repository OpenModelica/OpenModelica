// This file defines templates for transforming Modelica/MetaModelica code to FMU
// code. They are used in the code generator phase of the compiler to write
// target code.
//
// There are one root template intended to be called from the code generator:
// translateModel. These template do not return any
// result but instead write the result to files. All other templates return
// text and are used by the root templates (most of them indirectly).
//
// To future maintainers of this file:
//
// - A line like this
//     # var = "" /*BUFD*/
//   declares a text buffer that you can later append text to. It can also be
//   passed to other templates that in turn can append text to it. In the new
//   version of Susan it should be written like this instead:
//     let &var = buffer ""
//
// - A line like this
//     ..., Text var /*BUFP*/, ...
//   declares that a template takes a text buffer as input parameter. In the
//   new version of Susan it should be written like this instead:
//     ..., Text &var, ...
//
// - A line like this:
//     ..., var /*BUFC*/, ...
//   passes a text buffer to a template. In the new version of Susan it should
//   be written like this instead:
//     ..., &var, ...
//
// - Style guidelines:
//
//   - Try (hard) to limit each row to 80 characters
//
//   - Code for a template should be indented with 2 spaces
//
//     - Exception to this rule is if you have only a single case, then that
//       single case can be written using no indentation
//
//       This single case can be seen as a clarification of the input to the
//       template
//
//   - Code after a case should be indented with 2 spaces if not written on the
//     same line

package CodegenFMUCppHpcom



import interface SimCodeBackendTV;
import interface SimCodeTV;
import CodegenFMUCpp.*;
import CodegenCppHpcom.*;
import CodegenUtil;
import CodegenCpp;
import CodegenCppInit;

template translateModel(SimCode simCode, String FMUVersion, String FMUType)
 "Generates C++ code and Makefile for compiling an FMU of a Modelica model.
  Calls CodegenCpp.translateModel for the actual model code."
::=
  match simCode
    case SIMCODE(modelInfo = MODELINFO(__), makefileParams = MAKEFILE_PARAMS(__), hpcomData = HPCOMDATA(__)) then
      let guid = getUUIDStr()
      let target  = simulationCodeTarget()
      let stateDerVectorName = "__zDot"
      let &extraFuncs = buffer "" /*BUFD*/
      let &extraFuncsDecl = buffer "" /*BUFD*/

      let className = CodegenCpp.lastIdentOfPath(modelInfo.name)
      let numRealVars = numRealvarsHpcom(modelInfo, hpcomData.hpcOmMemory)
      let numIntVars = numIntvarsHpcom(modelInfo, hpcomData.hpcOmMemory)
      let numBoolVars = numBoolvarsHpcom(modelInfo, hpcomData.hpcOmMemory)
      let numPreVars = numPreVarsHpcom(modelInfo, hpcomData.hpcOmMemory)

      let()= textFile(CodegenCppInit.modelInitXMLFile(simCode, numRealVars, numIntVars, numBoolVars, FMUVersion, FMUType, guid, true, "hpcom cpp-runtime"), 'modelDescription.xml')
      let cpp = CodegenCpp.translateModel(simCode)
      let()= textFile(fmuWriteOutputHeaderFile(simCode , &extraFuncs , &extraFuncsDecl, ""),'OMCpp<%fileNamePrefix%>WriteOutput.h')
      let()= textFile(fmuModelHeaderFile(simCode, extraFuncs, extraFuncsDecl, "",guid, FMUVersion), 'OMCpp<%fileNamePrefix%>FMU.h')
      let()= textFile(fmuModelCppFile(simCode, extraFuncs, extraFuncsDecl, "",guid, FMUVersion), 'OMCpp<%fileNamePrefix%>FMU.cpp')
      //let()= textFile(modelInitXMLFile(simCode, numRealVars, numIntVars, numBoolVars, true, FMUVersion, FMUType, guid), '')
      // Def file is only used on windows, to define exported symbols
      //let()= textFile(fmudeffile(simCode, FMUVersion), '<%fileNamePrefix%>.def')
      let()= textFile(fmuMakefile(target,simCode, extraFuncs, extraFuncsDecl, "", FMUVersion), '<%fileNamePrefix%>_FMU.makefile')
      let()= textFile(fmuCalcHelperMainfile(simCode), 'OMCpp<%fileNamePrefix%>CalcHelperMain.cpp')

      let() = textFile(CodegenCpp.simulationCppFile(simCode, contextOther, updateHpcom(allEquations, whenClauses, simCode, &extraFuncs, &extraFuncsDecl, "", contextOther, stateDerVectorName, false),
                                         '<%numRealVars%>-1', '<%numIntVars%>-1', '<%numBoolVars%>-1', &extraFuncs, &extraFuncsDecl, className,
                                         additionalHpcomConstructorDefinitions(hpcomData.schedules),
                                         additionalHpcomConstructorBodyStatements(hpcomData.schedules, className, CodegenUtil.dotPath(modelInfo.name)),
                                         additionalHpcomDestructorBodyStatements(hpcomData.schedules),
                                         stateDerVectorName, false), 'OMCpp<%fileNamePrefix%>.cpp')

      let() = textFile(CodegenCpp.simulationHeaderFile(simCode ,contextOther, &extraFuncs, &extraFuncsDecl, "",
                      additionalHpcomIncludes(simCode, &extraFuncs, &extraFuncsDecl, className, false),
                      "",
                      additionalHpcomProtectedMemberDeclaration(simCode, &extraFuncs, &extraFuncsDecl, "", false),
                      CodegenCpp.memberVariableDefine(modelInfo, varToArrayIndexMapping, '<%numRealVars%>-1', '<%numIntVars%>-1', '<%numBoolVars%>-1', Flags.isSet(Flags.GEN_DEBUG_SYMBOLS), false),
                      CodegenCpp.memberVariableDefinePreVariables(modelInfo, varToArrayIndexMapping, '<%numRealVars%>-1', '<%numIntVars%>-1', '<%numBoolVars%>-1', Flags.isSet(Flags.GEN_DEBUG_SYMBOLS), false), false),
                      'OMCpp<%fileNamePrefix%>.h')
      ""
      // empty result of the top-level template .., only side effects
  end match
end translateModel;

template fmuMakefile(String target, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, String FMUVersion)
::=
  let type = getConfigString(HPCOM_CODE)

  let &additionalCFlags_GCC = buffer ""
  let &additionalCFlags_MSVC = buffer ""
  let &additionalLinkerFlags_GCC = buffer ""
  let &additionalLinkerFlags_MSVC = buffer ""

  let &additionalLinkerFlags_GCC += if boolOr(stringEq(type,"pthreads"), stringEq(type,"pthreads_spin")) then " -lboost_thread" else ""

  <<
  <%CodegenCppHpcom.getAdditionalMakefileFlags(additionalCFlags_GCC, additionalCFlags_MSVC, additionalLinkerFlags_GCC, additionalLinkerFlags_MSVC)%>
  <%CodegenFMUCpp.fmuMakefile(target, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, FMUVersion, additionalLinkerFlags_GCC, additionalLinkerFlags_MSVC, additionalCFlags_GCC, additionalCFlags_MSVC)%>
  >>
end fmuMakefile;

annotation(__OpenModelica_Interface="backend");
end CodegenFMUCppHpcom;

// vim: filetype=susan sw=2 sts=2