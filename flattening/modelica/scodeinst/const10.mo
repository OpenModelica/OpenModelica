// name: const10.mo
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  constant Integer i = 3;

  model B
    constant Integer j = i;
    Real x = j;
  end B;
end A;

model C
  A.B b;
end C;

// Result:
// class C
//   constant Integer b.j = 3;
//   Real b.x = 3.0;
// end C;
// endResult
