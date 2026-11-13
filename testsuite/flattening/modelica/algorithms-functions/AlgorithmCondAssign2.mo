// name:     AlgorithmCondAssign
// keywords: for statement, if statement
// status:   correct
//
// Assignments within if-Statements
// Drmodelica: 9.1  if-Statement (p. 292)
//

function CondAssignFunc
  input Real z;
  output Real x = 35;
  output Real y = 45;
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

// Result:
// class CondAssignFuncCall
//   Real a;
//   Real b;
// equation
//   a = 400.0;
//   b = 45.0;
// end CondAssignFuncCall;
// endResult
