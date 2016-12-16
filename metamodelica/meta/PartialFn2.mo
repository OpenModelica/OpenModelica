// name:     PartialFn2
// keywords: PartialFn
// status:  correct
// cflags: -g=MetaModelica -d=gen
//
// Using pointers to functions pointing to other functions.
//

model PartialFn2

function AddInt
  input Integer i;
  output Integer out;
algorithm
  out := i+1;
end AddInt;

function ApplyIntOp

  input FuncIntToInt inFunc;
  input Integer i;
  output Integer outInt;

  partial function FuncIntToInt
    input Integer in1;
    output Integer out1;
  end FuncIntToInt;

algorithm
  outInt := inFunc(i);
end ApplyIntOp;

function ApplyApplyIntOp

  input FuncFuncIntToInt inFuncFunc;
  input FuncIntToInt inFunc;
  input Integer i;
  output Integer outInt;

  partial function FuncFuncIntToInt
    input FuncIntToInt inFunc;
    input Integer in1;
    output Integer out1;
  end FuncFuncIntToInt;

  partial function FuncIntToInt
    input Integer in1;
    output Integer out1;
  end FuncIntToInt;

algorithm
  outInt := inFuncFunc(inFunc, i);
end ApplyApplyIntOp;


function TestApplyApplyIntOp
  input Integer i1;
  output Integer out;
algorithm
  out := ApplyApplyIntOp(ApplyIntOp,AddInt,i1);
end TestApplyApplyIntOp;

constant Integer i1 = AddInt(1);
Integer i2 = TestApplyApplyIntOp(i1);
end PartialFn2;

// Result:
// function PartialFn2.AddInt
//   input Integer i;
//   output Integer out;
// algorithm
//   out := 1 + i;
// end PartialFn2.AddInt;
//
// function PartialFn2.ApplyApplyIntOp
//   input inFuncFunc<function>(.PartialFn2.ApplyApplyIntOp.FuncIntToInt<function>(#Integer in1) => #Integer inFunc, #Integer in1) => #Integer inFuncFunc;
//   input inFunc<function>(#Integer in1) => #Integer inFunc;
//   input Integer i;
//   output Integer outInt;
// algorithm
//   outInt := unbox(inFuncFunc(inFunc, #(i)));
// end PartialFn2.ApplyApplyIntOp;
//
// function PartialFn2.ApplyIntOp
//   input inFunc<function>(#Integer in1) => #Integer inFunc;
//   input Integer i;
//   output Integer outInt;
// algorithm
//   outInt := unbox(inFunc(#(i)));
// end PartialFn2.ApplyIntOp;
//
// function PartialFn2.TestApplyApplyIntOp
//   input Integer i1;
//   output Integer out;
// algorithm
//   out := PartialFn2.ApplyApplyIntOp(PartialFn2.ApplyIntOp, PartialFn2.AddInt, i1);
// end PartialFn2.TestApplyApplyIntOp;
//
// class PartialFn2
//   constant Integer i1 = 2;
//   Integer i2 = 3;
// end PartialFn2;
// endResult
