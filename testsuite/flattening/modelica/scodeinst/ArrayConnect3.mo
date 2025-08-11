// name: ArrayConnect3
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

model Cell
  C l, r, u, d;
end Cell;

model ArrayConnect3
  parameter Integer N = 1000;
  parameter Integer M = 100;
  A S;
  Cell cells[N, M];
equation
  for i in 1:N-1, j in 1:M-1 loop
    connect(cells[i, j].r, cells[i, j+1].l);
    connect(cells[i, j].d, cells[i+1, j].u);
  end for;

  for i in 1:N loop
    connect(cells[i, M].r, cells[i, 1].l);
  end for;

  for j in 1:M loop
    connect(cells[1, j].u, S.p);
    connect(cells[N, j].d, S.n);
  end for;
  annotation(__OpenModelica_commandLineOptions="-d=arrayConnect,-nfScalarize");
end ArrayConnect3;

// Result:
// class ArrayConnect3
//   final parameter Integer N = 1000;
//   final parameter Integer M = 100;
//   Real S.p.e;
//   Real S.p.f;
//   Real S.n.e;
//   Real S.n.f;
//   Real[1000, 100] cells.l.e;
//   Real[1000, 100] cells.l.f;
//   Real[1000, 100] cells.r.e;
//   Real[1000, 100] cells.r.f;
//   Real[1000, 100] cells.u.e;
//   Real[1000, 100] cells.u.f;
//   Real[1000, 100] cells.d.e;
//   Real[1000, 100] cells.d.f;
// equation
//   for $i0 in 1:999 loop
//     for $i1 in 1:99 loop
//       cells[$i0,$i1].d.e = cells[$i0 + 1,$i1].u.e;
//     end for;
//   end for;
//   for $i0 in 2:1000 loop
//     for $i1 in 1:99 loop
//       cells[$i0 - 1,$i1].d.f + cells[$i0,$i1].u.f = 0.0;
//     end for;
//   end for;
//   for $i0 in 1:999 loop
//     for $i1 in 1:99 loop
//       cells[$i0,$i1].r.e = cells[$i0,$i1 + 1].l.e;
//     end for;
//   end for;
//   for $i0 in 1:999 loop
//     for $i1 in 2:100 loop
//       cells[$i0,$i1 - 1].r.f + cells[$i0,$i1].l.f = 0.0;
//     end for;
//   end for;
//   for $i0 in 1:1000 loop
//     cells[$i0,100].r.e = cells[$i0,1].l.e;
//   end for;
//   for $i0 in 1:1000 loop
//     cells[$i0,100].r.f + cells[$i0,1].l.f = 0.0;
//   end for;
//   for $i1 in 1:100 loop
//     cells[1,$i1].u.e = S.p.e;
//   end for;
//   sum(cells[1,:].u.f) + S.p.f = 0.0;
//   for $i1 in 1:100 loop
//     cells[1000,$i1].d.e = S.n.e;
//   end for;
//   sum(cells[1000,:].d.f) + S.n.f = 0.0;
//   for $i1 in 2:100 loop
//     cells[1000,$i1].l.f = 0.0;
//   end for;
//   for $i1 in 1:99 loop
//     cells[1000,$i1].r.f = 0.0;
//   end for;
//   for $i0 in 2:1000 loop
//     cells[$i0,100].u.f = 0.0;
//   end for;
//   for $i0 in 1:999 loop
//     cells[$i0,100].d.f = 0.0;
//   end for;
// end ArrayConnect3;
// endResult
