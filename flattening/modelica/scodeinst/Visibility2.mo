// name: Visibility2
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x;
end A;

model Visibility2
  Real x = a.x;
protected
  A a;
end Visibility2;

// Result:
// class Visibility2
//   Real x = a.x;
//   protected Real a.x;
// end Visibility2;
// endResult
