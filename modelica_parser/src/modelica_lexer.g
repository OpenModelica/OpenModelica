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
	WHEN		= "when"	;
	WHILE		= "while"	;
	WITHIN		= "within" 	;
    
//    SUM = "sum" ;
//    ARRAY = "array";

// Extra tokens for RML
        ABSTYPE         = "abstype";
//        AND             = "and";
        AS              = "as";
        AXIOM           = "axiom";
        DATATYPE        = "datatype";
        FAIL            = "fail";
        LET             = "let";
        INTERFACE       = "interface";
        MODULE          = "module";
        OF              = "of";
        RELATION        = "relation";
        RULE            = "rule";
        VAL             = "val";
        WILD            = "_";
        WITH            = "with";
        WITHTYPE        = "withtype";
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
YIELDS          : "=>"  ;
AMPERSAND       : "&"   ;
PIPEBAR         : "|"   ;
COLONCOLON      : "::"  ;
DASHES          : '-' '-' '-' ( '-' )* ;


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
		NONDIGIT (NONDIGIT | DIGIT)*
		;

TYVARIDENT options { testLiterals = true; paraphrase = "a type identifier";} :
		     '\'' NONDIGIT (NONDIGIT | DIGIT)*
		;

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


UNSIGNED_INTEGER :
	(( (DIGIT)+ '.' ) => (DIGIT)+ ( '.' (DIGIT)* ) 
			{ 
				$setType(UNSIGNED_REAL); 
			}
	| 	(DIGIT)+
	)
	(EXPONENT { $setType(UNSIGNED_REAL); } )?
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





