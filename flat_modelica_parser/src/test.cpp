/* 
 * This file is part of OpenModelica.
 * 
 * Copyright (c) 1998-2008, Linköpings University,
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

#include <iostream>
#include <sstream>
#include <fstream> 

#include "flat_modelica_parser.hpp"
#include "flat_modelica_lexer.hpp"
#include "parse_tree_dumper.hpp"
#include "antlr/ANTLRException.hpp"
#include "antlr/CharStreamException.hpp"
#include "antlr/TokenStreamException.hpp"
#include "antlr/RecognitionException.hpp"
#include "antlr/NoViableAltException.hpp"
#include "antlr/MismatchedTokenException.hpp"
#include "antlr/TokenStreamRecognitionException.hpp"
#include "antlr/ASTFactory.hpp"
#include "MyAST.h"

using namespace std;

int main(int argc, char **argv) {
    char* filename = argv[1];
    string filestring(filename); 
    bool debug = false;
    bool parsedump = true;
    /* 2004-10-05 adrpo moved this declaration here to 
     * have the ast initialized before getting 
     * into the code. This way, if this relation fails at least the 
     * ast is initialized */
   void* ast= null;

    //For parsing flat modelica (mof) files, if such is given
    bool parseFlatModelica=false;
    if (filestring.size()-4 == filestring.rfind(".mof")){
      parseFlatModelica=true;
    }

    std::ifstream stream(filename);
    if (!stream) {    
      cerr << "File \"" << filename << "\" not found." << endl;
      exit(1);
    }
    //bool debug = true;
    flat_modelica_lexer *flat_lex=0;
    flat_modelica_parser *flat_parse=0;
    ANTLR_USE_NAMESPACE(antlr)ASTFactory my_factory( "MyAST", MyAST::factory );
    flat_lex = new flat_modelica_lexer(stream);
    flat_lex->setFilename(filename);

    if (!stream) 
      {
	std::cerr << "Error opening file" << std::endl;
      }
    RefMyAST t;
    if (parseFlatModelica){
      //We are parsing flat modelica and not modelica
      flat_parse = new flat_modelica_parser(*flat_lex);
      flat_parse->setFilename(filename); 

      // make factory with customized type of MyAST
      flat_parse->initializeASTFactory(my_factory);
      flat_parse->setASTFactory( &my_factory );

      try{
	cout << "Parsing flat modelica" << endl;
	flat_parse->stored_definition();
	cout << "done" << endl;
	t = RefMyAST(flat_parse->getAST());
      } 
      catch (ANTLR_USE_NAMESPACE(antlr)CharStreamException &e) 
	{
	  std::cerr << "Lexical error. CharStreamException. "  << std::endl;    
	}
      catch (ANTLR_USE_NAMESPACE(antlr)TokenStreamRecognitionException &e) 
	{
	  std::cerr << "Parsing error. TokenStreamRecognitionException on line "
		    << flat_lex->getLine() << "near :"<< flat_lex->getText() << std::endl;    
	}
      catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException &e) 
	{
	  std::cerr << "[" << filestring << ":" << e.getLine() << ":" << e.getColumn() 
		    << "]: error: " << e.getMessage() << std::endl;
	}
      catch (ANTLR_USE_NAMESPACE(antlr)TokenStreamException &e) 
	{
	  std::cerr << "[" << filestring << ":" << flat_lex->getLine() << ":" << flat_lex->getColumn() 
		    << "]: error: illegal token" << std::endl;
	}
      catch (ANTLR_USE_NAMESPACE(antlr)ANTLRException &e) 
	{
	  std::cerr << "ANTLRException: " << e.getMessage() << std::endl;
	}
      catch (std::exception &e) 
	{
	  std::cerr << "Error while parsing:\n" << e.what() << "\n";
	}
      catch (...) 
	{
	  std::cerr << "Error while parsing\n";
	}

    }

    if (parsedump) 
      {
	parse_tree_dumper dumper(std::cout);
	//dumper.initializeASTFactory(factory);
	//dumper.setASTFactory(&factory);
	dumper.dump(t);
      }
	

    if (flat_parse) delete flat_parse;
    if (flat_lex) delete flat_lex;

}
