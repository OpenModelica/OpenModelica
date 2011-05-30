package SCodeDumpTpl

import interface SCodeTV;

template dumpProgram(list<SCode.Element> program)
::= dumpElements(program, false)
end dumpProgram;

template dumpElements(list<SCode.Element> elements, Boolean indent)
::= dumpElements2(elements, "", indent, true, true)
end dumpElements;

template dumpElements2(list<SCode.Element> elements, String prevSpacing, 
    Boolean indent, Boolean firstElement, Boolean inPublicSection)
::=
match elements
  case el :: rest_els then
    let spacing = dumpElementSpacing(el)
    let pre_spacing = if not firstElement then 
      dumpPreElementSpacing(spacing, prevSpacing)
    let el_str = dumpElement(el)
    let vis_str = dumpElementVisibility(el, inPublicSection)
    let rest_str = if vis_str then
        dumpElements2(rest_els, spacing, indent, false, boolNot(inPublicSection))
      else
        dumpElements2(rest_els, spacing, indent, false, inPublicSection)
    let post_spacing = if rest_str then spacing
    let elements_str = if indent then
      <<
      <%pre_spacing%><%vis_str%>
        <%el_str%>;<%post_spacing%><%\n%>
      <%rest_str%>
      >>
      else
      <<
      <%pre_spacing%><%vis_str%>
      <%el_str%>;<%post_spacing%><%\n%>
      <%rest_str%>
      >>
    elements_str
end dumpElements2;
  
template dumpPreElementSpacing(String curSpacing, String prevSpacing)
::= if not prevSpacing then curSpacing
end dumpPreElementSpacing;

template dumpElementSpacing(SCode.Element element)
::= match element case CLASS(__) then dumpClassDefSpacing(classDef)
end dumpElementSpacing;

template dumpClassDefSpacing(SCode.ClassDef classDef)
::=
match classDef
  case PARTS(elementLst = {}, normalEquationLst = {}, initialEquationLst = {},
      normalAlgorithmLst = {}, initialAlgorithmLst = {}, externalDecl = NONE(),
      annotationLst = {}) then
    dumpCommentSpacing(comment)
  case CLASS_EXTENDS(__) then dumpClassDefSpacing(composition)
  case PARTS(__) then '<%\n%>'
end dumpClassDefSpacing;

template dumpCommentSpacing(Option<SCode.Comment> comment)
::=
match comment
  case SOME(COMMENT(annotation_ = NONE())) then ""
  case SOME(CLASS_COMMENT(annotations = {})) then ""
  else '<%\n%>'
end dumpCommentSpacing;

template dumpElement(SCode.Element element)
::=
match element
  case IMPORT(__) then dumpImport(element)
  case EXTENDS(__) then dumpExtends(element)
  case CLASS(__) then dumpClass(element)
  case COMPONENT(__) then dumpComponent(element)
  case DEFINEUNIT(__) then dumpDefineUnit(element)
  else errorMsg("SCodeDump.dumpElement: Unknown element.")
end dumpElement;

template dumpElementVisibility(SCode.Element element, Boolean inPublicSection)
::=
match element
  case IMPORT(__) then dumpSectionVisibility(visibility, inPublicSection)
  case EXTENDS(__) then dumpSectionVisibility(visibility, inPublicSection)
  case CLASS(prefixes = PREFIXES(visibility = vis)) then
    dumpSectionVisibility(vis, inPublicSection)
  case COMPONENT(prefixes = PREFIXES(visibility = vis)) then
    dumpSectionVisibility(vis, inPublicSection)
  case DEFINEUNIT(__) then dumpSectionVisibility(visibility, inPublicSection)
end dumpElementVisibility;

template dumpSectionVisibility(SCode.Visibility visibility, 
    Boolean inPublicSection)
::=
match visibility
  case SCode.PUBLIC(__) then
    if not inPublicSection then 'public<%\n%>'
  case SCode.PROTECTED(__) then
    if inPublicSection then 'protected<%\n%>'
end dumpSectionVisibility;

template dumpImport(SCode.Element import)
::=
match import
case IMPORT(__) then
  let visibility_str = dumpVisibility(visibility)
  let import_str = match imp
    case NAMED_IMPORT(__) then
      'import <%name%> = <%dumpPath(path)%>'
    case QUAL_IMPORT(__) then
      'import <%dumpPath(path)%>'
    case UNQUAL_IMPORT(__) then
      'import <%dumpPath(path)%>.*'
    else errorMsg("SCodeDump.dumpImport: Unknown import.")
  '<%visibility_str%><%import_str%>'
end dumpImport;

template dumpExtends(SCode.Element extends)
::=
match extends
  case EXTENDS(__) then
    let bc_str = dumpPath(baseClassPath)
    let visibility_str = dumpVisibility(visibility)
    let mod_str = dumpModifier(modifications)
    let ann_str = dumpAnnotationOpt(ann)
    '<%visibility_str%>extends <%bc_str%><%mod_str%><%ann_str%>' 
end dumpExtends;

template dumpClass(SCode.Element class)
::=
match class
  case CLASS(__) then
    let prefix_str = dumpPrefixes(prefixes)
    let enc_str = dumpEncapsulated(encapsulatedPrefix)
    let partial_str = dumpPartial(partialPrefix)
    let res_str = dumpRestriction(restriction)
    let prefixes_str = '<%prefix_str%><%enc_str%><%partial_str%><%res_str%>'
    let cdef_str = dumpClassDef(classDef)
    let header_str = dumpClassHeader(classDef, name)
    let footer_str = dumpClassFooter(classDef, cdef_str, name)
    let cmt_str = dumpClassComment(classDef)
    let cmt2_str = if cdef_str then 
        if cmt_str then 
          '<%\n%> <%cmt_str%>' 
        else "" 
      else cmt_str
    <<
    <%prefixes_str%> <%header_str%><%cmt2_str%> <%footer_str%>
    >>
end dumpClass;

template dumpClassHeader(SCode.ClassDef classDef, String name)
::=
match classDef
  case CLASS_EXTENDS(__) then 'extends <%name%>'
  else name
end dumpClassHeader;

template dumpClassDef(SCode.ClassDef classDef)
::=
match classDef
  case PARTS(__) then
    let el_str = dumpElements(elementLst, true)
    let neq_str = dumpEquations(normalEquationLst, "equation")
    let ieq_str = dumpEquations(initialEquationLst, "initial equation")
    let nal_str = dumpAlgorithmSections(normalAlgorithmLst, "algorithm")
    let ial_str = dumpAlgorithmSections(initialAlgorithmLst, "initial algorithm")
    let extdecl_str = dumpExternalDeclOpt(externalDecl)
    let annl_str = (annotationLst |> ann => dumpAnnotation(ann) ;separator="\n")
    <<
    <%el_str%>
      <%annl_str%>
    <%ieq_str%>
    <%ial_str%>
    <%neq_str%>
    <%nal_str%>
      <%extdecl_str%>
    >>
  case CLASS_EXTENDS(__) then
    let mod_str = dumpModifier(modifications)
    let cdef_str = dumpClassDef(composition)
    <<
    <%cdef_str%>
    >>
  case DERIVED(__) then
    let type_str = dumpTypeSpec(typeSpec)
    let mod_str = dumpModifier(modifications)
    let attr_str = dumpAttributes(attributes) 
    let cmt_str = dumpCommentOpt(comment) 
    '= <%type_str%><%mod_str%><%cmt_str%>' 
  case ENUMERATION(__) then
    let enum_str = if enumLst then
        (enumLst |> enum => dumpEnumLiteral(enum) ;separator=", ")
      else
        ':'
    let cmt_str = dumpCommentOpt(comment)
    '= enumeration(<%enum_str%>)<%cmt_str%>'
  case PDER(__) then
    let func_str = dumpPath(functionPath)
    let cmt_str = dumpCommentOpt(comment)
    '= der(<%func_str%>, <%derivedVariables ;separator=", "%>)<%cmt_str%>'
  else errorMsg("SCodeDump.dumpClassDef: Unknown class definition.")
end dumpClassDef;

template dumpClassFooter(SCode.ClassDef classDef, String cdefStr, String name)
::=
match classDef
  case DERIVED(__) then cdefStr
  case ENUMERATION(__) then cdefStr
  case PDER(__) then cdefStr
  else
    if cdefStr then
      <<

      <%cdefStr%>
      end <%name%>
      >>
    else
      <<
      end <%name%>
      >>
end dumpClassFooter;

template dumpClassComment(SCode.ClassDef classDef)
::=
match classDef
  case PARTS(__) then dumpClassComment2(comment)
  case CLASS_EXTENDS(__) then dumpClassComment(composition)
  case DERIVED(__) then dumpClassComment2(comment)
  case ENUMERATION(__) then dumpClassComment2(comment)
  case OVERLOAD(__) then dumpClassComment2(comment)
  case PDER(__) then dumpClassComment2(comment)
end dumpClassComment;

template dumpClassComment2(Option<SCode.Comment> comment)
::= 
  match comment 
    case SOME(CLASS_COMMENT(comment = SOME(cmt))) then dumpComment(cmt)
    case SOME(cmt as COMMENT(__)) then dumpComment(cmt)
end dumpClassComment2;

template dumpComponent(SCode.Element component)
::=
match component
  case COMPONENT(__) then
    let prefix_str = dumpPrefixes(prefixes)
    let cc_str = dumpReplaceableConstrainClass(prefixes)
    let attr_pre_str = dumpAttributes(attributes)
    let attr_dim_str = dumpAttributeDim(attributes)
    let type_str = dumpTypeSpec(typeSpec)
    let mod_str = dumpModifier(modifications)
    let cmt_str = dumpCommentOpt(comment)
    '<%prefix_str%><%attr_pre_str%><%type_str%><%attr_dim_str%> <%name%><%mod_str%><%cc_str%><%cmt_str%>' 
end dumpComponent;

template dumpDefineUnit(SCode.Element defineUnit)
::= errorMsg("SCodeDump.dumpDefineUnit not implemented.")
end dumpDefineUnit;

template dumpEnumLiteral(SCode.Enum enum)
::=
match enum
  case ENUM(__) then
    let cmt_str = dumpCommentOpt(comment)
    '<%literal%><%cmt_str%>'
end dumpEnumLiteral;

template dumpEquations(list<SCode.Equation> equations, String label)
::=
  if equations then
    <<
    <%label%>
      <%equations |> eq => dumpEquation(eq) ;separator="\n"%>
    >>
end dumpEquations;

template dumpEquation(SCode.Equation equation)
::= match equation case EQUATION(__) then dumpEEquation(eEquation)
end dumpEquation;

template dumpEEquation(SCode.EEquation equation)
::=
match equation
  case EQ_IF(__) then dumpIfEEquation(equation)
  case EQ_EQUALS(__) then
    let lhs_str = dumpExp(expLeft)
    let rhs_str = dumpExp(expRight)
    let cmt_str = dumpCommentOpt(comment)
    '<%lhs_str%> = <%rhs_str%><%cmt_str%>;'
  case EQ_CONNECT(__) then
    let lhs_str = dumpCref(crefLeft)
    let rhs_str = dumpCref(crefRight)
    let cmt_str = dumpCommentOpt(comment)
    'connect(<%lhs_str%>, <%rhs_str%>)<%cmt_str%>;'
  case EQ_FOR(__) then dumpForEEquation(equation)
  case EQ_WHEN(__) then dumpWhenEEquation(equation)
  case EQ_ASSERT(__) then
    let cond_str = dumpExp(condition)
    let msg_str = dumpExp(message)
    let cmt_str = dumpCommentOpt(comment)
    'assert(<%cond_str%>, <%msg_str%>)<%cmt_str%>;'
  case EQ_TERMINATE(__) then
    let msg_str = dumpExp(message)
    let cmt_str = dumpCommentOpt(comment)
    'terminate(<%msg_str%>)<%cmt_str%>;'
  case EQ_REINIT(__) then
    let cref_str = dumpCref(cref)
    let exp_str = dumpExp(expReinit)
    let cmt_str = dumpCommentOpt(comment)
    'reinit(<%cref_str%>, <%exp_str%>)<%cmt_str%>;'
  case EQ_NORETCALL(__) then
    let func_str = dumpCref(functionName)
    let args_str = dumpFunctionArgs(functionArgs)
    let cmt_str = dumpCommentOpt(comment)
    '<%func_str%>(<%args_str%>)<%cmt_str%>;'
  else errorMsg("SCodeDump.dumpEEquation: Unknown EEquation.")
end dumpEEquation;

template dumpIfEEquation(SCode.EEquation ifequation)
::=
match ifequation
  case EQ_IF(condition = if_cond :: elseif_conds,
             thenBranch = if_branch :: elseif_branches) then
    let if_cond_str = dumpExp(if_cond)
    let if_branch_str = (if_branch |> e => dumpEEquation(e) ;separator="\n")
    let elseif_str = dumpElseIfEEquation(elseif_conds, elseif_branches)
    let else_str = if elseBranch then
      <<
      else
        <%elseBranch |> e => dumpEEquation(e) ;separator="\n"%>
      >>
    <<
    if <%if_cond_str%> then
      <%if_branch_str%>
    <%elseif_str%>
    <%else_str%>
    end if;
    >>
end dumpIfEEquation;

template dumpElseIfEEquation(list<Absyn.Exp> condition,
    list<list<SCode.EEquation>> branches)
::=
match condition
  case cond :: rest_conds then
    match branches
      case branch :: rest_branches then
        let cond_str = dumpExp(cond)
        let branch_str = (branch |> e => dumpEEquation(e) ;separator="\n")
        let rest_str = dumpElseIfEEquation(rest_conds, rest_branches)
        <<
        elseif <%cond_str%> then
          <%branch_str%>
        <%rest_str%>
        >>
end dumpElseIfEEquation;
  
template dumpForEEquation(SCode.EEquation for_equation)
::=
match for_equation
  case EQ_FOR(__) then
    let range_str = dumpExp(range)
    let eq_str = (eEquationLst |> e => dumpEEquation(e) ;separator="\n")
    let cmt_str = dumpCommentOpt(comment)
    <<
    for <%index%> in <%range_str%> loop<%cmt_str%>
      <%eq_str%>
    end for;
    >>
end dumpForEEquation;

template dumpWhenEEquation(SCode.EEquation when_equation)
::=
match when_equation
  case EQ_WHEN(__) then
    let cond_str = dumpExp(condition)
    let body_str = (eEquationLst |> e => dumpEEquation(e) ;separator="\n")
    let else_str = (elseBranches |> (else_cond, else_body) =>
      let else_cond_str = dumpExp(else_cond)
      let else_body_str = (else_body |> e => dumpEEquation(e) ;separator="\n")
      <<
      elsewhen <%else_cond_str%> then
        <%else_body_str%>
      >> ;separator="\n")
    let cmt_str = dumpCommentOpt(comment)
    <<
    when <%cond_str%> then<%cmt_str%>
      <%body_str%>
    <%else_str%>
    end when;
    >>
end dumpWhenEEquation;

template dumpAlgorithmSections(list<SCode.AlgorithmSection> algorithms, 
    String label)
::=
  if algorithms then
    <<
    <%label%>
      <%algorithms |> al => dumpAlgorithmSection(al) ;separator="\n"%>
    >>
end dumpAlgorithmSections;

template dumpAlgorithmSection(SCode.AlgorithmSection algorithm)
::= match algorithm case ALGORITHM(__) then dumpStatements(statements)
end dumpAlgorithmSection;

template dumpStatements(list<SCode.Statement> statements)
::= statements |> s => dumpStatement(s) ;separator="\n"
end dumpStatements;

template dumpStatement(SCode.Statement statement)
::=
match statement
  case ALG_ASSIGN(__) then
    let lhs_str = dumpExp(assignComponent)
    let rhs_str = dumpExp(value)
    let cmt_str = dumpCommentOpt(comment)
    '<%lhs_str%> := <%rhs_str%><%cmt_str%>;'
  case ALG_IF(__) then dumpIfStatement(statement)
  case ALG_FOR(__) then dumpForStatement(statement)
  case ALG_WHILE(__) then dumpWhileStatement(statement)
  case ALG_WHEN_A(__) then dumpWhenStatement(statement)
  case ALG_NORETCALL(__) then
    let func_str = dumpCref(functionCall)
    let args_str = dumpFunctionArgs(functionArgs)
    let cmt_str = dumpCommentOpt(comment)
    '<%func_str%>(<%args_str%>)<%cmt_str%>;'
  case ALG_RETURN(__) then
    let cmt_str = dumpCommentOpt(comment)
    'return<%cmt_str%>;'
  case ALG_BREAK(__) then
    let cmt_str = dumpCommentOpt(comment)
    'break<%cmt_str%>;'
  else errorMsg("SCodeDump.dumpStatement: Unknown statement.")
end dumpStatement;

template dumpIfStatement(SCode.Statement if_statement)
::=
match if_statement
  case ALG_IF(__) then
    let cond_str = dumpExp(boolExpr)
    let true_branch_str = dumpStatements(trueBranch)
    let else_if_str = dumpElseIfStatements(elseIfBranch)
    let else_branch_str = dumpStatements(elseBranch)
    let cmt_str = dumpCommentOpt(comment)
    <<
    if <%cond_str%> then<%cmt_str%>
      <%true_branch_str%>
    <%else_if_str%>
    else
      <%else_branch_str%>
    end if;
    >>
end dumpIfStatement;

template dumpElseIfStatements(list<tuple<Absyn.Exp, list<SCode.Statement>>> else_if)
::=
  else_if |> eib as (cond, body) =>
    let cond_str = dumpExp(cond)
    let body_str = dumpStatements(body)
    <<
    elseif <%cond_str%> then
      <%body_str%>
    >> ;separator="\n"
end dumpElseIfStatements;

template dumpForStatement(SCode.Statement for_statement)
::=
match for_statement
  case ALG_FOR(__) then
    let iter_str = (iterators |> i => dumpForIterator(i) ;separator=", ")
    let body_str = dumpStatements(forBody)
    let cmt_str = dumpCommentOpt(comment)
    <<
    for <%iter_str%> loop<%cmt_str%>
      <%body_str%>
    end for;
    >>
end dumpForStatement;

template dumpForIterator(Absyn.ForIterator iterator)
::=
match iterator
  case ITERATOR(__) then
    let range_str = match range case SOME(r) then ' in <%dumpExp(r)%>'
    let guard_str = match guardExp case SOME(g) then ' guard <%dumpExp(g)%>'
    '<%name%><%range_str%><%guard_str%>'
end dumpForIterator;
    
template dumpWhileStatement(SCode.Statement while_statement)
::=
match while_statement
  case ALG_WHILE(__) then
    let cond_str = dumpExp(boolExpr)
    let body_str = dumpStatements(whileBody)
    let cmt_str = dumpCommentOpt(comment)
    <<
    while <%cond_str%> loop
      <%body_str%>
    end while;
    >>
end dumpWhileStatement;

template dumpWhenStatement(SCode.Statement when_statement)
::=
match when_statement
  case ALG_WHEN_A(branches = ((when_cond, when_body) :: elsewhens)) then
    let when_cond_str = dumpExp(when_cond)
    let when_body_str = dumpStatements(when_body)
    let elsewhen_str = (elsewhens |> ew as (ew_cond, ew_body) =>
      let ew_cond_str = dumpExp(ew_cond)
      let ew_body_str = dumpStatements(ew_body)
      <<
      elsewhen <%ew_cond_str%> then
        <%ew_body_str%>
      >> ;separator="\n")
    let cmt_str = dumpCommentOpt(comment)
    <<
    when <%when_cond_str%> then<%cmt_str%>
      <%when_body_str%>
    <%elsewhen_str%>
    end when;
    >>
end dumpWhenStatement;

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
    '<%name%><%dumpSubscripts(subScripts)%>.<%dumpCref(componentRef)%>'
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

template dumpPrefixes(SCode.Prefixes prefixes)
::=
match prefixes
  case PREFIXES(__) then
    let redeclare_str = dumpRedeclare(redeclarePrefix)
    let final_str = dumpFinal(finalPrefix)
    let io_str = dumpInnerOuter(innerOuter)
    let replaceable_str = dumpReplaceable(replaceablePrefix)
    '<%redeclare_str%><%final_str%><%io_str%><%replaceable_str%>'
end dumpPrefixes;

template dumpVisibility(SCode.Visibility visibility)
::=
match visibility
  case PROTECTED(__) then 'protected '
end dumpVisibility;

template dumpRedeclare(SCode.Redeclare redeclare)
::=
match redeclare
  case REDECLARE(__) then 'redeclare '
end dumpRedeclare;

template dumpFinal(SCode.Final final)
::=
match final
  case FINAL(__) then 'final '
end dumpFinal;

template dumpInnerOuter(Absyn.InnerOuter innerOuter)
::=
match innerOuter
  case INNER(__) then 'inner '
  case OUTER(__) then 'outer '
  case INNER_OUTER(__) then 'inner outer '
end dumpInnerOuter;

template dumpReplaceable(SCode.Replaceable replaceable)
::=
match replaceable
  case REPLACEABLE(__) then 
    'replaceable '
end dumpReplaceable;

template dumpReplaceableConstrainClass(SCode.Prefixes replaceable)
::=
match replaceable
  case PREFIXES(replaceablePrefix = REPLACEABLE(cc = SOME(CONSTRAINCLASS(
      constrainingClass = cc_path, modifier = cc_mod)))) then
    let path_str = dumpPath(cc_path)
    let mod_str = dumpModifier(cc_mod)
    ' constrainedby <%path_str%><%mod_str%>'
end dumpReplaceableConstrainClass;
    
template dumpEach(SCode.Each each)
::=
match each
  case EACH(__) then 'each '
end dumpEach;

template dumpEncapsulated(SCode.Encapsulated encapsulated)
::=
match encapsulated
  case ENCAPSULATED(__) then 'encapsulated '
end dumpEncapsulated;

template dumpPartial(SCode.Partial partial)
::=
match partial
  case PARTIAL(__) then 'partial '
end dumpPartial;

template dumpRestriction(SCode.Restriction restriction)
::=
match restriction
  case R_CLASS(__) then 'class'
  case R_OPTIMIZATION(__) then 'optimization'
  case R_MODEL(__) then 'model'
  case R_RECORD(__) then 'record'
  case R_BLOCK(__) then 'block'
  case R_CONNECTOR(__) then
    if isExpandable then 'expandable connector' else 'connector'
  case R_OPERATOR(__) then
    if isFunction then 'operator function' else 'operator'
  case R_TYPE(__) then 'type'
  case R_PACKAGE(__) then 'package'
  case R_FUNCTION(__) then 'function'
  case R_EXT_FUNCTION(__) then 'function'
  case R_ENUMERATION(__) then 'enumeration'
  case R_PREDEFINED_INTEGER(__) then 'IntegerType'
  case R_PREDEFINED_REAL(__) then 'RealType'
  case R_PREDEFINED_STRING(__) then 'StringType'
  case R_PREDEFINED_BOOLEAN(__) then 'BooleanType'
  case R_PREDEFINED_ENUMERATION(__) then 'EnumType'
  case R_METARECORD(__) then 'record'
  case R_UNIONTYPE(__) then 'uniontype'
  else errorMsg("SCodeDimp.dumpRestriction: Unknown restriction.")
end dumpRestriction;

template dumpModifier(SCode.Mod modifier)
::=
match modifier
  case MOD(__) then
    let binding_str = dumpModifierBinding(binding)
    let prefix_str = match subModLst 
      case NAMEMOD(A = m) :: _ then 
        dumpModifierPrefix(m)
      case IDXMOD(an = m) :: _ then
        dumpModifierPrefix(m)
    let submod_str = if subModLst then 
      '(<%prefix_str%><%(subModLst |> submod => dumpSubModifier(submod) ;separator=", ")%>)'
    '<%submod_str%><%binding_str%>'
end dumpModifier;

template dumpModifierPrefix(SCode.Mod modifier)
::=
match modifier
  case MOD(__) then
    let final_str = dumpFinal(finalPrefix)
    let each_str = dumpEach(eachPrefix)
    '<%final_str%><%each_str%>'
  case REDECL(__) then
    let final_str = dumpFinal(finalPrefix)
    let each_str = dumpEach(eachPrefix)
    '<%final_str%><%each_str%>'
end dumpModifierPrefix;

template dumpRedeclModifier(SCode.Mod modifier)
::=
match modifier
  case REDECL(__) then
    let final_str = dumpFinal(finalPrefix)
    let each_str = dumpEach(eachPrefix)
    let el_str = (elementLst |> e => dumpElement(e) ;separator=", ")
    '<%final_str%><%each_str%><%el_str%>'
end dumpRedeclModifier;
    
template dumpModifierBinding(Option<tuple<Absyn.Exp, Boolean>> binding)
::= match binding case SOME((exp, _)) then ' = <%dumpExp(exp)%>'
end dumpModifierBinding;

template dumpSubModifier(SCode.SubMod submod)
::=
match submod
  case NAMEMOD(A = MOD(__)) then
    '<%ident%><%dumpModifier(A)%>'
  case NAMEMOD(A = REDECL(__)) then
    '<%dumpRedeclModifier(A)%>'
  case IDXMOD(__) then
    '<%dumpSubscripts(subscriptLst)%><%dumpModifier(an)%>'
end dumpSubModifier;

template dumpAttributes(SCode.Attributes attributes)
::=
match attributes
  case ATTR(__) then
    let flow_str = dumpFlow(flowPrefix)
    let stream_str = dumpStream(streamPrefix)
    let var_str = dumpVariability(variability)
    let dir_str = dumpDirection(direction)
    '<%dir_str%><%var_str%><%flow_str%><%stream_str%>'
end dumpAttributes;

template dumpFlow(SCode.Flow flow)
::= match flow case FLOW(__) then 'flow '
end dumpFlow;

template dumpStream(SCode.Stream stream)
::= match stream case STREAM(__) then 'stream '
end dumpStream;

template dumpVariability(SCode.Variability variability)
::=
match variability
  case DISCRETE(__) then 'discrete '
  case PARAM(__) then 'parameter '
  case CONST(__) then 'constant '
end dumpVariability;

template dumpDirection(Absyn.Direction direction)
::=
match direction
  case INPUT(__) then 'input '
  case OUTPUT(__) then 'output '
end dumpDirection;

template dumpAttributeDim(SCode.Attributes attributes)
::= match attributes case ATTR(__) then dumpSubscripts(arrayDims)
end dumpAttributeDim;

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
  case SUBSCRIPT(__) then dumpExp(subScript)
end dumpSubscript;

template dumpAnnotationOpt(Option<SCode.Annotation> annotation)
::= match annotation case SOME(ann) then dumpAnnotation(ann)
end dumpAnnotationOpt;

template dumpAnnotation(SCode.Annotation annotation)
::=
match annotation
  case ANNOTATION(__) then 'annotation<%dumpModifier(modification)%>;'
end dumpAnnotation;

template dumpExternalDeclOpt(Option<ExternalDecl> externalDecl)
::= match externalDecl case SOME(extdecl) then dumpExternalDecl(extdecl)
end dumpExternalDeclOpt;

template dumpExternalDecl(ExternalDecl externalDecl)
::=
match externalDecl
  case EXTERNALDECL(__) then
    let func_name_str = match funcName case SOME(name) then name
    let func_args_str = (args |> arg => dumpExp(arg) ;separator=", ")
    let func_str = if func_name_str then ' <%func_name_str%>(<%func_args_str%>)'
    let lang_str = match lang case SOME(l) then ' "<%l%>"'
    let output_str = match output_ case SOME(name) then '<%dumpCref(name)%> ='
    'external<%lang_str%><%output_str%><%func_str%>;'
end dumpExternalDecl;

template dumpCommentOpt(Option<SCode.Comment> comment)
::= match comment case SOME(cmt) then dumpComment(cmt)
end dumpCommentOpt;

template dumpComment(SCode.Comment comment)
::= 
match comment
  case COMMENT(__) then
    let ann_str = dumpAnnotationOpt(annotation_)
    let cmt_str = dumpCommentStr(comment)
    '<%cmt_str%><%ann_str%>'
  case CLASS_COMMENT(__) then
    let annl_str = (annotations |> ann => dumpAnnotation(ann) ;separator="\n")
    let cmt_str = dumpCommentOpt(comment)
    '<%cmt_str%><%annl_str%>'
end dumpComment;

template dumpCommentStr(Option<String> comment)
::= match comment case SOME(cmt) then ' "<%cmt%>"'
end dumpCommentStr;

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

template errorMsg(String errMessage)
::=
let() = Tpl.addTemplateError(errMessage)
<<
<%errMessage%>
>>
end errorMsg;

end SCodeDumpTpl;
// vim: filetype=susan sw=2 sts=2
