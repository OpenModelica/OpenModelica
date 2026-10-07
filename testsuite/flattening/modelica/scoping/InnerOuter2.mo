// name:     InnerOuter2
// keywords: dynamic scope, lookup
// status:   correct
//
//  components with inner prefix references an outer component with
//  the same name and one variable is generated for all of them.
//
class A
  outer Real TI;
  class B
    Real TI;
    class C
      Real TI;
      class D
  outer Real TI; //
      end D;
      D d;
    end C;
    C c;
  end B;
  B b;
end A;
class E
  inner Real TI;
  class F
    inner Real TI;
    class G
      Real TI;
      class H
  A a;
      end H;
      H h;
    end G;
    G g;
  end F;
  F f;
end E;
class I
  inner Real TI;
  E e;
  // e.f.g.h.a.TI, e.f.g.h.a.b.c.d.TI, and e.f.TI is the same variable
  // But e.f.TI, e.TI and TI are different variables
  A a; // a.TI, a.b.c.d.TI, and TI is the same variable
end I;

// Result:
// class I
//   Real TI;
//   Real e.TI;
//   Real e.f.TI;
//   Real e.f.g.TI;
//   Real e.f.g.h.a.b.TI;
//   Real e.f.g.h.a.b.c.TI;
//   Real a.b.TI;
//   Real a.b.c.TI;
// end I;
// [flattening/modelica/scoping/InnerOuter2.mo:15:3-15:16:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter2.mo:13:7-13:14:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter2.mo:17:7-17:10:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter2.mo:11:5-11:12:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter2.mo:19:5-19:8:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter2.mo:9:3-9:16:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter2.mo:21:3-21:6:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter2.mo:30:3-30:6:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter2.mo:28:7-28:14:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter2.mo:32:7-32:10:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter2.mo:26:5-26:18:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter2.mo:34:5-34:8:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter2.mo:24:3-24:16:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter2.mo:36:3-36:6:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter2.mo:15:3-15:16:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter2.mo:13:7-13:14:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter2.mo:17:7-17:10:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter2.mo:11:5-11:12:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter2.mo:19:5-19:8:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter2.mo:9:3-9:16:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter2.mo:21:3-21:6:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter2.mo:39:3-39:16:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter2.mo:40:3-40:6:writable] Warning: Components are deprecated in class.
// [flattening/modelica/scoping/InnerOuter2.mo:43:3-43:6:writable] Warning: Components are deprecated in class.
//
// endResult
