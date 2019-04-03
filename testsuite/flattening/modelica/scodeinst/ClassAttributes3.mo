// name: ClassAttributes3
// keywords:
// status: correct
// cflags: -d=newInst
//

model ClassAttributes3
  type InputReal = input Real;
  input InputReal x;
end ClassAttributes3;

// Result:
// class ClassAttributes3
//   input Real x;
// end ClassAttributes3;
// endResult
