// name: CombineSubscripts2
// keywords:
// status: correct
//

record A
  Real[4] a;
end A;

model CombineSubscripts2
  A[3] b;
equation
  for i in 1:4 loop
    b[3].a[i] = 1;
  end for;

  for i in 1:4 loop
    b.a[i] = {1, 2, 3};
  end for;

  for i in 1:3 loop
    b[i].a = {1, 2, 3, 4};
  end for;
  annotation(__OpenModelica_commandLineOptions="-d=-nfScalarize,combineSubscripts");
end CombineSubscripts2;

// Result:
// class CombineSubscripts2
//   Real[3, 4] b.a;
// equation
//   for i in 1:4 loop
//     b.a[3,i] = 1.0;
//   end for;
//   for i in 1:4 loop
//     b.a[:,i] = {1.0, 2.0, 3.0};
//   end for;
//   for i in 1:3 loop
//     b.a[i,:] = {1.0, 2.0, 3.0, 4.0};
//   end for;
// end CombineSubscripts2;
// endResult
