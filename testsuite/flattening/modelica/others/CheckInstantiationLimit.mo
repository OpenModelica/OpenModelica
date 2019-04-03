// name: CheckInstantiationLimit
// status: correct

model CheckInstantiationLimit
  extends M(i=1);

package P
  constant Integer limit=10;
end P;

model N
  parameter Integer i;
  M m(i=i+1) if i <P.limit;
end N;

model M
  parameter Integer i;
  N n(i=i+1) if i<P.limit;
end M;

end CheckInstantiationLimit;
// Result:
// class CheckInstantiationLimit
//   parameter Integer i = 1;
//   parameter Integer n.i = 1 + i;
//   parameter Integer n.m.i = 1 + n.i;
//   parameter Integer n.m.n.i = 1 + n.m.i;
//   parameter Integer n.m.n.m.i = 1 + n.m.n.i;
//   parameter Integer n.m.n.m.n.i = 1 + n.m.n.m.i;
//   parameter Integer n.m.n.m.n.m.i = 1 + n.m.n.m.n.i;
//   parameter Integer n.m.n.m.n.m.n.i = 1 + n.m.n.m.n.m.i;
//   parameter Integer n.m.n.m.n.m.n.m.i = 1 + n.m.n.m.n.m.n.i;
//   parameter Integer n.m.n.m.n.m.n.m.n.i = 1 + n.m.n.m.n.m.n.m.i;
// end CheckInstantiationLimit;
// endResult
