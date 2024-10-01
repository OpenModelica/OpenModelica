// name: RecordBinding12
// keywords:
// status: correct
//

record BaseR
  parameter E e;
  parameter Real m = 1;
  parameter Integer N = 1;
  parameter Real[N] H = {0};
end BaseR;

record R
  extends BaseR(
    e = E.a,
    m = 1 + sum({H[k] for k in 1:N}),
    N = 4,
    H = {1, 2, 3, 4});
end R;

type E = enumeration(a, b, c);

model M
  parameter BaseR material;
equation
  if material.e == E.b then
  end if;
end M;

model RecordBinding12
  M m(material = R());
end RecordBinding12;

// Result:
// class RecordBinding12
//   final parameter enumeration(a, b, c) m.material.e = E.a;
//   parameter Real m.material.m = 11.0;
//   final parameter Integer m.material.N = 4;
//   parameter Real m.material.H[1] = 1.0;
//   parameter Real m.material.H[2] = 2.0;
//   parameter Real m.material.H[3] = 3.0;
//   parameter Real m.material.H[4] = 4.0;
// end RecordBinding12;
// endResult
