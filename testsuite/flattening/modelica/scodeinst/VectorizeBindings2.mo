// name: VectorizeBindings2
// keywords:
// status: correct
// cflags: -d=newInst,-nfScalarize,vectorizeBindings
//

model M1
  parameter Real p;
  Real x;
equation
  der(x) = 1;
end M1;

model M2
  M1 m1[10](each p = 2,
            x(each start = 1,
              each fixed = true));
  M1 m11[10,10](each p = 2);
end M2;

model M3
  M2 m2[3];
end M3;

// Result:
// class M3
//   parameter Real[3, 10, 10] m2.m11.p = fill(2.0, 3, 10, 10);
//   Real[3, 10, 10] m2.m11.x;
//   parameter Real[3, 10] m2.m1.p = fill(2.0, 3, 10);
//   Real[3, 10] m2.m1.x(start = fill(1.0, 3, 10), fixed = fill(true, 3, 10));
// equation
//   for $i1 in 1:3 loop
//     for $i1 in 1:10 loop
//       der(m2[$i1].m1[$i1].x) = 1.0;
//     end for;
//   end for;
//   for $i1 in 1:3 loop
//     for $i1 in 1:10 loop
//       for $i2 in 1:10 loop
//         der(m2[$i1].m11[$i2,$i1].x) = 1.0;
//       end for;
//     end for;
//   end for;
// end M3;
// endResult
