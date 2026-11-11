// name: OperationRelational1
// keywords: 
// status: correct
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
  annotation(__OpenModelica_commandLineOptions="--allowNonStandardModelica=realEquality");
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
// endResult
