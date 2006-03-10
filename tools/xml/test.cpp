#include <iostream>
#include <fstream>
#include "modelica_lexer.hpp"
#include "modelica_parser.hpp"
#include <antlr/AST.hpp>
#include "parse_tree_dumper.hpp"

using namespace std;


int main(int argc, char **argv) {

  if (argc != 2) {
    cerr << "Usage: " << argv[0] << " filename" << endl;
    exit(1);
  }

  ifstream is(argv[1]);
  if (!is) {    
    cerr << "File \"" << argv[1] << "\" not found." << endl;
    exit(1);
  }

  modelica_lexer lexer(is);
  modelica_parser parser(lexer);
  parser.stored_definition();
  antlr::RefAST ast = parser.getAST();
  parse_tree_dumper dumper(cout);
  dumper.dump(ast);
}
