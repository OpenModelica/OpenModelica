// name:     ShortClassdefExtends1
// keywords: extends
// status:   correct
//
// Checks that extending a short class definition works.
//

model A
  model B
    Real x;
  end B;
end A;

model ShortClassdefExtends1
  model D = A;
  extends D.B;
end ShortClassdefExtends1;

// Result:
// class ShortClassdefExtends1
//   Real x;
// end ShortClassdefExtends1;
// endResult
