// name:     FiveForEquations
// keywords: for
// status:   correct
//
// Drmodelica: 8.2 Repetitive Equation Structures with for-Equations (p. 241)
//

class FiveForEquations
  Real[5] x;
equation
  for i in 1:5 loop
    x[i] = i + 1;
  end for;
end FiveForEquations;

// Result:
// class FiveForEquations
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
//   Real x[5];
// equation
//   x[1] = 2.0;
//   x[2] = 3.0;
//   x[3] = 4.0;
//   x[4] = 5.0;
//   x[5] = 6.0;
// end FiveForEquations;
// [flattening/modelica/equations/FiveForEquations.mo:9:3-9:12:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/FiveForEquations.mo:11:3-13:10:writable] Warning: Equation sections are deprecated in class.
//
// endResult
