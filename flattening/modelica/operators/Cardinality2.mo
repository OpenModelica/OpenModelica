// name:     Cardinality2
// keywords: cardinality vectorization
// status:   correct
//
// Testing vectorization of the cardinality operator.
//

model Cardinality2
  connector C = input Real;

  C c[2];
  Integer i[2];
equation
  i = cardinality(c);
end Cardinality2;

// Result:
// class Cardinality2
//   input Real c[1];
//   input Real c[2];
//   Integer i[1];
//   Integer i[2];
// equation
//   i[1] = 0;
//   i[2] = 0;
// end Cardinality2;
// endResult
