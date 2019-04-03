// name:     ReinitArray
// keywords: reinit array
// status:   correct
//
// Tests reinit operator on an array.
//
model ReinitArray
  Real x[3](start={1.1,2.2,3.3});
equation
 when time > 0.1 then
   reinit(x,zeros(3));
 end when;
der(x)={-x[1],x[2],1};
end ReinitArray;

// Result:
// class ReinitArray
//   Real x[1](start = 1.1);
//   Real x[2](start = 2.2);
//   Real x[3](start = 3.3);
// equation
//   when time > 0.1 then
//   reinit(x[1],0.0);
//   reinit(x[2],0.0);
//   reinit(x[3],0.0);
//   end when;
//   der(x[1]) = -x[1];
//   der(x[2]) = x[2];
//   der(x[3]) = 1.0;
// end ReinitArray;
// endResult
