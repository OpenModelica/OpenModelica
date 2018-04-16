// name: Each5
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x;
end A;

model B
  A a;
end B;

model Each5
  B b[3](a(each x = 1.0));  
end Each5;

// Result:
// class Each5
//   Real b[1].a.x = 1.0;
//   Real b[2].a.x = 1.0;
//   Real b[3].a.x = 1.0;
// end Each5;
// endResult
