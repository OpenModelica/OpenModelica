// name: Inline5
// keywords:
// status: correct
// cflags: -d=newInst
//

package PartialMedium
  constant Real[nX] reference_X = {0.01, 0.99};
  constant Integer nX = 2;
  constant Integer nXi = 1;

  replaceable record ThermodynamicState
    Real p;
    Real T;
    Real[nX] X;
  end ThermodynamicState;

  replaceable function setState_pTX
    input Real p;
    input Real T;
    input Real[:] X = reference_X;
    output ThermodynamicState state;
  algorithm
    state := if size(X, 1) == nX then ThermodynamicState(p = p, T = T, X = X) else ThermodynamicState(p = p, T = T, X = cat(1, X, {1 - sum(X)}));
    annotation(Inline = true);
  end setState_pTX;
end PartialMedium;

model Inline5
  replaceable package Medium = PartialMedium;
  final parameter Medium.ThermodynamicState state_start = Medium.setState_pTX(T = 20, p = 20, X = X_start[1:Medium.nXi]);
  parameter Real[Medium.nX] X_start = Medium.reference_X;
end Inline5;

// Result:
// class Inline5
//   final parameter Real state_start.p = 20.0;
//   final parameter Real state_start.T = 20.0;
//   final parameter Real state_start.X[1] = 0.01;
//   final parameter Real state_start.X[2] = 0.99;
//   parameter Real X_start[1] = 0.01;
//   parameter Real X_start[2] = 0.99;
// end Inline5;
// endResult
