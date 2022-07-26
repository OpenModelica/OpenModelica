// name: CevalBinding6
// status: correct
// cflags: -d=newInst
//
//

model A
  parameter Real x annotation(Evaluate = true);
end A;

model B
  parameter Real y = 1;
end B;

model CevalBinding6
  B[3] b(y = {1 for i in 1:3});
  A a(x = sum(b.y));
end CevalBinding6;

// Result:
// class CevalBinding6
//   final parameter Real b[1].y = 1.0;
//   final parameter Real b[2].y = 1.0;
//   final parameter Real b[3].y = 1.0;
//   final parameter Real a.x = 3.0;
// end CevalBinding6;
// endResult
