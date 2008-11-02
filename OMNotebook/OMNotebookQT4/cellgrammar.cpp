/*
------------------------------------------------------------------------------------
This file is part of OpenModelica.

Copyright (c) 1998-2005, Linköpings universitet,
Department of Computer and Information Science, PELAB
See also: www.ida.liu.se/projects/OpenModelica

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

	* Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.

    * Neither the name of Linköpings universitet nor the names of its contributors
      may be used to endorse or promote products derived from this software without
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

For more information about the Qt-library visit TrollTech:s webpage regarding
licence: http://www.trolltech.com/products/qt/licensing.html

------------------------------------------------------------------------------------
*/

//#include <antlr/CommonAST.h>
#include "NotebookLexer.hpp"
#include "NotebookParser.hpp"
#include "NotebookTreeParser.hpp"
#include <iostream>
#include <fstream>
#include <exception>



using namespace antlr;

int main(int argc, char **argv)
{
    char *filename = 0;

    if(argc == 2)
	{
	    filename = argv[argc-1];
	}
    else
	{
	    filename = "test.nb";
	}

    std::ifstream mynb(filename);

    if(!mynb)
	{
	    std::cerr << "ERROR: Could not open file: " << filename;
	    return 1;
	}

    try{
	ASTFactory myFactory;
	NotebookLexer lexer(mynb);
	NotebookParser parser(lexer);

	parser.initializeASTFactory(myFactory);
	parser.setASTFactory(&myFactory);

	parser.document();

	antlr::RefAST t = parser.getAST();

	//std::cout << t->toStringList() << std::endl;

	NotebookTreeParser *walker = new NotebookTreeParser();

	walker->document(t);

    }
    catch(std::exception &e)
	{
	    std::cerr << "exception: " << e.what() << std::endl;
	}

    mynb.close();

    return 0;
}
