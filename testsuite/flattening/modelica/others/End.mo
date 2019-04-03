// name: End
// status: correct

model End
  Integer p2 = 1;
  parameter Integer p = 3;
  Real vals[1,p];
algorithm
  vals[end,:] := ones(p);
  vals[end,end-end+1:2:end] := {0,0};
end End;

// Result:
// class End
//   Integer p2 = 1;
//   parameter Integer p = 3;
//   Real vals[1,1];
//   Real vals[1,2];
//   Real vals[1,3];
// algorithm
//   vals[1,:] := {1.0, 1.0, 1.0};
//   vals[1,{1, 3}] := {0.0, 0.0};
// end End;
// endResult
