// name:     FunctionEvalFail
// keywords: function slice assignment
// status:   correct
// cflags:   +d=nogen
//
// Checks that the compiler fails on a binding it can't evaluate, instead of
// giving it a default value.
//

class FunctionEvalFail
  function x
    input String s;
    output Real r;
  external "builtin";
  end x;

  function f
    input String s;
    output Real r = x(s);
  end f;
  constant Real r = f("abc");
end FunctionEvalFail;

// Result:
// function FunctionEvalFail.f
//   input String s;
//   output Real r = x(s);
// end FunctionEvalFail.f;
//
// class FunctionEvalFail
//   constant Real r = FunctionEvalFail.f("abc");
// end FunctionEvalFail;
// endResult
