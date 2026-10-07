// name:     Enumeration3
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

model Enumeration3
   import M.Enum;
   parameter Enum em = Enum.e1;
   parameter N.Enum en = N.Enum.e3;
   Enum test;
equation
   test = if Enum.e1 == Enum.e3 then Enum.e2 else Enum.e1;
end Enumeration3;

// Result:
// class Enumeration3
//   parameter enumeration(e1, e2, e3) em = M.Enum.e1;
//   parameter enumeration(e3, e2, e1) en = N.Enum.e3;
//   enumeration(e1, e2, e3) test;
// equation
//   test = M.Enum.e1;
// end Enumeration3;
// endResult
