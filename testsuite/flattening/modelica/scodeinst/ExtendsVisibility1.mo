// name: ExtendsVisibility1
// keywords: extends visibility
// status: correct
// cflags: -d=newInst
//
// Checks that the visibility of extends clauses is handled correctly.
//


model Base1
  Real x1;
  Real y1;
  protected Real z1;
end Base1;

model Base2
  Real x2;
  Real y2;
  protected Real z2;
end Base2;

model ExtendsVisibility1
  extends Base1;
protected
  extends Base2;
end ExtendsVisibility1;

// Result:
// class ExtendsVisibility1
//   Real x1;
//   Real y1;
//   protected Real z1;
//   protected Real x2;
//   protected Real y2;
//   protected Real z2;
// end ExtendsVisibility1;
// endResult
