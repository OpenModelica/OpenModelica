// name:     MultFuncCall
// keywords: function, equation
// status:   correct
//
// Drmodelica: 2.2 Restricted Classes (p.28)
//
function Multiply
  input Real x;
  input Real y;
  output Real result;
algorithm
  result := x*y;
end Multiply;

model MultFuncCall
  Real res;
equation
  res = Multiply(3.5, 2.0);
end MultFuncCall;


// Result:
// function Multiply
//   input Real x;
//   input Real y;
//   output Real result;
// algorithm
//   result := x * y;
// end Multiply;
//
// class MultFuncCall
//   Real res;
// equation
//   res = 7.0;
// end MultFuncCall;
// endResult
