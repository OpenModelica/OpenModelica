// name:     Algorithm stucture test
// keywords: jacobian, algorithm
// status:   correct
//
// <insert description here>
//


model simple_test
  Real x;    // = time+1
  Real y;    // = e^x
  Real z1(start=1);    // = Int(y) = Int(e^x) = e^x
  Real z2(start=1);
  Real fac;
  Integer n(start=4);
algorithm
  y := 0;
  fac := 1;
  for i in 1:n loop
    fac := fac * i;
    y := y + (x^i)/fac;
  end for;
equation
 when sample(0,1) then
   n = pre(n) + 1;
 end when;
  x = z2;
  der(z1) = y;
  der(z2) = 1;
end simple_test;

// Result:
// class simple_test
//   Real x;
//   Real y;
//   Real z;
//   Real fac;
//   Real j;
//   parameter Integer n = 4;
// equation
//   x = 1.0 + time;
//   der(z) = y;
// algorithm
//   fac := 1.0;
//   for i in 0:n loop
//     j := Real(i);
//     if j > 0.0 then
//       fac := fac * j;
//     end if;
//     y := y + x ^ j / fac;
//   end for;
// end simple_test;
// endResult
