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
