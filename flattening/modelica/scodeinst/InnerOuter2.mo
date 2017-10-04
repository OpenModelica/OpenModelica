// name: InnerOuter2
// keywords:
// status: correct
// cflags: -d=newInst
//
// inner/outer example from the specification.
//

class A
  class B
    class C
      class D
        outer Real TI;
      end D;

      Real TI;
      D d;
    end C;

    Real TI;
    C c;
  end B;

  outer Real TI;
  B b;
end A;

class E
  class F
    class G
      class H
        A a;
      end H;

      Real TI;
      H h;
    end G;

    inner Real TI;
    G g;
  end F;

  inner Real TI;
  F f;
end E;

class I
  inner Real TI;
  E e;
  A a;
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
// [flattening/modelica/scodeinst/InnerOuter2.mo:13:9-13:22:writable] Notification: From here:
// [flattening/modelica/scodeinst/InnerOuter2.mo:16:7-16:14:writable] Warning: Ignoring non-inner TI when looking for inner.
// [flattening/modelica/scodeinst/InnerOuter2.mo:13:9-13:22:writable] Notification: From here:
// [flattening/modelica/scodeinst/InnerOuter2.mo:20:5-20:12:writable] Warning: Ignoring non-inner TI when looking for inner.
// [flattening/modelica/scodeinst/InnerOuter2.mo:13:9-13:22:writable] Notification: From here:
// [flattening/modelica/scodeinst/InnerOuter2.mo:24:3-24:16:writable] Warning: Ignoring non-inner TI when looking for inner.
// [flattening/modelica/scodeinst/InnerOuter2.mo:24:3-24:16:writable] Notification: From here:
// [flattening/modelica/scodeinst/InnerOuter2.mo:35:7-35:14:writable] Warning: Ignoring non-inner TI when looking for inner.
// [flattening/modelica/scodeinst/InnerOuter2.mo:13:9-13:22:writable] Notification: From here:
// [flattening/modelica/scodeinst/InnerOuter2.mo:16:7-16:14:writable] Warning: Ignoring non-inner TI when looking for inner.
// [flattening/modelica/scodeinst/InnerOuter2.mo:13:9-13:22:writable] Notification: From here:
// [flattening/modelica/scodeinst/InnerOuter2.mo:20:5-20:12:writable] Warning: Ignoring non-inner TI when looking for inner.
// [flattening/modelica/scodeinst/InnerOuter2.mo:13:9-13:22:writable] Notification: From here:
// [flattening/modelica/scodeinst/InnerOuter2.mo:24:3-24:16:writable] Warning: Ignoring non-inner TI when looking for inner.
// [flattening/modelica/scodeinst/InnerOuter2.mo:13:9-13:22:writable] Notification: From here:
// [flattening/modelica/scodeinst/InnerOuter2.mo:35:7-35:14:writable] Warning: Ignoring non-inner TI when looking for inner.
//
// endResult
