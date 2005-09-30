/*
    Copyright PELAB, Linkoping University

    This file is part of Open Source Modelica (OSM).

    OSM is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    OSM is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with OpenModelica; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

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
#include "../values.h"
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
      while( string(buf).find(var) == string(buf).npos) {
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
