#include "modelica_lexer.hpp"
#include "modelica_expression_parser.hpp"
#include "modelica_tree_parser.hpp"
#include "parse_tree_dumper.hpp"

#include <cstdlib>
#include <fstream>
#include <iostream>
#include <cstdio>
#include <strstream>

#include <readline/readline.h>
#include <readline/history.h>

#include "value.hpp"
#include "symboltable.hpp"

void read_and_evaluate(istream&instream);

// The symbol table
 symboltable symtab;

int main(int argc, char* argv[])
{
  
      if (argc > 2)
      {
  	std::cerr << "Incorrect number of arguments\n";
  	return EXIT_FAILURE;
      }

    
    if (argc == 1) // Interactiv mode
      {
	
	cout << "OpenModelica 0.1" << endl;
	cout << "Copyright 2002, PELAB, Linkoping University" << endl;

	bool done = false;
	while (!done)
	  {
	    char* line = readline(">>> ");
	    
	    if (!line) break;
	    if (*line == EOF) done = true;

	    if (*line)
	      {
		add_history(line);
		
		std::istrstream instream(line);
		read_and_evaluate(instream);
	      }
	    free(line);
	  }
	cout << endl;
	exit(EXIT_SUCCESS);
      }
    
    if (argc == 2) // Batch mode
      {
	std::ifstream file; 
	file.open(argv[1]);
    
	if (!file)
	  {
	    std::cerr << "Could not open file: " << argv[1] << endl;
	    return 2;
	  }

	read_and_evaluate(file);
	file.close();
      }
    return EXIT_SUCCESS;
}


void read_and_evaluate(istream& instream)
{
    modelica_lexer lexer(instream);
    //		lexer.setFilename(argv[1]);
    try
	{
	    modelica_expression_parser parser(lexer);
	    bool hide_result = parser.start_rule();
	    
	    antlr::RefAST ast = parser.getAST();
	    
	    parse_tree_dumper dumper(std::cout);
	    
	    if (ast) 
		{
		  //dumper.dump(ast);
		  
		  modelica_tree_parser walker;
		  //symboltable symtab;
		  //std::cout << "-------------- Beginning of walk-------------\n";
		  //		  value result = walker.start_expression(ast,&symtab);
		  value result = walker.start_algorithm(ast,&symtab);

		  if (!hide_result) cout << result << endl;
		  //std::cout << "---------------- Walking done ---------------\n";
		}
	    else
	      {
		std::cerr << "Parse error: <NULL> AST\n";
		
		
	      }
	}
    catch(std::exception& e) 
      {
	std::cerr << "Exception: " << e.what() << std::endl;
      }
}
