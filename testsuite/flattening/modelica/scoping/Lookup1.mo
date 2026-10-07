// name:     Lookup1
// keywords: scoping
// status:   correct
//
// Names are looked up in a partially defined class.
//

class Lookup1
  constant Real a = 3.0;
  class B
    Real c = a;
  end B;
  B b;
end Lookup1;


// Result:
// class Lookup1
//   constant Real a = 3.0;
//   Real b.c = 3.0;
// end Lookup1;
// [flattening/modelica/scoping/Lookup1.mo:11:5-11:15:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/Lookup1.mo:9:3-9:24:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/Lookup1.mo:13:3-13:6:writable] Warning: Components are deprecated in class.
//
// endResult
