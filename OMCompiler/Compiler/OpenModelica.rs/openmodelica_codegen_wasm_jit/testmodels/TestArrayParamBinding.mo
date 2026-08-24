model TestArrayParamBinding
  "A rank-3 parameter array bound to a function of parameters an equation computes"
  function prop
    input Integer n;
    input Real a[3, n];
    output Real o[3, n, 2];
  algorithm
    assert(a[1, 1] > 0, "prop ran before its inputs were computed");
    for i in 1:3 loop
      for j in 1:n loop
        o[i, j, 1] := a[i, j];
        o[i, j, 2] := 2*a[i, j];
      end for;
    end for;
  end prop;
  parameter Real s = 0.5;
  parameter Real a[3, 2] = {{s, 2*s}, {3*s, 4*s}, {5*s, 6*s}};
  parameter Real o[3, 2, 2] = prop(2, a);
  Real y = o[1, 1, 1] + o[3, 2, 2] + time;
end TestArrayParamBinding;
