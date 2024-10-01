// name: EqualityConstraint3
// keywords:
// status: correct
//

type Real2 = Real[2];
type Overconstrained
  extends Real2;
  function equalityConstraint
    input Real u1[2];
    input Real u2[2];
    output Real residue[1];
  algorithm
    residue[1] := u1[1] - u2[1];
  end equalityConstraint;
end Overconstrained;

connector C
  Real e;
  flow Real f;
  Overconstrained o;
  flow Real g;
end C;

model Source
  C c;
equation
  c.e = 1;
  Connections.potentialRoot(c.o);
  if Connections.isRoot(c.o) then
    c.o = {1, 0};
  end if;
end Source;

model Sink
  C c;
equation
  c.f = 1;
  c.g = 1;
end Sink;

model EqualityConstraint3
  Source source;
  Sink sink1;
  Sink sink2;
equation
  connect(source.c, sink1.c);
  connect(source.c, sink2.c);
  connect(sink1.c, sink2.c);
end EqualityConstraint3;

// Result:
// class EqualityConstraint3
//   Real source.c.e;
//   Real source.c.f;
//   Real source.c.o[1];
//   Real source.c.o[2];
//   Real source.c.g;
//   Real sink1.c.e;
//   Real sink1.c.f;
//   Real sink1.c.o[1];
//   Real sink1.c.o[2];
//   Real sink1.c.g;
//   Real sink2.c.e;
//   Real sink2.c.f;
//   Real sink2.c.o[1];
//   Real sink2.c.o[2];
//   Real sink2.c.g;
// equation
//   sink1.c.e = sink2.c.e;
//   sink1.c.e = source.c.e;
//   sink1.c.o[1] = sink2.c.o[1];
//   sink1.c.o[1] = source.c.o[1];
//   sink1.c.o[2] = sink2.c.o[2];
//   sink1.c.o[2] = source.c.o[2];
//   sink2.c.f + sink1.c.f + source.c.f = 0.0;
//   sink2.c.g + sink1.c.g + source.c.g = 0.0;
//   source.c.e = 1.0;
//   source.c.o[1] = 1.0;
//   source.c.o[2] = 0.0;
//   sink1.c.f = 1.0;
//   sink1.c.g = 1.0;
//   sink2.c.f = 1.0;
//   sink2.c.g = 1.0;
// end EqualityConstraint3;
// endResult
