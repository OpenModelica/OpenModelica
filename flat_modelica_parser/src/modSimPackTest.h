#include<stack>
#include<iostream>
#include<fstream>
#include<string>
#include "flat_modelica_lexer.hpp"
#include "flat_modelica_parser.hpp"
#include "flat_modelica_tree_parser.hpp"
#include "parse_tree_dumper.hpp"


#ifndef COMMONAST_HPP_
#define COMMONAST_HPP_
#include "antlr/CommonAST.hpp"
#endif



class modSimPackTest{
public :
  static void FlatEquation(stack< string >&);
  static void FlatVariable(string type, string name, int flow, int variability, 
			   int direction, double value);
};
