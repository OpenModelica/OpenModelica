// name:     PartialFn5
// keywords: PartialFn
// status:  correct
// cflags: -g=MetaModelica -d=gen
//
// Using function pointers to builtin functions
//

model PartialFn5

function ApplyRealOp

  input FuncRealToReal inFunc;
  input Real rin;
  output Real rout;

  partial function FuncRealToReal
    input Real r1;
    output Real r2;
  end FuncRealToReal;

algorithm
  rout := inFunc(rin);
end ApplyRealOp;

function ceil_
  input Real rin;
  output Real rout;
  external rout=ceil(rin);
end ceil_;

function TestApplyRealOp

  input Real rin;
  output Real rout;

algorithm
  rout := ApplyRealOp(ceil_, rin);
end TestApplyRealOp;

constant Real r1=1.2;
Real r2;

equation
  r2 = TestApplyRealOp(r1);
end PartialFn5;

// Result:
// function PartialFn5.ApplyRealOp
//   input inFunc<function>(#Real r1) => #Real inFunc;
//   input Real rin;
//   output Real rout;
// algorithm
//   rout := unbox(inFunc(#(rin)));
// end PartialFn5.ApplyRealOp;
//
// function PartialFn5.TestApplyRealOp
//   input Real rin;
//   output Real rout;
// algorithm
//   rout := PartialFn5.ApplyRealOp(PartialFn5.ceil_, rin);
// end PartialFn5.TestApplyRealOp;
//
// function PartialFn5.ceil_
//   input Real rin;
//   output Real rout;
//
//   external "C" rout = ceil(rin);
// end PartialFn5.ceil_;
//
// class PartialFn5
//   constant Real r1 = 1.2;
//   Real r2;
// equation
//   r2 = 2.0;
// end PartialFn5;
// endResult
