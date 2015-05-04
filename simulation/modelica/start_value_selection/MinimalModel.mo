model MinimalModel
 Real a;
 Real b = 0.0;
 Real c;
 Real d;
 parameter Real const_k(start = 1.0) = -15.0;
equation
 c = -d;
 d + (-const_k) = b;
 c + a = b;
end MinimalModel;
