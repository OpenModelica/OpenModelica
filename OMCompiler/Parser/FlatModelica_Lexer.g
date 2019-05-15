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
lexer grammar FlatModelica_Lexer;

options {
  language = C;
}

import BaseModelica_Lexer;

STAR       : '*';
MINUS      : '-';
PLUS       : '+';
LESS       : '<';
LESSEQ     : '<=';
LESSGT     : '<>';
GREATER    : '>';
GREATEREQ  : '>=';
EQEQ       : '==';
POWER      : '^';
SLASH      : '/';

/* Modelica 3.0 elementwise operators */ 
PLUS_EW : '.+'; /* Modelica 3.0 */
MINUS_EW : '.-'; /* Modelica 3.0 */ 
STAR_EW : '.*'; /* Modelica 3.0 */
SLASH_EW : './'; /* Modelica 3.0 */ 
POWER_EW : '.^'; /* Modelica 3.0 */

/* Modelica 3.1 */
STREAM : 'stream'; /* for Modelica 3.1 stream connectors */

fragment
IDENT2 : NONDIGIT ('.' | '[' | ']' | NONDIGIT | DIGIT)*;

