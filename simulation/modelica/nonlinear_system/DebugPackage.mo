within ;
package SolverFailure "Models showing different numerical failure modes"
    import SI = Modelica.SIunits;

    model NonlinearSolverFailureInitial
      "Nonlinear system of equations has no solutions"
      parameter SI.Pressure patm=101325 "Atmospheric pressure";
      parameter Real Kv=1e-2 "Valve coefficient";
      parameter Real dp_small=1 "Small dp for valve equation";
      parameter Real dp0=3e5 "Pump dp @ zero flow";
      parameter Real a1=1e6 "Pump coefficient";
      parameter Real a2=3e2 "Pump coefficient";
      parameter Real a3=3e2 "Pump coefficient";
      parameter SI.Temperature T0=20 + 273.15 "Temperature of incoming fluid";
      parameter SI.Density rho=995 "Density of fluid";
      parameter SI.Area A=0.01 "Storage tank cross section";
      parameter SI.MassFlowRate w_extra=0 "Extra mass flow rate into reservoir";
      constant SI.Acceleration g=Modelica.Constants.g_n
        "Acceleration of gravity";
      parameter SI.Temperature Tref=273.16
        "Reference temperature for specific enthalpy computation";
      parameter SI.SpecificHeatCapacity cp=4186 "Cp of the fluid";
      SI.MassFlowRate w_pump "Mass flow rate from the pump";
      SI.Pressure p1 "Pump discharge pressure";
      SI.Pressure p2 "Storage tank inlet pressure";
      SI.Pressure dp_pump "Pump dp";
      SI.Pressure dp_valve "Valve dp";
      Real sqrt_dp "Regularized sqrt(dp)";
      SI.SpecificEnthalpy h0 "Pump inlet specific enthalpy";
      SI.SpecificEnthalpy h1 "Pump discharge specific enthalpy";
      SI.Power W;
      SI.Length y(start=40, fixed=true) "Reservoir level";
      Real eta(final unit="1") = (p1 - patm)*w_pump/rho/W "Pump efficiency";
      SI.Temperature T1 "Pump discharge temperature";
      SI.Time tau=1 "Time constant of temperature sensor";
    equation
      dp_pump = p1 - patm "Pump dp";
      dp_valve = p1 - p2 "Valve dp";
      dp_pump = dp0 - a1*w_pump^2 "First characteristic curve of the pump";
      w_pump = Kv*sqrt_dp "Regularized sqrt(dp)";
      sqrt_dp = dp_valve/(dp_valve^2 + dp_small^2)^0.25 "Valve equation";
      W = a2 + a3*w_pump "Second characteristic curve of the pump";
      w_pump*(h1 - h0) = W "Energy balance of the pump";
      rho*A*der(y) = w_pump + w_extra "Mass balance of the reservoir";
      p2 = rho*g*y + patm "Static head of the storage tank";
      h0 = cp*(T0 - Tref) "h(T) relationship";
      h1 = cp*(T1 - Tref) "h(T) relationship";
      annotation (Documentation(info="<html>
<p>This model describes a simple hydraulic system with a pump, followed by a valve, which fills a reservoir.</p>
<p>The initial value of the level of the reservoir is too high for the pump sizing, so the pressure p2 is too high and consequently the nonlinear algebraic system of equations that determines p1 and w_pump has no solution.</p>
<p>It is possible to find a solution to the system either by lowering the initial value of y, and thus the pressure p2, or by increasing the value of the parameter dp0, increasing the head the pump can provide. </p>
<p>The debugger should show the dependency of the nonlinear system of equations on the parameters dp0, a1, a2, a3, and Kv (also showing their values), as well as the dependency on p2 (which has a too high value). Once one understands that p2 is too high, it should be possible to continue the analysis, looking at the equation that determines p2, which in turn depends on the value of the state y, which is the root cause of the problem. </p>
<p>The nonlinear system that cannot be solved has five unknowns: w_pump, dp_pump, dp_valve, sqrt_dp, and p1, which can be easily reduced to one by using dp_pump as as a tearing variable. It should be possible to track the values of all five variables during the iterations of the Newton algorithm.</p>
</html>"), experiment(StopTime=1000));
    end NonlinearSolverFailureInitial;

    model NonlinearSolverSimulation
      "Nonlinear systems ceases to have a solution during simulation"
      extends NonlinearSolverFailureInitial(
                                      y(start=20), w_extra=0.2);
      annotation (Documentation(info="<html>
<p>This model describes a simple hydraulic system with a pump, followed by a valve, which fills a reservoir.</p>
<p>The reservoir is filled both by the pump and by an extra source. The mass flow rate of the pump w_pump is determined by a nonlinear system with five unknowns: w_pump, dp_pump, dp_valve, sqrt_dp, and p1, which basically computes the operating point of the pump as the intersection between the pump head curve and the load (valve + reservoir head) curve. Note that these curves have two intersections (see NonlinearSolverFailure3). As the level increases, w_pump is reduced, and the two intersections get closer to each other, until at time t = 269 they collide, making the system singular. As the level increases further due to the extra source, this system ceases to have any solution. This is a typical bifurcation pattern in nonlinear systems.</p>
<p>The debugger can show that the condition number of the Jacobian of the nonlinear system gets bigger and bigger as the critical time when the two operating curves become tangent to each other, suggesting that this system becomes singular for some reason. Understanding the reason why this happens requires physical insight into the model. </p>
<p>The model can be fixed by adding some mass storage depending on the pressure p1, in order to avoid the singularity in determining p1, and also by using a more realistic cubic curve for the pump model, so that when the limit level is reached, the solution will jump to a big negative pump flow. Again, this requires physical insight into the validity range of the implemented model.</p>
</html>"), experiment(StopTime=500));
    end NonlinearSolverSimulation;

    model FiniteEscapeTime "Solution with finite escape time"
      extends NonlinearSolverFailureInitial(
                                      y(start=20));
      SI.Temperature Ts(start=T0) "Output of pump discharge temperature sensor";
    equation
      tau*der(Ts) = T1 - Ts "Temperature sensor dynamics";
    initial equation
      der(Ts) = 0;

      annotation (Documentation(info="<html>
<p>This model describes a simple hydraulic system with a pump, followed by a valve, which fills a reservoir.</p>
<p>As the reservoir level increase, the flow rate w_pump goes to zero. When it does, the energy balance equation causes the specific enthalpy h1, and thus the temperature T1, to go to infinity. The temperature T1 is the input of a first-order linear system, representing the temperature sensor dynamics. If a variable step-size solver with error control is used, it will try to compute the state trajectory, which also goes to infinity, so the solver eventually gets stuck at time t = 664.</p>
<p>The debugger should identify the state variable (Ts, in this case) whose error estimate is causing the step size to be reduced, then suggest the user to look at how its derivative der(Ts) is computed. It will be shown that it depends on T1, which goes to infinity. T1 in turn depends on h1, which also goes to infinity. Finally, h1 depends on the energy balance equation, which depends on w_pump - at that point it will become apparent that as the flow rate w_pump goes to zero, the model wil become ill-posed. The solution in this case is to change the pump model, by adding to the energy balance some dynamic energy storage and/or some heat transfer to the ambient.</p>
</html>"), experiment(StopTime=1000));
    end FiniteEscapeTime;

    model WrongInitialSolutionSelected
      "Initialization converges to the wrong solution"
      extends NonlinearSolverFailureInitial(
                                      y(start=20), dp_pump(start=-1000));
      annotation (Documentation(info="<html>
<p>This model describes a simple hydraulic system with a pump, followed by a valve, which fills a reservoir.</p>
<p>The operating point of the pumpt is determined by a nonlinear system with five unknowns: w_pump, dp_pump, dp_valve, sqrt_dp, and p1. Dymola selects dp_pump as as a tearing variable. At time t=0, this system has two solutions, one with positive w_pump, and the other one with negative w_pump. If the start value of the tearing variable dp_pump is chosen incorrectly, the solver will converge to the negative solution, then lock onto it for the rest of the simulation.</p>
<p>When the user sees the negative w_pump, he/she should be able to analyze how this value was found at time t = 0. The debugger should show that w_pump is solved by that nonlinear system, and show the values of the tearing variables and of the torn variables at each iteration. It will then become apparent that the start value of the teaing variable dp_pump leads to a negative value of the torn variable w_pump, leading to the solution of the problem, i.e., changing the start value of dp_pump to a value that allows to converge on the desired solution.</p>
</html>"), experiment(StopTime=500));
    end WrongInitialSolutionSelected;

end SolverFailure;
