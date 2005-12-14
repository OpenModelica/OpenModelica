/*
This file is part of OpenModelica.

Copyright (c) 1998-2005, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

* Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/* Interface for pltolemy plot format.
  Peter Aronsson. 2003-10-30
*/
#include <iostream>
#include <fstream>
#include <string>



using namespace std;

extern "C"
{
#include "rml.h"  
#include "../Values.h"
#include <stdio.h>
#include "../absyn_builder/yacclib.h"
void print_error_buf_impl(char*str);


  /* Given a file name and an array of variables, return the RML datastructure
     in Values for Real[size(vars,1],:] i.e. a matrix of variable values, one column for each variable. */
  void * read_ptolemy_dataset(char*filename, int size,char**vars,int datasize)
  {
    char buf[255];
    void *lst;
    void *olst;
    ifstream stream(filename);
    
    if (!stream) {
      cerr << "Error opening file" << endl;
      return NULL;
    }

    // Find interval size
    while( stream.getline(buf,255)
	   && string(buf).find("#IntervalSize") == string(buf).npos);
    string intervalText=string(buf);
    int equalPos=intervalText.find("=");
    int readIntervalSize = atoi(intervalText.substr(equalPos+1).c_str());
    // exit if intervals not compatible...
    if (datasize == 0) { 
      datasize = readIntervalSize;
    } else {
      if( readIntervalSize == 0) {
	cerr << "could not read interval size." << endl;
	print_error_buf_impl("could not read interval size.\n");
	return NULL;
      }
      if (readIntervalSize != datasize) {
	cerr << "intervalsize not matching data size." << endl;
	print_error_buf_impl("intervalsize not matching data size.\n");
	return NULL;
      }
    }
    olst = mk_nil();
    for (int i=0; i<size; i++) {
      string readstr;
      double val; char ch;
      string var(string("DataSet: ")+vars[i]);
      

      stream.seekg(0); //Reset stream
      // Search to the correct position.
      stream.getline(buf,255);
      while( string(buf).find(var) == string(buf).npos || strlen(buf) > var.length()) {
	if (!stream.getline(buf,255)) {
	  // if we reached end of file return..
	  string str=string("variable ")+ vars[i]
	    +"  not found in simulation result.\n";
	  cerr << str;
	  print_error_buf_impl((char*)str.c_str());
	  return NULL;
	}
      }

      lst = mk_nil();
      int j=0;
      while(j<datasize) {
	stream.getline(buf,255);

	if (string(buf).find("DataSet:") == 1) {
	  j = datasize;
	  break;
	}
	string values(buf);
	int commapos=values.find(",");
	val = atof(values.substr(commapos+1).c_str()); // Second value after comma
	
	lst = (void*)mk_cons(Values__REAL(mk_rcon(val)),lst);
	j++;
      }

      olst = (void*)mk_cons(Values__ARRAY(lst),olst);
    }
    olst = Values__ARRAY(olst);
    return olst;
  }

  /* Given a file name, returns the size of that simulation result in that file*/
  void * read_ptolemy_dataset_size(char*filename)
  {
    char buf[255];
    ifstream stream(filename);
    

    if (!stream) {
      cerr << "Error opening file" << endl;
      return NULL;
    }

    // Find interval size
    while( stream.getline(buf,255)
	   && string(buf).find("#IntervalSize") == string(buf).npos);

    string intervalText=string(buf);
    int equalPos=intervalText.find("=");
    int readIntervalSize = atoi(intervalText.substr(equalPos+1).c_str());
    // exit if intervals not compatible...
    if( readIntervalSize == 0) {
      cerr << "could not read interval size." << endl;
      print_error_buf_impl("could not read interval size.\n");
      return NULL;
    }
    return (void*)readIntervalSize;
  }
}
