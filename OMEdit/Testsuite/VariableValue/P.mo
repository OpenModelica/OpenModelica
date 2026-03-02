package P

  type Dynamics = enumeration(
    FreeInitial   "Free initial conditions",
    FixedInitial   "Fixed initial conditions",
    SteadyInitial   "Steady-state initial conditions");

  model Test
    parameter Dynamics dynType = P.Dynamics.FixedInitial;

    parameter String variable = "Value";
     annotation (Diagram(graphics={
       Text(origin = {28, 32}, extent = {{-10, -10}, {10, 10}}, textString = "%variable"), Text(origin = {-30, 30}, extent = {{-10, -10}, {10, 10}}, textString = "%dynType")}));
  end Test;

end P;
