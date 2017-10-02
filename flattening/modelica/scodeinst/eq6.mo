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
//   Real a[1].x;
//   Real a[2].x;
//   Real a[3].x;
// equation
//   a[1].x = /*Real*/(P[1].i);
//   a[2].x = /*Real*/(P[2].i);
//   a[3].x = /*Real*/(P[3].i);
// end B;
// endResult
