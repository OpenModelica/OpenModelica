// name: RedeclareConnectorType2
// keywords:
// status: correct
//

connector C
  Real e;
  replaceable flow Real f;
end C;

model RedeclareConnectorType2
  C c(redeclare Real f);
end RedeclareConnectorType2;

// Result:
// class RedeclareConnectorType2
//   Real c.e;
//   Real c.f;
// equation
//   c.f = 0.0;
// end RedeclareConnectorType2;
// endResult
