// name: StateSelect3
// keywords:
// status: correct
//

model A
  parameter StateSelect ssu[1];
  Real u[1](stateSelect = ssu);
end A;

model B
  parameter StateSelect ss = StateSelect.prefer;
  A a(ssu = {ss});
end B;

model StateSelect3
  B b(ss = StateSelect.always);
end StateSelect3;

// Result:
// class StateSelect3
//   final parameter enumeration(never, avoid, default, prefer, always) b.ss = StateSelect.always;
//   final parameter enumeration(never, avoid, default, prefer, always) b.a.ssu[1] = StateSelect.always;
//   Real b.a.u[1](stateSelect = StateSelect.always);
// end StateSelect3;
// endResult
