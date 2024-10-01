// name: ClassRestriction1
// keywords:
// status: correct
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
// [flattening/modelica/declarations/ClassRestriction1.mo:7:3-7:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/declarations/ClassRestriction1.mo:9:3-9:8:writable] Warning: Equation sections are deprecated in class.
// [flattening/modelica/declarations/ClassRestriction1.mo:11:3-11:9:writable] Warning: Algorithm sections are deprecated in class.
//
// endResult
