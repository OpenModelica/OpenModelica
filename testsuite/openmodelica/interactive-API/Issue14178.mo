package ModelicaServices "ModelicaServices (OpenModelica implementation) - Models and functions used in the Modelica Standard Library requiring a tool specific implementation"
  constant String target = "OpenModelica" "Target of this ModelicaServices implementation";

  package Machine "Machine dependent constants"
    final constant Real eps = 2.2204460492503131e-016 "The difference between 1 and the least value greater than 1 that is representable in the given floating point type";
    final constant Real small = 2.2250738585072014e-308 "Minimum normalized positive floating-point number";
    final constant Real inf = 1e60 "Maximum representable finite floating-point number";
    final constant Integer Integer_inf = OpenModelica.Internal.Architecture.integerMax() "Biggest Integer number such that Integer_inf and -Integer_inf are representable on the machine";
  end Machine;

  package System "System dependent functions" end System;

  package Types "Library of types with vendor specific choices" end Types;
  annotation(version = "4.1.0", versionDate = "2025-05-23", dateModified = "2025-05-23 15:00:00Z");
end ModelicaServices;

package Modelica "Modelica Standard Library"
  package Blocks "Library of basic input/output control blocks (continuous, discrete, logical, table blocks)"
    import Modelica.Units.SI;

    package Examples "Library of examples to demonstrate the usage of package Blocks" end Examples;

    package Continuous "Library of continuous control blocks with internal states"
      import Modelica.Blocks.Interfaces;

      block Integrator "Output the integral of the input signal with optional reset"
        import Modelica.Blocks.Types.Init;
        parameter Real k = 1 "Integrator gain";
        parameter Boolean use_reset = false "= true, if reset port enabled" annotation(Evaluate = true, HideResult = true);
        parameter Boolean use_set = false "= true, if set port enabled and used as reinitialization value when reset" annotation(Evaluate = true, HideResult = true);
        parameter Init initType = Init.InitialState "Type of initialization (1: no init, 2: steady state, 3,4: initial output)" annotation(Evaluate = true);
        parameter Real y_start = 0 "Initial or guess value of output (= state)";
        extends Interfaces.SISO;
        Modelica.Blocks.Interfaces.BooleanInput reset if use_reset "Optional connector of reset signal";
        Modelica.Blocks.Interfaces.RealInput set if use_reset and use_set "Optional connector of set signal";
      protected
        Modelica.Blocks.Interfaces.BooleanOutput local_reset annotation(HideResult = true);
        Modelica.Blocks.Interfaces.RealOutput local_set annotation(HideResult = true);
      initial equation
        if initType == Init.SteadyState then
          der(y) = 0;
        elseif initType == Init.InitialState or initType == Init.InitialOutput then
          y = y_start;
        end if;
      equation
        if use_reset then
          connect(reset, local_reset);
          if use_set then
            connect(set, local_set);
          else
            local_set = y_start;
          end if;
          when local_reset then
            reinit(y, local_set);
          end when;
        else
          local_reset = false;
          local_set = 0;
        end if;
        der(y) = k*u;
      end Integrator;

      block Derivative "Approximated derivative block"
        import Modelica.Blocks.Types.Init;
        parameter Real k = 1 "Gains";
        parameter SI.Time T(min = Modelica.Constants.small) = 0.01 "Time constants (T>0 required; T=0 is ideal derivative block)";
        parameter Init initType = Init.NoInit "Type of initialization (1: no init, 2: steady state, 3: initial state, 4: initial output)" annotation(Evaluate = true);
        parameter Real x_start = 0 "Initial or guess value of state";
        parameter Real y_start = 0 "Initial value of output (= state)";
        extends Interfaces.SISO;
        output Real x(start = x_start) "State of block";
      protected
        parameter Boolean zeroGain = abs(k) < Modelica.Constants.eps;
      initial equation
        if initType == Init.SteadyState then
          der(x) = 0;
        elseif initType == Init.InitialState then
          x = x_start;
        elseif initType == Init.InitialOutput then
          if zeroGain then
            x = u;
          else
            y = y_start;
          end if;
        end if;
      equation
        der(x) = if zeroGain then 0 else (u - x)/T;
        y = if zeroGain then 0 else (k/T)*(u - x);
      end Derivative;

      block FirstOrder "First order transfer function block (= 1 pole)"
        import Modelica.Blocks.Types.Init;
        parameter Real k = 1 "Gain";
        parameter SI.Time T(start = 1) "Time Constant";
        parameter Init initType = Init.NoInit "Type of initialization (1: no init, 2: steady state, 3/4: initial output)" annotation(Evaluate = true);
        parameter Real y_start = 0 "Initial or guess value of output (= state)";
        extends Interfaces.SISO(y(start = y_start));
      initial equation
        if initType == Init.SteadyState then
          der(y) = 0;
        elseif initType == Init.InitialState or initType == Init.InitialOutput then
          y = y_start;
        end if;
      equation
        der(y) = (k*u - y)/T;
      end FirstOrder;

      block PI "Proportional-Integral controller"
        import Modelica.Blocks.Types.Init;
        parameter Real k = 1 "Gain";
        parameter SI.Time T(start = 1, min = Modelica.Constants.small) "Time Constant (T>0 required)";
        parameter Init initType = Init.NoInit "Type of initialization (1: no init, 2: steady state, 3: initial state, 4: initial output)" annotation(Evaluate = true);
        parameter Real x_start = 0 "Initial or guess value of state";
        parameter Real y_start = 0 "Initial value of output";
        extends Interfaces.SISO;
        output Real x(start = x_start) "State of block";
      initial equation
        if initType == Init.SteadyState then
          der(x) = 0;
        elseif initType == Init.InitialState then
          x = x_start;
        elseif initType == Init.InitialOutput then
          y = y_start;
        end if;
      equation
        der(x) = u/T;
        y = k*(x + u);
      end PI;

      block PID "PID controller in additive description form"
        import Modelica.Blocks.Types.Init;
        extends Interfaces.SISO;
        parameter Real k = 1 "Gain";
        parameter SI.Time Ti(min = Modelica.Constants.small, start = 0.5) "Time Constant of Integrator";
        parameter SI.Time Td(min = 0, start = 0.1) "Time Constant of Derivative block";
        parameter Real Nd(min = Modelica.Constants.small) = 10 "The higher Nd, the more ideal the derivative block";
        parameter Init initType = Init.InitialState "Type of initialization (1: no init, 2: steady state, 3: initial state, 4: initial output)" annotation(Evaluate = true);
        parameter Real xi_start = 0 "Initial or guess value for integrator output (= integrator state)";
        parameter Real xd_start = 0 "Initial or guess value for state of derivative block";
        parameter Real y_start = 0 "Initial value of output";
        constant SI.Time unitTime = 1 annotation(HideResult = true);
        Blocks.Math.Gain P(k = 1) "Proportional part of PID controller";
        Blocks.Continuous.Integrator I(k = unitTime/Ti, y_start = xi_start, initType = if initType == Init.SteadyState then Init.SteadyState else if initType == Init.InitialState then Init.InitialState else Init.NoInit) "Integral part of PID controller";
        Blocks.Continuous.Derivative D(k = Td/unitTime, T = max([Td/Nd, 100*Modelica.Constants.eps]), x_start = xd_start, initType = if initType == Init.SteadyState or initType == Init.InitialOutput then Init.SteadyState else if initType == Init.InitialState then Init.InitialState else Init.NoInit) "Derivative part of PID controller";
        Blocks.Math.Gain Gain(k = k) "Gain of PID controller";
        Blocks.Math.Add3 Add;
      initial equation
        if initType == Init.InitialOutput then
          y = y_start;
        end if;
      equation
        connect(u, P.u);
        connect(u, I.u);
        connect(u, D.u);
        connect(P.y, Add.u1);
        connect(I.y, Add.u2);
        connect(D.y, Add.u3);
        connect(Add.y, Gain.u);
        connect(Gain.y, y);
      end PID;

      block LimPID "P, PI, PD, and PID controller with limited output, anti-windup compensation, setpoint weighting and optional feed-forward"
        import Modelica.Blocks.Types.Init;
        import Modelica.Blocks.Types.SimpleController;
        extends Modelica.Blocks.Interfaces.SVcontrol;
        output Real controlError = u_s - u_m "Control error (set point - measurement)";
        parameter .Modelica.Blocks.Types.SimpleController controllerType = .Modelica.Blocks.Types.SimpleController.PID "Type of controller";
        parameter Real k = 1 "Gain of controller, must be non-zero";
        parameter SI.Time Ti(min = Modelica.Constants.small) = 0.5 "Time constant of Integrator block";
        parameter SI.Time Td(min = 0) = 0.1 "Time constant of Derivative block";
        parameter Real yMax(start = 1) "Upper limit of output";
        parameter Real yMin = -yMax "Lower limit of output";
        parameter Real wp(min = 0) = 1 "Set-point weight for Proportional block (0..1)";
        parameter Real wd(min = 0) = 0 "Set-point weight for Derivative block (0..1)";
        parameter Real Ni(min = 100*Modelica.Constants.eps) = 0.9 "Ni*Ti is time constant of anti-windup compensation";
        parameter Real Nd(min = 100*Modelica.Constants.eps) = 10 "The higher Nd, the more ideal the derivative block";
        parameter Boolean withFeedForward = false "Use feed-forward input?" annotation(Evaluate = true);
        parameter Real kFF = 1 "Gain of feed-forward input";
        parameter Init initType = Init.InitialState "Type of initialization (1: no init, 2: steady state, 3: initial state, 4: initial output)" annotation(Evaluate = true);
        parameter Real xi_start = 0 "Initial or guess value for integrator output (= integrator state)";
        parameter Real xd_start = 0 "Initial or guess value for state of derivative block";
        parameter Real y_start = 0 "Initial value of output";
        parameter Modelica.Blocks.Types.LimiterHomotopy homotopyType = Modelica.Blocks.Types.LimiterHomotopy.Linear "Simplified model for homotopy-based initialization" annotation(Evaluate = true);
        parameter Boolean strict = false "= true, if strict limits with noEvent(..)" annotation(Evaluate = true);
        constant SI.Time unitTime = 1 annotation(HideResult = true);
        Modelica.Blocks.Interfaces.RealInput u_ff if withFeedForward "Optional connector of feed-forward input signal";
        Modelica.Blocks.Math.Add addP(k1 = wp, k2 = -1);
        Modelica.Blocks.Math.Add addD(k1 = wd, k2 = -1) if with_D;
        Modelica.Blocks.Math.Gain P(k = 1);
        Modelica.Blocks.Continuous.Integrator I(k = unitTime/Ti, y_start = xi_start, initType = if initType == Init.SteadyState then Init.SteadyState else if initType == Init.InitialState then Init.InitialState else Init.NoInit) if with_I;
        Modelica.Blocks.Continuous.Derivative D(k = Td/unitTime, T = max([Td/Nd, 1.e-14]), x_start = xd_start, initType = if initType == Init.SteadyState or initType == Init.InitialOutput then Init.SteadyState else if initType == Init.InitialState then Init.InitialState else Init.NoInit) if with_D;
        Modelica.Blocks.Math.Gain gainPID(k = k);
        Modelica.Blocks.Math.Add3 addPID;
        Modelica.Blocks.Math.Add3 addI(k2 = -1) if with_I;
        Modelica.Blocks.Math.Add addSat(k1 = +1, k2 = -1) if with_I;
        Modelica.Blocks.Math.Gain gainTrack(k = 1/(k*Ni)) if with_I;
        Modelica.Blocks.Nonlinear.Limiter limiter(uMax = yMax, uMin = yMin, strict = strict, homotopyType = homotopyType);
      protected
        parameter Boolean with_I = controllerType == SimpleController.PI or controllerType == SimpleController.PID annotation(Evaluate = true, HideResult = true);
        parameter Boolean with_D = controllerType == SimpleController.PD or controllerType == SimpleController.PID annotation(Evaluate = true, HideResult = true);
      public
        Modelica.Blocks.Sources.Constant Dzero(k = 0) if not with_D;
        Modelica.Blocks.Sources.Constant Izero(k = 0) if not with_I;
        Modelica.Blocks.Sources.Constant FFzero(k = 0) if not withFeedForward;
        Modelica.Blocks.Math.Add addFF(k1 = 1, k2 = kFF);
      initial equation
        if initType == Init.InitialOutput then
          gainPID.y = y_start;
        end if;
      equation
        assert(abs(k) >= Modelica.Constants.small, "Controller gain must be non-zero.");
        if initType == Init.InitialOutput and (y_start < yMin or y_start > yMax) then
          Modelica.Utilities.Streams.error("LimPID: Start value y_start (=" + String(y_start) + ") is outside of the limits of yMin (=" + String(yMin) + ") and yMax (=" + String(yMax) + ")");
        end if;
        connect(u_s, addP.u1);
        connect(u_s, addD.u1);
        connect(u_s, addI.u1);
        connect(addP.y, P.u);
        connect(addD.y, D.u);
        connect(addI.y, I.u);
        connect(P.y, addPID.u1);
        connect(D.y, addPID.u2);
        connect(I.y, addPID.u3);
        connect(limiter.y, addSat.u1);
        connect(limiter.y, y);
        connect(addSat.y, gainTrack.u);
        connect(gainTrack.y, addI.u3);
        connect(u_m, addP.u2);
        connect(u_m, addD.u2);
        connect(u_m, addI.u2);
        connect(Dzero.y, addPID.u2);
        connect(Izero.y, addPID.u3);
        connect(addPID.y, gainPID.u);
        connect(addFF.y, limiter.u);
        connect(gainPID.y, addFF.u1);
        connect(FFzero.y, addFF.u2);
        connect(addFF.u2, u_ff);
        connect(addFF.y, addSat.u2);
      end LimPID;

      package Internal "Internal utility functions and blocks that should not be directly utilized by the user" end Internal;
    end Continuous;

    package Interfaces "Library of connectors and partial models for input/output blocks"
      connector RealInput = input Real "'input Real' as connector";
      connector RealOutput = output Real "'output Real' as connector";
      connector BooleanInput = input Boolean "'input Boolean' as connector";
      connector BooleanOutput = output Boolean "'output Boolean' as connector";

      partial block SO "Single Output continuous control block"
        RealOutput y "Connector of Real output signal";
      end SO;

      partial block SISO "Single Input Single Output continuous control block"
        RealInput u "Connector of Real input signal";
        RealOutput y "Connector of Real output signal";
      end SISO;

      partial block SI2SO "2 Single Input / 1 Single Output continuous control block"
        RealInput u1 "Connector of Real input signal 1";
        RealInput u2 "Connector of Real input signal 2";
        RealOutput y "Connector of Real output signal";
      end SI2SO;

      partial block SignalSource "Base class for continuous signal source"
        extends SO;
        parameter Real offset = 0 "Offset of output signal y";
        parameter SI.Time startTime = 0 "Output y = offset for time < startTime";
      end SignalSource;

      partial block SVcontrol "Single-Variable continuous controller"
        RealInput u_s "Connector of setpoint input signal";
        RealInput u_m "Connector of measurement input signal";
        RealOutput y "Connector of actuator output signal";
      end SVcontrol;
    end Interfaces;

    package Math "Library of Real mathematical functions as input/output blocks"
      import Modelica.Blocks.Interfaces;

      block Gain "Output the product of a gain value with the input signal"
        parameter Real k(start = 1) "Gain value multiplied with input signal";
        Interfaces.RealInput u "Input signal connector";
        Interfaces.RealOutput y "Output signal connector";
      equation
        y = k*u;
      end Gain;

      block Feedback "Output difference between commanded and feedback input"
        Interfaces.RealInput u1 "Commanded input";
        Interfaces.RealInput u2 "Feedback input";
        Interfaces.RealOutput y;
      equation
        y = u1 - u2;
      end Feedback;

      block Add "Output the sum of the two inputs"
        extends Interfaces.SI2SO;
        parameter Real k1 = +1 "Gain of input signal 1";
        parameter Real k2 = +1 "Gain of input signal 2";
      equation
        y = k1*u1 + k2*u2;
      end Add;

      block Add3 "Output the sum of the three inputs"
        parameter Real k1 = +1 "Gain of input signal 1";
        parameter Real k2 = +1 "Gain of input signal 2";
        parameter Real k3 = +1 "Gain of input signal 3";
        Interfaces.RealInput u1 "Connector of Real input signal 1";
        Interfaces.RealInput u2 "Connector of Real input signal 2";
        Interfaces.RealInput u3 "Connector of Real input signal 3";
        Interfaces.RealOutput y "Connector of Real output signal";
      equation
        y = k1*u1 + k2*u2 + k3*u3;
      end Add3;

      block Power "Output the power to a base of the input"
        extends Interfaces.SISO;
        parameter Real base = Modelica.Constants.e "Base of power" annotation(Evaluate = true);
        parameter Boolean useExp = true "Use exp function in implementation" annotation(Evaluate = true);
      equation
        y = if useExp then Modelica.Math.exp(u*Modelica.Math.log(base)) else base^u;
      end Power;
    end Math;

    package Nonlinear "Library of discontinuous or non-differentiable algebraic control blocks"
      import Modelica.Blocks.Interfaces;

      block Limiter "Limit the range of a signal"
        parameter Real uMax(start = 1) "Upper limits of input signals";
        parameter Real uMin = -uMax "Lower limits of input signals";
        parameter Boolean strict = false "= true, if strict limits with noEvent(..)" annotation(Evaluate = true);
        parameter Types.LimiterHomotopy homotopyType = Modelica.Blocks.Types.LimiterHomotopy.Linear "Simplified model for homotopy-based initialization" annotation(Evaluate = true);
        extends Interfaces.SISO;
      protected
        Real simplifiedExpr "Simplified expression for homotopy-based initialization";
      equation
        assert(uMax >= uMin, "Limiter: Limits must be consistent. However, uMax (=" + String(uMax) + ") < uMin (=" + String(uMin) + ")");
        simplifiedExpr = (if homotopyType == Types.LimiterHomotopy.Linear then u else if homotopyType == Types.LimiterHomotopy.UpperLimit then uMax else if homotopyType == Types.LimiterHomotopy.LowerLimit then uMin else 0);
        if strict then
          if homotopyType == Types.LimiterHomotopy.NoHomotopy then
            y = smooth(0, noEvent(if u > uMax then uMax else if u < uMin then uMin else u));
          else
            y = homotopy(actual = smooth(0, noEvent(if u > uMax then uMax else if u < uMin then uMin else u)), simplified = simplifiedExpr);
          end if;
        else
          if homotopyType == Types.LimiterHomotopy.NoHomotopy then
            y = smooth(0, if u > uMax then uMax else if u < uMin then uMin else u);
          else
            y = homotopy(actual = smooth(0, if u > uMax then uMax else if u < uMin then uMin else u), simplified = simplifiedExpr);
          end if;
        end if;
      end Limiter;
    end Nonlinear;

    package Sources "Library of signal source blocks generating Real, Integer and Boolean signals"
      import Modelica.Blocks.Interfaces;

      block RealExpression "Set output signal to a time varying Real expression"
        Modelica.Blocks.Interfaces.RealOutput y = 0.0 "Value of Real output";
      end RealExpression;

      block Constant "Generate constant signal of type Real"
        parameter Real k(start = 1) "Constant output value";
        extends Interfaces.SO;
      equation
        y = k;
      end Constant;

      block Pulse "Generate pulse signal of type Real"
        parameter Real amplitude = 1 "Amplitude of pulse";
        parameter Real width(final min = Modelica.Constants.small, final max = 100) = 50 "Width of pulse in % of period";
        parameter SI.Time period(final min = Modelica.Constants.small, start = 1) "Time for one period";
        parameter Integer nperiod = -1 "Number of periods (< 0 means infinite number of periods)";
        extends Interfaces.SignalSource;
      protected
        SI.Time T_width = period*width/100;
        SI.Time T_start "Start time of current period";
        Integer count "Period count";
      initial algorithm
        count := integer((time - startTime)/period);
        T_start := startTime + count*period;
      equation
        when time >= (pre(count) + 1)*period + startTime then
          count = pre(count) + 1;
          T_start = time;
        end when;
        y = offset + (if (time < startTime or nperiod == 0 or (nperiod > 0 and count >= nperiod)) then 0 else if time < T_start + T_width then amplitude else 0);
      end Pulse;
    end Sources;

    package Types "Library of constants, external objects and types with choices, especially to build menus"
      type Init = enumeration(NoInit "No initialization (start values are used as guess values with fixed=false)", SteadyState "Steady state initialization (derivatives of states are zero)", InitialState "Initialization with initial states", InitialOutput "Initialization with initial outputs (and steady state of the states if possible)") "Enumeration defining initialization of a block" annotation(Evaluate = true);
      type SimpleController = enumeration(P "P controller", PI "PI controller", PD "PD controller", PID "PID controller") "Enumeration defining P, PI, PD, or PID simple controller type" annotation(Evaluate = true);
      type LimiterHomotopy = enumeration(NoHomotopy "Homotopy is not used", Linear "Simplified model without limits", UpperLimit "Simplified model fixed at upper limit", LowerLimit "Simplified model fixed at lower limit") "Enumeration defining use of homotopy in limiter components" annotation(Evaluate = true);
    end Types;

    package Icons "Icons for Blocks"
      partial block Block "Basic graphical layout of input/output block" end Block;
    end Icons;
  end Blocks;

  package Mechanics "Library of 1-dim. and 3-dim. mechanical components (multi-body, rotational, translational)"
    import Modelica.Units.SI;

    package Rotational "Library to model 1-dimensional, rotational mechanical systems"
      package Examples "Demonstration examples of the components of this package"
        package Utilities "Utility classes used by rotational example models" end Utilities;
      end Examples;

      package Components "Components for 1D rotational mechanical drive trains" end Components;

      package Sensors "Sensors to measure variables in 1D rotational mechanical components" end Sensors;

      package Sources "Sources to drive 1D rotational mechanical components"
        model Torque "Input signal acting as external torque on a flange"
          extends Modelica.Mechanics.Rotational.Interfaces.PartialElementaryOneFlangeAndSupport2;
          Modelica.Blocks.Interfaces.RealInput tau(unit = "N.m") "Accelerating torque acting at flange (= -flange.tau)";
        equation
          flange.tau = -tau;
        end Torque;
      end Sources;

      package Interfaces "Connectors and partial models for 1D rotational mechanical components"
        connector Flange "One-dimensional rotational flange"
          SI.Angle phi "Absolute rotation angle of flange";
          flow SI.Torque tau "Cut torque in the flange";
        end Flange;

        connector Flange_a "One-dimensional rotational flange of a shaft (filled circle icon)"
          extends Flange;
        end Flange_a;

        connector Flange_b "One-dimensional rotational flange of a shaft (non-filled circle icon)"
          extends Flange;
        end Flange_b;

        connector Support "Support/housing flange of a one-dimensional rotational shaft"
          extends Flange;
        end Support;

        partial model PartialElementaryOneFlangeAndSupport2 "Partial model for a component with one rotational 1-dim. shaft flange and a support used for textual modeling, i.e., for elementary models"
          parameter Boolean useSupport = false "= true, if support flange enabled, otherwise implicitly grounded" annotation(Evaluate = true, HideResult = true);
          Flange_b flange "Flange of shaft";
          Support support(phi = phi_support, tau = -flange.tau) if useSupport "Support/housing of component" annotation(mustBeConnected = "An enabled support connector should be connected");
        protected
          SI.Angle phi_support "Absolute angle of support flange";
        equation
          if not useSupport then
            phi_support = 0;
          end if;
        end PartialElementaryOneFlangeAndSupport2;

        partial model PartialAbsoluteSensor "Partial model to measure a single absolute flange variable"
          Flange_a flange "Flange of shaft from which sensor information shall be measured";
        equation
          0 = flange.tau;
        end PartialAbsoluteSensor;
      end Interfaces;

      package Icons "Icons for Rotational package" end Icons;
    end Rotational;
  end Mechanics;

  package Fluid "Library of 1-dim. thermo-fluid flow models using the Modelica.Media media description"
    import Modelica.Units.SI;
    import Cv = Modelica.Units.Conversions;

    package Examples "Demonstration of the usage of the library" end Examples;

    model System "System properties and default values (ambient, flow direction, initialization)"
      package Medium = Modelica.Media.Interfaces.PartialMedium "Medium model for default start values" annotation(choicesAllMatching = true);
      parameter SI.AbsolutePressure p_ambient = 101325 "Default ambient pressure";
      parameter SI.Temperature T_ambient = 293.15 "Default ambient temperature";
      parameter SI.Acceleration g = Modelica.Constants.g_n "Constant gravity acceleration";
      parameter Boolean allowFlowReversal = true "= false to restrict to design flow direction (port_a -> port_b)" annotation(Evaluate = true);
      parameter Modelica.Fluid.Types.Dynamics energyDynamics = Modelica.Fluid.Types.Dynamics.DynamicFreeInitial "Default formulation of energy balances" annotation(Evaluate = true);
      parameter Modelica.Fluid.Types.Dynamics massDynamics = energyDynamics "Default formulation of mass balances" annotation(Evaluate = true);
      final parameter Modelica.Fluid.Types.Dynamics substanceDynamics = massDynamics "Default formulation of substance balances" annotation(Evaluate = true);
      final parameter Modelica.Fluid.Types.Dynamics traceDynamics = massDynamics "Default formulation of trace substance balances" annotation(Evaluate = true);
      parameter Modelica.Fluid.Types.Dynamics momentumDynamics = Modelica.Fluid.Types.Dynamics.SteadyState "Default formulation of momentum balances, if options available" annotation(Evaluate = true);
      parameter SI.MassFlowRate m_flow_start = 0 "Default start value for mass flow rates";
      parameter SI.AbsolutePressure p_start = p_ambient "Default start value for pressures";
      parameter SI.Temperature T_start = T_ambient "Default start value for temperatures";
      parameter Boolean use_eps_Re = false "= true to determine turbulent region automatically using Reynolds number" annotation(Evaluate = true);
      parameter SI.MassFlowRate m_flow_nominal = if use_eps_Re then 1 else 1e2*m_flow_small "Default nominal mass flow rate";
      parameter Real eps_m_flow(min = 0) = 1e-4 "Regularization of zero flow for |m_flow| < eps_m_flow*m_flow_nominal";
      parameter SI.AbsolutePressure dp_small(min = 0) = 1 "Default small pressure drop for regularization of laminar and zero flow";
      parameter SI.MassFlowRate m_flow_small(min = 0) = 1e-2 "Default small mass flow rate for regularization of laminar and zero flow";
      annotation(defaultComponentPrefixes = "inner", missingInnerMessage = "
    Your model is using an outer \"system\" component but
    an inner \"system\" component is not defined.
    For simulation drag Modelica.Fluid.System into your model
    to specify system properties.");
    end System;

    package Sources "Define fixed or prescribed boundary conditions"
      package BaseClasses "Base classes used in the Sources package (only of interest to build new component models)" end BaseClasses;
    end Sources;

    package Sensors "Ideal sensor components to extract signals from a fluid connector"
      model Pressure "Ideal pressure sensor"
        extends Sensors.BaseClasses.PartialAbsoluteSensor;
        Modelica.Blocks.Interfaces.RealOutput p(final quantity = "Pressure", final unit = "Pa", displayUnit = "bar", min = 0) "Pressure at port";
      equation
        p = port.p;
      end Pressure;

      model Density "Ideal one port density sensor"
        extends Sensors.BaseClasses.PartialAbsoluteSensor;
        Modelica.Blocks.Interfaces.RealOutput d(final quantity = "Density", final unit = "kg/m3", displayUnit = "g/cm3", min = 0) "Density in port medium";
      equation
        d = Medium.density(Medium.setState_phX(port.p, inStream(port.h_outflow), inStream(port.Xi_outflow)));
      end Density;

      model Temperature "Ideal one port temperature sensor"
        extends Sensors.BaseClasses.PartialAbsoluteSensor;
        Modelica.Blocks.Interfaces.RealOutput T(final quantity = "ThermodynamicTemperature", final unit = "K", displayUnit = "degC", min = 0) "Temperature in port medium";
      equation
        T = Medium.temperature(Medium.setState_phX(port.p, inStream(port.h_outflow), inStream(port.Xi_outflow)));
      end Temperature;

      model SpecificEnthalpy "Ideal one port specific enthalpy sensor"
        extends Sensors.BaseClasses.PartialAbsoluteSensor;
        Modelica.Blocks.Interfaces.RealOutput h_out(final quantity = "SpecificEnergy", final unit = "J/kg") "Specific enthalpy in port medium";
      equation
        h_out = inStream(port.h_outflow);
      end SpecificEnthalpy;

      model SpecificEntropy "Ideal one port specific entropy sensor"
        extends Sensors.BaseClasses.PartialAbsoluteSensor;
        Modelica.Blocks.Interfaces.RealOutput s(final quantity = "SpecificEntropy", final unit = "J/(kg.K)") "Specific entropy in port medium";
      equation
        s = Medium.specificEntropy(Medium.setState_phX(port.p, inStream(port.h_outflow), inStream(port.Xi_outflow)));
      end SpecificEntropy;

      model MassFlowRate "Ideal sensor for mass flow rate"
        extends Sensors.BaseClasses.PartialFlowSensor;
        Modelica.Blocks.Interfaces.RealOutput m_flow(quantity = "MassFlowRate", final unit = "kg/s") "Mass flow rate from port_a to port_b";
      equation
        m_flow = port_a.m_flow;
      end MassFlowRate;

      model VolumeFlowRate "Ideal sensor for volume flow rate"
        extends Sensors.BaseClasses.PartialFlowSensor;
        Modelica.Blocks.Interfaces.RealOutput V_flow(final quantity = "VolumeFlowRate", final unit = "m3/s") "Volume flow rate from port_a to port_b";
      protected
        Medium.Density rho_a_inflow "Density of inflowing fluid at port_a";
        Medium.Density rho_b_inflow "Density of inflowing fluid at port_b or rho_a_inflow, if uni-directional flow";
        Medium.Density d "Density of the passing fluid";
      equation
        if allowFlowReversal then
          rho_a_inflow = Medium.density(Medium.setState_phX(port_b.p, port_b.h_outflow, port_b.Xi_outflow));
          rho_b_inflow = Medium.density(Medium.setState_phX(port_a.p, port_a.h_outflow, port_a.Xi_outflow));
          d = Modelica.Fluid.Utilities.regStep(port_a.m_flow, rho_a_inflow, rho_b_inflow, m_flow_small);
        else
          d = Medium.density(Medium.setState_phX(port_b.p, port_b.h_outflow, port_b.Xi_outflow));
          rho_a_inflow = d;
          rho_b_inflow = d;
        end if;
        V_flow = port_a.m_flow/d;
      end VolumeFlowRate;

      package BaseClasses "Base classes used in the Sensors package (only of interest to build new component models)"
        partial model PartialAbsoluteSensor "Partial component to model a sensor that measures a potential variable"
          replaceable package Medium = Modelica.Media.Interfaces.PartialMedium "Medium in the sensor" annotation(choicesAllMatching = true);
          Modelica.Fluid.Interfaces.FluidPort_a port(redeclare package Medium = Medium, m_flow(min = 0));
        equation
          port.m_flow = 0;
          port.h_outflow = Medium.h_default;
          port.Xi_outflow = Medium.X_default[1:Medium.nXi];
          port.C_outflow = zeros(Medium.nC);
        end PartialAbsoluteSensor;

        partial model PartialFlowSensor "Partial component to model sensors that measure flow properties"
          extends Modelica.Fluid.Interfaces.PartialTwoPort;
          parameter Medium.MassFlowRate m_flow_nominal = system.m_flow_nominal "Nominal value of m_flow = port_a.m_flow";
          parameter Medium.MassFlowRate m_flow_small(min = 0) = if system.use_eps_Re then system.eps_m_flow*m_flow_nominal else system.m_flow_small "Regularization for bi-directional flow in the region |m_flow| < m_flow_small (m_flow_small > 0 required)";
        equation
          0 = port_a.m_flow + port_b.m_flow;
          port_a.p = port_b.p;
          port_a.h_outflow = inStream(port_b.h_outflow);
          port_b.h_outflow = inStream(port_a.h_outflow);
          port_a.Xi_outflow = inStream(port_b.Xi_outflow);
          port_b.Xi_outflow = inStream(port_a.Xi_outflow);
          port_a.C_outflow = inStream(port_b.C_outflow);
          port_b.C_outflow = inStream(port_a.C_outflow);
        end PartialFlowSensor;
      end BaseClasses;
    end Sensors;

    package Interfaces "Interfaces for steady state and unsteady, mixed-phase, multi-substance, incompressible and compressible flow"
      connector FluidPort "Interface for quasi one-dimensional fluid flow in a piping network (incompressible or compressible, one or more phases, one or more substances)"
        replaceable package Medium = Modelica.Media.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
        flow Medium.MassFlowRate m_flow "Mass flow rate from the connection point into the component";
        Medium.AbsolutePressure p "Thermodynamic pressure in the connection point";
        stream Medium.SpecificEnthalpy h_outflow "Specific thermodynamic enthalpy close to the connection point if m_flow < 0";
        stream Medium.MassFraction Xi_outflow[Medium.nXi] "Independent mixture mass fractions m_i/m close to the connection point if m_flow < 0";
        stream Medium.ExtraProperty C_outflow[Medium.nC] "Properties c_i/m close to the connection point if m_flow < 0";
      end FluidPort;

      connector FluidPort_a "Generic fluid connector at design inlet"
        extends FluidPort;
      end FluidPort_a;

      connector FluidPort_b "Generic fluid connector at design outlet"
        extends FluidPort;
      end FluidPort_b;

      partial model PartialTwoPort "Partial component with two ports"
        import Modelica.Constants;
        outer Modelica.Fluid.System system "System wide properties";
        replaceable package Medium = Modelica.Media.Interfaces.PartialMedium "Medium in the component" annotation(choicesAllMatching = true);
        parameter Boolean allowFlowReversal = system.allowFlowReversal "= true to allow flow reversal, false restricts to design direction (port_a -> port_b)" annotation(Evaluate = true);
        Modelica.Fluid.Interfaces.FluidPort_a port_a(redeclare package Medium = Medium, m_flow(min = if allowFlowReversal then -Constants.inf else 0)) "Fluid connector a (positive design flow direction is from port_a to port_b)";
        Modelica.Fluid.Interfaces.FluidPort_b port_b(redeclare package Medium = Medium, m_flow(max = if allowFlowReversal then +Constants.inf else 0)) "Fluid connector b (positive design flow direction is from port_a to port_b)";
      protected
        parameter Boolean port_a_exposesState = false "= true if port_a exposes the state of a fluid volume";
        parameter Boolean port_b_exposesState = false "= true if port_b.p exposes the state of a fluid volume";
        parameter Boolean showDesignFlowDirection = true "= false to hide the arrow in the model icon";
      end PartialTwoPort;
    end Interfaces;

    package Types "Common types for fluid models"
      type Dynamics = enumeration(DynamicFreeInitial "DynamicFreeInitial -- Dynamic balance, Initial guess value", FixedInitial "FixedInitial -- Dynamic balance, Initial value fixed", SteadyStateInitial "SteadyStateInitial -- Dynamic balance, Steady state initial with guess value", SteadyState "SteadyState -- Steady state balance, Initial guess value") "Enumeration to define definition of balance equations";
    end Types;

    package Utilities "Utility models to construct fluid components (should not be used directly)"
      function regSquare "Anti-symmetric square approximation with non-zero derivative in the origin"
        input Real x;
        input Real delta = 0.01 "Range of significant deviation from x^2*sgn(x)";
        output Real y;
      algorithm
        y := x*sqrt(x*x + delta*delta);
      end regSquare;

      function regPow "Anti-symmetric power approximation with non-zero derivative in the origin"
        input Real x;
        input Real a;
        input Real delta = 0.01 "Range of significant deviation from x^a*sgn(x)";
        output Real y;
      algorithm
        y := x*(x*x + delta*delta)^((a - 1)/2);
      end regPow;

      function regStep "Approximation of a general step, such that the characteristic is continuous and differentiable"
        input Real x "Abscissa value";
        input Real y1 "Ordinate value for x > 0";
        input Real y2 "Ordinate value for x < 0";
        input Real x_small(min = 0) = 1e-5 "Approximation of step for -x_small <= x <= x_small; x_small >= 0 required";
        output Real y "Ordinate value to approximate y = if x > 0 then y1 else y2";
      algorithm
        y := smooth(1, if x > x_small then y1 else if x < -x_small then y2 else if x_small > 0 then (x/x_small)*((x/x_small)^2 - 3)*(y2 - y1)/4 + (y1 + y2)/2 else (y1 + y2)/2);
      end regStep;
    end Utilities;
  end Fluid;

  package Media "Library of media property models"
    import Modelica.Units.SI;
    import Cv = Modelica.Units.Conversions;

    package Examples "Demonstrate usage of property models"
      package Utilities "Functions, connectors and models needed for the media model tests"
        connector FluidPort "Interface for quasi one-dimensional fluid flow in a piping network (incompressible or compressible, one or more phases, one or more substances)"
          replaceable package Medium = Modelica.Media.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
          Medium.AbsolutePressure p "Pressure in the connection point";
          flow Medium.MassFlowRate m_flow "Mass flow rate from the connection point into the component";
          Medium.SpecificEnthalpy h "Specific mixture enthalpy in the connection point";
          flow Medium.EnthalpyFlowRate H_flow "Enthalpy flow rate into the component (if m_flow > 0, H_flow = m_flow*h)";
          Medium.MassFraction Xi[Medium.nXi] "Independent mixture mass fractions m_i/m in the connection point";
          flow Medium.MassFlowRate mXi_flow[Medium.nXi] "Mass flow rates of the independent substances from the connection point into the component (if m_flow > 0, mX_flow = m_flow*X)";
          Medium.ExtraProperty C[Medium.nC] "Properties c_i/m in the connection point";
          flow Medium.ExtraPropertyFlowRate mC_flow[Medium.nC] "Flow rates of auxiliary properties from the connection point into the component (if m_flow > 0, mC_flow = m_flow*C)";
        end FluidPort;

        connector FluidPort_a "Fluid connector with filled icon"
          extends FluidPort;
        end FluidPort_a;

        connector FluidPort_b "Fluid connector with outlined icon"
          extends FluidPort;
        end FluidPort_b;
      end Utilities;
    end Examples;

    package Interfaces "Interfaces for media models"
      partial package PartialMedium "Partial medium properties (base package of all media packages)"
        extends Modelica.Media.Interfaces.Types;
        constant Modelica.Media.Interfaces.Choices.IndependentVariables ThermoStates "Enumeration type for independent variables";
        constant String mediumName = "unusablePartialMedium" "Name of the medium";
        constant String substanceNames[:] = {mediumName} "Names of the mixture substances. Set substanceNames={mediumName} if only one substance.";
        constant String extraPropertiesNames[:] = fill("", 0) "Names of the additional (extra) transported properties. Set extraPropertiesNames=fill(\"\",0) if unused";
        constant Boolean singleState "= true, if u and d are not a function of pressure";
        constant Boolean reducedX = true "= true, if medium contains the equation sum(X) = 1.0; set reducedX=true, if only one substance (see docu for details)";
        constant Boolean fixedX = false "= true, if medium contains the equation X = reference_X";
        constant AbsolutePressure reference_p = 101325 "Reference pressure of Medium: default 1 atmosphere";
        constant Temperature reference_T = 298.15 "Reference temperature of Medium: default 25 deg Celsius";
        constant MassFraction reference_X[nX] = fill(1/nX, nX) "Default mass fractions of medium";
        constant AbsolutePressure p_default = 101325 "Default value for pressure of medium (for initialization)";
        constant Temperature T_default = Modelica.Units.Conversions.from_degC(20) "Default value for temperature of medium (for initialization)";
        constant SpecificEnthalpy h_default = specificEnthalpy_pTX(p_default, T_default, X_default) "Default value for specific enthalpy of medium (for initialization)";
        constant MassFraction X_default[nX] = reference_X "Default value for mass fractions of medium (for initialization)";
        constant ExtraProperty C_default[nC] = fill(0, nC) "Default value for trace substances of medium (for initialization)";
        final constant Integer nS = size(substanceNames, 1) "Number of substances";
        constant Integer nX = nS "Number of mass fractions";
        constant Integer nXi = if fixedX then 0 else if reducedX then nS - 1 else nS "Number of structurally independent mass fractions (see docu for details)";
        final constant Integer nC = size(extraPropertiesNames, 1) "Number of extra (outside of standard mass-balance) transported properties";
        constant Real C_nominal[nC](min = fill(Modelica.Constants.eps, nC)) = 1.0e-6*ones(nC) "Default for the nominal values for the extra properties";
        replaceable record FluidConstants = Modelica.Media.Interfaces.Types.Basic.FluidConstants "Critical, triple, molecular and other standard data of fluid";

        replaceable record ThermodynamicState "Minimal variable set that is available as input argument to every medium function" end ThermodynamicState;

        replaceable partial model BaseProperties "Base properties (p, d, T, h, u, R_s, MM and, if applicable, X and Xi) of a medium"
          InputAbsolutePressure p "Absolute pressure of medium";
          InputMassFraction Xi[nXi](start = reference_X[1:nXi]) "Structurally independent mass fractions";
          InputSpecificEnthalpy h "Specific enthalpy of medium";
          Density d "Density of medium";
          Temperature T "Temperature of medium";
          MassFraction X[nX](start = reference_X) "Mass fractions (= (component mass)/total mass  m_i/m)";
          SpecificInternalEnergy u "Specific internal energy of medium";
          SpecificHeatCapacity R_s "Gas constant (of mixture if applicable)";
          MolarMass MM "Molar mass (of mixture or single fluid)";
          ThermodynamicState state "Thermodynamic state record for optional functions";
          parameter Boolean preferredMediumStates = false "= true, if StateSelect.prefer shall be used for the independent property variables of the medium" annotation(Evaluate = true);
          parameter Boolean standardOrderComponents = true "If true, and reducedX = true, the last element of X will be computed from the other ones";
          Modelica.Units.NonSI.Temperature_degC T_degC = Modelica.Units.Conversions.to_degC(T) "Temperature of medium in [degC]";
          Modelica.Units.NonSI.Pressure_bar p_bar = Modelica.Units.Conversions.to_bar(p) "Absolute pressure of medium in [bar]";
          connector InputAbsolutePressure = input SI.AbsolutePressure "Pressure as input signal connector";
          connector InputSpecificEnthalpy = input SI.SpecificEnthalpy "Specific enthalpy as input signal connector";
          connector InputMassFraction = input SI.MassFraction "Mass fraction as input signal connector";
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
              assert(X[i] >= -1.e-5 and X[i] <= 1 + 1.e-5, "Mass fraction X[" + String(i) + "] = " + String(X[i]) + "of substance " + substanceNames[i] + "\nof medium " + mediumName + " is not in the range 0..1");
            end for;
          end if;
          assert(p >= 0.0, "Pressure (= " + String(p) + " Pa) of medium \"" + mediumName + "\" is negative\n(Temperature = " + String(T) + " K)");
        end BaseProperties;

        replaceable partial function setState_pTX "Return thermodynamic state as function of p, T and composition X or Xi"
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input MassFraction X[:] = reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state record";
        end setState_pTX;

        replaceable partial function setState_phX "Return thermodynamic state as function of p, h and composition X or Xi"
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction X[:] = reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state record";
        end setState_phX;

        replaceable partial function setState_dTX "Return thermodynamic state as function of d, T and composition X or Xi"
          input Density d "Density";
          input Temperature T "Temperature";
          input MassFraction X[:] = reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state record";
        end setState_dTX;

        replaceable partial function dynamicViscosity "Return dynamic viscosity"
          input ThermodynamicState state "Thermodynamic state record";
          output DynamicViscosity eta "Dynamic viscosity";
        end dynamicViscosity;

        replaceable partial function pressure "Return pressure"
          input ThermodynamicState state "Thermodynamic state record";
          output AbsolutePressure p "Pressure";
        end pressure;

        replaceable partial function temperature "Return temperature"
          input ThermodynamicState state "Thermodynamic state record";
          output Temperature T "Temperature";
        end temperature;

        replaceable partial function density "Return density"
          input ThermodynamicState state "Thermodynamic state record";
          output Density d "Density";
        end density;

        replaceable partial function specificEnthalpy "Return specific enthalpy"
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificEnthalpy h "Specific enthalpy";
        end specificEnthalpy;

        replaceable partial function specificEntropy "Return specific entropy"
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificEntropy s "Specific entropy";
        end specificEntropy;

        replaceable partial function specificHeatCapacityCp "Return specific heat capacity at constant pressure"
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificHeatCapacity cp "Specific heat capacity at constant pressure";
        end specificHeatCapacityCp;

        replaceable partial function specificHeatCapacityCv "Return specific heat capacity at constant volume"
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificHeatCapacity cv "Specific heat capacity at constant volume";
        end specificHeatCapacityCv;

        replaceable partial function isentropicExponent "Return isentropic exponent"
          input ThermodynamicState state "Thermodynamic state record";
          output IsentropicExponent gamma "Isentropic exponent";
        end isentropicExponent;

        replaceable partial function velocityOfSound "Return velocity of sound"
          input ThermodynamicState state "Thermodynamic state record";
          output VelocityOfSound a "Velocity of sound";
        end velocityOfSound;

        replaceable partial function isobaricExpansionCoefficient "Return overall the isobaric expansion coefficient beta"
          input ThermodynamicState state "Thermodynamic state record";
          output IsobaricExpansionCoefficient beta "Isobaric expansion coefficient";
        end isobaricExpansionCoefficient;

        function beta = isobaricExpansionCoefficient "Alias for isobaricExpansionCoefficient for user convenience";

        replaceable partial function density_derp_h "Return density derivative w.r.t. pressure at constant specific enthalpy"
          input ThermodynamicState state "Thermodynamic state record";
          output DerDensityByPressure ddph "Density derivative w.r.t. pressure";
        end density_derp_h;

        replaceable partial function molarMass "Return the molar mass of the medium"
          input ThermodynamicState state "Thermodynamic state record";
          output MolarMass MM "Mixture molar mass";
        end molarMass;

        replaceable function specificEnthalpy_pTX "Return specific enthalpy from p, T, and X or Xi"
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input MassFraction X[:] = reference_X "Mass fractions";
          output SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := specificEnthalpy(setState_pTX(p, T, X));
          annotation(inverse(T = temperature_phX(p, h, X)));
        end specificEnthalpy_pTX;

        replaceable function temperature_phX "Return temperature from p, h, and X or Xi"
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction X[:] = reference_X "Mass fractions";
          output Temperature T "Temperature";
        algorithm
          T := temperature(setState_phX(p, h, X));
        end temperature_phX;

        replaceable function density_phX "Return density from p, h, and X or Xi"
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction X[:] = reference_X "Mass fractions";
          output Density d "Density";
        algorithm
          d := density(setState_phX(p, h, X));
        end density_phX;

        replaceable partial function massFraction "Return independent mass fractions (if any)"
          input ThermodynamicState state "Thermodynamic state record";
          output MassFraction Xi[nXi] "Independent mass fractions";
        end massFraction;

        type MassFlowRate = SI.MassFlowRate(quantity = "MassFlowRate." + mediumName, min = -1.0e5, max = 1.e5) "Type for mass flow rate with medium specific attributes";
      end PartialMedium;

      partial package PartialPureSubstance "Base class for pure substances of one chemical substance"
        extends PartialMedium(final reducedX = true, final fixedX = true);

        replaceable function density_ph "Return density from p and h"
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          output Density d "Density";
        algorithm
          d := density_phX(p, h, fill(0.0, 0));
        end density_ph;

        replaceable function temperature_ph "Return temperature from p and h"
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          output Temperature T "Temperature";
        algorithm
          T := temperature_phX(p, h, fill(0.0, 0));
        end temperature_ph;

        replaceable function pressure_dT "Return pressure from d and T"
          input Density d "Density";
          input Temperature T "Temperature";
          output AbsolutePressure p "Pressure";
        algorithm
          p := pressure(setState_dTX(d, T, fill(0.0, 0)));
        end pressure_dT;

        replaceable function specificEnthalpy_dT "Return specific enthalpy from d and T"
          input Density d "Density";
          input Temperature T "Temperature";
          output SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := specificEnthalpy(setState_dTX(d, T, fill(0.0, 0)));
        end specificEnthalpy_dT;

        replaceable function specificEnthalpy_pT "Return specific enthalpy from p and T"
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          output SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := specificEnthalpy_pTX(p, T, fill(0.0, 0));
        end specificEnthalpy_pT;

        replaceable function density_pT "Return density from p and T"
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          output Density d "Density";
        algorithm
          d := density(setState_pTX(p, T, fill(0.0, 0)));
        end density_pT;

        redeclare replaceable function massFraction "Return independent mass fractions (if any)"
          input ThermodynamicState state "Thermodynamic state record";
          output MassFraction Xi[nXi] "Independent mass fractions";
        algorithm
          Xi := fill(0, 0);
        end massFraction;

        redeclare replaceable partial model extends BaseProperties(final standardOrderComponents = true) end BaseProperties;
      end PartialPureSubstance;

      partial package PartialTwoPhaseMedium "Base class for two phase medium of one substance"
        extends PartialPureSubstance(redeclare replaceable record FluidConstants = Modelica.Media.Interfaces.Types.TwoPhase.FluidConstants);
        constant Boolean smoothModel = false "= true, if the (derived) model should not generate state events";
        constant Boolean onePhase = false "= true, if the (derived) model should never be called with two-phase inputs";
        constant FluidConstants fluidConstants[nS] "Constant data for the fluid";

        redeclare replaceable record extends ThermodynamicState "Thermodynamic state of two phase medium"
          FixedPhase phase(min = 0, max = 2) "Phase of the fluid: 1 for 1-phase, 2 for two-phase, 0 for not known, e.g., interactive use";
        end ThermodynamicState;

        redeclare replaceable partial model extends BaseProperties "Base properties (p, d, T, h, u, R_s, MM, sat) of two phase medium"
          SaturationProperties sat "Saturation properties at the medium pressure";
        end BaseProperties;

        redeclare replaceable partial function extends setState_dTX "Return thermodynamic state as function of d, T and composition X or Xi"
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
        end setState_dTX;

        redeclare replaceable partial function extends setState_phX "Return thermodynamic state as function of p, h and composition X or Xi"
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
        end setState_phX;

        redeclare replaceable partial function extends setState_pTX "Return thermodynamic state as function of p, T and composition X or Xi"
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
        end setState_pTX;

        replaceable function setSat_p "Return saturation property record from pressure"
          input AbsolutePressure p "Pressure";
          output SaturationProperties sat "Saturation property record";
        algorithm
          sat.psat := p;
          sat.Tsat := saturationTemperature(p);
        end setSat_p;

        replaceable partial function bubbleEnthalpy "Return bubble point specific enthalpy"
          input SaturationProperties sat "Saturation property record";
          output SI.SpecificEnthalpy hl "Boiling curve specific enthalpy";
        end bubbleEnthalpy;

        replaceable partial function dewEnthalpy "Return dew point specific enthalpy"
          input SaturationProperties sat "Saturation property record";
          output SI.SpecificEnthalpy hv "Dew curve specific enthalpy";
        end dewEnthalpy;

        replaceable partial function bubbleDensity "Return bubble point density"
          input SaturationProperties sat "Saturation property record";
          output Density dl "Boiling curve density";
        end bubbleDensity;

        replaceable partial function dewDensity "Return dew point density"
          input SaturationProperties sat "Saturation property record";
          output Density dv "Dew curve density";
        end dewDensity;

        replaceable partial function saturationPressure "Return saturation pressure"
          input Temperature T "Temperature";
          output AbsolutePressure p "Saturation pressure";
        end saturationPressure;

        replaceable partial function saturationTemperature "Return saturation temperature"
          input AbsolutePressure p "Pressure";
          output Temperature T "Saturation temperature";
        end saturationTemperature;

        redeclare replaceable function extends molarMass "Return the molar mass of the medium"
        algorithm
          MM := fluidConstants[1].molarMass;
        end molarMass;

        redeclare replaceable function specificEnthalpy_pTX "Return specific enthalpy from pressure, temperature and mass fraction"
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input MassFraction X[:] "Mass fractions";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output SpecificEnthalpy h "Specific enthalpy at p, T, X";
        algorithm
          h := specificEnthalpy(setState_pTX(p, T, X, phase));
        end specificEnthalpy_pTX;

        redeclare replaceable function temperature_phX "Return temperature from p, h, and X or Xi"
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction X[:] "Mass fractions";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Temperature T "Temperature";
        algorithm
          T := temperature(setState_phX(p, h, X, phase));
        end temperature_phX;

        redeclare replaceable function density_phX "Return density from p, h, and X or Xi"
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction X[:] "Mass fractions";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Density d "Density";
        algorithm
          d := density(setState_phX(p, h, X, phase));
        end density_phX;

        replaceable function vapourQuality "Return vapour quality"
          input ThermodynamicState state "Thermodynamic state record";
          output MassFraction x "Vapour quality";
        protected
          constant SpecificEnthalpy eps = 1e-8;
        algorithm
          x := min(max((specificEnthalpy(state) - bubbleEnthalpy(setSat_p(pressure(state))))/(dewEnthalpy(setSat_p(pressure(state))) - bubbleEnthalpy(setSat_p(pressure(state))) + eps), 0), 1);
        end vapourQuality;

        redeclare replaceable function density_ph "Return density from p and h"
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Density d "Density";
        algorithm
          d := density_phX(p, h, fill(0.0, 0), phase);
        end density_ph;

        redeclare replaceable function temperature_ph "Return temperature from p and h"
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Temperature T "Temperature";
        algorithm
          T := temperature_phX(p, h, fill(0.0, 0), phase);
        end temperature_ph;

        redeclare replaceable function pressure_dT "Return pressure from d and T"
          input Density d "Density";
          input Temperature T "Temperature";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output AbsolutePressure p "Pressure";
        algorithm
          p := pressure(setState_dTX(d, T, fill(0.0, 0), phase));
        end pressure_dT;

        redeclare replaceable function specificEnthalpy_dT "Return specific enthalpy from d and T"
          input Density d "Density";
          input Temperature T "Temperature";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := specificEnthalpy(setState_dTX(d, T, fill(0.0, 0), phase));
        end specificEnthalpy_dT;

        redeclare replaceable function specificEnthalpy_pT "Return specific enthalpy from p and T"
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := specificEnthalpy_pTX(p, T, fill(0.0, 0), phase);
        end specificEnthalpy_pT;

        redeclare replaceable function density_pT "Return density from p and T"
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          output Density d "Density";
        algorithm
          d := density(setState_pTX(p, T, fill(0.0, 0), phase));
        end density_pT;
      end PartialTwoPhaseMedium;

      partial package PartialSimpleMedium "Medium model with linear dependency of u, h from temperature. All other quantities, especially density, are constant."
        extends Interfaces.PartialPureSubstance(final ThermoStates = Modelica.Media.Interfaces.Choices.IndependentVariables.pT, final singleState = true);
        constant SpecificHeatCapacity cp_const "Constant specific heat capacity at constant pressure";
        constant SpecificHeatCapacity cv_const "Constant specific heat capacity at constant volume";
        constant Density d_const "Constant density";
        constant DynamicViscosity eta_const "Constant dynamic viscosity";
        constant ThermalConductivity lambda_const "Constant thermal conductivity";
        constant VelocityOfSound a_const "Constant velocity of sound";
        constant Temperature T_min "Minimum temperature valid for medium model";
        constant Temperature T_max "Maximum temperature valid for medium model";
        constant Temperature T0 = reference_T "Zero enthalpy temperature";
        constant MolarMass MM_const "Molar mass";
        constant FluidConstants fluidConstants[nS] "Fluid constants";

        redeclare record extends ThermodynamicState "Thermodynamic state"
          AbsolutePressure p "Absolute pressure of medium";
          Temperature T "Temperature of medium";
        end ThermodynamicState;

        redeclare replaceable model extends BaseProperties(T(stateSelect = if preferredMediumStates then StateSelect.prefer else StateSelect.default), p(stateSelect = if preferredMediumStates then StateSelect.prefer else StateSelect.default)) "Base properties"
        equation
          assert(T >= T_min and T <= T_max, "
        Temperature T (= " + String(T) + " K) is not
        in the allowed range (" + String(T_min) + " K <= T <= " + String(T_max) + " K)
        required from medium model \"" + mediumName + "\".
          ");
          h = specificEnthalpy_pTX(p, T, X);
          u = cv_const*(T - T0);
          d = d_const;
          R_s = 0;
          MM = MM_const;
          state.T = T;
          state.p = p;
        end BaseProperties;

        redeclare function setState_pTX "Return thermodynamic state from p, T, and X or Xi"
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input MassFraction X[:] = reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state record";
        algorithm
          state := ThermodynamicState(p = p, T = T);
        end setState_pTX;

        redeclare function setState_phX "Return thermodynamic state from p, h, and X or Xi"
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction X[:] = reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state record";
        algorithm
          state := ThermodynamicState(p = p, T = T0 + h/cp_const);
        end setState_phX;

        redeclare function setState_dTX "Return thermodynamic state from d, T, and X or Xi"
          input Density d "Density";
          input Temperature T "Temperature";
          input MassFraction X[:] = reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state record";
        algorithm
          assert(false, "Pressure can not be computed from temperature and density for an incompressible fluid!");
        end setState_dTX;

        redeclare function extends dynamicViscosity "Return dynamic viscosity"
        algorithm
          eta := eta_const;
        end dynamicViscosity;

        redeclare function extends pressure "Return pressure"
        algorithm
          p := state.p;
        end pressure;

        redeclare function extends temperature "Return temperature"
        algorithm
          T := state.T;
        end temperature;

        redeclare function extends density "Return density"
        algorithm
          d := d_const;
        end density;

        redeclare function extends specificEnthalpy "Return specific enthalpy"
        algorithm
          h := cp_const*(state.T - T0);
        end specificEnthalpy;

        redeclare function extends specificHeatCapacityCp "Return specific heat capacity at constant pressure"
        algorithm
          cp := cp_const;
        end specificHeatCapacityCp;

        redeclare function extends specificHeatCapacityCv "Return specific heat capacity at constant volume"
        algorithm
          cv := cv_const;
        end specificHeatCapacityCv;

        redeclare function extends isentropicExponent "Return isentropic exponent"
        algorithm
          gamma := cp_const/cv_const;
        end isentropicExponent;

        redeclare function extends velocityOfSound "Return velocity of sound"
        algorithm
          a := a_const;
        end velocityOfSound;

        redeclare function specificEnthalpy_pTX "Return specific enthalpy from p, T, and X or Xi"
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input MassFraction X[:] "Mass fractions";
          output SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := cp_const*(T - T0);
        end specificEnthalpy_pTX;

        redeclare function temperature_phX "Return temperature from p, h, and X or Xi"
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction X[:] "Mass fractions";
          output Temperature T "Temperature";
        algorithm
          T := T0 + h/cp_const;
        end temperature_phX;

        redeclare function density_phX "Return density from p, h, and X or Xi"
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction X[:] "Mass fractions";
          output Density d "Density";
        algorithm
          d := density(setState_phX(p, h, X));
        end density_phX;

        redeclare function extends specificEntropy "Return specific entropy"
        algorithm
          s := cv_const*Modelica.Math.log(state.T/T0);
        end specificEntropy;

        redeclare function extends isobaricExpansionCoefficient "Returns overall the isobaric expansion coefficient beta"
        algorithm
          beta := 0.0;
        end isobaricExpansionCoefficient;

        redeclare function extends molarMass "Return the molar mass of the medium"
        algorithm
          MM := MM_const;
        end molarMass;
      end PartialSimpleMedium;

      package Choices "Types, constants to define menu choices"
        type IndependentVariables = enumeration(T "Temperature", pT "Pressure, Temperature", ph "Pressure, Specific Enthalpy", phX "Pressure, Specific Enthalpy, Mass Fraction", pTX "Pressure, Temperature, Mass Fractions", dTX "Density, Temperature, Mass Fractions") "Enumeration defining the independent variables of a medium";
        type Init = enumeration(NoInit "NoInit (no initialization)", InitialStates "InitialStates (initialize medium states)", SteadyState "SteadyState (initialize in steady state)", SteadyMass "SteadyMass (initialize density or pressure in steady state)") "Enumeration defining initialization for fluid flow" annotation(Evaluate = true);
        type pd = enumeration(default "Default (no boundary condition for p or d)", p_known "p_known (pressure p is known)", d_known "d_known (density d is known)") "Enumeration defining whether p or d are known for the boundary condition" annotation(Evaluate = true);
      end Choices;

      package Types "Types to be used in fluid models"
        type AbsolutePressure = SI.AbsolutePressure(min = 0, max = 1.e8, nominal = 1.e5, start = 1.e5) "Type for absolute pressure with medium specific attributes";
        type Density = SI.Density(min = 0, max = 1.e5, nominal = 1, start = 1) "Type for density with medium specific attributes";
        type DynamicViscosity = SI.DynamicViscosity(min = 0, max = 1.e8, nominal = 1.e-3, start = 1.e-3) "Type for dynamic viscosity with medium specific attributes";
        type EnthalpyFlowRate = SI.EnthalpyFlowRate(nominal = 1000.0, min = -1.0e8, max = 1.e8) "Type for enthalpy flow rate with medium specific attributes";
        type MassFraction = Real(quantity = "MassFraction", final unit = "kg/kg", min = 0, max = 1, nominal = 0.1) "Type for mass fraction with medium specific attributes";
        type MoleFraction = Real(quantity = "MoleFraction", final unit = "mol/mol", min = 0, max = 1, nominal = 0.1) "Type for mole fraction with medium specific attributes";
        type MolarMass = SI.MolarMass(min = 0.001, max = 0.25, nominal = 0.032) "Type for molar mass with medium specific attributes";
        type MolarVolume = SI.MolarVolume(min = 1e-6, max = 1.0e6, nominal = 1.0) "Type for molar volume with medium specific attributes";
        type IsentropicExponent = SI.RatioOfSpecificHeatCapacities(min = 1, max = 500000, nominal = 1.2, start = 1.2) "Type for isentropic exponent with medium specific attributes";
        type SpecificEnergy = SI.SpecificEnergy(min = -1.0e8, max = 1.e8, nominal = 1.e6) "Type for specific energy with medium specific attributes";
        type SpecificInternalEnergy = SpecificEnergy "Type for specific internal energy with medium specific attributes";
        type SpecificEnthalpy = SI.SpecificEnthalpy(min = -1.0e10, max = 1.e10, nominal = 1.e6) "Type for specific enthalpy with medium specific attributes";
        type SpecificEntropy = SI.SpecificEntropy(min = -1.e7, max = 1.e7, nominal = 1.e3) "Type for specific entropy with medium specific attributes";
        type SpecificHeatCapacity = SI.SpecificHeatCapacity(min = 0, max = 1.e7, nominal = 1.e3, start = 1.e3) "Type for specific heat capacity with medium specific attributes";
        type Temperature = SI.Temperature(min = 1, max = 1.e4, nominal = 300, start = 288.15) "Type for temperature with medium specific attributes";
        type ThermalConductivity = SI.ThermalConductivity(min = 0, max = 500, nominal = 1, start = 1) "Type for thermal conductivity with medium specific attributes";
        type VelocityOfSound = SI.Velocity(min = 0, max = 1.e5, nominal = 1000, start = 1000) "Type for velocity of sound with medium specific attributes";
        type ExtraProperty = Real(min = 0.0, start = 1.0) "Type for unspecified, mass-specific property transported by flow";
        type ExtraPropertyFlowRate = Real(unit = "kg/s") "Type for flow rate of unspecified, mass-specific property";
        type IsobaricExpansionCoefficient = Real(min = 0, max = 1.0e8, unit = "1/K") "Type for isobaric expansion coefficient with medium specific attributes";
        type DipoleMoment = Real(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment") "Type for dipole moment with medium specific attributes";
        type DerDensityByPressure = SI.DerDensityByPressure "Type for partial derivative of density with respect to pressure with medium specific attributes";

        replaceable record SaturationProperties "Saturation properties of two phase medium"
          AbsolutePressure psat "Saturation pressure";
          Temperature Tsat "Saturation temperature";
        end SaturationProperties;

        type FixedPhase = Integer(min = 0, max = 2) "Phase of the fluid: 1 for 1-phase, 2 for two-phase, 0 for not known, e.g., interactive use";

        package Basic "The most basic version of a record used in several degrees of detail"
          record FluidConstants "Critical, triple, molecular and other standard data of fluid"
            String iupacName "Complete IUPAC name (or common name, if non-existent)";
            String casRegistryNumber "Chemical abstracts sequencing number (if it exists)";
            String chemicalFormula "Chemical formula, (brutto, nomenclature according to Hill";
            String structureFormula "Chemical structure formula";
            MolarMass molarMass "Molar mass";
          end FluidConstants;
        end Basic;

        package TwoPhase "The two phase fluid version of a record used in several degrees of detail"
          record FluidConstants "Extended fluid constants"
            extends Modelica.Media.Interfaces.Types.Basic.FluidConstants;
            Temperature criticalTemperature "Critical temperature";
            AbsolutePressure criticalPressure "Critical pressure";
            MolarVolume criticalMolarVolume "Critical molar Volume";
            Real acentricFactor "Pitzer acentric factor";
            Temperature triplePointTemperature "Triple point temperature";
            AbsolutePressure triplePointPressure "Triple point pressure";
            Temperature meltingPoint "Melting point at 101325 Pa";
            Temperature normalBoilingPoint "Normal boiling point (at 101325 Pa)";
            DipoleMoment dipoleMoment "Dipole moment of molecule in Debye (1 debye = 3.33564e-30 C.m)";
            Boolean hasIdealGasHeatCapacity = false "= true, if ideal gas heat capacity is available";
            Boolean hasCriticalData = false "= true, if critical data are known";
            Boolean hasDipoleMoment = false "= true, if a dipole moment known";
            Boolean hasFundamentalEquation = false "= true, if a fundamental equation";
            Boolean hasLiquidHeatCapacity = false "= true, if liquid heat capacity is available";
            Boolean hasSolidHeatCapacity = false "= true, if solid heat capacity is available";
            Boolean hasAccurateViscosityData = false "= true, if accurate data for a viscosity function is available";
            Boolean hasAccurateConductivityData = false "= true, if accurate data for thermal conductivity is available";
            Boolean hasVapourPressureCurve = false "= true, if vapour pressure data, e.g., Antoine coefficients are known";
            Boolean hasAcentricFactor = false "= true, if Pitzer acentric factor is known";
            SpecificEnthalpy HCRIT0 = 0.0 "Critical specific enthalpy of the fundamental equation";
            SpecificEntropy SCRIT0 = 0.0 "Critical specific entropy of the fundamental equation";
            SpecificEnthalpy deltah = 0.0 "Difference between specific enthalpy model (h_m) and f.eq. (h_f) (h_m - h_f)";
            SpecificEntropy deltas = 0.0 "Difference between specific enthalpy model (s_m) and f.eq. (s_f) (s_m - s_f)";
          end FluidConstants;
        end TwoPhase;
      end Types;
    end Interfaces;

    package Common "Data structures and fundamental functions for fluid properties"
      type DerPressureByDensity = Real(final quantity = "DerPressureByDensity", final unit = "Pa.m3/kg");
      type DerPressureByTemperature = Real(final quantity = "DerPressureByTemperature", final unit = "Pa/K");
      type IsentropicExponent = Real(final quantity = "IsentropicExponent", unit = "1");
      constant Real MINPOS = 1.0e-9 "Minimal value for physical variables which are always > 0.0";
      constant SI.Area AMIN = MINPOS "Minimal init area";
      constant SI.Area AMAX = 1.0e5 "Maximal init area";
      constant SI.Area ANOM = 1.0 "Nominal init area";
      constant SI.AmountOfSubstance MOLMIN = -1.0*MINPOS "Minimal Mole Number";
      constant SI.AmountOfSubstance MOLMAX = 1.0e8 "Maximal Mole Number";
      constant SI.AmountOfSubstance MOLNOM = 1.0 "Nominal Mole Number";
      constant SI.Density DMIN = 1e-6 "Minimal init density";
      constant SI.Density DMAX = 30.0e3 "Maximal init density";
      constant SI.Density DNOM = 1.0 "Nominal init density";
      constant SI.ThermalConductivity LAMMIN = MINPOS "Minimal thermal conductivity";
      constant SI.ThermalConductivity LAMNOM = 1.0 "Nominal thermal conductivity";
      constant SI.ThermalConductivity LAMMAX = 1000.0 "Maximal thermal conductivity";
      constant SI.DynamicViscosity ETAMIN = MINPOS "Minimal init dynamic viscosity";
      constant SI.DynamicViscosity ETAMAX = 1.0e8 "Maximal init dynamic viscosity";
      constant SI.DynamicViscosity ETANOM = 100.0 "Nominal init dynamic viscosity";
      constant SI.Energy EMIN = -1.0e10 "Minimal init energy";
      constant SI.Energy EMAX = 1.0e10 "Maximal init energy";
      constant SI.Energy ENOM = 1.0e3 "Nominal init energy";
      constant SI.Entropy SMIN = -1.0e6 "Minimal init entropy";
      constant SI.Entropy SMAX = 1.0e6 "Maximal init entropy";
      constant SI.Entropy SNOM = 1.0e3 "Nominal init entropy";
      constant SI.MassFlowRate MDOTMIN = -1.0e5 "Minimal init mass flow rate";
      constant SI.MassFlowRate MDOTMAX = 1.0e5 "Maximal init mass flow rate";
      constant SI.MassFlowRate MDOTNOM = 1.0 "Nominal init mass flow rate";
      constant SI.MassFraction MASSXMIN = -1.0*MINPOS "Minimal init mass fraction";
      constant SI.MassFraction MASSXMAX = 1.0 "Maximal init mass fraction";
      constant SI.MassFraction MASSXNOM = 0.1 "Nominal init mass fraction";
      constant SI.Mass MMIN = -1.0*MINPOS "Minimal init mass";
      constant SI.Mass MMAX = 1.0e8 "Maximal init mass";
      constant SI.Mass MNOM = 1.0 "Nominal init mass";
      constant SI.MolarMass MMMIN = 0.001 "Minimal initial molar mass";
      constant SI.MolarMass MMMAX = 250.0 "Maximal initial molar mass";
      constant SI.MolarMass MMNOM = 0.2 "Nominal initial molar mass";
      constant SI.MoleFraction MOLEYMIN = -1.0*MINPOS "Minimal init mole fraction";
      constant SI.MoleFraction MOLEYMAX = 1.0 "Maximal init mole fraction";
      constant SI.MoleFraction MOLEYNOM = 0.1 "Nominal init mole fraction";
      constant SI.MomentumFlux GMIN = -1.0e8 "Minimal init momentum flux";
      constant SI.MomentumFlux GMAX = 1.0e8 "Maximal init momentum flux";
      constant SI.MomentumFlux GNOM = 1.0 "Nominal init momentum flux";
      constant SI.Power POWMIN = -1.0e8 "Minimal init power or heat";
      constant SI.Power POWMAX = 1.0e8 "Maximal init power or heat";
      constant SI.Power POWNOM = 1.0e3 "Nominal init power or heat";
      constant SI.Pressure PMIN = 1.0e4 "Minimal init pressure";
      constant SI.Pressure PMAX = 1.0e8 "Maximal init pressure";
      constant SI.Pressure PNOM = 1.0e5 "Nominal init pressure";
      constant SI.Pressure COMPPMIN = -1.0*MINPOS "Minimal init pressure";
      constant SI.Pressure COMPPMAX = 1.0e8 "Maximal init pressure";
      constant SI.Pressure COMPPNOM = 1.0e5 "Nominal init pressure";
      constant SI.RatioOfSpecificHeatCapacities KAPPAMIN = 1.0 "Minimal init isentropic exponent";
      constant SI.RatioOfSpecificHeatCapacities KAPPAMAX = 1.7 "Maximal init isentropic exponent";
      constant SI.RatioOfSpecificHeatCapacities KAPPANOM = 1.2 "Nominal init isentropic exponent";
      constant SI.SpecificEnergy SEMIN = -1.0e8 "Minimal init specific energy";
      constant SI.SpecificEnergy SEMAX = 1.0e8 "Maximal init specific energy";
      constant SI.SpecificEnergy SENOM = 1.0e6 "Nominal init specific energy";
      constant SI.SpecificEnthalpy SHMIN = -1.0e8 "Minimal init specific enthalpy";
      constant SI.SpecificEnthalpy SHMAX = 1.0e8 "Maximal init specific enthalpy";
      constant SI.SpecificEnthalpy SHNOM = 1.0e6 "Nominal init specific enthalpy";
      constant SI.SpecificEntropy SSMIN = -1.0e6 "Minimal init specific entropy";
      constant SI.SpecificEntropy SSMAX = 1.0e6 "Maximal init specific entropy";
      constant SI.SpecificEntropy SSNOM = 1.0e3 "Nominal init specific entropy";
      constant SI.SpecificHeatCapacity CPMIN = MINPOS "Minimal init specific heat capacity";
      constant SI.SpecificHeatCapacity CPMAX = 1.0e6 "Maximal init specific heat capacity";
      constant SI.SpecificHeatCapacity CPNOM = 1.0e3 "Nominal init specific heat capacity";
      constant SI.Temperature TMIN = 1.0 "Minimal init temperature";
      constant SI.Temperature TMAX = 6000.0 "Maximal init temperature";
      constant SI.Temperature TNOM = 320.0 "Nominal init temperature";
      constant SI.ThermalConductivity LMIN = MINPOS "Minimal init thermal conductivity";
      constant SI.ThermalConductivity LMAX = 500.0 "Maximal init thermal conductivity";
      constant SI.ThermalConductivity LNOM = 1.0 "Nominal init thermal conductivity";
      constant SI.Velocity VELMIN = -1.0e5 "Minimal init speed";
      constant SI.Velocity VELMAX = 1.0e5 "Maximal init speed";
      constant SI.Velocity VELNOM = 1.0 "Nominal init speed";
      constant SI.Volume VMIN = 0.0 "Minimal init volume";
      constant SI.Volume VMAX = 1.0e5 "Maximal init volume";
      constant SI.Volume VNOM = 1.0e-3 "Nominal init volume";

      record SaturationProperties "Properties in the two phase region"
        SI.Temperature T "Temperature";
        SI.Density d "Density";
        SI.Pressure p "Pressure";
        SI.SpecificEnergy u "Specific inner energy";
        SI.SpecificEnthalpy h "Specific enthalpy";
        SI.SpecificEntropy s "Specific entropy";
        SI.SpecificHeatCapacity cp "Heat capacity at constant pressure";
        SI.SpecificHeatCapacity cv "Heat capacity at constant volume";
        SI.SpecificHeatCapacity R_s "Gas constant";
        SI.RatioOfSpecificHeatCapacities kappa "Isentropic expansion coefficient";
        PhaseBoundaryProperties liq "Thermodynamic base properties on the boiling curve";
        PhaseBoundaryProperties vap "Thermodynamic base properties on the dew curve";
        Real dpT(unit = "Pa/K") "Derivative of saturation pressure w.r.t. temperature";
        SI.MassFraction x "Vapour mass fraction";
      end SaturationProperties;

      record IF97BaseTwoPhase "Intermediate property data record for IF 97"
        Integer phase(start = 0) "Phase: 2 for two-phase, 1 for one phase, 0 if unknown";
        Integer region(min = 1, max = 5) "IF 97 region";
        SI.Pressure p "Pressure";
        SI.Temperature T "Temperature";
        SI.SpecificEnthalpy h "Specific enthalpy";
        SI.SpecificHeatCapacity R_s "Gas constant";
        SI.SpecificHeatCapacity cp "Specific heat capacity";
        SI.SpecificHeatCapacity cv "Specific heat capacity";
        SI.Density rho "Density";
        SI.SpecificEntropy s "Specific entropy";
        DerPressureByTemperature pt "Derivative of pressure w.r.t. temperature";
        DerPressureByDensity pd "Derivative of pressure w.r.t. density";
        Real vt "Derivative of specific volume w.r.t. temperature";
        Real vp "Derivative of specific volume w.r.t. pressure";
        Real x "Dryness fraction";
        Real dpT "dp/dT derivative of saturation curve";
      end IF97BaseTwoPhase;

      record IF97PhaseBoundaryProperties "Thermodynamic base properties on the phase boundary for IF97 steam tables"
        Boolean region3boundary "= true, if boundary between 2-phase and region 3";
        SI.SpecificHeatCapacity R_s "Specific heat capacity";
        SI.Temperature T "Temperature";
        SI.Density d "Density";
        SI.SpecificEnthalpy h "Specific enthalpy";
        SI.SpecificEntropy s "Specific entropy";
        SI.SpecificHeatCapacity cp "Heat capacity at constant pressure";
        SI.SpecificHeatCapacity cv "Heat capacity at constant volume";
        DerPressureByTemperature dpT "dp/dT derivative of saturation curve";
        DerPressureByTemperature pt "Derivative of pressure w.r.t. temperature";
        DerPressureByDensity pd "Derivative of pressure w.r.t. density";
        Real vt(unit = "m3/(kg.K)") "Derivative of specific volume w.r.t. temperature";
        Real vp(unit = "m3/(kg.Pa)") "Derivative of specific volume w.r.t. pressure";
      end IF97PhaseBoundaryProperties;

      record GibbsDerivs "Derivatives of dimensionless Gibbs-function w.r.t. dimensionless pressure and temperature"
        SI.Pressure p "Pressure";
        SI.Temperature T "Temperature";
        SI.SpecificHeatCapacity R_s "Specific heat capacity";
        Real pi(unit = "1") "Dimensionless pressure";
        Real tau(unit = "1") "Dimensionless temperature";
        Real g(unit = "1") "Dimensionless Gibbs-function";
        Real gpi(unit = "1") "Derivative of g w.r.t. pi";
        Real gpipi(unit = "1") "2nd derivative of g w.r.t. pi";
        Real gtau(unit = "1") "Derivative of g w.r.t. tau";
        Real gtautau(unit = "1") "2nd derivative of g w.r.t. tau";
        Real gtaupi(unit = "1") "Mixed derivative of g w.r.t. pi and tau";
      end GibbsDerivs;

      record HelmholtzDerivs "Derivatives of dimensionless Helmholtz-function w.r.t. dimensionless pressure, density and temperature"
        SI.Density d "Density";
        SI.Temperature T "Temperature";
        SI.SpecificHeatCapacity R_s "Specific heat capacity";
        Real delta(unit = "1") "Dimensionless density";
        Real tau(unit = "1") "Dimensionless temperature";
        Real f(unit = "1") "Dimensionless Helmholtz-function";
        Real fdelta(unit = "1") "Derivative of f w.r.t. delta";
        Real fdeltadelta(unit = "1") "2nd derivative of f w.r.t. delta";
        Real ftau(unit = "1") "Derivative of f w.r.t. tau";
        Real ftautau(unit = "1") "2nd derivative of f w.r.t. tau";
        Real fdeltatau(unit = "1") "Mixed derivative of f w.r.t. delta and tau";
      end HelmholtzDerivs;

      record PhaseBoundaryProperties "Thermodynamic base properties on the phase boundary"
        SI.Density d "Density";
        SI.SpecificEnthalpy h "Specific enthalpy";
        SI.SpecificEnergy u "Inner energy";
        SI.SpecificEntropy s "Specific entropy";
        SI.SpecificHeatCapacity cp "Heat capacity at constant pressure";
        SI.SpecificHeatCapacity cv "Heat capacity at constant volume";
        DerPressureByTemperature pt "Derivative of pressure w.r.t. temperature";
        DerPressureByDensity pd "Derivative of pressure w.r.t. density";
      end PhaseBoundaryProperties;

      record NewtonDerivatives_ph "Derivatives for fast inverse calculations of Helmholtz functions: p & h"
        SI.Pressure p "Pressure";
        SI.SpecificEnthalpy h "Specific enthalpy";
        DerPressureByDensity pd "Derivative of pressure w.r.t. density";
        DerPressureByTemperature pt "Derivative of pressure w.r.t. temperature";
        Real hd "Derivative of specific enthalpy w.r.t. density";
        Real ht "Derivative of specific enthalpy w.r.t. temperature";
      end NewtonDerivatives_ph;

      record NewtonDerivatives_pT "Derivatives for fast inverse calculations of Helmholtz functions:p & T"
        SI.Pressure p "Pressure";
        DerPressureByDensity pd "Derivative of pressure w.r.t. density";
      end NewtonDerivatives_pT;

      function gibbsToBoundaryProps "Calculate phase boundary property record from dimensionless Gibbs function"
        input GibbsDerivs g "Dimensionless derivatives of Gibbs function";
        output PhaseBoundaryProperties sat "Phase boundary properties";
      protected
        Real vt "Derivative of specific volume w.r.t. temperature";
        Real vp "Derivative of specific volume w.r.t. pressure";
      algorithm
        sat.d := g.p/(g.R_s*g.T*g.pi*g.gpi);
        sat.h := g.R_s*g.T*g.tau*g.gtau;
        sat.u := g.T*g.R_s*(g.tau*g.gtau - g.pi*g.gpi);
        sat.s := g.R_s*(g.tau*g.gtau - g.g);
        sat.cp := -g.R_s*g.tau*g.tau*g.gtautau;
        sat.cv := g.R_s*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/(g.gpipi));
        vt := g.R_s/g.p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
        vp := g.R_s*g.T/(g.p*g.p)*g.pi*g.pi*g.gpipi;
        sat.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
        sat.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
      end gibbsToBoundaryProps;

      function helmholtzToBoundaryProps "Calculate phase boundary property record from dimensionless Helmholtz function"
        input HelmholtzDerivs f "Dimensionless derivatives of Helmholtz function";
        output PhaseBoundaryProperties sat "Phase boundary property record";
      protected
        SI.Pressure p "Pressure";
      algorithm
        p := f.R_s*f.d*f.T*f.delta*f.fdelta;
        sat.d := f.d;
        sat.h := f.R_s*f.T*(f.tau*f.ftau + f.delta*f.fdelta);
        sat.s := f.R_s*(f.tau*f.ftau - f.f);
        sat.u := f.R_s*f.T*f.tau*f.ftau;
        sat.cp := f.R_s*(-f.tau*f.tau*f.ftautau + (f.delta*f.fdelta - f.delta*f.tau*f.fdeltatau)^2/(2*f.delta*f.fdelta + f.delta*f.delta*f.fdeltadelta));
        sat.cv := f.R_s*(-f.tau*f.tau*f.ftautau);
        sat.pt := f.R_s*f.d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
        sat.pd := f.R_s*f.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
      end helmholtzToBoundaryProps;

      function cv2Phase "Compute isochoric specific heat capacity inside the two-phase region"
        input PhaseBoundaryProperties liq "Properties on the boiling curve";
        input PhaseBoundaryProperties vap "Properties on the condensation curve";
        input SI.MassFraction x "Vapour mass fraction";
        input SI.Temperature T "Temperature";
        input SI.Pressure p "Properties";
        output SI.SpecificHeatCapacity cv "Isochoric specific heat capacity";
      protected
        Real dpT "Derivative of pressure w.r.t. temperature";
        Real dxv "Derivative of vapour mass fraction w.r.t. specific volume";
        Real dvTl "Derivative of liquid specific volume w.r.t. temperature";
        Real dvTv "Derivative of vapour specific volume w.r.t. temperature";
        Real duTl "Derivative of liquid specific inner energy w.r.t. temperature";
        Real duTv "Derivative of vapour specific inner energy w.r.t. temperature";
        Real dxt "Derivative of vapour mass fraction w.r.t. temperature";
      algorithm
        dxv := if (liq.d <> vap.d) then liq.d*vap.d/(liq.d - vap.d) else 0.0;
        dpT := (vap.s - liq.s)*dxv;
        dvTl := (liq.pt - dpT)/liq.pd/liq.d/liq.d;
        dvTv := (vap.pt - dpT)/vap.pd/vap.d/vap.d;
        dxt := -dxv*(dvTl + x*(dvTv - dvTl));
        duTl := liq.cv + (T*liq.pt - p)*dvTl;
        duTv := vap.cv + (T*vap.pt - p)*dvTv;
        cv := duTl + x*(duTv - duTl) + dxt*(vap.u - liq.u);
      end cv2Phase;

      function Helmholtz_ph "Function to calculate analytic derivatives for computing d and t given p and h"
        input HelmholtzDerivs f "Dimensionless derivatives of Helmholtz function";
        output NewtonDerivatives_ph nderivs "Derivatives for Newton iteration to calculate d and t from p and h";
      protected
        SI.SpecificHeatCapacity cv "Isochoric heat capacity";
      algorithm
        cv := -f.R_s*(f.tau*f.tau*f.ftautau);
        nderivs.p := f.d*f.R_s*f.T*f.delta*f.fdelta;
        nderivs.h := f.R_s*f.T*(f.tau*f.ftau + f.delta*f.fdelta);
        nderivs.pd := f.R_s*f.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
        nderivs.pt := f.R_s*f.d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
        nderivs.ht := cv + nderivs.pt/f.d;
        nderivs.hd := (nderivs.pd - f.T*nderivs.pt/f.d)/f.d;
      end Helmholtz_ph;

      function Helmholtz_pT "Function to calculate analytic derivatives for computing d and t given p and t"
        input HelmholtzDerivs f "Dimensionless derivatives of Helmholtz function";
        output NewtonDerivatives_pT nderivs "Derivatives for Newton iteration to compute d and t from p and t";
      algorithm
        nderivs.p := f.d*f.R_s*f.T*f.delta*f.fdelta;
        nderivs.pd := f.R_s*f.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
      end Helmholtz_pT;
    end Common;

    package Water "Medium models for water"
      import Modelica.Media.Water.ConstantPropertyLiquidWater.simpleWaterConstants;
      constant Modelica.Media.Interfaces.Types.TwoPhase.FluidConstants waterConstants[1](each chemicalFormula = "H2O", each structureFormula = "H2O", each casRegistryNumber = "7732-18-5", each iupacName = "oxidane", each molarMass = 0.018015268, each criticalTemperature = 647.096, each criticalPressure = 22064.0e3, each criticalMolarVolume = 1/322.0*0.018015268, each normalBoilingPoint = 373.124, each meltingPoint = 273.15, each triplePointTemperature = 273.16, each triplePointPressure = 611.657, each acentricFactor = 0.344, each dipoleMoment = 1.8, each hasCriticalData = true);

      package ConstantPropertyLiquidWater "Water: Simple liquid water medium (incompressible, constant data)"
        constant Modelica.Media.Interfaces.Types.Basic.FluidConstants simpleWaterConstants[1](each chemicalFormula = "H2O", each structureFormula = "H2O", each casRegistryNumber = "7732-18-5", each iupacName = "oxidane", each molarMass = 0.018015268);
        extends Interfaces.PartialSimpleMedium(mediumName = "SimpleLiquidWater", cp_const = 4184, cv_const = 4184, d_const = 995.586, eta_const = 1.e-3, lambda_const = 0.598, a_const = 1484, T_min = Cv.from_degC(-1), T_max = Cv.from_degC(130), T0 = 273.15, MM_const = 0.018015268, fluidConstants = simpleWaterConstants);
      end ConstantPropertyLiquidWater;

      package StandardWater = WaterIF97_ph "Water using the IF97 standard, explicit in p and h. Recommended for most applications";

      package WaterIF97_ph "Water using the IF97 standard, explicit in p and h"
        extends WaterIF97_base(ThermoStates = Modelica.Media.Interfaces.Choices.IndependentVariables.ph, final ph_explicit = true, final dT_explicit = false, final pT_explicit = false, smoothModel = false, onePhase = false);
      end WaterIF97_ph;

      partial package WaterIF97_base "Water: Steam properties as defined by IAPWS/IF97 standard"
        extends Interfaces.PartialTwoPhaseMedium(mediumName = "WaterIF97", substanceNames = {"water"}, singleState = false, SpecificEnthalpy(start = 1.0e5, nominal = 5.0e5), Density(start = 150, nominal = 500), AbsolutePressure(start = 50e5, nominal = 10e5, min = 611.657, max = 100e6), Temperature(start = 500, nominal = 500, min = 273.15, max = 2273.15), smoothModel = false, onePhase = false, fluidConstants = waterConstants);

        redeclare record extends SaturationProperties end SaturationProperties;

        redeclare record extends ThermodynamicState "Thermodynamic state"
          SpecificEnthalpy h "Specific enthalpy";
          Density d "Density";
          Temperature T "Temperature";
          AbsolutePressure p "Pressure";
        end ThermodynamicState;

        constant Integer Region = 0 "Region of IF97, if known, zero otherwise";
        constant Boolean ph_explicit "True if explicit in pressure and specific enthalpy";
        constant Boolean dT_explicit "True if explicit in density and temperature";
        constant Boolean pT_explicit "True if explicit in pressure and temperature";

        redeclare replaceable model extends BaseProperties(h(stateSelect = if ph_explicit and preferredMediumStates then StateSelect.prefer else StateSelect.default), d(stateSelect = if dT_explicit and preferredMediumStates then StateSelect.prefer else StateSelect.default), T(stateSelect = if (pT_explicit or dT_explicit) and preferredMediumStates then StateSelect.prefer else StateSelect.default), p(stateSelect = if (pT_explicit or ph_explicit) and preferredMediumStates then StateSelect.prefer else StateSelect.default)) "Base properties of water"
          Integer phase(min = 0, max = 2, start = 1, fixed = false) "2 for two-phase, 1 for one-phase, 0 if not known";
        equation
          MM = fluidConstants[1].molarMass;
          if Region > 0 then
            phase = (if Region == 4 then 2 else 1);
          elseif smoothModel then
            if onePhase then
              phase = 1;
              if ph_explicit then
                assert(((h < bubbleEnthalpy(sat) or h > dewEnthalpy(sat)) or p > fluidConstants[1].criticalPressure), "With onePhase=true this model may only be called with one-phase states h < hl or h > hv!" + "(p = " + String(p) + ", h = " + String(h) + ")");
              else
                if dT_explicit then
                  assert(not ((d < bubbleDensity(sat) and d > dewDensity(sat)) and T < fluidConstants[1].criticalTemperature), "With onePhase=true this model may only be called with one-phase states d > dl or d < dv!" + "(d = " + String(d) + ", T = " + String(T) + ")");
                end if;
              end if;
            else
              phase = 0;
            end if;
          else
            if ph_explicit then
              phase = if ((h < bubbleEnthalpy(sat) or h > dewEnthalpy(sat)) or p > fluidConstants[1].criticalPressure) then 1 else 2;
            elseif dT_explicit then
              phase = if not ((d < bubbleDensity(sat) and d > dewDensity(sat)) and T < fluidConstants[1].criticalTemperature) then 1 else 2;
            else
              phase = 1;
            end if;
          end if;
          if dT_explicit then
            p = pressure_dT(d, T, phase, Region);
            h = specificEnthalpy_dT(d, T, phase, Region);
            sat.Tsat = T;
            sat.psat = saturationPressure(T);
          elseif ph_explicit then
            d = density_ph(p, h, phase, Region);
            T = temperature_ph(p, h, phase, Region);
            sat.Tsat = saturationTemperature(p);
            sat.psat = p;
          else
            h = specificEnthalpy_pT(p, T, Region);
            d = density_pT(p, T, Region);
            sat.psat = p;
            sat.Tsat = saturationTemperature(p);
          end if;
          u = h - p/d;
          R_s = Modelica.Constants.R/fluidConstants[1].molarMass;
          h = state.h;
          p = state.p;
          T = state.T;
          d = state.d;
          phase = state.phase;
        end BaseProperties;

        redeclare function density_ph "Computes density as a function of pressure and specific enthalpy"
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = Region "If 0, region is unknown, otherwise known and this input";
          output Density d "Density";
        algorithm
          d := IF97_Utilities.rho_ph(p, h, phase, region);
          annotation(Inline = true);
        end density_ph;

        redeclare function temperature_ph "Computes temperature as a function of pressure and specific enthalpy"
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = Region "If 0, region is unknown, otherwise known and this input";
          output Temperature T "Temperature";
        algorithm
          T := IF97_Utilities.T_ph(p, h, phase, region);
          annotation(Inline = true);
        end temperature_ph;

        redeclare function pressure_dT "Computes pressure as a function of density and temperature"
          input Density d "Density";
          input Temperature T "Temperature";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = Region "If 0, region is unknown, otherwise known and this input";
          output AbsolutePressure p "Pressure";
        algorithm
          p := IF97_Utilities.p_dT(d, T, phase, region);
          annotation(Inline = true);
        end pressure_dT;

        redeclare function specificEnthalpy_dT "Computes specific enthalpy as a function of density and temperature"
          input Density d "Density";
          input Temperature T "Temperature";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = Region "If 0, region is unknown, otherwise known and this input";
          output SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := IF97_Utilities.h_dT(d, T, phase, region);
          annotation(Inline = true);
        end specificEnthalpy_dT;

        redeclare function specificEnthalpy_pT "Computes specific enthalpy as a function of pressure and temperature"
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = Region "If 0, region is unknown, otherwise known and this input";
          output SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := IF97_Utilities.h_pT(p, T, region);
          annotation(Inline = true);
        end specificEnthalpy_pT;

        redeclare function density_pT "Computes density as a function of pressure and temperature"
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = Region "If 0, region is unknown, otherwise known and this input";
          output Density d "Density";
        algorithm
          d := IF97_Utilities.rho_pT(p, T, region);
          annotation(Inline = true);
        end density_pT;

        redeclare function extends dynamicViscosity "Dynamic viscosity of water"
        algorithm
          eta := IF97_Utilities.dynamicViscosity(state.d, state.T, state.p, state.phase);
          annotation(Inline = true);
        end dynamicViscosity;

        redeclare function extends pressure "Return pressure of ideal gas"
        algorithm
          p := state.p;
          annotation(Inline = true);
        end pressure;

        redeclare function extends temperature "Return temperature of ideal gas"
        algorithm
          T := state.T;
          annotation(Inline = true);
        end temperature;

        redeclare function extends density "Return density of ideal gas"
        algorithm
          d := state.d;
          annotation(Inline = true);
        end density;

        redeclare function extends specificEnthalpy "Return specific enthalpy"
        algorithm
          h := state.h;
          annotation(Inline = true);
        end specificEnthalpy;

        redeclare function extends specificEntropy "Specific entropy of water"
        algorithm
          s := if dT_explicit then IF97_Utilities.s_dT(state.d, state.T, state.phase, Region) else if pT_explicit then IF97_Utilities.s_pT(state.p, state.T, Region) else IF97_Utilities.s_ph(state.p, state.h, state.phase, Region);
          annotation(Inline = true);
        end specificEntropy;

        redeclare function extends specificHeatCapacityCp "Specific heat capacity at constant pressure of water"
        algorithm
          cp := if dT_explicit then IF97_Utilities.cp_dT(state.d, state.T, Region) else if pT_explicit then IF97_Utilities.cp_pT(state.p, state.T, Region) else IF97_Utilities.cp_ph(state.p, state.h, Region);
          annotation(Inline = true);
        end specificHeatCapacityCp;

        redeclare function extends specificHeatCapacityCv "Specific heat capacity at constant volume of water"
        algorithm
          cv := if dT_explicit then IF97_Utilities.cv_dT(state.d, state.T, state.phase, Region) else if pT_explicit then IF97_Utilities.cv_pT(state.p, state.T, Region) else IF97_Utilities.cv_ph(state.p, state.h, state.phase, Region);
          annotation(Inline = true);
        end specificHeatCapacityCv;

        redeclare function extends isentropicExponent "Return isentropic exponent"
        algorithm
          gamma := if dT_explicit then IF97_Utilities.isentropicExponent_dT(state.d, state.T, state.phase, Region) else if pT_explicit then IF97_Utilities.isentropicExponent_pT(state.p, state.T, Region) else IF97_Utilities.isentropicExponent_ph(state.p, state.h, state.phase, Region);
          annotation(Inline = true);
        end isentropicExponent;

        redeclare function extends isobaricExpansionCoefficient "Isobaric expansion coefficient of water"
        algorithm
          beta := if dT_explicit then IF97_Utilities.beta_dT(state.d, state.T, state.phase, Region) else if pT_explicit then IF97_Utilities.beta_pT(state.p, state.T, Region) else IF97_Utilities.beta_ph(state.p, state.h, state.phase, Region);
          annotation(Inline = true);
        end isobaricExpansionCoefficient;

        redeclare function extends velocityOfSound "Return velocity of sound as a function of the thermodynamic state record"
        algorithm
          a := if dT_explicit then IF97_Utilities.velocityOfSound_dT(state.d, state.T, state.phase, Region) else if pT_explicit then IF97_Utilities.velocityOfSound_pT(state.p, state.T, Region) else IF97_Utilities.velocityOfSound_ph(state.p, state.h, state.phase, Region);
          annotation(Inline = true);
        end velocityOfSound;

        redeclare function extends density_derp_h "Density derivative by pressure"
        algorithm
          ddph := IF97_Utilities.ddph(state.p, state.h, state.phase, Region);
          annotation(Inline = true);
        end density_derp_h;

        redeclare function extends bubbleEnthalpy "Boiling curve specific enthalpy of water"
        algorithm
          hl := IF97_Utilities.BaseIF97.Regions.hl_p(sat.psat);
          annotation(Inline = true);
        end bubbleEnthalpy;

        redeclare function extends dewEnthalpy "Dew curve specific enthalpy of water"
        algorithm
          hv := IF97_Utilities.BaseIF97.Regions.hv_p(sat.psat);
          annotation(Inline = true);
        end dewEnthalpy;

        redeclare function extends bubbleDensity "Boiling curve specific density of water"
        algorithm
          dl := if ph_explicit or pT_explicit then IF97_Utilities.BaseIF97.Regions.rhol_p(sat.psat) else IF97_Utilities.BaseIF97.Regions.rhol_T(sat.Tsat);
          annotation(Inline = true);
        end bubbleDensity;

        redeclare function extends dewDensity "Dew curve specific density of water"
        algorithm
          dv := if ph_explicit or pT_explicit then IF97_Utilities.BaseIF97.Regions.rhov_p(sat.psat) else IF97_Utilities.BaseIF97.Regions.rhov_T(sat.Tsat);
          annotation(Inline = true);
        end dewDensity;

        redeclare function extends saturationTemperature "Saturation temperature of water"
        algorithm
          T := IF97_Utilities.BaseIF97.Basic.tsat(p);
          annotation(Inline = true);
        end saturationTemperature;

        redeclare function extends saturationPressure "Saturation pressure of water"
        algorithm
          p := IF97_Utilities.BaseIF97.Basic.psat(T);
          annotation(Inline = true);
        end saturationPressure;

        redeclare function extends setState_dTX "Return thermodynamic state of water as function of d, T, and optional region"
          input Integer region = Region "If 0, region is unknown, otherwise known and this input";
        algorithm
          state := ThermodynamicState(d = d, T = T, phase = if region == 0 then 0 else if region == 4 then 2 else 1, h = specificEnthalpy_dT(d, T, region = region), p = pressure_dT(d, T, region = region));
          annotation(Inline = true);
        end setState_dTX;

        redeclare function extends setState_phX "Return thermodynamic state of water as function of p, h, and optional region"
          input Integer region = Region "If 0, region is unknown, otherwise known and this input";
        algorithm
          state := ThermodynamicState(d = density_ph(p, h, region = region), T = temperature_ph(p, h, region = region), phase = if region == 0 then 0 else if region == 4 then 2 else 1, h = h, p = p);
          annotation(Inline = true);
        end setState_phX;

        redeclare function extends setState_pTX "Return thermodynamic state of water as function of p, T, and optional region"
          input Integer region = Region "If 0, region is unknown, otherwise known and this input";
        algorithm
          state := ThermodynamicState(d = density_pT(p, T, region = region), T = T, phase = 1, h = specificEnthalpy_pT(p, T, region = region), p = p);
          annotation(Inline = true);
        end setState_pTX;
      end WaterIF97_base;

      package IF97_Utilities "Low level and utility computation for high accuracy water properties according to the IAPWS/IF97 standard"
        package BaseIF97 "Modelica Physical Property Model: the new industrial formulation IAPWS-IF97"
          record IterationData "Constants for iterations internal to some functions"
            constant Integer IMAX = 50 "Maximum number of iterations for inverse functions";
            constant Real DELP = 1.0e-6 "Maximum iteration error in pressure, Pa";
            constant Real DELS = 1.0e-8 "Maximum iteration error in specific entropy, J/{kg.K}";
            constant Real DELH = 1.0e-8 "Maximum iteration error in specific enthalpy, J/kg";
            constant Real DELD = 1.0e-8 "Maximum iteration error in density, kg/m^3";
          end IterationData;

          record data "Constant IF97 data and region limits"
            constant SI.SpecificHeatCapacity RH2O = 461.526 "Specific gas constant of water vapour";
            constant SI.MolarMass MH2O = 0.01801528 "Molar weight of water";
            constant SI.Temperature TSTAR1 = 1386.0 "Normalization temperature for region 1 IF97";
            constant SI.Pressure PSTAR1 = 16.53e6 "Normalization pressure for region 1 IF97";
            constant SI.Temperature TSTAR2 = 540.0 "Normalization temperature for region 2 IF97";
            constant SI.Pressure PSTAR2 = 1.0e6 "Normalization pressure for region 2 IF97";
            constant SI.Temperature TSTAR5 = 1000.0 "Normalization temperature for region 5 IF97";
            constant SI.Pressure PSTAR5 = 1.0e6 "Normalization pressure for region 5 IF97";
            constant SI.SpecificEnthalpy HSTAR1 = 2.5e6 "Normalization specific enthalpy for region 1 IF97";
            constant Real IPSTAR = 1.0e-6 "Normalization pressure for inverse function in region 2 IF97";
            constant Real IHSTAR = 5.0e-7 "Normalization specific enthalpy for inverse function in region 2 IF97";
            constant SI.Temperature TLIMIT1 = 623.15 "Temperature limit between regions 1 and 3";
            constant SI.Temperature TLIMIT2 = 1073.15 "Temperature limit between regions 2 and 5";
            constant SI.Temperature TLIMIT5 = 2273.15 "Upper temperature limit of 5";
            constant SI.Pressure PLIMIT1 = 100.0e6 "Upper pressure limit for regions 1, 2 and 3";
            constant SI.Pressure PLIMIT4A = 16.5292e6 "Pressure limit between regions 1 and 2, important for two-phase (region 4)";
            constant SI.Pressure PLIMIT5 = 10.0e6 "Upper limit of valid pressure in region 5";
            constant SI.Pressure PCRIT = 22064000.0 "The critical pressure";
            constant SI.Temperature TCRIT = 647.096 "The critical temperature";
            constant SI.Density DCRIT = 322.0 "The critical density";
            constant SI.SpecificEntropy SCRIT = 4412.02148223476 "The calculated specific entropy at the critical point";
            constant SI.SpecificEnthalpy HCRIT = 2087546.84511715 "The calculated specific enthalpy at the critical point";
            constant Real n[5] = array(0.34805185628969e3, -0.11671859879975e1, 0.10192970039326e-2, 0.57254459862746e3, 0.13918839778870e2) "Polynomial coefficients for boundary between regions 2 and 3";
          end data;

          record triple "Triple point data"
            constant SI.Temperature Ttriple = 273.16 "The triple point temperature";
            constant SI.Pressure ptriple = 611.657 "The triple point pressure";
            constant SI.Density dltriple = 999.792520031617642 "The triple point liquid density";
            constant SI.Density dvtriple = 0.485457572477861372e-2 "The triple point vapour density";
          end triple;

          package Regions "Functions to find the current region for given pairs of input variables"
            function boundary23ofT "Boundary function for region boundary between regions 2 and 3 (input temperature)"
              input SI.Temperature t "Temperature (K)";
              output SI.Pressure p "Pressure";
            protected
              constant Real n[5] = data.n;
            algorithm
              p := 1.0e6*(n[1] + t*(n[2] + t*n[3]));
            end boundary23ofT;

            function boundary23ofp "Boundary function for region boundary between regions 2 and 3 (input pressure)"
              input SI.Pressure p "Pressure";
              output SI.Temperature t "Temperature (K)";
            protected
              constant Real n[5] = data.n;
              Real pi "Dimensionless pressure";
            algorithm
              pi := p/1.0e6;
              assert(p > triple.ptriple, "IF97 medium function boundary23ofp called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              t := n[4] + sqrt((pi - n[5])/n[3]);
            end boundary23ofp;

            function hlowerofp5 "Explicit lower specific enthalpy limit of region 5 as function of pressure"
              input SI.Pressure p "Pressure";
              output SI.SpecificEnthalpy h "Specific enthalpy";
            protected
              Real pi "Dimensionless pressure";
            algorithm
              pi := p/data.PSTAR5;
              assert(p > triple.ptriple, "IF97 medium function hlowerofp5 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              h := 461526.*(9.01505286876203 + pi*(-0.00979043490246092 + (-0.0000203245575263501 + 3.36540214679088e-7*pi)*pi));
            end hlowerofp5;

            function hupperofp5 "Explicit upper specific enthalpy limit of region 5 as function of pressure"
              input SI.Pressure p "Pressure";
              output SI.SpecificEnthalpy h "Specific enthalpy";
            protected
              Real pi "Dimensionless pressure";
            algorithm
              pi := p/data.PSTAR5;
              assert(p > triple.ptriple, "IF97 medium function hupperofp5 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              h := 461526.*(15.9838891400332 + pi*(-0.000489898813722568 + (-5.01510211858761e-8 + 7.5006972718273e-8*pi)*pi));
            end hupperofp5;

            function hlowerofp1 "Explicit lower specific enthalpy limit of region 1 as function of pressure"
              input SI.Pressure p "Pressure";
              output SI.SpecificEnthalpy h "Specific enthalpy";
            protected
              Real pi1 "Dimensionless pressure";
              Real o[3] "Vector of auxiliary variables";
            algorithm
              pi1 := 7.1 - p/data.PSTAR1;
              assert(p > triple.ptriple, "IF97 medium function hlowerofp1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              o[1] := pi1*pi1;
              o[2] := o[1]*o[1];
              o[3] := o[2]*o[2];
              h := 639675.036*(0.173379420894777 + pi1*(-0.022914084306349 + pi1*(-0.00017146768241932 + pi1*(-4.18695814670391e-6 + pi1*(-2.41630417490008e-7 + pi1*(1.73545618580828e-11 + o[1]*pi1*(8.43755552264362e-14 + o[2]*o[3]*pi1*(5.35429206228374e-35 + o[1]*(-8.12140581014818e-38 + o[1]*o[2]*(-1.43870236842915e-44 + pi1*(1.73894459122923e-45 + (-7.06381628462585e-47 + 9.64504638626269e-49*pi1)*pi1)))))))))));
            end hlowerofp1;

            function hupperofp1 "Explicit upper specific enthalpy limit of region 1 as function of pressure (meets region 4 saturation pressure curve at 623.15 K)"
              input SI.Pressure p "Pressure";
              output SI.SpecificEnthalpy h "Specific enthalpy";
            protected
              Real pi1 "Dimensionless pressure";
              Real o[3] "Vector of auxiliary variables";
            algorithm
              pi1 := 7.1 - p/data.PSTAR1;
              assert(p > triple.ptriple, "IF97 medium function hupperofp1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              o[1] := pi1*pi1;
              o[2] := o[1]*o[1];
              o[3] := o[2]*o[2];
              h := 639675.036*(2.42896927729349 + pi1*(-0.00141131225285294 + pi1*(0.00143759406818289 + pi1*(0.000125338925082983 + pi1*(0.0000123617764767172 + pi1*(3.17834967400818e-6 + o[1]*pi1*(1.46754947271665e-8 + o[2]*o[3]*pi1*(1.86779322717506e-17 + o[1]*(-4.18568363667416e-19 + o[1]*o[2]*(-9.19148577641497e-22 + pi1*(4.27026404402408e-22 + (-6.66749357417962e-23 + 3.49930466305574e-24*pi1)*pi1)))))))))));
            end hupperofp1;

            function hlowerofp2 "Explicit lower specific enthalpy limit of region 2 as function of pressure (meets region 4 saturation pressure curve at 623.15 K)"
              input SI.Pressure p "Pressure";
              output SI.SpecificEnthalpy h "Specific enthalpy";
            protected
              Real pi "Dimensionless pressure";
              Real q1 "Auxiliary variable";
              Real q2 "Auxiliary variable";
              Real o[18] "Vector of auxiliary variables";
            algorithm
              pi := p/data.PSTAR2;
              assert(p > triple.ptriple, "IF97 medium function hlowerofp2 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              q1 := 572.54459862746 + 31.3220101646784*sqrt(-13.91883977887 + pi);
              q2 := -0.5 + 540./q1;
              o[1] := q1*q1;
              o[2] := o[1]*o[1];
              o[3] := o[2]*o[2];
              o[4] := pi*pi;
              o[5] := o[4]*o[4];
              o[6] := q2*q2;
              o[7] := o[6]*o[6];
              o[8] := o[6]*o[7];
              o[9] := o[5]*o[5];
              o[10] := o[7]*o[7];
              o[11] := o[9]*o[9];
              o[12] := o[10]*o[10];
              o[13] := o[12]*o[12];
              o[14] := o[7]*q2;
              o[15] := o[6]*q2;
              o[16] := o[10]*o[6];
              o[17] := o[13]*o[6];
              o[18] := o[13]*o[6]*q2;
              h := (4.63697573303507e9 + 3.74686560065793*o[2] + 3.57966647812489e-6*o[1]*o[2] + 2.81881548488163e-13*o[3] - 7.64652332452145e7*q1 - 0.00450789338787835*o[2]*q1 - 1.55131504410292e-9*o[1]*o[2]*q1 + o[1]*(2.51383707870341e6 - 4.78198198764471e6*o[10]*o[11]*o[12]*o[13]*o[4] + 49.9651389369988*o[11]*o[12]*o[13]*o[4]*o[5]*o[7] + o[15]*o[4]*(1.03746636552761e-13 - 0.00349547959376899*o[16] - 2.55074501962569e-7*o[8])*o[9] + (-242662.235426958*o[10]*o[12] - 3.46022402653609*o[16])*o[4]*o[5]*pi + o[4]*(0.109336249381227 - 2248.08924686956*o[14] - 354742.725841972*o[17] - 24.1331193696374*o[6])*pi - 3.09081828396912e-19*o[11]*o[12]*o[5]*o[7]*pi - 1.24107527851371e-8*o[11]*o[13]*o[4]*o[5]*o[6]*o[7]*pi + 3.99891272904219*o[5]*o[8]*pi + 0.0641817365250892*o[10]*o[7]*o[9]*pi + pi*(-4444.87643334512 - 75253.6156722047*o[14] - 43051.9020511789*o[6] - 22926.6247146068*q2) + o[4]*(-8.23252840892034 - 3927.0508365636*o[15] - 239.325789467604*o[18] - 76407.3727417716*o[8] - 94.4508644545118*q2) + 0.360567666582363*o[5]*(-0.0161221195808321 + q2)*(0.0338039844460968 + q2) + o[11]*(-0.000584580992538624*o[10]*o[12]*o[7] + 1.33248030241755e6*o[12]*o[13]*q2) + o[9]*(-7.38502736990986e7*o[18] + 0.0000224425477627799*o[6]*o[7]*q2) + o[4]*o[5]*(-2.08438767026518e8*o[17] - 0.0000124971648677697*o[6] - 8442.30378348203*o[10]*o[6]*o[7]*q2) + o[11]*o[9]*(4.73594929247646e-22*o[10]*o[12]*q2 - 13.6411358215175*o[10]*o[12]*o[13]*q2 + 5.52427169406836e-10*o[13]*o[6]*o[7]*q2) + o[11]*o[5]*(2.67174673301715e-6*o[17] + 4.44545133805865e-18*o[12]*o[6]*q2 - 50.2465185106411*o[10]*o[13]*o[6]*o[7]*q2)))/o[1];
            end hlowerofp2;

            function hupperofp2 "Explicit upper specific enthalpy limit of region 2 as function of pressure"
              input SI.Pressure p "Pressure";
              output SI.SpecificEnthalpy h "Specific enthalpy";
            protected
              Real pi "Dimensionless pressure";
              Real o[2] "Vector of auxiliary variables";
            algorithm
              pi := p/data.PSTAR2;
              assert(p > triple.ptriple, "IF97 medium function hupperofp2 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              o[1] := pi*pi;
              o[2] := o[1]*o[1]*o[1];
              h := 4.16066337647071e6 + pi*(-4518.48617188327 + pi*(-8.53409968320258 + pi*(0.109090430596056 + pi*(-0.000172486052272327 + pi*(4.2261295097284e-15 + pi*(-1.27295130636232e-10 + pi*(-3.79407294691742e-25 + pi*(7.56960433802525e-23 + pi*(7.16825117265975e-32 + pi*(3.37267475986401e-21 + (-7.5656940729795e-74 + o[1]*(-8.00969737237617e-134 + (1.6746290980312e-65 + pi*(-3.71600586812966e-69 + pi*(8.06630589170884e-129 + (-1.76117969553159e-103 + 1.88543121025106e-84*pi)*pi)))*o[1]))*o[2]))))))))));
            end hupperofp2;

            function d1n "Density in region 1 as function of p and T"
              input SI.Pressure p "Pressure";
              input SI.Temperature T "Temperature (K)";
              output SI.Density d "Density";
            protected
              Real pi "Dimensionless pressure";
              Real pi1 "Dimensionless pressure";
              Real tau "Dimensionless temperature";
              Real tau1 "Dimensionless temperature";
              Real gpi "Dimensionless Gibbs-derivative w.r.t. pi";
              Real o[11] "Auxiliary variables";
            algorithm
              pi := p/data.PSTAR1;
              tau := data.TSTAR1/T;
              pi1 := 7.1 - pi;
              tau1 := tau - 1.222;
              o[1] := tau1*tau1;
              o[2] := o[1]*o[1];
              o[3] := o[2]*o[2];
              o[4] := o[1]*o[2];
              o[5] := o[1]*tau1;
              o[6] := o[2]*tau1;
              o[7] := pi1*pi1;
              o[8] := o[7]*o[7];
              o[9] := o[8]*o[8];
              o[10] := o[3]*o[3];
              o[11] := o[10]*o[10];
              gpi := pi1*(pi1*((0.000095038934535162 + o[2]*(8.4812393955936e-6 + 2.55615384360309e-9*o[4]))/o[2] + pi1*((8.9701127632e-6 + (2.60684891582404e-6 + 5.7366919751696e-13*o[2]*o[3])*o[5])/o[6] + pi1*(2.02584984300585e-6/o[3] + o[7]*pi1*(o[8]*o[9]*pi1*(o[7]*(o[7]*o[8]*(-7.63737668221055e-22/(o[1]*o[11]*o[2]) + pi1*(pi1*(-5.65070932023524e-23/(o[11]*o[3]) + (2.99318679335866e-24*pi1)/(o[11]*o[3]*tau1)) + 3.5842867920213e-22/(o[1]*o[11]*o[2]*tau1))) - 3.33001080055983e-19/(o[1]*o[10]*o[2]*o[3]*tau1)) + 1.44400475720615e-17/(o[10]*o[2]*o[3]*tau1)) + (1.01874413933128e-8 + 1.39398969845072e-9*o[6])/(o[1]*o[3]*tau1))))) + (0.00094368642146534 + o[5]*(0.00060003561586052 + (-0.000095322787813974 + o[1]*(8.8283690661692e-6 + 1.45389992595188e-15*o[1]*o[2]*o[3]))*tau1))/o[5]) + (-0.00028319080123804 + o[1]*(0.00060706301565874 + o[4]*(0.018990068218419 + tau1*(0.032529748770505 + (0.021841717175414 + 0.00005283835796993*o[1])*tau1))))/(o[3]*tau1);
              d := p/(data.RH2O*T*pi*gpi);
            end d1n;

            function d2n "Density in region 2 as function of p and T"
              input SI.Pressure p "Pressure";
              input SI.Temperature T "Temperature (K)";
              output SI.Density d "Density";
            protected
              Real pi "Dimensionless pressure";
              Real tau "Dimensionless temperature";
              Real tau2 "Dimensionless temperature";
              Real gpi "Dimensionless Gibbs-derivative w.r.t. pi";
              Real o[12] "Auxiliary variables";
            algorithm
              pi := p/data.PSTAR2;
              tau := data.TSTAR2/T;
              tau2 := tau - 0.5;
              o[1] := tau2*tau2;
              o[2] := o[1]*tau2;
              o[3] := o[1]*o[1];
              o[4] := o[3]*o[3];
              o[5] := o[4]*o[4];
              o[6] := o[3]*o[4]*o[5]*tau2;
              o[7] := o[3]*o[4]*tau2;
              o[8] := o[1]*o[3]*o[4];
              o[9] := pi*pi;
              o[10] := o[9]*o[9];
              o[11] := o[3]*o[5]*tau2;
              o[12] := o[5]*o[5];
              gpi := (1. + pi*(-0.0017731742473213 + tau2*(-0.017834862292358 + tau2*(-0.045996013696365 + (-0.057581259083432 - 0.05032527872793*o[2])*tau2)) + pi*(tau2*(-0.000066065283340406 + (-0.0003789797503263 + o[1]*(-0.007878555448671 + o[2]*(-0.087594591301146 - 0.000053349095828174*o[6])))*tau2) + pi*(6.1445213076927e-8 + (1.31612001853305e-6 + o[1]*(-0.00009683303171571 + o[2]*(-0.0045101773626444 - 0.122004760687947*o[6])))*tau2 + pi*(tau2*(-3.15389238237468e-9 + (5.116287140914e-8 + 1.92901490874028e-6*tau2)*tau2) + pi*(0.0000114610381688305*o[1]*o[3]*tau2 + pi*(o[2]*(-1.00288598706366e-10 + o[7]*(-0.012702883392813 - 143.374451604624*o[1]*o[5]*tau2)) + pi*(-4.1341695026989e-17 + o[1]*o[4]*(-8.8352662293707e-6 - 0.272627897050173*o[8])*tau2 + pi*(o[4]*(9.0049690883672e-11 - 65.8490727183984*o[3]*o[4]*o[5]) + pi*(1.78287415218792e-7*o[7] + pi*(o[3]*(1.0406965210174e-18 + o[1]*(-1.0234747095929e-12 - 1.0018179379511e-8*o[3])*o[3]) + o[10]*o[9]*((-1.29412653835176e-9 + 1.71088510070544*o[11])*o[6] + o[9]*(-6.05920510335078*o[12]*o[4]*o[5]*tau2 + o[9]*(o[3]*o[5]*(1.78371690710842e-23 + o[1]*o[3]*o[4]*(6.1258633752464e-12 - 0.000084004935396416*o[7])*tau2) + pi*(-1.24017662339842e-24*o[11] + pi*(0.0000832192847496054*o[12]*o[3]*o[5]*tau2 + pi*(o[1]*o[4]*o[5]*(1.75410265428146e-27 + (1.32995316841867e-15 - 0.0000226487297378904*o[1]*o[5])*o[8])*pi - 2.93678005497663e-14*o[1]*o[12]*o[3]*tau2)))))))))))))))))/pi;
              d := p/(data.RH2O*T*pi*gpi);
            end d2n;

            function hl_p_R4b "Explicit approximation of liquid specific enthalpy on the boundary between regions 4 and 3"
              input SI.Pressure p "Pressure";
              output SI.SpecificEnthalpy h "Specific enthalpy";
            protected
              Real x "Auxiliary variable";
            algorithm
              x := Modelica.Math.acos(p/data.PCRIT);
              h := (1 + x*(-0.4945586958175176 + x*(1.346800016564904 + x*(-3.889388153209752 + x*(6.679385472887931 + x*(-6.75820241066552 + x*(3.558919744656498 + (-0.7179818554978939 - 0.0001152032945617821*x)*x)))))))*data.HCRIT;
            end hl_p_R4b;

            function hv_p_R4b "Explicit approximation of vapour specific enthalpy on the boundary between regions 4 and 3"
              input SI.Pressure p "Pressure";
              output SI.SpecificEnthalpy h "Specific enthalpy";
            protected
              Real x "Auxiliary variable";
            algorithm
              x := Modelica.Math.acos(p/data.PCRIT);
              h := (1 + x*(0.4880153718655694 + x*(0.2079670746250689 + x*(-6.084122698421623 + x*(25.08887602293532 + x*(-48.38215180269516 + x*(45.66489164833212 + (-16.98555442961553 + 0.0006616936460057691*x)*x)))))))*data.HCRIT;
            end hv_p_R4b;

            function rhol_p_R4b "Explicit approximation of liquid density on the boundary between regions 4 and 3"
              input SI.Pressure p "Pressure";
              output SI.Density dl "Liquid density";
            protected
              Real x "Auxiliary variable";
            algorithm
              if (p < data.PCRIT) then
                x := Modelica.Math.acos(p/data.PCRIT);
                dl := (1 + x*(1.903224079094824 + x*(-2.5314861802401123 + x*(-8.191449323843552 + x*(94.34196116778385 + x*(-369.3676833623383 + x*(796.6627910598293 + x*(-994.5385383600702 + x*(673.2581177021598 + (-191.43077336405156 + 0.00052536560808895*x)*x)))))))))*data.DCRIT;
              else
                dl := data.DCRIT;
              end if;
            end rhol_p_R4b;

            function rhov_p_R4b "Explicit approximation of vapour density on the boundary between regions 4 and 2"
              input SI.Pressure p "Pressure";
              output SI.Density dv "Vapour density";
            protected
              Real x "Auxiliary variable";
            algorithm
              if (p < data.PCRIT) then
                x := Modelica.Math.acos(p/data.PCRIT);
                dv := (1 + x*(-1.8463850803362596 + x*(-1.1447872718878493 + x*(59.18702203076563 + x*(-403.5391431811611 + x*(1437.2007245332388 + x*(-3015.853540307519 + x*(3740.5790348670057 + x*(-2537.375817253895 + (725.8761975803782 - 0.0011151111658332337*x)*x)))))))))*data.DCRIT;
              else
                dv := data.DCRIT;
              end if;
            end rhov_p_R4b;

            function boilingcurve_p "Properties on the boiling curve"
              input SI.Pressure p "Pressure";
              output Common.IF97PhaseBoundaryProperties bpro "Property record";
            protected
              Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives";
              Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives";
              SI.Pressure plim = min(p, data.PCRIT - 1e-7) "Pressure limited to critical pressure - epsilon";
            algorithm
              bpro.R_s := data.RH2O;
              bpro.T := Basic.tsat(plim);
              bpro.dpT := Basic.dptofT(bpro.T);
              bpro.region3boundary := bpro.T > data.TLIMIT1;
              if not bpro.region3boundary then
                g := Basic.g1(p, bpro.T);
                bpro.d := p/(bpro.R_s*bpro.T*g.pi*g.gpi);
                bpro.h := if p > plim then data.HCRIT else bpro.R_s*bpro.T*g.tau*g.gtau;
                bpro.s := g.R_s*(g.tau*g.gtau - g.g);
                bpro.cp := -bpro.R_s*g.tau*g.tau*g.gtautau;
                bpro.vt := bpro.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
                bpro.vp := bpro.R_s*bpro.T/(p*p)*g.pi*g.pi*g.gpipi;
                bpro.pt := -p/bpro.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
                bpro.pd := -bpro.R_s*bpro.T*g.gpi*g.gpi/(g.gpipi);
              else
                bpro.d := rhol_p_R4b(plim);
                f := Basic.f3(bpro.d, bpro.T);
                bpro.h := hl_p_R4b(plim);
                bpro.s := f.R_s*(f.tau*f.ftau - f.f);
                bpro.cv := bpro.R_s*(-f.tau*f.tau*f.ftautau);
                bpro.pt := bpro.R_s*bpro.d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
                bpro.pd := bpro.R_s*bpro.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
              end if;
            end boilingcurve_p;

            function dewcurve_p "Properties on the dew curve"
              input SI.Pressure p "Pressure";
              output Common.IF97PhaseBoundaryProperties bpro "Property record";
            protected
              Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives";
              Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives";
              SI.Pressure plim = min(p, data.PCRIT - 1e-7) "Pressure limited to critical pressure - epsilon";
            algorithm
              bpro.R_s := data.RH2O;
              bpro.T := Basic.tsat(plim);
              bpro.dpT := Basic.dptofT(bpro.T);
              bpro.region3boundary := bpro.T > data.TLIMIT1;
              if not bpro.region3boundary then
                g := Basic.g2(p, bpro.T);
                bpro.d := p/(bpro.R_s*bpro.T*g.pi*g.gpi);
                bpro.h := if p > plim then data.HCRIT else bpro.R_s*bpro.T*g.tau*g.gtau;
                bpro.s := g.R_s*(g.tau*g.gtau - g.g);
                bpro.cp := -bpro.R_s*g.tau*g.tau*g.gtautau;
                bpro.vt := bpro.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
                bpro.vp := bpro.R_s*bpro.T/(p*p)*g.pi*g.pi*g.gpipi;
                bpro.pt := -p/bpro.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
                bpro.pd := -bpro.R_s*bpro.T*g.gpi*g.gpi/(g.gpipi);
              else
                bpro.d := rhov_p_R4b(plim);
                f := Basic.f3(bpro.d, bpro.T);
                bpro.h := hv_p_R4b(plim);
                bpro.s := f.R_s*(f.tau*f.ftau - f.f);
                bpro.cv := bpro.R_s*(-f.tau*f.tau*f.ftautau);
                bpro.pt := bpro.R_s*bpro.d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
                bpro.pd := bpro.R_s*bpro.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
              end if;
            end dewcurve_p;

            function hvl_p
              input SI.Pressure p "Pressure";
              input Common.IF97PhaseBoundaryProperties bpro "Property record";
              output SI.SpecificEnthalpy h "Specific enthalpy";
            algorithm
              h := bpro.h;
              annotation(derivative(noDerivative = bpro) = hvl_p_der, Inline = false, LateInline = true);
            end hvl_p;

            function hl_p "Liquid specific enthalpy on the boundary between regions 4 and 3 or 1"
              input SI.Pressure p "Pressure";
              output SI.SpecificEnthalpy h "Specific enthalpy";
            algorithm
              h := hvl_p(p, boilingcurve_p(p));
              annotation(Inline = true);
            end hl_p;

            function hv_p "Vapour specific enthalpy on the boundary between regions 4 and 3 or 2"
              input SI.Pressure p "Pressure";
              output SI.SpecificEnthalpy h "Specific enthalpy";
            algorithm
              h := hvl_p(p, dewcurve_p(p));
              annotation(Inline = true);
            end hv_p;

            function hvl_p_der "Derivative function for the specific enthalpy along the phase boundary"
              input SI.Pressure p "Pressure";
              input Common.IF97PhaseBoundaryProperties bpro "Property record";
              input Real p_der "Derivative of pressure";
              output Real h_der "Time derivative of specific enthalpy along the phase boundary";
            algorithm
              if bpro.region3boundary then
                h_der := ((bpro.d*bpro.pd - bpro.T*bpro.pt)*p_der + (bpro.T*bpro.pt*bpro.pt + bpro.d*bpro.d*bpro.pd*bpro.cv)/bpro.dpT*p_der)/(bpro.pd*bpro.d*bpro.d);
              else
                h_der := (1/bpro.d - bpro.T*bpro.vt)*p_der + bpro.cp/bpro.dpT*p_der;
              end if;
              annotation(Inline = true);
            end hvl_p_der;

            function rhovl_p
              input SI.Pressure p "Pressure";
              input Common.IF97PhaseBoundaryProperties bpro "Property record";
              output SI.Density rho "Density";
            algorithm
              rho := bpro.d;
              annotation(derivative(noDerivative = bpro) = rhovl_p_der, Inline = false, LateInline = true);
            end rhovl_p;

            function rhol_p "Density of saturated water"
              input SI.Pressure p "Saturation pressure";
              output SI.Density rho "Density of steam at the condensation point";
            algorithm
              rho := rhovl_p(p, boilingcurve_p(p));
              annotation(Inline = true);
            end rhol_p;

            function rhov_p "Density of saturated vapour"
              input SI.Pressure p "Saturation pressure";
              output SI.Density rho "Density of steam at the condensation point";
            algorithm
              rho := rhovl_p(p, dewcurve_p(p));
              annotation(Inline = true);
            end rhov_p;

            function rhovl_p_der
              input SI.Pressure p "Saturation pressure";
              input Common.IF97PhaseBoundaryProperties bpro "Property record";
              input Real p_der "Derivative of pressure";
              output Real d_der "Time derivative of density along the phase boundary";
            algorithm
              d_der := if bpro.region3boundary then (p_der - bpro.pt*p_der/bpro.dpT)/bpro.pd else -bpro.d*bpro.d*(bpro.vp + bpro.vt/bpro.dpT)*p_der;
              annotation(Inline = true);
            end rhovl_p_der;

            function rhol_T "Density of saturated water"
              input SI.Temperature T "Temperature";
              output SI.Density d "Density of water at the boiling point";
            protected
              SI.Pressure p "Saturation pressure";
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

            function rhov_T "Density of saturated vapour"
              input SI.Temperature T "Temperature";
              output SI.Density d "Density of steam at the condensation point";
            protected
              SI.Pressure p "Saturation pressure";
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

            function region_ph "Return the current region (valid values: 1,2,3,4,5) in IF97 for given pressure and specific enthalpy"
              input SI.Pressure p "Pressure";
              input SI.SpecificEnthalpy h "Specific enthalpy";
              input Integer phase = 0 "Phase: 2 for two-phase, 1 for one phase, 0 if not known";
              input Integer mode = 0 "Mode: 0 means check, otherwise assume region=mode";
              output Integer region "Region (valid values: 1,2,3,4,5) in IF97";
            protected
              Boolean hsubcrit;
              SI.Temperature Ttest;
              constant Real n[5] = data.n;
              SI.SpecificEnthalpy hl "Bubble enthalpy";
              SI.SpecificEnthalpy hv "Dew enthalpy";
            algorithm
              if (mode <> 0) then
                region := mode;
              else
                hl := hl_p(p);
                hv := hv_p(p);
                if (phase == 2) then
                  region := 4;
                else
                  if (p < triple.ptriple) or (p > data.PLIMIT1) or (h < hlowerofp1(p)) or ((p < 10.0e6) and (h > hupperofp5(p))) or ((p >= 10.0e6) and (h > hupperofp2(p))) then
                    region := -1;
                  else
                    hsubcrit := (h < data.HCRIT);
                    if (p < data.PLIMIT4A) then
                      if hsubcrit then
                        if (phase == 1) then
                          region := 1;
                        else
                          if (h < Isentropic.hofpT1(p, Basic.tsat(p))) then
                            region := 1;
                          else
                            region := 4;
                          end if;
                        end if;
                      else
                        if (h > hlowerofp5(p)) then
                          if ((p < data.PLIMIT5) and (h < hupperofp5(p))) then
                            region := 5;
                          else
                            region := -2;
                          end if;
                        else
                          if (phase == 1) then
                            region := 2;
                          else
                            if (h > Isentropic.hofpT2(p, Basic.tsat(p))) then
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
                        if (h > hlowerofp2(p)) then
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

            function region_pT "Return the current region (valid values: 1,2,3,5) in IF97, given pressure and temperature"
              input SI.Pressure p "Pressure";
              input SI.Temperature T "Temperature (K)";
              input Integer mode = 0 "Mode: 0 means check, otherwise assume region=mode";
              output Integer region "Region (valid values: 1,2,3,5) in IF97, region 4 is impossible!";
            algorithm
              if (mode <> 0) then
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

            function region_dT "Return the current region (valid values: 1,2,3,4,5) in IF97, given density and temperature"
              input SI.Density d "Density";
              input SI.Temperature T "Temperature (K)";
              input Integer phase = 0 "Phase: 2 for two-phase, 1 for one phase, 0 if not known";
              input Integer mode = 0 "Mode: 0 means check, otherwise assume region=mode";
              output Integer region "(valid values: 1,2,3,4,5) in IF97";
            protected
              Boolean Tovercrit "Flag if overcritical temperature";
              SI.Pressure p23 "Pressure needed to know if region 2 or 3";
            algorithm
              Tovercrit := T > data.TCRIT;
              if (mode <> 0) then
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
                elseif (d > rhol_T(T)) then
                  if T < data.TLIMIT1 then
                    region := 1;
                  else
                    region := 3;
                  end if;
                elseif (d < rhov_T(T)) then
                  if (d > d2n(p23, T) and T > data.TLIMIT1) then
                    region := 3;
                  else
                    region := 2;
                  end if;
                else
                  region := 4;
                end if;
              end if;
            end region_dT;
          end Regions;

          package Basic "Base functions as described in IAWPS/IF97"
            function g1 "Gibbs function for region 1: g(p,T)"
              input SI.Pressure p "Pressure";
              input SI.Temperature T "Temperature (K)";
              output Modelica.Media.Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
            protected
              Real pi1 "Dimensionless pressure";
              Real tau1 "Dimensionless temperature";
              Real o[45] "Vector of auxiliary variables";
              Real pl "Auxiliary variable";
            algorithm
              pl := min(p, data.PCRIT - 1);
              assert(p > triple.ptriple, "IF97 medium function g1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              assert(p <= 100.0e6, "IF97 medium function g1: the input pressure (= " + String(p) + " Pa) is higher than 100 MPa");
              assert(T >= 273.15, "IF97 medium function g1: the temperature (= " + String(T) + " K) is lower than 273.15 K!");
              g.p := p;
              g.T := T;
              g.R_s := data.RH2O;
              g.pi := p/data.PSTAR1;
              g.tau := data.TSTAR1/T;
              pi1 := 7.1000000000000 - g.pi;
              tau1 := -1.22200000000000 + g.tau;
              o[1] := tau1*tau1;
              o[2] := o[1]*o[1];
              o[3] := o[2]*o[2];
              o[4] := o[3]*tau1;
              o[5] := 1/o[4];
              o[6] := o[1]*o[2];
              o[7] := o[1]*tau1;
              o[8] := 1/o[7];
              o[9] := o[1]*o[2]*o[3];
              o[10] := 1/o[2];
              o[11] := o[2]*tau1;
              o[12] := 1/o[11];
              o[13] := o[2]*o[3];
              o[14] := 1/o[3];
              o[15] := pi1*pi1;
              o[16] := o[15]*pi1;
              o[17] := o[15]*o[15];
              o[18] := o[17]*o[17];
              o[19] := o[17]*o[18]*pi1;
              o[20] := o[15]*o[17];
              o[21] := o[3]*o[3];
              o[22] := o[21]*o[21];
              o[23] := o[22]*o[3]*tau1;
              o[24] := 1/o[23];
              o[25] := o[22]*o[3];
              o[26] := 1/o[25];
              o[27] := o[1]*o[2]*o[22]*tau1;
              o[28] := 1/o[27];
              o[29] := o[1]*o[2]*o[22];
              o[30] := 1/o[29];
              o[31] := o[1]*o[2]*o[21]*o[3]*tau1;
              o[32] := 1/o[31];
              o[33] := o[2]*o[21]*o[3]*tau1;
              o[34] := 1/o[33];
              o[35] := o[1]*o[3]*tau1;
              o[36] := 1/o[35];
              o[37] := o[1]*o[3];
              o[38] := 1/o[37];
              o[39] := 1/o[6];
              o[40] := o[1]*o[22]*o[3];
              o[41] := 1/o[40];
              o[42] := 1/o[22];
              o[43] := o[1]*o[2]*o[21]*o[3];
              o[44] := 1/o[43];
              o[45] := 1/o[13];
              g.g := pi1*(pi1*(pi1*(o[10]*(-0.000031679644845054 + o[2]*(-2.82707979853120e-6 - 8.5205128120103e-10*o[6])) + pi1*(o[12]*(-2.24252819080000e-6 + (-6.5171222895601e-7 - 1.43417299379240e-13*o[13])*o[7]) + pi1*(-4.0516996860117e-7*o[14] + o[16]*((-1.27343017416410e-9 - 1.74248712306340e-10*o[11])*o[36] + o[19]*(-6.8762131295531e-19*o[34] + o[15]*(1.44783078285210e-20*o[32] + o[20]*(2.63357816627950e-23*o[30] + pi1*(-1.19476226400710e-23*o[28] + pi1*(1.82280945814040e-24*o[26] - 9.3537087292458e-26*o[24]*pi1))))))))) + o[8]*(-0.00047184321073267 + o[7]*(-0.000300017807930260 + (0.000047661393906987 + o[1]*(-4.4141845330846e-6 - 7.2694996297594e-16*o[9]))*tau1))) + o[5]*(0.000283190801238040 + o[1]*(-0.00060706301565874 + o[6]*(-0.0189900682184190 + tau1*(-0.032529748770505 + (-0.0218417171754140 - 0.000052838357969930*o[1])*tau1))))) + (0.146329712131670 + tau1*(-0.84548187169114 + tau1*(-3.7563603672040 + tau1*(3.3855169168385 + tau1*(-0.95791963387872 + tau1*(0.157720385132280 + (-0.0166164171995010 + 0.00081214629983568*tau1)*tau1))))))/o[1];
              g.gpi := pi1*(pi1*(o[10]*(0.000095038934535162 + o[2]*(8.4812393955936e-6 + 2.55615384360309e-9*o[6])) + pi1*(o[12]*(8.9701127632000e-6 + (2.60684891582404e-6 + 5.7366919751696e-13*o[13])*o[7]) + pi1*(2.02584984300585e-6*o[14] + o[16]*((1.01874413933128e-8 + 1.39398969845072e-9*o[11])*o[36] + o[19]*(1.44400475720615e-17*o[34] + o[15]*(-3.3300108005598e-19*o[32] + o[20]*(-7.6373766822106e-22*o[30] + pi1*(3.5842867920213e-22*o[28] + pi1*(-5.6507093202352e-23*o[26] + 2.99318679335866e-24*o[24]*pi1))))))))) + o[8]*(0.00094368642146534 + o[7]*(0.00060003561586052 + (-0.000095322787813974 + o[1]*(8.8283690661692e-6 + 1.45389992595188e-15*o[9]))*tau1))) + o[5]*(-0.000283190801238040 + o[1]*(0.00060706301565874 + o[6]*(0.0189900682184190 + tau1*(0.032529748770505 + (0.0218417171754140 + 0.000052838357969930*o[1])*tau1))));
              g.gpipi := pi1*(o[10]*(-0.000190077869070324 + o[2]*(-0.0000169624787911872 - 5.1123076872062e-9*o[6])) + pi1*(o[12]*(-0.0000269103382896000 + (-7.8205467474721e-6 - 1.72100759255088e-12*o[13])*o[7]) + pi1*(-8.1033993720234e-6*o[14] + o[16]*((-7.1312089753190e-8 - 9.7579278891550e-9*o[11])*o[36] + o[19]*(-2.88800951441230e-16*o[34] + o[15]*(7.3260237612316e-18*o[32] + o[20]*(2.13846547101895e-20*o[30] + pi1*(-1.03944316968618e-20*o[28] + pi1*(1.69521279607057e-21*o[26] - 9.2788790594118e-23*o[24]*pi1))))))))) + o[8]*(-0.00094368642146534 + o[7]*(-0.00060003561586052 + (0.000095322787813974 + o[1]*(-8.8283690661692e-6 - 1.45389992595188e-15*o[9]))*tau1));
              g.gtau := pi1*(o[38]*(-0.00254871721114236 + o[1]*(0.0042494411096112 + (0.0189900682184190 + (-0.0218417171754140 - 0.000158515073909790*o[1])*o[1])*o[6])) + pi1*(o[10]*(0.00141552963219801 + o[2]*(0.000047661393906987 + o[1]*(-0.0000132425535992538 - 1.23581493705910e-14*o[9]))) + pi1*(o[12]*(0.000126718579380216 - 5.1123076872062e-9*o[37]) + pi1*(o[39]*(0.0000112126409540000 + (1.30342445791202e-6 - 1.43417299379240e-12*o[13])*o[7]) + pi1*(3.2413597488094e-6*o[5] + o[16]*((1.40077319158051e-8 + 1.04549227383804e-9*o[11])*o[45] + o[19]*(1.99410180757040e-17*o[44] + o[15]*(-4.4882754268415e-19*o[42] + o[20]*(-1.00075970318621e-21*o[28] + pi1*(4.6595728296277e-22*o[26] + pi1*(-7.2912378325616e-23*o[24] + 3.8350205789908e-24*o[41]*pi1))))))))))) + o[8]*(-0.292659424263340 + tau1*(0.84548187169114 + o[1]*(3.3855169168385 + tau1*(-1.91583926775744 + tau1*(0.47316115539684 + (-0.066465668798004 + 0.0040607314991784*tau1)*tau1)))));
              g.gtautau := pi1*(o[36]*(0.0254871721114236 + o[1]*(-0.033995528876889 + (-0.037980136436838 - 0.00031703014781958*o[2])*o[6])) + pi1*(o[12]*(-0.0056621185287920 + o[6]*(-0.0000264851071985076 - 1.97730389929456e-13*o[9])) + pi1*((-0.00063359289690108 - 2.55615384360309e-8*o[37])*o[39] + pi1*(pi1*(-0.0000291722377392842*o[38] + o[16]*(o[19]*(-5.9823054227112e-16*o[32] + o[15]*(o[20]*(3.9029628424262e-20*o[26] + pi1*(-1.86382913185108e-20*o[24] + pi1*(2.98940751135026e-21*o[41] - (1.61070864317613e-22*pi1)/(o[1]*o[22]*o[3]*tau1)))) + 1.43624813658928e-17/(o[22]*tau1))) + (-1.68092782989661e-7 - 7.3184459168663e-9*o[11])/(o[2]*o[3]*tau1))) + (-0.000067275845724000 + (-3.9102733737361e-6 - 1.29075569441316e-11*o[13])*o[7])/(o[1]*o[2]*tau1))))) + o[10]*(0.87797827279002 + tau1*(-1.69096374338228 + o[7]*(-1.91583926775744 + tau1*(0.94632231079368 + (-0.199397006394012 + 0.0162429259967136*tau1)*tau1))));
              g.gtaupi := o[38]*(0.00254871721114236 + o[1]*(-0.0042494411096112 + (-0.0189900682184190 + (0.0218417171754140 + 0.000158515073909790*o[1])*o[1])*o[6])) + pi1*(o[10]*(-0.00283105926439602 + o[2]*(-0.000095322787813974 + o[1]*(0.0000264851071985076 + 2.47162987411820e-14*o[9]))) + pi1*(o[12]*(-0.00038015573814065 + 1.53369230616185e-8*o[37]) + pi1*(o[39]*(-0.000044850563816000 + (-5.2136978316481e-6 + 5.7366919751696e-12*o[13])*o[7]) + pi1*(-0.0000162067987440468*o[5] + o[16]*((-1.12061855326441e-7 - 8.3639381907043e-9*o[11])*o[45] + o[19]*(-4.1876137958978e-16*o[44] + o[15]*(1.03230334817355e-17*o[42] + o[20]*(2.90220313924001e-20*o[28] + pi1*(-1.39787184888831e-20*o[26] + pi1*(2.26028372809410e-21*o[24] - 1.22720658527705e-22*o[41]*pi1))))))))));
            end g1;

            function g2 "Gibbs function for region 2: g(p,T)"
              input SI.Pressure p "Pressure";
              input SI.Temperature T "Temperature (K)";
              input Boolean checkLimits = true "Check if inputs p,T are in region of validity";
              output Modelica.Media.Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
            protected
              Real tau2 "Dimensionless temperature";
              Real o[55] "Vector of auxiliary variables";
            algorithm
              g.p := p;
              g.T := T;
              g.R_s := data.RH2O;
              if checkLimits then
                assert(p > 0.0, "IF97 medium function g2 called with too low pressure\n" + "p = " + String(p) + " Pa <= 0.0 Pa");
                assert(p <= 100.0e6, "IF97 medium function g2: the input pressure (= " + String(p) + " Pa) is higher than 100 MPa");
                assert(T >= 273.15, "IF97 medium function g2: the temperature (= " + String(T) + " K) is lower than 273.15 K!");
                assert(T <= 1073.15, "IF97 medium function g2: the input temperature (= " + String(T) + " K) is higher than the limit of 1073.15 K");
              else
              end if;
              g.pi := p/data.PSTAR2;
              g.tau := data.TSTAR2/T;
              tau2 := -0.5 + g.tau;
              o[1] := tau2*tau2;
              o[2] := o[1]*tau2;
              o[3] := -0.050325278727930*o[2];
              o[4] := -0.057581259083432 + o[3];
              o[5] := o[4]*tau2;
              o[6] := -0.045996013696365 + o[5];
              o[7] := o[6]*tau2;
              o[8] := -0.0178348622923580 + o[7];
              o[9] := o[8]*tau2;
              o[10] := o[1]*o[1];
              o[11] := o[10]*o[10];
              o[12] := o[11]*o[11];
              o[13] := o[10]*o[11]*o[12]*tau2;
              o[14] := o[1]*o[10]*tau2;
              o[15] := o[10]*o[11]*tau2;
              o[16] := o[1]*o[12]*tau2;
              o[17] := o[1]*o[11]*tau2;
              o[18] := o[1]*o[10]*o[11];
              o[19] := o[10]*o[11]*o[12];
              o[20] := o[1]*o[10];
              o[21] := g.pi*g.pi;
              o[22] := o[21]*o[21];
              o[23] := o[21]*o[22];
              o[24] := o[10]*o[12]*tau2;
              o[25] := o[12]*o[12];
              o[26] := o[11]*o[12]*o[25]*tau2;
              o[27] := o[10]*o[12];
              o[28] := o[1]*o[10]*o[11]*tau2;
              o[29] := o[10]*o[12]*o[25]*tau2;
              o[30] := o[1]*o[10]*o[25]*tau2;
              o[31] := o[1]*o[11]*o[12];
              o[32] := o[1]*o[12];
              o[33] := g.tau*g.tau;
              o[34] := o[33]*o[33];
              o[35] := -0.000053349095828174*o[13];
              o[36] := -0.087594591301146 + o[35];
              o[37] := o[2]*o[36];
              o[38] := -0.0078785554486710 + o[37];
              o[39] := o[1]*o[38];
              o[40] := -0.00037897975032630 + o[39];
              o[41] := o[40]*tau2;
              o[42] := -0.000066065283340406 + o[41];
              o[43] := o[42]*tau2;
              o[44] := 5.7870447262208e-6*tau2;
              o[45] := -0.301951672367580*o[2];
              o[46] := -0.172743777250296 + o[45];
              o[47] := o[46]*tau2;
              o[48] := -0.091992027392730 + o[47];
              o[49] := o[48]*tau2;
              o[50] := o[1]*o[11];
              o[51] := o[10]*o[11];
              o[52] := o[11]*o[12]*o[25];
              o[53] := o[10]*o[12]*o[25];
              o[54] := o[1]*o[10]*o[25];
              o[55] := o[11]*o[12]*tau2;
              g.g := g.pi*(-0.00177317424732130 + o[9] + g.pi*(tau2*(-0.000033032641670203 + (-0.000189489875163150 + o[1]*(-0.0039392777243355 + (-0.043797295650573 - 0.0000266745479140870*o[13])*o[2]))*tau2) + g.pi*(2.04817376923090e-8 + (4.3870667284435e-7 + o[1]*(-0.000032277677238570 + (-0.00150339245421480 - 0.040668253562649*o[13])*o[2]))*tau2 + g.pi*(g.pi*(2.29220763376610e-6*o[14] + g.pi*((-1.67147664510610e-11 + o[15]*(-0.00211714723213550 - 23.8957419341040*o[16]))*o[2] + g.pi*(-5.9059564324270e-18 + o[17]*(-1.26218088991010e-6 - 0.038946842435739*o[18]) + g.pi*(o[11]*(1.12562113604590e-11 - 8.2311340897998*o[19]) + g.pi*(1.98097128020880e-8*o[15] + g.pi*(o[10]*(1.04069652101740e-19 + (-1.02347470959290e-13 - 1.00181793795110e-9*o[10])*o[20]) + o[23]*(o[13]*(-8.0882908646985e-11 + 0.106930318794090*o[24]) + o[21]*(-0.33662250574171*o[26] + o[21]*(o[27]*(8.9185845355421e-25 + (3.06293168762320e-13 - 4.2002467698208e-6*o[15])*o[28]) + g.pi*(-5.9056029685639e-26*o[24] + g.pi*(3.7826947613457e-6*o[29] + g.pi*(-1.27686089346810e-15*o[30] + o[31]*(7.3087610595061e-29 + o[18]*(5.5414715350778e-17 - 9.4369707241210e-7*o[32]))*g.pi)))))))))))) + tau2*(-7.8847309559367e-10 + (1.27907178522850e-8 + 4.8225372718507e-7*tau2)*tau2))))) + (-0.0056087911830200 + g.tau*(0.071452738814550 + g.tau*(-0.40710498239280 + g.tau*(1.42408197144400 + g.tau*(-4.3839511194500 + g.tau*(-9.6927686002170 + g.tau*(10.0866556801800 + (-0.284086326077200 + 0.0212684635330700*g.tau)*g.tau) + Modelica.Math.log(g.pi)))))))/(o[34]*g.tau);
              g.gpi := (1.00000000000000 + g.pi*(-0.00177317424732130 + o[9] + g.pi*(o[43] + g.pi*(6.1445213076927e-8 + (1.31612001853305e-6 + o[1]*(-0.000096833031715710 + (-0.0045101773626444 - 0.122004760687947*o[13])*o[2]))*tau2 + g.pi*(g.pi*(0.0000114610381688305*o[14] + g.pi*((-1.00288598706366e-10 + o[15]*(-0.0127028833928130 - 143.374451604624*o[16]))*o[2] + g.pi*(-4.1341695026989e-17 + o[17]*(-8.8352662293707e-6 - 0.272627897050173*o[18]) + g.pi*(o[11]*(9.0049690883672e-11 - 65.849072718398*o[19]) + g.pi*(1.78287415218792e-7*o[15] + g.pi*(o[10]*(1.04069652101740e-18 + (-1.02347470959290e-12 - 1.00181793795110e-8*o[10])*o[20]) + o[23]*(o[13]*(-1.29412653835176e-9 + 1.71088510070544*o[24]) + o[21]*(-6.0592051033508*o[26] + o[21]*(o[27]*(1.78371690710842e-23 + (6.1258633752464e-12 - 0.000084004935396416*o[15])*o[28]) + g.pi*(-1.24017662339842e-24*o[24] + g.pi*(0.000083219284749605*o[29] + g.pi*(-2.93678005497663e-14*o[30] + o[31]*(1.75410265428146e-27 + o[18]*(1.32995316841867e-15 - 0.0000226487297378904*o[32]))*g.pi)))))))))))) + tau2*(-3.15389238237468e-9 + (5.1162871409140e-8 + 1.92901490874028e-6*tau2)*tau2))))))/g.pi;
              g.gpipi := (-1.00000000000000 + o[21]*(o[43] + g.pi*(1.22890426153854e-7 + (2.63224003706610e-6 + o[1]*(-0.000193666063431420 + (-0.0090203547252888 - 0.244009521375894*o[13])*o[2]))*tau2 + g.pi*(g.pi*(0.000045844152675322*o[14] + g.pi*((-5.0144299353183e-10 + o[15]*(-0.063514416964065 - 716.87225802312*o[16]))*o[2] + g.pi*(-2.48050170161934e-16 + o[17]*(-0.000053011597376224 - 1.63576738230104*o[18]) + g.pi*(o[11]*(6.3034783618570e-10 - 460.94350902879*o[19]) + g.pi*(1.42629932175034e-6*o[15] + g.pi*(o[10]*(9.3662686891566e-18 + (-9.2112723863361e-12 - 9.0163614415599e-8*o[10])*o[20]) + o[23]*(o[13]*(-1.94118980752764e-8 + 25.6632765105816*o[24]) + o[21]*(-103.006486756963*o[26] + o[21]*(o[27]*(3.3890621235060e-22 + (1.16391404129682e-10 - 0.00159609377253190*o[15])*o[28]) + g.pi*(-2.48035324679684e-23*o[24] + g.pi*(0.00174760497974171*o[29] + g.pi*(-6.4609161209486e-13*o[30] + o[31]*(4.0344361048474e-26 + o[18]*(3.05889228736295e-14 - 0.00052092078397148*o[32]))*g.pi)))))))))))) + tau2*(-9.4616771471240e-9 + (1.53488614227420e-7 + o[44])*tau2)))))/o[21];
              g.gtau := (0.0280439559151000 + g.tau*(-0.285810955258200 + g.tau*(1.22131494717840 + g.tau*(-2.84816394288800 + g.tau*(4.3839511194500 + o[33]*(10.0866556801800 + (-0.56817265215440 + 0.063805390599210*g.tau)*g.tau))))))/(o[33]*o[34]) + g.pi*(-0.0178348622923580 + o[49] + g.pi*(-0.000033032641670203 + (-0.00037897975032630 + o[1]*(-0.0157571108973420 + (-0.306581069554011 - 0.00096028372490713*o[13])*o[2]))*tau2 + g.pi*(4.3870667284435e-7 + o[1]*(-0.000096833031715710 + (-0.0090203547252888 - 1.42338887469272*o[13])*o[2]) + g.pi*(-7.8847309559367e-10 + g.pi*(0.0000160454534363627*o[20] + g.pi*(o[1]*(-5.0144299353183e-11 + o[15]*(-0.033874355714168 - 836.35096769364*o[16])) + g.pi*((-0.0000138839897890111 - 0.97367106089347*o[18])*o[50] + g.pi*(o[14]*(9.0049690883672e-11 - 296.320827232793*o[19]) + g.pi*(2.57526266427144e-7*o[51] + g.pi*(o[2]*(4.1627860840696e-19 + (-1.02347470959290e-12 - 1.40254511313154e-8*o[10])*o[20]) + o[23]*(o[19]*(-2.34560435076256e-9 + 5.3465159397045*o[24]) + o[21]*(-19.1874828272775*o[52] + o[21]*(o[16]*(1.78371690710842e-23 + (1.07202609066812e-11 - 0.000201611844951398*o[15])*o[28]) + g.pi*(-1.24017662339842e-24*o[27] + g.pi*(0.000200482822351322*o[53] + g.pi*(-4.9797574845256e-14*o[54] + (1.90027787547159e-27 + o[18]*(2.21658861403112e-15 - 0.000054734430199902*o[32]))*o[55]*g.pi)))))))))))) + (2.55814357045700e-8 + 1.44676118155521e-6*tau2)*tau2))));
              g.gtautau := (-0.168263735490600 + g.tau*(1.42905477629100 + g.tau*(-4.8852597887136 + g.tau*(8.5444918286640 + g.tau*(-8.7679022389000 + o[33]*(-0.56817265215440 + 0.127610781198420*g.tau)*g.tau)))))/(o[33]*o[34]*g.tau) + g.pi*(-0.091992027392730 + (-0.34548755450059 - 1.50975836183790*o[2])*tau2 + g.pi*(-0.00037897975032630 + o[1]*(-0.047271332692026 + (-1.83948641732407 - 0.033609930371750*o[13])*o[2]) + g.pi*((-0.000193666063431420 + (-0.045101773626444 - 48.395221739552*o[13])*o[2])*tau2 + g.pi*(2.55814357045700e-8 + 2.89352236311042e-6*tau2 + g.pi*(0.000096272720618176*o[10]*tau2 + g.pi*((-1.00288598706366e-10 + o[15]*(-0.50811533571252 - 28435.9329015838*o[16]))*tau2 + g.pi*(o[11]*(-0.000138839897890111 - 23.3681054614434*o[18])*tau2 + g.pi*((6.3034783618570e-10 - 10371.2289531477*o[19])*o[20] + g.pi*(3.09031519712573e-6*o[17] + g.pi*(o[1]*(1.24883582522088e-18 + (-9.2112723863361e-12 - 1.82330864707100e-7*o[10])*o[20]) + o[23]*(o[1]*o[11]*o[12]*(-6.5676921821352e-8 + 261.979281045521*o[24])*tau2 + o[21]*(-1074.49903832754*o[1]*o[10]*o[12]*o[25]*tau2 + o[21]*((3.3890621235060e-22 + (3.6448887082716e-10 - 0.0094757567127157*o[15])*o[28])*o[32] + g.pi*(-2.48035324679684e-23*o[16] + g.pi*(0.0104251067622687*o[1]*o[12]*o[25]*tau2 + g.pi*(o[11]*o[12]*(4.7506946886790e-26 + o[18]*(8.6446955947214e-14 - 0.00311986252139440*o[32]))*g.pi - 1.89230784411972e-12*o[10]*o[25]*tau2))))))))))))))));
              g.gtaupi := -0.0178348622923580 + o[49] + g.pi*(-0.000066065283340406 + (-0.00075795950065260 + o[1]*(-0.0315142217946840 + (-0.61316213910802 - 0.00192056744981426*o[13])*o[2]))*tau2 + g.pi*(1.31612001853305e-6 + o[1]*(-0.000290499095147130 + (-0.0270610641758664 - 4.2701666240781*o[13])*o[2]) + g.pi*(-3.15389238237468e-9 + g.pi*(0.000080227267181813*o[20] + g.pi*(o[1]*(-3.00865796119098e-10 + o[15]*(-0.203246134285008 - 5018.1058061618*o[16])) + g.pi*((-0.000097187928523078 - 6.8156974262543*o[18])*o[50] + g.pi*(o[14]*(7.2039752706938e-10 - 2370.56661786234*o[19]) + g.pi*(2.31773639784430e-6*o[51] + g.pi*(o[2]*(4.1627860840696e-18 + (-1.02347470959290e-11 - 1.40254511313154e-7*o[10])*o[20]) + o[23]*(o[19]*(-3.7529669612201e-8 + 85.544255035272*o[24]) + o[21]*(-345.37469089099*o[52] + o[21]*(o[16]*(3.5674338142168e-22 + (2.14405218133624e-10 - 0.0040322368990280*o[15])*o[28]) + g.pi*(-2.60437090913668e-23*o[27] + g.pi*(0.0044106220917291*o[53] + g.pi*(-1.14534422144089e-12*o[54] + (4.5606669011318e-26 + o[18]*(5.3198126736747e-14 - 0.00131362632479764*o[32]))*o[55]*g.pi)))))))))))) + (1.02325742818280e-7 + o[44])*tau2)));
            end g2;

            function f3 "Helmholtz function for region 3: f(d,T)"
              input SI.Density d "Density";
              input SI.Temperature T "Temperature (K)";
              output Modelica.Media.Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
            protected
              Real o[40] "Vector of auxiliary variables";
            algorithm
              f.T := T;
              f.d := d;
              f.R_s := data.RH2O;
              f.tau := data.TCRIT/T;
              f.delta := if (d == data.DCRIT and T == data.TCRIT) then 1 - Modelica.Constants.eps else abs(d/data.DCRIT);
              o[1] := f.tau*f.tau;
              o[2] := o[1]*o[1];
              o[3] := o[2]*f.tau;
              o[4] := o[1]*f.tau;
              o[5] := o[2]*o[2];
              o[6] := o[1]*o[5]*f.tau;
              o[7] := o[5]*f.tau;
              o[8] := -0.64207765181607*o[1];
              o[9] := 0.88521043984318 + o[8];
              o[10] := o[7]*o[9];
              o[11] := -1.15244078066810 + o[10];
              o[12] := o[11]*o[2];
              o[13] := -1.26543154777140 + o[12];
              o[14] := o[1]*o[13];
              o[15] := o[1]*o[2]*o[5]*f.tau;
              o[16] := o[2]*o[5];
              o[17] := o[1]*o[5];
              o[18] := o[5]*o[5];
              o[19] := o[1]*o[18]*o[2];
              o[20] := o[1]*o[18]*o[2]*f.tau;
              o[21] := o[18]*o[5];
              o[22] := o[1]*o[18]*o[5];
              o[23] := 0.251168168486160*o[2];
              o[24] := 0.078841073758308 + o[23];
              o[25] := o[15]*o[24];
              o[26] := -6.1005234513930 + o[25];
              o[27] := o[26]*f.tau;
              o[28] := 9.7944563083754 + o[27];
              o[29] := o[2]*o[28];
              o[30] := -1.70429417648412 + o[29];
              o[31] := o[1]*o[30];
              o[32] := f.delta*f.delta;
              o[33] := -10.9153200808732*o[1];
              o[34] := 13.2781565976477 + o[33];
              o[35] := o[34]*o[7];
              o[36] := -6.9146446840086 + o[35];
              o[37] := o[2]*o[36];
              o[38] := -2.53086309554280 + o[37];
              o[39] := o[38]*f.tau;
              o[40] := o[18]*o[5]*f.tau;
              f.f := -15.7328452902390 + f.tau*(20.9443969743070 + (-7.6867707878716 + o[3]*(2.61859477879540 + o[4]*(-2.80807811486200 + o[1]*(1.20533696965170 - 0.0084566812812502*o[6]))))*f.tau) + f.delta*(o[14] + f.delta*(0.38493460186671 + o[1]*(-0.85214708824206 + o[2]*(4.8972281541877 + (-3.05026172569650 + o[15]*(0.039420536879154 + 0.125584084243080*o[2]))*f.tau)) + f.delta*(-0.279993296987100 + o[1]*(1.38997995694600 + o[1]*(-2.01899150235700 + o[16]*(-0.0082147637173963 - 0.47596035734923*o[17]))) + f.delta*(0.043984074473500 + o[1]*(-0.44476435428739 + o[1]*(0.90572070719733 + 0.70522450087967*o[19])) + f.delta*(f.delta*(-0.0221754008730960 + o[1]*(0.094260751665092 + 0.164362784479610*o[21]) + f.delta*(-0.0135033722413480*o[1] + f.delta*(-0.0148343453524720*o[22] + f.delta*(o[1]*(0.00057922953628084 + 0.0032308904703711*o[21]) + f.delta*(0.000080964802996215 - 0.000044923899061815*f.delta*o[22] - 0.000165576797950370*f.tau))))) + (0.107705126263320 + o[1]*(-0.32913623258954 - 0.50871062041158*o[20]))*f.tau))))) + 1.06580700285130*Modelica.Math.log(f.delta);
              f.fdelta := (1.06580700285130 + f.delta*(o[14] + f.delta*(0.76986920373342 + o[31] + f.delta*(-0.83997989096130 + o[1]*(4.1699398708380 + o[1]*(-6.0569745070710 + o[16]*(-0.0246442911521889 - 1.42788107204769*o[17]))) + f.delta*(0.175936297894000 + o[1]*(-1.77905741714956 + o[1]*(3.6228828287893 + 2.82089800351868*o[19])) + f.delta*(f.delta*(-0.133052405238576 + o[1]*(0.56556450999055 + 0.98617670687766*o[21]) + f.delta*(-0.094523605689436*o[1] + f.delta*(-0.118674762819776*o[22] + f.delta*(o[1]*(0.0052130658265276 + 0.0290780142333399*o[21]) + f.delta*(0.00080964802996215 - 0.00049416288967996*f.delta*o[22] - 0.00165576797950370*f.tau))))) + (0.53852563131660 + o[1]*(-1.64568116294770 - 2.54355310205790*o[20]))*f.tau))))))/f.delta;
              f.fdeltadelta := (-1.06580700285130 + o[32]*(0.76986920373342 + o[31] + f.delta*(-1.67995978192260 + o[1]*(8.3398797416760 + o[1]*(-12.1139490141420 + o[16]*(-0.049288582304378 - 2.85576214409538*o[17]))) + f.delta*(0.52780889368200 + o[1]*(-5.3371722514487 + o[1]*(10.8686484863680 + 8.4626940105560*o[19])) + f.delta*(f.delta*(-0.66526202619288 + o[1]*(2.82782254995276 + 4.9308835343883*o[21]) + f.delta*(-0.56714163413662*o[1] + f.delta*(-0.83072333973843*o[22] + f.delta*(o[1]*(0.041704526612220 + 0.232624113866719*o[21]) + f.delta*(0.0072868322696594 - 0.0049416288967996*f.delta*o[22] - 0.0149019118155333*f.tau))))) + (2.15410252526640 + o[1]*(-6.5827246517908 - 10.1742124082316*o[20]))*f.tau)))))/o[32];
              f.ftau := 20.9443969743070 + (-15.3735415757432 + o[3]*(18.3301634515678 + o[4]*(-28.0807811486200 + o[1]*(14.4640436358204 - 0.194503669468755*o[6]))))*f.tau + f.delta*(o[39] + f.delta*(f.tau*(-1.70429417648412 + o[2]*(29.3833689251262 + (-21.3518320798755 + o[15]*(0.86725181134139 + 3.2651861903201*o[2]))*f.tau)) + f.delta*((2.77995991389200 + o[1]*(-8.0759660094280 + o[16]*(-0.131436219478341 - 12.3749692910800*o[17])))*f.tau + f.delta*((-0.88952870857478 + o[1]*(3.6228828287893 + 18.3358370228714*o[19]))*f.tau + f.delta*(0.107705126263320 + o[1]*(-0.98740869776862 - 13.2264761307011*o[20]) + f.delta*((0.188521503330184 + 4.2734323964699*o[21])*f.tau + f.delta*(-0.0270067444826960*f.tau + f.delta*(-0.38569297916427*o[40] + f.delta*(f.delta*(-0.000165576797950370 - 0.00116802137560719*f.delta*o[40]) + (0.00115845907256168 + 0.084003152229649*o[21])*f.tau)))))))));
              f.ftautau := -15.3735415757432 + o[3]*(109.980980709407 + o[4]*(-252.727030337580 + o[1]*(159.104479994024 - 4.2790807283126*o[6]))) + f.delta*(-2.53086309554280 + o[2]*(-34.573223420043 + (185.894192367068 - 174.645121293971*o[1])*o[7]) + f.delta*(-1.70429417648412 + o[2]*(146.916844625631 + (-128.110992479253 + o[15]*(18.2122880381691 + 81.629654758002*o[2]))*f.tau) + f.delta*(2.77995991389200 + o[1]*(-24.2278980282840 + o[16]*(-1.97154329217511 - 309.374232277000*o[17])) + f.delta*(-0.88952870857478 + o[1]*(10.8686484863680 + 458.39592557179*o[19]) + f.delta*(f.delta*(0.188521503330184 + 106.835809911747*o[21] + f.delta*(-0.0270067444826960 + f.delta*(-9.6423244791068*o[21] + f.delta*(0.00115845907256168 + 2.10007880574121*o[21] - 0.0292005343901797*o[21]*o[32])))) + (-1.97481739553724 - 330.66190326753*o[20])*f.tau)))));
              f.fdeltatau := o[39] + f.delta*(f.tau*(-3.4085883529682 + o[2]*(58.766737850252 + (-42.703664159751 + o[15]*(1.73450362268278 + 6.5303723806402*o[2]))*f.tau)) + f.delta*((8.3398797416760 + o[1]*(-24.2278980282840 + o[16]*(-0.39430865843502 - 37.124907873240*o[17])))*f.tau + f.delta*((-3.5581148342991 + o[1]*(14.4915313151573 + 73.343348091486*o[19]))*f.tau + f.delta*(0.53852563131660 + o[1]*(-4.9370434888431 - 66.132380653505*o[20]) + f.delta*((1.13112901998110 + 25.6405943788192*o[21])*f.tau + f.delta*(-0.189047211378872*f.tau + f.delta*(-3.08554383331418*o[40] + f.delta*(f.delta*(-0.00165576797950370 - 0.0128482351316791*f.delta*o[40]) + (0.0104261316530551 + 0.75602837006684*o[21])*f.tau))))))));
            end f3;

            function g5 "Base function for region 5: g(p,T)"
              input SI.Pressure p "Pressure";
              input SI.Temperature T "Temperature (K)";
              output Modelica.Media.Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
            protected
              Real o[11] "Vector of auxiliary variables";
            algorithm
              assert(p > 0.0, "IF97 medium function g5 called with too low pressure\n" + "p = " + String(p) + " Pa <=  0.0 Pa");
              assert(p <= data.PLIMIT5, "IF97 medium function g5: input pressure (= " + String(p) + " Pa) is higher than 10 MPa in region 5");
              assert(T <= 2273.15, "IF97 medium function g5: input temperature (= " + String(T) + " K) is higher than limit of 2273.15K in region 5");
              g.p := p;
              g.T := T;
              g.R_s := data.RH2O;
              g.pi := p/data.PSTAR5;
              g.tau := data.TSTAR5/T;
              o[1] := g.tau*g.tau;
              o[2] := -0.0045942820899910*o[1];
              o[3] := 0.00217746787145710 + o[2];
              o[4] := o[3]*g.tau;
              o[5] := o[1]*g.tau;
              o[6] := o[1]*o[1];
              o[7] := o[6]*o[6];
              o[8] := o[7]*g.tau;
              o[9] := -7.9449656719138e-6*o[8];
              o[10] := g.pi*g.pi;
              o[11] := -0.0137828462699730*o[1];
              g.g := g.pi*(-0.000125631835895920 + o[4] + g.pi*(-3.9724828359569e-6*o[8] + 1.29192282897840e-7*o[5]*g.pi)) + (-0.0248051489334660 + g.tau*(0.36901534980333 + g.tau*(-3.11613182139250 + g.tau*(-13.1799836742010 + (6.8540841634434 - 0.32961626538917*g.tau)*g.tau + Modelica.Math.log(g.pi)))))/o[5];
              g.gpi := (1.0 + g.pi*(-0.000125631835895920 + o[4] + g.pi*(o[9] + 3.8757684869352e-7*o[5]*g.pi)))/g.pi;
              g.gpipi := (-1.00000000000000 + o[10]*(o[9] + 7.7515369738704e-7*o[5]*g.pi))/o[10];
              g.gtau := g.pi*(0.00217746787145710 + o[11] + g.pi*(-0.000035752345523612*o[7] + 3.8757684869352e-7*o[1]*g.pi)) + (0.074415446800398 + g.tau*(-0.73803069960666 + (3.11613182139250 + o[1]*(6.8540841634434 - 0.65923253077834*g.tau))*g.tau))/o[6];
              g.gtautau := (-0.297661787201592 + g.tau*(2.21409209881998 + (-6.2322636427850 - 0.65923253077834*o[5])*g.tau))/(o[6]*g.tau) + g.pi*(-0.0275656925399460*g.tau + g.pi*(-0.000286018764188897*o[1]*o[6]*g.tau + 7.7515369738704e-7*g.pi*g.tau));
              g.gtaupi := 0.00217746787145710 + o[11] + g.pi*(-0.000071504691047224*o[7] + 1.16273054608056e-6*o[1]*g.pi);
            end g5;

            function tph1 "Inverse function for region 1: T(p,h)"
              input SI.Pressure p "Pressure";
              input SI.SpecificEnthalpy h "Specific enthalpy";
              output SI.Temperature T "Temperature (K)";
            protected
              Real pi "Dimensionless pressure";
              Real eta1 "Dimensionless specific enthalpy";
              Real o[3] "Vector of auxiliary variables";
            algorithm
              assert(p > triple.ptriple, "IF97 medium function tph1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              pi := p/data.PSTAR2;
              eta1 := h/data.HSTAR1 + 1.0;
              o[1] := eta1*eta1;
              o[2] := o[1]*o[1];
              o[3] := o[2]*o[2];
              T := -238.724899245210 - 13.3917448726020*pi + eta1*(404.21188637945 + 43.211039183559*pi + eta1*(113.497468817180 - 54.010067170506*pi + eta1*(30.5358922039160*pi + eta1*(-6.5964749423638*pi + o[1]*(-5.8457616048039 + o[2]*(pi*(0.0093965400878363 + (-0.0000258586412820730 + 6.6456186191635e-8*pi)*pi) + o[2]*o[3]*(-0.000152854824131400 + o[1]*o[3]*(-1.08667076953770e-6 + pi*(1.15736475053400e-7 + pi*(-4.0644363084799e-9 + pi*(8.0670734103027e-11 + pi*(-9.3477771213947e-13 + (5.8265442020601e-15 - 1.50201859535030e-17*pi)*pi))))))))))));
            end tph1;

            function tph2 "Reverse function for region 2: T(p,h)"
              input SI.Pressure p "Pressure";
              input SI.SpecificEnthalpy h "Specific enthalpy";
              output SI.Temperature T "Temperature (K)";
            protected
              Real pi "Dimensionless pressure";
              Real pi2b "Dimensionless pressure";
              Real pi2c "Dimensionless pressure";
              Real eta "Dimensionless specific enthalpy";
              Real etabc "Dimensionless specific enthalpy";
              Real eta2a "Dimensionless specific enthalpy";
              Real eta2b "Dimensionless specific enthalpy";
              Real eta2c "Dimensionless specific enthalpy";
              Real o[8] "Vector of auxiliary variables";
            algorithm
              pi := p*data.IPSTAR;
              eta := h*data.IHSTAR;
              etabc := h*1.0e-3;
              if (pi < 4.0) then
                eta2a := eta - 2.1;
                o[1] := eta2a*eta2a;
                o[2] := o[1]*o[1];
                o[3] := pi*pi;
                o[4] := o[3]*o[3];
                o[5] := o[3]*pi;
                T := 1089.89523182880 + (1.84457493557900 - 0.0061707422868339*pi)*pi + eta2a*(849.51654495535 - 4.1792700549624*pi + eta2a*(-107.817480918260 + (6.2478196935812 - 0.310780466295830*pi)*pi + eta2a*(33.153654801263 - 17.3445631081140*pi + o[2]*(-7.4232016790248 + pi*(-200.581768620960 + 11.6708730771070*pi) + o[1]*(271.960654737960*pi + o[1]*(-455.11318285818*pi + eta2a*(1.38657242832260*o[4] + o[1]*o[2]*(3091.96886047550*pi + o[1]*(11.7650487243560 + o[2]*(-13551.3342407750*o[5] + o[2]*(-62.459855192507*o[3]*o[4]*pi + o[2]*(o[4]*(235988.325565140 + 7399.9835474766*pi) + o[1]*(19127.7292396600*o[3]*o[4] + o[1]*(o[3]*(1.28127984040460e8 - 551966.97030060*o[5]) + o[1]*(-9.8554909623276e8*o[3] + o[1]*(2.82245469730020e9*o[3] + o[1]*(o[3]*(-3.5948971410703e9 + 3.7154085996233e6*o[5]) + o[1]*pi*(252266.403578720 + pi*(1.72273499131970e9 + pi*(1.28487346646500e7 + (-1.31052365450540e7 - 415351.64835634*o[3])*pi))))))))))))))))))));
              elseif (pi < (0.12809002730136e-03*etabc - 0.67955786399241)*etabc + 0.90584278514723e3) then
                eta2b := eta - 2.6;
                pi2b := pi - 2.0;
                o[1] := pi2b*pi2b;
                o[2] := o[1]*pi2b;
                o[3] := o[1]*o[1];
                o[4] := eta2b*eta2b;
                o[5] := o[4]*o[4];
                o[6] := o[4]*o[5];
                o[7] := o[5]*o[5];
                T := 1489.50410795160 + 0.93747147377932*pi2b + eta2b*(743.07798314034 + o[2]*(0.000110328317899990 - 1.75652339694070e-18*o[1]*o[3]) + eta2b*(-97.708318797837 + pi2b*(3.3593118604916 + pi2b*(-0.0218107553247610 + pi2b*(0.000189552483879020 + (2.86402374774560e-7 - 8.1456365207833e-14*o[2])*pi2b))) + o[5]*(3.3809355601454*pi2b + o[4]*(-0.108297844036770*o[1] + o[5]*(2.47424647056740 + (0.168445396719040 + o[1]*(0.00308915411605370 - 0.0000107798573575120*pi2b))*pi2b + o[6]*(-0.63281320016026 + pi2b*(0.73875745236695 + (-0.046333324635812 + o[1]*(-0.000076462712454814 + 2.82172816350400e-7*pi2b))*pi2b) + o[6]*(1.13859521296580 + pi2b*(-0.47128737436186 + o[1]*(0.00135555045549490 + (0.0000140523928183160 + 1.27049022719450e-6*pi2b)*pi2b)) + o[5]*(-0.47811863648625 + (0.150202731397070 + o[2]*(-0.0000310838143314340 + o[1]*(-1.10301392389090e-8 - 2.51805456829620e-11*pi2b)))*pi2b + o[5]*o[7]*(0.0085208123431544 + pi2b*(-0.00217641142197500 + pi2b*(0.000071280351959551 + o[1]*(-1.03027382121030e-6 + (7.3803353468292e-8 + 8.6934156344163e-15*o[3])*pi2b))))))))))));
              else
                eta2c := eta - 1.8;
                pi2c := pi + 25.0;
                o[1] := pi2c*pi2c;
                o[2] := o[1]*o[1];
                o[3] := o[1]*o[2]*pi2c;
                o[4] := 1/o[3];
                o[5] := o[1]*o[2];
                o[6] := eta2c*eta2c;
                o[7] := o[2]*o[2];
                o[8] := o[6]*o[6];
                T := eta2c*((859777.22535580 + o[1]*(482.19755109255 + 1.12615974072300e-12*o[5]))/o[1] + eta2c*((-5.8340131851590e11 + (2.08255445631710e10 + 31081.0884227140*o[2])*pi2c)/o[5] + o[6]*(o[8]*(o[6]*(1.23245796908320e-7*o[5] + o[6]*(-1.16069211309840e-6*o[5] + o[8]*(0.0000278463670885540*o[5] + (-0.00059270038474176*o[5] + 0.00129185829918780*o[5]*o[6])*o[8]))) - 10.8429848800770*pi2c) + o[4]*(7.3263350902181e12 + o[7]*(3.7966001272486 + (-0.045364172676660 - 1.78049822406860e-11*o[2])*pi2c))))) + o[4]*(-3.2368398555242e12 + pi2c*(3.5825089945447e11 + pi2c*(-1.07830682174700e10 + o[1]*pi2c*(610747.83564516 + pi2c*(-25745.7236041700 + (1208.23158659360 + 1.45591156586980e-13*o[5])*pi2c)))));
              end if;
            end tph2;

            function tsat "Region 4 saturation temperature as a function of pressure"
              input SI.Pressure p "Pressure";
              output SI.Temperature t_sat "Temperature";
            protected
              Real pi "Dimensionless pressure";
              Real o[20] "Vector of auxiliary variables";
            algorithm
              assert(p > triple.ptriple, "IF97 medium function tsat called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              pi := min(p, data.PCRIT)*data.IPSTAR;
              o[1] := pi^0.25;
              o[2] := -3.2325550322333e6*o[1];
              o[3] := pi^0.5;
              o[4] := -724213.16703206*o[3];
              o[5] := 405113.40542057 + o[2] + o[4];
              o[6] := -17.0738469400920*o[1];
              o[7] := 14.9151086135300 + o[3] + o[6];
              o[8] := -4.0*o[5]*o[7];
              o[9] := 12020.8247024700*o[1];
              o[10] := 1167.05214527670*o[3];
              o[11] := -4823.2657361591 + o[10] + o[9];
              o[12] := o[11]*o[11];
              o[13] := o[12] + o[8];
              o[14] := o[13]^0.5;
              o[15] := -o[14];
              o[16] := -12020.8247024700*o[1];
              o[17] := -1167.05214527670*o[3];
              o[18] := 4823.2657361591 + o[15] + o[16] + o[17];
              o[19] := 1/o[18];
              o[20] := 2.0*o[19]*o[5];
              t_sat := 0.5*(650.17534844798 + o[20] - (-4.0*(-0.238555575678490 + 1300.35069689596*o[19]*o[5]) + (650.17534844798 + o[20])^2.0)^0.5);
              annotation(derivative = tsat_der);
            end tsat;

            function dtsatofp "Derivative of saturation temperature w.r.t. pressure"
              input SI.Pressure p "Pressure";
              output Real dtsat(unit = "K/Pa") "Derivative of T w.r.t. p";
            protected
              Real pi "Dimensionless pressure";
              Real o[49] "Vector of auxiliary variables";
            algorithm
              pi := max(Modelica.Constants.small, p*data.IPSTAR);
              o[1] := pi^0.75;
              o[2] := 1/o[1];
              o[3] := -4.268461735023*o[2];
              o[4] := sqrt(pi);
              o[5] := 1/o[4];
              o[6] := 0.5*o[5];
              o[7] := o[3] + o[6];
              o[8] := pi^0.25;
              o[9] := -3.2325550322333e6*o[8];
              o[10] := -724213.16703206*o[4];
              o[11] := 405113.40542057 + o[10] + o[9];
              o[12] := -4*o[11]*o[7];
              o[13] := -808138.758058325*o[2];
              o[14] := -362106.58351603*o[5];
              o[15] := o[13] + o[14];
              o[16] := -17.073846940092*o[8];
              o[17] := 14.91510861353 + o[16] + o[4];
              o[18] := -4*o[15]*o[17];
              o[19] := 3005.2061756175*o[2];
              o[20] := 583.52607263835*o[5];
              o[21] := o[19] + o[20];
              o[22] := 12020.82470247*o[8];
              o[23] := 1167.0521452767*o[4];
              o[24] := -4823.2657361591 + o[22] + o[23];
              o[25] := 2.0*o[21]*o[24];
              o[26] := o[12] + o[18] + o[25];
              o[27] := -4.0*o[11]*o[17];
              o[28] := o[24]*o[24];
              o[29] := o[27] + o[28];
              o[30] := sqrt(o[29]);
              o[31] := 1/o[30];
              o[32] := (-o[30]);
              o[33] := -12020.82470247*o[8];
              o[34] := -1167.0521452767*o[4];
              o[35] := 4823.2657361591 + o[32] + o[33] + o[34];
              o[36] := o[30];
              o[37] := -4823.2657361591 + o[22] + o[23] + o[36];
              o[38] := o[37]*o[37];
              o[39] := 1/o[38];
              o[40] := -1.72207339365771*o[30];
              o[41] := 21592.2055343628*o[8];
              o[42] := o[30]*o[8];
              o[43] := -8192.87114842946*o[4];
              o[44] := -0.510632954559659*o[30]*o[4];
              o[45] := -3100.02526152368*o[1];
              o[46] := pi;
              o[47] := 1295.95640782102*o[46];
              o[48] := 2862.09212505088 + o[40] + o[41] + o[42] + o[43] + o[44] + o[45] + o[47];
              o[49] := 1/(o[35]*o[35]);
              dtsat := data.IPSTAR*0.5*((2.0*o[15])/o[35] - 2.*o[11]*(-3005.2061756175*o[2] - 0.5*o[26]*o[31] - 583.52607263835*o[5])*o[49] - (20953.46356643991*(o[39]*(1295.95640782102 + 5398.05138359071*o[2] + 0.25*o[2]*o[30] - 0.861036696828853*o[26]*o[31] - 0.255316477279829*o[26]*o[31]*o[4] - 4096.43557421473*o[5] - 0.255316477279829*o[30]*o[5] - 2325.01894614276/o[8] + 0.5*o[26]*o[31]*o[8]) - 2.0*(o[19] + o[20] + 0.5*o[26]*o[31])*o[48]*o[37]^(-3)))/sqrt(o[39]*o[48]));
            end dtsatofp;

            function tsat_der "Derivative function for tsat"
              input SI.Pressure p "Pressure";
              input SI.PressureSlope der_p "Pressure derivative";
              output SI.TemperatureSlope der_tsat "Temperature derivative";
            protected
              Real dtp;
            algorithm
              dtp := dtsatofp(p);
              der_tsat := dtp*der_p;
            end tsat_der;

            function psat "Region 4 saturation pressure as a function of temperature"
              input SI.Temperature T "Temperature (K)";
              output SI.Pressure p_sat "Pressure";
            protected
              Real o[8] "Vector of auxiliary variables";
              Real Tlim = min(T, data.TCRIT);
            algorithm
              assert(T >= 273.16, "IF97 medium function psat: input temperature (= " + String(triple.Ttriple) + " K).\n" + "lower than the triple point temperature 273.16 K");
              o[1] := -650.17534844798 + Tlim;
              o[2] := 1/o[1];
              o[3] := -0.238555575678490*o[2];
              o[4] := o[3] + Tlim;
              o[5] := -4823.2657361591*o[4];
              o[6] := o[4]*o[4];
              o[7] := 14.9151086135300*o[6];
              o[8] := 405113.40542057 + o[5] + o[7];
              p_sat := 16.0e6*o[8]*o[8]*o[8]*o[8]*1/(3.2325550322333e6 - 12020.8247024700*o[4] + 17.0738469400920*o[6] + sqrt(-4.0*(-724213.16703206 + 1167.05214527670*o[4] + o[6])*o[8] + (-3.2325550322333e6 + 12020.8247024700*o[4] - 17.0738469400920*o[6])^2.0))^4.0;
              annotation(derivative = psat_der);
            end psat;

            function dptofT "Derivative of pressure w.r.t. temperature along the saturation pressure curve"
              input SI.Temperature T "Temperature (K)";
              output Real dpt(unit = "Pa/K") "Temperature derivative of pressure";
            protected
              Real o[31] "Vector of auxiliary variables";
              Real Tlim "Temperature limited to TCRIT";
            algorithm
              Tlim := min(T, data.TCRIT);
              o[1] := -650.17534844798 + Tlim;
              o[2] := 1/o[1];
              o[3] := -0.238555575678490*o[2];
              o[4] := o[3] + Tlim;
              o[5] := -4823.2657361591*o[4];
              o[6] := o[4]*o[4];
              o[7] := 14.9151086135300*o[6];
              o[8] := 405113.40542057 + o[5] + o[7];
              o[9] := o[8]*o[8];
              o[10] := o[9]*o[9];
              o[11] := o[1]*o[1];
              o[12] := 1/o[11];
              o[13] := 0.238555575678490*o[12];
              o[14] := 1.00000000000000 + o[13];
              o[15] := 12020.8247024700*o[4];
              o[16] := -17.0738469400920*o[6];
              o[17] := -3.2325550322333e6 + o[15] + o[16];
              o[18] := -4823.2657361591*o[14];
              o[19] := 29.8302172270600*o[14]*o[4];
              o[20] := o[18] + o[19];
              o[21] := 1167.05214527670*o[4];
              o[22] := -724213.16703206 + o[21] + o[6];
              o[23] := o[17]*o[17];
              o[24] := -4.0000000000000*o[22]*o[8];
              o[25] := o[23] + o[24];
              o[26] := sqrt(o[25]);
              o[27] := -12020.8247024700*o[4];
              o[28] := 17.0738469400920*o[6];
              o[29] := 3.2325550322333e6 + o[26] + o[27] + o[28];
              o[30] := o[29]*o[29];
              o[31] := o[30]*o[30];
              dpt := 1e6*((-64.0*o[10]*(-12020.8247024700*o[14] + 34.147693880184*o[14]*o[4] + (0.5*(-4.0*o[20]*o[22] + 2.00000000000000*o[17]*(12020.8247024700*o[14] - 34.147693880184*o[14]*o[4]) - 4.0*(1167.05214527670*o[14] + 2.0*o[14]*o[4])*o[8]))/o[26]))/(o[29]*o[31]) + (64.*o[20]*o[8]*o[9])/o[31]);
            end dptofT;

            function psat_der "Derivative function for psat"
              input SI.Temperature T "Temperature (K)";
              input SI.TemperatureSlope der_T "Temperature derivative";
              output SI.PressureSlope der_psat "Pressure derivative";
            protected
              Real dpt;
            algorithm
              dpt := dptofT(T);
              der_psat := dpt*der_T;
            end psat_der;

            function h3ab_p "Region 3 a b boundary for pressure/enthalpy"
              output SI.SpecificEnthalpy h "Enthalpy";
              input SI.Pressure p "Pressure";
            protected
              constant Real n[:] = {0.201464004206875e4, 0.374696550136983e1, -0.219921901054187e-1, 0.875131686009950e-4};
              constant SI.SpecificEnthalpy hstar = 1000 "Normalization enthalpy";
              constant SI.Pressure pstar = 1e6 "Normalization pressure";
              Real pi = p/pstar "Normalized specific pressure";
            algorithm
              h := (n[1] + n[2]*pi + n[3]*pi^2 + n[4]*pi^3)*hstar;
            end h3ab_p;

            function T3a_ph "Region 3 a: inverse function T(p,h)"
              input SI.Pressure p "Pressure";
              input SI.SpecificEnthalpy h "Specific enthalpy";
              output SI.Temperature T "Temperature";
            protected
              constant Real n[:] = {-0.133645667811215e-6, 0.455912656802978e-5, -0.146294640700979e-4, 0.639341312970080e-2, 0.372783927268847e3, -0.718654377460447e4, 0.573494752103400e6, -0.267569329111439e7, -0.334066283302614e-4, -0.245479214069597e-1, 0.478087847764996e2, 0.764664131818904e-5, 0.128350627676972e-2, 0.171219081377331e-1, -0.851007304583213e1, -0.136513461629781e-1, -0.384460997596657e-5, 0.337423807911655e-2, -0.551624873066791, 0.729202277107470, -0.992522757376041e-2, -0.119308831407288, 0.793929190615421, 0.454270731799386, 0.209998591259910, -0.642109823904738e-2, -0.235155868604540e-1, 0.252233108341612e-2, -0.764885133368119e-2, 0.136176427574291e-1, -0.133027883575669e-1};
              constant Real I[:] = {-12, -12, -12, -12, -12, -12, -12, -12, -10, -10, -10, -8, -8, -8, -8, -5, -3, -2, -2, -2, -1, -1, 0, 0, 1, 3, 3, 4, 4, 10, 12};
              constant Real J[:] = {0, 1, 2, 6, 14, 16, 20, 22, 1, 5, 12, 0, 2, 4, 10, 2, 0, 1, 3, 4, 0, 2, 0, 1, 1, 0, 1, 0, 3, 4, 5};
              constant SI.SpecificEnthalpy hstar = 2300e3 "Normalization enthalpy";
              constant SI.Pressure pstar = 100e6 "Normalization pressure";
              constant SI.Temperature Tstar = 760 "Normalization temperature";
              Real pi = p/pstar "Normalized specific pressure";
              Real eta = h/hstar "Normalized specific enthalpy";
            algorithm
              T := sum(n[i]*(pi + 0.240)^I[i]*(eta - 0.615)^J[i] for i in 1:31)*Tstar;
            end T3a_ph;

            function T3b_ph "Region 3 b: inverse function T(p,h)"
              input SI.Pressure p "Pressure";
              input SI.SpecificEnthalpy h "Specific enthalpy";
              output SI.Temperature T "Temperature";
            protected
              constant Real n[:] = {0.323254573644920e-4, -0.127575556587181e-3, -0.475851877356068e-3, 0.156183014181602e-2, 0.105724860113781, -0.858514221132534e2, 0.724140095480911e3, 0.296475810273257e-2, -0.592721983365988e-2, -0.126305422818666e-1, -0.115716196364853, 0.849000969739595e2, -0.108602260086615e-1, 0.154304475328851e-1, 0.750455441524466e-1, 0.252520973612982e-1, -0.602507901232996e-1, -0.307622221350501e1, -0.574011959864879e-1, 0.503471360939849e1, -0.925081888584834, 0.391733882917546e1, -0.773146007130190e2, 0.949308762098587e4, -0.141043719679409e7, 0.849166230819026e7, 0.861095729446704, 0.323346442811720, 0.873281936020439, -0.436653048526683, 0.286596714529479, -0.131778331276228, 0.676682064330275e-2};
              constant Real I[:] = {-12, -12, -10, -10, -10, -10, -10, -8, -8, -8, -8, -8, -6, -6, -6, -4, -4, -3, -2, -2, -1, -1, -1, -1, -1, -1, 0, 0, 1, 3, 5, 6, 8};
              constant Real J[:] = {0, 1, 0, 1, 5, 10, 12, 0, 1, 2, 4, 10, 0, 1, 2, 0, 1, 5, 0, 4, 2, 4, 6, 10, 14, 16, 0, 2, 1, 1, 1, 1, 1};
              constant SI.Temperature Tstar = 860 "Normalization temperature";
              constant SI.Pressure pstar = 100e6 "Normalization pressure";
              constant SI.SpecificEnthalpy hstar = 2800e3 "Normalization enthalpy";
              Real pi = p/pstar "Normalized specific pressure";
              Real eta = h/hstar "Normalized specific enthalpy";
            algorithm
              T := sum(n[i]*(pi + 0.298)^I[i]*(eta - 0.720)^J[i] for i in 1:33)*Tstar;
            end T3b_ph;

            function v3a_ph "Region 3 a: inverse function v(p,h)"
              input SI.Pressure p "Pressure";
              input SI.SpecificEnthalpy h "Specific enthalpy";
              output SI.SpecificVolume v "Specific volume";
            protected
              constant Real n[:] = {0.529944062966028e-2, -0.170099690234461, 0.111323814312927e2, -0.217898123145125e4, -0.506061827980875e-3, 0.556495239685324, -0.943672726094016e1, -0.297856807561527, 0.939353943717186e2, 0.192944939465981e-1, 0.421740664704763, -0.368914126282330e7, -0.737566847600639e-2, -0.354753242424366, -0.199768169338727e1, 0.115456297059049e1, 0.568366875815960e4, 0.808169540124668e-2, 0.172416341519307, 0.104270175292927e1, -0.297691372792847, 0.560394465163593, 0.275234661176914, -0.148347894866012, -0.651142513478515e-1, -0.292468715386302e1, 0.664876096952665e-1, 0.352335014263844e1, -0.146340792313332e-1, -0.224503486668184e1, 0.110533464706142e1, -0.408757344495612e-1};
              constant Real I[:] = {-12, -12, -12, -12, -10, -10, -10, -8, -8, -6, -6, -6, -4, -4, -3, -2, -2, -1, -1, -1, -1, 0, 0, 1, 1, 1, 2, 2, 3, 4, 5, 8};
              constant Real J[:] = {6, 8, 12, 18, 4, 7, 10, 5, 12, 3, 4, 22, 2, 3, 7, 3, 16, 0, 1, 2, 3, 0, 1, 0, 1, 2, 0, 2, 0, 2, 2, 2};
              constant SI.Volume vstar = 0.0028 "Normalization temperature";
              constant SI.Pressure pstar = 100e6 "Normalization pressure";
              constant SI.SpecificEnthalpy hstar = 2100e3 "Normalization enthalpy";
              Real pi = p/pstar "Normalized specific pressure";
              Real eta = h/hstar "Normalized specific enthalpy";
            algorithm
              v := sum(n[i]*(pi + 0.128)^I[i]*(eta - 0.727)^J[i] for i in 1:32)*vstar;
            end v3a_ph;

            function v3b_ph "Region 3 b: inverse function v(p,h)"
              input SI.Pressure p "Pressure";
              input SI.SpecificEnthalpy h "Specific enthalpy";
              output SI.SpecificVolume v "Specific volume";
            protected
              constant Real n[:] = {-0.225196934336318e-8, 0.140674363313486e-7, 0.233784085280560e-5, -0.331833715229001e-4, 0.107956778514318e-2, -0.271382067378863, 0.107202262490333e1, -0.853821329075382, -0.215214194340526e-4, 0.769656088222730e-3, -0.431136580433864e-2, 0.453342167309331, -0.507749535873652, -0.100475154528389e3, -0.219201924648793, -0.321087965668917e1, 0.607567815637771e3, 0.557686450685932e-3, 0.187499040029550, 0.905368030448107e-2, 0.285417173048685, 0.329924030996098e-1, 0.239897419685483, 0.482754995951394e1, -0.118035753702231e2, 0.169490044091791, -0.179967222507787e-1, 0.371810116332674e-1, -0.536288335065096e-1, 0.160697101092520e1};
              constant Real I[:] = {-12, -12, -8, -8, -8, -8, -8, -8, -6, -6, -6, -6, -6, -6, -4, -4, -4, -3, -3, -2, -2, -1, -1, -1, -1, 0, 1, 1, 2, 2};
              constant Real J[:] = {0, 1, 0, 1, 3, 6, 7, 8, 0, 1, 2, 5, 6, 10, 3, 6, 10, 0, 2, 1, 2, 0, 1, 4, 5, 0, 0, 1, 2, 6};
              constant SI.Volume vstar = 0.0088 "Normalization temperature";
              constant SI.Pressure pstar = 100e6 "Normalization pressure";
              constant SI.SpecificEnthalpy hstar = 2800e3 "Normalization enthalpy";
              Real pi = p/pstar "Normalized specific pressure";
              Real eta = h/hstar "Normalized specific enthalpy";
            algorithm
              v := sum(n[i]*(pi + 0.0661)^I[i]*(eta - 0.720)^J[i] for i in 1:30)*vstar;
            end v3b_ph;
          end Basic;

          package Transport "Transport properties for water according to IAPWS/IF97"
            function visc_dTp "Dynamic viscosity eta(d,T,p), industrial formulation"
              input SI.Density d "Density";
              input SI.Temperature T "Temperature (K)";
              input SI.Pressure p "Pressure (only needed for region of validity)";
              input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known (unused)";
              input Boolean checkLimits = true "Check if inputs d,T,P are in region of validity";
              output SI.DynamicViscosity eta "Dynamic viscosity";
            protected
              constant Real n0 = 1.0 "Viscosity coefficient";
              constant Real n1 = 0.978197 "Viscosity coefficient";
              constant Real n2 = 0.579829 "Viscosity coefficient";
              constant Real n3 = -0.202354 "Viscosity coefficient";
              constant Real nn[42] = array(0.5132047, 0.3205656, 0.0, 0.0, -0.7782567, 0.1885447, 0.2151778, 0.7317883, 1.241044, 1.476783, 0.0, 0.0, -0.2818107, -1.070786, -1.263184, 0.0, 0.0, 0.0, 0.1778064, 0.460504, 0.2340379, -0.4924179, 0.0, 0.0, -0.0417661, 0.0, 0.0, 0.1600435, 0.0, 0.0, 0.0, -0.01578386, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.003629481, 0.0, 0.0) "Viscosity coefficients";
              constant SI.Density rhostar = 317.763 "Scaling density";
              constant SI.DynamicViscosity etastar = 55.071e-6 "Scaling viscosity";
              constant SI.Temperature tstar = 647.226 "Scaling temperature";
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
              delta := d/rhostar;
              if checkLimits then
                assert(d > triple.dvtriple, "IF97 medium function visc_dTp for viscosity called with too low density\n" + "d = " + String(d) + " <= " + String(triple.dvtriple) + " (triple point density)");
                assert((p <= 500e6 and (Tc >= 0.0 and Tc <= 150)) or (p <= 350e6 and (Tc > 150.0 and Tc <= 600)) or (p <= 300e6 and (Tc > 600.0 and Tc <= 900)), "IF97 medium function visc_dTp: viscosity computed outside the range\n" + "of validity of the IF97 formulation: p = " + String(p) + " Pa, Tc = " + String(Tc) + " K");
              else
              end if;
              deltam1 := delta - 1.0;
              tau := tstar/T;
              taum1 := tau - 1.0;
              Psi0 := 1/(n0 + (n1 + (n2 + n3*tau)*tau)*tau)/(sqrt(tau));
              Psi1 := 0.0;
              tfun := 1.0;
              for i in 1:6 loop
                if (i <> 1) then
                  tfun := tfun*taum1;
                else
                end if;
                rhofun := 1.;
                for j in 0:6 loop
                  if (j <> 0) then
                    rhofun := rhofun*deltam1;
                  else
                  end if;
                  Psi1 := Psi1 + nn[i + j*6]*tfun*rhofun;
                end for;
              end for;
              eta := etastar*Psi0*Modelica.Math.exp(delta*Psi1);
            end visc_dTp;
          end Transport;

          package Isentropic "Functions for calculating the isentropic enthalpy from pressure p and specific entropy s"
            function hofpT1 "Intermediate function for isentropic specific enthalpy in region 1"
              input SI.Pressure p "Pressure";
              input SI.Temperature T "Temperature (K)";
              output SI.SpecificEnthalpy h "Specific enthalpy";
            protected
              Real o[13] "Vector of auxiliary variables";
              Real pi1 "Dimensionless pressure";
              Real tau "Dimensionless temperature";
              Real tau1 "Dimensionless temperature";
            algorithm
              tau := data.TSTAR1/T;
              pi1 := 7.1 - p/data.PSTAR1;
              assert(p > triple.ptriple, "IF97 medium function hofpT1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              tau1 := -1.222 + tau;
              o[1] := tau1*tau1;
              o[2] := o[1]*tau1;
              o[3] := o[1]*o[1];
              o[4] := o[3]*o[3];
              o[5] := o[1]*o[4];
              o[6] := o[1]*o[3];
              o[7] := o[3]*tau1;
              o[8] := o[3]*o[4];
              o[9] := pi1*pi1;
              o[10] := o[9]*o[9];
              o[11] := o[10]*o[10];
              o[12] := o[4]*o[4];
              o[13] := o[12]*o[12];
              h := data.RH2O*T*tau*(pi1*((-0.00254871721114236 + o[1]*(0.00424944110961118 + (0.018990068218419 + (-0.021841717175414 - 0.00015851507390979*o[1])*o[1])*o[6]))/o[5] + pi1*((0.00141552963219801 + o[3]*(0.000047661393906987 + o[1]*(-0.0000132425535992538 - 1.2358149370591e-14*o[1]*o[3]*o[4])))/o[3] + pi1*((0.000126718579380216 - 5.11230768720618e-9*o[5])/o[7] + pi1*((0.000011212640954 + o[2]*(1.30342445791202e-6 - 1.4341729937924e-12*o[8]))/o[6] + pi1*(o[9]*pi1*((1.40077319158051e-8 + 1.04549227383804e-9*o[7])/o[8] + o[10]*o[11]*pi1*(1.9941018075704e-17/(o[1]*o[12]*o[3]*o[4]) + o[9]*(-4.48827542684151e-19/o[13] + o[10]*o[9]*(pi1*(4.65957282962769e-22/(o[13]*o[4]) + pi1*((3.83502057899078e-24*pi1)/(o[1]*o[13]*o[4]) - 7.2912378325616e-23/(o[13]*o[4]*tau1))) - 1.00075970318621e-21/(o[1]*o[13]*o[3]*tau1))))) + 3.24135974880936e-6/(o[4]*tau1)))))) + (-0.29265942426334 + tau1*(0.84548187169114 + o[1]*(3.3855169168385 + tau1*(-1.91583926775744 + tau1*(0.47316115539684 + (-0.066465668798004 + 0.0040607314991784*tau1)*tau1)))))/o[2]);
            end hofpT1;

            function hofpT2 "Intermediate function for isentropic specific enthalpy in region 2"
              input SI.Pressure p "Pressure";
              input SI.Temperature T "Temperature (K)";
              output SI.SpecificEnthalpy h "Specific enthalpy";
            protected
              Real o[16] "Vector of auxiliary variables";
              Real pi "Dimensionless pressure";
              Real tau "Dimensionless temperature";
              Real tau2 "Dimensionless temperature";
            algorithm
              assert(p > triple.ptriple, "IF97 medium function hofpT2 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
              pi := p/data.PSTAR2;
              tau := data.TSTAR2/T;
              tau2 := -0.5 + tau;
              o[1] := tau*tau;
              o[2] := o[1]*o[1];
              o[3] := tau2*tau2;
              o[4] := o[3]*tau2;
              o[5] := o[3]*o[3];
              o[6] := o[5]*o[5];
              o[7] := o[6]*o[6];
              o[8] := o[5]*o[6]*o[7]*tau2;
              o[9] := o[3]*o[5];
              o[10] := o[5]*o[6]*tau2;
              o[11] := o[3]*o[7]*tau2;
              o[12] := o[3]*o[5]*o[6];
              o[13] := o[5]*o[6]*o[7];
              o[14] := pi*pi;
              o[15] := o[14]*o[14];
              o[16] := o[7]*o[7];
              h := data.RH2O*T*tau*((0.0280439559151 + tau*(-0.2858109552582 + tau*(1.2213149471784 + tau*(-2.848163942888 + tau*(4.38395111945 + o[1]*(10.08665568018 + (-0.5681726521544 + 0.06380539059921*tau)*tau))))))/(o[1]*o[2]) + pi*(-0.017834862292358 + tau2*(-0.09199202739273 + (-0.172743777250296 - 0.30195167236758*o[4])*tau2) + pi*(-0.000033032641670203 + (-0.0003789797503263 + o[3]*(-0.015757110897342 + o[4]*(-0.306581069554011 - 0.000960283724907132*o[8])))*tau2 + pi*(4.3870667284435e-7 + o[3]*(-0.00009683303171571 + o[4]*(-0.0090203547252888 - 1.42338887469272*o[8])) + pi*(-7.8847309559367e-10 + (2.558143570457e-8 + 1.44676118155521e-6*tau2)*tau2 + pi*(0.0000160454534363627*o[9] + pi*((-5.0144299353183e-11 + o[10]*(-0.033874355714168 - 836.35096769364*o[11]))*o[3] + pi*((-0.0000138839897890111 - 0.973671060893475*o[12])*o[3]*o[6] + pi*((9.0049690883672e-11 - 296.320827232793*o[13])*o[3]*o[5]*tau2 + pi*(2.57526266427144e-7*o[5]*o[6] + pi*(o[4]*(4.1627860840696e-19 + (-1.0234747095929e-12 - 1.40254511313154e-8*o[5])*o[9]) + o[14]*o[15]*(o[13]*(-2.34560435076256e-9 + 5.3465159397045*o[5]*o[7]*tau2) + o[14]*(-19.1874828272775*o[16]*o[6]*o[7] + o[14]*(o[11]*(1.78371690710842e-23 + (1.07202609066812e-11 - 0.000201611844951398*o[10])*o[3]*o[5]*o[6]*tau2) + pi*(-1.24017662339842e-24*o[5]*o[7] + pi*(0.000200482822351322*o[16]*o[5]*o[7] + pi*(-4.97975748452559e-14*o[16]*o[3]*o[5] + o[6]*o[7]*(1.90027787547159e-27 + o[12]*(2.21658861403112e-15 - 0.0000547344301999018*o[3]*o[7]))*pi*tau2)))))))))))))))));
            end hofpT2;
          end Isentropic;

          package Inverses "Efficient inverses for selected pairs of variables"
            function fixdT "Region limits for inverse iteration in region 3"
              input SI.Density din "Density";
              input SI.Temperature Tin "Temperature";
              output SI.Density dout "Density";
              output SI.Temperature Tout "Temperature";
            protected
              SI.Temperature Tmin "Approximation of minimum temperature";
              SI.Temperature Tmax "Approximation of maximum temperature";
            algorithm
              if (din > 765.0) then
                dout := 765.0;
              elseif (din < 110.0) then
                dout := 110.0;
              else
                dout := din;
              end if;
              if (dout < 390.0) then
                Tmax := 554.3557377 + dout*0.809344262;
              else
                Tmax := 1116.85 - dout*0.632948717;
              end if;
              if (dout < data.DCRIT) then
                Tmin := data.TCRIT*(1.0 - (dout - data.DCRIT)*(dout - data.DCRIT)/1.0e6);
              else
                Tmin := data.TCRIT*(1.0 - (dout - data.DCRIT)*(dout - data.DCRIT)/1.44e6);
              end if;
              if (Tin < Tmin) then
                Tout := Tmin;
              elseif (Tin > Tmax) then
                Tout := Tmax;
              else
                Tout := Tin;
              end if;
            end fixdT;

            function dofp13 "Density at the boundary between regions 1 and 3"
              input SI.Pressure p "Pressure";
              output SI.Density d "Density";
            protected
              Real p2 "Auxiliary variable";
              Real o[3] "Vector of auxiliary variables";
            algorithm
              p2 := 7.1 - 6.04960677555959e-8*p;
              o[1] := p2*p2;
              o[2] := o[1]*o[1];
              o[3] := o[2]*o[2];
              d := 57.4756752485113/(0.0737412153522555 + p2*(0.00145092247736023 + p2*(0.000102697173772229 + p2*(0.0000114683182476084 + p2*(1.99080616601101e-6 + o[1]*p2*(1.13217858826367e-8 + o[2]*o[3]*p2*(1.35549330686006e-17 + o[1]*(-3.11228834832975e-19 + o[1]*o[2]*(-7.02987180039442e-22 + p2*(3.29199117056433e-22 + (-5.17859076694812e-23 + 2.73712834080283e-24*p2)*p2))))))))));
            end dofp13;

            function dofp23 "Density at the boundary between regions 2 and 3"
              input SI.Pressure p "Pressure";
              output SI.Density d "Density";
            protected
              SI.Temperature T;
              Real o[13] "Vector of auxiliary variables";
              Real taug "Auxiliary variable";
              Real pi "Dimensionless pressure";
              Real gpi23 "Derivative of g w.r.t. pi on the boundary between regions 2 and 3";
            algorithm
              pi := p/data.PSTAR2;
              T := 572.54459862746 + 31.3220101646784*(-13.91883977887 + pi)^0.5;
              o[1] := (-13.91883977887 + pi)^0.5;
              taug := -0.5 + 540.0/(572.54459862746 + 31.3220101646784*o[1]);
              o[2] := taug*taug;
              o[3] := o[2]*taug;
              o[4] := o[2]*o[2];
              o[5] := o[4]*o[4];
              o[6] := o[5]*o[5];
              o[7] := o[4]*o[5]*o[6]*taug;
              o[8] := o[4]*o[5]*taug;
              o[9] := o[2]*o[4]*o[5];
              o[10] := pi*pi;
              o[11] := o[10]*o[10];
              o[12] := o[4]*o[6]*taug;
              o[13] := o[6]*o[6];
              gpi23 := (1.0 + pi*(-0.0017731742473213 + taug*(-0.017834862292358 + taug*(-0.045996013696365 + (-0.057581259083432 - 0.05032527872793*o[3])*taug)) + pi*(taug*(-0.000066065283340406 + (-0.0003789797503263 + o[2]*(-0.007878555448671 + o[3]*(-0.087594591301146 - 0.000053349095828174*o[7])))*taug) + pi*(6.1445213076927e-8 + (1.31612001853305e-6 + o[2]*(-0.00009683303171571 + o[3]*(-0.0045101773626444 - 0.122004760687947*o[7])))*taug + pi*(taug*(-3.15389238237468e-9 + (5.116287140914e-8 + 1.92901490874028e-6*taug)*taug) + pi*(0.0000114610381688305*o[2]*o[4]*taug + pi*(o[3]*(-1.00288598706366e-10 + o[8]*(-0.012702883392813 - 143.374451604624*o[2]*o[6]*taug)) + pi*(-4.1341695026989e-17 + o[2]*o[5]*(-8.8352662293707e-6 - 0.272627897050173*o[9])*taug + pi*(o[5]*(9.0049690883672e-11 - 65.8490727183984*o[4]*o[5]*o[6]) + pi*(1.78287415218792e-7*o[8] + pi*(o[4]*(1.0406965210174e-18 + o[2]*(-1.0234747095929e-12 - 1.0018179379511e-8*o[4])*o[4]) + o[10]*o[11]*((-1.29412653835176e-9 + 1.71088510070544*o[12])*o[7] + o[10]*(-6.05920510335078*o[13]*o[5]*o[6]*taug + o[10]*(o[4]*o[6]*(1.78371690710842e-23 + o[2]*o[4]*o[5]*(6.1258633752464e-12 - 0.000084004935396416*o[8])*taug) + pi*(-1.24017662339842e-24*o[12] + pi*(0.0000832192847496054*o[13]*o[4]*o[6]*taug + pi*(o[2]*o[5]*o[6]*(1.75410265428146e-27 + (1.32995316841867e-15 - 0.0000226487297378904*o[2]*o[6])*o[9])*pi - 2.93678005497663e-14*o[13]*o[2]*o[4]*taug)))))))))))))))))/pi;
              d := p/(data.RH2O*T*pi*gpi23);
            end dofp23;

            function dofpt3 "Inverse iteration in region 3: (d) = f(p,T)"
              input SI.Pressure p "Pressure";
              input SI.Temperature T "Temperature (K)";
              input SI.Pressure delp "Iteration converged if (p-pre(p) < delp)";
              output SI.Density d "Density";
              output Integer error = 0 "Error flag: iteration failed if different from 0";
            protected
              SI.Density dguess "Guess density";
              Integer i = 0 "Loop counter";
              Real dp "Pressure difference";
              SI.Density deld "Density step";
              Modelica.Media.Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
              Modelica.Media.Common.NewtonDerivatives_pT nDerivs "Derivatives needed in Newton iteration";
              Boolean found = false "Flag for iteration success";
              Boolean supercritical "Flag, true for supercritical states";
              Boolean liquid "Flag, true for liquid states";
              SI.Density dmin "Lower density limit";
              SI.Density dmax "Upper density limit";
              SI.Temperature Tmax "Maximum temperature";
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
                dguess := dmax - (T - data.TLIMIT1)/(data.TLIMIT1 - Tmax)*(dmax - dmin);
              else
                liquid := T < Basic.tsat(p);
                if liquid then
                  dmax := dofp13(p);
                  dmin := Regions.rhol_p_R4b(p);
                  dguess := 1.1*Regions.rhol_T(T) "Guess: 10 percent more than on the phase boundary for same T";
                else
                  dmax := Regions.rhov_p_R4b(p);
                  dmin := dofp23(p);
                  dguess := 0.9*Regions.rhov_T(T) "Guess: 10% less than on the phase boundary for same T";
                end if;
              end if;
              while ((i < IterationData.IMAX) and not found) loop
                d := dguess;
                f := Basic.f3(d, T);
                nDerivs := Modelica.Media.Common.Helmholtz_pT(f);
                dp := nDerivs.p - p;
                if (abs(dp/p) <= delp) then
                  found := true;
                else
                end if;
                deld := dp/nDerivs.pd*damping;
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

            function dtofph3 "Inverse iteration in region 3: (d,T) = f(p,h)"
              input SI.Pressure p "Pressure";
              input SI.SpecificEnthalpy h "Specific enthalpy";
              input SI.Pressure delp "Iteration accuracy";
              input SI.SpecificEnthalpy delh "Iteration accuracy";
              output SI.Density d "Density";
              output SI.Temperature T "Temperature (K)";
              output Integer error "Error flag: iteration failed if different from 0";
            protected
              SI.Temperature Tguess "Initial temperature";
              SI.Density dguess "Initial density";
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
                subregion := if h < (Regions.hl_p(p) + 10.0) then 1 else if h > (Regions.hv_p(p) - 10.0) then 2 else 0;
                assert(subregion <> 0, "Inverse iteration of dt from ph called in 2 phase region: this can not work");
              else
                subregion := if h < Basic.h3ab_p(p) then 1 else 2;
              end if;
              T := if subregion == 1 then Basic.T3a_ph(p, h) else Basic.T3b_ph(p, h);
              d := if subregion == 1 then 1/Basic.v3a_ph(p, h) else 1/Basic.v3b_ph(p, h);
              i := 0;
              error := 0;
              while ((i < IterationData.IMAX) and not found) loop
                f := Basic.f3(d, T);
                nDerivs := Modelica.Media.Common.Helmholtz_ph(f);
                dh := nDerivs.h - h;
                dp := nDerivs.p - p;
                if ((abs(dh/h) <= delh) and (abs(dp/p) <= delp)) then
                  found := true;
                else
                end if;
                det := nDerivs.ht*nDerivs.pd - nDerivs.pt*nDerivs.hd;
                delt := (nDerivs.pd*dh - nDerivs.hd*dp)/det;
                deld := (nDerivs.ht*dp - nDerivs.pt*dh)/det;
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

            function pofdt125 "Inverse iteration in region 1,2 and 5: p = g(d,T)"
              input SI.Density d "Density";
              input SI.Temperature T "Temperature (K)";
              input SI.Pressure reldd "Relative iteration accuracy of density";
              input Integer region "Region in IAPWS/IF97 in which inverse should be calculated";
              output SI.Pressure p "Pressure";
              output Integer error "Error flag: iteration failed if different from 0";
            protected
              Integer i "Counter for while-loop";
              Modelica.Media.Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
              Boolean found "Flag if iteration has been successful";
              Real dd "Difference between density for guessed p and the current density";
              Real delp "Step in p in Newton-iteration";
              Real relerr "Relative error in d";
              SI.Pressure pguess1 = 1.0e6 "Initial pressure guess in region 1";
              SI.Pressure pguess2 "Initial pressure guess in region 2";
              constant SI.Pressure pguess5 = 0.5e6 "Initial pressure guess in region 5";
            algorithm
              i := 0;
              error := 0;
              pguess2 := 42800*d;
              found := false;
              if region == 1 then
                p := pguess1;
              elseif region == 2 then
                p := pguess2;
              else
                p := pguess5;
              end if;
              while ((i < IterationData.IMAX) and not found) loop
                if region == 1 then
                  g := Basic.g1(p, T);
                elseif region == 2 then
                  g := Basic.g2(p, T);
                else
                  g := Basic.g5(p, T);
                end if;
                dd := p/(data.RH2O*T*g.pi*g.gpi) - d;
                relerr := dd/d;
                if (abs(relerr) < reldd) then
                  found := true;
                else
                end if;
                delp := dd*(-p*p/(d*d*data.RH2O*T*g.pi*g.pi*g.gpipi));
                p := p - delp;
                i := i + 1;
                if not found then
                  if p < triple.ptriple then
                    p := 2.0*triple.ptriple;
                  else
                  end if;
                  if p > data.PLIMIT1 then
                    p := 0.95*data.PLIMIT1;
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

            function tofph5 "Inverse iteration in region 5: (p,T) = f(p,h)"
              input SI.Pressure p "Pressure";
              input SI.SpecificEnthalpy h "Specific enthalpy";
              input SI.SpecificEnthalpy reldh "Iteration accuracy";
              output SI.Temperature T "Temperature (K)";
              output Integer error "Error flag: iteration failed if different from 0";
            protected
              Modelica.Media.Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
              SI.SpecificEnthalpy proh "H for current guess in T";
              constant SI.Temperature Tguess = 1500 "Initial temperature";
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
              while ((i < IterationData.IMAX) and not found) loop
                g := Basic.g5(p, T);
                proh := data.RH2O*T*g.tau*g.gtau;
                dh := proh - h;
                relerr := dh/h;
                if (abs(relerr) < reldh) then
                  found := true;
                else
                end if;
                dT := dh/(-data.RH2O*g.tau*g.tau*g.gtautau);
                T := T - dT;
                i := i + 1;
              end while;
              if not found then
                error := 1;
              else
              end if;
              assert(error <> 1, "Error in inverse function tofph5: iteration failed");
            end tofph5;
          end Inverses;

          package TwoPhase "Steam properties in the two-phase region and on the phase boundaries" end TwoPhase;
        end BaseIF97;

        function waterBaseProp_ph "Intermediate property record for water"
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase = 0 "Phase: 2 for two-phase, 1 for one phase, 0 if unknown";
          input Integer region = 0 "If 0, do region computation, otherwise assume the region is this input";
          output Common.IF97BaseTwoPhase aux "Auxiliary record";
        protected
          Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          Integer error "Error flag for inverse iterations";
          SI.SpecificEnthalpy h_liq "Liquid specific enthalpy";
          SI.Density d_liq "Liquid density";
          SI.SpecificEnthalpy h_vap "Vapour specific enthalpy";
          SI.Density d_vap "Vapour density";
          Common.PhaseBoundaryProperties liq "Phase boundary property record";
          Common.PhaseBoundaryProperties vap "Phase boundary property record";
          Common.GibbsDerivs gl "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          Common.GibbsDerivs gv "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          Modelica.Media.Common.HelmholtzDerivs fl "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          Modelica.Media.Common.HelmholtzDerivs fv "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          SI.Temperature t1 "Temperature at phase boundary, using inverse from region 1";
          SI.Temperature t2 "Temperature at phase boundary, using inverse from region 2";
        algorithm
          aux.region := if region == 0 then (if phase == 2 then 4 else BaseIF97.Regions.region_ph(p = p, h = h, phase = phase)) else region;
          aux.phase := if phase <> 0 then phase else if aux.region == 4 then 2 else 1;
          aux.p := max(p, 611.657);
          aux.h := max(h, 1e3);
          aux.R_s := BaseIF97.data.RH2O;
          aux.vt := 0.0 "Initialized in case it is not needed";
          aux.vp := 0.0 "Initialized in case it is not needed";
          if (aux.region == 1) then
            aux.T := BaseIF97.Basic.tph1(aux.p, aux.h);
            g := BaseIF97.Basic.g1(p, aux.T);
            aux.s := aux.R_s*(g.tau*g.gtau - g.g);
            aux.rho := p/(aux.R_s*aux.T*g.pi*g.gpi);
            aux.vt := aux.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
            aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
            aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
            aux.vp := aux.R_s*aux.T/(p*p)*g.pi*g.pi*g.gpipi;
            aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
            aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi));
            aux.x := 0.0;
            aux.dpT := -aux.vt/aux.vp;
          elseif (aux.region == 2) then
            aux.T := BaseIF97.Basic.tph2(aux.p, aux.h);
            g := BaseIF97.Basic.g2(p, aux.T);
            aux.s := aux.R_s*(g.tau*g.gtau - g.g);
            aux.rho := p/(aux.R_s*aux.T*g.pi*g.gpi);
            aux.vt := aux.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
            aux.vp := aux.R_s*aux.T/(p*p)*g.pi*g.pi*g.gpipi;
            aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
            aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
            aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
            aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi));
            aux.x := 1.0;
            aux.dpT := -aux.vt/aux.vp;
          elseif (aux.region == 3) then
            (aux.rho, aux.T, error) := BaseIF97.Inverses.dtofph3(p = aux.p, h = aux.h, delp = 1.0e-7, delh = 1.0e-6);
            f := BaseIF97.Basic.f3(aux.rho, aux.T);
            aux.h := aux.R_s*aux.T*(f.tau*f.ftau + f.delta*f.fdelta);
            aux.s := aux.R_s*(f.tau*f.ftau - f.f);
            aux.pd := aux.R_s*aux.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
            aux.pt := aux.R_s*aux.rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
            aux.cv := abs(aux.R_s*(-f.tau*f.tau*f.ftautau)) "Can be close to neg. infinity near critical point";
            aux.cp := (aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)/(aux.rho*aux.rho*aux.pd);
            aux.x := 0.0;
            aux.dpT := aux.pt;
          elseif (aux.region == 4) then
            h_liq := hl_p(p);
            h_vap := hv_p(p);
            aux.x := if (h_vap <> h_liq) then (h - h_liq)/(h_vap - h_liq) else 1.0;
            if p < BaseIF97.data.PLIMIT4A then
              t1 := BaseIF97.Basic.tph1(aux.p, h_liq);
              t2 := BaseIF97.Basic.tph2(aux.p, h_vap);
              gl := BaseIF97.Basic.g1(aux.p, t1);
              gv := BaseIF97.Basic.g2(aux.p, t2);
              liq := Common.gibbsToBoundaryProps(gl);
              vap := Common.gibbsToBoundaryProps(gv);
              aux.T := t1 + aux.x*(t2 - t1);
            else
              aux.T := BaseIF97.Basic.tsat(aux.p);
              d_liq := rhol_T(aux.T);
              d_vap := rhov_T(aux.T);
              fl := BaseIF97.Basic.f3(d_liq, aux.T);
              fv := BaseIF97.Basic.f3(d_vap, aux.T);
              liq := Common.helmholtzToBoundaryProps(fl);
              vap := Common.helmholtzToBoundaryProps(fv);
            end if;
            aux.dpT := if (liq.d <> vap.d) then (vap.s - liq.s)*liq.d*vap.d/(liq.d - vap.d) else BaseIF97.Basic.dptofT(aux.T);
            aux.s := liq.s + aux.x*(vap.s - liq.s);
            aux.rho := liq.d*vap.d/(vap.d + aux.x*(liq.d - vap.d));
            aux.cv := Common.cv2Phase(liq, vap, aux.x, aux.T, p);
            aux.cp := liq.cp + aux.x*(vap.cp - liq.cp);
            aux.pt := liq.pt + aux.x*(vap.pt - liq.pt);
            aux.pd := liq.pd + aux.x*(vap.pd - liq.pd);
          elseif (aux.region == 5) then
            (aux.T, error) := BaseIF97.Inverses.tofph5(p = aux.p, h = aux.h, reldh = 1.0e-7);
            assert(error == 0, "Error in inverse iteration of steam tables");
            g := BaseIF97.Basic.g5(aux.p, aux.T);
            aux.s := aux.R_s*(g.tau*g.gtau - g.g);
            aux.rho := p/(aux.R_s*aux.T*g.pi*g.gpi);
            aux.vt := aux.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
            aux.vp := aux.R_s*aux.T/(p*p)*g.pi*g.pi*g.gpipi;
            aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
            aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
            aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
            aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi));
            aux.dpT := -aux.vt/aux.vp;
          else
            assert(false, "Error in region computation of IF97 steam tables" + "(p = " + String(p) + ", h = " + String(h) + ")");
          end if;
        end waterBaseProp_ph;

        function rho_props_ph "Density as function of pressure and specific enthalpy"
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase properties "Auxiliary record";
          output SI.Density rho "Density";
        algorithm
          rho := properties.rho;
          annotation(derivative(noDerivative = properties) = rho_ph_der, Inline = false, LateInline = true);
        end rho_props_ph;

        function rho_ph "Density as function of pressure and specific enthalpy"
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output SI.Density rho "Density";
        algorithm
          rho := rho_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
          annotation(Inline = true);
        end rho_ph;

        function rho_ph_der "Derivative function of rho_ph"
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase properties "Auxiliary record";
          input Real p_der "Derivative of pressure";
          input Real h_der "Derivative of specific enthalpy";
          output Real rho_der "Derivative of density";
        algorithm
          if (properties.region == 4) then
            rho_der := (properties.rho*(properties.rho*properties.cv/properties.dpT + 1.0)/(properties.dpT*properties.T))*p_der + (-properties.rho*properties.rho/(properties.dpT*properties.T))*h_der;
          elseif (properties.region == 3) then
            rho_der := ((properties.rho*(properties.cv*properties.rho + properties.pt))/(properties.rho*properties.rho*properties.pd*properties.cv + properties.T*properties.pt*properties.pt))*p_der + (-properties.rho*properties.rho*properties.pt/(properties.rho*properties.rho*properties.pd*properties.cv + properties.T*properties.pt*properties.pt))*h_der;
          else
            rho_der := (-properties.rho*properties.rho*(properties.vp*properties.cp - properties.vt/properties.rho + properties.T*properties.vt*properties.vt)/properties.cp)*p_der + (-properties.rho*properties.rho*properties.vt/(properties.cp))*h_der;
          end if;
        end rho_ph_der;

        function T_props_ph "Temperature as function of pressure and specific enthalpy"
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase properties "Auxiliary record";
          output SI.Temperature T "Temperature";
        algorithm
          T := properties.T;
          annotation(derivative(noDerivative = properties) = T_ph_der, Inline = false, LateInline = true);
        end T_props_ph;

        function T_ph "Temperature as function of pressure and specific enthalpy"
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output SI.Temperature T "Temperature";
        algorithm
          T := T_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
          annotation(Inline = true);
        end T_ph;

        function T_ph_der "Derivative function of T_ph"
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase properties "Auxiliary record";
          input Real p_der "Derivative of pressure";
          input Real h_der "Derivative of specific enthalpy";
          output Real T_der "Derivative of temperature";
        algorithm
          if (properties.region == 4) then
            T_der := 1/properties.dpT*p_der;
          elseif (properties.region == 3) then
            T_der := ((-properties.rho*properties.pd + properties.T*properties.pt)/(properties.rho*properties.rho*properties.pd*properties.cv + properties.T*properties.pt*properties.pt))*p_der + ((properties.rho*properties.rho*properties.pd)/(properties.rho*properties.rho*properties.pd*properties.cv + properties.T*properties.pt*properties.pt))*h_der;
          else
            T_der := ((-1/properties.rho + properties.T*properties.vt)/properties.cp)*p_der + (1/properties.cp)*h_der;
          end if;
        end T_ph_der;

        function s_props_ph "Specific entropy as function of pressure and specific enthalpy"
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase properties "Auxiliary record";
          output SI.SpecificEntropy s "Specific entropy";
        algorithm
          s := properties.s;
          annotation(derivative(noDerivative = properties) = s_ph_der, Inline = false, LateInline = true);
        end s_props_ph;

        function s_ph "Specific entropy as function of pressure and specific enthalpy"
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output SI.SpecificEntropy s "Specific entropy";
        algorithm
          s := s_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
          annotation(Inline = true);
        end s_ph;

        function s_ph_der "Specific entropy as function of pressure and specific enthalpy"
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase properties "Auxiliary record";
          input Real p_der "Derivative of pressure";
          input Real h_der "Derivative of specific enthalpy";
          output Real s_der "Derivative of entropy";
        algorithm
          s_der := -1/(properties.rho*properties.T)*p_der + 1/properties.T*h_der;
          annotation(Inline = true);
        end s_ph_der;

        function cv_props_ph "Specific heat capacity at constant volume as function of pressure and specific enthalpy"
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.SpecificHeatCapacity cv "Specific heat capacity";
        algorithm
          cv := aux.cv;
          annotation(Inline = false, LateInline = true);
        end cv_props_ph;

        function cv_ph "Specific heat capacity at constant volume as function of pressure and specific enthalpy"
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output SI.SpecificHeatCapacity cv "Specific heat capacity";
        algorithm
          cv := cv_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
          annotation(Inline = true);
        end cv_ph;

        function cp_props_ph "Specific heat capacity at constant pressure as function of pressure and specific enthalpy"
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.SpecificHeatCapacity cp "Specific heat capacity";
        algorithm
          cp := aux.cp;
          annotation(Inline = false, LateInline = true);
        end cp_props_ph;

        function cp_ph "Specific heat capacity at constant pressure as function of pressure and specific enthalpy"
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output SI.SpecificHeatCapacity cp "Specific heat capacity";
        algorithm
          cp := cp_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
          annotation(Inline = true);
        end cp_ph;

        function beta_props_ph "Isobaric expansion coefficient as function of pressure and specific enthalpy"
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.RelativePressureCoefficient beta "Isobaric expansion coefficient";
        algorithm
          beta := if aux.region == 3 or aux.region == 4 then aux.pt/(aux.rho*aux.pd) else aux.vt*aux.rho;
          annotation(Inline = false, LateInline = true);
        end beta_props_ph;

        function beta_ph "Isobaric expansion coefficient as function of pressure and specific enthalpy"
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output SI.RelativePressureCoefficient beta "Isobaric expansion coefficient";
        algorithm
          beta := beta_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
          annotation(Inline = true);
        end beta_ph;

        function velocityOfSound_props_ph "Speed of sound as function of pressure and specific enthalpy"
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.Velocity v_sound "Speed of sound";
        algorithm
          v_sound := if aux.region == 3 then sqrt(max(0, (aux.pd*aux.rho*aux.rho*aux.cv + aux.pt*aux.pt*aux.T)/(aux.rho*aux.rho*aux.cv))) else if aux.region == 4 then sqrt(max(0, 1/((aux.rho*(aux.rho*aux.cv/aux.dpT + 1.0)/(aux.dpT*aux.T)) - 1/aux.rho*aux.rho*aux.rho/(aux.dpT*aux.T)))) else sqrt(max(0, -aux.cp/(aux.rho*aux.rho*(aux.vp*aux.cp + aux.vt*aux.vt*aux.T))));
          annotation(Inline = false, LateInline = true);
        end velocityOfSound_props_ph;

        function velocityOfSound_ph
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output SI.Velocity v_sound "Speed of sound";
        algorithm
          v_sound := velocityOfSound_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
          annotation(Inline = true);
        end velocityOfSound_ph;

        function isentropicExponent_props_ph "Isentropic exponent as function of pressure and specific enthalpy"
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output Real gamma "Isentropic exponent";
        algorithm
          gamma := if aux.region == 3 then 1/(aux.rho*p)*((aux.pd*aux.cv*aux.rho*aux.rho + aux.pt*aux.pt*aux.T)/(aux.cv)) else if aux.region == 4 then 1/(aux.rho*p)*aux.dpT*aux.dpT*aux.T/aux.cv else -1/(aux.rho*aux.p)*aux.cp/(aux.vp*aux.cp + aux.vt*aux.vt*aux.T);
          annotation(Inline = false, LateInline = true);
        end isentropicExponent_props_ph;

        function isentropicExponent_ph "Isentropic exponent as function of pressure and specific enthalpy"
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output Real gamma "Isentropic exponent";
        algorithm
          gamma := isentropicExponent_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
          annotation(Inline = false, LateInline = true);
        end isentropicExponent_ph;

        function ddph_props "Density derivative by pressure"
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.DerDensityByPressure ddph "Density derivative by pressure";
        algorithm
          ddph := if aux.region == 3 then ((aux.rho*(aux.cv*aux.rho + aux.pt))/(aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)) else if aux.region == 4 then (aux.rho*(aux.rho*aux.cv/aux.dpT + 1.0)/(aux.dpT*aux.T)) else (-aux.rho*aux.rho*(aux.vp*aux.cp - aux.vt/aux.rho + aux.T*aux.vt*aux.vt)/aux.cp);
          annotation(Inline = false, LateInline = true);
        end ddph_props;

        function ddph "Density derivative by pressure"
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output SI.DerDensityByPressure ddph "Density derivative by pressure";
        algorithm
          ddph := ddph_props(p, h, waterBaseProp_ph(p, h, phase, region));
          annotation(Inline = true);
        end ddph;

        function waterBaseProp_pT "Intermediate property record for water (p and T preferred states)"
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Integer region = 0 "If 0, do region computation, otherwise assume the region is this input";
          output Common.IF97BaseTwoPhase aux "Auxiliary record";
        protected
          Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          Integer error "Error flag for inverse iterations";
        algorithm
          aux.phase := 1;
          aux.region := if region == 0 then BaseIF97.Regions.region_pT(p = p, T = T) else region;
          aux.R_s := BaseIF97.data.RH2O;
          aux.p := p;
          aux.T := T;
          aux.vt := 0.0 "Initialized in case it is not needed";
          aux.vp := 0.0 "Initialized in case it is not needed";
          if (aux.region == 1) then
            g := BaseIF97.Basic.g1(p, T);
            aux.h := aux.R_s*aux.T*g.tau*g.gtau;
            aux.s := aux.R_s*(g.tau*g.gtau - g.g);
            aux.rho := p/(aux.R_s*T*g.pi*g.gpi);
            aux.vt := aux.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
            aux.vp := aux.R_s*T/(p*p)*g.pi*g.pi*g.gpipi;
            aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
            aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi));
            aux.x := 0.0;
            aux.dpT := -aux.vt/aux.vp;
            aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
            aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
          elseif (aux.region == 2) then
            g := BaseIF97.Basic.g2(p, T);
            aux.h := aux.R_s*aux.T*g.tau*g.gtau;
            aux.s := aux.R_s*(g.tau*g.gtau - g.g);
            aux.rho := p/(aux.R_s*T*g.pi*g.gpi);
            aux.vt := aux.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
            aux.vp := aux.R_s*T/(p*p)*g.pi*g.pi*g.gpipi;
            aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
            aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
            aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
            aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi));
            aux.x := 1.0;
            aux.dpT := -aux.vt/aux.vp;
          elseif (aux.region == 3) then
            (aux.rho, error) := BaseIF97.Inverses.dofpt3(p = p, T = T, delp = 1.0e-7);
            f := BaseIF97.Basic.f3(aux.rho, T);
            aux.h := aux.R_s*T*(f.tau*f.ftau + f.delta*f.fdelta);
            aux.s := aux.R_s*(f.tau*f.ftau - f.f);
            aux.pd := aux.R_s*T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
            aux.pt := aux.R_s*aux.rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
            aux.cv := aux.R_s*(-f.tau*f.tau*f.ftautau);
            aux.x := 0.0;
            aux.dpT := aux.pt;
          elseif (aux.region == 5) then
            g := BaseIF97.Basic.g5(p, T);
            aux.h := aux.R_s*aux.T*g.tau*g.gtau;
            aux.s := aux.R_s*(g.tau*g.gtau - g.g);
            aux.rho := p/(aux.R_s*T*g.pi*g.gpi);
            aux.vt := aux.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
            aux.vp := aux.R_s*T/(p*p)*g.pi*g.pi*g.gpipi;
            aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
            aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
            aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
            aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi));
            aux.x := 1.0;
            aux.dpT := -aux.vt/aux.vp;
          else
            assert(false, "Error in region computation of IF97 steam tables" + "(p = " + String(p) + ", T = " + String(T) + ")");
          end if;
        end waterBaseProp_pT;

        function rho_props_pT "Density as function or pressure and temperature"
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.Density rho "Density";
        algorithm
          rho := aux.rho;
          annotation(derivative(noDerivative = aux) = rho_pT_der, Inline = false, LateInline = true);
        end rho_props_pT;

        function rho_pT "Density as function or pressure and temperature"
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output SI.Density rho "Density";
        algorithm
          rho := rho_props_pT(p, T, waterBaseProp_pT(p, T, region));
          annotation(Inline = true);
        end rho_pT;

        function h_props_pT "Specific enthalpy as function or pressure and temperature"
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := aux.h;
          annotation(derivative(noDerivative = aux) = h_pT_der, Inline = false, LateInline = true);
        end h_props_pT;

        function h_pT "Specific enthalpy as function or pressure and temperature"
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output SI.SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := h_props_pT(p, T, waterBaseProp_pT(p, T, region));
          annotation(Inline = true);
        end h_pT;

        function h_pT_der "Derivative function of h_pT"
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          input Real p_der "Derivative of pressure";
          input Real T_der "Derivative of temperature";
          output Real h_der "Derivative of specific enthalpy";
        algorithm
          if (aux.region == 3) then
            h_der := ((-aux.rho*aux.pd + T*aux.pt)/(aux.rho*aux.rho*aux.pd))*p_der + ((aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)/(aux.rho*aux.rho*aux.pd))*T_der;
          else
            h_der := (1/aux.rho - aux.T*aux.vt)*p_der + aux.cp*T_der;
          end if;
        end h_pT_der;

        function rho_pT_der "Derivative function of rho_pT"
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          input Real p_der "Derivative of pressure";
          input Real T_der "Derivative of temperature";
          output Real rho_der "Derivative of density";
        algorithm
          if (aux.region == 3) then
            rho_der := (1/aux.pd)*p_der - (aux.pt/aux.pd)*T_der;
          else
            rho_der := (-aux.rho*aux.rho*aux.vp)*p_der + (-aux.rho*aux.rho*aux.vt)*T_der;
          end if;
        end rho_pT_der;

        function s_props_pT "Specific entropy as function of pressure and temperature"
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.SpecificEntropy s "Specific entropy";
        algorithm
          s := aux.s;
          annotation(Inline = false, LateInline = true);
        end s_props_pT;

        function s_pT "Temperature as function of pressure and temperature"
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output SI.SpecificEntropy s "Specific entropy";
        algorithm
          s := s_props_pT(p, T, waterBaseProp_pT(p, T, region));
          annotation(Inline = true);
        end s_pT;

        function cv_props_pT "Specific heat capacity at constant volume as function of pressure and temperature"
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.SpecificHeatCapacity cv "Specific heat capacity";
        algorithm
          cv := aux.cv;
          annotation(Inline = false, LateInline = true);
        end cv_props_pT;

        function cv_pT "Specific heat capacity at constant volume as function of pressure and temperature"
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output SI.SpecificHeatCapacity cv "Specific heat capacity";
        algorithm
          cv := cv_props_pT(p, T, waterBaseProp_pT(p, T, region));
          annotation(Inline = true);
        end cv_pT;

        function cp_props_pT "Specific heat capacity at constant pressure as function of pressure and temperature"
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.SpecificHeatCapacity cp "Specific heat capacity";
        algorithm
          cp := if aux.region == 3 then (aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)/(aux.rho*aux.rho*aux.pd) else aux.cp;
          annotation(Inline = false, LateInline = true);
        end cp_props_pT;

        function cp_pT "Specific heat capacity at constant pressure as function of pressure and temperature"
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output SI.SpecificHeatCapacity cp "Specific heat capacity";
        algorithm
          cp := cp_props_pT(p, T, waterBaseProp_pT(p, T, region));
          annotation(Inline = true);
        end cp_pT;

        function beta_props_pT "Isobaric expansion coefficient as function of pressure and temperature"
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.RelativePressureCoefficient beta "Isobaric expansion coefficient";
        algorithm
          beta := if aux.region == 3 then aux.pt/(aux.rho*aux.pd) else aux.vt*aux.rho;
          annotation(Inline = false, LateInline = true);
        end beta_props_pT;

        function beta_pT "Isobaric expansion coefficient as function of pressure and temperature"
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output SI.RelativePressureCoefficient beta "Isobaric expansion coefficient";
        algorithm
          beta := beta_props_pT(p, T, waterBaseProp_pT(p, T, region));
          annotation(Inline = true);
        end beta_pT;

        function velocityOfSound_props_pT "Speed of sound as function of pressure and temperature"
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.Velocity v_sound "Speed of sound";
        algorithm
          v_sound := if aux.region == 3 then sqrt(max(0, (aux.pd*aux.rho*aux.rho*aux.cv + aux.pt*aux.pt*aux.T)/(aux.rho*aux.rho*aux.cv))) else sqrt(max(0, -aux.cp/(aux.rho*aux.rho*(aux.vp*aux.cp + aux.vt*aux.vt*aux.T))));
          annotation(Inline = false, LateInline = true);
        end velocityOfSound_props_pT;

        function velocityOfSound_pT "Speed of sound as function of pressure and temperature"
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output SI.Velocity v_sound "Speed of sound";
        algorithm
          v_sound := velocityOfSound_props_pT(p, T, waterBaseProp_pT(p, T, region));
          annotation(Inline = true);
        end velocityOfSound_pT;

        function isentropicExponent_props_pT "Isentropic exponent as function of pressure and temperature"
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output Real gamma "Isentropic exponent";
        algorithm
          gamma := if aux.region == 3 then 1/(aux.rho*p)*((aux.pd*aux.cv*aux.rho*aux.rho + aux.pt*aux.pt*aux.T)/(aux.cv)) else -1/(aux.rho*aux.p)*aux.cp/(aux.vp*aux.cp + aux.vt*aux.vt*aux.T);
          annotation(Inline = false, LateInline = true);
        end isentropicExponent_props_pT;

        function isentropicExponent_pT "Isentropic exponent as function of pressure and temperature"
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output Real gamma "Isentropic exponent";
        algorithm
          gamma := isentropicExponent_props_pT(p, T, waterBaseProp_pT(p, T, region));
          annotation(Inline = false, LateInline = true);
        end isentropicExponent_pT;

        function waterBaseProp_dT "Intermediate property record for water (d and T preferred states)"
          input SI.Density rho "Density";
          input SI.Temperature T "Temperature";
          input Integer phase = 0 "Phase: 2 for two-phase, 1 for one phase, 0 if unknown";
          input Integer region = 0 "If 0, do region computation, otherwise assume the region is this input";
          output Common.IF97BaseTwoPhase aux "Auxiliary record";
        protected
          SI.SpecificEnthalpy h_liq "Liquid specific enthalpy";
          SI.Density d_liq "Liquid density";
          SI.SpecificEnthalpy h_vap "Vapour specific enthalpy";
          SI.Density d_vap "Vapour density";
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
          aux.region := if region == 0 then (if phase == 2 then 4 else BaseIF97.Regions.region_dT(d = rho, T = T, phase = phase)) else region;
          aux.phase := if aux.region == 4 then 2 else 1;
          aux.R_s := BaseIF97.data.RH2O;
          aux.rho := rho;
          aux.T := T;
          aux.vt := 0.0 "Initialized in case it is not needed";
          aux.vp := 0.0 "Initialized in case it is not needed";
          if (aux.region == 1) then
            (aux.p, error) := BaseIF97.Inverses.pofdt125(d = rho, T = T, reldd = 1.0e-8, region = 1);
            g := BaseIF97.Basic.g1(aux.p, T);
            aux.h := aux.R_s*aux.T*g.tau*g.gtau;
            aux.s := aux.R_s*(g.tau*g.gtau - g.g);
            aux.rho := aux.p/(aux.R_s*T*g.pi*g.gpi);
            aux.vt := aux.R_s/aux.p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
            aux.vp := aux.R_s*T/(aux.p*aux.p)*g.pi*g.pi*g.gpipi;
            aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
            aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
            aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
            aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi));
            aux.x := 0.0;
          elseif (aux.region == 2) then
            (aux.p, error) := BaseIF97.Inverses.pofdt125(d = rho, T = T, reldd = 1.0e-8, region = 2);
            g := BaseIF97.Basic.g2(aux.p, T);
            aux.h := aux.R_s*aux.T*g.tau*g.gtau;
            aux.s := aux.R_s*(g.tau*g.gtau - g.g);
            aux.rho := aux.p/(aux.R_s*T*g.pi*g.gpi);
            aux.vt := aux.R_s/aux.p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
            aux.vp := aux.R_s*T/(aux.p*aux.p)*g.pi*g.pi*g.gpipi;
            aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
            aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
            aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
            aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi));
            aux.x := 1.0;
          elseif (aux.region == 3) then
            f := BaseIF97.Basic.f3(rho, T);
            aux.p := aux.R_s*rho*T*f.delta*f.fdelta;
            aux.h := aux.R_s*T*(f.tau*f.ftau + f.delta*f.fdelta);
            aux.s := aux.R_s*(f.tau*f.ftau - f.f);
            aux.pd := aux.R_s*T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
            aux.pt := aux.R_s*rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
            aux.cv := aux.R_s*(-f.tau*f.tau*f.ftautau);
            aux.cp := (aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)/(aux.rho*aux.rho*aux.pd);
            aux.x := 0.0;
          elseif (aux.region == 4) then
            aux.p := BaseIF97.Basic.psat(T);
            d_liq := rhol_T(T);
            d_vap := rhov_T(T);
            h_liq := hl_p(aux.p);
            h_vap := hv_p(aux.p);
            aux.x := if (d_vap <> d_liq) then (1/rho - 1/d_liq)/(1/d_vap - 1/d_liq) else 1.0;
            aux.h := h_liq + aux.x*(h_vap - h_liq);
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
            aux.dpT := if (liq.d <> vap.d) then (vap.s - liq.s)*liq.d*vap.d/(liq.d - vap.d) else BaseIF97.Basic.dptofT(aux.T);
            aux.s := liq.s + aux.x*(vap.s - liq.s);
            aux.cv := Common.cv2Phase(liq, vap, aux.x, aux.T, aux.p);
            aux.cp := liq.cp + aux.x*(vap.cp - liq.cp);
            aux.pt := liq.pt + aux.x*(vap.pt - liq.pt);
            aux.pd := liq.pd + aux.x*(vap.pd - liq.pd);
          elseif (aux.region == 5) then
            (aux.p, error) := BaseIF97.Inverses.pofdt125(d = rho, T = T, reldd = 1.0e-8, region = 5);
            g := BaseIF97.Basic.g2(aux.p, T);
            aux.h := aux.R_s*aux.T*g.tau*g.gtau;
            aux.s := aux.R_s*(g.tau*g.gtau - g.g);
            aux.rho := aux.p/(aux.R_s*T*g.pi*g.gpi);
            aux.vt := aux.R_s/aux.p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
            aux.vp := aux.R_s*T/(aux.p*aux.p)*g.pi*g.pi*g.gpipi;
            aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
            aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
            aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
            aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi));
          else
            assert(false, "Error in region computation of IF97 steam tables" + "(rho = " + String(rho) + ", T = " + String(T) + ")");
          end if;
        end waterBaseProp_dT;

        function h_props_dT "Specific enthalpy as function of density and temperature"
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := aux.h;
          annotation(derivative(noDerivative = aux) = h_dT_der, Inline = false, LateInline = true);
        end h_props_dT;

        function h_dT "Specific enthalpy as function of density and temperature"
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output SI.SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := h_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
          annotation(Inline = true);
        end h_dT;

        function h_dT_der "Derivative function of h_dT"
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          input Real d_der "Derivative of density";
          input Real T_der "Derivative of temperature";
          output Real h_der "Derivative of specific enthalpy";
        algorithm
          if (aux.region == 3) then
            h_der := ((-d*aux.pd + T*aux.pt)/(d*d))*d_der + ((aux.cv*d + aux.pt)/d)*T_der;
          elseif (aux.region == 4) then
            h_der := T*aux.dpT/(d*d)*d_der + ((aux.cv*d + aux.dpT)/d)*T_der;
          else
            h_der := (-(-1/d + T*aux.vt)/(d*d*aux.vp))*d_der + ((aux.vp*aux.cp - aux.vt/d + T*aux.vt*aux.vt)/aux.vp)*T_der;
          end if;
        end h_dT_der;

        function p_props_dT "Pressure as function of density and temperature"
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.Pressure p "Pressure";
        algorithm
          p := aux.p;
          annotation(derivative(noDerivative = aux) = p_dT_der, Inline = false, LateInline = true);
        end p_props_dT;

        function p_dT "Pressure as function of density and temperature"
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output SI.Pressure p "Pressure";
        algorithm
          p := p_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
          annotation(Inline = true);
        end p_dT;

        function p_dT_der "Derivative function of p_dT"
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          input Real d_der "Derivative of density";
          input Real T_der "Derivative of temperature";
          output Real p_der "Derivative of pressure";
        algorithm
          if (aux.region == 3) then
            p_der := aux.pd*d_der + aux.pt*T_der;
          elseif (aux.region == 4) then
            p_der := aux.dpT*T_der;
          else
            p_der := (-1/(d*d*aux.vp))*d_der + (-aux.vt/aux.vp)*T_der;
          end if;
        end p_dT_der;

        function s_props_dT "Specific entropy as function of density and temperature"
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.SpecificEntropy s "Specific entropy";
        algorithm
          s := aux.s;
          annotation(Inline = false, LateInline = true);
        end s_props_dT;

        function s_dT "Temperature as function of density and temperature"
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output SI.SpecificEntropy s "Specific entropy";
        algorithm
          s := s_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
          annotation(Inline = true);
        end s_dT;

        function cv_props_dT "Specific heat capacity at constant volume as function of density and temperature"
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.SpecificHeatCapacity cv "Specific heat capacity";
        algorithm
          cv := aux.cv;
          annotation(Inline = false, LateInline = true);
        end cv_props_dT;

        function cv_dT "Specific heat capacity at constant volume as function of density and temperature"
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output SI.SpecificHeatCapacity cv "Specific heat capacity";
        algorithm
          cv := cv_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
          annotation(Inline = true);
        end cv_dT;

        function cp_props_dT "Specific heat capacity at constant pressure as function of density and temperature"
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.SpecificHeatCapacity cp "Specific heat capacity";
        algorithm
          cp := aux.cp;
          annotation(Inline = false, LateInline = true);
        end cp_props_dT;

        function cp_dT "Specific heat capacity at constant pressure as function of density and temperature"
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output SI.SpecificHeatCapacity cp "Specific heat capacity";
        algorithm
          cp := cp_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
          annotation(Inline = true);
        end cp_dT;

        function beta_props_dT "Isobaric expansion coefficient as function of density and temperature"
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.RelativePressureCoefficient beta "Isobaric expansion coefficient";
        algorithm
          beta := if aux.region == 3 or aux.region == 4 then aux.pt/(aux.rho*aux.pd) else aux.vt*aux.rho;
          annotation(Inline = false, LateInline = true);
        end beta_props_dT;

        function beta_dT "Isobaric expansion coefficient as function of density and temperature"
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output SI.RelativePressureCoefficient beta "Isobaric expansion coefficient";
        algorithm
          beta := beta_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
          annotation(Inline = true);
        end beta_dT;

        function velocityOfSound_props_dT "Speed of sound as function of density and temperature"
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.Velocity v_sound "Speed of sound";
        algorithm
          v_sound := if aux.region == 3 then sqrt(max(0, ((aux.pd*aux.rho*aux.rho*aux.cv + aux.pt*aux.pt*aux.T)/(aux.rho*aux.rho*aux.cv)))) else if aux.region == 4 then sqrt(max(0, 1/((aux.rho*(aux.rho*aux.cv/aux.dpT + 1.0)/(aux.dpT*aux.T)) - 1/aux.rho*aux.rho*aux.rho/(aux.dpT*aux.T)))) else sqrt(max(0, -aux.cp/(aux.rho*aux.rho*(aux.vp*aux.cp + aux.vt*aux.vt*aux.T))));
          annotation(Inline = false, LateInline = true);
        end velocityOfSound_props_dT;

        function velocityOfSound_dT "Speed of sound as function of density and temperature"
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
          output SI.Velocity v_sound "Speed of sound";
        algorithm
          v_sound := velocityOfSound_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
          annotation(Inline = true);
        end velocityOfSound_dT;

        function isentropicExponent_props_dT "Isentropic exponent as function of density and temperature"
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output Real gamma "Isentropic exponent";
        algorithm
          gamma := if aux.region == 3 then 1/(aux.rho*aux.p)*((aux.pd*aux.cv*aux.rho*aux.rho + aux.pt*aux.pt*aux.T)/(aux.cv)) else if aux.region == 4 then 1/(aux.rho*aux.p)*aux.dpT*aux.dpT*aux.T/aux.cv else -1/(aux.rho*aux.p)*aux.cp/(aux.vp*aux.cp + aux.vt*aux.vt*aux.T);
          annotation(Inline = false, LateInline = true);
        end isentropicExponent_props_dT;

        function isentropicExponent_dT "Isentropic exponent as function of density and temperature"
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
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
        function rhol_p = BaseIF97.Regions.rhol_p "Compute the saturated liquid d(p)";
        function rhov_p = BaseIF97.Regions.rhov_p "Compute the saturated vapour d(p)";
        function dynamicViscosity = BaseIF97.Transport.visc_dTp "Compute eta(d,T) in the one-phase region";
      end IF97_Utilities;
    end Water;
  end Media;

  package Thermal "Library of thermal system components to model heat transfer and simple thermo-fluid pipe flow"
    import Modelica.Units.SI;

    package HeatTransfer "Library of 1-dimensional heat transfer with lumped elements"
      package Examples "Example models to demonstrate the usage of package Modelica.Thermal.HeatTransfer"
        package Utilities "Utility classes used by the Example models" end Utilities;
      end Examples;

      package Components "Lumped thermal components"
        model HeatCapacitor "Lumped thermal element storing heat"
          parameter SI.HeatCapacity C "Heat capacity of element (= cp*m)";
          SI.Temperature T(start = 293.15, displayUnit = "degC") "Temperature of element";
          SI.TemperatureSlope der_T(start = 0) "Time derivative of temperature (= der(T))";
          Interfaces.HeatPort_a port;
        equation
          T = port.T;
          der_T = der(T);
          C*der(T) = port.Q_flow;
        end HeatCapacitor;

        model ThermalConductor "Lumped thermal element transporting heat without storing it"
          extends Interfaces.Element1D;
          parameter SI.ThermalConductance G "Constant thermal conductance of material";
        equation
          Q_flow = G*dT;
        end ThermalConductor;

        model ThermalResistor "Lumped thermal element transporting heat without storing it"
          extends Interfaces.Element1D;
          parameter SI.ThermalResistance R "Constant thermal resistance of material";
        equation
          dT = R*Q_flow;
        end ThermalResistor;
      end Components;

      package Sensors "Thermal sensors" end Sensors;

      package Sources "Thermal sources"
        model FixedTemperature "Fixed temperature boundary condition in Kelvin"
          parameter SI.Temperature T "Fixed temperature at port";
          Interfaces.HeatPort_b port;
        equation
          port.T = T;
        end FixedTemperature;

        model PrescribedHeatFlow "Prescribed heat flow boundary condition"
          parameter SI.Temperature T_ref = 293.15 "Reference temperature";
          parameter SI.LinearTemperatureCoefficient alpha = 0 "Temperature coefficient of heat flow rate";
          Modelica.Blocks.Interfaces.RealInput Q_flow(unit = "W");
          Interfaces.HeatPort_b port;
        equation
          port.Q_flow = -Q_flow*(1 + alpha*(port.T - T_ref));
        end PrescribedHeatFlow;
      end Sources;

      package Celsius "Components with Celsius input and/or output"
        model FixedTemperature "Fixed temperature boundary condition in degree Celsius"
          parameter Modelica.Units.NonSI.Temperature_degC T "Fixed temperature at the port";
          Interfaces.HeatPort_b port;
        equation
          port.T = Modelica.Units.Conversions.from_degC(T);
        end FixedTemperature;
      end Celsius;

      package Interfaces "Connectors and partial models"
        partial connector HeatPort "Thermal port for 1-dim. heat transfer"
          SI.Temperature T "Port temperature";
          flow SI.HeatFlowRate Q_flow "Heat flow rate (positive if flowing from outside into the component)";
        end HeatPort;

        connector HeatPort_a "Thermal port for 1-dim. heat transfer (filled rectangular icon)"
          extends HeatPort;
        end HeatPort_a;

        connector HeatPort_b "Thermal port for 1-dim. heat transfer (unfilled rectangular icon)"
          extends HeatPort;
        end HeatPort_b;

        partial model Element1D "Partial heat transfer element with two HeatPort connectors that does not store energy"
          SI.HeatFlowRate Q_flow "Heat flow rate from port_a -> port_b";
          SI.TemperatureDifference dT "port_a.T - port_b.T";
          HeatPort_a port_a;
          HeatPort_b port_b;
        equation
          dT = port_a.T - port_b.T;
          port_a.Q_flow = Q_flow;
          port_b.Q_flow = -Q_flow;
        end Element1D;
      end Interfaces;

      package Icons "Icons"
        model Conversion "Conversion of temperatures" end Conversion;

        model FixedTemperature "Icon of fixed temperature source" end FixedTemperature;
      end Icons;
    end HeatTransfer;
  end Thermal;

  package Math "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices"
    package Nonlinear "Library of functions operating on nonlinear equations"
      package Examples "Examples demonstrating the usage of the functions in package Nonlinear" end Examples;

      package Interfaces "Interfaces for functions" end Interfaces;
    end Nonlinear;

    package Icons "Icons for Math"
      partial function AxisLeft "Basic icon for mathematical function with y-axis on left side" end AxisLeft;

      partial function AxisCenter "Basic icon for mathematical function with y-axis in the center" end AxisCenter;
    end Icons;

    function tan "Tangent (u shall not be -pi/2, pi/2, 3*pi/2, ...)"
      input Modelica.Units.SI.Angle u "Independent variable";
      output Real y "Dependent variable y=tan(u)";
    algorithm
      y := .tan(u);
      annotation(Inline = true);
    end tan;

    function asin "Inverse sine (-1 <= u <= 1)"
      input Real u "Independent variable";
      output Modelica.Units.SI.Angle y "Dependent variable y=asin(u)";
    algorithm
      y := .asin(u);
      annotation(Inline = true);
    end asin;

    function acos "Inverse cosine (-1 <= u <= 1)"
      input Real u "Independent variable";
      output Modelica.Units.SI.Angle y "Dependent variable y=acos(u)";
    algorithm
      y := .acos(u);
      annotation(Inline = true);
    end acos;

    function exp "Exponential, base e"
      input Real u "Independent variable";
      output Real y "Dependent variable y=exp(u)";
    algorithm
      y := .exp(u);
      annotation(Inline = true);
    end exp;

    function log "Natural (base e) logarithm (u shall be > 0)"
      input Real u "Independent variable";
      output Real y "Dependent variable y=ln(u)";
    algorithm
      y := .log(u);
      annotation(Inline = true);
    end log;

    function log10 "Base 10 logarithm (u shall be > 0)"
      input Real u "Independent variable";
      output Real y "Dependent variable y=lg(u)";
    algorithm
      y := .log10(u);
      annotation(Inline = true);
    end log10;
  end Math;

  package Utilities "Library of utility functions dedicated to scripting (operating on files, streams, strings, system)"
    package Examples "Examples to demonstrate the usage of package Modelica.Utilities" end Examples;

    package Streams "Read from files and write to files"
      pure function error "Print error message and cancel all actions - in case of an unrecoverable error"
        input String string "String to be printed to error message window";
      algorithm
        assert(false, string);
      end error;
    end Streams;

    package System "Interaction with environment" end System;

    package Types "Type definitions used in package Modelica.Utilities" end Types;

    package Internal "Internal components that a user should usually not directly utilize"
      import Modelica.Units.SI;
    end Internal;
  end Utilities;

  package Constants "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)"
    import Modelica.Units.SI;
    import Modelica.Units.NonSI;
    final constant Real e(final unit = "1") = Modelica.Math.exp(1.0);
    final constant Real pi = 2*Modelica.Math.asin(1.0);
    final constant Real D2R(final unit = "rad/deg") = pi/180 "Degree to Radian";
    final constant Real R2D(final unit = "deg/rad") = 180/pi "Radian to Degree";
    final constant Real gamma(final unit = "1") = 0.57721566490153286061 "See http://en.wikipedia.org/wiki/Euler_constant";
    final constant Real eps = ModelicaServices.Machine.eps "The difference between 1 and the least value greater than 1 that is representable in the given floating point type";
    final constant Real small = ModelicaServices.Machine.small "Minimum normalized positive floating-point number";
    final constant Real inf = ModelicaServices.Machine.inf "Maximum representable finite floating-point number";
    final constant Integer Integer_inf = ModelicaServices.Machine.Integer_inf "Biggest Integer number such that Integer_inf and -Integer_inf are representable on the machine";
    final constant SI.Velocity c = 299792458 "Speed of light in vacuum";
    final constant SI.Acceleration g_n = 9.80665 "Standard acceleration of gravity on earth";
    final constant Real G(final unit = "m3/(kg.s2)") = 6.67430e-11 "Newtonian constant of gravitation";
    final constant SI.ElectricCharge q = 1.602176634e-19 "Elementary charge";
    final constant SI.FaradayConstant F = q*N_A "Faraday constant, C/mol";
    final constant Real h(final unit = "J.s") = 6.62607015e-34 "Planck constant";
    final constant Real k(final unit = "J/K") = 1.380649e-23 "Boltzmann constant";
    final constant Real R(final unit = "J/(mol.K)") = k*N_A "Molar gas constant";
    final constant Real sigma(final unit = "W/(m2.K4)") = 2*pi^5*k^4/(15*h^3*c^2) "Stefan-Boltzmann constant ";
    final constant Real N_A(final unit = "1/mol") = 6.02214076e23 "Avogadro constant";
    final constant SI.Permeability mu_0 = 1.25663706212e-6 "Magnetic constant";
    final constant Real epsilon_0(final unit = "F/m") = 1/(mu_0*c*c) "Electric constant";
    final constant NonSI.Temperature_degC T_zero = -273.15 "Absolute zero temperature";
  end Constants;

  package Icons "Library of icons"
    partial package ExamplesPackage "Icon for packages containing runnable examples" end ExamplesPackage;

    partial model Example "Icon for runnable examples" end Example;

    partial package Package "Icon for standard packages" end Package;

    partial package BasesPackage "Icon for packages containing base classes" end BasesPackage;

    partial package VariantsPackage "Icon for package containing variants" end VariantsPackage;

    partial package InterfacesPackage "Icon for packages containing interfaces" end InterfacesPackage;

    partial package SourcesPackage "Icon for packages containing sources" end SourcesPackage;

    partial package SensorsPackage "Icon for packages containing sensors" end SensorsPackage;

    partial package UtilitiesPackage "Icon for utility packages" end UtilitiesPackage;

    partial package TypesPackage "Icon for packages containing type definitions" end TypesPackage;

    partial package FunctionsPackage "Icon for packages containing functions" end FunctionsPackage;

    partial package IconsPackage "Icon for packages containing icons" end IconsPackage;

    partial package InternalPackage "Icon for an internal package (indicating that the package should not be directly utilized by user)" end InternalPackage;

    partial package MaterialPropertiesPackage "Icon for package containing property classes" end MaterialPropertiesPackage;

    partial class RoundSensor "Icon representing a round measurement device" end RoundSensor;

    partial function Function "Icon for functions" end Function;

    partial record Record "Icon for records" end Record;
  end Icons;

  package Units "Library of type and unit definitions"
    package SI "Library of SI unit definitions"
      type Angle = Real(final quantity = "Angle", final unit = "rad", displayUnit = "deg");
      type Length = Real(final quantity = "Length", final unit = "m");
      type Height = Length(min = 0);
      type Radius = Length(min = 0);
      type Area = Real(final quantity = "Area", final unit = "m2");
      type Volume = Real(final quantity = "Volume", final unit = "m3");
      type Time = Real(final quantity = "Time", final unit = "s");
      type AngularVelocity = Real(final quantity = "AngularVelocity", final unit = "rad/s");
      type AngularAcceleration = Real(final quantity = "AngularAcceleration", final unit = "rad/s2");
      type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
      type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
      type Mass = Real(quantity = "Mass", final unit = "kg", min = 0);
      type Density = Real(final quantity = "Density", final unit = "kg/m3", displayUnit = "g/cm3", min = 0.0);
      type SpecificVolume = Real(final quantity = "SpecificVolume", final unit = "m3/kg", min = 0.0);
      type MomentOfInertia = Real(final quantity = "MomentOfInertia", final unit = "kg.m2");
      type Torque = Real(final quantity = "Torque", final unit = "N.m");
      type Pressure = Real(final quantity = "Pressure", final unit = "Pa", displayUnit = "bar");
      type AbsolutePressure = Pressure(min = 0.0, nominal = 1e5);
      type PressureSlope = Real(final quantity = "PressureSlope", final unit = "Pa/s", displayUnit = "bar/s");
      type DynamicViscosity = Real(final quantity = "DynamicViscosity", final unit = "Pa.s", min = 0);
      type Energy = Real(final quantity = "Energy", final unit = "J");
      type Power = Real(final quantity = "Power", final unit = "W");
      type EnthalpyFlowRate = Real(final quantity = "EnthalpyFlowRate", final unit = "W");
      type MassFlowRate = Real(quantity = "MassFlowRate", final unit = "kg/s");
      type VolumeFlowRate = Real(final quantity = "VolumeFlowRate", final unit = "m3/s");
      type MomentumFlux = Real(final quantity = "MomentumFlux", final unit = "N");
      type ThermodynamicTemperature = Real(final quantity = "ThermodynamicTemperature", final unit = "K", min = 0.0, start = 288.15, nominal = 300, displayUnit = "degC") "Absolute temperature (use type TemperatureDifference for relative temperatures)" annotation(absoluteValue = true);
      type Temperature = ThermodynamicTemperature;
      type TemperatureDifference = Real(final quantity = "ThermodynamicTemperature", final unit = "K") annotation(absoluteValue = false);
      type TemperatureSlope = Real(final quantity = "TemperatureSlope", final unit = "K/s");
      type LinearTemperatureCoefficient = Real(final quantity = "LinearTemperatureCoefficient", final unit = "1/K");
      type RelativePressureCoefficient = Real(final quantity = "RelativePressureCoefficient", final unit = "1/K");
      type HeatFlowRate = Real(final quantity = "Power", final unit = "W");
      type ThermalConductivity = Real(final quantity = "ThermalConductivity", final unit = "W/(m.K)");
      type CoefficientOfHeatTransfer = Real(final quantity = "CoefficientOfHeatTransfer", final unit = "W/(m2.K)");
      type ThermalResistance = Real(final quantity = "ThermalResistance", final unit = "K/W");
      type ThermalConductance = Real(final quantity = "ThermalConductance", final unit = "W/K");
      type HeatCapacity = Real(final quantity = "HeatCapacity", final unit = "J/K");
      type SpecificHeatCapacity = Real(final quantity = "SpecificHeatCapacity", final unit = "J/(kg.K)");
      type RatioOfSpecificHeatCapacities = Real(final quantity = "RatioOfSpecificHeatCapacities", final unit = "1");
      type IsentropicExponent = Real(final quantity = "IsentropicExponent", final unit = "1");
      type Entropy = Real(final quantity = "Entropy", final unit = "J/K");
      type SpecificEntropy = Real(final quantity = "SpecificEntropy", final unit = "J/(kg.K)");
      type SpecificEnergy = Real(final quantity = "SpecificEnergy", final unit = "J/kg");
      type SpecificInternalEnergy = SpecificEnergy;
      type SpecificEnthalpy = SpecificEnergy;
      type DerDensityByPressure = Real(final unit = "s2/m2");
      type DerPressureByDensity = Real(final unit = "Pa.m3/kg");
      type DerPressureByTemperature = Real(final unit = "Pa/K");
      type ElectricCharge = Real(final quantity = "ElectricCharge", final unit = "C");
      type Permeability = Real(final quantity = "Permeability", final unit = "V.s/(A.m)");
      type VelocityOfSound = Real(final quantity = "Velocity", final unit = "m/s");
      type AmountOfSubstance = Real(final quantity = "AmountOfSubstance", final unit = "mol", min = 0);
      type MolarMass = Real(final quantity = "MolarMass", final unit = "kg/mol", min = 0);
      type MolarVolume = Real(final quantity = "MolarVolume", final unit = "m3/mol", min = 0);
      type MassFraction = Real(final quantity = "MassFraction", final unit = "1", min = 0, max = 1);
      type MoleFraction = Real(final quantity = "MoleFraction", final unit = "1", min = 0, max = 1);
      type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
      type ReynoldsNumber = Real(final quantity = "ReynoldsNumber", final unit = "1");
    end SI;

    package NonSI "Type definitions of non SI and other units"
      type Temperature_degC = Real(final quantity = "ThermodynamicTemperature", final unit = "degC") "Absolute temperature in degree Celsius (for relative temperature use Modelica.Units.SI.TemperatureDifference)" annotation(absoluteValue = true);
      type Pressure_bar = Real(final quantity = "Pressure", final unit = "bar") "Absolute pressure in bar";
    end NonSI;

    package Conversions "Conversion functions to/from non SI units and type definitions of non SI units"
      function to_degC "Convert from kelvin to degree Celsius"
        input SI.Temperature Kelvin "Value in kelvin";
        output Modelica.Units.NonSI.Temperature_degC Celsius "Value in degree Celsius";
      algorithm
        Celsius := Kelvin + Modelica.Constants.T_zero;
        annotation(Inline = true);
      end to_degC;

      function from_degC "Convert from degree Celsius to kelvin"
        input Modelica.Units.NonSI.Temperature_degC Celsius "Value in degree Celsius";
        output SI.Temperature Kelvin "Value in kelvin";
      algorithm
        Kelvin := Celsius - Modelica.Constants.T_zero;
        annotation(Inline = true);
      end from_degC;

      function to_bar "Convert from Pascal to bar"
        input SI.Pressure Pa "Value in Pascal";
        output Modelica.Units.NonSI.Pressure_bar bar "Value in bar";
      algorithm
        bar := Pa/1e5;
        annotation(Inline = true);
      end to_bar;
    end Conversions;

    package Icons "Icons for Units"
      partial function Conversion "Base icon for conversion functions" end Conversion;
    end Icons;
  end Units;
  annotation(version = "4.1.0", versionDate = "2025-05-23", dateModified = "2025-05-23 15:00:00Z");
end Modelica;

package ThermofluidStream "Library for the modeling of thermofluid streams"
  import Modelica.Units.SI;

  package Examples "Application Examples for the Library"
    model EspressoMachine "Get your simulated coffee!"
      package Water = Media.myMedia.Water.StandardWater "Medium Model for Water";
      Utilities.BoilerEspresso boiler(redeclare package Medium = Water, p_0 = 3e3, V(displayUnit = "l") = 0.001, x_0 = 0.001);
      Processes.FlowResistance flowResistance(redeclare package Medium = Water, initM_flow = ThermofluidStream.Utilities.Types.InitializationMethods.state, r(displayUnit = "mm") = 0.003, l = 0.3, redeclare function pLoss = Processes.Internal.FlowResistance.linearQuadraticPressureLoss(k = 3e8, k2 = 0));
      FlowControl.TanValve tanValve(redeclare package Medium = Water, invertInput = false, relativeLeakiness = 1e-8);
      Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow heating_element;
      FlowControl.TanValve tanValve1(redeclare package Medium = Water, relativeLeakiness = 1e-6);
      Utilities.SteamSink steamSink1(redeclare package Medium = Water, p0_par = 100000, m_flow_animate = 1e-3);
      Processes.FlowResistance flowResistance1(redeclare package Medium = Water, initM_flow = ThermofluidStream.Utilities.Types.InitializationMethods.state, r(displayUnit = "mm") = 0.003, l = 0.3, redeclare function pLoss = Processes.Internal.FlowResistance.linearQuadraticPressureLoss(k = 1e7, k2 = 0));
      Modelica.Blocks.Sources.Pulse steam_valve(width = 100, period = 100, nperiod = 1, offset = 0, startTime = 1200);
      Modelica.Blocks.Continuous.FirstOrder firstOrder1(k = 1, T = 1, initType = Modelica.Blocks.Types.Init.InitialState);
      Boundaries.Volume hex(redeclare package Medium = Water, useHeatport = true, A = 0.1, p_start = 100000, V_par(displayUnit = "l") = 0.0001, medium(h(start = 1e4)));
      Boundaries.Source source1(redeclare package Medium = Water, T0_par = 298.15, p0_par = 100000);
      Processes.FlowResistance flowResistance2(redeclare package Medium = Water, initM_flow = ThermofluidStream.Utilities.Types.InitializationMethods.state, r(displayUnit = "mm") = 0.003, l = 0.3, computeL = true, redeclare function pLoss = Processes.Internal.FlowResistance.linearQuadraticPressureLoss(k = 1e7, k2 = 0));
      Utilities.CupSink Tasse(redeclare package Medium = Water);
      Utilities.CoffeeStrainer coffeeStrainer(redeclare package Medium = Water);
      Sensors.SingleFlowSensor singleFlowSensor(redeclare package Medium = Water, digits = 2, quantity = ThermofluidStream.Sensors.Internal.Types.MassFlowQuantities.V_flow_lpMin);
      FlowControl.TanValve tanValve2(redeclare package Medium = Water, initM_flow = ThermofluidStream.Utilities.Types.InitializationMethods.state, relativeLeakiness = 1e-7);
      Modelica.Blocks.Sources.Pulse espressoValve(amplitude = 1, width = 30, period = 100, nperiod = 2, offset = 0, startTime = 1000);
      Modelica.Blocks.Continuous.FirstOrder firstOrder2(T = 1, initType = Modelica.Blocks.Types.Init.InitialState);
      Sensors.MultiSensor_Tp multiSensor_Tp(redeclare package Medium = Water, outputTemperature = true, temperatureUnit = "degC", pressureUnit = "bar");
      Modelica.Thermal.HeatTransfer.Components.HeatCapacitor brewing_head(C = 500, T(start = 298.15, fixed = true));
      Processes.ConductionElement conductionElement1(redeclare package Medium = Water, V(displayUnit = "l") = 1e-05, T_0 = 298.15);
      Topology.SplitterT2 splitterT2_1(redeclare package Medium = Water);
      Topology.JunctionT2 junctionT2_1(redeclare package Medium = Water);
      Processes.Pump pump(redeclare package Medium = Water, initM_flow = ThermofluidStream.Utilities.Types.InitializationMethods.state, omega_from_input = true, omegaStateSelect = StateSelect.never, redeclare function dp_tau_pump = Processes.Internal.TurboComponent.dp_tau_nominal_flow(k_fric_input = 0));
      Modelica.Blocks.Continuous.PI PI(k = 1e2, T = 1, initType = Modelica.Blocks.Types.Init.InitialState);
      Modelica.Blocks.Math.Feedback feedback;
      Modelica.Blocks.Math.Gain gain(k = 10e-4);
      Sensors.SingleFlowSensor singleFlowSensor1(redeclare package Medium = Water, digits = 3, outputValue = true, quantity = ThermofluidStream.Sensors.Internal.Types.MassFlowQuantities.V_flow_lpMin);
      Sensors.MultiSensor_Tp multiSensor_Tp1(redeclare package Medium = Water, outputTemperature = false, temperatureUnit = "degC", pressureUnit = "bar");
      Processes.Pump pump1(J_p = 1e-3, redeclare package Medium = Water, redeclare function dp_tau_pump = Processes.Internal.TurboComponent.dp_tau_nominal_flow(parametrizeByDesignPoint = false, V_r_input(displayUnit = "m3") = 0.1, k_p_input = 1e6, k_fric_input = 0), enableOutput = false, initOmega = ThermofluidStream.Utilities.Types.InitializationMethods.state, initPhi = false, omegaStateSelect = StateSelect.default, omega_from_input = true);
      Topology.SplitterT2 splitterT2_2(redeclare package Medium = Water);
      Modelica.Thermal.HeatTransfer.Components.ThermalResistor thermalResistor(R = 2);
      Modelica.Thermal.HeatTransfer.Sources.FixedTemperature environment(T = 298.15);
      Sensors.MultiSensor_Tp multiSensor_Tp2(redeclare package Medium = Water, outputTemperature = false, outputPressure = true, temperatureUnit = "degC", pressureUnit = "bar");
      Sensors.SingleFlowSensor singleFlowSensor2(redeclare package Medium = Water, digits = 2, quantity = ThermofluidStream.Sensors.Internal.Types.MassFlowQuantities.V_flow_lpMin);
      Modelica.Blocks.Continuous.LimPID PID1(controllerType = Modelica.Blocks.Types.SimpleController.PI, k = 1, Ti = 2, yMax = 3000, yMin = 0, y_start = 0);
      Modelica.Blocks.Sources.RealExpression realExpression1(y = 1.25e5);
      Modelica.Blocks.Continuous.LimPID PID2(controllerType = Modelica.Blocks.Types.SimpleController.PI, k = 1, Ti = 1, yMax = 0.005, yMin = 0.00001, y_start = 0);
      Modelica.Blocks.Sources.RealExpression realExpression2(y = 0.3);
      Modelica.Blocks.Continuous.FirstOrder firstOrder3(T = 1, initType = Modelica.Blocks.Types.Init.InitialState);
      Modelica.Blocks.Continuous.LimPID PID3(Ti = 3, controllerType = Modelica.Blocks.Types.SimpleController.PI, initType = .Modelica.Blocks.Types.Init.NoInit, k = 100, yMax = 5000, yMin = 0, y_start = 0);
      Modelica.Blocks.Sources.RealExpression realExpression3(y = 8.5);
      FlowControl.TanValve tanValve6(redeclare package Medium = Water, relativeLeakiness = 1e-6);
      Utilities.WaterSink waterSink(redeclare package Medium = Water, p0_par = 100000, m_flow_animate = 2.5e-3);
      Processes.FlowResistance flowResistance5(redeclare package Medium = Water, initM_flow = ThermofluidStream.Utilities.Types.InitializationMethods.state, r(displayUnit = "mm") = 0.003, l = 0.3, redeclare function pLoss = Processes.Internal.FlowResistance.linearQuadraticPressureLoss(k = 1e7, k2 = 0));
      Modelica.Blocks.Sources.Pulse steam_valve1(width = 100, period = 100, nperiod = 1, offset = 0, startTime = 1350);
      Modelica.Blocks.Continuous.FirstOrder firstOrder7(k = 1, T = 1, initType = Modelica.Blocks.Types.Init.InitialState);
      Sensors.SingleFlowSensor singleFlowSensor3(redeclare package Medium = Water, digits = 2, quantity = ThermofluidStream.Sensors.Internal.Types.MassFlowQuantities.V_flow_lpMin);
      Sensors.MultiSensor_Tp multiSensor_Tp3(redeclare package Medium = Water, outputTemperature = false, temperatureUnit = "degC", pressureUnit = "bar");
      Sensors.MultiSensor_Tp multiSensor_Tp4(redeclare package Medium = Water, outputTemperature = false, temperatureUnit = "degC", pressureUnit = "bar");
      Sensors.TwoPhaseSensorSelect sensorVaporQuality(redeclare package Medium = Water, quantity = ThermofluidStream.Sensors.Internal.Types.TwoPhaseQuantities.x_kgpkg);
      Sensors.TwoPhaseSensorSelect sensorVaporQuality1(redeclare package Medium = Water, quantity = ThermofluidStream.Sensors.Internal.Types.TwoPhaseQuantities.x_kgpkg);
      Sensors.TwoPhaseSensorSelect sensorVaporQuality2(redeclare package Medium = Water, quantity = ThermofluidStream.Sensors.Internal.Types.TwoPhaseQuantities.x_kgpkg);
      Sensors.SingleFlowSensor singleFlowSensor5(redeclare package Medium = Water, digits = 3, quantity = ThermofluidStream.Sensors.Internal.Types.MassFlowQuantities.V_flow_lpMin);
      inner DropOfCommons dropOfCommons(assertionLevel = AssertionLevel.warning, m_flow_reg = 0.5e-5, p_min(displayUnit = "Pa") = 700);
      Topology.SplitterT1 splitterT1_1(redeclare package Medium = Water);
      Utilities.CupSink Tasse1(redeclare package Medium = Water, flowResistance(initM_flow = ThermofluidStream.Utilities.Types.InitializationMethods.state));
      Processes.FlowResistance flowResistance4(redeclare package Medium = Water, r(displayUnit = "mm") = 0.003, l = 0.2, redeclare function pLoss = Processes.Internal.FlowResistance.linearQuadraticPressureLoss(k = 1e4));
      ThermofluidStream.Utilities.Icons.DLRLogo dLRLogo;
    equation
      connect(boiler.heatport_heat, heating_element.port);
      connect(boiler.steam_out, flowResistance1.inlet);
      connect(tanValve1.inlet, flowResistance1.outlet);
      connect(boiler.heatport_HX, hex.heatPort);
      connect(singleFlowSensor.outlet, tanValve2.inlet);
      connect(tanValve2.outlet, coffeeStrainer.inlet);
      connect(espressoValve.y, firstOrder2.u);
      connect(tanValve2.u, firstOrder2.y);
      connect(multiSensor_Tp.inlet, hex.outlet);
      connect(splitterT2_1.outletB, singleFlowSensor.inlet);
      connect(flowResistance2.outlet, junctionT2_1.inletB);
      connect(hex.inlet, junctionT2_1.outlet);
      connect(pump.outlet, junctionT2_1.inletA);
      connect(PI.y, pump.omega_input);
      connect(multiSensor_Tp.T_out, gain.u);
      connect(feedback.u2, singleFlowSensor1.value_out);
      connect(brewing_head.port, conductionElement1.heatPort);
      connect(splitterT2_1.inlet, conductionElement1.outlet);
      connect(multiSensor_Tp1.inlet, coffeeStrainer.inlet);
      connect(flowResistance.outlet, tanValve.inlet);
      connect(boiler.inlet, tanValve.outlet);
      connect(gain.y, feedback.u1);
      connect(tanValve1.u, firstOrder1.y);
      connect(thermalResistor.port_a, brewing_head.port);
      connect(environment.port, thermalResistor.port_b);
      connect(tanValve1.outlet, singleFlowSensor2.inlet);
      connect(steamSink1.inlet, singleFlowSensor2.outlet);
      connect(steam_valve.y, firstOrder1.u);
      connect(PI.u, feedback.y);
      connect(pump1.outlet, splitterT2_2.inlet);
      connect(flowResistance2.inlet, splitterT2_2.outletB);
      connect(heating_element.Q_flow, PID1.y);
      connect(boiler.p_out, PID1.u_m);
      connect(PID1.u_s, realExpression1.y);
      connect(realExpression2.y, PID2.u_s);
      connect(PID2.u_m, boiler.y_out);
      connect(PID2.y, firstOrder3.u);
      connect(tanValve.u, firstOrder3.y);
      connect(realExpression3.y, PID3.u_s);
      connect(PID3.u_m, multiSensor_Tp2.p_out);
      connect(source1.outlet, pump1.inlet);
      connect(tanValve6.inlet, flowResistance5.outlet);
      connect(tanValve6.u, firstOrder7.y);
      connect(tanValve6.outlet, singleFlowSensor3.inlet);
      connect(waterSink.inlet, singleFlowSensor3.outlet);
      connect(steam_valve1.y, firstOrder7.u);
      connect(flowResistance5.inlet, boiler.water_out);
      connect(multiSensor_Tp3.inlet, singleFlowSensor2.outlet);
      connect(multiSensor_Tp4.inlet, singleFlowSensor3.outlet);
      connect(sensorVaporQuality.inlet, singleFlowSensor3.outlet);
      connect(sensorVaporQuality2.inlet, coffeeStrainer.inlet);
      connect(sensorVaporQuality1.inlet, singleFlowSensor2.outlet);
      connect(splitterT2_2.outletA, singleFlowSensor5.inlet);
      connect(coffeeStrainer.outlet, splitterT1_1.inlet);
      connect(splitterT1_1.outletB, Tasse1.inlet);
      connect(splitterT1_1.outletA, Tasse.inlet);
      connect(PID3.y, pump1.omega_input);
      connect(multiSensor_Tp2.inlet, splitterT2_2.inlet);
      connect(singleFlowSensor5.outlet, flowResistance.inlet);
      connect(splitterT2_1.outletA, singleFlowSensor1.inlet);
      connect(pump.inlet, flowResistance4.outlet);
      connect(flowResistance4.inlet, singleFlowSensor1.outlet);
      connect(conductionElement1.inlet, hex.outlet);
      annotation(experiment(StopTime = 1500, Tolerance = 1e-6, Interval = 1.5, __Dymola_Algorithm = "Dassl"));
    end EspressoMachine;

    package Utilities "Package for sub-models of examples"
      model BoilerEspresso "Model of a boiler in a espresso machine."
        replaceable package Medium = Media.myMedia.Interfaces.PartialTwoPhaseMedium "Medium model";
        parameter SI.Pressure p_0 = 1e5 "Start pressure";
        parameter SI.Volume V = 1 "Boiler volume";
        parameter SI.ThermalConductance UA_HX = 200 "Heat transfer coefficient times contact area to medium to Water Pipe";
        parameter SI.ThermalConductance UA_heat = 200 "Heat transfer coefficient times contact area to medium to left Heatport";
        parameter Medium.MassFraction x_0 = 0.05 "Initial vapor quality of steam.";
        Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatport_heat "heatport to add heat";
        Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatport_HX "heatport to add heat";
        Interfaces.Outlet steam_out(redeclare package Medium = Medium) "ontlet for steam";
        Interfaces.Outlet water_out(redeclare package Medium = Medium) "ontlet for hot water";
        Interfaces.Inlet inlet(redeclare package Medium = Medium) "inlet for fresh water";
        Modelica.Blocks.Interfaces.RealOutput y_out(unit = "") "Water level percentage []";
        Modelica.Blocks.Interfaces.RealOutput p_out(unit = "Pa") "Boiler pressure [Pa]";
        Boundaries.PhaseSeparator2 phaseSeparator2_1(redeclare package Medium = Medium, useHeatport = true, A = 2e5, U = 2e5, p_start = p_0, V_par = V, pipe1_low = 0.05, pipe1_high = 0.1, pipe2_low = 0.9, pipe2_high = 0.95, init_method = ThermofluidStream.Boundaries.Internal.InitializationMethodsPhaseSeperator.x, x_0 = x_0);
        Modelica.Thermal.HeatTransfer.Components.ThermalConductor thermalConductor(G = UA_heat);
        Modelica.Thermal.HeatTransfer.Components.ThermalConductor thermalConductor1(G = UA_HX);
        Modelica.Blocks.Sources.RealExpression p(y = phaseSeparator2_1.medium.p);
        Modelica.Blocks.Sources.RealExpression p1(y = phaseSeparator2_1.liquid_level);
      equation
        connect(phaseSeparator2_1.outlet[1], water_out);
        connect(phaseSeparator2_1.outlet[2], steam_out);
        connect(inlet, phaseSeparator2_1.inlet);
        connect(heatport_HX, thermalConductor1.port_b);
        connect(thermalConductor1.port_a, phaseSeparator2_1.heatPort);
        connect(thermalConductor.port_b, phaseSeparator2_1.heatPort);
        connect(thermalConductor.port_a, heatport_heat);
        connect(p.y, p_out);
        connect(p1.y, y_out);
      end BoilerEspresso;

      model CoffeeStrainer "Holds coffee in the machine."
        replaceable package Medium = Media.myMedia.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
        Interfaces.Inlet inlet(redeclare package Medium = Medium);
        Interfaces.Outlet outlet(redeclare package Medium = Medium);
        Processes.FlowResistance coffeeStrainer(redeclare package Medium = Medium, r(displayUnit = "mm") = 0.003, l = 0.3, redeclare function pLoss = Processes.Internal.FlowResistance.linearQuadraticPressureLoss(k = 8e8, k2 = 0));
      equation
        connect(coffeeStrainer.inlet, inlet);
        connect(coffeeStrainer.outlet, outlet);
      end CoffeeStrainer;

      model SteamSink "Sink with fancy steam animation."
        extends Boundaries.Sink(final pressureFromInput = false);
        parameter SI.MassFlowRate m_flow_animate = 1e-4 "Mass flow rate where the animation is at original size.";
        Real x(unit = "1");
      initial equation
        x = 0;
      equation
        der(x)*0.1 = max(0, inlet.m_flow/m_flow_animate) - x;
      end SteamSink;

      model WaterSink "Sink with fancy water animation."
        extends Boundaries.Sink(final pressureFromInput = false);
        parameter SI.MassFlowRate m_flow_animate = 1e-4 "Mass flow rate where the animation is at original size.";
        Real x(unit = "1");
      initial equation
        x = 0;
      equation
        der(x)*0.1 = max(0, inlet.m_flow/m_flow_animate) - x;
      end WaterSink;

      model CupSink "Sink with fancy cup animation"
        replaceable package Medium = Media.myMedia.Interfaces.PartialMedium "Medium Model" annotation(choicesAllMatching = true);
        parameter SI.Mass M = 3.448e-2 "Mass of medium that fits in the cup";
        Real x(unit = "1", start = 0, fixed = true);
        Boundaries.Sink sink(redeclare package Medium = Medium, final pressureFromInput = false, final p0_par = 100000);
        Interfaces.Inlet inlet(redeclare package Medium = Medium);
        Processes.FlowResistance flowResistance(redeclare package Medium = Medium, r(displayUnit = "cm") = 0.05, l(displayUnit = "cm") = 0.01, redeclare function pLoss = Processes.Internal.FlowResistance.linearQuadraticPressureLoss(k = 10));
      equation
        der(x) = inlet.m_flow/M;
        connect(flowResistance.outlet, sink.inlet);
        connect(flowResistance.inlet, inlet);
      end CupSink;
    end Utilities;
  end Examples;

  package Interfaces "Interface definitions for the library"
    connector Inlet "Inlet port for a fluid"
      replaceable package Medium = Media.myMedia.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
      SI.Pressure r "Inertial pressure";
      flow SI.MassFlowRate m_flow "Mass flow rate";
      input Medium.ThermodynamicState state "Thermodynamic state assuming steady mass flow pressure";
    end Inlet;

    connector Outlet "Outlet port for a fluid"
      replaceable package Medium = Media.myMedia.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
      SI.Pressure r "Inertial pressure";
      flow SI.MassFlowRate m_flow "Mass flow rate";
      output Medium.ThermodynamicState state "Thermodynamic state assuming steady mass flow pressure";
    end Outlet;

    partial model SISOFlow "Base Model with basic flow eqautions for SISO"
      extends ThermofluidStream.Utilities.DropOfCommonsPlus;
      import ThermofluidStream.Utilities.Types.InitializationMethods;
      replaceable package Medium = Media.myMedia.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
      parameter Utilities.Units.Inertance L = dropOfCommons.L "Inertance";
      parameter StateSelect m_flowStateSelect = StateSelect.default "State selection for mass flow rate";
      parameter InitializationMethods initM_flow = ThermofluidStream.Utilities.Types.InitializationMethods.none "Initialization method for mass flow rate";
      parameter SI.MassFlowRate m_flow_0 = 0 "Initial value for mass flow rate";
      parameter Utilities.Units.MassFlowAcceleration m_acceleration_0 = 0 "Initial value for derivative of mass flow rate";
      parameter Boolean clip_p_out "= false, if dr_corr=0 (correction of inertial pressure difference)";
      parameter SI.Pressure p_min = dropOfCommons.p_min "Minimum steady-state output pressure";
      Inlet inlet(redeclare package Medium = Medium);
      Outlet outlet(redeclare package Medium = Medium);
      SI.MassFlowRate m_flow(stateSelect = m_flowStateSelect) = inlet.m_flow "Mass flow rate";
      SI.Pressure dr_corr "Correction of inertial pressure difference";
      SI.Pressure dp "Pressure difference";
    protected
      SI.Pressure p_in = Medium.pressure(inlet.state) "Inlet pressure";
      SI.SpecificEnthalpy h_in = Medium.specificEnthalpy(inlet.state) "Inlet specific enthalpy";
      Medium.MassFraction Xi_in[Medium.nXi] = Medium.massFraction(inlet.state) "Inlet mass fractions";
      SI.Pressure p_out "Outlet pressure";
      SI.SpecificEnthalpy h_out "Outlet specific enthalpy";
      Medium.MassFraction Xi_out[Medium.nXi] "Outlet mass fractions";
    initial equation
      if initM_flow == InitializationMethods.state then
        m_flow = m_flow_0;
      elseif initM_flow == InitializationMethods.derivative then
        der(m_flow) = m_acceleration_0;
      elseif initM_flow == InitializationMethods.steadyState then
        der(m_flow) = 0;
      end if;
    equation
      inlet.m_flow + outlet.m_flow = 0;
      outlet.r = inlet.r + dr_corr - der(inlet.m_flow)*L;
      if clip_p_out then
        p_out = max(p_min, p_in + dp);
        dr_corr = dp - (p_out - p_in);
      else
        p_out = p_in + dp;
        dr_corr = 0;
      end if;
      outlet.state = Medium.setState_phX(p_out, h_out, Xi_out);
    end SISOFlow;
  end Interfaces;

  package Boundaries "This package contains boundary models for the stream."
    model Source "Source (p,T,Xi) or (p,h,Xi)"
      extends ThermofluidStream.Utilities.DropOfCommonsPlus;
      replaceable package Medium = Media.myMedia.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
      parameter Boolean pressureFromInput = false "= true, if pressure input connector is enabled" annotation(Evaluate = true, HideResult = true);
      parameter SI.Pressure p0_par = Medium.p_default "Pressure set value";
      parameter Boolean temperatureFromInput = false "= true, if temperature input connector is enabled" annotation(Evaluate = true, HideResult = true);
      parameter SI.Temperature T0_par = Medium.T_default "Temperature set value";
      parameter Boolean xiFromInput = false "= true, if mass fractions input connector is enabled" annotation(Evaluate = true, HideResult = true);
      parameter Medium.MassFraction Xi0_par[Medium.nXi] = Medium.X_default[1:Medium.nXi] "Mass fractions set value";
      parameter Boolean setEnthalpy = false "= true, if specific enthalpy is set, (= false to set temperature)" annotation(Evaluate = true, HideResult = true);
      parameter Boolean enthalpyFromInput = false "= true, if specific enthalpy input connector is enabled" annotation(Evaluate = true, HideResult = true);
      parameter SI.SpecificEnthalpy h0_par = Medium.h_default "Specific enthalpy set value";
      parameter Utilities.Units.Inertance L = dropOfCommons.L "Inertance";
      parameter Boolean displayPressure = true "= true, if pressure p0_par is displayed" annotation(Evaluate = true, HideResult = true);
      parameter Boolean displayTemperature = true "= true, if temperature T0_par or specific enthalpy h0_par is displayed" annotation(Evaluate = true, HideResult = true);
      parameter Boolean displayMassFractions = false "= true, if mass fractions Xi0_par are displayed" annotation(Evaluate = true, HideResult = true);
      parameter Boolean displayInertance = false "= true, if inertance L is displayed" annotation(Evaluate = true, HideResult = true);
      final parameter Boolean displayP = displayPressure and not pressureFromInput annotation(Evaluate = true, HideResult = true);
      final parameter Boolean displayT = displayTemperature and not temperatureFromInput and not setEnthalpy annotation(Evaluate = true, HideResult = true);
      final parameter Boolean displayH = displayTemperature and not enthalpyFromInput and setEnthalpy annotation(Evaluate = true, HideResult = true);
      final parameter Boolean displayXi = displayMassFractions and not xiFromInput annotation(Evaluate = true, HideResult = true);
      final parameter String displayPos1 = if displayP then "p = %p0_par" elseif displayT then "T = %T0_par"
       elseif displayH then "h = %h0_par"
       elseif displayXi then "Xi = %Xi0_par"
       elseif displayInertance then "L = %L" else "";
      final parameter String displayPos2 = if displayP and displayT then "T = %T0_par" elseif displayP and displayH then "h = %h0_par"
       elseif displayXi and (displayP or displayT or displayH) then "Xi = %Xi0_par"
       elseif displayInertance and (displayP or displayT or displayH or displayXi) then "L = %L" else "";
      final parameter String displayPos3 = if displayXi and displayP and (displayT or displayH) then "Xi = %Xi0_par" elseif displayInertance and not displayPos2 == "L = %L" and not displayPos1 == "L = %L" then "L = %L" else "";
      final parameter String displayPos4 = if displayP and (displayT or displayH) and displayXi and displayInertance then "L = %L" else "" annotation(Evaluate = true, HideResult = true);
      Modelica.Blocks.Interfaces.RealInput p0_var(unit = "Pa") if pressureFromInput "Pressure input connector [Pa]";
      Modelica.Blocks.Interfaces.RealInput T0_var(unit = "K") if not setEnthalpy and temperatureFromInput "Temperature input connector [K]";
      Modelica.Blocks.Interfaces.RealInput h0_var(unit = "J/kg") if setEnthalpy and enthalpyFromInput "Enthalpy input connector [J/kg]";
      Modelica.Blocks.Interfaces.RealInput xi_var[Medium.nXi](each unit = "kg/kg") if xiFromInput "Mass fractions connector [kg/kg]";
      Interfaces.Outlet outlet(redeclare package Medium = Medium);
    protected
      Modelica.Blocks.Interfaces.RealInput p0(unit = "Pa") "Internal pressure connector";
      Modelica.Blocks.Interfaces.RealInput T0(unit = "K") "Internal temperature connector";
      Modelica.Blocks.Interfaces.RealInput h0(unit = "J/kg") "Internal enthalpy connector";
      Modelica.Blocks.Interfaces.RealInput Xi0[Medium.nXi](each unit = "kg/kg") "Internal mass fractions connector";
    equation
      connect(T0_var, T0);
      if not temperatureFromInput or setEnthalpy then
        T0 = T0_par;
      end if;
      connect(p0_var, p0);
      if not pressureFromInput then
        p0 = p0_par;
      end if;
      connect(xi_var, Xi0);
      if not xiFromInput then
        Xi0 = Xi0_par;
      end if;
      connect(h0_var, h0);
      if not enthalpyFromInput or not setEnthalpy then
        h0 = h0_par;
      end if;
      L*der(outlet.m_flow) = outlet.r - 0;
      outlet.state = if not setEnthalpy then Medium.setState_pTX(p0, T0, Xi0) else Medium.setState_phX(p0, h0, Xi0);
    end Source;

    model Sink "Sink (p)"
      extends ThermofluidStream.Utilities.DropOfCommonsPlus;
      replaceable package Medium = Media.myMedia.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
      parameter Boolean pressureFromInput = false "= true, if pressure input connector is enabled" annotation(Evaluate = true, HideResult = true);
      parameter SI.Pressure p0_par = Medium.p_default "Pressure set value";
      parameter Utilities.Units.Inertance L = dropOfCommons.L "Inertance";
      parameter Boolean displayPressure = true "= true, if pressure p0_par is displayed" annotation(Evaluate = true, HideResult = true);
      parameter Boolean displayInertance = false "= true, if inertance L is displayed" annotation(Evaluate = true, HideResult = true);
      final parameter Boolean displayP = displayPressure and not pressureFromInput annotation(Evaluate = true, HideResult = true);
      final parameter String displayPos1 = if displayP then "p = %p0_par" elseif displayInertance then "L = %L" else "";
      final parameter String displayPos2 = if displayP and displayInertance then "L = %L" else "";
      Interfaces.Inlet inlet(redeclare package Medium = Medium);
      Modelica.Blocks.Interfaces.RealInput p0_var(unit = "Pa") if pressureFromInput "Pressure input connector [Pa]";
    protected
      Modelica.Blocks.Interfaces.RealInput p0(unit = "Pa") "Internal pressure connector";
      SI.Pressure r "Inertial pressure";
      SI.Pressure p = Medium.pressure(inlet.state) "Steady state pressure";
    equation
      connect(p0_var, p0);
      if not pressureFromInput then
        p0 = p0_par;
      end if;
      der(inlet.m_flow)*L = inlet.r - r;
      r + p = p0;
    end Sink;

    model Volume "Volume of fixed size, closed to the ambient"
      extends Internal.PartialVolume;
      parameter SI.Volume V_par(displayUnit = "l") = 0.001 "Volume";
      parameter Boolean density_derp_h_from_media = false "= true, if the derivative of density by pressure at const specific enthalpy is calculated from media model (only available for some media models)" annotation(Evaluate = true, HideResult = true);
      parameter SI.DerDensityByPressure density_derp_h_set = 1e-6 "Derivative of density by pressure at const specific enthalpy set value (e.g approx. 1e-5 for air, 1e-7 for water)";
    equation
      assert(abs(density_derp_h) > 1e-12, "The simple Volume model should not be used with (nearly) incompressible media. Consider using the FlexVolume instead.", dropOfCommons.assertionLevel);
      if density_derp_h_from_media then
        density_derp_h = Medium.density_derp_h(medium.state);
      else
        density_derp_h = density_derp_h_set;
      end if;
      V = V_par;
      W_v = 0;
      state_out = medium.state;
    end Volume;

    model PhaseSeparator2 "Phase separator with two outlets"
      extends Boundaries.Internal.PartialVolumeM(redeclare replaceable package Medium = Media.myMedia.Interfaces.PartialTwoPhaseMedium, useHeatport = false, final initialize_energy = false, final T_start = 0, final h_start = 0, final use_hstart = false, final M_outlets = 2);
      import Init = ThermofluidStream.Boundaries.Internal.InitializationMethodsPhaseSeperator;
      parameter SI.Volume V_par(displayUnit = "l") = 0.01 "Volume of phase separator";
      parameter Real pipe1_low(unit = "1", min = 0, max = 1) "Low end of first pipe";
      parameter Real pipe1_high(unit = "1", min = 0, max = 1) "High end of first pipe";
      parameter Real pipe2_low(unit = "1", min = 0, max = 1) "Low end of second pipe";
      parameter Real pipe2_high(unit = "1", min = 0, max = 1) "High end of second pipe";
      parameter Boolean density_derp_h_from_media = false "= true, if the derivative of density by pressure at const specific enthalpy is calculated from media model (only available for some media models)" annotation(Evaluate = true, HideResult = true);
      parameter SI.DerDensityByPressure density_derp_h_set = 1e-6 "Derivative of density by pressure at const specific enthalpy set value (e.g approx. 1e-5 for air, 1e-7 for water)";
      parameter Init init_method = ThermofluidStream.Boundaries.Internal.InitializationMethodsPhaseSeperator.l "Initialization method";
      parameter SI.SpecificEnthalpy h_0 = Medium.h_default "Initial specific enthalpy";
      parameter SI.Mass M_0 = 1 "Initial mass";
      parameter Real l_0(unit = "1", min = 0, max = 1) = 0.5 "Initial liquid level";
      parameter Real x_0(unit = "kg/kg", min = 0, max = 1) = 0.5 "Initial vapor quality";
      Real liquid_level(unit = "1") "Level of liquid line";
      Real liquid_level_pipe1(unit = "1") "Level of liquid line in first pipe";
      Real liquid_level_pipe2(unit = "1") "Level of liquid line in second pipe";
    protected
      Medium.MassFraction x = (medium.h - h_bubble)/(h_dew - h_bubble) "Calculated vapor quality of medium that can go below zero and above one";
      SI.SpecificEnthalpy h_pipe1 "Specific enthalpy of medium in first pipe";
      SI.SpecificEnthalpy h_pipe2 "Specific enthalpy of medium in second pipe";
      SI.Density d_liq = Medium.bubbleDensity(Medium.setSat_p(medium.p)) "Bubble density at saturation";
      SI.Density d_gas = Medium.dewDensity(Medium.setSat_p(medium.p)) "Dew density at saturation";
      SI.SpecificEnthalpy h_bubble = Medium.bubbleEnthalpy(Medium.setSat_p(medium.p)) - 1 "Specific bubble enthalpy";
      SI.SpecificEnthalpy h_dew = Medium.dewEnthalpy(Medium.setSat_p(medium.p)) + 1 "Specific dew enthalpy";
    initial equation
      assert(pipe1_high > pipe1_low, "Upper pipe end must be higher then lower end.");
      assert(pipe2_high > pipe2_low, "Upper pipe end must be higher then lower end.");
      if init_method == Init.h then
        medium.h = h_0;
      elseif init_method == Init.M then
        x/d_gas + (1 - x)/d_liq = V/M_0;
        assert(x >= 0 and x <= 1, "Initialization by mass might be inaccurate outside the two-phase region", AssertionLevel.warning);
      elseif init_method == Init.l then
        x = (d_gas*(1 - l_0))/(d_liq*l_0 + d_gas*(1 - l_0));
      elseif init_method == Init.x then
        x = x_0;
      end if;
    equation
      if density_derp_h_from_media then
        density_derp_h = Medium.density_derp_h(medium.state);
      else
        density_derp_h = density_derp_h_set;
      end if;
      V = V_par;
      W_v = 0;
      liquid_level = max(0, min(1, M*(1 - x)/d_liq/V));
      liquid_level_pipe1 = max(0, min(1, (liquid_level - pipe1_low)/(pipe1_high - pipe1_low)));
      liquid_level_pipe2 = max(0, min(1, (liquid_level - pipe2_low)/(pipe2_high - pipe2_low)));
      h_pipe1 = smooth(1, if x < 0 then medium.h elseif x <= 1 then liquid_level_pipe1*h_bubble + (1 - liquid_level_pipe1)*h_dew else medium.h);
      h_pipe2 = smooth(1, if x < 0 then medium.h elseif x <= 1 then liquid_level_pipe2*h_bubble + (1 - liquid_level_pipe2)*h_dew else medium.h);
      state_out[1] = Medium.setState_phX(medium.p, h_pipe1, medium.Xi);
      state_out[2] = Medium.setState_phX(medium.p, h_pipe2, medium.Xi);
    end PhaseSeparator2;

    package Internal "Partials and Internal functions"
      partial model PartialVolume "Partial volume with one inlet and one outlet"
        extends ThermofluidStream.Utilities.DropOfCommonsPlus;
        replaceable package Medium = Media.myMedia.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
        parameter Boolean useHeatport = false "=true, if heatport is enabled" annotation(Evaluate = true, HideResult = true);
        parameter Boolean useInlet = true "= true, if inlet is enabled" annotation(Evaluate = true, HideResult = true);
        parameter Boolean useOutlet = true "= true, if outlet is enabled" annotation(Evaluate = true, HideResult = true);
        parameter SI.Area A = 1 "Heat transfer area";
        parameter SI.CoefficientOfHeatTransfer U = 200 "Thermal transmittance";
        parameter Boolean initialize_pressure = true "=true, if pressure is initialized" annotation(Evaluate = true, HideResult = true);
        parameter SI.Pressure p_start = Medium.p_default "Initial pressure set value";
        parameter Boolean initialize_energy = true "= true, if internal energy is initialized" annotation(Evaluate = true, HideResult = true);
        parameter SI.Temperature T_start = Medium.T_default "Initial Temperature set value";
        parameter Boolean initialize_Xi = true "=true, if mass fractions are iinitialized" annotation(Evaluate = true, HideResult = true);
        parameter Medium.MassFraction Xi_0[Medium.nXi] = Medium.X_default[1:Medium.nXi] "Initial mass fractions set values";
        parameter Boolean use_hstart = false "=true, if internal energy is initialized with specific enthalpy" annotation(Evaluate = true, HideResult = true);
        parameter SI.SpecificEnthalpy h_start = Medium.h_default "Initial specific enthalpy set value";
        parameter Utilities.Units.Inertance L = dropOfCommons.L "Inertance of inlet/outlet";
        parameter Real k_volume_damping(unit = "1", min = 0) = dropOfCommons.k_volume_damping "Damping factor multiplicator";
        parameter SI.MassFlowRate m_flow_assert(max = 0) = -dropOfCommons.m_flow_reg "Assertion threshold for negative massflow";
        parameter Boolean usePreferredMediumStates = false "=true, if preferred medium states are used" annotation(Evaluate = true, HideResult = true);
        Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort(Q_flow = Q_flow, T = T_heatPort) if useHeatport;
        Interfaces.Inlet inlet(redeclare package Medium = Medium, m_flow = m_flow_in, r = r_in, state = state_in) if useInlet;
        Interfaces.Outlet outlet(redeclare package Medium = Medium, m_flow = m_flow_out, r = r_out, state = state_out) if useOutlet;
        Medium.BaseProperties medium(preferredMediumStates = usePreferredMediumStates);
        SI.Volume V "Volume";
        SI.Mass M(stateSelect = if usePreferredMediumStates then StateSelect.default else StateSelect.always) = V*medium.d "Mass";
        SI.Mass MXi[Medium.nXi](each stateSelect = if usePreferredMediumStates then StateSelect.default else StateSelect.always) = M*medium.Xi "Masses of species";
        SI.Energy U_med(stateSelect = if usePreferredMediumStates then StateSelect.default else StateSelect.always) = M*medium.u "Internal energy";
        SI.HeatFlowRate Q_flow "Heat flow rate";
        SI.Power W_v "Work due to change of volume";
      protected
        SI.Temperature T_heatPort "Heat port temperature";
        SI.Pressure r "Inertial pressure";
        Real d(unit = "1/(m.s)") = k_volume_damping*sqrt(abs(2*L/(V*max(density_derp_h, 1e-10)))) "Friction factor for coupled boundaries";
        SI.DerDensityByPressure density_derp_h "Partial derivative of density by pressure at constant specific enthalpy";
        SI.Pressure r_damping = d*der(M) "Damping of inertial pressure";
        Medium.ThermodynamicState state_in "Inlet state";
        SI.Pressure p_in = Medium.pressure(state_in) "Inlet pressure";
        SI.SpecificEnthalpy h_in = if noEvent(m_flow_in >= 0) then Medium.specificEnthalpy(state_in) else medium.h "Inlet specific enthalpy";
        Medium.MassFraction Xi_in[Medium.nXi] = if noEvent(m_flow_in >= 0) then Medium.massFraction(state_in) else medium.Xi "Inlet mass fractions";
        Medium.ThermodynamicState state_out "Oulet state";
        SI.SpecificEnthalpy h_out = if noEvent(-m_flow_out >= 0) then Medium.specificEnthalpy(state_out) else medium.h "Outlet specific enthalpy";
        Medium.MassFraction Xi_out[Medium.nXi] = if noEvent(-m_flow_out >= 0) then Medium.massFraction(state_out) else medium.Xi "Outlet mass fractions";
        SI.Pressure r_in;
        SI.Pressure r_out "Inlet/Outlet inertial pressure";
        SI.MassFlowRate m_flow_in;
        SI.MassFlowRate m_flow_out "Inlet/Outlet mass flow rate";
      initial equation
        if initialize_pressure then
          medium.p = p_start;
        end if;
        if initialize_energy then
          if use_hstart then
            medium.h = h_start;
          else
            medium.T = T_start;
          end if;
        end if;
        if initialize_Xi then
          medium.Xi = Xi_0;
        end if;
      equation
        assert(m_flow_in > m_flow_assert, "Negative mass flow rate at Volume inlet", dropOfCommons.assertionLevel);
        assert(-m_flow_out > m_flow_assert, "Positive mass flow rate at Volume outlet", dropOfCommons.assertionLevel);
        assert(M > 0, "Negative mass inside the volume");
        der(m_flow_in)*L = r_in - r - r_damping;
        der(m_flow_out)*L = r_out - r_damping;
        r + p_in = medium.p;
        der(M) = m_flow_in + m_flow_out;
        der(U_med) = W_v + Q_flow + h_in*m_flow_in + h_out*m_flow_out;
        der(MXi) = Xi_in*m_flow_in + Xi_out*m_flow_out;
        Q_flow = U*A*(T_heatPort - medium.T);
        if not useHeatport then
          T_heatPort = medium.T;
        end if;
        if not useInlet then
          m_flow_in = 0;
          state_in = Medium.setState_phX(Medium.p_default, Medium.h_default, Medium.X_default[1:Medium.nXi]);
        end if;
        if not useOutlet then
          m_flow_out = 0;
        end if;
      end PartialVolume;

      partial model PartialVolumeM "Partial volume with one inlet and M outlet"
        extends ThermofluidStream.Utilities.DropOfCommonsPlus;
        replaceable package Medium = Media.myMedia.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
        parameter Integer M_outlets = 1 "Number if outlets";
        parameter Boolean useHeatport = false "=true, if heatPort is enabled" annotation(Evaluate = true, HideResult = true);
        parameter SI.Area A = 1 "Heat transfer area";
        parameter SI.CoefficientOfHeatTransfer U = 200 "Thermal transmittance";
        parameter Boolean initialize_pressure = true "=true, if pressure is initialized" annotation(Evaluate = true, HideResult = true);
        parameter SI.Pressure p_start = Medium.p_default "Initial pressure set value";
        parameter Boolean initialize_energy = true "= true, if internal energy is initialized" annotation(Evaluate = true, HideResult = true);
        parameter SI.Temperature T_start = Medium.T_default "Initial Temperature set value";
        parameter Boolean initialize_Xi = true "=true, if mass fractions are iinitialized" annotation(Evaluate = true, HideResult = true);
        parameter Medium.MassFraction Xi_0[Medium.nXi] = Medium.X_default[1:Medium.nXi] "Initial mass fractions set values";
        parameter Boolean use_hstart = false "=true, if internal energy is initialized with specific enthalpy" annotation(Evaluate = true, HideResult = true);
        parameter SI.SpecificEnthalpy h_start = Medium.h_default "Initial specific enthalpy set value";
        parameter Utilities.Units.Inertance L = dropOfCommons.L "Inertance of inlet/outlet";
        parameter Real k_volume_damping(unit = "1", min = 0) = dropOfCommons.k_volume_damping "Damping factor multiplicator";
        parameter SI.MassFlowRate m_flow_assert(max = 0) = -dropOfCommons.m_flow_reg "Assertion threshold for negative massflow";
        parameter Boolean usePreferredMediumStates = false "=true, if preferred medium states are used" annotation(Evaluate = true, HideResult = true);
        Interfaces.Inlet inlet(redeclare package Medium = Medium);
        Interfaces.Outlet outlet[M_outlets](redeclare package Medium = Medium);
        Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort(Q_flow = Q_flow, T = T_heatPort) if useHeatport;
        Medium.BaseProperties medium(preferredMediumStates = usePreferredMediumStates);
        SI.Volume V "Volume";
        SI.Mass M(stateSelect = if usePreferredMediumStates then StateSelect.default else StateSelect.always) = V*medium.d "Mass";
        SI.Mass MXi[Medium.nXi](each stateSelect = if usePreferredMediumStates then StateSelect.default else StateSelect.always) = M*medium.Xi "Masses of species";
        SI.Energy U_med(stateSelect = if usePreferredMediumStates then StateSelect.default else StateSelect.always) = M*medium.u "Internal energy";
        SI.HeatFlowRate Q_flow "Heat flow rate";
        SI.Power W_v "Volumenänderungsarbeitsstrom (work due to change of volume)";
      protected
        SI.Pressure p_in = Medium.pressure(inlet.state) "Inlet pressure";
        SI.SpecificEnthalpy h_in = if noEvent(m_flow_in >= 0) then Medium.specificEnthalpy(inlet.state) else medium.h "Inlet specific enthalpy";
        Medium.MassFraction Xi_in[Medium.nXi] = if noEvent(m_flow_in >= 0) then Medium.massFraction(inlet.state) else medium.Xi "Inlet mass fractions";
        Medium.ThermodynamicState state_out[M_outlets] "States at outlets";
        SI.SpecificEnthalpy h_out[M_outlets] "Specific enthalpy at outlets";
        Medium.MassFraction Xi_out[Medium.nXi, M_outlets] "Mass fractions at outlets";
        Real d(unit = "1/(m.s)") = k_volume_damping*sqrt(abs(2*L/(V*max(density_derp_h, 1e-10)))) "Friction factor for coupled boundaries";
        SI.DerDensityByPressure density_derp_h "Partial derivative of density by pressure at constant specific enthalpy";
        SI.Pressure r_damping = d*der(M);
        SI.Pressure r "Inertial pressure";
        SI.Temperature T_heatPort "Heat port temperature";
        SI.MassFlowRate m_flow_in = inlet.m_flow "Inlet mass flow rate";
        SI.MassFlowRate m_flow_out[M_outlets] = outlet.m_flow "Mass flow rates at outlets";
      initial equation
        if initialize_pressure then
          medium.p = p_start;
        end if;
        if initialize_energy then
          if use_hstart then
            medium.h = h_start;
          else
            medium.T = T_start;
          end if;
        end if;
        if initialize_Xi then
          medium.Xi = Xi_0;
        end if;
      equation
        assert(m_flow_in > m_flow_assert, "Negative mass flow rate at volume inlet", dropOfCommons.assertionLevel);
        for i in 1:M_outlets loop
          assert(-m_flow_out[i] > m_flow_assert, "Positive mass flow rate at volume outlet", dropOfCommons.assertionLevel);
        end for;
        assert(M > 0, "Negative mass inside volume");
        der(inlet.m_flow)*L = inlet.r - r - r_damping;
        der(outlet.m_flow)*L = outlet.r - r_damping*ones(M_outlets);
        r + p_in = medium.p;
        for i in 1:M_outlets loop
          h_out[i] = if noEvent(-m_flow_out[i] >= 0) then Medium.specificEnthalpy(state_out[i]) else medium.h;
          Xi_out[:, i] = if noEvent(-m_flow_out[i] >= 0) then Medium.massFraction(state_out[i]) else medium.Xi;
        end for;
        der(M) = inlet.m_flow + sum(outlet.m_flow);
        der(U_med) = W_v + Q_flow + inlet.m_flow*h_in + sum(outlet.m_flow.*h_out);
        der(MXi) = Xi_in*inlet.m_flow + Xi_out*outlet.m_flow;
        Q_flow = U*A*(T_heatPort - medium.T);
        outlet.state = state_out;
        if not useHeatport then
          T_heatPort = medium.T;
        end if;
      end PartialVolumeM;

      type InitializationMethodsPhaseSeperator = enumeration(h "Specific enthalpy h_0", M "Mass M_0", l "Liquid Level l_0", x "Vapor Quality x_0") "Choices for initialization of state h of PhaseSeperator";
    end Internal;
  end Boundaries;

  package Topology
    model SplitterT1 "Splitter with one inlet and two outlets"
      extends ThermofluidStream.Utilities.DropOfCommonsPlus;
      replaceable package Medium = Media.myMedia.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
      parameter Utilities.Units.Inertance L = dropOfCommons.L "Inertance of each inlet/outlet";
      Interfaces.Inlet inlet(redeclare package Medium = Medium);
      Interfaces.Outlet outletA(redeclare package Medium = Medium);
      Interfaces.Outlet outletB(redeclare package Medium = Medium);
      SplitterN splitterN(final N = 2, final L = L, redeclare package Medium = Medium);
    equation
      connect(splitterN.inlet, inlet);
      connect(splitterN.outlets[2], outletA);
      connect(outletB, splitterN.outlets[1]);
    end SplitterT1;

    model SplitterT2 "Splitter with one inlet and two oulets"
      extends ThermofluidStream.Utilities.DropOfCommonsPlus;
      replaceable package Medium = Media.myMedia.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
      parameter Utilities.Units.Inertance L = dropOfCommons.L "Inertance of each inlet/outlet";
      Interfaces.Inlet inlet(redeclare package Medium = Medium);
      Interfaces.Outlet outletA(redeclare package Medium = Medium);
      Interfaces.Outlet outletB(redeclare package Medium = Medium);
      SplitterN splitterN(final N = 2, final L = L, redeclare package Medium = Medium);
    equation
      connect(splitterN.inlet, inlet);
      connect(splitterN.outlets[1], outletB);
      connect(outletA, splitterN.outlets[2]);
    end SplitterT2;

    model JunctionT2 "Junction with two inlets and one outlet"
      extends ThermofluidStream.Utilities.DropOfCommonsPlus;
      replaceable package Medium = Media.myMedia.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
      parameter Boolean assumeConstantDensity = true "= true, if mixture states are determined by mass flow rates" annotation(Evaluate = true, HideResult = true);
      parameter SI.MassFlowRate m_flow_eps = dropOfCommons.m_flow_reg "Regularization threshold for small mass flows";
      parameter Utilities.Units.Inertance L = dropOfCommons.L "Inertance of each inlet/outlet";
      Interfaces.Outlet outlet(redeclare package Medium = Medium);
      Interfaces.Inlet inletA(redeclare package Medium = Medium);
      Interfaces.Inlet inletB(redeclare package Medium = Medium);
      JunctionN junctionN(final N = 2, redeclare package Medium = Medium, final L = L, final assumeConstantDensity = assumeConstantDensity, final m_flow_eps = m_flow_eps);
    equation
      connect(junctionN.inlets[2], inletB);
      connect(inletA, junctionN.inlets[1]);
      connect(junctionN.outlet, outlet);
    end JunctionT2;

    model SplitterN "Splitter with one inlet and N outlets"
      extends ThermofluidStream.Utilities.DropOfCommonsPlus;
      replaceable package Medium = Media.myMedia.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
      parameter Integer N(min = 1) = 1 "Number of outputs";
      parameter Utilities.Units.Inertance L = dropOfCommons.L "Inertance of each inlet/outlet";
      Interfaces.Inlet inlet(redeclare package Medium = Medium) "Inlet";
      Interfaces.Outlet outlets[N](redeclare package Medium = Medium) "Vector of N outlets";
    protected
      SI.Pressure r_mix "Inertial pressure of mixture";
    equation
      der(inlet.m_flow)*L = inlet.r - r_mix;
      for i in 1:N loop
        der(outlets[i].m_flow)*L = outlets[i].r - r_mix;
        outlets[i].state = inlet.state;
      end for;
      sum(outlets.m_flow) + inlet.m_flow = 0;
    end SplitterN;

    model JunctionN "Junction with N inlets and one outlet"
      extends ThermofluidStream.Utilities.DropOfCommonsPlus;
      replaceable package Medium = Media.myMedia.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
      parameter Integer N(min = 1) = 1 "Number of inlets";
      parameter Boolean assumeConstantDensity = true "= true, if mixture states are determined by mass flow rates" annotation(Evaluate = true, HideResult = true);
      parameter SI.MassFlowRate m_flow_eps = dropOfCommons.m_flow_reg "Regularization threshold for small mass flows";
      parameter Utilities.Units.Inertance L = dropOfCommons.L "Inertance of each inlet/outlet";
      Interfaces.Inlet inlets[N](redeclare package Medium = Medium) "Vector of N inlets";
      Interfaces.Outlet outlet(redeclare package Medium = Medium) "Outlet";
      output Real w[N](each unit = "1") "Regularized weighting factor for specific enthalpy";
      output SI.Density rho[N] = Medium.density(inlets.state) "Density at inlets";
    protected
      SI.Pressure p[N] = Medium.pressure(inlets.state) "(Steady mass-flow) pressure at inlets";
      SI.SpecificEnthalpy h[N] = Medium.specificEnthalpy(inlets.state) "Specific enthapy at inlets";
      Medium.MassFraction Xi[Medium.nXi, N] "Mass factions at inlets";
      SI.Pressure p_mix "Outlet (steady mass-flow) pressure";
      SI.Pressure r_mix "Outlet inertial pressure";
      SI.SpecificEnthalpy h_mix "Outlet specific enthalpy";
      Medium.MassFraction Xi_mix[Medium.nXi] "Outlet mass fractions";
      Real w2[N](each unit = "1") "Regularized weighting factors for steady mass flow pressure";
      SI.Pressure r_in[N] "Inertial pressure of inlets";
      function mfk = Utilities.Functions.massFractionK(redeclare package Medium = Medium);
    equation
      sum(inlets.m_flow) + outlet.m_flow = 0;
      for i in 1:N loop
        der(inlets[i].m_flow)*L = inlets[i].r - r_in[i];
        for j in 1:Medium.nXi loop
          Xi[j, i] = mfk(inlets[i].state, j);
        end for;
        p[i] + r_in[i] = p_mix + r_mix;
        w[i] = (abs(inlets[i].m_flow) + m_flow_eps)/(sum(abs(inlets.m_flow)) + N*m_flow_eps);
        w2[i] = ((abs(inlets[i].m_flow) + m_flow_eps)/rho[i])/(sum((abs(inlets.m_flow) + m_flow_eps*ones(N))./rho));
      end for;
      der(outlet.m_flow)*L = outlet.r - r_mix;
      if not assumeConstantDensity then
        p_mix = sum(w2.*p);
      else
        p_mix = sum(w.*p);
      end if;
      h_mix = sum(w.*h);
      Xi_mix = Xi*w;
      outlet.state = Medium.setState_phX(p_mix, h_mix, Xi_mix);
    end JunctionN;

    package Internal end Internal;
  end Topology;

  package Processes "Process model package"
    model FlowResistance "Flow resistance model"
      extends Interfaces.SISOFlow(final L = if computeL then l/areaHydraulic else L_value, final clip_p_out = true);
      import Modelica.Constants.pi;
      import ThermofluidStream.Processes.Internal.ShapeOfResistance;
      replaceable function pLoss = Internal.FlowResistance.pleaseSelectPressureLoss constrainedby Internal.FlowResistance.partialPressureLoss;
      parameter SI.Length l(min = 0) "Length";
      parameter ShapeOfResistance shape = ThermofluidStream.Processes.Internal.ShapeOfResistance.circular "Cross section shape";
      parameter SI.Radius r(min = 0) = 0 "Radius";
      parameter SI.Length a(min = 0) = 0 "Rectangle width";
      parameter SI.Length b(min = 0) = 0 "Rectangle height";
      parameter SI.Area areaCrossInput(min = 0) = 0 "Cross-sectional area";
      parameter SI.Length perimeterInput(min = 0) = 0 "Wetted perimeter";
      parameter Boolean computeL = true "= true, if inertance L is computed from the geometry" annotation(Evaluate = true, HideResult = true);
      parameter Utilities.Units.Inertance L_value = dropOfCommons.L "Inertance";
      parameter SI.Density rho_min = dropOfCommons.rho_min "Minimal inlet density";
      final parameter SI.Length D_h = 4*areaCross/perimeter "Hydraulic diameter";
      final parameter SI.Length perimeter = if shape == ShapeOfResistance.circular then 2*pi*r elseif shape == ShapeOfResistance.rectangle then 2*a + 2*b else perimeterInput "Perimeter";
      final parameter SI.Area areaCross = if shape == ShapeOfResistance.circular then pi*r*r elseif shape == ShapeOfResistance.rectangle then a*b else areaCrossInput "Cross-sectional area";
      final parameter SI.Area areaHydraulic = pi*D_h*D_h*1/4 "Hydraulic cross-sectional area";
    protected
      SI.Density rho_in = max(rho_min, Medium.density(inlet.state)) "Inlet density";
      SI.DynamicViscosity mu_in = Medium.dynamicViscosity(inlet.state) "Inlet dynamic viscosity";
    equation
      dp = -pLoss(m_flow, rho_in, mu_in, D_h/2, l);
      h_out = h_in;
      Xi_out = Xi_in;
    end FlowResistance;

    model Pump "A simple pump model"
      extends Internal.PartialTurboComponent(redeclare function dp_tau = dp_tau_pump);
      parameter Real max_rel_volume(min = 0, max = 1, unit = "1") = 0.05 "Maximum relative volume change (checking incompressibility approach)";
      replaceable function dp_tau_pump = Internal.TurboComponent.pleaseSelect_dp_tau constrainedby Internal.TurboComponent.partial_dp_tau(redeclare package Medium = Medium);
      Real eta(unit = "1") = if noEvent(abs(W_t) > 1e-4) then dp*v_in*m_flow/W_t else 0.0 "Efficiency";
    protected
      SI.SpecificVolume v_out = 1/max(rho_min, Medium.density(inlet.state)) "Specific volume at outlet";
    equation
      assert(abs(v_in - v_out)/v_in < max_rel_volume, "Medium in pump is assumed to be incompressible, but check failed", dropOfCommons.assertionLevel);
    end Pump;

    model ConductionElement "Model of quasi-stationary mass and heat transfer"
      extends Internal.PartialConductionElement;
      parameter Boolean resistanceFromAU = true "= true, if thermal conductance is given by U*A" annotation(Evaluate = true, HideResult = true);
      parameter SI.Area A = 1 "Heat transfer area";
      parameter SI.CoefficientOfHeatTransfer U = 200 "Thermal transmittance";
      parameter SI.ThermalConductance k_par = 200 "Thermal conductance";
      final parameter SI.ThermalConductance k_internal = if resistanceFromAU then A*U else k_par;
      parameter Boolean displayVolume = true "= true, if volume V is displayed" annotation(Evaluate = true, HideResult = true);
      parameter Boolean displayConduction = true "= true, if thermal conductance is displayed" annotation(Evaluate = true, HideResult = true);
      final parameter Boolean displayAnything = displayParameters and (displayVolume or displayConduction) annotation(Evaluate = true, HideResult = true);
      final parameter String parameterString = if displayParameters and displayVolume and displayConduction then "V=%V, " + conductionString elseif displayParameters and displayVolume and not displayConduction then "V=%V"
       elseif displayParameters and not displayVolume and displayConduction then conductionString else "" annotation(Evaluate = true, HideResult = true);
      final parameter String conductionString = if resistanceFromAU then "A=%A, U=%U" else "k=%k_par" annotation(Evaluate = true, HideResult = true);
    equation
      k = k_internal;
    end ConductionElement;

    package Internal "Helper functions and models for Processes"
      package FlowResistance "Implementations of Flow Resistance functions"
        partial function partialPressureLoss "Partial pressure loss function"
          input SI.MassFlowRate m_flow "Mass flow rate";
          input SI.Density rho "Density";
          input SI.DynamicViscosity mu "Dynamic viscosity";
          input SI.Length r(min = 0) "Radius";
          input SI.Length l(min = 0) "Length";
          output SI.Pressure pressureLoss "pressure loss (dp)";
          annotation(Inline = true, smoothOrder = 100);
        end partialPressureLoss;

        function linearQuadraticPressureLoss "Linear-quadratic pressure loss function"
          extends Internal.FlowResistance.partialPressureLoss;
          input Real k(unit = "Pa.s/kg") = 0 "Linear resistance coefficient";
          input Real k2(unit = "(Pa.s.s)/(kg.kg)") = 0 "Quadratic resistance coefficient";
        algorithm
          pressureLoss := k*m_flow + k2*m_flow*abs(m_flow);
        end linearQuadraticPressureLoss;

        function laminarPressureLoss "Laminar pressure loss function (Hagen-Poiseuille)"
          extends Internal.FlowResistance.partialPressureLoss;
          import Modelica.Constants.pi;
        algorithm
          pressureLoss := m_flow*(8*mu*l)/(pi*rho*r^4);
        end laminarPressureLoss;

        function laminarTurbulentPressureLoss "Pressure loss function (Cheng 2008) for laminar, transient and turbulent flow regimes"
          extends Internal.FlowResistance.partialPressureLoss;
          import Modelica.Constants.pi;
          input SI.Length ks_input(min = 1e-7) = 1e-7 "Surface roughness";
          input ThermofluidStream.Processes.Internal.Material material = ThermofluidStream.Processes.Internal.Material.other "Material of pipe";
        protected
          constant SI.ReynoldsNumber R_laminar_DarcyWeisbach_min = 500 "Minimal Reynolds number to use the general equation. Laminar flow before";
          SI.Length ks "Surface roughness";
          Real a(unit = "1") "Laminar flow factor for the DarcyWeisbach equation (= 1 for laminar flow, = 0 for turbulent flow)";
          Real b(unit = "1") "Turbulent flow factor for the DarcyWeisbach equation (= 1 for fully smooth turbulent flow, = 0 for fully rough turbulent flow)";
          Real lambda_aux(unit = "1") "Darcy friction factor for Darcy-Weisbach equation";
          SI.Velocity u "Velocity";
          SI.ReynoldsNumber Re "Reynolds number";
          constant Real eps(unit = "1") = 0.001;
        algorithm
          if material == ThermofluidStream.Processes.Internal.Material.concrete then
            ks := 5e-3;
          elseif material == ThermofluidStream.Processes.Internal.Material.wood then
            ks := 0.5e-3;
          elseif material == ThermofluidStream.Processes.Internal.Material.castIron then
            ks := 0.25e-3;
          elseif material == ThermofluidStream.Processes.Internal.Material.galvanizedIron then
            ks := 0.15e-3;
          elseif material == ThermofluidStream.Processes.Internal.Material.steel then
            ks := 0.059e-3;
          elseif material == ThermofluidStream.Processes.Internal.Material.drawnPipe then
            ks := 0.0015e-3;
          else
            ks := ks_input;
          end if;
          assert(ks < r, "Surface roughness shall be smaller than pipe radius");
          u := m_flow/(r^2*pi*rho);
          Re := abs(u)*rho*2*r/mu + eps;
          a := 1/(1 + (Re/2720)^9);
          b := 1/(1 + (Re/(160*2*r/ks))^2);
          lambda_aux := 64^a*Re^(1 - a)*((1.8*log10(Re/6.8))^(2*(a - 1)*b)*(2*log10(3.7*2*r/ks))^(2*(a - 1)*(1 - b)));
          pressureLoss := lambda_aux*l*mu*u/(8*r^2);
        end laminarTurbulentPressureLoss;

        function laminarTurbulentPressureLossHaaland "Pressure loss function (Haaland 1983) for laminar, transient and turbulent flow regimes"
          extends Internal.FlowResistance.partialPressureLoss;
          import Modelica.Constants.pi;
          input SI.ReynoldsNumber Re_laminar = 2000 "Upper limit for laminar flow (Reynolds number)";
          input SI.ReynoldsNumber Re_turbulent = 4000 "Lower limit for turbulent flow (Reynolds number)";
          input Real shape_factor(unit = "1") = 64 "Laminar pressure loss factor (Hagen-Poiseuille)";
          input Real n(unit = "1") = 1 "Transition coefficient (see documentation)";
          input SI.Length ks_input(min = 1e-7) = 1e-7 "Surface roughness";
          input ThermofluidStream.Processes.Internal.Material material = ThermofluidStream.Processes.Internal.Material.other "Material of pipe";
        protected
          SI.Length ks "Surface roughness";
          SI.Length diameter = r*2 "Diameter";
          SI.Area area = pi*r^2 "Cross-sectional area";
          Real relative_roughness "Relative surface roughness";
          SI.ReynoldsNumber Re_abs "Absolute value of Reynolds number";
          SI.ReynoldsNumber Re_abs_limited "Limited absolute value of Reynolds number";
          Real friction_factor(unit = "1");
          SI.Pressure pressureLossLaminar "Laminar pressure loss";
          SI.Pressure pressureLossTurbulent "Turbulent pressure loss";
          constant SI.ReynoldsNumber Re_small = 1e-5 "Lower limit of turbulent Reynolds number to avoid division by zero";
        algorithm
          if material == ThermofluidStream.Processes.Internal.Material.concrete then
            ks := 5e-3;
          elseif material == ThermofluidStream.Processes.Internal.Material.wood then
            ks := 0.5e-3;
          elseif material == ThermofluidStream.Processes.Internal.Material.castIron then
            ks := 0.25e-3;
          elseif material == ThermofluidStream.Processes.Internal.Material.galvanizedIron then
            ks := 0.15e-3;
          elseif material == ThermofluidStream.Processes.Internal.Material.steel then
            ks := 0.059e-3;
          elseif material == ThermofluidStream.Processes.Internal.Material.drawnPipe then
            ks := 0.0015e-3;
          else
            ks := ks_input;
          end if;
          relative_roughness := ks/diameter;
          Re_abs := abs(m_flow)*diameter/(area*mu);
          Re_abs_limited := max(Re_small, min(1, Re_abs));
          friction_factor := (-1.8/n*log10((6.9/Re_abs_limited)^n + (relative_roughness/3.75)^(1.11*n)))^(-2);
          pressureLossLaminar := m_flow*mu*shape_factor*l/(2*rho*diameter^2*area);
          pressureLossTurbulent := m_flow*abs(m_flow)*friction_factor*l/(2*rho*diameter*area^2);
          pressureLoss := Utilities.Functions.blendFunction(y1 = pressureLossLaminar, y2 = pressureLossTurbulent, x1 = Re_laminar, x2 = Re_turbulent, x = Re_abs);
        end laminarTurbulentPressureLossHaaland;

        function pleaseSelectPressureLoss "Please select pressure loss function"
          extends Internal.FlowResistance.partialPressureLoss;
        algorithm
          assert(false, "Please select pressure loss function");
          pressureLoss := 0;
        end pleaseSelectPressureLoss;

        function zetaPressureLoss "Pressure loss coefficient function"
          extends Internal.FlowResistance.partialPressureLoss;
          input Real zeta(unit = "1") "Pressure loss coefficient (dp = zeta*rho/2*v^2)";
          input Boolean fromGeometry = true "= true, if cross-sectional area if calculated from geometry" annotation(Evaluate = true, HideResult = true);
          input SI.Area A = Modelica.Constants.pi*r*r "Cross-sectional area";
        protected
          SI.Area A_zeta "Cross-sectional area";
        algorithm
          if fromGeometry then
            A_zeta := Modelica.Constants.pi*r*r;
          else
            A_zeta := A;
          end if;
          pressureLoss := zeta/(2*rho)*Modelica.Fluid.Utilities.regSquare(m_flow/A_zeta);
        end zetaPressureLoss;

        function referencePressureLoss "Pressure loss function based on reference values"
          extends Internal.FlowResistance.partialPressureLoss;
          input SI.Pressure dp_ref "Reference pressure loss";
          input SI.MassFlowRate m_flow_ref "Reference mass flow rate";
          input SI.Density rho_ref "Reference density";
          input ThermofluidStream.Processes.Internal.ReferencePressureDropFunction dp_function = ThermofluidStream.Processes.Internal.ReferencePressureDropFunction.linear "Pressure loss function";
          input Real m(unit = "1") = 1.5 "Exponent for pressure loss function";
        algorithm
          if dp_function == ThermofluidStream.Processes.Internal.ReferencePressureDropFunction.linear then
            pressureLoss := rho_ref/rho*dp_ref*m_flow/m_flow_ref;
          elseif dp_function == ThermofluidStream.Processes.Internal.ReferencePressureDropFunction.quadratic then
            pressureLoss := rho_ref/rho*dp_ref*Modelica.Fluid.Utilities.regSquare(m_flow/m_flow_ref);
          elseif dp_function == ThermofluidStream.Processes.Internal.ReferencePressureDropFunction.customExponent then
            pressureLoss := rho_ref/rho*dp_ref*Modelica.Fluid.Utilities.regPow(m_flow/m_flow_ref, m);
          else
          end if;
        end referencePressureLoss;
      end FlowResistance;

      package TurboComponent "Helper functions for all turbo component models"
        partial function partial_dp_tau "Compute dp and tau_st of a TurboComponent from the current state"
          replaceable package Medium = Media.myMedia.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
          input Medium.MassFlowRate m_flow "Mass flow rate";
          input SI.AngularVelocity omega "Angular velocity";
          input Medium.ThermodynamicState state_in "Inlet state";
          input Medium.MassFlowRate m_flow_norm "Normalization mass flow rate";
          input SI.AngularVelocity omega_norm "Normalization angular velocity";
          input Medium.Density rho_min "Minimum density (relevant at p=0)";
          output SI.Pressure dp "Pressure difference";
          output SI.Torque tau_st "Steady state torque";
          annotation(Inline = true);
        end partial_dp_tau;

        function dp_tau_centrifugal "Model of a centrifugal pump"
          extends partial_dp_tau;
          import Modelica.Constants.g_n;
          input Boolean parametrizeByScaling = true "= true, if pump characteristic curve is computed from one design point";
          input SI.Height TDH_D = 3.6610 "Design pressure head (max efficiency)";
          input SI.VolumeFlowRate V_flow_D = 3.06e-3 "Design volume flow (max efficiency)";
          input SI.AngularVelocity omega_D = 314.2 "Design angular velocity";
          input Real K_D_input(unit = "m3/rad") = 9.73e-06 "Vflow_D / omega_D";
          input Integer f_q_input = 1 "Number of floods";
          input SI.Radius r_input = 1.60e-2 "Pump radius (r2)";
          input SI.Density rho_ref_input = 1.00e3 "Reference density";
          input Real a_h_input(unit = "m.s2/rad2", displayUnit = "m.min2") = 4.864e-5 "HQ factor 1";
          input Real b_h_input(unit = "s2/(m2.rad)", displayUnit = "m.h.min/l") = -2.677 "HQ factor 2";
          input Real c_h_input(unit = "s2/m5", displayUnit = "m.h2/l2") = 3.967e+5 "HQ factor 3";
          input Real a_t_input(unit = "N.m.s2/(rad.m3)", displayUnit = "N.m.min.h/l") = 5.427e-1 "TQ factor 1";
          input Real b_t_input(unit = "N.m.s2/m6", displayUnit = "N.m.h2/l2") = 2.777e+4 "TQ factor 2";
          input Real v_i_input(unit = "N.m.s2/rad2", displayUnit = "N.m.min2") = 1.218e-6 "TQ factor 4";
          input Real v_s_input(unit = "N.m.s/rad", displayUnit = "N.m.min") = 1.832e-4 "TQ factor 3";
          input Real Re_mod_min(unit = "1") = 1e2 "Minimum modified Reynolds number";
        protected
          Real alpha(unit = "1") = TDH_D/TDH_D_ref "Pressure scaling factor";
          Real beta(unit = "1") = omega_D/omega_D_ref "Speed scaling factor";
          Real gamma(unit = "1") = V_flow_D/V_flow_D_ref "Flow scaling factor";
          SI.SpecificVolume v_in = 1/max(rho_min, Medium.density(state_in)) "Inlet specific volume";
          SI.SpecificVolume mu_in = Medium.dynamicViscosity(state_in) "Inlet dynamic viscosity";
          SI.SpecificVolume v_ref = 1/rho_ref "Reference specific volume";
          SI.Power W_t "Power (technical work flow rate)";
          SI.Length TDH "Total dynamic head";
          SI.VolumeFlowRate V_flow "Volume flow rate";
          constant SI.AngularVelocity omega_D_ref = 314.2 "Design angular velocity of reference pump";
          constant SI.VolumeFlowRate V_flow_D_ref = 3.06e-3 "Design volume flow rate (max efficiency) of reference pump";
          constant SI.Height TDH_D_ref = 3.6610 "Design total dynamic head (max efficiency) of reference pump";
          constant Real a_h_ref(unit = "m.s2/rad2") = 4.864e-5 "HQ factor 1";
          constant Real b_h_ref(unit = "s2/(m2.rad)") = -2.677 "HQ factor 2";
          constant Real c_h_ref(unit = "s2/m5") = 3.967e+5 "HQ factor 3";
          constant Real a_t_ref(unit = "N.m.s2/(rad.m3)") = 5.427e-1 "TQ factor 1";
          constant Real b_t_ref(unit = "N.m.s2/m6") = 2.777e+4 "TQ factor 2";
          constant Real v_i_ref(unit = "N.m.s2/rad2") = 1.218e-6 "TQ factor 4";
          constant Real v_s_ref(unit = "N.m.s/rad") = 1.832e-4 "TQ factor 3";
          constant Integer f_q_ref = 1 "Number of floods of reference pump";
          constant Real K_D_ref(unit = "m3/rad") = 9.73e-06 "Vflow_D / omega_D for reference pump";
          constant SI.Density rho_ref_ref = 1.00e3 "Reference density of reference pump";
          constant SI.Length r_ref = 1.60e-2 "Radius of reference pump (r2)";
          Real a_h(unit = "m.s2/rad2") = if parametrizeByScaling then alpha/(beta^2)*a_h_ref else a_h_input "HQ factor 1";
          Real b_h(unit = "s2/(m2.rad)") = if parametrizeByScaling then alpha/(beta*gamma)*b_h_ref else b_h_input "HQ factor 2";
          Real c_h(unit = "s2/m5") = if parametrizeByScaling then alpha/(gamma^2)*c_h_ref else c_h_input "HQ factor 3";
          Real a_t(unit = "N.m.s2/(rad.m3)") = if parametrizeByScaling then alpha/(beta^2)*a_t_ref else a_t_input "TQ factor 1";
          Real b_t(unit = "N.m.s2/m6") = if parametrizeByScaling then alpha/(beta*gamma)*b_t_ref else b_t_input "TQ factor 2";
          Real v_i(unit = "N.m.s2/rad2") = if parametrizeByScaling then sqrt(alpha)*gamma/beta*v_i_ref else v_i_input "TQ factor 4";
          Real v_s(unit = "N.m.s/rad") = if parametrizeByScaling then alpha^(-1/4)*beta^(1/2)*gamma^(3/2)*v_s_ref else v_s_input "TQ factor 3";
          Integer f_q = if parametrizeByScaling then f_q_ref else f_q_input "Number of floods";
          Real K_D(unit = "m3/rad") = if parametrizeByScaling then gamma/beta*K_D_ref else f_q_input "Vflow_D / omega_D";
          SI.Density rho_ref = if parametrizeByScaling then rho_ref_ref else rho_ref_input "Reference density";
          SI.Length r = if parametrizeByScaling then sqrt(alpha)/beta*r_ref else r_input "Pump radius (r2)";
          Real omega_s(unit = "1") = ((K_D/f_q)^0.5)/((g_n*(a_h + b_h*K_D + c_h*K_D^2))^0.75) "specific speed (using angular velocity)";
          SI.VolumeFlowRate V_flow_BEP "optimal volume flow at omega";
          SI.AngularVelocity omega_hat "abs omega clipped Re_mod_min";
          Real Re_mod(unit = "1") "Modified Reynolds number";
          Real f_Q(unit = "1") "Scaling factor for volume flow rate";
          Real f_H(unit = "1") "Scaling factor for head";
          Real f_eta(unit = "1") "Scaling factor for efficiency";
        algorithm
          omega_hat := max(Re_mod_min/(omega_s^1.5*f_q^0.75)/r^2*mu_in, abs(omega));
          V_flow_BEP := K_D*omega_hat;
          Re_mod := (omega_hat*r^2)/(mu_in)*(omega_s^1.5*f_q^0.75);
          f_Q := Re_mod^(-6.7/(Re_mod^0.735));
          f_eta := Re_mod^(-19/(Re_mod^0.705));
          V_flow := v_in*m_flow/f_Q;
          f_H := 1 - (1 - f_Q)*abs(V_flow/V_flow_BEP)^0.75;
          TDH := f_H*(a_h*omega*abs(omega) - b_h*omega*abs(V_flow) - c_h*V_flow*abs(V_flow));
          tau_st := (f_Q*f_H/f_eta)*(v_ref/v_in*(a_t*V_flow*abs(omega) - b_t*V_flow*abs(V_flow) + v_i*omega*abs(omega))) + v_s*abs(omega);
          dp := g_n*TDH/v_in;
        end dp_tau_centrifugal;

        function dp_tau_nominal_flow "Pump model with the nominal massflow model"
          extends partial_dp_tau;
          input Boolean parametrizeByDesignPoint = false "= true, if pump characteristic curve is computed from one design point";
          input SI.Pressure dp_D = 500000 "Design pressure difference";
          input SI.VolumeFlowRate V_flow_D(displayUnit = "l/min") = 0.0016666666666667 "Design volume flow rate";
          input SI.AngularVelocity omega_D = 314.2 "Design angular velocity";
          input Real slip_D(unit = "1", min = 0, max = 1) = 0.5 "Design slip ((V_flow_nominal-V_flow)/V_flow_nominal)";
          input Real eta_D(unit = "1", min = 0.001, max = 1) = 0.75 "Design efficiency";
          input SI.Volume V_r_input = 0.0001 "Reference volume of pump";
          input Real k_p_input(unit = "N.s/(m5)") = 1e5 "Linear pressure factor";
          input Real k_fric_input(unit = "N.s/(m2)") = 1e-2 "Linear friction factor";
        protected
          SI.SpecificVolume v_in = 1/max(rho_min, Medium.density(state_in)) "Inlet specific volume";
          SI.VolumeFlowRate V_flow_nominal "Nominal volume flow rate";
          SI.VolumeFlowRate V_flow "Volume flow rate";
          SI.Volume V_r = if parametrizeByDesignPoint then V_flow_D*radPrevolution/omega_D/(1 - slip_D) else V_r_input "Pump volume";
          Real k_p(unit = "N.s/(m5)") = if parametrizeByDesignPoint then dp_D/(slip_D/(1 - slip_D)*V_flow_D) else k_p_input "Linear pressure factor";
          Real k_fric(unit = "N.s/(m2)") = if parametrizeByDesignPoint then (dp_D*(1 - slip_D))/(slip_D*omega_D)*(1/eta_D - 1) else k_fric_input "Linear frication factor";
          constant Real radPrevolution(unit = "rad") = 2*Modelica.Constants.pi;
        algorithm
          V_flow := v_in*m_flow;
          V_flow_nominal := omega*V_r/radPrevolution;
          dp := k_p*(V_flow_nominal - V_flow);
          tau_st := V_flow*dp*omega/(omega^2 + omega_norm^2) + k_fric*(V_flow_nominal - V_flow);
        end dp_tau_nominal_flow;

        function pleaseSelect_dp_tau "Please select dp_tau function"
          extends partial_dp_tau;
        algorithm
          assert(false, "please select dp_tau function");
          dp := 0;
          tau_st := 0;
        end pleaseSelect_dp_tau;
      end TurboComponent;

      partial model PartialTurboComponent "Partial model of turbo component"
        extends Interfaces.SISOFlow(m_flowStateSelect = StateSelect.prefer, final clip_p_out = true);
        import ThermofluidStream.Utilities.Types.InitializationMethods;
        import Quantity = ThermofluidStream.Sensors.Internal.Types.MassFlowQuantities;
        parameter Boolean omega_from_input = false "= true, if omega input connector is enabled" annotation(Evaluate = true, HideResult = true);
        parameter Boolean enableAccessHeatPort = false "= true, if heatPort is enabled" annotation(Evaluate = true, HideResult = true);
        parameter SI.MomentOfInertia J_p = 5e-4 "Moment of inertia";
        parameter Boolean enableOutput = false "= true, if selectable quantity output connector is enabled" annotation(Evaluate = true, HideResult = true);
        parameter Quantity outputQuantity = Quantity.m_flow_kgps "Output quantity";
        parameter SI.AngularVelocity omega_reg = dropOfCommons.omega_reg "Normalization angular velocity";
        parameter SI.MassFlowRate m_flow_reg = dropOfCommons.m_flow_reg "Normalization mass flow rate";
        parameter SI.Density rho_min = dropOfCommons.rho_min "Minimum density (relevant at p=0)";
        parameter StateSelect omegaStateSelect = if omega_from_input then StateSelect.default else StateSelect.prefer "State select for angular velocity";
        parameter InitializationMethods initOmega = ThermofluidStream.Utilities.Types.InitializationMethods.none "Initialization method for angular velocity";
        parameter SI.AngularVelocity omega_0 = 0 "Initial value for angular velocity";
        parameter SI.AngularAcceleration omega_dot_0 = 0 "Initial value for der(omega)";
        parameter Boolean initPhi = false "= true, if angle is initialized" annotation(Evaluate = true, HideResult = true);
        parameter SI.Angle phi_0 = 0 "Initial value for angle";
        Modelica.Mechanics.Rotational.Interfaces.Flange_a flange(phi = phi, tau = tau) if not omega_from_input "Flange";
        Modelica.Blocks.Interfaces.RealInput omega_input(unit = "rad/s") = omega if omega_from_input "Angular velocity input connector [rad/s]";
        Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatport(Q_flow = Q_t) if enableAccessHeatPort "HeatPort";
        Modelica.Blocks.Interfaces.RealOutput output_val(unit = Sensors.Internal.getFlowUnit(outputQuantity)) = getQuantity(inlet.state, m_flow, outputQuantity, rho_min) if enableOutput "Quantity output connector";
        replaceable function dp_tau = TurboComponent.pleaseSelect_dp_tau constrainedby TurboComponent.partial_dp_tau(redeclare package Medium = Medium);
        function getQuantity = Sensors.Internal.getFlowQuantity(redeclare package Medium = Medium) "Function to compute a selectable quantity";
        SI.Power W_t "Power (technichal work flow rate)";
        SI.Power Q_t "Heat flow rate";
        SI.Torque tau_st "Steady-state torque";
      protected
        SI.SpecificVolume v_in = 1/max(rho_min, Medium.density(inlet.state)) "Inlet specific volume";
        SI.SpecificEnergy dh "Difference of specific enthalpy";
        SI.Angle phi "Angle";
        SI.AngularVelocity omega(stateSelect = omegaStateSelect) "Angular velocity";
        SI.Torque tau "Torque";
        SI.Torque tau_normalized "Normalized torque";
      initial equation
        if initOmega == InitializationMethods.state then
          omega = omega_0;
        elseif initM_flow == InitializationMethods.derivative then
          der(omega) = omega_dot_0;
        elseif initM_flow == InitializationMethods.steadyState then
          der(omega) = 0;
        end if;
        if initPhi then
          phi = phi_0;
        end if;
      equation
        (dp, tau_st) = dp_tau(m_flow, omega, inlet.state, m_flow_reg, omega_reg, rho_min);
        h_out = h_in + dh;
        Xi_out = Xi_in;
        W_t = tau_st*omega;
        dh = (m_flow*W_t)/(m_flow^2 + (m_flow_reg)^2);
        if noEvent(W_t >= 0) then
          Q_t = W_t - m_flow*dh;
          tau_normalized = tau_st;
        else
          Q_t = 0;
          tau_normalized = dh*m_flow/(noEvent(if abs(omega) > omega_reg then omega else (if omega < 0 then -omega_reg else omega_reg)));
        end if;
        if noEvent(omega_from_input) then
          tau = 0;
          phi = 0;
        else
          J_p*der(omega) = tau - tau_normalized;
          omega = der(phi);
        end if;
      end PartialTurboComponent;

      partial model PartialConductionElement "Partial model of quasi-stationary mass and heat transfer"
        extends Interfaces.SISOFlow(final clip_p_out = false);
        parameter SI.Volume V(displayUnit = "l") = 0.001 "Volume";
        parameter Internal.InitializationMethodsCondElement init = ThermofluidStream.Processes.Internal.InitializationMethodsCondElement.inlet "Initialization for specific enthalpy";
        parameter Medium.Temperature T_0 = Medium.T_default "Initial Temperature";
        parameter SI.SpecificEnthalpy h_0 = Medium.h_default "Initial specific enthalpy";
        parameter SI.Density rho_min = dropOfCommons.rho_min "Minimal density";
        parameter Boolean neglectPressureChanges = true "=true, if pressure changes are neglected" annotation(Evaluate = true, HideResult = true);
        parameter SI.MassFlowRate m_flow_assert(max = 0) = -dropOfCommons.m_flow_reg "Assertion threshold for negative massflows";
        parameter Boolean enforce_global_energy_conservation = false "= true, if global conservation of energy is enforced" annotation(Evaluate = true, HideResult = true);
        parameter SI.Time T_e = 100 "Time constant for global conservation of energy";
        Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort(Q_flow = Q_flow, T = T_heatPort);
        SI.SpecificEnthalpy h(start = Medium.h_default, stateSelect = StateSelect.prefer) "Volume? specific enthalpy";
        Medium.ThermodynamicState state = Medium.setState_phX(p_in, h, Xi_in) "Volume thermodynamic state";
        SI.Temperature T = Medium.temperature(state) "Volume temperature";
        SI.ThermalConductance k "Thermal conductance";
        SI.Energy deltaE_system(start = 0, fixed = true) "Energy difference between m_flow*(h_in-h_out) and Q_flow";
        SI.Mass M "Mass (of the volume)";
      protected
        SI.Density rho = max(rho_min, Medium.density(state)) "Volume density";
        SI.SpecificEnthalpy h_in_norm = if noEvent(inlet.m_flow >= 0) then h_in else h "Inlet specific enthalpy";
        SI.Temperature T_heatPort "Heatport Temperature";
        SI.HeatFlowRate Q_flow "Heat flow rate";
      initial equation
        if init == Internal.InitializationMethodsCondElement.T then
          h = Medium.specificEnthalpy(Medium.setState_pTX(p_in, T_0, Xi_in));
        elseif init == Internal.InitializationMethodsCondElement.h then
          h = h_0;
        else
          h = Medium.specificEnthalpy(inlet.state);
        end if;
      equation
        assert(noEvent(inlet.m_flow > m_flow_assert), "Negative mass flow rate at inlet", dropOfCommons.assertionLevel);
        M = V*rho;
        if not neglectPressureChanges then
          M*der(h) = Q_flow + m_flow*(h_in_norm - h) + V*der(p_in) + (if enforce_global_energy_conservation then deltaE_system/T_e else 0);
        else
          M*der(h) = Q_flow + m_flow*(h_in_norm - h) + (if enforce_global_energy_conservation then deltaE_system/T_e else 0);
        end if;
        if enforce_global_energy_conservation then
          der(deltaE_system) = Q_flow + m_flow*(h_in_norm - h);
        else
          deltaE_system = 0;
        end if;
        Q_flow = k*(T_heatPort - T);
        dp = 0;
        h_out = h;
        Xi_out = Xi_in;
      end PartialConductionElement;

      type InitializationMethodsCondElement = enumeration(T "Temperature T_0", h "Specific enthalpy h_0", inlet "Inlet state") "Choices for initialization of state h of ConductionElement";
      type Material = enumeration(other "Other", concrete "Concrete, ks = 5 mm", wood "Wood, ks = 0.5 mm", castIron "Cast iron, ks = 0.25 mm", galvanizedIron "Galvanized iron, ks = 0.15 mm", steel "Steel, ks = 0.059 mm", drawnPipe "Drawn pipe ks = 0.0015 mm") "Material list with known roughnesses: todo make record of it";
      type ShapeOfResistance = enumeration(circular "Circular", rectangle "Rectangular", other "Other") "Provides the choice of different shapes for cross section";
      type ReferencePressureDropFunction = enumeration(linear "Linear", quadratic "Quadratic", customExponent "Custom exponent") "Provides the choice of linear or quadratic pressure loss functions";
    end Internal;
  end Processes;

  package FlowControl "Package for flow control components"
    model TanValve "Valve with tan-shaped flow resistance"
      extends Interfaces.SISOFlow(final clip_p_out = true);
      Modelica.Blocks.Interfaces.RealInput u(unit = "1") "Valve control signal []";
      parameter Utilities.Units.Inertance L = dropOfCommons.L "Inertance";
      parameter Boolean invertInput = false "= true, if input u_in is inverted" annotation(Evaluate = true, HideResult = true);
      parameter SI.MassFlowRate m_flow_ref = 0.1 "Reference mass flow rate";
      parameter SI.Pressure p_ref = 1e5 "Reference pressure";
      parameter Real relativeLeakiness(unit = "1") = 1e-3 "Imperfection of valve";
    protected
      Real k(unit = "(Pa.s)/kg");
      Real u2(unit = "1");
    equation
      if invertInput then
        u2 = max(relativeLeakiness, min(1 - relativeLeakiness, u));
      else
        u2 = max(relativeLeakiness, min(1 - relativeLeakiness, 1 - u));
      end if;
      k = p_ref/m_flow_ref*tan(u2*Modelica.Constants.pi/2);
      dp = -k*inlet.m_flow;
      h_out = h_in;
      Xi_out = Xi_in;
    end TanValve;

    package Internal "Internal models, functions and reckords for FlowControl"
      package Types end Types;
    end Internal;
  end FlowControl;

  package Sensors "Package containing sensors for the thermofluid simulation"
    model SingleFlowSensor "Flow rate sensor"
      extends ThermofluidStream.Utilities.DropOfCommonsPlus(displayInstanceName = false);
      import Quantities = ThermofluidStream.Sensors.Internal.Types.MassFlowQuantities;
      import InitMode = ThermofluidStream.Sensors.Internal.Types.InitializationModelSensor;
      replaceable package Medium = Media.myMedia.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
      parameter Integer digits(min = 0) = 1 "Number of displayed digits";
      parameter Quantities quantity "Measured quantity";
      final parameter String quantityString = if quantity == ThermofluidStream.Sensors.Internal.Types.MassFlowQuantities.m_flow_kgps then "m_flow in kg/s" elseif quantity == ThermofluidStream.Sensors.Internal.Types.MassFlowQuantities.m_flow_gps then "m_flow in g/s"
       elseif quantity == ThermofluidStream.Sensors.Internal.Types.MassFlowQuantities.V_flow_m3ps then "V_flow in m3/s"
       elseif quantity == ThermofluidStream.Sensors.Internal.Types.MassFlowQuantities.V_flow_lpMin then "V_flow in l/min"
       elseif quantity == ThermofluidStream.Sensors.Internal.Types.MassFlowQuantities.H_flow_Jps then "H_flow in W"
       elseif quantity == ThermofluidStream.Sensors.Internal.Types.MassFlowQuantities.S_flow_JpKs then "S_flow in W/K"
       elseif quantity == ThermofluidStream.Sensors.Internal.Types.MassFlowQuantities.Cp_flow_JpKs then "Cp_flow in W/K" else "error";
      parameter SI.Density rho_min = dropOfCommons.rho_min "Minimum density";
      parameter Boolean outputValue = false "= true, if sensor output is enabled" annotation(Evaluate = true, HideResult = true);
      parameter Boolean filter_output = false "= true, if sensor output is filtered (to break algebraic loops)" annotation(Evaluate = true, HideResult = true);
      parameter SI.Time TC = 0.1 "Time constant of sensor output filter (PT1)";
      parameter InitMode init = InitMode.steadyState "Initialization mode for sensor output";
      parameter Real value_0(unit = Internal.getFlowUnit(quantity)) = 0 "Start value of sensor output";
      Interfaces.Inlet inlet(redeclare package Medium = Medium);
      Interfaces.Outlet outlet(redeclare package Medium = Medium);
      Modelica.Blocks.Interfaces.RealOutput value_out(unit = Internal.getFlowUnit(quantity)) = value if outputValue "Sensor output connector";
      output Real value(unit = Internal.getFlowUnit(quantity));
    protected
      Real direct_value(unit = Internal.getFlowUnit(quantity));
      output SI.MassFlowRate m_flow = inlet.m_flow;
      function getQuantity = Internal.getFlowQuantity(redeclare package Medium = Medium) "Quantity compute function";
    initial equation
      if filter_output and init == InitMode.steadyState then
        value = direct_value;
      elseif filter_output then
        value = value_0;
      end if;
    equation
      inlet.m_flow + outlet.m_flow = 0;
      outlet.r = inlet.r;
      outlet.state = inlet.state;
      direct_value = getQuantity(inlet.state, inlet.m_flow, quantity, rho_min);
      if filter_output then
        der(value)*TC = direct_value - value;
      else
        value = direct_value;
      end if;
    end SingleFlowSensor;

    model MultiSensor_Tp "Temperature and pressure sensor"
      extends ThermofluidStream.Utilities.DropOfCommonsPlus(displayInstanceName = false);
      import InitMode = ThermofluidStream.Sensors.Internal.Types.InitializationModelSensor;
      replaceable package Medium = Media.myMedia.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
      parameter Integer digits(min = 0) = 1 "Number of displayed digits";
      parameter ThermofluidStream.Sensors.Internal.Types.TemperatureUnit temperatureUnit = "K" "Temperature unit (display and output)" annotation(choicesAllMatching = true, Evaluate = true);
      parameter ThermofluidStream.Sensors.Internal.Types.PressureUnit pressureUnit = "Pa" "Pressure unit (display and output)" annotation(choicesAllMatching = true, Evaluate = true);
      final parameter String temperatureString = if temperatureUnit == "K" then "K" elseif temperatureUnit == "degC" then "°C" else "error";
      parameter Boolean outputTemperature = false "= true, if temperature output is enabled" annotation(Evaluate = true, HideResult = true);
      parameter Boolean outputPressure = false "= true, if pressure output is enabled" annotation(Evaluate = true, HideResult = true);
      parameter Boolean filter_output = false "= true, if sensor output is filtered (to break algebraic loops)" annotation(Evaluate = true, HideResult = true);
      parameter SI.Time TC = 0.1 "Time constant of sensor output filter (PT1)";
      parameter InitMode init = InitMode.steadyState "Initialization mode for sensor output";
      parameter Real T_0(final quantity = "ThermodynamicTemperature", final unit = temperatureUnit) = 0 "Start value for temperature output";
      parameter Real p_0(final quantity = "Pressure", final unit = pressureUnit) = 0 "Start value for pressure output";
      Interfaces.Inlet inlet(redeclare package Medium = Medium);
      Modelica.Blocks.Interfaces.RealOutput T_out(final quantity = "ThermodynamicTemperature", final unit = temperatureUnit) = T if outputTemperature "Temperature output connector";
      Modelica.Blocks.Interfaces.RealOutput p_out(final quantity = "Pressure", final unit = pressureUnit) = p if outputPressure "Pressure output connector";
      output Real p(final quantity = "Pressure", final unit = pressureUnit);
      output Real T(final quantity = "ThermodynamicTemperature", final unit = temperatureUnit);
      Real direct_p;
      Real direct_T;
    initial equation
      if filter_output and init == InitMode.steadyState then
        p = direct_p;
        T = direct_T;
      elseif filter_output then
        p = p_0;
        T = T_0;
      end if;
    equation
      inlet.m_flow = 0;
      if temperatureUnit == "K" then
        direct_T = Medium.temperature(inlet.state);
      elseif temperatureUnit == "degC" then
        direct_T = Modelica.Units.Conversions.to_degC(Medium.temperature(inlet.state));
      end if;
      if pressureUnit == "Pa" then
        direct_p = Medium.pressure(inlet.state);
      elseif pressureUnit == "bar" then
        direct_p = Modelica.Units.Conversions.to_bar(Medium.pressure(inlet.state));
      end if;
      if filter_output then
        der(p)*TC = direct_p - p;
        der(T)*TC = direct_T - T;
      else
        p = direct_p;
        T = direct_T;
      end if;
    end MultiSensor_Tp;

    model TwoPhaseSensorSelect "Selectable Sensor for two phase medium"
      extends ThermofluidStream.Utilities.DropOfCommonsPlus(displayInstanceName = false);
      import Quantities = ThermofluidStream.Sensors.Internal.Types.TwoPhaseQuantities;
      import InitMode = ThermofluidStream.Sensors.Internal.Types.InitializationModelSensor;
      replaceable package Medium = Media.myMedia.Interfaces.PartialTwoPhaseMedium "Medium model" annotation(choicesAllMatching = true);
      parameter Integer digits(min = 0) = 1 "Number of displayed digits";
      parameter Quantities quantity "Measured quantity";
      final parameter String quantityString = if quantity == ThermofluidStream.Sensors.Internal.Types.TwoPhaseQuantities.x_kgpkg then "x in kg/kg" elseif quantity == ThermofluidStream.Sensors.Internal.Types.TwoPhaseQuantities.T_sat_K then "T_sat in K"
       elseif quantity == ThermofluidStream.Sensors.Internal.Types.TwoPhaseQuantities.T_sat_C then "T_sat in °C"
       elseif quantity == ThermofluidStream.Sensors.Internal.Types.TwoPhaseQuantities.p_sat_Pa then "p_sat in Pa"
       elseif quantity == ThermofluidStream.Sensors.Internal.Types.TwoPhaseQuantities.p_sat_bar then "p_sat in bar"
       elseif quantity == ThermofluidStream.Sensors.Internal.Types.TwoPhaseQuantities.T_oversat_K then "T - T_sat in K"
       elseif quantity == ThermofluidStream.Sensors.Internal.Types.TwoPhaseQuantities.p_oversat_Pa then "p - p_sat in Pa"
       elseif quantity == ThermofluidStream.Sensors.Internal.Types.TwoPhaseQuantities.p_oversat_bar then "p - p_sat in bar" else "error";
      parameter Boolean outputValue = false "= true, if sensor output is enabled" annotation(Evaluate = true, HideResult = true);
      parameter Boolean filter_output = false "= true, if sensor output is filtered (to break algebraic loops)" annotation(Evaluate = true, HideResult = true);
      parameter SI.Time TC = 0.1 "Time constant of sensor output filter (PT1)";
      parameter InitMode init = InitMode.steadyState "Initialization mode for sensor output";
      parameter Real value_0(unit = Internal.getTwoPhaseUnit(quantity)) = 0 "Start value of sensor output";
      Interfaces.Inlet inlet(redeclare package Medium = Medium);
      Modelica.Blocks.Interfaces.RealOutput value_out(unit = Internal.getTwoPhaseUnit(quantity)) = value if outputValue "Sensor output connector";
      output Real value(unit = Internal.getTwoPhaseUnit(quantity)) "Computed value of the selected quantity [variable]";
    protected
      Real direct_value(unit = Internal.getTwoPhaseUnit(quantity));
      function getQuantity = Internal.getTwoPhaseQuantity(redeclare package Medium = Medium) "Quantity compute function";
    initial equation
      if filter_output and init == InitMode.steadyState then
        value = direct_value;
      elseif filter_output then
        value = value_0;
      end if;
    equation
      inlet.m_flow = 0;
      direct_value = getQuantity(inlet.state, quantity);
      if filter_output then
        der(value)*TC = direct_value - value;
      else
        value = direct_value;
      end if;
    end TwoPhaseSensorSelect;

    package Internal "Helper functions for sensor package"
      package Types "Types used in the Sensor Package"
        type TemperatureUnit
          extends String;
        end TemperatureUnit;

        type PressureUnit
          extends String;
        end PressureUnit;

        type Quantities = enumeration(T_K "Temperature (K)", T_C "Temperature (°C)", p_Pa "Steadystate pressure (Pa)", p_bar "Steadystate pressure (bar)", rho_kgpm3 "Density (kg/m3)", v_m3pkg "Specific volume (m3/kg)", h_Jpkg "Specific enthalpy (J/kg)", s_JpkgK "Specific entropy (J/(kg.K))", cp_JpkgK "Specific isobaric heatcapacity (J/(kg.K))", cv_JpkgK "Specific isochoric heatcapacity (J/(kg.K))", kappa_1 "Isentropic Exponent (1))", a_mps "Velocity of sound (m/s)", MM_kgpmol "Molar Mass (kg/mol)", r_Pa "Inertial pressure (Pa)", r_bar "Inertial pressure (bar)", p_total_Pa "Steadystate pressure + inertial pressure (Pa)", p_total_bar "Steadystate pressure + inertial pressure (bar)");
        type MassFlowQuantities = enumeration(m_flow_kgps "Mass flow rate (kg/s)", m_flow_gps "Mass flow rate (g/s)", V_flow_m3ps "Volume flow rate (m3/s)", V_flow_lpMin "Volume flow rate (l/min)", H_flow_Jps "Enthalpy flow rate (W)", S_flow_JpKs "Entropy flow rate (W/K)", Cp_flow_JpKs "Heat capacity flow rate (W/K)");
        type TwoPhaseQuantities = enumeration(x_kgpkg "Vapor quality (kg/kg)", T_sat_K "Saturation temperature (K)", T_sat_C "Saturation temperature (°C)", p_sat_Pa "Saturation pressure (Pa)", p_sat_bar "Saturation pressure (bar)", T_oversat_K "Temperature above saturation (K)", p_oversat_Pa "Pressure above saturation (Pa)", p_oversat_bar "Pressure above saturation (bar)");
        type InitializationModelSensor = enumeration(steadyState "Steady state initialization (derivatives of states are zero)", state "Initialization with initial output state") "Initialization modes for sensor lowpass";
      end Types;

      function getQuantity "Computes selected quantity from state"
        replaceable package Medium = Media.myMedia.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
        input Medium.ThermodynamicState state;
        input SI.Pressure r;
        input Types.Quantities quantity;
        input SI.Density rho_min;
        output Real value;
      algorithm
        if quantity == Types.Quantities.T_K then
          value := Medium.temperature(state);
        elseif quantity == Types.Quantities.T_C then
          value := Modelica.Units.Conversions.to_degC(Medium.temperature(state));
        elseif quantity == Types.Quantities.p_Pa then
          value := Medium.pressure(state);
        elseif quantity == Types.Quantities.p_bar then
          value := Modelica.Units.Conversions.to_bar(Medium.pressure(state));
        elseif quantity == Types.Quantities.r_Pa then
          value := r;
        elseif quantity == Types.Quantities.r_bar then
          value := Modelica.Units.Conversions.to_bar(r);
        elseif quantity == Types.Quantities.p_total_Pa then
          value := Medium.pressure(state) + r;
        elseif quantity == Types.Quantities.p_total_bar then
          value := Modelica.Units.Conversions.to_bar(Medium.pressure(state) + r);
        elseif quantity == Types.Quantities.h_Jpkg then
          value := Medium.specificEnthalpy(state);
        elseif quantity == Types.Quantities.s_JpkgK then
          value := Medium.specificEntropy(state);
        elseif quantity == Types.Quantities.rho_kgpm3 then
          value := Medium.density(state);
        elseif quantity == Types.Quantities.v_m3pkg then
          value := 1/(max(rho_min, Medium.density(state)));
        elseif quantity == Types.Quantities.a_mps then
          value := Medium.velocityOfSound(state);
        elseif quantity == Types.Quantities.cv_JpkgK then
          value := Medium.specificHeatCapacityCv(state);
        elseif quantity == Types.Quantities.cp_JpkgK then
          value := Medium.specificHeatCapacityCp(state);
        elseif quantity == Types.Quantities.kappa_1 then
          value := Medium.isentropicExponent(state);
        elseif quantity == Types.Quantities.MM_kgpmol then
          value := Medium.molarMass(state);
        else
          value := 0;
        end if;
      end getQuantity;

      function getFlowQuantity "Computes selected quantity from state and massflow"
        replaceable package Medium = Media.myMedia.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
        input Medium.ThermodynamicState state;
        input SI.MassFlowRate m_flow;
        input Types.MassFlowQuantities quantity;
        input SI.Density rho_min;
        output Real value;
      protected
        Real m3ps_to_lpMin(unit = "(l.s)/(m3.min)") = 60000;
      algorithm
        if quantity == Types.MassFlowQuantities.Cp_flow_JpKs then
          value := m_flow*Medium.specificHeatCapacityCp(state);
        elseif quantity == Types.MassFlowQuantities.H_flow_Jps then
          value := m_flow*Medium.specificEnthalpy(state);
        elseif quantity == Types.MassFlowQuantities.m_flow_kgps then
          value := m_flow;
        elseif quantity == Types.MassFlowQuantities.m_flow_gps then
          value := m_flow*1000;
        elseif quantity == Types.MassFlowQuantities.V_flow_m3ps then
          value := m_flow/max(rho_min, Medium.density(state));
        elseif quantity == Types.MassFlowQuantities.V_flow_lpMin then
          value := m_flow/max(rho_min, Medium.density(state))*m3ps_to_lpMin;
        elseif quantity == Types.MassFlowQuantities.S_flow_JpKs then
          value := m_flow*Medium.specificEntropy(state);
        else
          value := 0;
        end if;
      end getFlowQuantity;

      function getTwoPhaseQuantity "Computes selected two-phase quantity from state"
        replaceable package Medium = Media.myMedia.Interfaces.PartialTwoPhaseMedium "Medium model" annotation(choicesAllMatching = true);
        input Medium.ThermodynamicState state;
        input Types.TwoPhaseQuantities quantity;
        output Real value;
      algorithm
        if quantity == Types.TwoPhaseQuantities.x_kgpkg then
          value := Medium.vapourQuality(state);
        elseif quantity == Types.TwoPhaseQuantities.p_sat_Pa then
          value := Medium.saturationPressure(Medium.temperature(state));
        elseif quantity == Types.TwoPhaseQuantities.p_sat_bar then
          value := Modelica.Units.Conversions.to_bar(Medium.saturationPressure(Medium.temperature(state)));
        elseif quantity == Types.TwoPhaseQuantities.T_sat_K then
          value := Medium.saturationTemperature(Medium.pressure(state));
        elseif quantity == Types.TwoPhaseQuantities.T_sat_C then
          value := Modelica.Units.Conversions.to_degC(Medium.saturationTemperature(Medium.pressure(state)));
        elseif quantity == Types.TwoPhaseQuantities.p_oversat_Pa then
          value := Medium.pressure(state) - Medium.saturationPressure(Medium.temperature(state));
        elseif quantity == Types.TwoPhaseQuantities.p_oversat_bar then
          value := Modelica.Units.Conversions.to_bar(Medium.pressure(state) - Medium.saturationPressure(Medium.temperature(state)));
        elseif quantity == Types.TwoPhaseQuantities.T_oversat_K then
          value := Medium.temperature(state) - Medium.saturationTemperature(Medium.pressure(state));
        else
          value := 0;
        end if;
      end getTwoPhaseQuantity;

      function getFlowUnit "Returns unit of input flow-quantity"
        input Types.MassFlowQuantities quantity;
        output String unit;
      algorithm
        if quantity == Types.MassFlowQuantities.Cp_flow_JpKs then
          unit := "J/(K.s)";
        elseif quantity == Types.MassFlowQuantities.H_flow_Jps then
          unit := "J/s";
        elseif quantity == Types.MassFlowQuantities.m_flow_kgps then
          unit := "kg/s";
        elseif quantity == Types.MassFlowQuantities.V_flow_m3ps then
          unit := "m3/s";
        elseif quantity == Types.MassFlowQuantities.V_flow_lpMin then
          unit := "l/min";
        elseif quantity == Types.MassFlowQuantities.S_flow_JpKs then
          unit := "J/(K.s)";
        else
          unit := "";
        end if;
      end getFlowUnit;

      function getTwoPhaseUnit "Returns unit of input two-phase-quantity"
        input Types.TwoPhaseQuantities quantity;
        output String unit;
      algorithm
        if quantity == Types.TwoPhaseQuantities.x_kgpkg then
          unit := "kg/kg";
        elseif quantity == Types.TwoPhaseQuantities.p_sat_Pa then
          unit := "Pa";
        elseif quantity == Types.TwoPhaseQuantities.p_sat_bar then
          unit := "bar";
        elseif quantity == Types.TwoPhaseQuantities.T_sat_K then
          unit := "K";
        elseif quantity == Types.TwoPhaseQuantities.T_sat_C then
          unit := "degC";
        elseif quantity == Types.TwoPhaseQuantities.p_oversat_Pa then
          unit := "Pa";
        elseif quantity == Types.TwoPhaseQuantities.p_oversat_bar then
          unit := "bar";
        elseif quantity == Types.TwoPhaseQuantities.T_oversat_K then
          unit := "K";
        else
          unit := "";
        end if;
      end getTwoPhaseUnit;
    end Internal;
  end Sensors;

  package Undirected "Components for undirected flow"
    package Interfaces "Interfaces package for undirected thermofluid simulation"
      connector Rear "Undirected connector outputting the rearward state"
        replaceable package Medium = Media.myMedia.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
        SI.Pressure r "Inertial pressure";
        flow SI.MassFlowRate m_flow "Mass flow rate";
        output Medium.ThermodynamicState state_rearwards "Thermodynamic state in rearwards direction";
        input Medium.ThermodynamicState state_forwards "Thermodynamic state in forwards direction";
      end Rear;

      connector Fore "Undirected connector outputting the forward state"
        replaceable package Medium = Media.myMedia.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
        SI.Pressure r "Inertial pressure";
        flow SI.MassFlowRate m_flow "Mass flow rate";
        input Medium.ThermodynamicState state_rearwards "Thermodynamic state in rearwards direction";
        output Medium.ThermodynamicState state_forwards "Thermodynamic state in forwards direction";
      end Fore;

      partial model SISOBiFlow "Base Model with basic flow eqautions for SISO"
        import ThermofluidStream.Utilities.Types.InitializationMethods;
        extends ThermofluidStream.Utilities.DropOfCommonsPlus;
        replaceable package Medium = Media.myMedia.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
        parameter Utilities.Units.Inertance L = dropOfCommons.L "Inertance";
        parameter StateSelect m_flowStateSelect = StateSelect.default "State select for mass flow rate";
        parameter InitializationMethods initM_flow = ThermofluidStream.Utilities.Types.InitializationMethods.none "Initialization method for mass flow rate";
        parameter SI.MassFlowRate m_flow_0 = 0 "Initial value for mass flow rate";
        parameter Utilities.Units.MassFlowAcceleration m_acceleration_0 = 0 "Initial value for der(m_flow)";
        parameter SI.MassFlowRate m_flow_reg = dropOfCommons.m_flow_reg "Regularization threshold of mass flow rate";
        parameter Boolean clip_p_out "If true, set dr_corr to zero";
        parameter SI.Pressure p_min = dropOfCommons.p_min "Minimal steady-state output pressure";
        Fore fore(redeclare package Medium = Medium);
        Rear rear(redeclare package Medium = Medium);
        SI.MassFlowRate m_flow(stateSelect = m_flowStateSelect) = rear.m_flow "Mass flow rate";
        SI.Pressure dp_fore;
        SI.Pressure dp_rear;
        SI.Pressure dr_corr_fore;
        SI.Pressure dr_corr_rear;
        SI.Pressure dr_corr;
      protected
        SI.Pressure p_rear_in = Medium.pressure(rear.state_forwards) "Pressure of medium entering";
        SI.Pressure p_fore_in = Medium.pressure(fore.state_rearwards) "Pressure of medium entering";
        SI.SpecificEnthalpy h_rear_in = Medium.specificEnthalpy(rear.state_forwards) "Specific enthalpy of medium entering";
        SI.SpecificEnthalpy h_fore_in = Medium.specificEnthalpy(fore.state_rearwards) "Specific enthalpy of medium entering";
        Medium.MassFraction Xi_rear_in[Medium.nXi] = Medium.massFraction(rear.state_forwards) "Mass fractions of medium entering";
        Medium.MassFraction Xi_fore_in[Medium.nXi] = Medium.massFraction(fore.state_rearwards) "Mass fractions of medium entering";
        SI.Pressure p_rear_out "Pressure of medium exiting";
        SI.Pressure p_fore_out "Pressure of medium exiting";
        SI.SpecificEnthalpy h_rear_out "Speicifc enthalpy of medium exiting";
        SI.SpecificEnthalpy h_fore_out "Specific enthalpy of medium exiting";
        Medium.MassFraction Xi_rear_out[Medium.nXi] "Mass fractions of medium exiting";
        Medium.MassFraction Xi_fore_out[Medium.nXi] "Mass fractions of medium exiting";
      initial equation
        if initM_flow == InitializationMethods.state then
          m_flow = m_flow_0;
        elseif initM_flow == InitializationMethods.derivative then
          der(m_flow) = m_acceleration_0;
        elseif initM_flow == InitializationMethods.steadyState then
          der(m_flow) = 0;
        end if;
      equation
        fore.m_flow + rear.m_flow = 0;
        fore.r = rear.r + dr_corr - der(rear.m_flow)*L;
        if clip_p_out then
          p_fore_out = max(p_min, p_rear_in + dp_fore);
          dr_corr_fore = dp_fore - (p_fore_out - p_rear_in);
          p_rear_out = max(p_min, p_fore_in + dp_rear);
          dr_corr_rear = dp_rear - (p_rear_out - p_fore_in);
          dr_corr = Internal.regStep(m_flow, dr_corr_fore, -dr_corr_rear, m_flow_reg);
        else
          p_fore_out = p_rear_in + dp_fore;
          p_rear_out = p_fore_in + dp_rear;
          dr_corr_fore = 0;
          dr_corr_rear = 0;
          dr_corr = 0;
        end if;
        rear.state_rearwards = Medium.setState_phX(p_rear_out, h_rear_out, Xi_rear_out);
        fore.state_forwards = Medium.setState_phX(p_fore_out, h_fore_out, Xi_fore_out);
      end SISOBiFlow;
    end Interfaces;

    package Boundaries "Boundary models for undirected thermofluid simulation"
      model Volume "Volume of fixed size, closed to the ambient"
        extends Internal.PartialVolume;
        parameter SI.Volume V_par(displayUnit = "l") = 0.001 "Volume";
        parameter Boolean density_derp_h_from_media = false "= true, if the derivative of density by pressure at const specific enthalpy is calculated from media model (only available for some media models)" annotation(Evaluate = true, HideResult = true);
        parameter SI.DerDensityByPressure density_derp_h_set = 1e-6 "Derivative of density by pressure at const specific enthalpy set value (e.g approx. 1e-5 for air, 1e-7 for water)";
      equation
        assert(abs(density_derp_h) > 1e-12, "The simple Volume model should not be used with incompressible or nearly incompressible media. Consider using the FlexVolume instead.", dropOfCommons.assertionLevel);
        if density_derp_h_from_media then
          density_derp_h = Medium.density_derp_h(medium.state);
        else
          density_derp_h = density_derp_h_set;
        end if;
        V = V_par;
        W_v = 0;
        state_out_rear = medium.state;
        state_out_fore = medium.state;
      end Volume;

      package Internal "Partials and Internal functions"
        partial model PartialVolume "Partial volume with one fore port and one rear port"
          extends ThermofluidStream.Utilities.DropOfCommonsPlus;
          replaceable package Medium = Media.myMedia.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
          parameter Boolean useHeatport = false "=true, if heatport is enabled" annotation(Evaluate = true, HideResult = true);
          parameter Boolean useRear = true "= true, if rear port is enabled" annotation(Evaluate = true, HideResult = true);
          parameter Boolean useFore = true "= true, if fore port is enabled" annotation(Evaluate = true, HideResult = true);
          parameter SI.Area A = 1 "Heat transfer area";
          parameter SI.CoefficientOfHeatTransfer U = 200 "Thermal transmittance";
          parameter Boolean initialize_pressure = true "=true, if pressure is initialized" annotation(Evaluate = true, HideResult = true);
          parameter SI.Pressure p_start = Medium.p_default "Initial pressure set value";
          parameter Boolean initialize_energy = true "= true, if internal energy is initialized" annotation(Evaluate = true, HideResult = true);
          parameter SI.Temperature T_start = Medium.T_default "Initial Temperature set value";
          parameter Boolean initialize_Xi = true "=true, if mass fractions are iinitialized" annotation(Evaluate = true, HideResult = true);
          parameter Medium.MassFraction Xi_0[Medium.nXi] = Medium.X_default[1:Medium.nXi] "Initial mass fractions set values";
          parameter Boolean use_hstart = false "=true, if internal energy is initialized with specific enthalpy" annotation(Evaluate = true, HideResult = true);
          parameter SI.SpecificEnthalpy h_start = Medium.h_default "Initial specific enthalpy set value";
          parameter Utilities.Units.Inertance L = dropOfCommons.L "Inertance of rear/fore ports";
          parameter SI.MassFlowRate m_flow_reg = dropOfCommons.m_flow_reg "Regularization threshold of mass flow rate";
          parameter Real k_volume_damping(unit = "1") = dropOfCommons.k_volume_damping "Damping factor multiplicator";
          parameter Boolean usePreferredMediumStates = false "=true, if preferred medium states are used" annotation(Evaluate = true, HideResult = true);
          Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort(Q_flow = Q_flow, T = T_heatPort) if useHeatport;
          Interfaces.Rear rear(redeclare package Medium = Medium, m_flow = m_flow_rear, r = r_rear_port, state_rearwards = state_out_rear, state_forwards = state_in_rear) if useRear;
          Interfaces.Fore fore(redeclare package Medium = Medium, m_flow = m_flow_fore, r = r_fore_port, state_forwards = state_out_fore, state_rearwards = state_in_fore) if useFore;
          Medium.BaseProperties medium(preferredMediumStates = usePreferredMediumStates);
          SI.Volume V "Volume";
          SI.Mass M(stateSelect = if usePreferredMediumStates then StateSelect.default else StateSelect.always) = V*medium.d "Mass";
          SI.Mass MXi[Medium.nXi](each stateSelect = if usePreferredMediumStates then StateSelect.default else StateSelect.always) = M*medium.Xi "Mases of species";
          SI.Energy U_med(stateSelect = if usePreferredMediumStates then StateSelect.default else StateSelect.always) = M*medium.u "Internal energy";
          SI.HeatFlowRate Q_flow "Heat flow rate";
          SI.Power W_v "Work due to change in volume (Volumenänderungsarbeit)";
        protected
          SI.Temperature T_heatPort "Heat port temperature";
          SI.Pressure r_rear_intern = ThermofluidStream.Undirected.Internal.regStep(m_flow_rear, medium.p - Medium.pressure(state_in_rear), 0, m_flow_reg) "Rear port inertial pressure";
          SI.Pressure r_fore_intern = ThermofluidStream.Undirected.Internal.regStep(m_flow_fore, medium.p - Medium.pressure(state_in_fore), 0, m_flow_reg) "Fore port inertial pressure";
          SI.EnthalpyFlowRate H_flow_rear = (if m_flow_rear >= 0 then Medium.specificEnthalpy(state_in_rear) else h_out_rear)*m_flow_rear "Rear port enthalpy flow rate";
          SI.EnthalpyFlowRate H_flow_fore = (if m_flow_fore >= 0 then Medium.specificEnthalpy(state_in_fore) else h_out_fore)*m_flow_fore "Fore port enthalpy flow rate";
          SI.MassFlowRate Xi_flow_rear[Medium.nXi] = (if m_flow_rear >= 0 then Medium.massFraction(state_in_rear) else Xi_out_rear)*m_flow_rear "Rear port mass flow rates of species";
          SI.MassFlowRate Xi_flow_fore[Medium.nXi] = (if m_flow_fore >= 0 then Medium.massFraction(state_in_fore) else Xi_out_fore)*m_flow_fore "Fore port mass flow rates of species";
          Medium.ThermodynamicState state_out_rear "Rear port outlet state";
          SI.SpecificEnthalpy h_out_rear = Medium.specificEnthalpy(state_out_rear) "Rear port outlet state specific enthalpy";
          Medium.MassFraction Xi_out_rear[Medium.nXi] = Medium.massFraction(state_out_rear);
          Medium.ThermodynamicState state_out_fore "Fore port outlet state";
          SI.SpecificEnthalpy h_out_fore = Medium.specificEnthalpy(state_out_fore) "Fore port outlet state specific enthalpy";
          Medium.MassFraction Xi_out_fore[Medium.nXi] = Medium.massFraction(state_out_fore) "Fore port outlet state mass fractions";
          Real d(unit = "1/(m.s)") = k_volume_damping*sqrt(abs(2*L/(V*max(density_derp_h, 1e-10)))) "Friction factor for coupled boundaries";
          SI.DerDensityByPressure density_derp_h "Partial derivative of density by pressure at constant specific enthalpy";
          SI.Pressure r_damping = d*der(M) "Inertial pressure damping";
          SI.Pressure r_rear_port;
          SI.Pressure r_fore_port "Inertial pressures at rear/fore port";
          SI.MassFlowRate m_flow_rear;
          SI.MassFlowRate m_flow_fore "Mass flow rates at rear/fore port";
          Medium.ThermodynamicState state_in_rear;
          Medium.ThermodynamicState state_in_fore "Inlet states at rear/fore port";
        initial equation
          if initialize_pressure then
            medium.p = p_start;
          end if;
          if initialize_energy then
            if use_hstart then
              medium.h = h_start;
            else
              medium.T = T_start;
            end if;
          end if;
          if initialize_Xi then
            medium.Xi = Xi_0;
          end if;
        equation
          assert(M > 0, "Volumes might not become empty");
          der(m_flow_rear)*L = r_rear_port - r_rear_intern - r_damping;
          der(m_flow_fore)*L = r_fore_port - r_fore_intern - r_damping;
          der(M) = m_flow_rear + m_flow_fore;
          der(U_med) = Q_flow + H_flow_rear + H_flow_fore;
          der(MXi) = Xi_flow_rear + Xi_flow_fore;
          Q_flow = U*A*(T_heatPort - medium.T);
          if not useHeatport then
            T_heatPort = medium.T;
          end if;
          if not useRear then
            m_flow_rear = 0;
            state_in_rear = Medium.setState_phX(Medium.p_default, Medium.h_default, Medium.X_default[1:Medium.nXi]);
          end if;
          if not useFore then
            m_flow_fore = 0;
            state_in_fore = Medium.setState_phX(Medium.p_default, Medium.h_default, Medium.X_default[1:Medium.nXi]);
          end if;
        end PartialVolume;
      end Internal;
    end Boundaries;

    package Topology "Junctions and Connectors for undirected thermofluid simulation" end Topology;

    package Processes "Undirected process package"
      model FlowResistance "Flow resistance model"
        extends Interfaces.SISOBiFlow(final L = if computeL then l/(r^2*pi) else L_value, final clip_p_out = true);
        import Modelica.Constants.pi;
        parameter SI.Radius r(min = 0) "Radius";
        parameter SI.Length l(min = 0) "Length";
        replaceable function pLoss = ThermofluidStream.Processes.Internal.FlowResistance.pleaseSelectPressureLoss constrainedby ThermofluidStream.Processes.Internal.FlowResistance.partialPressureLoss;
        parameter Boolean computeL = true "= true, if inertance L is computed from the geometry" annotation(Evaluate = true, HideResult = true);
        parameter Utilities.Units.Inertance L_value = dropOfCommons.L "Inertance";
        parameter SI.Density rho_min = dropOfCommons.rho_min "Minium inlet density";
      protected
        SI.Density rho_rear_in = max(rho_min, Medium.density(rear.state_forwards)) "Inlet density of rear port";
        SI.DynamicViscosity mu_rear_in = Medium.dynamicViscosity(rear.state_forwards) "Inlet dynamic viscosity of rear port";
        SI.Density rho_fore_in = max(rho_min, Medium.density(fore.state_rearwards)) "Inlet density of fore port";
        SI.DynamicViscosity mu_fore_in = Medium.dynamicViscosity(fore.state_rearwards) "Inlet dynamic viscosity of fore port";
      equation
        dp_fore = -pLoss(m_flow, rho_rear_in, mu_rear_in, r, l);
        h_fore_out = h_rear_in;
        Xi_fore_out = Xi_rear_in;
        dp_rear = -pLoss(-m_flow, rho_fore_in, mu_fore_in, r, l);
        h_rear_out = h_fore_in;
        Xi_rear_out = Xi_fore_in;
      end FlowResistance;

      model ConductionElement "Model of quasi-sationary mass and heat transfer"
        extends Internal.PartialConductionElement;
        parameter Boolean resistanceFromAU = true "= true, if thermal conductance is given by U*A" annotation(Evaluate = true, HideResult = true);
        parameter SI.Area A = 1 "Heat transfer area";
        parameter SI.CoefficientOfHeatTransfer U = 200 "Thermal transmittance";
        parameter SI.ThermalConductance k_par = 200 "Thermal conductance";
        final parameter SI.ThermalConductance k_internal = if resistanceFromAU then A*U else k_par;
        parameter Boolean displayVolume = true "= true, if volume V is displayed" annotation(Evaluate = true, HideResult = true);
        parameter Boolean displayConduction = true "= true, if thermal conductance is displayed" annotation(Evaluate = true, HideResult = true);
        final parameter Boolean displayAnything = displayParameters and (displayVolume or displayConduction) annotation(Evaluate = true, HideResult = true);
        final parameter String parameterString = if displayParameters and displayVolume and displayConduction then "V=%V, " + conductionString elseif displayParameters and displayVolume and not displayConduction then "V=%V"
         elseif displayParameters and not displayVolume and displayConduction then conductionString else "" annotation(Evaluate = true, HideResult = true);
        final parameter String conductionString = if resistanceFromAU then "A=%A, U=%U" else "k=%k_par" annotation(Evaluate = true, HideResult = true);
      equation
        k = k_internal;
      end ConductionElement;

      package Internal "Internals package for Processes"
        partial model PartialConductionElement "Partial model of quasi-stationary mass and heat transfer"
          extends Interfaces.SISOBiFlow(final clip_p_out = false);
          parameter SI.Volume V(displayUnit = "l") = 0.001 "Volume";
          parameter ThermofluidStream.Undirected.Processes.Internal.InitializationMethodsCondElement init = ThermofluidStream.Undirected.Processes.Internal.InitializationMethodsCondElement.rear "Initialization method for specific enthalpy";
          parameter SI.Temperature T_0 = Medium.T_default "Initial Temperature";
          parameter SI.SpecificEnthalpy h_0 = Medium.h_default "Initial specific enthalpy";
          parameter SI.Density rho_min = dropOfCommons.rho_min "Minimal density";
          parameter Boolean neglectPressureChanges = true "=true, if pressure changes are neglected" annotation(Evaluate = true, HideResult = true);
          parameter SI.MassFlowRate m_flow_reg = dropOfCommons.m_flow_reg "Regularization massflow to switch between positive- and negative-massflow model";
          parameter Boolean enforce_global_energy_conservation = false "= true, if global conservation of energy is enforced" annotation(Evaluate = true, HideResult = true);
          parameter SI.Time T_e = 100 "Time constant for global conservation of energy";
          Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort(Q_flow = Q_flow, T = T_heatPort);
          SI.SpecificEnthalpy h(start = Medium.h_default, stateSelect = StateSelect.prefer) "Medium specific enthalpy";
          Medium.ThermodynamicState state = Medium.setState_phX(p, h, Xi) "Medium thermodynamic state";
          SI.Temperature T = Medium.temperature(state) "Medium temperature";
          SI.ThermalConductance k "Thermal conductance";
          SI.Energy deltaE_system(start = 0, fixed = true) "Energy difference between m_flow*(h_in-h_out) and Q_flow";
          SI.Mass M "Medium mass";
        protected
          SI.Pressure p = Undirected.Internal.regStep(m_flow, p_rear_in, p_fore_in, m_flow_reg) "Pressure";
          Medium.MassFraction Xi[Medium.nXi] = Undirected.Internal.regStep(m_flow, Xi_rear_in, Xi_fore_in, m_flow_reg) "Mass fractions";
          SI.SpecificEnthalpy h_in = if m_flow >= 0 then h_rear_in else h_fore_in "Inlet specific enthalpy";
          SI.Density rho = max(rho_min, Medium.density(state)) "Medium density";
          SI.SpecificEnthalpy h_out = Medium.specificEnthalpy(state) "Outlet specific enthalpy";
          SI.Temperature T_heatPort "Heatport temperature";
          SI.HeatFlowRate Q_flow "Heat flow rate";
        initial equation
          if init == Internal.InitializationMethodsCondElement.T then
            h = Medium.specificEnthalpy(Medium.setState_pTX(p, T_0, Xi));
          elseif init == Internal.InitializationMethodsCondElement.h then
            h = h_0;
          elseif init == InitializationMethodsCondElement.port then
            h = h_in;
          elseif init == Internal.InitializationMethodsCondElement.fore then
            h = h_fore_in;
          else
            h = h_rear_in;
          end if;
        equation
          M = V*rho;
          if not neglectPressureChanges then
            M*der(h) = Q_flow + abs(m_flow)*(h_in - h_out) + V*der(p) + (if enforce_global_energy_conservation then deltaE_system/T_e else 0);
          else
            M*der(h) = Q_flow + abs(m_flow)*(h_in - h_out) + (if enforce_global_energy_conservation then deltaE_system/T_e else 0);
          end if;
          if enforce_global_energy_conservation then
            der(deltaE_system) = Q_flow + abs(m_flow)*(h_in - h_out);
          else
            deltaE_system = 0;
          end if;
          Q_flow = k*(T_heatPort - T);
          dp_fore = 0;
          h_fore_out = h;
          Xi_fore_out = Xi_rear_in;
          dp_rear = 0;
          h_rear_out = h;
          Xi_rear_out = Xi_fore_in;
        end PartialConductionElement;

        type InitializationMethodsCondElement = enumeration(T "Temperature T_0", h "specific enthalpy h_0", fore "input state from fore", rear "input state from rear", port "regularized input state from fore or rear, depending on massflow") "Choices for initialization of state h of undirected ConductionElement";
      end Internal;
    end Processes;

    package FlowControl "Package for undirected flow control components"
      model TanValve "Valve with tan-shaped flow resistance"
        extends ThermofluidStream.Undirected.Interfaces.SISOBiFlow(final clip_p_out = true);
        Modelica.Blocks.Interfaces.RealInput u(unit = "1") "Valve control input []";
        parameter Utilities.Units.Inertance L = dropOfCommons.L "Inertance";
        parameter Boolean invertInput = false "= true, if input u is inverted" annotation(Evaluate = true, HideResult = true);
        parameter SI.MassFlowRate m_flow_ref = 0.1 "Reference mass flow rate";
        parameter SI.Pressure p_ref = 1e5 "Reference pressure";
        parameter Real relativeLeakiness(unit = "1") = 1e-3 "Imperfection of valve";
      protected
        Real k(unit = "(Pa.s)/kg");
        Real u2(unit = "1");
      equation
        if invertInput then
          u2 = max(relativeLeakiness, min(1 - relativeLeakiness, u));
        else
          u2 = max(relativeLeakiness, min(1 - relativeLeakiness, 1 - u));
        end if;
        k = p_ref/m_flow_ref*tan(u2*Modelica.Constants.pi/2);
        dp_fore = -k*m_flow;
        h_fore_out = h_rear_in;
        Xi_fore_out = Xi_rear_in;
        dp_rear = -dp_fore;
        h_rear_out = h_fore_in;
        Xi_rear_out = Xi_fore_in;
      end TanValve;

      package Internal "Internal models, functions and reckords for undirected FlowControl" end Internal;
    end FlowControl;

    package Sensors "Sensors package for undirected thermofluid simulation"
      import ThermofluidStream.Sensors.Internal;

      model SingleFlowSensor "Flow sensor"
        extends Internal.PartialSensor;
        import Quantities = ThermofluidStream.Sensors.Internal.Types.MassFlowQuantities;
        import InitMode = ThermofluidStream.Sensors.Internal.Types.InitializationModelSensor;
        parameter Quantities quantity "Meassured quantity";
        final parameter String quantityString = if quantity == ThermofluidStream.Sensors.Internal.Types.MassFlowQuantities.m_flow_kgps then "m_flow in kg/s" elseif quantity == ThermofluidStream.Sensors.Internal.Types.MassFlowQuantities.m_flow_gps then "m_flow in g/s"
         elseif quantity == ThermofluidStream.Sensors.Internal.Types.MassFlowQuantities.V_flow_m3ps then "V_flow in m3/s"
         elseif quantity == ThermofluidStream.Sensors.Internal.Types.MassFlowQuantities.V_flow_lpMin then "V_flow in l/min"
         elseif quantity == ThermofluidStream.Sensors.Internal.Types.MassFlowQuantities.H_flow_Jps then "H_flow in J/s"
         elseif quantity == ThermofluidStream.Sensors.Internal.Types.MassFlowQuantities.S_flow_JpKs then "S_flow in J/(K.s)"
         elseif quantity == ThermofluidStream.Sensors.Internal.Types.MassFlowQuantities.Cp_flow_JpKs then "Cp_flow in J/(K.s)" else "error";
        parameter SI.Density rho_min = dropOfCommons.rho_min "Minimum Density";
        parameter Boolean outputValue = false "= true, if sensor output is enabled" annotation(Evaluate = true, HideResult = true);
        parameter Boolean filter_output = false "= true, if sensor output is filtered (to break algebraic loops)" annotation(Evaluate = true, HideResult = true);
        parameter SI.Time TC = 0.1 "Time constant of sensor output filter (PT1)";
        parameter InitMode init = InitMode.steadyState "Initialization mode for sensor output";
        parameter Real value_0(unit = ThermofluidStream.Sensors.Internal.getFlowUnit(quantity)) = 0 "Start value of sensor output";
        Modelica.Blocks.Interfaces.RealOutput value_out(unit = ThermofluidStream.Sensors.Internal.getFlowUnit(quantity)) = value if outputValue "Sensor output connector";
        output Real value(unit = ThermofluidStream.Sensors.Internal.getFlowUnit(quantity));
      protected
        Real direct_value(unit = ThermofluidStream.Sensors.Internal.getFlowUnit(quantity));
        function getQuantity = ThermofluidStream.Sensors.Internal.getFlowQuantity(redeclare package Medium = Medium) "Quantity compute function";
      initial equation
        if filter_output and init == InitMode.steadyState then
          value = direct_value;
        elseif filter_output then
          value = value_0;
        end if;
      equation
        direct_value = getQuantity(state, rear.m_flow, quantity, rho_min);
        if filter_output then
          der(value)*TC = direct_value - value;
        else
          value = direct_value;
        end if;
      end SingleFlowSensor;

      model TwoPhaseSensorSelect "Selectable sensor for two phase medium"
        extends Internal.PartialSensor(redeclare package Medium = Medium2Phase);
        import Quantities = ThermofluidStream.Sensors.Internal.Types.TwoPhaseQuantities;
        import InitMode = ThermofluidStream.Sensors.Internal.Types.InitializationModelSensor;
        replaceable package Medium2Phase = Media.myMedia.Interfaces.PartialTwoPhaseMedium "Medium model" annotation(choicesAllMatching = true);
        parameter Quantities quantity "Measured quantity" annotation(choicesAllMatching = true);
        final parameter String quantityString = if quantity == ThermofluidStream.Sensors.Internal.Types.TwoPhaseQuantities.x_kgpkg then "x in kg/kg" elseif quantity == ThermofluidStream.Sensors.Internal.Types.TwoPhaseQuantities.T_sat_K then "T_sat in K"
         elseif quantity == ThermofluidStream.Sensors.Internal.Types.TwoPhaseQuantities.T_sat_C then "T_sat in °C"
         elseif quantity == ThermofluidStream.Sensors.Internal.Types.TwoPhaseQuantities.p_sat_Pa then "p_sat in Pa"
         elseif quantity == ThermofluidStream.Sensors.Internal.Types.TwoPhaseQuantities.p_sat_bar then "p_sat in bar"
         elseif quantity == ThermofluidStream.Sensors.Internal.Types.TwoPhaseQuantities.T_oversat_K then "T - T_sat in K"
         elseif quantity == ThermofluidStream.Sensors.Internal.Types.TwoPhaseQuantities.p_oversat_Pa then "p - p_sat in Pa"
         elseif quantity == ThermofluidStream.Sensors.Internal.Types.TwoPhaseQuantities.p_oversat_bar then "p - p_sat in bar" else "error";
        parameter Boolean outputValue = false "= true, if sensor output is enabled" annotation(Evaluate = true, HideResult = true);
        parameter Boolean filter_output = false "= true, if sensor output is filtered (to break algebraic loops)" annotation(Evaluate = true, HideResult = true);
        parameter SI.Time TC = 0.1 "Time constant of sensor output filter (PT1)";
        parameter InitMode init = InitMode.steadyState "Initialization mode for sensor output";
        parameter Real value_0(unit = ThermofluidStream.Sensors.Internal.getTwoPhaseUnit(quantity)) = 0 "Start value of sensor output";
        Modelica.Blocks.Interfaces.RealOutput value_out(unit = ThermofluidStream.Sensors.Internal.getTwoPhaseUnit(quantity)) = value if outputValue "Sensor output connector";
        Real value(unit = ThermofluidStream.Sensors.Internal.getTwoPhaseUnit(quantity));
      protected
        Real direct_value(unit = ThermofluidStream.Sensors.Internal.getTwoPhaseUnit(quantity));
        function getQuantity = ThermofluidStream.Sensors.Internal.getTwoPhaseQuantity(redeclare package Medium = Medium) "Quantity compute function";
      initial equation
        if filter_output and init == InitMode.steadyState then
          value = direct_value;
        elseif filter_output then
          value = value_0;
        end if;
      equation
        direct_value = getQuantity(state, quantity);
        if filter_output then
          der(value)*TC = direct_value - value;
        else
          value = direct_value;
        end if;
      end TwoPhaseSensorSelect;

      package Internal "Partials and functions"
        partial model PartialSensor "Partial undirected sensor"
          extends ThermofluidStream.Utilities.DropOfCommonsPlus(displayInstanceName = false);
          replaceable package Medium = Media.myMedia.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
          parameter Integer digits(min = 0) = 1 "Number of displayed digits";
          parameter SI.MassFlowRate m_flow_reg = dropOfCommons.m_flow_reg "Regularization threshold of mass flow rate";
          Interfaces.Rear rear(redeclare package Medium = Medium);
          Interfaces.Fore fore(redeclare package Medium = Medium);
          Medium.ThermodynamicState state = Medium.setState_phX(p_reg, h_reg, Xi_reg);
        protected
          SI.Pressure p_reg = Undirected.Internal.regStep(rear.m_flow, Medium.pressure(rear.state_forwards), Medium.pressure(rear.state_rearwards), m_flow_reg);
          SI.SpecificEnthalpy h_reg = Undirected.Internal.regStep(rear.m_flow, Medium.specificEnthalpy(rear.state_forwards), Medium.specificEnthalpy(rear.state_rearwards), m_flow_reg);
          Medium.MassFraction Xi_reg[Medium.nXi];
          Medium.MassFraction Xi_forwards[Medium.nXi] = Medium.massFraction(rear.state_forwards);
          Medium.MassFraction Xi_rearwards[Medium.nXi] = Medium.massFraction(rear.state_rearwards);
        equation
          for i in 1:Medium.nXi loop
            Xi_reg[i] = Undirected.Internal.regStep(rear.m_flow, Xi_forwards[i], Xi_rearwards[i], m_flow_reg);
          end for;
          fore.state_forwards = rear.state_forwards;
          rear.state_rearwards = fore.state_rearwards;
          fore.r = rear.r;
          fore.m_flow + rear.m_flow = 0;
        end PartialSensor;
      end Internal;
    end Sensors;

    package Internal "Internal helper functions and models for the undirected themofluid simulation."
      function regStep "Approximation of a general step, such that the characteristic is continuous and differentiable"
        input Real x "Abscissa value";
        input Real y1 "Ordinate value for x > 0";
        input Real y2 "Ordinate value for x < 0";
        input Real x_small(min = 0) = 1e-5 "Approximation of step for -x_small <= x <= x_small; x_small >= 0 required";
        output Real y "Ordinate value to approximate y = if x > 0 then y1 else y2";
      algorithm
        y := smooth(1, if x > x_small then y1 else if x < -x_small then y2 else if x_small > 0 then (x/x_small)*((x/x_small)^2 - 3)*(y2 - y1)/4 + (y1 + y2)/2 else (y1 + y2)/2);
      end regStep;
    end Internal;
  end Undirected;

  package Utilities
    package Functions
      function massFractionK
        replaceable package Medium = Media.myMedia.Interfaces.PartialMedium;
        input Medium.ThermodynamicState state;
        input Integer k;
        output Medium.MassFraction x;
      protected
        Medium.MassFraction Xi[Medium.nXi] = Medium.massFraction(state);
      algorithm
        x := Xi[k];
      end massFractionK;

      function blendFunction "Smooth step between two values at two support points"
        import ThermofluidStream.Undirected.Internal.regStep;
        input Real y1 "Value of y at x1";
        input Real y2 "Value of y at x2";
        input Real x1;
        input Real x2;
        input Real x;
        output Real y;
      protected
        Real u;
      algorithm
        u := (2*x - (x1 + x2))/(x2 - x1);
        y := regStep(u, y2, y1, 1);
      end blendFunction;
    end Functions;

    package Units "Units package for the thermofluid library"
      type Inertance = Real(quantity = "Inertance", unit = "1/m", min = 0) "Unit of Inertance";
      type MassFlowAcceleration = Real(quantity = "MassFlowAcceleration", unit = "kg/s2") "Acceleration Unit for a MassFlow";
    end Units;

    package Types "Types that are not units needed."
      type InitializationMethods = enumeration(none "No initialization", steadyState "Steady state initialization (derivatives of states are zero)", state "Initialization with initial states", derivative "Initialization with initial derivatives of states") "Choices for initialization of a state.";
    end Types;

    package Icons
      model DLRLogo end DLRLogo;
    end Icons;

    model DropOfCommonsPlus "Extend this to use 'dropOfCommons', 'displayInstanceName' and 'displayParameters'"
    protected
      outer DropOfCommons dropOfCommons;
    public
      parameter Boolean displayInstanceName = dropOfCommons.displayInstanceNames "= true, if instance name is displayed" annotation(Evaluate = true, HideResult = true);
      parameter Boolean displayParameters = dropOfCommons.displayParameters "= true, if displaying parameters is enabled" annotation(Evaluate = true, HideResult = true);
    end DropOfCommonsPlus;
  end Utilities;

  package Media "Package containing available media models and wrappers"
    package myMedia "Library of media property models"
      import Modelica.Units.SI;
      import Cv = Modelica.Units.Conversions;

      package Examples "Demonstrate usage of property models"
        package Utilities "Functions, connectors and models needed for the media model tests"
          connector FluidPort "Interface for quasi one-dimensional fluid flow in a piping network (incompressible or compressible, one or more phases, one or more substances)"
            replaceable package Medium = ThermofluidStream.Media.myMedia.Interfaces.PartialMedium "Medium model" annotation(choicesAllMatching = true);
            Medium.AbsolutePressure p "Pressure in the connection point";
            flow Medium.MassFlowRate m_flow "Mass flow rate from the connection point into the component";
            Medium.SpecificEnthalpy h "Specific mixture enthalpy in the connection point";
            flow Medium.EnthalpyFlowRate H_flow "Enthalpy flow rate into the component (if m_flow > 0, H_flow = m_flow*h)";
            Medium.MassFraction Xi[Medium.nXi] "Independent mixture mass fractions m_i/m in the connection point";
            flow Medium.MassFlowRate mXi_flow[Medium.nXi] "Mass flow rates of the independent substances from the connection point into the component (if m_flow > 0, mX_flow = m_flow*X)";
            Medium.ExtraProperty C[Medium.nC] "Properties c_i/m in the connection point";
            flow Medium.ExtraPropertyFlowRate mC_flow[Medium.nC] "Flow rates of auxiliary properties from the connection point into the component (if m_flow > 0, mC_flow = m_flow*C)";
          end FluidPort;

          connector FluidPort_a "Fluid connector with filled icon"
            extends FluidPort;
          end FluidPort_a;

          connector FluidPort_b "Fluid connector with outlined icon"
            extends FluidPort;
          end FluidPort_b;
        end Utilities;
      end Examples;

      package Interfaces "Interfaces for media models"
        partial package PartialMedium "Partial medium properties (base package of all media packages)"
          extends ThermofluidStream.Media.myMedia.Interfaces.Types;
          constant ThermofluidStream.Media.myMedia.Interfaces.Choices.IndependentVariables ThermoStates "Enumeration type for independent variables";
          constant String mediumName = "unusablePartialMedium" "Name of the medium";
          constant String substanceNames[:] = {mediumName} "Names of the mixture substances. Set substanceNames={mediumName} if only one substance.";
          constant String extraPropertiesNames[:] = fill("", 0) "Names of the additional (extra) transported properties. Set extraPropertiesNames=fill(\"\",0) if unused";
          constant Boolean singleState "= true, if u and d are not a function of pressure";
          constant Boolean reducedX = true "= true, if medium contains the equation sum(X) = 1.0; set reducedX=true if only one substance (see docu for details)";
          constant Boolean fixedX = false "= true, if medium contains the equation X = reference_X";
          constant AbsolutePressure reference_p = 101325 "Reference pressure of Medium: default 1 atmosphere";
          constant Temperature reference_T = 298.15 "Reference temperature of Medium: default 25 deg Celsius";
          constant MassFraction reference_X[nX] = fill(1/nX, nX) "Default mass fractions of medium";
          constant AbsolutePressure p_default = 101325 "Default value for pressure of medium (for initialization)";
          constant Temperature T_default = Modelica.Units.Conversions.from_degC(20) "Default value for temperature of medium (for initialization)";
          constant SpecificEnthalpy h_default = specificEnthalpy_pTX(p_default, T_default, X_default) "Default value for specific enthalpy of medium (for initialization)";
          constant MassFraction X_default[nX] = reference_X "Default value for mass fractions of medium (for initialization)";
          constant ExtraProperty C_default[nC] = fill(0, nC) "Default value for trace substances of medium (for initialization)";
          final constant Integer nS = size(substanceNames, 1) "Number of substances";
          constant Integer nX = nS "Number of mass fractions";
          constant Integer nXi = if fixedX then 0 else if reducedX then nS - 1 else nS "Number of structurally independent mass fractions (see docu for details)";
          final constant Integer nC = size(extraPropertiesNames, 1) "Number of extra (outside of standard mass-balance) transported properties";
          constant Real C_nominal[nC](min = fill(Modelica.Constants.eps, nC)) = 1.0e-6*ones(nC) "Default for the nominal values for the extra properties";
          replaceable record FluidConstants = ThermofluidStream.Media.myMedia.Interfaces.Types.Basic.FluidConstants "Critical, triple, molecular and other standard data of fluid";

          replaceable record ThermodynamicState "Minimal variable set that is available as input argument to every medium function" end ThermodynamicState;

          replaceable partial model BaseProperties "Base properties (p, d, T, h, u, R_s, MM and, if applicable, X and Xi) of a medium"
            InputAbsolutePressure p "Absolute pressure of medium";
            InputMassFraction Xi[nXi](start = reference_X[1:nXi]) "Structurally independent mass fractions";
            InputSpecificEnthalpy h "Specific enthalpy of medium";
            Density d "Density of medium";
            Temperature T "Temperature of medium";
            MassFraction X[nX](start = reference_X) "Mass fractions (= (component mass)/total mass m_i/m)";
            SpecificInternalEnergy u "Specific internal energy of medium";
            SpecificHeatCapacity R_s "Gas constant (of mixture if applicable)";
            MolarMass MM "Molar mass (of mixture or single fluid)";
            ThermodynamicState state "Thermodynamic state record for optional functions";
            parameter Boolean preferredMediumStates = false "= true, if StateSelect.prefer shall be used for the independent property variables of the medium" annotation(Evaluate = true);
            parameter Boolean standardOrderComponents = true "If true, and reducedX = true, the last element of X will be computed from the other ones";
            Modelica.Units.NonSI.Temperature_degC T_degC = Modelica.Units.Conversions.to_degC(T) "Temperature of medium in [degC]";
            Modelica.Units.NonSI.Pressure_bar p_bar = Modelica.Units.Conversions.to_bar(p) "Absolute pressure of medium in [bar]";
            connector InputAbsolutePressure = input SI.AbsolutePressure "Pressure as input signal connector";
            connector InputSpecificEnthalpy = input SI.SpecificEnthalpy "Specific enthalpy as input signal connector";
            connector InputMassFraction = input SI.MassFraction "Mass fraction as input signal connector";
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
                assert(X[i] >= -1.e-5 and X[i] <= 1 + 1.e-5, "Mass fraction X[" + String(i) + "] = " + String(X[i]) + "of substance " + substanceNames[i] + "\nof medium " + mediumName + " is not in the range 0..1");
              end for;
            end if;
            assert(p >= 0.0, "Pressure (= " + String(p) + " Pa) of medium \"" + mediumName + "\" is negative\n(Temperature = " + String(T) + " K)");
          end BaseProperties;

          replaceable partial function setState_pTX "Return thermodynamic state as function of p, T and composition X or Xi"
            input AbsolutePressure p "Pressure";
            input Temperature T "Temperature";
            input MassFraction X[:] = reference_X "Mass fractions";
            output ThermodynamicState state "Thermodynamic state record";
          end setState_pTX;

          replaceable partial function setState_phX "Return thermodynamic state as function of p, h and composition X or Xi"
            input AbsolutePressure p "Pressure";
            input SpecificEnthalpy h "Specific enthalpy";
            input MassFraction X[:] = reference_X "Mass fractions";
            output ThermodynamicState state "Thermodynamic state record";
          end setState_phX;

          replaceable partial function setState_dTX "Return thermodynamic state as function of d, T and composition X or Xi"
            input Density d "Density";
            input Temperature T "Temperature";
            input MassFraction X[:] = reference_X "Mass fractions";
            output ThermodynamicState state "Thermodynamic state record";
          end setState_dTX;

          replaceable partial function dynamicViscosity "Return dynamic viscosity"
            input ThermodynamicState state "Thermodynamic state record";
            output DynamicViscosity eta "Dynamic viscosity";
          end dynamicViscosity;

          replaceable partial function massFraction "Return independent mass Fraction"
            input ThermodynamicState state "Thermodynamic state record";
            output MassFraction Xi[nXi] "(independent) Mass Fraction";
          end massFraction;

          replaceable partial function pressure "Return pressure"
            input ThermodynamicState state "Thermodynamic state record";
            output AbsolutePressure p "Pressure";
          end pressure;

          replaceable partial function temperature "Return temperature"
            input ThermodynamicState state "Thermodynamic state record";
            output Temperature T "Temperature";
          end temperature;

          replaceable partial function density "Return density"
            input ThermodynamicState state "Thermodynamic state record";
            output Density d "Density";
          end density;

          replaceable partial function specificEnthalpy "Return specific enthalpy"
            input ThermodynamicState state "Thermodynamic state record";
            output SpecificEnthalpy h "Specific enthalpy";
          end specificEnthalpy;

          replaceable partial function specificEntropy "Return specific entropy"
            input ThermodynamicState state "Thermodynamic state record";
            output SpecificEntropy s "Specific entropy";
          end specificEntropy;

          replaceable partial function specificHeatCapacityCp "Return specific heat capacity at constant pressure"
            input ThermodynamicState state "Thermodynamic state record";
            output SpecificHeatCapacity cp "Specific heat capacity at constant pressure";
          end specificHeatCapacityCp;

          replaceable partial function specificHeatCapacityCv "Return specific heat capacity at constant volume"
            input ThermodynamicState state "Thermodynamic state record";
            output SpecificHeatCapacity cv "Specific heat capacity at constant volume";
          end specificHeatCapacityCv;

          replaceable partial function isentropicExponent "Return isentropic exponent"
            input ThermodynamicState state "Thermodynamic state record";
            output IsentropicExponent gamma "Isentropic exponent";
          end isentropicExponent;

          replaceable partial function velocityOfSound "Return velocity of sound"
            input ThermodynamicState state "Thermodynamic state record";
            output VelocityOfSound a "Velocity of sound";
          end velocityOfSound;

          replaceable partial function isobaricExpansionCoefficient "Return overall the isobaric expansion coefficient beta"
            input ThermodynamicState state "Thermodynamic state record";
            output IsobaricExpansionCoefficient beta "Isobaric expansion coefficient";
          end isobaricExpansionCoefficient;

          function beta = isobaricExpansionCoefficient "Alias for isobaricExpansionCoefficient for user convenience";

          replaceable partial function density_derp_h "Return density derivative w.r.t. pressure at const specific enthalpy"
            input ThermodynamicState state "Thermodynamic state record";
            output DerDensityByPressure ddph "Density derivative w.r.t. pressure";
          end density_derp_h;

          replaceable partial function molarMass "Return the molar mass of the medium"
            input ThermodynamicState state "Thermodynamic state record";
            output MolarMass MM "Mixture molar mass";
          end molarMass;

          replaceable function specificEnthalpy_pTX "Return specific enthalpy from p, T, and X or Xi"
            input AbsolutePressure p "Pressure";
            input Temperature T "Temperature";
            input MassFraction X[:] = reference_X "Mass fractions";
            output SpecificEnthalpy h "Specific enthalpy";
          algorithm
            h := specificEnthalpy(setState_pTX(p, T, X));
            annotation(inverse(T = temperature_phX(p, h, X)));
          end specificEnthalpy_pTX;

          replaceable function temperature_phX "Return temperature from p, h, and X or Xi"
            input AbsolutePressure p "Pressure";
            input SpecificEnthalpy h "Specific enthalpy";
            input MassFraction X[:] = reference_X "Mass fractions";
            output Temperature T "Temperature";
          algorithm
            T := temperature(setState_phX(p, h, X));
          end temperature_phX;

          replaceable function density_phX "Return density from p, h, and X or Xi"
            input AbsolutePressure p "Pressure";
            input SpecificEnthalpy h "Specific enthalpy";
            input MassFraction X[:] = reference_X "Mass fractions";
            output Density d "Density";
          algorithm
            d := density(setState_phX(p, h, X));
          end density_phX;

          type MassFlowRate = SI.MassFlowRate(quantity = "MassFlowRate." + mediumName, min = -1.0e5, max = 1.e5) "Type for mass flow rate with medium specific attributes";
          package Choices = myMedia.Interfaces.Choices annotation(obsolete = "Use Modelica.Media.Interfaces.Choices");
        end PartialMedium;

        partial package PartialPureSubstance "Base class for pure substances of one chemical substance"
          extends PartialMedium(final reducedX = true, final fixedX = true);

          redeclare replaceable function massFraction "Return independent mass Fraction"
            input ThermodynamicState state "Thermodynamic state record";
            output MassFraction Xi[nXi] "(independent) Mass Fraction";
          algorithm
            Xi := fill(0, 0);
          end massFraction;

          replaceable function density_ph "Return density from p and h"
            input AbsolutePressure p "Pressure";
            input SpecificEnthalpy h "Specific enthalpy";
            output Density d "Density";
          algorithm
            d := density_phX(p, h, fill(0, 0));
          end density_ph;

          replaceable function temperature_ph "Return temperature from p and h"
            input AbsolutePressure p "Pressure";
            input SpecificEnthalpy h "Specific enthalpy";
            output Temperature T "Temperature";
          algorithm
            T := temperature_phX(p, h, fill(0, 0));
          end temperature_ph;

          replaceable function pressure_dT "Return pressure from d and T"
            input Density d "Density";
            input Temperature T "Temperature";
            output AbsolutePressure p "Pressure";
          algorithm
            p := pressure(setState_dTX(d, T, fill(0, 0)));
          end pressure_dT;

          replaceable function specificEnthalpy_dT "Return specific enthalpy from d and T"
            input Density d "Density";
            input Temperature T "Temperature";
            output SpecificEnthalpy h "Specific enthalpy";
          algorithm
            h := specificEnthalpy(setState_dTX(d, T, fill(0, 0)));
          end specificEnthalpy_dT;

          replaceable function specificEnthalpy_pT "Return specific enthalpy from p and T"
            input AbsolutePressure p "Pressure";
            input Temperature T "Temperature";
            output SpecificEnthalpy h "Specific enthalpy";
          algorithm
            h := specificEnthalpy_pTX(p, T, fill(0, 0));
          end specificEnthalpy_pT;

          replaceable function density_pT "Return density from p and T"
            input AbsolutePressure p "Pressure";
            input Temperature T "Temperature";
            output Density d "Density";
          algorithm
            d := density(setState_pTX(p, T, fill(0, 0)));
          end density_pT;

          redeclare replaceable partial model extends BaseProperties(final standardOrderComponents = true) end BaseProperties;
        end PartialPureSubstance;

        partial package PartialTwoPhaseMedium "Base class for two phase medium of one substance"
          extends PartialPureSubstance(redeclare replaceable record FluidConstants = ThermofluidStream.Media.myMedia.Interfaces.Types.TwoPhase.FluidConstants);
          constant Boolean smoothModel = false "True if the (derived) model should not generate state events";
          constant Boolean onePhase = false "True if the (derived) model should never be called with two-phase inputs";
          constant FluidConstants fluidConstants[nS] "Constant data for the fluid";

          redeclare replaceable record extends ThermodynamicState "Thermodynamic state of two phase medium"
            FixedPhase phase(min = 0, max = 2) "Phase of the fluid: 1 for 1-phase, 2 for two-phase, 0 for not known, e.g., interactive use";
          end ThermodynamicState;

          redeclare replaceable partial model extends BaseProperties "Base properties (p, d, T, h, u, R_s, MM, sat) of two phase medium"
            SaturationProperties sat "Saturation properties at the medium pressure";
          end BaseProperties;

          redeclare replaceable partial function extends setState_dTX "Return thermodynamic state as function of d, T and composition X or Xi"
            input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          end setState_dTX;

          redeclare replaceable partial function extends setState_phX "Return thermodynamic state as function of p, h and composition X or Xi"
            input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          end setState_phX;

          redeclare replaceable partial function extends setState_pTX "Return thermodynamic state as function of p, T and composition X or Xi"
            input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
          end setState_pTX;

          replaceable function setSat_p "Return saturation property record from pressure"
            input AbsolutePressure p "Pressure";
            output SaturationProperties sat "Saturation property record";
          algorithm
            sat.psat := p;
            sat.Tsat := saturationTemperature(p);
          end setSat_p;

          replaceable partial function bubbleEnthalpy "Return bubble point specific enthalpy"
            input SaturationProperties sat "Saturation property record";
            output SI.SpecificEnthalpy hl "Boiling curve specific enthalpy";
          end bubbleEnthalpy;

          replaceable partial function dewEnthalpy "Return dew point specific enthalpy"
            input SaturationProperties sat "Saturation property record";
            output SI.SpecificEnthalpy hv "Dew curve specific enthalpy";
          end dewEnthalpy;

          replaceable partial function bubbleDensity "Return bubble point density"
            input SaturationProperties sat "Saturation property record";
            output Density dl "Boiling curve density";
          end bubbleDensity;

          replaceable partial function dewDensity "Return dew point density"
            input SaturationProperties sat "Saturation property record";
            output Density dv "Dew curve density";
          end dewDensity;

          replaceable partial function saturationPressure "Return saturation pressure"
            input Temperature T "Temperature";
            output AbsolutePressure p "Saturation pressure";
          end saturationPressure;

          replaceable partial function saturationTemperature "Return saturation temperature"
            input AbsolutePressure p "Pressure";
            output Temperature T "Saturation temperature";
          end saturationTemperature;

          redeclare replaceable function extends molarMass "Return the molar mass of the medium"
          algorithm
            MM := fluidConstants[1].molarMass;
          end molarMass;

          redeclare replaceable function specificEnthalpy_pTX "Return specific enthalpy from pressure, temperature and mass fraction"
            input AbsolutePressure p "Pressure";
            input Temperature T "Temperature";
            input MassFraction X[:] "Mass fractions";
            input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            output SpecificEnthalpy h "Specific enthalpy at p, T, X";
          algorithm
            h := specificEnthalpy(setState_pTX(p, T, X, phase));
          end specificEnthalpy_pTX;

          redeclare replaceable function temperature_phX "Return temperature from p, h, and X or Xi"
            input AbsolutePressure p "Pressure";
            input SpecificEnthalpy h "Specific enthalpy";
            input MassFraction X[:] "Mass fractions";
            input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            output Temperature T "Temperature";
          algorithm
            T := temperature(setState_phX(p, h, X, phase));
          end temperature_phX;

          redeclare replaceable function density_phX "Return density from p, h, and X or Xi"
            input AbsolutePressure p "Pressure";
            input SpecificEnthalpy h "Specific enthalpy";
            input MassFraction X[:] "Mass fractions";
            input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            output Density d "Density";
          algorithm
            d := density(setState_phX(p, h, X, phase));
          end density_phX;

          replaceable function vapourQuality "Return vapour quality"
            input ThermodynamicState state "Thermodynamic state record";
            output MassFraction x "Vapour quality";
          protected
            constant SpecificEnthalpy eps = 1e-8;
          algorithm
            x := min(max((specificEnthalpy(state) - bubbleEnthalpy(setSat_p(pressure(state))))/(dewEnthalpy(setSat_p(pressure(state))) - bubbleEnthalpy(setSat_p(pressure(state))) + eps), 0), 1);
          end vapourQuality;

          redeclare replaceable function density_ph "Return density from p and h"
            input AbsolutePressure p "Pressure";
            input SpecificEnthalpy h "Specific enthalpy";
            input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            output Density d "Density";
          algorithm
            d := density_phX(p, h, fill(0, 0), phase);
          end density_ph;

          redeclare replaceable function temperature_ph "Return temperature from p and h"
            input AbsolutePressure p "Pressure";
            input SpecificEnthalpy h "Specific enthalpy";
            input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            output Temperature T "Temperature";
          algorithm
            T := temperature_phX(p, h, fill(0, 0), phase);
          end temperature_ph;

          redeclare replaceable function pressure_dT "Return pressure from d and T"
            input Density d "Density";
            input Temperature T "Temperature";
            input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            output AbsolutePressure p "Pressure";
          algorithm
            p := pressure(setState_dTX(d, T, fill(0, 0), phase));
          end pressure_dT;

          redeclare replaceable function specificEnthalpy_dT "Return specific enthalpy from d and T"
            input Density d "Density";
            input Temperature T "Temperature";
            input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            output SpecificEnthalpy h "Specific enthalpy";
          algorithm
            h := specificEnthalpy(setState_dTX(d, T, fill(0, 0), phase));
          end specificEnthalpy_dT;

          redeclare replaceable function specificEnthalpy_pT "Return specific enthalpy from p and T"
            input AbsolutePressure p "Pressure";
            input Temperature T "Temperature";
            input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            output SpecificEnthalpy h "Specific enthalpy";
          algorithm
            h := specificEnthalpy_pTX(p, T, fill(0, 0), phase);
          end specificEnthalpy_pT;

          redeclare replaceable function density_pT "Return density from p and T"
            input AbsolutePressure p "Pressure";
            input Temperature T "Temperature";
            input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            output Density d "Density";
          algorithm
            d := density(setState_pTX(p, T, fill(0, 0), phase));
          end density_pT;
        end PartialTwoPhaseMedium;

        partial package PartialSimpleMedium "Medium model with linear dependency of u, h from temperature. All other quantities, especially density, are constant."
          extends Interfaces.PartialPureSubstance(final ThermoStates = ThermofluidStream.Media.myMedia.Interfaces.Choices.IndependentVariables.pT, final singleState = true);
          constant SpecificHeatCapacity cp_const "Constant specific heat capacity at constant pressure";
          constant SpecificHeatCapacity cv_const "Constant specific heat capacity at constant volume";
          constant Density d_const "Constant density";
          constant DynamicViscosity eta_const "Constant dynamic viscosity";
          constant ThermalConductivity lambda_const "Constant thermal conductivity";
          constant VelocityOfSound a_const "Constant velocity of sound";
          constant Temperature T_min "Minimum temperature valid for medium model";
          constant Temperature T_max "Maximum temperature valid for medium model";
          constant Temperature T0 = reference_T "Zero enthalpy temperature";
          constant MolarMass MM_const "Molar mass";
          constant FluidConstants fluidConstants[nS] "Fluid constants";

          redeclare record extends ThermodynamicState "Thermodynamic state"
            AbsolutePressure p "Absolute pressure of medium";
            Temperature T "Temperature of medium";
          end ThermodynamicState;

          redeclare replaceable model extends BaseProperties(T(stateSelect = if preferredMediumStates then StateSelect.prefer else StateSelect.default), p(stateSelect = if preferredMediumStates then StateSelect.prefer else StateSelect.default)) "Base properties"
          equation
            assert(T >= T_min and T <= T_max, "
          Temperature T (= " + String(T) + " K) is not
          in the allowed range (" + String(T_min) + " K <= T <= " + String(T_max) + " K)
          required from medium model \"" + mediumName + "\".
            ");
            h = specificEnthalpy_pTX(p, T, X);
            u = cv_const*(T - T0);
            d = d_const;
            R_s = 0;
            MM = MM_const;
            state.T = T;
            state.p = p;
          end BaseProperties;

          redeclare function setState_pTX "Return thermodynamic state from p, T, and X or Xi"
            input AbsolutePressure p "Pressure";
            input Temperature T "Temperature";
            input MassFraction X[:] = reference_X "Mass fractions";
            output ThermodynamicState state "Thermodynamic state record";
          algorithm
            state := ThermodynamicState(p = p, T = T);
          end setState_pTX;

          redeclare function setState_phX "Return thermodynamic state from p, h, and X or Xi"
            input AbsolutePressure p "Pressure";
            input SpecificEnthalpy h "Specific enthalpy";
            input MassFraction X[:] = reference_X "Mass fractions";
            output ThermodynamicState state "Thermodynamic state record";
          algorithm
            state := ThermodynamicState(p = p, T = T0 + h/cp_const);
          end setState_phX;

          redeclare function setState_dTX "Return thermodynamic state from d, T, and X or Xi"
            input Density d "Density";
            input Temperature T "Temperature";
            input MassFraction X[:] = reference_X "Mass fractions";
            output ThermodynamicState state "Thermodynamic state record";
          algorithm
            assert(false, "Pressure can not be computed from temperature and density for an incompressible fluid!");
          end setState_dTX;

          redeclare function extends dynamicViscosity "Return dynamic viscosity"
          algorithm
            eta := eta_const;
          end dynamicViscosity;

          redeclare function extends pressure "Return pressure"
          algorithm
            p := state.p;
          end pressure;

          redeclare function extends temperature "Return temperature"
          algorithm
            T := state.T;
          end temperature;

          redeclare function extends density "Return density"
          algorithm
            d := d_const;
          end density;

          redeclare function extends specificEnthalpy "Return specific enthalpy"
          algorithm
            h := cp_const*(state.T - T0);
          end specificEnthalpy;

          redeclare function extends specificHeatCapacityCp "Return specific heat capacity at constant pressure"
          algorithm
            cp := cp_const;
          end specificHeatCapacityCp;

          redeclare function extends specificHeatCapacityCv "Return specific heat capacity at constant volume"
          algorithm
            cv := cv_const;
          end specificHeatCapacityCv;

          redeclare function extends isentropicExponent "Return isentropic exponent"
          algorithm
            gamma := cp_const/cv_const;
          end isentropicExponent;

          redeclare function extends velocityOfSound "Return velocity of sound"
          algorithm
            a := a_const;
          end velocityOfSound;

          redeclare function specificEnthalpy_pTX "Return specific enthalpy from p, T, and X or Xi"
            input AbsolutePressure p "Pressure";
            input Temperature T "Temperature";
            input MassFraction X[nX] "Mass fractions";
            output SpecificEnthalpy h "Specific enthalpy";
          algorithm
            h := cp_const*(T - T0);
          end specificEnthalpy_pTX;

          redeclare function temperature_phX "Return temperature from p, h, and X or Xi"
            input AbsolutePressure p "Pressure";
            input SpecificEnthalpy h "Specific enthalpy";
            input MassFraction X[nX] "Mass fractions";
            output Temperature T "Temperature";
          algorithm
            T := T0 + h/cp_const;
          end temperature_phX;

          redeclare function density_phX "Return density from p, h, and X or Xi"
            input AbsolutePressure p "Pressure";
            input SpecificEnthalpy h "Specific enthalpy";
            input MassFraction X[nX] "Mass fractions";
            output Density d "Density";
          algorithm
            d := density(setState_phX(p, h, X));
          end density_phX;

          redeclare function extends specificEntropy "Return specific entropy"
          algorithm
            s := cv_const*Modelica.Math.log(state.T/T0);
          end specificEntropy;

          redeclare function extends isobaricExpansionCoefficient "Returns overall the isobaric expansion coefficient beta"
          algorithm
            beta := 0.0;
          end isobaricExpansionCoefficient;

          redeclare function extends density_derp_h "Returns the partial derivative of density with respect to pressure at constant specific enthalpy"
          algorithm
            ddph := 0;
          end density_derp_h;

          redeclare function extends molarMass "Return the molar mass of the medium"
          algorithm
            MM := MM_const;
          end molarMass;
        end PartialSimpleMedium;

        package Choices "Types, constants to define menu choices"
          type IndependentVariables = enumeration(T "Temperature", pT "Pressure, Temperature", ph "Pressure, Specific Enthalpy", phX "Pressure, Specific Enthalpy, Mass Fraction", pTX "Pressure, Temperature, Mass Fractions", dTX "Density, Temperature, Mass Fractions") "Enumeration defining the independent variables of a medium";
          type Init = enumeration(NoInit "NoInit (no initialization)", InitialStates "InitialStates (initialize medium states)", SteadyState "SteadyState (initialize in steady state)", SteadyMass "SteadyMass (initialize density or pressure in steady state)") "Enumeration defining initialization for fluid flow" annotation(Evaluate = true);
          type pd = enumeration(default "Default (no boundary condition for p or d)", p_known "p_known (pressure p is known)", d_known "d_known (density d is known)") "Enumeration defining whether p or d are known for the boundary condition" annotation(Evaluate = true);
        end Choices;

        package Types "Types to be used in fluid models"
          type AbsolutePressure = SI.AbsolutePressure(min = 0, max = 1.e8, nominal = 1.e5, start = 1.e5) "Type for absolute pressure with medium specific attributes";
          type Density = SI.Density(min = 0, max = 1.e5, nominal = 1, start = 1) "Type for density with medium specific attributes";
          type DynamicViscosity = SI.DynamicViscosity(min = 0, max = 1.e8, nominal = 1.e-3, start = 1.e-3) "Type for dynamic viscosity with medium specific attributes";
          type EnthalpyFlowRate = SI.EnthalpyFlowRate(nominal = 1000.0, min = -1.0e8, max = 1.e8) "Type for enthalpy flow rate with medium specific attributes";
          type MassFraction = Real(quantity = "MassFraction", final unit = "kg/kg", min = 0, max = 1, nominal = 0.1) "Type for mass fraction with medium specific attributes";
          type MoleFraction = Real(quantity = "MoleFraction", final unit = "mol/mol", min = 0, max = 1, nominal = 0.1) "Type for mole fraction with medium specific attributes";
          type MolarMass = SI.MolarMass(min = 0.001, max = 0.25, nominal = 0.032) "Type for molar mass with medium specific attributes";
          type MolarVolume = SI.MolarVolume(min = 1e-6, max = 1.0e6, nominal = 1.0) "Type for molar volume with medium specific attributes";
          type IsentropicExponent = SI.RatioOfSpecificHeatCapacities(min = 1, max = 500000, nominal = 1.2, start = 1.2) "Type for isentropic exponent with medium specific attributes";
          type SpecificEnergy = SI.SpecificEnergy(min = -1.0e8, max = 1.e8, nominal = 1.e6) "Type for specific energy with medium specific attributes";
          type SpecificInternalEnergy = SpecificEnergy "Type for specific internal energy with medium specific attributes";
          type SpecificEnthalpy = SI.SpecificEnthalpy(min = -1.0e10, max = 1.e10, nominal = 1.e6) "Type for specific enthalpy with medium specific attributes";
          type SpecificEntropy = SI.SpecificEntropy(min = -1.e7, max = 1.e7, nominal = 1.e3) "Type for specific entropy with medium specific attributes";
          type SpecificHeatCapacity = SI.SpecificHeatCapacity(min = 0, max = 1.e7, nominal = 1.e3, start = 1.e3) "Type for specific heat capacity with medium specific attributes";
          type Temperature = SI.Temperature(min = 1, max = 1.e4, nominal = 300, start = 288.15) "Type for temperature with medium specific attributes";
          type ThermalConductivity = SI.ThermalConductivity(min = 0, max = 500, nominal = 1, start = 1) "Type for thermal conductivity with medium specific attributes";
          type VelocityOfSound = SI.Velocity(min = 0, max = 1.e5, nominal = 1000, start = 1000) "Type for velocity of sound with medium specific attributes";
          type ExtraProperty = Real(min = 0.0, start = 1.0) "Type for unspecified, mass-specific property transported by flow";
          type ExtraPropertyFlowRate = Real(unit = "kg/s") "Type for flow rate of unspecified, mass-specific property";
          type IsobaricExpansionCoefficient = Real(min = 0, max = 1.0e8, unit = "1/K") "Type for isobaric expansion coefficient with medium specific attributes";
          type DipoleMoment = Real(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment") "Type for dipole moment with medium specific attributes";
          type DerDensityByPressure = SI.DerDensityByPressure "Type for partial derivative of density with respect to pressure with medium specific attributes";

          replaceable record SaturationProperties "Saturation properties of two phase medium"
            AbsolutePressure psat "Saturation pressure";
            Temperature Tsat "Saturation temperature";
          end SaturationProperties;

          type FixedPhase = Integer(min = 0, max = 2) "Phase of the fluid: 1 for 1-phase, 2 for two-phase, 0 for not known, e.g., interactive use";

          package Basic "The most basic version of a record used in several degrees of detail"
            record FluidConstants "Critical, triple, molecular and other standard data of fluid"
              String iupacName "Complete IUPAC name (or common name, if non-existent)";
              String casRegistryNumber "Chemical abstracts sequencing number (if it exists)";
              String chemicalFormula "Chemical formula, (brutto, nomenclature according to Hill";
              String structureFormula "Chemical structure formula";
              MolarMass molarMass "Molar mass";
            end FluidConstants;
          end Basic;

          package TwoPhase "The two phase fluid version of a record used in several degrees of detail"
            record FluidConstants "Extended fluid constants"
              extends ThermofluidStream.Media.myMedia.Interfaces.Types.Basic.FluidConstants;
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
              Boolean hasVapourPressureCurve = false "True if vapour pressure data, e.g., Antoine coefficients are known";
              Boolean hasAcentricFactor = false "True if Pitzer acentric factor is known";
              SpecificEnthalpy HCRIT0 = 0.0 "Critical specific enthalpy of the fundamental equation";
              SpecificEntropy SCRIT0 = 0.0 "Critical specific entropy of the fundamental equation";
              SpecificEnthalpy deltah = 0.0 "Difference between specific enthalpy model (h_m) and f.eq. (h_f) (h_m - h_f)";
              SpecificEntropy deltas = 0.0 "Difference between specific enthalpy model (s_m) and f.eq. (s_f) (s_m - s_f)";
            end FluidConstants;
          end TwoPhase;
        end Types;
      end Interfaces;

      package Common "Data structures and fundamental functions for fluid properties"
        type DerPressureByDensity = Real(final quantity = "DerPressureByDensity", final unit = "Pa.m3/kg");
        type DerPressureByTemperature = Real(final quantity = "DerPressureByTemperature", final unit = "Pa/K");
        type IsentropicExponent = Real(final quantity = "IsentropicExponent", unit = "1");
        constant Real MINPOS = 1.0e-9 "Minimal value for physical variables which are always > 0.0";
        constant SI.Area AMIN = MINPOS "Minimal init area";
        constant SI.Area AMAX = 1.0e5 "Maximal init area";
        constant SI.Area ANOM = 1.0 "Nominal init area";
        constant SI.AmountOfSubstance MOLMIN = -1.0*MINPOS "Minimal Mole Number";
        constant SI.AmountOfSubstance MOLMAX = 1.0e8 "Maximal Mole Number";
        constant SI.AmountOfSubstance MOLNOM = 1.0 "Nominal Mole Number";
        constant SI.Density DMIN = 1e-6 "Minimal init density";
        constant SI.Density DMAX = 30.0e3 "Maximal init density";
        constant SI.Density DNOM = 1.0 "Nominal init density";
        constant SI.ThermalConductivity LAMMIN = MINPOS "Minimal thermal conductivity";
        constant SI.ThermalConductivity LAMNOM = 1.0 "Nominal thermal conductivity";
        constant SI.ThermalConductivity LAMMAX = 1000.0 "Maximal thermal conductivity";
        constant SI.DynamicViscosity ETAMIN = MINPOS "Minimal init dynamic viscosity";
        constant SI.DynamicViscosity ETAMAX = 1.0e8 "Maximal init dynamic viscosity";
        constant SI.DynamicViscosity ETANOM = 100.0 "Nominal init dynamic viscosity";
        constant SI.Energy EMIN = -1.0e10 "Minimal init energy";
        constant SI.Energy EMAX = 1.0e10 "Maximal init energy";
        constant SI.Energy ENOM = 1.0e3 "Nominal init energy";
        constant SI.Entropy SMIN = -1.0e6 "Minimal init entropy";
        constant SI.Entropy SMAX = 1.0e6 "Maximal init entropy";
        constant SI.Entropy SNOM = 1.0e3 "Nominal init entropy";
        constant SI.MassFlowRate MDOTMIN = -1.0e5 "Minimal init mass flow rate";
        constant SI.MassFlowRate MDOTMAX = 1.0e5 "Maximal init mass flow rate";
        constant SI.MassFlowRate MDOTNOM = 1.0 "Nominal init mass flow rate";
        constant SI.MassFraction MASSXMIN = -1.0*MINPOS "Minimal init mass fraction";
        constant SI.MassFraction MASSXMAX = 1.0 "Maximal init mass fraction";
        constant SI.MassFraction MASSXNOM = 0.1 "Nominal init mass fraction";
        constant SI.Mass MMIN = -1.0*MINPOS "Minimal init mass";
        constant SI.Mass MMAX = 1.0e8 "Maximal init mass";
        constant SI.Mass MNOM = 1.0 "Nominal init mass";
        constant SI.MolarMass MMMIN = 0.001 "Minimal initial molar mass";
        constant SI.MolarMass MMMAX = 250.0 "Maximal initial molar mass";
        constant SI.MolarMass MMNOM = 0.2 "Nominal initial molar mass";
        constant SI.MoleFraction MOLEYMIN = -1.0*MINPOS "Minimal init mole fraction";
        constant SI.MoleFraction MOLEYMAX = 1.0 "Maximal init mole fraction";
        constant SI.MoleFraction MOLEYNOM = 0.1 "Nominal init mole fraction";
        constant SI.MomentumFlux GMIN = -1.0e8 "Minimal init momentum flux";
        constant SI.MomentumFlux GMAX = 1.0e8 "Maximal init momentum flux";
        constant SI.MomentumFlux GNOM = 1.0 "Nominal init momentum flux";
        constant SI.Power POWMIN = -1.0e8 "Minimal init power or heat";
        constant SI.Power POWMAX = 1.0e8 "Maximal init power or heat";
        constant SI.Power POWNOM = 1.0e3 "Nominal init power or heat";
        constant SI.Pressure PMIN = 1.0e4 "Minimal init pressure";
        constant SI.Pressure PMAX = 1.0e8 "Maximal init pressure";
        constant SI.Pressure PNOM = 1.0e5 "Nominal init pressure";
        constant SI.Pressure COMPPMIN = -1.0*MINPOS "Minimal init pressure";
        constant SI.Pressure COMPPMAX = 1.0e8 "Maximal init pressure";
        constant SI.Pressure COMPPNOM = 1.0e5 "Nominal init pressure";
        constant SI.RatioOfSpecificHeatCapacities KAPPAMIN = 1.0 "Minimal init isentropic exponent";
        constant SI.RatioOfSpecificHeatCapacities KAPPAMAX = 1.7 "Maximal init isentropic exponent";
        constant SI.RatioOfSpecificHeatCapacities KAPPANOM = 1.2 "Nominal init isentropic exponent";
        constant SI.SpecificEnergy SEMIN = -1.0e8 "Minimal init specific energy";
        constant SI.SpecificEnergy SEMAX = 1.0e8 "Maximal init specific energy";
        constant SI.SpecificEnergy SENOM = 1.0e6 "Nominal init specific energy";
        constant SI.SpecificEnthalpy SHMIN = -1.0e8 "Minimal init specific enthalpy";
        constant SI.SpecificEnthalpy SHMAX = 1.0e8 "Maximal init specific enthalpy";
        constant SI.SpecificEnthalpy SHNOM = 1.0e6 "Nominal init specific enthalpy";
        constant SI.SpecificEntropy SSMIN = -1.0e6 "Minimal init specific entropy";
        constant SI.SpecificEntropy SSMAX = 1.0e6 "Maximal init specific entropy";
        constant SI.SpecificEntropy SSNOM = 1.0e3 "Nominal init specific entropy";
        constant SI.SpecificHeatCapacity CPMIN = MINPOS "Minimal init specific heat capacity";
        constant SI.SpecificHeatCapacity CPMAX = 1.0e6 "Maximal init specific heat capacity";
        constant SI.SpecificHeatCapacity CPNOM = 1.0e3 "Nominal init specific heat capacity";
        constant SI.Temperature TMIN = 1.0 "Minimal init temperature";
        constant SI.Temperature TMAX = 6000.0 "Maximal init temperature";
        constant SI.Temperature TNOM = 320.0 "Nominal init temperature";
        constant SI.ThermalConductivity LMIN = MINPOS "Minimal init thermal conductivity";
        constant SI.ThermalConductivity LMAX = 500.0 "Maximal init thermal conductivity";
        constant SI.ThermalConductivity LNOM = 1.0 "Nominal init thermal conductivity";
        constant SI.Velocity VELMIN = -1.0e5 "Minimal init speed";
        constant SI.Velocity VELMAX = 1.0e5 "Maximal init speed";
        constant SI.Velocity VELNOM = 1.0 "Nominal init speed";
        constant SI.Volume VMIN = 0.0 "Minimal init volume";
        constant SI.Volume VMAX = 1.0e5 "Maximal init volume";
        constant SI.Volume VNOM = 1.0e-3 "Nominal init volume";

        record SaturationProperties "Properties in the two phase region"
          SI.Temperature T "Temperature";
          SI.Density d "Density";
          SI.Pressure p "Pressure";
          SI.SpecificEnergy u "Specific inner energy";
          SI.SpecificEnthalpy h "Specific enthalpy";
          SI.SpecificEntropy s "Specific entropy";
          SI.SpecificHeatCapacity cp "Heat capacity at constant pressure";
          SI.SpecificHeatCapacity cv "Heat capacity at constant volume";
          SI.SpecificHeatCapacity R_s "Gas constant";
          SI.RatioOfSpecificHeatCapacities kappa "Isentropic expansion coefficient";
          PhaseBoundaryProperties liq "Thermodynamic base properties on the boiling curve";
          PhaseBoundaryProperties vap "Thermodynamic base properties on the dew curve";
          Real dpT(unit = "Pa/K") "Derivative of saturation pressure w.r.t. temperature";
          SI.MassFraction x "Vapour mass fraction";
        end SaturationProperties;

        record IF97BaseTwoPhase "Intermediate property data record for IF 97"
          Integer phase(start = 0) "Phase: 2 for two-phase, 1 for one phase, 0 if unknown";
          Integer region(min = 1, max = 5) "IF 97 region";
          SI.Pressure p "Pressure";
          SI.Temperature T "Temperature";
          SI.SpecificEnthalpy h "Specific enthalpy";
          SI.SpecificHeatCapacity R_s "Gas constant";
          SI.SpecificHeatCapacity cp "Specific heat capacity";
          SI.SpecificHeatCapacity cv "Specific heat capacity";
          SI.Density rho "Density";
          SI.SpecificEntropy s "Specific entropy";
          DerPressureByTemperature pt "Derivative of pressure w.r.t. temperature";
          DerPressureByDensity pd "Derivative of pressure w.r.t. density";
          Real vt "Derivative of specific volume w.r.t. temperature";
          Real vp "Derivative of specific volume w.r.t. pressure";
          Real x "Dryness fraction";
          Real dpT "dp/dT derivative of saturation curve";
        end IF97BaseTwoPhase;

        record IF97PhaseBoundaryProperties "Thermodynamic base properties on the phase boundary for IF97 steam tables"
          Boolean region3boundary "True if boundary between 2-phase and region 3";
          SI.SpecificHeatCapacity R_s "Specific heat capacity";
          SI.Temperature T "Temperature";
          SI.Density d "Density";
          SI.SpecificEnthalpy h "Specific enthalpy";
          SI.SpecificEntropy s "Specific entropy";
          SI.SpecificHeatCapacity cp "Heat capacity at constant pressure";
          SI.SpecificHeatCapacity cv "Heat capacity at constant volume";
          DerPressureByTemperature dpT "dp/dT derivative of saturation curve";
          DerPressureByTemperature pt "Derivative of pressure w.r.t. temperature";
          DerPressureByDensity pd "Derivative of pressure w.r.t. density";
          Real vt(unit = "m3/(kg.K)") "Derivative of specific volume w.r.t. temperature";
          Real vp(unit = "m3/(kg.Pa)") "Derivative of specific volume w.r.t. pressure";
        end IF97PhaseBoundaryProperties;

        record GibbsDerivs "Derivatives of dimensionless Gibbs-function w.r.t. dimensionless pressure and temperature"
          SI.Pressure p "Pressure";
          SI.Temperature T "Temperature";
          SI.SpecificHeatCapacity R_s "Specific heat capacity";
          Real pi(unit = "1") "Dimensionless pressure";
          Real tau(unit = "1") "Dimensionless temperature";
          Real g(unit = "1") "Dimensionless Gibbs-function";
          Real gpi(unit = "1") "Derivative of g w.r.t. pi";
          Real gpipi(unit = "1") "2nd derivative of g w.r.t. pi";
          Real gtau(unit = "1") "Derivative of g w.r.t. tau";
          Real gtautau(unit = "1") "2nd derivative of g w.r.t. tau";
          Real gtaupi(unit = "1") "Mixed derivative of g w.r.t. pi and tau";
        end GibbsDerivs;

        record HelmholtzDerivs "Derivatives of dimensionless Helmholtz-function w.r.t. dimensionless pressure, density and temperature"
          SI.Density d "Density";
          SI.Temperature T "Temperature";
          SI.SpecificHeatCapacity R_s "Specific heat capacity";
          Real delta(unit = "1") "Dimensionless density";
          Real tau(unit = "1") "Dimensionless temperature";
          Real f(unit = "1") "Dimensionless Helmholtz-function";
          Real fdelta(unit = "1") "Derivative of f w.r.t. delta";
          Real fdeltadelta(unit = "1") "2nd derivative of f w.r.t. delta";
          Real ftau(unit = "1") "Derivative of f w.r.t. tau";
          Real ftautau(unit = "1") "2nd derivative of f w.r.t. tau";
          Real fdeltatau(unit = "1") "Mixed derivative of f w.r.t. delta and tau";
        end HelmholtzDerivs;

        record PhaseBoundaryProperties "Thermodynamic base properties on the phase boundary"
          SI.Density d "Density";
          SI.SpecificEnthalpy h "Specific enthalpy";
          SI.SpecificEnergy u "Inner energy";
          SI.SpecificEntropy s "Specific entropy";
          SI.SpecificHeatCapacity cp "Heat capacity at constant pressure";
          SI.SpecificHeatCapacity cv "Heat capacity at constant volume";
          DerPressureByTemperature pt "Derivative of pressure w.r.t. temperature";
          DerPressureByDensity pd "Derivative of pressure w.r.t. density";
        end PhaseBoundaryProperties;

        record NewtonDerivatives_ph "Derivatives for fast inverse calculations of Helmholtz functions: p & h"
          SI.Pressure p "Pressure";
          SI.SpecificEnthalpy h "Specific enthalpy";
          DerPressureByDensity pd "Derivative of pressure w.r.t. density";
          DerPressureByTemperature pt "Derivative of pressure w.r.t. temperature";
          Real hd "Derivative of specific enthalpy w.r.t. density";
          Real ht "Derivative of specific enthalpy w.r.t. temperature";
        end NewtonDerivatives_ph;

        record NewtonDerivatives_pT "Derivatives for fast inverse calculations of Helmholtz functions:p & T"
          SI.Pressure p "Pressure";
          DerPressureByDensity pd "Derivative of pressure w.r.t. density";
        end NewtonDerivatives_pT;

        function gibbsToBoundaryProps "Calculate phase boundary property record from dimensionless Gibbs function"
          input GibbsDerivs g "Dimensionless derivatives of Gibbs function";
          output PhaseBoundaryProperties sat "Phase boundary properties";
        protected
          Real vt "Derivative of specific volume w.r.t. temperature";
          Real vp "Derivative of specific volume w.r.t. pressure";
        algorithm
          sat.d := g.p/(g.R_s*g.T*g.pi*g.gpi);
          sat.h := g.R_s*g.T*g.tau*g.gtau;
          sat.u := g.T*g.R_s*(g.tau*g.gtau - g.pi*g.gpi);
          sat.s := g.R_s*(g.tau*g.gtau - g.g);
          sat.cp := -g.R_s*g.tau*g.tau*g.gtautau;
          sat.cv := g.R_s*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/(g.gpipi));
          vt := g.R_s/g.p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
          vp := g.R_s*g.T/(g.p*g.p)*g.pi*g.pi*g.gpipi;
          sat.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
          sat.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
        end gibbsToBoundaryProps;

        function helmholtzToBoundaryProps "Calculate phase boundary property record from dimensionless Helmholtz function"
          input HelmholtzDerivs f "Dimensionless derivatives of Helmholtz function";
          output PhaseBoundaryProperties sat "Phase boundary property record";
        protected
          SI.Pressure p "Pressure";
        algorithm
          p := f.R_s*f.d*f.T*f.delta*f.fdelta;
          sat.d := f.d;
          sat.h := f.R_s*f.T*(f.tau*f.ftau + f.delta*f.fdelta);
          sat.s := f.R_s*(f.tau*f.ftau - f.f);
          sat.u := f.R_s*f.T*f.tau*f.ftau;
          sat.cp := f.R_s*(-f.tau*f.tau*f.ftautau + (f.delta*f.fdelta - f.delta*f.tau*f.fdeltatau)^2/(2*f.delta*f.fdelta + f.delta*f.delta*f.fdeltadelta));
          sat.cv := f.R_s*(-f.tau*f.tau*f.ftautau);
          sat.pt := f.R_s*f.d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
          sat.pd := f.R_s*f.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
        end helmholtzToBoundaryProps;

        function cv2Phase "Compute isochoric specific heat capacity inside the two-phase region"
          input PhaseBoundaryProperties liq "Properties on the boiling curve";
          input PhaseBoundaryProperties vap "Properties on the condensation curve";
          input SI.MassFraction x "Vapour mass fraction";
          input SI.Temperature T "Temperature";
          input SI.Pressure p "Properties";
          output SI.SpecificHeatCapacity cv "Isochoric specific heat capacity";
        protected
          Real dpT "Derivative of pressure w.r.t. temperature";
          Real dxv "Derivative of vapour mass fraction w.r.t. specific volume";
          Real dvTl "Derivative of liquid specific volume w.r.t. temperature";
          Real dvTv "Derivative of vapour specific volume w.r.t. temperature";
          Real duTl "Derivative of liquid specific inner energy w.r.t. temperature";
          Real duTv "Derivative of vapour specific inner energy w.r.t. temperature";
          Real dxt "Derivative of vapour mass fraction w.r.t. temperature";
        algorithm
          dxv := if (liq.d <> vap.d) then liq.d*vap.d/(liq.d - vap.d) else 0.0;
          dpT := (vap.s - liq.s)*dxv;
          dvTl := (liq.pt - dpT)/liq.pd/liq.d/liq.d;
          dvTv := (vap.pt - dpT)/vap.pd/vap.d/vap.d;
          dxt := -dxv*(dvTl + x*(dvTv - dvTl));
          duTl := liq.cv + (T*liq.pt - p)*dvTl;
          duTv := vap.cv + (T*vap.pt - p)*dvTv;
          cv := duTl + x*(duTv - duTl) + dxt*(vap.u - liq.u);
        end cv2Phase;

        function Helmholtz_ph "Function to calculate analytic derivatives for computing d and t given p and h"
          input HelmholtzDerivs f "Dimensionless derivatives of Helmholtz function";
          output NewtonDerivatives_ph nderivs "Derivatives for Newton iteration to calculate d and t from p and h";
        protected
          SI.SpecificHeatCapacity cv "Isochoric heat capacity";
        algorithm
          cv := -f.R_s*(f.tau*f.tau*f.ftautau);
          nderivs.p := f.d*f.R_s*f.T*f.delta*f.fdelta;
          nderivs.h := f.R_s*f.T*(f.tau*f.ftau + f.delta*f.fdelta);
          nderivs.pd := f.R_s*f.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
          nderivs.pt := f.R_s*f.d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
          nderivs.ht := cv + nderivs.pt/f.d;
          nderivs.hd := (nderivs.pd - f.T*nderivs.pt/f.d)/f.d;
        end Helmholtz_ph;

        function Helmholtz_pT "Function to calculate analytic derivatives for computing d and t given p and t"
          input HelmholtzDerivs f "Dimensionless derivatives of Helmholtz function";
          output NewtonDerivatives_pT nderivs "Derivatives for Newton iteration to compute d and t from p and t";
        algorithm
          nderivs.p := f.d*f.R_s*f.T*f.delta*f.fdelta;
          nderivs.pd := f.R_s*f.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
        end Helmholtz_pT;
      end Common;

      package Water "Medium models for water"
        import ThermofluidStream.Media.myMedia.Water.ConstantPropertyLiquidWater.simpleWaterConstants;
        constant ThermofluidStream.Media.myMedia.Interfaces.Types.TwoPhase.FluidConstants waterConstants[1](each chemicalFormula = "H2O", each structureFormula = "H2O", each casRegistryNumber = "7732-18-5", each iupacName = "oxidane", each molarMass = 0.018015268, each criticalTemperature = 647.096, each criticalPressure = 22064.0e3, each criticalMolarVolume = 1/322.0*0.018015268, each normalBoilingPoint = 373.124, each meltingPoint = 273.15, each triplePointTemperature = 273.16, each triplePointPressure = 611.657, each acentricFactor = 0.344, each dipoleMoment = 1.8, each hasCriticalData = true);

        package ConstantPropertyLiquidWater "Water: Simple liquid water medium (incompressible, constant data)"
          constant ThermofluidStream.Media.myMedia.Interfaces.Types.Basic.FluidConstants simpleWaterConstants[1](each chemicalFormula = "H2O", each structureFormula = "H2O", each casRegistryNumber = "7732-18-5", each iupacName = "oxidane", each molarMass = 0.018015268);
          extends Interfaces.PartialSimpleMedium(mediumName = "SimpleLiquidWater", cp_const = 4184, cv_const = 4184, d_const = 995.586, eta_const = 1.e-3, lambda_const = 0.598, a_const = 1484, T_min = Cv.from_degC(-1), T_max = Cv.from_degC(130), T0 = 273.15, MM_const = 0.018015268, fluidConstants = simpleWaterConstants);
        end ConstantPropertyLiquidWater;

        package StandardWater = WaterIF97_ph "Water using the IF97 standard, explicit in p and h. Recommended for most applications";

        package WaterIF97_ph "Water using the IF97 standard, explicit in p and h"
          extends WaterIF97_base(ThermoStates = ThermofluidStream.Media.myMedia.Interfaces.Choices.IndependentVariables.ph, final ph_explicit = true, final dT_explicit = false, final pT_explicit = false, smoothModel = false, onePhase = false);
        end WaterIF97_ph;

        partial package WaterIF97_base "Water: Steam properties as defined by IAPWS/IF97 standard"
          extends Interfaces.PartialTwoPhaseMedium(mediumName = "WaterIF97", substanceNames = {"water"}, singleState = false, SpecificEnthalpy(start = 1.0e5, nominal = 5.0e5), Density(start = 150, nominal = 500), AbsolutePressure(start = 50e5, nominal = 10e5, min = 611.657, max = 100e6), Temperature(start = 500, nominal = 500, min = 273.15, max = 2273.15), smoothModel = false, onePhase = false, fluidConstants = waterConstants);

          redeclare record extends SaturationProperties end SaturationProperties;

          redeclare record extends ThermodynamicState "Thermodynamic state"
            SpecificEnthalpy h "Specific enthalpy";
            Density d "Density";
            Temperature T "Temperature";
            AbsolutePressure p "Pressure";
          end ThermodynamicState;

          constant Integer Region = 0 "Region of IF97, if known, zero otherwise";
          constant Boolean ph_explicit "True if explicit in pressure and specific enthalpy";
          constant Boolean dT_explicit "True if explicit in density and temperature";
          constant Boolean pT_explicit "True if explicit in pressure and temperature";

          redeclare replaceable model extends BaseProperties(h(stateSelect = if ph_explicit and preferredMediumStates then StateSelect.prefer else StateSelect.default), d(stateSelect = if dT_explicit and preferredMediumStates then StateSelect.prefer else StateSelect.default), T(stateSelect = if (pT_explicit or dT_explicit) and preferredMediumStates then StateSelect.prefer else StateSelect.default), p(stateSelect = if (pT_explicit or ph_explicit) and preferredMediumStates then StateSelect.prefer else StateSelect.default)) "Base properties of water"
            Integer phase(min = 0, max = 2, start = 1, fixed = false) "2 for two-phase, 1 for one-phase, 0 if not known";
          equation
            MM = fluidConstants[1].molarMass;
            if Region > 0 then
              phase = (if Region == 4 then 2 else 1);
            elseif smoothModel then
              if onePhase then
                phase = 1;
                if ph_explicit then
                  assert(((h < bubbleEnthalpy(sat) or h > dewEnthalpy(sat)) or p > fluidConstants[1].criticalPressure), "With onePhase=true this model may only be called with one-phase states h < hl or h > hv!" + "(p = " + String(p) + ", h = " + String(h) + ")");
                else
                  if dT_explicit then
                    assert(not ((d < bubbleDensity(sat) and d > dewDensity(sat)) and T < fluidConstants[1].criticalTemperature), "With onePhase=true this model may only be called with one-phase states d > dl or d < dv!" + "(d = " + String(d) + ", T = " + String(T) + ")");
                  end if;
                end if;
              else
                phase = 0;
              end if;
            else
              if ph_explicit then
                phase = if ((h < bubbleEnthalpy(sat) or h > dewEnthalpy(sat)) or p > fluidConstants[1].criticalPressure) then 1 else 2;
              elseif dT_explicit then
                phase = if not ((d < bubbleDensity(sat) and d > dewDensity(sat)) and T < fluidConstants[1].criticalTemperature) then 1 else 2;
              else
                phase = 1;
              end if;
            end if;
            if dT_explicit then
              p = pressure_dT(d, T, phase, Region);
              h = specificEnthalpy_dT(d, T, phase, Region);
              sat.Tsat = T;
              sat.psat = saturationPressure(T);
            elseif ph_explicit then
              d = density_ph(p, h, phase, Region);
              T = temperature_ph(p, h, phase, Region);
              sat.Tsat = saturationTemperature(p);
              sat.psat = p;
            else
              h = specificEnthalpy_pT(p, T, Region);
              d = density_pT(p, T, Region);
              sat.psat = p;
              sat.Tsat = saturationTemperature(p);
            end if;
            u = h - p/d;
            R_s = Modelica.Constants.R/fluidConstants[1].molarMass;
            h = state.h;
            p = state.p;
            T = state.T;
            d = state.d;
            phase = state.phase;
          end BaseProperties;

          redeclare function density_ph "Computes density as a function of pressure and specific enthalpy"
            input AbsolutePressure p "Pressure";
            input SpecificEnthalpy h "Specific enthalpy";
            input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            input Integer region = Region "If 0, region is unknown, otherwise known and this input";
            output Density d "Density";
          algorithm
            d := IF97_Utilities.rho_ph(p, h, phase, region);
            annotation(Inline = true);
          end density_ph;

          redeclare function temperature_ph "Computes temperature as a function of pressure and specific enthalpy"
            input AbsolutePressure p "Pressure";
            input SpecificEnthalpy h "Specific enthalpy";
            input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            input Integer region = Region "If 0, region is unknown, otherwise known and this input";
            output Temperature T "Temperature";
          algorithm
            T := IF97_Utilities.T_ph(p, h, phase, region);
            annotation(Inline = true);
          end temperature_ph;

          redeclare function pressure_dT "Computes pressure as a function of density and temperature"
            input Density d "Density";
            input Temperature T "Temperature";
            input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            input Integer region = Region "If 0, region is unknown, otherwise known and this input";
            output AbsolutePressure p "Pressure";
          algorithm
            p := IF97_Utilities.p_dT(d, T, phase, region);
            annotation(Inline = true);
          end pressure_dT;

          redeclare function specificEnthalpy_dT "Computes specific enthalpy as a function of density and temperature"
            input Density d "Density";
            input Temperature T "Temperature";
            input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            input Integer region = Region "If 0, region is unknown, otherwise known and this input";
            output SpecificEnthalpy h "Specific enthalpy";
          algorithm
            h := IF97_Utilities.h_dT(d, T, phase, region);
            annotation(Inline = true);
          end specificEnthalpy_dT;

          redeclare function specificEnthalpy_pT "Computes specific enthalpy as a function of pressure and temperature"
            input AbsolutePressure p "Pressure";
            input Temperature T "Temperature";
            input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            input Integer region = Region "If 0, region is unknown, otherwise known and this input";
            output SpecificEnthalpy h "Specific enthalpy";
          algorithm
            h := IF97_Utilities.h_pT(p, T, region);
            annotation(Inline = true);
          end specificEnthalpy_pT;

          redeclare function density_pT "Computes density as a function of pressure and temperature"
            input AbsolutePressure p "Pressure";
            input Temperature T "Temperature";
            input FixedPhase phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            input Integer region = Region "If 0, region is unknown, otherwise known and this input";
            output Density d "Density";
          algorithm
            d := IF97_Utilities.rho_pT(p, T, region);
            annotation(Inline = true);
          end density_pT;

          redeclare function extends dynamicViscosity "Dynamic viscosity of water"
          algorithm
            eta := IF97_Utilities.dynamicViscosity(state.d, state.T, state.p, state.phase);
            annotation(Inline = true);
          end dynamicViscosity;

          redeclare function extends pressure "Return pressure of ideal gas"
          algorithm
            p := state.p;
            annotation(Inline = true);
          end pressure;

          redeclare function extends temperature "Return temperature of ideal gas"
          algorithm
            T := state.T;
            annotation(Inline = true);
          end temperature;

          redeclare function extends density "Return density of ideal gas"
          algorithm
            d := state.d;
            annotation(Inline = true);
          end density;

          redeclare function extends specificEnthalpy "Return specific enthalpy"
          algorithm
            h := state.h;
            annotation(Inline = true);
          end specificEnthalpy;

          redeclare function extends specificEntropy "Specific entropy of water"
          algorithm
            s := if dT_explicit then IF97_Utilities.s_dT(state.d, state.T, state.phase, Region) else if pT_explicit then IF97_Utilities.s_pT(state.p, state.T, Region) else IF97_Utilities.s_ph(state.p, state.h, state.phase, Region);
            annotation(Inline = true);
          end specificEntropy;

          redeclare function extends specificHeatCapacityCp "Specific heat capacity at constant pressure of water"
          algorithm
            cp := if dT_explicit then IF97_Utilities.cp_dT(state.d, state.T, Region) else if pT_explicit then IF97_Utilities.cp_pT(state.p, state.T, Region) else IF97_Utilities.cp_ph(state.p, state.h, Region);
            annotation(Inline = true);
          end specificHeatCapacityCp;

          redeclare function extends specificHeatCapacityCv "Specific heat capacity at constant volume of water"
          algorithm
            cv := if dT_explicit then IF97_Utilities.cv_dT(state.d, state.T, state.phase, Region) else if pT_explicit then IF97_Utilities.cv_pT(state.p, state.T, Region) else IF97_Utilities.cv_ph(state.p, state.h, state.phase, Region);
            annotation(Inline = true);
          end specificHeatCapacityCv;

          redeclare function extends isentropicExponent "Return isentropic exponent"
          algorithm
            gamma := if dT_explicit then IF97_Utilities.isentropicExponent_dT(state.d, state.T, state.phase, Region) else if pT_explicit then IF97_Utilities.isentropicExponent_pT(state.p, state.T, Region) else IF97_Utilities.isentropicExponent_ph(state.p, state.h, state.phase, Region);
            annotation(Inline = true);
          end isentropicExponent;

          redeclare function extends isobaricExpansionCoefficient "Isobaric expansion coefficient of water"
          algorithm
            beta := if dT_explicit then IF97_Utilities.beta_dT(state.d, state.T, state.phase, Region) else if pT_explicit then IF97_Utilities.beta_pT(state.p, state.T, Region) else IF97_Utilities.beta_ph(state.p, state.h, state.phase, Region);
            annotation(Inline = true);
          end isobaricExpansionCoefficient;

          redeclare function extends velocityOfSound "Return velocity of sound as a function of the thermodynamic state record"
          algorithm
            a := if dT_explicit then IF97_Utilities.velocityOfSound_dT(state.d, state.T, state.phase, Region) else if pT_explicit then IF97_Utilities.velocityOfSound_pT(state.p, state.T, Region) else IF97_Utilities.velocityOfSound_ph(state.p, state.h, state.phase, Region);
            annotation(Inline = true);
          end velocityOfSound;

          redeclare function extends density_derp_h "Density derivative by pressure"
          algorithm
            ddph := IF97_Utilities.ddph(state.p, state.h, state.phase, Region);
            annotation(Inline = true);
          end density_derp_h;

          redeclare function extends bubbleEnthalpy "Boiling curve specific enthalpy of water"
          algorithm
            hl := IF97_Utilities.BaseIF97.Regions.hl_p(sat.psat);
            annotation(Inline = true);
          end bubbleEnthalpy;

          redeclare function extends dewEnthalpy "Dew curve specific enthalpy of water"
          algorithm
            hv := IF97_Utilities.BaseIF97.Regions.hv_p(sat.psat);
            annotation(Inline = true);
          end dewEnthalpy;

          redeclare function extends bubbleDensity "Boiling curve specific density of water"
          algorithm
            dl := if ph_explicit or pT_explicit then IF97_Utilities.BaseIF97.Regions.rhol_p(sat.psat) else IF97_Utilities.BaseIF97.Regions.rhol_T(sat.Tsat);
            annotation(Inline = true);
          end bubbleDensity;

          redeclare function extends dewDensity "Dew curve specific density of water"
          algorithm
            dv := if ph_explicit or pT_explicit then IF97_Utilities.BaseIF97.Regions.rhov_p(sat.psat) else IF97_Utilities.BaseIF97.Regions.rhov_T(sat.Tsat);
            annotation(Inline = true);
          end dewDensity;

          redeclare function extends saturationTemperature "Saturation temperature of water"
          algorithm
            T := IF97_Utilities.BaseIF97.Basic.tsat(p);
            annotation(Inline = true);
          end saturationTemperature;

          redeclare function extends saturationPressure "Saturation pressure of water"
          algorithm
            p := IF97_Utilities.BaseIF97.Basic.psat(T);
            annotation(Inline = true);
          end saturationPressure;

          redeclare function extends setState_dTX "Return thermodynamic state of water as function of d, T, and optional region"
            input Integer region = Region "If 0, region is unknown, otherwise known and this input";
          algorithm
            state := ThermodynamicState(d = d, T = T, phase = if region == 0 then 0 else if region == 4 then 2 else 1, h = specificEnthalpy_dT(d, T, region = region), p = pressure_dT(d, T, region = region));
            annotation(Inline = true);
          end setState_dTX;

          redeclare function extends setState_phX "Return thermodynamic state of water as function of p, h, and optional region"
            input Integer region = Region "If 0, region is unknown, otherwise known and this input";
          algorithm
            state := ThermodynamicState(d = density_ph(p, h, region = region), T = temperature_ph(p, h, region = region), phase = if region == 0 then 0 else if region == 4 then 2 else 1, h = h, p = p);
            annotation(Inline = true);
          end setState_phX;

          redeclare function extends setState_pTX "Return thermodynamic state of water as function of p, T, and optional region"
            input Integer region = Region "If 0, region is unknown, otherwise known and this input";
          algorithm
            state := ThermodynamicState(d = density_pT(p, T, region = region), T = T, phase = 1, h = specificEnthalpy_pT(p, T, region = region), p = p);
            annotation(Inline = true);
          end setState_pTX;
        end WaterIF97_base;

        package IF97_Utilities "Low level and utility computation for high accuracy water properties according to the IAPWS/IF97 standard"
          package BaseIF97 "Modelica Physical Property Model: the new industrial formulation IAPWS-IF97"
            record IterationData "Constants for iterations internal to some functions"
              constant Integer IMAX = 50 "Maximum number of iterations for inverse functions";
              constant Real DELP = 1.0e-6 "Maximum iteration error in pressure, Pa";
              constant Real DELS = 1.0e-8 "Maximum iteration error in specific entropy, J/{kg.K}";
              constant Real DELH = 1.0e-8 "Maximum iteration error in specific enthalpy, J/kg";
              constant Real DELD = 1.0e-8 "Maximum iteration error in density, kg/m^3";
            end IterationData;

            record data "Constant IF97 data and region limits"
              constant SI.SpecificHeatCapacity RH2O = 461.526 "Specific gas constant of water vapour";
              constant SI.MolarMass MH2O = 0.01801528 "Molar weight of water";
              constant SI.Temperature TSTAR1 = 1386.0 "Normalization temperature for region 1 IF97";
              constant SI.Pressure PSTAR1 = 16.53e6 "Normalization pressure for region 1 IF97";
              constant SI.Temperature TSTAR2 = 540.0 "Normalization temperature for region 2 IF97";
              constant SI.Pressure PSTAR2 = 1.0e6 "Normalization pressure for region 2 IF97";
              constant SI.Temperature TSTAR5 = 1000.0 "Normalization temperature for region 5 IF97";
              constant SI.Pressure PSTAR5 = 1.0e6 "Normalization pressure for region 5 IF97";
              constant SI.SpecificEnthalpy HSTAR1 = 2.5e6 "Normalization specific enthalpy for region 1 IF97";
              constant Real IPSTAR = 1.0e-6 "Normalization pressure for inverse function in region 2 IF97";
              constant Real IHSTAR = 5.0e-7 "Normalization specific enthalpy for inverse function in region 2 IF97";
              constant SI.Temperature TLIMIT1 = 623.15 "Temperature limit between regions 1 and 3";
              constant SI.Temperature TLIMIT2 = 1073.15 "Temperature limit between regions 2 and 5";
              constant SI.Temperature TLIMIT5 = 2273.15 "Upper temperature limit of 5";
              constant SI.Pressure PLIMIT1 = 100.0e6 "Upper pressure limit for regions 1, 2 and 3";
              constant SI.Pressure PLIMIT4A = 16.5292e6 "Pressure limit between regions 1 and 2, important for two-phase (region 4)";
              constant SI.Pressure PLIMIT5 = 10.0e6 "Upper limit of valid pressure in region 5";
              constant SI.Pressure PCRIT = 22064000.0 "The critical pressure";
              constant SI.Temperature TCRIT = 647.096 "The critical temperature";
              constant SI.Density DCRIT = 322.0 "The critical density";
              constant SI.SpecificEntropy SCRIT = 4412.02148223476 "The calculated specific entropy at the critical point";
              constant SI.SpecificEnthalpy HCRIT = 2087546.84511715 "The calculated specific enthalpy at the critical point";
              constant Real n[5] = array(0.34805185628969e3, -0.11671859879975e1, 0.10192970039326e-2, 0.57254459862746e3, 0.13918839778870e2) "Polynomial coefficients for boundary between regions 2 and 3";
            end data;

            record triple "Triple point data"
              constant SI.Temperature Ttriple = 273.16 "The triple point temperature";
              constant SI.Pressure ptriple = 611.657 "The triple point pressure";
              constant SI.Density dltriple = 999.792520031617642 "The triple point liquid density";
              constant SI.Density dvtriple = 0.485457572477861372e-2 "The triple point vapour density";
            end triple;

            package Regions "Functions to find the current region for given pairs of input variables"
              function boundary23ofT "Boundary function for region boundary between regions 2 and 3 (input temperature)"
                input SI.Temperature t "Temperature (K)";
                output SI.Pressure p "Pressure";
              protected
                constant Real n[5] = data.n;
              algorithm
                p := 1.0e6*(n[1] + t*(n[2] + t*n[3]));
              end boundary23ofT;

              function boundary23ofp "Boundary function for region boundary between regions 2 and 3 (input pressure)"
                input SI.Pressure p "Pressure";
                output SI.Temperature t "Temperature (K)";
              protected
                constant Real n[5] = data.n;
                Real pi "Dimensionless pressure";
              algorithm
                pi := p/1.0e6;
                assert(p > triple.ptriple, "IF97 medium function boundary23ofp called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
                t := n[4] + ((pi - n[5])/n[3])^0.5;
              end boundary23ofp;

              function hlowerofp5 "Explicit lower specific enthalpy limit of region 5 as function of pressure"
                input SI.Pressure p "Pressure";
                output SI.SpecificEnthalpy h "Specific enthalpy";
              protected
                Real pi "Dimensionless pressure";
              algorithm
                pi := p/data.PSTAR5;
                assert(p > triple.ptriple, "IF97 medium function hlowerofp5 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
                h := 461526.*(9.01505286876203 + pi*(-0.00979043490246092 + (-0.0000203245575263501 + 3.36540214679088e-7*pi)*pi));
              end hlowerofp5;

              function hupperofp5 "Explicit upper specific enthalpy limit of region 5 as function of pressure"
                input SI.Pressure p "Pressure";
                output SI.SpecificEnthalpy h "Specific enthalpy";
              protected
                Real pi "Dimensionless pressure";
              algorithm
                pi := p/data.PSTAR5;
                assert(p > triple.ptriple, "IF97 medium function hupperofp5 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
                h := 461526.*(15.9838891400332 + pi*(-0.000489898813722568 + (-5.01510211858761e-8 + 7.5006972718273e-8*pi)*pi));
              end hupperofp5;

              function hlowerofp1 "Explicit lower specific enthalpy limit of region 1 as function of pressure"
                input SI.Pressure p "Pressure";
                output SI.SpecificEnthalpy h "Specific enthalpy";
              protected
                Real pi1 "Dimensionless pressure";
                Real o[3] "Vector of auxiliary variables";
              algorithm
                pi1 := 7.1 - p/data.PSTAR1;
                assert(p > triple.ptriple, "IF97 medium function hlowerofp1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
                o[1] := pi1*pi1;
                o[2] := o[1]*o[1];
                o[3] := o[2]*o[2];
                h := 639675.036*(0.173379420894777 + pi1*(-0.022914084306349 + pi1*(-0.00017146768241932 + pi1*(-4.18695814670391e-6 + pi1*(-2.41630417490008e-7 + pi1*(1.73545618580828e-11 + o[1]*pi1*(8.43755552264362e-14 + o[2]*o[3]*pi1*(5.35429206228374e-35 + o[1]*(-8.12140581014818e-38 + o[1]*o[2]*(-1.43870236842915e-44 + pi1*(1.73894459122923e-45 + (-7.06381628462585e-47 + 9.64504638626269e-49*pi1)*pi1)))))))))));
              end hlowerofp1;

              function hupperofp1 "Explicit upper specific enthalpy limit of region 1 as function of pressure (meets region 4 saturation pressure curve at 623.15 K)"
                input SI.Pressure p "Pressure";
                output SI.SpecificEnthalpy h "Specific enthalpy";
              protected
                Real pi1 "Dimensionless pressure";
                Real o[3] "Vector of auxiliary variables";
              algorithm
                pi1 := 7.1 - p/data.PSTAR1;
                assert(p > triple.ptriple, "IF97 medium function hupperofp1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
                o[1] := pi1*pi1;
                o[2] := o[1]*o[1];
                o[3] := o[2]*o[2];
                h := 639675.036*(2.42896927729349 + pi1*(-0.00141131225285294 + pi1*(0.00143759406818289 + pi1*(0.000125338925082983 + pi1*(0.0000123617764767172 + pi1*(3.17834967400818e-6 + o[1]*pi1*(1.46754947271665e-8 + o[2]*o[3]*pi1*(1.86779322717506e-17 + o[1]*(-4.18568363667416e-19 + o[1]*o[2]*(-9.19148577641497e-22 + pi1*(4.27026404402408e-22 + (-6.66749357417962e-23 + 3.49930466305574e-24*pi1)*pi1)))))))))));
              end hupperofp1;

              function hlowerofp2 "Explicit lower specific enthalpy limit of region 2 as function of pressure (meets region 4 saturation pressure curve at 623.15 K)"
                input SI.Pressure p "Pressure";
                output SI.SpecificEnthalpy h "Specific enthalpy";
              protected
                Real pi "Dimensionless pressure";
                Real q1 "Auxiliary variable";
                Real q2 "Auxiliary variable";
                Real o[18] "Vector of auxiliary variables";
              algorithm
                pi := p/data.PSTAR2;
                assert(p > triple.ptriple, "IF97 medium function hlowerofp2 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
                q1 := 572.54459862746 + 31.3220101646784*(-13.91883977887 + pi)^0.5;
                q2 := -0.5 + 540./q1;
                o[1] := q1*q1;
                o[2] := o[1]*o[1];
                o[3] := o[2]*o[2];
                o[4] := pi*pi;
                o[5] := o[4]*o[4];
                o[6] := q2*q2;
                o[7] := o[6]*o[6];
                o[8] := o[6]*o[7];
                o[9] := o[5]*o[5];
                o[10] := o[7]*o[7];
                o[11] := o[9]*o[9];
                o[12] := o[10]*o[10];
                o[13] := o[12]*o[12];
                o[14] := o[7]*q2;
                o[15] := o[6]*q2;
                o[16] := o[10]*o[6];
                o[17] := o[13]*o[6];
                o[18] := o[13]*o[6]*q2;
                h := (4.63697573303507e9 + 3.74686560065793*o[2] + 3.57966647812489e-6*o[1]*o[2] + 2.81881548488163e-13*o[3] - 7.64652332452145e7*q1 - 0.00450789338787835*o[2]*q1 - 1.55131504410292e-9*o[1]*o[2]*q1 + o[1]*(2.51383707870341e6 - 4.78198198764471e6*o[10]*o[11]*o[12]*o[13]*o[4] + 49.9651389369988*o[11]*o[12]*o[13]*o[4]*o[5]*o[7] + o[15]*o[4]*(1.03746636552761e-13 - 0.00349547959376899*o[16] - 2.55074501962569e-7*o[8])*o[9] + (-242662.235426958*o[10]*o[12] - 3.46022402653609*o[16])*o[4]*o[5]*pi + o[4]*(0.109336249381227 - 2248.08924686956*o[14] - 354742.725841972*o[17] - 24.1331193696374*o[6])*pi - 3.09081828396912e-19*o[11]*o[12]*o[5]*o[7]*pi - 1.24107527851371e-8*o[11]*o[13]*o[4]*o[5]*o[6]*o[7]*pi + 3.99891272904219*o[5]*o[8]*pi + 0.0641817365250892*o[10]*o[7]*o[9]*pi + pi*(-4444.87643334512 - 75253.6156722047*o[14] - 43051.9020511789*o[6] - 22926.6247146068*q2) + o[4]*(-8.23252840892034 - 3927.0508365636*o[15] - 239.325789467604*o[18] - 76407.3727417716*o[8] - 94.4508644545118*q2) + 0.360567666582363*o[5]*(-0.0161221195808321 + q2)*(0.0338039844460968 + q2) + o[11]*(-0.000584580992538624*o[10]*o[12]*o[7] + 1.33248030241755e6*o[12]*o[13]*q2) + o[9]*(-7.38502736990986e7*o[18] + 0.0000224425477627799*o[6]*o[7]*q2) + o[4]*o[5]*(-2.08438767026518e8*o[17] - 0.0000124971648677697*o[6] - 8442.30378348203*o[10]*o[6]*o[7]*q2) + o[11]*o[9]*(4.73594929247646e-22*o[10]*o[12]*q2 - 13.6411358215175*o[10]*o[12]*o[13]*q2 + 5.52427169406836e-10*o[13]*o[6]*o[7]*q2) + o[11]*o[5]*(2.67174673301715e-6*o[17] + 4.44545133805865e-18*o[12]*o[6]*q2 - 50.2465185106411*o[10]*o[13]*o[6]*o[7]*q2)))/o[1];
              end hlowerofp2;

              function hupperofp2 "Explicit upper specific enthalpy limit of region 2 as function of pressure"
                input SI.Pressure p "Pressure";
                output SI.SpecificEnthalpy h "Specific enthalpy";
              protected
                Real pi "Dimensionless pressure";
                Real o[2] "Vector of auxiliary variables";
              algorithm
                pi := p/data.PSTAR2;
                assert(p > triple.ptriple, "IF97 medium function hupperofp2 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
                o[1] := pi*pi;
                o[2] := o[1]*o[1]*o[1];
                h := 4.16066337647071e6 + pi*(-4518.48617188327 + pi*(-8.53409968320258 + pi*(0.109090430596056 + pi*(-0.000172486052272327 + pi*(4.2261295097284e-15 + pi*(-1.27295130636232e-10 + pi*(-3.79407294691742e-25 + pi*(7.56960433802525e-23 + pi*(7.16825117265975e-32 + pi*(3.37267475986401e-21 + (-7.5656940729795e-74 + o[1]*(-8.00969737237617e-134 + (1.6746290980312e-65 + pi*(-3.71600586812966e-69 + pi*(8.06630589170884e-129 + (-1.76117969553159e-103 + 1.88543121025106e-84*pi)*pi)))*o[1]))*o[2]))))))))));
              end hupperofp2;

              function d1n "Density in region 1 as function of p and T"
                input SI.Pressure p "Pressure";
                input SI.Temperature T "Temperature (K)";
                output SI.Density d "Density";
              protected
                Real pi "Dimensionless pressure";
                Real pi1 "Dimensionless pressure";
                Real tau "Dimensionless temperature";
                Real tau1 "Dimensionless temperature";
                Real gpi "Dimensionless Gibbs-derivative w.r.t. pi";
                Real o[11] "Auxiliary variables";
              algorithm
                pi := p/data.PSTAR1;
                tau := data.TSTAR1/T;
                pi1 := 7.1 - pi;
                tau1 := tau - 1.222;
                o[1] := tau1*tau1;
                o[2] := o[1]*o[1];
                o[3] := o[2]*o[2];
                o[4] := o[1]*o[2];
                o[5] := o[1]*tau1;
                o[6] := o[2]*tau1;
                o[7] := pi1*pi1;
                o[8] := o[7]*o[7];
                o[9] := o[8]*o[8];
                o[10] := o[3]*o[3];
                o[11] := o[10]*o[10];
                gpi := pi1*(pi1*((0.000095038934535162 + o[2]*(8.4812393955936e-6 + 2.55615384360309e-9*o[4]))/o[2] + pi1*((8.9701127632e-6 + (2.60684891582404e-6 + 5.7366919751696e-13*o[2]*o[3])*o[5])/o[6] + pi1*(2.02584984300585e-6/o[3] + o[7]*pi1*(o[8]*o[9]*pi1*(o[7]*(o[7]*o[8]*(-7.63737668221055e-22/(o[1]*o[11]*o[2]) + pi1*(pi1*(-5.65070932023524e-23/(o[11]*o[3]) + (2.99318679335866e-24*pi1)/(o[11]*o[3]*tau1)) + 3.5842867920213e-22/(o[1]*o[11]*o[2]*tau1))) - 3.33001080055983e-19/(o[1]*o[10]*o[2]*o[3]*tau1)) + 1.44400475720615e-17/(o[10]*o[2]*o[3]*tau1)) + (1.01874413933128e-8 + 1.39398969845072e-9*o[6])/(o[1]*o[3]*tau1))))) + (0.00094368642146534 + o[5]*(0.00060003561586052 + (-0.000095322787813974 + o[1]*(8.8283690661692e-6 + 1.45389992595188e-15*o[1]*o[2]*o[3]))*tau1))/o[5]) + (-0.00028319080123804 + o[1]*(0.00060706301565874 + o[4]*(0.018990068218419 + tau1*(0.032529748770505 + (0.021841717175414 + 0.00005283835796993*o[1])*tau1))))/(o[3]*tau1);
                d := p/(data.RH2O*T*pi*gpi);
              end d1n;

              function d2n "Density in region 2 as function of p and T"
                input SI.Pressure p "Pressure";
                input SI.Temperature T "Temperature (K)";
                output SI.Density d "Density";
              protected
                Real pi "Dimensionless pressure";
                Real tau "Dimensionless temperature";
                Real tau2 "Dimensionless temperature";
                Real gpi "Dimensionless Gibbs-derivative w.r.t. pi";
                Real o[12] "Auxiliary variables";
              algorithm
                pi := p/data.PSTAR2;
                tau := data.TSTAR2/T;
                tau2 := tau - 0.5;
                o[1] := tau2*tau2;
                o[2] := o[1]*tau2;
                o[3] := o[1]*o[1];
                o[4] := o[3]*o[3];
                o[5] := o[4]*o[4];
                o[6] := o[3]*o[4]*o[5]*tau2;
                o[7] := o[3]*o[4]*tau2;
                o[8] := o[1]*o[3]*o[4];
                o[9] := pi*pi;
                o[10] := o[9]*o[9];
                o[11] := o[3]*o[5]*tau2;
                o[12] := o[5]*o[5];
                gpi := (1. + pi*(-0.0017731742473213 + tau2*(-0.017834862292358 + tau2*(-0.045996013696365 + (-0.057581259083432 - 0.05032527872793*o[2])*tau2)) + pi*(tau2*(-0.000066065283340406 + (-0.0003789797503263 + o[1]*(-0.007878555448671 + o[2]*(-0.087594591301146 - 0.000053349095828174*o[6])))*tau2) + pi*(6.1445213076927e-8 + (1.31612001853305e-6 + o[1]*(-0.00009683303171571 + o[2]*(-0.0045101773626444 - 0.122004760687947*o[6])))*tau2 + pi*(tau2*(-3.15389238237468e-9 + (5.116287140914e-8 + 1.92901490874028e-6*tau2)*tau2) + pi*(0.0000114610381688305*o[1]*o[3]*tau2 + pi*(o[2]*(-1.00288598706366e-10 + o[7]*(-0.012702883392813 - 143.374451604624*o[1]*o[5]*tau2)) + pi*(-4.1341695026989e-17 + o[1]*o[4]*(-8.8352662293707e-6 - 0.272627897050173*o[8])*tau2 + pi*(o[4]*(9.0049690883672e-11 - 65.8490727183984*o[3]*o[4]*o[5]) + pi*(1.78287415218792e-7*o[7] + pi*(o[3]*(1.0406965210174e-18 + o[1]*(-1.0234747095929e-12 - 1.0018179379511e-8*o[3])*o[3]) + o[10]*o[9]*((-1.29412653835176e-9 + 1.71088510070544*o[11])*o[6] + o[9]*(-6.05920510335078*o[12]*o[4]*o[5]*tau2 + o[9]*(o[3]*o[5]*(1.78371690710842e-23 + o[1]*o[3]*o[4]*(6.1258633752464e-12 - 0.000084004935396416*o[7])*tau2) + pi*(-1.24017662339842e-24*o[11] + pi*(0.0000832192847496054*o[12]*o[3]*o[5]*tau2 + pi*(o[1]*o[4]*o[5]*(1.75410265428146e-27 + (1.32995316841867e-15 - 0.0000226487297378904*o[1]*o[5])*o[8])*pi - 2.93678005497663e-14*o[1]*o[12]*o[3]*tau2)))))))))))))))))/pi;
                d := p/(data.RH2O*T*pi*gpi);
              end d2n;

              function hl_p_R4b "Explicit approximation of liquid specific enthalpy on the boundary between regions 4 and 3"
                input SI.Pressure p "Pressure";
                output SI.SpecificEnthalpy h "Specific enthalpy";
              protected
                Real x "Auxiliary variable";
              algorithm
                x := Modelica.Math.acos(p/data.PCRIT);
                h := (1 + x*(-0.4945586958175176 + x*(1.346800016564904 + x*(-3.889388153209752 + x*(6.679385472887931 + x*(-6.75820241066552 + x*(3.558919744656498 + (-0.7179818554978939 - 0.0001152032945617821*x)*x)))))))*data.HCRIT;
              end hl_p_R4b;

              function hv_p_R4b "Explicit approximation of vapour specific enthalpy on the boundary between regions 4 and 3"
                input SI.Pressure p "Pressure";
                output SI.SpecificEnthalpy h "Specific enthalpy";
              protected
                Real x "Auxiliary variable";
              algorithm
                x := Modelica.Math.acos(p/data.PCRIT);
                h := (1 + x*(0.4880153718655694 + x*(0.2079670746250689 + x*(-6.084122698421623 + x*(25.08887602293532 + x*(-48.38215180269516 + x*(45.66489164833212 + (-16.98555442961553 + 0.0006616936460057691*x)*x)))))))*data.HCRIT;
              end hv_p_R4b;

              function rhol_p_R4b "Explicit approximation of liquid density on the boundary between regions 4 and 3"
                input SI.Pressure p "Pressure";
                output SI.Density dl "Liquid density";
              protected
                Real x "Auxiliary variable";
              algorithm
                if (p < data.PCRIT) then
                  x := Modelica.Math.acos(p/data.PCRIT);
                  dl := (1 + x*(1.903224079094824 + x*(-2.5314861802401123 + x*(-8.191449323843552 + x*(94.34196116778385 + x*(-369.3676833623383 + x*(796.6627910598293 + x*(-994.5385383600702 + x*(673.2581177021598 + (-191.43077336405156 + 0.00052536560808895*x)*x)))))))))*data.DCRIT;
                else
                  dl := data.DCRIT;
                end if;
              end rhol_p_R4b;

              function rhov_p_R4b "Explicit approximation of vapour density on the boundary between regions 4 and 2"
                input SI.Pressure p "Pressure";
                output SI.Density dv "Vapour density";
              protected
                Real x "Auxiliary variable";
              algorithm
                if (p < data.PCRIT) then
                  x := Modelica.Math.acos(p/data.PCRIT);
                  dv := (1 + x*(-1.8463850803362596 + x*(-1.1447872718878493 + x*(59.18702203076563 + x*(-403.5391431811611 + x*(1437.2007245332388 + x*(-3015.853540307519 + x*(3740.5790348670057 + x*(-2537.375817253895 + (725.8761975803782 - 0.0011151111658332337*x)*x)))))))))*data.DCRIT;
                else
                  dv := data.DCRIT;
                end if;
              end rhov_p_R4b;

              function boilingcurve_p "Properties on the boiling curve"
                input SI.Pressure p "Pressure";
                output Common.IF97PhaseBoundaryProperties bpro "Property record";
              protected
                Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives";
                Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives";
                SI.Pressure plim = min(p, data.PCRIT - 1e-7) "Pressure limited to critical pressure - epsilon";
              algorithm
                bpro.R_s := data.RH2O;
                bpro.T := Basic.tsat(plim);
                bpro.dpT := Basic.dptofT(bpro.T);
                bpro.region3boundary := bpro.T > data.TLIMIT1;
                if not bpro.region3boundary then
                  g := Basic.g1(p, bpro.T);
                  bpro.d := p/(bpro.R_s*bpro.T*g.pi*g.gpi);
                  bpro.h := if p > plim then data.HCRIT else bpro.R_s*bpro.T*g.tau*g.gtau;
                  bpro.s := g.R_s*(g.tau*g.gtau - g.g);
                  bpro.cp := -bpro.R_s*g.tau*g.tau*g.gtautau;
                  bpro.vt := bpro.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
                  bpro.vp := bpro.R_s*bpro.T/(p*p)*g.pi*g.pi*g.gpipi;
                  bpro.pt := -p/bpro.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
                  bpro.pd := -bpro.R_s*bpro.T*g.gpi*g.gpi/(g.gpipi);
                else
                  bpro.d := rhol_p_R4b(plim);
                  f := Basic.f3(bpro.d, bpro.T);
                  bpro.h := hl_p_R4b(plim);
                  bpro.s := f.R_s*(f.tau*f.ftau - f.f);
                  bpro.cv := bpro.R_s*(-f.tau*f.tau*f.ftautau);
                  bpro.pt := bpro.R_s*bpro.d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
                  bpro.pd := bpro.R_s*bpro.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
                end if;
              end boilingcurve_p;

              function dewcurve_p "Properties on the dew curve"
                input SI.Pressure p "Pressure";
                output Common.IF97PhaseBoundaryProperties bpro "Property record";
              protected
                Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives";
                Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives";
                SI.Pressure plim = min(p, data.PCRIT - 1e-7) "Pressure limited to critical pressure - epsilon";
              algorithm
                bpro.R_s := data.RH2O;
                bpro.T := Basic.tsat(plim);
                bpro.dpT := Basic.dptofT(bpro.T);
                bpro.region3boundary := bpro.T > data.TLIMIT1;
                if not bpro.region3boundary then
                  g := Basic.g2(p, bpro.T);
                  bpro.d := p/(bpro.R_s*bpro.T*g.pi*g.gpi);
                  bpro.h := if p > plim then data.HCRIT else bpro.R_s*bpro.T*g.tau*g.gtau;
                  bpro.s := g.R_s*(g.tau*g.gtau - g.g);
                  bpro.cp := -bpro.R_s*g.tau*g.tau*g.gtautau;
                  bpro.vt := bpro.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
                  bpro.vp := bpro.R_s*bpro.T/(p*p)*g.pi*g.pi*g.gpipi;
                  bpro.pt := -p/bpro.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
                  bpro.pd := -bpro.R_s*bpro.T*g.gpi*g.gpi/(g.gpipi);
                else
                  bpro.d := rhov_p_R4b(plim);
                  f := Basic.f3(bpro.d, bpro.T);
                  bpro.h := hv_p_R4b(plim);
                  bpro.s := f.R_s*(f.tau*f.ftau - f.f);
                  bpro.cv := bpro.R_s*(-f.tau*f.tau*f.ftautau);
                  bpro.pt := bpro.R_s*bpro.d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
                  bpro.pd := bpro.R_s*bpro.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
                end if;
              end dewcurve_p;

              function hvl_p
                input SI.Pressure p "Pressure";
                input Common.IF97PhaseBoundaryProperties bpro "Property record";
                output SI.SpecificEnthalpy h "Specific enthalpy";
              algorithm
                h := bpro.h;
                annotation(derivative(noDerivative = bpro) = hvl_p_der, Inline = false, LateInline = true);
              end hvl_p;

              function hl_p "Liquid specific enthalpy on the boundary between regions 4 and 3 or 1"
                input SI.Pressure p "Pressure";
                output SI.SpecificEnthalpy h "Specific enthalpy";
              algorithm
                h := hvl_p(p, boilingcurve_p(p));
                annotation(Inline = true);
              end hl_p;

              function hv_p "Vapour specific enthalpy on the boundary between regions 4 and 3 or 2"
                input SI.Pressure p "Pressure";
                output SI.SpecificEnthalpy h "Specific enthalpy";
              algorithm
                h := hvl_p(p, dewcurve_p(p));
                annotation(Inline = true);
              end hv_p;

              function hvl_p_der "Derivative function for the specific enthalpy along the phase boundary"
                input SI.Pressure p "Pressure";
                input Common.IF97PhaseBoundaryProperties bpro "Property record";
                input Real p_der "Derivative of pressure";
                output Real h_der "Time derivative of specific enthalpy along the phase boundary";
              algorithm
                if bpro.region3boundary then
                  h_der := ((bpro.d*bpro.pd - bpro.T*bpro.pt)*p_der + (bpro.T*bpro.pt*bpro.pt + bpro.d*bpro.d*bpro.pd*bpro.cv)/bpro.dpT*p_der)/(bpro.pd*bpro.d*bpro.d);
                else
                  h_der := (1/bpro.d - bpro.T*bpro.vt)*p_der + bpro.cp/bpro.dpT*p_der;
                end if;
                annotation(Inline = true);
              end hvl_p_der;

              function rhovl_p
                input SI.Pressure p "Pressure";
                input Common.IF97PhaseBoundaryProperties bpro "Property record";
                output SI.Density rho "Density";
              algorithm
                rho := bpro.d;
                annotation(derivative(noDerivative = bpro) = rhovl_p_der, Inline = false, LateInline = true);
              end rhovl_p;

              function rhol_p "Density of saturated water"
                input SI.Pressure p "Saturation pressure";
                output SI.Density rho "Density of steam at the condensation point";
              algorithm
                rho := rhovl_p(p, boilingcurve_p(p));
                annotation(Inline = true);
              end rhol_p;

              function rhov_p "Density of saturated vapour"
                input SI.Pressure p "Saturation pressure";
                output SI.Density rho "Density of steam at the condensation point";
              algorithm
                rho := rhovl_p(p, dewcurve_p(p));
                annotation(Inline = true);
              end rhov_p;

              function rhovl_p_der
                input SI.Pressure p "Saturation pressure";
                input Common.IF97PhaseBoundaryProperties bpro "Property record";
                input Real p_der "Derivative of pressure";
                output Real d_der "Time derivative of density along the phase boundary";
              algorithm
                d_der := if bpro.region3boundary then (p_der - bpro.pt*p_der/bpro.dpT)/bpro.pd else -bpro.d*bpro.d*(bpro.vp + bpro.vt/bpro.dpT)*p_der;
                annotation(Inline = true);
              end rhovl_p_der;

              function rhol_T "Density of saturated water"
                input SI.Temperature T "Temperature";
                output SI.Density d "Density of water at the boiling point";
              protected
                SI.Pressure p "Saturation pressure";
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

              function rhov_T "Density of saturated vapour"
                input SI.Temperature T "Temperature";
                output SI.Density d "Density of steam at the condensation point";
              protected
                SI.Pressure p "Saturation pressure";
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

              function region_ph "Return the current region (valid values: 1,2,3,4,5) in IF97 for given pressure and specific enthalpy"
                input SI.Pressure p "Pressure";
                input SI.SpecificEnthalpy h "Specific enthalpy";
                input Integer phase = 0 "Phase: 2 for two-phase, 1 for one phase, 0 if not known";
                input Integer mode = 0 "Mode: 0 means check, otherwise assume region=mode";
                output Integer region "Region (valid values: 1,2,3,4,5) in IF97";
              protected
                Boolean hsubcrit;
                SI.Temperature Ttest;
                constant Real n[5] = data.n;
                SI.SpecificEnthalpy hl "Bubble enthalpy";
                SI.SpecificEnthalpy hv "Dew enthalpy";
              algorithm
                if (mode <> 0) then
                  region := mode;
                else
                  hl := hl_p(p);
                  hv := hv_p(p);
                  if (phase == 2) then
                    region := 4;
                  else
                    if (p < triple.ptriple) or (p > data.PLIMIT1) or (h < hlowerofp1(p)) or ((p < 10.0e6) and (h > hupperofp5(p))) or ((p >= 10.0e6) and (h > hupperofp2(p))) then
                      region := -1;
                    else
                      hsubcrit := (h < data.HCRIT);
                      if (p < data.PLIMIT4A) then
                        if hsubcrit then
                          if (phase == 1) then
                            region := 1;
                          else
                            if (h < Isentropic.hofpT1(p, Basic.tsat(p))) then
                              region := 1;
                            else
                              region := 4;
                            end if;
                          end if;
                        else
                          if (h > hlowerofp5(p)) then
                            if ((p < data.PLIMIT5) and (h < hupperofp5(p))) then
                              region := 5;
                            else
                              region := -2;
                            end if;
                          else
                            if (phase == 1) then
                              region := 2;
                            else
                              if (h > Isentropic.hofpT2(p, Basic.tsat(p))) then
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
                          if (h > hlowerofp2(p)) then
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

              function region_pT "Return the current region (valid values: 1,2,3,5) in IF97, given pressure and temperature"
                input SI.Pressure p "Pressure";
                input SI.Temperature T "Temperature (K)";
                input Integer mode = 0 "Mode: 0 means check, otherwise assume region=mode";
                output Integer region "Region (valid values: 1,2,3,5) in IF97, region 4 is impossible!";
              algorithm
                if (mode <> 0) then
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

              function region_dT "Return the current region (valid values: 1,2,3,4,5) in IF97, given density and temperature"
                input SI.Density d "Density";
                input SI.Temperature T "Temperature (K)";
                input Integer phase = 0 "Phase: 2 for two-phase, 1 for one phase, 0 if not known";
                input Integer mode = 0 "Mode: 0 means check, otherwise assume region=mode";
                output Integer region "(valid values: 1,2,3,4,5) in IF97";
              protected
                Boolean Tovercrit "Flag if overcritical temperature";
                SI.Pressure p23 "Pressure needed to know if region 2 or 3";
              algorithm
                Tovercrit := T > data.TCRIT;
                if (mode <> 0) then
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
                  elseif (d > rhol_T(T)) then
                    if T < data.TLIMIT1 then
                      region := 1;
                    else
                      region := 3;
                    end if;
                  elseif (d < rhov_T(T)) then
                    if (d > d2n(p23, T) and T > data.TLIMIT1) then
                      region := 3;
                    else
                      region := 2;
                    end if;
                  else
                    region := 4;
                  end if;
                end if;
              end region_dT;
            end Regions;

            package Basic "Base functions as described in IAWPS/IF97"
              function g1 "Gibbs function for region 1: g(p,T)"
                input SI.Pressure p "Pressure";
                input SI.Temperature T "Temperature (K)";
                output ThermofluidStream.Media.myMedia.Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
              protected
                Real pi1 "Dimensionless pressure";
                Real tau1 "Dimensionless temperature";
                Real o[45] "Vector of auxiliary variables";
                Real pl "Auxiliary variable";
              algorithm
                pl := min(p, data.PCRIT - 1);
                assert(p > triple.ptriple, "IF97 medium function g1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
                assert(p <= 100.0e6, "IF97 medium function g1: the input pressure (= " + String(p) + " Pa) is higher than 100 MPa");
                assert(T >= 273.15, "IF97 medium function g1: the temperature (= " + String(T) + " K) is lower than 273.15 K!");
                g.p := p;
                g.T := T;
                g.R_s := data.RH2O;
                g.pi := p/data.PSTAR1;
                g.tau := data.TSTAR1/T;
                pi1 := 7.1000000000000 - g.pi;
                tau1 := -1.22200000000000 + g.tau;
                o[1] := tau1*tau1;
                o[2] := o[1]*o[1];
                o[3] := o[2]*o[2];
                o[4] := o[3]*tau1;
                o[5] := 1/o[4];
                o[6] := o[1]*o[2];
                o[7] := o[1]*tau1;
                o[8] := 1/o[7];
                o[9] := o[1]*o[2]*o[3];
                o[10] := 1/o[2];
                o[11] := o[2]*tau1;
                o[12] := 1/o[11];
                o[13] := o[2]*o[3];
                o[14] := 1/o[3];
                o[15] := pi1*pi1;
                o[16] := o[15]*pi1;
                o[17] := o[15]*o[15];
                o[18] := o[17]*o[17];
                o[19] := o[17]*o[18]*pi1;
                o[20] := o[15]*o[17];
                o[21] := o[3]*o[3];
                o[22] := o[21]*o[21];
                o[23] := o[22]*o[3]*tau1;
                o[24] := 1/o[23];
                o[25] := o[22]*o[3];
                o[26] := 1/o[25];
                o[27] := o[1]*o[2]*o[22]*tau1;
                o[28] := 1/o[27];
                o[29] := o[1]*o[2]*o[22];
                o[30] := 1/o[29];
                o[31] := o[1]*o[2]*o[21]*o[3]*tau1;
                o[32] := 1/o[31];
                o[33] := o[2]*o[21]*o[3]*tau1;
                o[34] := 1/o[33];
                o[35] := o[1]*o[3]*tau1;
                o[36] := 1/o[35];
                o[37] := o[1]*o[3];
                o[38] := 1/o[37];
                o[39] := 1/o[6];
                o[40] := o[1]*o[22]*o[3];
                o[41] := 1/o[40];
                o[42] := 1/o[22];
                o[43] := o[1]*o[2]*o[21]*o[3];
                o[44] := 1/o[43];
                o[45] := 1/o[13];
                g.g := pi1*(pi1*(pi1*(o[10]*(-0.000031679644845054 + o[2]*(-2.82707979853120e-6 - 8.5205128120103e-10*o[6])) + pi1*(o[12]*(-2.24252819080000e-6 + (-6.5171222895601e-7 - 1.43417299379240e-13*o[13])*o[7]) + pi1*(-4.0516996860117e-7*o[14] + o[16]*((-1.27343017416410e-9 - 1.74248712306340e-10*o[11])*o[36] + o[19]*(-6.8762131295531e-19*o[34] + o[15]*(1.44783078285210e-20*o[32] + o[20]*(2.63357816627950e-23*o[30] + pi1*(-1.19476226400710e-23*o[28] + pi1*(1.82280945814040e-24*o[26] - 9.3537087292458e-26*o[24]*pi1))))))))) + o[8]*(-0.00047184321073267 + o[7]*(-0.000300017807930260 + (0.000047661393906987 + o[1]*(-4.4141845330846e-6 - 7.2694996297594e-16*o[9]))*tau1))) + o[5]*(0.000283190801238040 + o[1]*(-0.00060706301565874 + o[6]*(-0.0189900682184190 + tau1*(-0.032529748770505 + (-0.0218417171754140 - 0.000052838357969930*o[1])*tau1))))) + (0.146329712131670 + tau1*(-0.84548187169114 + tau1*(-3.7563603672040 + tau1*(3.3855169168385 + tau1*(-0.95791963387872 + tau1*(0.157720385132280 + (-0.0166164171995010 + 0.00081214629983568*tau1)*tau1))))))/o[1];
                g.gpi := pi1*(pi1*(o[10]*(0.000095038934535162 + o[2]*(8.4812393955936e-6 + 2.55615384360309e-9*o[6])) + pi1*(o[12]*(8.9701127632000e-6 + (2.60684891582404e-6 + 5.7366919751696e-13*o[13])*o[7]) + pi1*(2.02584984300585e-6*o[14] + o[16]*((1.01874413933128e-8 + 1.39398969845072e-9*o[11])*o[36] + o[19]*(1.44400475720615e-17*o[34] + o[15]*(-3.3300108005598e-19*o[32] + o[20]*(-7.6373766822106e-22*o[30] + pi1*(3.5842867920213e-22*o[28] + pi1*(-5.6507093202352e-23*o[26] + 2.99318679335866e-24*o[24]*pi1))))))))) + o[8]*(0.00094368642146534 + o[7]*(0.00060003561586052 + (-0.000095322787813974 + o[1]*(8.8283690661692e-6 + 1.45389992595188e-15*o[9]))*tau1))) + o[5]*(-0.000283190801238040 + o[1]*(0.00060706301565874 + o[6]*(0.0189900682184190 + tau1*(0.032529748770505 + (0.0218417171754140 + 0.000052838357969930*o[1])*tau1))));
                g.gpipi := pi1*(o[10]*(-0.000190077869070324 + o[2]*(-0.0000169624787911872 - 5.1123076872062e-9*o[6])) + pi1*(o[12]*(-0.0000269103382896000 + (-7.8205467474721e-6 - 1.72100759255088e-12*o[13])*o[7]) + pi1*(-8.1033993720234e-6*o[14] + o[16]*((-7.1312089753190e-8 - 9.7579278891550e-9*o[11])*o[36] + o[19]*(-2.88800951441230e-16*o[34] + o[15]*(7.3260237612316e-18*o[32] + o[20]*(2.13846547101895e-20*o[30] + pi1*(-1.03944316968618e-20*o[28] + pi1*(1.69521279607057e-21*o[26] - 9.2788790594118e-23*o[24]*pi1))))))))) + o[8]*(-0.00094368642146534 + o[7]*(-0.00060003561586052 + (0.000095322787813974 + o[1]*(-8.8283690661692e-6 - 1.45389992595188e-15*o[9]))*tau1));
                g.gtau := pi1*(o[38]*(-0.00254871721114236 + o[1]*(0.0042494411096112 + (0.0189900682184190 + (-0.0218417171754140 - 0.000158515073909790*o[1])*o[1])*o[6])) + pi1*(o[10]*(0.00141552963219801 + o[2]*(0.000047661393906987 + o[1]*(-0.0000132425535992538 - 1.23581493705910e-14*o[9]))) + pi1*(o[12]*(0.000126718579380216 - 5.1123076872062e-9*o[37]) + pi1*(o[39]*(0.0000112126409540000 + (1.30342445791202e-6 - 1.43417299379240e-12*o[13])*o[7]) + pi1*(3.2413597488094e-6*o[5] + o[16]*((1.40077319158051e-8 + 1.04549227383804e-9*o[11])*o[45] + o[19]*(1.99410180757040e-17*o[44] + o[15]*(-4.4882754268415e-19*o[42] + o[20]*(-1.00075970318621e-21*o[28] + pi1*(4.6595728296277e-22*o[26] + pi1*(-7.2912378325616e-23*o[24] + 3.8350205789908e-24*o[41]*pi1))))))))))) + o[8]*(-0.292659424263340 + tau1*(0.84548187169114 + o[1]*(3.3855169168385 + tau1*(-1.91583926775744 + tau1*(0.47316115539684 + (-0.066465668798004 + 0.0040607314991784*tau1)*tau1)))));
                g.gtautau := pi1*(o[36]*(0.0254871721114236 + o[1]*(-0.033995528876889 + (-0.037980136436838 - 0.00031703014781958*o[2])*o[6])) + pi1*(o[12]*(-0.0056621185287920 + o[6]*(-0.0000264851071985076 - 1.97730389929456e-13*o[9])) + pi1*((-0.00063359289690108 - 2.55615384360309e-8*o[37])*o[39] + pi1*(pi1*(-0.0000291722377392842*o[38] + o[16]*(o[19]*(-5.9823054227112e-16*o[32] + o[15]*(o[20]*(3.9029628424262e-20*o[26] + pi1*(-1.86382913185108e-20*o[24] + pi1*(2.98940751135026e-21*o[41] - (1.61070864317613e-22*pi1)/(o[1]*o[22]*o[3]*tau1)))) + 1.43624813658928e-17/(o[22]*tau1))) + (-1.68092782989661e-7 - 7.3184459168663e-9*o[11])/(o[2]*o[3]*tau1))) + (-0.000067275845724000 + (-3.9102733737361e-6 - 1.29075569441316e-11*o[13])*o[7])/(o[1]*o[2]*tau1))))) + o[10]*(0.87797827279002 + tau1*(-1.69096374338228 + o[7]*(-1.91583926775744 + tau1*(0.94632231079368 + (-0.199397006394012 + 0.0162429259967136*tau1)*tau1))));
                g.gtaupi := o[38]*(0.00254871721114236 + o[1]*(-0.0042494411096112 + (-0.0189900682184190 + (0.0218417171754140 + 0.000158515073909790*o[1])*o[1])*o[6])) + pi1*(o[10]*(-0.00283105926439602 + o[2]*(-0.000095322787813974 + o[1]*(0.0000264851071985076 + 2.47162987411820e-14*o[9]))) + pi1*(o[12]*(-0.00038015573814065 + 1.53369230616185e-8*o[37]) + pi1*(o[39]*(-0.000044850563816000 + (-5.2136978316481e-6 + 5.7366919751696e-12*o[13])*o[7]) + pi1*(-0.0000162067987440468*o[5] + o[16]*((-1.12061855326441e-7 - 8.3639381907043e-9*o[11])*o[45] + o[19]*(-4.1876137958978e-16*o[44] + o[15]*(1.03230334817355e-17*o[42] + o[20]*(2.90220313924001e-20*o[28] + pi1*(-1.39787184888831e-20*o[26] + pi1*(2.26028372809410e-21*o[24] - 1.22720658527705e-22*o[41]*pi1))))))))));
              end g1;

              function g2 "Gibbs function for region 2: g(p,T)"
                input SI.Pressure p "Pressure";
                input SI.Temperature T "Temperature (K)";
                input Boolean checkLimits = true "Check if inputs p,T are in region of validity";
                output ThermofluidStream.Media.myMedia.Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
              protected
                Real tau2 "Dimensionless temperature";
                Real o[55] "Vector of auxiliary variables";
              algorithm
                g.p := p;
                g.T := T;
                g.R_s := data.RH2O;
                if checkLimits then
                  assert(p > 0.0, "IF97 medium function g2 called with too low pressure\n" + "p = " + String(p) + " Pa <= 0.0 Pa");
                  assert(p <= 100.0e6, "IF97 medium function g2: the input pressure (= " + String(p) + " Pa) is higher than 100 MPa");
                  assert(T >= 273.15, "IF97 medium function g2: the temperature (= " + String(T) + " K) is lower than 273.15 K!");
                  assert(T <= 1073.15, "IF97 medium function g2: the input temperature (= " + String(T) + " K) is higher than the limit of 1073.15 K");
                else
                end if;
                g.pi := p/data.PSTAR2;
                g.tau := data.TSTAR2/T;
                tau2 := -0.5 + g.tau;
                o[1] := tau2*tau2;
                o[2] := o[1]*tau2;
                o[3] := -0.050325278727930*o[2];
                o[4] := -0.057581259083432 + o[3];
                o[5] := o[4]*tau2;
                o[6] := -0.045996013696365 + o[5];
                o[7] := o[6]*tau2;
                o[8] := -0.0178348622923580 + o[7];
                o[9] := o[8]*tau2;
                o[10] := o[1]*o[1];
                o[11] := o[10]*o[10];
                o[12] := o[11]*o[11];
                o[13] := o[10]*o[11]*o[12]*tau2;
                o[14] := o[1]*o[10]*tau2;
                o[15] := o[10]*o[11]*tau2;
                o[16] := o[1]*o[12]*tau2;
                o[17] := o[1]*o[11]*tau2;
                o[18] := o[1]*o[10]*o[11];
                o[19] := o[10]*o[11]*o[12];
                o[20] := o[1]*o[10];
                o[21] := g.pi*g.pi;
                o[22] := o[21]*o[21];
                o[23] := o[21]*o[22];
                o[24] := o[10]*o[12]*tau2;
                o[25] := o[12]*o[12];
                o[26] := o[11]*o[12]*o[25]*tau2;
                o[27] := o[10]*o[12];
                o[28] := o[1]*o[10]*o[11]*tau2;
                o[29] := o[10]*o[12]*o[25]*tau2;
                o[30] := o[1]*o[10]*o[25]*tau2;
                o[31] := o[1]*o[11]*o[12];
                o[32] := o[1]*o[12];
                o[33] := g.tau*g.tau;
                o[34] := o[33]*o[33];
                o[35] := -0.000053349095828174*o[13];
                o[36] := -0.087594591301146 + o[35];
                o[37] := o[2]*o[36];
                o[38] := -0.0078785554486710 + o[37];
                o[39] := o[1]*o[38];
                o[40] := -0.00037897975032630 + o[39];
                o[41] := o[40]*tau2;
                o[42] := -0.000066065283340406 + o[41];
                o[43] := o[42]*tau2;
                o[44] := 5.7870447262208e-6*tau2;
                o[45] := -0.301951672367580*o[2];
                o[46] := -0.172743777250296 + o[45];
                o[47] := o[46]*tau2;
                o[48] := -0.091992027392730 + o[47];
                o[49] := o[48]*tau2;
                o[50] := o[1]*o[11];
                o[51] := o[10]*o[11];
                o[52] := o[11]*o[12]*o[25];
                o[53] := o[10]*o[12]*o[25];
                o[54] := o[1]*o[10]*o[25];
                o[55] := o[11]*o[12]*tau2;
                g.g := g.pi*(-0.00177317424732130 + o[9] + g.pi*(tau2*(-0.000033032641670203 + (-0.000189489875163150 + o[1]*(-0.0039392777243355 + (-0.043797295650573 - 0.0000266745479140870*o[13])*o[2]))*tau2) + g.pi*(2.04817376923090e-8 + (4.3870667284435e-7 + o[1]*(-0.000032277677238570 + (-0.00150339245421480 - 0.040668253562649*o[13])*o[2]))*tau2 + g.pi*(g.pi*(2.29220763376610e-6*o[14] + g.pi*((-1.67147664510610e-11 + o[15]*(-0.00211714723213550 - 23.8957419341040*o[16]))*o[2] + g.pi*(-5.9059564324270e-18 + o[17]*(-1.26218088991010e-6 - 0.038946842435739*o[18]) + g.pi*(o[11]*(1.12562113604590e-11 - 8.2311340897998*o[19]) + g.pi*(1.98097128020880e-8*o[15] + g.pi*(o[10]*(1.04069652101740e-19 + (-1.02347470959290e-13 - 1.00181793795110e-9*o[10])*o[20]) + o[23]*(o[13]*(-8.0882908646985e-11 + 0.106930318794090*o[24]) + o[21]*(-0.33662250574171*o[26] + o[21]*(o[27]*(8.9185845355421e-25 + (3.06293168762320e-13 - 4.2002467698208e-6*o[15])*o[28]) + g.pi*(-5.9056029685639e-26*o[24] + g.pi*(3.7826947613457e-6*o[29] + g.pi*(-1.27686089346810e-15*o[30] + o[31]*(7.3087610595061e-29 + o[18]*(5.5414715350778e-17 - 9.4369707241210e-7*o[32]))*g.pi)))))))))))) + tau2*(-7.8847309559367e-10 + (1.27907178522850e-8 + 4.8225372718507e-7*tau2)*tau2))))) + (-0.0056087911830200 + g.tau*(0.071452738814550 + g.tau*(-0.40710498239280 + g.tau*(1.42408197144400 + g.tau*(-4.3839511194500 + g.tau*(-9.6927686002170 + g.tau*(10.0866556801800 + (-0.284086326077200 + 0.0212684635330700*g.tau)*g.tau) + Modelica.Math.log(g.pi)))))))/(o[34]*g.tau);
                g.gpi := (1.00000000000000 + g.pi*(-0.00177317424732130 + o[9] + g.pi*(o[43] + g.pi*(6.1445213076927e-8 + (1.31612001853305e-6 + o[1]*(-0.000096833031715710 + (-0.0045101773626444 - 0.122004760687947*o[13])*o[2]))*tau2 + g.pi*(g.pi*(0.0000114610381688305*o[14] + g.pi*((-1.00288598706366e-10 + o[15]*(-0.0127028833928130 - 143.374451604624*o[16]))*o[2] + g.pi*(-4.1341695026989e-17 + o[17]*(-8.8352662293707e-6 - 0.272627897050173*o[18]) + g.pi*(o[11]*(9.0049690883672e-11 - 65.849072718398*o[19]) + g.pi*(1.78287415218792e-7*o[15] + g.pi*(o[10]*(1.04069652101740e-18 + (-1.02347470959290e-12 - 1.00181793795110e-8*o[10])*o[20]) + o[23]*(o[13]*(-1.29412653835176e-9 + 1.71088510070544*o[24]) + o[21]*(-6.0592051033508*o[26] + o[21]*(o[27]*(1.78371690710842e-23 + (6.1258633752464e-12 - 0.000084004935396416*o[15])*o[28]) + g.pi*(-1.24017662339842e-24*o[24] + g.pi*(0.000083219284749605*o[29] + g.pi*(-2.93678005497663e-14*o[30] + o[31]*(1.75410265428146e-27 + o[18]*(1.32995316841867e-15 - 0.0000226487297378904*o[32]))*g.pi)))))))))))) + tau2*(-3.15389238237468e-9 + (5.1162871409140e-8 + 1.92901490874028e-6*tau2)*tau2))))))/g.pi;
                g.gpipi := (-1.00000000000000 + o[21]*(o[43] + g.pi*(1.22890426153854e-7 + (2.63224003706610e-6 + o[1]*(-0.000193666063431420 + (-0.0090203547252888 - 0.244009521375894*o[13])*o[2]))*tau2 + g.pi*(g.pi*(0.000045844152675322*o[14] + g.pi*((-5.0144299353183e-10 + o[15]*(-0.063514416964065 - 716.87225802312*o[16]))*o[2] + g.pi*(-2.48050170161934e-16 + o[17]*(-0.000053011597376224 - 1.63576738230104*o[18]) + g.pi*(o[11]*(6.3034783618570e-10 - 460.94350902879*o[19]) + g.pi*(1.42629932175034e-6*o[15] + g.pi*(o[10]*(9.3662686891566e-18 + (-9.2112723863361e-12 - 9.0163614415599e-8*o[10])*o[20]) + o[23]*(o[13]*(-1.94118980752764e-8 + 25.6632765105816*o[24]) + o[21]*(-103.006486756963*o[26] + o[21]*(o[27]*(3.3890621235060e-22 + (1.16391404129682e-10 - 0.00159609377253190*o[15])*o[28]) + g.pi*(-2.48035324679684e-23*o[24] + g.pi*(0.00174760497974171*o[29] + g.pi*(-6.4609161209486e-13*o[30] + o[31]*(4.0344361048474e-26 + o[18]*(3.05889228736295e-14 - 0.00052092078397148*o[32]))*g.pi)))))))))))) + tau2*(-9.4616771471240e-9 + (1.53488614227420e-7 + o[44])*tau2)))))/o[21];
                g.gtau := (0.0280439559151000 + g.tau*(-0.285810955258200 + g.tau*(1.22131494717840 + g.tau*(-2.84816394288800 + g.tau*(4.3839511194500 + o[33]*(10.0866556801800 + (-0.56817265215440 + 0.063805390599210*g.tau)*g.tau))))))/(o[33]*o[34]) + g.pi*(-0.0178348622923580 + o[49] + g.pi*(-0.000033032641670203 + (-0.00037897975032630 + o[1]*(-0.0157571108973420 + (-0.306581069554011 - 0.00096028372490713*o[13])*o[2]))*tau2 + g.pi*(4.3870667284435e-7 + o[1]*(-0.000096833031715710 + (-0.0090203547252888 - 1.42338887469272*o[13])*o[2]) + g.pi*(-7.8847309559367e-10 + g.pi*(0.0000160454534363627*o[20] + g.pi*(o[1]*(-5.0144299353183e-11 + o[15]*(-0.033874355714168 - 836.35096769364*o[16])) + g.pi*((-0.0000138839897890111 - 0.97367106089347*o[18])*o[50] + g.pi*(o[14]*(9.0049690883672e-11 - 296.320827232793*o[19]) + g.pi*(2.57526266427144e-7*o[51] + g.pi*(o[2]*(4.1627860840696e-19 + (-1.02347470959290e-12 - 1.40254511313154e-8*o[10])*o[20]) + o[23]*(o[19]*(-2.34560435076256e-9 + 5.3465159397045*o[24]) + o[21]*(-19.1874828272775*o[52] + o[21]*(o[16]*(1.78371690710842e-23 + (1.07202609066812e-11 - 0.000201611844951398*o[15])*o[28]) + g.pi*(-1.24017662339842e-24*o[27] + g.pi*(0.000200482822351322*o[53] + g.pi*(-4.9797574845256e-14*o[54] + (1.90027787547159e-27 + o[18]*(2.21658861403112e-15 - 0.000054734430199902*o[32]))*o[55]*g.pi)))))))))))) + (2.55814357045700e-8 + 1.44676118155521e-6*tau2)*tau2))));
                g.gtautau := (-0.168263735490600 + g.tau*(1.42905477629100 + g.tau*(-4.8852597887136 + g.tau*(8.5444918286640 + g.tau*(-8.7679022389000 + o[33]*(-0.56817265215440 + 0.127610781198420*g.tau)*g.tau)))))/(o[33]*o[34]*g.tau) + g.pi*(-0.091992027392730 + (-0.34548755450059 - 1.50975836183790*o[2])*tau2 + g.pi*(-0.00037897975032630 + o[1]*(-0.047271332692026 + (-1.83948641732407 - 0.033609930371750*o[13])*o[2]) + g.pi*((-0.000193666063431420 + (-0.045101773626444 - 48.395221739552*o[13])*o[2])*tau2 + g.pi*(2.55814357045700e-8 + 2.89352236311042e-6*tau2 + g.pi*(0.000096272720618176*o[10]*tau2 + g.pi*((-1.00288598706366e-10 + o[15]*(-0.50811533571252 - 28435.9329015838*o[16]))*tau2 + g.pi*(o[11]*(-0.000138839897890111 - 23.3681054614434*o[18])*tau2 + g.pi*((6.3034783618570e-10 - 10371.2289531477*o[19])*o[20] + g.pi*(3.09031519712573e-6*o[17] + g.pi*(o[1]*(1.24883582522088e-18 + (-9.2112723863361e-12 - 1.82330864707100e-7*o[10])*o[20]) + o[23]*(o[1]*o[11]*o[12]*(-6.5676921821352e-8 + 261.979281045521*o[24])*tau2 + o[21]*(-1074.49903832754*o[1]*o[10]*o[12]*o[25]*tau2 + o[21]*((3.3890621235060e-22 + (3.6448887082716e-10 - 0.0094757567127157*o[15])*o[28])*o[32] + g.pi*(-2.48035324679684e-23*o[16] + g.pi*(0.0104251067622687*o[1]*o[12]*o[25]*tau2 + g.pi*(o[11]*o[12]*(4.7506946886790e-26 + o[18]*(8.6446955947214e-14 - 0.00311986252139440*o[32]))*g.pi - 1.89230784411972e-12*o[10]*o[25]*tau2))))))))))))))));
                g.gtaupi := -0.0178348622923580 + o[49] + g.pi*(-0.000066065283340406 + (-0.00075795950065260 + o[1]*(-0.0315142217946840 + (-0.61316213910802 - 0.00192056744981426*o[13])*o[2]))*tau2 + g.pi*(1.31612001853305e-6 + o[1]*(-0.000290499095147130 + (-0.0270610641758664 - 4.2701666240781*o[13])*o[2]) + g.pi*(-3.15389238237468e-9 + g.pi*(0.000080227267181813*o[20] + g.pi*(o[1]*(-3.00865796119098e-10 + o[15]*(-0.203246134285008 - 5018.1058061618*o[16])) + g.pi*((-0.000097187928523078 - 6.8156974262543*o[18])*o[50] + g.pi*(o[14]*(7.2039752706938e-10 - 2370.56661786234*o[19]) + g.pi*(2.31773639784430e-6*o[51] + g.pi*(o[2]*(4.1627860840696e-18 + (-1.02347470959290e-11 - 1.40254511313154e-7*o[10])*o[20]) + o[23]*(o[19]*(-3.7529669612201e-8 + 85.544255035272*o[24]) + o[21]*(-345.37469089099*o[52] + o[21]*(o[16]*(3.5674338142168e-22 + (2.14405218133624e-10 - 0.0040322368990280*o[15])*o[28]) + g.pi*(-2.60437090913668e-23*o[27] + g.pi*(0.0044106220917291*o[53] + g.pi*(-1.14534422144089e-12*o[54] + (4.5606669011318e-26 + o[18]*(5.3198126736747e-14 - 0.00131362632479764*o[32]))*o[55]*g.pi)))))))))))) + (1.02325742818280e-7 + o[44])*tau2)));
              end g2;

              function f3 "Helmholtz function for region 3: f(d,T)"
                input SI.Density d "Density";
                input SI.Temperature T "Temperature (K)";
                output ThermofluidStream.Media.myMedia.Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
              protected
                Real o[40] "Vector of auxiliary variables";
              algorithm
                f.T := T;
                f.d := d;
                f.R_s := data.RH2O;
                f.tau := data.TCRIT/T;
                f.delta := if (d == data.DCRIT and T == data.TCRIT) then 1 - Modelica.Constants.eps else abs(d/data.DCRIT);
                o[1] := f.tau*f.tau;
                o[2] := o[1]*o[1];
                o[3] := o[2]*f.tau;
                o[4] := o[1]*f.tau;
                o[5] := o[2]*o[2];
                o[6] := o[1]*o[5]*f.tau;
                o[7] := o[5]*f.tau;
                o[8] := -0.64207765181607*o[1];
                o[9] := 0.88521043984318 + o[8];
                o[10] := o[7]*o[9];
                o[11] := -1.15244078066810 + o[10];
                o[12] := o[11]*o[2];
                o[13] := -1.26543154777140 + o[12];
                o[14] := o[1]*o[13];
                o[15] := o[1]*o[2]*o[5]*f.tau;
                o[16] := o[2]*o[5];
                o[17] := o[1]*o[5];
                o[18] := o[5]*o[5];
                o[19] := o[1]*o[18]*o[2];
                o[20] := o[1]*o[18]*o[2]*f.tau;
                o[21] := o[18]*o[5];
                o[22] := o[1]*o[18]*o[5];
                o[23] := 0.251168168486160*o[2];
                o[24] := 0.078841073758308 + o[23];
                o[25] := o[15]*o[24];
                o[26] := -6.1005234513930 + o[25];
                o[27] := o[26]*f.tau;
                o[28] := 9.7944563083754 + o[27];
                o[29] := o[2]*o[28];
                o[30] := -1.70429417648412 + o[29];
                o[31] := o[1]*o[30];
                o[32] := f.delta*f.delta;
                o[33] := -10.9153200808732*o[1];
                o[34] := 13.2781565976477 + o[33];
                o[35] := o[34]*o[7];
                o[36] := -6.9146446840086 + o[35];
                o[37] := o[2]*o[36];
                o[38] := -2.53086309554280 + o[37];
                o[39] := o[38]*f.tau;
                o[40] := o[18]*o[5]*f.tau;
                f.f := -15.7328452902390 + f.tau*(20.9443969743070 + (-7.6867707878716 + o[3]*(2.61859477879540 + o[4]*(-2.80807811486200 + o[1]*(1.20533696965170 - 0.0084566812812502*o[6]))))*f.tau) + f.delta*(o[14] + f.delta*(0.38493460186671 + o[1]*(-0.85214708824206 + o[2]*(4.8972281541877 + (-3.05026172569650 + o[15]*(0.039420536879154 + 0.125584084243080*o[2]))*f.tau)) + f.delta*(-0.279993296987100 + o[1]*(1.38997995694600 + o[1]*(-2.01899150235700 + o[16]*(-0.0082147637173963 - 0.47596035734923*o[17]))) + f.delta*(0.043984074473500 + o[1]*(-0.44476435428739 + o[1]*(0.90572070719733 + 0.70522450087967*o[19])) + f.delta*(f.delta*(-0.0221754008730960 + o[1]*(0.094260751665092 + 0.164362784479610*o[21]) + f.delta*(-0.0135033722413480*o[1] + f.delta*(-0.0148343453524720*o[22] + f.delta*(o[1]*(0.00057922953628084 + 0.0032308904703711*o[21]) + f.delta*(0.000080964802996215 - 0.000044923899061815*f.delta*o[22] - 0.000165576797950370*f.tau))))) + (0.107705126263320 + o[1]*(-0.32913623258954 - 0.50871062041158*o[20]))*f.tau))))) + 1.06580700285130*Modelica.Math.log(f.delta);
                f.fdelta := (1.06580700285130 + f.delta*(o[14] + f.delta*(0.76986920373342 + o[31] + f.delta*(-0.83997989096130 + o[1]*(4.1699398708380 + o[1]*(-6.0569745070710 + o[16]*(-0.0246442911521889 - 1.42788107204769*o[17]))) + f.delta*(0.175936297894000 + o[1]*(-1.77905741714956 + o[1]*(3.6228828287893 + 2.82089800351868*o[19])) + f.delta*(f.delta*(-0.133052405238576 + o[1]*(0.56556450999055 + 0.98617670687766*o[21]) + f.delta*(-0.094523605689436*o[1] + f.delta*(-0.118674762819776*o[22] + f.delta*(o[1]*(0.0052130658265276 + 0.0290780142333399*o[21]) + f.delta*(0.00080964802996215 - 0.00049416288967996*f.delta*o[22] - 0.00165576797950370*f.tau))))) + (0.53852563131660 + o[1]*(-1.64568116294770 - 2.54355310205790*o[20]))*f.tau))))))/f.delta;
                f.fdeltadelta := (-1.06580700285130 + o[32]*(0.76986920373342 + o[31] + f.delta*(-1.67995978192260 + o[1]*(8.3398797416760 + o[1]*(-12.1139490141420 + o[16]*(-0.049288582304378 - 2.85576214409538*o[17]))) + f.delta*(0.52780889368200 + o[1]*(-5.3371722514487 + o[1]*(10.8686484863680 + 8.4626940105560*o[19])) + f.delta*(f.delta*(-0.66526202619288 + o[1]*(2.82782254995276 + 4.9308835343883*o[21]) + f.delta*(-0.56714163413662*o[1] + f.delta*(-0.83072333973843*o[22] + f.delta*(o[1]*(0.041704526612220 + 0.232624113866719*o[21]) + f.delta*(0.0072868322696594 - 0.0049416288967996*f.delta*o[22] - 0.0149019118155333*f.tau))))) + (2.15410252526640 + o[1]*(-6.5827246517908 - 10.1742124082316*o[20]))*f.tau)))))/o[32];
                f.ftau := 20.9443969743070 + (-15.3735415757432 + o[3]*(18.3301634515678 + o[4]*(-28.0807811486200 + o[1]*(14.4640436358204 - 0.194503669468755*o[6]))))*f.tau + f.delta*(o[39] + f.delta*(f.tau*(-1.70429417648412 + o[2]*(29.3833689251262 + (-21.3518320798755 + o[15]*(0.86725181134139 + 3.2651861903201*o[2]))*f.tau)) + f.delta*((2.77995991389200 + o[1]*(-8.0759660094280 + o[16]*(-0.131436219478341 - 12.3749692910800*o[17])))*f.tau + f.delta*((-0.88952870857478 + o[1]*(3.6228828287893 + 18.3358370228714*o[19]))*f.tau + f.delta*(0.107705126263320 + o[1]*(-0.98740869776862 - 13.2264761307011*o[20]) + f.delta*((0.188521503330184 + 4.2734323964699*o[21])*f.tau + f.delta*(-0.0270067444826960*f.tau + f.delta*(-0.38569297916427*o[40] + f.delta*(f.delta*(-0.000165576797950370 - 0.00116802137560719*f.delta*o[40]) + (0.00115845907256168 + 0.084003152229649*o[21])*f.tau)))))))));
                f.ftautau := -15.3735415757432 + o[3]*(109.980980709407 + o[4]*(-252.727030337580 + o[1]*(159.104479994024 - 4.2790807283126*o[6]))) + f.delta*(-2.53086309554280 + o[2]*(-34.573223420043 + (185.894192367068 - 174.645121293971*o[1])*o[7]) + f.delta*(-1.70429417648412 + o[2]*(146.916844625631 + (-128.110992479253 + o[15]*(18.2122880381691 + 81.629654758002*o[2]))*f.tau) + f.delta*(2.77995991389200 + o[1]*(-24.2278980282840 + o[16]*(-1.97154329217511 - 309.374232277000*o[17])) + f.delta*(-0.88952870857478 + o[1]*(10.8686484863680 + 458.39592557179*o[19]) + f.delta*(f.delta*(0.188521503330184 + 106.835809911747*o[21] + f.delta*(-0.0270067444826960 + f.delta*(-9.6423244791068*o[21] + f.delta*(0.00115845907256168 + 2.10007880574121*o[21] - 0.0292005343901797*o[21]*o[32])))) + (-1.97481739553724 - 330.66190326753*o[20])*f.tau)))));
                f.fdeltatau := o[39] + f.delta*(f.tau*(-3.4085883529682 + o[2]*(58.766737850252 + (-42.703664159751 + o[15]*(1.73450362268278 + 6.5303723806402*o[2]))*f.tau)) + f.delta*((8.3398797416760 + o[1]*(-24.2278980282840 + o[16]*(-0.39430865843502 - 37.124907873240*o[17])))*f.tau + f.delta*((-3.5581148342991 + o[1]*(14.4915313151573 + 73.343348091486*o[19]))*f.tau + f.delta*(0.53852563131660 + o[1]*(-4.9370434888431 - 66.132380653505*o[20]) + f.delta*((1.13112901998110 + 25.6405943788192*o[21])*f.tau + f.delta*(-0.189047211378872*f.tau + f.delta*(-3.08554383331418*o[40] + f.delta*(f.delta*(-0.00165576797950370 - 0.0128482351316791*f.delta*o[40]) + (0.0104261316530551 + 0.75602837006684*o[21])*f.tau))))))));
              end f3;

              function g5 "Base function for region 5: g(p,T)"
                input SI.Pressure p "Pressure";
                input SI.Temperature T "Temperature (K)";
                output ThermofluidStream.Media.myMedia.Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
              protected
                Real o[11] "Vector of auxiliary variables";
              algorithm
                assert(p > 0.0, "IF97 medium function g5 called with too low pressure\n" + "p = " + String(p) + " Pa <=  0.0 Pa");
                assert(p <= data.PLIMIT5, "IF97 medium function g5: input pressure (= " + String(p) + " Pa) is higher than 10 MPa in region 5");
                assert(T <= 2273.15, "IF97 medium function g5: input temperature (= " + String(T) + " K) is higher than limit of 2273.15K in region 5");
                g.p := p;
                g.T := T;
                g.R_s := data.RH2O;
                g.pi := p/data.PSTAR5;
                g.tau := data.TSTAR5/T;
                o[1] := g.tau*g.tau;
                o[2] := -0.0045942820899910*o[1];
                o[3] := 0.00217746787145710 + o[2];
                o[4] := o[3]*g.tau;
                o[5] := o[1]*g.tau;
                o[6] := o[1]*o[1];
                o[7] := o[6]*o[6];
                o[8] := o[7]*g.tau;
                o[9] := -7.9449656719138e-6*o[8];
                o[10] := g.pi*g.pi;
                o[11] := -0.0137828462699730*o[1];
                g.g := g.pi*(-0.000125631835895920 + o[4] + g.pi*(-3.9724828359569e-6*o[8] + 1.29192282897840e-7*o[5]*g.pi)) + (-0.0248051489334660 + g.tau*(0.36901534980333 + g.tau*(-3.11613182139250 + g.tau*(-13.1799836742010 + (6.8540841634434 - 0.32961626538917*g.tau)*g.tau + Modelica.Math.log(g.pi)))))/o[5];
                g.gpi := (1.0 + g.pi*(-0.000125631835895920 + o[4] + g.pi*(o[9] + 3.8757684869352e-7*o[5]*g.pi)))/g.pi;
                g.gpipi := (-1.00000000000000 + o[10]*(o[9] + 7.7515369738704e-7*o[5]*g.pi))/o[10];
                g.gtau := g.pi*(0.00217746787145710 + o[11] + g.pi*(-0.000035752345523612*o[7] + 3.8757684869352e-7*o[1]*g.pi)) + (0.074415446800398 + g.tau*(-0.73803069960666 + (3.11613182139250 + o[1]*(6.8540841634434 - 0.65923253077834*g.tau))*g.tau))/o[6];
                g.gtautau := (-0.297661787201592 + g.tau*(2.21409209881998 + (-6.2322636427850 - 0.65923253077834*o[5])*g.tau))/(o[6]*g.tau) + g.pi*(-0.0275656925399460*g.tau + g.pi*(-0.000286018764188897*o[1]*o[6]*g.tau + 7.7515369738704e-7*g.pi*g.tau));
                g.gtaupi := 0.00217746787145710 + o[11] + g.pi*(-0.000071504691047224*o[7] + 1.16273054608056e-6*o[1]*g.pi);
              end g5;

              function tph1 "Inverse function for region 1: T(p,h)"
                input SI.Pressure p "Pressure";
                input SI.SpecificEnthalpy h "Specific enthalpy";
                output SI.Temperature T "Temperature (K)";
              protected
                Real pi "Dimensionless pressure";
                Real eta1 "Dimensionless specific enthalpy";
                Real o[3] "Vector of auxiliary variables";
              algorithm
                assert(p > triple.ptriple, "IF97 medium function tph1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
                pi := p/data.PSTAR2;
                eta1 := h/data.HSTAR1 + 1.0;
                o[1] := eta1*eta1;
                o[2] := o[1]*o[1];
                o[3] := o[2]*o[2];
                T := -238.724899245210 - 13.3917448726020*pi + eta1*(404.21188637945 + 43.211039183559*pi + eta1*(113.497468817180 - 54.010067170506*pi + eta1*(30.5358922039160*pi + eta1*(-6.5964749423638*pi + o[1]*(-5.8457616048039 + o[2]*(pi*(0.0093965400878363 + (-0.0000258586412820730 + 6.6456186191635e-8*pi)*pi) + o[2]*o[3]*(-0.000152854824131400 + o[1]*o[3]*(-1.08667076953770e-6 + pi*(1.15736475053400e-7 + pi*(-4.0644363084799e-9 + pi*(8.0670734103027e-11 + pi*(-9.3477771213947e-13 + (5.8265442020601e-15 - 1.50201859535030e-17*pi)*pi))))))))))));
              end tph1;

              function tph2 "Reverse function for region 2: T(p,h)"
                input SI.Pressure p "Pressure";
                input SI.SpecificEnthalpy h "Specific enthalpy";
                output SI.Temperature T "Temperature (K)";
              protected
                Real pi "Dimensionless pressure";
                Real pi2b "Dimensionless pressure";
                Real pi2c "Dimensionless pressure";
                Real eta "Dimensionless specific enthalpy";
                Real etabc "Dimensionless specific enthalpy";
                Real eta2a "Dimensionless specific enthalpy";
                Real eta2b "Dimensionless specific enthalpy";
                Real eta2c "Dimensionless specific enthalpy";
                Real o[8] "Vector of auxiliary variables";
              algorithm
                pi := p*data.IPSTAR;
                eta := h*data.IHSTAR;
                etabc := h*1.0e-3;
                if (pi < 4.0) then
                  eta2a := eta - 2.1;
                  o[1] := eta2a*eta2a;
                  o[2] := o[1]*o[1];
                  o[3] := pi*pi;
                  o[4] := o[3]*o[3];
                  o[5] := o[3]*pi;
                  T := 1089.89523182880 + (1.84457493557900 - 0.0061707422868339*pi)*pi + eta2a*(849.51654495535 - 4.1792700549624*pi + eta2a*(-107.817480918260 + (6.2478196935812 - 0.310780466295830*pi)*pi + eta2a*(33.153654801263 - 17.3445631081140*pi + o[2]*(-7.4232016790248 + pi*(-200.581768620960 + 11.6708730771070*pi) + o[1]*(271.960654737960*pi + o[1]*(-455.11318285818*pi + eta2a*(1.38657242832260*o[4] + o[1]*o[2]*(3091.96886047550*pi + o[1]*(11.7650487243560 + o[2]*(-13551.3342407750*o[5] + o[2]*(-62.459855192507*o[3]*o[4]*pi + o[2]*(o[4]*(235988.325565140 + 7399.9835474766*pi) + o[1]*(19127.7292396600*o[3]*o[4] + o[1]*(o[3]*(1.28127984040460e8 - 551966.97030060*o[5]) + o[1]*(-9.8554909623276e8*o[3] + o[1]*(2.82245469730020e9*o[3] + o[1]*(o[3]*(-3.5948971410703e9 + 3.7154085996233e6*o[5]) + o[1]*pi*(252266.403578720 + pi*(1.72273499131970e9 + pi*(1.28487346646500e7 + (-1.31052365450540e7 - 415351.64835634*o[3])*pi))))))))))))))))))));
                elseif (pi < (0.12809002730136e-03*etabc - 0.67955786399241)*etabc + 0.90584278514723e3) then
                  eta2b := eta - 2.6;
                  pi2b := pi - 2.0;
                  o[1] := pi2b*pi2b;
                  o[2] := o[1]*pi2b;
                  o[3] := o[1]*o[1];
                  o[4] := eta2b*eta2b;
                  o[5] := o[4]*o[4];
                  o[6] := o[4]*o[5];
                  o[7] := o[5]*o[5];
                  T := 1489.50410795160 + 0.93747147377932*pi2b + eta2b*(743.07798314034 + o[2]*(0.000110328317899990 - 1.75652339694070e-18*o[1]*o[3]) + eta2b*(-97.708318797837 + pi2b*(3.3593118604916 + pi2b*(-0.0218107553247610 + pi2b*(0.000189552483879020 + (2.86402374774560e-7 - 8.1456365207833e-14*o[2])*pi2b))) + o[5]*(3.3809355601454*pi2b + o[4]*(-0.108297844036770*o[1] + o[5]*(2.47424647056740 + (0.168445396719040 + o[1]*(0.00308915411605370 - 0.0000107798573575120*pi2b))*pi2b + o[6]*(-0.63281320016026 + pi2b*(0.73875745236695 + (-0.046333324635812 + o[1]*(-0.000076462712454814 + 2.82172816350400e-7*pi2b))*pi2b) + o[6]*(1.13859521296580 + pi2b*(-0.47128737436186 + o[1]*(0.00135555045549490 + (0.0000140523928183160 + 1.27049022719450e-6*pi2b)*pi2b)) + o[5]*(-0.47811863648625 + (0.150202731397070 + o[2]*(-0.0000310838143314340 + o[1]*(-1.10301392389090e-8 - 2.51805456829620e-11*pi2b)))*pi2b + o[5]*o[7]*(0.0085208123431544 + pi2b*(-0.00217641142197500 + pi2b*(0.000071280351959551 + o[1]*(-1.03027382121030e-6 + (7.3803353468292e-8 + 8.6934156344163e-15*o[3])*pi2b))))))))))));
                else
                  eta2c := eta - 1.8;
                  pi2c := pi + 25.0;
                  o[1] := pi2c*pi2c;
                  o[2] := o[1]*o[1];
                  o[3] := o[1]*o[2]*pi2c;
                  o[4] := 1/o[3];
                  o[5] := o[1]*o[2];
                  o[6] := eta2c*eta2c;
                  o[7] := o[2]*o[2];
                  o[8] := o[6]*o[6];
                  T := eta2c*((859777.22535580 + o[1]*(482.19755109255 + 1.12615974072300e-12*o[5]))/o[1] + eta2c*((-5.8340131851590e11 + (2.08255445631710e10 + 31081.0884227140*o[2])*pi2c)/o[5] + o[6]*(o[8]*(o[6]*(1.23245796908320e-7*o[5] + o[6]*(-1.16069211309840e-6*o[5] + o[8]*(0.0000278463670885540*o[5] + (-0.00059270038474176*o[5] + 0.00129185829918780*o[5]*o[6])*o[8]))) - 10.8429848800770*pi2c) + o[4]*(7.3263350902181e12 + o[7]*(3.7966001272486 + (-0.045364172676660 - 1.78049822406860e-11*o[2])*pi2c))))) + o[4]*(-3.2368398555242e12 + pi2c*(3.5825089945447e11 + pi2c*(-1.07830682174700e10 + o[1]*pi2c*(610747.83564516 + pi2c*(-25745.7236041700 + (1208.23158659360 + 1.45591156586980e-13*o[5])*pi2c)))));
                end if;
              end tph2;

              function tsat "Region 4 saturation temperature as a function of pressure"
                input SI.Pressure p "Pressure";
                output SI.Temperature t_sat "Temperature";
              protected
                Real pi "Dimensionless pressure";
                Real o[20] "Vector of auxiliary variables";
              algorithm
                assert(p > triple.ptriple, "IF97 medium function tsat called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
                pi := min(p, data.PCRIT)*data.IPSTAR;
                o[1] := pi^0.25;
                o[2] := -3.2325550322333e6*o[1];
                o[3] := pi^0.5;
                o[4] := -724213.16703206*o[3];
                o[5] := 405113.40542057 + o[2] + o[4];
                o[6] := -17.0738469400920*o[1];
                o[7] := 14.9151086135300 + o[3] + o[6];
                o[8] := -4.0*o[5]*o[7];
                o[9] := 12020.8247024700*o[1];
                o[10] := 1167.05214527670*o[3];
                o[11] := -4823.2657361591 + o[10] + o[9];
                o[12] := o[11]*o[11];
                o[13] := o[12] + o[8];
                o[14] := o[13]^0.5;
                o[15] := -o[14];
                o[16] := -12020.8247024700*o[1];
                o[17] := -1167.05214527670*o[3];
                o[18] := 4823.2657361591 + o[15] + o[16] + o[17];
                o[19] := 1/o[18];
                o[20] := 2.0*o[19]*o[5];
                t_sat := 0.5*(650.17534844798 + o[20] - (-4.0*(-0.238555575678490 + 1300.35069689596*o[19]*o[5]) + (650.17534844798 + o[20])^2.0)^0.5);
                annotation(derivative = tsat_der);
              end tsat;

              function dtsatofp "Derivative of saturation temperature w.r.t. pressure"
                input SI.Pressure p "Pressure";
                output Real dtsat(unit = "K/Pa") "Derivative of T w.r.t. p";
              protected
                Real pi "Dimensionless pressure";
                Real o[49] "Vector of auxiliary variables";
              algorithm
                pi := max(Modelica.Constants.small, p*data.IPSTAR);
                o[1] := pi^0.75;
                o[2] := 1/o[1];
                o[3] := -4.268461735023*o[2];
                o[4] := sqrt(pi);
                o[5] := 1/o[4];
                o[6] := 0.5*o[5];
                o[7] := o[3] + o[6];
                o[8] := pi^0.25;
                o[9] := -3.2325550322333e6*o[8];
                o[10] := -724213.16703206*o[4];
                o[11] := 405113.40542057 + o[10] + o[9];
                o[12] := -4*o[11]*o[7];
                o[13] := -808138.758058325*o[2];
                o[14] := -362106.58351603*o[5];
                o[15] := o[13] + o[14];
                o[16] := -17.073846940092*o[8];
                o[17] := 14.91510861353 + o[16] + o[4];
                o[18] := -4*o[15]*o[17];
                o[19] := 3005.2061756175*o[2];
                o[20] := 583.52607263835*o[5];
                o[21] := o[19] + o[20];
                o[22] := 12020.82470247*o[8];
                o[23] := 1167.0521452767*o[4];
                o[24] := -4823.2657361591 + o[22] + o[23];
                o[25] := 2.0*o[21]*o[24];
                o[26] := o[12] + o[18] + o[25];
                o[27] := -4.0*o[11]*o[17];
                o[28] := o[24]*o[24];
                o[29] := o[27] + o[28];
                o[30] := sqrt(o[29]);
                o[31] := 1/o[30];
                o[32] := (-o[30]);
                o[33] := -12020.82470247*o[8];
                o[34] := -1167.0521452767*o[4];
                o[35] := 4823.2657361591 + o[32] + o[33] + o[34];
                o[36] := o[30];
                o[37] := -4823.2657361591 + o[22] + o[23] + o[36];
                o[38] := o[37]*o[37];
                o[39] := 1/o[38];
                o[40] := -1.72207339365771*o[30];
                o[41] := 21592.2055343628*o[8];
                o[42] := o[30]*o[8];
                o[43] := -8192.87114842946*o[4];
                o[44] := -0.510632954559659*o[30]*o[4];
                o[45] := -3100.02526152368*o[1];
                o[46] := pi;
                o[47] := 1295.95640782102*o[46];
                o[48] := 2862.09212505088 + o[40] + o[41] + o[42] + o[43] + o[44] + o[45] + o[47];
                o[49] := 1/(o[35]*o[35]);
                dtsat := data.IPSTAR*0.5*((2.0*o[15])/o[35] - 2.*o[11]*(-3005.2061756175*o[2] - 0.5*o[26]*o[31] - 583.52607263835*o[5])*o[49] - (20953.46356643991*(o[39]*(1295.95640782102 + 5398.05138359071*o[2] + 0.25*o[2]*o[30] - 0.861036696828853*o[26]*o[31] - 0.255316477279829*o[26]*o[31]*o[4] - 4096.43557421473*o[5] - 0.255316477279829*o[30]*o[5] - 2325.01894614276/o[8] + 0.5*o[26]*o[31]*o[8]) - 2.0*(o[19] + o[20] + 0.5*o[26]*o[31])*o[48]*o[37]^(-3)))/sqrt(o[39]*o[48]));
              end dtsatofp;

              function tsat_der "Derivative function for tsat"
                input SI.Pressure p "Pressure";
                input Real der_p(unit = "Pa/s") "Pressure derivative";
                output Real der_tsat(unit = "K/s") "Temperature derivative";
              protected
                Real dtp;
              algorithm
                dtp := dtsatofp(p);
                der_tsat := dtp*der_p;
              end tsat_der;

              function psat "Region 4 saturation pressure as a function of temperature"
                input SI.Temperature T "Temperature (K)";
                output SI.Pressure p_sat "Pressure";
              protected
                Real o[8] "Vector of auxiliary variables";
                Real Tlim = min(T, data.TCRIT);
              algorithm
                assert(T >= 273.16, "IF97 medium function psat: input temperature (= " + String(triple.Ttriple) + " K).\n" + "lower than the triple point temperature 273.16 K");
                o[1] := -650.17534844798 + Tlim;
                o[2] := 1/o[1];
                o[3] := -0.238555575678490*o[2];
                o[4] := o[3] + Tlim;
                o[5] := -4823.2657361591*o[4];
                o[6] := o[4]*o[4];
                o[7] := 14.9151086135300*o[6];
                o[8] := 405113.40542057 + o[5] + o[7];
                p_sat := 16.0e6*o[8]*o[8]*o[8]*o[8]*1/(3.2325550322333e6 - 12020.8247024700*o[4] + 17.0738469400920*o[6] + (-4.0*(-724213.16703206 + 1167.05214527670*o[4] + o[6])*o[8] + (-3.2325550322333e6 + 12020.8247024700*o[4] - 17.0738469400920*o[6])^2.0)^0.5)^4.0;
                annotation(derivative = psat_der);
              end psat;

              function dptofT "Derivative of pressure w.r.t. temperature along the saturation pressure curve"
                input SI.Temperature T "Temperature (K)";
                output Real dpt(unit = "Pa/K") "Temperature derivative of pressure";
              protected
                Real o[31] "Vector of auxiliary variables";
                Real Tlim "Temperature limited to TCRIT";
              algorithm
                Tlim := min(T, data.TCRIT);
                o[1] := -650.17534844798 + Tlim;
                o[2] := 1/o[1];
                o[3] := -0.238555575678490*o[2];
                o[4] := o[3] + Tlim;
                o[5] := -4823.2657361591*o[4];
                o[6] := o[4]*o[4];
                o[7] := 14.9151086135300*o[6];
                o[8] := 405113.40542057 + o[5] + o[7];
                o[9] := o[8]*o[8];
                o[10] := o[9]*o[9];
                o[11] := o[1]*o[1];
                o[12] := 1/o[11];
                o[13] := 0.238555575678490*o[12];
                o[14] := 1.00000000000000 + o[13];
                o[15] := 12020.8247024700*o[4];
                o[16] := -17.0738469400920*o[6];
                o[17] := -3.2325550322333e6 + o[15] + o[16];
                o[18] := -4823.2657361591*o[14];
                o[19] := 29.8302172270600*o[14]*o[4];
                o[20] := o[18] + o[19];
                o[21] := 1167.05214527670*o[4];
                o[22] := -724213.16703206 + o[21] + o[6];
                o[23] := o[17]*o[17];
                o[24] := -4.0000000000000*o[22]*o[8];
                o[25] := o[23] + o[24];
                o[26] := sqrt(o[25]);
                o[27] := -12020.8247024700*o[4];
                o[28] := 17.0738469400920*o[6];
                o[29] := 3.2325550322333e6 + o[26] + o[27] + o[28];
                o[30] := o[29]*o[29];
                o[31] := o[30]*o[30];
                dpt := 1e6*((-64.0*o[10]*(-12020.8247024700*o[14] + 34.147693880184*o[14]*o[4] + (0.5*(-4.0*o[20]*o[22] + 2.00000000000000*o[17]*(12020.8247024700*o[14] - 34.147693880184*o[14]*o[4]) - 4.0*(1167.05214527670*o[14] + 2.0*o[14]*o[4])*o[8]))/o[26]))/(o[29]*o[31]) + (64.*o[20]*o[8]*o[9])/o[31]);
              end dptofT;

              function psat_der "Derivative function for psat"
                input SI.Temperature T "Temperature (K)";
                input Real der_T(unit = "K/s") "Temperature derivative";
                output Real der_psat(unit = "Pa/s") "Pressure";
              protected
                Real dpt;
              algorithm
                dpt := dptofT(T);
                der_psat := dpt*der_T;
              end psat_der;

              function h3ab_p "Region 3 a b boundary for pressure/enthalpy"
                output SI.SpecificEnthalpy h "Enthalpy";
                input SI.Pressure p "Pressure";
              protected
                constant Real n[:] = {0.201464004206875e4, 0.374696550136983e1, -0.219921901054187e-1, 0.875131686009950e-4};
                constant SI.SpecificEnthalpy hstar = 1000 "Normalization enthalpy";
                constant SI.Pressure pstar = 1e6 "Normalization pressure";
                Real pi = p/pstar "Normalized specific pressure";
              algorithm
                h := (n[1] + n[2]*pi + n[3]*pi^2 + n[4]*pi^3)*hstar;
              end h3ab_p;

              function T3a_ph "Region 3 a: inverse function T(p,h)"
                input SI.Pressure p "Pressure";
                input SI.SpecificEnthalpy h "Specific enthalpy";
                output SI.Temperature T "Temperature";
              protected
                constant Real n[:] = {-0.133645667811215e-6, 0.455912656802978e-5, -0.146294640700979e-4, 0.639341312970080e-2, 0.372783927268847e3, -0.718654377460447e4, 0.573494752103400e6, -0.267569329111439e7, -0.334066283302614e-4, -0.245479214069597e-1, 0.478087847764996e2, 0.764664131818904e-5, 0.128350627676972e-2, 0.171219081377331e-1, -0.851007304583213e1, -0.136513461629781e-1, -0.384460997596657e-5, 0.337423807911655e-2, -0.551624873066791, 0.729202277107470, -0.992522757376041e-2, -0.119308831407288, 0.793929190615421, 0.454270731799386, 0.209998591259910, -0.642109823904738e-2, -0.235155868604540e-1, 0.252233108341612e-2, -0.764885133368119e-2, 0.136176427574291e-1, -0.133027883575669e-1};
                constant Real I[:] = {-12, -12, -12, -12, -12, -12, -12, -12, -10, -10, -10, -8, -8, -8, -8, -5, -3, -2, -2, -2, -1, -1, 0, 0, 1, 3, 3, 4, 4, 10, 12};
                constant Real J[:] = {0, 1, 2, 6, 14, 16, 20, 22, 1, 5, 12, 0, 2, 4, 10, 2, 0, 1, 3, 4, 0, 2, 0, 1, 1, 0, 1, 0, 3, 4, 5};
                constant SI.SpecificEnthalpy hstar = 2300e3 "Normalization enthalpy";
                constant SI.Pressure pstar = 100e6 "Normalization pressure";
                constant SI.Temperature Tstar = 760 "Normalization temperature";
                Real pi = p/pstar "Normalized specific pressure";
                Real eta = h/hstar "Normalized specific enthalpy";
              algorithm
                T := sum(n[i]*(pi + 0.240)^I[i]*(eta - 0.615)^J[i] for i in 1:31)*Tstar;
              end T3a_ph;

              function T3b_ph "Region 3 b: inverse function T(p,h)"
                input SI.Pressure p "Pressure";
                input SI.SpecificEnthalpy h "Specific enthalpy";
                output SI.Temperature T "Temperature";
              protected
                constant Real n[:] = {0.323254573644920e-4, -0.127575556587181e-3, -0.475851877356068e-3, 0.156183014181602e-2, 0.105724860113781, -0.858514221132534e2, 0.724140095480911e3, 0.296475810273257e-2, -0.592721983365988e-2, -0.126305422818666e-1, -0.115716196364853, 0.849000969739595e2, -0.108602260086615e-1, 0.154304475328851e-1, 0.750455441524466e-1, 0.252520973612982e-1, -0.602507901232996e-1, -0.307622221350501e1, -0.574011959864879e-1, 0.503471360939849e1, -0.925081888584834, 0.391733882917546e1, -0.773146007130190e2, 0.949308762098587e4, -0.141043719679409e7, 0.849166230819026e7, 0.861095729446704, 0.323346442811720, 0.873281936020439, -0.436653048526683, 0.286596714529479, -0.131778331276228, 0.676682064330275e-2};
                constant Real I[:] = {-12, -12, -10, -10, -10, -10, -10, -8, -8, -8, -8, -8, -6, -6, -6, -4, -4, -3, -2, -2, -1, -1, -1, -1, -1, -1, 0, 0, 1, 3, 5, 6, 8};
                constant Real J[:] = {0, 1, 0, 1, 5, 10, 12, 0, 1, 2, 4, 10, 0, 1, 2, 0, 1, 5, 0, 4, 2, 4, 6, 10, 14, 16, 0, 2, 1, 1, 1, 1, 1};
                constant SI.Temperature Tstar = 860 "Normalization temperature";
                constant SI.Pressure pstar = 100e6 "Normalization pressure";
                constant SI.SpecificEnthalpy hstar = 2800e3 "Normalization enthalpy";
                Real pi = p/pstar "Normalized specific pressure";
                Real eta = h/hstar "Normalized specific enthalpy";
              algorithm
                T := sum(n[i]*(pi + 0.298)^I[i]*(eta - 0.720)^J[i] for i in 1:33)*Tstar;
              end T3b_ph;

              function v3a_ph "Region 3 a: inverse function v(p,h)"
                input SI.Pressure p "Pressure";
                input SI.SpecificEnthalpy h "Specific enthalpy";
                output SI.SpecificVolume v "Specific volume";
              protected
                constant Real n[:] = {0.529944062966028e-2, -0.170099690234461, 0.111323814312927e2, -0.217898123145125e4, -0.506061827980875e-3, 0.556495239685324, -0.943672726094016e1, -0.297856807561527, 0.939353943717186e2, 0.192944939465981e-1, 0.421740664704763, -0.368914126282330e7, -0.737566847600639e-2, -0.354753242424366, -0.199768169338727e1, 0.115456297059049e1, 0.568366875815960e4, 0.808169540124668e-2, 0.172416341519307, 0.104270175292927e1, -0.297691372792847, 0.560394465163593, 0.275234661176914, -0.148347894866012, -0.651142513478515e-1, -0.292468715386302e1, 0.664876096952665e-1, 0.352335014263844e1, -0.146340792313332e-1, -0.224503486668184e1, 0.110533464706142e1, -0.408757344495612e-1};
                constant Real I[:] = {-12, -12, -12, -12, -10, -10, -10, -8, -8, -6, -6, -6, -4, -4, -3, -2, -2, -1, -1, -1, -1, 0, 0, 1, 1, 1, 2, 2, 3, 4, 5, 8};
                constant Real J[:] = {6, 8, 12, 18, 4, 7, 10, 5, 12, 3, 4, 22, 2, 3, 7, 3, 16, 0, 1, 2, 3, 0, 1, 0, 1, 2, 0, 2, 0, 2, 2, 2};
                constant SI.Volume vstar = 0.0028 "Normalization temperature";
                constant SI.Pressure pstar = 100e6 "Normalization pressure";
                constant SI.SpecificEnthalpy hstar = 2100e3 "Normalization enthalpy";
                Real pi = p/pstar "Normalized specific pressure";
                Real eta = h/hstar "Normalized specific enthalpy";
              algorithm
                v := sum(n[i]*(pi + 0.128)^I[i]*(eta - 0.727)^J[i] for i in 1:32)*vstar;
              end v3a_ph;

              function v3b_ph "Region 3 b: inverse function v(p,h)"
                input SI.Pressure p "Pressure";
                input SI.SpecificEnthalpy h "Specific enthalpy";
                output SI.SpecificVolume v "Specific volume";
              protected
                constant Real n[:] = {-0.225196934336318e-8, 0.140674363313486e-7, 0.233784085280560e-5, -0.331833715229001e-4, 0.107956778514318e-2, -0.271382067378863, 0.107202262490333e1, -0.853821329075382, -0.215214194340526e-4, 0.769656088222730e-3, -0.431136580433864e-2, 0.453342167309331, -0.507749535873652, -0.100475154528389e3, -0.219201924648793, -0.321087965668917e1, 0.607567815637771e3, 0.557686450685932e-3, 0.187499040029550, 0.905368030448107e-2, 0.285417173048685, 0.329924030996098e-1, 0.239897419685483, 0.482754995951394e1, -0.118035753702231e2, 0.169490044091791, -0.179967222507787e-1, 0.371810116332674e-1, -0.536288335065096e-1, 0.160697101092520e1};
                constant Real I[:] = {-12, -12, -8, -8, -8, -8, -8, -8, -6, -6, -6, -6, -6, -6, -4, -4, -4, -3, -3, -2, -2, -1, -1, -1, -1, 0, 1, 1, 2, 2};
                constant Real J[:] = {0, 1, 0, 1, 3, 6, 7, 8, 0, 1, 2, 5, 6, 10, 3, 6, 10, 0, 2, 1, 2, 0, 1, 4, 5, 0, 0, 1, 2, 6};
                constant SI.Volume vstar = 0.0088 "Normalization temperature";
                constant SI.Pressure pstar = 100e6 "Normalization pressure";
                constant SI.SpecificEnthalpy hstar = 2800e3 "Normalization enthalpy";
                Real pi = p/pstar "Normalized specific pressure";
                Real eta = h/hstar "Normalized specific enthalpy";
              algorithm
                v := sum(n[i]*(pi + 0.0661)^I[i]*(eta - 0.720)^J[i] for i in 1:30)*vstar;
              end v3b_ph;
            end Basic;

            package Transport "Transport properties for water according to IAPWS/IF97"
              function visc_dTp "Dynamic viscosity eta(d,T,p), industrial formulation"
                input SI.Density d "Density";
                input SI.Temperature T "Temperature (K)";
                input SI.Pressure p "Pressure (only needed for region of validity)";
                input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known (unused)";
                input Boolean checkLimits = true "Check if inputs d,T,P are in region of validity";
                output SI.DynamicViscosity eta "Dynamic viscosity";
              protected
                constant Real n0 = 1.0 "Viscosity coefficient";
                constant Real n1 = 0.978197 "Viscosity coefficient";
                constant Real n2 = 0.579829 "Viscosity coefficient";
                constant Real n3 = -0.202354 "Viscosity coefficient";
                constant Real nn[42] = array(0.5132047, 0.3205656, 0.0, 0.0, -0.7782567, 0.1885447, 0.2151778, 0.7317883, 1.241044, 1.476783, 0.0, 0.0, -0.2818107, -1.070786, -1.263184, 0.0, 0.0, 0.0, 0.1778064, 0.460504, 0.2340379, -0.4924179, 0.0, 0.0, -0.0417661, 0.0, 0.0, 0.1600435, 0.0, 0.0, 0.0, -0.01578386, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.003629481, 0.0, 0.0) "Viscosity coefficients";
                constant SI.Density rhostar = 317.763 "Scaling density";
                constant SI.DynamicViscosity etastar = 55.071e-6 "Scaling viscosity";
                constant SI.Temperature tstar = 647.226 "Scaling temperature";
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
                delta := d/rhostar;
                if checkLimits then
                  assert(d > triple.dvtriple, "IF97 medium function visc_dTp for viscosity called with too low density\n" + "d = " + String(d) + " <= " + String(triple.dvtriple) + " (triple point density)");
                  assert((p <= 500e6 and (Tc >= 0.0 and Tc <= 150)) or (p <= 350e6 and (Tc > 150.0 and Tc <= 600)) or (p <= 300e6 and (Tc > 600.0 and Tc <= 900)), "IF97 medium function visc_dTp: viscosity computed outside the range\n" + "of validity of the IF97 formulation: p = " + String(p) + " Pa, Tc = " + String(Tc) + " K");
                else
                end if;
                deltam1 := delta - 1.0;
                tau := tstar/T;
                taum1 := tau - 1.0;
                Psi0 := 1/(n0 + (n1 + (n2 + n3*tau)*tau)*tau)/(tau^0.5);
                Psi1 := 0.0;
                tfun := 1.0;
                for i in 1:6 loop
                  if (i <> 1) then
                    tfun := tfun*taum1;
                  else
                  end if;
                  rhofun := 1.;
                  for j in 0:6 loop
                    if (j <> 0) then
                      rhofun := rhofun*deltam1;
                    else
                    end if;
                    Psi1 := Psi1 + nn[i + j*6]*tfun*rhofun;
                  end for;
                end for;
                eta := etastar*Psi0*Modelica.Math.exp(delta*Psi1);
              end visc_dTp;
            end Transport;

            package Isentropic "Functions for calculating the isentropic enthalpy from pressure p and specific entropy s"
              function hofpT1 "Intermediate function for isentropic specific enthalpy in region 1"
                input SI.Pressure p "Pressure";
                input SI.Temperature T "Temperature (K)";
                output SI.SpecificEnthalpy h "Specific enthalpy";
              protected
                Real o[13] "Vector of auxiliary variables";
                Real pi1 "Dimensionless pressure";
                Real tau "Dimensionless temperature";
                Real tau1 "Dimensionless temperature";
              algorithm
                tau := data.TSTAR1/T;
                pi1 := 7.1 - p/data.PSTAR1;
                assert(p > triple.ptriple, "IF97 medium function hofpT1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
                tau1 := -1.222 + tau;
                o[1] := tau1*tau1;
                o[2] := o[1]*tau1;
                o[3] := o[1]*o[1];
                o[4] := o[3]*o[3];
                o[5] := o[1]*o[4];
                o[6] := o[1]*o[3];
                o[7] := o[3]*tau1;
                o[8] := o[3]*o[4];
                o[9] := pi1*pi1;
                o[10] := o[9]*o[9];
                o[11] := o[10]*o[10];
                o[12] := o[4]*o[4];
                o[13] := o[12]*o[12];
                h := data.RH2O*T*tau*(pi1*((-0.00254871721114236 + o[1]*(0.00424944110961118 + (0.018990068218419 + (-0.021841717175414 - 0.00015851507390979*o[1])*o[1])*o[6]))/o[5] + pi1*((0.00141552963219801 + o[3]*(0.000047661393906987 + o[1]*(-0.0000132425535992538 - 1.2358149370591e-14*o[1]*o[3]*o[4])))/o[3] + pi1*((0.000126718579380216 - 5.11230768720618e-9*o[5])/o[7] + pi1*((0.000011212640954 + o[2]*(1.30342445791202e-6 - 1.4341729937924e-12*o[8]))/o[6] + pi1*(o[9]*pi1*((1.40077319158051e-8 + 1.04549227383804e-9*o[7])/o[8] + o[10]*o[11]*pi1*(1.9941018075704e-17/(o[1]*o[12]*o[3]*o[4]) + o[9]*(-4.48827542684151e-19/o[13] + o[10]*o[9]*(pi1*(4.65957282962769e-22/(o[13]*o[4]) + pi1*((3.83502057899078e-24*pi1)/(o[1]*o[13]*o[4]) - 7.2912378325616e-23/(o[13]*o[4]*tau1))) - 1.00075970318621e-21/(o[1]*o[13]*o[3]*tau1))))) + 3.24135974880936e-6/(o[4]*tau1)))))) + (-0.29265942426334 + tau1*(0.84548187169114 + o[1]*(3.3855169168385 + tau1*(-1.91583926775744 + tau1*(0.47316115539684 + (-0.066465668798004 + 0.0040607314991784*tau1)*tau1)))))/o[2]);
              end hofpT1;

              function hofpT2 "Intermediate function for isentropic specific enthalpy in region 2"
                input SI.Pressure p "Pressure";
                input SI.Temperature T "Temperature (K)";
                output SI.SpecificEnthalpy h "Specific enthalpy";
              protected
                Real o[16] "Vector of auxiliary variables";
                Real pi "Dimensionless pressure";
                Real tau "Dimensionless temperature";
                Real tau2 "Dimensionless temperature";
              algorithm
                assert(p > triple.ptriple, "IF97 medium function hofpT2 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
                pi := p/data.PSTAR2;
                tau := data.TSTAR2/T;
                tau2 := -0.5 + tau;
                o[1] := tau*tau;
                o[2] := o[1]*o[1];
                o[3] := tau2*tau2;
                o[4] := o[3]*tau2;
                o[5] := o[3]*o[3];
                o[6] := o[5]*o[5];
                o[7] := o[6]*o[6];
                o[8] := o[5]*o[6]*o[7]*tau2;
                o[9] := o[3]*o[5];
                o[10] := o[5]*o[6]*tau2;
                o[11] := o[3]*o[7]*tau2;
                o[12] := o[3]*o[5]*o[6];
                o[13] := o[5]*o[6]*o[7];
                o[14] := pi*pi;
                o[15] := o[14]*o[14];
                o[16] := o[7]*o[7];
                h := data.RH2O*T*tau*((0.0280439559151 + tau*(-0.2858109552582 + tau*(1.2213149471784 + tau*(-2.848163942888 + tau*(4.38395111945 + o[1]*(10.08665568018 + (-0.5681726521544 + 0.06380539059921*tau)*tau))))))/(o[1]*o[2]) + pi*(-0.017834862292358 + tau2*(-0.09199202739273 + (-0.172743777250296 - 0.30195167236758*o[4])*tau2) + pi*(-0.000033032641670203 + (-0.0003789797503263 + o[3]*(-0.015757110897342 + o[4]*(-0.306581069554011 - 0.000960283724907132*o[8])))*tau2 + pi*(4.3870667284435e-7 + o[3]*(-0.00009683303171571 + o[4]*(-0.0090203547252888 - 1.42338887469272*o[8])) + pi*(-7.8847309559367e-10 + (2.558143570457e-8 + 1.44676118155521e-6*tau2)*tau2 + pi*(0.0000160454534363627*o[9] + pi*((-5.0144299353183e-11 + o[10]*(-0.033874355714168 - 836.35096769364*o[11]))*o[3] + pi*((-0.0000138839897890111 - 0.973671060893475*o[12])*o[3]*o[6] + pi*((9.0049690883672e-11 - 296.320827232793*o[13])*o[3]*o[5]*tau2 + pi*(2.57526266427144e-7*o[5]*o[6] + pi*(o[4]*(4.1627860840696e-19 + (-1.0234747095929e-12 - 1.40254511313154e-8*o[5])*o[9]) + o[14]*o[15]*(o[13]*(-2.34560435076256e-9 + 5.3465159397045*o[5]*o[7]*tau2) + o[14]*(-19.1874828272775*o[16]*o[6]*o[7] + o[14]*(o[11]*(1.78371690710842e-23 + (1.07202609066812e-11 - 0.000201611844951398*o[10])*o[3]*o[5]*o[6]*tau2) + pi*(-1.24017662339842e-24*o[5]*o[7] + pi*(0.000200482822351322*o[16]*o[5]*o[7] + pi*(-4.97975748452559e-14*o[16]*o[3]*o[5] + o[6]*o[7]*(1.90027787547159e-27 + o[12]*(2.21658861403112e-15 - 0.0000547344301999018*o[3]*o[7]))*pi*tau2)))))))))))))))));
              end hofpT2;
            end Isentropic;

            package Inverses "Efficient inverses for selected pairs of variables"
              function fixdT "Region limits for inverse iteration in region 3"
                input SI.Density din "Density";
                input SI.Temperature Tin "Temperature";
                output SI.Density dout "Density";
                output SI.Temperature Tout "Temperature";
              protected
                SI.Temperature Tmin "Approximation of minimum temperature";
                SI.Temperature Tmax "Approximation of maximum temperature";
              algorithm
                if (din > 765.0) then
                  dout := 765.0;
                elseif (din < 110.0) then
                  dout := 110.0;
                else
                  dout := din;
                end if;
                if (dout < 390.0) then
                  Tmax := 554.3557377 + dout*0.809344262;
                else
                  Tmax := 1116.85 - dout*0.632948717;
                end if;
                if (dout < data.DCRIT) then
                  Tmin := data.TCRIT*(1.0 - (dout - data.DCRIT)*(dout - data.DCRIT)/1.0e6);
                else
                  Tmin := data.TCRIT*(1.0 - (dout - data.DCRIT)*(dout - data.DCRIT)/1.44e6);
                end if;
                if (Tin < Tmin) then
                  Tout := Tmin;
                elseif (Tin > Tmax) then
                  Tout := Tmax;
                else
                  Tout := Tin;
                end if;
              end fixdT;

              function dofp13 "Density at the boundary between regions 1 and 3"
                input SI.Pressure p "Pressure";
                output SI.Density d "Density";
              protected
                Real p2 "Auxiliary variable";
                Real o[3] "Vector of auxiliary variables";
              algorithm
                p2 := 7.1 - 6.04960677555959e-8*p;
                o[1] := p2*p2;
                o[2] := o[1]*o[1];
                o[3] := o[2]*o[2];
                d := 57.4756752485113/(0.0737412153522555 + p2*(0.00145092247736023 + p2*(0.000102697173772229 + p2*(0.0000114683182476084 + p2*(1.99080616601101e-6 + o[1]*p2*(1.13217858826367e-8 + o[2]*o[3]*p2*(1.35549330686006e-17 + o[1]*(-3.11228834832975e-19 + o[1]*o[2]*(-7.02987180039442e-22 + p2*(3.29199117056433e-22 + (-5.17859076694812e-23 + 2.73712834080283e-24*p2)*p2))))))))));
              end dofp13;

              function dofp23 "Density at the boundary between regions 2 and 3"
                input SI.Pressure p "Pressure";
                output SI.Density d "Density";
              protected
                SI.Temperature T;
                Real o[13] "Vector of auxiliary variables";
                Real taug "Auxiliary variable";
                Real pi "Dimensionless pressure";
                Real gpi23 "Derivative of g w.r.t. pi on the boundary between regions 2 and 3";
              algorithm
                pi := p/data.PSTAR2;
                T := 572.54459862746 + 31.3220101646784*(-13.91883977887 + pi)^0.5;
                o[1] := (-13.91883977887 + pi)^0.5;
                taug := -0.5 + 540.0/(572.54459862746 + 31.3220101646784*o[1]);
                o[2] := taug*taug;
                o[3] := o[2]*taug;
                o[4] := o[2]*o[2];
                o[5] := o[4]*o[4];
                o[6] := o[5]*o[5];
                o[7] := o[4]*o[5]*o[6]*taug;
                o[8] := o[4]*o[5]*taug;
                o[9] := o[2]*o[4]*o[5];
                o[10] := pi*pi;
                o[11] := o[10]*o[10];
                o[12] := o[4]*o[6]*taug;
                o[13] := o[6]*o[6];
                gpi23 := (1.0 + pi*(-0.0017731742473213 + taug*(-0.017834862292358 + taug*(-0.045996013696365 + (-0.057581259083432 - 0.05032527872793*o[3])*taug)) + pi*(taug*(-0.000066065283340406 + (-0.0003789797503263 + o[2]*(-0.007878555448671 + o[3]*(-0.087594591301146 - 0.000053349095828174*o[7])))*taug) + pi*(6.1445213076927e-8 + (1.31612001853305e-6 + o[2]*(-0.00009683303171571 + o[3]*(-0.0045101773626444 - 0.122004760687947*o[7])))*taug + pi*(taug*(-3.15389238237468e-9 + (5.116287140914e-8 + 1.92901490874028e-6*taug)*taug) + pi*(0.0000114610381688305*o[2]*o[4]*taug + pi*(o[3]*(-1.00288598706366e-10 + o[8]*(-0.012702883392813 - 143.374451604624*o[2]*o[6]*taug)) + pi*(-4.1341695026989e-17 + o[2]*o[5]*(-8.8352662293707e-6 - 0.272627897050173*o[9])*taug + pi*(o[5]*(9.0049690883672e-11 - 65.8490727183984*o[4]*o[5]*o[6]) + pi*(1.78287415218792e-7*o[8] + pi*(o[4]*(1.0406965210174e-18 + o[2]*(-1.0234747095929e-12 - 1.0018179379511e-8*o[4])*o[4]) + o[10]*o[11]*((-1.29412653835176e-9 + 1.71088510070544*o[12])*o[7] + o[10]*(-6.05920510335078*o[13]*o[5]*o[6]*taug + o[10]*(o[4]*o[6]*(1.78371690710842e-23 + o[2]*o[4]*o[5]*(6.1258633752464e-12 - 0.000084004935396416*o[8])*taug) + pi*(-1.24017662339842e-24*o[12] + pi*(0.0000832192847496054*o[13]*o[4]*o[6]*taug + pi*(o[2]*o[5]*o[6]*(1.75410265428146e-27 + (1.32995316841867e-15 - 0.0000226487297378904*o[2]*o[6])*o[9])*pi - 2.93678005497663e-14*o[13]*o[2]*o[4]*taug)))))))))))))))))/pi;
                d := p/(data.RH2O*T*pi*gpi23);
              end dofp23;

              function dofpt3 "Inverse iteration in region 3: (d) = f(p,T)"
                input SI.Pressure p "Pressure";
                input SI.Temperature T "Temperature (K)";
                input SI.Pressure delp "Iteration converged if (p-pre(p) < delp)";
                output SI.Density d "Density";
                output Integer error = 0 "Error flag: iteration failed if different from 0";
              protected
                SI.Density dguess "Guess density";
                Integer i = 0 "Loop counter";
                Real dp "Pressure difference";
                SI.Density deld "Density step";
                ThermofluidStream.Media.myMedia.Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
                ThermofluidStream.Media.myMedia.Common.NewtonDerivatives_pT nDerivs "Derivatives needed in Newton iteration";
                Boolean found = false "Flag for iteration success";
                Boolean supercritical "Flag, true for supercritical states";
                Boolean liquid "Flag, true for liquid states";
                SI.Density dmin "Lower density limit";
                SI.Density dmax "Upper density limit";
                SI.Temperature Tmax "Maximum temperature";
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
                  dguess := dmax - (T - data.TLIMIT1)/(data.TLIMIT1 - Tmax)*(dmax - dmin);
                else
                  liquid := T < Basic.tsat(p);
                  if liquid then
                    dmax := dofp13(p);
                    dmin := Regions.rhol_p_R4b(p);
                    dguess := 1.1*Regions.rhol_T(T) "Guess: 10 percent more than on the phase boundary for same T";
                  else
                    dmax := Regions.rhov_p_R4b(p);
                    dmin := dofp23(p);
                    dguess := 0.9*Regions.rhov_T(T) "Guess: 10% less than on the phase boundary for same T";
                  end if;
                end if;
                while ((i < IterationData.IMAX) and not found) loop
                  d := dguess;
                  f := Basic.f3(d, T);
                  nDerivs := ThermofluidStream.Media.myMedia.Common.Helmholtz_pT(f);
                  dp := nDerivs.p - p;
                  if (abs(dp/p) <= delp) then
                    found := true;
                  else
                  end if;
                  deld := dp/nDerivs.pd*damping;
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

              function dtofph3 "Inverse iteration in region 3: (d,T) = f(p,h)"
                input SI.Pressure p "Pressure";
                input SI.SpecificEnthalpy h "Specific enthalpy";
                input SI.Pressure delp "Iteration accuracy";
                input SI.SpecificEnthalpy delh "Iteration accuracy";
                output SI.Density d "Density";
                output SI.Temperature T "Temperature (K)";
                output Integer error "Error flag: iteration failed if different from 0";
              protected
                SI.Temperature Tguess "Initial temperature";
                SI.Density dguess "Initial density";
                Integer i "Iteration counter";
                Real dh "Newton-error in h-direction";
                Real dp "Newton-error in p-direction";
                Real det "Determinant of directional derivatives";
                Real deld "Newton-step in d-direction";
                Real delt "Newton-step in T-direction";
                ThermofluidStream.Media.myMedia.Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
                ThermofluidStream.Media.myMedia.Common.NewtonDerivatives_ph nDerivs "Derivatives needed in Newton iteration";
                Boolean found = false "Flag for iteration success";
                Integer subregion "1 for subregion 3a, 2 for subregion 3b";
              algorithm
                if p < data.PCRIT then
                  subregion := if h < (Regions.hl_p(p) + 10.0) then 1 else if h > (Regions.hv_p(p) - 10.0) then 2 else 0;
                  assert(subregion <> 0, "Inverse iteration of dt from ph called in 2 phase region: this can not work");
                else
                  subregion := if h < Basic.h3ab_p(p) then 1 else 2;
                end if;
                T := if subregion == 1 then Basic.T3a_ph(p, h) else Basic.T3b_ph(p, h);
                d := if subregion == 1 then 1/Basic.v3a_ph(p, h) else 1/Basic.v3b_ph(p, h);
                i := 0;
                error := 0;
                while ((i < IterationData.IMAX) and not found) loop
                  f := Basic.f3(d, T);
                  nDerivs := ThermofluidStream.Media.myMedia.Common.Helmholtz_ph(f);
                  dh := nDerivs.h - h;
                  dp := nDerivs.p - p;
                  if ((abs(dh/h) <= delh) and (abs(dp/p) <= delp)) then
                    found := true;
                  else
                  end if;
                  det := nDerivs.ht*nDerivs.pd - nDerivs.pt*nDerivs.hd;
                  delt := (nDerivs.pd*dh - nDerivs.hd*dp)/det;
                  deld := (nDerivs.ht*dp - nDerivs.pt*dh)/det;
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

              function pofdt125 "Inverse iteration in region 1,2 and 5: p = g(d,T)"
                input SI.Density d "Density";
                input SI.Temperature T "Temperature (K)";
                input SI.Pressure reldd "Relative iteration accuracy of density";
                input Integer region "Region in IAPWS/IF97 in which inverse should be calculated";
                output SI.Pressure p "Pressure";
                output Integer error "Error flag: iteration failed if different from 0";
              protected
                Integer i "Counter for while-loop";
                ThermofluidStream.Media.myMedia.Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
                Boolean found "Flag if iteration has been successful";
                Real dd "Difference between density for guessed p and the current density";
                Real delp "Step in p in Newton-iteration";
                Real relerr "Relative error in d";
                SI.Pressure pguess1 = 1.0e6 "Initial pressure guess in region 1";
                SI.Pressure pguess2 "Initial pressure guess in region 2";
                constant SI.Pressure pguess5 = 0.5e6 "Initial pressure guess in region 5";
              algorithm
                i := 0;
                error := 0;
                pguess2 := 42800*d;
                found := false;
                if region == 1 then
                  p := pguess1;
                elseif region == 2 then
                  p := pguess2;
                else
                  p := pguess5;
                end if;
                while ((i < IterationData.IMAX) and not found) loop
                  if region == 1 then
                    g := Basic.g1(p, T);
                  elseif region == 2 then
                    g := Basic.g2(p, T);
                  else
                    g := Basic.g5(p, T);
                  end if;
                  dd := p/(data.RH2O*T*g.pi*g.gpi) - d;
                  relerr := dd/d;
                  if (abs(relerr) < reldd) then
                    found := true;
                  else
                  end if;
                  delp := dd*(-p*p/(d*d*data.RH2O*T*g.pi*g.pi*g.gpipi));
                  p := p - delp;
                  i := i + 1;
                  if not found then
                    if p < triple.ptriple then
                      p := 2.0*triple.ptriple;
                    else
                    end if;
                    if p > data.PLIMIT1 then
                      p := 0.95*data.PLIMIT1;
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

              function tofph5 "Inverse iteration in region 5: (p,T) = f(p,h)"
                input SI.Pressure p "Pressure";
                input SI.SpecificEnthalpy h "Specific enthalpy";
                input SI.SpecificEnthalpy reldh "Iteration accuracy";
                output SI.Temperature T "Temperature (K)";
                output Integer error "Error flag: iteration failed if different from 0";
              protected
                ThermofluidStream.Media.myMedia.Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
                SI.SpecificEnthalpy proh "H for current guess in T";
                constant SI.Temperature Tguess = 1500 "Initial temperature";
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
                while ((i < IterationData.IMAX) and not found) loop
                  g := Basic.g5(p, T);
                  proh := data.RH2O*T*g.tau*g.gtau;
                  dh := proh - h;
                  relerr := dh/h;
                  if (abs(relerr) < reldh) then
                    found := true;
                  else
                  end if;
                  dT := dh/(-data.RH2O*g.tau*g.tau*g.gtautau);
                  T := T - dT;
                  i := i + 1;
                end while;
                if not found then
                  error := 1;
                else
                end if;
                assert(error <> 1, "Error in inverse function tofph5: iteration failed");
              end tofph5;
            end Inverses;

            package TwoPhase "Steam properties in the two-phase region and on the phase boundaries" end TwoPhase;
          end BaseIF97;

          function waterBaseProp_ph "Intermediate property record for water"
            input SI.Pressure p "Pressure";
            input SI.SpecificEnthalpy h "Specific enthalpy";
            input Integer phase = 0 "Phase: 2 for two-phase, 1 for one phase, 0 if unknown";
            input Integer region = 0 "If 0, do region computation, otherwise assume the region is this input";
            output Common.IF97BaseTwoPhase aux "Auxiliary record";
          protected
            Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
            Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
            Integer error "Error flag for inverse iterations";
            SI.SpecificEnthalpy h_liq "Liquid specific enthalpy";
            SI.Density d_liq "Liquid density";
            SI.SpecificEnthalpy h_vap "Vapour specific enthalpy";
            SI.Density d_vap "Vapour density";
            Common.PhaseBoundaryProperties liq "Phase boundary property record";
            Common.PhaseBoundaryProperties vap "Phase boundary property record";
            Common.GibbsDerivs gl "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
            Common.GibbsDerivs gv "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
            ThermofluidStream.Media.myMedia.Common.HelmholtzDerivs fl "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
            ThermofluidStream.Media.myMedia.Common.HelmholtzDerivs fv "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
            SI.Temperature t1 "Temperature at phase boundary, using inverse from region 1";
            SI.Temperature t2 "Temperature at phase boundary, using inverse from region 2";
          algorithm
            aux.region := if region == 0 then (if phase == 2 then 4 else BaseIF97.Regions.region_ph(p = p, h = h, phase = phase)) else region;
            aux.phase := if phase <> 0 then phase else if aux.region == 4 then 2 else 1;
            aux.p := max(p, 611.657);
            aux.h := max(h, 1e3);
            aux.R_s := BaseIF97.data.RH2O;
            aux.vt := 0.0 "Initialized in case it is not needed";
            aux.vp := 0.0 "Initialized in case it is not needed";
            if (aux.region == 1) then
              aux.T := BaseIF97.Basic.tph1(aux.p, aux.h);
              g := BaseIF97.Basic.g1(p, aux.T);
              aux.s := aux.R_s*(g.tau*g.gtau - g.g);
              aux.rho := p/(aux.R_s*aux.T*g.pi*g.gpi);
              aux.vt := aux.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
              aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
              aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
              aux.vp := aux.R_s*aux.T/(p*p)*g.pi*g.pi*g.gpipi;
              aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
              aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi));
              aux.x := 0.0;
              aux.dpT := -aux.vt/aux.vp;
            elseif (aux.region == 2) then
              aux.T := BaseIF97.Basic.tph2(aux.p, aux.h);
              g := BaseIF97.Basic.g2(p, aux.T);
              aux.s := aux.R_s*(g.tau*g.gtau - g.g);
              aux.rho := p/(aux.R_s*aux.T*g.pi*g.gpi);
              aux.vt := aux.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
              aux.vp := aux.R_s*aux.T/(p*p)*g.pi*g.pi*g.gpipi;
              aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
              aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
              aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
              aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi));
              aux.x := 1.0;
              aux.dpT := -aux.vt/aux.vp;
            elseif (aux.region == 3) then
              (aux.rho, aux.T, error) := BaseIF97.Inverses.dtofph3(p = aux.p, h = aux.h, delp = 1.0e-7, delh = 1.0e-6);
              f := BaseIF97.Basic.f3(aux.rho, aux.T);
              aux.h := aux.R_s*aux.T*(f.tau*f.ftau + f.delta*f.fdelta);
              aux.s := aux.R_s*(f.tau*f.ftau - f.f);
              aux.pd := aux.R_s*aux.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
              aux.pt := aux.R_s*aux.rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
              aux.cv := abs(aux.R_s*(-f.tau*f.tau*f.ftautau)) "Can be close to neg. infinity near critical point";
              aux.cp := (aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)/(aux.rho*aux.rho*aux.pd);
              aux.x := 0.0;
              aux.dpT := aux.pt;
            elseif (aux.region == 4) then
              h_liq := hl_p(p);
              h_vap := hv_p(p);
              aux.x := if (h_vap <> h_liq) then (h - h_liq)/(h_vap - h_liq) else 1.0;
              if p < BaseIF97.data.PLIMIT4A then
                t1 := BaseIF97.Basic.tph1(aux.p, h_liq);
                t2 := BaseIF97.Basic.tph2(aux.p, h_vap);
                gl := BaseIF97.Basic.g1(aux.p, t1);
                gv := BaseIF97.Basic.g2(aux.p, t2);
                liq := Common.gibbsToBoundaryProps(gl);
                vap := Common.gibbsToBoundaryProps(gv);
                aux.T := t1 + aux.x*(t2 - t1);
              else
                aux.T := BaseIF97.Basic.tsat(aux.p);
                d_liq := rhol_T(aux.T);
                d_vap := rhov_T(aux.T);
                fl := BaseIF97.Basic.f3(d_liq, aux.T);
                fv := BaseIF97.Basic.f3(d_vap, aux.T);
                liq := Common.helmholtzToBoundaryProps(fl);
                vap := Common.helmholtzToBoundaryProps(fv);
              end if;
              aux.dpT := if (liq.d <> vap.d) then (vap.s - liq.s)*liq.d*vap.d/(liq.d - vap.d) else BaseIF97.Basic.dptofT(aux.T);
              aux.s := liq.s + aux.x*(vap.s - liq.s);
              aux.rho := liq.d*vap.d/(vap.d + aux.x*(liq.d - vap.d));
              aux.cv := Common.cv2Phase(liq, vap, aux.x, aux.T, p);
              aux.cp := liq.cp + aux.x*(vap.cp - liq.cp);
              aux.pt := liq.pt + aux.x*(vap.pt - liq.pt);
              aux.pd := liq.pd + aux.x*(vap.pd - liq.pd);
            elseif (aux.region == 5) then
              (aux.T, error) := BaseIF97.Inverses.tofph5(p = aux.p, h = aux.h, reldh = 1.0e-7);
              assert(error == 0, "Error in inverse iteration of steam tables");
              g := BaseIF97.Basic.g5(aux.p, aux.T);
              aux.s := aux.R_s*(g.tau*g.gtau - g.g);
              aux.rho := p/(aux.R_s*aux.T*g.pi*g.gpi);
              aux.vt := aux.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
              aux.vp := aux.R_s*aux.T/(p*p)*g.pi*g.pi*g.gpipi;
              aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
              aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
              aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
              aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi));
              aux.dpT := -aux.vt/aux.vp;
            else
              assert(false, "Error in region computation of IF97 steam tables" + "(p = " + String(p) + ", h = " + String(h) + ")");
            end if;
          end waterBaseProp_ph;

          function rho_props_ph "Density as function of pressure and specific enthalpy"
            input SI.Pressure p "Pressure";
            input SI.SpecificEnthalpy h "Specific enthalpy";
            input Common.IF97BaseTwoPhase properties "Auxiliary record";
            output SI.Density rho "Density";
          algorithm
            rho := properties.rho;
            annotation(derivative(noDerivative = properties) = rho_ph_der, Inline = false, LateInline = true);
          end rho_props_ph;

          function rho_ph "Density as function of pressure and specific enthalpy"
            input SI.Pressure p "Pressure";
            input SI.SpecificEnthalpy h "Specific enthalpy";
            input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
            output SI.Density rho "Density";
          algorithm
            rho := rho_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
            annotation(Inline = true);
          end rho_ph;

          function rho_ph_der "Derivative function of rho_ph"
            input SI.Pressure p "Pressure";
            input SI.SpecificEnthalpy h "Specific enthalpy";
            input Common.IF97BaseTwoPhase properties "Auxiliary record";
            input Real p_der "Derivative of pressure";
            input Real h_der "Derivative of specific enthalpy";
            output Real rho_der "Derivative of density";
          algorithm
            if (properties.region == 4) then
              rho_der := (properties.rho*(properties.rho*properties.cv/properties.dpT + 1.0)/(properties.dpT*properties.T))*p_der + (-properties.rho*properties.rho/(properties.dpT*properties.T))*h_der;
            elseif (properties.region == 3) then
              rho_der := ((properties.rho*(properties.cv*properties.rho + properties.pt))/(properties.rho*properties.rho*properties.pd*properties.cv + properties.T*properties.pt*properties.pt))*p_der + (-properties.rho*properties.rho*properties.pt/(properties.rho*properties.rho*properties.pd*properties.cv + properties.T*properties.pt*properties.pt))*h_der;
            else
              rho_der := (-properties.rho*properties.rho*(properties.vp*properties.cp - properties.vt/properties.rho + properties.T*properties.vt*properties.vt)/properties.cp)*p_der + (-properties.rho*properties.rho*properties.vt/(properties.cp))*h_der;
            end if;
          end rho_ph_der;

          function T_props_ph "Temperature as function of pressure and specific enthalpy"
            input SI.Pressure p "Pressure";
            input SI.SpecificEnthalpy h "Specific enthalpy";
            input Common.IF97BaseTwoPhase properties "Auxiliary record";
            output SI.Temperature T "Temperature";
          algorithm
            T := properties.T;
            annotation(derivative(noDerivative = properties) = T_ph_der, Inline = false, LateInline = true);
          end T_props_ph;

          function T_ph "Temperature as function of pressure and specific enthalpy"
            input SI.Pressure p "Pressure";
            input SI.SpecificEnthalpy h "Specific enthalpy";
            input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
            output SI.Temperature T "Temperature";
          algorithm
            T := T_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
            annotation(Inline = true);
          end T_ph;

          function T_ph_der "Derivative function of T_ph"
            input SI.Pressure p "Pressure";
            input SI.SpecificEnthalpy h "Specific enthalpy";
            input Common.IF97BaseTwoPhase properties "Auxiliary record";
            input Real p_der "Derivative of pressure";
            input Real h_der "Derivative of specific enthalpy";
            output Real T_der "Derivative of temperature";
          algorithm
            if (properties.region == 4) then
              T_der := 1/properties.dpT*p_der;
            elseif (properties.region == 3) then
              T_der := ((-properties.rho*properties.pd + properties.T*properties.pt)/(properties.rho*properties.rho*properties.pd*properties.cv + properties.T*properties.pt*properties.pt))*p_der + ((properties.rho*properties.rho*properties.pd)/(properties.rho*properties.rho*properties.pd*properties.cv + properties.T*properties.pt*properties.pt))*h_der;
            else
              T_der := ((-1/properties.rho + properties.T*properties.vt)/properties.cp)*p_der + (1/properties.cp)*h_der;
            end if;
          end T_ph_der;

          function s_props_ph "Specific entropy as function of pressure and specific enthalpy"
            input SI.Pressure p "Pressure";
            input SI.SpecificEnthalpy h "Specific enthalpy";
            input Common.IF97BaseTwoPhase properties "Auxiliary record";
            output SI.SpecificEntropy s "Specific entropy";
          algorithm
            s := properties.s;
            annotation(derivative(noDerivative = properties) = s_ph_der, Inline = false, LateInline = true);
          end s_props_ph;

          function s_ph "Specific entropy as function of pressure and specific enthalpy"
            input SI.Pressure p "Pressure";
            input SI.SpecificEnthalpy h "Specific enthalpy";
            input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
            output SI.SpecificEntropy s "Specific entropy";
          algorithm
            s := s_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
            annotation(Inline = true);
          end s_ph;

          function s_ph_der "Specific entropy as function of pressure and specific enthalpy"
            input SI.Pressure p "Pressure";
            input SI.SpecificEnthalpy h "Specific enthalpy";
            input Common.IF97BaseTwoPhase properties "Auxiliary record";
            input Real p_der "Derivative of pressure";
            input Real h_der "Derivative of specific enthalpy";
            output Real s_der "Derivative of entropy";
          algorithm
            s_der := -1/(properties.rho*properties.T)*p_der + 1/properties.T*h_der;
            annotation(Inline = true);
          end s_ph_der;

          function cv_props_ph "Specific heat capacity at constant volume as function of pressure and specific enthalpy"
            input SI.Pressure p "Pressure";
            input SI.SpecificEnthalpy h "Specific enthalpy";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            output SI.SpecificHeatCapacity cv "Specific heat capacity";
          algorithm
            cv := aux.cv;
            annotation(Inline = false, LateInline = true);
          end cv_props_ph;

          function cv_ph "Specific heat capacity at constant volume as function of pressure and specific enthalpy"
            input SI.Pressure p "Pressure";
            input SI.SpecificEnthalpy h "Specific enthalpy";
            input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
            output SI.SpecificHeatCapacity cv "Specific heat capacity";
          algorithm
            cv := cv_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
            annotation(Inline = true);
          end cv_ph;

          function cp_props_ph "Specific heat capacity at constant pressure as function of pressure and specific enthalpy"
            input SI.Pressure p "Pressure";
            input SI.SpecificEnthalpy h "Specific enthalpy";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            output SI.SpecificHeatCapacity cp "Specific heat capacity";
          algorithm
            cp := aux.cp;
            annotation(Inline = false, LateInline = true);
          end cp_props_ph;

          function cp_ph "Specific heat capacity at constant pressure as function of pressure and specific enthalpy"
            input SI.Pressure p "Pressure";
            input SI.SpecificEnthalpy h "Specific enthalpy";
            input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
            output SI.SpecificHeatCapacity cp "Specific heat capacity";
          algorithm
            cp := cp_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
            annotation(Inline = true);
          end cp_ph;

          function beta_props_ph "Isobaric expansion coefficient as function of pressure and specific enthalpy"
            input SI.Pressure p "Pressure";
            input SI.SpecificEnthalpy h "Specific enthalpy";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            output SI.RelativePressureCoefficient beta "Isobaric expansion coefficient";
          algorithm
            beta := if aux.region == 3 or aux.region == 4 then aux.pt/(aux.rho*aux.pd) else aux.vt*aux.rho;
            annotation(Inline = false, LateInline = true);
          end beta_props_ph;

          function beta_ph "Isobaric expansion coefficient as function of pressure and specific enthalpy"
            input SI.Pressure p "Pressure";
            input SI.SpecificEnthalpy h "Specific enthalpy";
            input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
            output SI.RelativePressureCoefficient beta "Isobaric expansion coefficient";
          algorithm
            beta := beta_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
            annotation(Inline = true);
          end beta_ph;

          function velocityOfSound_props_ph "Speed of sound as function of pressure and specific enthalpy"
            input SI.Pressure p "Pressure";
            input SI.SpecificEnthalpy h "Specific enthalpy";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            output SI.Velocity v_sound "Speed of sound";
          algorithm
            v_sound := if aux.region == 3 then sqrt(max(0, (aux.pd*aux.rho*aux.rho*aux.cv + aux.pt*aux.pt*aux.T)/(aux.rho*aux.rho*aux.cv))) else if aux.region == 4 then sqrt(max(0, 1/((aux.rho*(aux.rho*aux.cv/aux.dpT + 1.0)/(aux.dpT*aux.T)) - 1/aux.rho*aux.rho*aux.rho/(aux.dpT*aux.T)))) else sqrt(max(0, -aux.cp/(aux.rho*aux.rho*(aux.vp*aux.cp + aux.vt*aux.vt*aux.T))));
            annotation(Inline = false, LateInline = true);
          end velocityOfSound_props_ph;

          function velocityOfSound_ph
            input SI.Pressure p "Pressure";
            input SI.SpecificEnthalpy h "Specific enthalpy";
            input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
            output SI.Velocity v_sound "Speed of sound";
          algorithm
            v_sound := velocityOfSound_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
            annotation(Inline = true);
          end velocityOfSound_ph;

          function isentropicExponent_props_ph "Isentropic exponent as function of pressure and specific enthalpy"
            input SI.Pressure p "Pressure";
            input SI.SpecificEnthalpy h "Specific enthalpy";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            output Real gamma "Isentropic exponent";
          algorithm
            gamma := if aux.region == 3 then 1/(aux.rho*p)*((aux.pd*aux.cv*aux.rho*aux.rho + aux.pt*aux.pt*aux.T)/(aux.cv)) else if aux.region == 4 then 1/(aux.rho*p)*aux.dpT*aux.dpT*aux.T/aux.cv else -1/(aux.rho*aux.p)*aux.cp/(aux.vp*aux.cp + aux.vt*aux.vt*aux.T);
            annotation(Inline = false, LateInline = true);
          end isentropicExponent_props_ph;

          function isentropicExponent_ph "Isentropic exponent as function of pressure and specific enthalpy"
            input SI.Pressure p "Pressure";
            input SI.SpecificEnthalpy h "Specific enthalpy";
            input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
            output Real gamma "Isentropic exponent";
          algorithm
            gamma := isentropicExponent_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
            annotation(Inline = false, LateInline = true);
          end isentropicExponent_ph;

          function ddph_props "Density derivative by pressure"
            input SI.Pressure p "Pressure";
            input SI.SpecificEnthalpy h "Specific enthalpy";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            output SI.DerDensityByPressure ddph "Density derivative by pressure";
          algorithm
            ddph := if aux.region == 3 then ((aux.rho*(aux.cv*aux.rho + aux.pt))/(aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)) else if aux.region == 4 then (aux.rho*(aux.rho*aux.cv/aux.dpT + 1.0)/(aux.dpT*aux.T)) else (-aux.rho*aux.rho*(aux.vp*aux.cp - aux.vt/aux.rho + aux.T*aux.vt*aux.vt)/aux.cp);
            annotation(Inline = false, LateInline = true);
          end ddph_props;

          function ddph "Density derivative by pressure"
            input SI.Pressure p "Pressure";
            input SI.SpecificEnthalpy h "Specific enthalpy";
            input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
            output SI.DerDensityByPressure ddph "Density derivative by pressure";
          algorithm
            ddph := ddph_props(p, h, waterBaseProp_ph(p, h, phase, region));
            annotation(Inline = true);
          end ddph;

          function waterBaseProp_pT "Intermediate property record for water (p and T preferred states)"
            input SI.Pressure p "Pressure";
            input SI.Temperature T "Temperature";
            input Integer region = 0 "If 0, do region computation, otherwise assume the region is this input";
            output Common.IF97BaseTwoPhase aux "Auxiliary record";
          protected
            Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
            Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
            Integer error "Error flag for inverse iterations";
          algorithm
            aux.phase := 1;
            aux.region := if region == 0 then BaseIF97.Regions.region_pT(p = p, T = T) else region;
            aux.R_s := BaseIF97.data.RH2O;
            aux.p := p;
            aux.T := T;
            aux.vt := 0.0 "Initialized in case it is not needed";
            aux.vp := 0.0 "Initialized in case it is not needed";
            if (aux.region == 1) then
              g := BaseIF97.Basic.g1(p, T);
              aux.h := aux.R_s*aux.T*g.tau*g.gtau;
              aux.s := aux.R_s*(g.tau*g.gtau - g.g);
              aux.rho := p/(aux.R_s*T*g.pi*g.gpi);
              aux.vt := aux.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
              aux.vp := aux.R_s*T/(p*p)*g.pi*g.pi*g.gpipi;
              aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
              aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi));
              aux.x := 0.0;
              aux.dpT := -aux.vt/aux.vp;
              aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
              aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
            elseif (aux.region == 2) then
              g := BaseIF97.Basic.g2(p, T);
              aux.h := aux.R_s*aux.T*g.tau*g.gtau;
              aux.s := aux.R_s*(g.tau*g.gtau - g.g);
              aux.rho := p/(aux.R_s*T*g.pi*g.gpi);
              aux.vt := aux.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
              aux.vp := aux.R_s*T/(p*p)*g.pi*g.pi*g.gpipi;
              aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
              aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
              aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
              aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi));
              aux.x := 1.0;
              aux.dpT := -aux.vt/aux.vp;
            elseif (aux.region == 3) then
              (aux.rho, error) := BaseIF97.Inverses.dofpt3(p = p, T = T, delp = 1.0e-7);
              f := BaseIF97.Basic.f3(aux.rho, T);
              aux.h := aux.R_s*T*(f.tau*f.ftau + f.delta*f.fdelta);
              aux.s := aux.R_s*(f.tau*f.ftau - f.f);
              aux.pd := aux.R_s*T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
              aux.pt := aux.R_s*aux.rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
              aux.cv := aux.R_s*(-f.tau*f.tau*f.ftautau);
              aux.x := 0.0;
              aux.dpT := aux.pt;
            elseif (aux.region == 5) then
              g := BaseIF97.Basic.g5(p, T);
              aux.h := aux.R_s*aux.T*g.tau*g.gtau;
              aux.s := aux.R_s*(g.tau*g.gtau - g.g);
              aux.rho := p/(aux.R_s*T*g.pi*g.gpi);
              aux.vt := aux.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
              aux.vp := aux.R_s*T/(p*p)*g.pi*g.pi*g.gpipi;
              aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
              aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
              aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
              aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi));
              aux.x := 1.0;
              aux.dpT := -aux.vt/aux.vp;
            else
              assert(false, "Error in region computation of IF97 steam tables" + "(p = " + String(p) + ", T = " + String(T) + ")");
            end if;
          end waterBaseProp_pT;

          function rho_props_pT "Density as function or pressure and temperature"
            input SI.Pressure p "Pressure";
            input SI.Temperature T "Temperature";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            output SI.Density rho "Density";
          algorithm
            rho := aux.rho;
            annotation(derivative(noDerivative = aux) = rho_pT_der, Inline = false, LateInline = true);
          end rho_props_pT;

          function rho_pT "Density as function or pressure and temperature"
            input SI.Pressure p "Pressure";
            input SI.Temperature T "Temperature";
            input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
            output SI.Density rho "Density";
          algorithm
            rho := rho_props_pT(p, T, waterBaseProp_pT(p, T, region));
            annotation(Inline = true);
          end rho_pT;

          function h_props_pT "Specific enthalpy as function or pressure and temperature"
            input SI.Pressure p "Pressure";
            input SI.Temperature T "Temperature";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            output SI.SpecificEnthalpy h "Specific enthalpy";
          algorithm
            h := aux.h;
            annotation(derivative(noDerivative = aux) = h_pT_der, Inline = false, LateInline = true);
          end h_props_pT;

          function h_pT "Specific enthalpy as function or pressure and temperature"
            input SI.Pressure p "Pressure";
            input SI.Temperature T "Temperature";
            input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
            output SI.SpecificEnthalpy h "Specific enthalpy";
          algorithm
            h := h_props_pT(p, T, waterBaseProp_pT(p, T, region));
            annotation(Inline = true);
          end h_pT;

          function h_pT_der "Derivative function of h_pT"
            input SI.Pressure p "Pressure";
            input SI.Temperature T "Temperature";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            input Real p_der "Derivative of pressure";
            input Real T_der "Derivative of temperature";
            output Real h_der "Derivative of specific enthalpy";
          algorithm
            if (aux.region == 3) then
              h_der := ((-aux.rho*aux.pd + T*aux.pt)/(aux.rho*aux.rho*aux.pd))*p_der + ((aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)/(aux.rho*aux.rho*aux.pd))*T_der;
            else
              h_der := (1/aux.rho - aux.T*aux.vt)*p_der + aux.cp*T_der;
            end if;
          end h_pT_der;

          function rho_pT_der "Derivative function of rho_pT"
            input SI.Pressure p "Pressure";
            input SI.Temperature T "Temperature";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            input Real p_der "Derivative of pressure";
            input Real T_der "Derivative of temperature";
            output Real rho_der "Derivative of density";
          algorithm
            if (aux.region == 3) then
              rho_der := (1/aux.pd)*p_der - (aux.pt/aux.pd)*T_der;
            else
              rho_der := (-aux.rho*aux.rho*aux.vp)*p_der + (-aux.rho*aux.rho*aux.vt)*T_der;
            end if;
          end rho_pT_der;

          function s_props_pT "Specific entropy as function of pressure and temperature"
            input SI.Pressure p "Pressure";
            input SI.Temperature T "Temperature";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            output SI.SpecificEntropy s "Specific entropy";
          algorithm
            s := aux.s;
            annotation(Inline = false, LateInline = true);
          end s_props_pT;

          function s_pT "Temperature as function of pressure and temperature"
            input SI.Pressure p "Pressure";
            input SI.Temperature T "Temperature";
            input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
            output SI.SpecificEntropy s "Specific entropy";
          algorithm
            s := s_props_pT(p, T, waterBaseProp_pT(p, T, region));
            annotation(Inline = true);
          end s_pT;

          function cv_props_pT "Specific heat capacity at constant volume as function of pressure and temperature"
            input SI.Pressure p "Pressure";
            input SI.Temperature T "Temperature";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            output SI.SpecificHeatCapacity cv "Specific heat capacity";
          algorithm
            cv := aux.cv;
            annotation(Inline = false, LateInline = true);
          end cv_props_pT;

          function cv_pT "Specific heat capacity at constant volume as function of pressure and temperature"
            input SI.Pressure p "Pressure";
            input SI.Temperature T "Temperature";
            input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
            output SI.SpecificHeatCapacity cv "Specific heat capacity";
          algorithm
            cv := cv_props_pT(p, T, waterBaseProp_pT(p, T, region));
            annotation(Inline = true);
          end cv_pT;

          function cp_props_pT "Specific heat capacity at constant pressure as function of pressure and temperature"
            input SI.Pressure p "Pressure";
            input SI.Temperature T "Temperature";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            output SI.SpecificHeatCapacity cp "Specific heat capacity";
          algorithm
            cp := if aux.region == 3 then (aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)/(aux.rho*aux.rho*aux.pd) else aux.cp;
            annotation(Inline = false, LateInline = true);
          end cp_props_pT;

          function cp_pT "Specific heat capacity at constant pressure as function of pressure and temperature"
            input SI.Pressure p "Pressure";
            input SI.Temperature T "Temperature";
            input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
            output SI.SpecificHeatCapacity cp "Specific heat capacity";
          algorithm
            cp := cp_props_pT(p, T, waterBaseProp_pT(p, T, region));
            annotation(Inline = true);
          end cp_pT;

          function beta_props_pT "Isobaric expansion coefficient as function of pressure and temperature"
            input SI.Pressure p "Pressure";
            input SI.Temperature T "Temperature";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            output SI.RelativePressureCoefficient beta "Isobaric expansion coefficient";
          algorithm
            beta := if aux.region == 3 then aux.pt/(aux.rho*aux.pd) else aux.vt*aux.rho;
            annotation(Inline = false, LateInline = true);
          end beta_props_pT;

          function beta_pT "Isobaric expansion coefficient as function of pressure and temperature"
            input SI.Pressure p "Pressure";
            input SI.Temperature T "Temperature";
            input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
            output SI.RelativePressureCoefficient beta "Isobaric expansion coefficient";
          algorithm
            beta := beta_props_pT(p, T, waterBaseProp_pT(p, T, region));
            annotation(Inline = true);
          end beta_pT;

          function velocityOfSound_props_pT "Speed of sound as function of pressure and temperature"
            input SI.Pressure p "Pressure";
            input SI.Temperature T "Temperature";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            output SI.Velocity v_sound "Speed of sound";
          algorithm
            v_sound := if aux.region == 3 then sqrt(max(0, (aux.pd*aux.rho*aux.rho*aux.cv + aux.pt*aux.pt*aux.T)/(aux.rho*aux.rho*aux.cv))) else sqrt(max(0, -aux.cp/(aux.rho*aux.rho*(aux.vp*aux.cp + aux.vt*aux.vt*aux.T))));
            annotation(Inline = false, LateInline = true);
          end velocityOfSound_props_pT;

          function velocityOfSound_pT "Speed of sound as function of pressure and temperature"
            input SI.Pressure p "Pressure";
            input SI.Temperature T "Temperature";
            input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
            output SI.Velocity v_sound "Speed of sound";
          algorithm
            v_sound := velocityOfSound_props_pT(p, T, waterBaseProp_pT(p, T, region));
            annotation(Inline = true);
          end velocityOfSound_pT;

          function isentropicExponent_props_pT "Isentropic exponent as function of pressure and temperature"
            input SI.Pressure p "Pressure";
            input SI.Temperature T "Temperature";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            output Real gamma "Isentropic exponent";
          algorithm
            gamma := if aux.region == 3 then 1/(aux.rho*p)*((aux.pd*aux.cv*aux.rho*aux.rho + aux.pt*aux.pt*aux.T)/(aux.cv)) else -1/(aux.rho*aux.p)*aux.cp/(aux.vp*aux.cp + aux.vt*aux.vt*aux.T);
            annotation(Inline = false, LateInline = true);
          end isentropicExponent_props_pT;

          function isentropicExponent_pT "Isentropic exponent as function of pressure and temperature"
            input SI.Pressure p "Pressure";
            input SI.Temperature T "Temperature";
            input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
            output Real gamma "Isentropic exponent";
          algorithm
            gamma := isentropicExponent_props_pT(p, T, waterBaseProp_pT(p, T, region));
            annotation(Inline = false, LateInline = true);
          end isentropicExponent_pT;

          function waterBaseProp_dT "Intermediate property record for water (d and T preferred states)"
            input SI.Density rho "Density";
            input SI.Temperature T "Temperature";
            input Integer phase = 0 "Phase: 2 for two-phase, 1 for one phase, 0 if unknown";
            input Integer region = 0 "If 0, do region computation, otherwise assume the region is this input";
            output Common.IF97BaseTwoPhase aux "Auxiliary record";
          protected
            SI.SpecificEnthalpy h_liq "Liquid specific enthalpy";
            SI.Density d_liq "Liquid density";
            SI.SpecificEnthalpy h_vap "Vapour specific enthalpy";
            SI.Density d_vap "Vapour density";
            Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
            Common.HelmholtzDerivs f "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
            ThermofluidStream.Media.myMedia.Common.PhaseBoundaryProperties liq "Phase boundary property record";
            ThermofluidStream.Media.myMedia.Common.PhaseBoundaryProperties vap "Phase boundary property record";
            ThermofluidStream.Media.myMedia.Common.GibbsDerivs gl "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
            ThermofluidStream.Media.myMedia.Common.GibbsDerivs gv "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
            ThermofluidStream.Media.myMedia.Common.HelmholtzDerivs fl "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
            ThermofluidStream.Media.myMedia.Common.HelmholtzDerivs fv "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
            Integer error "Error flag for inverse iterations";
          algorithm
            aux.region := if region == 0 then (if phase == 2 then 4 else BaseIF97.Regions.region_dT(d = rho, T = T, phase = phase)) else region;
            aux.phase := if aux.region == 4 then 2 else 1;
            aux.R_s := BaseIF97.data.RH2O;
            aux.rho := rho;
            aux.T := T;
            aux.vt := 0.0 "Initialized in case it is not needed";
            aux.vp := 0.0 "Initialized in case it is not needed";
            if (aux.region == 1) then
              (aux.p, error) := BaseIF97.Inverses.pofdt125(d = rho, T = T, reldd = 1.0e-8, region = 1);
              g := BaseIF97.Basic.g1(aux.p, T);
              aux.h := aux.R_s*aux.T*g.tau*g.gtau;
              aux.s := aux.R_s*(g.tau*g.gtau - g.g);
              aux.rho := aux.p/(aux.R_s*T*g.pi*g.gpi);
              aux.vt := aux.R_s/aux.p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
              aux.vp := aux.R_s*T/(aux.p*aux.p)*g.pi*g.pi*g.gpipi;
              aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
              aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
              aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
              aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi));
              aux.x := 0.0;
            elseif (aux.region == 2) then
              (aux.p, error) := BaseIF97.Inverses.pofdt125(d = rho, T = T, reldd = 1.0e-8, region = 2);
              g := BaseIF97.Basic.g2(aux.p, T);
              aux.h := aux.R_s*aux.T*g.tau*g.gtau;
              aux.s := aux.R_s*(g.tau*g.gtau - g.g);
              aux.rho := aux.p/(aux.R_s*T*g.pi*g.gpi);
              aux.vt := aux.R_s/aux.p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
              aux.vp := aux.R_s*T/(aux.p*aux.p)*g.pi*g.pi*g.gpipi;
              aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
              aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
              aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
              aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi));
              aux.x := 1.0;
            elseif (aux.region == 3) then
              f := BaseIF97.Basic.f3(rho, T);
              aux.p := aux.R_s*rho*T*f.delta*f.fdelta;
              aux.h := aux.R_s*T*(f.tau*f.ftau + f.delta*f.fdelta);
              aux.s := aux.R_s*(f.tau*f.ftau - f.f);
              aux.pd := aux.R_s*T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
              aux.pt := aux.R_s*rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
              aux.cv := aux.R_s*(-f.tau*f.tau*f.ftautau);
              aux.cp := (aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)/(aux.rho*aux.rho*aux.pd);
              aux.x := 0.0;
            elseif (aux.region == 4) then
              aux.p := BaseIF97.Basic.psat(T);
              d_liq := rhol_T(T);
              d_vap := rhov_T(T);
              h_liq := hl_p(aux.p);
              h_vap := hv_p(aux.p);
              aux.x := if (d_vap <> d_liq) then (1/rho - 1/d_liq)/(1/d_vap - 1/d_liq) else 1.0;
              aux.h := h_liq + aux.x*(h_vap - h_liq);
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
              aux.dpT := if (liq.d <> vap.d) then (vap.s - liq.s)*liq.d*vap.d/(liq.d - vap.d) else BaseIF97.Basic.dptofT(aux.T);
              aux.s := liq.s + aux.x*(vap.s - liq.s);
              aux.cv := Common.cv2Phase(liq, vap, aux.x, aux.T, aux.p);
              aux.cp := liq.cp + aux.x*(vap.cp - liq.cp);
              aux.pt := liq.pt + aux.x*(vap.pt - liq.pt);
              aux.pd := liq.pd + aux.x*(vap.pd - liq.pd);
            elseif (aux.region == 5) then
              (aux.p, error) := BaseIF97.Inverses.pofdt125(d = rho, T = T, reldd = 1.0e-8, region = 5);
              g := BaseIF97.Basic.g2(aux.p, T);
              aux.h := aux.R_s*aux.T*g.tau*g.gtau;
              aux.s := aux.R_s*(g.tau*g.gtau - g.g);
              aux.rho := aux.p/(aux.R_s*T*g.pi*g.gpi);
              aux.vt := aux.R_s/aux.p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
              aux.vp := aux.R_s*T/(aux.p*aux.p)*g.pi*g.pi*g.gpipi;
              aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
              aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
              aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
              aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi));
            else
              assert(false, "Error in region computation of IF97 steam tables" + "(rho = " + String(rho) + ", T = " + String(T) + ")");
            end if;
          end waterBaseProp_dT;

          function h_props_dT "Specific enthalpy as function of density and temperature"
            input SI.Density d "Density";
            input SI.Temperature T "Temperature";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            output SI.SpecificEnthalpy h "Specific enthalpy";
          algorithm
            h := aux.h;
            annotation(derivative(noDerivative = aux) = h_dT_der, Inline = false, LateInline = true);
          end h_props_dT;

          function h_dT "Specific enthalpy as function of density and temperature"
            input SI.Density d "Density";
            input SI.Temperature T "Temperature";
            input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
            output SI.SpecificEnthalpy h "Specific enthalpy";
          algorithm
            h := h_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
            annotation(Inline = true);
          end h_dT;

          function h_dT_der "Derivative function of h_dT"
            input SI.Density d "Density";
            input SI.Temperature T "Temperature";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            input Real d_der "Derivative of density";
            input Real T_der "Derivative of temperature";
            output Real h_der "Derivative of specific enthalpy";
          algorithm
            if (aux.region == 3) then
              h_der := ((-d*aux.pd + T*aux.pt)/(d*d))*d_der + ((aux.cv*d + aux.pt)/d)*T_der;
            elseif (aux.region == 4) then
              h_der := T*aux.dpT/(d*d)*d_der + ((aux.cv*d + aux.dpT)/d)*T_der;
            else
              h_der := (-(-1/d + T*aux.vt)/(d*d*aux.vp))*d_der + ((aux.vp*aux.cp - aux.vt/d + T*aux.vt*aux.vt)/aux.vp)*T_der;
            end if;
          end h_dT_der;

          function p_props_dT "Pressure as function of density and temperature"
            input SI.Density d "Density";
            input SI.Temperature T "Temperature";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            output SI.Pressure p "Pressure";
          algorithm
            p := aux.p;
            annotation(derivative(noDerivative = aux) = p_dT_der, Inline = false, LateInline = true);
          end p_props_dT;

          function p_dT "Pressure as function of density and temperature"
            input SI.Density d "Density";
            input SI.Temperature T "Temperature";
            input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
            output SI.Pressure p "Pressure";
          algorithm
            p := p_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
            annotation(Inline = true);
          end p_dT;

          function p_dT_der "Derivative function of p_dT"
            input SI.Density d "Density";
            input SI.Temperature T "Temperature";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            input Real d_der "Derivative of density";
            input Real T_der "Derivative of temperature";
            output Real p_der "Derivative of pressure";
          algorithm
            if (aux.region == 3) then
              p_der := aux.pd*d_der + aux.pt*T_der;
            elseif (aux.region == 4) then
              p_der := aux.dpT*T_der;
            else
              p_der := (-1/(d*d*aux.vp))*d_der + (-aux.vt/aux.vp)*T_der;
            end if;
          end p_dT_der;

          function s_props_dT "Specific entropy as function of density and temperature"
            input SI.Density d "Density";
            input SI.Temperature T "Temperature";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            output SI.SpecificEntropy s "Specific entropy";
          algorithm
            s := aux.s;
            annotation(Inline = false, LateInline = true);
          end s_props_dT;

          function s_dT "Temperature as function of density and temperature"
            input SI.Density d "Density";
            input SI.Temperature T "Temperature";
            input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
            output SI.SpecificEntropy s "Specific entropy";
          algorithm
            s := s_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
            annotation(Inline = true);
          end s_dT;

          function cv_props_dT "Specific heat capacity at constant volume as function of density and temperature"
            input SI.Density d "Density";
            input SI.Temperature T "Temperature";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            output SI.SpecificHeatCapacity cv "Specific heat capacity";
          algorithm
            cv := aux.cv;
            annotation(Inline = false, LateInline = true);
          end cv_props_dT;

          function cv_dT "Specific heat capacity at constant volume as function of density and temperature"
            input SI.Density d "Density";
            input SI.Temperature T "Temperature";
            input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
            output SI.SpecificHeatCapacity cv "Specific heat capacity";
          algorithm
            cv := cv_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
            annotation(Inline = true);
          end cv_dT;

          function cp_props_dT "Specific heat capacity at constant pressure as function of density and temperature"
            input SI.Density d "Density";
            input SI.Temperature T "Temperature";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            output SI.SpecificHeatCapacity cp "Specific heat capacity";
          algorithm
            cp := aux.cp;
            annotation(Inline = false, LateInline = true);
          end cp_props_dT;

          function cp_dT "Specific heat capacity at constant pressure as function of density and temperature"
            input SI.Density d "Density";
            input SI.Temperature T "Temperature";
            input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
            output SI.SpecificHeatCapacity cp "Specific heat capacity";
          algorithm
            cp := cp_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
            annotation(Inline = true);
          end cp_dT;

          function beta_props_dT "Isobaric expansion coefficient as function of density and temperature"
            input SI.Density d "Density";
            input SI.Temperature T "Temperature";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            output SI.RelativePressureCoefficient beta "Isobaric expansion coefficient";
          algorithm
            beta := if aux.region == 3 or aux.region == 4 then aux.pt/(aux.rho*aux.pd) else aux.vt*aux.rho;
            annotation(Inline = false, LateInline = true);
          end beta_props_dT;

          function beta_dT "Isobaric expansion coefficient as function of density and temperature"
            input SI.Density d "Density";
            input SI.Temperature T "Temperature";
            input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
            output SI.RelativePressureCoefficient beta "Isobaric expansion coefficient";
          algorithm
            beta := beta_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
            annotation(Inline = true);
          end beta_dT;

          function velocityOfSound_props_dT "Speed of sound as function of density and temperature"
            input SI.Density d "Density";
            input SI.Temperature T "Temperature";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            output SI.Velocity v_sound "Speed of sound";
          algorithm
            v_sound := if aux.region == 3 then sqrt(max(0, ((aux.pd*aux.rho*aux.rho*aux.cv + aux.pt*aux.pt*aux.T)/(aux.rho*aux.rho*aux.cv)))) else if aux.region == 4 then sqrt(max(0, 1/((aux.rho*(aux.rho*aux.cv/aux.dpT + 1.0)/(aux.dpT*aux.T)) - 1/aux.rho*aux.rho*aux.rho/(aux.dpT*aux.T)))) else sqrt(max(0, -aux.cp/(aux.rho*aux.rho*(aux.vp*aux.cp + aux.vt*aux.vt*aux.T))));
            annotation(Inline = false, LateInline = true);
          end velocityOfSound_props_dT;

          function velocityOfSound_dT "Speed of sound as function of density and temperature"
            input SI.Density d "Density";
            input SI.Temperature T "Temperature";
            input Integer phase = 0 "2 for two-phase, 1 for one-phase, 0 if not known";
            input Integer region = 0 "If 0, region is unknown, otherwise known and this input";
            output SI.Velocity v_sound "Speed of sound";
          algorithm
            v_sound := velocityOfSound_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
            annotation(Inline = true);
          end velocityOfSound_dT;

          function isentropicExponent_props_dT "Isentropic exponent as function of density and temperature"
            input SI.Density d "Density";
            input SI.Temperature T "Temperature";
            input Common.IF97BaseTwoPhase aux "Auxiliary record";
            output Real gamma "Isentropic exponent";
          algorithm
            gamma := if aux.region == 3 then 1/(aux.rho*aux.p)*((aux.pd*aux.cv*aux.rho*aux.rho + aux.pt*aux.pt*aux.T)/(aux.cv)) else if aux.region == 4 then 1/(aux.rho*aux.p)*aux.dpT*aux.dpT*aux.T/aux.cv else -1/(aux.rho*aux.p)*aux.cp/(aux.vp*aux.cp + aux.vt*aux.vt*aux.T);
            annotation(Inline = false, LateInline = true);
          end isentropicExponent_props_dT;

          function isentropicExponent_dT "Isentropic exponent as function of density and temperature"
            input SI.Density d "Density";
            input SI.Temperature T "Temperature";
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
          function rhol_p = BaseIF97.Regions.rhol_p "Compute the saturated liquid d(p)";
          function rhov_p = BaseIF97.Regions.rhov_p "Compute the saturated vapour d(p)";
          function dynamicViscosity = BaseIF97.Transport.visc_dTp "Compute eta(d,T) in the one-phase region";
        end IF97_Utilities;
      end Water;
    end myMedia;
  end Media;

  model DropOfCommons "Model for global parameters"
    parameter Utilities.Units.Inertance L = 0.01 "Inertance of the flow";
    parameter SI.MassFlowRate m_flow_reg = 0.01 "Regularization threshold of mass flow rate";
    parameter SI.AngularVelocity omega_reg = 1 "Angular velocity used for regularization";
    parameter SI.Density rho_min = 1e-10 "Minimum allowed density";
    parameter SI.Pressure p_min = 100 "Minimal steady-state pressure";
    parameter Real k_volume_damping(unit = "1") = 0.1 "Volume damping factor multiplicator";
    parameter SI.Acceleration g = Modelica.Constants.g_n "Acceleration of gravity";
    parameter AssertionLevel assertionLevel = AssertionLevel.error "Global assertion level";
    parameter Boolean displayInstanceNames = false "= true, if ThermofluidStream instance names are displayed" annotation(Evaluate = true, HideResult = true);
    parameter Boolean displayParameters = false "= true, if displaying parameters is enabled" annotation(Evaluate = true, HideResult = true);
    final parameter Integer instanceNameColor[3] = {28, 108, 200};
    annotation(defaultComponentPrefixes = "inner", missingInnerMessage = "
  Your model is using an outer \"dropOfCommons\" component but
  an inner \"dropOfCommons\" component is not defined.
  Use ThermoFluidStream.DropOfCommons in your model
  to specify system properties.");
  end DropOfCommons;
  annotation(version = "1.2.0", versionDate = "2024-11-18", dateModified = "2024-11-18 16:54:00Z");
end ThermofluidStream;

model EspressoMachine_total  "Get your simulated coffee!"
  extends ThermofluidStream.Examples.EspressoMachine;
 annotation(experiment(StopTime = 1500, Tolerance = 1e-6, Interval = 1.5, __Dymola_Algorithm = "Dassl"));
end EspressoMachine_total;
