package RecordTest

function mk_add1
  input Real a1;
  input Real a2;
  output ADD out;
algorithm
  out.a1 := a1;
  out.a2 := a2;
end mk_add1;

function mk_add2
  input Real a1;
  input Real a2;
  output ADD out;
algorithm
  out := ADD(a1,a2);
end mk_add2;

function mk_add3
  output ADD out;
algorithm
  out := ADD(1,2);
end mk_add3;

function mk_add_ext
  input Real a1;
  input Real a2;
  output ADD out;
  external "C" annotation(Library="External_C_RecordTest.o");
end mk_add_ext;

function eval_add
  input ADD add;
  output Real out;
algorithm
  out := add.a1 + add.a2;
end eval_add;

record ADD
  Real a1;
  Real a2;
end ADD;

function mk_plus1
  input ADD left;
  input ADD right;
  output PLUS out;
algorithm
  out := PLUS(left,right);
end mk_plus1;

function mk_plus2
  input ADD left;
  input ADD right;
  output PLUS out;
algorithm
  out.left := left;
  out.right := right;
end mk_plus2;

function mk_plus3
  input ADD left;
  input ADD right;
  output PLUS out;
algorithm
  out.left.a1 := left.a1;
  out.left.a2 := left.a2;
  out.right.a1 := right.a1;
  out.right.a2 := right.a2;
end mk_plus3;

function mk_plus4
  input Real la1;
  input Real la2;
  input Real ra1;
  input Real ra2;
  output PLUS out;
algorithm
  out.left.a1 := la1;
  out.left.a2 := la2;
  out.right.a1 := ra1;
  out.right.a2 := ra2;
end mk_plus4;

function mk_plus_ext
  input ADD left;
  input ADD right;
  output PLUS out;
  external "C" annotation(Library="External_C_RecordTest.o");
end mk_plus_ext;

function mk_plus_ext_explicit
  input ADD left;
  input ADD right;
  output PLUS out;
  external "C" out = mk_plus_ext(left, right) annotation(Library="External_C_RecordTest.o");
end mk_plus_ext_explicit;

function mk_plus_ext_by_reference
  input ADD left;
  input ADD right;
  output PLUS out;
  external "C" void_mk_plus_ext(out, left, right) annotation(Library="External_C_RecordTest.o");
end mk_plus_ext_by_reference;

function eval_plus
  input PLUS plus;
  output Real out;
algorithm
  out := plus.left.a1 + plus.left.a2 + plus.right.a1 + plus.right.a2;
end eval_plus;

function plus_ident
  input PLUS plus;
  output PLUS out;
algorithm
  out := plus;
end plus_ident;

record PLUS
  ADD left;
  ADD right;
end PLUS;

record MULT_PLUS
  PLUS plus1;
  PLUS plus2;
  PLUS plus3;
end MULT_PLUS;

function eval_mult
  input MULT_PLUS mult;
  output Real out;
algorithm
  out := eval_plus(mult.plus1) * eval_plus(mult.plus2) * eval_plus(mult.plus3);
end eval_mult;

function mk_empty1
  output EMPTY out;
algorithm
end mk_empty1;

function mk_empty2
  output EMPTY out;
algorithm
  out := EMPTY();
end mk_empty2;

function mk_empty_ext
  output EMPTY out;
  external "C" annotation(Library="External_C_RecordTest.o");
end mk_empty_ext;

function eval_empty
  input EMPTY in1;
  output Real out;
algorithm
  out := 0;
end eval_empty;

record EMPTY
end EMPTY;

record WithParameters
  Integer x = 5;
  parameter Integer y = 3;
  constant Integer z = 1;
end WithParameters;

function TestWithParameters
  parameter input Integer x(fixed=false);
  input Integer y;
  output WithParameters out1;
algorithm
  out1 := WithParameters(y,x);
end TestWithParameters;

function TestWithoutParameters
  output WithParameters out2;
algorithm
  out2 := WithParameters();
end TestWithoutParameters;

end RecordTest;
