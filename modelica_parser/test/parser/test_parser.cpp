
#include <antlr/Token.hpp>
#include "antlr/ANTLRException.hpp"

#include "modelica_lexer.hpp"
#include "modelica_parser.hpp"
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

	parse_tree_dumper dumper(std::cout);
	if (std::string(argv[0]) == "dot_parser")
	{
	    dumper.dump_dot(parser.getAST());
	}
	else
	{
	    dumper.dump(parser.getAST());
	}

	
    }
    catch (ANTLR_USE_NAMESPACE(antlr)ANTLRException &e)
      {
	std::cerr << "ANTLRException: " << e.getMessage() << std::endl;
	file.close();
	return EXIT_FAILURE;
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
