package AbsynJLDumpTpl
"
  This program dumps the AST into a Julia representation
"
import interface AbsynDumpTV;

template dump(Absyn.Program program)
::= dump2(program, defaultDumpOptions)
end dump;

template dump2(Absyn.Program program, DumpOptions options)
::=
match program
  case PROGRAM(classes = {}) then <<PROGRAM(list(), <%dumpWithin(within_)%>)>>
  case PROGRAM(__) then
    let within_str = dumpWithin(within_)
    let cls_str = (classes |> cls => dumpClass(cls, options) ;separator=", <%\n%>")
    <<PROGRAM(list(<%cls_str%>), <%within_str%>)>>
end dump2;

template dumpClass(Absyn.Class cls, DumpOptions options)
::= match cls
    case CLASS(__) then
      let n = name
      let pp = dumpFinal(partialPrefix)
      let fp = dumpFinal(finalPrefix)
      let ep = dumpFinal(encapsulatedPrefix)
      let r = dumpRestriction(restriction)
      let cd = dumpClassDef(body, options)
      let i = dumpInfo(info)
      'CLASS("<%n%>", <%pp%>, <%fp%> ,<%ep%>, <%r%>, <%cd%>, <%i%>)'
end dumpClass;

template dumpClassDef(Absyn.ClassDef cdef, DumpOptions options)
::=
match cdef
  case PARTS(__) then
    let tvs_str = (typeVars |> typevar => typevar ;separator=", ")
    let ann_str = (listReverse(ann) |> a => dumpAnnotation(a) ;separator=", ")
    let cmt_str = dumpStringCommentOption(comment)
    let body_str = (classParts |> class_part hasindex idx =>
        dumpClassPart(class_part, options) ;separator=", ")
    let attr_str = (classAttrs |> e => dumpNamedArg(e) ;separator=", ")
    'PARTS(list(<%tvs_str%>), list(<%attr_str%>), list(<%body_str%>), list(<%ann_str%>), <%cmt_str%>)'
  case DERIVED(__) then
    let attr_str = dumpElementAttr(attributes)
    let ty_str = dumpTypeSpec(typeSpec)
    let arg_str = '(<%(arguments |> arg => dumpElementArg(arg) ;separator=", ")%>)'
    let cmt_str = dumpCommentOpt(comment)
    'DERIVED(<%ty_str%>, <%attr_str%>, list(<%arg_str%>), <%cmt_str%>)'
  case CLASS_EXTENDS(__) then
    let body_str = (parts |> class_part hasindex idx =>
      dumpClassPart(class_part, options) ;separator=", ")
    let mod_str = if modifications then
      '(<%(modifications |> mod => dumpElementArg(mod) ;separator=", ")%>)'
    let cmt_str = dumpStringCommentOption(comment)
    let ann_str = (listReverse(ann) |> a => dumpAnnotation(a) ;separator=", ")
    'CLASS_EXTENDS(<%baseClassName%>, list(<%mod_str%>), <%cmt_str%>, list(<%body_str%>), list(<%ann_str%>))'
  case ENUMERATION(__) then
    let enum_str = dumpEnumDef(enumLiterals)
    let cmt_str = dumpCommentOpt(comment)
    'ENUMERATION(<%enum_str%>, <%cmt_str%>)'
  case OVERLOAD(__) then
    let funcs_str = (functionNames |> fn => dumpPath(fn) ;separator=", ")
    let cmt_str = dumpCommentOpt(comment)
    'OVERLOAD(list(<%funcs_str%>), <%cmt_str%>)'
  case PDER(__) then "NOT SUPPORTED???"
end dumpClassDef;

template dumpEnumDef(Absyn.EnumDef enum_def)
::=
match enum_def
  case ENUMLITERALS(__) then
    let els = (enumLiterals |> lit => dumpEnumLiteral(lit) ;separator=", ")
    'ENUMLITERALS(list(<%els%>))'
  case ENUM_COLON() then 'ENUM_COLON()'
end dumpEnumDef;

template dumpEnumLiteral(Absyn.EnumLiteral lit)
::=
match lit
  case ENUMLITERAL(__) then
    let cmt_str = dumpCommentOpt(comment)
    'ENUMLITERAL(<%literal%>, <%cmt_str%>)'
end dumpEnumLiteral;


template dumpRestriction(Absyn.Restriction restriction)
::=
match restriction
  case R_CLASS(__) then 'R_CLASS()'
  case R_OPTIMIZATION(__) then 'R_OPTIMIZATION()'
  case R_MODEL(__) then 'R_MODEL()'
  case R_RECORD(__) then 'R_RECORD()'
  case R_BLOCK(__) then 'R_BLOCK()'
  case R_CONNECTOR(__) then 'R_CONNECTOR()'
  case R_EXP_CONNECTOR(__) then 'R_EXP_CONNECTOR()'
  case R_TYPE(__) then 'R_TYPE()'
  case R_PACKAGE(__) then 'R_PACKAGE()'
  case R_FUNCTION(__) then
    let prefix_str = match functionRestriction
      case FR_NORMAL_FUNCTION(purity = IMPURE()) then 'FR_NORMAL_FUNCTION(IMPURE())'
      case FR_NORMAL_FUNCTION(purity = PURE()) then 'FR_NORMAL_FUNCTION(PURE())'
      case FR_NORMAL_FUNCTION(purity = NO_PURITY()) then 'FR_NORMAL_FUNCTION(NO_PURITY())'
      case FR_OPERATOR_FUNCTION() then 'FR_OPERATOR_FUNCTION()'
      case FR_PARALLEL_FUNCTION() then 'FR_PARALLEL_FUNCTION()'
      case FR_KERNEL_FUNCTION() then 'FR_KERNEL_FUNCTION()'
    'R_FUNCTION(<%prefix_str%>)'
  case R_OPERATOR(__) then 'R_OPERATOR()'
  case R_OPERATOR_RECORD(__) then 'R_OPERATOR_RECORD()'
  case R_ENUMERATION(__) then 'R_ENUMERATION()'
  case R_PREDEFINED_INTEGER(__) then 'R_PREDEFINED_INTEGER()'
  case R_PREDEFINED_REAL(__) then 'R_PREDEFINED_REAL()'
  case R_PREDEFINED_STRING(__) then 'R_PREDEFINED_STRING()'
  case R_PREDEFINED_BOOLEAN(__) then 'R_PREDEFINED_BOOLEAN()'
  case R_PREDEFINED_ENUMERATION(__) then 'R_PREDEFINED_ENUMERATION()'
  case R_UNIONTYPE(__) then 'R_UNIONTYPE()'
  case R_METARECORD(__) then "MR: Does not work"
  case R_UNKNOWN(__) then 'R_UNKNOWN()'
end dumpRestriction;


template dumpClassPart(Absyn.ClassPart class_part, DumpOptions options)
::=
match class_part
  case PUBLIC(__) then
    let el_str = (contents |> c => dumpElementItem(c, options);separator=", ")
    'PUBLIC(list(<%el_str%>))'
  case PROTECTED(__) then
    let el_str = (contents |> c => dumpElementItem(c, options);separator=", ")
    'PROTECTED(list(<%el_str%>))'
  case CONSTRAINTS(__) then
    let el_str = (contents |> exp => dumpExp(exp) ;separator=", ")
    'CONSTRAINTS(<%el_str%>)'
  case EQUATIONS(__) then
      let el_str = (contents |> eq => dumpEquationItem(eq) ;separator=", ")
      'EQUATIONS(list(<%el_str%>))'
  case INITIALEQUATIONS(__) then
      let el_str = (contents |> eq => dumpEquationItem(eq) ;separator=", ")
      'INITIALEQUATIONS(list(<%el_str%>))'
  case ALGORITHMS(__) then
      let el_str = (contents |> eq => dumpAlgorithmItem(eq) ;separator=", ")
      'ALGORITHMS(list(<%el_str%>))'
  case INITIALALGORITHMS(__) then
      let el_str = (contents |> eq => dumpAlgorithmItem(eq) ;separator=", ")
      'INITIALALGORITHMS(list(<%el_str%>))'
  case EXTERNAL(__) then
    let ann_str = match annotation_ case SOME(ann) then 'SOME(<%dumpAnnotation(ann)%>)' else 'NONE()'
    match externalDecl
      case EXTERNALDECL(__) then
        let fn_str = match funcName case SOME(fn) then 'SOME(<%fn%>)' else 'NONE()'
        let lang_str = match lang case SOME(l) then 'SOME(1)' else 'NONE()'
        let output_str = match output_ case SOME(o) then 'SOME(<%dumpCref(o)%>)' else 'NONE()'
        let args_str = (args |> arg => dumpExp(arg) ;separator=", ")
        let ann2_str = dumpAnnotationOptSpace(annotation_)
       'EXTERNAL(EXTERNALDECL(<%fn_str%>, <%lang_str%>, <%output_str%>, list(<%args_str%>), <%ann2_str%>), <%ann_str%>)'
end dumpClassPart;

template dumpWithin(Absyn.Within within)
::=
match within
  case TOP(__) then 'TOP()'
  case WITHIN(__) then 'WITHIN(<%dumpPath(path)%>)'
end dumpWithin;

template dumpInfo(builtin.SourceInfo info)
::=
match info
  case SOURCEINFO(__) then
    let rm_str = if isReadOnly then "true" else "false"
    'SOURCEINFO("<%fileName%>", <%rm_str%>, <%lineNumberStart%>, <%columnNumberStart%>, <%lineNumberEnd%>, <%columnNumberEnd%>)'
end dumpInfo;

template dumpAnnotation(Absyn.Annotation ann)
::=
match ann
  case ANNOTATION(elementArgs={}) then "ANNOTATION(list())"
  case ANNOTATION(__) then 'ANNOTATION(list(<%(elementArgs |> earg => dumpElementArg(earg) ;separator=', ')%>))'
end dumpAnnotation;

template dumpAnnotationOpt(Option<Absyn.Annotation> oann)
::= match oann case SOME(ann) then 'SOME(<%dumpAnnotation(ann)%>)' else 'NONE()'
end dumpAnnotationOpt;

template dumpAnnotationOptSpace(Option<Absyn.Annotation> oann)
::= match oann case SOME(ann) then 'SOME(dumpAnnotation(ann))' else 'NONE()'
end dumpAnnotationOptSpace;

template dumpComment(Absyn.Comment cmt)
::=
match cmt
  case COMMENT(__) then 'COMMENT(<%dumpStringCommentOption(comment)%>, <%dumpAnnotationOptSpace(annotation_)%>)'
end dumpComment;

template dumpCommentOpt(Option<Absyn.Comment> ocmt)
::= match ocmt case SOME(cmt) then 'SOME(<%dumpComment(cmt)%>)' else 'NONE()'
end dumpCommentOpt;

template dumpElementArg(Absyn.ElementArg earg)
::=
match earg
  case MODIFICATION(__) then
    let each_str = dumpEach(eachPrefix)
    let final_str = dumpFinal(finalPrefix)
    let path_str = dumpPath(path)
    let mod_str = match modification case SOME(mod) then 'SOME(<%dumpModification(mod)%>)' else 'NONE()'
    let cmt_str = dumpStringCommentOption(comment)
    let info_str = dumpInfo(info)
    'MODIFICATION(<%final_str%>, <%each_str%>, <%path_str%>, <%mod_str%>, <%cmt_str%>, <%info_str%>)'
  case REDECLARATION(__) then
    let each_str = dumpEach(eachPrefix)
    let final_str = dumpFinal(finalPrefix)
    let redecl_str = dumpRedeclare(redeclareKeywords)
    let elem_str = dumpElementSpec(elementSpec, final_str, "", "", "", defaultDumpOptions)
    let cc_str = match constrainClass case SOME(cc) then 'SOME(<%dumpConstrainClass(cc)%>)' else 'NONE()'
    let info_str = dumpInfo(info)
    'REDECLARATION(<%final_str%>, <%redecl_str%>, <%each_str%>, <%elem_str%>, <%cc_str%>, <%info_str%>)'
end dumpElementArg;

template dumpEach(Absyn.Each each)
::= match each case EACH() then "EACH()" else "NON_EACH()"
end dumpEach;

template dumpFinal(Boolean final)
::= if final then "true" else "false"
end dumpFinal;

template dumpRedeclare(Absyn.RedeclareKeywords redecl)
::=
match redecl
  case REDECLARE() then "REDECLARE()"
  case REDECLARE_REPLACEABLE() then "REDECLARE_REPLACEABLE()"
end dumpRedeclare;

template dumpReplaceable(Absyn.RedeclareKeywords repl)
::=
match repl
  case REPLACEABLE() then "REPLACEABLE()"
  case REDECLARE_REPLACEABLE() then "REDECLARE_REPLACEABLE()"
end dumpReplaceable;

template dumpInnerOuter(Absyn.InnerOuter io)
::=
match io
  case INNER() then "INNER()"
  case OUTER() then "OUTER()"
  case INNER_OUTER() then "INNER_OUTER()"
  case NOT_INNER_OUTER() then "NOT_INNER_OUTER()"
end dumpInnerOuter;

template dumpModification(Absyn.Modification mod)
::=
match mod
  case CLASSMOD(__) then
    let arg_str = (elementArgLst |> earg => dumpElementArg(earg) ;separator=", ")
    let eq_str = dumpEqMod(eqMod)
    'CLASSMOD(list(<%arg_str%>), <%eq_str%>)'
end dumpModification;

template dumpEqMod(Absyn.EqMod eqmod)
::= match eqmod
  case EQMOD(__) then
    let exp_str = dumpExp(exp)
    let info_str = dumpInfo(info)
    'EQMOD(<%exp_str%>, <%info_str%>)'
  case NOMOD(__) then
    "NOMOD()"
end dumpEqMod;

template dumpElementSpec(Absyn.ElementSpec elem, String final, String redecl,
    String repl, String io, DumpOptions options)
::=
match elem
  case CLASSDEF(__) then
     'CLASSDEF(<%replaceable_%>, <%dumpClass(class_, options)%>)'
  case EXTENDS(__) then
    let bc_str = dumpPath(path)
    let args_str = (elementArg |> earg => dumpElementArg(earg) ;separator=", ")
    let ann_str = dumpAnnotationOptSpace(annotationOpt)
    'EXTENDS(<%bc_str%>, list(<%args_str%>), <%ann_str%>)'
  case COMPONENTS(__) then
    let ty_str = dumpTypeSpec(typeSpec)
    let attr_str = dumpElementAttr(attributes)
    let comps_str = (components |> comp => dumpComponentItem(comp) ;separator=", ")
    'COMPONENTS(<%attr_str%>, <%ty_str%>, list(<%comps_str%>))'
  case IMPORT(__) then
    let cmt_str = dumpCommentOpt(comment)
    let info_str = dumpInfo(info)
    'IMPORT(<%dumpImport(import_)%>, <%cmt_str%>, <%info_str%>)'
end dumpElementSpec;

template dumpElementAttr(Absyn.ElementAttributes attr)
::=
match attr
  case ATTR(__) then
    let flow_str = if flowPrefix then "true" else "false"
    let stream_str = if streamPrefix then "true" else "false"
    let par_str = dumpParallelism(parallelism)
    let field_str = dumpIsField(isField)
    let var_str = dumpVariability(variability)
    let dir_str = dumpDirection(direction)
    let array_dim = dumpArrayDim(arrayDim)
    'ATTR(<%flow_str%>, <%stream_str%>, <%par_str%>, <%var_str%>, <%dir_str%>, <%field_str%>, <%array_dim%>)'
end dumpElementAttr;

template dumpParallelism(Absyn.Parallelism par)
::=
match par
  case PARGLOBAL() then "PARGLOBAL()"
  case PARLOCAL() then "PARGLOBAL()"
  case NON_PARALLEL() then "NON_PARALLEL()"
end dumpParallelism;

template dumpIsField(Absyn.IsField isField)
::=
match isField
  case NONFIELD() then "NONFIELD()"
  case FIELD() then "FIELD()"
end dumpIsField;

template dumpVariability(Absyn.Variability var)
::=
match var
  case VAR() then "VAR()"
  case DISCRETE() then "DISCRETE()"
  case PARAM() then "PARAM()"
  case CONST() then "CONST()"
end dumpVariability;

template dumpDirection(Absyn.Direction dir)
::=
match dir
  case BIDIR() then "BIDIR()"
  case INPUT() then "INPUT()"
  case OUTPUT() then "OUTPUT()"
  case INPUT_OUTPUT() then "INPUT_OUTPUT()"
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
    'CONSTRAINCLASS(<%path_str%>, list(<%el_str%>), <%cmt_str%>)'
end dumpConstrainClass;

template dumpComponentItem(Absyn.ComponentItem comp)
::=
match comp
  case COMPONENTITEM(__) then
    let comp_str = dumpComponent(component)
    let cond_str = dumpComponentCondition(condition)
    let cmt = dumpCommentOpt(comment)
    'COMPONENTITEM(<%comp_str%>, <%cond_str%>, <%cmt%>)'
end dumpComponentItem;

template dumpComponent(Absyn.Component comp)
::=
match comp
  case COMPONENT(__) then
    let dim_str = dumpSubscripts(arrayDim)
    let mod_str = match modification case SOME(mod) then 'SOME(<%dumpModification(mod)%>)' else 'NONE()'
    'COMPONENT("<%Util.escapeModelicaStringToCString(name)%>", <%dim_str%>, <%mod_str%>)'
end dumpComponent;

template dumpComponentCondition(Option<Absyn.ComponentCondition> cond)
::= match cond case SOME(cexp) then 'SOME(<%dumpExp(cexp)%>)' else 'NONE()'
end dumpComponentCondition;

template dumpImport(Absyn.Import imp)
::=
match imp
  case NAMED_IMPORT(__) then 'NAMED_IMPORT("<%Util.escapeModelicaStringToCString(name)%>", <%dumpPath(path)%>)'
  case QUAL_IMPORT(__) then 'QUAL_IMPORT(dumpPath(path))'
  case UNQUAL_IMPORT(__) then 'UNQUAL_IMPORT(<%dumpPath(path)%>)'
  case GROUP_IMPORT(__) then
    let prefix_str = dumpPath(prefix)
    let groups_str = (groups |> group => dumpGroupImport(group) ;separator=",")
    'GROUP_IMPORT(<%prefix_str%>, list(<%groups_str%>))'
end dumpImport;

template dumpGroupImport(Absyn.GroupImport gimp)
::=
match gimp
  case GROUP_IMPORT_NAME(__) then 'GROUP_IMPORT_NAME("<%Util.escapeModelicaStringToCString(name)%>")'
  case GROUP_IMPORT_RENAME(__) then 'GROUP_IMPORT_RENAME("<%Util.escapeModelicaStringToCString(rename)%>", "<%Util.escapeModelicaStringToCString(name)%>")'
end dumpGroupImport;

template dumpElementItem(Absyn.ElementItem eitem, DumpOptions options)
::=
match eitem
  case ELEMENTITEM(__) then 'ELEMENTITEM(<%dumpElement(element, options)%>)'
  case LEXER_COMMENT(__) then 'LEXER_COMMENT("<%System.trimWhitespace(comment)%>")'
end dumpElementItem;

template dumpElement(Absyn.Element elem, DumpOptions options)
::=
match elem
  case ELEMENT(__) then
    if boolOr(boolUnparseFileFromInfo(info, options), boolNot(isClassdef(elem))) then
    let final_str = dumpFinal(finalPrefix)
    let redecl_str = match redeclareKeywords case SOME(re) then 'SOME(<%dumpRedeclare(re)%>)' else 'NONE()'
    let repl_str = match redeclareKeywords case SOME(re) then 'SOME(<%dumpReplaceable(re)%>)' else 'NONE()'
    let io_str = dumpInnerOuter(innerOuter)
    let ec_str = dumpElementSpec(specification, final_str, redecl_str, repl_str, io_str, options)
    let cc_str = match constrainClass case SOME(cc) then 'SOME(<%dumpConstrainClass(cc)%>)' else 'NONE()'
    let info_str = dumpInfo(info)
    'ELEMENT(<%finalPrefix%>, <%redecl_str%>, <%io_str%>, <%ec_str%>, <%info_str%>, <%cc_str%>)'
  case DEFINEUNIT(__) then
    let args_str = if args then '<%(args |> arg => dumpNamedArg(arg))%>'
    'DEFINEUNIT("<%Util.escapeModelicaStringToCString(name)%>", list(<%args_str%>))'
  case TEXT(__) then
    if boolUnparseFileFromInfo(info, options) then
    let name_str = match optName case SOME(name) then 'SOME(name)' else 'NONE()'
    let info_str = dumpInfo(info)
    let string_str = string
    'TEXT("<%name_str%>","<%string_str%>",<%info_str%>)'
end dumpElement;

template dumpEquationItem(Absyn.EquationItem eq)
::=
match eq
  case EQUATIONITEM(__) then
    let eq_str = dumpEquation(equation_)
    let cmt_str = dumpCommentOpt(comment)
    let info_str = dumpInfo(info)
    'EQUATIONITEM(<%eq_str%>, <%cmt_str%>, <%info_str%>)'
  case EQUATIONITEMCOMMENT(__) then 'EQUATIONITEMCOMMENT("<%System.trimWhitespace(comment)%>")'
end dumpEquationItem;

template dumpEquationItems(list<Absyn.EquationItem> eql)
::= (eql |> eq => dumpEquationItem(eq) ;separator=", ")
end dumpEquationItems;

template dumpEquation(Absyn.Equation eq)
::=
match eq
  case EQ_IF(__) then
    let if_str = dumpExp(ifExp)
    let eq_true_str = dumpEquationItems(equationTrueItems)
    let elseif_str = (elseIfBranches |> (c, b) =>
        'tuple(<%dumpExp(c)%>, list(<%dumpEquationItems(b)%>))' ;separator=", ")
    let else_branch_str = dumpEquationItems(equationElseItems)
    'EQ_IF(<%if_str%>, list(<%eq_true_str%>), list(<%elseif_str%>), list(<%else_branch_str%>))'
  case EQ_EQUALS(__) then
    let lhs = dumpLhsExp(leftSide)
    let rhs = dumpExp(rightSide)
    'EQ_EQUALS(<%lhs%>, <%rhs%>)'
  case EQ_PDE(__) then
    let lhs = dumpLhsExp(leftSide)
    let rhs = dumpExp(rightSide)
    let domain_str = dumpCref(domain)
    'EQ_PDE(<%lhs%>, <%rhs%>, <%domain_str%>)'
  case EQ_CONNECT(__) then
    let c1_str = dumpCref(connector1)
    let c2_str = dumpCref(connector2)
    'EQ_CONNECT(<%c1_str%>, <%c2_str%>)'
  case EQ_FOR(__) then
    let iter_str = dumpForIterators(iterators)
    let body_str = dumpEquationItems(forEquations)
    'EQ_FOR(<%iter_str%>, list(<%body_str%>))'
  case EQ_WHEN_E(__) then
    let when_str = dumpExp(whenExp)
    let elsewhen_eqs_str = (elseWhenEquations |> (c, b) =>
        'tuple(<%dumpExp(c)%>, list(<%dumpEquationItems(b)%>))' ;separator=", ")
    let when_eqs = dumpEquationItems(whenEquations)
    'EQ_WHEN_E(<%when_str%>, list(<%when_eqs%>),list(<%elsewhen_eqs_str%>))'
  case EQ_NORETCALL(__) then
    let name_str = dumpCref(functionName)
    let args_str = dumpFunctionArgs(functionArgs)
    'EQ_NORETCALL(<%name_str%>, <%args_str%>)'
  case EQ_FAILURE(__) then
    let eq_str = dumpEquationItem(equ)
    'EQ_FAILURE(<%eq_str%>)'
end dumpEquation;

template dumpAlgorithmItems(list<Absyn.AlgorithmItem> algs)
::=
  let items = (algs |> alg => dumpAlgorithmItem(alg) ;separator=", ")
  'list(<%items%>)'
end dumpAlgorithmItems;

template dumpAlgorithmItem(Absyn.AlgorithmItem alg)
::=
match alg
  case ALGORITHMITEM(__) then
    let alg_str = dumpAlgorithm(algorithm_)
    let cmt_str = dumpCommentOpt(comment)
    let info_str  = dumpInfo(info)
    'ALGORITHMITEM(<%alg_str%>, <%cmt_str%>, <%info_str%>)'
  case ALGORITHMITEMCOMMENT(__) then 'ALGORITHMITEMCOMMENT("I am useless. I am a comment")'
end dumpAlgorithmItem;

template dumpAlgorithm(Absyn.Algorithm alg)
::=
match alg
  case ALG_ASSIGN(__) then
    let lhs_str = dumpLhsExp(assignComponent)
    let rhs_str = dumpExp(value)
    'ALG_ASSIGN(<%lhs_str%>, <%rhs_str%>)'
  case ALG_IF(__) then
    let if_str = dumpExp(ifExp)
    let true_branch = dumpAlgorithmItems(trueBranch)
    let else_if_alg_branch = (elseIfAlgorithmBranch |> (c, b) =>
        '(<%dumpExp(c)%>, list(<%dumpAlgorithmItems(b)%>))' ;separator=", ")
    let else_branch_str = dumpAlgorithmItems(elseBranch)
    let else_branch = dumpAlgorithmItems(elseBranch)
      'ALG_IF(<%if_str%>, <%true_branch%>, list(<%else_if_alg_branch%>), <%else_branch%>)'
  case ALG_FOR(__) then
    let iter_str = dumpForIterators(iterators)
    let body_str = dumpAlgorithmItems(forBody)
    'ALG_FOR(<%iter_str%>, <%body_str%>)'
  case ALG_PARFOR(__) then
    let iter_str = dumpForIterators(iterators)
    let body_str = dumpAlgorithmItems(parforBody)
    'ALG_PARFOR(<%iter_str%>, <%body_str%>)'
  case ALG_WHILE(__) then
    'ALG_WHILE(<%dumpExp(boolExpr)%>, <%dumpAlgorithmItems(whileBody)%>)'
  case ALG_WHEN_A(__) then
    let ewab = (elseWhenAlgorithmBranch |> (c, b) =>
        '(<%dumpExp(c)%>, list(<%dumpAlgorithmItems(b)%>))' ;separator=", ")
    'ALG_WHEN_A(<%dumpExp(boolExpr)%>, <%dumpAlgorithmItems(whenBody)%>, <%ewab%>)'
  case ALG_NORETCALL(__) then
    let name_str = dumpCref(functionCall)
    let args_str = dumpFunctionArgs(functionArgs)
    'ALG_NORETCALL("<%name_str%>", <%args_str%>)'
  case ALG_RETURN(__) then 'ALG_RETURN()'
  case ALG_BREAK(__) then 'ALG_BREAK()'
  case ALG_FAILURE(__) then
    let arg_str = if equ then dumpAlgorithmItems(equ)
    'ALG_FAILURE(<%arg_str%>)'
  case ALG_TRY(__) then 'ALG_TRY(<%dumpAlgorithmItems(body)%>, <%dumpAlgorithmItems(elseBody)%>)'
  case ALG_CONTINUE(__) then 'ALG_CONTINUE()'
end dumpAlgorithm;

template dumpPath(Absyn.Path path)
::=
match path
  case FULLYQUALIFIED(__) then
    'FULLYQUALIFIED(<%dumpPath(path)%>)'
  case QUALIFIED(__) then
    if (Flags.getConfigBool(Flags.MODELICA_OUTPUT)) then
    'QUALIFIED("<%Util.escapeModelicaStringToCString(name)%>", <%dumpPath(path)%>)'
    else
    'IDENT("<%Util.escapeModelicaStringToCString(name)%>")'
  case IDENT(__) then
    'IDENT("<%Util.escapeModelicaStringToCString(name)%>")'
  else
    errorMsg("SCodeDump.dumpPath: Unknown path.")
end dumpPath;

template dumpPathNoQual(Absyn.Path path)
::=
match path
  case FULLYQUALIFIED(__) then 'FULLYQUALIFIED(<%dumpPath(path)%>)'
  else dumpPath(path)
end dumpPathNoQual;

template dumpStringCommentOption(Option<String> cmt)
::= match cmt case SOME(str) then 'SOME("<%str%>")' else 'NONE()'
end dumpStringCommentOption;

template dumpTypeSpec(Absyn.TypeSpec typeSpec)
::=
match typeSpec
  case TPATH(__) then
    let path_str = dumpPath(path)
    let arraydim_str = dumpArrayDimOpt(arrayDim)
    'TPATH(<%path_str%>, <%arraydim_str%>)'
  case TCOMPLEX(__) then
    let path_str = dumpPath(path)
    let ty_str = (typeSpecs |> ty => dumpTypeSpec(ty) ;separator=", ")
    let arraydim_str = dumpArrayDimOpt(arrayDim)
    'TCOMPLEX(<%path_str%>, list(<%ty_str%>), <%arraydim_str%>)'
end dumpTypeSpec;

template dumpArrayDimOpt(Option<Absyn.ArrayDim> arraydim)
::= match arraydim case SOME(ad) then 'SOME(<%dumpSubscripts(ad)%>)' else 'NONE()'
end dumpArrayDimOpt;

template dumpArrayDim(Absyn.ArrayDim arraydim)
::= dumpSubscripts(arraydim)
end dumpArrayDim;

template dumpSubscripts(list<Subscript> subscripts)
::= let sub_str = (subscripts |> s => dumpSubscript(s) ;separator=", ")
    'list(<%sub_str%>)'
end dumpSubscripts;

template dumpSubscript(Absyn.Subscript subscript)
::=
match subscript
  case NOSUB(__) then 'NOSUB()'
  case SUBSCRIPT(__) then 'SUBSCRIPT(<%dumpExp(subscript)%>)'
end dumpSubscript;

template dumpExp(Absyn.Exp exp)
::=
match exp
  case INTEGER(__) then 'INTEGER(<%value%>)'
  case REAL(__) then 'REAL("Util.escapeModelicaStringToCString(<%value%>)")'
  case CREF(__) then 'CREF(<%dumpCref(componentRef)%>)'
  case STRING(__) then 'STRING("<%Util.escapeModelicaStringToCString(value)%>")'
  case BOOL(__) then 'BOOL(<%value%>)'
  case e as BINARY(__) then
    let lhs_str = dumpOperand(exp1, e, true)
    let rhs_str = dumpOperand(exp2, e, false)
    let op_str = dumpOperator(op)
    'BINARY(<%lhs_str%>, <%op_str%>, <%rhs_str%>)'
  case e as UNARY(__) then
    let exp_str = dumpOperand(exp, e, false)
    let op_str = dumpOperator(op)
    'UNARY(<%op_str%>, <%exp_str%>)'
  case e as LBINARY(__) then
    let lhs_str = dumpOperand(exp1, e, true)
    let rhs_str = dumpOperand(exp2, e, false)
    let op_str = dumpOperator(op)
    'LBINARY(<%lhs_str%>, <%op_str%>, <%rhs_str%>)'
  case e as LUNARY(__) then
    let exp_str = dumpOperand(exp, e, false)
    let op_str = dumpOperator(op)
    'LUNARY(<%op_str%>, <%exp_str%>)'
  case e as RELATION(__) then
    let lhs_str = dumpOperand(exp1, e, true)
    let rhs_str = dumpOperand(exp2, e, false)
    let op_str = dumpOperator(op)
    'RELATION(<%lhs_str%>, <%op_str%>, <%rhs_str%>)'
  case IFEXP(__) then dumpIfExp(exp)
  case CALL(function_=Absyn.CREF_IDENT(name="$array")) then
    let args_str = dumpFunctionArgs(functionArgs)
    'CALL(CREF_IDENT("<%Util.escapeModelicaStringToCString("array")%>") ,list(<%args_str%>))'
  case CALL(__) then
    let func_str = dumpCref(function_)
    let args_str = dumpFunctionArgs(functionArgs)
    'CALL(<%func_str%>, <%args_str%>)'
  case PARTEVALFUNCTION(__) then
    let func_str = dumpCref(function_)
    let args_str = dumpFunctionArgs(functionArgs)
    'PARTEVALFUNCTION(<%func_str%>, <%args_str%>)'
  case ARRAY(__) then
    let array_str = (arrayExp |> e => dumpExp(e) ;separator=", ")
    'ARRAY(list(<%array_str%>))'
  case MATRIX(__) then
    let matrix_str = (matrix |> row =>
        'list(<%(row |> e => dumpExp(e) ;separator=", ")%>)' ;separator=", ")
    'MATRIX(list(<%matrix_str%>))'
  case e as RANGE(step = SOME(step)) then
    let start_str = dumpOperand(start, e, false)
    let step_str = dumpOperand(step, e, false)
    let stop_str = dumpOperand(stop, e, false)
    'RANGE(<%start_str%>, SOME(<%step_str%>), <%stop_str%>)'
  case e as RANGE(step = NONE()) then
    let start_str = dumpOperand(start, e, false)
    let stop_str = dumpOperand(stop, e, false)
    'RANGE(<%start_str%>, NONE(), <%stop_str%>)'
  case TUPLE(__) then
    let tuple_str = (expressions |> e => dumpExp(e); separator=", " ;empty)
    'TUPLE(list(<%tuple_str%>))'
  case END(__) then 'END()'
  case CODE(__) then 'CODE(<%dumpCodeNode(code)%>)'
  case AS(__) then
    let exp_str = dumpExp(exp)
    'AS(<%id%>, <%exp_str%>)'
  case CONS(__) then
    let head_str = dumpExp(head)
    let rest_str = dumpExp(rest)
    'CONS(<%head_str%>, <%rest_str%>)'
  case MATCHEXP(__) then dumpMatchExp(exp)
  case LIST(__) then
    let list_str = (exps |> e => dumpExp(e) ;separator=", ")
    'LIST(list(<%list_str%>))'
  case DOT(__) then
    'DOT(<%dumpExp(exp)%>, <%dumpExp(index)%>)'
  case _ then '/* AbsynDumpTpl.dumpExp: UNHANDLED Abyn.Exp */'
end dumpExp;

template dumpLhsExp(Absyn.Exp lhs)
::=
match lhs
  case IFEXP(__) then '(<%dumpExp(lhs)%>)'
  else dumpExp(lhs)
end dumpLhsExp;

template dumpOperand(Absyn.Exp operand, Absyn.Exp operation, Boolean lhs)
::= dumpExp(operand)
end dumpOperand;

template dumpIfExp(Absyn.Exp if_exp)
::=
match if_exp
  case IFEXP(__) then
    let cond_str = dumpExp(ifExp)
    let true_branch_str = dumpExp(trueBranch)
    let else_branch_str = dumpExp(elseBranch)
    let else_if_str = dumpElseIfExp(elseIfBranch)
    'IFEXP(<%cond_str%>, <%true_branch_str%>, <%else_branch_str%>, <%else_if_str%>)'
end dumpIfExp;

template dumpElseIfExp(list<tuple<Absyn.Exp, Absyn.Exp>> else_if)
::=
  let lst = else_if |> eib as (cond, branch) =>
      let cond_str = dumpExp(cond)
      let branch_str = dumpExp(branch)
      '(<%cond_str%>, <%branch_str%>)' ;separator=", "
  'list(<%lst%>)'
end dumpElseIfExp;

template dumpCodeNode(Absyn.CodeNode code)
::=
match code
  case C_TYPENAME(__) then 'C_TYPENAME(dumpPath(path))'
  case C_VARIABLENAME(__) then 'C_VARIABLENAME(dumpCref(componentRef))'
  case C_CONSTRAINTSECTION(__) then
    let initial_str = if boolean then "true" else "false"
    let equation_is_str = dumpEquationItems(equationItemLst)
    'C_CONSTRAINTSECTION(<%initial_str%>, list(<%equation_is_str%>))'
  case C_EQUATIONSECTION(__) then
    let initial_str = if boolean then "true" else "false"
    let eql_str = dumpEquationItems(equationItemLst)
    'C_EQUATIONSECTION(<%initial_str%>, list(<%eql_str%>))'
  case C_ALGORITHMSECTION(__) then
    let initial_str = if boolean then "true" else "false"
    let algs_str = dumpAlgorithmItems(algorithmItemLst)
    'C_ALGORITHMSECTION(<%initial_str%>, list(<%algs_str%>))'
  case C_EXPRESSION(__) then 'C_EXPRESSION(<%dumpExp(exp)%>)'
  case C_MODIFICATION(__) then 'C_MODIFICATION(<%dumpModification(modification)%>'
  case C_ELEMENT(__) then 'C_ELEMENT(<%dumpElement(element, Dump.defaultDumpOptions)%>)'
end dumpCodeNode;

template dumpMatchExp(Absyn.Exp match_exp)
::=
match match_exp
  case MATCHEXP(__) then
    let ty_str = dumpMatchType(matchTy)
    let input_str = dumpExp(inputExp)
    let locals_str = dumpMatchLocals(localDecls)
    let cases_str = (cases |> c => dumpMatchCase(c) ;separator=", ")
    let cmt_str = dumpStringCommentOption(comment)
    'MATCHEXP(<%ty_str%>, <%input_str%>, <%locals_str%>, <%cases_str%>, <%cmt_str%>)'
end dumpMatchExp;

template dumpMatchType(Absyn.MatchType match_type)
::=
match match_type
  case MATCH() then "MATCH()"
  case MATCHCONTINUE() then "MATCHCONTINUE()"
end dumpMatchType;

template dumpMatchLocals(list<ElementItem> locals)
::= if locals then
      'list(<%(locals |> decl => dumpElementItem(decl, defaultDumpOptions) ;separator=", ")%>)'
end dumpMatchLocals;

template dumpMatchEquations(ClassPart cp)
::=
  match cp
  case EQUATIONS(contents={}) then "EQUATIONS(list())"
  case EQUATIONS(contents=eql) then
      'EQUATIONS(<%(eql |> eq => dumpEquationItem(eq) ;separator=", ")%>)'
  case ALGORITHMS(contents={}) then "ALGORITHMS(list())"
  case ALGORITHMS(contents=algs) then
      'ALGORITHMS(<%(algs |> alg => dumpAlgorithmItem(alg) ;separator=", ")%>)'
end dumpMatchEquations;

template dumpMatchCase(Absyn.Case c)
::=
match c
  case CASE(__) then
    let pattern_str = dumpExp(pattern)
    let guard_str = match patternGuard case SOME(g) then 'SOME(<%dumpExp(g)%>)' else 'NONE()'
    let p_info_str = dumpInfo(patternInfo)
    let local_decls_str = (localDecls |> d => dumpElementItem(d, defaultDumpOptions);separator=", ")
    let eql_str = dumpMatchEquations(classPart)
    let result_str = dumpExp(result)
    let r_i_str = dumpInfo(resultInfo)
    let cmt_str = dumpStringCommentOption(comment)
    let i_str = dumpInfo(info)
    'CASE(<%pattern_str%>, <%guard_str%>, <%p_info_str%>, list(<%local_decls_str%>), <%eql_str%>, <%result_str%>, <%r_i_str%>, <%cmt_str%>, <%i_str%>)'
  case ELSE(__) then
    let local_decls_str = (localDecls |> d => dumpElementItem(d, defaultDumpOptions);separator=", ")
    let eql_str = dumpMatchEquations(classPart)
    let result_str = dumpExp(result)
    let cmt_str = dumpStringCommentOption(comment)
    let r_i_str = dumpInfo(resultInfo)
    let info_str = dumpInfo(info)
    'ELSE(<%local_decls_str%>, <%eql_str%>, <%result_str%>, <%r_i_str%>, <%cmt_str%>, <%info_str%>)'
end dumpMatchCase;

template dumpOperator(Absyn.Operator op)
::=
match op
  case ADD(__) then 'ADD()'
  case ADD_EW(__) then 'ADD_EW()'
  case AND(__) then 'AND()'
  case DIV(__) then 'DIV()'
  case DIV_EW(__) then 'DIV_EW()'
  case EQUAL(__) then 'EQUAL()'
  case GREATER(__) then 'GREATER()'
  case GREATEREQ(__) then 'GREATEREQ()'
  case LESS(__) then 'LESS()'
  case LESSEQ(__) then 'LESSEQ()'
  case MUL(__) then 'MUL()'
  case MUL_EW(__) then 'MUL_EW()'
  case NEQUAL(__) then 'NEQUAL()'
  case NOT(__) then 'NOT()'
  case OR(__) then 'OR()'
  case POW(__) then 'POW()'
  case POW_EW(__) then 'POW_EW()'
  case SUB(__) then 'SUB()'
  case SUB_EW(__) then 'SUB_EW()'
  case UMINUS(__) then 'UMINUS()'
  case UMINUS_EW(__) then 'UMINUS_EW()'
  case UPLUS(__) then 'UPLUS()'
  case UPLUS_EW(__) then 'UPLUS_EW()'
end dumpOperator;

template dumpCref(Absyn.ComponentRef cref)
::=
match cref
  case CREF_QUAL(__) then 'CREF_QUAL("<%Util.escapeModelicaStringToCString(name)%>", <%dumpSubscripts(subscripts)%>, <%dumpCref(componentRef)%>)'
  case CREF_IDENT(__) then 'CREF_IDENT("<%Util.escapeModelicaStringToCString(name)%>", <%dumpSubscripts(subscripts)%>)'
  case CREF_FULLYQUALIFIED(__) then 'CREF_FULLYQUALIFIED(<%dumpCref(componentRef)%>)'
  case WILD(__) then if Config.acceptMetaModelicaGrammar() then "WILD()" else "WILD()"
  case ALLWILD(__) then 'ALLWILD()'
end dumpCref;

template dumpFunctionArgs(Absyn.FunctionArgs args)
::=
match args
  case FUNCTIONARGS(__) then
    let args_str = (args |> arg => dumpExp(arg) ;separator=", ")
    let namedargs_str = (argNames |> narg => dumpNamedArg(narg) ;separator=", ")
    'FUNCTIONARGS(list(<%args_str%>), list(<%namedargs_str%>))'
  case FOR_ITER_FARG(__) then
    let exp_str = dumpExp(exp)
    let iter_str = (iterators |> i => dumpForIterator(i) ;separator=", ")
    let iter_type_str = match iterType case THREAD() then "THREAD()" else "COMBINE()"
    'FOR_ITER_FARG(<%exp_str%>, <%iter_type_str%>,<%iter_str%>)'
end dumpFunctionArgs;

template dumpNamedArg(Absyn.NamedArg narg)
::= match narg case NAMEDARG(__) then 'NAMEDARG(<%argName%>, <%dumpExp(argValue)%>)'
end dumpNamedArg;

template dumpForIterators(Absyn.ForIterators iters)
::= (iters |> i => dumpForIterator(i) ;separator=", ")
end dumpForIterators;

template dumpForIterator(Absyn.ForIterator iterator)
::=
match iterator case ITERATOR(__) then
  let ge = match guardExp case SOME(x) then 'SOME(<%dumpExp(x)%>)' else 'NONE()'
  let re = match range case SOME(x) then 'SOME(<%dumpExp(x)%>)' else 'NONE()'
  'ITERATOR("<%Util.escapeModelicaStringToCString(name)%>", <%ge%>, <%re%>)'
end dumpForIterator;

template errorMsg(String errMessage)
::=
let() = Tpl.addTemplateError(errMessage)
<<
<%errMessage%>
>>
end errorMsg;

annotation(__OpenModelica_Interface="frontend");

end AbsynJLDumpTpl;
