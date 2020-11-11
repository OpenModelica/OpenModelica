// name:     AlgorithmCondAssign
// keywords: for statement, if statement
// status:   correct
//
// Assignments within if-Statements
// Drmodelica: 9.1  if-Statement (p. 292)
// cflags: -d=-newInst
//

function CondAssignFunc
  input Real z;
  output Real x := 35;
  output Real y := 45;
algorithm
  if x > 5 then
    x := 400;
  end if;
  if z > 10 then
    y := 500;
  end if;
end CondAssignFunc;

model CondAssignFuncCall
  Real a, b;
equation
  (a, b) = CondAssignFunc(5);
end CondAssignFuncCall;

// function CondAssignFunc
// input Real z;
// output Real x;
// output Real y;
// equation
//   x = 35.0;
//   y = 45.0;
// algorithm
//   if x > 5.0 then
//     x := 400.0;
//   end if;
//   if z > 10.0 then
//     y := 500.0;
//   end if;
// end CondAssignFunc;
//
// class CondAssignFuncCall
// Real a;
// Real b;
// equation
//   (a,b) = (400.0,-1.0);
// end CondAssignFuncCall;
