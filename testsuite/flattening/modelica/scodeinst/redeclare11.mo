// name: redeclare11.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
//
//

model ModelA
  parameter Real a = 10 ;
end ModelA;

model ModelB
  replaceable model Model = ModelA;
  Model m;
end ModelB;

model Test3
  model ModelA1 = ModelA(final a = 1);

  ModelB b( redeclare model Model = ModelA(a = 1));
  ModelB b1( redeclare model Model = ModelA1);
  ModelA1 a;
end Test3;

// Result:
// class Test3
//   parameter Real b.m.a = 1.0;
//   final parameter Real b1.m.a = 1.0;
//   final parameter Real a.a = 1.0;
// end Test3;
// endResult
