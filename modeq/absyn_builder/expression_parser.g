/*
    Copyright PELAB, Linkoping University

    This file is part of Open Source Modelica (OSM).

    OSM is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    OSM is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/

/* $Name$ */


/* $Id$ */

header "post_include_hpp" {

#define null 0
#include "MyAST.h"
}

options {
        language = "Cpp";
}

class modelica_expression_parser extends modelica_parser;

options {
    ASTLabelType = "RefMyAST";
}


tokens {
	INTERACTIVE_STMT;
	INTERACTIVE_ALG;
	INTERACTIVE_EXP;
}

interactiveStmts 
	:
		(interactiveStmt (SEMICOLON)? EOF!) => interactiveStmt (SEMICOLON)? EOF!
	|
		interactiveStmt SEMICOLON! interactiveStmts 
		
		;

interactiveStmt! 
	: 
		(expression) => e:expression {
			#interactiveStmt = #([INTERACTIVE_EXP,"INTERACTIVE_EXP"],#e);
		}
	| ( a:algorithm)		{	
			#interactiveStmt = #([INTERACTIVE_ALG,"INTERACTIVE_ALG"],#a);
		}
	; 

