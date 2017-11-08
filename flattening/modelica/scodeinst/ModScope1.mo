// name: ModScope1
// keywords:
// status: correct
// cflags: -d=newInst
//
// Checks that modifiers are instantiated in the correct scope.
// 

model A 
  parameter Real x = 0;
end A;

model B 
  parameter Real x = 0;
  A a(x = x);
end B;

model C 
  extends B;
end C;

model ModScope1
  C c;
end ModScope1;

// Result:
// class ModScope1
//   parameter Real c.x = 0.0;
//   parameter Real c.a.x = c.x;
// end ModScope1;
// endResult
