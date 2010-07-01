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
#include <map>
#include <set>
#include <string>
#include <vector>


using namespace std;

typedef map<std::string, bool> stringMap;
stringMap options;
const char *undefined = "## UNDEFINED OPTION ##";
extern "C"
{
#include "rml.h"

	// For all options to be used, add an initial value here.
	void OptManager_5finit(void)
	{
		options.clear();
		options.insert(std::pair<std::string,bool>("translateDAEString",true));
		options.insert(std::pair<std::string,bool>("cevalEquation",true));
		options.insert(std::pair<std::string,bool>("generateBoschCode",false));
		options.insert(std::pair<std::string,bool>("noTearing",false));
		options.insert(std::pair<std::string,bool>("noCse",false));
		options.insert(std::pair<std::string,bool>("evaluatingSystem",false));
		options.insert(std::pair<std::string,bool>("MOOSEScaleEquations",true));
		options.insert(std::pair<std::string,bool>("analyticJacobian",false));
		options.insert(std::pair<std::string,bool>("dummyOption",false));
		options.insert(std::pair<std::string,bool>("logSelectedStates",false));
		options.insert(std::pair<std::string,bool>("checkModel",false));
		options.insert(std::pair<std::string,bool>("unitChecking",false));
		options.insert(std::pair<std::string,bool>("reportMatchingError",false));
		options.insert(std::pair<std::string,bool>("envCache",true));
		options.insert(std::pair<std::string,bool>("collectZCFromSmooth", true)); // If true zero crossings are collected from expr in smooth(N, expr)
		//options.insert(std::pair<std::string,bool>("dummy",false));

/*		for(stringMap::const_iterator it = options.begin(); it != options.end(); ++it)
	    {
	        cout << "Who(key = first): " << it->first;
	        cout << " Score(value = second): " << it->second << endl;
	    }
*/
	}
	RML_BEGIN_LABEL(OptManager__dumpOptions)
	{
		cout << endl << "Option mappings, (key, value):" <<endl;
		for(stringMap::const_iterator it = options.begin(); it != options.end(); ++it)
	    {
	        cout <<"(" << it->first;
	        cout << " ==> " << it->second << ")"<< endl;
	    }
		cout << endl;
		RML_TAILCALLK(rmlSC);
	}
	RML_END_LABEL
	RML_BEGIN_LABEL(OptManager__setOption)
	{
		void *entry = rmlA0;
		void *value = rmlA1;
		char *strEntry = RML_STRINGDATA(entry);
		bool strValue = RML_PRIM_MKBOOL(value);
		stringMap::iterator iter = options.begin();
		iter = options.find(strEntry);
		if( iter != options.end() ){
			options[strEntry] = strValue;
			rmlA0 = RML_TRUE;//mk_bcon(1);
		}
		else{
			cout << "Error, option " << strEntry << " is not defined in options-map. Every option needs to be defined at program start." << endl;
			RML_TAILCALLK(rmlFC);
			rmlA0 = RML_FALSE; //mk_bcon(-1);
		}

		RML_TAILCALLK(rmlSC);
	}
	RML_END_LABEL

	RML_BEGIN_LABEL(OptManager__getOption)
	{
		void *entry = rmlA0;
		char *strEntry = RML_STRINGDATA(entry);
		stringMap::iterator iter = options.begin();
		iter = options.find(strEntry);
		if( iter != options.end() ){
			rmlA0 = iter->second? RML_TRUE:RML_FALSE;//mk_bcon(iter->second);
		}
		else{
			cout << "Error, option " << strEntry << " is not defined in options-map" << endl;
			RML_TAILCALLK(rmlFC);
		}
		RML_TAILCALLK(rmlSC);
	}
	RML_END_LABEL
} // extern "C"
