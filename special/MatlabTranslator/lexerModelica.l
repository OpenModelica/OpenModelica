%{

%}
	
%option noyywrap
%s QuoteSC
%x B_COMMENT
%x S_COMMENT	
	
HSPACE 			[ \t]
HSPACES   	 	{HSPACE}+
NEWLINE 		((\n)|(\r)|(\r\n))
NEWLINES 		{NEWLINE}+
IDENTIFIER 		[a-zA-Z][_a-zA-Z0-9]*
CONT            (\.\.\.)
Im              [iIjJ]
DIGIT 			[0-9]
DIGITS			{DIGIT}+
EXPON           ([DdEe][+-]?{DIGIT}+)
NUMBER          (({DIGIT}+\.?{DIGIT}*{EXPON}?)|(\.{DIGIT}+{EXPON}?)|(0[xX][0-9a-fA-F]+))
COMMENT 		\%[^\n\r\f]*{NEWLINE}?
ELLIPSIS 		\.\.\.
CONTINUATION    {ELLIPSIS}[^\n\r\f]*{NEWLINE}?

%%
    	
"function" return FUNCTION;	
"end" 	return END;		
"if" 	return IF;		
"elseif" return ELSEIF;		
"else"	return ELSE;
"while" return WHILE;
"for" 	return FOR;  			
"switch" return SWITCH;	
"case"  return CASE;
"otherwise" return OTHERWISE;
"global" return GLOBAL;		
"break" return BREAK;
"continue" return CONTINUE;
"return" return RETURN;

"classdef" return CLASSDEF;
"properties" return PROPERTIES;
"methods" return METHODS;
"events" return EVENTS;
"get" return GET;
"set" return SET;
"try" return TRY;
"catch" return CATCH;
 		
 		
{DIGITS} return INTEGER; 		
{NUMBER}	return NUMBER;		
{NUMBER}{Im} return IMAG_NUM;
{IDENTIFIER}	return IDENT;		
{COMMENT}   ;
{HSPACES}   ; 	
{NEWLINES}	return NEWLINES;

<INITIAL>'[^'\n\r\f]*'/' {   
			yymore();
		}
<INITIAL>'[^'\r\f\n]*' 	return STRING;   		

"\+"    return ADD;
"-"     return SUB;
"\*"    return MUL;
"\/"    return DIV;
"\^"    return POW;

".*"    return EMUL;
"./"    return EDIV;
"\.\\"  return ELEFTDIV;
"\.^"   return EPOW;

"\<"    return EXPR_LT;
">"     return EXPR_GT;
"\<="   return EXPR_LE;
">="    return EXPR_GE;
"=="    return EXPR_EQ;
"~="    return EXPR_NE;

"&"     return EXPR_AND;
"\|"    return EXPR_OR;
"\\"    return LEFTDIV;
"&&"    return EXPR_AND_AND;
"||"    return EXPR_OR_OR;
"~" 	return EXPR_NOT;

","     return COMMA;
"="     return EQ;
":"     return COLON;
";"     return SEMI_COLON;

"]" return RBRACK;
"[" return LBRACK;
"(" return LPAR;
")" return RPAR;   
"}" return RBRACE;
"{" return LBRACE;

"." return DOT;
"\@" return AT;

{IDENTIFIER}@{IDENTIFIER}{HSPACE}* return SUPERCLASSREF;
{IDENTIFIER}@{IDENTIFIER}.{IDENTIFIER}{HSPACE}* return SUPERCLASSREF;
\?{IDENTIFIER}{HSPACE}* return METAQUERY;
\?{IDENTIFIER}.{IDENTIFIER}{HSPACE}* return METAQUERY;

"%{"	     {
		BEGIN(B_COMMENT);
             }
<B_COMMENT>
{
    "%}"    { 
    		BEGIN(INITIAL);  
    		}    	           
}

"%"	     {
              BEGIN(S_COMMENT);                
         }             
<S_COMMENT> 
{ 
   \n        { 
              BEGIN(INITIAL); 
			 } 			     
}
\.' 	{
			BEGIN(QuoteSC);
			return TRANSPOSE;
		}
<QuoteSC>'		{
			return CTRANSPOSE;
		}

{CONTINUATION}		{
			
		}
    
%%
