package ModelicaServices
  "(version = 3.2.1, target = \"Dymola\") Models and functions used in the Modelica Standard Library requiring a tool specific implementation"

package Machine

  final constant Real inf=1.e+60
  "Biggest Real number such that inf and -inf are representable on the machine";
end Machine;
end ModelicaServices;

package Modelica "Modelica Standard Library - Version 3.2.1 (Build 2)"
extends Modelica.Icons.Package;

  package Blocks
  "Library of basic input/output control blocks (continuous, discrete, logical, table blocks)"
  import SI = Modelica.SIunits;
  extends Modelica.Icons.Package;

    package Continuous
    "Library of continuous control blocks with internal states"
      import Modelica.Blocks.Interfaces;
      import Modelica.SIunits;
      extends Modelica.Icons.Package;

      block Integrator "Output the integral of the input signal"
        import Modelica.Blocks.Types.Init;
        parameter Real k(unit="1")=1 "Integrator gain";

        /* InitialState is the default, because it was the default in Modelica 2.2
     and therefore this setting is backward compatible
  */
        parameter Modelica.Blocks.Types.Init initType=Modelica.Blocks.Types.Init.InitialState
        "Type of initialization (1: no init, 2: steady state, 3,4: initial output)";
        parameter Real y_start=0 "Initial or guess value of output (= state)";
        extends Interfaces.SISO(y(start=y_start));

      initial equation
        if initType == Init.SteadyState then
           der(y) = 0;
        elseif initType == Init.InitialState or
               initType == Init.InitialOutput then
          y = y_start;
        end if;
      equation
        der(y) = k*u;
      end Integrator;
    end Continuous;

    package Interfaces
    "Library of connectors and partial models for input/output blocks"
      import Modelica.SIunits;
      extends Modelica.Icons.InterfacesPackage;

      connector RealInput = input Real "'input Real' as connector";

      connector RealOutput = output Real "'output Real' as connector";

      partial block SISO "Single Input Single Output continuous control block"
        extends Modelica.Blocks.Icons.Block;

        RealInput u "Connector of Real input signal";
        RealOutput y "Connector of Real output signal";
      end SISO;

      partial block SI2SO
      "2 Single Input / 1 Single Output continuous control block"
        extends Modelica.Blocks.Icons.Block;

        RealInput u1 "Connector of Real input signal 1";
        RealInput u2 "Connector of Real input signal 2";
        RealOutput y "Connector of Real output signal";


      end SI2SO;
    end Interfaces;

    package Math
    "Library of Real mathematical functions as input/output blocks"
      import Modelica.SIunits;
      import Modelica.Blocks.Interfaces;
      extends Modelica.Icons.Package;

          block Gain "Output the product of a gain value with the input signal"

            parameter Real k(start=1, unit="1")
        "Gain value multiplied with input signal";
    public
            Interfaces.RealInput u "Input signal connector";
            Interfaces.RealOutput y "Output signal connector";

          equation
            y = k*u;
          end Gain;

          block Add "Output the sum of the two inputs"
            extends Interfaces.SI2SO;

            parameter Real k1=+1 "Gain of upper input";
            parameter Real k2=+1 "Gain of lower input";

          equation
            y = k1*u1 + k2*u2;
          end Add;

          block Add3 "Output the sum of the three inputs"
            extends Modelica.Blocks.Icons.Block;

            parameter Real k1=+1 "Gain of upper input";
            parameter Real k2=+1 "Gain of middle input";
            parameter Real k3=+1 "Gain of lower input";
            Interfaces.RealInput u1 "Connector 1 of Real input signals";
            Interfaces.RealInput u2 "Connector 2 of Real input signals";
            Interfaces.RealInput u3 "Connector 3 of Real input signals";
            Interfaces.RealOutput y "Connector of Real output signals";

          equation
            y = k1*u1 + k2*u2 + k3*u3;
          end Add3;

          block Division "Output first input divided by second input"
            extends Interfaces.SI2SO;

          equation
            y = u1/u2;
          end Division;
    end Math;

    package Nonlinear
    "Library of discontinuous or non-differentiable algebraic control blocks"
      import Modelica.Blocks.Interfaces;
      extends Modelica.Icons.Package;

          block Limiter "Limit the range of a signal"
            parameter Real uMax(start=1) "Upper limits of input signals";
            parameter Real uMin= -uMax "Lower limits of input signals";
            parameter Boolean strict=false
        "= true, if strict limits with noEvent(..)";
            parameter Boolean limitsAtInit=true
        "= false, if limits are ignored during initialization (i.e., y=u)";
            extends Interfaces.SISO;

          equation
            assert(uMax >= uMin, "Limiter: Limits must be consistent. However, uMax (=" + String(uMax) +
                                 ") < uMin (=" + String(uMin) + ")");
            if initial() and not limitsAtInit then
               y = u;
               assert(u >= uMin - 0.01*abs(uMin) and
                      u <= uMax + 0.01*abs(uMax),
                     "Limiter: During initialization the limits have been ignored.\n"+
                     "However, the result is that the input u is not within the required limits:\n"+
                     "  u = " + String(u) + ", uMin = " + String(uMin) + ", uMax = " + String(uMax));
            elseif strict then
               y = smooth(0, noEvent(if u > uMax then uMax else if u < uMin then uMin else u));
            else
               y = smooth(0,if u > uMax then uMax else if u < uMin then uMin else u);
            end if;
          end Limiter;
    end Nonlinear;

    package Types
    "Library of constants and types with choices, especially to build menus"
      extends Modelica.Icons.TypesPackage;

      type Init = enumeration(
        NoInit
          "No initialization (start values are used as guess values with fixed=false)",

        SteadyState
          "Steady state initialization (derivatives of states are zero)",
        InitialState "Initialization with initial states",
        InitialOutput
          "Initialization with initial outputs (and steady state of the states if possible)")
      "Enumeration defining initialization of a block";
    end Types;

    package Icons "Icons for Blocks"
        extends Modelica.Icons.IconsPackage;

        partial block Block "Basic graphical layout of input/output block"


        end Block;
    end Icons;
  end Blocks;

  package Math
  "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices"
  import SI = Modelica.SIunits;
  extends Modelica.Icons.Package;

  package Icons "Icons for Math"
    extends Modelica.Icons.IconsPackage;

    partial function AxisLeft
    "Basic icon for mathematical function with y-axis on left side"

    end AxisLeft;
  end Icons;

  function log10 "Base 10 logarithm (u shall be > 0)"
    extends Modelica.Math.Icons.AxisLeft;
    input Real u;
    output Real y;

  external "builtin" y=  log10(u);
  end log10;
  end Math;

  package Constants
  "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)"
    import SI = Modelica.SIunits;
    import NonSI = Modelica.SIunits.Conversions.NonSIunits;
    extends Modelica.Icons.Package;

    final constant Real inf=ModelicaServices.Machine.inf
    "Biggest Real number such that inf and -inf are representable on the machine";
  end Constants;

  package Icons "Library of icons"
    extends Icons.Package;

    partial model Example "Icon for runnable examples"

    end Example;

    partial package Package "Icon for standard packages"

    end Package;

    partial package InterfacesPackage "Icon for packages containing interfaces"
      extends Modelica.Icons.Package;
    end InterfacesPackage;

    partial package TypesPackage
    "Icon for packages containing type definitions"
      extends Modelica.Icons.Package;
    end TypesPackage;

    partial package IconsPackage "Icon for packages containing icons"
      extends Modelica.Icons.Package;
    end IconsPackage;

    partial package Library
    "This icon will be removed in future Modelica versions, use Package instead"
      // extends Modelica.Icons.ObsoleteModel;
    end Library;
  end Icons;

  package SIunits
  "Library of type and unit definitions based on SI units according to ISO 31-1992"
    extends Modelica.Icons.Package;

    package Conversions
    "Conversion functions to/from non SI units and type definitions of non SI units"
      extends Modelica.Icons.Package;

      package NonSIunits "Type definitions of non SI units"
        extends Modelica.Icons.Package;
      end NonSIunits;
    end Conversions;
  end SIunits;
end Modelica;

package SystemDynamics "System Dynamics Library (Version 2.1)"

  package Interfaces
  "Connectors and partial models of the System Dynamics methodology"
    extends Modelica.Icons.Library;

    connector MassInPort = Modelica.Blocks.Interfaces.RealInput
    "Mass flow input signal";

    connector MassOutPort = Modelica.Blocks.Interfaces.RealOutput
    "Mass flow output signal";

    partial block Nonlin_0 "Non-linear function with zero inputs"
      Modelica.Blocks.Interfaces.RealOutput y "Output variable";
    end Nonlin_0;

    partial block Nonlin_1 "Non-linear function with one input"
      Modelica.Blocks.Interfaces.RealInput u "Input variable";
      Modelica.Blocks.Interfaces.RealOutput y "Output variable";
    end Nonlin_1;

    partial block Nonlin_2 "Non-linear function with two inputs"
      Modelica.Blocks.Interfaces.RealInput u1 "First input variable";
      Modelica.Blocks.Interfaces.RealInput u2 "Second input variable";
      Modelica.Blocks.Interfaces.RealOutput y "Output variable";
    end Nonlin_2;

    partial block Nonlin_3 "Non-linear function with three inputs"
      Modelica.Blocks.Interfaces.RealInput u1 "First input variable";
      Modelica.Blocks.Interfaces.RealInput u2 "Second input variable";
      Modelica.Blocks.Interfaces.RealInput u3 "Third input variable";
      Modelica.Blocks.Interfaces.RealOutput y "Output variable";
    end Nonlin_3;

    partial block Nonlin_4 "Non-linear function with four inputs"
      Modelica.Blocks.Interfaces.RealInput u1 "First input variable";
      Modelica.Blocks.Interfaces.RealInput u2 "Second input variable";
      Modelica.Blocks.Interfaces.RealInput u3 "Third input variable";
      Modelica.Blocks.Interfaces.RealInput u4 "Fourth input variable";
      Modelica.Blocks.Interfaces.RealOutput y "Output variable";
    end Nonlin_4;
  end Interfaces;

  package Auxiliary "Auxiliary elements of the System Dynamics methodology"
    extends Modelica.Icons.Library;

    block Const "A constant factor"
      parameter Real k = 0 "Constant additive term";
      Modelica.Blocks.Interfaces.RealOutput y "Output variable";
    equation
      y = k;
    end Const;

    block Prod_2 "Product of two influencing factors"
      Modelica.Blocks.Interfaces.RealInput u1 "First input variable";
      Modelica.Blocks.Interfaces.RealInput u2 "Second input variable";
      Modelica.Blocks.Interfaces.RealOutput y "Output variable";
    equation
      y = u1 * u2;
    end Prod_2;

    block Prod_3 "Product of three influencing factors"
      Modelica.Blocks.Interfaces.RealInput u1 "First input variable";
      Modelica.Blocks.Interfaces.RealInput u2 "Second input variable";
      Modelica.Blocks.Interfaces.RealInput u3 "Third input variable";
      Modelica.Blocks.Interfaces.RealOutput y "Output variable";
    equation
      y = u1 * u2 * u3;
    end Prod_3;

    block Prod_4 "Product of four influencing factors"
      Modelica.Blocks.Interfaces.RealInput u1 "First input variable";
      Modelica.Blocks.Interfaces.RealInput u2 "Second input variable";
      Modelica.Blocks.Interfaces.RealInput u3 "Third input variable";
      Modelica.Blocks.Interfaces.RealInput u4 "Fourth input variable";
      Modelica.Blocks.Interfaces.RealOutput y "Output variable";
    equation
      y = u1 * u2 * u3 * u4;
    end Prod_4;

    block Prod_5 "Product of five influencing factors"
      Modelica.Blocks.Interfaces.RealInput u1 "First input variable";
      Modelica.Blocks.Interfaces.RealInput u2 "Second input variable";
      Modelica.Blocks.Interfaces.RealInput u3 "Third input variable";
      Modelica.Blocks.Interfaces.RealInput u4 "Fourth input variable";
      Modelica.Blocks.Interfaces.RealInput u5 "Fifth input variable";
      Modelica.Blocks.Interfaces.RealOutput y "Output variable";
    equation
      y = u1 * u2 * u3 * u4 * u5;
    end Prod_5;
  end Auxiliary;

  package Functions "Functions of the System Dynamics methodology"
    extends Modelica.Icons.Library annotation(preferedView = "info", Documentation(info = "<html>
This package contains a number of standard functional relationships used in the System Dynamics methodology.
</html>"));

    block SMTH1 "First-order exponential smoothing"
      parameter Real averaging_time = 1 "Averaging time";
      parameter Real smooth_init = 0 "Initial value of smoothed variable";
      SystemDynamics.Levels.Level1a Smooth_of_Input(x0 = smooth_init);
      SystemDynamics.Rates.Rate_1 Change_in_Smooth;
      SystemDynamics.Sources.Source source;
      SystemDynamics.Functions.Utilities.Change_In_Smooth change_in_smooth(averaging_time = averaging_time);
      Modelica.Blocks.Interfaces.RealInput u "Input variable";
      Modelica.Blocks.Interfaces.RealOutput y "Output variable";
    equation
      connect(Change_in_Smooth.y1,Smooth_of_Input.u1);
      connect(source.MassInPort1,Change_in_Smooth.y);
      connect(change_in_smooth.y,Change_in_Smooth.u);
      connect(change_in_smooth.u2,Smooth_of_Input.y4);
      connect(change_in_smooth.u1,u);
      connect(y,Smooth_of_Input.y1);
    end SMTH1;

    block SMTH3 "Third-order exponential smoothing"
      parameter Real averaging_time = 1 "Averaging time";
      parameter Real smooth_init = 0 "Initial value of smoothed variable";
      SystemDynamics.Levels.Level1a Smooth1(x0 = smooth_init);
      SystemDynamics.Rates.Rate_1 Change_in_Smooth1;
      SystemDynamics.Sources.Source source;
      SystemDynamics.Functions.Utilities.Change_In_Smooth ch_in_smooth1(averaging_time = averaging_time / 3);
      Modelica.Blocks.Interfaces.RealInput u "Input variable";
      Modelica.Blocks.Interfaces.RealOutput y "Output variable";
      SystemDynamics.Levels.Level1a Smooth2(x0 = smooth_init);
      SystemDynamics.Rates.Rate_1 Change_in_Smooth2;
      SystemDynamics.Sources.Source source1;
      SystemDynamics.Functions.Utilities.Change_In_Smooth ch_in_smooth2(averaging_time = averaging_time / 3);
      SystemDynamics.Levels.Level1a Smooth3(x0 = smooth_init);
      SystemDynamics.Rates.Rate_1 Change_in_Smooth3;
      SystemDynamics.Sources.Source source2;
      SystemDynamics.Functions.Utilities.Change_In_Smooth ch_in_smooth3(averaging_time = averaging_time / 3);
    equation
      connect(Change_in_Smooth1.y1,Smooth1.u1);
      connect(source.MassInPort1,Change_in_Smooth1.y);
      connect(ch_in_smooth1.y,Change_in_Smooth1.u);
      connect(ch_in_smooth1.u2,Smooth1.y4);
      connect(Change_in_Smooth2.y1,Smooth2.u1);
      connect(source1.MassInPort1,Change_in_Smooth2.y);
      connect(ch_in_smooth2.y,Change_in_Smooth2.u);
      connect(ch_in_smooth2.u2,Smooth2.y4);
      connect(Change_in_Smooth3.y1,Smooth3.u1);
      connect(source2.MassInPort1,Change_in_Smooth3.y);
      connect(ch_in_smooth3.y,Change_in_Smooth3.u);
      connect(ch_in_smooth3.u2,Smooth3.y4);
      connect(u,ch_in_smooth1.u1);
      connect(ch_in_smooth2.u1,Smooth1.y3);
      connect(ch_in_smooth3.u1,Smooth2.y3);
      connect(y,Smooth3.y1);
    end SMTH3;

    block Tabular "Tabular function"
      parameter Real x_vals[:] = {0} "Independent variable data points";
      parameter Real y_vals[:] = {0} "Dependent variable data points";
      Modelica.Blocks.Interfaces.RealInput u "Input variable";
      Modelica.Blocks.Interfaces.RealOutput y "Output variable";
    equation
      y = Functions.Utilities.Piecewise(x=  u, x_grid=  x_vals, y_grid=  y_vals);
    end Tabular;

    package Utilities "Utility modules of the set of functions"
      extends Modelica.Icons.Library annotation(preferedView = "info", Documentation(info = "<html>
Utility models of the set of functions.
</html>"));

      block Change_In_Smooth "Smoothing rate"
        extends Interfaces.Nonlin_2;
        parameter Real averaging_time = 1 "Averaging time";
        output Real input_variable "Variable to be smoothed";
        output Real smooth_of_input "Smoothed variable";
        output Real smoothing_rate "Smoothing rate";
      equation
        input_variable = u1;
        smooth_of_input = u2;
        smoothing_rate = (input_variable - smooth_of_input) / averaging_time;
        y = smoothing_rate;
      end Change_In_Smooth;

      function Piecewise "Piecewise linear function"
        input Real x "Independent variable";
        input Real x_grid[:] "Independent variable data points";
        input Real y_grid[:] "Dependent variable data points";
        output Real y "Interpolated result";
    protected
        Integer n;
      algorithm
        n:=size(x_grid, 1);
        assert(size(x_grid, 1) == size(y_grid, 1), "Size mismatch");
        assert(x >= x_grid[1] and x <= x_grid[n], "Out of range");
        for i in 1:n - 1 loop
                  if x >= x_grid[i] and x <= x_grid[i + 1] then
            y:=y_grid[i] + (y_grid[i + 1] - y_grid[i]) * (x - x_grid[i]) / (x_grid[i + 1] - x_grid[i]);
          else

          end if;
        end for;
      end Piecewise;
    end Utilities;
  end Functions;

  package Levels "Levels of the System Dynamics methodology"
    extends Modelica.Icons.Library annotation(preferedView = "info", Documentation(info = "<html>
This package contains a set of different <b>Levels</b> (integrators of state variables) frequently used in the System Dynamics methodology.
</html>"));

    block Level "General System Dynamics level"
      parameter Real x0 = 0 "Initial condition";
      output Real level "Continuous state variable";
      Modelica.Blocks.Math.Add Add1(k2 = -1);
      Modelica.Blocks.Continuous.Integrator Integrator1(y_start = x0);
      SystemDynamics.Interfaces.MassInPort u1 "Inflow variable";
      SystemDynamics.Interfaces.MassInPort u2 "Outflow variable";
      SystemDynamics.Interfaces.MassOutPort y "State variable";
      SystemDynamics.Interfaces.MassOutPort y1 "State variable";
      SystemDynamics.Interfaces.MassOutPort y2 "State variable";
      SystemDynamics.Interfaces.MassOutPort y3 "State variable";
      SystemDynamics.Interfaces.MassOutPort y4 "State variable";
    equation
      level = y;
      connect(Add1.y,Integrator1.u);
      connect(y,Integrator1.y);
      connect(u1,Add1.u1);
      connect(u2,Add1.u2);
      connect(y1,Integrator1.y);
      connect(y2,Integrator1.y);
      connect(y3,Integrator1.y);
      connect(y4,Integrator1.y);
    end Level;

    block Level1a "General System Dynamics level with no outflow"
      parameter Real x0 = 0 "Initial condition";
      output Real level "Continuous state variable";
      Modelica.Blocks.Continuous.Integrator Integrator1(y_start = x0);
      SystemDynamics.Interfaces.MassInPort u1 "Inflow variable";
      SystemDynamics.Interfaces.MassOutPort y "State variable";
      SystemDynamics.Interfaces.MassOutPort y1 "State variable";
      SystemDynamics.Interfaces.MassOutPort y2 "State variable";
      SystemDynamics.Interfaces.MassOutPort y3 "State variable";
      SystemDynamics.Interfaces.MassOutPort y4 "State variable";
    equation
      level = y;
      connect(y1,Integrator1.y);
      connect(y2,Integrator1.y);
      connect(y3,Integrator1.y);
      connect(y4,Integrator1.y);
      connect(u1,Integrator1.u);
      connect(y1,y);
    end Level1a;

    block Level1b "General System Dynamics level with no inflow"
      parameter Real x0 = 0 "Initial condition";
      output Real level "Continuous state variable";
      Modelica.Blocks.Continuous.Integrator Integrator1(y_start = x0);
      SystemDynamics.Interfaces.MassInPort u1 "Outflow variable";
      SystemDynamics.Interfaces.MassOutPort y "State variable";
      SystemDynamics.Interfaces.MassOutPort y1 "State variable";
      SystemDynamics.Interfaces.MassOutPort y2 "State variable";
      SystemDynamics.Interfaces.MassOutPort y3 "State variable";
      SystemDynamics.Interfaces.MassOutPort y4 "State variable";
      Modelica.Blocks.Math.Gain Gain1(k = -1);
    equation
      level = y;
      connect(y,Integrator1.y);
      connect(y2,Integrator1.y);
      connect(y3,Integrator1.y);
      connect(y4,Integrator1.y);
      connect(y,y1);
      connect(u1,Gain1.u);
      connect(Gain1.y,Integrator1.u);
    end Level1b;

    block Level2b "General System Dynamics level with two outflows"
      parameter Real x0 = 0 "Initial condition";
      output Real level "Continuous state variable";
      Modelica.Blocks.Continuous.Integrator Integrator1(y_start = x0);
      SystemDynamics.Interfaces.MassInPort u1 "Inflow variable";
      SystemDynamics.Interfaces.MassInPort u2 "First outflow variable";
      SystemDynamics.Interfaces.MassInPort u3 "Second outflow variable";
      SystemDynamics.Interfaces.MassOutPort y "State variable";
      SystemDynamics.Interfaces.MassOutPort y1 "State variable";
      SystemDynamics.Interfaces.MassOutPort y2 "State variable";
      SystemDynamics.Interfaces.MassOutPort y3 "State variable";
      Modelica.Blocks.Math.Add3 Add1(k3 = -1, k1 = -1);
    equation
      level = y;
      connect(y,Integrator1.y);
      connect(y1,Integrator1.y);
      connect(y2,Integrator1.y);
      connect(y3,Integrator1.y);
      connect(Add1.y,Integrator1.u);
      connect(u1,Add1.u2);
      connect(u2,Add1.u1);
      connect(u3,Add1.u3);
    end Level2b;
  end Levels;

  package Rates "Rates of the System Dynamics methodology"
    extends Modelica.Icons.Library annotation(preferedView = "info", Documentation(info = "<html>
This package contains a set of different <b>Rates</b> (state derivative variables) frequently used in the System Dynamics methodology.
</html>"));

    block Rate_1 "Unrestricted rate element with one influencing variable"
      output Real rate;
      Modelica.Blocks.Interfaces.RealInput u "Signal inflow variable";
      SystemDynamics.Interfaces.MassOutPort y "Mass inflow variable";
      SystemDynamics.Interfaces.MassOutPort y1 "Mass outflow variable";
    equation
      rate = y;
      connect(y,y1);
      connect(y1,u);
    end Rate_1;

    block RRate "Restricted rate element"
      constant Real inf = Modelica.Constants.inf;
      parameter Real minFlow = 0 "Smallest allowed flow";
      parameter Real maxFlow = inf "Largest allowed flow";
      output Real rate;
      Modelica.Blocks.Interfaces.RealInput u "Signal inflow variable";
      SystemDynamics.Interfaces.MassOutPort y "Mass inflow variable";
      SystemDynamics.Interfaces.MassOutPort y1 "Mass outflow variable";
      Modelica.Blocks.Nonlinear.Limiter Limiter1(uMax = maxFlow, uMin = minFlow);
    equation
      rate = y;
      connect(y,y1);
      connect(u,Limiter1.u);
      connect(y1,Limiter1.y);
    end RRate;
  end Rates;

  package Sources "Sources and sinks of the System Dynamics methodology"
    extends Modelica.Icons.Library;

    block Source "This is the (dummy) source model of System Dynamics"
      SystemDynamics.Interfaces.MassInPort MassInPort1 "Outflow variable";
    end Source;

    block Sink "This is the (dummy) sink model of System Dynamics"
      SystemDynamics.Interfaces.MassInPort MassInPort1 "Inflow variable";
    end Sink;
  end Sources;

  package WorldDynamics "World models"
    extends Modelica.Icons.Example;

    package World3 "Meadows' World Model (2004 Edition)"
      extends Modelica.Icons.Example;

      block Arable_Land_Dynamics "Arable land dynamics"
        parameter Real arable_land_init(unit = "hectare") = 900000000.0
        "Initial arable land";
        parameter Real avg_life_land_norm(unit = "yr") = 1000
        "Normal life span of land";
        parameter Real inherent_land_fert(unit = "kg/(hectare.yr)") = 600
        "Inherent land fertility";
        parameter Real pot_arable_land_init(unit = "hectare") = 2300000000.0
        "Initial potential arable land";
        parameter Real pot_arable_land_tot(unit = "hectare") = 3200000000.0
        "Total potential arable land";
        parameter Real social_discount(unit = "1/yr") = 0.07 "Social discount";
        parameter Real t_land_life_time(unit = "yr") = 4000 "Land life time";
        parameter Real urban_ind_land_init(unit = "hectare") = 8200000.0
        "Initial urban and industrial land";
        parameter Real urb_ind_land_dev_time(unit = "yr") = 10
        "Urban and industrial land development time";
        SystemDynamics.Rates.RRate Land_Devel_Rt
        "p.289 of Dynamics of Growth in a Finite World";
        SystemDynamics.Levels.Level2b Arable_Land(x0 = arable_land_init)
        "p.279 of Dynamics of Growth in a Finite World";
        SystemDynamics.Rates.RRate Land_Rem_Urb_Ind_Use
        "p.322 of Dynamics of Growth in a Finite World";
        SystemDynamics.Rates.RRate Land_Erosion_Rt
        "p.318 of Dynamics of Growth in a Finite World";
        SystemDynamics.Sources.Sink sink;
        SystemDynamics.Levels.Level1b Pot_Arable_Land(x0 = pot_arable_land_init)
        "p.279 of Dynamics of Growth in a Finite World";
        SystemDynamics.Levels.Level1a Urban_Ind_Land(x0 = urban_ind_land_init)
        "p.322 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.Land_Devel_Rt Land_Dev_Rt
        "p.289 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.Land_Rem_Urb_Ind_Use Land_Rem_UI_Use(urb_ind_land_dev_time = urb_ind_land_dev_time)
        "p.322 of Dynamics of Growth in a Finite World";
        Modelica.Blocks.Math.Division Land_Er_Rt
        "p.318 of Dynamics of Growth in a Finite World";
        Modelica.Blocks.Math.Gain Avg_Life_Land(k = avg_life_land_norm)
        "p.316 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Dev_Cost_Per_Hect(x_vals=  0.0:0.1:1.0, y_vals = {100000,7400,5200,3500,2400,1500,750,300,150,75,50})
        "p.291 of Dynamics of Growth in a Finite World";
        Modelica.Blocks.Math.Gain Gain1(k = 1 / pot_arable_land_tot)
        "p.291 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.Marg_Prod_Land_Dev Marg_Prod_Land_Dev(social_discount = social_discount)
        "p.312 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Fr_Inp_Al_Land_Dev(x_vals=  0.0:0.25:2.0, y_vals = {0.0,0.05,0.15,0.3,0.5,0.7,0.85,0.95,1.0})
        "p.311 of Dynamics of Growth in a Finite World";
        Modelica.Blocks.Math.Division Div1
        "p.311 of Dynamics of Growth in a Finite World";
        Modelica.Blocks.Math.Gain Land_Fr_Cult(k = 1 / pot_arable_land_tot)
        "p.278 of Dynamics of Growth in a Finite World";
        SystemDynamics.Auxiliary.Prod_2 Urb_Ind_Land_Req
        "p.321 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Urb_Ind_Land_PC(x_vals=  0:200:1600, y_vals = {0.005,0.008,0.015,0.025,0.04,0.055,0.07,0.08,0.09})
        "p.321 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.S_Land_Life_Mlt_Yield S_Land_Life_Mlt_Yield(t_land_life_time = t_land_life_time)
        "p.317 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular P_Land_Life_Mlt_Yield_1(y_vals = {1.2,1.0,0.63,0.36,0.16,0.055,0.04,0.025,0.015,0.01,0.01}, x_vals = {0,1,2,3,4,5,6,7,8,9,50})
        "p.317 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular P_Land_Life_Mlt_Yield_2(y_vals = {1.2,1.0,0.63,0.36,0.29,0.26,0.24,0.22,0.21,0.2,0.2}, x_vals = {0,1,2,3,4,5,6,7,8,9,50})
        "p.318 of Dynamics of Growth in a Finite World";
        Modelica.Blocks.Math.Gain Gain2(k = 1 / inherent_land_fert)
        "p.317 of Dynamics of Growth in a Finite World";
        SystemDynamics.Interfaces.MassInPort land_yield(unit = "kg/(hectare.yr)")
        "Land yield";
        SystemDynamics.Interfaces.MassInPort marg_prod_agr_inp(unit = "kg/dollar")
        "Development of marginally producing land";
        SystemDynamics.Interfaces.MassInPort population "Population";
        SystemDynamics.Interfaces.MassInPort ind_out_pc
        "Per capita annual industrial output";
        SystemDynamics.Interfaces.MassInPort tot_agric_invest(unit = "dollar/yr")
        "Total investment in the agricultural sector";
        SystemDynamics.Interfaces.MassOutPort arable_land(unit = "hectare")
        "Arable land";
        SystemDynamics.Interfaces.MassOutPort urban_ind_land(unit = "hectare")
        "Land occupied by human dwellings and industry";
        SystemDynamics.Interfaces.MassOutPort fr_inp_al_land_dev
        "Fraction of capital invested in agriculture allocated to the devlopment of arable land";
      equation
        connect(Fr_Inp_Al_Land_Dev.y,fr_inp_al_land_dev);
        connect(Fr_Inp_Al_Land_Dev.u,Div1.y);
        connect(Fr_Inp_Al_Land_Dev.y,Land_Dev_Rt.u2);
        connect(Div1.u2,marg_prod_agr_inp);
        connect(Marg_Prod_Land_Dev.y,Div1.u1);
        connect(Marg_Prod_Land_Dev.u1,land_yield);
        connect(Dev_Cost_Per_Hect.y,Marg_Prod_Land_Dev.u2);
        connect(Gain1.y,Dev_Cost_Per_Hect.u);
        connect(Dev_Cost_Per_Hect.y,Land_Dev_Rt.u1);
        connect(Gain1.u,Pot_Arable_Land.y);
        connect(Land_Fr_Cult.u,Arable_Land.y);
        connect(arable_land,Arable_Land.y1);
        connect(Land_Er_Rt.u1,Arable_Land.y2);
        connect(Land_Rem_Urb_Ind_Use.y,Arable_Land.u2);
        connect(Land_Erosion_Rt.y,Arable_Land.u3);
        connect(Land_Devel_Rt.y1,Arable_Land.u1);
        connect(Land_Dev_Rt.y,Land_Devel_Rt.u);
        connect(Pot_Arable_Land.u1,Land_Devel_Rt.y);
        connect(P_Land_Life_Mlt_Yield_1.y,S_Land_Life_Mlt_Yield.u1);
        connect(P_Land_Life_Mlt_Yield_2.y,S_Land_Life_Mlt_Yield.u2);
        connect(Gain2.u,land_yield);
        connect(Gain2.y,P_Land_Life_Mlt_Yield_2.u);
        connect(Gain2.y,P_Land_Life_Mlt_Yield_1.u);
        connect(S_Land_Life_Mlt_Yield.y,Avg_Life_Land.u);
        connect(Urb_Ind_Land_PC.u,ind_out_pc);
        connect(Urb_Ind_Land_PC.y,Urb_Ind_Land_Req.u1);
        connect(Urb_Ind_Land_Req.u2,population);
        connect(Urb_Ind_Land_Req.y,Land_Rem_UI_Use.u1);
        connect(sink.MassInPort1,Land_Erosion_Rt.y1);
        connect(Land_Er_Rt.u2,Avg_Life_Land.y);
        connect(urban_ind_land,Urban_Ind_Land.y2);
        connect(Land_Rem_UI_Use.u2,Urban_Ind_Land.y4);
        connect(Urban_Ind_Land.u1,Land_Rem_Urb_Ind_Use.y1);
        connect(Land_Rem_UI_Use.y,Land_Rem_Urb_Ind_Use.u);
        connect(Land_Er_Rt.y,Land_Erosion_Rt.u);
        connect(tot_agric_invest,Land_Dev_Rt.u3);
      end Arable_Land_Dynamics;

      block Food_Production "Food production"
        parameter Real agr_inp_init(unit = "dollar/yr") = 5000000000.0
        "Initial agricultural input";
        parameter Real food_short_perc_del(unit = "yr") = 2
        "Food shortage perception delay";
        parameter Real land_fr_harvested = 0.7 "Land fraction harvested";
        parameter Real p_avg_life_agr_inp_1(unit = "yr") = 2
        "Default average life of agricultural input";
        parameter Real p_avg_life_agr_inp_2(unit = "yr") = 2
        "Controlled average life of agricultural input";
        parameter Real p_land_yield_fact_1 = 1 "Default land yield factor";
        parameter Real perc_food_ratio_init = 1 "Initial perceived food ratio";
        parameter Real processing_loss = 0.1 "Processing loss";
        parameter Real subsist_food_pc(unit = "kg/yr") = 230
        "Available per capita food";
        parameter Real t_policy_year(unit = "yr") = 4000
        "Year of policy change";
        parameter Real tech_dev_del_TDD(unit = "yr") = 20
        "Technology development time";
        SystemDynamics.Interfaces.MassInPort ind_out_pc(unit = "dollar/yr")
        "Per capita annual industrial output";
        SystemDynamics.Functions.Tabular P_Indic_Food_PC_1(x_vals=  0:200:1600, y_vals = {230,480,690,850,970,1070,1150,1210,1250})
        "p.286 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular P_Indic_Food_PC_2(x_vals=  0:200:1600, y_vals = {230,480,690,850,970,1070,1150,1210,1250})
        "p.286 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.S_Indic_Food_PC S_Indic_Food_PC(t_policy_year = t_policy_year)
        "p.286 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular P_Fr_IO_Al_Agr_1(x_vals=  0:0.5:2.5, y_vals = {0.4,0.2,0.1,0.025,0,0})
        "p.287 of Dynamics of Growth in a Finite World";
        Modelica.Blocks.Math.Division Div1;
        SystemDynamics.Functions.Tabular P_Fr_IO_Al_Agr_2(x_vals=  0:0.5:2.5, y_vals = {0.4,0.2,0.1,0.025,0,0})
        "p.287 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.S_FIOA_Agr S_FIOA_Agr(t_policy_year = t_policy_year)
        "p.287 of Dynamics of Growth in a Finite World";
        SystemDynamics.Auxiliary.Prod_2 Tot_Agric_Invest
        "p.287 of Dynamics of Growth in a Finite World";
        SystemDynamics.Interfaces.MassInPort industrial_output(unit = "dollar/yr")
        "Annual industrial output";
        SystemDynamics.Sources.Source Source1;
        SystemDynamics.Rates.Rate_1 Chg_Agr_Inp;
        SystemDynamics.Levels.Level1a Agr_Inp(x0 = agr_inp_init);
        SystemDynamics.WorldDynamics.World3.Utilities.Ch_Agr_Inp Ch_Agr_Inp
        "p.292 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.Current_Agr_Inp Current_Agr_Inp
        "p.292 of Dynamics of Growth in a Finite World";
        SystemDynamics.Interfaces.MassInPort fr_inp_al_land_dev
        "Fraction of capital invested in agriculture allocated to the devlopment of arable land";
        SystemDynamics.WorldDynamics.World3.Utilities.S_Avg_Life_Agr_Inp S_Avg_Life_Agr_Inp(t_policy_year = t_policy_year, p_avg_life_agr_inp_1 = p_avg_life_agr_inp_1, p_avg_life_agr_inp_2 = p_avg_life_agr_inp_2)
        "p.293 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular P_Fr_Inp_For_Land_Maint(x_vals = 0:4, y_vals = {0,0.04,0.07,0.09,0.1})
        "p.332 of Dynamics of Growth in a Finite World";
        SystemDynamics.Sources.Source Source2;
        SystemDynamics.Rates.Rate_1 Chg_Perc_Food_Ratio;
        SystemDynamics.Levels.Level1a Perc_Food_Ratio(x0 = perc_food_ratio_init);
        SystemDynamics.WorldDynamics.World3.Utilities.Agr_Inp_Per_Hect Agr_Inp_Per_Hect
        "p.294 of Dynamics of Growth in a Finite World";
        SystemDynamics.Interfaces.MassInPort arable_land(unit = "hectare")
        "Arable land";
        SystemDynamics.Functions.Tabular Marg_Land_Yield_Mlt_Cap(y_vals = {0.075,0.03,0.015,0.011,0.009,0.008,0.007,0.006,0.005,0.005,0.005,0.005,0.005,0.005,0.005,0.005,0.005}, x_vals = {0,40,80,120,160,200,240,280,320,360,400,440,480,520,560,600,10000})
        "p.313 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Land_Yield_Mlt_Cap(y_vals = {1,3,4.5,5,5.3,5.6,5.9,6.1,6.35,6.6,6.9,7.2,7.4,7.6,7.8,8,8.2,8.4,8.6,8.8,9,9.2,9.4,9.6,9.8,10,10}, x_vals = {0,40,80,120,160,200,240,280,320,360,400,440,480,520,560,600,640,680,720,760,800,840,880,920,960,1000,10000})
        "p.306 of Dynamics of Growth in a Finite World";
        SystemDynamics.Auxiliary.Prod_4 Land_Yield
        "p.307 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.Marg_Prod_Agr_Inp Marg_Prod_Agr_Inp
        "p.313 of Dynamics of Growth in a Finite World";
        SystemDynamics.Interfaces.MassOutPort marg_prod_agr_inp(unit = "kg/dollar")
        "Development of marginally producing land";
        SystemDynamics.Interfaces.MassOutPort land_yield(unit = "kg/(hectare.yr)")
        "Land yield";
        SystemDynamics.WorldDynamics.World3.Utilities.Food Food(land_fr_harvested = land_fr_harvested, processing_loss = processing_loss)
        "p.280 of Dynamics of Growth in a Finite World";
        Modelica.Blocks.Math.Division Food_PC
        "p.281 of Dynamics of Growth in a Finite World";
        SystemDynamics.Interfaces.MassInPort population "Population";
        Modelica.Blocks.Math.Gain Food_Ratio(k = 1 / subsist_food_pc)
        "p.332 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.Ch_Perc_Food_Ratio Ch_Perc_Food_Ratio(food_short_perc_del = food_short_perc_del)
        "p.333 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.S_Land_Yield_Fact S_Land_Yield_Fact(t_policy_year = t_policy_year, p_land_yield_fact_1 = p_land_yield_fact_1)
        "p.307 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.SMTH3 P_Land_Yield_Fact_2(averaging_time(unit = "yr") = tech_dev_del_TDD);
        SystemDynamics.Interfaces.MassInPort yield_tech_LYTD
        "Technology induced absolute yield enhancement";
        SystemDynamics.Interfaces.MassInPort land_fertility(unit = "kg/(hectare.yr)")
        "Land fertility";
        SystemDynamics.Interfaces.MassInPort s_yield_mlt_air_poll
        "Land yield multiplier from air pollution";
        SystemDynamics.Interfaces.MassOutPort food_ratio "Food ratio";
        SystemDynamics.Interfaces.MassOutPort tot_agric_invest(unit = "dollar/yr")
        "Total investment in the agricultural sector";
        SystemDynamics.Interfaces.MassOutPort agr_inp_per_hect(unit = "dollar/(hectare.yr)")
        "Agricultural investments per hectare";
        SystemDynamics.Interfaces.MassOutPort s_fioa_agr
        "Fraction of total investments allocated to the agricultural sector";
        SystemDynamics.Interfaces.MassOutPort p_fr_inp_for_land_maint
        "Fraction of investments in the agricultural sector allocated to land maintenance";
        SystemDynamics.Functions.Tabular Yield_Tech_Mult_Icor_COYM(y_vals = {1,1,1.05,1.12,1.25,1.35,1.5,1.5}, x_vals = {0,1,1.2,1.4,1.6,1.8,2,50});
        SystemDynamics.Interfaces.MassOutPort yield_tech_mult_icor_COYM
        "Technology induced relative enhancement of land yield";
        SystemDynamics.Interfaces.MassOutPort food_pc(unit = "kg/yr")
        "Per capita annually consumed food";
      equation
        connect(Marg_Prod_Agr_Inp.y,marg_prod_agr_inp);
        connect(S_FIOA_Agr.u1,P_Fr_IO_Al_Agr_1.y);
        connect(S_FIOA_Agr.u2,P_Fr_IO_Al_Agr_2.y);
        connect(S_Indic_Food_PC.u2,P_Indic_Food_PC_2.y);
        connect(S_Indic_Food_PC.u1,P_Indic_Food_PC_1.y);
        connect(Tot_Agric_Invest.y,Current_Agr_Inp.u2);
        connect(Current_Agr_Inp.u1,fr_inp_al_land_dev);
        connect(Ch_Agr_Inp.u3,Agr_Inp.y4);
        connect(Agr_Inp_Per_Hect.u3,Agr_Inp.y);
        connect(Marg_Land_Yield_Mlt_Cap.u,Agr_Inp_Per_Hect.y);
        connect(Land_Yield_Mlt_Cap.u,Agr_Inp_Per_Hect.y);
        connect(arable_land,Agr_Inp_Per_Hect.u2);
        connect(Agr_Inp_Per_Hect.u1,P_Fr_Inp_For_Land_Maint.y);
        connect(S_FIOA_Agr.y,s_fioa_agr);
        connect(Tot_Agric_Invest.u1,S_FIOA_Agr.y);
        connect(P_Fr_IO_Al_Agr_2.u,Div1.y);
        connect(P_Fr_IO_Al_Agr_1.u,Div1.y);
        connect(Div1.u2,S_Indic_Food_PC.y);
        connect(P_Indic_Food_PC_2.u,ind_out_pc);
        connect(P_Indic_Food_PC_1.u,ind_out_pc);
        connect(S_Avg_Life_Agr_Inp.y,Marg_Prod_Agr_Inp.u4);
        connect(S_Avg_Life_Agr_Inp.y,Ch_Agr_Inp.u2);
        connect(Current_Agr_Inp.y,Ch_Agr_Inp.u1);
        connect(Ch_Agr_Inp.y,Chg_Agr_Inp.u);
        connect(Source1.MassInPort1,Chg_Agr_Inp.y);
        connect(Chg_Agr_Inp.y1,Agr_Inp.u1);
        connect(Marg_Land_Yield_Mlt_Cap.u,agr_inp_per_hect);
        connect(Marg_Land_Yield_Mlt_Cap.y,Marg_Prod_Agr_Inp.u3);
        connect(Land_Yield.y,Marg_Prod_Agr_Inp.u1);
        connect(Land_Yield_Mlt_Cap.y,Marg_Prod_Agr_Inp.u2);
        connect(Land_Yield.u3,s_yield_mlt_air_poll);
        connect(Land_Yield.u2,land_fertility);
        connect(Ch_Perc_Food_Ratio.y,Chg_Perc_Food_Ratio.u);
        connect(Perc_Food_Ratio.y1,Ch_Perc_Food_Ratio.u2);
        connect(Food_Ratio.y,Ch_Perc_Food_Ratio.u1);
        connect(P_Fr_Inp_For_Land_Maint.u,Perc_Food_Ratio.y);
        connect(Chg_Perc_Food_Ratio.y1,Perc_Food_Ratio.u1);
        connect(Land_Yield.y,Food.u1);
        connect(Food.u2,arable_land);
        connect(Land_Yield.u4,Land_Yield_Mlt_Cap.y);
        connect(S_Land_Yield_Fact.y,Land_Yield.u1);
        connect(Land_Yield.y,land_yield);
        connect(P_Land_Yield_Fact_2.u,yield_tech_LYTD);
        connect(P_Land_Yield_Fact_2.y,S_Land_Yield_Fact.u);
        connect(S_Land_Yield_Fact.y,Yield_Tech_Mult_Icor_COYM.u);
        connect(Yield_Tech_Mult_Icor_COYM.y,yield_tech_mult_icor_COYM);
        connect(P_Fr_Inp_For_Land_Maint.y,p_fr_inp_for_land_maint);
        connect(Source2.MassInPort1,Chg_Perc_Food_Ratio.y);
        connect(Food_Ratio.y,food_ratio);
        connect(Food_Ratio.u,Food_PC.y);
        connect(Food_PC.u1,Food.y);
        connect(Tot_Agric_Invest.u2,industrial_output);
        connect(population,Food_PC.u2);
        connect(Food_PC.y,Div1.u1);
        connect(Food_PC.y,food_pc);
        connect(Tot_Agric_Invest.y,tot_agric_invest);
      end Food_Production;

      block Human_Ecological_Footprint "Ecological footprint"
        SystemDynamics.Interfaces.MassInPort urban_ind_land(unit = "hectare")
        "Land occupied by human dwellings and industry";
        SystemDynamics.Interfaces.MassInPort arable_land(unit = "hectare")
        "Arable land";
        SystemDynamics.Interfaces.MassInPort ppoll_gen_rt(unit = "1/yr")
        "Persistent pollution generation rate";
        Modelica.Blocks.Math.Gain Arable_Land_In_Gha(k = 0.000000001);
        Modelica.Blocks.Math.Gain Urban_Land_In_Gha(k = 0.000000001);
        SystemDynamics.Auxiliary.Prod_2 Absorption_Land_In_Gha;
        SystemDynamics.Auxiliary.Const Gha_Per_Unit_Of_Pollution(k = 0.000000004);
        SystemDynamics.WorldDynamics.World3.Utilities.HEF_Human_Ecological_Footprint
                                                                                     HEF_Human_Ecological_Footprint;
        SystemDynamics.Interfaces.MassOutPort hef_human_ecological_footprint(unit = "hectare")
        "Ecological footprint";
      equation
        connect(Gha_Per_Unit_Of_Pollution.y,Absorption_Land_In_Gha.u2);
        connect(Absorption_Land_In_Gha.y,HEF_Human_Ecological_Footprint.u3);
        connect(Absorption_Land_In_Gha.u1,ppoll_gen_rt);
        connect(Urban_Land_In_Gha.y,HEF_Human_Ecological_Footprint.u2);
        connect(Urban_Land_In_Gha.u,urban_ind_land);
        connect(Arable_Land_In_Gha.y,HEF_Human_Ecological_Footprint.u1);
        connect(arable_land,Arable_Land_In_Gha.u);
        connect(HEF_Human_Ecological_Footprint.y,hef_human_ecological_footprint);
      end Human_Ecological_Footprint;

      block Human_Fertility "Human fertility"
        parameter Real des_compl_fam_size_norm = 3.8
        "Desired normal complete family size";
        parameter Real hlth_serv_impact_del(unit = "yr") = 20
        "Health service impact delay";
        parameter Real income_expect_avg_time(unit = "yr") = 3
        "Income expected average time";
        parameter Real lifet_perc_del(unit = "yr") = 20
        "Perceived life-time delay";
        parameter Real max_tot_fert_norm = 12 "Normal maximal total fertility";
        parameter Real social_adj_del(unit = "yr") = 20
        "Social adjustment delay";
        parameter Real t_fert_cont_eff_time(unit = "yr") = 4000
        "Year of continued fertility change";
        parameter Real t_zero_pop_grow_time(unit = "yr") = 4000
        "Time to zero population growth";
        SystemDynamics.Interfaces.MassInPort ind_out_pc(unit = "dollar/yr")
        "Per capita annual industrial output";
        SystemDynamics.Functions.SMTH1 Avg_Ind_Out_PC(averaging_time(unit = "yr") = income_expect_avg_time, smooth_init(unit = "dollar/yr") = 43.3)
        "p.122 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.Fam_Income_Expect Fam_Income_Expect
        "p.122 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Fam_Resp_To_Soc_Norm(x_vals=  (-0.2):0.1:0.2, y_vals = {0.5,0.6,0.7,0.85,1})
        "p.122 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.SMTH3 Del_Ind_Out_PC(averaging_time(unit = "yr") = social_adj_del, smooth_init(unit = "dollar/yr") = 0)
        "p.119 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Soc_Fam_Size_Norm(x_vals=  0:200:800, y_vals = {1.25,0.94,0.715,0.59,0.5})
        "p.119 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.Des_Compl_Fam_Size Des_Compl_Fam_Size(t_zero_pop_grow_time = t_zero_pop_grow_time, des_compl_fam_size_norm = des_compl_fam_size_norm)
        "p.113 of Dynamics of Growth in a Finite World";
        SystemDynamics.Interfaces.MassInPort life_expectancy(unit = "yr")
        "Average life expectancy of human population";
        SystemDynamics.Functions.SMTH3 Perc_Life_Expectancy(averaging_time(unit = "yr") = lifet_perc_del, smooth_init(unit = "yr") = 0)
        "p.112 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Compl_Mlt_Perc_Lifet(x_vals=  0:10:90, y_vals = {3,2.1,1.6,1.4,1.3,1.2,1.1,1.05,1,1})
        "p.112 of Dynamics of Growth in a Finite World";
        SystemDynamics.Auxiliary.Prod_2 Des_Tot_Fert
        "p.107 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Fecundity_Mult(x_vals=  0:10:90, y_vals = {0,0.2,0.4,0.6,0.7,0.75,0.79,0.84,0.87,0.87})
        "p.104 of Dynamics of Growth in a Finite World";
        Modelica.Blocks.Math.Gain Max_Tot_Fert(k = max_tot_fert_norm)
        "p.104 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.Need_For_Fert_Cont Need_For_Fert_Cont
        "p.131 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Fr_Serv_Al_Fert_Cont(x_vals=  0:2:10, y_vals = {0,0.005,0.015,0.025,0.03,0.035})
        "p.132 of Dynamics of Growth in a Finite World";
        SystemDynamics.Interfaces.MassInPort serv_out_pc(unit = "dollar/yr")
        "Per capita annual expenditure in services";
        SystemDynamics.Auxiliary.Prod_2 Fert_Cont_Al_PC
        "p.132 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.SMTH3 Fert_Cont_Facil_PC(averaging_time(unit = "yr") = hlth_serv_impact_del, smooth_init(unit = "dollar/yr") = 0)
        "p.133 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Fert_Cont_Eff_Table(y_vals = {0.75,0.85,0.9,0.95,0.98,0.99,1,1}, x_vals = {0,0.5,1,1.5,2,2.5,3,15})
        "p.133 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.Fert_Cont_Eff Fert_Cont_Eff(t_fert_cont_eff_time = t_fert_cont_eff_time)
        "p.133 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.Total_Fertility Total_Fertility
        "p.97 of Dynamics of Growth in a Finite World";
        SystemDynamics.Interfaces.MassOutPort total_fertility
        "Average human fertility";
      equation
        connect(Fam_Income_Expect.u1,ind_out_pc);
        connect(Des_Compl_Fam_Size.u2,Fam_Resp_To_Soc_Norm.y);
        connect(Fam_Resp_To_Soc_Norm.u,Fam_Income_Expect.y);
        connect(Fam_Income_Expect.u2,Avg_Ind_Out_PC.y);
        connect(Max_Tot_Fert.u,Fecundity_Mult.y);
        connect(Fecundity_Mult.u,life_expectancy);
        connect(Fr_Serv_Al_Fert_Cont.y,Fert_Cont_Al_PC.u2);
        connect(Fr_Serv_Al_Fert_Cont.u,Need_For_Fert_Cont.y);
        connect(Need_For_Fert_Cont.u1,Max_Tot_Fert.y);
        connect(Des_Tot_Fert.y,Need_For_Fert_Cont.u2);
        connect(Soc_Fam_Size_Norm.y,Des_Compl_Fam_Size.u1);
        connect(Des_Compl_Fam_Size.y,Des_Tot_Fert.u2);
        connect(Soc_Fam_Size_Norm.u,Del_Ind_Out_PC.y);
        connect(Compl_Mlt_Perc_Lifet.y,Des_Tot_Fert.u1);
        connect(Compl_Mlt_Perc_Lifet.u,Perc_Life_Expectancy.y);
        connect(Avg_Ind_Out_PC.u,ind_out_pc);
        connect(Del_Ind_Out_PC.u,ind_out_pc);
        connect(Perc_Life_Expectancy.u,life_expectancy);
        connect(Max_Tot_Fert.y,Total_Fertility.u2);
        connect(Des_Tot_Fert.y,Total_Fertility.u3);
        connect(Fert_Cont_Eff.y,Total_Fertility.u1);
        connect(Total_Fertility.y,total_fertility);
        connect(Fert_Cont_Eff.u,Fert_Cont_Eff_Table.y);
        connect(Fert_Cont_Eff_Table.u,Fert_Cont_Facil_PC.y);
        connect(Fert_Cont_Facil_PC.u,Fert_Cont_Al_PC.y);
        connect(Fert_Cont_Al_PC.u1,serv_out_pc);
      end Human_Fertility;

      block Human_Welfare_Index "Human welfare index"
        SystemDynamics.Interfaces.MassInPort life_expectancy(unit = "yr")
        "Average life expectancy of human population";
        SystemDynamics.Interfaces.MassInPort ind_out_pc(unit = "dollar/yr")
        "Per capita annual industrial output";
        SystemDynamics.Functions.Tabular Life_Expectancy_Index(x_vals = {0,25,35,45,55,65,75,85,95}, y_vals = {0,0,0.16,0.33,0.5,0.67,0.84,1,1});
        SystemDynamics.Functions.Tabular GDP_Per_Capita(x_vals=  0:200:1000, y_vals = {120,600,1200,1800,2500,3200});
        SystemDynamics.Functions.Tabular Education_Index(x_vals=  0:1000:7000, y_vals = {0,0.81,0.88,0.92,0.95,0.98,0.99,1});
        SystemDynamics.WorldDynamics.World3.Utilities.GDP_Index GDP_Index;
        SystemDynamics.WorldDynamics.World3.Utilities.HWI_Human_Welfare_Index HWI_Human_Welfare_Index;
        SystemDynamics.Interfaces.MassOutPort hwi_human_welfare_index
        "Human welfare index";
      equation
        connect(Education_Index.y,HWI_Human_Welfare_Index.u2);
        connect(GDP_Per_Capita.y,Education_Index.u);
        connect(GDP_Index.u,GDP_Per_Capita.y);
        connect(GDP_Per_Capita.u,ind_out_pc);
        connect(Life_Expectancy_Index.y,HWI_Human_Welfare_Index.u1);
        connect(Life_Expectancy_Index.u,life_expectancy);
        connect(GDP_Index.y,HWI_Human_Welfare_Index.u3);
        connect(HWI_Human_Welfare_Index.y,hwi_human_welfare_index);
      end Human_Welfare_Index;

      block Industrial_Investment
      "Investments in the military/industrial sector"
        parameter Real industrial_capital_init(unit = "dollar") = 210000000000.0
        "Initial industrial investment";
        parameter Real ind_out_pc_des(unit = "dollar/yr") = 400
        "Desired annual industrial per capita output";
        parameter Real p_avg_life_ind_cap_1(unit = "yr") = 14
        "Default average life of industrial capital";
        parameter Real p_avg_life_ind_cap_2(unit = "yr") = 14
        "Controlled average life of industrial capital";
        parameter Real p_fioa_cons_const_1 = 0.43
        "Default fraction of industrial output allocated to consumption";
        parameter Real p_fioa_cons_const_2 = 0.43
        "Controlled fraction of industrial output allocated to consumption";
        parameter Real p_ind_cap_out_ratio_1(unit = "yr") = 3
        "Default industrial capital output ratio";
        parameter Real t_ind_equil_time(unit = "yr") = 4000
        "Year of industrial equilibrium";
        parameter Real t_policy_year(unit = "yr") = 4000
        "Year of policy change";
        SystemDynamics.Levels.Level Industrial_Capital(x0 = industrial_capital_init)
        "p.218 of Dynamics of Growth in a Finite World";
        SystemDynamics.Rates.RRate Ind_Cap_Invest
        "p.222 of Dynamics of Growth in a Finite World";
        SystemDynamics.Rates.RRate Ind_Cap_Deprec
        "p.221 of Dynamics of Growth in a Finite World";
        SystemDynamics.Auxiliary.Prod_2 Ind_Cap_Inv
        "p.222 of Dynamics of Growth in a Finite World";
        Modelica.Blocks.Math.Division Ind_Cap_Dep
        "p.221 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.Industrial_Output Industrial_Output
        "p.216 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.S_Ind_Cap_Out_Ratio S_Ind_Cap_Out_Ratio(t_policy_year = t_policy_year, p_ind_cap_out_ratio_1 = p_ind_cap_out_ratio_1)
        "p.216 of Dynamics of Growth in a Finite World";
        SystemDynamics.Auxiliary.Prod_3 P_Ind_Cap_Out_Ratio_2;
        SystemDynamics.WorldDynamics.World3.Utilities.S_Avg_Life_Ind_Cap S_Avg_Life_Ind_Cap(t_policy_year = t_policy_year, p_avg_life_ind_cap_1 = p_avg_life_ind_cap_1, p_avg_life_ind_cap_2 = p_avg_life_ind_cap_2)
        "p.221 of Dynamics of Growth in a Finite World";
        SystemDynamics.Sources.Source Source1;
        SystemDynamics.Sources.Sink Sink1;
        SystemDynamics.WorldDynamics.World3.Utilities.FIOA_Ind FIOA_Ind
        "p.223 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.S_FIOA_Cons S_FIOA_Cons(t_ind_equil_time = t_ind_equil_time)
        "p.223 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.S_FIOA_Cons_Const S_FIOA_Cons_Const(p_fioa_cons_const_1 = p_fioa_cons_const_1, p_fioa_cons_const_2 = p_fioa_cons_const_2, t_policy_year = t_policy_year)
        "p.223 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular P_FIOA_Cons_Var(x_vals=  0:0.2:2, y_vals = {0.3,0.32,0.34,0.36,0.38,0.43,0.73,0.77,0.81,0.82,0.83})
        "p.225 of Dynamics of Growth in a Finite World";
        Modelica.Blocks.Math.Gain Gain1(k = 1 / ind_out_pc_des);
        Modelica.Blocks.Math.Division Ind_Out_PC
        "p.214 of Dynamics of Growth in a Finite World";
        SystemDynamics.Interfaces.MassInPort population "Population";
        SystemDynamics.Interfaces.MassInPort s_fioa_serv
        "Fraction of total investments allocated to the service sector";
        SystemDynamics.Interfaces.MassInPort s_fioa_agr
        "Fraction of total investments allocated to the agricultural sector";
        SystemDynamics.Interfaces.MassInPort s_fr_cap_al_obt_res
        "Fraction of capital allocated to resource use efficiency";
        SystemDynamics.Interfaces.MassInPort capital_util_fr
        "Capital utilization fraction";
        SystemDynamics.Interfaces.MassInPort ppoll_tech_mult_icor_COPM
        "Technology induced reduction in persistent pollution release";
        SystemDynamics.Interfaces.MassInPort yield_tech_mult_icor_COYM
        "Technology induced relative enhancement of land yield";
        SystemDynamics.Interfaces.MassInPort ind_cap_out_ratio_2_ICOR2T
        "Industrial capital output ratio";
        SystemDynamics.Interfaces.MassOutPort industrial_output(unit = "dollar/yr")
        "Annual industrial output";
        SystemDynamics.Interfaces.MassOutPort industrial_capital(unit = "dollar")
        "Total capital invested in the military/industrial sector";
        SystemDynamics.Interfaces.MassOutPort ind_out_pc(unit = "dollar/yr")
        "Per capita annual industrial output";
        SystemDynamics.Auxiliary.Prod_2 Cons_Ind_Out;
        Modelica.Blocks.Math.Division Cons_Ind_Out_PC;
        SystemDynamics.Interfaces.MassOutPort cons_ind_out_pc1(unit = "dollar/yr")
        "Per capita general industrial output";
      equation
        connect(P_FIOA_Cons_Var.y,S_FIOA_Cons.u2);
        connect(S_FIOA_Cons_Const.y,S_FIOA_Cons.u1);
        connect(FIOA_Ind.u1,s_fioa_agr);
        connect(FIOA_Ind.u3,S_FIOA_Cons.y);
        connect(industrial_capital,Industrial_Capital.y2);
        connect(Industrial_Output.u4,Industrial_Capital.y1);
        connect(S_Ind_Cap_Out_Ratio.y,Industrial_Output.u3);
        connect(Industrial_Output.u2,capital_util_fr);
        connect(Industrial_Output.u1,s_fr_cap_al_obt_res);
        connect(Cons_Ind_Out.y,Cons_Ind_Out_PC.u1);
        connect(Ind_Out_PC.u2,Cons_Ind_Out_PC.u2);
        connect(Ind_Cap_Dep.u2,S_Avg_Life_Ind_Cap.y);
        connect(Ind_Out_PC.y,Gain1.u);
        connect(Gain1.y,P_FIOA_Cons_Var.u);
        connect(S_FIOA_Cons.y,Cons_Ind_Out.u2);
        connect(Industrial_Output.y,Cons_Ind_Out.u1);
        connect(FIOA_Ind.u2,s_fioa_serv);
        connect(Ind_Cap_Inv.u1,FIOA_Ind.y);
        connect(Industrial_Output.y,Ind_Cap_Inv.u2);
        connect(Ind_Cap_Inv.y,Ind_Cap_Invest.u);
        connect(Sink1.MassInPort1,Ind_Cap_Deprec.y1);
        connect(Ind_Cap_Dep.y,Ind_Cap_Deprec.u);
        connect(Industrial_Capital.u2,Ind_Cap_Deprec.y);
        connect(Ind_Cap_Dep.u1,Industrial_Capital.y3);
        connect(Ind_Cap_Invest.y1,Industrial_Capital.u1);
        connect(Source1.MassInPort1,Ind_Cap_Invest.y);
        connect(Industrial_Output.y,industrial_output);
        connect(Ind_Out_PC.u1,Industrial_Output.y);
        connect(P_Ind_Cap_Out_Ratio_2.y,S_Ind_Cap_Out_Ratio.u);
        connect(P_Ind_Cap_Out_Ratio_2.u3,ppoll_tech_mult_icor_COPM);
        connect(P_Ind_Cap_Out_Ratio_2.u2,yield_tech_mult_icor_COYM);
        connect(P_Ind_Cap_Out_Ratio_2.u1,ind_cap_out_ratio_2_ICOR2T);
        connect(Cons_Ind_Out_PC.y,cons_ind_out_pc1);
        connect(Ind_Out_PC.u2,population);
        connect(Ind_Out_PC.y,ind_out_pc);
      end Industrial_Investment;

      block Labor_Utilization "Utilization of the labor force"
        parameter Real labor_util_fr_del_init = 1
        "Initial delayed labor utilization fraction";
        parameter Real labor_util_fr_del_time(unit = "yr") = 2
        "Labor utilization fraction delay time";
        SystemDynamics.Levels.Level1a Labor_Util_Fr_Del(x0 = labor_util_fr_del_init);
        SystemDynamics.Rates.Rate_1 Chg_Lab_Util_Fr_Del;
        SystemDynamics.Sources.Source Source1;
        SystemDynamics.WorldDynamics.World3.Utilities.Ch_Lab_Util_Fr_Del Ch_Lab_Util_Fr_Del(labor_util_fr_del_time = labor_util_fr_del_time)
        "p.241 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Capital_Util_Fr(x_vals=  (-1):2:11, y_vals = {1,1,0.9,0.7,0.3,0.1,0.1})
        "p.241 of Dynamics of Growth in a Finite World";
        Modelica.Blocks.Math.Division Labor_Util_Fr
        "p.241 of Dynamics of Growth in a Finite World";
        Modelica.Blocks.Math.Add3 Jobs
        "p.233 of Dynamics of Growth in a Finite World";
        SystemDynamics.Auxiliary.Prod_2 Pot_Jobs_Agr_Sector
        "p.237 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Jobs_Per_Hect(x_vals = {0,2,6,10,14,18,22,26,30,10000}, y_vals = {2,2,0.5,0.4,0.3,0.27,0.24,0.2,0.2,0.2})
        "p.239 of Dynamics of Growth in a Finite World";
        SystemDynamics.Auxiliary.Prod_2 Pot_Jobs_Ind_Sector
        "p.233 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Jobs_Per_Ind_Cap_Unit(x_vals=  (-100):150:800, y_vals = {0.00037,0.00037,0.00018,0.00012,0.00009,0.00007,0.00006})
        "p.236 of Dynamics of Growth in a Finite World";
        SystemDynamics.Auxiliary.Prod_2 Pot_Jobs_In_Serv_Sector
        "p.236 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Jobs_Per_Serv_Cap_Unit(x_vals = {0,50,200,350,500,650,800,1200}, y_vals = {0.0011,0.0011,0.0006,0.00035,0.0002,0.00015,0.00015,0.00015})
        "p.237 of Dynamics of Growth in a Finite World";
        SystemDynamics.Interfaces.MassInPort service_capital(unit = "dollar")
        "Total capital invested in service sector";
        SystemDynamics.Interfaces.MassInPort ind_out_pc(unit = "dollar/yr")
        "Per capita annual industrial output";
        SystemDynamics.Interfaces.MassInPort industrial_capital(unit = "dollar")
        "Total capital invested in the military/industrial sector";
        SystemDynamics.Interfaces.MassInPort agr_inp_per_hect(unit = "dollar/(hectare.yr)")
        "Agricultural investments per hectare";
        SystemDynamics.Interfaces.MassInPort arable_land(unit = "hectare")
        "Arable land";
        SystemDynamics.Interfaces.MassInPort labor_force
        "Total human labor force";
        SystemDynamics.Interfaces.MassInPort serv_out_pc(unit = "dollar/yr")
        "Per capita annual expenditure in services";
        SystemDynamics.Interfaces.MassOutPort capital_util_fr
        "Capital utilization fraction";
      equation
        connect(Jobs_Per_Hect.u,agr_inp_per_hect);
        connect(Pot_Jobs_In_Serv_Sector.u2,service_capital);
        connect(Capital_Util_Fr.u,Labor_Util_Fr_Del.y1);
        connect(Ch_Lab_Util_Fr_Del.u2,Labor_Util_Fr_Del.y4);
        connect(Labor_Util_Fr.y,Ch_Lab_Util_Fr_Del.u1);
        connect(Ch_Lab_Util_Fr_Del.y,Chg_Lab_Util_Fr_Del.u);
        connect(Chg_Lab_Util_Fr_Del.y1,Labor_Util_Fr_Del.u1);
        connect(Source1.MassInPort1,Chg_Lab_Util_Fr_Del.y);
        connect(Pot_Jobs_In_Serv_Sector.y,Jobs.u3);
        connect(Jobs_Per_Serv_Cap_Unit.y,Pot_Jobs_In_Serv_Sector.u1);
        connect(Pot_Jobs_Ind_Sector.u2,industrial_capital);
        connect(Jobs_Per_Ind_Cap_Unit.y,Pot_Jobs_Ind_Sector.u1);
        connect(Pot_Jobs_Ind_Sector.y,Jobs.u2);
        connect(Pot_Jobs_Agr_Sector.u2,arable_land);
        connect(Jobs_Per_Hect.y,Pot_Jobs_Agr_Sector.u1);
        connect(Pot_Jobs_Agr_Sector.y,Jobs.u1);
        connect(Labor_Util_Fr.u1,Jobs.y);
        connect(Labor_Util_Fr.u2,labor_force);
        connect(Jobs_Per_Ind_Cap_Unit.u,ind_out_pc);
        connect(Jobs_Per_Serv_Cap_Unit.u,serv_out_pc);
        connect(capital_util_fr,Capital_Util_Fr.y);
      end Labor_Utilization;

      block Land_Fertility "Land fertility"
        parameter Real des_food_ratio_dfr = 2 "Desired food ratio";
        parameter Real inherent_land_fert(unit = "kg/(hectare.yr)") = 600
        "Inherent land fertility";
        parameter Real land_fertility_init(unit = "kg/(hectare.yr)") = 600
        "Initial industrial investment";
        parameter Real t_policy_year(unit = "yr") = 4000
        "Year of policy change";
        parameter Real yield_tech_init = 1 "Initial yield technology factor";
        parameter Real p_yield_tech_chg_mlt[:] = {0,0,0,0}
        "Yield technology change multiplier";
        SystemDynamics.Sources.Source Source1;
        SystemDynamics.Rates.RRate Land_Fert_Regen
        "p.328 of Dynamics of Growth in a Finite World";
        SystemDynamics.Levels.Level Land_Fertility(x0 = land_fertility_init)
        "p.324 of Dynamics of Growth in a Finite World";
        SystemDynamics.Rates.RRate Land_Fert_Degr
        "p.326 of Dynamics of Growth in a Finite World";
        SystemDynamics.Sources.Sink Sink1;
        SystemDynamics.WorldDynamics.World3.Utilities.Land_Fert_Reg Land_Fert_Reg(inherent_land_fert = inherent_land_fert)
        "p.328 of Dynamics of Growth in a Finite World";
        SystemDynamics.Auxiliary.Prod_2 Land_Fert_Deg
        "p.326 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Land_Fert_Regen_Time(x_vals=  0:0.02:0.1, y_vals = {20,13,8,4,2,2})
        "p.330 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Land_Fert_Degr_Rt(x_vals = {0,10,20,30,100}, y_vals = {0,0.1,0.3,0.5,0.5})
        "p.326 of Dynamics of Growth in a Finite World";
        SystemDynamics.Interfaces.MassInPort p_fr_inp_for_land_maint
        "Fraction of investments in the agricultural sector allocated to land maintenance";
        SystemDynamics.Interfaces.MassInPort ppoll_index
        "Persistent pollution index";
        SystemDynamics.Interfaces.MassOutPort land_fertility(unit = "kg/(hectare.yr)")
        "Land fertility";
        SystemDynamics.Rates.Rate_1 Yield_Tech_Chg_Rt_LYTDR;
        SystemDynamics.WorldDynamics.World3.Utilities.Yield_Tech_Chg_Rt Yield_Tech_Chg_Rt(t_policy_year = t_policy_year);
        SystemDynamics.Functions.Tabular P_Yield_Tech_Chg_Mlt_LYCM(y_vals = p_yield_tech_chg_mlt, x_vals = {-2,0,1,2});
        SystemDynamics.Interfaces.MassInPort food_ratio "Food ratio";
        Modelica.Blocks.Math.Add Add1(k2 = -1);
        SystemDynamics.Auxiliary.Const Des_Food_Ratio_DFR(k = des_food_ratio_dfr);
        SystemDynamics.Interfaces.MassOutPort yield_tech_LYTD
        "Technology induced absolute yield enhancement";
        SystemDynamics.Sources.Source Source2;
        SystemDynamics.Levels.Level1a Yield_Tech_LYTD(x0 = yield_tech_init);
      equation
        connect(Land_Fert_Regen_Time.u,p_fr_inp_for_land_maint);
        connect(Land_Fert_Regen_Time.y,Land_Fert_Reg.u1);
        connect(land_fertility,Land_Fertility.y1);
        connect(Land_Fert_Deg.u1,Land_Fertility.y2);
        connect(Land_Fert_Reg.u2,Land_Fertility.y4);
        connect(Land_Fertility.u2,Land_Fert_Degr.y);
        connect(Land_Fert_Regen.y1,Land_Fertility.u1);
        connect(Land_Fert_Degr_Rt.y,Land_Fert_Deg.u2);
        connect(Land_Fert_Deg.y,Land_Fert_Degr.u);
        connect(Land_Fert_Degr.y1,Sink1.MassInPort1);
        connect(Land_Fert_Reg.y,Land_Fert_Regen.u);
        connect(Source1.MassInPort1,Land_Fert_Regen.y);
        connect(yield_tech_LYTD,Yield_Tech_LYTD.y2);
        connect(Yield_Tech_Chg_Rt.u2,Yield_Tech_LYTD.y4);
        connect(Yield_Tech_Chg_Rt_LYTDR.y1,Yield_Tech_LYTD.u1);
        connect(Source2.MassInPort1,Yield_Tech_Chg_Rt_LYTDR.y);
        connect(Yield_Tech_Chg_Rt.y,Yield_Tech_Chg_Rt_LYTDR.u);
        connect(food_ratio,Add1.u2);
        connect(Add1.u1,Des_Food_Ratio_DFR.y);
        connect(Add1.y,P_Yield_Tech_Chg_Mlt_LYCM.u);
        connect(Yield_Tech_Chg_Rt.u1,P_Yield_Tech_Chg_Mlt_LYCM.y);
        connect(Land_Fert_Degr_Rt.u,ppoll_index);
      end Land_Fertility;

      block Life_Expectancy "Life expectancy"
        parameter Real hlth_serv_impact_del(unit = "yr") = 20
        "Health services impact delay";
        parameter Real life_expect_norm(unit = "yr") = 28
        "Normal life expectancy";
        parameter Real subsist_food_pc(unit = "kg/yr") = 230
        "Available per capita food";
        SystemDynamics.Auxiliary.Prod_5 Life_Expectancy;
        SystemDynamics.Interfaces.MassOutPort life_expectancy(unit = "yr")
        "Average life expectancy of human population";
        SystemDynamics.Auxiliary.Const Life_Expect_Norm(k = life_expect_norm);
        SystemDynamics.WorldDynamics.World3.Utilities.Lifet_Mult_Hlth_Serv Lifet_Mult_Hlth_Serv
        "p.76 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Lifet_Mlt_Hlth_Serv_1(x_vals = {0,20,40,60,80,100,200}, y_vals = {1,1.1,1.4,1.6,1.7,1.8,1.8})
        "p.76 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Lifet_Mlt_Hlth_Serv_2(x_vals = {0,20,40,60,80,100,200}, y_vals = {1,1.5,1.9,2,2,2,2})
        "p.76 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.SMTH1 Eff_Hlth_Serv_PC(averaging_time(unit = "yr") = hlth_serv_impact_del, smooth_init(unit = "dollar/yr") = 0)
        "p.71 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Hlth_Serv_Al_PC(x_vals=  0:250:2000, y_vals = {0,20,50,95,140,175,200,220,230})
        "p.70 of Dynamics of Growth in a Finite World";
        SystemDynamics.Interfaces.MassInPort serv_out_pc(unit = "dollar/yr")
        "Per capita annual expenditure in services";
        SystemDynamics.WorldDynamics.World3.Utilities.Lifet_Mlt_Crowd Lifet_Mlt_Crowd
        "p.90 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Crowd_Mult_Ind(x_vals=  0:200:1600, y_vals = {0.5,0.05,-0.1,-0.08,-0.02,0.05,0.1,0.15,0.2})
        "p.90 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Fr_Pop_Urban(x_vals=  0:2000000000.0:16000000000.0, y_vals = {0,0.2,0.4,0.5,0.58,0.65,0.72,0.78,0.8})
        "p.88 of Dynamics of Growth in a Finite World";
        SystemDynamics.Interfaces.MassInPort ind_out_pc(unit = "dollar/yr")
        "Per capita annual industrial output";
        SystemDynamics.Interfaces.MassInPort population "Population";
        SystemDynamics.Functions.Tabular Lifet_Mlt_Food(x_vals = 0:5, y_vals = {0,1,1.43,1.5,1.5,1.5})
        "p.66 of Dynamics of Growth in a Finite World";
        Modelica.Blocks.Math.Gain Gain1(k = 1 / subsist_food_pc);
        SystemDynamics.Interfaces.MassInPort food_pc(unit = "kg/yr")
        "Per capita annually consumed food";
        SystemDynamics.Functions.Tabular Lifet_Mlt_PPoll(x_vals=  0:10:100, y_vals = {1,0.99,0.97,0.95,0.9,0.85,0.75,0.65,0.55,0.4,0.2})
        "p.94 of Dynamics of Growth in a Finite World";
        SystemDynamics.Interfaces.MassInPort ppoll_index
        "Persistent pollution index";
      equation
        connect(Life_Expect_Norm.y,Life_Expectancy.u1);
        connect(Lifet_Mlt_Hlth_Serv_1.y,Lifet_Mult_Hlth_Serv.u1);
        connect(Lifet_Mlt_Hlth_Serv_2.y,Lifet_Mult_Hlth_Serv.u2);
        connect(Lifet_Mult_Hlth_Serv.y,Life_Expectancy.u2);
        connect(Lifet_Mlt_Food.y,Life_Expectancy.u4);
        connect(Lifet_Mlt_PPoll.y,Life_Expectancy.u5);
        connect(Lifet_Mlt_Crowd.y,Life_Expectancy.u3);
        connect(Life_Expectancy.y,life_expectancy);
        connect(Crowd_Mult_Ind.y,Lifet_Mlt_Crowd.u1);
        connect(Fr_Pop_Urban.y,Lifet_Mlt_Crowd.u2);
        connect(Gain1.u,food_pc);
        connect(Gain1.y,Lifet_Mlt_Food.u);
        connect(Lifet_Mlt_PPoll.u,ppoll_index);
        connect(Fr_Pop_Urban.u,population);
        connect(Crowd_Mult_Ind.u,ind_out_pc);
        connect(Eff_Hlth_Serv_PC.y,Lifet_Mlt_Hlth_Serv_2.u);
        connect(Eff_Hlth_Serv_PC.y,Lifet_Mlt_Hlth_Serv_1.u);
        connect(Hlth_Serv_Al_PC.y,Eff_Hlth_Serv_PC.u);
        connect(Hlth_Serv_Al_PC.u,serv_out_pc);
      end Life_Expectancy;

      block NR_Resource_Utilization
      "Utilization of non-recoverable natural resources"
        parameter Real des_res_use_rt_DNRUR(unit = "ton/yr") = 4800000000.0
        "Desired resource utilization rate";
        parameter Real nr_resources_init(unit = "ton") = 1000000000000.0
        "Initial available non-recoverable resources";
        parameter Real p_nr_res_use_fact_1 = 1
        "Default non-recoverable resource utilization factor";
        parameter Real res_tech_init = 1
        "Initial non-recoverable resource technology factor";
        parameter Real t_policy_year(unit = "yr") = 4000
        "Year of policy change";
        parameter Real t_fcaor_time(unit = "yr") = 4000
        "Year of capital allocation to resource use efficiency";
        parameter Real tech_dev_del_TDD(unit = "yr") = 20
        "Technology development time";
        parameter Real p_fr_cap_al_obt_res_2[:] = {1,0.2,0.1,0.05,0.05,0.05,0.05,0.05,0.05,0.05,0.05}
        "Non-renewable resource fraction remaining";
        parameter Real p_res_tech_chg_mlt[:] = {0,0,0,0}
        "Resource technology change multiplier";
        SystemDynamics.Levels.Level1b NR_Resources(x0 = nr_resources_init)
        "p.387 of Dynamics of Growth in a Finite World";
        SystemDynamics.Rates.RRate NR_Res_Use_Rate
        "p.389 of Dynamics of Growth in a Finite World";
        SystemDynamics.Sources.Sink Sink1;
        SystemDynamics.Auxiliary.Prod_3 NR_Res_Use_Rt
        "p.389 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.S_NR_Res_Use_Fact S_NR_Res_Use_Fact(t_policy_year = t_policy_year, p_nr_res_use_fact_1 = p_nr_res_use_fact_1)
        "p.390 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.SMTH3 P_Nr_Res_Use_Fact_2(averaging_time(unit = "yr") = tech_dev_del_TDD);
        SystemDynamics.Levels.Level1a Res_Tech_NRTD(x0 = res_tech_init);
        SystemDynamics.Rates.Rate_1 Res_Tech_Ch_Rt_NRATE;
        SystemDynamics.Sources.Source Source1;
        SystemDynamics.WorldDynamics.World3.Utilities.Res_Tech_Ch_Rt_NRATE Res_Tech_Chg_Rt(t_policy_year = t_policy_year);
        SystemDynamics.Functions.Tabular P_Res_Tech_Chg_Mlt_NRCM(x_vals = {-10,-1,0,1}, y_vals = p_res_tech_chg_mlt);
        SystemDynamics.WorldDynamics.World3.Utilities.P_Res_Tech_Chg P_Res_Tech_Chg(des_res_use_rt_DNRUR = des_res_use_rt_DNRUR);
        SystemDynamics.Functions.Tabular PC_Res_Use_Mlt(x_vals=  0:200:1600, y_vals = {0,0.85,2.6,3.4,3.8,4.1,4.4,4.7,5})
        "p.390 of Dynamics of Growth in a Finite World";
        SystemDynamics.Interfaces.MassInPort ind_out_pc(unit = "dollar/yr")
        "Per capita annual industrial output";
        SystemDynamics.Interfaces.MassInPort population "Population";
        SystemDynamics.Interfaces.MassOutPort pc_res_use_mlt(unit = "ton/yr")
        "Per capita resource utilization";
        Modelica.Blocks.Math.Gain NR_Res_Fr_Remain(k = 1 / nr_resources_init)
        "p.393 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular P_Fr_Cap_Al_Obt_Res_1(x_vals=  0:0.1:1, y_vals = {1,0.9,0.7,0.5,0.2,0.1,0.05,0.05,0.05,0.05,0.05})
        "p.394 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular P_Fr_Cap_Al_Obt_Res_2(x_vals=  0:0.1:1, y_vals = p_fr_cap_al_obt_res_2)
        "p.394 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.S_Fr_Cap_Al_Obt_Res S_Fr_Cap_Al_Obt_Res(t_fcaor_time = t_fcaor_time)
        "p.393 of Dynamics of Growth in a Finite World";
        SystemDynamics.Interfaces.MassOutPort s_fr_cap_al_obt_res
        "Fraction of capital allocated to resource use efficiency";
        SystemDynamics.Functions.Tabular Ind_Cap_Out_Ratio_2(x_vals = {0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1,2}, y_vals = {3.75,3.6,3.47,3.36,3.25,3.16,3.1,3.06,3.02,3.01,3,3});
        SystemDynamics.Interfaces.MassOutPort ind_cap_out_ratio_2_ICOR2T
        "Industrial capital output ratio";
        SystemDynamics.Interfaces.MassInPort industrial_output(unit = "dollar/yr")
        "Annual industrial output";
        Modelica.Blocks.Math.Division Res_Intens;
        SystemDynamics.Interfaces.MassOutPort res_intens(unit = "ton/dollar")
        "Resource utilization intensity";
      equation
        connect(P_Fr_Cap_Al_Obt_Res_1.y,S_Fr_Cap_Al_Obt_Res.u1);
        connect(P_Fr_Cap_Al_Obt_Res_2.y,S_Fr_Cap_Al_Obt_Res.u2);
        connect(P_Res_Tech_Chg.y,P_Res_Tech_Chg_Mlt_NRCM.u);
        connect(P_Res_Tech_Chg_Mlt_NRCM.y,Res_Tech_Chg_Rt.u1);
        connect(industrial_output,Res_Intens.u2);
        connect(Res_Intens.y,res_intens);
        connect(P_Res_Tech_Chg.u,Res_Intens.u1);
        connect(Res_Tech_Ch_Rt_NRATE.y,Source1.MassInPort1);
        connect(Res_Tech_NRTD.u1,Res_Tech_Ch_Rt_NRATE.y1);
        connect(Res_Tech_Chg_Rt.y,Res_Tech_Ch_Rt_NRATE.u);
        connect(P_Nr_Res_Use_Fact_2.u,Res_Tech_NRTD.y1);
        connect(Res_Tech_Chg_Rt.u2,Res_Tech_NRTD.y4);
        connect(Ind_Cap_Out_Ratio_2.y,ind_cap_out_ratio_2_ICOR2T);
        connect(Ind_Cap_Out_Ratio_2.u,S_NR_Res_Use_Fact.y);
        connect(P_Nr_Res_Use_Fact_2.y,S_NR_Res_Use_Fact.u);
        connect(S_NR_Res_Use_Fact.y,NR_Res_Use_Rt.u2);
        connect(NR_Res_Use_Rt.u3,population);
        connect(PC_Res_Use_Mlt.y,NR_Res_Use_Rt.u1);
        connect(NR_Res_Use_Rt.y,P_Res_Tech_Chg.u);
        connect(NR_Res_Use_Rt.y,NR_Res_Use_Rate.u);
        connect(PC_Res_Use_Mlt.y,pc_res_use_mlt);
        connect(PC_Res_Use_Mlt.u,ind_out_pc);
        connect(NR_Res_Use_Rate.y1,Sink1.MassInPort1);
        connect(NR_Res_Use_Rate.y,NR_Resources.u1);
        connect(NR_Res_Fr_Remain.u,NR_Resources.y);
        connect(NR_Res_Fr_Remain.y,P_Fr_Cap_Al_Obt_Res_2.u);
        connect(NR_Res_Fr_Remain.y,P_Fr_Cap_Al_Obt_Res_1.u);
        connect(S_Fr_Cap_Al_Obt_Res.y,s_fr_cap_al_obt_res);
      end NR_Resource_Utilization;

      block Pollution_Dynamics "Pollution dynamics"
        parameter Real agr_mtl_toxic_index(unit = "1/dollar") = 1
        "Agricultural materials toxicity index";
        parameter Real assim_half_life_1970(unit = "yr") = 1.5
        "Pollution assimilation half life in 1970";
        parameter Real des_ppoll_index_DPOLX = 1.2
        "Desired persistent pollution index";
        parameter Real fr_agr_inp_pers_mtl = 0.001
        "Effective fraction of agricultural pollution input";
        parameter Real frac_res_pers_mtl = 0.02
        "Effective fraction of resource utilization on pollution generation";
        parameter Real ind_mtl_emiss_fact(unit = "1/ton") = 0.1
        "Industrial materials emission factor";
        parameter Real ind_mtl_toxic_index = 10.0
        "Industrial materials toxicity index";
        parameter Real ind_out_in_1970(unit = "dollar/yr") = 790000000000.0
        "Industrial output in 1970";
        parameter Real p_ppoll_gen_fact_1 = 1
        "Default persistent pollution generation factor";
        parameter Real pers_pollution_init = 25000000.0
        "Initial persistent pollution";
        parameter Real ppoll_in_1970 = 136000000.0
        "Persistent pollution in 1970";
        parameter Real ppoll_tech_init = 1
        "Initial persistent pollution technology change factor";
        parameter Real ppoll_trans_del(unit = "yr") = 20
        "Persistent pollution transmission delay";
        parameter Real t_air_poll_time(unit = "yr") = 4000
        "Air pollution change time";
        parameter Real t_policy_year(unit = "yr") = 4000
        "Year of policy change";
        parameter Real tech_dev_del_TDD(unit = "yr") = 20
        "Technology development time";
        parameter Real p_ppoll_tech_chg_mlt[:] = {0,0,0,0}
        "Persistent pollution technology change multiplier";
        SystemDynamics.Levels.Level Pers_Pollution(x0 = pers_pollution_init)
        "p.440 of Dynamics of Growth in a Finite World";
        SystemDynamics.Rates.RRate PPoll_Appear_Rt
        "p.435 of Dynamics of Growth in a Finite World";
        SystemDynamics.Rates.RRate PPoll_Assim_Rt
        "p.442 of Dynamics of Growth in a Finite World";
        SystemDynamics.Sources.Source Source1;
        SystemDynamics.Sources.Sink Sink1;
        SystemDynamics.Functions.SMTH3 PPoll_Appear_Rate(smooth_init(unit = "1/yr") = 0, averaging_time(unit = "yr") = ppoll_trans_del)
        "p.435 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.PPoll_Assim_Rt PPoll_Ass_Rt
        "p.442 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Assim_Half_Life_Mlt(x_vals=  (-249):250:1001, y_vals = {1,1,11,21,31,41})
        "p.453 of Dynamics of Growth in a Finite World";
        Modelica.Blocks.Math.Gain PPoll_Index(k = 1 / ppoll_in_1970)
        "p.441 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.PPoll_Gen_Rt PPoll_Gen_Rt
        "p.428 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.PPoll_Gen_Agr PPoll_Gen_Agr(agr_mtl_toxic_index = agr_mtl_toxic_index, fr_agr_inp_pers_mtl = fr_agr_inp_pers_mtl)
        "p.433 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.PPoll_Gen_Ind PPoll_Gen_Ind(frac_res_pers_mtl = frac_res_pers_mtl, ind_mtl_emiss_fact = ind_mtl_emiss_fact, ind_mtl_toxic_index = ind_mtl_toxic_index)
        "p.429 of Dynamics of Growth in a Finite World";
        SystemDynamics.Levels.Level1a PPoll_Tech_PTD(x0 = ppoll_tech_init);
        SystemDynamics.Rates.Rate_1 PPoll_Tech_Chg_Rt;
        SystemDynamics.Sources.Source Source2;
        SystemDynamics.WorldDynamics.World3.Utilities.PPoll_Tech_Chg_Rt PPoll_Tech_Ch_Rt(t_policy_year = t_policy_year);
        SystemDynamics.Functions.Tabular P_PPoll_Tech_Chg_mlt_POLGFM(y_vals = p_ppoll_tech_chg_mlt, x_vals = {-100,-1,0,1});
        SystemDynamics.WorldDynamics.World3.Utilities.P_PPoll_Tech_Chg P_PPoll_Tech_Chg(des_ppoll_index_DPOLX = des_ppoll_index_DPOLX);
        SystemDynamics.Functions.SMTH3 P_PPoll_Gen_Fact_2(averaging_time(unit = "yr") = tech_dev_del_TDD);
        SystemDynamics.WorldDynamics.World3.Utilities.S_PPoll_Gen_Fact S_PPoll_Gen_Fact(t_policy_year = t_policy_year, p_ppoll_gen_fact_1 = p_ppoll_gen_fact_1)
        "p.428 of Dynamics of Growth in a Finite World";
        SystemDynamics.Interfaces.MassInPort population "Population";
        SystemDynamics.Interfaces.MassInPort pc_res_use_mlt(unit = "ton/yr")
        "Per capita resource utilization";
        SystemDynamics.Interfaces.MassInPort arable_land(unit = "hectare")
        "Arable land";
        SystemDynamics.Interfaces.MassInPort agr_inp_per_hect(unit = "dollar/(hectare.yr)")
        "Agricultural investments per hectare";
        SystemDynamics.Functions.Tabular PPoll_Tech_Mult_Icor_COPM(x_vals = {0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1,2}, y_vals = {1.25,1.2,1.15,1.11,1.08,1.05,1.03,1.02,1.01,1,1,1});
        SystemDynamics.Interfaces.MassOutPort ppoll_tech_mult_icor_COPM
        "Technology induced reduction in persistent pollution release";
        SystemDynamics.Interfaces.MassOutPort ppoll_index
        "Persistent pollution index";
        SystemDynamics.Interfaces.MassOutPort ppoll_gen_rt(unit = "1/yr")
        "Persistent pollution generation rate";
        SystemDynamics.Interfaces.MassInPort industrial_output(unit = "dollar/yr")
        "Annual industrial output";
        SystemDynamics.WorldDynamics.World3.Utilities.Poll_Intens_Ind Poll_Intens_Ind;
        SystemDynamics.Interfaces.MassOutPort poll_intens_ind(unit = "1/dollar")
        "Persistent pollution intensity index";
        Modelica.Blocks.Math.Gain Gain1(k = 1 / ind_out_in_1970);
        SystemDynamics.Functions.Tabular P_Yield_Mlt_Air_Poll_1(x_vals=  0:10:30, y_vals = {1,1,0.7,0.4})
        "p.310 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular P_Yield_Mlt_Air_Poll_2(x_vals=  0:10:30, y_vals = {1,1,0.98,0.95})
        "p.310 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.S_Yield_Mlt_Air_Poll S_Yield_Mlt_Air_Poll(t_air_poll_time = t_air_poll_time)
        "p.310 of Dynamics of Growth in a Finite World";
        SystemDynamics.Interfaces.MassOutPort s_yield_mlt_air_poll
        "Land yield multiplier to air pollution release";
        Modelica.Blocks.Math.Gain Assim_Half_Life(k = assim_half_life_1970)
        "p.453 of Dynamics of Growth in a Finite World";
      equation
        connect(S_Yield_Mlt_Air_Poll.u1,P_Yield_Mlt_Air_Poll_1.y);
        connect(P_Yield_Mlt_Air_Poll_2.y,S_Yield_Mlt_Air_Poll.u2);
        connect(arable_land,PPoll_Gen_Agr.u2);
        connect(agr_inp_per_hect,PPoll_Gen_Agr.u1);
        connect(PPoll_Gen_Ind.u2,population);
        connect(PPoll_Gen_Ind.u1,pc_res_use_mlt);
        connect(S_PPoll_Gen_Fact.y,PPoll_Gen_Rt.u1);
        connect(PPoll_Gen_Agr.y,PPoll_Gen_Rt.u3);
        connect(Assim_Half_Life.y,PPoll_Ass_Rt.u2);
        connect(PPoll_Ass_Rt.u1,Pers_Pollution.y2);
        connect(S_Yield_Mlt_Air_Poll.y,s_yield_mlt_air_poll);
        connect(Gain1.y,P_Yield_Mlt_Air_Poll_2.u);
        connect(Gain1.y,P_Yield_Mlt_Air_Poll_1.u);
        connect(PPoll_Ass_Rt.y,PPoll_Assim_Rt.u);
        connect(Assim_Half_Life_Mlt.y,Assim_Half_Life.u);
        connect(PPoll_Index.y,Assim_Half_Life_Mlt.u);
        connect(PPoll_Index.y,ppoll_index);
        connect(PPoll_Index.y,P_PPoll_Tech_Chg.u);
        connect(PPoll_Index.u,Pers_Pollution.y3);
        connect(PPoll_Gen_Rt.y,ppoll_gen_rt);
        connect(PPoll_Gen_Ind.y,PPoll_Gen_Rt.u2);
        connect(PPoll_Gen_Rt.y,PPoll_Appear_Rate.u);
        connect(Gain1.u,industrial_output);
        connect(PPoll_Gen_Ind.y,Poll_Intens_Ind.u2);
        connect(PPoll_Appear_Rate.y,PPoll_Appear_Rt.u);
        connect(PPoll_Assim_Rt.y,Pers_Pollution.u2);
        connect(Sink1.MassInPort1,PPoll_Assim_Rt.y1);
        connect(Source1.MassInPort1,PPoll_Appear_Rt.y);
        connect(PPoll_Appear_Rt.y1,Pers_Pollution.u1);
        connect(P_PPoll_Tech_Chg.y,P_PPoll_Tech_Chg_mlt_POLGFM.u);
        connect(PPoll_Tech_Ch_Rt.u1,P_PPoll_Tech_Chg_mlt_POLGFM.y);
        connect(PPoll_Tech_Ch_Rt.u2,PPoll_Tech_PTD.y4);
        connect(P_PPoll_Gen_Fact_2.u,PPoll_Tech_PTD.y);
        connect(PPoll_Tech_Chg_Rt.y1,PPoll_Tech_PTD.u1);
        connect(PPoll_Tech_Ch_Rt.y,PPoll_Tech_Chg_Rt.u);
        connect(Source2.MassInPort1,PPoll_Tech_Chg_Rt.y);
        connect(S_PPoll_Gen_Fact.u,P_PPoll_Gen_Fact_2.y);
        connect(S_PPoll_Gen_Fact.y,Poll_Intens_Ind.u3);
        connect(S_PPoll_Gen_Fact.y,PPoll_Tech_Mult_Icor_COPM.u);
        connect(PPoll_Tech_Mult_Icor_COPM.y,ppoll_tech_mult_icor_COPM);
        connect(Poll_Intens_Ind.u1,industrial_output);
        connect(Poll_Intens_Ind.y,poll_intens_ind);
      end Pollution_Dynamics;

      block Population_Dynamics "Population dynamics"
        parameter Real pop1_init = 650000000.0
        "Initial population 14 years and younger";
        parameter Real pop2_init = 700000000.0
        "Initial population 15 to 44 years old";
        parameter Real pop3_init = 190000000.0
        "Initial population 45 to 64 years old";
        parameter Real pop4_init = 60000000.0
        "Initial population 65 years and older";
        parameter Real labor_force_partic = 0.75
        "Percentage of participating labor force";
        parameter Real reproductive_lifetime(unit = "yr") = 30
        "Reproductive life time";
        parameter Real t_pop_equil_time(unit = "yr") = 4000
        "Population equilibrium time";
        SystemDynamics.Rates.RRate Births
        "p.96 of Dynamics of Growth in a Finite World";
        SystemDynamics.Sources.Source source;
        SystemDynamics.Levels.Level2b Pop_0_14(x0 = pop1_init);
        SystemDynamics.Rates.RRate Matur_14
        "p.141 of Dynamics of Growth in a Finite World";
        SystemDynamics.Levels.Level2b Pop_15_44(x0 = pop2_init)
        "p.57 of Dynamics of Growth in a Finite World";
        SystemDynamics.Rates.RRate Matur_44
        "p.141 of Dynamics of Growth in a Finite World";
        SystemDynamics.Levels.Level2b Pop_45_64(x0 = pop3_init)
        "p.57 of Dynamics of Growth in a Finite World";
        SystemDynamics.Rates.RRate Matur_64
        "p.141 of Dynamics of Growth in a Finite World";
        SystemDynamics.Levels.Level Pop_65plus(x0 = pop4_init)
        "p.57 of Dynamics of Growth in a Finite World";
        SystemDynamics.Rates.RRate Deaths_65p
        "p.57 of Dynamics of Growth in a Finite World";
        SystemDynamics.Sources.Sink sink;
        SystemDynamics.WorldDynamics.World3.Utilities.Birth_Factors births(Repro_Life = reproductive_lifetime, t_pop_equil_time = t_pop_equil_time)
        "p.96 of Dynamics of Growth in a Finite World";
        SystemDynamics.Rates.RRate Deaths_0_14
        "p.57 of Dynamics of Growth in a Finite World";
        SystemDynamics.Sources.Sink sink1;
        SystemDynamics.Rates.RRate Deaths_15_44
        "p.57 of Dynamics of Growth in a Finite World";
        SystemDynamics.Sources.Sink sink2;
        SystemDynamics.Rates.RRate Deaths_45_64
        "p.57 of Dynamics of Growth in a Finite World";
        SystemDynamics.Sources.Sink sink3;
        SystemDynamics.WorldDynamics.World3.Utilities.Matur_Factors matur_14(bracket = 15)
        "p.141 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.Matur_Factors matur_44(bracket = 30)
        "p.141 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.Matur_Factors matur_64(bracket = 20)
        "p.141 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.Death_Factors deaths_0_14
        "p.57 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.Death_Factors deaths_15_44
        "p.57 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.Death_Factors deaths_45_64
        "p.57 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.Death_Factors deaths_65p
        "p.57 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Mort_0_14(x_vals=  20:10:90, y_vals = {0.0567,0.0366,0.0243,0.0155,0.0082,0.0023,0.001,0.001})
        "p.57 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Mort_15_44(x_vals=  20:10:90, y_vals = {0.0266,0.0171,0.011,0.0065,0.004,0.0016,0.0008,0.0008})
        "p.57 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Mort_45_64(x_vals=  20:10:90, y_vals = {0.0562,0.0373,0.0252,0.0171,0.0118,0.0083,0.006,0.006})
        "p.57 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular Mort_65p(x_vals=  20:10:90, y_vals = {0.13,0.11,0.09,0.07,0.06,0.05,0.04,0.04})
        "p.57 of Dynamics of Growth in a Finite World";
        SystemDynamics.Interfaces.MassInPort life_expectancy(unit = "yr")
        "Average life expectancy of human population";
        Modelica.Blocks.Math.Add Pop_Young;
        Modelica.Blocks.Math.Add Pop_Old;
        Modelica.Blocks.Math.Add Population;
        Modelica.Blocks.Math.Add Death_Young;
        Modelica.Blocks.Math.Add Death_Old;
        Modelica.Blocks.Math.Add Deaths;
        Modelica.Blocks.Math.Add Work_Pop
        "p.241 of Dynamics of Growth in a Finite World";
        Modelica.Blocks.Math.Gain Labor_Force(k = labor_force_partic)
        "p.241 of Dynamics of Growth in a Finite World";
        SystemDynamics.Interfaces.MassOutPort labor_force
        "Total human labor force";
        SystemDynamics.WorldDynamics.World3.Utilities.BD_Rates Birth_Rate
        "p.97 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.BD_Rates Death_Rate
        "p.140 of Dynamics of Growth in a Finite World";
        SystemDynamics.Interfaces.MassInPort total_fertility
        "Average human fertility";
        SystemDynamics.Interfaces.MassOutPort population "Population";
      equation
        connect(Labor_Force.y,labor_force);
        connect(Labor_Force.u,Work_Pop.y);
        connect(matur_64.u1,Pop_45_64.y1);
        connect(matur_44.u1,Pop_15_44.y1);
        connect(matur_14.u1,Pop_0_14.y1);
        connect(deaths_0_14.u1,Pop_0_14.y2);
        connect(Mort_0_14.y,deaths_0_14.u2);
        connect(deaths_15_44.u1,Pop_15_44.y2);
        connect(Mort_15_44.y,deaths_15_44.u2);
        connect(deaths_45_64.u1,Pop_45_64.y2);
        connect(Mort_45_64.y,deaths_45_64.u2);
        connect(Work_Pop.u2,Pop_45_64.y);
        connect(Pop_Old.u1,Pop_45_64.y);
        connect(Pop_45_64.u3,Deaths_45_64.y);
        connect(Pop_45_64.u2,Matur_64.y);
        connect(Matur_44.y1,Pop_45_64.u1);
        connect(deaths_65p.u1,Pop_65plus.y2);
        connect(Pop_Old.u2,Pop_65plus.y);
        connect(Pop_65plus.u2,Deaths_65p.y);
        connect(Matur_64.y1,Pop_65plus.u1);
        connect(matur_64.y,Matur_64.u);
        connect(Matur_14.y1,Pop_15_44.u1);
        connect(Work_Pop.u1,Pop_15_44.y);
        connect(Pop_Young.u2,Pop_15_44.y);
        connect(births.u3,Pop_15_44.y3);
        connect(Pop_15_44.u3,Deaths_15_44.y);
        connect(Pop_15_44.u2,Matur_44.y);
        connect(matur_14.y,Matur_14.u);
        connect(Pop_0_14.u2,Matur_14.y);
        connect(Deaths_65p.y1,sink.MassInPort1);
        connect(deaths_65p.y,Deaths_65p.u);
        connect(deaths_45_64.y,Deaths_45_64.u);
        connect(Deaths_45_64.y1,sink3.MassInPort1);
        connect(deaths_45_64.y,Death_Old.u1);
        connect(deaths_15_44.y,Death_Young.u2);
        connect(deaths_15_44.y,Deaths_15_44.u);
        connect(Deaths_15_44.y1,sink2.MassInPort1);
        connect(deaths_0_14.y,Deaths_0_14.u);
        connect(Deaths_0_14.y1,sink1.MassInPort1);
        connect(Pop_0_14.u3,Deaths_0_14.y);
        connect(Mort_0_14.y,matur_14.u2);
        connect(Mort_15_44.y,matur_44.u2);
        connect(matur_44.y,Matur_44.u);
        connect(Mort_45_64.y,matur_64.u2);
        connect(deaths_65p.y,Death_Old.u2);
        connect(Mort_65p.y,deaths_65p.u2);
        connect(Mort_65p.u,Mort_45_64.u);
        connect(Mort_45_64.u,Mort_15_44.u);
        connect(Mort_15_44.u,Mort_0_14.u);
        connect(Mort_0_14.u,life_expectancy);
        connect(deaths_0_14.y,Death_Young.u1);
        connect(source.MassInPort1,Births.y);
        connect(Births.y1,Pop_0_14.u1);
        connect(births.y,Births.u);
        connect(Pop_Young.u1,Pop_0_14.y);
        connect(Pop_Young.y,Population.u1);
        connect(Pop_Old.y,Population.u2);
        connect(Death_Young.y,Deaths.u1);
        connect(Death_Old.y,Deaths.u2);
        connect(Birth_Rate.u2,Population.y);
        connect(births.y,Birth_Rate.u1);
        connect(Population.y,Death_Rate.u2);
        connect(Deaths.y,Death_Rate.u1);
        connect(Deaths.y,births.u2);
        connect(births.u1,total_fertility);
        connect(Population.y,population);
      end Population_Dynamics;

      block Service_Sector_Investment "Investments in the service sector"
        parameter Real t_policy_year(unit = "yr") = 4000
        "Year of policy change";
        parameter Real p_avg_life_serv_cap_1(unit = "yr") = 20
        "Default average life of service sector capital";
        parameter Real p_avg_life_serv_cap_2(unit = "yr") = 20
        "Controlled average life of service sector capital";
        parameter Real p_serv_cap_out_ratio_1(unit = "yr") = 1.0
        "Default fraction of service sector output ratio";
        parameter Real p_serv_cap_out_ratio_2(unit = "yr") = 1.0
        "Controlled fraction of service sector output ratio";
        parameter Real service_capital_init(unit = "dollar") = 144000000000.0
        "Initial service sector investment";
        SystemDynamics.Sources.Source Source1;
        SystemDynamics.Rates.RRate Serv_Cap_Invest
        "p.230 of Dynamics of Growth in a Finite World";
        SystemDynamics.Levels.Level Service_Capital(x0 = service_capital_init)
        "p.230 of Dynamics of Growth in a Finite World";
        SystemDynamics.Rates.RRate Serv_Cap_Deprec
        "p.231 of Dynamics of Growth in a Finite World";
        SystemDynamics.Sources.Sink Sink1;
        SystemDynamics.Auxiliary.Prod_2 Serv_Cap_Inv
        "p.230 of Dynamics of Growth in a Finite World";
        Modelica.Blocks.Math.Division Serv_Cap_Dep
        "p.231 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.S_Avg_Life_Serv_Cap S_Avg_Life_Serv_Cap(t_policy_year = t_policy_year, p_avg_life_serv_cap_1 = p_avg_life_serv_cap_1, p_avg_life_serv_cap_2 = p_avg_life_serv_cap_2)
        "p.231 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.Service_Output Service_Output
        "p.231 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.S_Serv_Cap_Out_Ratio S_Serv_Cap_Out_Ratio(t_policy_year = t_policy_year, p_serv_cap_out_ratio_1 = p_serv_cap_out_ratio_1, p_serv_cap_out_ratio_2 = p_serv_cap_out_ratio_2)
        "p.232 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.S_FIOA_Serv S_FIOA_Serv(t_policy_year = t_policy_year)
        "p.229 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular P_Fr_IO_Al_Serv_1(x_vals = {0,0.5,1,1.5,2,5}, y_vals = {0.3,0.2,0.1,0.05,0,0})
        "p.229 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular P_Fr_IO_Al_Serv_2(x_vals = {0,0.5,1,1.5,2,5}, y_vals = {0.3,0.2,0.1,0.05,0,0})
        "p.229 of Dynamics of Growth in a Finite World";
        Modelica.Blocks.Math.Division Div1
        "p.229 of Dynamics of Growth in a Finite World";
        SystemDynamics.WorldDynamics.World3.Utilities.S_Indic_Serv_PC S_Indic_Serv_PC(t_policy_year = t_policy_year)
        "p.227 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular P_Indic_Serv_PC_1(x_vals=  0:200:1600, y_vals = {40,300,640,1000,1220,1450,1650,1800,2000})
        "p.227 of Dynamics of Growth in a Finite World";
        SystemDynamics.Functions.Tabular P_Indic_Serv_PC_2(x_vals=  0:200:1600, y_vals = {40,300,640,1000,1220,1450,1650,1800,2000})
        "p.227 of Dynamics of Growth in a Finite World";
        Modelica.Blocks.Math.Division Serv_Out_PC
        "p.232 of Dynamics of Growth in a Finite World";
        SystemDynamics.Interfaces.MassInPort population "Population";
        SystemDynamics.Interfaces.MassInPort capital_util_fr
        "Capital utilization fraction";
        SystemDynamics.Interfaces.MassInPort industrial_output(unit = "dollar/yr")
        "Annual industrial output";
        SystemDynamics.Interfaces.MassInPort ind_out_pc(unit = "dollar/yr")
        "Per capita annual industrial output";
        SystemDynamics.Interfaces.MassOutPort serv_out_pc(unit = "dollar/yr")
        "Per capita annual expenditure in services";
        SystemDynamics.Interfaces.MassOutPort service_capital(unit = "dollar")
        "Total capital invested in service sector";
        SystemDynamics.Interfaces.MassOutPort s_fioa_serv
        "Fraction of total investments allocated to the service sector";
      equation
        connect(Service_Output.u1,capital_util_fr);
        connect(Service_Output.u3,Service_Capital.y1);
        connect(service_capital,Service_Capital.y2);
        connect(Serv_Cap_Dep.u1,Service_Capital.y3);
        connect(P_Fr_IO_Al_Serv_1.y,S_FIOA_Serv.u1);
        connect(P_Fr_IO_Al_Serv_2.y,S_FIOA_Serv.u2);
        connect(P_Indic_Serv_PC_1.y,S_Indic_Serv_PC.u1);
        connect(P_Indic_Serv_PC_2.y,S_Indic_Serv_PC.u2);
        connect(P_Indic_Serv_PC_1.u,P_Indic_Serv_PC_2.u);
        connect(P_Indic_Serv_PC_2.u,ind_out_pc);
        connect(S_Indic_Serv_PC.y,Div1.u2);
        connect(S_Avg_Life_Serv_Cap.y,Serv_Cap_Dep.u2);
        connect(Div1.y,P_Fr_IO_Al_Serv_2.u);
        connect(Div1.y,P_Fr_IO_Al_Serv_1.u);
        connect(S_FIOA_Serv.y,s_fioa_serv);
        connect(S_FIOA_Serv.y,Serv_Cap_Inv.u2);
        connect(Serv_Cap_Dep.y,Serv_Cap_Deprec.u);
        connect(Serv_Cap_Deprec.y1,Sink1.MassInPort1);
        connect(Service_Capital.u2,Serv_Cap_Deprec.y);
        connect(Serv_Cap_Invest.y1,Service_Capital.u1);
        connect(Serv_Cap_Inv.y,Serv_Cap_Invest.u);
        connect(Source1.MassInPort1,Serv_Cap_Invest.y);
        connect(S_Serv_Cap_Out_Ratio.y,Service_Output.u2);
        connect(Serv_Out_PC.u1,Service_Output.y);
        connect(Serv_Out_PC.y,serv_out_pc);
        connect(Serv_Out_PC.u2,population);
        connect(Serv_Out_PC.y,Div1.u1);
        connect(Serv_Cap_Inv.u1,industrial_output);
      end Service_Sector_Investment;

      model Scenario_1 "Original WORLD3 model"
        parameter Real agr_mtl_toxic_index(unit = "1/dollar") = 1
        "Agricultural materials toxicity index";
        parameter Real assim_half_life_1970(unit = "yr") = 1.5
        "Pollution assimilation half life in 1970";
        parameter Real avg_life_land_norm(unit = "yr") = 1000
        "Normal life span of land";
        parameter Real des_compl_fam_size_norm = 3.8
        "Desired normal complete family size";
        parameter Real des_food_ratio_dfr = 2 "Desired food ratio";
        parameter Real des_ppoll_index_DPOLX = 1.2
        "Desired persistent pollution index";
        parameter Real des_res_use_rt_DNRUR(unit = "ton/yr") = 4800000000.0
        "Desired resource utilization rate";
        parameter Real food_short_perc_del(unit = "yr") = 2
        "Food shortage perception delay";
        parameter Real fr_agr_inp_pers_mtl = 0.001
        "Effective fraction of agricultural pollution input";
        parameter Real frac_res_pers_mtl = 0.02
        "Effective fraction of resource utilization on pollution generation";
        parameter Real hlth_serv_impact_del(unit = "yr") = 20
        "Health service impact delay";
        parameter Real income_expect_avg_time(unit = "yr") = 3
        "Income expected average time";
        parameter Real ind_mtl_emiss_fact(unit = "1/ton") = 0.1
        "Industrial materials emission factor";
        parameter Real ind_mtl_toxic_index = 10.0
        "Industrial materials toxicity index";
        parameter Real ind_out_pc_des(unit = "dollar/yr") = 400
        "Desired annual industrial per capita output";
        parameter Real ind_out_in_1970(unit = "dollar/yr") = 790000000000.0
        "Industrial output in 1970";
        parameter Real inherent_land_fert(unit = "kg/(hectare.yr)") = 600
        "Inherent land fertility";
        parameter Real labor_force_partic = 0.75
        "Percentage of participating labor force";
        parameter Real labor_util_fr_del_time(unit = "yr") = 2
        "Labor utilization fraction delay time";
        parameter Real land_fr_harvested = 0.7 "Land fraction harvested";
        parameter Real life_expect_norm(unit = "yr") = 28
        "Normal life expectancy";
        parameter Real lifet_perc_del(unit = "yr") = 20
        "Perceived life-time delay";
        parameter Real max_tot_fert_norm = 12 "Normal maximal total fertility";
        parameter Real p_avg_life_agr_inp_1(unit = "yr") = 2
        "Default average life of agricultural input";
        parameter Real p_avg_life_agr_inp_2(unit = "yr") = 2
        "Controlled average life of agricultural input";
        parameter Real p_avg_life_ind_cap_1(unit = "yr") = 14
        "Default average life of industrial capital";
        parameter Real p_avg_life_ind_cap_2(unit = "yr") = 14
        "Controlled average life of industrial capital";
        parameter Real p_avg_life_serv_cap_1(unit = "yr") = 20
        "Default average life of service sector capital";
        parameter Real p_avg_life_serv_cap_2(unit = "yr") = 20
        "Controlled average life of service sector capital";
        parameter Real p_fioa_cons_const_1 = 0.43
        "Default fraction of industrial output allocated to consumption";
        parameter Real p_fioa_cons_const_2 = 0.43
        "Controlled fraction of industrial output allocated to consumption";
        parameter Real p_ind_cap_out_ratio_1(unit = "yr") = 3
        "Default industrial capital output ratio";
        parameter Real p_land_yield_fact_1 = 1 "Default land yield factor";
        parameter Real p_nr_res_use_fact_1 = 1
        "Default non-recoverable resource utilization factor";
        parameter Real p_ppoll_gen_fact_1 = 1
        "Default persistent pollution generation factor";
        parameter Real p_serv_cap_out_ratio_1(unit = "yr") = 1.0
        "Default fraction of service sector output ratio";
        parameter Real p_serv_cap_out_ratio_2(unit = "yr") = 1.0
        "Controlled fraction of service sector output ratio";
        parameter Real pot_arable_land_tot(unit = "hectare") = 3200000000.0
        "Total potential arable land";
        parameter Real ppoll_in_1970 = 136000000.0
        "Persistent pollution in 1970";
        parameter Real ppoll_trans_del(unit = "yr") = 20
        "Persistent pollution transmission delay";
        parameter Real processing_loss = 0.1 "Processing loss";
        parameter Real reproductive_lifetime(unit = "yr") = 30.0
        "Reproductive life time";
        parameter Real social_adj_del(unit = "yr") = 20
        "Social adjustment delay";
        parameter Real social_discount(unit = "1/yr") = 0.07 "Social discount";
        parameter Real subsist_food_pc(unit = "kg/yr") = 230
        "Available per capita food";
        parameter Real tech_dev_del_TDD(unit = "yr") = 20
        "Technology development time";
        parameter Real urb_ind_land_dev_time(unit = "yr") = 10
        "Urban and industrial land development time";
        parameter Real t_air_poll_time(unit = "yr") = 4000
        "Air pollution change time";
        parameter Real t_fcaor_time(unit = "yr") = 4000
        "Year of capital allocation to resource use efficiency";
        parameter Real t_fert_cont_eff_time(unit = "yr") = 4000
        "Year of continued fertility change";
        parameter Real t_ind_equil_time(unit = "yr") = 4000
        "Year of industrial equilibrium";
        parameter Real t_land_life_time(unit = "yr") = 4000 "Land life time";
        parameter Real t_policy_year(unit = "yr") = 4000
        "Year of policy change";
        parameter Real t_pop_equil_time(unit = "yr") = 4000
        "Population equilibrium time";
        parameter Real t_zero_pop_grow_time(unit = "yr") = 4000
        "Time to zero population growth";
        parameter Real p_fr_cap_al_obt_res_2[:] = {1,0.2,0.1,0.05,0.05,0.05,0.05,0.05,0.05,0.05,0.05}
        "Non-renewable resource fraction remaining";
        parameter Real p_ppoll_tech_chg_mlt[:] = {0,0,0,0}
        "Persistent pollution technology change multiplier";
        parameter Real p_res_tech_chg_mlt[:] = {0,0,0,0}
        "Resource technology change multiplier";
        parameter Real p_yield_tech_chg_mlt[:] = {0,0,0,0}
        "Yield technology change multiplier";
        parameter Real agr_inp_init(unit = "dollar/yr") = 5000000000.0
        "Initial agricultural input";
        parameter Real arable_land_init(unit = "hectare") = 900000000.0
        "Initial arable land";
        parameter Real industrial_capital_init(unit = "dollar") = 210000000000.0
        "Initial industrial investment";
        parameter Real labor_util_fr_del_init = 1
        "Initial delayed labor utilization fraction";
        parameter Real land_fertility_init(unit = "kg/(hectare.yr)") = 600
        "Initial industrial investment";
        parameter Real nr_resources_init(unit = "ton") = 1000000000000.0
        "Initial available non-recoverable resources";
        parameter Real perc_food_ratio_init = 1 "Initial perceived food ratio";
        parameter Real pers_pollution_init = 25000000.0
        "Initial persistent pollution";
        parameter Real pop1_init = 650000000.0
        "Initial population 14 years and younger";
        parameter Real pop2_init = 700000000.0
        "Initial population 15 to 44 years old";
        parameter Real pop3_init = 190000000.0
        "Initial population 45 to 64 years old";
        parameter Real pop4_init = 60000000.0
        "Initial population 65 years and older";
        parameter Real pot_arable_land_init(unit = "hectare") = 2300000000.0
        "Initial potential arable land";
        parameter Real ppoll_tech_init = 1
        "Initial persistent pollution technology change factor";
        parameter Real res_tech_init = 1
        "Initial non-recoverable resource technology factor";
        parameter Real service_capital_init(unit = "dollar") = 144000000000.0
        "Initial service sector investment";
        parameter Real urban_ind_land_init(unit = "hectare") = 8200000.0
        "Initial urban and industrial land";
        parameter Real yield_tech_init = 1 "Initial yield technology factor";
        output Real population "Total human world population";
        output Real food(unit = "dollar/yr") "Total annually produced food";
        output Real industrial_output(unit = "dollar/yr")
        "Total annual world industrial output";
        output Real ppoll_index "Persistent pollution index";
        output Real nr_resources "Remaining non-recoverable natural resources";
        output Real fioa_ind
        "Fraction of industrial output allocated to industrial/military complex";
        output Real s_fioa_agr
        "Fraction of industrial output allocated to food production";
        output Real s_fioa_cons
        "Fraction of industrial output allocated to consumption";
        output Real s_fioa_serv
        "Fraction of industrial output allocated to service sector";
        output Real s_fr_cap_al_obt_res
        "Fraction of capital allocated to resource use efficiency";
        output Real life_expectancy(unit = "yr") "Life expectancy";
        output Real food_pc(unit = "dollar/yr") "Total annual food per person";
        output Real serv_out_pc(unit = "dollar/yr")
        "Total annual services per person";
        output Real ind_out_pc(unit = "dollar/yr")
        "Total annual consumer goods per person";
        output Real human_ecological_footprint(unit = "Gha")
        "Human ecological footprint";
        output Real human_welfare_index "Human welfare index";
        SystemDynamics.WorldDynamics.World3.Population_Dynamics Population_Dynamics1(pop1_init = pop1_init, pop2_init = pop2_init, pop3_init = pop3_init, pop4_init = pop4_init, labor_force_partic = labor_force_partic, reproductive_lifetime = reproductive_lifetime, t_pop_equil_time = t_pop_equil_time)
        "Population dynamics";
        SystemDynamics.WorldDynamics.World3.Pollution_Dynamics Pollution_Dynamics1(agr_mtl_toxic_index = agr_mtl_toxic_index, assim_half_life_1970 = assim_half_life_1970, des_ppoll_index_DPOLX = des_ppoll_index_DPOLX, fr_agr_inp_pers_mtl = fr_agr_inp_pers_mtl, frac_res_pers_mtl = frac_res_pers_mtl, ind_mtl_emiss_fact = ind_mtl_emiss_fact, ind_mtl_toxic_index = ind_mtl_toxic_index, ind_out_in_1970 = ind_out_in_1970, p_ppoll_gen_fact_1 = p_ppoll_gen_fact_1, pers_pollution_init = pers_pollution_init, ppoll_in_1970 = ppoll_in_1970, ppoll_tech_init = ppoll_tech_init, ppoll_trans_del = ppoll_trans_del, t_air_poll_time = t_air_poll_time, t_policy_year = t_policy_year, tech_dev_del_TDD = tech_dev_del_TDD, p_ppoll_tech_chg_mlt = p_ppoll_tech_chg_mlt)
        "Persistent pollution generation";
        SystemDynamics.WorldDynamics.World3.Arable_Land_Dynamics Arable_Land_Dynamics1(arable_land_init = arable_land_init, avg_life_land_norm = avg_life_land_norm, inherent_land_fert = inherent_land_fert, pot_arable_land_init = pot_arable_land_init, pot_arable_land_tot = pot_arable_land_tot, social_discount = social_discount, t_land_life_time = t_land_life_time, urban_ind_land_init = urban_ind_land_init, urb_ind_land_dev_time = urb_ind_land_dev_time)
        "Arable land dynamics";
        SystemDynamics.WorldDynamics.World3.Food_Production Food_Production1(agr_inp_init = agr_inp_init, food_short_perc_del = food_short_perc_del, p_avg_life_agr_inp_1 = p_avg_life_agr_inp_1, p_avg_life_agr_inp_2 = p_avg_life_agr_inp_2, p_land_yield_fact_1 = p_land_yield_fact_1, perc_food_ratio_init = perc_food_ratio_init, processing_loss = processing_loss, subsist_food_pc = subsist_food_pc, t_policy_year = t_policy_year, tech_dev_del_TDD = tech_dev_del_TDD, land_fr_harvested = land_fr_harvested)
        "Food production";
        SystemDynamics.WorldDynamics.World3.Human_Ecological_Footprint Human_Ecological_Footprint1
        "Human ecological footprint";
        SystemDynamics.WorldDynamics.World3.Human_Fertility Human_Fertility1(des_compl_fam_size_norm = des_compl_fam_size_norm, hlth_serv_impact_del = hlth_serv_impact_del, income_expect_avg_time = income_expect_avg_time, lifet_perc_del = lifet_perc_del, max_tot_fert_norm = max_tot_fert_norm, social_adj_del = social_adj_del, t_fert_cont_eff_time = t_fert_cont_eff_time, t_zero_pop_grow_time = t_zero_pop_grow_time)
        "Human fertility";
        SystemDynamics.WorldDynamics.World3.Human_Welfare_Index Human_Welfare_Index1
        "Human welfare index";
        SystemDynamics.WorldDynamics.World3.Industrial_Investment Industrial_Investment1(industrial_capital_init = industrial_capital_init, ind_out_pc_des = ind_out_pc_des, p_avg_life_ind_cap_1 = p_avg_life_ind_cap_1, p_avg_life_ind_cap_2 = p_avg_life_ind_cap_2, p_fioa_cons_const_1 = p_fioa_cons_const_1, p_fioa_cons_const_2 = p_fioa_cons_const_2, p_ind_cap_out_ratio_1 = p_ind_cap_out_ratio_1, t_ind_equil_time = t_ind_equil_time, t_policy_year = t_policy_year)
        "Industrial investment";
        SystemDynamics.WorldDynamics.World3.Labor_Utilization Labor_Utilization1(labor_util_fr_del_init = labor_util_fr_del_init, labor_util_fr_del_time = labor_util_fr_del_time)
        "Labor utilization";
        SystemDynamics.WorldDynamics.World3.Land_Fertility Land_Fertility1(des_food_ratio_dfr = des_food_ratio_dfr, inherent_land_fert = inherent_land_fert, land_fertility_init = land_fertility_init, t_policy_year = t_policy_year, yield_tech_init = yield_tech_init, p_yield_tech_chg_mlt = p_yield_tech_chg_mlt)
        "Land fertility";
        SystemDynamics.WorldDynamics.World3.Life_Expectancy Life_Expectancy1(hlth_serv_impact_del = hlth_serv_impact_del, life_expect_norm = life_expect_norm, subsist_food_pc = subsist_food_pc)
        "Life expectancy";
        SystemDynamics.WorldDynamics.World3.NR_Resource_Utilization NR_Resource_Utilization1(des_res_use_rt_DNRUR = des_res_use_rt_DNRUR, nr_resources_init = nr_resources_init, p_nr_res_use_fact_1 = p_nr_res_use_fact_1, res_tech_init = res_tech_init, t_policy_year = t_policy_year, t_fcaor_time = t_fcaor_time, tech_dev_del_TDD = tech_dev_del_TDD, p_fr_cap_al_obt_res_2 = p_fr_cap_al_obt_res_2, p_res_tech_chg_mlt = p_res_tech_chg_mlt)
        "Non-recoverable natural resource utilization";
        SystemDynamics.WorldDynamics.World3.Service_Sector_Investment Service_Sector_Investment1(t_policy_year = t_policy_year, p_avg_life_serv_cap_1 = p_avg_life_serv_cap_1, p_avg_life_serv_cap_2 = p_avg_life_serv_cap_2, p_serv_cap_out_ratio_1 = p_serv_cap_out_ratio_1, p_serv_cap_out_ratio_2 = p_serv_cap_out_ratio_2, service_capital_init = service_capital_init)
        "Service sector investment";
      equation
        connect(Food_Production1.tot_agric_invest,Arable_Land_Dynamics1.tot_agric_invest);
        connect(Food_Production1.yield_tech_mult_icor_COYM,Industrial_Investment1.yield_tech_mult_icor_COYM);
        connect(Arable_Land_Dynamics1.urban_ind_land,Human_Ecological_Footprint1.urban_ind_land);
        connect(Pollution_Dynamics1.ppoll_gen_rt,Human_Ecological_Footprint1.ppoll_gen_rt);
        connect(NR_Resource_Utilization1.s_fr_cap_al_obt_res,Industrial_Investment1.s_fr_cap_al_obt_res);
        connect(Labor_Utilization1.capital_util_fr,Industrial_Investment1.capital_util_fr);
        connect(NR_Resource_Utilization1.ind_cap_out_ratio_2_ICOR2T,Industrial_Investment1.ind_cap_out_ratio_2_ICOR2T);
        connect(Pollution_Dynamics1.ppoll_tech_mult_icor_COPM,Industrial_Investment1.ppoll_tech_mult_icor_COPM);
        connect(Labor_Utilization1.capital_util_fr,Service_Sector_Investment1.capital_util_fr);
        connect(Pollution_Dynamics1.s_yield_mlt_air_poll,Food_Production1.s_yield_mlt_air_poll);
        connect(Arable_Land_Dynamics1.fr_inp_al_land_dev,Food_Production1.fr_inp_al_land_dev);
        connect(Land_Fertility1.yield_tech_LYTD,Food_Production1.yield_tech_LYTD);
        connect(NR_Resource_Utilization1.pc_res_use_mlt,Pollution_Dynamics1.pc_res_use_mlt);
        connect(Human_Fertility1.life_expectancy,Population_Dynamics1.life_expectancy);
        connect(Human_Welfare_Index1.life_expectancy,Human_Fertility1.life_expectancy);
        connect(Life_Expectancy1.life_expectancy,Human_Welfare_Index1.life_expectancy);
        connect(Industrial_Investment1.industrial_capital,Labor_Utilization1.industrial_capital);
        connect(Human_Fertility1.total_fertility,Population_Dynamics1.total_fertility);
        connect(Population_Dynamics1.labor_force,Labor_Utilization1.labor_force);
        connect(Service_Sector_Investment1.s_fioa_serv,Industrial_Investment1.s_fioa_serv);
        connect(Food_Production1.p_fr_inp_for_land_maint,Land_Fertility1.p_fr_inp_for_land_maint);
        connect(Food_Production1.s_fioa_agr,Industrial_Investment1.s_fioa_agr);
        connect(Food_Production1.agr_inp_per_hect,Labor_Utilization1.agr_inp_per_hect);
        connect(Food_Production1.agr_inp_per_hect,Pollution_Dynamics1.agr_inp_per_hect);
        connect(Food_Production1.marg_prod_agr_inp,Arable_Land_Dynamics1.marg_prod_agr_inp);
        connect(Food_Production1.food_pc,Life_Expectancy1.food_pc);
        connect(Food_Production1.land_yield,Arable_Land_Dynamics1.land_yield);
        connect(Land_Fertility1.ppoll_index,Life_Expectancy1.ppoll_index);
        connect(Pollution_Dynamics1.ppoll_index,Land_Fertility1.ppoll_index);
        connect(Service_Sector_Investment1.serv_out_pc,Labor_Utilization1.serv_out_pc);
        connect(Service_Sector_Investment1.serv_out_pc,Human_Fertility1.serv_out_pc);
        connect(Industrial_Investment1.ind_out_pc,NR_Resource_Utilization1.ind_out_pc);
        connect(Industrial_Investment1.ind_out_pc,Life_Expectancy1.ind_out_pc);
        connect(Industrial_Investment1.ind_out_pc,Human_Welfare_Index1.ind_out_pc);
        connect(Human_Fertility1.ind_out_pc,Labor_Utilization1.ind_out_pc);
        connect(Industrial_Investment1.ind_out_pc,Human_Fertility1.ind_out_pc);
        connect(Food_Production1.ind_out_pc,Service_Sector_Investment1.ind_out_pc);
        connect(Arable_Land_Dynamics1.ind_out_pc,Food_Production1.ind_out_pc);
        connect(Industrial_Investment1.ind_out_pc,Arable_Land_Dynamics1.ind_out_pc);
        connect(Industrial_Investment1.industrial_output,NR_Resource_Utilization1.industrial_output);
        connect(Pollution_Dynamics1.industrial_output,Food_Production1.industrial_output);
        connect(Industrial_Investment1.industrial_output,Pollution_Dynamics1.industrial_output);
        connect(Labor_Utilization1.arable_land,Human_Ecological_Footprint1.arable_land);
        connect(Arable_Land_Dynamics1.arable_land,Labor_Utilization1.arable_land);
        connect(Pollution_Dynamics1.arable_land,Food_Production1.arable_land);
        connect(Arable_Land_Dynamics1.arable_land,Pollution_Dynamics1.arable_land);
        connect(Life_Expectancy1.population,NR_Resource_Utilization1.population);
        connect(Industrial_Investment1.population,Life_Expectancy1.population);
        connect(Population_Dynamics1.population,Industrial_Investment1.population);
        connect(Food_Production1.population,Service_Sector_Investment1.population);
        connect(Arable_Land_Dynamics1.population,Food_Production1.population);
        connect(Pollution_Dynamics1.population,Arable_Land_Dynamics1.population);
        connect(Population_Dynamics1.population,Pollution_Dynamics1.population);
        connect(Food_Production1.food_ratio,Land_Fertility1.food_ratio);
        connect(Life_Expectancy1.serv_out_pc,Labor_Utilization1.serv_out_pc);
        connect(Service_Sector_Investment1.service_capital,Labor_Utilization1.service_capital);
        connect(Land_Fertility1.land_fertility,Food_Production1.land_fertility);
        connect(Food_Production1.industrial_output,Service_Sector_Investment1.industrial_output);
        population = Population_Dynamics1.Population.y;
        food = Food_Production1.Food.food;
        industrial_output = Industrial_Investment1.Industrial_Output.industrial_output;
        ppoll_index = Pollution_Dynamics1.PPoll_Index.y;
        nr_resources = NR_Resource_Utilization1.NR_Resources.y;
        fioa_ind = Industrial_Investment1.FIOA_Ind.fioa_ind;
        s_fioa_agr = Food_Production1.S_FIOA_Agr.s_fioa_agr;
        s_fioa_cons = Industrial_Investment1.S_FIOA_Cons.s_fioa_cons;
        s_fioa_serv = Service_Sector_Investment1.S_FIOA_Serv.s_fioa_serv;
        s_fr_cap_al_obt_res = NR_Resource_Utilization1.S_Fr_Cap_Al_Obt_Res.s_fr_cap_al_obt_res;
        life_expectancy = Life_Expectancy1.Life_Expectancy.y;
        food_pc = Food_Production1.Food_PC.y;
        serv_out_pc = Service_Sector_Investment1.Serv_Out_PC.y;
        ind_out_pc = Industrial_Investment1.Ind_Out_PC.y;
        human_ecological_footprint = Human_Ecological_Footprint1.HEF_Human_Ecological_Footprint.hef_human_ecological_footprint;
        human_welfare_index = Human_Welfare_Index1.HWI_Human_Welfare_Index.hwi_human_welfare_index;
      end Scenario_1;

      package Utilities "Utility models of Meadows' WORLD3 model"
        extends Modelica.Icons.Library;

        block Agr_Inp_Per_Hect "Agricultural input per hectare"
          extends Interfaces.Nonlin_3;
          output Real p_fr_inp_for_land_maint
          "Fraction of agricultural investiment allocated to land maintenance";
          output Real arable_land(unit = "hectare") "Total arable land";
          output Real agr_inp(unit = "dollar/yr") "Agricultural input";
          output Real agr_inp_per_hect(unit = "dollar/(hectare.yr)")
          "Agricultural input per hectare";
        equation
          p_fr_inp_for_land_maint = u1;
          arable_land = u2;
          agr_inp = u3;
          agr_inp_per_hect = agr_inp * (1 - p_fr_inp_for_land_maint) / arable_land;
          y = agr_inp_per_hect;
        end Agr_Inp_Per_Hect;

        block BD_Rates "Birth and death rates"
          extends Interfaces.Nonlin_2;
          output Real bd(unit = "1/yr") "Total annual births or deaths";
          output Real pop "Total population";
          output Real bd_rate(unit = "1/yr") "Total annual birth or death rate";
        equation
          bd = u1;
          pop = u2;
          bd_rate = 1000 * bd / pop;
          y = bd_rate;
        end BD_Rates;

        block Birth_Factors "Birth factors of WORLD3 model"
          extends Interfaces.Nonlin_3;
          parameter Real Repro_Life(unit = "yr") = 30 "Reproductive lifetime";
          parameter Real t_pop_equil_time(unit = "yr") = 4000
          "Population equilibrium time";
          output Real tot_fert "Total fertility";
          output Real deaths "Total deaths";
          output Real pop_15_44 "Population between the ages of 15 and 44";
          output Real births "Total births";
        equation
          tot_fert = u1;
          deaths = u2;
          pop_15_44 = u3;
          births = if time > t_pop_equil_time then deaths else 0.5 * tot_fert * pop_15_44 / Repro_Life;
          y = births;
        end Birth_Factors;

        block Ch_Agr_Inp "Change in agricultural input"
          extends Interfaces.Nonlin_3;
          output Real current_agr_inp(unit = "dollar/yr")
          "Current agricultural input";
          output Real s_avg_life_agr_inp(unit = "yr")
          "Average life of agricultural input";
          output Real agr_inp(unit = "dollar/yr") "Agricultural input";
          output Real chg_agr_inp(unit = "dollar/yr2")
          "Change in agricultural input";
        equation
          current_agr_inp = u1;
          s_avg_life_agr_inp = u2;
          agr_inp = u3;
          chg_agr_inp = (current_agr_inp - agr_inp) / s_avg_life_agr_inp;
          y = chg_agr_inp;
        end Ch_Agr_Inp;

        block Ch_Lab_Util_Fr_Del "Change in delayed labor utilization fraction"
          extends Interfaces.Nonlin_2;
          parameter Real labor_util_fr_del_time(unit = "yr") = 2
          "Labor utilization fraction delay time";
          output Real labor_util_fr "Labor utilization fraction";
          output Real labor_util_fr_del "Delayed labor utilization fraction";
          output Real chg_lab_util_fr_del(unit = "1/yr")
          "Change in delayed labor utilization fraction";
        equation
          labor_util_fr = u1;
          labor_util_fr_del = u2;
          chg_lab_util_fr_del = (labor_util_fr - labor_util_fr_del) / labor_util_fr_del_time;
          y = chg_lab_util_fr_del;
        end Ch_Lab_Util_Fr_Del;

        block Ch_Perc_Food_Ratio "Change in perceived food ratio"
          extends Interfaces.Nonlin_2;
          parameter Real food_short_perc_del(unit = "yr") = 2
          "Food shortage perception delay";
          output Real food_ratio "Food ratio";
          output Real perc_food_ratio "Perceived food ratio";
          output Real chg_perc_food_ratio(unit = "1/yr")
          "Change in perceived food ratio";
        equation
          food_ratio = u1;
          perc_food_ratio = u2;
          chg_perc_food_ratio = (food_ratio - perc_food_ratio) / food_short_perc_del;
          y = chg_perc_food_ratio;
        end Ch_Perc_Food_Ratio;

        block Current_Agr_Inp "Current agricultural input"
          extends Interfaces.Nonlin_2;
          output Real fr_inp_al_land_dev
          "Fraction of agricultural input allocated to land development";
          output Real tot_agric_invest(unit = "dollar/yr")
          "Total agricultural investment";
          output Real current_agr_inp(unit = "dollar/yr")
          "Current agricultural input";
        equation
          fr_inp_al_land_dev = u1;
          tot_agric_invest = u2;
          current_agr_inp = tot_agric_invest * (1 - fr_inp_al_land_dev);
          y = current_agr_inp;
        end Current_Agr_Inp;

        block Death_Factors "Number of people dying from a given group"
          extends Interfaces.Nonlin_2;
          output Real pop "Population of previous group";
          output Real mort(unit = "1/yr")
          "Mortality rate of people in previous group";
          output Real deaths(unit = "1/yr") "Number of people dying per year";
        equation
          pop = u1;
          mort = u2;
          deaths = pop * mort;
          y = deaths;
        end Death_Factors;

        block Des_Compl_Fam_Size "Desired complete family size"
          extends Interfaces.Nonlin_2;
          parameter Real t_zero_pop_grow_time(unit = "yr") = 4000
          "Time to zero population growth";
          parameter Real des_compl_fam_size_norm = 3.8
          "Desired normal complete family size";
          output Real soc_fam_size_norm "Social family size norm";
          output Real fam_resp_to_soc_norm "Family response to social norm";
          output Real des_compl_fam_size "Desired complete family size";
        equation
          soc_fam_size_norm = u1;
          fam_resp_to_soc_norm = u2;
          des_compl_fam_size = if time > t_zero_pop_grow_time then 2.0 else des_compl_fam_size_norm * fam_resp_to_soc_norm * soc_fam_size_norm;
          y = des_compl_fam_size;
        end Des_Compl_Fam_Size;

        block Fam_Income_Expect "Expected family income"
          extends Interfaces.Nonlin_2;
          output Real ind_out_pc(unit = "dollar/yr")
          "Per capita industrial output";
          output Real avg_ind_out_pc(unit = "dollar/yr")
          "Average per capita industrial output";
          output Real fam_income_expect "Expected family income fraction";
        equation
          ind_out_pc = u1;
          avg_ind_out_pc = u2;
          fam_income_expect = max({-0.2,min({0.2,(ind_out_pc - avg_ind_out_pc) / avg_ind_out_pc})});
          y = fam_income_expect;
        end Fam_Income_Expect;

        block Fert_Cont_Eff "Effective fertility continuation"
          extends Interfaces.Nonlin_1;
          parameter Real t_fert_cont_eff_time(unit = "yr") = 4000
          "Year of continued fertility change";
          output Real fert_cont_eff_table
          "Effective fertility continuation table";
          output Real fert_cont_eff "Effective fertility continuation";
        equation
          fert_cont_eff_table = u;
          fert_cont_eff = if time > t_fert_cont_eff_time then 1.0 else fert_cont_eff_table;
          y = fert_cont_eff;
        end Fert_Cont_Eff;

        block FIOA_Ind "Fraction of industrial output allocated to industry"
          extends Interfaces.Nonlin_3;
          output Real s_fioa_agr
          "Fraction of industrial output allocated to agriculture";
          output Real s_fioa_serv
          "Fraction of industrial output allocated to the service sector";
          output Real s_fioa_cons
          "Fraction of industrial output allocated to consumption";
          output Real fioa_ind
          "Fraction of industrial output allocated to industry";
        equation
          s_fioa_agr = u1;
          s_fioa_serv = u2;
          s_fioa_cons = u3;
          fioa_ind = 1 - s_fioa_agr - s_fioa_serv - s_fioa_cons;
          y = fioa_ind;
        end FIOA_Ind;

        block Food "Total produced food"
          extends Interfaces.Nonlin_2;
          parameter Real land_fr_harvested = 0.7 "Land fraction harvested";
          parameter Real processing_loss = 0.1 "Processing loss";
          output Real land_yield(unit = "kg/(hectare.yr)") "Land yield";
          output Real arable_land(unit = "hectare") "Total arable land";
          output Real food(unit = "kg/yr") "Total produced food";
        equation
          land_yield = u1;
          arable_land = u2;
          food = land_yield * arable_land * land_fr_harvested * (1.0 - processing_loss);
          y = food;
        end Food;

        block GDP_Index "Gross domestic product index"
          extends Interfaces.Nonlin_1;
          output Real gdp_per_capita(unit = "dollar/yr")
          "Per capita gross domestic product";
          output Real gdp_index "Gross domestic product index";
        equation
          gdp_per_capita = u;
          gdp_index = (Modelica.Math.log10(gdp_per_capita) - Modelica.Math.log10(24.0)) / (Modelica.Math.log10(9508.0) - Modelica.Math.log10(24.0));
          y = gdp_index;
        end GDP_Index;

        block HEF_Human_Ecological_Footprint "Human ecological footprint"
          extends Interfaces.Nonlin_3;
          output Real arable_land_in_Gha(unit = "Gha")
          "Arable land in Gigahectare";
          output Real urban_land_in_Gha(unit = "Gha")
          "Urban land in Gigahectare";
          output Real absorption_land_in_Gha(unit = "Gha")
          "Absorption land in Gigahectare";
          output Real hef_human_ecological_footprint(unit = "hectare")
          "Human ecological footprint";
        equation
          arable_land_in_Gha = u1;
          urban_land_in_Gha = u2;
          absorption_land_in_Gha = u3;
          hef_human_ecological_footprint = (arable_land_in_Gha + urban_land_in_Gha + absorption_land_in_Gha) / 1.91;
          y = hef_human_ecological_footprint;
        end HEF_Human_Ecological_Footprint;

        block HWI_Human_Welfare_Index "Human welfare index"
          extends Interfaces.Nonlin_3;
          output Real life_expectancy_index "Life expectancy index";
          output Real education_index "Education index";
          output Real gdp_index "Gross domestic product index";
          output Real hwi_human_welfare_index "Human welfare index";
        equation
          life_expectancy_index = u1;
          education_index = u2;
          gdp_index = u3;
          hwi_human_welfare_index = (life_expectancy_index + education_index + gdp_index) / 3;
          y = hwi_human_welfare_index;
        end HWI_Human_Welfare_Index;

        block Industrial_Output "Industrial output"
          extends Interfaces.Nonlin_4;
          output Real s_fr_cap_al_obt_res
          "Fraction of capital allocated to obtaining resources";
          output Real capital_util_fr "Capital utilization fraction";
          output Real s_ind_cap_out_ratio(unit = "yr")
          "Industrial capital output ratio";
          output Real industrial_capital(unit = "dollar")
          "Capital invested in industry";
          output Real industrial_output(unit = "dollar/yr") "Industrial output";
        equation
          s_fr_cap_al_obt_res = u1;
          capital_util_fr = u2;
          s_ind_cap_out_ratio = u3;
          industrial_capital = u4;
          industrial_output = industrial_capital * (1 - s_fr_cap_al_obt_res) * capital_util_fr / s_ind_cap_out_ratio;
          y = industrial_output;
        end Industrial_Output;

        block Land_Devel_Rt "Land development rate"
          extends Interfaces.Nonlin_3;
          output Real dev_cost_per_hect(unit = "dollar/hectare")
          "Development cost per hectare";
          output Real fr_inp_al_land_dev
          "Percentage of land available for development";
          output Real tot_agric_invest(unit = "dollar/yr")
          "Total agricultural investment";
          output Real land_devel_rt(unit = "hectare/yr")
          "Land development rate";
        equation
          dev_cost_per_hect = u1;
          fr_inp_al_land_dev = u2;
          tot_agric_invest = u3;
          land_devel_rt = tot_agric_invest * fr_inp_al_land_dev / dev_cost_per_hect;
          y = land_devel_rt;
        end Land_Devel_Rt;

        block Land_Fert_Reg "Land fertility regeneration"
          extends Interfaces.Nonlin_2;
          parameter Real inherent_land_fert(unit = "kg/(hectare.yr)") = 600
          "Inherent land fertility";
          output Real land_fert_regen_time(unit = "yr")
          "Land fertility regeneration time";
          output Real land_fertility(unit = "kg/(hectare.yr)") "Land fertility";
          output Real land_fert_regen(unit = "kg/(hectare.yr2)")
          "Land fertility regeneration";
        equation
          land_fert_regen_time = u1;
          land_fertility = u2;
          land_fert_regen = (inherent_land_fert - land_fertility) / land_fert_regen_time;
          y = land_fert_regen;
        end Land_Fert_Reg;

        block Land_Rem_Urb_Ind_Use "Land removal for urban/industrial use"
          extends Interfaces.Nonlin_2;
          parameter Real urb_ind_land_dev_time(unit = "yr") = 10
          "Urban and industrial land development time";
          output Real urb_ind_land_req(unit = "hectare")
          "Required urban and industrial land";
          output Real urban_ind_land(unit = "hectare")
          "Urban and industrial land";
          output Real land_rem_urb_ind_use(unit = "hectare/yr")
          "Land removal for urban/industrial use";
        equation
          urb_ind_land_req = u1;
          urban_ind_land = u2;
          land_rem_urb_ind_use = (urb_ind_land_req - urban_ind_land) / urb_ind_land_dev_time;
          y = land_rem_urb_ind_use;
        end Land_Rem_Urb_Ind_Use;

        block Lifet_Mlt_Crowd "Life expectancy multiplier due to crowding"
          extends Interfaces.Nonlin_2;
          output Real crowd_mult_ind "Crowding multiplier index";
          output Real fr_pop_urban "Fraction of urban population";
          output Real lifet_mlt_crowd
          "Life expectancy multiplier due to crowding";
        equation
          crowd_mult_ind = u1;
          fr_pop_urban = u2;
          lifet_mlt_crowd = 1 - crowd_mult_ind * fr_pop_urban;
          y = lifet_mlt_crowd;
        end Lifet_Mlt_Crowd;

        block Lifet_Mult_Hlth_Serv
        "Life expectancy multiplier due to health services"
          extends Interfaces.Nonlin_2;
          output Real lifet_mlt_hlth_serv_1
          "Original life expectancy multiplier due to health services";
          output Real lifet_mlt_hlth_serv_2
          "Improved life expectancy multiplier due to health services";
          output Real lifet_mult_hlth_serv
          "Life expectancy multiplier due to health services";
        equation
          lifet_mlt_hlth_serv_1 = u1;
          lifet_mlt_hlth_serv_2 = u2;
          lifet_mult_hlth_serv = if time > 1940 then lifet_mlt_hlth_serv_2 else lifet_mlt_hlth_serv_1;
          y = lifet_mult_hlth_serv;
        end Lifet_Mult_Hlth_Serv;

        block Marg_Prod_Agr_Inp
        "Agricultural input for marginally producing land"
          extends Interfaces.Nonlin_4;
          output Real land_yield(unit = "kg/(hectare.yr)") "Total land yield";
          output Real land_yield_mlt_cap "Land yield multiplier from capital";
          output Real marg_land_yield_mlt_cap(unit = "hectare/dollar")
          "Marginal land yield multiplier from capital";
          output Real s_avg_life_agr_inp(unit = "yr")
          "Average life of agricultural input";
          output Real marg_prod_agr_inp(unit = "kg/dollar")
          "Marginal productivity of agricultural inputs";
        equation
          land_yield = u1;
          land_yield_mlt_cap = u2;
          marg_land_yield_mlt_cap = u3;
          s_avg_life_agr_inp = u4;
          marg_prod_agr_inp = s_avg_life_agr_inp * land_yield * marg_land_yield_mlt_cap / land_yield_mlt_cap;
          y = marg_prod_agr_inp;
        end Marg_Prod_Agr_Inp;

        block Marg_Prod_Land_Dev "Development of marginally producing land"
          extends Interfaces.Nonlin_2;
          parameter Real social_discount(unit = "1/yr") = 0.07
          "Social discount";
          output Real land_yield(unit = "kg/(hectare.yr)") "Land yield";
          output Real dev_cost_per_hect(unit = "dollar/hectare")
          "Development cost per hectare";
          output Real marg_prod_land_dev(unit = "kg/dollar")
          "Marginal productivity of land development";
        equation
          land_yield = u1;
          dev_cost_per_hect = u2;
          marg_prod_land_dev = land_yield / (dev_cost_per_hect * social_discount);
          y = marg_prod_land_dev;
        end Marg_Prod_Land_Dev;

        block Matur_Factors "Number of people switching groups"
          extends Interfaces.Nonlin_2;
          parameter Real bracket(unit = "yr") = 1
          "Time bracket of previous group";
          output Real pop "Population of previous group";
          output Real mort "Mortality rate of people in previous group";
          output Real matur(unit = "1/yr") "Number of people switching groups";
        equation
          pop = u1;
          mort = u2;
          matur = pop * (1 - mort) / bracket;
          y = matur;
        end Matur_Factors;

        block Need_For_Fert_Cont "Need for fertility continuation"
          extends Interfaces.Nonlin_2;
          output Real max_tot_fert "Maximal total fertility";
          output Real des_tot_fert "Desired total fertility";
          output Real need_for_fert_cont "Need for fertility continuation";
        equation
          max_tot_fert = u1;
          des_tot_fert = u2;
          need_for_fert_cont = max({0,min({10,max_tot_fert / des_tot_fert - 1.0})});
          y = need_for_fert_cont;
        end Need_For_Fert_Cont;

        block P_PPoll_Tech_Chg
        "Percentage of effective pollution technology change"
          extends Interfaces.Nonlin_1;
          parameter Real des_ppoll_index_DPOLX = 1.2
          "Desired persistent pollution index";
          output Real ppoll_index "Persistent pollution index";
          output Real p_ppoll_tech_chg
          "Percentage of effective pollution technology change";
        equation
          ppoll_index = u;
          p_ppoll_tech_chg = 1 - ppoll_index / des_ppoll_index_DPOLX;
          y = p_ppoll_tech_chg;
        end P_PPoll_Tech_Chg;

        block P_Res_Tech_Chg
        "Percentage of effective resource technology change"
          extends Interfaces.Nonlin_1;
          parameter Real des_res_use_rt_DNRUR(unit = "ton/yr") = 4800000000.0
          "Desired resource utilization rate";
          output Real nr_res_use_rate(unit = "ton/yr")
          "Non-recoverable resource utilization rate";
          output Real p_res_tech_chg
          "Percentage of effective resource technology change";
        equation
          nr_res_use_rate = u;
          p_res_tech_chg = 1 - nr_res_use_rate / des_res_use_rt_DNRUR;
          y = p_res_tech_chg;
        end P_Res_Tech_Chg;

        block Poll_Intens_Ind "Pollution intensity index"
          extends Interfaces.Nonlin_3;
          output Real industrial_output(unit = "dollar/yr") "Industrial output";
          output Real ppoll_gen_ind(unit = "1/yr") "Persistent pollution index";
          output Real s_ppoll_gen_fact "Pollution generation factor";
          output Real poll_intens_ind(unit = "1/dollar")
          "Pollution intensity index";
        equation
          industrial_output = u1;
          ppoll_gen_ind = u2;
          s_ppoll_gen_fact = u3;
          poll_intens_ind = ppoll_gen_ind * s_ppoll_gen_fact / industrial_output;
          y = poll_intens_ind;
        end Poll_Intens_Ind;

        block PPoll_Assim_Rt "Persistent pollution assimilation rate"
          extends Interfaces.Nonlin_2;
          output Real pers_pollution "Persistent pollution";
          output Real assim_half_life(unit = "yr")
          "Persistent pollution assimilation half-life";
          output Real ppoll_assim_rt(unit = "1/yr")
          "Persistent pollution assimilation rate";
        equation
          pers_pollution = u1;
          assim_half_life = u2;
          ppoll_assim_rt = pers_pollution / (1.4 * assim_half_life);
          y = ppoll_assim_rt;
        end PPoll_Assim_Rt;

        block PPoll_Gen_Agr
        "Persistent pollution generated by agricultural output"
          extends Interfaces.Nonlin_2;
          parameter Real agr_mtl_toxic_index(unit = "1/dollar") = 1
          "Agricultural materials toxicity index";
          parameter Real fr_agr_inp_pers_mtl = 0.001
          "Effective fraction of agricultural pollution input";
          output Real agr_inp_per_hect(unit = "dollar/(hectare.yr)")
          "Agricultural input per hectare";
          output Real arable_land(unit = "hectare") "Total arable land";
          output Real ppoll_gen_agr(unit = "1/yr")
          "Persistent pollution generated by agricultural output";
        equation
          agr_inp_per_hect = u1;
          arable_land = u2;
          ppoll_gen_agr = agr_inp_per_hect * arable_land * fr_agr_inp_pers_mtl * agr_mtl_toxic_index;
          y = ppoll_gen_agr;
        end PPoll_Gen_Agr;

        block PPoll_Gen_Ind
        "Persistent pollution generated by industrial output"
          extends Interfaces.Nonlin_2;
          parameter Real frac_res_pers_mtl = 0.02
          "Fraction of resources as persistent materials";
          parameter Real ind_mtl_emiss_fact(unit = "1/ton") = 0.1
          "Industrial materials emission factor";
          parameter Real ind_mtl_toxic_index = 10.0
          "Industrial materials toxicity index";
          output Real pc_res_use_mlt(unit = "ton/yr")
          "Per capita resource utilization multiplier";
          output Real population "Total population";
          output Real ppoll_gen_ind(unit = "1/yr")
          "Persistent pollution generated by industrial output";
        equation
          pc_res_use_mlt = u1;
          population = u2;
          ppoll_gen_ind = pc_res_use_mlt * population * frac_res_pers_mtl * ind_mtl_emiss_fact * ind_mtl_toxic_index;
          y = ppoll_gen_ind;
        end PPoll_Gen_Ind;

        block PPoll_Gen_Rt "Persistent pollution generation rate"
          extends Interfaces.Nonlin_3;
          output Real s_ppoll_gen_fact
          "Percentage of effective persistent pollution generation";
          output Real ppoll_gen_ind(unit = "1/yr")
          "Persistent pollution generation from industry";
          output Real ppoll_gen_agr(unit = "1/yr")
          "Persistent pollution generation from agriculture";
          output Real ppoll_gen_rt(unit = "1/yr")
          "Persistent pollution generation rate";
        equation
          s_ppoll_gen_fact = u1;
          ppoll_gen_ind = u2;
          ppoll_gen_agr = u3;
          ppoll_gen_rt = (ppoll_gen_ind + ppoll_gen_agr) * s_ppoll_gen_fact;
          y = ppoll_gen_rt;
        end PPoll_Gen_Rt;

        block PPoll_Tech_Chg_Rt "Persistent pollution technology change rate"
          extends Interfaces.Nonlin_2;
          parameter Real t_policy_year(unit = "yr") = 4000
          "Year of policy change";
          output Real p_ppoll_tech_chg_mlt_POLGFM
          "Percentage of effective technology change on pollution generation";
          output Real ppoll_tech_PTD(unit = "1/yr")
          "Persistent pollution technology change factor";
          output Real ppoll_tech_chg_rt(unit = "1/yr")
          "Persistent pollution technology change rate";
        equation
          p_ppoll_tech_chg_mlt_POLGFM = u1;
          ppoll_tech_PTD = u2;
          ppoll_tech_chg_rt = if time > t_policy_year then p_ppoll_tech_chg_mlt_POLGFM * ppoll_tech_PTD else 0;
          y = ppoll_tech_chg_rt;
        end PPoll_Tech_Chg_Rt;

        block Res_Tech_Ch_Rt_NRATE
        "Non-recoverable resource technology change rate"
          extends Interfaces.Nonlin_2;
          parameter Real t_policy_year(unit = "yr") = 4000
          "Year of policy change";
          output Real p_res_tech_chg_mlt_NRCM
          "Percentage of effective technology change";
          output Real res_tech_NRTD(unit = "1/yr")
          "Non-recoverable resource technology change factor";
          output Real res_tech_ch_rt_NRATE(unit = "1/yr")
          "Non-recoverable resource technology change rate";
        equation
          p_res_tech_chg_mlt_NRCM = u1;
          res_tech_NRTD = u2;
          res_tech_ch_rt_NRATE = if time > t_policy_year then p_res_tech_chg_mlt_NRCM * res_tech_NRTD else 0;
          y = res_tech_ch_rt_NRATE;
        end Res_Tech_Ch_Rt_NRATE;

        block S_Avg_Life_Agr_Inp "Average life of service sector capital"
          extends Interfaces.Nonlin_0;
          parameter Real t_policy_year(unit = "yr") = 4000
          "Year of policy change";
          parameter Real p_avg_life_agr_inp_1(unit = "yr") = 2
          "Default average life of agricultural input";
          parameter Real p_avg_life_agr_inp_2(unit = "yr") = 2
          "Controlled average life of agricultural input";
          output Real s_avg_life_agr_inp(unit = "yr")
          "Average life of agricultural input";
        equation
          s_avg_life_agr_inp = if time > t_policy_year then p_avg_life_agr_inp_2 else p_avg_life_agr_inp_1;
          y = s_avg_life_agr_inp;
        end S_Avg_Life_Agr_Inp;

        block S_Avg_Life_Ind_Cap "Average life of industrial capital"
          extends Interfaces.Nonlin_0;
          parameter Real t_policy_year(unit = "yr") = 4000
          "Year of policy change";
          parameter Real p_avg_life_ind_cap_1(unit = "yr") = 14
          "Default average life of industrial capital";
          parameter Real p_avg_life_ind_cap_2(unit = "yr") = 14
          "Controlled average life of industrial capital";
          output Real s_avg_life_ind_cap(unit = "yr")
          "Average life of industrial capital";
        equation
          s_avg_life_ind_cap = if time > t_policy_year then p_avg_life_ind_cap_2 else p_avg_life_ind_cap_1;
          y = s_avg_life_ind_cap;
        end S_Avg_Life_Ind_Cap;

        block S_Avg_Life_Serv_Cap "Average life of service sector capital"
          extends Interfaces.Nonlin_0;
          parameter Real t_policy_year(unit = "yr") = 4000
          "Year of policy change";
          parameter Real p_avg_life_serv_cap_1(unit = "yr") = 20
          "Default average life of service sector capital";
          parameter Real p_avg_life_serv_cap_2(unit = "yr") = 20
          "Controlled average life of service sector capital";
          output Real s_avg_life_serv_cap(unit = "yr")
          "Average life of service sector capital";
        equation
          s_avg_life_serv_cap = if time > t_policy_year then p_avg_life_serv_cap_2 else p_avg_life_serv_cap_1;
          y = s_avg_life_serv_cap;
        end S_Avg_Life_Serv_Cap;

        block S_FIOA_Agr
        "Fraction of industrial output allocated to agricultural sector"
          extends Interfaces.Nonlin_2;
          parameter Real t_policy_year(unit = "yr") = 4000
          "Year of policy change";
          output Real p_fr_io_al_agr_1
          "Default fraction of industrial output allocated to agricultural sector";
          output Real p_fr_io_al_agr_2
          "Controlled fraction of industrial output allocated to agricultural sector";
          output Real s_fioa_agr
          "Fraction of industrial output allocated to agricultural sector";
        equation
          p_fr_io_al_agr_1 = u1;
          p_fr_io_al_agr_2 = u2;
          s_fioa_agr = if time > t_policy_year then p_fr_io_al_agr_2 else p_fr_io_al_agr_1;
          y = s_fioa_agr;
        end S_FIOA_Agr;

        block S_FIOA_Cons
        "Fraction of industrial output allocated to consumption"
          extends Interfaces.Nonlin_2;
          parameter Real t_ind_equil_time(unit = "yr") = 4000
          "Year of industrial equilibrium";
          output Real s_fioa_cons_const
          "Original capital allocation to resource use efficiency";
          output Real p_fioa_cons_var
          "Modified capital allocation to resource use efficiency";
          output Real s_fioa_cons
          "Fraction of industrial output allocated to consumption";
        equation
          s_fioa_cons_const = u1;
          p_fioa_cons_var = u2;
          s_fioa_cons = if time > t_ind_equil_time then p_fioa_cons_var else s_fioa_cons_const;
          y = s_fioa_cons;
        end S_FIOA_Cons;

        block S_FIOA_Cons_Const
        "Fraction of industrial output allocated to consumption"
          extends Interfaces.Nonlin_0;
          parameter Real t_policy_year(unit = "yr") = 4000
          "Year of policy change";
          parameter Real p_fioa_cons_const_1 = 0.43
          "Default fraction of industrial output allocated to consumption";
          parameter Real p_fioa_cons_const_2 = 0.43
          "Controlled fraction of industrial output allocated to consumption";
          output Real s_fioa_cons_const
          "Fraction of industrial output allocated to consumption";
        equation
          s_fioa_cons_const = if time > t_policy_year then p_fioa_cons_const_2 else p_fioa_cons_const_1;
          y = s_fioa_cons_const;
        end S_FIOA_Cons_Const;

        block S_FIOA_Serv
        "Fraction of industrial output allocated to service sector"
          extends Interfaces.Nonlin_2;
          parameter Real t_policy_year(unit = "yr") = 4000
          "Year of policy change";
          output Real p_fr_io_al_serv_1
          "Default fraction of industrial output allocated to service sector";
          output Real p_fr_io_al_serv_2
          "Controlled fraction of industrial output allocated to service sector";
          output Real s_fioa_serv
          "Fraction of industrial output allocated to service sector";
        equation
          p_fr_io_al_serv_1 = u1;
          p_fr_io_al_serv_2 = u2;
          s_fioa_serv = if time > t_policy_year then p_fr_io_al_serv_2 else p_fr_io_al_serv_1;
          y = s_fioa_serv;
        end S_FIOA_Serv;

        block S_Fr_Cap_Al_Obt_Res
        "Fraction of capital allocated to resource use efficiency"
          extends Interfaces.Nonlin_2;
          parameter Real t_fcaor_time(unit = "yr") = 4000
          "Year of capital allocation to resource use efficiency";
          output Real p_fr_cap_al_obt_res_1
          "Original capital allocation to resource use efficiency";
          output Real p_fr_cap_al_obt_res_2
          "Modified capital allocation to resource use efficiency";
          output Real s_fr_cap_al_obt_res
          "Fraction of capital allocated to resource use efficiency";
        equation
          p_fr_cap_al_obt_res_1 = u1;
          p_fr_cap_al_obt_res_2 = u2;
          s_fr_cap_al_obt_res = if time > t_fcaor_time then p_fr_cap_al_obt_res_2 else p_fr_cap_al_obt_res_1;
          y = s_fr_cap_al_obt_res;
        end S_Fr_Cap_Al_Obt_Res;

        block S_Ind_Cap_Out_Ratio "Industrial capital output ratio"
          extends Interfaces.Nonlin_1;
          parameter Real t_policy_year(unit = "yr") = 4000
          "Year of policy change";
          parameter Real p_ind_cap_out_ratio_1(unit = "yr") = 3
          "Default industrial capital output ratio";
          output Real p_ind_cap_out_ratio_2(unit = "yr")
          "Controlled industrial capital output ratio";
          output Real s_ind_cap_out_ratio(unit = "yr")
          "Industrial capital output ratio";
        equation
          p_ind_cap_out_ratio_2 = u;
          s_ind_cap_out_ratio = if time > t_policy_year then p_ind_cap_out_ratio_2 else p_ind_cap_out_ratio_1;
          y = s_ind_cap_out_ratio;
        end S_Ind_Cap_Out_Ratio;

        block S_Indic_Food_PC "Indicated food per capita"
          extends Interfaces.Nonlin_2;
          parameter Real t_policy_year(unit = "yr") = 4000
          "Year of policy change";
          output Real p_indic_food_pc_1(unit = "kg/yr")
          "Default indicated food per capita";
          output Real p_indic_food_pc_2(unit = "kg/yr")
          "Controlled indicated food per capita";
          output Real s_indic_food_pc(unit = "kg/yr")
          "Indicated food per capita";
        equation
          p_indic_food_pc_1 = u1;
          p_indic_food_pc_2 = u2;
          s_indic_food_pc = if time > t_policy_year then p_indic_food_pc_2 else p_indic_food_pc_1;
          y = s_indic_food_pc;
        end S_Indic_Food_PC;

        block S_Indic_Serv_PC
        "Fraction of per capita indicated output allocated to service sector"
          extends Interfaces.Nonlin_2;
          parameter Real t_policy_year(unit = "yr") = 4000
          "Year of policy change";
          output Real p_indic_serv_pc_1(unit = "dollar/yr")
          "Default fraction of per capita indicated output allocated to service sector";
          output Real p_indic_serv_pc_2(unit = "dollar/yr")
          "Controlled fraction of per capita indicated output allocated to service sector";
          output Real s_indic_serv_pc(unit = "dollar/yr")
          "Fraction of per capita indicated output allocated to service sector";
        equation
          p_indic_serv_pc_1 = u1;
          p_indic_serv_pc_2 = u2;
          s_indic_serv_pc = if time > t_policy_year then p_indic_serv_pc_2 else p_indic_serv_pc_1;
          y = s_indic_serv_pc;
        end S_Indic_Serv_PC;

        block S_Land_Life_Mlt_Yield "Land Life Yield Factor"
          extends Interfaces.Nonlin_2;
          constant Real time_unit(unit = "yr") = 1 "Unit conversion constant";
          parameter Real t_land_life_time(unit = "yr") = 4000 "Land life time";
          output Real p_land_life_mlt_yield_1
          "Percentage of land with multiple yield - first model";
          output Real p_land_life_mlt_yield_2
          "Percentage of land with multiple yield - second model";
          output Real s_land_life_mlt_yield "Land Life Yield Factor";
      protected
          Real k "Homotopy factor";
        equation
          p_land_life_mlt_yield_1 = u1;
          p_land_life_mlt_yield_2 = u2;
          if time > t_land_life_time then
            k = 0.95 ^ ((time - t_land_life_time) / time_unit);
          else
            k = 1;
          end if;
          s_land_life_mlt_yield = k * p_land_life_mlt_yield_1 + (1 - k) * p_land_life_mlt_yield_2;
          y = s_land_life_mlt_yield;
        end S_Land_Life_Mlt_Yield;

        block S_Land_Yield_Fact "Land yield factor"
          extends Interfaces.Nonlin_1;
          parameter Real t_policy_year(unit = "yr") = 4000
          "Year of policy change";
          parameter Real p_land_yield_fact_1 = 1 "Default land yield factor";
          output Real p_land_yield_fact_2 "Controlled land yield factor";
          output Real s_land_yield_fact "Land yield factor";
        equation
          p_land_yield_fact_2 = u;
          s_land_yield_fact = if time > t_policy_year then p_land_yield_fact_2 else p_land_yield_fact_1;
          y = s_land_yield_fact;
        end S_Land_Yield_Fact;

        block S_NR_Res_Use_Fact "Non-recoverable resource utilization factor"
          extends Interfaces.Nonlin_1;
          parameter Real t_policy_year(unit = "yr") = 4000
          "Year of policy change";
          parameter Real p_nr_res_use_fact_1 = 1
          "Default non-recoverable resource utilization factor";
          output Real p_nr_res_use_fact_2
          "Controlled non-recoverable resource utilization factor";
          output Real s_nr_res_use_fact
          "Non-recoverable resource utilization factor";
        equation
          p_nr_res_use_fact_2 = u;
          s_nr_res_use_fact = if time > t_policy_year then p_nr_res_use_fact_2 else p_nr_res_use_fact_1;
          y = s_nr_res_use_fact;
        end S_NR_Res_Use_Fact;

        block S_PPoll_Gen_Fact "Persistent pollution generation factor"
          extends Interfaces.Nonlin_1;
          parameter Real t_policy_year(unit = "yr") = 4000
          "Year of policy change";
          parameter Real p_ppoll_gen_fact_1 = 1
          "Default persistent pollution generation factor";
          output Real p_ppoll_gen_fact_2
          "Controlled persistent pollution generation factor";
          output Real s_ppoll_gen_fact "Persistent pollution generation factor";
        equation
          p_ppoll_gen_fact_2 = u;
          s_ppoll_gen_fact = if time > t_policy_year then p_ppoll_gen_fact_2 else p_ppoll_gen_fact_1;
          y = s_ppoll_gen_fact;
        end S_PPoll_Gen_Fact;

        block S_Serv_Cap_Out_Ratio "Service sector capital output ratio"
          extends Interfaces.Nonlin_0;
          parameter Real t_policy_year(unit = "yr") = 4000
          "Year of policy change";
          parameter Real p_serv_cap_out_ratio_1(unit = "yr") = 1.0
          "Default fraction of service sector output ratio";
          parameter Real p_serv_cap_out_ratio_2(unit = "yr") = 1.0
          "Controlled fraction of service sector output ratio";
          output Real s_serv_cap_out_ratio(unit = "yr")
          "Service sector capital output ratio";
        equation
          s_serv_cap_out_ratio = if time > t_policy_year then p_serv_cap_out_ratio_2 else p_serv_cap_out_ratio_1;
          y = s_serv_cap_out_ratio;
        end S_Serv_Cap_Out_Ratio;

        block S_Yield_Mlt_Air_Poll "Air pollution factor on agricultural yield"
          extends Interfaces.Nonlin_2;
          parameter Real t_air_poll_time(unit = "yr") = 4000
          "Air pollution change time";
          output Real p_yield_mlt_air_poll_1
          "Default air pollution factor on agricultural yield";
          output Real p_yield_mlt_air_poll_2
          "Controlled air pollution factor on agricultural yield";
          output Real s_yield_mlt_air_poll
          "Air pollution factor on agricultural yield";
        equation
          p_yield_mlt_air_poll_1 = u1;
          p_yield_mlt_air_poll_2 = u2;
          s_yield_mlt_air_poll = if time > t_air_poll_time then p_yield_mlt_air_poll_2 else p_yield_mlt_air_poll_1;
          y = s_yield_mlt_air_poll;
        end S_Yield_Mlt_Air_Poll;

        block Service_Output "Service sector output"
          extends Interfaces.Nonlin_3;
          output Real capital_util_fr "Fraction of capacity utilization";
          output Real s_serv_cap_out_ratio(unit = "yr")
          "Service sector capital output ratio";
          output Real service_capital(unit = "dollar")
          "Capital invested in the service sector";
          output Real service_output(unit = "dollar/yr")
          "Service sector output";
        equation
          capital_util_fr = u1;
          s_serv_cap_out_ratio = u2;
          service_capital = u3;
          service_output = service_capital * capital_util_fr / s_serv_cap_out_ratio;
          y = service_output;
        end Service_Output;

        block Total_Fertility "Total fertility"
          extends Interfaces.Nonlin_3;
          output Real fert_cont_eff "Fertility control effectiveness";
          output Real max_tot_fert "Maximum total fertility";
          output Real des_tot_fert "Desired total fertility";
          output Real total_fertility "Total fertility";
        equation
          fert_cont_eff = u1;
          max_tot_fert = u2;
          des_tot_fert = u3;
          total_fertility = min({max_tot_fert,fert_cont_eff * des_tot_fert + (1 - fert_cont_eff) * max_tot_fert});
          y = total_fertility;
        end Total_Fertility;

        block Yield_Tech_Chg_Rt "Yield technology change rate"
          extends Interfaces.Nonlin_2;
          parameter Real t_policy_year(unit = "yr") = 4000
          "Year of policy change";
          output Real p_yield_tech_chg_mlt_LYCM
          "Yield technology change factor";
          output Real yield_tech_LYTD "Yield technology";
          output Real yield_tech_chg_rt(unit = "1/yr")
          "Yield technology change rate";
        equation
          p_yield_tech_chg_mlt_LYCM = u1;
          yield_tech_LYTD = u2;
          yield_tech_chg_rt = if time > t_policy_year then p_yield_tech_chg_mlt_LYCM * yield_tech_LYTD else 0;
          y = yield_tech_chg_rt;
        end Yield_Tech_Chg_Rt;
      end Utilities;
    end World3;
  end WorldDynamics;
end SystemDynamics;
model SystemDynamics_WorldDynamics_World3_Scenario_1
 extends SystemDynamics.WorldDynamics.World3.Scenario_1;
  annotation(experiment(StartTime=1900, StopTime=2100),uses(SystemDynamics(version="2.1")));
end SystemDynamics_WorldDynamics_World3_Scenario_1;
