/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include <iostream>
#include <fstream>
#include <list>
#include <map>
#include <set>
#include <string>
#include <vector>


using namespace std;

typedef std::pair<std::string,bool> optPair;
static const optPair pairs[] = {
  optPair("translateDAEString",true),
  optPair("cevalEquation",true),
  optPair("generateBoschCode",false),
  optPair("noTearing",false),
  optPair("noCse",false),
  optPair("dynamicStateSelection", false),
  optPair("evaluatingSystem",false),
  optPair("MOOSEScaleEquations",true),
  optPair("analyticJacobian",false),
  optPair("dummyOption",false),
  optPair("logSelectedStates",false),
  optPair("checkModel",false),
  optPair("unitChecking",false),
  optPair("reportMatchingError",false),
  optPair("envCache",true),
  optPair("collectZCFromSmooth", true), // If true zero crossings are collected from expr in smooth(N, expr)
  optPair("noVectorization", false)  
};

typedef std::list<optPair> listOptPair;
static const listOptPair lst (pairs, pairs + sizeof(pairs) / sizeof(optPair) );

typedef map<std::string, bool> stringMap;
static stringMap options (lst.begin(), lst.end());
static const char *undefined = "## UNDEFINED OPTION ##";

extern "C" {

extern void OptManagerImpl__dumpOptions()
{
  cout << endl << "Option mappings, (key, value):" <<endl;
  for(stringMap::const_iterator it = options.begin(); it != options.end(); ++it)
  {
    cout <<"(" << it->first;
    cout << " ==> " << it->second << ")"<< endl;
  }
  cout << endl;
}

int OptManagerImpl__setOption(const char *strEntry, int strValue)
{
  stringMap::iterator iter = options.begin();
  iter = options.find(strEntry);
  if( iter != options.end() ){
    options[strEntry] = strValue;
    return 0;
  }
  else{
    cout << "Error, option " << strEntry << " is not defined in options-map. Every option needs to be defined at program start." << endl;
    return 1;
  }
}

int OptManagerImpl__getOption(const char *strEntry)
{
  stringMap::iterator iter = options.begin();
  iter = options.find(strEntry);
  if( iter != options.end() ) {
    return iter->second;
  } else {
    cout << "Error, option " << strEntry << " is not defined in options-map" << endl;
    return -1;
  }
}

} // extern "C"
