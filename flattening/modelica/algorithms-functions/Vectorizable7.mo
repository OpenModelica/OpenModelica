// status: correct
// bug #2529

model Vectorizable7
  function f
    input Integer m;
    output Real y;
  protected
    parameter Real phi[m] = linspace(0,1,m);
    parameter Real t[m] = cos(phi);
  algorithm
    y := sum(t);
  end f;

  Real r = f(integer(time));
end Vectorizable7;

// Result:
// function Vectorizable7.f
//   input Integer m;
//   output Real y;
//   protected parameter Real[m] phi = array(/*Real*/(-1 + i) / /*Real*/(-1 + m) for i in 1:m);
//   protected parameter Real[m] t = array(cos($tmpVar5) for $tmpVar5 in phi);
// algorithm
//   y := sum(t);
// end Vectorizable7.f;
//
// class Vectorizable7
//   Real r = Vectorizable7.f(integer(time));
// end Vectorizable7;
// endResult
