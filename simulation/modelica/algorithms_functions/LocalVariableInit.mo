function testFcn
  input Real r;
  output Real res;
protected
  Real coef = -42.0;
algorithm
  res := coef;
end testFcn;

model LocalVariableInit
  input Real ir;
  Real r = testFcn(ir);
end LocalVariableInit;
