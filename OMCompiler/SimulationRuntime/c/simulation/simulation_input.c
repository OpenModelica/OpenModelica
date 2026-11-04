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


/*
 * Reads the model input from <prefix>_init.bin, see util/omc_init_bin.h.
 */

#include "simulation_input.h"
#include "arrayIndex.h"
#include <errno.h>
#include <ctype.h>
#include <limits.h>
#include <string.h>
#include <inttypes.h>
#include <math.h>
#include "simulation_runtime.h"
#include "options.h"
#include "../util/omc_error.h"
#include "../util/omc_file.h"
#include "../util/omc_init_bin.h"
#include "../util/omc_strdup.h"
#include "../util/modelica_string.h"
#include "../util/uthash.h"
#include "solver/model_help.h"

typedef struct hash_string_string
{
  const char *id;
  const char *val;
  UT_hash_handle hh;
} hash_string_string;

typedef struct hash_string_long
{
  const char *id;
  long val;
  UT_hash_handle hh;
} hash_string_long;

static const double REAL_MIN = -DBL_MAX;
static const double REAL_MAX = DBL_MAX;
static const modelica_integer INTEGER_MIN = MODELICA_INT_MIN;
static const modelica_integer INTEGER_MAX = MODELICA_INT_MAX;

/* All quantities given with -override/-overrideFile, see isQuantityOverridden. */
static hash_string_string *gCommandLineOverrides = NULL;

static inline modelica_real read_value_real(const char *s);
static modelica_integer read_value_long(const char *s, modelica_integer default_value);
static modelica_boolean read_value_bool(const char *s);

static const char* findHashStringStringNull(hash_string_string *ht, const char *key)
{
  hash_string_string *res;
  HASH_FIND_STR(ht, key, res);
  return res ? res->val : NULL;
}

static void addHashStringString(hash_string_string **ht, const char *key, const char *val)
{
  hash_string_string *v = (hash_string_string*) calloc(1, sizeof(hash_string_string));
  v->id = omc_strdup(key);
  v->val = omc_strdup(val);
  HASH_ADD_KEYPTR(hh, *ht, v->id, strlen(v->id), v);
}

static long* findHashStringLongPtr(hash_string_long *ht, const char *key)
{
  hash_string_long *res;
  HASH_FIND_STR(ht, key, res);
  return res ? &res->val : NULL;
}

static void addHashStringLong(hash_string_long **ht, const char *key, long val)
{
  hash_string_long *v;
  HASH_FIND_STR(*ht, key, v);
  if (v) {
    v->val = val;
    return;
  }
  v = (hash_string_long*) calloc(1, sizeof(hash_string_long));
  v->id = omc_strdup(key);
  v->val = val;
  HASH_ADD_KEYPTR(hh, *ht, v->id, strlen(v->id), v);
}

static void freeHashStringLong(hash_string_long *ht)
{
  hash_string_long *c, *tmp;
  HASH_ITER(hh, ht, c, tmp) {
    HASH_DEL(ht, c);
    free((void*)c->id);
    free(c);
  }
}

typedef void (*put_token_t)(const char *token, size_t i, base_array_t *array);

static void put_real_token(const char *token, size_t i, base_array_t *array)
{
  put_real_element(read_value_real(token), i, array);
}

static void put_integer_token(const char *token, size_t i, base_array_t *array)
{
  put_integer_element(read_value_long(token, 0), i, array);
}

static void put_boolean_token(const char *token, size_t i, base_array_t *array)
{
  put_boolean_element(read_value_bool(token), i, array);
}

/**
 * @brief Read string with multiple space separated values into `array`.
 *
 * @param str           String to read values from.
 * @param put           Converts a single token and stores it in `array`.
 * @param array         Array to fill. Needs enough memory to store
 *                      `num_elements` elements.
 *                      If `NULL` only counts number of elements, but doesn't
 *                      write into `array`.
 * @param num_elements  Number of elements to read from `str`.
 * @return size_t       Returns number of elements read.
 */
static size_t read_tokens(const char* str, put_token_t put, base_array_t* array, size_t num_elements) {
  const char* delimeter = " ";
  size_t count = 0;

  char* copy = omc_strdup(str);
  assertStreamPrint(NULL, copy != NULL, "Out of memory!");
  char* rest = copy;

  char *token = strtok_r(rest, delimeter, &rest);
  while (token != NULL) {
      count++;
      if (count <= num_elements && array != NULL) {
        put(token, count-1, array);
      }
      token = strtok_r(rest, delimeter, &rest);
  }

  free(copy);

  return count;
}

/**
 * @brief Read string with multiple real values into `array`.
 *
 * @param str           String to read values from.
 * @param array         Array to fill. Needs enough memory to store
 *                      `num_elements` elements.
 *                      If `NULL` only counts number of elements, but doesn't
 *                      write into `array`.
 * @param num_elements  Number of elements to read from `str`.
 * @return size_t       Returns number of elements read.
 */
size_t read_str(const char* str,  real_array* array, size_t num_elements) {
  return read_tokens(str, put_real_token, array, num_elements);
}

/**
 * @brief Read string into array variable.
 *
 * @param array           Array variable to populate.
 * @param str             String with numbers to be read into real array.
 *                        Values delimited by space `" "`.
 * @param default_value
 */
void read_array_var_real(real_array* array, const char* str, modelica_real default_value) {
  size_t length;

  length = read_str(str, NULL, 0);
  if (length == 0) {
    length = 1;
    simple_alloc_1d_real_array(array, length);
    put_real_element(default_value, 0, array);
  } else {
    simple_alloc_1d_real_array(array, length);
    read_str(str, array, length);
  }
}

/**
 * @brief Read string into integer array variable.
 *
 * @param array           Array variable to populate.
 * @param str             String with integers to be read into integer array.
 *                        Values delimited by space `" "`.
 * @param default_value   Value to use if `str` is empty.
 */
void read_array_var_integer(integer_array* array, const char* str, modelica_integer default_value) {
  size_t length;

  length = read_tokens(str, put_integer_token, NULL, 0);
  if (length == 0) {
    simple_alloc_1d_integer_array(array, 1);
    put_integer_element(default_value, 0, array);
  } else {
    simple_alloc_1d_integer_array(array, length);
    read_tokens(str, put_integer_token, array, length);
  }
}

/**
 * @brief Read string into boolean array variable.
 *
 * @param array           Array variable to populate.
 * @param str             String with `true`/`false` values to be read into
 *                        boolean array. Values delimited by space `" "`.
 * @param default_value   Value to use if `str` is empty.
 */
void read_array_var_boolean(boolean_array* array, const char* str, modelica_boolean default_value) {
  size_t length;

  length = read_tokens(str, put_boolean_token, NULL, 0);
  if (length == 0) {
    simple_alloc_1d_boolean_array(array, 1);
    put_boolean_element(default_value, 0, array);
  } else {
    simple_alloc_1d_boolean_array(array, length);
    read_tokens(str, put_boolean_token, array, length);
  }
}

/**
 * @brief Read string with multiple quoted string values into `array`.
 *
 * Values are enclosed in double quotes and delimited by space, e.g.
 * `"a" "b c" ""`. Inside a value `"` is not escaped, so a quote only closes
 * the value if it is followed by the end of `str` or by spaces and the next
 * opening quote.
 *
 * @param str           String to read values from.
 * @param array         Array to fill. Needs enough memory to store
 *                      `num_elements` elements.
 *                      If `NULL` only counts number of elements, but doesn't
 *                      write into `array`.
 * @param num_elements  Number of elements to read from `str`.
 * @return size_t       Returns number of elements read or 0 if `str` isn't a
 *                      list of quoted values.
 */
size_t read_quoted_str(const char* str, string_array* array, size_t num_elements) {
  const char *pos = str;
  const char *begin;
  const char *end;
  const char *next;
  size_t count = 0;

  while (*pos == ' ') pos++;
  while (*pos != '\0') {
    if (*pos != '"') {
      return 0;
    }
    begin = pos + 1;

    /* find closing quote */
    end = NULL;
    for (next = begin; *next != '\0'; next++) {
      if (*next == '"') {
        const char *after = next + 1;
        while (*after == ' ') after++;
        if (*after == '\0' || (*after == '"' && after > next + 1)) {
          end = next;
          break;
        }
      }
    }
    if (end == NULL) {
      return 0;
    }

    count++;
    if (count <= num_elements && array != NULL) {
      modelica_string value = omc_string_new_len(begin, (mmc_uint_t)(end - begin));
      put_string_element(value, count-1, array);
      omc_string_release(value);
    }

    pos = end + 1;
    while (*pos == ' ') pos++;
  }

  return count;
}

/**
 * @brief Read string into string array variable.
 *
 * For scalar variables `str` is the value itself. For array variables `str`
 * is a list of quoted values, see `read_quoted_str`. If it doesn't start with a
 * quote it is a single value that is used for all array elements.
 *
 * @param array     Array variable to populate.
 * @param str       String to read.
 * @param isScalar  If true `str` belongs to a scalar variable.
 */
void read_array_var_string(string_array* array, const char* str, modelica_boolean isScalar) {  size_t length = 0;
  modelica_string value;

  if (!isScalar) {
    length = read_quoted_str(str, NULL, 0);
  }

  if (length == 0) {
    simple_alloc_1d_string_array(array, 1);
    value = omc_string_new(str);
    put_string_element(value, 0, array);
    omc_string_release(value);
  } else {
    simple_alloc_1d_string_array(array, length);
    read_quoted_str(str, array, length);
  }
}


static void set_real_values(real_array *array, const omc_init_bin *bin, omc_init_bin_values v, modelica_real default_value)
{
  uint32_t i;
  simple_alloc_1d_real_array(array, v.count ? v.count : 1);
  if (!v.count) {
    put_real_element(default_value, 0, array);
  }
  for (i = 0; i < v.count; i++) {
    put_real_element(omc_init_bin_real(bin, v.index + i), i, array);
  }
}

static void set_integer_values(integer_array *array, const omc_init_bin *bin, omc_init_bin_values v, modelica_integer default_value)
{
  uint32_t i;
  simple_alloc_1d_integer_array(array, v.count ? v.count : 1);
  if (!v.count) {
    put_integer_element(default_value, 0, array);
  }
  for (i = 0; i < v.count; i++) {
    put_integer_element((modelica_integer) omc_init_bin_integer(bin, v.index + i), i, array);
  }
}

static void set_boolean_values(boolean_array *array, const omc_init_bin *bin, omc_init_bin_values v)
{
  uint32_t i;
  simple_alloc_1d_boolean_array(array, v.count ? v.count : 1);
  if (!v.count) {
    put_boolean_element(0, 0, array);
  }
  for (i = 0; i < v.count; i++) {
    put_boolean_element(omc_init_bin_integer(bin, v.index + i) != 0, i, array);
  }
}

static void set_string_values(string_array *array, const omc_init_bin *bin, omc_init_bin_values v)
{
  uint32_t i;
  modelica_string value;
  simple_alloc_1d_string_array(array, v.count ? v.count : 1);
  for (i = 0; i < (v.count ? v.count : 1); i++) {
    value = omc_string_new(v.count ? omc_init_bin_string(bin, v.index + i) : "");
    put_string_element(value, i, array);
    omc_string_release(value);
  }
}

static void read_var_info(const omc_init_bin_variable *v, VAR_INFO *info)
{
  info->name = omc_strdup(v->name);
  info->inputIndex = v->inputIndex;
  info->id = v->valueReference;
  info->comment = omc_strdup(v->description);
  info->info.filename = omc_strdup(v->fileName);
  info->info.lineStart = v->startLine;
  info->info.colStart = v->startColumn;
  info->info.lineEnd = v->endLine;
  info->info.colEnd = v->endColumn;
  info->info.readonly = !(v->flags & OMC_INIT_BIN_FILE_WRITABLE);
}

static void read_var_dimension(const omc_init_bin *bin, const omc_init_bin_variable *v, DIMENSION_INFO *dimension_info)
{
  size_t i;
  DIMENSION_ATTRIBUTE *dim;

  dimension_info->numberOfDimensions = v->numDimensions;
  if (v->numDimensions == 0) {
    dimension_info->dimensions = NULL;
    dimension_info->scalar_length = 1;
    return;
  }
  dimension_info->dimensions = (DIMENSION_ATTRIBUTE*) calloc(v->numDimensions, sizeof(DIMENSION_ATTRIBUTE));
  for (i = 0; i < v->numDimensions; i++) {
    dim = &dimension_info->dimensions[i];
    dim->start = (modelica_integer) omc_init_bin_integer(bin, v->firstDimension + 2*i);
    dim->valueReference = (modelica_integer) omc_init_bin_integer(bin, v->firstDimension + 2*i + 1);
    dim->type = dim->valueReference >= 0 ? DIMENSION_BY_VALUE_REFERENCE : DIMENSION_BY_START;
  }
  /* The values of structural parameters may not be known yet. */
  dimension_info->scalar_length = -1;
}

/**
 * @brief Check if a variable should be filtered from the output.
 *
 * Protected variables and variables with HideResult=true are filtered, unless
 * -emit_protected (not for encrypted variables) or -ignoreHideResult says
 * otherwise.
 */
static modelica_boolean shouldFilterOutput(const omc_init_bin_variable *v)
{
  int isProtected = (v->flags & OMC_INIT_BIN_PROTECTED) != 0;
  int hideResult = v->hideResult == OMC_INIT_BIN_HIDE_RESULT_TRUE;
  int shouldFilter = isProtected || hideResult;

  if (!(v->flags & OMC_INIT_BIN_ENCRYPTED) && omc_flag[FLAG_EMIT_PROTECTED] && isProtected) {
    shouldFilter = FALSE;
  }
  if (omc_flag[FLAG_IGNORE_HIDERESULT] && hideResult) {
    shouldFilter = FALSE;
  }
  return shouldFilter;
}

static void read_variable(const omc_init_bin *bin, const omc_init_bin_variable *v, const char *start,
                          VAR_INFO *info, DIMENSION_INFO *dimension, modelica_boolean *filterOutput, void *attribute)
{
  modelica_boolean isScalar;
  read_var_dimension(bin, v, dimension);
  isScalar = dimension->numberOfDimensions == 0;
  read_var_info(v, info);
  *filterOutput = shouldFilterOutput(v);

  switch (v->baseType) {
    case OMC_INIT_BIN_REAL:
    {
      REAL_ATTRIBUTE *a = (REAL_ATTRIBUTE*) attribute;
      if (start) {
        read_array_var_real(&a->start, start, 0.0);
      } else {
        set_real_values(&a->start, bin, v->start, 0.0);
      }
      a->fixed = (v->flags & OMC_INIT_BIN_FIXED) != 0;
      a->useNominal = (v->flags & OMC_INIT_BIN_USE_NOMINAL) != 0;
      set_real_values(&a->nominal, bin, v->nominal, 1.0);
      set_real_values(&a->min, bin, v->min, REAL_MIN);
      set_real_values(&a->max, bin, v->max, REAL_MAX);
      a->unit = omc_string_new(v->unit);
      a->displayUnit = omc_string_new(v->displayUnit);
      a->relativeQuantity = (v->flags & OMC_INIT_BIN_RELATIVE_QUANTITY) != 0;
      break;
    }
    case OMC_INIT_BIN_INTEGER:
    case OMC_INIT_BIN_ENUMERATION:
    {
      INTEGER_ATTRIBUTE *a = (INTEGER_ATTRIBUTE*) attribute;
      if (start) {
        read_array_var_integer(&a->start, start, 0);
      } else {
        set_integer_values(&a->start, bin, v->start, 0);
      }
      a->fixed = (v->flags & OMC_INIT_BIN_FIXED) != 0;
      set_integer_values(&a->min, bin, v->min, INTEGER_MIN);
      set_integer_values(&a->max, bin, v->max, INTEGER_MAX);
      break;
    }
    case OMC_INIT_BIN_BOOLEAN:
    {
      BOOLEAN_ATTRIBUTE *a = (BOOLEAN_ATTRIBUTE*) attribute;
      if (start) {
        read_array_var_boolean(&a->start, start, 0);
      } else {
        set_boolean_values(&a->start, bin, v->start);
      }
      a->fixed = (v->flags & OMC_INIT_BIN_FIXED) != 0;
      break;
    }
    case OMC_INIT_BIN_STRING:
    {
      STRING_ATTRIBUTE *a = (STRING_ATTRIBUTE*) attribute;
      if (start) {
        read_array_var_string(&a->start, start, isScalar);
      } else {
        set_string_values(&a->start, bin, v->start);
      }
      break;
    }
    default:
      throwStreamPrint(NULL, "simulation_input.c: variable %s has an unsupported type.", v->name);
  }
  infoStreamPrint(OMC_LOG_DEBUG, 0, "read variable %s from the init file", info->name);
}


/**
 * @brief Read double value from a string.
 *
 * @param s               Null terminated string.
 *                        Treat string value `"true"` as `1.0` and `"false"`
 *                        as `0.0`.
 * @return modelica_real  Real value.
 */
static inline modelica_real read_value_real(const char *s)
{
  if (*s == '\0') {
    throwStreamPrint(NULL, "read_value_real: Nothing to read!");
  }

  if (0 == strcmp(s, "true")) {
    return 1.0;
  } else if (0 == strcmp(s, "false")) {
    return 0.0;
  } else {
    return atof(s);
  }
}

/**
 * @brief Read long value from string.
 *
 * @param s                   Null terminated string to read.
 *                            Treat string value `"true"` as `1` and `"false"`
 *                            as `0`.
 * @param default_value       Default value if string is empty.
 * @return modelica_integer   Long integer.
 */
static inline modelica_integer read_value_long(const char *s, modelica_integer default_value)
{
  if (s == NULL || *s == '\0') {
    return default_value;
  } else if (0 == strcmp(s, "true")) {
    return 1;
  } else if (0 == strcmp(s, "false")) {
    return 0;
  } else {
    return atol(s);
  }
}


/**
 * @brief Read boolean value from string.
 *
 * @param s                   Null terminated string to read.
 * @return modelica_boolean   Return TRUE if string equals "true", FALSE otherwise.
 */
static inline modelica_boolean read_value_bool(const char *s)
{
  return 0 == strcmp(s, "true");
}


static char* trim(char *str) {
  char *res=str,*end=str+strlen(str)-1;
  while (isspace(*res)) {
    res++;
  }
  while (isspace(*end)) {
    *end='\0';
    end--;
  }
  return res;
}

/**
 * @brief Parse -override and -overrideFile into name=value pairs.
 */
static hash_string_string* parseOverrides(const char *override, const char *overrideFile)
{
  hash_string_string *overrides = NULL;
  char *strs[2] = {NULL, NULL};
  int k;

  if (override && overrideFile) {
    infoStreamPrint(OMC_LOG_SOLVER, 0, "using -override=%s and -overrideFile=%s", override, overrideFile);
  }
  if (override) {
    strs[0] = omc_strdup(override);
  }
  if (overrideFile) {
    FILE *infile;
    char *line, *tline, *tline2, *overrideLine;
    size_t n;

    infoStreamPrint(OMC_LOG_SOLVER, 0, "read override values from file: %s", overrideFile);
    infile = omc_fopen(overrideFile, "rb");
    if (!infile) {
      throwStreamPrint(NULL, "simulation_input.c: could not open the file given to -overrideFile=%s", overrideFile);
    }
    fseek(infile, 0L, SEEK_END);
    n = ftell(infile);
    line = (char*) malloc(n+1);
    fseek(infile, 0L, SEEK_SET);
    errno = 0;
    if (n > 0 && 1 != omc_fread(line, n, 1, infile, 0)) {
      free(line);
      throwStreamPrint(NULL, "simulation_input.c: could not read overrideFile %s: %s", overrideFile, strerror(errno));
    }
    line[n] = '\0';
    fclose(infile);
    overrideLine = (char*) malloc(n+1);
    overrideLine[0] = '\0';
    strs[1] = overrideLine;
    tline = line;
    while (0 != (tline2 = strchr(tline, '\n'))) {
      *tline2 = '\0';
      tline = trim(tline);
      /* skip empty lines and // comments */
      if (tline[0] && tline[0] != '/' && tline[1] != '/') {
        if (overrideLine != strs[1]) {
          overrideLine[0] = ',';
          ++overrideLine;
        }
        overrideLine = strcpy(overrideLine, tline) + strlen(tline);
      }
      tline = tline2 + 1;
    }
    free(line);
  }

  infoStreamPrint(OMC_LOG_SOLVER, 0, "-override=%s", strs[0] ? strs[0] : "[not given]");
  infoStreamPrint(OMC_LOG_SOLVER, 0, "-overrideFile=%s", strs[1] ? strs[1] : "[not given]");
  for (k = 0; k < 2; k++) {
    char *p, *value, *saveptr = NULL;
    const char *ov;
    if (!strs[k]) {
      continue;
    }
    parseVariableStr(strs[k]);
    for (p = strtok_r(strs[k], "!", &saveptr); p; p = strtok_r(NULL, "!", &saveptr)) {
      value = strchr(p, '=');
      if (!value) {
        throwStreamPrint(NULL, "Invalid format for value of override flag: %s", p);
      }
      *value = '\0';
      value++;
      ov = findHashStringStringNull(overrides, p);
      if (ov) {
        warningStreamPrint(OMC_LOG_STDOUT, 0, "You are overriding variable: %s=%s again with %s=%s.", p, ov, p, value);
        hash_string_string *res;
        HASH_FIND_STR(overrides, p, res);
        free((void*) res->val);
        res->val = omc_strdup(value);
      } else {
        addHashStringString(&overrides, p, value);
      }
    }
    free(strs[k]);
  }
  return overrides;
}

/**
 * @brief The start value given with -override for `v`, or NULL.
 *
 * Marks the override as used; a variable that cannot be changed keeps its
 * start value and gets a warning.
 */
static const char* overrideValue(hash_string_string *overrides, hash_string_long **uses, const omc_init_bin_variable *v)
{
  const char *value = findHashStringStringNull(overrides, v->name);
  if (!value) {
    return NULL;
  }
  addHashStringLong(uses, v->name, 1);
  if (!(v->flags & OMC_INIT_BIN_VALUE_CHANGEABLE)) {
    warningStreamPrint(OMC_LOG_STDOUT, 0,
                       "It is not possible to override the following quantity: %s\n"
                       "It seems to be structural, final, protected or evaluated or has a non-constant binding.",
                       v->name);
    return NULL;
  }
  infoStreamPrint(OMC_LOG_SOLVER, 0, "override %s = %s", v->name, value);
  if (v->classType == OMC_INIT_BIN_REAL_PARAMETER || v->classType == OMC_INIT_BIN_INTEGER_PARAMETER) {
    if (fabs(atof(value)) < 1e-6) {
      warningStreamPrint(OMC_LOG_STDOUT, 0,
                         "You are overriding %s with a small value or zero.\n"
                         "This could lead to numerically dirty solutions or divisions by zero if not tearingStrictness=veryStrict.",
                         v->name);
    }
  }
  return value;
}

static void read_experiment(SIMULATION_INFO* simulationInfo, const omc_init_bin_experiment *de, modelica_boolean useFlags)
{
  modelica_boolean reCalcStepSize = FALSE;

  if (useFlags && omc_flag[FLAG_START_TIME]) {
    simulationInfo->startTime = atof(omc_flagValue[FLAG_START_TIME]);
    reCalcStepSize = TRUE;
  } else {
    simulationInfo->startTime = de->startTime;
  }
  if (useFlags && omc_flag[FLAG_STOP_TIME]) {
    simulationInfo->stopTime = atof(omc_flagValue[FLAG_STOP_TIME]);
    reCalcStepSize = TRUE;
  } else {
    simulationInfo->stopTime = de->stopTime;
  }
  if (useFlags && omc_flag[FLAG_STEP_SIZE]) {
    simulationInfo->stepSize = atof(omc_flagValue[FLAG_STEP_SIZE]);
  } else if (reCalcStepSize) {
    simulationInfo->stepSize = (simulationInfo->stopTime - simulationInfo->startTime) / 500;
    warningStreamPrint(OMC_LOG_STDOUT, 1, "Start or stop time was overwritten, but no new integrator step size was provided.");
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Re-calculating step size for 500 intervals.");
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Use `-stepSize=<value>` to silence this warning.");
    messageCloseWarning(OMC_LOG_STDOUT);
  } else {
    simulationInfo->stepSize = de->stepSize;
  }
  simulationInfo->tolerance = useFlags && omc_flag[FLAG_TOLERANCE] ? atof(omc_flagValue[FLAG_TOLERANCE]) : de->tolerance;
  simulationInfo->solverMethod = GC_strdup(useFlags && omc_flag[FLAG_S] ? omc_flagValue[FLAG_S] : de->solver);
  simulationInfo->outputFormat = GC_strdup(useFlags && omc_flag[FLAG_OUTPUT_FORMAT] ? omc_flagValue[FLAG_OUTPUT_FORMAT] : de->outputFormat);
  simulationInfo->variableFilter = GC_strdup(useFlags && omc_flag[FLAG_VARIABLE_FILTER] ? omc_flagValue[FLAG_VARIABLE_FILTER] : de->variableFilter);

  infoStreamPrint(OMC_LOG_SIMULATION, 1, "Read all Experiment values:");
  infoStreamPrint(OMC_LOG_SIMULATION, 0, "startTime = %g", simulationInfo->startTime);
  infoStreamPrint(OMC_LOG_SIMULATION, 0, "stopTime = %g", simulationInfo->stopTime);
  infoStreamPrint(OMC_LOG_SIMULATION, 0, "stepSize = %g", simulationInfo->stepSize);
  infoStreamPrint(OMC_LOG_SIMULATION, 0, "tolerance = %g", simulationInfo->tolerance);
  infoStreamPrint(OMC_LOG_SIMULATION, 0, "solver method: %s", simulationInfo->solverMethod);
  infoStreamPrint(OMC_LOG_SIMULATION, 0, "output format: %s", simulationInfo->outputFormat);
  infoStreamPrint(OMC_LOG_SIMULATION, 0, "variable filter: %s", simulationInfo->variableFilter);
  messageClose(OMC_LOG_SIMULATION);
}

static void read_sizes(const omc_init_bin_model *md, MODEL_DATA *modelData)
{
  modelData->nStatesArray = md->numberOfContinuousStates;
  modelData->nVariablesRealArray = 2*md->numberOfContinuousStates + md->numberOfRealAlgebraicVariables;
  modelData->nAliasRealArray = md->numberOfRealAlgebraicAliasVariables;
  modelData->nParametersRealArray = md->numberOfRealParameters;
  modelData->nParametersIntegerArray = md->numberOfIntegerParameters;
  modelData->nVariablesIntegerArray = md->numberOfIntegerAlgebraicVariables;
  modelData->nAliasIntegerArray = md->numberOfIntegerAliasVariables;
  modelData->nParametersBooleanArray = md->numberOfBooleanParameters;
  modelData->nVariablesBooleanArray = md->numberOfBooleanAlgebraicVariables;
  modelData->nAliasBooleanArray = md->numberOfBooleanAliasVariables;
  modelData->nParametersStringArray = md->numberOfStringParameters;
  modelData->nVariablesStringArray = md->numberOfStringAlgebraicVariables;
  modelData->nAliasStringArray = md->numberOfStringAliasVariables;
}

static void read_enumeration_types(const omc_init_bin *bin, MODEL_DATA *modelData)
{
  size_t i, k;
  modelData->nEnumerationTypes = bin->numEnumerations;
  modelData->enumerationTypes = bin->numEnumerations ? (ENUMERATION_TYPE*) calloc(bin->numEnumerations, sizeof(ENUMERATION_TYPE)) : NULL;
  for (i = 0; i < bin->numEnumerations; i++) {
    ENUMERATION_TYPE *t = &modelData->enumerationTypes[i];
    t->name = omc_strdup(bin->enumerations[i].name);
    t->nLiterals = bin->enumerations[i].numLiterals;
    t->literals = (char**) calloc(t->nLiterals ? t->nLiterals : 1, sizeof(char*));
    for (k = 0; k < t->nLiterals; k++) {
      t->literals[k] = omc_strdup(omc_init_bin_string(bin, bin->enumerations[i].firstLiteral + k));
    }
  }
}

static ENUMERATION_TYPE* find_enumeration(MODEL_DATA *modelData, const char *declaredType)
{
  size_t k;
  for (k = 0; *declaredType && k < modelData->nEnumerationTypes; k++) {
    if (0 == strcmp(declaredType, modelData->enumerationTypes[k].name)) {
      return &modelData->enumerationTypes[k];
    }
  }
  return NULL;
}

static void read_alias(const omc_init_bin_variable *v, DATA_ALIAS *alias, hash_string_long *mapAlias, hash_string_long *mapAliasParam)
{
  long *it, *itParam;

  read_var_info(v, &alias->info);
  alias->unit = omc_string_new(v->unit);
  alias->displayUnit = omc_string_new(v->displayUnit);
  alias->relativeQuantity = (v->flags & OMC_INIT_BIN_RELATIVE_QUANTITY) != 0;
  alias->negate = v->alias == OMC_INIT_BIN_NEGATED_ALIAS;
  alias->filterOutput = shouldFilterOutput(v);

  it = findHashStringLongPtr(mapAlias, v->aliasVariable);
  itParam = findHashStringLongPtr(mapAliasParam, v->aliasVariable);
  if (it) {
    alias->nameID = *it;
    alias->aliasType = ALIAS_TYPE_VARIABLE;
  } else if (itParam) {
    alias->nameID = *itParam;
    alias->aliasType = ALIAS_TYPE_PARAMETER;
  } else if (0 == strcmp(v->aliasVariable, "time")) {
    alias->aliasType = ALIAS_TYPE_TIME;
  } else {
    throwStreamPrint(NULL, "Alias variable %s not found.", v->aliasVariable);
  }
}

/**
 * @brief The name of the init file: -f, else -inputPath, else the resources
 * directory of an FMU, else the working directory.
 */
static const char* getInitFileName(MODEL_DATA *modelData)
{
  const char *filename;
  if (omc_flag[FLAG_F]) {
    return omc_flagValue[FLAG_F];
  }
  if (omc_flag[FLAG_INPUT_PATH]) {
    GC_asprintf(&filename, "%s/%s_init.bin", omc_flagValue[FLAG_INPUT_PATH], modelData->modelFilePrefix);
  } else if (modelData->resourcesDir) {
    GC_asprintf(&filename, "%s/%s_init.bin", modelData->resourcesDir, modelData->modelFilePrefix);
  } else {
    GC_asprintf(&filename, "%s_init.bin", modelData->modelFilePrefix);
  }
  return filename;
}

static void load_init_bin(omc_init_bin *bin, MODEL_DATA *modelData, threadData_t *threadData)
{
  const char *filename = NULL;
  int status;

  if (modelData->initBinData) {
    status = omc_init_bin_load_buffer(bin, modelData->initBinData, modelData->initBinSize);
  } else {
    filename = getInitFileName(modelData);
    status = omc_init_bin_load_file(bin, filename);
  }
  if (status) {
    char msg[sizeof(bin->error)];
    memcpy(msg, bin->error, sizeof(msg));
    omc_init_bin_free(bin);
    throwStreamPrint(threadData, "Failed to read the init file: %s", msg);
  }
  if (strcmp(modelData->modelGUID, bin->model.guid)) {
    char guid[128];
    snprintf(guid, sizeof(guid), "%s", bin->model.guid);
    omc_init_bin_free(bin);
    throwStreamPrint(threadData, "GUID: %s from input data file: %s does not match the GUID compiled in the model: %s",
        guid, filename ? filename : "(compiled into the model)", modelData->modelGUID);
  }
}

static void reset_start(const omc_init_bin *bin, const omc_init_bin_variable *v, base_array_t *start)
{
  if (v->baseType == OMC_INIT_BIN_STRING) {
    omc_string_array_release(start);
  } else {
    omc_array_release(start);
  }
  switch (v->baseType) {
    case OMC_INIT_BIN_REAL: set_real_values(start, bin, v->start, 0.0); break;
    case OMC_INIT_BIN_INTEGER:
    case OMC_INIT_BIN_ENUMERATION: set_integer_values(start, bin, v->start, 0); break;
    case OMC_INIT_BIN_BOOLEAN: set_boolean_values(start, bin, v->start); break;
    case OMC_INIT_BIN_STRING: set_string_values(start, bin, v->start); break;
    default: break;
  }
}

void read_input_defaults(MODEL_DATA* modelData, SIMULATION_INFO* simulationInfo, modelica_boolean isFMU, threadData_t* threadData)
{
  omc_init_bin bin;
  size_t i, k;
  load_init_bin(&bin, modelData, threadData);
  read_experiment(simulationInfo, &bin.experiment, !isFMU);
  simulationInfo->OPENMODELICAHOME = GC_strdup(bin.model.omhome);
  for (i = 0; i < bin.numVariables; i++) {
    const omc_init_bin_variable *v = &bin.variables[i];
    k = i - bin.classStart[v->classType];
    switch (v->classType) {
      case OMC_INIT_BIN_REAL_STATE:
      case OMC_INIT_BIN_REAL_DERIVATIVE:
      case OMC_INIT_BIN_REAL_ALGEBRAIC:
        k += (v->classType == OMC_INIT_BIN_REAL_STATE ? 0 : v->classType == OMC_INIT_BIN_REAL_DERIVATIVE ? 1 : 2) * modelData->nStatesArray;
        if (k < (size_t) modelData->nVariablesRealArray) reset_start(&bin, v, &modelData->realVarsData[k].attribute.start);
        break;
      case OMC_INIT_BIN_REAL_PARAMETER:
        if (k < (size_t) modelData->nParametersRealArray) reset_start(&bin, v, &modelData->realParameterData[k].attribute.start);
        break;
      case OMC_INIT_BIN_INTEGER_ALGEBRAIC:
        if (k < (size_t) modelData->nVariablesIntegerArray) reset_start(&bin, v, &modelData->integerVarsData[k].attribute.start);
        break;
      case OMC_INIT_BIN_INTEGER_PARAMETER:
        if (k < (size_t) modelData->nParametersIntegerArray) reset_start(&bin, v, &modelData->integerParameterData[k].attribute.start);
        break;
      case OMC_INIT_BIN_BOOLEAN_ALGEBRAIC:
        if (k < (size_t) modelData->nVariablesBooleanArray) reset_start(&bin, v, &modelData->booleanVarsData[k].attribute.start);
        break;
      case OMC_INIT_BIN_BOOLEAN_PARAMETER:
        if (k < (size_t) modelData->nParametersBooleanArray) reset_start(&bin, v, &modelData->booleanParameterData[k].attribute.start);
        break;
#if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
      case OMC_INIT_BIN_STRING_ALGEBRAIC:
        if (k < (size_t) modelData->nVariablesStringArray) reset_start(&bin, v, &modelData->stringVarsData[k].attribute.start);
        break;
#endif
      case OMC_INIT_BIN_STRING_PARAMETER:
        if (k < (size_t) modelData->nParametersStringArray) reset_start(&bin, v, &modelData->stringParameterData[k].attribute.start);
        break;
      default:
        break;
    }
  }
  omc_init_bin_free(&bin);
}

void read_input(MODEL_DATA* modelData, SIMULATION_INFO* simulationInfo, modelica_boolean isFMU, threadData_t* threadData)
{
  omc_init_bin bin;
  hash_string_string *overrides = NULL;
  hash_string_long *overridesUses = NULL, *mapAlias = NULL, *mapAliasParam = NULL;
  hash_string_long *mapAliasSen = NULL;
  int sensitivityParIndex = 0;
  size_t i, j;

  load_init_bin(&bin, modelData, threadData);

  read_sizes(&bin.model, modelData);

  if (!isFMU && (omc_flagValue[FLAG_OVERRIDE] || omc_flagValue[FLAG_OVERRIDE_FILE])) {
    overrides = parseOverrides(omc_flagValue[FLAG_OVERRIDE], omc_flagValue[FLAG_OVERRIDE_FILE]);
    gCommandLineOverrides = overrides;
  } else {
    infoStreamPrint(OMC_LOG_SOLVER, 0, "NO override given on the command line.");
  }

  read_experiment(simulationInfo, &bin.experiment, !isFMU);
  simulationInfo->OPENMODELICAHOME = GC_strdup(bin.model.omhome);
  infoStreamPrint(OMC_LOG_SIMULATION, 0, "OPENMODELICAHOME: %s", simulationInfo->OPENMODELICAHOME);

  allocModelDataVars(modelData, TRUE, threadData);
  read_enumeration_types(&bin, modelData);

  if (omc_flag[FLAG_IDAS]) {
    simulationInfo->sensitivityParList = (int*) calloc(modelData->nSensitivityParamVars, sizeof(int));
    simulationInfo->sensitivityMatrix = (modelica_real*) calloc(modelData->nSensitivityVars - modelData->nSensitivityParamVars, sizeof(modelica_real));
  }

  for (i = 0; i < bin.numVariables; i++) {
    const omc_init_bin_variable *v = &bin.variables[i];
    size_t k = i - bin.classStart[v->classType];
    const char *start = overrides && v->classType != OMC_INIT_BIN_REAL_SENSITIVITY ? overrideValue(overrides, &overridesUses, v) : NULL;
    switch (v->classType) {
      case OMC_INIT_BIN_REAL_STATE:
      case OMC_INIT_BIN_REAL_DERIVATIVE:
      case OMC_INIT_BIN_REAL_ALGEBRAIC:
        j = k + (v->classType == OMC_INIT_BIN_REAL_STATE ? 0 : v->classType == OMC_INIT_BIN_REAL_DERIVATIVE ? 1 : 2) * modelData->nStatesArray;
        if (j >= (size_t) modelData->nVariablesRealArray) break;
        read_variable(&bin, v, start, &modelData->realVarsData[j].info, &modelData->realVarsData[j].dimension,
                      &modelData->realVarsData[j].filterOutput, &modelData->realVarsData[j].attribute);
        addHashStringLong(&mapAlias, v->name, j);
        break;
      case OMC_INIT_BIN_REAL_PARAMETER:
        if (k >= (size_t) modelData->nParametersRealArray) break;
        read_variable(&bin, v, start, &modelData->realParameterData[k].info, &modelData->realParameterData[k].dimension,
                      &modelData->realParameterData[k].filterOutput, &modelData->realParameterData[k].attribute);
        addHashStringLong(&mapAliasParam, v->name, k);
        break;
      case OMC_INIT_BIN_INTEGER_ALGEBRAIC:
        if (k >= (size_t) modelData->nVariablesIntegerArray) break;
        read_variable(&bin, v, start, &modelData->integerVarsData[k].info, &modelData->integerVarsData[k].dimension,
                      &modelData->integerVarsData[k].filterOutput, &modelData->integerVarsData[k].attribute);
        modelData->integerVarsData[k].enumeration = find_enumeration(modelData, v->declaredType);
        addHashStringLong(&mapAlias, v->name, k);
        break;
      case OMC_INIT_BIN_INTEGER_PARAMETER:
        if (k >= (size_t) modelData->nParametersIntegerArray) break;
        read_variable(&bin, v, start, &modelData->integerParameterData[k].info, &modelData->integerParameterData[k].dimension,
                      &modelData->integerParameterData[k].filterOutput, &modelData->integerParameterData[k].attribute);
        modelData->integerParameterData[k].enumeration = find_enumeration(modelData, v->declaredType);
        addHashStringLong(&mapAliasParam, v->name, k);
        break;
      case OMC_INIT_BIN_BOOLEAN_ALGEBRAIC:
        if (k >= (size_t) modelData->nVariablesBooleanArray) break;
        read_variable(&bin, v, start, &modelData->booleanVarsData[k].info, &modelData->booleanVarsData[k].dimension,
                      &modelData->booleanVarsData[k].filterOutput, &modelData->booleanVarsData[k].attribute);
        addHashStringLong(&mapAlias, v->name, k);
        break;
      case OMC_INIT_BIN_BOOLEAN_PARAMETER:
        if (k >= (size_t) modelData->nParametersBooleanArray) break;
        read_variable(&bin, v, start, &modelData->booleanParameterData[k].info, &modelData->booleanParameterData[k].dimension,
                      &modelData->booleanParameterData[k].filterOutput, &modelData->booleanParameterData[k].attribute);
        addHashStringLong(&mapAliasParam, v->name, k);
        break;
#if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
      case OMC_INIT_BIN_STRING_ALGEBRAIC:
        if (k >= (size_t) modelData->nVariablesStringArray) break;
        read_variable(&bin, v, start, &modelData->stringVarsData[k].info, &modelData->stringVarsData[k].dimension,
                      &modelData->stringVarsData[k].filterOutput, &modelData->stringVarsData[k].attribute);
        addHashStringLong(&mapAlias, v->name, k);
        break;
#endif
      case OMC_INIT_BIN_STRING_PARAMETER:
        if (k >= (size_t) modelData->nParametersStringArray) break;
        read_variable(&bin, v, start, &modelData->stringParameterData[k].info, &modelData->stringParameterData[k].dimension,
                      &modelData->stringParameterData[k].filterOutput, &modelData->stringParameterData[k].attribute);
        addHashStringLong(&mapAliasParam, v->name, k);
        break;
      case OMC_INIT_BIN_REAL_SENSITIVITY:
        if (!omc_flag[FLAG_IDAS] || k >= (size_t) modelData->nSensitivityVars) break;
        read_variable(&bin, v, NULL, &modelData->realSensitivityData[k].info, &modelData->realSensitivityData[k].dimension,
                      &modelData->realSensitivityData[k].filterOutput, &modelData->realSensitivityData[k].attribute);
        addHashStringLong(&mapAliasSen, v->name, k);
        if (v->flags & OMC_INIT_BIN_VALUE_CHANGEABLE) {
          long *p = findHashStringLongPtr(mapAliasParam, v->name);
          if (p) {
            simulationInfo->sensitivityParList[sensitivityParIndex] = *p;
            infoStreamPrint(OMC_LOG_SOLVER, 0, "%d. sensitivity parameter %s at index %d", sensitivityParIndex, v->name, simulationInfo->sensitivityParList[sensitivityParIndex]);
            sensitivityParIndex++;
          }
        }
        break;
      default:
        break;
    }
  }

  for (i = 0; i < bin.numVariables; i++) {
    const omc_init_bin_variable *v = &bin.variables[i];
    size_t k = i - bin.classStart[v->classType];
    DATA_ALIAS *aliases;
    long n;
    switch (v->classType) {
      case OMC_INIT_BIN_REAL_ALIAS: aliases = modelData->realAlias; n = modelData->nAliasRealArray; break;
      case OMC_INIT_BIN_INTEGER_ALIAS: aliases = modelData->integerAlias; n = modelData->nAliasIntegerArray; break;
      case OMC_INIT_BIN_BOOLEAN_ALIAS: aliases = modelData->booleanAlias; n = modelData->nAliasBooleanArray; break;
      case OMC_INIT_BIN_STRING_ALIAS: aliases = modelData->stringAlias; n = modelData->nAliasStringArray; break;
      default: continue;
    }
    if ((long) k < n) {
      read_alias(v, &aliases[k], mapAlias, mapAliasParam);
    }
  }

  calculateAllScalarLength(modelData);

  if (overrides) {
    hash_string_string *o, *otmp;
    HASH_ITER(hh, overrides, o, otmp) {
      if (!findHashStringLongPtr(overridesUses, o->id)) {
        warningStreamPrint(OMC_LOG_STDOUT, 0, "simulation_input.c: override variable name not found in model: %s\n", o->id);
      }
    }
    infoStreamPrint(OMC_LOG_SOLVER, 0, "override done!");
  }
  freeHashStringLong(overridesUses);
  freeHashStringLong(mapAlias);
  freeHashStringLong(mapAliasParam);
  freeHashStringLong(mapAliasSen);
  omc_init_bin_free(&bin);
}

static void json_string(FILE *out, const char *s)
{
  fputc('"', out);
  for (; *s; s++) {
    unsigned char c = (unsigned char) *s;
    switch (c) {
      case '"': fputs("\\\"", out); break;
      case '\\': fputs("\\\\", out); break;
      case '\n': fputs("\\n", out); break;
      case '\r': fputs("\\r", out); break;
      case '\t': fputs("\\t", out); break;
      default:
        if (c < 0x20) {
          fprintf(out, "\\u%04x", c);
        } else {
          fputc(c, out);
        }
    }
  }
  fputc('"', out);
}

/* The shortest text that reads back as r; JSON has no infinity or NaN. */
static void json_real(FILE *out, double r)
{
  char buf[32];
  int precision;
  if (isnan(r)) {
    fputs("null", out);
    return;
  }
  if (isinf(r)) {
    fputs(r > 0 ? "1e999" : "-1e999", out);
    return;
  }
  for (precision = 15; precision < 17; precision++) {
    snprintf(buf, sizeof(buf), "%.*g", precision, r);
    if (strtod(buf, NULL) == r) {
      break;
    }
  }
  if (precision == 17) {
    snprintf(buf, sizeof(buf), "%.17g", r);
  }
  fputs(buf, out);
}

static void json_value(FILE *out, const omc_init_bin *bin, const omc_init_bin_variable *v, size_t index)
{
  switch (v->baseType) {
    case OMC_INIT_BIN_REAL: json_real(out, omc_init_bin_real(bin, index)); break;
    case OMC_INIT_BIN_BOOLEAN: fputs(omc_init_bin_integer(bin, index) ? "true" : "false", out); break;
    case OMC_INIT_BIN_STRING: json_string(out, omc_init_bin_string(bin, index)); break;
    default: fprintf(out, "%" PRId64, omc_init_bin_integer(bin, index)); break;
  }
}

static void json_values(FILE *out, const omc_init_bin *bin, const omc_init_bin_variable *v, const char *name, omc_init_bin_values values)
{
  uint32_t i;
  if (!values.count) {
    return;
  }
  fprintf(out, ",\"%s\":", name);
  if (!(v->flags & OMC_INIT_BIN_ARRAY)) {
    json_value(out, bin, v, values.index);
    return;
  }
  fputc('[', out);
  for (i = 0; i < values.count; i++) {
    if (i) fputc(',', out);
    json_value(out, bin, v, values.index + i);
  }
  fputc(']', out);
}

/* An -override value with the type of v, else as a string. */
static void json_override(FILE *out, const omc_init_bin_variable *v, const char *value)
{
  char *end;
  if (!(v->flags & OMC_INIT_BIN_ARRAY) && *value) {
    switch (v->baseType) {
      case OMC_INIT_BIN_REAL: {
        double r = strtod(value, &end);
        if (!*end) {
          json_real(out, r);
          return;
        }
        break;
      }
      case OMC_INIT_BIN_INTEGER:
      case OMC_INIT_BIN_ENUMERATION: {
        long long i = strtoll(value, &end, 10);
        if (!*end) {
          fprintf(out, "%lld", i);
          return;
        }
        break;
      }
      case OMC_INIT_BIN_BOOLEAN:
        if (!strcmp(value, "true") || !strcmp(value, "false")) {
          fputs(value, out);
          return;
        }
        break;
      default:
        break;
    }
  }
  json_string(out, value);
}

static void json_variable(FILE *out, const omc_init_bin *bin, const omc_init_bin_variable *v, const char *start)
{
  static const char *types[] = {"Real", "Integer", "Boolean", "String", "Enumeration", "ExternalObject"};
  static const char *variabilities[] = {"continuous", "discrete", "parameter", "constant"};
  static const char *causalities[] = {"local", "none", "output", "input", "parameter", "calculatedParameter"};
  static const char *aliases[] = {"noAlias", "alias", "negatedAlias"};
  uint32_t d;

  fputs("{\"name\":", out);
  json_string(out, v->name);
  fprintf(out, ",\"type\":\"%s\",\"description\":", types[v->baseType]);
  json_string(out, v->description);
  fprintf(out, ",\"variability\":\"%s\",\"causality\":\"%s\",\"isValueChangeable\":%s,\"alias\":\"%s\"",
          variabilities[v->variability], causalities[v->causality],
          v->flags & OMC_INIT_BIN_VALUE_CHANGEABLE ? "true" : "false", aliases[v->alias]);
  if (v->alias != OMC_INIT_BIN_NO_ALIAS) {
    fputs(",\"aliasVariable\":", out);
    json_string(out, v->aliasVariable);
  }
  fprintf(out, ",\"isProtected\":%s,\"isEncrypted\":%s",
          v->flags & OMC_INIT_BIN_PROTECTED ? "true" : "false", v->flags & OMC_INIT_BIN_ENCRYPTED ? "true" : "false");
  if (v->hideResult != OMC_INIT_BIN_HIDE_RESULT_UNSET) {
    fprintf(out, ",\"hideResult\":%s", v->hideResult == OMC_INIT_BIN_HIDE_RESULT_TRUE ? "true" : "false");
  }
  if (*v->declaredType) {
    fputs(",\"declaredType\":", out);
    json_string(out, v->declaredType);
  }
  if (v->flags & OMC_INIT_BIN_ARRAY) {
    fputs(",\"dimensions\":[", out);
    for (d = 0; d < v->numDimensions; d++) {
      int64_t size = omc_init_bin_integer(bin, v->firstDimension + 2*d);
      if (d) fputc(',', out);
      if (size >= 0) {
        fprintf(out, "%" PRId64, size);
      } else {
        fprintf(out, "{\"valueReference\":%" PRId64 "}", omc_init_bin_integer(bin, v->firstDimension + 2*d + 1));
      }
    }
    fputc(']', out);
  }
  if (start) {
    fputs(",\"start\":", out);
    json_override(out, v, start);
  } else {
    json_values(out, bin, v, "start", v->start);
  }
  json_values(out, bin, v, "min", v->min);
  json_values(out, bin, v, "max", v->max);
  if (*v->unit) {
    fputs(",\"unit\":", out);
    json_string(out, v->unit);
  }
  if (*v->displayUnit) {
    fputs(",\"displayUnit\":", out);
    json_string(out, v->displayUnit);
  }
  fputc('}', out);
}

void list_variables(MODEL_DATA* modelData, threadData_t* threadData)
{
  omc_init_bin bin;
  hash_string_string *overrides = NULL;
  const omc_init_bin_experiment *e;
  size_t i;
  FILE *out = stdout;

  load_init_bin(&bin, modelData, threadData);
  if (omc_flagValue[FLAG_OVERRIDE] || omc_flagValue[FLAG_OVERRIDE_FILE]) {
    overrides = parseOverrides(omc_flagValue[FLAG_OVERRIDE], omc_flagValue[FLAG_OVERRIDE_FILE]);
  }
  e = &bin.experiment;
  fputs("{\"modelName\":", out);
  json_string(out, bin.model.modelName);
  fputs(",\"generationTool\":", out);
  json_string(out, bin.model.generationTool);
  fputs(",\"defaultExperiment\":{\"startTime\":", out);
  json_real(out, e->startTime);
  fputs(",\"stopTime\":", out);
  json_real(out, e->stopTime);
  fputs(",\"stepSize\":", out);
  json_real(out, e->stepSize);
  fputs(",\"tolerance\":", out);
  json_real(out, e->tolerance);
  fputs(",\"solver\":", out);
  json_string(out, e->solver);
  fputs(",\"outputFormat\":", out);
  json_string(out, e->outputFormat);
  fputs(",\"variableFilter\":", out);
  json_string(out, e->variableFilter);
  fputs("},\"variables\":[", out);
  for (i = 0; i < bin.numVariables; i++) {
    const omc_init_bin_variable *v = &bin.variables[i];
    modelica_boolean changeable = (v->flags & OMC_INIT_BIN_VALUE_CHANGEABLE) && v->classType != OMC_INIT_BIN_REAL_SENSITIVITY;
    fputs(i ? ",\n" : "\n", out);
    json_variable(out, &bin, v, changeable ? findHashStringStringNull(overrides, v->name) : NULL);
  }
  fputs("\n]}\n", out);
  fflush(out);
  omc_init_bin_free(&bin);
}

int isQuantityOverridden(const char *name)
{
  return findHashStringStringNull(gCommandLineOverrides, name) != NULL;
}

void parseVariableStr(char* variableStr)
{
  /* TODO! FIXME!: support also quoted identifiers containing comma: , */
  unsigned int i = 0, insideArray = 0;
  for (i = 0; i < strlen(variableStr); i++)
  {
    if (variableStr[i] == '[') { insideArray = 1; }
    if (variableStr[i] == ']') { insideArray = 0; }
    if ((insideArray == 0) && (variableStr[i] == ',')) { variableStr[i] = '!'; }
  }
}
