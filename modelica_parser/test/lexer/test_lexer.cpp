
#include <antlr/Token.hpp>

#include "modelica_lexer.hpp"
#include "token_names.hpp"

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
    
    std::ifstream token_file("modelicaTokenTypes.txt");
    if (!token_file)
    {
	std::cerr << "Could not open token file\n";
	return 3;
    }


    try 
    {
	token_names names(token_file);

	modelica_lexer lexer(file);
	lexer.setFilename(argv[1]);

	while (1)
	{
	    antlr::RefToken tok = lexer.nextToken();
	    if (tok->getType() < antlr::Token::MIN_USER_TYPE)
	    {
		switch (tok->getType())
		{
		    case antlr::Token::NULL_TREE_LOOKAHEAD:
			std::cerr << "\n** NULL_TREE_LOOKAHEAD **\n";
			break;
		    case antlr::Token::INVALID_TYPE:
			std::cerr << "\n** INVALID_TYPE **\n";
			break;
		    case antlr::Token::SKIP:
			std::cerr << "\n** SKIP **\n";
			break;
		    case antlr::Token::EOF_TYPE:
			break;
		    default:
			std::cerr << "\n** UNKNOWN_ERROR **\n";
			break;			
		}
		break;
	    }
	    
	    std::cout << names.name(tok->getType())
		      << " (" << tok->getLine() << ", " << tok->getColumn() << ")"
		      << " | " << tok->getText() << "\n";
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
