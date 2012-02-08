#include "read_matlab4.h"
#include <stdint.h>
#include <string.h>
#include "errorext.h"
#include "ptolemyio.h"
#include "read_csv.h"
#include <math.h>
#include "omc_msvc.h" /* For INFINITY and NAN */

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
  ModelicaMatReader matReader;
  FILE *pltReader;
  FILE *csvReader;
} SimulationResult_Globals;

void SimulationResultsImpl__close(SimulationResult_Globals* simresglob)
{
  switch (simresglob->curFormat) {
  case MATLAB4: omc_free_matlab4_reader(&simresglob->matReader); break;
  case PLT: fclose(simresglob->pltReader); break;
  case CSV: fclose(simresglob->csvReader); break;
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
  if (simresglob->curFileName && 0==strcmp(filename,simresglob->curFileName)) return simresglob->curFormat; // Super cache :)
  // Start by closing the old file...
  SimulationResultsImpl__close(simresglob);
  
  if (len < 5) format = UNKNOWN_PLOT;
  else if (0 == strcmp(filename+len-4, ".mat")) format = MATLAB4;
  else if (0 == strcmp(filename+len-4, ".plt")) format = PLT;
  else if (0 == strcmp(filename+len-4, ".csv")) format = CSV;
  else format = UNKNOWN_PLOT;
  switch (format) {
  case MATLAB4:
    if (0!=(msg[0]=omc_new_matlab4_reader(filename,&simresglob->matReader))) {
      msg[1] = filename;
      c_add_message(-1, ErrorType_scripting, ErrorLevel_error, "Failed to open simulation result %s: %s\n", msg, 2);
      return UNKNOWN_PLOT;
    }
    break;
  case PLT:
    simresglob->pltReader = fopen(filename, "r");
    if (simresglob->pltReader==NULL) {
      msg[1] = filename;
      c_add_message(-1, ErrorType_scripting, ErrorLevel_error, "Failed to open simulation result %s: %s\n", msg, 2);
      return UNKNOWN_PLOT;
    }
    break;
  case CSV:
    simresglob->csvReader = fopen(filename, "r");
    if (simresglob->csvReader==NULL) {
      msg[1] = filename;
      c_add_message(-1, ErrorType_scripting, ErrorLevel_error, "Failed to open simulation result %s: %s\n", msg, 2);
      return UNKNOWN_PLOT;
    }
    break;
  default:
    msg[0] = filename;
    c_add_message(-1, ErrorType_scripting, ErrorLevel_error, "Failed to open simulation result %s\n", msg, 1);
    return UNKNOWN_PLOT;
  }

  simresglob->curFormat = format;
  simresglob->curFileName = strdup(filename);
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
      c_add_message(-1, ErrorType_scripting, ErrorLevel_error, "%s not found in %s\n", msg, 2);
      res = NAN;
      break;
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
      c_add_message(-1, ErrorType_scripting, ErrorLevel_error, "%s not defined at time %s (startTime=%s, stopTime=%s).", msg, 4);
      res = NAN;
      break;
    }
    break;
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
        c_add_message(-1, ErrorType_scripting, ErrorLevel_error, "%s not found in %s\n", msg, 2);
        res = NAN;
        break;
      }
    } while (strcmp(strToFind,line));
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
      c_add_message(-1, ErrorType_scripting, ErrorLevel_error, "%s not defined at time %s\n", msg, 2);
      res = NAN;
      break;
    } else {
      /* Linear interpolation */
      if ((t-pt) == 0.0) return v;
      w1 = (timeStamp - pt) / (t-pt);
      w2 = 1.0 - w1;
      res = pv*w2 + v*w1;
      break;
    }
  }
  default:
    msg[0] = PlotFormatStr[simresglob->curFormat];
    c_add_message(-1, ErrorType_scripting, ErrorLevel_error, "val() not implemented for plot format: %s\n", msg, 1);
    res = NAN;
    break;
  }
  SimulationResultsImpl__close(simresglob);
  return res;
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
    size = simresglob->matReader.nrows;
    break;
  }
  case PLT: {
    size = read_ptolemy_dataset_size(filename);
    msg[0] = filename;
    if (size == -1) c_add_message(-1, ErrorType_scripting, ErrorLevel_error, "Failed to read readSimulationResultSize from file: %s\n", msg, 1);
    break;
  }
  default:
    msg[0] = PlotFormatStr[simresglob->curFormat];
    c_add_message(-1, ErrorType_scripting, ErrorLevel_error, "readSimulationResultSize() not implemented for plot format: %s\n", msg, 1);
    size = -1;
    break;
  }
  SimulationResultsImpl__close(simresglob);
  return size;
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
    break;
  }
  case PLT: {
    res = read_ptolemy_variables(filename);
    break;
  }
  case CSV: {
    char **variables = read_csv_variables(filename);
    char **toFree = variables;
    while (*variables)
    {
      res = mk_cons(mk_scon(*variables),res);
      free(*variables);
      variables++;
    }
    free(toFree);
    break;
  }
  default:
    msg[0] = PlotFormatStr[simresglob->curFormat];
    c_add_message(-1, ErrorType_scripting, ErrorLevel_error, "readSimulationResultSize() not implemented for plot format: %s", msg, 1);
    return mk_nil();
  }
  SimulationResultsImpl__close(simresglob);
  return res;
}

static void* SimulationResultsImpl__readDataset(const char *filename, void *vars, int dimsize, SimulationResult_Globals* simresglob)
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
      c_add_message(-1, ErrorType_scripting, ErrorLevel_error, "readDataset(...): Expected and actual dimension sizes do not match.", NULL, 0);
      break;
    }
    while (RML_NILHDR != RML_GETHDR(vars)) {
      var = RML_STRINGDATA(RML_CAR(vars));
      vars = RML_CDR(vars);
      mat_var = omc_matlab4_find_var(&simresglob->matReader,var);
      if (mat_var == NULL) {
        msg[1] = var;
        msg[0] = filename;
        c_add_message(-1, ErrorType_scripting, ErrorLevel_error, "Could not read variable %s in file %s.", msg, 2);
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
    break;
  }
  case PLT: {
    res = read_ptolemy_dataset(filename,vars,dimsize);
    break;
  }
  default:
    msg[0] = PlotFormatStr[simresglob->curFormat];
    c_add_message(-1, ErrorType_scripting, ErrorLevel_error, "readDataSet() not implemented for plot format: %s\n", msg, 1);
    break;
  }
  SimulationResultsImpl__close(simresglob);
  return res;
}
