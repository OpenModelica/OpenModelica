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
// endResult
