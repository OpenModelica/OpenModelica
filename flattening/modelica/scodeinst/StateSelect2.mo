// name: StateSelect2
// keywords:
// status: correct
// cflags: -d=newInst
//

model StateSelect2
  parameter StateSelect s = StateSelect.default;
  Real x(stateSelect = s);
end StateSelect2;

// Result:
// class StateSelect2
//   parameter enumeration(never, avoid, default, prefer, always) s = StateSelect.default;
//   Real x(stateSelect = StateSelect.default);
// end StateSelect2;
// endResult
