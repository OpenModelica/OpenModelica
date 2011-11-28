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
CODE_EXP;
CODE_NAME;
CODE_VAR;
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
END_FOR;
END_IDENT;
END_IF;
END_MATCH;
END_MATCHCONTINUE;
END_WHEN;
END_WHILE;
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
GARBAGE;
IF;
IMPORT;
T_IN;
IMPURE;
INITIAL;
INNER;
T_INPUT;
LOOP;
MODEL;
T_NOT;
T_OUTER;
OPERATOR; 
OVERLOAD;
PURE;
T_OR;
T_OUTPUT;
T_PACKAGE;
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
GUARD;
LOCAL;
MATCH;
MATCHCONTINUE;
SUBTYPEOF;
UNIONTYPE;
WILD;
ALLWILD;

// ---------
// OptiMo
// ---------

OPTIMIZATION;
CONSTRAINT;
//FREE;
//INITIALGUESS;
//FINALTIME;

// ---------
// ParModelica Extensions
// ---------

PARFOR;
T_PARALLEL;
T_LOCAL;
T_GLOBAL;
T_KERNEL;
END_PARFOR;



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

IDENT;

}

@includes {
  #include "ModelicaParserCommon.h"
  #include "runtime/errorext.h"
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
T_PACKAGE : 'package';
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

// ---------
// OptiMo
// ---------
// in the file MetaModelica_Lexer.g

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
NL: '\r\n' | '\n' | '\r';

/* OpenModelica extensions */
CODE : 'Code' | '$Code';
CODE_NAME : '$TypeName';
CODE_EXP : '$Exp';
CODE_VAR : '$Var';

PURE : 'pure';
IMPURE : 'impure';

STRING : '"' STRING_GUTS '"'
       {
         pANTLR3_STRING text = $STRING_GUTS.text;
         /*
          * adpro: this is not needed anymore as we
          *        open the files in binary mode "wb" 
          *        in System.writeFile and Print.writeBuf
          * fixString(text); */ /* Replace \r\n with \n, but only in Windows */
         SETTEXT(text);
       };

fragment
STRING_GUTS: (SCHAR | SESCAPE)*
       ;

fragment
SCHAR : NL | ~('\r' | '\n' | '\\' | '"');

fragment
SESCAPE : esc='\\' ('\\' | '"' | '\'' | '?' | 'a' | 'b' | 'f' | 'n' | 'r' | 't' | 'v' |
  {
    char chars[2] = {LA(1),'\0'};
    const char *str = chars;
    int len = strlen((char*)$text->chars);
    c_add_source_message(2, ErrorType_syntax, ErrorLevel_warning, "Lexer treating \\ as \\\\, since \\\%s is not a valid Modelica escape sequence.",
          &str, 1, $line, $pos+1, $line, $pos+len+1,
          ModelicaParser_readonly, ModelicaParser_filename_C);
  });

fragment
EAT_WS_COMMENT : (WS)+ {$channel=ANTLR3_TOKEN_DEFAULT_CHANNEL;};

END_IF : 'end' EAT_WS_COMMENT 'if';
END_FOR : 'end' EAT_WS_COMMENT 'for';
END_WHEN : 'end' EAT_WS_COMMENT 'when';
END_WHILE : 'end' EAT_WS_COMMENT 'while';
END_IDENT : 'end' EAT_WS_COMMENT
    ( IDENT2 {SETTEXT($IDENT2.text);}
    | QIDENT {SETTEXT($QIDENT.text);}
    )
  ;
T_END : 'end' EAT_WS_COMMENT?;

IDENT : QIDENT | IDENT2;

fragment
IDENT2 : NONDIGIT (NONDIGIT | DIGIT)*;

fragment
QIDENT :
         '\'' (QCHAR | SESCAPE) (QCHAR | SESCAPE)* '\'' ;

fragment
QCHAR :  NL  | '\t' | ~('\n' | '\t' | '\r' | '\\' | '\'');

fragment
NONDIGIT :   ('_' | 'a'..'z' | 'A'..'Z');

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
      ( (DIGIT)+ EXPONENT?
          {
            const char *strs[2] = {(char*)$text->chars,(char*)$text->chars};
            int len = strlen((char*)$text->chars);
            $type = UNSIGNED_REAL;
            c_add_source_message(2, ErrorType_syntax, ErrorLevel_warning, "Treating \%s as 0\%s. This is not standard Modelica and only done for compatibility with old code. Support for this feature may be removed in the future.",
               strs, 2, $line, $pos+1, $line, $pos+len+1,
               ModelicaParser_readonly, ModelicaParser_filename_C);
           } 
         | /* Modelica 3.0 element-wise operators! */
         (('+' { $type = PLUS_EW; }) 
          |('-' { $type = MINUS_EW; }) 
          |('*' { $type = STAR_EW; }) 
          |('/' { $type = SLASH_EW; }) 
          |('^' { $type = POWER_EW; })
          )?
      )
  ;
