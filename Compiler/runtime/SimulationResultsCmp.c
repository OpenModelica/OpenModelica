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

#include "systemimpl.h"

/* Size of the buffer for warnings and other messages */
#define WARNINGBUFFSIZE 4096

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
  char interpolate;
} DiffData;

typedef struct {
  DiffData *data;
  unsigned int n;
  unsigned int n_max;
} DiffDataField;

#define DOUBLEEQUAL_TOTAL 0.0000000001
#define DOUBLEEQUAL_REL 0.00001

static SimulationResult_Globals simresglob_c = {UNKNOWN_PLOT,0};
static SimulationResult_Globals simresglob_ref = {UNKNOWN_PLOT,0};

static char ** getVars(void *vars, unsigned int* nvars)
{
  char **cmpvars = NULL;
  unsigned int ncmpvars = 0;
  unsigned int i = 0;
  void *v;

  /* Count the number of variables in the list. */
  for(v = vars; MMC_NILHDR != MMC_GETHDR(v); v = MMC_CDR(v)) {
    ++ncmpvars;
  }

  /* Allocate a new string array to contain the variable names. */
  cmpvars = (char**)GC_malloc(sizeof(char*)*(ncmpvars));

  /* Copy the variable names from the MetaModelica list to the string array. */
  for(; MMC_NILHDR != MMC_GETHDR(vars); vars = MMC_CDR(vars)) {
    cmpvars[i++] = GC_strdup(MMC_STRINGDATA(MMC_CAR(vars)));
  }

  *nvars = ncmpvars;
  return cmpvars;
}

static DataField getData(const char *varname,const char *filename, unsigned int size, int suggestRealAll, SimulationResult_Globals* srg, int runningTestsuite)
{
  DataField res;
  void *cmpvar,*dataset,*lst,*datasetBackup;
  unsigned int i;
  res.n = 0;
  res.data = NULL;

  /* fprintf(stderr, "getData of Var: %s from file %s\n", varname,filename);  */
  cmpvar = mmc_mk_nil();
  cmpvar =  mmc_mk_cons(mmc_mk_scon(varname),cmpvar);
  dataset = SimulationResultsImpl__readDataset(filename,cmpvar,size,suggestRealAll,srg,runningTestsuite);
  if (dataset==NULL) {
    /* fprintf(stderr, "getData of Var: %s failed!\n",varname); */
    return res;
  }

  /* fprintf(stderr, "Data of Var: %s\n", varname); */
  /*  First calculate the length of the matrix */
  datasetBackup = dataset;
  while (MMC_NILHDR != MMC_GETHDR(dataset)) {
    lst = MMC_CAR(dataset);
    while (MMC_NILHDR != MMC_GETHDR(lst)) {
      res.n++;
      lst = MMC_CDR(lst);
    }
    dataset = MMC_CDR(dataset);
  }
  if (res.n == 0) return res;

  /* The allocate and read the values */
  dataset = datasetBackup;
  i = res.n;
  res.data = (double*) malloc(sizeof(double)*res.n);
  while (MMC_NILHDR != MMC_GETHDR(dataset)) {
    lst = MMC_CAR(dataset);
    while (MMC_NILHDR != MMC_GETHDR(lst)) {
      res.data[--i] = mmc_prim_get_real(MMC_CAR(lst));
      lst = MMC_CDR(lst);
    }
    dataset = MMC_CDR(dataset);
  }
  assert(i == 0);

  /* for (i=0;i<res.n;i++)
    fprintf(stderr, "%d: %.15g\n",  i, res.data[i]); */

  return res;
}

/* see http://randomascii.wordpress.com/2012/02/25/comparing-floating-point-numbers-2012-edition/ */
static char almostEqualRelativeAndAbs(double a, double b, double reltol, double abstol)
{
  /* Check if the numbers are really close -- needed when comparing numbers near zero. */
  double diff = fabs(a - b);
  if (diff <= abstol) {
    return 1;
  }
  if (diff <= fmax(fabs(a),fabs(b)) * reltol) {
    return 1;
  }
  return 0;
}

static char almostEqualWithDefaultTolerance(double a, double b)
{
  return almostEqualRelativeAndAbs(a,b,DOUBLEEQUAL_REL,DOUBLEEQUAL_TOTAL);
}

static unsigned int cmpData(int isResultCmp, char* varname, DataField *time, DataField *reftime, DataField *data, DataField *refdata, double reltol, double abstol, DiffDataField *ddf, char **cmpdiffvars, unsigned int vardiffindx, int keepEqualResults, void **diffLst, const char *prefix)
{
  unsigned int i,j,k,j_event;
  double t,tr,d,dr,err,d_left,d_right,dr_left,dr_right,t_event;
  char increased = 0;
  char interpolate = 0;
  char isdifferent = 0;
  char refevent = 0;
  double average=0;
  FILE *fout = NULL;
  char *fname = NULL;
  if (!isResultCmp) {
    fname = (char*) malloc(25 + strlen(prefix) + strlen(varname));
    sprintf(fname, "%s.%s.csv", prefix, varname);
    fout = fopen(fname,"w");
    if (fout) {
      fprintf(fout, "time,reference,actual,err,relerr,threshold\n");
    }
  }
  for (i=0;i<refdata->n;i++){
    average += fabs(refdata->data[i]);
  }
  average = average/((double)refdata->n);
#ifdef DEBUGOUTPUT
   fprintf(stderr, "average: %.15g\n",average);
#endif
  average = reltol*fabs(average)+abstol;
  j = 0;
  tr = reftime->data[j];
  dr = refdata->data[j];
#ifdef DEBUGOUTPUT
   fprintf(stderr, "compare: %s\n",varname);
#endif
  for (i=0;i<data->n;i++){
    t = time->data[i];
    d = data->data[i];
    increased = 0;
#ifdef DEBUGOUTPUT
     fprintf(stderr, "i: %d t: %.15g   d:%.15g\n",i,t,d);
#endif
    while(tr < t){
      if (j +1< reftime->n) {
        j += 1;
        tr = reftime->data[j];
        increased = 1;
        if (tr == t) {
          break;
        }
#ifdef DEBUGOUTPUT
         fprintf(stderr, "j: %d tr:%.15g\n",j,tr);
#endif
      }
      else
        break;
    }
    if (increased==1) {
      if ( (fabs((t-tr)/tr) > reltol) || (fabs(t-tr) > fabs(t-reftime->data[j-1]))) {
        j = j- 1;
        tr = reftime->data[j];
      }
    }
#ifdef DEBUGOUTPUT
    fprintf(stderr, "i: %d t: %.15g   d:%.15g  j: %d tr:%.15g\n",i,t,d,j,tr);
#endif
    /* events, in case of an event compare only the left and right values of the absolute event time range,
    * this means ta_left = min(t_left,tr_left) and
    * ta_right = max(t_right,ta_right) */
    if(i<time->n) {
#ifdef DEBUGOUTPUT
       fprintf(stderr, "check event: %.15g  - %.15g = %.15g\n",t,time->data[i+1],fabs(t-time->data[i+1]));
#endif
      /* an event */
      if (almostEqualWithDefaultTolerance(t,time->data[i+1])) {
#ifdef DEBUGOUTPUT
         fprintf(stderr, "event: %.15g  %d  %.15g\n",t,i,d);
#endif
        /* left value */
        d_left = d;
#ifdef DEBUGOUTPUT
         fprintf(stderr, "left value: %.15g  %d %.15g\n",t,i,d_left);
#endif
        /* right value */
        if (i+1<data->n) {
          while (almostEqualWithDefaultTolerance(t,time->data[i+1])) {
            i +=1;
            if (i+1>=data->n) break;
          }
        }
        t = time->data[i];
        d_right = data->data[i];
#ifdef DEBUGOUTPUT
        fprintf(stderr, "right value: %.15g  %d %.15g\n",t,i,d_right);
#endif
        /* search event in reference forwards */
        refevent = 0;
        t_event = t + t*reltol*0.1;
        /* do not exceed next time step */
        if (i+1<=data->n) {
          t_event = (t_event > time->data[i])?time->data[i]:t_event;
        }else{
          t_event = (t_event > time->data[i+1])?time->data[i+1]:t_event;
        }
        j_event = j;
        while(tr < t_event) {
          if (j+1<reftime->n) {
            if (almostEqualWithDefaultTolerance(tr,reftime->data[j+1])) {
              dr_left = refdata->data[j];
#ifdef DEBUGOUTPUT
              fprintf(stderr, "ref left value: %.15g  %d %.15g\n",tr,j,dr_left);
#endif
              refevent = 1;

              do {
                j +=1;
                if (j+1>=reftime->n) break;
              } while (almostEqualWithDefaultTolerance(tr,reftime->data[j+1]));
            }
          }
          if (refevent == 0) {
            j += 1;
            if (j >= reftime->n)
              break;
            tr = reftime->data[j];
          }
          else {
            tr = reftime->data[j];
            break;
          }
        }
        if (refevent==1) {
          tr = reftime->data[j];
          dr_right = refdata->data[j];
#ifdef DEBUGOUTPUT
           fprintf(stderr, "ref right value: %.15g  %d %.15g\n",tr,j,dr_right);
#endif

          err = fabs(d_left-dr_left);
#ifdef DEBUGOUTPUT
           fprintf(stderr, "delta:%.15g  reltol:%.15g\n",err,average);
#endif
          if ( err < average){
            err = fabs(d_right-dr_right);
#ifdef DEBUGOUTPUT
             fprintf(stderr, "delta:%.15g  reltol:%.15g\n",err,average);
#endif
            if ( err < average ) {
              continue;
            }
          }
        }
        else {
          /* search event in reference backwards */
          j = j_event;
          tr = reftime->data[j];
          refevent = 0;
          t_event = t - t*reltol*0.1;
          while(tr > t_event) {
            if (j-1>0) {
              if (almostEqualWithDefaultTolerance(tr,reftime->data[j-1])) {
                dr_right = refdata->data[j];
#ifdef DEBUGOUTPUT
                fprintf(stderr, "ref right value: %.15g  %d %.15g\n",tr,j,dr_right);
#endif
                refevent = 1;

                do {
                  j -=1;
                  if (j-1<=0) break;
                } while (almostEqualWithDefaultTolerance(tr,reftime->data[j-1]));
              }
            }
            if (refevent == 0) {
              j -= 1;
              if (j == 0)
                break;
              tr = reftime->data[j];
            }
            else {
              tr = reftime->data[j];
              break;
            }
          }
          if (refevent==1) {
            tr = reftime->data[j];
            dr_left = refdata->data[j];
#ifdef DEBUGOUTPUT
            fprintf(stderr, "ref left value: %.15g  %d %.15g\n",tr,j,dr_left);
#endif
            err = fabs(d_left-dr_left);
#ifdef DEBUGOUTPUT
            fprintf(stderr, "delta:%.15g  reltol:%.15g\n",err,average);
#endif
            if ( err < average){
              err = fabs(d_right-dr_right);
#ifdef DEBUGOUTPUT
              fprintf(stderr, "delta:%.15g  reltol:%.15g\n",err,average);
#endif
              if ( err < average){
                j = j_event;
                tr = reftime->data[j];
                continue;
              }
            }
          }
          j = j_event;
          tr = reftime->data[j];
        }
      }
    }

    interpolate = 0;
#ifdef DEBUGOUTPUT
     fprintf(stderr, "interpolate? %d %.15g:%.15g  %.15g:%.15g\n",i,t,tr,fabs((t-tr)/tr),abstol);
#endif
    if (fabs(t-tr) > 0.00001) {
      interpolate = 1;
    }

    dr = refdata->data[j];
    if (interpolate==1){
#ifdef DEBUGOUTPUT
      fprintf(stderr, "interpolate %.15g:%.15g  %.15g:%.15g %d",t,d,tr,dr,j);
#endif
      unsigned int jj = j;
      /* look for interpolation partner */
      if (tr > t) {
        if (j-1 > 0) {
          jj = j-1;
          increased = 0;
          if (reftime->data[jj] == tr){
            increased = 1;
            do {
              jj -= 1;
              if (jj<=0) break;
            } while (reftime->data[jj] == tr);
          }
        }
#ifdef DEBUGOUTPUT
        fprintf(stderr, "-> %d %.15g %.15g\n",jj,reftime->data[jj],refdata->data[jj]);
#endif
        if (reftime->data[jj] != tr){
          dr = refdata->data[jj] + ((dr-refdata->data[jj])/(tr-reftime->data[jj]))*(t-reftime->data[jj]);
        }
#ifdef DEBUGOUTPUT
        fprintf(stderr, "-> dr:%.15g\n",dr);
#endif
      }
      else {
        if (j+1<reftime->n) {
          jj = j+1;
          increased = 0;
          if (reftime->data[jj] == tr){
            increased = 1;
            do {
              jj += 1;
              if (jj>=reftime->n) break;
            } while (reftime->data[jj] == tr);
          }
        }
#ifdef DEBUGOUTPUT
        fprintf(stderr, "-> %d %.15g %.15g\n",jj,reftime->data[jj],tr);
#endif
        if (reftime->data[jj] != tr){
          dr = dr + ((refdata->data[jj] - dr)/(reftime->data[jj] - tr))*(t-tr);
        }
#ifdef DEBUGOUTPUT
        fprintf(stderr, "-> dr:%.15g\n",dr);
#endif
      }
    }
#ifdef DEBUGOUTPUT
    fprintf(stderr, "j: %d tr: %.15g  dr:%.15g  t:%.15g  d:%.15g\n",j,tr,dr,t,d);
#endif
    err = fabs(d-dr);
#ifdef DEBUGOUTPUT
    fprintf(stderr, "delta:%.15g  reltol:%.15g\n",err,average);
#endif
    if (fout) {
      fprintf(fout, "%.15g,%.15g,%.15g,%.15g,%.15g,%.15g\n",tr,dr,d,err,almostEqualWithDefaultTolerance(d,0) ? err/average : fabs(err/d),average);
    }
    if ( err > average){
      if (j+1<reftime->n) {
        if (reftime->data[j+1] == tr) {
          dr = refdata->data[j+1];
          err = fabs(d-dr);
        }
      }

      if (err < average){
        continue;
      }

      isdifferent = 1;
      if (isResultCmp) { /* If we produce the full diff, this data has already been output */
        if (ddf->n >= ddf->n_max) {
          DiffData *newData;
          ddf->n_max = ddf->n_max ? ddf->n_max*2 : 1024;
          newData = (DiffData*) realloc(ddf->data, sizeof(DiffData)*(ddf->n_max));
          if (!newData) continue; /* realloc failed... pretty bad, but let's continue */
          ddf->data = newData;
        }
        ddf->data[ddf->n].name = varname;
        ddf->data[ddf->n].data = d;
        ddf->data[ddf->n].dataref = dr;
        ddf->data[ddf->n].time = t;
        ddf->data[ddf->n].timeref = tr;
        ddf->data[ddf->n].interpolate = interpolate?'1':'0';
        ddf->n +=1;
      }
    }
  }
  if (isdifferent) {
    cmpdiffvars[vardiffindx] = varname;
    vardiffindx++;
    if (!isResultCmp) {
      *diffLst = mmc_mk_cons(mmc_mk_scon(varname),*diffLst);
    }
  }
  if (fout) {
    fclose(fout);
  }
  if (!isdifferent && 0==keepEqualResults && 0==isResultCmp) {
    SystemImpl__removeFile(fname);
  }
  if (fname) {
    free(fname);
  }
  return vardiffindx;
}

static int writeLogFile(const char *filename,DiffDataField *ddf,const char *f,const char *reff,double reltol,double abstol)
{
  FILE* fout;
  unsigned int i;
  /* fprintf(stderr, "writeLogFile: %s\n",filename); */
  fout = fopen(filename, "w");
  if (!fout)
    return -1;

  fprintf(fout, "\"Generated by OpenModelica\";;;;;\n");
  fprintf(fout, "\"Compared Files\";;;\"absolute tolerance\";%.15g;relative tolerance;%.15g\n",abstol,reltol);
  fprintf(fout, "\"%s\";;;;;;\n",f);
  fprintf(fout, "\"%s\";;;;;;\n",reff);
  fprintf(fout, "\"Name\";\"Time\";\"DataPoint\";\"RefTime\";\"RefDataPoint\";\"absolute error\";\"relative error\";interpolate;\n");
  for (i=0;i<ddf->n;i++){
    fprintf(fout, "%s;%.15g;%.15g;%.15g;%.15g;%.15g;%.15g;%c;\n",ddf->data[i].name,ddf->data[i].time,ddf->data[i].data,ddf->data[i].timeref,ddf->data[i].dataref,
      fabs(ddf->data[i].data-ddf->data[i].dataref),fabs((ddf->data[i].data-ddf->data[i].dataref)/ddf->data[i].dataref),ddf->data[i].interpolate);
  }
  fclose(fout);
  /* fprintf(stderr, "writeLogFile: %s finished\n",filename); */
  return 0;
}

static const char* getTimeVarName(void *vars) {
  const char *res = "time";
  while (MMC_NILHDR != MMC_GETHDR(vars)) {
    char *var = MMC_STRINGDATA(MMC_CAR(vars));
    if (0==strcmp("time",var)) break;
    if (0==strcmp("Time",var)) {
      res="Time";
      break;
    }
    vars = MMC_CDR(vars);
  }
  return res;
}

#include "SimulationResultsCmpTubes.c"

/* Common, huge function, for both result comparison and result diff */
void* SimulationResultsCmp_compareResults(int isResultCmp, int runningTestsuite, const char *filename, const char *reffilename, const char *resultfilename, double reltol, double abstol, double reltolDiffMaxMin, double rangeDelta, void *vars, int keepEqualResults, int *success, void **failVars, int isHtml, char **htmlOut)
{
  char **cmpvars=NULL;
  char **cmpdiffvars=NULL;
  unsigned int vardiffindx=0;
  unsigned int ncmpvars = 0;
  unsigned int ngetfailedvars = 0;
  void *allvars,*allvarsref,*res;
  unsigned int i,size,size_ref,len,j,k;
  char *var,*var1,*var2;
  DataField time,timeref,data,dataref;
  DiffDataField ddf;
  const char *msg[2] = {"",""};
  const char *timeVarName, *timeVarNameRef;
  int suggestReadAll=0;
  ddf.data=NULL;
  ddf.n=0;
  ddf.n_max=0;
  len = 1;
  *failVars = mmc_mk_nil();

  /* open files */
  /*  fprintf(stderr, "Open File %s\n", filename); */
  if (UNKNOWN_PLOT == SimulationResultsImpl__openFile(filename,&simresglob_c)) {
    char *str = (char*) GC_malloc(25+strlen(filename));
    *str = 0;
    strcat(strcat(str,"Error opening file: "), filename);
    void *res = mmc_mk_scon(str);
    GC_free(str);
    return mmc_mk_cons(res,mmc_mk_nil());
  }
  /* fprintf(stderr, "Open File %s\n", reffilename); */
  if (UNKNOWN_PLOT == SimulationResultsImpl__openFile(reffilename,&simresglob_ref)) {
    char *str = (char*) GC_malloc(35+strlen(reffilename));
    *str = 0;
    strcat(strcat(str,"Error opening reference file: "), reffilename);
    void *res = mmc_mk_scon(str);
    GC_free(str);
    return mmc_mk_cons(res,mmc_mk_nil());
  }

  size = SimulationResultsImpl__readSimulationResultSize(filename,&simresglob_c);
  /* fprintf(stderr, "Read size of File %s size= %d\n", filename,size); */
  size_ref = SimulationResultsImpl__readSimulationResultSize(reffilename,&simresglob_ref);
  /* fprintf(stderr, "Read size of File %s size= %d\n", reffilename,size_ref); */

  /* get vars to compare */
  cmpvars = getVars(vars,&ncmpvars);
  /* if no var compare all vars */
  allvars = SimulationResultsImpl__readVarsFilterAliases(filename,&simresglob_c);
  allvarsref = SimulationResultsImpl__readVarsFilterAliases(reffilename,&simresglob_ref);
  if (ncmpvars==0) {
    suggestReadAll = 1;
    cmpvars = getVars(allvarsref,&ncmpvars);
    if (ncmpvars==0) return mmc_mk_cons(mmc_mk_scon("Error Get Vars!"),mmc_mk_nil());
  }
#ifdef DEBUGOUTPUT
  fprintf(stderr, "Compare Vars:\n");
  for(i=0;i<ncmpvars;i++)
    fprintf(stderr, "Var: %s\n", cmpvars[i]);
#endif
  /*  get time */
  /* fprintf(stderr, "get time\n"); */
  timeVarName = getTimeVarName(allvars);
  timeVarNameRef = getTimeVarName(allvarsref);
  time = getData(timeVarName,filename,size,suggestReadAll,&simresglob_c,runningTestsuite);
  if (time.n==0) {
    return mmc_mk_cons(mmc_mk_scon("Error get time!"),mmc_mk_nil());
  }
  /* fprintf(stderr, "get reftime\n"); */
  timeref = getData(timeVarNameRef,reffilename,size_ref,suggestReadAll,&simresglob_ref,runningTestsuite);
  if (timeref.n==0) {
    return mmc_mk_cons(mmc_mk_scon("Error get ref time!"),mmc_mk_nil());
  }
  cmpdiffvars = (char**)GC_malloc(sizeof(char*)*(ncmpvars));
  /* check if time is larger or less reftime */
  res = mmc_mk_nil();
  if (fabs(time.data[time.n-1]-timeref.data[timeref.n-1]) > reltol*fabs(timeref.data[timeref.n-1])) {
    char buf[WARNINGBUFFSIZE];
#ifdef DEBUGOUTPUT
    fprintf(stderr, "max time value=%.15g ref max time value: %.15g\n",time.data[time.n-1],timeref.data[timeref.n-1]);
#endif
    snprintf(buf,WARNINGBUFFSIZE,"Resultfile and Reference have different end time points!\n"
    "Reffile[%d]=%f\n"
    "File[%d]=%f\n",timeref.n,timeref.data[timeref.n-1],time.n,time.data[time.n-1]);
    c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_warning, buf, NULL, 0);
  }
  var1=NULL;
  var2=NULL;
  /* compare vars */
  /* fprintf(stderr, "compare vars\n"); */
  for (i=0;i<ncmpvars;i++) {
    var = cmpvars[i];
    len = strlen(var);
    if (var1) {
      free(var1);
      var1 = NULL;
    }
    var1 = (char*) GC_malloc(len+10);
    k = 0;
    for (j=0;j<len;j++) {
      if (var[j] !='\"' ) {
        var1[k] = var[j];
        k +=1;
      }
    }
    var1[k] = 0;
    /* fprintf(stderr, "compare var: %s\n",var); */
    /* check if in ref_file */
    dataref = getData(var1,reffilename,size_ref,suggestReadAll,&simresglob_ref,runningTestsuite);
    if (dataref.n==0) {
      if (dataref.data) {
        free(dataref.data);
      }
      if (var1) {
        GC_free(var1);
        var1 = NULL;
      }
      msg[0] = runningTestsuite ? SystemImpl__basename(reffilename) : reffilename;
      msg[1] = var;
      c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_warning, gettext("Get data of variable %s from file %s failed!\n"), msg, 2);
      ngetfailedvars++;
      continue;
    }
    /*  check if in file */
    data = getData(var1,filename,size,suggestReadAll,&simresglob_c,runningTestsuite);
    if (data.n==0)  {
      if (data.data) {
        free(data.data);
      }
      if (var1) {
        GC_free(var1);
        var1 = NULL;
      }
      msg[0] = runningTestsuite ? SystemImpl__basename(filename) : filename;
      msg[1] = var;
      c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_warning, gettext("Get data of variable %s from file %s failed!\n"), msg, 2);
      ngetfailedvars++;
      continue;
    }
    /* compare */
    if (isHtml) {
      vardiffindx = cmpDataTubes(isResultCmp,var,&time,&timeref,&data,&dataref,reltol,rangeDelta,reltolDiffMaxMin,&ddf,cmpdiffvars,vardiffindx,keepEqualResults,&res,resultfilename,failVars,1,htmlOut);
    } else if (isResultCmp) {
      vardiffindx = cmpData(isResultCmp,var,&time,&timeref,&data,&dataref,reltol,abstol,&ddf,cmpdiffvars,vardiffindx,keepEqualResults,&res,resultfilename);
    } else {
      vardiffindx = cmpDataTubes(isResultCmp,var,&time,&timeref,&data,&dataref,reltol,rangeDelta,reltolDiffMaxMin,&ddf,cmpdiffvars,vardiffindx,keepEqualResults,&res,resultfilename,failVars,0,0);
    }
    /* free */
    if (dataref.data) {
      free(dataref.data);
    }
    if (data.data) {
      free(data.data);
    }
    if (var1) {
      GC_free(var1);
      var1 = NULL;
    }
  }

  if (isResultCmp) {
    if (writeLogFile(resultfilename,&ddf,filename,reffilename,reltol,abstol)) {
      c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_warning, gettext("Cannot write to the difference (.csv) file!\n"), msg, 0);
    }

    if ((ddf.n > 0) || (ngetfailedvars > 0) || vardiffindx > 0){
      /* fprintf(stderr, "diff: %d\n",ddf.n); */
      /* for (i=0;i<vardiffindx;i++)
      fprintf(stderr, "diffVar: %s\n",cmpdiffvars[i]); */
      for (i=0;i<vardiffindx;i++){
        res = (void*)mmc_mk_cons(mmc_mk_scon(cmpdiffvars[i]),res);
      }
      res = mmc_mk_cons(mmc_mk_scon("Files not Equal!"),res);
      c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_warning, gettext("Files not Equal\n"), msg, 0);
    } else {
      res = mmc_mk_cons(mmc_mk_scon("Files Equal!"),res);
    }
  } else {
    if (success) {
      *success = ((ddf.n == 0) && (vardiffindx == 0));
    }
  }

  // if (var1) free(var1);
  // if (var2) free(var2);
  if (ddf.data) free(ddf.data);
  if (cmpvars) GC_free(cmpvars);
  if (time.data) free(time.data);
  if (timeref.data) free(timeref.data);
  if (cmpdiffvars) GC_free(cmpdiffvars);
  /* close files */
  SimulationResultsImpl__close(&simresglob_c);
  SimulationResultsImpl__close(&simresglob_ref);

  return res;
}

