#include <iostream>
#include <fstream>
#include <map>
#include <set>
#include <string>
#include <vector>


using namespace std;


extern "C"
{
#include <assert.h>
#include "rml.h"
#include "../absyn_builder/yacclib.h"

  map<string,int> output_var_number;
  map<string,int> input_var_number;


  
  void TORNADOEXT_5finit(void)
  {
  }
  

  RML_BEGIN_LABEL(TORNADOEXT__dump_5ftesting)
  {
    int nvars = RML_UNTAGFIXNUM(rmlA0);
    cout << "testing tornadoext" << endl
         << "================" << nvars << endl;
    
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(TORNADOEXT__get_5foutput_5fvar_5fnumber)
  {
    int nvars = RML_UNTAGFIXNUM(rmlA0);
    char* str = RML_STRINGDATA(rmlA0);
    string str_key = string(str);
    
    map<string, int>::const_iterator search;
    search = output_var_number.find(str_key);
    int ret_val = 0;
    if(search != output_var_number.end()){
      ret_val = static_cast<int>(search->second);
      ret_val += 1;
//       cout << "\nSTATE_ALG:" << str_key << " " << ret_val << nvars << endl;

    } // else {
//        cout << "\nNO STATE_ALG:" << str_key << " " << ret_val << nvars << endl;
//     }

    output_var_number[str_key] = ret_val;
    rmlA0 = (void*) mk_icon(ret_val);
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(TORNADOEXT__get_5finput_5fvar_5fnumber)
  {
    int nvars = RML_UNTAGFIXNUM(rmlA0);
    char* str = RML_STRINGDATA(rmlA0);
    string str_key = string(str);
    
    map<string, int>::const_iterator search;
    search = input_var_number.find(str_key);
    int ret_val = 0;
    if(search != input_var_number.end()){
      ret_val = static_cast<int>(search->second);
      ret_val += 1;
//       cout << "\nSTATE_ALG:" << str_key << " " << ret_val << nvars << endl;

    } // else {
//        cout << "\nNO STATE_ALG:" << str_key << " " << ret_val << nvars << endl;
//     }

    input_var_number[str_key] = ret_val;
    rmlA0 = (void*) mk_icon(ret_val);
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL


} // extern "C"
