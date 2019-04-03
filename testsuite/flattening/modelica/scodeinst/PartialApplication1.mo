// name: PartialApplication1
// keywords:
// status: correct
// cflags: -d=newInst
//

function f1
  input Real x;
  input Real y;
  output Real z = x + y;
end f1;

partial function pf
  input Real x;
  output Real z;
end pf;

function f2
  input Real x;
  input pf func; 
  output Real z = x * func(x);
end f2;

function f3
  input Real x;
  output Real z = x;
end f3;

model PartialApplication1
  Real x = f2(time, function f1(y = 2.0));  
  //Real x = f2(time, f3);
end PartialApplication1;

// Result:
// function f1
//   input Real x;
//   input Real y;
//   output Real z = x + y;
// end f1;
//
// function f2
//   input Real x;
//   input func<function>(#Real x) => #Real func;
//   output Real z = x * unbox(func(#(x)));
// end f2;
//
// class PartialApplication1
//   Real x = f2(time, function f1(#(2.0)));
// end PartialApplication1;
// endResult
