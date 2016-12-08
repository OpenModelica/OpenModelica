/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

/* The recon wall format is optimized for writing */

#include "util/omc_error.h"
#include "simulation_result_wall.h"
#include "util/rtclock.h"
#include "meta/meta_modelica.h"

#include <fstream>
#include <string.h>
#include <assert.h>

#if defined(__MINGW32__) || defined(_MSC_VER)
#include <winsock2.h> /* htonl */
#if defined(_MSC_VER)
#include <stdint.h> /* for int32_t */
#endif
#else
#include <arpa/inet.h> /* htonl */
#endif

#define PARAM_TABLE_NAME "params"
#define CONT_TABLE_NAME "continuous"

extern "C" {

typedef struct wall_storage {
  std::ofstream fp;
  long header_length;
  long data_start;
} wall_storage;

static void msgpack_obj_header(std::ofstream &fp, int n) {
  static char buffer[1];
  static int32_t ibuffer;
  buffer[0] = 0xDF;
  ibuffer = htonl(n);
  fp.write(buffer, 1);
  fp.write((char *)&ibuffer, 4);
}

static void msgpack_array_header(std::ofstream &fp, int n) {
  static char buffer[1];
  static int32_t ibuffer;
  buffer[0] = 0xDD;
  ibuffer = htonl(n);
  fp.write(buffer, 1);
  fp.write((char *)&ibuffer, 4);
}

static void msgpack_int32(std::ofstream &fp, int32_t n) {
  static char buffer[1];
  static int32_t ibuffer;
  buffer[0] = 0xd2;
  ibuffer = htonl(n);
  fp.write(buffer, 1);
  fp.write((char *)&ibuffer, 4);
}

static void msgpack_boolean(std::ofstream &fp, bool b) {
  static char buffer[1];
  if (b) buffer[0] = 0xc3;
  else buffer[0] = 0xc2;
  fp.write(buffer, 1);
}

static void raw_uint32(std::ofstream &fp, uint32_t n) {
  static uint32_t ibuffer;
  ibuffer = htonl(n);
  fp.write((char *)&ibuffer, 4);
}

static void msgpack_str(std::ofstream &fp, const char *s)
__attribute__((nonnull));

static void msgpack_str(std::ofstream &fp, const char *s) {
  static char buffer[1];
  int strl = htonl(strlen(s));
  buffer[0] = 0xDB;
  fp.write(buffer, 1);
  fp.write((char*)&strl, 4);
  fp.write(s, strlen(s));
}

static void marshall_double(double d, char *buffer) {
  char *b = (char *)&d;
  if (htonl(1)==1) for(int i=0;i<8;i++) buffer[i] = b[i];
  else for(int i=0;i<8;i++) buffer[7-i] = b[i];
}

static void msgpack_double(std::ofstream &fp, double d) {
  static char buffer[1];
  static char dbuffer[8];

  buffer[0] = 0xcb;
  marshall_double(d, dbuffer);
  fp.write(buffer, 1);
  fp.write(dbuffer, 8);
}

static void write_description(std::ofstream &fp, const char *name, const char *comment) {
  msgpack_str(fp, name); // key
  msgpack_obj_header(fp, 1); // value (is an object of one field)
  msgpack_str(fp, "description"); // field name
  msgpack_str(fp, comment); // field value
}

static void write_alias(std::ofstream &fp, const char *name, const char *sig, bool negate) {
  msgpack_str(fp, name); // alias name
  msgpack_obj_header(fp, negate ? 2 : 1);
  msgpack_str(fp, "s");
  msgpack_str(fp, sig);
  if (negate) { msgpack_str(fp, "t"); msgpack_str(fp, "inv"); }
}

static void write_aliases(std::ofstream &fp, MODEL_DATA *modelData, int include[]) {
  const char *sig = NULL;
  msgpack_str(fp, "als");
  int na = 0; // Number of aliases (include time) for this request
  for(long i=0;i<modelData->nAliasReal;i++)
    na += include[(int)modelData->realAlias[i].aliasType];
  for(long i=0;i<modelData->nAliasInteger;i++)
    na += include[(int)modelData->integerAlias[i].aliasType];
  for(long i=0;i<modelData->nAliasBoolean;i++)
    na += include[(int)modelData->booleanAlias[i].aliasType];
  for(long i=0;i<modelData->nAliasString;i++)
    na += include[(int)modelData->stringAlias[i].aliasType];

  msgpack_obj_header(fp, na);

  for(long i=0;i<modelData->nAliasReal;i++) {
    DATA_REAL_ALIAS *alias = &modelData->realAlias[i];
    if (include[(int)alias->aliasType]==0) continue;
    if (alias->aliasType==2) sig = "time";
    if (alias->aliasType==1) sig = modelData->realParameterData[alias->nameID].info.name;
    if (alias->aliasType==0) sig = modelData->realVarsData[alias->nameID].info.name;
    write_alias(fp, alias->info.name, sig, alias->negate);
  }

  for(long i=0;i<modelData->nAliasInteger;i++) {
    DATA_INTEGER_ALIAS *alias = &modelData->integerAlias[i];
    if (include[(int)alias->aliasType]==0) continue;
    if (alias->aliasType==2) sig = "time";
    if (alias->aliasType==1) sig = modelData->integerParameterData[alias->nameID].info.name;
    if (alias->aliasType==0) sig = modelData->integerVarsData[alias->nameID].info.name;
    write_alias(fp, alias->info.name, sig, alias->negate);
  }

  for(long i=0;i<modelData->nAliasBoolean;i++) {
    DATA_BOOLEAN_ALIAS *alias = &modelData->booleanAlias[i];
    if (include[(int)alias->aliasType]==0) continue;
    if (alias->aliasType==2) sig = "time";
    if (alias->aliasType==1) sig = modelData->booleanParameterData[alias->nameID].info.name;
    if (alias->aliasType==0) sig = modelData->booleanVarsData[alias->nameID].info.name;
    write_alias(fp, alias->info.name, sig, alias->negate);
  }

  for(long i=0;i<modelData->nAliasString;i++) {
    DATA_STRING_ALIAS *alias = &modelData->stringAlias[i];
    if (include[(int)alias->aliasType]==0) continue;
    if (alias->aliasType==2) sig = "time";
    if (alias->aliasType==1) sig = modelData->stringParameterData[alias->nameID].info.name;
    if (alias->aliasType==0) sig = modelData->stringVarsData[alias->nameID].info.name;
    write_alias(fp, alias->info.name, sig, alias->negate);
  }
}

static void write_param_table(std::ofstream &fp, MODEL_DATA *modelData) {
  msgpack_str(fp, PARAM_TABLE_NAME);
  msgpack_obj_header(fp, 4); // params

  msgpack_str(fp, "tmeta");
  msgpack_obj_header(fp, 0); // tmeta

  msgpack_str(fp, "sigs");
  msgpack_array_header(fp, 1+modelData->nParametersReal+modelData->nParametersInteger+
    modelData->nParametersBoolean+modelData->nParametersString);
  msgpack_str(fp, "time");
  for(long i=0;i<modelData->nParametersReal;i++)
    msgpack_str(fp, modelData->realParameterData[i].info.name);
  for(long i=0;i<modelData->nParametersInteger;i++)
    msgpack_str(fp, modelData->integerParameterData[i].info.name);
  for(long i=0;i<modelData->nParametersBoolean;i++)
    msgpack_str(fp, modelData->booleanParameterData[i].info.name);
  for(long i=0;i<modelData->nParametersString;i++)
    msgpack_str(fp, modelData->stringParameterData[i].info.name);

  int include[3] = {0, 1, 0};
  write_aliases(fp, modelData, include);

  msgpack_str(fp, "vmeta");
  msgpack_obj_header(fp, 1+modelData->nParametersReal+modelData->nParametersInteger+
    modelData->nParametersBoolean+modelData->nParametersString);
  write_description(fp, "time", "Time");
  for(long i=0;i<modelData->nParametersReal;i++)
    write_description(fp, modelData->realParameterData[i].info.name,
          modelData->realParameterData[i].info.comment);
  for(long i=0;i<modelData->nParametersInteger;i++)
    write_description(fp, modelData->integerParameterData[i].info.name,
          modelData->integerParameterData[i].info.comment);
  for(long i=0;i<modelData->nParametersBoolean;i++)
    write_description(fp, modelData->booleanParameterData[i].info.name,
          modelData->booleanParameterData[i].info.comment);
  for(long i=0;i<modelData->nParametersString;i++)
    write_description(fp, modelData->stringParameterData[i].info.name,
          modelData->stringParameterData[i].info.comment);
}

static void write_cont_table(std::ofstream &fp, MODEL_DATA *modelData) {
  long nvars = modelData->nVariablesReal+modelData->nVariablesInteger+
    modelData->nVariablesBoolean+modelData->nVariablesString;
  msgpack_str(fp, "continuous");
  msgpack_obj_header(fp, 4); // params

  msgpack_str(fp, "tmeta");
  msgpack_obj_header(fp, 0); // tmeta

  msgpack_str(fp, "sigs");
  msgpack_array_header(fp, nvars+1);
  msgpack_str(fp, "time");
  for(long i=0;i<modelData->nVariablesReal;i++)
    msgpack_str(fp, modelData->realVarsData[i].info.name);
  for(long i=0;i<modelData->nVariablesInteger;i++)
    msgpack_str(fp, modelData->integerVarsData[i].info.name);
  for(long i=0;i<modelData->nVariablesBoolean;i++)
    msgpack_str(fp, modelData->booleanVarsData[i].info.name);
  for(long i=0;i<modelData->nVariablesString;i++)
    msgpack_str(fp, modelData->stringVarsData[i].info.name);

  int include[3] = {1, 0, 1};
  write_aliases(fp, modelData, include);

  msgpack_str(fp, "vmeta");
  msgpack_obj_header(fp, 1+nvars);
  write_description(fp, "time", "Time");
  for(long i=0;i<modelData->nVariablesReal;i++)
    write_description(fp, modelData->realVarsData[i].info.name,
          modelData->realVarsData[i].info.comment);
  for(long i=0;i<modelData->nVariablesInteger;i++)
    write_description(fp, modelData->integerVarsData[i].info.name,
          modelData->integerVarsData[i].info.comment);
  for(long i=0;i<modelData->nVariablesBoolean;i++)
    write_description(fp, modelData->booleanVarsData[i].info.name,
          modelData->booleanVarsData[i].info.comment);
  for(long i=0;i<modelData->nVariablesString;i++)
    write_description(fp, modelData->stringVarsData[i].info.name,
          modelData->stringVarsData[i].info.comment);
}

static void write_header(std::ofstream &fp, MODEL_DATA *modelData) {
  static char buffer[80];

  msgpack_obj_header(fp, 3); // header

  msgpack_str(fp, "fmeta");
  msgpack_obj_header(fp, 0); // fmeta

  msgpack_str(fp, "tabs");
  msgpack_obj_header(fp, 2); // tabs
  write_param_table(fp, modelData);
  write_cont_table(fp, modelData);

  msgpack_str(fp, "objs");
  msgpack_obj_header(fp, 0); // objs
}

/* The purpose of this routine is to do the following (in order):
   - Write ID bytes
   - Write temp header length
   - Write header
   - Adjust header length
   - Seek to end of header
*/
void recon_wall_init(simulation_result *self,DATA *data, threadData_t *threadData)
{
  wall_storage *storage = new wall_storage();
  static char header[14] = {0x72, 0x65, 0x63, 0x6f, 0x6e, 0x3a, 0x77,
          0x61, 0x6c, 0x6c, 0x3a, 0x76, 0x30, 0x31};
  static char blank_length[4] = {0x00, 0x00, 0x00, 0x00};
  self->storage = (void *)storage;
  try {
    storage->fp.open(self->filename, std::ofstream::binary|std::ofstream::trunc);
    if(!storage->fp) {
      throwStreamPrint(threadData, "Cannot open File %s for writing",self->filename);
    }
    /* Write ID */
    storage->fp.write(header, 14);
    /* Store location of header length */
    storage->header_length = storage->fp.tellp();
    /* Fill in empty length info (to be filled in later, after header is written) */
    storage->fp.write(blank_length, 4);
    /* Write header */
    write_header(storage->fp, data->modelData);
    storage->data_start = storage->fp.tellp();
    uint32_t sz = storage->data_start-(storage->header_length+4);
    storage->fp.seekp(storage->header_length);
    raw_uint32(storage->fp, sz);
    storage->fp.seekp(storage->data_start);
  }
  catch(...)
  {
    storage->fp.close();
    throwStreamPrint(threadData, "Error while writing mat file %s",self->filename);
  }
  rt_accumulate(SIM_TIMER_OUTPUT);
}

void write_parameter_data(std::ofstream &fp, double t,
        MODEL_DATA *modelData, const SIMULATION_INFO *sInfo) {
  long i;

  long length_pos = fp.tellp();
  raw_uint32(fp, 0);

  long data_pos = fp.tellp();
  msgpack_obj_header(fp, 1); // table name
  msgpack_str(fp, PARAM_TABLE_NAME);

  msgpack_array_header(fp, 1+modelData->nParametersReal+modelData->nParametersInteger+
    modelData->nParametersBoolean+modelData->nParametersString);

  msgpack_double(fp, t);
  for(i=0;i<modelData->nParametersReal;i++) msgpack_double(fp, sInfo->realParameter[i]);
  for(i=0;i<modelData->nParametersInteger;i++) msgpack_int32(fp, sInfo->integerParameter[i]);
  for(i=0;i<modelData->nParametersBoolean;i++) msgpack_boolean(fp, sInfo->booleanParameter[i]);
  for(i=0;i<modelData->nParametersString;i++) msgpack_str(fp, MMC_STRINGDATA(sInfo->stringParameter[i]));

  long end_pos = fp.tellp();
  fp.seekp(length_pos);
  raw_uint32(fp, end_pos-data_pos);
  fp.seekp(end_pos);
}

void recon_wall_writeParameterData(simulation_result *self,DATA *data, threadData_t *threadData)
{
  wall_storage *storage = (wall_storage *)self->storage;
  std::ofstream &fp = storage->fp;
  MODEL_DATA *modelData = data->modelData;
  const SIMULATION_INFO *sInfo = data->simulationInfo;
  write_parameter_data(fp, sInfo->startTime, modelData, sInfo);
  write_parameter_data(fp, sInfo->stopTime, modelData, sInfo);
}

void recon_wall_emit(simulation_result *self,DATA *data, threadData_t *threadData)
{
  wall_storage *storage = (wall_storage *)self->storage;
  std::ofstream &fp = storage->fp;
  MODEL_DATA *modelData = data->modelData;
  const SIMULATION_INFO *sInfo = data->simulationInfo;

  long i;
  long length_pos = fp.tellp();
  raw_uint32(fp, 0);

  long data_pos = fp.tellp();
  msgpack_obj_header(fp, 1); // table name
  msgpack_str(fp, CONT_TABLE_NAME);

  msgpack_array_header(fp, 1+modelData->nVariablesReal+modelData->nVariablesInteger+
    modelData->nVariablesBoolean+modelData->nVariablesString);

  msgpack_double(fp, data->localData[0]->timeValue);
  for(i=0;i<modelData->nVariablesReal;i++) {
    msgpack_double(fp, data->localData[0]->realVars[i]);
  }
  for(i=0;i<modelData->nVariablesInteger;i++) {
    msgpack_int32(fp, data->localData[0]->integerVars[i]);
  }
  for(i=0;i<modelData->nVariablesBoolean;i++) {
    msgpack_boolean(fp, data->localData[0]->booleanVars[i]);
  }
  for(i=0;i<modelData->nVariablesString;i++) {
    msgpack_str(fp, MMC_STRINGDATA(data->localData[0]->stringVars[i]));
  }

  long end_pos = fp.tellp();
  fp.seekp(length_pos);
  raw_uint32(fp, end_pos-data_pos);
  fp.seekp(end_pos);
}

void recon_wall_free(simulation_result *self,DATA *data, threadData_t *threadData)
{
  wall_storage *storage = (wall_storage *)self->storage;
  storage->fp.close();
  rt_tick(SIM_TIMER_OUTPUT);
  delete storage;
  self->storage = NULL;
  rt_accumulate(SIM_TIMER_OUTPUT);
}

} /* extern C */
