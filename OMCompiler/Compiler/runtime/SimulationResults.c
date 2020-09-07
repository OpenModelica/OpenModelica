#include "util/read_matlab4.h"
#include "util/write_matlab4.h"
#include <stdint.h>
#include <string.h>
#include "errorext.h"
#include "systemimpl.h"
#include "ptolemyio.h"
#include "util/read_csv.h"
#include <math.h>
#include <gc.h>
#include "util/omc_file.h"
#include "util/omc_msvc.h" /* For INFINITY and NAN */
#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>

#if defined(__MINGW32__) || defined(_MSC_VER)
#define stat _stat
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
  time_t mtime;
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
#if defined(__MINGW32__) || defined(_MSC_VER)
  struct _stat buf;
#else
  struct stat buf = {0} /* Zero this or valgrind complains */;
#endif

  if (simresglob->curFileName && 0==strcmp(filename,simresglob->curFileName)) {
    /* Also check that the file was not modified */
    if (omc_stat(filename, &buf)==0 && difftime(buf.st_mtime,simresglob->mtime)==0.0) {
      return simresglob->curFormat; // Super cache :)
    }
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
    simresglob->pltReader = omc_fopen(filename, "r");
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

static void* makeOMCStyle(const char *var, int omcStyle)
{
  char *res1 = NULL;
  const char *res2 = NULL;
  if (!omcStyle) {
    return mmc_mk_scon(var);
  }
  res1 = openmodelicaStyleVariableName(var);
  res2 = _replace(res1 ? res1 : var, " ", "");
  if (res1 == NULL) {
    free(res1);
  }
  return mmc_mk_scon(res2);
}

static void* SimulationResultsImpl__readVars(const char *filename, int readParameters, int omcStyle, SimulationResult_Globals* simresglob)
{
  const char *msg[2] = {"",""};
  void *res;
  if (UNKNOWN_PLOT == SimulationResultsImpl__openFile(filename,simresglob)) {
    return mmc_mk_nil();
  }
  res = mmc_mk_nil();
  switch (simresglob->curFormat) {
  case MATLAB4: {
    int i;
    for (i=simresglob->matReader.nall-1; i>=0; i--) {
      if (readParameters || !simresglob->matReader.allInfo[i].isParam) {
        res = mmc_mk_cons(makeOMCStyle(simresglob->matReader.allInfo[i].name, omcStyle),res);
      }
    }
    return res;
  }
  case PLT: {
    return read_ptolemy_variables(filename /* Assume it is in OMC style */);
  }
  case CSV: {
    if (simresglob->csvReader && simresglob->csvReader->variables) {
      char **variables = simresglob->csvReader->variables;
      int i;
      for (i=simresglob->csvReader->numvars-1; i>=0; i--) {
        if (variables[i][0] != '\0') {
          res = mmc_mk_cons(makeOMCStyle(variables[i], omcStyle),res);
        }
      }
    }
    return res;
  }
  default:
    msg[0] = PlotFormatStr[simresglob->curFormat];
    c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("readSimulationResultSize() not implemented for plot format: %s"), msg, 1);
    return mmc_mk_nil();
  }
}

static void* SimulationResultsImpl__readVarsFilterAliases(const char *filename, SimulationResult_Globals* simresglob)
{
  if (UNKNOWN_PLOT == SimulationResultsImpl__openFile(filename,simresglob)) {
    return mmc_mk_nil();
  }
  switch (simresglob->curFormat) {
  case MATLAB4: {
    void *res = mmc_mk_nil();
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
      res = mmc_mk_cons(mmc_mk_scon(simresglob->matReader.allInfo[i].name),res);
    }
    free(params);
    free(vars);
    return res;
  }
  default: return SimulationResultsImpl__readVars(filename, 0, 0, simresglob);
  }
}

static void* SimulationResultsImpl__readDataset(const char *filename, void *vars, int dimsize, int suggestReadAllVars, SimulationResult_Globals* simresglob, int runningTestsuite)
{
  const char *msg[2] = {"",""};
  void *res,*col;
  char *var;
  double *vals;
  int i;
  if (UNKNOWN_PLOT == SimulationResultsImpl__openFile(filename,simresglob)) {
    return NULL;
  }
  res = mmc_mk_nil();
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
    while (MMC_NILHDR != MMC_GETHDR(vars)) {
      var = MMC_STRINGDATA(MMC_CAR(vars));
      vars = MMC_CDR(vars);
      mat_var = omc_matlab4_find_var(&simresglob->matReader,var);
      if (mat_var == NULL) {
        msg[0] = runningTestsuite ? SystemImpl__basename(filename) : filename;
        msg[1] = var;
        c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("Could not read variable %s in file %s."), msg, 2);
        return NULL;
      } else if (mat_var->isParam) {
        col=mmc_mk_nil();
        for (i=0;i<dimsize;i++) col=mmc_mk_cons(mmc_mk_rcon((mat_var->index<0)?-simresglob->matReader.params[abs(mat_var->index)-1]:simresglob->matReader.params[abs(mat_var->index)-1]),col);
        res = mmc_mk_cons(col,res);
      } else {
        vals = omc_matlab4_read_vals(&simresglob->matReader,mat_var->index);
        col=mmc_mk_nil();
        for (i=0;i<dimsize;i++) col=mmc_mk_cons(mmc_mk_rcon(vals[i]),col);
        res = mmc_mk_cons(col,res);
      }
    }
    return res;
  }
  case PLT: {
    return read_ptolemy_dataset(filename,vars,dimsize);
  }
  case CSV: {
    while (MMC_NILHDR != MMC_GETHDR(vars)) {
      var = MMC_STRINGDATA(MMC_CAR(vars));
      vars = MMC_CDR(vars);
      vals = simresglob->csvReader ? read_csv_dataset(simresglob->csvReader,var) : NULL;
      if (vals == NULL) {
        msg[0] = runningTestsuite ? SystemImpl__basename(filename) : filename;
        msg[1] = var;
        c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("Could not read variable %s in file %s."), msg, 2);
        return NULL;
      } else {
        col=mmc_mk_nil();
        for (i=0;i<dimsize;i++) {
          col=mmc_mk_cons(mmc_mk_rcon(vals[i]),col);
        }
        res = mmc_mk_cons(col,res);
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

static inline int failedToWriteToFileImpl(const char *file, const char *sourceFile, const char *line)
{
  const char *msg[3] = {file,line,sourceFile};
  c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("%s:%s: Failed to write to file %s."), msg, 3);
  return 0;
}

#define STR_HELPER(x) #x
#define STR(x) STR_HELPER(x)
#define failedToWriteToFile(file) failedToWriteToFileImpl(file, __FILE__, STR(__LINE__))


static inline int intMax(int a, int b)
{
  return a>b ? a : b;
}

static int endsWith(const char *s, const char *suffix)
{
  s = strrchr(s, *suffix);
  if (s != NULL) {
    return 0==strcmp(s, suffix);
  } else {
    return 0;
  }
}
int SimulationResults_filterSimulationResults(const char *inFile, const char *outFile, void *vars, int numberOfIntervals, int removeDescription)
{
  const char *msg[5] = {"","","","",""};
  void *tmp;
  if (UNKNOWN_PLOT == SimulationResultsImpl__openFile(inFile, &simresglob)) {
    return 0;
  }
  vars = mmc_mk_cons(mmc_mk_scon("time"),vars);
  switch (simresglob.curFormat) {
  case MATLAB4: {
    int numToFilter = listLength(vars);
    int i, j;
    int numUnique = 0;
    int numUniqueParam = 1;
    int longestName = 0;
    int longestDesc = 0;
    ModelicaMatVariable_t **mat_var = omc_alloc_interface.malloc(numToFilter*sizeof(ModelicaMatVariable_t*));
    int *indexes = (int*) omc_alloc_interface.malloc(simresglob.matReader.nvar*sizeof(int)); /* Need it to be zeros; note that the actual number of indexes is smaller */
    int *parameter_indexes = (int*) omc_alloc_interface.malloc(simresglob.matReader.nparam*sizeof(int)); /* Need it to be zeros; note that the actual number of indexes is smaller */
    int *indexesToOutput = NULL;
    int *parameter_indexesToOutput = NULL;
    FILE *fout = NULL;
    char *tmp;
    double start = omc_matlab4_startTime(&simresglob.matReader);
    double stop = omc_matlab4_stopTime(&simresglob.matReader);
    double start_stop[2] = {start, stop};
    parameter_indexes[0] = 1; /* time */
    omc_matlab4_read_all_vals(&simresglob.matReader);
    if (endsWith(outFile,".csv")) {
      double **vals = omc_alloc_interface.malloc(sizeof(double*)*numToFilter);
      FILE *fout = NULL;
      for (i=0; i<numToFilter; i++) {
        const char *var = MMC_STRINGDATA(MMC_CAR(vars));
        vars = MMC_CDR(vars);
        mat_var[i] = omc_matlab4_find_var(&simresglob.matReader, var);
        if (mat_var[i] == NULL) {
          msg[0] = SystemImpl__basename(inFile);
          msg[1] = var;
          c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("Could not read variable %s in file %s."), msg, 2);
          return 0;
        }
        if (mat_var[i]->isParam) {
          msg[0] = var;
          c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("Could not filter parameter %s since the output format is CSV (only variables are allowed)."), msg, 1);
          return 0;
        } else {
          vals[i] = omc_matlab4_read_vals(&simresglob.matReader, mat_var[i]->index);
        }
      }
      fout = fopen(outFile, "w");
      fprintf(fout, "time");
      for (i=1; i<numToFilter; i++) {
        fprintf(fout, ",\"%s\"", mat_var[i]->name);
      }
      fprintf(fout, ",nrows=%d\n", simresglob.matReader.nrows);
      for (i=0; i<simresglob.matReader.nrows; i++) {
        fprintf(fout, "%.15g", vals[0][i]);
        for (j=1; j<numToFilter; j++) {
          fprintf(fout, ",%.15g", vals[j][i]);
        }
        fprintf(fout, "\n");
      }
      fclose(fout);
      return 1;
    } /* Not CSV */

    for (i=0; i<numToFilter; i++) {
      const char *var = MMC_STRINGDATA(MMC_CAR(vars));
      vars = MMC_CDR(vars);
      mat_var[i] = omc_matlab4_find_var(&simresglob.matReader,var);
      if (mat_var[i] == NULL) {
        msg[0] = SystemImpl__basename(inFile);
        msg[1] = var;
        c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("Could not read variable %s in file %s."), msg, 2);
        return 0;
      }
      if (mat_var[i]->isParam) {
        /* Store the old index in the array */
        if (0==parameter_indexes[abs(mat_var[i]->index)-1]++) {
          numUniqueParam++;
        }
      } else {
        /* Store the old index in the array */
        if (0==indexes[abs(mat_var[i]->index)-1]++) {
          numUnique++;
        }
      }
      longestName = intMax(longestName, strlen(mat_var[i]->name));
      longestDesc = intMax(longestDesc, strlen(mat_var[i]->descr));
    }
    /* Create the list of variable indexes to output */
    indexesToOutput = omc_alloc_interface.malloc_atomic(numUnique * sizeof(int));
    parameter_indexesToOutput = omc_alloc_interface.malloc_atomic(numUniqueParam * sizeof(int));
    j=0;
    for (i=0; i<simresglob.matReader.nvar; i++) {
      if (indexes[i]) {
        indexesToOutput[j++] = i+1;
      }
      /* indexes becomes the lookup table from old index to new index */
      indexes[i] = j;
    }
    j=0;
    for (i=0; i<simresglob.matReader.nparam; i++) {
      if (parameter_indexes[i]) {
        parameter_indexesToOutput[j++] = i+1;
      }
      /* indexes becomes the lookup table from old index to new index */
      parameter_indexes[i] = j;
    }
    fout = fopen(outFile, "wb");
    if (fout == NULL) {
      return failedToWriteToFile(outFile);
    }
    /* Matrix list: "Aclass" "name" "description" "dataInfo" "data_1" "data_2" */
    if (writeMatVer4AclassNormal(fout)) {
      return failedToWriteToFile(outFile);
    }
    if (writeMatVer4MatrixHeader(fout, "name", numToFilter, longestName, sizeof(int8_t))) {
      return failedToWriteToFile(outFile);
    }

    tmp = omc_alloc_interface.malloc(numToFilter*longestName);
    for (i=0; i<numToFilter; i++) {
      int len = strlen(mat_var[i]->name);
      for (j=0; j<len; j++) {
        tmp[numToFilter*j+i] = mat_var[i]->name[j];
      }
    }
    if (1 != fwrite(tmp, numToFilter*longestName, 1, fout)) {
      return failedToWriteToFile(outFile);
    }
    GC_free(tmp);

    if (removeDescription) {
      if (writeMatVer4MatrixHeader(fout, "description", numToFilter, 0, sizeof(int8_t))) {
        return failedToWriteToFile(outFile);
      }
    } else {
      if (writeMatVer4MatrixHeader(fout, "description", numToFilter, longestDesc, sizeof(int8_t))) {
        return failedToWriteToFile(outFile);
      }

      tmp = omc_alloc_interface.malloc(numToFilter*longestDesc);
      for (i=0; i<numToFilter; i++) {
        int len = strlen(mat_var[i]->descr);
        for (j=0; j<len; j++) {
          tmp[numToFilter*j+i] = mat_var[i]->descr[j];
        }
      }
      if (1 != fwrite(tmp, numToFilter*longestDesc, 1, fout)) {
        return failedToWriteToFile(outFile);
      }
      GC_free(tmp);
    }

    if (writeMatVer4MatrixHeader(fout, "dataInfo", numToFilter, 4, sizeof(int32_t))) {
      return failedToWriteToFile(outFile);
    }
    for (i=0; i<numToFilter; i++) {
      int32_t x = mat_var[i]->isParam ? 1 : 2; /* data_1 or data_2 */
      if (1 != fwrite(&x, sizeof(int32_t), 1, fout)) {
        return failedToWriteToFile(outFile);
      }
    }
    for (i=0; i<numToFilter; i++) {
      int32_t x = (mat_var[i]->index < 0 ? -1 : 1) * (mat_var[i]->isParam ? parameter_indexes[abs(mat_var[i]->index)-1] : indexes[abs(mat_var[i]->index)-1]);
      if (1 != fwrite(&x, sizeof(int32_t), 1, fout)) {
        return failedToWriteToFile(outFile);
      }
    }
    for (i=0; i<numToFilter; i++) {
      int32_t x = 0; /* linear interpolation */
      if (1 != fwrite(&x, sizeof(int32_t), 1, fout)) {
        return failedToWriteToFile(outFile);
      }
    }
    for (i=0; i<numToFilter; i++) {
      int32_t x = -1; /* not defined outside the time interval */
      if (1 != fwrite(&x, sizeof(int32_t), 1, fout)) {
        return failedToWriteToFile(outFile);
      }
    }

    if (writeMatVer4MatrixHeader(fout, "data_1", 2, numUniqueParam, sizeof(double))) {
      return failedToWriteToFile(outFile);
    }

    if (1 != fwrite(start_stop, sizeof(double)*2, 1, fout)) {
      return failedToWriteToFile(outFile);
    }

    for (i=1; i<numUniqueParam; i++) {
      int paramIndex = parameter_indexesToOutput[i];
      double d[2] = {simresglob.matReader.params[abs(paramIndex)-1],0};
      d[1] = d[0];
      if (1!=fwrite(d, sizeof(double)*2, 1, fout)) {
        return failedToWriteToFile(outFile);
      }
    }

    if (numberOfIntervals) {
      double *timevals = omc_matlab4_read_vals(&simresglob.matReader, 1);
      int last_found=0;
      int nevents=0, neventpoints=0;
      for (i=1; i<numberOfIntervals; i++) {
        double t = start + (stop-start)*((double)i)/numberOfIntervals;
        while (timevals[j]<=t) {
          if (timevals[j]==timevals[j+1]) {
            while (timevals[j]==timevals[j+1]) {
              j++;
              neventpoints++;
            }
            nevents++;
          }
          j++;
        }
      }
      msg[4] = inFile;
      GC_asprintf(msg+3, "%d", simresglob.matReader.nrows);
      GC_asprintf(msg+2, "%d", numberOfIntervals);
      GC_asprintf(msg+1, "%d", nevents);
      GC_asprintf(msg+0, "%d", neventpoints);
      c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_notification, gettext("Resampling %s from %s points to %s points, removing %s events stored in %s points.\n"), msg, 5);
    }

    if (writeMatVer4MatrixHeader(fout, "data_2", numberOfIntervals ? numberOfIntervals+1 : simresglob.matReader.nrows, numUnique, sizeof(double))) {
      return failedToWriteToFile(outFile);
    }
    for (i=0; i<numUnique; i++) {
      double *vals = NULL;
      int nrows;
      if (numberOfIntervals) {
        omc_matlab4_read_all_vals(&simresglob.matReader);
        nrows = numberOfIntervals+1;
        vals = omc_alloc_interface.malloc_atomic(sizeof(double)*nrows);
        for (j=0; j<=numberOfIntervals; j++) {
          double t = j==numberOfIntervals ? stop : start + (stop-start)*((double)j)/numberOfIntervals;
          ModelicaMatVariable_t var = {0};
          var.name="";
          var.descr="";
          var.isParam=0;
          var.index=indexesToOutput[i];
          if (omc_matlab4_val(vals+j, &simresglob.matReader, &var, t)) {
            msg[2] = inFile;
            GC_asprintf(msg+1, "%d", indexesToOutput[i]);
            GC_asprintf(msg+0, "%.15g", t);
            c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("Resampling %s failed to get variable %s at time %s.\n"), msg, 3);
            return 0;
          }
        }
      } else {
        vals = omc_matlab4_read_vals(&simresglob.matReader, indexesToOutput[i]);
        nrows = simresglob.matReader.nrows;
      }
      if (nrows > 0) {
        if (1!=fwrite(vals, sizeof(double)*nrows, 1, fout)) {
          fprintf(stderr, "nrows=%d\n", nrows);
          return failedToWriteToFile(outFile);
        }
      }
      if (numberOfIntervals) {
        GC_free(vals);
      }
    }
    fclose(fout);
    return 1;
  }
  default:
    msg[0] = PlotFormatStr[simresglob.curFormat];
    c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("filterSimulationResults not implemented for plot format: %s\n"), msg, 1);
    return 0;
  }
}
