
#include <iostream>
#include <strstream>
#include <fstream>

#include "modelica_lexer.hpp"
#include "modelica_parser.hpp"
#include "modelica_tree_parser.hpp"
#include "modelica_expression_parser.hpp"
#include "parse_tree_dumper.hpp"

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
  try 
    {
      std::ifstream stream(filename);

      modelica_lexer lex(stream);
      modelica_parser parse(lex);
      parse.stored_definition();
      antlr::RefAST t = parse.getAST();
      
      if (t)
	{
	  if (debug)
	    {
	      parse_tree_dumper dumper(std::cout);
	      dumper.dump(t);
	    }

	  modelica_tree_parser build;
	  void* ast = build.stored_definition(t);
	  
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
      std::cerr << "Error while parsing:\n" << e.what() << "\n";
    }
  catch (...)
    {
      std::cerr << "Error while parsing\n";
    }
  RML_TAILCALLK(rmlFC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Parser__parsestring)
{
  char* str = RML_STRINGDATA(rmlA0);
  bool debug = check_debug_flag("parsedump");
  try 
    {
      std::istrstream stream(str);

      modelica_lexer lex(stream);
      modelica_parser parse(lex);
      parse.stored_definition();
      antlr::RefAST t = parse.getAST();
      
      if (t)
	{
	  if (debug)
	    {
	      parse_tree_dumper dumper(std::cout);
	      dumper.dump(t);
	    }

	  modelica_tree_parser build;
	  void* ast = build.stored_definition(t);
	  
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
      std::istrstream stream(str);

      modelica_lexer lex(stream);
      modelica_expression_parser parse(lex);
      parse.interactiveStmt();
      antlr::RefAST t = parse.getAST();
      
      if (t)
	{
	  if (debug)
	    {
	      //std::cout << "parsedump not implemented for interactiveStmt yet"<<endl;
	      parse_tree_dumper dumper(std::cout);
	      dumper.dump(t);
	    }

	  modelica_tree_parser build;
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

