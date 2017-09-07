// name: const15.mo
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model A
  model B
    constant Integer i = 3;
  end B;
end A;

model C
  extends A(B(i = 4));
  Real x = B.i;
end C;

// Result:
// class C
//   Real x = /*Real*/(B.i);
// end C;
// endResult
