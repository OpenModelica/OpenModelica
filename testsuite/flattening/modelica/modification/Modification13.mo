// name:     Modification13
// keywords: modification, attributes, arrays
// status:   correct
//
//

class Modification12
  Real x[:] (min = fill(1,size(x,1))) = {1.0,2.0};
end Modification12;

class Modification13
  Modification12 a(x={1.0,2.0,4.0});
end Modification13;


// Result:
// class Modification13
//   Real a.x[1](min = 1.0);
//   Real a.x[2](min = 1.0);
//   Real a.x[3](min = 1.0);
// equation
//   a.x = {1.0, 2.0, 4.0};
// end Modification13;
// [flattening/modelica/modification/Modification13.mo:8:3-8:50:writable] Warning: Components are deprecated in class.
// [flattening/modelica/modification/Modification13.mo:12:3-12:36:writable] Warning: Components are deprecated in class.
//
// endResult
