/* 
 * This file is part of OpenModelica.
 * 
 * Copyright (c) 1998-2008, Linkopings University,
 * Department of Computer and Information Science, 
 * SE-58183 Linkoping, Sweden. 
 * 
 * All rights reserved.
 * 
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC 
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF 
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC 
 * PUBLIC LICENSE. 
 * 
 * The OpenModelica software and the Open Source Modelica 
 * Consortium (OSMC) Public License (OSMC-PL) are obtained 
 * from Linkopings University, either from the above address, 
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 * 
 * This program is distributed  WITHOUT ANY WARRANTY; without 
 * even the implied warranty of  MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH 
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS 
 * OF OSMC-PL. 
 * 
 * See the full OSMC Public License conditions for more details.
 * 
 */

/* $Name$ */


/* $Id$ */

header "post_include_hpp" {

#define null 0
#include "MyAST.h"

#include "../../Compiler/runtime/errorext.h"

#include "../../Compiler/runtime/error_reporting.h"
}

options {
        language = "Cpp";
}

class modelica_expression_parser extends modelica_parser;

options {
    ASTLabelType = "RefMyAST";
    defaultErrorHandler=false;
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

