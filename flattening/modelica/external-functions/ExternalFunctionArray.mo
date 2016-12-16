// name: ExternalFunctionArray
// cflags: -d=noevalfunc,gen
// status: correct
// teardown_command: rm -f ExternalFunctionArray_*
//
// Tests that the output arrays in temporaries do not overlap

model ExternalFunctionArray

function get_results
  input Real m;
  input String property;
  input Integer n;
  output Real res[n];
  external "C" getresults(m, property, res, n) annotation(Include="
void getresults(double m,const char *str,double *res, int n) {
  assert(n == 2);
  res[0]=m*1.5;res[1]=m*2.5;
}");
end get_results;

function f
  input Real r;
  output Real res[2] = (get_results(r,"abc",2).+get_results(2*r,"abc",2));
end f;

  Real res[2] = f(1.5);
end ExternalFunctionArray;
// Result:
// function ExternalFunctionArray.f
//   input Real r;
//   output Real[2] res = ExternalFunctionArray.get_results(r, "abc", 2) + ExternalFunctionArray.get_results(2.0 * r, "abc", 2);
// end ExternalFunctionArray.f;
//
// function ExternalFunctionArray.get_results
//   input Real m;
//   input String property;
//   input Integer n;
//   output Real[n] res;
//
//   external "C" getresults(m, property, res, n);
// end ExternalFunctionArray.get_results;
//
// class ExternalFunctionArray
//   Real res[1];
//   Real res[2];
// equation
//   res = {6.75, 11.25};
// end ExternalFunctionArray;
// endResult
