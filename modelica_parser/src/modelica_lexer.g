/* 
 * This file is part of OpenModelica.
 * 
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science, 
 * SE-58183 Linköping, Sweden. 
 * 
 * All rights reserved.
 * 
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC 
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF 
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC 
 * PUBLIC LICENSE. 
 * 
 * The OpenModelica software and the Open Source Modelica 
 * Consortium (OSMC) Public License (OSMC-PL) are obtained 
 * from Linköpings University, either from the above address, 
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 * 
 * This program is distributed  WITHOUT ANY WARRANTY; without 
 * even the implied warranty of  MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH 
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS 
 * OF OSMC-PL. 
 * 
 * See the full OSMC Public License conditions for more details.
 * 
 */
 
header {

}

options {
  language = "Cpp";
}

class modelica_lexer extends Lexer; 

options {
    k=2;
    charVocabulary = '\3'..'\377';
    exportVocab = modelica;
    testLiterals = false;
    defaultErrorHandler = false;
    caseSensitive = true;
}

tokens {
	ALGORITHM	= "algorithm"	;
	AND			= "and"	;
	ANNOTATION	= "annotation"	;
	BLOCK		= "block"	;
	CODE		= "Code"		;
	CLASS		= "class"	;
	CONNECT		= "connect"	;
	CONNECTOR	= "connector"	;
	CONSTANT	= "constant"	;
	DISCRETE	= "discrete"	;
    DER         = "der";
	EACH		= "each"	;
	ELSE		= "else"	;
	ELSEIF		= "elseif"	;
	ELSEWHEN	= "elsewhen"	;
  	END		= "end"		;
	ENUMERATION	= "enumeration"	;
	EQUATION	= "equation"	;
	ENCAPSULATED	= "encapsulated";
    EXPANDABLE  = "expandable";
	EXTENDS		= "extends"	;
	EXTERNAL	= "external"	;
	FALSE		= "false"	;
	FINAL		= "final"	;
	FLOW		= "flow"	;
	FOR		= "for"		;
	FUNCTION	= "function"	;
	IF		= "if"		;
	IMPORT		= "import"	;
	IN		= "in"		;
	INITIAL		= "initial"	;
	INNER		= "inner"	;
	INPUT		= "input"	;
	LOOP		= "loop"	;
	MODEL		= "model"	;
	NOT		= "not"		;
	OUTER		= "outer"	;
    OVERLOAD    = "overload";
	OR		= "or"		;
	OUTPUT		= "output"	;
	PACKAGE		= "package"	;
	PARAMETER	= "parameter"	;
	PARTIAL		= "partial"	;
	PROTECTED	= "protected"	;
	PUBLIC		= "public"	;
	RECORD		= "record"	;
	REDECLARE	= "redeclare"	;
	REPLACEABLE	= "replaceable"	;
	RESULTS		= "results"	;
	THEN		= "then"	;
	TRUE		= "true"	;
	TYPE		= "type"	;
	UNSIGNED_REAL	= "unsigned_real";
    DOT         = ".";
	WHEN		= "when"	;
	WHILE		= "while"	;
	WITHIN		= "within" 	;
	RETURN		= "return"  ;
	BREAK		= "break"	;
	/* MetaModelica keywords. I guess not all are needed here. */	
	AS		= "as"	;
	CASE		= "case"	;
	EQUALITY	= "equality";
	FAILURE		= "failure";
	LOCAL		= "local"	;
	MATCH		= "match"	;
	MATCHCONTINUE	= "matchcontinue"	;	
	UNIONTYPE	= "uniontype"		;
	WILD		= "_"			;
	SUBTYPEOF   = "subtypeof"  ;
	/*
	LIST		= "list"	;
	OPTION		= "Option"		;
	TUPLE		= "tuple"		;
	FAIL		= "fail";
	*/
	LESSEQ ;
	RLESS  ;
}


// ---------
// Operators
// ---------

LPAR		: '('	;
RPAR		: ')'	;
LBRACK		: '['	;
RBRACK		: ']'	;
LBRACE		: '{'	;
RBRACE		: '}'	;
EQUALS		: '='	;
ASSIGN		: ":="	;
PLUS		: '+'|"+."|"+&" ;
MINUS		: '-'|"-." ;
STAR		: '*'|"*." ;
SLASH		: '/'|"/." ;
COMMA		: ',';
LESS		: '<' 
			(  ('='   { $setType(LESSEQ); }) 
			 | ('.'   { $setType(RLESS); })
			 | ("=."  { $setType(LESSEQ); })
			 | ('>'   { $setType(LESSGT); })
			 | (">."  { $setType(LESSGT); }) 
			)?        
			;
LESSGT		: ("!=")('.')?;
GREATER		: '>' ;
RGREATER	: ">." ;
GREATEREQ	: ">="(".")?;
EQEQ		: "=="(('.')|('&'))?;
COLON		: ':'	;
SEMICOLON	: ';'	;
POWER		: '^'('.')?;

/* MetaModelica operators */
COLONCOLON      : "::"  ;
MOD		: '%'   ;


WS :
	(	' '
	|	'\t'
	|	( "\r\n" | '\r' |	'\n' ) { newline(); }
	)
	{ $setType(antlr::Token::SKIP); }
	;

ML_COMMENT :
		"/*"
		(options { generateAmbigWarnings=false; } : ML_COMMENT_CHAR
		| {LA(2)!='/'}? '*')*
		"*/" { $setType(antlr::Token::SKIP); } ;

protected
ML_COMMENT_CHAR :	
		("\r\n" | '\n') { newline(); }	
		| ~('*'|'\n'|'\r') 
		;
		
SL_COMMENT :
		"//" (~('\n' | '\r') )*
		{  $setType(antlr::Token::SKIP); }
  	;

IDENT options { testLiterals = true; paraphrase = "an identifier";} :
		   ('_' {  $setType(WILD); } | NONDIGIT { $setType(IDENT); }) 
		   (('_' | NONDIGIT | DIGIT) { $setType(IDENT); })*
		| (QIDENT { $setType(IDENT); })
		;

protected 
QIDENT options { testLiterals = true; paraphrase = "an identifier";} : 
         '\'' (QCHAR | SESCAPE) (QCHAR | SESCAPE)* '\'' ;

protected
NONDIGIT : 	('a'..'z' | 'A'..'Z');

protected 
DIGIT :
	'0'..'9'
	;

protected
EXPONENT :
	('e'|'E') ('+' | '-')? (DIGIT)+
	;


UNSIGNED_INTEGER :
        (DIGIT)+ ('.' (DIGIT)* { $setType(UNSIGNED_REAL);} )? 
        (EXPONENT { $setType(UNSIGNED_REAL); } )?
    |
        ('.' DIGIT) => ('.' (DIGIT)+ { $setType(UNSIGNED_REAL);})         
        (EXPONENT { $setType(UNSIGNED_REAL); } )?
    | 
      '.' { $setType(DOT); }
	;

STRING : '"'! (SCHAR | SESCAPE)* '"'!;

		
protected 
SCHAR :	(options { generateAmbigWarnings=false; } : ('\n' | "\r\n"))	{ newline(); }
	| '\t'
	| ~('\n' | '\t' | '\r' | '\\' | '"');

protected 
QCHAR :	(options { generateAmbigWarnings=false; } : ('\n' | "\r\n"))	{ newline(); }
	| '\t'
	| ~('\n' | '\t' | '\r' | '\\' | '\'');

protected
SESCAPE : '\\' ('\\' | '"' | "'" | '?' | 'a' | 'b' | 'f' | 'n' | 'r' | 't' | 'v');


protected
ESC :
	'\\'
	(	'"'
	|	'\\'
	)
	;





