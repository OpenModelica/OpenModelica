#ifndef PARSE_TREE_DUMPER_H_
#define PARSE_TREE_DUMPER_H_

#include "antlr/CommonAST.hpp"
#include <iostream>
#include "MyAST.h"

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

    void dump(RefMyAST ast)
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
		dump( RefMyAST(ast->getFirstChild()) );
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
		dump(RefMyAST(ast->getNextSibling()));
	    }
	}
    }
    void dump_dot(RefMyAST ast)
    {
	out << "digraph G {\n";
	dump_dot_recursive(ast);
	out << "}\n";
    }

    void dump_dot_recursive(RefMyAST ast)
    {
	if (ast == 0)
	{
	    out << "\n";
	}
	else
	{
	    out << "\"" << ast.get() << "\" [label=\"" << ast->toString() << "\" shape=\"box\"];\n";
	    RefMyAST current_ast = RefMyAST(ast->getFirstChild());

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
