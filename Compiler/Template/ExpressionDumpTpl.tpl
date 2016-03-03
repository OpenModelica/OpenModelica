package ExpressionDumpTpl

import interface ExpressionDumpTV;
import AbsynDumpTpl;
import DAEDumpTpl;

template dumpExp(DAE.Exp exp, String stringDelimiter)
::=
match exp
  case ICONST(__) then integer
  case RCONST(__) then real
  case SCONST(__) then
    let str = escapedString(string,false)
    '<%stringDelimiter%><%str%><%stringDelimiter%>'
  case BCONST(__) then bool
  case CLKCONST(__) then dumpClockKind(clk, stringDelimiter)
  case ENUM_LITERAL(__) then
    (if typeinfo() then '/* <%index%> */') + AbsynDumpTpl.dumpPath(name)
  case CREF(__) then (if typeinfo() then '/*<%unparseType(ty)%>*/ ') + dumpCref(componentRef)
  case e as BINARY(__) then
    let lhs_str = dumpOperand(exp1, e, true)
    let rhs_str = dumpOperand(exp2, e, false)
    let op_str = dumpBinOp(operator)
    '<%lhs_str%> <%op_str%> <%rhs_str%>'
  case e as UNARY(__) then
    let exp_str = dumpOperand(exp, e, false)
    let op_str = dumpUnaryOp(operator)
    '<%op_str%><%exp_str%>'
  case e as LBINARY(__) then
    let lhs_str = dumpOperand(exp1, e, true)
    let rhs_str = dumpOperand(exp2, e, false)
    let op_str = dumpLogicalBinOp(operator)
    '<%lhs_str%> <%op_str%> <%rhs_str%>'
  case e as LUNARY(__) then
    let exp_str = dumpOperand(exp, e, false)
    let op_str = dumpLogicalUnaryOp(operator)
    '<%op_str%> <%exp_str%>'
  case e as RELATION(__) then
    let lhs_str = dumpOperand(exp1, e, true)
    let rhs_str = dumpOperand(exp2, e, false)
    let op_str = dumpRelationOp(operator)
    '<%lhs_str%> <%op_str%> <%rhs_str%>'
  case IFEXP(__) then
    let cond_str = dumpExp(expCond, stringDelimiter)
    let then_str = dumpExp(expThen, stringDelimiter)
    let else_str = dumpExp(expElse, stringDelimiter)
    'if <%cond_str%> then <%then_str%> else <%else_str%>'
  case CALL(attr=attr as CALL_ATTR(builtin=true)) then
    let func_str = AbsynDumpTpl.dumpPathNoQual(path)
    let argl = dumpExpList(expLst, stringDelimiter, ", ")
    '<%if typeinfo() then '/*<%unparseType(attr.ty)%>*/ ' %><%func_str%>(<%argl%>)'
  case CALL(__) then
    let func_str = AbsynDumpTpl.dumpPathNoQual(path)
    let argl = dumpExpList(expLst, stringDelimiter, ", ")
    '<%func_str%>(<%argl%>)'
  case RECORD(__) then
    let func_str = AbsynDumpTpl.dumpPathNoQual(path)
    let argl = dumpExpList(exps, stringDelimiter, ", ")
    '<%func_str%>(<%argl%>)'
  case PARTEVALFUNCTION(__) then
    let func_str = AbsynDumpTpl.dumpPathNoQual(path)
    let argl = dumpExpList(expList, stringDelimiter, ", ")
    'function <%func_str%>(<%argl%>)'
  case ARRAY(array={}) then
    if (Flags.getConfigBool(Flags.MODELICA_OUTPUT)) then
    'fill(0,0)'
    else
    let expl = dumpExpList(array, stringDelimiter, ", ")
    '<%if typeinfo() then (if scalar then '/* scalar <%unparseType(ty)%>*/' else '/* non-scalar <%unparseType(ty)%> */ ')%>{<%expl%>}'
  case ARRAY(__) then
    let expl = dumpExpList(array, stringDelimiter, ", ")
    '<%if typeinfo() then (if scalar then '/* scalar <%unparseType(ty)%>*/' else '/* non-scalar <%unparseType(ty)%> */ ')%>{<%expl%>}'

  case MATRIX(__) then
    let mat_str = (matrix |> row => dumpExpList(row, stringDelimiter, ", ") ;separator="}, {")
    '<%if typeinfo() then '/* matrix <%unparseType(ty) %> */ '%>{{<%mat_str%>}}'
  case e as RANGE(__) then
    let start_str = dumpOperand(start, e, false)
    let step_str = match step case SOME(step) then '<%dumpOperand(step, e, false)%>:'
    let stop_str = dumpOperand(stop, e, false)
    '<%start_str%>:<%step_str%><%stop_str%>'
  case TUPLE(__) then
    let tuple_str = dumpExpList(PR, stringDelimiter, ", ")
    '(<%tuple_str%>)'
  case CAST(__) then
    let exp_str = dumpExp(exp, stringDelimiter)
    let ty_str = dumpType(ty)
    '/*<%ty_str%>*/(<%exp_str%>)'
  case ASUB(__) then
    let needs_paren = parenthesizeSubExp(exp)
    let lparen = if needs_paren then "("
    let rparen = if needs_paren then ")"
    let exp_str = dumpExp(exp, stringDelimiter)
    let sub_str = dumpExpList(sub, stringDelimiter, ", ")
    '<%lparen%><%exp_str%><%rparen%><%if typeinfo() then "/*ASUB*/"%>[<%sub_str%>]'
  case TSUB(__) then
    let needs_paren = parenthesizeSubExp(exp)
    let lparen = if needs_paren then "("
    let rparen = if needs_paren then ")"
    let exp_str = dumpExp(exp, stringDelimiter)
    '<%lparen%><%exp_str%><%rparen%>[<%ix%>]'
  case RSUB(__) then
    let needs_paren = parenthesizeSubExp(exp)
    let lparen = if needs_paren then "("
    let rparen = if needs_paren then ")"
    let exp_str = dumpExp(exp, stringDelimiter)
    '<%if typeinfo() then '/*RSUB: <%unparseType(ty)%>*/'%><%lparen%><%exp_str%><%rparen%>.<%fieldName%>'
  case SIZE(__) then
    let exp_str = dumpExp(exp, stringDelimiter)
    let dim_str = match sz case SOME(dim) then ', <%dumpExp(dim, stringDelimiter)%>'
    'size(<%exp_str%><%dim_str%>)'
  case CODE(__) then
    let code_str = Dump.printCodeStr(code)
    '$Code(<%code_str%>)'
  case EMPTY(__) then
    let name_str = dumpCref(name)
    '<EMPTY(scope: <%scope%>, name: <%name_str%>, ty: <%tyStr%>)>'
  case REDUCTION(reductionInfo = ri as REDUCTIONINFO(__)) then
    let name_str = AbsynDumpTpl.dumpPathNoQual(ri.path)
    let exp_str = dumpExp(expr, stringDelimiter)
    let iter_str = (iterators |> it => dumpReductionIterator(it, stringDelimiter) ;separator=", ")
    '<%name_str%>(<%exp_str%> for <% match ri.iterType case THREAD() then "threaded " %><%iter_str%>)'
  case LIST(__) then
    let expl_str = dumpExpList(valList, stringDelimiter, ", ")
    'List(<%expl_str%>)'
  case CONS(__) then
    let car_str = dumpExp(car, stringDelimiter)
    let cdr_str = dumpExp(cdr, stringDelimiter)
    'listCons(<%car_str%>, <%cdr_str%>)'
  case META_TUPLE(__) then
    let tuple_str = dumpExpList(listExp, stringDelimiter, ", ")
    'Tuple(<%tuple_str%>)'
  case META_OPTION(exp = SOME(exp)) then 'SOME(<%dumpExp(exp, stringDelimiter)%>)'
  case META_OPTION(__) then 'NONE()'
  case METARECORDCALL(__) then
    let name_str = AbsynDumpTpl.dumpPath(path)
    let args_str = dumpExpList(args, stringDelimiter, ", ")
    '<%name_str%>(<%args_str%>)'
  case MATCHEXPRESSION(__) then
    let match_ty = dumpMatchType(matchType)
    let inputs_str = dumpExpList(inputs, stringDelimiter, ", ")
    let case_str = (cases |> c => dumpMatchCase(c) ;separator="\n")
    <<
    <%match_ty%> (<%inputs_str%>)
        <%case_str%>
      end <%match_ty%>
    >>
  case BOX(__) then
    '#(<%dumpExp(exp, stringDelimiter)%>)'
  case UNBOX(__) then
    'unbox(<%dumpExp(exp, stringDelimiter)%>)'
  case SHARED_LITERAL(__) then
    if typeinfo() then '/* Shared literal <%index%> */ <%dumpExp(exp, stringDelimiter)%>' else dumpExp(exp, stringDelimiter)
  case PATTERN(__) then (if typeinfo() then '/*pattern*/') + dumpPattern(pattern)
  case SUM(__) then
    let bodyStr = dumpExp(body,stringDelimiter)
    let iterStr = dumpExp(iterator,stringDelimiter)
    let startStr = dumpExp(startIt,stringDelimiter)
    let endStr = dumpExp(endIt,stringDelimiter)
    'SIGMA[<%iterStr%>:<%startStr%>to<%endStr%>](<%bodyStr%>)'

  else errorMsg("ExpressionDumpTpl.dumpExp: Unknown expression.")
end dumpExp;

template parenthesizeSubExp(DAE.Exp exp)
::=
match exp
  case ICONST(__) then ""
  case RCONST(__) then ""
  case SCONST(__) then ""
  case BCONST(__) then ""
  case ENUM_LITERAL(__) then ""
  case CREF(__) then ""
  case CALL(__) then ""
  case ARRAY(__) then ""
  case MATRIX(__) then ""
  case TUPLE(__) then  ""
  case CAST(__) then ""
  case SIZE(__) then ""
  case REDUCTION(__) then ""
  else "y"
end parenthesizeSubExp;

template dumpExpList(list<DAE.Exp> expl, String stringDelimiter, String expDelimiter)
::= (expl |> exp => dumpExp(exp, stringDelimiter) ;separator=expDelimiter)
end dumpExpList;

template dumpExpListCrefs(list<DAE.Exp> expl, String stringDelimiter, String expDelimiter)
::= (expl |> exp => dumpExpCrefs(exp, stringDelimiter) ;separator=expDelimiter)
end dumpExpListCrefs;

template dumpClockKind(DAE.ClockKind clk, String stringDelimiter)
::=
match clk
  case INFERRED_CLOCK(__) then "Clock()"
  case INTEGER_CLOCK(__) then
    let ic_str = dumpExp(intervalCounter, stringDelimiter)
    let re_str = dumpExp(resolution, stringDelimiter)
    'Clock(<%ic_str%>, <%re_str%>)'
  case REAL_CLOCK(__) then
    let interval_str = dumpExp(interval, stringDelimiter)
    'Clock(<%interval_str%>)'
  case BOOLEAN_CLOCK(__) then
    let condition_str = dumpExp(condition, stringDelimiter)
    let si_str = dumpExp(startInterval, stringDelimiter)
    'Clock(<%condition_str%>, <%si_str%>)'
  case SOLVER_CLOCK(__) then
    let clk_str = dumpExp(c, stringDelimiter)
    let sm_str = dumpExp(solverMethod, stringDelimiter)
    'Clock(<%clk_str%>, <%sm_str%>)'
end dumpClockKind;


template dumpCref(DAE.ComponentRef cref)
::=
match cref
  case CREF_IDENT(__) then
    let sub_str = dumpSubscripts(subscriptLst)
    '<%ident%><%sub_str%>'
  case CREF_ITER(__) then
    let sub_str = dumpSubscripts(subscriptLst)
    '<%ident%><%sub_str%> /* iter index <%index%> */'
  case CREF_QUAL(__) then
    let sub_str = dumpSubscripts(subscriptLst)
    let cref_str = dumpCref(componentRef)
    if (Flags.getConfigBool(Flags.MODELICA_OUTPUT)) then
    '<%ident%><%sub_str%>__<%cref_str%>'
    else
    '<%ident%><%sub_str%>.<%cref_str%>'
  case WILD() then '_'
  case OPTIMICA_ATTR_INST_CREF(__) then
    '<%dumpCref(componentRef)%>(<%instant%>)'
  else errorMsg("ExpressionDumpTpl.dumpCref: unknown cref")
end dumpCref;

template dumpSubscripts(list<DAE.Subscript> subscripts)
::=
if subscripts then
  if (Flags.getConfigBool(Flags.MODELICA_OUTPUT)) then
  let sub_str = (subscripts |> sub => dumpSubscript(sub) ;separator="_")
  '_<%sub_str%>'
  else
  let sub_str = (subscripts |> sub => dumpSubscript(sub) ;separator=",")
  '[<%sub_str%>]'
end dumpSubscripts;

template dumpSubscript(DAE.Subscript subscript)
::=
match subscript
  case WHOLEDIM(__) then ':'
  case SLICE(__) then dumpExp(exp, "\"")
  case INDEX(__) then dumpExp(exp, "\"")
  case WHOLE_NONEXP(__) then dumpExp(exp, "\"")
end dumpSubscript;

template dumpReductionIterator(DAE.ReductionIterator iterator, String stringDelimiter)
::=
match iterator
  case REDUCTIONITER(guardExp = NONE()) then
    let exp_str = dumpExp(exp, stringDelimiter)
    '<%id%> in <%exp_str%>'
  case REDUCTIONITER(guardExp = SOME(gexp)) then
    let exp_str = dumpExp(exp, stringDelimiter)
    let guard_str = dumpExp(gexp, stringDelimiter)
    '<%id%> guard <%guard_str%> in <%exp_str%>'
end dumpReductionIterator;

template dumpOperand(DAE.Exp operand, DAE.Exp operation, Boolean lhs)
::=
  let op_str = dumpExp(operand, "\"")
  if shouldParenthesize(operand, operation, lhs) then
    '(<%op_str%>)'
  else
    op_str
end dumpOperand;

template dumpBinOp(DAE.Operator op)
::=
if typeinfo() then
match op
  case ADD(__) then '+'
  case SUB(__) then '-'
  case MUL(__) then '*'
  case DIV(__) then '/'
  case POW(__) then '^'
  case ADD_ARR(__) then '+ /* ADD_ARR */'
  case SUB_ARR(__) then '- /* SUB_ARR */'
  case MUL_ARR(__) then '.* /* MUL_ARR */'
  case DIV_ARR(__) then './ /* DIV_ARR */'
  case POW_ARR(__) then '^ /* POW_ARR */'
  case POW_ARR2(__) then '.^ /* POW_ARR2 */'
  case MUL_ARRAY_SCALAR(__) then '* /* MUL_ARR_SCA */'
  case ADD_ARRAY_SCALAR(__) then '.+ /* ADD_ARR_SCA */'
  case SUB_SCALAR_ARRAY(__) then '.- /* SUB_SCA_ARR */'
  case POW_SCALAR_ARRAY(__) then '.^ /* POW_SCA_ARR */'
  case POW_ARRAY_SCALAR(__) then '.^ /* POW_ARR_SCA */'
  case MUL_SCALAR_PRODUCT(__) then '* /* MUL_SCA_PRO */'
  case MUL_MATRIX_PRODUCT(__) then '* /* MUL_MAT_PRO */'
  case DIV_SCALAR_ARRAY(__) then '/ /* DIV_SCA_ARR */'
  case DIV_ARRAY_SCALAR(__) then '/ /* DIV_ARR_SCA */'
  else errorMsg("ExpressionDumpTpl.dumpBinOp: Unknown operator.")
else
match op
  case ADD(__) then '+'
  case SUB(__) then '-'
  case MUL(__) then '*'
  case DIV(__) then '/'
  case POW(__) then '^'
  case ADD_ARR(__) then '+'
  case SUB_ARR(__) then '-'
  case MUL_ARR(__) then '.*'
  case DIV_ARR(__) then './'
  case POW_ARR(__) then '^'
  case POW_ARR2(__) then '.^'
  case MUL_ARRAY_SCALAR(__) then '*'
  case ADD_ARRAY_SCALAR(__) then '.+'
  case SUB_SCALAR_ARRAY(__) then '.-'
  case POW_SCALAR_ARRAY(__) then '.^'
  case POW_ARRAY_SCALAR(__) then '.^'
  case MUL_SCALAR_PRODUCT(__) then '*'
  case MUL_MATRIX_PRODUCT(__) then '*'
  case DIV_SCALAR_ARRAY(__) then './'
  case DIV_ARRAY_SCALAR(__) then '/'
  else errorMsg("ExpressionDumpTpl.dumpBinOp: Unknown operator.")
end dumpBinOp;

template dumpUnaryOp(DAE.Operator op)
::=
match op
  case UMINUS(__) then '-'
  case UMINUS_ARR(__) then '-'
  case ADD(__) then '+'
  else errorMsg("ExpressionDumpTpl.dumpUnaryOp: Unknown operator.")
end dumpUnaryOp;

template dumpLogicalBinOp(DAE.Operator op)
::=
match op
  case DAE.AND(__) then 'and'
  case DAE.OR(__) then 'or'
  else errorMsg("ExpressionDumpTpl.dumpLogicalBinOp: Unknown operator.")
end dumpLogicalBinOp;

template dumpLogicalUnaryOp(DAE.Operator op)
::=
match op
  case DAE.NOT(__) then 'not'
  else errorMsg("ExpressionDumpTpl.dumpLogicalUnaryOp: Unknown operator.")
end dumpLogicalUnaryOp;

template dumpRelationOp(DAE.Operator op)
::=
match op
  case LESS(__) then "<"
  case LESSEQ(__) then "<="
  case GREATER(__) then ">"
  case GREATEREQ(__) then ">="
  case EQUAL(__) then "=="
  case NEQUAL(__) then "<>"
  case USERDEFINED(__) then "USERDEFINED"
  else errorMsg("ExpressionDumpTpl.dumpRelationOp: Unknown operator.")
end dumpRelationOp;

template dumpType(DAE.Type ty)
::=
match ty
  case T_INTEGER(__) then 'Integer'
  case T_REAL(__) then 'Real'
  case T_BOOL(__) then 'Bool'
  case T_STRING(__) then 'String'
  case T_ENUMERATION(__) then AbsynDumpTpl.dumpPath(path)
  case T_ARRAY(__) then
    let dim_str = dumpDimensions(dims)
    let ty_str = dumpType(ty)
    '<%ty_str%>[<%dim_str%>]'
  case T_COMPLEX(__) then dumpClassState(complexClassType)
  case T_SUBTYPE_BASIC(__) then dumpClassState(complexClassType)
  case T_FUNCTION(__) then
    let arg_str = (funcArg |> arg => dumpFuncArg(arg) ;separator=", ")
    let ret_str = dumpType(funcResultType)
    '<function>(<%arg_str%>) => <%ret_str%>'
  case T_FUNCTION_REFERENCE_VAR(__) then dumpType(functionType)
  case T_FUNCTION_REFERENCE_FUNC(__) then dumpType(functionType)
  case T_TUPLE(__) then
    let ty_str = (types |> ty => dumpType(ty) ;separator=", ")
    '(<%ty_str%>'
  case T_CODE(__) then '#T_CODE#'
  case T_METALIST(__) then
    let ty_str = dumpType(ty)
    'list<<%ty_str%>>'
  case T_METATUPLE(__) then
    let ty_str = (types |> ty => dumpType(ty) ;separator=", ")
    'tuple<<%ty_str%>>'
  case T_METAOPTION(__) then
    let ty_str = dumpType(ty)
    'Option<<%ty_str%>>'
  case T_METAUNIONTYPE(source = {p}) then AbsynDumpTpl.dumpPath(p)
  case T_METARECORD(source = {p}) then AbsynDumpTpl.dumpPath(p)
  case T_METAARRAY(__) then
    let ty_str = dumpType(ty)
    'array<<%ty_str%>>'
  case T_METABOXED(__) then dumpType(ty)
  case T_METAPOLYMORPHIC(__) then 'polymorphic<<%name%>>'
  case T_METATYPE(__) then dumpType(ty)
  case T_UNKNOWN(__) then '#T_UNKNOWN#'
  case T_ANYTYPE(__) then 'Any'
  case T_NORETCALL(__) then '#T_NORETCALL#'
end dumpType;

template dumpFuncArg(DAE.FuncArg arg)
::= match arg case arg as FUNCARG() then arg.name
end dumpFuncArg;

template dumpDimensions(DAE.Dimensions dims)
::= (dims |> dim => dumpDimension(dim) ;separator=", ")
end dumpDimensions;

template dumpDimension(DAE.Dimension dim)
::=
match dim
  case DIM_INTEGER(__) then integer
  case DIM_ENUM(__) then AbsynDumpTpl.dumpPath(enumTypeName)
  case DIM_EXP(__) then dumpExp(exp, "\"")
  case DIM_UNKNOWN(__) then ':'
end dumpDimension;

template dumpClassState(ClassInf.State state)
::= AbsynDumpTpl.dumpPath(ClassInf.getStateName(state))
end dumpClassState;

template dumpMatchType(DAE.MatchType ty)
::=
match ty
  case MATCHCONTINUE() then "matchcontinue"
  case MATCH(switch = NONE()) then "match"
  case MATCH(switch = SOME(_)) then "match /* switch */"
end dumpMatchType;

template dumpMatchCase(DAE.MatchCase mcase)
::=
match mcase
  case CASE(body = {}, result = SOME(result)) then
    let pat_str = dumpPatterns(patterns)
    let res_str = dumpExp(result, "\"")
    'case (<%pat_str%>) then <%res_str%>;'
  case CASE(body = {}, result = NONE()) then
    let pat_str = dumpPatterns(patterns)
    'case (<%pat_str%>) then fail();'
  case CASE(result = SOME(result)) then
    let pat_str = dumpPatterns(patterns)
    let res_str = dumpExp(result, "\"")
    let body_str = DAEDumpTpl.dumpStatements(body)
    <<
    case (<%pat_str%>)
      algorithm
        <%body_str%>
      then
        <%res_str%>;
    >>
  case CASE(__) then
    let pat_str = dumpPatterns(patterns)
    let body_str = DAEDumpTpl.dumpStatements(body)
    <<
    case (<%pat_str%>)
      algorithm
        <%body_str%>
      then
        fail();
    >>
end dumpMatchCase;

template dumpPatterns(list<DAE.Pattern> patterns)
::= (patterns |> pat => dumpPattern(pat) ;separator=", ")
end dumpPatterns;

template dumpPattern(DAE.Pattern pattern)
::=
match pattern
  case PAT_WILD() then "_"
  case PAT_AS(pat = PAT_WILD()) then id
  case PAT_AS_FUNC_PTR(pat = PAT_WILD()) then id
  case PAT_SOME(__) then 'SOME(<%dumpPattern(pat)%>)'
  case PAT_META_TUPLE(__) then '(<%dumpPatterns(patterns)%>)'
  case PAT_CALL_TUPLE(__) then '(<%dumpPatterns(patterns)%>)'
  case PAT_CALL(__) then
    let name_str = AbsynDumpTpl.dumpPath(name)
    let pat_str = dumpPatterns(patterns)
    '<%name_str%>(<%pat_str%>)'
  case PAT_CALL_NAMED(__) then
    let name_str = AbsynDumpTpl.dumpPath(name)
    let pat_str = (patterns |> pat => dumpNamedPattern(pat) ;separator=", ")
    '<%name_str%>(<%pat_str%>)'
  case PAT_CONS(__) then '<%dumpPattern(head)%>::<%dumpPattern(tail)%>'
  case PAT_CONSTANT(__) then dumpExp(exp, "\"")
  case PAT_AS(__) then '<%id%> as <%dumpPattern(pat)%>'
  case PAT_AS_FUNC_PTR(__) then '<%id%> as <%dumpPattern(pat)%>'
  else "*PATTERN*"
end dumpPattern;

template dumpNamedPattern(tuple<Pattern, String, Type> pattern)
::= match pattern case (pat, id, _) then '<%id%> = <%dumpPattern(pat)%>'
end dumpNamedPattern;



template dumpExpCrefs(DAE.Exp exp, String stringDelimiter)
::=
match exp
  case ICONST(__) then ''
  case RCONST(__) then ''
  case SCONST(__) then ''
  case BCONST(__) then ''
  case ENUM_LITERAL(__) then AbsynDumpTpl.dumpPath(name)
  case CREF(__) then dumpCref(componentRef)
  case e as BINARY(__) then
    let lhs_str = dumpExpCrefs(exp1, stringDelimiter)
    let rhs_str = dumpExpCrefs(exp2, stringDelimiter)
    '<%lhs_str%> <%rhs_str%>'
  case e as UNARY(__) then
    let exp_str = dumpOperand(exp, e, false)
    let op_str = dumpUnaryOp(operator)
    '<%op_str%><%exp_str%>'
  case e as LBINARY(__) then
    let lhs_str = dumpExpCrefs(exp1, stringDelimiter)
    let rhs_str = dumpExpCrefs(exp2, stringDelimiter)
    '<%lhs_str%> <%rhs_str%>'
  case e as LUNARY(__) then
    let lhs_str = dumpExpCrefs(exp, stringDelimiter)
    '<%lhs_str%>'
  case e as RELATION(__) then
    let lhs_str = dumpExpCrefs(exp1, stringDelimiter)
    let rhs_str = dumpExpCrefs(exp2, stringDelimiter)
    '<%lhs_str%> <%rhs_str%>'
  case IFEXP(__) then
    let cond_str = dumpExpCrefs(expCond, stringDelimiter)
    let then_str = dumpExpCrefs(expThen, stringDelimiter)
    let else_str = dumpExpCrefs(expElse, stringDelimiter)
    '<%cond_str%> <%then_str%> <%else_str%>'
  case CALL(attr=attr as CALL_ATTR(builtin=true)) then
    let argl = dumpExpListCrefs(expLst, stringDelimiter, " ")
    '<%argl%>'
  case CALL(__) then
    let argl = dumpExpListCrefs(expLst, stringDelimiter, " ")
    '<%argl%>'
  case PARTEVALFUNCTION(__) then
    let func_str = AbsynDumpTpl.dumpPathNoQual(path)
    let argl = dumpExpList(expList, stringDelimiter, ", ")
    'function <%func_str%>(<%argl%>)'
  case ARRAY(__) then
    let expl = dumpExpList(array, stringDelimiter, ", ")
    '<%if typeinfo() then (if scalar then "/* scalar */ " else "/* non-scalar */ ")%>{<%expl%>}'
  case MATRIX(__) then
    let mat_str = (matrix |> row => dumpExpList(row, stringDelimiter, ", ") ;separator="}, {")
    '<%if typeinfo() then '/* matrix <%unparseType(ty) %> */ '%>{{<%mat_str%>}}'
  case e as RANGE(__) then
    let start_str = dumpOperand(start, e, false)
    let step_str = match step case SOME(step) then '<%dumpOperand(step, e, false)%>:'
    let stop_str = dumpOperand(stop, e, false)
    '<%start_str%>:<%step_str%><%stop_str%>'
  case TUPLE(PR={}) then ""
  case TUPLE(__) then
    let tuple_str = dumpExpList(PR, stringDelimiter, ", ")
    '(<%tuple_str%>)'
  case CAST(__) then
    let exp_str = dumpExpCrefs(exp, stringDelimiter)
    '(<%exp_str%>)'
  case ASUB(__) then
    let needs_paren = parenthesizeSubExp(exp)
    let lparen = if needs_paren then "("
    let rparen = if needs_paren then ")"
    let exp_str = dumpExp(exp, stringDelimiter)
    let sub_str = dumpExpList(sub, stringDelimiter, ", ")
    '<%lparen%><%exp_str%><%rparen%>[<%sub_str%>]'
  case TSUB(__) then
    let needs_paren = parenthesizeSubExp(exp)
    let lparen = if needs_paren then "("
    let rparen = if needs_paren then ")"
    let exp_str = dumpExp(exp, stringDelimiter)
    '<%lparen%><%exp_str%><%rparen%>[<%ix%>]'
  case SIZE(__) then
    let exp_str = dumpExp(exp, stringDelimiter)
    let dim_str = match sz case SOME(dim) then ', <%dumpExp(dim, stringDelimiter)%>'
    'size(<%exp_str%><%dim_str%>)'
  case CODE(__) then
    let code_str = Dump.printCodeStr(code)
    '$Code(<%code_str%>)'
  case EMPTY(__) then
    let name_str = dumpCref(name)
    '<EMPTY(scope: <%scope%>, name: <%name_str%>, ty: <%tyStr%>)>'
  case REDUCTION(reductionInfo = ri as REDUCTIONINFO(path = name)) then
    let name_str = AbsynDumpTpl.dumpPathNoQual(name)
    let exp_str = dumpExp(expr, stringDelimiter)
    let iter_str = (iterators |> it => dumpReductionIterator(it, stringDelimiter) ;separator=", ")
    '<%name_str%>(<%exp_str%> for <% match ri.iterType case THREAD() then "threaded " %><%iter_str%>)'
  case LIST(__) then
    let expl_str = dumpExpList(valList, stringDelimiter, ", ")
    'List(<%expl_str%>)'
  case CONS(__) then
    let car_str = dumpExp(car, stringDelimiter)
    let cdr_str = dumpExp(cdr, stringDelimiter)
    'listCons(<%car_str%>, <%cdr_str%>)'
  case META_TUPLE(__) then
    let tuple_str = dumpExpList(listExp, stringDelimiter, ", ")
    'Tuple(<%tuple_str%>)'
  case META_OPTION(exp = SOME(exp)) then 'SOME(<%dumpExp(exp, stringDelimiter)%>)'
  case META_OPTION(__) then 'NONE()'
  case METARECORDCALL(__) then
    let name_str = AbsynDumpTpl.dumpPath(path)
    let args_str = dumpExpList(args, stringDelimiter, ", ")
    '<%name_str%>(<%args_str%>)'
  case MATCHEXPRESSION(__) then
    let match_ty = dumpMatchType(matchType)
    let inputs_str = dumpExpList(inputs, stringDelimiter, ", ")
    let case_str = (cases |> c => dumpMatchCase(c) ;separator="\n")
    <<
    <%match_ty%> (<%inputs_str%>)
        <%case_str%>
      end <%match_ty%>
    >>
  case BOX(__) then
    '#(<%dumpExp(exp, stringDelimiter)%>)'
  case UNBOX(__) then
    'unbox(<%dumpExp(exp, stringDelimiter)%>)'
  case SHARED_LITERAL(__) then
    dumpExpCrefs(exp, stringDelimiter)
  case PATTERN(__) then dumpPattern(pattern)
  else errorMsg("ExpressionDumpTpl.dumpExp: Unknown expression.")
end dumpExpCrefs;




template errorMsg(String errMessage)
::=
let() = Tpl.addTemplateError(errMessage)
<<
<%errMessage%>
>>
end errorMsg;

annotation(__OpenModelica_Interface="frontend");
end ExpressionDumpTpl;
