
spackage TplCodegen
  
typeview "TplCodegenTV.mo"


template mmPackage(MMPackage it) ::=  
  match it
  case MM_PACKAGE(__) then
    <<
    package <%pathIdent(name)%>

    protected constant Tpl.Text emptyTxt = Tpl.MEM_TEXT({}, {}); 

    public import Tpl;

    <%mmDeclarations |> it => mmDeclaration(it);separator="\n"%>
 
    end <%pathIdent(name)%>;
    >>
end mmPackage;

template mmDeclaration(MMDeclaration it) ::=
  match it
  case MM_IMPORT(packageName = IDENT(ident = "Tpl")) then '' //ignore Tpl as it is always imported
  case MM_IMPORT(packageName = IDENT(ident = "builtin")) then '' //ignore Tpl as it is always imported
  case MM_IMPORT(__) then
    <<
    <%mmPublic(isPublic)%> import <%pathIdent(packageName)%>;
    >>
  case MM_STR_TOKEN_DECL(__) then
    <<
  
    <%mmPublic(isPublic)%> constant Tpl.StringToken <%name%> = <%mmStringTokenConstant(value)%>;
    >>
  case MM_LITERAL_DECL(__) then
    <<
  
    <%mmPublic(isPublic)%> constant <%typeSig(litType)%> <%name%> = <%value%>;
    >>
  case mf as MM_FUN(__) then
    <<
  
    <%mmPublic(isPublic)%> function <%name%>  
    <%match statements
     case {c as MM_MATCH(__)} then //match function 
       mmMatchFunBody(mf.inArgs, mf.outArgs, mf.locals, c.matchCases)       
     case sts then //simple assignment functions
       <<
         <%typedIdentsEx(mf.inArgs, "input", "")%>
  
         <%typedIdentsEx(mf.outArgs, "output", "out_")%>
       <%if mf.locals then <<
       protected
         <%typedIdents(mf.locals)%>
       >>%>
       algorithm
         <%sts |> it => '<%mmExp(it, ":=")%>;' ;separator="\n"%>
       >>
    %>
    end <%name%>;
    >>
end mmDeclaration;

template mmMatchFunBody(TypedIdents inArgs, TypedIdents outArgs, TypedIdents locals, list<MMMatchCase> matchCases) ::=
<<
  <%typedIdentsEx(inArgs, "input", "in_")%>
  
  <%typedIdentsEx(outArgs, "output", "out_")%>
algorithm
  <%match outArgs
   case {(nm,_)} then 'out_<%nm%>'
   case outArgs  then <<(<%outArgs |> (nm,_)=> 'out_<%nm%>' ;separator=", "%>)>>
  %> :=  
  matchcontinue(<%inArgs |> (nm,_) => 'in_<%nm%>' ;separator=", "%>)
    local
      <%typedIdents(locals)%>
  <%matchCases |> (mexps, locals, statements) =>
  <<
    
    case ( <%mexps |> it => mmMatchingExp(it) ;separator=",\n"; anchor%> )
    <%if locals then <<
      local   
        <%typedIdents(locals)%>
    >>%>
    <%if statements then <<
      equation
        <%statements |> it => '<%mmExp(it, "=")%>;' ;separator="\n"%>
    >>%>
      then <%match outArgs
            case {(nm,_)} then nm
            case oas then '(<%oas |> (nm,_)=> nm ;separator=", "%>)'
           %>;       
  >>;separator="\n"%>
  end matchcontinue;
>>
end mmMatchFunBody;

template pathIdent(PathIdent path) ::= 
  match path
  case IDENT(__)      then ident
  case PATH_IDENT(__) then ident + "." + pathIdent(path) //'<%ident%>.<%pathIdent(path)%>'
end pathIdent;

template mmPublic(Boolean it) ::= 
  match it
  case true then "public" 
  case _    then "protected"
end mmPublic;


template typedIdents(TypedIdents decls) ::=
(decls |> (id,ts) => 
   '<%typeSig(ts)%> <%id%>;' 
   ;separator="\n" 
)
end typedIdents;

template typedIdentsEx(TypedIdents decls, String typePrfx, String idPrfx) ::= 
(decls |> (id,ty)=> 
  '<%typePrfx%> <%typeSig(ty)%> <%idPrfx%><%id%>;'
  ;separator="\n"
)
end typedIdentsEx;

template typeSig(TypeSignature it) ::=
  match it
  case LIST_TYPE(__)   then 'list<<%typeSig(ofType)%>>'
  case ARRAY_TYPE(__)  then '<%typeSig(ofType)%>[:]'
  case OPTION_TYPE(__) then 'Option<<%typeSig(ofType)%>>'
  case TUPLE_TYPE(__)  then 'tuple<<%ofTypes |> it => typeSig(it);separator=", "%>>'
  case NAMED_TYPE(__)  then pathIdent(name)

  case STRING_TYPE(__)       then "String"
  case TEXT_TYPE(__)         then "Tpl.Text"
  case STRING_TOKEN_TYPE(__) then "Tpl.StringToken"
  case INTEGER_TYPE(__)      then "Integer"
  case REAL_TYPE(__)         then "Real"
  case BOOLEAN_TYPE(__)      then "Boolean"
  case UNRESOLVED_TYPE(__)   then '#type? <%reason%> ?#'

end typeSig;

template mmStringTokenConstant(StringToken it) ::=
  match it
  case ST_NEW_LINE(__) then "Tpl.ST_NEW_LINE()"
  case ST_STRING(__)   then 'Tpl.ST_STRING("<%mmEscapeStringConst(value,true)%>")'
  case ST_LINE(__)     then 'Tpl.ST_LINE("<%mmEscapeStringConst(line,true)%>")'
  case ST_STRING_LIST(__)  then 
    (<<
    Tpl.ST_STRING_LIST({
        <%strList |> it => '"<%mmEscapeStringConst(it,true)%>"' ;separator=",\n"%>
    }, <%lastHasNewLine%>)
    >>; anchor) // perhaps this should be automatic ?
end mmStringTokenConstant;

template mmEscapeStringConst(String internalValue, Boolean escapeNewLine) ::= 
  stringListStringChar(internalValue) |> it=>
    match it
    case "\\"  then <<\\>>
    case "'"   then <<\'>>
    case "\""  then <<\">>
    //case \a  then <<\a>>
    //case \b  then <<\b>>
    //case \f  then <<\f>>
    case "\n"  then if escapeNewLine then <<\n>> else "\n"
    //case \r  then <<\r>>
    case "\t"  then <<\t>>
    //case "\v"  then <<\v>>
    case c   then c 
end mmEscapeStringConst;

template mmExp(MMExp it, String assignStr) ::=
  match it
  case MM_ASSIGN(__)  then  
    <<
    <%match lhsArgs
     case {id} then id 
     case args then '(<%args;separator=", "%>)'
    %> <%assignStr%> <%mmExp(rhs, assignStr)%>
    >>
  case MM_FN_CALL(__)   then '<%pathIdent(fnName)%>(<%args |> it => mmExp(it,assignStr);separator=", "%>)'
  case MM_IDENT(__)     then pathIdent(ident)
  case MM_STR_TOKEN(__) then mmStringTokenConstant(value) 
  case MM_STRING(__)    then ('"<%mmEscapeStringConst(value,false)%>"' ; absIndent)
  case MM_LITERAL(__)   then value 
  // MM_MATCH won't appear here, it is caught in the mmMatchFunBody
end mmExp;

template mmMatchingExp(MatchingExp it) ::=
  match it
  case BIND_AS_MATCH(__) then '(<%bindIdent%> as <%mmMatchingExp(matchingExp)%>)'
  case BIND_MATCH(__)    then bindIdent
  case RECORD_MATCH(__)  then
    <<
    <%pathIdent(tagName)%>(<%fieldMatchings |> (field, mexp) =>
                            '<%field%> = <%mmMatchingExp(mexp)%>'
                         ;separator=", "%>)
    >>
  case SOME_MATCH(__)     then 'SOME(<%mmMatchingExp(value)%>)'
  case NONE_MATCH(__)     then "NONE"
  case TUPLE_MATCH(__)    then '(<%tupleArgs |> it => mmMatchingExp(it);separator=", "%>)'
  case LIST_MATCH(__)     then '{<%listElts |> it => mmMatchingExp(it);separator=", "%>}'
  case LIST_CONS_MATCH(__)  then  '<%mmMatchingExp(head)%> :: <%mmMatchingExp(rest)%>'
  case STRING_MATCH(__)   then '"<%mmEscapeStringConst(value,true)%>"'
  case LITERAL_MATCH(__)  then value
  case REST_MATCH(__)     then "_"
end mmMatchingExp;

// **** helper dumping functions (Susan unparser) ****

template mmStatements(list<MMExp> stmts) ::=
  (stmts |> it => '<%mmExp(it, "=")%>;' ;separator="\n")
end mmStatements;

template sTemplPackage(TemplPackage it) ::= 
  match it
  case TEMPL_PACKAGE(__) then 
	<<
    spackage <%pathIdent(name)%>
      <%astDefs |> AST_DEF(__) => 
      <<
      <%if isDefault then "default "%>absyn <%pathIdent(importPackage)%>
        <%types |> (id, tinfo) => sASTDefType(id, tinfo) ;separator="\n\n"%>
      end <%pathIdent(importPackage)%>;<%\n%>
      >> ;separator="\n" %>

    <%templateDefs |> (id, def) => sTemplateDef(def,id) ;separator="\n\n"%>
    end <%pathIdent(name)%>;
	>>
end sTemplPackage;

template sASTDefType(Ident id, TypeInfo info) ::=
  match info
  case TI_UNION_TYPE(__) then
	<<
    uniontype <%id%>
      <%recTags |> (rid, tids) => sRecordTypeDef(rid, tids) ;separator="\n"%>
    end <%id%>;
	>>
  case TI_RECORD_TYPE(__) then  sRecordTypeDef(id, fields)
  case TI_ALIAS_TYPE(__)  then  'type <%id%> = <%typeSig(aliasType)%>;'
  case TI_FUN_TYPE(__)    then
    <<
    function <%id%>
      <%inArgs |> (aid,ts)  => 'input <%typeSig(ts)%> <%aid%>;<%\n%>'%>
      <%outArgs |> (aid,ts) => 'output <%typeSig(ts)%> <%aid%>;<%\n%>'%>
    end <%id%>;
	>>
  case TI_CONST_TYPE(__) then 'constant <%typeSig(constType)%> <%id%>;'
end sASTDefType;

template sRecordTypeDef(Ident id, TypedIdents fields) ::= 
<<
record <%id%> <%if fields then <<<%"\n"%>
  <%fields |> (fid, ts) => '<%typeSig(ts)%> <%fid%>;<%\n%>'%>
>>
%>end <%id%>;
>>
end sRecordTypeDef;

template sTemplateDef(TemplateDef it, Ident templId) ::= 
	match it
	case STR_TOKEN_DEF(__) then '<%templId%> = <%sConstStringToken(value)%>'
/*
case TEMPLATE_DEF(__) then 
{
<%name%>(<%signature |> it => 
        case (tsign, arg) then '<%typeSignature(tsign)%> <%arg%>'
        ;separator=", " 
       %> <%lesc%><%resc%>= <%expression(exp, lesc, resc)%>
}
case CONST_DEF(__) then '<%name%> = <%constant(value)%>'
%>}
*/
end sTemplateDef;

template sConstStringToken(StringToken it) ::=
  match it
  case ST_NEW_LINE(__) then <<\n>>
  case ST_STRING(__)   then '"<%mmEscapeStringConst(value,true)%>"'
  case ST_LINE(__)     then '"<%mmEscapeStringConst(line,true)%>"'
  case ST_STRING_LIST(strList = sl) then 
  	if not canBeOnOneLine(sl) 
  	then ('"<%sl |> it => mmEscapeStringConst(it,false)%>"' ; absIndent) 
  	else if canBeEscapedUnquoted(sl) 
  	     then  sl |> it => mmEscapeStringConst(it,true)
  	     else  '"<%sl |> it => mmEscapeStringConst(it,true)%>"'
end sConstStringToken;

end TplCodegen;
