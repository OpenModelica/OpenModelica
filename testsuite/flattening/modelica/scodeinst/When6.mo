// name: When6
// keywords:
// status: correct
// cflags:   -d=newInst
//
//

model When6
  Real a, b, c, d, e, f;
equation
  when time > 0 then
    a = 1;
    b = 2;
    c = 3;
    d = 4;
    e = 5;
    f = 6;
  elsewhen time > 1 then
    c = 1;
    e = 2;
    a = 3;
    b = 4;
    f = 5;
    d = 6;
  end when;
end When6;

// Result:
// class When6
//   Real a;
//   Real b;
//   Real c;
//   Real d;
//   Real e;
//   Real f;
// equation
//   when time > 0.0 then
//     a = 1.0;
//     b = 2.0;
//     c = 3.0;
//     d = 4.0;
//     e = 5.0;
//     f = 6.0;
//   elsewhen time > 1.0 then
//     c = 1.0;
//     e = 2.0;
//     a = 3.0;
//     b = 4.0;
//     f = 5.0;
//     d = 6.0;
//   end when;
// end When6;
// endResult
