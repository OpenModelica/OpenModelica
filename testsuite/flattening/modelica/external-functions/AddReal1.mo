// name:     AddReal1
// keywords: external function, equation
// cflags:   +d=nogen
// status:   correct


function addReal1_
  input Real x;
  input Real y;
  output Real res;
  external "C";
end addReal1_;

model AddReal1
  parameter Real a=2.3;
  parameter Real b=4.5;
  Real c;
equation
  c = addReal1_(a, b);
end AddReal1;

// Result:
// function addReal1_
//   input Real x;
//   input Real y;
//   output Real res;
//
//   external "C" res = addReal1_(x, y);
// end addReal1_;
//
// class AddReal1
//   parameter Real a = 2.3;
//   parameter Real b = 4.5;
//   Real c;
// equation
//   c = addReal1_(a, b);
// end AddReal1;
// endResult
