// status: correct
// cflags: +t
// From bug #2376
// Note the usage of +t to verify that the expression internally has the correct types set.
//   It is not supposed to be Real[2] or Real[3] in the scalar expressions.

model M
  parameter Real th = 0;
  parameter Integer NVd = 2;
  Real h[NVd+1];
equation
  ones(NVd) = cos(th)*h[1:end-1];
end M;

// Result:
// class M
//   parameter Real th = 0.0;
//   parameter Integer NVd = 2;
//   Real h[1];
//   Real h[2];
//   Real h[3];
// equation
//   1.0 = /*Real*/ h[1] * /*Real*/ cos(/*Real*/ th);
//   1.0 = /*Real*/ h[2] * /*Real*/ cos(/*Real*/ th);
// end M;
// endResult
