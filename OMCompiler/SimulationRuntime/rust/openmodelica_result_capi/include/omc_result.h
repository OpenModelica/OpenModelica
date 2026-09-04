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

/* Result files (.mat, .arrow, .csv, .plt) read, compared and converted by the
 * Rust `openmodelica_result_files` crate, as a C ABI plus a header-only C++
 * wrapper (namespace omc, below). Exported by libOpenModelicaCompiler and by
 * libopenmodelica_result_capi on its own.
 *
 * Ownership: `char*` results are malloc'd, free them with
 * omc_result_free_string; `const char*` and `const double*` results belong to
 * the reader and stay valid until omc_result_close. One reader is used from one
 * thread at a time. */
#ifndef OMC_RESULT_H
#define OMC_RESULT_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct omc_result omc_result;

typedef struct omc_result_tolerances {
  double reltol;             /* 1e-3 */
  double reltol_diff_min_max; /* 1e-4 */
  double range_delta;        /* 0.002 */
} omc_result_tolerances;

/* One variable's tube comparison (diffSimulationResultsHtml as data). */
typedef struct omc_result_tube {
  int differs;
  size_t n;                  /* length of time, reference, actual, high, low */
  const double *time;
  const double *reference;
  const double *actual;      /* the actual signal on the reference timeline */
  const double *high;
  const double *low;
  size_t n_error;            /* 0 when the signal stayed inside the tube */
  const double *error;
  size_t n_actual;           /* length of actual_time, actual_original */
  const double *actual_time;
  const double *actual_original;
  double abstol;
} omc_result_tube;

/* Open by suffix. NULL on failure; then *error (if error is not NULL) holds
 * the message. */
omc_result *omc_result_open(const char *path, char **error);
void omc_result_close(omc_result *r);
void omc_result_free_string(char *s);
void omc_result_free_strings(char **s, size_t n);

size_t omc_result_num_variables(const omc_result *r);
const char *omc_result_variable_name(const omc_result *r, size_t i);
/* The variables omc_result_diff compares when given none (no aliases). */
size_t omc_result_num_compared_variables(const omc_result *r);
const char *omc_result_compared_variable_name(const omc_result *r, size_t i);
int omc_result_has_variable(const omc_result *r, const char *var);
int omc_result_is_parameter(const omc_result *r, const char *var);
char *omc_result_description(const omc_result *r, const char *var);
char *omc_result_unit(const omc_result *r, const char *var);
char *omc_result_display_unit(const omc_result *r, const char *var);
char *omc_result_type(const omc_result *r, const char *var); /* Real, Integer, Boolean, String, enumeration */

size_t omc_result_num_rows(const omc_result *r);
const char *omc_result_time_name(const omc_result *r);
double omc_result_start_time(omc_result *r);
double omc_result_stop_time(omc_result *r);

/* Every row of var (a parameter repeats its value); NULL if unreadable. */
const double *omc_result_trajectory(omc_result *r, const char *var, size_t *len);
/* val(var, time); returns 0 when unreadable there. */
int omc_result_value_at(omc_result *r, const char *var, double time, double *out);
/* A String variable's text per row (*len entries), owned by the reader; NULL
 * unless the file stores Strings (.arrow) and var is one. */
const char *const *omc_result_strings(omc_result *r, const char *var, size_t *len);
/* The text of String var at time, for omc_result_free_string; NULL unless var
 * is a String with a value there. */
char *omc_result_string_at(omc_result *r, const char *var, double time);

/* Write path (.mat, .arrow or .csv by suffix) with n vars (all when 0),
 * resampled onto intervals equidistant steps unless 0, reals as single
 * precision when single. Returns 1 on success. */
int omc_result_write(omc_result *r, const char *path, const char *const *vars, size_t n,
                     unsigned intervals, int single, char **error);

omc_result_tolerances omc_result_default_tolerances(void);
/* diffSimulationResults: the differing variables among n vars (the reference's
 * compared variables when 0). tol NULL selects the defaults. Free the result
 * with omc_result_free_strings(result, *n_out). */
char **omc_result_diff(omc_result *actual, omc_result *reference, const char *const *vars, size_t n,
                       const omc_result_tolerances *tol, size_t *n_out, char **error);
omc_result_tube *omc_result_diff_variable(omc_result *actual, omc_result *reference, const char *var,
                                          const omc_result_tolerances *tol, char **error);
void omc_result_tube_free(omc_result_tube *t);

/* ---- Writers, for the C simulation runtime (simulation_result_rust.cpp). ---- */

enum { OMC_RESULT_TYPE_REAL = 0, OMC_RESULT_TYPE_INTEGER = 1, OMC_RESULT_TYPE_BOOLEAN = 2, OMC_RESULT_TYPE_STRING = 3 };
enum { OMC_RESULT_KIND_TIME = 0, OMC_RESULT_KIND_COLUMN = 1, OMC_RESULT_KIND_PARAMETER = 2 };
enum { OMC_RESULT_NEGATE_NONE = 0, OMC_RESULT_NEGATE_ARITHMETIC = 1, OMC_RESULT_NEGATE_LOGICAL = 2 };

/* One result variable. A kind-COLUMN signal reads row column `column`; several
 * signals on one column are aliases (`negate` for a negated one); `unvarying`
 * marks a column constant after initialization, stored like a parameter. A
 * kind-PARAMETER signal takes the next value of the `params` array. */
typedef struct omc_result_signal {
  const char *name;
  const char *description;
  const char *unit;
  const char *display_unit;
  int type;
  int discrete;
  int kind;
  unsigned column;
  int negate;
  int unvarying;
  /* FMI's relativeQuantity (Modelica absoluteValue=false): the value is a
   * difference in its unit, so a conversion scales it but adds no offset. */
  int relative_quantity;
} omc_result_signal;

typedef struct omc_result_writer omc_result_writer;

/* The id a String value takes in a STRING row column or parameter value.
 * Only the .arrow writer stores Strings. Process-global, never freed. */
unsigned omc_result_intern(const char *s);

/* Open path for format ("mat", "arrow", "csv", "plt"). column_types[c] is the
 * OMC_RESULT_TYPE_* of row column c; first_row is the row at open (n_columns
 * doubles); mat_sync > 0 flushes a readable file every that many rows (the
 * -mat_sync flag). NULL with *error set on failure. */
omc_result_writer *omc_result_writer_open(const char *path, const char *format,
                                          const omc_result_signal *signal_list, size_t n_signals,
                                          const int *column_types, size_t n_columns,
                                          const double *params, size_t n_params,
                                          const double *first_row, double start_time, double stop_time,
                                          int single, int mat_sync, char **error);
void omc_result_writer_emit(omc_result_writer *w, const double *row);
/* Finishes and frees the writer. Returns 1 if every write succeeded. */
int omc_result_writer_close(omc_result_writer *w);

#ifdef __cplusplus
} /* extern "C" */

#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

namespace omc {

class ResultError : public std::runtime_error {
public:
  explicit ResultError(const std::string &msg) : std::runtime_error(msg) {}
};

namespace detail {
inline std::string take(char *s) {
  std::string out = s ? s : "";
  omc_result_free_string(s);
  return out;
}
inline std::vector<const char *> ptrs(const std::vector<std::string> &v) {
  std::vector<const char *> out;
  out.reserve(v.size());
  for (const std::string &s : v) out.push_back(s.c_str());
  return out;
}
[[noreturn]] inline void raise(char *error, const char *fallback) {
  throw ResultError(error ? take(error) : std::string(fallback));
}
} // namespace detail

struct Tube {
  bool differs = false;
  std::vector<double> time, reference, actual, high, low, error, actualTime, actualOriginal;
  double abstol = 0;
};

class ResultFile {
public:
  ResultFile() = default;
  explicit ResultFile(const std::string &path) { open(path); }
  ~ResultFile() { close(); }
  ResultFile(const ResultFile &) = delete;
  ResultFile &operator=(const ResultFile &) = delete;
  ResultFile(ResultFile &&o) noexcept : r_(o.r_) { o.r_ = nullptr; }
  ResultFile &operator=(ResultFile &&o) noexcept {
    if (this != &o) { close(); r_ = o.r_; o.r_ = nullptr; }
    return *this;
  }

  void open(const std::string &path) {
    close();
    char *error = nullptr;
    r_ = omc_result_open(path.c_str(), &error);
    if (!r_) detail::raise(error, "Failed to open simulation result");
  }
  void close() { omc_result_close(r_); r_ = nullptr; }
  bool isOpen() const { return r_ != nullptr; }
  omc_result *handle() const { return r_; }

  std::vector<std::string> variables() const {
    std::vector<std::string> out;
    size_t n = omc_result_num_variables(r_);
    out.reserve(n);
    for (size_t i = 0; i < n; ++i) out.emplace_back(omc_result_variable_name(r_, i));
    return out;
  }
  bool hasVariable(const std::string &v) const { return omc_result_has_variable(r_, v.c_str()) != 0; }
  bool isParameter(const std::string &v) const { return omc_result_is_parameter(r_, v.c_str()) != 0; }
  std::string description(const std::string &v) const { return detail::take(omc_result_description(r_, v.c_str())); }
  std::string unit(const std::string &v) const { return detail::take(omc_result_unit(r_, v.c_str())); }
  std::string displayUnit(const std::string &v) const { return detail::take(omc_result_display_unit(r_, v.c_str())); }
  std::string type(const std::string &v) const { return detail::take(omc_result_type(r_, v.c_str())); }

  size_t rows() const { return omc_result_num_rows(r_); }
  std::string timeName() const { return omc_result_time_name(r_); }
  double startTime() const { return omc_result_start_time(r_); }
  double stopTime() const { return omc_result_stop_time(r_); }

  /* Owned by the reader; valid until close(). Empty when unreadable. */
  std::pair<const double *, size_t> trajectory(const std::string &v) const {
    size_t n = 0;
    const double *p = omc_result_trajectory(r_, v.c_str(), &n);
    return {p, p ? n : 0};
  }
  std::vector<double> values(const std::string &v) const {
    std::pair<const double *, size_t> t = trajectory(v);
    return std::vector<double>(t.first, t.first + t.second);
  }
  bool valueAt(const std::string &v, double time, double &out) const {
    return omc_result_value_at(r_, v.c_str(), time, &out) != 0;
  }
  /* A String variable's text per row; empty unless the file stores it. */
  std::vector<std::string> strings(const std::string &v) const {
    size_t n = 0;
    const char *const *p = omc_result_strings(r_, v.c_str(), &n);
    return p ? std::vector<std::string>(p, p + n) : std::vector<std::string>();
  }
  bool stringAt(const std::string &v, double time, std::string &out) const {
    char *s = omc_result_string_at(r_, v.c_str(), time);
    if (!s) return false;
    out = detail::take(s);
    return true;
  }

  void write(const std::string &path, const std::vector<std::string> &vars = {}, unsigned intervals = 0,
             bool single = false) const {
    std::vector<const char *> p = detail::ptrs(vars);
    char *error = nullptr;
    if (!omc_result_write(r_, path.c_str(), p.data(), p.size(), intervals, single ? 1 : 0, &error))
      detail::raise(error, "Failed to write result file");
  }

  static std::vector<std::string> diff(ResultFile &actual, ResultFile &reference,
                                       const std::vector<std::string> &vars = {},
                                       const omc_result_tolerances &tol = omc_result_default_tolerances()) {
    std::vector<const char *> p = detail::ptrs(vars);
    size_t n = 0;
    char *error = nullptr;
    char **names = omc_result_diff(actual.r_, reference.r_, p.data(), p.size(), &tol, &n, &error);
    if (!names) detail::raise(error, "diffSimulationResults failed");
    std::vector<std::string> out(names, names + n);
    omc_result_free_strings(names, n);
    return out;
  }

  static Tube diffVariable(ResultFile &actual, ResultFile &reference, const std::string &var,
                           const omc_result_tolerances &tol = omc_result_default_tolerances()) {
    char *error = nullptr;
    omc_result_tube *t = omc_result_diff_variable(actual.r_, reference.r_, var.c_str(), &tol, &error);
    if (!t) detail::raise(error, "diffSimulationResults failed");
    Tube out;
    out.differs = t->differs != 0;
    out.time.assign(t->time, t->time + t->n);
    out.reference.assign(t->reference, t->reference + t->n);
    out.actual.assign(t->actual, t->actual + t->n);
    out.high.assign(t->high, t->high + t->n);
    out.low.assign(t->low, t->low + t->n);
    out.error.assign(t->error, t->error + t->n_error);
    out.actualTime.assign(t->actual_time, t->actual_time + t->n_actual);
    out.actualOriginal.assign(t->actual_original, t->actual_original + t->n_actual);
    out.abstol = t->abstol;
    omc_result_tube_free(t);
    return out;
  }

private:
  omc_result *r_ = nullptr;
};

} // namespace omc
#endif /* __cplusplus */

#endif /* OMC_RESULT_H */
