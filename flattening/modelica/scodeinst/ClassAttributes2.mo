// name: ClassAttributes2
// keywords:
// status: correct
// cflags: -d=newInst
//

model ClassAttributes2
  type InputReal = input Real;
  type ConstantInputReal = constant InputReal;
  ConstantInputReal x;
end ClassAttributes2;

// Result:
// class ClassAttributes2
//   constant input Real x;
// end ClassAttributes2;
// endResult
