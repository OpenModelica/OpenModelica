// name: PrintRecordTypes1
// keywords:
// status: correct
//

record R1
  Real x;
  Real y;
end R1;

record R2
  R1 ra;
  R1 rb;
end R2;

model B
  R2 c[10];
end B;

model PrintRecordTypes1
  B[100] b;
equation
  for i in 1:100 loop
    b[i].c[10] = R2(R1(1, 0), R1(i,1));
    b[i].c[1].rb = R1(i,0);
  end for;
  annotation(__OpenModelica_commandLineOptions="-d=-nfScalarize,printRecordTypes");
end PrintRecordTypes1;

// Result:
// record R1
//   input Real x;
//   input Real y;
// end R1;
//
// record R2
//   input R1 ra;
//   input R1 rb;
// end R2;
//
// class PrintRecordTypes1
//   Real[100, 10] b.c.ra.x;
//   Real[100, 10] b.c.ra.y;
//   Real[100, 10] b.c.rb.x;
//   Real[100, 10] b.c.rb.y;
// equation
//   for i in 1:100 loop
//     b[i].c[10] = R2(R1(1.0, 0.0), R1(/*Real*/(i), 1.0));
//     b[i].c[1].rb = R1(/*Real*/(i), 0.0);
//   end for;
// end PrintRecordTypes1;
// endResult
