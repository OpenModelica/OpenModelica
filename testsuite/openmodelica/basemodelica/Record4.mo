// name: Record4
// status: correct


record ThermodynamicState
  Real p;
  Real T;
  Real X[2];
end ThermodynamicState;

function f
  input Real p;
  input Real T;
  input Real X[:];
  output ThermodynamicState state;
algorithm
  state := ThermodynamicState(p, T, X);
end f;

model Record4
  ThermodynamicState state = f(1e5, 298.15, {0.03, 0.97});
  annotation(__OpenModelica_commandLineOptions="-d=newInst -f");
end Record4;

// Result:
// //! base 0.1.0
// package 'Record4'
//   record 'ThermodynamicState'
//     Real 'p';
//     Real 'T';
//     Real[2] 'X';
//   end 'ThermodynamicState';
//
//   model 'Record4'
//     'ThermodynamicState' 'state'('p' = 1e5, 'T' = 298.15);
//   equation
//     'state'.'X' = {0.03, 0.97};
//   end 'Record4';
// end 'Record4';
// endResult
