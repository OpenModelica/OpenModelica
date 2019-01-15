// name: OperationRelational1
// keywords: 
// status: correct
// cflags: -d=newInst
//

model OperationRelational1
  Real r1, r2;
  Integer i1, i2;
  String s1, s2;
  Boolean b1, b2;
  E e1, e2;
  type E = enumeration(one, two, three);
equation
  b1 = r1 < r2;
  b1 = r1 <= r2;
  b1 = r1 > r2;
  b1 = r1 >= r2;
  b1 = r1 == r2;
  b1 = r1 <> r2;
  b1 = i1 < i2;
  b1 = i1 <= i2;
  b1 = i1 > i2;
  b1 = i1 >= i2;
  b1 = i1 == i2;
  b1 = i1 <> i2;
  b1 = s1 < s2;
  b1 = s1 <= s2;
  b1 = s1 > s2;
  b1 = s1 >= s2;
  b1 = s1 == s2;
  b1 = s1 <> s2;
  b1 = b1 < b2;
  b1 = b1 <= b2;
  b1 = b1 > b2;
  b1 = b1 >= b2;
  b1 = b1 == b2;
  b1 = b1 <> b2;
  b1 = e1 < e2;
  b1 = e1 <= e2;
  b1 = e1 > e2;
  b1 = e1 >= e2;
  b1 = e1 == e2;
  b1 = e1 <> e2;
end OperationRelational1;

// Result:
// class OperationRelational1
//   Real r1;
//   Real r2;
//   Integer i1;
//   Integer i2;
//   String s1;
//   String s2;
//   Boolean b1;
//   Boolean b2;
//   enumeration(one, two, three) e1;
//   enumeration(one, two, three) e2;
// equation
//   b1 = r1 < r2;
//   b1 = r1 <= r2;
//   b1 = r1 > r2;
//   b1 = r1 >= r2;
//   b1 = r1 == r2;
//   b1 = r1 <> r2;
//   b1 = i1 < i2;
//   b1 = i1 <= i2;
//   b1 = i1 > i2;
//   b1 = i1 >= i2;
//   b1 = i1 == i2;
//   b1 = i1 <> i2;
//   b1 = s1 < s2;
//   b1 = s1 <= s2;
//   b1 = s1 > s2;
//   b1 = s1 >= s2;
//   b1 = s1 == s2;
//   b1 = s1 <> s2;
//   b1 = b1 < b2;
//   b1 = b1 <= b2;
//   b1 = b1 > b2;
//   b1 = b1 >= b2;
//   b1 = b1 == b2;
//   b1 = b1 <> b2;
//   b1 = e1 < e2;
//   b1 = e1 <= e2;
//   b1 = e1 > e2;
//   b1 = e1 >= e2;
//   b1 = e1 == e2;
//   b1 = e1 <> e2;
// end OperationRelational1;
// [flattening/modelica/scodeinst/OperationRelational1.mo:19:3-19:16:writable] Warning: In relation r1 == r2, == on Real numbers is only allowed inside functions.
// [flattening/modelica/scodeinst/OperationRelational1.mo:20:3-20:16:writable] Warning: In relation r1 <> r2, <> on Real numbers is only allowed inside functions.
//
// endResult
