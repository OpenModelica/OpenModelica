package BuiltinReal

function funcRealRealToReal
  input Real r1;
  input Real r2;
  output Real outAdd;
  output Real outSub;
  output Real outMul;
  output Real outDiv;
  output Real outMod;
  output Real outPow;
  output Real outMax;
  output Real outMin;
algorithm
  outAdd := realAdd(r1,r2);
  outSub := realSub(r1,r2);
  outMul := realMul(r1,r2);
  outDiv := realDiv(r1,r2);
  outMod := realMod(r1,r2);
  outPow := realPow(r1,r2);
  outMax := realMax(r1,r2);
  outMin := realMin(r1,r2);
end funcRealRealToReal;

function funcRealTransform
  input Real r;
  output Real outRealAbs;
  output Real outRealNeg;
algorithm
  outRealAbs := realAbs(r);
  outRealNeg := realNeg(r);
end funcRealTransform;

function funcRealRelations
  input Real r1;
  input Real r2;
  output Boolean outRealLt;
  output Boolean outRealLe;
  output Boolean outRealEq;
  output Boolean outRealNe;
  output Boolean outRealGe;
  output Boolean outRealGt;
algorithm
  outRealLt := realLt(r1, r2);
  outRealLe := realLe(r1, r2);
  outRealEq := realEq(r1, r2);
  outRealNe := realNe(r1, r2);
  outRealGe := realGe(r1, r2);
  outRealGt := realGt(r1, r2);
end funcRealRelations;

function funcRealString
  input Real r;
  output String s;
algorithm
  s := realString(r);
end funcRealString;

function funcRealInt
  input Real r;
  output Integer i;
algorithm
  i := realInt(r);
end funcRealInt;

end BuiltinReal;
