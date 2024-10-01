// name: Expression1
// status: correct

function f
  input Real X[:];
  output Real Y;
protected
  constant Real Z[2] = {2, 3};
algorithm
  Y := 1 / (X*Z);
end f;

model Expression1
  Real Q;
  Real X[2];
equation
  Q = f(X);
  annotation(__OpenModelica_commandLineOptions="-d=newInst -f");
end Expression1;

// Result:
// //! base 0.1.0
// package 'Expression1'
//   function 'f'
//     input Real[:] 'X';
//     output Real 'Y';
//     constant Real[2] 'Z' = {2.0, 3.0};
//   algorithm
//     'Y' := 1.0 / ('X' * 'Z');
//   end 'f';
//
//   model 'Expression1'
//     Real 'Q';
//     Real[2] 'X';
//   equation
//     'Q' = 'f'('X');
//   end 'Expression1';
// end 'Expression1';
// endResult
