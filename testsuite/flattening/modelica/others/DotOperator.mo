// status: correct
// Enhancement #3096

model DotOperator

  function f
    input Real r;
    output Real x=1,y=2;
  end f;

  function y
    input Real i;
    output Real o = f(i).y;
  end y;

  function x
    input Real i;
    output Real o = f(i).x;
  end x;

  constant Real r1 = y(1.5);
  constant Real r2 = x(1.5);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end DotOperator;
// Result:
// function DotOperator.f
//   input Real r;
//   output Real x = 1.0;
//   output Real y = 2.0;
// end DotOperator.f;
//
// function DotOperator.x
//   input Real i;
//   output Real o = DotOperator.f(i)[1];
// end DotOperator.x;
//
// function DotOperator.y
//   input Real i;
//   output Real o = DotOperator.f(i)[2];
// end DotOperator.y;
//
// class DotOperator
//   constant Real r1 = 2.0;
//   constant Real r2 = 1.0;
// end DotOperator;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
