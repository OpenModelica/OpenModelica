/* Interface for pltolemy plot format.
  Peter Aronsson.
*/
#include <iostream>
#include <fstream>
#include <sstream>



using namespace std;

extern "C"
{
#include "rml.h"  
#include "../values.h"
#include "../absyn_builder/yacclib.h"

  /* Given a file name and an array of variables, return the RML datastructure
     in Values for Real[size(vars,1],:] i.e. a matrix of variable values, one column for each variable. */
  void * read_ptolemy_dataset(char*filename, int size,char**vars,int datasize)
  {
    char buf[255];
    void *lst;
    void *olst;
    //cout << "opening file "<<filename << endl;
    ifstream stream(filename);
    
    if (!stream) {
      cerr << "Error opening file" << endl;
      return NULL;
    }
    //cout << "Entering reading ptolemy data\n";
    olst = mk_nil();
    for (int i=0; i<size; i++) {
      string readstr;
      double val; char ch;
      string var(vars[i]);
      
      // Search to the correct position.
      //cout << "searching for " << var << endl;
      stream.seekg(0); //Reset stream
      while( stream.getline(buf,255)
	     && string(buf).find(var) == string(buf).npos) {
      }
      if (!stream.getline(buf,255)) { return NULL; }
      lst = mk_nil();
      int j=0;
      while(j<datasize) {
	stream.getline(buf,255);
	if (string(buf).find("DataSet:") == 1) {
	  j = datasize;
	  break;
	}
	string values(buf);
	//cout << "values: " << values << endl;
	int commapos=values.find(",");
	//cout << "value : " << values.substr(commapos+1) << endl;
	val = atof(values.substr(commapos+1).c_str());
	//cout <<  "got value " << val << endl;
	
	lst = (void*)mk_cons(Values__REAL(mk_rcon(val)),lst);
	j++;
      }
      //cout << "Done variable no." << i <<endl;

      olst = (void*)mk_cons(Values__ARRAY(lst),olst);
    }
    olst = Values__ARRAY(olst);
    return olst;
  }
}
