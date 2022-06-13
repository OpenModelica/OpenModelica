model TestEventsDaeMode
   Real x(start = 0, fixed=true), val;
   Real y(start = 0, fixed=true);
equation
   val = sin(time);
   when x>1 then
     y = pre(y)+1;
   end when;
   der(x) = if val<1/2 then 1 else -1;
end TestEventsDaeMode;
