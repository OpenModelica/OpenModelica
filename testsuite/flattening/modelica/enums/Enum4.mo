// name:     Enumeration4
// keywords: enumeration enum
// status:   correct
//
//
//

package M
  type Enum = enumeration(e1,e2,e3);
end M;

package N
  type Enum = enumeration(e3,e2,e1);
end N;

model Enumeration4
   parameter M.Enum em = M.Enum.e1;
   parameter N.Enum en = N.Enum.e3;
   M.Enum test;
equation
   test = if M.Enum.e1 == M.Enum.e3 then M.Enum.e2 else M.Enum.e1;
end Enumeration4;

// Result:
// class Enumeration4
//   parameter enumeration(e1, e2, e3) em = M.Enum.e1;
//   parameter enumeration(e3, e2, e1) en = N.Enum.e3;
//   enumeration(e1, e2, e3) test;
// equation
//   test = M.Enum.e1;
// end Enumeration4;
// endResult
