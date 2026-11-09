// name:     ShortClassdefExtends2
// keywords: extends
// status:   correct
//
// Checks that a short class definition is allowed to extend a replaceable
// class.
//

model ShortClassdefExtends2
  replaceable model A
    Real x;
  end A;

  model D = A;
  D d;
end ShortClassdefExtends2;

// Result:
// class ShortClassdefExtends2
//   Real d.x;
// end ShortClassdefExtends2;
// endResult
