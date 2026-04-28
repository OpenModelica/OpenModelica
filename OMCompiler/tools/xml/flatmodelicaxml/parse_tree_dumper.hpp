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

#ifndef PARSE_TREE_DUMPER_H_
#define PARSE_TREE_DUMPER_H_


#ifndef COMMONAST_HPP_
#define COMMONAST_HPP_
#include "antlr/CommonAST.hpp"
#endif

#include <iostream>


class parse_tree_dumper
{
private:
    int fIndent;
    static char c1;
    static char c2;

    static char c;
    static char prefix[];

    static int indentSize;

    std::ostream &out;

public:
    parse_tree_dumper(std::ostream& os) : out(os){
	fIndent = 0;
    }

    void flush()
    {
	out.flush();
    }

    void toIndent()
    {
	if (fIndent <= 0)
	    return;
	for (int i=0; i<fIndent; i++)
	{
	    c = (c == c1 ? c2 : c1);
	    out << c;
	}
    }

    void indent(int i)
    {
	fIndent += i;
    }

    void dump(antlr::RefAST ast)
    {
	toIndent();
	out << prefix;
	if (ast == 0)
	{
	    out << "<NULL>";
	}
	else
	{
	    out << ast->toString();
	    if (ast->getFirstChild() != 0)
	    {
		out << " {" << std::endl;
		indent(indentSize);
		dump(ast->getFirstChild());
		indent(-indentSize);
		toIndent();
		out << "}" << std::endl;
	    }
	    else
	    {
		out << std::endl;
	    }
	    if (ast->getNextSibling() != 0)
	    {
		dump(ast->getNextSibling());
	    }
	}
    }
    void dump_dot(antlr::RefAST ast)
    {
	out << "digraph G {\n";
	dump_dot_recursive(ast);
	out << "}\n";
    }

    void dump_dot_recursive(antlr::RefAST ast)
    {
	if (ast == 0)
	{
	    out << "\n";
	}
	else
	{
	    out << "\"" << ast.get() << "\" [label=\"" << ast->toString() << "\" shape=\"box\"];\n";
	    antlr::RefAST current_ast = ast->getFirstChild();

	    while (current_ast != 0)
	    {
		dump_dot_recursive(current_ast);
		out << "\t\"" <<  ast.get() << "\" -> \"" << current_ast.get() << "\";\n";

		current_ast = current_ast->getNextSibling();
	    }
	}
    }

};


#endif
