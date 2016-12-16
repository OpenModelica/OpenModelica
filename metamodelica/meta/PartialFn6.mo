// name:     PartialFn6
// keywords: PartialFn
// status:   correct
// cflags:   -g=MetaModelica -d=gen
// depends:  PartialFn6.ext_f.c
//
// Passing external functions as arguments to function calls

function ApplyRealOp
  input RealToReal inFunc;
  input Real x;
  output Real y;

  partial function RealToReal
    input Real x;
    output Real y;
  end RealToReal;

algorithm
  y := inFunc(x);
end ApplyRealOp;

function TestApplyRealOp
  input Real x;
  output Real y;

algorithm
  y := ApplyRealOp(ExtFunc,x);
end TestApplyRealOp;

function ExtFunc
  input Real r;
  output Real out;
  external "C" out=PartialFn6_f(r) annotation(Library="PartialFn6.ext_f.c");
end ExtFunc;

model PartialFn6
  constant Real x = 5;
  Real y;
equation
  y = TestApplyRealOp(x);
end PartialFn6;
// Result:
// function ApplyRealOp
//   input inFunc<function>(#Real x) => #Real inFunc;
//   input Real x;
//   output Real y;
// algorithm
//   y := unbox(inFunc(#(x)));
// end ApplyRealOp;
//
// function ExtFunc
//   input Real r;
//   output Real out;
//
//   external "C" out = PartialFn6_f(r);
// end ExtFunc;
//
// function TestApplyRealOp
//   input Real x;
//   output Real y;
// algorithm
//   y := ApplyRealOp(ExtFunc, x);
// end TestApplyRealOp;
//
// class PartialFn6
//   constant Real x = 5.0;
//   Real y;
// equation
//   y = 15.0;
// end PartialFn6;
// endResult
