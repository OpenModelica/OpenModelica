// name:     RecordFuncParam
// keywords: record function
// status:   correct
//
// Tests records as input arguments to functions in a simulation context.
// Fix for bug #1215: http://openmodelica.ida.liu.se:8080/cb/issue/1215
//

record R
  Real x;
  Real y;
end R;

function f
  input R r;
  output Real y;
end f;

model RecordFuncParam
  input R r;
  output Real y;
equation
  r.x = time;
  r.y = r.x * 2;
  y = f(r);
end RecordFuncParam;

// Result:
// function R "Automatically generated record constructor for R"
//   input Real x;
//   input Real y;
//   output R res;
// end R;
//
// function f
//   input R r;
//   output Real y;
// end f;
//
// class RecordFuncParam
//   input Real r.x;
//   input Real r.y;
//   output Real y;
// equation
//   r.x = time;
//   r.y = 2.0 * r.x;
//   y = f(r);
// end RecordFuncParam;
// endResult
