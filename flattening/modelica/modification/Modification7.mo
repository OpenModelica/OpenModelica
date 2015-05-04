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
// endResult
