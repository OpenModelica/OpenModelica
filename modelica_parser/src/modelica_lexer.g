/*
This file is part of OpenModelica.

Copyright (c) 1998-2006, Linkopings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

* Neither the name of Linkopings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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





