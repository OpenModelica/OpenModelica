// name: TopLevelInputs2
// keywords:
// status: correct
// cflags: -d=newInst
//
// Top-level inputs with bindings should not be counted as top-level inputs
// without bindings if their binding is moved to an equation section.
//

model TopLevelInputs2
  input Real x[:] = {1, 2, 3};
end TopLevelInputs2;

// Result:
// class TopLevelInputs2
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   x = {1.0, 2.0, 3.0};
// end TopLevelInputs2;
// [flattening/modelica/scodeinst/TopLevelInputs2.mo:11:3-11:30:writable] Notification: Top-level input 'x' has a binding equation and will not be accessible as an input of the model.
//
// endResult
