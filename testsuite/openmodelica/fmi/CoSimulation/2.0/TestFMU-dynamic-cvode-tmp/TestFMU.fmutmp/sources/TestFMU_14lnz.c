/* Linearization */
#include "TestFMU_model.h"
#if defined(__cplusplus)
extern "C" {
#endif
const char *TestFMU_linear_model_frame()
{
  return "model linearized_model \"TestFMU\"\n"
  "  parameter Integer n = 1 \"number of states\";\n"
  "  parameter Integer m = 0 \"number of inputs\";\n"
  "  parameter Integer p = 1 \"number of outputs\";\n"
  "  parameter Real x0[n] = %s;\n"
  "  parameter Real u0[m] = %s;\n"
  "\n"
  "  parameter Real A[n, n] =\n\t[%s];\n\n"
  "  parameter Real B[n, m] = zeros(n, m);%s\n\n"
  "  parameter Real C[p, n] =\n\t[%s];\n\n"
  "  parameter Real D[p, m] = zeros(p, m);%s\n\n"
  "\n"
  "  Real x[n](start=x0);\n"
  "  input Real u[m];\n"
  "  output Real y[p];\n"
  "\n"
  "  Real 'x_$outputAlias_x' = x[1];\n"
  "  Real 'y_x' = y[1];\n"
  "equation\n"
  "  der(x) = A * x + B * u;\n"
  "  y = C * x + D * u;\n"
  "end linearized_model;\n";
}
const char *TestFMU_linear_model_datarecovery_frame()
{
  return "model linearized_model \"TestFMU\"\n"
  "  parameter Integer n = 1 \"number of states\";\n"
  "  parameter Integer m = 0 \"number of inputs\";\n"
  "  parameter Integer p = 1 \"number of outputs\";\n"
  "  parameter Integer nz = 2 \"data recovery variables\";\n"
  "  parameter Real x0[1] = %s;\n"
  "  parameter Real u0[0] = %s;\n"
  "  parameter Real z0[2] = %s;\n"
  "\n"
  "  parameter Real A[n, n] =\n\t[%s];\n\n"
  "  parameter Real B[n, m] = zeros(n, m);%s\n\n"
  "  parameter Real C[p, n] =\n\t[%s];\n\n"
  "  parameter Real D[p, m] = zeros(p, m);%s\n\n"
  "  parameter Real Cz[nz, n] =\n\t[%s];\n\n"
  "  parameter Real Dz[nz, m] = zeros(nz, m);%s\n\n"
  "\n"
  "  Real x[n](start=x0);\n"
  "  input Real u[m];\n"
  "  output Real y[p];\n"
  "  output Real z[nz];\n"
  "\n"
  "  Real 'x_$outputAlias_x' = x[1];\n"
  "  Real 'y_x' = y[1];\n"
  "  Real 'z_$x_der' = z[1];\n"
  "  Real 'z_x' = z[2];\n"
  "equation\n"
  "  der(x) = A * x + B * u;\n"
  "  y = C * x + D * u;\n"
  "  z = Cz * x + Dz * u;\n"
  "end linearized_model;\n";
}
#if defined(__cplusplus)
}
#endif

