model BuiltinMath
   Real x[13];
equation
   x[1] = sin(time) "sine";
   x[2] = cos(time) "cosine";
   x[3] = tan(time) "tangent (x shall not be: ..., -p/2, p/2, 3p/2, ...)";
   x[4] = asin(time) "inverse sine (-1 = x = 1)";
   x[5] = acos(time) "inverse cosine (-1 = x = 1)";
   x[6] = atan(time) "inverse tangent";
   x[7] = atan2(time,2*time);
   x[8] = sinh(time) "hyperbolic sine";
   x[9] = cosh(time) "hyperbolic cosine";
   x[10] = tanh(time) "hyperbolic tangent";
   x[11] = exp(time) "exponential, base e";
   x[12] = log(if time<=0.1 then 0.1 else time) "natural (base e) logarithm (x > 0)";
   x[13] = log10(if time <=0.1 then 0.1 else time);
end BuiltinMath;



