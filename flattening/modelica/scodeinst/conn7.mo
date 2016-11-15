// name: conn7.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Connects not handled yet.
//

model A
  model B
    connector InReal = input Real;
    connector OutReal = output Real;
    parameter Integer p = 3;
    InReal x[p];
    OutReal y[p+1];
  end B;

  B b1[3], b2[3];
equation
  //connect(b1[1:3].x[1:3], b2[1:3].y[1:3]);
  b1[1:3].x[1:3] = b2[1:3].y[1:3];
end A;
