#include "read_matlab4.h"
#include <stdint.h>
#include <string.h>
#include "errorext.h"
#include <math.h>
#include "omc_msvc.h" /* For INFINITY and NAN */

typedef enum {
  UNKNOWN_PLOT=0,
  MATLAB4,
  PLT,
  CSV
} PlotFormat;
const char *PlotFormatStr[] = {"Unknown","MATLAB4","PLT","CSV"};

static PlotFormat curFormat = UNKNOWN_PLOT;
static char *curFileName = NULL;
static ModelicaMatReader matReader;
static FILE *pltReader;

static void SimulationResultsImpl__closeFile()
{
  switch (curFormat) {
  case MATLAB4: omc_free_matlab4_reader(&matReader); break;
  case PLT: fclose(pltReader); break;
  }
  curFormat = UNKNOWN_PLOT;
  if (curFileName) free(curFileName);
  curFileName = NULL;
}

static PlotFormat SimulationResultsImpl__openFile(const char *filename)
{
  PlotFormat format;
  int len = strlen(filename);
  const char *msg[] = {"",""};
  if (curFileName && 0==strcmp(filename,curFileName)) return curFormat; // Super cache :)
  // Start by closing the old file...
  SimulationResultsImpl__closeFile();
  
  if (len < 5) format = UNKNOWN_PLOT;
  else if (0 == strcmp(filename+len-4, ".mat")) format = MATLAB4;
  else if (0 == strcmp(filename+len-4, ".plt")) format = PLT;
  else if (0 == strcmp(filename+len-4, ".csv")) format = CSV;
  else format = UNKNOWN_PLOT;
  switch (format) {
  case MATLAB4:
    if (0!=(msg[0]=omc_new_matlab4_reader(filename,&matReader))) {
      msg[1] = filename;
      c_add_message(-1, "SCRIPT", "Error", "Failed to open simulation result %s: %s\n", msg, 2);
      return UNKNOWN_PLOT;
    }
    break;
  case PLT:
    pltReader = fopen(filename, "r");
    if (pltReader==NULL) {
      msg[1] = filename;
      c_add_message(-1, "SCRIPT", "Error", "Failed to open simulation result %s: %s\n", msg, 2);
      return UNKNOWN_PLOT;
    }
    break;
  default:
    msg[0] = filename;
    c_add_message(-1, "SCRIPT", "Error", "Failed to open simulation result %s\n", msg, 1);
    return UNKNOWN_PLOT;
  }

  curFormat = format;
  curFileName = strdup(filename);
  // fprintf(stderr, "SimulationResultsImpl__openFile(%s) => %s\n", filename, PlotFormatStr[curFormat]);
  return curFormat;
}

static double SimulationResultsImpl__val(const char *filename, const char *varname, double timeStamp)
{
  double res;
  const char *msg[2] = {"",""};
  if (UNKNOWN_PLOT == SimulationResultsImpl__openFile(filename)) {
    return NAN;
  }
  switch (curFormat) {
  case MATLAB4: {
    ModelicaMatVariable_t *var;
    if (0 == (var=omc_matlab4_find_var(&matReader,varname))) {
      msg[1] = varname;
      msg[0] = filename;
      c_add_message(-1, "SCRIPT", "Error", "%s not found in %s\n", msg, 2);
      return NAN;
    }
    if (omc_matlab4_val(&res,&matReader,var,timeStamp)) {
      char buf[64];
      snprintf(buf,60,"%g",timeStamp);
      msg[1] = varname;
      msg[0] = buf;
      c_add_message(-1, "SCRIPT", "Error", "%s not defined at time %s\n", msg, 2);
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
    fseek(pltReader,0,SEEK_SET);
    do {
      if (NULL==fgets(line,255,pltReader)) {
        msg[1] = varname;
        msg[0] = filename;
        c_add_message(-1, "SCRIPT", "Error", "%s not found in %s\n", msg, 2);
        return NAN;
      }
    } while (strcmp(strToFind,line));
    while (fscanf(pltReader,"%lg, %lg\n",&t,&v) == 2) {
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
      c_add_message(-1, "SCRIPT", "Error", "%s not defined at time %s\n", msg, 2);
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
    msg[0] = PlotFormatStr[curFormat];
    c_add_message(-1, "SCRIPT", "Error", "val() not implemented for plot format: %s\n", msg, 1);
    return NAN;
  }
}
