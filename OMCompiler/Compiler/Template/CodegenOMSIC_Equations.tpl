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

package CodegenOMSIC_Equations
" file:        CodegenOMSIC_Equations.tpl
  package:     CodegenOMSIC_Equations
  description: Code generation using Susan templates for
               OpenModelica Simulation Inferface (OMSI) for equation related templates for C
"

import interface SimCodeTV;
import interface SimCodeBackendTV;

import CodegenC;
import CodegenCFunctions;
import CodegenUtil;
import CodegenUtilSimulation;


template equationFunctionPrototypes(SimEqSystem eq, String modelNamePrefixStr)
 "Generates prototype for an equation function."
::=
  let ix = CodegenUtilSimulation.equationIndex(eq)
  <<
  void <%CodegenUtil.symbolName(modelNamePrefixStr,"eqFunction")%>_<%ix%>(Data_Struct_something* data, Data_Struct_something* threadData);<%\n%>
  >>
end equationFunctionPrototypes;


template generateEquationFunction(SimEqSystem eq, String modelNamePrefixStr,String modelFunctionnamePrefixStr, SimCodeFunction.Context context, Text &functionPrototypes)
 "Generates C-function for an equation evaluation."
::=
  let ix = CodegenUtilSimulation.equationIndex(eq)
  let equationInfos = CodegenUtilSimulation.dumpEqs(fill(eq,1))

  let &varDecls = buffer ""
  let &auxFunction = buffer ""
  let equationCode = equationCStr(eq, &varDecls, &auxFunction, context)

  let funcName = (match eq
    case SES_RESIDUAL(__) then
      "resFunction"
    case SES_ALGEBRAIC_SYSTEM(__) then
      "algSystFunction"
    else
    match  Config.simCodeTarget()
    case "omsic" then
      "eqFunction"
    case "omsicpp" then
      "omsi_" + modelFunctionnamePrefixStr
    end match
    )

  let funcArguments = (match eq
    case SES_RESIDUAL(__) then
      "omsi_function_t* this_function, const omsi_values* model_vars_and_params, omsi_real* res"
    case SES_ALGEBRAIC_SYSTEM(__) then
      "omsi_function_t* this_function, const omsi_values* model_vars_and_params"
    else
      "omsi_function_t* this_function, const omsi_values* model_vars_and_params"
  )

  let &functionPrototypes +=  match  Config.simCodeTarget()
    case "omsic" then
       <<void <%CodegenUtil.symbolName(modelNamePrefixStr,funcName)%>_<%ix%>(<%funcArguments%>);<%\n%>>>
    case "omsicpp" then
       <<void <%funcName%>_<%ix%>(<%funcArguments%>);<%\n%>>>
    end match

  <<
  /*
  <%equationInfos%>
  */
  <%match  Config.simCodeTarget()
  case "omsic" then
  'void <%CodegenUtil.symbolName(modelNamePrefixStr,funcName)%>_<%ix%>(<%funcArguments%>){'
  case "omsicpp" then
   'void <%modelNamePrefixStr%>::<%funcName%>_<%ix%>(<%funcArguments%>){'
   end match%>
    <%if not stringEq(varDecls, "") then
      <<
      /* Variables */
      <%varDecls%>

      >>
    %>
    <%auxFunction%>
    <%equationCode%>
  }<%"\n"%>
  >>
end generateEquationFunction;


template equationCStr(SimEqSystem eq, Text &varDecls, Text &auxFunction, Context context)
 "Generates an equation that is just a simple assignment."
::=
  let &preExp = buffer ""

  match eq
  case SES_SIMPLE_ASSIGN(__) then
    let crefStr = CodegenCFunctions.crefOMSI(cref, context)
    let expPart = CodegenCFunctions.daeExp(exp, context, &preExp, &varDecls, &auxFunction)
    <<
    <%preExp%>
    <%crefStr%> = <%expPart%>;
    >>
  case SES_RESIDUAL(__) then
    let expPart = CodegenCFunctions.daeExp(exp, context, &preExp, &varDecls, &auxFunction)
    <<
    <%preExp%>
    *res = <%expPart%>;
    >>
  case SES_WHEN(__) then
    let whenEq = equationWhen(eq, context, &varDecls, &auxFunction)
    <<
    <%whenEq%>
    >>
  else
    <<
    NOT IMPLEMENTED YET Error in function equationCStr in template CodegenOMSIC_Equations
    >>
end equationCStr;


template equationCall(SimEqSystem eq, String modelNamePrefixStr,String modelFunctionnamePrefixStr, String input, String omsiName)
 "Generates call function for evaluating functions."
::=
  match eq
  case SES_SIMPLE_ASSIGN(__)
  case SES_WHEN(__) then
    let i = index
    match  Config.simCodeTarget()
    case "omsic" then
      <<
      <%CodegenUtil.symbolName(modelNamePrefixStr,"eqFunction")%>_<%i%>(<%input%>);
      >>
    case "omsicpp" then
      <<
      omsi_<%modelFunctionnamePrefixStr%>_<%i%>(<%input%>);
      >>
    end match
  case SES_RESIDUAL(__) then
    <<
    <%CodegenUtil.symbolName(modelNamePrefixStr,"resFunction")%>_<%index%>(<%input%>);
    >>
  case SES_ALGEBRAIC_SYSTEM(__) then
    <<
    new_status = <%CodegenUtil.symbolName(modelNamePrefixStr,omsiName)%>_algSystFunction_<%algSysIndex%>(<%input%>);
    status = (new_status==omsi_ok && status==omsi_ok) ? omsi_ok:new_status;
    >>
  else
    /* ToDo: generate Warning */
    <<
    /* equationCall not implemented yet */
    >>
end equationCall;


template generateMatrixInitialization(Option<DerivativeMatrix> matrix)
"Generates code for matrix initialization and evaluation."
::=
  let columnsString = ""

  match matrix
  case SOME(m as DERIVATIVE_MATRIX(__)) then
    let _ = m.columns |> col => (
      let columnsString = generateMatrixColumnInitialization(col)
      <<>>
    )

  <<

  <%columnsString%>

  >>
end generateMatrixInitialization;


template generateMatrixColumnInitialization(OMSIFunction column)
"Helper function for template generateMatrixInitialization."
::=
  let &varDecls = buffer ""
  let &auxFunction = buffer ""
  let &body = buffer ""

  match column
  case omsiFunction as OMSI_FUNCTION(__) then
    let _ = (equations |> eq =>
      let &body += equationCStr(eq, &varDecls, &auxFunction, omsiFunction.context)
      <<>>
    )

  <<
  <%body%>
  >>
end generateMatrixColumnInitialization;


template generateDerivativeMatrix(Option<DerivativeMatrix> matrix, String modelName, String index, Text &functionPrototypes, String omsiName)
"Generates equations for derivative matrix."
::=
  let &columnsString = buffer ""
  match matrix
  case SOME(m as DERIVATIVE_MATRIX(__)) then
    let columnsString = (m.columns |> col =>
      <<
      <%generateDereivativeMatrixColumnFunction(col, modelName, index, &functionPrototypes)%>

      <%generateDereivativeMatrixColumnCall(col, modelName, index, &functionPrototypes, omsiName)%>
      >>
    ;separator="\n\n")

  <<
  <%columnsString%>
  >>
end generateDerivativeMatrix;


template generateDereivativeMatrixColumnFunction(OMSIFunction column, String modelName, String index, Text &functionPrototypes)
"Generates equations code for columns of derivative matrix."
::=
  let bodyBuffer = ""
  let &preExp = buffer ""
  let &varDecls = buffer ""
  let &auxFunction = buffer ""

  match column
  case omsiFunction as OMSI_FUNCTION(__) then
    let bodyBuffer = ( equations |> eq=>
      <<
      <%generateEquationFunction(eq, modelName,"",omsiFunction.context, &functionPrototypes)%>
      >>
    ;separator="\n")

  <<
  <%bodyBuffer%>
  >>
end generateDereivativeMatrixColumnFunction;


template generateDereivativeMatrixColumnCall(OMSIFunction column, String modelName, String index, Text &functionPrototypes, String omsiName)
"Generate function call for derivative matrix evaluations."
::=
  let bodyBuffer = ""
  let &preExp = buffer ""
  let &varDecls = buffer ""
  let &auxFunction = buffer ""

  match column
  case OMSI_FUNCTION() then
    let bodyBuffer = ( equations |> eq =>
      <<
      <%equationCall(eq, modelName,"", "this_function, model_vars_and_params", omsiName)%>
      >>
    ;separator="\n")

  let &functionPrototypes += <<omsi_status <%CodegenUtil.symbolName(modelName,omsiName)%>_derivativeMatFunc_<%index%>(omsi_function_t* this_function, const omsi_values* model_vars_and_params, void* data);<%\n%>>>

  <<
  /*
  Description something
  */
  omsi_status <%CodegenUtil.symbolName(modelName,omsiName)%>_derivativeMatFunc_<%index%>(omsi_function_t* this_function, const omsi_values* model_vars_and_params, void* data){

    <%bodyBuffer%>

    return omsi_ok;
  }
  >>
end generateDereivativeMatrixColumnCall;


/***************************************
*
* Handling of When-Equations
*
****************************************/

template equationWhen(SimEqSystem eq, Context context, Text &varDecls, Text &auxFunction)
 "Generates a when equation."
::=
  match eq
    case SES_WHEN(whenStmtLst = whenStmtLst, conditions=conditions, elseWhen=NONE()) then
      let helpIf = if not listEmpty(conditions) then (conditions |> cr =>
            '(<%CodegenCFunctions.crefOMSI(cr, context)%> && !<%CodegenCFunctions.crefOMSI(ComponentReference.crefPrefixPre(cr), context)%> /* edge */)'
            ;separator=" || ") else '0'
      // TODO: convert whenOperators to SImEqSystems
      let assign = ( whenStmtLst |>  stmt =>
                match stmt
                case ASSIGN(left=lhs as DAE.CREF(componentRef=left), right=right) then
                  let &preExp = buffer ""
                  let lhs = CodegenCFunctions.crefOMSI(left, context)
                  let rhs = CodegenCFunctions.daeExp(right, context, &preExp, &varDecls, &auxFunction)
                  <<
                    <%preExp%>
                    <%lhs%> = <%rhs%>;
                  >>

                case REINIT(stateVar=stateVar, value=value, source=source) then
                  let &preExp = buffer ""
                  let val = CodegenCFunctions.daeExp(value, context, &preExp, &varDecls, &auxFunction)
                  let lhs = match crefTypeConsiderSubs(stateVar)
                    case DAE.T_ARRAY(__) then
                      'TODO: Implement for arrays!'
                    else
                      '<%CodegenCFunctions.crefOMSI(stateVar, context)%> = <%val%>;'
                  <<
                  <%preExp%>
                  <%lhs%>
                  /* ToDo: Add some info that variable was reinitialized */
                  >>

                else
                  <<
                  TODO: when expression not supported yet
                  >>
                //end match
              ;separator="\n")
      <<
      if(<%helpIf%>)
      {
        <%assign%>
      }
      >>
    else
      <<
      TODO: Implement elsewhen
      >>
end equationWhen;


annotation(__OpenModelica_Interface="backend");
end CodegenOMSIC_Equations;
