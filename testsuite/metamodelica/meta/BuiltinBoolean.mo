package BuiltinBoolean

function func
  input Boolean b1;
  input Boolean b2;
  output Boolean outBoolAnd;
  output Boolean outBoolOr;
  output Boolean outBoolNot;
algorithm
  outBoolAnd := boolAnd(b1,b2);
  outBoolOr := boolOr(b1,b2);
  outBoolNot := boolNot(b1);
end func;

end BuiltinBoolean;
