model VDP
    // see: Second-order sensitivities of general dynamic systems with application to optimal control problems
    // Vassilios S. Vassiliadis, Eva Balsa Canto, Julio R. Banga
    // Received 19 February 1998; received in revised form 4 November 1998; accepted 17 November 1998

    Real x1(start = 0, fixed = true);
    Real x2(start = 1, fixed = true);
    input Real u(max = 1, min = -0.5);
  equation
    der(x1) = (1 - x2^2) * x1 - x2 + u;
    der(x2) = x1;
end VDP;

optimization nmpcVDP(objective =  cost)
    extends VDP;
    Real cost(start = 10, fixed = true);
  equation
    der(cost) = x1^2 + x2^2 + u^2;
end nmpcVDP;
