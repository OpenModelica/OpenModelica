package OverdeterminedInitialization
  "Test cases of systems with overdetermined initialization problems due to index reduction"
  extends Modelica.Icons.ExamplesPackage;

  package Fluid "Test cases with Fluid systems"
  extends Modelica.Icons.ExamplesPackage;
    model DynamicPipeLumpedPressureInitialization
      "Steady-state initialization of a dynamic pipe using lumped pressure states"
      extends Modelica.Icons.Example;

      Modelica.Fluid.Sources.FixedBoundary source(nPorts=1,
        redeclare package Medium = Modelica.Media.Water.StandardWater,
        use_T=false,
        h=2.5e6,
        p=system.p_start)
        annotation (Placement(transformation(extent={{-80,-10},{-60,10}})));
      Modelica.Fluid.Pipes.DynamicPipe pipe(
        redeclare package Medium = Modelica.Media.Water.StandardWater,
        diameter=0.05,
        length=200,
        use_T_start=false,
        useLumpedPressure=true,
        nNodes=5,
        modelStructure=Modelica.Fluid.Types.ModelStructure.a_vb,
        h_start=2.5e6)
        annotation (Placement(transformation(extent={{-40,-10},{-20,10}})));
      Modelica.Fluid.Valves.ValveCompressible valve(
        redeclare package Medium = Modelica.Media.Water.StandardWater,
        m_flow_nominal=10,
        rho_nominal=60,
        CvData=Modelica.Fluid.Types.CvTypes.Av,
        Av=0.05^2/4*Modelica.Constants.pi,
        dp_nominal=100000,
        p_nominal=10000000)
        annotation (Placement(transformation(extent={{0,-10},{20,10}})));
      Modelica.Fluid.Sources.FixedBoundary sink(nPorts=1,redeclare package
          Medium =
            Modelica.Media.Water.StandardWaterOnePhase, p=9500000)
                  annotation (Placement(transformation(extent={{60,-10},{40,10}})));
      Modelica.Blocks.Sources.Ramp ramp(
        offset=1,
        startTime=2,
        duration=0,
        height=-0.8)
                  annotation (Placement(transformation(extent={{46,30},{26,50}})));
      inner Modelica.Fluid.System system(energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyStateInitial,
        use_eps_Re=true,
        p_start=10000000)
        annotation (Placement(transformation(extent={{-80,60},{-60,80}})));
      discrete Modelica.SIunits.MassFlowRate m_flow_initial;
    equation
      when time > 0.1 then
        m_flow_initial = valve.port_a.m_flow;
      end when;
      if pipe.energyDynamics >= Modelica.Fluid.Types.Dynamics.SteadyStateInitial and
         pipe.massDynamics >= Modelica.Fluid.Types.Dynamics.SteadyStateInitial then
        when time > 1 then
          assert(abs(valve.port_a.m_flow - m_flow_initial) < 1e-3, "!!!THE SIMULATION DID NOT START IN STEADY-STATE!!!");
        end when;
      end if;
      connect(source.ports[1], pipe.port_a)         annotation (Line(
          points={{-60,6.66134e-16},{-55,6.66134e-16},{-55,1.27676e-15},{-50,
              1.27676e-15},{-50,6.10623e-16},{-40,6.10623e-16}},
          color={0,127,255},
          smooth=Smooth.None));
      connect(pipe.port_b, valve.port_a)               annotation (Line(
          points={{-20,6.10623e-16},{-15,6.10623e-16},{-15,1.22125e-15},{-10,
              1.22125e-15},{-10,6.10623e-16},{-5.55112e-16,6.10623e-16}},
          color={0,127,255},
          smooth=Smooth.None));
      connect(valve.port_b, sink.ports[1])                          annotation (Line(
          points={{20,6.10623e-16},{25,6.10623e-16},{25,1.27676e-15},{30,
              1.27676e-15},{30,6.66134e-16},{40,6.66134e-16}},
          color={0,127,255},
          smooth=Smooth.None));
      connect(ramp.y, valve.opening)               annotation (Line(
          points={{25,40},{10,40},{10,8}},
          color={0,0,127},
          smooth=Smooth.None));

      annotation (Documentation(info="<html>
All pressure states of the pipe are lumped into one.
The steady-state initial conditions become overdetermined as they are now specified nNodes times for the same pressure state.
The initial equations are consistent however and a tool shall reduce them appropriately.
</html>"),
      Diagram(coordinateSystem(preserveAspectRatio=true,
              extent={{-100,-100},{100,100}}), graphics={Text(
              extent={{-100,-20},{100,-40}},
              lineColor={0,0,255},
              textString=
                  "Problem: pipe.medium.p[1:5] are equal and have initial equations der(medium.p)=zeros(5);"),
              Text(
              extent={{-76,-40},{80,-58}},
              lineColor={0,0,255},
              textString=
                  "A translator should remove consistently overdetermined initial equations.")}),
        experiment(StopTime=4));
    end DynamicPipeLumpedPressureInitialization;

    model DynamicPipeInitialValues
      "Initialization of a dynamic pipe with fixed initial values and without adaptation of modelStructure to boundaries"
      extends Modelica.Icons.Example;

      Modelica.Fluid.Sources.FixedBoundary source(nPorts=1,
        redeclare package Medium = Modelica.Media.Water.StandardWater,
        use_T=false,
        h=2.5e6,
        p=system.p_start)
        annotation (Placement(transformation(extent={{-80,-10},{-60,10}})));
      Modelica.Fluid.Pipes.DynamicPipe pipe(
        redeclare package Medium = Modelica.Media.Water.StandardWater,
        diameter=0.05,
        length=200,
        use_T_start=false,
        nNodes=5,
        modelStructure=Modelica.Fluid.Types.ModelStructure.av_vb,
        h_start=2.5e6)
        annotation (Placement(transformation(extent={{-40,-10},{-20,10}})));
      Modelica.Fluid.Valves.ValveCompressible valve(
        redeclare package Medium = Modelica.Media.Water.StandardWater,
        m_flow_nominal=10,
        rho_nominal=60,
        CvData=Modelica.Fluid.Types.CvTypes.Av,
        Av=0.05^2/4*Modelica.Constants.pi,
        dp_nominal=100000,
        p_nominal=10000000)
        annotation (Placement(transformation(extent={{0,-10},{20,10}})));
      Modelica.Fluid.Sources.FixedBoundary sink(nPorts=1,redeclare package
          Medium =
            Modelica.Media.Water.StandardWaterOnePhase, p=9500000)
                  annotation (Placement(transformation(extent={{60,-10},{40,10}})));
      Modelica.Blocks.Sources.Ramp ramp(
        offset=1,
        startTime=2,
        duration=0,
        height=-0.8)
                  annotation (Placement(transformation(extent={{46,30},{26,50}})));
      inner Modelica.Fluid.System system(energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
        p_start=10000000,
        use_eps_Re=true)
        annotation (Placement(transformation(extent={{-80,60},{-60,80}})));
      discrete Modelica.SIunits.MassFlowRate m_flow_initial;
    equation
      when time > 0.1 then
        m_flow_initial = valve.port_a.m_flow;
      end when;
      if pipe.energyDynamics >= Modelica.Fluid.Types.Dynamics.SteadyStateInitial and
         pipe.massDynamics >= Modelica.Fluid.Types.Dynamics.SteadyStateInitial then
        when time > 1 then
          assert(abs(valve.port_a.m_flow - m_flow_initial) < 1e-3, "!!!THE SIMULATION DID NOT START IN STEADY-STATE!!!");
        end when;
      end if;
      connect(source.ports[1], pipe.port_a)         annotation (Line(
          points={{-60,6.66134e-16},{-55,6.66134e-16},{-55,1.27676e-15},{-50,
              1.27676e-15},{-50,6.10623e-16},{-40,6.10623e-16}},
          color={0,127,255},
          smooth=Smooth.None));
      connect(pipe.port_b, valve.port_a)               annotation (Line(
          points={{-20,6.10623e-16},{-15,6.10623e-16},{-15,1.22125e-15},{-10,
              1.22125e-15},{-10,6.10623e-16},{-5.55112e-16,6.10623e-16}},
          color={0,127,255},
          smooth=Smooth.None));
      connect(valve.port_b, sink.ports[1])                          annotation (Line(
          points={{20,6.10623e-16},{25,6.10623e-16},{25,1.27676e-15},{30,
              1.27676e-15},{30,6.66134e-16},{40,6.66134e-16}},
          color={0,127,255},
          smooth=Smooth.None));
      connect(ramp.y, valve.opening)               annotation (Line(
          points={{25,40},{10,40},{10,8}},
          color={0,0,127},
          smooth=Smooth.None));
      annotation (Documentation(info="<html>
The initial values are overdetermined as the first pipe segment is directly connected to a source with fixed pressure.
The initial equations are consistent however and a tool shall reduce them appropriately.
</html>"),
      Diagram(coordinateSystem(preserveAspectRatio=false,
              extent={{-100,-100},{100,100}}), graphics={
            Text(
              extent={{-100,-20},{100,-40}},
              lineColor={0,0,255},
              textString=
                  "Problem: pipe.medium[1].p is equal to source.p and  has a consistent initial value  of system.p_start = 100 bar;"),
            Text(
              extent={{-76,-36},{76,-54}},
              lineColor={0,0,255},
              textString=
                  "A translator should remove consistently overdetermined initial equations."),
            Text(
              extent={{-100,-64},{90,-84}},
              lineColor={0,0,255},
              textString=
                  "Work-around 2: change system.energyDynamics from FixedInitial to DynamicFreeInitial"),
            Text(
              extent={{-100,-54},{42,-74}},
              lineColor={0,0,255},
              textString=
                  "Work-around 1: change pipe.modelStructure from av_vb to a_vb")}),
        experiment(StopTime=4));
    end DynamicPipeInitialValues;

    model DynamicPipesSeriesSteadyStateInitial
      "Two series-connected pipes with steady-state initial condition, overedetermined initialization due to pressure states at the ports"
      extends Modelica.Icons.Example;

      Modelica.Fluid.Sources.FixedBoundary source(nPorts=1,
        redeclare package Medium = Modelica.Media.Water.StandardWater,
        use_T=false,
        h=2.5e6,
        p=system.p_start)
        annotation (Placement(transformation(extent={{-90,-10},{-70,10}})));
      Modelica.Fluid.Pipes.DynamicPipe pipe1(
        redeclare package Medium = Modelica.Media.Water.StandardWater,
        length=200,
        use_T_start=false,
        nNodes=5,
        modelStructure=Modelica.Fluid.Types.ModelStructure.av_vb,
        h_start=2.5e6,
        diameter=0.01)
        annotation (Placement(transformation(extent={{-50,-10},{-30,10}})));
      Modelica.Fluid.Valves.ValveCompressible valve(
        redeclare package Medium = Modelica.Media.Water.StandardWater,
        m_flow_nominal=10,
        rho_nominal=60,
        CvData=Modelica.Fluid.Types.CvTypes.Av,
        Av=0.05^2/4*Modelica.Constants.pi,
        dp_nominal=100000,
        p_nominal=10000000)
        annotation (Placement(transformation(extent={{26,-10},{46,10}})));
      Modelica.Fluid.Sources.FixedBoundary sink(nPorts=1,redeclare package
          Medium =
            Modelica.Media.Water.StandardWaterOnePhase, p=9500000)
                  annotation (Placement(transformation(extent={{86,-10},{66,10}})));
      Modelica.Blocks.Sources.Ramp ramp(
        offset=1,
        startTime=2,
        duration=0,
        height=-0.8)
                  annotation (Placement(transformation(extent={{72,30},{52,50}})));
      inner Modelica.Fluid.System system(
        use_eps_Re=true,
        energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyStateInitial,
        p_start=10000000)
        annotation (Placement(transformation(extent={{-90,60},{-70,80}})));
      Modelica.Fluid.Pipes.DynamicPipe pipe2(
        redeclare package Medium = Modelica.Media.Water.StandardWater,
        length=200,
        use_T_start=false,
        nNodes=5,
        modelStructure=Modelica.Fluid.Types.ModelStructure.av_vb,
        h_start=2.5e6,
        diameter=0.01)
        annotation (Placement(transformation(extent={{-14,-10},{6,10}})));
    equation
      connect(source.ports[1], pipe1.port_a) annotation (Line(
          points={{-70,0},{-50,0}},
          color={0,127,255},
          smooth=Smooth.None));
      connect(valve.port_b,sink. ports[1])                          annotation (Line(
          points={{46,0},{66,0}},
          color={0,127,255},
          smooth=Smooth.None));
      connect(ramp.y,valve. opening)               annotation (Line(
          points={{51,40},{36,40},{36,8}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(pipe1.port_b, pipe2.port_a) annotation (Line(
          points={{-30,0},{-14,0}},
          color={0,127,255},
          smooth=Smooth.None));
      connect(pipe2.port_b, valve.port_a) annotation (Line(
          points={{6,0},{26,0}},
          color={0,127,255},
          smooth=Smooth.None));
      annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{
                -100,-100},{100,100}}), graphics));
    end DynamicPipesSeriesSteadyStateInitial;

    model DynamicPipesSeriesLargeNSteadyStateInitial
      "Same as DynamicPipesSeriesSteadyStateInitial but with larger number of nodes"
       extends DynamicPipesSeriesSteadyStateInitial(
         pipe1(nNodes = 50),
         pipe2(nNodes = 50));
    equation

    end DynamicPipesSeriesLargeNSteadyStateInitial;

    model TwoVolumesEquationsReducedInitial
      "Initial values only for state variables after index reduction"
      extends Modelica.Icons.Example;
      extends BaseClasses.TwoVolumesEquations;
    initial equation
      T1 = 300;
      p2 = 1e5;
      T2 = 300;
      annotation(experiment(StopTime=1.0));
    end TwoVolumesEquationsReducedInitial;

    model TwoVolumesEquationsFullInitial
      "Fully specified initial values for all dynamic variables, consistent values"
      extends Modelica.Icons.Example;
      extends BaseClasses.TwoVolumesEquations;
    initial equation
        p1 = 1e5;
        T1 = 300;
        p2 = 1e5;
        T2 = 350;
      annotation(experiment(StopTime=1.0));
    end TwoVolumesEquationsFullInitial;

    model TwoVolumesEquationsFullInitialInconsistent
      "Fully specified initial values all for dynamic variables, inconsistent values. An error should be reported"
      extends Modelica.Icons.Example;
      extends BaseClasses.TwoVolumesEquations;
    initial equation
      p1 = 1e5;
      T1 = 300;
      p2 = 2e5;
      T2 = 350;
      annotation(experiment(StopTime=1.0));
    end TwoVolumesEquationsFullInitialInconsistent;

    model TwoVolumesEquationsReducedSteadyStatePressureAndTemperature
      "Steady-state equations only for state variables after index reduction"
      extends Modelica.Icons.Example;
      extends BaseClasses.TwoVolumesEquations;
    initial equation
      der(p1) = 0;
      der(T1) = 0;
      der(T2) = 0;
      annotation(experiment(StopTime=1.0));
    end TwoVolumesEquationsReducedSteadyStatePressureAndTemperature;

    model TwoVolumesEquationsFullSteadyStatePressureAndTemperature
      "Steady-state equations only for all dynamic variables after state variable change"
      extends Modelica.Icons.Example;
      extends BaseClasses.TwoVolumesEquations;
    initial equation
      der(p1) = 0;
      der(T1) = 0;
      der(p2) = 0;
      der(T2) = 0;
      annotation(experiment(StopTime=1.0));
    end TwoVolumesEquationsFullSteadyStatePressureAndTemperature;

    model TwoVolumesEquationsFullSteadyStateMassAndEnergy
      "Steady-state equations for all original dynamic variables"
      extends Modelica.Icons.Example;
      extends BaseClasses.TwoVolumesEquations;
    initial equation
      der(M1) = 0;
      der(E1) = 0;
      der(M2) = 0;
      der(E2) = 0;
      annotation(experiment(StopTime=1.0));
    end TwoVolumesEquationsFullSteadyStateMassAndEnergy;

    model TwoVolumesFullInitial
      "Fully specified initial values for all dynamic variables, consistent values"
      extends Modelica.Icons.Example;
      extends BaseClasses.TwoVolumes(
        system(energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial),
        V1(p_start=100000, T_start(displayUnit="K") = 300),
        V2(p_start=100000, T_start=623.15));
      annotation(experiment(StopTime=1.0));
    end TwoVolumesFullInitial;

    model TwoVolumesFullInitialInconsistent
      "Fully specified initial values for all dynamic variables, inconsistent values. An error should be reported"
      extends Modelica.Icons.Example;
      extends BaseClasses.TwoVolumes(
        system(energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial),
        V1(p_start=100000, T_start(displayUnit="K") = 300),
        V2(p_start=200000, T_start=623.15));
      annotation(experiment(StopTime=1.0));
    end TwoVolumesFullInitialInconsistent;

    model TwoVolumesFullSteadyStatePressureAndTemperature
      "Fully specified steady-state conditions for all dynamic variables"
      extends Modelica.Icons.Example;
      extends BaseClasses.TwoVolumes(
        system(energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyStateInitial),
        V1(p_start=100000, T_start(displayUnit="K") = 300),
        V2(p_start=100000, T_start=623.15));
      annotation(experiment(StopTime=1.0));
    end TwoVolumesFullSteadyStatePressureAndTemperature;

    package BaseClasses "Base classes for test models"
      extends Modelica.Icons.BasesPackage;
      model TwoVolumes
        "Two volumes containing an ideal gas with a zero dp connection, MSL-based"

        Modelica.Fluid.Vessels.ClosedVolume V1(
          use_portsData=false,
          V=1,
          nPorts=2,
          redeclare package Medium = Modelica.Media.Air.DryAirNasa)
          annotation (Placement(transformation(extent={{-48,0},{-28,20}})));
        Modelica.Fluid.Vessels.ClosedVolume V2(
          use_portsData=false,
          V=1,
          nPorts=2,
          redeclare package Medium = Modelica.Media.Air.DryAirNasa)
          annotation (Placement(transformation(extent={{-12,0},{8,20}})));
        Modelica.Fluid.Sources.MassFlowSource_T source(
          nPorts=1,
          redeclare package Medium = Modelica.Media.Air.DryAirNasa,
          m_flow=0.01)
          annotation (Placement(transformation(extent={{-80,-20},{-60,0}})));
        Modelica.Fluid.Sources.FixedBoundary sink(
          redeclare package Medium = Modelica.Media.Air.DryAirNasa,
          T(displayUnit="K") = 300,
          nPorts=1,
          p=1000) annotation (Placement(transformation(extent={{80,-20},{60,0}})));
        inner Modelica.Fluid.System system
          annotation (Placement(transformation(extent={{60,60},{80,80}})));
        Modelica.Fluid.Valves.ValveLinear valveLinear(
          redeclare package Medium = Modelica.Media.Air.DryAirNasa,
          dp_nominal=100000,
          m_flow_nominal=0.01)
          annotation (Placement(transformation(extent={{20,-20},{40,0}})));
        Modelica.Blocks.Sources.RealExpression one(y=1)
          annotation (Placement(transformation(extent={{2,24},{22,44}})));
      equation
        connect(source.ports[1], V1.ports[1]) annotation (Line(
            points={{-60,-10},{-40,-10},{-40,0}},
            color={0,127,255},
            smooth=Smooth.None));
        connect(V1.ports[2], V2.ports[1]) annotation (Line(
            points={{-36,0},{-36,-10},{-4,-10},{-4,0}},
            color={0,127,255},
            smooth=Smooth.None));
        connect(V2.ports[2], valveLinear.port_a) annotation (Line(
            points={{0,0},{0,-10},{20,-10}},
            color={0,127,255},
            smooth=Smooth.None));
        connect(valveLinear.port_b, sink.ports[1]) annotation (Line(
            points={{40,-10},{60,-10}},
            color={0,127,255},
            smooth=Smooth.None));
        connect(one.y, valveLinear.opening) annotation (Line(
            points={{23,34},{30,34},{30,-2}},
            color={0,0,127},
            smooth=Smooth.None));
        annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{
                  -100,-100},{100,100}}), graphics));
      end TwoVolumes;

      model TwoVolumesEquations
        "Two volumes containing an ideal gas with a zero dp connection, equation-based"
        Real M1(stateSelect = StateSelect.avoid),
             M2(stateSelect = StateSelect.avoid),
             E1(stateSelect = StateSelect.avoid),
             E2(stateSelect = StateSelect.avoid),
             p1(stateSelect = StateSelect.prefer),
             p2(stateSelect = StateSelect.prefer),
             T1(stateSelect = StateSelect.prefer),
             T2(stateSelect = StateSelect.prefer),
             w0, w1, w2, h1, h2;
        parameter Real V = 1;
        parameter Real R = 400;
        parameter Real cp = 1000;
        parameter Real cv = cp-R;
        parameter Real h0 = cp*300;
        parameter Real Kv = 1e-7;
      equation
        der(M1) = w0 - w1;
        der(E1) = w0*h0 - w1*h1;
        der(M2) = w1 - w2;
        der(E2) = w1*h1 - w2*h2;
        M1 = V*p1/(R*T1);
        M2 = V*p2/(R*T2);
        E1 = M1*cv*T1;
        E2 = M2*cv*T2;
        h1 = cp*T1;
        h2 = cp*T2;
        w0 = 0.01;
        w2 = Kv*p2;
        p1 = p2;
      end TwoVolumesEquations;
    end BaseClasses;
  end Fluid;

  package Mechanical "Test cases with Mechanical systems"
    extends Modelica.Icons.ExamplesPackage;

    model TwoMassesEquationsFullInitial
      "Fully specified initial values for dynamic variables"
      extends BaseClasses.TwoMassesEquations;
      extends Modelica.Icons.Example;
    initial equation
      x1 = 0;
      v1 = 0;
      x2 = 0;
      v2 = 0;
      annotation(experiment(StopTime=1.0));
    end TwoMassesEquationsFullInitial;

    model TwoMassesEquationsFullInitialInconsistent
      "Fully specified initial values for dynamic variables, inconsistent values"
      extends BaseClasses.TwoMassesEquations;
      extends Modelica.Icons.Example;
    initial equation
      x1 = 0;
      v1 = 0;
      x2 = 1;
      v2 = 0;
      annotation(experiment(StopTime=1.0));
    end TwoMassesEquationsFullInitialInconsistent;

    model TwoMassesEquationsReducedInitial
      "Initial values for state variables after index reduction"
      extends BaseClasses.TwoMassesEquations;
      extends Modelica.Icons.Example;
    initial equation
      x1 = 0;
      v1 = 0;
      annotation(experiment(StopTime=1.0));
    end TwoMassesEquationsReducedInitial;

    model TwoMassesEquationsFullSteadyState
      "Fully specified initial values for dynamic variables"
      extends BaseClasses.TwoMassesEquations;
      extends Modelica.Icons.Example;
    initial equation
      der(x1) = 0;
      der(v1) = 0;
      der(x2) = 0;
      der(v2) = 0;
      annotation(experiment(StopTime=1.0));
    end TwoMassesEquationsFullSteadyState;

    model TwoMassesEquationsReducedSteadyState
      "Fully specified initial values for states after index reduction"
      extends BaseClasses.TwoMassesEquations;
      extends Modelica.Icons.Example;
    initial equation
      der(x1) = 0;
      der(v1) = 0;
      annotation(experiment(StopTime=1.0));
    end TwoMassesEquationsReducedSteadyState;

    model TwoMassesFullInitial
      "Fully specified initial values for dynamic variables"
      extends Modelica.Icons.Example;
      extends BaseClasses.TwoMasses(
        mass1(s(fixed=true), v(fixed=true)),
        mass2(s(fixed=true), v(fixed=true)));
      annotation (experiment(StopTime=10));
    end TwoMassesFullInitial;

    model TwoMassesFullInitialInconsistent
      "Fully specified initial values for dynamic variables, inconsistent values"
      extends Modelica.Icons.Example;
      extends BaseClasses.TwoMasses(
        mass1(s(fixed=true), v(fixed=true)),
        mass2(s(fixed=true, start=2), v(fixed=true)));
      annotation (experiment(StopTime=10));
    end TwoMassesFullInitialInconsistent;

    model TwoMassesReducedInitial
      "Initial values for state variables after index reduction"
      extends Modelica.Icons.Example;
      extends BaseClasses.TwoMasses(
                        mass1(s(fixed=true), v(fixed=true)));
      annotation (experiment(StopTime=10));
    end TwoMassesReducedInitial;

    model TwoMassesFullSteadyState
      "Fully specified steady state conditions for dynamic variables"
      extends Modelica.Icons.Example;
      extends BaseClasses.TwoMasses(
         mass1(v(fixed=true, start=0), a(fixed=true, start=0)),
         mass2(v(fixed=true, start=0), a(fixed=true, start=0)));
      annotation (experiment(StopTime=10));
    end TwoMassesFullSteadyState;

    model TwoMassesReducedSteadyState
      "Steady-state initial conditions for states after index reduction"
      extends Modelica.Icons.Example;
      extends BaseClasses.TwoMasses(
        mass1(v(fixed=true, start=0), a(fixed=true, start=0)));
      annotation (experiment(StopTime=10));
    end TwoMassesReducedSteadyState;

    package BaseClasses "Base classes for test cases"
      extends Modelica.Icons.BasesPackage;
      model TwoMasses
        "Two rigidly connected masses, connected to ground via a spring"

        Modelica.Mechanics.Translational.Components.Mass mass1(
           m=1, s(fixed=false,start=1))
          annotation (Placement(transformation(extent={{-12,-10},{8,10}})));
        Modelica.Mechanics.Translational.Components.Mass mass2(
           m=1, s(fixed=false, start=1))
          annotation (Placement(transformation(extent={{26,-10},{46,10}})));
        Modelica.Mechanics.Translational.Components.Fixed fixed
          annotation (Placement(transformation(extent={{-70,-10},{-50,10}})));
        Modelica.Mechanics.Translational.Components.Spring spring(c=1, s_rel0=0.5)
          annotation (Placement(transformation(extent={{-42,-10},{-22,10}})));
      equation
        connect(fixed.flange, spring.flange_a) annotation (Line(
            points={{-60,0},{-42,0}},
            color={0,127,0},
            smooth=Smooth.None));
        connect(spring.flange_b, mass1.flange_a) annotation (Line(
            points={{-22,0},{-12,0}},
            color={0,127,0},
            smooth=Smooth.None));
        connect(mass1.flange_b, mass2.flange_a) annotation (Line(
            points={{8,0},{26,0}},
            color={0,127,0},
            smooth=Smooth.None));
      end TwoMasses;

      model TwoMassesEquations
        "Two rigidly connected masses, connected to ground via a spring, equation-based"
        Real x1, v1, x2, v2, F1, F2;
        parameter Real M = 1;
        parameter Real K = 1;
        parameter Real F0 = 1;
      equation
        der(x1) = v1;
        M*der(v1) = F1+F2;
        der(x2) = v2;
        M*der(v2) = -F2;
        F1 = -K*x1;
        x1 = x2;
      end TwoMassesEquations;
    end BaseClasses;
  end Mechanical;

  package Electrical "Test cases with Electrical systems"
    extends Modelica.Icons.ExamplesPackage;
    package BaseClasses "Base classes for test cases"
      extends Modelica.Icons.BasesPackage;

      connector Negative3PhasePin

        Modelica.Electrical.Analog.Interfaces.NegativePin p1 annotation(Placement(transformation(extent = {{-10,10},{10,30}}, rotation = 0)));
        Modelica.Electrical.Analog.Interfaces.NegativePin p2 annotation(Placement(transformation(extent = {{-10,-10},{10,10}}, rotation = 0)));
        Modelica.Electrical.Analog.Interfaces.NegativePin p3 annotation(Placement(transformation(extent = {{-10,-30},{10,-10}}, rotation = 0)));
        annotation(Diagram(coordinateSystem(extent = {{-10,-30},{10,30}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2,2})), Icon(coordinateSystem(extent = {{-10,-30},{10,30}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2,2})));
      end Negative3PhasePin;

      connector Positive3PhasePin

        Modelica.Electrical.Analog.Interfaces.PositivePin p1 annotation(Placement(transformation(extent = {{-10,10},{10,30}}, rotation = 0)));
        Modelica.Electrical.Analog.Interfaces.PositivePin p2 annotation(Placement(transformation(extent = {{-10,-10},{10,10}}, rotation = 0)));
        Modelica.Electrical.Analog.Interfaces.PositivePin p3 annotation(Placement(transformation(extent = {{-10,-30},{10,-10}}, rotation = 0)));
        annotation(Diagram(coordinateSystem(extent = {{-10,-30},{10,30}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2,2})), Icon(coordinateSystem(extent = {{-10,-30},{10,30}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2,2})));
      end Positive3PhasePin;

      model Line3Phase
        constant Real pi = Modelica.Constants.pi;
        Real i_abc[3] = {I1.i,I2.i,I3.i};
        Real i_dq0[3];
      protected
        Real theta;
        Real Park[3,3];
      public
        Positive3PhasePin P annotation (Placement(transformation(
                extent={{-60,-10},{-40,10}}, rotation=0), iconTransformation(
                extent={{-60,-10},{-40,10}})));
        Negative3PhasePin N annotation (Placement(transformation(
                extent={{40,-10},{60,10}}, rotation=0), iconTransformation(
                extent={{40,-10},{60,10}})));
        Modelica.Electrical.Analog.Basic.Inductor I1(L = 1) annotation(Placement(transformation(extent = {{-40,30},{-20,50}}, rotation = 0)));
        Modelica.Electrical.Analog.Basic.Inductor I2(L = 1) annotation(Placement(transformation(extent = {{-40,-10},{-20,10}}, rotation = 0)));
        Modelica.Electrical.Analog.Basic.Inductor I3(L = 1) annotation(Placement(transformation(extent = {{-40,-50},{-20,-30}}, rotation = 0)));
        Modelica.Electrical.Analog.Basic.Resistor R1(R = 0.5) annotation(Placement(transformation(extent = {{20,30},{40,50}}, rotation = 0)));
        Modelica.Electrical.Analog.Basic.Resistor R2(R = 0.5) annotation(Placement(transformation(extent = {{20,-10},{40,10}}, rotation = 0)));
        Modelica.Electrical.Analog.Basic.Resistor R3(R = 0.5) annotation(Placement(transformation(extent = {{20,-50},{40,-30}}, rotation = 0)));
      equation
        theta = 2 * pi * time;
        Park = sqrt(2) / sqrt(3) * [sin(theta),sin(theta + 2 * pi / 3),sin(theta + 4 * pi / 3);cos(theta),cos(theta + 2 * pi / 3),cos(theta + 4 * pi / 3);1 / sqrt(2),1 / sqrt(2),1 / sqrt(2)];
        i_dq0 = Park * i_abc;
        connect(P.p1,I1.p) annotation(Line(points = {{-50,0},{-60,0},{-60,40},{-40,40}}, color = {0,0,255}, smooth = Smooth.None));
        connect(P.p2,I2.p) annotation(Line(points = {{-50,0},{-60,0},{-60,0},{-40,0}}, color = {0,0,255}, smooth = Smooth.None));
        connect(P.p3,I3.p) annotation(Line(points = {{-50,0},{-60,0},{-60,-40},{-40,-40}}, color = {0,0,255}, smooth = Smooth.None));
        connect(I1.n,R1.p) annotation(Line(points = {{-20,40},{20,40}}, color = {0,0,255}, smooth = Smooth.None));
        connect(I2.n,R2.p) annotation(Line(points = {{-20,0},{20,0}}, color = {0,0,255}, smooth = Smooth.None));
        connect(I3.n,R3.p) annotation(Line(points = {{-20,-40},{20,-40}}, color = {0,0,255}, smooth = Smooth.None));
        connect(R1.n,N.p1) annotation(Line(points = {{40,40},{60,40},{60,0},{50,0}}, color = {0,0,255}, smooth = Smooth.None));
        connect(R2.n,N.p2) annotation(Line(points = {{40,0},{60,0},{60,0},{50,0}}, color = {0,0,255}, smooth = Smooth.None));
        connect(R3.n,N.p3) annotation(Line(points = {{40,-40},{60,-40},{60,0},{50,0}}, color = {0,0,255}, smooth = Smooth.None));
        annotation(Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100,-60},{100,60}}), graphics), Icon(coordinateSystem(extent = {{-100,-60},{100,60}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2,2}), graphics={  Rectangle(fillColor = {135,135,135},
                  fillPattern =                                                                                                    FillPattern.HorizontalCylinder, extent = {{-40,20},{-20,-20}}),Rectangle(fillColor = {95,95,95},
                  fillPattern =                                                                                                    FillPattern.HorizontalCylinder, extent = {{-20,20},{40,-20}}),Rectangle(extent = {{-54,-2},{-40,-6}}, lineColor = {0,0,0},
                  fillPattern =                                                                                                    FillPattern.Solid),Rectangle(extent = {{-54,2},{-40,-2}}, lineColor = {0,0,0}, fillColor = {255,255,255},
                  fillPattern =                                                                                                    FillPattern.Solid),Rectangle(extent = {{-54,6},{-40,2}}, lineColor = {0,0,0},
                  fillPattern =                                                                                                    FillPattern.Solid),Rectangle(extent = {{40,-2},{54,-6}}, lineColor = {0,0,0},
                  fillPattern =                                                                                                    FillPattern.Solid, fillColor = {255,255,255}),Rectangle(extent = {{40,2},{54,-2}}, lineColor = {0,0,0},
                  fillPattern =                                                                                                    FillPattern.Solid),Rectangle(extent = {{40,6},{54,2}}, lineColor = {0,0,0},
                  fillPattern =                                                                                                    FillPattern.Solid, fillColor = {255,255,255}),Text(extent = {{-20,-40},{20,-60}}, lineColor = {0,0,0}, textString = "%name")}));
      end Line3Phase;

      model Line3PhaseInit
        extends Line3Phase;
      initial equation
        der(i_dq0) = {0,0,0};
        annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100,-60},{100,60}}), graphics), Diagram(coordinateSystem(extent = {{-100,-60},{100,60}})));
      end Line3PhaseInit;

      model Source3Phase
        constant Real pi = Modelica.Constants.pi;
        parameter Real shift = 0.0;
      public
        Positive3PhasePin P annotation (Placement(transformation(
                extent={{-60,-10},{-40,10}}, rotation=0), iconTransformation(
                extent={{-60,-10},{-40,10}})));
        Modelica.Electrical.Analog.Basic.Ground G annotation(Placement(transformation(extent = {{30,-80},{50,-60}}, rotation = 0)));
        Modelica.Electrical.Analog.Sources.SineVoltage S1(freqHz = 1, V = 1, phase = shift) annotation(Placement(transformation(extent = {{-10,30},{10,50}}, rotation = 0)));
        Modelica.Electrical.Analog.Sources.SineVoltage S2(freqHz = 1, V = 1, phase = 2 * pi / 3 + shift) annotation(Placement(transformation(extent = {{-10,-10},{10,10}}, rotation = 0)));
        Modelica.Electrical.Analog.Sources.SineVoltage S3(freqHz = 1, V = 1, phase = 4 * pi / 3 + shift) annotation(Placement(transformation(extent = {{-8,-50},{12,-30}}, rotation = 0)));
      equation
        connect(G.p,S1.n) annotation(Line(points = {{40,-60},{40,40},{10,40}}, color = {0,0,255}, smooth = Smooth.None));
        connect(G.p,S2.n) annotation(Line(points = {{40,-60},{40,0},{10,0}}, color = {0,0,255}, smooth = Smooth.None));
        connect(G.p,S3.n) annotation(Line(points = {{40,-60},{40,-40},{12,-40}}, color = {0,0,255}, smooth = Smooth.None));
        connect(S1.p,P.p1) annotation(Line(points = {{-10,40},{-40,40},{-40,0},{-50,0}}, color = {0,0,255}, smooth = Smooth.None));
        connect(S2.p,P.p2) annotation(Line(points = {{-10,0},{-30,0},{-30,0},{-50,0}}, color = {0,0,255}, smooth = Smooth.None));
        connect(S3.p,P.p3) annotation(Line(points = {{-8,-40},{-40,-40},{-40,0},{-50,0}}, color = {0,0,255}, smooth = Smooth.None));
        annotation(Diagram(coordinateSystem(extent = {{-60,-60},{60,60}}), graphics), Icon(coordinateSystem(extent = {{-60,-60},{60,60}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2,2}), graphics={  Ellipse(extent = {{-40,40},{40,-40}}, endAngle = 360),Line(points = {{-40,0},{40,0}}),Line(origin = {-2.8,-20}, points = {{-11.2,2},{-9.24,7.98},{-7.96,11.3},{-6.84,13.62},{-5.86,15.04},{-4.86,15.84},{-3.88,15.96},{-2.9,15.4},{-1.92,14.2},{-0.92,12.4},{0.2,9.720000000000001},{1.604,5.72},{4.558,-3.38},{5.82,-6.8},{6.96,-9.24},{7.94,-10.8},{8.92,-11.72},{9.9,-12},{10.9,-11.58},{11.88,-10.5},{12.86,-8.82},{13.98,-6.26},{15.4,-2.34},{16.8,2}}),Rectangle(extent = {{-54,-2},{-40,-6}}, lineColor = {0,0,0},
                  fillPattern =                                                                                                    FillPattern.Solid),Rectangle(extent = {{-54,2},{-40,-2}}, lineColor = {0,0,0}, fillColor = {255,255,255},
                  fillPattern =                                                                                                    FillPattern.Solid),Rectangle(extent = {{-54,6},{-40,2}}, lineColor = {0,0,0},
                  fillPattern =                                                                                                    FillPattern.Solid),Text(extent = {{-20,-40},{20,-60}}, lineColor = {0,0,0}, textString = "%name")}));
      end Source3Phase;
    end BaseClasses;

    model Test3PhaseSystemsFullInitial
      extends Modelica.Icons.Example;

      BaseClasses.Source3Phase S(shift=0) annotation (Placement(visible=true,
            transformation(
            origin={-40,0},
            extent={{-6,6},{6,-6}},
            rotation=180)));
      BaseClasses.Line3PhaseInit LR1 annotation (Placement(visible=true,
            transformation(
            origin={0,0},
            extent={{-10,-6},{10,6}},
            rotation=0)));
      BaseClasses.Source3Phase SS(shift=0.4) annotation (Placement(visible=true,
            transformation(
            origin={20,0},
            extent={{-6,-6},{6,6}},
            rotation=0)));
      BaseClasses.Line3PhaseInit LR2 annotation (Placement(visible=true,
            transformation(
            origin={-20,0},
            extent={{-10,-6},{10,6}},
            rotation=0)));
    equation
      connect(S.P,LR2.P) annotation(Line(points = {{-35,0},{-28.1076,0},{-25,0},{-25,0}}));
      connect(LR2.N,LR1.P) annotation(Line(points = {{-15,0},{-5,0}}));
      connect(LR1.N,SS.P) annotation(Line(points = {{5,0},{15,0}}));
      annotation(experiment(StopTime=10), Diagram(coordinateSystem(extent = {{-60,-20},{40,20}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2,2})));
    end Test3PhaseSystemsFullInitial;

    model Test3PhaseSystemsReducedInitial
      extends Modelica.Icons.Example;
      BaseClasses.Source3Phase S(shift=0) annotation (Placement(visible=true,
            transformation(
            origin={-40,0},
            extent={{-6,6},{6,-6}},
            rotation=180)));
      BaseClasses.Line3PhaseInit LR1 annotation (Placement(visible=true,
            transformation(
            origin={0,0},
            extent={{-10,-6},{10,6}},
            rotation=0)));
      BaseClasses.Source3Phase SS(shift=0.4) annotation (Placement(visible=true,
            transformation(
            origin={20,0},
            extent={{-6,-6},{6,6}},
            rotation=0)));
      BaseClasses.Line3Phase LR2 annotation (Placement(visible=true,
            transformation(
            origin={-20,0},
            extent={{-10,-6},{10,6}},
            rotation=0)));
    equation
      connect(S.P,LR2.P) annotation(Line(points = {{-35,0},{-28.1076,0},{-25,0},{-25,0}}));
      connect(LR2.N,LR1.P) annotation(Line(points = {{-15,0},{-5,0}}));
      connect(LR1.N,SS.P) annotation(Line(points = {{5,0},{15,0}}));
      annotation(experiment(StopTime=10), Diagram(coordinateSystem(extent = {{-60,-20},{40,20}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2,2})));
    end Test3PhaseSystemsReducedInitial;
  end Electrical;
end OverdeterminedInitialization;
