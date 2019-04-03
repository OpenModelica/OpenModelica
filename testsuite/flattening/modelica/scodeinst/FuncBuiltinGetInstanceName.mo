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

  String s = getInstanceName();
  A a;
  C c;
  String ps = P.s;
  String pas = P.a.s;
  constant String fs = f();
  Real rs(displayUnit = getInstanceName());
end FuncBuiltinGetInstanceName;

// Result:
// class FuncBuiltinGetInstanceName
//   String s = "FuncBuiltinGetInstanceName";
//   String a.b.s = "FuncBuiltinGetInstanceName.a.b";
//   String a.s = "FuncBuiltinGetInstanceName.a";
//   String c.b.s = "FuncBuiltinGetInstanceName.c.b";
//   String c.s = "FuncBuiltinGetInstanceName.c";
//   String ps = "P";
//   String pas = "P.a";
//   constant String fs = "FuncBuiltinGetInstanceName.f";
//   Real rs(displayUnit = "FuncBuiltinGetInstanceName");
// end FuncBuiltinGetInstanceName;
// endResult
