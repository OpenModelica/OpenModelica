%{

%}

%x c_comment
%x c_linecomment
%x c_string

whitespace   [ \t\n]+
letter       [a-zA-Z]
wild         [_]
digit        [0-9]
digits       {digit}+
ident        (({letter}|{wild})|['\'']({letter}|{digit}|[-*+/^=])*['\''])({letter}|{digit}|{wild})*
exponent     ([e]|[E])([+]|[-])?{digits}
real         {digits}[\.]({digits})?({exponent})?
real2        {digits}{exponent}
real3        [\.]{digits}({exponent})?
endif        "end"{whitespace}"if"
endfor        "end"{whitespace}"for"
endparfor     "end"{whitespace}"parfor"
endwhile        "end"{whitespace}"while"
endwhen        "end"{whitespace}"when"
endmatch        "end"{whitespace}"match"
endmatchcontinue  "end"{whitespace}"matchcontinue"
initialequation   "initial"{whitespace}"equation"
initialalgorithm  "initial"{whitespace}"algorithm"
endident          "end"{whitespace}{ident}

/* Lex style lexical syntax of tokens in the MODELICA language */




%%
{whitespace} ;
{real}      return UNSIGNED_REAL;
{real2}      return UNSIGNED_REAL;
{real3}     { sToken = LexerModelica.printBuffer(listReverse(buffer));
              Error.addSourceMessage(6000,{"Treating "+ sToken +" as 0"+sToken+". This is not standard Modelica and only done for compatibility with old code. Support for this feature may be removed in the future."},info);
              ;} return UNSIGNED_REAL; // throw a warning
{endif}     return ENDIF;
{endfor}     return ENDFOR;
{endparfor}   return ENDPARFOR;
{endwhile}     return ENDWHILE;
{endwhen}     return ENDWHEN;
{endmatchcontinue}   return ENDMATCHCONTINUE;
{endmatch}     return ENDMATCH;
{initialequation} return INITIALEQUATION;
{initialalgorithm} return INITIALALGORITHM;
{endident}   return ENDCLASS;
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
"unsigned_real" return UNSIGNED_REAL;
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

"$Code" return CODE;
"$TypeName" return CODE_NAME;
"$Exp" return CODE_EXP;
"$Var" return CODE_VAR;

"pure" return PURE;
"impure" return IMPURE;
"optimization" return T_OPTIMIZATION;
"parallel" return T_PARALLEL;
"parkernel"  return T_KERNEL;
"parfor"  return PARFOR;
"parlocal" return T_PARLOCAL;
"parglobal" return T_PARGLOBAL;

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

"as" return AS;
"case" return CASE;
"equality" return EQUALITY;
"failure" return FAILURE;
"guard" return GUARD;
"local" return LOCAL;
"match" return MATCH;
"matchcontinue" return MATCHCONTINUE;
"uniontype" return UNIONTYPE;
"__" return ALLWILD;
"_" return WILD;
"subtypeof" return SUBTYPEOF;
"\%" return MOD;

"stream" return STREAM;

"\." return DOT;

%"[\"][^\"]*[\"]" return STRING;

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
    BEGIN(c_comment);
             }
<c_comment>
{
    "\*/"    { BEGIN(INITIAL); }
    "/\*"    { yyerror("Suspicious comment"); }
    [^\n]    ;
    \n       ;
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
    \n    { BEGIN(INITIAL); }
    [^\n]  ;
}



%%
