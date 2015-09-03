%{
import DiffAlgorithm;
%}

%x c_comment
%x c_linecomment
%x c_string

whitespace1  [ \t]+
whitespace2  \n
letter       [a-zA-Z]
wild         [_]
digit        [0-9]
digits       {digit}+
ident        (({letter}|{wild})|['\'']({letter}|{digit}|[-*+/^=])*['\''])({letter}|{digit}|{wild})*
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
"algorithm" return T_ALGORITHM;
"and" return T_AND;
"annotation" return T_ANNOTATION;
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
"end" return T_END;
"enumeration" return ENUMERATION;
"equation" return EQUATION;
"encapsulated" return ENCAPSULATED;
"expandable" return EXPANDABLE;
"extends" return EXTENDS;
"constrainedby" return CONSTRAINEDBY;
"external" return EXTERNAL;
"false" return T_FALSE;
"final" return FINAL;
"flow" return FLOW;
"for" return FOR;
"function" return FUNCTION;
"if" return IF;
"import" return IMPORT;
"in" return T_IN;
"initial" return T_INITIAL;
"inner" return INNER;
"input" return T_INPUT;
"loop" return LOOP;
"model" return MODEL;
"not" return T_NOT;
"outer" return T_OUTER;
"operator" return OPERATOR;
"overload" return OVERLOAD;
"or" return T_OR;
"output" return T_OUTPUT;
"package" return T_PACKAGE;
"parameter" return PARAMETER;
"partial" return PARTIAL;
"protected" return PROTECTED;
"public" return PUBLIC;
"record" return RECORD;
"redeclare" return REDECLARE;
"replaceable" return REPLACEABLE;
"results" return RESULTS;
"then" return THEN;
"true" return T_TRUE;
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
"optimization" return T_OPTIMIZATION;

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

{ident}      return IDENT;
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
    case TokenId.IDENT then tokenContent(ta)==tokenContent(tb);
    case TokenId.UNSIGNED_INTEGER then tokenContent(ta)==tokenContent(tb);
    case TokenId.UNSIGNED_REAL
      then stringReal(tokenContent(ta))==stringReal(tokenContent(tb));
    case TokenId.BLOCK_COMMENT
      then valueEq(blockCommentCanonical(ta),blockCommentCanonical(tb));
    case TokenId.LINE_COMMENT then tokenContent(ta)==tokenContent(tb);
    case TokenId.STRING then tokenContent(ta)==tokenContent(tb);
    case TokenId.WHITESPACE then true; // tokenContent(ta)==tokenContent(tb);
    else true;
  end match;
end modelicaDiffTokenEq;

function modelicaDiffTokenWhitespace
  import LexerModelicaDiff.{Token,TokenId,tokenContent};
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
        Token t,t1,t2;
      // Do not delete whitespace in-between two tokens
      case (e1 as (Diff.Equal,_))::(Diff.Delete,t1 as TOKEN(id=TokenId.NEWLINE))::(Diff.Delete,t2 as TOKEN(id=TokenId.WHITESPACE))::(e2 as (Diff.Equal,_))::rest then (false,e1::(Diff.Equal,t1)::(Diff.Equal,t2)::e2::rest,tmp);
      case (e1 as (Diff.Equal,_))::(Diff.Delete,t as TOKEN(id=TokenId.WHITESPACE))::(e2 as (Diff.Equal,_))::rest then (false,e1::(Diff.Equal,t)::e2::rest,tmp);

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

annotation(__OpenModelica_Interface="backend");
