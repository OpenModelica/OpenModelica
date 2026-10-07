// name:     InnerOuter1
// keywords: dynamic scope, lookup
// status:   correct
//
//  components with inner prefix references an outer component with
//  the same name and one variable is generated for all of them.
//

class A
  outer Real T0;
end A;

class B
  inner Real T0=100;
  A a1, a2; // B.T0, B.a1.T0 and B.a2.T0 is the same variable
end B;

// Result:
// class B
//   Real T0 = 100.0;
// end B;
// [flattening/modelica/scoping/InnerOuter1.mo:10:3-10:16:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter1.mo:14:3-14:20:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter1.mo:15:3-15:11:writable] Warning: Components are deprecated in class.
//
// endResult
