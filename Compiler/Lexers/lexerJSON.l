
%{
/* grammar according to json.org */
protected
import Error;
import StringUtil;
public
%}

DIGITS [0-9]+
INT [0-9]|[1-9]{DIGITS}|-[0-9]|-[1-9]{DIGITS}
FRAC [.]{DIGITS}
EXP {E}{DIGITS}
E [eE][+-]?
NUMBER {INT}|{INT}{FRAC}|{INT}{EXP}|{INT}{FRAC}{EXP}


HEX_DIGIT [0-9a-fA-F]

UNESCAPEDCHAR [ -!#-\[\]-~]
ESCAPEDCHAR \\["\\bfnrt/]
UNICODECHAR \\u{HEX_DIGIT}{HEX_DIGIT}{HEX_DIGIT}{HEX_DIGIT}
CHAR {UNESCAPEDCHAR}|{ESCAPEDCHAR}|{UNICODECHAR}
CHARS {CHAR}+
%%
["]["] return STRING;
["]{CHARS}["] return STRING;
{NUMBER} return NUMBER;
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
