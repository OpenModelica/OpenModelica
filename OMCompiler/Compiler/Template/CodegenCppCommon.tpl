package CodegenCppCommon
import interface SimCodeTV;
import CodegenUtil.*;
import ExpressionDumpTpl;

/**
* Basic template functions for cpp template
* -cref to string template functions
* -type to string template functions
* -string for temp var template functions
* -exp to string template functions
* -accessors to SimCode attributes
*/

/*******************************************************************************************************************************************************
* cref to string template functions
*******************************************************************************************************************************************************/

template cref(ComponentRef cr, Boolean useFlatArrayNotation)
 "Generates C equivalent name for component reference."
::=
  match cr
  case CREF_IDENT(ident = "time") then "_simTime"
  case WILD(__) then ''
  else "_"+crefToCStr(cr, useFlatArrayNotation)
end cref;

template localCref(ComponentRef cr, Boolean useFlatArrayNotation)
 "Generates C equivalent name for a local component reference."
::=
  match cr
  case CREF_IDENT(ident = "time") then "_simTime"
  case WILD(__) then ''
  else crefToCStr(cr,useFlatArrayNotation)
end localCref;

template subscriptsToCStr(list<Subscript> subscripts, Boolean useFlatArrayNotation)
::=
  if subscripts then

    if useFlatArrayNotation then
        '_<%subscripts |> s => subscriptToCStr(s) ;separator="_"%>'
    else
        '(<%subscripts |> s => subscriptToCStr(s) ;separator=","%>)'
end subscriptsToCStr;

template subscriptToCStr(Subscript subscript)
::=
  match subscript
  case SLICE(exp=ICONST(integer=i)) then i
  case WHOLEDIM(__) then "WHOLEDIM"
  case INDEX(__) then
   match exp
    case ICONST(integer=i) then i
    case ENUM_LITERAL(index=i) then i
    case CREF(componentRef=cr) then crefToCStr(cr, false)
    end match
  else "UNKNOWN_SUBSCRIPT"
end subscriptToCStr;

template crefToCStrForArray(ComponentRef cr, Text& dims)
 "Convert array cref to cstr. Skip subscripts if not NF_SCALARIZE."
::=
  match cr
  case CREF_IDENT(__) then
    let &dims+=listLength(subscriptLst)
    '<%ident%>_'
  case CREF_QUAL(__) then
    let subs = if Flags.isSet(Flags.NF_SCALARIZE) then subscriptsToCStrForArray(subscriptLst)
    '<%ident%><%subs%>_P_<%crefToCStrForArray(componentRef,dims)%>'
  case WILD(__) then ' '
  else "CREF_NOT_IDENT_OR_QUAL"
end crefToCStrForArray;

template crefToCStr1(ComponentRef cr, Boolean useFlatArrayNotation)
::=
  match cr
  case CREF_IDENT(__) then '<%ident%>_'
  case CREF_QUAL(__) then
    '<%ident%><%subscriptsToCStrForArray(subscriptLst)%>_P_<%crefToCStr1(componentRef,useFlatArrayNotation)%>'
  case WILD(__) then ' '
  else "CREF_NOT_IDENT_OR_QUAL"
end crefToCStr1;

template subscriptsToCStrForArray(list<Subscript> subscripts)
::=
  if subscripts then
    '<%subscripts |> s => subscriptToCStr(s) ;separator="$c"%>'
end subscriptsToCStrForArray;

template crefStrForWriteOutput(ComponentRef cr)
 "template for writing output variable names in mat or csv files"
::=
  match cr
  case CREF_IDENT(ident = "xloc") then '__xd<%subscriptsStrForWriteOutput(subscriptLst)%>'
  case CREF_IDENT(ident = "time") then "_simTime"
  case CREF_IDENT(__) then '<%ident%><%subscriptsStrForWriteOutput(subscriptLst)%>'
  case CREF_QUAL(ident = "$DER") then 'der(<%crefStrForWriteOutput(componentRef)%>)'
  case CREF_QUAL(ident = "$CLKPRE") then 'previous(<%crefStrForWriteOutput(componentRef)%>)'
  case CREF_QUAL(__) then '<%ident%><%subscriptsStrForWriteOutput(subscriptLst)%>.<%crefStrForWriteOutput(componentRef)%>'
  else "CREF_NOT_IDENT_OR_QUAL"
end crefStrForWriteOutput;

template crefStrForSetVariables(ComponentRef cr, Boolean useFlatArrayNotation)
 "template for Set Variables for labeling reduction"
::=
  match cr
  case CREF_QUAL(ident = "$DER") then ""
  else cref(cr,useFlatArrayNotation)
end crefStrForSetVariables;

template subscriptsStrForWriteOutput(list<Subscript> subscripts)
 "Generares subscript part of the name."
::=
  if subscripts then
    '[<%subscripts |> s => subscriptStr(s) ;separator=","%>]'//previous multi_array     '[<%subscripts |> s => subscriptStr(s) ;separator=","%>]'
end subscriptsStrForWriteOutput;

template crefStr(ComponentRef cr)
::=
  match cr
  case CREF_IDENT(ident = "xloc") then '__xd<%subscriptsStr(subscriptLst)%>'
  case CREF_IDENT(ident = "time") then "_simTime"
  case CREF_IDENT(__) then '<%System.unquoteIdentifier(ident)%>_<%subscriptsStr(subscriptLst)%>'
  case CREF_QUAL(__) then '<%System.unquoteIdentifier(ident)%>_<%subscriptsStr(subscriptLst)%>.<%crefStr(componentRef)%>'
  else "CREF_NOT_IDENT_OR_QUAL"
end crefStr;

template subscriptsStr(list<Subscript> subscripts)
 "Generares subscript part of the name."
::=
  if subscripts then
    '(<%subscripts |> s => subscriptStr(s) ;separator=","%>)'//previous multi_array     '[<%subscripts |> s => subscriptStr(s) ;separator=","%>]'
end subscriptsStr;

template subscriptStr(Subscript subscript)
 "Generates a single subscript.
  Only works for constant integer indicies."
::=
  match subscript
  case INDEX(exp=ICONST(integer=i)) then i
  case SLICE(exp=ICONST(integer=i)) then i
  case WHOLEDIM(__) then "WHOLEDIM"
  else "UNKNOWN_SUBSCRIPT"
end subscriptStr;

template contextCref(ComponentRef cr, Context context,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
  "Generates code for a component reference depending on which context we're in."
::=
match cr
case CREF_QUAL(ident = "$PRE") then
   '_discrete_events->pre(<%contextCref(componentRef,context,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>)'
 else
  let &varDeclsCref = buffer "" /*BUFD*/
  match context
  case FUNCTION_CONTEXT(__) then crefStr(cr)
  else '<%cref1(cr,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,context,varDeclsCref,stateDerVectorName,useFlatArrayNotation)%>'
end contextCref;

template contextCref2(ComponentRef cr, Context context)
  "Generates code for a component reference depending on which context we're in."
::=
  match context
  case FUNCTION_CONTEXT(__) then crefStr(cr)
  else ""
end contextCref2;

template contextFunName(String funName, Context context)
  "Generates a name in the Functions object depending on the context we're in."
::=
  match context
  case FUNCTION_CONTEXT(__) then '<%funName%>'
  else '_functions-><%funName%>'
end contextFunName;

template contextIteratorName(Ident name, Context context)
  "Generates code for an iterator variable."
::=
  name + "_"
end contextIteratorName;

template crefWithIndex(ComponentRef cr, Context context, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                       Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Return cref with index for the lhs of a for loop, i.e., _resistori_P_i."
::=
  match cr
    case CREF_QUAL(__) then
      "_" + crefToCStrWithIndex(cr, context, varDecls, simCode, extraFuncs, extraFuncsDecl, extraFuncsNamespace, stateDerVectorName /*=__zDot*/, useFlatArrayNotation)
  end match
end crefWithIndex;

template crefToCStrWithIndex(ComponentRef cr, Context context, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                             Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Helper function to crefWithIndex."
::=
  let &preExp = buffer ""
  let tmp = ""
  match cr
    case CREF_QUAL(__) then
      let identTmp = '<%ident%>'
      match listHead(subscriptLst)
        case INDEX(__) then
          match exp case e as CREF(__) then
            let tmp = daeExpCrefRhs(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
            '<%identTmp%><%tmp%><%subscriptsToCStrForArray(subscriptLst)%>_P_<%crefToCStr(componentRef,useFlatArrayNotation)%>'
          end match
      end match
  else "CREF_NOT_IDENT_OR_QUAL"
end crefToCStrWithIndex;


template cref1(ComponentRef cr, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Text &varDecls, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation) ::=
  match cr
  case CREF_IDENT(ident = "xloc") then '<%representationCref(cr, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)%>'
  case CREF_IDENT(ident = "time") then
    match context
    case  ALGLOOP_CONTEXT(genInitialisation=false)
    then "_system->_simTime"
    else "_simTime"
    end match
  case CREF_QUAL(ident = "$START") then '<%representationCref(componentRef, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)%>'
  else '<%representationCref(cr, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)%>'
end cref1;

template representationCref(ComponentRef inCref, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Context context, Text &varDecls, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation) ::=
  cref2simvar(inCref, simCode) |> var as SIMVAR(varKind=varKind, index=i, matrixName=matrixName) =>
  match varKind
    case STATE() then
      '__z[<%i%>]'
    case STATE_DER() then
      '__zDot[<%i%>]'
    case DAE_RESIDUAL_VAR() then
      '__daeResidual[<%i%>]'
    case JAC_VAR() then
      '<%contextSystem(context)%>_<%getOption(matrixName)%>jac_y(<%i%>)'
    case JAC_DIFF_VAR() then
      '<%contextSystem(context)%>_<%getOption(matrixName)%>jac_tmp(<%i%>)'
    case SEED_VAR() then
      '<%contextSystem(context)%>_<%getOption(matrixName)%>jac_x(<%i%>)'
    case VARIABLE() then
      match var
        case SIMVAR(index=-2) then
          // unknown in cref2simvar, e.g. local in a function, iterator or time
          '<%localCref(inCref, useFlatArrayNotation)%>'
        else
          match context
            case ALGLOOP_CONTEXT(genInitialisation = false, genJacobian=false) then
              '_system-><%cref(inCref, useFlatArrayNotation)%>'
            case ALGLOOP_CONTEXT(genInitialisation = false, genJacobian=true) then
              '_system->_<%crefToCStr(inCref,false)%>'
            case JACOBIAN_CONTEXT() then
              '_<%crefToCStr(inCref, false)%>'
            else
              '<%cref(inCref, useFlatArrayNotation)%>'
    else
      '<%contextSystem(context)%><%cref(inCref, useFlatArrayNotation)%>'
end representationCref;

template crefToCStrWithoutIndexOperator(ComponentRef cr)
 "Helper function to cref."
::=
  match cr
  case CREF_IDENT(__) then '<%unquoteIdentifier(ident)%><%subscriptsToCStrWithoutIndexOperator(subscriptLst)%>'
  case CREF_QUAL(__) then '<%unquoteIdentifier(ident)%><%subscriptsToCStrWithoutIndexOperator(subscriptLst)%>$P<%crefToCStrWithoutIndexOperator(componentRef)%>'
  case WILD(__) then ''
  else "CREF_NOT_IDENT_OR_QUAL"
end crefToCStrWithoutIndexOperator;

template subscriptsToCStrWithoutIndexOperator(list<Subscript> subscripts)
::=
  if subscripts then
    '$lB<%subscripts |> s => subscriptToCStrWithoutIndexOperator(s) ;separator="$c"%>$rB'
end subscriptsToCStrWithoutIndexOperator;

template subscriptToCStrWithoutIndexOperator(Subscript subscript)
::=
  match subscript
  case SLICE(exp=ICONST(integer=i)) then i
  case WHOLEDIM(__) then "WHOLEDIM"
  case INDEX(__) then
   match exp
    case ICONST(integer=i) then i
    case ENUM_LITERAL(index=i) then i
      end match
  else "UNKNOWN_SUBSCRIPT"
end subscriptToCStrWithoutIndexOperator;


template arraycref(ComponentRef cr, Boolean useFlatArrayNotation)
::=
  match cr
  case CREF_IDENT(ident = "xloc") then crefStr(cr)
  case CREF_IDENT(ident = "time") then "_simTime"
  case WILD(__) then ''
  else "_"+crefToCStr1(cr, useFlatArrayNotation)
end arraycref;


template arraycref2(ComponentRef cr, Text& dims)
::=
  match cr
  case CREF_IDENT(ident = "xloc") then crefStr(cr)
  case CREF_IDENT(ident = "time") then "_simTime"
  case WILD(__) then ''
  else "_"+crefToCStrForArray(cr,dims)
end arraycref2;

template cref2(ComponentRef cr, Boolean useFlatArrayNotation)
 "Generates C equivalent name for component reference."
::=
  match cr
  case CREF_IDENT(ident = "xloc") then '<%crefStr(cr)%>'
  case CREF_IDENT(ident = "time") then "_simTime"
  case WILD(__) then ''
  else "_"+crefToCStr(cr,useFlatArrayNotation)
end cref2;

template crefToCStr(ComponentRef cr, Boolean useFlatArrayNotation)
 "Helper function to cref."
::=
  match cr
  case CREF_IDENT(__) then
    let subs = if Flags.isSet(Flags.NF_SCALARIZE) then subscriptsToCStr(subscriptLst, useFlatArrayNotation)
    '<%ident%>_<%subs%>'
  case CREF_QUAL(__) then
    let subs = if Flags.isSet(Flags.NF_SCALARIZE) then subscriptsToCStrForArray(subscriptLst)
    '<%ident%><%subs%>_P_<%crefToCStr(componentRef, useFlatArrayNotation)%>'
  case WILD(__) then ''
  else "CREF_NOT_IDENT_OR_QUAL"
end crefToCStr;

template contextSystem(Context context)
 "Dereference _system in algloop context"
::=
  match context
  case ALGLOOP_CONTEXT(genInitialisation = false) then
    '_system->'
  else
    ''
end contextSystem;

template daeExpCrefRhs(Exp exp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs,
                       Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a component reference on the right hand side of an
 expression."
::=
  match exp
  // A record cref without subscripts (i.e. a record instance) is handled
  // by daeExpRecordCrefRhs only in a simulation context, not in a function.
  case CREF(componentRef = cr, ty = t as T_COMPLEX(complexClassType = RECORD(path = _))) then
    match context case FUNCTION_CONTEXT(__) then
      '<%daeExpCrefRhs2(exp, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
    else
      daeExpRecordCrefRhs(t, cr, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case CREF(ty = T_FUNCTION_REFERENCE_FUNC(functionType=t)) then
    functionClosure(underscorePath(crefToPathIgnoreSubs(componentRef)), "", t, t, context, &extraFuncsDecl)
  case CREF(componentRef = CREF_IDENT(ident=ident), ty = T_FUNCTION_REFERENCE_VAR(__)) then
    contextFunName(ident, context)
  else
    daeExpCrefRhs2(exp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
end daeExpCrefRhs;


template daeExpCrefRhs2(Exp ecr, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs,
                        Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a component reference."
::=
match ecr
case component as CREF(componentRef=cr, ty=ty) then
  let box = daeExpCrefRhsArrayBox(cr, ty, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  if box then
    box
  else if crefIsScalar(cr, context) then
    contextCref(cr, context, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  else
    if boolAnd(intEq(listLength(crefSubs(cr)), listLength(crefDims(cr))), crefSubIsScalar(cr)) then
      // The array subscript results in a scalar
      let arrName = contextCref(crefStripLastSubs(cr), context,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      let arrayType = expTypeShort(ty)
      let dimsValuesStr = (crefSubs(cr) |> INDEX(__) =>
          daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        ;separator=",")
      match arrayType
        case "metatype_array" then
          'arrayGet(<%arrName%>,<%dimsValuesStr%>) /* DAE.CREF */'
        else
         <<
         <%arrName%>(<%dimsValuesStr%>)
         >>
    else
      // The array subscript denotes a slice
      let arrName = contextArrayCref(cr, context)
      let typeStr = expTypeShort(ty)
      let slice = daeExpCrefIndexSpec(crefSubs(cr), context, &preExp,
        &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace,
        stateDerVectorName, useFlatArrayNotation)
      let &preExp += 'ArraySlice<<%typeStr%>> <%slice%>_as(<%arrName%>, <%slice%>);<%\n%>'
      '<%slice%>_as'
end daeExpCrefRhs2;


template daeExpCrefIndexSpec(list<Subscript> subs, Context context,
  Text &preExp, Text &varDecls, SimCode simCode,
  Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace,
  Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates index spec of an array as temporary vector<Slice>."
::=
  let tmp_slice = tempDecl("vector<Slice>", &varDecls /*BUFD*/)
  let &preExp += '<%tmp_slice%>.clear();<%\n%>'
  let _ = (subs |> sub hasindex i1 =>
    match sub
      case INDEX(__) then
        let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        let &preExp += '<%tmp_slice%>.push_back(Slice(<%expPart%>));<%\n%>'
        ''
      case WHOLEDIM(__) then
        let &preExp += '<%tmp_slice%>.push_back(Slice());<%\n%>'
        ''
      case SLICE(__) then
        match exp
        case RANGE(__) then
          let start_exp = daeExp(start, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
          let stop_exp = daeExp(stop, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
          let step_exp = match step case SOME(stepExp) then daeExp(stepExp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) else "1"
          let &preExp += '<%tmp_slice%>.push_back(Slice(<%start_exp%>, <%step_exp%>, <%stop_exp%>));<%\n%>'
          ''
        else
          // default branch if exp is no range
          let expPart = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
          let &preExp += '<%tmp_slice%>.push_back(Slice(<%expPart%>));<%\n%>'
          ''
        end match
    ;separator="\n ")
  '<%tmp_slice%>'
end daeExpCrefIndexSpec;

template daeExpCrefRhsArrayBox(ComponentRef cr, DAE.Type ty, Context context, Text &preExp,
                               Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                               Text extraFuncsNamespace, Text stateDerVectorName, Boolean useFlatArrayNotation)
 "Helper to daeExpCrefRhs."
::=
  cref2simvar(cr, simCode) |> var as SIMVAR(index=i, matrixName=matrixName) =>
    match varKind
        case STATE()
        case STATE_DER()
        case DAE_RESIDUAL_VAR() then
          let arrdata = representationCref(cr, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)
          daeExpCrefRhsArrayBox2(arrdata, ty, false, context, preExp, varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace)
        case JAC_VAR()
        case JAC_DIFF_VAR()
        case SEED_VAR() then
          let arrdata = representationCref(cr, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, context, varDecls, stateDerVectorName, useFlatArrayNotation)
          daeExpCrefRhsArrayBox2(arrdata, ty, true, context, preExp, varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace)
        else
          match context
          case FUNCTION_CONTEXT(__) then ''
          else
            match ty
            case t as T_ARRAY(ty=aty, dims=dims) then
              match cr
              case CREF_QUAL(ident = "$PRE") then
                let arr = arrayCrefCStr(componentRef, context)
                let ndims = listLength(dims)
                let dimstr = checkDimension(dims)
                let T = expTypeShort(aty)
                let &preExp +=
                  <<
                  StatArrayDim<%ndims%><<%T%>, <%dimstr%>> <%arr%>_pre;
                  std::transform(<%arr%>.getData(),
                                 <%arr%>.getData() + <%arr%>.getNumElems(),
                                 <%arr%>_pre.getData(),
                                 PreArray2CArray<<%T%>>(_discrete_events));
                  >>
                '<%arr%>_pre'
              else
                ''
            else ''
end daeExpCrefRhsArrayBox;


template daeExpCrefRhsArrayBox2(Text arrayData, DAE.Type ty, Boolean isRowMajorData, Context context, Text &preExp /*BUFP*/,
                                Text &varDecls /*BUFP*/, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace)
::=
 match ty
  case t as T_ARRAY(ty=aty,dims=dims) then
    let dimstr = checkDimension(dims)
    let arrayType = match dimstr
      case "" then 'DynArrayDim<%listLength(dims)%><<%expTypeShort(ty)%>>'
      else 'StatArrayDim<%listLength(dims)%><<%expTypeShort(ty)%>,<%dimstr%>>'
      end match
    let &tmpdecl = buffer "" /*BUFD*/
    let arrayVar = tempDecl(arrayType, &tmpdecl /*BUFD*/)
    let arrayAssign = if isRowMajorData then
      'assignRowMajorData(&<%arrayData%>, <%arrayVar%>)' else
      '<%arrayVar%>.assign(&<%arrayData%>)'
    let &preExp +=
      <<
      <%arrayType%> <%arrayVar%>;
      <%arrayAssign%>;<%\n%>
      >>
    arrayVar
  else
    arrayData
end daeExpCrefRhsArrayBox2;

template daeExpRecordCrefRhs(DAE.Type ty, ComponentRef cr, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs,
                             Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match ty
case T_COMPLEX(complexClassType = record_state, varLst = var_lst) then
  let vars = var_lst |> v => daeExp(makeCrefRecordExp(cr,v), context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
             ;separator=", "
  let record_type_name = underscorePath(ClassInf.getStateName(record_state))
  let ret_type = '<%record_type_name%>RetType'
  let ret_var = tempDecl(ret_type, &varDecls)
  let &preExp += '<%contextFunName(record_type_name, context)%>(<%vars%>,<%ret_var%>);<%\n%>'
  '<%ret_var%>'
end daeExpRecordCrefRhs;

template crefST(ComponentRef cr, Boolean useFlatArrayNotation)
 "Generates C equivalent name for component reference."
::=
  match cr
  case CREF_IDENT(ident = "time") then "_simTime"
  case WILD(__) then ''
  else crefToCStr(cr, useFlatArrayNotation)
end crefST;

template contextArrayCref(ComponentRef cr, Context context)
 "Generates code for an array component reference depending on the context."
::=
  match context
  case FUNCTION_CONTEXT(__) then arrayCrefStr(cr)
  else arrayCrefCStr(cr,context)
end contextArrayCref;

template arrayCrefStr(ComponentRef cr)
::=
  match cr
  case CREF_IDENT(ident = "time") then "_simTime"
  case CREF_IDENT(__) then '<%ident%>_'
  case CREF_QUAL(__) then '<%ident%>_.<%arrayCrefStr(componentRef)%>'
  else "CREF_NOT_IDENT_OR_QUAL"
end arrayCrefStr;

template arrayCrefCStr(ComponentRef cr,Context context)
::=
match context
case ALGLOOP_CONTEXT(genInitialisation = false) then
 let& dims = buffer "" /*BUFD*/
<< _system->_<%crefToCStrForArray(cr,dims)%> >>
else
let& dims = buffer "" /*BUFD*/
'_<%crefToCStrForArray(cr,dims)%>'
end arrayCrefCStr;

template arrayCrefCStr2(ComponentRef cr)
::=
  match cr
  case CREF_IDENT(__) then '<%unquoteIdentifier(ident)%>'
  case CREF_QUAL(__) then '<%unquoteIdentifier(ident)%>_P_<%arrayCrefCStr2(componentRef)%>'
  else "CREF_NOT_IDENT_OR_QUAL"
end arrayCrefCStr2;

template crefTypeST(ComponentRef cr) "template crefType
  Like cref but with cast if type is integer."
::=
  match cr
    case CREF_IDENT(__) then '<%expTypeShortSPS(identType)%>'
    case CREF_QUAL(__)  then '<%crefTypeST(componentRef)%>'
    else "crefType:ERROR"
  end match
end crefTypeST;

template crefTypeMLPI(ComponentRef cr) "template crefType
  Like cref but with cast if type is integer."
::=
  match cr
    case CREF_IDENT(__) then '<%expTypeShortMLPI(identType)%>'
    case CREF_QUAL(__)  then '<%crefTypeMLPI(componentRef)%>'
    else "crefType:ERROR"
  end match
end crefTypeMLPI;


template crefStartValueType(ComponentRef cr)
 "Returns type string for get/set<type>StartValue methods."
::=
  match cr
  case CREF_IDENT(__) then
    let typeShort = expTypeShort(identType)
    let typeString = if stringEq(typeShort, "double") then "Real"
      else if stringEq(typeShort, "int") then "Int"
      else if stringEq(typeShort, "bool") then
      let booltype =  match  Config.simCodeTarget()
      case "Cpp" then
      "Bool"
      case "omsicpp" then
      "Int"
      end match
      booltype
      else if stringEq(typeShort, "string") then "String"
      else if stringEq(typeShort, "void*") then "ExternalObject"
      else 'ERROR:crefStartValueType <%typeShort%> '
    '<%typeString%>'
  case CREF_QUAL(__) then
    '<%crefStartValueType(componentRef)%>'
  else
    'crefStartValueType:ERROR'
  end match
end crefStartValueType;

/*******************************************************************************************************************************************************
* end of cref to string template functions
*******************************************************************************************************************************************************/


/*******************************************************************************************************************************************************
* type to string template functions
*******************************************************************************************************************************************************/

template dimension(Dimension d,Context context)
::=
  match d
  case DAE.DIM_BOOLEAN(__) then '2'
  case DAE.DIM_INTEGER(__) then integer
  case DAE.DIM_ENUM(__) then size
  case DAE.DIM_EXP(exp=e) then dimensionExp(e,context, false)
  case DAE.DIM_UNKNOWN(__) then '-1'//error(sourceInfo(),"Unknown dimensions may not be part of generated code. This is most likely an error on the part of OpenModelica. Please submit a detailed bug-report.")
  else error(sourceInfo(), 'dimension: INVALID_DIMENSION')
end dimension;

template checkDimension(Dimensions dims)
::=
  dimensionsList(dims) |> dim as Integer   =>  '<%dim%>';separator=","
end checkDimension;

template checkExpDimension(list<DAE.Exp> dims)
::=
  expDimensionsList(dims) |> dim as Integer   =>  '<%dim%>';separator=","
end checkExpDimension;

template listDimsFlat(Dimensions dims, Type elty)
 "return list of dimensions of form 'd1, d2, ..., dn', flattening subarrays"
::=
  let dimstr = checkDimension(dims)
  match dimstr
  case "" then
    ''
  else
    match elty
    case T_ARRAY(dims=subdims, ty=subty) then
      let subdimstr = listDimsFlat(subdims, subty)
      match subdimstr
      case "" then
        ''
      else
        '<%dimstr%>, <%subdimstr%>'
      end match
    else
      dimstr
end listDimsFlat;

template nDimsFlat(Dimensions dims, Type elty, Integer offset)
 "return number of dimensions, flattening subarrays"
::=
  match elty
  case T_ARRAY(dims=subdims, ty=subty) then
    nDimsFlat(subdims, subty, intAdd(listLength(dims), offset))
  else
    intAdd(listLength(dims), offset)
end nDimsFlat;

template expTypeShort(DAE.Type type)
 "Returns the base type name for declarations"
::=
  match type
  case T_INTEGER(__)     then "int"
  case T_REAL(__)        then "double"
  case T_STRING(__)      then if acceptMetaModelicaGrammar() then "metatype" else "string"
  case T_BOOL(__)        then "bool"
  case T_ENUMERATION(__) then "int"
  case T_UNKNOWN(__)     then "double /*W1*/" // assumming real for unknown type
  case T_ANYTYPE(__)     then "complex2"
  case T_SUBTYPE_BASIC(__) then expTypeShort(complexType)
  case T_ARRAY(__)       then expTypeShort(ty)
  case T_COMPLEX(complexClassType=EXTERNAL_OBJ(__)) then "void*"
  case T_COMPLEX(__)     then '<%underscorePath(ClassInf.getStateName(complexClassType))%>Type'
  case T_METATYPE(__)
  case T_METABOXED(__)   then "metatype"
  case T_FUNCTION_REFERENCE_VAR(__) then "fnptr"
  else 'expTypeShort:ERROR <%unparseType(type)%> '
end expTypeShort;

template expTypeFlag(DAE.Type ty, Integer flag)
 "Returns code for a type, depending on flag"
::=
  match flag
  case 1 then
    // we want the short type
    expTypeShort(ty)
  case 2 then
    // we want the "modelica type"
    match ty case T_COMPLEX(complexClassType=EXTERNAL_OBJ(__)) then
      '<%expTypeShort(ty)%>'
    else match ty case T_COMPLEX(complexClassType=RECORD(path=rname)) then
      '<%underscorePath(rname)%>Type'
    else match ty case T_COMPLEX(__) then
      '<%underscorePath(ClassInf.getStateName(complexClassType))%>'
     else
      '<%expTypeShort(ty)%>'
  case 3 then
    // we want the "array type", static if dims are known, dynamic otherwise
    match ty
    case T_ARRAY(ty=elty, dims=dims) then
      expTypeArrayDims(elty, dims)
    else
      'ERROR:expTypeFlag3 no array'
    end match
  case 4 then
    // we want the "array type" only if type is array, otherwise "modelica type"
    match ty
    case T_ARRAY(ty=elty, dims=dims) then
      expTypeArrayDims(elty, dims)
    else
      expTypeFlag(ty, 2)
    end match
  case 5 then
    match ty
  /* previous multiarray
    case T_ARRAY(dims=dims) then 'multi_array_ref<<%expTypeShort(ty)%>,<%listLength(dims)%>>'
    */
  case T_ARRAY(dims=dims) then
  //let testbasearray = dims |> dim =>  '<%testdimension(dim)%>' ;separator=''
  let dimstr = checkDimension(dims)
  match dimstr
  case "" then 'DynArrayDim<%listLength(dims)%><<%expTypeShort(ty)%>>'
  else 'StatArrayDim<%listLength(dims)%><<%expTypeShort(ty)%>,<%dimstr%>>&'
  else expTypeFlag(ty, 2)
    end match

  case 6 then
    expTypeFlag(ty, 4)

  case 7 then
     match ty
    case T_ARRAY(dims=dims)
    then
     'multi_array<<%expTypeShort(ty)%>,<%listLength(dims)%>>'
    end match

  case 8 then
    match ty
  case T_ARRAY(dims=dims) then'BaseArray<<%expTypeShort(ty)%>>&'
  else expTypeFlag(ty, 9)
    end match

  case 9 then
  // we want the "modelica type"
  match ty case T_COMPLEX(complexClassType=EXTERNAL_OBJ(__)) then
    '<%expTypeShort(ty)%>'
  else match ty case T_COMPLEX(complexClassType=RECORD(path=rname)) then
    '<%underscorePath(rname)%>Type&'
  else match ty case T_COMPLEX(__) then
    '<%underscorePath(ClassInf.getStateName(complexClassType))%>&'
   else
    '<%expTypeShort(ty)%>'

end expTypeFlag;

template crefType(ComponentRef cr) "template crefType
  Like cref but with cast if type is integer."
::=
  match cr
    case CREF_IDENT(__) then expTypeArrayIf(identType)
    case CREF_QUAL(__)  then crefType(componentRef)
    else "crefType:ERROR"
  end match
end crefType;

template expTypeFromExpShort(Exp exp)

::=
  expTypeFromExpFlag(exp, 1)
end expTypeFromExpShort;

template expTypeFromExpModelica(Exp exp)

::=
  expTypeFromExpFlag(exp, 2)
end expTypeFromExpModelica;

template expTypeFromExpArray(Exp exp)

::=
  expTypeFromExpFlag(exp, 4)
end expTypeFromExpArray;

template expTypeShortSPS(DAE.Type type)
::=
  match type
  case T_INTEGER(__)         then "INT"
  case T_REAL(__)        then "LREAL"
  case T_STRING(__)      then if acceptMetaModelicaGrammar() then "metatype" else "string"
  case T_BOOL(__)        then "BOOL"
  case T_ENUMERATION(__) then "INT"
  /* assumming real for uknown type! */
  case T_UNKNOWN(__)     then "LREAL"
  case T_ANYTYPE(__)     then "type not supported"
  case T_ARRAY(__)       then expTypeShortSPS(ty)
  case T_COMPLEX(complexClassType=EXTERNAL_OBJ(__))
                      then "type not supported"
  case T_COMPLEX(__)     then '<%underscorePath(ClassInf.getStateName(complexClassType))%>Type'
  case T_METATYPE(__) case T_METABOXED(__)    then "type not supported"
  case T_FUNCTION_REFERENCE_VAR(__) then "type not supported"
  else "expTypeShort:ERROR"
end expTypeShortSPS;

template expTypeShortMLPI(DAE.Type type)
::=
  match type
  case T_INTEGER(__)     then "MLPI_IEC_INT"
  case T_REAL(__)        then "MLPI_IEC_LREAL"
  case T_STRING(__)      then if acceptMetaModelicaGrammar() then "metatype" else "string"
  case T_BOOL(__)        then "MLPI_IEC_BOOL"
  case T_ENUMERATION(__) then "MLPI_IEC_INT"
  /* assumming real for uknown type! */
  case T_UNKNOWN(__)     then "MLPI_IEC_LREAL"
  case T_ANYTYPE(__)     then "type not supported"
  case T_ARRAY(__)       then expTypeShortSPS(ty)
  case T_COMPLEX(complexClassType=EXTERNAL_OBJ(__))
                      then "type not supported"
  case T_COMPLEX(__)     then '<%underscorePath(ClassInf.getStateName(complexClassType))%>Type'
  case T_METATYPE(__) case T_METABOXED(__)    then "type not supported"
  case T_FUNCTION_REFERENCE_VAR(__) then "type not supported"
  else "expTypeShort:ERROR"
end expTypeShortMLPI;

template expType(DAE.Type ty, Boolean isArray)
 "Generate type helper."
::=
  if isArray
  then 'expType_<%expTypeArray1(ty,0)%>_NOT_YET'
  else expTypeShort(ty)
end expType;

template expTypeModelica(DAE.Type ty)
 "Generate type helper."
::=
  expTypeFlag(ty, 2)
end expTypeModelica;

template expTypeArray(DAE.Type ty)
  "Returns the array type"
::=
  expTypeFlag(ty, 3)
end expTypeArray;

template expTypeArrayIf(DAE.Type ty)
 "Generate type helper."
::=
  expTypeFlag(ty, 4)
end expTypeArrayIf;

template expTypeArray1(DAE.Type ty, Integer dims) ::=
<<
SimArray<%dims%><<%expTypeShort(ty)%>>
>>
end expTypeArray1;

template expTypeArrayDims(DAE.Type elty, DAE.Dimensions dims)
 "Generate type string for static or dynamic array, depending on dims"
::=
  let typeShort = expTypeShort(elty)
  let dimstr = listDimsFlat(dims, elty)
  match dimstr
  case "" then
    'DynArrayDim<%nDimsFlat(dims, elty, 0)%><<%typeShort%>>'
  else
    'StatArrayDim<%nDimsFlat(dims, elty, 0)%><<%typeShort%>, <%dimstr%>>'
  end match
end expTypeArrayDims;

template allocateDimensions(DAE.Type ty,Context context)
::=
 match ty
     case T_ARRAY(dims=dims) then
     let dimstr = dims |> dim =>  '<%dimension(dim,context)%>'  ;separator=','
    <<
    <%dimstr%>
    >>

end allocateDimensions;



/*******************************************************************************************************************************************************
* end of type to string template functions
********************************************************************************************************************************************************/


/*******************************************************************************************************************************************************
* string for temp var template functions
********************************************************************************************************************************************************/

template tempDecl(String ty, Text &varDecls /*BUFP*/)
 "Declares a temporary variable in varDecls and returns the name."
::=
  let newVar = 'tmp<%System.tmpTick()%>'
  let &varDecls += '<%ty%> <%newVar%>;<%\n%>'
  newVar
end tempDecl;

template tempDeclAssign(String ty, Text &varDecls /*BUFP*/,String assign)
 "Declares a temporary variable in varDecls and returns the name."
::=
  let newVar = 'tmp<%System.tmpTick()%>'
  let &varDecls += '<%ty%> <%newVar%> = <%assign%>;<%\n%>'
  newVar
end tempDeclAssign;

template tempDecl1(String ty, String exp, Text &varDecls /*BUFP*/)
 "Declares a temporary variable in varDecls and returns the name."
::=
  let newVar = 'tmp<%System.tmpTick()%>'
  let newVar1 = '<%newVar%>(<%exp%>)'
  let &varDecls += '<%ty%> <%newVar1%>;<%\n%>'
  newVar
end tempDecl1;

/*******************************************************************************************************************************************************
end string for temp var template functions
********************************************************************************************************************************************************/



/*******************************************************************************************************************************************************
exp to string template functions
********************************************************************************************************************************************************/

template dimensionExp(DAE.Exp dimExp,Context context,Boolean useFlatArrayNotation)
::=
  match dimExp
  case DAE.CREF(componentRef = cr) then
   match context
    case FUNCTION_CONTEXT(__) then System.unquoteIdentifier(crefStr(cr))
   else '<%cref(cr, useFlatArrayNotation)%>'
  else '/* fehler dimensionExp: INVALID_DIMENSION <%ExpressionDumpTpl.dumpExp(dimExp,"\"")%>*/' //error(sourceInfo(), 'dimensionExp: INVALID_DIMENSION <%ExpressionDumpTpl.dumpExp(dimExp,"\"")%>')
end dimensionExp;

template daeDimensionExp(Exp exp)
 "Generates code for an expression."
::=
  match exp
  case e as ICONST(__)          then '<%integer%>'
  else '-1'
end daeDimensionExp;


template daeExp(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for an expression."
::=
  match exp
  case e as ICONST(__)          then    integer
  case e as RCONST(__)          then    real
  case e as BCONST(__)          then    if bool then "true" else "false"
  case e as ENUM_LITERAL(__)    then    index
  case e as CREF(__)            then    daeExpCrefRhs(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as CAST(__)            then    daeExpCast(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as CONS(__)            then    "Cons not supported yet"
  case e as SCONST(__)          then     daeExpSconst(string, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as UNARY(__)           then     daeExpUnary(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as LBINARY(__)         then     daeExpLbinary(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as LUNARY(__)          then     daeExpLunary(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as BINARY(__)          then     daeExpBinary(operator, exp1, exp2, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as IFEXP(__)           then     daeExpIf(expCond, expThen, expElse, context, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as RELATION(__)        then     daeExpRelation(e, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as CALL(__)            then     daeExpCall(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as RECORD(__)          then     daeExpRecord(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as ASUB(__)            then     '/*t1*/<%daeExpAsub(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
  case e as MATRIX(__)          then     daeExpMatrix(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as RANGE(__)           then     '/*t2*/<%daeExpRange(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
  case e as TSUB(__)            then     '/*t3*/<%daeExpTsub(e, context,  &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation )%>'
  case e as REDUCTION(__)       then     daeExpReduction(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as ARRAY(__)           then     '/*t4*/<%daeExpArray(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
  case e as SIZE(__)            then     daeExpSize(e, context, &preExp, &varDecls, simCode , &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as SHARED_LITERAL(__)  then     daeExpSharedLiteral(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/, useFlatArrayNotation)
  case e as PARTEVALFUNCTION(__)then daeExpPartEvalFunction(e, context, &preExp, &varDecls, simCode , &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as BOX(__)             then daeExpBox(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as UNBOX(__)           then daeExpUnbox(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  case e as RSUB(__)            then daeExpRSub(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)

  else error(sourceInfo(), 'Unknown exp:<%ExpressionDumpTpl.dumpExp(exp,"\"")%>')
end daeExp;

template daeExpRSub(Exp exp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                     Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for an tsub expression."
::=
  match exp
  case RSUB(ix=-1) then
    let res = daeExp(exp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    '<%res%>.<%fieldName%>_'
  case RSUB(__) then
    error(sourceInfo(), '<%ExpressionDumpTpl.dumpExp(exp,"\"")%>: failed')
end daeExpRSub;

template daeExpRange(Exp exp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                     Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a range expression."
::=
  match exp
  case RANGE(__) then
    let ty_str = expTypeShort(ty)
    let start_exp = daeExp(start, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let stop_exp = daeExp(stop, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let tmp = tempDecl('DynArrayDim1<<%ty_str%>>', &varDecls /*BUFD*/)
    let step_exp = match step case SOME(stepExp) then daeExp(stepExp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) else "1"
    let &preExp +=
      <<
      int <%tmp%>_num_elems =(<%stop_exp%>-<%start_exp%>)/<%step_exp%>+1;
      <%tmp%>.setDims(<%tmp%>_num_elems) /*daeExpRange*/;
      for (int <%tmp%>_i = 1; <%tmp%>_i <= <%tmp%>_num_elems; <%tmp%>_i++)
        <%tmp%>(<%tmp%>_i) = <%start_exp%>+(<%tmp%>_i-1)*<%step_exp%>;<%\n%>
      >>
    '<%tmp%>'
end daeExpRange;

template daeExpReduction(Exp exp, Context context, Text &preExp,
                         Text &varDecls,SimCode simCode, Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a reduction expression. The code is quite messy because it handles all
  special reduction functions (list, listReverse, array) and handles both list and array as input"
::=
  match exp
  case r as REDUCTION(reductionInfo=ri as REDUCTIONINFO(iterType=THREAD()),iterators=iterators)
  case r as REDUCTION(reductionInfo=ri as REDUCTIONINFO(iterType=COMBINE()),iterators=iterators as {_}) then
  (
  let &tmpVarDecls = buffer ""
  let &tmpExpPre = buffer ""
  let &bodyExpPre = buffer ""
  let &rangeExpPre = buffer ""
  let arrayTypeResult = expTypeFromExpArray(r)
  let arrIndex = match ri.path case IDENT(name="array") then tempDecl("int",&tmpVarDecls)
  let foundFirst = if not ri.defaultValue then tempDecl("int",&tmpVarDecls)
  let resType = expTypeArrayIf(typeof(exp))
  let res = contextCref(makeUntypedCrefIdent(ri.resultName), context,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let &tmpVarDecls += '<%resType%> <%res%>;<%\n%>'
  let resTmp = tempDecl(resType,&varDecls)
  let &preDefault = buffer ""
  let resTail = (match ri.path case IDENT(name="list") then tempDecl("modelica_metatype*",&tmpVarDecls))
  let defaultValue = (match ri.path
    case IDENT(name="array") then ""
    else (match ri.defaultValue
          case SOME(v) then daeExp(valueExp(v), context, &preDefault, &tmpVarDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)))
  let reductionBodyExpr = contextCref(makeUntypedCrefIdent(ri.foldName), context,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let bodyExprType = expTypeArrayIf(typeof(r.expr))
  let reductionBodyExprWork = daeExp(r.expr, context, &bodyExpPre, &tmpVarDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let &tmpVarDecls += '<%bodyExprType%> <%reductionBodyExpr%>;<%\n%>'
  let &bodyExpPre += '<%reductionBodyExpr%> = <%reductionBodyExprWork%>;<%\n%>'
  let foldExp = (match ri.path
    case IDENT(name="list") then
    <<
    *<%resTail%> = mmc_mk_cons(<%reductionBodyExpr%>,0);
    <%resTail%> = &MMC_CDR(*<%resTail%>);
    >>
    case IDENT(name="listReverse") then // This is too easy; the damn list is already in the correct order
      '<%res%> = mmc_mk_cons(<%reductionBodyExpr%>,<%res%>);'
    case IDENT(name="array") then
      match typeof(r.expr)
        case T_COMPLEX(complexClassType = record_state) then
          let rec_name = '<%underscorePath(ClassInf.getStateName(record_state))%>'
          '*((<%rec_name%>*)generic_array_element_addr(&<%res%>, sizeof(<%rec_name%>), 1, <%arrIndex%>++)) = <%reductionBodyExpr%>;'
        case T_ARRAY(__) then
          let tmp_shape = tempDecl("vector<size_t>", &varDecls /*BUFD*/)
          let tmp_indeces = tempDecl("idx_type", &varDecls /*BUFD*/)
          /*let idx_str = (dims |> dim =>
            let tmp_idx = tempDecl("vector<size_t>", &varDecls)
            let &preExp += '<%tmp_shape%>.push_back(1);<%\n%>
                       <%tmp_indeces%>.push_back(<%tmp_idx%>);<%\n%>'
                       ''
                       )*/
          let tmp_idx = tempDecl("vector<size_t>", &varDecls /*BUFD*/)
          /*let &preExp += '<%tmp_shape%>.push_back(0);<%\n%>
                        <%tmp_idx%>.push_back(<%arrIndex%>++);<%\n%>
                        <%tmp_indeces%>.push_back(<%tmp_idx%>);<%\n%>'
          let tmp = 'make_pair(<%tmp_shape%>,<%tmp_indeces%>)'
          */

          <<
          <%(dims |> dim =>
            let tmp_idx = tempDecl("vector<size_t>", &varDecls /*BUFD*/)
                       '<%tmp_shape%>.push_back(1);<%\n%>
                       <%tmp_indeces%>.push_back(<%tmp_idx%>);<%\n%>'
            )%>
          <%tmp_shape%>.push_back(0);<%\n%>
          <%tmp_idx%>.push_back(<%arrIndex%>++);<%\n%>
          <%tmp_indeces%>.push_back(<%tmp_idx%>);<%\n%>
          fill_array_from_shape(make_pair(<%tmp_shape%>,<%tmp_indeces%>),<%reductionBodyExpr%>,<%res%>);
          >>
        else
          '<%res%>(<%arrIndex%>++) = <%reductionBodyExpr%>;'
    else match ri.foldExp case SOME(fExp) then
      let &foldExpPre = buffer ""
      let fExpStr = daeExp(fExp, context, &bodyExpPre, &tmpVarDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      if not ri.defaultValue then
      <<
      if(<%foundFirst%>)
      {
        <%res%> = <%fExpStr%>;
      }
      else
      {
        <%res%> = <%reductionBodyExpr%>;
        <%foundFirst%> = 1;
      }
      >>
      else '<%res%> = <%fExpStr%>;')
  let endLoop = tempDecl("int",&tmpVarDecls)
  let loopHeadIter = (iterators |> iter as REDUCTIONITER(__) =>
    let identType = expTypeFromExpModelica(iter.exp)
    let ty_str = expTypeShort(ty)
    let arrayType = 'DynArrayDim1<<%identType%>>'//expTypeFromExpArray(iter.exp)
    let loopVar = '<%iter.id%>_loopVar'
    let &guardExpPre = buffer ""
    let &tmpVarDecls += '<%arrayType%> <%loopVar%>;/*testloopvar*/<%\n%>'
    let firstIndex = tempDecl("int",&tmpVarDecls)
    let rangeExp = daeExp(iter.exp, context, &rangeExpPre, &tmpVarDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let &rangeExpPre += '<%loopVar%> = <%rangeExp%>/*testloopvar2*/;<%\n%>'
    let &rangeExpPre += if firstIndex then '<%firstIndex%> = 1;<%\n%>'
    let guardCond = (match iter.guardExp case SOME(grd) then daeExp(grd, context, &guardExpPre, &tmpVarDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) else "1")
    let empty = '0 == (<%loopVar%>.getDim(2))'
    let iteratorName = contextIteratorName(iter.id, context)
    let &tmpVarDecls += '<%identType%> <%iteratorName%>;<%\n%>'
    let guardExp =
      <<
      <%&guardExpPre%>
      if(<%guardCond%>) { /* found non-guarded */
        <%endLoop%>--;
        break;
      }
      >>
      let addr = match iter.ty
        case T_ARRAY(ty=T_COMPLEX(complexClassType = record_state)) then
          let rec_name = '<%underscorePath(ClassInf.getStateName(record_state))%>'
          '*((<%rec_name%>*)generic_array_element_addr(&<%loopVar%>, sizeof(<%rec_name%>), 1, <%firstIndex%>++))'
        else
          '<%loopVar%>( <%firstIndex%>++)'
      <<
      while(<%firstIndex%> <=  <%loopVar%>.getDim(1)) {
        <%iteratorName%> = <%addr%>;
        <%guardExp%>
      }
      >>)
  let firstValue = (match ri.path
     case IDENT(name="array") then
       let length = tempDecl("int", &tmpVarDecls)
       let &rangeExpPre += '<%length%> = 0;<%\n%>'
       let _ = (iterators |> iter as REDUCTIONITER(__) =>
         let loopVar = '<%iter.id%>_loopVar'
         let &rangeExpPre += '<%length%> = max(<%length%>, <%loopVar%>.getDim(1));<%\n%>'
         "")
       <<
       <%arrIndex%> = 1;
       <% match typeof(r.expr)
        case T_COMPLEX(complexClassType = record_state) then
          let rec_name = '<%underscorePath(ClassInf.getStateName(record_state))%>'
          'alloc_generic_array(&<%res%>,sizeof(<%rec_name%>),1,<%length%>);'
        case T_ARRAY(__) then
          let dim_vec = tempDecl("std::vector<size_t>",&tmpVarDecls)
          let dimSizes = dims |> dim => match dim
            case DIM_INTEGER(__) then '<%dim_vec%>.push_back(<%integer%>)'
            case DIM_BOOLEAN(__) then '<%dim_vec%>.push_back(2)'
            case DIM_ENUM(__) then '<%dim_vec%>.push_back(<%size%>)'
            case DIM_EXP(exp = exp) then
              let val = daeExp(exp, context, &rangeExpPre, &tmpVarDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
              '<%dim_vec%>.push_back(<%val%>)'
            else error(sourceInfo(), 'array reduction unable to generate code for element of unknown dimension sizes; type <%unparseType(typeof(r.expr))%>: <%ExpressionDumpTpl.dumpExp(r.expr,"\"")%>')
            ; separator = "; "
          <<
          <%dim_vec%>.push_back(<%length%>);
          <%dimSizes%>;
          <%res%>.setDims(<%dim_vec%>);
          >>

        else
          '<%res%>.setDims(<%length%>);'%>

       >>
     else if ri.defaultValue then
     <<
     <%&preDefault%>
     <%res%> = <%defaultValue%>; /* defaultValue */
     >>
     else
     <<
     <%foundFirst%> = 0; /* <%dotPath(ri.path)%> lacks default-value */
     >>)
  let loop =
    <<
    while(1) {
      <%endLoop%> = <%listLength(iterators)%>;
      <%loopHeadIter%>
      if (<%endLoop%> == 0) {
        <%&bodyExpPre%>
        <%foldExp%>
      } <% match iterators case _::_ then
      <<
      else if (<%endLoop%> == <%listLength(iterators)%>) {
        break;
      } else {
        throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Internal error");
      }
      >> %>
    }
    >>
  let &preExp += <<
  {
    <%&tmpVarDecls%>
    <%&rangeExpPre%>
    <%firstValue%>
    <% if resTail then '<%resTail%> = &<%res%>;' %>
    <%loop%>
    <% if not ri.defaultValue then 'if (!<%foundFirst%>) throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Internal error");' %>
    <% if resTail then '*<%resTail%> = NULL;' %>
    <% resTmp %> = <% res %>;
  }<%\n%>
  >>
  resTmp)
  else error(sourceInfo(), 'Code generation does not support multiple iterators: <%ExpressionDumpTpl.dumpExp(exp,"\"")%>')
end daeExpReduction;


template daeExpSize(Exp exp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                    Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a size expression."
::=
  match exp
  case SIZE(exp=CREF(__), sz=SOME(dim)) then
    let expPart = daeExp(exp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let dimPart = daeExp(dim, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    '<%expPart%>.getDim(<%dimPart%>)'
  case SIZE(exp=CREF(__)) then
    let expPart = daeExp(exp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let tmp = tempDecl("vector<size_t>", &varDecls)
    let &preExp +=
      <<
      <%tmp%> = <%expPart%>.getDims();
      DynArrayDim1<int> <%tmp%>_size(<%tmp%>.size());
      for (size_t <%tmp%>_i = 1; <%tmp%>_i <= <%tmp%>.size(); <%tmp%>_i++)
        <%tmp%>_size(<%tmp%>_i) = (int)<%tmp%>[<%tmp%>_i-1];<%\n%>
      >>
    '<%tmp%>_size'
  else "size(X) not implemented"
end daeExpSize;


template daeExpMatrix(Exp exp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs,
                      Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a matrix expression."
::=
  match exp
  case MATRIX(matrix={{}})  // special case for empty matrix: create dimensional array Real[0,1]
  case MATRIX(matrix={})    // special case for empty array: create dimensional array Real[0,1]
    then
    let typestr = expTypeShort(ty)
    let arrayTypeStr = 'DynArrayDim2<<%typestr%>>'
    let tmp = tempDecl(arrayTypeStr, &varDecls /*BUFD*/)
   // let &preExp += 'alloc_<%arrayTypeStr%>(&<%tmp%>, test2, 0, 1);<%\n%>'
    tmp
   case m as MATRIX(matrix=(row1::_)) then
     let arrayTypeStr = expTypeShort(ty)
     let StatArrayDim = expTypeArrayIf(ty)
     let &tmp = buffer "" /*BUFD*/
     let arrayVar = tempDecl(arrayTypeStr, &tmp /*BUFD*/)
     let &vals = buffer "" /*BUFD*/
     let dim_cols = listLength(row1)

/*
/////////////////////////////////////////////////NonCED
    let params = (m.matrix |> row =>
        let vars = daeExpMatrixRow(row, context, &varDecls,&preExp,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,useFlatArrayNotation)
        '<%vars%>'
      ;separator=",")
  let &preExp += '
    <%StatArrayDim%><%arrayVar%>;
    <%arrayTypeStr%> <%arrayVar%>_data[]={<%params%>};
    <%arrayVar%>.assign( <%arrayVar%>_data );<%\n%>'
   arrayVar
/////////////////////////////////////////////////NonCED
*/

///////////////////////////////////////////////CED
 let matrixassign = match m.matrix
    case row::_ then
        let vars = "NO_ASSIGN" //daeExpMatrixRow(m.matrix,context,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName)
        match vars
        case "NO_ASSIGN"
        then
           let params = (m.matrix |> row =>
           let vars = daeExpMatrixRow2(row, context, &varDecls, &preExp, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
              '<%vars%>'
           ;separator=",")
           let &preExp +=
             <<
             //default matrix assign
             <%StatArrayDim%> <%arrayVar%>;
             <%arrayTypeStr%> <%arrayVar%>_data[] = {<%params%>};
             assignRowMajorData(<%arrayVar%>_data, <%arrayVar%>);<%\n%>
             >>
           ''
        else
           let &preExp +=
             <<
             //optimized matrix assign
             <%StatArrayDim%> <%arrayVar%>;
             <%arrayVar%>.assign( <%vars%> );<%\n%>
             >>
        ''
  end match


  //let &preExp += '
 //  <%StatArrayDim%><%arrayVar%>;
 //   <%arrayVar%>.assign( <%matrixassign%> );<%\n%>'


     arrayVar
end daeExpMatrix;


template daeExpMatrixRow2(list<Exp> row, Context context, Text &varDecls, Text &preExp, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                          Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Helper to daeExpMatrix."
::=
   let varLstStr = (row |> e =>
      let expVar = daeExp(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      '<%expVar%>'
    ;separator=",")
  varLstStr
end daeExpMatrixRow2;
/////////////////////////////////////////////////CED

/*
/////////////////////////////////////////////////NonCED functions
template daeExpMatrixRow(list<Exp> row,
                         Context context,
                         Text &varDecls ,Text &preExp ,SimCode simCode, Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,Boolean useFlatArrayNotation)
 "Helper to daeExpMatrix."
::=

   let varLstStr = (row |> e =>

      let expVar = daeExp(e, context, &preExp , &varDecls ,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,useFlatArrayNotation)
      '<%expVar%>'
    ;separator=",")
  varLstStr
end daeExpMatrixRow;
/////////////////////////////////////////////////NonCED functions
*/

////////////////////////////////////////////////////////////////////////CED Functions
template daeExpMatrixRow(list<list<Exp>> matrix,Context context,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace,Text stateDerVectorName /*=__zDot*/)
 "Helper to daeExpMatrix."
::=
if isCrefListWithEqualIdents(List.flatten(matrix)) then
  match matrix
  case row::_ then
      daeExpMatrixName(row,context,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName)
  else
   "NO_ASSIGN"
   end match
  else
   "NO_ASSIGN"
end daeExpMatrixRow;

template daeExpMatrixName(list<Exp> row,Context context,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl, Text stateDerVectorName /*=__zDot*/, Text extraFuncsNamespace)
::=
  let &varDecls = buffer "" /*BUFD*/
  let &preExp = buffer "" /*BUFD*/
  match row
   case CREF(componentRef = cr)::_ then
      contextCref(crefStripLastSubs(cr),context,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, false)
   /*
   match context
   case FUNCTION_CONTEXT(__) then
    cref2(cr,false) //daeExpMatrixName2(cr) //assign array complete to the function therefore false as second argument
   else
   "_"+cref2(cr,false)//daeExpMatrixName2(cr) //assign array complete to function therefore false as second argument
  else
  "NO_ASSIGN"
  */
end daeExpMatrixName;


template daeExpMatrixName2(ComponentRef cr)
::=

  match cr
  case CREF_IDENT(__) then
    '<%ident%>'
 case CREF_QUAL(__) then               '<%ident%><%subscriptsToCStrForArray(subscriptLst)%>_P_<%daeExpMatrixName2(componentRef)%>'

  case WILD(__) then ' '
  else "CREF_NOT_IDENT_OR_QUAL"
end daeExpMatrixName2;


template daeExpArray(Exp exp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                     Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for an array expression."
::=
match exp
case ARRAY(array=_::_, ty = arraytype) then
  let arrayTypeStr = expTypeShort(ty)
  let ArrayType = expTypeArrayIf(ty)
  let &tmpVar = buffer ""
  let arrayVar = tempDecl(arrayTypeStr, &tmpVar /*BUFD*/)
  let arrayassign =  if scalar then
                     let params =    daeExpArray2(array,arrayVar,ArrayType,arrayTypeStr,context,preExp,varDecls,simCode, &extraFuncs,&extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
                          ""
                      else
                       let &varDecls += '<%ArrayType%> <%arrayVar%>;<%\n%>'
                       daeExpArray3(array, arrayVar, ArrayType, context, preExp, varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  arrayVar
case ARRAY(__) then
  let arrayTypeStr = expTypeShort(ty)
  let arrayDef = expTypeArrayIf(ty)
  let &tmpdecl = buffer ""
  let arrayVar = tempDecl(arrayTypeStr, &tmpdecl )
  let &tmpVar = buffer ""
   let &preExp += '
   //tmp array
   <%arrayDef%><%arrayVar%>;<%\n%>'
  arrayVar
end daeExpArray;



template daeExpArray3(list<Exp> array,  String arrayVar, String ArrayType, Context context, Text &preExp,
                     Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for an array expression."
::=
let arraycreate = (array |> e hasindex i0 fromindex 1 =>
       let subArraycall = daeExp(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
       <<
       <%arrayVar%>.append(<%i0%>, <%subArraycall%>,<%listLength(array)%>);
       >> ;separator="\n")
       let &preExp +=
       <<
         <%arraycreate%>
         <%\n%>
       >>
arraycreate
end daeExpArray3;





/*
Array creation template functions, which splits the array creation code in separate methods
*/
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//template daeExpArray(Exp exp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
//                     Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
// "Generates code for an array expression."
//::=
//match exp
//case ARRAY(array=_::_, ty = arraytype) then
//  let arrayTypeStr = expTypeShort(ty)
//  let ArrayType = expTypeArrayIf(ty)
//  let &tmpVar = buffer ""
//  let arrayVar = tempDecl(arrayTypeStr, &tmpVar /*BUFD*/)
//  let arrayassign =  if scalar then
//                     let params =    daeExpArray2(array,arrayVar,ArrayType,arrayTypeStr,context,preExp,varDecls,simCode, &extraFuncs,&extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
//                          ""
//                      else
//                              let funcCalls = daeExpSubArray(array, arrayVar, ArrayType, context, preExp, varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
//                              let &extraFuncsDecl += 'void createArray_<%arrayVar%>(<%ArrayType%>& <%arrayVar%>);<%\n%>'
//                              let &extraFuncs +=
//                               <<
//                               void <%extraFuncsNamespace%>::createArray_<%arrayVar%>(<%ArrayType%>& <%arrayVar%>)
//                               {
//                                 <%arrayVar%>.setDims(<%allocateDimensions(arraytype,context)%>);
//                                 <%funcCalls%>
//                               }<%\n%>
//                               >>
//                               <<
//                               <%ArrayType%> <%arrayVar%>;
//                               createArray_<%arrayVar%>(<%arrayVar%>);<%\n%>
//                               >>
//
//  let &preExp += '<%arrayassign%>'
//  arrayVar
//case ARRAY(__) then
//  let arrayTypeStr = expTypeShort(ty)
//  let arrayDef = expTypeArrayIf(ty)
//  let &tmpdecl = buffer ""
//  let arrayVar = tempDecl(arrayTypeStr, &tmpdecl )
//  let &tmpVar = buffer ""
//   let &preExp += '
//   //tmp array
//   <%arrayDef%><%arrayVar%>;<%\n%>'
//  arrayVar
//end daeExpArray;
//
//template daeExpSubArray(list<Exp> array, String arrayVar, String ArrayType, Context context, Text &preExp, Text &varDecls, SimCode simCode,
//                        Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
// "Generates code for an array expression."
//::=
//(List.partition(array,50) |> subarray hasindex i0 fromindex 0 =>
//   daeExpSubArray2(subarray,i0,50,arrayVar,ArrayType,context,preExp,varDecls,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
//   ;separator ="\n")
//end daeExpSubArray;
//
//template daeExpSubArray2(list<Exp> array, Integer idx, Integer multiplicator, String arrayVar, String ArrayType, Context context, Text &preExp,
//                     Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
// "Generates code for an array expression."
//::=
//let func = 'void createArray_<%arrayVar%>_<%idx%>(<%ArrayType%>& <%arrayVar%>);'
//let &extraFuncsDecl += '<%func%><%\n%>'
//let funcCall = 'createArray_<%arrayVar%>_<%idx%>(<%arrayVar%>);'
//let &funcVarDecls = buffer ""
//let &preExpSubArrays = buffer ""
//let funcs = (array |> e hasindex i0 fromindex intAdd(intMul(idx, multiplicator),1) =>
//       let subArraycall = daeExp(e, context, &preExpSubArrays, &funcVarDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
//       <<
//       <%arrayVar%>.append(<%i0%>, <%subArraycall%>);
//       >> ;separator="\n")
//       let &extraFuncs +=
//       <<
//       void <%extraFuncsNamespace%>::createArray_<%arrayVar%>_<%idx%>(<%ArrayType%>& <%arrayVar%>)
//       {
//         <%funcVarDecls%>
//         <%preExpSubArrays%>
//         <%funcs%>
//       }<%\n%>
//       >>
//funcCall
//end daeExpSubArray2;

template daeExpArray2(list<Exp> array,String arrayVar,String ArrayType,String arrayTypeStr, Context context, Text &preExp,
                     Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for an array expression."
::=
let params = (array |> e =>  '<%daeExp(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")
let &preExp +=
  <<
  <%arrayTypeStr%> <%arrayVar%>_data[]={<%params%>};
  <%ArrayType%> <%arrayVar%>(<%arrayVar%>_data);<%\n%>
  >>

params
end daeExpArray2;

template daeExpAsub(Exp inExp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                    Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for an asub expression."
::=
  match expTypeFromExpShort(inExp)
  case "metatype" then
  // MetaModelica Array
    (match inExp case ASUB(exp=e, sub={idx}) then
      let e1 = daeExp(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      let idx1 = daeExp(idx, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      'arrayGet(<%e1%>,<%idx1%>) /* DAE.ASUB */')
  // Modelica Array
  else
  match inExp

  case ASUB(exp=ASUB(__)) then
    error(sourceInfo(),'Nested array subscripting *should* have been handled by the routine creating the asub, but for some reason it was not: <%ExpressionDumpTpl.dumpExp(exp,"\"")%>')

  // Faster asub: Do not construct a whole new array just to access one subscript
  case ASUB(exp=exp as ARRAY(scalar=true), sub={idx}) then
    let res = tempDecl(expTypeFromExpModelica(exp),&varDecls)
    let idx1 = daeExp(idx, context, &preExp, &varDecls,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let expl = (exp.array |> e hasindex i1 fromindex 1 =>
      let &caseVarDecls = buffer ""
      let &casePreExp = buffer ""
      let v =daeExp(e, context, &casePreExp, &caseVarDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
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
   '<%res%>'

  case ASUB(exp=RANGE(ty=t), sub={idx}) then
    error(sourceInfo(),'ASUB_EASY_CASE <%ExpressionDumpTpl.dumpExp(exp,"\"")%>')

 case ASUB(exp=ecr as CREF(__), sub=subs) then
    let arrName =  daeExpCrefRhs(buildCrefExpFromAsub(ecr, subs), context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    match context case FUNCTION_CONTEXT(__)  then
      arrName
    else
      '<%arrayScalarRhs(ecr.ty, subs, arrName, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
  case ASUB(exp=e, sub=indexes) then
  let exp = daeExp(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  // let typeShort = expTypeFromExpShort(e)
  let expIndexes = (indexes |> index => '<%daeExpASubIndex(index, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=",")
   //'<%typeShort%>_get<%match listLength(indexes) case 1 then "" case i then '_<%i%>D'%>(&<%exp%>, <%expIndexes%>)'
  '(<%exp%>)(<%expIndexes%>)'
  case exp then
    error(sourceInfo(),'OTHER_ASUB <%ExpressionDumpTpl.dumpExp(exp,"\"")%>')
end daeExpAsub;



template daeExpASubIndex(Exp exp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                         Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match exp
  case ICONST(__) then integer
  case ENUM_LITERAL(__) then index
  else daeExp(exp, context, &preExp, &varDecls, simCode ,&extraFuncs ,&extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
end daeExpASubIndex;


template arrayScalarRhs(Type ty, list<Exp> subs, String arrName, Context context,
               Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Helper to daeExpAsub."
::=
  /* match exp
   case ASUB(exp=ecr as CREF(__)) then*/
  let arrayType = expTypeShort(ty)
  let dimsLenStr = listLength(subs)
  let dimsValuesStr = (subs |> exp =>
      daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ;separator=",")
    //previous multi_array ;separator="][")


  match arrayType
    case "metatype_array" then
      'arrayGet(<%arrName%>,<%dimsValuesStr%>) /*arrayScalarRhs*/'
    else
      //ToDo before used <%arrayCrefCStr(ecr.componentRef)%>[<%dimsValuesStr%>]
      << <%arrName%>(<%dimsValuesStr%>) >>
end arrayScalarRhs;

template daeExpCast(Exp exp, Context context, Text &preExp /*BUFP*/,
                    Text &varDecls /*BUFP*/,SimCode simCode, Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a cast expression."
::=
match exp
case CAST(__) then
  let expVar = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  match ty
  case T_INTEGER(__)   then '((int)<%expVar%>)'
  case T_REAL(__)  then '((double)<%expVar%>)'
  case T_ENUMERATION(__)   then '((int)<%expVar%>)'
  case T_BOOL(__)   then '((bool)<%expVar%>)'
  case T_ARRAY(dims=dims) then
    let from = expTypeFromExpShort(exp)
    let to = expTypeShort(ty)
    let tvar = tempDecl(expTypeArrayDims(ty, dims), &varDecls /*BUFD*/)
    let &preExp += 'cast_array<<%from%>, <%to%>>(<%expVar%>, <%tvar%>);<%\n%>'
    '<%tvar%>'
  case T_COMPLEX(varLst=vl,complexClassType=rec as RECORD(__))   then
    let tvar = tempDecl(underscorePath(rec.path)+"Type", &varDecls /*BUFD*/)
    let &preExp += '<%structParams(expVar,tvar,vl)%><%\n%>'
    '<%tvar%>'
  else
    '(<%expVar%>) /* could not cast, using the variable as it is */'
end daeExpCast;


template structParams(String structName,String varName,list<Var>  exps)
::=
   let  params = (exps |> e => match e
    case TYPES_VAR(__) then
    '<%varName%>.<%name%>_ = <%structName%>.<%name%>_;'
    ;separator="\n" )
  params
end structParams;

template daeExpRecord(Exp rec, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                      Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  match rec
  case RECORD(__) then
  let name = tempDecl(underscorePath(path) + "Type", &varDecls)
  let ass = threadTuple(exps,comp) |>  (exp,compn) =>
    let compnStr = crefStr(makeUntypedCrefIdent(compn))
    '<%name%>.<%compnStr%> = <%daeExp(exp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>;<%\n%>'
  let &preExp += ass
  name
end daeExpRecord;

template daeExpCall(Exp call, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/,SimCode simCode, Text& extraFuncs,Text& extraFuncsDecl,
                    Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a function call."
::=
  //<%name%>
  match call
  // special builtins

  case CALL(path=IDENT(name="edge"),
            expLst={e1}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    '_discrete_events.edge(<%var1%>)'

  case CALL(path=IDENT(name="pre"),
            expLst={arg as CREF(__)}) then
    let var1 = daeExp(arg, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    '_discrete_events->pre(<%var1%>)'

  case CALL(path=IDENT(name="previous"), expLst={arg as CREF(__)}) then
    '<%daeExp(crefExp(crefPrefixPrevious(arg.componentRef)), context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'

  case CALL(path=IDENT(name="firstTick")) then
    '(<%contextSystem(context)%>_clockStart[clockIndex - 1] || <%contextSystem(context)%>_clockSubactive[clockIndex - 1])'

  case CALL(path=IDENT(name="interval")) then
    '<%contextSystem(context)%>_clockInterval[clockIndex - 1]'

  case CALL(path=IDENT(name="$_clkfire"), expLst={arg as ICONST(__)}) then
    '_time_conditions[<%absoluteClockIdxForBaseClock(arg.integer, getClockedPartitions(simCode))%> - 1 + <%timeEventLength(simCode)%>] = (_simTime > _clockTime[<%arg.integer%> - 1])'

  case CALL(path=IDENT(name="$getPart"), expLst={e1}) then
    daeExp(e1, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)

  case CALL(path=IDENT(name="sample"), expLst={ICONST(integer=index), start, interval}) then
    let &preExp = buffer "" /*BUFD*/
    let eStart = daeExp(start, contextOther, &preExp, &varDecls, simCode, &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let eInterval = daeExp(interval, contextOther, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    match context
     case  ALGLOOP_CONTEXT(genInitialisation=false) then
     '_system->_time_conditions[<%intSub(index, 1)%>]'
     else
     '_time_conditions[<%intSub(index, 1)%>]'
  case CALL(path=IDENT(name="initial") ) then
     match context

    case ALGLOOP_CONTEXT(genInitialisation = false)

        then  '_system->_initial'
    else
          '_initial'
  case CALL(path=IDENT(name="terminal") ) then
     match context

    case ALGLOOP_CONTEXT(genInitialisation = false)

        then  '_system->_terminal'
    else
          '_terminal'

   case CALL(path=IDENT(name="DIVISION"), expLst={e1, e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var3 = Util.escapeModelicaStringToCString(ExpressionDumpTpl.dumpExp(e2,"\""))
    match context
     case ALGLOOP_CONTEXT(genInitialisation = false)
        then
    <<
     division(<%var1%>,<%var2%>,!_system->_initial,"<%var3%>")
    >>
    else
    <<
     division(<%var1%>,<%var2%>,!_initial,"<%var3%>")
    >>
    end match


   case CALL(path=IDENT(name="sign"),
            expLst={e1}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
     'sgn(<%var1%>)'

   case CALL(attr=CALL_ATTR(ty=ty as T_ARRAY(dims=dims)),
            path=IDENT(name="DIVISION_ARRAY_SCALAR"),
            expLst={e1, e2}) then
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then "int"
                        case T_ARRAY(ty=T_ENUMERATION(__)) then "int"
                        else "double"

    let var = tempDecl('multi_array<<%type%>,<%listLength(dims)%>>', &varDecls /*BUFD*/)
    let var1 = daeExp(e1, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var3 = Util.escapeModelicaStringToCString(ExpressionDumpTpl.dumpExp(e2,"\""))
    let &preExp += 'assign_array(<%var%>,divide_array<<%type%>,<%listLength(dims)%>>(<%var1%>, <%var2%>));<%\n%>'
    //let &preExp += 'division_alloc_<%type%>_scalar(&<%var1%>, <%var2%>, &<%var%>, "<%var3%>");<%\n%>'
    '<%var%>'

  case CALL(path=IDENT(name="der"), expLst={arg as CREF(__)}) then
    let var = cref2simvar(arg.componentRef, simCode) |> SIMVAR(index=i) => '__zDot[<%i%>]'
    '<%var%>'

  case CALL(path=IDENT(name="print"), expLst={e1}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    if acceptMetaModelicaGrammar() then 'print(<%var1%>)' else 'puts(<%var1%>)'


  case CALL(path=IDENT(name="integer"), expLst={inExp,index}) then
    let exp = daeExp(inExp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
   // let constIndex = daeExp(index, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace,useFlatArrayNotation)
    'integer(<%exp%>)'


  case CALL(path=IDENT(name="floor"), expLst={inExp,index}, attr=CALL_ATTR(ty = ty)) then
    let exp = daeExp(inExp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    //let constIndex = daeExp(index, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'std::floor(<%exp%>)'
 case CALL(path=IDENT(name="floor"), expLst={inExp}, attr=CALL_ATTR(ty = ty)) then
    let exp = daeExp(inExp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    //let constIndex = daeExp(index, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'std::floor(<%exp%>)'
  case CALL(path=IDENT(name="ceil"), expLst={inExp,index}, attr=CALL_ATTR(ty = ty)) then
    let exp = daeExp(inExp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    //let constIndex = daeExp(index, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'std::ceil(<%exp%>)'
  case CALL(path=IDENT(name="ceil"), expLst={inExp}, attr=CALL_ATTR(ty = ty)) then
    let exp = daeExp(inExp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl , extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    //let constIndex = daeExp(index, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'std::ceil(<%exp%>)'

  case CALL(path=IDENT(name="integer"), expLst={inExp}) then
    let exp = daeExp(inExp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
   'integer(<%exp%>)'

  case CALL(path=IDENT(name="max"), attr=CALL_ATTR(ty = T_REAL(__)), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'max(<%var1%>,<%var2%>)'

  case CALL(path=IDENT(name="max"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'max(<%var1%>,<%var2%>)'

  case CALL(attr=CALL_ATTR(ty = T_REAL(__)),
            path=IDENT(name="min"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'min(<%var1%>,<%var2%>)'

  case CALL(path=IDENT(name="min"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'min(<%var1%>,<%var2%>)'

  case CALL(path=IDENT(name="abs"), expLst={e1}, attr=CALL_ATTR(ty = T_INTEGER(__))) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'std::labs(<%var1%>)'

  case CALL(path=IDENT(name="abs"), expLst={e1}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'std::abs(<%var1%>)'

  case CALL(path=IDENT(name="sqrt"),
            expLst={e1},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")
    (if isPositiveOrZero(e1) then
       let typeStr = expTypeShort(attr.ty )
       let retVar = tempDecl(typeStr, &varDecls /*BUFD*/)
       let &preExp += '<%retVar%> = std::sqrt(<%argStr%>);<%\n%>'

      '<%retVar%>'
    else
        let tmp = tempDecl(expTypeFromExpModelica(e1), &varDecls)
        let cstr = ExpressionDumpTpl.dumpExp(e1,"\"")
        let &preExp +=
          <<
          <%tmp%> = <%argStr%>;
          <%assertCommonVar('<%tmp%> >= 0.0', '"Model error: Argument of sqrt(<%Util.escapeModelicaStringToCString(cstr)%>) should be >= 0"', context, &varDecls, dummyInfo)%>
          >>
       'sqrt(<%tmp%>)')

  // built-in mathematical functions
  case CALL(path=IDENT(name="sin"), expLst={e1})
  case CALL(path=IDENT(name="cos"), expLst={e1})
  case CALL(path=IDENT(name="tan"), expLst={e1})
  case CALL(path=IDENT(name="asin"), expLst={e1})
  case CALL(path=IDENT(name="acos"), expLst={e1})
  case CALL(path=IDENT(name="atan"), expLst={e1})
  case CALL(path=IDENT(name="sinh"), expLst={e1})
  case CALL(path=IDENT(name="cosh"), expLst={e1})
  case CALL(path=IDENT(name="tanh"), expLst={e1})
  case CALL(path=IDENT(name="exp"), expLst={e1})
  case CALL(path=IDENT(name="log"), expLst={e1})
  case CALL(path=IDENT(name="log10"), expLst={e1}) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    'std::<%funName%>(<%argStr%>)'

  case CALL(path=IDENT(name="atan2"),
            expLst={e1,e2},attr=attr as CALL_ATTR(__)) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")

    let retType = 'double'
    let retVar = tempDecl(retType, &varDecls /*BUFD*/)
    let &preExp += '<%retVar%> = std::atan2(<%argStr%>);<%\n%>'
    '<%retVar%>'

  case CALL(path=IDENT(name="smooth"),
            expLst={e1,e2},attr=attr as CALL_ATTR(__)) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    '<%var2%>'

  case CALL(path=IDENT(name="homotopy"),
            expLst={e1,e2},attr=attr as CALL_ATTR(__)) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    '<%var1%>'

  case CALL(path=IDENT(name="homotopyParameter"),
            expLst={},attr=attr as CALL_ATTR(__)) then
     '1.0'

  case CALL(path=IDENT(name="div"), expLst={e1,e2}, attr=CALL_ATTR(ty = T_INTEGER(__))) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'ldiv(<%var1%>,<%var2%>).quot'

  case CALL(path=IDENT(name="div"), expLst={e1,e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'omcpp::trunc(<%var1%>/<%var2%>)'

  case CALL(path=IDENT(name="div"), expLst={e1,e2,index}) then
    // TODO: should trigger event if result changes discontinuously
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'omcpp::trunc(<%var1%>/<%var2%>)'

  case CALL(path=IDENT(name="mod"), expLst={e1,e2,index}, attr=attr as CALL_ATTR(__))
  case CALL(path=IDENT(name="mod"), expLst={e1,e2}, attr=attr as CALL_ATTR(__)) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'modelica_mod_<%expTypeShort(attr.ty)%>(<%var1%>,<%var2%>)'

   case CALL(path=IDENT(name="semiLinear"), expLst={e1,e2,e3}, attr=attr as CALL_ATTR(__)) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var3 = daeExp(e3, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    'semiLinear(<%var1%>,<%var2%>,<%var3%>)'

  case CALL(path=IDENT(name="max"), attr=CALL_ATTR(ty = ty), expLst={array}) then
    //let &tmpVar = buffer "" /*BUFD*/
    let expVar = daeExp(array, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let arr_tp_str = expTypeShort(ty)
    let tvar = tempDecl(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = min_max<<%arr_tp_str%>>(<%expVar%>).second;<%\n%>'
    '<%tvar%>'
  case CALL(path=IDENT(name="sum"), attr=CALL_ATTR(ty = ty), expLst={array}) then
    //let &tmpVar = buffer "" /*BUFD*/
    let expVar = daeExp(array, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let arr_tp_str = expTypeShort(ty)
    let tvar = tempDecl(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = sum_array<<%arr_tp_str%>>(<%expVar%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="min"), attr=CALL_ATTR(ty = ty), expLst={array}) then
    //let &tmpVar = buffer "" /*BUFD*/
    let expVar = daeExp(array, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let arr_tp_str = expTypeShort(ty)
    let tvar = tempDecl(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += '<%tvar%> = min_max<<%arr_tp_str%>>(<%expVar%>).first;<%\n%>'
    '<%tvar%>'

  case call as CALL(path=IDENT(name="vector"), expLst={exp}, attr=CALL_ATTR(ty=ty)) then
    let expVar = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let tvar = match ty
    case T_ARRAY(ty=elty) then
      // use dynamic array as static arrays are treated during translation
      'DynArrayDim1<<%expTypeShort(elty)%>>(<%expVar%>.getNumElems(), ConstArray(<%expVar%>).getData())'
    else
      // this should never happen because it is eliminated during translation
      'StatArrayDim1<<%expTypeShort(ty)%>, 1, true>(&<%expVar%>)'
    end match
    '<%tvar%>'

  case CALL(path=IDENT(name="fill"), expLst=val::dims, attr=attr as CALL_ATTR(__)) then
    let valExp = daeExp(val, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let dimsExp = (dims |> dim =>    daeExp(dim, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation) ;separator=",")

    let ty_str = '<%expTypeShort(attr.ty)%>'
  //previous multi_array
  // let tmp_type_str =  'multi_array<<%ty_str%>,<%listLength(dims)%>>'
    let tmp_type_str =  'DynArrayDim<%listLength(dims)%><<%ty_str%>>'

    let tvar = tempDecl(tmp_type_str, &varDecls /*BUFD*/)

    let &preExp += '<%tvar%>.setDims(<%dimsExp%>);<%\n%>'

    let &preExp += 'fill_array<<%ty_str%>>(<%tvar%>, <%valExp%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="cat"), expLst=dim::a0::arrays, attr=attr as CALL_ATTR(__)) then
    let dim_exp = daeExp(dim, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let& dimstr = buffer ""
    let tmp_type_str = match typeof(a0)
      case ty as T_ARRAY(dims=dims) then
        let &dimstr += listLength(dims)
        'DynArrayDim<%listLength(dims)%><<%expTypeShort(ty)%>>'
        else
        let &dimstr += 'error array dims'
        'array error'
    let ty_str = '<%expTypeShort(attr.ty)%>'
    let tvar = tempDecl(tmp_type_str, &varDecls /*BUFD*/)
    let a0str = daeExp(a0, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let arrays_exp = (arrays |> array =>
    '<%tvar%>_list.push_back(&<%daeExp(array, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>);' ;separator="\n")
    let &preExp +=
      <<
      vector<const BaseArray<<%ty_str%>>*> <%tvar%>_list;
      <%tvar%>_list.push_back(&<%a0str%>);
      <%arrays_exp%>
      cat_array<<%ty_str%>>(<%dim_exp%>, <%tvar%>_list, <%tvar%>);<%\n%>
      >>
    '<%tvar%>'

  case CALL(path=IDENT(name="promote"), expLst={A, n}, attr=attr as CALL_ATTR(ty=ty)) then
  //match A
    //case component as CREF(componentRef=cr, ty=ty) then
    let var1 = daeExp(A, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(n, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    //let temp = tempDeclAssign('const size_t*', &varDecls /*BUFD*/,'<%var1%>.shape()')
    //let temp_ex = tempDecl('std::vector<size_t>', &varDecls /*BUFD*/)
    let arrayType = expTypeArrayIf(ty)
    //let dimstr = listLength(crefSubs(cr))
    let tmp = tempDecl('<%arrayType%>', &varDecls /*BUFD*/)

   // let arr_tp_str = '<%expTypeFromExpArray(A)%>'
    //let tvar = tempDecl(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += 'promote_array(<%var2%>, <%var1%>, <%tmp%>);<%\n%>'

    '<%tmp%> '
   //else
   //'promote array error'
  case CALL(path=IDENT(name="transpose"), expLst={A}) then
    let var1 = daeExp(A, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let type_str = expTypeFromExpShort(A)
    let arr_tp_str = '<%expTypeFromExpArray(A)%>'
    let tvar = tempDecl(arr_tp_str, &varDecls /*BUFD*/)
    let &preExp += 'transpose_array<<%type_str%>>(<%var1%>, <%tvar%>);<%\n%>'
    '<%tvar%>'

   case CALL(path=IDENT(name="cross"), expLst={v1, v2},attr=CALL_ATTR(ty=ty as T_ARRAY(dims=dims))) then
    let var1 = daeExp(v1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(v2, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let type = match ty case T_ARRAY(ty=T_INTEGER(__)) then 'int'
                        case T_ARRAY(ty=T_ENUMERATION(__)) then 'int'
                        else 'double'
    let tvar = tempDecl('multi_array<<%type%>,<%listLength(dims)%>>', &varDecls /*BUFD*/)
    let &preExp += 'assign_array(<%tvar%>,cross_array<<%type%>>(<%var1%>,<%var2%>));<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="identity"), expLst={A}) then
    let var1 = daeExp(A, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let tvar = tempDecl('DynArrayDim2<int>', &varDecls)
    let &preExp += 'identity_alloc(<%var1%>, <%tvar%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="rem"), expLst={e1, e2}) then
    let var1 = daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(e2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let typeStr = expTypeFromExpShort(e1)
    'modelica_rem_<%typeStr%>(<%var1%>,<%var2%>)'


   case CALL(path=IDENT(name="String"),
             expLst={s, format}) then
    let emptybuf = ""
  let tvar = tempDecl("string", &varDecls /*BUFD*/)
    let sExp = daeExp(s, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let formatExp = daeExp(format, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let typeStr = expTypeFromExpModelica(s)
    let &preExp += 'string <%tvar%> = omcpp::to_string(<%sExp%>);<%\n%>'
    '<%tvar%>'

   case CALL(path=IDENT(name="String"),
             expLst={s, minlen, leftjust}) then
    let emptybuf = ""
    let tvar = tempDecl("string", &emptybuf /*BUFD*/)
    let sExp = daeExp(s, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let minlenExp = daeExp(minlen, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let leftjustExp = daeExp(leftjust, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let typeStr = expTypeFromExpModelica(s)
    let &preExp += 'string <%tvar%> = omcpp::to_string(<%sExp%>);<%\n%>'
    '<%tvar%>'


  //hierhier todo
  case CALL(path=IDENT(name="String"),
            expLst={s, minlen, leftjust, signdig}) then
  let emptybuf = ""
    let tvar = tempDecl("string", &emptybuf /*BUFD*/)
    let sExp = daeExp(s, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let minlenExp = daeExp(minlen, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let leftjustExp = daeExp(leftjust, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let signdigExp = daeExp(signdig, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let &preExp +=  'string <%tvar%> = omcpp::to_string(<%sExp%>);<%\n%>'
    '<%tvar%>'

  case CALL(path=IDENT(name="delay"),
            expLst={ICONST(integer=index), e, d, delayMax}) then
    let tvar = tempDecl("double", &varDecls /*BUFD*/)
    let var1 = daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var2 = daeExp(d, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let var3 = daeExp(delayMax, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let &preExp += '<%tvar%> = delay(<%index%>, <%var1%>,  <%var2%>, <%var3%>);<%\n%>'
    '<%tvar%>'


  case CALL(path=IDENT(name="integer"),
            expLst={toBeCasted}) then
    let castedVar = daeExp(toBeCasted, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    '((int)<%castedVar%>)'

   case CALL(path=IDENT(name="Integer"),
             expLst={toBeCasted}) then
    let castedVar = daeExp(toBeCasted, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    '((int)<%castedVar%>)'

  case CALL(path=IDENT(name="clock"), expLst={}) then
    'mmc_clock()'

  case CALL(path=IDENT(name="noEvent"),
            expLst={e1}) then
    daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)

  case CALL(path=IDENT(name="anyString"),
            expLst={e1}) then
    'mmc_anyString(<%daeExp(e1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>)'

  case CALL(path=IDENT(name="mmc_get_field"),
            expLst={s1, ICONST(integer=i)}) then
    let tvar = tempDecl("modelica_metatype", &varDecls /*BUFD*/)
    let expPart = daeExp(s1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let &preExp += '<%tvar%> = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(<%expPart%>), <%i%>));<%\n%>'
    '<%tvar%>'

  case exp as CALL(attr=attr as CALL_ATTR(ty=T_NORETCALL(__))) then
    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")
    let funName = '<%underscorePath(path)%>'
    let &preExp += '<%contextFunName(funName, context)%>(<%argStr%>);<%\n%>'
    ""
    /*Function calls with array return type*/
    case exp as CALL(attr=attr as CALL_ATTR(ty=T_ARRAY(ty=ty,dims=dims))) then

    let argStr = (expLst |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=",")
    let funName = '<%underscorePath(path)%>'
    let retType = '<%funName%>RetType /* undefined */'
    let retVar = tempDecl(retType, &varDecls)
    let &preExp += '<%contextFunName(funName, context)%>(<%argStr%><%if expLst then if retVar then "," %><%retVar%>);<%\n%>'
    '<%retVar%>'
   /*Function calls with tuple return type
   case exp as CALL(attr=attr as CALL_ATTR(ty=T_TUPLE(__))) then
     then  "Tuple not supported yet"
   */
    /*Function calls with default type*/
    case exp as CALL(expLst = explist,attr=attr as CALL_ATTR(ty =ty)) then

    let funName = '<%underscorePath(path)%>'
    /*workaround until we support this*/
    match funName
    case "Modelica_Utilities_Files_loadResource"
    then
    '"noName"'
    else
    /*end workaround*/
    let argStr = (explist |> exp => '<%daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")
    let retType = '<%funName%>RetType /* undefined */'
    let retVar = tempDecl(retType, &varDecls)
    let &preExp += match context case FUNCTION_CONTEXT(__) then'<%funName%>(<%argStr%><%if explist then if retVar then "," %><%if retVar then '<%retVar%>'%>);<%\n%>'
    else '<%contextFunName(funName, context)%>(<%argStr%><%if explist then if retVar then "," %> <%if retVar then '<%retVar%>'%>);<%\n%>'
     '<%retVar%>'

  else
    error(sourceInfo(), 'Code generation does not support daeExpCall(<%ExpressionDumpTpl.dumpExp(call,"\"")%>)')
end daeExpCall;

template daeExpLunary(Exp exp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                      Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a logical unary expression."
::=
match exp
case LUNARY(__) then
  let e = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  match operator
  case NOT(__) then '(!<%e%>)'
end daeExpLunary;

template daeExpLbinary(Exp exp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs,Text& extraFuncsDecl,
                       Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a logical binary expression."
::=
match exp
case LBINARY(__) then
  let e1 = daeExp(exp1, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let e2 = daeExp(exp2, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  match operator
  case AND(__) then '(<%e1%> && <%e2%>)'
  case OR(__)  then '(<%e1%> || <%e2%>)'
  else "daeExpLbinary:ERR"
end daeExpLbinary;

template expTypeFromExpFlag(Exp exp, Integer flag)
::=
  match exp
  case ICONST(__)        then match flag case 8 then "int" case 1 then "int" else "int"
  case RCONST(__)        then match flag case 1 then "double" else "double"
  case SCONST(__)        then if acceptMetaModelicaGrammar() then
                                (match flag case 1 then "metatype" else "modelica_metatype")
                              else
                                (match flag case 1 then "string" else "modelica_string")
  case BCONST(__)        then match flag case 1 then "bool" else "modelica_boolean"
  case ENUM_LITERAL(__)  then match flag case 8 then "int" case 1 then "int" else "int"
  case e as BINARY(__)
  case e as UNARY(__)
  case e as LBINARY(__)
  case e as LUNARY(__)
  case e as RELATION(__) then expTypeFromOpFlag(e.operator, flag)
  case IFEXP(__)         then expTypeFromExpFlag(expThen, flag)
  case CALL(attr=CALL_ATTR(__))          then expTypeFlag(attr.ty, flag)
  case c as RECORD(__)   then expTypeFlag(c.ty, flag)
  case c as ARRAY(__)
  case c as MATRIX(__)
  case c as RANGE(__)
  case c as CAST(__)
  case c as CREF(__)
  case c as CODE(__)     then expTypeFlag(c.ty, flag)
  case ASUB(__)          then expTypeFromExpFlag(exp, flag)
  case REDUCTION(__)     then expTypeFlag(typeof(exp), flag)
  case e as CONS(__)
  case e as LIST(__)
  case e as SIZE(__)     then expTypeFlag(typeof(e), flag)

  case META_TUPLE(__)
  case META_OPTION(__)
  case MATCHEXPRESSION(__)
  case METARECORDCALL(__)
  case BOX(__)           then match flag case 1 then "metatype" else "modelica_metatype"
  case c as UNBOX(__)    then expTypeFlag(c.ty, flag)
  case c as SHARED_LITERAL(__) then expTypeFromExpFlag(c.exp, flag)
  else 'ERROR:expTypeFromExpFlag <%ExpressionDumpTpl.dumpExp(exp,"\"")%> '
end expTypeFromExpFlag;

template expTypeFromOpFlag(Operator op, Integer flag)
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
    expTypeFlag(o.ty, flag)
  case o as AND(__)
  case o as OR(__)
  case o as NOT(__) then
    match flag case 1 then "bool" else "modelica_boolean"
  else "expTypeFromOpFlag:ERROR"
end expTypeFromOpFlag;


template daeExpBinary(Operator it, Exp exp1, Exp exp2, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                      Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let e1 = daeExp(exp1, context, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let e2 = daeExp(exp2, context, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  match it
  case ADD(__) then '(<%e1%> + <%e2%>)'
  case SUB(__) then '(<%e1%> - <%e2%>)'
  case MUL(__) then '(<%e1%> * <%e2%>)'
  case DIV(__) then
   let e2str = Util.escapeModelicaStringToCString(ExpressionDumpTpl.dumpExp(exp2,"\""))
    match context
     case ALGLOOP_CONTEXT(genInitialisation = false)
        then
        <<
        division(<%e1%>,<%e2%>,!_system->_initial,"<%e2str%>")
        >>
       else
        <<
        division(<%e1%>,<%e2%>,!_initial,"<%e2str%>")
        >>
    end match
  case POW(__) then 'std::pow(<%e1%>, <%e2%>)'
  case AND(__) then '(<%e1%> && <%e2%>)'
  case OR(__)  then '(<%e1%> || <%e2%>)'
  case MUL_ARRAY_SCALAR(ty=T_ARRAY(dims=dims)) then
    let type = expTypeShort(ty.ty)
    let tvar = tempDecl(expTypeArrayDims(ty.ty, dims), &varDecls /*BUFD*/)
    let &preExp += 'multiply_array<<%type%>>(<%e1%>, <%e2%>, <%tvar%>);<%\n%>'
    '<%tvar%>'
  case MUL_MATRIX_PRODUCT(ty=T_ARRAY(dims=dims)) then
    let type = expTypeShort(ty.ty)
    let tvar = tempDecl(expTypeArrayDims(ty.ty, dims), &varDecls /*BUFD*/)
    let &preExp += 'multiply_array<<%type%>>(<%e1%>, <%e2%>, <%tvar%>);<%\n%>'
    '<%tvar%>'
  case DIV_ARRAY_SCALAR(ty=T_ARRAY(dims=dims)) then
    let type = expTypeShort(ty.ty)
    let tvar = tempDecl(expTypeArrayDims(ty.ty, dims), &varDecls /*BUFD*/)
    let &preExp += 'divide_array<<%type%>>(<%e1%>, <%e2%>, <%tvar%>);<%\n%>'
    '<%tvar%>'
  case DIV_SCALAR_ARRAY(__) then "daeExpBinary:ERR DIV_SCALAR_ARR not supported"
  case UMINUS(__) then "daeExpBinary:ERR UMINUS not supported"
  case UMINUS_ARR(__) then "daeExpBinary:ERR UMINUS_ARR not supported"
  case ADD_ARR(ty=T_ARRAY(dims=dims)) then
    let type = expTypeShort(ty.ty)
    let tvar = tempDecl(expTypeArrayDims(ty.ty, dims), &varDecls /*BUFD*/)
    let &preExp += 'add_array<<%type%>>(<%e1%>, <%e2%>, <%tvar%>);<%\n%>'
    '<%tvar%>'
  case SUB_ARR(ty=T_ARRAY(dims=dims)) then
    let type = expTypeShort(ty.ty)
    let tvar = tempDecl(expTypeArrayDims(ty.ty, dims), &varDecls /*BUFD*/)
    let &preExp += 'subtract_array<<%type%>>(<%e1%>, <%e2%>, <%tvar%>);<%\n%>'
    '<%tvar%>'
  case MUL_ARR(ty=T_ARRAY(dims=dims)) then
    let type = expTypeShort(ty.ty)
    let tvar = tempDecl(expTypeArrayDims(ty.ty, dims), &varDecls /*BUFD*/)
    let &preExp += 'multiply_array_elem_wise<<%type%>>(<%e1%>, <%e2%>, <%tvar%>);<%\n%>'
    '<%tvar%>'
  case DIV_ARR(ty=T_ARRAY(dims=dims)) then
    let type = expTypeShort(ty.ty)
    let tvar = tempDecl(expTypeArrayDims(ty.ty, dims), &varDecls /*BUFD*/)
    let &preExp += 'divide_array_elem_wise<<%type%>>(<%e1%>, <%e2%>, <%tvar%>);<%\n%>'
    '<%tvar%>'
  case ADD_ARRAY_SCALAR(ty=T_ARRAY(dims=dims)) then
    let type = expTypeShort(ty.ty)
    let tvar = tempDecl(expTypeArrayDims(ty.ty, dims), &varDecls /*BUFD*/)
    let &preExp += 'add_array_scalar<<%type%>>(<%e2%>, <%e1%>, <%tvar%>);<%\n%>'
    '<%tvar%>'
  case SUB_SCALAR_ARRAY(ty=T_ARRAY(dims=dims)) then
    let type = expTypeShort(ty.ty)
    let tvar = tempDecl(expTypeArrayDims(ty.ty, dims), &varDecls /*BUFD*/)
    let &preExp += 'subtract_array_scalar<<%type%>>(<%e2%>, <%e1%>, <%tvar%>);<%\n%>'
    '<%tvar%>'
  case MUL_SCALAR_PRODUCT(__) then
    let type = expTypeShort(ty)
    'dot_array<<%type%>>(<%e1%>, <%e2%>)'
  case DIV_SCALAR_ARRAY(__) then "daeExpBinary:ERR DIV_SCALAR_ARRAY not supported"
  case POW_ARRAY_SCALAR(ty=T_ARRAY(dims=dims)) then
    let tvar = tempDecl(expTypeArrayDims(ty.ty, dims), &varDecls /*BUFD*/)
    let &preExp += 'pow_array_scalar(<%e1%>, <%e2%>, <%tvar%>);<%\n%>'
    '<%tvar%>'
  case POW_SCALAR_ARRAY(__) then "daeExpBinary:ERR POW_SCALAR_ARRAY not supported"
  case POW_ARR(__) then "daeExpBinary:ERR POW_ARR not supported"
  case POW_ARR2(__) then "daeExpBinary:ERR POW_ARR2 not supported"
  case NOT(__) then "daeExpBinary:ERR NOT not supported"
  case LESS(__) then "daeExpBinary:ERR LESS not supported"
  case LESSEQ(__) then "daeExpBinary:ERR LESSEQ not supported"
  case GREATER(__) then "daeExpBinary:ERR GREATER not supported"
  case GREATEREQ(__) then "daeExpBinary:ERR GREATEREQ not supported"
  case EQUAL(__) then "daeExpBinary:ERR EQUAL not supported"
  case NEQUAL(__) then "daeExpBinary:ERR NEQUAL not supported"
  case USERDEFINED(__) then "daeExpBinary:ERR POW_ARR not supported"
  case _   then 'daeExpBinary:ERR <%ExpressionDumpTpl.dumpExp(exp1,"\"")%> <%binopSymbol(it)%> <%ExpressionDumpTpl.dumpExp(exp2,"\"")%>'
end daeExpBinary;


template daeExpSconst(String string, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl,
                      Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a string constant."
::=
  '"<%Util.escapeModelicaStringToCString(string)%>"'
end daeExpSconst;

template daeExpUnary(Exp exp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs,
                     Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a unary expression."
::=
match exp
case UNARY(__) then
  let e = daeExp(exp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  match operator
  case UMINUS(__)     then '(-<%e%>)'
  case UMINUS_ARR(ty=T_ARRAY(ty=T_REAL(__))) then

    let dimensions = (ty.dims |> dim as DIM_INTEGER(integer=i)  =>  '<%i%>';separator=",")
    let listlength = listLength(ty.dims)
  let tmp_type_str =  match dimensions
        case "" then 'DynArrayDim<%listlength%><double>'
        else 'StatArrayDim<%listlength%><double, <%dimensions%>>'


   //previous multi_array let tmp_type_str =  'multi_array<double,<%listLength(ty.dims)%>>'

   let tvar = tempDecl(tmp_type_str, &varDecls /*BUFD*/)
    let &preExp += 'usub_array<double>(<%e%>,<%tvar%>);<%\n%>'
    '<%tvar%>'
  case UMINUS_ARR(ty=T_ARRAY(ty=T_INTEGER(__))) then
    let tmp_type_str =  'multi_array<int,<%listLength(ty.dims)%>>/*multi3*/'
    let tvar = tempDecl(tmp_type_str, &varDecls /*BUFD*/)
    let &preExp += 'usub_array<int>(<%e%>,<%tvar%>);<%\n%>'
    '<%tvar%>'
  case UMINUS_ARR(__) then 'unary minus for non-real arrays not implemented'
  else "daeExpUnary:ERR"
end daeExpUnary;

template daeExpRelation(Exp exp, Context context, Text &preExp,Text &varDecls,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
match exp
case rel as RELATION(__) then
match rel.optionExpisASUB
 case NONE() then
    daeExpRelation2(rel.operator,rel.index,rel.exp1,rel.exp2, context, preExp,varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
 case SOME((exp,i,j)) then
    let e1 = daeExp(rel.exp1, context, &preExp /*BUFC*/, &varDecls /*BUFC*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let e2 = daeExp(rel.exp2, context, &preExp /*BUFC*/, &varDecls /*BUFC*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    match context
    case ALGLOOP_CONTEXT(genInitialisation = false) then
       match rel.operator
       case LESS(__) then
          '_system->getCondition(<%rel.index%>) && (<%e1%> < <%e2%>)'

        case LESSEQ(__) then
          '_system->getCondition(<%rel.index%>) && (<%e1%> <= <%e2%>)'

        case GREATER(__) then
          '_system->getCondition(<%rel.index%>) && (<%e1%> > <%e2%>)'

        case GREATEREQ(__) then
         '_system->getCondition(<%rel.index%>)  && (<%e1%> >= <%e2%>)'
            end match
   else
          match rel.operator
        case LESS(__) then
          '(<%e1%> < <%e2%>)'

        case LESSEQ(__) then
          '(<%e1%> <= <%e2%>)'

        case GREATER(__) then
          '(<%e1%> > <%e2%>)'

        case GREATEREQ(__) then
         '(<%e1%> >= <%e2%>)'
            end match
end daeExpRelation;


template daeExpRelation3(Context context,Integer index) ::=
match context
    case ALGLOOP_CONTEXT(genInitialisation = false)
        then  <<_system->getCondition(<%index%>)>>
    else
       <<getCondition(<%index%>)>>
end daeExpRelation3;


template daeExpRelation2(Operator op, Integer index,Exp exp1, Exp exp2, Context context, Text &preExp,Text &varDecls,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation) ::=
  let e1 = daeExp(exp1, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let e2 = daeExp(exp2, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  match index
  case -1 then
     match op
    case LESS(ty = T_BOOL(__))        then '(!<%e1%> && <%e2%>)'
    case LESS(ty = T_STRING(__))      then "# string comparison not supported\n"
    case LESS(ty = T_INTEGER(__))
    case LESS(ty = T_REAL(__))        then '(<%e1%> < <%e2%>)'
    case LESS(ty = T_ENUMERATION(__))      then '(<%e1%> < <%e2%>)'

    case GREATER(ty = T_BOOL(__))     then '(<%e1%> && !<%e2%>)'
    case GREATER(ty = T_STRING(__))   then "# string comparison not supported\n"
    case GREATER(ty = T_INTEGER(__))
    case GREATER(ty = T_REAL(__))     then '(<%e1%> > <%e2%>)'
     case GREATER(ty = T_ENUMERATION(__))   then '(<%e1%> > <%e2%>)'

    case LESSEQ(ty = T_BOOL(__))      then '(!<%e1%> || <%e2%>)'
    case LESSEQ(ty = T_STRING(__))    then "# string comparison not supported\n"
    case LESSEQ(ty = T_INTEGER(__))
    case LESSEQ(ty = T_REAL(__))       then '(<%e1%> <= <%e2%>)'
    case LESSEQ(ty = T_ENUMERATION(__))    then '(<%e1%> <= <%e2%>)'

    case GREATEREQ(ty = T_BOOL(__))   then '(<%e1%> || !<%e2%>)'
    case GREATEREQ(ty = T_STRING(__)) then "# string comparison not supported\n"
    case GREATEREQ(ty = T_INTEGER(__))
    case GREATEREQ(ty = T_REAL(__))   then '(<%e1%> >= <%e2%>)'
     case GREATEREQ(ty = T_ENUMERATION(__)) then '(<%e1%> >= <%e2%>)'

    case EQUAL(ty = T_BOOL(__))       then '((!<%e1%> && !<%e2%>) || (<%e1%> && <%e2%>))'
    case EQUAL(ty = T_STRING(__))
    case EQUAL(ty = T_INTEGER(__))
    case EQUAL(ty = T_REAL(__))       then '(<%e1%> == <%e2%>)'
    case EQUAL(ty = T_ENUMERATION(__))     then '(<%e1%> == <%e2%>)'

    case NEQUAL(ty = T_BOOL(__))      then '((!<%e1%> && <%e2%>) || (<%e1%> && !<%e2%>))'
    case NEQUAL(ty = T_STRING(__))
    case NEQUAL(ty = T_INTEGER(__))
    case NEQUAL(ty = T_REAL(__))      then '(<%e1%> != <%e2%>)'
    case NEQUAL(ty = T_ENUMERATION(__))    then '(<%e1%> != <%e2%>)'

    case _                            then "daeExpRelation:ERR"
      end match
  case _ then
     match op
    case LESS(ty = T_BOOL(__))        then daeExpRelation3(context,index)
    case LESS(ty = T_STRING(__))      then "# string comparison not supported\n"
    case LESS(ty = T_INTEGER(__))
    case LESS(ty = T_REAL(__))        then daeExpRelation3(context,index)

    case GREATER(ty = T_BOOL(__))     then daeExpRelation3(context,index)
    case GREATER(ty = T_STRING(__))   then "# string comparison not supported\n"
    case GREATER(ty = T_INTEGER(__))
    case GREATER(ty = T_REAL(__))     then daeExpRelation3(context,index)

    case LESSEQ(ty = T_BOOL(__))      then daeExpRelation3(context,index)
    case LESSEQ(ty = T_STRING(__))    then "# string comparison not supported\n"
    case LESSEQ(ty = T_INTEGER(__))
    case LESSEQ(ty = T_REAL(__))       then daeExpRelation3(context,index)

    case GREATEREQ(ty = T_BOOL(__))   then daeExpRelation3(context,index)
    case GREATEREQ(ty = T_STRING(__)) then "# string comparison not supported\n"
    case GREATEREQ(ty = T_INTEGER(__))
    case GREATEREQ(ty = T_REAL(__))   then daeExpRelation3(context,index)

    case EQUAL(ty = T_BOOL(__))       then daeExpRelation3(context,index)
    case EQUAL(ty = T_STRING(__))
    case EQUAL(ty = T_INTEGER(__))
    case EQUAL(ty = T_REAL(__))       then daeExpRelation3(context,index)

    case NEQUAL(ty = T_BOOL(__))      then daeExpRelation3(context,index)
    case NEQUAL(ty = T_STRING(__))
    case NEQUAL(ty = T_INTEGER(__))
    case NEQUAL(ty = T_REAL(__))      then daeExpRelation3(context,index)
    case _                         then "daeExpRelationCondition:ERR"
      end match
end daeExpRelation2;


template daeExpIf(Exp cond, Exp then_, Exp else_, Context context, Text &preExp, Text &varDecls,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation) ::=
  let condExp = daeExp(cond, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let &preExpThen = buffer ""
  let eThen = daeExp(then_, context, &preExpThen, &varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  let &preExpElse = buffer ""
  let eElse = daeExp(else_, context, &preExpElse /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      //let resVarType = expTypeFromExpArrayIf(else_,context,preExp,varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace)
      let resVar  = expTypeFromExpArrayIf(else_,context,preExp,varDecls,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      /*previous multi_array instead of .assign:
    'assign_array(<%resVar%>,<%eThen%>);'
    */
    let &preExp +=
      <<
      if <%encloseInParantheses(condExp)%> {
        <%preExpThen%>
        <% match typeof(then_)
            case T_ARRAY(dims=dims) then
              '<%resVar%>.assign(<%eThen%>);'
                else
                '<%resVar%> = <%eThen%>;'
                %>
      } else {
        <%preExpElse%>
        <%match typeof(else_)
            case T_ARRAY(dims=dims) then
              '<%resVar%>.assign(<%eElse%>);'
                else
                '<%resVar%> = <%eElse%>;'
        %>
      }<%\n%>
      >>
      resVar
end daeExpIf;
template expTypeFromExpArrayIf(Exp exp, Context context, Text &preExp, Text &varDecls,SimCode simCode,
                               Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for an array expression."
::=
match exp
case ARRAY(__) then
  let arrayTypeStr = expTypeShort(ty)
  let StatArrayDim = expTypeArrayIf(ty)
  let &tmpdecl = buffer "" /*BUFD*/
  let arrayVar = tempDecl(arrayTypeStr, &tmpdecl /*BUFD*/)
  // let scalarPrefix = if scalar then "scalar_" else ""
  //let scalarRef = if scalar then "&" else ""
  let &tmpVar = buffer ""
  let params = (array |> e =>
    '<%daeExp(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
   ;separator=", ")
   /* previous multi_array
      //tmp array
   <%StatArrayDim%><%arrayVar%>(boost::extents[<%listLength(array)%>]);
   <%arrayVar%>.reindex(1);'
   */
   let &preExp += '
   //tmp array
   <%StatArrayDim%><%arrayVar%>;/*testarray6*/<%\n%>'
  arrayVar
  else
    match typeof(exp)
      case ty as T_ARRAY(dims=dims) then
    // previous multi_array let resVarType = 'multi_array<<%expTypeShort(ty)%>,<%listLength(dims)%>>'
      let resVarType = 'DynArrayDim<%listLength(dims)%><<%expTypeShort(ty)%>>'//TODO evtl statarray
       let resVar = tempDecl(resVarType, &varDecls /*BUFD*/)

      resVar
     else
    let resVarType = expTypeFlag(typeof(exp), 2)
    let resVar = tempDecl(resVarType, &varDecls /*BUFD*/)
   resVar
   end match
  end match
end expTypeFromExpArrayIf;



template expTypeFromExp(Exp it) ::=
  match it
  case ICONST(__)    then "int"
  case ENUM_LITERAL(__)    then "int"
  case RCONST(__)    then "double"
  case SCONST(__)    then "string"
  case BCONST(__)    then "bool"
  case BINARY(__)
  case UNARY(__)
  case LBINARY(__)
  case LUNARY(__)     then expTypeFromOp(operator)
  case RELATION(__)   then "bool" //TODO: a HACK, it was expTypeFromOp(operator)
  case IFEXP(__)      then expTypeFromExp(expThen)
  case CALL(attr=CALL_ATTR(__))       then expTypeShort(attr.ty)
  case ARRAY(__)
  case MATRIX(__)
  case RANGE(__)
  case CAST(__)
  case CREF(__)
  case CODE(__)       then expTypeShort(ty)
  case ASUB(__)       then expTypeFromExp(exp)
  case REDUCTION(__)  then expTypeFromExp(expr)

  case TUPLE(__) then "expTypeFromExp:ERROR TUPLE unsupported"
  case TSUB(__) then "expTypeFromExp:ERROR TSUB unsupported"
  case SIZE(__) then "expTypeFromExp:ERROR SIZE unsupported"

  /* Part of MetaModelica extension. KS */
  case LIST(__) then "expTypeFromExp:ERROR LIST unsupported"
  case CONS(__) then "expTypeFromExp:ERROR CONS unsupported"
  case META_TUPLE(__) then "expTypeFromExp:ERROR META_TUPLE unsupported"
  case META_OPTION(__) then "expTypeFromExp:ERROR META_OPTION unsupported"
  case METARECORDCALL(__) then "expTypeFromExp:ERROR METARECORDCALL unsupported"
  case MATCHEXPRESSION(__) then "expTypeFromExp:ERROR MATCHEXPRESSION unsupported"
  case BOX(__) then "expTypeFromExp:ERROR BOX unsupported"
  case UNBOX(__) then "expTypeFromExp:ERROR UNBOX unsupported"
  case SHARED_LITERAL(__) then expTypeFromExp(exp)
  case PATTERN(__) then "expTypeFromExp:ERROR PATTERN unsupported"

  case _          then "expTypeFromExp:ERROR"
end expTypeFromExp;


template expTypeFromOp(Operator it) ::=
  match it
  case ADD(__)
  case SUB(__)
  case MUL(__)
  case DIV(__)
  case POW(__)
  case UMINUS(__)
  case UMINUS_ARR(__)
  case ADD_ARR(__)
  case SUB_ARR(__)
  case MUL_ARR(__)
  case DIV_ARR(__)
  case MUL_ARRAY_SCALAR(__)
  case ADD_ARRAY_SCALAR(__)
  case SUB_SCALAR_ARRAY(__)
  case MUL_SCALAR_PRODUCT(__)
  case MUL_MATRIX_PRODUCT(__)
  case DIV_ARRAY_SCALAR(__)
  case DIV_SCALAR_ARRAY(__)
  case POW_ARRAY_SCALAR(__)
  case POW_SCALAR_ARRAY(__)
  case POW_ARR(__)
  case POW_ARR2(__)
  case LESS(__)
  case LESSEQ(__)
  case GREATER(__)
  case GREATEREQ(__)
  case EQUAL(__)
  case NEQUAL(__)       then  expTypeShort(ty)
  case AND(__)
  case OR(__)
  case NOT(__) then "bool"
  case _ then "expTypeFromOp:ERROR"
end expTypeFromOp;




template algStmtTupleAssign(DAE.Statement stmt, Context context, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates a tuple assigment algorithm statement."
::=
match stmt
case STMT_TUPLE_ASSIGN(exp=CALL(__)) then
  let &preExp = buffer "" /*BUFD*/
  let crefs = (expExpLst |> e => ExpressionDumpTpl.dumpExp(e,"\"") ;separator=", ")
  let marker = '(<%crefs%>) = <%ExpressionDumpTpl.dumpExp(exp,"\"")%>'
  let retStruct = daeExp(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  //previous multi_array let rhsStr = 'get<<%i1%>>(<%retStruct%>.data)'

  let lhsCrefs = (expExpLst |> cr hasindex i1 fromindex 0 =>
                    let rhsStr = 'get<<%i1%>>(<%retStruct%>.data)'
                    writeLhsCref(cr, rhsStr, context, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
                  ;separator="\n";empty)
  <<
  // algStmtTupleAssign: preExp <%marker%>
  <%preExp%>
  // algStmtTupleAssign: writeLhsCref
  <%lhsCrefs%>
  >>

else error(sourceInfo(), 'algStmtTupleAssign failed')
end algStmtTupleAssign;



template error(builtin.SourceInfo srcInfo, String errMessage)
"Example source template error reporting template to be used together with the sourceInfo() magic function.
Usage: error(sourceInfo(), <<message>>) "
::=
let() = Tpl.addSourceTemplateError(errMessage, srcInfo)
<<
#error "<% Error.infoStr(srcInfo) %> <% errMessage %>"<%\n%>
>>
end error;

//for completeness; although the error() template above is preferable
template errorMsg(String errMessage)
"Example template error reporting template
 that is reporting only the error message without the usage of source infotmation."
::=
let() = Tpl.addTemplateError(errMessage)
<<
#error "<% errMessage %>"<%\n%>
>>
end errorMsg;

template encloseInParantheses(String expStr)
 "Encloses expression in paranthesis if not yet given"
::=
if intEq(stringGet(expStr, 1), stringGet("(", 1)) then '<%expStr%>' else '(<%expStr%>)'
end encloseInParantheses;

template assignJacArray(String lhsStr, String rhsStr, DAE.Type ty)
 "Assign array to JAC/DIFF/SEED vars that are flat vectors with row major odering"
::=
  match ty
  case DAE.T_ARRAY(ty=elty, dims=dims) then
    let dimstr = listDimsFlat(dims, elty)
    let arrayWrapper = 'tmp<%System.tmpTick()%>'
    <<
    /*assign through wrapper array*/
    StatArrayDim<%nDimsFlat(dims, elty, 0)%><<%expTypeShort(elty)%>, <%dimstr%>, true> <%arrayWrapper%>(&<%lhsStr%>);
    assignRowMajorData(<%rhsStr%>.getData(), <%arrayWrapper%>);
    >>
end assignJacArray;

template writeLhsCref(Exp exp, String rhsStr, Context context, Text &preExp, Text &varDecls, SimCode simCode,
                      Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName, Boolean useFlatArrayNotation)
 "Generates code for writing a returnStructur to var."
::=
match exp
case ecr as CREF(componentRef=WILD(__)) then
  ''
case ecr as CREF(componentRef=cr, ty=ty as DAE.T_ARRAY()) then
  let lhsStr = scalarLhsCref(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  match cref2simvar(cr, simCode)
  case SIMVAR(varKind=varKind) then
    match varKind
    case JAC_VAR()
    case JAC_DIFF_VAR()
    case SEED_VAR() then
      <<
      <%assignJacArray(lhsStr, rhsStr, ty)%>
      >>
    else
      <<
      <%lhsStr%>.assign(<%rhsStr%>);
      >>
    end match
  end match
case UNARY(exp = e as CREF(ty= t as DAE.T_ARRAY(__))) then
  let lhsStr = scalarLhsCref(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  match context
  case SIMULATION_CONTEXT(__) then
    <<
    usub_<%expTypeShort(t)%>_array(&<%rhsStr%>);<%\n%>
    copy_<%expTypeShort(t)%>_array_data_mem(&<%rhsStr%>, &<%lhsStr%>);
    >>
  else
    '<%lhsStr%> = -<%rhsStr%>;'
case CREF(componentRef = cr, ty=DAE.T_COMPLEX(varLst = varLst, complexClassType=RECORD(__))) then
  match context
  case FUNCTION_CONTEXT(__) then
    writeLhsCref1(exp, rhsStr, context, &preExp /*BUFC*/, &varDecls /*BUFD*/, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  else
    let lhsStr = contextCref(crefStripSubs(cr), context, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    <<
    <% varLst |> var as TYPES_VAR(__) hasindex i1 fromindex 0 =>
      '_<%lhsStr%>P_<%var.name%>_ = <%rhsStr%>.<%var.name%>_;'
    ; separator="\n"
    %>
    >>
  end match
case CREF(__) then
  writeLhsCref1(exp, rhsStr, context, &preExp /*BUFC*/, &varDecls /*BUFD*/, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
case UNARY(exp = e as CREF(__)) then
  let lhsStr = scalarLhsCref(e, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  <<
  <%lhsStr%> = -<%rhsStr%>;
  >>
case ARRAY(array = {}) then
  <<

  >>
case ARRAY(ty=T_ARRAY(ty=ty,dims=dims),array=expl) then
  let typeShort = expTypeFromExpShort(exp)
  let fcallsuf = match listLength(dims) case 1 then "" case i then '_<%i%>D'
  let body = (threadTuple(expl,dimsToAllIndexes(dims)) |>  (lhs,indxs) =>
                 let lhsstr = scalarLhsCref(lhs, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
                 let indxstr = (indxs |> i => '<%i%>' ;separator=",")
                 '<%lhsstr%> = <%typeShort%>_get<%fcallsuf%>(&<%rhsStr%>, <%indxstr%>);/*writeLhsCref2*/'
              ;separator="\n")
  <<
  <%body%>
  >>
case ASUB(__) then
  error(sourceInfo(), 'writeLhsCref UNHANDLED ASUB (should never be part of a lhs expression): <%ExpressionDumpTpl.dumpExp(exp,"\"")%> = <%rhsStr%>')
else
  error(sourceInfo(), 'writeLhsCref UNHANDLED: <%ExpressionDumpTpl.dumpExp(exp,"\"")%> = <%rhsStr%>')

end writeLhsCref;

template writeLhsCref1(Exp exp, String rhsStr, Context context, Text &preExp,Text &varDecls, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generate a simple assignment of a tuple element"
::=
  let lhsStr = scalarLhsCref(exp, context, &preExp /*BUFC*/, &varDecls /*BUFD*/,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  <<
  <%lhsStr%> = <%rhsStr%> /*writeLhsCref1*/;
  >>
end writeLhsCref1;

template scalarLhsCref(Exp ecr, Context context, Text &preExp,Text &varDecls, SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation) ::=
match ecr
case ecr as CREF(componentRef=CREF_IDENT(subscriptLst=subs)) then
  if crefNoSub(ecr.componentRef) then
    contextCref(ecr.componentRef, context,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
  else
    daeExpCrefRhs(ecr, context, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
case ecr as CREF(componentRef=cr as CREF_QUAL(__)) then
    if crefIsScalar(cr, context) then
      contextCref(ecr.componentRef, context,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    else
      let arrName = contextCref(crefStripSubs(cr), context, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      <<
      <%arrName%>(<%threadDimSubList(crefDims(cr),crefSubs(cr),context,&preExp,&varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>)
      >>

case ecr as CREF(componentRef=CREF_QUAL(__)) then
    contextCref(ecr.componentRef, context,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
else
    "ONLY_IDENT_OR_QUAL_CREF_SUPPORTED_SLHS"
end scalarLhsCref;


template threadDimSubList(list<Dimension> dims, list<Subscript> subs, Context context, Text &preExp, Text &varDecls,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
  "Do direct indexing since sizes are known during compile-time"
::=
  match subs
  case {} then error(sourceInfo(),"Empty dimensions in indexing cref?")

  case {sub as INDEX(__)} then
    match dims
    case {dim} then
       let estr = daeExp(sub.exp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
      '<%estr%>'
    else error(sourceInfo(),"Less subscripts that dimensions in indexing cref? That's odd!")

  case (sub as INDEX(__))::subrest then
    match dims
      case _::dimrest
      then

        let estr = daeExp(sub.exp, context, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        '<%estr%><%match subrest case {} then "" else ',<%threadDimSubList(dimrest, subrest, context, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'%>'
        /*'((<%estr%><%
          dimrest |> dim =>
          match dim
          case DIM_INTEGER(__) then ')*<%integer%>'
          case DIM_BOOLEAN(__) then '*2'
          case DIM_ENUM(__) then '*<%size%>'
          else error(sourceInfo(),"Non-constant dimension in simulation context")
        %>)<%match subrest case {} then "" else ',<%threadDimSubList(dimrest, subrest, context, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, useFlatArrayNotation)%>'%>'
        */
      else error(sourceInfo(),"Less subscripts that dimensions in indexing cref? That's odd!")
  else error(sourceInfo(),"Non-index subscript in indexing cref? That's odd!")
end threadDimSubList;




template daeExpTsub(Exp inExp, Context context, Text &preExp,
                    Text &varDecls,SimCode simCode, Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for an tsub expression."
::=
  match inExp
  case TSUB(ix=1) then
    let tuple_val = daeExp(exp, context, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
     'get<0>(<%tuple_val%>.data)'
  //case TSUB(exp=CALL(attr=CALL_ATTR(ty=T_TUPLE(types=tys)))) then
  case TSUB(exp=CALL(path=p,attr=CALL_ATTR(ty=tys as T_TUPLE(__)))) then
    //let v = tempDecl(expTypeArrayIf(listGet(tys,ix)), &varDecls)
    //let additionalOutputs = List.restOrEmpty(tys) |> ty hasindex i1 fromindex 2 => if intEq(i1,ix) then ', &<%v%>' else ", NULL"
     let retType = '<%underscorePath(p)%>RetType /* undefined */'
    let retVar = tempDecl(retType, &varDecls)
     let res = daeExpCallTuple(exp,retVar, context, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    let &preExp += '<%res%>;<%\n%>'
    'get<<%intAdd(-1,ix)%>>(<%retVar%>.data)'

  case TSUB(__) then
    error(sourceInfo(), '<%ExpressionDumpTpl.dumpExp(inExp,"\"")%>: TSUB only makes sense if the subscripted expression is a function call of tuple type')
end daeExpTsub;

template daeExpCallTuple(Exp call , Text additionalOutputs/* arguments 2..N */, Context context, Text &preExp, Text &varDecls,SimCode simCode ,Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  match call
  case exp as CALL(attr=attr as CALL_ATTR(__)) then


    let argStr = if boolOr(attr.builtin,isParallelFunctionContext(context))
                   then (expLst |> exp => '<%daeExp(exp, context, &preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>' ;separator=", ")
                 else ((expLst |> exp => (daeExp(exp, context, preExp, &varDecls, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation));separator=", "))
    if attr.isFunctionPointerCall
      then
        let typeCast1 = generateTypeCast(attr.ty, expLst, true,preExp, varDecls,context, simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        let typeCast2 = generateTypeCast(attr.ty, expLst, false, preExp, varDecls,context,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
        let name = '_<%underscorePath(path)%>'
        let func = '(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(<%name%>), 1)))'
        let closure = '(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(<%name%>), 2)))'
        let argStrPointer = ('threadData, <%closure%>' + (expLst |> exp => (", " + daeExp(exp, context, &preExp, &varDecls,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation))))
        //'<%name%>(<%argStr%><%additionalOutputs%>)'
        '/*Closure?*/<%closure%> ? (<%typeCast1%> <%func%>) (<%argStrPointer%><%additionalOutputs%>) : (<%typeCast2%> <%func%>) (<%argStr%><%additionalOutputs%>)'
      else
        let name = underscorePath(path)
        '<%contextFunName(name, context)%>(<%argStr%>,<%additionalOutputs%>)'
end daeExpCallTuple;

template generateTypeCast(Type ty, list<DAE.Exp> es, Boolean isClosure, Text &preExp /*BUFP*/,
                     Text &varDecls, Context context,SimCode simCode, Text& extraFuncs,Text& extraFuncsDecl,Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
::=
  let ret = (match ty
    case T_NORETCALL(__) then "void"
    else "modelica_metatype")
  let inputs = es |> e => ', <%expTypeFromExpArrayIf(e,context, &preExp ,&varDecls ,simCode , &extraFuncs , &extraFuncsDecl,  extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>'
  let outputs = match ty
    case T_TUPLE(types=_::tys) then (tys |> t => ', <%expTypeArrayIf(t)%>')
  '(<%ret%>(*)(threadData_t*<%if isClosure then ", modelica_metatype"%><%inputs%><%outputs%>))'
end generateTypeCast;

template daeExpSharedLiteral(Exp exp, Context context, Text &preExp /*BUFP*/, Text &varDecls /*BUFP*/, Boolean useFlatArrayNotation)
 "Generates code for a match expression."
::=
  match exp case exp as SHARED_LITERAL(__) then
    let lit = '_OMC_LIT<%exp.index%>'
    '<%contextFunName(lit, context)%>'
end daeExpSharedLiteral;

template daeExpPartEvalFunction(Exp exp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Generates code for a function reference and a closure."
::=
  match exp
  case PARTEVALFUNCTION(ty=T_FUNCTION_REFERENCE_VAR(functionType = t), origType=T_FUNCTION_REFERENCE_VAR(functionType=t_orig as T_FUNCTION(path=name))) then
    let funcName = '<%underscorePath(name)%>'
    let closureArgs = (expList |> e => ', <%daeExp(e, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)%>')
    functionClosure(funcName, closureArgs, t, t_orig, context, &extraFuncsDecl)
  case PARTEVALFUNCTION(__) then
    error(sourceInfo(), 'PARTEVALFUNCTION: <%ExpressionDumpTpl.dumpExp(exp,"\"")%>, ty=<%unparseType(ty)%>, origType=<%unparseType(origType)%>')
end daeExpPartEvalFunction;

template functionClosure(String funcName, String closureArgs, Type t, Type t_orig, Context context, Text& extraFuncsDecl)
 "Generates a closure for calling a function."
::=
  match t
  case T_FUNCTION(funcArg=funcArgs) then
  match t_orig
  case T_FUNCTION(funcArg=funcArgsOrig) then
    let closureName = '_Closure<%System.tmpTickIndex(2/*auxFunction*/)%>_<%funcName%>'
    let functionsObject = match context case FUNCTION_CONTEXT(__) then 'this' else '_functions'
    let closureArgsDecl = (setDifference(funcArgsOrig, funcArgs) |> a as FUNCARG(__) hasindex i1 fromindex 1 => ', <%expTypeUnboxed(a.ty)%> <%a.name%>')
    let callArgsDecl = (funcArgs |> a as FUNCARG(__) hasindex i1 fromindex 1 => '<%expTypeUnboxed(a.ty)%> <%a.name%>, ')
    let callArgsOrig = (funcArgsOrig |> a as FUNCARG(__) hasindex i1 fromindex 1 => '<%a.name%>, ')
    let &extraFuncsDecl +=
    <<

    class <%closureName%>
    {
      Functions* _functions;
      <%setDifference(funcArgsOrig, funcArgs) |> a as FUNCARG(__) hasindex i1 fromindex 1 => '<%expTypeUnboxed(a.ty)%> <%a.name%>;<%\n%>'%>
     public:
      <%closureName%>(Functions* functions<%closureArgsDecl%>)
        : _functions(functions)
        <%setDifference(funcArgsOrig, funcArgs) |> a as FUNCARG(__) hasindex i1 fromindex 1 => ', <%a.name%>(<%a.name%>)<%\n%>'%>
      {}
      void operator()(<%callArgsDecl%><%funcName%>RetType &output) {
        _functions-><%funcName%>(<%callArgsOrig%>output);
      }
    };<%\n%>
    >>
    '<%closureName%>(<%functionsObject%><%closureArgs%>)'
end functionClosure;


template assertCommonVar(Text condVar, Text msgVar, Context context, Text &varDecls, builtin.SourceInfo info)
::=
  match context
  case FUNCTION_CONTEXT(__) then
    <<
    if(!(<%condVar%>))
    {

      throw ModelicaSimulationError(MODEL_EQ_SYSTEM,  <%msgVar%>);
    }
    >>
  // OpenCL doesn't have support for variadic args. So message should be just a single string.
  case PARALLEL_FUNCTION_CONTEXT(__) then
    <<
    if(!(<%condVar%>))
    {

      throw ModelicaSimulationError(MODEL_EQ_SYSTEM, "Common assertion failed");

    }
    >>
  else
    <<
    if(!(<%condVar%>))
    {
       //string error_msg = "The following assertion has been violated %sat time %f", initial() ? "during initialization " : "", data->localData[0]->timeValue);
       throw ModelicaSimulationError(MODEL_EQ_SYSTEM,<%msgVar%>);
    }
    >>
end assertCommonVar;


template expTypeUnboxed(Type t)
  "Returns the actual type in the box"
::=
  match t
  case T_METABOXED(__) then
    expTypeFlag(Types.unboxedType(t), 8)
  else
    expTypeFlag(t, 8)
end expTypeUnboxed;

template daeExpBox(Exp exp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Not needed; just returns exp"
::=
  match exp
  case BOX(__) then
    let elty = expTypeFromExpShort(exp)
    let ty = if isArrayType(typeof(exp)) then 'BaseArray<'+'<%elty%>'+'>' else '<%elty%>'
    let res = daeExp(exp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    '/*box <%ty%>*/<%res%>'
end daeExpBox;

template daeExpUnbox(Exp exp, Context context, Text &preExp, Text &varDecls, SimCode simCode, Text& extraFuncs, Text& extraFuncsDecl, Text extraFuncsNamespace, Text stateDerVectorName /*=__zDot*/, Boolean useFlatArrayNotation)
 "Not needed; just returns exp.exp"
::=
  match exp
  case exp as UNBOX(__) then
    let ty = expTypeShort(exp.ty)
    let res = daeExp(exp.exp, context, &preExp, &varDecls, simCode, &extraFuncs, &extraFuncsDecl, extraFuncsNamespace, stateDerVectorName, useFlatArrayNotation)
    '/*unbox <%ty%>*/<%res%>'
end daeExpUnbox;

/*******************************************************************************************************************************************************
* end of exp to string template functions
********************************************************************************************************************************************************/

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
end CodegenCppCommon;
