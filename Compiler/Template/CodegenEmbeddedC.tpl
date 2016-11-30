// This file defines templates for transforming Modelica code to embeddedC
// code. They are used in the code generator phase of the compiler to write
// target code.
//
// There are two root templates intended to be called from the code generator:
// translateModel and translateFunctions. These templates do not return any
// result but instead write the result to files. All other templates return
// text and are used by the root templates (most of them indirectly).
//
// To future maintainers of this file:
//
// - A line like this
//     # var = ""
//   declares a text buffer that you can later append text to. It can also be
//   passed to other templates that in turn can append text to it. In the new
//   version of Susan it should be written like this instead:
//     let &var = buffer ""
//
// - A line like this
//     ..., Text var, ...
//   declares that a template takes a tmext buffer as input parameter. In the
//   new version of Susan it should be written like this instead:
//     ..., Text &var, ...
//
// - A line like this:
//     ..., var, ...
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

package CodegenEmbeddedC

import interface SimCodeTV;
import interface SimCodeBackendTV;

import CodegenUtil.*;
import ExpressionDumpTpl;
import DAEDumpTpl;

template mainFile(SimCode simCode)
::=
let modelNamePrefixStr = modelNamePrefix(simCode)
match simCode
case simCode as SIMCODE(simulationSettingsOpt=NONE()) then
  error(sourceInfo(), "Missing simulation settings")
case simCode as SIMCODE(modelInfo=MODELINFO(functions=functions, varInfo=varInfo as VARINFO(__), vars=vars as SIMVARS(__)),
                        extObjInfo=extObjInfo as EXTOBJINFO(vars=extObjVars),
                        simulationSettingsOpt=SOME(settings as SIMULATION_SETTINGS(__))) then
<<
#define fmi2TypesPlatform_h

#define fmi2TypesPlatform "default" /* Compatible */

typedef struct <%symbolName(modelNamePrefixStr,"fmi2Component_s")%>* fmi2Component;
typedef void* fmi2ComponentEnvironment;    /* Pointer to FMU environment    */
typedef void* fmi2FMUstate;                /* Pointer to internal FMU state */
typedef unsigned int fmi2ValueReference;
typedef double fmi2Real;
typedef int fmi2Integer;
typedef int fmi2Boolean;
typedef char fmi2Char;
typedef const fmi2Char* fmi2String;
typedef char fmi2Byte;

#define fmi2True 1
#define fmi2False 0

#include "fmi2/fmi2Functions.h"

#include <stdint.h>
#include <stdio.h>

void ModelicaFormatMessage(const char *fmt, ...)
{
  va_list args;
  va_start(args, fmt);
  vprintf(fmt, args);
  va_end(args);
}

typedef struct <%symbolName(modelNamePrefixStr,"fmi2Component_s")%> {
  fmi2Real currentTime;
  <% match nVariablesReal(varInfo)
    case 0 then ""
    case n then 'fmi2Real fmi2RealVars[<%n%>];<%\n%>'
  %><% match varInfo.numIntAlgVars
    case 0 then ""
    case n then 'fmi2Integer fmi2IntegerVars[<%n%>];<%\n%>'
  %><% match varInfo.numBoolAlgVars
    case 0 then ""
    case n then 'fmi2Boolean fmi2BooleanVars[<%n%>];<%\n%>'
  %><% match varInfo.numStringAlgVars
    case 0 then ""
    else error(sourceInfo(), "String variables not supported yet")
  %><% match varInfo.numParams
    case 0 then ""
    case n then 'fmi2Real fmi2RealParameter[<%n%>];<%\n%>'
  %><% match varInfo.numIntParams
    case 0 then ""
    case n then 'fmi2Integer fmi2IntegerParameter[<%n%>];<%\n%>'
  %><% match varInfo.numBoolParams
    case 0 then ""
    case n then 'fmi2Boolean fmi2BooleanParameter[<%n%>];<%\n%>'
  %><% match varInfo.numIntParams
    case 0 then ""
    case n then 'fmi2String fmi2StringParameter[<%n%>];<%\n%>'
  %><% match listLength(extObjVars)
    case 0 then ""
    case n then 'void* extObjs[<%n%>];<%\n%>'
  %>
} <%symbolName(modelNamePrefixStr,"fmi2Component")%>;

<%symbolName(modelNamePrefixStr,"fmi2Component")%> <%symbolName(modelNamePrefixStr,"component")%> = {
  <% match nVariablesReal(varInfo)
    case 0 then ""
    else
    <<
    .fmi2RealVars = {
      <%vars.stateVars |> var => startValue(var) %>
      <%vars.derivativeVars |> var => startValue(var) %>
      <%vars.algVars |> var => startValue(var) %>
      <%vars.discreteAlgVars |> var => startValue(var) %>
      <%vars.realOptimizeConstraintsVars |> var => startValue(var) %>
      <%vars.realOptimizeFinalConstraintsVars |> var => startValue(var) %>
    },<%\n%>
    >>
  %><% match varInfo.numIntAlgVars
    case 0 then ""
    else
    <<
    .fmi2IntegerVars = {
      <%vars.intAlgVars |> var => startValue(var) %>
    },<%\n%>
    >>
  %><% match varInfo.numBoolAlgVars
    case 0 then ""
    else
    <<
    .fmi2BooleanVars = {
      <%vars.boolAlgVars |> var => startValue(var) %>
    },<%\n%>
    >>
  %><% match varInfo.numStringAlgVars
    case 0 then ""
    else
    <<
    .fmi2StringVars = {
      <%vars.stringAlgVars |> var => startValue(var) %>
    },<%\n%>
    >>
  %><% match varInfo.numParams
    case 0 then ""
    else
    <<
    .fmi2RealParameter = {
      <%vars.paramVars |> var => startValue(var) %>
    },<%\n%>
    >>
  %><% match varInfo.numIntParams
    case 0 then ""
    else
    <<
    .fmi2IntegerParameter = {
      <%vars.intParamVars |> var => startValue(var) %>
    },<%\n%>
    >>
  %><% match varInfo.numBoolParams
    case 0 then ""
    else
    <<
    .fmi2BooleanParameter = {
      <%vars.boolParamVars |> var => startValue(var) %>
    },<%\n%>
    >>
  %><% match varInfo.numStringParamVars
    case 0 then ""
    else
    <<
    .fmi2StringParameter = {
      <%vars.stringParamVars |> var => startValue(var) %>
    },<%\n%>
    >>
  %>
};

#include <math.h>
/* TODO: Generate used builtin functions before SimCode */
static inline double om_mod(double x, double y)
{
  return x-floor(x/y)*y;
}

<%functionsFile(functions, literals, externalFunctionIncludes)%>

fmi2Component <%symbolName(modelNamePrefixStr,"fmi2Instantiate")%>(fmi2String name, fmi2Type ty, fmi2String GUID, fmi2String resources, const fmi2CallbackFunctions* functions, fmi2Boolean visible, fmi2Boolean loggingOn)
{
  static int initDone=0;
  if (initDone) {
    return NULL;
  }
  return &<%symbolName(modelNamePrefixStr,"component")%>;
}

fmi2Status <%symbolName(modelNamePrefixStr,"fmi2SetupExperiment")%>(fmi2Component comp, fmi2Boolean toleranceDefined, fmi2Real tolerance, fmi2Real startTime, fmi2Boolean stopTimeDefined, fmi2Real stopTime)
{
  return fmi2OK;
}

fmi2Status <%symbolName(modelNamePrefixStr,"fmi2EnterInitializationMode")%>(fmi2Component comp)
{
  <%callExternalObjectConstructors(extObjInfo)%>
  return fmi2OK;
}

fmi2Status <%symbolName(modelNamePrefixStr,"fmi2ExitInitializationMode")%>(fmi2Component comp)
{
  return fmi2OK;
}

static fmi2Status <%symbolName(modelNamePrefixStr,"functionODE")%>(fmi2Component comp)
{
  <% match odeEquations
  case {} then ""
  case {eqs} then (eqs |> eq => equation_(eq); separator="\n")
  else error(sourceInfo(), "TODO") // List.flatten(odeEquations) |> eq => equation_(eq); separator="\n"
  %>
}

static fmi2Status <%symbolName(modelNamePrefixStr,"functionOutputs")%>(fmi2Component comp)
{
  <% match allEquations
  case {} then ""
  case {eqs} then (eqs |> eq => equation_(eq); separator="\n")
  else (allEquations |> eqs => (eqs |> eq => equation_(eq); separator="\n"); separator="\n")
  %>
}

fmi2Status <%symbolName(modelNamePrefixStr,"fmi2DoStep")%>(fmi2Component comp, fmi2Real currentCommunicationPoint, fmi2Real communicationStepSize, fmi2Boolean noSetFMUStatePriorToCurrentPoint)
{
  comp->currentTime = currentCommunicationPoint;
  <%match varInfo.numStateVars
  case 0 then ""
  else
  <<
  int i=0;
  for (i=0; i<<%varInfo.numStateVars%>; i++) {
    comp->fmi2RealVars[i] += comp->fmi2RealVars[i+<%varInfo.numStateVars%>]*communicationStepSize;
  }
  >>
  %>
  /* TODO: Calculate time/state-dependent variables here... */
  <%symbolName(modelNamePrefixStr,"functionOutputs")%>(comp);
  return fmi2OK;
}

int main(int argc, char **argv)
{
  int terminateSimulation = 0;
  fmi2Status status = fmi2OK;
  fmi2CallbackFunctions cbf = {
  .logger = NULL,
  .allocateMemory = NULL /*calloc*/,
  .freeMemory = NULL /*free*/,
  .stepFinished = NULL, //synchronous execution
  .componentEnvironment = NULL
  };

  fmi2Component comp = <%symbolName(modelNamePrefixStr,"fmi2Instantiate")%>("", fmi2CoSimulation, "", "", &cbf, fmi2False, fmi2False);
  if (comp==NULL) {
    return 1;
  }
  <%symbolName(modelNamePrefixStr,"fmi2SetupExperiment")%>(comp, fmi2False, 0.0, <%settings.startTime%>, fmi2False, <%settings.stopTime%>);
  <%symbolName(modelNamePrefixStr,"fmi2EnterInitializationMode")%>(comp);
  // Set start-values? Nah...
  <%symbolName(modelNamePrefixStr,"fmi2ExitInitializationMode")%>(comp);

  double currentTime = <%settings.startTime%>;
  double h = <%settings.stepSize%>;
  uint32_t i = 0;

  while (status == fmi2OK) {
    //retrieve outputs
      // fmi2GetReal(m, ..., 1, &y1);
    //set inputs
      // fmi2SetReal(m, ..., 1, &y2);

    //call slave and check status
    status = <%symbolName(modelNamePrefixStr,"fmi2DoStep")%>(comp, currentTime, h, fmi2True);
    switch (status) {
      case fmi2Discard:
      case fmi2Error:
      case fmi2Fatal:
      case fmi2Pending /* Cannot happen */:
        terminateSimulation = 1;
        break;
      case fmi2OK:
      case fmi2Warning:
        break;
    }
    if (terminateSimulation) {
      break;
    }
    i++;
    /* increment master time */
    currentTime = <%settings.startTime%> + h*i;
  }

#if 0
  if ((status != fmi2Error) && (status != fmi2Fatal)) {
    fmi2Terminate(m);
  }
  if (status != fmi2Fatal) {
    fmi2FreeInstance(m);
  }
#endif
}

>>
end mainFile;

template equation_(SimEqSystem eq)
::=
  match eq
  case SES_SIMPLE_ASSIGN(__) then
    <<
    <%cref(cref)%> = <%daeExp(exp)%>; /* equation <%index%> */
    >>
  case SES_ALGORITHM(__) then
    (statements |> stmt => statement(stmt) ; separator="\n")
  else error(sourceInfo(), 'Unsupported equation: ...')
end equation_;

template statement(Statement stmt)
::=
  match stmt
  case STMT_ASSIGN(type_=T_ARRAY(__))
    then error(sourceInfo(), "Array assignments are not supported")
  case STMT_ASSIGN(exp1=CREF(componentRef=cr))
    then '<%cref(cr)%> = <%daeExp(exp)%>;'
  case STMT_NORETCALL(__)
    then '<%daeExp(exp)%>;'
  case STMT_IF(__) then
    <<
    if (<%daeExp(exp)%>) {
      <%statementLst |> stmt => statement(stmt) ; separator="\n"%>
    }<%elseStatement(else_)%>
    >>
  else error(sourceInfo(), 'Unsupported statement: <%DAEDumpTpl.dumpStatement(stmt)%>')
end statement;

template elseStatement(Else else_)
::=
  match else_
  case NOELSE(__) then ""
  case ELSEIF(__) then
    <<
    else if (<%daeExp(exp)%>) {
      <%statementLst |> stmt => statement(stmt) ; separator="\n"%>
    }<%elseStatement(else_)%>
    >>
  case ELSE(__) then
    <<
    else {
      <%statementLst |> stmt => statement(stmt) ; separator="\n"%>
    }
    >>
end elseStatement;

template cref(ComponentRef cr)
 "Generates C equivalent name for component reference.
  used in Compiler/Template/CodegenFMU.tpl"
::=
  match cr
  case CREF_IDENT(ident = "time") then "comp->currentTime"
  case WILD(__) then ''
  else crefToCStr(cr, 0, false)
end cref;

template crefLocal(ComponentRef cr)
 "Generates C equivalent name for component reference.
  used in Compiler/Template/CodegenFMU.tpl"
::=
  match cr
  case CREF_IDENT(__) then "om_"+ident
  else error(sourceInfo(), "Only CREF_IDENT as local identifiers (for now)")
end crefLocal;

template crefToCStr(ComponentRef cr, Integer ix, Boolean isPre)
 "Helper function to cref."
::=
  match cr
  case CREF_QUAL(ident="$PRE", subscriptLst={}) then
    (if isPre then error(sourceInfo(), 'Got $PRE for something that is already pre: <%crefStr(cr)%>')
    else crefToCStr(componentRef, ix, true))
  else match cref2simvar(cr, getSimCode())
  case var as SIMVAR(index=-1) then error(sourceInfo(), 'crefToCStr got index=-1 for <%variabilityString(varKind)%> <%crefStr(name)%>')
  case var as SIMVAR(__) then '<%varArrayNameValues(var, ix, isPre)%>[<%index%>] /* <%Util.escapeModelicaStringToCString(crefStr(name))%> <%variabilityString(varKind)%> */'
  else "CREF_NOT_IDENT_OR_QUAL"
end crefToCStr;

template crefShortType(ComponentRef cr) "template crefType
  Like cref but with cast if type is integer."
::=
  match cr
  case CREF_IDENT(__) then expTypeShort(identType)
  case CREF_QUAL(__)  then crefShortType(componentRef)
  else "crefType:ERROR"
  end match
end crefShortType;

template expTypeShort(DAE.Type type)
 "Generate type helper."
::=
  match type
  case T_INTEGER(__)       then "fmi2Integer"
  case T_REAL(__)          then "fmi2Real"
  case T_STRING(__)        then "fmi2String"
  case T_BOOL(__)          then "fmi2Boolean"
  case T_ENUMERATION(__)   then "fmi2Integer"
  case T_SUBTYPE_BASIC(__) then expTypeShort(complexType)
  case T_ARRAY(__)         then expTypeShort(ty)
  case T_COMPLEX(complexClassType=EXTERNAL_OBJ(__)) then "void*"
  else error(sourceInfo(),'expTypeShort: <%unparseType(type)%>')
end expTypeShort;

template daeExp(Exp exp)
::=
  match exp
  case ICONST(__) then integer
  case RCONST(__) then real
  case SCONST(__) then '"<%Util.escapeModelicaStringToCString(string)%>"'
  case BCONST(__) then (if bool then "fmi2True" else "fmi2False")
  case ENUM_LITERAL(__) then index
  case LUNARY(operator=NOT(__)) then '!(<%daeExp(exp)%>)'
  case UNARY(operator=UMINUS(__)) then '-(<%daeExp(exp)%>)'
  case BINARY(__) then daeExpBinary(exp1,operator,exp2,exp)
  case RELATION(__) then daeExpBinary(exp1,operator,exp2,exp)
  case IFEXP(__) then '(<%daeExp(expCond)%>) ? (<%daeExp(expThen)%>) : (<%daeExp(expElse)%>)'
  case CALL(attr=CALL_ATTR(builtin=true)) then daeExpCallBuiltin(exp)
  case CALL(__) then daeExpCall(exp)
  case CREF(ty=T_ARRAY(__)) then error(sourceInfo(), 'CREF array... <%ExpressionDumpTpl.dumpExp(exp,"\"")%>')
  case CREF(__) then cref(componentRef)
  case CAST(ty=T_REAL(__), exp=e) then daeExp(e)
  else error(sourceInfo(), 'daeExp: Not supporting <%ExpressionDumpTpl.dumpExp(exp,"\"")%>')
end daeExp;

template daeExpBinary(Exp exp1, Operator op, Exp exp2, Exp origExp)
::=
  match op
  case ADD(__) then '(<%daeExp(exp1)%>)+(<%daeExp(exp2)%>)'
  case SUB(__) then '(<%daeExp(exp1)%>)-(<%daeExp(exp2)%>)'
  case MUL(__) then '(<%daeExp(exp1)%>)*(<%daeExp(exp2)%>)'

  case GREATER(__) then '(<%daeExp(exp1)%>)>(<%daeExp(exp2)%>)'
  case GREATEREQ(__) then '(<%daeExp(exp1)%>)>=(<%daeExp(exp2)%>)'
  case LESS(__) then '(<%daeExp(exp1)%>)<(<%daeExp(exp2)%>)'

  else error(sourceInfo(), 'daeExpBinary: Not supporting operator? <%ExpressionDumpTpl.dumpExp(origExp,"\"")%>')
end daeExpBinary;

template daeExpCallBuiltin(Exp exp)
::=
  match exp
  case CALL(path=IDENT(name="DIVISION"),expLst=exp1::exp2::_) then '(<%daeExp(exp1)%>)/(<%daeExp(exp2)%>)'
  case CALL(path=IDENT(name="smooth"),expLst={exp1,exp2}) then daeExp(exp2)
  case CALL(path=IDENT(name="integer"),expLst=exp1::_) then '((int)<%daeExp(exp1)%>)'
  case CALL(path=IDENT(name="abs"),expLst={exp1}) then 'fabs(<%daeExp(exp1)%>)'
  case CALL(path=IDENT(name="min"),expLst={exp1,exp2},attr=CALL_ATTR(ty=T_REAL(__))) then 'fmin(<%daeExp(exp1)%>,<%daeExp(exp2)%>)'
  case CALL(path=IDENT(name="max"),expLst={exp1,exp2},attr=CALL_ATTR(ty=T_REAL(__))) then 'fmax(<%daeExp(exp1)%>,<%daeExp(exp2)%>)'
  /* TODO: Generate used builtin functions before SimCode */
  case CALL(path=IDENT(name="mod"),expLst=exp1::exp2::_) then 'om_mod(<%daeExp(exp1)%>,<%daeExp(exp2)%>)'
  /* TODO: pre needs to be handled in a special way */
  case CALL(path=IDENT(name="pre"),expLst={exp1}) then daeExp(exp1)
  case CALL(__) then error(sourceInfo(), 'daeExpCallBuiltin: Not supported: <%ExpressionDumpTpl.dumpExp(exp,"\"")%>')
end daeExpCallBuiltin;

template daeExpCall(Exp exp)
::=
  match exp
  case CALL(path=path,  attr=CALL_ATTR(__)) then '<%underscorePath(path)%>(comp<%expLst |> e => ', <%daeExp(e)%>'%>)'
  case CALL(__) then error(sourceInfo(), 'daeExpCall: Not supported: <%ExpressionDumpTpl.dumpExp(exp,"\"")%>')
end daeExpCall;

template varArrayNameValues(SimVar var, Integer ix, Boolean isPre)
::=
  match ix case 0 then
  (match var
  case SIMVAR(varKind=PARAM())
  case SIMVAR(varKind=OPT_TGRID())
  then 'comp-><%crefShortType(name)%>Parameter'
  case SIMVAR(varKind=EXTOBJ()) then 'comp->extObjs'
  case SIMVAR(__) then 'comp<%if isPre then "XXXPreVars???" else ''%>-><%crefShortType(name)%>Vars<%if isPre then "Pre"%>')
  else error(sourceInfo(), "varArrayNameValues ix>0")
end varArrayNameValues;

template constVal(Exp value, Type ty_)
  "Returns initial value of ScalarVariable."
::=
  match value
  case ICONST(__) then integer
  case RCONST(__) then real
  case SCONST(__) then '"<%Util.escapeModelicaStringToCString(string)%>"'
  case BCONST(__) then (if bool then "fmi2True" else "fmi2False")
  case ENUM_LITERAL(__) then index
  else (match ty_
    case T_REAL(__) then "0.0"
    else error(sourceInfo(), 'No start value for variable... <%ExpressionDumpTpl.dumpExp(value,"\"")%>')
  )
end constVal;

template startValue(SimVar var)
::=
  match var
  case SIMVAR(initialValue=SOME(e), type_=ty) then '<%constVal(e,ty)%> /*<%crefStr(name)%>*/,<%\n%>'
  case SIMVAR(type_=T_REAL(__)) then '0.0 /*<%crefStr(name)%>*/,<%\n%>'
  case SIMVAR(type_=T_INTEGER(__)) then '0 /*<%crefStr(name)%>*/,<%\n%>'
  case SIMVAR(type_=T_BOOL(__)) then 'fmi2False /*<%crefStr(name)%>*/,<%\n%>'
  case SIMVAR(type_=T_STRING(__)) then '"" /*<%crefStr(name)%>*/,<%\n%>'
  case SIMVAR(__) then error(sourceInfo(), 'No start value for variable <%crefStr(name)%>.')
end startValue;

template functionsFile(list<Function> functions,
                       list<Exp> literals,
                       list<String> externalFunctionIncludes)
 "Generates the contents of the main C file for the function case."
::=
  <<
  <% /* Note: The literals may not be part of the header due to separate compilation */
     literals |> literal hasindex i0 fromindex 0 => literalExpConst(literal,i0) ; separator="\n";empty
  %>
  <%externalFunctionIncludes |> inc => inc; separator="\n"%>

  <%functions |> func => functionDeclaration(func) ; separator="\n" %>

  <%functions |> func => functionBody(func) ; separator="\n" %>
  >>
end functionsFile;

template functionBody(Function fn)
 "Generates the body for a function."
::=
  match fn
  case fn as FUNCTION(__)                    then functionBodyRegularFunction(fn)
  case fn as EXTERNAL_FUNCTION(__)           then functionBodyExternalFunction(fn)
  case fn as RECORD_CONSTRUCTOR(__)          then error(sourceInfo(), "No records in embedded C yet") // functionBodyRecordConstructor(fn)
  case fn as KERNEL_FUNCTION(__)             then error(sourceInfo(), "No kernel functions in embedded C")
end functionBody;

template functionDeclaration(Function fn)
 "Generates the body for a function."
::=
  match fn
  case fn as FUNCTION(__)                    then functionPrototype(underscorePath(name), functionArguments, outVars)+";"
  case fn as EXTERNAL_FUNCTION(__)           then "static inline "+functionPrototype(underscorePath(name), funArgs, outVars)+";"
  case fn as RECORD_CONSTRUCTOR(__)          then error(sourceInfo(), "No records in embedded C yet") // functionBodyRecordConstructor(fn)
  case fn as KERNEL_FUNCTION(__)             then error(sourceInfo(), "No kernel functions in embedded C")
end functionDeclaration;

template functionBodyRegularFunction(Function fn)
 "Generates the body for a function."
::=
  match fn
  case fn as FUNCTION(__) then
  let fname = underscorePath(name)
  let prototype = functionPrototype(fname, functionArguments, outVars)
  let bodyPart = body |> stmt => statement(stmt) ; separator="\n"

  <<
  <%prototype%>
  {
    <% /* No tail recursion in MISRA C? */ /* _tailrecursive: OMC_LABEL_UNUSED */%>
    <% /* varInits */ %>
    <%bodyPart%>
    <% /* _return: OMC_LABEL_UNUSED */ /* No return label; avoid setjmp/longjmp in embedded C */ %>
    <% /* outVarAssign */ %>
    <% /* freeConstructedExternalObjects */ %>
    <%match outVars
       case v::_ then 'return <%varName(v)%>;'
       else ""
    %>
  }
  >>
end functionBodyRegularFunction;

template functionBodyExternalFunction(Function fn)
 "Generates the body for a function."
::=
  match fn
  case fn as EXTERNAL_FUNCTION(language="C") then
  let fname = underscorePath(name)
  let prototype = functionPrototype(fname, funArgs, outVars)
  let args = (extArgs |> arg => extArg(arg) ;separator=", ")
  let varDecl = (outVars |> arg => '<%varType(arg)%> <%varName(arg)%>;' ;separator="\n")
  let returnAssign = match extReturn case SIMEXTARG(cref=c) then '<%crefLocal(c)%> = '
  let returnStatement = (match outVars
    case {} then ""
    case VARIABLE(name=cref)::_ then 'return <%crefLocal(cref)%>;'
    else error(sourceInfo(), "Not variable return"))
  let varAssign = if outVars then
    (List.rest(outVars) |> var => '*out<%varName(var)%> = <%varName(var)%>;')
  <<
  static inline <%prototype%>
  {
    <%varDecl%>
    <%returnAssign%><%extName%>(<%args%>);
    <%varAssign%>
    <%returnStatement%>
  }
  >>
  else error(sourceInfo(), "Unknown external language")
end functionBodyExternalFunction;

template extArg(SimExtArg extArg)
::=
  match extArg
  case SIMEXTARG(isInput=true, isArray=false) then crefLocal(cref)
  case SIMEXTARGEXP(type_=T_REAL())
  case SIMEXTARGEXP(type_=T_INTEGER())
  case SIMEXTARGEXP(type_=T_STRING())
  case SIMEXTARGEXP(type_=T_BOOL()) then daeExp(exp)
  else error(sourceInfo(), "Unknown extArg")
end extArg;

template functionPrototype(Text fname, list<Variable> fargs, list<Variable> outVars)
::=
  let fargsStr = (fargs |> var => ', <%varType(var)%> <%varName(var)%>')
  let outarg = (match outVars
    case var::_ then (match var
      case VARIABLE(__) then varType(var)
      else error(sourceInfo(), "modelica_fnptr"))
    else "void")
  let outargs = if outVars then (List.rest(outVars) |> var => ', <%varType(var)%> *out<%varName(var)%>')
  '<%outarg%> <%fname%>(fmi2Component comp<%fargsStr%><%outargs%>)'
end functionPrototype;

template varName(Variable var)
::=
  match var
  case VARIABLE(__) then crefLocal(name)
  else error(sourceInfo(), "Not VARIABLE(__)")
end varName;

template varType(Variable var)
::=
  match var
  case VARIABLE(__) then expTypeShort(ty)
  else error(sourceInfo(), "Not VARIABLE(__)")
end varType;

template literalExpConst(Exp e, Integer i0)
::=
  match e
  case SCONST(__) then 'static const char * const OMCLIT<%i0%> = "<%Util.escapeModelicaStringToCString(string)%>";'
  else error(sourceInfo(), 'Literal expression: <%ExpressionDumpTpl.dumpExp(e,"\"")%>')
end literalExpConst;

template callExternalObjectConstructors(ExtObjInfo extObjInfo)
  "Generates function in simulation file."
::=
  match extObjInfo
  case EXTOBJINFO(__) then
    (vars |> var as SIMVAR(initialValue=SOME(exp)) =>
      '<%cref(var.name)%> = <%daeExp(exp)%>;'
      ;separator="\n")
  end match
end callExternalObjectConstructors;

template callExternalObjectDestructors(ExtObjInfo extObjInfo)
  "Generates function in simulation file."
::=
  match extObjInfo
  case EXTOBJINFO(__) then
    (vars |> var as SIMVAR(varKind=ext as EXTOBJ(__)) =>
      'omc_<%underscorePath(ext.fullClassName)%>_destructor(threadData,<%cref(var.name)%>);'
      ;separator="\n")
  end match
end callExternalObjectDestructors;

annotation(__OpenModelica_Interface="backend");
end CodegenEmbeddedC;

// vim: filetype=susan sw=2 sts=2
