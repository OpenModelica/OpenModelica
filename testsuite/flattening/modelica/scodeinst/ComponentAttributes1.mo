// name: ComponentAttributes1
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x;
protected
  Real y;
end A;

model ComponentAttributes1
  protected A a;  
end ComponentAttributes1;

// Result:
// class ComponentAttributes1
//   protected Real a.x;
//   protected Real a.y;
// end ComponentAttributes1;
// endResult
