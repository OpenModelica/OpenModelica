// name: inst4.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//
// FAILREASON: Invalid mix of extensions not checked.
//


type B
  Real x;
end B;

class MyReal
  extends Real;
  extends B;
end MyReal;

model A
  MyReal r;
end A;

// Result:
//
// EXPANDED FORM:
//
// class A
//   Real r;
// end A;
//
//
// Found 1 components and 0 parameters.
// class A
//   final parameter String r.unit = "";
//   final parameter String r.quantity = "";
//   final parameter String r.displayUnit = "";
//   final parameter Real r.min = 0.0;
//   final parameter Real r.max = 0.0;
//   final parameter Real r.start = 0.0;
//   final parameter Boolean r.fixed = false;
//   final parameter Real r.nominal;
//   final parameter enumeration(never, avoid, default, prefer, always) r.stateSelect = StateSelect.default;
//   final parameter enumeration(given, sought, refine) r.uncertain = Uncertainty.given;
//   Real r.x;
// end A;
// endResult
