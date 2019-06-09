package MMToJulia

import interface MMToJuliaTV;
import AbsynDumpTpl;
import SCodeDumpTpl;

template dumpProgram(list<SCode.Element> program)
::= dumpElements(program, false, packageContext)
end dumpProgram;

template dumpElements(list<SCode.Element> elements, Boolean indent, Context context)
::= dumpElements2(filterElements(elements, defaultOptions), indent, context)
end dumpElements;

template dumpElements2(list<SCode.Element> elements,
    Boolean indent, Context context)
::=
  (
  elements |> el hasindex i1 fromindex 1 =>
    match el
      case CLASS(restriction=R_UNIONTYPE(__)) then
      'abstract type <%name%> end<%\n%>'
  )
  +
  (elements |> el hasindex i1 fromindex 1 =>
    let el_str = dumpElement(el,'', context)
    if indent then
      <<
        <%el_str%><%\n%>
      >>
      else
      <<
      <%el_str%><%\n%>
      >>)
end dumpElements2;

template dumpPreElementSpacing(String curSpacing, Boolean prevSpacing)
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

template dumpElement(SCode.Element element, String each, Context context)
::=
match element
  case IMPORT(__) then
    dumpImport(element)
  case EXTENDS(__) then dumpExtends(element)
  case CLASS(__) then dumpClass(element, each)
  case COMPONENT(__) then dumpComponent(element, each, context)
  else error(sourceInfo(), "SCodeDump.dumpElement: Unknown element.")
end dumpElement;

template dumpImport(SCode.Element import)
::=
match import
case IMPORT(__) then
  match imp
    case NAMED_IMPORT(__) then
      'import <%name%> = <%dumpPathJL(path)%>'
    case QUAL_IMPORT(__) then
      'import <%dumpPathJL(path)%>'
    case UNQUAL_IMPORT(__) then
      'import <%dumpPathJL(path)%>.*'
    else error(sourceInfo(), "SCodeDump.dumpImport: Unknown import.")
end dumpImport;

template dumpExtends(SCode.Element extends)
::=
match extends
  case EXTENDS(__) then
    let bc_str = dumpPathJL(baseClassPath)
    let mod_str = dumpModifier(modifications)
    let ann_str = dumpAnnotationOpt(ann)
    'extends <%bc_str%><%mod_str%><%ann_str%>'
end dumpExtends;

template dumpClass(SCode.Element class, String each)
::=
match class
  case CLASS(restriction=R_UNIONTYPE(__)) then
    dumpClassDef(classDef, packageContext)
  case CLASS(partialPrefix=PARTIAL(__), restriction=R_FUNCTION(__)) then
    '<%name%> = Function' // Julia does not really support types of higher-order functions
  case CLASS(classDef=p as PARTS(__), restriction=R_FUNCTION(__)) then
    let cdef_str = dumpClassDef(classDef, functionContext)
    let cmt_str = dumpClassComment(cmt)
    let ann_str = dumpClassAnnotation(cmt)
    let returnType =
      match SCode.getOutputElements(p.elementLst)
        case {} then ""
        case L as H::{} then '::<%dumpOutputs(SCode.getOutputElements(p.elementLst))%>'
        case L as H::T then '::Tuple{<%dumpOutputs(SCode.getOutputElements(p.elementLst))%>}'
    let inputs = p.elementLst |> elt as COMPONENT(attributes=ATTR(direction=INPUT(__))) =>
      let type_str = dumpTypeSpec(elt.typeSpec)
      let mod_str = dumpModifier(elt.modifications)
      let cmt_str = dumpComment(elt.comment)
      '<%elt.name%>::<%type_str%><%mod_str%><%cmt_str%>'
      ; separator = ","
    <<
    function <%name%>(<%inputs%>)<%returnType%>
    <%cmt_str%>
      <%cdef_str%>
    <%ann_str%>
    end
    >>
  case CLASS(__) then
    let prefix_str = dumpPrefixes(prefixes, each)
    // let enc_str = dumpEncapsulated(encapsulatedPrefix)
    let partial_str = dumpPartial(partialPrefix)
    let res_str = dumpRestriction(restriction)
    let prefixes_str = '<%prefix_str%><%partial_str%><%res_str%>'
    let cdef_str1 = dumpClassDef(classDef, packageContext)
    let cdef_str2 = match restriction
      case R_PACKAGE(__) then
        <<
        using MetaModelica
        <%cdef_str1%>
        >>
      else cdef_str1
    let cdef_str = cdef_str2
    let cmt_str = dumpClassComment(cmt)
    let ann_str = dumpClassAnnotation(cmt)
    let header_str = dumpClassHeader(classDef, name, restriction, cmt_str)
    let footer_str = dumpClassFooter(classDef, cdef_str, name, cmt_str, ann_str)
    <<
    <%prefixes_str%> <%header_str%> <%footer_str%>
    >>
end dumpClass;

template dumpClassHeader(SCode.ClassDef classDef, String name, SCode.Restriction restr, String cmt)
::=
match classDef
  case CLASS_EXTENDS(__)
    then
    let mod_str = dumpModifier(modifications)
    'extends <%name%><%mod_str%> <%cmt%>'
  case PARTS(__) then '<%name%><%dumpRestrictionTypeVars(restr)%><%dumpRestrictionSuperType(restr)%> <%cmt%>'
  else '<%name%>'
end dumpClassHeader;

template dumpRestrictionSuperType(SCode.Restriction r)
::=
match r
case R_METARECORD(__) then '<: <%dumpPathJL(name)%>'
end dumpRestrictionSuperType;

template dumpClassDef(SCode.ClassDef classDef, Context context)
::=
match classDef
  case p as PARTS(__) then
    let el_str = dumpElements(elementLst, false, context)
    let neq_str = dumpEquations(normalEquationLst)
    let nal_str = dumpAlgorithmSections(p.normalAlgorithmLst)
    let extdecl_str = dumpExternalDeclOpt(p.externalDecl)
    let cdef_str =
      <<
      <%el_str%>
      <%neq_str%>
      <%nal_str%>
        <%extdecl_str%>
      >>
    cdef_str
  case CLASS_EXTENDS(__) then
    let mod_str = dumpModifier(modifications)
    let cdef_str = dumpClassDef(composition, packageContext)
    <<
    <%cdef_str%>
    >>
  case DERIVED(__) then
    let type_str = dumpTypeSpec(typeSpec)
    let mod_str = dumpModifier(modifications)
    // let attr_str = dumpAttributes(attributes)
    '= <%type_str%><%mod_str%>'
  case ENUMERATION(__) then
    let enum_str = if enumLst then
        (enumLst |> enum => dumpEnumLiteral(enum) ;separator=", ")
      else
        ':'
    '= enumeration(<%enum_str%>)'
  case PDER(__) then
    let func_str = dumpPathJL(functionPath)
    '= der(<%func_str%>, <%derivedVariables ;separator=", "%>)'
  case OVERLOAD(__) then
    '= overload(<%pathLst |> path => dumpPathJL(path); separator=", "%>)'
  else error(sourceInfo(), "SCodeDump.dumpClassDef: Unknown class definition.")
end dumpClassDef;

template dumpTypeSpec(Absyn.TypeSpec typeSpec)
::=
match typeSpec
  case TPATH(__) then
    let path_str = dumpPathJL(path)
    let arraydim_str = AbsynDumpTpl.dumpArrayDimOpt(arrayDim)
    '<%path_str%><%arraydim_str%>'
  case TCOMPLEX(__) then
    let path_str = (match path
       case IDENT(name="list") then 'List'
       else dumpPathJL(path))
    let ty_str = (typeSpecs |> ty => dumpTypeSpec(ty) ;separator=", ")
    let arraydim_str = AbsynDumpTpl.dumpArrayDimOpt(arrayDim)
    '<%path_str%>{<%ty_str%>}<%arraydim_str%>'
end dumpTypeSpec;

template dumpTypeSpecAF(Absyn.TypeSpec typeSpec)
::=
match typeSpec
  case TPATH(__) then
    let path_str = dumpPathJLAF(path)
    let arraydim_str = AbsynDumpTpl.dumpArrayDimOpt(arrayDim)
    '<%path_str%><%arraydim_str%>'
  case TCOMPLEX(__) then
    let path_str = (match path
       case IDENT(name="list") then 'List'
       else dumpPathJL(path))
    let ty_str = (typeSpecs |> ty => dumpTypeSpecAF(ty) ;separator=", ")
    let arraydim_str = AbsynDumpTpl.dumpArrayDimOpt(arrayDim)
    '<%path_str%>{<%ty_str%>}<%arraydim_str%>'
end dumpTypeSpecAF;

template dumpClassFooter(SCode.ClassDef classDef, String cdefStr, String name, String cmt, String ann)
::=
match classDef
  case DERIVED(__) then '<%cdefStr%><%cmt%><%ann%>'
  case ENUMERATION(__) then '<%cdefStr%><%cmt%><%ann%>'
  case _ then
    let annstr = if ann then '<%ann%> ' else ''
    if cdefStr then
      <<

        <%cdefStr%>
      <%if annstr then " "%><%annstr%>
      end
      >>
    else
      <<
      <%annstr%>end
      >>
end dumpClassFooter;

template dumpClassComment(SCode.Comment comment)
::=
  match comment
    case COMMENT(__) then dumpCommentStr(comment)
end dumpClassComment;

template dumpClassAnnotation(SCode.Comment comment)
::=
  match comment
    case COMMENT(__) then dumpAnnotationOpt(annotation_)
end dumpClassAnnotation;

template dumpComponent(SCode.Element component, String each, Context context)
::=
match component
  case COMPONENT(attributes=ATTR(direction=INPUT(__))) then ""
  case COMPONENT(__) then
    let prefix_str = dumpPrefixes(prefixes, each)
    let attr_pre_str = dumpAttributes(attributes, context)
    let attr_dim_str = dumpAttributeDim(attributes)
    let type_str = dumpTypeSpec(typeSpec)
    let mod_str1 = dumpModifier(modifications)
    let mod_str = // If stripOutputBindings is set, we need to look for the direction
      mod_str1
    let cond_str = match condition case SOME(cond) then ' if <%AbsynDumpTpl.dumpExp(cond)%>'
    let cmt_str = dumpComment(comment)
    '<%prefix_str%><%attr_pre_str%><%attr_dim_str%> <%name%><%mod_str%>::<%type_str%><%cond_str%><%cmt_str%>'
end dumpComponent;

template dumpEnumLiteral(SCode.Enum enum)
::=
match enum
  case ENUM(__) then
    let cmt_str = dumpComment(comment)
    '<%literal%><%cmt_str%>'
end dumpEnumLiteral;

template dumpEquations(list<SCode.Equation> equations)
::=
  equations |> eq => dumpEquation(eq) ;separator="\n"
end dumpEquations;

template dumpEquation(SCode.Equation equation)
::= match equation case EQUATION(__) then dumpEEquation(eEquation)
end dumpEquation;

template dumpEEquation(SCode.EEquation equation)
::=
match equation
  case EQ_IF(__) then dumpIfEEquation(equation)
  case EQ_EQUALS(__) then
    let lhs_str = dumpLhsExp(expLeft)
    let rhs_str = dumpExp(expRight)
    let cmt_str = dumpComment(comment)
    '<%lhs_str%> = <%rhs_str%><%cmt_str%>;'
  case EQ_CONNECT(__) then
    let lhs_str = dumpCref(crefLeft)
    let rhs_str = dumpCref(crefRight)
    let cmt_str = dumpComment(comment)
    'connect(<%lhs_str%>, <%rhs_str%>)<%cmt_str%>;'
  case EQ_FOR(__) then dumpForEEquation(equation)
  case EQ_WHEN(__) then dumpWhenEEquation(equation)
  case EQ_ASSERT(__) then
    let cond_str = dumpExp(condition)
    let msg_str = dumpExp(message)
    let lvl_str = dumpAssertionLevel(level)
    let cmt_str = dumpComment(comment)
    'assert(<%cond_str%>, <%msg_str%><%lvl_str%>)<%cmt_str%>;'
  case EQ_TERMINATE(__) then
    let msg_str = dumpExp(message)
    let cmt_str = dumpComment(comment)
    'terminate(<%msg_str%>)<%cmt_str%>;'
  case EQ_REINIT(__) then
    let cref_str = dumpExp(cref)
    let exp_str = dumpExp(expReinit)
    let cmt_str = dumpComment(comment)
    'reinit(<%cref_str%>, <%exp_str%>)<%cmt_str%>;'
  case EQ_NORETCALL(__) then
    let exp_str = dumpExp(exp)
    let cmt_str = dumpComment(comment)
    '<%exp_str%><%cmt_str%>;'
  else error(sourceInfo(), "SCodeDump.dumpEEquation: Unknown EEquation.")
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
    end;
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
  case EQ_FOR(range=SOME(range)) then
    let range_str = dumpExp(range)
    let eq_str = (eEquationLst |> e => dumpEEquation(e) ;separator="\n")
    let cmt_str = dumpComment(comment)
    <<
    for <%index%> in <%range_str%> loop
      <%eq_str%>
    end for<%cmt_str%>;
    >>
  case EQ_FOR(__) then
    let eq_str = (eEquationLst |> e => dumpEEquation(e) ;separator="\n")
    let cmt_str = dumpComment(comment)
    <<
    for <%index%> loop
      <%eq_str%>
    end for<%cmt_str%>;
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
    let cmt_str = dumpComment(comment)
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
  else ', <%dumpExp(exp)%>'
end dumpAssertionLevel;

template dumpAlgorithmSections(list<SCode.AlgorithmSection> algorithms)
::=
  algorithms |> al => dumpAlgorithmSection(al) ;separator="\n"
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
    let lhs_str = dumpLhsExp(assignComponent)
    let rhs_str = dumpExp(value)
    let cmt_str = dumpComment(comment)
    '<%lhs_str%> = <%rhs_str%><%cmt_str%>;'
  case ALG_IF(__) then dumpIfStatement(statement)
  case ALG_FOR(__) then dumpForStatement(statement)
  case ALG_WHILE(__) then dumpWhileStatement(statement)
  case ALG_WHEN_A(__) then dumpWhenStatement(statement)
  case ALG_ASSERT(__) then
    let cond_str = dumpExp(condition)
    let msg_str = dumpExp(message)
    let lvl_str = dumpAssertionLevel(level)
    'assert(<%cond_str%>, <%msg_str%><%lvl_str%>)'
  case ALG_TERMINATE(__) then
    let msg_str = dumpExp(message)
    'terminate(<%msg_str%>)'
  case ALG_REINIT(__) then
    let cr_str = dumpExp(cref)
    let exp_str = dumpExp(newValue)
    'reinit(<%cr_str%>, <%exp_str%>)'
  case ALG_NORETCALL(__) then
    let exp_str = dumpExp(exp)
    let cmt_str = dumpComment(comment)
    '<%exp_str%><%cmt_str%>'
  case ALG_RETURN(__) then
    let cmt_str = dumpComment(comment)
    'return<%cmt_str%>'
  case ALG_BREAK(__) then
    let cmt_str = dumpComment(comment)
    'break<%cmt_str%>'
  case ALG_FAILURE(stmts={stmt}) then
    let cmt_str = dumpComment(comment)
    'failure(<%dumpStatement(stmt)%>)<%cmt_str%>'
  case SCode.ALG_TRY(__) then dumpTryStatement(statement)
  case ALG_CONTINUE(__) then
    let cmt_str = dumpComment(comment)
    'continue<%cmt_str%>'
  else error(sourceInfo(), "SCodeDump.dumpStatement: Unknown statement.")
end dumpStatement;

template dumpIfStatement(SCode.Statement if_statement)
::=
match if_statement
  case ALG_IF(__) then
    let cond_str = dumpExp(boolExpr)
    let true_branch_str = dumpStatements(trueBranch)
    let else_if_str = dumpElseIfStatements(elseIfBranch)
    let else_branch_str = dumpStatements(elseBranch)
    let cmt_str = dumpComment(comment)
    <<
    if <%cond_str%> then<%cmt_str%>
      <%true_branch_str%>
    <%else_if_str%>
    else
      <%else_branch_str%>
    end;
    >>
end dumpIfStatement;

template dumpElseIfStatements(list<tuple<Absyn.Exp, list<SCode.Statement>>> else_if)
::=
  else_if |> eib as (cond, body) =>
    let cond_str = dumpExp(cond)
    let body_str = dumpStatements(body)
    <<
    elseif <%cond_str%>
      <%body_str%>
    >> ;separator="\n"
end dumpElseIfStatements;

template dumpForStatement(SCode.Statement for_statement)
::=
match for_statement
  case ALG_FOR(range=SOME(e))
    let range_str = dumpExp(e)
    let body_str = dumpStatements(forBody)
    let cmt_str = dumpComment(comment)
    <<
    for <%index%> in <%range_str%>
      <%body_str%>
    end <%cmt_str%>
    >>
  case ALG_FOR(__) then
    let body_str = dumpStatements(forBody)
    let cmt_str = dumpComment(comment)
    <<
    for <%index%>
      <%body_str%>
    end <%cmt_str%>
    >>
end dumpForStatement;

template dumpWhileStatement(SCode.Statement while_statement)
::=
match while_statement
  case ALG_WHILE(__) then
    let cond_str = dumpExp(boolExpr)
    let body_str = dumpStatements(whileBody)
    let cmt_str = dumpComment(comment)
    <<
    while <%cond_str%>
      <%body_str%>
    end
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
    let cmt_str = dumpComment(comment)
    <<
    when <%when_cond_str%> then<%cmt_str%>
      <%when_body_str%>
    <%elsewhen_str%>
    end when;
    >>
end dumpWhenStatement;

template dumpTryStatement(SCode.Statement try_statement)
::=
match try_statement
  case s as ALG_TRY(__) then
    let cmt_str = dumpComment(comment)
    let algs1 = dumpStatements(body)
    let algs2 = dumpStatements(elseBody)
    <<
    try
      <%algs1%>
    catch Exception
      <%algs2%>
    end <%cmt_str%>
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
  case R_PACKAGE(__) then 'module'
  case R_METARECORD(__) then 'struct'
  case R_UNIONTYPE(__) then 'uniontype'
  case R_RECORD(__) then 'record'
  case R_TYPE(__) then '' // Should be const iff in global scope
  case R_FUNCTION(__) then 'function'
  else error(sourceInfo(), 'SCodeDump.dumpRestriction: Unknown restriction <%SCodeDumpTpl.dumpRestriction(restriction)%>')
end dumpRestriction;

template dumpRestrictionTypeVars(SCode.Restriction restriction)
::=
match restriction
  case R_UNIONTYPE(__) then
    (if typeVars then ("{" + (typeVars |> tv => tv ; separator=",") + "}"))
  else ""
end dumpRestrictionTypeVars;

template dumpFunctionRestriction(SCode.FunctionRestriction funcRest)
::=
match funcRest
  case FR_NORMAL_FUNCTION(__) then if isImpure then 'impure function' else 'function'
  case FR_EXTERNAL_FUNCTION(__) then if isImpure then 'impure function' else 'function'

  case FR_OPERATOR_FUNCTION(__) then 'operator function'
  case FR_RECORD_CONSTRUCTOR(__) then 'function'
  else error(sourceInfo(), "SCodeDump.dumpFunctionRestriction: Unknown Function restriction.")
end dumpFunctionRestriction;

template dumpModifier(SCode.Mod modifier)
::=
match modifier
  case MOD(__) then
    let binding_str = dumpModifierBinding(binding)
    let submod_str = if subModLst then
      '(<%(subModLst |> submod => dumpSubModifier(submod) ;separator=", ")%>)'
    '<%submod_str%><%binding_str%>'
end dumpModifier;

template dumpAnnotationModifier(SCode.Mod modifier)
::=
match modifier
  case MOD(__) then
    let binding_str = dumpModifierBinding(binding)
    let text = subModLst |> submod => dumpAnnotationSubModifier(submod) ;separator=", "
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

template dumpRedeclModifier(SCode.Mod modifier)
::=
match modifier
  case REDECL(__) then
    let each_str = dumpEach(eachPrefix)
    dumpElement(element, each_str, packageContext)
end dumpRedeclModifier;

template dumpModifierBinding(Option<Absyn.Exp> binding)
::= match binding case SOME(exp) then '<%\ %>= <%dumpExp(exp)%>'
end dumpModifierBinding;

template dumpSubModifier(SCode.SubMod submod)
::=
match submod
  case NAMEMOD(mod = MOD(__)) then
    '<%dumpModifierPrefix(mod)%><%ident%><%dumpModifier(mod)%>'
  case NAMEMOD(mod = REDECL(__)) then
    '<%dumpRedeclModifier(mod)%>'
end dumpSubModifier;

template dumpAnnotationSubModifier(SCode.SubMod submod)
::=
match submod
  case NAMEMOD(mod = nameMod as MOD(__)) then
    (if Config.showAnnotations() then
      '<%dumpModifierPrefix(mod)%><%ident%><%dumpAnnotationModifier(nameMod)%>'
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
      else '<%dumpModifierPrefix(nameMod)%><%ident%><%dumpAnnotationModifier(nameMod)%>')
  case NAMEMOD(mod = REDECL(__)) then
    '<%dumpRedeclModifier(mod)%>'
end dumpAnnotationSubModifier;

template dumpAttributes(SCode.Attributes attributes, Context context)
::=
match attributes
  case ATTR(variability=CONST(__)) then match '' //Only global constants are allowed in Julia
  case ATTR(__) then dumpDirection(direction, context)
end dumpAttributes;

template dumpDirection(Absyn.Direction direction, Context context)
::=
match direction
  case INPUT(__)
  case INPUT_OUTPUT(__) then error(sourceInfo(), 'input/output')
  // Also output need to be a local, since we need to return them...
  else (match context case FUNCTION(__) then 'local ')
end dumpDirection;

template dumpAttributeDim(SCode.Attributes attributes)
::= match attributes case ATTR(__) then dumpSubscripts(arrayDims)
end dumpAttributeDim;

template dumpAnnotationOpt(Option<SCode.Annotation> annotation)
::= match annotation case SOME(ann) then dumpAnnotation(ann)
end dumpAnnotationOpt;

template dumpAnnotation(SCode.Annotation annotation)
::=
  match annotation
    case ANNOTATION(__) then
     let modifStr = dumpAnnotationModifier(modification)
     if modifStr then '<%\ %>#= annotation<%modifStr%> =#'
end dumpAnnotation;

template dumpAnnotationElement(SCode.Annotation annotation)
::=
  let annstr = '<%dumpAnnotation(annotation)%>'
  if annstr then
    '<%\ %><%annstr%>'
end dumpAnnotationElement;

template dumpExternalDeclOpt(Option<SCode.ExternalDecl> externalDecl)
::= match externalDecl case SOME(extdecl) then dumpExternalDecl(extdecl)
end dumpExternalDeclOpt;

template dumpExternalDecl(SCode.ExternalDecl externalDecl)
::=
let res = match externalDecl
  case EXTERNALDECL(__) then
    let func_name_str = match funcName case SOME(name) then name
    let func_args_str = (args |> arg => dumpExp(arg) ;separator=", ")
    let func_str = if func_name_str then ' <%func_name_str%>(<%func_args_str%>)'
    let lang_str = match lang case SOME(l) then ' "<%l%>"'
    let ann_str = dumpAnnotationOpt(annotation_)
    let output_str = match output_ case SOME(name) then ' <%dumpCref(name)%> ='
    'external<%lang_str%><%output_str%><%func_str%><%ann_str%>;'
match externalDecl
  case EXTERNALDECL(lang=SOME("builtin")) then res
  else res
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
end dumpComment;

template dumpCommentStr(Option<String> comment)
::=
match comment case SOME(cmt) then '<%\ %>#= <%System.escapedString(cmt,false)%> =#'
end dumpCommentStr;

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
  case STRING(__) then ('"<%stringReplace(value,"$","\\$"); absIndent=0%>"')
  case BOOL(__) then value
  case e as BINARY(__) then
    let lhs_str = dumpOperand(exp1, e, true)
    let rhs_str = dumpOperand(exp2, e, false)
    let op_str = dumpOperator(op)
    '<%lhs_str%> <%op_str%> <%rhs_str%>'
  case e as UNARY(__) then
    let exp_str = dumpOperand(exp, e, false)
    let op_str = dumpOperator(op)
    '<%op_str%><%exp_str%>'
  case e as LBINARY(__) then
    let lhs_str = dumpOperand(exp1, e, true)
    let rhs_str = dumpOperand(exp2, e, false)
    let op_str = dumpOperator(op)
    '<%lhs_str%> <%op_str%> <%rhs_str%>'
  case e as LUNARY(__) then
    let exp_str = dumpOperand(exp, e, false)
    let op_str = dumpOperator(op)
    '<%op_str%> <%exp_str%>'
  case e as RELATION(__) then
    let lhs_str = dumpOperand(exp1, e, true)
    let rhs_str = dumpOperand(exp2, e, false)
    let op_str = dumpOperator(op)
    '<%lhs_str%> <%op_str%> <%rhs_str%>'
  case IFEXP(__) then dumpIfExp(exp)
  case CALL(function_=Absyn.CREF_IDENT(name="$array")) then
    let args_str = dumpFunctionArgs(functionArgs)
    'list(<%args_str%>)'
  case CALL(function_=function_ as CREF_IDENT(name=id)) then
    let args_str = dumpFunctionArgs(functionArgs)
    let func_str = (match id
    case "list" then "list"
    else dumpCref(function_))
    '<%func_str%>(<%args_str%>)'
  case CALL(__) then
    let func_str = dumpCref(function_)
    let args_str = dumpFunctionArgs(functionArgs)
    '<%func_str%>(<%args_str%>)'
  case PARTEVALFUNCTION(__) then
    let func_str = dumpCref(function_)
    let args_str = dumpFunctionArgs(functionArgs)
    'function <%func_str%>(<%args_str%>)'
  case ARRAY(__) then
    let array_str = (arrayExp |> e => dumpExp(e) ;separator=", ")
    'list(<%array_str%>)'
  case MATRIX(__) then
    let matrix_str = (matrix |> row =>
        (row |> e => dumpExp(e) ;separator=", ") ;separator="; ")
    '[<%matrix_str%>]'
  case e as RANGE(step = SOME(step)) then
    let start_str = dumpOperand(start, e, false)
    let step_str = dumpOperand(step, e, false)
    let stop_str = dumpOperand(stop, e, false)
    '<%start_str%>:<%step_str%>:<%stop_str%>'
  case e as RANGE(step = NONE()) then
    let start_str = dumpOperand(start, e, false)
    let stop_str = dumpOperand(stop, e, false)
    '<%start_str%>:<%stop_str%>'
  case TUPLE(__) then
    let tuple_str = (expressions |> e => dumpExp(e); separator=", " ;empty)
    '(<%tuple_str%>)'
  case END(__) then 'end'
  case AS(__) then
    let exp_str = dumpExp(exp)
    '<%id%> as <%exp_str%>'
  case CONS(__) then
    let head_str = dumpExp(head)
    let rest_str = dumpExp(rest)
    '<%head_str%> :: <%rest_str%>'
  case MATCHEXP(__) then dumpMatchExp(exp)
  case LIST(__) then
    let list_str = (exps |> e => dumpExp(e) ;separator=", ")
    'list(<%list_str%>)'
  case DOT(__) then
    '<%dumpExp(exp)%>.<%dumpExp(index)%>'
  case _ then '/* AbsynDumpTpl.dumpExp: UNHANDLED Abyn.Exp */'
end dumpExp;

template dumpPattern(Absyn.Exp exp)
::=
match exp
  case INTEGER(__) then value
  case REAL(__) then value
  case CREF(__) then dumpCref(componentRef)
  case STRING(__) then ('"<%stringReplace(value,"$","\\$"); absIndent=0%>"')
  case BOOL(__) then value
  case ARRAY(arrayExp=exps)
  case LIST(__)
  case CALL(function_=Absyn.CREF_IDENT(name="list"), functionArgs=FUNCTIONARGS(args=exps))
  case CALL(function_=Absyn.CREF_IDENT(name="$array"), functionArgs=FUNCTIONARGS(args=exps)) then
    '<%exps |> e => '<%dumpPattern(e)%> => '%> Nil()'
  case CALL(function_=function_ as CREF_IDENT(name=id)) then
    let args_str = dumpFunctionArgsPattern(functionArgs)
    let func_str = (match id
    case "list" then "list"
    else dumpCref(function_))
    '<%func_str%>(<%args_str%>)'
  case CALL(__) then
    let func_str = dumpCref(function_)
    let args_str = dumpFunctionArgsPattern(functionArgs)
    '<%func_str%>(<%args_str%>)'
  case TUPLE(__) then
    let tuple_str = (expressions |> e => dumpPattern(e); separator=", " ;empty)
    '(<%tuple_str%>)'
  case AS(__) then
    let exp_str = dumpPattern(exp)
    '<%id%> as <%exp_str%>'
  case CONS(__) then
    let head_str = dumpPattern(head)
    let rest_str = dumpPattern(rest)
    '<%head_str%> :: <%rest_str%>'
  case _ then '/* AbsynDumpTpl.dumpPattern: UNHANDLED Abyn.Exp <%dumpExp(exp)%> */'
end dumpPattern;

template dumpLhsExp(Absyn.Exp lhs)
::=
match lhs
  case IFEXP(__) then '(<%dumpExp(lhs)%>)'
  else dumpExp(lhs)
end dumpLhsExp;

template dumpOperand(Absyn.Exp operand, Absyn.Exp operation, Boolean lhs)
::=
  let op_str = dumpExp(operand)
  if shouldParenthesize(operand, operation, lhs) then
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
::=
match match_exp
  case MATCHEXP(__) then
    let ty_str = dumpMatchType(matchTy)
    let decls = dumpElements2(SCodeUtil.translateEitemlist(localDecls), false, functionContext)
    let input_str = dumpExp(inputExp)
    let cases_str = (cases |> c => dumpMatchCase(c) ;separator="\n\n")
    let cmt_str = AbsynDumpTpl.dumpStringCommentOption(comment)
    <<
    begin
      <%decls%>
      <%ty_str%> <%input_str%> begin
        <%cases_str%><%cmt_str%>
      end
    end
    >>
end dumpMatchExp;

template dumpMatchType(Absyn.MatchType match_type)
::=
match match_type
  case MATCH() then "@match"
  case MATCHCONTINUE() then "@matchcontinue"
end dumpMatchType;

template dumpMatchEquations(ClassPart cp)
::=
  match cp
  case EQUATIONS(contents={}) then ""
  case EQUATIONS(contents=eql) then
    dumpEquations(SCodeUtil.translateEquations(eql, false))
  case ALGORITHMS(contents={}) then ""
  case ALGORITHMS(contents=algs) then
    dumpStatements(SCodeUtil.translateClassdefAlgorithmitems(algs))
end dumpMatchEquations;

template dumpMatchCase(Absyn.Case c)
::=
match c
  case CASE(__) then
    let pattern_str = dumpPattern(pattern)
    let guard_str = match patternGuard case SOME(g) then 'guard <%dumpExp(g)%> '
    let eql_str = dumpMatchEquations(classPart)
    let result_str = dumpExp(result)
    let cmt_str = AbsynDumpTpl.dumpStringCommentOption(comment)
    <<
    <%pattern_str%> <%guard_str%><%cmt_str%> => (
      <%eql_str%>
      <%result_str%>
      )
    >>
  case ELSE(__) then
    let eql_str = dumpMatchEquations(classPart)
    let result_str = dumpExp(result)
    let cmt_str = AbsynDumpTpl.dumpStringCommentOption(comment)
    <<
    _ <%cmt_str%> => begin (
      <%eql_str%>
      <%result_str%>
      )
    >>
end dumpMatchCase;

template dumpOperator(Absyn.Operator op)
"Just calls the corresponding function in AbsynDumptpl for most things"
::= match op
      case AND(__) then '&&'
      case OR(__) then '||'
      case NOT(__) then '!'
      case NEQUAL(__) then '!='
    else AbsynDumpTpl.dumpOperator(op)
end dumpOperator;

template dumpCref(Absyn.ComponentRef cref)
::=
match cref
  case CREF_QUAL(__) then
    '<%name%><%dumpSubscripts(subscripts)%>.<%dumpCref(componentRef)%>'
  case CREF_IDENT(__)
    then '<%name%><%dumpSubscripts(subscripts)%>'
  case CREF_FULLYQUALIFIED(__) then '.<%dumpCref(componentRef)%>'
  case WILD(__) then if Config.acceptMetaModelicaGrammar() then "_" else ""
  case ALLWILD(__) then '__'
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
    '<%exp_str%> <%match iterType case THREAD(__) then "threaded "%>for <%iter_str%>'
end dumpFunctionArgs;

template dumpFunctionArgsPattern(Absyn.FunctionArgs args)
::=
match args
  case FUNCTIONARGS(__) then
    let args_str = (args |> arg => dumpPattern(arg) ;separator=", ")
    let namedargs_str = (argNames |> narg => dumpNamedArgPattern(narg) ;separator=", ")
    let separator = if args_str then if argNames then ', '
    '<%args_str%><%separator%><%namedargs_str%>'
  else 'ERROR FOR_ITER_FARG in pattern'
end dumpFunctionArgsPattern;

template dumpNamedArg(Absyn.NamedArg narg)
::=
match narg
  case NAMEDARG(__) then
    '<%argName%> = <%dumpExp(argValue)%>'
end dumpNamedArg;

template dumpNamedArgPattern(Absyn.NamedArg narg)
::=
match narg
  case NAMEDARG(__) then
    '<%argName%> = <%dumpPattern(argValue)%>'
end dumpNamedArgPattern;

template dumpForIterators(Absyn.ForIterators iters)
::= (iters |> i => dumpForIterator(i) ;separator=", ")
end dumpForIterators;

template dumpForIterator(Absyn.ForIterator iterator)
::=
match iterator
  case ITERATOR(__) then
    let range_str = match range case SOME(r) then ' in <%dumpExp(r)%>'
    let guard_str = match guardExp case SOME(g) then ' guard <%dumpExp(g)%>'
    '<%name%><%guard_str%><%range_str%>'
end dumpForIterator;

template error(SourceInfo srcInfo, String errMessage)
"Example source template error reporting template to be used together with the sourceInfo() magic function.
Usage: error(sourceInfo(), <<message>>) "
::=
let() = Tpl.addSourceTemplateError(errMessage, srcInfo)
<<

#error "<% Error.infoStr(srcInfo) %> <% errMessage %>"<%\n%>
>>
end error;

template dumpPathJL(Absyn.Path path)
"Wrapper function for dump path. Needed since certain keywords will have a sligthly different meaning in Julia"
::=
match path
  case FULLYQUALIFIED(__) then
    '.<%AbsynDumpTpl.dumpPath(path)%>'
  case QUALIFIED(__) then
    if (Flags.getConfigBool(Flags.MODELICA_OUTPUT)) then
    '<%name%>__<%AbsynDumpTpl.dumpPath(path)%>'
    else
    '<%name%>.<%AbsynDumpTpl.dumpPath(path)%>'
  /*Julia keywords have a slightly different semantic meaning*/
  case IDENT(__) then
    match name
      case "Real" then 'ModelicaReal'
      /* Integers in Modelica are Signed */
      case "Integer" then 'Signed'
      case "Boolean" then 'Bool'
      else '<%name%>'
  else
    AbsynDumpTpl.errorMsg("SCodeDump.dumpPath: Unknown path.")
end dumpPathJL;

template dumpPathJLAF(Absyn.Path path)
"Similar to the first but with AF. Used for return values"
::=
match path
  case FULLYQUALIFIED(__) then
    '.<%AbsynDumpTpl.dumpPath(path)%>'
  case QUALIFIED(__) then
    if (Flags.getConfigBool(Flags.MODELICA_OUTPUT)) then
    '<%name%>__<%AbsynDumpTpl.dumpPath(path)%>'
    else
    '<%name%>.<%AbsynDumpTpl.dumpPath(path)%>'
  /*Julia keywords have a slightly different semantic meaning*/
  case IDENT(__) then
    match name
      case "Real" then 'AbstractFloat'
      /* Integers in Modelica are Signed */
      case "Integer" then 'Signed'
      case "Boolean" then 'Bool'
      else '<%name%>'
  else
    AbsynDumpTpl.errorMsg("SCodeDump.dumpPath: Unknown path.")
end dumpPathJLAF;

template dumpOutputs(list<SCode.Element> elements)
::= elements |> elt as COMPONENT(attributes=ATTR(direction=OUTPUT(__))) =>
      let type_str = '<%dumpTypeSpecAF(elt.typeSpec)%>'
      '<%type_str%>'
      ; separator = ", "
end dumpOutputs;

annotation(__OpenModelica_Interface="backend");
end MMToJulia;
// vim: filetype=susan sw=2 sts=