// name: Record5
// status: correct


package P
  constant Real X_start[:] = {1, 2};

  record ThermodynamicState
    Real p;
    Real T;
    Real X[2](start = X_start) = X_start;
  end ThermodynamicState;

  function f
    input Real p;
    input Real T;
    input Real X[:];
    output ThermodynamicState state;
  algorithm
    state := ThermodynamicState(p, T, X);
  end f;
end P;

model Record5
  P.ThermodynamicState state = P.f(1e5, 298.15, {0.03, 0.97});
  annotation(__OpenModelica_commandLineOptions="-d=newInst -f");
end Record5;

// Result:
// //! base 0.1.0
// package 'Record5'
//   record 'P.ThermodynamicState'
//     Real 'p';
//     Real 'T';
//     Real[2] 'X'(start = {1.0, 2.0}) = {1.0, 2.0};
//   end 'P.ThermodynamicState';
//
//   model 'Record5'
//     'P.ThermodynamicState' 'state'('p' = 1e5, 'T' = 298.15, 'X'(start = {1.0, 2.0}));
//   equation
//     'state'.'X' = {0.03, 0.97};
//   end 'Record5';
// end 'Record5';
// endResult
