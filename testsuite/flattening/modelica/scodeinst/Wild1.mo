// name: Wild1
// keywords:
// status: correct
//

function f
  output Real x = 1.0;
  output Real y = 2.0;
end f;

model Wild1
  Real x;
algorithm
  (, x) := f();
end Wild1;

// Result:
// class Wild1
//   Real x;
// algorithm
//   x := 2.0;
// end Wild1;
// endResult
