model ArrayBox
  "Whole-array, slice and run-time-indexed references to arrays whose elements
   are stored apart (a state, an algebraic, a constant; records)"
  record R
    Real a;
    Real b;
  end R;

  function weightedSum
    input Real v[:];
    output Real s = 0;
  algorithm
    for i in 1:size(v, 1) loop
      s := s + i*v[i];
    end for;
    annotation(Inline=false);
  end weightedSum;

  function dot
    input R r[:];
    output Real s = 0;
  algorithm
    for i in 1:size(r, 1) loop
      s := s + r[i].a*r[i].b;
    end for;
    annotation(Inline=false);
  end dot;

  Real x[3](start={1, 0, 2}, fixed={true, false, false});
  Integer k = if time < 0.5 then 1 else 2;
  R r[2];
  Real whole, slice, element, records;
equation
  der(x[1]) = -x[1];
  x[2] = time;
  x[3] = 2.0;
  whole = weightedSum(x);
  slice = weightedSum(x[2:3]);
  element = x[k];
  r[1].a = time;
  r[1].b = x[1];
  r[2].a = 3;
  r[2].b = 4;
  records = dot(r);
end ArrayBox;
