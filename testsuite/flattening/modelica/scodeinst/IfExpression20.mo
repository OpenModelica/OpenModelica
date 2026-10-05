// name: IfExpression20
// keywords:
// status: correct
//

package MixtureGasNasa
  constant Boolean fixedX = false;
  constant Real reference_X[nX] = fill(1/nX, nX);
  constant Integer nX = 3;

  model BaseProperties
    Real h;
    Real T;
    Real X[nX];
  equation
    h = h_TX(T, X);
  end BaseProperties;

  function h_TX
    input Real T;
    input Real X[:] = reference_X;
    output Real h;
  algorithm
    h := (if fixedX then reference_X else X)*X;
  end h_TX;
end MixtureGasNasa;

model IfExpression20
  replaceable package Medium = MixtureGasNasa;
  Medium.BaseProperties medium;
end IfExpression20;

// Result:
// function IfExpression20.Medium.h_TX
//   input Real T;
//   input Real[:] X = {0.3333333333333333, 0.3333333333333333, 0.3333333333333333};
//   output Real h;
// algorithm
//   h := X * X;
// end IfExpression20.Medium.h_TX;
//
// class IfExpression20
//   Real medium.h;
//   Real medium.T;
//   Real medium.X[1];
//   Real medium.X[2];
//   Real medium.X[3];
// equation
//   medium.h = IfExpression20.Medium.h_TX(medium.T, medium.X);
// end IfExpression20;
// endResult
