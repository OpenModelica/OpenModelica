package PartialFn16

encapsulated package P
  partial function PF
    input Real x;
    output Real y;
  end PF;

  function f
    input Real x;
    output Real y;
  algorithm
    y := x;
  end f;

  function f2
    input String s;
    output Real r;
    output PF pf;
  algorithm
    (r, pf) := match(s)
      case _ then (1.0, f);
    end match;
  end f2;

  function f3
    input String s;
    output Real r;
    output PF pf;
  algorithm
    (r, pf) := match(s)
      local PF lpf;
      // Avoid template error by returning the function indirectly.
      case _ equation lpf = f; then (1.0, lpf);
    end match;
  end f3;
end P;

function all
  input Real r;
  output Real o1,o2,o3;
algorithm
  o1 :=  P.f(r);
  o2 :=  P.f2(if r > 1 then "a" else "b");
  o3 :=  P.f3(if r > 1 then "a" else "b");
end all;

end PartialFn16;
