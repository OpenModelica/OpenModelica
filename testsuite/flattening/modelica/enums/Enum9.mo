// name:     Enumeration9
// keywords: enumeration enum Integer
// status:   correct
//
//
//

type ABC = enumeration(a,b,c);

model EnumTest
   Integer a;
equation
   a = Integer(ABC.b);
end EnumTest;


// Result:
// class EnumTest
//   Integer a;
// equation
//   a = 2;
// end EnumTest;
// endResult
