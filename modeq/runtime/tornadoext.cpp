#include <iostream>
#include <fstream>
#include <map>
#include <set>
#include <string>
#include <vector>
#include <strstream>

using namespace std;


extern "C"
{
#include <assert.h>
#include "rml.h"
#include "../absyn_builder/yacclib.h"

  string top_class;
  
  struct variable {
    string name;
    string type;
    string direction;
    int index;
    variable(string n,string val, string t){name = n;type = val; direction = t; index = -1;};
    variable(){name="";type="";direction=""; index = -1;};
  };

  map<string,map<string,variable> > generated_classes;
  map<string,variable> all_var_and_params;
  map<string,int> generated_var_types;
  
  void TORNADOEXT_5finit(void)
  {
  }
  
  int get_no_of_direction_vars_with_type(string direction, string type, map<string,variable>& variables)
  {

    map<string,variable>::const_iterator search2;    
    int return_val = 0;
    
    for(search2 = variables.begin();
        search2 != variables.end();
        ++search2)
      {
        //output << search2->second.name << " : " << search2->second.direction << " = " << search2->second.type << endl;
        if((search2->second.direction == direction)
           && (search2->second.type == type))
          {
            return_val++;
          }
      }
    return return_val;
  }
  
        
  void set_index_on_variable(string name, string class_name, int index)
  {

    map<string, map<string,variable> >::iterator search;
    search = generated_classes.find(class_name);
    
    if(search != generated_classes.end()){
      map<string,variable>::iterator search2;
      search2 = search->second.find(name);
      if(search2 != search->second.end())
        {
          search2->second.index = index;
          //cout << "FOUND:" << name << " " << class_name << " " << index << endl;
        }
      else
        {
          //cout << name << " var NAN " << class_name << " " << index << endl;
        }
            
    }else{
    //cout << name << " class NAN " << class_name << " " << index << endl;
    }

  }

  string generate_impl_code_from_class(const string& class_name, 
                                map<string,variable>& variables)
  {
    strstream output;
    string class_name_with_c = "C" + class_name;
    map<string,variable>::const_iterator search2;    
    output << class_name_with_c << "::\n";
    output << class_name_with_c << "(const wchar_t* Name)\n";
    output << "{\n";
    output << "  SetName(Name);\n";
    output << "  SetDesc(L\" \");\n\n";
    //output << "std::cout << \"new:" << class_name << "\" << std::endl;\n";
    //output << "  printf(\"GENERATING "<< class_name << "\\n\");\n";

    int no_of_input_vars = get_no_of_direction_vars_with_type(string("input"), 
                                                              string("variable"),
                                                              variables);
    if(no_of_input_vars > 0){
      output << "  SetNoInputVars(" << no_of_input_vars << ");\n\n";
    }

    int no_of_params = get_no_of_direction_vars_with_type(string(""),
                                                          string("parameter"),
                                                          variables);
    if(no_of_params > 0){
      output << "  SetNoParams(" << no_of_params << ");\n\n";
    }

    for(search2 = variables.begin();
        search2 != variables.end();
        ++search2)
      {
        if(search2->second.type == string("parameter")){
          output << "  SetParam(" << search2->second.index << ", new CParam(L\"" << search2->second.name;
          output << "\", L\"\", 0.000000, MSLE_MIN_INF, MSLE_PLUS_INF, L\"" << search2->second.name << "\"));\n";
        } 
      }
    


    int no_of_output_vars = get_no_of_direction_vars_with_type(string("output"),
                                                               string("variable"),
                                                               variables);
    if(no_of_output_vars > 0){
      output << "  SetNoOutputVars(" << no_of_output_vars << ");\n\n";
    }

    for(search2 = variables.begin();
        search2 != variables.end();
        ++search2)
      {
        if((search2->second.direction == string("input"))
           && (search2->second.type == string("variable"))){
          output << "  SetInputVar(" << search2->second.index << ", new CInputVar(L\"" << search2->second.name;
          output << "\", L\"\", 0.000000, MSLE_MIN_INF, MSLE_PLUS_INF, L\"" << search2->second.name << "\"));\n";
        } else if((search2->second.direction == string("output"))
           && (search2->second.type == string("variable"))){
          output << "  SetOutputVar(" << search2->second.index << ", new COutputVar(L\"" << search2->second.name;
          output << "\", L\"\", 0.000000, MSLE_MIN_INF, MSLE_PLUS_INF, L\"" << search2->second.name << "\"));\n";
        }
      }
    output << "\n";
    output << "  SetNoIndepVars(1);\n\n";
    output << "  SetIndepVar(0, new CIndepVar(L\"t\",L\"d\", 0.000000, 0.000000, MSLE_PLUS_INF, L\"t\"));\n\n";

    int no_of_state_vars = get_no_of_direction_vars_with_type(string(""),
                                                              string("state"),
                                                              variables);
    if(no_of_state_vars > 0){
      output << "  SetNoDerStateVars(" << no_of_state_vars << ");\n\n";
    }

    for(search2 = variables.begin();
        search2 != variables.end();
        ++search2)
      {
        if(search2->second.type == string("state")){
          output << "  SetDerStateVar(" << search2->second.index << ", new CDerStateVar(L\"" << search2->second.name;
          output << "\", L\"\", 0.000000, MSLE_MIN_INF, MSLE_PLUS_INF, L\"" << class_name << "\"));\n";
        } 
      }
   //fixme der state var
    output << "}\n\n";
    output << "void " << class_name_with_c << "::\n";
    output << "ComputeOutput()\n{\n}\n\n";
    output << "void " << class_name_with_c << "::\n";
    output << "ComputeTerminal()\n{\n}\n\n";
    output << "void " << class_name_with_c << "::\n";
    output << "ComputeState()\n{\n}\n\n";
    output << "void " << class_name_with_c << "::\n";
    output << "ComputeInitial()\n{\n}\n\n";
    output << ends;
    return string(output.str());
    
  }

  string generate_header_code_from_class(const string& class_name)
  {
    strstream output;
    string class_name_with_c = "C" + class_name;
    output << "class " << class_name_with_c << " : public Tornado::CDAEModel\n";
    output << "{\n";
    output << "  public:\n\n";
    output << "    " << class_name_with_c << "(const wchar_t* Name);\n\n";
    output << "  public:\n\n";
    output << "    void ComputeInitial();\n";
    output << "    void ComputeTerminal();\n";
    output << "    void ComputeState();\n";
    output << "    void ComputeOutput();\n";
    output << "};\n\n";
    output << ends;
    return string(output.str());
    
  }
 

  RML_BEGIN_LABEL(TORNADOEXT__dump_5ftesting)
  {
    
    map<string, map<string,variable> >::iterator search;
    map<string,variable>::const_iterator search2;    
    cout << "=============== dumping TORNADOEXT ====================\n";
    for(search = generated_classes.begin();
        search != generated_classes.end();
        ++search)
      {
        cout << "\n -------------- class: " << search->first << endl;
        for(search2 = search->second.begin();
            search2 != search->second.end();
            ++search2)
          {
            cout << search2->second.name << " : " << search2->second.direction << " = " << search2->second.type << " index: " << search2->second.index << endl;
          }
      }
    cout << "-----------------------------------\n";
    for(search2 = all_var_and_params.begin();
        search2 != all_var_and_params.end();
        ++search2)
      {
        cout << search2->first << "  " << search2->second.name << " : " << search2->second.direction << " = " << search2->second.type << " index: " << search2->second.index << endl;
      }
        
   cout << "======================================================\n";
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(TORNADOEXT__get_5fvar_5findex)
  {
    char* str = RML_STRINGDATA(rmlA0);
    string variable_name = string(str);
    char* class_str = RML_STRINGDATA(rmlA1);
    string class_str_key = string(class_str);
//     char* direction_str = RML_STRINGDATA(rmlA2);
//     string direction = string(direction_str);
//     char* type_str = RML_STRINGDATA(rmlA3);
//     string type = string(direction_str);
    int ret_val = -2;

    bool debug_found = false;
    
    map<string, map<string,variable> >::iterator search;
    search = generated_classes.find(class_str_key);
    
    if(search != generated_classes.end()){
      map<string,variable>::const_iterator search2;
      search2 = search->second.find(variable_name);
      if(search2 != search->second.end())
        {
          debug_found = true;
          ret_val = search2->second.index;
        }           

    }
    //cout << (debug_found ? "FOUND  " : "NOT FOUND ") << "TORNADOEXT " << variable_name << " in class  " << class_str_key << " index: "<< ret_val<<  endl;

    rmlA0 = (void*) mk_icon(ret_val);
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL





  RML_BEGIN_LABEL(TORNADOEXT__add_5fvariable_5fto_5fclass)
  {
    char* class_name = RML_STRINGDATA(rmlA0);
    char* variable_name = RML_STRINGDATA(rmlA1);
    char* type = RML_STRINGDATA(rmlA2);
    char* direction = RML_STRINGDATA(rmlA3);
    string variable_name_str = string(variable_name);
    variable var(variable_name_str,string(type),string(direction));

    string str_key = string(class_name);
    
    //cout << "adding var: " << variable_name_str << " to class " << str_key << endl;

    map<string, map<string,variable> >::iterator search;
    search = generated_classes.find(str_key);
    
    if(search == generated_classes.end()){
      map<string,variable> var_list;
      // no class exist so the index is 0
      var.index = 0;
      var_list[variable_name_str] = var;
      generated_classes[str_key] = var_list;
      //cout << "\nSTATE_ALG:" << str_key << " " << ret_val << nvars << endl;

    }  else {
      map<string,variable>::const_iterator search2;
      //count the already added variables with same type and direction
      var.index = get_no_of_direction_vars_with_type(var.direction,var.type,search->second);
      search2 = search->second.find(variable_name_str);
      if(search2 == search->second.end())
        {
          
          search->second[variable_name_str] = var;
        }           
//        cout << "\nNO STATE_ALG:" << str_key << " " << ret_val << nvars << endl;

    }

    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

//   RML_BEGIN_LABEL(TORNADOEXT__set_5ftop_5fmodel)
//   {
//     char* class_name = RML_STRINGDATA(rmlA0);
//     top_class = string(class_name);
//     RML_TAILCALLK(rmlSC);
//   }
//   RML_END_LABEL

  
  RML_BEGIN_LABEL(TORNADOEXT__get_5fhierachical_5fcode)
  {
    char* class_name = RML_STRINGDATA(rmlA0);
    top_class = string(class_name);
    ostrstream output_impl;
    ostrstream output_header;
    
    map<string, map<string,variable> >::iterator search;
    map<string,variable>::const_iterator search2;    

    for(search = generated_classes.begin();
        search != generated_classes.end();
        ++search)
      {
        if(search->first != class_name){
          output_impl << generate_impl_code_from_class(search->first, search->second);
          output_header << generate_header_code_from_class(search->first);
//           output_impl << "\n -------------- class: " << search->first << endl;
//           for(search2 = search->second.begin();
//               search2 != search->second.end();
//               ++search2)
//             {
//               output_impl << search2->second.name << " : " << search2->second.direction << " = " << search2->second.type << endl;
//             }
        }
      }
        
    output_impl << ends;
    output_header << ends;

    rmlA0 = (void*) mk_scon(output_header.str());
    rmlA1 = (void*) mk_scon(output_impl.str());

    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL
  
  RML_BEGIN_LABEL(TORNADOEXT__add_5fvariable_5ffor_5findex)
  {
    char* class_name = RML_STRINGDATA(rmlA0);
    char* variable_name = RML_STRINGDATA(rmlA1);
    char* type = RML_STRINGDATA(rmlA2);
    string type_str = string(type);
    string variable_name_str = string(variable_name);
    variable var(variable_name_str,string(type),string(""));

    string str_key = string(class_name) + "." + string(variable_name);
    
    //cout << "adding var: " << variable_name_str << " to class " << str_key << endl;

    map<string,variable>::iterator search;
    map<string,int>::iterator search_index;
    int index = 0;
    search_index = generated_var_types.find(type_str);
    if(search_index != generated_var_types.end()) {
      index = search_index->second + 1;
      
    }
    generated_var_types[type_str] = index;
    var.index = index;
      
    search = all_var_and_params.find(str_key);
    if(search == all_var_and_params.end()){
      all_var_and_params[str_key] = var;
    }else{
      //cout << "THIS: " << str_key << "has already been generated" << endl;
    }

    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(TORNADOEXT__get_5fflat_5fvar_5findex)
  {
    char* variable_name = RML_STRINGDATA(rmlA0);
    char* class_name = RML_STRINGDATA(rmlA1);

    string str_key = string(class_name) + "." + string(variable_name);
    
    //cout << "str_key " << str_key << endl;
    
    int ret_val = -1;
    map<string,variable>::iterator search;
    search = all_var_and_params.find(str_key);
    if(search != all_var_and_params.end()){
      ret_val = search->second.index;
    }
    
    rmlA0 = (void*) mk_icon(ret_val);
 
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL 

  RML_BEGIN_LABEL(TORNADOEXT__get_5fno_5fof_5fvars_5fwith_5ftype)
  {
    char* type_name = RML_STRINGDATA(rmlA0);

    string str_key = string(type_name);
    
    //cout << "str_key " << str_key << endl;
    
    int ret_val = 0;
    map<string,int>::iterator search;
    search = generated_var_types.find(str_key);
    if(search != generated_var_types.end()){
      ret_val = search->second + 1;
    }
    
    rmlA0 = (void*) mk_icon(ret_val);
 
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL 


} // extern "C"
