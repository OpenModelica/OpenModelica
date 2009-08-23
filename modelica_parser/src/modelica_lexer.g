/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linkopings University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
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
 * from Linkopings University, either from the above address,
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
    /* k=2; */
    charVocabulary = '\3'..'\377';
    exportVocab = modelica;
    testLiterals = false;
    defaultErrorHandler = false;
    caseSensitive = true;
    codeGenMakeSwitchThreshold=2;
    codeGenBitsetTestThreshold=3;
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
    DEFINEUNIT  = "defineunit"  ;
	EACH		= "each"	;
	ELSE		= "else"	;
	ELSEIF		= "elseif"	;
	ELSEWHEN	= "elsewhen"	;
  	END		= "end"		;
	ENUMERATION	= "enumeration"	;
	EQUATION	= "equation"	;
	ENCAPSULATED	= "encapsulated";
    EXPANDABLE  = "expandable";
	EXTENDS		= "extends" ;
	CONSTRAINEDBY =  "constrainedby" ;
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
	STREAM		= "stream"	; /* for Modelica 3.1 stream connectors */
	LESSEQ    ;
	LESSGT    ;
	GREATEREQ ;
	EQEQ      ;
	COLON     ;
	ASSIGN    ;
	ML_COMMENT ;
	/* Modelica 3.0 element-wise operators */
    PLUS_EW  ;
    MINUS_EW ;
    STAR_EW  ;
    SLASH_EW ;
    POWER_EW ;
	
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
	COLONCOLON ;
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
COLON		: ':' ( (':' { $setType(COLONCOLON);}) | ('='{$setType(ASSIGN);}) )?;
PLUS		: '+'('.'|'&')? ;
MINUS		: '-'('.')? ;
STAR		: '*'('.')? ;
COMMA		: ',';
LESS		: '<' ( ('.' {$setType(LESS);})|('='('.')? {$setType(LESSEQ);})|('>'('.')? {$setType(LESSGT);}) )? ;
GREATER		: '>' ( ('.' {$setType(GREATER);})|('='('.')? {$setType(GREATEREQ);}) )? ;
EQUALS		: '=' ('='(('.')|('&'))? {$setType(EQEQ);} )?;
SEMICOLON	: ';' ;
POWER		: '^'('.')? ;
/* MetaModelica operators */
MOD         : '%'   ;

WS :
	( ' '
	| '\t'
	| NL
	)
	{ $setType(antlr::Token::SKIP); }
	;

SLASH : '/' {$setType(SLASH);}
        ( '.' {$setType(SLASH);}
        | '/' ( ~('\r'|'\n') )* {$setType(antlr::Token::SKIP);}
		| '*' ( options { generateAmbigWarnings=false; } : ML_COMMENT_CHAR | {LA(2)!='/'}? '*')* '*''/' {$setType(antlr::Token::SKIP);}
		)?        
		;

protected
NL: (('\r')? '\n') { newline(); };

protected 
ML_COMMENT_CHAR:
         NL 
       | ~('*'|'\r'|'\n')
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
    (DIGIT)+ ('.' (DIGIT)* { $setType(UNSIGNED_REAL); } )? (EXPONENT { $setType(UNSIGNED_REAL); } )?      
  | ('.' { $setType(DOT); } )
      ( (DIGIT)+ { $setType(UNSIGNED_REAL); } (EXPONENT { $setType(UNSIGNED_REAL); } )?
         | /* Modelica 3.0 element-wise operators! */
         (('+' { $setType(PLUS_EW); }) 
          |('-' { $setType(MINUS_EW); }) 
          |('*' { $setType(STAR_EW); }) 
          |('/' { $setType(SLASH_EW); }) 
          |('^' { $setType(POWER_EW); })
          )?
      )
	;

STRING : '"'! (SCHAR | SESCAPE)* '"'!;

protected
SCHAR :	
      NL
	| '\t'
	| ~('\n' | '\t' | '\r' | '\\' | '"');

protected
QCHAR :	
      NL	
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





