// name:     Modification7
// keywords: modification
// status:   correct
//
// This test checks that two modifications of subsubcomponents are both
// taken care of.
//

class Modification7
  class A
    Real x,y;
  end A;
  class B
    A a;
  end B;

  // This could be written as
  //   B b(a(x = 1.0, y = 2.0))
  // This tests whether it works in the following way too.
  B b(a.x = 1.0, a.y = 2.0);
end Modification7;

// Result:
// class Modification7
//   Real b.a.x = 1.0;
//   Real b.a.y = 2.0;
// end Modification7;
// [flattening/modelica/modification/Modification7.mo:11:5-11:13:writable] Warning: Components are deprecated in class.
// [flattening/modelica/modification/Modification7.mo:14:5-14:8:writable] Warning: Components are deprecated in class.
// [flattening/modelica/modification/Modification7.mo:20:3-20:28:writable] Warning: Components are deprecated in class.
//
// endResult
