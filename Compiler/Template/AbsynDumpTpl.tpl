package AbsynDumpTpl

import interface AbsynDumpTV;

template dumpPath(Absyn.Path path)
::=
match path
  case FULLYQUALIFIED(__) then
    '.<%dumpPath(path)%>'
  case QUALIFIED(__) then
    '<%name%>.<%dumpPath(path)%>'
  case IDENT(__) then
    '<%name%>'
  else
    errorMsg("SCodeDump.dumpPath: Unknown path.")
end dumpPath;

template dumpPathNoQual(Absyn.Path path)
::=
match path
  case FULLYQUALIFIED(__) then
    dumpPath(path)
  else
    dumpPath(path)
end dumpPathNoQual;

template dumpTypeSpec(Absyn.TypeSpec typeSpec)
::=
match typeSpec
  case TPATH(__) then
    let path_str = dumpPath(path)
    let arraydim_str = dumpArrayDimOpt(arrayDim)
    '<%path_str%><%arraydim_str%>'
  case TCOMPLEX(__) then
    let path_str = dumpPath(path)
    let ty_str = (typeSpecs |> ty => dumpTypeSpec(ty) ;separator=", ")
    let arraydim_str = dumpArrayDimOpt(arrayDim)
    '<%path_str%><<%ty_str%>><%arraydim_str%>'
end dumpTypeSpec;

template dumpArrayDimOpt(Option<Absyn.ArrayDim> arraydim)
::= match arraydim case SOME(ad) then dumpSubscripts(ad)
end dumpArrayDimOpt;

template dumpSubscripts(list<Subscript> subscripts)
::=
  if subscripts then
    let sub_str = (subscripts |> s => dumpSubscript(s) ;separator=", ")
    '[<%sub_str%>]'
end dumpSubscripts;

template dumpSubscript(Absyn.Subscript subscript)
::=
match subscript
  case NOSUB(__) then ':'
  case SUBSCRIPT(__) then dumpExp(subscript)
end dumpSubscript;

template dumpExp(Absyn.Exp exp)
::=
match exp
  case INTEGER(__) then value
  case REAL(__) then value
  case CREF(__) then dumpCref(componentRef)
  case STRING(__) then '"<%value%>"'
  case BOOL(__) then value
  case e as BINARY(__) then
    let rhs_str = dumpOperand(exp1, e)
    let lhs_str = dumpOperand(exp2, e)
    let op_str = dumpOperator(op)
    '<%rhs_str%> <%op_str%> <%lhs_str%>'
  case e as UNARY(__) then
    let exp_str = dumpOperand(exp, e)
    let op_str = dumpOperator(op)
    '<%op_str%><%exp_str%>'
  case e as LBINARY(__) then
    let rhs_str = dumpOperand(exp1, e)
    let lhs_str = dumpOperand(exp2, e)
    let op_str = dumpOperator(op)
    '<%rhs_str%> <%op_str%> <%lhs_str%>'
  case e as LUNARY(__) then
    let exp_str = dumpOperand(exp, e)
    let op_str = dumpOperator(op)
    '<%op_str%> <%exp_str%>'
  case e as RELATION(__) then
    let rhs_str = dumpOperand(exp1, e)
    let lhs_str = dumpOperand(exp2, e)
    let op_str = dumpOperator(op)
    '<%rhs_str%> <%op_str%> <%lhs_str%>'
  case IFEXP(__) then dumpIfExp(exp)
  case CALL(__) then
    let func_str = dumpCref(function_)
    let args_str = dumpFunctionArgs(functionArgs)
    '<%func_str%>(<%args_str%>)'
  case ARRAY(__) then
    let array_str = (arrayExp |> e => dumpExp(e) ;separator=", ")
    '{<%array_str%>}'
  case MATRIX(__) then
    let matrix_str = (matrix |> row =>
        (row |> e => dumpExp(e) ;separator=", ") ;separator="; ")
    '[<%matrix_str%>]'
  case e as RANGE(step = SOME(step)) then
    let start_str = dumpOperand(start, e)
    let step_str = dumpOperand(step, e)
    let stop_str = dumpOperand(stop, e)
    '<%start_str%>:<%step_str%>:<%stop_str%>'
  case e as RANGE(step = NONE()) then
    let start_str = dumpOperand(start, e)
    let stop_str = dumpOperand(stop, e)
    '<%start_str%>:<%stop_str%>'
  case TUPLE(__) then
    let tuple_str = (expressions |> e => dumpExp(e); separator=", ")
    '(<%tuple_str%>)'
  case END(__) then 'end'
  case AS(__) then 'as'
  case CONS(__) then
    let head_str = dumpExp(head)
    let rest_str = dumpExp(rest)
    '<%head_str%> :: <%rest_str%>'
  case MATCHEXP(__) then dumpMatchExp(exp)
  case LIST(__) then
    let list_str = (exps |> e => dumpExp(e) ;separator=", ")
    '{<%list_str%>}'
end dumpExp;

template dumpOperand(Absyn.Exp operand, Absyn.Exp operation)
::=
  let op_str = dumpExp(operand)
  if intLt(expPriority(operation), expPriority(operand)) then
    '(<%op_str%>)'
  else
    op_str
end dumpOperand;

template dumpIfExp(Absyn.Exp if_exp)
::=
match if_exp
  case IFEXP(__) then
    let cond_str = dumpExp(ifExp)
    let true_branch_str = dumpExp(trueBranch)
    let else_branch_str = dumpExp(elseBranch)
    let else_if_str = dumpElseIfExp(elseIfBranch)
    'if <%cond_str%> then <%true_branch_str%><%else_if_str%> else <%else_branch_str%>'
end dumpIfExp;

template dumpElseIfExp(list<tuple<Absyn.Exp, Absyn.Exp>> else_if)
::=
  else_if |> eib as (cond, branch) =>
    let cond_str = dumpExp(cond)
    let branch_str = dumpExp(branch)
    ' elseif <%cond_str%> then <%branch_str%>' ;separator="\n"
end dumpElseIfExp;

template dumpMatchExp(Absyn.Exp match_exp)
::= "MATCH_EXP"
end dumpMatchExp;

template dumpOperator(Absyn.Operator op)
::=
match op
  case ADD(__) then '+'
  case SUB(__) then '-'
  case MUL(__) then '*'
  case DIV(__) then '/'
  case POW(__) then '^'
  case UPLUS(__) then '+'
  case UMINUS(__) then '-'
  case ADD_EW(__) then '.+'
  case SUB_EW(__) then '.-'
  case MUL_EW(__) then '.*'
  case DIV_EW(__) then './'
  case POW_EW(__) then '.^'
  case UPLUS_EW(__) then '.+'
  case UMINUS_EW(__) then '.-'
  case AND(__) then 'and'
  case OR(__) then 'or'
  case NOT(__) then 'not'
  case LESS(__) then '<'
  case LESSEQ(__) then '<='
  case GREATER(__) then '>'
  case GREATEREQ(__) then '>='
  case EQUAL(__) then '=='
  case NEQUAL(__) then '<>'
end dumpOperator;

template dumpCref(Absyn.ComponentRef cref)
::=
match cref
  case CREF_QUAL(__) then
    '<%name%><%dumpSubscripts(subscripts)%>.<%dumpCref(componentRef)%>'
  case CREF_IDENT(__)
    then '<%name%><%dumpSubscripts(subscripts)%>'
  case CREF_FULLYQUALIFIED(__) then '.<%dumpCref(componentRef)%>'
  case WILD(__) then '_'
  case ALLWILD(__) then '__'
  case CREF_INVALID(__) then 'INVALID(<%dumpCref(cref)%>'
end dumpCref;

template dumpFunctionArgs(Absyn.FunctionArgs args)
::=
match args
  case FUNCTIONARGS(__) then
    let args_str = (args |> arg => dumpExp(arg) ;separator=", ")
    let namedargs_str = (argNames |> narg => dumpNamedArg(narg) ;separator=", ")
    let separator = if args_str then if argNames then ', '
    '<%args_str%><%separator%><%namedargs_str%>'
  case FOR_ITER_FARG(__) then
    let exp_str = dumpExp(exp)
    let iter_str = (iterators |> i => dumpForIterator(i) ;separator=", ")
    '<%exp_str%> for <%iter_str%>'
end dumpFunctionArgs;

template dumpNamedArg(Absyn.NamedArg narg)
::=
match narg
  case NAMEDARG(__) then
    '<%argName%> = <%dumpExp(argValue)%>'
end dumpNamedArg;

template dumpForIterator(Absyn.ForIterator iterator)
::=
match iterator
  case ITERATOR(__) then
    let range_str = match range case SOME(r) then ' in <%dumpExp(r)%>'
    let guard_str = match guardExp case SOME(g) then ' guard <%dumpExp(g)%>'
    '<%name%><%range_str%><%guard_str%>'
end dumpForIterator;

template errorMsg(String errMessage)
::=
let() = Tpl.addTemplateError(errMessage)
<<
<%errMessage%>
>>
end errorMsg;

end AbsynDumpTpl;
