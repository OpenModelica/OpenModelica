%{

%}

%x rml_comment
%x c_comment
%x c_linecomment

whitespace   [\t\n]+
letter       [a-zA-Z]
wild         [_]
digit        [0-9]
digits       {digit}+
quote        ['] 
ident        ({letter}|{wild})({letter}|{digit}|{wild}|{quote})*  
exponent     ([e]|[E])([+]|[-])?{digits}
real         {digits}[\.]({digits})?({exponent})? 
real2        {digits}{exponent}
real3        [\.]{digits}({exponent})?
alnum        {letter}|[_'0-9]
tyvar         "'"+{letter}{alnum}*
sescape        "\\\""

/* Lex style lexical syntax of tokens for RML */
        
  

%%

{whitespace} ;
{digits}     return ICON;
{real}       return RCON;
{real2}      return RCON;
"and"        return KW_AND;   
"as"  	     return KW_AS;
"axiom"      return KW_AXIOM;
"datatype"   return KW_DATATYPE;
"default"    return KW_DEFAULT ;
"end"        return KW_END;
"eqtype"     return KW_EQTYPE;
"fail"	     return KW_FAIL; 
"let"        return KW_LET;
"module"     return KW_MODULE;
"not"	     return KW_NOT ;
"of"         return KW_OF;
"relation"   return KW_RELATION;
"rule"       return KW_RULE;
"type"       return KW_TYPE;
"val"	     return KW_VAL;
"with"       return KW_WITH;
"withtype"   return KW_WITHTYPE;


"&"          return AMPERSAND;
"("  	     return LPAR;
")"          return RPAR;
"*"          return STAR;
","          return COMMA;
"-""-"+      return DASHES;
"\."         return DOT;
"::"         return COLONCOLON;
":"          return COLON;
"="          return EQ;
"=>"         return FATARROW;
"["          return LBRACK;
"]"          return RBRACK;
{wild}       return WILD;
"|"          return BAR;



"+"  		return ADD_INT;
"-"  		return SUB_INT;
"~"  		return NEG_INT;
"/"  		return DIV_INT;
"\%" 		return MOD_INT;
"==" 		return EQEQ_INT;
">="  		return GE_INT;
">"  		return GT_INT;
"<=" 		return LE_INT;
"<"  		return LT_INT;
"!=" 		return NOTEQ_INT;
"<>"  		return NOTEQ_INT;

"+."  		return ADD_REAL;
"-."  		return SUB_REAL; 
"~."  		return NEG_REAL;
"*."  		return MUL_REAL;
"/."  		return DIV_REAL;
"\%." 		return MOD_REAL;
"^."  		return POWER_REAL;
"==."  	    return EQEQ_REAL;
">=."  	    return GE_REAL;
">."  		return GT_REAL;
"<=." 		return LE_REAL;
"<."  		return LT_REAL;
"!=." 		return NOTEQ_REAL;
"<>."  	    return NOTEQ_REAL;


\"(\\.|[^\\"])*\" 	return SCON;

{ident}     		return IDENT;
{tyvar}      `       return TYVAR ;


 "(*"	     {
		BEGIN(rml_comment);
             }
<rml_comment>
{
    "*)"    { BEGIN(INITIAL); }
    
    [^\n]    ;
    \n       ;
    <<EOF>>  {
              yyterminate();
	     }
}

"/\*"	     {
		BEGIN(c_comment);
             }
<c_comment>
{
    "\*/"    { BEGIN(INITIAL); }
    [^\n]    ;
    \n       ;
    <<EOF>>  {
               yyterminate();
	     }
}

"//"	     {
		       BEGIN(c_linecomment); 
             }
             
<c_linecomment>
{
    \n        { 
	           BEGIN(INITIAL); 
			    }
    [^\n]     ;
	<<EOF>>  {
               yyterminate();
	            }
}

%%
