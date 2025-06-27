// name: Record6
// status: correct

type MassFraction = Real(min = 0);

record ThermodynamicState
  MassFraction X[2];
end ThermodynamicState;

function specificEnthalpy
  input ThermodynamicState state;
  output Real h;
algorithm
  h := state.X[1];
end specificEnthalpy;

model Record6
  Real X_in_internal[2];
  Real h_internal = specificEnthalpy(ThermodynamicState(X_in_internal));
  annotation(__OpenModelica_commandLineOptions="-d=newInst -f");
end Record6;

// Result:
// //! base 0.1.0
// package 'Record6'
//   function 'specificEnthalpy'
//     input 'ThermodynamicState' 'state';
//     output Real 'h';
//   algorithm
//     'h' := 'state'.'X'[1];
//   end 'specificEnthalpy';
//
//   record 'ThermodynamicState'
//     Real[2] 'X'(min = fill(0.0, 2));
//   end 'ThermodynamicState';
//
//   model 'Record6'
//     Real[2] 'X_in_internal';
//     Real 'h_internal' = 'specificEnthalpy'('ThermodynamicState'('X_in_internal'));
//   end 'Record6';
// end 'Record6';
// endResult
