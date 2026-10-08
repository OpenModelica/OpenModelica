// name: IfExpression19
// keywords:
// status: correct
//

function normalize
  input Real v[:];
  output Real result[size(v, 1)] = v;
algorithm
  result := smooth(0, if sqrt(v*v) >= 0 then v/sqrt(v*v) else v);
end normalize;

function from_nxy
  input Real n_x[3];
  input Real n_y[3];
  output Orientation T;
algorithm
  T := {n_x, normalize(n_x), n_y};
end from_nxy;

type Orientation = Real[3, 3];

model IfExpression19
  Real n_x[3] = {1, 0, 0};
  Real n_y[3] = {0, 1, 0};
  Orientation R_rel = from_nxy(n_x, n_y);
end IfExpression19;

// Result:
// function from_nxy
//   input Real[3] n_x;
//   input Real[3] n_y;
//   output Real[3, 3] T;
// algorithm
//   T := {n_x, normalize(n_x), n_y};
// end from_nxy;
//
// function normalize
//   input Real[:] v;
//   output Real[size(v, 1)] result = v;
// algorithm
//   result := smooth(0, if sqrt(v * v) >= 0.0 then v / sqrt(v * v) else v);
// end normalize;
//
// class IfExpression19
//   Real n_x[1];
//   Real n_x[2];
//   Real n_x[3];
//   Real n_y[1];
//   Real n_y[2];
//   Real n_y[3];
//   Real R_rel[1,1];
//   Real R_rel[1,2];
//   Real R_rel[1,3];
//   Real R_rel[2,1];
//   Real R_rel[2,2];
//   Real R_rel[2,3];
//   Real R_rel[3,1];
//   Real R_rel[3,2];
//   Real R_rel[3,3];
// equation
//   n_x = {1.0, 0.0, 0.0};
//   n_y = {0.0, 1.0, 0.0};
//   R_rel = from_nxy(n_x, n_y);
// end IfExpression19;
// endResult
