/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#include "simulation_result_rust.h"

#ifdef OM_RUST_RESULT_WRITERS

#include "omc_result.h"
#include "util/omc_error.h"
#include "util/rtclock.h"
#include "simulation/options.h"

#include <cstring>
#include <string>
#include <vector>

extern "C" {

/* A kept array variable: where its scalars start in the runtime's value array
 * and how many there are. Rows are filled from these in signal order. */
struct block { size_t start; size_t len; };

struct rust_result_data
{
  omc_result_writer *writer;
  std::vector<std::string> strings;         /* owns every name/description/unit the signals point at */
  std::vector<omc_result_signal> signals;
  std::vector<int> columnTypes;
  std::vector<block> reals, ints, bools, strs;
  size_t nSensitivities;
  std::vector<double> row;
  std::vector<double> params;
};

static std::string arrayName(const char *name, const DIMENSION_INFO *dimension, size_t linear, modelica_boolean isStateDerivative)
{
  std::string out = name;
  if (dimension == NULL || dimension->numberOfDimensions == 0) {
    return out;
  }
  if (isStateDerivative) {
    out.pop_back(); /* the ")" of der(x): the subscripts go inside it */
  }
  size_t rem = linear;
  for (size_t k = 0; k < dimension->numberOfDimensions; k++) {
    size_t stride = 1;
    for (size_t j = k + 1; j < dimension->numberOfDimensions; j++) {
      stride *= (size_t)dimension->dimensions[j].start;
    }
    out += (k == 0 ? "[" : ",") + std::to_string(rem / stride + 1);
    rem = rem % stride;
  }
  out += "]";
  if (isStateDerivative) {
    out += ")";
  }
  return out;
}

static const char *mmcString(const modelica_string *s)
{
  if (s == NULL || *s == NULL) {
    return "";
  }
  const char *str = MMC_STRINGDATA(*s);
  return str ? str : "";
}

/* A String value travels in the row (or params) as its interned id. */
static double internString(modelica_string s)
{
  return omc_result_intern(mmcString(&s));
}

/* Adds the signals of one (array) variable: scalar_length of them. `column` is
 * the row column of the first scalar for a column signal, -1 for the others. */
static void addSignals(rust_result_data *d, const char *name, const char *comment, const char *unit, const char *displayUnit,
                       int type, int kind, long column, int negate, int unvarying,
                       const DIMENSION_INFO *dimension, modelica_boolean isStateDerivative,
                       modelica_boolean relativeQuantity = FALSE)
{
  size_t n = dimension ? dimension->scalar_length : 1;
  for (size_t i = 0; i < n; i++) {
    /* Pointers into `strings` are taken only after every push_back (open()). */
    d->strings.push_back(arrayName(name, dimension, i, isStateDerivative));
    d->strings.push_back(comment ? comment : "");
    d->strings.push_back(unit ? unit : "");
    d->strings.push_back(displayUnit ? displayUnit : "");
    omc_result_signal s;
    memset(&s, 0, sizeof(s));
    s.type = type;
    s.discrete = type != OMC_RESULT_TYPE_REAL;
    s.kind = kind;
    s.column = kind == OMC_RESULT_KIND_COLUMN ? (unsigned)(column + i) : 0;
    s.negate = negate;
    s.unvarying = unvarying;
    s.relative_quantity = relativeQuantity;
    d->signals.push_back(s);
  }
}

void rust_result_init(simulation_result *self, DATA *data, threadData_t *threadData)
{
  const MODEL_DATA *mData = data->modelData;
  const SIMULATION_INFO *sInfo = data->simulationInfo;
  rust_result_data *d = new rust_result_data();
  d->writer = NULL;
  d->nSensitivities = 0;
  self->storage = d;

  /* Row layout: time, $cpuTime, $solverSteps, kept reals, sensitivities, kept
   * integers, kept booleans, kept strings (as interned ids). */
  long column = 0;
  addSignals(d, "time", "Simulation time", "s", "", OMC_RESULT_TYPE_REAL, OMC_RESULT_KIND_TIME, column++, 0, 0, NULL, FALSE);
  d->columnTypes.push_back(OMC_RESULT_TYPE_REAL);
  if (self->cpuTime) {
    addSignals(d, "$cpuTime", "cpu time", "s", "", OMC_RESULT_TYPE_REAL, OMC_RESULT_KIND_COLUMN, column++, 0, 0, NULL, FALSE);
    d->columnTypes.push_back(OMC_RESULT_TYPE_REAL);
  }
  if (omc_flag[FLAG_SOLVER_STEPS]) {
    addSignals(d, "$solverSteps", "number of steps taken by the integrator", "", "", OMC_RESULT_TYPE_REAL, OMC_RESULT_KIND_COLUMN, column++, 0, 0, NULL, FALSE);
    d->columnTypes.push_back(OMC_RESULT_TYPE_REAL);
  }
  /* Row column of each kept scalar variable, by its index in the value arrays;
   * the aliases look their targets up here. */
  std::vector<long> realColumn(mData->nVariablesReal, -1), intColumn(mData->nVariablesInteger, -1), boolColumn(mData->nVariablesBoolean, -1);
  /* The discrete Reals are the tail of realVarsData. */
  const long firstDiscreteReal = mData->nVariablesRealArray - mData->nDiscreteRealArray;
  auto markDiscrete = [d](size_t from) {
    for (size_t j = from; j < d->signals.size(); j++) d->signals[j].discrete = 1;
  };
  for (int i = 0; i < mData->nVariablesRealArray; i++) {
    const STATIC_REAL_DATA *v = &mData->realVarsData[i];
    if (v->filterOutput) continue;
    modelica_boolean isStateDerivative = mData->nStatesArray <= i && i < 2 * mData->nStatesArray;
    size_t start = sInfo->realVarsIndex[i];
    for (size_t k = 0; k < v->dimension.scalar_length; k++) {
      realColumn[start + k] = column + k;
      d->columnTypes.push_back(OMC_RESULT_TYPE_REAL);
    }
    size_t first = d->signals.size();
    addSignals(d, v->info.name, v->info.comment, mmcString(&v->attribute.unit), mmcString(&v->attribute.displayUnit),
               OMC_RESULT_TYPE_REAL, OMC_RESULT_KIND_COLUMN, column, 0, v->time_unvarying, &v->dimension, isStateDerivative,
               v->attribute.relativeQuantity);
    if (i >= firstDiscreteReal) markDiscrete(first);
    d->reals.push_back({start, v->dimension.scalar_length});
    column += v->dimension.scalar_length;
  }
  if (omc_flag[FLAG_IDAS]) {
    for (int i = mData->nSensitivityParamVars; i < mData->nSensitivityVars; i++) {
      addSignals(d, mData->realSensitivityData[i].info.name, mData->realSensitivityData[i].info.comment, "", "",
                 OMC_RESULT_TYPE_REAL, OMC_RESULT_KIND_COLUMN, column++, 0, 0, NULL, FALSE);
      d->columnTypes.push_back(OMC_RESULT_TYPE_REAL);
      d->nSensitivities++;
    }
  }
  for (int i = 0; i < mData->nVariablesIntegerArray; i++) {
    const STATIC_INTEGER_DATA *v = &mData->integerVarsData[i];
    if (v->filterOutput) continue;
    size_t start = sInfo->integerVarsIndex[i];
    for (size_t k = 0; k < v->dimension.scalar_length; k++) {
      intColumn[start + k] = column + k;
      d->columnTypes.push_back(OMC_RESULT_TYPE_INTEGER);
    }
    addSignals(d, v->info.name, v->info.comment, "", "", OMC_RESULT_TYPE_INTEGER, OMC_RESULT_KIND_COLUMN, column, 0, v->time_unvarying, &v->dimension, FALSE);
    d->ints.push_back({start, v->dimension.scalar_length});
    column += v->dimension.scalar_length;
  }
  for (int i = 0; i < mData->nVariablesBooleanArray; i++) {
    const STATIC_BOOLEAN_DATA *v = &mData->booleanVarsData[i];
    if (v->filterOutput) continue;
    size_t start = sInfo->booleanVarsIndex[i];
    for (size_t k = 0; k < v->dimension.scalar_length; k++) {
      boolColumn[start + k] = column + k;
      d->columnTypes.push_back(OMC_RESULT_TYPE_BOOLEAN);
    }
    addSignals(d, v->info.name, v->info.comment, "", "", OMC_RESULT_TYPE_BOOLEAN, OMC_RESULT_KIND_COLUMN, column, 0, v->time_unvarying, &v->dimension, FALSE);
    d->bools.push_back({start, v->dimension.scalar_length});
    column += v->dimension.scalar_length;
  }
  std::vector<long> stringColumn(mData->nVariablesString, -1);
  for (int i = 0; i < mData->nVariablesStringArray; i++) {
    const STATIC_STRING_DATA *v = &mData->stringVarsData[i];
    if (v->filterOutput) continue;
    size_t start = sInfo->stringVarsIndex[i];
    for (size_t k = 0; k < v->dimension.scalar_length; k++) {
      stringColumn[start + k] = column + k;
      d->columnTypes.push_back(OMC_RESULT_TYPE_STRING);
    }
    addSignals(d, v->info.name, v->info.comment, "", "", OMC_RESULT_TYPE_STRING, OMC_RESULT_KIND_COLUMN, column, 0, v->time_unvarying, &v->dimension, FALSE);
    d->strs.push_back({start, v->dimension.scalar_length});
    column += v->dimension.scalar_length;
  }
  d->row.assign(column, 0.0);

  /* Parameter values are read when the file is opened, after initialization. */
  for (int i = 0; i < mData->nParametersRealArray; i++) {
    const STATIC_REAL_DATA *v = &mData->realParameterData[i];
    if (v->filterOutput) continue;
    addSignals(d, v->info.name, v->info.comment, mmcString(&v->attribute.unit), mmcString(&v->attribute.displayUnit),
               OMC_RESULT_TYPE_REAL, OMC_RESULT_KIND_PARAMETER, -1, 0, 0, &v->dimension, FALSE,
               v->attribute.relativeQuantity);
  }
  for (int i = 0; i < mData->nParametersIntegerArray; i++) {
    const STATIC_INTEGER_DATA *v = &mData->integerParameterData[i];
    if (v->filterOutput) continue;
    addSignals(d, v->info.name, v->info.comment, "", "", OMC_RESULT_TYPE_INTEGER, OMC_RESULT_KIND_PARAMETER, -1, 0, 0, &v->dimension, FALSE);
  }
  for (int i = 0; i < mData->nParametersBooleanArray; i++) {
    const STATIC_BOOLEAN_DATA *v = &mData->booleanParameterData[i];
    if (v->filterOutput) continue;
    addSignals(d, v->info.name, v->info.comment, "", "", OMC_RESULT_TYPE_BOOLEAN, OMC_RESULT_KIND_PARAMETER, -1, 0, 0, &v->dimension, FALSE);
  }
  for (int i = 0; i < mData->nParametersStringArray; i++) {
    const STATIC_STRING_DATA *v = &mData->stringParameterData[i];
    if (v->filterOutput) continue;
    addSignals(d, v->info.name, v->info.comment, "", "", OMC_RESULT_TYPE_STRING, OMC_RESULT_KIND_PARAMETER, -1, 0, 0, &v->dimension, FALSE);
  }

  /* Aliases share their target's column (or repeat its parameter value). */
  for (int i = 0; i < mData->nAliasRealArray; i++) {
    const DATA_REAL_ALIAS *a = &mData->realAlias[i];
    if (a->filterOutput) continue;
    int negate = a->negate ? OMC_RESULT_NEGATE_ARITHMETIC : OMC_RESULT_NEGATE_NONE;
    switch (a->aliasType) {
    case ALIAS_TYPE_VARIABLE: {
      const STATIC_REAL_DATA *v = &mData->realVarsData[a->nameID];
      modelica_boolean isStateDerivative = mData->nStatesArray <= a->nameID && a->nameID < 2 * mData->nStatesArray;
      size_t first = d->signals.size();
      addSignals(d, a->info.name, a->info.comment, mmcString(&a->unit), mmcString(&a->displayUnit),
                 OMC_RESULT_TYPE_REAL, OMC_RESULT_KIND_COLUMN, realColumn[sInfo->realVarsIndex[a->nameID]], negate, v->time_unvarying, &v->dimension, isStateDerivative,
                 a->relativeQuantity);
      if (a->nameID >= firstDiscreteReal) markDiscrete(first);
      break;
    }
    case ALIAS_TYPE_PARAMETER: {
      const STATIC_REAL_DATA *v = &mData->realParameterData[a->nameID];
      addSignals(d, a->info.name, a->info.comment, mmcString(&a->unit), mmcString(&a->displayUnit),
                 OMC_RESULT_TYPE_REAL, OMC_RESULT_KIND_PARAMETER, -1, negate, 0, &v->dimension, FALSE,
                 a->relativeQuantity);
      break;
    }
    case ALIAS_TYPE_TIME: {
      const char *unit = mmcString(&a->unit);
      addSignals(d, a->info.name, a->info.comment, unit[0] ? unit : "s", mmcString(&a->displayUnit),
                 OMC_RESULT_TYPE_REAL, OMC_RESULT_KIND_TIME, 0, negate, 0, NULL, FALSE,
                 a->relativeQuantity);
      break;
    }
    default:
      throwStreamPrint(threadData, "rust_result_init: Unknown alias type for real alias.");
    }
  }
  for (int i = 0; i < mData->nAliasIntegerArray; i++) {
    const DATA_INTEGER_ALIAS *a = &mData->integerAlias[i];
    if (a->filterOutput) continue;
    int negate = a->negate ? OMC_RESULT_NEGATE_ARITHMETIC : OMC_RESULT_NEGATE_NONE;
    switch (a->aliasType) {
    case ALIAS_TYPE_VARIABLE: {
      const STATIC_INTEGER_DATA *v = &mData->integerVarsData[a->nameID];
      addSignals(d, a->info.name, a->info.comment, "", "", OMC_RESULT_TYPE_INTEGER, OMC_RESULT_KIND_COLUMN,
                 intColumn[sInfo->integerVarsIndex[a->nameID]], negate, v->time_unvarying, &v->dimension, FALSE);
      break;
    }
    case ALIAS_TYPE_PARAMETER:
      addSignals(d, a->info.name, a->info.comment, "", "", OMC_RESULT_TYPE_INTEGER, OMC_RESULT_KIND_PARAMETER, -1, negate, 0,
                 &mData->integerParameterData[a->nameID].dimension, FALSE);
      break;
    default:
      throwStreamPrint(threadData, "rust_result_init: Unknown alias type for integer alias.");
    }
  }
  for (int i = 0; i < mData->nAliasBooleanArray; i++) {
    const DATA_BOOLEAN_ALIAS *a = &mData->booleanAlias[i];
    if (a->filterOutput) continue;
    int negate = a->negate ? OMC_RESULT_NEGATE_LOGICAL : OMC_RESULT_NEGATE_NONE;
    switch (a->aliasType) {
    case ALIAS_TYPE_VARIABLE: {
      const STATIC_BOOLEAN_DATA *v = &mData->booleanVarsData[a->nameID];
      addSignals(d, a->info.name, a->info.comment, "", "", OMC_RESULT_TYPE_BOOLEAN, OMC_RESULT_KIND_COLUMN,
                 boolColumn[sInfo->booleanVarsIndex[a->nameID]], negate, v->time_unvarying, &v->dimension, FALSE);
      break;
    }
    case ALIAS_TYPE_PARAMETER:
      addSignals(d, a->info.name, a->info.comment, "", "", OMC_RESULT_TYPE_BOOLEAN, OMC_RESULT_KIND_PARAMETER, -1, negate, 0,
                 &mData->booleanParameterData[a->nameID].dimension, FALSE);
      break;
    default:
      throwStreamPrint(threadData, "rust_result_init: Unknown alias type for boolean alias.");
    }
  }
  for (int i = 0; i < mData->nAliasStringArray; i++) {
    const DATA_STRING_ALIAS *a = &mData->stringAlias[i];
    if (a->filterOutput) continue;
    switch (a->aliasType) {
    case ALIAS_TYPE_VARIABLE: {
      const STATIC_STRING_DATA *v = &mData->stringVarsData[a->nameID];
      addSignals(d, a->info.name, a->info.comment, "", "", OMC_RESULT_TYPE_STRING, OMC_RESULT_KIND_COLUMN,
                 stringColumn[sInfo->stringVarsIndex[a->nameID]], 0, v->time_unvarying, &v->dimension, FALSE);
      break;
    }
    case ALIAS_TYPE_PARAMETER:
      addSignals(d, a->info.name, a->info.comment, "", "", OMC_RESULT_TYPE_STRING, OMC_RESULT_KIND_PARAMETER, -1, 0, 0,
                 &mData->stringParameterData[a->nameID].dimension, FALSE);
      break;
    default:
      throwStreamPrint(threadData, "rust_result_init: Unknown alias type for string alias.");
    }
  }
  for (size_t i = 0; i < d->signals.size(); i++) {
    d->signals[i].name = d->strings[4 * i].c_str();
    d->signals[i].description = d->strings[4 * i + 1].c_str();
    d->signals[i].unit = d->strings[4 * i + 2].c_str();
    d->signals[i].display_unit = d->strings[4 * i + 3].c_str();
  }
}

static void fillRow(rust_result_data *d, simulation_result *self, DATA *data)
{
  const SIMULATION_INFO *sInfo = data->simulationInfo;
  const SIMULATION_DATA *local = data->localData[0];
  size_t cur = 0;
  d->row[cur++] = local->timeValue;
  if (self->cpuTime) {
    rt_accumulate(SIM_TIMER_TOTAL);
    d->row[cur++] = rt_accumulated(SIM_TIMER_TOTAL);
    rt_tick(SIM_TIMER_TOTAL);
  }
  if (omc_flag[FLAG_SOLVER_STEPS]) {
    d->row[cur++] = sInfo->solverSteps;
  }
  for (const block &b : d->reals) {
    for (size_t k = 0; k < b.len; k++) d->row[cur++] = local->realVars[b.start + k];
  }
  for (size_t i = 0; i < d->nSensitivities; i++) {
    d->row[cur++] = sInfo->sensitivityMatrix[i];
  }
  for (const block &b : d->ints) {
    for (size_t k = 0; k < b.len; k++) d->row[cur++] = local->integerVars[b.start + k];
  }
  for (const block &b : d->bools) {
    for (size_t k = 0; k < b.len; k++) d->row[cur++] = local->booleanVars[b.start + k];
  }
  for (const block &b : d->strs) {
    for (size_t k = 0; k < b.len; k++) d->row[cur++] = internString(local->stringVars[b.start + k]);
  }
}

/* The parameter values in signal order (an alias of a parameter repeats it). */
static void fillParams(rust_result_data *d, DATA *data)
{
  const MODEL_DATA *mData = data->modelData;
  const SIMULATION_INFO *sInfo = data->simulationInfo;
  d->params.clear();
  for (int i = 0; i < mData->nParametersRealArray; i++) {
    if (mData->realParameterData[i].filterOutput) continue;
    for (size_t k = 0; k < mData->realParameterData[i].dimension.scalar_length; k++)
      d->params.push_back(sInfo->realParameter[sInfo->realParamsIndex[i] + k]);
  }
  for (int i = 0; i < mData->nParametersIntegerArray; i++) {
    if (mData->integerParameterData[i].filterOutput) continue;
    for (size_t k = 0; k < mData->integerParameterData[i].dimension.scalar_length; k++)
      d->params.push_back(sInfo->integerParameter[sInfo->integerParamsIndex[i] + k]);
  }
  for (int i = 0; i < mData->nParametersBooleanArray; i++) {
    if (mData->booleanParameterData[i].filterOutput) continue;
    for (size_t k = 0; k < mData->booleanParameterData[i].dimension.scalar_length; k++)
      d->params.push_back(sInfo->booleanParameter[sInfo->booleanParamsIndex[i] + k]);
  }
  for (int i = 0; i < mData->nParametersStringArray; i++) {
    if (mData->stringParameterData[i].filterOutput) continue;
    for (size_t k = 0; k < mData->stringParameterData[i].dimension.scalar_length; k++)
      d->params.push_back(internString(sInfo->stringParameter[sInfo->stringParamsIndex[i] + k]));
  }
  for (int i = 0; i < mData->nAliasRealArray; i++) {
    const DATA_REAL_ALIAS *a = &mData->realAlias[i];
    if (a->filterOutput || a->aliasType != ALIAS_TYPE_PARAMETER) continue;
    for (size_t k = 0; k < mData->realParameterData[a->nameID].dimension.scalar_length; k++)
      d->params.push_back(sInfo->realParameter[sInfo->realParamsIndex[a->nameID] + k]);
  }
  for (int i = 0; i < mData->nAliasIntegerArray; i++) {
    const DATA_INTEGER_ALIAS *a = &mData->integerAlias[i];
    if (a->filterOutput || a->aliasType != ALIAS_TYPE_PARAMETER) continue;
    for (size_t k = 0; k < mData->integerParameterData[a->nameID].dimension.scalar_length; k++)
      d->params.push_back(sInfo->integerParameter[sInfo->integerParamsIndex[a->nameID] + k]);
  }
  for (int i = 0; i < mData->nAliasBooleanArray; i++) {
    const DATA_BOOLEAN_ALIAS *a = &mData->booleanAlias[i];
    if (a->filterOutput || a->aliasType != ALIAS_TYPE_PARAMETER) continue;
    for (size_t k = 0; k < mData->booleanParameterData[a->nameID].dimension.scalar_length; k++)
      d->params.push_back(sInfo->booleanParameter[sInfo->booleanParamsIndex[a->nameID] + k]);
  }
  for (int i = 0; i < mData->nAliasStringArray; i++) {
    const DATA_STRING_ALIAS *a = &mData->stringAlias[i];
    if (a->filterOutput || a->aliasType != ALIAS_TYPE_PARAMETER) continue;
    for (size_t k = 0; k < mData->stringParameterData[a->nameID].dimension.scalar_length; k++)
      d->params.push_back(internString(sInfo->stringParameter[sInfo->stringParamsIndex[a->nameID] + k]));
  }
}

static void openWriter(rust_result_data *d, simulation_result *self, DATA *data, threadData_t *threadData)
{
  fillParams(d, data);
  fillRow(d, self, data);
  char *error = NULL;
  d->writer = omc_result_writer_open(self->filename, data->simulationInfo->outputFormat,
                                     d->signals.data(), d->signals.size(),
                                     d->columnTypes.data(), d->columnTypes.size(),
                                     d->params.data(), d->params.size(),
                                     d->row.data(), data->simulationInfo->startTime, data->simulationInfo->stopTime,
                                     omc_flag[FLAG_SINGLE_PRECISION] ? 1 : 0,
                                     omc_flag[FLAG_MAT_SYNC] ? atoi(omc_flagValue[FLAG_MAT_SYNC]) : 0, &error);
  if (!d->writer) {
    std::string msg = error ? error : "unknown error";
    omc_result_free_string(error);
    throwStreamPrint(threadData, "Error opening result file %s: %s", self->filename, msg.c_str());
  }
}

/* Called once initialization is done: parameters and the time-invariant
 * variables have their final values, so the file is opened here. */
void rust_result_writeParameterData(simulation_result *self, DATA *data, threadData_t *threadData)
{
  rust_result_data *d = (rust_result_data *)self->storage;
  rt_tick(SIM_TIMER_OUTPUT);
  if (!d->writer) {
    openWriter(d, self, data, threadData);
  }
  rt_accumulate(SIM_TIMER_OUTPUT);
}

void rust_result_emit(simulation_result *self, DATA *data, threadData_t *threadData)
{
  rust_result_data *d = (rust_result_data *)self->storage;
  rt_tick(SIM_TIMER_OUTPUT);
  if (!d->writer) {
    openWriter(d, self, data, threadData);
  }
  fillRow(d, self, data);
  omc_result_writer_emit(d->writer, d->row.data());
  rt_accumulate(SIM_TIMER_OUTPUT);
}

void rust_result_free(simulation_result *self, DATA *data, threadData_t *threadData)
{
  rust_result_data *d = (rust_result_data *)self->storage;
  if (!d) {
    return;
  }
  rt_tick(SIM_TIMER_OUTPUT);
  if (d->writer && !omc_result_writer_close(d->writer)) {
    warningStreamPrint(OMC_LOG_STDOUT, 0, "Writing the result file %s failed.", self->filename);
  }
  delete d;
  self->storage = NULL;
  rt_accumulate(SIM_TIMER_OUTPUT);
}

} /* extern "C" */

#endif /* OM_RUST_RESULT_WRITERS */
