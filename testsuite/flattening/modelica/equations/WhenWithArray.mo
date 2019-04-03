// name:     WhenWithArray
// keywords: when
// status:   correct
//
// check if we support conditions with cref arrays
//


model WhenWithArray "Model with many events in when clauses and a when clause with many triggering conditions"
  parameter Integer N = 5;
  Real x[N](each start = 0, each fixed = true);
  Boolean e[N](each start = false, each fixed = true);
  Integer v(start = 0, fixed = true);
equation
  for i in 1:N loop
    der(x[i]) = 1/i;
    when x[i] > 1 then
      e[i] = true;
    end when;
  end for;
  when e then
    v = pre(v) + 1;
  end when;
end WhenWithArray;

// Result:
// class WhenWithArray "Model with many events in when clauses and a when clause with many triggering conditions"
//   parameter Integer N = 5;
//   Real x[1](start = 0.0, fixed = true);
//   Real x[2](start = 0.0, fixed = true);
//   Real x[3](start = 0.0, fixed = true);
//   Real x[4](start = 0.0, fixed = true);
//   Real x[5](start = 0.0, fixed = true);
//   Boolean e[1](start = false, fixed = true);
//   Boolean e[2](start = false, fixed = true);
//   Boolean e[3](start = false, fixed = true);
//   Boolean e[4](start = false, fixed = true);
//   Boolean e[5](start = false, fixed = true);
//   Integer v(start = 0, fixed = true);
// equation
//   der(x[1]) = 1.0;
//   when x[1] > 1.0 then
//     e[1] = true;
//   end when;
//   der(x[2]) = 0.5;
//   when x[2] > 1.0 then
//     e[2] = true;
//   end when;
//   der(x[3]) = 0.3333333333333333;
//   when x[3] > 1.0 then
//     e[3] = true;
//   end when;
//   der(x[4]) = 0.25;
//   when x[4] > 1.0 then
//     e[4] = true;
//   end when;
//   der(x[5]) = 0.2;
//   when x[5] > 1.0 then
//     e[5] = true;
//   end when;
//   when {e[1], e[2], e[3], e[4], e[5]} then
//     v = 1 + pre(v);
//   end when;
// end WhenWithArray;
// endResult
