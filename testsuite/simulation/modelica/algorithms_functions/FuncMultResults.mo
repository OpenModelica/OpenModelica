// name:     FuncMultResults
// keywords: function
// status:   correct
//
// function handling
// Drmodelica: 9.1 Function with Multiple Results (p. 287)
//

function f
  input Real x;
  input Real y;
  output Real r1;
  output Real r2;
  output Real r3;
algorithm
  r1 := x;
  r2 := y;
  r3 := x*y;
end f;

model fCall
  Real x[3];
  Real a, b, c;
equation
  (a, b, c) = f(1.0, 2.0);
  (x[1], x[2], x[3]) = f(3.0, 4.0);
end fCall;

// function f
// input Real x;
// input Real y;
// output Real r1;
// output Real r2;
// output Real r3;
// algorithm
//   r1 := x;
//   r2 := y;
//   r3 := x * y;
// end f;
//
// class fCall
// Real x[1];
// Real x[2];
// Real x[3];
// Real a;
// Real b;
// Real c;
// equation
//   (a,b,c) = (1.0,2.0,2.0);
//   (x[1],x[2],x[3]) = (3.0,4.0,12.0);
// end fCall;
