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
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
lexer grammar MetaModelica_Lexer;

options {
  language = C;
}

import BaseModelica_Lexer;

@includes {
  #include "ModelicaParserCommon.h"

  #define METAMODELICA_REAL_OP() {if (LA(1)=='.' && (LA(2) == ' ' || LA(2)=='\t' || LA(2)=='\n')) LEXER->matchc(LEXER,'.');}
  #define METAMODELICA_REAL_STRING_OP() {if (LA(1)=='&' || (LA(1)=='.' && (LA(2) == ' ' || LA(2)=='\t' || LA(2)=='\n'))) LEXER->matchAny(LEXER);}
}


/* MetaModelica extensions */
AS : 'as';
CASE : 'case';
EQUALITY : 'equality';
FAILURE : 'failure';
LOCAL : 'local';
MATCH : 'match';
MATCHCONTINUE : 'matchcontinue';
UNIONTYPE : 'uniontype';
WILD : '_';
SUBTYPEOF : 'subtypeof';
COLONCOLON : '::';
MOD : '%';

STAR    : '*' {METAMODELICA_REAL_OP()};
MINUS    : '-' {METAMODELICA_REAL_OP()};
PLUS    : '+' {METAMODELICA_REAL_STRING_OP()};
LESS    : '<' {METAMODELICA_REAL_OP()};
LESSEQ    : '<=' {METAMODELICA_REAL_OP()};
LESSGT    : '<>' {METAMODELICA_REAL_OP()}; /* '!=' */
GREATER    : '>' {METAMODELICA_REAL_OP()};
GREATEREQ  : '>=' {METAMODELICA_REAL_OP()};
EQEQ    : '==' {METAMODELICA_REAL_STRING_OP()};
POWER    : '^' {METAMODELICA_REAL_OP()};
SLASH    : '/' {METAMODELICA_REAL_OP()};

/*STAR    : '*' ('. ')?;
MINUS    : '-' ('. ')?;
PLUS    : '+' ('. '|'&')?;
LESS    : '<' ('. ')?;
LESSEQ    : '<=' ('. ')?;
LESSGT    : '<>' ('. ')?;
GREATER    : '>' ('. ')?;
GREATEREQ  : '>=' ('. ')?;
EQEQ    : '==' ('. '|'&')?;
POWER    : '^' ('. ')?;
SLASH    : '/' ('. ')?;*/

/* Modelica 3.0 elementwise operators */ 
PLUS_EW : '.+'; /* Modelica 3.0 */
MINUS_EW : '.-'; /* Modelica 3.0 */ 
STAR_EW : '.*'; /* Modelica 3.0 */
SLASH_EW : './'; /* Modelica 3.0 */ 
POWER_EW : '.^'; /* Modelica 3.0 */

/* Modelica 3.1 */
STREAM : 'stream'; /* for Modelica 3.1 stream connectors */

/* OpenModelica extensions */
CODE : '$Code';
