package SCodeDumpTpl

import interface SCodeTV;
import AbsynDumpTpl;

template dumpProgram(list<SCode.Element> program, SCodeDumpOptions options)
::= dumpElements(program, false, options)
end dumpProgram;

template dumpElements(list<SCode.Element> elements, Boolean indent, SCodeDumpOptions options)
::= dumpElements2(filterElements(elements,options), "", indent, true, true, options)
end dumpElements;

template dumpElements2(list<SCode.Element> elements, String prevSpacing,
    Boolean indent, Boolean firstElement, Boolean inPublicSection, SCodeDumpOptions options)
::=
match elements
  case el :: rest_els then
    let spacing = dumpElementSpacing(el)
    let pre_spacing = if not firstElement then
      dumpPreElementSpacing(spacing, prevSpacing)
    let el_str = dumpElement(el,'',options)
    let vis_str = dumpElementVisibility(el, inPublicSection)
    let rest_str = if vis_str then
        dumpElements2(rest_els, spacing, indent, false, boolNot(inPublicSection), options)
      else
        dumpElements2(rest_els, spacing, indent, false, inPublicSection, options)
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
  case CLASS_EXTENDS(__) then dumpClassDefSpacing(composition)
  case PARTS(__) then '<%\n%>'
end dumpClassDefSpacing;

template dumpElement(SCode.Element element, String each, SCodeDumpOptions options)
::=
match element
  case IMPORT(__) then
    match visibility
      case PROTECTED(__) then (match options case OPTIONS(stripProtectedImports=true) then "" else dumpImport(element)) else dumpImport(element)
  case EXTENDS(__) then dumpExtends(element,options)
  case CLASS(__) then dumpClass(element, each, options)
  case COMPONENT(__) then dumpComponent(element, each, options)
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
      'import <%name%> = <%AbsynDumpTpl.dumpPath(path)%>'
    case QUAL_IMPORT(__) then
      'import <%AbsynDumpTpl.dumpPath(path)%>'
    case UNQUAL_IMPORT(__) then
      'import <%AbsynDumpTpl.dumpPath(path)%>.*'
    else errorMsg("SCodeDump.dumpImport: Unknown import.")
  '<%visibility_str%><%import_str%>'
end dumpImport;

template dumpExtends(SCode.Element extends, SCodeDumpOptions options)
::=
match extends
  case EXTENDS(__) then
    let bc_str = AbsynDumpTpl.dumpPath(baseClassPath)
    let visibility_str = dumpVisibility(visibility)
    let mod_str = dumpModifier(modifications, options)
    let ann_str = dumpAnnotationOpt(ann, options)
    '<%visibility_str%>extends <%bc_str%><%mod_str%><%ann_str%>'
end dumpExtends;

template dumpClass(SCode.Element class, String each, SCodeDumpOptions options)
::=
match class
  case CLASS(__) then
    let prefix_str = dumpPrefixes(prefixes, each)
    let enc_str = dumpEncapsulated(encapsulatedPrefix)
    let partial_str = dumpPartial(partialPrefix)
    let res_str = dumpRestriction(restriction)
    let prefixes_str = '<%prefix_str%><%enc_str%><%partial_str%><%res_str%>'
    let cdef_str = dumpClassDef(classDef, options)
    let cmt_str = dumpClassComment(cmt, options)
    let ann_str = dumpClassAnnotation(cmt, options)
    let cc_str = dumpReplaceableConstrainClass(prefixes, options)
    let header_str = dumpClassHeader(classDef, name, restriction, cmt_str, options)
    let footer_str = dumpClassFooter(classDef, cdef_str, name, cmt_str, ann_str, cc_str)
    <<
    <%prefixes_str%> <%header_str%> <%footer_str%>
    >>
end dumpClass;

template dumpClassHeader(SCode.ClassDef classDef, String name, SCode.Restriction restr, String cmt, SCodeDumpOptions options)
::=
match classDef
  case CLASS_EXTENDS(__)
    then
    let mod_str = dumpModifier(modifications, options)
    'extends <%name%><%mod_str%> <%cmt%>'
  case PARTS(__) then '<%name%><%dumpRestrictionTypeVars(restr)%> <%cmt%>'
  else '<%name%>'
end dumpClassHeader;

template dumpClassDef(SCode.ClassDef classDef, SCodeDumpOptions options)
::=
match classDef
  case p as PARTS(__) then
    let el_str = dumpElements(elementLst, true, options)
    let neq_str = dumpEquations(normalEquationLst, "equation", options)
    let ieq_str = dumpEquations(initialEquationLst, "initial equation", options)
    let nal_str = match options case OPTIONS(stripAlgorithmSections=false) then dumpAlgorithmSections(p.normalAlgorithmLst, "algorithm", options)
    let ial_str = match options case OPTIONS(stripAlgorithmSections=false) then dumpAlgorithmSections(p.initialAlgorithmLst, "initial algorithm", options)
    let extdecl_str = dumpExternalDeclOpt(p.externalDecl, options)
    let cdef_str =
      <<
      <%el_str%>
      <%ieq_str%>
      <%ial_str%>
      <%neq_str%>
      <%nal_str%>
        <%extdecl_str%>
      >>
    cdef_str
  case CLASS_EXTENDS(__) then
    let mod_str = dumpModifier(modifications,options)
    let cdef_str = dumpClassDef(composition,options)
    <<
    <%cdef_str%>
    >>
  case DERIVED(__) then
    let type_str = AbsynDumpTpl.dumpTypeSpec(typeSpec)
    let mod_str = dumpModifier(modifications,options)
    let attr_str = dumpAttributes(attributes)
    '= <%attr_str%><%type_str%><%mod_str%>'
  case ENUMERATION(__) then
    let enum_str = if enumLst then
        (enumLst |> enum => dumpEnumLiteral(enum, options) ;separator=", ")
      else
        ':'
    '= enumeration(<%enum_str%>)'
  case PDER(__) then
    let func_str = AbsynDumpTpl.dumpPath(functionPath)
    '= der(<%func_str%>, <%derivedVariables ;separator=", "%>)'
  case OVERLOAD(__) then
    '= overload(<%pathLst |> path => AbsynDumpTpl.dumpPath(path); separator=", "%>)'
  else errorMsg("SCodeDump.dumpClassDef: Unknown class definition.")
end dumpClassDef;

template dumpClassFooter(SCode.ClassDef classDef, String cdefStr, String name, String cmt, String ann, String cc_str)
::=
match classDef
  case DERIVED(__) then '<%cdefStr%><%cmt%><%ann%><%cc_str%>'
  case ENUMERATION(__) then '<%cdefStr%><%cmt%><%ann%><%cc_str%>'
  case PDER(__) then cdefStr
  case _ then
    let annstr = if ann then '<%ann%>; ' else ''
    if cdefStr then
      <<

      <%cdefStr%>
      <%if annstr then " "%><%annstr%>
      end <%name%><%cc_str%>
      >>
    else
      <<
      <%annstr%>end <%name%><%cc_str%>
      >>
end dumpClassFooter;

template dumpClassComment(SCode.Comment comment, SCodeDumpOptions options)
::=
  match comment
    case COMMENT(__) then dumpCommentStr(comment, options)
end dumpClassComment;

template dumpClassAnnotation(SCode.Comment comment, SCodeDumpOptions options)
::=
  match comment
    case COMMENT(__) then dumpAnnotationOpt(annotation_, options)
end dumpClassAnnotation;

template dumpComponent(SCode.Element component, String each, SCodeDumpOptions options)
::=
match component
  case COMPONENT(__) then
    let prefix_str = dumpPrefixes(prefixes, each)
    let cc_str = dumpReplaceableConstrainClass(prefixes,options)
    let attr_pre_str = dumpAttributes(attributes)
    let attr_dim_str = dumpAttributeDim(attributes)
    let type_str = AbsynDumpTpl.dumpTypeSpec(typeSpec)
    let mod_str1 = dumpModifier(modifications,options)
    let mod_str = // If stripOutputBindings is set, we need to look for the direction
      match options
      case OPTIONS(stripOutputBindings=false) then mod_str1
      else match attributes
        case ATTR(direction=OUTPUT(__)) then ""
        else mod_str1
      end match
    let cond_str = match condition case SOME(cond) then ' if <%AbsynDumpTpl.dumpExp(cond)%>'
    let cmt_str = dumpComment(comment, options)
    '<%prefix_str%><%attr_pre_str%><%type_str%><%attr_dim_str%> <%name%><%mod_str%><%cond_str%><%cc_str%><%cmt_str%>'
end dumpComponent;

template dumpDefineUnit(SCode.Element defineUnit)
::=
match defineUnit
  case DEFINEUNIT(__) then
    let vis_str = dumpVisibility(visibility)
    let exp_str = match exp case SOME(e) then 'exp = "<%e%>"'
    let weight_str = match weight case SOME(w) then 'weight = <%w%>'
    let args_str = {exp_str, weight_str} ;separator=", "
    let pb = if args_str then '('
    let pe = if args_str then ')'
    'defineunit <%name%><%pb%><%args_str%><%pe%>'
end dumpDefineUnit;

template dumpEnumLiteral(SCode.Enum enum, SCodeDumpOptions options)
::=
match enum
  case ENUM(__) then
    let cmt_str = dumpComment(comment, options)
    '<%literal%><%cmt_str%>'
end dumpEnumLiteral;

template dumpEquations(list<SCode.Equation> equations, String label, SCodeDumpOptions options)
::=
  if equations then
    <<
    <%label%>
      <%equations |> eq => dumpEquation(eq, options) ;separator="\n"%>
    >>
end dumpEquations;

template dumpEquation(SCode.Equation equation, SCodeDumpOptions options)
::= match equation case EQUATION(__) then dumpEEquation(eEquation, options)
end dumpEquation;

template dumpEEquation(SCode.EEquation equation, SCodeDumpOptions options)
::=
match equation
  case EQ_IF(__) then dumpIfEEquation(equation, options)
  case EQ_EQUALS(__) then
    let lhs_str = AbsynDumpTpl.dumpLhsExp(expLeft)
    let rhs_str = AbsynDumpTpl.dumpExp(expRight)
    let cmt_str = dumpComment(comment, options)
    '<%lhs_str%> = <%rhs_str%><%cmt_str%>;'
  case EQ_CONNECT(__) then
    let lhs_str = AbsynDumpTpl.dumpCref(crefLeft)
    let rhs_str = AbsynDumpTpl.dumpCref(crefRight)
    let cmt_str = dumpComment(comment, options)
    'connect(<%lhs_str%>, <%rhs_str%>)<%cmt_str%>;'
  case EQ_FOR(__) then dumpForEEquation(equation, options)
  case EQ_WHEN(__) then dumpWhenEEquation(equation, options)
  case EQ_ASSERT(__) then
    let cond_str = AbsynDumpTpl.dumpExp(condition)
    let msg_str = AbsynDumpTpl.dumpExp(message)
    let lvl_str = dumpAssertionLevel(level)
    let cmt_str = dumpComment(comment, options)
    'assert(<%cond_str%>, <%msg_str%><%lvl_str%>)<%cmt_str%>;'
  case EQ_TERMINATE(__) then
    let msg_str = AbsynDumpTpl.dumpExp(message)
    let cmt_str = dumpComment(comment, options)
    'terminate(<%msg_str%>)<%cmt_str%>;'
  case EQ_REINIT(__) then
    let cref_str = AbsynDumpTpl.dumpCref(cref)
    let exp_str = AbsynDumpTpl.dumpExp(expReinit)
    let cmt_str = dumpComment(comment, options)
    'reinit(<%cref_str%>, <%exp_str%>)<%cmt_str%>;'
  case EQ_NORETCALL(__) then
    let exp_str = AbsynDumpTpl.dumpExp(exp)
    let cmt_str = dumpComment(comment, options)
    '<%exp_str%><%cmt_str%>;'
  else errorMsg("SCodeDump.dumpEEquation: Unknown EEquation.")
end dumpEEquation;

template dumpIfEEquation(SCode.EEquation ifequation, SCodeDumpOptions options)
::=
match ifequation
  case EQ_IF(condition = if_cond :: elseif_conds,
             thenBranch = if_branch :: elseif_branches) then
    let if_cond_str = AbsynDumpTpl.dumpExp(if_cond)
    let if_branch_str = (if_branch |> e => dumpEEquation(e, options) ;separator="\n")
    let elseif_str = dumpElseIfEEquation(elseif_conds, elseif_branches, options)
    let else_str = if elseBranch then
      <<
      else
        <%elseBranch |> e => dumpEEquation(e, options) ;separator="\n"%>
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
    list<list<SCode.EEquation>> branches, SCodeDumpOptions options)
::=
match condition
  case cond :: rest_conds then
    match branches
      case branch :: rest_branches then
        let cond_str = AbsynDumpTpl.dumpExp(cond)
        let branch_str = (branch |> e => dumpEEquation(e, options) ;separator="\n")
        let rest_str = dumpElseIfEEquation(rest_conds, rest_branches, options)
        <<
        elseif <%cond_str%> then
          <%branch_str%>
        <%rest_str%>
        >>
end dumpElseIfEEquation;

template dumpForEEquation(SCode.EEquation for_equation, SCodeDumpOptions options)
::=
match for_equation
  case EQ_FOR(range=SOME(range)) then
    let range_str = AbsynDumpTpl.dumpExp(range)
    let eq_str = (eEquationLst |> e => dumpEEquation(e, options) ;separator="\n")
    let cmt_str = dumpComment(comment, options)
    <<
    for <%index%> in <%range_str%> loop
      <%eq_str%>
    end for<%cmt_str%>;
    >>
  case EQ_FOR(__) then
    let eq_str = (eEquationLst |> e => dumpEEquation(e, options) ;separator="\n")
    let cmt_str = dumpComment(comment, options)
    <<
    for <%index%> loop
      <%eq_str%>
    end for<%cmt_str%>;
    >>
end dumpForEEquation;

template dumpWhenEEquation(SCode.EEquation when_equation, SCodeDumpOptions options)
::=
match when_equation
  case EQ_WHEN(__) then
    let cond_str = AbsynDumpTpl.dumpExp(condition)
    let body_str = (eEquationLst |> e => dumpEEquation(e, options) ;separator="\n")
    let else_str = (elseBranches |> (else_cond, else_body) =>
      let else_cond_str = AbsynDumpTpl.dumpExp(else_cond)
      let else_body_str = (else_body |> e => dumpEEquation(e, options) ;separator="\n")
      <<
      elsewhen <%else_cond_str%> then
        <%else_body_str%>
      >> ;separator="\n")
    let cmt_str = dumpComment(comment, options)
    <<
    when <%cond_str%> then<%cmt_str%>
      <%body_str%>
    <%else_str%>
    end when;
    >>
end dumpWhenEEquation;

template dumpAssertionLevel(Absyn.Exp exp)
::= match exp
  case CREF(componentRef = CREF_FULLYQUALIFIED(componentRef = CREF_QUAL(
    name = "AssertionLevel", componentRef = CREF_IDENT(name = "error")))) then ""
  case CREF(componentRef = CREF_QUAL(name = "AssertionLevel",
    componentRef = CREF_IDENT(name = "error"))) then ""
  else ', <%AbsynDumpTpl.dumpExp(exp)%>'
end dumpAssertionLevel;

template dumpAlgorithmSections(list<SCode.AlgorithmSection> algorithms,
    String label, SCodeDumpOptions options)
::=
  if algorithms then
    <<
    <%label%>
      <%algorithms |> al => dumpAlgorithmSection(al, options) ;separator="\n"%>
    >>
end dumpAlgorithmSections;

template dumpAlgorithmSection(SCode.AlgorithmSection algorithm, SCodeDumpOptions options)
::= match algorithm case ALGORITHM(__) then dumpStatements(statements, options)
end dumpAlgorithmSection;

template dumpStatements(list<SCode.Statement> statements, SCodeDumpOptions options)
::= statements |> s => dumpStatement(s, options) ;separator="\n"
end dumpStatements;

template dumpStatement(SCode.Statement statement, SCodeDumpOptions options)
::=
match statement
  case ALG_ASSIGN(__) then
    let lhs_str = AbsynDumpTpl.dumpLhsExp(assignComponent)
    let rhs_str = AbsynDumpTpl.dumpExp(value)
    let cmt_str = dumpComment(comment, options)
    '<%lhs_str%> := <%rhs_str%><%cmt_str%>;'
  case ALG_IF(__) then dumpIfStatement(statement, options)
  case ALG_FOR(__) then dumpForStatement(statement, options)
  case ALG_WHILE(__) then dumpWhileStatement(statement, options)
  case ALG_WHEN_A(__) then dumpWhenStatement(statement, options)
  case ALG_ASSERT(__) then
    let cond_str = AbsynDumpTpl.dumpExp(condition)
    let msg_str = AbsynDumpTpl.dumpExp(message)
    let lvl_str = dumpAssertionLevel(level)
    'assert(<%cond_str%>, <%msg_str%><%lvl_str%>);'
  case ALG_TERMINATE(__) then
    let msg_str = AbsynDumpTpl.dumpExp(message)
    'terminate(<%msg_str%>);'
  case ALG_REINIT(__) then
    let cr_str = AbsynDumpTpl.dumpCref(cref)
    let exp_str = AbsynDumpTpl.dumpExp(newValue)
    'reinit(<%cr_str%>, <%exp_str%>);'
  case ALG_NORETCALL(__) then
    let exp_str = AbsynDumpTpl.dumpExp(exp)
    let cmt_str = dumpComment(comment, options)
    '<%exp_str%><%cmt_str%>;'
  case ALG_RETURN(__) then
    let cmt_str = dumpComment(comment, options)
    'return<%cmt_str%>;'
  case ALG_BREAK(__) then
    let cmt_str = dumpComment(comment, options)
    'break<%cmt_str%>;'
  case ALG_FAILURE(stmts={stmt}) then
    let cmt_str = dumpComment(comment, options)
    'failure(<%dumpStatement(stmt,options)%>)<%cmt_str%>;'
  case SCode.ALG_TRY(__) then dumpTryStatement(statement, options)
  case ALG_CONTINUE(__) then
    let cmt_str = dumpComment(comment, options)
    'continue<%cmt_str%>;'
  else errorMsg("SCodeDump.dumpStatement: Unknown statement.")
end dumpStatement;

template dumpIfStatement(SCode.Statement if_statement, SCodeDumpOptions options)
::=
match if_statement
  case ALG_IF(__) then
    let cond_str = AbsynDumpTpl.dumpExp(boolExpr)
    let true_branch_str = dumpStatements(trueBranch, options)
    let else_if_str = dumpElseIfStatements(elseIfBranch, options)
    let else_branch_str = dumpStatements(elseBranch, options)
    let cmt_str = dumpComment(comment, options)
    <<
    if <%cond_str%> then<%cmt_str%>
      <%true_branch_str%>
    <%else_if_str%>
    else
      <%else_branch_str%>
    end if;
    >>
end dumpIfStatement;

template dumpElseIfStatements(list<tuple<Absyn.Exp, list<SCode.Statement>>> else_if, SCodeDumpOptions options)
::=
  else_if |> eib as (cond, body) =>
    let cond_str = AbsynDumpTpl.dumpExp(cond)
    let body_str = dumpStatements(body, options)
    <<
    elseif <%cond_str%> then
      <%body_str%>
    >> ;separator="\n"
end dumpElseIfStatements;

template dumpForStatement(SCode.Statement for_statement, SCodeDumpOptions options)
::=
match for_statement
  case ALG_FOR(range=SOME(e)) then
    let range_str = AbsynDumpTpl.dumpExp(e)
    let body_str = dumpStatements(forBody, options)
    let cmt_str = dumpComment(comment, options)
    <<
    for <%index%> in <%range_str%> loop
      <%body_str%>
    end for<%cmt_str%>;
    >>
  case ALG_FOR(__) then
    let body_str = dumpStatements(forBody, options)
    let cmt_str = dumpComment(comment, options)
    <<
    for <%index%> loop
      <%body_str%>
    end for<%cmt_str%>;
    >>
end dumpForStatement;

template dumpWhileStatement(SCode.Statement while_statement, SCodeDumpOptions options)
::=
match while_statement
  case ALG_WHILE(__) then
    let cond_str = AbsynDumpTpl.dumpExp(boolExpr)
    let body_str = dumpStatements(whileBody, options)
    let cmt_str = dumpComment(comment, options)
    <<
    while <%cond_str%> loop
      <%body_str%>
    end while;
    >>
end dumpWhileStatement;

template dumpWhenStatement(SCode.Statement when_statement, SCodeDumpOptions options)
::=
match when_statement
  case ALG_WHEN_A(branches = ((when_cond, when_body) :: elsewhens)) then
    let when_cond_str = AbsynDumpTpl.dumpExp(when_cond)
    let when_body_str = dumpStatements(when_body, options)
    let elsewhen_str = (elsewhens |> ew as (ew_cond, ew_body) =>
      let ew_cond_str = AbsynDumpTpl.dumpExp(ew_cond)
      let ew_body_str = dumpStatements(ew_body, options)
      <<
      elsewhen <%ew_cond_str%> then
        <%ew_body_str%>
      >> ;separator="\n")
    let cmt_str = dumpComment(comment, options)
    <<
    when <%when_cond_str%> then<%cmt_str%>
      <%when_body_str%>
    <%elsewhen_str%>
    end when;
    >>
end dumpWhenStatement;

template dumpTryStatement(SCode.Statement try_statement, SCodeDumpOptions options)
::=
match try_statement
  case s as ALG_TRY(__) then
    let cmt_str = dumpComment(comment, options)
    let algs1 = dumpStatements(body, options)
    let algs2 = dumpStatements(elseBody, options)
    <<
    try
      <%algs1%>
    else
      <%algs2%>
    end try<%cmt_str%>;
    >>
end dumpTryStatement;

template dumpPrefixes(SCode.Prefixes prefixes, String each)
::=
match prefixes
  case PREFIXES(__) then
    let redeclare_str = dumpRedeclare(redeclarePrefix)
    let final_str = dumpFinal(finalPrefix)
    let io_str = dumpInnerOuter(innerOuter)
    let replaceable_str = dumpReplaceable(replaceablePrefix)
    '<%redeclare_str%><%each%><%final_str%><%io_str%><%replaceable_str%>'
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

template dumpReplaceableConstrainClass(SCode.Prefixes replaceable, SCodeDumpOptions options)
::=
match replaceable
  case PREFIXES(replaceablePrefix = REPLACEABLE(cc = SOME(CONSTRAINCLASS(
      constrainingClass = cc_path, modifier = cc_mod)))) then
    let path_str = AbsynDumpTpl.dumpPath(cc_path)
    let mod_str = dumpModifier(cc_mod, options)
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
  case R_RECORD(__) then
    if isOperator then 'operator record' else 'record'
  case R_OPERATOR(__) then 'operator'
  case R_BLOCK(__) then 'block'
  case R_CONNECTOR(__) then
    if isExpandable then 'expandable connector' else 'connector'
  case R_OPERATOR(__) then 'operator'
  case R_TYPE(__) then 'type'
  case R_PACKAGE(__) then 'package'
  case R_FUNCTION(__) then dumpFunctionRestriction(functionRestriction)
  case R_ENUMERATION(__) then 'enumeration'
  case R_PREDEFINED_INTEGER(__) then 'IntegerType'
  case R_PREDEFINED_REAL(__) then 'RealType'
  case R_PREDEFINED_STRING(__) then 'StringType'
  case R_PREDEFINED_BOOLEAN(__) then 'BooleanType'
  case R_PREDEFINED_ENUMERATION(__) then 'EnumType'
  case R_METARECORD(__) then 'record'
  case R_UNIONTYPE(__) then 'uniontype'
  else errorMsg("SCodeDump.dumpRestriction: Unknown restriction.")
end dumpRestriction;

template dumpRestrictionTypeVars(SCode.Restriction restriction)
::=
match restriction
  case R_UNIONTYPE(__) then
    (if typeVars then ("<" + (typeVars |> tv => tv ; separator=",") + ">"))
  else ""
end dumpRestrictionTypeVars;

template dumpFunctionRestriction(SCode.FunctionRestriction funcRest)
::=
match funcRest
  case FR_NORMAL_FUNCTION(__) then if isImpure then 'impure function' else 'function'
  case FR_EXTERNAL_FUNCTION(__) then if isImpure then 'impure function' else 'function'

  case FR_OPERATOR_FUNCTION(__) then 'operator function'
  case FR_RECORD_CONSTRUCTOR(__) then 'function'
  else errorMsg("SCodeDump.dumpFunctionRestriction: Unknown Function restriction.")
end dumpFunctionRestriction;

template dumpModifier(SCode.Mod modifier, SCodeDumpOptions options)
::=
match modifier
  case MOD(__) then
    let binding_str = dumpModifierBinding(binding)
    let submod_str = if subModLst then
      '(<%(subModLst |> submod => dumpSubModifier(submod, options) ;separator=", ")%>)'
    '<%submod_str%><%binding_str%>'
end dumpModifier;

template dumpAnnotationModifier(SCode.Mod modifier, SCodeDumpOptions options)
::=
match modifier
  case MOD(__) then
    let binding_str = dumpModifierBinding(binding)
    let text = subModLst |> submod => dumpAnnotationSubModifier(submod, options) ;separator=", "
    let submod_str = if text then '(<%text%>)'
    '<%submod_str%><%binding_str%>'
end dumpAnnotationModifier;

template dumpModifierPrefix(SCode.Mod modifier)
::=
match modifier
  case MOD(__) then
    let final_str = dumpFinal(finalPrefix)
    let each_str = dumpEach(eachPrefix)
    '<%each_str%><%final_str%>'
  case REDECL(__) then
    let final_str = dumpFinal(finalPrefix)
    let each_str = dumpEach(eachPrefix)
    '<%each_str%><%final_str%>'
end dumpModifierPrefix;

template dumpRedeclModifier(SCode.Mod modifier, SCodeDumpOptions options)
::=
match modifier
  case REDECL(__) then
    let each_str = dumpEach(eachPrefix)
    '<%dumpElement(element, each_str, options)%>'
end dumpRedeclModifier;

template dumpModifierBinding(Option<Absyn.Exp> binding)
::= match binding case SOME(exp) then '<%\ %>= <%AbsynDumpTpl.dumpExp(exp)%>'
end dumpModifierBinding;

template dumpSubModifier(SCode.SubMod submod, SCodeDumpOptions options)
::=
match submod
  case NAMEMOD(mod = MOD(__)) then
    '<%dumpModifierPrefix(mod)%><%ident%><%dumpModifier(mod,options)%>'
  case NAMEMOD(mod = REDECL(__)) then
    '<%dumpRedeclModifier(mod,options)%>'
end dumpSubModifier;

template dumpAnnotationSubModifier(SCode.SubMod submod, SCodeDumpOptions options)
::=
match submod
  case NAMEMOD(mod = nameMod as MOD(__)) then
    (if Config.showAnnotations() then
      '<%dumpModifierPrefix(mod)%><%ident%><%dumpAnnotationModifier(nameMod,options)%>'
    else
      match ident
      case "choices"
      case "Documentation"
      case "Dialog"
      case "Diagram"
      case "Icon"
      case "Line"
      case "Placement"
      case "preferredView"
      case "conversion"
      case "defaultComponentName"
      case "revisionId"
      case "uses"
        then ""
      else '<%dumpModifierPrefix(nameMod)%><%ident%><%dumpAnnotationModifier(nameMod,options)%>')
  case NAMEMOD(mod = REDECL(__)) then
    '<%dumpRedeclModifier(mod,options)%>'
end dumpAnnotationSubModifier;

template dumpAttributes(SCode.Attributes attributes)
::=
match attributes
  case ATTR(__) then
    let ct_str = dumpConnectorType(connectorType)
    let prl_str = dumpParallelism(parallelism)
    let var_str = dumpVariability(variability)
    let dir_str = dumpDirection(direction)
    '<%prl_str%><%var_str%><%dir_str%><%ct_str%>'
end dumpAttributes;

template dumpConnectorType(SCode.ConnectorType connectorType)
::=
match connectorType
  case FLOW() then 'flow '
  case STREAM() then 'stream '
end dumpConnectorType;

template dumpParallelism(SCode.Parallelism parallelism)
::=
match parallelism
  case PARGLOBAL(__) then 'parglobal '
  case PARLOCAL(__) then 'parlocal '
end dumpParallelism;

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
::= match attributes case ATTR(__) then AbsynDumpTpl.dumpSubscripts(arrayDims)
end dumpAttributeDim;

template dumpAnnotationOpt(Option<SCode.Annotation> annotation, SCodeDumpOptions options)
::= match annotation case SOME(ann) then dumpAnnotation(ann, options)
end dumpAnnotationOpt;

template dumpAnnotation(SCode.Annotation annotation, SCodeDumpOptions options)
::=
  match annotation
    case ANNOTATION(__) then
     let modifStr = dumpAnnotationModifier(modification,options)
     if modifStr then '<%\ %>annotation<%modifStr%>'
end dumpAnnotation;

template dumpAnnotationElement(SCode.Annotation annotation, SCodeDumpOptions options)
::=
  let annstr = '<%dumpAnnotation(annotation, options)%>'
  if annstr then
    '<%\ %><%annstr%>;'
end dumpAnnotationElement;

template dumpExternalDeclOpt(Option<ExternalDecl> externalDecl, SCodeDumpOptions options)
::= match externalDecl case SOME(extdecl) then dumpExternalDecl(extdecl, options)
end dumpExternalDeclOpt;

template dumpExternalDecl(ExternalDecl externalDecl, SCodeDumpOptions options)
::=
let res = match externalDecl
  case EXTERNALDECL(__) then
    let func_name_str = match funcName case SOME(name) then name
    let func_args_str = (args |> arg => AbsynDumpTpl.dumpExp(arg) ;separator=", ")
    let func_str = if func_name_str then ' <%func_name_str%>(<%func_args_str%>)'
    let lang_str = match lang case SOME(l) then ' "<%l%>"'
    let ann_str = dumpAnnotationOpt(annotation_, options)
    let output_str = match output_ case SOME(name) then ' <%AbsynDumpTpl.dumpCref(name)%> ='
    'external<%lang_str%><%output_str%><%func_str%><%ann_str%>;'
match externalDecl
  case EXTERNALDECL(lang=SOME("builtin")) then res
  else match options case OPTIONS(stripExternalDecl=false) then res
end dumpExternalDecl;

template dumpCommentOpt(Option<SCode.Comment> comment, SCodeDumpOptions options)
::= match comment case SOME(cmt) then dumpComment(cmt, options)
end dumpCommentOpt;

template dumpComment(SCode.Comment comment, SCodeDumpOptions options)
::=
  match comment
    case COMMENT(__) then
      let ann_str = dumpAnnotationOpt(annotation_, options)
      let cmt_str = dumpCommentStr(comment, options)
      '<%cmt_str%><%ann_str%>'
end dumpComment;

template dumpCommentStr(Option<String> comment, SCodeDumpOptions options)
::=
match options case OPTIONS(stripStringComments=false) then
match comment case SOME(cmt) then '<%\ %>"<%System.escapedString(cmt,false)%>"'
end dumpCommentStr;

template errorMsg(String errMessage)
::=
let() = Tpl.addTemplateError(errMessage)
<<
<%errMessage%>
>>
end errorMsg;

annotation(__OpenModelica_Interface="frontend");
end SCodeDumpTpl;
// vim: filetype=susan sw=2 sts=2
