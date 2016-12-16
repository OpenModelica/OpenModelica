// name:     ExternalFunction3
// keywords: external function,code generation,constant propagation
// status:   correct
// cflags: -d=gen
// setup_command: gcc `if test "x86_64" = \`uname -m\`; then echo -fPIC; fi` -c -o ExternalFunction3-addmatrices.o ExternalFunction3-addmatrices.c
// teardown_command: rm -f ExternalFunction3-addmatrices.o ExternalFunction3_*
//
// Constant evaluation of function calls. Result of a function call with
// constant arguments is inserted into flat modelica.
//

model ExternalFunction3

function addmatrices
  input Real a[:,:];
  input Real b[size(a,1),size(a,2)];
  output Real c[size(a,1),size(a,2)];
external "C" annotation(Library = "ExternalFunction3-addmatrices.o");
end addmatrices;

  constant Real a[2,2]={{1,2},{3,4}};
  constant Real b[2,2]={{5,6},{7,8}};
  Real c[2,2];
equation
  c = addmatrices(a,b);
end ExternalFunction3;

// Result:
// function ExternalFunction3.addmatrices
//   input Real[:, :] a;
//   input Real[size(a, 1), size(a, 2)] b;
//   output Real[size(a, 1), size(a, 2)] c;
//
//   external "C" addmatrices(a, size(a, 1), size(a, 2), b, size(b, 1), size(b, 2), c, size(c, 1), size(c, 2));
// end ExternalFunction3.addmatrices;
//
// class ExternalFunction3
//   constant Real a[1,1] = 1.0;
//   constant Real a[1,2] = 2.0;
//   constant Real a[2,1] = 3.0;
//   constant Real a[2,2] = 4.0;
//   constant Real b[1,1] = 5.0;
//   constant Real b[1,2] = 6.0;
//   constant Real b[2,1] = 7.0;
//   constant Real b[2,2] = 8.0;
//   Real c[1,1];
//   Real c[1,2];
//   Real c[2,1];
//   Real c[2,2];
// equation
//   c[1,1] = 6.0;
//   c[1,2] = 8.0;
//   c[2,1] = 10.0;
//   c[2,2] = 12.0;
// end ExternalFunction3;
// [flattening/modelica/external-functions/ExternalFunction3.mo:14:1-19:16:writable] Warning: An external declaration with a single output without explicit mapping is defined as having the output as the lhs, but language C does not support this for array variables. OpenModelica will put the output as an input (as is done when there is more than 1 output), but this is not according to the Modelica Specification. Use an explicit mapping instead of the implicit one to suppress this warning.
//
// endResult
