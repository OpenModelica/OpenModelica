package AbsynDumpTpl

import interface AbsynDumpTV;

template spaceString(String str)
::= if str then ' <%str%>'
end spaceString;

template dump(Absyn.Program program, DumpOptions options)
::=
match program
  case PROGRAM(classes = {}) then ""
  case PROGRAM(__) then
    let within_str = dumpWithin(within_)
    let cls_str = (classes |> cls => dumpClass(cls, options) ;separator=";\n\n")
    '<%within_str%><%cls_str%>;'
end dump;

template dumpClass(Absyn.Class cls, DumpOptions options)
::= dumpClassElement(cls, "", "", "" , "", options)
end dumpClass;

template dumpWithin(Absyn.Within within)
::=
match within
  case TOP(__) then ""
  case WITHIN(__) then
    let path_str = dumpPath(path)
    <<
    within <%path_str%>;

    >>
  else Tpl.addSourceTemplateError("Unknown operation", sourceInfo())
end dumpWithin;

template dumpClassHeader(Absyn.Class cls, String final_str,
    String redecl_str, String repl_str, String io_str)
::=
match cls
  case CLASS(__) then
    let res_str = dumpRestriction(restriction)
    let pref_str = dumpClassPrefixes(cls, final_str, redecl_str, repl_str, io_str)
    '<%pref_str%><%res_str%>'
end dumpClassHeader;

template dumpClassElement(Absyn.Class cls, String final_str,
    String redecl_str, String repl_str, String io_str, DumpOptions options)
::=
match cls
  case CLASS(__) then
    let header_str = dumpClassHeader(cls, final_str, redecl_str, repl_str, io_str)
    let body_str = dumpClassDef(body, name, options)
    '<%header_str%> <%body_str%>'
end dumpClassElement;

template dumpClassDef(Absyn.ClassDef cdef, String cls_name, DumpOptions options)
::=
match cdef
  case PARTS(__) then
    let tvs_str = if typeVars then '<<%(typeVars |> typevar => typevar ;separator=", ")%>>'
    let ann_str = (listReverse(ann) |> a => dumpAnnotation(a) ;separator=";\n")
    let cmt_str = dumpStringCommentOption(comment)
    let body_str = (classParts |> class_part hasindex idx =>
        dumpClassPart(class_part, idx, options) ;separator="")
    <<
    <%cls_name%><%tvs_str%><%cmt_str%><%\n%>
    <%body_str%>
      <%if ann_str then '<%ann_str%>;'%>
    end <%cls_name%>
    >>
  case DERIVED(__) then
    let attr_str = dumpElementAttr(attributes)
    let ty_str = dumpTypeSpec(typeSpec)
    let mod_str = if arguments then
      '(<%(arguments |> arg => dumpElementArg(arg) ;separator=", ")%>)'
    let cmt_str = dumpCommentOpt(comment)
    '<%cls_name%> = <%attr_str%><%ty_str%><%mod_str%><%cmt_str%>'
  case CLASS_EXTENDS(__) then
    let body_str = (parts |> class_part hasindex idx =>
      dumpClassPart(class_part, idx, options) ;separator="\n")
    let mod_str = if modifications then
      '(<%(modifications |> mod => dumpElementArg(mod) ;separator=", ")%>)'
    let cmt_str = dumpStringCommentOption(comment)
    let ann_str = (listReverse(ann) |> a => dumpAnnotation(a) ;separator=";\n")
    <<
    extends <%baseClassName%><%mod_str%><%cmt_str%>
      <%body_str%>
      <%if ann_str then '<%ann_str%>;'%>
    end <%cls_name%>
    >>
  case ENUMERATION(__) then
    let enum_str = dumpEnumDef(enumLiterals)
    let cmt_str = dumpCommentOpt(comment)
    '<%cls_name%> = enumeration(<%enum_str%>)<%cmt_str%>'
  case OVERLOAD(__) then
    let funcs_str = (functionNames |> fn => dumpPath(fn) ;separator=", ")
    let cmt_str = dumpCommentOpt(comment)
    '<%cls_name%> = $overload(<%funcs_str%>)<%cmt_str%>'
  case PDER(__) then
    let fn_str = dumpPath(functionName)
    let vars_str = (vars |> var => var ;separator=", ")
    '<%cls_name%> = der(<%fn_str%>, <%vars_str%>)'
end dumpClassDef;

template dumpEnumDef(Absyn.EnumDef enum_def)
::=
match enum_def
  case ENUMLITERALS(__) then
    (enumLiterals |> lit => dumpEnumLiteral(lit) ;separator=", ")
  case ENUM_COLON() then ":"
end dumpEnumDef;

template dumpEnumLiteral(Absyn.EnumLiteral lit)
::=
match lit
  case ENUMLITERAL(__) then
    let cmt_str = dumpCommentOpt(comment)
    '<%literal%><%cmt_str%>'
end dumpEnumLiteral;

template dumpClassPrefixes(Absyn.Class cls, String final_str,
    String redecl_str, String repl_str, String io_str)
::=
match cls
  case CLASS(__) then
    let enc_str = if encapsulatedPrefix then "encapsulated "
    let partial_str = if partialPrefix then "partial "
    let fin_str = dumpFinal(finalPrefix)
    '<%redecl_str%><%fin_str%><%io_str%><%repl_str%><%enc_str%><%partial_str%>'
end dumpClassPrefixes;

template dumpRestriction(Absyn.Restriction restriction)
::=
match restriction
  case R_CLASS(__) then "class"
  case R_OPTIMIZATION(__) then "optimization"
  case R_MODEL(__) then "model"
  case R_RECORD(__) then "record"
  case R_BLOCK(__) then "block"
  case R_CONNECTOR(__) then "connector"
  case R_EXP_CONNECTOR(__) then "expandable connector"
  case R_TYPE(__) then "type"
  case R_PACKAGE(__) then "package"
  case R_FUNCTION(__) then
    let prefix_str = match functionRestriction
      case FR_NORMAL_FUNCTION(purity = IMPURE()) then "impure "
      case FR_NORMAL_FUNCTION(purity = PURE()) then "pure "
      case FR_NORMAL_FUNCTION(purity = NO_PURITY()) then ""
      case FR_OPERATOR_FUNCTION() then "operator "
      case FR_PARALLEL_FUNCTION() then "parallel "
      case FR_KERNEL_FUNCTION() then "kernel "
    '<%prefix_str%>function'
  case R_OPERATOR(__) then "operator"
  case R_OPERATOR_RECORD(__) then "operator record"
  case R_ENUMERATION(__) then "enumeration"
  case R_PREDEFINED_INTEGER(__) then "Integer"
  case R_PREDEFINED_REAL(__) then "Real"
  case R_PREDEFINED_STRING(__) then "String"
  case R_PREDEFINED_BOOLEAN(__) then "Boolean"
  case R_PREDEFINED_ENUMERATION(__) then "enumeration(:)"
  case R_UNIONTYPE(__) then "uniontype"
  case R_METARECORD(__) then "metarecord"
  case R_UNKNOWN(__) then "*unknown*"
end dumpRestriction;

template dumpClassPart(Absyn.ClassPart class_part, Integer idx, DumpOptions options)
::=
match class_part
  case PUBLIC(__) then
    // Skip printing out "public" if it's the first section.
    let section_str = if idx then "public" else ""
    let el_str = dumpElementItems(contents, "", true, options)
    <<
    <%section_str%>
      <%el_str%>
    >>
  case PROTECTED(__) then
    let el_str = dumpElementItems(contents, "", true, options)
    <<
    protected
      <%el_str%>
    >>
      //<%(contents |> ei => dumpElementItem(ei) ;separator="\n")%>
  case CONSTRAINTS(__) then
    <<
    constraint
      <%(contents |> exp => dumpExp(exp) ;separator="; ")%>
    >>
  case EQUATIONS(__) then
    <<
    equation
      <%(contents |> eq => dumpEquationItem(eq) ;separator="\n")%><%\n%>
    >>
  case INITIALEQUATIONS(__) then
    <<
    initial equation
      <%(contents |> eq => dumpEquationItem(eq) ;separator="\n")%><%\n%>
    >>
  case ALGORITHMS(__) then
    <<
    algorithm
      <%(contents |> eq => dumpAlgorithmItem(eq) ;separator="\n")%><%\n%>
    >>
  case INITIALALGORITHMS(__) then
    <<
    initial algorithm
      <%(contents |> eq => dumpAlgorithmItem(eq) ;separator="\n")%><%\n%>
    >>
  case EXTERNAL(__) then
    let ann_str = match annotation_ case SOME(ann) then ' <%dumpAnnotation(ann)%>;'
    match externalDecl
      case EXTERNALDECL(__) then
        let fn_str = match funcName case SOME(fn) then fn
        let lang_str = match lang case SOME(l) then '"<%l%>" '
        let output_str = match output_ case SOME(o) then '<%dumpCref(o)%> = '
        let args_str = if args then '(<%(args |> arg => dumpExp(arg) ;separator=", ")%>)' else (if fn_str then "()")
        let ann2_str = dumpAnnotationOpt(annotation_)
        <<

          external <%lang_str%><%output_str%><%fn_str%><%args_str%><%spaceString(ann2_str)%>;<%ann_str%>
        >>
end dumpClassPart;

template dumpElementItems(list<Absyn.ElementItem> items, String prevSpacing, Boolean first, DumpOptions options)
::=
match items
  case item :: rest_items then
    let spacing = dumpElementItemSpacing(item)
    let pre_spacing = if not first then
      dumpElementItemPreSpacing(spacing, prevSpacing)
    let item_str = dumpElementItem(item, options)
    let rest_str = dumpElementItems(rest_items, spacing, false, options)
    let post_spacing = if rest_str then spacing
    <<
    <%pre_spacing%>
    <%item_str%><%post_spacing%><%\n%>
    <%if rest_str then rest_str%>
    >>
end dumpElementItems;

template dumpElementItemPreSpacing(String curSpacing, String prevSpacing)
::= if not prevSpacing then curSpacing
end dumpElementItemPreSpacing;

template dumpElementItemSpacing(Absyn.ElementItem item)
::=
match item
  case ELEMENTITEM(element = ELEMENT(specification = CLASSDEF(class_ = CLASS(body = cdef))))
    then dumpClassDefSpacing(cdef)
end dumpElementItemSpacing;

template dumpClassDefSpacing(Absyn.ClassDef cdef)
::=
match cdef
  case PARTS(__) then '<%\n%>'
  case CLASS_EXTENDS(__) then '<%\n%>'
end dumpClassDefSpacing;

template dumpElementItem(Absyn.ElementItem eitem, DumpOptions options)
::=
match eitem
  case ELEMENTITEM(__) then dumpElement(element, options)
  case LEXER_COMMENT(__) then System.trimWhitespace(comment)
end dumpElementItem;

template dumpElement(Absyn.Element elem, DumpOptions options)
::=
match elem
  case ELEMENT(__) then
    if boolOr(boolUnparseFileFromInfo(info, options), boolNot(isClassdef(elem))) then
    let final_str = dumpFinal(finalPrefix)
    let redecl_str = match redeclareKeywords case SOME(re) then dumpRedeclare(re)
    let repl_str = match redeclareKeywords case SOME(re) then dumpReplaceable(re)
    let io_str = dumpInnerOuter(innerOuter)
    let ec_str = dumpElementSpec(specification, final_str, redecl_str, repl_str, io_str, options)
    let cc_str = match constrainClass case SOME(cc) then dumpConstrainClass(cc)
    '<%ec_str%><%cc_str%>;'
  case DEFINEUNIT(__) then
    let args_str = if args then '(<%(args |> arg => dumpNamedArg(arg))%>)'
    'defineunit <%name%><%args_str%>;'
  case TEXT(__) then
    if boolUnparseFileFromInfo(info, options) then
    let name_str = match optName case SOME(name) then name
    let info_str = dumpInfo(info)
    '/* Absyn.TEXT(SOME("<%name_str%>"), "<%string%>", "<%info_str%>"); */'
end dumpElement;

template dumpInfo(builtin.SourceInfo info)
::=
match info
  case SOURCEINFO(__) then
    let rm_str = if isReadOnly then "readonly" else "writable"
    'SOURCEINFO("<%fileName%>", <%rm_str%>, <%lineNumberStart%>, <%columnNumberStart%>, <%lineNumberEnd%>, <%columnNumberEnd%>)\n'
end dumpInfo;

template dumpAnnotation(Absyn.Annotation ann)
::=
match ann
  case ANNOTATION(__) then
    let args = (elementArgs |> earg => dumpElementArg(earg) ;separator=", ")
    'annotation(<%args ;absIndent%>)'
end dumpAnnotation;

template dumpAnnotationOpt(Option<Absyn.Annotation> oann)
::= match oann case SOME(ann) then dumpAnnotation(ann)
end dumpAnnotationOpt;

template dumpComment(Absyn.Comment cmt)
::=
match cmt
  case COMMENT(__) then
    let ann_str = dumpAnnotationOpt(annotation_)
    let cmt_str = dumpStringCommentOption(comment)
    '<%cmt_str%><%spaceString(ann_str)%>'
end dumpComment;

template dumpCommentOpt(Option<Absyn.Comment> ocmt)
::= match ocmt case SOME(cmt) then dumpComment(cmt)
end dumpCommentOpt;

template dumpElementArg(Absyn.ElementArg earg)
::=
match earg
  case MODIFICATION(__) then
    let each_str = dumpEach(eachPrefix)
    let final_str = dumpFinal(finalPrefix)
    let path_str = dumpPath(path)
    let mod_str = match modification case SOME(mod) then dumpModification(mod)
    let cmt_str = dumpStringCommentOption(comment)
    '<%each_str%><%final_str%><%path_str%><%mod_str%><%cmt_str%>'
  case REDECLARATION(__) then
    let each_str = dumpEach(eachPrefix)
    let final_str = dumpFinal(finalPrefix)
    let redecl_str = dumpRedeclare(redeclareKeywords)
    let repl_str = dumpReplaceable(redeclareKeywords)
    let eredecl_str = '<%redecl_str%><%each_str%>'
    let elem_str = dumpElementSpec(elementSpec, final_str, eredecl_str, repl_str, "", defaultDumpOptions)
    let cc_str = match constrainClass case SOME(cc) then dumpConstrainClass(cc)
    '<%elem_str%><%cc_str%>'
end dumpElementArg;

template dumpEach(Absyn.Each each)
::= match each case EACH() then "each "
end dumpEach;

template dumpFinal(Boolean final)
::= if final then "final "
end dumpFinal;

template dumpRedeclare(Absyn.RedeclareKeywords redecl)
::=
match redecl
  case REDECLARE() then "redeclare "
  case REDECLARE_REPLACEABLE() then "redeclare "
end dumpRedeclare;

template dumpReplaceable(Absyn.RedeclareKeywords repl)
::=
match repl
  case REPLACEABLE() then "replaceable "
  case REDECLARE_REPLACEABLE() then "replaceable "
end dumpReplaceable;

template dumpInnerOuter(Absyn.InnerOuter io)
::=
match io
  case INNER() then "inner "
  case OUTER() then "outer "
  case INNER_OUTER() then "inner outer "
end dumpInnerOuter;

template dumpModification(Absyn.Modification mod)
::=
match mod
  case CLASSMOD(__) then
    let arg_str = if elementArgLst then
      '(<%(elementArgLst |> earg => dumpElementArg(earg) ;separator=", ")%>)'
    let eq_str = dumpEqMod(eqMod)
    '<%arg_str%><%eq_str%>'
end dumpModification;

template dumpEqMod(Absyn.EqMod eqmod)
::= match eqmod case EQMOD(__) then '<%\ %>= <%dumpExp(exp)%>'
end dumpEqMod;

template dumpElementSpec(Absyn.ElementSpec elem, String final, String redecl,
    String repl, String io, DumpOptions options)
::=
match elem
  case CLASSDEF(__) then dumpClassElement(class_, final, redecl, repl, io, options)
  case EXTENDS(__) then
    let bc_str = dumpPath(path)
    let args_str = (elementArg |> earg => dumpElementArg(earg) ;separator=", ")
    let mod_str = if args_str then '(<%args_str%>)'
    let ann_str = dumpAnnotationOpt(annotationOpt)
    'extends <%bc_str%><%mod_str%><%spaceString(ann_str)%>'
  case COMPONENTS(__) then
    let ty_str = dumpTypeSpec(typeSpec)
    let attr_str = dumpElementAttr(attributes)
    let dim_str = dumpElementAttrDim(attributes)
    let comps_str = (components |> comp => dumpComponentItem(comp) ;separator=", ")
    let prefix_str = '<%redecl%><%final%><%io%><%repl%>'
    '<%prefix_str%><%attr_str%><%ty_str%><%dim_str%> <%comps_str%>'
  case IMPORT(__) then
    let imp_str = dumpImport(import_)
    'import <%imp_str%>'
end dumpElementSpec;

template dumpElementAttr(Absyn.ElementAttributes attr)
::=
match attr
  case ATTR(__) then
    let flow_str = if flowPrefix then "flow "
    let stream_str = if streamPrefix then "stream "
    let par_str = dumpParallelism(parallelism)
    let var_str = dumpVariability(variability)
    let dir_str = dumpDirection(direction)
    '<%flow_str%><%stream_str%><%par_str%><%var_str%><%dir_str%>'
end dumpElementAttr;

template dumpParallelism(Absyn.Parallelism par)
::=
match par
  case PARGLOBAL() then "parglobal "
  case PARLOCAL() then "parlocal "
  case NON_PARALLEL() then ""
end dumpParallelism;

template dumpVariability(Absyn.Variability var)
::=
match var
  case VAR() then ""
  case DISCRETE() then "discrete "
  case PARAM() then "parameter "
  case CONST() then "constant "
end dumpVariability;

template dumpDirection(Absyn.Direction dir)
::=
match dir
  case BIDIR() then ""
  case INPUT() then "input "
  case OUTPUT() then "output "
end dumpDirection;

template dumpElementAttrDim(Absyn.ElementAttributes attr)
::= match attr case ATTR(__) then dumpSubscripts(arrayDim)
end dumpElementAttrDim;

template dumpConstrainClass(Absyn.ConstrainClass cc)
::=
match cc
  case CONSTRAINCLASS(elementSpec = Absyn.EXTENDS(path = p, elementArg = el)) then
    let path_str = dumpPath(p)
    let el_str = if el then '(<%(el |> e => dumpElementArg(e) ;separator=", ")%>)'
    let cmt_str = dumpCommentOpt(comment)
    ' constrainedby <%path_str%><%el_str%><%cmt_str%>'
end dumpConstrainClass;

template dumpComponentItem(Absyn.ComponentItem comp)
::=
match comp
  case COMPONENTITEM(__) then
    let comp_str = dumpComponent(component)
    let cond_str = dumpComponentCondition(condition)
    let cmt = dumpCommentOpt(comment)
    '<%comp_str%><%cond_str%><%cmt%>'
end dumpComponentItem;

template dumpComponent(Absyn.Component comp)
::=
match comp
  case COMPONENT(__) then
    let dim_str = dumpSubscripts(arrayDim)
    let mod_str = match modification case SOME(mod) then dumpModification(mod)
    '<%name%><%dim_str%><%mod_str%>'
end dumpComponent;

template dumpComponentCondition(Option<Absyn.ComponentCondition> cond)
::=
match cond
  case SOME(cexp) then
    let exp_str = dumpExp(cexp)
    ' if <%exp_str%>'
end dumpComponentCondition;

template dumpImport(Absyn.Import imp)
::=
match imp
  case NAMED_IMPORT(__) then '<%name%> = <%dumpPath(path)%>'
  case QUAL_IMPORT(__) then dumpPath(path)
  case UNQUAL_IMPORT(__) then '<%dumpPath(path)%>.*'
  case GROUP_IMPORT(__) then
    let prefix_str = dumpPath(prefix)
    let groups_str = (groups |> group => dumpGroupImport(group) ;separator=",")
    '<%prefix_str%>.{<%groups_str%>}'
end dumpImport;

template dumpGroupImport(Absyn.GroupImport gimp)
::=
match gimp
  case GROUP_IMPORT_NAME(__) then name
  case GROUP_IMPORT_RENAME(__) then '<%rename%> = <%name%>'
end dumpGroupImport;

template dumpEquationItem(Absyn.EquationItem eq)
::=
match eq
  case EQUATIONITEM(__) then
    let eq_str = dumpEquation(equation_)
    let cmt_str = dumpCommentOpt(comment)
    '<%eq_str%><%cmt_str%>;'
  case EQUATIONITEMCOMMENT(__) then (System.trimWhitespace(comment) ; absIndent=0)
end dumpEquationItem;

template dumpEquationItems(list<Absyn.EquationItem> eql)
::= (eql |> eq => dumpEquationItem(eq) ;separator="\n")
end dumpEquationItems;

template dumpEquation(Absyn.Equation eq)
::=
match eq
  case EQ_IF(__) then
    let if_str = dumpEquationBranch(ifExp, equationTrueItems, "if")
    let elseif_str = (elseIfBranches |> (c, b) =>
        dumpEquationBranch(c, b, "elseif") ;separator="\n")
    let else_branch_str = dumpEquationItems(equationElseItems)
    let else_str = if else_branch_str then
      <<
      else
        <%else_branch_str%>
      >>
    <<
    <%if_str%>
    <%elseif_str%>
    <%else_str%>
    end if
    >>
  case EQ_EQUALS(__) then
    let lhs = dumpLhsExp(leftSide)
    let rhs = dumpExp(rightSide)
    '<%lhs%> = <%rhs%>'
  case EQ_CONNECT(__) then
    let c1_str = dumpCref(connector1)
    let c2_str = dumpCref(connector2)
    'connect(<%c1_str%>, <%c2_str%>)'
  case EQ_FOR(__) then
    let iter_str = dumpForIterators(iterators)
    let body_str = dumpEquationItems(forEquations)
    <<
    for <%iter_str%> loop
      <%body_str%>
    end for
    >>
  case EQ_WHEN_E(__) then
    let when_str = dumpEquationBranch(whenExp, whenEquations, "when")
    let elsewhen_str = (elseWhenEquations |> (c, b) =>
        dumpEquationBranch(c, b, "elsewhen") ;separator="\n")
    <<
    <%when_str%>
    <%elsewhen_str%>
    end when
    >>
  case EQ_NORETCALL(__) then
    let name_str = dumpCref(functionName)
    let args_str = dumpFunctionArgs(functionArgs)
    '<%name_str%>(<%args_str%>)'
  case EQ_FAILURE(__) then
    let eq_str = dumpEquationItem(equ)
    'failure(<%eq_str%>)'
end dumpEquation;

template dumpEquationBranch(Absyn.Exp cond, list<Absyn.EquationItem> body, String header)
::=
  let cond_str = dumpExp(cond)
  let body_str = (body |> eq => dumpEquationItem(eq) ;separator="\n")
  <<
  <%header%> <%cond_str%> then
    <%body_str%>
  >>
end dumpEquationBranch;

template dumpAlgorithmItems(list<Absyn.AlgorithmItem> algs)
::= (algs |> alg => dumpAlgorithmItem(alg) ;separator="\n")
end dumpAlgorithmItems;

template dumpAlgorithmItem(Absyn.AlgorithmItem alg)
::=
match alg
  case ALGORITHMITEM(__) then
    let alg_str = dumpAlgorithm(algorithm_)
    let cmt_str = dumpCommentOpt(comment)
    '<%alg_str%><%cmt_str%>;'
  case ALGORITHMITEMCOMMENT(__) then (System.trimWhitespace(comment) ; absIndent=0)
end dumpAlgorithmItem;

template dumpAlgorithm(Absyn.Algorithm alg)
::=
match alg
  case ALG_ASSIGN(__) then
    let lhs_str = dumpLhsExp(assignComponent)
    let rhs_str = dumpExp(value)
    '<%lhs_str%> := <%rhs_str%>'
  case ALG_IF(__) then
    let if_str = dumpAlgorithmBranch(ifExp, trueBranch, "if", "then")
    let elseif_str = (elseIfAlgorithmBranch |> (c, b) =>
        dumpAlgorithmBranch(c, b, "elseif", "then") ;separator="\n")
    let else_branch_str = dumpAlgorithmItems(elseBranch)
    let else_str = if else_branch_str then
      <<
      else
        <%else_branch_str%>
      >>
    <<
    <%if_str%>
    <%elseif_str%>
    <%else_str%>
    end if
    >>
  case ALG_FOR(__) then
    let iter_str = dumpForIterators(iterators)
    let body_str = dumpAlgorithmItems(forBody)
    <<
    for <%iter_str%> loop
      <%body_str%>
    end for
    >>
  case ALG_PARFOR(__) then
    let iter_str = dumpForIterators(iterators)
    let body_str = dumpAlgorithmItems(parforBody)
    <<
    parfor <%iter_str%> loop
      <%body_str%>
    end parfor
    >>
  case ALG_WHILE(__) then
    let while_str = dumpAlgorithmBranch(boolExpr, whileBody, "while", "loop")
    <<
    <%while_str%>
    end while
    >>
  case ALG_WHEN_A(__) then
    let when_str = dumpAlgorithmBranch(boolExpr, whenBody, "when", "then")
    let elsewhen_str = (elseWhenAlgorithmBranch |> (c, b) =>
        dumpAlgorithmBranch(c, b, "elsewhen", "then") ;separator="\n")
    <<
    <%when_str%>
    <%elsewhen_str%>
    end when
    >>
  case ALG_NORETCALL(__) then
    let name_str = dumpCref(functionCall)
    let args_str = dumpFunctionArgs(functionArgs)
    '<%name_str%>(<%args_str%>)'
  case ALG_RETURN(__) then "return"
  case ALG_BREAK(__) then "break"
  case ALG_FAILURE(__) then
    let arg_str = if equ then dumpAlgorithmItems(equ) else "..."
    'failure(<%arg_str%>)'
  case ALG_TRY(__) then
    let arg1 = dumpAlgorithmItems(body)
    let arg2 = dumpAlgorithmItems(elseBody)
    <<
    try
      <%arg1%>
    else
      <%arg2%>
    end try;
    >>
  case ALG_CONTINUE(__) then "continue"
end dumpAlgorithm;

template dumpAlgorithmBranch(Absyn.Exp cond, list<Absyn.AlgorithmItem> body,
String header, String exec_str)
::=
  let cond_str = dumpExp(cond)
  let body_str = (body |> eq => dumpAlgorithmItem(eq) ;separator="\n")
  <<
  <%header%> <%cond_str%> <%exec_str%>
    <%body_str%>
  >>
end dumpAlgorithmBranch;

template dumpPath(Absyn.Path path)
::=
match path
  case FULLYQUALIFIED(__) then
    '.<%dumpPath(path)%>'
  case QUALIFIED(__) then
    if (Flags.getConfigBool(Flags.MODELICA_OUTPUT)) then
    '<%name%>__<%dumpPath(path)%>'
    else
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

template dumpStringCommentOption(Option<String> cmt)
::= match cmt case SOME(str) then '<%\ %>"<%str%>"'
end dumpStringCommentOption;

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
  case STRING(__) then ('"<%value ; absIndent=0%>"')
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
    '{<%args_str%>}'
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
    '{<%array_str%>}'
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
  case CODE(__) then '$Code(<%dumpCodeNode(code)%>)'
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
    '{<%list_str%>}'
  case DOT(__) then
    '<%dumpExp(exp)%>.<%dumpExp(index)%>'
  case _ then '/* AbsynDumpTpl.dumpExp: UNHANDLED Abyn.Exp */'
end dumpExp;

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

template dumpCodeNode(Absyn.CodeNode code)
::=
match code
  case C_TYPENAME(__) then dumpPath(path)
  case C_VARIABLENAME(__) then dumpCref(componentRef)
  case C_CONSTRAINTSECTION(__) then
    let initial_str = if boolean then "initial " else ""
    let eql_str = dumpEquationItems(equationItemLst)
    <<
    <%initial_str%>constraint
      <%eql_str%>
    >>
  case C_EQUATIONSECTION(__) then
    let initial_str = if boolean then "initial " else ""
    let eql_str = dumpEquationItems(equationItemLst)
    <<
    <%initial_str%>equation
      <%eql_str%>
    >>
  case C_ALGORITHMSECTION(__) then
    let initial_str = if boolean then "initial " else ""
    let algs_str = dumpAlgorithmItems(algorithmItemLst)
    <<
    <%initial_str%>algorithm
      <%algs_str%>
    >>
  case C_ELEMENT(__) then dumpElement(element, Dump.defaultDumpOptions)
  case C_EXPRESSION(__) then dumpExp(exp)
  case C_MODIFICATION(__) then dumpModification(modification)
end dumpCodeNode;

template dumpMatchExp(Absyn.Exp match_exp)
::=
match match_exp
  case MATCHEXP(__) then
    let ty_str = dumpMatchType(matchTy)
    let input_str = dumpExp(inputExp)
    let locals_str = dumpMatchLocals(localDecls)
    let cases_str = (cases |> c => dumpMatchCase(c) ;separator="\n\n")
    let cmt_str = dumpStringCommentOption(comment)
    <<
    <%ty_str%> <%input_str%>
    <%locals_str%>
      <%cases_str%><%cmt_str%>
    end <%ty_str%>
    >>
end dumpMatchExp;

template dumpMatchType(Absyn.MatchType match_type)
::=
match match_type
  case MATCH() then "match"
  case MATCHCONTINUE() then "matchcontinue"
end dumpMatchType;

template dumpMatchLocals(list<ElementItem> locals)
::= if locals then
  <<
    local
      <%(locals |> decl => dumpElementItem(decl, defaultDumpOptions) ;separator="\n")%>

  >>
end dumpMatchLocals;

template dumpMatchEquations(ClassPart cp)
::=
  match cp
  case EQUATIONS(contents={}) then ""
  case EQUATIONS(contents=eql) then
  <<

    equation
      <%(eql |> eq => dumpEquationItem(eq) ;separator="\n")%>
  >>
  case ALGORITHMS(contents={}) then ""
  case ALGORITHMS(contents=algs) then
  <<

    algorithm
      <%(algs |> alg => dumpAlgorithmItem(alg) ;separator="\n")%>
  >>
end dumpMatchEquations;

template dumpMatchCase(Absyn.Case c)
::=
match c
  case CASE(__) then
    let pattern_str = dumpExp(pattern)
    let guard_str = match patternGuard case SOME(g) then 'guard <%dumpExp(g)%> '
    let eql_str = dumpMatchEquations(classPart)
    let result_str = dumpExp(result)
    let then_str = if eql_str then
      <<

        then
          <%result_str%>
      >>
      else 'then <%result_str%>'
    let cmt_str = dumpStringCommentOption(comment)
    <<
    case <%pattern_str%> <%guard_str%><%cmt_str%><%eql_str%><%then_str%>;
    >>
  case ELSE(__) then
    let eql_str = dumpMatchEquations(classPart)
    let result_str = dumpExp(result)
    let then_str = if eql_str then
      <<

        then
          <%result_str%>
      >>
      else 'then <%result_str%>'
    let cmt_str = dumpStringCommentOption(comment)
    <<
    else <%cmt_str%><%eql_str%><%then_str%>;
    >>
end dumpMatchCase;

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

template dumpNamedArg(Absyn.NamedArg narg)
::=
match narg
  case NAMEDARG(__) then
    '<%argName%> = <%dumpExp(argValue)%>'
end dumpNamedArg;

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

template errorMsg(String errMessage)
::=
let() = Tpl.addTemplateError(errMessage)
<<
<%errMessage%>
>>
end errorMsg;

annotation(__OpenModelica_Interface="frontend");
end AbsynDumpTpl;
