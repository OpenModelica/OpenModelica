/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linkopings universitet, Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 *
 * @author Martin Sjölund <martin.sjolund@liu.se>
 *
 * Based on OMC Values.Value output syntax
 */

grammar OMCOutput;

options {
  ASTLabelType = pANTLR3_BASE_TREE;
  language = C;
}

@includes {
#include <QVariant>
}

exp [QVariant &res]
@init {
  QVariantList res2;
}
  : T_INTEGER {res = QVariant::fromValue((long) QString((char*)$T_INTEGER.text->chars).toLong());}
  | T_REAL {res = QVariant(QString((char*)$T_REAL.text->chars).toDouble());}
  | T_MODELICA_STRING {res = QVariant(QString((char*)$T_MODELICA_STRING.text->chars));}
  | T_IDENT {res = QVariant(QString((char*)$T_IDENT.text->chars));}
  | T_TRUE {res = QVariant(true);}
  | T_FALSE {res = QVariant(false);}
  | T_FAIL {res = QVariant();}
  | T_LPAR T_RPAR {res = QVariantList();}
  | T_LPAR {res2 = QVariantList();} exp_list[res2] {res = res2;}
  ;

exp_list [QVariantList &lst]
@init {
  QVariant res;
}
  : exp[res] (T_COMMA exp_list[lst] | T_RPAR) {lst.push_front(res);}
  ;

// LEXER

T_LPAR : '(' | '{';
T_RPAR : ')' | '}';
T_FAIL : 'fail()';

T_TRUE : 'true';
T_FALSE : 'false';

T_MODELICA_STRING : '"' ('\\"' | ~'"')* '"';

T_IDENT : QIDENT | IDENT2;
T_COMMA : ',';

fragment
IDENT2 : NONDIGIT (NONDIGIT | DIGIT)*;

fragment
QIDENT :
         '\'' (QCHAR | SESCAPE) (QCHAR | SESCAPE)* '\'' ;

fragment
QCHAR :  (DIGIT | NONDIGIT | '!' | '#' | '$' | '%' | '&' | '(' | ')' | '*' | '+' | ',' | '-' | '.' | '/' | ':' | ';' | '<' | '>' | '=' | '?' | '@' | '[' | ']' | '^' |
'{' | '}' | '|' | '~' | ' ');

fragment
SESCAPE : esc='\\' ('\\' | '"' | '\'' | '?' | 'a' | 'b' | 'f' | 'n' | 'r' | 't' | 'v');

fragment
NONDIGIT :   ('_' | 'a'..'z' | 'A'..'Z');

fragment
DIGIT :
  '0'..'9'
  ;

WS :
  (' ' | '\t' | '\n') { $channel=HIDDEN; }
  ;

fragment
EXPONENT :
  ('e'|'E') ('+' | '-')? (DIGIT)+
  ;


T_INTEGER : '-'? (DIGIT)+;
T_REAL :
  '-'?
  (
    ((DIGIT)+ '.' (DIGIT)*|(DIGIT)* '.' (DIGIT)+) EXPONENT?
  | (DIGIT)+ EXPONENT
  )
  ;
