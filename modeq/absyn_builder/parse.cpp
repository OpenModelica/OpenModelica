#include <iostream>
#include <sstream>
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

using namespace std;
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
		bool debug = check_debug_flag("parsedebug");
		bool parsedump = check_debug_flag("parsedump");
		/* 2004-10-05 adrpo moved this declaration here to 
		* have the ast initialized before getting 
		* into the code. This way, if this relation fails at least the 
		* ast is initialized */
		void* ast = mk_nil();

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
		modelica_lexer *lex=0;
		modelica_parser *parse=0;
		flat_modelica_parser *flat_parse=0;
		flat_modelica_lexer *flat_lex=0;
		ANTLR_USE_NAMESPACE(antlr)ASTFactory my_factory( "MyAST", MyAST::factory );

		if (!stream) 
		{
			std::cerr << "Error opening file" << std::endl;
			RML_TAILCALLK(rmlFC);
		}
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
			std::cerr << "Parsing error. TokenStreamRecognitionException on line "
				<< flat_lex->getLine() << "near :"<< flat_lex->getText() << std::endl;
			ast = mk_nil();
		}
		catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException &e) 
		{
			std::cerr << "[" << filestring << ":" << e.getLine() << ":" << e.getColumn() 
				<< "]: error: " << e.getMessage() << std::endl;
			ast = mk_nil();
		}
		catch (ANTLR_USE_NAMESPACE(antlr)TokenStreamException &e) 
		{
			std::cerr << "[" << filestring << ":" << flat_lex->getLine() << ":" << flat_lex->getColumn() 
				<< "]: error: illegal token" << std::endl;
			ast = mk_nil();
		}
		catch (ANTLR_USE_NAMESPACE(antlr)ANTLRException &e) 
		{
			std::cerr << "ANTLRException: " << e.getMessage() << std::endl;
			ast = mk_nil();
		}
		catch (std::exception &e) 
		{
			std::cerr << "Error while parsing:\n" << e.what() << "\n";
			ast = mk_nil();
		}
		catch (...) 
		{
			std::cerr << "Error while parsing\n";
			ast = mk_nil();
		}

		//Parsing complete
		if (debug) 
		{
			std::cerr << "Parsing complete. Starting to traverse ast." << std::endl;
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
				ast = mk_nil();
				RML_TAILCALLK(rmlSC); // rmlFC
			}

			if (debug) 
			{
				std::cout << "Build done\n";
			} 

			rmlA0 = ast ? ast : mk_nil();

			// adrpo added 2004-10-27 
			if (flat_parse) delete parse;
			if (parse) delete parse;
			if (lex) delete lex;
			if (flat_lex) delete flat_lex;
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
			std::cerr << "Error building AST" << std::endl;
		}
		RML_TAILCALLK(rmlSC); // rmlFC
	}
	RML_END_LABEL



	char *get_string(std::ostringstream& s) 
	{
		char *buf=0;
		unsigned int size=0;
		string str = s.str();
		if (str.length() >= size) 
		{
			size = 2*str.length();
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

