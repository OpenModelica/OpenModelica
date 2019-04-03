model FunctionTupleRecord
  record R
    Real r1;
    Integer r2;
  end R;

  function f4
    input Real x1;
    input Real x2;
    input R r;
    output R y1;
    output Real y2;
  algorithm
    y1.r1 := if x1>x2 then sin(r.r1) else cos(r.r2);
    y1.r2 := integer(ceil(y1.r1));
    for i in 1:y1.r2 loop
      y1.r1 := y1.r1+x1*x2+r.r1*r.r2;
    end for;
    y2 := r.r1*r.r2;
  end f4;

  R cse4, y;
  Real cse5;
equation
  y = cse4;
  (cse4, cse5) = f4(time, 0, R(time, 2));
end FunctionTupleRecord;
