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
}

tokens {
	ALGORITHM	= "algorithm"	;
	AND			= "and"	;
	ANNOTATION	= "annotation"	;
	BLOCK		= "block"	;
	BOUNDARY	= "boundary"	;
	CODE		= "Code"		;
	CLASS		= "class"	;
	CONNECT		= "connect"	;
	CONNECTOR	= "connector"	;
	CONSTANT	= "constant"	;
	DISCRETE	= "discrete"	;
	EACH		= "each"	;
	ELSE		= "else"	;
	ELSEIF		= "elseif"	;
	ELSEWHEN	= "elsewhen"	;
  	END		= "end"		;
	ENUMERATION	= "enumeration"	;
	EQUATION	= "equation"	;
	ENCAPSULATED	= "encapsulated";
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
	OVERLOAD    = "overload";
	OUTER		= "outer"	;
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
	WHEN		= "when"	;
	WHILE		= "while"	;
	WITHIN		= "within" 	;
    
//    SUM = "sum" ;
//    ARRAY = "array";
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
PLUS		: '+'	;
MINUS		: '-'	;
STAR		: '*'	;
SLASH		: '/'	;
DOT		: '.'	;
COMMA		: ','	;
LESS		: '<'	;
LESSEQ		: "<="	;
GREATER		: '>'	;
GREATEREQ	: ">="	;
EQEQ		: "=="	;
LESSGT		: "<>"	;
COLON		: ':'	;
SEMICOLON	: ';'	;
POWER		: '^'	;




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
		"//" (~('\n' | '\r'))* 
		{  $setType(antlr::Token::SKIP); }
  	;

IDENT options { testLiterals = true;} :
		NONDIGIT (NONDIGIT | DIGIT)*;

protected
NONDIGIT : 	('_' | 'a'..'z' | 'A'..'Z');

protected 
DIGIT :
	'0'..'9'
	;

protected
EXPONENT :
	('e'|'E') ('+' | '-')? (DIGIT)+
	;

/*
NUM_INT
	:	('0'..'9')+ // everything starts with a digit sequence
		(	(	{(LA(2)!='.')&&(LA(2)!=')')}?				// force k=2; avoid ".."
//PSPSPS example ARRAY (.1..99.) OF char; // after .. thinks it's a NUM_REAL
				'.' {$setType(NUM_REAL);}	// dot means we are float
				('0'..'9')+ (EXPONENT)?
			)?
		|	EXPONENT {$setType(NUM_REAL);}	// 'E' means we are float
		)
	;

// a couple protected methods to assist in matching floating point numbers
protected
EXPONENT
	:	('e') ('+'|'-')? ('0'..'9')+
	;
*/

UNSIGNED_INTEGER :
    (DIGIT)+
		( ( {LA(2) != '.' }?
		 '.' {$setType(UNSIGNED_REAL);}
		 (DIGIT)* (EXPONENT)?
		 )?
	     | (EXPONENT { $setType(UNSIGNED_REAL); } )
	    )
	;

STRING : '"'! (SCHAR | SESCAPE)* '"'!;

		
protected 
SCHAR :	(options { generateAmbigWarnings=false; } : ('\n' | "\r\n"))	{ newline(); }
	| '\t'
	| ~('\n' | '\t' | '\r' | '\\' | '"');

protected
SESCAPE : '\\' ('\\' | '"' | "'" | '?' | 'a' | 'b' | 'f' | 'n' | 'r' | 't' | 'v');


protected
ESC :
	'\\'
	(	'"'
	|	'\\'
	)
	;



