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

/*
 * file:        BackendDAEEXT.cpp
 * description: The BackendDAEEXT.cpp file is the external implementation of
 *              MetaModelica package: Compiler/BackendDAEEXT.mo.
 *              This is used for the BLT and index reduction algorithms in BackendDAE.
 *              The implementation mainly consists of several bitvectors implemented
 *              using std::vector<bool> since such functionality is not available in
 *              MetaModelica Compiler (MMC).
 *
 * RCS: $Id$
 *
 */

#include <iostream>
#include <fstream>
#include <map>
#include <set>
#include <string>
#include <vector>
#include <cassert>


static std::set<int> e_mark;
static std::set<int> differentiated_mark;
static std::set<int> v_mark;

static std::vector<int> number;
static std::vector<int> lowlink;
static std::vector<int> v;
static std::vector<int> f;

using namespace std;

extern "C" {

void BackendDAEEXTImpl__initMarks(int nvars, int neqns)
{
// Why are the inputs not even used?
  v_mark.clear();
  e_mark.clear();
} 

void BackendDAEEXTImpl__eMark(int i)
{
  e_mark.insert(e_mark.begin(),i);
}

void BackendDAEEXTImpl__vMark(int i)
{
  v_mark.insert(v_mark.begin(),i);
}

int BackendDAEEXTImpl__getVMark(int i)
{
  return v_mark.find(i) != v_mark.end();
}

int BackendDAEEXTImpl__getEMark(int i)
{
  //cout << "get_e_mark[" << i << "] == " << e_mark[i-1] << endl;
  return e_mark.find(i) != e_mark.end();
}

void* BackendDAEEXTImpl__getMarkedEqns()
{
  std::set<int>::iterator it;
  void *res = mk_nil();
  for (it=e_mark.begin(); it != e_mark.end(); it++) {
    res = mk_cons(mk_icon(*it),res);
  }
  return res;
}

void BackendDAEEXTImpl__markDifferentiated(int i)
{
  differentiated_mark.insert(differentiated_mark.begin(),i);
}

void BackendDAEEXTImpl__clearDifferentiated()
{
  differentiated_mark.clear();
}

void* BackendDAEEXTImpl__getDifferentiatedEqns()
{
  std::set<int>::iterator it;
  void *res = mk_nil();
  for (it=differentiated_mark.begin(); it != differentiated_mark.end(); it++) {
    res = mk_cons(mk_icon(*it),res);
  }
  return res;
}

void* BackendDAEEXTImpl__getMarkedVariables()
{
  std::set<int>::iterator it;
  void *res = mk_nil();
  for (it=v_mark.begin(); it != v_mark.end(); it++) {
    res = mk_cons(mk_icon(*it),res);
  }
  return res;
}

void BackendDAEEXTImpl__initLowLink(int nvars)
{
  //cout << "init lowlink n= " << nvars << endl;
  lowlink.reserve(nvars);
  
  while (lowlink.size() < (unsigned int)nvars)
    lowlink.push_back(0);
  for (int i =0; i < nvars; i++)
    lowlink[i]=0;
} 

void BackendDAEEXTImpl__initNumber(int nvars)
{
  //cout << "init number n= " << nvars << endl;
  number.reserve(nvars);
  
  while (number.size() < (unsigned int)nvars)
    number.push_back(0);
  for (int i =0; i < nvars; i++) 
    number[i]=0;
} 

void BackendDAEEXTImpl__setLowLink(int i, int val)
{
  lowlink[i-1]=val;
}

void BackendDAEEXTImpl__setNumber(int i, int val)
{
  number[i-1]=val;
}

int BackendDAEEXTImpl__getNumber(int i)
{
  return number[i-1];
}

int BackendDAEEXTImpl__getLowLink(int i)
{
  return lowlink[i-1];
}

void BackendDAEEXTImpl__dumpMarkedEquations(int nvars)
{
  cout << "marked equations" << endl << "================" << endl;
  for (std::set<int>::iterator i =e_mark.begin() ; i != e_mark.end(); i++)
    cout << "eqn " << *i << endl;
}

void BackendDAEEXTImpl__dumpMarkedVariables(int nvars)
{
  cout << "marked variables" << endl << "================" << endl;
  for (std::set<int>::iterator i =v_mark.begin() ; i != v_mark.end(); i++)
    cout << "var " << *i << endl;
}

void BackendDAEEXTImpl__initV(int size)
{
  v.reserve(size);
}

void BackendDAEEXTImpl__initF(int size)
{
  f.reserve(size);
}

void BackendDAEEXTImpl__setF(int i, int val)
{
  if (i > f.size()) { f.resize(i); }
  f[i-1]=val;
}

int BackendDAEEXTImpl__getF(int i)
{
  assert(i <= f.size());
  return f[i-1];
}

void BackendDAEEXTImpl__setV(int i, int val)
{
  if ( i > v.size() ) { v.resize(i); }
  v[i-1]=val;
}

int BackendDAEEXTImpl__getV(int i)
{
  assert(i <= v.size());
  return v[i-1];
}

}
