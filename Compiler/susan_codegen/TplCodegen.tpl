
spackage TplCodegen
  
typeview "TplCodegenTV.mo"


template mmPackage(MMPackage) ::=  
  case MM_PACKAGE then
    <<
    package <%pathIdent(name)%>

    protected constant Tpl.Text emptyTxt = Tpl.MEM_TEXT({}, {}); 

    public import Tpl;

    <%mmDeclarations : mmDeclaration()\n%>
 
    end <%pathIdent(name)%>;
    >>
end mmPackage;

template mmDeclaration(MMDeclaration) ::=
  case MM_IMPORT(packageName = IDENT(ident = "Tpl")) then '' //ignore Tpl as it is always imported
  case MM_IMPORT(packageName = IDENT(ident = "builtin")) then '' //ignore Tpl as it is always imported
  case MM_IMPORT then
    <<
    <%mmPublic(isPublic)%> import <%pathIdent(packageName)%>;
    >>
  case MM_STR_TOKEN_DECL then
    <<
  
    <%mmPublic(isPublic)%> constant Tpl.StringToken <%name%> = <%mmStringTokenConstant(value)%>;
    >>
  case MM_LITERAL_DECL then
    <<
  
    <%mmPublic(isPublic)%> constant <%typeSig(litType)%> <%name%> = <%value%>;
    >>
  case mf as MM_FUN then
    <<
  
    <%mmPublic(isPublic)%> function <%name%>  
    <%match statements
     case {c as MM_MATCH} then //match function 
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
         <%sts : '<%mmExp(it, ":=")%>;' \n%>
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
   case outArgs  then <<(<%outArgs of (nm,_): 'out_<%nm%>' ", "%>)>>
  %> :=  
  matchcontinue(<%inArgs of (nm,_) : 'in_<%nm%>' ", "%>)
    local
      <%typedIdents(locals)%>
  <%matchCases of (mexps, locals, statements) :
  <<
    
    case ( <%mexps : mmMatchingExp() ",\n"; anchor%> )
    <%if locals then <<
      local   
        <%typedIdents(locals)%>
    >>%>
    <%if statements then <<
      equation
        <%statements : '<%mmExp(it, "=")%>;' \n%>
    >>%>
      then <%match outArgs
            case {(nm,_)} then nm
            case oas then '(<%oas of (nm,_): nm ", "%>)'
           %>;       
  >>\n%>
  end matchcontinue;
>>
end mmMatchFunBody;

template pathIdent(PathIdent path) ::= 
  case IDENT      then ident
  case PATH_IDENT then ident + "." + pathIdent(path) //'<%ident%>.<%pathIdent(path)%>'
end pathIdent;

template mmPublic(Boolean) ::= 
  case true then "public" 
  case _    then "protected"
end mmPublic;


template typedIdents(TypedIdents decls) ::=
(decls of (id,ts) : 
   '<%typeSig(ts)%> <%id%>;' 
   \n 
)
end typedIdents;

template typedIdentsEx(TypedIdents decls, String typePrfx, String idPrfx) ::= 
(decls of (id,ty): 
  '<%typePrfx%> <%typeSig(ty)%> <%idPrfx%><%id%>;'
  \n
)
end typedIdentsEx;

template typeSig(TypeSignature) ::=
  case LIST_TYPE   then 'list<<%typeSig(ofType)%>>'
  case ARRAY_TYPE  then '<%typeSig(ofType)%>[:]'
  case OPTION_TYPE then 'Option<<%typeSig(ofType)%>>'
  case TUPLE_TYPE  then 'tuple<<%ofTypes : typeSig()", "%>>'
  case NAMED_TYPE  then pathIdent(name)

  case STRING_TYPE       then "String"
  case TEXT_TYPE         then "Tpl.Text"
  case STRING_TOKEN_TYPE then "Tpl.StringToken"
  case INTEGER_TYPE      then "Integer"
  case REAL_TYPE         then "Real"
  case BOOLEAN_TYPE      then "Boolean"
  case UNRESOLVED_TYPE   then '#type? <%reason%> ?#'

end typeSig;

template mmStringTokenConstant(StringToken) ::=
  case ST_NEW_LINE then "Tpl.ST_NEW_LINE()"
  case ST_STRING   then 'Tpl.ST_STRING("<%mmEscapeStringConst(value,true)%>")'
  case ST_LINE     then 'Tpl.ST_LINE("<%mmEscapeStringConst(line,true)%>")'
  case ST_STRING_LIST  then 
    (<<
    Tpl.ST_STRING_LIST({
        <%strList : '"<%mmEscapeStringConst(it,true)%>"' ",\n"%>
    }, <%lastHasNewLine%>)
    >>; anchor) // perhaps this should be automatic ?
end mmStringTokenConstant;

template mmEscapeStringConst(String internalValue, Boolean escapeNewLine) ::= 
  stringListStringChar(internalValue) :
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

template mmExp(MMExp, String assignStr) ::=
  case MM_ASSIGN  then  
    <<
    <%match lhsArgs
     case {id} then id 
     case args then '(<%args", "%>)'
    %> <%assignStr%> <%mmExp(rhs, assignStr)%>
    >>
  case MM_FN_CALL   then '<%pathIdent(fnName)%>(<%args : mmExp(it,assignStr)", "%>)'
  case MM_IDENT     then pathIdent(ident)
  case MM_STR_TOKEN then mmStringTokenConstant(value) 
  case MM_STRING    then ('"<%mmEscapeStringConst(value,false)%>"' ; absIndent)
  case MM_LITERAL   then value 
  // MM_MATCH won't appear here, it is caught in the mmMatchFunBody
end mmExp;

template mmMatchingExp(MatchingExp) ::=
  case BIND_AS_MATCH then '(<%bindIdent%> as <%mmMatchingExp(matchingExp)%>)'
  case BIND_MATCH    then bindIdent
  case RECORD_MATCH  then
    <<
    <%pathIdent(tagName)%>(<%fieldMatchings of (field, mexp) :
                            '<%field%> = <%mmMatchingExp(mexp)%>'
                         ", "%>)
    >>
  case SOME_MATCH     then 'SOME(<%mmMatchingExp(value)%>)'
  case NONE_MATCH     then "NONE"
  case TUPLE_MATCH    then '(<%tupleArgs : mmMatchingExp()", "%>)'
  case LIST_MATCH     then '{<%listElts : mmMatchingExp()", "%>}'
  case LIST_CONS_MATCH  then  '<%mmMatchingExp(head)%> :: <%mmMatchingExp(rest)%>'
  case STRING_MATCH   then '"<%mmEscapeStringConst(value,true)%>"'
  case LITERAL_MATCH  then value
  case REST_MATCH     then "_"
end mmMatchingExp;

// **** helper dumping functions (Susan unparser) ****

template mmStatements(list<MMExp> stmts) ::=
  (stmts : '<%mmExp(it, "=")%>;' \n)
end mmStatements;

template sTemplPackage(TemplPackage) ::= 
  case TEMPL_PACKAGE then 
	<<
    spackage <%pathIdent(name)%>
      <%astDefs of AST_DEF : 
      <<
      <%if isDefault then "default "%>absyn <%pathIdent(importPackage)%>
        <%types of (id, tinfo) : sASTDefType(id, tinfo) \n\n%>
      end <%pathIdent(importPackage)%>;<%\n%>
      >> \n %>

    <%templateDefs of (id, def) : sTemplateDef(def,id) \n\n%>
    end <%pathIdent(name)%>;
	>>
end sTemplPackage;

template sASTDefType(Ident id, TypeInfo info) ::=
  match info
  case TI_UNION_TYPE then
	<<
    uniontype <%id%>
      <%recTags of (rid, tids) : sRecordTypeDef(rid, tids) \n%>
    end <%id%>;
	>>
  case TI_RECORD_TYPE then  sRecordTypeDef(id, fields)
  case TI_ALIAS_TYPE  then  'type <%id%> = <%typeSig(aliasType)%>;'
  case TI_FUN_TYPE    then
    <<
    function <%id%>
      <%inArgs of (aid,ts)  : 'input <%typeSig(ts)%> <%aid%>;<%\n%>'%>
      <%outArgs of (aid,ts) : 'output <%typeSig(ts)%> <%aid%>;<%\n%>'%>
    end <%id%>;
	>>
  case TI_CONST_TYPE then 'constant <%typeSig(constType)%> <%id%>;'
end sASTDefType;

template sRecordTypeDef(Ident id, TypedIdents fields) ::= 
<<
record <%id%> <%if fields then <<<%"\n"%>
  <%fields of (fid, ts) : '<%typeSig(ts)%> <%fid%>;<%\n%>'%>
>>
%>end <%id%>;
>>
end sRecordTypeDef;

template sTemplateDef(TemplateDef, Ident templId) ::= 
	case STR_TOKEN_DEF then '<%templId%> = <%sConstStringToken(value)%>'
/*
case TEMPLATE_DEF then 
{
<%name%>(<%signature : 
        case (tsign, arg) then '<%typeSignature(tsign)%> <%arg%>'
        ", " 
       %> <%lesc%><%resc%>= <%expression(exp, lesc, resc)%>
}
case CONST_DEF then '<%name%> = <%constant(value)%>'
%>}
*/
end sTemplateDef;

template sConstStringToken(StringToken) ::=
  case ST_NEW_LINE then <<\n>>
  case ST_STRING   then '"<%mmEscapeStringConst(value,true)%>"'
  case ST_LINE     then '"<%mmEscapeStringConst(line,true)%>"'
  case ST_STRING_LIST(strList = sl) then 
  	if not canBeOnOneLine(sl) 
  	then ('"<%sl : mmEscapeStringConst(it,false)%>"' ; absIndent) 
  	else if canBeEscapedUnquoted(sl) 
  	     then  sl : mmEscapeStringConst(it,true)
  	     else  '"<%sl : mmEscapeStringConst(it,true)%>"'
end sConstStringToken;

end TplCodegen;
