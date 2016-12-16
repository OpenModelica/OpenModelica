// name:     ExternalFunction1
// cflags: -d=gen
// keywords: external function,code generation,constant propagation
// status:   correct
// setup_command: gcc `if test "x86_64" = \`uname -m\`; then echo -fPIC; fi` -c -o ExternalFunction1_f.o ExternalFunction1_f.c
// teardown_command: rm -f ExternalFunction1_f.o
//
// Constant evaluation of function calls. Result of a function call with
// constant arguments is inserted into flat modelica.
//

function f
  input Real x;
  output Real y;
external "C" y=ExternalFunction1_f(x) annotation(Library = "ExternalFunction1_f.o");
end f;

model ExternalFunction1
  constant Real x=5;
  Real y;
equation
  y = f(x);
end ExternalFunction1;


// function f
// input Real x;
// output Real y;
//
// external "C";
// end f;
//
// Result:
// function f
//   input Real x;
//   output Real y;
//
//   external "C" y = ExternalFunction1_f(x);
// end f;
//
// class ExternalFunction1
//   constant Real x = 5.0;
//   Real y;
// equation
//   y = 15.0;
// end ExternalFunction1;
// endResult
