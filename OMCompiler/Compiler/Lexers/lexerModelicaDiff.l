%{
import DiffAlgorithm;
protected
import Error;
import StringUtil;
public
%}

%x c_comment
%x c_linecomment
%x c_string

whitespace1  [ \t]+
whitespace2  \r?\n
letter       [a-zA-Z]
wild         [_]
nondigit     [_a-zA-Z]
qchar        []_a-zA-Z0-9!#$%&()*+,./:;<>=?@[^{}| \-]
sescape      "\\"['"=abfnryv\\]
digit        [0-9]
digitnondigit [_a-zA-Z0-9]
digits       {digit}+
exponent     ([e]|[E])([+]|[-])?{digits}
real         {digits}[\.]({digits})?({exponent})?
real2        {digits}{exponent}
real3        [\.]{digits}({exponent})?
initialequation   "initial"{whitespace}"equation"
initialalgorithm  "initial"{whitespace}"algorithm"

/* Lex style lexical syntax of tokens in the MODELICA language
 * Including whitespace and comments as tokens in order to create textual
 * diffs of Modelica code.
 */

%%
{whitespace1} return WHITESPACE;
{whitespace2} return NEWLINE;
{real}      return UNSIGNED_REAL;
{real2}     return UNSIGNED_REAL;
{real3}     return UNSIGNED_REAL;
"algorithm" return ALGORITHM;
"and" return AND;
"annotation" return ANNOTATION;
"block" return BLOCK;
"class" return CLASS;
"connect" return CONNECT;
"connector" return CONNECTOR;
"constant" return CONSTANT;
"discrete" return DISCRETE;
"der" return DER;
"defineunit" return DEFINEUNIT;
"each" return EACH;
"else" return ELSE;
"elseif" return ELSEIF;
"elsewhen" return ELSEWHEN;
"end" return END;
"enumeration" return ENUMERATION;
"equation" return EQUATION;
"encapsulated" return ENCAPSULATED;
"expandable" return EXPANDABLE;
"extends" return EXTENDS;
"constrainedby" return CONSTRAINEDBY;
"external" return EXTERNAL;
"false" return FALSE;
"final" return FINAL;
"flow" return FLOW;
"for" return FOR;
"function" return FUNCTION;
"if" return IF;
"import" return IMPORT;
"in" return IN;
"initial" return INITIAL;
"inner" return INNER;
"input" return INPUT;
"loop" return LOOP;
"model" return MODEL;
"not" return NOT;
"outer" return OUTER;
"operator" return OPERATOR;
"overload" return OVERLOAD;
"or" return OR;
"output" return OUTPUT;
"package" return PACKAGE;
"parameter" return PARAMETER;
"partial" return PARTIAL;
"protected" return PROTECTED;
"public" return PUBLIC;
"record" return RECORD;
"redeclare" return REDECLARE;
"replaceable" return REPLACEABLE;
"results" return RESULTS;
"then" return THEN;
"true" return TRUE;
"type" return TYPE;
"when" return WHEN;
"while" return WHILE;
"within" return WITHIN;
"return" return RETURN;
"break" return BREAK;

"(" return LPAR;
")" return RPAR;
"[" return LBRACK;
"]" return RBRACK;
"{" return LBRACE;
"}" return RBRACE;
"==" return EQEQ;
"=" return EQUALS;
"," return COMMA;
":=" return ASSIGN;
"::" return COLONCOLON;
":" return COLON;
";" return SEMICOLON;

"pure" return PURE;
"impure" return IMPURE;
"optimization" return OPTIMIZATION;

".+" return PLUS_EW;
".-" return MINUS_EW;
".*" return STAR_EW;
"./" return SLASH_EW;
".^" return POWER_EW;

"*"  return STAR;
"-"  return MINUS;
"+"  return PLUS;
"<=" return LESSEQ;
"<>"  return LESSGT;
"<"  return LESS;
">"  return GREATER;
">="  return GREATEREQ;

"^" return POWER;
"/" return SLASH;

"subtypeof" return SUBTYPEOF;

"stream" return STREAM;

"\." return DOT;

{nondigit}{digitnondigit}* return IDENT;

"'"({qchar}|{sescape})+"'"  return IDENT;

{digits}     return UNSIGNED_INTEGER;

"\""       {
    BEGIN(c_string) keepBuffer;
             }
<c_string>
{
    "\\"+"\"" { keepBuffer; }
    "\\"+"\\" { keepBuffer; }
    "\""    { BEGIN(INITIAL) return STRING; }
    [^\n]   {keepBuffer; }
    \n       {keepBuffer; }
}

"/\*"      {
    BEGIN(c_comment) keepBuffer;
             }
<c_comment>
{
    "\*/"    { BEGIN(INITIAL); return BLOCK_COMMENT; }
    [^\n]    {keepBuffer;}
    \n       {keepBuffer;}
    <<EOF>>  {
         yyerror("Unterminated comment");
         yyterminate();
       }
}

"//"       {
    BEGIN(c_linecomment) keepBuffer;
             }

<c_linecomment>
{
    \n    { BEGIN(INITIAL); return LINE_COMMENT; }
    [^\n] { keepBuffer; };
}

%%
public

function modelicaDiffTokenEq
  import LexerModelicaDiff.{Token,TokenId,tokenContent};
  input Token ta,tb;
  output Boolean b;
protected
  LexerModelicaDiff.TokenId ida,idb;
algorithm
  LexerModelicaDiff.TOKEN(id=ida) := ta;
  LexerModelicaDiff.TOKEN(id=idb) := tb;
  if ida <> idb then
    b := false;
    return;
  end if;
  b := match ida
    case TokenId.IDENT then tokenContentEq(ta,tb);
    case TokenId.UNSIGNED_INTEGER then tokenContentEq(ta,tb);
    case TokenId.UNSIGNED_REAL
      then stringReal(tokenContent(ta))==stringReal(tokenContent(tb));
    case TokenId.BLOCK_COMMENT
      then valueEq(blockCommentCanonical(ta),blockCommentCanonical(tb));
    case TokenId.LINE_COMMENT then tokenContentEq(ta,tb);
    case TokenId.STRING
      algorithm
        b := tokenContentEq(ta,tb);
        if not b then
          b := if 0<>StringUtil.findChar(tokenContent(ta), stringCharInt("\n")) then valueEq(blockCommentCanonical(ta),blockCommentCanonical(tb)) else false;
        end if;
      then b;
    case TokenId.WHITESPACE then true; // tokenContent(ta)==tokenContent(tb);
    else true;
  end match;
end modelicaDiffTokenEq;

function modelicaDiffTokenWhitespace
  import LexerModelicaDiff.{Token,TokenId};
  input Token t;
  output Boolean b;
protected
  LexerModelicaDiff.TokenId id;
algorithm
  LexerModelicaDiff.TOKEN(id=id) := t;
  b := id==TokenId.BLOCK_COMMENT or id==TokenId.LINE_COMMENT or id==TokenId.WHITESPACE or id==TokenId.NEWLINE;
end modelicaDiffTokenWhitespace;

function filterModelicaDiff
  import LexerModelicaDiff.{Token,TokenId,tokenContent,TOKEN};
  import DiffAlgorithm.Diff;
  input list<tuple<Diff, list<Token>>> diffs;
  input Boolean removeWhitespace=true;
  output list<tuple<Diff, list<Token>>> odiffs;
protected
  list<String> addedLineComments, removedLineComments;
  list<list<String>> addedBlockComments, removedBlockComments;
  list<tuple<Diff, Token>> simpleDiff, tmp, rest;
  Boolean lastIsNewline;
  Integer depth;
algorithm
  // No changes are easy
  _ := match diffs
    case {(Diff.Equal,_)}
      algorithm
        odiffs := diffs;
        return;
      then ();
    else ();
  end match;

  odiffs := listReverse(match e
    local
      list<Token> ts;
    case (Diff.Delete,ts as {TOKEN(id=TokenId.WHITESPACE)}) then (Diff.Equal,ts);
    case (Diff.Delete,ts as {TOKEN(id=TokenId.NEWLINE)}) then (Diff.Equal,ts);
    else e;
    end match

    for e guard(
    match e
      // Single addition of whitespace, not followed by another addition
      // is suspected garbage added by OMC.
      case (Diff.Add,{TOKEN(id=TokenId.WHITESPACE)}) then not removeWhitespace;
      case (Diff.Add,{TOKEN(id=TokenId.NEWLINE)}) then not removeWhitespace;
      case (_,{}) then false;
      else true;
    end match
  ) in diffs);

  // Convert from multiple additions per item to one per item
  // Costs more memory, but is easier to transform
  simpleDiff := listAppend(
    match e
      local
        list<Token> ts;
      case (Diff.Add,ts) then list((Diff.Add,t) for t in ts);
      case (Diff.Equal,ts) then list((Diff.Equal,t) for t in ts);
      case (Diff.Delete,ts) then list((Diff.Delete,t) for t in ts);
    end match
  for e in odiffs);

  tmp := {};
  lastIsNewline := false;
  depth := 2;
  while not listEmpty(simpleDiff) loop
    (lastIsNewline,simpleDiff,tmp) := match simpleDiff
      local
        tuple<Diff, Token> e,e1,e2;
        Token t,t1,t2,tk3,tk4,tk5;
        TokenId t3,t4,t5;
        Diff d1,d2,d3,d4,d5;
      // Do not delete whitespace in-between two tokens
      case (e1 as (Diff.Equal,_))::(Diff.Delete,t1 as TOKEN(id=TokenId.NEWLINE))::(Diff.Delete,t2 as TOKEN(id=TokenId.WHITESPACE))::(e2 as (Diff.Equal,_))::rest then (false,e1::(Diff.Equal,t1)::(Diff.Equal,t2)::e2::rest,tmp);
      case (e1 as (Diff.Equal,_))::(Diff.Delete,t as TOKEN(id=TokenId.WHITESPACE))::(e2 as (Diff.Equal,_))::rest then (false,e1::(Diff.Equal,t)::e2::rest,tmp);
      case (e1 as (Diff.Equal,TOKEN(id=t3)))::rest
        guard t3<>TokenId.WHITESPACE and t3<>TokenId.NEWLINE and deleteWhitespaceFollowedByEqualNonWhitespace(rest)
        algorithm
          (_,rest) := deleteWhitespaceFollowedByEqualNonWhitespace(rest);
        then (false,e1::rest,tmp);

      // Do not delete+add the same token just because there is whitespace added
      case (d1,t1)::(Diff.Add,TOKEN(id=t3))::(Diff.Add,TOKEN(id=t4))::(Diff.Add,TOKEN(id=t5))::(d2,t2)::rest
        guard ((d1==Diff.Add and d2==Diff.Delete) or (d2==Diff.Add and d1==Diff.Delete)) and modelicaDiffTokenEq(t1,t2)
               and (t3==TokenId.NEWLINE or t3 == TokenId.WHITESPACE) and (t4==TokenId.NEWLINE or t4 == TokenId.WHITESPACE) and (t5==TokenId.NEWLINE or t5 == TokenId.WHITESPACE)
        then (false,(Diff.Equal,t1)::rest,tmp);
      case (d1,t1)::(Diff.Add,TOKEN(id=t3))::(Diff.Add,TOKEN(id=t4))::(d2,t2)::rest
        guard ((d1==Diff.Add and d2==Diff.Delete) or (d2==Diff.Add and d1==Diff.Delete)) and modelicaDiffTokenEq(t1,t2)
               and (t3==TokenId.NEWLINE or t3 == TokenId.WHITESPACE) and (t4==TokenId.NEWLINE or t4 == TokenId.WHITESPACE)
        then (false,(Diff.Equal,t1)::rest,tmp);
      case (d1,t1)::(Diff.Add,TOKEN(id=t3))::(d2,t2)::rest
        guard ((d1==Diff.Add and d2==Diff.Delete) or (d2==Diff.Add and d1==Diff.Delete)) and modelicaDiffTokenEq(t1,t2)
               and (t3==TokenId.NEWLINE or t3 == TokenId.WHITESPACE)
        then (false,(Diff.Equal,t1)::rest,tmp);

      // Odd case of Delete token + equals whitespace + Add token again... Do Equal token + equal whitespace
      case (d1,t1)::(d3,tk3 as TOKEN(id=t3))::(d4,tk4 as TOKEN(id=t4))::(d5,tk5 as TOKEN(id=t5))::(d2,t2)::rest
        guard ((d1==Diff.Add and d2==Diff.Delete) or (d2==Diff.Add and d1==Diff.Delete)) and modelicaDiffTokenEq(t1,t2)
               and (d3==Diff.Equal or d3==Diff.Delete) and (d4==Diff.Equal or d4==Diff.Delete) and (d5==Diff.Equal or d5==Diff.Delete)
               and (t3==TokenId.NEWLINE or t3 == TokenId.WHITESPACE) and (t4==TokenId.NEWLINE or t4 == TokenId.WHITESPACE) and (t5==TokenId.NEWLINE or t5 == TokenId.WHITESPACE)
        then (false,(Diff.Equal,t1)::(Diff.Equal,tk3)::(Diff.Equal,tk4)::(Diff.Equal,tk5)::rest,tmp);
      case (d1,t1)::(d3,tk3 as TOKEN(id=t3))::(d4,tk4 as TOKEN(id=t4))::(d2,t2)::rest
        guard ((d1==Diff.Add and d2==Diff.Delete) or (d2==Diff.Add and d1==Diff.Delete)) and modelicaDiffTokenEq(t1,t2)
               and (d3==Diff.Equal or d3==Diff.Delete) and (d4==Diff.Equal or d4==Diff.Delete)
               and (t3==TokenId.NEWLINE or t3 == TokenId.WHITESPACE) and (t4==TokenId.NEWLINE or t4 == TokenId.WHITESPACE)
        then (false,(Diff.Equal,t1)::(Diff.Equal,tk3)::(Diff.Equal,tk4)::rest,tmp);
      case (d1,t1)::(d3,tk3 as TOKEN(id=t3))::(d2,t2)::rest
        guard ((d1==Diff.Add and d2==Diff.Delete) or (d2==Diff.Add and d1==Diff.Delete)) and modelicaDiffTokenEq(t1,t2)
               and (d3==Diff.Equal or d3==Diff.Delete)
               and (t3==TokenId.NEWLINE or t3 == TokenId.WHITESPACE)
        then (false,(Diff.Equal,t1)::(Diff.Equal,tk3)::rest,tmp);

      case (Diff.Add,TOKEN(id=TokenId.NEWLINE))::(Diff.Add,TOKEN(id=TokenId.WHITESPACE))::(rest as (_,TOKEN(id=TokenId.NEWLINE))::_)
        then (false,rest,tmp);
      case (Diff.Add,TOKEN(id=TokenId.NEWLINE))::(rest as (_,TOKEN(id=TokenId.NEWLINE))::_)
        then (false,rest,tmp);
      case (e as (_,TOKEN(id=TokenId.NEWLINE)))::(Diff.Add,TOKEN(id=TokenId.NEWLINE))::rest
        then (false,e::rest,tmp);
      case (e as (_,TOKEN(id=TokenId.NEWLINE)))::rest then (true,rest,e::tmp);
      case (Diff.Add,TOKEN(id=TokenId.WHITESPACE))::(e as (Diff.Add,t))::rest guard lastIsNewline
        then (false,rest,e::
          (Diff.Add,TOKEN("WHITESPACE",TokenId.WHITESPACE,sum(" " for i in 1:depth),1,depth,0,0,0,0))
          ::tmp);
      case (Diff.Add,TOKEN(id=TokenId.WHITESPACE))::(rest as (_,TOKEN(id=TokenId.NEWLINE))::_) guard lastIsNewline
        then (true,rest,tmp);
      case (e as (_,t as TOKEN(id=TokenId.WHITESPACE)))::rest guard lastIsNewline
        algorithm
          TOKEN(length=depth) := t;
        then (false,rest,e::tmp);
      case e::rest then (false,rest,e::tmp);
    end match;
  end while;
  simpleDiff := listReverse(tmp);

  addedLineComments := list(tokenContent(tuple22(e)) for e guard Diff.Add==tuple21(e) and isLineComment(tuple22(e)) in simpleDiff);
  removedLineComments := list(tokenContent(tuple22(e)) for e guard Diff.Delete==tuple21(e) and isLineComment(tuple22(e)) in simpleDiff);

  addedBlockComments := list(blockCommentCanonical(tuple22(e)) for e guard Diff.Add==tuple21(e) and isBlockComment(tuple22(e)) in simpleDiff);
  removedBlockComments := list(blockCommentCanonical(tuple22(e)) for e guard Diff.Delete==tuple21(e) and isBlockComment(tuple22(e)) in simpleDiff);

  simpleDiff := list(
    match e
      local
        Token t;
      case (Diff.Delete,t as TOKEN(id=TokenId.LINE_COMMENT)) then (if listMember(tokenContent(t), addedLineComments) then (Diff.Equal,t) else e);
      case (Diff.Delete,t as TOKEN(id=TokenId.BLOCK_COMMENT)) then (if listMember(blockCommentCanonical(t), addedBlockComments) then (Diff.Equal,t) else e);
      else e;
    end match
    for e guard(
    match e
      local
        Token t;
      case (Diff.Add,t as TOKEN(id=TokenId.LINE_COMMENT)) then not listMember(tokenContent(t), removedLineComments);
      case (Diff.Add,t as TOKEN(id=TokenId.BLOCK_COMMENT)) then not listMember(blockCommentCanonical(t), removedBlockComments);
      else true;
    end match
  ) in simpleDiff);

  odiffs := list(
    match e
      local
        Diff d;
        Token t;
      case (d,t) then (d,{t});
    end match
    for e in simpleDiff);
end filterModelicaDiff;

function isBlockComment
  import LexerModelicaDiff.{Token,TokenId,TOKEN};
  input Token t;
  output Boolean b;
algorithm
  b := match t case TOKEN(id=TokenId.BLOCK_COMMENT) then true; else false; end match;
end isBlockComment;

function isLineComment
  import LexerModelicaDiff.{Token,TokenId,TOKEN};
  input Token t;
  output Boolean b;
algorithm
  b := match t case TOKEN(id=TokenId.LINE_COMMENT) then true; else false; end match;
end isLineComment;

function tuple21<A,B>
  input tuple<A,B> t;
  output A a;
algorithm
  (a,_) := t;
end tuple21;

function tuple22<A,B>
  input tuple<A,B> t;
  output B b;
algorithm
  (_,b) := t;
end tuple22;

function blockCommentCanonical
  import LexerModelicaDiff.{Token,tokenContent};
  input Token t;
  output list<String> lines;
algorithm
  // Canonical representation trims whitespace from each line
  lines := list(System.trim(s) for s in System.strtok(tokenContent(t),"\n"));
end blockCommentCanonical;

function deleteWhitespaceFollowedByEqualNonWhitespace
  import LexerModelicaDiff.{Token,TokenId,TOKEN};
  import DiffAlgorithm.Diff;
  input list<tuple<Diff, Token>> inRest;
  output Boolean b;
  output list<tuple<Diff, Token>> result;
protected
  tuple<Diff, Token> head;
  Diff diff;
  Token t;
  TokenId id;
  list<tuple<Diff, Token>> rest;
  Boolean foundWS=false, foundNL=false;
algorithm
  rest := inRest;
  result := {};
  while not listEmpty(rest) loop
    (head as (diff,t as TOKEN(id=id))) := listHead(rest);
    if diff <> Diff.Delete then
      break;
    end if;
    rest := listRest(rest);
    if id==TokenId.WHITESPACE and not foundWS then
      foundWS := true;
      result := (Diff.Equal,t)::result;
    elseif id==TokenId.NEWLINE then
      foundNL := true;
      break;
    else
      result := head :: result;
    end if;
  end while;
  if (not foundWS) or foundNL then
    // If we find a newline, we probably went too far.
    b := false;
    result := {};
    return;
  end if;
  _ := match rest
    case (Diff.Equal,t)::_ then ();
    else
      algorithm
        b := false;
        result := {};
        return;
      then fail();
  end match;
  b := true;
  for i in result loop
    rest := i::rest;
  end for;
  result := rest;
end deleteWhitespaceFollowedByEqualNonWhitespace;

function reportErrors
  import LexerModelicaDiff.{Token,TokenId,tokenContent,tokenSourceInfo};
  input list<Token> tokens;
protected
  Integer i=0;
algorithm
  for t in tokens loop
    i := i+1;
    if i>10 then
      Error.addMessage(Error.SCANNER_ERROR_LIMIT, {});
    end if;
    Error.addSourceMessage(Error.SCANNER_ERROR, {tokenContent(t)}, tokenSourceInfo(t));
  end for;
  if not listEmpty(tokens) then
    fail();
  end if;
end reportErrors;

annotation(__OpenModelica_Interface="backend");
