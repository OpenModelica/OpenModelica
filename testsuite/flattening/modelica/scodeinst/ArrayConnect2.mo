// name: ArrayConnect2
// keywords:
// status: correct
// cflags: -d=newInst,arrayConnect,-nfScalarize
//

connector C
  Real e;
  flow Real f;
end C;

model A
  C p;
  C n;
end A;

model ArrayConnect2
  parameter Integer N = 1000;
  A S, R[N], C[N], G;
equation
  connect(S.p, R[1].p);
  connect(S.n, G.p) ;
  connect(C[1].n, G.p) ;

  for i in 1:N-1 loop
    connect(R[i].n, R[i+1].p);
    connect(C[i+1].n, C[i].n);
  end for;

  for i in 1:N loop
    connect(C[i].p, R[i].n);
  end for;
end ArrayConnect2;

// Result:
// class ArrayConnect2
//   final parameter Integer N = 1000;
//   Real S.p.e;
//   Real S.p.f;
//   Real S.n.e;
//   Real S.n.f;
//   Real[1000] R.n.f;
//   Real[1000] R.n.e;
//   Real[1000] R.p.f;
//   Real[1000] R.p.e;
//   Real[1000] C.n.f;
//   Real[1000] C.n.e;
//   Real[1000] C.p.f;
//   Real[1000] C.p.e;
//   Real G.p.e;
//   Real G.p.f;
//   Real G.n.e;
//   Real G.n.f;
// equation
//   C[1000].n.e = C[1].n.e;
//   C[1].n.f + C[1000].n.f = 0.0;
//   R[1].p.e = S.p.e;
//   S.p.f + R[1].p.f = 0.0;
//   G.p.e = S.n.e;
//   S.n.f + G.p.f = 0.0;
//   for $i1 in 3:999 loop
//     C[$i1].n.e = C[2].n.e;
//   end for;
//   sum(C[2:999].n.f) = 0.0;
//   for $i1 in 1:999 loop
//     C[$i1].p.e = R[$i1 + 1].p.e;
//   end for;
//   for $i1 in 2:1000 loop
//     C[$i1 - 1].p.f + R[$i1].p.f = 0.0;
//   end for;
//   for $i1 in 1:999 loop
//     R[$i1].n.f = 0.0;
//   end for;
//   C[1000].p.e = R[1000].n.e;
//   C[1000].p.f + R[1000].n.f = 0.0;
//   G.n.f = 0.0;
// end ArrayConnect2;
// endResult
