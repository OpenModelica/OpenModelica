#ifndef modSimPackTest_h
#define modSimPackTest_h
#include "modSimPackTest.h"
#endif    



//Dummy method to test the parser
void modSimPackTest::FlatEquation(stack< string > &eq_stack){
  cout << "Equation received: ";

  string tmp;
  while (!eq_stack.empty()){
    cout << eq_stack.top() << " ";
    eq_stack.pop();
  }
  cout << endl;
}


//Dummy method to test the parser
void modSimPackTest::FlatVariable(string type, string name, int flow, int variability, 
				  int direction, double value){

  cout << "Variable of type: \"" << type << "\" (flow=" << flow << ", variability=" 
       << variability << ", direction=" << direction << ") name: \"" << name 
       << "\" with value=" << value << endl;
}

int main(int argc, char* argv[]){
  if (argc == 2) {
    const char *filename;

    filename = argv[1];
    ifstream strm( filename );

    if (strm.is_open()) {

      flat_modelica_lexer* L = new flat_modelica_lexer(strm);
      flat_modelica_parser* P = new flat_modelica_parser(*L);
      (*P).stored_definition();
      antlr::RefAST resultTree = (antlr::RefAST)((*P).getAST());
      flat_modelica_tree_parser* T = new flat_modelica_tree_parser();
      (*T).stored_definition(resultTree);


//        parse_tree_dumper* dumper = new parse_tree_dumper(cout);
//        (*dumper).dump( (antlr::RefAST)((*P).getAST()) );
//        (*dumper).flush();


    }
  }

  return 0;

}
