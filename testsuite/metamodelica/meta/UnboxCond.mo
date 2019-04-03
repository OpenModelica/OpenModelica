// cflags: +g=MetaModelica +d=noevalfunc,nogen
// status: correct

model UnboxCond

function f
  input Predicate predicate;
  input Integer i;
  output Integer r;
protected
  partial function Predicate
    input Integer value;
    output Boolean result;
  end Predicate;
algorithm
  r := if predicate(i) then 1 else 2;
end f;

function constTrue
  input Integer x;
  output Boolean t;
algorithm
  t := true;
end constTrue;

function test
algorithm
  f(constTrue, 0);
end test;
algorithm
  test();
end UnboxCond;
// Result:
// function UnboxCond.constTrue
//   input Integer x;
//   output Boolean t;
// algorithm
//   t := true;
// end UnboxCond.constTrue;
//
// function UnboxCond.f
//   input predicate<function>(#Integer value) => #Boolean predicate;
//   input Integer i;
//   output Integer r;
// algorithm
//   r := if unbox(predicate(#(i))) then 1 else 2;
// end UnboxCond.f;
//
// function UnboxCond.test
// algorithm
//   UnboxCond.f(UnboxCond.constTrue, 0);
// end UnboxCond.test;
//
// class UnboxCond
// algorithm
//   UnboxCond.test();
// end UnboxCond;
// endResult
