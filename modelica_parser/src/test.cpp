/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
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
  lexer.setFilename(argv[1]);
  modelica_parser parser(lexer);
  parser.setFilename(argv[1]);

  antlr::ASTFactory ast_factory;
  parser.initializeASTFactory(ast_factory);
  parser.setASTFactory(&ast_factory);

  parser.stored_definition();
  RefMyAST ast = RefMyAST(parser.getAST());
  parse_tree_dumper dumper(cout);
  dumper.dump(ast);
}
