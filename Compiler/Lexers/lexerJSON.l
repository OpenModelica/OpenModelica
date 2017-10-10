
%{
/* grammar according to json.org */
protected
import Error;
import StringUtil;
public
%}

digit        [0-9]
digitnondigit [_a-zA-Z0-9]
digits       {digit}+
exponent     ([e]|[E])([+]|[-])?{digits}
real         {digits}[\.]{digits}({exponent})?
real2        {digits}{exponent}

HEX_DIGIT [0-9a-fA-F]

ESCAPEDCHAR \\["\\bfnrt/]
UNICODECHAR \\u{HEX_DIGIT}{HEX_DIGIT}{HEX_DIGIT}{HEX_DIGIT}
CHAR {UNESCAPEDCHAR}|{ESCAPEDCHAR}|{UNICODECHAR}
CHARS ([^"\\]|{ESCAPEDCHAR}|{UNICODECHAR})+
DOUBLE_QUOTE ["]
%%
{DOUBLE_QUOTE}{DOUBLE_QUOTE} return STRING;
{DOUBLE_QUOTE}{CHARS}{DOUBLE_QUOTE} return STRING;
{real} return NUMBER;
{real2} return NUMBER;
{digits} return INTEGER;
true return TRUE;
false return FALSE;
null return NULL;
"{" return OBJECTBEGIN;
"}" return OBJECTEND;

"[" return ARRAYBEGIN;

"]" return ARRAYEND;

"," return COMMA;
":" return COLON;

[ \t\n]+ /* whitespace */;

%%

annotation(__OpenModelica_Interface="util");
