// name:     AlgorithmCondAssign
// keywords: for statement, if statement
// status:   correct
//
// Assignments within if-Statements
// Drmodelica: 9.1  if-Statement (p. 292)
//


model CondAssign
  Real x(start = 35);
  Real y(start = 45);
  parameter Real z := 0;
algorithm
  if x > 5 then
    x := 400;
  end if;
  if z > 10 then
    y := 500;
  end if;
end CondAssign;

// class CondAssign
// Real x(start = 35.0);
// Real y(start = 45.0);
// parameter Real z = 0;
// algorithm
//   if x > 5.0 then
//     x := 400.0;
//   end if;
//   if z > 10.0 then
//     y := 500.0;
//   end if;
// end CondAssign;

