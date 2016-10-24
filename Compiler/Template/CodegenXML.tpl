// This file defines templates for transforming flattened Modelica code to Xml code.
// + Optimica code to XML code
// @author Alachew Shitahun <alash325@student.liu.se> - Some of the template taken from CodegenC.tpl

package CodegenXML

import interface SimCodeTV;
import ExpressionDumpTpl;


/*********************************************************************
 *         SECTION: SIMULATION TARGET, ROOT TEMPLATE
 *********************************************************************/

template translateModel(SimCode simCode)
 "Generates root template for compiling a simulation of a Modelica model."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
    let() = textFile(generateXml(simCode), '<%dotPathXml(modelInfo.name)%>.xml')
    "" //always returns an empty result since generated texts are written to files directly
end translateModel;

/*********************************************************************
 *     SECTION: SIMULATION TARGET, XML FILE SPECIFIC TEMPLATES
 *********************************************************************/

template generateXml(SimCode simCode)
 "Generates XML code for simulation file."
::=
match simCode
case SIMCODE(modelInfo = MODELINFO(__)) then
  let guid = getUUIDStr()
  <<
  <?xml version="1.0" encoding="UTF-8"?>
  <OpenModelicaModelDescription
    xmlns:exp="https://svn.jmodelica.org/trunk/XML/daeExpressions.xsd"
    xmlns:equ="https://svn.jmodelica.org/trunk/XML/daeEquations.xsd"
    xmlns:fun="https://svn.jmodelica.org/trunk/XML/daeFunctions.xsd"
    xmlns:opt="https://svn.jmodelica.org/trunk/XML/daeOptimization.xsd"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    <%modelDescriptionXml(simCode,guid)%>
    >

    <%vendorAnnotationsXml(simCode)%>

    <%defaultExperiment(simulationSettingsOpt)%>

    <%modelVariablesXml(modelInfo)%>

    <%bindingEquationsXml(modelInfo)%>

    <%equationsXml(allEquations)%>

    <%initialEquationsXml(modelInfo, initialEquations)%>

    <%algorithmicEquationsXml(allEquations)%>

    <%recordsXml(recordDecls)%>

    <%functionsXml(modelInfo.functions)%>

    <%objectiveFunctionXml(classAttributes, simCode)%>

  </OpenModelicaModelDescription>
  >>
 end generateXml;

 /***********************************************************************************
 *      SECTION: GENERATE XML for MODEL DESCRIPTION AND SCALAR VARIABLES IN SIMULATION FILE
 *************************************************************************************/

template vendorAnnotationsXml(SimCode simCode)
::=
 match simCode
 case SIMCODE(modelInfo = MODELINFO(varInfo = VARINFO(__))) then
  let generationTool= 'OpenModelica Compiler <%getVersionNr()%>'
  <<
  <VendorAnnotations>
    <Tool name="<%generationTool%>"> </Tool>
  </VendorAnnotations>
  >>
end vendorAnnotationsXml;

template modelDescriptionXml(SimCode simCode, String guid) ::=
match simCode
case SIMCODE(modelInfo = MODELINFO(varInfo = VARINFO(__))) then
  let fmiVersion = '1.0'
  let modelName = dotPathXml(modelInfo.name)
  let modelIdentifier = System.stringReplace(fileNamePrefix,".", "_")
  let description = ''
  let author = ''
  let version= ''
  let generationDateAndTime = xsdateTimeXml(getCurrentDateTime())
  let variableNamingConvention= 'structured'
  let numberOfContinuousStates =modelInfo.varInfo.numStateVars
  let numberOfEventIndicators =modelInfo.varInfo.numZeroCrossings
  <<
  fmiVersion="<%fmiVersion%>"
  modelName="<%modelName%>"
  modelIdentifier="<%modelIdentifier%>"
  guid="{<%guid%>}"
  generationDateAndTime="<%generationDateAndTime%>"
  variableNamingConvention="<%variableNamingConvention%>"
  numberOfContinuousStates="<%numberOfContinuousStates%>"
  numberOfEventIndicators="<%numberOfEventIndicators%>"
 >>
end modelDescriptionXml;

template xsdateTimeXml(DateTime dt)
 "YYYY-MM-DDThh:mm:ss"
::=
  match dt
    case DATETIME(__) then
      <<
      <%year%>-<%twodigit(mon)%>-<%twodigit(mday)%>T<%twodigit(hour)%>:<%twodigit(min)%>:<%twodigit(sec)%>
      >>
end xsdateTimeXml;

template defaultExperiment(Option<SimulationSettings> simulationSettingsOpt)
 "Generates code for defaultExperiment file for FMU target."
::=
match simulationSettingsOpt
  case SOME(de as  SIMULATION_SETTINGS(__)) then
  <<
  <DefaultExperiment startTime="<%de.startTime%>" stopTime="<%de.stopTime%>" tolerance="<%de.tolerance%>" />
  >>
end defaultExperiment;

template modelVariablesXml(ModelInfo modelInfo)
 "Generates XML code for ModelVariables file ."
::=
match modelInfo
case MODELINFO(vars=SIMVARS(__)) then
  <<
  <ModelVariables>
  <%vars.stateVars |> var => ScalarVariableXml(var) ;separator="\n"%>
  <%vars.derivativeVars |> var => ScalarVariableXml(var) ;separator="\n"%>
  <%vars.algVars |> var => ScalarVariableXml(var) ;separator="\n"%>
  <%vars.discreteAlgVars |> var => ScalarVariableXml(var) ;separator="\n"%>
  <%vars.intAlgVars |> var => ScalarVariableXml(var) ;separator="\n"%>
  <%vars.boolAlgVars |> var => ScalarVariableXml(var) ;separator="\n"%>
  <%/*vars.inputVars |> var => ScalarVariableXml(var) ;separator="\n"*/%>
  <%vars.outputVars |> var => ScalarVariableXml(var) ;separator="\n"%>
  <%vars.aliasVars |> var => ScalarVariableXml(var) ;separator="\n"%>
  <%vars.intAliasVars |> var => ScalarVariableXml(var) ;separator="\n"%>
  <%vars.boolAliasVars |> var => ScalarVariableXml(var) ;separator="\n"%>
  <%vars.paramVars |> var => ScalarVariableXml(var) ;separator="\n"%>
  <%vars.intParamVars |> var => ScalarVariableXml(var) ;separator="\n"%>
  <%vars.boolParamVars |> var => ScalarVariableXml(var) ;separator="\n"%>
  <%vars.stringAlgVars |> var => ScalarVariableXml(var) ; separator="\n"%>
  <%vars.stringParamVars |> var => ScalarVariableXml(var) ; separator="\n"%>
  <%vars.stringAliasVars |> var => ScalarVariableXml(var) ; separator="\n"%>
  <%vars.extObjVars |> var => ScalarVariableXml(var) ; separator="\n"%>
  <%vars.constVars |> var => ScalarVariableXml(var) ; separator="\n"%>
  <%vars.intConstVars |> var => ScalarVariableXml(var) ; separator="\n"%>
  <%vars.boolConstVars |> var => ScalarVariableXml(var) ; separator="\n"%>
  <%vars.stringConstVars |> var => ScalarVariableXml(var) ; separator="\n"%>
  </ModelVariables><%\n%>
  >>
end modelVariablesXml;

template ScalarVariableXml(SimVar simVar)
 "Generates XML code for ScalarVariable file ."
::=
match simVar
case SIMVAR(__) then
  <<
  <%ScalarVariableAttributesXml(simVar)%>
  >>
end ScalarVariableXml;

template ScalarVariableAttributesXml(SimVar simVar)
 "Generates XML code for ScalarVariable Attribute file ."
::=
match simVar
case SIMVAR(__) then
  let valueReference = '<%System.tmpTick()%>'
  let variability = getVariablityXml(varKind)
  let description = if comment then 'description="<%Util.escapeModelicaStringToXmlString(comment)%>"'
  let alias = getAliasVarXml(aliasvar)
  let caus = getCausalityXml(causality)
  let variableCategory = variableCategoryXml(varKind)
  <<
    <ScalarVariable name="<%crefStrXml(name)%>" <%description%> valueReference="<%valueReference%>" variability="<%variability%>" causality="<%caus%>" alias="<%alias%>">
      <%ScalarVariableTypeXml(type_,unit,displayUnit, minValue, maxValue, initialValue,isFixed)%>
      <QualifiedName>
        <%qualifiedNamePartXml(name)%>
      </QualifiedName>
    <isLinearTimedVariables>
      <TimePoint index="0" isLinear="true"/>
    </isLinearTimedVariables>
      <VariableCategory><%variableCategory%></VariableCategory>
    </ScalarVariable> <%\n%>
  >>
end ScalarVariableAttributesXml;

template getCausalityXml(Causality c)
 "Returns the Causality Attribute of ScalarVariable."
::=
match c
  case NONECAUS(__) then "none"
  case INTERNAL(__) then "internal"
  case OUTPUT(__) then "output"
  case INPUT(__) then "input"
end getCausalityXml;

template getVariablityXml(VarKind varKind)
 "Returns the variablity Attribute of ScalarVariable."
::=
match varKind
  case DISCRETE(__) then "discrete"
  case PARAM(__) then "parameter"
  case CONST(__) then "constant"
  else "continuous"
end getVariablityXml;

template getAliasVarXml(AliasVariable aliasvar)
 "Returns the alias Attribute of ScalarVariable."
::=
match aliasvar
  case NOALIAS(__) then "noAlias"
  case ALIAS(__) then '<%crefStrXml(varName)%>'
  case NEGATEDALIAS(__) then '-<%crefStrXml(varName)%>'
  else ""
end getAliasVarXml;

template variableCategoryXml(VarKind varKind)
 "Returns the variable category of ScalarVariable."
::=
  match varKind
  case VARIABLE(__)     then "algebraic"
  case STATE(__)        then "state"
  case STATE_DER(__)    then "derivative"
  case DUMMY_DER(__)    then "algebraic"
  case DUMMY_STATE(__)  then "algebraic"
  case DISCRETE(__)     then "algebraic"
  case PARAM(__)        then "independentParameter"
  case CONST(__)        then "independentConstant"
  case EXTOBJ(__)       then 'externalObject_<%dotPathXml(fullClassName)%>'
  case JAC_VAR(__)      then "jacobianVar"
  case JAC_DIFF_VAR(__) then "jacobianDiffVar"
  else error(sourceInfo(), "Unexpected simVarTypeName varKind")
end variableCategoryXml;

template ScalarVariableTypeXml(DAE.Type type_, String unit, String displayUnit, Option<DAE.Exp> minValue, Option<DAE.Exp> maxValue, Option<DAE.Exp> initialValue, Boolean isFixed)
 "Generates XML code for ScalarVariable Type file."
::=
match type_
  case T_INTEGER(__) then '<Integer <%ScalarVariableTypeCommonAttributeXml(initialValue,isFixed)%> <%ScalarVariableTypeMinAttribute(minValue)%> <%ScalarVariableTypeMaxAttribute(maxValue)%>/>'
  case T_REAL(__) then '<Real <%ScalarVariableTypeCommonAttributeXml(initialValue,isFixed)%> <%ScalarVariableTypeMinAttribute(minValue)%> <%ScalarVariableTypeMaxAttribute(maxValue)%> <%ScalarVariableTypeRealAttributeXml(unit,displayUnit)%>/>'
  case T_BOOL(__) then '<Boolean <%ScalarVariableTypeCommonAttributeXml(initialValue,isFixed)%>/>'
  case T_STRING(__) then '<String <%ScalarVariableTypeCommonAttributeXml(initialValue,isFixed)%>/>'
  case T_ENUMERATION(__) then '<Real <%ScalarVariableTypeCommonAttributeXml(initialValue,isFixed)%>/>'
  else 'UNKOWN_TYPE'
end ScalarVariableTypeXml;

template ScalarVariableTypeCommonAttributeXml(Option<DAE.Exp> initialValue, Boolean isFixed)
 "Generates XML code for ScalarVariable Type file ."
::=
match initialValue
  case SOME(exp) then 'start="<%initValXml(exp)%>" fixed="<%isFixed%>"'
end ScalarVariableTypeCommonAttributeXml;

template ScalarVariableTypeMinAttribute(Option<DAE.Exp> minValue)
 "generates code for min attribute"
::=
match minValue
  case SOME(exp) then 'min="<%initValXml(exp)%>"'
end ScalarVariableTypeMinAttribute;

template ScalarVariableTypeMaxAttribute(Option<DAE.Exp> maxValue)
 "generates code for max attribute"
::=
match maxValue
  case SOME(exp) then 'max="<%initValXml(exp)%>"'
end ScalarVariableTypeMaxAttribute;

template initValXml(Exp initialValue)
  "Returns initial value of ScalarVariable."
::=
  match initialValue
  case ICONST(__) then integer
  case RCONST(__) then real
  case SCONST(__) then '&quot;<%Util.escapeModelicaStringToXmlString(string)%>&quot;'
  case BCONST(__) then (if bool then "1" else "0")
  case ENUM_LITERAL(__) then '<%index%>'
  case CREF(__) then '<%crefStrXml(componentRef)%>'
  else "*ERROR* initial value of unknown type"
end initValXml;

template ScalarVariableTypeRealAttributeXml(String unit, String displayUnit)
 "Generates XML code for ScalarVariable Type Real file ."
::=
  let unit_ = if unit then 'unit="<%unit%>"'
  let displayUnit_ = if displayUnit then 'displayUnit="<%displayUnit%>"'
  <<
  <%unit_%> <%displayUnit_%>
  >>
end ScalarVariableTypeRealAttributeXml;

template contextCrefXml(ComponentRef cr, Context context)
  "Generates XML code for a component reference depending on which context we're in."
::=
  match context
  case FUNCTION_CONTEXT(__) then  System.unquoteIdentifier(crefStrXml(cr))
  else crefXml(cr)
end contextCrefXml;

template contextIteratorNameXml(Ident name, Context context)
  "Generates XML code for an iterator variable."
::=
  match context
  case FUNCTION_CONTEXT(__) then name
  else  name
end contextIteratorNameXml;

template crefXml(ComponentRef cr)
 "Generates Xml equivalent name for component reference."
::=
  match cr
  case CREF_IDENT(ident = "xloc") then crefStrXml(cr)
  case CREF_IDENT(ident = "time") then '<exp:Time>time</exp:Time>'
  case WILD(__) then ''
  else  crefToXmlStr(cr)
end crefXml;

template qualifiedNamePartXml(ComponentRef cr)
 "Generates XML code of the Qualified name of a variable . "
::=
  match cr
  case CREF_IDENT(__) then
    let arrayTest = arraysubscriptsStrXml(subscriptLst)
    if arrayTest then
    <<
    <exp:QualifiedNamePart name="<%ident%>">
      <%arraysubscriptsStrXml(subscriptLst)%>
    </exp:QualifiedNamePart>
    >>
    else
    <<
    <exp:QualifiedNamePart name="<%ident%>"/>
    >>
  case CREF_QUAL(ident = "$DER") then '<%qualifiedNamePartXml(componentRef)%>'
  case CREF_QUAL(__) then
    let arrayTest = arraysubscriptsStrXml(subscriptLst)
    if arrayTest then
    <<
    <exp:QualifiedNamePart name="<%ident%>">
      <%arraysubscriptsStrXml(subscriptLst)%>
    <%qualifiedNamePartXml(componentRef)%>
    </exp:QualifiedNamePart>
    >>
    else
    <<
    <exp:QualifiedNamePart name="<%ident%>"/>
    <%qualifiedNamePartXml(componentRef)%>
    >>
  else "CREF_NOT_IDENT_OR_QUAL"

end qualifiedNamePartXml;

template arraysubscriptsStrXml(list<Subscript> subscripts)
 "Generares XML code for subscript part of the name."
::=
  if subscripts then
  <<
  <exp:ArraySubscripts>
    <%subscripts |> s => arraysubscriptStrXml(s) ;separator="\n"%>
  </exp:ArraySubscripts>
  >>
  else
  <<>>
end arraysubscriptsStrXml;

template arraysubscriptStrXml(Subscript subscript)
 "Generates a single subscript XML code.
  Only works for constant integer indicies."

::=
  match subscript
  case INDEX(exp=ICONST(integer=i)) then
    <<
    <exp:IndexExpression>
      <exp:IntegerLiteral><%i%></exp:IntegerLiteral>
    </exp:IndexExpression>
    >>
  case SLICE(exp=ICONST(integer=i)) then
    <<
    <exp:IndexExpression>
      <exp:IntegerLiteral><%i%></exp:IntegerLiteral>
    </exp:IndexExpression>
    >>
  case WHOLEDIM(__) then "WHOLEDIM"
  else "UNKNOWN_SUBSCRIPT"
end arraysubscriptStrXml;

template crefToXmlStr(ComponentRef cr)
 "Helper function to crefXml"
::=
  match cr
  case CREF_IDENT(__) then
    <<
    <exp:Identifier>
      <%qualifiedNamePartXml(cr)%>
    </exp:Identifier>
    >>
  case CREF_QUAL(ident = "$DER") then
    <<
    <exp:Der>
      <%crefToXmlStr(componentRef)%>
    </exp:Der>
    >>
  case CREF_QUAL(__) then
    <<
    <exp:Identifier>
      <%qualifiedNamePartXml(cr)%>
    </exp:Identifier>
    >>
  case OPTIMICA_ATTR_INST_CREF(__) then
    <<
    <exp:TimedVariable timePointIndex = "0">
      <%crefToXmlStr(componentRef)%>
      <exp:Instant><%instant%></exp:Instant>
    </exp:TimedVariable>
    >>
  case WILD(__) then ''
  else "CREF_NOT_IDENT_OR_QUAL"
end crefToXmlStr;

template crefStrXml(ComponentRef cr)
 "Generates the name of a variable for variable name array."
::=
  match cr
  case CREF_IDENT(__) then '<%ident%><%subscriptsStrXml(subscriptLst)%>'
  case CREF_QUAL(ident = "$DER") then 'der(<%crefStrXml(componentRef)%>)'
  case CREF_QUAL(ident = "$PRE") then 'pre(<%crefStrXml(componentRef)%>)'
  case CREF_QUAL(__) then '<%ident%><%subscriptsStrXml(subscriptLst)%>.<%crefStrXml(componentRef)%>'
  else "CREF_NOT_IDENT_OR_QUAL"
end crefStrXml;

template contextArrayCrefXml(ComponentRef cr, Context context)
 "Generates XML code for an array component reference depending on the context."
::=
  match context
  case FUNCTION_CONTEXT(__) then  arrayCrefStrXml(cr)
  else arrayCrefXmlStr(cr)
end contextArrayCrefXml;

template arrayCrefXmlStr(ComponentRef cr)
::= '<%arrayCrefXmlStr2(cr)%>'
end arrayCrefXmlStr;

template arrayCrefXmlStr2(ComponentRef cr)
::=
  match cr
  case CREF_IDENT(__) then
    <<
    <exp:QualifiedName>
      <exp:QualifiedNamePart name="<%unquoteIdentifier(ident)%>">
    >>
  case CREF_QUAL(__) then '<%unquoteIdentifier(ident)%><%subscriptsStrXml(subscriptLst)%>$P<%arrayCrefXmlStr2(componentRef)%>testing array'
  else "CREF_NOT_IDENT_OR_QUAL"
end arrayCrefXmlStr2;

template arrayCrefStrXml(ComponentRef cr)
::=
  match cr
  case CREF_IDENT(__) then
    <<
    <exp:Identifier>
      <exp:QualifiedNamepart name ="<%ident%>"/>
    </exp:Identifier>
    >>
  case CREF_QUAL(__) then '<%ident%>.<%arrayCrefStrXml(componentRef)%>'
  else "CREF_NOT_IDENT_OR_QUAL"
end arrayCrefStrXml;

template subscriptsStrXml(list<Subscript> subscripts)
 "Generares subscript part of the name."
::=
  if subscripts then
    '[<%subscripts |> s => subscriptStrXml(s) ;separator=","%>]'
end subscriptsStrXml;

template subscriptStrXml(Subscript subscript)
 "Generates a single subscript.
  Only works for constant integer indicies."

::=
  match subscript
  case INDEX(exp=ICONST(integer=i)) then i
  case SLICE(exp=ICONST(integer=i)) then i
  case WHOLEDIM(__) then "WHOLEDIM"
  else "UNKNOWN_SUBSCRIPT"
end subscriptStrXml;

template expCrefXml(DAE.Exp ecr)
::=
  match ecr
    case CREF(__) then crefXml(componentRef)
    case CALL(path = IDENT(name = "der"), expLst = {arg as CREF(__)}) then
      <<
      <exp:Der>
        <%crefXml(arg.componentRef)%>
      </exp:Der>
      >>
  else "ERROR_NOT_A_CREF"
end expCrefXml;

template crefFunctionNameXml(ComponentRef cr)
::=
  match cr
  case CREF_IDENT(__) then
    System.stringReplace(unquoteIdentifier(ident), "_", "__")
  case CREF_QUAL(__) then
    '<%System.stringReplace(unquoteIdentifier(ident), "_", "__")%>_<%crefFunctionNameXml(componentRef)%>'
end crefFunctionNameXml;

template dotPathXml(Path path)
 "Generates paths with components separated by dots."
::=
  match path
  case QUALIFIED(__)      then '<%name%>.<%dotPathXml(path)%>'
  case IDENT(__)          then name
  case FULLYQUALIFIED(__) then dotPathXml(path)
end dotPathXml;

template replaceDotAndUnderscoreXml(String str)
 "Replace _ with __ and dot in identifiers with _"
::=
  match str
  case name then
    let str_dots = System.stringReplace(name,".", "_")
    let str_underscores = System.stringReplace(str_dots, "_", "__")
    System.unquoteIdentifier(str_underscores)
end replaceDotAndUnderscoreXml;

template underscorePathXml(Path path)
 "Generate XML code for paths"
::=
  match path
  case QUALIFIED(__) then
    <<
    <exp:QualifiedNamePart name="<%name%>"/>
    <%underscorePathXml(path)%>
    >>
  case IDENT(__) then
    <<
    <exp:QualifiedNamePart name="<%name%>"/>
    >>
  case FULLYQUALIFIED(__) then
    <<
    <%underscorePathXml(path)%>
    >>
end underscorePathXml;


/*****************************************************************************
 *         SECTION: GENERATE All Function IN SIMULATION FILE
 *****************************************************************************/

template bindingEquationsXml(ModelInfo modelInfo)
 "Function for Binding Equations"
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(numStateVars=numStateVars),vars=SIMVARS(__)) then
  <<
  <equ:BindingEquations>
    <%vars.paramVars |> var => bindingEquationXml(var) ;separator="\n"%>
    <%vars.intParamVars |> var => bindingEquationXml(var) ;separator="\n"%>
    <%vars.boolParamVars |> var => bindingEquationXml(var) ;separator="\n"%>
    <%vars.stringParamVars |> var => bindingEquationXml(var) ;separator="\n"%>
  </equ:BindingEquations>
  >>
end bindingEquationsXml;

template bindingEquationXml(SimVar var)
  "Generate XML code for binding Equations"
::=
  match var
    case SIMVAR(__) then
    let varName = '<%qualifiedNamePartXml(name)%>'
    match initialValue
      case SOME(exp) then
      let &varDecls = buffer "" /*BUFD*/
      let &preExp = buffer "" /*BUFD*/
        <<
        <equ:BindingEquation>
          <equ:Parameter>
            <%varName%>
          </equ:Parameter>
          <equ:BindingExp>
            <%daeExpXml(exp, contextOther, &preExp, &varDecls)%>
          </equ:BindingExp>
        </equ:BindingEquation><%\n%>
        >>
end bindingEquationXml;

template equationsXml(list<SimEqSystem> allEquationsPlusWhen)
  "Function for all equations"
::=
  let &varDecls = buffer "" /*BUFD*/
  let jens = System.tmpTickReset(0)
  let &tmp = buffer ""
  let eqs = (allEquationsPlusWhen |> eq =>
      equation_Xml(eq, contextSimulationDiscrete, &varDecls /*BUFD*/, &tmp)
    ;separator="\n")
  <<
  <equ:DynamicEquations>
    <%&tmp%>
    <%eqs%>
  </equ:DynamicEquations>
  >>
end equationsXml;

template algorithmicEquationsXml( list<SimEqSystem> allEquations)
  "Generates XML for an equation that is an algorithm."
::=
  let &varDecls = buffer "" /*BUFD*/
  let algs = (allEquations |> eq =>
      equationAlgorithmXml(eq, contextSimulationDiscrete, &varDecls /*BUFD*/)
    ;separator="\n")
    <<
    <fun:Algorithm>
      <%algs%>
    </fun:Algorithm>
    >>
end algorithmicEquationsXml;

template equationAlgorithmXml(SimEqSystem eq, Context context, Text &varDecls /*BUFP*/)
 "Generates XML for an equation that is an algorithm."
::=
match eq
case SES_ALGORITHM(__) then
let alg =(statements |> stmt =>
    algStatementXml(stmt, contextFunction, &varDecls /*BUFD*/)
  ;separator="\n")
  <<
  <%alg%>
  >>
end equationAlgorithmXml;


template initialEquationsXml(ModelInfo modelInfo, list<SimEqSystem> initialEqs)
 "Function for Inititial Equations."
::=
match modelInfo
case MODELINFO(varInfo=VARINFO(numStateVars=numStateVars),vars=SIMVARS(__)) then
  let &varDecls = buffer "" /*BUFD*/
  let jens = System.tmpTickReset(0)
  let &tmp = buffer ""
  let eqs = (initialEqs |> eq =>
      equation_Xml(eq, contextSimulationDiscrete, &varDecls /*BUFD*/, &tmp)
    ;separator="\n")
  <<
  <equ:InitialEquations>
    <%vars.stateVars |> var => initialEquationXml(var) ;separator="\n"%>
    <%vars.derivativeVars |> var => initialEquationXml(var) ;separator="\n"%>
    <%vars.algVars |> var => initialEquationXml(var) ;separator="\n"%>
    <%vars.discreteAlgVars |> var => initialEquationXml(var) ;separator="\n"%>
    <%vars.intAlgVars |> var => initialEquationXml(var) ;separator="\n"%>
    <%vars.boolAlgVars |> var => initialEquationXml(var) ;separator="\n"%>
    <%vars.stringAlgVars |> var => initialEquationXml(var) ;separator="\n"%>
    <%&tmp%>
    <%eqs%>
  </equ:InitialEquations>
  >>
end initialEquationsXml;

template initialEquationXml(SimVar var)
  "Generates XML code for Inititial Equations."
::=
  match var
    case SIMVAR(__) then
    let identName = '<%crefXml(name)%>'
    match initialValue
      case SOME(exp) then
      let &varDecls = buffer "" /*BUFD*/
      let &preExp = buffer "" /*BUFD*/
         <<
         <equ:Equation>
           <exp:Sub>
             <%identName%>
             <%daeExpXml(exp, contextOther, &preExp, &varDecls)%>
           </exp:Sub>
         </equ:Equation><%\n%>
         >>
end initialEquationXml;

 /*****************************************************************************
 *       SECTION: GENERATE All EQUATIONS IN SIMULATION FILE
 *****************************************************************************/

template equation_Xml(SimEqSystem eq, Context context, Text &varDecls /*BUFP*/, Text &eqs)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
  case e as SES_MIXED(__) then " MIXED EQUATION NOT IMPLEMENTED "
  case e as SES_ALGORITHM(statements={}) then " "
  case e as SES_ALGORITHM(__) then " "
  case e as SES_WHEN(__)
    then equationWhenXml(e, context, &varDecls /*BUFD*/)
  else
  (
  let ix = System.tmpTickIndex(10)
  let &tmp = buffer ""
  let &varD = buffer ""
  let x = match eq
  case e as SES_SIMPLE_ASSIGN(__)
    then  equationSimpleAssignXml(e, context, &varD /*BUFD*/)
  case e as SES_ARRAY_CALL_ASSIGN(__)
    then  equationArrayCallAssignXml(e, context, &varD /*BUFD*/)
  case e as SES_IFEQUATION(__)
    then 'IfEquation Assign Not implemente yet'
  case e as SES_LINEAR(__)
    then  equationLinearXml(e, context, &varD /*BUFD*/)
  case e as SES_NONLINEAR(__)
    then  equationNonlinearXml(e, context, &varD /*BUFD*/)
  case e as SES_WHEN(__)
    then " "
  else
    "NOT IMPLEMENTED EQUATION"
  let &eqs +=
  <<
  <equ:Equation>
    <exp:Sub>
      <%x%>
    </exp:Sub>
  </equ:Equation>  <%\n%>
  >>
  <<
  >>
  )
end equation_Xml;

template old_equation_Xml(SimEqSystem eq, Context context, Text &varDecls)
 "Generates an equation.
  This template should not be used for a SES_RESIDUAL.
  Residual equations are handled differently."
::=
  match eq
  case e as SES_MIXED(__)
  case e as SES_SIMPLE_ASSIGN(__)
    then equationSimpleAssignXml(e, context, &varDecls)
  case e as SES_ARRAY_CALL_ASSIGN(__)
    then equationArrayCallAssignXml(e, context, &varDecls)
  case e as SES_ALGORITHM(__) then " "
  case e as SES_LINEAR(__) then " equations are not implemented yet"
  case e as SES_NONLINEAR(__) then "equations are not implemented yet "
  case e as SES_WHEN(__)
    then equationWhenXml(e, context, &varDecls)
  else
    "NOT IMPLEMENTED EQUATION"
end old_equation_Xml;

template equationSimpleAssignXml(SimEqSystem eq, Context context,
                              Text &varDecls /*BUFP*/)
 "Generates an equation that is just a simple assignment."
::=
match eq
case SES_SIMPLE_ASSIGN(__) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExpXml(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  let result = if preExp then preExp else expPart
  <<
  <%crefXml(cref)%>
  <%result%>
  >>
end equationSimpleAssignXml;

template equationArrayCallAssignXml(SimEqSystem eq, Context context,
                                 Text &varDecls /*BUFP*/)
 "Generates equation on form 'cref_array = call(...)'."
::=
<<
<%match eq

case eqn as SES_ARRAY_CALL_ASSIGN(lhs=lhs as CREF(__)) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExpXml(exp, context, &preExp /*BUF  let &preExp = buffer "" /*BUFD*/
  //let &helpInits = buffer "" /*BUFD*/
  //let helpIf = (conditions |> e =>
     // let helpInit = daeExpXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      //let &helpInits += ' <%helpInit%>'
     // '';separator=" || ")C*/, &varDecls /*BUFD*/)
  match expTypeFromExpShortXml(eqn.exp)
  case "boolean" then
    <<
    <%expPart%>
    <%crefXml(lhs.componentRef)%>
    >>
  case "integer" then
    <<
    <%expPart%>
    <%crefXml(lhs.componentRef)%>
    >>
  case "real" then
    <<
    <%crefXml(lhs.componentRef)%>
    <%expPart%>
    >>
  else error(sourceInfo(), 'No runtime support for this sort of array call: <%ExpressionDumpTpl.dumpExp(eqn.exp,"\"")%>')
%>
>>
end equationArrayCallAssignXml;


template equationLinearXml(SimEqSystem eq, Context context, Text &varDecls /*BUFP*/)
 "Generates a when equation XML."
::=
match eq
case SES_LINEAR(lSystem=ls as LINEARSYSTEM(__)) then
  <<
  <%ls.simJac |> (row, col, eq as SES_RESIDUAL(__)) =>
     let &preExp = buffer "" /*BUFD*/
     let expPart = daeExpXml(eq.exp, context, &preExp /*BUFC*/,  &varDecls /*BUFD*/)
 '<%preExp%>
  <%expPart%>' ;separator="\n"%>
  <%ls.beqs |> exp hasindex i0 =>
     let &preExp = buffer "" /*BUFD*/
     let expPart = daeExpXml(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  '<%preExp%>
   <%expPart%>' ;separator="\n"%>
  >>
end equationLinearXml;

template equationNonlinearXml(SimEqSystem eq, Context context, Text &varDecls /*BUFP*/)
 "Generates a when equation XML."
::=
match eq
  case SES_NONLINEAR(nlSystem=nls as NONLINEARSYSTEM(__)) then
   let &varDecls = buffer "" /*BUFD*/
   let &tmp = buffer ""
   let prebody = (nls.eqs |> eq2 =>
       functionExtraResidualsPreBody(eq2, &varDecls /*BUFD*/, &tmp)
     ;separator="\n")
   let body = (nls.eqs |> eq2 as SES_RESIDUAL(__) hasindex i0 =>
       let &preExp = buffer "" /*BUFD*/
       let expPart = daeExpXml(eq2.exp, contextSimulationDiscrete,
                      &preExp /*BUFC*/, &varDecls /*BUFD*/)
 '<%preExp%>
  <%expPart%>;';separator="\n")
  <<
  <%&tmp%>
  <%prebody%>
  <%body%>
  >>
end equationNonlinearXml;

template functionExtraResidualsPreBody(SimEqSystem eq, Text &varDecls /*BUFP*/, Text &eqs)
 "Generates an equation."
::=
  match eq
  case e as SES_RESIDUAL(__) then ""
  else equation_Xml(eq, contextSimulationDiscrete, &varDecls /*BUFD*/, &eqs)
  end match
end functionExtraResidualsPreBody;


template equationWhenXml(SimEqSystem eq, Context context, Text &varDecls /*BUFP*/)
 "Generates a when equation XML."
::=
match eq
  case SES_WHEN(whenStmtLst = whenStmtLst, conditions=conditions,elseWhen = NONE()) then
    let &preExp = buffer "" /*BUFD*/
    let &helpInits = buffer "" /*BUFD*/
    let helpIf = (conditions |> e =>
        let helpInit = crefToXmlStr(e)
        let &helpInits += '<%helpInit%><%\n%>'
        '';separator="\n")
    let body = whenOps(whenStmtLst, context, &varDecls /*BUFD*/)
    let cond = if preExp then preExp else helpInits
      <<
      <equ:When>
        <equ:Condition>
          <%cond%>
        </equ:Condition>
        <equ:Equation>
          <%body%>
        </equ:Equation>
      </equ:When>
      >>
  case SES_WHEN(whenStmtLst = whenStmtLst, conditions=conditions,elseWhen = SOME(elseWhenEq)) then
    let &preExp = buffer "" /*BUFD*/
    let &helpInits = buffer "" /*BUFD*/
    let helpIf = (conditions |> e =>
        let helpInit = crefToXmlStr(e)
        let &helpInits += '<%helpInit%><%\n%>'
        '';separator=" || ")
    let body = whenOps(whenStmtLst, context, &varDecls /*BUFD*/)
    let elseWhen = equationElseWhenXml(elseWhenEq,context,preExp,helpInits, varDecls)
     let cond = if preExp then preExp else helpInits
      <<
      <equ:When>
        <equ:Condition>
          <%cond%>
        </equ:Condition>
        <equ:Equation>
          <%body%>
        </equ:Equation>
      </equ:When>
      <%elseWhen%>
      >>
end equationWhenXml;

template equationElseWhenXml(SimEqSystem eq, Context context, Text &preExp /*BUFD*/, Text &helpInits /*BUFD*/, Text &varDecls /*BUFP*/)
 "Generates a else when equation."
::=
match eq
case SES_WHEN(whenStmtLst = whenStmtLst, conditions=conditions,elseWhen = NONE()) then
  let helpIf = (conditions |> e =>
      let helpInit = crefToXmlStr(e)
      let &helpInits += '<%helpInit%><%\n%>'
      '';separator=" || ")
   let body = whenOps(whenStmtLst, context, &varDecls /*BUFD*/)
   let cond = if preExp then preExp else helpInits
    <<
    <equ:ElseWhen>
      <equ:Condition>
        <%cond%>
      </equ:Condition>
      <equ:Equation>
        <%body%>
      </equ:Equation>
    </equ:ElseWhen>
    >>
case SES_WHEN(whenStmtLst = whenStmtLst, conditions=conditions,elseWhen = SOME(elseWhenEq)) then
  let helpIf = (conditions |> e =>
      let helpInit = crefToXmlStr(e)
      let &helpInits += '<%helpInit%><%\n%>'
      '';separator=" || ")
  let body = whenOps(whenStmtLst, context, &varDecls /*BUFD*/)
  let elseWhen = equationElseWhenXml(elseWhenEq,context,preExp,helpInits, varDecls)
   let cond = if preExp then preExp else helpInits
    <<
    <equ:ElseWhen>
      <equ:Condition>
        <%cond%>
      </equ:Condition>
      <equ:Equation>
        <%body%>
      </equ:Equation>
    </equ:ElseWhen>
    <%elseWhen%>
    >>
end equationElseWhenXml;

template whenOps(list<WhenOperator> whenOps, Context context, Text &varDecls /*BUFP*/)
 "Generates re-init statement for when equation."
::=
  let body = (whenOps |> whenOp =>
    match whenOp
    case ASSIGN(left = lhls as DAE.CREF(componentRef = cr)) then
      let &preExp = buffer "" /*BUFD*/
      let exp = daeExpXml(right, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      <<
        <exp:Sub>
          <%crefXml(cr)%>
          <%exp%>
        </exp:Sub>
      >>
    case REINIT(__) then
      let &preExp = buffer "" /*BUFD*/
      let val = daeExpXml(value, contextSimulationDiscrete,
                   &preExp /*BUFC*/, &varDecls /*BUFD*/)
       <<
       <exp:Reinit>
         <%crefXml(stateVar)%>
         <%val%>
       </exp:Reinit>
       >>
    case TERMINATE(__) then
      let &preExp = buffer "" /*BUFD*/
      let msgVar = daeExpXml(message, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        <<
         <%preExp%>
         <%msgVar%>
        >>
  case ASSERT(source=SOURCE(info=info)) then
    assertCommonXml(condition, message, contextSimulationDiscrete, &varDecls, info)
  ;separator="\n")
    <<
    <%body%>
    >>
end whenOps;


/*****************************************************************************
 *         SECTION: GENERATE ALL RECORDS ( RECORD LIST) IN SIMULATION FILE
 *****************************************************************************/

template recordsXml(list<RecordDeclaration> recordDecls)
  "Generates XML code for all records."
::=
   <<
   <fun:RecordsList>
     <%recordDecls |> rd => recordDeclarationXml(rd) ;separator="\n"%>
   </fun:RecordsList>
   >>
end recordsXml;

template recordDeclarationXml(RecordDeclaration recDecl)
 "Generates XML structs for a record declaration."
::=
  match recDecl
  case RECORD_DECL_FULL(__) then
    <<
    <fun:Record>
      <fun:Name>
        <exp:QualifiedNamePart  name ='<%name%>'/>
      </fun:Name>
      <%variables |> var  => recordBodyXml(var) ;separator="\n"%>
    </fun:Record>
    >>
  case RECORD_DECL_DEF(__) then
    <<
      Record Declaration definition is not yet implemented
    >>
end recordDeclarationXml;

template recordBodyXml(Variable var)
::=
  match var
  case VARIABLE(ty=T_COMPLEX(complexClassType=RECORD(__))) then
    <<
    <fun:Field  type="Record">
      <fun:Name>
        <exp:QualifiedNamePart name="<%contextCrefXml(name,contextFunction)%>"/>
      </fun:Name>
      <fun:Record>
        <%varTypeXml(var)%>
      </fun:Record>
    </fun:Field>
    >>
  case VARIABLE(__) then
    <<
    <fun:Field  type="<%varTypeXml(var)%>">
      <fun:Name>
        <exp:QualifiedNamePart name="<%crefStrXml(var.name)%>"/>
      </fun:Name>
    </fun:Field>
    >>
  case FUNCTION_PTR(__) then 'modelica_fnptr <%name%>'
end  recordBodyXml;

/*********************************************************************************************
 * SECTION: GENERATE All USER DEFINED FUNCTIONS INCLUDING EXTERNAL FUNCTIONS IN SIMULATION FILE
 **********************************************************************************************/

template functionsXml(list<Function> functions)
 "Generates the body for a set of functions."
::=
  <<
  <fun:FunctionsList>
    <%functions |> fn => functionXml(fn) ;separator="\n"%>
  </fun:FunctionsList>
  >>
end functionsXml;

template functionXml(Function fn)
 "Generates the body for a function."
::=
  match fn
  case fn as FUNCTION(__)           then regularFunctionXml(fn)
  case fn as EXTERNAL_FUNCTION(__)  then externalFunctionXml(fn)
  case fn as RECORD_CONSTRUCTOR(__) then ''
end functionXml;

template regularFunctionXml(Function fn)
 "Generates XML code   for a Modelica function."
::=
match fn
case FUNCTION(__) then
  let()= System.tmpTickReset(1)
  let fname = underscorePathXml(name)
  let &varDecls = buffer "" /*BUFD*/
  let &varInits = buffer "" /*BUFD*/
  let bodyPart = funStatementXml(body, &varDecls)
  <<
  <fun:Function>
    <fun:Name>
      <%fname%>
    </fun:Name>
    <%outVars |> var => funOutputVariableXml(var) ;separator="\n"%>
    <%functionArguments |> var => funArgDefinitionXml(var) ;separator="\n"%>
    <%/*variableDeclarations |> var => funVarDeclarationsXml(var) ;separator="\n"*/%>
    <fun:Algorithm>
      <%bodyPart%>
    </fun:Algorithm>
  </fun:Function> <%\n%>
  >>
end regularFunctionXml;

template externalFunctionXml(Function fn)
 "Generates the body for an external function (just a wrapper)."
::=
match fn
case efn as EXTERNAL_FUNCTION(__) then
  let()= System.tmpTickReset(1)
  let &preExp = buffer "" /*BUFD*/
  let &varDecls = buffer "" /*BUFD*/
  let fname = underscorePathXml(name)
  let callPart = extFunCallXml(fn, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  <fun:Function>
    <fun:Name>
      <%fname%>
    </fun:Name>
    <%outVars |> var => funOutputVariableXml(var) ;separator="\n"%>
    <%funArgs |> var => funArgDefinitionXml(var) ;separator="\n"%>
    <fun:Algorithm>
      <%callPart%>
    </fun:Algorithm>
  </fun:Function> <%\n%>
  >>
end externalFunctionXml;

template funArgNameXml(Variable var)
::=
  match var
  case VARIABLE(__) then contextCrefXml(name,contextFunction)
  case FUNCTION_PTR(__) then name
end funArgNameXml;

template funOutputVariableXml(Variable var)
::=
  match var
  case VARIABLE(ty=T_COMPLEX(complexClassType=RECORD(__))) then
    <<
    <fun:OutputVariable type="Record">
      <fun:Name>
        <exp:QualifiedNamePart name="<%contextCrefXml(name,contextFunction)%>"/>
      </fun:Name>
      <fun:Record>
        <%varTypeXml(var)%>
      </fun:Record>
    </fun:OutputVariable>
    >>
  case VARIABLE(__) then
    <<
    <fun:OutputVariable type="<%varTypeXml(var)%>">
      <fun:Name>
        <exp:QualifiedNamePart name="<%contextCrefXml(name,contextFunction)%>"/>
      </fun:Name>
    </fun:OutputVariable>
    >>
  case FUNCTION_PTR(__) then '<%name%>'
end funOutputVariableXml;

template funArgDefinitionXml(Variable var)
::=
  match var
  case VARIABLE(ty=T_COMPLEX(complexClassType=RECORD(__))) then
    <<
    <fun:InputVariable type="Record">
      <fun:Name>
        <exp:QualifiedNamePart name="<%contextCrefXml(name,contextFunction)%>"/>
      </fun:Name>
      <fun:Record>
        <%varTypeXml(var)%>
      </fun:Record>
    </fun:InputVariable>
    >>
  case VARIABLE(__) then
    <<
    <fun:InputVariable type="<%varTypeXml(var)%>">
      <fun:Name>
        <exp:QualifiedNamePart name="<%contextCrefXml(name,contextFunction)%>"/>
      </fun:Name>
    <%/*underscorePathXml(ClassInf.getStateName(complexClassType))*/%>
    </fun:InputVariable>
    >>
  case FUNCTION_PTR(__) then 'modelica_fnptr <%name%>'
end funArgDefinitionXml;

template funVarDeclarationsXml(Variable var)
::=
  match var
  case VARIABLE(__) then
  <<
  <fun:protectedVariable type="<%varTypeXml(var)%>">
    <fun:Name>
      <exp:QualifiedNamePart name="<%contextCrefXml(name,contextFunction)%>"/>
    </fun:Name>
    <%/*underscorePathXml(ClassInf.getStateName(complexClassType))*/%>
  </fun:ProtectedVariable>
  >>
  case FUNCTION_PTR(__) then 'modelica_fnptr <%name%>'
end funVarDeclarationsXml;

template extFunctionNameXml(String name, String language)
::=
  match language
  case "C" then
    <<
    <exp:QualifiedName name="<%name%>"/>
    >>
  case "FORTRAN 77" then
    <<
    <exp:QualifiedName name="<%name%>"/>
    >>
  else error(sourceInfo(), 'Unsupport external language: <%language%>')
end extFunctionNameXml;

template extTypeXml(Type type, Boolean isInput, Boolean isArray)
 "Generates type for external function argument or return value."
::=
  let s = match type
  case T_INTEGER(__)     then "int"
  case T_REAL(__)        then "double"
  case T_STRING(__)      then "const char*"
  case T_BOOL(__)        then "int"
  case T_ENUMERATION(__) then "int"
  case T_ARRAY(__)       then extTypeXml(ty,isInput,true)
  case T_COMPLEX(complexClassType=EXTERNAL_OBJ(__))
                      then "void *"
  case T_COMPLEX(complexClassType=RECORD(path=rname))
                      then 'struct <%underscorePathXml(rname)%>'
  case T_METATYPE(__) case T_METABOXED(__)    then "modelica_metatype"
  else error(sourceInfo(), 'Unknown external C type <%unparseType(type)%>')
  match type case T_ARRAY(__) then s else if isInput then (if isArray then '<%match s case "const char*" then "" else "const "%><%s%>*' else s) else '<%s%>*'
end extTypeXml;

template extTypeF77Xml(Type type, Boolean isReference)
  "Generates type for external function argument or return value for F77."
::=
  let s = match type
  case T_INTEGER(__)     then "int"
  case T_REAL(__)        then "double"
  case T_STRING(__)      then "char"
  case T_BOOL(__)        then "int"
  case T_ENUMERATION(__) then "int"
  case T_ARRAY(__)       then extTypeF77Xml(ty, true)
  case T_COMPLEX(complexClassType=EXTERNAL_OBJ(__))
                         then "void*"
  case T_COMPLEX(complexClassType=RECORD(path=rname))
                         then 'struct <%underscorePathXml(rname)%>'
  case T_METATYPE(__) case T_METABOXED(__) then "void*"
  else error(sourceInfo(), 'Unknown external F77 type <%unparseType(type)%>')
  match type case T_ARRAY(__) then s else if isReference then '<%s%>*' else s
end extTypeF77Xml;

template functionNameXml(Function fn, Boolean dotPath)
::=
  match fn
  case FUNCTION(__)
  case EXTERNAL_FUNCTION(__)
  case RECORD_CONSTRUCTOR(__) then if dotPath then dotPathXml(name) else underscorePathXml(name)
end functionNameXml;

template extVarNameXml(ComponentRef cr)
::=
  <<
  <%crefXml(cr)%>
  >>
end extVarNameXml;

template extFunCallXml(Function fun, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates the call to an external function."
::=
match fun
case EXTERNAL_FUNCTION(__) then
  match language
  case "C" then extFunCallCXml(fun, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case "FORTRAN 77" then extFunCallF77Xml(fun, &preExp /*BUFC*/, &varDecls /*BUFD*/)
end extFunCallXml;

template extFunCallCXml(Function fun, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates the call to an external C function."
::=
match fun
case EXTERNAL_FUNCTION(__) then
  let args = (extArgs |> arg =>
      extArgCXml(arg, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    ;separator="\n ")
  let returnAssign = match extReturn case SIMEXTARG(cref=c) then
      '<%extVarNameXml(c)%> '
    else
      ""
  <<
  <fun:Assign>
    <%returnAssign%>
    <fun:Expression>
      <exp:FunctionCall>
        <exp:Name>
          <exp:QualifiedNamePart name="<%extName%>" />
        </exp:Name>
        <exp:Arguments>
          <%args%>
        </exp:Arguments>
      </exp:FunctionCall>
    </fun:Expression>
  </fun:Assign>
  >>
end extFunCallCXml;

template extFunCallF77Xml(Function fun, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates the call to an external Fortran 77 function."
::=
match fun
case EXTERNAL_FUNCTION(__) then
  let args = (extArgs |> arg => extArgF77Xml(arg, &preExp, &varDecls) ;separator=", ")
  let returnAssign = match extReturn case SIMEXTARG(cref=c) then
      '<%extVarNameXml(c)%>'
    else
      ""
  <<
  <fun:Assign>
    <%returnAssign%>
    <fun:Expression>
      <exp:FunctionCall>
        <exp:Name>
          <exp:QualifiedNamePart name="<%extName%>" />
        </exp:Name>
        <exp:Arguments>
          <%args%>
        </exp:Arguments>
      </exp:FunctionCall>
    </fun:Expression>
  </fun:Assign>
  >>
end extFunCallF77Xml;

template extArgCXml(SimExtArg extArg, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Helper to extFunCallXml."
::=
  match extArg
  case SIMEXTARG(cref=c, outputIndex=oi, isArray=true, type_=t) then
    <<
    <%extVarNameXml(c)%>
    >>
  case SIMEXTARG(cref=c, isInput=ii, outputIndex=0, type_=t) then
    <<
    <%extVarNameXml(c)%>
    >>
  case SIMEXTARG(cref=c, isInput=ii, outputIndex=oi, type_=t) then
    <<
    <%extVarNameXml(c)%>
    >>
  case SIMEXTARGEXP(__) then
    daeExternalXmlExp(exp, contextFunction, &preExp /*BUFC*/, &varDecls /*BUFD*/) +'test daeexternal xml'
  case SIMEXTARGSIZE(cref=c) then
    let name = extVarNameXml(c)
    let dim = daeExpXml(exp, contextFunction, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      <<
      <exp:Size>
        <%name%>
        <%dim%>
      </exp:size>
      >>
end extArgCXml;

template extArgF77Xml(SimExtArg extArg, Text &preExp, Text &varDecls)
::=
  match extArg
  case SIMEXTARG(cref=c, isArray=true, type_=t) then
    <<
    <%extVarNameXml(c)%>
    >>
  case SIMEXTARG(cref=c, outputIndex=oi, type_=T_INTEGER(__)) then
    <<
    <%extVarNameXml(c)%>
    >>
  case SIMEXTARG(cref=c, outputIndex=oi, type_ = T_STRING(__)) then
    <<
    <%extVarNameXml(c)%>
    >>
  case SIMEXTARG(cref=c, outputIndex=oi, type_=t) then
    <<
    <%extVarNameXml(c)%>
    >>
  case SIMEXTARGEXP(exp=exp, type_ = T_STRING(__)) then
    let texp = daeExpXml(exp, contextFunction, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    <%texp%>
    >>
  case SIMEXTARGSIZE(cref=c) then
    let dim = daeExpXml(exp, contextFunction, &preExp, &varDecls)
    let name = extVarNameXml(c)
      <<
      <exp:Size>
        <%name%>
        <%dim%>
      </exp:size>
      >>
end extArgF77Xml;


/*****************************************************************************
 *         SECTION: GENERATE OPTIMIZATION IN SIMULATION FILE
 *****************************************************************************/

template objectiveFunctionXml( list<DAE.ClassAttributes> classAttributes ,SimCode simCode)
  "Generates XML for Objective Functions."
::=
    (classAttributes |> classAttribute => classAttributesXml(classAttribute,simCode); separator="\n")

end objectiveFunctionXml;

template classAttributesXml(ClassAttributes classAttribute, SimCode simCode)
"Generates XML for class attributes of objective function."
::=
  match classAttribute
    case OPTIMIZATION_ATTRS(__) then
      let &varDecls = buffer "" /*BUFD*/
      let &preExp = buffer "" /*BUFD*/
      // let test = match objetiveE case SOME(exp) then
        // <<
        // <%daeExpXml(exp, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/)%>
        // >>
        // else 'No cref for Objective '
      let objectiveFunction = match objetiveE case SOME(exp) then
        <<
        <opt:ObjectiveFunction>
          <%daeExpXml(exp, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/)%>
        </opt:ObjectiveFunction>
        >>
      let objectiveIntegrand = match objectiveIntegrandE case SOME(exp) then
        <<
        <opt:IntegrandObjectiveFunction>
          <%daeExpXml(exp, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/)%>
        </opt:IntegrandObjectiveFunction>
        >>
      let startTime = match startTimeE case SOME(exp) then
        <<
        <opt:IntervalStartTime>
          <opt:Value><%daeExpValueXml(exp, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/)%></opt:Value>
        </opt:IntervalStartTime>
        >>
      let finalTime = match finalTimeE case SOME(exp) then
        <<
        <opt:IntervalFinalTime>
          <opt:Value><%daeExpValueXml(exp, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/)%></opt:Value>
        </opt:IntervalFinalTime>
        >>
      let timePointIndex = match startTimeE case SOME(exp) then
      <<
        index = "<%daeExpValueXml(exp, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/)%>"
      >>
      let timePointValue = match finalTimeE case SOME(exp) then
      <<
        value = "<%daeExpValueXml(exp, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/)%>"
      >>
      let constraints = match simCode case SIMCODE(modelInfo = MODELINFO(__)) then constraintsXml(constraints)
        <<
        <opt:Optimization>
          <%objectiveFunction%>
          <%objectiveIntegrand%>
          <%startTime%>
          <%finalTime%>
          <opt:TimePoints>
            <opt:TimePoint <%timePointIndex%> <%timePointValue%>>
            <%/*test*/%>
            </opt:TimePoint>
          </opt:TimePoints>
          <opt:PathConstraints>
              <%constraints%>
          </opt:PathConstraints>
        </opt:Optimization>
        >>
    else error(sourceInfo(), 'Unknown Optimization attribute')
end classAttributesXml;

template constraintsXml( list<DAE.Constraint> constraints)
  "Generates XML for Optimization."
::=
    (constraints |> constraint => constraintXml(constraint); separator="\n")

end constraintsXml;

template constraintXml(Constraint cons)
"Generates XML for List of Constraints."
::=
  match cons
    case CONSTRAINT_EXPS(__) then
      let &varDecls = buffer "" /*BUFD*/
      let &preExp = buffer "" /*BUFD*/
      let constrain = (constraintLst |> constraint =>
         daeExpConstraintXml(constraint, contextSimulationDiscrete, &preExp /*BUFC*/, &varDecls /*BUFD*/)
          ;separator="\n")
      <<
      <%constrain%>
      >>
    else error(sourceInfo(), 'Unknown Constraint List')
end constraintXml;

/*****************************************************************************
 *         SECTION: GENERATE All Algorithm IN SIMULATION FILE
 *****************************************************************************/

template funStatementXml(list<DAE.Statement> statementLst, Text &varDecls /*BUFP*/)
 "Generates function statements."
::=
  statementLst |> stmt => algStatementXml(stmt, contextFunction, &varDecls /*BUFD*/) ;separator="\n"
end funStatementXml;

template algStatementXml(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates an algorithm statement."
::=
  let res = match stmt
  case s as STMT_ASSIGN(__)         then algStmtAssignXml(s, context, &varDecls /*BUFD*/)
  case s as STMT_ASSIGN_ARR(__)     then algStmtAssignArrXml(s, context, &varDecls /*BUFD*/)
  case s as STMT_TUPLE_ASSIGN(__)   then algStmtTupleAssignXml(s, context, &varDecls /*BUFD*/)
  case s as STMT_IF(__)             then algStmtIfXml(s, context, &varDecls /*BUFD*/)
  case s as STMT_FOR(__)            then algStmtForXml(s, context, &varDecls /*BUFD*/)
  case s as STMT_WHILE(__)          then algStmtWhileXml(s, context, &varDecls /*BUFD*/)
  case s as STMT_ASSERT(__)         then algStmtAssertXml(s, context, &varDecls /*BUFD*/)
  case s as STMT_TERMINATE(__)      then algStmtTerminateXml(s, context, &varDecls /*BUFD*/)
  case s as STMT_WHEN(__)           then algStmtWhenXml(s, context, &varDecls /*BUFD*/)
  case s as STMT_BREAK(__)          then '<fun:Break/><%\n%>'
  case s as STMT_RETURN(__)         then '<fun:Return/><%\n%>'
  case s as STMT_NORETCALL(__)      then algStmtNoretcallXml(s, context, &varDecls /*BUFD*/)
  case s as STMT_REINIT(__)         then algStmtReinitXml(s, context, &varDecls /*BUFD*/)
  else error(sourceInfo(), 'ALG_STATEMENT NYI')
  <<
  <%res%>
  >>
end algStatementXml;

template algStmtAssignXml(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates an assigment algorithm statement."
::=
  match stmt
  case STMT_ASSIGN(exp1=CREF(componentRef=WILD(__)), exp=e) then
    let &preExp = buffer "" /*BUFD*/
    let expPart = daeExpXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    <fun:Assign>
      <fun:Expression>
        <%expPart%>
      </fun:Expression>
    </fun:Assign>
    >>
  case STMT_ASSIGN(exp1=CREF(ty = T_FUNCTION_REFERENCE_VAR(__)))
  case STMT_ASSIGN(exp1=CREF(ty = T_FUNCTION_REFERENCE_FUNC(__))) then
    let &preExp = buffer "" /*BUFD*/
    let varPart = scalarLhsCrefXml(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let expPart = daeExpXml(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    <fun:Assign>
      <%varPart%>
      <fun:Expression>
        <%expPart%>
      </fun:Expression>
    </fun:Assign>
    >>
  case STMT_ASSIGN(exp1=CREF(__)) then
    let &preExp = buffer "" /*BUFD*/
    let varPart = scalarLhsCrefXml(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let expPart = daeExpXml(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    <fun:Assign>
      <%varPart%>
      <fun:Expression>
        <%expPart%>
      </fun:Expression>
    </fun:Assign>
    >>
  case STMT_ASSIGN(exp1=exp1 as ASUB(__),exp=val) then
    (match expTypeFromExpShortXml(exp)
      case "metatype" then
        // MetaModelica Array
        (match exp case ASUB(exp=arr, sub={idx}) then
        let &preExp = buffer ""
        let arr1 = daeExpXml(arr, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        let idx1 = daeExpXml(idx, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        let val1 = daeExpXml(val, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        <<
        <%preExp%>
        <%arr1%>
        <%idx1%>
        <%val1%>
        >>)
        // Modelica Array
      else
        let &preExp = buffer "" /*BUFD*/
        let varPart = daeExpAsubXml(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        let expPart = daeExpXml(val, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        <<
        <fun:Assign>
          <%varPart%>
          <fun:Expression>
            <%expPart%>
          </fun:Expression>
        </fun:Assign>
        >>
    )
  case STMT_ASSIGN(__) then
    let &preExp = buffer "" /*BUFD*/
    let expPart1 = daeExpXml(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let expPart2 = daeExpXml(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    <fun:Assign>
      <%expPart1%>
      <fun:Expression>
        <%expPart2%>
      </fun:Expression>
    </fun:Assign>
    >>
end algStmtAssignXml;

template algStmtAssignArrXml(DAE.Statement stmt, Context context,
                 Text &varDecls /*BUFP*/)
 "Generates an array assigment algorithm statement."
::=
match stmt
case STMT_ASSIGN_ARR(exp=e, lhs=CREF(componentRef=cr), type_=t) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExpXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  let ispec = indexSpecFromCrefXml(cr, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  if ispec then
    <<
    <%preExp%>
    <%indexedAssignXml(t, expPart, cr, ispec, context, &varDecls)%>
    >>
  else
    <<
    <fun:Assign>
      <%copyArrayDataXml(t, expPart, cr, context)%>
      <fun:Expression>
        <%preExp%>
      </fun:Expression>
    </fun:Assign>
    >>
end algStmtAssignArrXml;

template indexedAssignXml(DAE.Type ty, String exp, DAE.ComponentRef cr,
  String ispec, Context context, Text &varDecls)
::=
  let type = expTypeArrayXml(ty)
  let cref = contextArrayCrefXml(cr, context)
  match context
  case FUNCTION_CONTEXT(__) then
    <<
    <%cref%>
    >>
  else
    <<
    <%exp%>
    <%ispec%>
    <%cref%>
    >>
end indexedAssignXml;

template copyArrayDataXml(DAE.Type ty, String exp, DAE.ComponentRef cr,

  Context context)
::=
  let type = expTypeArrayXml(ty)
  let cref = contextArrayCrefXml(cr, context)
  match context
  case FUNCTION_CONTEXT(__) then '<%cref%>'
  else
    <<
    <%cref%>
    >>

end copyArrayDataXml;

template algStmtTupleAssignXml(DAE.Statement stmt, Context context,
                   Text &varDecls /*BUFP*/)
 "Generates XML for a tuple assigment algorithm statement."
::=
match stmt
case STMT_TUPLE_ASSIGN(exp=CALL(__)) then
  let &preExp = buffer "" /*BUFD*/
  let &afterExp = buffer "" /*BUFD*/
  let crefs = (expExpLst |> e => ExpressionDumpTpl.dumpExp(e,"\"") ;separator=", ")
  let marker = '(<%crefs%>) = <%ExpressionDumpTpl.dumpExp(exp,"\"")%>'
  let &preExp += '/* algStmtTupleAssign: preExp buffer created for <%marker%> */<%\n%>'
  let &afterExp += '/* algStmtTupleAssign: afterExp buffer created for <%marker%> */<%\n%>'
  let retStruct = daeExpXml(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  let lhsCrefs = (expExpLst |> cr hasindex i1 fromindex 1 =>
                    let rhsStr = '<%retStruct%>.targ<%i1%>'
                    writeLhsCrefXml(cr, rhsStr, context, &afterExp /*BUFC*/, &varDecls /*BUFD*/)
                  ;separator="\n")
  <<
  <fun:FunctionCallStatement>
    <fun:OutputArgument>
      <%lhsCrefs%>
    </fun:OutputArgument>
    <%retStruct%>
  </fun:FunctionCallStatement>
  >>
case STMT_TUPLE_ASSIGN(exp=MATCHEXPRESSION(__)) then
  let &preExp = buffer "" /*BUFD*/
  let &afterExp = buffer "" /*BUFD*/
  let prefix = 'tmp<%System.tmpTick()%>'
  //let _ = daeExpMatch2Xml(exp, expExpLst, prefix, context, &preExp, &varDecls)
  let lhsCrefs = (expExpLst |> cr hasindex i1 fromindex 1 =>
                    let rhsStr = '<%prefix%>_targ<%i1%>'
                    writeLhsCrefXml(cr, rhsStr, context, &afterExp /*BUFC*/, &varDecls /*BUFD*/)
                  ;separator="\n")
  <<
  <%expExpLst |> cr hasindex i1 fromindex 1 =>
    let rhsStr = '<%prefix%>_targ<%i1%>'
    let typ = '<%expTypeFromExpModelicaXml(cr)%>'
    let initVar = match typ case "modelica_metatype" then ' = NULL' else ''
    let addRoot = match typ case "modelica_metatype" then ' mmc_GC_add_root(&<%rhsStr%>, mmc_GC_local_state, "<%rhsStr%>");' else ''
    let &varDecls += '<%typ%> <%rhsStr%><%initVar%>;<%addRoot%><%\n%>'
    ""
  ;separator="\n";empty%>
  <%preExp%>
  <%lhsCrefs%>
  <%afterExp%>
  >>
else error(sourceInfo(), 'algStmtTupleAssign failed')
end algStmtTupleAssignXml;

template writeLhsCrefXml(Exp exp, String rhsStr, Context context, Text &preExp /*BUFP*/,
              Text &varDecls /*BUFP*/)
 "Generates XML code for writing a returnStructur to var."
::=
match exp
case ecr as CREF(componentRef=WILD(__)) then
    <<
    <fun:EmptyOutputArgument></fun:EmptyOutputArgument>
    >>
case CREF(ty= t as DAE.T_ARRAY(__)) then
  let lhsStr = scalarLhsCrefXml(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  match context
  case SIMULATION_CONTEXT(__) then
    <<
    <%lhsStr%>
    >>
  else
    <<
    <%lhsStr%>
    >>

case UNARY(exp = e as CREF(ty= t as DAE.T_ARRAY(__))) then
  let lhsStr = scalarLhsCrefXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  match context
  case SIMULATION_CONTEXT(__) then
    <<
    <%rhsStr%>
    <%lhsStr%>
    >>
  else
    <<
    <%lhsStr%>
    >>
case CREF(__) then
  let lhsStr = scalarLhsCrefXml(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  <%lhsStr%>
  >>
case UNARY(exp = e as CREF(__)) then
  let lhsStr = scalarLhsCrefXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  <%lhsStr%>
  >>
case _ then
  <<
  /* SimCodeC.tpl template: writeLhsCref: UNHANDLED LHS
   * <%ExpressionDumpTpl.dumpExp(exp,"\"")%> = <%rhsStr%>
   */
  >>
end writeLhsCrefXml;

template algStmtIfXml(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates an if algorithm statement."
::=
match stmt
case STMT_IF(__) then
  let &preExp = buffer "" /*BUFD*/
  let condExp = daeExpXml(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    <fun:If>
      <fun:Condition>
        <%condExp%>
      </fun:Condition>
      <fun:Statements>
        <%statementLst |> stmt => algStatementXml(stmt, context, &varDecls /*BUFD*/) ;separator="\n"%>
      </fun:Statements>
      <%elseExprXml(else_, context, &varDecls /*BUFD*/)%>
    </fun:If>
    >>
end algStmtIfXml;

template algStmtForXml(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates a for algorithm statement."
::=
  match stmt
  case s as STMT_FOR(range=rng as RANGE(__)) then
    algStmtForRangeXml(s, context, &varDecls /*BUFD*/)
  case s as STMT_FOR(__) then
    algStmtForGenericXml(s, context, &varDecls /*BUFD*/)
end algStmtForXml;

template algStmtForRangeXml(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates a for algorithm statement where range is RANGE."
::=
match stmt
case STMT_FOR(range=rng as RANGE(__)) then
  let identType = expTypeXml(type_, iterIsArray)
  let identTypeShort = expTypeShortXml(type_)
  let stmtStr = (statementLst |> stmt => algStatementXml(stmt, context, &varDecls)
                 ;separator="\n")
  algStmtForRange_implXml(rng, iter, identType, identTypeShort, stmtStr, context, &varDecls)
end algStmtForRangeXml;

template algStmtForRange_implXml(Exp range, Ident iterator, String type, String shortType, Text body, Context context, Text &varDecls)
 "The implementation of algStmtForRange, ."
::=
match range
case RANGE(__) then
  let iterName = contextIteratorNameXml(iterator, context)
  let &preExp = buffer ""
  let startValue = daeExpXml(start, context, &preExp, &varDecls)
  let stepValue = match step case SOME(eo) then
      daeExpXml(eo, context, &preExp, &varDecls)
    else
      '' //because the default step value is 1
  let stopValue = daeExpXml(stop, context, &preExp, &varDecls)
    <<
    <fun:For>
      <fun:Index>
        <fun:IterationVariable>
          <exp:QualifiedNamePart name="<%iterName%>"/>
        </fun:IterationVariable>
        <fun:IterationSet>
          <exp:Range>
            <%startValue%>
            <%stepValue%>
            <%stopValue%>
          </exp:Range>
        </fun:IterationSet>
      </fun:Index>
      <fun:Statements>
        <%body%>
      </fun:Statements>
    </fun:For>
    >>
end algStmtForRange_implXml;

template algStmtForGenericXml(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates a for algorithm statement where range is not RANGE."
::=
match stmt
case STMT_FOR(__) then
  let iterType = expTypeXml(type_, iterIsArray)
  let arrayType = expTypeArrayXml(type_)

  let stmtStr = (statementLst |> stmt =>
    algStatementXml(stmt, context, &varDecls) ;separator="\n")
  algStmtForGeneric_implXml(range, iter, iterType, arrayType, iterIsArray, stmtStr,
    context, &varDecls)
end algStmtForGenericXml;

template algStmtForGeneric_implXml(Exp exp, Ident iterator, String type,
  String arrayType, Boolean iterIsArray, Text &body, Context context, Text &varDecls)
 "The implementation of algStmtForGeneric, which is also used by daeExpReduction."
::=
  let iterName = contextIteratorNameXml(iterator, context)
  let &preExp = buffer ""
  let evar = daeExpXml(exp, context, &preExp, &varDecls)
    <<
    <fun:For>
      <fun:Index>
        <fun:IterationVariable>
          <exp:QualifiedNamePart name="<%iterName%>"/>
        </fun:IterationVariable>
        <fun:IterationSet>
          <exp:Array>
            <%preExp%>
          </exp:Array>
        </fun:IterationSet>
      </fun:Index>
      <fun:Statements>
          <%body%>
      </fun:Statements>
    </fun:For>
    >>
end algStmtForGeneric_implXml;

template algStmtWhileXml(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates a while algorithm statement."
::=
match stmt
case STMT_WHILE(__) then
  let &preExp = buffer "" /*BUFD*/
  let var = daeExpXml(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    <fun:While>
      <fun:Condition>
        <%var%>
      </fun:Condition>
      <fun:Statements>
        <%statementLst |> stmt => algStatementXml(stmt, context, &varDecls /*BUFD*/) ;separator="\n"%>
      </fun:Statements>
    </fun:While>
    >>
end algStmtWhileXml;

template algStmtAssertXml(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates an assert algorithm statement."
::=
match stmt
case STMT_ASSERT(source=SOURCE(info=info)) then
  assertCommonXml(cond, msg, context, &varDecls, info)
end algStmtAssertXml;

template algStmtTerminateXml(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates an assert algorithm statement."
::=
match stmt
case STMT_TERMINATE(__) then
  let &preExp = buffer "" /*BUFD*/
  let msgVar = daeExpXml(msg, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  <%preExp%>
  <%msgVar%>
  >>
end algStmtTerminateXml;

template algStmtNoretcallXml(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates a no return call algorithm statement."
::=
match stmt
case STMT_NORETCALL(__) then
  let &preExp = buffer "" /*BUFD*/
  let expPart = daeExpXml(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  <<
  <%preExp%>
  <%expPart%>
  >>

end algStmtNoretcallXml;

template algStmtWhenXml(DAE.Statement when, Context context, Text &varDecls /*BUFP*/)
 "Generates a when algorithm statement."
::=
  match when
  case STMT_WHEN(__) then
    let cond = (conditions |> e => '<%crefToXmlStr(e)%>';separator="\n")
    let statements = (statementLst |> stmt =>
        algStatementXml(stmt, context, &varDecls /*BUFD*/)
      ;separator="\n")
    let else = algStatementWhenElseXml(elseWhen, &varDecls /*BUFD*/)
      <<
      <fun:When>
        <fun:Condition>
          <%cond%>
        </fun:Condition>
        <fun:Statements>
          <%statements%>
        </fun:Statements>
        <%else%>
      >>
  end match
end algStmtWhenXml;

template algStatementWhenElseXml(Option<DAE.Statement> stmt, Text &varDecls /*BUFP*/)
 "Helper to algStmtWhen."
::=
match stmt
case SOME(when as STMT_WHEN(__)) then
  let statements = (when.statementLst |> stmt =>
      algStatementXml(stmt, contextSimulationDiscrete, &varDecls /*BUFD*/)
    ;separator="\n")
  let else = algStatementWhenElseXml(when.elseWhen, &varDecls /*BUFD*/)
  let elseCondStr = (when.conditions |> e => '<%crefToXmlStr(e)%>';separator="\n ")
    <<
    <fun:Condition>
      <%elseCondStr%>
    </fun:Condition>
    <fun:Statements>
      <%statements%>
    </fun:Statements>
    <%else%>
    </fun:When>
    >>
end algStatementWhenElseXml;

template algStmtReinitXml(DAE.Statement stmt, Context context, Text &varDecls /*BUFP*/)
 "Generates an assigment algorithm statement."
::=
  match stmt
  case STMT_REINIT(__) then
    let &preExp = buffer "" /*BUFD*/
    let expPart1 = daeExpXml(var, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let expPart2 = daeExpXml(value, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      <<
      <exp:Reinit>
        <%expPart1%>
        <%expPart2%>
      </exp:Reinit>
      >>
end algStmtReinitXml;

template indexSpecFromCrefXml(ComponentRef cr, Context context, Text &preExp /*BUFP*/,
                  Text &varDecls /*BUFP*/)
 "Helper to algStmtAssignArr.
  Currently works only for CREF_IDENT."
::=
match cr
case CREF_IDENT(subscriptLst=subs as (_ :: _)) then
  daeExpCrefRhsIndexSpecXml(subs, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
end indexSpecFromCrefXml;

template elseExprXml(DAE.Else else_, Context context, Text &varDecls /*BUFP*/)
 "Helper to algStmtIf."
 ::=
  match else_
  case NOELSE(__) then
    ""
  case ELSEIF(__) then
    let &preExp = buffer "" /*BUFD*/
    let condExp = daeExpXml(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      <<
      <fun:ElseIf>
        <fun:Condition>
          <%condExp%>
        </fun:Condition>
        <%statementLst |> stmt =>algStatementXml(stmt, context, &varDecls /*BUFD*/);separator="\n"%>
      </fun:ElseIf>
      <%elseExprXml(else_, context, &varDecls /*BUFD*/)%>
      >>
  case ELSE(__) then
    <<
    <fun:Else>
      <%statementLst |> stmt =>
        algStatementXml(stmt, context, &varDecls /*BUFD*/)
      ;separator="\n"%>
    </fun:Else>
    >>
end elseExprXml;

template scalarLhsCrefXml(Exp ecr, Context context, Text &preExp, Text &varDecls)
 "Generates the left hand side (for use on left hand side) of a component
  reference."
::=
  match ecr
  case CREF(componentRef = cr, ty = T_FUNCTION_REFERENCE_VAR(__)) then
    <<
    <%crefStrXml(cr)%>
    >>
  case ecr as CREF(componentRef=CREF_IDENT(__)) then
    if crefNoSub(ecr.componentRef) then
     crefXml(ecr.componentRef)
    else
      daeExpCrefLhsXml(ecr, context, &preExp, &varDecls)
  case ecr as CREF(componentRef=CREF_QUAL(__)) then
    crefXml(ecr.componentRef)
  case ecr as CREF(componentRef=WILD(__)) then
    ''
  else
    "ONLY_IDENT_OR_QUAL_CREF_SUPPORTED_SLHS"
end scalarLhsCrefXml;

/*****************************************************************************
 *         SECTION: GENERATE  All DAE Expression IN SIMULATION FILE
 *****************************************************************************/

template daeExpXml(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Root Template for Expression-XML generation."
::=
  let e = daeExpXml_dispatch(exp, context, &preExp /*BUFP*/, &varDecls /*BUFP*/)
  let eStr1 = if e then e else preExp
  let eStr2 = if intEq(0, stringFind(eStr1, "tmp")) then preExp else eStr1
  eStr2
end daeExpXml;

template daeExpXml_dispatch(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Root Template for Expression-XML generation."
::=
  match exp
  case e as ICONST(__)          then '<exp:IntegerLiteral><%integer%></exp:IntegerLiteral>'
  case e as RCONST(__)          then '<exp:RealLiteral><%real%></exp:RealLiteral>'
  case e as SCONST(__)          then '<exp:StringLiteral><%daeExpSconstXml(string, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)%></exp:StringLiteral>'
  case e as BCONST(__)          then '<exp:BooleanLiteral>' + (if bool then "1" else "0") + '</exp:BooleanLiteral>'
  case e as ENUM_LITERAL(__)    then index
  case e as CREF(__)            then daeExpCrefRhsXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as BINARY(__)          then daeExpBinaryXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as UNARY(__)           then daeExpUnaryXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as LBINARY(__)         then daeExpLbinaryXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as LUNARY(__)          then daeExpLunaryXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as RELATION(__)        then daeExpRelationXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as IFEXP(__)           then daeExpIfXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as CALL(__)            then daeExpCallXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as ARRAY(__)           then daeExpArrayXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as MATRIX(__)          then daeExpMatrixXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as RANGE(__)           then daeExpRangeXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as CAST(__)            then daeExpCastXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as ASUB(__)            then daeExpAsubXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as TSUB(__)            then '<%daeExpXml(exp, context, &preExp, &varDecls)%>'
  case e as SIZE(__)            then daeExpSizeXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as TUPLE(__)           then 'Tuple Not yet Implemented'
  case e as BOX(__)             then daeExpBoxXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as UNBOX(__)           then daeExpUnboxXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case e as SHARED_LITERAL(__)  then daeExpSharedLiteralXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  else error(sourceInfo(), 'Unknown expression: <%ExpressionDumpTpl.dumpExp(exp,"\"")%>')
end daeExpXml_dispatch;

template daeExpValueXml(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Expression-XML generation mainly used for optimica extension start and final value."
::=
  match exp
  case e as ICONST(__)          then '<%integer%>'
  case e as RCONST(__)          then '<%real%>'
end daeExpValueXml;

template daeExternalXmlExp(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
  "Like daeExp, "
::=
  match typeof(exp)
    case T_ARRAY(__) then  // Array-expressions
      <<
      <%daeExpXml(exp, context, &preExp, &varDecls)%>
      >>
end daeExternalXmlExp;

template daeExpSconstXml(String string, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates code for a string constant."
::=
  <<
  "<%Util.escapeModelicaStringToXmlString(string)%>"
  >>
end daeExpSconstXml;


/*********************************************************************
 *********************************************************************
 *                       RIGHT HAND SIDE
 *********************************************************************
 *********************************************************************/

template daeExpCrefRhsXml(Exp exp, Context context, Text &preExp /*BUFP*/,
                       Text &varDecls /*BUFP*/)
 "Generates code for a component reference on the right hand side of an
 expression."
::=
  match exp
  // A record cref without subscripts (i.e. a record instance) is handled
  // by daeExpRecordCrefRhs only in a simulation context, not in a function.
  case CREF(componentRef = cr, ty = t as T_COMPLEX(complexClassType = RECORD(path = _))) then
    match context case FUNCTION_CONTEXT(__) then
      daeExpCrefRhs2Xml(exp, context, &preExp, &varDecls)
    else
      daeExpRecordCrefRhsXml(t, cr, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case CREF(componentRef = cr, ty = T_FUNCTION_REFERENCE_FUNC(__)) then
    <<
    <%crefFunctionNameXml(cr)%>
    >>

  case CREF(componentRef = cr, ty = T_FUNCTION_REFERENCE_VAR(__)) then
    <<
    <%crefStrXml(cr)%>
    >>
   else daeExpCrefRhs2Xml(exp, context, &preExp, &varDecls)
end daeExpCrefRhsXml;

template daeExpCrefRhs2Xml(Exp ecr, Context context, Text &preExp /*BUFP*/,
                        Text &varDecls /*BUFP*/)
 "Generates code for a component reference."
::=
  match ecr
  case ecr as CREF(componentRef=cr, ty=ty) then
    // let &preExp += '/* daeExpCrefRhs2 begin preExp (<%ExpressionDumpTpl.dumpExp(ecr,"\"")%>) */<%\n%>'
    let box = daeExpCrefRhsArrayBoxXml(ecr, context, &preExp, &varDecls)
    if box then
      box
    else
      if crefIsScalar(cr, context)
      then
        <<
        <%crefXml(ecr.componentRef)%>
        >>

      else
        if crefSubIsScalar(cr)
        then
          // The array subscript results in a scalar
          // let &preExp += '/* daeExpCrefRhs2 SCALAR(<%ExpressionDumpTpl.dumpExp(ecr,"\"")%>) preExp  */<%\n%>'
          let arrName = contextCrefXml(crefStripLastSubs(cr), context)
          let arrayType = expTypeArrayXml(ty)
          let dimsLenStr = listLength(crefSubs(cr))
          match arrayType
            case "metatype_array" then
              let dimsValuesStr = (crefSubs(cr) |> INDEX(__) =>
                 daeExpXml(exp, context, &preExp, &varDecls)
                 ;separator=", ")
              'arrayGet(<%arrName%>,<%dimsValuesStr%>) /* DAE.CREF */'
            else
              match context
              case FUNCTION_CONTEXT(__) then
                let dimsValuesStr = (crefSubs(cr) |> INDEX(__) =>
                  daeExpXml(exp, context, &preExp, &varDecls)
                  ;separator="\n ")
                <<
                <exp:Identifier>
                  <exp:QualifiedNamePart name="<%arrName%>">
                    <exp:ArraySubscripts>
                      <exp:IndexExpression>
                        <%dimsValuesStr%>
                      </exp:IndexExpression>
                    </exp:ArraySubscripts>
                  </exp:QualifiedNamePart>
                </exp:Identifier>
                >>
              else
                match crefLastType(cr)
                case et as T_ARRAY(__) then
                <<
                (&<%arrName%>)[<%threadDimSubListXml(et.dims,crefSubs(cr),context,&preExp,&varDecls)%>]
                >>
                else error(sourceInfo(),'Indexing non-array <%ExpressionDumpTpl.dumpExp(ecr,"\"")%>')
        else
          // The array subscript denotes a slice
          // let &preExp += '/* daeExpCrefRhs2 SLICE(<%ExpressionDumpTpl.dumpExp(ecr,"\"")%>) preExp  */<%\n%>'
          let arrName = contextArrayCrefXml(cr, context)
          let arrayType = expTypeArrayXml(ty)
          let tmp = tempDeclXml(arrayType, &varDecls /*BUFD*/)
          let spec1 = daeExpCrefRhsIndexSpecXml(crefSubs(cr), context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
          let &preExp +=
            <<
            <%arrName%>
            <%spec1%><%\n%>
            >>
          tmp

  case ecr then
    // let &preExp += '/* daeExpCrefRhs2 UNHANDLED(<%ExpressionDumpTpl.dumpExp(ecr,"\"")%>) preExp */<%\n%>'
    error(sourceInfo(),'daeExpCrefRhs2: UNHANDLED EXPRESSION: <%ExpressionDumpTpl.dumpExp(ecr,"\"")%>')
end daeExpCrefRhs2Xml;

template threadDimSubListXml(list<Dimension> dims, list<Subscript> subs, Context context, Text &preExp, Text &varDecls)
  "Do direct indexing since sizes are known during compile-time"
::=
  match subs
  case {} then error(sourceInfo(),"Empty dimensions in indexing cref?")
  case (sub as INDEX(__))::subrest
  then
    match dims
      case _::dimrest
      then
        let estr = daeExpXml(sub.exp, context, &preExp, &varDecls)
        '((<%estr%>)<%
          dimrest |> dim =>
          match dim
          case DIM_INTEGER(__) then '*<%integer%>'
          case DIM_ENUM(__) then '*<%size%>'
          else error(sourceInfo(),"Non-constant dimension in simulation context")
        %>)<%match subrest case {} then "" else '+<%threadDimSubListXml(dimrest,subrest,context,&preExp,&varDecls)%>'%>'
      else error(sourceInfo(),"Less subscripts that dimensions in indexing cref? That's odd!")
  else error(sourceInfo(),"Non-index subscript in indexing cref? That's odd!")
end threadDimSubListXml;

template daeExpCrefRhsIndexSpecXml(list<Subscript> subs, Context context,
                                Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Helper to daeExpCrefRhs."
::=
  let nridx_str = listLength(subs)
  let idx_str = (subs |> sub =>
      match sub
      case INDEX(__) then
        let expPart = daeExpXml(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        let str =
        <<
        <%expPart%>
        >>
        str
      case WHOLEDIM(__) then
        let str = <<(1), (int*)0, 'W'>>
        str
      case SLICE(__) then
        let expPart = daeExpXml(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
        let tmp = tempDeclXml("modelica_integer", &varDecls /*BUFD*/)
        let &preExp += '<%tmp%> = size_of_dimension_integer_array(&<%expPart%>, 1);<%\n%>'
        let str = <<(int) <%tmp%>, integer_array_make_index_array(&<%expPart%>), 'A'>>
        str
    ;separator=", ")
  let tmp = tempDeclXml("index_spec_t", &varDecls /*BUFD*/)
  let &preExp += 'create_index_spec(&<%tmp%>, <%nridx_str%>, <%idx_str%>);<%\n%>'
  tmp
end daeExpCrefRhsIndexSpecXml;

template daeExpCrefRhsArrayBoxXml(Exp ecr, Context context, Text &preExp /*BUFP*/,
                               Text &varDecls /*BUFP*/)
 "Helper to daeExpCrefRhs."
::=
match ecr
case ecr as CREF(ty=T_ARRAY(ty=aty,dims=dims)) then
  match context
  case FUNCTION_CONTEXT(__) then ''
  else
    // For context simulation and other array variables must be boxed into a real_array
    // object since they are represented only in a double array.
    let tmpArr = tempDeclXml(expTypeArrayXml(aty), &varDecls /*BUFD*/)
    let dimsLenStr = listLength(dims)
    let dimsValuesStr = (dims |> dim => dimensionXml(dim) ;separator=", ")
    let type = expTypeShortXml(aty)
    let &preExp +=
      <<
      <%arrayCrefXmlStr(ecr.componentRef)%><%\n%>
      >>
    tmpArr
end daeExpCrefRhsArrayBoxXml;

template daeExpRecordCrefRhsXml(DAE.Type ty, ComponentRef cr, Context context, Text &preExp /*BUFP*/,
                       Text &varDecls /*BUFP*/)
::=
match ty
case T_COMPLEX(complexClassType = record_state, varLst = var_lst) then
  let vars = var_lst |> v => daeExpXml(makeCrefRecordExp(cr,v), context, &preExp, &varDecls)
             ;separator="\n "
   <<
   <%vars%>
   >>
end daeExpRecordCrefRhsXml;


/*********************************************************************
 *********************************************************************
 *                       LEFT HAND SIDE
 *********************************************************************
 *********************************************************************/

 /*
  * adrpo:2011-06-25: NOTE that Lhs generates afterExp not preExp!
  *                   Also, all the causality is REVERSED, meaning
  *                   that if for RHS x = y for LHS y = x;
  */


template daeExpCrefLhsXml(Exp exp, Context context, Text &afterExp /*BUFP*/,
                       Text &varDecls /*BUFP*/)
 "Generates code for a component reference on the left hand side of an expression."
::=
  match exp
  // A record cref without subscripts (i.e. a record instance) is handled
  // by daeExpRecordCrefLhs only in a simulation context, not in a function.
  case CREF(componentRef = cr, ty = t as T_COMPLEX(complexClassType = RECORD(path = _))) then
    match context case FUNCTION_CONTEXT(__) then
      daeExpCrefLhs2Xml(exp, context, &afterExp, &varDecls)
    else
      daeExpRecordCrefLhsXml(t, cr, context, &afterExp /*BUFC*/, &varDecls /*BUFD*/)
  case CREF(componentRef = cr, ty = T_FUNCTION_REFERENCE_FUNC(__)) then
    <<
    <%crefFunctionNameXml(cr)%>
    >>

  case CREF(componentRef = cr, ty = T_FUNCTION_REFERENCE_VAR(__)) then
    <<
    <%crefStrXml(cr)%>
    >>
   else daeExpCrefLhs2Xml(exp, context, &afterExp, &varDecls)
end daeExpCrefLhsXml;

template daeExpCrefLhs2Xml(Exp ecr, Context context, Text &afterExp /*BUFP*/,
                        Text &varDecls /*BUFP*/)
 "Generates XML code for a component reference on the left hand side!"
::=
  match ecr
  case ecr as CREF(componentRef=cr, ty=ty) then
    let &afterExp += '/* daeExpCrefLhs2 begin afterExp (<%ExpressionDumpTpl.dumpExp(ecr,"\"")%>) */<%\n%>'
    let box = daeExpCrefLhsArrayBoxXml(ecr, context, &afterExp, &varDecls)
    if box then
      box
    else
      if crefIsScalar(cr, context)
      then
        <<
        <%contextCrefXml(cr,context)%>
        >>

      else
        if crefSubIsScalar(cr)
        then
          // The array subscript results in a scalar
          let &afterExp += '/* daeExpCrefLhs2 SCALAR(<%ExpressionDumpTpl.dumpExp(ecr,"\"")%>) afterExp  */<%\n%>'
          let arrName = contextCrefXml(crefStripLastSubs(cr), context)
          let arrayType = expTypeArrayXml(ty)
          let dimsLenStr = listLength(crefSubs(cr))
          let dimsValuesStr = (crefSubs(cr) |> INDEX(__) =>
              daeExpXml(exp, context, &afterExp /*BUFC*/, &varDecls /*BUFD*/)
            ;separator="\n")
          match arrayType
            case "metatype_array" then
              'arrayGet(<%arrName%>,<%dimsValuesStr%>) /* DAE.CREF */'
            else
              <<
              <exp:Identifier>
                <exp:QualifiedNamePart name="<%arrName%>">
                  <exp:ArraySubscripts>
                    <exp:IndexExpression>
                      <%dimsValuesStr%>
                    </exp:IndexExpression>
                  </exp:ArraySubscripts>
                </exp:QualifiedNamePart>
              </exp:Identifier>
              >>
        else
          // The array subscript denotes a slice
          let &afterExp += '/* daeExpCrefLhs2 SLICE(<%ExpressionDumpTpl.dumpExp(ecr,"\"")%>) afterExp  */<%\n%>'
          let arrName = contextArrayCrefXml(cr, context)
          let arrayType = expTypeArrayXml(ty)
          let tmp = tempDeclXml(arrayType, &varDecls /*BUFD*/)
          let spec1 = daeExpCrefLhsIndexSpecXml(crefSubs(cr), context, &afterExp /*BUFC*/, &varDecls /*BUFD*/)
          let &afterExp += 'indexed_assign_<%arrayType%>(&<%tmp%>, &<%arrName%>, &<%spec1%>);<%\n%>'
          tmp

  case ecr then
    let &afterExp += '/* daeExpCrefLhs2 UNHANDLED(<%ExpressionDumpTpl.dumpExp(ecr,"\"")%>) afterExp */<%\n%>'
    <<
    /* SimCodeC.tpl template: daeExpCrefLhs2: UNHANDLED EXPRESSION:
     * <%ExpressionDumpTpl.dumpExp(ecr,"\"")%>
     */
    >>
end daeExpCrefLhs2Xml;

template daeExpCrefLhsIndexSpecXml(list<Subscript> subs, Context context,
                                Text &afterExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Helper to daeExpCrefLhs."
::=
  let nridx_str = listLength(subs)
  let idx_str = (subs |> sub =>
      match sub
      case INDEX(__) then
        let expPart = daeExpXml(exp, context, &afterExp /*BUFC*/, &varDecls /*BUFD*/)
        let str = <<(0), make_index_array(1, (int) <%expPart%>), 'S'>>
        str
      case WHOLEDIM(__) then
        let str = <<(1), (int*)0, 'W'>>
        str
      case SLICE(__) then
        let expPart = daeExpXml(exp, context, &afterExp /*BUFC*/, &varDecls /*BUFD*/)
        let tmp = tempDeclXml("modelica_integer", &varDecls /*BUFD*/)
        let &afterExp += '<%tmp%> = size_of_dimension_integer_array(&<%expPart%>, 1);<%\n%>'
        let str = <<(int) <%tmp%>, integer_array_make_index_array(&<%expPart%>), 'A'>>
        str
    ;separator=", ")
  let tmp = tempDeclXml("index_spec_t", &varDecls /*BUFD*/)
  let &afterExp += 'create_index_spec(&<%tmp%>, <%nridx_str%>, <%idx_str%>);<%\n%>'
  tmp
end daeExpCrefLhsIndexSpecXml;

template daeExpCrefLhsArrayBoxXml(Exp ecr, Context context, Text &afterExp /*BUFP*/,
                               Text &varDecls /*BUFP*/)
 "Helper to daeExpCrefLhs."
::=
match ecr
case ecr as CREF(ty=T_ARRAY(ty=aty,dims=dims)) then
  match context
  case FUNCTION_CONTEXT(__) then ''
  else
    // For context simulation and other array variables must be boxed into a real_array
    // object since they are represented only in a double array.
    let tmpArr = tempDeclXml(expTypeArrayXml(aty), &varDecls /*BUFD*/)
    let dimsLenStr = listLength(dims)
    let dimsValuesStr = (dims |> dim => dimensionXml(dim) ;separator=", ")
    let type = expTypeShortXml(aty)
    let &afterExp += '<%type%>_array_create(&<%tmpArr%>, ((modelica_<%type%>*)&(<%arrayCrefXmlStr(ecr.componentRef)%>)), <%dimsLenStr%>, <%dimsValuesStr%>);<%\n%>'
    tmpArr
end daeExpCrefLhsArrayBoxXml;

template daeExpRecordCrefLhsXml(DAE.Type ty, ComponentRef cr, Context context, Text &afterExp /*BUFP*/,
                             Text &varDecls /*BUFP*/)
::=
match ty
case T_COMPLEX(complexClassType = record_state, varLst = var_lst) then
  let vars = var_lst |> v => daeExpXml(makeCrefRecordExp(cr,v), context, &afterExp, &varDecls)
             ;separator=", "
  let record_type_name = underscorePathXml(ClassInf.getStateName(record_state))
  let ret_type = '<%record_type_name%>_rettype'
  let ret_var = tempDeclXml(ret_type, &varDecls)
  let &afterExp += '<%ret_var%> = _<%record_type_name%>(<%vars%>);<%\n%>'
  '<%ret_var%>.<%ret_type%>_1'
end daeExpRecordCrefLhsXml;

/*********************************************************************
 *********************************************************************
 *                         DONE RHS and LHS
 *********************************************************************
 *********************************************************************/

template daeExpBinaryXml(Exp exp, Context context, Text &preExp /*BUFP*/,
                      Text &varDecls /*BUFP*/)
 "Generates code for a binary expression."
::=

match exp
case BINARY(__) then
  let e1 = daeExpXml(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  let e2 = daeExpXml(exp2, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  match operator
  case ADD(__) then
    <<
    <exp:Add>
      <%e1%>
      <%e2%>
    </exp:Add>
    >>
  case SUB(__) then
    <<
    <exp:Sub>
      <%e1%>
      <%e2%>
    </exp:Sub>
    >>
  case MUL(__) then
    <<
    <exp:Mul>
      <%e1%>
      <%e2%>
    </exp:Mul>
    >>
  case DIV(__) then
    <<
    <exp:Div>
      <%e1%>
      <%e2%>
    </exp:Div>
    >>
  case POW(__) then
    <<
    <exp:Pow>
      <%e1%>
      <%e2%>
    </exp:Pow>
    >>
  case UMINUS(__) then daeExpUnaryXml(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  case ADD_ARR(__) then
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then "integer_array"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then "integer_array"
                        else "real_array"
    let var = tempDeclXml(type, &varDecls /*BUFD*/)
    let &preExp +=
    <<
    <exp:Add>
      <%e1%>
      <%e2%>
    </exp:Add> <%\n%>
    >>
    '<%var%>'
  case SUB_ARR(__) then
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then "integer_array"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then "integer_array"
                        else "real_array"
    let var = tempDeclXml(type, &varDecls /*BUFD*/)
    let &preExp +=
    <<
    <exp:Sub>
    <%e1%>
    <%e2%>
    </exp:Sub> <%\n%>
    >>
    '<%var%>'
  case MUL_ARR(__) then  'daeExpBinary:ERR for MUL_ARR'
  case DIV_ARR(__) then  'daeExpBinary:ERR for DIV_ARR'
  case MUL_ARRAY_SCALAR(__) then
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then "integer_array"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then "integer_array"
                        else "real_array"
    let var = tempDeclXml(type, &varDecls /*BUFD*/)
    let &preExp +=
    <<
    <exp:Mul>
    <%e1%>
    <%e2%>
    </exp:Mul> <%\n%>
    >>
    '<%var%>'
  case ADD_ARRAY_SCALAR(__) then 'daeExpBinary:ERR for ADD_ARRAY_SCALAR'
  case SUB_SCALAR_ARRAY(__) then 'daeExpBinary:ERR for SUB_SCALAR_ARRAY'
  case MUL_SCALAR_PRODUCT(__) then
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then "integer_scalar"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then "integer_scalar"
                        else "real_scalar"
    'mul_<%type%>_product(&<%e1%>, &<%e2%>)'
  case MUL_MATRIX_PRODUCT(__) then
    let typeShort = match ty case T_ARRAY(ty=T_INTEGER(__)) then "integer"
                             case T_ARRAY(ty=T_ENUMERATION(__)) then "integer"
                             else "real"
    let type = '<%typeShort%>_array'
    let var = tempDeclXml(type, &varDecls /*BUFD*/)
    let &preExp +=
    <<
    <exp:Mul>
    <%e1%>
    <%e2%>
    </exp:Mul> <%\n%>
    >>
    '<%var%>'
  case DIV_ARRAY_SCALAR(__) then
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then "integer_array"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then "integer_array"
                        else "real_array"
    let var = tempDeclXml(type, &varDecls /*BUFD*/)
    let &preExp +=
    <<
    <exp:Div>
    <%e1%>
    <%e2%>
    </exp:Div> <%\n%>
    >>
    '<%var%>'
  case DIV_SCALAR_ARRAY(__) then 'daeExpBinary:ERR for DIV_SCALAR_ARRAY'
  case POW_ARRAY_SCALAR(__) then 'daeExpBinary:ERR for POW_ARRAY_SCALAR'
  case POW_SCALAR_ARRAY(__) then 'daeExpBinary:ERR for POW_SCALAR_ARRAY'
  case POW_ARR(__) then 'daeExpBinary:ERR for POW_ARR'
  case POW_ARR2(__) then 'daeExpBinary:ERR for POW_ARR2'
  else "daeExpBinary:ERR"
end daeExpBinaryXml;

template daeExpUnaryXml(Exp exp, Context context, Text &preExp /*BUFP*/,
                     Text &varDecls /*BUFP*/)
 "Generates code for a unary expression."
::=
match exp
case UNARY(__) then
  let e = daeExpXml(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  match operator
  case UMINUS(__)     then
    <<
      <exp:Neg>
        <%e%>
      </exp:Neg>
    >>
  case UMINUS_ARR(ty=T_ARRAY(ty=T_REAL(__))) then
    <<
      <exp:Neg>
        <%e%>
      </exp:Neg>
    >>
  case UMINUS_ARR(__) then error(sourceInfo(),"unary minus for non-real arrays not implemented")
  else error(sourceInfo(),"daeExpUnary:ERR")
end daeExpUnaryXml;

template daeExpLbinaryXml(Exp exp, Context context, Text &preExp /*BUFP*/,
                       Text &varDecls /*BUFP*/)
 "Generates code for a logical binary expression."
::=
match exp
case LBINARY(__) then
  let e1 = daeExpXml(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  let e2 = daeExpXml(exp2, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  match operator
  case AND(__) then
    <<
    <exp:And>
      <%e1%>
      <%e2%>
    </exp:And>
    >>
  case OR(__)  then
    <<
    <exp:Or>
      <%e1%>
      <%e2%>
    </exp:Or>
    >>
  else "daeExpLbinary:ERR"
end daeExpLbinaryXml;

template daeExpLunaryXml(Exp exp, Context context, Text &preExp /*BUFP*/,
                      Text &varDecls /*BUFP*/)
 "Generates code for a logical unary expression."
::=
match exp
case LUNARY(__) then
  let e = daeExpXml(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  match operator
  case NOT(__) then
    <<
    <exp:Not>
      <%e%>
    </exp:Not>
    >>
end daeExpLunaryXml;

template daeExpRelationXml(Exp exp, Context context, Text &preExp /*BUFP*/,
                        Text &varDecls /*BUFP*/)
 "Generates code for a relation expression."
::=
match exp
case rel as RELATION(__) then
  let simRel = daeExpRelationSimXml(rel, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  if simRel then
    simRel
  else
    let e1 = daeExpXml(rel.exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let e2 = daeExpXml(rel.exp2, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    match rel.operator

    case LESS(ty = T_BOOL(__))             then '(!<%e1%> && <%e2%>)'
    case LESS(ty = T_STRING(__))           then '(stringCompare(<%e1%>, <%e2%>) < 0)'
    case LESS(__)                          then
      <<
      <exp:LogLt>
        <%e1%>
        <%e2%>
      </exp:LogLt>
      >>
    case GREATER(ty = T_BOOL(__))          then '(<%e1%> && !<%e2%>)'
    case GREATER(ty = T_STRING(__))        then '(stringCompare(<%e1%>, <%e2%>) > 0)'
    case GREATER(__)       then
      <<
      <exp:LogGt>
        <%e1%>
        <%e2%>
      </exp:LogGt>
      >>
    case LESSEQ(ty = T_BOOL(__))           then '(!<%e1%> || <%e2%>)'
    case LESSEQ(ty = T_STRING(__))         then '(stringCompare(<%e1%>, <%e2%>) <= 0)'
    case LESSEQ(__)                        then
      <<
      <exp:LogLeq>
        <%e1%>
        <%e2%>
      </exp:LogLeq>
      >>
    case GREATEREQ(ty = T_BOOL(__))        then '(<%e1%> || !<%e2%>)'
    case GREATEREQ(ty = T_STRING(__))      then '(stringCompare(<%e1%>, <%e2%>) >= 0)'
    case GREATEREQ(__)     then
      <<
      <exp:LogGeq>
        <%e1%>
        <%e2%>
      </exp:LogGeq>
      >>
    case EQUAL(ty = T_BOOL(__))            then '((!<%e1%> && !<%e2%>) || (<%e1%> && <%e2%>))'
    case EQUAL(ty = T_STRING(__))          then '(stringEqual(<%e1%>, <%e2%>))'
    case EQUAL(__)                         then
      <<
      <exp:LogEq>
        <%e1%>
        <%e2%>
      </exp:LogEq>
      >>
    case NEQUAL(ty = T_BOOL(__))           then '((!<%e1%> && <%e2%>) || (<%e1%> && !<%e2%>))'
    case NEQUAL(ty = T_STRING(__))         then '(!stringEqual(<%e1%>, <%e2%>))'
    case NEQUAL(__)                        then
      <<
      <exp:LogNeq>
        <%e1%>
        <%e2%>
      </exp:LogNeq>
      >>
    else "daeExpRelation:ERR"

end daeExpRelationXml;

template daeExpRelationSimXml(Exp exp, Context context, Text &preExp /*BUFP*/,
                           Text &varDecls /*BUFP*/)
 "Helper to daeExpRelation."
::=
match exp
case rel as RELATION(__) then
  match context
  case SIMULATION_CONTEXT(genDiscrete=false) then
     match rel.optionExpisASUB
     case NONE() then
        let e1 = daeExpXml(rel.exp1, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
        let e2 = daeExpXml(rel.exp2, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
        let res = tempDeclXml("modelica_boolean", &varDecls /*BUFC*/)
        match rel.operator
        case LESS(__) then
          let &preExp +=
          <<
          <exp:LogLt>
            <%e1%>
            <%e2%>
          </exp:LogLt> <%\n%>
          >>
          res
        case LESSEQ(__) then
          let &preExp +=
          <<
          <exp:LogLeq>
            <%e1%>
            <%e2%>
          </exp:LogLeq> <%\n%>
          >>
          res
        case GREATER(__) then
          let &preExp +=
          <<
          <exp:LogGt>
            <%e1%>
            <%e2%>
          </exp:LogGt> <%\n%>
          >>
          res
        case GREATEREQ(__) then
          let &preExp +=
          <<
          <exp:LogGeq>
            <%e1%>
            <%e2%>
          </exp:LogGeq> <%\n%>
          >>
          res
        end match
    case SOME((exp,i,j)) then
      let e1 = daeExpXml(rel.exp1, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
      let e2 = daeExpXml(rel.exp2, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
      let iterator = daeExpXml(exp, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
      let res = tempDeclXml("modelica_boolean", &varDecls /*BUFC*/)
      //let e3 = daeExp(createArray(i), context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
      match rel.operator
      case LESS(__) then
        let &preExp +=
        <<
          <exp:LogLt>
            <%e1%>
            <%e2%>
          </exp:LogLt><%\n%>
        >>
        res
      case LESSEQ(__) then
        let &preExp +=
        <<
          <exp:LogLeq>
            <%e1%>
            <%e2%>
          <exp:LogLeq> <%\n%>
        >>
        res
      case GREATER(__) then
        let &preExp +=
        <<
          <exp:LogGt>
            <%e1%>
            <%e2%>
          </exp:LogGt><%\n%>
        >>
        res
      case GREATEREQ(__) then
        let &preExp +=
        <<
          <exp:LogGeq>
            <%e1%>
            <%e2%>
          </exp:LogGeq><%\n%>
        >>
        res
        end match
      end match
   case SIMULATION_CONTEXT(genDiscrete=true) then
     match rel.optionExpisASUB
     case NONE() then
        let e1 = daeExpXml(rel.exp1, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
        let e2 = daeExpXml(rel.exp2, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
        let res = tempDeclXml("modelica_boolean", &varDecls /*BUFC*/)
       match rel.operator
        case LESS(__) then
          let &preExp +=
          <<
          <exp:LogLt>
            <%e1%>
            <%e2%>
          </exp:LogLt><%\n%>
          >>
          res
        case LESSEQ(__) then
          let &preExp +=
          <<
          <exp:LogLeq>
            <%e1%>
            <%e2%>
          </exp:LogLeq> <%\n%>
          >>
          res
        case GREATER(__) then
          let &preExp +=
          <<
          <exp:LogGt>
            <%e1%>
            <%e2%>
          </exp:LogGt><%\n%>
          >>
          res
        case GREATEREQ(__) then
          let &preExp +=
          <<
          <exp:LogGeq>
            <%e1%>
            <%e2%>
          </exp:LogGeq><%\n%>
          >>
          res
        end match
    case SOME((exp,i,j)) then
         let e1 = daeExpXml(rel.exp1, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
         let e2 = daeExpXml(rel.exp2, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
         let res = tempDeclXml("modelica_boolean", &varDecls /*BUFC*/)
         //let e3 = daeExp(createArray(i), context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
         let iterator = daeExpXml(exp, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
     match rel.operator
     case LESS(__) then
        let &preExp +=
        <<
            <exp:LogLt>
              <%e1%>
              <%e2%>
            </exp:LogLt><%\n%>
        >>
        res
     case LESSEQ(__) then
        let &preExp +=
        <<
            <exp:LogLeq>
              <%e1%>
              <%e2%>
            </exp:LogLeq> <%\n%>
        >>
        res
     case GREATER(__) then
        let &preExp +=
        <<
            <exp:LogGt>
              <%e1%>
              <%e2%>
            </exp:LogGt><%\n%>
        >>
        res
     case GREATEREQ(__) then
        let &preExp +=
        <<
            <exp:LogGeq>
              <%e1%>
              <%e2%>
            </exp:LogGeq><%\n%>
        >>
        res
          end match
        end match
  end match
end match
end daeExpRelationSimXml;

template daeExpConstraintXml(Exp exp, Context context, Text &preExp /*BUFP*/,
                           Text &varDecls /*BUFP*/)
 "Generates XML for constraint"
::=
match exp
case rel as RELATION(__) then
  match context
   case SIMULATION_CONTEXT(genDiscrete=true) then
     match rel.optionExpisASUB
     case NONE() then
        let e1 = daeExpXml(rel.exp1, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
        let e2 = daeExpXml(rel.exp2, context, &preExp /*BUFC*/, &varDecls /*BUFC*/)
        let res = tempDeclXml("modelica_boolean", &varDecls /*BUFC*/)
       match rel.operator
        case EQUAL(__) then
          <<
          <opt:ConstraintEqu>
            <%e1%>
            <%e2%>
          </opt:ConstraintEqu> <%\n%>
          >>
        case LESSEQ(__) then
          <<
          <opt:ConstraintLeq>
            <%e1%>
            <%e2%>
          </opt:ConstraintLeq> <%\n%>
          >>
        case GREATEREQ(__) then
          <<
          <opt:ConstraintGeq>
            <%e1%>
            <%e2%>
          </opt:ConstraintGeq> <%\n%>
          >>
        else
          <<
            "The XML schema does only support =, >= , <=  operators for constraints"
          >>
        end match
        end match
  end match
end match
end daeExpConstraintXml;

template daeExpIfXml(Exp exp, Context context, Text &preExp /*BUFP*/,
                  Text &varDecls /*BUFP*/)
 "Generates code for an if expression."
::=
match exp
case IFEXP(__) then
  let &preExpCond = buffer ""
  let condExp = daeExpXml(expCond, context, &preExpCond, &varDecls /*BUFD*/)
  let &resVar = buffer ""
  let &preExpThen = buffer ""
  let eThen = daeExpXml(expThen, context, &preExpThen, &varDecls /*BUFD*/)
  let &preExpElse = buffer ""
  let eElse = daeExpXml(expElse, context, &preExpElse, &varDecls /*BUFD*/)
  let &preExp +=
  <<
  <fun:If>
    <fun:Condition>
      <%condExp%>
    </fun:Condition>
    <fun:Statements>
      <%eThen%>
    </fun:Statements>
    <fun:Else>
      <%eElse%>
    </fun:Else>
  </fun:If>
  >>
  resVar
end daeExpIfXml;

template daeExpCallXml(Exp call, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/)
 "Generates code for a function call."
::=
  match call
  // special builtins
  case CALL(path=IDENT(name="DIVISION"),
            expLst={e1, e2, DAE.SCONST(string=string)}) then
    let var1 = daeExpXml(e1, context, &preExp, &varDecls)
    let var2 = daeExpXml(e2, context, &preExp, &varDecls)
    let var3 = Util.escapeModelicaStringToXmlString(string)
    <<
    <exp:Div>
      <%var1%>
      <%var2%>
    </exp:Div>
    >>
  case CALL(attr=CALL_ATTR(ty=ty),
            path=IDENT(name="DIVISION_ARRAY_SCALAR"),
            expLst={e1, e2, e3 as SHARED_LITERAL(__)}) then
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then "integer_array"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then "integer_array"
                        else "real_array"
    let var = tempDeclXml(type, &varDecls)
    let var1 = daeExpXml(e1, context, &preExp, &varDecls)
    let var2 = daeExpXml(e2, context, &preExp, &varDecls)
    let var3 = daeExpXml(e3, context, &preExp, &varDecls)
    let &preExp += 'division_alloc_<%type%>_scalar(&<%var1%>, <%var2%>, &<%var%>, <%var3%>);<%\n%>'
    '<%var%>'

  case exp as CALL(path=IDENT(name="DIVISION_ARRAY_SCALAR")) then
    error(sourceInfo(), 'Code generation does not support <%ExpressionDumpTpl.dumpExp(exp,"\"")%>')

  case CALL(path=IDENT(name="der"), expLst={arg as CREF(__)}) then
    <<
    <exp:Der>
      <%crefXml(arg.componentRef)%>
    </exp:Der>
    >>
  case CALL(path=IDENT(name="der"), expLst={exp}) then
    error(sourceInfo(), 'Code generation does not support der(<%ExpressionDumpTpl.dumpExp(exp,"\"")%>)')
  case CALL(path=IDENT(name="pre"), expLst={arg}) then
    daeExpCallPreXml(arg, context, preExp, varDecls)
// a $_start is used to get get start value of a variable
  case CALL(path=IDENT(name="$_start"), expLst={arg}) then
    daeExpCallPreXml(arg, context, preExp, varDecls)
  case CALL(path=IDENT(name="edge"), expLst={arg as CREF(__)}) then
    <<
    <%crefXml(arg.componentRef)%>
    >>
  case CALL(path=IDENT(name="edge"), expLst={exp}) then
    error(sourceInfo(), 'Code generation does not support edge(<%ExpressionDumpTpl.dumpExp(exp,"\"")%>)')
  case CALL(path=IDENT(name="change"), expLst={arg as CREF(__)}) then
    <<
    <%crefXml(arg.componentRef)%>
    >>
  case CALL(path=IDENT(name="change"), expLst={exp}) then
    error(sourceInfo(), 'Code generation does not support change(<%ExpressionDumpTpl.dumpExp(exp,"\"")%>)')

  case CALL(path=IDENT(name="print"), expLst={e1}) then
    let var1 = daeExpXml(e1, context, &preExp, &varDecls)
    if acceptMetaModelicaGrammar() then 'print(<%var1%>)' else 'puts(<%var1%>)'

  case CALL(path=IDENT(name="max"), attr=CALL_ATTR(ty = T_REAL(__)), expLst={e1,e2}) then
    let var1 = daeExpXml(e1, context, &preExp, &varDecls)
    let var2 = daeExpXml(e2, context, &preExp, &varDecls)
      <<
      <exp:Max>
        <%var1%>
        <%var2%>
      </exp:Max>
      >>

  case CALL(path=IDENT(name="max"), expLst={e1,e2}) then
    let var1 = daeExpXml(e1, context, &preExp, &varDecls)
    let var2 = daeExpXml(e2, context, &preExp, &varDecls)
      <<
      <exp:Max>
        <%var1%>
        <%var2%>
      </exp:Max>
      >>

  case CALL(path=IDENT(name="sum"), attr=CALL_ATTR(ty = ty), expLst={e}) then
    let arr = daeExpXml(e, context, &preExp, &varDecls)
    let ty_str = '<%expTypeArrayXml(ty)%>'
    'sum_<%ty_str%>(&<%arr%>)'

  case CALL(path=IDENT(name="min"), attr=CALL_ATTR(ty = T_REAL(__)), expLst={e1,e2}) then
    let var1 = daeExpXml(e1, context, &preExp, &varDecls)
    let var2 = daeExpXml(e2, context, &preExp, &varDecls)
      <<
      <exp:Min>
      <%var1%>
      <%var2%>
      </exp:Min>
      >>
  case CALL(path=IDENT(name="min"), expLst={e1,e2}) then
    let var1 = daeExpXml(e1, context, &preExp, &varDecls)
    let var2 = daeExpXml(e2, context, &preExp, &varDecls)
      <<
      <exp:Min>
        <%var1%>
        <%var2%>
      </exp:Min>
      >>

  case CALL(path=IDENT(name="abs"), expLst={e1}, attr=CALL_ATTR(ty = T_INTEGER(__))) then
    let var1 = daeExpXml(e1, context, &preExp, &varDecls)
      <<
      <exp:Abs>
        <%var1%>
      </exp:Abs>
      >>

  case CALL(path=IDENT(name="abs"), expLst={e1}) then
    let var1 = daeExpXml(e1, context, &preExp, &varDecls)
      <<
      <exp:Abs>
        <%var1%>
      </exp:Abs>
      >>

    //sqrt
  case CALL(path=IDENT(name="sqrt"), expLst={e1}, attr=attr as CALL_ATTR(__)) then
    let retPre = assertCommonXml(createAssertforSqrt(e1),createDAEString("Model error: Argument of sqrt should be >= 0"), context, &varDecls, dummyInfo)
    let argStr = daeExpXml(e1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let &preExp += '<%retPre%>'
      <<
      <exp:Sqrt>
        <%argStr%>
      </exp:Sqrt>
      >>

  case CALL(path=IDENT(name="div"), expLst={e1,e2}, attr=CALL_ATTR(ty = T_INTEGER(__))) then
    let var1 = daeExpXml(e1, context, &preExp, &varDecls)
    let var2 = daeExpXml(e2, context, &preExp, &varDecls)
      <<
      <exp:Div>
        <%var1%>
        <%var2%>
      </exp:Div>
      >>
  case CALL(path=IDENT(name="div"), expLst={e1,e2}) then
    let var1 = daeExpXml(e1, context, &preExp, &varDecls)
    let var2 = daeExpXml(e2, context, &preExp, &varDecls)
      <<
      <exp:Div>
        <%var1%>
        <%var2%>
      </exp:Div>
      >>

  case CALL(path=IDENT(name="mod"), expLst={e1,e2}, attr=CALL_ATTR(ty = ty)) then
    let var1 = daeExpXml(e1, context, &preExp, &varDecls)
    let var2 = daeExpXml(e2, context, &preExp, &varDecls)
    'modelica_mod_<%expTypeShortXml(ty)%>(<%var1%>,<%var2%>)'

  case CALL(path=IDENT(name="max"), attr=CALL_ATTR(ty = ty), expLst={array}) then
    let expVar = daeExpXml(array, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let arr_tp_str = '<%expTypeArrayXml(ty)%>'
    let tvar = tempDeclXml(expTypeModelicaXml(ty), &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = max_<%arr_tp_str%>(&<%expVar%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="min"), attr=CALL_ATTR(ty = ty), expLst={array}) then
    let expVar = daeExpXml(array, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let arr_tp_str = '<%expTypeArrayXml(ty)%>'
    let tvar = tempDeclXml(expTypeModelicaXml(ty), &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = min_<%arr_tp_str%>(&<%expVar%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="fill"), expLst=val::dims, attr=CALL_ATTR(ty = ty)) then
    let valExp = daeExpXml(val, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let dimsExp = (dims |> dim =>
      daeExpXml(dim, context, &preExp /*BUFC*/, &varDecls /*BUFD*/) ;separator=", ")
    let ty_str = '<%expTypeArrayXml(ty)%>'
    let tvar = tempDeclXml(ty_str, &varDecls /*BUFD*/)
    let &preExp += 'fill_alloc_<%ty_str%>(&<%tvar%>, <%valExp%>, <%listLength(dims)%>, <%dimsExp%>);<%\n%>'
    '<%tvar%>'

  case call as CALL(path=IDENT(name="vector")) then
    error(sourceInfo(),'vector() call does not have a C implementation <%ExpressionDumpTpl.dumpExp(call,"\"")%>')

  case CALL(path=IDENT(name="cat"), expLst=dim::arrays, attr=CALL_ATTR(ty = ty)) then
    let dim_exp = daeExpXml(dim, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let arrays_exp = (arrays |> array =>
      daeExpXml(array, context, &preExp /*BUFC*/, &varDecls /*BUFD*/) ;separator=", &")
    let ty_str = '<%expTypeArrayXml(ty)%>'
    let tvar = tempDeclXml(ty_str, &varDecls /*BUFD*/)
    let &preExp += 'cat_alloc_<%ty_str%>(<%dim_exp%>, &<%tvar%>, <%listLength(arrays)%>, &<%arrays_exp%>);<%\n%> where is cat2'
    '<%tvar%>'

  case CALL(path=IDENT(name="promote"), expLst={A, n}) then
    let var1 = daeExpXml(A, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let var2 = daeExpXml(n, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let arr_tp_str = '<%expTypeFromExpArrayXml(A)%>'
    let tvar = tempDeclXml(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += 'promote_alloc_<%arr_tp_str%>(&<%var1%>, <%var2%>, &<%tvar%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="transpose"), expLst={A}) then
    let var1 = daeExpXml(A, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let arr_tp_str = '<%expTypeFromExpArrayXml(A)%>'
    let tvar = tempDeclXml(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += 'transpose_alloc_<%arr_tp_str%>(&<%var1%>, &<%tvar%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="cross"), expLst={v1, v2}) then
    let var1 = daeExpXml(v1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let var2 = daeExpXml(v2, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let arr_tp_str = '<%expTypeFromExpArrayXml(v1)%>'
    let tvar = tempDeclXml(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += 'cross_alloc_<%arr_tp_str%>(&<%var1%>, &<%var2%>, &<%tvar%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="identity"), expLst={A}) then
    let var1 = daeExpXml(A, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let arr_tp_str = '<%expTypeFromExpArrayXml(A)%>'
    let tvar = tempDeclXml(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += 'identity_alloc_<%arr_tp_str%>(<%var1%>, &<%tvar%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="rem"), expLst={e1, e2}) then
    let var1 = daeExpXml(e1, context, &preExp, &varDecls)
    let var2 = daeExpXml(e2, context, &preExp, &varDecls)
    let typeStr = expTypeFromExpShortXml(e1)
    'modelica_rem_<%typeStr%>(<%var1%>,<%var2%>)'

/*
  case CALL(path=IDENT(name="String"), expLst={s, format}) then
    let tvar = tempDeclXml("modelica_string", &varDecls /*BUFD*/)
    let sExp = daeExpXml(s, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)

    let formatExp = daeExpXml(format, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let typeStr = expTypeFromExpModelicaXml(s)
    let &preExp += '<%tvar%> = <%typeStr%>_to_modelica_string_format(<%sExp%>, <%formatExp%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="String"), expLst={s, minlen, leftjust}) then
    let tvar = tempDeclXml("modelica_string", &varDecls /*BUFD*/)
    let sExp = daeExpXml(s, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let minlenExp = daeExpXml(minlen, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let leftjustExp = daeExpXml(leftjust, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let typeStr = expTypeFromExpModelicaXml(s)
    let &preExp += '<%tvar%> = <%typeStr%>_to_modelica_string(<%sExp%>, <%minlenExp%>, <%leftjustExp%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="String"), expLst={s, minlen, leftjust, signdig}) then
    let tvar = tempDeclXml("modelica_string", &varDecls /*BUFD*/)
    let sExp = daeExpXml(s, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let minlenExp = daeExpXml(minlen, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let leftjustExp = daeExpXml(leftjust, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let signdigExp = daeExpXml(signdig, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = modelica_real_to_modelica_string(<%sExp%>, <%minlenExp%>, <%leftjustExp%>, <%signdigExp%>);<%\n%>'
    '<%tvar%>'
*/

  case CALL(path=IDENT(name="delay"), expLst={ICONST(integer=index), e, d, delayMax}) then
    let var1 = daeExpXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let var2 = daeExpXml(d, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let var3 = daeExpXml(delayMax, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      <<
      <exp:Delay>
        <%var1%>
        <%var2%>
        <%var3%>
      </exp:Delay>
      >>
  case CALL(path=IDENT(name="integer"), expLst={toBeCasted}) then
    let castedVar = daeExpXml(toBeCasted, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    '<%castedVar%>'

  case CALL(path=IDENT(name="Integer"), expLst={toBeCasted}) then
    let castedVar = daeExpXml(toBeCasted, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    '<%castedVar%>'

  case CALL(path=IDENT(name="clock"), expLst={}) then
    'mmc_clock()'

  case CALL(path=IDENT(name="noEvent"), expLst={e1}) then
    daeExpXml(e1, context, &preExp, &varDecls)

  case CALL(path=IDENT(name="anyString"), expLst={e1}) then
    '<%daeExpXml(e1, context, &preExp, &varDecls)%>'

  case CALL(path=IDENT(name="mmc_get_field"), expLst={s1, ICONST(integer=i)}) then
    let tvar = tempDeclXml("modelica_metatype", &varDecls /*BUFD*/)
    let expPart = daeExpXml(s1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(<%expPart%>), <%i%>));<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name = "mmc_unbox_record"), expLst={s1}, attr=CALL_ATTR(ty=ty)) then
    <<
      "mmc_unbox_record" is not necessary
    >>

  case exp as CALL(attr=attr as CALL_ATTR(tailCall=tail as TAIL(__))) then
    let res = <<
    /* Tail recursive call <%ExpressionDumpTpl.dumpExp(exp,"\"")%> */
    <%daeExpTailCallXml(expLst,tail.vars,context,&preExp,&varDecls)%>goto _tailrecursive;
    /* TODO: Make sure any eventual dead code below is never generated */
    >>
    let &preExp += res
    ""

  case exp as CALL(attr=attr as CALL_ATTR(__)) then
    let &preExp = buffer "" /*BUFD*/
    let argStr = (expLst |> exp => '<%daeExpXml(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)%>' ;separator="\n")
    let result = if preExp then preExp else argStr
    //let builtinName ='<%dotPathXml(path)%>'
    let builtinFunctionName ='<%builtinFunctionNameXml(path)%>'
    let funName = '<%underscorePathXml(path)%>'
    let retType = if attr.builtin then (match attr.ty case T_NORETCALL(__) then ""
      else expTypeModelicaXml(attr.ty))
      else '<%funName%>'
    let retVar = match attr.ty
      case T_NORETCALL(__) then ""
      else tempDeclXml(retType, &varDecls)
    match exp
      // no return calls
      case CALL(attr=CALL_ATTR(ty=T_NORETCALL(__))) then '/* NORETCALL */'
     // non tuple calls (single return value)
      case CALL(attr=CALL_ATTR(tuple_=false)) then
        if attr.builtin then
          <<
          <exp:<%builtinFunctionName%>>
            <%result%>
          </exp:<%builtinFunctionName%>>
          >>
        else
          <<
          <exp:FunctionCall>
            <exp:Name>
              <%funName%>
            </exp:Name>
            <exp:Arguments>
              <%result%>
            </exp:Arguments>
          </exp:FunctionCall>
          >>
     // tuple calls (multiple return values)
      else
        <<
        <exp:FunctionCall>
          <exp:Name>
            <%funName%>
          </exp:Name>
          <exp:Arguments>
            <%result%>
          </exp:Arguments>
        </exp:FunctionCall>
        >>
end daeExpCallXml;

template builtinFunctionNameXml(Path path)
::=
  match path
  case IDENT(name="DIVISION") then 'Div'
  case IDENT(name="ADDITION") then 'Add'
  case IDENT(name="SUBTRACTION") then 'Sub'
  case IDENT(name="POWER") then 'Pow'
  case IDENT(name="sin") then 'Sin'
  case IDENT(name="cos") then 'Cos'
  case IDENT(name="tan") then 'Tan'
  case IDENT(name="asin") then 'Asin'
  case IDENT(name="acos") then 'Acos'
  case IDENT(name="atan") then 'Atan'
  case IDENT(name="sinh") then 'Sinh'
  case IDENT(name="cosh") then 'Cosh'
  case IDENT(name="tanh") then 'Tanh'
  case IDENT(name="exp") then 'Exp'
  case IDENT(name="log") then 'Log'
  case IDENT(name="log10") then 'Log10'
  case IDENT(name="sqrt") then 'Sqrt'
  case IDENT(name="atan2") then 'Atan2'
  case IDENT(name="abs") then 'Abs'
  case IDENT(name="sign") then 'Sign'
  case IDENT(name="min") then 'Min'
  case IDENT(name="max") then 'Max'
  case IDENT(name="noEvent") then 'NoEvent'
  case IDENT(name="array") then 'Array'
  case IDENT(name="sample") then 'Sample'
  case IDENT(name="smooth") then 'Smooth'
  case IDENT(name="homotopy") then 'Homotopy'
  else '<%dotPathXml(path)%>'
end builtinFunctionNameXml;

template daeExpTailCallXml(list<DAE.Exp> es, list<String> vs, Context context, Text &preExp, Text &varDecls)
::=
  match es
  case e::erest then
    match vs
    case v::vrest then
      let exp = daeExpXml(e,context,&preExp,&varDecls)
      match e
      case CREF(componentRef = cr, ty = T_FUNCTION_REFERENCE_VAR(__)) then
        // adrpo: ignore _x = _x!
        if stringEq(v, crefStrXml(cr))
        then '<%daeExpTailCallXml(erest, vrest, context, &preExp, &varDecls)%>'
        else '_<%v%> = <%exp%>;<%\n%><%daeExpTailCallXml(erest, vrest, context, &preExp, &varDecls)%>'
      case _ then
        '_<%v%> = <%exp%>;<%\n%><%daeExpTailCallXml(erest, vrest, context, &preExp, &varDecls)%>'
end daeExpTailCallXml;

template daeExpCallBuiltinPrefixXml(Boolean builtin)
 "Helper to daeExpCallXml."
::=
  match builtin
  case true  then ""
  case false then "_"
end daeExpCallBuiltinPrefixXml;

template daeExpArrayXml(Exp exp, Context context, Text &preExp /*BUFP*/,
                     Text &varDecls /*BUFP*/)
 "Generates code for an array expression."
::=
match exp
case ARRAY(__) then
  let params = (array |> e =>
     '<%daeExpXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)%>'
    ;separator="\n")
  let &preExp +=
    <<
    <exp:Array>
      <%params%>
    </exp:Array>
    >>
    params
end daeExpArrayXml;

template daeExpMatrixXml(Exp exp, Context context, Text &preExp /*BUFP*/,
                      Text &varDecls /*BUFP*/)
 "Generates code for a matrix expression."
::=
  match exp
  case MATRIX(matrix={{}})  // special case for empty matrix: create dimensional array Real[0,1]
  case MATRIX(matrix={})    // special case for empty array: create dimensional array Real[0,1]
    then ''
  case m as MATRIX(__) then
    let arrayTypeStr = expTypeArrayXml(m.ty)
    let &vars2 = buffer "" /*BUFD*/
    let &promote = buffer "" /*BUFD*/
    let catAlloc = (m.matrix |> row =>
        let tmp = tempDeclXml(arrayTypeStr, &varDecls /*BUFD*/)
        let vars = daeExpMatrixRowXml(row, arrayTypeStr, context,
                                 &promote /*BUFC*/, &varDecls /*BUFD*/)
        let &vars2 += ', &<%tmp%>'
        '';separator="\n")
    let &preExp += promote
    let &preExp += catAlloc
    let &preExp += "\n"
    let tmp = tempDeclXml(arrayTypeStr, &varDecls /*BUFD*/)
    let &preExp += ''
    tmp
end daeExpMatrixXml;

template daeExpMatrixRowXml(list<Exp> row, String arrayTypeStr,
                         Context context, Text &preExp /*BUFP*/,
                         Text &varDecls /*BUFP*/)
 "Helper to daeExpMatrixXML."
::=
  let &varLstStr = buffer "" /*BUFD*/

  let preExp2 = (row |> e =>
      let expVar = daeExpXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      let tmp = tempDeclXml(arrayTypeStr, &varDecls /*BUFD*/)
      let &varLstStr += ', &<%tmp%>'
       <<
       <%expVar%>
       >>
    ;separator="\n")
  let &preExp2 += "\n"
  let &preExp += preExp2
  varLstStr
end daeExpMatrixRowXml;

template daeExpRangeXml(Exp exp, Context context, Text &preExp /*BUFP*/,
                      Text &varDecls /*BUFP*/)
 "Generates XML code for a range expression."
::=
  match exp
  case RANGE(__) then
    let ty_str = expTypeArrayXml(ty)
    let start_exp = daeExpXml(start, context, &preExp, &varDecls)
    let stop_exp = daeExpXml(stop, context, &preExp, &varDecls)
    let tmp = tempDeclXml(ty_str, &varDecls)
    let step_exp = match step case SOME(stepExp) then daeExpXml(stepExp, context, &preExp, &varDecls) else "1"
    let &preExp +=
      <<
      <exp:Range>
        <%start_exp%>
        <%step_exp%>
        <%stop_exp%>
      </exp:Range><%\n%>
      >>
    '<%tmp%>'
end daeExpRangeXml;

template daeExpCastXml(Exp exp, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/)
 "Generates code for a cast expression."
::=
match exp
case CAST(__) then
  let expVar = daeExpXml(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
  match ty
  case T_INTEGER(__)   then '<%expVar%>'
  case T_REAL(__)  then '<%expVar%>'
  case T_ENUMERATION(__)   then '<%expVar%>'
  case T_BOOL(__)   then '<%expVar%>'
  case T_ARRAY(__) then
    let arrayTypeStr = expTypeArrayXml(ty)
    let tvar = tempDeclXml(arrayTypeStr, &varDecls /*BUFD*/)
    let to = expTypeShortXml(ty)
    let from = expTypeFromExpShortXml(exp)
    let &preExp += 'cast_<%from%>_array_to_<%to%>(&<%expVar%>, &<%tvar%>);<%\n%>'
    '<%tvar%>'
  else
    '<%expVar%> /* could not cast, using the variable as it is */'
end daeExpCastXml;


template daeExpAsubXml(Exp inExp, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/)
 "Generates XML code for an asub expression."
::=
  match expTypeFromExpShortXml(inExp)
  case "metatype" then
  // MetaModelica Array
    (match inExp case ASUB(exp=e, sub={idx}) then
      let e1 = daeExpXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      let idx1 = daeExpXml(idx, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
      'arrayGet(<%e1%>,<%idx1%>) /* DAE.ASUB */')
  // Modelica Array
  else
  match inExp

  case ASUB(exp=ASUB(__)) then
    error(sourceInfo(),'Nested array subscripting *should* have been handled by the routine creating the asub, but for some reason it was not: <%ExpressionDumpTpl.dumpExp(exp,"\"")%>')

  // Faster asub: Do not construct a whole new array just to access one subscript
  case ASUB(exp=exp as ARRAY(scalar=true), sub={idx}) then
    let res = tempDeclXml(expTypeFromExpModelicaXml(exp),&varDecls) +' asub tmp test'
    let idx1 = daeExpXml(idx, context, &preExp, &varDecls)
    let expl = (exp.array |> e hasindex i1 fromindex 1 =>
      let &caseVarDecls = buffer ""
      let &casePreExp = buffer ""
      let v = daeExpXml(e, context, &casePreExp, &caseVarDecls)
      <<
      case <%i1%>: {
        <%&caseVarDecls%>
        <%&casePreExp%>
        <%res%> = <%v%>;
        break;
      }
      >> ; separator = "\n")
    let &preExp +=
    <<
    switch (<%idx1%>) { /* ASUB */
    <%expl%>
    default:
      assert(NULL == "index out of bounds");
    }
    >>
    res

  case ASUB(exp=RANGE(ty=t), sub={idx}) then
    error(sourceInfo(),'ASUB_EASY_CASE <%ExpressionDumpTpl.dumpExp(exp,"\"")%>')

  case ASUB(exp=ecr as CREF(__), sub=subs) then
    let arrName = daeExpCrefRhsXml(buildCrefExpFromAsub(ecr, subs), context,
                              &preExp /*BUFC*/, &varDecls /*BUFD*/)
    match context case FUNCTION_CONTEXT(__)  then
      arrName
    else
      arrayScalarRhsXml(ecr.ty, subs, arrName, context, &preExp, &varDecls) + 'Asub array scalar RHS'

  case ASUB(exp=e, sub=indexes) then
    let exp = daeExpXml(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    '<%exp%>'

  case exp then
    error(sourceInfo(),'OTHER_ASUB <%ExpressionDumpTpl.dumpExp(exp,"\"")%>')
end daeExpAsubXml;

template daeExpASubIndexXml(Exp exp, Context context, Text &preExp, Text &varDecls)
::=
match exp
  case ICONST(__) then incrementInt(integer,-1)
  case ENUM_LITERAL(__) then incrementInt(index,-1)
  else daeExpXml(exp,context,&preExp,&varDecls)
end daeExpASubIndexXml;

template daeExpCallPreXml(Exp exp, Context context, Text &preExp /*BUFP*/,
                       Text &varDecls /*BUFP*/)
  "Generates code for an asub of a cref, which becomes cref + offset."
::=
  match exp
  case cr as CREF(__) then
  <<
  <exp:Pre>
    <%crefXml(cr.componentRef)%>
  </exp:Pre>
  >>
  case ASUB(exp = cr as CREF(__), sub = {sub_exp}) then
  <<
   "case ASUB(exp = cr as CREF(__), sub = {sub_exp}) is not yet implemented"
  >>
  else
    error(sourceInfo(), 'Code generation does not support pre(<%ExpressionDumpTpl.dumpExp(exp,"\"")%>)')
end daeExpCallPreXml;

template daeExpSizeXml(Exp exp, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/)
 "Generates XML code for a size expression."
::=
  match exp
  case SIZE(exp=CREF(__), sz=SOME(dim)) then
    let expPart = daeExpXml(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    let dimPart = daeExpXml(dim, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)
    <<
    <exp:Size>
      <%expPart%>
      <%dimPart%>
    </exp:Size>
    >>
  else "size(X) not implemented"
end daeExpSizeXml;

template daeExpBoxXml(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates XML code for a match expression box."
::=
match exp
case exp as BOX(__) then
  let res = daeExpXml(exp.exp,context,&preExp,&varDecls)
    <<
    <%res%>
    >>
end daeExpBoxXml;

template daeExpUnboxXml(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates XML code for a match expression unbox."
::=
match exp
case exp as UNBOX(__) then
  let res = daeExpXml(exp.exp,context,&preExp,&varDecls)
    <<
    <%res%>
    >>
end daeExpUnboxXml;

template daeExpSharedLiteralXml(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Generates code for a match expression."
::=
match exp case exp as SHARED_LITERAL(__) then ''
end daeExpSharedLiteralXml;

// TODO: Optimize as in Codegen
// TODO: Use this function in other places where almost the same thing is hard
//       coded
template arrayScalarRhsXml(Type ty, list<Exp> subs, String arrName, Context context,
               Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/)
 "Helper to daeExpAsub."
::=
  let arrayType = expTypeArrayXml(ty)
  let dimsLenStr = listLength(subs)
  let dimsValuesStr = (subs |> exp =>
      daeExpXml(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/)

    ;separator=", ")
  match arrayType
    case "metatype_array" then
      'arrayGet(<%arrName%>,<%dimsValuesStr%>) /*arrayScalarRhs*/'
    else
      << wrong LHS
          <exp:ArraySubscripts>
            <exp:IndexExpression>
              <%dimsValuesStr%>
            </exp:IndexExpression>
          </exp:ArraySubscripts>
        </exp:QualifiedNamepart>
      </exp:QualifiedName>
      >>
end arrayScalarRhsXml;


/*****************************************************************************
 *         SECTION:
 *****************************************************************************/

template outDeclXml(String ty, Text &varDecls /*BUFP*/)
 "Declares a temporary variable in varDecls and returns the name."
::=
  let newVar = 'out'
  let &varDecls += '<%ty%> <%newVar%>;<%\n%>'
  newVar
end outDeclXml;

template tempDeclXml(String ty, Text &varDecls /*BUFP*/)
 "Declares a temporary variable in varDecls and returns the name."
::=
  let newVar
         =
    match ty /* TODO! FIXME! UGLY! UGLY! hack! */
      case "modelica_metatype"
      case "metamodelica_string"
      case "metamodelica_string_const"
        then 'tmpMeta[<%System.tmpTickIndex(1)%>]'
      else
        let newVarIx = 'tmp<%System.tmpTick()%>'
        let &varDecls += '<%ty%> <%newVarIx%>;<%\n%>'
        newVarIx
  newVar
end tempDeclXml;

template tempDeclConstXml(String ty, String val, Text &varDecls /*BUFP*/)
 "Declares a temporary variable in varDecls and returns the name."
::=
  let newVar = 'tmp<%System.tmpTick()%>'
  let &varDecls += '<%ty%> <%newVar%> = <%val%>;<%\n%>'
  newVar
end tempDeclConstXml;

template varTypeXml(Variable var)
 "Generates type for a variable."
::=
match var
case var as VARIABLE(__) then
  if instDims then
    expTypeArrayXml(var.ty)
  else
    expTypeArrayIfXml(var.ty)
end varTypeXml;

template varTypeBoxedXml(Variable var)
::=
  match var
  case VARIABLE(__) then 'modelica_metatype'
  case FUNCTION_PTR(__) then 'modelica_fnptr'
end varTypeBoxedXml;

template expTypeRWXml(DAE.Type type)
 "Helper to writeOutVarRecordMembers."
::=
  match type
  case T_INTEGER(__)         then "TYPE_DESC_INT"
  case T_REAL(__)        then "TYPE_DESC_REAL"
  case T_STRING(__)      then "TYPE_DESC_STRING"
  case T_BOOL(__)        then "TYPE_DESC_BOOL"
  case T_ENUMERATION(__) then "TYPE_DESC_INT"
  case T_ARRAY(__)       then '<%expTypeRWXml(ty)%>_ARRAY'
  case T_COMPLEX(complexClassType=RECORD(__))
                      then "TYPE_DESC_RECORD"
  case T_METATYPE(__) case T_METABOXED(__)    then "TYPE_DESC_MMC"
end expTypeRWXml;

template expTypeShortXml(DAE.Type type)
 "Generate type helper."
::=
  match type
  case T_INTEGER(__)     then "Integer"
  case T_REAL(__)        then "Real"
  case T_STRING(__)      then if acceptMetaModelicaGrammar() then "MetaType" else "String"
  case T_BOOL(__)        then "Boolean"
  case T_ENUMERATION(__) then "Integer"
  case T_ARRAY(__)       then expTypeShortXml(ty)
  case T_COMPLEX(complexClassType=EXTERNAL_OBJ(__))
                      then "Complex"
  case T_COMPLEX(__)     then '<%underscorePathXml(ClassInf.getStateName(complexClassType))%>'
  case T_METATYPE(__) case T_METABOXED(__)    then "MetaType"
  case T_FUNCTION_REFERENCE_VAR(__) then "fnptr"
  case T_UNKNOWN(__) then "Complex" /* TODO: Don't do this to me! */
  case T_ANYTYPE(__) then "Complex" /* TODO: Don't do this to me! */
  else error(sourceInfo(),'expTypeShortXml:<%unparseType(type)%>')
end expTypeShortXml;

template expTypeXml(DAE.Type ty, Boolean array)
 "Generate type helper."
::=
  match array
  case true  then expTypeArrayXml(ty)
  case false then expTypeModelicaXml(ty)
end expTypeXml;

template expTypeModelicaXml(DAE.Type ty)
 "Generate type helper."
::=
  expTypeFlagXml(ty, 2)
end expTypeModelicaXml;

template expTypeArrayXml(DAE.Type ty)
 "Generate type helper."
::=
  expTypeFlagXml(ty, 3)
end expTypeArrayXml;

template expTypeArrayIfXml(DAE.Type ty)
 "Generate type helper."
::=
  expTypeFlagXml(ty, 4)
end expTypeArrayIfXml;

template expTypeFromExpShortXml(Exp exp)
 "Generate type helper."
::=
  expTypeFromExpFlagXml(exp, 1)
end expTypeFromExpShortXml;

template expTypeFromExpModelicaXml(Exp exp)
 "Generate type helper."
::=
  expTypeFromExpFlagXml(exp, 2)
end expTypeFromExpModelicaXml;

template expTypeFromExpArrayXml(Exp exp)
 "Generate type helper."
::=
  expTypeFromExpFlagXml(exp, 3)
end expTypeFromExpArrayXml;

template expTypeFromExpArrayIfXml(Exp exp)
 "Generate type helper."
::=
  expTypeFromExpFlagXml(exp, 4)
end expTypeFromExpArrayIfXml;

template expTypeFlagXml(DAE.Type ty, Integer flag)
 "Generate type helper."
::=
  match flag
  case 1 then
    // we want the short type
    expTypeShortXml(ty)
  case 2 then
    // we want the "modelica type"
    match ty case T_COMPLEX(complexClassType=EXTERNAL_OBJ(__)) then
      '<%expTypeShortXml(ty)%>'
    else match ty case T_COMPLEX(__) then '<%underscorePathXml(ClassInf.getStateName(complexClassType))%>'
    else
      '<%expTypeShortXml(ty)%>'
  case 3 then
    // we want the "array type"
    '<%expTypeShortXml(ty)%>'
  case 4 then
    // we want the "array type" only if type is array, otherwise "modelica type"
    match ty
    case T_ARRAY(__) then '<%expTypeShortXml(ty)%>'
    else expTypeFlagXml(ty, 2)
end expTypeFlagXml;

template expTypeFromExpFlagXml(Exp exp, Integer flag)
 "Generate type helper."
::=
  match exp
  case ICONST(__)        then match flag case 8 then "int" case 1 then "integer" else "modelica_integer"
  case RCONST(__)        then match flag case 1 then "real" else "modelica_real"
  case SCONST(__)        then if acceptMetaModelicaGrammar() then
                                (match flag case 1 then "metatype" else "modelica_metatype")
                              else
                                (match flag case 1 then "string" else "modelica_string")
  case BCONST(__)        then match flag case 1 then "boolean" else "modelica_boolean"
  case ENUM_LITERAL(__)  then match flag case 8 then "int" case 1 then "integer" else "modelica_integer"
  case e as BINARY(__)
  case e as UNARY(__)
  case e as LBINARY(__)
  case e as LUNARY(__)
  case e as RELATION(__) then expTypeFromOpFlagXml(e.operator, flag)
  case IFEXP(__)         then expTypeFromExpFlagXml(expThen, flag)
  case CALL(attr=CALL_ATTR(__)) then expTypeFlagXml(attr.ty, flag)
  case c as ARRAY(__)
  case c as MATRIX(__)
  case c as RANGE(__)
  case c as CAST(__)
  case c as CREF(__)
  case c as CODE(__)     then expTypeFlagXml(c.ty, flag)
  case c as ASUB(__)     then expTypeFlagXml(typeof(c), flag)
  case REDUCTION(__)     then expTypeFlagXml(typeof(exp), flag)
  case BOX(__)
  case CONS(__)
  case LIST(__)
  case SIZE(__)          then expTypeFlagXml(typeof(exp), flag)

  case META_TUPLE(__)
  case META_OPTION(__)
  case MATCHEXPRESSION(__)
  case METARECORDCALL(__)
  case BOX(__)           then match flag case 1 then "metatype" else "modelica_metatype"
  case c as UNBOX(__)    then expTypeFlagXml(c.ty, flag)
  case c as SHARED_LITERAL(__) then expTypeFromExpFlagXml(c.exp, flag)
  else error(sourceInfo(), 'expTypeFromExpFlag:<%ExpressionDumpTpl.dumpExp(exp,"\"")%>')
end expTypeFromExpFlagXml;

template expTypeFromOpFlagXml(Operator op, Integer flag)
 "Generate type helper."
::=
  match op
  case o as ADD(__)
  case o as SUB(__)
  case o as MUL(__)
  case o as DIV(__)
  case o as POW(__)

  case o as UMINUS(__)
  case o as UMINUS_ARR(__)
  case o as ADD_ARR(__)
  case o as SUB_ARR(__)
  case o as MUL_ARR(__)
  case o as DIV_ARR(__)
  case o as MUL_ARRAY_SCALAR(__)
  case o as ADD_ARRAY_SCALAR(__)
  case o as SUB_SCALAR_ARRAY(__)
  case o as MUL_SCALAR_PRODUCT(__)
  case o as MUL_MATRIX_PRODUCT(__)
  case o as DIV_ARRAY_SCALAR(__)
  case o as DIV_SCALAR_ARRAY(__)
  case o as POW_ARRAY_SCALAR(__)
  case o as POW_SCALAR_ARRAY(__)
  case o as POW_ARR(__)
  case o as POW_ARR2(__)
  case o as LESS(__)
  case o as LESSEQ(__)
  case o as GREATER(__)
  case o as GREATEREQ(__)
  case o as EQUAL(__)
  case o as NEQUAL(__) then
    expTypeFlagXml(o.ty, flag)
  case o as AND(__)
  case o as OR(__)
  case o as NOT(__) then
    match flag case 1 then "boolean" else "modelica_boolean"
  else "expTypeFromOpFlag:ERROR"
end expTypeFromOpFlagXml;

template dimensionXml(Dimension d)
::=
  match d
  case DAE.DIM_INTEGER(__) then integer
  case DAE.DIM_ENUM(__) then size
  case DAE.DIM_UNKNOWN(__) then ":"
  else "INVALID_DIMENSION"
end dimensionXml;

template assertCommonXml(Exp condition, Exp message, Context context, Text &varDecls, builtin.SourceInfo info)
::=
  let &preExpCond = buffer ""
  let &preExpMsg = buffer ""
  let condVar = daeExpXml(condition, context, &preExpCond, &varDecls)
  let msgVar = daeExpXml(message, context, &preExpMsg, &varDecls)
  <<
  <fun:Assertion>
    <fun:Condition>
      <%condVar%>
    </fun:Condition>
    <fun:Message>
      <%msgVar%>
    </fun:Message>
  </fun:Assertion>
  >>
end assertCommonXml;

template error(builtin.SourceInfo srcInfo, String errMessage)
"Example source template error reporting template to be used together with the sourceInfo() magic function.
Usage: error(sourceInfo(), <<message>>) "
::=
let() = Tpl.addSourceTemplateError(errMessage, srcInfo)
<<

#error "<% Error.infoStr(srcInfo) %> <% errMessage %>"<%\n%>
>>
end error;

annotation(__OpenModelica_Interface="backend");
end CodegenXML;
// vim: filetype=susan sw=2 sts=2
