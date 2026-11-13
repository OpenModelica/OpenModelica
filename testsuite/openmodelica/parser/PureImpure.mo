// name: PureImpure.mo
// keywords: test pure/impure Modelica 3.3 keywords
// status: correct
//
// Test pure/impure keywords
//

pure function f
  input Boolean a;
  output Boolean b;
algorithm
  b := a;
end f;

impure function fimpure
  input Boolean a;
  output Boolean b;
algorithm
  b := a;
end fimpure;

function fdefaultpure
  input Boolean a;
  output Boolean b;
algorithm
  b := a;
end fdefaultpure;

model PureImpure
  parameter Boolean y = true;
  parameter Boolean x = f(y);
  parameter Boolean z = fimpure(y);
  parameter Boolean w = fdefaultpure(y);
end PureImpure;

// Result:
// function f
//   input Boolean a;
//   output Boolean b;
// algorithm
//   b := a;
// end f;
//
// function fdefaultpure
//   input Boolean a;
//   output Boolean b;
// algorithm
//   b := a;
// end fdefaultpure;
//
// impure function fimpure
//   input Boolean a;
//   output Boolean b;
// algorithm
//   b := a;
// end fimpure;
//
// class PureImpure
//   parameter Boolean y = true;
//   parameter Boolean x = f(y);
//   parameter Boolean z = fimpure(y);
//   parameter Boolean w = fdefaultpure(y);
// end PureImpure;
// endResult
