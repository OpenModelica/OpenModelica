// name:     ExternalFunction1
// keywords: external function,code generation,constant propagation
// status:   correct
// setup_command: $OMC_CC $OMC_CFLAGS $OMC_EXTLIB_FLAGS -o ExternalFunction1_f$OMC_EXTLIB_EXT ExternalFunction1_f.c $OMC_EXTLIB_LIBS
// teardown_command: rm -f ExternalFunction1_f$OMC_EXTLIB_EXT
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
  annotation(__OpenModelica_commandLineOptions="-d=gen -d=-newInst");
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
