
#include <iostream>
#include <sstream>
#include <fstream> 

#include "modelica_lexer.hpp"
#include "modelica_parser.hpp"
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
  bool debug = check_debug_flag("parsedump");
  modelica_lexer *lex=0;
  modelica_parser *parse=0;
  ANTLR_USE_NAMESPACE(antlr)ASTFactory factory;
  try 
    {
      std::ifstream stream(filename);
      
      if (!stream) {
	std::cerr << "Error opening file" << std::endl;
	RML_TAILCALLK(rmlFC);
      }
      lex = new modelica_lexer(stream);
      //modelica_lexer lex(stream);
      parse = new modelica_parser(*lex);
      parse->initializeASTFactory(factory);
      parse->setASTFactory(&factory);

      //modelica_parser parse(lex);
      parse->stored_definition();
      antlr::RefAST t = parse->getAST();

      if (debug) {
	std::cerr << "Parsing complete. Starting to traverse ast." << std::endl;
      }
	
      if (t)
	{
	  if (debug)
	    {
	      parse_tree_dumper dumper(std::cout);
	      //dumper.initializeASTFactory(factory);
	      //dumper.setASTFactory(&factory);
	      dumper.dump(t);
	    }
	  modelica_tree_parser build;      
	  void* ast=0;
	  try {
		  build.initializeASTFactory(factory);
		  build.setASTFactory(&factory);
		  ast = build.stored_definition(t);
	  }
	  catch (ANTLR_USE_NAMESPACE(antlr)NoViableAltException &e)
	    {
	      parse_tree_dumper dumper(std::cout);
	      std::cerr << "Error walking AST while  building RML data: " << e.getMessage() << " AST:" << std::endl;
	      dumper.dump(e.node);	      
	    }
	  catch (ANTLR_USE_NAMESPACE(antlr)MismatchedTokenException &e)
	    {
	      parse_tree_dumper dumper(std::cout);
	      if (e.node) {
		std::cerr << "Error walking AST while  building RML data: " << e.getMessage() << " AST:" << std::endl;
		dumper.dump(e.node);	      
	      } else {
		std::cerr << "Error walking AST while  building RML data: " << e.getMessage() << " AST: == NULL" << std::endl;
	      }
	      throw e;
	    }
	      
	  if (debug)
	    {
	  std::cout << "Build done\n";
	    } 

	  rmlA0 = ast ? ast : mk_nil();
	  
	  RML_TAILCALLK(rmlSC); 
	}    
      else {
	std::cerr << "Error building AST" << std::endl;
      }
    } 
  catch (ANTLR_USE_NAMESPACE(antlr)CharStreamException &e) {
    std::cerr << "Lexical error. CharStreamException. "  << std::endl;    
  }
  catch (ANTLR_USE_NAMESPACE(antlr)TokenStreamRecognitionException &e) {
    std::cerr << "Parsing error. TokenStreamRecognitionException on line "  << lex->getLine() << "near :"<< lex->getText() << std::endl;    
  }
  catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException &e) {
    std::cerr << "Parsing error. RecognitionException on line "  << lex->getLine() << "near :"<< lex->getText() << std::endl;    
  }
  catch (ANTLR_USE_NAMESPACE(antlr)TokenStreamException &e) {
    std::cerr << "Lexical error. Illegal Token on line "  << lex->getLine() << "near :"<< lex->getText() << std::endl;    
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
  std::cerr << "Exiting Parse" << std::endl;
  RML_TAILCALLK(rmlFC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Parser__parsestring)
{
  char* str = RML_STRINGDATA(rmlA0);
  bool debug = check_debug_flag("parsedump");
  try 
    {
      std::istringstream stream(str);
      modelica_lexer lex(stream);
      modelica_parser parse(lex);
      ANTLR_USE_NAMESPACE(antlr)ASTFactory factory;
      parse.initializeASTFactory(factory);
      parse.setASTFactory(&factory);

      parse.stored_definition();

      antlr::RefAST t = parse.getAST();
      
      if (t)
	{
	  if (debug)
	    {
	      parse_tree_dumper dumper(std::cout);
	      //dumper.initializeASTFactory(factory);
	      //dumper.setASTFactory(&factory);
	      dumper.dump(t);
	    }

	  modelica_tree_parser build;
	  build.initializeASTFactory(factory);
	  build.setASTFactory(&factory);
	  void* ast = build.stored_definition(t);
	  
	  if (debug)
	    {
	  std::cout << "Build done\n";
	    }

	  rmlA0 = ast ? ast : mk_nil();
	  
	  RML_TAILCALLK(rmlSC); 
	}    
    } 
  catch (ANTLR_USE_NAMESPACE(antlr)CharStreamException &e) {
    std::cerr << "Lexical error. CharStreamException. "  << std::endl;
  }
  catch (std::exception &e)
    {
      std::cerr << "Error while parsing:\n" << e.what() << "\n";
    }
  catch (...)
    {
      std::cerr << "Error while parsing\n";
    }
  RML_TAILCALLK(rmlFC);
}
RML_END_LABEL


RML_BEGIN_LABEL(Parser__parsestringexp)
{
  char* str = RML_STRINGDATA(rmlA0);
  bool debug = check_debug_flag("parsedump");
  try 
    {
      std::istringstream stream(str);

      modelica_lexer lex(stream);
      modelica_expression_parser parse(lex);
      ANTLR_USE_NAMESPACE(antlr)ASTFactory factory;
      parse.initializeASTFactory(factory);
      parse.setASTFactory(&factory);
      parse.interactiveStmts();
      antlr::RefAST t = parse.getAST();
      
      if (t)
	{
	  if (debug)
	    {
	      //std::cout << "parsedump not implemented for interactiveStmt yet"<<endl;
	      //parse_tree_dumper dumper(std::cout);
	      //dumper.dump(t);
	    }

	  modelica_tree_parser build;
	  build.initializeASTFactory(factory);
	  build.setASTFactory(&factory);
	  void* ast = build.interactive_stmt(t);
	  
	  if (debug)
	    {
	  std::cout << "Build done\n";
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
      std::cerr << "Error while parsing expression\n";
    }
  RML_TAILCALLK(rmlFC);
}
RML_END_LABEL

} // extern "C"

