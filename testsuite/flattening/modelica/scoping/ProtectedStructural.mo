// name:     ProtectedStructural
// keywords: protected #2503
// status:   correct
//
// Checks that the protected attribute is propagated to the components of a
// structured component.
//

model ProtectedStructural
  model A
    Real x;
  end A;

  protected A a;
end ProtectedStructural;

// Result:
// class ProtectedStructural
//   protected Real a.x;
// end ProtectedStructural;
// endResult
