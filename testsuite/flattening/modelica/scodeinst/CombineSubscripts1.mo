// name: CombineSubscripts1
// keywords:
// status: correct
//

model B
  Real[10] c;
end B;

model CombineSubscripts1
  B[100] b;
equation
  for i in 1:100 loop
    b[i].c[10] = 2;
  end for;
  annotation(__OpenModelica_commandLineOptions="-d=-nfScalarize,combineSubscripts");
end CombineSubscripts1;

// Result:
// class CombineSubscripts1
//   Real[100, 10] b.c;
// equation
//   for i in 1:100 loop
//     b.c[i,10] = 2.0;
//   end for;
// end CombineSubscripts1;
// endResult
