// name: enum8.mo
// keywords:
// status: correct
// cflags: -d=newInst
//

model M
  Real x[StateSelect];
end M;

// Result:
// class M
//   Real x[StateSelect.never];
//   Real x[StateSelect.avoid];
//   Real x[StateSelect.default];
//   Real x[StateSelect.prefer];
//   Real x[StateSelect.always];
// end M;
// endResult
