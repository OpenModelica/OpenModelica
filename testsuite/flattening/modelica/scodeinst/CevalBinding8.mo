// name: CevalBinding8
// status: correct
//
//

record Orientation
  Real[3, 3] T;
  Real[3] w;
end Orientation;

function from_nxy
  input Real[3] n_x(each final unit = "1");
  input Real[3] n_y(each final unit = "1");
  output Orientation R;
protected
  Real abs_n_x = sqrt(n_x * n_x);
  Real[3] e_x(each final unit = "1") = if abs_n_x < 1.e-10 then {1, 0, 0} else n_x / abs_n_x;
  Real[3] n_z_aux(each final unit = "1") = cross(e_x, n_y);
  Real[3] n_y_aux(each final unit = "1") = if n_z_aux * n_z_aux > 1.0e-6 then n_y else if abs(e_x[1]) > 1.0e-6 then {0, 1, 0} else {1, 0, 0};
  Real[3] e_z_aux(each final unit = "1") = cross(e_x, n_y_aux);
  Real[3] e_z(each final unit = "1") = e_z_aux / sqrt(e_z_aux * e_z_aux);
algorithm
  R := Orientation(T = {e_x, cross(e_z, e_x), e_z}, w = zeros(3));
end from_nxy;

model BodyCylinder
  parameter Real[3] r(start = {0.1, 0, 0});
  final parameter Orientation R = from_nxy(r, {0, 1, 0});
end BodyCylinder;

model Pendulum
  parameter Real L;
  parameter Real d = 0.01;
  BodyCylinder string(r = {0, L, 0});
end Pendulum;

model CevalBinding8
  parameter Integer n = 3;
  parameter Real T = 54;
  parameter Real X = 30;
  parameter Real[n] lengths = {(T / (2 * (X + n - i))) ^ 2 for i in 1:n};
  Pendulum[n] pendulum(L = lengths);
end CevalBinding8;

// Result:
// class CevalBinding8
//   final parameter Integer n = 3;
//   parameter Real T = 54.0;
//   parameter Real X = 30.0;
//   parameter Real lengths[1] = (T / (2.0 * (X + 3.0 - 1.0))) ^ 2.0;
//   parameter Real lengths[2] = (T / (2.0 * (X + 3.0 - 2.0))) ^ 2.0;
//   parameter Real lengths[3] = (T / (2.0 * (X + 3.0 - 3.0))) ^ 2.0;
//   parameter Real pendulum[1].L = lengths[1];
//   parameter Real pendulum[1].d = 0.01;
//   parameter Real pendulum[1].string.r[1](start = 0.1) = 0.0;
//   parameter Real pendulum[1].string.r[2](start = 0.0) = pendulum[1].L;
//   parameter Real pendulum[1].string.r[3](start = 0.0) = 0.0;
//   final parameter Real pendulum[1].string.R.T[1,1] = 0.0;
//   final parameter Real pendulum[1].string.R.T[1,2] = 1.0;
//   final parameter Real pendulum[1].string.R.T[1,3] = 0.0;
//   final parameter Real pendulum[1].string.R.T[2,1] = 1.0;
//   final parameter Real pendulum[1].string.R.T[2,2] = -0.0;
//   final parameter Real pendulum[1].string.R.T[2,3] = 0.0;
//   final parameter Real pendulum[1].string.R.T[3,1] = 0.0;
//   final parameter Real pendulum[1].string.R.T[3,2] = 0.0;
//   final parameter Real pendulum[1].string.R.T[3,3] = -1.0;
//   final parameter Real pendulum[1].string.R.w[1] = 0.0;
//   final parameter Real pendulum[1].string.R.w[2] = 0.0;
//   final parameter Real pendulum[1].string.R.w[3] = 0.0;
//   parameter Real pendulum[2].L = 0.7585848074921956;
//   parameter Real pendulum[2].d = 0.01;
//   parameter Real pendulum[2].string.r[1](start = 0.1) = 0.0;
//   parameter Real pendulum[2].string.r[2](start = 0.0) = 0.7585848074921956;
//   parameter Real pendulum[2].string.r[3](start = 0.0) = 0.0;
//   final parameter Real pendulum[2].string.R.T[1,1] = 0.0;
//   final parameter Real pendulum[2].string.R.T[1,2] = 1.0;
//   final parameter Real pendulum[2].string.R.T[1,3] = 0.0;
//   final parameter Real pendulum[2].string.R.T[2,1] = 1.0;
//   final parameter Real pendulum[2].string.R.T[2,2] = -0.0;
//   final parameter Real pendulum[2].string.R.T[2,3] = 0.0;
//   final parameter Real pendulum[2].string.R.T[3,1] = 0.0;
//   final parameter Real pendulum[2].string.R.T[3,2] = 0.0;
//   final parameter Real pendulum[2].string.R.T[3,3] = -1.0;
//   final parameter Real pendulum[2].string.R.w[1] = 0.0;
//   final parameter Real pendulum[2].string.R.w[2] = 0.0;
//   final parameter Real pendulum[2].string.R.w[3] = 0.0;
//   parameter Real pendulum[3].L = 0.81;
//   parameter Real pendulum[3].d = 0.01;
//   parameter Real pendulum[3].string.r[1](start = 0.1) = 0.0;
//   parameter Real pendulum[3].string.r[2](start = 0.0) = 0.81;
//   parameter Real pendulum[3].string.r[3](start = 0.0) = 0.0;
//   final parameter Real pendulum[3].string.R.T[1,1] = 0.0;
//   final parameter Real pendulum[3].string.R.T[1,2] = 1.0;
//   final parameter Real pendulum[3].string.R.T[1,3] = 0.0;
//   final parameter Real pendulum[3].string.R.T[2,1] = 1.0;
//   final parameter Real pendulum[3].string.R.T[2,2] = -0.0;
//   final parameter Real pendulum[3].string.R.T[2,3] = 0.0;
//   final parameter Real pendulum[3].string.R.T[3,1] = 0.0;
//   final parameter Real pendulum[3].string.R.T[3,2] = 0.0;
//   final parameter Real pendulum[3].string.R.T[3,3] = -1.0;
//   final parameter Real pendulum[3].string.R.w[1] = 0.0;
//   final parameter Real pendulum[3].string.R.w[2] = 0.0;
//   final parameter Real pendulum[3].string.R.w[3] = 0.0;
// end CevalBinding8;
// endResult
