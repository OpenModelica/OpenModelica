#include "read_matlab4.h"
#include <stdint.h>
#include <string.h>
#include "errorext.h"
#include "systemimpl.h"
#include "ptolemyio.h"
#include "read_csv.h"
#include <math.h>
#include <gc.h>
#include "omc_msvc.h" /* For INFINITY and NAN */
#if !defined(__MINGW32__) && !defined(_MSC_VER)
#include <time.h>
#include <sys/stat.h>
#endif

#if defined(_MSC_VER)
#define fmax(x, y) ((x>y)?x:y)
#define fmin(x, y) ((x<y)?x:y)
#define snprintf sprintf_s
#endif

typedef enum {
  UNKNOWN_PLOT=0,
  MATLAB4,
  PLT,
  CSV
} PlotFormat;
const char *PlotFormatStr[] = {"Unknown","MATLAB4","PLT","CSV"};

typedef struct {
  PlotFormat curFormat;
  char *curFileName;
#if !defined(__MINGW32__) && !defined(_MSC_VER)
  time_t mtime;
#endif
  ModelicaMatReader matReader;
  FILE *pltReader;
  struct csv_data *csvReader;
} SimulationResult_Globals;

static SimulationResult_Globals simresglob = {
  UNKNOWN_PLOT,
  0
};

static void SimulationResultsImpl__close(SimulationResult_Globals* simresglob)
{
  switch (simresglob->curFormat) {
  case MATLAB4: omc_free_matlab4_reader(&simresglob->matReader); break;
  case PLT: fclose(simresglob->pltReader); break;
  case CSV: omc_free_csv_reader(simresglob->csvReader); simresglob->csvReader=NULL; break;
  default: break;
  }
  simresglob->curFormat = UNKNOWN_PLOT;
  if (simresglob->curFileName) free(simresglob->curFileName);
  simresglob->curFileName = NULL;
}

static PlotFormat SimulationResultsImpl__openFile(const char *filename, SimulationResult_Globals* simresglob)
{
  PlotFormat format;
  int len = strlen(filename);
  const char *msg[] = {"",""};
#if !defined(__MINGW32__) && !defined(_MSC_VER)
  struct stat buf = {0} /* Zero this or valgrind complains */;
#endif
  if (simresglob->curFileName && 0==strcmp(filename,simresglob->curFileName)) {
#if defined(__MINGW32__) || defined(_MSC_VER)
    return simresglob->curFormat; // Super cache :)
#else
    /* Also check that the file was not modified */
    if (stat(filename, &buf)==0 && difftime(buf.st_mtime,simresglob->mtime)==0.0) {
      return simresglob->curFormat; // Super cache :)
    }
#endif
  }
  // Start by closing the old file...
  SimulationResultsImpl__close(simresglob);

  if (len < 5) format = UNKNOWN_PLOT;
  else if (0 == strcmp(filename+len-4, ".mat")) format = MATLAB4;
  else if (0 == strcmp(filename+len-4, ".plt")) format = PLT;
  else if (0 == strcmp(filename+len-4, ".csv")) format = CSV;
  else {
    msg[0] = filename;
    c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("Unknown result-file suffix of file '%s'"), msg, 1);
    format = UNKNOWN_PLOT;
  }
  switch (format) {
  case MATLAB4:
    if (0!=(msg[0]=omc_new_matlab4_reader(filename,&simresglob->matReader))) {
      msg[1] = filename;
      c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("Failed to open simulation result %s: %s"), msg, 2);
      return UNKNOWN_PLOT;
    }
    break;
  case PLT:
    simresglob->pltReader = fopen(filename, "r");
    if (simresglob->pltReader==NULL) {
      msg[1] = filename;
      c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("Failed to open simulation result %s: %s"), msg, 2);
      return UNKNOWN_PLOT;
    }
    break;
  case CSV:
    simresglob->csvReader = read_csv(filename);
    if (simresglob->csvReader==NULL) {
      msg[1] = filename;
      c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("Failed to open simulation result %s: %s"), msg, 2);
      return UNKNOWN_PLOT;
    }
    break;
  default:
    msg[0] = filename;
    c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("Failed to open simulation result %s"), msg, 1);
    return UNKNOWN_PLOT;
  }

  simresglob->curFormat = format;
  simresglob->curFileName = strdup(filename);
#if !defined(__MINGW32__) && !defined(_MSC_VER)
  stat(filename, &buf);
  simresglob->mtime = buf.st_mtime;
#endif
  // fprintf(stderr, "SimulationResultsImpl__openFile(%s) => %s\n", filename, PlotFormatStr[curFormat]);
  return simresglob->curFormat;
}

static double SimulationResultsImpl__val(const char *filename, const char *varname, double timeStamp, SimulationResult_Globals* simresglob)
{
  double res;
  const char *msg[4] = {"","","",""};
  if (UNKNOWN_PLOT == SimulationResultsImpl__openFile(filename,simresglob)) {
    return NAN;
  }
  switch (simresglob->curFormat) {
  case MATLAB4: {
    ModelicaMatVariable_t *var;
    if (0 == (var=omc_matlab4_find_var(&simresglob->matReader,varname))) {
      msg[1] = varname;
      msg[0] = filename;
      c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("%s not found in %s\n"), msg, 2);
      return NAN;
    }
    if (omc_matlab4_val(&res,&simresglob->matReader,var,timeStamp)) {
      char buf[64],buf2[64],buf3[64];
      snprintf(buf,60,"%g",timeStamp);
      snprintf(buf2,60,"%g",omc_matlab4_startTime(&simresglob->matReader));
      snprintf(buf3,60,"%g",omc_matlab4_stopTime(&simresglob->matReader));
      msg[3] = varname;
      msg[2] = buf;
      msg[1] = buf2;
      msg[0] = buf3;
      c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("%s not defined at time %s (startTime=%s, stopTime=%s)."), msg, 4);
      return NAN;
    }
    return res;
  }
  case PLT: {
    char *strToFind = (char*) malloc(strlen(varname)+30);
    char line[255];
    double pt,t,pv,v,w1,w2;
    int nread=0;
    sprintf(strToFind,"DataSet: %s\n",varname);
    fseek(simresglob->pltReader,0,SEEK_SET);
    do {
      if (NULL==fgets(line,255,simresglob->pltReader)) {
        msg[1] = varname;
        msg[0] = filename;
        c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("%s not found in %s\n"), msg, 2);
        return NAN;
      }
    } while (strcmp(strToFind,line));
    free(strToFind);
    while (fscanf(simresglob->pltReader,"%lg, %lg\n",&t,&v) == 2) {
      nread++;
      if (t > timeStamp) break;
      pt = t;
      pv = v;
    };
    if (nread == 0 || nread == 1 || t < timeStamp) {
      char buf[64];
      snprintf(buf,60,"%g",timeStamp);
      msg[1] = varname;
      msg[0] = buf;
      c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("%s not defined at time %s\n"), msg, 2);
      return NAN;
    } else {
      /* Linear interpolation */
      if ((t-pt) == 0.0) return v;
      w1 = (timeStamp - pt) / (t-pt);
      w2 = 1.0 - w1;
      return pv*w2 + v*w1;
    }
  }
  default:
    msg[0] = PlotFormatStr[simresglob->curFormat];
    c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("val() not implemented for plot format: %s\n"), msg, 1);
    return NAN;
  }
}

static int SimulationResultsImpl__readSimulationResultSize(const char *filename, SimulationResult_Globals* simresglob)
{
  const char *msg[2] = {"",""};
  int size;
  if (UNKNOWN_PLOT == SimulationResultsImpl__openFile(filename,simresglob)) {
    return -1;
  }
  switch (simresglob->curFormat) {
  case MATLAB4: {
    return simresglob->matReader.nrows;
  }
  case PLT: {
    size = read_ptolemy_dataset_size(filename);
    msg[0] = filename;
    if (size == -1) c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("Failed to read readSimulationResultSize from file: %s\n"), msg, 1);
    return size;
  }
  case CSV: {
    size = simresglob->csvReader ? simresglob->csvReader->numsteps : -1;
    msg[0] = filename;
    if (size == -1) c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("Failed to read readSimulationResultSize from file: %s\n"), msg, 1);
    return size;
  }
  default:
    msg[0] = PlotFormatStr[simresglob->curFormat];
    c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("readSimulationResultSize() not implemented for plot format: %s\n"), msg, 1);
    return -1;
  }
}

static void* SimulationResultsImpl__readVars(const char *filename, SimulationResult_Globals* simresglob)
{
  const char *msg[2] = {"",""};
  void *res;
  if (UNKNOWN_PLOT == SimulationResultsImpl__openFile(filename,simresglob)) {
    return mk_nil();
  }
  res = mk_nil();
  switch (simresglob->curFormat) {
  case MATLAB4: {
    int i;
    for (i=simresglob->matReader.nall-1; i>=0; i--) res = mk_cons(mk_scon(simresglob->matReader.allInfo[i].name),res);
    return res;
  }
  case PLT: {
    return read_ptolemy_variables(filename);
  }
  case CSV: {
    if (simresglob->csvReader && simresglob->csvReader->variables) {
      char **variables = simresglob->csvReader->variables;
      int i;
      for (i=simresglob->csvReader->numvars-1; i>=0; i--) {
        if (variables[i][0] != '\0') {
          res = mk_cons(mk_scon(variables[i]),res);
        }
      }
    }
    return res;
  }
  default:
    msg[0] = PlotFormatStr[simresglob->curFormat];
    c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("readSimulationResultSize() not implemented for plot format: %s"), msg, 1);
    return mk_nil();
  }
}

static void* SimulationResultsImpl__readVarsFilterAliases(const char *filename, SimulationResult_Globals* simresglob)
{
  const char *msg[2] = {"",""};
  if (UNKNOWN_PLOT == SimulationResultsImpl__openFile(filename,simresglob)) {
    return mk_nil();
  }
  switch (simresglob->curFormat) {
  case MATLAB4: {
    void *res = mk_nil();
    int i;
    int *params = (int*) calloc(simresglob->matReader.nparam+1,sizeof(int));
    int *vars = (int*) calloc(simresglob->matReader.nvar+1,sizeof(int));
    for (i=simresglob->matReader.nall-1; i>=0; i--) {
      if (0 >= simresglob->matReader.allInfo[i].index) continue; /* Negated aliases always have a real variable, so skip it */
      if (simresglob->matReader.allInfo[i].isParam && params[simresglob->matReader.allInfo[i].index]) continue;
      if (!simresglob->matReader.allInfo[i].isParam && vars[simresglob->matReader.allInfo[i].index]) continue;
      if (simresglob->matReader.allInfo[i].isParam) {
        params[simresglob->matReader.allInfo[i].index] = 1;
      } else {
        vars[simresglob->matReader.allInfo[i].index] = 1;
      }
      res = mk_cons(mk_scon(simresglob->matReader.allInfo[i].name),res);
    }
    free(params);
    free(vars);
    return res;
  }
  default: return SimulationResultsImpl__readVars(filename, simresglob);
  }
}

static void* SimulationResultsImpl__readDataset(const char *filename, void *vars, int dimsize, int suggestReadAllVars, SimulationResult_Globals* simresglob)
{
  const char *msg[2] = {"",""};
  void *res,*col;
  char *var;
  double *vals;
  int i;
  if (UNKNOWN_PLOT == SimulationResultsImpl__openFile(filename,simresglob)) {
    return NULL;
  }
  res = mk_nil();
  switch (simresglob->curFormat) {
  case MATLAB4: {
    ModelicaMatVariable_t *mat_var;
    if (dimsize == 0) {
      dimsize = simresglob->matReader.nrows;
    } else if (simresglob->matReader.nrows != dimsize) {
      fprintf(stderr, "dimsize: %d, rows %d\n", dimsize, simresglob->matReader.nrows);
      c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("readDataset(...): Expected and actual dimension sizes do not match."), NULL, 0);
      return NULL;
    }
    if (suggestReadAllVars) {
      omc_matlab4_read_all_vals(&simresglob->matReader);
    }
    while (RML_NILHDR != RML_GETHDR(vars)) {
      var = RML_STRINGDATA(RML_CAR(vars));
      vars = RML_CDR(vars);
      mat_var = omc_matlab4_find_var(&simresglob->matReader,var);
      if (mat_var == NULL) {
        msg[1] = var;
        msg[0] = filename;
        c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("Could not read variable %s in file %s."), msg, 2);
        return NULL;
      } else if (mat_var->isParam) {
        col=mk_nil();
        for (i=0;i<dimsize;i++) col=mk_cons(mk_rcon((mat_var->index<0)?-simresglob->matReader.params[abs(mat_var->index)-1]:simresglob->matReader.params[abs(mat_var->index)-1]),col);
        res = mk_cons(col,res);
      } else {
        vals = omc_matlab4_read_vals(&simresglob->matReader,mat_var->index);
        col=mk_nil();
        for (i=0;i<dimsize;i++) col=mk_cons(mk_rcon(vals[i]),col);
        res = mk_cons(col,res);
      }
    }
    return res;
  }
  case PLT: {
    return read_ptolemy_dataset(filename,vars,dimsize);
  }
  case CSV: {
    while (RML_NILHDR != RML_GETHDR(vars)) {
      var = RML_STRINGDATA(RML_CAR(vars));
      vars = RML_CDR(vars);
      vals = simresglob->csvReader ? read_csv_dataset(simresglob->csvReader,var) : NULL;
      if (vals == NULL) {
        msg[1] = var;
        msg[0] = filename;
        c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("Could not read variable %s in file %s."), msg, 2);
        return NULL;
      } else {
        col=mk_nil();
        for (i=0;i<dimsize;i++) {
          col=mk_cons(mk_rcon(vals[i]),col);
        }
        res = mk_cons(col,res);
      }
    }
    return res;
  }
  default:
    msg[0] = PlotFormatStr[simresglob->curFormat];
    c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("readDataSet() not implemented for plot format: %s\n"), msg, 1);
    return NULL;
  }
}
