// name: ExtendsVisibility3
// keywords: extends visibility
// status: correct
// cflags: -d=newInst
//
// Checks that the visibility of extends clauses is handled correctly.
//

model ExtendsVisibility3
  extends B;
protected
  model A
    Real x;
  end A;

  model B = A;
end ExtendsVisibility3;

// Result:
// class ExtendsVisibility3
//   Real x;
// end ExtendsVisibility3;
// endResult
