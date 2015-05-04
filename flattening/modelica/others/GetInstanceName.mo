// name: GetInstanceName
// cflags: +i=O.N
// status: correct

function f
  output String s = getInstanceName();
end f;

package P
  constant String s = getInstanceName();
end P;

model M
  String s1 = getInstanceName();
  String s2 = f();
  String s3 = P.s;
end M;

model O
model P
  M m;
end P;
model N
  M m;
  P p;
end N;
end O;

// Result:
// function f
//   output String s = "f";
// end f;
//
// class O.N
//   String m.s1 = "N.m";
//   String m.s2 = "f";
//   String m.s3 = "P";
//   String p.m.s1 = "N.p.m";
//   String p.m.s2 = "f";
//   String p.m.s3 = "P";
// end O.N;
// endResult
