// name:     HideVariableForEquations
// keywords: for
// status:   correct
//
// Drmodelica: 8.2 Repetitive Equation Structures with for-Equations (p. 241)
//

class HideVariableForEquations
  constant Integer k = 4;
  Real     x[k + 1];
equation
  for k in 1:k+1 loop  // The iteration variable k gets values 1, 2, 3, 4, 5
    x[k] = k;          // Uses of the iteration variable k
  end for;
end HideVariableForEquations;

// Result:
// class HideVariableForEquations
//   constant Integer k = 4;
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
//   Real x[5];
// equation
//   x[1] = 1.0;
//   x[2] = 2.0;
//   x[3] = 3.0;
//   x[4] = 4.0;
//   x[5] = 5.0;
// end HideVariableForEquations;
// endResult
