// name: eq6.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//

package P
  model A
    Real x;
  equation
    x = i;
  end A;

  constant Integer i = 2;
end P;

model B
  P.A a[3];
end B;

// Result:
// class B
//   constant Integer P.i = 2;
//   Real a[1].x;
//   Real a[2].x;
//   Real a[3].x;
// equation
//   a[1].x = /*Real*/(P.i);
//   a[2].x = /*Real*/(P.i);
//   a[3].x = /*Real*/(P.i);
// end B;
// endResult
