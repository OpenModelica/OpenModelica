// name: ClassRestriction1
// keywords:
// status: correct
// cflags: -d=newInst
//

class ClassRestriction1
  Real x;
equation
  x = 0;
algorithm
  x := 0;
end ClassRestriction1;

// Result:
// class ClassRestriction1
//   Real x;
// equation
//   x = 0.0;
// algorithm
//   x := 0.0;
// end ClassRestriction1;
// [flattening/modelica/declarations/ClassRestriction1.mo:8:3-8:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/declarations/ClassRestriction1.mo:10:3-10:8:writable] Warning: Equation sections are deprecated in class.
// [flattening/modelica/declarations/ClassRestriction1.mo:12:3-12:9:writable] Warning: Algorithm sections are deprecated in class.
//
// endResult
