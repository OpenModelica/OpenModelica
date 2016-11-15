// name: dim14.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//
// FAILREASON: Not good enough error message.
//

model A
  Real x[:, :];
end A;

model B
  A a[2];
end B;

model C
  B b[4](each a(each x = 3.0));
end C;
