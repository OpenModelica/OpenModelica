// name:     Ticket5249.mo
// keywords: tests if array binding works fine
// status:   correct
//
// cflags:   -d=newInst
//

model M

  record X
    Real a;
	Real b;
  end X;
  constant Integer n = 2;
  X x[n] = {X(1, 2), X(2, 3)};
  
  model H
    X x;
  end H;
  
  H h[n](x = x);
end M;

// Result:
// class M
//   constant Integer n = 2;
//   Real x[1].a = 1.0;
//   Real x[1].b = 2.0;
//   Real x[2].a = 2.0;
//   Real x[2].b = 3.0;
//   Real h[1].x.a = x[1].a;
//   Real h[1].x.b = x[1].b;
//   Real h[2].x.a = x[2].a;
//   Real h[2].x.b = x[2].b;
// end M;
// endResult
