// name: RedeclareConnectorType1
// keywords:
// status: correct
//

connector C
  Real e;
  replaceable Real f;
end C;

model RedeclareConnectorType1
  C c(redeclare flow Real f);
end RedeclareConnectorType1;

// Result:
// class RedeclareConnectorType1
//   Real c.e;
//   Real c.f;
// equation
//   c.f = 0.0;
// end RedeclareConnectorType1;
// endResult
