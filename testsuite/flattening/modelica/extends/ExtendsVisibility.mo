// name:     ExtendsVisibility
// keywords: extends
// status:   correct
//
// Testing propagation of visibility for extends.

model A
  Real x;
end A;

model B
  extends A;
  Real y;
end B;

model ExtendsVisibility
  protected extends B;
end ExtendsVisibility;

// Result:
// class ExtendsVisibility
//   protected Real x;
//   protected Real y;
// end ExtendsVisibility;
// endResult
