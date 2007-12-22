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
#include <list>
#include <string>


#include <fstream> 

#include "modelica_lexer.hpp"
#include "modelica_parser.hpp"
#include "flat_modelica_parser.hpp"
#include "flat_modelica_lexer.hpp"
#include "modelica_tree_parser.hpp"
#include "modelica_expression_parser.hpp"
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

#include "../runtime/errorext.h"

using namespace std;
string modelicafilename; // The filename for the parsed file.
bool modelicafileReadOnly; // True if file is read only.
extern "C"
{



	int check_debug_flag(char const* strdata);

#include <errno.h>


	void Parser_5finit(void)
	{
	}


	RML_BEGIN_LABEL(Parser__parse)
	{
		char* filename = RML_STRINGDATA(rmlA0);
		string filestring(filename);
		bool debug = false, parsedump = false, parseonly = false;
		debug      = check_debug_flag("parsedebug");
		parsedump  = check_debug_flag("parsedump");
		parseonly  = check_debug_flag("parseonly");
		/* 2004-10-05 adrpo moved this declaration here to 
		* have the ast initialized before getting 
		* into the code. This way, if this relation fails at least the 
		* ast is initialized */
		void* ast = mk_nil();
		
		if (debug) { std::cerr << "Starting parsing of file:" << filename << std::endl; }

		// Set global filename, used to populate elements with
		// corresponding file name.
		modelicafilename=filestring;

		//For parsing flat modelica (mof) files, if such is given
		bool parseFlatModelica=false;
		if (filestring.size()-4 == filestring.rfind(".mof"))
		{
			parseFlatModelica=true;
			if (debug) { std::cerr << "File:" << filename << " is a flat Modelica file." << std::endl; }			
		}
		std::ifstream checkROfile(filename,ios::out); // open file in write mode to check if readonly
		modelicafileReadOnly = !checkROfile;
		if (debug && modelicafileReadOnly) { std::cerr << "File:" << filename << " is read-only." << std::endl; }	
		
		std::ifstream stream(filename);
		if (!stream) 
		{
		  std::list<std::string> tokens;
		  tokens.push_back(std::string(filename));
		  add_message(85, /* Error opening file,see Error.rml*/
			      "TRANSLATION",
			      "ERROR",
			      "Error opening file %s",
			      tokens);
		  RML_TAILCALLK(rmlFC);
		}
		//bool debug = true;
		modelica_lexer *lex=0;
		modelica_parser *parse=0;
		flat_modelica_parser *flat_parse=0;
		flat_modelica_lexer *flat_lex=0;
		ANTLR_USE_NAMESPACE(antlr)ASTFactory my_factory( "MyAST", MyAST::factory );

		RefMyAST t = 0;
		try
		{
			if (parseFlatModelica){
				//We are parsing flat modelica and not modelica
				flat_lex = new flat_modelica_lexer(stream);
				flat_lex->setFilename(filename);

				flat_parse = new flat_modelica_parser(*flat_lex);
				//flat_parse->setFilename(filename); 

				// make factory with customized type of MyAST
				flat_parse->initializeASTFactory(my_factory);
				flat_parse->setASTFactory( &my_factory );

				flat_parse->stored_definition();
				t = RefMyAST(flat_parse->getAST());
			}
			else{
				//We are parsing regular modelica
				lex = new modelica_lexer(stream);
				lex->setFilename(filename);

				parse = new modelica_parser(*lex);
				//parse->setFilename(filename); 

				// make factory with customized type of MyAST
				parse->initializeASTFactory(my_factory);
				parse->setASTFactory( &my_factory );

				parse->stored_definition();

				t = RefMyAST(parse->getAST());
			}
		} 
		catch (ANTLR_USE_NAMESPACE(antlr)CharStreamException &e) 
		{
			std::cerr << "Lexical error. CharStreamException. "  << std::endl;
			ast = mk_nil();
		}
		catch (ANTLR_USE_NAMESPACE(antlr)TokenStreamRecognitionException &e) 
		{
		  modelica_lexer *currentLex=0;
		  
		  if (parseFlatModelica) {
		    currentLex = (modelica_lexer*)flat_lex;
		  }
		  else {
		    currentLex = lex;
		  }
		  std::list<std::string> tokens;
		  tokens.push_back(std::string(currentLex->getText()));
		  add_source_message(1, /* syntax error, see Error.rml */
				     "SYNTAX",
				     "ERROR",
				     "Syntax error near: %s",
				     tokens,
				     currentLex->getLine(),
				     currentLex->getColumn(),
				     currentLex->getLine(),
				     currentLex->getColumn(),
				     false,
				     filename);
		  ast = mk_nil();
		}
		catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException &e) 
		{
		  std::list<std::string> tokens;
		  tokens.push_back(std::string(e.getMessage()));
		  add_source_message(2, /* Grammar error, see Error.rml */
				     "GRAMMAR",
				     "ERROR",
				     "Parse error: %s",
				     tokens,
				     e.getLine(),
				     e.getColumn(),
				     e.getLine(),
				     e.getColumn(),
				     false,
				     filename);
		  ast = mk_nil();
		}
		catch (ANTLR_USE_NAMESPACE(antlr)TokenStreamException &e) 
		{
		  std::list<std::string> tokens;
		  tokens.push_back(std::string(e.getMessage()));
		  add_source_message(2, /* Grammar error, see Error.rml */
				     "GRAMMAR",
				     "ERROR",
				     "Parse error: %s",
				     tokens,
				     0,
				     0,
				     0,
				     0,
				     false,
				     filename);
		  ast = mk_nil();
		}
		catch (ANTLR_USE_NAMESPACE(antlr)ANTLRException &e) 
		{
		  std::list<std::string> tokens;
		  tokens.push_back(std::string("while parsing:")+
				   std::string(e.getMessage()));
		  add_source_message(63, /* Internal error, see Error.rml */
				     "TRANSLATION",
				     "ERROR",
				     "Internal error %s",
				     tokens,
				     0,
				     0,
				     0,
				     0,
				     false,
				     filename);
		  ast = mk_nil();
		}
		catch (std::exception &e) 
		{
		  std::list<std::string> tokens;
		  tokens.push_back(std::string("while parsing:"));
		  add_source_message(63, /* Internal error, see Error.rml */
				     "TRANSLATION",
				     "ERROR",
				     "Internal error %s",
				     tokens,
				     0,
				     0,
				     0,
				     0,
				     false,
				     filename);
		  ast = mk_nil();
		}
		catch (...) 
		  {
		    std::list<std::string> tokens;
		    tokens.push_back(std::string("while parsing:"));
		    add_source_message(63, /* Internal error, see Error.rml */
				       "TRANSLATION",
				       "ERROR",
				       "Internal error %s",
				       tokens,
				       0,
				       0,
				       0,
				       0,
				       false,
				       filename);
		    ast = mk_nil();
		}
				
		//Parsing complete
		if (debug) 
		{
			std::cerr << "Parsing of: [" << filename << "] complete. Starting to traverse ast." << std::endl;
		}
				
		if (t) //Did we get at AST?
		{ 
			if (parsedump) 
			{
				parse_tree_dumper dumper(std::cout);
				//dumper.initializeASTFactory(factory);
				//dumper.setASTFactory(&factory);
				dumper.dump(t);
			}
			
			if (parseonly) /* only do the parsing, do not build the AST and return a null ast! */ 
			{
				rmlA0 = Absyn__PROGRAM(mk_nil(), Absyn__TOP);
				RML_TAILCALLK(rmlSC);
			}		
			
			
			modelica_tree_parser build;      
			try 
			{
				build.initializeASTFactory(my_factory);
				build.setASTFactory(&my_factory);
				ast = build.stored_definition(t);
			}
			catch (ANTLR_USE_NAMESPACE(antlr)NoViableAltException &e) 
			{
				std::cerr << "1 Error walking AST while building RML data: " 
					<< e.getMessage() << " AST:" << std::endl;
				parse_tree_dumper dumper(std::cerr);
				dumper.dump(RefMyAST(e.node));	 
				ast = mk_nil();
				modelicafilename=string("");
				RML_TAILCALLK(rmlFC);
			}
			catch (ANTLR_USE_NAMESPACE(antlr)MismatchedTokenException &e) 
			{				
				if (e.node) 
				{
					std::cerr << "2 Error walking AST while  building RML data: " 
						<< e.getMessage() << " AST:" << std::endl;
					parse_tree_dumper dumper(std::cerr);
					dumper.dump(RefMyAST(e.node));	      
				} 
				else 
				{
					std::cerr << "3 Error walking AST while  building RML data: " 
						<< e.getMessage() << " AST: == NULL" << std::endl;
				}

				// adrpo added 2004-10-27 
				if (parse) delete parse;
				if (flat_parse) delete parse;
				if (lex) delete lex;
				modelicafilename=string("");
				RML_TAILCALLK(rmlFC); // rmlFC
			}
			modelicafilename=string("");
			if (debug) 
			{
				std::cout << "Build done\n";
			} 

			
			rmlA0 = ast;

			// adrpo added 2004-10-27 
			if (flat_parse) delete parse;
			if (parse) delete parse;
			if (lex) delete lex;
			if (flat_lex) delete flat_lex;

			if (!ast) {
			  RML_TAILCALLK(rmlFC); 
			}
			RML_TAILCALLK(rmlSC); 
		}    
		else 
		{
			// adrpo added 2004-10-27 
			if (flat_parse) delete flat_parse;
			if (parse) delete parse;
			if (lex) delete lex;
			if (flat_lex) delete flat_lex;
			ast = mk_nil();
			//std::cerr << "Error building AST" << std::endl;
		}

		RML_TAILCALLK(rmlFC); // rmlFC
	}
	RML_END_LABEL



	char *get_string(std::ostringstream& s) 
	{
		char *buf=0;
		unsigned int size=0;
		string str = s.str();
		if (str.length() >= size) 
		{
			size = (unsigned int)2*str.length();
			if (buf)
				delete [] buf;
			buf = new char[size];
		}
		strcpy(buf,str.c_str());
		return buf;
	}


	RML_BEGIN_LABEL(Parser__parsestring)
	{
		std::ostringstream stringStream;

		char* str = RML_STRINGDATA(rmlA0);
		bool a0set=false;
		bool a1set=false;
		bool debug = check_debug_flag("parsedump");
		std::istringstream stream(str);
		modelicafileReadOnly = false;
		modelica_lexer lex(stream);
		modelica_parser parse(lex);

		/* 2004-10-05 adrpo moved this declaration here to 
		* have the ast initialized before getting 
		* into the code. This way, if this relation fails at least the 
		* ast is initialized */
		void* ast = mk_nil();

		/* adrpo added 2004-10-27 
		* I use this to delete [] the temp allocation of get_string(...)
		*/
		char* getStringHolder = NULL;

		try 
		{
			ANTLR_USE_NAMESPACE(antlr)ASTFactory my_factory( "MyAST", MyAST::factory );

			parse.initializeASTFactory(my_factory);
			parse.setASTFactory(&my_factory);

			parse.stored_definition();

			RefMyAST t = RefMyAST(parse.getAST());


			if (t) 
			{
				if (debug) 
				{
					parse_tree_dumper dumper(std::cerr);
					//dumper.initializeASTFactory(factory);
					//dumper.setASTFactory(&factory);
					dumper.dump(t);
				}

				modelica_tree_parser build;
				build.initializeASTFactory(my_factory);
				build.setASTFactory(&my_factory);
				ast = build.stored_definition(t);

				if (debug) { std::cerr << "Build done\n"; }

				rmlA0 = ast ? ast : mk_nil(); a0set=true;
				rmlA1 = mk_scon("Ok"); a1set=true;

				RML_TAILCALLK(rmlSC); 
			}
			else 
			{
				rmlA0 = mk_nil(); a0set=true;
				rmlA1 = mk_scon("Internal error: parse tree null"); a1set=true;
				RML_TAILCALLK(rmlSC); 
			}
		}
		catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException &e) 
		{
			stringStream << "[" << e.getLine() << ":" << e.getColumn() 
				<< "]: error: " << e.getMessage() << std::endl;
			//		std::cerr << stringStream.str().c_str();
			rmlA0 = mk_nil(); a0set=true;
			rmlA1 = mk_scon((getStringHolder = get_string(stringStream))); a1set=true;
		}
		catch (ANTLR_USE_NAMESPACE(antlr)CharStreamException &e) 
		{
			//		std::cerr << "Lexical error (CharStreamException). "  << std::endl;    
			rmlA0 = mk_nil(); a0set=true;
			rmlA1 = mk_scon("[-,-]: internal error: lexical error"); a1set=true;
		}
		catch (ANTLR_USE_NAMESPACE(antlr)TokenStreamException &e) 
		{
			stringStream << "[" << lex.getLine() << ":" << lex.getColumn() 
				<< "]: error: illegal token" << std::endl;
			//		std::cerr << stringStream.str().c_str();
			rmlA0 = mk_nil(); a0set=true;
			rmlA1 = mk_scon((getStringHolder = get_string(stringStream))); a1set=true;
		}
		catch (ANTLR_USE_NAMESPACE(antlr)ANTLRException &e) 
		{
			//		std::cerr << "ANTLRException: " << e.getMessage() << std::endl;
			stringStream << "[-,-]: internal error: " << e.getMessage() << std::endl;
			rmlA0 = mk_nil(); a0set=true;
			rmlA1 = mk_scon((getStringHolder = get_string(stringStream))); a1set=true;
		}
		catch (std::exception &e) 
		{
			//		std::cerr << "Error while parsing: " << e.what() << "\n";
			stringStream << "[-,-]: internal error: " << e.what() << std::endl;
			rmlA0 = mk_nil(); a0set=true;
			rmlA1 = mk_scon((getStringHolder = get_string(stringStream))); a1set=true;
		}
		catch (...) 
		{
			//		std::cerr << "Error while parsing\n";
			rmlA0 = mk_nil(); a0set=true;
			rmlA1 = mk_scon("[-,-]: internal error"); a1set=true;
		}

		/* adrpo added 2004-10-27 
		* no need for getStringHolder temp value allocated from get_string
		*/
		if (getStringHolder) delete [] getStringHolder; 

		if (! a0set) 
		{
			rmlA0 = mk_nil(); a0set=true;
		}
		if (! a1set) 
		{
			rmlA1 = mk_scon("internal error"); a1set=true;
		}
		RML_TAILCALLK(rmlSC); 
	}
	RML_END_LABEL


		RML_BEGIN_LABEL(Parser__parsestringexp)
	{
		char* str = RML_STRINGDATA(rmlA0);
		std::ostringstream stringStream;
		bool debug = check_debug_flag("parsedump");
		/* 2004-10-05 adrpo moved this declaration here to 
		* have the ast initialized before getting 
		* into the code. This way, if this relation fails at least the 
		* ast is initialized */
		void* ast = mk_nil();


		/* adrpo added 2004-10-27 
		* I use this to delete [] the temp allocation of get_string(...)
		*/
		char* getStringHolder = NULL;


		try 
		{
			std::istringstream stream(str);
			modelicafileReadOnly = false;
			modelica_lexer lex(stream);
			modelica_expression_parser parse(lex);
			ANTLR_USE_NAMESPACE(antlr)ASTFactory factory;
			parse.initializeASTFactory(factory);
			parse.setASTFactory(&factory);
			parse.interactiveStmts();
			RefMyAST t = RefMyAST(parse.getAST());

			if (t) 
			{
				if (debug) 
				{
					std::cerr << "parsedump not implemented for interactiveStmt yet"<<endl;
					//parse_tree_dumper dumper(std::cerr);
					//dumper.dump(t);
				}

				modelica_tree_parser build;
				build.initializeASTFactory(factory);
				build.setASTFactory(&factory);
				ast = build.interactive_stmt(t);

				if (debug) 
				{
					std::cerr << "Build done\n";
				}

				rmlA0 = ast ? ast : mk_nil();
				rmlA1 = mk_scon("Ok");

				RML_TAILCALLK(rmlSC); 
			}
			else 
			{
				rmlA0 = mk_nil();
				rmlA1 = mk_scon("parse tree null");
			}
		} 
		catch (ANTLR_USE_NAMESPACE(antlr)ANTLRException &e) 
		{
			//std::cerr << "Error while parsing expression:\n" << e.getMessage() << "\n";
			stringStream << "[-,-]: internal error: " << e.getMessage() << std::endl;
			rmlA0 = mk_nil();
			rmlA1 = mk_scon((getStringHolder = get_string(stringStream)));
		}
		catch (std::exception &e) 
		{
			//std::cerr << "Error while parsing expression:\n" << e.what() << "\n";
			stringStream << "[-,-]: internal error: " << e.what() << std::endl;
			rmlA0 = mk_nil();
			rmlA1 = mk_scon((getStringHolder = get_string(stringStream)));
		}
		catch (...) 
		  {
			//std::cerr << "Error while parsing expression\n";
			stringStream << "Error while parsing expression. Unknown exception in parse.cpp." << std::endl;
			rmlA0 = mk_nil();
			rmlA1 = mk_scon((getStringHolder = get_string(stringStream)));
		}

		/* adrpo added 2004-10-27 
		* no need for getStringHolder temp value allocated from get_string
		*/
		if (getStringHolder) delete [] getStringHolder; 


		RML_TAILCALLK(rmlSC);
	}
	RML_END_LABEL


		RML_BEGIN_LABEL(Parser__parseexp)
	{
		char * filename = RML_STRINGDATA(rmlA0);
		bool debug = check_debug_flag("parsedump");

		/* 2004-10-05 adrpo moved this declaration here to 
		* have the ast initialized before getting 
		* into the code. This way, if this relation fails at least the 
		* ast is initialized */
		void* ast = mk_nil();

		try 
		{
			std::ifstream stream(filename);
			modelicafileReadOnly = false;
			modelica_lexer lex(stream);
			modelica_expression_parser parse(lex);
			ANTLR_USE_NAMESPACE(antlr)ASTFactory factory;
			parse.initializeASTFactory(factory);
			parse.setASTFactory(&factory);
			parse.interactiveStmts();
			RefMyAST t = RefMyAST(parse.getAST());

			if (t) 
			{
				if (debug) 
				{
					//std::cerr << "parsedump not implemented for interactiveStmt yet"<<endl;
					parse_tree_dumper dumper(std::cerr);
					dumper.dump(t);
				}

				modelica_tree_parser build;
				build.initializeASTFactory(factory);
				build.setASTFactory(&factory);
				ast = build.interactive_stmt(t);

				if (debug) 
				{
					std::cerr << "Build done\n";
				}

				rmlA0 = ast ? ast : mk_nil();

				RML_TAILCALLK(rmlSC); 
			}    
		} 
		catch (std::exception &e) 
		{
			std::cerr << "Error while parsing expression:\n" << e.what() << "\n";
		}
		catch (...) 
		{
			std::cerr << "Error while parsing expression: Unknown exception\n";
		}
		rmlA0 = mk_nil();
		RML_TAILCALLK(rmlFC);
	}
	RML_END_LABEL

} // extern "C"

