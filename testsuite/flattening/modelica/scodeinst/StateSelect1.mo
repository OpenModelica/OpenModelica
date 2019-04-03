// name: StateSelect1
// keywords:
// status: correct
// cflags: -d=newInst
//

model StateSelect1
  Real x1(stateSelect = StateSelect.never);
  Real x2(stateSelect = StateSelect.avoid);
  Real x3(stateSelect = StateSelect.default);
  Real x4(stateSelect = StateSelect.prefer);
  Real x5(stateSelect = StateSelect.always);
end StateSelect1;

// Result:
// class StateSelect1
//   Real x1(stateSelect = StateSelect.never);
//   Real x2(stateSelect = StateSelect.avoid);
//   Real x3(stateSelect = StateSelect.default);
//   Real x4(stateSelect = StateSelect.prefer);
//   Real x5(stateSelect = StateSelect.always);
// end StateSelect1;
// endResult
