// name: FuncBuiltinGetInstanceName
// keywords: getInstanceName
// status: correct
// cflags: -d=newInst
//
// Tests the builtin getInstanceName operator.
//

package P
  constant String s = getInstanceName();
  constant A a;
end P;

model A
  model B
    String s = getInstanceName();
  end B;

  B b;
  String s = getInstanceName();
end A;

model C
  extends A;
end C;

model FuncBuiltinGetInstanceName
  function f
    output String s = getInstanceName();
  end f;

  function f2
    input Real dummy;
  algorithm
    assert(true, getInstanceName());
  end f2;

  String s = getInstanceName();
  A a;
  A a1[2];
  C c;
  C c2[1, 2];
  String ps = P.s;
  String pas = P.a.s;
  constant String fs = f();
  Real rs(displayUnit = getInstanceName());
equation
  f2(time);
end FuncBuiltinGetInstanceName;

// Result:
// function FuncBuiltinGetInstanceName.f2
//   input Real dummy;
// algorithm
//   assert(true, "FuncBuiltinGetInstanceName.f2");
// end FuncBuiltinGetInstanceName.f2;
//
// class FuncBuiltinGetInstanceName
//   String s = "FuncBuiltinGetInstanceName";
//   String a.b.s = "FuncBuiltinGetInstanceName.a.b";
//   String a.s = "FuncBuiltinGetInstanceName.a";
//   String a1[1].b.s = "FuncBuiltinGetInstanceName.a1[1].b";
//   String a1[1].s = "FuncBuiltinGetInstanceName.a1[1]";
//   String a1[2].b.s = "FuncBuiltinGetInstanceName.a1[2].b";
//   String a1[2].s = "FuncBuiltinGetInstanceName.a1[2]";
//   String c.b.s = "FuncBuiltinGetInstanceName.c.b";
//   String c.s = "FuncBuiltinGetInstanceName.c";
//   String c2[1,1].b.s = "FuncBuiltinGetInstanceName.c2[1, 1].b";
//   String c2[1,1].s = "FuncBuiltinGetInstanceName.c2[1, 1]";
//   String c2[1,2].b.s = "FuncBuiltinGetInstanceName.c2[1, 2].b";
//   String c2[1,2].s = "FuncBuiltinGetInstanceName.c2[1, 2]";
//   String ps = "P";
//   String pas = "P.a";
//   constant String fs = "FuncBuiltinGetInstanceName.f";
//   Real rs(displayUnit = "FuncBuiltinGetInstanceName");
// equation
//   FuncBuiltinGetInstanceName.f2(time);
// end FuncBuiltinGetInstanceName;
// endResult
