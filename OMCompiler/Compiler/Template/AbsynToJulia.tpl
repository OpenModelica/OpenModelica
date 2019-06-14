package AbsynToJulia

import interface AbsynToJuliaTV;
import AbsynDumpTpl;

template dumpProgram(Absyn.Program program)
::=
match program
  case PROGRAM(classes = {}) then ""
  case PROGRAM(__) then
    let cls_str = (classes |> cls => dumpClass(cls, defaultDumpOptions) ;separator="\n\n")
    '<%cls_str%>'
end dumpProgram;

template dumpClass(Absyn.Class cls, DumpOptions options)
::= dumpClassElement(cls, options)
end dumpClass;

template dumpClassElement(Absyn.Class class, DumpOptions options)
::=
match class
  case CLASS(restriction=R_UNIONTYPE(__)) then
      dumpClassDef(body, packageContext, options)
  case CLASS(partialPrefix=true, restriction=R_FUNCTION(__)) then
    /* Julia does not really support types of higher-order functions */
    '<%name%> = Function'
  case CLASS(body=parts as PARTS(__), restriction=R_FUNCTION(__)) then
    let commentStr = dumpCommentStrOpt(parts.comment)
    //Currently only check first section. See over this... people can add inputs at other places
    let returnType = (parts.classParts |> cp => dumpReturnTypeJL(Absyn.getElementItemsInClassPart(cp)))
    let return_str = (parts.classParts |> cp => dumpReturnStrJL(Absyn.getElementItemsInClassPart(cp)))
    let inputs_str = (parts.classParts |> cp => dumpInputsJL(Absyn.getElementItemsInClassPart(cp)))
    let functionBodyStr = dumpClassDef(parts, functionContext, options)
    <<
    function <%name%>(<%inputs_str%>)<%returnType%>
    <%commentStr%>
      <%functionBodyStr%>
      return <%return_str%>
    end
    >>
  case CLASS(body=parts as PARTS(__)) then
    let enc_str = if encapsulatedPrefix then "" /*Should we use a macro here?*/ else ""
    let partial_str = if partialPrefix then "abstract" else ""
    let res_str = dumpRestriction(restriction)
    let prefixes_str = '<%partial_str%><%res_str%> <%name%>'
    let cdef_str1 = dumpClassDef(parts, packageContext, options)
    let cdef_str2 = match restriction
      case R_PACKAGE(__) then
        <<

        using MetaModelica
        <%cdef_str1%>
        >>
      else cdef_str1
    let cdef_str = cdef_str2
    let cmt_str = dumpCommentStrOpt(parts.comment)
    /* Investigate header_str and annotation string*/
    //let ann_str = dumpClassAnnotation(cmt)
    //let header_str = dumpClassHeader(body, name, restriction, cmt_str)
    let footer_str = dumpClassFooter(parts, cdef_str, name, cmt_str, "" /*ann_str*/)
    <<
    <%prefixes_str%> <%footer_str%>
    >>
end dumpClassElement;

template dumpClassFooter(ClassDef classDef, String cdefStr, String name, String cmt, String ann)
::=
match classDef
  case DERIVED(__) then AbsynDumpTpl.errorMsg("AbsynToJulia.dumpClassFooter: Derived not yet supported.")
  case ENUMERATION(__) then AbsynDumpTpl.errorMsg("AbsynToJulia.dumpClassFooterf: ENUMERATION not yet supported.")
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

template dumpInputsJL(list<ElementItem> inputs)
::=
  let inputStr = ((MMToJuliaUtil.filterOnDirection(inputs, MMToJuliaUtil.makeInputDirection()))
    |> ei
      => '<%dumpComponentItems(getComponentItemsFromElementItem(ei))%>::<%dumpTypeSpecOpt(getTypeSpecFromElementItemOpt(ei))%>'
      ;separator=", ")
 '<%inputStr%>'

end dumpInputsJL;

template dumpReturnTypeJL(list<ElementItem> outputs)
::=
match MMToJuliaUtil.filterOnDirection(outputs, MMToJuliaUtil.makeOutputDirection())
  case {} then ""
  case L as H::{} then '::<%dumpOutputsJL(L)%>'
  case L as H::T then '::Tuple{<%dumpOutputsJL(L)%>}'
end dumpReturnTypeJL;

template dumpReturnStrJL(list<ElementItem> outputs)
::=
match MMToJuliaUtil.filterOnDirection(outputs, MMToJuliaUtil.makeOutputDirection())
  case {} then ""
  case L as H::{} then
  <<
    <%(L |> e => dumpElementItemNoLocal(e, defaultDumpOptions); separator=", ")%>
  >>
  case L as H::T then
  <<
  (
    <%(L |> e => dumpElementItemNoLocal(e, defaultDumpOptions); separator=", ")%>
  )
  >>
end dumpReturnStrJL;


template dumpClassDef(Absyn.ClassDef cdef, Context context, DumpOptions options)
::=
match cdef
  case PARTS(__) then
    let body_str = (classParts |> class_part hasindex idx =>
        dumpClassPart(class_part, idx, context, options) ;separator="")
    <<
      <%body_str%>
    >>
  case DERIVED(__) then
    AbsynDumpTpl.errorMsg("AbsynToJulia.dumpClassDef: Derived not yet supported.")
  case CLASS_EXTENDS(__) then
    AbsynDumpTpl.errorMsg("AbsynToJulia.dumpClassDef: CLASS_EXETENDS not yet supported.")
  case ENUMERATION(__) then
    AbsynDumpTpl.errorMsg("AbsynToJulia.dumpClassDef: CLASS_ENUMERATION not yet supported.")
  else "TODO Unkown class definition"
end dumpClassDef;

template dumpClassPrefixes(Absyn.Class cls, String final_str,
    String redecl_str, String repl_str)
::=
match cls
  case CLASS(__) then
    let enc_str = if encapsulatedPrefix then "encapsulated "
    let partial_str = if partialPrefix then "partial "
    let fin_str = dumpFinal(finalPrefix)
    '<%redecl_str%><%fin_str%><%repl_str%><%enc_str%><%partial_str%>'
end dumpClassPrefixes;

template dumpRestriction(Absyn.Restriction restriction)
::=
match restriction
  case R_PACKAGE(__) then 'module'
  case R_METARECORD(__) then 'struct'
  case R_UNIONTYPE(__) then 'uniontype'
  case R_TYPE(__) then '' // Should be const iff we are in a global scope (Julia 1.0 (Packages are not))
  case R_FUNCTION(__) then 'function'
  //TODO: The other ones are probably not relevant for now
  else AbsynDumpTpl.errorMsg("AbsynToJulia.dumpRestriction: Unknown restriction for class.")
end dumpRestriction;

template dumpClassPart(Absyn.ClassPart class_part, Integer idx, Context context, DumpOptions options)
::=
match class_part
  case PUBLIC(__) then
        let el_str = if isFunctionContext(context) then
                       dumpElementItems(filterOnDirection(contents, makeOutputDirection()), "", true, options)
                     else
                       dumpElementItems(contents, "", true, options)
      <<
        <%el_str%>
      >>
  case PROTECTED(__) then
    let el_str = dumpElementItems(contents, "", true, options)
    <<
      <%el_str%>
    >>
  case CONSTRAINTS(__) then
    <<
    constraint
      <%(contents |> exp => dumpExp(exp) ;separator=" ")%>
    >>
  case EQUATIONS(__) then
    AbsynDumpTpl.errorMsg("AbsynToJulia.dumpClassPart: EQUATIONS(__) not supported.")
  case INITIALEQUATIONS(__) then
    AbsynDumpTpl.errorMsg("AbsynToJulia.dumpClassPart: INITIALEQUATIONS() not supported.")
  case ALGORITHMS(__) then
    <<
      <%(contents |> eq => dumpAlgorithmItem(eq) ;separator="\n")%><%\n%>
    >>
  case INITIALALGORITHMS(__) then
    AbsynDumpTpl.errorMsg("AbsynToJulia.dumpClassPart: INITIALALGORITHMS() not supported.")
  case EXTERNAL(__) then
    let ann_str = match annotation_ case SOME(ann) then ' <%dumpAnnotation(ann)%>;'
    match externalDecl
      case EXTERNALDECL(__) then
        AbsynDumpTpl.errorMsg("AbsynToJulia.dumpClassPart: EXTERNALDECL(__) not supported.")
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
  case ELEMENTITEM(__) then 'local <%dumpElement(element, options)%>'
  case LEXER_COMMENT(__) then dumpCommentStr(comment)
end dumpElementItem;

template dumpElementItemNoLocal(Absyn.ElementItem eitem, DumpOptions options)
"Same as dumpElementItem but does not add the local prefix"
::=
match eitem
  case ELEMENTITEM(__) then '<%dumpElement(element, options)%>'
  case LEXER_COMMENT(__) then dumpCommentStr(comment)
end dumpElementItemNoLocal;

template dumpElement(Absyn.Element elem, DumpOptions options)
::=
match elem
  case ELEMENT(__) then
    if boolOr(boolUnparseFileFromInfo(info, options), boolNot(isClassdef(elem))) then
    let final_str = dumpFinal(finalPrefix)
    let redecl_str = match redeclareKeywords case SOME(re) then dumpRedeclare(re)
    let repl_str = match redeclareKeywords case SOME(re) then dumpReplaceable(re)
    let elementSpec_str = dumpElementSpec(specification, options)
    let constrainClass_str = match constrainClass case SOME(cc) then dumpConstrainClass(cc)
    '<%elementSpec_str%><%constrainClass_str%>'
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
  case ANNOTATION(elementArgs={}) then "#= annotation() =#"
  case ANNOTATION(__) then
    <<
    #= annotation(
      <%(elementArgs |> earg => dumpElementArg(earg) ;separator=',<%\n%>')%>) #=
    >>
end dumpAnnotation;

template dumpAnnotationOpt(Option<Absyn.Annotation> oann)
::= match oann case SOME(ann) then dumpAnnotation(ann)
end dumpAnnotationOpt;

template dumpAnnotationOptSpace(Option<Absyn.Annotation> oann)
::= match oann case SOME(ann) then " " + dumpAnnotation(ann)
end dumpAnnotationOptSpace;

template dumpComment(Absyn.Comment cmt)
::=
match cmt
  case COMMENT(__) then
    dumpCommentStrOpt(comment) + dumpAnnotationOptSpace(annotation_)
end dumpComment;

template dumpCommentOpt(Option<Absyn.Comment> ocmt)
::= match ocmt case SOME(cmt) then dumpComment(cmt)
end dumpCommentOpt;

template dumpCommentStrOpt(Option<String> comment)
::=match comment case SOME(cmt) then dumpCommentStr(cmt)
end dumpCommentStrOpt;

template dumpCommentStr(String comment)
::=
let replaceAllRegular = '<%\ %>#= <%System.stringReplace(System.escapedString(comment, false), "//","")%> =#'
'<%replaceAllRegular%>'
end dumpCommentStr;

template dumpElementArg(Absyn.ElementArg earg)
::= AbsynDumpTpl.errorMsg("AbsynToJulia.dumpElementArg: Not implemented")
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

template dumpElementSpec(ElementSpec specification, DumpOptions options)
::=
match specification
  case CLASSDEF(__) then dumpClassElement(class_, options)
  case EXTENDS(__) then
    let bc_str = dumpPathJL(path)
    let args_str = (elementArg |> earg => dumpElementArg(earg) ;separator=", ")
    let mod_str = if args_str then '(<%args_str%>)'
    let ann_str = dumpAnnotationOptSpace(annotationOpt)
    'extends <%bc_str%><%mod_str%><%ann_str%>'
  case COMPONENTS(__) then
    let ty_str = dumpTypeSpec(typeSpec)
    let attr_str = dumpElementAttr(attributes)
    //let dim_str = dumpElementAttrDim(attributes) readd. We do not use it for now
    let comps_str = (components |> comp => dumpComponentItem(comp) ;separator=", ")
    //TODO more check for more complex variables..
    //This must be local variables. Output and protected variables should be dumped here..
    '<%comps_str%>::<%ty_str%>'
  case IMPORT(__) then
    let imp_str = dumpImport(import_)
    'import <%imp_str%>'
end dumpElementSpec;

template dumpElementAttr(Absyn.ElementAttributes attr)
::=
match attr
  case ATTR(__) then
    let var_str = dumpVariability(variability)
    '<%var_str%>'
end dumpElementAttr;

template dumpVariability(Absyn.Variability var)
::=
match var
  /*
    Constants are currently only allowed in the global scope (Julia 1.1).
    TODO: Global scope is only defined as a scope outside a module.
          What do to here, Scope as a parameter?
  */
  case VAR() then ""
  case CONST() then ""
  else AbsynDumpTpl.errorMsg("AbsynToJulia.dumpVariability: Only const and var are supported")
end dumpVariability;

template dumpElementAttrDim(Absyn.ElementAttributes attr)
::= match attr case ATTR(__) then dumpSubscripts(arrayDim)
end dumpElementAttrDim;

template dumpConstrainClass(Absyn.ConstrainClass cc)
::=
match cc
  case CONSTRAINCLASS(elementSpec = Absyn.EXTENDS(path = p, elementArg = el)) then
    let path_str = dumpPathJL(p)
    let el_str = if el then '(<%(el |> e => dumpElementArg(e) ;separator=", ")%>)'
    let cmt_str = dumpCommentOpt(comment)
    ' constrainedby <%path_str%><%el_str%><%cmt_str%>'
end dumpConstrainClass;

template dumpComponentItems(list<Absyn.ComponentItem> componentItems)
"Returns a comma separated list of component items without the condition string"
::= (componentItems |> ci => dumpComponentItemWithoutCondString(ci) ;separator=", ")
end dumpComponentItems;

template dumpComponentItem(Absyn.ComponentItem comp)
::=
match comp
  case COMPONENTITEM(__) then
    let comp_str = dumpComponent(component)
    let cond_str = dumpComponentCondition(condition) //TODO. This will complicate things...
    let cmt = dumpCommentOpt(comment)
    '<%comp_str%><%cond_str%><%cmt%>'
end dumpComponentItem;

template dumpComponentItemWithoutCondStringOpt(Option<Absyn.ComponentItem> compOpt)
::= match compOpt case SOME(comp) then dumpComponentItemWithoutCondString(comp) else ""
end dumpComponentItemWithoutCondStringOpt;

template dumpComponentItemWithoutCondString(Absyn.ComponentItem comp)
::=
match comp
  case COMPONENTITEM(__) then
    let comp_str = dumpComponent(component)
    //let cmt = dumpCommentOpt(comment)
    '<%comp_str%>'
end dumpComponentItemWithoutCondString;

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
  case NAMED_IMPORT(__) then AbsynDumpTpl.errorMsg("Named imports are not implemented!.")
  case QUAL_IMPORT(__) then dumpPathJL(path)
  case UNQUAL_IMPORT(__) then '<%dumpPathJL(path)%>.*'
  case GROUP_IMPORT(__) then
    let prefix_str = dumpPathJL(prefix)
    let groups_str = (groups |> group => dumpGroupImport(group) ;separator=",")
    '<%prefix_str%>.{<%groups_str%>}'
end dumpImport;

template dumpGroupImport(Absyn.GroupImport gimp)
::=
match gimp
  case GROUP_IMPORT_NAME(__) then name
  case GROUP_IMPORT_RENAME(__) then '<%rename%> = <%name%>'
end dumpGroupImport;

template dumpEquation(Absyn.Equation eq)
::= "No equations allowed. Translate them to algorithms"
end dumpEquation;

template dumpAlgorithmItems(list<Absyn.AlgorithmItem> algs)
::= (algs |> alg => dumpAlgorithmItem(alg) ;separator="\n")
end dumpAlgorithmItems;

template dumpAlgorithmItem(Absyn.AlgorithmItem alg)
::=
match alg
  case ALGORITHMITEM(__) then
    let alg_str = dumpAlgorithm(algorithm_)
    let cmt_str = dumpCommentOpt(comment)
    '<%alg_str%><%cmt_str%>'
  case ALGORITHMITEMCOMMENT(__) then dumpCommentStr(comment)
end dumpAlgorithmItem;

template dumpAlgorithm(Absyn.Algorithm alg)
::=
match alg
  case ALG_ASSIGN(__) then
    let lhs_str = dumpLhsExp(assignComponent)
    let rhs_str = dumpExp(value)
    '<%lhs_str%> = <%rhs_str%>'
  case ALG_IF(__) then
    let if_str = dumpAlgorithmBranch(ifExp, trueBranch, "if")
    let elseif_str = (elseIfAlgorithmBranch |> (c, b) =>
        dumpAlgorithmBranch(c, b, "elseif") ;separator="\n")
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
    end
    >>
  case ALG_FOR(__) then
    let iter_str = dumpForIterators(iterators)
    let body_str = dumpAlgorithmItems(forBody)
    <<
    for <%iter_str%>
      <%body_str%>
    end
    >>
  case ALG_WHILE(__) then
    let while_str = dumpAlgorithmBranch(boolExpr, whileBody, "while")
    <<
    <%while_str%>
    end
    >>
  case ALG_WHEN_A(__) then  AbsynDumpTpl.errorMsg("When statements are not allowed!.")
  case ALG_NORETCALL(__) then
    let name_str = dumpCref(functionCall)
    let args_str = dumpFunctionArgs(functionArgs)
    '<%name_str%>(<%args_str%>)'
  case ALG_RETURN(__) then "return"
  case ALG_BREAK(__) then "break"
  case ALG_FAILURE(__) then
    let arg_str = if equ then dumpAlgorithmItems(equ) else "..."
    '@failure(<%arg_str%>)' //We could simply use throw or we can define a macro for this
  case ALG_TRY(__) then
    let arg1 = dumpAlgorithmItems(body)
    let arg2 = dumpAlgorithmItems(elseBody)
    <<
    try
      <%arg1%>
    catch Exception //MM does not really have specialised exceptions
      <%arg2%>
    end
    >>
  case ALG_CONTINUE(__) then "continue"
end dumpAlgorithm;

template dumpAlgorithmBranch(Absyn.Exp cond, list<Absyn.AlgorithmItem> body,
String header)
::=
  let cond_str = dumpExp(cond)
  let body_str = (body |> eq => dumpAlgorithmItem(eq) ;separator="\n")
  <<
  <%header%> <%cond_str%>
    <%body_str%>
  >>
end dumpAlgorithmBranch;

template dumpPathJL(Absyn.Path path)
"Wrapper function for dump path.
 Needed since certain keywords will have a sligthly different meaning in Julia"
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
  /*
    ModelicaReal = Union {Signed, AbstractFloat}
    ModelicaInteger is represented as it's own type.
    Bool should not require any change if the above is kept
    Clock e.t.c are probably not necessary to add
  */
  case IDENT(__) then
    match name
      case "Real" then 'ModelicaReal'
      case "Integer" then 'ModelicaInteger'
      case "Boolean" then 'Bool'
      else '<%name%>'
  else
    AbsynDumpTpl.errorMsg("AbsynToJulia.dumpPathJL: Unknown path.")
end dumpPathJL;

template dumpPathNoQual(Absyn.Path path)
::=
match path
  case FULLYQUALIFIED(__) then
    dumpPathJL(path)
  else
    dumpPathJL(path)
end dumpPathNoQual;

template dumpTypeSpecOpt(Option<Absyn.TypeSpec> typespecOpt)
::= match typespecOpt case SOME(ts) then dumpTypeSpec(ts) else ""
end dumpTypeSpecOpt;

template dumpTypeSpec(Absyn.TypeSpec typeSpec)
::=
match typeSpec
  case TPATH(__) then
    let path_str = dumpPathJL(path)
    let arraydim_str = dumpArrayDimOpt(arrayDim)
    '<%path_str%><%arraydim_str%>'
  case TCOMPLEX(__) then
    let path_str = dumpPathJL(path)
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
  case STRING(__) then ('"<%value; absIndent=0%>"')
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
    '<%head_str%>> => <%rest_str%>'
  case MATCHEXP(__) then dumpMatchExp(exp)
  case LIST(__) then
    let list_str = (exps |> e => dumpExp(e) ;separator=", ")
    '{<%list_str%>}'
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

template dumpNamedArgPattern(Absyn.NamedArg narg)
::=
match narg
  case NAMEDARG(__) then
    '<%argName%> = <%dumpPattern(argValue)%>'
end dumpNamedArgPattern;

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
  case C_TYPENAME(__) then dumpPathJL(path)
  case C_VARIABLENAME(__) then dumpCref(componentRef)
  case C_CONSTRAINTSECTION(__) then
    AbsynDumpTpl.errorMsg("AbsynToJulia.dumpCodeNode: C_CONSTRAINTSECTION not supported")
  case C_EQUATIONSECTION(__) then
    AbsynDumpTpl.errorMsg("AbsynToJulia.dumpCodeNode: C_CONSTRAINTSECTION not supported")
  case C_ALGORITHMSECTION(__) then
    AbsynDumpTpl.errorMsg("AbsynToJulia.dumpCodeNode: C_ALGORITHMSECTION not supported")
  case C_ELEMENT(__) then dumpElement(element, Dump.defaultDumpOptions)
  case C_EXPRESSION(__) then dumpExp(exp)
  case C_MODIFICATION(__) then dumpModification(modification)
end dumpCodeNode;

//John: look at this one more time...
template dumpMatchExp(Absyn.Exp match_exp)
::=
match match_exp
  case MATCHEXP(__) then
    let ty_str = dumpMatchType(matchTy)
    let input_str = dumpExp(inputExp)
    let locals_str = dumpMatchLocals(localDecls)
    let cases_str = (cases |> c => dumpMatchCase(c) ;separator="\n\n")
    let cmt_str = dumpCommentStrOpt(comment)
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
  case MATCH() then "@match"
  case MATCHCONTINUE() then "@matchcontinue"
end dumpMatchType;

template dumpMatchEquations(ClassPart cp)
::=
  match cp
  case EQUATIONS(__) then
    AbsynDumpTpl.errorMsg("Failed to dump match equations. Support not yet added")
  case ALGORITHMS(contents={}) then ""
  case ALGORITHMS(contents=algs) then
    <<
      <%(algs |> alg => dumpAlgorithmItem(alg) ;separator="\n")%>
    >>
end dumpMatchEquations;

template dumpMatchLocals(list<ElementItem> locals)
::= if locals then
  <<
    local //TODO add a local decl to this
      <%(locals |> decl => dumpElementItem(decl, defaultDumpOptions) ;separator="\n")%>
  >>
end dumpMatchLocals;

template dumpMatchCase(Absyn.Case c)
::=
match c
  case CASE(__) then
    let pattern_str = dumpPattern(pattern)
    let guard_str = match patternGuard case SOME(g) then 'guard <%dumpExp(g)%> '
    let eql_str = dumpMatchEquations(classPart)
    let result_str = dumpExp(result)
    let cmt_str = dumpCommentStrOpt(comment)
    <<
    <%pattern_str%> <%guard_str%><%cmt_str%> => (
      <%eql_str%>
      <%result_str%>
      )
    >>
  case ELSE(__) then
    let eql_str = dumpMatchEquations(classPart)
    let result_str = dumpExp(result)
    let cmt_str = dumpCommentStrOpt(comment)
    <<
    _ <%cmt_str%> => begin (
      <%eql_str%>
      <%result_str%>
      )
    >>
end dumpMatchCase;

template dumpOperator(Absyn.Operator op)
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

template dumpOutputsJL(list<ElementItem> elements)
::=
  let outputStr = (elements |> e => dumpTypeSpecOpt(AbsynUtil.getTypeSpecFromElementItemOpt(e)) ;separator=", ")
  '<%outputStr%>'
end dumpOutputsJL;

annotation(__OpenModelica_Interface="backend");
end AbsynToJulia;
