package test

type aaa = abc;

function RecordToRecord
  input abc i1;
  output abc o1;
algorithm
  o1 := i1;
end RecordToRecord;

package SimpleInner
  record InnerDummy
    type IntegerTwoDim = Integer[2,3];
    IntegerTwoDim[2] fourDim[1],threeDim;
  end InnerDummy;
end SimpleInner;

function AddOne
  input Integer i;
  output Real out;
  Integer one = 1;
algorithm
  out := i+one;
end AddOne;

function AddTwo
  input Integer i;
  output Integer out1;
  output Integer out2;
algorithm
  out1 := i+1;
  out2 := i+2;
end AddTwo;

record abc
  Integer a;
  Integer b;
  Real c;
end abc;

record def
  abc d;
  abc e;
  abc f;
end def;

type defRef = def;
type defRefRef = defRef;

end test;

package Simple2
record defgh
  extends test.defRefRef;
  Integer g = 13;
  Integer h = 4;
end defgh;

package Simple2Inner
record One
  Integer one;
end One;
end Simple2Inner;

record Two
  Integer two;
end Two;

record extendsTwo
  extends Simple2.Simple2Inner.One;
  extends Two;
end extendsTwo;

end Simple2;

function testEvil
  type evil = Integer;
  output evil out;
algorithm
  out := 1;
end testEvil;

function doubleArray
  input Real iarr[:];
  output Real out[size(iarr,1)];
algorithm
  out := 2*iarr;
end doubleArray;

