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

package CodegenFMUCommon

import interface SimCodeTV;
import interface SimCodeBackendTV;
import CodegenUtil.*;
import CodegenC.*; //unqualified import, no need the CodegenC is optional when calling a template; or mandatory when the same named template exists in this package (name hiding)
import CodegenCFunctions.*;

template ModelExchange(SimCode simCode)
 "Generates ModelExchange code for ModelDescription file for FMU target."
::=
match simCode
case SIMCODE(__) then
  let modelIdentifier = modelNamePrefix(simCode)
  <<
  <ModelExchange
    modelIdentifier="<%modelIdentifier%>"<% if Flags.isSet(FMU_EXPERIMENTAL) then ' providesDirectionalDerivative="true"'%>>
  </ModelExchange>
  >>
end ModelExchange;

template fmiModelVariables(SimCode simCode, String FMUVersion)
 "Generates code for ModelVariables file for FMU target."
::=
match simCode
case SIMCODE(modelInfo=modelInfo) then
match modelInfo
case MODELINFO(vars=SIMVARS(stateVars=stateVars)) then
  <<
  <ModelVariables>
  <%System.tmpTickReset(0)%>
  <%vars.stateVars |> var =>
    ScalarVariable(var, simCode, stateVars, FMUVersion)
  ;separator="\n"%>
  <%vars.derivativeVars |> var =>
    ScalarVariable(var, simCode, stateVars, FMUVersion)
  ;separator="\n"%>
  <%vars.algVars |> var =>
    ScalarVariable(var, simCode, stateVars, FMUVersion)
  ;separator="\n"%>
  <%vars.discreteAlgVars |> var =>
    ScalarVariable(var, simCode, stateVars, FMUVersion)
  ;separator="\n"%>
  <%vars.paramVars |> var =>
    ScalarVariable(var, simCode, stateVars, FMUVersion)
  ;separator="\n"%>
  <%vars.aliasVars |> var =>
    ScalarVariable(var, simCode, stateVars, FMUVersion)
  ;separator="\n"%>
  <%System.tmpTickReset(0)%>
  <%vars.intAlgVars |> var =>
    ScalarVariable(var, simCode, stateVars, FMUVersion)
  ;separator="\n"%>
  <%vars.intParamVars |> var =>
    ScalarVariable(var, simCode, stateVars, FMUVersion)
  ;separator="\n"%>
  <%vars.intAliasVars |> var =>
    ScalarVariable(var, simCode, stateVars, FMUVersion)
  ;separator="\n"%>
  <%System.tmpTickReset(0)%>
  <%vars.boolAlgVars |> var =>
    ScalarVariable(var, simCode, stateVars, FMUVersion)
  ;separator="\n"%>
  <%vars.boolParamVars |> var =>
    ScalarVariable(var, simCode, stateVars, FMUVersion)
  ;separator="\n"%>
  <%vars.boolAliasVars |> var =>
    ScalarVariable(var, simCode, stateVars, FMUVersion)
  ;separator="\n"%>
  <%System.tmpTickReset(0)%>
  <%vars.stringAlgVars |> var =>
    ScalarVariable(var, simCode, stateVars, FMUVersion)
  ;separator="\n"%>
  <%vars.stringParamVars |> var =>
    ScalarVariable(var, simCode, stateVars, FMUVersion)
  ;separator="\n"%>
  <%vars.stringAliasVars |> var =>
    ScalarVariable(var, simCode, stateVars, FMUVersion)
  ;separator="\n"%>
  <%System.tmpTickReset(0)%>
  <%externalFunctions(modelInfo)%>
  </ModelVariables>
  >>
end fmiModelVariables;

template ScalarVariable(SimVar simVar, SimCode simCode, list<SimVar> stateVars, String FMUVersion)
 "Generates code for ScalarVariable file for FMU target."
::=
match simVar
case SIMVAR(__) then
  if stringEq(crefStr(name),"$dummy") then
  <<>>
  else if stringEq(crefStr(name),"der($dummy)") then
  <<>>
  else if isFMIVersion20(FMUVersion) then
  <<
  <!-- Index of variable = "<%getVariableIndex(simVar)%>" -->
  <ScalarVariable
    <%ScalarVariableAttribute2(simVar, simCode)%>>
    <%ScalarVariableType2(simVar, stateVars)%>
  </ScalarVariable>
  >>
  else
  <<
  <ScalarVariable
    <%ScalarVariableAttribute(simVar)%>>
    <%ScalarVariableType(simVar)%>
  </ScalarVariable>
  >>
end ScalarVariable;

template ScalarVariableAttribute(SimVar simVar)
 "Generates code for ScalarVariable Attribute file for FMU target."
::=
match simVar
  case SIMVAR(__) then
  let valueReference = '<%System.tmpTick()%>'
  let variability = getVariability(varKind)
  let description = if comment then 'description="<%Util.escapeModelicaStringToXmlString(comment)%>"'
  let alias = getAliasVar(aliasvar)
  let caus = getCausality(causality)
  <<
  name="<%System.stringReplace(crefStrNoUnderscore(name),"$", "_D_")%>"
  valueReference="<%valueReference%>"
  <%description%>
  variability="<%variability%>"
  causality="<%caus%>"
  alias="<%alias%>"
  >>
end ScalarVariableAttribute;

template getCausality(Causality c)
 "Returns the Causality Attribute of ScalarVariable."
::=
match c
  case NONECAUS(__) then "none"
  case INTERNAL(__) then "internal"
  case OUTPUT(__) then "output"
  case INPUT(__) then "input"
end getCausality;

template getVariability(VarKind varKind)
 "Returns the variability Attribute of ScalarVariable."
::=
match varKind
  case DISCRETE(__) then "discrete"
  case PARAM(__) then "parameter"
  case CONST(__) then "constant"
  else "continuous"
end getVariability;

template getAliasVar(AliasVariable aliasvar)
 "Returns the alias Attribute of ScalarVariable."
::=
match aliasvar
  case NOALIAS(__) then "noAlias"
  /* We don't handle the alias and negatedAlias properly. If a variable is alias it must get the valueReference of the aliased variable. */
  /*case ALIAS(__) then "alias"
  case NEGATEDALIAS(__) then "negatedAlias"
  */
  else "noAlias"
end getAliasVar;

template ScalarVariableType(SimVar simvar)
 "Generates code for ScalarVariable Type file for FMU target."
::=
match simvar
case SIMVAR(__) then
  match type_
    case T_INTEGER(__) then '<Integer<%StartString(simvar)%>/>'
    /* Don't generate the units for now since it is wrong. If you generate a unit attribute here then we must add the UnitDefinitions tag section also. */
    case T_REAL(__) then '<Real<%StartString(simvar)/*%> <%ScalarVariableTypeRealAttribute(unit,displayUnit)*/%>/>'
    case T_BOOL(__) then '<Boolean<%StartString(simvar)%>/>'
    case T_STRING(__) then '<String<%StartString(simvar)%>/>'
    case T_ENUMERATION(__) then '<Enumeration declaredType="<%Absyn.pathString(path, ".", false)%>"<%StartString(simvar)%>/>'
    else 'UNKOWN_TYPE'
end ScalarVariableType;

template StartString(SimVar simvar)
::=
match simvar
case SIMVAR(initialValue = initialValue, causality = causality, type_ = type_) then
  match initialValue
    case SOME(e as ICONST(__)) then ' start="<%initValXml(e)%>"'
    case SOME(e as RCONST(__)) then ' start="<%initValXml(e)%>"'
    case SOME(e as SCONST(__)) then ' start="<%initValXml(e)%>"'
    case SOME(e as BCONST(__)) then ' start="<%initValXml(e)%>"'
    case SOME(e as ENUM_LITERAL(__)) then ' start="<%initValXml(e)%>"'
    else
      match causality
        case INPUT(__) then ' start="<%initDefaultValXml(type_)%>"'
        else ''
end StartString;

template ScalarVariableTypeRealAttribute(String unit, String displayUnit)
 "Generates code for ScalarVariable Type Real file for FMU target."
::=
  let unit_ = if unit then 'unit="<%unit%>"'
  let displayUnit_ = if displayUnit then 'displayUnit="<%displayUnit%>"'
  <<
  <%unit_%> <%displayUnit_%>
  >>
end ScalarVariableTypeRealAttribute;

template externalFunctions(ModelInfo modelInfo)
 "Generates external function definitions."
::=
match modelInfo
case MODELINFO(__) then
  (functions |> fn => externalFunction(fn) ; separator="\n")
end externalFunctions;

template externalFunction(Function fn)
 "Generates external function definitions."
::=
  match fn
    case EXTERNAL_FUNCTION(dynamicLoad=true) then
      let fname = extFunctionName(extName, language)
      <<
      <ExternalFunction
        name="<%fname%>"
        valueReference="<%System.tmpTick()%>"/>
      >>
end externalFunction;

template Implementation()
 "Generate Co-simulation Implementation section"
::=
  <<
  <Implementation>
    <CoSimulation_StandAlone>
      <Capabilities
        canHandleVariableCommunicationStepSize="true"
        canHandleEvents="true"
        canBeInstantiatedOnlyOncePerProcess="false"
        canInterpolateInputs="true"
        maxOutputDerivativeOrder="1"/>
    </CoSimulation_StandAlone>
  </Implementation>
  >>
end Implementation;

template ModelStructure(Option<FmiModelStructure> fmiModelStructure)
 "Generates ModelStructure"
::=
match fmiModelStructure
case SOME(fmistruct as FMIMODELSTRUCTURE(__)) then
  <<
  <ModelStructure>
    <%ModelStructureOutputs(fmistruct.fmiOutputs)%>
    <%ModelStructureDerivatives(fmistruct.fmiDerivatives)%>
    <%ModelStructureDiscreteStates(fmistruct.fmiDiscreteStates)%>
    <%ModelStructureInitialUnknowns(fmistruct.fmiInitialUnknowns)%>
  </ModelStructure>
  >>
else
  <<
  <ModelStructure>
  </ModelStructure>
  >>
end ModelStructure;

template TypeDefinitionsClocks(SimCode simCode)
 "Generates TypeDefinitions Clocks"
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let clocks = (clockedPartitions |> partition =>
    match partition
    case CLOCKED_PARTITION(baseClock=baseClock, subPartitions=subPartitions) then
      match baseClock
      case REAL_CLOCK(interval=baseInterval as RCONST(real=bi)) then
        (subPartitions |> subPartition =>
          match subPartition
          case SUBPARTITION(subClock=SUBCLOCK(factor=RATIONAL(nom=fnom, denom=fres), shift=RATIONAL(nom=snom, denom=sres))) then
          <<
          <Clock><Periodic
                  baseInterval="<%bi%>"
                  <%if intGt(fnom, 1) then 'subSampleFactor="'+fnom+'"'%>
                  <%if intGt(fres, 1) then 'superSampleFactor="'+fres+'"'%>
                  <%if intGt(snom, 0) then 'shiftCounter="'+snom+'"'%>
                  /></Clock>
          >>
        ; separator="\n")
      case INTEGER_CLOCK(intervalCounter=ic as ICONST(integer=bic), resolution=res as ICONST(integer=resi)) then
        (subPartitions |> subPartition =>
          match subPartition
          case SUBPARTITION(subClock=SUBCLOCK(factor=RATIONAL(nom=fnom, denom=fres), shift=RATIONAL(nom=snom, denom=sres))) then
          <<
          <Clock><Periodic
                  intervalCounter="<%bic%>"
                  resolution="<%resi%>"
                  <%if intGt(fnom, 1) then 'subSampleFactor="'+fnom+'"'%>
                  <%if intGt(snom, 0) then 'shiftCounter="'+snom+'"'%>
                  /></Clock>
          >>
        ; separator="\n")
      case INFERRED_CLOCK(__) then
        <<
        <Clock><Inferred/></Clock>
        >>
      else
        <<
        <Clock><Triggered/></Clock>
        >>
    ;separator="\n")
  match clocks
  case "" then
    <<>>
  else
    <<
    <Clocks>
      <%clocks%>
    </Clocks>
    >>
end TypeDefinitionsClocks;

template ModelStructureOutputs(FmiOutputs fmiOutputs)
 "Generates Model Structure Outputs."
::=
match fmiOutputs
case FMIOUTPUTS(__) then
  <<
  <Outputs>
    <%ModelStructureUnknowns(fmiUnknownsList)%>
  </Outputs>
  >>
end ModelStructureOutputs;

template ModelStructureDerivatives(FmiDerivatives fmiDerivatives)
 "Generates Model Structure Derivatives."
::=
match fmiDerivatives
case FMIDERIVATIVES(__) then
  <<
  <Derivatives>
    <%ModelStructureUnknowns(fmiUnknownsList)%>
  </Derivatives>
  >>
end ModelStructureDerivatives;

template ModelStructureDiscreteStates(FmiDiscreteStates fmiDiscreteStates)
 "Generates Model Structure DiscreteStates."
::=
match fmiDiscreteStates
case FMIDISCRETESTATES(__) then
  if intGt(listLength(fmiUnknownsList), 0) then
  <<
  <DiscreteStates>
    <%ModelStructureUnknowns(fmiUnknownsList)%>
  </DiscreteStates>
  >>
  else
  // don't generate if model has no discrete states for FMI 2.0 compatibility
  <<>>
end ModelStructureDiscreteStates;

template ModelStructureInitialUnknowns(FmiInitialUnknowns fmiInitialUnknowns)
 "Generates Model Structure InitialUnknowns."
::=
match fmiInitialUnknowns
case FMIINITIALUNKNOWNS(__) then
  if listEmpty(fmiUnknownsList)
  then
  ''
  else
  <<
  <InitialUnknowns>
    <%ModelStructureUnknowns(fmiUnknownsList)%>
  </InitialUnknowns>
  >>
end match
end ModelStructureInitialUnknowns;

template ModelStructureUnknowns(list<FmiUnknown> fmiUnknownsList)
 "Generates Model Structure Unknowns"
::=
  <<
  <%fmiUnknownsList |> fmiUnknown => FmiUnknownAttributes(fmiUnknown) ;separator="\n"%>
  >>
end ModelStructureUnknowns;

template FmiUnknownAttributes(FmiUnknown fmiUnknown)
 "Generates Model Structure Unknown attributes"
::=
match fmiUnknown
case FMIUNKNOWN(__) then
  <<
  <Unknown index="<%index%>"<%FmiUnknownDependencies(dependencies)%><%FmiUnknownDependenciesKind(dependenciesKind)%> />
  >>
end FmiUnknownAttributes;

template FmiUnknownDependencies(list<Integer> dependencies)
::=
  // Note: dependencies="" means no dependencies;
  // missing dependencies means dependent on all knowns (see FMI 2.0 spec).
  <<
   dependencies="<%dependencies |> dependency => dependency ;separator=" "%>"
  >>
end FmiUnknownDependencies;

template FmiUnknownDependenciesKind(list<String> dependenciesKind)
::=
  <<
   dependenciesKind="<%dependenciesKind |> dependencyKind => dependencyKind ;separator=" "%>"
  >>
end FmiUnknownDependenciesKind;

template ScalarVariableAttribute2(SimVar simVar, SimCode simCode)
 "Generates code for ScalarVariable Attribute file for FMU 2.0 target."
::=
match simVar
  case SIMVAR(__) then
  let defaultValueReference = '<%System.tmpTick()%>'
  let valueReference = getValueReference(simVar, simCode, false)
  let description = if comment then 'description="<%Util.escapeModelicaStringToXmlString(comment)%>"'
  let variability = if getClockIndex(simVar, simCode) then "discrete" else getVariability2(varKind, type_)
  let clockIndex = getClockIndex(simVar, simCode)
  let previous = match varKind case CLOCKED_STATE(__) then '<%getVariableIndex(cref2simvar(previousName, simCode))%>'
  let caus = getCausality2(causality, varKind, isValueChangeable)
  let initial = getInitialType2(variability, caus, initialValue)
  <<
  name="<%System.stringReplace(crefStrNoUnderscore(name),"$", "_D_")%>"
  valueReference="<%valueReference%>"
  <%description%>
  variability="<%variability%>"
  causality="<%caus%>"
  <%if boolNot(stringEq(clockIndex, "")) then 'clockIndex="'+clockIndex+'"' %>
  <%if boolNot(stringEq(previous, "")) then 'previous="'+previous+'"' %>
  <%if boolNot(stringEq(initial, "")) then match aliasvar case SimCodeVar.ALIAS(__) then "" else 'initial="'+initial+'"' %>
  >>
end ScalarVariableAttribute2;

template getVariability2(VarKind varKind, DAE.Type type_)
 "Returns the variability Attribute of ScalarVariable."
::=
match varKind
  case DISCRETE(__) then "discrete"
  case PARAM(__) then "fixed"
  /*case PARAM(__) then "tunable"*/  /*TODO! Don't know how tunable variables are represented in OpenModelica.*/
  case CONST(__) then "constant"
  else
  match type_
    case T_REAL(__) then "continuous"
    else "discrete"
end getVariability2;

template getCausality2(Causality c, VarKind varKind, Boolean isValueChangeable)
 "Returns the Causality Attribute of ScalarVariable."
::=
match c
  case NONECAUS(__) then getCausality2Helper(varKind, isValueChangeable)
  case INTERNAL(__) then getCausality2Helper(varKind, isValueChangeable)
  case OUTPUT(__) then "output"
  case INPUT(__) then "input"
  /*TODO! Handle "independent" causality.*/
  else "local"
end getCausality2;

template getCausality2Helper(VarKind varKind, Boolean isValueChangeable)
::=
match varKind
  case PARAM(__) then if isValueChangeable then "parameter" else "calculatedParameter"
  else "local"
end getCausality2Helper;

template getNumberOfEventIndicators(SimCode simCode)
 "Get the number of event indicators, which depends on the selected code target (c or cpp)."
::=
match simCode
  case SIMCODE(zeroCrossings = zeroCrossings, modelInfo = MODELINFO(varInfo = vi as VARINFO(__))) then
    match Config.simCodeTarget()
      case "Cpp" then listLength(zeroCrossings)
      else vi.numZeroCrossings
    end match
  else ""
end getNumberOfEventIndicators;

template getInitialType2(String variability, String causality, Option<DAE.Exp> initialValue)
 "Returns the Initial Attribute of ScalarVariable."
::=
match variability
  case "constant" then
    match causality
      case "output"
      case "local" then "exact"
      else ""
  case "fixed"
  case "tunable" then
    match causality
      case "parameter" then "exact"
      case "calculatedParameter"
      case "local" then "calculated"
      else ""
  case "discrete"
  case "continuous" then
    match causality
      case "output"
      case "local" then
        match initialValue
        case SOME(exp) then "exact"
        else "calculated"
      else ""
  else ""
end getInitialType2;

template ScalarVariableType2(SimVar simvar, list<SimVar> stateVars)
 "Generates code for ScalarVariable Type file for FMU 2.0 target.
  - Don't generate the units for now since it is wrong. If you generate a unit attribute here then we must add the UnitDefinitions tag section also.
 "
::=
match simvar
case SIMVAR(__) then
  match type_
    case T_REAL(__) then '<Real<%ScalarVariableTypeCommonAttribute2(simvar, stateVars)%>/>'
    case T_INTEGER(__) then '<Integer<%ScalarVariableTypeCommonAttribute2(simvar, stateVars)%>/>'
    case T_BOOL(__) then '<Boolean<%ScalarVariableTypeCommonAttribute2(simvar, stateVars)%>/>'
    case T_STRING(__) then '<String<%ScalarVariableTypeCommonAttribute2(simvar, stateVars)%>/>'
    case T_ENUMERATION(__) then '<Enumeration declaredType="<%Absyn.pathString(path, ".", false)%>"<%ScalarVariableTypeCommonAttribute2(simvar, stateVars)%>/>'
    else 'UNKOWN_TYPE'
end ScalarVariableType2;

template ScalarVariableTypeCommonAttribute2(SimVar simvar, list<SimVar> stateVars)
 "Generates code for ScalarVariable Type file for FMU 2.0 target."
::=
match simvar
case SIMVAR(varKind = varKind, isValueChangeable = isValueChangeable, index = index) then
  match varKind
  case STATE_DER(__) then ' derivative="<%getStateSimVarIndexFromIndex(stateVars, index)%>"'
  case PARAM(__) then if isValueChangeable then '<%StartString2(simvar)%><%MinString2(simvar)%><%MaxString2(simvar)%><%NominalString2(simvar)%>' else '<%MinString2(simvar)%><%MaxString2(simvar)%><%NominalString2(simvar)%>'
  else '<%StartString2(simvar)%><%MinString2(simvar)%><%MaxString2(simvar)%><%NominalString2(simvar)%>'
end ScalarVariableTypeCommonAttribute2;

template StartString2(SimVar simvar)
::=
match simvar
case SIMVAR(aliasvar = SimCodeVar.ALIAS(__)) then
  ''
case SIMVAR(initialValue = initialValue, varKind = varKind, causality = causality, type_ = type_, isValueChangeable = isValueChangeable) then
  match initialValue
    case SOME(e as ICONST(__)) then ' start="<%initValXml(e)%>"'
    case SOME(e as RCONST(__)) then ' start="<%initValXml(e)%>"'
    case SOME(e as SCONST(__)) then ' start="<%initValXml(e)%>"'
    case SOME(e as BCONST(__)) then ' start="<%initValXml(e)%>"'
    case SOME(e as ENUM_LITERAL(__)) then ' start="<%initValXml(e)%>"'
    else
      let variability = getVariability2(varKind, type_)
      let caus = getCausality2(causality, varKind, isValueChangeable)
      let initial = getInitialType2(variability, caus, initialValue)
      if boolOr(stringEq(initial, "exact"), boolOr(stringEq(initial, "approx"), stringEq(caus, "input"))) then ' start="<%initDefaultValXml(type_)%>"'
      else ''
end StartString2;

template MinString2(SimVar simvar)
::=
match simvar
case SIMVAR(minValue = minValue) then
  match minValue
    case SOME(e as ICONST(__)) then ' min="<%initValXml(e)%>"'
    case SOME(e as RCONST(__)) then ' min="<%initValXml(e)%>"'
    case SOME(e as SCONST(__)) then ' min="<%initValXml(e)%>"'
    case SOME(e as BCONST(__)) then ' min="<%initValXml(e)%>"'
    case SOME(e as ENUM_LITERAL(__)) then ' min="<%initValXml(e)%>"'
    else ''
end MinString2;

template MaxString2(SimVar simvar)
::=
match simvar
case SIMVAR(maxValue = maxValue) then
  match maxValue
    case SOME(e as ICONST(__)) then ' max="<%initValXml(e)%>"'
    case SOME(e as RCONST(__)) then ' max="<%initValXml(e)%>"'
    case SOME(e as SCONST(__)) then ' max="<%initValXml(e)%>"'
    case SOME(e as BCONST(__)) then ' max="<%initValXml(e)%>"'
    case SOME(e as ENUM_LITERAL(__)) then ' max="<%initValXml(e)%>"'
    else ''
end MaxString2;

template NominalString2(SimVar simvar)
::=
match simvar
case SIMVAR(nominalValue = nominalValue) then
  match nominalValue
    case SOME(e as RCONST(__)) then ' nominal="<%initValXml(e)%>"'
    else ''
end NominalString2;

template statesnumwithDummy(list<SimVar> vars)
" return number of states without dummy vars"
::=
 (vars |> var =>  match var case SIMVAR(__) then if stringEq(crefStr(name),"$dummy") then '0' else '1' ;separator="\n")
end statesnumwithDummy;

template xsdateTime(DateTime dt)
 "YYYY-MM-DDThh:mm:ssZ"
::=
  match dt
  case DATETIME(__) then '<%year%>-<%twodigit(mon)%>-<%twodigit(mday)%>T<%twodigit(hour)%>:<%twodigit(min)%>:<%twodigit(sec)%>Z'
end xsdateTime;

template UnitDefinitions(SimCode simCode)
 "Generates code for UnitDefinitions file for FMU target."
::=
match simCode
case SIMCODE(__) then
  <<
  <UnitDefinitions>
  </UnitDefinitions>
  >>
end UnitDefinitions;

template fmiTypeDefinitions(SimCode simCode, String FMUVersion)
 "Generates code for TypeDefinitions for FMU target."
::=
match simCode
case SIMCODE(modelInfo=modelInfo) then
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  <%TypeDefinitionsHelper(simCode, SimCodeUtil.getEnumerationTypes(vars), FMUVersion)%>
  >>
end fmiTypeDefinitions;

template TypeDefinitionsHelper(SimCode simCode, list<SimCodeVar.SimVar> vars, String FMUVersion)
 "Generates code for TypeDefinitions for FMU target."
::=
  let clocks = if isFMIVersion10(FMUVersion) then "" else TypeDefinitionsClocks(simCode)
  if boolOr(intGt(listLength(vars), 0), boolNot(stringEq(clocks, ""))) then
  <<
  <TypeDefinitions>
    <%vars |> var => TypeDefinition(var,FMUVersion) ;separator="\n"%>
    <%clocks%>
  </TypeDefinitions>
  >>
end TypeDefinitionsHelper;

template TypeDefinition(SimVar simVar, String FMUVersion)
::=
match simVar
case SIMVAR(__) then
  <<
  <%TypeDefinitionType(type_,FMUVersion)%>
  >>
end TypeDefinition;

template TypeDefinitionType(DAE.Type type_, String FMUVersion)
 "Generates code for TypeDefinitions Type file for FMU target."
::=
match type_
  case T_ENUMERATION(__) then
  if isFMIVersion20(FMUVersion) then
  <<
  <SimpleType name="<%Absyn.pathString(path, ".", false)%>">
    <Enumeration>
      <%names |> name hasindex i0 fromindex 1 => '<Item name="<%name%>" value="<%i0%>"/>' ;separator="\n"%>
    </Enumeration>
  </SimpleType>
  >>
  else
  <<
  <Type name="<%Absyn.pathString(path, ".", false)%>">
    <EnumerationType>
      <%names |> name => '<Item name="<%name%>"/>' ;separator="\n"%>
    </EnumerationType>
  </Type>
  >>
end TypeDefinitionType;

template DefaultExperiment(Option<SimulationSettings> simulationSettingsOpt)
 "Generates code for DefaultExperiment file for FMU target."
::=
match simulationSettingsOpt
  case SOME(v) then
    <<
    <DefaultExperiment <%DefaultExperimentAttribute(v)%>/>
    >>
end DefaultExperiment;

template DefaultExperimentAttribute(SimulationSettings simulationSettings)
 "Generates code for DefaultExperiment Attribute file for FMU target."
::=
match simulationSettings
  case SIMULATION_SETTINGS(__) then
    <<
    startTime="<%startTime%>" stopTime="<%stopTime%>" tolerance="<%tolerance%>"
    >>
end DefaultExperimentAttribute;

annotation(__OpenModelica_Interface="backend");
end CodegenFMUCommon;

// vim: filetype=susan sw=2 sts=2
