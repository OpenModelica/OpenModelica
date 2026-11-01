// name:     FunctionEvalFail
// keywords: function slice assignment
// status:   correct
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
  annotation(__OpenModelica_commandLineOptions="+d=nogen -d=-newInst");
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
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
