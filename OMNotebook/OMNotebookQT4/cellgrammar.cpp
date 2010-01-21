/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
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
 * from Linköpings University, either from the above address,
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
