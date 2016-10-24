package CodegenCppInit

import interface SimCodeTV;
import interface SimCodeBackendTV;
import CodegenUtil.*;
import CodegenCppCommon;
import CodegenFMUCommon;
import CodegenFMU2;
import CodegenFMU1;

template modelInitXMLFile(SimCode simCode, String numRealVars, String numIntVars, String numBoolVars, String numStringVars, String FMUVersion, String FMUType, String FMUGuid, Boolean generateFMUModelDescription, String generatorComments, Text& complexStartExpressions, Text stateDerVectorName)
 "Generate a xml file that contains informations for initialization or for the FMU-structure"
::=
  match simCode
    case SIMCODE(modelInfo = MODELINFO(__)) then
      let variables = modelVariablesXML(simCode, modelInfo, varToArrayIndexMapping, '<%numRealVars%> - 1', '<%numIntVars%> - 1', '<%numBoolVars%> - 1', '<%numStringVars%> - 1', generateFMUModelDescription, complexStartExpressions, stateDerVectorName)
      //let algLoops = (listAppend(allEquations,initialEquations) |> eq => algLoopXML(eq, simCode, varToArrayIndexMapping, '<%numRealVars%> - 1') ;separator="\n")
      //let jacobianMatrixes = jacobianMatrixesXML(simCode.jacobianMatrixes)
      let descriptionTag = if generateFMUModelDescription then "fmiModelDescription" else "ModelDescription"
      let fmiDescriptionAttributes = if generateFMUModelDescription then fmiDescriptionAttributes(simCode, FMUVersion, FMUType, FMUGuid) else 'modelName="<%dotPath(modelInfo.name)%>"'
      let fmiTypeDefinitions = if generateFMUModelDescription then CodegenFMUCommon.fmiTypeDefinitions(simCode, FMUVersion)
      let fmiDefaultExperiment = if generateFMUModelDescription then CodegenFMUCommon.DefaultExperiment(simulationSettingsOpt)
      <<
      <?xml version="1.0" encoding="UTF-8"?>
      <!--Generated with the modifications: <%generatorComments%> -->
      <!--Take care about array indices, they are stored in column major layout.-->
      <<%descriptionTag%> <%fmiDescriptionAttributes%>>
        <%fmiTypeDefinitions%>
        <%fmiDefaultExperiment%>
        <ModelVariables>
          <%variables%>
        </ModelVariables>
      </<%descriptionTag%>>
      >>
      /*
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
      */
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
      let modelName = System.stringReplace(dotPath(modelInfo.name),"$", "_D_")
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

template modelVariablesXML(SimCode simCode, ModelInfo modelInfo, HashTableCrIListArray.HashTable varToArrayIndexMapping, String indexForUndefinedReferencesReal,
                           String indexForUndefinedReferencesInt, String indexForUndefinedReferencesBool, String indexForUndefinedReferencesString,
                           Boolean generateFMUModelDescription, Text& complexStartExpressions, Text stateDerVectorName)
 "Generates the xml code for the variable defintions."
::=
  match modelInfo
    case MODELINFO(vars=SIMVARS(__),varInfo=VARINFO(numAlgVars= numAlgVars, numDiscreteReal = numDiscreteReal, numOptimizeConstraints = numOptimizeConstraints)) then
      <<
      <%vars.stateVars       |> var => scalarVariableXML(simCode, var, varToArrayIndexMapping, indexForUndefinedReferencesReal, generateFMUModelDescription, complexStartExpressions, stateDerVectorName) ;separator="\n";empty%>
      <%vars.derivativeVars  |> var => scalarVariableXML(simCode, var, varToArrayIndexMapping, indexForUndefinedReferencesReal, generateFMUModelDescription, complexStartExpressions, stateDerVectorName) ;separator="\n";empty%>
      <%vars.algVars         |> var => scalarVariableXML(simCode, var, varToArrayIndexMapping, indexForUndefinedReferencesReal, generateFMUModelDescription, complexStartExpressions, stateDerVectorName) ;separator="\n";empty%>
      <%vars.discreteAlgVars |> var => scalarVariableXML(simCode, var, varToArrayIndexMapping, indexForUndefinedReferencesReal, generateFMUModelDescription, complexStartExpressions, stateDerVectorName) ;separator="\n";empty%>
      <%/*vars.realOptimizeConstraintsVars
                             |> var hasindex i0 => scalarVariableXML(simCode, var,varToArrayIndexMapping, indexForUndefinedReferencesReal, generateFMUModelDescription, complexStartExpressions, stateDerVectorName) ;separator="\n";empty*/%>
      <%/*vars.realOptimizeFinalConstraintsVars
                             |> var => scalarVariableXML(simCode, var, varToArrayIndexMapping, indexForUndefinedReferencesReal, generateFMUModelDescription, complexStartExpressions, stateDerVectorName) ;separator="\n";empty*/%>
      <%vars.paramVars       |> var => scalarVariableXML(simCode, var, varToArrayIndexMapping, indexForUndefinedReferencesReal, generateFMUModelDescription, complexStartExpressions, stateDerVectorName) ;separator="\n";empty%>
      <%vars.aliasVars       |> var => scalarVariableXML(simCode, var, varToArrayIndexMapping, indexForUndefinedReferencesReal, generateFMUModelDescription, complexStartExpressions, stateDerVectorName) ;separator="\n";empty%>

      <%vars.intAlgVars      |> var => scalarVariableXML(simCode, var, varToArrayIndexMapping, indexForUndefinedReferencesInt, generateFMUModelDescription, complexStartExpressions, stateDerVectorName) ;separator="\n";empty%>
      <%vars.intParamVars    |> var => scalarVariableXML(simCode, var, varToArrayIndexMapping, indexForUndefinedReferencesInt, generateFMUModelDescription, complexStartExpressions, stateDerVectorName) ;separator="\n";empty%>
      <%vars.intAliasVars    |> var => scalarVariableXML(simCode, var, varToArrayIndexMapping, indexForUndefinedReferencesInt, generateFMUModelDescription, complexStartExpressions, stateDerVectorName) ;separator="\n";empty%>

      <%vars.boolAlgVars     |> var => scalarVariableXML(simCode, var, varToArrayIndexMapping, indexForUndefinedReferencesBool, generateFMUModelDescription, complexStartExpressions, stateDerVectorName) ;separator="\n";empty%>
      <%vars.boolParamVars   |> var => scalarVariableXML(simCode, var, varToArrayIndexMapping, indexForUndefinedReferencesBool, generateFMUModelDescription, complexStartExpressions, stateDerVectorName) ;separator="\n";empty%>
      <%vars.boolAliasVars   |> var => scalarVariableXML(simCode, var, varToArrayIndexMapping, indexForUndefinedReferencesBool, generateFMUModelDescription, complexStartExpressions, stateDerVectorName) ;separator="\n";empty%>

      <%vars.stringAlgVars   |> var => scalarVariableXML(simCode, var, varToArrayIndexMapping, indexForUndefinedReferencesString, generateFMUModelDescription, complexStartExpressions, stateDerVectorName) ;separator="\n";empty%>
      <%vars.stringParamVars |> var => scalarVariableXML(simCode, var, varToArrayIndexMapping, indexForUndefinedReferencesString, generateFMUModelDescription, complexStartExpressions, stateDerVectorName) ;separator="\n";empty%>
      <%vars.stringAliasVars |> var => scalarVariableXML(simCode, var, varToArrayIndexMapping, indexForUndefinedReferencesString, generateFMUModelDescription, complexStartExpressions, stateDerVectorName) ;separator="\n";empty%>
      >>
end modelVariablesXML;

template scalarVariableXML(SimCode simCode, SimVar simVar, HashTableCrIListArray.HashTable varToArrayIndexMapping, String indexForUndefinedReferences, Boolean generateFMUModelDescription, Text& complexStartExpressions, Text stateDerVectorName)
 "Generates code for ScalarVariable file for FMU target."
::=
  match simVar
    case SIMVAR(__) then
      let variableCode = if generateFMUModelDescription then CodegenFMUCommon.ScalarVariableType(simVar) else
                                                             ScalarVariableType(simCode, name, aliasvar, unit, displayUnit, minValue, maxValue, initialValue, nominalValue, isFixed, type_, complexStartExpressions, stateDerVectorName)
      <<
      <ScalarVariable <%scalarVariableAttributeXML(simVar, simCode, indexForUndefinedReferences, generateFMUModelDescription)%>>
        <%variableCode%>
      </ScalarVariable>
      >>
end scalarVariableXML;

template scalarVariableAttributeXML(SimVar simVar, SimCode simCode, String indexForUndefinedReferences, Boolean generateFMUModelDescription)
 "Generates code for ScalarVariable Attribute file for FMU target."
::=
  match simVar
    case SIMVAR(source = SOURCE(info = info)) then
      let valueReference = SimCodeUtil.getValueReference(simVar, simCode, true)
      let alias = getAliasAttribute(aliasvar)
      let causalityAtt = CodegenFMUCommon.getCausality(causality)
      let variability = getVariablity(varKind)
      let description = if comment then 'description="<%Util.escapeModelicaStringToXmlString(comment)%>"'
      let additionalAttributes = if generateFMUModelDescription then '' else 'isProtected="<%isProtected%>" hideResult="<%hideResult%>" isDiscrete="<%isDiscrete%>" isValueChangeable="<%isValueChangeable%>"'
      <<
      name="<%System.stringReplace(Util.escapeModelicaStringToXmlString(crefStrNoUnderscore(name)),"$", "_D_")%>" valueReference="<%valueReference%>" <%description%> variability="<%variability%>" causality="<%causalityAtt%>" alias="<%alias%>" <%additionalAttributes%>
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

template ScalarVariableType(SimCode simCode, DAE.ComponentRef simVarCref, AliasVariable simVarAlias, String unit, String displayUnit, Option<DAE.Exp> minValue, Option<DAE.Exp> maxValue, Option<DAE.Exp> startValue, Option<DAE.Exp> nominalValue, Boolean isFixed, DAE.Type type_, Text& complexStartExpressions, Text stateDerVectorName)
 "Generates code for ScalarVariable Type file for FMU target."
::=
  match type_
    case T_INTEGER(__) then '<Integer <%ScalarVariableTypeStartAttribute(simCode, simVarCref, simVarAlias, startValue, "Int", complexStartExpressions, stateDerVectorName)%><%ScalarVariableTypeFixedAttribute(isFixed)%><%ScalarVariableTypeIntegerMinAttribute(minValue)%><%ScalarVariableTypeIntegerMaxAttribute(maxValue)%><%ScalarVariableTypeUnitAttribute(unit)%><%ScalarVariableTypeDisplayUnitAttribute(displayUnit)%> />'
    case T_REAL(__) then '<Real <%ScalarVariableTypeStartAttribute(simCode, simVarCref, simVarAlias, startValue, "Real", complexStartExpressions, stateDerVectorName)%><%ScalarVariableTypeFixedAttribute(isFixed)%><%ScalarVariableTypeNominalAttribute(nominalValue)%><%ScalarVariableTypeRealMinAttribute(minValue)%><%ScalarVariableTypeRealMaxAttribute(maxValue)%><%ScalarVariableTypeUnitAttribute(unit)%><%ScalarVariableTypeDisplayUnitAttribute(displayUnit)%> />'
    case T_BOOL(__) then '<Boolean <%ScalarVariableTypeStartAttribute(simCode, simVarCref, simVarAlias, startValue, "Bool", complexStartExpressions, stateDerVectorName)%><%ScalarVariableTypeFixedAttribute(isFixed)%><%ScalarVariableTypeUnitAttribute(unit)%><%ScalarVariableTypeDisplayUnitAttribute(displayUnit)%> />'
    case T_STRING(__) then '<String <%ScalarVariableTypeStartAttribute(simCode, simVarCref, simVarAlias, startValue, "String", complexStartExpressions, stateDerVectorName)%><%ScalarVariableTypeFixedAttribute(isFixed)%><%ScalarVariableTypeUnitAttribute(unit)%><%ScalarVariableTypeDisplayUnitAttribute(displayUnit)%> />'
    case T_ENUMERATION(__) then '<Integer <%ScalarVariableTypeStartAttribute(simCode, simVarCref, simVarAlias, startValue, "Int", complexStartExpressions, stateDerVectorName)%><%ScalarVariableTypeFixedAttribute(isFixed)%><%ScalarVariableTypeUnitAttribute(unit)%><%ScalarVariableTypeDisplayUnitAttribute(displayUnit)%> />'
    case T_COMPLEX(complexClassType = ci as ClassInf.EXTERNAL_OBJ(__)) then '<ExternalObject path="<%escapeModelicaStringToXmlString(dotPath(ci.path))%>" />'
    else error(sourceInfo(), 'ScalarVariableType: <%unparseType(type_)%>')
end ScalarVariableType;

template ScalarVariableTypeStartAttribute(SimCode simCode, DAE.ComponentRef simVarCref, AliasVariable simVarAlias, Option<DAE.Exp> startValue, Text type, Text& complexStartExpressions, Text stateDerVectorName)
 "generates code for start attribute"
::=
  match startValue
    case SOME(exp) then
      let startString = StartString(exp)
      match startString
        case "" then
          let unsued = match simVarAlias
            case NOALIAS(__) then
              let &complexPreExpression = buffer ""
              let &varDecls = buffer ""
              let &extraFuncs = buffer ""
              let &extraFuncsDecl = buffer ""
              let crefStr = CodegenCppCommon.cref1(simVarCref, simCode , &extraFuncs, &extraFuncsDecl, "", contextOther, varDecls, stateDerVectorName, false)
              let expression = CodegenCppCommon.daeExp(exp, contextOther, &complexPreExpression, &varDecls, simCode, &extraFuncs , &extraFuncsDecl, "", stateDerVectorName, false)
              let &complexStartExpressions += '<%varDecls%><%complexPreExpression%>SystemDefaultImplementation::set<%type%>StartValue(<%crefStr%>,<%expression%>);<%\n%>'
              ''
            else ''
          'useStart="false"'
        else
          'useStart="true"<%startString%>'
    case NONE() then 'useStart="false"'
end ScalarVariableTypeStartAttribute;

template algLoopXML(SimEqSystem eqs, SimCode simCode, HashTableCrIListArray.HashTable varToArrayIndexMapping, String indexForUndefinedReferences)
::=
  <<
  <%
  match(eqs)
    case(SES_LINEAR(lSystem = ls as LINEARSYSTEM(__))) then
      <<
      <Linear eqIdx="<%ls.index%>" sparse="true" size="<%listLength(ls.vars)%>">
        <Vars>
          <%ls.vars |> v as SIMVAR(__) => '<Var type="double" index="<%SimCodeUtil.getVarIndexListByMapping(varToArrayIndexMapping,v.name,true,indexForUndefinedReferences)%>" />' ;separator="\n"%>
        </Vars>
      </Linear>
      >>
    case(SES_NONLINEAR(nlSystem = nls as NONLINEARSYSTEM(__))) then
      <<
      <NonLinear eqIdx="<%nls.index%>" size="<%listLength(nls.crefs)%>">
        <Vars>
          <%nls.crefs |> name => '<Var type="double" index="<%SimCodeUtil.getVarIndexListByMapping(varToArrayIndexMapping,name,true,indexForUndefinedReferences)%>" />' ;separator="\n"%>
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