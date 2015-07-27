package CodegenCppInit

import interface SimCodeTV;
import interface SimCodeBackendTV;
import CodegenUtil.*;
import CodegenFMUCommon;
import CodegenFMU2;
import CodegenFMU1;

template modelInitXMLFile(SimCode simCode, String numRealVars, String numIntVars, String numBoolVars, String FMUVersion, String FMUType, String FMUGuid, Boolean generateFMUModelDescription, String generatorComments)
 "Generate a xml file that contains informations for initialization or for the FMU-structure"
::=
  match simCode
    case SIMCODE(modelInfo = MODELINFO(__)) then
      let variables = modelVariablesXML(modelInfo, varToArrayIndexMapping, '<%numRealVars%> - 1', '<%numIntVars%> - 1', '<%numBoolVars%> - 1', generateFMUModelDescription)
      let algLoops = (listAppend(allEquations,initialEquations) |> eq => algLoopXML(eq, simCode, varToArrayIndexMapping, '<%numRealVars%> - 1') ;separator="\n")
      let jacobianMatrixes = jacobianMatrixesXML(simCode.jacobianMatrixes)
      let descriptionTag = if generateFMUModelDescription then "fmiModelDescription" else "ModelDescription"
      let fmiDescriptionAttributes = if generateFMUModelDescription then fmiDescriptionAttributes(simCode, FMUVersion, FMUType, FMUGuid) else 'modelName="<%dotPath(modelInfo.name)%>"'
      let fmiTypeDefinitions = if generateFMUModelDescription then CodegenFMUCommon.fmiTypeDefinitions(modelInfo, FMUVersion)
      let fmiDefaultExperiment = if generateFMUModelDescription then CodegenFMUCommon.DefaultExperiment(simulationSettingsOpt)
      <<
      <?xml version="1.0" encoding="UTF-8"?>
      <!--Generated with the modifications: <%generatorComments%> -->
      <<%descriptionTag%> <%fmiDescriptionAttributes%>>
        <%fmiTypeDefinitions%>
        <%fmiDefaultExperiment%>
        <ModelVariables>
          <%variables%>
        </ModelVariables>
        <%if boolNot(generateFMUModelDescription) then
        <<
        <AlgLoops>
          <%algLoops%>
        </AlgLoops>
        <Jacobian>
          <%jacobianMatrixes%>
        </Jacobian>
        >>
        %>
      </<%descriptionTag%>>
      >>
end modelInitXMLFile;

template fmiDescriptionAttributes(SimCode simCode, String FMUVersion, String FMUType, String FMUGuid)
::=
  if isFMIVersion20(FMUVersion) then CodegenFMU2.fmiModelDescriptionAttributes(simCode,FMUGuid)
  else fmiModelDescriptionAttributes(simCode,FMUGuid)
end fmiDescriptionAttributes;

template fmiModelDescriptionAttributes(SimCode simCode, String guid)
 "Generates code for ModelDescription file for FMU target."
::=
  match simCode
    case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__), vars = SIMVARS(stateVars = listStates))) then
      let fmiVersion = '1.0'
      let modelName = dotPath(modelInfo.name)
      let modelIdentifier = System.stringReplace(fileNamePrefix,".", "_")
      let description = ''
      let author = ''
      let version= ''
      let generationTool= 'OpenModelica Compiler <%getVersionNr()%>'
      let generationDateAndTime = CodegenFMUCommon.xsdateTime(getCurrentDateTime())
      let variableNamingConvention = 'structured'
      let numberOfContinuousStates = vi.numStateVars
      let numberOfEventIndicators = CodegenFMUCommon.getNumberOfEventIndicators(simCode)
      <<
      fmiVersion="<%fmiVersion%>"
      modelName="<%modelName%>"
      modelIdentifier="<%modelIdentifier%>"
      guid="{<%guid%>}"
      generationTool="<%generationTool%>"
      generationDateAndTime="<%generationDateAndTime%>"
      variableNamingConvention="<%variableNamingConvention%>"
      numberOfContinuousStates="<%numberOfContinuousStates%>"
      numberOfEventIndicators="<%numberOfEventIndicators%>"
      >>
end fmiModelDescriptionAttributes;

template modelVariablesXML(ModelInfo modelInfo, HashTableCrIListArray.HashTable varToArrayIndexMapping, String indexForUndefinedReferencesReal, String indexForUndefinedReferencesInt, String indexForUndefinedReferencesBool, Boolean generateFMUModelDescription)
 "Generates the xml code for the variable defintions."
::=
  match modelInfo
    case MODELINFO(vars=SIMVARS(__),varInfo=VARINFO(numAlgVars= numAlgVars, numDiscreteReal = numDiscreteReal, numOptimizeConstraints = numOptimizeConstraints)) then
      <<
      <%vars.stateVars       |> var => scalarVariableXML(var, varToArrayIndexMapping, indexForUndefinedReferencesReal, generateFMUModelDescription) ;separator="\n";empty%>
      <%vars.derivativeVars  |> var => scalarVariableXML(var, varToArrayIndexMapping, indexForUndefinedReferencesReal, generateFMUModelDescription) ;separator="\n";empty%>
      <%vars.algVars         |> var => scalarVariableXML(var, varToArrayIndexMapping, indexForUndefinedReferencesReal, generateFMUModelDescription) ;separator="\n";empty%>
      <%vars.discreteAlgVars |> var => scalarVariableXML(var, varToArrayIndexMapping, indexForUndefinedReferencesReal, generateFMUModelDescription) ;separator="\n";empty%>
      <%/*vars.realOptimizeConstraintsVars
                             |> var hasindex i0 => scalarVariableXML(var,varToArrayIndexMapping, indexForUndefinedReferencesReal, generateFMUModelDescription) ;separator="\n";empty*/%>
      <%/*vars.realOptimizeFinalConstraintsVars
                             |> var => scalarVariableXML(var,varToArrayIndexMapping, indexForUndefinedReferencesReal, generateFMUModelDescription) ;separator="\n";empty*/%>
      <%vars.paramVars       |> var => scalarVariableXML(var,varToArrayIndexMapping, indexForUndefinedReferencesReal, generateFMUModelDescription) ;separator="\n";empty%>
      <%vars.aliasVars       |> var => scalarVariableXML(var,varToArrayIndexMapping, indexForUndefinedReferencesReal, generateFMUModelDescription) ;separator="\n";empty%>

      <%vars.intAlgVars      |> var => scalarVariableXML(var,varToArrayIndexMapping, indexForUndefinedReferencesInt, generateFMUModelDescription) ;separator="\n";empty%>
      <%vars.intParamVars    |> var => scalarVariableXML(var,varToArrayIndexMapping, indexForUndefinedReferencesInt, generateFMUModelDescription) ;separator="\n";empty%>
      <%vars.intAliasVars    |> var => scalarVariableXML(var,varToArrayIndexMapping, indexForUndefinedReferencesInt, generateFMUModelDescription) ;separator="\n";empty%>

      <%vars.boolAlgVars     |> var => scalarVariableXML(var,varToArrayIndexMapping, indexForUndefinedReferencesBool, generateFMUModelDescription) ;separator="\n";empty%>
      <%vars.boolParamVars   |> var => scalarVariableXML(var,varToArrayIndexMapping, indexForUndefinedReferencesBool, generateFMUModelDescription) ;separator="\n";empty%>
      <%vars.boolAliasVars   |> var => scalarVariableXML(var,varToArrayIndexMapping, indexForUndefinedReferencesBool, generateFMUModelDescription) ;separator="\n";empty%>
      >>
      /*
      <%vars.stringAlgVars   |> var hasindex i0 => ScalarVariable(var,i0,"sAlg") ;separator="\n";empty%>
      <%vars.stringParamVars |> var hasindex i0 => ScalarVariable(var,i0,"sPar") ;separator="\n";empty%>
      <%vars.stringAliasVars |> var hasindex i0 => ScalarVariable(var,i0,"sAli") ;separator="\n";empty%>
      */
end modelVariablesXML;

template scalarVariableXML(SimVar simVar, HashTableCrIListArray.HashTable varToArrayIndexMapping, String indexForUndefinedReferences, Boolean generateFMUModelDescription)
 "Generates code for ScalarVariable file for FMU target."
::=
  match simVar
    case SIMVAR(__) then
      let variableCode = if generateFMUModelDescription then CodegenFMUCommon.ScalarVariableType(simVar) else
                                                             ScalarVariableType(unit, displayUnit, minValue, maxValue, initialValue, nominalValue, isFixed, type_)
      <<
      <ScalarVariable <%scalarVariableAttributeXML(simVar, varToArrayIndexMapping, indexForUndefinedReferences, generateFMUModelDescription)%>>
        <%variableCode%>
      </ScalarVariable>
      >>
end scalarVariableXML;

template scalarVariableAttributeXML(SimVar simVar, HashTableCrIListArray.HashTable varToArrayIndexMapping, String indexForUndefinedReferences, Boolean generateFMUModelDescription)
 "Generates code for ScalarVariable Attribute file for FMU target."
::=
  match simVar
    case SIMVAR(source = SOURCE(info = info)) then
      let valueReference = SimCodeUtil.getVarIndexByMapping(varToArrayIndexMapping,name,indexForUndefinedReferences)
      let alias = getAliasAttribute(aliasvar)
      let causalityAtt = CodegenFMUCommon.getCausality(causality)
      let variability = getVariablity(varKind)
      let description = if comment then 'description="<%Util.escapeModelicaStringToXmlString(comment)%>"'
      let additionalAttributes = if generateFMUModelDescription then '' else 'isProtected="<%isProtected%>'
      <<
      name="<%Util.escapeModelicaStringToXmlString(crefStrNoUnderscore(name))%>" valueReference="<%valueReference%>" <%description%> variability="<%variability%>" causality="<%causalityAtt%>" alias="<%alias%>" <%additionalAttributes%>
      >>
end scalarVariableAttributeXML;

template getAliasAttribute(AliasVariable aliasvar)
  "Returns the alias Attribute of ScalarVariable."
  ::=
  match aliasvar
    case NOALIAS(__) then "noAlias"
    case ALIAS(__) then "alias"
    case NEGATEDALIAS(__) then "negatedAlias"
    else "undefinedAliasType"
end getAliasAttribute;

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

template zeroCrossLength(SimCode simCode)
::=
  match simCode
    case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__))) then
      let size = listLength(zeroCrossings)
      <<
      <%intSub(listLength(zeroCrossings), vi.numTimeEvents)%>
      >>
end zeroCrossLength;

template timeEventLength(SimCode simCode)
::=
  match simCode
    case SIMCODE(modelInfo = MODELINFO(varInfo = vi as VARINFO(__))) then
      <<
      <%vi.numTimeEvents%>
      >>
end timeEventLength;

annotation(__OpenModelica_Interface="backend");
end CodegenCppInit;