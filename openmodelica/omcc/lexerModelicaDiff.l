%{

%}

%x c_comment
%x c_linecomment
%x c_string

whitespace1  [ \t]+
whitespace2  [ \t]*\n
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
{whitespace2} return WHITESPACE;
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
