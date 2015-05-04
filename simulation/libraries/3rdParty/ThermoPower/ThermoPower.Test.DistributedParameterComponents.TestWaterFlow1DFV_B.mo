package ThermoPower  "Open library for thermal power plant simulation"
  extends Modelica.Icons.Package;

  model System  "System wide properties"
    parameter Boolean allowFlowReversal = true "= false to restrict to design flow direction (flangeA -> flangeB)" annotation(Evaluate = true);
    parameter ThermoPower.Choices.System.Dynamics Dynamics = Choices.System.Dynamics.DynamicFreeInitial;
    annotation(defaultComponentName = "system", defaultComponentPrefixes = "inner", Icon(graphics = {Polygon(points = {{-100, 60}, {-60, 100}, {60, 100}, {100, 60}, {100, -60}, {60, -100}, {-60, -100}, {-100, -60}, {-100, 60}}, lineColor = {0, 0, 255}, smooth = Smooth.None, fillColor = {170, 213, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-80, 40}, {80, -20}}, lineColor = {0, 0, 255}, textString = "system")}));
  end System;

  package Icons  "Icons for ThermoPower library"
    extends Modelica.Icons.Package;

    package Water  "Icons for component using water/steam as working fluid"
      extends Modelica.Icons.Package;

      partial model SourceP   annotation(Icon(graphics = {Ellipse(extent = {{-80, 80}, {80, -80}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-20, 34}, {28, -26}}, lineColor = {255, 255, 255}, textString = "P"), Text(extent = {{-100, -78}, {100, -106}}, textString = "%name")})); end SourceP;

      partial model SourceW   annotation(Icon(graphics = {Rectangle(extent = {{-80, 40}, {80, -40}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid), Polygon(points = {{-12, -20}, {66, 0}, {-12, 20}, {34, 0}, {-12, -20}}, lineColor = {255, 255, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-100, -52}, {100, -80}}, textString = "%name")})); end SourceW;

      partial model Tube   annotation(Icon(graphics = {Rectangle(extent = {{-80, 40}, {80, -40}}, lineColor = {0, 0, 0}, fillPattern = FillPattern.HorizontalCylinder)}), Diagram()); end Tube;

      partial model Valve   annotation(Icon(graphics = {Line(points = {{0, 40}, {0, 0}}, color = {0, 0, 0}, thickness = 0.5), Polygon(points = {{-80, 40}, {-80, -40}, {0, 0}, {-80, 40}}, lineColor = {0, 0, 0}, lineThickness = 0.5, fillPattern = FillPattern.Solid, fillColor = {0, 0, 255}), Polygon(points = {{80, 40}, {0, 0}, {80, -40}, {80, 40}}, lineColor = {0, 0, 0}, lineThickness = 0.5, fillPattern = FillPattern.Solid, fillColor = {0, 0, 255}), Rectangle(extent = {{-20, 60}, {20, 40}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid)}), Diagram()); end Valve;

      model SensThrough   annotation(Icon(graphics = {Rectangle(extent = {{-40, -20}, {40, -60}}, lineColor = {0, 0, 0}, fillPattern = FillPattern.Solid, fillColor = {0, 0, 255}), Line(points = {{0, 20}, {0, -20}}, color = {0, 0, 0}), Ellipse(extent = {{-40, 100}, {40, 20}}, lineColor = {0, 0, 0}), Line(points = {{40, 60}, {60, 60}}), Text(extent = {{-100, -76}, {100, -100}}, textString = "%name")})); end SensThrough;
    end Water;

    partial model HeatFlow   annotation(Icon(graphics = {Rectangle(extent = {{-80, 20}, {80, -20}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Forward)})); end HeatFlow;
  end Icons;

  package Functions  "Miscellaneous functions"
    extends Modelica.Icons.Package;

    function squareReg  "Anti-symmetric square approximation with non-zero derivative in the origin"
      extends Modelica.Icons.Function;
      input Real x;
      input Real delta = 0.01 "Range of significant deviation from x^2*sgn(x)";
      output Real y;
    algorithm
      y := x * sqrt(x * x + delta * delta);
      annotation(Documentation(info = "<html>
       This function approximates x^2*sgn(x), such that the derivative is non-zero in x=0.
       </p>
       <p>
       <table border=1 cellspacing=0 cellpadding=2>
       <tr><th>Function</th><th>Approximation</th><th>Range</th></tr>
       <tr><td>y = regSquare(x)</td><td>y ~= x^2*sgn(x)</td><td>abs(x) &gt;&gt delta</td></tr>
       <tr><td>y = regSquare(x)</td><td>y ~= x*delta</td><td>abs(x) &lt;&lt  delta</td></tr>
       </table>
       <p>
       With the default value of delta=0.01, the difference between x^2 and regSquare(x) is 41% around x=0.01, 0.4% around x=0.1 and 0.005% around x=1.
       </p>
       </p>
       </html>", revisions = "<html>
       <ul>
       <li><i>15 Mar 2005</i>
           by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
              Created. </li>
       </ul>
       </html>"));
    end squareReg;
    annotation(Documentation(info = "<HTML>
     This package contains general-purpose functions and models
     </HTML>"));
  end Functions;

  package Choices  "Choice enumerations for ThermoPower models"
    extends Modelica.Icons.Package;

    package Flow1D
      type FFtypes = enumeration(Kfnom "Kfnom friction factor", OpPoint "Friction factor defined by operating point", Cfnom "Cfnom friction factor", Colebrook "Colebrook's equation", NoFriction "No friction") "Type, constants and menu choices to select the friction factor";
      type HCtypes = enumeration(Middle "Middle of the pipe", Upstream "At the inlet", Downstream "At the outlet") "Type, constants and menu choices to select the location of the hydraulic capacitance";
    end Flow1D;

    package Init  "Options for initialisation"
      type Options = enumeration(noInit "No initial equations", steadyState "Steady-state initialisation", steadyStateNoP "Steady-state initialisation except pressures", steadyStateNoT "Steady-state initialisation except temperatures", steadyStateNoPT "Steady-state initialisation except pressures and temperatures") "Type, constants and menu choices to select the initialisation options";
    end Init;

    package System
      type Dynamics = enumeration(DynamicFreeInitial "DynamicFreeInitial -- Dynamic balance, Initial guess value", FixedInitial "FixedInitial -- Dynamic balance, Initial value fixed", SteadyStateInitial "SteadyStateInitial -- Dynamic balance, Steady state initial with guess value", SteadyState "SteadyState -- Steady state balance, Initial guess value") "Enumeration to define definition of balance equations";
    end System;

    package FluidPhase
      type FluidPhases = enumeration(Liquid "Liquid", Steam "Steam", TwoPhases "Two Phases") "Type, constants and menu choices to select the fluid phase";
    end FluidPhase;
  end Choices;

  package Test  "Test cases for the ThermoPower models"
    extends Modelica.Icons.Package;

    package DistributedParameterComponents  "Tests for thermo-hydraulic distributed parameter components"
      model TestWaterFlow1DFV_B  "Test case for Water.Flow1DFV"
        package Medium = Modelica.Media.Water.WaterIF97OnePhase_ph;
        parameter Integer Nnodes = 10 "Number of nodes";
        parameter Integer Nt = 5 "Number of tubes";
        parameter Modelica.SIunits.Length Lhex = 2 "Total length";
        parameter Modelica.SIunits.Diameter Dihex = 0.02 "Internal diameter";
        final parameter Modelica.SIunits.Radius rhex = Dihex / 2 "Internal radius";
        final parameter Modelica.SIunits.Length omegahex = Modelica.Constants.pi * Dihex "Internal perimeter";
        final parameter Modelica.SIunits.Area Ahex = Modelica.Constants.pi * rhex ^ 2 "Internal cross section";
        parameter Real Cfhex = 0.005 "Friction coefficient";
        parameter Modelica.SIunits.MassFlowRate whex = 0.31 "Nominal mass flow rate";
        parameter Modelica.SIunits.Pressure phex = 300000.0 "Initial pressure";
        parameter Modelica.SIunits.SpecificEnthalpy hs = 100000.0 "Initial inlet specific enthalpy";
        parameter Modelica.SIunits.CoefficientOfHeatTransfer gamma = 1500 "Fixed heat transfer coefficient";
        Real cp = Medium.specificHeatCapacityCp(hex.fluidState[1]);
        Real NTU = Nt * Lhex * Dihex * 3.1415 * gamma / (whex * Medium.specificHeatCapacityCp(hex.fluidState[1])) "Number of heat transfer units";
        Real alpha = 1 - .Modelica.Math.exp(-NTU) "Steady state gain of outlet temperature vs. external temperature";
        Water.ValveLin valve(Kv = 2 * whex / phex) annotation(Placement(transformation(extent = {{14, -22}, {34, -2}}, rotation = 0)));
        Water.SourceMassFlow fluidSource(w0 = whex, p0 = phex, h = hs) annotation(Placement(transformation(extent = {{-86, -22}, {-66, -2}}, rotation = 0)));
        Water.SinkPressure fluidSink(p0 = phex / 2, h = hs) annotation(Placement(transformation(extent = {{74, -22}, {94, -2}}, rotation = 0)));
        Modelica.Blocks.Sources.Step Temperature(height = 10, startTime = 10, offset = 296.9) annotation(Placement(transformation(extent = {{-82, 34}, {-62, 54}}, rotation = 0)));
        Modelica.Blocks.Sources.Constant Constant1(k = 1) annotation(Placement(transformation(extent = {{-12, 56}, {8, 76}}, rotation = 0)));
        Water.SensT T_in(redeclare package Medium = Medium) annotation(Placement(transformation(extent = {{-56, -18}, {-36, 2}}, rotation = 0)));
        Water.SensT T_out(redeclare package Medium = Medium) annotation(Placement(transformation(extent = {{44, -18}, {64, 2}}, rotation = 0)));
        inner System system annotation(Placement(transformation(extent = {{80, 80}, {100, 100}})));
        Thermal.TempSource1DFV tempSource(Nw = Nnodes - 1) annotation(Placement(transformation(extent = {{-22, 14}, {-2, 34}})));
        Water.Flow1DFV hex(
          redeclare package Medium = Medium, N = Nnodes, L = Lhex, A = Ahex,
          omega = omegahex, Dhyd = Dihex, wnom = whex, FFtype = ThermoPower.Choices.Flow1D.FFtypes.Cfnom,
          Cfnom = Cfhex, HydraulicCapacitance = ThermoPower.Choices.Flow1D.HCtypes.Downstream,
          FluidPhaseStart = ThermoPower.Choices.FluidPhase.FluidPhases.Liquid,
          pstart = phex, hstartin = hs, hstartout = hs, initOpt = ThermoPower.Choices.Init.Options.steadyState,
          redeclare ThermoPower.Thermal.HeatTransfer.ConstantHeatTransferCoefficient heatTransfer(gamma = gamma),
          Nt = Nt, dpnom = 1000) annotation(Placement(transformation(extent = {{-22, -22}, {-2, -2}})));
      equation
        connect(T_in.inlet, fluidSource.flange) annotation(Line(points = {{-52, -12}, {-60, -12}, {-66, -12}}, thickness = 0.5, color = {0, 0, 255}));
        connect(valve.outlet, T_out.inlet) annotation(Line(points = {{34, -12}, {48, -12}}, thickness = 0.5, color = {0, 0, 255}));
        connect(T_out.outlet, fluidSink.flange) annotation(Line(points = {{60, -12}, {74, -12}}, thickness = 0.5, color = {0, 0, 255}));
        connect(Constant1.y, valve.cmd) annotation(Line(points = {{9, 66}, {24, 66}, {24, -4}}, color = {0, 0, 127}));
        connect(T_in.outlet, hex.infl) annotation(Line(points = {{-40, -12}, {-22, -12}}, color = {0, 0, 255}, smooth = Smooth.None));
        connect(hex.outfl, valve.inlet) annotation(Line(points = {{-2, -12}, {14, -12}}, color = {0, 0, 255}, smooth = Smooth.None));
        connect(tempSource.wall, hex.wall) annotation(Line(points = {{-12, 21}, {-12, -7}}, color = {255, 127, 0}, smooth = Smooth.None));
        connect(Temperature.y, tempSource.temperature) annotation(Line(points = {{-61, 44}, {-12, 44}, {-12, 28}}, color = {0, 0, 127}, smooth = Smooth.None));
        annotation(Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}})), experiment(StopTime = 40, Tolerance = 0.000001), Documentation(info = "<html>
         <p>The model is designed to test the component <code>Water.Flow1DFV</code> (fluid side of a heat exchanger, finite volumes). </p>
         <p>This model represent the fluid side of a heat exchanger with convective exchange with an external source of uniform given temperature. The operating fluid is liquid water. The number of transfer units in the selected operating point is NTU = 0.73. Assuming incompressible fluid and constant cp, when the external temperature is raised at time t = 20 s, the outlet temperature should follow a ramp change, with a duration equal to the residence time of the fluid in the tubes, and an amplitude equal to a fraction exp(-NTU) of the external temperature change.</p>
         <p>Simulation Interval = [0...200] sec </p>
         <p>Integration Algorithm = DASSL </p>
         <p>Algorithm Tolerance = 1e-6 </p>
         </html>", revisions = "<html>
         <p><ul>
         <li>18 Sep 2013 by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br/>Updated to new FV structure. Updated parameters.</li></li>
         <li><i>1 Oct 2003</i> by <a href=\"mailto:francesco.schiavo@polimi.it\">Francesco Schiavo</a>:<br/>First release.</li>
         </ul></p>
         </html>"));
      end TestWaterFlow1DFV_B;
    end DistributedParameterComponents;
    annotation(Documentation(info = "<HTML>
     This package contains test cases for the ThermoPower library.
     </HTML>"));
  end Test;

  package Thermal  "Thermal models of heat transfer"
    extends Modelica.Icons.Package;

    connector DHTVolumes  "Distributed Heat Terminal"
      parameter Integer N "Number of volumes";
      AbsoluteTemperature[N] T "Temperature at the volumes";
      flow .Modelica.SIunits.Power[N] Q "Heat flow at the volumes";
      annotation(Icon(graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {255, 127, 0}, fillColor = {255, 127, 0}, fillPattern = FillPattern.Solid)}));
    end DHTVolumes;

    model TempSource1DFV  "Uniform Distributed Temperature Source for Finite Volume models"
      extends Icons.HeatFlow;
      parameter Integer Nw = 1 "Number of volumes on the wall port";
      Thermal.DHTVolumes wall(final N = Nw) annotation(Placement(transformation(extent = {{-40, -40}, {40, -20}}, rotation = 0)));
      Modelica.Blocks.Interfaces.RealInput temperature "Temperature [K]" annotation(Placement(transformation(origin = {0, 40}, extent = {{-20, -20}, {20, 20}}, rotation = 270)));
    equation
      for i in 1:Nw loop
        wall.T[i] = temperature;
      end for;
      annotation(Diagram(), Icon(graphics = {Text(extent = {{-100, -46}, {100, -70}}, lineColor = {191, 95, 0}, textString = "%name")}), Documentation(info = "<HTML>
       <p>Model of an ideal 1D uniform temperature source (finite volume). The actual temperature is provided by the <tt>temperature</tt> signal connector.
       </HTML>", revisions = "<html>
       <ul>
       <li><i>3 May 2013</i>
           by <a href=\"mailto:stefanoboni@hotmail.com\">Stefano Boni</a>:<br>
              First release.</li>
       </ul>
       </html>
       "));
    end TempSource1DFV;

    package HeatTransfer  "Heat transfer models"
      model IdealHeatTransfer  "Delta T across the boundary layer is zero (infinite h.t.c.)"
        extends BaseClasses.DistributedHeatTransferFV(final useAverageTemperature = false);
        Medium.Temperature[Nf] T "Fluid temperature";
      equation
        assert(Nw == Nf - 1, "Number of volumes Nw on wall side should be equal to number of volumes fluid side Nf - 1");
        for j in 1:Nw loop
          wall.T[j] = T[j + 1] "Ideal infinite heat transfer";
        end for;
      end IdealHeatTransfer;

      model ConstantHeatTransferCoefficient  "Constant heat transfer coefficient"
        extends BaseClasses.DistributedHeatTransferFV;
        parameter .Modelica.SIunits.CoefficientOfHeatTransfer gamma "Constant heat transfer coefficient";
        Medium.Temperature[Nw] Tvol "Fluid temperature in the volumes";
        .Modelica.SIunits.Power Q "Total heat flow through lateral boundary";
      equation
        assert(Nw == Nf - 1, "The number of volumes Nw on wall side should be equal to number of volumes fluid side Nf - 1");
        for j in 1:Nw loop
          Tvol[j] = if useAverageTemperature then (T[j] + T[j + 1]) / 2 else T[j + 1];
          wall.Q[j] = (wall.T[j] - Tvol[j]) * omega * l * gamma * Nt;
        end for;
        Q = sum(wall.Q);
        annotation(Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}})), Icon(graphics = {Text(extent = {{-100, -52}, {100, -80}}, textString = "%name")}));
      end ConstantHeatTransferCoefficient;
    end HeatTransfer;

    package BaseClasses
      partial model DistributedHeatTransferFV  "Base class for distributed heat transfer models - finite volumes"
        extends ThermoPower.Icons.HeatFlow;
        replaceable package Medium = Modelica.Media.Interfaces.PartialMedium "Medium model";
        input Medium.ThermodynamicState[Nf] fluidState;
        input .Modelica.SIunits.MassFlowRate[Nf] w;
        ThermoPower.Thermal.DHTVolumes wall(final N = Nw) annotation(Placement(transformation(extent = {{-40, 20}, {40, 40}}, rotation = 0)));
        parameter Integer Nf(min = 2) = 2 "Number of nodes on the fluid side";
        parameter Integer Nw "Number of nodes on the wallside";
        parameter Integer Nt(min = 1) "Number of tubes in parallel";
        parameter .Modelica.SIunits.Distance L "Tube length";
        parameter .Modelica.SIunits.Area A "Cross-sectional area (single tube)";
        parameter .Modelica.SIunits.Length omega "Wet perimeter of heat transfer surface (single tube)";
        parameter .Modelica.SIunits.Length Dhyd "Hydraulic Diameter (single tube)";
        parameter .Modelica.SIunits.MassFlowRate wnom "Nominal mass flow rate (single tube)";
        parameter Boolean useAverageTemperature = true "= true to use average temperature for heat transfer";
        final parameter .Modelica.SIunits.Length l = L / Nw "Length of a single volume";
        Medium.Temperature[Nf] T "Temperatures at the fluid side nodes";
      equation
        for j in 1:Nf loop
          T[j] = Medium.temperature(fluidState[j]);
        end for;
      end DistributedHeatTransferFV;
    end BaseClasses;
    annotation(Documentation(info = "<HTML>
     This package contains models of physical processes and components related to heat transfer phenomena.
     <p>All models with dynamic equations provide initialisation support. Set the <tt>initOpt</tt> parameter to the appropriate value:
     <ul>
     <li><tt>Choices.Init.Options.noInit</tt>: no initialisation
     <li><tt>Choices.Init.Options.steadyState</tt>: full steady-state initialisation
     </ul>
     The latter options can be useful when two or more components are connected directly so that they will have the same pressure or temperature, to avoid over-specified systems of initial equations.

     </HTML>"));
  end Thermal;

  package Water  "Models of components with water/steam as working fluid"
    connector Flange  "Flange connector for water/steam flows"
      replaceable package Medium = StandardWater constrainedby Modelica.Media.Interfaces.PartialMedium;
      flow Medium.MassFlowRate m_flow "Mass flow rate from the connection point into the component";
      Medium.AbsolutePressure p "Thermodynamic pressure in the connection point";
      stream Medium.SpecificEnthalpy h_outflow "Specific thermodynamic enthalpy close to the connection point if m_flow < 0";
      stream Medium.MassFraction[Medium.nXi] Xi_outflow "Independent mixture mass fractions m_i/m close to the connection point if m_flow < 0";
      stream Medium.ExtraProperty[Medium.nC] C_outflow "Properties c_i/m close to the connection point if m_flow < 0";
      annotation(Documentation(info = "<HTML>.
       </HTML>", revisions = "<html>
       <ul>
       <li><i>16 Dec 2004</i>
           by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
              Medium model added.</li>
       <li><i>1 Oct 2003</i>
           by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
              First release.</li>
       </ul>
       </html>"), Diagram(), Icon());
    end Flange;

    connector FlangeA  "A-type flange connector for water/steam flows"
      extends ThermoPower.Water.Flange;
      annotation(Icon(graphics = {Ellipse(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 255}, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid)}));
    end FlangeA;

    connector FlangeB  "B-type flange connector for water/steam flows"
      extends ThermoPower.Water.Flange;
      annotation(Icon(graphics = {Ellipse(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 255}, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid), Ellipse(extent = {{-40, 40}, {40, -40}}, lineColor = {0, 0, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid)}));
    end FlangeB;

    extends Modelica.Icons.Package;
    package StandardWater = Modelica.Media.Water.StandardWater;

    model SinkPressure  "Pressure sink for water/steam flows"
      extends Icons.Water.SourceP;
      replaceable package Medium = StandardWater constrainedby Modelica.Media.Interfaces.PartialMedium;
      parameter .Modelica.SIunits.Pressure p0 = 101325.0 "Nominal pressure";
      parameter HydraulicResistance R = 0 "Hydraulic resistance" annotation(Evaluate = true);
      parameter .Modelica.SIunits.SpecificEnthalpy h = 100000.0 "Nominal specific enthalpy";
      parameter Boolean allowFlowReversal = system.allowFlowReversal "= true to allow flow reversal, false restricts to design direction";
      parameter Boolean use_in_p0 = false "Use connector input for the pressure" annotation(Dialog(group = "External inputs"));
      parameter Boolean use_in_h = false "Use connector input for the specific enthalpy" annotation(Dialog(group = "External inputs"));
      outer ThermoPower.System system "System wide properties";
      .Modelica.SIunits.Pressure p "Actual pressure";
      FlangeA flange(redeclare package Medium = Medium, m_flow(min = if allowFlowReversal then -Modelica.Constants.inf else 0)) annotation(Placement(transformation(extent = {{-120, -20}, {-80, 20}}, rotation = 0)));
      Modelica.Blocks.Interfaces.RealInput in_p0 if use_in_p0 annotation(Placement(transformation(origin = {-40, 88}, extent = {{-20, -20}, {20, 20}}, rotation = 270)));
      Modelica.Blocks.Interfaces.RealInput in_h if use_in_h annotation(Placement(transformation(origin = {40, 88}, extent = {{-20, -20}, {20, 20}}, rotation = 270)));
    protected
      Modelica.Blocks.Interfaces.RealInput in_p0_internal;
      Modelica.Blocks.Interfaces.RealInput in_h_internal;
    equation
      if R == 0 then
        flange.p = p;
      else
        flange.p = p + flange.m_flow * R;
      end if;
      p = in_p0_internal;
      if not use_in_p0 then
        in_p0_internal = p0 "Pressure set by parameter";
      end if;
      flange.h_outflow = in_h_internal;
      if not use_in_h then
        in_h_internal = h "Enthalpy set by parameter";
      end if;
      connect(in_p0, in_p0_internal);
      connect(in_h, in_h_internal);
      annotation(Icon(graphics = {Text(extent = {{-106, 92}, {-56, 50}}, textString = "p0"), Text(extent = {{54, 94}, {112, 52}}, textString = "h")}), Diagram(), Documentation(info = "<HTML>
       <p><b>Modelling options</b></p>
       <p>If <tt>R</tt> is set to zero, the pressure sink is ideal; otherwise, the inlet pressure increases proportionally to the incoming flowrate.</p>
       <p>If the <tt>in_p0</tt> connector is wired, then the source pressure is given by the corresponding signal, otherwise it is fixed to <tt>p0</tt>.</p>
       <p>If the <tt>in_h</tt> connector is wired, then the source pressure is given by the corresponding signal, otherwise it is fixed to <tt>h</tt>.</p>
       </HTML>", revisions = "<html>
       <ul>
       <li><i>16 Dec 2004</i>
           by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
              Medium model and standard medium definition added.</li>
       <li><i>18 Jun 2004</i>
           by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
              Removed <tt>p0_fix</tt> and <tt>hfix</tt>; the connection of external signals is now detected automatically.</li>
       <li><i>1 Oct 2003</i>
           by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
              First release.</li>
       </ul>
       </html>"));
    end SinkPressure;

    model SourceMassFlow  "Flowrate source for water/steam flows"
      extends Icons.Water.SourceW;
      replaceable package Medium = StandardWater constrainedby Modelica.Media.Interfaces.PartialMedium;
      parameter .Modelica.SIunits.MassFlowRate w0 = 0 "Nominal mass flowrate";
      parameter .Modelica.SIunits.Pressure p0 = 100000.0 "Nominal pressure";
      parameter HydraulicConductance G = 0 "Hydraulic conductance";
      parameter .Modelica.SIunits.SpecificEnthalpy h = 100000.0 "Nominal specific enthalpy";
      parameter Boolean allowFlowReversal = system.allowFlowReversal "= true to allow flow reversal, false restricts to design direction";
      parameter Boolean use_in_w0 = false "Use connector input for the mass flow" annotation(Dialog(group = "External inputs"));
      parameter Boolean use_in_h = false "Use connector input for the specific enthalpy" annotation(Dialog(group = "External inputs"));
      outer ThermoPower.System system "System wide properties";
      .Modelica.SIunits.MassFlowRate w "Mass flowrate";
      FlangeB flange(redeclare package Medium = Medium, m_flow(max = if allowFlowReversal then +Modelica.Constants.inf else 0)) annotation(Placement(transformation(extent = {{80, -20}, {120, 20}}, rotation = 0)));
      Modelica.Blocks.Interfaces.RealInput in_w0 if use_in_w0 annotation(Placement(transformation(origin = {-40, 60}, extent = {{-20, -20}, {20, 20}}, rotation = 270)));
      Modelica.Blocks.Interfaces.RealInput in_h if use_in_h annotation(Placement(transformation(origin = {40, 60}, extent = {{-20, -20}, {20, 20}}, rotation = 270)));
    protected
      Modelica.Blocks.Interfaces.RealInput in_w0_internal;
      Modelica.Blocks.Interfaces.RealInput in_h_internal;
    equation
      if G == 0 then
        flange.m_flow = -w;
      else
        flange.m_flow = -w + (flange.p - p0) * G;
      end if;
      w = in_w0_internal;
      if not use_in_w0 then
        in_w0_internal = w0 "Flow rate set by parameter";
      end if;
      flange.h_outflow = in_h_internal "Enthalpy set by connector";
      if not use_in_h then
        in_h_internal = h "Enthalpy set by parameter";
      end if;
      connect(in_w0, in_w0_internal);
      connect(in_h, in_h_internal);
      annotation(Icon(graphics = {Text(extent = {{-98, 74}, {-48, 42}}, textString = "w0"), Text(extent = {{48, 74}, {98, 42}}, textString = "h")}), Diagram(), Documentation(info = "<HTML>
       <p><b>Modelling options</b></p>
       <p>If <tt>G</tt> is set to zero, the flowrate source is ideal; otherwise, the outgoing flowrate decreases proportionally to the outlet pressure.</p>
       <p>If the <tt>in_w0</tt> connector is wired, then the source pressure is given by the corresponding signal, otherwise it is fixed to <tt>p0</tt>.</p>
       <p>If the <tt>in_h</tt> connector is wired, then the source pressure is given by the corresponding signal, otherwise it is fixed to <tt>h</tt>.</p>
       </HTML>", revisions = "<html>
       <ul>
       <li><i>16 Dec 2004</i>
           by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
              Medium model and standard medium definition added.</li>
       <li><i>18 Jun 2004</i>
           by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
              Removed <tt>p0_fix</tt> and <tt>hfix</tt>; the connection of external signals is now detected automatically.</li>
       <li><i>1 Oct 2003</i>
           by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
              First release.</li>
       </ul>
       </html>"));
    end SourceMassFlow;

    model Flow1DFV  "1-dimensional fluid flow model for water/steam (finite volumes)"
      extends BaseClasses.Flow1DBase;
      Medium.ThermodynamicState[N] fluidState "Thermodynamic state of the fluid at the nodes";
      .Modelica.SIunits.Length omega_hyd "Wet perimeter (single tube)";
      .Modelica.SIunits.Pressure Dpfric "Pressure drop due to friction (total)";
      .Modelica.SIunits.Pressure Dpfric1 "Pressure drop due to friction (from inlet to capacitance)";
      .Modelica.SIunits.Pressure Dpfric2 "Pressure drop due to friction (from capacitance to outlet)";
      .Modelica.SIunits.Pressure Dpstat "Pressure drop due to static head";
      .Modelica.SIunits.MassFlowRate win "Flow rate at the inlet (single tube)";
      .Modelica.SIunits.MassFlowRate wout "Flow rate at the outlet (single tube)";
      Real Kf "Hydraulic friction coefficient";
      Real dwdt "Dynamic momentum term";
      Real Cf "Fanning friction factor";
      Medium.AbsolutePressure p(start = pstart, stateSelect = StateSelect.prefer) "Fluid pressure for property calculations";
      .Modelica.SIunits.MassFlowRate w(start = wnom / Nt) "Mass flow rate (single tube)";
      .Modelica.SIunits.MassFlowRate[N - 1] wbar(each start = wnom / Nt) "Average flow rate through volumes (single tube)";
      .Modelica.SIunits.Power[Nw] Q_single "Heat flows entering the volumes from the lateral boundary (single tube)";
      .Modelica.SIunits.Velocity[N] u "Fluid velocity";
      Medium.Temperature[N] T "Fluid temperature";
      Medium.SpecificEnthalpy[N] h(start = hstart) "Fluid specific enthalpy at the nodes";
      Medium.SpecificEnthalpy[N - 1] htilde(start = hstart[2:N], each stateSelect = StateSelect.prefer) "Enthalpy state variables";
      Medium.Density[N] rho "Fluid nodal density";
      .Modelica.SIunits.Mass M "Fluid mass (single tube)";
      .Modelica.SIunits.Mass Mtot "Fluid mass (total)";
      Real[N - 1] dMdt "Time derivative of mass in each cell between two nodes";
      replaceable Thermal.HeatTransfer.IdealHeatTransfer heatTransfer
       constrainedby ThermoPower.Thermal.BaseClasses.DistributedHeatTransferFV(
         redeclare package Medium = Medium,
         final Nf = N,
         final Nw = Nw,
         final Nt = Nt,
         final L = L,
         final A = A,
         final Dhyd = Dhyd,
         final omega = omega,
         final wnom = wnom / Nt,
         final w = w * ones(N),
         final fluidState = fluidState);
      ThermoPower.Thermal.DHTVolumes wall(final N = Nw) annotation(Dialog(enable = false), Placement(transformation(extent = {{-40, 40}, {40, 60}}, rotation = 0)));
    protected
      Density[N - 1] rhobar "Fluid average density";
      .Modelica.SIunits.SpecificVolume[N - 1] vbar "Fluid average specific volume";
      .Modelica.SIunits.DerDensityByEnthalpy[N] drdh "Derivative of density by enthalpy";
      .Modelica.SIunits.DerDensityByEnthalpy[N - 1] drbdh "Derivative of average density by enthalpy";
      .Modelica.SIunits.DerDensityByPressure[N] drdp "Derivative of density by pressure";
      .Modelica.SIunits.DerDensityByPressure[N - 1] drbdp "Derivative of average density by pressure";
    initial equation
      if initOpt == Choices.Init.Options.noInit then
      elseif initOpt == Choices.Init.Options.steadyState then
        der(htilde) = zeros(N - 1);
        if not Medium.singleState then
          der(p) = 0;
        end if;
      elseif initOpt == Choices.Init.Options.steadyStateNoP then
        der(htilde) = zeros(N - 1);
      elseif initOpt == Choices.Init.Options.steadyStateNoT and not Medium.singleState then
        der(p) = 0;
      else
        assert(false, "Unsupported initialisation option");
      end if;
    equation
      assert(FFtype == .ThermoPower.Choices.Flow1D.FFtypes.NoFriction or dpnom > 0, "dpnom=0 not supported, it is also used in the homotopy trasformation during the inizialization");
      omega_hyd = 4 * A / Dhyd;
      if FFtype == .ThermoPower.Choices.Flow1D.FFtypes.Kfnom then
        Kf = Kfnom * Kfc;
      elseif FFtype == .ThermoPower.Choices.Flow1D.FFtypes.OpPoint then
        Kf = dpnom * rhonom / (wnom / Nt) ^ 2 * Kfc;
      elseif FFtype == .ThermoPower.Choices.Flow1D.FFtypes.Cfnom then
        Cf = Cfnom * Kfc;
      elseif FFtype == .ThermoPower.Choices.Flow1D.FFtypes.Colebrook then
        Cf = f_colebrook(w, Dhyd / A, e, Medium.dynamicViscosity(fluidState[integer(N / 2)])) * Kfc;
      else
        Cf = 0;
      end if;
      Kf = Cf * omega_hyd * L / (2 * A ^ 3) "Relationship between friction coefficient and Fanning friction factor";
      assert(Kf >= 0, "Negative friction coefficient");
      if DynamicMomentum then
        dwdt = der(w);
      else
        dwdt = 0;
      end if;
      sum(dMdt) = (infl.m_flow + outfl.m_flow) / Nt "Mass balance";
      L / A * dwdt + outfl.p - infl.p + Dpstat + Dpfric = 0 "Momentum balance";
      Dpfric = Dpfric1 + Dpfric2 "Total pressure drop due to friction";
      if FFtype == .ThermoPower.Choices.Flow1D.FFtypes.NoFriction then
        Dpfric1 = 0;
        Dpfric2 = 0;
      elseif HydraulicCapacitance == .ThermoPower.Choices.Flow1D.HCtypes.Middle then
        Dpfric1 = homotopy(Kf * squareReg(win, wnom / Nt * wnf) * sum(vbar[1:integer((N - 1) / 2)]) / (N - 1), dpnom / 2 / wnom / Nt * win) "Pressure drop from inlet to capacitance";
        Dpfric2 = homotopy(Kf * squareReg(wout, wnom / Nt * wnf) * sum(vbar[1 + integer((N - 1) / 2):N - 1]) / (N - 1), dpnom / 2 / wnom / Nt * wout) "Pressure drop from capacitance to outlet";
      elseif HydraulicCapacitance == .ThermoPower.Choices.Flow1D.HCtypes.Upstream then
        Dpfric1 = 0 "Pressure drop from inlet to capacitance";
        Dpfric2 = homotopy(Kf * squareReg(wout, wnom / Nt * wnf) * sum(vbar) / (N - 1), dpnom / wnom / Nt * wout) "Pressure drop from capacitance to outlet";
      else
        Dpfric1 = homotopy(Kf * squareReg(win, wnom / Nt * wnf) * sum(vbar) / (N - 1), dpnom / wnom / Nt * win) "Pressure drop from inlet to capacitance";
        Dpfric2 = 0 "Pressure drop from capacitance to outlet";
      end if;
      Dpstat = if abs(dzdx) < 0.000001 then 0 else g * l * dzdx * sum(rhobar) "Pressure drop due to static head";
      for j in 1:Nw loop
        if Medium.singleState then
          A * l * rhobar[j] * der(htilde[j]) + wbar[j] * (h[j + 1] - h[j]) = Q_single[j] "Energy balance (pressure effects neglected)";
        else
          A * l * rhobar[j] * der(htilde[j]) + wbar[j] * (h[j + 1] - h[j]) - A * l * der(p) = Q_single[j] "Energy balance";
        end if;
        dMdt[j] = A * l * (drbdh[j] * der(htilde[j]) + drbdp[j] * der(p)) "Mass derivative for each volume";
        rhobar[j] = (rho[j] + rho[j + 1]) / 2;
        drbdp[j] = (drdp[j] + drdp[j + 1]) / 2;
        drbdh[j] = (drdh[j] + drdh[j + 1]) / 2;
        vbar[j] = 1 / rhobar[j];
        wbar[j] = homotopy(infl.m_flow / Nt - sum(dMdt[1:j - 1]) - dMdt[j] / 2, wnom / Nt);
      end for;
      for j in 1:N loop
        fluidState[j] = Medium.setState_ph(p, h[j]);
        T[j] = Medium.temperature(fluidState[j]);
        rho[j] = Medium.density(fluidState[j]);
        drdp[j] = if Medium.singleState then 0 else Medium.density_derp_h(fluidState[j]);
        drdh[j] = Medium.density_derh_p(fluidState[j]);
        u[j] = w / (rho[j] * A);
      end for;
      win = infl.m_flow / Nt;
      wout = -outfl.m_flow / Nt;
      Q_single = wall.Q / Nt;
      assert(HydraulicCapacitance == .ThermoPower.Choices.Flow1D.HCtypes.Upstream or HydraulicCapacitance == .ThermoPower.Choices.Flow1D.HCtypes.Middle or HydraulicCapacitance == .ThermoPower.Choices.Flow1D.HCtypes.Downstream, "Unsupported HydraulicCapacitance option");
      if HydraulicCapacitance == .ThermoPower.Choices.Flow1D.HCtypes.Middle then
        p = infl.p - Dpfric1 - Dpstat / 2;
        w = win;
      elseif HydraulicCapacitance == .ThermoPower.Choices.Flow1D.HCtypes.Upstream then
        p = infl.p;
        w = -outfl.m_flow / Nt;
      else
        p = outfl.p;
        w = win;
      end if;
      infl.h_outflow = htilde[1];
      outfl.h_outflow = htilde[N - 1];
      h[1] = inStream(infl.h_outflow);
      h[2:N] = htilde;
      connect(wall, heatTransfer.wall);
      Q = sum(heatTransfer.wall.Q) "Total heat flow through lateral boundary";
      M = sum(rhobar) * A * l "Fluid mass (single tube)";
      Mtot = M * Nt "Fluid mass (total)";
      Tr = noEvent(M / max(win, Modelica.Constants.eps)) "Residence time";
      annotation(Diagram(), Icon(graphics = {Text(extent = {{-100, -40}, {100, -80}}, textString = "%name")}), Documentation(info = "<HTML>
       <p>This model describes the flow of water or steam in a rigid tube. The basic modelling assumptions are:
       <ul><li>The fluid state is always one-phase (i.e. subcooled liquid or superheated steam).
       <li>Uniform velocity is assumed on the cross section, leading to a 1-D distributed parameter model.
       <li>Turbulent friction is always assumed; a small linear term is added to avoid numerical singularities at zero flowrate. The friction effects are not accurately computed in the laminar and transitional flow regimes, which however should not be an issue in most applications using water or steam as a working fluid.
       <li>The model is based on dynamic mass, momentum, and energy balances. The dynamic momentum term can be switched off, to avoid the fast oscillations that can arise from its coupling with the mass balance (sound wave dynamics).
       <li>The longitudinal heat diffusion term is neglected.
       <li>The energy balance equation is written by assuming a uniform pressure distribution; the compressibility effects are lumped at the inlet, at the outlet, or at the middle of the pipe.
       <li>The fluid flow can exchange thermal power through the lateral surface, which is represented by the <tt>wall</tt> connector. The actual heat flux must be computed by a connected component (heat transfer computation module).
       </ul>
       <p>The mass, momentum and energy balance equation are discretised with the finite volume method. The state variables are one pressure, one flowrate (optional) and N-1 specific enthalpies.
       <p>The turbulent friction factor can be either assumed as a constant, or computed by Colebrook's equation. In the former case, the friction factor can be supplied directly, or given implicitly by a specified operating point. In any case, the multiplicative correction coefficient <tt>Kfc</tt> can be used to modify the friction coefficient, e.g. to fit experimental data.
       <p>A small linear pressure drop is added to avoid numerical singularities at low or zero flowrate. The <tt>wnom</tt> parameter must be always specified: the additional linear pressure drop is such that it is equal to the turbulent pressure drop when the flowrate is equal to <tt>wnf*wnom</tt> (the default value is 1% of the nominal flowrate). Increase <tt>wnf</tt> if numerical instabilities occur in tubes with very low pressure drops.
       <p>Flow reversal is fully supported.
       <p><b>Modelling options</b></p>
       <p>Thermal variables (enthalpy, temperature, density) are computed in <tt>N</tt> equally spaced nodes, including the inlet (node 1) and the outlet (node N); <tt>N</tt> must be greater than or equal to 2.
       <p>The following options are available to specify the friction coefficient:
       <ul><li><tt>FFtype = FFtypes.Kfnom</tt>: the hydraulic friction coefficient <tt>Kf</tt> is set directly to <tt>Kfnom</tt>.
       <li><tt>FFtype = FFtypes.OpPoint</tt>: the hydraulic friction coefficient is specified by a nominal operating point (<tt>wnom</tt>,<tt>dpnom</tt>, <tt>rhonom</tt>).
       <li><tt>FFtype = FFtypes.Cfnom</tt>: the friction coefficient is computed by giving the (constant) value of the Fanning friction factor <tt>Cfnom</tt>.
       <li><tt>FFtype = FFtypes.Colebrook</tt>: the Fanning friction factor is computed by Colebrook's equation (assuming Re > 2100, e.g. turbulent flow).
       <li><tt>FFtype = FFtypes.NoFriction</tt>: no friction is assumed across the pipe.</ul>
       <p>The dynamic momentum term is included or neglected depending on the <tt>DynamicMomentum</tt> parameter.
       <p>If <tt>HydraulicCapacitance = HCtypes.Downstream</tt> (default option) then the compressibility effect depending on the pressure derivative is lumped at the outlet, while the optional dynamic momentum term depending on the flowrate is lumped at the inlet; therefore, the state variables are the outlet pressure and the inlet flowrate. If <tt>HydraulicCapacitance = HCtypes.Upstream</tt> the reverse takes place.
        If <tt>HydraulicCapacitance = HCtypes.Middle</tt>, the compressibility effect is lumped at the middle of the pipe; to use this option, an odd number of nodes N is required.
       <p>Start values for the pressure and flowrate state variables are specified by <tt>pstart</tt>, <tt>wstart</tt>. The start values for the node enthalpies are linearly distributed from <tt>hstartin</tt> at the inlet to <tt>hstartout</tt> at the outlet.
       <p>A bank of <tt>Nt</tt> identical tubes working in parallel can be modelled by setting <tt>Nt > 1</tt>. The geometric parameters always refer to a <i>single</i> tube.
       <p>This models makes the temperature and external heat flow distributions available to connected components through the <tt>wall</tt> connector. If other variables (e.g. the heat transfer coefficient) are needed by external components to compute the actual heat flow, the <tt>wall</tt> connector can be replaced by an extended version of the <tt>DHT</tt> connector.
       </HTML>", revisions = "<html>
       <ul>
       <li><i>16 Sep 2005</i>
           by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
              Option to lump compressibility at the middle added.</li>
       <li><i>30 May 2005</i>
           by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
              Initialisation support added.</li>
       <li><i>24 Mar 2005</i>
           by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
              <tt>FFtypes</tt> package and <tt>NoFriction</tt> option added.</li>
       <li><i>16 Dec 2004</i>
           by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
              Standard medium definition added.</li>
       <li><i>8 Oct 2004</i>
           by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
              Model now based on <tt>Flow1DBase</tt>.
       <li><i>24 Sep 2004</i>
           by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
              Removed <tt>wstart</tt>, <tt>pstart</tt>. Added <tt>pstartin</tt>, <tt>pstartout</tt>.
       <li><i>22 Jun 2004</i>
           by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
              Adapted to Modelica.Media.
       <li><i>15 Jan 2004</i>
           by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
              Computation of fluid velocity <i>u</i> added. Improved treatment of geometric parameters</li>.
       <li><i>1 Oct 2003</i>
           by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
              First release.</li>
       </ul>
       </html>
       "));
    end Flow1DFV;

    model SensT  "Temperature sensor for water-steam"
      extends Icons.Water.SensThrough;
      replaceable package Medium = StandardWater constrainedby Modelica.Media.Interfaces.PartialMedium;
      parameter Boolean allowFlowReversal = system.allowFlowReversal "= true to allow flow reversal, false restricts to design direction";
      outer ThermoPower.System system "System wide properties";
      .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy of the fluid";
      Medium.ThermodynamicState fluidState "Thermodynamic state of the fluid";
      FlangeA inlet(redeclare package Medium = Medium, m_flow(min = if allowFlowReversal then -Modelica.Constants.inf else 0)) annotation(Placement(transformation(extent = {{-80, -60}, {-40, -20}}, rotation = 0)));
      FlangeB outlet(redeclare package Medium = Medium, m_flow(max = if allowFlowReversal then +Modelica.Constants.inf else 0)) annotation(Placement(transformation(extent = {{40, -60}, {80, -20}}, rotation = 0)));
      Modelica.Blocks.Interfaces.RealOutput T annotation(Placement(transformation(extent = {{60, 40}, {100, 80}}, rotation = 0)));
    equation
      inlet.m_flow + outlet.m_flow = 0 "Mass balance";
      inlet.p = outlet.p "No pressure drop";
      h = homotopy(if not allowFlowReversal then inStream(inlet.h_outflow) else actualStream(inlet.h_outflow), inStream(inlet.h_outflow));
      fluidState = Medium.setState_ph(inlet.p, h);
      T = Medium.temperature(fluidState);
      inlet.h_outflow = inStream(outlet.h_outflow);
      inStream(inlet.h_outflow) = outlet.h_outflow;
      annotation(Diagram(), Icon(graphics = {Text(extent = {{-40, 84}, {38, 34}}, lineColor = {0, 0, 0}, textString = "T")}), Documentation(info = "<HTML>
       <p>This component can be inserted in a hydraulic circuit to measure the temperature of the fluid flowing through it.
       <p>Flow reversal is supported.
       </HTML>", revisions = "<html>
       <ul>
       <li><i>16 Dec 2004</i>
           by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
              Standard medium definition added.</li>
       <li><i>1 Jul 2004</i>
           by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
              Adapted to Modelica.Media.</li>
       <li><i>1 Oct 2003</i>
           by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
              First release.</li>
       </ul>
       </html>"));
    end SensT;

    model ValveLin  "Valve for water/steam flows with linear pressure drop"
      extends Icons.Water.Valve;
      replaceable package Medium = StandardWater constrainedby Modelica.Media.Interfaces.PartialMedium;
      parameter HydraulicConductance Kv "Nominal hydraulic conductance";
      parameter Boolean allowFlowReversal = system.allowFlowReversal "= true to allow flow reversal, false restricts to design direction";
      outer ThermoPower.System system "System wide properties";
      .Modelica.SIunits.MassFlowRate w "Mass flowrate";
      FlangeA inlet(redeclare package Medium = Medium, m_flow(min = if allowFlowReversal then -Modelica.Constants.inf else 0)) annotation(Placement(transformation(extent = {{-120, -20}, {-80, 20}}, rotation = 0)));
      FlangeB outlet(redeclare package Medium = Medium, m_flow(max = if allowFlowReversal then +Modelica.Constants.inf else 0)) annotation(Placement(transformation(extent = {{80, -20}, {120, 20}}, rotation = 0)));
      Modelica.Blocks.Interfaces.RealInput cmd annotation(Placement(transformation(origin = {0, 80}, extent = {{-20, -20}, {20, 20}}, rotation = 270)));
    equation
      inlet.m_flow + outlet.m_flow = 0 "Mass balance";
      w = Kv * cmd * (inlet.p - outlet.p) "Valve characteristics";
      w = inlet.m_flow;
      inlet.h_outflow = inStream(outlet.h_outflow);
      inStream(inlet.h_outflow) = outlet.h_outflow;
      annotation(Icon(graphics = {Text(extent = {{-100, -40}, {100, -74}}, textString = "%name")}), Diagram(), Documentation(info = "<HTML>
       <p>This very simple model provides a pressure drop which is proportional to the flowrate and to the <tt>cmd</tt> signal, without computing any fluid property.</p>
       </HTML>", revisions = "<html>
       <ul>
       <li><i>16 Dec 2004</i>
           by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
              Medium model and standard medium definition added.</li>
       <li><i>1 Oct 2003</i>
           by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
              First release.</li>
       </ul>
       </html>"));
    end ValveLin;

    function f_colebrook  "Fanning friction factor for water/steam flows"
      input .Modelica.SIunits.MassFlowRate w;
      input Real D_A;
      input Real e;
      input .Modelica.SIunits.DynamicViscosity mu;
      output Real f;
    protected
      Real Re;
    algorithm
      Re := abs(w) * D_A / mu;
      Re := if Re > 2100 then Re else 2100;
      f := 0.332 / .Modelica.Math.log(e / 3.7 + 5.47 / Re ^ 0.9) ^ 2;
      annotation(Documentation(info = "<HTML>
       <p>The Fanning friction factor is computed by Colebrook's equation, assuming turbulent, one-phase flow. For low Reynolds numbers, the limit value for turbulent flow is returned.
       <p><b>Revision history:</b></p>
       <ul>
       <li><i>1 Oct 2003</i>
           by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
              First release.</li>
       </ul>
       </HTML>"));
    end f_colebrook;

    package BaseClasses  "Contains partial models"
      partial model Flow1DBase  "Basic interface for 1-dimensional water/steam fluid flow models"
        replaceable package Medium = StandardWater constrainedby Modelica.Media.Interfaces.PartialMedium;
        extends Icons.Water.Tube;
        constant Real pi = Modelica.Constants.pi;
        parameter Integer N(min = 2) = 2 "Number of nodes for thermal variables";
        parameter Integer Nw = N - 1 "Number of volumes on the wall interface";
        parameter Integer Nt = 1 "Number of tubes in parallel";
        parameter .Modelica.SIunits.Distance L "Tube length" annotation(Evaluate = true);
        parameter .Modelica.SIunits.Position H = 0 "Elevation of outlet over inlet";
        parameter .Modelica.SIunits.Area A "Cross-sectional area (single tube)";
        parameter .Modelica.SIunits.Length omega "Perimeter of heat transfer surface (single tube)";
        parameter .Modelica.SIunits.MassFlowRate wnom "Nominal mass flowrate (total)";
        parameter .ThermoPower.Choices.Flow1D.FFtypes FFtype = .ThermoPower.Choices.Flow1D.FFtypes.NoFriction "Friction Factor Type" annotation(Evaluate = true);
        parameter Real Kfnom(unit = "Pa.kg/(m3.kg2/s2)", min = 0) = 0 "Nominal hydraulic resistance coefficient";
        parameter .Modelica.SIunits.Pressure dpnom = 0 "Nominal pressure drop (friction term only!)";
        parameter Density rhonom = 0 "Nominal inlet density";
        parameter .Modelica.SIunits.Length Dhyd = omega / pi "Hydraulic Diameter (single tube)";
        parameter Real Cfnom = 0 "Nominal Fanning friction factor";
        parameter Real e = 0 "Relative roughness (ratio roughness/diameter)";
        parameter Boolean DynamicMomentum = false "Inertial phenomena accounted for" annotation(Evaluate = true);
        parameter .ThermoPower.Choices.Flow1D.HCtypes HydraulicCapacitance = .ThermoPower.Choices.Flow1D.HCtypes.Downstream "Location of the hydraulic capacitance";
        parameter Boolean avoidInletEnthalpyDerivative = true "Avoid inlet enthalpy derivative";
        parameter Boolean allowFlowReversal = system.allowFlowReversal "= true to allow flow reversal, false restricts to design direction";
        outer ThermoPower.System system "System wide properties";
        parameter Choices.FluidPhase.FluidPhases FluidPhaseStart = Choices.FluidPhase.FluidPhases.Liquid "Fluid phase (only for initialization!)" annotation(Dialog(tab = "Initialisation"));
        parameter .Modelica.SIunits.Pressure pstart = 100000.0 "Pressure start value" annotation(Dialog(tab = "Initialisation"));
        parameter .Modelica.SIunits.SpecificEnthalpy hstartin = if FluidPhaseStart == Choices.FluidPhase.FluidPhases.Liquid then 100000.0 else if FluidPhaseStart == Choices.FluidPhase.FluidPhases.Steam then 3000000.0 else 1000000.0 "Inlet enthalpy start value" annotation(Dialog(tab = "Initialisation"));
        parameter .Modelica.SIunits.SpecificEnthalpy hstartout = if FluidPhaseStart == Choices.FluidPhase.FluidPhases.Liquid then 100000.0 else if FluidPhaseStart == Choices.FluidPhase.FluidPhases.Steam then 3000000.0 else 1000000.0 "Outlet enthalpy start value" annotation(Dialog(tab = "Initialisation"));
        parameter .Modelica.SIunits.SpecificEnthalpy[N] hstart = linspace(hstartin, hstartout, N) "Start value of enthalpy vector (initialized by default)" annotation(Dialog(tab = "Initialisation"));
        parameter Real wnf = 0.02 "Fraction of nominal flow rate at which linear friction equals turbulent friction";
        parameter Real Kfc = 1 "Friction factor correction coefficient";
        parameter Choices.Init.Options initOpt = Choices.Init.Options.noInit "Initialisation option" annotation(Dialog(tab = "Initialisation"));
        constant Real g = Modelica.Constants.g_n;
        function squareReg = ThermoPower.Functions.squareReg;
        FlangeA infl(h_outflow(start = hstartin), redeclare package Medium = Medium, m_flow(start = wnom, min = if allowFlowReversal then -Modelica.Constants.inf else 0)) annotation(Placement(transformation(extent = {{-120, -20}, {-80, 20}}, rotation = 0)));
        FlangeB outfl(h_outflow(start = hstartout), redeclare package Medium = Medium, m_flow(start = -wnom, max = if allowFlowReversal then +Modelica.Constants.inf else 0)) annotation(Placement(transformation(extent = {{80, -20}, {120, 20}}, rotation = 0)));
        .Modelica.SIunits.Power Q "Total heat flow through the lateral boundary (all Nt tubes)";
        .Modelica.SIunits.Time Tr "Residence time";
        final parameter Real dzdx = H / L "Slope" annotation(Evaluate = true);
        final parameter .Modelica.SIunits.Length l = L / (N - 1) "Length of a single volume" annotation(Evaluate = true);
        annotation(Documentation(info = "<HTML>
         Basic interface of the <tt>Flow1D</tt> models, containing the common parameters and connectors.
         </HTML>
         ", revisions = "<html>
         <ul>
         <li><i>23 Jul 2007</i>
             by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
                Added hstart for more detailed initialization of enthalpy vector.</li>
         <li><i>30 May 2005</i>
             by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
                Initialisation support added.</li>
         <li><i>24 Mar 2005</i>
             by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
                <tt>FFtypes</tt> package and <tt>NoFriction</tt> option added.</li>
         <li><i>16 Dec 2004</i>
             by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
                Standard medium definition added.</li>
         <li><i>8 Oct 2004</i>
             by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
                Created.</li>
         </ul>
         </html>"), Diagram(), Icon());
      end Flow1DBase;
    end BaseClasses;
    annotation(Documentation(info = "<HTML>
     This package contains models of physical processes and components using water or steam as working fluid.
     <p>All models use the <tt>StandardWater</tt> medium model by default, which is in turn set to <tt>Modelica.Media.Water.StandardWater</tt> at the library level. It is of course possible to redeclare the medium model to any model extending <tt>Modelica.Media.Interfaces.PartialMedium</tt> (or <tt>PartialTwoPhaseMedium</tt> for 2-phase models). This can be done by directly setting Medium in the parameter dialog, or through a local package definition, as shown e.g. in <tt>Test.TestMixerSlowFast</tt>. The latter solution allows to easily replace the medium model for an entire set of components.
     <p>All models with dynamic equations provide initialisation support. Set the <tt>initOpt</tt> parameter to the appropriate value:
     <ul>
     <li><tt>Choices.Init.Options.noInit</tt>: no initialisation
     <li><tt>Choices.Init.Options.steadyState</tt>: full steady-state initialisation
     <li><tt>Choices.Init.Options.steadyStateNoP</tt>: steady-state initialisation (except pressure)
     <li><tt>Choices.Init.Options.steadyStateNoT</tt>: steady-state initialisation (except temperature)
     </ul>
     The latter options can be useful when two or more components are connected directly so that they will have the same pressure or temperature, to avoid over-specified systems of initial equations.
     </HTML>"));
  end Water;

  type HydraulicConductance = Real(final quantity = "HydraulicConductance", final unit = "(kg/s)/Pa");
  type HydraulicResistance = Real(final quantity = "HydraulicResistance", final unit = "Pa/(kg/s)");
  type Density = Modelica.SIunits.Density(start = 40) "generic start value";
  type AbsoluteTemperature = .Modelica.SIunits.Temperature(start = 300, nominal = 500) "generic temperature";
  annotation(Documentation(info = "<html>
   <b>General Information</b>
   <p>The ThermoPower library is an open-source <a href=\"http://www.modelica.org/libraries\">Modelica library</a>for the dynamic modelling of thermal power plants and energy conversion systems. It provides basic components for system-level modelling, in particular for the study of control systems in traditional and innovative power plants and energy conversion systems.</p>
   <p>The library is hosted by <a href=\"http://sourceforge.net/projects/thermopower/\">sourceforge.net</a> and has been under continuous development at Politecnico di Milano since 2002. It has been applied to the dynamic modelling of steam generators, combined-cycle power plants, III- and IV-generation nuclear power plants, direct steam generation solar plants, organic Rankine cycle plants, and cryogenic circuits for nuclear fusion applications. The main author is Francesco Casella, with contributions from Alberto Leva, Matilde Ratti, Luca Savoldelli, Roberto Bonifetto, Stefano Boni, and many others. The library is licensed under the <b><a href=\"http://www.modelica.org/licenses/ModelicaLicense2\">Modelica License 2</a></b>. The library has been developed as a tool for research in the field of energy system control at the Dipartimento di Elettronica, Informazione e Bioingegneria of Politecnico di Milano and progressively enhanced as new projects were undertaken there. It has been released as open source for the benefit of the community, but without any guarantee of support or completeness of documentation.</p>
   <p>The latest official release of the library is ThermoPower 2.1, which is compatible with Modelica 2.2 and Modelica Standard Library 2.2.x. This release is now quite old. From 2009 to 2012, the development of the library focused on: </p>
   <ul>
   <li>Conversion to Modelica 3.x (new graphical annotations, use of enumerations) </li>
   <li>Use of stream connectors, compatible with the Modelica.Fluid library, allowing multiple-way connections (see <a href=\"http://dx.doi.org/10.3384/ecp09430078\">paper</a>) </li>
   <li>Use of the homotopy operator for improved initialization (see <a href=\"https://www.modelica.org/events/modelica2011/Proceedings/pages/papers/04_2_ID_131_a_fv.pdf\">paper</a>) </li>
   <li>Bugfixing</li>
   </ul>
   <p>Until 2012, the library was developed using the tool <a href=\"http://www.3ds.com/products/catia/portfolio/dymola\">Dymola</a>, and could only be used within that tool, due to limitations of other Modelica tools available at the time. An official version was never released during that period, because we kept on experimenting new features, some of them experimental (e.g., homotopy-based initialization), so the library never reached a stable state. The plan is to release a revision 3.0, which will run in Dymola, and will incorporate all these changes. In the meantime, you can obtain this version of the library by anonymous SVN checkout from this URL:<br><br><a href=\"svn://svn.code.sf.net/p/thermopower/svn/branches/release.3.0\">svn://svn.code.sf.net/p/thermopower/svn/branches/release.3.0</a><br><br>
   If you are running Windows, we recommend using the excellent <a href=\"http://tortoisesvn.net/\">TortoiseSVN</a> client to checkout the library.</p>
   <p>Since 2013, the development started focusing on three main lines.
   <ol>
   <li>We are working towards making the library fully compliant to Modelica 3.2rev2 and to the Modelica Standard Library 3.2.1, in order to be usable with other Modelica tools. The library is currently being tested with OpenModelica, and is expected to run satisfactorily in that tool within the year 2013. </li>
   <li>The second development line is to improve the structure of the Flow1D models, for greater flexibility and ease of use. In particular, we are changing the design of the distributed heat ports, which had several shortcomings in the original design, and adding replaceable models for the heat transfer and friction models. The new Flow1D models will be incompatible with the old ones, which will be kept (but deprecated) for backwards compatibility. </li>
   <li>The last development is to change the way initial conditions are specified. The current design relies on initial equations being automatically generated by the tool, based on start attributes, which has several problems if you want to use the library with different Modelica tools and get the same results everywhere. Doing this right might eventually lead to a library which is not backwards-compatible with earlier versions.</li>
   </ol></p>
   <p>Eventually, these improvements will be incorporated in the 3.1 release. You can have a look at the work in progress by anonymous SVN checkout from this URL:<br><br><a href=\"svn://svn.code.sf.net/p/thermopower/svn/trunk\">svn://svn.code.sf.net/p/thermopower/svn/trunk</a></p>
   <p>To give you an idea on the structure and content of the library, the automatically generated&nbsp;documentation of the 2.1 release can be browsed on-line <a href=\"http://thermopower.sourceforge.net/help/ThermoPower.html\">here</a>.</p>
   <p>If you want to get involved in the development, or you need some information, please contact the main developer <a href=\"mailto://francesco.casella@polimi.it\">francesco.casella@polimi.it</a>.</p>
   <p><b>References</b></p>
   <p>A general description of the library and on the modelling principles can be found in the papers: </p>
   <p><ul>
   <li>F. Casella, A. Leva, &QUOT;Modelling of distributed thermo-hydraulic processes using Modelica&QUOT;, <i>Proceedings of the MathMod &apos;03 Conference</i>, Wien , Austria, February 2003. </li>
   <li>F. Casella, A. Leva, &QUOT;Modelica open library for power plant simulation: design and experimental validation&QUOT;, <i>Proceedings of the 2003 Modelica Conference</i>, Link&ouml;ping, Sweden, November 2003, pp. 41-50. (<a href=\"http://www.modelica.org/Conference2003/papers/h08_Leva.pdf\">Available online</a>) </li>
   <li>F. Casella, A. Leva, &QUOT;Simulazione di impianti termoidraulici con strumenti object-oriented&QUOT;, <i>Atti convegno ANIPLA Enersis 2004,</i> Milano, Italy, April 2004 (in Italian). </li>
   <li>F. Casella, A. Leva, &QUOT;Object-oriented library for thermal power plant simulation&QUOT;, <i>Proceedings of the Eurosis Industrial Simulation Conference 2004 (ISC-2004)</i>, Malaga, Spain, June 2004. </li>
   <li>F. Casella, A. Leva, &QUOT;Simulazione object-oriented di impianti di generazione termoidraulici per studi di sistema&QUOT;, <i>Atti convegno nazionale ANIPLA 2004</i>, Milano, Italy, September 2004 (in Italian).</li>
   <li>Francesco Casella and Alberto Leva, &ldquo;Modelling of Thermo-Hydraulic Power Generation Processes Using Modelica&rdquo;. <i>Mathematical and Computer Modeling of Dynamical Systems</i>, vol. 12, n. 1, pp. 19-33, Feb. 2006. <a href=\"http://dx.doi.org/10.1080/13873950500071082\">Online</a>. </li>
   <li>Francesco Casella, J. G. van Putten and Piero Colonna, &ldquo;Dynamic Simulation of a Biomass-Fired Power Plant: a Comparison Between Causal and A-Causal Modular Modeling&rdquo;. In <i>Proceedings of 2007 ASME International Mechanical Engineering Congress and Exposition</i>, Seattle, Washington, USA, Nov. 11-15, 2007, paper IMECE2007-41091 (Best paper award). </li>
   </ul></p>
   <p><br/>Other papers about the library and its applications:</p>
   <p><ul>
   <li>F. Casella, F. Schiavo, &QUOT;Modelling and Simulation of Heat Exchangers in Modelica with Finite Element Methods&QUOT;, <i>Proceedings of the 2003 Modelica Conference</i>, Link&ouml;ping, Sweden, 2003, pp. 343-352. (<a href=\"http://www.modelica.org/Conference2003/papers/h22_Schiavo.pdf\">Available online</a>) </li>
   <li>A. Cammi, M.E. Ricotti, F. Casella, F. Schiavo, &QUOT;New modelling strategy for IRIS dynamic response simulation&QUOT;, <i>Proc. 5th International Conference on Nuclear Option in Countries with Small and Medium Electricity Grids</i>, Dubrovnik, Croatia, May 2004.</li>
   <li>A. Cammi, F. Casella, M.E. Ricotti, F. Schiavo, &QUOT;Object-oriented Modelling for Integral Nuclear Reactors Dynamic Dimulation&QUOT;, <i>Proceedings of the International Conference on Integrated Modeling &AMP; Analysis in Applied Control &AMP; Automation</i>, Genova, Italy, October 2004. </li>
   <li>Antonio Cammi, Francesco Casella, Marco Ricotti and Francesco Schiavo, &ldquo;Object-Oriented Modeling, Simulation and Control of the IRIS Nuclear Power Plant with Modelica&rdquo;. In <i>Proceedings 4th International Modelica Conference</i>, Hamburg, Germany,Mar. 7-8, 2005, pp. 423-432. <a href=\"http://www.modelica.org/events/Conference2005/online_proceedings/Session5/Session5b3.pdf\">Online</a>. </li>
   <li>A. Cammi, F. Casella, M. E. Ricotti, F. Schiavo, G. D. Storrick, &QUOT;Object-oriented Simulation for the Control of the IRIS Nuclear Power Plant&QUOT;, <i>Proceedings of the IFAC World Congress, </i>Prague, Czech Republic, July 2005 </li>
   <li>Francesco Casella and Francesco Pretolani, &ldquo;Fast Start-up of a Combined-Cycle Power Plant: a Simulation Study with Modelica&rdquo;. In <i>Proceedings 5th International Modelica Conference</i>, Vienna, Austria, Sep. 6-8, 2006, pp. 3-10. <a href=\"http://www.modelica.org/events/modelica2006/Proceedings/sessions/Session1a1.pdf\">Online</a>. </li>
   <li>Francesco Casella, &ldquo;Object-Oriented Modelling of Two-Phase Fluid Flows by the Finite Volume Method&rdquo;. In <i>Proceedings 5th Mathmod Vienna</i>, Vienna, Austria, Feb. 8-10, 2006. </li>
   <li>Andrea Bartolini, Francesco Casella, Alberto Leva and Valeria Motterle, &ldquo;A Simulation Study of the Flue Gas Path Control System in a Coal-Fired Power Plant&rdquo;. In <i>Proceedings ANIPLA International Congress 2006</i>, Rome, Italy,vNov. 13-15, 2006. </li>
   <li>Francesco Schiavo and Francesco Casella, &ldquo;Object-oriented modelling and simulation of heat exchangers with finite element methods&rdquo;. <i>Mathematical and Computer Modeling of Dynamical Sytems</i>, vol. 13, n. 3, pp. 211-235, Jun. 2007. <a href=\"http://dx.doi.org/10.1080/13873950600821766\">Online</a>. </li>
   <li>Laura Savoldi Richard, Francesco Casella, Barbara Fiori and Roberto Zanino, &ldquo;Development of the Cryogenic Circuit Conductor and Coil (4C) Code for thermal-hydraulic modelling of ITER superconducting coils&rdquo;. In <i>Presented at the 22nd International Cryogenic Engineering Conference ICEC22</i>, Seoul, Korea, July 21-25, 2008. </li>
   <li>Francesco Casella, &ldquo;Object-Oriented Modelling of Power Plants: a Structured Approach&rdquo;. In <i>Proceedings of the IFAC Symposium on Power Plants and Power Systems Control</i>, Tampere, Finland, July 5-8, 2009. </li>
   <li>Laura Savoldi Richard, Francesco Casella, Barbara Fiori and Roberto Zanino, &ldquo;The 4C code for the cryogenic circuit conductor and coil modeling in ITER&rdquo;. <i>Cryogenics</i>, vol. 50, n. 3, pp. 167-176, Mar 2010. <a href=\"http://dx.doi.org/10.1016/j.cryogenics.2009.07.008\">Online</a>. </li>
   <li>Antonio Cammi, Francesco Casella, Marco Enrico Ricotti and Francesco Schiavo, &ldquo;An object-oriented approach to simulation of IRIS dynamic response&rdquo;. <i>Progress in Nuclear Energy</i>, vol. 53, n. 1, pp. 48-58, Jan. 2011. <a href=\"http://dx.doi.org/10.1016/j.pnucene.2010.09.004\">Online</a>. </li>
   <li>Francesco Casella and Piero Colonna, &ldquo;Development of a Modelica dynamic model of solar supercritical CO2 Brayton cycle power plants for control studies&rdquo;. In <i>Proceedings of the Supercritical CO2 Power Cycle Symposium</i>, Boulder, Colorado, USA, May 24-25, 2011, pp. 1-7. <a href=\"http://www.sco2powercyclesymposium.org/resource_center/system_modeling_control\">Online</a>. </li>
   <li>Roberto Bonifetto, Francesco Casella, Laura Savoldi Richard and Roberto Zanino, &ldquo;Dynamic modeling of a SHe closed loop with the 4C code&rdquo;. In <i>Transactions of the Cryogenic Engineering Conference - CEC: Advances in Cryogenic Engineering</i>, Spokane, Washington, USA, Jun. 13-17, 2011, pp. 1-8. </li>
   <li>Roberto Zanino, Roberto Bonifetto, Francesco Casella and Laura Savoldi Richard, &ldquo;Validation of the 4C code against data from the HELIOS loop at CEA Grenoble&rdquo;. <i>Cryogenics</i>, vol. 0, pp. 1-6, 2012. In press; available online 6 May 2012. <a href=\"http://dx.doi.org/10.1016/j.cryogenics.2012.04.010\">Online</a>. </li>
   <li>Francesco Casella and Piero Colonna, &ldquo;Dynamic modelling of IGCC power plants&rdquo;. <i>Applied Thermal Engineering</i>, vol. 35, pp. 91-111, 2012. <a href=\"http://dx.doi.org/10.1016/j.applthermaleng.2011.10.011\">Online</a>. </li>
   </ul></p>

   <b>Release notes:</b>
   <p><b></font><font style=\"font-size: 10pt; \">Version 2.1 (<i>6 Jul 2009</i>)</b></p>
   <p>The 2.1 release of ThermoPower contains several additions and a few bug fixes with respect to version 2.0. We tried to keep the new version backwards-compatible with the old one, but there might be a few cases where small adaptations could be required.</p><p>ThermoPower 2.1 requires the Modelica Standard Library version 2.2.1 or 2.2.2. It has been tested with Dymola 6.1 (using MSL 2.2.1) and with Dymola 7.1 (using MSL 2.2.2). It is planned to be usable also with other tools, in particular OpenModelica, MathModelica and SimulationX, but this is not possible with the currently released versions of those tools. It is expected that this should become at least partially possible within the year 2009. </p><p>ThermoPower 2.1 is the last major revision compatible with Modelica 2.1 and the Modelica Standard Library 2.2.x. The next version is planned to use Modelica 3.1 and the Modelica Standard Library 3.1. It will use use stream connectors, which generalize the concept of Flange connectors, lifting the restrictions that only two complementary connectors can be bound.</p><p>This is a list of the main changes with respect to v. 2.0</p>
   <li><ul>
   <li>New PowerPlants package, containing a library of high-level reusable components for the modelling of combined-cycle power plants, including full models that can be simulated. </li>
   <li>New examples cases in the Examples package. </li>
   <li>New components in the Electrical package, to model the generator-grid connection by the swing equation </li>
   <li>Three-way junctions (FlowJoin and FlowSplit) now have an option to describe unidirectional flow at each flange. This feature can substantially enhance numerical robustness and simulation performance in all cases when it is known a priori that no flow reversal will occur. </li>
   <li>The Flow1D and Flow1D2ph models are now restricted to positive flow direction, since it was found that it is not possible to describe flow reversal consistently with the average-density approach adopted in this library. For full flow reversal support please use the Flow1Dfem model, which does not have any restriction in this respect. </li>
   <li>A bug in Flow1D and Flow1D2ph has been corrected, which caused significant errors in the mass balance under dynamic conditions; this was potentially critical in closed-loop models, but has now been resolved.&nbsp; </li>
   <li>The connectors for lumped- and distribute-parameters heat transfer with variable heat transfer coefficients have been split: HThtc and DHThtc now have an output qualifier on the h.t.c., while HThtc_in and DHThtc_in have an input qualifier. This was necessary to avoid incorrect connections, and is also required by tools to correctly checked if a model is balanced. This change should have no impact on most user-developed models. </li>
   </ul></li>
   </ul></p>
   <p><b>Version 2.0 (<i>10 Jun 2005</i>)</b></p>
   <li><ul>
   <li>The new Modelica 2.2 standard library is used. </li>
   <li>The ThermoPower library is now based on the Modelica.Media standard library for fluid property calculations. All the component models use a Modelica.Media compliant interface to specify the medium model. Standard water and gas models from the Modelica.Media library can be used, as well as custom-built water and gas models, compliant with the Modelica.Media interfaces. </li>
   <li>Fully functional gas components are now available, including model for gas compressors and turbines, as well as compact gas turbine unit models. </li>
   <li>Steady-state initialisation support has been added to all dynamic models. </li>
   <li>Some components are still under development, and could be changed in the final 2.0 release: </li>
   <li><ul>
   <li>Moving boundary model for two-phase flow in once-through evaporators. </li>
   <li>Stress models for headers and turbines. </li>
   </ul></li>
   </ul></li>
   </ul></p>
   <p><b>Version 1.2 (<i>18 Nov 2004</i>)</b></p>
   <li><ul>
   <li>Valve and pump models restructured using inheritance. </li>
   <li>Simple model of a steam turbine unit added (requires the Modelica.Media library). </li>
   <li>CISE example restructured and moved to the <code>Examples</code> package. </li>
   <li>Preliminary version of gas components added in the <code>Gas</code> package. </li>
   <li>Finite element model of thermohydraulic two-phase flow added. </li>
   <li>Simplified models for the connection to the power system added in the <code>Electrical</code> package. </li>
   </ul></li>
   </ul></p>
   <p><b>Version 1.1 (<i>15 Feb 2004</i>)</b></p>
   <li><ul>
   <li>No default values for parameters whose values must be set explicitly by the user. </li>
   <li>Description of the meaning of the model variables added. </li>
   <li><code>Pump</code>, <code>PumpMech</code>, <code>Accumulator</code> models added. </li>
   <li>More rational geometric parameters for <code>Flow1D*</code> models. </li>
   <li><code>Flow1D</code> model corrected to avoid numerical problems when the phase transition boundaries cross the nodes. </li>
   <li><code>Flow1D2phDB</code> model updated. </li>
   <li><code>Flow1D2phChen</code> models with two-phase heat transfer added. </li>
   </ul></li>
   </ul></p>
   <p><b>Version 1.0 (<i>20 Oct 2003</i>)</b></p>
   <li><ul>
   <li>First release in the public domain</li>
   </ul></li>
   </ul></p>
   <p><b></font><font style=\"font-size: 12pt; \">License agreement</b></p>
   <p>The ThermoPower package is licensed by Politecnico di Milano under the <b><a href=\"http://www.modelica.org/licenses/ModelicaLicense2\">Modelica License 2</a></b>. </p>
   <p><h4>Copyright &copy; 2002-2013, Politecnico di Milano.</h4></p>
   </html>"), uses(Modelica(version = "3.2.1")), version = "3.1");
end ThermoPower;

package ModelicaServices  "ModelicaServices (OpenModelica implementation) - Models and functions used in the Modelica Standard Library requiring a tool specific implementation"
  extends Modelica.Icons.Package;

  package Machine
    extends Modelica.Icons.Package;
    final constant Real eps = 0.000000000000001 "Biggest number such that 1.0 + eps = 1.0";
    final constant Real small = 1e-60 "Smallest number such that small and -small are representable on the machine";
    final constant Real inf = 1e+60 "Biggest Real number such that inf and -inf are representable on the machine";
    final constant Integer Integer_inf = OpenModelica.Internal.Architecture.integerMax() "Biggest Integer number such that Integer_inf and -Integer_inf are representable on the machine";
    annotation(Documentation(info = "<html>
     <p>
     Package in which processor specific constants are defined that are needed
     by numerical algorithms. Typically these constants are not directly used,
     but indirectly via the alias definition in
     <a href=\"modelica://Modelica.Constants\">Modelica.Constants</a>.
     </p>
     </html>"));
  end Machine;
  annotation(Protection(access = Access.hide), preferredView = "info", version = "3.2.1", versionBuild = 2, versionDate = "2013-08-14", dateModified = "2013-08-14 08:44:41Z", revisionId = "$Id:: package.mo 6931 2013-08-14 11:38:51Z #$", uses(Modelica(version = "3.2.1")), conversion(noneFromVersion = "1.0", noneFromVersion = "1.1", noneFromVersion = "1.2"), Documentation(info = "<html>
   <p>
   This package contains a set of functions and models to be used in the
   Modelica Standard Library that requires a tool specific implementation.
   These are:
   </p>

   <ul>
   <li> <a href=\"modelica://ModelicaServices.Animation.Shape\">Shape</a>
        provides a 3-dim. visualization of elementary
        mechanical objects. It is used in
   <a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape</a>
        via inheritance.</li>

   <li> <a href=\"modelica://ModelicaServices.Animation.Surface\">Surface</a>
        provides a 3-dim. visualization of
        moveable parameterized surface. It is used in
   <a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Surface\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Surface</a>
        via inheritance.</li>

   <li> <a href=\"modelica://ModelicaServices.ExternalReferences.loadResource\">loadResource</a>
        provides a function to return the absolute path name of an URI or a local file name. It is used in
   <a href=\"modelica://Modelica.Utilities.Files.loadResource\">Modelica.Utilities.Files.loadResource</a>
        via inheritance.</li>

   <li> <a href=\"modelica://ModelicaServices.Machine\">ModelicaServices.Machine</a>
        provides a package of machine constants. It is used in
   <a href=\"modelica://Modelica.Constants\">Modelica.Constants</a>.</li>

   <li> <a href=\"modelica://ModelicaServices.Types.SolverMethod\">Types.SolverMethod</a>
        provides a string defining the integration method to solve differential equations in
        a clocked discretized continuous-time partition (see Modelica 3.3 language specification).
        It is not yet used in the Modelica Standard Library, but in the Modelica_Synchronous library
        that provides convenience blocks for the clock operators of Modelica version &ge; 3.3.</li>
   </ul>

   <p>
   This is the default implementation, if no tool-specific implementation is available.
   This ModelicaServices package provides only \"dummy\" models that do nothing.
   </p>

   <p>
   <b>Licensed by DLR and Dassault Syst&egrave;mes AB under the Modelica License 2</b><br>
   Copyright &copy; 2009-2013, DLR and Dassault Syst&egrave;mes AB.
   </p>

   <p>
   <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
   </p>

   </html>"));
end ModelicaServices;

package Modelica  "Modelica Standard Library - Version 3.2.1 (Build 2)"
  extends Modelica.Icons.Package;

  package Blocks  "Library of basic input/output control blocks (continuous, discrete, logical, table blocks)"
    extends Modelica.Icons.Package;

    package Interfaces  "Library of connectors and partial models for input/output blocks"
      extends Modelica.Icons.InterfacesPackage;
      connector RealInput = input Real "'input Real' as connector" annotation(defaultComponentName = "u", Icon(graphics = {Polygon(lineColor = {0, 0, 127}, fillColor = {0, 0, 127}, fillPattern = FillPattern.Solid, points = {{-100.0, 100.0}, {100.0, 0.0}, {-100.0, -100.0}})}, coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}, preserveAspectRatio = true, initialScale = 0.2)), Diagram(coordinateSystem(preserveAspectRatio = true, initialScale = 0.2, extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(lineColor = {0, 0, 127}, fillColor = {0, 0, 127}, fillPattern = FillPattern.Solid, points = {{0.0, 50.0}, {100.0, 0.0}, {0.0, -50.0}, {0.0, 50.0}}), Text(lineColor = {0, 0, 127}, extent = {{-10.0, 60.0}, {-10.0, 85.0}}, textString = "%name")}), Documentation(info = "<html>
        <p>
        Connector with one input signal of type Real.
        </p>
        </html>"));
      connector RealOutput = output Real "'output Real' as connector" annotation(defaultComponentName = "y", Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100.0, -100.0}, {100.0, 100.0}}, initialScale = 0.1), graphics = {Polygon(lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-100.0, 100.0}, {100.0, 0.0}, {-100.0, -100.0}})}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100.0, -100.0}, {100.0, 100.0}}, initialScale = 0.1), graphics = {Polygon(lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-100.0, 50.0}, {0.0, 0.0}, {-100.0, -50.0}}), Text(lineColor = {0, 0, 127}, extent = {{30.0, 60.0}, {30.0, 110.0}}, textString = "%name")}), Documentation(info = "<html>
        <p>
        Connector with one output signal of type Real.
        </p>
        </html>"));

      partial block SO  "Single Output continuous control block"
        extends Modelica.Blocks.Icons.Block;
        RealOutput y "Connector of Real output signal" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}}, rotation = 0)));
        annotation(Documentation(info = "<html>
         <p>
         Block has one continuous Real output signal.
         </p>
         </html>"));
      end SO;

      partial block SignalSource  "Base class for continuous signal source"
        extends SO;
        parameter Real offset = 0 "Offset of output signal y";
        parameter .Modelica.SIunits.Time startTime = 0 "Output y = offset for time < startTime";
        annotation(Documentation(info = "<html>
         <p>
         Basic block for Real sources of package Blocks.Sources.
         This component has one continuous Real output signal y
         and two parameters (offset, startTime) to shift the
         generated signal.
         </p>
         </html>"));
      end SignalSource;
      annotation(Documentation(info = "<HTML>
       <p>
       This package contains interface definitions for
       <b>continuous</b> input/output blocks with Real,
       Integer and Boolean signals. Furthermore, it contains
       partial models for continuous and discrete blocks.
       </p>

       </html>", revisions = "<html>
       <ul>
       <li><i>Oct. 21, 2002</i>
              by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
              and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
              Added several new interfaces.
       <li><i>Oct. 24, 1999</i>
              by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
              RealInputSignal renamed to RealInput. RealOutputSignal renamed to
              output RealOutput. GraphBlock renamed to BlockIcon. SISOreal renamed to
              SISO. SOreal renamed to SO. I2SOreal renamed to M2SO.
              SignalGenerator renamed to SignalSource. Introduced the following
              new models: MIMO, MIMOs, SVcontrol, MVcontrol, DiscreteBlockIcon,
              DiscreteBlock, DiscreteSISO, DiscreteMIMO, DiscreteMIMOs,
              BooleanBlockIcon, BooleanSISO, BooleanSignalSource, MI2BooleanMOs.</li>
       <li><i>June 30, 1999</i>
              by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
              Realized a first version, based on an existing Dymola library
              of Dieter Moormann and Hilding Elmqvist.</li>
       </ul>
       </html>"));
    end Interfaces;

    package Sources  "Library of signal source blocks generating Real and Boolean signals"
      extends Modelica.Icons.SourcesPackage;

      block Constant  "Generate constant signal of type Real"
        parameter Real k(start = 1) "Constant output value";
        extends .Modelica.Blocks.Interfaces.SO;
      equation
        y = k;
        annotation(defaultComponentName = "const", Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-80, 68}, {-80, -80}}, color = {192, 192, 192}), Polygon(points = {{-80, 90}, {-88, 68}, {-72, 68}, {-80, 90}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-90, -70}, {82, -70}}, color = {192, 192, 192}), Polygon(points = {{90, -70}, {68, -62}, {68, -78}, {90, -70}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, 0}, {80, 0}}, color = {0, 0, 0}), Text(extent = {{-150, -150}, {150, -110}}, lineColor = {0, 0, 0}, textString = "k=%k")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(points = {{-80, 90}, {-86, 68}, {-74, 68}, {-80, 90}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, 68}, {-80, -80}}, color = {95, 95, 95}), Line(points = {{-80, 0}, {80, 0}}, color = {0, 0, 255}, thickness = 0.5), Line(points = {{-90, -70}, {82, -70}}, color = {95, 95, 95}), Polygon(points = {{90, -70}, {68, -64}, {68, -76}, {90, -70}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Text(extent = {{-83, 92}, {-30, 74}}, lineColor = {0, 0, 0}, textString = "y"), Text(extent = {{70, -80}, {94, -100}}, lineColor = {0, 0, 0}, textString = "time"), Text(extent = {{-101, 8}, {-81, -12}}, lineColor = {0, 0, 0}, textString = "k")}), Documentation(info = "<html>
         <p>
         The Real output y is a constant signal:
         </p>

         <p>
         <img src=\"modelica://Modelica/Resources/Images/Blocks/Sources/Constant.png\"
              alt=\"Constant.png\">
         </p>
         </html>"));
      end Constant;

      block Step  "Generate step signal of type Real"
        parameter Real height = 1 "Height of step";
        extends .Modelica.Blocks.Interfaces.SignalSource;
      equation
        y = offset + (if time < startTime then 0 else height);
        annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-80, 68}, {-80, -80}}, color = {192, 192, 192}), Polygon(points = {{-80, 90}, {-88, 68}, {-72, 68}, {-80, 90}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-90, -70}, {82, -70}}, color = {192, 192, 192}), Polygon(points = {{90, -70}, {68, -62}, {68, -78}, {90, -70}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -70}, {0, -70}, {0, 50}, {80, 50}}, color = {0, 0, 0}), Text(extent = {{-150, -150}, {150, -110}}, lineColor = {0, 0, 0}, textString = "startTime=%startTime")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(points = {{-80, 90}, {-86, 68}, {-74, 68}, {-80, 90}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, 68}, {-80, -80}}, color = {95, 95, 95}), Line(points = {{-80, -18}, {0, -18}, {0, 50}, {80, 50}}, color = {0, 0, 255}, thickness = 0.5), Line(points = {{-90, -70}, {82, -70}}, color = {95, 95, 95}), Polygon(points = {{90, -70}, {68, -64}, {68, -76}, {90, -70}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Text(extent = {{70, -80}, {94, -100}}, lineColor = {0, 0, 0}, textString = "time"), Text(extent = {{-21, -72}, {25, -90}}, lineColor = {0, 0, 0}, textString = "startTime"), Line(points = {{0, -18}, {0, -70}}, color = {95, 95, 95}), Text(extent = {{-68, -36}, {-22, -54}}, lineColor = {0, 0, 0}, textString = "offset"), Line(points = {{-13, 50}, {-13, -17}}, color = {95, 95, 95}), Polygon(points = {{0, 50}, {-21, 50}, {0, 50}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Polygon(points = {{-13, -18}, {-16, -5}, {-10, -5}, {-13, -18}, {-13, -18}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Polygon(points = {{-13, 50}, {-16, 37}, {-10, 37}, {-13, 50}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Text(extent = {{-68, 26}, {-22, 8}}, lineColor = {0, 0, 0}, textString = "height"), Polygon(points = {{-13, -70}, {-16, -57}, {-10, -57}, {-13, -70}, {-13, -70}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-13, -18}, {-13, -70}}, color = {95, 95, 95}), Polygon(points = {{-13, -18}, {-16, -31}, {-10, -31}, {-13, -18}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Text(extent = {{-72, 100}, {-31, 80}}, lineColor = {0, 0, 0}, textString = "y")}), Documentation(info = "<html>
         <p>
         The Real output y is a step signal:
         </p>

         <p>
         <img src=\"modelica://Modelica/Resources/Images/Blocks/Sources/Step.png\"
              alt=\"Step.png\">
         </p>

         </html>"));
      end Step;
      annotation(Documentation(info = "<HTML>
       <p>
       This package contains <b>source</b> components, i.e., blocks which
       have only output signals. These blocks are used as signal generators
       for Real, Integer and Boolean signals.
       </p>

       <p>
       All Real source signals (with the exception of the Constant source)
       have at least the following two parameters:
       </p>

       <table border=1 cellspacing=0 cellpadding=2>
         <tr><td valign=\"top\"><b>offset</b></td>
             <td valign=\"top\">Value which is added to the signal</td>
         </tr>
         <tr><td valign=\"top\"><b>startTime</b></td>
             <td valign=\"top\">Start time of signal. For time &lt; startTime,
                       the output y is set to offset.</td>
         </tr>
       </table>

       <p>
       The <b>offset</b> parameter is especially useful in order to shift
       the corresponding source, such that at initial time the system
       is stationary. To determine the corresponding value of offset,
       usually requires a trimming calculation.
       </p>
       </html>", revisions = "<html>
       <ul>
       <li><i>October 21, 2002</i>
              by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
              and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
              Integer sources added. Step, TimeTable and BooleanStep slightly changed.</li>
       <li><i>Nov. 8, 1999</i>
              by <a href=\"mailto:clauss@eas.iis.fhg.de\">Christoph Clau&szlig;</a>,
              <a href=\"mailto:Andre.Schneider@eas.iis.fraunhofer.de\">Andre.Schneider@eas.iis.fraunhofer.de</a>,
              <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
              New sources: Exponentials, TimeTable. Trapezoid slightly enhanced
              (nperiod=-1 is an infinite number of periods).</li>
       <li><i>Oct. 31, 1999</i>
              by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
              <a href=\"mailto:clauss@eas.iis.fhg.de\">Christoph Clau&szlig;</a>,
              <a href=\"mailto:Andre.Schneider@eas.iis.fraunhofer.de\">Andre.Schneider@eas.iis.fraunhofer.de</a>,
              All sources vectorized. New sources: ExpSine, Trapezoid,
              BooleanConstant, BooleanStep, BooleanPulse, SampleTrigger.
              Improved documentation, especially detailed description of
              signals in diagram layer.</li>
       <li><i>June 29, 1999</i>
              by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
              Realized a first version, based on an existing Dymola library
              of Dieter Moormann and Hilding Elmqvist.</li>
       </ul>
       </html>"));
    end Sources;

    package Icons  "Icons for Blocks"
      extends Modelica.Icons.IconsPackage;

      partial block Block  "Basic graphical layout of input/output block"  annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, -100}, {100, 100}}, lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-150, 150}, {150, 110}}, textString = "%name", lineColor = {0, 0, 255})}), Documentation(info = "<html>
        <p>
        Block that has only the basic icon for an input/output
        block (no declarations, no equations). Most blocks
        of package Modelica.Blocks inherit directly or indirectly
        from this block.
        </p>
        </html>")); end Block;
    end Icons;
    annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100.0, -100.0}, {100.0, 100.0}}, initialScale = 0.1), graphics = {Rectangle(origin = {0.0, 35.1488}, fillColor = {255, 255, 255}, extent = {{-30.0, -20.1488}, {30.0, 20.1488}}), Rectangle(origin = {0.0, -34.8512}, fillColor = {255, 255, 255}, extent = {{-30.0, -20.1488}, {30.0, 20.1488}}), Line(origin = {-51.25, 0.0}, points = {{21.25, -35.0}, {-13.75, -35.0}, {-13.75, 35.0}, {6.25, 35.0}}), Polygon(origin = {-40.0, 35.0}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{10.0, 0.0}, {-5.0, 5.0}, {-5.0, -5.0}}), Line(origin = {51.25, 0.0}, points = {{-21.25, 35.0}, {13.75, 35.0}, {13.75, -35.0}, {-6.25, -35.0}}), Polygon(origin = {40.0, -35.0}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-10.0, 0.0}, {5.0, 5.0}, {5.0, -5.0}})}), Documentation(info = "<html>
     <p>
     This library contains input/output blocks to build up block diagrams.
     </p>

     <dl>
     <dt><b>Main Author:</b>
     <dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a><br>
         Deutsches Zentrum f&uuml;r Luft und Raumfahrt e. V. (DLR)<br>
         Oberpfaffenhofen<br>
         Postfach 1116<br>
         D-82230 Wessling<br>
         email: <A HREF=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</A><br>
     </dl>
     <p>
     Copyright &copy; 1998-2013, Modelica Association and DLR.
     </p>
     <p>
     <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
     </p>
     </html>", revisions = "<html>
     <ul>
     <li><i>June 23, 2004</i>
            by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
            Introduced new block connectors and adapted all blocks to the new connectors.
            Included subpackages Continuous, Discrete, Logical, Nonlinear from
            package ModelicaAdditions.Blocks.
            Included subpackage ModelicaAdditions.Table in Modelica.Blocks.Sources
            and in the new package Modelica.Blocks.Tables.
            Added new blocks to Blocks.Sources and Blocks.Logical.
            </li>
     <li><i>October 21, 2002</i>
            by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
            and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
            New subpackage Examples, additional components.
            </li>
     <li><i>June 20, 2000</i>
            by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and
            Michael Tiller:<br>
            Introduced a replaceable signal type into
            Blocks.Interfaces.RealInput/RealOutput:
     <pre>
        replaceable type SignalType = Real
     </pre>
            in order that the type of the signal of an input/output block
            can be changed to a physical type, for example:
     <pre>
        Sine sin1(outPort(redeclare type SignalType=Modelica.SIunits.Torque))
     </pre>
           </li>
     <li><i>Sept. 18, 1999</i>
            by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
            Renamed to Blocks. New subpackages Math, Nonlinear.
            Additional components in subpackages Interfaces, Continuous
            and Sources. </li>
     <li><i>June 30, 1999</i>
            by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
            Realized a first version, based on an existing Dymola library
            of Dieter Moormann and Hilding Elmqvist.</li>
     </ul>
     </html>"));
  end Blocks;

  package Media  "Library of media property models"
    extends Modelica.Icons.Package;

    package Interfaces  "Interfaces for media models"
      extends Modelica.Icons.InterfacesPackage;

      partial package PartialMedium  "Partial medium properties (base package of all media packages)"
        extends Modelica.Media.Interfaces.Types;
        extends Modelica.Icons.MaterialPropertiesPackage;
        constant Modelica.Media.Interfaces.Choices.IndependentVariables ThermoStates "Enumeration type for independent variables";
        constant String mediumName = "unusablePartialMedium" "Name of the medium";
        constant String[:] substanceNames = {mediumName} "Names of the mixture substances. Set substanceNames={mediumName} if only one substance.";
        constant String[:] extraPropertiesNames = fill("", 0) "Names of the additional (extra) transported properties. Set extraPropertiesNames=fill(\"\",0) if unused";
        constant Boolean singleState "= true, if u and d are not a function of pressure";
        constant Boolean reducedX = true "= true if medium contains the equation sum(X) = 1.0; set reducedX=true if only one substance (see docu for details)";
        constant Boolean fixedX = false "= true if medium contains the equation X = reference_X";
        constant MassFraction[nX] reference_X = fill(1 / nX, nX) "Default mass fractions of medium";
        constant AbsolutePressure p_default = 101325 "Default value for pressure of medium (for initialization)";
        constant Temperature T_default = Modelica.SIunits.Conversions.from_degC(20) "Default value for temperature of medium (for initialization)";
        constant MassFraction[nX] X_default = reference_X "Default value for mass fractions of medium (for initialization)";
        final constant Integer nS = size(substanceNames, 1) "Number of substances" annotation(Evaluate = true);
        constant Integer nX = nS "Number of mass fractions" annotation(Evaluate = true);
        constant Integer nXi = if fixedX then 0 else if reducedX then nS - 1 else nS "Number of structurally independent mass fractions (see docu for details)" annotation(Evaluate = true);
        final constant Integer nC = size(extraPropertiesNames, 1) "Number of extra (outside of standard mass-balance) transported properties" annotation(Evaluate = true);
        replaceable record FluidConstants = Modelica.Media.Interfaces.Types.Basic.FluidConstants "Critical, triple, molecular and other standard data of fluid";

        replaceable record ThermodynamicState  "Minimal variable set that is available as input argument to every medium function"
          extends Modelica.Icons.Record;
        end ThermodynamicState;

        replaceable partial model BaseProperties  "Base properties (p, d, T, h, u, R, MM and, if applicable, X and Xi) of a medium"
          InputAbsolutePressure p "Absolute pressure of medium";
          InputMassFraction[nXi] Xi(start = reference_X[1:nXi]) "Structurally independent mass fractions";
          InputSpecificEnthalpy h "Specific enthalpy of medium";
          Density d "Density of medium";
          Temperature T "Temperature of medium";
          MassFraction[nX] X(start = reference_X) "Mass fractions (= (component mass)/total mass  m_i/m)";
          SpecificInternalEnergy u "Specific internal energy of medium";
          SpecificHeatCapacity R "Gas constant (of mixture if applicable)";
          MolarMass MM "Molar mass (of mixture or single fluid)";
          ThermodynamicState state "Thermodynamic state record for optional functions";
          parameter Boolean preferredMediumStates = false "= true if StateSelect.prefer shall be used for the independent property variables of the medium" annotation(Evaluate = true, Dialog(tab = "Advanced"));
          parameter Boolean standardOrderComponents = true "If true, and reducedX = true, the last element of X will be computed from the other ones";
          .Modelica.SIunits.Conversions.NonSIunits.Temperature_degC T_degC = Modelica.SIunits.Conversions.to_degC(T) "Temperature of medium in [degC]";
          .Modelica.SIunits.Conversions.NonSIunits.Pressure_bar p_bar = Modelica.SIunits.Conversions.to_bar(p) "Absolute pressure of medium in [bar]";
          connector InputAbsolutePressure = input .Modelica.SIunits.AbsolutePressure "Pressure as input signal connector";
          connector InputSpecificEnthalpy = input .Modelica.SIunits.SpecificEnthalpy "Specific enthalpy as input signal connector";
          connector InputMassFraction = input .Modelica.SIunits.MassFraction "Mass fraction as input signal connector";
        equation
          if standardOrderComponents then
            Xi = X[1:nXi];
            if fixedX then
              X = reference_X;
            end if;
            if reducedX and not fixedX then
              X[nX] = 1 - sum(Xi);
            end if;
            for i in 1:nX loop
              assert(X[i] >= -0.00001 and X[i] <= 1 + 0.00001, "Mass fraction X[" + String(i) + "] = " + String(X[i]) + "of substance " + substanceNames[i] + "\nof medium " + mediumName + " is not in the range 0..1");
            end for;
          end if;
          assert(p >= 0.0, "Pressure (= " + String(p) + " Pa) of medium \"" + mediumName + "\" is negative\n(Temperature = " + String(T) + " K)");
          annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, lineColor = {0, 0, 255}), Text(extent = {{-152, 164}, {152, 102}}, textString = "%name", lineColor = {0, 0, 255})}), Documentation(info = "<html>
           <p>
           Model <b>BaseProperties</b> is a model within package <b>PartialMedium</b>
           and contains the <b>declarations</b> of the minimum number of
           variables that every medium model is supposed to support.
           A specific medium inherits from model <b>BaseProperties</b> and provides
           the equations for the basic properties.</p>
           <p>
           The BaseProperties model contains the following <b>7+nXi variables</b>
           (nXi is the number of independent mass fractions defined in package
           PartialMedium):
           </p>
           <table border=1 cellspacing=0 cellpadding=2>
             <tr><td valign=\"top\"><b>Variable</b></td>
                 <td valign=\"top\"><b>Unit</b></td>
                 <td valign=\"top\"><b>Description</b></td></tr>
             <tr><td valign=\"top\">T</td>
                 <td valign=\"top\">K</td>
                 <td valign=\"top\">temperature</td></tr>
             <tr><td valign=\"top\">p</td>
                 <td valign=\"top\">Pa</td>
                 <td valign=\"top\">absolute pressure</td></tr>
             <tr><td valign=\"top\">d</td>
                 <td valign=\"top\">kg/m3</td>
                 <td valign=\"top\">density</td></tr>
             <tr><td valign=\"top\">h</td>
                 <td valign=\"top\">J/kg</td>
                 <td valign=\"top\">specific enthalpy</td></tr>
             <tr><td valign=\"top\">u</td>
                 <td valign=\"top\">J/kg</td>
                 <td valign=\"top\">specific internal energy</td></tr>
             <tr><td valign=\"top\">Xi[nXi]</td>
                 <td valign=\"top\">kg/kg</td>
                 <td valign=\"top\">independent mass fractions m_i/m</td></tr>
             <tr><td valign=\"top\">R</td>
                 <td valign=\"top\">J/kg.K</td>
                 <td valign=\"top\">gas constant</td></tr>
             <tr><td valign=\"top\">M</td>
                 <td valign=\"top\">kg/mol</td>
                 <td valign=\"top\">molar mass</td></tr>
           </table>
           <p>
           In order to implement an actual medium model, one can extend from this
           base model and add <b>5 equations</b> that provide relations among
           these variables. Equations will also have to be added in order to
           set all the variables within the ThermodynamicState record state.</p>
           <p>
           If standardOrderComponents=true, the full composition vector X[nX]
           is determined by the equations contained in this base class, depending
           on the independent mass fraction vector Xi[nXi].</p>
           <p>Additional <b>2 + nXi</b> equations will have to be provided
           when using the BaseProperties model, in order to fully specify the
           thermodynamic conditions. The input connector qualifier applied to
           p, h, and nXi indirectly declares the number of missing equations,
           permitting advanced equation balance checking by Modelica tools.
           Please note that this doesn't mean that the additional equations
           should be connection equations, nor that exactly those variables
           should be supplied, in order to complete the model.
           For further information, see the Modelica.Media User's guide, and
           Section 4.7 (Balanced Models) of the Modelica 3.0 specification.</p>
           </html>"));
        end BaseProperties;

        replaceable partial function setState_pTX  "Return thermodynamic state as function of p, T and composition X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input MassFraction[:] X = reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state record";
        end setState_pTX;

        replaceable partial function setState_phX  "Return thermodynamic state as function of p, h and composition X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction[:] X = reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state record";
        end setState_phX;

        replaceable partial function setState_psX  "Return thermodynamic state as function of p, s and composition X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          input MassFraction[:] X = reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state record";
        end setState_psX;

        replaceable partial function setState_dTX  "Return thermodynamic state as function of d, T and composition X or Xi"
          extends Modelica.Icons.Function;
          input Density d "Density";
          input Temperature T "Temperature";
          input MassFraction[:] X = reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state record";
        end setState_dTX;

        replaceable partial function setSmoothState  "Return thermodynamic state so that it smoothly approximates: if x > 0 then state_a else state_b"
          extends Modelica.Icons.Function;
          input Real x "m_flow or dp";
          input ThermodynamicState state_a "Thermodynamic state if x > 0";
          input ThermodynamicState state_b "Thermodynamic state if x < 0";
          input Real x_small(min = 0) "Smooth transition in the region -x_small < x < x_small";
          output ThermodynamicState state "Smooth thermodynamic state for all x (continuous and differentiable)";
          annotation(Documentation(info = "<html>
           <p>
           This function is used to approximate the equation
           </p>
           <pre>
               state = <b>if</b> x &gt; 0 <b>then</b> state_a <b>else</b> state_b;
           </pre>

           <p>
           by a smooth characteristic, so that the expression is continuous and differentiable:
           </p>

           <pre>
              state := <b>smooth</b>(1, <b>if</b> x &gt;  x_small <b>then</b> state_a <b>else</b>
                                 <b>if</b> x &lt; -x_small <b>then</b> state_b <b>else</b> f(state_a, state_b));
           </pre>

           <p>
           This is performed by applying function <b>Media.Common.smoothStep</b>(..)
           on every element of the thermodynamic state record.
           </p>

           <p>
           If <b>mass fractions</b> X[:] are approximated with this function then this can be performed
           for all <b>nX</b> mass fractions, instead of applying it for nX-1 mass fractions and computing
           the last one by the mass fraction constraint sum(X)=1. The reason is that the approximating function has the
           property that sum(state.X) = 1, provided sum(state_a.X) = sum(state_b.X) = 1.
           This can be shown by evaluating the approximating function in the abs(x) &lt; x_small
           region (otherwise state.X is either state_a.X or state_b.X):
           </p>

           <pre>
               X[1]  = smoothStep(x, X_a[1] , X_b[1] , x_small);
               X[2]  = smoothStep(x, X_a[2] , X_b[2] , x_small);
                  ...
               X[nX] = smoothStep(x, X_a[nX], X_b[nX], x_small);
           </pre>

           <p>
           or
           </p>

           <pre>
               X[1]  = c*(X_a[1]  - X_b[1])  + (X_a[1]  + X_b[1])/2
               X[2]  = c*(X_a[2]  - X_b[2])  + (X_a[2]  + X_b[2])/2;
                  ...
               X[nX] = c*(X_a[nX] - X_b[nX]) + (X_a[nX] + X_b[nX])/2;
               c     = (x/x_small)*((x/x_small)^2 - 3)/4
           </pre>

           <p>
           Summing all mass fractions together results in
           </p>

           <pre>
               sum(X) = c*(sum(X_a) - sum(X_b)) + (sum(X_a) + sum(X_b))/2
                      = c*(1 - 1) + (1 + 1)/2
                      = 1
           </pre>

           </html>"));
        end setSmoothState;

        replaceable partial function dynamicViscosity  "Return dynamic viscosity"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output DynamicViscosity eta "Dynamic viscosity";
        end dynamicViscosity;

        replaceable partial function thermalConductivity  "Return thermal conductivity"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output ThermalConductivity lambda "Thermal conductivity";
        end thermalConductivity;

        replaceable partial function pressure  "Return pressure"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output AbsolutePressure p "Pressure";
        end pressure;

        replaceable partial function temperature  "Return temperature"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output Temperature T "Temperature";
        end temperature;

        replaceable partial function density  "Return density"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output Density d "Density";
        end density;

        replaceable partial function specificEnthalpy  "Return specific enthalpy"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificEnthalpy h "Specific enthalpy";
        end specificEnthalpy;

        replaceable partial function specificInternalEnergy  "Return specific internal energy"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificEnergy u "Specific internal energy";
        end specificInternalEnergy;

        replaceable partial function specificEntropy  "Return specific entropy"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificEntropy s "Specific entropy";
        end specificEntropy;

        replaceable partial function specificGibbsEnergy  "Return specific Gibbs energy"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificEnergy g "Specific Gibbs energy";
        end specificGibbsEnergy;

        replaceable partial function specificHelmholtzEnergy  "Return specific Helmholtz energy"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificEnergy f "Specific Helmholtz energy";
        end specificHelmholtzEnergy;

        replaceable partial function specificHeatCapacityCp  "Return specific heat capacity at constant pressure"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificHeatCapacity cp "Specific heat capacity at constant pressure";
        end specificHeatCapacityCp;

        replaceable partial function specificHeatCapacityCv  "Return specific heat capacity at constant volume"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificHeatCapacity cv "Specific heat capacity at constant volume";
        end specificHeatCapacityCv;

        replaceable partial function isentropicExponent  "Return isentropic exponent"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output IsentropicExponent gamma "Isentropic exponent";
        end isentropicExponent;

        replaceable partial function isentropicEnthalpy  "Return isentropic enthalpy"
          extends Modelica.Icons.Function;
          input AbsolutePressure p_downstream "Downstream pressure";
          input ThermodynamicState refState "Reference state for entropy";
          output SpecificEnthalpy h_is "Isentropic enthalpy";
          annotation(Documentation(info = "<html>
           <p>
           This function computes an isentropic state transformation:
           </p>
           <ol>
           <li> A medium is in a particular state, refState.</li>
           <li> The enthalpy at another state (h_is) shall be computed
                under the assumption that the state transformation from refState to h_is
                is performed with a change of specific entropy ds = 0 and the pressure of state h_is
                is p_downstream and the composition X upstream and downstream is assumed to be the same.</li>
           </ol>

           </html>"));
        end isentropicEnthalpy;

        replaceable partial function velocityOfSound  "Return velocity of sound"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output VelocityOfSound a "Velocity of sound";
        end velocityOfSound;

        replaceable partial function isobaricExpansionCoefficient  "Return overall the isobaric expansion coefficient beta"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output IsobaricExpansionCoefficient beta "Isobaric expansion coefficient";
          annotation(Documentation(info = "<html>
           <pre>
           beta is defined as  1/v * der(v,T), with v = 1/d, at constant pressure p.
           </pre>
           </html>"));
        end isobaricExpansionCoefficient;

        replaceable partial function isothermalCompressibility  "Return overall the isothermal compressibility factor"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output .Modelica.SIunits.IsothermalCompressibility kappa "Isothermal compressibility";
          annotation(Documentation(info = "<html>
           <pre>

           kappa is defined as - 1/v * der(v,p), with v = 1/d at constant temperature T.

           </pre>
           </html>"));
        end isothermalCompressibility;

        replaceable partial function density_derp_h  "Return density derivative w.r.t. pressure at const specific enthalpy"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output DerDensityByPressure ddph "Density derivative w.r.t. pressure";
        end density_derp_h;

        replaceable partial function density_derh_p  "Return density derivative w.r.t. specific enthalpy at constant pressure"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output DerDensityByEnthalpy ddhp "Density derivative w.r.t. specific enthalpy";
        end density_derh_p;

        replaceable partial function molarMass  "Return the molar mass of the medium"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output MolarMass MM "Mixture molar mass";
        end molarMass;

        replaceable function specificEnthalpy_pTX  "Return specific enthalpy from p, T, and X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input MassFraction[:] X = reference_X "Mass fractions";
          output SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := specificEnthalpy(setState_pTX(p, T, X));
          annotation(inverse(T = temperature_phX(p, h, X)));
        end specificEnthalpy_pTX;

        replaceable function temperature_phX  "Return temperature from p, h, and X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction[:] X = reference_X "Mass fractions";
          output Temperature T "Temperature";
        algorithm
          T := temperature(setState_phX(p, h, X));
        end temperature_phX;

        replaceable function density_phX  "Return density from p, h, and X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction[:] X = reference_X "Mass fractions";
          output Density d "Density";
        algorithm
          d := density(setState_phX(p, h, X));
        end density_phX;

        replaceable function temperature_psX  "Return temperature from p,s, and X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          input MassFraction[:] X = reference_X "Mass fractions";
          output Temperature T "Temperature";
        algorithm
          T := temperature(setState_psX(p, s, X));
          annotation(inverse(s = specificEntropy_pTX(p, T, X)));
        end temperature_psX;

        replaceable function density_psX  "Return density from p, s, and X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          input MassFraction[:] X = reference_X "Mass fractions";
          output Density d "Density";
        algorithm
          d := density(setState_psX(p, s, X));
        end density_psX;

        replaceable function specificEnthalpy_psX  "Return specific enthalpy from p, s, and X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          input MassFraction[:] X = reference_X "Mass fractions";
          output SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := specificEnthalpy(setState_psX(p, s, X));
        end specificEnthalpy_psX;

        type MassFlowRate = .Modelica.SIunits.MassFlowRate(quantity = "MassFlowRate." + mediumName, min = -100000.0, max = 100000.0) "Type for mass flow rate with medium specific attributes";
        annotation(Documentation(info = "<html>
         <p>
         <b>PartialMedium</b> is a package and contains all <b>declarations</b> for
         a medium. This means that constants, models, and functions
         are defined that every medium is supposed to support
         (some of them are optional). A medium package
         inherits from <b>PartialMedium</b> and provides the
         equations for the medium. The details of this package
         are described in
         <a href=\"modelica://Modelica.Media.UsersGuide\">Modelica.Media.UsersGuide</a>.
         </p>
         </html>", revisions = "<html>

         </html>"));
      end PartialMedium;

      partial package PartialPureSubstance  "Base class for pure substances of one chemical substance"
        extends PartialMedium(final reducedX = true, final fixedX = true);

        replaceable function setState_ph  "Return thermodynamic state from p and h"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          output ThermodynamicState state "Thermodynamic state record";
        algorithm
          state := setState_phX(p, h, fill(0, 0));
        end setState_ph;

        replaceable function density_ph  "Return density from p and h"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          output Density d "Density";
        algorithm
          d := density_phX(p, h, fill(0, 0));
        end density_ph;

        replaceable function temperature_ph  "Return temperature from p and h"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          output Temperature T "Temperature";
        algorithm
          T := temperature_phX(p, h, fill(0, 0));
        end temperature_ph;

        replaceable function pressure_dT  "Return pressure from d and T"
          extends Modelica.Icons.Function;
          input Density d "Density";
          input Temperature T "Temperature";
          output AbsolutePressure p "Pressure";
        algorithm
          p := pressure(setState_dTX(d, T, fill(0, 0)));
        end pressure_dT;

        replaceable function specificEnthalpy_dT  "Return specific enthalpy from d and T"
          extends Modelica.Icons.Function;
          input Density d "Density";
          input Temperature T "Temperature";
          output SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := specificEnthalpy(setState_dTX(d, T, fill(0, 0)));
        end specificEnthalpy_dT;

        replaceable function specificEnthalpy_ps  "Return specific enthalpy from p and s"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          output SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := specificEnthalpy_psX(p, s, fill(0, 0));
        end specificEnthalpy_ps;

        replaceable function temperature_ps  "Return temperature from p and s"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          output Temperature T "Temperature";
        algorithm
          T := temperature_psX(p, s, fill(0, 0));
        end temperature_ps;

        replaceable function density_ps  "Return density from p and s"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          output Density d "Density";
        algorithm
          d := density_psX(p, s, fill(0, 0));
        end density_ps;

        replaceable function specificEnthalpy_pT  "Return specific enthalpy from p and T"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          output SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := specificEnthalpy_pTX(p, T, fill(0, 0));
        end specificEnthalpy_pT;

        replaceable function density_pT  "Return density from p and T"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          output Density d "Density";
        algorithm
          d := density(setState_pTX(p, T, fill(0, 0)));
        end density_pT;

        redeclare replaceable partial model extends BaseProperties  end BaseProperties;
      end PartialPureSubstance;

      partial package PartialTwoPhaseMedium  "Base class for two phase medium of one substance"
        extends PartialPureSubstance(redeclare record FluidConstants = Modelica.Media.Interfaces.Types.TwoPhase.FluidConstants);
        constant Boolean smoothModel = false "True if the (derived) model should not generate state events";
        constant Boolean onePhase = false "True if the (derived) model should never be called with two-phase inputs";
        constant FluidConstants[nS] fluidConstants "Constant data for the fluid";

        redeclare replaceable record extends ThermodynamicState  "Thermodynamic state of two phase medium"
          FixedPhase phase(min = 0, max = 2) "Phase of the fluid: 1 for 1-phase, 2 for two-phase, 0 for not known, e.g., interactive use";
        end ThermodynamicState;

        redeclare replaceable partial model extends BaseProperties  "Base properties (p, d, T, h, u, R, MM, sat) of two phase medium"
          SaturationProperties sat "Saturation properties at the medium pressure";
        end BaseProperties;

        replaceable partial function setDewState  "Return the thermodynamic state on the dew line"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation point";
          input FixedPhase phase(min = 1, max = 2) = 1 "Phase: default is one phase";
          output ThermodynamicState state "Complete thermodynamic state info";
        end setDewState;

        replaceable partial function setBubbleState  "Return the thermodynamic state on the bubble line"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation point";
          input FixedPhase phase(min = 1, max = 2) = 1 "Phase: default is one phase";
          output ThermodynamicState state "Complete thermodynamic state info";
        end setBubbleState;

        redeclare replaceable partial function extends setState_dTX  "Return thermodynamic state as function of d, T and composition X or Xi"
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
        end setState_dTX;

        redeclare replaceable partial function extends setState_phX  "Return thermodynamic state as function of p, h and composition X or Xi"
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
        end setState_phX;

        redeclare replaceable partial function extends setState_psX  "Return thermodynamic state as function of p, s and composition X or Xi"
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
        end setState_psX;

        redeclare replaceable partial function extends setState_pTX  "Return thermodynamic state as function of p, T and composition X or Xi"
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
        end setState_pTX;

        replaceable partial function bubbleEnthalpy  "Return bubble point specific enthalpy"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output .Modelica.SIunits.SpecificEnthalpy hl "Boiling curve specific enthalpy";
        end bubbleEnthalpy;

        replaceable partial function dewEnthalpy  "Return dew point specific enthalpy"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output .Modelica.SIunits.SpecificEnthalpy hv "Dew curve specific enthalpy";
        end dewEnthalpy;

        replaceable partial function bubbleEntropy  "Return bubble point specific entropy"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output .Modelica.SIunits.SpecificEntropy sl "Boiling curve specific entropy";
        end bubbleEntropy;

        replaceable partial function dewEntropy  "Return dew point specific entropy"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output .Modelica.SIunits.SpecificEntropy sv "Dew curve specific entropy";
        end dewEntropy;

        replaceable partial function bubbleDensity  "Return bubble point density"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output Density dl "Boiling curve density";
        end bubbleDensity;

        replaceable partial function dewDensity  "Return dew point density"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output Density dv "Dew curve density";
        end dewDensity;

        replaceable partial function saturationPressure  "Return saturation pressure"
          extends Modelica.Icons.Function;
          input Temperature T "Temperature";
          output AbsolutePressure p "Saturation pressure";
        end saturationPressure;

        replaceable partial function saturationTemperature  "Return saturation temperature"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          output Temperature T "Saturation temperature";
        end saturationTemperature;

        replaceable partial function saturationTemperature_derp  "Return derivative of saturation temperature w.r.t. pressure"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          output DerTemperatureByPressure dTp "Derivative of saturation temperature w.r.t. pressure";
        end saturationTemperature_derp;

        replaceable partial function surfaceTension  "Return surface tension sigma in the two phase region"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output SurfaceTension sigma "Surface tension sigma in the two phase region";
        end surfaceTension;

        redeclare replaceable function extends molarMass  "Return the molar mass of the medium"
        algorithm
          MM := fluidConstants[1].molarMass;
        end molarMass;

        replaceable partial function dBubbleDensity_dPressure  "Return bubble point density derivative"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output DerDensityByPressure ddldp "Boiling curve density derivative";
        end dBubbleDensity_dPressure;

        replaceable partial function dDewDensity_dPressure  "Return dew point density derivative"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output DerDensityByPressure ddvdp "Saturated steam density derivative";
        end dDewDensity_dPressure;

        replaceable partial function dBubbleEnthalpy_dPressure  "Return bubble point specific enthalpy derivative"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output DerEnthalpyByPressure dhldp "Boiling curve specific enthalpy derivative";
        end dBubbleEnthalpy_dPressure;

        replaceable partial function dDewEnthalpy_dPressure  "Return dew point specific enthalpy derivative"
          extends Modelica.Icons.Function;
          input SaturationProperties sat "Saturation property record";
          output DerEnthalpyByPressure dhvdp "Saturated steam specific enthalpy derivative";
        end dDewEnthalpy_dPressure;

        redeclare replaceable function specificEnthalpy_pTX  "Return specific enthalpy from pressure, temperature and mass fraction"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input MassFraction[:] X "Mass fractions";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output SpecificEnthalpy h "Specific enthalpy at p, T, X";
        algorithm
          h := specificEnthalpy(setState_pTX(p, T, X, phase));
        end specificEnthalpy_pTX;

        redeclare replaceable function temperature_phX  "Return temperature from p, h, and X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction[:] X "Mass fractions";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Temperature T "Temperature";
        algorithm
          T := temperature(setState_phX(p, h, X, phase));
        end temperature_phX;

        redeclare replaceable function density_phX  "Return density from p, h, and X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction[:] X "Mass fractions";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Density d "Density";
        algorithm
          d := density(setState_phX(p, h, X, phase));
        end density_phX;

        redeclare replaceable function temperature_psX  "Return temperature from p, s, and X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          input MassFraction[:] X "Mass fractions";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Temperature T "Temperature";
        algorithm
          T := temperature(setState_psX(p, s, X, phase));
        end temperature_psX;

        redeclare replaceable function density_psX  "Return density from p, s, and X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          input MassFraction[:] X "Mass fractions";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Density d "Density";
        algorithm
          d := density(setState_psX(p, s, X, phase));
        end density_psX;

        redeclare replaceable function specificEnthalpy_psX  "Return specific enthalpy from p, s, and X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          input MassFraction[:] X "Mass fractions";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := specificEnthalpy(setState_psX(p, s, X, phase));
        end specificEnthalpy_psX;

        redeclare replaceable function setState_ph  "Return thermodynamic state from p and h"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output ThermodynamicState state "Thermodynamic state record";
        algorithm
          state := setState_phX(p, h, fill(0, 0), phase);
        end setState_ph;

        redeclare replaceable function density_ph  "Return density from p and h"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Density d "Density";
        algorithm
          d := density_phX(p, h, fill(0, 0), phase);
        end density_ph;

        redeclare replaceable function temperature_ph  "Return temperature from p and h"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Temperature T "Temperature";
        algorithm
          T := temperature_phX(p, h, fill(0, 0), phase);
        end temperature_ph;

        redeclare replaceable function pressure_dT  "Return pressure from d and T"
          extends Modelica.Icons.Function;
          input Density d "Density";
          input Temperature T "Temperature";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output AbsolutePressure p "Pressure";
        algorithm
          p := pressure(setState_dTX(d, T, fill(0, 0), phase));
        end pressure_dT;

        redeclare replaceable function specificEnthalpy_dT  "Return specific enthalpy from d and T"
          extends Modelica.Icons.Function;
          input Density d "Density";
          input Temperature T "Temperature";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := specificEnthalpy(setState_dTX(d, T, fill(0, 0), phase));
        end specificEnthalpy_dT;

        redeclare replaceable function specificEnthalpy_ps  "Return specific enthalpy from p and s"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := specificEnthalpy_psX(p, s, fill(0, 0));
        end specificEnthalpy_ps;

        redeclare replaceable function temperature_ps  "Return temperature from p and s"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Temperature T "Temperature";
        algorithm
          T := temperature_psX(p, s, fill(0, 0), phase);
        end temperature_ps;

        redeclare replaceable function density_ps  "Return density from p and s"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Density d "Density";
        algorithm
          d := density_psX(p, s, fill(0, 0), phase);
        end density_ps;

        redeclare replaceable function specificEnthalpy_pT  "Return specific enthalpy from p and T"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := specificEnthalpy_pTX(p, T, fill(0, 0), phase);
        end specificEnthalpy_pT;

        redeclare replaceable function density_pT  "Return density from p and T"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Density d "Density";
        algorithm
          d := density(setState_pTX(p, T, fill(0, 0), phase));
        end density_pT;
      end PartialTwoPhaseMedium;

      package Choices  "Types, constants to define menu choices"
        extends Modelica.Icons.Package;
        type IndependentVariables = enumeration(T "Temperature", pT "Pressure, Temperature", ph "Pressure, Specific Enthalpy", phX "Pressure, Specific Enthalpy, Mass Fraction", pTX "Pressure, Temperature, Mass Fractions", dTX "Density, Temperature, Mass Fractions") "Enumeration defining the independent variables of a medium";
        annotation(Documentation(info = "<html>
         <p>
         Enumerations and data types for all types of fluids
         </p>

         <p>
         Note: Reference enthalpy might have to be extended with enthalpy of formation.
         </p>
         </html>"));
      end Choices;

      package Types  "Types to be used in fluid models"
        extends Modelica.Icons.Package;
        type AbsolutePressure = .Modelica.SIunits.AbsolutePressure(min = 0, max = 100000000.0, nominal = 100000.0, start = 100000.0) "Type for absolute pressure with medium specific attributes";
        type Density = .Modelica.SIunits.Density(min = 0, max = 100000.0, nominal = 1, start = 1) "Type for density with medium specific attributes";
        type DynamicViscosity = .Modelica.SIunits.DynamicViscosity(min = 0, max = 100000000.0, nominal = 0.001, start = 0.001) "Type for dynamic viscosity with medium specific attributes";
        type MassFraction = Real(quantity = "MassFraction", final unit = "kg/kg", min = 0, max = 1, nominal = 0.1) "Type for mass fraction with medium specific attributes";
        type MolarMass = .Modelica.SIunits.MolarMass(min = 0.001, max = 0.25, nominal = 0.032) "Type for molar mass with medium specific attributes";
        type MolarVolume = .Modelica.SIunits.MolarVolume(min = 0.000001, max = 1000000.0, nominal = 1.0) "Type for molar volume with medium specific attributes";
        type IsentropicExponent = .Modelica.SIunits.RatioOfSpecificHeatCapacities(min = 1, max = 500000, nominal = 1.2, start = 1.2) "Type for isentropic exponent with medium specific attributes";
        type SpecificEnergy = .Modelica.SIunits.SpecificEnergy(min = -100000000.0, max = 100000000.0, nominal = 1000000.0) "Type for specific energy with medium specific attributes";
        type SpecificInternalEnergy = SpecificEnergy "Type for specific internal energy with medium specific attributes";
        type SpecificEnthalpy = .Modelica.SIunits.SpecificEnthalpy(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0) "Type for specific enthalpy with medium specific attributes";
        type SpecificEntropy = .Modelica.SIunits.SpecificEntropy(min = -10000000.0, max = 10000000.0, nominal = 1000.0) "Type for specific entropy with medium specific attributes";
        type SpecificHeatCapacity = .Modelica.SIunits.SpecificHeatCapacity(min = 0, max = 10000000.0, nominal = 1000.0, start = 1000.0) "Type for specific heat capacity with medium specific attributes";
        type SurfaceTension = .Modelica.SIunits.SurfaceTension "Type for surface tension with medium specific attributes";
        type Temperature = .Modelica.SIunits.Temperature(min = 1, max = 10000.0, nominal = 300, start = 300) "Type for temperature with medium specific attributes";
        type ThermalConductivity = .Modelica.SIunits.ThermalConductivity(min = 0, max = 500, nominal = 1, start = 1) "Type for thermal conductivity with medium specific attributes";
        type VelocityOfSound = .Modelica.SIunits.Velocity(min = 0, max = 100000.0, nominal = 1000, start = 1000) "Type for velocity of sound with medium specific attributes";
        type ExtraProperty = Real(min = 0.0, start = 1.0) "Type for unspecified, mass-specific property transported by flow";
        type IsobaricExpansionCoefficient = Real(min = 0, max = 100000000.0, unit = "1/K") "Type for isobaric expansion coefficient with medium specific attributes";
        type DipoleMoment = Real(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment") "Type for dipole moment with medium specific attributes";
        type DerDensityByPressure = .Modelica.SIunits.DerDensityByPressure "Type for partial derivative of density with respect to pressure with medium specific attributes";
        type DerDensityByEnthalpy = .Modelica.SIunits.DerDensityByEnthalpy "Type for partial derivative of density with respect to enthalpy with medium specific attributes";
        type DerEnthalpyByPressure = .Modelica.SIunits.DerEnthalpyByPressure "Type for partial derivative of enthalpy with respect to pressure with medium specific attributes";
        type DerTemperatureByPressure = Real(final unit = "K/Pa") "Type for partial derivative of temperature with respect to pressure with medium specific attributes";

        replaceable record SaturationProperties  "Saturation properties of two phase medium"
          extends Modelica.Icons.Record;
          AbsolutePressure psat "Saturation pressure";
          Temperature Tsat "Saturation temperature";
        end SaturationProperties;

        type FixedPhase = Integer(min = 0, max = 2) "Phase of the fluid: 1 for 1-phase, 2 for two-phase, 0 for not known, e.g., interactive use";

        package Basic  "The most basic version of a record used in several degrees of detail"
          extends Icons.Package;

          record FluidConstants  "Critical, triple, molecular and other standard data of fluid"
            extends Modelica.Icons.Record;
            String iupacName "Complete IUPAC name (or common name, if non-existent)";
            String casRegistryNumber "Chemical abstracts sequencing number (if it exists)";
            String chemicalFormula "Chemical formula, (brutto, nomenclature according to Hill";
            String structureFormula "Chemical structure formula";
            MolarMass molarMass "Molar mass";
          end FluidConstants;
        end Basic;

        package TwoPhase  "The two phase fluid version of a record used in several degrees of detail"
          extends Icons.Package;

          record FluidConstants  "Extended fluid constants"
            extends Modelica.Media.Interfaces.Types.Basic.FluidConstants;
            Temperature criticalTemperature "Critical temperature";
            AbsolutePressure criticalPressure "Critical pressure";
            MolarVolume criticalMolarVolume "Critical molar Volume";
            Real acentricFactor "Pitzer acentric factor";
            Temperature triplePointTemperature "Triple point temperature";
            AbsolutePressure triplePointPressure "Triple point pressure";
            Temperature meltingPoint "Melting point at 101325 Pa";
            Temperature normalBoilingPoint "Normal boiling point (at 101325 Pa)";
            DipoleMoment dipoleMoment "Dipole moment of molecule in Debye (1 debye = 3.33564e10-30 C.m)";
            Boolean hasIdealGasHeatCapacity = false "True if ideal gas heat capacity is available";
            Boolean hasCriticalData = false "True if critical data are known";
            Boolean hasDipoleMoment = false "True if a dipole moment known";
            Boolean hasFundamentalEquation = false "True if a fundamental equation";
            Boolean hasLiquidHeatCapacity = false "True if liquid heat capacity is available";
            Boolean hasSolidHeatCapacity = false "True if solid heat capacity is available";
            Boolean hasAccurateViscosityData = false "True if accurate data for a viscosity function is available";
            Boolean hasAccurateConductivityData = false "True if accurate data for thermal conductivity is available";
            Boolean hasVapourPressureCurve = false "True if vapour pressure data, e.g., Antoine coefficents are known";
            Boolean hasAcentricFactor = false "True if Pitzer accentric factor is known";
            SpecificEnthalpy HCRIT0 = 0.0 "Critical specific enthalpy of the fundamental equation";
            SpecificEntropy SCRIT0 = 0.0 "Critical specific entropy of the fundamental equation";
            SpecificEnthalpy deltah = 0.0 "Difference between specific enthalpy model (h_m) and f.eq. (h_f) (h_m - h_f)";
            SpecificEntropy deltas = 0.0 "Difference between specific enthalpy model (s_m) and f.eq. (s_f) (s_m - s_f)";
          end FluidConstants;
        end TwoPhase;
      end Types;
      annotation(Documentation(info = "<HTML>
       <p>
       This package provides basic interfaces definitions of media models for different
       kind of media.
       </p>
       </HTML>"));
    end Interfaces;

    package Common  "Data structures and fundamental functions for fluid properties"
      extends Modelica.Icons.Package;
      type DerPressureByDensity = Real(final quantity = "DerPressureByDensity", final unit = "Pa.m3/kg");
      type DerPressureByTemperature = Real(final quantity = "DerPressureByTemperature", final unit = "Pa/K");
      constant Real MINPOS = 0.000000001 "Minimal value for physical variables which are always > 0.0";

      record IF97BaseTwoPhase  "Intermediate property data record for IF 97"
        extends Modelica.Icons.Record;
        Integer phase = 0 "Phase: 2 for two-phase, 1 for one phase, 0 if unknown";
        Integer region(min = 1, max = 5) "IF 97 region";
        .Modelica.SIunits.Pressure p "Pressure";
        .Modelica.SIunits.Temperature T "Temperature";
        .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
        .Modelica.SIunits.SpecificHeatCapacity R "Gas constant";
        .Modelica.SIunits.SpecificHeatCapacity cp "Specific heat capacity";
        .Modelica.SIunits.SpecificHeatCapacity cv "Specific heat capacity";
        .Modelica.SIunits.Density rho "Density";
        .Modelica.SIunits.SpecificEntropy s "Specific entropy";
        DerPressureByTemperature pt "Derivative of pressure w.r.t. temperature";
        DerPressureByDensity pd "Derivative of pressure w.r.t. density";
        Real vt "Derivative of specific volume w.r.t. temperature";
        Real vp "Derivative of specific volume w.r.t. pressure";
        Real x "Dryness fraction";
        Real dpT "dp/dT derivative of saturation curve";
      end IF97BaseTwoPhase;

      record IF97PhaseBoundaryProperties  "Thermodynamic base properties on the phase boundary for IF97 steam tables"
        extends Modelica.Icons.Record;
        Boolean region3boundary "True if boundary between 2-phase and region 3";
        .Modelica.SIunits.SpecificHeatCapacity R "Specific heat capacity";
        .Modelica.SIunits.Temperature T "Temperature";
        .Modelica.SIunits.Density d "Density";
        .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
        .Modelica.SIunits.SpecificEntropy s "Specific entropy";
        .Modelica.SIunits.SpecificHeatCapacity cp "Heat capacity at constant pressure";
        .Modelica.SIunits.SpecificHeatCapacity cv "Heat capacity at constant volume";
        DerPressureByTemperature dpT "dp/dT derivative of saturation curve";
        DerPressureByTemperature pt "Derivative of pressure w.r.t. temperature";
        DerPressureByDensity pd "Derivative of pressure w.r.t. density";
        Real vt(unit = "m3/(kg.K)") "Derivative of specific volume w.r.t. temperature";
        Real vp(unit = "m3/(kg.Pa)") "Derivative of specific volume w.r.t. pressure";
      end IF97PhaseBoundaryProperties;

      record GibbsDerivs  "Derivatives of dimensionless Gibbs-function w.r.t. dimensionless pressure and temperature"
        extends Modelica.Icons.Record;
        .Modelica.SIunits.Pressure p "Pressure";
        .Modelica.SIunits.Temperature T "Temperature";
        .Modelica.SIunits.SpecificHeatCapacity R "Specific heat capacity";
        Real pi(unit = "1") "Dimensionless pressure";
        Real tau(unit = "1") "Dimensionless temperature";
        Real g(unit = "1") "Dimensionless Gibbs-function";
        Real gpi(unit = "1") "Derivative of g w.r.t. pi";
        Real gpipi(unit = "1") "2nd derivative of g w.r.t. pi";
        Real gtau(unit = "1") "Derivative of g w.r.t. tau";
        Real gtautau(unit = "1") "2nd derivative of g w.r.t. tau";
        Real gtaupi(unit = "1") "Mixed derivative of g w.r.t. pi and tau";
      end GibbsDerivs;

      record HelmholtzDerivs  "Derivatives of dimensionless Helmholtz-function w.r.t. dimensionless pressure, density and temperature"
        extends Modelica.Icons.Record;
        .Modelica.SIunits.Density d "Density";
        .Modelica.SIunits.Temperature T "Temperature";
        .Modelica.SIunits.SpecificHeatCapacity R "Specific heat capacity";
        Real delta(unit = "1") "Dimensionless density";
        Real tau(unit = "1") "Dimensionless temperature";
        Real f(unit = "1") "Dimensionless Helmholtz-function";
        Real fdelta(unit = "1") "Derivative of f w.r.t. delta";
        Real fdeltadelta(unit = "1") "2nd derivative of f w.r.t. delta";
        Real ftau(unit = "1") "Derivative of f w.r.t. tau";
        Real ftautau(unit = "1") "2nd derivative of f w.r.t. tau";
        Real fdeltatau(unit = "1") "Mixed derivative of f w.r.t. delta and tau";
      end HelmholtzDerivs;

      record PhaseBoundaryProperties  "Thermodynamic base properties on the phase boundary"
        extends Modelica.Icons.Record;
        .Modelica.SIunits.Density d "Density";
        .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
        .Modelica.SIunits.SpecificEnergy u "Inner energy";
        .Modelica.SIunits.SpecificEntropy s "Specific entropy";
        .Modelica.SIunits.SpecificHeatCapacity cp "Heat capacity at constant pressure";
        .Modelica.SIunits.SpecificHeatCapacity cv "Heat capacity at constant volume";
        DerPressureByTemperature pt "Derivative of pressure w.r.t. temperature";
        DerPressureByDensity pd "Derivative of pressure w.r.t. density";
      end PhaseBoundaryProperties;

      record NewtonDerivatives_ph  "Derivatives for fast inverse calculations of Helmholtz functions: p & h"
        extends Modelica.Icons.Record;
        .Modelica.SIunits.Pressure p "Pressure";
        .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
        DerPressureByDensity pd "Derivative of pressure w.r.t. density";
        DerPressureByTemperature pt "Derivative of pressure w.r.t. temperature";
        Real hd "Derivative of specific enthalpy w.r.t. density";
        Real ht "Derivative of specific enthalpy w.r.t. temperature";
      end NewtonDerivatives_ph;

      record NewtonDerivatives_ps  "Derivatives for fast inverse calculation of Helmholtz functions: p & s"
        extends Modelica.Icons.Record;
        .Modelica.SIunits.Pressure p "Pressure";
        .Modelica.SIunits.SpecificEntropy s "Specific entropy";
        DerPressureByDensity pd "Derivative of pressure w.r.t. density";
        DerPressureByTemperature pt "Derivative of pressure w.r.t. temperature";
        Real sd "Derivative of specific entropy w.r.t. density";
        Real st "Derivative of specific entropy w.r.t. temperature";
      end NewtonDerivatives_ps;

      record NewtonDerivatives_pT  "Derivatives for fast inverse calculations of Helmholtz functions:p & T"
        extends Modelica.Icons.Record;
        .Modelica.SIunits.Pressure p "Pressure";
        DerPressureByDensity pd "Derivative of pressure w.r.t. density";
      end NewtonDerivatives_pT;

      function gibbsToBoundaryProps  "Calculate phase boundary property record from dimensionless Gibbs function"
        extends Modelica.Icons.Function;
        input GibbsDerivs g "Dimensionless derivatives of Gibbs function";
        output PhaseBoundaryProperties sat "Phase boundary properties";
      protected
        Real vt "Derivative of specific volume w.r.t. temperature";
        Real vp "Derivative of specific volume w.r.t. pressure";
      algorithm
        sat.d := g.p / (g.R * g.T * g.pi * g.gpi);
        sat.h := g.R * g.T * g.tau * g.gtau;
        sat.u := g.T * g.R * (g.tau * g.gtau - g.pi * g.gpi);
        sat.s := g.R * (g.tau * g.gtau - g.g);
        sat.cp := -g.R * g.tau * g.tau * g.gtautau;
        sat.cv := g.R * (-g.tau * g.tau * g.gtautau + (g.gpi - g.tau * g.gtaupi) * (g.gpi - g.tau * g.gtaupi) / g.gpipi);
        vt := g.R / g.p * (g.pi * g.gpi - g.tau * g.pi * g.gtaupi);
        vp := g.R * g.T / (g.p * g.p) * g.pi * g.pi * g.gpipi;
        sat.pt := -g.p / g.T * (g.gpi - g.tau * g.gtaupi) / (g.gpipi * g.pi);
        sat.pd := -g.R * g.T * g.gpi * g.gpi / g.gpipi;
      end gibbsToBoundaryProps;

      function helmholtzToBoundaryProps  "Calculate phase boundary property record from dimensionless Helmholtz function"
        extends Modelica.Icons.Function;
        input HelmholtzDerivs f "Dimensionless derivatives of Helmholtz function";
        output PhaseBoundaryProperties sat "Phase boundary property record";
      protected
        .Modelica.SIunits.Pressure p "Pressure";
      algorithm
        p := f.R * f.d * f.T * f.delta * f.fdelta;
        sat.d := f.d;
        sat.h := f.R * f.T * (f.tau * f.ftau + f.delta * f.fdelta);
        sat.s := f.R * (f.tau * f.ftau - f.f);
        sat.u := f.R * f.T * f.tau * f.ftau;
        sat.cp := f.R * (-f.tau * f.tau * f.ftautau + (f.delta * f.fdelta - f.delta * f.tau * f.fdeltatau) ^ 2 / (2 * f.delta * f.fdelta + f.delta * f.delta * f.fdeltadelta));
        sat.cv := f.R * (-f.tau * f.tau * f.ftautau);
        sat.pt := f.R * f.d * f.delta * (f.fdelta - f.tau * f.fdeltatau);
        sat.pd := f.R * f.T * f.delta * (2.0 * f.fdelta + f.delta * f.fdeltadelta);
      end helmholtzToBoundaryProps;

      function cv2Phase  "Compute isochoric specific heat capacity inside the two-phase region"
        extends Modelica.Icons.Function;
        input PhaseBoundaryProperties liq "Properties on the boiling curve";
        input PhaseBoundaryProperties vap "Properties on the condensation curve";
        input .Modelica.SIunits.MassFraction x "Vapour mass fraction";
        input .Modelica.SIunits.Temperature T "Temperature";
        input .Modelica.SIunits.Pressure p "Properties";
        output .Modelica.SIunits.SpecificHeatCapacity cv "Isochoric specific heat capacity";
      protected
        Real dpT "Derivative of pressure w.r.t. temperature";
        Real dxv "Derivative of vapour mass fraction w.r.t. specific volume";
        Real dvTl "Derivative of liquid specific volume w.r.t. temperature";
        Real dvTv "Derivative of vapour specific volume w.r.t. temperature";
        Real duTl "Derivative of liquid specific inner energy w.r.t. temperature";
        Real duTv "Derivative of vapour specific inner energy w.r.t. temperature";
        Real dxt "Derivative of vapour mass fraction w.r.t. temperature";
      algorithm
        dxv := if liq.d <> vap.d then liq.d * vap.d / (liq.d - vap.d) else 0.0;
        dpT := (vap.s - liq.s) * dxv;
        dvTl := (liq.pt - dpT) / liq.pd / liq.d / liq.d;
        dvTv := (vap.pt - dpT) / vap.pd / vap.d / vap.d;
        dxt := -dxv * (dvTl + x * (dvTv - dvTl));
        duTl := liq.cv + (T * liq.pt - p) * dvTl;
        duTv := vap.cv + (T * vap.pt - p) * dvTv;
        cv := duTl + x * (duTv - duTl) + dxt * (vap.u - liq.u);
      end cv2Phase;

      function Helmholtz_ph  "Function to calculate analytic derivatives for computing d and t given p and h"
        extends Modelica.Icons.Function;
        input HelmholtzDerivs f "Dimensionless derivatives of Helmholtz function";
        output NewtonDerivatives_ph nderivs "Derivatives for Newton iteration to calculate d and t from p and h";
      protected
        .Modelica.SIunits.SpecificHeatCapacity cv "Isochoric heat capacity";
      algorithm
        cv := -f.R * f.tau * f.tau * f.ftautau;
        nderivs.p := f.d * f.R * f.T * f.delta * f.fdelta;
        nderivs.h := f.R * f.T * (f.tau * f.ftau + f.delta * f.fdelta);
        nderivs.pd := f.R * f.T * f.delta * (2.0 * f.fdelta + f.delta * f.fdeltadelta);
        nderivs.pt := f.R * f.d * f.delta * (f.fdelta - f.tau * f.fdeltatau);
        nderivs.ht := cv + nderivs.pt / f.d;
        nderivs.hd := (nderivs.pd - f.T * nderivs.pt / f.d) / f.d;
      end Helmholtz_ph;

      function Helmholtz_pT  "Function to calculate analytic derivatives for computing d and t given p and t"
        extends Modelica.Icons.Function;
        input HelmholtzDerivs f "Dimensionless derivatives of Helmholtz function";
        output NewtonDerivatives_pT nderivs "Derivatives for Newton iteration to compute d and t from p and t";
      algorithm
        nderivs.p := f.d * f.R * f.T * f.delta * f.fdelta;
        nderivs.pd := f.R * f.T * f.delta * (2.0 * f.fdelta + f.delta * f.fdeltadelta);
      end Helmholtz_pT;

      function Helmholtz_ps  "Function to calculate analytic derivatives for computing d and t given p and s"
        extends Modelica.Icons.Function;
        input HelmholtzDerivs f "Dimensionless derivatives of Helmholtz function";
        output NewtonDerivatives_ps nderivs "Derivatives for Newton iteration to compute d and t from p and s";
      protected
        .Modelica.SIunits.SpecificHeatCapacity cv "Isochoric heat capacity";
      algorithm
        cv := -f.R * f.tau * f.tau * f.ftautau;
        nderivs.p := f.d * f.R * f.T * f.delta * f.fdelta;
        nderivs.s := f.R * (f.tau * f.ftau - f.f);
        nderivs.pd := f.R * f.T * f.delta * (2.0 * f.fdelta + f.delta * f.fdeltadelta);
        nderivs.pt := f.R * f.d * f.delta * (f.fdelta - f.tau * f.fdeltatau);
        nderivs.st := cv / f.T;
        nderivs.sd := -nderivs.pt / (f.d * f.d);
      end Helmholtz_ps;

      function smoothStep  "Approximation of a general step, such that the characteristic is continuous and differentiable"
        extends Modelica.Icons.Function;
        input Real x "Abscissa value";
        input Real y1 "Ordinate value for x > 0";
        input Real y2 "Ordinate value for x < 0";
        input Real x_small(min = 0) = 0.00001 "Approximation of step for -x_small <= x <= x_small; x_small > 0 required";
        output Real y "Ordinate value to approximate y = if x > 0 then y1 else y2";
      algorithm
        y := smooth(1, if x > x_small then y1 else if x < -x_small then y2 else if abs(x_small) > 0 then x / x_small * ((x / x_small) ^ 2 - 3) * (y2 - y1) / 4 + (y1 + y2) / 2 else (y1 + y2) / 2);
        annotation(Inline = true, smoothOrder = 1, Documentation(revisions = "<html>
         <ul>
         <li><i>April 29, 2008</i>
             by <a href=\"mailto:Martin.Otter@DLR.de\">Martin Otter</a>:<br>
             Designed and implemented.</li>
         <li><i>August 12, 2008</i>
             by <a href=\"mailto:Michael.Sielemann@dlr.de\">Michael Sielemann</a>:<br>
             Minor modification to cover the limit case <code>x_small -> 0</code> without division by zero.</li>
         </ul>
         </html>", info = "<html>
         <p>
         This function is used to approximate the equation
         </p>
         <pre>
             y = <b>if</b> x &gt; 0 <b>then</b> y1 <b>else</b> y2;
         </pre>

         <p>
         by a smooth characteristic, so that the expression is continuous and differentiable:
         </p>

         <pre>
            y = <b>smooth</b>(1, <b>if</b> x &gt;  x_small <b>then</b> y1 <b>else</b>
                          <b>if</b> x &lt; -x_small <b>then</b> y2 <b>else</b> f(y1, y2));
         </pre>

         <p>
         In the region -x_small &lt; x &lt; x_small a 2nd order polynomial is used
         for a smooth transition from y1 to y2.
         </p>

         <p>
         If <b>mass fractions</b> X[:] are approximated with this function then this can be performed
         for all <b>nX</b> mass fractions, instead of applying it for nX-1 mass fractions and computing
         the last one by the mass fraction constraint sum(X)=1. The reason is that the approximating function has the
         property that sum(X) = 1, provided sum(X_a) = sum(X_b) = 1
         (and y1=X_a[i], y2=X_b[i]).
         This can be shown by evaluating the approximating function in the abs(x) &lt; x_small
         region (otherwise X is either X_a or X_b):
         </p>

         <pre>
             X[1]  = smoothStep(x, X_a[1] , X_b[1] , x_small);
             X[2]  = smoothStep(x, X_a[2] , X_b[2] , x_small);
                ...
             X[nX] = smoothStep(x, X_a[nX], X_b[nX], x_small);
         </pre>

         <p>
         or
         </p>

         <pre>
             X[1]  = c*(X_a[1]  - X_b[1])  + (X_a[1]  + X_b[1])/2
             X[2]  = c*(X_a[2]  - X_b[2])  + (X_a[2]  + X_b[2])/2;
                ...
             X[nX] = c*(X_a[nX] - X_b[nX]) + (X_a[nX] + X_b[nX])/2;
             c     = (x/x_small)*((x/x_small)^2 - 3)/4
         </pre>

         <p>
         Summing all mass fractions together results in
         </p>

         <pre>
             sum(X) = c*(sum(X_a) - sum(X_b)) + (sum(X_a) + sum(X_b))/2
                    = c*(1 - 1) + (1 + 1)/2
                    = 1
         </pre>
         </html>"));
      end smoothStep;
      annotation(Documentation(info = "<HTML><h4>Package description</h4>
             <p>Package Modelica.Media.Common provides records and functions shared by many of the property sub-packages.
             High accuracy fluid property models share a lot of common structure, even if the actual models are different.
             Common data structures and computations shared by these property models are collected in this library.
          </p>

       </html>", revisions = "<html>
             <ul>
             <li>First implemented: <i>July, 2000</i>
             by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>
             for the ThermoFluid Library with help from Jonas Eborn and Falko Jens Wagner
             </li>
             <li>Code reorganization, enhanced documentation, additional functions: <i>December, 2002</i>
             by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a> and move to Modelica
                                   properties library.</li>
             <li>Inclusion into Modelica.Media: September 2003 </li>
             </ul>

             <address>Author: Hubertus Tummescheit, <br>
             Lund University<br>
             Department of Automatic Control<br>
             Box 118, 22100 Lund, Sweden<br>
             email: hubertus@control.lth.se
             </address>
       </html>"));
    end Common;

    package Water  "Medium models for water"
      extends Modelica.Icons.VariantsPackage;
      constant Modelica.Media.Interfaces.Types.TwoPhase.FluidConstants[1] waterConstants(each chemicalFormula = "H2O", each structureFormula = "H2O", each casRegistryNumber = "7732-18-5", each iupacName = "oxidane", each molarMass = 0.018015268, each criticalTemperature = 647.096, each criticalPressure = 22064000.0, each criticalMolarVolume = 1 / 322.0 * 0.018015268, each normalBoilingPoint = 373.124, each meltingPoint = 273.15, each triplePointTemperature = 273.16, each triplePointPressure = 611.657, each acentricFactor = 0.344, each dipoleMoment = 1.8, each hasCriticalData = true);
      package StandardWater = WaterIF97_ph "Water using the IF97 standard, explicit in p and h. Recommended for most applications";

      package WaterIF97OnePhase_ph  "Water using the IF97 standard, explicit in p and h, and only valid outside the two-phase dome"
        extends WaterIF97_base(ThermoStates = Modelica.Media.Interfaces.Choices.IndependentVariables.ph, final ph_explicit = true, final dT_explicit = false, final pT_explicit = false, final smoothModel = true, final onePhase = true);
        annotation(Documentation(info = "<html>

         </html>"));
      end WaterIF97OnePhase_ph;

      package WaterIF97_ph  "Water using the IF97 standard, explicit in p and h"
        extends WaterIF97_base(ThermoStates = Modelica.Media.Interfaces.Choices.IndependentVariables.ph, final ph_explicit = true, final dT_explicit = false, final pT_explicit = false, smoothModel = false, onePhase = false);
        annotation(Documentation(info = "<html>

         </html>"));
      end WaterIF97_ph;

      partial package WaterIF97_base  "Water: Steam properties as defined by IAPWS/IF97 standard"
        extends Interfaces.PartialTwoPhaseMedium(mediumName = "WaterIF97", substanceNames = {"water"}, singleState = false, SpecificEnthalpy(start = 100000.0, nominal = 500000.0), Density(start = 150, nominal = 500), AbsolutePressure(start = 5000000.0, nominal = 1000000.0, min = 611.657, max = 100000000.0), Temperature(start = 500, nominal = 500, min = 273.15, max = 2273.15), smoothModel = false, onePhase = false, fluidConstants = waterConstants);

        redeclare record extends ThermodynamicState  "Thermodynamic state"
          SpecificEnthalpy h "Specific enthalpy";
          Density d "Density";
          Temperature T "Temperature";
          AbsolutePressure p "Pressure";
        end ThermodynamicState;

        constant Boolean ph_explicit "True if explicit in pressure and specific enthalpy";
        constant Boolean dT_explicit "True if explicit in density and temperature";
        constant Boolean pT_explicit "True if explicit in pressure and temperature";

        redeclare replaceable model extends BaseProperties  "Base properties of water"
          Integer phase(min = 0, max = 2, start = 1, fixed = false) "2 for two-phase, 1 for one-phase, 0 if not known";
        equation
          MM = fluidConstants[1].molarMass;
          if smoothModel then
            if onePhase then
              phase = 1;
              if ph_explicit then
                assert(h < bubbleEnthalpy(sat) or h > dewEnthalpy(sat) or p > fluidConstants[1].criticalPressure, "With onePhase=true this model may only be called with one-phase states h < hl or h > hv!" + "(p = " + String(p) + ", h = " + String(h) + ")");
              else
                if dT_explicit then
                  assert(not (d < bubbleDensity(sat) and d > dewDensity(sat) and T < fluidConstants[1].criticalTemperature), "With onePhase=true this model may only be called with one-phase states d > dl or d < dv!" + "(d = " + String(d) + ", T = " + String(T) + ")");
                end if;
              end if;
            else
              phase = 0;
            end if;
          else
            if ph_explicit then
              phase = if h < bubbleEnthalpy(sat) or h > dewEnthalpy(sat) or p > fluidConstants[1].criticalPressure then 1 else 2;
            elseif dT_explicit then
              phase = if not (d < bubbleDensity(sat) and d > dewDensity(sat) and T < fluidConstants[1].criticalTemperature) then 1 else 2;
            else
              phase = 1;
            end if;
          end if;
          if dT_explicit then
            p = pressure_dT(d, T, phase);
            h = specificEnthalpy_dT(d, T, phase);
            sat.Tsat = T;
            sat.psat = saturationPressure(T);
          elseif ph_explicit then
            d = density_ph(p, h, phase);
            T = temperature_ph(p, h, phase);
            sat.Tsat = saturationTemperature(p);
            sat.psat = p;
          else
            h = specificEnthalpy_pT(p, T);
            d = density_pT(p, T);
            sat.psat = p;
            sat.Tsat = saturationTemperature(p);
          end if;
          u = h - p / d;
          R = Modelica.Constants.R / fluidConstants[1].molarMass;
          h = state.h;
          p = state.p;
          T = state.T;
          d = state.d;
          phase = state.phase;
        end BaseProperties;

        redeclare function density_ph  "Computes density as a function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Density d "Density";
        algorithm
          d := IF97_Utilities.rho_ph(p, h, phase);
          annotation(Inline = true);
        end density_ph;

        redeclare function temperature_ph  "Computes temperature as a function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Temperature T "Temperature";
        algorithm
          T := IF97_Utilities.T_ph(p, h, phase);
          annotation(Inline = true);
        end temperature_ph;

        redeclare function temperature_ps  "Compute temperature from pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Temperature T "Temperature";
        algorithm
          T := IF97_Utilities.T_ps(p, s, phase);
          annotation(Inline = true);
        end temperature_ps;

        redeclare function density_ps  "Computes density as a function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Density d "Density";
        algorithm
          d := IF97_Utilities.rho_ps(p, s, phase);
          annotation(Inline = true);
        end density_ps;

        redeclare function pressure_dT  "Computes pressure as a function of density and temperature"
          extends Modelica.Icons.Function;
          input Density d "Density";
          input Temperature T "Temperature";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output AbsolutePressure p "Pressure";
        algorithm
          p := IF97_Utilities.p_dT(d, T, phase);
          annotation(Inline = true);
        end pressure_dT;

        redeclare function specificEnthalpy_dT  "Computes specific enthalpy as a function of density and temperature"
          extends Modelica.Icons.Function;
          input Density d "Density";
          input Temperature T "Temperature";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := IF97_Utilities.h_dT(d, T, phase);
          annotation(Inline = true);
        end specificEnthalpy_dT;

        redeclare function specificEnthalpy_pT  "Computes specific enthalpy as a function of pressure and temperature"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := IF97_Utilities.h_pT(p, T);
          annotation(Inline = true);
        end specificEnthalpy_pT;

        redeclare function specificEnthalpy_ps  "Computes specific enthalpy as a function of pressure and temperature"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := IF97_Utilities.h_ps(p, s, phase);
          annotation(Inline = true);
        end specificEnthalpy_ps;

        redeclare function density_pT  "Computes density as a function of pressure and temperature"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Density d "Density";
        algorithm
          d := IF97_Utilities.rho_pT(p, T);
          annotation(Inline = true);
        end density_pT;

        redeclare function extends setDewState  "Set the thermodynamic state on the dew line"
        algorithm
          state := ThermodynamicState(phase = phase, p = sat.psat, T = sat.Tsat, h = dewEnthalpy(sat), d = dewDensity(sat));
          annotation(Inline = true);
        end setDewState;

        redeclare function extends setBubbleState  "Set the thermodynamic state on the bubble line"
        algorithm
          state := ThermodynamicState(phase = phase, p = sat.psat, T = sat.Tsat, h = bubbleEnthalpy(sat), d = bubbleDensity(sat));
          annotation(Inline = true);
        end setBubbleState;

        redeclare function extends dynamicViscosity  "Dynamic viscosity of water"
        algorithm
          eta := IF97_Utilities.dynamicViscosity(state.d, state.T, state.p, state.phase);
          annotation(Inline = true);
        end dynamicViscosity;

        redeclare function extends thermalConductivity  "Thermal conductivity of water"
        algorithm
          lambda := IF97_Utilities.thermalConductivity(state.d, state.T, state.p, state.phase);
          annotation(Inline = true);
        end thermalConductivity;

        redeclare function extends surfaceTension  "Surface tension in two phase region of water"
        algorithm
          sigma := IF97_Utilities.surfaceTension(sat.Tsat);
          annotation(Inline = true);
        end surfaceTension;

        redeclare function extends pressure  "Return pressure of ideal gas"
        algorithm
          p := state.p;
          annotation(Inline = true);
        end pressure;

        redeclare function extends temperature  "Return temperature of ideal gas"
        algorithm
          T := state.T;
          annotation(Inline = true);
        end temperature;

        redeclare function extends density  "Return density of ideal gas"
        algorithm
          d := state.d;
          annotation(Inline = true);
        end density;

        redeclare function extends specificEnthalpy  "Return specific enthalpy"
          extends Modelica.Icons.Function;
        algorithm
          h := state.h;
          annotation(Inline = true);
        end specificEnthalpy;

        redeclare function extends specificInternalEnergy  "Return specific internal energy"
          extends Modelica.Icons.Function;
        algorithm
          u := state.h - state.p / state.d;
          annotation(Inline = true);
        end specificInternalEnergy;

        redeclare function extends specificGibbsEnergy  "Return specific Gibbs energy"
          extends Modelica.Icons.Function;
        algorithm
          g := state.h - state.T * specificEntropy(state);
          annotation(Inline = true);
        end specificGibbsEnergy;

        redeclare function extends specificHelmholtzEnergy  "Return specific Helmholtz energy"
          extends Modelica.Icons.Function;
        algorithm
          f := state.h - state.p / state.d - state.T * specificEntropy(state);
          annotation(Inline = true);
        end specificHelmholtzEnergy;

        redeclare function extends specificEntropy  "Specific entropy of water"
        algorithm
          s := if dT_explicit then IF97_Utilities.s_dT(state.d, state.T, state.phase) else if pT_explicit then IF97_Utilities.s_pT(state.p, state.T) else IF97_Utilities.s_ph(state.p, state.h, state.phase);
          annotation(Inline = true);
        end specificEntropy;

        redeclare function extends specificHeatCapacityCp  "Specific heat capacity at constant pressure of water"
        algorithm
          cp := if dT_explicit then IF97_Utilities.cp_dT(state.d, state.T, state.phase) else if pT_explicit then IF97_Utilities.cp_pT(state.p, state.T) else IF97_Utilities.cp_ph(state.p, state.h, state.phase);
          annotation(Inline = true, Documentation(info = "<html>
                                           <p>In the two phase region this function returns the interpolated heat capacity between the
                                           liquid and vapour state heat capacities.</p>
                                           </html>"));
        end specificHeatCapacityCp;

        redeclare function extends specificHeatCapacityCv  "Specific heat capacity at constant volume of water"
        algorithm
          cv := if dT_explicit then IF97_Utilities.cv_dT(state.d, state.T, state.phase) else if pT_explicit then IF97_Utilities.cv_pT(state.p, state.T) else IF97_Utilities.cv_ph(state.p, state.h, state.phase);
          annotation(Inline = true);
        end specificHeatCapacityCv;

        redeclare function extends isentropicExponent  "Return isentropic exponent"
        algorithm
          gamma := if dT_explicit then IF97_Utilities.isentropicExponent_dT(state.d, state.T, state.phase) else if pT_explicit then IF97_Utilities.isentropicExponent_pT(state.p, state.T) else IF97_Utilities.isentropicExponent_ph(state.p, state.h, state.phase);
        end isentropicExponent;

        redeclare function extends isothermalCompressibility  "Isothermal compressibility of water"
        algorithm
          kappa := if dT_explicit then IF97_Utilities.kappa_dT(state.d, state.T, state.phase) else if pT_explicit then IF97_Utilities.kappa_pT(state.p, state.T) else IF97_Utilities.kappa_ph(state.p, state.h, state.phase);
          annotation(Inline = true);
        end isothermalCompressibility;

        redeclare function extends isobaricExpansionCoefficient  "Isobaric expansion coefficient of water"
        algorithm
          beta := if dT_explicit then IF97_Utilities.beta_dT(state.d, state.T, state.phase) else if pT_explicit then IF97_Utilities.beta_pT(state.p, state.T) else IF97_Utilities.beta_ph(state.p, state.h, state.phase);
          annotation(Inline = true);
        end isobaricExpansionCoefficient;

        redeclare function extends velocityOfSound  "Return velocity of sound as a function of the thermodynamic state record"
        algorithm
          a := if dT_explicit then IF97_Utilities.velocityOfSound_dT(state.d, state.T, state.phase) else if pT_explicit then IF97_Utilities.velocityOfSound_pT(state.p, state.T) else IF97_Utilities.velocityOfSound_ph(state.p, state.h, state.phase);
          annotation(Inline = true);
        end velocityOfSound;

        redeclare function extends isentropicEnthalpy  "Compute h(p,s)"
        algorithm
          h_is := IF97_Utilities.isentropicEnthalpy(p_downstream, specificEntropy(refState), 0);
          annotation(Inline = true);
        end isentropicEnthalpy;

        redeclare function extends density_derh_p  "Density derivative by specific enthalpy"
        algorithm
          ddhp := IF97_Utilities.ddhp(state.p, state.h, state.phase);
          annotation(Inline = true);
        end density_derh_p;

        redeclare function extends density_derp_h  "Density derivative by pressure"
        algorithm
          ddph := IF97_Utilities.ddph(state.p, state.h, state.phase);
          annotation(Inline = true);
        end density_derp_h;

        redeclare function extends bubbleEnthalpy  "Boiling curve specific enthalpy of water"
        algorithm
          hl := IF97_Utilities.BaseIF97.Regions.hl_p(sat.psat);
          annotation(Inline = true);
        end bubbleEnthalpy;

        redeclare function extends dewEnthalpy  "Dew curve specific enthalpy of water"
        algorithm
          hv := IF97_Utilities.BaseIF97.Regions.hv_p(sat.psat);
          annotation(Inline = true);
        end dewEnthalpy;

        redeclare function extends bubbleEntropy  "Boiling curve specific entropy of water"
        algorithm
          sl := IF97_Utilities.BaseIF97.Regions.sl_p(sat.psat);
          annotation(Inline = true);
        end bubbleEntropy;

        redeclare function extends dewEntropy  "Dew curve specific entropy of water"
        algorithm
          sv := IF97_Utilities.BaseIF97.Regions.sv_p(sat.psat);
          annotation(Inline = true);
        end dewEntropy;

        redeclare function extends bubbleDensity  "Boiling curve specific density of water"
        algorithm
          dl := if ph_explicit then IF97_Utilities.BaseIF97.Regions.rhol_p(sat.psat) else IF97_Utilities.BaseIF97.Regions.rhol_T(sat.Tsat);
          annotation(Inline = true);
        end bubbleDensity;

        redeclare function extends dewDensity  "Dew curve specific density of water"
        algorithm
          dv := if ph_explicit or pT_explicit then IF97_Utilities.BaseIF97.Regions.rhov_p(sat.psat) else IF97_Utilities.BaseIF97.Regions.rhov_T(sat.Tsat);
          annotation(Inline = true);
        end dewDensity;

        redeclare function extends saturationTemperature  "Saturation temperature of water"
        algorithm
          T := IF97_Utilities.BaseIF97.Basic.tsat(p);
          annotation(Inline = true);
        end saturationTemperature;

        redeclare function extends saturationTemperature_derp  "Derivative of saturation temperature w.r.t. pressure"
        algorithm
          dTp := IF97_Utilities.BaseIF97.Basic.dtsatofp(p);
          annotation(Inline = true);
        end saturationTemperature_derp;

        redeclare function extends saturationPressure  "Saturation pressure of water"
        algorithm
          p := IF97_Utilities.BaseIF97.Basic.psat(T);
          annotation(Inline = true);
        end saturationPressure;

        redeclare function extends dBubbleDensity_dPressure  "Bubble point density derivative"
        algorithm
          ddldp := IF97_Utilities.BaseIF97.Regions.drhol_dp(sat.psat);
          annotation(Inline = true);
        end dBubbleDensity_dPressure;

        redeclare function extends dDewDensity_dPressure  "Dew point density derivative"
        algorithm
          ddvdp := IF97_Utilities.BaseIF97.Regions.drhov_dp(sat.psat);
          annotation(Inline = true);
        end dDewDensity_dPressure;

        redeclare function extends dBubbleEnthalpy_dPressure  "Bubble point specific enthalpy derivative"
        algorithm
          dhldp := IF97_Utilities.BaseIF97.Regions.dhl_dp(sat.psat);
          annotation(Inline = true);
        end dBubbleEnthalpy_dPressure;

        redeclare function extends dDewEnthalpy_dPressure  "Dew point specific enthalpy derivative"
        algorithm
          dhvdp := IF97_Utilities.BaseIF97.Regions.dhv_dp(sat.psat);
          annotation(Inline = true);
        end dDewEnthalpy_dPressure;

        redeclare function extends setState_dTX  "Return thermodynamic state of water as function of d and T"
        algorithm
          state := ThermodynamicState(d = d, T = T, phase = 0, h = specificEnthalpy_dT(d, T), p = pressure_dT(d, T));
          annotation(Inline = true);
        end setState_dTX;

        redeclare function extends setState_phX  "Return thermodynamic state of water as function of p and h"
        algorithm
          state := ThermodynamicState(d = density_ph(p, h), T = temperature_ph(p, h), phase = 0, h = h, p = p);
          annotation(Inline = true);
        end setState_phX;

        redeclare function extends setState_psX  "Return thermodynamic state of water as function of p and s"
        algorithm
          state := ThermodynamicState(d = density_ps(p, s), T = temperature_ps(p, s), phase = 0, h = specificEnthalpy_ps(p, s), p = p);
          annotation(Inline = true);
        end setState_psX;

        redeclare function extends setState_pTX  "Return thermodynamic state of water as function of p and T"
        algorithm
          state := ThermodynamicState(d = density_pT(p, T), T = T, phase = 1, h = specificEnthalpy_pT(p, T), p = p);
          annotation(Inline = true);
        end setState_pTX;

        redeclare function extends setSmoothState  "Return thermodynamic state so that it smoothly approximates: if x > 0 then state_a else state_b"
        algorithm
          state := ThermodynamicState(p = .Modelica.Media.Common.smoothStep(x, state_a.p, state_b.p, x_small), h = .Modelica.Media.Common.smoothStep(x, state_a.h, state_b.h, x_small), d = density_ph(.Modelica.Media.Common.smoothStep(x, state_a.p, state_b.p, x_small), .Modelica.Media.Common.smoothStep(x, state_a.h, state_b.h, x_small)), T = temperature_ph(.Modelica.Media.Common.smoothStep(x, state_a.p, state_b.p, x_small), .Modelica.Media.Common.smoothStep(x, state_a.h, state_b.h, x_small)), phase = 0);
          annotation(Inline = true);
        end setSmoothState;
        annotation(Documentation(info = "<HTML>
         <p>
         This model calculates medium properties
         for water in the <b>liquid</b>, <b>gas</b> and <b>two phase</b> regions
         according to the IAPWS/IF97 standard, i.e., the accepted industrial standard
         and best compromise between accuracy and computation time.
         For more details see <a href=\"modelica://Modelica.Media.Water.IF97_Utilities\">
         Modelica.Media.Water.IF97_Utilities</a>. Three variable pairs can be the
         independent variables of the model:
         </p>
         <ol>
         <li>Pressure <b>p</b> and specific enthalpy <b>h</b> are the most natural choice for general applications. This is the recommended choice for most general purpose applications, in particular for power plants.</li>
         <li>Pressure <b>p</b> and temperature <b>T</b> are the most natural choice for applications where water is always in the same phase, both for liquid water and steam.</li>
         <li>Density <b>d</b> and temperature <b>T</b> are explicit variables of the Helmholtz function in the near-critical region and can be the best choice for applications with super-critical or near-critical states.</li>
         </ol>
         <p>
         The following quantities are always computed:
         </p>
         <table border=1 cellspacing=0 cellpadding=2>
           <tr><td valign=\"top\"><b>Variable</b></td>
               <td valign=\"top\"><b>Unit</b></td>
               <td valign=\"top\"><b>Description</b></td></tr>
           <tr><td valign=\"top\">T</td>
               <td valign=\"top\">K</td>
               <td valign=\"top\">temperature</td></tr>
           <tr><td valign=\"top\">u</td>
               <td valign=\"top\">J/kg</td>
               <td valign=\"top\">specific internal energy</td></tr>
           <tr><td valign=\"top\">d</td>
               <td valign=\"top\">kg/m^3</td>
               <td valign=\"top\">density</td></tr>
           <tr><td valign=\"top\">p</td>
               <td valign=\"top\">Pa</td>
               <td valign=\"top\">pressure</td></tr>
           <tr><td valign=\"top\">h</td>
               <td valign=\"top\">J/kg</td>
               <td valign=\"top\">specific enthalpy</td></tr>
         </table>
         <p>
         In some cases additional medium properties are needed.
         A component that needs these optional properties has to call
         one of the functions listed in
         <a href=\"modelica://Modelica.Media.UsersGuide.MediumUsage.OptionalProperties\">
         Modelica.Media.UsersGuide.MediumUsage.OptionalProperties</a> and in
         <a href=\"modelica://Modelica.Media.UsersGuide.MediumUsage.TwoPhase\">
         Modelica.Media.UsersGuide.MediumUsage.TwoPhase</a>.
         </p>
         <p>Many further properties can be computed. Using the well-known Bridgman's Tables, all first partial derivatives of the standard thermodynamic variables can be computed easily.</p>
         </html>"));
      end WaterIF97_base;

      package IF97_Utilities  "Low level and utility computation for high accuracy water properties according to the IAPWS/IF97 standard"
        extends Modelica.Icons.UtilitiesPackage;

        package BaseIF97  "Modelica Physical Property Model: the new industrial formulation IAPWS-IF97"
          extends Modelica.Icons.Package;

          record IterationData  "Constants for iterations internal to some functions"
            extends Modelica.Icons.Record;
            constant Integer IMAX = 50 "Maximum number of iterations for inverse functions";
            constant Real DELP = 0.000001 "Maximum iteration error in pressure, Pa";
            constant Real DELS = 0.00000001 "Maximum iteration error in specific entropy, J/{kg.K}";
            constant Real DELH = 0.00000001 "Maximum iteration error in specific enthalpy, J/kg";
            constant Real DELD = 0.00000001 "Maximum iteration error in density, kg/m^3";
          end IterationData;

          record data  "Constant IF97 data and region limits"
            extends Modelica.Icons.Record;
            constant .Modelica.SIunits.SpecificHeatCapacity RH2O = 461.526 "Specific gas constant of water vapour";
            constant .Modelica.SIunits.MolarMass MH2O = 0.01801528 "Molar weight of water";
            constant .Modelica.SIunits.Temperature TSTAR1 = 1386.0 "Normalization temperature for region 1 IF97";
            constant .Modelica.SIunits.Pressure PSTAR1 = 16530000.0 "Normalization pressure for region 1 IF97";
            constant .Modelica.SIunits.Temperature TSTAR2 = 540.0 "Normalization temperature for region 2 IF97";
            constant .Modelica.SIunits.Pressure PSTAR2 = 1000000.0 "Normalization pressure for region 2 IF97";
            constant .Modelica.SIunits.Temperature TSTAR5 = 1000.0 "Normalization temperature for region 5 IF97";
            constant .Modelica.SIunits.Pressure PSTAR5 = 1000000.0 "Normalization pressure for region 5 IF97";
            constant .Modelica.SIunits.SpecificEnthalpy HSTAR1 = 2500000.0 "Normalization specific enthalpy for region 1 IF97";
            constant Real IPSTAR = 0.000001 "Normalization pressure for inverse function in region 2 IF97";
            constant Real IHSTAR = 0.0000005 "Normalization specific enthalpy for inverse function in region 2 IF97";
            constant .Modelica.SIunits.Temperature TLIMIT1 = 623.15 "Temperature limit between regions 1 and 3";
            constant .Modelica.SIunits.Temperature TLIMIT2 = 1073.15 "Temperature limit between regions 2 and 5";
            constant .Modelica.SIunits.Temperature TLIMIT5 = 2273.15 "Upper temperature limit of 5";
            constant .Modelica.SIunits.Pressure PLIMIT1 = 100000000.0 "Upper pressure limit for regions 1, 2 and 3";
            constant .Modelica.SIunits.Pressure PLIMIT4A = 16529200.0 "Pressure limit between regions 1 and 2, important for for two-phase (region 4)";
            constant .Modelica.SIunits.Pressure PLIMIT5 = 10000000.0 "Upper limit of valid pressure in region 5";
            constant .Modelica.SIunits.Pressure PCRIT = 22064000.0 "The critical pressure";
            constant .Modelica.SIunits.Temperature TCRIT = 647.096 "The critical temperature";
            constant .Modelica.SIunits.Density DCRIT = 322.0 "The critical density";
            constant .Modelica.SIunits.SpecificEntropy SCRIT = 4412.02148223476 "The calculated specific entropy at the critical point";
            constant .Modelica.SIunits.SpecificEnthalpy HCRIT = 2087546.84511715 "The calculated specific enthalpy at the critical point";
            constant Real[5] n = array(348.05185628969, -1.1671859879975, 0.0010192970039326, 572.54459862746, 13.91883977887) "Polynomial coefficients for boundary between regions 2 and 3";
            annotation(Documentation(info = "<HTML>
              <h4>Record description</h4>
                                        <p>Constants needed in the international steam properties IF97.
                                        SCRIT and HCRIT are calculated from Helmholtz function for region 3.</p>
             <h4>Version Info and Revision history
             </h4>
             <ul>
             <li>First implemented: <i>July, 2000</i>
                    by Hubertus Tummescheit
                    </li>
             </ul>
              <address>Author: Hubertus Tummescheit, <br>
                   Modelon AB<br>
                   Ideon Science Park<br>
                   SE-22370 Lund, Sweden<br>
                   email: hubertus@modelon.se
              </address>
             <ul>
              <li>Initial version: July 2000</li>
              <li>Documentation added: December 2002</li>
             </ul>
             </html>"));
          end data;

          record triple  "Triple point data"
            extends Modelica.Icons.Record;
            constant .Modelica.SIunits.Temperature Ttriple = 273.16 "The triple point temperature";
            constant .Modelica.SIunits.Pressure ptriple = 611.657 "The triple point temperature";
            constant .Modelica.SIunits.Density dltriple = 999.7925200316176 "The triple point liquid density";
            constant .Modelica.SIunits.Density dvtriple = 0.004854575724778614 "The triple point vapour density";
            annotation(Documentation(info = "<HTML>
              <h4>Record description</h4>
              <p>Vapour/liquid/ice triple point data for IF97 steam properties.</p>
             <h4>Version Info and Revision history
             </h4>
             <ul>
             <li>First implemented: <i>July, 2000</i>
                    by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>
                    </li>
             </ul>
              <address>Author: Hubertus Tummescheit, <br>
                   Modelon AB<br>
                   Ideon Science Park<br>
                   SE-22370 Lund, Sweden<br>
                   email: hubertus@modelon.se
              </address>
             <ul>
              <li>Initial version: July 2000</li>
              <li>Documentation added: December 2002</li>
             </ul>
             </html>"));
          end triple;

          package Regions  "Functions to find the current region for given pairs of input variables"
            extends Modelica.Icons.Package;

            function boundary23ofT  "Boundary function for region boundary between regions 2 and 3 (input temperature)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Temperature t "Temperature (K)";
              output .Modelica.SIunits.Pressure p "Pressure";
            protected
              constant Real[5] n = data.n;
            algorithm
              p := 1000000.0 * (n[1] + t * (n[2] + t * n[3]));
            end boundary23ofT;

            function boundary23ofp  "Boundary function for region boundary between regions 2 and 3 (input pressure)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.Temperature t "Temperature (K)";
            protected
              constant Real[5] n = data.n;
              Real pi "Dimensionless pressure";
            algorithm
              pi := p / 1000000.0;
              assert(p > triple.ptriple, "IF97 medium function boundary23ofp called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              t := n[4] + ((pi - n[5]) / n[3]) ^ 0.5;
            end boundary23ofp;

            function hlowerofp5  "Explicit lower specific enthalpy limit of region 5 as function of pressure"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
            protected
              Real pi "Dimensionless pressure";
            algorithm
              pi := p / data.PSTAR5;
              assert(p > triple.ptriple, "IF97 medium function hlowerofp5 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              h := 461526.0 * (9.01505286876203 + pi * (-0.00979043490246092 + (-0.0000203245575263501 + 0.000000336540214679088 * pi) * pi));
            end hlowerofp5;

            function hupperofp5  "Explicit upper specific enthalpy limit of region 5 as function of pressure"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
            protected
              Real pi "Dimensionless pressure";
            algorithm
              pi := p / data.PSTAR5;
              assert(p > triple.ptriple, "IF97 medium function hupperofp5 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              h := 461526.0 * (15.9838891400332 + pi * (-0.000489898813722568 + (-0.0000000501510211858761 + 0.000000075006972718273 * pi) * pi));
            end hupperofp5;

            function slowerofp5  "Explicit lower specific entropy limit of region 5 as function of pressure"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.SpecificEntropy s "Specific entropy";
            protected
              Real pi "Dimensionless pressure";
            algorithm
              pi := p / data.PSTAR5;
              assert(p > triple.ptriple, "IF97 medium function slowerofp5 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              s := 461.526 * (18.4296209980112 + pi * (-0.00730911805860036 + (-0.0000168348072093888 + 0.000000209066899426354 * pi) * pi) - Modelica.Math.log(pi));
            end slowerofp5;

            function supperofp5  "Explicit upper specific entropy limit of region 5 as function of pressure"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.SpecificEntropy s "Specific entropy";
            protected
              Real pi "Dimensionless pressure";
            algorithm
              pi := p / data.PSTAR5;
              assert(p > triple.ptriple, "IF97 medium function supperofp5 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              s := 461.526 * (22.7281531474243 + pi * (-0.000656650220627603 + (-0.0000000196109739782049 + 0.0000000219979537113031 * pi) * pi) - Modelica.Math.log(pi));
            end supperofp5;

            function hlowerofp1  "Explicit lower specific enthalpy limit of region 1 as function of pressure"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
            protected
              Real pi1 "Dimensionless pressure";
              Real[3] o "Vector of auxiliary variables";
            algorithm
              pi1 := 7.1 - p / data.PSTAR1;
              assert(p > triple.ptriple, "IF97 medium function hlowerofp1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              o[1] := pi1 * pi1;
              o[2] := o[1] * o[1];
              o[3] := o[2] * o[2];
              h := 639675.036 * (0.173379420894777 + pi1 * (-0.022914084306349 + pi1 * (-0.00017146768241932 + pi1 * (-0.00000418695814670391 + pi1 * (-0.000000241630417490008 + pi1 * (0.0000000000173545618580828 + o[1] * pi1 * (0.0000000000000843755552264362 + o[2] * o[3] * pi1 * (5.35429206228374e-35 + o[1] * (-8.12140581014818e-38 + o[1] * o[2] * (-1.43870236842915e-44 + pi1 * (1.73894459122923e-45 + (-7.06381628462585e-47 + 9.64504638626269e-49 * pi1) * pi1)))))))))));
            end hlowerofp1;

            function hupperofp1  "Explicit upper specific enthalpy limit of region 1 as function of pressure (meets region 4 saturation pressure curve at 623.15 K)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
            protected
              Real pi1 "Dimensionless pressure";
              Real[3] o "Vector of auxiliary variables";
            algorithm
              pi1 := 7.1 - p / data.PSTAR1;
              assert(p > triple.ptriple, "IF97 medium function hupperofp1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              o[1] := pi1 * pi1;
              o[2] := o[1] * o[1];
              o[3] := o[2] * o[2];
              h := 639675.036 * (2.42896927729349 + pi1 * (-0.00141131225285294 + pi1 * (0.00143759406818289 + pi1 * (0.000125338925082983 + pi1 * (0.0000123617764767172 + pi1 * (0.00000317834967400818 + o[1] * pi1 * (0.0000000146754947271665 + o[2] * o[3] * pi1 * (0.0000000000000000186779322717506 + o[1] * (-0.000000000000000000418568363667416 + o[1] * o[2] * (-0.000000000000000000000919148577641497 + pi1 * (0.000000000000000000000427026404402408 + (-0.0000000000000000000000666749357417962 + 0.00000000000000000000000349930466305574 * pi1) * pi1)))))))))));
            end hupperofp1;

            function supperofp1  "Explicit upper specific entropy limit of region 1 as function of pressure (meets region 4 saturation pressure curve at 623.15 K)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.SpecificEntropy s "Specific entropy";
            protected
              Real pi1 "Dimensionless pressure";
              Real[3] o "Vector of auxiliary variables";
            algorithm
              pi1 := 7.1 - p / data.PSTAR1;
              assert(p > triple.ptriple, "IF97 medium function supperofp1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              o[1] := pi1 * pi1;
              o[2] := o[1] * o[1];
              o[3] := o[2] * o[2];
              s := 461.526 * (7.28316418503422 + pi1 * (0.070602197808399 + pi1 * (0.0039229343647356 + pi1 * (0.000313009170788845 + pi1 * (0.0000303619398631619 + pi1 * (0.00000746739440045781 + o[1] * pi1 * (0.0000000340562176858676 + o[2] * o[3] * pi1 * (0.0000000000000000421886233340801 + o[1] * (-0.000000000000000000944504571473549 + o[1] * o[2] * (-0.00000000000000000000206859611434475 + pi1 * (0.000000000000000000000960758422254987 + (-0.000000000000000000000149967810652241 + 0.00000000000000000000000786863124555783 * pi1) * pi1)))))))))));
            end supperofp1;

            function hlowerofp2  "Explicit lower specific enthalpy limit of region 2 as function of pressure (meets region 4 saturation pressure curve at 623.15 K)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
            protected
              Real pi "Dimensionless pressure";
              Real q1 "Auxiliary variable";
              Real q2 "Auxiliary variable";
              Real[18] o "Vector of auxiliary variables";
            algorithm
              pi := p / data.PSTAR2;
              assert(p > triple.ptriple, "IF97 medium function hlowerofp2 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              q1 := 572.54459862746 + 31.3220101646784 * (-13.91883977887 + pi) ^ 0.5;
              q2 := -0.5 + 540.0 / q1;
              o[1] := q1 * q1;
              o[2] := o[1] * o[1];
              o[3] := o[2] * o[2];
              o[4] := pi * pi;
              o[5] := o[4] * o[4];
              o[6] := q2 * q2;
              o[7] := o[6] * o[6];
              o[8] := o[6] * o[7];
              o[9] := o[5] * o[5];
              o[10] := o[7] * o[7];
              o[11] := o[9] * o[9];
              o[12] := o[10] * o[10];
              o[13] := o[12] * o[12];
              o[14] := o[7] * q2;
              o[15] := o[6] * q2;
              o[16] := o[10] * o[6];
              o[17] := o[13] * o[6];
              o[18] := o[13] * o[6] * q2;
              h := (4636975733.03507 + 3.74686560065793 * o[2] + 0.00000357966647812489 * o[1] * o[2] + 0.000000000000281881548488163 * o[3] - 76465233.2452145 * q1 - 0.00450789338787835 * o[2] * q1 - 0.00000000155131504410292 * o[1] * o[2] * q1 + o[1] * (2513837.07870341 - 4781981.98764471 * o[10] * o[11] * o[12] * o[13] * o[4] + 49.9651389369988 * o[11] * o[12] * o[13] * o[4] * o[5] * o[7] + o[15] * o[4] * (0.000000000000103746636552761 - 0.00349547959376899 * o[16] - 0.000000255074501962569 * o[8]) * o[9] + (-242662.235426958 * o[10] * o[12] - 3.46022402653609 * o[16]) * o[4] * o[5] * pi + o[4] * (0.109336249381227 - 2248.08924686956 * o[14] - 354742.725841972 * o[17] - 24.1331193696374 * o[6]) * pi - 0.000000000000000000309081828396912 * o[11] * o[12] * o[5] * o[7] * pi - 0.0000000124107527851371 * o[11] * o[13] * o[4] * o[5] * o[6] * o[7] * pi + 3.99891272904219 * o[5] * o[8] * pi + 0.0641817365250892 * o[10] * o[7] * o[9] * pi + pi * (-4444.87643334512 - 75253.6156722047 * o[14] - 43051.9020511789 * o[6] - 22926.6247146068 * q2) + o[4] * (-8.23252840892034 - 3927.0508365636 * o[15] - 239.325789467604 * o[18] - 76407.3727417716 * o[8] - 94.4508644545118 * q2) + 0.360567666582363 * o[5] * (-0.0161221195808321 + q2) * (0.0338039844460968 + q2) + o[11] * (-0.000584580992538624 * o[10] * o[12] * o[7] + 1332480.30241755 * o[12] * o[13] * q2) + o[9] * (-73850273.6990986 * o[18] + 0.0000224425477627799 * o[6] * o[7] * q2) + o[4] * o[5] * (-208438767.026518 * o[17] - 0.0000124971648677697 * o[6] - 8442.30378348203 * o[10] * o[6] * o[7] * q2) + o[11] * o[9] * (0.000000000000000000000473594929247646 * o[10] * o[12] * q2 - 13.6411358215175 * o[10] * o[12] * o[13] * q2 + 0.000000000552427169406836 * o[13] * o[6] * o[7] * q2) + o[11] * o[5] * (0.00000267174673301715 * o[17] + 0.00000000000000000444545133805865 * o[12] * o[6] * q2 - 50.2465185106411 * o[10] * o[13] * o[6] * o[7] * q2))) / o[1];
            end hlowerofp2;

            function hupperofp2  "Explicit upper specific enthalpy limit of region 2 as function of pressure"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
            protected
              Real pi "Dimensionless pressure";
              Real[2] o "Vector of auxiliary variables";
            algorithm
              pi := p / data.PSTAR2;
              assert(p > triple.ptriple, "IF97 medium function hupperofp2 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              o[1] := pi * pi;
              o[2] := o[1] * o[1] * o[1];
              h := 4160663.37647071 + pi * (-4518.48617188327 + pi * (-8.53409968320258 + pi * (0.109090430596056 + pi * (-0.000172486052272327 + pi * (0.0000000000000042261295097284 + pi * (-0.000000000127295130636232 + pi * (-0.000000000000000000000000379407294691742 + pi * (0.0000000000000000000000756960433802525 + pi * (7.16825117265975e-32 + pi * (0.00000000000000000000337267475986401 + (-7.5656940729795e-74 + o[1] * (-8.00969737237617e-134 + (1.6746290980312e-65 + pi * (-3.71600586812966e-69 + pi * (8.06630589170884e-129 + (-1.76117969553159e-103 + 1.88543121025106e-84 * pi) * pi))) * o[1])) * o[2]))))))))));
            end hupperofp2;

            function slowerofp2  "Explicit lower specific entropy limit of region 2 as function of pressure (meets region 4 saturation pressure curve at 623.15 K)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.SpecificEntropy s "Specific entropy";
            protected
              Real pi "Dimensionless pressure";
              Real q1 "Auxiliary variable";
              Real q2 "Auxiliary variable";
              Real[40] o "Vector of auxiliary variables";
            algorithm
              pi := p / data.PSTAR2;
              assert(p > triple.ptriple, "IF97 medium function slowerofp2 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              q1 := 572.54459862746 + 31.3220101646784 * (-13.91883977887 + pi) ^ 0.5;
              q2 := -0.5 + 540.0 / q1;
              o[1] := pi * pi;
              o[2] := o[1] * pi;
              o[3] := o[1] * o[1];
              o[4] := o[1] * o[3] * pi;
              o[5] := q1 * q1;
              o[6] := o[5] * q1;
              o[7] := 1 / o[5];
              o[8] := 1 / q1;
              o[9] := o[5] * o[5];
              o[10] := o[9] * q1;
              o[11] := q2 * q2;
              o[12] := o[11] * q2;
              o[13] := o[1] * o[3];
              o[14] := o[11] * o[11];
              o[15] := o[3] * o[3];
              o[16] := o[1] * o[15];
              o[17] := o[11] * o[14];
              o[18] := o[11] * o[14] * q2;
              o[19] := o[3] * pi;
              o[20] := o[14] * o[14];
              o[21] := o[11] * o[20];
              o[22] := o[15] * pi;
              o[23] := o[14] * o[20] * q2;
              o[24] := o[20] * o[20];
              o[25] := o[15] * o[15];
              o[26] := o[25] * o[3];
              o[27] := o[14] * o[24];
              o[28] := o[25] * o[3] * pi;
              o[29] := o[20] * o[24] * q2;
              o[30] := o[15] * o[25];
              o[31] := o[24] * o[24];
              o[32] := o[11] * o[31] * q2;
              o[33] := o[14] * o[31];
              o[34] := o[1] * o[25] * o[3] * pi;
              o[35] := o[11] * o[14] * o[31] * q2;
              o[36] := o[1] * o[25] * o[3];
              o[37] := o[1] * o[25];
              o[38] := o[20] * o[24] * o[31] * q2;
              o[39] := o[14] * q2;
              o[40] := o[11] * o[31];
              s := 461.526 * (9.692768600217 + 0.000000000000000122151969114703 * o[10] + 0.00018948987516315 * o[1] * o[11] + 0.000000000016714766451061 * o[12] * o[13] + 0.0039392777243355 * o[1] * o[14] - 0.00000000000000000010406965210174 * o[14] * o[16] + 0.043797295650573 * o[1] * o[18] - 0.0000022922076337661 * o[18] * o[19] - 0.000000020481737692309 * o[2] + 0.00003227767723857 * o[12] * o[2] + 0.0015033924542148 * o[17] * o[2] - 0.000000000011256211360459 * o[15] * o[20] + 0.0000000010018179379511 * o[11] * o[14] * o[16] * o[20] + 0.00000000000010234747095929 * o[16] * o[21] - 0.000000019809712802088 * o[22] * o[23] + 0.0021171472321355 * o[13] * o[24] - 0.00000000000000000000000089185845355421 * o[26] * o[27] - 0.000000012790717852285 * o[11] * o[3] - 0.00000048225372718507 * o[12] * o[3] - 0.000000000000000000000000000073087610595061 * o[11] * o[20] * o[24] * o[30] - 0.10693031879409 * o[11] * o[24] * o[25] * o[31] + 0.0000042002467698208 * o[24] * o[26] * o[31] - 0.000000000000000055414715350778 * o[20] * o[30] * o[31] + 0.0000009436970724121 * o[11] * o[20] * o[24] * o[30] * o[31] + 23.895741934104 * o[13] * o[32] + 0.040668253562649 * o[2] * o[32] - 0.00000000000030629316876232 * o[26] * o[32] + 0.000026674547914087 * o[1] * o[33] + 8.2311340897998 * o[15] * o[33] + 0.0000000000000012768608934681 * o[34] * o[35] + 0.33662250574171 * o[37] * o[38] + 0.000000000000000005905956432427 * o[4] + 0.038946842435739 * o[29] * o[4] - 0.00000488368302964335 * o[5] - 3349017.34177133 / o[6] + 0.00000000258538448402683 * o[6] + 82839.5726841115 * o[7] - 5446.7940672972 * o[8] - 0.000000000000840318337484194 * o[9] + 0.0017731742473213 * pi + 0.045996013696365 * o[11] * pi + 0.057581259083432 * o[12] * pi + 0.05032527872793 * o[17] * pi + o[8] * pi * (9.63082563787332 - 0.008917431146179 * q1) + 0.00811842799898148 * q1 + 0.000033032641670203 * o[1] * q2 - 0.00000043870667284435 * o[2] * q2 + 0.000000000080882908646985 * o[14] * o[20] * o[24] * o[25] * q2 + 0.000000000000000000000000059056029685639 * o[14] * o[24] * o[28] * q2 + 0.00000000078847309559367 * o[3] * q2 - 0.0000037826947613457 * o[14] * o[24] * o[31] * o[36] * q2 + 0.0000012621808899101 * o[11] * o[20] * o[4] * q2 + 540.0 * o[8] * (10.08665568018 - 0.000033032641670203 * o[1] - 0.0000000000000062245802776607 * o[10] - 0.015757110897342 * o[1] * o[12] - 0.000000000050144299353183 * o[11] * o[13] + 0.00000000000000000041627860840696 * o[12] * o[16] - 0.306581069554011 * o[1] * o[17] + 0.000000000090049690883672 * o[15] * o[18] + 0.0000160454534363627 * o[17] * o[19] + 0.00000043870667284435 * o[2] - 0.00009683303171571 * o[11] * o[2] + 0.000000257526266427144 * o[14] * o[20] * o[22] - 0.0000000140254511313154 * o[16] * o[23] - 0.00000000234560435076256 * o[14] * o[20] * o[24] * o[25] - 0.00000000000000000000000124017662339842 * o[27] * o[28] - 0.00000000078847309559367 * o[3] + 0.00000144676118155521 * o[11] * o[3] + 0.00000000000000000000000000190027787547159 * o[29] * o[30] - 0.000960283724907132 * o[1] * o[32] - 296.320827232793 * o[15] * o[32] - 0.0000000000000497975748452559 * o[11] * o[14] * o[31] * o[34] + 0.00000000000000221658861403112 * o[30] * o[35] + 0.000200482822351322 * o[14] * o[24] * o[31] * o[36] - 19.1874828272775 * o[20] * o[24] * o[31] * o[37] - 0.0000547344301999018 * o[30] * o[38] - 0.0090203547252888 * o[2] * o[39] - 0.0000138839897890111 * o[21] * o[4] - 0.973671060893475 * o[20] * o[24] * o[4] - 836.35096769364 * o[13] * o[40] - 1.42338887469272 * o[2] * o[40] + 0.0000000000107202609066812 * o[26] * o[40] + 0.0000150341259240398 * o[5] - 0.000000018087714924605 * o[6] + 18605.6518987296 * o[7] - 306.813232163376 * o[8] + 0.0000000000143632471334824 * o[9] + 0.00000000000000000113103675106207 * o[5] * o[9] - 0.017834862292358 * pi - 0.172743777250296 * o[11] * pi - 0.30195167236758 * o[39] * pi + o[8] * pi * (-49.6756947920742 + 0.045996013696365 * q1) - 0.0003789797503263 * o[1] * q2 - 0.033874355714168 * o[11] * o[13] * o[14] * o[20] * q2 - 0.0000000000010234747095929 * o[16] * o[20] * q2 + 0.0000000000000000000000178371690710842 * o[11] * o[24] * o[26] * q2 + 0.00000002558143570457 * o[3] * q2 + 5.3465159397045 * o[24] * o[25] * o[31] * q2 - 0.000201611844951398 * o[11] * o[14] * o[20] * o[26] * o[31] * q2) - Modelica.Math.log(pi));
            end slowerofp2;

            function supperofp2  "Explicit upper specific entropy limit of region 2 as function of pressure"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.SpecificEntropy s "Specific entropy";
            protected
              Real pi "Dimensionless pressure";
              Real[2] o "Vector of auxiliary variables";
            algorithm
              pi := p / data.PSTAR2;
              assert(p > triple.ptriple, "IF97 medium function supperofp2 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              o[1] := pi * pi;
              o[2] := o[1] * o[1] * o[1];
              s := 8505.73409708683 - 461.526 * Modelica.Math.log(pi) + pi * (-3.36563543302584 + pi * (-0.00790283552165338 + pi * (0.0000915558349202221 + pi * (-0.000000159634706513 + pi * (0.00000000000000000393449217595397 + pi * (-0.000000000000118367426347994 + pi * (0.00000000000000272575244843195 + pi * (0.0000000000000000000000000704803892603536 + pi * (6.67637687381772e-35 + pi * (0.0000000000000000000000031377970315132 + (-7.04844558482265e-77 + o[1] * (-7.46289531275314e-137 + (1.55998511254305e-68 + pi * (-3.46166288915497e-72 + pi * (7.51557618628583e-132 + (-1.64086406733212e-106 + 1.75648443097063e-87 * pi) * pi))) * o[1])) * o[2] * o[2]))))))))));
            end supperofp2;

            function d1n  "Density in region 1 as function of p and T"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.Temperature T "Temperature (K)";
              output .Modelica.SIunits.Density d "Density";
            protected
              Real pi "Dimensionless pressure";
              Real pi1 "Dimensionless pressure";
              Real tau "Dimensionless temperature";
              Real tau1 "Dimensionless temperature";
              Real gpi "Dimensionless Gibbs-derivative w.r.t. pi";
              Real[11] o "Auxiliary variables";
            algorithm
              pi := p / data.PSTAR1;
              tau := data.TSTAR1 / T;
              pi1 := 7.1 - pi;
              tau1 := tau - 1.222;
              o[1] := tau1 * tau1;
              o[2] := o[1] * o[1];
              o[3] := o[2] * o[2];
              o[4] := o[1] * o[2];
              o[5] := o[1] * tau1;
              o[6] := o[2] * tau1;
              o[7] := pi1 * pi1;
              o[8] := o[7] * o[7];
              o[9] := o[8] * o[8];
              o[10] := o[3] * o[3];
              o[11] := o[10] * o[10];
              gpi := pi1 * (pi1 * ((0.000095038934535162 + o[2] * (0.0000084812393955936 + 0.00000000255615384360309 * o[4])) / o[2] + pi1 * ((0.0000089701127632 + (0.00000260684891582404 + 0.00000000000057366919751696 * o[2] * o[3]) * o[5]) / o[6] + pi1 * (0.00000202584984300585 / o[3] + o[7] * pi1 * (o[8] * o[9] * pi1 * (o[7] * (o[7] * o[8] * (-0.000000000000000000000763737668221055 / (o[1] * o[11] * o[2]) + pi1 * (pi1 * (-0.0000000000000000000000565070932023524 / (o[11] * o[3]) + 0.00000000000000000000000299318679335866 * pi1 / (o[11] * o[3] * tau1)) + 0.00000000000000000000035842867920213 / (o[1] * o[11] * o[2] * tau1))) - 0.000000000000000000333001080055983 / (o[1] * o[10] * o[2] * o[3] * tau1)) + 0.0000000000000000144400475720615 / (o[10] * o[2] * o[3] * tau1)) + (0.0000000101874413933128 + 0.00000000139398969845072 * o[6]) / (o[1] * o[3] * tau1))))) + (0.00094368642146534 + o[5] * (0.00060003561586052 + (-0.000095322787813974 + o[1] * (0.0000088283690661692 + 0.00000000000000145389992595188 * o[1] * o[2] * o[3])) * tau1)) / o[5]) + (-0.00028319080123804 + o[1] * (0.00060706301565874 + o[4] * (0.018990068218419 + tau1 * (0.032529748770505 + (0.021841717175414 + 0.00005283835796993 * o[1]) * tau1)))) / (o[3] * tau1);
              d := p / (data.RH2O * T * pi * gpi);
            end d1n;

            function d2n  "Density in region 2 as function of p and T"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.Temperature T "Temperature (K)";
              output .Modelica.SIunits.Density d "Density";
            protected
              Real pi "Dimensionless pressure";
              Real tau "Dimensionless temperature";
              Real tau2 "Dimensionless temperature";
              Real gpi "Dimensionless Gibbs-derivative w.r.t. pi";
              Real[12] o "Auxiliary variables";
            algorithm
              pi := p / data.PSTAR2;
              tau := data.TSTAR2 / T;
              tau2 := tau - 0.5;
              o[1] := tau2 * tau2;
              o[2] := o[1] * tau2;
              o[3] := o[1] * o[1];
              o[4] := o[3] * o[3];
              o[5] := o[4] * o[4];
              o[6] := o[3] * o[4] * o[5] * tau2;
              o[7] := o[3] * o[4] * tau2;
              o[8] := o[1] * o[3] * o[4];
              o[9] := pi * pi;
              o[10] := o[9] * o[9];
              o[11] := o[3] * o[5] * tau2;
              o[12] := o[5] * o[5];
              gpi := (1.0 + pi * (-0.0017731742473213 + tau2 * (-0.017834862292358 + tau2 * (-0.045996013696365 + (-0.057581259083432 - 0.05032527872793 * o[2]) * tau2)) + pi * (tau2 * (-0.000066065283340406 + (-0.0003789797503263 + o[1] * (-0.007878555448671 + o[2] * (-0.087594591301146 - 0.000053349095828174 * o[6]))) * tau2) + pi * (0.000000061445213076927 + (0.00000131612001853305 + o[1] * (-0.00009683303171571 + o[2] * (-0.0045101773626444 - 0.122004760687947 * o[6]))) * tau2 + pi * (tau2 * (-0.00000000315389238237468 + (0.00000005116287140914 + 0.00000192901490874028 * tau2) * tau2) + pi * (0.0000114610381688305 * o[1] * o[3] * tau2 + pi * (o[2] * (-0.000000000100288598706366 + o[7] * (-0.012702883392813 - 143.374451604624 * o[1] * o[5] * tau2)) + pi * (-0.000000000000000041341695026989 + o[1] * o[4] * (-0.0000088352662293707 - 0.272627897050173 * o[8]) * tau2 + pi * (o[4] * (0.000000000090049690883672 - 65.8490727183984 * o[3] * o[4] * o[5]) + pi * (0.000000178287415218792 * o[7] + pi * (o[3] * (0.0000000000000000010406965210174 + o[1] * (-0.0000000000010234747095929 - 0.000000010018179379511 * o[3]) * o[3]) + o[10] * o[9] * ((-0.00000000129412653835176 + 1.71088510070544 * o[11]) * o[6] + o[9] * (-6.05920510335078 * o[12] * o[4] * o[5] * tau2 + o[9] * (o[3] * o[5] * (0.0000000000000000000000178371690710842 + o[1] * o[3] * o[4] * (0.0000000000061258633752464 - 0.000084004935396416 * o[7]) * tau2) + pi * (-0.00000000000000000000000124017662339842 * o[11] + pi * (0.0000832192847496054 * o[12] * o[3] * o[5] * tau2 + pi * (o[1] * o[4] * o[5] * (0.00000000000000000000000000175410265428146 + (0.00000000000000132995316841867 - 0.0000226487297378904 * o[1] * o[5]) * o[8]) * pi - 0.0000000000000293678005497663 * o[1] * o[12] * o[3] * tau2))))))))))))))))) / pi;
              d := p / (data.RH2O * T * pi * gpi);
            end d2n;

            function hl_p_R4b  "Explicit approximation of liquid specific enthalpy on the boundary between regions 4 and 3"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
            protected
              Real x "Auxiliary variable";
            algorithm
              x := Modelica.Math.acos(p / data.PCRIT);
              h := (1 + x * (-0.4945586958175176 + x * (1.346800016564904 + x * (-3.889388153209752 + x * (6.679385472887931 + x * (-6.75820241066552 + x * (3.558919744656498 + (-0.717981855497894 - 0.0001152032945617821 * x) * x))))))) * data.HCRIT;
            end hl_p_R4b;

            function hv_p_R4b  "Explicit approximation of vapour specific enthalpy on the boundary between regions 4 and 3"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
            protected
              Real x "Auxiliary variable";
            algorithm
              x := Modelica.Math.acos(p / data.PCRIT);
              h := (1 + x * (0.4880153718655694 + x * (0.2079670746250689 + x * (-6.084122698421623 + x * (25.08887602293532 + x * (-48.38215180269516 + x * (45.66489164833212 + (-16.98555442961553 + 0.0006616936460057692 * x) * x))))))) * data.HCRIT;
            end hv_p_R4b;

            function sl_p_R4b  "Explicit approximation of liquid specific entropy on the boundary between regions 4 and 3"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.SpecificEntropy s "Specific entropy";
            protected
              Real x "Auxiliary variable";
            algorithm
              x := Modelica.Math.acos(p / data.PCRIT);
              s := (1 + x * (-0.36160692245648063 + x * (0.9962778630486647 + x * (-2.8595548144171103 + x * (4.906301159555333 + x * (-4.974092309614206 + x * (2.6249651699204457 + (-0.5319954375299023 - 0.00008064497431880644 * x) * x))))))) * data.SCRIT;
            end sl_p_R4b;

            function sv_p_R4b  "Explicit approximation of vapour specific entropy on the boundary between regions 4 and 3"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.SpecificEntropy s;
            protected
              Real x "Auxiliary variable";
            algorithm
              x := Modelica.Math.acos(p / data.PCRIT);
              s := (1 + x * (0.35682641826674344 + x * (0.1642457027815487 + x * (-4.425350377422446 + x * (18.324477859983133 + x * (-35.338631625948665 + x * (33.36181025816282 + (-12.408711490585757 + 0.0004810049834109226 * x) * x))))))) * data.SCRIT;
            end sv_p_R4b;

            function rhol_p_R4b  "Explicit approximation of liquid density on the boundary between regions 4 and 3"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.Density dl "Liquid density";
            protected
              Real x "Auxiliary variable";
            algorithm
              if p < data.PCRIT then
                x := Modelica.Math.acos(p / data.PCRIT);
                dl := (1 + x * (1.903224079094824 + x * (-2.5314861802401123 + x * (-8.191449323843552 + x * (94.34196116778385 + x * (-369.3676833623383 + x * (796.6627910598293 + x * (-994.5385383600702 + x * (673.2581177021598 + (-191.43077336405156 + 0.00052536560808895 * x) * x))))))))) * data.DCRIT;
              else
                dl := data.DCRIT;
              end if;
            end rhol_p_R4b;

            function rhov_p_R4b  "Explicit approximation of vapour density on the boundary between regions 4 and 2"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.Density dv "Vapour density";
            protected
              Real x "Auxiliary variable";
            algorithm
              if p < data.PCRIT then
                x := Modelica.Math.acos(p / data.PCRIT);
                dv := (1 + x * (-1.8463850803362596 + x * (-1.1447872718878493 + x * (59.18702203076563 + x * (-403.5391431811611 + x * (1437.2007245332388 + x * (-3015.853540307519 + x * (3740.5790348670057 + x * (-2537.375817253895 + (725.8761975803782 - 0.0011151111658332337 * x) * x))))))))) * data.DCRIT;
              else
                dv := data.DCRIT;
              end if;
            end rhov_p_R4b;

            function boilingcurve_p  "Properties on the boiling curve"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output Common.IF97PhaseBoundaryProperties bpro "Property record";
            protected
              Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives";
              Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives";
              .Modelica.SIunits.Pressure plim = min(p, data.PCRIT - 0.0000001) "Pressure limited to critical pressure - epsilon";
            algorithm
              bpro.R := data.RH2O;
              bpro.T := Basic.tsat(plim);
              bpro.dpT := Basic.dptofT(bpro.T);
              bpro.region3boundary := bpro.T > data.TLIMIT1;
              if not bpro.region3boundary then
                g := Basic.g1(p, bpro.T);
                bpro.d := p / (bpro.R * bpro.T * g.pi * g.gpi);
                bpro.h := if p > plim then data.HCRIT else bpro.R * bpro.T * g.tau * g.gtau;
                bpro.s := g.R * (g.tau * g.gtau - g.g);
                bpro.cp := -bpro.R * g.tau * g.tau * g.gtautau;
                bpro.vt := bpro.R / p * (g.pi * g.gpi - g.tau * g.pi * g.gtaupi);
                bpro.vp := bpro.R * bpro.T / (p * p) * g.pi * g.pi * g.gpipi;
                bpro.pt := -p / bpro.T * (g.gpi - g.tau * g.gtaupi) / (g.gpipi * g.pi);
                bpro.pd := -bpro.R * bpro.T * g.gpi * g.gpi / g.gpipi;
              else
                bpro.d := rhol_p_R4b(plim);
                f := Basic.f3(bpro.d, bpro.T);
                bpro.h := hl_p_R4b(plim);
                bpro.s := f.R * (f.tau * f.ftau - f.f);
                bpro.cv := bpro.R * (-f.tau * f.tau * f.ftautau);
                bpro.pt := bpro.R * bpro.d * f.delta * (f.fdelta - f.tau * f.fdeltatau);
                bpro.pd := bpro.R * bpro.T * f.delta * (2.0 * f.fdelta + f.delta * f.fdeltadelta);
              end if;
            end boilingcurve_p;

            function dewcurve_p  "Properties on the dew curve"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output Common.IF97PhaseBoundaryProperties bpro "Property record";
            protected
              Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives";
              Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives";
              .Modelica.SIunits.Pressure plim = min(p, data.PCRIT - 0.0000001) "Pressure limited to critical pressure - epsilon";
            algorithm
              bpro.R := data.RH2O;
              bpro.T := Basic.tsat(plim);
              bpro.dpT := Basic.dptofT(bpro.T);
              bpro.region3boundary := bpro.T > data.TLIMIT1;
              if not bpro.region3boundary then
                g := Basic.g2(p, bpro.T);
                bpro.d := p / (bpro.R * bpro.T * g.pi * g.gpi);
                bpro.h := if p > plim then data.HCRIT else bpro.R * bpro.T * g.tau * g.gtau;
                bpro.s := g.R * (g.tau * g.gtau - g.g);
                bpro.cp := -bpro.R * g.tau * g.tau * g.gtautau;
                bpro.vt := bpro.R / p * (g.pi * g.gpi - g.tau * g.pi * g.gtaupi);
                bpro.vp := bpro.R * bpro.T / (p * p) * g.pi * g.pi * g.gpipi;
                bpro.pt := -p / bpro.T * (g.gpi - g.tau * g.gtaupi) / (g.gpipi * g.pi);
                bpro.pd := -bpro.R * bpro.T * g.gpi * g.gpi / g.gpipi;
              else
                bpro.d := rhov_p_R4b(plim);
                f := Basic.f3(bpro.d, bpro.T);
                bpro.h := hv_p_R4b(plim);
                bpro.s := f.R * (f.tau * f.ftau - f.f);
                bpro.cv := bpro.R * (-f.tau * f.tau * f.ftautau);
                bpro.pt := bpro.R * bpro.d * f.delta * (f.fdelta - f.tau * f.fdeltatau);
                bpro.pd := bpro.R * bpro.T * f.delta * (2.0 * f.fdelta + f.delta * f.fdeltadelta);
              end if;
            end dewcurve_p;

            function hvl_p
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input Common.IF97PhaseBoundaryProperties bpro "Property record";
              output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
            algorithm
              h := bpro.h;
              annotation(derivative(noDerivative = bpro) = hvl_p_der, Inline = false, LateInline = true);
            end hvl_p;

            function hl_p  "Liquid specific enthalpy on the boundary between regions 4 and 3 or 1"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
            algorithm
              h := hvl_p(p, boilingcurve_p(p));
              annotation(Inline = true);
            end hl_p;

            function hv_p  "Vapour specific enthalpy on the boundary between regions 4 and 3 or 2"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
            algorithm
              h := hvl_p(p, dewcurve_p(p));
              annotation(Inline = true);
            end hv_p;

            function hvl_p_der  "Derivative function for the specific enthalpy along the phase boundary"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input Common.IF97PhaseBoundaryProperties bpro "Property record";
              input Real p_der "Derivative of pressure";
              output Real h_der "Time derivative of specific enthalpy along the phase boundary";
            algorithm
              if bpro.region3boundary then
                h_der := ((bpro.d * bpro.pd - bpro.T * bpro.pt) * p_der + (bpro.T * bpro.pt * bpro.pt + bpro.d * bpro.d * bpro.pd * bpro.cv) / bpro.dpT * p_der) / (bpro.pd * bpro.d * bpro.d);
              else
                h_der := (1 / bpro.d - bpro.T * bpro.vt) * p_der + bpro.cp / bpro.dpT * p_der;
              end if;
              annotation(Inline = true);
            end hvl_p_der;

            function rhovl_p
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input Common.IF97PhaseBoundaryProperties bpro "Property record";
              output .Modelica.SIunits.Density rho "Density";
            algorithm
              rho := bpro.d;
              annotation(derivative(noDerivative = bpro) = rhovl_p_der, Inline = false, LateInline = true);
            end rhovl_p;

            function rhol_p  "Density of saturated water"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Saturation pressure";
              output .Modelica.SIunits.Density rho "Density of steam at the condensation point";
            algorithm
              rho := rhovl_p(p, boilingcurve_p(p));
              annotation(Inline = true);
            end rhol_p;

            function rhov_p  "Density of saturated vapour"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Saturation pressure";
              output .Modelica.SIunits.Density rho "Density of steam at the condensation point";
            algorithm
              rho := rhovl_p(p, dewcurve_p(p));
              annotation(Inline = true);
            end rhov_p;

            function rhovl_p_der
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Saturation pressure";
              input Common.IF97PhaseBoundaryProperties bpro "Property record";
              input Real p_der "Derivative of pressure";
              output Real d_der "Time derivative of density along the phase boundary";
            algorithm
              d_der := if bpro.region3boundary then (p_der - bpro.pt * p_der / bpro.dpT) / bpro.pd else -bpro.d * bpro.d * (bpro.vp + bpro.vt / bpro.dpT) * p_der;
              annotation(Inline = true);
            end rhovl_p_der;

            function sl_p  "Liquid specific entropy on the boundary between regions 4 and 3 or 1"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.SpecificEntropy s "Specific entropy";
            protected
              .Modelica.SIunits.Temperature Tsat "Saturation temperature";
              .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
            algorithm
              if p < data.PLIMIT4A then
                Tsat := Basic.tsat(p);
                (h, s) := Isentropic.handsofpT1(p, Tsat);
              elseif p < data.PCRIT then
                s := sl_p_R4b(p);
              else
                s := data.SCRIT;
              end if;
            end sl_p;

            function sv_p  "Vapour specific entropy on the boundary between regions 4 and 3 or 2"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.SpecificEntropy s "Specific entropy";
            protected
              .Modelica.SIunits.Temperature Tsat "Saturation temperature";
              .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
            algorithm
              if p < data.PLIMIT4A then
                Tsat := Basic.tsat(p);
                (h, s) := Isentropic.handsofpT2(p, Tsat);
              elseif p < data.PCRIT then
                s := sv_p_R4b(p);
              else
                s := data.SCRIT;
              end if;
            end sv_p;

            function rhol_T  "Density of saturated water"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Temperature T "Temperature";
              output .Modelica.SIunits.Density d "Density of water at the boiling point";
            protected
              .Modelica.SIunits.Pressure p "Saturation pressure";
            algorithm
              p := Basic.psat(T);
              if T < data.TLIMIT1 then
                d := d1n(p, T);
              elseif T < data.TCRIT then
                d := rhol_p_R4b(p);
              else
                d := data.DCRIT;
              end if;
            end rhol_T;

            function rhov_T  "Density of saturated vapour"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Temperature T "Temperature";
              output .Modelica.SIunits.Density d "Density of steam at the condensation point";
            protected
              .Modelica.SIunits.Pressure p "Saturation pressure";
            algorithm
              p := Basic.psat(T);
              if T < data.TLIMIT1 then
                d := d2n(p, T);
              elseif T < data.TCRIT then
                d := rhov_p_R4b(p);
              else
                d := data.DCRIT;
              end if;
            end rhov_T;

            function region_ph  "Return the current region (valid values: 1,2,3,4,5) in IF97 for given pressure and specific enthalpy"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
              input Integer phase = 0 "Phase: 2 for two-phase, 1 for one phase, 0 if not known";
              input Integer mode = 0 "Mode: 0 means check, otherwise assume region=mode";
              output Integer region "Region (valid values: 1,2,3,4,5) in IF97";
            protected
              Boolean hsubcrit;
              .Modelica.SIunits.Temperature Ttest;
              .Modelica.SIunits.SpecificEnthalpy hl "Bubble enthalpy";
              .Modelica.SIunits.SpecificEnthalpy hv "Dew enthalpy";
            algorithm
              if mode <> 0 then
                region := mode;
              else
                hl := hl_p(p);
                hv := hv_p(p);
                if phase == 2 then
                  region := 4;
                else
                  if p < triple.ptriple or p > data.PLIMIT1 or h < hlowerofp1(p) or p < 10000000.0 and h > hupperofp5(p) or p >= 10000000.0 and h > hupperofp2(p) then
                    region := -1;
                  else
                    hsubcrit := h < data.HCRIT;
                    if p < data.PLIMIT4A then
                      if hsubcrit then
                        if phase == 1 then
                          region := 1;
                        else
                          if h < Isentropic.hofpT1(p, Basic.tsat(p)) then
                            region := 1;
                          else
                            region := 4;
                          end if;
                        end if;
                      else
                        if h > hlowerofp5(p) then
                          if p < data.PLIMIT5 and h < hupperofp5(p) then
                            region := 5;
                          else
                            region := -2;
                          end if;
                        else
                          if phase == 1 then
                            region := 2;
                          else
                            if h > Isentropic.hofpT2(p, Basic.tsat(p)) then
                              region := 2;
                            else
                              region := 4;
                            end if;
                          end if;
                        end if;
                      end if;
                    else
                      if hsubcrit then
                        if h < hupperofp1(p) then
                          region := 1;
                        else
                          if h < hl or p > data.PCRIT then
                            region := 3;
                          else
                            region := 4;
                          end if;
                        end if;
                      else
                        if h > hlowerofp2(p) then
                          region := 2;
                        else
                          if h > hv or p > data.PCRIT then
                            region := 3;
                          else
                            region := 4;
                          end if;
                        end if;
                      end if;
                    end if;
                  end if;
                end if;
              end if;
            end region_ph;

            function region_ps  "Return the current region (valid values: 1,2,3,4,5) in IF97 for given pressure and specific entropy"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.SpecificEntropy s "Specific entropy";
              input Integer phase = 0 "Phase: 2 for two-phase, 1 for one phase, 0 if unknown";
              input Integer mode = 0 "Mode: 0 means check, otherwise assume region=mode";
              output Integer region "Region (valid values: 1,2,3,4,5) in IF97";
            protected
              Boolean ssubcrit;
              .Modelica.SIunits.Temperature Ttest;
              .Modelica.SIunits.SpecificEntropy sl "Bubble entropy";
              .Modelica.SIunits.SpecificEntropy sv "Dew entropy";
            algorithm
              if mode <> 0 then
                region := mode;
              else
                sl := sl_p(p);
                sv := sv_p(p);
                if phase == 2 or phase == 0 and s > sl and s < sv and p < data.PCRIT then
                  region := 4;
                else
                  region := 0;
                  if p < triple.ptriple then
                    region := -2;
                  else
                  end if;
                  if p > data.PLIMIT1 then
                    region := -3;
                  else
                  end if;
                  if p < 10000000.0 and s > supperofp5(p) then
                    region := -5;
                  else
                  end if;
                  if p >= 10000000.0 and s > supperofp2(p) then
                    region := -6;
                  else
                  end if;
                  if region < 0 then
                    assert(false, "Region computation from p and s failed: function called outside the legal region");
                  else
                    ssubcrit := s < data.SCRIT;
                    if p < data.PLIMIT4A then
                      if ssubcrit then
                        region := 1;
                      else
                        if s > slowerofp5(p) then
                          if p < data.PLIMIT5 and s < supperofp5(p) then
                            region := 5;
                          else
                            region := -1;
                          end if;
                        else
                          region := 2;
                        end if;
                      end if;
                    else
                      if ssubcrit then
                        if s < supperofp1(p) then
                          region := 1;
                        else
                          if s < sl or p > data.PCRIT then
                            region := 3;
                          else
                            region := 4;
                          end if;
                        end if;
                      else
                        if s > slowerofp2(p) then
                          region := 2;
                        else
                          if s > sv or p > data.PCRIT then
                            region := 3;
                          else
                            region := 4;
                          end if;
                        end if;
                      end if;
                    end if;
                  end if;
                end if;
              end if;
            end region_ps;

            function region_pT  "Return the current region (valid values: 1,2,3,5) in IF97, given pressure and temperature"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.Temperature T "Temperature (K)";
              input Integer mode = 0 "Mode: 0 means check, otherwise assume region=mode";
              output Integer region "Region (valid values: 1,2,3,5) in IF97, region 4 is impossible!";
            algorithm
              if mode <> 0 then
                region := mode;
              else
                if p < data.PLIMIT4A then
                  if T > data.TLIMIT2 then
                    region := 5;
                  elseif T > Basic.tsat(p) then
                    region := 2;
                  else
                    region := 1;
                  end if;
                else
                  if T < data.TLIMIT1 then
                    region := 1;
                  elseif T < boundary23ofp(p) then
                    region := 3;
                  else
                    region := 2;
                  end if;
                end if;
              end if;
            end region_pT;

            function region_dT  "Return the current region (valid values: 1,2,3,4,5) in IF97, given density and temperature"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Density d "Density";
              input .Modelica.SIunits.Temperature T "Temperature (K)";
              input Integer phase = 0 "Phase: 2 for two-phase, 1 for one phase, 0 if not known";
              input Integer mode = 0 "Mode: 0 means check, otherwise assume region=mode";
              output Integer region "(valid values: 1,2,3,4,5) in IF97";
            protected
              Boolean Tovercrit "Flag if overcritical temperature";
              .Modelica.SIunits.Pressure p23 "Pressure needed to know if region 2 or 3";
            algorithm
              Tovercrit := T > data.TCRIT;
              if mode <> 0 then
                region := mode;
              else
                p23 := boundary23ofT(T);
                if T > data.TLIMIT2 then
                  if d < 20.5655874106483 then
                    region := 5;
                  else
                    assert(false, "Out of valid region for IF97, pressure above region 5!");
                  end if;
                elseif Tovercrit then
                  if d > d2n(p23, T) and T > data.TLIMIT1 then
                    region := 3;
                  elseif T < data.TLIMIT1 then
                    region := 1;
                  else
                    region := 2;
                  end if;
                elseif d > rhol_T(T) then
                  if T < data.TLIMIT1 then
                    region := 1;
                  else
                    region := 3;
                  end if;
                elseif d < rhov_T(T) then
                  if d > d2n(p23, T) and T > data.TLIMIT1 then
                    region := 3;
                  else
                    region := 2;
                  end if;
                else
                  region := 4;
                end if;
              end if;
            end region_dT;

            function hvl_dp  "Derivative function for the specific enthalpy along the phase boundary"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input Common.IF97PhaseBoundaryProperties bpro "Property record";
              output Real dh_dp "Derivative of specific enthalpy along the phase boundary";
            algorithm
              if bpro.region3boundary then
                dh_dp := (bpro.d * bpro.pd - bpro.T * bpro.pt + (bpro.T * bpro.pt * bpro.pt + bpro.d * bpro.d * bpro.pd * bpro.cv) / bpro.dpT) / (bpro.pd * bpro.d * bpro.d);
              else
                dh_dp := 1 / bpro.d - bpro.T * bpro.vt + bpro.cp / bpro.dpT;
              end if;
            end hvl_dp;

            function dhl_dp  "Derivative of liquid specific enthalpy on the boundary between regions 4 and 3 or 1 w.r.t. pressure"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.DerEnthalpyByPressure dh_dp "Specific enthalpy derivative w.r.t. pressure";
            algorithm
              dh_dp := hvl_dp(p, boilingcurve_p(p));
              annotation(Inline = true);
            end dhl_dp;

            function dhv_dp  "Derivative of vapour specific enthalpy on the boundary between regions 4 and 3 or 1 w.r.t. pressure"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.DerEnthalpyByPressure dh_dp "Specific enthalpy derivative w.r.t. pressure";
            algorithm
              dh_dp := hvl_dp(p, dewcurve_p(p));
              annotation(Inline = true);
            end dhv_dp;

            function drhovl_dp
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Saturation pressure";
              input Common.IF97PhaseBoundaryProperties bpro "Property record";
              output Real dd_dp(unit = "kg/(m3.Pa)") "Derivative of density along the phase boundary";
            algorithm
              dd_dp := if bpro.region3boundary then (1.0 - bpro.pt / bpro.dpT) / bpro.pd else -bpro.d * bpro.d * (bpro.vp + bpro.vt / bpro.dpT);
              annotation(Inline = true);
            end drhovl_dp;

            function drhol_dp  "Derivative of density of saturated water w.r.t. pressure"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Saturation pressure";
              output .Modelica.SIunits.DerDensityByPressure dd_dp "Derivative of density of water at the boiling point";
            algorithm
              dd_dp := drhovl_dp(p, boilingcurve_p(p));
              annotation(Inline = true);
            end drhol_dp;

            function drhov_dp  "Derivative of density of saturated steam w.r.t. pressure"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Saturation pressure";
              output .Modelica.SIunits.DerDensityByPressure dd_dp "Derivative of density of water at the boiling point";
            algorithm
              dd_dp := drhovl_dp(p, dewcurve_p(p));
              annotation(Inline = true);
            end drhov_dp;
            annotation(Documentation(info = "<HTML><h4>Package description</h4>
              <p>Package <b>Regions</b> contains a large number of auxiliary functions which are needed to compute the current region
              of the IAPWS/IF97 for a given pair of input variables as quickly as possible. The focus of this implementation was on
              computational efficiency, not on compact code. Many of the function values calculated in these functions could be obtained
              using the fundamental functions of IAPWS/IF97, but with considerable overhead. If the region of IAPWS/IF97 is known in advance,
              the input variable mode can be set to the region, then the somewhat costly region checks are omitted.
              The checking for the phase has to be done outside the region functions because many properties are not
              differentiable at the region boundary. If the input phase is 2, the output region will be set to 4 immediately.</p>
              <h4>Package contents</h4>
              <p> The main 4 functions in this package are the functions returning the appropriate region for two input variables.</p>
              <ul>
              <li>Function <b>region_ph</b> compute the region of IAPWS/IF97 for input pair pressure and specific enthalpy.</li>
              <li>Function <b>region_ps</b> compute the region of IAPWS/IF97 for input pair pressure and specific entropy</li>
              <li>Function <b>region_dT</b> compute the region of IAPWS/IF97 for input pair density and temperature.</li>
              <li>Function <b>region_pT</b> compute the region of IAPWS/IF97 for input pair pressure and temperature (only in phase region).</li>
              </ul>
              <p>In addition, functions of the boiling and condensation curves compute the specific enthalpy, specific entropy, or density on these
              curves. The functions for the saturation pressure and temperature are included in the package <b>Basic</b> because they are part of
              the original <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/IF97.pdf\">IAPWS/IF97 standards document</a>. These functions are also aliased to
              be used directly from package <b>Water</b>.
             </p>
              <ul>
              <li>Function <b>hl_p</b> computes the liquid specific enthalpy as a function of pressure. For overcritical pressures,
              the critical specific enthalpy is returned. An approximation is used for temperatures > 623.15 K.</li>
              <li>Function <b>hv_p</b> computes the vapour specific enthalpy as a function of pressure. For overcritical pressures,
              the critical specific enthalpy is returned. An approximation is used for temperatures > 623.15 K.</li>
              <li>Function <b>sl_p</b> computes the liquid specific entropy as a function of pressure. For overcritical pressures,
              the critical  specific entropy is returned. An approximation is used for temperatures > 623.15 K.</li>
              <li>Function <b>sv_p</b> computes the vapour  specific entropy as a function of pressure. For overcritical pressures,
              the critical  specific entropy is returned. An approximation is used for temperatures > 623.15 K.</li>
              <li>Function <b>rhol_T</b> computes the liquid density as a function of temperature. For overcritical temperatures,
              the critical density is returned. An approximation is used for temperatures > 623.15 K.</li>
              <li>Function <b>rhol_T</b> computes the vapour density as a function of temperature. For overcritical temperatures,
              the critical density is returned. An approximation is used for temperatures > 623.15 K.</li>
              </ul>
              <p>All other functions are auxiliary functions called from the region functions to check a specific boundary.</p>
              <ul>
              <li>Function <b>boundary23ofT</b> computes the boundary pressure between regions 2 and 3 (input temperature)</li>
              <li>Function <b>boundary23ofp</b> computes the boundary temperature between regions 2 and 3 (input pressure)</li>
              <li>Function <b>hlowerofp5</b> computes the lower specific enthalpy limit of region 5 (input p, T=1073.15 K)</li>
              <li>Function <b>hupperofp5</b> computes the upper specific enthalpy limit of region 5 (input p, T=2273.15 K)</li>
              <li>Function <b>slowerofp5</b> computes the lower specific entropy limit of region 5 (input p, T=1073.15 K)</li>
              <li>Function <b>supperofp5</b> computes the upper specific entropy limit of region 5 (input p, T=2273.15 K)</li>
              <li>Function <b>hlowerofp1</b> computes the lower specific enthalpy limit of region 1 (input p, T=273.15 K)</li>
              <li>Function <b>hupperofp1</b> computes the upper specific enthalpy limit of region 1 (input p, T=623.15 K)</li>
              <li>Function <b>slowerofp1</b> computes the lower specific entropy limit of region 1 (input p, T=273.15 K)</li>
              <li>Function <b>supperofp1</b> computes the upper specific entropy limit of region 1 (input p, T=623.15 K)</li>
              <li>Function <b>hlowerofp2</b> computes the lower specific enthalpy limit of region 2 (input p, T=623.15 K)</li>
              <li>Function <b>hupperofp2</b> computes the upper specific enthalpy limit of region 2 (input p, T=1073.15 K)</li>
              <li>Function <b>slowerofp2</b> computes the lower specific entropy limit of region 2 (input p, T=623.15 K)</li>
              <li>Function <b>supperofp2</b> computes the upper specific entropy limit of region 2 (input p, T=1073.15 K)</li>
              <li>Function <b>d1n</b> computes the density in region 1 as function of pressure and temperature</li>
              <li>Function <b>d2n</b> computes the density in region 2 as function of pressure and temperature</li>
              <li>Function <b>dhot1ofp</b> computes the hot density limit of region 1 (input p, T=623.15 K)</li>
              <li>Function <b>dupper1ofT</b>computes the high pressure density limit of region 1 (input T, p=100MPa)</li>
              <li>Function <b>hl_p_R4b</b> computes a high accuracy approximation to the liquid enthalpy for temperatures > 623.15 K (input p)</li>
              <li>Function <b>hv_p_R4b</b> computes a high accuracy approximation to the vapour enthalpy for temperatures > 623.15 K (input p)</li>
              <li>Function <b>sl_p_R4b</b> computes a high accuracy approximation to the liquid entropy for temperatures > 623.15 K (input p)</li>
              <li>Function <b>sv_p_R4b</b> computes a high accuracy approximation to the vapour entropy for temperatures > 623.15 K (input p)</li>
              <li>Function <b>rhol_p_R4b</b> computes a high accuracy approximation to the liquid density for temperatures > 623.15 K (input p)</li>
              <li>Function <b>rhov_p_R4b</b> computes a high accuracy approximation to the vapour density for temperatures > 623.15 K (input p)</li>
              </ul>

             <h4>Version Info and Revision history</h4>
             <ul>
             <li>First implemented: <i>July, 2000</i>
                    by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>
                    </li>
             </ul>
             <address>Authors: Hubertus Tummescheit, Jonas Eborn and Falko Jens Wagner<br>
                   Modelon AB<br>
                   Ideon Science Park<br>
                   SE-22370 Lund, Sweden<br>
                   email: hubertus@modelon.se
              </address>
              <ul>
              <li>Initial version: July 2000</li>
              <li>Revised and extended for inclusion in Modelica.Thermal: December 2002</li>
             </ul>
             </html>"));
          end Regions;

          package Basic  "Base functions as described in IAWPS/IF97"
            extends Modelica.Icons.Package;

            function g1  "Gibbs function for region 1: g(p,T)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.Temperature T "Temperature (K)";
              output Modelica.Media.Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
            protected
              Real pi1 "Dimensionless pressure";
              Real tau1 "Dimensionless temperature";
              Real[45] o "Vector of auxiliary variables";
              Real pl "Auxiliary variable";
            algorithm
              pl := min(p, data.PCRIT - 1);
              assert(p > triple.ptriple, "IF97 medium function g1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              assert(p <= 100000000.0, "IF97 medium function g1: the input pressure (= " + String(p) + " Pa) is higher than 100 Mpa");
              assert(T >= 273.15, "IF97 medium function g1: the temperature (= " + String(T) + " K) is lower than 273.15 K!");
              g.p := p;
              g.T := T;
              g.R := data.RH2O;
              g.pi := p / data.PSTAR1;
              g.tau := data.TSTAR1 / T;
              pi1 := 7.1 - g.pi;
              tau1 := -1.222 + g.tau;
              o[1] := tau1 * tau1;
              o[2] := o[1] * o[1];
              o[3] := o[2] * o[2];
              o[4] := o[3] * tau1;
              o[5] := 1 / o[4];
              o[6] := o[1] * o[2];
              o[7] := o[1] * tau1;
              o[8] := 1 / o[7];
              o[9] := o[1] * o[2] * o[3];
              o[10] := 1 / o[2];
              o[11] := o[2] * tau1;
              o[12] := 1 / o[11];
              o[13] := o[2] * o[3];
              o[14] := 1 / o[3];
              o[15] := pi1 * pi1;
              o[16] := o[15] * pi1;
              o[17] := o[15] * o[15];
              o[18] := o[17] * o[17];
              o[19] := o[17] * o[18] * pi1;
              o[20] := o[15] * o[17];
              o[21] := o[3] * o[3];
              o[22] := o[21] * o[21];
              o[23] := o[22] * o[3] * tau1;
              o[24] := 1 / o[23];
              o[25] := o[22] * o[3];
              o[26] := 1 / o[25];
              o[27] := o[1] * o[2] * o[22] * tau1;
              o[28] := 1 / o[27];
              o[29] := o[1] * o[2] * o[22];
              o[30] := 1 / o[29];
              o[31] := o[1] * o[2] * o[21] * o[3] * tau1;
              o[32] := 1 / o[31];
              o[33] := o[2] * o[21] * o[3] * tau1;
              o[34] := 1 / o[33];
              o[35] := o[1] * o[3] * tau1;
              o[36] := 1 / o[35];
              o[37] := o[1] * o[3];
              o[38] := 1 / o[37];
              o[39] := 1 / o[6];
              o[40] := o[1] * o[22] * o[3];
              o[41] := 1 / o[40];
              o[42] := 1 / o[22];
              o[43] := o[1] * o[2] * o[21] * o[3];
              o[44] := 1 / o[43];
              o[45] := 1 / o[13];
              g.g := pi1 * (pi1 * (pi1 * (o[10] * (-0.000031679644845054 + o[2] * (-0.0000028270797985312 - 0.00000000085205128120103 * o[6])) + pi1 * (o[12] * (-0.0000022425281908 + (-0.00000065171222895601 - 0.00000000000014341729937924 * o[13]) * o[7]) + pi1 * (-0.00000040516996860117 * o[14] + o[16] * ((-0.0000000012734301741641 - 0.00000000017424871230634 * o[11]) * o[36] + o[19] * (-0.00000000000000000068762131295531 * o[34] + o[15] * (0.000000000000000000014478307828521 * o[32] + o[20] * (0.000000000000000000000026335781662795 * o[30] + pi1 * (-0.000000000000000000000011947622640071 * o[28] + pi1 * (0.0000000000000000000000018228094581404 * o[26] - 0.000000000000000000000000093537087292458 * o[24] * pi1))))))))) + o[8] * (-0.00047184321073267 + o[7] * (-0.00030001780793026 + (0.000047661393906987 + o[1] * (-0.0000044141845330846 - 0.00000000000000072694996297594 * o[9])) * tau1))) + o[5] * (0.00028319080123804 + o[1] * (-0.00060706301565874 + o[6] * (-0.018990068218419 + tau1 * (-0.032529748770505 + (-0.021841717175414 - 0.00005283835796993 * o[1]) * tau1))))) + (0.14632971213167 + tau1 * (-0.84548187169114 + tau1 * (-3.756360367204 + tau1 * (3.3855169168385 + tau1 * (-0.95791963387872 + tau1 * (0.15772038513228 + (-0.016616417199501 + 0.00081214629983568 * tau1) * tau1)))))) / o[1];
              g.gpi := pi1 * (pi1 * (o[10] * (0.000095038934535162 + o[2] * (0.0000084812393955936 + 0.00000000255615384360309 * o[6])) + pi1 * (o[12] * (0.0000089701127632 + (0.00000260684891582404 + 0.00000000000057366919751696 * o[13]) * o[7]) + pi1 * (0.00000202584984300585 * o[14] + o[16] * ((0.0000000101874413933128 + 0.00000000139398969845072 * o[11]) * o[36] + o[19] * (0.0000000000000000144400475720615 * o[34] + o[15] * (-0.00000000000000000033300108005598 * o[32] + o[20] * (-0.00000000000000000000076373766822106 * o[30] + pi1 * (0.00000000000000000000035842867920213 * o[28] + pi1 * (-0.000000000000000000000056507093202352 * o[26] + 0.00000000000000000000000299318679335866 * o[24] * pi1))))))))) + o[8] * (0.00094368642146534 + o[7] * (0.00060003561586052 + (-0.000095322787813974 + o[1] * (0.0000088283690661692 + 0.00000000000000145389992595188 * o[9])) * tau1))) + o[5] * (-0.00028319080123804 + o[1] * (0.00060706301565874 + o[6] * (0.018990068218419 + tau1 * (0.032529748770505 + (0.021841717175414 + 0.00005283835796993 * o[1]) * tau1))));
              g.gpipi := pi1 * (o[10] * (-0.000190077869070324 + o[2] * (-0.0000169624787911872 - 0.0000000051123076872062 * o[6])) + pi1 * (o[12] * (-0.0000269103382896 + (-0.0000078205467474721 - 0.00000000000172100759255088 * o[13]) * o[7]) + pi1 * (-0.0000081033993720234 * o[14] + o[16] * ((-0.00000007131208975319 - 0.000000009757927889155 * o[11]) * o[36] + o[19] * (-0.00000000000000028880095144123 * o[34] + o[15] * (0.0000000000000000073260237612316 * o[32] + o[20] * (0.0000000000000000000213846547101895 * o[30] + pi1 * (-0.0000000000000000000103944316968618 * o[28] + pi1 * (0.00000000000000000000169521279607057 * o[26] - 0.000000000000000000000092788790594118 * o[24] * pi1))))))))) + o[8] * (-0.00094368642146534 + o[7] * (-0.00060003561586052 + (0.000095322787813974 + o[1] * (-0.0000088283690661692 - 0.00000000000000145389992595188 * o[9])) * tau1));
              g.gtau := pi1 * (o[38] * (-0.00254871721114236 + o[1] * (0.0042494411096112 + (0.018990068218419 + (-0.021841717175414 - 0.00015851507390979 * o[1]) * o[1]) * o[6])) + pi1 * (o[10] * (0.00141552963219801 + o[2] * (0.000047661393906987 + o[1] * (-0.0000132425535992538 - 0.000000000000012358149370591 * o[9]))) + pi1 * (o[12] * (0.000126718579380216 - 0.0000000051123076872062 * o[37]) + pi1 * (o[39] * (0.000011212640954 + (0.00000130342445791202 - 0.0000000000014341729937924 * o[13]) * o[7]) + pi1 * (0.0000032413597488094 * o[5] + o[16] * ((0.0000000140077319158051 + 0.00000000104549227383804 * o[11]) * o[45] + o[19] * (0.000000000000000019941018075704 * o[44] + o[15] * (-0.00000000000000000044882754268415 * o[42] + o[20] * (-0.00000000000000000000100075970318621 * o[28] + pi1 * (0.00000000000000000000046595728296277 * o[26] + pi1 * (-0.000000000000000000000072912378325616 * o[24] + 0.0000000000000000000000038350205789908 * o[41] * pi1))))))))))) + o[8] * (-0.29265942426334 + tau1 * (0.84548187169114 + o[1] * (3.3855169168385 + tau1 * (-1.91583926775744 + tau1 * (0.47316115539684 + (-0.066465668798004 + 0.0040607314991784 * tau1) * tau1)))));
              g.gtautau := pi1 * (o[36] * (0.0254871721114236 + o[1] * (-0.033995528876889 + (-0.037980136436838 - 0.00031703014781958 * o[2]) * o[6])) + pi1 * (o[12] * (-0.005662118528792 + o[6] * (-0.0000264851071985076 - 0.000000000000197730389929456 * o[9])) + pi1 * ((-0.00063359289690108 - 0.0000000255615384360309 * o[37]) * o[39] + pi1 * (pi1 * (-0.0000291722377392842 * o[38] + o[16] * (o[19] * (-0.00000000000000059823054227112 * o[32] + o[15] * (o[20] * (0.000000000000000000039029628424262 * o[26] + pi1 * (-0.0000000000000000000186382913185108 * o[24] + pi1 * (0.00000000000000000000298940751135026 * o[41] - 0.000000000000000000000161070864317613 * pi1 / (o[1] * o[22] * o[3] * tau1)))) + 0.0000000000000000143624813658928 / (o[22] * tau1))) + (-0.000000168092782989661 - 0.0000000073184459168663 * o[11]) / (o[2] * o[3] * tau1))) + (-0.000067275845724 + (-0.0000039102733737361 - 0.0000000000129075569441316 * o[13]) * o[7]) / (o[1] * o[2] * tau1))))) + o[10] * (0.87797827279002 + tau1 * (-1.69096374338228 + o[7] * (-1.91583926775744 + tau1 * (0.94632231079368 + (-0.199397006394012 + 0.0162429259967136 * tau1) * tau1))));
              g.gtaupi := o[38] * (0.00254871721114236 + o[1] * (-0.0042494411096112 + (-0.018990068218419 + (0.021841717175414 + 0.00015851507390979 * o[1]) * o[1]) * o[6])) + pi1 * (o[10] * (-0.00283105926439602 + o[2] * (-0.000095322787813974 + o[1] * (0.0000264851071985076 + 0.000000000000024716298741182 * o[9]))) + pi1 * (o[12] * (-0.00038015573814065 + 0.0000000153369230616185 * o[37]) + pi1 * (o[39] * (-0.000044850563816 + (-0.0000052136978316481 + 0.0000000000057366919751696 * o[13]) * o[7]) + pi1 * (-0.0000162067987440468 * o[5] + o[16] * ((-0.000000112061855326441 - 0.0000000083639381907043 * o[11]) * o[45] + o[19] * (-0.00000000000000041876137958978 * o[44] + o[15] * (0.0000000000000000103230334817355 * o[42] + o[20] * (0.0000000000000000000290220313924001 * o[28] + pi1 * (-0.0000000000000000000139787184888831 * o[26] + pi1 * (0.0000000000000000000022602837280941 * o[24] - 0.000000000000000000000122720658527705 * o[41] * pi1))))))))));
            end g1;

            function g2  "Gibbs function for region 2: g(p,T)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.Temperature T "Temperature (K)";
              output Modelica.Media.Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
            protected
              Real tau2 "Dimensionless temperature";
              Real[55] o "Vector of auxiliary variables";
            algorithm
              g.p := p;
              g.T := T;
              g.R := data.RH2O;
              assert(p > 0.0, "IF97 medium function g2 called with too low pressure\n" + "p = " + String(p) + " Pa <=  0.0 Pa");
              assert(p <= 100000000.0, "IF97 medium function g2: the input pressure (= " + String(p) + " Pa) is higher than 100 Mpa");
              assert(T >= 273.15, "IF97 medium function g2: the temperature (= " + String(T) + " K) is lower than 273.15 K!");
              assert(T <= 1073.15, "IF97 medium function g2: the input temperature (= " + String(T) + " K) is higher than the limit of 1073.15 K");
              g.pi := p / data.PSTAR2;
              g.tau := data.TSTAR2 / T;
              tau2 := -0.5 + g.tau;
              o[1] := tau2 * tau2;
              o[2] := o[1] * tau2;
              o[3] := -0.05032527872793 * o[2];
              o[4] := -0.057581259083432 + o[3];
              o[5] := o[4] * tau2;
              o[6] := -0.045996013696365 + o[5];
              o[7] := o[6] * tau2;
              o[8] := -0.017834862292358 + o[7];
              o[9] := o[8] * tau2;
              o[10] := o[1] * o[1];
              o[11] := o[10] * o[10];
              o[12] := o[11] * o[11];
              o[13] := o[10] * o[11] * o[12] * tau2;
              o[14] := o[1] * o[10] * tau2;
              o[15] := o[10] * o[11] * tau2;
              o[16] := o[1] * o[12] * tau2;
              o[17] := o[1] * o[11] * tau2;
              o[18] := o[1] * o[10] * o[11];
              o[19] := o[10] * o[11] * o[12];
              o[20] := o[1] * o[10];
              o[21] := g.pi * g.pi;
              o[22] := o[21] * o[21];
              o[23] := o[21] * o[22];
              o[24] := o[10] * o[12] * tau2;
              o[25] := o[12] * o[12];
              o[26] := o[11] * o[12] * o[25] * tau2;
              o[27] := o[10] * o[12];
              o[28] := o[1] * o[10] * o[11] * tau2;
              o[29] := o[10] * o[12] * o[25] * tau2;
              o[30] := o[1] * o[10] * o[25] * tau2;
              o[31] := o[1] * o[11] * o[12];
              o[32] := o[1] * o[12];
              o[33] := g.tau * g.tau;
              o[34] := o[33] * o[33];
              o[35] := -0.000053349095828174 * o[13];
              o[36] := -0.087594591301146 + o[35];
              o[37] := o[2] * o[36];
              o[38] := -0.007878555448671 + o[37];
              o[39] := o[1] * o[38];
              o[40] := -0.0003789797503263 + o[39];
              o[41] := o[40] * tau2;
              o[42] := -0.000066065283340406 + o[41];
              o[43] := o[42] * tau2;
              o[44] := 0.0000057870447262208 * tau2;
              o[45] := -0.30195167236758 * o[2];
              o[46] := -0.172743777250296 + o[45];
              o[47] := o[46] * tau2;
              o[48] := -0.09199202739273 + o[47];
              o[49] := o[48] * tau2;
              o[50] := o[1] * o[11];
              o[51] := o[10] * o[11];
              o[52] := o[11] * o[12] * o[25];
              o[53] := o[10] * o[12] * o[25];
              o[54] := o[1] * o[10] * o[25];
              o[55] := o[11] * o[12] * tau2;
              g.g := g.pi * (-0.0017731742473213 + o[9] + g.pi * (tau2 * (-0.000033032641670203 + (-0.00018948987516315 + o[1] * (-0.0039392777243355 + (-0.043797295650573 - 0.000026674547914087 * o[13]) * o[2])) * tau2) + g.pi * (0.000000020481737692309 + (0.00000043870667284435 + o[1] * (-0.00003227767723857 + (-0.0015033924542148 - 0.040668253562649 * o[13]) * o[2])) * tau2 + g.pi * (g.pi * (0.0000022922076337661 * o[14] + g.pi * ((-0.000000000016714766451061 + o[15] * (-0.0021171472321355 - 23.895741934104 * o[16])) * o[2] + g.pi * (-0.000000000000000005905956432427 + o[17] * (-0.0000012621808899101 - 0.038946842435739 * o[18]) + g.pi * (o[11] * (0.000000000011256211360459 - 8.2311340897998 * o[19]) + g.pi * (0.000000019809712802088 * o[15] + g.pi * (o[10] * (0.00000000000000000010406965210174 + (-0.00000000000010234747095929 - 0.0000000010018179379511 * o[10]) * o[20]) + o[23] * (o[13] * (-0.000000000080882908646985 + 0.10693031879409 * o[24]) + o[21] * (-0.33662250574171 * o[26] + o[21] * (o[27] * (0.00000000000000000000000089185845355421 + (0.00000000000030629316876232 - 0.0000042002467698208 * o[15]) * o[28]) + g.pi * (-0.000000000000000000000000059056029685639 * o[24] + g.pi * (0.0000037826947613457 * o[29] + g.pi * (-0.0000000000000012768608934681 * o[30] + o[31] * (0.000000000000000000000000000073087610595061 + o[18] * (0.000000000000000055414715350778 - 0.0000009436970724121 * o[32])) * g.pi)))))))))))) + tau2 * (-0.00000000078847309559367 + (0.000000012790717852285 + 0.00000048225372718507 * tau2) * tau2))))) + (-0.00560879118302 + g.tau * (0.07145273881455 + g.tau * (-0.4071049823928 + g.tau * (1.424081971444 + g.tau * (-4.38395111945 + g.tau * (-9.692768600217 + g.tau * (10.08665568018 + (-0.2840863260772 + 0.02126846353307 * g.tau) * g.tau) + Modelica.Math.log(g.pi))))))) / (o[34] * g.tau);
              g.gpi := (1.0 + g.pi * (-0.0017731742473213 + o[9] + g.pi * (o[43] + g.pi * (0.000000061445213076927 + (0.00000131612001853305 + o[1] * (-0.00009683303171571 + (-0.0045101773626444 - 0.122004760687947 * o[13]) * o[2])) * tau2 + g.pi * (g.pi * (0.0000114610381688305 * o[14] + g.pi * ((-0.000000000100288598706366 + o[15] * (-0.012702883392813 - 143.374451604624 * o[16])) * o[2] + g.pi * (-0.000000000000000041341695026989 + o[17] * (-0.0000088352662293707 - 0.272627897050173 * o[18]) + g.pi * (o[11] * (0.000000000090049690883672 - 65.849072718398 * o[19]) + g.pi * (0.000000178287415218792 * o[15] + g.pi * (o[10] * (0.0000000000000000010406965210174 + (-0.0000000000010234747095929 - 0.000000010018179379511 * o[10]) * o[20]) + o[23] * (o[13] * (-0.00000000129412653835176 + 1.71088510070544 * o[24]) + o[21] * (-6.0592051033508 * o[26] + o[21] * (o[27] * (0.0000000000000000000000178371690710842 + (0.0000000000061258633752464 - 0.000084004935396416 * o[15]) * o[28]) + g.pi * (-0.00000000000000000000000124017662339842 * o[24] + g.pi * (0.000083219284749605 * o[29] + g.pi * (-0.0000000000000293678005497663 * o[30] + o[31] * (0.00000000000000000000000000175410265428146 + o[18] * (0.00000000000000132995316841867 - 0.0000226487297378904 * o[32])) * g.pi)))))))))))) + tau2 * (-0.00000000315389238237468 + (0.00000005116287140914 + 0.00000192901490874028 * tau2) * tau2)))))) / g.pi;
              g.gpipi := (-1.0 + o[21] * (o[43] + g.pi * (0.000000122890426153854 + (0.0000026322400370661 + o[1] * (-0.00019366606343142 + (-0.0090203547252888 - 0.244009521375894 * o[13]) * o[2])) * tau2 + g.pi * (g.pi * (0.000045844152675322 * o[14] + g.pi * ((-0.00000000050144299353183 + o[15] * (-0.063514416964065 - 716.87225802312 * o[16])) * o[2] + g.pi * (-0.000000000000000248050170161934 + o[17] * (-0.000053011597376224 - 1.63576738230104 * o[18]) + g.pi * (o[11] * (0.0000000006303478361857 - 460.94350902879 * o[19]) + g.pi * (0.00000142629932175034 * o[15] + g.pi * (o[10] * (0.0000000000000000093662686891566 + (-0.0000000000092112723863361 - 0.000000090163614415599 * o[10]) * o[20]) + o[23] * (o[13] * (-0.0000000194118980752764 + 25.6632765105816 * o[24]) + o[21] * (-103.006486756963 * o[26] + o[21] * (o[27] * (0.0000000000000000000003389062123506 + (0.000000000116391404129682 - 0.0015960937725319 * o[15]) * o[28]) + g.pi * (-0.0000000000000000000000248035324679684 * o[24] + g.pi * (0.00174760497974171 * o[29] + g.pi * (-0.00000000000064609161209486 * o[30] + o[31] * (0.000000000000000000000000040344361048474 + o[18] * (0.0000000000000305889228736295 - 0.00052092078397148 * o[32])) * g.pi)))))))))))) + tau2 * (-0.000000009461677147124 + (0.00000015348861422742 + o[44]) * tau2))))) / o[21];
              g.gtau := (0.0280439559151 + g.tau * (-0.2858109552582 + g.tau * (1.2213149471784 + g.tau * (-2.848163942888 + g.tau * (4.38395111945 + o[33] * (10.08665568018 + (-0.5681726521544 + 0.06380539059921 * g.tau) * g.tau)))))) / (o[33] * o[34]) + g.pi * (-0.017834862292358 + o[49] + g.pi * (-0.000033032641670203 + (-0.0003789797503263 + o[1] * (-0.015757110897342 + (-0.306581069554011 - 0.00096028372490713 * o[13]) * o[2])) * tau2 + g.pi * (0.00000043870667284435 + o[1] * (-0.00009683303171571 + (-0.0090203547252888 - 1.42338887469272 * o[13]) * o[2]) + g.pi * (-0.00000000078847309559367 + g.pi * (0.0000160454534363627 * o[20] + g.pi * (o[1] * (-0.000000000050144299353183 + o[15] * (-0.033874355714168 - 836.35096769364 * o[16])) + g.pi * ((-0.0000138839897890111 - 0.97367106089347 * o[18]) * o[50] + g.pi * (o[14] * (0.000000000090049690883672 - 296.320827232793 * o[19]) + g.pi * (0.000000257526266427144 * o[51] + g.pi * (o[2] * (0.00000000000000000041627860840696 + (-0.0000000000010234747095929 - 0.0000000140254511313154 * o[10]) * o[20]) + o[23] * (o[19] * (-0.00000000234560435076256 + 5.3465159397045 * o[24]) + o[21] * (-19.1874828272775 * o[52] + o[21] * (o[16] * (0.0000000000000000000000178371690710842 + (0.0000000000107202609066812 - 0.000201611844951398 * o[15]) * o[28]) + g.pi * (-0.00000000000000000000000124017662339842 * o[27] + g.pi * (0.000200482822351322 * o[53] + g.pi * (-0.000000000000049797574845256 * o[54] + (0.00000000000000000000000000190027787547159 + o[18] * (0.00000000000000221658861403112 - 0.000054734430199902 * o[32])) * o[55] * g.pi)))))))))))) + (0.00000002558143570457 + 0.00000144676118155521 * tau2) * tau2))));
              g.gtautau := (-0.1682637354906 + g.tau * (1.429054776291 + g.tau * (-4.8852597887136 + g.tau * (8.544491828664 + g.tau * (-8.7679022389 + o[33] * (-0.5681726521544 + 0.12761078119842 * g.tau) * g.tau))))) / (o[33] * o[34] * g.tau) + g.pi * (-0.09199202739273 + (-0.34548755450059 - 1.5097583618379 * o[2]) * tau2 + g.pi * (-0.0003789797503263 + o[1] * (-0.047271332692026 + (-1.83948641732407 - 0.03360993037175 * o[13]) * o[2]) + g.pi * ((-0.00019366606343142 + (-0.045101773626444 - 48.395221739552 * o[13]) * o[2]) * tau2 + g.pi * (0.00000002558143570457 + 0.00000289352236311042 * tau2 + g.pi * (0.000096272720618176 * o[10] * tau2 + g.pi * ((-0.000000000100288598706366 + o[15] * (-0.50811533571252 - 28435.9329015838 * o[16])) * tau2 + g.pi * (o[11] * (-0.000138839897890111 - 23.3681054614434 * o[18]) * tau2 + g.pi * ((0.0000000006303478361857 - 10371.2289531477 * o[19]) * o[20] + g.pi * (0.00000309031519712573 * o[17] + g.pi * (o[1] * (0.00000000000000000124883582522088 + (-0.0000000000092112723863361 - 0.0000001823308647071 * o[10]) * o[20]) + o[23] * (o[1] * o[11] * o[12] * (-0.000000065676921821352 + 261.979281045521 * o[24]) * tau2 + o[21] * (-1074.49903832754 * o[1] * o[10] * o[12] * o[25] * tau2 + o[21] * ((0.0000000000000000000003389062123506 + (0.00000000036448887082716 - 0.0094757567127157 * o[15]) * o[28]) * o[32] + g.pi * (-0.0000000000000000000000248035324679684 * o[16] + g.pi * (0.0104251067622687 * o[1] * o[12] * o[25] * tau2 + g.pi * (o[11] * o[12] * (0.00000000000000000000000004750694688679 + o[18] * (0.000000000000086446955947214 - 0.0031198625213944 * o[32])) * g.pi - 0.00000000000189230784411972 * o[10] * o[25] * tau2))))))))))))))));
              g.gtaupi := -0.017834862292358 + o[49] + g.pi * (-0.000066065283340406 + (-0.0007579595006526 + o[1] * (-0.031514221794684 + (-0.61316213910802 - 0.00192056744981426 * o[13]) * o[2])) * tau2 + g.pi * (0.00000131612001853305 + o[1] * (-0.00029049909514713 + (-0.0270610641758664 - 4.2701666240781 * o[13]) * o[2]) + g.pi * (-0.00000000315389238237468 + g.pi * (0.000080227267181813 * o[20] + g.pi * (o[1] * (-0.000000000300865796119098 + o[15] * (-0.203246134285008 - 5018.1058061618 * o[16])) + g.pi * ((-0.000097187928523078 - 6.8156974262543 * o[18]) * o[50] + g.pi * (o[14] * (0.00000000072039752706938 - 2370.56661786234 * o[19]) + g.pi * (0.0000023177363978443 * o[51] + g.pi * (o[2] * (0.0000000000000000041627860840696 + (-0.000000000010234747095929 - 0.000000140254511313154 * o[10]) * o[20]) + o[23] * (o[19] * (-0.000000037529669612201 + 85.544255035272 * o[24]) + o[21] * (-345.37469089099 * o[52] + o[21] * (o[16] * (0.00000000000000000000035674338142168 + (0.000000000214405218133624 - 0.004032236899028 * o[15]) * o[28]) + g.pi * (-0.0000000000000000000000260437090913668 * o[27] + g.pi * (0.0044106220917291 * o[53] + g.pi * (-0.00000000000114534422144089 * o[54] + (0.000000000000000000000000045606669011318 + o[18] * (0.000000000000053198126736747 - 0.00131362632479764 * o[32])) * o[55] * g.pi)))))))))))) + (0.00000010232574281828 + o[44]) * tau2)));
            end g2;

            function f3  "Helmholtz function for region 3: f(d,T)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Density d "Density";
              input .Modelica.SIunits.Temperature T "Temperature (K)";
              output Modelica.Media.Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
            protected
              Real[40] o "Vector of auxiliary variables";
            algorithm
              f.T := T;
              f.d := d;
              f.R := data.RH2O;
              f.tau := data.TCRIT / T;
              f.delta := if d == data.DCRIT and T == data.TCRIT then 1 - Modelica.Constants.eps else abs(d / data.DCRIT);
              o[1] := f.tau * f.tau;
              o[2] := o[1] * o[1];
              o[3] := o[2] * f.tau;
              o[4] := o[1] * f.tau;
              o[5] := o[2] * o[2];
              o[6] := o[1] * o[5] * f.tau;
              o[7] := o[5] * f.tau;
              o[8] := -0.64207765181607 * o[1];
              o[9] := 0.88521043984318 + o[8];
              o[10] := o[7] * o[9];
              o[11] := -1.1524407806681 + o[10];
              o[12] := o[11] * o[2];
              o[13] := -1.2654315477714 + o[12];
              o[14] := o[1] * o[13];
              o[15] := o[1] * o[2] * o[5] * f.tau;
              o[16] := o[2] * o[5];
              o[17] := o[1] * o[5];
              o[18] := o[5] * o[5];
              o[19] := o[1] * o[18] * o[2];
              o[20] := o[1] * o[18] * o[2] * f.tau;
              o[21] := o[18] * o[5];
              o[22] := o[1] * o[18] * o[5];
              o[23] := 0.25116816848616 * o[2];
              o[24] := 0.078841073758308 + o[23];
              o[25] := o[15] * o[24];
              o[26] := -6.100523451393 + o[25];
              o[27] := o[26] * f.tau;
              o[28] := 9.7944563083754 + o[27];
              o[29] := o[2] * o[28];
              o[30] := -1.70429417648412 + o[29];
              o[31] := o[1] * o[30];
              o[32] := f.delta * f.delta;
              o[33] := -10.9153200808732 * o[1];
              o[34] := 13.2781565976477 + o[33];
              o[35] := o[34] * o[7];
              o[36] := -6.9146446840086 + o[35];
              o[37] := o[2] * o[36];
              o[38] := -2.5308630955428 + o[37];
              o[39] := o[38] * f.tau;
              o[40] := o[18] * o[5] * f.tau;
              f.f := -15.732845290239 + f.tau * (20.944396974307 + (-7.6867707878716 + o[3] * (2.6185947787954 + o[4] * (-2.808078114862 + o[1] * (1.2053369696517 - 0.0084566812812502 * o[6])))) * f.tau) + f.delta * (o[14] + f.delta * (0.38493460186671 + o[1] * (-0.85214708824206 + o[2] * (4.8972281541877 + (-3.0502617256965 + o[15] * (0.039420536879154 + 0.12558408424308 * o[2])) * f.tau)) + f.delta * (-0.2799932969871 + o[1] * (1.389979956946 + o[1] * (-2.018991502357 + o[16] * (-0.0082147637173963 - 0.47596035734923 * o[17]))) + f.delta * (0.0439840744735 + o[1] * (-0.44476435428739 + o[1] * (0.90572070719733 + 0.70522450087967 * o[19])) + f.delta * (f.delta * (-0.022175400873096 + o[1] * (0.094260751665092 + 0.16436278447961 * o[21]) + f.delta * (-0.013503372241348 * o[1] + f.delta * (-0.014834345352472 * o[22] + f.delta * (o[1] * (0.00057922953628084 + 0.0032308904703711 * o[21]) + f.delta * (0.000080964802996215 - 0.000044923899061815 * f.delta * o[22] - 0.00016557679795037 * f.tau))))) + (0.10770512626332 + o[1] * (-0.32913623258954 - 0.50871062041158 * o[20])) * f.tau))))) + 1.0658070028513 * Modelica.Math.log(f.delta);
              f.fdelta := (1.0658070028513 + f.delta * (o[14] + f.delta * (0.76986920373342 + o[31] + f.delta * (-0.8399798909613 + o[1] * (4.169939870838 + o[1] * (-6.056974507071 + o[16] * (-0.0246442911521889 - 1.42788107204769 * o[17]))) + f.delta * (0.175936297894 + o[1] * (-1.77905741714956 + o[1] * (3.6228828287893 + 2.82089800351868 * o[19])) + f.delta * (f.delta * (-0.133052405238576 + o[1] * (0.56556450999055 + 0.98617670687766 * o[21]) + f.delta * (-0.094523605689436 * o[1] + f.delta * (-0.118674762819776 * o[22] + f.delta * (o[1] * (0.0052130658265276 + 0.0290780142333399 * o[21]) + f.delta * (0.00080964802996215 - 0.00049416288967996 * f.delta * o[22] - 0.0016557679795037 * f.tau))))) + (0.5385256313166 + o[1] * (-1.6456811629477 - 2.5435531020579 * o[20])) * f.tau)))))) / f.delta;
              f.fdeltadelta := (-1.0658070028513 + o[32] * (0.76986920373342 + o[31] + f.delta * (-1.6799597819226 + o[1] * (8.339879741676 + o[1] * (-12.113949014142 + o[16] * (-0.049288582304378 - 2.85576214409538 * o[17]))) + f.delta * (0.527808893682 + o[1] * (-5.3371722514487 + o[1] * (10.868648486368 + 8.462694010556 * o[19])) + f.delta * (f.delta * (-0.66526202619288 + o[1] * (2.82782254995276 + 4.9308835343883 * o[21]) + f.delta * (-0.56714163413662 * o[1] + f.delta * (-0.83072333973843 * o[22] + f.delta * (o[1] * (0.04170452661222 + 0.232624113866719 * o[21]) + f.delta * (0.0072868322696594 - 0.0049416288967996 * f.delta * o[22] - 0.0149019118155333 * f.tau))))) + (2.1541025252664 + o[1] * (-6.5827246517908 - 10.1742124082316 * o[20])) * f.tau))))) / o[32];
              f.ftau := 20.944396974307 + (-15.3735415757432 + o[3] * (18.3301634515678 + o[4] * (-28.08078114862 + o[1] * (14.4640436358204 - 0.194503669468755 * o[6])))) * f.tau + f.delta * (o[39] + f.delta * (f.tau * (-1.70429417648412 + o[2] * (29.3833689251262 + (-21.3518320798755 + o[15] * (0.86725181134139 + 3.2651861903201 * o[2])) * f.tau)) + f.delta * ((2.779959913892 + o[1] * (-8.075966009428 + o[16] * (-0.131436219478341 - 12.37496929108 * o[17]))) * f.tau + f.delta * ((-0.88952870857478 + o[1] * (3.6228828287893 + 18.3358370228714 * o[19])) * f.tau + f.delta * (0.10770512626332 + o[1] * (-0.98740869776862 - 13.2264761307011 * o[20]) + f.delta * ((0.188521503330184 + 4.2734323964699 * o[21]) * f.tau + f.delta * (-0.027006744482696 * f.tau + f.delta * (-0.38569297916427 * o[40] + f.delta * (f.delta * (-0.00016557679795037 - 0.00116802137560719 * f.delta * o[40]) + (0.00115845907256168 + 0.084003152229649 * o[21]) * f.tau)))))))));
              f.ftautau := -15.3735415757432 + o[3] * (109.980980709407 + o[4] * (-252.72703033758 + o[1] * (159.104479994024 - 4.2790807283126 * o[6]))) + f.delta * (-2.5308630955428 + o[2] * (-34.573223420043 + (185.894192367068 - 174.645121293971 * o[1]) * o[7]) + f.delta * (-1.70429417648412 + o[2] * (146.916844625631 + (-128.110992479253 + o[15] * (18.2122880381691 + 81.629654758002 * o[2])) * f.tau) + f.delta * (2.779959913892 + o[1] * (-24.227898028284 + o[16] * (-1.97154329217511 - 309.374232277 * o[17])) + f.delta * (-0.88952870857478 + o[1] * (10.868648486368 + 458.39592557179 * o[19]) + f.delta * (f.delta * (0.188521503330184 + 106.835809911747 * o[21] + f.delta * (-0.027006744482696 + f.delta * (-9.6423244791068 * o[21] + f.delta * (0.00115845907256168 + 2.10007880574121 * o[21] - 0.0292005343901797 * o[21] * o[32])))) + (-1.97481739553724 - 330.66190326753 * o[20]) * f.tau)))));
              f.fdeltatau := o[39] + f.delta * (f.tau * (-3.4085883529682 + o[2] * (58.766737850252 + (-42.703664159751 + o[15] * (1.73450362268278 + 6.5303723806402 * o[2])) * f.tau)) + f.delta * ((8.339879741676 + o[1] * (-24.227898028284 + o[16] * (-0.39430865843502 - 37.12490787324 * o[17]))) * f.tau + f.delta * ((-3.5581148342991 + o[1] * (14.4915313151573 + 73.343348091486 * o[19])) * f.tau + f.delta * (0.5385256313166 + o[1] * (-4.9370434888431 - 66.132380653505 * o[20]) + f.delta * ((1.1311290199811 + 25.6405943788192 * o[21]) * f.tau + f.delta * (-0.189047211378872 * f.tau + f.delta * (-3.08554383331418 * o[40] + f.delta * (f.delta * (-0.0016557679795037 - 0.0128482351316791 * f.delta * o[40]) + (0.0104261316530551 + 0.75602837006684 * o[21]) * f.tau))))))));
            end f3;

            function g5  "Base function for region 5: g(p,T)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.Temperature T "Temperature (K)";
              output Modelica.Media.Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
            protected
              Real[11] o "Vector of auxiliary variables";
            algorithm
              assert(p > 0.0, "IF97 medium function g5 called with too low pressure\n" + "p = " + String(p) + " Pa <=  0.0 Pa");
              assert(p <= data.PLIMIT5, "IF97 medium function g5: input pressure (= " + String(p) + " Pa) is higher than 10 Mpa in region 5");
              assert(T <= 2273.15, "IF97 medium function g5: input temperature (= " + String(T) + " K) is higher than limit of 2273.15K in region 5");
              g.p := p;
              g.T := T;
              g.R := data.RH2O;
              g.pi := p / data.PSTAR5;
              g.tau := data.TSTAR5 / T;
              o[1] := g.tau * g.tau;
              o[2] := -0.004594282089991 * o[1];
              o[3] := 0.0021774678714571 + o[2];
              o[4] := o[3] * g.tau;
              o[5] := o[1] * g.tau;
              o[6] := o[1] * o[1];
              o[7] := o[6] * o[6];
              o[8] := o[7] * g.tau;
              o[9] := -0.0000079449656719138 * o[8];
              o[10] := g.pi * g.pi;
              o[11] := -0.013782846269973 * o[1];
              g.g := g.pi * (-0.00012563183589592 + o[4] + g.pi * (-0.0000039724828359569 * o[8] + 0.00000012919228289784 * o[5] * g.pi)) + (-0.024805148933466 + g.tau * (0.36901534980333 + g.tau * (-3.1161318213925 + g.tau * (-13.179983674201 + (6.8540841634434 - 0.32961626538917 * g.tau) * g.tau + Modelica.Math.log(g.pi))))) / o[5];
              g.gpi := (1.0 + g.pi * (-0.00012563183589592 + o[4] + g.pi * (o[9] + 0.00000038757684869352 * o[5] * g.pi))) / g.pi;
              g.gpipi := (-1.0 + o[10] * (o[9] + 0.00000077515369738704 * o[5] * g.pi)) / o[10];
              g.gtau := g.pi * (0.0021774678714571 + o[11] + g.pi * (-0.000035752345523612 * o[7] + 0.00000038757684869352 * o[1] * g.pi)) + (0.074415446800398 + g.tau * (-0.73803069960666 + (3.1161318213925 + o[1] * (6.8540841634434 - 0.65923253077834 * g.tau)) * g.tau)) / o[6];
              g.gtautau := (-0.297661787201592 + g.tau * (2.21409209881998 + (-6.232263642785 - 0.65923253077834 * o[5]) * g.tau)) / (o[6] * g.tau) + g.pi * (-0.027565692539946 * g.tau + g.pi * (-0.000286018764188897 * o[1] * o[6] * g.tau + 0.00000077515369738704 * g.pi * g.tau));
              g.gtaupi := 0.0021774678714571 + o[11] + g.pi * (-0.000071504691047224 * o[7] + 0.00000116273054608056 * o[1] * g.pi);
            end g5;

            function tph1  "Inverse function for region 1: T(p,h)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
              output .Modelica.SIunits.Temperature T "Temperature (K)";
            protected
              Real pi "Dimensionless pressure";
              Real eta1 "Dimensionless specific enthalpy";
              Real[3] o "Vector of auxiliary variables";
            algorithm
              assert(p > triple.ptriple, "IF97 medium function tph1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              pi := p / data.PSTAR2;
              eta1 := h / data.HSTAR1 + 1.0;
              o[1] := eta1 * eta1;
              o[2] := o[1] * o[1];
              o[3] := o[2] * o[2];
              T := -238.72489924521 - 13.391744872602 * pi + eta1 * (404.21188637945 + 43.211039183559 * pi + eta1 * (113.49746881718 - 54.010067170506 * pi + eta1 * (30.535892203916 * pi + eta1 * (-6.5964749423638 * pi + o[1] * (-5.8457616048039 + o[2] * (pi * (0.0093965400878363 + (-0.000025858641282073 + 0.000000066456186191635 * pi) * pi) + o[2] * o[3] * (-0.0001528548241314 + o[1] * o[3] * (-0.0000010866707695377 + pi * (0.0000001157364750534 + pi * (-0.0000000040644363084799 + pi * (0.000000000080670734103027 + pi * (-0.00000000000093477771213947 + (0.0000000000000058265442020601 - 0.000000000000000015020185953503 * pi) * pi))))))))))));
            end tph1;

            function tps1  "Inverse function for region 1: T(p,s)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.SpecificEntropy s "Specific entropy";
              output .Modelica.SIunits.Temperature T "Temperature (K)";
            protected
              constant .Modelica.SIunits.Pressure pstar = 1000000.0;
              constant .Modelica.SIunits.SpecificEntropy sstar = 1000.0;
              Real pi "Dimensionless pressure";
              Real sigma1 "Dimensionless specific entropy";
              Real[6] o "Vector of auxiliary variables";
            algorithm
              pi := p / pstar;
              assert(p > triple.ptriple, "IF97 medium function tps1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              sigma1 := s / sstar + 2.0;
              o[1] := sigma1 * sigma1;
              o[2] := o[1] * o[1];
              o[3] := o[2] * o[2];
              o[4] := o[3] * o[3];
              o[5] := o[4] * o[4];
              o[6] := o[1] * o[2] * o[4];
              T := 174.78268058307 + sigma1 * (34.806930892873 + sigma1 * (6.5292584978455 + (0.33039981775489 + o[3] * (-0.00000019281382923196 - 0.000000000000000000000024909197244573 * o[2] * o[4])) * sigma1)) + pi * (-0.26107636489332 + pi * (0.00056608900654837 + pi * (o[1] * o[3] * (0.00000000000026400441360689 + 0.000000000000000000000000000078124600459723 * o[6]) - 3.0732199903668e-31 * o[5] * pi) + sigma1 * (-0.00032635483139717 + sigma1 * (0.000044778286690632 + o[1] * o[2] * (-0.00000000051322156908507 - 0.000000000000000000000000042522657042207 * o[6]) * sigma1))) + sigma1 * (0.22592965981586 + sigma1 * (-0.064256463395226 + sigma1 * (0.0078876289270526 + o[3] * sigma1 * (0.00000000035672110607366 + 0.0000000000000000000000017332496994895 * o[1] * o[4] * sigma1)))));
            end tps1;

            function tph2  "Reverse function for region 2: T(p,h)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
              output .Modelica.SIunits.Temperature T "Temperature (K)";
            protected
              Real pi "Dimensionless pressure";
              Real pi2b "Dimensionless pressure";
              Real pi2c "Dimensionless pressure";
              Real eta "Dimensionless specific enthalpy";
              Real etabc "Dimensionless specific enthalpy";
              Real eta2a "Dimensionless specific enthalpy";
              Real eta2b "Dimensionless specific enthalpy";
              Real eta2c "Dimensionless specific enthalpy";
              Real[8] o "Vector of auxiliary variables";
            algorithm
              pi := p * data.IPSTAR;
              eta := h * data.IHSTAR;
              etabc := h * 0.001;
              if pi < 4.0 then
                eta2a := eta - 2.1;
                o[1] := eta2a * eta2a;
                o[2] := o[1] * o[1];
                o[3] := pi * pi;
                o[4] := o[3] * o[3];
                o[5] := o[3] * pi;
                T := 1089.8952318288 + (1.844574935579 - 0.0061707422868339 * pi) * pi + eta2a * (849.51654495535 - 4.1792700549624 * pi + eta2a * (-107.81748091826 + (6.2478196935812 - 0.31078046629583 * pi) * pi + eta2a * (33.153654801263 - 17.344563108114 * pi + o[2] * (-7.4232016790248 + pi * (-200.58176862096 + 11.670873077107 * pi) + o[1] * (271.96065473796 * pi + o[1] * (-455.11318285818 * pi + eta2a * (1.3865724283226 * o[4] + o[1] * o[2] * (3091.9688604755 * pi + o[1] * (11.765048724356 + o[2] * (-13551.334240775 * o[5] + o[2] * (-62.459855192507 * o[3] * o[4] * pi + o[2] * (o[4] * (235988.32556514 + 7399.9835474766 * pi) + o[1] * (19127.72923966 * o[3] * o[4] + o[1] * (o[3] * (128127984.04046 - 551966.9703006 * o[5]) + o[1] * (-985549096.23276 * o[3] + o[1] * (2822454697.3002 * o[3] + o[1] * (o[3] * (-3594897141.0703 + 3715408.5996233 * o[5]) + o[1] * pi * (252266.40357872 + pi * (1722734991.3197 + pi * (12848734.66465 + (-13105236.545054 - 415351.64835634 * o[3]) * pi))))))))))))))))))));
              elseif pi < (0.00012809002730136 * etabc - 0.67955786399241) * etabc + 905.84278514723 then
                eta2b := eta - 2.6;
                pi2b := pi - 2.0;
                o[1] := pi2b * pi2b;
                o[2] := o[1] * pi2b;
                o[3] := o[1] * o[1];
                o[4] := eta2b * eta2b;
                o[5] := o[4] * o[4];
                o[6] := o[4] * o[5];
                o[7] := o[5] * o[5];
                T := 1489.5041079516 + 0.93747147377932 * pi2b + eta2b * (743.07798314034 + o[2] * (0.00011032831789999 - 0.0000000000000000017565233969407 * o[1] * o[3]) + eta2b * (-97.708318797837 + pi2b * (3.3593118604916 + pi2b * (-0.021810755324761 + pi2b * (0.00018955248387902 + (0.00000028640237477456 - 0.000000000000081456365207833 * o[2]) * pi2b))) + o[5] * (3.3809355601454 * pi2b + o[4] * (-0.10829784403677 * o[1] + o[5] * (2.4742464705674 + (0.16844539671904 + o[1] * (0.0030891541160537 - 0.000010779857357512 * pi2b)) * pi2b + o[6] * (-0.63281320016026 + pi2b * (0.73875745236695 + (-0.046333324635812 + o[1] * (-0.000076462712454814 + 0.0000002821728163504 * pi2b)) * pi2b) + o[6] * (1.1385952129658 + pi2b * (-0.47128737436186 + o[1] * (0.0013555504554949 + (0.000014052392818316 + 0.0000012704902271945 * pi2b) * pi2b)) + o[5] * (-0.47811863648625 + (0.15020273139707 + o[2] * (-0.000031083814331434 + o[1] * (-0.000000011030139238909 - 0.000000000025180545682962 * pi2b))) * pi2b + o[5] * o[7] * (0.0085208123431544 + pi2b * (-0.002176411421975 + pi2b * (0.000071280351959551 + o[1] * (-0.0000010302738212103 + (0.000000073803353468292 + 0.0000000000000086934156344163 * o[3]) * pi2b))))))))))));
              else
                eta2c := eta - 1.8;
                pi2c := pi + 25.0;
                o[1] := pi2c * pi2c;
                o[2] := o[1] * o[1];
                o[3] := o[1] * o[2] * pi2c;
                o[4] := 1 / o[3];
                o[5] := o[1] * o[2];
                o[6] := eta2c * eta2c;
                o[7] := o[2] * o[2];
                o[8] := o[6] * o[6];
                T := eta2c * ((859777.2253558 + o[1] * (482.19755109255 + 0.000000000001126159740723 * o[5])) / o[1] + eta2c * ((-583401318515.9 + (20825544563.171 + 31081.088422714 * o[2]) * pi2c) / o[5] + o[6] * (o[8] * (o[6] * (0.00000012324579690832 * o[5] + o[6] * (-0.0000011606921130984 * o[5] + o[8] * (0.000027846367088554 * o[5] + (-0.00059270038474176 * o[5] + 0.0012918582991878 * o[5] * o[6]) * o[8]))) - 10.842984880077 * pi2c) + o[4] * (7326335090218.1 + o[7] * (3.7966001272486 + (-0.04536417267666 - 0.000000000017804982240686 * o[2]) * pi2c))))) + o[4] * (-3236839855524.2 + pi2c * (358250899454.47 + pi2c * (-10783068217.47 + o[1] * pi2c * (610747.83564516 + pi2c * (-25745.72360417 + (1208.2315865936 + 0.00000000000014559115658698 * o[5]) * pi2c)))));
              end if;
            end tph2;

            function tps2a  "Reverse function for region 2a: T(p,s)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.SpecificEntropy s "Specific entropy";
              output .Modelica.SIunits.Temperature T "Temperature (K)";
            protected
              Real[12] o "Vector of auxiliary variables";
              constant Real IPSTAR = 0.000001 "Scaling variable";
              constant Real ISSTAR2A = 1 / 2000.0 "Scaling variable";
              Real pi "Dimensionless pressure";
              Real sigma2a "Dimensionless specific entropy";
            algorithm
              pi := p * IPSTAR;
              sigma2a := s * ISSTAR2A - 2.0;
              o[1] := pi ^ 0.5;
              o[2] := sigma2a * sigma2a;
              o[3] := o[2] * o[2];
              o[4] := o[3] * o[3];
              o[5] := o[4] * o[4];
              o[6] := pi ^ 0.25;
              o[7] := o[2] * o[4] * o[5];
              o[8] := 1 / o[7];
              o[9] := o[3] * sigma2a;
              o[10] := o[2] * o[3] * sigma2a;
              o[11] := o[3] * o[4] * sigma2a;
              o[12] := o[2] * sigma2a;
              T := ((-392359.83861984 + (515265.7382727 + o[3] * (40482.443161048 + o[2] * o[3] * (-321.93790923902 + o[2] * (96.961424218694 - 22.867846371773 * sigma2a)))) * sigma2a) / (o[4] * o[5]) + o[6] * ((-449429.14124357 + o[3] * (-5011.8336020166 + 0.35684463560015 * o[4] * sigma2a)) / (o[2] * o[5] * sigma2a) + o[6] * (o[8] * (44235.33584819 + o[9] * (-13673.388811708 + o[3] * (421632.60207864 + (22516.925837475 + o[10] * (474.42144865646 - 149.31130797647 * sigma2a)) * sigma2a))) + o[6] * ((-197811.26320452 - 23554.39947076 * sigma2a) / (o[2] * o[3] * o[4] * sigma2a) + o[6] * ((-19070.616302076 + o[11] * (55375.669883164 + (3829.3691437363 - 603.91860580567 * o[2]) * o[3])) * o[8] + o[6] * ((1936.3102620331 + o[2] * (4266.064369861 + o[2] * o[3] * o[4] * (-5978.0638872718 - 704.01463926862 * o[9]))) / (o[2] * o[4] * o[5] * sigma2a) + o[1] * ((338.36784107553 + o[12] * (20.862786635187 + (0.033834172656196 - 0.000043124428414893 * o[12]) * o[3])) * sigma2a + o[6] * (166.53791356412 + sigma2a * (-139.86292055898 + o[3] * (-0.78849547999872 + (0.072132411753872 + o[3] * (-0.0059754839398283 + (-0.000012141358953904 + 0.00000023227096733871 * o[2]) * o[3])) * sigma2a)) + o[6] * (-10.538463566194 + o[3] * (2.0718925496502 + (-0.072193155260427 + 0.0000002074988708112 * o[4]) * o[9]) + o[6] * (o[6] * (o[12] * (0.21037527893619 + 0.00025681239729999 * o[3] * o[4]) + (-0.012799002933781 - 0.0000082198102652018 * o[11]) * o[6] * o[9]) + o[10] * (-0.018340657911379 + 0.00000029036272348696 * o[2] * o[4] * sigma2a))))))))))) / (o[1] * pi);
            end tps2a;

            function tps2b  "Reverse function for region 2b: T(p,s)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.SpecificEntropy s "Specific entropy";
              output .Modelica.SIunits.Temperature T "Temperature (K)";
            protected
              Real[8] o "Vector of auxiliary variables";
              constant Real IPSTAR = 0.000001 "Scaling variable";
              constant Real ISSTAR2B = 1 / 785.3 "Scaling variable";
              Real pi "Dimensionless pressure";
              Real sigma2b "Dimensionless specific entropy";
            algorithm
              pi := p * IPSTAR;
              sigma2b := 10.0 - s * ISSTAR2B;
              o[1] := pi * pi;
              o[2] := o[1] * o[1];
              o[3] := sigma2b * sigma2b;
              o[4] := o[3] * o[3];
              o[5] := o[4] * o[4];
              o[6] := o[3] * o[5] * sigma2b;
              o[7] := o[3] * o[5];
              o[8] := o[3] * sigma2b;
              T := (316876.65083497 + 20.864175881858 * o[6] + pi * (-398593.99803599 - 21.816058518877 * o[6] + pi * (223697.85194242 + (-2784.1703445817 + 9.920743607148 * o[7]) * sigma2b + pi * (-75197.512299157 + (2970.8605951158 + o[7] * (-3.4406878548526 + 0.38815564249115 * sigma2b)) * sigma2b + pi * (17511.29508575 + sigma2b * (-1423.7112854449 + (1.0943803364167 + 0.89971619308495 * o[4]) * o[4] * sigma2b) + pi * (-3375.9740098958 + (471.62885818355 + o[4] * (-1.9188241993679 + o[8] * (0.41078580492196 - 0.33465378172097 * sigma2b))) * sigma2b + pi * (1387.0034777505 + sigma2b * (-406.63326195838 + sigma2b * (41.72734715961 + o[3] * (2.1932549434532 + sigma2b * (-1.0320050009077 + (0.35882943516703 + 0.0052511453726066 * o[8]) * sigma2b)))) + pi * (12.838916450705 + sigma2b * (-2.8642437219381 + sigma2b * (0.56912683664855 + (-0.099962954584931 + o[4] * (-0.0032632037778459 + 0.00023320922576723 * sigma2b)) * sigma2b)) + pi * (-0.1533480985745 + (0.029072288239902 + 0.00037534702741167 * o[4]) * sigma2b + pi * (0.0017296691702411 + (-0.00038556050844504 - 0.000035017712292608 * o[3]) * sigma2b + pi * (-0.000014566393631492 + 0.0000056420857267269 * sigma2b + pi * (0.000000041286150074605 + (-0.000000020684671118824 + 0.0000000016409393674725 * sigma2b) * sigma2b)))))))))))) / (o[1] * o[2]);
            end tps2b;

            function tps2c  "Reverse function for region 2c: T(p,s)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.SpecificEntropy s "Specific entropy";
              output .Modelica.SIunits.Temperature T "Temperature (K)";
            protected
              constant Real IPSTAR = 0.000001 "Scaling variable";
              constant Real ISSTAR2C = 1 / 2925.1 "Scaling variable";
              Real pi "Dimensionless pressure";
              Real sigma2c "Dimensionless specific entropy";
              Real[3] o "Vector of auxiliary variables";
            algorithm
              pi := p * IPSTAR;
              sigma2c := 2.0 - s * ISSTAR2C;
              o[1] := pi * pi;
              o[2] := sigma2c * sigma2c;
              o[3] := o[2] * o[2];
              T := (909.68501005365 + 2404.566708842 * sigma2c + pi * (-591.6232638713 + pi * (541.45404128074 + sigma2c * (-270.98308411192 + (979.76525097926 - 469.66772959435 * sigma2c) * sigma2c) + pi * (14.399274604723 + (-19.104204230429 + o[2] * (5.3299167111971 - 21.252975375934 * sigma2c)) * sigma2c + pi * (-0.3114733441376 + (0.60334840894623 - 0.042764839702509 * sigma2c) * sigma2c + pi * (0.0058185597255259 + (-0.014597008284753 + 0.0056631175631027 * o[3]) * sigma2c + pi * (-0.000076155864584577 + sigma2c * (0.00022440342919332 - 0.000012561095013413 * o[2] * sigma2c) + pi * (0.00000063323132660934 + (-0.0000020541989675375 + 0.000000036405370390082 * sigma2c) * sigma2c + pi * (-0.0000000029759897789215 + 0.000000010136618529763 * sigma2c + pi * (0.0000000000059925719692351 + sigma2c * (-0.000000000020677870105164 + o[2] * (-0.000000000020874278181886 + (0.00000000010162166825089 - 0.00000000016429828281347 * sigma2c) * sigma2c)))))))))))) / o[1];
            end tps2c;

            function tps2  "Reverse function for region 2: T(p,s)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.SpecificEntropy s "Specific entropy";
              output .Modelica.SIunits.Temperature T "Temperature (K)";
            protected
              Real pi "Dimensionless pressure";
              constant .Modelica.SIunits.SpecificEntropy SLIMIT = 5850.0 "Subregion boundary specific entropy between regions 2a and 2b";
            algorithm
              if p < 4000000.0 then
                T := tps2a(p, s);
              elseif s > SLIMIT then
                T := tps2b(p, s);
              else
                T := tps2c(p, s);
              end if;
            end tps2;

            function tsat  "Region 4 saturation temperature as a function of pressure"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.Temperature t_sat "Temperature";
            protected
              Real pi "Dimensionless pressure";
              Real[20] o "Vector of auxiliary variables";
            algorithm
              assert(p > triple.ptriple, "IF97 medium function tsat called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              pi := min(p, data.PCRIT) * data.IPSTAR;
              o[1] := pi ^ 0.25;
              o[2] := -3232555.0322333 * o[1];
              o[3] := pi ^ 0.5;
              o[4] := -724213.16703206 * o[3];
              o[5] := 405113.40542057 + o[2] + o[4];
              o[6] := -17.073846940092 * o[1];
              o[7] := 14.91510861353 + o[3] + o[6];
              o[8] := -4.0 * o[5] * o[7];
              o[9] := 12020.82470247 * o[1];
              o[10] := 1167.0521452767 * o[3];
              o[11] := -4823.2657361591 + o[10] + o[9];
              o[12] := o[11] * o[11];
              o[13] := o[12] + o[8];
              o[14] := o[13] ^ 0.5;
              o[15] := -o[14];
              o[16] := -12020.82470247 * o[1];
              o[17] := -1167.0521452767 * o[3];
              o[18] := 4823.2657361591 + o[15] + o[16] + o[17];
              o[19] := 1 / o[18];
              o[20] := 2.0 * o[19] * o[5];
              t_sat := 0.5 * (650.17534844798 + o[20] - (-4.0 * (-0.23855557567849 + 1300.35069689596 * o[19] * o[5]) + (650.17534844798 + o[20]) ^ 2.0) ^ 0.5);
              annotation(derivative = tsat_der);
            end tsat;

            function dtsatofp  "Derivative of saturation temperature w.r.t. pressure"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output Real dtsat(unit = "K/Pa") "Derivative of T w.r.t. p";
            protected
              Real pi "Dimensionless pressure";
              Real[49] o "Vector of auxiliary variables";
            algorithm
              pi := max(Modelica.Constants.small, p * data.IPSTAR);
              o[1] := pi ^ 0.75;
              o[2] := 1 / o[1];
              o[3] := -4.268461735023 * o[2];
              o[4] := sqrt(pi);
              o[5] := 1 / o[4];
              o[6] := 0.5 * o[5];
              o[7] := o[3] + o[6];
              o[8] := pi ^ 0.25;
              o[9] := -3232555.0322333 * o[8];
              o[10] := -724213.16703206 * o[4];
              o[11] := 405113.40542057 + o[10] + o[9];
              o[12] := -4 * o[11] * o[7];
              o[13] := -808138.758058325 * o[2];
              o[14] := -362106.58351603 * o[5];
              o[15] := o[13] + o[14];
              o[16] := -17.073846940092 * o[8];
              o[17] := 14.91510861353 + o[16] + o[4];
              o[18] := -4 * o[15] * o[17];
              o[19] := 3005.2061756175 * o[2];
              o[20] := 583.52607263835 * o[5];
              o[21] := o[19] + o[20];
              o[22] := 12020.82470247 * o[8];
              o[23] := 1167.0521452767 * o[4];
              o[24] := -4823.2657361591 + o[22] + o[23];
              o[25] := 2.0 * o[21] * o[24];
              o[26] := o[12] + o[18] + o[25];
              o[27] := -4.0 * o[11] * o[17];
              o[28] := o[24] * o[24];
              o[29] := o[27] + o[28];
              o[30] := sqrt(o[29]);
              o[31] := 1 / o[30];
              o[32] := -o[30];
              o[33] := -12020.82470247 * o[8];
              o[34] := -1167.0521452767 * o[4];
              o[35] := 4823.2657361591 + o[32] + o[33] + o[34];
              o[36] := o[30];
              o[37] := -4823.2657361591 + o[22] + o[23] + o[36];
              o[38] := o[37] * o[37];
              o[39] := 1 / o[38];
              o[40] := -1.72207339365771 * o[30];
              o[41] := 21592.2055343628 * o[8];
              o[42] := o[30] * o[8];
              o[43] := -8192.87114842946 * o[4];
              o[44] := -0.510632954559659 * o[30] * o[4];
              o[45] := -3100.02526152368 * o[1];
              o[46] := pi;
              o[47] := 1295.95640782102 * o[46];
              o[48] := 2862.09212505088 + o[40] + o[41] + o[42] + o[43] + o[44] + o[45] + o[47];
              o[49] := 1 / (o[35] * o[35]);
              dtsat := data.IPSTAR * 0.5 * (2.0 * o[15] / o[35] - 2.0 * o[11] * (-3005.2061756175 * o[2] - 0.5 * o[26] * o[31] - 583.52607263835 * o[5]) * o[49] - 20953.46356643991 * (o[39] * (1295.95640782102 + 5398.05138359071 * o[2] + 0.25 * o[2] * o[30] - 0.861036696828853 * o[26] * o[31] - 0.255316477279829 * o[26] * o[31] * o[4] - 4096.43557421473 * o[5] - 0.255316477279829 * o[30] * o[5] - 2325.01894614276 / o[8] + 0.5 * o[26] * o[31] * o[8]) - 2.0 * (o[19] + o[20] + 0.5 * o[26] * o[31]) * o[48] * o[37] ^ (-3)) / sqrt(o[39] * o[48]));
            end dtsatofp;

            function tsat_der  "Derivative function for tsat"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input Real der_p(unit = "Pa/s") "Pressure derivative";
              output Real der_tsat(unit = "K/s") "Temperature derivative";
            protected
              Real dtp;
            algorithm
              dtp := dtsatofp(p);
              der_tsat := dtp * der_p;
            end tsat_der;

            function psat  "Region 4 saturation pressure as a function of temperature"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Temperature T "Temperature (K)";
              output .Modelica.SIunits.Pressure p_sat "Pressure";
            protected
              Real[8] o "Vector of auxiliary variables";
              Real Tlim = min(T, data.TCRIT);
            algorithm
              assert(T >= 273.16, "IF97 medium function psat: input temperature (= " + String(triple.ptriple) + " K).\n" + "lower than the triple point temperature 273.16 K");
              o[1] := -650.17534844798 + Tlim;
              o[2] := 1 / o[1];
              o[3] := -0.23855557567849 * o[2];
              o[4] := o[3] + Tlim;
              o[5] := -4823.2657361591 * o[4];
              o[6] := o[4] * o[4];
              o[7] := 14.91510861353 * o[6];
              o[8] := 405113.40542057 + o[5] + o[7];
              p_sat := 16000000.0 * o[8] * o[8] * o[8] * o[8] * 1 / (3232555.0322333 - 12020.82470247 * o[4] + 17.073846940092 * o[6] + (-4.0 * (-724213.16703206 + 1167.0521452767 * o[4] + o[6]) * o[8] + (-3232555.0322333 + 12020.82470247 * o[4] - 17.073846940092 * o[6]) ^ 2.0) ^ 0.5) ^ 4.0;
              annotation(derivative = psat_der);
            end psat;

            function dptofT  "Derivative of pressure w.r.t. temperature along the saturation pressure curve"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Temperature T "Temperature (K)";
              output Real dpt(unit = "Pa/K") "Temperature derivative of pressure";
            protected
              Real[31] o "Vector of auxiliary variables";
              Real Tlim "Temperature limited to TCRIT";
            algorithm
              Tlim := min(T, data.TCRIT);
              o[1] := -650.17534844798 + Tlim;
              o[2] := 1 / o[1];
              o[3] := -0.23855557567849 * o[2];
              o[4] := o[3] + Tlim;
              o[5] := -4823.2657361591 * o[4];
              o[6] := o[4] * o[4];
              o[7] := 14.91510861353 * o[6];
              o[8] := 405113.40542057 + o[5] + o[7];
              o[9] := o[8] * o[8];
              o[10] := o[9] * o[9];
              o[11] := o[1] * o[1];
              o[12] := 1 / o[11];
              o[13] := 0.23855557567849 * o[12];
              o[14] := 1.0 + o[13];
              o[15] := 12020.82470247 * o[4];
              o[16] := -17.073846940092 * o[6];
              o[17] := -3232555.0322333 + o[15] + o[16];
              o[18] := -4823.2657361591 * o[14];
              o[19] := 29.83021722706 * o[14] * o[4];
              o[20] := o[18] + o[19];
              o[21] := 1167.0521452767 * o[4];
              o[22] := -724213.16703206 + o[21] + o[6];
              o[23] := o[17] * o[17];
              o[24] := -4.0 * o[22] * o[8];
              o[25] := o[23] + o[24];
              o[26] := sqrt(o[25]);
              o[27] := -12020.82470247 * o[4];
              o[28] := 17.073846940092 * o[6];
              o[29] := 3232555.0322333 + o[26] + o[27] + o[28];
              o[30] := o[29] * o[29];
              o[31] := o[30] * o[30];
              dpt := 1000000.0 * ((-64.0 * o[10] * (-12020.82470247 * o[14] + 34.147693880184 * o[14] * o[4] + 0.5 * (-4.0 * o[20] * o[22] + 2.0 * o[17] * (12020.82470247 * o[14] - 34.147693880184 * o[14] * o[4]) - 4.0 * (1167.0521452767 * o[14] + 2.0 * o[14] * o[4]) * o[8]) / o[26])) / (o[29] * o[31]) + 64.0 * o[20] * o[8] * o[9] / o[31]);
            end dptofT;

            function psat_der  "Derivative function for psat"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Temperature T "Temperature (K)";
              input Real der_T(unit = "K/s") "Temperature derivative";
              output Real der_psat(unit = "Pa/s") "Pressure";
            protected
              Real dpt;
            algorithm
              dpt := dptofT(T);
              der_psat := dpt * der_T;
            end psat_der;

            function h3ab_p  "Region 3 a b boundary for pressure/enthalpy"
              extends Modelica.Icons.Function;
              output .Modelica.SIunits.SpecificEnthalpy h "Enthalpy";
              input .Modelica.SIunits.Pressure p "Pressure";
            protected
              constant Real[:] n = {2014.64004206875, 3.74696550136983, -0.0219921901054187, 0.000087513168600995};
              constant .Modelica.SIunits.SpecificEnthalpy hstar = 1000 "Normalization enthalpy";
              constant .Modelica.SIunits.Pressure pstar = 1000000.0 "Normalization pressure";
              Real pi = p / pstar "Normalized specific pressure";
            algorithm
              h := (n[1] + n[2] * pi + n[3] * pi ^ 2 + n[4] * pi ^ 3) * hstar;
              annotation(Documentation(info = "<html>
                     <p>
                     &nbsp;Equation number 1 from:
                     </p>
                     <div style=\"text-align: center;\">&nbsp;[1] The international Association
                     for the Properties of Water and Steam<br>
                     &nbsp;Vejle, Denmark<br>
                     &nbsp;August 2003<br>
                     &nbsp;Supplementary Release on Backward Equations for the Functions
                     T(p,h), v(p,h) and T(p,s), <br>
                     &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
                     the Thermodynamic Properties of<br>
                     &nbsp;Water and Steam</div>
                     </html>"));
            end h3ab_p;

            function T3a_ph  "Region 3 a: inverse function T(p,h)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
              output .Modelica.SIunits.Temp_K T "Temperature";
            protected
              constant Real[:] n = {-0.000000133645667811215, 0.00000455912656802978, -0.0000146294640700979, 0.0063934131297008, 372.783927268847, -7186.54377460447, 573494.7521034, -2675693.29111439, -0.0000334066283302614, -0.0245479214069597, 47.8087847764996, 0.00000764664131818904, 0.00128350627676972, 0.0171219081377331, -8.51007304583213, -0.0136513461629781, -0.00000384460997596657, 0.00337423807911655, -0.551624873066791, 0.72920227710747, -0.00992522757376041, -0.119308831407288, 0.793929190615421, 0.454270731799386, 0.20999859125991, -0.00642109823904738, -0.023515586860454, 0.00252233108341612, -0.00764885133368119, 0.0136176427574291, -0.0133027883575669};
              constant Real[:] I = {-12, -12, -12, -12, -12, -12, -12, -12, -10, -10, -10, -8, -8, -8, -8, -5, -3, -2, -2, -2, -1, -1, 0, 0, 1, 3, 3, 4, 4, 10, 12};
              constant Real[:] J = {0, 1, 2, 6, 14, 16, 20, 22, 1, 5, 12, 0, 2, 4, 10, 2, 0, 1, 3, 4, 0, 2, 0, 1, 1, 0, 1, 0, 3, 4, 5};
              constant .Modelica.SIunits.SpecificEnthalpy hstar = 2300000.0 "Normalization enthalpy";
              constant .Modelica.SIunits.Pressure pstar = 100000000.0 "Normalization pressure";
              constant .Modelica.SIunits.Temp_K Tstar = 760 "Normalization temperature";
              Real pi = p / pstar "Normalized specific pressure";
              Real eta = h / hstar "Normalized specific enthalpy";
            algorithm
              T := sum(n[i] * (pi + 0.24) ^ I[i] * (eta - 0.615) ^ J[i] for i in 1:31) * Tstar;
              annotation(Documentation(info = "<html>
               <p>
                &nbsp;Equation number 2 from:
               </p>
                <div style=\"text-align: center;\">&nbsp;[1] The international Association
                for the Properties of Water and Steam<br>
                &nbsp;Vejle, Denmark<br>
                &nbsp;August 2003<br>
                &nbsp;Supplementary Release on Backward Equations for the Functions
                T(p,h), v(p,h) and T(p,s), <br>
                &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
                the Thermodynamic Properties of<br>
                &nbsp;Water and Steam</div>
                </html>"));
            end T3a_ph;

            function T3b_ph  "Region 3 b: inverse function T(p,h)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
              output .Modelica.SIunits.Temp_K T "Temperature";
            protected
              constant Real[:] n = {0.000032325457364492, -0.000127575556587181, -0.000475851877356068, 0.00156183014181602, 0.105724860113781, -85.8514221132534, 724.140095480911, 0.00296475810273257, -0.00592721983365988, -0.0126305422818666, -0.115716196364853, 84.9000969739595, -0.0108602260086615, 0.0154304475328851, 0.0750455441524466, 0.0252520973612982, -0.0602507901232996, -3.07622221350501, -0.0574011959864879, 5.03471360939849, -0.925081888584834, 3.91733882917546, -77.314600713019, 9493.08762098587, -1410437.19679409, 8491662.30819026, 0.861095729446704, 0.32334644281172, 0.873281936020439, -0.436653048526683, 0.286596714529479, -0.131778331276228, 0.00676682064330275};
              constant Real[:] I = {-12, -12, -10, -10, -10, -10, -10, -8, -8, -8, -8, -8, -6, -6, -6, -4, -4, -3, -2, -2, -1, -1, -1, -1, -1, -1, 0, 0, 1, 3, 5, 6, 8};
              constant Real[:] J = {0, 1, 0, 1, 5, 10, 12, 0, 1, 2, 4, 10, 0, 1, 2, 0, 1, 5, 0, 4, 2, 4, 6, 10, 14, 16, 0, 2, 1, 1, 1, 1, 1};
              constant .Modelica.SIunits.Temp_K Tstar = 860 "Normalization temperature";
              constant .Modelica.SIunits.Pressure pstar = 100000000.0 "Normalization pressure";
              constant .Modelica.SIunits.SpecificEnthalpy hstar = 2800000.0 "Normalization enthalpy";
              Real pi = p / pstar "Normalized specific pressure";
              Real eta = h / hstar "Normalized specific enthalpy";
            algorithm
              T := sum(n[i] * (pi + 0.298) ^ I[i] * (eta - 0.72) ^ J[i] for i in 1:33) * Tstar;
              annotation(Documentation(info = "<html>
                <p>
                &nbsp;Equation number 3 from:
               </p>
                <div style=\"text-align: center;\">&nbsp;[1] The international Association
                for the Properties of Water and Steam<br>
                &nbsp;Vejle, Denmark<br>
                &nbsp;August 2003<br>
                &nbsp;Supplementary Release on Backward Equations for the Functions
                T(p,h), v(p,h) and T(p,s), <br>
                &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
                the Thermodynamic Properties of<br>
                &nbsp;Water and Steam</div>
                </html>"));
            end T3b_ph;

            function v3a_ph  "Region 3 a: inverse function v(p,h)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
              output .Modelica.SIunits.SpecificVolume v "Specific volume";
            protected
              constant Real[:] n = {0.00529944062966028, -0.170099690234461, 11.1323814312927, -2178.98123145125, -0.000506061827980875, 0.556495239685324, -9.43672726094016, -0.297856807561527, 93.9353943717186, 0.0192944939465981, 0.421740664704763, -3689141.2628233, -0.00737566847600639, -0.354753242424366, -1.99768169338727, 1.15456297059049, 5683.6687581596, 0.00808169540124668, 0.172416341519307, 1.04270175292927, -0.297691372792847, 0.560394465163593, 0.275234661176914, -0.148347894866012, -0.0651142513478515, -2.92468715386302, 0.0664876096952665, 3.52335014263844, -0.0146340792313332, -2.24503486668184, 1.10533464706142, -0.0408757344495612};
              constant Real[:] I = {-12, -12, -12, -12, -10, -10, -10, -8, -8, -6, -6, -6, -4, -4, -3, -2, -2, -1, -1, -1, -1, 0, 0, 1, 1, 1, 2, 2, 3, 4, 5, 8};
              constant Real[:] J = {6, 8, 12, 18, 4, 7, 10, 5, 12, 3, 4, 22, 2, 3, 7, 3, 16, 0, 1, 2, 3, 0, 1, 0, 1, 2, 0, 2, 0, 2, 2, 2};
              constant .Modelica.SIunits.Volume vstar = 0.0028 "Normalization temperature";
              constant .Modelica.SIunits.Pressure pstar = 100000000.0 "Normalization pressure";
              constant .Modelica.SIunits.SpecificEnthalpy hstar = 2100000.0 "Normalization enthalpy";
              Real pi = p / pstar "Normalized specific pressure";
              Real eta = h / hstar "Normalized specific enthalpy";
            algorithm
              v := sum(n[i] * (pi + 0.128) ^ I[i] * (eta - 0.727) ^ J[i] for i in 1:32) * vstar;
              annotation(Documentation(info = "<html>
               <p>
               &nbsp;Equation number 4 from:
               </p>
                <div style=\"text-align: center;\">&nbsp;[1] The international Association
                for the Properties of Water and Steam<br>
                &nbsp;Vejle, Denmark<br>
                &nbsp;August 2003<br>
                &nbsp;Supplementary Release on Backward Equations for the Functions
                T(p,h), v(p,h) and T(p,s), <br>
                &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
                the Thermodynamic Properties of<br>
                &nbsp;Water and Steam</div>
                </html>"));
            end v3a_ph;

            function v3b_ph  "Region 3 b: inverse function v(p,h)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
              output .Modelica.SIunits.SpecificVolume v "Specific volume";
            protected
              constant Real[:] n = {-0.00000000225196934336318, 0.0000000140674363313486, 0.0000023378408528056, -0.0000331833715229001, 0.00107956778514318, -0.271382067378863, 1.07202262490333, -0.853821329075382, -0.0000215214194340526, 0.00076965608822273, -0.00431136580433864, 0.453342167309331, -0.507749535873652, -100.475154528389, -0.219201924648793, -3.21087965668917, 607.567815637771, 0.000557686450685932, 0.18749904002955, 0.00905368030448107, 0.285417173048685, 0.0329924030996098, 0.239897419685483, 4.82754995951394, -11.8035753702231, 0.169490044091791, -0.0179967222507787, 0.0371810116332674, -0.0536288335065096, 1.6069710109252};
              constant Real[:] I = {-12, -12, -8, -8, -8, -8, -8, -8, -6, -6, -6, -6, -6, -6, -4, -4, -4, -3, -3, -2, -2, -1, -1, -1, -1, 0, 1, 1, 2, 2};
              constant Real[:] J = {0, 1, 0, 1, 3, 6, 7, 8, 0, 1, 2, 5, 6, 10, 3, 6, 10, 0, 2, 1, 2, 0, 1, 4, 5, 0, 0, 1, 2, 6};
              constant .Modelica.SIunits.Volume vstar = 0.0088 "Normalization temperature";
              constant .Modelica.SIunits.Pressure pstar = 100000000.0 "Normalization pressure";
              constant .Modelica.SIunits.SpecificEnthalpy hstar = 2800000.0 "Normalization enthalpy";
              Real pi = p / pstar "Normalized specific pressure";
              Real eta = h / hstar "Normalized specific enthalpy";
            algorithm
              v := sum(n[i] * (pi + 0.0661) ^ I[i] * (eta - 0.72) ^ J[i] for i in 1:30) * vstar;
              annotation(Documentation(info = "<html>
               <p>
                &nbsp;Equation number 5 from:
               </p>
                <div style=\"text-align: center;\">&nbsp;[1] The international Association
                for the Properties of Water and Steam<br>
                &nbsp;Vejle, Denmark<br>
                &nbsp;August 2003<br>
                &nbsp;Supplementary Release on Backward Equations for the Functions
                T(p,h), v(p,h) and T(p,s), <br>
                &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
                the Thermodynamic Properties of<br>
                &nbsp;Water and Steam</div>
                </html>"));
            end v3b_ph;

            function T3a_ps  "Region 3 a: inverse function T(p,s)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.SpecificEntropy s "Specific entropy";
              output .Modelica.SIunits.Temp_K T "Temperature";
            protected
              constant Real[:] n = {1500420082.63875, -159397258480.424, 0.000502181140217975, -67.2057767855466, 1450.58545404456, -8238.8953488889, -0.154852214233853, 11.2305046746695, -29.7000213482822, 43856513263.5495, 0.00137837838635464, -2.97478527157462, 9717779473494.13, -0.0000571527767052398, 28830.794977842, -74442828926270.3, 12.8017324848921, -368.275545889071, 6.64768904779177e+15, 0.044935925195888, -4.22897836099655, -0.240614376434179, -4.74341365254924, 0.72409399912611, 0.923874349695897, 3.99043655281015, 0.0384066651868009, -0.00359344365571848, -0.735196448821653, 0.188367048396131, 0.000141064266818704, -0.00257418501496337, 0.00123220024851555};
              constant Real[:] I = {-12, -12, -10, -10, -10, -10, -8, -8, -8, -8, -6, -6, -6, -5, -5, -5, -4, -4, -4, -2, -2, -1, -1, 0, 0, 0, 1, 2, 2, 3, 8, 8, 10};
              constant Real[:] J = {28, 32, 4, 10, 12, 14, 5, 7, 8, 28, 2, 6, 32, 0, 14, 32, 6, 10, 36, 1, 4, 1, 6, 0, 1, 4, 0, 0, 3, 2, 0, 1, 2};
              constant .Modelica.SIunits.Temp_K Tstar = 760 "Normalization temperature";
              constant .Modelica.SIunits.Pressure pstar = 100000000.0 "Normalization pressure";
              constant .Modelica.SIunits.SpecificEntropy sstar = 4400.0 "Normalization entropy";
              Real pi = p / pstar "Normalized specific pressure";
              Real sigma = s / sstar "Normalized specific entropy";
            algorithm
              T := sum(n[i] * (pi + 0.24) ^ I[i] * (sigma - 0.703) ^ J[i] for i in 1:33) * Tstar;
              annotation(Documentation(info = "<html>
               <p>
                &nbsp;Equation number 6 from:
               </p>
                <div style=\"text-align: center;\">&nbsp;[1] The international Association
                for the Properties of Water and Steam<br>
                &nbsp;Vejle, Denmark<br>
                &nbsp;August 2003<br>
                &nbsp;Supplementary Release on Backward Equations for the Functions
                T(p,h), v(p,h) and T(p,s), <br>
                &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
                the Thermodynamic Properties of<br>
                &nbsp;Water and Steam</div>
                </html>"));
            end T3a_ps;

            function T3b_ps  "Region 3 b: inverse function T(p,s)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.SpecificEntropy s "Specific entropy";
              output .Modelica.SIunits.Temp_K T "Temperature";
            protected
              constant Real[:] n = {0.52711170160166, -40.1317830052742, 153.020073134484, -2247.99398218827, -0.193993484669048, -1.40467557893768, 42.6799878114024, 0.752810643416743, 22.6657238616417, -622.873556909932, -0.660823667935396, 0.841267087271658, -25.3717501764397, 485.708963532948, 880.531517490555, 2650155.92794626, -0.359287150025783, -656.991567673753, 2.41768149185367, 0.856873461222588, 0.655143675313458, -0.213535213206406, 0.00562974957606348, -316955725450471.0, -0.000699997000152457, 0.0119845803210767, 0.0000193848122022095, -0.0000215095749182309};
              constant Real[:] I = {-12, -12, -12, -12, -8, -8, -8, -6, -6, -6, -5, -5, -5, -5, -5, -4, -3, -3, -2, 0, 2, 3, 4, 5, 6, 8, 12, 14};
              constant Real[:] J = {1, 3, 4, 7, 0, 1, 3, 0, 2, 4, 0, 1, 2, 4, 6, 12, 1, 6, 2, 0, 1, 1, 0, 24, 0, 3, 1, 2};
              constant .Modelica.SIunits.Temp_K Tstar = 860 "Normalization temperature";
              constant .Modelica.SIunits.Pressure pstar = 100000000.0 "Normalization pressure";
              constant .Modelica.SIunits.SpecificEntropy sstar = 5300.0 "Normalization entropy";
              Real pi = p / pstar "Normalized specific pressure";
              Real sigma = s / sstar "Normalized specific entropy";
            algorithm
              T := sum(n[i] * (pi + 0.76) ^ I[i] * (sigma - 0.818) ^ J[i] for i in 1:28) * Tstar;
              annotation(Documentation(info = "<html>
               <p>
                &nbsp;Equation number 7 from:
               </p>
                <div style=\"text-align: center;\">&nbsp;[1] The international Association
                for the Properties of Water and Steam<br>
                &nbsp;Vejle, Denmark<br>
                &nbsp;August 2003<br>
                &nbsp;Supplementary Release on Backward Equations for the Functions
                T(p,h), v(p,h) and T(p,s), <br>
                &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
                the Thermodynamic Properties of<br>
                &nbsp;Water and Steam</div>
               </html>"));
            end T3b_ps;

            function v3a_ps  "Region 3 a: inverse function v(p,s)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.SpecificEntropy s "Specific entropy";
              output .Modelica.SIunits.SpecificVolume v "Specific volume";
            protected
              constant Real[:] n = {79.5544074093975, -2382.6124298459, 17681.3100617787, -0.00110524727080379, -15.3213833655326, 297.544599376982, -35031520.6871242, 0.277513761062119, -0.523964271036888, -148011.182995403, 1600148.99374266, 1708023226634.27, 0.000246866996006494, 1.6532608479798, -0.118008384666987, 2.537986423559, 0.965127704669424, -28.2172420532826, 0.203224612353823, 1.10648186063513, 0.52612794845128, 0.277000018736321, 1.08153340501132, -0.0744127885357893, 0.0164094443541384, -0.0680468275301065, 0.025798857610164, -0.000145749861944416};
              constant Real[:] I = {-12, -12, -12, -10, -10, -10, -10, -8, -8, -8, -8, -6, -5, -4, -3, -3, -2, -2, -1, -1, 0, 0, 0, 1, 2, 4, 5, 6};
              constant Real[:] J = {10, 12, 14, 4, 8, 10, 20, 5, 6, 14, 16, 28, 1, 5, 2, 4, 3, 8, 1, 2, 0, 1, 3, 0, 0, 2, 2, 0};
              constant .Modelica.SIunits.Volume vstar = 0.0028 "Normalization temperature";
              constant .Modelica.SIunits.Pressure pstar = 100000000.0 "Normalization pressure";
              constant .Modelica.SIunits.SpecificEntropy sstar = 4400.0 "Normalization entropy";
              Real pi = p / pstar "Normalized specific pressure";
              Real sigma = s / sstar "Normalized specific entropy";
            algorithm
              v := sum(n[i] * (pi + 0.187) ^ I[i] * (sigma - 0.755) ^ J[i] for i in 1:28) * vstar;
              annotation(Documentation(info = "<html>
               <p>
                &nbsp;Equation number 8 from:
               </p>
                <div style=\"text-align: center;\">&nbsp;[1] The international Association
                for the Properties of Water and Steam<br>
                &nbsp;Vejle, Denmark<br>
                &nbsp;August 2003<br>
                &nbsp;Supplementary Release on Backward Equations for the Functions
                T(p,h), v(p,h) and T(p,s), <br>
                &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
                the Thermodynamic Properties of<br>
                &nbsp;Water and Steam</div>
               </html>"));
            end v3a_ps;

            function v3b_ps  "Region 3 b: inverse function v(p,s)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.SpecificEntropy s "Specific entropy";
              output .Modelica.SIunits.SpecificVolume v "Specific volume";
            protected
              constant Real[:] n = {0.0000591599780322238, -0.00185465997137856, 0.0104190510480013, 0.0059864730203859, -0.771391189901699, 1.72549765557036, -0.000467076079846526, 0.0134533823384439, -0.0808094336805495, 0.508139374365767, 0.00128584643361683, -1.63899353915435, 5.86938199318063, -2.92466667918613, -0.00614076301499537, 5.76199014049172, -12.1613320606788, 1.67637540957944, -7.44135838773463, 0.0378168091437659, 4.01432203027688, 16.0279837479185, 3.17848779347728, -3.58362310304853, -1159952.60446827, 0.199256573577909, -0.122270624794624, -19.1449143716586, -0.0150448002905284, 14.6407900162154, -3.2747778718823};
              constant Real[:] I = {-12, -12, -12, -12, -12, -12, -10, -10, -10, -10, -8, -5, -5, -5, -4, -4, -4, -4, -3, -2, -2, -2, -2, -2, -2, 0, 0, 0, 1, 1, 2};
              constant Real[:] J = {0, 1, 2, 3, 5, 6, 0, 1, 2, 4, 0, 1, 2, 3, 0, 1, 2, 3, 1, 0, 1, 2, 3, 4, 12, 0, 1, 2, 0, 2, 2};
              constant .Modelica.SIunits.Volume vstar = 0.0088 "Normalization temperature";
              constant .Modelica.SIunits.Pressure pstar = 100000000.0 "Normalization pressure";
              constant .Modelica.SIunits.SpecificEntropy sstar = 5300.0 "Normalization entropy";
              Real pi = p / pstar "Normalized specific pressure";
              Real sigma = s / sstar "Normalized specific entropy";
            algorithm
              v := sum(n[i] * (pi + 0.298) ^ I[i] * (sigma - 0.816) ^ J[i] for i in 1:31) * vstar;
              annotation(Documentation(info = "<html>
               <p>
                &nbsp;Equation number 9 from:
               </p>
               <div style=\"text-align: center;\">&nbsp;[1] The international Association
                for the Properties of Water and Steam<br>
                &nbsp;Vejle, Denmark<br>
                &nbsp;August 2003<br>
                &nbsp;Supplementary Release on Backward Equations for the Functions
                T(p,h), v(p,h) and T(p,s), <br>
                &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
                the Thermodynamic Properties of<br>
                &nbsp;Water and Steam</div>
               </html>"));
            end v3b_ps;
            annotation(Documentation(info = "<HTML><h4>Package description</h4>
                       <p>Package BaseIF97/Basic computes the the fundamental functions for the 5 regions of the steam tables
                       as described in the standards document <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/IF97.pdf\">IF97.pdf</a>. The code of these
                       functions has been generated using <b><i>Mathematica</i></b> and the add-on packages \"Format\" and \"Optimize\"
                       to generate highly efficient, expression-optimized C-code from a symbolic representation of the thermodynamic
                       functions. The C-code has than been transformed into Modelica code. An important feature of this optimization was to
                       simultaneously optimize the functions and the directional derivatives because they share many common subexpressions.</p>
                       <h4>Package contents</h4>
                       <ul>
                       <li>Function <b>g1</b> computes the dimensionless Gibbs function for region 1 and all derivatives up
                       to order 2 w.r.t. pi and tau. Inputs: p and T.</li>
                       <li>Function <b>g2</b> computes the dimensionless Gibbs function  for region 2 and all derivatives up
                       to order 2 w.r.t. pi and tau. Inputs: p and T.</li>
                       <li>Function <b>g2metastable</b> computes the dimensionless Gibbs function for metastable vapour
                       (adjacent to region 2 but 2-phase at equilibrium) and all derivatives up
                       to order 2 w.r.t. pi and tau. Inputs: p and T.</li>
                       <li>Function <b>f3</b> computes the dimensionless Helmholtz function  for region 3 and all derivatives up
                       to order 2 w.r.t. delta and tau. Inputs: d and T.</li>
                       <li>Function <b>g5</b>computes the dimensionless Gibbs function for region 5 and all derivatives up
                       to order 2 w.r.t. pi and tau. Inputs: p and T.</li>
                       <li>Function <b>tph1</b> computes the inverse function T(p,h) in region 1.</li>
                       <li>Function <b>tph2</b> computes the inverse function T(p,h) in region 2.</li>
                       <li>Function <b>tps2a</b> computes the inverse function T(p,s) in region 2a.</li>
                       <li>Function <b>tps2b</b> computes the inverse function T(p,s) in region 2b.</li>
                       <li>Function <b>tps2c</b> computes the inverse function T(p,s) in region 2c.</li>
                       <li>Function <b>tps2</b> computes the inverse function T(p,s) in region 2.</li>
                       <li>Function <b>tsat</b> computes the saturation temperature as a function of pressure.</li>
                       <li>Function <b>dtsatofp</b> computes the derivative of the saturation temperature w.r.t. pressure as
                       a function of pressure.</li>
                       <li>Function <b>tsat_der</b> computes the Modelica derivative function of tsat.</li>
                       <li>Function <b>psat</b> computes the saturation pressure as a function of temperature.</li>
                       <li>Function <b>dptofT</b>  computes the derivative of the saturation pressure w.r.t. temperature as
                       a function of temperature.</li>
                       <li>Function <b>psat_der</b> computes the Modelica derivative function of psat.</li>
                       </ul>
                       <h4>Version Info and Revision history
                       </h4>
                       <ul>
                       <li>First implemented: <i>July, 2000</i>
                       by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>
                       </li>
                       </ul>
                       <address>Author: Hubertus Tummescheit, <br>
                   Modelon AB<br>
                   Ideon Science Park<br>
                   SE-22370 Lund, Sweden<br>
                   email: hubertus@modelon.se
                       </address>
                       <ul>
                       <li>Initial version: July 2000</li>
                       <li>Documentation added: December 2002</li>
                       </ul>
                    <p>
                    Equation from:
                    </p>
                    <div style=\"text-align: center;\">&nbsp;[1] The international Association
                    for the Properties of Water and Steam<br>
                    &nbsp;Vejle, Denmark<br>
                    &nbsp;August 2003<br>
                    &nbsp;Supplementary Release on Backward Equations for the Functions
                    T(p,h), v(p,h) and T(p,s), <br>
                    &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
                    the Thermodynamic Properties of<br>
                    &nbsp;Water and Steam</div>
                    </html>"));
          end Basic;

          package Transport  "Transport properties for water according to IAPWS/IF97"
            extends Modelica.Icons.Package;

            function visc_dTp  "Dynamic viscosity eta(d,T,p), industrial formulation"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Density d "Density";
              input .Modelica.SIunits.Temperature T "Temperature (K)";
              input .Modelica.SIunits.Pressure p "Pressure (only needed for region of validity)";
              input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
              output .Modelica.SIunits.DynamicViscosity eta "Dynamic viscosity";
            protected
              constant Real n0 = 1.0 "Viscosity coefficient";
              constant Real n1 = 0.978197 "Viscosity coefficient";
              constant Real n2 = 0.579829 "Viscosity coefficient";
              constant Real n3 = -0.202354 "Viscosity coefficient";
              constant Real[42] nn = array(0.5132047, 0.3205656, 0.0, 0.0, -0.7782567, 0.1885447, 0.2151778, 0.7317883, 1.241044, 1.476783, 0.0, 0.0, -0.2818107, -1.070786, -1.263184, 0.0, 0.0, 0.0, 0.1778064, 0.460504, 0.2340379, -0.4924179, 0.0, 0.0, -0.0417661, 0.0, 0.0, 0.1600435, 0.0, 0.0, 0.0, -0.01578386, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.003629481, 0.0, 0.0) "Viscosity coefficients";
              constant .Modelica.SIunits.Density rhostar = 317.763 "Scaling density";
              constant .Modelica.SIunits.DynamicViscosity etastar = 0.000055071 "Scaling viscosity";
              constant .Modelica.SIunits.Temperature tstar = 647.226 "Scaling temperature";
              Integer i "Auxiliary variable";
              Integer j "Auxiliary variable";
              Real delta "Dimensionless density";
              Real deltam1 "Dimensionless density";
              Real tau "Dimensionless temperature";
              Real taum1 "Dimensionless temperature";
              Real Psi0 "Auxiliary variable";
              Real Psi1 "Auxiliary variable";
              Real tfun "Auxiliary variable";
              Real rhofun "Auxiliary variable";
              Real Tc = T - 273.15 "Celsius temperature for region check";
            algorithm
              delta := d / rhostar;
              assert(d > triple.dvtriple, "IF97 medium function visc_dTp for viscosity called with too low density\n" + "d = " + String(d) + " <= " + String(triple.dvtriple) + " (triple point density)");
              assert(p <= 500000000.0 and Tc >= 0.0 and Tc <= 150 or p <= 350000000.0 and Tc > 150.0 and Tc <= 600 or p <= 300000000.0 and Tc > 600.0 and Tc <= 900, "IF97 medium function visc_dTp: viscosity computed outside the range\n" + "of validity of the IF97 formulation: p = " + String(p) + " Pa, Tc = " + String(Tc) + " K");
              deltam1 := delta - 1.0;
              tau := tstar / T;
              taum1 := tau - 1.0;
              Psi0 := 1 / (n0 + (n1 + (n2 + n3 * tau) * tau) * tau) / tau ^ 0.5;
              Psi1 := 0.0;
              tfun := 1.0;
              for i in 1:6 loop
                if i <> 1 then
                  tfun := tfun * taum1;
                else
                end if;
                rhofun := 1.0;
                for j in 0:6 loop
                  if j <> 0 then
                    rhofun := rhofun * deltam1;
                  else
                  end if;
                  Psi1 := Psi1 + nn[i + j * 6] * tfun * rhofun;
                end for;
              end for;
              eta := etastar * Psi0 * Modelica.Math.exp(delta * Psi1);
            end visc_dTp;

            function cond_dTp  "Thermal conductivity lam(d,T,p) (industrial use version) only in one-phase region"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Density d "Density";
              input .Modelica.SIunits.Temperature T "Temperature (K)";
              input .Modelica.SIunits.Pressure p "Pressure";
              input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
              input Boolean industrialMethod = true "If true, the industrial method is used, otherwise the scientific one";
              output .Modelica.SIunits.ThermalConductivity lambda "Thermal conductivity";
            protected
              Integer region(min = 1, max = 5) "IF97 region, valid values:1,2,3, and 5";
              constant Real n0 = 1.0 "Conductivity coefficient";
              constant Real n1 = 6.978267 "Conductivity coefficient";
              constant Real n2 = 2.599096 "Conductivity coefficient";
              constant Real n3 = -0.998254 "Conductivity coefficient";
              constant Real[30] nn = array(1.3293046, 1.7018363, 5.2246158, 8.7127675, -1.8525999, -0.40452437, -2.2156845, -10.124111, -9.5000611, 0.9340469, 0.2440949, 1.6511057, 4.9874687, 4.3786606, 0.0, 0.018660751, -0.76736002, -0.27297694, -0.91783782, 0.0, -0.12961068, 0.37283344, -0.43083393, 0.0, 0.0, 0.044809953, -0.1120316, 0.13333849, 0.0, 0.0) "Conductivity coefficient";
              constant .Modelica.SIunits.ThermalConductivity lamstar = 0.4945 "Scaling conductivity";
              constant .Modelica.SIunits.Density rhostar = 317.763 "Scaling density";
              constant .Modelica.SIunits.Temperature tstar = 647.226 "Scaling temperature";
              constant .Modelica.SIunits.Pressure pstar = 22115000.0 "Scaling pressure";
              constant .Modelica.SIunits.DynamicViscosity etastar = 0.000055071 "Scaling viscosity";
              Integer i "Auxiliary variable";
              Integer j "Auxiliary variable";
              Real delta "Dimensionless density";
              Real tau "Dimensionless temperature";
              Real deltam1 "Dimensionless density";
              Real taum1 "Dimensionless temperature";
              Real Lam0 "Part of thermal conductivity";
              Real Lam1 "Part of thermal conductivity";
              Real Lam2 "Part of thermal conductivity";
              Real tfun "Auxiliary variable";
              Real rhofun "Auxiliary variable";
              Real dpitau "Auxiliary variable";
              Real ddelpi "Auxiliary variable";
              Real d2 "Auxiliary variable";
              Modelica.Media.Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
              Modelica.Media.Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
              Real Tc = T - 273.15 "Celsius temperature for region check";
              Real Chi "Symmetrized compressibility";
              constant .Modelica.SIunits.Density rhostar2 = 317.7 "Reference density";
              constant .Modelica.SIunits.Temperature Tstar2 = 647.25 "Reference temperature";
              constant .Modelica.SIunits.ThermalConductivity lambdastar = 1 "Reference thermal conductivity";
              parameter Real TREL = T / Tstar2 "Relative temperature";
              parameter Real rhoREL = d / rhostar2 "Relative density";
              Real lambdaREL "Relative thermal conductivity";
              Real deltaTREL "Relative temperature increment";
              constant Real[:] C = {0.642857, -4.11717, -6.17937, 0.00308976, 0.0822994, 10.0932};
              constant Real[:] dpar = {0.0701309, 0.011852, 0.00169937, -1.02};
              constant Real[:] b = {-0.39707, 0.400302, 1.06};
              constant Real[:] B = {-0.171587, 2.39219};
              constant Real[:] a = {0.0102811, 0.0299621, 0.0156146, -0.00422464};
              Real Q;
              Real S;
              Real lambdaREL2 "Function, part of the interpolating equation of the thermal conductivity";
              Real lambdaREL1 "Function, part of the interpolating equation of the thermal conductivity";
              Real lambdaREL0 "Function, part of the interpolating equation of the thermal conductivity";
            algorithm
              assert(d > triple.dvtriple, "IF97 medium function cond_dTp called with too low density\n" + "d = " + String(d) + " <= " + String(triple.dvtriple) + " (triple point density)");
              assert(p <= 100000000.0 and Tc >= 0.0 and Tc <= 500 or p <= 70000000.0 and Tc > 500.0 and Tc <= 650 or p <= 40000000.0 and Tc > 650.0 and Tc <= 800, "IF97 medium function cond_dTp: thermal conductivity computed outside the range\n" + "of validity of the IF97 formulation: p = " + String(p) + " Pa, Tc = " + String(Tc) + " K");
              if industrialMethod == true then
                deltaTREL := abs(TREL - 1) + C[4];
                Q := 2 + C[5] / deltaTREL ^ (3 / 5);
                if TREL >= 1 then
                  S := 1 / deltaTREL;
                else
                  S := C[6] / deltaTREL ^ (3 / 5);
                end if;
                lambdaREL2 := (dpar[1] / TREL ^ 10 + dpar[2]) * rhoREL ^ (9 / 5) * Modelica.Math.exp(C[1] * (1 - rhoREL ^ (14 / 5))) + dpar[3] * S * rhoREL ^ Q * Modelica.Math.exp(Q / (1 + Q) * (1 - rhoREL ^ (1 + Q))) + dpar[4] * Modelica.Math.exp(C[2] * TREL ^ (3 / 2) + C[3] / rhoREL ^ 5);
                lambdaREL1 := b[1] + b[2] * rhoREL + b[3] * Modelica.Math.exp(B[1] * (rhoREL + B[2]) ^ 2);
                lambdaREL0 := TREL ^ (1 / 2) * sum(a[i] * TREL ^ (i - 1) for i in 1:4);
                lambdaREL := lambdaREL0 + lambdaREL1 + lambdaREL2;
                lambda := lambdaREL * lambdastar;
              else
                if p < data.PLIMIT4A then
                  if d > data.DCRIT then
                    region := 1;
                  else
                    region := 2;
                  end if;
                else
                  assert(false, "The scientific method works only for temperature up to 623.15 K");
                end if;
                tau := tstar / T;
                delta := d / rhostar;
                deltam1 := delta - 1.0;
                taum1 := tau - 1.0;
                Lam0 := 1 / (n0 + (n1 + (n2 + n3 * tau) * tau) * tau) / tau ^ 0.5;
                Lam1 := 0.0;
                tfun := 1.0;
                for i in 1:5 loop
                  if i <> 1 then
                    tfun := tfun * taum1;
                  else
                  end if;
                  rhofun := 1.0;
                  for j in 0:5 loop
                    if j <> 0 then
                      rhofun := rhofun * deltam1;
                    else
                    end if;
                    Lam1 := Lam1 + nn[i + j * 5] * tfun * rhofun;
                  end for;
                end for;
                if region == 1 then
                  g := Basic.g1(p, T);
                  dpitau := -tstar / pstar * data.PSTAR1 * (g.gpi - data.TSTAR1 / T * g.gtaupi) / g.gpipi / T;
                  ddelpi := -pstar / rhostar * data.RH2O / data.PSTAR1 / data.PSTAR1 * T * d * d * g.gpipi;
                  Chi := delta * ddelpi;
                elseif region == 2 then
                  g := Basic.g2(p, T);
                  dpitau := -tstar / pstar * data.PSTAR2 * (g.gpi - data.TSTAR2 / T * g.gtaupi) / g.gpipi / T;
                  ddelpi := -pstar / rhostar * data.RH2O / data.PSTAR2 / data.PSTAR2 * T * d * d * g.gpipi;
                  Chi := delta * ddelpi;
                else
                  assert(false, "Thermal conductivity can only be called in the one-phase regions below 623.15 K\n" + "(p = " + String(p) + " Pa, T = " + String(T) + " K, region = " + String(region) + ")");
                end if;
                taum1 := 1 / tau - 1;
                d2 := deltam1 * deltam1;
                Lam2 := 0.0013848 * etastar / visc_dTp(d, T, p) / (tau * tau * delta * delta) * dpitau * dpitau * max(Chi, Modelica.Constants.small) ^ 0.4678 * delta ^ 0.5 * Modelica.Math.exp(-18.66 * taum1 * taum1 - d2 * d2);
                lambda := lamstar * (Lam0 * Modelica.Math.exp(delta * Lam1) + Lam2);
              end if;
            end cond_dTp;

            function surfaceTension  "Surface tension in region 4 between steam and water"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Temperature T "Temperature (K)";
              output .Modelica.SIunits.SurfaceTension sigma "Surface tension in SI units";
            protected
              Real Theta "Dimensionless temperature";
            algorithm
              Theta := min(1.0, T / data.TCRIT);
              sigma := 0.2358 * (1 - Theta) ^ 1.256 * (1 - 0.625 * (1 - Theta));
            end surfaceTension;
            annotation(Documentation(info = "<HTML><h4>Package description</h4>
                       <h4>Package contents</h4>
                       <ul>
                       <li>Function <b>visc_dTp</b> implements a function to compute the industrial formulation of the
                       dynamic viscosity of water as a function of density and temperature.
                       The details are described in the document <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/visc.pdf\">visc.pdf</a>.</li>
                       <li>Function <b>cond_dTp</b> implements a function to compute  the industrial formulation of the thermal conductivity of water as
                       a function of density, temperature and pressure. <b>Important note</b>: Obviously only two of the three
                       inputs are really needed, but using three inputs speeds up the computation and the three variables are known in most models anyways.
                       The inputs d,T and p have to be consistent.
                       The details are described in the document <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/surf.pdf\">surf.pdf</a>.</li>
                       <li>Function <b>surfaceTension</b> implements a function to compute the surface tension between vapour
                       and liquid water as a function of temperature.
                       The details are described in the document <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/thcond.pdf\">thcond.pdf</a>.</li>
                       </ul>
                       <h4>Version Info and Revision history
                       </h4>
                       <ul>
                       <li>First implemented: <i>October, 2002</i>
                       by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>
                       </li>
                       </ul>
                       <address>Authors: Hubertus Tummescheit and Jonas Eborn<br>
                   Modelon AB<br>
                   Ideon Science Park<br>
                   SE-22370 Lund, Sweden<br>
                   email: hubertus@modelon.se
                       </address>
                       <ul>
                       <li>Initial version: October 2002</li>
                       </ul>
                       </html>"));
          end Transport;

          package Isentropic  "Functions for calculating the isentropic enthalpy from pressure p and specific entropy s"
            extends Modelica.Icons.Package;

            function hofpT1  "Intermediate function for isentropic specific enthalpy in region 1"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.Temperature T "Temperature (K)";
              output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
            protected
              Real[13] o "Vector of auxiliary variables";
              Real pi1 "Dimensionless pressure";
              Real tau "Dimensionless temperature";
              Real tau1 "Dimensionless temperature";
            algorithm
              tau := data.TSTAR1 / T;
              pi1 := 7.1 - p / data.PSTAR1;
              assert(p > triple.ptriple, "IF97 medium function hofpT1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              tau1 := -1.222 + tau;
              o[1] := tau1 * tau1;
              o[2] := o[1] * tau1;
              o[3] := o[1] * o[1];
              o[4] := o[3] * o[3];
              o[5] := o[1] * o[4];
              o[6] := o[1] * o[3];
              o[7] := o[3] * tau1;
              o[8] := o[3] * o[4];
              o[9] := pi1 * pi1;
              o[10] := o[9] * o[9];
              o[11] := o[10] * o[10];
              o[12] := o[4] * o[4];
              o[13] := o[12] * o[12];
              h := data.RH2O * T * tau * (pi1 * ((-0.00254871721114236 + o[1] * (0.00424944110961118 + (0.018990068218419 + (-0.021841717175414 - 0.00015851507390979 * o[1]) * o[1]) * o[6])) / o[5] + pi1 * ((0.00141552963219801 + o[3] * (0.000047661393906987 + o[1] * (-0.0000132425535992538 - 0.000000000000012358149370591 * o[1] * o[3] * o[4]))) / o[3] + pi1 * ((0.000126718579380216 - 0.00000000511230768720618 * o[5]) / o[7] + pi1 * ((0.000011212640954 + o[2] * (0.00000130342445791202 - 0.0000000000014341729937924 * o[8])) / o[6] + pi1 * (o[9] * pi1 * ((0.0000000140077319158051 + 0.00000000104549227383804 * o[7]) / o[8] + o[10] * o[11] * pi1 * (0.000000000000000019941018075704 / (o[1] * o[12] * o[3] * o[4]) + o[9] * (-0.000000000000000000448827542684151 / o[13] + o[10] * o[9] * (pi1 * (0.000000000000000000000465957282962769 / (o[13] * o[4]) + pi1 * (0.00000000000000000000000383502057899078 * pi1 / (o[1] * o[13] * o[4]) - 0.000000000000000000000072912378325616 / (o[13] * o[4] * tau1))) - 0.00000000000000000000100075970318621 / (o[1] * o[13] * o[3] * tau1))))) + 0.00000324135974880936 / (o[4] * tau1)))))) + (-0.29265942426334 + tau1 * (0.84548187169114 + o[1] * (3.3855169168385 + tau1 * (-1.91583926775744 + tau1 * (0.47316115539684 + (-0.066465668798004 + 0.0040607314991784 * tau1) * tau1))))) / o[2]);
            end hofpT1;

            function handsofpT1  "Special function for specific enthalpy and specific entropy in region 1"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.Temperature T "Temperature (K)";
              output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
              output .Modelica.SIunits.SpecificEntropy s "Specific entropy";
            protected
              Real[28] o "Vector of auxiliary variables";
              Real pi1 "Dimensionless pressure";
              Real tau "Dimensionless temperature";
              Real tau1 "Dimensionless temperature";
              Real g "Dimensionless Gibbs energy";
              Real gtau "Derivative of dimensionless Gibbs energy w.r.t. tau";
            algorithm
              assert(p > triple.ptriple, "IF97 medium function handsofpT1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              tau := data.TSTAR1 / T;
              pi1 := 7.1 - p / data.PSTAR1;
              tau1 := -1.222 + tau;
              o[1] := tau1 * tau1;
              o[2] := o[1] * o[1];
              o[3] := o[2] * o[2];
              o[4] := o[3] * tau1;
              o[5] := 1 / o[4];
              o[6] := o[1] * o[2];
              o[7] := o[1] * tau1;
              o[8] := 1 / o[7];
              o[9] := o[1] * o[2] * o[3];
              o[10] := 1 / o[2];
              o[11] := o[2] * tau1;
              o[12] := 1 / o[11];
              o[13] := o[2] * o[3];
              o[14] := pi1 * pi1;
              o[15] := o[14] * pi1;
              o[16] := o[14] * o[14];
              o[17] := o[16] * o[16];
              o[18] := o[16] * o[17] * pi1;
              o[19] := o[14] * o[16];
              o[20] := o[3] * o[3];
              o[21] := o[20] * o[20];
              o[22] := o[21] * o[3] * tau1;
              o[23] := 1 / o[22];
              o[24] := o[21] * o[3];
              o[25] := 1 / o[24];
              o[26] := o[1] * o[2] * o[21] * tau1;
              o[27] := 1 / o[26];
              o[28] := o[1] * o[3];
              g := pi1 * (pi1 * (pi1 * (o[10] * (-0.000031679644845054 + o[2] * (-0.0000028270797985312 - 0.00000000085205128120103 * o[6])) + pi1 * (o[12] * (-0.0000022425281908 + (-0.00000065171222895601 - 0.00000000000014341729937924 * o[13]) * o[7]) + pi1 * (-0.00000040516996860117 / o[3] + o[15] * (o[18] * (o[14] * (o[19] * (0.000000000000000000000026335781662795 / (o[1] * o[2] * o[21]) + pi1 * (-0.000000000000000000000011947622640071 * o[27] + pi1 * (0.0000000000000000000000018228094581404 * o[25] - 0.000000000000000000000000093537087292458 * o[23] * pi1))) + 0.000000000000000000014478307828521 / (o[1] * o[2] * o[20] * o[3] * tau1)) - 0.00000000000000000068762131295531 / (o[2] * o[20] * o[3] * tau1)) + (-0.0000000012734301741641 - 0.00000000017424871230634 * o[11]) / (o[1] * o[3] * tau1))))) + o[8] * (-0.00047184321073267 + o[7] * (-0.00030001780793026 + (0.000047661393906987 + o[1] * (-0.0000044141845330846 - 0.00000000000000072694996297594 * o[9])) * tau1))) + o[5] * (0.00028319080123804 + o[1] * (-0.00060706301565874 + o[6] * (-0.018990068218419 + tau1 * (-0.032529748770505 + (-0.021841717175414 - 0.00005283835796993 * o[1]) * tau1))))) + (0.14632971213167 + tau1 * (-0.84548187169114 + tau1 * (-3.756360367204 + tau1 * (3.3855169168385 + tau1 * (-0.95791963387872 + tau1 * (0.15772038513228 + (-0.016616417199501 + 0.00081214629983568 * tau1) * tau1)))))) / o[1];
              gtau := pi1 * ((-0.00254871721114236 + o[1] * (0.00424944110961118 + (0.018990068218419 + (-0.021841717175414 - 0.00015851507390979 * o[1]) * o[1]) * o[6])) / o[28] + pi1 * (o[10] * (0.00141552963219801 + o[2] * (0.000047661393906987 + o[1] * (-0.0000132425535992538 - 0.000000000000012358149370591 * o[9]))) + pi1 * (o[12] * (0.000126718579380216 - 0.00000000511230768720618 * o[28]) + pi1 * ((0.000011212640954 + (0.00000130342445791202 - 0.0000000000014341729937924 * o[13]) * o[7]) / o[6] + pi1 * (0.00000324135974880936 * o[5] + o[15] * ((0.0000000140077319158051 + 0.00000000104549227383804 * o[11]) / o[13] + o[18] * (0.000000000000000019941018075704 / (o[1] * o[2] * o[20] * o[3]) + o[14] * (-0.000000000000000000448827542684151 / o[21] + o[19] * (-0.00000000000000000000100075970318621 * o[27] + pi1 * (0.000000000000000000000465957282962769 * o[25] + pi1 * (-0.000000000000000000000072912378325616 * o[23] + 0.00000000000000000000000383502057899078 * pi1 / (o[1] * o[21] * o[3])))))))))))) + o[8] * (-0.29265942426334 + tau1 * (0.84548187169114 + o[1] * (3.3855169168385 + tau1 * (-1.91583926775744 + tau1 * (0.47316115539684 + (-0.066465668798004 + 0.0040607314991784 * tau1) * tau1)))));
              h := data.RH2O * T * tau * gtau;
              s := data.RH2O * (tau * gtau - g);
            end handsofpT1;

            function hofpT2  "Intermediate function for isentropic specific enthalpy in region 2"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.Temperature T "Temperature (K)";
              output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
            protected
              Real[16] o "Vector of auxiliary variables";
              Real pi "Dimensionless pressure";
              Real tau "Dimensionless temperature";
              Real tau2 "Dimensionless temperature";
            algorithm
              assert(p > triple.ptriple, "IF97 medium function hofpT2 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              pi := p / data.PSTAR2;
              tau := data.TSTAR2 / T;
              tau2 := -0.5 + tau;
              o[1] := tau * tau;
              o[2] := o[1] * o[1];
              o[3] := tau2 * tau2;
              o[4] := o[3] * tau2;
              o[5] := o[3] * o[3];
              o[6] := o[5] * o[5];
              o[7] := o[6] * o[6];
              o[8] := o[5] * o[6] * o[7] * tau2;
              o[9] := o[3] * o[5];
              o[10] := o[5] * o[6] * tau2;
              o[11] := o[3] * o[7] * tau2;
              o[12] := o[3] * o[5] * o[6];
              o[13] := o[5] * o[6] * o[7];
              o[14] := pi * pi;
              o[15] := o[14] * o[14];
              o[16] := o[7] * o[7];
              h := data.RH2O * T * tau * ((0.0280439559151 + tau * (-0.2858109552582 + tau * (1.2213149471784 + tau * (-2.848163942888 + tau * (4.38395111945 + o[1] * (10.08665568018 + (-0.5681726521544 + 0.06380539059921 * tau) * tau)))))) / (o[1] * o[2]) + pi * (-0.017834862292358 + tau2 * (-0.09199202739273 + (-0.172743777250296 - 0.30195167236758 * o[4]) * tau2) + pi * (-0.000033032641670203 + (-0.0003789797503263 + o[3] * (-0.015757110897342 + o[4] * (-0.306581069554011 - 0.000960283724907132 * o[8]))) * tau2 + pi * (0.00000043870667284435 + o[3] * (-0.00009683303171571 + o[4] * (-0.0090203547252888 - 1.42338887469272 * o[8])) + pi * (-0.00000000078847309559367 + (0.00000002558143570457 + 0.00000144676118155521 * tau2) * tau2 + pi * (0.0000160454534363627 * o[9] + pi * ((-0.000000000050144299353183 + o[10] * (-0.033874355714168 - 836.35096769364 * o[11])) * o[3] + pi * ((-0.0000138839897890111 - 0.973671060893475 * o[12]) * o[3] * o[6] + pi * ((0.000000000090049690883672 - 296.320827232793 * o[13]) * o[3] * o[5] * tau2 + pi * (0.000000257526266427144 * o[5] * o[6] + pi * (o[4] * (0.00000000000000000041627860840696 + (-0.0000000000010234747095929 - 0.0000000140254511313154 * o[5]) * o[9]) + o[14] * o[15] * (o[13] * (-0.00000000234560435076256 + 5.3465159397045 * o[5] * o[7] * tau2) + o[14] * (-19.1874828272775 * o[16] * o[6] * o[7] + o[14] * (o[11] * (0.0000000000000000000000178371690710842 + (0.0000000000107202609066812 - 0.000201611844951398 * o[10]) * o[3] * o[5] * o[6] * tau2) + pi * (-0.00000000000000000000000124017662339842 * o[5] * o[7] + pi * (0.000200482822351322 * o[16] * o[5] * o[7] + pi * (-0.0000000000000497975748452559 * o[16] * o[3] * o[5] + o[6] * o[7] * (0.00000000000000000000000000190027787547159 + o[12] * (0.00000000000000221658861403112 - 0.0000547344301999018 * o[3] * o[7])) * pi * tau2)))))))))))))))));
            end hofpT2;

            function handsofpT2  "Function for isentropic specific enthalpy and specific entropy in region 2"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.Temperature T "Temperature (K)";
              output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
              output .Modelica.SIunits.SpecificEntropy s "Specific entropy";
            protected
              Real[22] o "Vector of auxiliary variables";
              Real pi "Dimensionless pressure";
              Real tau "Dimensionless temperature";
              Real tau2 "Dimensionless temperature";
              Real g "Dimensionless Gibbs energy";
              Real gtau "Derivative of dimensionless Gibbs energy w.r.t. tau";
            algorithm
              assert(p > triple.ptriple, "IF97 medium function handsofpT2 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              tau := data.TSTAR2 / T;
              pi := p / data.PSTAR2;
              tau2 := tau - 0.5;
              o[1] := tau2 * tau2;
              o[2] := o[1] * tau2;
              o[3] := o[1] * o[1];
              o[4] := o[3] * o[3];
              o[5] := o[4] * o[4];
              o[6] := o[3] * o[4] * o[5] * tau2;
              o[7] := o[1] * o[3] * tau2;
              o[8] := o[3] * o[4] * tau2;
              o[9] := o[1] * o[5] * tau2;
              o[10] := o[1] * o[3] * o[4];
              o[11] := o[3] * o[4] * o[5];
              o[12] := o[1] * o[3];
              o[13] := pi * pi;
              o[14] := o[13] * o[13];
              o[15] := o[13] * o[14];
              o[16] := o[3] * o[5] * tau2;
              o[17] := o[5] * o[5];
              o[18] := o[3] * o[5];
              o[19] := o[1] * o[3] * o[4] * tau2;
              o[20] := o[1] * o[5];
              o[21] := tau * tau;
              o[22] := o[21] * o[21];
              g := pi * (-0.0017731742473213 + tau2 * (-0.017834862292358 + tau2 * (-0.045996013696365 + (-0.057581259083432 - 0.05032527872793 * o[2]) * tau2)) + pi * (tau2 * (-0.000033032641670203 + (-0.00018948987516315 + o[1] * (-0.0039392777243355 + o[2] * (-0.043797295650573 - 0.000026674547914087 * o[6]))) * tau2) + pi * (0.000000020481737692309 + (0.00000043870667284435 + o[1] * (-0.00003227767723857 + o[2] * (-0.0015033924542148 - 0.040668253562649 * o[6]))) * tau2 + pi * (tau2 * (-0.00000000078847309559367 + (0.000000012790717852285 + 0.00000048225372718507 * tau2) * tau2) + pi * (0.0000022922076337661 * o[7] + pi * (o[2] * (-0.000000000016714766451061 + o[8] * (-0.0021171472321355 - 23.895741934104 * o[9])) + pi * (-0.000000000000000005905956432427 + o[1] * (-0.0000012621808899101 - 0.038946842435739 * o[10]) * o[4] * tau2 + pi * ((0.000000000011256211360459 - 8.2311340897998 * o[11]) * o[4] + pi * (0.000000019809712802088 * o[8] + pi * ((0.00000000000000000010406965210174 + o[12] * (-0.00000000000010234747095929 - 0.0000000010018179379511 * o[3])) * o[3] + o[15] * ((-0.000000000080882908646985 + 0.10693031879409 * o[16]) * o[6] + o[13] * (-0.33662250574171 * o[17] * o[4] * o[5] * tau2 + o[13] * (o[18] * (0.00000000000000000000000089185845355421 + o[19] * (0.00000000000030629316876232 - 0.0000042002467698208 * o[8])) + pi * (-0.000000000000000000000000059056029685639 * o[16] + pi * (0.0000037826947613457 * o[17] * o[3] * o[5] * tau2 + pi * (o[1] * (0.000000000000000000000000000073087610595061 + o[10] * (0.000000000000000055414715350778 - 0.0000009436970724121 * o[20])) * o[4] * o[5] * pi - 0.0000000000000012768608934681 * o[1] * o[17] * o[3] * tau2)))))))))))))))) + (-0.00560879118302 + tau * (0.07145273881455 + tau * (-0.4071049823928 + tau * (1.424081971444 + tau * (-4.38395111945 + tau * (-9.692768600217 + tau * (10.08665568018 + (-0.2840863260772 + 0.02126846353307 * tau) * tau) + Modelica.Math.log(pi))))))) / (o[22] * tau);
              gtau := (0.0280439559151 + tau * (-0.2858109552582 + tau * (1.2213149471784 + tau * (-2.848163942888 + tau * (4.38395111945 + o[21] * (10.08665568018 + (-0.5681726521544 + 0.06380539059921 * tau) * tau)))))) / (o[21] * o[22]) + pi * (-0.017834862292358 + tau2 * (-0.09199202739273 + (-0.172743777250296 - 0.30195167236758 * o[2]) * tau2) + pi * (-0.000033032641670203 + (-0.0003789797503263 + o[1] * (-0.015757110897342 + o[2] * (-0.306581069554011 - 0.000960283724907132 * o[6]))) * tau2 + pi * (0.00000043870667284435 + o[1] * (-0.00009683303171571 + o[2] * (-0.0090203547252888 - 1.42338887469272 * o[6])) + pi * (-0.00000000078847309559367 + (0.00000002558143570457 + 0.00000144676118155521 * tau2) * tau2 + pi * (0.0000160454534363627 * o[12] + pi * (o[1] * (-0.000000000050144299353183 + o[8] * (-0.033874355714168 - 836.35096769364 * o[9])) + pi * (o[1] * (-0.0000138839897890111 - 0.973671060893475 * o[10]) * o[4] + pi * ((0.000000000090049690883672 - 296.320827232793 * o[11]) * o[7] + pi * (0.000000257526266427144 * o[3] * o[4] + pi * (o[2] * (0.00000000000000000041627860840696 + o[12] * (-0.0000000000010234747095929 - 0.0000000140254511313154 * o[3])) + o[15] * (o[11] * (-0.00000000234560435076256 + 5.3465159397045 * o[16]) + o[13] * (-19.1874828272775 * o[17] * o[4] * o[5] + o[13] * ((0.0000000000000000000000178371690710842 + o[19] * (0.0000000000107202609066812 - 0.000201611844951398 * o[8])) * o[9] + pi * (-0.00000000000000000000000124017662339842 * o[18] + pi * (0.000200482822351322 * o[17] * o[3] * o[5] + pi * (-0.0000000000000497975748452559 * o[1] * o[17] * o[3] + (0.00000000000000000000000000190027787547159 + o[10] * (0.00000000000000221658861403112 - 0.0000547344301999018 * o[20])) * o[4] * o[5] * pi * tau2))))))))))))))));
              h := data.RH2O * T * tau * gtau;
              s := data.RH2O * (tau * gtau - g);
            end handsofpT2;
            annotation(Documentation(info = "<HTML><h4>Package description</h4>
                       <h4>Package contents</h4>
                       <ul>
                       <li>Function <b>hofpT1</b> computes h(p,T) in region 1.</li>
                       <li>Function <b>handsofpT1</b> computes (s,h)=f(p,T) in region 1, needed for two-phase properties.</li>
                       <li>Function <b>hofps1</b> computes h(p,s) in region 1.</li>
                       <li>Function <b>hofpT2</b> computes h(p,T) in region 2.</li>
                       <li>Function <b>handsofpT2</b> computes (s,h)=f(p,T) in region 2, needed for two-phase properties.</li>
                       <li>Function <b>hofps2</b> computes h(p,s) in region 2.</li>
                       <li>Function <b>hofdT3</b> computes h(d,T) in region 3.</li>
                       <li>Function <b>hofpsdt3</b> computes h(p,s,dguess,Tguess) in region 3, where dguess and Tguess are initial guess
                       values for the density and temperature consistent with p and s.</li>
                       <li>Function <b>hofps4</b> computes h(p,s) in region 4.</li>
                       <li>Function <b>hofpT5</b> computes h(p,T) in region 5.</li>
                       <li>Function <b>water_hisentropic</b> computes h(p,s,phase) in all regions.
                       The phase input is needed due to discontinuous derivatives at the phase boundary.</li>
                       <li>Function <b>water_hisentropic_dyn</b> computes h(p,s,dguess,Tguess,phase) in all regions.
                       The phase input is needed due to discontinuous derivatives at the phase boundary. Tguess and dguess are initial guess
                       values for the density and temperature consistent with p and s. This function should be preferred in
                       dynamic simulations where good guesses are often available.</li>
                       </ul>
                       <h4>Version Info and Revision history
                       </h4>
                       <ul>
                       <li>First implemented: <i>July, 2000</i>
                       by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>
                       </li>
                       </ul>
                       <address>Author: Hubertus Tummescheit, <br>
                   Modelon AB<br>
                   Ideon Science Park<br>
                   SE-22370 Lund, Sweden<br>
                   email: hubertus@modelon.se
                       </address>
                       <ul>
                       <li>Initial version: July 2000</li>
                       <li>Documentation added: December 2002</li>
                       </ul>
                       </html>"));
          end Isentropic;

          package Inverses  "Efficient inverses for selected pairs of variables"
            extends Modelica.Icons.Package;

            function fixdT  "Region limits for inverse iteration in region 3"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Density din "Density";
              input .Modelica.SIunits.Temperature Tin "Temperature";
              output .Modelica.SIunits.Density dout "Density";
              output .Modelica.SIunits.Temperature Tout "Temperature";
            protected
              .Modelica.SIunits.Temperature Tmin "Approximation of minimum temperature";
              .Modelica.SIunits.Temperature Tmax "Approximation of maximum temperature";
            algorithm
              if din > 765.0 then
                dout := 765.0;
              elseif din < 110.0 then
                dout := 110.0;
              else
                dout := din;
              end if;
              if dout < 390.0 then
                Tmax := 554.3557377 + dout * 0.809344262;
              else
                Tmax := 1116.85 - dout * 0.632948717;
              end if;
              if dout < data.DCRIT then
                Tmin := data.TCRIT * (1.0 - (dout - data.DCRIT) * (dout - data.DCRIT) / 1000000.0);
              else
                Tmin := data.TCRIT * (1.0 - (dout - data.DCRIT) * (dout - data.DCRIT) / 1440000.0);
              end if;
              if Tin < Tmin then
                Tout := Tmin;
              elseif Tin > Tmax then
                Tout := Tmax;
              else
                Tout := Tin;
              end if;
            end fixdT;

            function dofp13  "Density at the boundary between regions 1 and 3"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.Density d "Density";
            protected
              Real p2 "Auxiliary variable";
              Real[3] o "Vector of auxiliary variables";
            algorithm
              p2 := 7.1 - 0.0000000604960677555959 * p;
              o[1] := p2 * p2;
              o[2] := o[1] * o[1];
              o[3] := o[2] * o[2];
              d := 57.4756752485113 / (0.0737412153522555 + p2 * (0.00145092247736023 + p2 * (0.000102697173772229 + p2 * (0.0000114683182476084 + p2 * (0.00000199080616601101 + o[1] * p2 * (0.0000000113217858826367 + o[2] * o[3] * p2 * (0.0000000000000000135549330686006 + o[1] * (-0.000000000000000000311228834832975 + o[1] * o[2] * (-0.000000000000000000000702987180039442 + p2 * (0.000000000000000000000329199117056433 + (-0.0000000000000000000000517859076694812 + 0.00000000000000000000000273712834080283 * p2) * p2))))))))));
            end dofp13;

            function dofp23  "Density at the boundary between regions 2 and 3"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              output .Modelica.SIunits.Density d "Density";
            protected
              .Modelica.SIunits.Temperature T;
              Real[13] o "Vector of auxiliary variables";
              Real taug "Auxiliary variable";
              Real pi "Dimensionless pressure";
              Real gpi23 "Derivative of g w.r.t. pi on the boundary between regions 2 and 3";
            algorithm
              pi := p / data.PSTAR2;
              T := 572.54459862746 + 31.3220101646784 * (-13.91883977887 + pi) ^ 0.5;
              o[1] := (-13.91883977887 + pi) ^ 0.5;
              taug := -0.5 + 540.0 / (572.54459862746 + 31.3220101646784 * o[1]);
              o[2] := taug * taug;
              o[3] := o[2] * taug;
              o[4] := o[2] * o[2];
              o[5] := o[4] * o[4];
              o[6] := o[5] * o[5];
              o[7] := o[4] * o[5] * o[6] * taug;
              o[8] := o[4] * o[5] * taug;
              o[9] := o[2] * o[4] * o[5];
              o[10] := pi * pi;
              o[11] := o[10] * o[10];
              o[12] := o[4] * o[6] * taug;
              o[13] := o[6] * o[6];
              gpi23 := (1.0 + pi * (-0.0017731742473213 + taug * (-0.017834862292358 + taug * (-0.045996013696365 + (-0.057581259083432 - 0.05032527872793 * o[3]) * taug)) + pi * (taug * (-0.000066065283340406 + (-0.0003789797503263 + o[2] * (-0.007878555448671 + o[3] * (-0.087594591301146 - 0.000053349095828174 * o[7]))) * taug) + pi * (0.000000061445213076927 + (0.00000131612001853305 + o[2] * (-0.00009683303171571 + o[3] * (-0.0045101773626444 - 0.122004760687947 * o[7]))) * taug + pi * (taug * (-0.00000000315389238237468 + (0.00000005116287140914 + 0.00000192901490874028 * taug) * taug) + pi * (0.0000114610381688305 * o[2] * o[4] * taug + pi * (o[3] * (-0.000000000100288598706366 + o[8] * (-0.012702883392813 - 143.374451604624 * o[2] * o[6] * taug)) + pi * (-0.000000000000000041341695026989 + o[2] * o[5] * (-0.0000088352662293707 - 0.272627897050173 * o[9]) * taug + pi * (o[5] * (0.000000000090049690883672 - 65.8490727183984 * o[4] * o[5] * o[6]) + pi * (0.000000178287415218792 * o[8] + pi * (o[4] * (0.0000000000000000010406965210174 + o[2] * (-0.0000000000010234747095929 - 0.000000010018179379511 * o[4]) * o[4]) + o[10] * o[11] * ((-0.00000000129412653835176 + 1.71088510070544 * o[12]) * o[7] + o[10] * (-6.05920510335078 * o[13] * o[5] * o[6] * taug + o[10] * (o[4] * o[6] * (0.0000000000000000000000178371690710842 + o[2] * o[4] * o[5] * (0.0000000000061258633752464 - 0.000084004935396416 * o[8]) * taug) + pi * (-0.00000000000000000000000124017662339842 * o[12] + pi * (0.0000832192847496054 * o[13] * o[4] * o[6] * taug + pi * (o[2] * o[5] * o[6] * (0.00000000000000000000000000175410265428146 + (0.00000000000000132995316841867 - 0.0000226487297378904 * o[2] * o[6]) * o[9]) * pi - 0.0000000000000293678005497663 * o[13] * o[2] * o[4] * taug))))))))))))))))) / pi;
              d := p / (data.RH2O * T * pi * gpi23);
            end dofp23;

            function dofpt3  "Inverse iteration in region 3: (d) = f(p,T)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.Temperature T "Temperature (K)";
              input .Modelica.SIunits.Pressure delp "Iteration converged if (p-pre(p) < delp)";
              output .Modelica.SIunits.Density d "Density";
              output Integer error = 0 "Error flag: iteration failed if different from 0";
            protected
              .Modelica.SIunits.Density dguess "Guess density";
              Integer i = 0 "Loop counter";
              Real dp "Pressure difference";
              .Modelica.SIunits.Density deld "Density step";
              Modelica.Media.Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
              Modelica.Media.Common.NewtonDerivatives_pT nDerivs "Derivatives needed in Newton iteration";
              Boolean found = false "Flag for iteration success";
              Boolean supercritical "Flag, true for supercritical states";
              Boolean liquid "Flag, true for liquid states";
              .Modelica.SIunits.Density dmin "Lower density limit";
              .Modelica.SIunits.Density dmax "Upper density limit";
              .Modelica.SIunits.Temperature Tmax "Maximum temperature";
              Real damping "Damping factor";
            algorithm
              found := false;
              assert(p >= data.PLIMIT4A, "BaseIF97.dofpt3: function called outside of region 3! p too low\n" + "p = " + String(p) + " Pa < " + String(data.PLIMIT4A) + " Pa");
              assert(T >= data.TLIMIT1, "BaseIF97.dofpt3: function called outside of region 3! T too low\n" + "T = " + String(T) + " K < " + String(data.TLIMIT1) + " K");
              assert(p >= Regions.boundary23ofT(T), "BaseIF97.dofpt3: function called outside of region 3! T too high\n" + "p = " + String(p) + " Pa, T = " + String(T) + " K");
              supercritical := p > data.PCRIT;
              damping := if supercritical then 1.0 else 1.0;
              Tmax := Regions.boundary23ofp(p);
              if supercritical then
                dmax := dofp13(p);
                dmin := dofp23(p);
                dguess := dmax - (T - data.TLIMIT1) / (data.TLIMIT1 - Tmax) * (dmax - dmin);
              else
                liquid := T < Basic.tsat(p);
                if liquid then
                  dmax := dofp13(p);
                  dmin := Regions.rhol_p_R4b(p);
                  dguess := 1.1 * Regions.rhol_T(T) "Guess: 10 percent more than on the phase boundary for same T";
                else
                  dmax := Regions.rhov_p_R4b(p);
                  dmin := dofp23(p);
                  dguess := 0.9 * Regions.rhov_T(T) "Guess: 10% less than on the phase boundary for same T";
                end if;
              end if;
              while i < IterationData.IMAX and not found loop
                d := dguess;
                f := Basic.f3(d, T);
                nDerivs := Modelica.Media.Common.Helmholtz_pT(f);
                dp := nDerivs.p - p;
                if abs(dp / p) <= delp then
                  found := true;
                else
                end if;
                deld := dp / nDerivs.pd * damping;
                d := d - deld;
                if d > dmin and d < dmax then
                  dguess := d;
                else
                  if d > dmax then
                    dguess := dmax - sqrt(Modelica.Constants.eps);
                  else
                    dguess := dmin + sqrt(Modelica.Constants.eps);
                  end if;
                end if;
                i := i + 1;
              end while;
              if not found then
                error := 1;
              else
              end if;
              assert(error <> 1, "Error in inverse function dofpt3: iteration failed");
            end dofpt3;

            function dtofph3  "Inverse iteration in region 3: (d,T) = f(p,h)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
              input .Modelica.SIunits.Pressure delp "Iteration accuracy";
              input .Modelica.SIunits.SpecificEnthalpy delh "Iteration accuracy";
              output .Modelica.SIunits.Density d "Density";
              output .Modelica.SIunits.Temperature T "Temperature (K)";
              output Integer error "Error flag: iteration failed if different from 0";
            protected
              .Modelica.SIunits.Temperature Tguess "Initial temperature";
              .Modelica.SIunits.Density dguess "Initial density";
              Integer i "Iteration counter";
              Real dh "Newton-error in h-direction";
              Real dp "Newton-error in p-direction";
              Real det "Determinant of directional derivatives";
              Real deld "Newton-step in d-direction";
              Real delt "Newton-step in T-direction";
              Modelica.Media.Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
              Modelica.Media.Common.NewtonDerivatives_ph nDerivs "Derivatives needed in Newton iteration";
              Boolean found = false "Flag for iteration success";
              Integer subregion "1 for subregion 3a, 2 for subregion 3b";
            algorithm
              if p < data.PCRIT then
                subregion := if h < Regions.hl_p(p) + 10.0 then 1 else if h > Regions.hv_p(p) - 10.0 then 2 else 0;
                assert(subregion <> 0, "Inverse iteration of dt from ph called in 2 phase region: this can not work");
              else
                subregion := if h < Basic.h3ab_p(p) then 1 else 2;
              end if;
              T := if subregion == 1 then Basic.T3a_ph(p, h) else Basic.T3b_ph(p, h);
              d := if subregion == 1 then 1 / Basic.v3a_ph(p, h) else 1 / Basic.v3b_ph(p, h);
              i := 0;
              error := 0;
              while i < IterationData.IMAX and not found loop
                f := Basic.f3(d, T);
                nDerivs := Modelica.Media.Common.Helmholtz_ph(f);
                dh := nDerivs.h - h;
                dp := nDerivs.p - p;
                if abs(dh / h) <= delh and abs(dp / p) <= delp then
                  found := true;
                else
                end if;
                det := nDerivs.ht * nDerivs.pd - nDerivs.pt * nDerivs.hd;
                delt := (nDerivs.pd * dh - nDerivs.hd * dp) / det;
                deld := (nDerivs.ht * dp - nDerivs.pt * dh) / det;
                T := T - delt;
                d := d - deld;
                dguess := d;
                Tguess := T;
                i := i + 1;
                (d, T) := fixdT(dguess, Tguess);
              end while;
              if not found then
                error := 1;
              else
              end if;
              assert(error <> 1, "Error in inverse function dtofph3: iteration failed");
            end dtofph3;

            function dtofps3  "Inverse iteration in region 3: (d,T) = f(p,s)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.SpecificEntropy s "Specific entropy";
              input .Modelica.SIunits.Pressure delp "Iteration accuracy";
              input .Modelica.SIunits.SpecificEntropy dels "Iteration accuracy";
              output .Modelica.SIunits.Density d "Density";
              output .Modelica.SIunits.Temperature T "Temperature (K)";
              output Integer error "Error flag: iteration failed if different from 0";
            protected
              .Modelica.SIunits.Temperature Tguess "Initial temperature";
              .Modelica.SIunits.Density dguess "Initial density";
              Integer i "Iteration counter";
              Real ds "Newton-error in s-direction";
              Real dp "Newton-error in p-direction";
              Real det "Determinant of directional derivatives";
              Real deld "Newton-step in d-direction";
              Real delt "Newton-step in T-direction";
              Modelica.Media.Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
              Modelica.Media.Common.NewtonDerivatives_ps nDerivs "Derivatives needed in Newton iteration";
              Boolean found "Flag for iteration success";
              Integer subregion "1 for subregion 3a, 2 for subregion 3b";
            algorithm
              i := 0;
              error := 0;
              found := false;
              if p < data.PCRIT then
                subregion := if s < Regions.sl_p(p) + 10.0 then 1 else if s > Regions.sv_p(p) - 10.0 then 2 else 0;
                assert(subregion <> 0, "Inverse iteration of dt from ps called in 2 phase region: this is illegal!");
              else
                subregion := if s < data.SCRIT then 1 else 2;
              end if;
              T := if subregion == 1 then Basic.T3a_ps(p, s) else Basic.T3b_ps(p, s);
              d := if subregion == 1 then 1 / Basic.v3a_ps(p, s) else 1 / Basic.v3b_ps(p, s);
              while i < IterationData.IMAX and not found loop
                f := Basic.f3(d, T);
                nDerivs := Modelica.Media.Common.Helmholtz_ps(f);
                ds := nDerivs.s - s;
                dp := nDerivs.p - p;
                if abs(ds / s) <= dels and abs(dp / p) <= delp then
                  found := true;
                else
                end if;
                det := nDerivs.st * nDerivs.pd - nDerivs.pt * nDerivs.sd;
                delt := (nDerivs.pd * ds - nDerivs.sd * dp) / det;
                deld := (nDerivs.st * dp - nDerivs.pt * ds) / det;
                T := T - delt;
                d := d - deld;
                dguess := d;
                Tguess := T;
                i := i + 1;
                (d, T) := fixdT(dguess, Tguess);
              end while;
              if not found then
                error := 1;
              else
              end if;
              assert(error <> 1, "Error in inverse function dtofps3: iteration failed");
            end dtofps3;

            function pofdt125  "Inverse iteration in region 1,2 and 5: p = g(d,T)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Density d "Density";
              input .Modelica.SIunits.Temperature T "Temperature (K)";
              input .Modelica.SIunits.Pressure reldd "Relative iteration accuracy of density";
              input Integer region "Region in IAPWS/IF97 in which inverse should be calculated";
              output .Modelica.SIunits.Pressure p "Pressure";
              output Integer error "Error flag: iteration failed if different from 0";
            protected
              Integer i "Counter for while-loop";
              Modelica.Media.Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
              Boolean found "Flag if iteration has been successful";
              Real dd "Difference between density for guessed p and the current density";
              Real delp "Step in p in Newton-iteration";
              Real relerr "Relative error in d";
              .Modelica.SIunits.Pressure pguess1 = 1000000.0 "Initial pressure guess in region 1";
              .Modelica.SIunits.Pressure pguess2 "Initial pressure guess in region 2";
              constant .Modelica.SIunits.Pressure pguess5 = 500000.0 "Initial pressure guess in region 5";
            algorithm
              i := 0;
              error := 0;
              pguess2 := 42800 * d;
              found := false;
              if region == 1 then
                p := pguess1;
              elseif region == 2 then
                p := pguess2;
              else
                p := pguess5;
              end if;
              while i < IterationData.IMAX and not found loop
                if region == 1 then
                  g := Basic.g1(p, T);
                elseif region == 2 then
                  g := Basic.g2(p, T);
                else
                  g := Basic.g5(p, T);
                end if;
                dd := p / (data.RH2O * T * g.pi * g.gpi) - d;
                relerr := dd / d;
                if abs(relerr) < reldd then
                  found := true;
                else
                end if;
                delp := dd * (-p * p / (d * d * data.RH2O * T * g.pi * g.pi * g.gpipi));
                p := p - delp;
                i := i + 1;
                if not found then
                  if p < triple.ptriple then
                    p := 2.0 * triple.ptriple;
                  else
                  end if;
                  if p > data.PLIMIT1 then
                    p := 0.95 * data.PLIMIT1;
                  else
                  end if;
                else
                end if;
              end while;
              if not found then
                error := 1;
              else
              end if;
              assert(error <> 1, "Error in inverse function pofdt125: iteration failed");
            end pofdt125;

            function tofph5  "Inverse iteration in region 5: (p,T) = f(p,h)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
              input .Modelica.SIunits.SpecificEnthalpy reldh "Iteration accuracy";
              output .Modelica.SIunits.Temperature T "Temperature (K)";
              output Integer error "Error flag: iteration failed if different from 0";
            protected
              Modelica.Media.Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
              .Modelica.SIunits.SpecificEnthalpy proh "H for current guess in T";
              constant .Modelica.SIunits.Temperature Tguess = 1500 "Initial temperature";
              Integer i "Iteration counter";
              Real relerr "Relative error in h";
              Real dh "Newton-error in h-direction";
              Real dT "Newton-step in T-direction";
              Boolean found "Flag for iteration success";
            algorithm
              i := 0;
              error := 0;
              T := Tguess;
              found := false;
              while i < IterationData.IMAX and not found loop
                g := Basic.g5(p, T);
                proh := data.RH2O * T * g.tau * g.gtau;
                dh := proh - h;
                relerr := dh / h;
                if abs(relerr) < reldh then
                  found := true;
                else
                end if;
                dT := dh / (-data.RH2O * g.tau * g.tau * g.gtautau);
                T := T - dT;
                i := i + 1;
              end while;
              if not found then
                error := 1;
              else
              end if;
              assert(error <> 1, "Error in inverse function tofph5: iteration failed");
            end tofph5;

            function tofps5  "Inverse iteration in region 5: (p,T) = f(p,s)"
              extends Modelica.Icons.Function;
              input .Modelica.SIunits.Pressure p "Pressure";
              input .Modelica.SIunits.SpecificEntropy s "Specific entropy";
              input .Modelica.SIunits.SpecificEnthalpy relds "Iteration accuracy";
              output .Modelica.SIunits.Temperature T "Temperature (K)";
              output Integer error "Error flag: iteration failed if different from 0";
            protected
              Modelica.Media.Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
              .Modelica.SIunits.SpecificEntropy pros "S for current guess in T";
              parameter .Modelica.SIunits.Temperature Tguess = 1500 "Initial temperature";
              Integer i "Iteration counter";
              Real relerr "Relative error in s";
              Real ds "Newton-error in s-direction";
              Real dT "Newton-step in T-direction";
              Boolean found "Flag for iteration success";
            algorithm
              i := 0;
              error := 0;
              T := Tguess;
              found := false;
              while i < IterationData.IMAX and not found loop
                g := Basic.g5(p, T);
                pros := data.RH2O * (g.tau * g.gtau - g.g);
                ds := pros - s;
                relerr := ds / s;
                if abs(relerr) < relds then
                  found := true;
                else
                end if;
                dT := ds * T / (-data.RH2O * g.tau * g.tau * g.gtautau);
                T := T - dT;
                i := i + 1;
              end while;
              if not found then
                error := 1;
              else
              end if;
              assert(error <> 1, "Error in inverse function tofps5: iteration failed");
            end tofps5;
            annotation(Documentation(info = "<HTML><h4>Package description</h4>
                       <h4>Package contents</h4>
                       <ul>
                       <li>Function <b>fixdT</b> constrains density and temperature to allowed region</li>
                       <li>Function <b>dofp13</b> computes d as a function of p at boundary between regions 1 and 3</li>
                       <li>Function <b>dofp23</b> computes d as a function of p at boundary between regions 2 and 3</li>
                       <li>Function <b>dofpt3</b> iteration to compute d as a function of p and T in region 3</li>
                       <li>Function <b>dtofph3</b> iteration to compute d and T as a function of p and h in region 3</li>
                       <li>Function <b>dtofps3</b> iteration to compute d and T as a function of p and s in region 3</li>
                       <li>Function <b>dtofpsdt3</b> iteration to compute d and T as a function of p and s in region 3,
                       with initial guesses</li>
                       <li>Function <b>pofdt125</b> iteration to compute p as a function of p and T in regions 1, 2 and 5</li>
                       <li>Function <b>tofph5</b> iteration to compute T as a function of p and h in region 5</li>
                       <li>Function <b>tofps5</b> iteration to compute T as a function of p and s in region 5</li>
                       <li>Function <b>tofpst5</b> iteration to compute T as a function of p and s in region 5, with initial guess in T</li>
                       </ul>
                       <h4>Version Info and Revision history
                       </h4>
                       <ul>
                       <li>First implemented: <i>July, 2000</i>
                       by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>
                       </li>
                       </ul>
                       <address>Author: Hubertus Tummescheit, <br>
                   Modelon AB<br>
                   Ideon Science Park<br>
                   SE-22370 Lund, Sweden<br>
                   email: hubertus@modelon.se
                       </address>
                       <ul>
                       <li>Initial version: July 2000</li>
                       <li>Documentation added: December 2002</li>
                       </ul>
                       </html>"));
          end Inverses;
          annotation(Documentation(info = "<HTML>
           <style type=\"text/css\">
           .nobr
           {
           white-space:nowrap;
           }
           </style>
               <h4>Version Info and Revision history</h4>
                   <ul>
                   <li>First implemented: <i>July, 2000</i>
                   by Hubertus Tummescheit
                   for the ThermoFluid Library with help from Jonas Eborn and Falko Jens Wagner
                   </li>
                 <li>Code reorganization, enhanced documentation, additional functions:   <i>December, 2002</i>
                 by <a href=\"mailto:Hubertus.Tummescheit@modelon.se\">Hubertus Tummescheit</a> and moved to Modelica
                 properties library.</li>
                   </ul>
                 <address>Author: Hubertus Tummescheit, <br>
                 Modelon AB<br>
                 Ideon Science Park<br>
                 SE-22370 Lund, Sweden<br>
                 email: hubertus@modelon.se
                 </address>
                   <p>In September 1997, the International Association for the Properties
                   of Water and Steam (<A HREF=\"http://www.iapws.org\">IAPWS</A>) adopted a
                   new formulation for the thermodynamic properties of water and steam for
                   industrial use. This new industrial standard is called \"IAPWS Industrial
                   Formulation for the Thermodynamic Properties of Water and Steam\" (IAPWS-IF97).
                   The formulation IAPWS-IF97 replaces the previous industrial standard IFC-67.
                   <p>Based on this new formulation, a new steam table, titled \"<a href=\"http://www.springer.de/cgi-bin/search_book.pl?isbn=3-540-64339-7\">Properties of Water and Steam</a>\" by W. Wagner and A. Kruse, was published by
                   the Springer-Verlag, Berlin - New-York - Tokyo in April 1998. This
                   steam table, ref. <a href=\"#steamprop\">[1]</a> is bilingual (English /
                   German) and contains a complete description of the equations of
                   IAPWS-IF97. This reference is the authoritative source of information
                   for this implementation. A mostly identical version has been published by the International
                   Association for the Properties
                   of Water and Steam (<A HREF=\"http://www.iapws.org\">IAPWS</A>) with permission granted to re-publish the
                   information if credit is given to IAPWS. This document is distributed with this library as
                   <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/IF97.pdf\">IF97.pdf</a>.
                   In addition, the equations published by <A HREF=\"http://www.iapws.org\">IAPWS</A> for
                   the transport properties dynamic viscosity (standards document: <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/visc.pdf\">visc.pdf</a>)
                   and thermal conductivity (standards document: <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/thcond.pdf\">thcond.pdf</a>)
                   and equations for the surface tension (standards document: <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/surf.pdf\">surf.pdf</a>)
                   are also implemented in this library and included for reference.</p>
                   <p>
                   The functions in BaseIF97.mo are low level functions which should
                   only be used in those exceptions when the standard user level
                   functions in Water.mo do not contain the wanted properties.
                </p>
           <p>Based on IAPWS-IF97, Modelica functions are available for calculating
           the most common thermophysical properties (thermodynamic and transport
           properties). The implementation requires part of the common medium
           property infrastructure of the Modelica.Thermal.Properties library in the file
           Common.mo. There are a few extensions from the version of IF97 as
           documented in <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/IF97.pdf\">IF97.pdf</a> in order to improve performance for
           dynamic simulations. Input variables for calculating the properties are
           only implemented for a limited number of variable pairs which make sense as dynamic states: (p,h), (p,T), (p,s) and (d,T).
           </p>
           <hr size=3 width=\"70%\">
           <h4><a name=\"regions\">1. Structure and Regions of IAPWS-IF97</a></h4>
           <p>The IAPWS Industrial Formulation 1997 consists of
           a set of equations for different regions which cover the following range
           of validity:</p>
           <table border=0 cellpadding=4>
           <tr>
           <td valign=\"top\">273,15 K &lt; <em>T</em> &lt; 1073,15 K</td>
           <td valign=\"top\"><em>p</em> &lt; 100 MPa</td>
           </tr>
           <tr>
           <td valign=\"top\">1073,15 K &lt; <em>T</em> &lt; 2273,15 K</td>
           <td valign=\"top\"><em>p</em> &lt; 10 MPa</td>
           </tr>
           </table>
           <p>
           Figure 1 shows the 5 regions into which the entire range of validity of
           IAPWS-IF97 is divided. The boundaries of the regions can be directly taken
           from Fig. 1 except for the boundary between regions 2 and 3; this boundary,
           which corresponds approximately to the isentropic line <span class=\"nobr\"><em>s</em> = 5.047 kJ kg
           <sup>-1</sup>K<sup>-1</sup></span>, is defined
           by a corresponding auxiliary equation. Both regions 1 and 2 are individually
           covered by a fundamental equation for the specific Gibbs free energy <span class=\"nobr\"><em>g</em>( <em>p</em>,<em>T</em> )</span>, region 3 by a fundamental equation for the specific Helmholtz
           free energy <span class=\"nobr\"><em>f </em>(<em> <font face=\"symbol\">r</font></em>,<em>T
           </em>)</span>, and the saturation curve, corresponding to region 4, by a saturation-pressure
           equation <span><em>p</em><sub>s</sub>( <em>T</em> )</span>. The high-temperature
           region 5 is also covered by a <span class=\"nobr\"><em>g</em>( <em>p</em>,<em>T</em> )</span> equation. These
           5 equations, shown in rectangular boxes in Fig. 1, form the so-called <em>basic
           equations</em>.
           </p>
           <table border=\"0\" cellspacing=\"0\" cellpadding=\"2\">
             <caption align=\"bottom\">Figure 1: Regions and equations of IAPWS-IF97</caption>
             <tr>
               <td>
               <img src=\"modelica://Modelica/Resources/Images/Media/Water/if97.png\" alt=\"Regions and equations of IAPWS-IF97\">
               </td>
             </tr>
           </table>
           <p>
           In addition to these basic equations, so-called <em>backward
           equations</em> are provided for regions 1, 2, and 4 in form of
           <span class=\"nobr\"><em>T</em>( <em>p</em>,<em>h</em> )</span> and <span class=\"nobr\"><em>T</em>( <em>
           p</em>,<em>s</em> )</span> for regions 1 and 2, and <span class=\"nobr\"><em>T</em><sub>s</sub>( <em>p</em> )</span> for region 4. These
           backward equations, marked in grey in Fig. 1, were developed in such a
           way that they are numerically very consistent with the corresponding
           basic equation. Thus, properties as functions of&nbsp; <em>p</em>,<em>h
           </em>and of&nbsp;<em> p</em>,<em>s </em>for regions 1 and 2, and of
           <em>p</em> for region 4 can be calculated without any iteration. As a
           result of this special concept for the development of the new
           industrial standard IAPWS-IF97, the most important properties can be
           calculated extremely quickly. All Modelica functions are optimized
           with regard to short computing times.
           </p>
           <p>
           The complete description of the individual equations of the new industrial
           formulation IAPWS-IF97 is given in <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/IF97.pdf\">IF97.pdf</a>. Comprehensive information on
           IAPWS-IF97 (requirements, concept, accuracy, consistency along region boundaries,
           and the increase of computing speed in comparison with IFC-67, etc.) can
           be taken from <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/IF97.pdf\">IF97.pdf</a> or [2].
           </p>
           <p>
           <a name=\"steamprop\">[1]<em>Wagner, W., Kruse, A.</em> Properties of Water
           and Steam / Zustandsgr&ouml;&szlig;en von Wasser und Wasserdampf / IAPWS-IF97.
           Springer-Verlag, Berlin, 1998.</a>
           </p>
           <p>
           [2] <em>Wagner, W., Cooper, J. R., Dittmann, A., Kijima,
           J., Kretzschmar, H.-J., Kruse, A., Mare&#353; R., Oguchi, K., Sato, H., St&ouml;cker,
           I., &#352;ifner, O., Takaishi, Y., Tanishita, I., Tr&uuml;benbach, J., and Willkommen,
           Th.</em> The IAPWS Industrial Formulation 1997 for the Thermodynamic Properties
           of Water and Steam. ASME Journal of Engineering for Gas Turbines and Power 122 (2000), 150 - 182.
           </p>
           <HR size=3 width=\"90%\">
           <h4>2. Calculable Properties      </h4>
           <table border=\"1\" cellpadding=\"2\" cellspacing=\"0\">
                  <tbody>
                  <tr>
                  <td valign=\"top\" bgcolor=\"#cccccc\"><br>
                 </td>
                 <td valign=\"top\" bgcolor=\"#cccccc\"><b>Common name</b><br>
                  </td>
                  <td valign=\"top\" bgcolor=\"#cccccc\"><b>Abbreviation </b><br>
                  </td>
                  <td valign=\"top\" bgcolor=\"#cccccc\"><b>Unit</b><br>
                  </td>
                  </tr>
                  <tr>
                  <td valign=\"top\">&nbsp;1<br>
                 </td>
                 <td valign=\"top\">Pressure</td>
                  <td valign=\"top\">p<br>
                   </td>
                  <td valign=\"top\">Pa<br>
                  </td>
                  </tr>
                  <tr>
                  <td valign=\"top\">&nbsp;2<br>
                 </td>
                 <td valign=\"top\">Temperature</td>
                  <td valign=\"top\">T<br>
                  </td>
                  <td valign=\"top\">K<br>
                  </td>
                  </tr>
                  <tr>
                  <td valign=\"top\">&nbsp;3<br>
                 </td>
                 <td valign=\"top\">Density</td>
                   <td valign=\"top\">d<br>
                   </td>
                  <td valign=\"top\">kg/m<sup>3</sup><br>
                  </td>
                  </tr>
                  <tr>
                  <td valign=\"top\">&nbsp;4<br>
                 </td>
                 <td valign=\"top\">Specific volume</td>
                   <td valign=\"top\">v<br>
                   </td>
                  <td valign=\"top\">m<sup>3</sup>/kg<br>
                  </td>
                  </tr>
                  <tr>
                  <td valign=\"top\">&nbsp;5<br>
                 </td>
                 <td valign=\"top\">Specific enthalpy</td>
                  <td valign=\"top\">h<br>
                  </td>
                  <td valign=\"top\">J/kg<br>
                  </td>
                  </tr>
                  <tr>
                  <td valign=\"top\">&nbsp;6<br>
                 </td>
                 <td valign=\"top\">Specific entropy</td>
                  <td valign=\"top\">s<br>
                  </td>
                  <td valign=\"top\">J/(kg K)<br>
                  </td>
                  </tr>
                  <tr>
                  <td valign=\"top\">&nbsp;7<br>
                 </td>
                 <td valign=\"top\">Specific internal energy<br>
                  </td>
                  <td valign=\"top\">u<br>
                  </td>
                  <td valign=\"top\">J/kg<br>
                  </td>
                  </tr>
                  <tr>
                  <td valign=\"top\">&nbsp;8<br>
                 </td>
                 <td valign=\"top\">Specific isobaric heat capacity</td>
                  <td valign=\"top\">c<sub>p</sub><br>
                  </td>
                  <td valign=\"top\">J/(kg K)<br>
                  </td>
                  </tr>
                  <tr>
                  <td valign=\"top\">&nbsp;9<br>
                 </td>
                 <td valign=\"top\">Specific isochoric heat capacity</td>
                  <td valign=\"top\">c<sub>v</sub><br>
                  </td>
                  <td valign=\"top\">J/(kg K)<br>
                  </td>
                  </tr>
                  <tr>
                  <td valign=\"top\">10<br>
                 </td>
                 <td valign=\"top\">Isentropic exponent, kappa<span class=\"nobr\">=<font face=\"Symbol\">-</font>(v/p)
           (dp/dv)<sub>s</sub></span></td>
                <td valign=\"top\">kappa (<font face=\"Symbol\">k</font>)<br>
                </td>
                <td valign=\"top\">1<br>
                </td>
                </tr>
                <tr>
                <td valign=\"top\">11<br>
                 </td>
                 <td valign=\"top\">Speed of sound<br>
                </td>
                <td valign=\"top\">a<br>
                </td>
                <td valign=\"top\">m/s<br>
                </td>
                </tr>
                <tr>
                <td valign=\"top\">12<br>
                 </td>
                 <td valign=\"top\">Dryness fraction<br>
                </td>
                <td valign=\"top\">x<br>
                </td>
                <td valign=\"top\">kg/kg<br>
                </td>
                </tr>
                <tr>
                <td valign=\"top\">13<br>
                 </td>
                 <td valign=\"top\">Specific Helmholtz free energy,     f = u - Ts</td>
                <td valign=\"top\">f<br>
                </td>
                <td valign=\"top\">J/kg<br>
                </td>
                </tr>
                <tr>
                <td valign=\"top\">14<br>
                 </td>
                 <td valign=\"top\">Specific Gibbs free energy,     g = h - Ts</td>
                <td valign=\"top\">g<br>
                </td>
                <td valign=\"top\">J/kg<br>
                </td>
                </tr>
                <tr>
                <td valign=\"top\">15<br>
                 </td>
                 <td valign=\"top\">Isenthalpic exponent, <span class=\"nobr\"> theta = -(v/p)(dp/dv)<sub>h</sub></span></td>
                <td valign=\"top\">theta (<font face=\"Symbol\">q</font>)<br>
                </td>
                <td valign=\"top\">1<br>
                </td>
                </tr>
                <tr>
                <td valign=\"top\">16<br>
                 </td>
                 <td valign=\"top\">Isobaric volume expansion coefficient, alpha = v<sup>-1</sup>       (dv/dT)<sub>p</sub></td>
                <td valign=\"top\">alpha  (<font face=\"Symbol\">a</font>)<br>
                </td>
                  <td valign=\"top\">1/K<br>
                </td>
                </tr>
                <tr>
                <td valign=\"top\">17<br>
                 </td>
                 <td valign=\"top\">Isochoric pressure coefficient,     <span class=\"nobr\">beta = p<sup><font face=\"Symbol\">-</font>1</sup>(dp/dT)<sub>v</sub></span></td>
                <td valign=\"top\">beta (<font face=\"Symbol\">b</font>)<br>
                </td>
                <td valign=\"top\">1/K<br>
                </td>
                </tr>
                <tr>
                <td valign=\"top\">18<br>
                </td>
                <td valign=\"top\">Isothermal compressibility, <span class=\"nobr\">gamma = <font
            face=\"Symbol\">-</font>v<sup><font face=\"Symbol\">-</font>1</sup>(dv/dp)<sub>T</sub></span></td>
                <td valign=\"top\">gamma (<font face=\"Symbol\">g</font>)<br>
                </td>
                <td valign=\"top\">1/Pa<br>
                </td>
                </tr>
                <!-- <tr><td valign=\"top\">f</td><td valign=\"top\">Fugacity</td></tr> --> <tr>
                <td valign=\"top\">19<br>
                 </td>
                 <td valign=\"top\">Dynamic viscosity</td>
                <td valign=\"top\">eta (<font face=\"Symbol\">h</font>)<br>
                </td>
                <td valign=\"top\">Pa s<br>
                </td>
                </tr>
                <tr>
                <td valign=\"top\">20<br>
                 </td>
                 <td valign=\"top\">Kinematic viscosity</td>
                <td valign=\"top\">nu (<font face=\"Symbol\">n</font>)<br>
                </td>
                <td valign=\"top\">m<sup>2</sup>/s<br>
                </td>
                </tr>
                <!-- <tr><td valign=\"top\">Pr</td><td valign=\"top\">Prandtl number</td></tr> --> <tr>
                <td valign=\"top\">21<br>
                 </td>
                 <td valign=\"top\">Thermal conductivity</td>
                <td valign=\"top\">lambda (<font face=\"Symbol\">l</font>)<br>
                </td>
                <td valign=\"top\">W/(m K)<br>
                </td>
                </tr>
                <tr>
                <td valign=\"top\">22 <br>
                 </td>
                 <td valign=\"top\">Surface tension</td>
                <td valign=\"top\">sigma (<font face=\"Symbol\">s</font>)<br>
                </td>
                <td valign=\"top\">N/m<br>
                </td>
                </tr>
             </tbody>
           </table>
                   <p>The properties 1-11 are calculated by default with the functions for dynamic
                   simulation, 2 of these variables are the dynamic states and are the inputs
                   to calculate all other properties. In addition to these properties
                   of general interest, the entries to the thermodynamic Jacobian matrix which render
                   the mass- and energy balances explicit in the input variables to the property calculation are also calculated.
                   For an explanatory example using pressure and specific enthalpy as states, see the Examples sub-package.</p>
                   <p>The high-level calls to steam properties are grouped into records comprising both the properties of general interest
                   and the entries to the thermodynamic Jacobian. If additional properties are
                   needed the low level functions in BaseIF97 provide more choice.</p>
                   <HR size=3 width=\"90%\">
                   <h4>Additional functions</h4>
                   <ul>
                   <li>Function <b>boundaryvals_p</b> computes the temperature and the specific enthalpy and
                   entropy on both phase boundaries as a function of p</li>
                   <li>Function <b>boundaryderivs_p</b> is the Modelica derivative function of <b>boundaryvals_p</b></li>
                   <li>Function <b>extraDerivs_ph</b> computes all entries to Bridgmans tables for all
                   one-phase regions of IF97 using inputs (p,h). All 336 directional derivatives of the
                   thermodynamic surface can be computed as a ratio of two entries in the return data, see package Common
                   for details.</li>
                   <li>Function <b>extraDerivs_pT</b> computes all entries to Bridgmans tables for all
                   one-phase regions of IF97 using inputs (p,T).</li>
                   </ul>
                   </HTML>"));
        end BaseIF97;

        function waterBaseProp_ph  "Intermediate property record for water"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase = 0 "Phase: 2 for two-phase, 1 for one phase, 0 if unknown";
          input Integer region = 0 "If 0, do region computation, otherwise assume the region is this input";
          output Common.IF97BaseTwoPhase aux "Auxiliary record";
        protected
          Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          Integer error "Error flag for inverse iterations";
          .Modelica.SIunits.SpecificEnthalpy h_liq "Liquid specific enthalpy";
          .Modelica.SIunits.Density d_liq "Liquid density";
          .Modelica.SIunits.SpecificEnthalpy h_vap "Vapour specific enthalpy";
          .Modelica.SIunits.Density d_vap "Vapour density";
          Common.PhaseBoundaryProperties liq "Phase boundary property record";
          Common.PhaseBoundaryProperties vap "Phase boundary property record";
          Common.GibbsDerivs gl "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          Common.GibbsDerivs gv "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          Modelica.Media.Common.HelmholtzDerivs fl "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          Modelica.Media.Common.HelmholtzDerivs fv "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          .Modelica.SIunits.Temperature t1 "Temperature at phase boundary, using inverse from region 1";
          .Modelica.SIunits.Temperature t2 "Temperature at phase boundary, using inverse from region 2";
        algorithm
          aux.region := if region == 0 then if phase == 2 then 4 else BaseIF97.Regions.region_ph(p = p, h = h, phase = phase) else region;
          aux.phase := if phase <> 0 then phase else if aux.region == 4 then 2 else 1;
          aux.p := max(p, 611.657);
          aux.h := max(h, 1000.0);
          aux.R := BaseIF97.data.RH2O;
          if aux.region == 1 then
            aux.T := BaseIF97.Basic.tph1(aux.p, aux.h);
            g := BaseIF97.Basic.g1(p, aux.T);
            aux.s := aux.R * (g.tau * g.gtau - g.g);
            aux.rho := p / (aux.R * aux.T * g.pi * g.gpi);
            aux.vt := aux.R / p * (g.pi * g.gpi - g.tau * g.pi * g.gtaupi);
            aux.vp := aux.R * aux.T / (p * p) * g.pi * g.pi * g.gpipi;
            aux.cp := -aux.R * g.tau * g.tau * g.gtautau;
            aux.cv := aux.R * (-g.tau * g.tau * g.gtautau + (g.gpi - g.tau * g.gtaupi) * (g.gpi - g.tau * g.gtaupi) / g.gpipi);
            aux.x := 0.0;
            aux.dpT := -aux.vt / aux.vp;
          elseif aux.region == 2 then
            aux.T := BaseIF97.Basic.tph2(aux.p, aux.h);
            g := BaseIF97.Basic.g2(p, aux.T);
            aux.s := aux.R * (g.tau * g.gtau - g.g);
            aux.rho := p / (aux.R * aux.T * g.pi * g.gpi);
            aux.vt := aux.R / p * (g.pi * g.gpi - g.tau * g.pi * g.gtaupi);
            aux.vp := aux.R * aux.T / (p * p) * g.pi * g.pi * g.gpipi;
            aux.cp := -aux.R * g.tau * g.tau * g.gtautau;
            aux.cv := aux.R * (-g.tau * g.tau * g.gtautau + (g.gpi - g.tau * g.gtaupi) * (g.gpi - g.tau * g.gtaupi) / g.gpipi);
            aux.x := 1.0;
            aux.dpT := -aux.vt / aux.vp;
          elseif aux.region == 3 then
            (aux.rho, aux.T, error) := BaseIF97.Inverses.dtofph3(p = aux.p, h = aux.h, delp = 0.0000001, delh = 0.000001);
            f := BaseIF97.Basic.f3(aux.rho, aux.T);
            aux.h := aux.R * aux.T * (f.tau * f.ftau + f.delta * f.fdelta);
            aux.s := aux.R * (f.tau * f.ftau - f.f);
            aux.pd := aux.R * aux.T * f.delta * (2.0 * f.fdelta + f.delta * f.fdeltadelta);
            aux.pt := aux.R * aux.rho * f.delta * (f.fdelta - f.tau * f.fdeltatau);
            aux.cv := abs(aux.R * (-f.tau * f.tau * f.ftautau)) "Can be close to neg. infinity near critical point";
            aux.cp := (aux.rho * aux.rho * aux.pd * aux.cv + aux.T * aux.pt * aux.pt) / (aux.rho * aux.rho * aux.pd);
            aux.x := 0.0;
            aux.dpT := aux.pt;
          elseif aux.region == 4 then
            h_liq := hl_p(p);
            h_vap := hv_p(p);
            aux.x := if h_vap <> h_liq then (h - h_liq) / (h_vap - h_liq) else 1.0;
            if p < BaseIF97.data.PLIMIT4A then
              t1 := BaseIF97.Basic.tph1(aux.p, h_liq);
              t2 := BaseIF97.Basic.tph2(aux.p, h_vap);
              gl := BaseIF97.Basic.g1(aux.p, t1);
              gv := BaseIF97.Basic.g2(aux.p, t2);
              liq := Common.gibbsToBoundaryProps(gl);
              vap := Common.gibbsToBoundaryProps(gv);
              aux.T := t1 + aux.x * (t2 - t1);
            else
              aux.T := BaseIF97.Basic.tsat(aux.p);
              d_liq := rhol_T(aux.T);
              d_vap := rhov_T(aux.T);
              fl := BaseIF97.Basic.f3(d_liq, aux.T);
              fv := BaseIF97.Basic.f3(d_vap, aux.T);
              liq := Common.helmholtzToBoundaryProps(fl);
              vap := Common.helmholtzToBoundaryProps(fv);
            end if;
            aux.dpT := if liq.d <> vap.d then (vap.s - liq.s) * liq.d * vap.d / (liq.d - vap.d) else BaseIF97.Basic.dptofT(aux.T);
            aux.s := liq.s + aux.x * (vap.s - liq.s);
            aux.rho := liq.d * vap.d / (vap.d + aux.x * (liq.d - vap.d));
            aux.cv := Common.cv2Phase(liq, vap, aux.x, aux.T, p);
            aux.cp := liq.cp + aux.x * (vap.cp - liq.cp);
            aux.pt := liq.pt + aux.x * (vap.pt - liq.pt);
            aux.pd := liq.pd + aux.x * (vap.pd - liq.pd);
          elseif aux.region == 5 then
            (aux.T, error) := BaseIF97.Inverses.tofph5(p = aux.p, h = aux.h, reldh = 0.0000001);
            assert(error == 0, "Error in inverse iteration of steam tables");
            g := BaseIF97.Basic.g5(aux.p, aux.T);
            aux.s := aux.R * (g.tau * g.gtau - g.g);
            aux.rho := p / (aux.R * aux.T * g.pi * g.gpi);
            aux.vt := aux.R / p * (g.pi * g.gpi - g.tau * g.pi * g.gtaupi);
            aux.vp := aux.R * aux.T / (p * p) * g.pi * g.pi * g.gpipi;
            aux.cp := -aux.R * g.tau * g.tau * g.gtautau;
            aux.cv := aux.R * (-g.tau * g.tau * g.gtautau + (g.gpi - g.tau * g.gtaupi) * (g.gpi - g.tau * g.gtaupi) / g.gpipi);
            aux.dpT := -aux.vt / aux.vp;
          else
            assert(false, "Error in region computation of IF97 steam tables" + "(p = " + String(p) + ", h = " + String(h) + ")");
          end if;
        end waterBaseProp_ph;

        function waterBaseProp_ps  "Intermediate property record for water"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEntropy s "Specific entropy";
          input Integer phase = 0 "Phase: 2 for two-phase, 1 for one phase, 0 if unknown";
          input Integer region = 0 "If 0, do region computation, otherwise assume the region is this input";
          output Common.IF97BaseTwoPhase aux "Auxiliary record";
        protected
          Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          Integer error "Error flag for inverse iterations";
          .Modelica.SIunits.SpecificEntropy s_liq "Liquid specific entropy";
          .Modelica.SIunits.Density d_liq "Liquid density";
          .Modelica.SIunits.SpecificEntropy s_vap "Vapour specific entropy";
          .Modelica.SIunits.Density d_vap "Vapour density";
          Common.PhaseBoundaryProperties liq "Phase boundary property record";
          Common.PhaseBoundaryProperties vap "Phase boundary property record";
          Common.GibbsDerivs gl "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          Common.GibbsDerivs gv "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          Modelica.Media.Common.HelmholtzDerivs fl "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          Modelica.Media.Common.HelmholtzDerivs fv "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          .Modelica.SIunits.Temperature t1 "Temperature at phase boundary, using inverse from region 1";
          .Modelica.SIunits.Temperature t2 "Temperature at phase boundary, using inverse from region 2";
        algorithm
          aux.region := if region == 0 then if phase == 2 then 4 else BaseIF97.Regions.region_ps(p = p, s = s, phase = phase) else region;
          aux.phase := if phase <> 0 then phase else if aux.region == 4 then 2 else 1;
          aux.p := p;
          aux.s := s;
          aux.R := BaseIF97.data.RH2O;
          if aux.region == 1 then
            aux.T := BaseIF97.Basic.tps1(p, s);
            g := BaseIF97.Basic.g1(p, aux.T);
            aux.h := aux.R * aux.T * g.tau * g.gtau;
            aux.rho := p / (aux.R * aux.T * g.pi * g.gpi);
            aux.vt := aux.R / p * (g.pi * g.gpi - g.tau * g.pi * g.gtaupi);
            aux.vp := aux.R * aux.T / (p * p) * g.pi * g.pi * g.gpipi;
            aux.cp := -aux.R * g.tau * g.tau * g.gtautau;
            aux.cv := aux.R * (-g.tau * g.tau * g.gtautau + (g.gpi - g.tau * g.gtaupi) * (g.gpi - g.tau * g.gtaupi) / g.gpipi);
            aux.x := 0.0;
            aux.dpT := -aux.vt / aux.vp;
          elseif aux.region == 2 then
            aux.T := BaseIF97.Basic.tps2(p, s);
            g := BaseIF97.Basic.g2(p, aux.T);
            aux.h := aux.R * aux.T * g.tau * g.gtau;
            aux.rho := p / (aux.R * aux.T * g.pi * g.gpi);
            aux.vt := aux.R / p * (g.pi * g.gpi - g.tau * g.pi * g.gtaupi);
            aux.vp := aux.R * aux.T / (p * p) * g.pi * g.pi * g.gpipi;
            aux.cp := -aux.R * g.tau * g.tau * g.gtautau;
            aux.cv := aux.R * (-g.tau * g.tau * g.gtautau + (g.gpi - g.tau * g.gtaupi) * (g.gpi - g.tau * g.gtaupi) / g.gpipi);
            aux.x := 1.0;
            aux.dpT := -aux.vt / aux.vp;
          elseif aux.region == 3 then
            (aux.rho, aux.T, error) := BaseIF97.Inverses.dtofps3(p = p, s = s, delp = 0.0000001, dels = 0.000001);
            f := BaseIF97.Basic.f3(aux.rho, aux.T);
            aux.h := aux.R * aux.T * (f.tau * f.ftau + f.delta * f.fdelta);
            aux.s := aux.R * (f.tau * f.ftau - f.f);
            aux.pd := aux.R * aux.T * f.delta * (2.0 * f.fdelta + f.delta * f.fdeltadelta);
            aux.pt := aux.R * aux.rho * f.delta * (f.fdelta - f.tau * f.fdeltatau);
            aux.cv := aux.R * (-f.tau * f.tau * f.ftautau);
            aux.cp := (aux.rho * aux.rho * aux.pd * aux.cv + aux.T * aux.pt * aux.pt) / (aux.rho * aux.rho * aux.pd);
            aux.x := 0.0;
            aux.dpT := aux.pt;
          elseif aux.region == 4 then
            s_liq := BaseIF97.Regions.sl_p(p);
            s_vap := BaseIF97.Regions.sv_p(p);
            aux.x := if s_vap <> s_liq then (s - s_liq) / (s_vap - s_liq) else 1.0;
            if p < BaseIF97.data.PLIMIT4A then
              t1 := BaseIF97.Basic.tps1(p, s_liq);
              t2 := BaseIF97.Basic.tps2(p, s_vap);
              gl := BaseIF97.Basic.g1(p, t1);
              gv := BaseIF97.Basic.g2(p, t2);
              liq := Common.gibbsToBoundaryProps(gl);
              vap := Common.gibbsToBoundaryProps(gv);
              aux.T := t1 + aux.x * (t2 - t1);
            else
              aux.T := BaseIF97.Basic.tsat(p);
              d_liq := rhol_T(aux.T);
              d_vap := rhov_T(aux.T);
              fl := BaseIF97.Basic.f3(d_liq, aux.T);
              fv := BaseIF97.Basic.f3(d_vap, aux.T);
              liq := Common.helmholtzToBoundaryProps(fl);
              vap := Common.helmholtzToBoundaryProps(fv);
            end if;
            aux.dpT := if liq.d <> vap.d then (vap.s - liq.s) * liq.d * vap.d / (liq.d - vap.d) else BaseIF97.Basic.dptofT(aux.T);
            aux.h := liq.h + aux.x * (vap.h - liq.h);
            aux.rho := liq.d * vap.d / (vap.d + aux.x * (liq.d - vap.d));
            aux.cv := Common.cv2Phase(liq, vap, aux.x, aux.T, p);
            aux.cp := liq.cp + aux.x * (vap.cp - liq.cp);
            aux.pt := liq.pt + aux.x * (vap.pt - liq.pt);
            aux.pd := liq.pd + aux.x * (vap.pd - liq.pd);
          elseif aux.region == 5 then
            (aux.T, error) := BaseIF97.Inverses.tofps5(p = p, s = s, relds = 0.0000001);
            assert(error == 0, "Error in inverse iteration of steam tables");
            g := BaseIF97.Basic.g5(p, aux.T);
            aux.h := aux.R * aux.T * g.tau * g.gtau;
            aux.rho := p / (aux.R * aux.T * g.pi * g.gpi);
            aux.vt := aux.R / p * (g.pi * g.gpi - g.tau * g.pi * g.gtaupi);
            aux.vp := aux.R * aux.T / (p * p) * g.pi * g.pi * g.gpipi;
            aux.cp := -aux.R * g.tau * g.tau * g.gtautau;
            aux.cv := aux.R * (-g.tau * g.tau * g.gtautau + (g.gpi - g.tau * g.gtaupi) * (g.gpi - g.tau * g.gtaupi) / g.gpipi);
            aux.dpT := -aux.vt / aux.vp;
            aux.x := 1.0;
          else
            assert(false, "Error in region computation of IF97 steam tables" + "(p = " + String(p) + ", s = " + String(s) + ")");
          end if;
        end waterBaseProp_ps;

        function rho_props_ps  "Density as function of pressure and specific entropy"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEntropy s "Specific entropy";
          input Common.IF97BaseTwoPhase properties "Auxiliary record";
          output .Modelica.SIunits.Density rho "Density";
        algorithm
          rho := properties.rho;
          annotation(Inline = false, LateInline = true);
        end rho_props_ps;

        function rho_ps  "Density as function of pressure and specific entropy"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEntropy s "Specific entropy";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.Density rho "Density";
        algorithm
          rho := rho_props_ps(p, s, waterBaseProp_ps(p, s, phase, region));
          annotation(Inline = true);
        end rho_ps;

        function T_props_ps  "Temperature as function of pressure and specific entropy"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEntropy s "Specific entropy";
          input Common.IF97BaseTwoPhase properties "Auxiliary record";
          output .Modelica.SIunits.Temperature T "Temperature";
        algorithm
          T := properties.T;
          annotation(Inline = false, LateInline = true);
        end T_props_ps;

        function T_ps  "Temperature as function of pressure and specific entropy"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEntropy s "Specific entropy";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.Temperature T "Temperature";
        algorithm
          T := T_props_ps(p, s, waterBaseProp_ps(p, s, phase, region));
          annotation(Inline = true);
        end T_ps;

        function h_props_ps  "Specific enthalpy as function or pressure and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEntropy s "Specific entropy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := aux.h;
          annotation(Inline = false, LateInline = true);
        end h_props_ps;

        function h_ps  "Specific enthalpy as function or pressure and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEntropy s "Specific entropy";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := h_props_ps(p, s, waterBaseProp_ps(p, s, phase, region));
          annotation(Inline = true);
        end h_ps;

        function rho_props_ph  "Density as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase properties "Auxiliary record";
          output .Modelica.SIunits.Density rho "Density";
        algorithm
          rho := properties.rho;
          annotation(derivative(noDerivative = properties) = rho_ph_der, Inline = false, LateInline = true);
        end rho_props_ph;

        function rho_ph  "Density as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.Density rho "Density";
        algorithm
          rho := rho_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
          annotation(Inline = true);
        end rho_ph;

        function rho_ph_der  "Derivative function of rho_ph"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          input Real p_der "Derivative of pressure";
          input Real h_der "Derivative of specific enthalpy";
          output Real rho_der "Derivative of density";
        algorithm
          if aux.region == 4 then
            rho_der := aux.rho * (aux.rho * aux.cv / aux.dpT + 1.0) / (aux.dpT * aux.T) * p_der + (-aux.rho * aux.rho / (aux.dpT * aux.T)) * h_der;
          elseif aux.region == 3 then
            rho_der := aux.rho * (aux.cv * aux.rho + aux.pt) / (aux.rho * aux.rho * aux.pd * aux.cv + aux.T * aux.pt * aux.pt) * p_der + (-aux.rho * aux.rho * aux.pt / (aux.rho * aux.rho * aux.pd * aux.cv + aux.T * aux.pt * aux.pt)) * h_der;
          else
            rho_der := (-aux.rho * aux.rho * (aux.vp * aux.cp - aux.vt / aux.rho + aux.T * aux.vt * aux.vt) / aux.cp) * p_der + (-aux.rho * aux.rho * aux.vt / aux.cp) * h_der;
          end if;
        end rho_ph_der;

        function T_props_ph  "Temperature as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase properties "Auxiliary record";
          output .Modelica.SIunits.Temperature T "Temperature";
        algorithm
          T := properties.T;
          annotation(derivative(noDerivative = properties) = T_ph_der, Inline = false, LateInline = true);
        end T_props_ph;

        function T_ph  "Temperature as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.Temperature T "Temperature";
        algorithm
          T := T_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
          annotation(Inline = true);
        end T_ph;

        function T_ph_der  "Derivative function of T_ph"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          input Real p_der "Derivative of pressure";
          input Real h_der "Derivative of specific enthalpy";
          output Real T_der "Derivative of temperature";
        algorithm
          if aux.region == 4 then
            T_der := 1 / aux.dpT * p_der;
          elseif aux.region == 3 then
            T_der := (-aux.rho * aux.pd + aux.T * aux.pt) / (aux.rho * aux.rho * aux.pd * aux.cv + aux.T * aux.pt * aux.pt) * p_der + aux.rho * aux.rho * aux.pd / (aux.rho * aux.rho * aux.pd * aux.cv + aux.T * aux.pt * aux.pt) * h_der;
          else
            T_der := (-1 / aux.rho + aux.T * aux.vt) / aux.cp * p_der + 1 / aux.cp * h_der;
          end if;
        end T_ph_der;

        function s_props_ph  "Specific entropy as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase properties "Auxiliary record";
          output .Modelica.SIunits.SpecificEntropy s "Specific entropy";
        algorithm
          s := properties.s;
          annotation(derivative(noDerivative = properties) = s_ph_der, Inline = false, LateInline = true);
        end s_props_ph;

        function s_ph  "Specific entropy as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.SpecificEntropy s "Specific entropy";
        algorithm
          s := s_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
          annotation(Inline = true);
        end s_ph;

        function s_ph_der  "Specific entropy as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          input Real p_der "Derivative of pressure";
          input Real h_der "Derivative of specific enthalpy";
          output Real s_der "Derivative of entropy";
        algorithm
          s_der := -1 / (aux.rho * aux.T) * p_der + 1 / aux.T * h_der;
          annotation(Inline = true);
        end s_ph_der;

        function cv_props_ph  "Specific heat capacity at constant volume as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.SpecificHeatCapacity cv "Specific heat capacity";
        algorithm
          cv := aux.cv;
          annotation(Inline = false, LateInline = true);
        end cv_props_ph;

        function cv_ph  "Specific heat capacity at constant volume as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.SpecificHeatCapacity cv "Specific heat capacity";
        algorithm
          cv := cv_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
          annotation(Inline = true);
        end cv_ph;

        function cp_props_ph  "Specific heat capacity at constant pressure as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.SpecificHeatCapacity cp "Specific heat capacity";
        algorithm
          cp := aux.cp;
          annotation(Inline = false, LateInline = true);
        end cp_props_ph;

        function cp_ph  "Specific heat capacity at constant pressure as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.SpecificHeatCapacity cp "Specific heat capacity";
        algorithm
          cp := cp_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
          annotation(Inline = true);
        end cp_ph;

        function beta_props_ph  "Isobaric expansion coefficient as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.RelativePressureCoefficient beta "Isobaric expansion coefficient";
        algorithm
          beta := if aux.region == 3 or aux.region == 4 then aux.pt / (aux.rho * aux.pd) else aux.vt * aux.rho;
          annotation(Inline = false, LateInline = true);
        end beta_props_ph;

        function beta_ph  "Isobaric expansion coefficient as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.RelativePressureCoefficient beta "Isobaric expansion coefficient";
        algorithm
          beta := beta_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
          annotation(Inline = true);
        end beta_ph;

        function kappa_props_ph  "Isothermal compressibility factor as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.IsothermalCompressibility kappa "Isothermal compressibility factor";
        algorithm
          kappa := if aux.region == 3 or aux.region == 4 then 1 / (aux.rho * aux.pd) else -aux.vp * aux.rho;
          annotation(Inline = false, LateInline = true);
        end kappa_props_ph;

        function kappa_ph  "Isothermal compressibility factor as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.IsothermalCompressibility kappa "Isothermal compressibility factor";
        algorithm
          kappa := kappa_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
          annotation(Inline = true);
        end kappa_ph;

        function velocityOfSound_props_ph  "Speed of sound as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.Velocity v_sound "Speed of sound";
        algorithm
          v_sound := if aux.region == 3 then sqrt(max(0, (aux.pd * aux.rho * aux.rho * aux.cv + aux.pt * aux.pt * aux.T) / (aux.rho * aux.rho * aux.cv))) else if aux.region == 4 then sqrt(max(0, 1 / (aux.rho * (aux.rho * aux.cv / aux.dpT + 1.0) / (aux.dpT * aux.T) - 1 / aux.rho * aux.rho * aux.rho / (aux.dpT * aux.T)))) else sqrt(max(0, -aux.cp / (aux.rho * aux.rho * (aux.vp * aux.cp + aux.vt * aux.vt * aux.T))));
          annotation(Inline = false, LateInline = true);
        end velocityOfSound_props_ph;

        function velocityOfSound_ph
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.Velocity v_sound "Speed of sound";
        algorithm
          v_sound := velocityOfSound_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
          annotation(Inline = true);
        end velocityOfSound_ph;

        function isentropicExponent_props_ph  "Isentropic exponent as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output Real gamma "Isentropic exponent";
        algorithm
          gamma := if aux.region == 3 then 1 / (aux.rho * p) * (aux.pd * aux.cv * aux.rho * aux.rho + aux.pt * aux.pt * aux.T) / aux.cv else if aux.region == 4 then 1 / (aux.rho * p) * aux.dpT * aux.dpT * aux.T / aux.cv else -1 / (aux.rho * aux.p) * aux.cp / (aux.vp * aux.cp + aux.vt * aux.vt * aux.T);
          annotation(Inline = false, LateInline = true);
        end isentropicExponent_props_ph;

        function isentropicExponent_ph  "Isentropic exponent as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output Real gamma "Isentropic exponent";
        algorithm
          gamma := isentropicExponent_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
          annotation(Inline = false, LateInline = true);
        end isentropicExponent_ph;

        function ddph_props  "Density derivative by pressure"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.DerDensityByPressure ddph "Density derivative by pressure";
        algorithm
          ddph := if aux.region == 3 then aux.rho * (aux.cv * aux.rho + aux.pt) / (aux.rho * aux.rho * aux.pd * aux.cv + aux.T * aux.pt * aux.pt) else if aux.region == 4 then aux.rho * (aux.rho * aux.cv / aux.dpT + 1.0) / (aux.dpT * aux.T) else -aux.rho * aux.rho * (aux.vp * aux.cp - aux.vt / aux.rho + aux.T * aux.vt * aux.vt) / aux.cp;
          annotation(Inline = false, LateInline = true);
        end ddph_props;

        function ddph  "Density derivative by pressure"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.DerDensityByPressure ddph "Density derivative by pressure";
        algorithm
          ddph := ddph_props(p, h, waterBaseProp_ph(p, h, phase, region));
          annotation(Inline = true);
        end ddph;

        function ddhp_props  "Density derivative by specific enthalpy"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.DerDensityByEnthalpy ddhp "Density derivative by specific enthalpy";
        algorithm
          ddhp := if aux.region == 3 then -aux.rho * aux.rho * aux.pt / (aux.rho * aux.rho * aux.pd * aux.cv + aux.T * aux.pt * aux.pt) else if aux.region == 4 then -aux.rho * aux.rho / (aux.dpT * aux.T) else -aux.rho * aux.rho * aux.vt / aux.cp;
          annotation(Inline = false, LateInline = true);
        end ddhp_props;

        function ddhp  "Density derivative by specific enthalpy"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.DerDensityByEnthalpy ddhp "Density derivative by specific enthalpy";
        algorithm
          ddhp := ddhp_props(p, h, waterBaseProp_ph(p, h, phase, region));
          annotation(Inline = true);
        end ddhp;

        function waterBaseProp_pT  "Intermediate property record for water (p and T preferred states)"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Integer region = 0 "If 0, do region computation, otherwise assume the region is this input";
          output Common.IF97BaseTwoPhase aux "Auxiliary record";
        protected
          Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          Integer error "Error flag for inverse iterations";
        algorithm
          aux.phase := 1;
          aux.region := if region == 0 then BaseIF97.Regions.region_pT(p = p, T = T) else region;
          aux.R := BaseIF97.data.RH2O;
          aux.p := p;
          aux.T := T;
          aux.dpT := 0.0;
          aux.pt := 0.0;
          aux.pd := 0.0;
          aux.x := 0.0;
          aux.rho := 0.0;
          aux.vt := 0.0;
          aux.vp := 0.0;
          aux.cp := 0.0;
          if aux.region == 1 then
            g := BaseIF97.Basic.g1(p, T);
            aux.h := aux.R * aux.T * g.tau * g.gtau;
            aux.s := aux.R * (g.tau * g.gtau - g.g);
            aux.rho := p / (aux.R * T * g.pi * g.gpi);
            aux.vt := aux.R / p * (g.pi * g.gpi - g.tau * g.pi * g.gtaupi);
            aux.vp := aux.R * T / (p * p) * g.pi * g.pi * g.gpipi;
            aux.cp := -aux.R * g.tau * g.tau * g.gtautau;
            aux.cv := aux.R * (-g.tau * g.tau * g.gtautau + (g.gpi - g.tau * g.gtaupi) * (g.gpi - g.tau * g.gtaupi) / g.gpipi);
            aux.x := 0.0;
            aux.dpT := -aux.vt / aux.vp;
          elseif aux.region == 2 then
            g := BaseIF97.Basic.g2(p, T);
            aux.h := aux.R * aux.T * g.tau * g.gtau;
            aux.s := aux.R * (g.tau * g.gtau - g.g);
            aux.rho := p / (aux.R * T * g.pi * g.gpi);
            aux.vt := aux.R / p * (g.pi * g.gpi - g.tau * g.pi * g.gtaupi);
            aux.vp := aux.R * T / (p * p) * g.pi * g.pi * g.gpipi;
            aux.cp := -aux.R * g.tau * g.tau * g.gtautau;
            aux.cv := aux.R * (-g.tau * g.tau * g.gtautau + (g.gpi - g.tau * g.gtaupi) * (g.gpi - g.tau * g.gtaupi) / g.gpipi);
            aux.x := 1.0;
            aux.dpT := -aux.vt / aux.vp;
          elseif aux.region == 3 then
            (aux.rho, error) := BaseIF97.Inverses.dofpt3(p = p, T = T, delp = 0.0000001);
            f := BaseIF97.Basic.f3(aux.rho, T);
            aux.h := aux.R * T * (f.tau * f.ftau + f.delta * f.fdelta);
            aux.s := aux.R * (f.tau * f.ftau - f.f);
            aux.pd := aux.R * T * f.delta * (2.0 * f.fdelta + f.delta * f.fdeltadelta);
            aux.pt := aux.R * aux.rho * f.delta * (f.fdelta - f.tau * f.fdeltatau);
            aux.cv := aux.R * (-f.tau * f.tau * f.ftautau);
            aux.x := 0.0;
            aux.dpT := aux.pt;
          elseif aux.region == 5 then
            g := BaseIF97.Basic.g5(p, T);
            aux.h := aux.R * aux.T * g.tau * g.gtau;
            aux.s := aux.R * (g.tau * g.gtau - g.g);
            aux.rho := p / (aux.R * T * g.pi * g.gpi);
            aux.vt := aux.R / p * (g.pi * g.gpi - g.tau * g.pi * g.gtaupi);
            aux.vp := aux.R * T / (p * p) * g.pi * g.pi * g.gpipi;
            aux.cp := -aux.R * g.tau * g.tau * g.gtautau;
            aux.cv := aux.R * (-g.tau * g.tau * g.gtautau + (g.gpi - g.tau * g.gtaupi) * (g.gpi - g.tau * g.gtaupi) / g.gpipi);
            aux.x := 1.0;
            aux.dpT := -aux.vt / aux.vp;
          else
            assert(false, "Error in region computation of IF97 steam tables" + "(p = " + String(p) + ", T = " + String(T) + ")");
          end if;
        end waterBaseProp_pT;

        function rho_props_pT  "Density as function or pressure and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.Density rho "Density";
        algorithm
          rho := aux.rho;
          annotation(derivative(noDerivative = aux) = rho_pT_der, Inline = false, LateInline = true);
        end rho_props_pT;

        function rho_pT  "Density as function or pressure and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.Density rho "Density";
        algorithm
          rho := rho_props_pT(p, T, waterBaseProp_pT(p, T, region));
          annotation(Inline = true);
        end rho_pT;

        function h_props_pT  "Specific enthalpy as function or pressure and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := aux.h;
          annotation(derivative(noDerivative = aux) = h_pT_der, Inline = false, LateInline = true);
        end h_props_pT;

        function h_pT  "Specific enthalpy as function or pressure and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := h_props_pT(p, T, waterBaseProp_pT(p, T, region));
          annotation(Inline = true);
        end h_pT;

        function h_pT_der  "Derivative function of h_pT"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          input Real p_der "Derivative of pressure";
          input Real T_der "Derivative of temperature";
          output Real h_der "Derivative of specific enthalpy";
        algorithm
          if aux.region == 3 then
            h_der := (-aux.rho * aux.pd + T * aux.pt) / (aux.rho * aux.rho * aux.pd) * p_der + (aux.rho * aux.rho * aux.pd * aux.cv + aux.T * aux.pt * aux.pt) / (aux.rho * aux.rho * aux.pd) * T_der;
          else
            h_der := (1 / aux.rho - aux.T * aux.vt) * p_der + aux.cp * T_der;
          end if;
        end h_pT_der;

        function rho_pT_der  "Derivative function of rho_pT"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          input Real p_der "Derivative of pressure";
          input Real T_der "Derivative of temperature";
          output Real rho_der "Derivative of density";
        algorithm
          if aux.region == 3 then
            rho_der := 1 / aux.pd * p_der - aux.pt / aux.pd * T_der;
          else
            rho_der := (-aux.rho * aux.rho * aux.vp) * p_der + (-aux.rho * aux.rho * aux.vt) * T_der;
          end if;
        end rho_pT_der;

        function s_props_pT  "Specific entropy as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.SpecificEntropy s "Specific entropy";
        algorithm
          s := aux.s;
          annotation(Inline = false, LateInline = true);
        end s_props_pT;

        function s_pT  "Temperature as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.SpecificEntropy s "Specific entropy";
        algorithm
          s := s_props_pT(p, T, waterBaseProp_pT(p, T, region));
          annotation(Inline = true);
        end s_pT;

        function cv_props_pT  "Specific heat capacity at constant volume as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.SpecificHeatCapacity cv "Specific heat capacity";
        algorithm
          cv := aux.cv;
          annotation(Inline = false, LateInline = true);
        end cv_props_pT;

        function cv_pT  "Specific heat capacity at constant volume as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.SpecificHeatCapacity cv "Specific heat capacity";
        algorithm
          cv := cv_props_pT(p, T, waterBaseProp_pT(p, T, region));
          annotation(Inline = true);
        end cv_pT;

        function cp_props_pT  "Specific heat capacity at constant pressure as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.SpecificHeatCapacity cp "Specific heat capacity";
        algorithm
          cp := if aux.region == 3 then (aux.rho * aux.rho * aux.pd * aux.cv + aux.T * aux.pt * aux.pt) / (aux.rho * aux.rho * aux.pd) else aux.cp;
          annotation(Inline = false, LateInline = true);
        end cp_props_pT;

        function cp_pT  "Specific heat capacity at constant pressure as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.SpecificHeatCapacity cp "Specific heat capacity";
        algorithm
          cp := cp_props_pT(p, T, waterBaseProp_pT(p, T, region));
          annotation(Inline = true);
        end cp_pT;

        function beta_props_pT  "Isobaric expansion coefficient as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.RelativePressureCoefficient beta "Isobaric expansion coefficient";
        algorithm
          beta := if aux.region == 3 then aux.pt / (aux.rho * aux.pd) else aux.vt * aux.rho;
          annotation(Inline = false, LateInline = true);
        end beta_props_pT;

        function beta_pT  "Isobaric expansion coefficient as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.RelativePressureCoefficient beta "Isobaric expansion coefficient";
        algorithm
          beta := beta_props_pT(p, T, waterBaseProp_pT(p, T, region));
          annotation(Inline = true);
        end beta_pT;

        function kappa_props_pT  "Isothermal compressibility factor as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.IsothermalCompressibility kappa "Isothermal compressibility factor";
        algorithm
          kappa := if aux.region == 3 then 1 / (aux.rho * aux.pd) else -aux.vp * aux.rho;
          annotation(Inline = false, LateInline = true);
        end kappa_props_pT;

        function kappa_pT  "Isothermal compressibility factor as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.IsothermalCompressibility kappa "Isothermal compressibility factor";
        algorithm
          kappa := kappa_props_pT(p, T, waterBaseProp_pT(p, T, region));
          annotation(Inline = true);
        end kappa_pT;

        function velocityOfSound_props_pT  "Speed of sound as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.Velocity v_sound "Speed of sound";
        algorithm
          v_sound := if aux.region == 3 then sqrt(max(0, (aux.pd * aux.rho * aux.rho * aux.cv + aux.pt * aux.pt * aux.T) / (aux.rho * aux.rho * aux.cv))) else sqrt(max(0, -aux.cp / (aux.rho * aux.rho * (aux.vp * aux.cp + aux.vt * aux.vt * aux.T))));
          annotation(Inline = false, LateInline = true);
        end velocityOfSound_props_pT;

        function velocityOfSound_pT  "Speed of sound as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.Velocity v_sound "Speed of sound";
        algorithm
          v_sound := velocityOfSound_props_pT(p, T, waterBaseProp_pT(p, T, region));
          annotation(Inline = true);
        end velocityOfSound_pT;

        function isentropicExponent_props_pT  "Isentropic exponent as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output Real gamma "Isentropic exponent";
        algorithm
          gamma := if aux.region == 3 then 1 / (aux.rho * p) * (aux.pd * aux.cv * aux.rho * aux.rho + aux.pt * aux.pt * aux.T) / aux.cv else -1 / (aux.rho * aux.p) * aux.cp / (aux.vp * aux.cp + aux.vt * aux.vt * aux.T);
          annotation(Inline = false, LateInline = true);
        end isentropicExponent_props_pT;

        function isentropicExponent_pT  "Isentropic exponent as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output Real gamma "Isentropic exponent";
        algorithm
          gamma := isentropicExponent_props_pT(p, T, waterBaseProp_pT(p, T, region));
          annotation(Inline = false, LateInline = true);
        end isentropicExponent_pT;

        function waterBaseProp_dT  "Intermediate property record for water (d and T preferred states)"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Density rho "Density";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Integer phase = 0 "Phase: 2 for two-phase, 1 for one phase, 0 if unknown";
          input Integer region = 0 "If 0, do region computation, otherwise assume the region is this input";
          output Common.IF97BaseTwoPhase aux "Auxiliary record";
        protected
          .Modelica.SIunits.SpecificEnthalpy h_liq "Liquid specific enthalpy";
          .Modelica.SIunits.Density d_liq "Liquid density";
          .Modelica.SIunits.SpecificEnthalpy h_vap "Vapour specific enthalpy";
          .Modelica.SIunits.Density d_vap "Vapour density";
          Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          Modelica.Media.Common.PhaseBoundaryProperties liq "Phase boundary property record";
          Modelica.Media.Common.PhaseBoundaryProperties vap "Phase boundary property record";
          Modelica.Media.Common.GibbsDerivs gl "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          Modelica.Media.Common.GibbsDerivs gv "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          Modelica.Media.Common.HelmholtzDerivs fl "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          Modelica.Media.Common.HelmholtzDerivs fv "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          Integer error "Error flag for inverse iterations";
        algorithm
          aux.region := if region == 0 then if phase == 2 then 4 else BaseIF97.Regions.region_dT(d = rho, T = T, phase = phase) else region;
          aux.phase := if aux.region == 4 then 2 else 1;
          aux.R := BaseIF97.data.RH2O;
          aux.rho := rho;
          aux.T := T;
          if aux.region == 1 then
            (aux.p, error) := BaseIF97.Inverses.pofdt125(d = rho, T = T, reldd = 0.00000001, region = 1);
            g := BaseIF97.Basic.g1(aux.p, T);
            aux.h := aux.R * aux.T * g.tau * g.gtau;
            aux.s := aux.R * (g.tau * g.gtau - g.g);
            aux.rho := aux.p / (aux.R * T * g.pi * g.gpi);
            aux.vt := aux.R / aux.p * (g.pi * g.gpi - g.tau * g.pi * g.gtaupi);
            aux.vp := aux.R * T / (aux.p * aux.p) * g.pi * g.pi * g.gpipi;
            aux.cp := -aux.R * g.tau * g.tau * g.gtautau;
            aux.cv := aux.R * (-g.tau * g.tau * g.gtautau + (g.gpi - g.tau * g.gtaupi) * (g.gpi - g.tau * g.gtaupi) / g.gpipi);
            aux.x := 0.0;
          elseif aux.region == 2 then
            (aux.p, error) := BaseIF97.Inverses.pofdt125(d = rho, T = T, reldd = 0.00000001, region = 2);
            g := BaseIF97.Basic.g2(aux.p, T);
            aux.h := aux.R * aux.T * g.tau * g.gtau;
            aux.s := aux.R * (g.tau * g.gtau - g.g);
            aux.rho := aux.p / (aux.R * T * g.pi * g.gpi);
            aux.vt := aux.R / aux.p * (g.pi * g.gpi - g.tau * g.pi * g.gtaupi);
            aux.vp := aux.R * T / (aux.p * aux.p) * g.pi * g.pi * g.gpipi;
            aux.cp := -aux.R * g.tau * g.tau * g.gtautau;
            aux.cv := aux.R * (-g.tau * g.tau * g.gtautau + (g.gpi - g.tau * g.gtaupi) * (g.gpi - g.tau * g.gtaupi) / g.gpipi);
            aux.x := 1.0;
          elseif aux.region == 3 then
            f := BaseIF97.Basic.f3(rho, T);
            aux.p := aux.R * rho * T * f.delta * f.fdelta;
            aux.h := aux.R * T * (f.tau * f.ftau + f.delta * f.fdelta);
            aux.s := aux.R * (f.tau * f.ftau - f.f);
            aux.pd := aux.R * T * f.delta * (2.0 * f.fdelta + f.delta * f.fdeltadelta);
            aux.pt := aux.R * rho * f.delta * (f.fdelta - f.tau * f.fdeltatau);
            aux.cp := (aux.rho * aux.rho * aux.pd * aux.cv + aux.T * aux.pt * aux.pt) / (aux.rho * aux.rho * aux.pd);
            aux.cv := aux.R * (-f.tau * f.tau * f.ftautau);
            aux.x := 0.0;
          elseif aux.region == 4 then
            aux.p := BaseIF97.Basic.psat(T);
            d_liq := rhol_T(T);
            d_vap := rhov_T(T);
            h_liq := hl_p(aux.p);
            h_vap := hv_p(aux.p);
            aux.x := if d_vap <> d_liq then (1 / rho - 1 / d_liq) / (1 / d_vap - 1 / d_liq) else 1.0;
            aux.h := h_liq + aux.x * (h_vap - h_liq);
            if T < BaseIF97.data.TLIMIT1 then
              gl := BaseIF97.Basic.g1(aux.p, T);
              gv := BaseIF97.Basic.g2(aux.p, T);
              liq := Common.gibbsToBoundaryProps(gl);
              vap := Common.gibbsToBoundaryProps(gv);
            else
              fl := BaseIF97.Basic.f3(d_liq, T);
              fv := BaseIF97.Basic.f3(d_vap, T);
              liq := Common.helmholtzToBoundaryProps(fl);
              vap := Common.helmholtzToBoundaryProps(fv);
            end if;
            aux.dpT := if liq.d <> vap.d then (vap.s - liq.s) * liq.d * vap.d / (liq.d - vap.d) else BaseIF97.Basic.dptofT(aux.T);
            aux.s := liq.s + aux.x * (vap.s - liq.s);
            aux.cv := Common.cv2Phase(liq, vap, aux.x, aux.T, aux.p);
            aux.cp := liq.cp + aux.x * (vap.cp - liq.cp);
            aux.pt := liq.pt + aux.x * (vap.pt - liq.pt);
            aux.pd := liq.pd + aux.x * (vap.pd - liq.pd);
          elseif aux.region == 5 then
            (aux.p, error) := BaseIF97.Inverses.pofdt125(d = rho, T = T, reldd = 0.00000001, region = 5);
            g := BaseIF97.Basic.g2(aux.p, T);
            aux.h := aux.R * aux.T * g.tau * g.gtau;
            aux.s := aux.R * (g.tau * g.gtau - g.g);
            aux.rho := aux.p / (aux.R * T * g.pi * g.gpi);
            aux.vt := aux.R / aux.p * (g.pi * g.gpi - g.tau * g.pi * g.gtaupi);
            aux.vp := aux.R * T / (aux.p * aux.p) * g.pi * g.pi * g.gpipi;
            aux.cp := -aux.R * g.tau * g.tau * g.gtautau;
            aux.cv := aux.R * (-g.tau * g.tau * g.gtautau + (g.gpi - g.tau * g.gtaupi) * (g.gpi - g.tau * g.gtaupi) / g.gpipi);
          else
            assert(false, "Error in region computation of IF97 steam tables" + "(rho = " + String(rho) + ", T = " + String(T) + ")");
          end if;
        end waterBaseProp_dT;

        function h_props_dT  "Specific enthalpy as function of density and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Density d "Density";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := aux.h;
          annotation(derivative(noDerivative = aux) = h_dT_der, Inline = false, LateInline = true);
        end h_props_dT;

        function h_dT  "Specific enthalpy as function of density and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Density d "Density";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := h_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
          annotation(Inline = true);
        end h_dT;

        function h_dT_der  "Derivative function of h_dT"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Density d "Density";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          input Real d_der "Derivative of density";
          input Real T_der "Derivative of temperature";
          output Real h_der "Derivative of specific enthalpy";
        algorithm
          if aux.region == 3 then
            h_der := (-d * aux.pd + T * aux.pt) / (d * d) * d_der + (aux.cv * d + aux.pt) / d * T_der;
          elseif aux.region == 4 then
            h_der := T * aux.dpT / (d * d) * d_der + (aux.cv * d + aux.dpT) / d * T_der;
          else
            h_der := (-(-1 / d + T * aux.vt) / (d * d * aux.vp)) * d_der + (aux.vp * aux.cp - aux.vt / d + T * aux.vt * aux.vt) / aux.vp * T_der;
          end if;
        end h_dT_der;

        function p_props_dT  "Pressure as function of density and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Density d "Density";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.Pressure p "Pressure";
        algorithm
          p := aux.p;
          annotation(derivative(noDerivative = aux) = p_dT_der, Inline = false, LateInline = true);
        end p_props_dT;

        function p_dT  "Pressure as function of density and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Density d "Density";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.Pressure p "Pressure";
        algorithm
          p := p_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
          annotation(Inline = true);
        end p_dT;

        function p_dT_der  "Derivative function of p_dT"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Density d "Density";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          input Real d_der "Derivative of density";
          input Real T_der "Derivative of temperature";
          output Real p_der "Derivative of pressure";
        algorithm
          if aux.region == 3 then
            p_der := aux.pd * d_der + aux.pt * T_der;
          elseif aux.region == 4 then
            p_der := aux.dpT * T_der;
          else
            p_der := (-1 / (d * d * aux.vp)) * d_der + (-aux.vt / aux.vp) * T_der;
          end if;
        end p_dT_der;

        function s_props_dT  "Specific entropy as function of density and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Density d "Density";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.SpecificEntropy s "Specific entropy";
        algorithm
          s := aux.s;
          annotation(Inline = false, LateInline = true);
        end s_props_dT;

        function s_dT  "Temperature as function of density and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Density d "Density";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.SpecificEntropy s "Specific entropy";
        algorithm
          s := s_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
          annotation(Inline = true);
        end s_dT;

        function cv_props_dT  "Specific heat capacity at constant volume as function of density and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Density d "Density";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.SpecificHeatCapacity cv "Specific heat capacity";
        algorithm
          cv := aux.cv;
          annotation(Inline = false, LateInline = true);
        end cv_props_dT;

        function cv_dT  "Specific heat capacity at constant volume as function of density and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Density d "Density";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.SpecificHeatCapacity cv "Specific heat capacity";
        algorithm
          cv := cv_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
          annotation(Inline = true);
        end cv_dT;

        function cp_props_dT  "Specific heat capacity at constant pressure as function of density and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Density d "Density";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.SpecificHeatCapacity cp "Specific heat capacity";
        algorithm
          cp := aux.cp;
          annotation(Inline = false, LateInline = true);
        end cp_props_dT;

        function cp_dT  "Specific heat capacity at constant pressure as function of density and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Density d "Density";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.SpecificHeatCapacity cp "Specific heat capacity";
        algorithm
          cp := cp_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
          annotation(Inline = true);
        end cp_dT;

        function beta_props_dT  "Isobaric expansion coefficient as function of density and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Density d "Density";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.RelativePressureCoefficient beta "Isobaric expansion coefficient";
        algorithm
          beta := if aux.region == 3 or aux.region == 4 then aux.pt / (aux.rho * aux.pd) else aux.vt * aux.rho;
          annotation(Inline = false, LateInline = true);
        end beta_props_dT;

        function beta_dT  "Isobaric expansion coefficient as function of density and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Density d "Density";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.RelativePressureCoefficient beta "Isobaric expansion coefficient";
        algorithm
          beta := beta_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
          annotation(Inline = true);
        end beta_dT;

        function kappa_props_dT  "Isothermal compressibility factor as function of density and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Density d "Density";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.IsothermalCompressibility kappa "Isothermal compressibility factor";
        algorithm
          kappa := if aux.region == 3 or aux.region == 4 then 1 / (aux.rho * aux.pd) else -aux.vp * aux.rho;
          annotation(Inline = false, LateInline = true);
        end kappa_props_dT;

        function kappa_dT  "Isothermal compressibility factor as function of density and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Density d "Density";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.IsothermalCompressibility kappa "Isothermal compressibility factor";
        algorithm
          kappa := kappa_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
          annotation(Inline = true);
        end kappa_dT;

        function velocityOfSound_props_dT  "Speed of sound as function of density and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Density d "Density";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.Velocity v_sound "Speed of sound";
        algorithm
          v_sound := if aux.region == 3 then sqrt(max(0, (aux.pd * aux.rho * aux.rho * aux.cv + aux.pt * aux.pt * aux.T) / (aux.rho * aux.rho * aux.cv))) else if aux.region == 4 then sqrt(max(0, 1 / (aux.rho * (aux.rho * aux.cv / aux.dpT + 1.0) / (aux.dpT * aux.T) - 1 / aux.rho * aux.rho * aux.rho / (aux.dpT * aux.T)))) else sqrt(max(0, -aux.cp / (aux.rho * aux.rho * (aux.vp * aux.cp + aux.vt * aux.vt * aux.T))));
          annotation(Inline = false, LateInline = true);
        end velocityOfSound_props_dT;

        function velocityOfSound_dT  "Speed of sound as function of density and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Density d "Density";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.Velocity v_sound "Speed of sound";
        algorithm
          v_sound := velocityOfSound_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
          annotation(Inline = true);
        end velocityOfSound_dT;

        function isentropicExponent_props_dT  "Isentropic exponent as function of density and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Density d "Density";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output Real gamma "Isentropic exponent";
        algorithm
          gamma := if aux.region == 3 then 1 / (aux.rho * aux.p) * (aux.pd * aux.cv * aux.rho * aux.rho + aux.pt * aux.pt * aux.T) / aux.cv else if aux.region == 4 then 1 / (aux.rho * aux.p) * aux.dpT * aux.dpT * aux.T / aux.cv else -1 / (aux.rho * aux.p) * aux.cp / (aux.vp * aux.cp + aux.vt * aux.vt * aux.T);
          annotation(Inline = false, LateInline = true);
        end isentropicExponent_props_dT;

        function isentropicExponent_dT  "Isentropic exponent as function of density and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Density d "Density";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output Real gamma "Isentropic exponent";
        algorithm
          gamma := isentropicExponent_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
          annotation(Inline = false, LateInline = true);
        end isentropicExponent_dT;

        function hl_p = BaseIF97.Regions.hl_p "Compute the saturated liquid specific h(p)";
        function hv_p = BaseIF97.Regions.hv_p "Compute the saturated vapour specific h(p)";
        function rhol_T = BaseIF97.Regions.rhol_T "Compute the saturated liquid d(T)";
        function rhov_T = BaseIF97.Regions.rhov_T "Compute the saturated vapour d(T)";
        function dynamicViscosity = BaseIF97.Transport.visc_dTp "Compute eta(d,T) in the one-phase region";
        function thermalConductivity = BaseIF97.Transport.cond_dTp "Compute lambda(d,T,p) in the one-phase region";
        function surfaceTension = BaseIF97.Transport.surfaceTension "Compute sigma(T) at saturation T";

        function isentropicEnthalpy  "Isentropic specific enthalpy from p,s (preferably use dynamicIsentropicEnthalpy in dynamic simulation!)"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEntropy s "Specific entropy";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := isentropicEnthalpy_props(p, s, waterBaseProp_ps(p, s, phase, region));
          annotation(Inline = true);
        end isentropicEnthalpy;

        function isentropicEnthalpy_props
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEntropy s "Specific entropy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output .Modelica.SIunits.SpecificEnthalpy h "Isentropic enthalpy";
        algorithm
          h := aux.h;
          annotation(derivative(noDerivative = aux) = isentropicEnthalpy_der, Inline = false, LateInline = true);
        end isentropicEnthalpy_props;

        function isentropicEnthalpy_der  "Derivative of isentropic specific enthalpy from p,s"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.SpecificEntropy s "Specific entropy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          input Real p_der "Pressure derivative";
          input Real s_der "Entropy derivative";
          output Real h_der "Specific enthalpy derivative";
        algorithm
          h_der := 1 / aux.rho * p_der + aux.T * s_der;
          annotation(Inline = true);
        end isentropicEnthalpy_der;
        annotation(Documentation(info = "<HTML>
               <h4>Package description:</h4>
               <p>This package provides high accuracy physical properties for water according
               to the IAPWS/IF97 standard. It has been part of the ThermoFluid Modelica library and been extended,
               reorganized and documented to become part of the Modelica Standard library.</p>
               <p>An important feature that distinguishes this implementation of the IF97 steam property standard
               is that this implementation has been explicitly designed to work well in dynamic simulations. Computational
               performance has been of high importance. This means that there often exist several ways to get the same result
               from different functions if one of the functions is called often but can be optimized for that purpose.
               </p>
               <p>
               The original documentation of the IAPWS/IF97 steam properties can freely be distributed with computer
               implementations, so for curious minds the complete standard documentation is provided with the Modelica
               properties library. The following documents are included
               (in directory Modelica/Resources/Documentation/Media/Water/IF97documentation):
               </p>
               <ul>
               <li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/IF97.pdf\">IF97.pdf</a> The standards document for the main part of the IF97.</li>
               <li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/Back3.pdf\">Back3.pdf</a> The backwards equations for region 3.</li>
               <li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/crits.pdf\">crits.pdf</a> The critical point data.</li>
               <li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/meltsub.pdf\">meltsub.pdf</a> The melting- and sublimation line formulation (in IF97_Utilities.BaseIF97.IceBoundaries)</li>
               <li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/surf.pdf\">surf.pdf</a> The surface tension standard definition</li>
               <li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/thcond.pdf\">thcond.pdf</a> The thermal conductivity standard definition</li>
               <li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/visc.pdf\">visc.pdf</a> The viscosity standard definition</li>
               </ul>
               <h4>Package contents
               </h4>
               <ul>
               <li>Package <b>BaseIF97</b> contains the implementation of the IAPWS-IF97 as described in
               <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/IF97.pdf\">IF97.pdf</a>. The explicit backwards equations for region 3 from
               <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/Back3.pdf\">Back3.pdf</a> are implemented as initial values for an inverse iteration of the exact
               function in IF97 for the input pairs (p,h) and (p,s).
               The low-level functions in BaseIF97 are not needed for standard simulation usage,
               but can be useful for experts and some special purposes.</li>
               <li>Function <b>water_ph</b> returns all properties needed for a dynamic control volume model and properties of general
               interest using pressure p and specific entropy enthalpy h as dynamic states in the record ThermoProperties_ph. </li>
               <li>Function <b>water_ps</b> returns all properties needed for a dynamic control volume model and properties of general
               interest using pressure p and specific entropy s as dynamic states in the record ThermoProperties_ps. </li>
               <li>Function <b>water_dT</b> returns all properties needed for a dynamic control volume model and properties of general
               interest using density d and temperature T as dynamic states in the record ThermoProperties_dT. </li>
               <li>Function <b>water_pT</b> returns all properties needed for a dynamic control volume model and properties of general
               interest using pressure p and temperature T as dynamic states in the record ThermoProperties_pT. Due to the coupling of
               pressure and temperature in the two-phase region, this model can obviously
               only be used for one-phase models or models treating both phases independently.</li>
               <li>Function <b>hl_p</b> computes the liquid specific enthalpy as a function of pressure. For overcritical pressures,
               the critical specific enthalpy is returned</li>
               <li>Function <b>hv_p</b> computes the vapour specific enthalpy as a function of pressure. For overcritical pressures,
               the critical specific enthalpy is returned</li>
               <li>Function <b>sl_p</b> computes the liquid specific entropy as a function of pressure. For overcritical pressures,
               the critical  specific entropy is returned</li>
               <li>Function <b>sv_p</b> computes the vapour  specific entropy as a function of pressure. For overcritical pressures,
               the critical  specific entropy is returned</li>
               <li>Function <b>rhol_T</b> computes the liquid density as a function of temperature. For overcritical temperatures,
               the critical density is returned</li>
               <li>Function <b>rhol_T</b> computes the vapour density as a function of temperature. For overcritical temperatures,
               the critical density is returned</li>
               <li>Function <b>dynamicViscosity</b> computes the dynamic viscosity as a function of density and temperature.</li>
               <li>Function <b>thermalConductivity</b> computes the thermal conductivity as a function of density, temperature and pressure.
               <b>Important note</b>: Obviously only two of the three
               inputs are really needed, but using three inputs speeds up the computation and the three variables
               are known in most models anyways. The inputs d,T and p have to be consistent.</li>
               <li>Function <b>surfaceTension</b> computes the surface tension between vapour
                   and liquid water as a function of temperature.</li>
               <li>Function <b>isentropicEnthalpy</b> computes the specific enthalpy h(p,s,phase) in all regions.
                   The phase input is needed due to discontinuous derivatives at the phase boundary.</li>
               <li>Function <b>dynamicIsentropicEnthalpy</b> computes the specific enthalpy h(p,s,,dguess,Tguess,phase) in all regions.
                   The phase input is needed due to discontinuous derivatives at the phase boundary. Tguess and dguess are initial guess
                   values for the density and temperature consistent with p and s. This function should be preferred in
                   dynamic simulations where good guesses are often available.</li>
               </ul>
               <h4>Version Info and Revision history
               </h4>
               <ul>
               <li>First implemented: <i>July, 2000</i>
               by Hubertus Tummescheit for the ThermoFluid Library with help from Jonas Eborn and Falko Jens Wagner
               </li>
               <li>Code reorganization, enhanced documentation, additional functions:   <i>December, 2002</i>
               by <a href=\"mailto:Hubertus.Tummescheit@modelon.se\">Hubertus Tummescheit</a> and moved to Modelica
               properties library.</li>
               </ul>
               <address>Author: Hubertus Tummescheit, <br>
               Modelon AB<br>
               Ideon Science Park<br>
               SE-22370 Lund, Sweden<br>
               email: hubertus@modelon.se
               </address>
               </HTML>", revisions = "<h4>Intermediate release notes during development</h4>
         <p>Currently the Events/noEvents switch is only implemented for p-h states. Only after testing that implementation, it will be extended to dT.</p>"));
      end IF97_Utilities;
      annotation(Documentation(info = "<html>
       <p>This package contains different medium models for water:</p>
       <ul>
       <li><b>ConstantPropertyLiquidWater</b><br>
           Simple liquid water medium (incompressible, constant data).</li>
       <li><b>IdealSteam</b><br>
           Steam water medium as ideal gas from Media.IdealGases.SingleGases.H2O</li>
       <li><b>WaterIF97 derived models</b><br>
           High precision water model according to the IAPWS/IF97 standard
           (liquid, steam, two phase region). Models with different independent
           variables are provided as well as models valid only
           for particular regions. The <b>WaterIF97_ph</b> model is valid
           in all regions and is the recommended one to use.</li>
       </ul>
       <h4>Overview of WaterIF97 derived water models</h4>
       <p>
       The WaterIF97 models calculate medium properties
       for water in the <b>liquid</b>, <b>gas</b> and <b>two phase</b> regions
       according to the IAPWS/IF97 standard, i.e., the accepted industrial standard
       and best compromise between accuracy and computation time.
       It has been part of the ThermoFluid Modelica library and been extended,
       reorganized and documented to become part of the Modelica Standard library.</p>
       <p>An important feature that distinguishes this implementation of the IF97 steam property standard
       is that this implementation has been explicitly designed to work well in dynamic simulations. Computational
       performance has been of high importance. This means that there often exist several ways to get the same result
       from different functions if one of the functions is called often but can be optimized for that purpose.
       </p>
       <p>Three variable pairs can be the independent variables of the model:
       </p>
       <ol>
       <li>Pressure <b>p</b> and specific enthalpy <b>h</b> are
           the most natural choice for general applications.
           This is the recommended choice for most general purpose
           applications, in particular for power plants.</li>
       <li>Pressure <b>p</b> and temperature <b>T</b> are the most natural
           choice for applications where water is always in the same phase,
           both for liquid water and steam.</li>
       <li>Density <b>d</b> and temperature <b>T</b> are explicit
           variables of the Helmholtz function in the near-critical
           region and can be the best choice for applications with
           super-critical or near-critical states.</li>
       </ol>
       <p>
       The following quantities are always computed in Medium.BaseProperties:
       </p>
       <table border=1 cellspacing=0 cellpadding=2>
         <tr><td valign=\"top\"><b>Variable</b></td>
             <td valign=\"top\"><b>Unit</b></td>
             <td valign=\"top\"><b>Description</b></td></tr>
         <tr><td valign=\"top\">T</td>
             <td valign=\"top\">K</td>
             <td valign=\"top\">temperature</td></tr>
         <tr><td valign=\"top\">u</td>
             <td valign=\"top\">J/kg</td>
             <td valign=\"top\">specific internal energy</td></tr>
         <tr><td valign=\"top\">d</td>
             <td valign=\"top\">kg/m^3</td>
             <td valign=\"top\">density</td></tr>
         <tr><td valign=\"top\">p</td>
             <td valign=\"top\">Pa</td>
             <td valign=\"top\">pressure</td></tr>
         <tr><td valign=\"top\">h</td>
             <td valign=\"top\">J/kg</td>
             <td valign=\"top\">specific enthalpy</td></tr>
       </table>
       <p>
       In some cases additional medium properties are needed.
       A component that needs these optional properties has to call
       one of the following functions:
       </p>
       <table border=1 cellspacing=0 cellpadding=2>
         <tr><td valign=\"top\"><b>Function call</b></td>
             <td valign=\"top\"><b>Unit</b></td>
             <td valign=\"top\"><b>Description</b></td></tr>
         <tr><td valign=\"top\">Medium.dynamicViscosity(medium.state)</td>
             <td valign=\"top\">Pa.s</td>
             <td valign=\"top\">dynamic viscosity</td></tr>
         <tr><td valign=\"top\">Medium.thermalConductivity(medium.state)</td>
             <td valign=\"top\">W/(m.K)</td>
             <td valign=\"top\">thermal conductivity</td></tr>
         <tr><td valign=\"top\">Medium.prandtlNumber(medium.state)</td>
             <td valign=\"top\">1</td>
             <td valign=\"top\">Prandtl number</td></tr>
         <tr><td valign=\"top\">Medium.specificEntropy(medium.state)</td>
             <td valign=\"top\">J/(kg.K)</td>
             <td valign=\"top\">specific entropy</td></tr>
         <tr><td valign=\"top\">Medium.heatCapacity_cp(medium.state)</td>
             <td valign=\"top\">J/(kg.K)</td>
             <td valign=\"top\">specific heat capacity at constant pressure</td></tr>
         <tr><td valign=\"top\">Medium.heatCapacity_cv(medium.state)</td>
             <td valign=\"top\">J/(kg.K)</td>
             <td valign=\"top\">specific heat capacity at constant density</td></tr>
         <tr><td valign=\"top\">Medium.isentropicExponent(medium.state)</td>
             <td valign=\"top\">1</td>
             <td valign=\"top\">isentropic exponent</td></tr>
         <tr><td valign=\"top\">Medium.isentropicEnthalpy(pressure, medium.state)</td>
             <td valign=\"top\">J/kg</td>
             <td valign=\"top\">isentropic enthalpy</td></tr>
         <tr><td valign=\"top\">Medium.velocityOfSound(medium.state)</td>
             <td valign=\"top\">m/s</td>
             <td valign=\"top\">velocity of sound</td></tr>
         <tr><td valign=\"top\">Medium.isobaricExpansionCoefficient(medium.state)</td>
             <td valign=\"top\">1/K</td>
             <td valign=\"top\">isobaric expansion coefficient</td></tr>
         <tr><td valign=\"top\">Medium.isothermalCompressibility(medium.state)</td>
             <td valign=\"top\">1/Pa</td>
             <td valign=\"top\">isothermal compressibility</td></tr>
         <tr><td valign=\"top\">Medium.density_derp_h(medium.state)</td>
             <td valign=\"top\">kg/(m3.Pa)</td>
             <td valign=\"top\">derivative of density by pressure at constant enthalpy</td></tr>
         <tr><td valign=\"top\">Medium.density_derh_p(medium.state)</td>
             <td valign=\"top\">kg2/(m3.J)</td>
             <td valign=\"top\">derivative of density by enthalpy at constant pressure</td></tr>
         <tr><td valign=\"top\">Medium.density_derp_T(medium.state)</td>
             <td valign=\"top\">kg/(m3.Pa)</td>
             <td valign=\"top\">derivative of density by pressure at constant temperature</td></tr>
         <tr><td valign=\"top\">Medium.density_derT_p(medium.state)</td>
             <td valign=\"top\">kg/(m3.K)</td>
             <td valign=\"top\">derivative of density by temperature at constant pressure</td></tr>
         <tr><td valign=\"top\">Medium.density_derX(medium.state)</td>
             <td valign=\"top\">kg/m3</td>
             <td valign=\"top\">derivative of density by mass fraction</td></tr>
         <tr><td valign=\"top\">Medium.molarMass(medium.state)</td>
             <td valign=\"top\">kg/mol</td>
             <td valign=\"top\">molar mass</td></tr>
       </table>
       <p>More details are given in
       <a href=\"modelica://Modelica.Media.UsersGuide.MediumUsage.OptionalProperties\">
       Modelica.Media.UsersGuide.MediumUsage.OptionalProperties</a>.

       Many additional optional functions are defined to compute properties of
       saturated media, either liquid (bubble point) or vapour (dew point).
       The argument to such functions is a SaturationProperties record, which can be
       set starting from either the saturation pressure or the saturation temperature.
       With reference to a model defining a pressure p, a temperature T, and a
       SaturationProperties record sat, the following functions are provided:
       </p>
       <table border=1 cellspacing=0 cellpadding=2>
         <tr><td valign=\"top\"><b>Function call</b></td>
             <td valign=\"top\"><b>Unit</b></td>
             <td valign=\"top\"><b>Description</b></td></tr>
         <tr><td valign=\"top\">Medium.saturationPressure(T)</td>
             <td valign=\"top\">Pa</td>
             <td valign=\"top\">Saturation pressure at temperature T</td></tr>
         <tr><td valign=\"top\">Medium.saturationTemperature(p)</td>
             <td valign=\"top\">K</td>
             <td valign=\"top\">Saturation temperature at pressure p</td></tr>
         <tr><td valign=\"top\">Medium.saturationTemperature_derp(p)</td>
             <td valign=\"top\">K/Pa</td>
             <td valign=\"top\">Derivative of saturation temperature with respect to pressure</td></tr>
         <tr><td valign=\"top\">Medium.bubbleEnthalpy(sat)</td>
             <td valign=\"top\">J/kg</td>
             <td valign=\"top\">Specific enthalpy at bubble point</td></tr>
         <tr><td valign=\"top\">Medium.dewEnthalpy(sat)</td>
             <td valign=\"top\">J/kg</td>
             <td valign=\"top\">Specific enthalpy at dew point</td></tr>
         <tr><td valign=\"top\">Medium.bubbleEntropy(sat)</td>
             <td valign=\"top\">J/(kg.K)</td>
             <td valign=\"top\">Specific entropy at bubble point</td></tr>
         <tr><td valign=\"top\">Medium.dewEntropy(sat)</td>
             <td valign=\"top\">J/(kg.K)</td>
             <td valign=\"top\">Specific entropy at dew point</td></tr>
         <tr><td valign=\"top\">Medium.bubbleDensity(sat)</td>
             <td valign=\"top\">kg/m3</td>
             <td valign=\"top\">Density at bubble point</td></tr>
         <tr><td valign=\"top\">Medium.dewDensity(sat)</td>
             <td valign=\"top\">kg/m3</td>
             <td valign=\"top\">Density at dew point</td></tr>
         <tr><td valign=\"top\">Medium.dBubbleDensity_dPressure(sat)</td>
             <td valign=\"top\">kg/(m3.Pa)</td>
             <td valign=\"top\">Derivative of density at bubble point with respect to pressure</td></tr>
         <tr><td valign=\"top\">Medium.dDewDensity_dPressure(sat)</td>
             <td valign=\"top\">kg/(m3.Pa)</td>
             <td valign=\"top\">Derivative of density at dew point with respect to pressure</td></tr>
         <tr><td valign=\"top\">Medium.dBubbleEnthalpy_dPressure(sat)</td>
             <td valign=\"top\">J/(kg.Pa)</td>
             <td valign=\"top\">Derivative of specific enthalpy at bubble point with respect to pressure</td></tr>
         <tr><td valign=\"top\">Medium.dDewEnthalpy_dPressure(sat)</td>
             <td valign=\"top\">J/(kg.Pa)</td>
             <td valign=\"top\">Derivative of specific enthalpy at dew point with respect to pressure</td></tr>
         <tr><td valign=\"top\">Medium.surfaceTension(sat)</td>
             <td valign=\"top\">N/m</td>
             <td valign=\"top\">Surface tension between liquid and vapour phase</td></tr>
       </table>
       <p>Details on usage and some examples are given in:
       <a href=\"modelica://Modelica.Media.UsersGuide.MediumUsage.TwoPhase\">
       Modelica.Media.UsersGuide.MediumUsage.TwoPhase</a>.
       </p>
       <p>Many further properties can be computed. Using the well-known Bridgman's Tables,
       all first partial derivatives of the standard thermodynamic variables can be computed easily.
       </p>
       <p>
       The documentation of the IAPWS/IF97 steam properties can be freely
       distributed with computer implementations and are included here
       (in directory Modelica/Resources/Documentation/Media/Water/IF97documentation):
       </p>
       <ul>
       <li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/IF97.pdf\">IF97.pdf</a> The standards document for the main part of the IF97.</li>
       <li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/Back3.pdf\">Back3.pdf</a> The backwards equations for region 3.</li>
       <li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/crits.pdf\">crits.pdf</a> The critical point data.</li>
       <li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/meltsub.pdf\">meltsub.pdf</a> The melting- and sublimation line formulation (not implemented)</li>
       <li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/surf.pdf\">surf.pdf</a> The surface tension standard definition</li>
       <li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/thcond.pdf\">thcond.pdf</a> The thermal conductivity standard definition</li>
       <li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/visc.pdf\">visc.pdf</a> The viscosity standard definition</li>
       </ul>
       </html>"));
    end Water;
    annotation(preferredView = "info", Documentation(info = "<HTML>
     <p>
     This library contains <a href=\"modelica://Modelica.Media.Interfaces\">interface</a>
     definitions for media and the following <b>property</b> models for
     single and multiple substance fluids with one and multiple phases:
     </p>
     <ul>
     <li> <a href=\"modelica://Modelica.Media.IdealGases\">Ideal gases:</a><br>
          1241 high precision gas models based on the
          NASA Glenn coefficients, plus ideal gas mixture models based
          on the same data.</li>
     <li> <a href=\"modelica://Modelica.Media.Water\">Water models:</a><br>
          ConstantPropertyLiquidWater, WaterIF97 (high precision
          water model according to the IAPWS/IF97 standard)</li>
     <li> <a href=\"modelica://Modelica.Media.Air\">Air models:</a><br>
          SimpleAir, DryAirNasa, ReferenceAir, MoistAir, ReferenceMoistAir.</li>
     <li> <a href=\"modelica://Modelica.Media.Incompressible\">
          Incompressible media:</a><br>
          TableBased incompressible fluid models (properties are defined by tables rho(T),
          HeatCapacity_cp(T), etc.)</li>
     <li> <a href=\"modelica://Modelica.Media.CompressibleLiquids\">
          Compressible liquids:</a><br>
          Simple liquid models with linear compressibility</li>
     <li> <a href=\"modelica://Modelica.Media.R134a\">Refrigerant Tetrafluoroethane (R134a)</a>.</li>
     </ul>
     <p>
     The following parts are useful, when newly starting with this library:
     <ul>
     <li> <a href=\"modelica://Modelica.Media.UsersGuide\">Modelica.Media.UsersGuide</a>.</li>
     <li> <a href=\"modelica://Modelica.Media.UsersGuide.MediumUsage\">Modelica.Media.UsersGuide.MediumUsage</a>
          describes how to use a medium model in a component model.</li>
     <li> <a href=\"modelica://Modelica.Media.UsersGuide.MediumDefinition\">
          Modelica.Media.UsersGuide.MediumDefinition</a>
          describes how a new fluid medium model has to be implemented.</li>
     <li> <a href=\"modelica://Modelica.Media.UsersGuide.ReleaseNotes\">Modelica.Media.UsersGuide.ReleaseNotes</a>
          summarizes the changes of the library releases.</li>
     <li> <a href=\"modelica://Modelica.Media.Examples\">Modelica.Media.Examples</a>
          contains examples that demonstrate the usage of this library.</li>
     </ul>
     <p>
     Copyright &copy; 1998-2013, Modelica Association.
     </p>
     <p>
     <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
     </p>
     </HTML>", revisions = "<html>
     <ul>
     <li><i>May 16, 2013</i> by Stefan Wischhusen (XRG Simulation):<br/>
         Added new media models Air.ReferenceMoistAir, Air.ReferenceAir, R134a.</li>
     <li><i>May 25, 2011</i> by Francesco Casella:<br/>Added min/max attributes to Water, TableBased, MixtureGasNasa, SimpleAir and MoistAir local types.</li>
     <li><i>May 25, 2011</i> by Stefan Wischhusen:<br/>Added individual settings for polynomial fittings of properties.</li>
     </ul>
     </html>"), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-76, -80}, {-62, -30}, {-32, 40}, {4, 66}, {48, 66}, {73, 45}, {62, -8}, {48, -50}, {38, -80}}, color = {64, 64, 64}, smooth = Smooth.Bezier), Line(points = {{-40, 20}, {68, 20}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{-40, 20}, {-44, 88}, {-44, 88}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{68, 20}, {86, -58}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{-60, -28}, {56, -28}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{-60, -28}, {-74, 84}, {-74, 84}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{56, -28}, {70, -80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{-76, -80}, {38, -80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{-76, -80}, {-94, -16}, {-94, -16}}, color = {175, 175, 175}, smooth = Smooth.None)}));
  end Media;

  package Math  "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices"
    extends Modelica.Icons.Package;

    package Icons  "Icons for Math"
      extends Modelica.Icons.IconsPackage;

      partial function AxisLeft  "Basic icon for mathematical function with y-axis on left side"  annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-80, 68}}, color = {192, 192, 192}), Polygon(points = {{-80, 90}, {-88, 68}, {-72, 68}, {-80, 90}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Text(extent = {{-150, 150}, {150, 110}}, textString = "%name", lineColor = {0, 0, 255})}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-80, 80}, {-88, 80}}, color = {95, 95, 95}), Line(points = {{-80, -80}, {-88, -80}}, color = {95, 95, 95}), Line(points = {{-80, -90}, {-80, 84}}, color = {95, 95, 95}), Text(extent = {{-75, 104}, {-55, 84}}, lineColor = {95, 95, 95}, textString = "y"), Polygon(points = {{-80, 98}, {-86, 82}, {-74, 82}, {-80, 98}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
        <p>
        Icon for a mathematical function, consisting of an y-axis on the left side.
        It is expected, that an x-axis is added and a plot of the function.
        </p>
        </html>")); end AxisLeft;

      partial function AxisCenter  "Basic icon for mathematical function with y-axis in the center"  annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{0, -80}, {0, 68}}, color = {192, 192, 192}), Polygon(points = {{0, 90}, {-8, 68}, {8, 68}, {0, 90}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Text(extent = {{-150, 150}, {150, 110}}, textString = "%name", lineColor = {0, 0, 255})}), Diagram(graphics = {Line(points = {{0, 80}, {-8, 80}}, color = {95, 95, 95}), Line(points = {{0, -80}, {-8, -80}}, color = {95, 95, 95}), Line(points = {{0, -90}, {0, 84}}, color = {95, 95, 95}), Text(extent = {{5, 104}, {25, 84}}, lineColor = {95, 95, 95}, textString = "y"), Polygon(points = {{0, 98}, {-6, 82}, {6, 82}, {0, 98}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
        <p>
        Icon for a mathematical function, consisting of an y-axis in the middle.
        It is expected, that an x-axis is added and a plot of the function.
        </p>
        </html>")); end AxisCenter;
    end Icons;

    function asin  "Inverse sine (-1 <= u <= 1)"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output .Modelica.SIunits.Angle y;
      external "builtin" y = asin(u);
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -72.8}, {-77.6, -67.5}, {-73.6, -59.4}, {-66.3, -49.8}, {-53.5, -37.3}, {-30.2, -19.7}, {37.4, 24.8}, {57.5, 40.8}, {68.7, 52.7}, {75.2, 62.2}, {77.6, 67.5}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-88, 78}, {-16, 30}}, lineColor = {192, 192, 192}, textString = "asin")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-40, -72}, {-15, -88}}, textString = "-pi/2", lineColor = {0, 0, 255}), Text(extent = {{-38, 88}, {-13, 72}}, textString = " pi/2", lineColor = {0, 0, 255}), Text(extent = {{68, -9}, {88, -29}}, textString = "+1", lineColor = {0, 0, 255}), Text(extent = {{-90, 21}, {-70, 1}}, textString = "-1", lineColor = {0, 0, 255}), Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{98, 0}, {82, 6}, {82, -6}, {98, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -72.8}, {-77.6, -67.5}, {-73.6, -59.4}, {-66.3, -49.8}, {-53.5, -37.3}, {-30.2, -19.7}, {37.4, 24.8}, {57.5, 40.8}, {68.7, 52.7}, {75.2, 62.2}, {77.6, 67.5}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{82, 24}, {102, 4}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {86, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{80, 86}, {80, -10}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
       <p>
       This function returns y = asin(u), with -1 &le; u &le; +1:
       </p>

       <p>
       <img src=\"modelica://Modelica/Resources/Images/Math/asin.png\">
       </p>
       </html>"));
    end asin;

    function acos  "Inverse cosine (-1 <= u <= 1)"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output .Modelica.SIunits.Angle y;
      external "builtin" y = acos(u);
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, -80}, {68, -80}}, color = {192, 192, 192}), Polygon(points = {{90, -80}, {68, -72}, {68, -88}, {90, -80}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, 80}, {-79.2, 72.8}, {-77.6, 67.5}, {-73.6, 59.4}, {-66.3, 49.8}, {-53.5, 37.3}, {-30.2, 19.7}, {37.4, -24.8}, {57.5, -40.8}, {68.7, -52.7}, {75.2, -62.2}, {77.6, -67.5}, {80, -80}}, color = {0, 0, 0}), Text(extent = {{-86, -14}, {-14, -62}}, lineColor = {192, 192, 192}, textString = "acos")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, -80}, {84, -80}}, color = {95, 95, 95}), Polygon(points = {{98, -80}, {82, -74}, {82, -86}, {98, -80}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, 80}, {-79.2, 72.8}, {-77.6, 67.5}, {-73.6, 59.4}, {-66.3, 49.8}, {-53.5, 37.3}, {-30.2, 19.7}, {37.4, -24.8}, {57.5, -40.8}, {68.7, -52.7}, {75.2, -62.2}, {77.6, -67.5}, {80, -80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-30, 88}, {-5, 72}}, textString = " pi", lineColor = {0, 0, 255}), Text(extent = {{-94, -57}, {-74, -77}}, textString = "-1", lineColor = {0, 0, 255}), Text(extent = {{60, -81}, {80, -101}}, textString = "+1", lineColor = {0, 0, 255}), Text(extent = {{82, -56}, {102, -76}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{-2, 80}, {84, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{80, 82}, {80, -86}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
       <p>
       This function returns y = acos(u), with -1 &le; u &le; +1:
       </p>

       <p>
       <img src=\"modelica://Modelica/Resources/Images/Math/acos.png\">
       </p>
       </html>"));
    end acos;

    function exp  "Exponential, base e"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output Real y;
      external "builtin" y = exp(u);
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, -80.3976}, {68, -80.3976}}, color = {192, 192, 192}), Polygon(points = {{90, -80.3976}, {68, -72.3976}, {68, -88.3976}, {90, -80.3976}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-31, -77.9}, {-6.03, -74}, {10.9, -68.4}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.1, 18.6}, {72, 38.2}, {76, 57.6}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-86, 50}, {-14, 2}}, lineColor = {192, 192, 192}, textString = "exp")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, -80.3976}, {84, -80.3976}}, color = {95, 95, 95}), Polygon(points = {{98, -80.3976}, {82, -74.3976}, {82, -86.3976}, {98, -80.3976}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-31, -77.9}, {-6.03, -74}, {10.9, -68.4}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.1, 18.6}, {72, 38.2}, {76, 57.6}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-31, 72}, {-11, 88}}, textString = "20", lineColor = {0, 0, 255}), Text(extent = {{-92, -81}, {-72, -101}}, textString = "-3", lineColor = {0, 0, 255}), Text(extent = {{66, -81}, {86, -101}}, textString = "3", lineColor = {0, 0, 255}), Text(extent = {{2, -69}, {22, -89}}, textString = "1", lineColor = {0, 0, 255}), Text(extent = {{78, -54}, {98, -74}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {88, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{80, 84}, {80, -84}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
       <p>
       This function returns y = exp(u), with -&infin; &lt; u &lt; &infin;:
       </p>

       <p>
       <img src=\"modelica://Modelica/Resources/Images/Math/exp.png\">
       </p>
       </html>"));
    end exp;

    function log  "Natural (base e) logarithm (u shall be > 0)"
      extends Modelica.Math.Icons.AxisLeft;
      input Real u;
      output Real y;
      external "builtin" y = log(u);
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -50.6}, {-78.4, -37}, {-77.6, -28}, {-76.8, -21.3}, {-75.2, -11.4}, {-72.8, -1.31}, {-69.5, 8.08}, {-64.7, 17.9}, {-57.5, 28}, {-47, 38.1}, {-31.8, 48.1}, {-10.1, 58}, {22.1, 68}, {68.7, 78.1}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-6, -24}, {66, -72}}, lineColor = {192, 192, 192}, textString = "log")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{100, 0}, {84, 6}, {84, -6}, {100, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-78, -80}, {-77.2, -50.6}, {-76.4, -37}, {-75.6, -28}, {-74.8, -21.3}, {-73.2, -11.4}, {-70.8, -1.31}, {-67.5, 8.08}, {-62.7, 17.9}, {-55.5, 28}, {-45, 38.1}, {-29.8, 48.1}, {-8.1, 58}, {24.1, 68}, {70.7, 78.1}, {82, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-105, 72}, {-85, 88}}, textString = "3", lineColor = {0, 0, 255}), Text(extent = {{60, -3}, {80, -23}}, textString = "20", lineColor = {0, 0, 255}), Text(extent = {{-78, -7}, {-58, -27}}, textString = "1", lineColor = {0, 0, 255}), Text(extent = {{84, 26}, {104, 6}}, lineColor = {95, 95, 95}, textString = "u"), Text(extent = {{-100, 9}, {-80, -11}}, textString = "0", lineColor = {0, 0, 255}), Line(points = {{-80, 80}, {84, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{82, 82}, {82, -6}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
       <p>
       This function returns y = log(10) (the natural logarithm of u),
       with u &gt; 0:
       </p>

       <p>
       <img src=\"modelica://Modelica/Resources/Images/Math/log.png\">
       </p>
       </html>"));
    end log;
    annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-80, 0}, {-68.7, 34.2}, {-61.5, 53.1}, {-55.1, 66.4}, {-49.4, 74.6}, {-43.8, 79.1}, {-38.2, 79.8}, {-32.6, 76.6}, {-26.9, 69.7}, {-21.3, 59.4}, {-14.9, 44.1}, {-6.83, 21.2}, {10.1, -30.8}, {17.3, -50.2}, {23.7, -64.2}, {29.3, -73.1}, {35, -78.4}, {40.6, -80}, {46.2, -77.6}, {51.9, -71.5}, {57.5, -61.9}, {63.9, -47.2}, {72, -24.8}, {80, 0}}, color = {0, 0, 0}, smooth = Smooth.Bezier)}), Documentation(info = "<HTML>
     <p>
     This package contains <b>basic mathematical functions</b> (such as sin(..)),
     as well as functions operating on
     <a href=\"modelica://Modelica.Math.Vectors\">vectors</a>,
     <a href=\"modelica://Modelica.Math.Matrices\">matrices</a>,
     <a href=\"modelica://Modelica.Math.Nonlinear\">nonlinear functions</a>, and
     <a href=\"modelica://Modelica.Math.BooleanVectors\">Boolean vectors</a>.
     </p>

     <dl>
     <dt><b>Main Authors:</b>
     <dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and
         Marcus Baur<br>
         Deutsches Zentrum f&uuml;r Luft und Raumfahrt e.V. (DLR)<br>
         Institut f&uuml;r Robotik und Mechatronik<br>
         Postfach 1116<br>
         D-82230 Wessling<br>
         Germany<br>
         email: <A HREF=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</A><br>
     </dl>

     <p>
     Copyright &copy; 1998-2013, Modelica Association and DLR.
     </p>
     <p>
     <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
     </p>
     </html>", revisions = "<html>
     <ul>
     <li><i>October 21, 2002</i>
            by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
            and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
            Function tempInterpol2 added.</li>
     <li><i>Oct. 24, 1999</i>
            by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
            Icons for icon and diagram level introduced.</li>
     <li><i>June 30, 1999</i>
            by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
            Realized.</li>
     </ul>

     </html>"));
  end Math;

  package Constants  "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)"
    extends Modelica.Icons.Package;
    final constant Real pi = 2 * Math.asin(1.0);
    final constant Real eps = ModelicaServices.Machine.eps "Biggest number such that 1.0 + eps = 1.0";
    final constant Real small = ModelicaServices.Machine.small "Smallest number such that small and -small are representable on the machine";
    final constant Real inf = ModelicaServices.Machine.inf "Biggest Real number such that inf and -inf are representable on the machine";
    final constant .Modelica.SIunits.Velocity c = 299792458 "Speed of light in vacuum";
    final constant .Modelica.SIunits.Acceleration g_n = 9.80665 "Standard acceleration of gravity on earth";
    final constant Real R(final unit = "J/(mol.K)") = 8.314472 "Molar gas constant";
    final constant Real mue_0(final unit = "N/A2") = 4 * pi * 0.0000001 "Magnetic constant";
    final constant .Modelica.SIunits.Conversions.NonSIunits.Temperature_degC T_zero = -273.15 "Absolute zero temperature";
    annotation(Documentation(info = "<html>
     <p>
     This package provides often needed constants from mathematics, machine
     dependent constants and constants from nature. The latter constants
     (name, value, description) are from the following source:
     </p>

     <dl>
     <dt>Peter J. Mohr and Barry N. Taylor (1999):</dt>
     <dd><b>CODATA Recommended Values of the Fundamental Physical Constants: 1998</b>.
         Journal of Physical and Chemical Reference Data, Vol. 28, No. 6, 1999 and
         Reviews of Modern Physics, Vol. 72, No. 2, 2000. See also <a href=
     \"http://physics.nist.gov/cuu/Constants/\">http://physics.nist.gov/cuu/Constants/</a></dd>
     </dl>

     <p>CODATA is the Committee on Data for Science and Technology.</p>

     <dl>
     <dt><b>Main Author:</b></dt>
     <dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a><br>
         Deutsches Zentrum f&uuml;r Luft und Raumfahrt e. V. (DLR)<br>
         Oberpfaffenhofen<br>
         Postfach 11 16<br>
         D-82230 We&szlig;ling<br>
         email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a></dd>
     </dl>

     <p>
     Copyright &copy; 1998-2013, Modelica Association and DLR.
     </p>
     <p>
     <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
     </p>
     </html>", revisions = "<html>
     <ul>
     <li><i>Nov 8, 2004</i>
            by <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
            Constants updated according to 2002 CODATA values.</li>
     <li><i>Dec 9, 1999</i>
            by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
            Constants updated according to 1998 CODATA values. Using names, values
            and description text from this source. Included magnetic and
            electric constant.</li>
     <li><i>Sep 18, 1999</i>
            by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
            Constants eps, inf, small introduced.</li>
     <li><i>Nov 15, 1997</i>
            by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
            Realized.</li>
     </ul>
     </html>"), Icon(coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(origin = {-9.2597, 25.6673}, fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{48.017, 11.336}, {48.017, 11.336}, {10.766, 11.336}, {-25.684, 10.95}, {-34.944, -15.111}, {-34.944, -15.111}, {-32.298, -15.244}, {-32.298, -15.244}, {-22.112, 0.168}, {11.292, 0.234}, {48.267, -0.097}, {48.267, -0.097}}, smooth = Smooth.Bezier), Polygon(origin = {-19.9923, -8.3993}, fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{3.239, 37.343}, {3.305, 37.343}, {-0.399, 2.683}, {-16.936, -20.071}, {-7.808, -28.604}, {6.811, -22.519}, {9.986, 37.145}, {9.986, 37.145}}, smooth = Smooth.Bezier), Polygon(origin = {23.753, -11.5422}, fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-10.873, 41.478}, {-10.873, 41.478}, {-14.048, -4.162}, {-9.352, -24.8}, {7.912, -24.469}, {16.247, 0.27}, {16.247, 0.27}, {13.336, 0.071}, {13.336, 0.071}, {7.515, -9.983}, {-3.134, -7.271}, {-2.671, 41.214}, {-2.671, 41.214}}, smooth = Smooth.Bezier)}));
  end Constants;

  package Icons  "Library of icons"
    extends Icons.Package;

    partial package Package  "Icon for standard packages"  annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {200, 200, 200}, fillColor = {248, 248, 248}, fillPattern = FillPattern.HorizontalCylinder, extent = {{-100.0, -100.0}, {100.0, 100.0}}, radius = 25.0), Rectangle(lineColor = {128, 128, 128}, fillPattern = FillPattern.None, extent = {{-100.0, -100.0}, {100.0, 100.0}}, radius = 25.0)}), Documentation(info = "<html>
      <p>Standard package icon.</p>
      </html>")); end Package;

    partial package VariantsPackage  "Icon for package containing variants"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(origin = {10.0, 10.0}, fillColor = {76, 76, 76}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-80.0, -80.0}, {-20.0, -20.0}}), Ellipse(origin = {10.0, 10.0}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{0.0, -80.0}, {60.0, -20.0}}), Ellipse(origin = {10.0, 10.0}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{0.0, 0.0}, {60.0, 60.0}}), Ellipse(origin = {10.0, 10.0}, lineColor = {128, 128, 128}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, extent = {{-80.0, 0.0}, {-20.0, 60.0}})}), Documentation(info = "<html>
       <p>This icon shall be used for a package/library that contains several variants of one components.</p>
       </html>"));
    end VariantsPackage;

    partial package InterfacesPackage  "Icon for packages containing interfaces"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {20.0, 0.0}, lineColor = {64, 64, 64}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-10.0, 70.0}, {10.0, 70.0}, {40.0, 20.0}, {80.0, 20.0}, {80.0, -20.0}, {40.0, -20.0}, {10.0, -70.0}, {-10.0, -70.0}}), Polygon(fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-100.0, 20.0}, {-60.0, 20.0}, {-30.0, 70.0}, {-10.0, 70.0}, {-10.0, -70.0}, {-30.0, -70.0}, {-60.0, -20.0}, {-100.0, -20.0}})}), Documentation(info = "<html>
       <p>This icon indicates packages containing interfaces.</p>
       </html>"));
    end InterfacesPackage;

    partial package SourcesPackage  "Icon for packages containing sources"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {23.3333, 0.0}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-23.333, 30.0}, {46.667, 0.0}, {-23.333, -30.0}}), Rectangle(fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-70, -4.5}, {0, 4.5}})}), Documentation(info = "<html>
       <p>This icon indicates a package which contains sources.</p>
       </html>"));
    end SourcesPackage;

    partial package UtilitiesPackage  "Icon for utility packages"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(origin = {1.3835, -4.1418}, rotation = 45.0, fillColor = {64, 64, 64}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-15.0, 93.333}, {-15.0, 68.333}, {0.0, 58.333}, {15.0, 68.333}, {15.0, 93.333}, {20.0, 93.333}, {25.0, 83.333}, {25.0, 58.333}, {10.0, 43.333}, {10.0, -41.667}, {25.0, -56.667}, {25.0, -76.667}, {10.0, -91.667}, {0.0, -91.667}, {0.0, -81.667}, {5.0, -81.667}, {15.0, -71.667}, {15.0, -61.667}, {5.0, -51.667}, {-5.0, -51.667}, {-15.0, -61.667}, {-15.0, -71.667}, {-5.0, -81.667}, {0.0, -81.667}, {0.0, -91.667}, {-10.0, -91.667}, {-25.0, -76.667}, {-25.0, -56.667}, {-10.0, -41.667}, {-10.0, 43.333}, {-25.0, 58.333}, {-25.0, 83.333}, {-20.0, 93.333}}), Polygon(origin = {10.1018, 5.218}, rotation = -45.0, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-15.0, 87.273}, {15.0, 87.273}, {20.0, 82.273}, {20.0, 27.273}, {10.0, 17.273}, {10.0, 7.273}, {20.0, 2.273}, {20.0, -2.727}, {5.0, -2.727}, {5.0, -77.727}, {10.0, -87.727}, {5.0, -112.727}, {-5.0, -112.727}, {-10.0, -87.727}, {-5.0, -77.727}, {-5.0, -2.727}, {-20.0, -2.727}, {-20.0, 2.273}, {-10.0, 7.273}, {-10.0, 17.273}, {-20.0, 27.273}, {-20.0, 82.273}})}), Documentation(info = "<html>
       <p>This icon indicates a package containing utility classes.</p>
       </html>"));
    end UtilitiesPackage;

    partial package IconsPackage  "Icon for packages containing icons"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {-8.167, -17}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-15.833, 20.0}, {-15.833, 30.0}, {14.167, 40.0}, {24.167, 20.0}, {4.167, -30.0}, {14.167, -30.0}, {24.167, -30.0}, {24.167, -40.0}, {-5.833, -50.0}, {-15.833, -30.0}, {4.167, 20.0}, {-5.833, 20.0}}, smooth = Smooth.Bezier, lineColor = {0, 0, 0}), Ellipse(origin = {-0.5, 56.5}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-12.5, -12.5}, {12.5, 12.5}}, lineColor = {0, 0, 0})}));
    end IconsPackage;

    partial package MaterialPropertiesPackage  "Icon for package containing property classes"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(lineColor = {102, 102, 102}, fillColor = {204, 204, 204}, pattern = LinePattern.None, fillPattern = FillPattern.Sphere, extent = {{-60.0, -60.0}, {60.0, 60.0}})}), Documentation(info = "<html>
       <p>This icon indicates a package that contains properties</p>
       </html>"));
    end MaterialPropertiesPackage;

    partial function Function  "Icon for functions"  annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Text(lineColor = {0, 0, 255}, extent = {{-150, 105}, {150, 145}}, textString = "%name"), Ellipse(lineColor = {108, 88, 49}, fillColor = {255, 215, 136}, fillPattern = FillPattern.Solid, extent = {{-100, -100}, {100, 100}}), Text(lineColor = {108, 88, 49}, extent = {{-90.0, -90.0}, {90.0, 90.0}}, textString = "f")}), Documentation(info = "<html>
      <p>This icon indicates Modelica functions.</p>
      </html>")); end Function;

    partial record Record  "Icon for records"  annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(lineColor = {0, 0, 255}, extent = {{-150, 60}, {150, 100}}, textString = "%name"), Rectangle(origin = {0.0, -25.0}, lineColor = {64, 64, 64}, fillColor = {255, 215, 136}, fillPattern = FillPattern.Solid, extent = {{-100.0, -75.0}, {100.0, 75.0}}, radius = 25.0), Line(points = {{-100.0, 0.0}, {100.0, 0.0}}, color = {64, 64, 64}), Line(origin = {0.0, -50.0}, points = {{-100.0, 0.0}, {100.0, 0.0}}, color = {64, 64, 64}), Line(origin = {0.0, -25.0}, points = {{0.0, 75.0}, {0.0, -75.0}}, color = {64, 64, 64})}), Documentation(info = "<html>
      <p>
      This icon is indicates a record.
      </p>
      </html>")); end Record;
    annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {-8.167, -17}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-15.833, 20.0}, {-15.833, 30.0}, {14.167, 40.0}, {24.167, 20.0}, {4.167, -30.0}, {14.167, -30.0}, {24.167, -30.0}, {24.167, -40.0}, {-5.833, -50.0}, {-15.833, -30.0}, {4.167, 20.0}, {-5.833, 20.0}}, smooth = Smooth.Bezier, lineColor = {0, 0, 0}), Ellipse(origin = {-0.5, 56.5}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-12.5, -12.5}, {12.5, 12.5}}, lineColor = {0, 0, 0})}), Documentation(info = "<html>
     <p>This package contains definitions for the graphical layout of components which may be used in different libraries. The icons can be utilized by inheriting them in the desired class using &quot;extends&quot; or by directly copying the &quot;icon&quot; layer. </p>

     <h4>Main Authors:</h4>

     <dl>
     <dt><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a></dt>
         <dd>Deutsches Zentrum fuer Luft und Raumfahrt e.V. (DLR)</dd>
         <dd>Oberpfaffenhofen</dd>
         <dd>Postfach 1116</dd>
         <dd>D-82230 Wessling</dd>
         <dd>email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a></dd>
     <dt>Christian Kral</dt>
         <dd><a href=\"http://www.ait.ac.at/\">Austrian Institute of Technology, AIT</a></dd>
         <dd>Mobility Department</dd><dd>Giefinggasse 2</dd>
         <dd>1210 Vienna, Austria</dd>
         <dd>email: <a href=\"mailto:dr.christian.kral@gmail.com\">dr.christian.kral@gmail.com</a></dd>
     <dt>Johan Andreasson</dt>
         <dd><a href=\"http://www.modelon.se/\">Modelon AB</a></dd>
         <dd>Ideon Science Park</dd>
         <dd>22370 Lund, Sweden</dd>
         <dd>email: <a href=\"mailto:johan.andreasson@modelon.se\">johan.andreasson@modelon.se</a></dd>
     </dl>

     <p>Copyright &copy; 1998-2013, Modelica Association, DLR, AIT, and Modelon AB. </p>
     <p><i>This Modelica package is <b>free</b> software; it can be redistributed and/or modified under the terms of the <b>Modelica license</b>, see the license conditions and the accompanying <b>disclaimer</b> in <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a>.</i> </p>
     </html>"));
  end Icons;

  package SIunits  "Library of type and unit definitions based on SI units according to ISO 31-1992"
    extends Modelica.Icons.Package;

    package Icons  "Icons for SIunits"
      extends Modelica.Icons.IconsPackage;

      partial function Conversion  "Base icon for conversion functions"  annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {191, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{-90, 0}, {30, 0}}, color = {191, 0, 0}), Polygon(points = {{90, 0}, {30, 20}, {30, -20}, {90, 0}}, lineColor = {191, 0, 0}, fillColor = {191, 0, 0}, fillPattern = FillPattern.Solid), Text(extent = {{-115, 155}, {115, 105}}, textString = "%name", lineColor = {0, 0, 255})})); end Conversion;
    end Icons;

    package Conversions  "Conversion functions to/from non SI units and type definitions of non SI units"
      extends Modelica.Icons.Package;

      package NonSIunits  "Type definitions of non SI units"
        extends Modelica.Icons.Package;
        type Temperature_degC = Real(final quantity = "ThermodynamicTemperature", final unit = "degC") "Absolute temperature in degree Celsius (for relative temperature use SIunits.TemperatureDifference)" annotation(absoluteValue = true);
        type Pressure_bar = Real(final quantity = "Pressure", final unit = "bar") "Absolute pressure in bar";
        annotation(Documentation(info = "<HTML>
         <p>
         This package provides predefined types, such as <b>Angle_deg</b> (angle in
         degree), <b>AngularVelocity_rpm</b> (angular velocity in revolutions per
         minute) or <b>Temperature_degF</b> (temperature in degree Fahrenheit),
         which are in common use but are not part of the international standard on
         units according to ISO 31-1992 \"General principles concerning quantities,
         units and symbols\" and ISO 1000-1992 \"SI units and recommendations for
         the use of their multiples and of certain other units\".</p>
         <p>If possible, the types in this package should not be used. Use instead
         types of package Modelica.SIunits. For more information on units, see also
         the book of Francois Cardarelli <b>Scientific Unit Conversion - A
         Practical Guide to Metrication</b> (Springer 1997).</p>
         <p>Some units, such as <b>Temperature_degC/Temp_C</b> are both defined in
         Modelica.SIunits and in Modelica.Conversions.NonSIunits. The reason is that these
         definitions have been placed erroneously in Modelica.SIunits although they
         are not SIunits. For backward compatibility, these type definitions are
         still kept in Modelica.SIunits.</p>
         </html>"), Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}), graphics = {Text(origin = {15.0, 51.8518}, extent = {{-105.0, -86.8518}, {75.0, -16.8518}}, lineColor = {0, 0, 0}, textString = "[km/h]")}));
      end NonSIunits;

      function to_degC  "Convert from Kelvin to degCelsius"
        extends Modelica.SIunits.Icons.Conversion;
        input Temperature Kelvin "Kelvin value";
        output NonSIunits.Temperature_degC Celsius "Celsius value";
      algorithm
        Celsius := Kelvin + Modelica.Constants.T_zero;
        annotation(Inline = true, Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-20, 100}, {-100, 20}}, lineColor = {0, 0, 0}, textString = "K"), Text(extent = {{100, -20}, {20, -100}}, lineColor = {0, 0, 0}, textString = "degC")}));
      end to_degC;

      function from_degC  "Convert from degCelsius to Kelvin"
        extends Modelica.SIunits.Icons.Conversion;
        input NonSIunits.Temperature_degC Celsius "Celsius value";
        output Temperature Kelvin "Kelvin value";
      algorithm
        Kelvin := Celsius - Modelica.Constants.T_zero;
        annotation(Inline = true, Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-20, 100}, {-100, 20}}, lineColor = {0, 0, 0}, textString = "degC"), Text(extent = {{100, -20}, {20, -100}}, lineColor = {0, 0, 0}, textString = "K")}));
      end from_degC;

      function to_bar  "Convert from Pascal to bar"
        extends Modelica.SIunits.Icons.Conversion;
        input Pressure Pa "Pascal value";
        output NonSIunits.Pressure_bar bar "bar value";
      algorithm
        bar := Pa / 100000.0;
        annotation(Inline = true, Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-12, 100}, {-100, 56}}, lineColor = {0, 0, 0}, textString = "Pa"), Text(extent = {{98, -52}, {-4, -100}}, lineColor = {0, 0, 0}, textString = "bar")}));
      end to_bar;
      annotation(Documentation(info = "<HTML>
       <p>This package provides conversion functions from the non SI Units
       defined in package Modelica.SIunits.Conversions.NonSIunits to the
       corresponding SI Units defined in package Modelica.SIunits and vice
       versa. It is recommended to use these functions in the following
       way (note, that all functions have one Real input and one Real output
       argument):</p>
       <pre>
         <b>import</b> SI = Modelica.SIunits;
         <b>import</b> Modelica.SIunits.Conversions.*;
            ...
         <b>parameter</b> SI.Temperature     T   = from_degC(25);   // convert 25 degree Celsius to Kelvin
         <b>parameter</b> SI.Angle           phi = from_deg(180);   // convert 180 degree to radian
         <b>parameter</b> SI.AngularVelocity w   = from_rpm(3600);  // convert 3600 revolutions per minutes
                                                             // to radian per seconds
       </pre>

       </html>"));
    end Conversions;

    type Angle = Real(final quantity = "Angle", final unit = "rad", displayUnit = "deg");
    type Length = Real(final quantity = "Length", final unit = "m");
    type Position = Length;
    type Distance = Length(min = 0);
    type Radius = Length(min = 0);
    type Diameter = Length(min = 0);
    type Area = Real(final quantity = "Area", final unit = "m2");
    type Volume = Real(final quantity = "Volume", final unit = "m3");
    type Time = Real(final quantity = "Time", final unit = "s");
    type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
    type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
    type Mass = Real(quantity = "Mass", final unit = "kg", min = 0);
    type Density = Real(final quantity = "Density", final unit = "kg/m3", displayUnit = "g/cm3", min = 0.0);
    type SpecificVolume = Real(final quantity = "SpecificVolume", final unit = "m3/kg", min = 0.0);
    type Pressure = Real(final quantity = "Pressure", final unit = "Pa", displayUnit = "bar");
    type AbsolutePressure = Pressure(min = 0.0, nominal = 100000.0);
    type DynamicViscosity = Real(final quantity = "DynamicViscosity", final unit = "Pa.s", min = 0);
    type SurfaceTension = Real(final quantity = "SurfaceTension", final unit = "N/m");
    type Energy = Real(final quantity = "Energy", final unit = "J");
    type Power = Real(final quantity = "Power", final unit = "W");
    type MassFlowRate = Real(quantity = "MassFlowRate", final unit = "kg/s");
    type MomentumFlux = Real(final quantity = "MomentumFlux", final unit = "N");
    type ThermodynamicTemperature = Real(final quantity = "ThermodynamicTemperature", final unit = "K", min = 0.0, start = 288.15, nominal = 300, displayUnit = "degC") "Absolute temperature (use type TemperatureDifference for relative temperatures)" annotation(absoluteValue = true);
    type Temp_K = ThermodynamicTemperature;
    type Temperature = ThermodynamicTemperature;
    type RelativePressureCoefficient = Real(final quantity = "RelativePressureCoefficient", final unit = "1/K");
    type Compressibility = Real(final quantity = "Compressibility", final unit = "1/Pa");
    type IsothermalCompressibility = Compressibility;
    type ThermalConductivity = Real(final quantity = "ThermalConductivity", final unit = "W/(m.K)");
    type CoefficientOfHeatTransfer = Real(final quantity = "CoefficientOfHeatTransfer", final unit = "W/(m2.K)");
    type SpecificHeatCapacity = Real(final quantity = "SpecificHeatCapacity", final unit = "J/(kg.K)");
    type RatioOfSpecificHeatCapacities = Real(final quantity = "RatioOfSpecificHeatCapacities", final unit = "1");
    type Entropy = Real(final quantity = "Entropy", final unit = "J/K");
    type SpecificEntropy = Real(final quantity = "SpecificEntropy", final unit = "J/(kg.K)");
    type SpecificEnergy = Real(final quantity = "SpecificEnergy", final unit = "J/kg");
    type SpecificEnthalpy = SpecificEnergy;
    type DerDensityByEnthalpy = Real(final unit = "kg.s2/m5");
    type DerDensityByPressure = Real(final unit = "s2/m2");
    type DerEnthalpyByPressure = Real(final unit = "J.m.s2/kg2");
    type AmountOfSubstance = Real(final quantity = "AmountOfSubstance", final unit = "mol", min = 0);
    type MolarMass = Real(final quantity = "MolarMass", final unit = "kg/mol", min = 0);
    type MolarVolume = Real(final quantity = "MolarVolume", final unit = "m3/mol", min = 0);
    type MassFraction = Real(final quantity = "MassFraction", final unit = "1", min = 0, max = 1);
    type MoleFraction = Real(final quantity = "MoleFraction", final unit = "1", min = 0, max = 1);
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
    annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-66, 78}, {-66, -40}}, color = {64, 64, 64}, smooth = Smooth.None), Ellipse(extent = {{12, 36}, {68, -38}}, lineColor = {64, 64, 64}, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-74, 78}, {-66, -40}}, lineColor = {64, 64, 64}, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Polygon(points = {{-66, -4}, {-66, 6}, {-16, 56}, {-16, 46}, {-66, -4}}, lineColor = {64, 64, 64}, smooth = Smooth.None, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Polygon(points = {{-46, 16}, {-40, 22}, {-2, -40}, {-10, -40}, {-46, 16}}, lineColor = {64, 64, 64}, smooth = Smooth.None, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Ellipse(extent = {{22, 26}, {58, -28}}, lineColor = {64, 64, 64}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Polygon(points = {{68, 2}, {68, -46}, {64, -60}, {58, -68}, {48, -72}, {18, -72}, {18, -64}, {46, -64}, {54, -60}, {58, -54}, {60, -46}, {60, -26}, {64, -20}, {68, -6}, {68, 2}}, lineColor = {64, 64, 64}, smooth = Smooth.Bezier, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
     <p>This package provides predefined types, such as <i>Mass</i>,
     <i>Angle</i>, <i>Time</i>, based on the international standard
     on units, e.g.,
     </p>

     <pre>   <b>type</b> Angle = Real(<b>final</b> quantity = \"Angle\",
                          <b>final</b> unit     = \"rad\",
                          displayUnit    = \"deg\");
     </pre>

     <p>
     as well as conversion functions from non SI-units to SI-units
     and vice versa in subpackage
     <a href=\"modelica://Modelica.SIunits.Conversions\">Conversions</a>.
     </p>

     <p>
     For an introduction how units are used in the Modelica standard library
     with package SIunits, have a look at:
     <a href=\"modelica://Modelica.SIunits.UsersGuide.HowToUseSIunits\">How to use SIunits</a>.
     </p>

     <p>
     Copyright &copy; 1998-2013, Modelica Association and DLR.
     </p>
     <p>
     <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
     </p>
     </html>", revisions = "<html>
     <ul>
     <li><i>May 25, 2011</i> by Stefan Wischhusen:<br/>Added molar units for energy and enthalpy.</li>
     <li><i>Jan. 27, 2010</i> by Christian Kral:<br/>Added complex units.</li>
     <li><i>Dec. 14, 2005</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Add User&#39;;s Guide and removed &quot;min&quot; values for Resistance and Conductance.</li>
     <li><i>October 21, 2002</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br/>Added new package <b>Conversions</b>. Corrected typo <i>Wavelenght</i>.</li>
     <li><i>June 6, 2000</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Introduced the following new types<br/>type Temperature = ThermodynamicTemperature;<br/>types DerDensityByEnthalpy, DerDensityByPressure, DerDensityByTemperature, DerEnthalpyByPressure, DerEnergyByDensity, DerEnergyByPressure<br/>Attribute &quot;final&quot; removed from min and max values in order that these values can still be changed to narrow the allowed range of values.<br/>Quantity=&quot;Stress&quot; removed from type &quot;Stress&quot;, in order that a type &quot;Stress&quot; can be connected to a type &quot;Pressure&quot;.</li>
     <li><i>Oct. 27, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>New types due to electrical library: Transconductance, InversePotential, Damping.</li>
     <li><i>Sept. 18, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Renamed from SIunit to SIunits. Subpackages expanded, i.e., the SIunits package, does no longer contain subpackages.</li>
     <li><i>Aug 12, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Type &quot;Pressure&quot; renamed to &quot;AbsolutePressure&quot; and introduced a new type &quot;Pressure&quot; which does not contain a minimum of zero in order to allow convenient handling of relative pressure. Redefined BulkModulus as an alias to AbsolutePressure instead of Stress, since needed in hydraulics.</li>
     <li><i>June 29, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Bug-fix: Double definition of &quot;Compressibility&quot; removed and appropriate &quot;extends Heat&quot; clause introduced in package SolidStatePhysics to incorporate ThermodynamicTemperature.</li>
     <li><i>April 8, 1998</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and Astrid Jaschinski:<br/>Complete ISO 31 chapters realized.</li>
     <li><i>Nov. 15, 1997</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>:<br/>Some chapters realized.</li>
     </ul>
     </html>"));
  end SIunits;
  annotation(preferredView = "info", version = "3.2.1", versionBuild = 3, versionDate = "2013-08-14", dateModified = "2013-08-23 19:30:00Z", revisionId = "$Id:: package.mo 6954 2013-08-23 17:46:49Z #$", uses(Complex(version = "3.2.1"), ModelicaServices(version = "3.2.1")), conversion(noneFromVersion = "3.2", noneFromVersion = "3.1", noneFromVersion = "3.0.1", noneFromVersion = "3.0", from(version = "2.1", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2.1", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2.2", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos")), Icon(coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(origin = {-6.9888, 20.048}, fillColor = {0, 0, 0}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-93.0112, 10.3188}, {-93.0112, 10.3188}, {-73.011, 24.6}, {-63.011, 31.221}, {-51.219, 36.777}, {-39.842, 38.629}, {-31.376, 36.248}, {-25.819, 29.369}, {-24.232, 22.49}, {-23.703, 17.463}, {-15.501, 25.135}, {-6.24, 32.015}, {3.02, 36.777}, {15.191, 39.423}, {27.097, 37.306}, {32.653, 29.633}, {35.035, 20.108}, {43.501, 28.046}, {54.085, 35.19}, {65.991, 39.952}, {77.897, 39.688}, {87.422, 33.338}, {91.126, 21.696}, {90.068, 9.525}, {86.099, -1.058}, {79.749, -10.054}, {71.283, -21.431}, {62.816, -33.337}, {60.964, -32.808}, {70.489, -16.14}, {77.368, -2.381}, {81.072, 10.054}, {79.749, 19.05}, {72.605, 24.342}, {61.758, 23.019}, {49.587, 14.817}, {39.003, 4.763}, {29.214, -6.085}, {21.012, -16.669}, {13.339, -26.458}, {5.401, -36.777}, {-1.213, -46.037}, {-6.24, -53.446}, {-8.092, -52.387}, {-0.684, -40.746}, {5.401, -30.692}, {12.81, -17.198}, {19.424, -3.969}, {23.658, 7.938}, {22.335, 18.785}, {16.514, 23.283}, {8.047, 23.019}, {-1.478, 19.05}, {-11.267, 11.113}, {-19.734, 2.381}, {-29.259, -8.202}, {-38.519, -19.579}, {-48.044, -31.221}, {-56.511, -43.392}, {-64.449, -55.298}, {-72.386, -66.939}, {-77.678, -74.612}, {-79.53, -74.083}, {-71.857, -61.383}, {-62.861, -46.037}, {-52.278, -28.046}, {-44.869, -15.346}, {-38.784, -2.117}, {-35.344, 8.731}, {-36.403, 19.844}, {-42.488, 23.813}, {-52.013, 22.49}, {-60.744, 16.933}, {-68.947, 10.054}, {-76.884, 2.646}, {-93.0112, -12.1707}, {-93.0112, -12.1707}}, smooth = Smooth.Bezier), Ellipse(origin = {40.8208, -37.7602}, fillColor = {161, 0, 4}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-17.8562, -17.8563}, {17.8563, 17.8562}})}), Documentation(info = "<HTML>
   <p>
   Package <b>Modelica&reg;</b> is a <b>standardized</b> and <b>free</b> package
   that is developed together with the Modelica&reg; language from the
   Modelica Association, see
   <a href=\"https://www.Modelica.org\">https://www.Modelica.org</a>.
   It is also called <b>Modelica Standard Library</b>.
   It provides model components in many domains that are based on
   standardized interface definitions. Some typical examples are shown
   in the next figure:
   </p>

   <p>
   <img src=\"modelica://Modelica/Resources/Images/UsersGuide/ModelicaLibraries.png\">
   </p>

   <p>
   For an introduction, have especially a look at:
   </p>
   <ul>
   <li> <a href=\"modelica://Modelica.UsersGuide.Overview\">Overview</a>
     provides an overview of the Modelica Standard Library
     inside the <a href=\"modelica://Modelica.UsersGuide\">User's Guide</a>.</li>
   <li><a href=\"modelica://Modelica.UsersGuide.ReleaseNotes\">Release Notes</a>
    summarizes the changes of new versions of this package.</li>
   <li> <a href=\"modelica://Modelica.UsersGuide.Contact\">Contact</a>
     lists the contributors of the Modelica Standard Library.</li>
   <li> The <b>Examples</b> packages in the various libraries, demonstrate
     how to use the components of the corresponding sublibrary.</li>
   </ul>

   <p>
   This version of the Modelica Standard Library consists of
   </p>
   <ul>
   <li><b>1360</b> models and blocks, and</li>
   <li><b>1280</b> functions</li>
   </ul>
   <p>
   that are directly usable (= number of public, non-partial classes). It is fully compliant
   to <a href=\"https://www.modelica.org/documents/ModelicaSpec32Revision2.pdf\">Modelica Specification Version 3.2 Revision 2</a>
   and it has been tested with Modelica tools from different vendors.
   </p>

   <p>
   <b>Licensed by the Modelica Association under the Modelica License 2</b><br>
   Copyright &copy; 1998-2013, ABB, AIT, T.&nbsp;B&ouml;drich, DLR, Dassault Syst&egrave;mes AB, Fraunhofer, A.Haumer, ITI, Modelon,
   TU Hamburg-Harburg, Politecnico di Milano, XRG Simulation.
   </p>

   <p>
   <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
   </p>

   <p>
   <b>Modelica&reg;</b> is a registered trademark of the Modelica Association.
   </p>
   </html>"));
end Modelica;
