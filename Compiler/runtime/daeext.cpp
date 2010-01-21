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

extern "C"
{
#include <assert.h>
#include "rml.h"

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
  
  RML_BEGIN_LABEL(DAEEXT__initMarks)
  {

    int nvars = RML_UNTAGFIXNUM(rmlA0);
    int neqns = RML_UNTAGFIXNUM(rmlA1);
    //cout << "init marks n= " << nvars << endl;
    v_mark.clear();
    e_mark.clear();
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL
  
  RML_BEGIN_LABEL(DAEEXT__eMark)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    e_mark.insert(e_mark.begin(),i);
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL
  
  RML_BEGIN_LABEL(DAEEXT__vMark)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    v_mark.insert(v_mark.begin(),i);
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__getVMark)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);

    rmlA0 = v_mark.find(i) != v_mark.end() ? RML_TRUE : RML_FALSE;
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__getEMark)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    //cout << "get_e_mark[" << i << "] == " << e_mark[i-1] << endl;
    rmlA0 = e_mark.find(i) != e_mark.end() ? RML_TRUE : RML_FALSE;
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__getMarkedEqns)
  {
    std::set<int>::iterator it;
    rmlA0 = mk_nil();
    for (it=e_mark.begin(); it != e_mark.end(); it++) {
      rmlA0 = mk_cons(mk_icon(*it),rmlA0);
    }
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__markDifferentiated)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    differentiated_mark.insert(differentiated_mark.begin(),i);
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__clearDifferentiated)
  {
    differentiated_mark.clear();
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__getDifferentiatedEqns)
  {
    std::set<int>::iterator it;
    rmlA0 = mk_nil();
    for (it=differentiated_mark.begin(); it != differentiated_mark.end(); it++) {
      rmlA0 = mk_cons(mk_icon(*it),rmlA0);
    }
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__getMarkedVariables)
  {
    std::set<int>::iterator it;
    rmlA0 = mk_nil();
    for (it=v_mark.begin(); it != v_mark.end(); it++) {
      rmlA0 = mk_cons(mk_icon(*it),rmlA0);
    }
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__initLowLink)
  {
    int nvars = RML_UNTAGFIXNUM(rmlA0);
    //cout << "init lowlink n= " << nvars << endl;
    lowlink.reserve(nvars);
    
    while (lowlink.size() < (unsigned int)nvars)
    {
    	lowlink.push_back(0);
    }

    for (int i =0; i < nvars; i++) 
    {
      lowlink[i]=0;
    }
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__initNumber)
  {
    int nvars = RML_UNTAGFIXNUM(rmlA0);
    //cout << "init number n= " << nvars << endl;
    number.reserve(nvars);
    
    while (number.size() < (unsigned int)nvars)
    {
    	number.push_back(0);
    }    

    for (int i =0; i < nvars; i++) 
    {
      number[i]=0;
    }
    RML_TAILCALLK(rmlSC);
  } 
  RML_END_LABEL
  
  RML_BEGIN_LABEL(DAEEXT__setLowLink)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    int val = RML_UNTAGFIXNUM(rmlA1);
    lowlink[i-1]=val;
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL
  
  RML_BEGIN_LABEL(DAEEXT__setNumber)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    int val = RML_UNTAGFIXNUM(rmlA1);
    number[i-1]=val;
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__getNumber)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    rmlA0 = (void*)mk_icon(number[i-1]);
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__getLowLink)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    rmlA0 = (void*)mk_icon(lowlink[i-1]);
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL


  RML_BEGIN_LABEL(DAEEXT__dumpMarkedEquations)
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

  RML_BEGIN_LABEL(DAEEXT__dumpMarkedVariables)
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

/*
  RML_BEGIN_LABEL(DAEEXT__vectorSetnth)
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
*/

  RML_BEGIN_LABEL(DAEEXT__initV)
  {
    int size = RML_UNTAGFIXNUM(rmlA1);
    v.reserve(size);
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__initF)
  {
    int size = RML_UNTAGFIXNUM(rmlA1);
    f.reserve(size);
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__setF)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    int val = RML_UNTAGFIXNUM(rmlA1);
    if (i > f.size()) { f.resize(i); }
    f[i-1]=val;
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__getF)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    assert(i <= f.size());
    rmlA0 = (void*)mk_icon(f[i-1]);
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__setV)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    int val = RML_UNTAGFIXNUM(rmlA1);
    if ( i > v.size() ) { v.resize(i); }
    v[i-1]=val;
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL

  RML_BEGIN_LABEL(DAEEXT__getV)
  {
    int i = RML_UNTAGFIXNUM(rmlA0);
    assert(i <= v.size());
    rmlA0 = (void*)mk_icon(v[i-1]);
    RML_TAILCALLK(rmlSC);
  }
  RML_END_LABEL


} // extern "C"
