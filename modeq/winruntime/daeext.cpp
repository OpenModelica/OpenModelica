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

  std::vector<bool> e_mark;
  std::vector<bool> v_mark;
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
    v_mark.reserve(nvars);
    e_mark.reserve(neqns);
    for (int i =0; i < nvars; i++) {
      v_mark[i]=false;
    }
    for (int i =0; i < neqns; i++) {
      e_mark[i]=false;
    }
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL
  
  RML_BEGIN_LABEL(DAEEXT__e_5fmark)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    e_mark[i-1]=true;
    //cout << "e_mark[" << i << "] := true" << endl;
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL
  
  RML_BEGIN_LABEL(DAEEXT__v_5fmark)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    v_mark[i-1]=true;
    //cout << "v_mark[" << i << "] := true" << endl;
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__get_5fv_5fmark)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    //cout << "get_v_mark[" << i << "] == " << v_mark[i-1] << endl;
    rmlA0 = v_mark[i-1] ? RML_TRUE : RML_FALSE;
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__get_5fe_5fmark)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    //cout << "get_e_mark[" << i << "] == " << e_mark[i-1] << endl;
    rmlA0 = e_mark[i-1] ? RML_TRUE : RML_FALSE;
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
    for (int i =0 ; i < nvars; i++) {
      if (e_mark[i]) cout << "eqn " << i+1 << endl;
    }
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__dump_5fmarked_5fvariables)
  {
    int nvars = RML_UNTAGFIXNUM(rmlA0);
    cout << "marked variables" << endl
	 << "================" << endl;
    for (int i =0 ; i < nvars; i++) {
      if (v_mark[i]) cout << "var " << i+1 << endl;
    }
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__vector_5fsetnth)
  {
    void* vec = rmlA0;
    int pos = RML_UNTAGFIXNUM(rmlA1);
    int val = RML_UNTAGFIXNUM(rmlA2);
    if ( pos >= RML_HDRSLOTS(RML_GETHDR(vec)) ) {
      RML_TAILCALLK(rmlFC);
    }
    ((int*)RML_STRUCTDATA(vec))[pos]=val;
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
