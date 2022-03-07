// name: NoScalarize2
// keywords:
// status: correct
// cflags: -d=newInst,-nfScalarize --noSimplify
//

model NoScalarize2
  model M
    Real p;
  end M;

  model Q
    M m[2];
  end Q;

  M m[2](each p = 2);
  Q q[3](m(each p = 2));
end NoScalarize2;

// Result:
// class NoScalarize2
//   Real[2] m.p = fill(2.0, 2);
//   Real[3, 2] q.m.p = fill(2.0, 3, 2);
// end NoScalarize2;
// endResult
