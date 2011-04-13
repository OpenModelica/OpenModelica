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

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <string.h>
#include <assert.h>


typedef struct {
  double *data;
  unsigned int n;
} DataField;

typedef struct {
  char *name;
  double data;
  double dataref;
  double time;
  double timeref;
} DiffData;

typedef struct {
  DiffData *data;
  unsigned int n;
} DiffDataField;


static SimulationResult_Globals simresglob_c = {UNKNOWN_PLOT,NULL,{NULL,NULL,0,NULL,0,NULL,0,0,0,NULL},NULL,NULL};
static SimulationResult_Globals simresglob_ref = {UNKNOWN_PLOT,NULL,{NULL,NULL,0,NULL,0,NULL,0,0,0,NULL},NULL,NULL};

// from an array of string creates flatten 'char*'-array suitable to be 
// stored as MAT-file matrix
static inline void fixDerInName(char *str, size_t len)
{
  size_t i;
  char* dot;
  if (len < 6) return;

  // check if name start with "der(" and includes at least one dot
  while (strncmp(str,"der(",4) == 0 && (dot = strrchr(str,'.')) != NULL) {
    size_t pos = (size_t)(dot-str)+1;
    // move prefix to the begining of string :"der(a.b.c.d)" -> "a.b.c.b.c.d)"
    for(i = 4; i < pos; ++i)
      str[i-4] = str[i];
    // move "der(" to the end of prefix
    // "a.b.c.b.c.d)" -> "a.b.c.der(d)"
    strncpy(&str[pos-4],"der(",4);
  }
}

static inline void fixCommaInName(char *str, size_t len)
{
  size_t i;
  char* dot;
  if (len < 2) return;

  // check if name start with "der(" and includes at least one dot
  while (strncmp(str,",",4) == 0 && (dot = strrchr(str,'.')) != NULL) {
    size_t pos = (size_t)(dot-str)+1;
    // move prefix to the begining of string :"der(a.b.c.d)" -> "a.b.c.b.c.d)"
    for(i = 4; i < pos; ++i)
      str[i-4] = str[i];
    // move "der(" to the end of prefix
    // "a.b.c.b.c.d)" -> "a.b.c.der(d)"
    strncpy(&str[pos-4],"der(",4);
  }
}

double absdouble(double d) 
{
  if (d > 0.0)
    return d;
  else
    return -1.0*d;
}

char ** getVars(void *vars, unsigned int* nvars)
{
  char **cmpvars=NULL;
  char *var;
  unsigned int i;
  unsigned int ncmpvars = 0;
  char **newvars=NULL;
  *nvars=0;

  //fprintf(stderr, "getVars\n");
  while (RML_NILHDR != RML_GETHDR(vars)) {
    var = RML_STRINGDATA(RML_CAR(vars));

    //fprintf(stderr, "Var: %s\n", var);
    newvars = (char**)malloc(sizeof(char*)*(ncmpvars+1));

    for (i=0;i<ncmpvars;i++)
      newvars[i] = cmpvars[i];
    newvars[ncmpvars] = var;
    ncmpvars += 1;
      if(cmpvars) free(cmpvars);
    cmpvars = newvars;
    //fprintf(stderr, "NVar: %d\n", ncmpvars);

    vars = RML_CDR(vars);
  }
  *nvars = ncmpvars;
  return cmpvars;
}

DataField getData(const char *varname,const char *filename, unsigned int size, SimulationResult_Globals* srg)
{
  DataField res;
  void *cmpvar,*dataset,*lst;
  double *newvars; 
  double d;
  unsigned int i;
  unsigned int ncmpvars = 0;
  res.n = 0;
  res.data = NULL;

  //fprintf(stderr, "getData of Var: %s from file %s\n", varname,filename);
  cmpvar = mk_nil();
  cmpvar =  mk_cons(mk_scon(varname),cmpvar); 
  dataset = SimulationResultsImpl__readDataset(filename,cmpvar,size,srg);
  if (dataset==NULL){
    //fprintf(stderr, "getData of Var: failed\n");
    return res;
  }

  //fprintf(stderr, "Data of Var: %s\n", varname);
  // this should walk a list of lists  
  while (RML_NILHDR != RML_GETHDR(dataset)) {
    lst = RML_CAR(dataset);
    while (RML_NILHDR != RML_GETHDR(lst)) {
      d = rml_prim_get_real(RML_CAR(lst));

      newvars = (double*) malloc(sizeof(double)*(res.n+1));
      for (i=0;i<res.n;i++)
        newvars[i] = res.data[i];
      newvars[res.n] = d;
      res.n +=1;
        if(res.data) free(res.data);
      res.data = newvars;

      lst = RML_CDR(lst);
    }
    dataset = RML_CDR(dataset);
  }

  // reverse lst
  newvars = (double*) malloc(sizeof(double)*(res.n));
  for (i=0;i<res.n;i++)
    newvars[i] = res.data[res.n-i-1];
  if(res.data) free(res.data);
    res.data = newvars;

  //for (i=0;i<res.n;i++)
  // fprintf(stderr, "%.6g\n",  res.data[i]);


  return res;
}

void cmpData(char* varname, DataField *time, DataField *reftime, DataField *data, DataField *refdata, double reltol, DiffDataField *ddf)
{
  unsigned int i,j;
  double t,tr,d,dr,delta;
  DiffData *diffdatafild; 
  char increased = 0;
  char interpolate = 0;
  j = 0;
  tr = reftime->data[j];
  dr = refdata->data[j];

  //fprintf(stderr, "compare: %s\n",varname);
  for (i=0;i<data->n;i++){
    t = time->data[i];
    d = data->data[i];
    // fprintf(stderr, " t: %.6g   d:%.6g\n",t,d);
    increased = 0;
    while(tr < t){
      if (j < reftime->n) {
        j += 1;
        tr = reftime->data[j];
        increased = 1;
      }
      else
        break;
    }
    if (increased==1){
      if ((t - reftime->data[j-1]) < (tr-t)) {
        j -= 1;
        tr = reftime->data[j];
      }
    }

    interpolate = 0;
    if (absdouble(t-tr) > reltol)
      interpolate = 1;

    dr = refdata->data[j]; 
    if (interpolate==1){
      //fprintf(stderr, "interpolate d:%.6g ",t,dr);
      dr = dr + ((refdata->data[j+1]-dr)/(reftime->data[j+1]-tr))*(t-tr);
      //fprintf(stderr, "-> dr:%.6g\n",dr);
    }
    //fprintf(stderr, "tr: %.6g  dr:%.6g\n",tr,dr);

    if (dr != 0){
      delta = absdouble(d-dr)/dr;
    }
    else
      delta = d;
    //fprintf(stderr, "delta:%.6g  reltol:%.6g\n",absdouble(delta),reltol);

    if (absdouble(delta) > reltol){

      diffdatafild = (DiffData*) malloc(sizeof(DiffData)*(ddf->n+1));
      for (j=0;j<ddf->n;j++)
        diffdatafild[j] = ddf->data[j];
      diffdatafild[ddf->n].name = varname;
      diffdatafild[ddf->n].data = d;
      diffdatafild[ddf->n].dataref = dr;
      diffdatafild[ddf->n].time = t;
      diffdatafild[ddf->n].timeref = tr;
      ddf->n +=1;
        if(ddf->data) free(ddf->data);
      ddf->data = diffdatafild;
    }
  }

}

int writeLogFile(const char *filename,DiffDataField *ddf,const char *f,const char *reff,double reltol)
{
  FILE* fout;
  unsigned int i;
  //fprintf(stderr, "writeLogFile: %s\n",filename);
  fout = fopen(filename, "w");
  if (!fout)
    return -1;

  fprintf(fout, "\"Generated by OpenModelica\";;;;;\n");
  fprintf(fout, "\"Compared Files\";\"%s\";\"%s\";\"relative tolerance\";%.6g;\n",f,reff,reltol);
  fprintf(fout, "\"Name\";\"Time\";\"DataPoint\";\"RefTime\";\"RefDataPoint\";\n");
  for (i=0;i<ddf->n;i++){
    fprintf(fout, "%s;%.6g;%.6g;%.6g;%.6g;\n",ddf->data[i].name,ddf->data[i].time,ddf->data[i].data,ddf->data[i].timeref,ddf->data[i].dataref);
  }
  fclose(fout);
  //fprintf(stderr, "writeLogFile: %s finished\n",filename);
  return 0;
}

void* SimulationResultsCmp_compareResults(const char *filename, const char *reffilename, const char *resultfilename, double reltol,  void *vars)
{
  char **cmpvars=NULL;
  unsigned int ncmpvars = 0;
  void *allvars,*cmpvar,*res;
  unsigned int i,size,size_ref,len,oldlen,j,k;
  char *var,*var1,*var2;
  DataField time,timeref,data,dataref;
  DiffDataField ddf;
  const char *msg[2] = {"",""};
  ddf.data=NULL;
  ddf.n=0;
  oldlen = 0;
  len = 1;

  // open files
  // fprintf(stderr, "Open File %s\n", filename);
  if (UNKNOWN_PLOT == SimulationResultsImpl__openFile(filename,&simresglob_c)) return mk_cons(mk_scon("Error Open File!"),mk_nil());
  // fprintf(stderr, "Open File %s\n", reffilename);
  if (UNKNOWN_PLOT == SimulationResultsImpl__openFile(reffilename,&simresglob_ref)) return mk_cons(mk_scon("Error Open RefFile!"),mk_nil());

  size = SimulationResultsImpl__readSimulationResultSize(filename,&simresglob_c);
  // fprintf(stderr, "Read size of File %s size= %d\n", filename,size);
  size_ref = SimulationResultsImpl__readSimulationResultSize(reffilename,&simresglob_ref);
  // fprintf(stderr, "Read size of File %s size= %d\n", reffilename,size_ref);

  // get vars to compare
  cmpvars = getVars(vars,&ncmpvars);
  // if no var compare all vars 
  if (ncmpvars==0){
    allvars = SimulationResultsImpl__readVars(filename,&simresglob_c);
    cmpvars = getVars(vars,&ncmpvars);
    if (ncmpvars==0) return mk_cons(mk_scon("Error Get Vars!"),mk_nil());
  }
  // fprintf(stderr, "Compare Vars:\n");
  // for(i=0;i<ncmpvars;i++)
  //  fprintf(stderr, "Var: %s\n", cmpvars[i]);

  // get time
  //fprintf(stderr, "get time\n");
  time = getData("time",filename,size,&simresglob_c);
  if (time.n==0)
  {
    time = getData("Time",filename,size,&simresglob_c);
    if (time.n==0){
      //fprintf(stderr, "Cannot get var time\n");
      return mk_cons(mk_scon("Error get time!"),mk_nil());  
    }
  }
  //fprintf(stderr, "get reftime\n");
  timeref = getData("time",reffilename,size_ref,&simresglob_ref);
  if (timeref.n==0)
  {
    timeref = getData("Time",reffilename,size_ref,&simresglob_ref);
    if (timeref.n==0){
      //fprintf(stderr, "Cannot get var reftime\n");
      return mk_cons(mk_scon("Error get ref time!"),mk_nil());  
    }
  }

  var1=NULL;
  var2=NULL;
  // compare vars
  //fprintf(stderr, "compare vars\n");
  for (i=0;i<ncmpvars;i++) {
    var = cmpvars[i];
    len = strlen(var);
    if (oldlen < len) {
      if (var1) free(var1);
      var1 = (char*) malloc(len+1);
      oldlen = len;
    }
    memset(var1,0,len);
    k = 0;
    for (j=0;j<len;j++) {
      if (var[j] !='\"' ) {
        var1[k] = var[j];
        k +=1;
      }
    }
    // fprintf(stderr, "compare var: %s\n",var);
    // check if in ref_file
    dataref = getData(var1,reffilename,size_ref,&simresglob_ref);
    if (dataref.n==0) {
      if (var2) free(var2);
      var2 = (char*) malloc(len);
      strncpy(var2,var1,len+1);
      fixDerInName(var2,len);
      dataref = getData(var2,reffilename,size_ref,&simresglob_ref);
      if (dataref.n==0) {
        fprintf(stderr, "Get Data of Var %s from file %s failed\n",var,reffilename);
        c_add_message(-1, "SCRIPT", "Warning", "Get Data of Var failed!\n", msg, 0);
        continue;
      }
    }
    // check if in file
    data = getData(var1,filename,size,&simresglob_c);
    if (data.n==0)  {
      fixDerInName(var1,len);
      data = getData(var1,filename,size,&simresglob_c);
      if (data.n==0)  {
        if (data.data) free(data.data);
        fprintf(stderr, "Get Data of Var %s from file %s failed\n",var,filename);
        c_add_message(-1, "SCRIPT", "Warning", "Get Data of Var failed!\n", msg, 0);
        continue;
      }
    }
    // compare
    cmpData(var,&time,&timeref,&data,&dataref,reltol,&ddf);
    // free 
    if (dataref.data) free(dataref.data);
    if (data.data) free(data.data);
  }

  if (writeLogFile(resultfilename,&ddf,filename,reffilename,reltol))
  {
     c_add_message(-1, "SCRIPT", "Warning", "Cannot write result file!\n", msg, 0);
  }

  if (ddf.n > 0){
    //fprintf(stderr, "diff: %d\n",ddf.n);
    res = mk_cons(mk_scon("Files not Equal!"),mk_nil());
    c_add_message(-1, "SCRIPT", "Warning", "Files not Equal\n", msg, 0);
  }
  else
    res = mk_cons(mk_scon("Files Equal!"),mk_nil());

  if (var1) free(var1);
  if (var2) free(var2);
  if (ddf.data) free(ddf.data);
  if(cmpvars) free(cmpvars);
  if (time.data) free(time.data);
  if (timeref.data) free(timeref.data);
  // close files
  SimulationResultsImpl__close(&simresglob_c);
  SimulationResultsImpl__close(&simresglob_ref);

  return res;
}

