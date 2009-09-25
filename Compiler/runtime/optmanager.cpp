/*
Copyright (c) 1998-2006, Linköpings universitet, Department of
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

#include <iostream>
#include <fstream>
#include <map>
#include <set>
#include <string>
#include <vector>


using namespace std;

typedef map<std::string, bool> stringMap;
stringMap options;
char *undefined = "## UNDEFINED OPTION ##";
extern "C"
{
#include "rml.h"
#include "../absyn_builder/yacclib.h"

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
