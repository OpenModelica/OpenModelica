model CheckSqrt
 Real x(start=1);
 Real y(start=1);
 Real u = 1 - time;
 parameter Real c = 1;
equation
 // this equation should cause a model error sqrt(u) and u < 0
 der(x) = if (u>0) then -c*sqrt(u) else 0;
 // this should be ok
 der(y) = if (noEvent(u>0)) then -c*sqrt(u) else 0;
end CheckSqrt;

