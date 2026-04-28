/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
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
