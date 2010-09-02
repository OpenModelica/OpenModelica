/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkoping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
lexer grammar BaseModelica_Lexer;

options {
  language = C;
}

tokens {
T_ALGORITHM;
T_AND;
T_ANNOTATION;
BLOCK;
CODE;
CLASS;
CONNECT;
CONNECTOR;
CONSTANT;
DISCRETE;
DER;
DEFINEUNIT;
EACH;
ELSE;
ELSEIF;
ELSEWHEN;
T_END;
ENUMERATION;
EQUATION;
ENCAPSULATED;
EXPANDABLE;
EXTENDS;
CONSTRAINEDBY;
EXTERNAL;
T_FALSE;
FINAL;
FLOW;
FOR;
FUNCTION;
IF;
IMPORT;
T_IN;
INITIAL;
INNER;
T_INPUT;
LOOP;
MODEL;
T_NOT;
T_OUTER;
OPERATOR; 
OVERLOAD;
T_OR;
T_OUTPUT;
PACKAGE;
PARAMETER;
PARTIAL;
PROTECTED;
PUBLIC;
RECORD;
REDECLARE;
REPLACEABLE;
RESULTS;
THEN;
T_TRUE;
TYPE;
UNSIGNED_REAL;
WHEN;
WHILE;
WITHIN;
RETURN;
BREAK;
STREAM;
/* MetaModelica keywords. I guess not all are needed here. */
AS;
CASE;
EQUALITY;
FAILURE;
LOCAL;
MATCH;
MATCHCONTINUE;
UNIONTYPE;
WILD;
SUBTYPEOF;
COLONCOLON;

// ---------
// Operators
// ---------

DOT; 
LPAR;
RPAR;
LBRACK;
RBRACK;
LBRACE;
RBRACE;
EQUALS;
ASSIGN;
COMMA;
COLON;
SEMICOLON;
/* elementwise operators */  
PLUS_EW;
MINUS_EW;
STAR_EW;
SLASH_EW;
POWER_EW;

/* MetaModelica operators */
COLONCOLON;
MOD;

// parser tokens 
ALGORITHM_STATEMENT;
ARGUMENT_LIST;
CLASS_DEFINITION;
CLASS_EXTENDS ;
CLASS_MODIFICATION;
CODE_EXPRESSION;
CODE_MODIFICATION;
CODE_ELEMENT;
CODE_EQUATION;
CODE_INITIALEQUATION;
CODE_ALGORITHM;
CODE_INITIALALGORITHM;
COMMENT;
COMPONENT_DEFINITION;
DECLARATION;
DEFINITION;
ENUMERATION_LITERAL;
ELEMENT;
ELEMENT_MODIFICATION;
ELEMENT_REDECLARATION;
EQUATION_STATEMENT;
EXTERNAL_ANNOTATION;
INITIAL_EQUATION;
INITIAL_ALGORITHM;
IMPORT_DEFINITION;
IDENT_LIST;
EXPRESSION_LIST;
EXTERNAL_FUNCTION_CALL;
FOR_INDICES;
FOR_ITERATOR;
FUNCTION_CALL;
INITIAL_FUNCTION_CALL;
FUNCTION_ARGUMENTS;
NAMED_ARGUMENTS;
QUALIFIED;
RANGE2;
RANGE3;
STORED_DEFINITION;
STRING_COMMENT;
UNARY_MINUS;
UNARY_PLUS;
UNARY_MINUS_EW;
UNARY_PLUS_EW;
UNQUALIFIED;
FLAT_IDENT;
TYPE_LIST;
EMPTY;
OPERATOR;
}

T_ALGORITHM : 'algorithm';
T_AND : 'and';
T_ANNOTATION : 'annotation';
BLOCK : 'block';
CLASS : 'class';
CONNECT : 'connect';
CONNECTOR : 'connector';
CONSTANT : 'constant';
DISCRETE : 'discrete';
DER : 'der';
DEFINEUNIT : 'defineunit';
EACH : 'each';
ELSE : 'else';
ELSEIF : 'elseif';
ELSEWHEN : 'elsewhen';
T_END : 'end';
ENUMERATION : 'enumeration';
EQUATION : 'equation';
ENCAPSULATED : 'encapsulated';
EXPANDABLE : 'expandable';
EXTENDS : 'extends';
CONSTRAINEDBY : 'constrainedby';
EXTERNAL : 'external';
T_FALSE : 'false';
FINAL : 'final';
FLOW : 'flow';
FOR : 'for';
FUNCTION : 'function';
IF : 'if';
IMPORT : 'import';
T_IN : 'in';
INITIAL : 'initial';
INNER : 'inner';
T_INPUT : 'input';
LOOP : 'loop';
MODEL : 'model';
T_NOT : 'not';
T_OUTER : 'outer';
OPERATOR : 'operator'; 
OVERLOAD : 'overload';
T_OR : 'or';
T_OUTPUT : 'output';
PACKAGE : 'package';
PARAMETER : 'parameter';
PARTIAL : 'partial';
PROTECTED : 'protected';
PUBLIC : 'public';
RECORD : 'record';
REDECLARE : 'redeclare';
REPLACEABLE : 'replaceable';
RESULTS : 'results';
THEN : 'then';
T_TRUE : 'true';
TYPE : 'type';
UNSIGNED_REAL : 'unsigned_real';
WHEN : 'when';
WHILE : 'while';
WITHIN : 'within';
RETURN : 'return';
BREAK : 'break';

// ---------
// Operators
// ---------

DOT : '.'; 
LPAR : '(';
RPAR : ')';
LBRACK : '[';
RBRACK : ']';
LBRACE : '{';
RBRACE : '}';
EQUALS : '=';
ASSIGN : ':=';
COMMA : ',';
COLON : ':';
SEMICOLON : ';';

/*------------------------------------------------------------------
 * LEXER RULES
 *------------------------------------------------------------------*/

WS : ( ' ' | '\t' | NL )+ { $channel=HIDDEN; }
  ;
  
LINE_COMMENT
    : '//' ( ~('\r'|'\n')* ) (NL|EOF) { $channel=HIDDEN; }
    ;  

ML_COMMENT
    :   '/*' (options {greedy=false;} : .)* '*/' { $channel=HIDDEN;  }
    ;

fragment 
NL: (('\r')? '\n');

IDENT :
       ('_' {  $type = WILD; } | NONDIGIT { $type = IDENT; })
       (('_' | NONDIGIT | DIGIT) { $type = IDENT; })*
    | (QIDENT { $type = IDENT; })
    ;

fragment
QIDENT :
         '\'' (QCHAR | SESCAPE) (QCHAR | SESCAPE)* '\'' ;

fragment
QCHAR :  NL  | '\t' | ~('\n' | '\t' | '\r' | '\\' | '\'');

fragment
NONDIGIT :   ('a'..'z' | 'A'..'Z');

fragment
DIGIT :
  '0'..'9'
  ;

fragment
EXPONENT :
  ('e'|'E') ('+' | '-')? (DIGIT)+
  ;


UNSIGNED_INTEGER :
    (DIGIT)+ ('.' (DIGIT)* { $type = UNSIGNED_REAL; } )? (EXPONENT { $type = UNSIGNED_REAL; } )?
  | ('.' { $type = DOT; } )
      ( (DIGIT)+ { $type = UNSIGNED_REAL; } (EXPONENT { $type = UNSIGNED_REAL; } )?
         | /* Modelica 3.0 element-wise operators! */
         (('+' { $type = PLUS_EW; }) 
          |('-' { $type = MINUS_EW; }) 
          |('*' { $type = STAR_EW; }) 
          |('/' { $type = SLASH_EW; }) 
          |('^' { $type = POWER_EW; })
          )?
      )
  ;

STRING : '"' STRING_GUTS '"'
       {SETTEXT($STRING_GUTS.text);};

fragment
STRING_GUTS: (SCHAR | SESCAPE)*
       ;

fragment
SCHAR :  NL | '\t' | ~('\n' | '\t' | '\r' | '\\' | '"');

fragment
SESCAPE : '\\' ('\\' | '"' | '\'' | '?' | 'a' | 'b' | 'f' | 'n' | 'r' | 't' | 'v');

/* OpenModelica extensions */
CODE : '$Code';
