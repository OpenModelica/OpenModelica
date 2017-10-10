// name: ClassAttributes1
// keywords:
// status: correct
// cflags: -d=newInst
//

model ClassAttributes1
  type InputReal = input Real;
  InputReal x;
end ClassAttributes1;

// Result:
// class ClassAttributes1
//   input Real x;
// end ClassAttributes1;
// endResult
