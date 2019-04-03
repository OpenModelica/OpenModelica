// name:     Function12
// keywords: function, short class def
// status:   correct
//
// This tests function as short class definition.


package Modelica

  package Math

    function atan2 "four quadrant inverse tangent"
  input Real u1;
  input Real u2;
  output Real y;

  external "C" y=atan2(u1,u2) ;

end atan2;
end Math;
end Modelica;

model BaseSampler
  input Real u;
  Boolean doSample;
  function f= Modelica.Math.atan2;
protected
  discrete Real x;

equation
  when doSample then
    x=f(pre(x), u);
  end when;
end BaseSampler;
// Result:
// class BaseSampler
//   input Real u;
//   Boolean doSample;
//   protected discrete Real x;
// equation
//   when doSample then
//   x = atan2(pre(x), u);
//   end when;
// end BaseSampler;
// endResult
