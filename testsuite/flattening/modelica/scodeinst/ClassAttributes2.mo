// name: ClassAttributes2
// keywords:
// status: correct
//

model ClassAttributes2
  type InputReal = input Real;
  type ConstantInputReal = constant InputReal;
  ConstantInputReal x = 1;
end ClassAttributes2;

// Result:
// class ClassAttributes2
//   constant input Real x = 1.0;
// end ClassAttributes2;
// endResult
