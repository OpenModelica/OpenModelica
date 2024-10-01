// name: ArrayConnect1
// keywords:
// status: correct
//

connector C
  Real e;
  flow Real f;
end C;

model A
  C p;
  C n;
end A;

model ArrayConnect1
  parameter Integer N = 10;
  A S, R[N], C[N], G;
equation
  connect(S.p, R[1].p);
  connect(S.n, G.p);
  for i in 1:N-1 loop
    connect(R[i].n, R[i+1].p);
  end for;
  for i in 1:N loop
    connect(C[i].p, R[i].n);
    connect(C[i].n, G.p);
  end for;
  annotation(__OpenModelica_commandLineOptions="-d=arrayConnect,-nfScalarize");
end ArrayConnect1;

// Result:
// class ArrayConnect1
//   final parameter Integer N = 10;
//   Real S.p.e;
//   Real S.p.f;
//   Real S.n.e;
//   Real S.n.f;
//   Real[10] R.p.e;
//   Real[10] R.p.f;
//   Real[10] R.n.e;
//   Real[10] R.n.f;
//   Real[10] C.p.e;
//   Real[10] C.p.f;
//   Real[10] C.n.e;
//   Real[10] C.n.f;
//   Real G.p.e;
//   Real G.p.f;
//   Real G.n.e;
//   Real G.n.f;
// equation
//   R[1].p.e = S.p.e;
//   S.p.f + R[1].p.f = 0.0;
//   G.p.e = S.n.e;
//   for $i1 in 1:10 loop
//     C[$i1].n.e = S.n.e;
//   end for;
//   S.n.f + sum(C[:].n.f) + G.p.f = 0.0;
//   for $i1 in 1:9 loop
//     C[$i1].p.e = R[$i1 + 1].p.e;
//   end for;
//   for $i1 in 1:9 loop
//     R[$i1].n.e = R[$i1 + 1].p.e;
//   end for;
//   for $i1 in 2:10 loop
//     R[$i1].p.f + R[$i1 - 1].n.f + C[$i1 - 1].p.f = 0.0;
//   end for;
//   C[10].p.e = R[10].n.e;
//   R[10].n.f + C[10].p.f = 0.0;
//   G.n.f = 0.0;
// end ArrayConnect1;
// endResult
