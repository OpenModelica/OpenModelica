// name:     PartialFn4
// keywords: PartialFn
// status:  correct
// cflags: -g=MetaModelica -d=gen
//
// Using function pointers to non-returning functions
//

model PartialFn4

function VoidOp
  input Integer i;
protected
  Integer j;
algorithm
  j := i + 1;
end VoidOp;

function ApplyVoidOp

  input FuncIntegerToVoid inFunc;
  input Integer i;
  output Integer j;

  partial function FuncIntegerToVoid
    input Integer i1;
  end FuncIntegerToVoid;

algorithm
  inFunc(i);
  j := 2;
end ApplyVoidOp;

function TestApplyVoidOp

  input Integer i;
  output Integer j;

algorithm
  j := ApplyVoidOp(VoidOp, i);
end TestApplyVoidOp;

constant Integer i1=1;
Integer i2=TestApplyVoidOp(i1);
end PartialFn4;

// Result:
// function PartialFn4.ApplyVoidOp
//   input inFunc<function>(#Integer i1) => #T_NORETCALL# inFunc;
//   input Integer i;
//   output Integer j;
// algorithm
//   inFunc(#(i));
//   j := 2;
// end PartialFn4.ApplyVoidOp;
//
// function PartialFn4.TestApplyVoidOp
//   input Integer i;
//   output Integer j;
// algorithm
//   j := PartialFn4.ApplyVoidOp(PartialFn4.VoidOp, i);
// end PartialFn4.TestApplyVoidOp;
//
// function PartialFn4.VoidOp
//   input Integer i;
//   protected Integer j;
// algorithm
//   j := 1 + i;
// end PartialFn4.VoidOp;
//
// class PartialFn4
//   constant Integer i1 = 1;
//   Integer i2 = 2;
// end PartialFn4;
// endResult
