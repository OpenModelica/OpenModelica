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
#include "matchmaker.h"

static unsigned int n=0; /* size of match */
static unsigned int m=0; /* size of row_match */
static int* match=NULL;
static int* row_match=NULL;
static int* col_ptrs=NULL;
static int* col_ids=NULL;

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
  void *res = mmc_mk_nil();
  for (it=e_mark.begin(); it != e_mark.end(); it++) {
    res = mmc_mk_cons(mmc_mk_icon(*it),res);
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
  void *res = mmc_mk_nil();
  for (it=differentiated_mark.begin(); it != differentiated_mark.end(); it++) {
    res = mmc_mk_cons(mmc_mk_icon(*it),res);
  }
  return res;
}

void* BackendDAEEXTImpl__getMarkedVariables()
{
  std::set<int>::iterator it;
  void *res = mmc_mk_nil();
  for (it=v_mark.begin(); it != v_mark.end(); it++) {
    res = mmc_mk_cons(mmc_mk_icon(*it),res);
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

void BackendDAEExtImpl__cheapmatching(int nvars, int neqns, int cheapID, int clear_match)
{
  int i=0;
  if (clear_match==0){
    if (neqns>n) {
      if(match)
      {
        int* tmp = (int*) malloc(neqns * sizeof(int));
        memcpy(tmp,match,n*sizeof(int));
        free(match);
        match = tmp;
        for (i = n; i < neqns; i++) {
          match[i] = -1;
        }
      } else {
         match = (int*) malloc(neqns * sizeof(int));
         memset(match,-1,neqns * sizeof(int));
      }
      n = neqns;
    }
    if (nvars>m) {
      if(row_match)
      {
        int* tmp = (int*) malloc(nvars * sizeof(int));
        memcpy(tmp,row_match,m*sizeof(int));
        free(row_match);
        row_match = tmp;
        for (i = m; i < nvars; i++) {
          row_match[i] = -1;
        }
      } else {
        row_match = (int*) malloc(nvars * sizeof(int));
         memset(row_match,-1,nvars * sizeof(int));
      }
      m = nvars;
    }
  }
  else {
  if (neqns>n) {
      if (match) free(match);
      match = (int*) malloc(neqns * sizeof(int));
      memset(match,-1,neqns * sizeof(int));
  } else {
      memset(match,-1,n * sizeof(int));
  }
    n = neqns;
    if (nvars>m) {
      if (row_match) free(row_match);
      row_match = (int*) malloc(nvars * sizeof(int));
      memset(row_match,-1,nvars * sizeof(int));
    } else {
      memset(row_match,-1,m * sizeof(int));
    }
    m = nvars;
  }
  if ((match != NULL) && (row_match != NULL)) {
    cheapmatching(col_ptrs,col_ids,match,row_match,neqns,nvars,cheapID,0 /*clear_match already done*/);
  }
}

void BackendDAEExtImpl__matching(int nvars, int neqns, int matchingID, int cheapID, double relabel_period, int clear_match)
{
  int i=0;
  if (clear_match==0){
    if (neqns>n) {
      if(match)
      {
        int* tmp = (int*) malloc(neqns * sizeof(int));
        memcpy(tmp,match,n*sizeof(int));
        free(match);
        match = tmp;
        for (i = n; i < neqns; i++) {
          match[i] = -1;
        }
      } else {
         match = (int*) malloc(neqns * sizeof(int));
         memset(match,-1,neqns * sizeof(int));
      }
      n = neqns;
    }
    if (nvars>m) {
      if(row_match)
      {
        int* tmp = (int*) malloc(nvars * sizeof(int));
        memcpy(tmp,row_match,m*sizeof(int));
        free(row_match);
        row_match = tmp;
        for (i = m; i < nvars; i++) {
          row_match[i] = -1;
        }
      } else {
        row_match = (int*) malloc(nvars * sizeof(int));
         memset(row_match,-1,nvars * sizeof(int));
      }
      m = nvars;
    }
  }
  else {
    if (neqns>n) {
      if (match) free(match);
      match = (int*) malloc(neqns * sizeof(int));
      memset(match,-1,neqns * sizeof(int));
    } else {
      memset(match,-1,n * sizeof(int));
    }
    n = neqns;
    if (nvars>m) {
      if (row_match) free(row_match);
      row_match = (int*) malloc(nvars * sizeof(int));
      memset(row_match,-1,nvars * sizeof(int));
    } else {
      memset(row_match,-1,m * sizeof(int));
    }
    m = nvars;
  }
  if ((match != NULL) && (row_match != NULL)) {
    matching(col_ptrs,col_ids,match,row_match,neqns,nvars,matchingID,cheapID,relabel_period,0 /*clear_match already done*/);
  }
}

}
