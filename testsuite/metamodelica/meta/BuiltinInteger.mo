package BuiltinInteger

function funcIntIntToInt
  input Integer i1;
  input Integer i2;
  output Integer outIntAdd;
  output Integer outIntSub;
  output Integer outIntMul;
  output Integer outIntDiv;
  output Integer outIntMod;
  output Integer outIntMax;
  output Integer outIntMin;
algorithm
  outIntAdd := intAdd(i1, i2);
  outIntSub := intSub(i1, i2);
  outIntMul := intMul(i1, i2);
  outIntDiv := intDiv(i1, i2);
  outIntMod := intMod(i1, i2);
  outIntMax := intMax(i1, i2);
  outIntMin := intMin(i1, i2);
end funcIntIntToInt;

function funcIntegerRelations
  input Integer i1;
  input Integer i2;
  output Boolean outIntLt;
  output Boolean outIntLe;
  output Boolean outIntEq;
  output Boolean outIntNe;
  output Boolean outIntGe;
  output Boolean outIntGt;
algorithm
  outIntLt := intLt(i1, i2);
  outIntLe := intLe(i1, i2);
  outIntEq := intEq(i1, i2);
  outIntNe := intNe(i1, i2);
  outIntGe := intGe(i1, i2);
  outIntGt := intGt(i1, i2);
end funcIntegerRelations;

function func
  input Integer i;
  output Integer outIntAbs;
  output Integer outIntNeg;
  output Real outIntReal;
  output String outIntString;
algorithm
  outIntAbs := intAbs(i);
  outIntNeg := intNeg(i);
  outIntReal := intReal(i);
  outIntString := intString(i);
end func;

end BuiltinInteger;
