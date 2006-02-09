/*
This file is part of OpenModelica.

Copyright (c) 1998-2005, Linkopings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

* Neither the name of Linkopings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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

