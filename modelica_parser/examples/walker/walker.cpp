
//#include <antlr/Token.hpp>

#include "modelica_lexer.hpp"
#include "modelica_parser.hpp"
#include "modelica_tree_parser.hpp"
#include "parse_tree_dumper.hpp"


#include <cstdlib>
#include <fstream>
#include <iostream>

int main(int argc, char* argv[])
{
    std::ifstream file;

    if (argc != 2)
      {
  	std::cerr << "Incorrect number of arguments\n";
  	return 1;
      }
    
      file.open(argv[1]);

      if (!file)
      {
  	std::cerr << "Could not open file: " << argv[1] << "\n";
  	return 2;
      }
    
      try 
	{
	  modelica_lexer lexer(file);
	  lexer.setFilename(argv[1]);

	  modelica_parser parser(lexer);

	  parser.stored_definition();

	  antlr::RefAST ast = parser.getAST();

	  parse_tree_dumper dumper(std::cout);
	  
	  std::cout << std::flush;
	  if (ast) 
	    {
	      dumper.dump(ast);

	      modelica_tree_parser walker;

	      std::cout << "-------------- Beginning of walk-------------\n";
	      walker.stored_definition(ast);	  
	      std::cout << "---------------- Walking done ---------------\n";
	      //antlr::RefAST ast2 = walker.getAST();
	      //	      cout << ast2->toStringList() << endl;
	      //dumper.dump(ast2);
	    }
	  else
	    {
	      std::cerr << "Parse error: <NULL> AST\n";
	    }
	}
      catch(std::exception& e) 
	{
	  std::cerr << "Exception: " << e.what() << std::endl;
	  file.close();
	  return EXIT_FAILURE;
	}
  
      file.close();
      return EXIT_SUCCESS;
}
