// name:     ModifierSubModMerging1
// keywords: modification #2789
// status:   correct
//
// Checks that submodifiers are merged correctly.
//

model A
  Real x;
end A;

model B
  extends A(x(start = 0, nominal = 0));
end B;

model ModifierSubModMerging1
  B b(x(start = 0), x(nominal = 0));
end ModifierSubModMerging1;

// Result:
// class ModifierSubModMerging1
//   Real b.x(start = 0.0, nominal = 0.0);
// end ModifierSubModMerging1;
// endResult
