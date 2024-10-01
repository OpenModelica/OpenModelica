// name: StateSelectVariability1
// keywords:
// status: correct
//

model StateSelectVariability1
  constant StateSelect s = StateSelect.never;
end StateSelectVariability1;

// Result:
// class StateSelectVariability1
//   constant enumeration(never, avoid, default, prefer, always) s = StateSelect.never;
// end StateSelectVariability1;
// endResult
