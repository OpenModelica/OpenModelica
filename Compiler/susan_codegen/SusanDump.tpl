
pathIdent(PathIdent path) <>= 
  case IDENT      then ident
  case PATH_IDENT then ident & '.' & pathIdent(path) //"<ident>.<pathIdent(path)>"


templPackage(TemplPackage) <>= 
	case TEMPL_PACKAGE then 
	<<
spackage <pathIdent(name)>
<astDefs of AST_DEF : <<
  <if isDefault then 'default '>absyn <pathIdent(importPackage)>
    <types of (id, tinfo) : astDefType(id, tinfo) \n\n>
  end <pathIdent(importPackage)>;<\n>
>> \n >

<templateDefs : templateDef()\n\n>
end <pathIdent(name)>;
	>>


astDefType(Ident id, TypeInfo info) <>=	
  match info
	case TI_UNION_TYPE then
	<<
uniontype <id>
  <recTags of (rid, tids) : recordTypeDef(rid, tids) \n>
end <id>;
	>>
	case TI_RECORD_TYPE then  recordTypeDef(id, fields)
	case TI_ALIAS_TYPE  then  "type <id> = <typeSig(aliasType)>;"
	case TI_FUN_TYPE    then
	<<
function <id>
  <inArgs of (aid,ts)  : "input <typeSig(ts)> <aid>;<\n>">
  <outArgs of (aid,ts) : "output <typeSig(ts)> <aid>;<\n>">
end <id>;
	>>
	case TI_CONST_TYPE then "constant <typeSig(constType)> <id>;"


recordTypeDef(Ident id, TypedIdents fields) <>= 
<<
record <id> <if fields then 
  <<<\n>
  <fields of (fid, ts) : "<typeSig(ts)> <fid>;<\n>">
  >>
>end <id>;
>>




templateDef(TemplateDef, Ident templId) <>= 
	case STR_TOKEN_DEF then
case TEMPLATE_DEF then 
{
<name>(<signature : 
        case (tsign, arg) then "<typeSignature(tsign)> <arg>"
        ', ' 
       > <lesc><resc>= <expression(exp, lesc, resc)>
}
case CONST_DEF then "<name> = <constant(value)>"
>}


typeSignature(TypeSignature) $$=
<<$
case LIST_TYPE   then "list<$typeSignature(ofType)$>"
case OPTION_TYPE then "Option<$typeSignature(ofType)$>"
case TUPLE_TYPE  then "tuple<$ofTypes : typeSignature(ofType)', '$>"
case NAMED_TYPE  then pathIdent(name)
$>>


pathIdent(PathIdent) <>= "<path : {<it>.}><ident>"

constant(Constant) <>= 
{<
  case STRING_CONST then escapeStringConst(value)
  case QUOTED_CONST then 
{
%<lesc>
<it : it \n; empty=''; noindent /* noindent only to ensure semantics of % */>
<resc>%"
}
case INTEGER_CONST then value  // auto intString(value)
case BOOL_CONST(value = true)  then 'true' 
case BOOL_CONST(value = false) then 'false'
case EMPTY_LIST    then '[]' 
>
}


escapeStringConst(String internalValue) <>= 
{<
stringListStringChar(internalValue) :
  case \\  then %(\\)%
  case \'  then %(\')%
  case \a  then %(\a)%
  case \b  then %(\b)%
  case \f  then %(\f)%
  case \n  then %(\n)%
  case \r  then %(\r)%
  case \t  then %(\t)%
  case \v  then %(\v)%
  case _   then it
>}

expression(Expression, String lesc, String resc) <>=
{<
case CONSTANT    then constant(value)
case TEMPLATE    then "<templItems : templItem(it, lesc, resc, lquote)>"
case BOUND_VALUE then pathIdent(boundValue)
case FN_CALL     then functionCall(fnCall, lesc, resc)
>}


templItem(TemplItem, String lesc, String resc, String templQuote) <>=
{<
case NEW_LINE    then \n
case STRING      then escapeTemplString(string, lesc, resc, templQuote)    
case INDENTATION then strIndent
case LIST_MAP    then
{
<lesc><listMapExp(listMapExp)
      > <match separator 
         case SOME(sep) then expression(sep, lesc, resc)
        ><escapedExpOptions(options, lesc, resc)><resc>
}
case ESCAPED_EXP     then "<lesc><templateExp(exp)> <escapedExpOptions(options, lesc, resc)><resc>"
case NON_TEMPL_CALL  then "<lesc><functionCall(fnCall, lesc, resc)><resc>"
case STREAM_CREATE   then "<lesc># <name> = <expression(exp, lesc, resc)> #<resc>" 
case STREAM_ADD      then "<lesc># <name> += <expression(exp, lesc, resc)> #<resc>" 
>}

// we cannot test equality against a parameter --> strict(er) model-view separation
// so we need to make it as fixed (and expected) view on the model ...
// possible and maybe even more elegant solution would be to preserve
// the original input string ... but for the sake of example
escapeTemplString(String string, String lesc, String resc, String templQuote) <>=
{<
stringListStringChar(string) :
  case \\   then %(\\)%
  case '<'  then {<if lesc = '<' then %(\<)% else it>}
  case '>'  then {<if lesc = '<' then %(\>)% else it>} 
  case '$'  then {<if lesc = '$' then %(\$)% else it>} 
  case '}'  then {<if templQuote = '{' then %(\})% else it>} 
  case '"'  then {<if templQuote = '"' then %(\")% else it>} 
  case _    then it
>}

escapedExpOptions(list<tuple<String, Expression>> options, String lesc, String resc) <>=
{< 
options :
  case (optName, value) then "; <optName> = <expression(value, lesc, resc)>"
>} 

functionCall(FunctionCall, String lesc, String resc) <>= // quite redundant, could be made only a record ... for future ? 
{<
case FUNCTION_CALL then "<pathIdent(name)>(<args of exp: expression(exp, lesc, resc)', '>)"
>}


listMapExp(ListMapExp, String lesc, String resc) <>= 
{<
case LIST_MAP_EXP then
{
<listBindings :
   case (listVal, BIND_MATCH(bindIdent = 'it'))  then listValue(listVal)
   case (listVal, me) then "<listValue(listVal)> of <matchingExp(me)>"
   ', '
><match templExp
  case SOME(te) then " : <templateExp(te)>"
 >
}
>}


listValue(ListValue, String lesc, String resc) <>=
{<
case LIST_BOUND_VALUE then pathIdent(boundValue)
case LIST_FN_CALL     then functionCall(fnCall, lesc, resc)
case LIST_MAP_VALUE   then listMapExp(listMapExp)
case LIST_CONSTR      then "[ <scalars : expression(it, lesc, resc)' ,'> ]"
case LIST_CONCAT      then "[ <lists   : listValue(it, lesc, resc)' ,'> ]"
>}
 

templateExp(TemplateExp, String lesc, String resc) <>=
{<
case EXPRESSION then expression(exp, lesc, resc) 
case cond as CONDITION then
{
if <match rhsValue
    case NONE then "<if cond.isNot then 'not '><expression(lhsExp, lesc, resc)>"
    case SOME(const) then {<expression(lhsExp, lesc, resc)
                           > <if cond.isNot 
                              then '<>' 
                              else '=='
                             > <expression(rhsExp, lesc, resc)>}
   >
then <expression(trueBranch, lesc, resc)
     ><match elseBranch
       case SOME(eb) then "<\n>else <expression(eb, lesc, resc)>"
      >
}
case MATCH then
{
<match matchExp
 case BOUND_VALUE(boundValue = PATH_IDENT(ident = 'it', path = [])) then ''
 case exp then "match <expression(exp, lesc, resc)><\n>"
><matchCases : 
  case (me, exp) then "case <matchingExp(me)> then <expression(exp, lesc, resc)>"
  \n
 >
}
>}

 
matchingExp(MatchingExp) <>=
{<
case RECORD_MATCH then
{
<match bindIdent
 case SOME(bid) then "<bid> as "
><pathIdent(tagName)
 ><if fieldMatchings <> [] then
      <<(<fieldMatchings :
          case (field, mexp) then "<field> = <matchingExp(mexp)>"
          ', '
         >)>>
  >
}
case SOME_MATCH  then "SOME(<matchingExp(value)>)"
case NONE_MATCH  then 'NONE'
case TUPLE_MATCH then "(<tupleArgs : matchingExp()', '>)"
case LIST_MATCH  then "[ <bindIdent> ]"
case CONST_MATCH then constant(value)
case REST_MATCH  then '_'
case BIND_MATCH  then bindIdent
>}
