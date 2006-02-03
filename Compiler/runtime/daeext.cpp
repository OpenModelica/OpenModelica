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


  std::set<int> e_mark;
  std::set<int> differentiated_mark;
  std::set<int> v_mark;


  std::vector<int> number;
  std::vector<int> lowlink;
  std::vector<int> v;
  std::vector<int> f;

  void DAEEXT_5finit(void)
  {
  }
  
  RML_BEGIN_LABEL(DAEEXT__init_5fmarks)
  {

    int nvars = RML_UNTAGFIXNUM(rmlA0);
    int neqns = RML_UNTAGFIXNUM(rmlA1);
    //cout << "init marks n= " << nvars << endl;
    v_mark.clear();
    e_mark.clear();
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL
  
  RML_BEGIN_LABEL(DAEEXT__e_5fmark)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    e_mark.insert(e_mark.begin(),i);
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__v_5fmark)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    v_mark.insert(v_mark.begin(),i);
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__get_5fv_5fmark)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);

    rmlA0 = v_mark.find(i) != v_mark.end() ? RML_TRUE : RML_FALSE;
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__get_5fe_5fmark)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    //cout << "get_e_mark[" << i << "] == " << e_mark[i-1] << endl;
    rmlA0 = e_mark.find(i) != e_mark.end() ? RML_TRUE : RML_FALSE;
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__get_5fmarked_5feqns)
  {
    std::set<int>::iterator it;
    rmlA0 = mk_nil();
    for (it=e_mark.begin(); it != e_mark.end(); it++) {
      rmlA0 = mk_cons(mk_icon(*it),rmlA0);
    }
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__mark_5fdifferentiated)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    differentiated_mark.insert(differentiated_mark.begin(),i);
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__get_5fdifferentiated_5feqns)
  {
    std::set<int>::iterator it;
    rmlA0 = mk_nil();
    for (it=differentiated_mark.begin(); it != differentiated_mark.end(); it++) {
      rmlA0 = mk_cons(mk_icon(*it),rmlA0);
    }
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__get_5fmarked_5fvariables)
  {
    std::set<int>::iterator it;
    rmlA0 = mk_nil();
    for (it=v_mark.begin(); it != v_mark.end(); it++) {
      rmlA0 = mk_cons(mk_icon(*it),rmlA0);
    }
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__init_5flowlink)
  {
    int nvars = RML_UNTAGFIXNUM(rmlA0);
    //cout << "init lowlink n= " << nvars << endl;
    lowlink.reserve(nvars);

    for (int i =0; i < nvars; i++) {
      lowlink[i]=0;
    }
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__init_5fnumber)
  {
    int nvars = RML_UNTAGFIXNUM(rmlA0);
    //cout << "init number n= " << nvars << endl;
    number.reserve(nvars);

    for (int i =0; i < nvars; i++) {
      number[i]=0;
    }
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL
  
  RML_BEGIN_LABEL(DAEEXT__set_5flowlink)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    int val = RML_UNTAGFIXNUM(rmlA1);
    lowlink[i-1]=val;
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL
  
  RML_BEGIN_LABEL(DAEEXT__set_5fnumber)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    int val = RML_UNTAGFIXNUM(rmlA1);
    number[i-1]=val;
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__get_5fnumber)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    rmlA0 = (void*)mk_icon(number[i-1]);
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__get_5flowlink)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    rmlA0 = (void*)mk_icon(lowlink[i-1]);
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL


  RML_BEGIN_LABEL(DAEEXT__dump_5fmarked_5fequations)
  {
    int nvars = RML_UNTAGFIXNUM(rmlA0);
    cout << "marked equations" << endl
	 << "================" << endl;
    for (std::set<int>::iterator i =e_mark.begin() ; i != e_mark.end(); i++) {
      cout << "eqn " << *i << endl;
    }
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__dump_5fmarked_5fvariables)
  {
    int nvars = RML_UNTAGFIXNUM(rmlA0);
    cout << "marked variables" << endl
	 << "================" << endl;
    for (std::set<int>::iterator i =v_mark.begin() ; i != v_mark.end(); i++) {
      cout << "var " << *i << endl;
    }
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__init_5fv)
  {
    int size = RML_UNTAGFIXNUM(rmlA1);
    v.reserve(size);
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__init_5ff)
  {
    int size = RML_UNTAGFIXNUM(rmlA1);
    f.reserve(size);
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__set_5ff)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    int val = RML_UNTAGFIXNUM(rmlA1);
    if (i > f.size()) { f.resize(i); }
    f[i-1]=val;
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__get_5ff)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    assert(i <= f.size());
    rmlA0 = (void*)mk_icon(f[i-1]);
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__set_5fv)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    int val = RML_UNTAGFIXNUM(rmlA1);
    if ( i > v.size() ) { v.resize(i); }
    v[i-1]=val;
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__get_5fv)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    assert(i <= v.size());
    rmlA0 = (void*)mk_icon(v[i-1]);
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL


} // extern "C"
