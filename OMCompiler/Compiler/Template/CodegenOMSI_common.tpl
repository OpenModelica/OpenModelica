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

 package CodegenOMSI_common
" file:        CodegenOMSICcommon.tpl
  package:     CodegenOMSIC_common
  description: Code generation using Susan templates for
               OpenModelica Simulation Inferface (OMSI) used for generating C and C++ code
"

import interface SimCodeTV;
import interface SimCodeBackendTV;

import CodegenOMSIC_Equations;
import CodegenUtil;
import CodegenUtilSimulation;
import CodegenCFunctions;
import CodegenFMU;


/* public */
template generateFMUModelDescriptionFile(SimCode simCode, String guid, String FMUVersion, String FMUType, list<String> sourceFiles, String fileName)
"Generate modelDescription.xml.
 ToDo: Workaround since runTplWriteFile from .mo file loses some spaces."
::=
  let content = CodegenFMU.fmuModelDescriptionFile(simCode, guid, FMUVersion, FMUType, sourceFiles)
  let () = textFile(content, fileName)
  <<>>
end generateFMUModelDescriptionFile;


template generateEquationsCode (SimCode simCode, String FileNamePrefix)
"Entrypoint to generate all Code for linear systems.
 Code is generated directly into files"
::=
  let modelNameOMSIC = makeC89Identifier(FileNamePrefix)
  match simCode
  case SIMCODE(modelInfo = MODELINFO(__),fileNamePrefix=fileNamePrefix, fullPathPrefix=fullPathPrefix,
               omsiData=omsiData as SOME(OMSI_DATA(simulation=simulation as OMSI_FUNCTION(__),
               initialization=initialization as OMSI_FUNCTION(__)))) then

    /* generate file for algebraic systems in simulation problem */


    let modelNamePrefix =   modelNameOMSIC



    let content = generateOmsiFunctionCode(simulation, modelNamePrefix,"","sim_eqns")
    let () = textFile(content, fullPathPrefix+"/"+fileNamePrefix+"_sim_eqns.c")



    let content = generateOmsiFunctionCode(initialization, modelNamePrefix,"", "init_eqns")
    let () = textFile(content, fullPathPrefix+"/"+fileNamePrefix+"_init_eqns.c")


  <<>>
end generateEquationsCode;


template generateOmsiFunctionCode(OMSIFunction omsiFunction, String FileNamePrefix, String modelFunctionnamePrefixStr, String omsiName)
"Generates content for file for all equations, containing equation evaluations for all systems"
::=
  let &includes = buffer ""
  let &evaluationCode = buffer ""
  let &functionCall = buffer ""
  let &functionPrototypes = buffer ""

  let fileNamePrefix = CodegenUtilSimulation.fileNamePrefix(getSimCode())
  let fullPathPrefix = CodegenUtilSimulation.fullPathPrefix(getSimCode())

  let initializationCode = generateInitalizationOMSIFunction(omsiFunction, "allEqns", FileNamePrefix,modelFunctionnamePrefixStr, &functionPrototypes, &includes, false, omsiName)
  let _ = generateOmsiFunctionCode_inner(omsiFunction, FileNamePrefix, modelFunctionnamePrefixStr,omsiName, &includes, &evaluationCode, &functionCall, "", &functionPrototypes, omsiName)

  // generate header file
  let &functionPrototypes +='omsi_status <%FileNamePrefix%>_<%omsiName%>_allEqns(struct omsi_function_t* simulation, const omsi_values* model_vars_and_params, void* data);<%\n%>'


  let headerFileName =     '<%fileNamePrefix%>_<%omsiName%>'


  let headerFileContent = generateCodeHeader(FileNamePrefix, &includes, headerFileName, &functionPrototypes)
  let () = textFile(headerFileContent, fullPathPrefix+"/"+headerFileName+".h")



  match omsiFunction
    case SimCode.OMSI_FUNCTION(__) then
    <<
    <%insertCopyrightOpenModelica()%>
      /* All Equations Code */
      #include "<%headerFileName%>.h"
    #if defined(__cplusplus)
    extern "C" {
    #endif

    /* Instantiation of omsi_function_t */
    <%initializationCode%>

    /* Evaluation functions for each equation */
    <%evaluationCode%>


    /* Equations evaluation */
    omsi_status <%FileNamePrefix%>_<%omsiName%>_allEqns(struct omsi_function_t* <%omsiName%>, const omsi_values* model_vars_and_params, void* data){


      /* Variables */
      omsi_status status, new_status;

      status = omsi_ok;
      <%if not nAlgebraicSystems then "new_status = omsi_ok;"%>

      <%functionCall%>

      return status;
    }

    #if defined(__cplusplus)
    }
    #endif
    <%\n%>
    >>
  /* leave a newline at the end of file to get rid of the warning */
end generateOmsiFunctionCode;


template lastIdentOfPath(Path modelName)
"Helper function. Returns last ident of given path."
::=
  match modelName
  case QUALIFIED(__) then lastIdentOfPath(path)
  case IDENT(__)     then name
  case FULLYQUALIFIED(__) then lastIdentOfPath(path)
end lastIdentOfPath;


template generateOmsiFunctionCode_inner(OMSIFunction omsiFunction, String FileNamePrefix,String modelFunctionnamePrefixStr, String funcCallArgName, Text &includes, Text &evaluationCode, Text &functionCall, Text &residualCall, Text &functionPrototypes, String omsiName)
"Generates function code for each individual equation or system of equations using CodegenOMSIC_Equations."
::=
  let fileNamePrefix = CodegenUtilSimulation.fileNamePrefix(getSimCode())
  let fullPathPrefix = CodegenUtilSimulation.fullPathPrefix(getSimCode())

  match omsiFunction
  case OMSI_FUNCTION(context=context as SimCodeFunction.OMSI_CONTEXT(__)) then
    let _ = (equations |> eqsystem hasindex i0 =>
      match eqsystem
      case SES_SIMPLE_ASSIGN(__) then
        let &evaluationCode += CodegenOMSIC_Equations.generateEquationFunction(eqsystem, FileNamePrefix,modelFunctionnamePrefixStr, context, &functionPrototypes) +"\n"
        let &functionCall += CodegenOMSIC_Equations.equationCall(eqsystem, FileNamePrefix,modelFunctionnamePrefixStr, '<%funcCallArgName%>, model_vars_and_params', omsiName) +"\n"
        <<>>
      case SES_RESIDUAL(__) then
        let &evaluationCode += CodegenOMSIC_Equations.generateEquationFunction(eqsystem, FileNamePrefix, modelFunctionnamePrefixStr,context, &functionPrototypes) +"\n"
        let &residualCall += CodegenOMSIC_Equations.equationCall(eqsystem, FileNamePrefix,modelFunctionnamePrefixStr, '<%funcCallArgName%>, model_vars_and_params, &res[i++]', omsiName) +"\n"
        <<>>
      case algSystem as SES_ALGEBRAIC_SYSTEM(__) then
        let &includes += <<#include "<%fileNamePrefix%>_<%omsiName%>_algSyst_<%algSysIndex%>.h"<%\n%>>>
        let &functionCall += CodegenOMSIC_Equations.equationCall(eqsystem, FileNamePrefix, modelFunctionnamePrefixStr,'&<%funcCallArgName%>->algebraic_system_t[<%algSysIndex%>], model_vars_and_params, <%omsiName%>->function_vars', omsiName) +"\n"
        // write own file for each algebraic system
        let content = generateOmsiAlgSystemCode(eqsystem, FileNamePrefix, omsiName)
        let () = textFile(content, fullPathPrefix+"/"+fileNamePrefix+"_"+omsiName+"_algSyst_"+ algSystem.algSysIndex + ".c")
        <<>>
      case whenEq as SES_WHEN(__) then
        let &evaluationCode += CodegenOMSIC_Equations.generateEquationFunction(eqsystem, FileNamePrefix,modelFunctionnamePrefixStr, context, &functionPrototypes) +"\n"
        let &functionCall += CodegenOMSIC_Equations.equationCall(eqsystem, FileNamePrefix,modelFunctionnamePrefixStr, '<%funcCallArgName%>, model_vars_and_params', omsiName) +"\n"
        <<>>
      else
        // NOT IMPLEMENTED YET
        // ToDo: add yl
        <<
        TODO: Equation not implemented
        >>
      end match
    )

  <<>>
end generateOmsiFunctionCode_inner;


template generateOmsiMemberFunction(OMSIFunction omsiFunction, String FileNamePrefix,String FunctionnamePrefix)
"Generates function code for each individual equation or system of equations using CodegenOMSIC_Equations for C++."
::=
  let &evaluationCode = buffer ""
  let &functionPrototypes = buffer ""
  match omsiFunction
  case OMSI_FUNCTION(context=context as SimCodeFunction.OMSI_CONTEXT(__)) then
    let _ = (equations |> eqsystem hasindex i0 =>
      match eqsystem
       case SES_SIMPLE_ASSIGN(__) then
        let &evaluationCode += CodegenOMSIC_Equations.generateEquationFunction(eqsystem, FileNamePrefix,FunctionnamePrefix, context, &functionPrototypes) +"\n"
        << >>
      case SES_RESIDUAL(__) then
        let &evaluationCode += CodegenOMSIC_Equations.generateEquationFunction(eqsystem, FileNamePrefix, FunctionnamePrefix,context, &functionPrototypes) +"\n"
        <<>>
      case algSystem as SES_ALGEBRAIC_SYSTEM(__) then
        "TODO: Equation  SES_ALGEBRAIC_SYSTEM not implemented yet"

      case whenEq as SES_WHEN(__) then
        let &evaluationCode += CodegenOMSIC_Equations.generateEquationFunction(eqsystem, FileNamePrefix,FunctionnamePrefix, context, &functionPrototypes) +"\n"
        <<>>
      else
        // NOT IMPLEMENTED YET
        // ToDo: add yl
        <<
        TODO: Equation not implemented
        >>
      end match
    )

  <<
    virtual omsi_status initialize_omsi_<%FunctionnamePrefix%>_functions (omsi_function_t* omsi_function);
    virtual omsi_status omsi_<%FunctionnamePrefix%>All(omsi_function_t* simulation, const omsi_values* model_vars_and_params, void* data);
    <%functionPrototypes%>
  >>
end generateOmsiMemberFunction;


template generateOmsiAlgSystemCode (SimEqSystem equationSystem, String FileNamePrefix, String omsiName)
"Returns code for an algebraic system and creates associated derMat file and header files."
::=
  let &includes = buffer ""
  let &evaluationCode = buffer ""
  let &functionCall = buffer ""
  let &residualCall = buffer ""
  let &derivativeMatrix = buffer ""
  let &functionPrototypes = buffer ""

  let fileNamePrefix = CodegenUtilSimulation.fileNamePrefix(getSimCode())
  let fullPathPrefix = CodegenUtilSimulation.fullPathPrefix(getSimCode())

  match equationSystem
  // Case for an algebraic system without derivaitve matrix
  case algSystem as SES_ALGEBRAIC_SYSTEM(matrix = NONE()) then
    let &includes += <<#include <omsi_solve_alg_system.h><%\n%>>>
    let initlaizationFunction = generateInitalizationAlgSystem(equationSystem, FileNamePrefix, &functionPrototypes, &includes, omsiName)
    let _ = generateOmsiFunctionCode_inner(residual, FileNamePrefix,"", "this_function", &includes, &evaluationCode, &functionCall, &residualCall, &functionPrototypes, omsiName)

    let equationInfos = CodegenUtilSimulation.dumpEqs(fill(equationSystem,1))

    // no need to generate jacobian matrix files
    let matrixString = ""

    // generate algebraic system header file
    let &functionPrototypes +=
      <<
      omsi_status <%FileNamePrefix%>_<%omsiName%>_resFunction_<%algSystem.algSysIndex%> (omsi_function_t* this_function, const omsi_values* model_vars_and_params, omsi_real* res);
      omsi_status <%FileNamePrefix%>_<%omsiName%>_algSystFunction_<%algSystem.algSysIndex%>(omsi_algebraic_system_t* this_alg_system, const omsi_values* model_vars_and_params, void* data);
      >>
    let headerFileName = fileNamePrefix+"_"+omsiName+"_algSyst_"+algSystem.algSysIndex
    let headerFileContent = generateCodeHeader(FileNamePrefix, &includes, headerFileName, &functionPrototypes)
    let () = textFile(headerFileContent, fullPathPrefix+"/"+headerFileName+".h")
    <<
    <%insertCopyrightOpenModelica()%>

    /* Algebraic system code */
    #include "<%headerFileName%>.h"

    #if defined(__cplusplus)
    extern "C" {
    #endif

    /* Instantiation and initialization */
    <%initlaizationFunction%>

    <%matrixString%>

    /* Evaluation functions for <%FileNamePrefix%>_<%omsiName%>_resFunction_<%algSystem.algSysIndex%> */
    <%evaluationCode%>

    omsi_status <%FileNamePrefix%>_<%omsiName%>_resFunction_<%algSystem.algSysIndex%> (omsi_function_t* this_function, const omsi_values* model_vars_and_params, omsi_real* res) {
      omsi_unsigned_int i=0;
      <%functionCall%>
      <%residualCall%>

      return omsi_ok;
    }

    /* Algebraic system evaluation */
    /*
    <%equationInfos%>
    */
    omsi_status <%FileNamePrefix%>_<%omsiName%>_algSystFunction_<%algSystem.algSysIndex%>(omsi_algebraic_system_t* this_alg_system,
                              const omsi_values* model_vars_and_params,
                              void* data){

      /* Variables */
      omsi_status status;

      /* Log function call */
      filtered_base_logger(global_logCategories, log_all, omsi_ok,
          "fmi2Evaluate: Solve algebraic system <%algSystem.algSysIndex%>.");

      /* call API function something */
      status = omsi_solve_algebraic_system(this_alg_system, model_vars_and_params);

      return status;
    }

    #if defined(__cplusplus)
    }
    #endif
    <%\n%>
    >>

  // Case for an algebraic system with derivaitve matrix
  case algSystem as SES_ALGEBRAIC_SYSTEM(matrix = matrix as SOME(DERIVATIVE_MATRIX(__))) then
    let &includes += <<#include <omsi_solve_alg_system.h><%\n%>>>
    let initlaizationFunction = generateInitalizationAlgSystem(equationSystem, FileNamePrefix, &functionPrototypes, &includes, omsiName)
    let _ = generateOmsiFunctionCode_inner(residual, FileNamePrefix,"", "this_function", &includes, &evaluationCode, &functionCall, &residualCall, &functionPrototypes, omsiName)

    let equationInfos = CodegenUtilSimulation.dumpEqs(fill(equationSystem,1))

    // generate jacobian matrix files
    let matrixString = CodegenOMSIC_Equations.generateMatrixInitialization(matrix)
    let &includes += <<#include "<%fileNamePrefix%>_<%omsiName%>_derMat_<%algSystem.algSysIndex%>.h"<%\n%>>>
    let _ = generateDerivativeFile(matrix, FileNamePrefix, algSystem.algSysIndex, omsiName)

    // generate algebraic system header file
    let &functionPrototypes +=
      <<
      omsi_status <%FileNamePrefix%>_<%omsiName%>_resFunction_<%algSystem.algSysIndex%> (omsi_function_t* this_function, const omsi_values* model_vars_and_params, omsi_real* res);
      omsi_status <%FileNamePrefix%>_<%omsiName%>_algSystFunction_<%algSystem.algSysIndex%>(omsi_algebraic_system_t* this_alg_system, const omsi_values* model_vars_and_params, void* data);
      >>
    let headerFileName = fileNamePrefix+"_"+omsiName+"_algSyst_"+algSystem.algSysIndex
    let headerFileContent = generateCodeHeader(FileNamePrefix, &includes, headerFileName, &functionPrototypes)
    let () = textFile(headerFileContent, fullPathPrefix+"/"+headerFileName+".h")
    <<
    <%insertCopyrightOpenModelica()%>

    /* Algebraic system code */
    #include "<%headerFileName%>.h"

    #if defined(__cplusplus)
    extern "C" {
    #endif

    /* Instantiation and initialization */
    <%initlaizationFunction%>

    <%matrixString%>

    /* Evaluation functions for <%FileNamePrefix%>_<%omsiName%>_resFunction_<%algSystem.algSysIndex%> */
    <%evaluationCode%>

    omsi_status <%FileNamePrefix%>_<%omsiName%>_resFunction_<%algSystem.algSysIndex%> (omsi_function_t* this_function, const omsi_values* model_vars_and_params, omsi_real* res) {
      omsi_unsigned_int i=0;
      <%functionCall%>
      <%residualCall%>

      return omsi_ok;
    }

    /* Algebraic system evaluation */
    /*
    <%equationInfos%>
    */
    omsi_status <%FileNamePrefix%>_<%omsiName%>_algSystFunction_<%algSystem.algSysIndex%>(omsi_algebraic_system_t* this_alg_system,
                              const omsi_values* model_vars_and_params,
                              void* data){

      /* Variables */
      omsi_status status;

      /* Log function call */
      filtered_base_logger(global_logCategories, log_all, omsi_ok,
          "fmi2Evaluate: Solve algebraic system <%algSystem.algSysIndex%>.");

      /* call API function something */
      status = omsi_solve_algebraic_system(this_alg_system, model_vars_and_params);

      return status;
    }

    #if defined(__cplusplus)
    }
    #endif
    <%\n%>
    >>
    /* leave a newline at the end of file to get rid of the warning */
end generateOmsiAlgSystemCode;


template generateCodeHeader(String FileNamePrefix, Text &includes, String headerName, Text &functionPrototypes)
"Generates Header for omsi algebraic system C files"
::=
  let macro_name = makeC89Identifier(headerName)

  <<
  <%insertCopyrightOpenModelica()%>

  #if !defined(<%macro_name%>_H)
  #define <%macro_name%>_H

  #include <omsi.h>
  #include <omsic.h>
  #include <omsi_callbacks.h>
  #include <omsi_global.h>

  #include <stdlib.h>
  #include <math.h>

  <%includes%>

  #if defined(__cplusplus)
  extern "C" {
  #endif

  /* Function prototypes */
  <%functionPrototypes%>

  #if defined(__cplusplus)
  }
  #endif

  #endif
  <%\n%>
  >>
  /* leave a newline at the end of file to get rid of the warning */
end generateCodeHeader;


template generateDerivativeFile (Option<DerivativeMatrix> matrix, String FileNamePrefix, String index, String omsiName)
"Generates code for derivative matrix C and header files and creates those files."
::=
  let &includes = buffer ""
  let &initalizationCodeCol = buffer ""
  let &functionPrototypes = buffer ""

  let initalizationCode = (match matrix
    case SOME(derMat as DERIVATIVE_MATRIX(__)) then
    let initalizationCodeCol = (derMat.columns |> column =>
      <<
      <%generateInitalizationOMSIFunction(column, 'derivativeMatFunc_<%index%>', FileNamePrefix,"", &functionPrototypes, &includes, true, omsiName)%>
      >>
    ;separator="\n\n")
    <<
    <%initalizationCodeCol%>
    >>
  )

  let body = CodegenOMSIC_Equations.generateDerivativeMatrix(matrix, FileNamePrefix, index, &functionPrototypes, omsiName)

  let headerFileName = CodegenUtilSimulation.fileNamePrefix(getSimCode())+"_"+omsiName+"_derMat_"+index
  let fileNamePrefix = CodegenUtilSimulation.fileNamePrefix(getSimCode())
  let fullPathPrefix = CodegenUtilSimulation.fullPathPrefix(getSimCode())

  let content =
    <<
    <%insertCopyrightOpenModelica()%>

    /* derivative matrix code for algebraic system <%index%>*/
    #include "<%headerFileName%>.h"

    #if defined(__cplusplus)
    extern "C" {
    #endif

    /* Instantiation and initalization */
    <%initalizationCode%>

    /* derivative matrix evaluation */
    <%body%>

    #if defined(__cplusplus)
    }
    #endif
    <%\n%>
    >>
    /* leave a newline at the end of file to get rid of the warning */

  // generate c and header files
  let () = textFile(content, fullPathPrefix+"/"+fileNamePrefix+"_"+omsiName+"_derMat_"+index+".c")

  let headerFileContent = generateCodeHeader(FileNamePrefix, &includes, headerFileName, &functionPrototypes)
  let()= textFile(headerFileContent, fullPathPrefix+"/"+headerFileName+".h")

  <<>>
end generateDerivativeFile;


template generateInitalizationAlgSystem (SimEqSystem equationSystem, String FileNamePrefix, Text &functionPrototypes, Text &includes, String omsiName)
"Generates code for omsi_algebraic_system_t initialization"
::=
  match equationSystem
  case SES_ALGEBRAIC_SYSTEM(dim_n=dim_n, residual=residual as OMSI_FUNCTION(__),matrix=matrix) then
    let &functionPrototypes += <<omsi_status <%FileNamePrefix%>_<%omsiName%>_instantiate_AlgSystem_<%algSysIndex%>(omsi_algebraic_system_t* algSystem, omsi_values* function_vars, omsi_values* pre_vars);<%\n%>>>

    let zeroCrossingIndices = (zeroCrossingConditions |> cond =>
      '<%cond%>'
    ;separator=", ")
    <<
    /* Function instantiate omsi_algebraic_system_t struct */
    omsi_status <%FileNamePrefix%>_<%omsiName%>_instantiate_AlgSystem_<%algSysIndex%>(omsi_algebraic_system_t* algSystem, omsi_values* function_vars, omsi_values* pre_vars) {
      algSystem->n_iteration_vars = <%dim_n%>;

      algSystem->n_conditions = <%listLength(zeroCrossingConditions)%>;
      <% if listLength(zeroCrossingConditions) then
      'algSystem->zerocrossing_indices[listLength(zeroCrossingConditions)] = {<%zeroCrossingIndices%>};'
      else
      'algSystem->zerocrossing_indices = NULL;'
       %>

      algSystem->isLinear = <% if linearSystem then 'omsi_true' else 'omsi_false'%>;

      /* Instantiate omsi_function_t jacobian */
      algSystem->jacobian = omsu_instantiate_omsi_function (function_vars, pre_vars);
      if (!algSystem->jacobian) {
        return omsi_error;
      }
      <%match matrix case SOME(__) then
      'if (<%FileNamePrefix%>_<%omsiName%>_instantiate_derivativeMatFunc_<%algSysIndex%>_OMSIFunc(algSystem->jacobian) == omsi_error){
        return omsi_error;
      }' else '' %>

      /* Instantiate omsi_function_t function */
      algSystem->functions = omsu_instantiate_omsi_function (function_vars, pre_vars);
      if (!algSystem->functions) {
        return omsi_error;
      }
      if (<%FileNamePrefix%>_<%omsiName%>_instantiate_resFunction_<%algSysIndex%>_OMSIFunc(algSystem->functions) == omsi_error){
        return omsi_error;
      }

      /* ToDo: put into init functions */
      algSystem->functions->evaluate = <%FileNamePrefix%>_<%omsiName%>_resFunction_<%algSysIndex%>;
      algSystem->jacobian->evaluate = <%match  matrix case NONE() then 'NULL;' else '<%FileNamePrefix%>_<%omsiName%>_derivativeMatFunc_<%algSysIndex%>;' %>

      algSystem->solver_data = NULL;

      return omsi_ok;
    }

    <%generateInitalizationOMSIFunction (residual, 'resFunction_<%algSysIndex%>', FileNamePrefix,"", &functionPrototypes, &includes, false, omsiName)%>
    >>
end generateInitalizationAlgSystem;


template generateOmsiIndexTypeInitialization (list<SimVar> variables, String StrucPrefix, String targetName, String omsiFuncName)
"Generates code for instantiation and initialization of struct omsi_index_type "
::=
  let stringBuffer = (variables |> variable hasindex i0 =>
    let stringType = (match variable
      case SIMVAR(type_=type_ as T_REAL(__)) then
        "OMSI_TYPE_REAL"
      case SIMVAR(type_=type_ as T_INTEGER(__)) then
        "OMSI_TYPE_INTEGER"
      case SIMVAR(type_=type_ as T_BOOL(__)) then
        "OMSI_TYPE_BOOLEAN"
      case SIMVAR(type_=type_ as T_STRING(__)) then
        "OMSI_TYPE_STRING"
      else
        "OMSI_TYPE_UNKNOWN"
    )

    let &stringName = buffer ""
    let &stringIndex = buffer ""
    let _ = (match variable
      case var as SIMVAR(varKind=JAC_VAR(__))
      case var as SIMVAR(varKind=JAC_TMP_VAR(__))
      case var as SIMVAR(varKind=SEED_VAR(__)) then
      let &stringName += '<%CodegenUtil.crefCCommentWithVariability(var)%>'
      let &stringIndex += var.index
      <<>>
      case var as SIMVAR(__) then
      let &stringName += '<%CodegenUtil.crefCCommentWithVariability(var)%>'
      let &stringIndex += getValueReference(var, getSimCode(), false)
      <<>>
    )

    <<
    <%omsiFuncName%>[<%i0%>].type  = <%stringType%>;
    <%omsiFuncName%>[<%i0%>].index = <%stringIndex%>;   <%stringName%>
    >>
  ;separator="\n")

  if listLength(variables) then
    <<
    /* maps to <%targetName%> */
    <%stringBuffer%>
    >>
  else
    <<>>
end generateOmsiIndexTypeInitialization;


template generateInitalizationOMSIFunction (OMSIFunction omsiFunction, String functionName, String FileNamePrefix,String modelFunctionnamePrefixStr, Text &functionPrototypes, Text &includes, Boolean hasLocalVars, String omsiName)
"Generates code for omsi_function_t initialization"
::=
  match omsiFunction
  case func as OMSI_FUNCTION(__) then
    let &functionPrototypes += "omsi_status " + FileNamePrefix + "_" + omsiName + "_instantiate_" + functionName + "_OMSIFunc (omsi_function_t* omsi_function);\n"

    let evaluationTarget = FileNamePrefix+"_"+omsiName+"_"+functionName
    let algSystemInit = generateAlgebraicSystemInstantiation (FileNamePrefix, nAlgebraicSystems, equations, omsiName)

    let &includes +=
      <<
      #include <omsu_helper.h>
      <%if nAlgebraicSystems then <<
        #include <solver_api.h>
        >>
      %>
      #include <omsi_input_sim_data.h><%\n%>
      >>

    <<


    omsi_status <%FileNamePrefix%>_<%omsiName%>_instantiate_<%functionName%>_OMSIFunc (omsi_function_t* omsi_function) {



      filtered_base_logger(global_logCategories, log_all, omsi_ok,
          "fmi2Instantiate: Instantiate omsi_function <%functionName%>.");

      omsi_function->n_algebraic_system = <%nAlgebraicSystems%>;

      omsi_function->n_input_vars = <%listLength(inputVars)%>;
      omsi_function->n_inner_vars = <%listLength(innerVars)%>;
      omsi_function->n_output_vars = <%listLength(outputVars)%>;

      <%if nAlgebraicSystems then
        <<
        /* Instantiate algebraic system */
        omsi_function->algebraic_system_t = omsu_instantiate_alg_system_array(<%nAlgebraicSystems%>);
        if (!omsi_function->algebraic_system_t) {
          filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                        "fmi2Instantiate: Not enough memory.");
          return omsi_error;
        }
        <%algSystemInit%>

        >>
      %>

      if (instantiate_input_inner_output_indices (omsi_function, <%listLength(inputVars)%>, <%listLength(outputVars)%>) == omsi_error) {
        return omsi_error;
      }

      <%if hasLocalVars then
        <<
        /* Allocate memory for local variables */
        omsi_function->local_vars = instantiate_omsi_values(<%nAllVars%>, 0, 0, 0);

        >>
      %>
      /* fill omsi_index_type indices */
      <%generateOmsiIndexTypeInitialization(inputVars, "omsi_function->input_vars_indices", "sim_data->model_vars_and_params", "omsi_function->input_vars_indices")%>
      <%if listLength(inputVars) then "\n"%>
      <%generateOmsiIndexTypeInitialization(outputVars, "omsi_function->output_vars_indices", "sim_data->model_vars_and_params", "omsi_function->output_vars_indices")%>

      /* Set pointer for evaluation function */
      omsi_function->evaluate = <%evaluationTarget%>;

      return omsi_ok;
    }
    >>
end generateInitalizationOMSIFunction;


template generateAlgebraicSystemInstantiation (String FileNamePrefix, Integer nAlgebraicSystems, list<SimEqSystem> equations, String omsiName)
"Generates code for instantiation of array of omsi_algebraic_system_t"
::=
  let initialization =  (equations |> equation hasindex i0 =>
    match equation
      case SES_ALGEBRAIC_SYSTEM(__) then
      <<
      <%FileNamePrefix%>_<%omsiName%>_instantiate_AlgSystem_<%algSysIndex%>(&(omsi_function->algebraic_system_t[<%i0%>]), omsi_function->function_vars, omsi_function->pre_vars);
      if (!&omsi_function->algebraic_system_t[<%i0%>]) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
            "fmi2Instantiate: Function <%FileNamePrefix%>_<%omsiName%>_instantiate_AlgSystem_<%algSysIndex%> failed.");
        return omsi_error;
      }
      >>
  ;separator="\n")

  <<
  <%initialization%>
  >>
end generateAlgebraicSystemInstantiation;


template functionInitSample(list<BackendDAE.TimeEvent> timeEvents, String fileNamePrefix)
  "Generates function initSample() in simulation file."
::=
  let &varDecls = buffer ""
  let &auxFunction = buffer ""
  let body = (timeEvents |> timeEvent hasindex i0 =>
      match timeEvent
        case SAMPLE_TIME_EVENT(__) then
          let &preExp = buffer ""
          let e1 = CodegenCFunctions.daeExp(startExp, contextOther, &preExp, &varDecls, &auxFunction)
          let e2 = CodegenCFunctions.daeExp(intervalExp, contextOther, &preExp, &varDecls, &auxFunction)
          <<
          <%preExp%>
          /* sample <%index%> */
          sample_events[<%i0%>].id = <%index%>;
          sample_events[<%i0%>].start_time = <%e1%>;
          sample_events[<%i0%>].interval = <%e2%>;
          >>
        else '')

  <<
  <%auxFunction%>
   /* Initializes sample time events */
  void <%fileNamePrefix%>_instantiate_samples(omsi_sample* sample_events)
  {
    <%varDecls%>
    <%body%>
  }
  >>
end functionInitSample;


template insertCopyrightOpenModelica()
"Insert copyright notive as C comment.
 Should be used in every generated C or C++ file."
::=
  <<
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
  >>
end insertCopyrightOpenModelica;


annotation(__OpenModelica_Interface="backend");
end CodegenOMSI_common;
