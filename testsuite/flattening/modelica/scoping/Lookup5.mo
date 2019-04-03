// name:     Lookup5
// keywords: scoping
// status:   correct
//
// Modelica no longer requires declare before use.
// Thus the = -a refers to the 'a' declared
// at the same point and not to the 'a' in the
// enclosing scope.

class Lookup5
  constant Real a = 3.0;
  class B
    Real a = -a;
  end B;
  B b;
end Lookup5;

// Result:
// class Lookup5
//   constant Real a = 3.0;
//   Real b.a = -b.a;
// end Lookup5;
// endResult
