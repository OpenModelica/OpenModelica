// name: ExtendsVisibility2
// keywords: extends visibility
// status: correct
// cflags: -d=newInst
//
// Checks that the visibility of extends clauses is handled correctly.
//

model A
  Real x;
end A;

model B = A;

model ExtendsVisibility2
protected
  extends B;
end ExtendsVisibility2;

// Result:
// class ExtendsVisibility2
//   protected Real x;
// end ExtendsVisibility2;
// endResult
