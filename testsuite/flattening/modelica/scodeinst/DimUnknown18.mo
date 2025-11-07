// name: DimUnknown18
// keywords:
// status: correct
//
//

record R
  parameter String names[:] = {""};
end R;

function f
  input R r;
  output String names[size(r.names, 1)];
algorithm
  names := r.names;
end f;

model DimUnknown18
  parameter R r = R(names = {"a", "b", "c"});
  parameter String names[:] = f(r);
end DimUnknown18;

// Result:
// function R "Automatically generated record constructor for R"
//   input String[:] names = {""};
//   output R res;
// end R;
//
// function f
//   input R r;
//   output String[size(r.names, 1)] names;
// algorithm
//   names := r.names;
// end f;
//
// class DimUnknown18
//   parameter String r.names[1] = "a";
//   parameter String r.names[2] = "b";
//   parameter String r.names[3] = "c";
//   parameter String[3] names = f(r);
// end DimUnknown18;
// endResult
