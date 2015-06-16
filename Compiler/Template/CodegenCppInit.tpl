package CodegenCppInit

import interface SimCodeTV;
import CodegenUtil.*;

template modelInitXMLFile(SimCode simCode, String numRealVars, String numIntVars, String numBoolVars)
::=
  match simCode
    case SIMCODE(modelInfo = MODELINFO(__)) then
      let variables = modelVariablesXML(modelInfo, varToArrayIndexMapping, '<%numRealVars%> - 1', '<%numIntVars%> - 1', '<%numBoolVars%> - 1')
      let algLoops = (listAppend(allEquations,initialEquations) |> eq => algLoopXML(eq, simCode, varToArrayIndexMapping, '<%numRealVars%> - 1') ;separator="\n")
      let jacobianMatrixes = jacobianMatrixesXML(simCode.jacobianMatrixes)
      <<
      <?xml version="1.0" encoding="UTF8"?>
      <ModelDescription modelName="<%dotPath(modelInfo.name)%>">
        <ModelVariables>
          <%variables%>
        </ModelVariables>
        <AlgLoops>
          <%algLoops%>
        </AlgLoops>
        <Jacobian>
          <%jacobianMatrixes%>
        </Jacobian>
      </ModelDescription>
      >>
end modelInitXMLFile;

template modelVariablesXML(ModelInfo modelInfo, HashTableCrIListArray.HashTable varToArrayIndexMapping, String indexForUndefinedReferencesReal, String indexForUndefinedReferencesInt, String indexForUndefinedReferencesBool)
 "Generates the xml code for the variable defintions."
::=
  match modelInfo
    case MODELINFO(vars=SIMVARS(__),varInfo=VARINFO(numAlgVars= numAlgVars, numDiscreteReal = numDiscreteReal, numOptimizeConstraints = numOptimizeConstraints)) then
      <<
      <%vars.stateVars       |> var => scalarVariableXML(var, varToArrayIndexMapping, indexForUndefinedReferencesReal) ;separator="\n";empty%>
      <%vars.derivativeVars  |> var => scalarVariableXML(var, varToArrayIndexMapping, indexForUndefinedReferencesReal) ;separator="\n";empty%>
      <%vars.algVars         |> var => scalarVariableXML(var, varToArrayIndexMapping, indexForUndefinedReferencesReal) ;separator="\n";empty%>
      <%vars.discreteAlgVars |> var => scalarVariableXML(var, varToArrayIndexMapping, indexForUndefinedReferencesReal) ;separator="\n";empty%>
      <%/*vars.realOptimizeConstraintsVars
                             |> var hasindex i0 => scalarVariableXML(var,varToArrayIndexMapping, indexForUndefinedReferencesReal) ;separator="\n";empty*/%>
      <%/*vars.realOptimizeFinalConstraintsVars
                             |> var => scalarVariableXML(var,varToArrayIndexMapping, indexForUndefinedReferencesReal) ;separator="\n";empty*/%>
      <%vars.paramVars       |> var => scalarVariableXML(var,varToArrayIndexMapping, indexForUndefinedReferencesReal) ;separator="\n";empty%>
      <%vars.aliasVars       |> var => scalarVariableXML(var,varToArrayIndexMapping, indexForUndefinedReferencesReal) ;separator="\n";empty%>

      <%vars.intAlgVars      |> var => scalarVariableXML(var,varToArrayIndexMapping, indexForUndefinedReferencesInt) ;separator="\n";empty%>
      <%vars.intParamVars    |> var => scalarVariableXML(var,varToArrayIndexMapping, indexForUndefinedReferencesInt) ;separator="\n";empty%>
      <%vars.intAliasVars    |> var => scalarVariableXML(var,varToArrayIndexMapping, indexForUndefinedReferencesInt) ;separator="\n";empty%>

      <%vars.boolAlgVars     |> var => scalarVariableXML(var,varToArrayIndexMapping, indexForUndefinedReferencesBool) ;separator="\n";empty%>
      <%vars.boolParamVars   |> var => scalarVariableXML(var,varToArrayIndexMapping, indexForUndefinedReferencesBool) ;separator="\n";empty%>
      <%vars.boolAliasVars   |> var => scalarVariableXML(var,varToArrayIndexMapping, indexForUndefinedReferencesBool) ;separator="\n";empty%>
      >>
      /*
      <%vars.stringAlgVars   |> var hasindex i0 => ScalarVariable(var,i0,"sAlg") ;separator="\n";empty%>
      <%vars.stringParamVars |> var hasindex i0 => ScalarVariable(var,i0,"sPar") ;separator="\n";empty%>
      <%vars.stringAliasVars |> var hasindex i0 => ScalarVariable(var,i0,"sAli") ;separator="\n";empty%>
      */
end modelVariablesXML;

template scalarVariableXML(SimVar simVar, HashTableCrIListArray.HashTable varToArrayIndexMapping, String indexForUndefinedReferences)
 "Generates code for ScalarVariable file for FMU target."
::=
  match simVar
    case SIMVAR(__) then
      <<
      <ScalarVariable <%scalarVariableAttributeXML(simVar, varToArrayIndexMapping, indexForUndefinedReferences)%>>
        <%ScalarVariableType(unit, displayUnit, minValue, maxValue, initialValue, nominalValue, isFixed, type_)%>
      </ScalarVariable>
      >>
end scalarVariableXML;

template scalarVariableAttributeXML(SimVar simVar, HashTableCrIListArray.HashTable varToArrayIndexMapping, String indexForUndefinedReferences)
 "Generates code for ScalarVariable Attribute file for FMU target."
::=
  match simVar
    case SIMVAR(source = SOURCE(info = info)) then
      let valueReference = SimCodeUtil.getVarIndexListByMapping(varToArrayIndexMapping,name,indexForUndefinedReferences)
      let variability = getVariablity(varKind)
      let description = if comment then 'description = "<%Util.escapeModelicaStringToXmlString(comment)%>"'
      <<
      name = "<%Util.escapeModelicaStringToXmlString(crefStrNoUnderscore(name))%>" valueReference = "<%valueReference%>" <%description%> variability = "<%variability%>" isProtected = "<%isProtected%>"
      >>
end scalarVariableAttributeXML;

template algLoopXML(SimEqSystem eqs, SimCode simCode, HashTableCrIListArray.HashTable varToArrayIndexMapping, String indexForUndefinedReferences)
::=
  <<
  <%
  match(eqs)
    case(SES_LINEAR(lSystem = ls as LINEARSYSTEM(__))) then
      <<
      <Linear eqIdx="<%ls.index%>" sparse="true" size="<%listLength(ls.vars)%>">
        <Vars>
          <%ls.vars |> v as SIMVAR(__) => '<Var type="double" index="<%SimCodeUtil.getVarIndexListByMapping(varToArrayIndexMapping,v.name,indexForUndefinedReferences)%>" />' ;separator="\n"%>
        </Vars>
      </Linear>
      >>
    case(SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__))) then
      <<
      <NonLinear eqIdx="<%nls.index%>" size="<%listLength(nls.crefs)%>">
        <Vars>
          <%nls.crefs |> name => '<Var type="double" index="<%SimCodeUtil.getVarIndexListByMapping(varToArrayIndexMapping,name,indexForUndefinedReferences)%>" />' ;separator="\n"%>
        </Vars>
        <NominalVars>
        <!-- Maybe Expressions here -->
        </NominalVars>
      </NonLinear>
      >>
    else
      ''
  %>
  >>
end algLoopXML;

template jacobianMatrixesXML(list<JacobianMatrix> JacobianMatrixes)
::=
  let jacMats = (JacobianMatrixes |> (mat, vars, name, (sparsepattern,_), colorList, maxColor, jacIndex) =>
    jacobianMatrixXML(jacIndex, mat, vars, name, sparsepattern, colorList, maxColor)
    ;separator="\n";empty)
  <<
  <%jacMats%>
  >>
end jacobianMatrixesXML;

template jacobianMatrixXML(Integer indexJacobian, list<JacobianColumn> jacobianColumn, list<SimVar> seedVars, String matrixName, list<tuple<Integer,list<Integer>>> sparsepattern, list<list<Integer>> colorList, Integer maxColor)
::=
  let indexColumn = (jacobianColumn |> (eqs,vars,indxColumn) => indxColumn; separator="\n")
  let jacvals = (sparsepattern |> (index,indexes) hasindex index0 =>
                   '<Column>
                   <%(indexes |> i_index hasindex index1 =>
                     (
                       match indexColumn case "1" then '<Entry indexX="<%index%>" indexY="0" valueIndex="0"/>'
                       else '<Entry indexX="<%index%>" indexY="<%i_index%>" valueIndex="<%i_index%>"/>'
                     );separator="\n"
                   )%>
                   </Column>'
                 ;separator="\n"
                )
  <<
  <Matrix name="<%matrixName%>">
    <Column>
      <%jacvals%>
    </Column>
  </Matrix>
  >>
end jacobianMatrixXML;


annotation(__OpenModelica_Interface="backend");
end CodegenCppInit;