// name: CevalBinding5
// status: correct
//
// Simple test of component bindings.
//

model A
  parameter R2 r2;
  parameter Boolean b;
initial equation
  if b then
  end if;
end A;

record R
  parameter Real[:] x;
end R;

record R2
  parameter R r(x = {0, 0});
end R2;

model B
  parameter R2 r2;
protected
  final parameter Boolean b = abs(r2.r.x[1]) < 0;
  A eff(final b = b);
end B;

model CevalBinding5
  parameter R2[2] r2;
  B[2] b(r2 = r2);
end CevalBinding5;

// Result:
// class CevalBinding5
//   parameter Real r2[1].r.x[1] = 0.0;
//   parameter Real r2[1].r.x[2] = 0.0;
//   parameter Real r2[2].r.x[1] = 0.0;
//   parameter Real r2[2].r.x[2] = 0.0;
//   final parameter Real b[1].r2.r.x[1] = 0.0;
//   final parameter Real b[1].r2.r.x[2] = 0.0;
//   protected final parameter Boolean b[1].b = false;
//   protected parameter Real b[1].eff.r2.r.x[1] = 0.0;
//   protected parameter Real b[1].eff.r2.r.x[2] = 0.0;
//   protected final parameter Boolean b[1].eff.b = false;
//   final parameter Real b[2].r2.r.x[1] = 0.0;
//   final parameter Real b[2].r2.r.x[2] = 0.0;
//   protected final parameter Boolean b[2].b = false;
//   protected parameter Real b[2].eff.r2.r.x[1] = 0.0;
//   protected parameter Real b[2].eff.r2.r.x[2] = 0.0;
//   protected final parameter Boolean b[2].eff.b = false;
// end CevalBinding5;
// endResult
