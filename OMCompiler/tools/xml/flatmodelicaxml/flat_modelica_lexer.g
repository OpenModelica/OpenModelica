/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

header {

}

options {
  language = "Cpp";
}

class flat_modelica_lexer extends Lexer;

options {
    k=2;
    charVocabulary = '\3'..'\377';
    exportVocab = flatmodelica;
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
{
    std::string & replaceAll(std::string & str, const char *src, const char* dst)
    {
        size_t pos;
        while((pos = str.find(".")) < str.size()-1) {
                str.replace(pos,1,"_");
            }
        return str;
    }
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
		NONDIGIT (NONDIGIT | DIGIT | DOT )*
        {
            std::string tmp=$getText;
            $setText(replaceAll(tmp,
                ".",
                "_"));
        }

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





