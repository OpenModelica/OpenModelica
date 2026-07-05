package BL "openScaling Swegon  demonstrator Buildingslibrary based"
  package Examples
    extends Modelica.Icons.ExamplesPackage;

    package Basic
      model Example2
        extends Modelica.Icons.Example;
        extends BaseClasses.BasicBase;
        Buildings.Fluid.Sources.Boundary_pT sin(redeclare package Medium = Medium, T = 273.15 + 10, p(displayUnit = "Pa") = 101325, nPorts = 1) "Pressure boundary condition";
        Buildings.Fluid.Movers.FlowControlled_m_flow mov(redeclare package Medium = Medium, redeclare Buildings.Fluid.Movers.Data.Fans.Greenheck.BIDW12 per, show_T = true, m_flow_nominal = 1);
        Buildings.Fluid.FixedResistances.PressureDrop res(redeclare package Medium = Medium, m_flow_nominal = 0.2, dp_nominal = 10) "Fixed resistance";
        Modelica.Blocks.Sources.Constant const(k = 1);
        Buildings.Fluid.Sources.Boundary_pT sou(redeclare package Medium = Buildings.Media.Air, T = 273.15 + 20, nPorts = 1) "Pressure boundary condition";
      equation
        connect(res.port_b, mov.port_a);
        connect(mov.port_b, sin.ports[1]);
        connect(const.y, mov.m_flow_in);
        connect(sou.ports[1], res.port_a);
      end Example2;

      package BaseClasses
        extends Modelica.Icons.BasesPackage;

        model BasicBase
          replaceable package Medium = Buildings.Media.Air constrainedby Modelica.Media.Interfaces.PartialMedium;
        end BasicBase;
      end BaseClasses;
    end Basic;
  end Examples;
  annotation(version = "1");
end BL;

package ModelicaServices "ModelicaServices (OpenModelica implementation) - Models and functions used in the Modelica Standard Library requiring a tool specific implementation"
  extends Modelica.Icons.Package;

  package Machine "Machine dependent constants"
    extends Modelica.Icons.Package;
    final constant Real eps = 2.2204460492503131e-016 "The difference between 1 and the least value greater than 1 that is representable in the given floating point type";
    final constant Real small = 2.2250738585072014e-308 "Minimum normalized positive floating-point number";
    final constant Real inf = 1e60 "Maximum representable finite floating-point number";
    final constant Integer Integer_inf = OpenModelica.Internal.Architecture.integerMax() "Biggest Integer number such that Integer_inf and -Integer_inf are representable on the machine";
  end Machine;
  annotation(version = "4.1.0", versionDate = "2025-05-23", dateModified = "2025-05-23 15:00:00Z");
end ModelicaServices;

package Modelica "Modelica Standard Library"
  extends Modelica.Icons.Package;

  package Blocks "Library of basic input/output control blocks (continuous, discrete, logical, table blocks)"
    extends Modelica.Icons.Package;
    import Modelica.Units.SI;

    package Interfaces "Library of connectors and partial models for input/output blocks"
      extends Modelica.Icons.InterfacesPackage;
      connector RealInput = input Real "'input Real' as connector";
      connector RealOutput = output Real "'output Real' as connector";
      connector IntegerInput = input Integer "'input Integer' as connector";

      partial block SO "Single Output continuous control block"
        extends Modelica.Blocks.Icons.Block;
        RealOutput y "Connector of Real output signal";
      end SO;

      partial block SISO "Single Input Single Output continuous control block"
        extends Modelica.Blocks.Icons.Block;
        RealInput u "Connector of Real input signal";
        RealOutput y "Connector of Real output signal";
      end SISO;

      partial block SI2SO "2 Single Input / 1 Single Output continuous control block"
        extends Modelica.Blocks.Icons.Block;
        RealInput u1 "Connector of Real input signal 1";
        RealInput u2 "Connector of Real input signal 2";
        RealOutput y "Connector of Real output signal";
      end SI2SO;

      partial block MISO "Multiple Input Single Output continuous control block"
        extends Modelica.Blocks.Icons.Block;
        parameter Integer nin = 1 "Number of inputs";
        RealInput u[nin] "Connector of Real input signals";
        RealOutput y "Connector of Real output signal";
      end MISO;
    end Interfaces;

    package Math "Library of Real mathematical functions as input/output blocks"
      import Modelica.Blocks.Interfaces;
      extends Modelica.Icons.Package;

      block Add "Output the sum of the two inputs"
        extends Interfaces.SI2SO;
        parameter Real k1 = +1 "Gain of input signal 1";
        parameter Real k2 = +1 "Gain of input signal 2";
      equation
        y = k1*u1 + k2*u2;
      end Add;
    end Math;

    package Nonlinear "Library of discontinuous or non-differentiable algebraic control blocks"
      import Modelica.Blocks.Interfaces;
      extends Modelica.Icons.Package;

      block SlewRateLimiter "Limits the slew rate of a signal"
        extends Modelica.Blocks.Interfaces.SISO;
        import Modelica.Constants.small;
        parameter Real Rising(min = small) = 1 "Maximum rising slew rate [+small..+inf) [1/s]";
        parameter Real Falling(max = -small) = -Rising "Maximum falling slew rate (-inf..-small] [1/s]";
        parameter SI.Time Td(min = small) = 0.001 "Derivative time constant";
        parameter Modelica.Blocks.Types.Init initType = Modelica.Blocks.Types.Init.SteadyState "Type of initialization (SteadyState implies y = u)" annotation(Evaluate = true);
        parameter Real y_start = 0 "Initial or guess value of output (= state)";
        parameter Boolean strict = false "= true, if strict limits with noEvent(..)" annotation(Evaluate = true);
      protected
        Real val = (u - y)/Td;
      initial equation
        if initType == Modelica.Blocks.Types.Init.SteadyState then
          y = u;
        elseif initType == Modelica.Blocks.Types.Init.InitialState or initType == Modelica.Blocks.Types.Init.InitialOutput then
          y = y_start;
        end if;
      equation
        if strict then
          der(y) = smooth(1, (if noEvent(val < Falling) then Falling else if noEvent(val > Rising) then Rising else val));
        else
          der(y) = if val < Falling then Falling else if val > Rising then Rising else val;
        end if;
      end SlewRateLimiter;
    end Nonlinear;

    package Routing "Library of blocks to combine and extract signals"
      extends Modelica.Icons.Package;

      model RealPassThrough "Pass a Real signal through without modification"
        extends Modelica.Blocks.Interfaces.SISO;
      equation
        y = u;
      end RealPassThrough;
    end Routing;

    package Sources "Library of signal source blocks generating Real, Integer and Boolean signals"
      import Modelica.Blocks.Interfaces;
      extends Modelica.Icons.SourcesPackage;

      block RealExpression "Set output signal to a time varying Real expression"
        Modelica.Blocks.Interfaces.RealOutput y = 0.0 "Value of Real output";
      end RealExpression;

      block Constant "Generate constant signal of type Real"
        parameter Real k(start = 1) "Constant output value";
        extends Interfaces.SO;
      equation
        y = k;
      end Constant;
    end Sources;

    package Types "Library of constants, external objects and types with choices, especially to build menus"
      extends Modelica.Icons.TypesPackage;
      type Init = enumeration(NoInit "No initialization (start values are used as guess values with fixed=false)", SteadyState "Steady state initialization (derivatives of states are zero)", InitialState "Initialization with initial states", InitialOutput "Initialization with initial outputs (and steady state of the states if possible)") "Enumeration defining initialization of a block" annotation(Evaluate = true);
    end Types;

    package Icons "Icons for Blocks"
      extends Modelica.Icons.IconsPackage;

      partial block Block "Basic graphical layout of input/output block" end Block;
    end Icons;
  end Blocks;

  package Fluid "Library of 1-dim. thermo-fluid flow models using the Modelica.Media media description"
    extends Modelica.Icons.Package;
    import Modelica.Units.SI;
    import Cv = Modelica.Units.Conversions;

    package Vessels "Devices for storing fluid"
      extends Modelica.Icons.VariantsPackage;

      package BaseClasses "Base classes used in the Vessels package (only of interest to build new component models)"
        extends Modelica.Icons.BasesPackage;

        connector VesselFluidPorts_b "Fluid connector with outlined, large icon to be used for horizontally aligned vectors of FluidPorts (vector dimensions must be added after dragging)"
          extends Interfaces.FluidPort;
        end VesselFluidPorts_b;
      end BaseClasses;
    end Vessels;

    package Interfaces "Interfaces for steady state and unsteady, mixed-phase, multi-substance, incompressible and compressible flow"
      extends Modelica.Icons.InterfacesPackage;

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

      connector FluidPorts_b "Fluid connector with outlined, large icon to be used for vectors of FluidPorts (vector dimensions must be added after dragging)"
        extends FluidPort;
      end FluidPorts_b;
    end Interfaces;

    package Types "Common types for fluid models"
      extends Modelica.Icons.TypesPackage;
      type Dynamics = enumeration(DynamicFreeInitial "DynamicFreeInitial -- Dynamic balance, Initial guess value", FixedInitial "FixedInitial -- Dynamic balance, Initial value fixed", SteadyStateInitial "SteadyStateInitial -- Dynamic balance, Steady state initial with guess value", SteadyState "SteadyState -- Steady state balance, Initial guess value") "Enumeration to define definition of balance equations";
      type PortFlowDirection = enumeration(Entering "Fluid flow is only entering", Leaving "Fluid flow is only leaving", Bidirectional "No restrictions on fluid flow (flow reversal possible)") "Enumeration to define whether flow reversal is allowed";
    end Types;

    package Utilities "Utility models to construct fluid components (should not be used directly)"
      extends Modelica.Icons.UtilitiesPackage;

      function checkBoundary "Check whether boundary definition is correct"
        extends Modelica.Icons.Function;
        input String mediumName;
        input String substanceNames[:] "Names of substances";
        input Boolean singleState;
        input Boolean define_p;
        input Real X_boundary[:];
        input String modelName = "??? boundary ???";
      protected
        Integer nX = size(X_boundary, 1);
        String X_str;
      algorithm
        assert(not singleState or singleState and define_p, "
      Wrong value of parameter define_p (= false) in model \"" + modelName + "\":
      The selected medium \"" + mediumName + "\" has Medium.singleState=true.
      Therefore, an boundary density cannot be defined and
      define_p = true is required.
        ");
        for i in 1:nX loop
          assert(X_boundary[i] >= 0.0, "
      Wrong boundary mass fractions in medium \"" + mediumName + "\" in model \"" + modelName + "\":
      The boundary value X_boundary(" + String(i) + ") = " + String(X_boundary[i]) + "
      is negative. It must be positive.
          ");
        end for;
        if nX > 0 and abs(sum(X_boundary) - 1.0) > 1e-10 then
          X_str := "";
          for i in 1:nX loop
            X_str := X_str + "   X_boundary[" + String(i) + "] = " + String(X_boundary[i]) + " \"" + substanceNames[i] + "\"\n";
          end for;
          Modelica.Utilities.Streams.error("The boundary mass fractions in medium \"" + mediumName + "\" in model \"" + modelName + "\"\n" + "do not sum up to 1. Instead, sum(X_boundary) = " + String(sum(X_boundary)) + ":\n" + X_str);
        else
        end if;
      end checkBoundary;

      function regStep "Approximation of a general step, such that the characteristic is continuous and differentiable"
        extends Modelica.Icons.Function;
        input Real x "Abscissa value";
        input Real y1 "Ordinate value for x > 0";
        input Real y2 "Ordinate value for x < 0";
        input Real x_small(min = 0) = 1e-5 "Approximation of step for -x_small <= x <= x_small; x_small >= 0 required";
        output Real y "Ordinate value to approximate y = if x > 0 then y1 else y2";
      algorithm
        y := smooth(1, if x > x_small then y1 else if x < -x_small then y2 else if x_small > 0 then (x/x_small)*((x/x_small)^2 - 3)*(y2 - y1)/4 + (y1 + y2)/2 else (y1 + y2)/2);
      end regStep;

      function cubicHermite "Evaluate a cubic Hermite spline"
        extends Modelica.Icons.Function;
        input Real x "Abscissa value";
        input Real x1 "Lower abscissa value";
        input Real x2 "Upper abscissa value";
        input Real y1 "Lower ordinate value";
        input Real y2 "Upper ordinate value";
        input Real y1d "Lower gradient";
        input Real y2d "Upper gradient";
        output Real y "Interpolated ordinate value";
      protected
        Real h "Distance between x1 and x2";
        Real t "Abscissa scaled with h, i.e., t=[0..1] within x=[x1..x2]";
        Real h00 "Basis function 00 of cubic Hermite spline";
        Real h10 "Basis function 10 of cubic Hermite spline";
        Real h01 "Basis function 01 of cubic Hermite spline";
        Real h11 "Basis function 11 of cubic Hermite spline";
        Real aux3 "t cube";
        Real aux2 "t square";
      algorithm
        h := x2 - x1;
        if abs(h) > 0 then
          t := (x - x1)/h;
          aux3 := t^3;
          aux2 := t^2;
          h00 := 2*aux3 - 3*aux2 + 1;
          h10 := aux3 - 2*aux2 + t;
          h01 := -2*aux3 + 3*aux2;
          h11 := aux3 - aux2;
          y := y1*h00 + h*y1d*h10 + y2*h01 + h*y2d*h11;
        else
          y := (y1 + y2)/2;
        end if;
        annotation(smoothOrder = 3);
      end cubicHermite;
    end Utilities;
  end Fluid;

  package Media "Library of media property models"
    extends Modelica.Icons.Package;
    import Modelica.Units.SI;
    import Cv = Modelica.Units.Conversions;

    package Interfaces "Interfaces for media models"
      extends Modelica.Icons.InterfacesPackage;

      partial package PartialMedium "Partial medium properties (base package of all media packages)"
        extends Modelica.Media.Interfaces.Types;
        extends Modelica.Icons.MaterialPropertiesPackage;
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
        final constant Integer nS = size(substanceNames, 1) "Number of substances";
        constant Integer nX = nS "Number of mass fractions";
        constant Integer nXi = if fixedX then 0 else if reducedX then nS - 1 else nS "Number of structurally independent mass fractions (see docu for details)";
        final constant Integer nC = size(extraPropertiesNames, 1) "Number of extra (outside of standard mass-balance) transported properties";
        replaceable record FluidConstants = Modelica.Media.Interfaces.Types.Basic.FluidConstants "Critical, triple, molecular and other standard data of fluid";

        replaceable record ThermodynamicState "Minimal variable set that is available as input argument to every medium function"
          extends Modelica.Icons.Record;
        end ThermodynamicState;

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
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input MassFraction X[:] = reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state record";
        end setState_pTX;

        replaceable partial function setState_phX "Return thermodynamic state as function of p, h and composition X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction X[:] = reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state record";
        end setState_phX;

        replaceable partial function setState_psX "Return thermodynamic state as function of p, s and composition X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          input MassFraction X[:] = reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state record";
        end setState_psX;

        replaceable partial function dynamicViscosity "Return dynamic viscosity"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output DynamicViscosity eta "Dynamic viscosity";
        end dynamicViscosity;

        replaceable partial function thermalConductivity "Return thermal conductivity"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output ThermalConductivity lambda "Thermal conductivity";
        end thermalConductivity;

        replaceable partial function pressure "Return pressure"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output AbsolutePressure p "Pressure";
        end pressure;

        replaceable partial function temperature "Return temperature"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output Temperature T "Temperature";
        end temperature;

        replaceable partial function density "Return density"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output Density d "Density";
        end density;

        replaceable partial function specificEnthalpy "Return specific enthalpy"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificEnthalpy h "Specific enthalpy";
        end specificEnthalpy;

        replaceable partial function specificInternalEnergy "Return specific internal energy"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificEnergy u "Specific internal energy";
        end specificInternalEnergy;

        replaceable partial function specificEntropy "Return specific entropy"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificEntropy s "Specific entropy";
        end specificEntropy;

        replaceable partial function specificGibbsEnergy "Return specific Gibbs energy"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificEnergy g "Specific Gibbs energy";
        end specificGibbsEnergy;

        replaceable partial function specificHelmholtzEnergy "Return specific Helmholtz energy"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificEnergy f "Specific Helmholtz energy";
        end specificHelmholtzEnergy;

        replaceable partial function specificHeatCapacityCp "Return specific heat capacity at constant pressure"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificHeatCapacity cp "Specific heat capacity at constant pressure";
        end specificHeatCapacityCp;

        replaceable partial function specificHeatCapacityCv "Return specific heat capacity at constant volume"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificHeatCapacity cv "Specific heat capacity at constant volume";
        end specificHeatCapacityCv;

        replaceable partial function isentropicEnthalpy "Return isentropic enthalpy"
          extends Modelica.Icons.Function;
          input AbsolutePressure p_downstream "Downstream pressure";
          input ThermodynamicState refState "Reference state for entropy";
          output SpecificEnthalpy h_is "Isentropic enthalpy";
        end isentropicEnthalpy;

        replaceable partial function isobaricExpansionCoefficient "Return overall the isobaric expansion coefficient beta"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output IsobaricExpansionCoefficient beta "Isobaric expansion coefficient";
        end isobaricExpansionCoefficient;

        replaceable partial function isothermalCompressibility "Return overall the isothermal compressibility factor"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SI.IsothermalCompressibility kappa "Isothermal compressibility";
        end isothermalCompressibility;

        replaceable partial function density_derp_T "Return density derivative w.r.t. pressure at constant temperature"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output DerDensityByPressure ddpT "Density derivative w.r.t. pressure";
        end density_derp_T;

        replaceable partial function density_derT_p "Return density derivative w.r.t. temperature at constant pressure"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output DerDensityByTemperature ddTp "Density derivative w.r.t. temperature";
        end density_derT_p;

        replaceable partial function density_derX "Return density derivative w.r.t. mass fraction"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output Density dddX[nX] "Derivative of density w.r.t. mass fraction";
        end density_derX;

        replaceable partial function molarMass "Return the molar mass of the medium"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output MolarMass MM "Mixture molar mass";
        end molarMass;

        replaceable function specificEnthalpy_pTX "Return specific enthalpy from p, T, and X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input MassFraction X[:] = reference_X "Mass fractions";
          output SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := specificEnthalpy(setState_pTX(p, T, X));
          annotation(inverse(T = temperature_phX(p, h, X)));
        end specificEnthalpy_pTX;

        replaceable function density_pTX "Return density from p, T, and X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input MassFraction X[:] "Mass fractions";
          output Density d "Density";
        algorithm
          d := density(setState_pTX(p, T, X));
        end density_pTX;

        replaceable function temperature_phX "Return temperature from p, h, and X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction X[:] = reference_X "Mass fractions";
          output Temperature T "Temperature";
        algorithm
          T := temperature(setState_phX(p, h, X));
        end temperature_phX;

        type MassFlowRate = SI.MassFlowRate(quantity = "MassFlowRate." + mediumName, min = -1.0e5, max = 1.e5) "Type for mass flow rate with medium specific attributes";
      end PartialMedium;

      partial package PartialMixtureMedium "Base class for pure substances of several chemical substances"
        extends PartialMedium(redeclare replaceable record FluidConstants = Modelica.Media.Interfaces.Types.IdealGas.FluidConstants);

        redeclare replaceable record extends ThermodynamicState "Thermodynamic state variables"
          AbsolutePressure p "Absolute pressure of medium";
          Temperature T "Temperature of medium";
          MassFraction X[nX](start = reference_X) "Mass fractions (= (component mass)/total mass  m_i/m)";
        end ThermodynamicState;

        constant FluidConstants fluidConstants[nS] "Constant data for the fluid";

        replaceable function gasConstant "Return the gas constant of the mixture (also for liquids)"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state";
          output SI.SpecificHeatCapacity R_s "Mixture gas constant";
        end gasConstant;

        function massToMoleFractions "Return mole fractions from mass fractions X"
          extends Modelica.Icons.Function;
          input SI.MassFraction X[:] "Mass fractions of mixture";
          input SI.MolarMass MMX[:] "Molar masses of components";
          output SI.MoleFraction moleFractions[size(X, 1)] "Mole fractions of gas mixture";
        protected
          Real invMMX[size(X, 1)] "Inverses of molar weights";
          SI.MolarMass Mmix "Molar mass of mixture";
        algorithm
          for i in 1:size(X, 1) loop
            invMMX[i] := 1/MMX[i];
          end for;
          Mmix := 1/(X*invMMX);
          for i in 1:size(X, 1) loop
            moleFractions[i] := Mmix*X[i]/MMX[i];
          end for;
          annotation(smoothOrder = 5);
        end massToMoleFractions;
      end PartialMixtureMedium;

      partial package PartialCondensingGases "Base class for mixtures of condensing and non-condensing gases"
        extends PartialMixtureMedium(ThermoStates = Modelica.Media.Interfaces.Choices.IndependentVariables.pTX);

        replaceable partial function saturationPressure "Return saturation pressure of condensing fluid"
          extends Modelica.Icons.Function;
          input Temperature Tsat "Saturation temperature";
          output AbsolutePressure psat "Saturation pressure";
        end saturationPressure;

        replaceable partial function enthalpyOfVaporization "Return vaporization enthalpy of condensing fluid"
          extends Modelica.Icons.Function;
          input Temperature T "Temperature";
          output SpecificEnthalpy r0 "Vaporization enthalpy";
        end enthalpyOfVaporization;

        replaceable partial function enthalpyOfLiquid "Return liquid enthalpy of condensing fluid"
          extends Modelica.Icons.Function;
          input Temperature T "Temperature";
          output SpecificEnthalpy h "Liquid enthalpy";
        end enthalpyOfLiquid;

        replaceable partial function enthalpyOfGas "Return enthalpy of non-condensing gas mixture"
          extends Modelica.Icons.Function;
          input Temperature T "Temperature";
          input MassFraction X[:] "Vector of mass fractions";
          output SpecificEnthalpy h "Specific enthalpy";
        end enthalpyOfGas;

        replaceable partial function enthalpyOfCondensingGas "Return enthalpy of condensing gas (most often steam)"
          extends Modelica.Icons.Function;
          input Temperature T "Temperature";
          output SpecificEnthalpy h "Specific enthalpy";
        end enthalpyOfCondensingGas;
      end PartialCondensingGases;

      package Choices "Types, constants to define menu choices"
        extends Modelica.Icons.Package;
        type IndependentVariables = enumeration(T "Temperature", pT "Pressure, Temperature", ph "Pressure, Specific Enthalpy", phX "Pressure, Specific Enthalpy, Mass Fraction", pTX "Pressure, Temperature, Mass Fractions", dTX "Density, Temperature, Mass Fractions") "Enumeration defining the independent variables of a medium";
      end Choices;

      package Types "Types to be used in fluid models"
        extends Modelica.Icons.Package;
        type AbsolutePressure = SI.AbsolutePressure(min = 0, max = 1.e8, nominal = 1.e5, start = 1.e5) "Type for absolute pressure with medium specific attributes";
        type Density = SI.Density(min = 0, max = 1.e5, nominal = 1, start = 1) "Type for density with medium specific attributes";
        type DynamicViscosity = SI.DynamicViscosity(min = 0, max = 1.e8, nominal = 1.e-3, start = 1.e-3) "Type for dynamic viscosity with medium specific attributes";
        type EnthalpyFlowRate = SI.EnthalpyFlowRate(nominal = 1000.0, min = -1.0e8, max = 1.e8) "Type for enthalpy flow rate with medium specific attributes";
        type MassFraction = Real(quantity = "MassFraction", final unit = "kg/kg", min = 0, max = 1, nominal = 0.1) "Type for mass fraction with medium specific attributes";
        type MolarMass = SI.MolarMass(min = 0.001, max = 0.25, nominal = 0.032) "Type for molar mass with medium specific attributes";
        type MolarVolume = SI.MolarVolume(min = 1e-6, max = 1.0e6, nominal = 1.0) "Type for molar volume with medium specific attributes";
        type SpecificEnergy = SI.SpecificEnergy(min = -1.0e8, max = 1.e8, nominal = 1.e6) "Type for specific energy with medium specific attributes";
        type SpecificInternalEnergy = SpecificEnergy "Type for specific internal energy with medium specific attributes";
        type SpecificEnthalpy = SI.SpecificEnthalpy(min = -1.0e10, max = 1.e10, nominal = 1.e6) "Type for specific enthalpy with medium specific attributes";
        type SpecificEntropy = SI.SpecificEntropy(min = -1.e7, max = 1.e7, nominal = 1.e3) "Type for specific entropy with medium specific attributes";
        type SpecificHeatCapacity = SI.SpecificHeatCapacity(min = 0, max = 1.e7, nominal = 1.e3, start = 1.e3) "Type for specific heat capacity with medium specific attributes";
        type Temperature = SI.Temperature(min = 1, max = 1.e4, nominal = 300, start = 288.15) "Type for temperature with medium specific attributes";
        type ThermalConductivity = SI.ThermalConductivity(min = 0, max = 500, nominal = 1, start = 1) "Type for thermal conductivity with medium specific attributes";
        type ExtraProperty = Real(min = 0.0, start = 1.0) "Type for unspecified, mass-specific property transported by flow";
        type ExtraPropertyFlowRate = Real(unit = "kg/s") "Type for flow rate of unspecified, mass-specific property";
        type IsobaricExpansionCoefficient = Real(min = 0, max = 1.0e8, unit = "1/K") "Type for isobaric expansion coefficient with medium specific attributes";
        type DipoleMoment = Real(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment") "Type for dipole moment with medium specific attributes";
        type DerDensityByPressure = SI.DerDensityByPressure "Type for partial derivative of density with respect to pressure with medium specific attributes";
        type DerDensityByTemperature = SI.DerDensityByTemperature "Type for partial derivative of density with respect to temperature with medium specific attributes";

        package Basic "The most basic version of a record used in several degrees of detail"
          extends Icons.Package;

          record FluidConstants "Critical, triple, molecular and other standard data of fluid"
            extends Modelica.Icons.Record;
            String iupacName "Complete IUPAC name (or common name, if non-existent)";
            String casRegistryNumber "Chemical abstracts sequencing number (if it exists)";
            String chemicalFormula "Chemical formula, (brutto, nomenclature according to Hill";
            String structureFormula "Chemical structure formula";
            MolarMass molarMass "Molar mass";
          end FluidConstants;
        end Basic;

        package IdealGas "The ideal gas version of a record used in several degrees of detail"
          extends Icons.Package;

          record FluidConstants "Extended fluid constants"
            extends Modelica.Media.Interfaces.Types.Basic.FluidConstants;
            Temperature criticalTemperature "Critical temperature";
            AbsolutePressure criticalPressure "Critical pressure";
            MolarVolume criticalMolarVolume "Critical molar Volume";
            Real acentricFactor "Pitzer acentric factor";
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
        end IdealGas;
      end Types;
    end Interfaces;

    package IdealGases "Data and models of ideal gases (single, fixed and dynamic mixtures) from NASA source"
      extends Modelica.Icons.VariantsPackage;

      package Common "Common packages and data for the ideal gas models"
        extends Modelica.Icons.Package;

        record DataRecord "Coefficient data record for properties of ideal gases based on NASA source"
          extends Modelica.Icons.Record;
          String name "Name of ideal gas";
          SI.MolarMass MM "Molar mass";
          SI.SpecificEnthalpy Hf "Enthalpy of formation at 298.15K";
          SI.SpecificEnthalpy H0 "H0(298.15K) - H0(0K)";
          SI.Temperature Tlimit "Temperature limit between low and high data sets";
          Real alow[7] "Low temperature coefficients a";
          Real blow[2] "Low temperature constants b";
          Real ahigh[7] "High temperature coefficients a";
          Real bhigh[2] "High temperature constants b";
          SI.SpecificHeatCapacity R_s "Gas constant";
        end DataRecord;

        package FluidData "Critical data, dipole moments and related data"
          extends Modelica.Icons.Package;
          import Modelica.Media.IdealGases.Common.SingleGasesData;
          constant Modelica.Media.Interfaces.Types.IdealGas.FluidConstants N2(chemicalFormula = "N2", iupacName = "molecular nitrogen", structureFormula = "unknown", casRegistryNumber = "7727-37-9", meltingPoint = 63.15, normalBoilingPoint = 77.35, criticalTemperature = 126.20, criticalPressure = 33.98e5, criticalMolarVolume = 90.10e-6, acentricFactor = 0.037, dipoleMoment = 0.0, molarMass = SingleGasesData.N2.MM, hasDipoleMoment = true, hasIdealGasHeatCapacity = true, hasCriticalData = true, hasAcentricFactor = true) "Nitrogen";
          constant Modelica.Media.Interfaces.Types.IdealGas.FluidConstants H2O(chemicalFormula = "H2O", iupacName = "oxidane", structureFormula = "H2O", casRegistryNumber = "7732-18-5", meltingPoint = 273.15, normalBoilingPoint = 373.124, criticalTemperature = 647.096, criticalPressure = 220.64e5, criticalMolarVolume = 55.95e-6, acentricFactor = 0.344, dipoleMoment = 1.8, molarMass = SingleGasesData.H2O.MM, hasDipoleMoment = true, hasIdealGasHeatCapacity = true, hasCriticalData = true, hasAcentricFactor = true) "Steam";
        end FluidData;

        package SingleGasesData "Ideal gas data based on the NASA Glenn coefficients"
          extends Modelica.Icons.Package;
          final constant Real R_NASA_2002(final unit = "J/(mol.K)") = 8.314510 "Universal gas constant as used by McBride B.J., Zehe M.J., and Gordon S. (2002)";
          constant IdealGases.Common.DataRecord Ag(name = "Ag", MM = 0.1078682, Hf = 2641186.188329832, H0 = 57453.70739476509, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {33520.0237, 6.56281935}, ahigh = {-330992.637, 982.0086420000001, 1.381179917, 0.0006170899989999999, -1.6881146e-007, 2.008826848e-011, -5.627285655e-016}, bhigh = {27267.19171, 14.56862733}, R_s = R_NASA_2002/Ag.MM);
          constant IdealGases.Common.DataRecord Agplus(name = "Agplus", MM = 0.1078676514, Hf = 9475442.514362559, H0 = 57454.94519963192, Tlimit = 1000, alow = {3691132.75, -43169.82999999999, 202.8445385, -0.465841374, 0.000558620051, -3.154880975e-007, 6.578702060000001e-011}, blow = {337157.447, -1142.924427}, ahigh = {-53274323.49999999, 131071.0631, -109.8820208, 0.0482600276, -1.093661557e-005, 1.26383591e-009, -5.852542535e-014}, bhigh = {-743912.2509999999, 844.6266189999999}, R_s = R_NASA_2002/Agplus.MM);
          constant IdealGases.Common.DataRecord Agminus(name = "Agminus", MM = 0.1078687486, Hf = 1419120.273357839, H0 = 57453.41519610434, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {17665.65919, 5.8696798}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {17665.65919, 5.8696798}, R_s = R_NASA_2002/Agminus.MM);
          constant IdealGases.Common.DataRecord Air(name = "Air", MM = 0.0289651159, Hf = -4333.833858403446, H0 = 298609.6803431054, Tlimit = 1000, alow = {10099.5016, -196.827561, 5.00915511, -0.00576101373, 1.06685993e-005, -7.94029797e-009, 2.18523191e-012}, blow = {-176.796731, -3.921504225}, ahigh = {241521.443, -1257.8746, 5.14455867, -0.000213854179, 7.06522784e-008, -1.07148349e-011, 6.57780015e-016}, bhigh = {6462.26319, -8.147411905}, R_s = R_NASA_2002/Air.MM);
          constant IdealGases.Common.DataRecord AL(name = "AL", MM = 0.026981538, Hf = 12230585.22460803, H0 = 256422.4100197698, Tlimit = 1000, alow = {5006.60889, 18.61304407, 2.412531111, 0.0001987604647, -2.432362152e-007, 1.538281506e-010, -3.944375734e-014}, blow = {38874.1268, 6.086585765}, ahigh = {-29208.20938, 116.7751876, 2.356906505, 7.73723152e-005, -1.529455262e-008, -9.97167026e-013, 5.053278264e-016}, bhigh = {38232.8865, 6.600920155}, R_s = R_NASA_2002/AL.MM);
          constant IdealGases.Common.DataRecord ALplus(name = "ALplus", MM = 0.0269809894, Hf = 33839201.16732265, H0 = 229696.0985426279, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {109064.4788, 3.79100578}, ahigh = {-4181.18325, -9.94855727, 2.548615878, -5.878760040000001e-005, 3.132291294e-008, -7.74889463e-012, 7.27444769e-016}, bhigh = {109101.1485, 3.48866729}, R_s = R_NASA_2002/ALplus.MM);
          constant IdealGases.Common.DataRecord ALminus(name = "ALminus", MM = 0.0269820866, Hf = 10417656.61666804, H0 = 250396.2388142361, Tlimit = 1000, alow = {29108.01723, -383.698375, 4.6551428, -0.00604582184, 8.57725964e-006, -5.47626e-009, 1.322714061e-012}, blow = {34906.1698, -5.9570977}, ahigh = {633981.432, -2383.438463, 5.46997113, -0.001299840355, 2.88830547e-007, -3.25324051e-011, 1.472436088e-015}, bhigh = {47803.0654, -15.36906816}, R_s = R_NASA_2002/ALminus.MM);
          constant IdealGases.Common.DataRecord ALBr(name = "ALBr", MM = 0.106885538, Hf = 134022.0133429089, H0 = 89545.4631102666, Tlimit = 1000, alow = {8176.158640000001, -251.6942718, 5.40329633, -0.00174721292, 2.07730477e-006, -1.261267579e-009, 3.16633597e-013}, blow = {1635.024429, -2.323594886}, ahigh = {-610339.5599999999, 2010.066834, 1.769617961, 0.001929888914, -6.64104783e-007, 1.172854627e-010, -7.17874276e-015}, bhigh = {-12178.12867, 22.04450764}, R_s = R_NASA_2002/ALBr.MM);
          constant IdealGases.Common.DataRecord ALBr2(name = "ALBr2", MM = 0.186789538, Hf = -753051.4101919348, H0 = 71727.1167510463, Tlimit = 1000, alow = {31993.7587, -711.917897, 9.478258110000001, -0.00487553167, 5.51651299e-006, -3.34005304e-009, 8.36847684e-013}, blow = {-15405.91306, -17.42171366}, ahigh = {-352378.29, 467.154417, 7.11190819, -0.00055517092, 3.16630113e-007, -5.52102833e-011, 3.17672595e-015}, bhigh = {-22650.04078, -2.69561036}, R_s = R_NASA_2002/ALBr2.MM);
          constant IdealGases.Common.DataRecord ALBr3(name = "ALBr3", MM = 0.266693538, Hf = -1539132.395476339, H0 = 67280.73028901059, Tlimit = 1000, alow = {47189.4884, -1053.853163, 13.50747168, -0.006639869929999999, 7.26927683e-006, -4.27804949e-009, 1.045573281e-012}, blow = {-46994.4033, -36.67936779999999}, ahigh = {-89355.2744, -26.78035134, 10.02063997, -8.458764399999999e-006, 1.904243317e-009, -2.215195785e-013, 1.038219389e-017}, bhigh = {-52492.4764, -15.79666403}, R_s = R_NASA_2002/ALBr3.MM);
          constant IdealGases.Common.DataRecord ALC(name = "ALC", MM = 0.038992238, Hf = 17497931.48574852, H0 = 232305.4398672885, Tlimit = 1000, alow = {41399.2188, -585.867789, 5.96244572, -0.002006064322, 1.665566136e-006, -7.12164921e-010, 1.271188744e-013}, blow = {83834.3611, -8.00216505}, ahigh = {1937001.487, -6749.117789999999, 13.47525643, -0.00585080265, 1.926461091e-006, -2.585922351e-010, 1.222659806e-014}, bhigh = {122536.3649, -61.52244872}, R_s = R_NASA_2002/ALC.MM);
          constant IdealGases.Common.DataRecord ALC2(name = "ALC2", MM = 0.051002938, Hf = 13246605.04851701, H0 = 240432.7374238716, Tlimit = 1000, alow = {15240.87465, -264.9987059, 6.2804149, -0.0001786037647, 3.79190774e-006, -3.99945007e-009, 1.299752388e-012}, blow = {80927.63279999999, -6.247291862}, ahigh = {146601.7895, -1362.764489, 8.457759149999999, -0.000367890168, 7.9031745e-008, -8.880023720000001e-012, 4.05363395e-016}, bhigh = {87059.24230000001, -21.27956728}, R_s = R_NASA_2002/ALC2.MM);
          constant IdealGases.Common.DataRecord ALCL(name = "ALCL", MM = 0.06243453800000001, Hf = -816974.7808496637, H0 = 149326.1950620985, Tlimit = 1000, alow = {23808.81392, -445.715942, 5.99285399, -0.002777300261, 3.101582418e-006, -1.815268376e-009, 4.414662339999999e-013}, blow = {-5202.73603, -7.383298016}, ahigh = {-899346.1220000001, 2765.942061, 1.003500696, 0.002267806833, -7.2805416e-007, 1.182380673e-010, -6.66049813e-015}, bhigh = {-24961.64448, 26.1692548}, R_s = R_NASA_2002/ALCL.MM);
          constant IdealGases.Common.DataRecord ALCLplus(name = "ALCLplus", MM = 0.0624339894, Hf = 13804168.45507553, H0 = 146625.821735492, Tlimit = 1000, alow = {34699.5522, -547.990003, 6.10601113, -0.002674711519, 2.696426573e-006, -1.463885068e-009, 3.35872906e-013}, blow = {105171.951, -7.816586372}, ahigh = {-754724.0819999999, 1251.545253, 4.44242491, -0.0009786116429999999, 6.347511329999999e-007, -1.158320344e-010, 6.870022460000001e-015}, bhigh = {93183.32699999999, 4.047521108}, R_s = R_NASA_2002/ALCLplus.MM);
          constant IdealGases.Common.DataRecord ALCL2(name = "ALCL2", MM = 0.09788753800000001, Hf = -2460724.387613059, H0 = 131241.0063883719, Tlimit = 1000, alow = {53405.4595, -967.805798, 10.06252671, -0.00553952845, 5.82342056e-006, -3.30654245e-009, 7.8315621e-013}, blow = {-26076.2711, -23.93364216}, ahigh = {430345.306, -1552.370585, 8.760657419999999, -0.0009467450059999999, 2.40184488e-007, -2.427836709e-011, 8.390123470000001e-016}, bhigh = {-21458.84709, -18.03641668}, R_s = R_NASA_2002/ALCL2.MM);
          constant IdealGases.Common.DataRecord ALCL3(name = "ALCL3", MM = 0.133340538, Hf = -4384854.5368851, H0 = 122999.3762287055, Tlimit = 1000, alow = {77506.0097, -1440.779717, 14.01744141, -0.00638163124, 5.87167472e-006, -2.908872278e-009, 5.994050889999999e-013}, blow = {-65793.43180000001, -44.94017799}, ahigh = {-137863.0916, -55.7920729, 10.04190387, -1.682165339e-005, 3.72466466e-009, -4.27552678e-013, 1.982341329e-017}, bhigh = {-73434.0747, -20.45130429}, R_s = R_NASA_2002/ALCL3.MM);
          constant IdealGases.Common.DataRecord ALF(name = "ALF", MM = 0.0459799412, Hf = -5742948.753488184, H0 = 193391.0041624847, Tlimit = 1000, alow = {30207.71686, -308.0986949, 3.88641314, 0.00356434369, -5.85847128e-006, 4.38810992e-009, -1.256906273e-012}, blow = {-31175.72862, 2.032567172}, ahigh = {-711122.905, 1903.013316, 2.191607179, 0.001421471467, -4.17963477e-007, 6.1538044e-011, -2.945403999e-015}, bhigh = {-45407.2896, 16.13163743}, R_s = R_NASA_2002/ALF.MM);
          constant IdealGases.Common.DataRecord ALFplus(name = "ALFplus", MM = 0.0459793926, Hf = 15055300.25205248, H0 = 191666.0160491116, Tlimit = 1000, alow = {36430.3812, -252.4634478, 3.105310486, 0.00573327043, -8.839786990000001e-006, 6.34357959e-009, -1.645011685e-012}, blow = {83702.37449999999, 6.76401558}, ahigh = {1505101.126, -2236.668821, 3.098216724, 0.00311541393, -1.168427068e-006, 1.773587168e-010, -9.665841379999999e-015}, bhigh = {98850.8385, 5.99189459}, R_s = R_NASA_2002/ALFplus.MM);
          constant IdealGases.Common.DataRecord ALFCL(name = "ALFCL", MM = 0.0814329412, Hf = -5359132.392481975, H0 = 148996.1534141419, Tlimit = 1000, alow = {41047.7948, -576.964642, 6.5626427, 0.00410628584, -7.21392112e-006, 5.48640145e-009, -1.580656193e-012}, blow = {-51148.287, -6.041227053}, ahigh = {69706.36350000001, -622.4485910000001, 7.57347541, -0.0002236155999, 2.382317949e-008, 4.44378576e-012, -5.486977849999999e-016}, bhigh = {-51009.43199999999, -10.91164505}, R_s = R_NASA_2002/ALFCL.MM);
          constant IdealGases.Common.DataRecord ALFCL2(name = "ALFCL2", MM = 0.1168859412, Hf = -6770663.741722942, H0 = 134646.3042383407, Tlimit = 1000, alow = {69556.07340000001, -1188.857902, 11.5667259, 0.000457495949, -3.40737283e-006, 3.35682254e-009, -1.085329228e-012}, blow = {-91620.4926, -32.06065081}, ahigh = {-172036.0526, -119.3340759, 10.08894431, -3.55099381e-005, 7.83095261e-009, -8.961734229999999e-013, 4.14533026e-017}, bhigh = {-98041.8547, -21.27046859}, R_s = R_NASA_2002/ALFCL2.MM);
          constant IdealGases.Common.DataRecord ALF2(name = "ALF2", MM = 0.0649783444, Hf = -9722688.08683282, H0 = 178535.3583123919, Tlimit = 1000, alow = {29949.51991, -219.4199915, 3.41674876, 0.01272953936, -1.883312206e-005, 1.330702256e-008, -3.68011863e-012}, blow = {-76075.3765, 8.759626916}, ahigh = {-214689.6245, 30.9684015, 6.81639962, 0.0001820129379, -7.79367744e-008, 1.472534201e-011, -8.803695299999999e-016}, bhigh = {-78840.02680000001, -7.915370474}, R_s = R_NASA_2002/ALF2.MM);
          constant IdealGases.Common.DataRecord ALF2minus(name = "ALF2minus", MM = 0.064978893, Hf = -13130889.82602397, H0 = 174392.244570864, Tlimit = 1000, alow = {123336.9037, -1348.195504, 8.61117805, 0.0002245141297, -2.424673201e-006, 2.21413243e-009, -6.60271396e-013}, blow = {-97084.37460000001, -21.92617549}, ahigh = {-159007.6965, -206.0486516, 7.15528938, -6.260167690000001e-005, 1.391935746e-008, -1.603901265e-012, 7.461508519999999e-017}, bhigh = {-104047.9429, -11.22696648}, R_s = R_NASA_2002/ALF2minus.MM);
          constant IdealGases.Common.DataRecord ALF2CL(name = "ALF2CL", MM = 0.1004313444, Hf = -9948369.714345874, H0 = 147638.3402869194, Tlimit = 1000, alow = {56774.12089999999, -886.9829470000001, 8.75274655, 0.0081957912, -1.380480934e-005, 1.032703706e-008, -2.948968416e-012}, blow = {-117793.6778, -18.5834736}, ahigh = {-211542.2988, -195.9188681, 10.1457685, -5.81321935e-005, 1.281071982e-008, -1.465366277e-012, 6.77600245e-017}, bhigh = {-122715.311, -23.59853398}, R_s = R_NASA_2002/ALF2CL.MM);
          constant IdealGases.Common.DataRecord ALF3(name = "ALF3", MM = 0.0839767476, Hf = -14400140.18832994, H0 = 167233.459277244, Tlimit = 1000, alow = {44102.6352, -566.7495739999999, 5.83307285, 0.01603535069, -2.413263602e-005, 1.71410616e-008, -4.7475432e-012}, blow = {-144334.9991, -5.461613658}, ahigh = {-249397.216, -291.1202519, 10.21662932, -8.64298597e-005, 1.905713108e-008, -2.181058411e-012, 1.009055287e-016}, bhigh = {-147569.4276, -27.03983244}, R_s = R_NASA_2002/ALF3.MM);
          constant IdealGases.Common.DataRecord ALF4minus(name = "ALF4minus", MM = 0.1029756994, Hf = -18952051.96343634, H0 = 163017.4409866645, Tlimit = 1000, alow = {231201.0037, -3235.37678, 20.17865547, -0.0091081935, 6.67955263e-006, -2.606075106e-009, 4.11006051e-013}, blow = {-221178.4563, -86.77268282}, ahigh = {-321741.161, -261.2097043, 13.19792654, -8.01013541e-005, 1.786204421e-008, -2.062751964e-012, 9.61258177e-017}, bhigh = {-238157.7915, -42.31634321999999}, R_s = R_NASA_2002/ALF4minus.MM);
          constant IdealGases.Common.DataRecord ALH(name = "ALH", MM = 0.027989478, Hf = 8905160.860806337, H0 = 309691.5205063846, Tlimit = 1000, alow = {-37591.1403, 508.900223, 1.128086896, 0.003988660910000001, -2.150790303e-007, -2.176790819e-009, 1.020805902e-012}, blow = {26444.31827, 16.50021856}, ahigh = {6802018.430000001, -21784.16933, 30.32713047, -0.01503343597, 4.49214236e-006, -6.17845037e-010, 3.11520526e-014}, bhigh = {165830.1221, -187.6766425}, R_s = R_NASA_2002/ALH.MM);
          constant IdealGases.Common.DataRecord ALHCL(name = "ALHCL", MM = 0.063442478, Hf = 165850.4890051741, H0 = 171597.5217739761, Tlimit = 1000, alow = {35871.6976, -591.624999, 6.94454238, -0.002511543148, 6.47133255e-006, -5.64227714e-009, 1.715950436e-012}, blow = {2750.930479, -9.903745880000001}, ahigh = {-168391.533, -886.230179, 8.062379399999999, -0.0009200551470000001, 3.94981722e-007, -6.40108676e-011, 3.5783541e-015}, bhigh = {3641.50485, -18.00686894}, R_s = R_NASA_2002/ALHCL.MM);
          constant IdealGases.Common.DataRecord ALHCL2(name = "ALHCL2", MM = 0.098895478, Hf = -3552022.520180347, H0 = 138289.3968114498, Tlimit = 1000, alow = {118482.8615, -2054.157118, 15.74696513, -0.01476257296, 2.065336978e-005, -1.42019885e-008, 3.82627986e-012}, blow = {-34342.7746, -57.61184061}, ahigh = {96080.63939999999, -1485.540161, 11.03592709, -0.00039569552, 8.46584373e-008, -9.48333652e-012, 4.31903353e-016}, bhigh = {-36692.1639, -32.36862171}, R_s = R_NASA_2002/ALHCL2.MM);
          constant IdealGases.Common.DataRecord ALHF(name = "ALHF", MM = 0.0469878812, Hf = -3886416.653322091, H0 = 224996.7593771817, Tlimit = 1000, alow = {-9289.545099999999, 133.5515868, 2.77244868, 0.00675141503, -4.13384614e-006, 5.86570407e-010, 2.276158011e-013}, blow = {-23846.85845, 12.28752581}, ahigh = {734216.9250000001, -3462.16413, 10.39714588, -0.001750737965, 4.615687860000001e-007, -5.39041474e-011, 2.340478515e-015}, bhigh = {-2965.279722, -37.13172313}, R_s = R_NASA_2002/ALHF.MM);
          constant IdealGases.Common.DataRecord ALHFCL(name = "ALHFCL", MM = 0.08244088120000001, Hf = -6735062.943504781, H0 = 152019.6754034696, Tlimit = 1000, alow = {129037.3237, -2142.099873, 14.8543442, -0.0114032693, 1.564521768e-005, -1.067574855e-008, 2.857255247e-012}, blow = {-58183.0307, -54.83424986}, ahigh = {40689.8713, -1502.129854, 11.05214126, -0.000403158773, 8.64525222e-008, -9.70065952e-012, 4.423629509999999e-016}, bhigh = {-61298.8811, -34.03564016}, R_s = R_NASA_2002/ALHFCL.MM);
          constant IdealGases.Common.DataRecord ALHF2(name = "ALHF2", MM = 0.0659862844, Hf = -11597852.32580848, H0 = 186401.9941695641, Tlimit = 1000, alow = {105018.1431, -1398.654202, 9.166334839999999, 0.00386728687, -4.83084109e-006, 3.099287181e-009, -8.440702990000001e-013}, blow = {-86590.48800000001, -25.57299683}, ahigh = {-4419.9473, -1612.826324, 11.13336052, -0.000435181266, 9.34439616e-008, -1.049431425e-011, 4.78833398e-016}, bhigh = {-86069.16189999999, -36.76383785}, R_s = R_NASA_2002/ALHF2.MM);
          constant IdealGases.Common.DataRecord ALH2(name = "ALH2", MM = 0.028997418, Hf = 9544813.058873035, H0 = 347990.7762822194, Tlimit = 1000, alow = {14551.82996, -215.3768996, 5.14437023, -0.00396522203, 1.340900203e-005, -1.216744854e-008, 3.74310713e-012}, blow = {33110.3794, -3.608799711}, ahigh = {143291.0601, -2365.907684, 9.085667190000001, -0.001308536612, 4.77719136e-007, -7.32472189e-011, 3.99790094e-015}, bhigh = {44859.5185, -32.20814285}, R_s = R_NASA_2002/ALH2.MM);
          constant IdealGases.Common.DataRecord ALH2CL(name = "ALH2CL", MM = 0.064450418, Hf = -1650034.387674569, H0 = 174603.2275539315, Tlimit = 1000, alow = {93038.2898, -1328.188016, 9.42476359, -0.00327766059, 1.004231609e-005, -8.94812309e-009, 2.708031665e-012}, blow = {-7647.43793, -26.82512215}, ahigh = {316692.993, -3094.037914, 12.1587202, -0.0008248269589999999, 1.765027123e-007, -1.977372723e-011, 9.00617628e-016}, bhigh = {2411.845642, -47.18390855}, R_s = R_NASA_2002/ALH2CL.MM);
          constant IdealGases.Common.DataRecord ALH2F(name = "ALH2F", MM = 0.0479958212, Hf = -6597571.331897535, H0 = 224286.2134839355, Tlimit = 1000, alow = {89060.39290000001, -975.080393, 5.87077232, 0.00689666369, -4.04581728e-006, 7.21931866e-010, 7.329846739999999e-014}, blow = {-34253.02600000001, -9.387539141}, ahigh = {271151.4962, -3169.62348, 12.21401118, -0.000846560026, 1.812341995e-007, -2.030947985e-011, 9.251825820000001e-016}, bhigh = {-22592.17746, -49.41337333}, R_s = R_NASA_2002/ALH2F.MM);
          constant IdealGases.Common.DataRecord ALH3(name = "ALH3", MM = 0.030005358, Hf = 4295768.77569666, H0 = 346957.3667476322, Tlimit = 1000, alow = {14812.07909, -28.3649534, 2.507597126, 0.00731592051, 2.331766687e-006, -6.38920989e-009, 2.456885069e-012}, blow = {14631.89428, 8.3131877}, ahigh = {588545.855, -4595.78566, 13.20893344, -0.001226849004, 2.626580824e-007, -2.943725869e-011, 1.341177648e-015}, bhigh = {39917.1695, -61.81829295}, R_s = R_NASA_2002/ALH3.MM);
          constant IdealGases.Common.DataRecord ALI(name = "ALI", MM = 0.153886008, Hf = 437954.1575995656, H0 = 63365.84545100423, Tlimit = 1000, alow = {1870.854131, -154.3184003, 5.07439188, -0.00112058483, 1.386302156e-006, -8.54078228e-010, 2.180358492e-013}, blow = {7517.44369, 0.6688267621999999}, ahigh = {475281.792, -1198.028588, 5.43368536, -0.0001004479306, -1.005928846e-007, 4.568173190000001e-011, -3.960201360000001e-015}, bhigh = {14646.27816, -3.141199746}, R_s = R_NASA_2002/ALI.MM);
          constant IdealGases.Common.DataRecord ALI2(name = "ALI2", MM = 0.280790478, Hf = -120420.5863419628, H0 = 49585.17859711753, Tlimit = 1000, alow = {14234.13595, -464.657569, 8.72267491, -0.00356051929, 4.18868229e-006, -2.616026962e-009, 6.72019551e-013}, blow = {-3846.13333, -10.73076578}, ahigh = {-335599.902, 474.334794, 7.10650139, -0.0005529965340000001, 3.161480314e-007, -5.51548916e-011, 3.17415582e-015}, bhigh = {-9785.48885, -0.5602275943999999}, R_s = R_NASA_2002/ALI2.MM);
          constant IdealGases.Common.DataRecord ALI3(name = "ALI3", MM = 0.407694948, Hf = -469298.0227952199, H0 = 46612.22095889204, Tlimit = 1000, alow = {27060.32439, -755.993681, 12.71396349, -0.00546688409, 6.29761892e-006, -3.86420961e-009, 9.77413244e-013}, blow = {-22209.66921, -28.47883861}, ahigh = {-63574.2747, -15.7877228, 10.01249733, -5.22867312e-006, 1.19617352e-009, -1.40919449e-013, 6.67127639e-018}, bhigh = {-26114.55525, -12.47999813}, R_s = R_NASA_2002/ALI3.MM);
          constant IdealGases.Common.DataRecord ALN(name = "ALN", MM = 0.040988238, Hf = 10706217.98868251, H0 = 226043.1638949691, Tlimit = 1000, alow = {27166.45079, -254.349111, 3.53898772, 0.00529625616, -9.845700609999999e-006, 8.45220904e-009, -2.592304568e-012}, blow = {53099.94910000001, 5.39943522}, ahigh = {3821214.22, -10677.76595, 14.49174222, -0.00372722713, 7.922770960000001e-007, -8.086892210000001e-011, 2.893539736e-015}, bhigh = {120523.634, -72.88585119000001}, R_s = R_NASA_2002/ALN.MM);
          constant IdealGases.Common.DataRecord ALO(name = "ALO", MM = 0.042980938, Hf = 1566252.602490899, H0 = 204465.1980373253, Tlimit = 1000, alow = {-7683.3911, 295.7969549, 0.480810844, 0.01169224855, -1.595428871e-005, 1.060766814e-008, -2.647888708e-012}, blow = {5843.67217, 21.60997839}, ahigh = {15657.21161, 3855.74101, -5.92607978, 0.009050960419999999, -2.930661549e-006, 4.238529070000001e-010, -2.280655341e-014}, bhigh = {-13316.94655, 68.30663436}, R_s = R_NASA_2002/ALO.MM);
          constant IdealGases.Common.DataRecord ALOplus(name = "ALOplus", MM = 0.0429803894, Hf = 23103397.01110293, H0 = 211485.1942220886, Tlimit = 1000, alow = {28291.78513, -417.90871, 5.31329987, -0.001410883046, 2.526524021e-006, -2.005474816e-009, 5.76255355e-013}, blow = {120364.8109, -3.41056593}, ahigh = {27108.46446, -699.8653420000001, 5.78781584, -0.000687189546, 2.075047303e-007, -2.655281004e-011, 1.28312966e-015}, bhigh = {121868.2226, -7.05103588}, R_s = R_NASA_2002/ALOplus.MM);
          constant IdealGases.Common.DataRecord ALOminus(name = "ALOminus", MM = 0.04298148659999999, Hf = -6349752.034867962, H0 = 203453.1304461675, Tlimit = 1000, alow = {20780.75267, 2.859351226, 1.90191237, 0.00730104566, -9.13976987e-006, 5.65298319e-009, -1.396787103e-012}, blow = {-33592.6773, 12.96339858}, ahigh = {-69719.4829, -232.0553036, 4.67278433, -4.26644704e-005, 1.632506336e-008, -1.727134051e-012, 8.136840640000001e-017}, bhigh = {-33077.1893, -2.155922595}, R_s = R_NASA_2002/ALOminus.MM);
          constant IdealGases.Common.DataRecord ALOCL(name = "ALOCL", MM = 0.078433938, Hf = -3844822.505278264, H0 = 151797.0065458144, Tlimit = 1000, alow = {-5144.627790000001, -58.86297070000001, 4.45231693, 0.009288235090000001, -1.246894823e-005, 8.17807354e-009, -2.130739934e-012}, blow = {-37596.8365, 2.476862818}, ahigh = {-125802.7706, -242.0565961, 7.68113002, -7.268741699999999e-005, 1.611337534e-008, 1.852889749e-012, 8.60727822e-017}, bhigh = {-37543.2605, -14.7581832}, R_s = R_NASA_2002/ALOCL.MM);
          constant IdealGases.Common.DataRecord ALOCL2(name = "ALOCL2", MM = 0.113886938, Hf = -3532526.873274967, H0 = 138316.950799046, Tlimit = 1000, alow = {69026.3713, -1189.2975, 11.61842739, 0.0002818279805, -3.145010615e-006, 3.16838065e-009, -1.032375462e-012}, blow = {-44833.2307, -31.65475132}, ahigh = {-170771.3922, -118.0013804, 10.08798517, -3.51385804e-005, 7.751187029999999e-009, -8.8724706e-013, 4.10481544e-017}, bhigh = {-51249.4414, -20.5925296}, R_s = R_NASA_2002/ALOCL2.MM);
          constant IdealGases.Common.DataRecord ALOF(name = "ALOF", MM = 0.0619793412, Hf = -9233554.147555217, H0 = 177526.9434454718, Tlimit = 1000, alow = {7030.57836, -115.457543, 3.37882359, 0.01283929158, -1.749748388e-005, 1.162605473e-008, -3.064218613e-012}, blow = {-69593.817, 5.994804586}, ahigh = {-164102.0297, -327.777029, 7.74451974, -9.78864944e-005, 2.165743208e-008, -2.486541919e-012, 1.153633944e-016}, bhigh = {-69740.85090000001, -17.17253748}, R_s = R_NASA_2002/ALOF.MM);
          constant IdealGases.Common.DataRecord ALOF2(name = "ALOF2", MM = 0.08097774440000001, Hf = -9553856.763142934, H0 = 173570.9867463288, Tlimit = 1000, alow = {47560.8529, -612.431836, 6.05022366, 0.01559291479, -2.366136797e-005, 1.688366194e-008, -4.690583099999999e-012}, blow = {-91718.2749, -4.956258224}, ahigh = {-249668.1413, -283.7821503, 10.21108125, -8.418303430000001e-005, 1.855520828e-008, -2.122974022e-012, 9.8193191e-017}, bhigh = {-95218.0419, -25.22534812}, R_s = R_NASA_2002/ALOF2.MM);
          constant IdealGases.Common.DataRecord ALOF2minus(name = "ALOF2minus", MM = 0.08097829299999999, Hf = -12006793.21555963, H0 = 173836.4749180376, Tlimit = 1000, alow = {154060.5112, -1928.054597, 12.55806423, -0.000490403537, -2.341783347e-006, 2.4151386e-009, -7.47180925e-013}, blow = {-109143.0174, -42.6582175}, ahigh = {-238988.1459, -288.0143725, 10.2170024, -8.747061999999999e-005, 1.944846334e-008, -2.241045051e-012, 1.042591053e-016}, bhigh = {-119057.6566, -26.00779629}, R_s = R_NASA_2002/ALOF2minus.MM);
          constant IdealGases.Common.DataRecord ALOH(name = "ALOH", MM = 0.043988878, Hf = -4382066.098617018, H0 = 235330.6442596694, Tlimit = 1000, alow = {58764.9318, -944.942269, 7.82059918, 0.000585888847, -4.08366681e-006, 4.587229340000001e-009, -1.563936726e-012}, blow = {-19932.83011, -20.65043885}, ahigh = {788206.811, -2263.671626, 7.82395488, 0.0001821171456, -8.26372932e-008, 1.265414876e-011, -6.87597253e-016}, bhigh = {-10398.08093, -22.09032458}, R_s = R_NASA_2002/ALOH.MM);
          constant IdealGases.Common.DataRecord ALOHCL(name = "ALOHCL", MM = 0.07944187800000001, Hf = -4705147.327962211, H0 = 175208.823739036, Tlimit = 1000, alow = {16363.60341, -191.5959416, 4.71117047, 0.01388068475, -1.999018454e-005, 1.43964735e-008, -4.03333045e-012}, blow = {-45680.83719999999, 4.644207506}, ahigh = {796711.551, -2843.470502, 10.9555997, -0.0001099328162, -1.344506283e-008, 4.41589377e-012, -2.973546112e-016}, bhigh = {-29698.61461, -32.96113996}, R_s = R_NASA_2002/ALOHCL.MM);
          constant IdealGases.Common.DataRecord ALOHCL2(name = "ALOHCL2", MM = 0.114894878, Hf = -6311381.504752545, H0 = 149265.1917868784, Tlimit = 1000, alow = {39719.2986, -775.155496, 9.49405153, 0.01074401359, -1.676464791e-005, 1.259706368e-008, -3.61317798e-012}, blow = {-85847.9693, -19.93481642}, ahigh = {738592.976, -2863.204228, 13.97062327, -0.0001160311527, -1.208248796e-008, 4.25832763e-012, -2.900049181e-016}, bhigh = {-72930.48, -46.81834857}, R_s = R_NASA_2002/ALOHCL2.MM);
          constant IdealGases.Common.DataRecord ALOHF(name = "ALOHF", MM = 0.0629872812, Hf = -9116309.897179686, H0 = 211393.1693244763, Tlimit = 1000, alow = {-1556.003336, 288.6581999, 0.7703793290000001, 0.02450406329, -3.41781101e-005, 2.388932902e-008, -6.570480510000001e-012}, blow = {-71772.22559999999, 24.53071801}, ahigh = {755711.3130000001, -2936.702803, 11.02455104, -0.000137307803, -7.432816159999999e-009, 3.72998122e-012, -2.657027781e-016}, bhigh = {-53401.309, -35.27397302}, R_s = R_NASA_2002/ALOHF.MM);
          constant IdealGases.Common.DataRecord ALOHF2(name = "ALOHF2", MM = 0.0819856844, Hf = -13923293.06456335, H0 = 188185.2681100507, Tlimit = 1000, alow = {17382.63538, -130.7687299, 3.31238192, 0.02784734099, -3.98236321e-005, 2.809344456e-008, -7.7645742e-012}, blow = {-138413.3568, 10.04739945}, ahigh = {653011.992, -3034.017232, 14.09719788, -0.0001663681799, -1.011564183e-009, 2.993805003e-012, -2.315956955e-016}, bhigh = {-122305.2213, -51.5121069}, R_s = R_NASA_2002/ALOHF2.MM);
          constant IdealGases.Common.DataRecord ALO2(name = "ALO2", MM = 0.058980338, Hf = -655436.5795597849, H0 = 226543.7848118131, Tlimit = 1000, alow = {43384.8045, -473.5292259999999, 6.00171767, 0.007094420880000001, -1.129107996e-005, 8.252691679999999e-009, -2.327652976e-012}, blow = {-3826.1458, -4.83002248}, ahigh = {118721.6642, -833.56254, 8.309301189999999, -0.000353866722, 5.96706946e-008, 4.0148977e-014, -3.51570252e-016}, bhigh = {-2033.107586, -17.15063884}, R_s = R_NASA_2002/ALO2.MM);
          constant IdealGases.Common.DataRecord ALO2minus(name = "ALO2minus", MM = 0.0589808866, Hf = -7673201.423187831, H0 = 180476.720741597, Tlimit = 1000, alow = {117867.8641, -1507.186304, 9.52474975, -0.000520798902, -1.586902345e-006, 1.700455028e-009, -5.30141977e-013}, blow = {-48254.6927, -30.81215859}, ahigh = {-187241.0758, -233.8853263, 7.67607002, -7.093570299999999e-005, 1.576717569e-008, -1.816494162e-012, 8.449707959999999e-017}, bhigh = {-55946.40560000001, -17.73751567}, R_s = R_NASA_2002/ALO2minus.MM);
          constant IdealGases.Common.DataRecord AL_OH_2(name = "AL_OH_2", MM = 0.060996218, Hf = -8322822.080542764, H0 = 229973.8485425441, Tlimit = 1000, alow = {4397.31691, 132.7680339, 1.093947024, 0.03054059173, -4.37594335e-005, 3.17461743e-008, -9.004259400000001e-012}, blow = {-63154.3739, 21.01977655}, ahigh = {1669643.735, -5924.73828, 15.49480264, -0.000538348808, 5.413044529999999e-008, -1.196022328e-012, -1.082001733e-016}, bhigh = {-26975.25061, -66.17911543}, R_s = R_NASA_2002/AL_OH_2.MM);
          constant IdealGases.Common.DataRecord AL_OH_2CL(name = "AL_OH_2CL", MM = 0.096449218, Hf = -8906829.332716828, H0 = 178560.6701342047, Tlimit = 1000, alow = {24778.79709, -445.457721, 5.9284702, 0.02730162734, -4.04140537e-005, 2.97421041e-008, -8.477150599999999e-012}, blow = {-103377.803, -3.679940779}, ahigh = {1603911.487, -5767.23224, 18.17772266, -0.000369181615, 1.137918702e-008, 4.0830794e-012, -3.64132343e-016}, bhigh = {-71186.9985, -77.57541774000001}, R_s = R_NASA_2002/AL_OH_2CL.MM);
          constant IdealGases.Common.DataRecord AL_OH_2F(name = "AL_OH_2F", MM = 0.07999462119999999, Hf = -13371257.86652266, H0 = 205914.4821602081, Tlimit = 1000, alow = {21328.12662, -193.2900224, 3.069174664, 0.0355501733, -5.18115833e-005, 3.75352028e-008, -1.059220701e-011}, blow = {-129579.7992, 10.01897011}, ahigh = {1559238.236, -5841.27303, 18.23229919, -0.000390780542, 1.610928938e-008, 3.54478406e-012, -3.39345388e-016}, bhigh = {-96231.0089, -79.71351802}, R_s = R_NASA_2002/AL_OH_2F.MM);
          constant IdealGases.Common.DataRecord AL_OH_3(name = "AL_OH_3", MM = 0.078003558, Hf = -12982325.01137961, H0 = 225563.6467249353, Tlimit = 1000, alow = {-14024.75452, 369.607346, -0.297960065, 0.0492985935, -6.98157228e-005, 5.0148017e-008, -1.412480165e-011}, blow = {-125526.076, 27.11490074}, ahigh = {2477063.616, -8968.617249999999, 22.80320998, -0.0008320292249999999, 8.66349443e-008, -2.420287082e-012, -1.331746442e-016}, bhigh = {-70152.7864, -112.1899198}, R_s = R_NASA_2002/AL_OH_3.MM);
          constant IdealGases.Common.DataRecord ALS(name = "ALS", MM = 0.059046538, Hf = 3940654.556241722, H0 = 153914.3412607866, Tlimit = 1000, alow = {26117.42801, -347.067389, 4.43620459, 0.00334016821, -8.41019967e-006, 8.50818511e-009, -2.780868507e-012}, blow = {28637.79062, 0.7522705491}, ahigh = {8909844.290000001, -25076.77454, 28.93456134, -0.00983976682, 2.045319809e-006, -2.08797089e-010, 8.152792520000001e-015}, bhigh = {188576.1615, -178.6036457}, R_s = R_NASA_2002/ALS.MM);
          constant IdealGases.Common.DataRecord ALS2(name = "ALS2", MM = 0.09111153799999999, Hf = 2727813.452122826, H0 = 158363.90556814, Tlimit = 1000, alow = {42523.3541, -776.46033, 9.80106896, -0.00391068009, 3.87569597e-006, -2.082025593e-009, 4.68293589e-013}, blow = {31679.6154, -21.78097896}, ahigh = {-68525.6354, -26.71667739, 7.52019386, -8.148565100000001e-006, 1.811865152e-009, -2.086958125e-013, 9.703246379999999e-018}, bhigh = {27583.62737, -7.873490263}, R_s = R_NASA_2002/ALS2.MM);
          constant IdealGases.Common.DataRecord AL2(name = "AL2", MM = 0.053963076, Hf = 9289717.324490547, H0 = 187889.9935207548, Tlimit = 1000, alow = {-5281.50965, -17.27374523, 4.60407701, -0.000261646777, 6.30231997e-007, -3.29093859e-010, 8.888365139999999e-014}, blow = {59007.0639, 3.060188921}, ahigh = {-2320724.102, 9218.70789, -9.44695187, 0.00999992001, -3.154798085e-006, 4.36154481e-010, -2.24115724e-014}, bhigh = {2904.589544, 99.60320745000001}, R_s = R_NASA_2002/AL2.MM);
          constant IdealGases.Common.DataRecord AL2Br6(name = "AL2Br6", MM = 0.533387076, Hf = -1766864.728083513, H0 = 71650.00938267952, Tlimit = 1000, alow = {64833.197, -1947.687811, 28.86989822, -0.01365825785, 1.557883731e-005, -9.486942000000001e-009, 2.385519396e-012}, blow = {-110152.6833, -102.5934782}, ahigh = {-173182.949, -43.42299780000001, 22.0341421, -1.421187503e-005, 3.23863134e-009, -3.80387976e-013, 1.796525455e-017}, bhigh = {-120233.8355, -62.0105495}, R_s = R_NASA_2002/AL2Br6.MM);
          constant IdealGases.Common.DataRecord AL2C2(name = "AL2C2", MM = 0.077984476, Hf = 6988288.284452922, H0 = 207284.8575657545, Tlimit = 1000, alow = {11109.87147, -350.243423, 8.598856, 0.001832528671, 1.035743392e-006, -2.09164989e-009, 7.716068700000001e-013}, blow = {64927.6419, -16.45080239}, ahigh = {159765.1967, -1644.007203, 11.64643675, -0.000437921543, 9.36964011e-008, -1.049615854e-011, 4.78046893e-016}, bhigh = {72048.89810000001, -36.48164252}, R_s = R_NASA_2002/AL2C2.MM);
          constant IdealGases.Common.DataRecord AL2CL6(name = "AL2CL6", MM = 0.266681076, Hf = -4863023.134044952, H0 = 128044.6686063318, Tlimit = 1000, alow = {134093.5279, -3001.037953, 31.43000879, -0.01700408496, 1.786540089e-005, -1.015419943e-008, 2.409630451e-012}, blow = {-147183.0046, -127.4445324}, ahigh = {-275297.5554, -92.48235969999999, 22.07058224, -2.870537915e-005, 6.42332569e-009, -7.4365852e-013, 3.47206467e-017}, bhigh = {-162915.7014, -70.91602129}, R_s = R_NASA_2002/AL2CL6.MM);
          constant IdealGases.Common.DataRecord AL2F6(name = "AL2F6", MM = 0.1679534952, Hf = -15673929.42829332, H0 = 155186.3447019232, Tlimit = 1000, alow = {191506.1289, -3168.24025, 22.45374802, 0.01271532036, -2.488697302e-005, 1.955252096e-008, -5.71208489e-012}, blow = {-304996.255, -93.96473100999999}, ahigh = {-585298.2609999999, -545.0571990000001, 22.4068632, -0.0001627323704, 3.59522504e-008, -4.12120144e-012, 1.909095384e-016}, bhigh = {-321968.391, -85.89867941}, R_s = R_NASA_2002/AL2F6.MM);
          constant IdealGases.Common.DataRecord AL2I6(name = "AL2I6", MM = 0.815389896, Hf = -598176.4520172568, H0 = 50185.76536297918, Tlimit = 1000, alow = {25875.71514, -1280.719742, 26.7771582, -0.009913018470000002, 1.168760413e-005, -7.30391853e-009, 1.874532749e-012}, blow = {-58911.0555, -83.30209321}, ahigh = {-121011.2399, -24.67542774, 22.0199265, -8.46202259e-006, 1.957831901e-009, -2.326573151e-013, 1.108910373e-017}, bhigh = {-65485.2375, -55.28536481}, R_s = R_NASA_2002/AL2I6.MM);
          constant IdealGases.Common.DataRecord AL2O(name = "AL2O", MM = 0.069962476, Hf = -2124157.040982941, H0 = 182619.5230711961, Tlimit = 1000, alow = {7776.5307, -129.4235361, 4.91250952, 0.008604223449999999, -1.217703648e-005, 8.31463487e-009, -2.237722201e-012}, blow = {-18865.12879, -0.02806368311}, ahigh = {-117107.4351, -178.3009166, 7.63321536, -5.33593177e-005, 1.180702791e-008, -1.355444579e-012, 6.28732389e-017}, bhigh = {-19475.80149, -14.15764167}, R_s = R_NASA_2002/AL2O.MM);
          constant IdealGases.Common.DataRecord AL2Oplus(name = "AL2Oplus", MM = 0.0699619274, Hf = 9276048.732756898, H0 = 185545.8887772151, Tlimit = 1000, alow = {68289.25719999999, -909.850417, 8.89656301, -0.000777255438, -4.034655619999999e-007, 6.97731505e-010, -2.417262484e-013}, blow = {80850.07550000001, -21.76216731}, ahigh = {-110222.5105, -121.4571732, 7.59159595, -3.69453916e-005, 8.21852032e-009, -9.473649719999999e-013, 4.40862135e-017}, bhigh = {76149.43580000001, -12.82233856}, R_s = R_NASA_2002/AL2Oplus.MM);
          constant IdealGases.Common.DataRecord AL2O2(name = "AL2O2", MM = 0.08596187600000001, Hf = -4689236.737923215, H0 = 184298.1300221973, Tlimit = 1000, alow = {-19405.60042, 250.8489836, 3.62140379, 0.01951385302, -2.560329071e-005, 1.662721576e-008, -4.3123962e-012}, blow = {-51726.9728, 9.923995945}, ahigh = {-194061.1656, -460.975243, 10.84375637, -0.0001376042893, 3.044733119e-008, -3.49619392e-012, 1.622305079e-016}, bhigh = {-49630.5578, -29.4653809}, R_s = R_NASA_2002/AL2O2.MM);
          constant IdealGases.Common.DataRecord AL2O2plus(name = "AL2O2plus", MM = 0.0859613274, Hf = 6484762.995877144, H0 = 174207.8147574069, Tlimit = 1000, alow = {82920.3499, -1757.427015, 15.25328567, -0.008983131330000001, 8.9539545e-006, -4.8405862e-009, 1.096696856e-012}, blow = {73116.7714, -55.1709255}, ahigh = {-165200.5184, -60.2160697, 10.04626917, -1.892194088e-005, 4.2533012e-009, -4.942390419999999e-013, 2.314507373e-017}, bhigh = {63862.19, -23.45753361}, R_s = R_NASA_2002/AL2O2plus.MM);
          constant IdealGases.Common.DataRecord AL2O3(name = "AL2O3", MM = 0.101961276, Hf = -5363708.178779559, H0 = 192210.9134844487, Tlimit = 1000, alow = {-7443.37432, 88.29004210000001, 5.26466264, 0.02507678848, -3.43454165e-005, 2.30251698e-008, -6.12252928e-012}, blow = {-68726.85950000001, 2.202324298}, ahigh = {-277778.4969, -491.746593, 13.86703888, -0.000146938194, 3.25040649e-008, -3.73086735e-012, 1.730444284e-016}, bhigh = {-67907.5785, -43.75559873}, R_s = R_NASA_2002/AL2O3.MM);
          constant IdealGases.Common.DataRecord AL2S(name = "AL2S", MM = 0.086028076, Hf = 2565198.959000316, H0 = 162783.2639195604, Tlimit = 1000, alow = {40946.2437, -779.7172469999999, 9.814423100000001, -0.00394033982, 3.91246543e-006, -2.105891677e-009, 4.74600108e-013}, blow = {28339.63305, -24.65067552}, ahigh = {-70434.3737, -26.76376869, 7.52023382, -8.16612306e-006, 1.81602604e-009, -2.091989298e-013, 9.727537699999999e-018}, bhigh = {24227.18377, -10.66580982}, R_s = R_NASA_2002/AL2S.MM);
          constant IdealGases.Common.DataRecord AL2S2(name = "AL2S2", MM = 0.118093076, Hf = 1145599.09507311, H0 = 153264.8789671632, Tlimit = 1000, alow = {66145.8732, -1111.319537, 12.57007304, -0.001456053256, -5.85162711e-007, 1.390055053e-009, -5.4964682e-013}, blow = {19144.56895, -36.00277092}, ahigh = {-137780.6456, -77.050325, 10.55723566, -2.277554487e-005, 5.00768285e-009, -5.715862119999999e-013, 2.63799924e-017}, bhigh = {13133.36091, -22.56851594}, R_s = R_NASA_2002/AL2S2.MM);
          constant IdealGases.Common.DataRecord Ar(name = "Ar", MM = 0.039948, Hf = 0, H0 = 155137.3785921698, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {-745.375, 4.37967491}, ahigh = {20.10538475, -0.05992661069999999, 2.500069401, -3.99214116e-008, 1.20527214e-011, -1.819015576e-015, 1.078576636e-019}, bhigh = {-744.993961, 4.37918011}, R_s = R_NASA_2002/Ar.MM);
          constant IdealGases.Common.DataRecord Arplus(name = "Arplus", MM = 0.0399474514, Hf = 38219669.92868035, H0 = 155353.7906050247, Tlimit = 1000, alow = {-57312.0917, 793.079147, -1.717121217, 0.01044184018, -1.180207501e-005, 6.52813478e-009, -1.44755813e-012}, blow = {179057.223, 29.4915095}, ahigh = {-383596.54, 816.20197, 2.301342628, -4.95298377e-006, 1.205108477e-008, -2.185050286e-012, 1.265493898e-016}, bhigh = {177181.1455, 7.94750748}, R_s = R_NASA_2002/Arplus.MM);
          constant IdealGases.Common.DataRecord B(name = "B", MM = 0.010811, Hf = 53241953.5658126, H0 = 584225.326056794, Tlimit = 1000, alow = {118.2394638, -0.0700991691, 2.500236159, -4.5842137e-007, 5.12318583e-010, -3.057217674e-013, 7.533815325e-017}, blow = {68483.59080000001, 4.20950192}, ahigh = {-107265.961, 322.530716, 2.126407232, 0.0002106579339, -5.93712916e-008, 7.37742799e-012, -2.282443381e-016}, bhigh = {66434.13099999999, 6.87706967}, R_s = R_NASA_2002/B.MM);
          constant IdealGases.Common.DataRecord Bplus(name = "Bplus", MM = 0.0108104514, Hf = 127868437.3901352, H0 = 573281.1490184396, Tlimit = 1000, alow = {0.07849791190000001, -0.000894748095, 2.500004085, -9.577271229999999e-009, 1.218136411e-011, -7.98675252e-015, 2.113769829e-018}, blow = {165508.026, 2.419053631}, ahigh = {-8911.54803, 4.58779009, 2.531500086, -4.9039491e-005, 2.853326582e-008, -7.38217591e-012, 7.12072156e-016}, bhigh = {165452.6303, 2.23866978}, R_s = R_NASA_2002/Bplus.MM);
          constant IdealGases.Common.DataRecord Bminus(name = "Bminus", MM = 0.0108115486, Hf = 50189988.32415183, H0 = 580175.7206178586, Tlimit = 1000, alow = {22.01568105, -0.00474046888, 2.500014238, -2.497056599e-008, 2.556360708e-011, -1.41527478e-014, 3.27177071e-018}, blow = {64517.9188, 4.61636729}, ahigh = {21.18018248, 0.0002070697496, 2.499999729, 1.456693631e-010, -3.88857176e-014, 5.09059863e-018, -2.601566168e-022}, bhigh = {64517.8914, 4.61645583}, R_s = R_NASA_2002/Bminus.MM);
          constant IdealGases.Common.DataRecord BBr(name = "BBr", MM = 0.090715, Hf = 2656146.81144243, H0 = 99179.38598908672, Tlimit = 1000, alow = {37960.935, -497.609602, 5.2670082, -3.74284019e-005, -1.13154437e-006, 1.261945702e-009, -4.28881188e-013}, blow = {30381.25367, -4.35340733}, ahigh = {253685.8027, -640.59095, 4.66682347, 0.000417548639, -2.963714868e-007, 7.51911954e-011, -4.83536832e-015}, bhigh = {31890.8434, -0.8255870910000001}, R_s = R_NASA_2002/BBr.MM);
          constant IdealGases.Common.DataRecord BBr2(name = "BBr2", MM = 0.170619, Hf = 573374.6944947515, H0 = 71508.54828594705, Tlimit = 1000, alow = {65165.5071, -902.959076, 8.063817800000001, 0.00112984901, -4.19548239e-006, 3.96565877e-009, -1.283029835e-012}, blow = {14704.66408, -13.36453164}, ahigh = {-419163.337, 415.768847, 7.14816983, -0.000568959075, 3.19544177e-007, -5.55317699e-011, 3.19113676e-015}, bhigh = {6118.98205, -5.50275962}, R_s = R_NASA_2002/BBr2.MM);
          constant IdealGases.Common.DataRecord BBr3(name = "BBr3", MM = 0.250523, Hf = -819485.6360493847, H0 = 62680.06131173585, Tlimit = 1000, alow = {39680.7369, -633.108716, 8.054551569999999, 0.009777571299999999, -1.614866025e-005, 1.216119883e-008, -3.51653961e-012}, blow = {-23667.23308, -11.0609939}, ahigh = {-190104.6795, -150.3627687, 10.10999896, -4.32309511e-005, 9.409696190000001e-009, -1.06521847e-012, 4.883048770000001e-017}, bhigh = {-27425.53062, -19.97496003}, R_s = R_NASA_2002/BBr3.MM);
          constant IdealGases.Common.DataRecord BC(name = "BC", MM = 0.0228217, Hf = 36726532.42308855, H0 = 382754.3522174071, Tlimit = 1000, alow = {-39157.58, 728.453806, -1.552743361, 0.01552898673, -1.976857863e-005, 1.272066405e-008, -3.22998278e-012}, blow = {96449.13680000001, 32.48204466}, ahigh = {-2346280.674, 6450.7513, -2.619532384, 0.0033391605, -4.50802214e-007, 1.351919576e-011, 8.265104270000001e-016}, bhigh = {57866.8507, 50.37884876}, R_s = R_NASA_2002/BC.MM);
          constant IdealGases.Common.DataRecord BC2(name = "BC2", MM = 0.0348324, Hf = 23003259.17823635, H0 = 335544.6366027033, Tlimit = 1000, alow = {-29874.22175, 364.312658, 2.963469415, 0.00656175015, -3.53976724e-006, 1.927356029e-010, 3.118724866e-013}, blow = {93048.3573, 10.83424193}, ahigh = {1525485.889, -5987.862380000001, 14.08384855, -0.0037474998, 1.081927223e-006, -1.378744645e-010, 6.473822e-015}, bhigh = {131120.4013, -63.37215498}, R_s = R_NASA_2002/BC2.MM);
          constant IdealGases.Common.DataRecord BCL(name = "BCL", MM = 0.046264, Hf = 3959308.25263704, H0 = 191538.4964551271, Tlimit = 1000, alow = {22024.58989, -170.0511155, 3.066075869, 0.00559507018, -8.46087041e-006, 6.08473341e-009, -1.702889433e-012}, blow = {21974.02537, 6.388978917}, ahigh = {-74212.6254, 263.8090127, 3.60022765, 0.001018866266, -4.666184119999999e-007, 9.849002029999999e-011, -6.46881817e-015}, bhigh = {19127.2648, 5.235317877}, R_s = R_NASA_2002/BCL.MM);
          constant IdealGases.Common.DataRecord BCLplus(name = "BCLplus", MM = 0.0462634514, Hf = 26679375.67667076, H0 = 191518.7417253525, Tlimit = 1000, alow = {65144.0542, -684.554101, 5.52727682, -0.000445835745, -4.55772884e-007, 6.37085816e-010, -2.13436612e-013}, blow = {150942.4507, -6.918246393}, ahigh = {-216942.3542, 358.997516, 4.03520837, 0.000327445243, -8.63457845e-008, 1.207061044e-011, -5.262253270000001e-016}, bhigh = {144547.7224, 3.488222017}, R_s = R_NASA_2002/BCLplus.MM);
          constant IdealGases.Common.DataRecord BCLOH(name = "BCLOH", MM = 0.06327134, Hf = -3698441.996012729, H0 = 196479.4644779137, Tlimit = 1000, alow = {-28984.27288, 689.404658, -2.288138069, 0.0334942862, -4.72522598e-005, 3.32698131e-008, -9.224238860000001e-012}, blow = {-32619.811, 39.76886651}, ahigh = {702773.844, -2857.391274, 10.9117584, -8.10770934e-005, -2.124440337e-008, 5.40991244e-012, -3.46415384e-016}, bhigh = {-13072.21888, -35.85168799}, R_s = R_NASA_2002/BCLOH.MM);
          constant IdealGases.Common.DataRecord BCL_OH_2(name = "BCL_OH_2", MM = 0.08027867999999999, Hf = -10032397.8670302, H0 = 168975.1625213569, Tlimit = 1000, alow = {80726.23009999999, -859.461982, 2.705039614, 0.0387879962, -5.72173435e-005, 4.14585033e-008, -1.168536754e-011}, blow = {-93799.10739999999, 7.134982695}, ahigh = {1423878.191, -5849.70407, 17.92165219, -0.0002009909087, -3.39343578e-008, 9.838560759999999e-012, -6.47267882e-016}, bhigh = {-64742.6176, -81.00399519}, R_s = R_NASA_2002/BCL_OH_2.MM);
          constant IdealGases.Common.DataRecord BCL2(name = "BCL2", MM = 0.081717, Hf = -745028.4518521237, H0 = 140896.2761726446, Tlimit = 1000, alow = {35988.7942, -360.28265, 4.15768545, 0.0115287745, -1.816567395e-005, 1.341714418e-008, -3.84082286e-012}, blow = {-6765.107050000001, 5.182311874}, ahigh = {350140.313, -1662.20359, 8.83953472, -0.000977254411, 2.467356248e-007, -2.501151018e-011, 8.722954559999999e-016}, bhigh = {568.2909440000001, -21.48348344}, R_s = R_NASA_2002/BCL2.MM);
          constant IdealGases.Common.DataRecord BCL2plus(name = "BCL2plus", MM = 0.0817164514, Hf = 8227417.985994433, H0 = 157236.4166562426, Tlimit = 1000, alow = {80659.5624, -1149.602601, 10.16765297, -0.00358649491, 2.837145924e-006, -1.225075731e-009, 2.224794198e-013}, blow = {84786.1741, -29.37256994}, ahigh = {302929.3331, -1305.533159, 8.920390060000001, -0.000728991964, 1.727833266e-007, -1.523567337e-011, 4.22691144e-016}, bhigh = {86534.15770000001, -22.67466616}, R_s = R_NASA_2002/BCL2plus.MM);
          constant IdealGases.Common.DataRecord BCL2OH(name = "BCL2OH", MM = 0.09872433999999999, Hf = -6127338.445615337, H0 = 142333.3799952474, Tlimit = 1000, alow = {20997.5517, -247.0699169, 2.578761742, 0.03120362393, -4.54531405e-005, 3.24201177e-008, -9.039822660000001e-012}, blow = {-73090.2862, 12.73658611}, ahigh = {587811.379, -2982.969317, 14.00662004, -0.0001194189832, -1.269775742e-008, 4.42289219e-012, -3.004089365e-016}, bhigh = {-58241.6807, -51.50858228}, R_s = R_NASA_2002/BCL2OH.MM);
          constant IdealGases.Common.DataRecord BF(name = "BF", MM = 0.0298094032, Hf = -3587186.341254897, H0 = 291675.4133474233, Tlimit = 1000, alow = {-52389.5473, 811.8476640000001, -1.141614903, 0.01161249417, -1.175212617e-005, 6.01923278e-009, -1.238293129e-012}, blow = {-17745.41998, 30.05086287}, ahigh = {-374638.978, 560.449391, 3.60918611, 0.000618721693, -1.77893877e-007, 2.426601527e-011, -9.394651579999999e-016}, bhigh = {-18191.79292, 3.71660929}, R_s = R_NASA_2002/BF.MM);
          constant IdealGases.Common.DataRecord BFCL(name = "BFCL", MM = 0.0652624032, Hf = -4277869.865509336, H0 = 169056.6001100003, Tlimit = 1000, alow = {-23635.12735, 438.316898, 0.391809572, 0.01719990692, -2.139592424e-005, 1.337389186e-008, -3.37116469e-012}, blow = {-36871.6659, 26.68102752}, ahigh = {-108630.9561, -523.343848, 7.29750474, -3.054410701e-005, -3.154598306e-008, 1.052290533e-011, -7.615432260000001e-016}, bhigh = {-33058.9121, -11.86586595}, R_s = R_NASA_2002/BFCL.MM);
          constant IdealGases.Common.DataRecord BFCL2(name = "BFCL2", MM = 0.1007154032, Hf = -6384326.325171282, H0 = 131369.3097542005, Tlimit = 1000, alow = {4402.55124, -157.1398929, 4.01632231, 0.01743396078, -2.25278906e-005, 1.433673443e-008, -3.64875558e-012}, blow = {-78224.52619999999, 6.886094746}, ahigh = {-223361.3309, -644.060296, 10.47861848, -0.0001911892367, 4.22488779e-008, -4.84726692e-012, 2.247974725e-016}, bhigh = {-77406.2648, -28.14630564}, R_s = R_NASA_2002/BFCL2.MM);
          constant IdealGases.Common.DataRecord BFOH(name = "BFOH", MM = 0.0468167432, Hf = -9646798.284764072, H0 = 255744.4448634778, Tlimit = 1000, alow = {-75639.5367, 1354.838128, -5.64821011, 0.0387027466, -5.03765918e-005, 3.33959264e-008, -8.847822949999999e-012}, blow = {-61944.4611, 58.0036282}, ahigh = {725131.809, -3215.62085, 11.17909777, -0.0001883881929, 2.57970808e-009, 2.6651581e-012, -2.186647438e-016}, bhigh = {-37168.0808, -39.7846349}, R_s = R_NASA_2002/BFOH.MM);
          constant IdealGases.Common.DataRecord BF_OH_2(name = "BF_OH_2", MM = 0.06382408319999999, Hf = -16449739.44568937, H0 = 201886.4878892612, Tlimit = 1000, alow = {13818.00676, 252.9637004, -3.84455204, 0.0525514085, -7.19311773e-005, 4.94830991e-008, -1.345922496e-011}, blow = {-128312.3258, 42.9365937}, ahigh = {1422037.64, -6257.297570000001, 18.22460686, -0.000322139645, -7.1267399e-009, 6.75869977e-012, -5.04255454e-016}, bhigh = {-91862.5419, -85.27895049999999}, R_s = R_NASA_2002/BF_OH_2.MM);
          constant IdealGases.Common.DataRecord BF2(name = "BF2", MM = 0.04880780639999999, Hf = -10232521.00098479, H0 = 217428.3743266118, Tlimit = 1000, alow = {-67876.51760000001, 1085.903536, -3.023320961, 0.02326503687, -2.641444147e-005, 1.515620683e-008, -3.51855918e-012}, blow = {-66409.18250000001, 44.31968310000001}, ahigh = {-115309.1296, -810.9800119999999, 7.60270923, -0.0002409209242, 5.32847186e-008, -6.11879794e-012, 2.839984178e-016}, bhigh = {-57962.2217, -16.55644047}, R_s = R_NASA_2002/BF2.MM);
          constant IdealGases.Common.DataRecord BF2plus(name = "BF2plus", MM = 0.0488072578, Hf = 6609394.064339341, H0 = 217436.5755906082, Tlimit = 1000, alow = {-29383.56477, 295.5698598, 1.894274526, 0.01280508319, -1.388757254e-005, 7.62436675e-009, -1.706339371e-012}, blow = {35989.9244, 13.84803311}, ahigh = {-176940.9966, -534.368518, 7.72805291, -1.958622052e-006, -2.419680893e-008, 5.73253381e-012, -3.21635423e-016}, bhigh = {39087.4505, -19.36560315}, R_s = R_NASA_2002/BF2plus.MM);
          constant IdealGases.Common.DataRecord BF2minus(name = "BF2minus", MM = 0.048808355, Hf = -15034371.94308229, H0 = 213766.0857449509, Tlimit = 1000, alow = {21097.65318, 143.95646, 0.2604646296, 0.01817373751, -2.241565287e-005, 1.369712886e-008, -3.35595268e-012}, blow = {-89718.0178, 23.51692604}, ahigh = {-170992.0627, -615.621979, 7.45887137, -0.0001836703248, 4.064363959999999e-008, -4.66770095e-012, 2.16626484e-016}, bhigh = {-87414.0453, -16.20604664}, R_s = R_NASA_2002/BF2minus.MM);
          constant IdealGases.Common.DataRecord BF2CL(name = "BF2CL", MM = 0.08426080640000001, Hf = -10538707.59062662, H0 = 146256.5281122208, Tlimit = 1000, alow = {4500.10125, -119.6284966, 3.19863514, 0.01743426933, -1.994070287e-005, 1.12513643e-008, -2.544020371e-012}, blow = {-107677.9851, 10.08195015}, ahigh = {-206681.7398, -1024.447292, 10.75843981, -0.0003023235319, 6.67252147e-008, -7.6499419e-012, 3.5462245e-016}, bhigh = {-104693.6725, -32.29995036}, R_s = R_NASA_2002/BF2CL.MM);
          constant IdealGases.Common.DataRecord BF2OH(name = "BF2OH", MM = 0.0658151464, Hf = -16595227.41713448, H0 = 188343.9858153989, Tlimit = 1000, alow = {-7522.52165, 436.712169, -3.128973474, 0.04323957680000001, -5.78549404e-005, 3.88585813e-008, -1.038574523e-011}, blow = {-134425.9458, 41.3917055}, ahigh = {576075.9250000001, -3611.90019, 14.4689764, -0.0003028293733, 2.764337508e-008, -1.90549317e-013, -8.69497194e-017}, bhigh = {-113358.9041, -58.9698151}, R_s = R_NASA_2002/BF2OH.MM);
          constant IdealGases.Common.DataRecord BF3(name = "BF3", MM = 0.0678062096, Hf = -16753627.82703017, H0 = 171831.2536378674, Tlimit = 1000, alow = {3465.584, 21.33198651, 1.641245191, 0.01993755064, -2.15011993e-005, 1.145669081e-008, -2.442285789e-012}, blow = {-137945.5591, 16.25533544}, ahigh = {-181976.7014, -1405.347931, 11.03412258, -0.000410459105, 9.031277570000001e-008, -1.03305736e-011, 4.780551830000001e-016}, bhigh = {-132313.6863, -37.3838608}, R_s = R_NASA_2002/BF3.MM);
          constant IdealGases.Common.DataRecord BF4minus(name = "BF4minus", MM = 0.0868051614, Hf = -20289876.42663378, H0 = 158926.5289932403, Tlimit = 1000, alow = {206848.52, -2463.190805, 12.06414196, 0.01102766923, -1.75172076e-005, 1.201346256e-008, -3.150588626e-012}, blow = {-201056.9206, -46.1082694}, ahigh = {-437324.171, -775.928941, 13.58222575, -0.0002341024178, 5.19691594e-008, -5.982245780000001e-012, 2.781163206e-016}, bhigh = {-212725.1877, -49.533697}, R_s = R_NASA_2002/BF4minus.MM);
          constant IdealGases.Common.DataRecord BH(name = "BH", MM = 0.01181894, Hf = 37966789.23829041, H0 = 730954.2141681063, Tlimit = 1000, alow = {20630.8255, -368.250252, 6.07133787, -0.00872832107, 1.458566459e-005, -1.036840401e-008, 2.779462579e-012}, blow = {54604.5992, -13.00392582}, ahigh = {-1098531.663, -174.5890126, 8.442426810000001, -0.00544019667, 2.718307052e-006, -4.83981221e-010, 2.868523222e-014}, bhigh = {50167.3567, -29.71030686}, R_s = R_NASA_2002/BH.MM);
          constant IdealGases.Common.DataRecord BHCL(name = "BHCL", MM = 0.04727194, Hf = 2991590.931110507, H0 = 217989.9322938725, Tlimit = 1000, alow = {47632.7491, -442.001652, 3.97564588, 0.008541698759999999, -1.377785182e-005, 1.131521587e-008, -3.56965918e-012}, blow = {18222.78428, 3.028452399}, ahigh = {349999.172, -2238.404757, 8.71110605, -0.001088882906, 4.18930109e-007, -6.56871126e-011, 3.6200676e-015}, bhigh = {28412.40364, -25.89566225}, R_s = R_NASA_2002/BHCL.MM);
          constant IdealGases.Common.DataRecord BHCL2(name = "BHCL2", MM = 0.08272494, Hf = -3044831.81251023, H0 = 141984.170674527, Tlimit = 1000, alow = {44199.1481, -238.4739577, 1.356682235, 0.02517866897, -3.6329104e-005, 2.644335581e-008, -7.62504411e-012}, blow = {-30038.77914, 17.87024616}, ahigh = {411099.606, -2858.027441, 11.79547506, -0.000632281797, 1.269551549e-007, -1.352862344e-011, 5.92165351e-016}, bhigh = {-16172.8876, -42.17900972}, R_s = R_NASA_2002/BHCL2.MM);
          constant IdealGases.Common.DataRecord BHF(name = "BHF", MM = 0.0308173432, Hf = -2466544.325599099, H0 = 325857.3243912862, Tlimit = 1000, alow = {-49083.6226, 961.0760210000001, -2.919850316, 0.02149156633, -2.595677863e-005, 1.693492714e-008, -4.55364884e-012}, blow = {-14669.25195, 41.6070931}, ahigh = {1184821.3, -4677.43518, 10.67328148, -0.001606366598, 3.7045347e-007, -3.79788275e-011, 1.432441145e-015}, bhigh = {18026.40937, -42.85931169999999}, R_s = R_NASA_2002/BHF.MM);
          constant IdealGases.Common.DataRecord BHFCL(name = "BHFCL", MM = 0.0662703432, Hf = -7288880.616510825, H0 = 172242.0384266246, Tlimit = 1000, alow = {576.116972, 304.215625, -0.9808900360000001, 0.02803843648, -3.67673402e-005, 2.499824138e-008, -6.87342164e-012}, blow = {-60502.0739, 31.32842092}, ahigh = {439077.892, -3137.181709, 12.00286161, -0.000715366934, 1.453878608e-007, -1.56519707e-011, 6.910075059999999e-016}, bhigh = {-42323.6834, -44.66542881}, R_s = R_NASA_2002/BHFCL.MM);
          constant IdealGases.Common.DataRecord BHF2(name = "BHF2", MM = 0.0498157464, Hf = -14846988.44138969, H0 = 213975.4549577521, Tlimit = 1000, alow = {-83535.40280000001, 1616.659766, -8.161405670000001, 0.0415378679, -4.92106328e-005, 3.054165306e-008, -7.78681398e-012}, blow = {-97480.65459999999, 70.3863075}, ahigh = {466087.6960000001, -3728.10049, 12.44152658, -0.000890684319, 1.841732568e-007, -2.010774349e-011, 8.979196590000001e-016}, bhigh = {-69781.4293, -51.0321804}, R_s = R_NASA_2002/BHF2.MM);
          constant IdealGases.Common.DataRecord BH2(name = "BH2", MM = 0.01282688, Hf = 25642171.6738599, H0 = 781449.5029188704, Tlimit = 1000, alow = {28125.57296, -300.0083489, 4.824221, -0.0002186429819, 1.485457398e-006, 3.89373968e-010, -6.331629389999999e-013}, blow = {39919.8842, -5.04268285}, ahigh = {1360117.365, -4917.70449, 9.75897103, -0.000741587064, 1.269760019e-007, -1.187742442e-011, 4.68255251e-016}, bhigh = {68902.92660000001, -41.9049012}, R_s = R_NASA_2002/BH2.MM);
          constant IdealGases.Common.DataRecord BH2CL(name = "BH2CL", MM = 0.04827988, Hf = -1674522.679012458, H0 = 215967.8524470235, Tlimit = 1000, alow = {16466.38117, 127.7320942, 0.1300268921, 0.01938143193, -2.316389616e-005, 1.607896164e-008, -4.66833765e-012}, blow = {-11121.12215, 23.08500112}, ahigh = {1427215.437, -6265.56434, 13.82183005, -0.001313843556, 2.587131606e-007, -2.71384527e-011, 1.172827257e-015}, bhigh = {26393.87516, -63.99725308}, R_s = R_NASA_2002/BH2CL.MM);
          constant IdealGases.Common.DataRecord BH2F(name = "BH2F", MM = 0.0318252832, Hf = -10179225.42791387, H0 = 318549.3098769974, Tlimit = 1000, alow = {-88379.2044, 1705.285929, -8.061246130000001, 0.0364318868, -4.15248255e-005, 2.620135756e-008, -6.930886410000001e-012}, blow = {-47872.7341, 68.6208767}, ahigh = {1435082.111, -6625.32017, 14.09165008, -0.00142246906, 2.828724718e-007, -2.992498948e-011, 1.302618926e-015}, bhigh = {-793.719267, -68.013564}, R_s = R_NASA_2002/BH2F.MM);
          constant IdealGases.Common.DataRecord BH3(name = "BH3", MM = 0.01383482, Hf = 7571229.622069531, H0 = 727129.0121591751, Tlimit = 1000, alow = {-66196.3507, 1262.658391, -4.6543559, 0.02461795131, -2.501537437e-005, 1.562330756e-008, -4.32394948e-012}, blow = {5667.58798, 46.66504620000001}, ahigh = {1855778.95, -8002.492370000001, 15.05692199, -0.001790456689, 3.6125111e-007, -3.86603591e-011, 1.698508879e-015}, bhigh = {59675.3707, -79.94046159999999}, R_s = R_NASA_2002/BH3.MM);
          constant IdealGases.Common.DataRecord BH3NH3(name = "BH3NH3", MM = 0.03086534, Hf = -3725862.083489118, H0 = 410866.3633706935, Tlimit = 1000, alow = {-181106.3598, 3010.341543, -15.24271135, 0.0621563775, -5.95988185e-005, 3.26742936e-008, -7.75124309e-012}, blow = {-29342.78877, 108.7399608}, ahigh = {4354925.96, -18242.35232, 31.6299983, -0.00320824361, 5.88507545e-007, -5.80853553e-011, 2.3825786e-015}, bhigh = {94381.18030000001, -189.7865799}, R_s = R_NASA_2002/BH3NH3.MM);
          constant IdealGases.Common.DataRecord BH4(name = "BH4", MM = 0.01484276, Hf = 17194273.6391345, H0 = 725665.3749033199, Tlimit = 1000, alow = {27342.74578, -84.73619380000001, 1.551871695, 0.01439765491, -6.11115236e-006, -1.324417559e-010, 5.13300815e-013}, blow = {30220.48074, 12.50358328}, ahigh = {1354714.146, -7870.76275, 18.2617061, -0.001948275329, 4.07270689e-007, -4.4827109e-011, 2.014115885e-015}, bhigh = {74702.49489999999, -96.8608689}, R_s = R_NASA_2002/BH4.MM);
          constant IdealGases.Common.DataRecord BI(name = "BI", MM = 0.13771547, Hf = 2367108.807746871, H0 = 66384.71335137585, Tlimit = 1000, alow = {35174.4953, -544.5819300000001, 6.02751101, -0.002387237926, 2.244796277e-006, -1.110001347e-009, 2.280204403e-013}, blow = {40719.1013, -7.28804984}, ahigh = {2132872.626, -6283.684960000001, 11.23964343, -0.00325885675, 7.06428215e-007, -4.23006893e-011, -4.20807847e-016}, bhigh = {77976.3481, -46.6404261}, R_s = R_NASA_2002/BI.MM);
          constant IdealGases.Common.DataRecord BI2(name = "BI2", MM = 0.26461994, Hf = 899767.1301716719, H0 = 47949.61407670186, Tlimit = 1000, alow = {66409.75900000001, -1044.411994, 9.73419724, -0.00395255754, 3.16556778e-006, -1.273764644e-009, 1.879968132e-013}, blow = {32057.5089, -20.12407058}, ahigh = {-392402.223, 442.290235, 7.12962358, -0.000561963406, 3.18076052e-007, -5.537079720000001e-011, 3.1839597e-015}, bhigh = {22919.72638, -3.20179324}, R_s = R_NASA_2002/BI2.MM);
          constant IdealGases.Common.DataRecord BI3(name = "BI3", MM = 0.39152441, Hf = 54658.1501776607, H0 = 43249.08375444586, Tlimit = 1000, alow = {62431.1489, -1002.408628, 11.06650075, 0.001609588058, -5.14725025e-006, 4.73251402e-009, -1.512999796e-012}, blow = {5160.34815, -24.20687643}, ahigh = {-150617.6506, -81.67210609999999, 10.05937867, -2.319396215e-005, 5.01996673e-009, -5.65434963e-013, 2.580651348e-017}, bhigh = {-426.168791, -16.17962779}, R_s = R_NASA_2002/BI3.MM);
          constant IdealGases.Common.DataRecord BN(name = "BN", MM = 0.0248177, Hf = 23157923.90108673, H0 = 361077.2956398055, Tlimit = 1000, alow = {-45697.0758, 670.4286070000001, 0.0361508908, 0.007339487509999999, -4.96903349e-006, 1.22903138e-009, 6.34028152e-014}, blow = {64854.6508, 25.39869896}, ahigh = {-227693.2705, -102.5649298, 4.41458681, 0.0002561670989, -1.612994942e-008, -6.526052929999999e-013, 5.74946612e-017}, bhigh = {67844.6513, -0.6778568656}, R_s = R_NASA_2002/BN.MM);
          constant IdealGases.Common.DataRecord BO(name = "BO", MM = 0.0268104, Hf = 761137.6182376987, H0 = 323535.0461015128, Tlimit = 1000, alow = {-11662.16822, 92.17579389999999, 3.65549849, -0.00311854292, 9.00832983e-006, -8.017789990000001e-009, 2.472952292e-012}, blow = {873.8284780000001, 4.48284739}, ahigh = {17886.00589, -630.901963, 4.5745284, 0.0001988001643, -9.70296348e-008, 1.870854291e-011, -1.030218131e-015}, bhigh = {4841.311089999999, -3.39889058}, R_s = R_NASA_2002/BO.MM);
          constant IdealGases.Common.DataRecord BOminus(name = "BOminus", MM = 0.0268109486, Hf = -10361105.8356958, H0 = 323525.4421397086, Tlimit = 1000, alow = {-82420.23209999999, 920.3636899999999, -0.2302659981, 0.006229904119999999, -3.157624391e-006, 1.184578107e-010, 2.819228693e-013}, blow = {-39111.4122, 25.99226838}, ahigh = {212280.4369, -1262.124688, 5.38316731, -0.00031810491, 7.28898825e-008, -8.141708919999999e-012, 3.71536439e-016}, bhigh = {-27068.92261, -9.77375367}, R_s = R_NASA_2002/BOminus.MM);
          constant IdealGases.Common.DataRecord BOCL(name = "BOCL", MM = 0.0622634, Hf = -5115954.075749156, H0 = 170371.5666025305, Tlimit = 1000, alow = {70523.8064, -1315.301429, 11.30087727, -0.0120711205, 1.880516131e-005, -1.373823975e-008, 3.85489016e-012}, blow = {-33553.991, -36.98462517}, ahigh = {155714.8487, -1446.254968, 8.50944805, -0.000385900738, 8.26226882e-008, -9.261027459999999e-012, 4.21999801e-016}, bhigh = {-32035.8904, -23.72713292}, R_s = R_NASA_2002/BOCL.MM);
          constant IdealGases.Common.DataRecord BOCL2(name = "BOCL2", MM = 0.0977164, Hf = -3700151.786189422, H0 = 134774.2037160599, Tlimit = 1000, alow = {7322.66736, -202.7726965, 4.16192409, 0.01733309456, -2.263908718e-005, 1.45227519e-008, -3.71959312e-012}, blow = {-44144.4188, 6.52042411}, ahigh = {-229752.7041, -619.456793, 10.46075518, -0.0001841620739, 4.07121543e-008, -4.67224655e-012, 2.167237536e-016}, bhigh = {-43715.3842, -27.43570215}, R_s = R_NASA_2002/BOCL2.MM);
          constant IdealGases.Common.DataRecord BOF(name = "BOF", MM = 0.0458088032, Hf = -12944636.61080759, H0 = 218043.1336830909, Tlimit = 1000, alow = {72268.02649999999, -1131.38663, 8.81605452, -0.00462769457, 7.80129958e-006, -5.681205839999999e-009, 1.534732094e-012}, blow = {-67111.16009999999, -25.47957229}, ahigh = {193702.0297, -1739.112297, 8.695650860000001, -0.000451889557, 9.59101908e-008, -1.067806769e-011, 4.840007660000001e-016}, bhigh = {-63301.5239, -27.02458617}, R_s = R_NASA_2002/BOF.MM);
          constant IdealGases.Common.DataRecord BOF2(name = "BOF2", MM = 0.0648072064, Hf = -12849924.35656045, H0 = 179169.2412774639, Tlimit = 1000, alow = {7227.79413, 21.48783624, 1.157840301, 0.02250585296, -2.610731536e-005, 1.508824929e-008, -3.51836485e-012}, blow = {-101399.5733, 20.10127136}, ahigh = {-220502.8861, -1254.23869, 10.9255138, -0.0003680144, 8.10716494e-008, -9.28127506e-012, 4.2975493e-016}, bhigh = {-96804.47579999999, -34.8285333}, R_s = R_NASA_2002/BOF2.MM);
          constant IdealGases.Common.DataRecord BOH(name = "BOH", MM = 0.02781834, Hf = -242882.1417812853, H0 = 360608.2893515573, Tlimit = 1000, alow = {-75214.1027, 1391.444703, -5.63033018, 0.02966358811, -3.83083518e-005, 2.550606424e-008, -6.79585721e-012}, blow = {-8341.300280000001, 55.17690039999999}, ahigh = {844749.8570000001, -3016.982887, 8.0838647, -0.0001609855388, -2.191830959e-009, 3.127133119e-012, -2.376665451e-016}, bhigh = {16476.98495, -26.03227947}, R_s = R_NASA_2002/BOH.MM);
          constant IdealGases.Common.DataRecord BO2(name = "BO2", MM = 0.0428098, Hf = -7220822.031404024, H0 = 251628.2953903078, Tlimit = 1000, alow = {-41410.9064, 719.885461, -1.477629435, 0.02277415194, -2.786326934e-005, 1.718462069e-008, -4.27899144e-012}, blow = {-41776.5769, 32.5845801}, ahigh = {-38344.5234, -956.326114, 8.200962779999999, -0.0002062130802, 9.87228899e-009, 8.15836676e-012, -7.52751966e-016}, bhigh = {-34235.6402, -22.24772278}, R_s = R_NASA_2002/BO2.MM);
          constant IdealGases.Common.DataRecord BO2minus(name = "BO2minus", MM = 0.0428103486, Hf = -16689749.42661411, H0 = 224187.4059395069, Tlimit = 1000, alow = {53242.7969, -732.631303, 5.90247, 0.0024374652, -4.87880395e-007, -8.47572476e-010, 4.08078118e-013}, blow = {-83442.9368, -10.53931911}, ahigh = {119922.6372, -1715.766982, 8.701038219999999, -0.000460124212, 9.867011870000001e-008, -1.107288516e-011, 5.05018324e-016}, bhigh = {-78257.89689999999, -28.39356505}, R_s = R_NASA_2002/BO2minus.MM);
          constant IdealGases.Common.DataRecord B_OH_2(name = "B_OH_2", MM = 0.04482568, Hf = -9486607.721288333, H0 = 267071.4197754501, Tlimit = 1000, alow = {1491.659222, 364.818484, -2.906006389, 0.0413683446, -5.78258422e-005, 4.069783560000001e-008, -1.126499791e-011}, blow = {-53754.8366, 38.8853518}, ahigh = {1557023.406, -5784.71076, 14.87391235, -0.0001821804765, -3.80354164e-008, 1.030332746e-011, -6.68588983e-016}, bhigh = {-18068.10301, -65.902689}, R_s = R_NASA_2002/B_OH_2.MM);
          constant IdealGases.Common.DataRecord BS(name = "BS", MM = 0.042876, Hf = 6379312.552476911, H0 = 203472.9219143577, Tlimit = 1000, alow = {-38394.901, 698.941749, -1.21398046, 0.01396391264, -1.689881284e-005, 1.038889985e-008, -2.582063989e-012}, blow = {28656.85472, 31.54819945}, ahigh = {1358760.165, -4364.03596, 9.034307589999999, -0.002114548699, 4.18927531e-007, -1.354787322e-011, -1.360684605e-015}, bhigh = {59130.6545, -33.36696868}, R_s = R_NASA_2002/BS.MM);
          constant IdealGases.Common.DataRecord BS2(name = "BS2", MM = 0.07494100000000001, Hf = 852236.559426749, H0 = 180936.4700230848, Tlimit = 1000, alow = {18202.64374, -515.067189, 8.547515000000001, -0.001626155268, 1.866387194e-006, -1.277165468e-009, 3.68198069e-013}, blow = {8186.839750000001, -17.78384854}, ahigh = {512040.251, -1938.581076, 9.814873459999999, -0.001339731606, 3.75430116e-007, -4.40038378e-011, 1.887662968e-015}, bhigh = {17365.35, -27.57546712}, R_s = R_NASA_2002/BS2.MM);
          constant IdealGases.Common.DataRecord B2(name = "B2", MM = 0.021622, Hf = 39652691.98039035, H0 = 407229.0259920451, Tlimit = 1000, alow = {-151641.8096, 2630.168946, -13.81358321, 0.05216225190000001, -6.93049474e-005, 4.46941039e-008, -1.128496456e-011}, blow = {89952.5105, 98.13118490000001}, ahigh = {1094594.495, -2602.735739, 6.90945621, -0.0006405949889999999, 1.951732355e-007, -2.555902119e-011, 1.053557323e-015}, bhigh = {118780.7611, -19.49045025}, R_s = R_NASA_2002/B2.MM);
          constant IdealGases.Common.DataRecord B2C(name = "B2C", MM = 0.0336327, Hf = 23799237.46829722, H0 = 348562.9759133224, Tlimit = 1000, alow = {-41665.1987, 579.777952, 1.411017091, 0.01174705713, -1.066474425e-005, 4.71723262e-009, -7.97001326e-013}, blow = {91968.742, 17.69254387}, ahigh = {1159241.019, -4567.79881, 12.28672097, -0.002500830701, 6.40997985e-007, -6.932935770000001e-011, 2.672933741e-015}, bhigh = {122244.2137, -51.99066186}, R_s = R_NASA_2002/B2C.MM);
          constant IdealGases.Common.DataRecord B2CL4(name = "B2CL4", MM = 0.163434, Hf = -2998152.159281422, H0 = 132090.8256543926, Tlimit = 1000, alow = {42855.5513, -728.074881, 9.315763670000001, 0.02331629623, -3.51124761e-005, 2.464057658e-008, -6.73547996e-012}, blow = {-58190.2324, -16.22083878}, ahigh = {-642798.703, 507.856299, 14.86725022, 2.026983515e-006, 6.27271881e-009, -1.218822573e-012, 7.241208409999999e-017}, bhigh = {-68200.66, -41.39110669}, R_s = R_NASA_2002/B2CL4.MM);
          constant IdealGases.Common.DataRecord B2F4(name = "B2F4", MM = 0.09761561279999999, Hf = -14731250.0403624, H0 = 181126.6916515224, Tlimit = 1000, alow = {-59716.9564, 818.9425440000001, -0.643767129, 0.0385896607, -4.31305319e-005, 2.404463223e-008, -5.39355935e-012}, blow = {-179004.1225, 35.5217997}, ahigh = {38558.6589, -2928.842655, 17.92063736, -0.000952399827, 1.614708845e-007, -1.428613504e-011, 5.21873967e-016}, bhigh = {-161305.1924, -71.8480325}, R_s = R_NASA_2002/B2F4.MM);
          constant IdealGases.Common.DataRecord B2H(name = "B2H", MM = 0.02262994, Hf = 35186239.86630102, H0 = 447000.6106953885, Tlimit = 1000, alow = {87755.7974, -1343.931564, 9.83209915, -0.00560713775, 5.730651049999999e-006, -2.266436197e-009, 1.97235208e-013}, blow = {100990.8698, -32.8246148}, ahigh = {617554.5750000001, -2627.897466, 9.08490507, -0.000538941833, 1.0507147e-007, -1.092459556e-011, 4.68485466e-016}, bhigh = {109953.7555, -31.6402991}, R_s = R_NASA_2002/B2H.MM);
          constant IdealGases.Common.DataRecord B2H2(name = "B2H2", MM = 0.02363788, Hf = 19235140.33407395, H0 = 447300.6462508482, Tlimit = 1000, alow = {142161.7322, -2138.011262, 13.17732399, -0.00894265807, 1.127804935e-005, -5.7878862e-009, 1.000813871e-012}, blow = {63723.19250000001, -53.4698274}, ahigh = {1240614.592, -5368.96502, 13.79292454, -0.001136749748, 2.245617156e-007, -2.361530467e-011, 1.022604572e-015}, bhigh = {85065.1149, -64.354613}, R_s = R_NASA_2002/B2H2.MM);
          constant IdealGases.Common.DataRecord B2H3(name = "B2H3", MM = 0.02464582, Hf = 14244716.58885767, H0 = 484407.5384791417, Tlimit = 1000, alow = {94251.4716, -1075.866284, 6.38399939, 0.01167858327, -1.429661252e-005, 1.128776882e-008, -3.68132506e-012}, blow = {46353.3508, -14.00002845}, ahigh = {1771506.902, -7872.26093, 17.89447015, -0.001709304785, 3.40957543e-007, -3.61454368e-011, 1.575671409e-015}, bhigh = {87377.1189, -90.5462946}, R_s = R_NASA_2002/B2H3.MM);
          constant IdealGases.Common.DataRecord B2H3_db(name = "B2H3_db", MM = 0.02464582, Hf = 14339479.35187387, H0 = 483296.0315380052, Tlimit = 1000, alow = {60640.1484, -752.446633, 5.58448384, 0.01080468494, -8.64903281e-006, 4.74833331e-009, -1.309096028e-012}, blow = {44917.923, -8.87368682}, ahigh = {1497731.017, -7219.31414, 17.50463766, -0.0015796988, 3.16410347e-007, -3.36722515e-011, 1.472919654e-015}, bhigh = {83243.4967, -87.79549259999999}, R_s = R_NASA_2002/B2H3_db.MM);
          constant IdealGases.Common.DataRecord B2H4(name = "B2H4", MM = 0.02565376, Hf = 8231232.341769785, H0 = 481015.6094077438, Tlimit = 1000, alow = {40001.323, -307.1548876, 1.763071673, 0.02646361882, -3.066168202e-005, 2.163781936e-008, -6.49183541e-012}, blow = {25810.33714, 10.1526713}, ahigh = {2292078.842, -10598.32517, 22.68612155, -0.002363586598, 4.76217307e-007, -5.0901004e-011, 2.23391159e-015}, bhigh = {86385.91979999999, -124.6794566}, R_s = R_NASA_2002/B2H4.MM);
          constant IdealGases.Common.DataRecord B2H4_db(name = "B2H4_db", MM = 0.02565376, Hf = 8183301.31723381, H0 = 449394.0849216645, Tlimit = 1000, alow = {-17814.96923, 571.6048040000001, -2.763085348, 0.03125348696, -2.709524346e-005, 1.341728634e-008, -3.004352798e-012}, blow = {21581.38307, 36.7587294}, ahigh = {1886854.256, -10100.45614, 22.47110812, -0.002319968667, 4.73187996e-007, -5.11067303e-011, 2.262693782e-015}, bhigh = {82334.87, -123.7455797}, R_s = R_NASA_2002/B2H4_db.MM);
          constant IdealGases.Common.DataRecord B2H5(name = "B2H5", MM = 0.0266617, Hf = 9556175.67521951, H0 = 458364.9579734226, Tlimit = 1000, alow = {38309.6545, -40.6614805, -1.422523787, 0.0367459527, -3.85198971e-005, 2.44449444e-008, -6.82172294e-012}, blow = {30089.56452, 28.02425895}, ahigh = {2696691.012, -13200.19835, 27.35260413, -0.002961879012, 5.98499943e-007, -6.41374855e-011, 2.821187823e-015}, bhigh = {106452.4901, -155.9654379}, R_s = R_NASA_2002/B2H5.MM);
          constant IdealGases.Common.DataRecord B2H5_db(name = "B2H5_db", MM = 0.0266617, Hf = 10320070.21307719, H0 = 437613.3554874596, Tlimit = 1000, alow = {14244.46027, 420.45582, -3.70045125, 0.036720531, -3.19350373e-005, 1.695013434e-008, -4.25703814e-012}, blow = {30466.84683, 42.45495820000001}, ahigh = {2571729.448, -13568.29858, 27.81376038, -0.00319236503, 6.56116526e-007, -7.12733394e-011, 3.16949265e-015}, bhigh = {110637.0527, -159.7214457}, R_s = R_NASA_2002/B2H5_db.MM);
          constant IdealGases.Common.DataRecord B2H6(name = "B2H6", MM = 0.02766964, Hf = 1322749.410545276, H0 = 431242.0761527797, Tlimit = 1000, alow = {-10528.44558, 1041.795556, -8.960518860000001, 0.0549248088, -5.30519705e-005, 3.011904756e-008, -7.688768300000001e-012}, blow = {-925.9374349999999, 68.12592429999999}, ahigh = {2835765.414, -15676.00163, 32.2612233, -0.00373860973, 7.71880646e-007, -8.41445454e-011, 3.75222338e-015}, bhigh = {93583.7855, -192.0223395}, R_s = R_NASA_2002/B2H6.MM);
          constant IdealGases.Common.DataRecord B2O(name = "B2O", MM = 0.0376214, Hf = 5124690.149755193, H0 = 313199.8809188387, Tlimit = 1000, alow = {-56995.4676, 1018.000465, -2.636481947, 0.02746009279, -3.63243272e-005, 2.406890217e-008, -6.38412972e-012}, blow = {17038.74394, 38.5534611}, ahigh = {-162872.322, -387.628981, 7.78772352, -0.0001146822108, 2.528097612e-008, -2.893783941e-012, 1.339210475e-016}, bhigh = {22630.35354, -19.08513011}, R_s = R_NASA_2002/B2O.MM);
          constant IdealGases.Common.DataRecord B2O2(name = "B2O2", MM = 0.0536208, Hf = -8536080.886521647, H0 = 249839.9501685913, Tlimit = 1000, alow = {81743.9169, -1732.702797, 16.05560926, -0.02160057288, 3.56685457e-005, -2.660198794e-008, 7.531833240000001e-012}, blow = {-48996.32900000001, -61.72702390000001}, ahigh = {460578.966, -2990.079203, 12.56764079, -0.000785097495, 1.672537624e-007, -1.86769478e-011, 8.486190669999999e-016}, bhigh = {-40157.4815, -48.7441371}, R_s = R_NASA_2002/B2O2.MM);
          constant IdealGases.Common.DataRecord B2O3(name = "B2O3", MM = 0.06962019999999999, Hf = -11999136.32824956, H0 = 207105.5383351384, Tlimit = 1000, alow = {73796.11910000001, -1263.620592, 10.72681512, 0.000384138372, 5.97605838e-006, -6.55289135e-009, 2.123951064e-012}, blow = {-96281.83140000001, -30.88078011}, ahigh = {390503.53, -3691.34821, 15.55502598, -0.0009707645510000001, 2.068887872e-007, -2.310858356e-011, 1.050136734e-015}, bhigh = {-82630.5441, -63.9086344}, R_s = R_NASA_2002/B2O3.MM);
          constant IdealGases.Common.DataRecord B2_OH_4(name = "B2_OH_4", MM = 0.08965136, Hf = -13998533.10646933, H0 = 216874.2225438633, Tlimit = 1000, alow = {-17287.17249, 849.591348, -8.715959570000001, 0.0936236261, -0.0001278784165, 8.81367116e-008, -2.400605571e-011}, blow = {-156433.7133, 71.2016931}, ahigh = {2983925.656, -12074.69577, 31.6261057, -0.000516368244, -4.23209397e-008, 1.67197728e-011, -1.156366726e-015}, bhigh = {-82809.76969999999, -165.3010498}, R_s = R_NASA_2002/B2_OH_4.MM);
          constant IdealGases.Common.DataRecord B2S(name = "B2S", MM = 0.053687, Hf = 11590528.52645892, H0 = 245547.4323393, Tlimit = 1000, alow = {66386.09299999999, -920.1185690000001, 8.699831339999999, 0.000764558901, -3.70902603e-006, 3.64237398e-009, -1.197766071e-012}, blow = {77703.758, -22.51712444}, ahigh = {-121150.1483, -64.73398450000001, 7.54682561, -1.82054145e-005, 3.92395117e-009, -4.40386238e-013, 2.003651718e-017}, bhigh = {72585.3187, -13.94971229}, R_s = R_NASA_2002/B2S.MM);
          constant IdealGases.Common.DataRecord B2S2(name = "B2S2", MM = 0.085752, Hf = 1612989.924433249, H0 = 169898.2181173617, Tlimit = 1000, alow = {-70615.4997, 718.294478, 1.919797788, 0.02036407461, -2.309813846e-005, 1.311616725e-008, -2.996394781e-012}, blow = {11008.29019, 18.55402586}, ahigh = {-164153.5014, -774.286564, 11.07731737, -0.0002313278554, 5.12561429e-008, -5.89408123e-012, 2.738673834e-016}, bhigh = {17330.03515, -33.59766998}, R_s = R_NASA_2002/B2S2.MM);
          constant IdealGases.Common.DataRecord B2S3(name = "B2S3", MM = 0.117817, Hf = 150691.8101801947, H0 = 169229.0331615981, Tlimit = 1000, alow = {-34312.685, 558.761537, 3.41407741, 0.02398333891, -2.841617637e-005, 1.690005199e-008, -4.060070709999999e-012}, blow = {-3027.690575, 18.46767864}, ahigh = {-190585.5086, -934.8342479999999, 13.69333613, -0.000276664725, 6.1101558e-008, -7.00804857e-012, 3.24952462e-016}, bhigh = {2906.43376, -39.46870479}, R_s = R_NASA_2002/B2S3.MM);
          constant IdealGases.Common.DataRecord B3H7_C2v(name = "B3H7_C2v", MM = 0.03948858, Hf = 4457469.450661431, H0 = 375258.8469881672, Tlimit = 1000, alow = {108600.9469, -792.15368, -0.9577368039999999, 0.0565611929, -6.4050345e-005, 4.28132296e-008, -1.227580455e-011}, blow = {24306.38819, 21.02582666}, ahigh = {3598592.14, -18637.01968, 39.9399883, -0.00427541016, 8.705358820000001e-007, -9.38510502e-011, 4.14786531e-015}, bhigh = {127215.4092, -237.9769856}, R_s = R_NASA_2002/B3H7_C2v.MM);
          constant IdealGases.Common.DataRecord B3H7_Cs(name = "B3H7_Cs", MM = 0.03948858, Hf = 4034541.682683955, H0 = 356642.9078989419, Tlimit = 1000, alow = {52981.69330000001, 407.174537, -9.63573053, 0.07944312000000001, -9.306456819999999e-005, 6.105147350000001e-008, -1.685927691e-011}, blow = {17070.69083, 68.73966560000001}, ahigh = {3281576.45, -18110.96595, 39.6383246, -0.00417842411, 8.52682906e-007, -9.20960024e-011, 4.076496770000001e-015}, bhigh = {121362.2564, -235.7090217}, R_s = R_NASA_2002/B3H7_Cs.MM);
          constant IdealGases.Common.DataRecord B3H9(name = "B3H9", MM = 0.04150446, Hf = 3346840.315474529, H0 = 417543.9217857551, Tlimit = 1000, alow = {84832.14900000001, -520.616304, -0.466570121, 0.0534698386, -4.15579682e-005, 1.944135439e-008, -4.54122735e-012}, blow = {18051.011, 21.10804198}, ahigh = {3863999.5, -22294.33407, 48.7504615, -0.00541844926, 1.125767651e-006, -1.233226406e-010, 5.52034818e-015}, bhigh = {142218.7123, -295.8240102}, R_s = R_NASA_2002/B3H9.MM);
          constant IdealGases.Common.DataRecord B3N3H6(name = "B3N3H6", MM = 0.08050073999999999, Hf = -6360189.980862289, H0 = 201505.5762220323, Tlimit = 1000, alow = {-155262.1082, 4010.21127, -33.824913, 0.1624575582, -0.0002065528647, 1.368862991e-007, -3.6734709e-011}, blow = {-80512.534, 199.5000751}, ahigh = {3739245.17, -19412.38951, 44.4507003, -0.00321030805, 5.71746542e-007, -5.48669214e-011, 2.191943197e-015}, bhigh = {47584.2616, -264.1156625}, R_s = R_NASA_2002/B3N3H6.MM);
          constant IdealGases.Common.DataRecord B3O3CL3(name = "B3O3CL3", MM = 0.1867902, Hf = -8758393.325774049, H0 = 130905.0528346776, Tlimit = 1000, alow = {-42844.52800000001, 1005.623966, -4.55651963, 0.08117967139999999, -0.0001038385803, 6.62142233e-008, -1.695748504e-011}, blow = {-204090.7277, 54.66113803}, ahigh = {-741405.981, -2527.447455, 26.87263667, -0.000746338936, 1.64633411e-007, -1.886231553e-011, 8.737926310000001e-016}, bhigh = {-192350.9858, -118.5636255}, R_s = R_NASA_2002/B3O3CL3.MM);
          constant IdealGases.Common.DataRecord B3O3FCL2(name = "B3O3FCL2", MM = 0.1703356032, Hf = -11059388.90995162, H0 = 137658.4728001245, Tlimit = 1000, alow = {-37191.2007, 867.3745889999999, -4.09577846, 0.0781556397, -9.767035169999999e-005, 6.09761009e-008, -1.532880319e-011}, blow = {-233138.3552, 51.98088158}, ahigh = {-716236.083, -2851.210308, 27.10953133, -0.000840091964, 1.852318684e-007, -2.121694694e-011, 9.827291560000002e-016}, bhigh = {-220272.9252, -121.0679365}, R_s = R_NASA_2002/B3O3FCL2.MM);
          constant IdealGases.Common.DataRecord B3O3F2CL(name = "B3O3F2CL", MM = 0.1538810064, Hf = -13860169.47053188, H0 = 144663.6691609264, Tlimit = 1000, alow = {-52770.1554, 1104.904696, -5.85418105, 0.07953943099999999, -9.59266077e-005, 5.79985631e-008, -1.416698348e-011}, blow = {-264040.0115, 60.71247222}, ahigh = {-681078.749, -3370.00902, 27.48953579, -0.000990544256, 2.18290844e-007, -2.49957348e-011, 1.157532106e-015}, bhigh = {-247211.4785, -126.1501548}, R_s = R_NASA_2002/B3O3F2CL.MM);
          constant IdealGases.Common.DataRecord B3O3F3(name = "B3O3F3", MM = 0.1374264096, Hf = -17337999.9152652, H0 = 154269.7510741051, Tlimit = 1000, alow = {-72515.4978, 1400.996228, -7.9067162, 0.0821716185, -9.63315266e-005, 5.66819426e-008, -1.349024305e-011}, blow = {-295346.1728, 70.01536830000001}, ahigh = {-662982.291, -3784.94687, 27.79526578, -0.001112096232, 2.450806704e-007, -2.80648498e-011, 1.299750466e-015}, bhigh = {-274886.5475, -131.5605015}, R_s = R_NASA_2002/B3O3F3.MM);
          constant IdealGases.Common.DataRecord B4H4(name = "B4H4", MM = 0.04727576, Hf = 6899738.893674052, H0 = 315946.3115981636, Tlimit = 1000, alow = {217179.1579, -2598.282557, 9.845440610000001, 0.0302630914, -4.128334159999999e-005, 3.089368344e-008, -9.35338426e-012}, blow = {50791.4348, -37.7075721}, ahigh = {1937200.886, -10781.85932, 28.79625241, -0.002401547707, 4.83775678e-007, -5.17049023e-011, 2.269138182e-015}, bhigh = {98365.95389999999, -156.1814117}, R_s = R_NASA_2002/B4H4.MM);
          constant IdealGases.Common.DataRecord B4H10(name = "B4H10", MM = 0.0533234, Hf = 1239605.876594516, H0 = 290408.6011019553, Tlimit = 1000, alow = {-32966.04820000001, 2440.532922, -26.85332563, 0.1406499347, -0.0001586710574, 9.87459413e-008, -2.601426018e-011}, blow = {-3091.924018, 158.9905532}, ahigh = {4030474.13, -25606.29762, 56.8723366, -0.00617856786, 1.280621032e-006, -1.400254585e-010, 6.258866560000001e-015}, bhigh = {150600.9087, -352.07142}, R_s = R_NASA_2002/B4H10.MM);
          constant IdealGases.Common.DataRecord B4H12(name = "B4H12", MM = 0.05533928000000001, Hf = 3401491.924000457, H0 = 393006.8117980573, Tlimit = 1000, alow = {71521.70299999999, -159.0351575, -4.71977166, 0.088112289, -8.60494688e-005, 5.12353551e-008, -1.37986525e-011}, blow = {21941.86547, 41.878974}, ahigh = {6158360.8, -32020.8673, 66.60443599999999, -0.00740636928, 1.512993908e-006, -1.635619071e-010, 7.24538514e-015}, bhigh = {205458.6275, -414.210686}, R_s = R_NASA_2002/B4H12.MM);
          constant IdealGases.Common.DataRecord B5H9(name = "B5H9", MM = 0.06312646, Hf = 1159893.965224725, H0 = 254293.9521715617, Tlimit = 1000, alow = {89984.7372, 104.2533357, -11.95549834, 0.1007310686, -9.866680210000001e-005, 5.29553518e-008, -1.232119583e-011}, blow = {8374.341780000001, 76.6309048}, ahigh = {3169017.62, -22825.03203, 55.1200898, -0.005563411420000001, 1.157837073e-006, -1.270332301e-010, 5.69426203e-015}, bhigh = {133445.2571, -337.106046}, R_s = R_NASA_2002/B5H9.MM);
          constant IdealGases.Common.DataRecord Ba(name = "Ba", MM = 0.137327, Hf = 1347149.504467439, H0 = 45128.98410363585, Tlimit = 1000, alow = {2222.563526, -34.0797785, 2.706751118, -0.0006382894490000001, 1.063003846e-006, -9.10262427e-010, 3.148062219e-013}, blow = {21665.49702, 5.10254588}, ahigh = {-19265792.28, 60065.0104, -66.3396413, 0.0350756593, -7.80760183e-006, 8.0851268e-010, -3.199486918e-014}, bhigh = {-358966.372, 500.75834}, R_s = R_NASA_2002/Ba.MM);
          constant IdealGases.Common.DataRecord Baplus(name = "Baplus", MM = 0.1373264514, Hf = 5054011.961456684, H0 = 45129.16438762649, Tlimit = 1000, alow = {-54231.6755, 674.468078, -0.8940272500000001, 0.008796642950000001, -1.222812901e-005, 8.387953870000001e-009, -2.037964358e-012}, blow = {79417.7464, 26.07063698}, ahigh = {8794971.85, -19518.17883, 14.85542861, -0.00094042335, -7.03125779e-007, 1.667412753e-010, -1.07011731e-014}, bhigh = {214680.0732, -92.28264190000002}, R_s = R_NASA_2002/Baplus.MM);
          constant IdealGases.Common.DataRecord BaBr(name = "BaBr", MM = 0.217231, Hf = -346749.2070652899, H0 = 46955.19055751711, Tlimit = 1000, alow = {-691.2557439999999, -62.4550016, 4.79667765, -0.000683800494, 1.04394768e-006, -7.4412243e-010, 2.172187003e-013}, blow = {-10113.49165, 5.19645487}, ahigh = {-1056014.042, 1034.740207, 6.73572938, -0.0037840263, 1.952196896e-006, -3.34783188e-010, 1.893189803e-014}, bhigh = {-19502.33645, -5.06927964}, R_s = R_NASA_2002/BaBr.MM);
          constant IdealGases.Common.DataRecord BaBr2(name = "BaBr2", MM = 0.297135, Hf = -1388307.473034143, H0 = 52116.91318760833, Tlimit = 1000, alow = {-5143.37406, -38.7051846, 7.16244697, -0.000369671531, 4.68971527e-007, -3.107902475e-010, 8.36358205e-014}, blow = {-51533.1826, 0.9741407000000001}, ahigh = {-8928.25121, -0.753655889, 7.00065821, -2.94982171e-007, 7.092392109999999e-011, -8.670038099999999e-015, 4.22174231e-019}, bhigh = {-51726.6949, 1.910185706}, R_s = R_NASA_2002/BaBr2.MM);
          constant IdealGases.Common.DataRecord BaCL(name = "BaCL", MM = 0.17278, Hf = -788811.6738048386, H0 = 57165.86989234866, Tlimit = 1000, alow = {-2661.946867, -77.2499634, 4.74610605, -0.000352354888, 3.99919835e-007, -1.936413749e-010, 4.124048529999999e-014}, blow = {-17363.28141, 3.904455084}, ahigh = {-1075410.089, 1209.303069, 6.2725586, -0.00328811031, 1.717751087e-006, -2.910607065e-010, 1.632658438e-014}, bhigh = {-27791.73737, -3.574185216}, R_s = R_NASA_2002/BaCL.MM);
          constant IdealGases.Common.DataRecord BaCLplus(name = "BaCLplus", MM = 0.1727794514, Hf = 2018166.090785492, H0 = 55957.05925479053, Tlimit = 1000, alow = {-895.155669, -133.4692684, 4.93541612, -0.000757405451, 8.355724e-007, -4.68525851e-010, 1.095343103e-013}, blow = {41251.5599, 1.896278378}, ahigh = {-18291.98157, -2.931616688, 4.50228071, 3.67178849e-005, 2.396147871e-009, 5.4794586e-014, 1.174342316e-018}, bhigh = {40551.00150000001, 4.503765564}, R_s = R_NASA_2002/BaCLplus.MM);
          constant IdealGases.Common.DataRecord BaCL2(name = "BaCL2", MM = 0.208233, Hf = -2397801.438772913, H0 = 70109.50713863796, Tlimit = 1000, alow = {-1157.501999, -205.4518828, 7.83751405, -0.001867700704, 2.335378734e-006, -1.531373341e-009, 4.08852509e-013}, blow = {-61156.6528, -5.978149218}, ahigh = {-22165.98768, -4.00248381, 7.00342674, -1.515820808e-006, 3.61184921e-010, -4.38675906e-014, 2.125803293e-018}, bhigh = {-62190.9527, -1.132439694}, R_s = R_NASA_2002/BaCL2.MM);
          constant IdealGases.Common.DataRecord BaF(name = "BaF", MM = 0.1563254032, Hf = -2040575.501295109, H0 = 59760.67746358449, Tlimit = 1000, alow = {25303.17292, -471.69951, 6.18503622, -0.0033666788, 4.011834559999999e-006, -2.506578601e-009, 6.47725816e-013}, blow = {-37318.7214, -6.22071538}, ahigh = {1868380.434, -7071.099600000001, 14.66959284, -0.0069959502, 2.366313845e-006, -3.2877343e-010, 1.647896238e-014}, bhigh = {3571.78068, -66.6239092}, R_s = R_NASA_2002/BaF.MM);
          constant IdealGases.Common.DataRecord BaFplus(name = "BaFplus", MM = 0.1563248546, Hf = 857593.7226555399, H0 = 58862.77024562158, Tlimit = 1000, alow = {28407.19922, -486.357182, 5.94605839, -0.002429844077, 2.445346729e-006, -1.316757471e-009, 2.97488632e-013}, blow = {17306.39076, -5.95120693}, ahigh = {-40544.2367, -17.01997704, 4.51305534, 2.632753508e-005, 2.612088236e-009, -9.502197929999999e-014, 6.515176160000001e-018}, bhigh = {14744.8657, 2.783167711}, R_s = R_NASA_2002/BaFplus.MM);
          constant IdealGases.Common.DataRecord BaF2(name = "BaF2", MM = 0.1753238064, Hf = -4631450.227286418, H0 = 76641.14346994921, Tlimit = 1000, alow = {34883.9552, -764.845956, 9.79775038, -0.00575645751, 6.7756038e-006, -4.24361475e-009, 1.093687692e-012}, blow = {-95903.56449999999, -20.82035292}, ahigh = {-55086.3366, -16.91114228, 7.01356488, -5.73190977e-006, 1.321203959e-009, -1.565528167e-013, 7.444983019999999e-018}, bhigh = {-99835.29700000001, -4.38958149}, R_s = R_NASA_2002/BaF2.MM);
          constant IdealGases.Common.DataRecord BaH(name = "BaH", MM = 0.13833494, Hf = 1514694.010059932, H0 = 63115.68863224288, Tlimit = 1000, alow = {-37652.6888, 698.668012, -1.313524351, 0.01460648882, -1.802974829e-005, 1.133031115e-008, -2.865589059e-012}, blow = {20974.78889, 32.308026}, ahigh = {-6755466.57, 17307.00212, -11.36812458, 0.00561774474, -3.18078885e-007, -1.052342502e-010, 1.111101879e-014}, bhigh = {-89540.70379999999, 118.2377538}, R_s = R_NASA_2002/BaH.MM);
          constant IdealGases.Common.DataRecord BaI(name = "BaI", MM = 0.26423147, Hf = -38745.10102827645, H0 = 39348.54920952451, Tlimit = 1000, alow = {-4186.28554, 10.33094613, 4.42890023, 0.0003026019976, -2.591429408e-007, 1.7416054e-010, -3.370062760000001e-014}, blow = {-2636.169733, 8.201924679999999}, ahigh = {-3533859.66, 7394.258, 1.285151488, -0.002303429302, 2.214839289e-006, -4.68109681e-010, 3.011371472e-014}, bhigh = {-53402.2959, 37.1044387}, R_s = R_NASA_2002/BaI.MM);
          constant IdealGases.Common.DataRecord BaI2(name = "BaI2", MM = 0.39113594, Hf = -737441.7318950542, H0 = 40370.70845496836, Tlimit = 1000, alow = {-4241.592729999999, -18.62214382, 7.07855675, -0.0001793922821, 2.281437677e-007, -1.514647881e-010, 4.08149836e-014}, blow = {-36703.5149, 3.16313897}, ahigh = {-6048.2248, -0.362272945, 7.00031745, -1.425793502e-007, 3.43334942e-011, -4.201754979999999e-015, 2.047703474e-019}, bhigh = {-36796.5075, 3.61547532}, R_s = R_NASA_2002/BaI2.MM);
          constant IdealGases.Common.DataRecord BaO(name = "BaO", MM = 0.1533264, Hf = -769263.4275636812, H0 = 58790.31921443405, Tlimit = 1000, alow = {37643.985, -507.15553, 5.39284728, -0.000411932469, -6.52789662e-007, 9.430588419999999e-010, -3.43660303e-013}, blow = {-12755.52614, -3.75221376}, ahigh = {13184816.98, -38542.5325, 46.8674161, -0.02188646633, 5.335677450000001e-006, -5.1523043e-010, 1.4330834e-014}, bhigh = {230690.2396, -302.8332772}, R_s = R_NASA_2002/BaO.MM);
          constant IdealGases.Common.DataRecord BaOplus(name = "BaOplus", MM = 0.1533258514, Hf = 3337367.321477009, H0 = 61762.48762705387, Tlimit = 1000, alow = {356641.097, -3779.24671, 16.73544137, -0.0130661161, 2.686157445e-006, 4.044077950000001e-009, -2.016508813e-012}, blow = {79832.68490000001, -72.8511855}, ahigh = {-331767.923, 1594.253495, 3.22724781, 0.00057226415, -1.147415658e-007, 1.382873231e-011, -6.38443703e-016}, bhigh = {50252.4761, 14.09092365}, R_s = R_NASA_2002/BaOplus.MM);
          constant IdealGases.Common.DataRecord BaOH(name = "BaOH", MM = 0.15433434, Hf = -1453056.481143471, H0 = 72728.99213486773, Tlimit = 1000, alow = {37762.3151, -889.139022, 9.531718, -0.0054588259, 4.94178301e-006, -1.809327537e-009, 2.050048305e-013}, blow = {-24418.52965, -24.89410158}, ahigh = {2637336.694, -8365.410400000001, 15.99803975, -0.005098446049999999, 1.594657431e-006, -2.180478542e-010, 1.084610688e-014}, bhigh = {23935.50647, -74.9070579}, R_s = R_NASA_2002/BaOH.MM);
          constant IdealGases.Common.DataRecord BaOHplus(name = "BaOHplus", MM = 0.1543337914, Hf = 1308976.544717996, H0 = 73237.2340332462, Tlimit = 1000, alow = {27976.32165, -768.07694, 9.05297844, -0.0043685779, 3.52349726e-006, -8.38636087e-010, -6.47545747e-014}, blow = {26232.80802, -22.64561641}, ahigh = {876673.843, -2335.8196, 7.97316606, 0.0001038679898, -6.31948578e-008, 1.028729445e-011, -5.74180857e-016}, bhigh = {37725.1747, -19.30805001}, R_s = R_NASA_2002/BaOHplus.MM);
          constant IdealGases.Common.DataRecord Ba_OH_2(name = "Ba_OH_2", MM = 0.17134168, Hf = -3540682.407222807, H0 = 101485.6688693609, Tlimit = 1000, alow = {57028.149, -1577.384797, 16.59935325, -0.01039598275, 9.664889600000001e-006, -3.67362144e-009, 4.62578499e-013}, blow = {-68351.58899999999, -58.51911699999999}, ahigh = {1762908.112, -4676.205419999999, 13.95135494, 0.0002051842928, -1.25726553e-007, 2.048917625e-011, -1.144045777e-015}, bhigh = {-45459.6441, -49.2945719}, R_s = R_NASA_2002/Ba_OH_2.MM);
          constant IdealGases.Common.DataRecord BaS(name = "BaS", MM = 0.169392, Hf = 229475.5065174271, H0 = 56414.20492112969, Tlimit = 1000, alow = {13770.75147, -329.350056, 5.81154584, -0.00284897376, 3.57633602e-006, -2.325649347e-009, 6.17280531e-013}, blow = {4964.43245, -3.497962615}, ahigh = {6104262.07, -22276.17479, 35.9751351, -0.0215779374, 7.31987235e-006, -1.089038636e-009, 5.88410195e-014}, bhigh = {140413.8006, -214.1776331}, R_s = R_NASA_2002/BaS.MM);
          constant IdealGases.Common.DataRecord Ba2(name = "Ba2", MM = 0.274654, Hf = 1296046.432966569, H0 = 41357.9885965615, Tlimit = 1000, alow = {-12941.77083, -727.633008, 14.64866569, -0.0396633165, 5.89871106e-005, -4.23530056e-008, 1.189594362e-011}, blow = {43867.1223, -41.4567367}, ahigh = {216011.4547, 195.0676877, 2.253699771, 0.0001507750613, -4.742515e-008, 7.04895196e-012, -3.54744017e-016}, bhigh = {41677.6297, 23.75906459}, R_s = R_NASA_2002/Ba2.MM);
          constant IdealGases.Common.DataRecord Be(name = "Be", MM = 0.009012181999999999, Hf = 35951337.86690061, H0 = 687672.3084376237, Tlimit = 1000, alow = {-0.000411290152, 5.36496736e-006, 2.499999972, 7.56920369e-011, -1.097852652e-013, 8.00211024e-017, -2.303022777e-020}, blow = {38222.6459, 2.146172983}, ahigh = {-692628.584, 2466.773005, -0.9776613340000001, 0.002458939515, -9.047950419999999e-007, 1.587880407e-010, -9.415600603e-015}, bhigh = {23002.12917, 26.23234754}, R_s = R_NASA_2002/Be.MM);
          constant IdealGases.Common.DataRecord Beplus(name = "Beplus", MM = 0.0090116334, Hf = 136457096.4460228, H0 = 687714.1717726777, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {147152.8569, 2.839228698}, ahigh = {-94781.35979999999, 276.8325398, 2.191388413, 0.0001648824289, -4.28016682e-008, 4.54235047e-012, -6.270417825e-017}, bhigh = {145385.0986, 5.05550384}, R_s = R_NASA_2002/Beplus.MM);
          constant IdealGases.Common.DataRecord Beplusplus(name = "Beplusplus", MM = 0.009011084800000001, Hf = 332146638.7709501, H0 = 687756.0402050593, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {359227.916, 2.145990203}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {359227.916, 2.145990203}, R_s = R_NASA_2002/Beplusplus.MM);
          constant IdealGases.Common.DataRecord BeBr(name = "BeBr", MM = 0.08891618200000001, Hf = 1489563.598221075, H0 = 100893.9857539092, Tlimit = 1000, alow = {37462.8806, -472.233907, 5.03940904, 0.0005798853219999999, -1.937634343e-006, 1.793372625e-009, -5.67229558e-013}, blow = {17231.35679, -2.573912886}, ahigh = {821723.8139999999, -2850.509348, 8.017266019999999, -0.002105663212, 6.84913634e-007, -9.98912932e-011, 5.192456840000001e-015}, bhigh = {32293.7287, -23.26810811}, R_s = R_NASA_2002/BeBr.MM);
          constant IdealGases.Common.DataRecord BeBr2(name = "BeBr2", MM = 0.168820182, Hf = -1386460.411469051, H0 = 76042.45445014389, Tlimit = 1000, alow = {-21186.98678, 209.0382611, 3.73117131, 0.01115501549, -1.542821761e-005, 1.052354444e-008, -2.850006057e-012}, blow = {-30904.56277, 9.458917720000001}, ahigh = {-104133.1811, -154.3443092, 7.61446541, -4.55670063e-005, 1.003180548e-008, -1.146879501e-012, 5.30179538e-017}, bhigh = {-29845.27608, -11.4936098}, R_s = R_NASA_2002/BeBr2.MM);
          constant IdealGases.Common.DataRecord BeCL(name = "BeCL", MM = 0.044465182, Hf = 1274999.998875525, H0 = 199281.9235508808, Tlimit = 1000, alow = {20161.38947, -141.3988978, 2.898223773, 0.00606992551, -9.162038470000001e-006, 6.61262066e-009, -1.859126853e-012}, blow = {6626.691440000001, 7.90018105}, ahigh = {280884.5146, -1103.100122, 5.67118983, -0.0005443000450000001, 1.459036606e-007, -1.230971735e-011, 9.90080476e-017}, bhigh = {12246.49804, -8.38237137}, R_s = R_NASA_2002/BeCL.MM);
          constant IdealGases.Common.DataRecord BeCL2(name = "BeCL2", MM = 0.079918182, Hf = -4523865.920773824, H0 = 151165.3505831752, Tlimit = 1000, alow = {-22299.57657, 152.8781667, 3.71499471, 0.0106777655, -1.397766942e-005, 9.066693559999998e-009, -2.350292311e-012}, blow = {-45904.2823, 6.682555572}, ahigh = {-115408.746, -248.4300053, 7.68567214, -7.44496037e-005, 1.649479787e-008, -1.895997075e-012, 8.804973950000001e-017}, bhigh = {-44687.4728, -15.00337407}, R_s = R_NASA_2002/BeCL2.MM);
          constant IdealGases.Common.DataRecord BeF(name = "BeF", MM = 0.0280105852, Hf = -6091439.853245195, H0 = 310993.3240523657, Tlimit = 1000, alow = {-46644.9723, 788.717885, -1.463363201, 0.01381790494, -1.591299964e-005, 9.35293152e-009, -2.229211181e-012}, blow = {-25226.27476, 31.976343}, ahigh = {-185794.1543, 47.76082770000001, 4.26998602, 0.0002310668473, -6.657214920000001e-008, 1.152149888e-011, -6.33558644e-016}, bhigh = {-22579.5096, -0.218478727}, R_s = R_NASA_2002/BeF.MM);
          constant IdealGases.Common.DataRecord BeF2(name = "BeF2", MM = 0.0470089884, Hf = -16945445.18213883, H0 = 231440.0792338684, Tlimit = 1000, alow = {7490.27024, -287.8053102, 5.43471282, 0.00390323346, -2.214865601e-006, -1.965806119e-010, 4.04236227e-013}, blow = {-95916.15640000001, -5.61661692}, ahigh = {-64820.1807, -768.455606, 8.062860840000001, -0.0002227502549, 4.89159866e-008, -5.58788672e-012, 2.583409761e-016}, bhigh = {-93954.9549, -21.25660266}, R_s = R_NASA_2002/BeF2.MM);
          constant IdealGases.Common.DataRecord BeH(name = "BeH", MM = 0.010020122, Hf = 34156480.72947615, H0 = 863073.7230544697, Tlimit = 1000, alow = {-1615.149125, -59.3528608, 4.5072691, -0.00526418961, 1.145319967e-005, -9.247883590000001e-009, 2.700364753e-012}, blow = {40301.93040000001, -3.48511705}, ahigh = {-2424081.636, 6597.39846, -3.62631648, 0.00457963435, -1.163329056e-006, 1.297785691e-010, -5.29188581e-015}, bhigh = {-2489.846221, 52.1601869}, R_s = R_NASA_2002/BeH.MM);
          constant IdealGases.Common.DataRecord BeHplus(name = "BeHplus", MM = 0.0100195734, Hf = 117591728.1069072, H0 = 862706.4900787092, Tlimit = 1000, alow = {-32206.1102, 252.0229596, 3.20771957, -0.00219128729, 6.90253449e-006, -5.76952263e-009, 1.656414969e-012}, blow = {139253.066, 3.30704477}, ahigh = {462234.1589999999, -1760.169629, 5.37990555, 2.742462444e-005, -1.16720817e-007, 3.55717791e-011, -2.569695765e-015}, bhigh = {151585.9734, -13.69222641}, R_s = R_NASA_2002/BeHplus.MM);
          constant IdealGases.Common.DataRecord BeH2(name = "BeH2", MM = 0.011028062, Hf = 14608088.25703011, H0 = 835967.6432722267, Tlimit = 1000, alow = {90653.14900000001, -1320.65722, 9.90130806, -0.01255772231, 2.205704068e-005, -1.633609388e-008, 4.50510324e-012}, blow = {24645.61869, -36.3582675}, ahigh = {607426.201, -3407.53425, 9.79237036, -0.000825461482, 1.915656246e-007, -1.962774813e-011, 8.929908660000001e-016}, bhigh = {37931.052, -42.5465358}, R_s = R_NASA_2002/BeH2.MM);
          constant IdealGases.Common.DataRecord BeI(name = "BeI", MM = 0.135916652, Hf = 1526334.749622879, H0 = 66872.66693414432, Tlimit = 1000, alow = {35300.5481, -519.095026, 5.71450524, -0.00140907364, 7.66477212e-007, -2.601945105e-011, -8.230960639999999e-014}, blow = {26379.03657, -5.14099784}, ahigh = {-532820.662, 1139.497861, 3.62917166, 0.0001704033769, 1.067048688e-007, -3.58945788e-011, 2.72276956e-015}, bhigh = {15854.74307, 9.370951270000001}, R_s = R_NASA_2002/BeI.MM);
          constant IdealGases.Common.DataRecord BeI2(name = "BeI2", MM = 0.262821122, Hf = -246401.2424389543, H0 = 51139.53131970877, Tlimit = 1000, alow = {359.272618, -48.6605901, 5.24157118, 0.007830305059999999, -1.169525374e-005, 8.389583910000001e-009, -2.356636003e-012}, blow = {-9333.22092, 2.896318281}, ahigh = {-93923.72840000001, -89.5921438, 7.56555479, -2.577727326e-005, 5.61426533e-009, -6.35966385e-013, 2.917080336e-017}, bhigh = {-9814.768620000001, -9.03204281}, R_s = R_NASA_2002/BeI2.MM);
          constant IdealGases.Common.DataRecord BeN(name = "BeN", MM = 0.023018882, Hf = 18549988.65713808, H0 = 379046.2542881101, Tlimit = 1000, alow = {-42477.8363, 759.0188900000001, -1.561469235, 0.01496945721, -1.83560888e-005, 1.146861461e-008, -2.897470581e-012}, blow = {46830.0332, 32.56973759}, ahigh = {-59096.9616, -307.8649431, 4.72795915, -3.92815883e-005, 2.006201069e-008, -2.300018068e-012, 1.066101831e-016}, bhigh = {51560.9571, -3.031380625}, R_s = R_NASA_2002/BeN.MM);
          constant IdealGases.Common.DataRecord BeO(name = "BeO", MM = 0.025011582, Hf = 5155223.847895747, H0 = 347363.2335611557, Tlimit = 1000, alow = {-48694.58319999999, 721.347362, -0.378415732, 0.008792203849999999, -7.07015126e-006, 2.25017562e-009, -2.799117872e-014}, blow = {11014.66639, 25.74081184}, ahigh = {-35034724.5, 105585.9473, -116.5011722, 0.0647736948, -1.649656058e-005, 2.0055584e-009, -9.426891790000001e-014}, bhigh = {-657001.8000000001, 864.0898030000001}, R_s = R_NASA_2002/BeO.MM);
          constant IdealGases.Common.DataRecord BeOH(name = "BeOH", MM = 0.026019522, Hf = -3832419.404168916, H0 = 415013.38879323, Tlimit = 1000, alow = {-38530.2452, 449.8059289999999, 1.532096459, 0.01299912603, -1.708979996e-005, 1.169968182e-008, -3.16318371e-012}, blow = {-15590.46567, 15.4554293}, ahigh = {855033.031, -2646.537838, 8.204784630000001, 1.110814513e-005, -4.265364e-008, 7.926511920000001e-012, -4.64541952e-016}, bhigh = {3121.216271, -25.71641308}, R_s = R_NASA_2002/BeOH.MM);
          constant IdealGases.Common.DataRecord BeOHplus(name = "BeOHplus", MM = 0.0260189734, Hf = 29208835.73369579, H0 = 367074.5902680389, Tlimit = 1000, alow = {71061.19160000001, -806.8981600000001, 5.60310781, 0.004932070859999999, -7.722847159999999e-006, 5.910889809999999e-009, -1.695201901e-012}, blow = {94407.8242, -10.88099852}, ahigh = {813487.439, -2814.653683, 8.381145009999999, -6.94207328e-005, -2.369535806e-008, 5.67810638e-012, -3.58325356e-016}, bhigh = {107312.9932, -29.01093335}, R_s = R_NASA_2002/BeOHplus.MM);
          constant IdealGases.Common.DataRecord Be_OH_2(name = "Be_OH_2", MM = 0.043026862, Hf = -14848036.46614991, H0 = 353868.6600012801, Tlimit = 1000, alow = {7863.08983, -739.7142249999999, 10.43303334, 0.00451424953, -6.95060153e-006, 5.77703004e-009, -1.727199382e-012}, blow = {-75856.7696, -33.0146661}, ahigh = {1722889.403, -5242.47719, 14.86877785, 3.93149836e-005, -8.92027631e-008, 1.630912925e-011, -9.505371139999999e-016}, bhigh = {-46428.2384, -64.7680402}, R_s = R_NASA_2002/Be_OH_2.MM);
          constant IdealGases.Common.DataRecord BeS(name = "BeS", MM = 0.041077182, Hf = 6015390.880513663, H0 = 213746.5515526357, Tlimit = 1000, alow = {-7390.57908, 282.8134792, 0.65520194, 0.01076012495, -1.398380157e-005, 8.81841889e-009, -2.110588578e-012}, blow = {27515.93294, 19.80493561}, ahigh = {-16557083.61, 54314.6612, -63.5185925, 0.0396409199, -1.078978696e-005, 1.394030343e-009, -6.93695504e-014}, bhigh = {-312155.9628, 480.3454935}, R_s = R_NASA_2002/BeS.MM);
          constant IdealGases.Common.DataRecord Be2(name = "Be2", MM = 0.018024364, Hf = 35371196.34290564, H0 = 545823.3089389452, Tlimit = 1000, alow = {-158087.381, 2035.567774, -3.69158063, 0.01028818435, -9.60385451e-006, 4.707519419999999e-009, -9.374688790000001e-013}, blow = {65269.68369999999, 48.7932499}, ahigh = {101003.4484, 141.4207488, 2.292070182, 0.0001543331824, -5.801043e-008, 1.003129697e-011, -5.68281834e-016}, bhigh = {75501.3973, 12.38758616}, R_s = R_NASA_2002/Be2.MM);
          constant IdealGases.Common.DataRecord Be2CL4(name = "Be2CL4", MM = 0.159836364, Hf = -5127775.385330963, H0 = 141653.5225989, Tlimit = 1000, alow = {121615.2589, -2000.824823, 17.23384275, 0.00581044828, -1.362970089e-005, 1.156602362e-008, -3.5522558e-012}, blow = {-92064.75470000001, -61.37959773999999}, ahigh = {-335492.008, -231.6199283, 16.17047912, -6.73440595e-005, 1.472073032e-008, -1.672352806e-012, 7.68877397e-017}, bhigh = {-103107.5197, -50.47009374}, R_s = R_NASA_2002/Be2CL4.MM);
          constant IdealGases.Common.DataRecord Be2F4(name = "Be2F4", MM = 0.0940179768, Hf = -18418816.28322808, H0 = 210965.0587588479, Tlimit = 1000, alow = {-6327.70187, -69.0253372, 5.47093723, 0.03097341347, -4.09431006e-005, 2.668113685e-008, -6.942909560000001e-012}, blow = {-210597.9269, -0.2073546195}, ahigh = {-368183.495, -943.919148, 16.70099855, -0.0002797974015, 6.178061719999999e-008, -7.08308019e-012, 3.28279104e-016}, bhigh = {-208904.5725, -60.9266576}, R_s = R_NASA_2002/Be2F4.MM);
          constant IdealGases.Common.DataRecord Be2O(name = "Be2O", MM = 0.034023764, Hf = -1088468.724389224, H0 = 328899.1188629218, Tlimit = 1000, alow = {-426.367357, -115.9556261, 4.08267777, 0.01015885064, -1.326015538e-005, 8.48895536e-009, -2.168039077e-012}, blow = {-5362.25812, 1.253737886}, ahigh = {-141264.6378, -349.864459, 7.76093268, -0.0001044953518, 2.313342334e-008, -2.657722263e-012, 1.233820439e-016}, bhigh = {-5172.38549, -18.54887619}, R_s = R_NASA_2002/Be2O.MM);
          constant IdealGases.Common.DataRecord Be2OF2(name = "Be2OF2", MM = 0.0720205704, Hf = -16725415.99309522, H0 = 230279.6813172699, Tlimit = 1000, alow = {-27834.91921, 178.2881461, 4.09425136, 0.02270142496, -2.672688189e-005, 1.572575618e-008, -3.73607058e-012}, blow = {-148008.1903, 7.35349477}, ahigh = {-228182.6506, -1130.355396, 13.83400563, -0.000331608064, 7.30492101e-008, -8.36270438e-012, 3.87218498e-016}, bhigh = {-143139.0587, -47.3915023}, R_s = R_NASA_2002/Be2OF2.MM);
          constant IdealGases.Common.DataRecord Be2O2(name = "Be2O2", MM = 0.050023164, Hf = -8228893.898034918, H0 = 218477.4237791116, Tlimit = 1000, alow = {-30317.1953, 1163.353177, -8.73315595, 0.0537200293, -7.27943919e-005, 4.89492825e-008, -1.312147056e-011}, blow = {-55469.3688, 69.53282640000001}, ahigh = {-396057.6640000001, -907.4948830000001, 10.67160422, -0.0002670905218, 5.87762999e-008, -6.71866409e-012, 3.105949075e-016}, bhigh = {-48611.1433, -36.1654689}, R_s = R_NASA_2002/Be2O2.MM);
          constant IdealGases.Common.DataRecord Be3O3(name = "Be3O3", MM = 0.075034746, Hf = -13643287.71100258, H0 = 201583.0506043161, Tlimit = 1000, alow = {-27380.72346, 874.38326, -6.59960612, 0.0653302114, -8.762305740000001e-005, 5.81724479e-008, -1.5406005e-011}, blow = {-128467.9012, 58.3720312}, ahigh = {-589080.936, -1392.823588, 17.03450699, -0.000412733074, 9.10752915e-008, -1.043465231e-011, 4.83305377e-016}, bhigh = {-121904.5534, -70.0061451}, R_s = R_NASA_2002/Be3O3.MM);
          constant IdealGases.Common.DataRecord Be4O4(name = "Be4O4", MM = 0.100046328, Hf = -16485308.50627521, H0 = 158265.6686810135, Tlimit = 1000, alow = {-68932.5564, 1687.565069, -14.79616594, 0.1007319774, -0.0001291057622, 8.243136760000001e-008, -2.111283987e-011}, blow = {-207287.7151, 100.2507262}, ahigh = {-884133.8459999999, -2726.394165, 24.02941774, -0.0008114675460000001, 1.794255972e-007, -2.059359498e-011, 9.552905330000001e-016}, bhigh = {-192371.0587, -113.662075}, R_s = R_NASA_2002/Be4O4.MM);
          constant IdealGases.Common.DataRecord Br(name = "Br", MM = 0.079904, Hf = 1400055.066079295, H0 = 77560.92310772926, Tlimit = 1000, alow = {-3700.29391, 61.4521542, 2.092120721, 0.00137681887, -2.445566658e-006, 2.050975161e-009, -5.144249091e-013}, blow = {12425.08647, 8.996166199999999}, ahigh = {-4789717.399999999, 16920.51999, -20.24085357, 0.01395620355, -3.65623056e-006, 4.489781e-010, -2.122507526e-014}, bhigh = {-92070.54960000001, 166.1695929}, R_s = R_NASA_2002/Br.MM);
          constant IdealGases.Common.DataRecord Brplus(name = "Brplus", MM = 0.07990345139999999, Hf = 15743087.58832913, H0 = 77561.53071505495, Tlimit = 1000, alow = {39811.8742, -475.158147, 4.73457898, -0.00516932479, 5.90585752e-006, -2.885129283e-009, 5.054894290000001e-013}, blow = {152905.2046, -5.76928322}, ahigh = {1741149.829, -5455.46567, 8.470663350000001, -0.002683465574, 6.59045456e-007, -7.9537703e-011, 3.735898818e-015}, bhigh = {185178.1643, -36.3790903}, R_s = R_NASA_2002/Brplus.MM);
          constant IdealGases.Common.DataRecord Brminus(name = "Brminus", MM = 0.0799045486, Hf = -2740776.036371977, H0 = 77560.39059833948, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {-27084.92743, 5.41955617}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {-27084.92743, 5.41955617}, R_s = R_NASA_2002/Brminus.MM);
          constant IdealGases.Common.DataRecord BrCL(name = "BrCL", MM = 0.115357, Hf = 128202.9959170228, H0 = 81547.82978059414, Tlimit = 1000, alow = {16532.91583, -357.876928, 5.70062216, -0.002201257188, 2.415146969e-006, -1.371032976e-009, 3.22780342e-013}, blow = {2252.619279, -4.155659669}, ahigh = {-128486.3067, -1138.379626, 7.9640408, -0.00343805667, 1.524999514e-006, -2.761469114e-010, 1.694450407e-014}, bhigh = {5938.264260000001, -19.25044389}, R_s = R_NASA_2002/BrCL.MM);
          constant IdealGases.Common.DataRecord BrF(name = "BrF", MM = 0.09890240319999999, Hf = -595045.6520352784, H0 = 91212.22243465163, Tlimit = 1000, alow = {38361.4319, -518.461197, 5.45832705, -0.00056568431, -4.12131197e-007, 7.85991348e-010, -3.03616152e-013}, blow = {-5595.53991, -4.9011295}, ahigh = {3771388.47, -12674.9343, 20.8055593, -0.0102635936, 3.30820359e-006, -4.90319225e-010, 2.64827508e-014}, bhigh = {70626.0972, -113.02536}, R_s = R_NASA_2002/BrF.MM);
          constant IdealGases.Common.DataRecord BrF3(name = "BrF3", MM = 0.1368992096, Hf = -1867067.025053153, H0 = 107463.1478369032, Tlimit = 1000, alow = {111645.5127, -1959.42433, 15.26220126, -0.0079993623, 6.98203026e-006, -3.24275796e-009, 6.16475146e-013}, blow = {-23453.41551, -55.226336}, ahigh = {-188653.224, -82.45232970000001, 10.06180694, -2.477319092e-005, 5.47857686e-009, -6.28265526e-013, 2.910628214e-017}, bhigh = {-33868.0037, -22.98937369}, R_s = R_NASA_2002/BrF3.MM);
          constant IdealGases.Common.DataRecord BrF5(name = "BrF5", MM = 0.174896016, Hf = -2451742.525684519, H0 = 109633.9610160131, Tlimit = 1000, alow = {221136.6805, -4024.80922, 27.34900212, -0.01832254979, 1.721754649e-005, -8.75350863e-009, 1.860196959e-012}, blow = {-35374.4767, -124.4296466}, ahigh = {-375764.764, -157.5896472, 16.11869838, -4.776497799999999e-005, 1.059755365e-008, -1.218527723e-012, 5.65753545e-017}, bhigh = {-56672.66800000001, -55.4083931}, R_s = R_NASA_2002/BrF5.MM);
          constant IdealGases.Common.DataRecord BrO(name = "BrO", MM = 0.0959034, Hf = 1311736.601622049, H0 = 94480.48765737189, Tlimit = 1000, alow = {14554.31116, 122.5152439, -0.3058728672, 0.02117309202, -3.49426119e-005, 2.622639719e-008, -7.50805954e-012}, blow = {13891.49932, 25.27867438}, ahigh = {-2392612.795, 6932.79313, -2.513183892, 0.00344654456, -7.569536839999999e-007, 6.51429134e-011, -1.715768736e-015}, bhigh = {-30844.99064, 53.6104836}, R_s = R_NASA_2002/BrO.MM);
          constant IdealGases.Common.DataRecord OBrO(name = "OBrO", MM = 0.1119028, Hf = 1357915.31579192, H0 = 101826.1383986817, Tlimit = 1000, alow = {34702.13230000001, -340.134182, 3.93225162, 0.01215938586, -1.901501702e-005, 1.398631495e-008, -3.99289976e-012}, blow = {18759.55788, 6.36123518}, ahigh = {-162450.466, -145.3689372, 7.10582213, -4.14136207e-005, 8.981833259999999e-009, -1.013712869e-012, 4.63513314e-017}, bhigh = {16500.75386, -9.11181792}, R_s = R_NASA_2002/OBrO.MM);
          constant IdealGases.Common.DataRecord BrOO(name = "BrOO", MM = 0.1119028, Hf = 965123.3034383413, H0 = 114837.6984311385, Tlimit = 1000, alow = {-44176.199, 495.963716, 3.23988495, 0.00594150211, -3.40269677e-006, -3.44477816e-011, 4.81195795e-013}, blow = {8815.22198, 16.07446878}, ahigh = {6172.483480000001, -658.504966, 7.48395533, -0.0001920530746, 4.22694617e-008, -4.83739261e-012, 2.23974132e-016}, bhigh = {14603.5347, -9.85038024}, R_s = R_NASA_2002/BrOO.MM);
          constant IdealGases.Common.DataRecord BrO3(name = "BrO3", MM = 0.1279022, Hf = 1726480.740753482, H0 = 102428.5821510498, Tlimit = 1000, alow = {106390.1881, -1501.928813, 9.70365743, 0.00813300076, -1.531857845e-005, 1.199117619e-008, -3.51274787e-012}, blow = {32331.3599, -27.3512543}, ahigh = {-282285.1113, -235.8973461, 10.17525279, -6.97845105e-005, 1.535701661e-008, -1.75445495e-012, 8.10410015e-017}, bhigh = {24011.4014, -25.88197197}, R_s = R_NASA_2002/BrO3.MM);
          constant IdealGases.Common.DataRecord Br2(name = "Br2", MM = 0.159808, Hf = 193419.6035242291, H0 = 60855.00725871045, Tlimit = 1000, alow = {7497.04754, -235.0884557, 5.49193432, -0.002227573303, 2.932401703e-006, -1.954889514e-009, 5.31230789e-013}, blow = {3521.47505, -1.96415157}, ahigh = {-4311698.57, 11112.68634, -5.55577561, 0.00363051659, -2.754164226e-007, -6.21750676e-011, 7.37534162e-015}, bhigh = {-70365.8416, 78.7847802}, R_s = R_NASA_2002/Br2.MM);
          constant IdealGases.Common.DataRecord BrBrO(name = "BrBrO", MM = 0.1758074, Hf = 955591.1753430174, H0 = 74726.64973146751, Tlimit = 1000, alow = {16174.98037, -246.4406776, 5.91285845, 0.00498035428, -8.09995825e-006, 6.072776260000001e-009, -1.753715313e-012}, blow = {19740.12093, 2.009704963}, ahigh = {-85371.0175, -64.8704607, 7.04715935, -1.843088186e-005, 3.99226786e-009, -4.50068795e-013, 2.055867395e-017}, bhigh = {18215.66655, -3.162186125}, R_s = R_NASA_2002/BrBrO.MM);
          constant IdealGases.Common.DataRecord BrOBr(name = "BrOBr", MM = 0.1758074, Hf = 612255.2634303221, H0 = 70526.37147241812, Tlimit = 1000, alow = {64050.6891, -1062.722566, 9.907866289999999, -0.00447049247, 3.91370107e-006, -1.805444867e-009, 3.36613255e-013}, blow = {16429.21537, -23.50319399}, ahigh = {-96866.60249999999, -39.5739527, 7.02943438, -1.171881908e-005, 2.576958549e-009, -2.941186078e-013, 1.357198784e-017}, bhigh = {10769.42321, -5.69777938}, R_s = R_NASA_2002/BrOBr.MM);
          constant IdealGases.Common.DataRecord C(name = "C", MM = 0.0120107, Hf = 59670127.46967287, H0 = 544172.696012722, Tlimit = 1000, alow = {649.503147, -0.964901086, 2.504675479, -1.281448025e-005, 1.980133654e-008, -1.606144025e-011, 5.314483411e-015}, blow = {85457.6311, 4.747924288}, ahigh = {-128913.6472, 171.9528572, 2.646044387, -0.000335306895, 1.74209274e-007, -2.902817829e-011, 1.642182385e-015}, bhigh = {84105.9785, 4.130047418}, R_s = R_NASA_2002/C.MM);
          constant IdealGases.Common.DataRecord Cplus(name = "Cplus", MM = 0.0120101514, Hf = 150659589.6867712, H0 = 553638.482858759, Tlimit = 1000, alow = {2258.535929, -1.574575687, 2.50363773, -5.20287837e-006, 4.51690839e-009, -2.181431053e-012, 4.495047033e-016}, blow = {216895.1913, 4.345699505}, ahigh = {12551.12551, -34.1187467, 2.543383218, -2.805120849e-005, 9.751641969999999e-009, -1.736855394e-012, 1.246191931e-016}, bhigh = {217100.1786, 4.063913515}, R_s = R_NASA_2002/Cplus.MM);
          constant IdealGases.Common.DataRecord Cminus(name = "Cminus", MM = 0.0120112486, Hf = 48980273.04172191, H0 = 517751.0021730797, Tlimit = 1000, alow = {4.67129153, -0.001986169369, 2.500008638, -1.976750928e-008, 2.478947477e-011, -1.610664044e-014, 4.23650681e-018}, blow = {70012.18549999999, 4.879570141}, ahigh = {4.25317572, 0.0005778186479999999, 2.499999424, 2.836136231e-010, -7.32725342e-014, 9.478507810000001e-018, -4.830487319999999e-022}, bhigh = {70012.17170000001, 4.879624211}, R_s = R_NASA_2002/Cminus.MM);
          constant IdealGases.Common.DataRecord CBr(name = "CBr", MM = 0.0919147, Hf = 5335727.756278375, H0 = 104609.1212831027, Tlimit = 1000, alow = {4324.44688, -159.6366559, 4.85785659, -0.000438943916, 4.40886363e-007, -2.281330618e-010, 5.44561822e-014}, blow = {58476.7725, 0.1351169646}, ahigh = {1021862.102, -3243.48436, 8.38822656, -0.002242155508, 6.988355369999999e-007, -9.719134370000001e-011, 4.71697624e-015}, bhigh = {78059.24059999999, -25.18386915}, R_s = R_NASA_2002/CBr.MM);
          constant IdealGases.Common.DataRecord CBr2(name = "CBr2", MM = 0.1718187, Hf = 1959177.429464895, H0 = 70986.5631622169, Tlimit = 1000, alow = {72481.97839999999, -1128.26123, 9.822303379999999, -0.0038727481, 2.904819596e-006, -1.061380159e-009, 1.297474642e-013}, blow = {44377.71599999999, -23.61121795}, ahigh = {-744143.141, 421.542783, 8.796797740000001, -0.002726562507, 1.336438546e-006, -2.304854483e-010, 1.337493953e-014}, bhigh = {33646.1814, -15.99565135}, R_s = R_NASA_2002/CBr2.MM);
          constant IdealGases.Common.DataRecord CBr3(name = "CBr3", MM = 0.2517227, Hf = 933566.9766771132, H0 = 61903.25703641347, Tlimit = 1000, alow = {85635.1626, -1275.764123, 11.17190031, 0.002341705749, -6.54067141e-006, 5.73671714e-009, -1.777823046e-012}, blow = {32432.1589, -27.66468801}, ahigh = {-192649.8949, -132.4072178, 10.09808665, -3.89504082e-005, 8.55044501e-009, -9.747493679999999e-013, 4.49424559e-017}, bhigh = {25415.76129, -18.66868947}, R_s = R_NASA_2002/CBr3.MM);
          constant IdealGases.Common.DataRecord CBr4(name = "CBr4", MM = 0.3316267000000001, Hf = 239727.3802139574, H0 = 61434.48039618039, Tlimit = 1000, alow = {102308.3739, -1735.600709, 16.51317914, -0.003147664747, 2.924135486e-007, 1.360605681e-009, -6.43175865e-013}, blow = {15005.02543, -55.3647676}, ahigh = {-205978.5072, -104.8517002, 13.0777255, -3.086857556e-005, 6.77530981e-009, -7.72183754e-013, 3.55921824e-017}, bhigh = {5615.89394, -32.8378763}, R_s = R_NASA_2002/CBr4.MM);
          constant IdealGases.Common.DataRecord CCL(name = "CCL", MM = 0.0474637, Hf = 9114566.668843769, H0 = 197943.1228496725, Tlimit = 1000, alow = {17070.70049, -14.63803497, 2.334108251, 0.00720209913, -1.034120045e-005, 7.2281067e-009, -1.985123755e-012}, blow = {51233.503, 12.00820386}, ahigh = {590050.763, -2075.31146, 6.88001723, -0.001294796228, 3.88313798e-007, -5.00698163e-011, 2.218229619e-015}, bhigh = {63589.2205, -16.10664472}, R_s = R_NASA_2002/CCL.MM);
          constant IdealGases.Common.DataRecord CCL2(name = "CCL2", MM = 0.08291670000000001, Hf = 2688724.310060578, H0 = 137761.8501459899, Tlimit = 1000, alow = {75096.23150000001, -1034.728559, 8.061704539999999, 0.001487134213, -4.56481711e-006, 3.95488581e-009, -1.166197091e-012}, blow = {30524.09293, -17.39691692}, ahigh = {-6437455.17, 19584.13353, -16.04038625, 0.01238833906, -3.013367274e-006, 3.47346892e-010, -1.553272793e-014}, bhigh = {-99612.42159999999, 155.6949315}, R_s = R_NASA_2002/CCL2.MM);
          constant IdealGases.Common.DataRecord CCL2Br2(name = "CCL2Br2", MM = 0.2427247, Hf = 41198.93855054718, H0 = 77008.69338802355, Tlimit = 1000, alow = {101849.5619, -1740.854039, 15.21338304, 0.00112825651, -5.875405490000001e-006, 5.65988697e-009, -1.821576512e-012}, blow = {6918.57219, -50.15385818999999}, ahigh = {-255334.7012, -159.8005477, 13.1186093, -4.717443870000001e-005, 1.036912808e-008, -1.183321687e-012, 5.46061269e-017}, bhigh = {-2588.63698, -34.61705319}, R_s = R_NASA_2002/CCL2Br2.MM);
          constant IdealGases.Common.DataRecord CCL3(name = "CCL3", MM = 0.1183697, Hf = 600897.0200988936, H0 = 121652.7540409412, Tlimit = 1000, alow = {34144.7165, -554.796973, 6.84554439, 0.01242006495, -2.036896881e-005, 1.554979993e-008, -4.56894011e-012}, blow = {9388.56882, -7.143598465}, ahigh = {-542757.254, 680.902062, 9.047723619999999, 0.0001324277766, 6.30126304e-008, -2.6566392e-011, 2.105668053e-015}, bhigh = {386.621615, -15.28745849}, R_s = R_NASA_2002/CCL3.MM);
          constant IdealGases.Common.DataRecord CCL3Br(name = "CCL3Br", MM = 0.1982737, Hf = -216871.9300643504, H0 = 90705.67099922984, Tlimit = 1000, alow = {104966.8463, -1793.828482, 14.89250892, 0.00239712831, -7.78961547e-006, 7.01661711e-009, -2.196069746e-012}, blow = {910.1349309999999, -50.58348139}, ahigh = {-277232.4186, -184.0310333, 13.13673812, -5.44391001e-005, 1.197658923e-008, -1.367818632e-012, 6.316164790000001e-017}, bhigh = {-8895.857689999999, -36.69528209}, R_s = R_NASA_2002/CCL3Br.MM);
          constant IdealGases.Common.DataRecord CCL4(name = "CCL4", MM = 0.1538227, Hf = -621494.746874161, H0 = 111547.3333909754, Tlimit = 1000, alow = {109338.5626, -1861.731846, 14.49632467, 0.00394948516, -1.010805379e-005, 8.64551417e-009, -2.642368852e-012}, blow = {-4948.00623, -51.8028475}, ahigh = {-304307.8255, -216.8170491, 13.16132386, -6.43112489e-005, 1.416482497e-008, -1.61934332e-012, 7.48397435e-017}, bhigh = {-15123.2007, -39.968443}, R_s = R_NASA_2002/CCL4.MM);
          constant IdealGases.Common.DataRecord CF(name = "CF", MM = 0.0310091032, Hf = 7813834.487157951, H0 = 292337.0257286254, Tlimit = 1000, alow = {-45827.8668, 797.263589, -1.364936319, 0.01312359375, -1.457012892e-005, 8.25327668e-009, -1.896351845e-012}, blow = {24382.5962, 32.4806528}, ahigh = {-132980.71, -121.4340891, 4.45241362, 0.0001293786948, -3.67055059e-008, 6.590212389999999e-012, -3.73126161e-016}, bhigh = {28159.34108, -0.664046873}, R_s = R_NASA_2002/CF.MM);
          constant IdealGases.Common.DataRecord CFplus(name = "CFplus", MM = 0.0310085546, Hf = 36943485.87921605, H0 = 280487.0821034657, Tlimit = 1000, alow = {-59752.132, 927.6863649999999, -1.866581982, 0.01384340912, -1.51342886e-005, 8.51855634e-009, -1.959577655e-012}, blow = {132351.941, 34.1201319}, ahigh = {-80537.6278, -339.027509, 4.7083735, -3.96314831e-005, 2.497996218e-008, -5.23679043e-012, 5.31394913e-016}, bhigh = {138133.7068, -3.92051473}, R_s = R_NASA_2002/CFplus.MM);
          constant IdealGases.Common.DataRecord CFBr3(name = "CFBr3", MM = 0.2707211032, Hf = -443260.6050343547, H0 = 67387.07763953881, Tlimit = 1000, alow = {51492.4428, -936.479664, 10.44260886, 0.01205370047, -1.876290291e-005, 1.344488618e-008, -3.73054576e-012}, blow = {-12432.46293, -23.63948551}, ahigh = {-272915.8956, -332.816465, 13.24822519, -9.92707754e-005, 2.193640054e-008, -2.515424945e-012, 1.165680878e-016}, bhigh = {-17301.85479, -36.2681843}, R_s = R_NASA_2002/CFBr3.MM);
          constant IdealGases.Common.DataRecord CFCL(name = "CFCL", MM = 0.0664621032, Hf = 388879.8692124447, H0 = 164039.0760309253, Tlimit = 1000, alow = {15419.97945, -82.74039809999999, 2.501701822, 0.01390738086, -1.8957347e-005, 1.261934581e-008, -3.33345382e-012}, blow = {2411.755114, 13.31517094}, ahigh = {-268163.0077, -2.328091539, 6.83463383, 0.0001565270633, -5.967755160000001e-008, 9.82092446e-012, -5.05889721e-016}, bhigh = {301.7669604, -9.005085128999999}, R_s = R_NASA_2002/CFCL.MM);
          constant IdealGases.Common.DataRecord CFCLBr2(name = "CFCLBr2", MM = 0.2262701032, Hf = -773411.9422985264, H0 = 77332.45688465308, Tlimit = 1000, alow = {58987.9974, -1050.714861, 10.39349401, 0.01273690622, -1.999097478e-005, 1.43820423e-008, -4.00013035e-012}, blow = {-18377.99602, -24.17479131}, ahigh = {-296081.1596, -353.12762, 13.26346169, -0.0001053860298, 2.32908508e-008, -2.670979639e-012, 1.237844667e-016}, bhigh = {-23875.94306, -36.84977271}, R_s = R_NASA_2002/CFCLBr2.MM);
          constant IdealGases.Common.DataRecord CFCL2(name = "CFCL2", MM = 0.1019151032, Hf = -1030269.280049161, H0 = 129685.9207811703, Tlimit = 1000, alow = {26113.98792, -335.35659, 4.09467308, 0.01960244711, -2.762775193e-005, 1.880124302e-008, -5.0474103e-012}, blow = {-12512.98871, 6.870882561}, ahigh = {-265311.8323, -446.972417, 10.33334881, -0.0001333673368, 2.948755634e-008, -3.3833062e-012, 1.568746348e-016}, bhigh = {-13931.60489, -25.56817972}, R_s = R_NASA_2002/CFCL2.MM);
          constant IdealGases.Common.DataRecord CFCL2Br(name = "CFCL2Br", MM = 0.1818191032, Hf = -1292493.450160192, H0 = 92017.68519117852, Tlimit = 1000, alow = {65299.59220000001, -1135.235485, 10.09526872, 0.01401380147, -2.191705096e-005, 1.573404132e-008, -4.36934034e-012}, blow = {-25044.88145, -24.51093103}, ahigh = {-321545.505, -388.412962, 13.28990796, -0.0001160048581, 2.564498787e-008, -2.941639768e-012, 1.363542881e-016}, bhigh = {-30974.21144, -38.71356695}, R_s = R_NASA_2002/CFCL2Br.MM);
          constant IdealGases.Common.DataRecord CFCL3(name = "CFCL3", MM = 0.1373681032, Hf = -2065253.820873898, H0 = 116938.2383959423, Tlimit = 1000, alow = {74001.74000000001, -1252.282466, 10.01327229, 0.01475107601, -2.315635251e-005, 1.664207025e-008, -4.62292996e-012}, blow = {-30205.08601, -27.08387087}, ahigh = {-345046.478, -417.782145, 13.31196736, -0.0001248759531, 2.761391353e-008, -3.16820764e-012, 1.468834601e-016}, bhigh = {-36740.6719, -41.56886057000001}, R_s = R_NASA_2002/CFCL3.MM);
          constant IdealGases.Common.DataRecord CF2(name = "CF2", MM = 0.0500075064, Hf = -3731439.806404744, H0 = 206987.1654308282, Tlimit = 1000, alow = {-37970.2627, 873.1800030000001, -3.46019157, 0.02746253741, -3.4746219e-005, 2.204470693e-008, -5.62175085e-012}, blow = {-27467.97157, 44.5677807}, ahigh = {-108642.8547, -585.498914, 7.01864895, 0.000392918615, -2.603822675e-007, 6.142196389999999e-011, -4.17283326e-015}, bhigh = {-21529.45157, -13.56143285}, R_s = R_NASA_2002/CF2.MM);
          constant IdealGases.Common.DataRecord CF2plus(name = "CF2plus", MM = 0.0500069578, Hf = 18984184.21686112, H0 = 206811.2009805164, Tlimit = 1000, alow = {-28923.73827, 604.935461, -0.972186666, 0.01808478341, -1.980065782e-005, 1.101640055e-008, -2.500457119e-012}, blow = {110275.567, 32.4759147}, ahigh = {-64889.6607, -1064.283593, 7.7857021, -0.0003158347626, 7.130804079999999e-008, -8.53318359e-012, 4.25163882e-016}, bhigh = {117844.6465, -18.19424707}, R_s = R_NASA_2002/CF2plus.MM);
          constant IdealGases.Common.DataRecord CF2Br2(name = "CF2Br2", MM = 0.2098155064, Hf = -1811114.948175251, H0 = 77591.96295512693, Tlimit = 1000, alow = {12614.04028, -281.5725114, 5.09803213, 0.02502548939, -3.43885319e-005, 2.297615553e-008, -6.08016143e-012}, blow = {-46427.6375, 3.094167118}, ahigh = {-332766.93, -618.435249, 13.46170049, -0.0001849172548, 4.09259134e-008, -4.69981043e-012, 2.180811799e-016}, bhigh = {-47151.8661, -41.0536924}, R_s = R_NASA_2002/CF2Br2.MM);
          constant IdealGases.Common.DataRecord CF2CL(name = "CF2CL", MM = 0.0854605064, Hf = -3217860.642117609, H0 = 145473.8981045869, Tlimit = 1000, alow = {8914.558349999999, -17.68816959, 1.607015025, 0.02473626554, -3.27073894e-005, 2.12635183e-008, -5.509831110000001e-012}, blow = {-34273.0625, 19.2968069}, ahigh = {-280234.6654, -686.031485, 10.51143635, -0.0002046954963, 4.52889718e-008, -5.20022903e-012, 2.41297145e-016}, bhigh = {-33081.7948, -28.74899785}, R_s = R_NASA_2002/CF2CL.MM);
          constant IdealGases.Common.DataRecord CF2CLBr(name = "CF2CLBr", MM = 0.1653645064, Hf = -2630552.404926478, H0 = 93903.11946651207, Tlimit = 1000, alow = {26966.99365, -467.883227, 5.24480942, 0.02530121349, -3.508443520000001e-005, 2.354353958e-008, -6.24616113e-012}, blow = {-51983.8273, 0.8532887803}, ahigh = {-359282.884, -653.928359, 13.48831524, -0.0001956099469, 4.32977597e-008, -4.97264437e-012, 2.30757505e-016}, bhigh = {-53651.4117, -42.24913908000001}, R_s = R_NASA_2002/CF2CLBr.MM);
          constant IdealGases.Common.DataRecord CF2CL2(name = "CF2CL2", MM = 0.1209135064, Hf = -4059099.885635274, H0 = 123072.2228066988, Tlimit = 1000, alow = {38412.5875, -613.949982, 5.26966719, 0.02574105783, -3.58737648e-005, 2.41160013e-008, -6.4022369e-012}, blow = {-57845.4133, -1.957454856}, ahigh = {-382744.855, -693.37748, 13.51791274, -0.0002075114435, 4.59402161e-008, -5.276874600000001e-012, 2.449037044e-016}, bhigh = {-60215.2777, -44.79580046}, R_s = R_NASA_2002/CF2CL2.MM);
          constant IdealGases.Common.DataRecord CF3(name = "CF3", MM = 0.0690059096, Hf = -6773332.932053692, H0 = 166528.7808915426, Tlimit = 1000, alow = {-29783.07106, 715.367883, -3.49818538, 0.0359545799, -4.50797443e-005, 2.82180845e-008, -7.098047020000001e-012}, blow = {-60599.9703, 45.0259264}, ahigh = {-299730.5557, -1046.989457, 10.77923191, -0.0003116087076, 6.89135143e-008, -7.91122564e-012, 3.67059302e-016}, bhigh = {-54253.044, -34.1703879}, R_s = R_NASA_2002/CF3.MM);
          constant IdealGases.Common.DataRecord CF3plus(name = "CF3plus", MM = 0.06900536099999999, Hf = 6138906.801748347, H0 = 167251.9327882366, Tlimit = 1000, alow = {-35874.6354, 374.35067, 0.778741393, 0.01929435768, -1.89281577e-005, 9.36390876e-009, -1.885759656e-012}, blow = {47755.8172, 22.24044005}, ahigh = {-29109.19531, -1996.658183, 11.44279678, -0.000565339304, 1.232297113e-007, -1.399758046e-011, 6.44301795e-016}, bhigh = {59023.458, -40.80349990000001}, R_s = R_NASA_2002/CF3plus.MM);
          constant IdealGases.Common.DataRecord CF3Br(name = "CF3Br", MM = 0.1489099096, Hf = -4356996.80258217, H0 = 96998.43374292129, Tlimit = 1000, alow = {-5439.48901, 124.361519, 0.923194195, 0.0348104438, -4.54964549e-005, 2.932836552e-008, -7.54800036e-012}, blow = {-80233.9676, 22.32999096}, ahigh = {-383408.851, -971.9093300000001, 13.72477396, -0.0002901710612, 6.421892200000001e-008, -7.37568877e-012, 3.42315425e-016}, bhigh = {-77653.0631, -47.1736721}, R_s = R_NASA_2002/CF3Br.MM);
          constant IdealGases.Common.DataRecord CF3CL(name = "CF3CL", MM = 0.1044589096, Hf = -6741406.766512906, H0 = 132020.8209410603, Tlimit = 1000, alow = {14994.09978, -136.5768572, 1.45291237, 0.0340476507, -4.47377764e-005, 2.888115112e-008, -7.43417133e-012}, blow = {-85471.6664, 17.27327095}, ahigh = {-406604.2119999999, -1022.626507, 13.76252628, -0.0003052722979, 6.75596604e-008, -7.75931525e-012, 3.60119229e-016}, bhigh = {-84105.5937, -49.13411939}, R_s = R_NASA_2002/CF3CL.MM);
          constant IdealGases.Common.DataRecord CF4(name = "CF4", MM = 0.0880043128, Hf = -10603116.71452538, H0 = 144655.558289866, Tlimit = 1000, alow = {9817.458500000001, 116.3343483, -1.288338636, 0.0395956691, -4.99624421e-005, 3.125339346e-008, -7.841700320000001e-012}, blow = {-113850.2297, 29.38656548}, ahigh = {-416445.678, -1414.797167, 14.05124837, -0.000419909386, 9.27892161e-008, -1.06457583e-011, 4.937099680000001e-016}, bhigh = {-109469.1149, -54.87105}, R_s = R_NASA_2002/CF4.MM);
          constant IdealGases.Common.DataRecord CHplus(name = "CHplus", MM = 0.0130180914, Hf = 125254229.2029076, H0 = 662777.9552999605, Tlimit = 1000, alow = {30196.07105, -461.814131, 6.22564119, -0.0077757118, 1.094489485e-005, -6.67548791e-009, 1.565232409e-012}, blow = {197249.1928, -14.31512811}, ahigh = {-7102094.67, 18283.54883, -13.12691402, 0.006191717360000001, -2.909421253e-007, -1.134243575e-010, 1.105962085e-014}, bhigh = {75412.9604, 124.3984829}, R_s = R_NASA_2002/CHplus.MM);
          constant IdealGases.Common.DataRecord CHBr3(name = "CHBr3", MM = 0.25273064, Hf = 66236.5275536041, H0 = 62938.94954723337, Tlimit = 1000, alow = {43465.7686, -499.963442, 5.62022211, 0.02079346321, -2.921336328e-005, 2.066942448e-008, -5.78122091e-012}, blow = {2627.830062, 1.247904015}, ahigh = {627423.495, -3378.7111, 14.87852612, -0.000593274527, 1.082421577e-007, -1.061012665e-011, 4.31915245e-016}, bhigh = {18772.34659, -53.1190965}, R_s = R_NASA_2002/CHBr3.MM);
          constant IdealGases.Common.DataRecord CHCL(name = "CHCL", MM = 0.04847164, Hf = 6129357.290159771, H0 = 210441.4663914817, Tlimit = 1000, alow = {-269991.2334, 4351.19973, -22.75911813, 0.07550621760000001, -9.07199797e-005, 5.25697186e-008, -1.189769182e-011}, blow = {14168.6268, 152.0980812}, ahigh = {-954806.1900000001, 2174.413794, 4.86764537, 0.0008321641859999999, -1.536948638e-007, 1.529236537e-011, -6.596159359999999e-016}, bhigh = {18801.2181, 2.674761385}, R_s = R_NASA_2002/CHCL.MM);
          constant IdealGases.Common.DataRecord CHCLBr2(name = "CHCLBr2", MM = 0.20827964, Hf = 48012.37413316059, H0 = 73416.85437904541, Tlimit = 1000, alow = {38153.8025, -408.4175110000001, 4.63924402, 0.02325990646, -3.22298886e-005, 2.254671151e-008, -6.25650774e-012}, blow = {1483.809044, 6.175235281}, ahigh = {604286.53, -3438.24101, 14.94162631, -0.000622842797, 1.153724426e-007, -1.147291377e-011, 4.733482859999999e-016}, bhigh = {18224.60958, -54.07258924}, R_s = R_NASA_2002/CHCLBr2.MM);
          constant IdealGases.Common.DataRecord CHCL2(name = "CHCL2", MM = 0.08392464, Hf = 1141500.27929819, H0 = 152517.7826202174, Tlimit = 1000, alow = {56385.5613, -656.245542, 6.06881802, 0.0097441226, -1.275310131e-005, 8.55238672e-009, -2.2315827e-012}, blow = {13304.47798, -4.533535456}, ahigh = {884939.3709999999, -3526.96973, 11.86372153, -0.000500237612, 6.1338604e-008, -1.885433405e-012, -1.234221421e-016}, bhigh = {30711.36475, -40.88905858}, R_s = R_NASA_2002/CHCL2.MM);
          constant IdealGases.Common.DataRecord CHCL2Br(name = "CHCL2Br", MM = 0.16382864, Hf = -274677.248129509, H0 = 89910.37830748031, Tlimit = 1000, alow = {32940.2265, -327.530117, 3.77323524, 0.02536466143, -3.47266699e-005, 2.404666618e-008, -6.62173093e-012}, blow = {-5425.56508, 9.433412003999999}, ahigh = {592487.644, -3509.47561, 14.99349593, -0.000643306257, 1.198581809e-007, -1.198476716e-011, 4.96994807e-016}, bhigh = {11972.51405, -56.02687781}, R_s = R_NASA_2002/CHCL2Br.MM);
          constant IdealGases.Common.DataRecord CHCL3(name = "CHCL3", MM = 0.11937764, Hf = -860295.1105416392, H0 = 119833.9488031427, Tlimit = 1000, alow = {33953.3329, -304.7428785, 2.923672263, 0.02830547858, -3.71242469e-005, 2.551365915e-008, -6.98765955e-012}, blow = {-12350.63157, 11.15556408}, ahigh = {613605.274, -3715.08717, 15.10777247, 0.0002362584336, 1.297140438e-007, -1.267494791e-011, 5.259022309999999e-016}, bhigh = {6203.31345, -59.92576539}, R_s = R_NASA_2002/CHCL3.MM);
          constant IdealGases.Common.DataRecord CHF(name = "CHF", MM = 0.03201704320000001, Hf = 3398190.123939989, H0 = 311746.9635672041, Tlimit = 1000, alow = {-78685.85829999999, 1300.218466, -3.94768525, 0.02114995848, -2.239962738e-005, 1.283155181e-008, -2.904778136e-012}, blow = {5824.38972, 47.8545377}, ahigh = {3994085.42, -7962.756200000001, 6.75559509, 0.00494983657, -2.101763812e-006, 3.34823295e-010, -1.88682505e-014}, bhigh = {67061.34940000001, -23.81240379}, R_s = R_NASA_2002/CHF.MM);
          constant IdealGases.Common.DataRecord CHFBr2(name = "CHFBr2", MM = 0.1918250432, Hf = -912289.6420648375, H0 = 74857.56687685709, Tlimit = 1000, alow = {-18201.9798, 436.224967, -0.373385417, 0.033886314, -4.37129853e-005, 2.889569295e-008, -7.683915110000001e-012}, blow = {-24656.11586, 33.2047879}, ahigh = {593575.1630000001, -3742.65658, 15.17184031, -0.0007158039030000001, 1.360636972e-007, -1.385897355e-011, 5.844209110000001e-016}, bhigh = {-2347.676027, -57.6578343}, R_s = R_NASA_2002/CHFBr2.MM);
          constant IdealGases.Common.DataRecord CHFCL(name = "CHFCL", MM = 0.06747004320000001, Hf = -1232320.301819519, H0 = 165198.5751211139, Tlimit = 1000, alow = {-71130.0851, 1377.872745, -6.48461724, 0.0389097249, -4.80073522e-005, 3.073300019e-008, -7.98285341e-012}, blow = {-17517.93745, 63.73895867}, ahigh = {662216.358, -3809.00798, 12.23880469, -0.000746718275, 1.43476785e-007, -1.475406631e-011, 6.27378068e-016}, bhigh = {10189.87746, -46.58365563}, R_s = R_NASA_2002/CHFCL.MM);
          constant IdealGases.Common.DataRecord CHFCLBr(name = "CHFCLBr", MM = 0.1473740432, Hf = -1560654.746289813, H0 = 93552.3359516542, Tlimit = 1000, alow = {-19592.40614, 490.172327, -1.259408503, 0.0361770847, -4.65424496e-005, 3.065240659e-008, -8.1239036e-012}, blow = {-31399.00705, 37.10450945}, ahigh = {580011.7509999999, -3823.33785, 15.22809062, -0.000737390631, 1.407097155e-007, -1.438245319e-011, 6.08386715e-016}, bhigh = {-8552.249899999999, -59.03677705}, R_s = R_NASA_2002/CHFCLBr.MM);
          constant IdealGases.Common.DataRecord CHFCL2(name = "CHFCL2", MM = 0.1029230432, Hf = -2768087.603534833, H0 = 129167.984026341, Tlimit = 1000, alow = {-17349.59015, 492.49132, -1.854635884, 0.0378278628, -4.86334304e-005, 3.19719763e-008, -8.45905799e-012}, blow = {-37887.4927, 38.01530544}, ahigh = {564011.302, -3887.0833, 15.27760246, -0.0007576487420000001, 1.452498792e-007, -1.490796515e-011, 6.3289985e-016}, bhigh = {-14847.36185, -61.67535516}, R_s = R_NASA_2002/CHFCL2.MM);
          constant IdealGases.Common.DataRecord CHF2(name = "CHF2", MM = 0.0510154464, Hf = -4682895.414201452, H0 = 214052.8167562991, Tlimit = 1000, alow = {-146969.0117, 2553.397313, -13.0262763, 0.0543812846, -6.71341879e-005, 4.28765173e-008, -1.110824216e-011}, blow = {-41793.7216, 99.39930250000001}, ahigh = {552680.655, -3696.00917, 12.08610573, -0.00064985881, 1.12084622e-007, -9.814147009999999e-012, 3.34919239e-016}, bhigh = {-9437.06842, -47.044162}, R_s = R_NASA_2002/CHF2.MM);
          constant IdealGases.Common.DataRecord CHF2Br(name = "CHF2Br", MM = 0.1309194464, Hf = -3223356.129315255, H0 = 100592.4204702412, Tlimit = 1000, alow = {-77145.1016, 1422.544046, -6.68439365, 0.0473838915, -5.83058875e-005, 3.69572047e-008, -9.49548528e-012}, blow = {-58785.00930000001, 66.0863909}, ahigh = {576770.684, -4177.71608, 15.50150581, -0.000849014729, 1.657177491e-007, -1.727828054e-011, 7.43562723e-016}, bhigh = {-29661.47348, -63.4938014}, R_s = R_NASA_2002/CHF2Br.MM);
          constant IdealGases.Common.DataRecord CHF2CL(name = "CHF2CL", MM = 0.08646844640000001, Hf = -5583539.662162821, H0 = 143029.0067059653, Tlimit = 1000, alow = {-72405.7941, 1365.510973, -7.15322208, 0.0485498797, -5.94878167e-005, 3.75096619e-008, -9.58952442e-012}, blow = {-65659.32799999999, 66.5721223}, ahigh = {562949.373, -4298.673049999999, 15.58191398, -0.000878927848, 1.720248689e-007, -1.797910869e-011, 7.753391699999999e-016}, bhigh = {-36340.6716, -66.11261479999999}, R_s = R_NASA_2002/CHF2CL.MM);
          constant IdealGases.Common.DataRecord CHF3(name = "CHF3", MM = 0.0700138496, Hf = -9902326.524836596, H0 = 165208.5418254162, Tlimit = 1000, alow = {-109513.226, 2042.273879, -11.66213079, 0.0578580777, -6.857135060000001e-005, 4.21211838e-008, -1.053196888e-011}, blow = {-93954.70050000001, 89.3592065}, ahigh = {568523.2020000001, -4728.3617, 15.86728516, -0.000738234865, 1.970841706e-007, -2.062115571e-011, 8.970599639999999e-016}, bhigh = {-59231.9637, -71.6127322}, R_s = R_NASA_2002/CHF3.MM);
          constant IdealGases.Common.DataRecord CHI3(name = "CHI3", MM = 0.39373205, Hf = 535576.4154835757, H0 = 43574.2708778724, Tlimit = 1000, alow = {52529.2359, -724.216647, 8.01862334, 0.01470995487, -2.163843469e-005, 1.594571452e-008, -4.60143796e-012}, blow = {26781.86915, -8.605054839999999}, ahigh = {629420.543, -3184.06157, 14.79622178, -0.00057495555, 1.062025541e-007, -1.052804696e-011, 4.32972002e-016}, bhigh = {41036.098, -49.0135739}, R_s = R_NASA_2002/CHI3.MM);
          constant IdealGases.Common.DataRecord CH2(name = "CH2", MM = 0.01402658, Hf = 27830341.89374745, H0 = 0, Tlimit = 1000, alow = {32189.2173, -287.7601815, 4.20358382, 0.00345540596, -6.74619334e-006, 7.65457164e-009, -2.870328419e-012}, blow = {4.733624710e+004, -2.143628603e+000}, ahigh = {2550418.031, -7971.62539, 12.28924487, -0.001699122922, 2.991728605e-007, -2.767007492e-011, 1.051341740e-015}, bhigh = {9.642216890e+004, -6.094739910e+001}, R_s = R_NASA_2002/CH2.MM);
          constant IdealGases.Common.DataRecord CH2Br2(name = "CH2Br2", MM = 0.17383458, Hf = -84965.83361032081, H0 = 72565.5792995847, Tlimit = 1000, alow = {4797.30801, 361.385924, -1.819592338, 0.0347704834, -4.49854618e-005, 3.068623685e-008, -8.43484634e-012}, blow = {-4481.49706, 38.2712359}, ahigh = {1528284.441, -6673.414949999999, 16.70213316, -0.001166351237, 2.122634493e-007, -2.07547224e-011, 8.4285777e-016}, bhigh = {36007.0664, -74.48065490000001}, R_s = R_NASA_2002/CH2Br2.MM);
          constant IdealGases.Common.DataRecord CH2CL(name = "CH2CL", MM = 0.04947958, Hf = 2409074.612193556, H0 = 221908.1083550022, Tlimit = 1000, alow = {-31885.8563, 633.316321, -1.164065495, 0.0216058608, -2.545462163e-005, 1.693887757e-008, -4.6600786e-012}, blow = {10201.4254, 32.30835289}, ahigh = {1662438.334, -6441.12572, 13.59753722, -0.00114053681, 2.087760159e-007, -2.052347186e-011, 8.37577227e-016}, bhigh = {52129.0612, -61.48586271}, R_s = R_NASA_2002/CH2CL.MM);
          constant IdealGases.Common.DataRecord CH2CLBr(name = "CH2CLBr", MM = 0.12938358, Hf = -347803.0210634147, H0 = 94221.74745821687, Tlimit = 1000, alow = {-13079.48755, 645.586038, -3.57734991, 0.0383368723, -4.86425205e-005, 3.26162233e-008, -8.852877389999999e-012}, blow = {-9402.27253, 47.48806758}, ahigh = {1525016.309, -6823.33416, 16.82769102, -0.001219735119, 2.244964495e-007, -2.219063248e-011, 9.104705129999999e-016}, bhigh = {33202.3992, -76.37571062000001}, R_s = R_NASA_2002/CH2CLBr.MM);
          constant IdealGases.Common.DataRecord CH2CL2(name = "CH2CL2", MM = 0.08493258000000001, Hf = -1118534.25387525, H0 = 139570.4333955238, Tlimit = 1000, alow = {-25098.41179, 868.766738, -5.09466921, 0.0415004999, -5.19977215e-005, 3.44594426e-008, -9.270292519999999e-012}, blow = {-16389.7884, 53.9689032}, ahigh = {1529279.337, -6976.95476, 16.94154931, -0.001265053995, 2.344766734e-007, -2.333227421e-011, 9.632834730000001e-016}, bhigh = {28063.18171, -79.49453509999999}, R_s = R_NASA_2002/CH2CL2.MM);
          constant IdealGases.Common.DataRecord CH2F(name = "CH2F", MM = 0.0330249832, Hf = -962907.3785569707, H0 = 336987.3023886958, Tlimit = 1000, alow = {-85697.1253, 1392.226749, -4.38205259, 0.02645916948, -2.848145663e-005, 1.732706028e-008, -4.44206144e-012}, blow = {-11694.44586, 50.494992}, ahigh = {2535399.502, -9358.43902, 17.00366206, -0.003062919929, 7.612869080000001e-007, -9.664554980000001e-011, 4.8447681e-015}, bhigh = {52283.9131, -87.0755157}, R_s = R_NASA_2002/CH2F.MM);
          constant IdealGases.Common.DataRecord CH2FBr(name = "CH2FBr", MM = 0.1129289832, Hf = -1903851.375507647, H0 = 102919.4248514229, Tlimit = 1000, alow = {-92561.0953, 1811.985865, -9.69834687, 0.0503584867, -6.07027268e-005, 3.8782508e-008, -1.012615992e-011}, blow = {-35375.0962, 81.4039605}, ahigh = {1539975.462, -7231.55136, 17.14566439, -0.001350184394, 2.538022824e-007, -2.558977386e-011, 1.069310946e-015}, bhigh = {15096.04224, -80.62053710000001}, R_s = R_NASA_2002/CH2FBr.MM);
          constant IdealGases.Common.DataRecord CH2FCL(name = "CH2FCL", MM = 0.0684779832, Hf = -3880079.225230454, H0 = 164320.8002656247, Tlimit = 1000, alow = {-107134.0332, 2081.328396, -11.55723697, 0.0544148211, -6.51862274e-005, 4.13315988e-008, -1.071935103e-011}, blow = {-42647.5621, 90.35923546999999}, ahigh = {1536120.418, -7378.93973, 17.25797178, -0.001395645457, 2.639247747e-007, -2.675653563e-011, 1.123582778e-015}, bhigh = {9813.71046, -83.13642553}, R_s = R_NASA_2002/CH2FCL.MM);
          constant IdealGases.Common.DataRecord CH2F2(name = "CH2F2", MM = 0.0520233864, Hf = -8694166.821866099, H0 = 205548.4607976231, Tlimit = 1000, alow = {-181991.75, 3174.42789, -17.14256906, 0.06411353830000001, -7.31359212e-005, 4.426384159999999e-008, -1.103877216e-011}, blow = {-70270.5895, 120.7331926}, ahigh = {1546609.496, -7876.88333, 17.68770469, -0.001581298721, 3.068917255e-007, -3.18340546e-011, 1.363827177e-015}, bhigh = {-9800.13596, -89.0742036}, R_s = R_NASA_2002/CH2F2.MM);
          constant IdealGases.Common.DataRecord CH2I2(name = "CH2I2", MM = 0.26783552, Hf = 438964.9289235423, H0 = 49472.25819786711, Tlimit = 1000, alow = {27381.33757, -89.7256804, 1.387869408, 0.02733482611, -3.61940877e-005, 2.53918761e-008, -7.145585160000001e-012}, blow = {13387.67276, 22.41870165}, ahigh = {1512892.716, -6442.9124, 16.59026137, -0.00113555152, 2.07375025e-007, -2.033902231e-011, 8.282283700000001e-016}, bhigh = {50582.1903, -71.2523514}, R_s = R_NASA_2002/CH2I2.MM);
          constant IdealGases.Common.DataRecord CH3(name = "CH3", MM = 0.01503452, Hf = 9754753.726756824, H0 = 0, Tlimit = 1000, alow = {-28761.88806, 509.326866, 0.2002143949, 0.01363605829, -1.433989346e-005, 1.013556725e-008, -3.027331936e-012}, blow = {1.408271825e+004, 2.022772791e+001}, ahigh = {2760802.663, -9336.53117, 14.87729606, -0.001439429774, 2.444477951e-007, -2.224555778e-011, 8.395065760e-016}, bhigh = {7.481809480e+004, -7.919682400e+001}, R_s = R_NASA_2002/CH3.MM);
          constant IdealGases.Common.DataRecord CH3Br(name = "CH3Br", MM = 0.09493852, Hf = -397520.4163705101, H0 = 111784.5001164965, Tlimit = 1000, alow = {-71155.85769999999, 1524.705928, -8.230445209999999, 0.0423997321, -4.94697989e-005, 3.19443334e-008, -8.531237080000001e-012}, blow = {-12517.53591, 70.48127769999999}, ahigh = {2524874.348, -10118.76098, 18.65902163, -0.00179767369, 3.29852011e-007, -3.25091203e-011, 1.330179925e-015}, bhigh = {55405.7639, -97.7866446}, R_s = R_NASA_2002/CH3Br.MM);
          constant IdealGases.Common.DataRecord CH3CL(name = "CH3CL", MM = 0.05048752, Hf = -1621588.859979654, H0 = 206311.2626645159, Tlimit = 1000, alow = {-98419.71100000001, 1983.700841, -10.84512305, 0.0477798005, -5.51551626e-005, 3.50617614e-008, -9.23610396e-012}, blow = {-19946.89506, 83.99658330999999}, ahigh = {2522463.305, -10301.15447, 18.82725852, -0.001872291294, 3.47337286e-007, -3.45888722e-011, 1.428941079e-015}, bhigh = {51114.1741, -100.6571389}, R_s = R_NASA_2002/CH3CL.MM);
          constant IdealGases.Common.DataRecord CH3F(name = "CH3F", MM = 0.0340329232, Hf = -6984413.257806781, H0 = 297806.5957025989, Tlimit = 1000, alow = {-202982.1878, 3447.33113, -17.68994275, 0.059452758, -6.46952825e-005, 3.85941804e-008, -9.626541530000001e-012}, blow = {-45779.26220000001, 122.8382176}, ahigh = {2561903.188, -10860.52758, 19.2944692, -0.002070973131, 3.92912453e-007, -3.99450342e-011, 1.681447081e-015}, bhigh = {35635.0851, -106.1158456}, R_s = R_NASA_2002/CH3F.MM);
          constant IdealGases.Common.DataRecord CH3I(name = "CH3I", MM = 0.14193899, Hf = 96980.82253509061, H0 = 76200.58449056177, Tlimit = 1000, alow = {-45164.6274, 1086.208429, -5.66317627, 0.0368317171, -4.3213935e-005, 2.833483666e-008, -7.684383690000001e-012}, blow = {-4303.83065, 56.88562690000001}, ahigh = {2511915.982, -9960.289989999999, 18.56907132, -0.001768191331, 3.24220626e-007, -3.19294201e-011, 1.305407821e-015}, bhigh = {60669.29949999999, -95.9077704}, R_s = R_NASA_2002/CH3I.MM);
          constant IdealGases.Common.DataRecord CH2OH(name = "CH2OH", MM = 0.03103392, Hf = -573565.9562182283, H0 = 379616.8837194915, Tlimit = 1000, alow = {-156007.6238, 2685.446279, -13.4202242, 0.0575713947, -7.28444999e-005, 4.836648860000001e-008, -1.293492601e-011}, blow = {-15968.2041, 99.630337}, ahigh = {2250349.506, -8173.186060000001, 15.99639179, -0.0008704133719999999, 6.06918395e-008, 4.40834946e-012, -5.7023095e-016}, bhigh = {46453.1343, -78.3515845}, R_s = R_NASA_2002/CH2OH.MM);
          constant IdealGases.Common.DataRecord CH2OHplus(name = "CH2OHplus", MM = 0.0310333714, Hf = 23084826.67790326, H0 = 327035.0446036295, Tlimit = 1000, alow = {-107708.0841, 2252.082711, -11.88167865, 0.0460231696, -4.87973688e-005, 2.876413471e-008, -7.1002265e-012}, blow = {74844.4777, 90.2792857}, ahigh = {2603333.487, -10099.5381, 17.30843898, -0.000694639032, 3.009715083e-008, 5.22148598e-012, -5.09018379e-016}, bhigh = {146540.2426, -92.2395528}, R_s = R_NASA_2002/CH2OHplus.MM);
          constant IdealGases.Common.DataRecord CH3O(name = "CH3O", MM = 0.03103392, Hf = 418896.4848784814, H0 = 364183.7705323724, Tlimit = 1000, alow = {86571.17660000001, -663.1685250000001, 2.257455672, 0.02266283789, -2.970566403e-005, 2.199341353e-008, -6.58804338e-012}, blow = {4174.102129999999, 8.174777900000001}, ahigh = {2101188.243, -8841.968800000001, 18.22645731, -0.001743485034, 3.34043427e-007, -3.43067316e-011, 1.473897771e-015}, bhigh = {53095.82060000001, -94.2250059}, R_s = R_NASA_2002/CH3O.MM);
          constant IdealGases.Common.DataRecord CH4(name = "CH4", MM = 0.01604246, Hf = -4650159.63885838, H0 = 624355.7409524474, Tlimit = 1000, alow = {-176685.0998, 2786.18102, -12.0257785, 0.0391761929, -3.61905443e-005, 2.026853043e-008, -4.976705489999999e-012}, blow = {-23313.1436, 89.0432275}, ahigh = {3730042.76, -13835.01485, 20.49107091, -0.001961974759, 4.72731304e-007, -3.72881469e-011, 1.623737207e-015}, bhigh = {75320.6691, -121.9124889}, R_s = R_NASA_2002/CH4.MM);
          constant IdealGases.Common.DataRecord CH3OH(name = "CH3OH", MM = 0.03204186, Hf = -6271171.523750494, H0 = 356885.5553329301, Tlimit = 1000, alow = {-241664.2886, 4032.14719, -20.46415436, 0.0690369807, -7.59893269e-005, 4.59820836e-008, -1.158706744e-011}, blow = {-44332.61169999999, 140.014219}, ahigh = {3411570.76, -13455.00201, 22.61407623, -0.002141029179, 3.73005054e-007, -3.49884639e-011, 1.366073444e-015}, bhigh = {56360.8156, -127.7814279}, R_s = R_NASA_2002/CH3OH.MM);
          constant IdealGases.Common.DataRecord CH3OOH(name = "CH3OOH", MM = 0.04804126, Hf = -2893346.261109721, H0 = 0, Tlimit = 1000, alow = {-149797.4156, 2656.222273, -13.77060625, 0.0658867383, -7.75180165e-005, 4.9688007e-008, -1.31436764e-011}, blow = {-3.058414201e+004, 1.031696850e+002}, ahigh = {3060740.61, -12829.59627, 25.41021168, -0.002394481095, 4.44342991e-007, -4.4166595e-011, 1.819673372e-015}, bhigh = {5.837492360e+004, -1.387713096e+002}, R_s = R_NASA_2002/CH3OOH.MM);
          constant IdealGases.Common.DataRecord CI(name = "CI", MM = 0.13891517, Hf = 4104669.15888308, H0 = 68344.68834469267, Tlimit = 1000, alow = {104301.1064, -1715.427168, 12.88874952, -0.01828504834, 2.135468356e-005, -1.286980869e-008, 3.16704766e-012}, blow = {75507.84700000001, -44.9681132}, ahigh = {-240822.9894, 344.738704, 4.9769687, -0.000844481539, 5.061239719999999e-007, -1.047700525e-010, 6.74084314e-015}, bhigh = {64513.4202, 1.090913159}, R_s = R_NASA_2002/CI.MM);
          constant IdealGases.Common.DataRecord CI2(name = "CI2", MM = 0.26581964, Hf = 1762073.084592245, H0 = 47562.82492896311, Tlimit = 1000, alow = {60282.89810000001, -1043.205435, 10.17465942, -0.00553567171, 5.63031901e-006, -3.108249657e-009, 7.20246956e-013}, blow = {59648.9655, -23.10319208}, ahigh = {-702865.553, 308.2750393, 9.04642705, -0.002946736644, 1.424347233e-006, -2.45318341e-010, 1.425270291e-014}, bhigh = {50211.34209999999, -15.60349377}, R_s = R_NASA_2002/CI2.MM);
          constant IdealGases.Common.DataRecord CI3(name = "CI3", MM = 0.39272411, Hf = 1033763.755935433, H0 = 42858.20649004717, Tlimit = 1000, alow = {85967.84250000001, -1347.703793, 12.72103659, -0.002442876357, 2.511609978e-007, 1.024658583e-009, -4.87269296e-013}, blow = {53107.1651, -32.384929}, ahigh = {-153651.1918, -83.5704437, 10.06203125, -2.466447336e-005, 5.41905475e-009, -6.181417e-013, 2.851262022e-017}, bhigh = {45825.8953, -14.94825345}, R_s = R_NASA_2002/CI3.MM);
          constant IdealGases.Common.DataRecord CI4(name = "CI4", MM = 0.51962858, Hf = 515644.0009516028, H0 = 43022.17172119363, Tlimit = 1000, alow = {89190.4387, -1651.906475, 17.96124325, -0.00851811425, 8.50868225e-006, -4.59909773e-009, 1.039492403e-012}, blow = {36893.9215, -58.0595312}, ahigh = {-144676.277, -52.8036517, 13.03985589, -1.606214814e-005, 3.56755047e-009, -4.10536698e-013, 1.907272766e-017}, bhigh = {28177.46618, -28.10414436}, R_s = R_NASA_2002/CI4.MM);
          constant IdealGases.Common.DataRecord CN(name = "CN", MM = 0.0260174, Hf = 16861160.30041434, H0 = 333319.3939440528, Tlimit = 1000, alow = {3949.14857, -139.1590572, 4.93083532, -0.006304670510000001, 1.256836472e-005, -9.878300500000001e-009, 2.843137221e-012}, blow = {52284.55379999999, -2.763115585}, ahigh = {-2228006.27, 5040.733389999999, -0.2121897722, 0.001354901134, 1.325929798e-007, -6.93700637e-011, 5.49495227e-015}, bhigh = {17844.96132, 32.82563919}, R_s = R_NASA_2002/CN.MM);
          constant IdealGases.Common.DataRecord CNplus(name = "CNplus", MM = 0.0260168514, Hf = 69143297.79352164, H0 = 333710.7886929008, Tlimit = 1000, alow = {-830290.9570000001, 8775.6875, -29.7744356, 0.0497689706, -1.302225951e-005, -2.058325353e-008, 1.126843895e-011}, blow = {170386.0539, 203.9918818}, ahigh = {-7153463.08, 18572.50421, -10.84534159, 0.00610668143, -1.191208566e-006, 1.184848778e-010, -4.799838730000001e-015}, bhigh = {92426.44959999999, 113.5340573}, R_s = R_NASA_2002/CNplus.MM);
          constant IdealGases.Common.DataRecord CNminus(name = "CNminus", MM = 0.0260179486, Hf = 2455424.32964911, H0 = 333273.93075102, Tlimit = 1000, alow = {-46065.4139, 429.417475, 2.32878188, -0.0001235303004, 4.47846277e-006, -4.40315129e-009, 1.349001191e-012}, blow = {4362.07834, 11.42928617}, ahigh = {351796.472, -1630.477359, 5.60987575, -0.000397560597, 8.856147079999999e-008, -9.722872320000001e-012, 4.43420569e-016}, bhigh = {16479.76581, -11.75502699}, R_s = R_NASA_2002/CNminus.MM);
          constant IdealGases.Common.DataRecord CNN(name = "CNN", MM = 0.0400241, Hf = 15827565.29191162, H0 = 259285.2806184274, Tlimit = 1000, alow = {-73576.9236, 965.2438659999999, -1.704121157, 0.02037239025, -2.183423906e-005, 1.176082777e-008, -2.551355221e-012}, blow = {70217.2983, 35.2815091}, ahigh = {-181714.8765, -672.986349, 7.85794834, -6.13688072e-005, -1.088178985e-008, 4.45665581e-012, -2.836496278e-016}, bhigh = {77234.8898, -19.66012324}, R_s = R_NASA_2002/CNN.MM);
          constant IdealGases.Common.DataRecord CO(name = "CO", MM = 0.0280101, Hf = -3946262.098314536, H0 = 309570.6191695138, Tlimit = 1000, alow = {14890.45326, -292.2285939, 5.72452717, -0.008176235030000001, 1.456903469e-005, -1.087746302e-008, 3.027941827e-012}, blow = {-13031.31878, -7.85924135}, ahigh = {461919.725, -1944.704863, 5.91671418, -0.0005664282830000001, 1.39881454e-007, -1.787680361e-011, 9.62093557e-016}, bhigh = {-2466.261084, -13.87413108}, R_s = R_NASA_2002/CO.MM);
          constant IdealGases.Common.DataRecord COplus(name = "COplus", MM = 0.0280095514, Hf = 44548703.62543543, H0 = 309576.6824741077, Tlimit = 1000, alow = {-21787.86658, 128.8857032, 3.76905755, -0.00343173013, 8.19394575e-006, -6.463814690000001e-009, 1.803727574e-012}, blow = {148234.5898, 3.99054707}, ahigh = {231684.7506, -1057.646148, 4.55425778, 0.000449552032, -2.489507047e-007, 5.26756642e-011, -3.28951027e-015}, bhigh = {155505.0724, -3.87346264}, R_s = R_NASA_2002/COplus.MM);
          constant IdealGases.Common.DataRecord COCL(name = "COCL", MM = 0.0634631, Hf = -252115.0085640317, H0 = 182007.3239409988, Tlimit = 1000, alow = {25131.7574, -596.918967, 8.327671349999999, -0.00705613259, 1.313150734e-005, -1.037059653e-008, 3.033665179e-012}, blow = {-705.277032, -15.80716775}, ahigh = {344372.024, -1793.14347, 8.392755899999999, -0.000537476959, 9.113555710000001e-008, -3.111441728e-012, -2.040435218e-016}, bhigh = {6914.470149999999, -19.98919104}, R_s = R_NASA_2002/COCL.MM);
          constant IdealGases.Common.DataRecord COCL2(name = "COCL2", MM = 0.09891610000000001, Hf = -2219052.307966044, H0 = 130197.4299431538, Tlimit = 1000, alow = {93193.2145, -1577.971273, 12.08353907, -0.00480901561, 7.688477319999999e-006, -5.8588412e-009, 1.687786559e-012}, blow = {-20542.52334, -38.3476732}, ahigh = {-25458.81891, -1305.958516, 10.92922584, -0.000360121016, 7.78701765e-008, -8.79245203e-012, 4.02869661e-016}, bhigh = {-22198.4734, -32.3330345}, R_s = R_NASA_2002/COCL2.MM);
          constant IdealGases.Common.DataRecord COFCL(name = "COFCL", MM = 0.08246150319999999, Hf = -5208404.471578928, H0 = 144355.821056631, Tlimit = 1000, alow = {72621.739, -1019.738175, 7.29091199, 0.00742069171, -7.902548079999999e-006, 4.209427650000001e-009, -9.3144129e-013}, blow = {-48043.8646, -13.16923671}, ahigh = {-53168.8791, -1581.009678, 11.12696501, -0.00043730008, 9.464190710000001e-008, -1.069291346e-011, 4.901756640000001e-016}, bhigh = {-45996.6723, -35.25879824}, R_s = R_NASA_2002/COFCL.MM);
          constant IdealGases.Common.DataRecord COF2(name = "COF2", MM = 0.06600690640000001, Hf = -9695955.088723866, H0 = 168678.2430391253, Tlimit = 1000, alow = {52633.9315, -461.860339, 2.774114516, 0.01831931082, -2.130172554e-005, 1.266924542e-008, -3.101675983e-012}, blow = {-75642.55099999999, 9.467181460000001}, ahigh = {-40738.0685, -1974.009812, 11.40363654, -0.000543711147, 1.175232744e-007, -1.326564192e-011, 6.07677213e-016}, bhigh = {-69077.9541, -40.09695}, R_s = R_NASA_2002/COF2.MM);
          constant IdealGases.Common.DataRecord COHCL(name = "COHCL", MM = 0.06447104000000001, Hf = -2547064.170207274, H0 = 170716.6814743488, Tlimit = 1000, alow = {6332.94687, 81.2036559, 1.374648391, 0.01650970564, -1.692917241e-005, 9.68404683e-009, -2.37446939e-012}, blow = {-21203.5658, 19.3837965}, ahigh = {831895.285, -4416.87084, 12.70661114, -0.0009361408629999999, 1.855335611e-007, -1.958378539e-011, 8.512046829999999e-016}, bhigh = {4330.49644, -51.45071542}, R_s = R_NASA_2002/COHCL.MM);
          constant IdealGases.Common.DataRecord COHF(name = "COHF", MM = 0.0480164432, Hf = -7801293.391093992, H0 = 217629.5098842307, Tlimit = 1000, alow = {-45858.285, 1048.202675, -4.77657422, 0.03080719931, -3.4158959e-005, 2.034926806e-008, -5.05419462e-012}, blow = {-50859.8373, 52.3224741}, ahigh = {857885.316, -4791.95912, 12.93975218, -0.001018285299, 2.021278474e-007, -2.136698091e-011, 9.299588910000002e-016}, bhigh = {-18789.33107, -55.2744914}, R_s = R_NASA_2002/COHF.MM);
          constant IdealGases.Common.DataRecord COS(name = "COS", MM = 0.0600751, Hf = -2358714.342547911, H0 = 165486.1498357889, Tlimit = 1000, alow = {85478.76430000001, -1319.464821, 9.735257239999999, -0.00687083096, 1.082331416e-005, -7.70559734e-009, 2.078570344e-012}, blow = {-11916.57685, -29.91988593}, ahigh = {195909.8567, -1756.167688, 8.71043034, -0.000413942496, 1.015243648e-007, -1.159609663e-011, 5.691053860000001e-016}, bhigh = {-8927.09669, -26.36328016}, R_s = R_NASA_2002/COS.MM);
          constant IdealGases.Common.DataRecord CO2(name = "CO2", MM = 0.0440095, Hf = -8941478.544405185, H0 = 212805.6215135368, Tlimit = 1000, alow = {49436.5054, -626.411601, 5.30172524, 0.002503813816, -2.127308728e-007, -7.68998878e-010, 2.849677801e-013}, blow = {-45281.9846, -7.04827944}, ahigh = {117696.2419, -1788.791477, 8.29152319, -9.22315678e-005, 4.86367688e-009, -1.891053312e-012, 6.330036589999999e-016}, bhigh = {-39083.5059, -26.52669281}, R_s = R_NASA_2002/CO2.MM);
          constant IdealGases.Common.DataRecord CO2plus(name = "CO2plus", MM = 0.0440089514, Hf = 21465814.54335674, H0 = 240089.5423288817, Tlimit = 1000, alow = {-73830.3098, 1086.211742, -2.771112737, 0.02318463595, -2.570240315e-005, 1.450335497e-008, -3.33447042e-012}, blow = {107178.4918, 40.54885210000001}, ahigh = {-169505.1682, -806.646973, 8.00282846, -0.0001577214041, 2.566759314e-008, -2.404195965e-012, 1.6774468e-016}, bhigh = {115438.9478, -21.33567772}, R_s = R_NASA_2002/CO2plus.MM);
          constant IdealGases.Common.DataRecord COOH(name = "COOH", MM = 0.04501744, Hf = -4731499.614371675, H0 = 240203.5522233161, Tlimit = 1000, alow = {-11283.80671, 377.517943, -0.5992550409999999, 0.02181894272, -2.425918417e-005, 1.451245206e-008, -3.59623338e-012}, blow = {-28410.42565, 29.34561769}, ahigh = {929318.873, -4483.030570000001, 12.42199567, -0.0007463139639999999, 1.332996131e-007, -1.28271055e-011, 5.1379979e-016}, bhigh = {-851.8232680000001, -50.6806551}, R_s = R_NASA_2002/COOH.MM);
          constant IdealGases.Common.DataRecord CP(name = "CP", MM = 0.042984461, Hf = 12101159.18401303, H0 = 202750.1287034866, Tlimit = 1000, alow = {-45239.4011, 775.8828140000001, -1.453947907, 0.01397713706, -1.624489706e-005, 9.514083879999999e-009, -2.210281109e-012}, blow = {57926.3467, 33.1164792}, ahigh = {-5449937.15, 16883.45926, -15.956922, 0.01136028761, -2.84654133e-006, 3.37936404e-010, -1.554457397e-014}, bhigh = {-45545.17739999999, 145.1324059}, R_s = R_NASA_2002/CP.MM);
          constant IdealGases.Common.DataRecord CS(name = "CS", MM = 0.0440757, Hf = 6319810.643960278, H0 = 197577.7582658926, Tlimit = 1000, alow = {-49248.4412, 816.69681, -1.542998408, 0.01380324735, -1.574407905e-005, 9.16971493e-009, -2.169700595e-012}, blow = {28651.82876, 33.08541327}, ahigh = {-971957.476, 2339.201284, 1.709390402, 0.001577178949, -4.146335910000001e-007, 4.50475708e-011, -5.94545773e-016}, bhigh = {16810.20727, 18.7404822}, R_s = R_NASA_2002/CS.MM);
          constant IdealGases.Common.DataRecord CS2(name = "CS2", MM = 0.07614069999999999, Hf = 1532688.824767831, H0 = 140059.4294510032, Tlimit = 1000, alow = {16135.60482, -464.948147, 6.29793879, 0.001888896706, 3.031927747e-007, -1.737645373e-009, 7.79398939e-013}, blow = {14777.61119, -9.303382129999999}, ahigh = {-1390419.724, 3354.9755, 3.019247723, 0.002876437543, -9.076812719999999e-007, 1.374091042e-010, -6.99957557e-015}, bhigh = {-10138.98046, 15.65113703}, R_s = R_NASA_2002/CS2.MM);
          constant IdealGases.Common.DataRecord C2(name = "C2", MM = 0.0240214, Hf = 34571562.10712116, H0 = 423335.9421182778, Tlimit = 1000, alow = {555963.451, -9980.12644, 66.8162037, -0.1743432724, 0.0002448523051, -1.70346758e-007, 4.68452773e-011}, blow = {144586.9634, -344.82297}, ahigh = {-968926.793, 3561.09299, -0.5064138930000001, 0.002945154879, -7.13944119e-007, 8.67065725e-011, -4.07690681e-015}, bhigh = {76817.96829999999, 33.3998524}, R_s = R_NASA_2002/C2.MM);
          constant IdealGases.Common.DataRecord C2plus(name = "C2plus", MM = 0.0240208514, Hf = 83459803.26076201, H0 = 361565.2024723819, Tlimit = 1000, alow = {-99134.2384, 1347.170609, -3.47675316, 0.01676429424, -1.865908025e-005, 1.091134647e-008, -2.434913818e-012}, blow = {233545.48, 44.0664462}, ahigh = {3836292.81, -6242.062449999999, 2.779245639, 0.006065865859999999, -2.452799858e-006, 3.8829425e-010, -2.190639912e-014}, bhigh = {285744.7553, 0.729738349}, R_s = R_NASA_2002/C2plus.MM);
          constant IdealGases.Common.DataRecord C2minus(name = "C2minus", MM = 0.0240219486, Hf = 20013651.34883354, H0 = 361174.0306529504, Tlimit = 1000, alow = {-118192.866, 1438.18971, -3.19613135, 0.01465548163, -1.545537278e-005, 9.061235610000001e-009, -2.135962274e-012}, blow = {49653.1779, 42.2560888}, ahigh = {4478136.25, -11541.45714, 13.10143499, -0.001862700578, 4.00693125e-008, 3.7102136e-011, -3.33726687e-015}, bhigh = {132535.6168, -69.75964399999999}, R_s = R_NASA_2002/C2minus.MM);
          constant IdealGases.Common.DataRecord C2CL(name = "C2CL", MM = 0.0594744, Hf = 8980049.752498554, H0 = 181264.9812356241, Tlimit = 1000, alow = {47258.8941, -898.0223609999999, 9.016877149999999, -0.00633378283, 1.08706005e-005, -8.089068920000001e-009, 2.248275223e-012}, blow = {67022.15700000001, -23.54893403}, ahigh = {213736.8408, -1630.519518, 8.62349025, -0.000425351786, 9.04001864e-008, -1.007541495e-011, 4.570764750000001e-016}, bhigh = {71710.9328, -24.13014598}, R_s = R_NASA_2002/C2CL.MM);
          constant IdealGases.Common.DataRecord C2CL2(name = "C2CL2", MM = 0.09492680000000001, Hf = 2387102.48317651, H0 = 0, Tlimit = 1000, alow = {3.871168730e+004, -9.336870210e+002, 1.119377832e+001, -3.746287380e-003, 6.770471350e-006, -4.910387450e-009, 1.299068486e-012}, blow = {2.948153174e+004, -3.310723530e+001}, ahigh = {2.961995390e+005, -2.044290845e+003, 1.187529729e+001, -5.115031340e-004, 1.072666588e-007, -1.183417569e-011, 5.326530480e-016}, bhigh = {3.636802500e+004, -4.000826050e+001}, R_s = R_NASA_2002/C2CL2.MM);
          constant IdealGases.Common.DataRecord C2CL3(name = "C2CL3", MM = 0.1303804, Hf = 1459357.326714752, H0 = 123870.2903197106, Tlimit = 1000, alow = {46750.1604, -885.1019640000001, 9.03227055, 0.01242122796, -1.554614347e-005, 9.51388712e-009, -2.341473263e-012}, blow = {24958.63399, -17.79070154}, ahigh = {-220402.8219, -1072.926248, 13.78367377, -0.0003093322915, 6.77752895e-008, -7.72730182e-012, 3.56669022e-016}, bhigh = {24310.20015, -43.42161815}, R_s = R_NASA_2002/C2CL3.MM);
          constant IdealGases.Common.DataRecord C2CL4(name = "C2CL4", MM = 0.1658322, Hf = -145930.6455561706, H0 = 0, Tlimit = 1000, alow = {3.746257500e+004, -8.481774390e+002, 1.009156041e+001, 1.845463807e-002, -2.390899731e-005, 1.514828471e-008, -3.841119950e-012}, blow = {-1.598289063e+003, -2.368079134e+001}, ahigh = {-3.001289625e+005, -1.132413909e+003, 1.683073063e+001, -3.288820170e-004, 7.220975400e-008, -8.245417760e-012, 3.810154710e-016}, bhigh = {-2.292758158e+003, -5.980164420e+001}, R_s = R_NASA_2002/C2CL4.MM);
          constant IdealGases.Common.DataRecord C2CL6(name = "C2CL6", MM = 0.2367376, Hf = -626009.5565723401, H0 = 0, Tlimit = 1000, alow = {1.593451902e+005, -2.606697262e+003, 2.028011918e+001, 1.769364625e-002, -3.133104894e-005, 2.389395021e-008, -6.893037660e-012}, blow = {-9.038007040e+003, -7.953073010e+001}, ahigh = {-5.577351940e+005, -4.976576790e+002, 2.237042798e+001, -1.477797229e-004, 3.257641460e-008, -3.727218070e-012, 1.723860648e-016}, bhigh = {-2.335217699e+004, -8.381736910e+001}, R_s = R_NASA_2002/C2CL6.MM);
          constant IdealGases.Common.DataRecord C2F(name = "C2F", MM = 0.0430198032, Hf = 8225223.16884983, H0 = 240982.8783224188, Tlimit = 1000, alow = {12497.97213, -348.387675, 5.75508435, 0.000852868538, 2.353546435e-006, -2.804737097e-009, 9.083575639999999e-013}, blow = {42815.2531, -6.43720096}, ahigh = {289877.6676, -2016.644658, 8.87504571, -0.000516684113, 1.092094306e-007, -1.212216787e-011, 5.48228768e-016}, bhigh = {52412.8792, -27.7308958}, R_s = R_NASA_2002/C2F.MM);
          constant IdealGases.Common.DataRecord C2FCL(name = "C2FCL", MM = 0.0784728032, Hf = 430294.2882509389, H0 = 176832.0543441476, Tlimit = 1000, alow = {26976.75344, -741.4403179999999, 9.6296043, -0.000386554493, 3.003347997e-006, -2.710191661e-009, 7.73758689e-013}, blow = {5500.62039, -25.15774889}, ahigh = {347145.489, -2348.4611, 12.06875617, -0.000580469823, 1.21273434e-007, -1.334214186e-011, 5.99255661e-016}, bhigh = {15020.61224, -42.52445687}, R_s = R_NASA_2002/C2FCL.MM);
          constant IdealGases.Common.DataRecord C2FCL3(name = "C2FCL3", MM = 0.1493788032, Hf = -1111268.777389696, H0 = 125398.7419816201, Tlimit = 1000, alow = {12372.82217, -470.396184, 7.58162179, 0.02305727066, -2.792144322e-005, 1.679699826e-008, -4.07757244e-012}, blow = {-20313.33976, -9.274637513}, ahigh = {-282950.5545, -1473.853145, 17.07879074, -0.000426521339, 9.357199850000001e-008, -1.067932796e-011, 4.93326161e-016}, bhigh = {-17384.33314, -61.97054796}, R_s = R_NASA_2002/C2FCL3.MM);
          constant IdealGases.Common.DataRecord C2F2(name = "C2F2", MM = 0.0620182064, Hf = -2332632.567071465, H0 = 213911.684488831, Tlimit = 1000, alow = {17763.13572, -611.328094, 8.6636068, 0.0009156381209999999, 2.363808425e-006, -2.753750054e-009, 8.713935969999999e-013}, blow = {-16496.11017, -21.65150307}, ahigh = {419389.094, -2715.359989, 12.30403413, -0.0006649305540000001, 1.385254301e-007, -1.520813764e-011, 6.81982103e-016}, bhigh = {-4179.221939999999, -46.7038623}, R_s = R_NASA_2002/C2F2.MM);
          constant IdealGases.Common.DataRecord C2F2CL2(name = "C2F2CL2", MM = 0.1329242064, Hf = -2541576.204588121, H0 = 134934.2567901161, Tlimit = 1000, alow = {-115043.3214, 2032.113595, -11.19750271, 0.08342451400000001, -0.0001163698616, 7.83309289e-008, -2.070004069e-011}, blow = {-52082.5681, 88.88322147}, ahigh = {-870256.566, 726.472448, 15.30689121, 0.0003045597224, -7.04546804e-008, 8.28592434e-012, -3.89858107e-016}, bhigh = {-52088.8871, -49.98300753}, R_s = R_NASA_2002/C2F2CL2.MM);
          constant IdealGases.Common.DataRecord C2F3(name = "C2F3", MM = 0.0810166096, Hf = -2816472.993952588, H0 = 174823.0032079743, Tlimit = 1000, alow = {-26147.75016, 210.1767714, 2.32862508, 0.02368943293, -2.416431591e-005, 1.224916093e-008, -2.488670434e-012}, blow = {-30285.66585, 16.9960879}, ahigh = {-124260.3837, -2137.292446, 14.55051371, -0.0006093891980000001, 1.331427672e-007, -1.515124358e-011, 6.98411206e-016}, bhigh = {-19771.46179, -54.21039870000001}, R_s = R_NASA_2002/C2F3.MM);
          constant IdealGases.Common.DataRecord C2F3CL(name = "C2F3CL", MM = 0.1164696096, Hf = -4423471.511318606, H0 = 147061.1008212738, Tlimit = 1000, alow = {-8122.270309999999, -157.4007092, 5.04181029, 0.02621692321, -2.843001445e-005, 1.537643979e-008, -3.36073067e-012}, blow = {-63540.49950000001, 2.792301872}, ahigh = {-216272.4659, -2195.103372, 17.59605428, -0.000628261729, 1.37416661e-007, -1.565004037e-011, 7.218309900000001e-016}, bhigh = {-55151.095, -69.21931823999999}, R_s = R_NASA_2002/C2F3CL.MM);
          constant IdealGases.Common.DataRecord C2F4(name = "C2F4", MM = 0.1000150128, Hf = -6594010.054458545, H0 = 163281.0269459867, Tlimit = 1000, alow = {-9991.530069999999, -129.1088427, 4.50422905, 0.0259202964, -2.63030872e-005, 1.316489777e-008, -2.625017169e-012}, blow = {-80904.47080000001, 3.27424147}, ahigh = {-162991.5758, -2603.903955, 17.88488423, -0.000739703801, 1.61446034e-007, -1.835820392e-011, 8.45764107e-016}, bhigh = {-70063.7166, -74.54165860000001}, R_s = R_NASA_2002/C2F4.MM);
          constant IdealGases.Common.DataRecord C2F6(name = "C2F6", MM = 0.1380118192, Hf = -9738296.384980919, H0 = 146886.2603037118, Tlimit = 1000, alow = {-37953.717, 799.82764, -4.67156181, 0.0750145099, -9.812116100000001e-005, 6.31980759e-008, -1.622597311e-011}, blow = {-167521.1878, 50.537592}, ahigh = {-1011551.484, -942.2140710000001, 22.02553906, -0.000131451875, 1.8660453e-008, -3.46711861e-012, 2.488311205e-016}, bhigh = {-165743.4402, -93.02161150000001}, R_s = R_NASA_2002/C2F6.MM);
          constant IdealGases.Common.DataRecord C2H(name = "C2H", MM = 0.02502934, Hf = 22621470.72196071, H0 = 417457.3520516323, Tlimit = 1000, alow = {13436.69487, -506.797072, 7.77210741, -0.00651233982, 1.030117855e-005, -5.880147670000001e-009, 1.226901861e-012}, blow = {68922.69989999999, -18.71881626}, ahigh = {3922334.57, -12047.51703, 17.5617292, -0.00365544294, 6.98768543e-007, -6.82516201e-011, 2.719262793e-015}, bhigh = {143326.6627, -95.6163438}, R_s = R_NASA_2002/C2H.MM);
          constant IdealGases.Common.DataRecord C2HCL(name = "C2HCL", MM = 0.06048204, Hf = 3743259.982632861, H0 = 0, Tlimit = 1000, alow = {1.329784931e+005, -2.174542005e+003, 1.497980787e+001, -1.290343200e-002, 1.602596399e-005, -9.152047430e-009, 2.021222995e-012}, blow = {3.604801260e+004, -5.958236750e+001}, ahigh = {1.152149855e+006, -4.461204350e+003, 1.281367818e+001, -6.797397460e-004, 1.151395389e-007, -1.046657798e-011, 3.949939170e-016}, bhigh = {5.233955000e+004, -5.320661700e+001}, R_s = R_NASA_2002/C2HCL.MM);
          constant IdealGases.Common.DataRecord C2HCL3(name = "C2HCL3", MM = 0.13138744, Hf = -133193.8577994974, H0 = 0, Tlimit = 1000, alow = {3.959233060e+004, -5.178756040e+002, 5.155030160e+000, 2.816922101e-002, -3.624741150e-005, 2.392073843e-008, -6.362400700e-012}, blow = {-1.534345080e+003, 1.209377115e+000}, ahigh = {6.049298240e+005, -4.237003190e+003, 1.846274582e+001, -8.137243260e-004, 1.551223511e-007, -1.584645594e-011, 6.701006540e-016}, bhigh = {1.848292676e+004, -7.698375250e+001}, R_s = R_NASA_2002/C2HCL3.MM);
          constant IdealGases.Common.DataRecord C2HF(name = "C2HF", MM = 0.0440277432, Hf = 946955.282504691, H0 = 259970.3543287678, Tlimit = 1000, alow = {91611.6911, -1537.245636, 11.33665074, -0.00462472931, 5.87798546e-006, -2.690992345e-009, 3.52471953e-013}, blow = {10859.0282, -40.23994380000001}, ahigh = {1234347.179, -4819.58196, 13.02337752, -0.000749543582, 1.285452942e-007, -1.184559365e-011, 4.53678476e-016}, bhigh = {32368.1171, -56.4079182}, R_s = R_NASA_2002/C2HF.MM);
          constant IdealGases.Common.DataRecord C2HFCL2(name = "C2HFCL2", MM = 0.1149337432, Hf = -1467349.755645999, H0 = 141466.6358834818, Tlimit = 1000, alow = {31173.99823, -136.9505457, 1.176399869, 0.040807766, -5.4181378e-005, 3.61360066e-008, -9.625862350000001e-012}, blow = {-21151.42871, 21.4643316}, ahigh = {407124.352, -3808.20452, 18.2114405, -0.000727896606, 1.381532849e-007, -1.405342513e-011, 5.92000972e-016}, bhigh = {-2676.849943, -75.67353566999999}, R_s = R_NASA_2002/C2HFCL2.MM);
          constant IdealGases.Common.DataRecord C2HF2CL(name = "C2HF2CL", MM = 0.09847914640000001, Hf = -3388067.54726298, H0 = 154984.6293143743, Tlimit = 1000, alow = {170443.7675, -1667.236861, 4.7887885, 0.0444483001, -7.32219777e-005, 5.62934755e-008, -1.654638029e-011}, blow = {-32918.0976, -5.78859364}, ahigh = {583037.47, -3810.31741, 17.99003171, -0.000588821086, 1.002861284e-007, -9.149788100000001e-012, 3.45998516e-016}, bhigh = {-22058.75409, -75.90948533}, R_s = R_NASA_2002/C2HF2CL.MM);
          constant IdealGases.Common.DataRecord C2HF3(name = "C2HF3", MM = 0.0820245496, Hf = -5986012.75343059, H0 = 174673.461419409, Tlimit = 1000, alow = {-14109.69036, 368.762492, -1.144797568, 0.0395630602, -4.60200136e-005, 2.785149385e-008, -6.90376008e-012}, blow = {-62264.1033, 32.8966169}, ahigh = {691741.378, -5260.30164, 19.15276614, -0.001072493938, 2.099276744e-007, -2.195126633e-011, 9.472702399999999e-016}, bhigh = {-32476.4021, -87.5045695}, R_s = R_NASA_2002/C2HF3.MM);
          constant IdealGases.Common.DataRecord C2H2_vinylidene(name = "C2H2_vinylidene", MM = 0.02603728, Hf = 15930556.80163212, H0 = 417638.4015534649, Tlimit = 1000, alow = {-14660.42239, 278.9475593, 1.276229776, 0.01395015463, -1.475702649e-005, 9.476298110000001e-009, -2.567602217e-012}, blow = {47361.1018, 16.58225704}, ahigh = {1940838.725, -6892.718150000001, 13.39582494, -0.0009368968669999999, 1.470804368e-007, -1.220040365e-011, 4.12239166e-016}, bhigh = {91071.1293, -63.3750293}, R_s = R_NASA_2002/C2H2_vinylidene.MM);
          constant IdealGases.Common.DataRecord C2H2CL2(name = "C2H2CL2", MM = 0.09694328000000001, Hf = 35175.20760593204, H0 = 153517.366030941, Tlimit = 1000, alow = {-12037.24514, 462.903119, -1.318184584, 0.039304496, -4.85152902e-005, 3.17841146e-008, -8.476938410000001e-012}, blow = {-3251.80686, 34.89218118}, ahigh = {1561121.185, -7358.096350000001, 20.11869185, -0.001310978834, 2.411885716e-007, -2.38416674e-011, 9.78541575e-016}, bhigh = {41222.009, -95.50252712000001}, R_s = R_NASA_2002/C2H2CL2.MM);
          constant IdealGases.Common.DataRecord C2H2FCL(name = "C2H2FCL", MM = 0.08048868319999999, Hf = -2050996.406411579, H0 = 167344.1838591292, Tlimit = 1000, alow = {226015.4427, -2557.428772, 9.2362412, 0.02879408894, -5.16397547e-005, 4.25219103e-008, -1.311612713e-011}, blow = {-8180.627839999999, -32.34787581}, ahigh = {1527690.968, -6689.712229999999, 19.5055383, -0.001040920895, 1.780587502e-007, -1.633098515e-011, 6.213465560000001e-016}, bhigh = {17052.66451, -91.94078300999999}, R_s = R_NASA_2002/C2H2FCL.MM);
          constant IdealGases.Common.DataRecord C2H2F2(name = "C2H2F2", MM = 0.06403408640000001, Hf = -5253452.011458697, H0 = 194891.2477964236, Tlimit = 1000, alow = {57029.3581, -676.28604, 4.11741171, 0.01822618762, -6.86133154e-006, -3.29575674e-009, 2.180965597e-012}, blow = {-38386.5078, 1.487528685}, ahigh = {-822719.275, -2915.718833, 18.30163995, -0.001039630129, 2.546725128e-007, -3.157578705e-011, 1.55154096e-015}, bhigh = {-31100.28589, -84.00834700000002}, R_s = R_NASA_2002/C2H2F2.MM);
          constant IdealGases.Common.DataRecord CH2CO_ketene(name = "CH2CO_ketene", MM = 0.04203668, Hf = -1179353.245784396, H0 = 0, Tlimit = 1000, alow = {35495.9809, -406.306283, 3.71892192, 0.01583501817, -1.726195691e-005, 1.157376959e-008, -3.30584263e-012}, blow = {-5.209992580e+003, 3.839604220e+000}, ahigh = {2013564.915, -8200.88746, 17.59694074, -0.001464544521, 2.695886969e-007, -2.66567484e-011, 1.094204522e-015}, bhigh = {4.177776880e+004, -8.725803580e+001}, R_s = R_NASA_2002/CH2CO_ketene.MM);
          constant IdealGases.Common.DataRecord O_CH_2O(name = "O_CH_2O", MM = 0.05803608, Hf = -3652900.058032865, H0 = 0, Tlimit = 1000, alow = {-229245.9698, 3724.09805, -18.93769993, 0.0751174414, -8.083855420000001e-005, 4.35823319e-008, -9.36453933e-012}, blow = {-4.454486010e+004, 1.327028760e+002}, ahigh = {267806.3593, -4436.61748, 17.81696797, -0.000709717378, 1.272621878e-007, -1.237226678e-011, 5.025057520e-016}, bhigh = {-4.479608280e+003, -8.156700640e+001}, R_s = R_NASA_2002/O_CH_2O.MM);
          constant IdealGases.Common.DataRecord HO_CO_2OH(name = "HO_CO_2OH", MM = 0.09003488, Hf = -8127961.074641295, H0 = 0, Tlimit = 1000, alow = {30725.13274, -391.617469, 3.17838864, 0.0374128975, -4.00975396e-005, 2.288662646e-008, -5.386771549999999e-012}, blow = {-8.797942550e+004, 9.751091370e+000}, ahigh = {1805560.696, -9240.33315, 26.25742604, -0.001418458557, 2.526840574e-007, -2.521005198e-011, 1.040036111e-015}, bhigh = {-3.754286460e+004, -1.326879788e+002}, R_s = R_NASA_2002/HO_CO_2OH.MM);
          constant IdealGases.Common.DataRecord C2H3_vinyl(name = "C2H3_vinyl", MM = 0.02704522, Hf = 11080953.19616553, H0 = 389044.3856622353, Tlimit = 1000, alow = {-33478.9687, 1064.104103, -6.40385706, 0.0393451548, -4.76004609e-005, 3.17007135e-008, -8.633406430000001e-012}, blow = {30391.22649, 58.0922618}, ahigh = {2718080.093, -10309.56829, 18.36579807, -0.001580131153, 2.680594939e-007, -2.439003999e-011, 9.20909639e-016}, bhigh = {97650.55589999999, -97.6008686}, R_s = R_NASA_2002/C2H3_vinyl.MM);
          constant IdealGases.Common.DataRecord CH2BrminusCOOH(name = "CH2BrminusCOOH", MM = 0.13894802, Hf = -2760024.935943672, H0 = 0, Tlimit = 1000, alow = {-78324.84789999999, 1648.865353, -9.34953363, 0.06879635440000001, -8.374880770000001e-005, 5.40603842e-008, -1.423159923e-011}, blow = {-5.541187620e+004, 8.165423200e+001}, ahigh = {2486349.85, -11402.56346, 27.56020307, -0.00184318701, 3.26539274e-007, -3.122663159e-011, 1.223452495e-015}, bhigh = {1.837013127e+004, -1.420040888e+002}, R_s = R_NASA_2002/CH2BrminusCOOH.MM);
          constant IdealGases.Common.DataRecord C2H3CL(name = "C2H3CL", MM = 0.06249792, Hf = 352011.7149498736, H0 = 0, Tlimit = 1000, alow = {-1.688896130e+004, 8.545105550e+002, -6.514968110e+000, 4.944682090e-002, -6.117756910e-005, 4.067294030e-008, -1.101392662e-011}, blow = {-2.069321797e+003, 5.928435530e+001}, ahigh = {2.456178566e+006, -1.047452720e+004, 2.178736544e+001, -1.816893523e-003, 3.296374030e-007, -3.214400710e-011, 1.302256512e-015}, bhigh = {6.346231290e+004, -1.149890773e+002}, R_s = R_NASA_2002/C2H3CL.MM);
          constant IdealGases.Common.DataRecord CH2CLminusCOOH(name = "CH2CLminusCOOH", MM = 0.09449671999999999, Hf = -4525024.783929008, H0 = 0, Tlimit = 1000, alow = {-1.122506431e+005, 2.168288546e+003, -1.227791221e+001, 7.514388060e-002, -9.083158490e-005, 5.812363980e-008, -1.518247440e-011}, blow = {-6.314314500e+004, 9.694389710e+001}, ahigh = {2.472881709e+006, -1.152275613e+004, 2.766275288e+001, -1.886429520e-003, 3.361772590e-007, -3.231268060e-011, 1.273273865e-015}, bhigh = {1.370384800e+004, -1.443191119e+002}, R_s = R_NASA_2002/CH2CLminusCOOH.MM);
          constant IdealGases.Common.DataRecord C2H3F(name = "C2H3F", MM = 0.0460436232, Hf = -3042766.625715937, H0 = 246199.7386860728, Tlimit = 1000, alow = {-45791.3496, 1411.541724, -10.21500877, 0.0577581657, -7.08067749e-005, 4.64085076e-008, -1.240455865e-011}, blow = {-24027.88827, 78.6082839}, ahigh = {2478832.34, -10759.32307, 21.94796688, -0.00186911411, 3.39528067e-007, -3.31538293e-011, 1.345081799e-015}, bhigh = {45634.5555, -118.0410277}, R_s = R_NASA_2002/C2H3F.MM);
          constant IdealGases.Common.DataRecord CH3CN(name = "CH3CN", MM = 0.04105192000000001, Hf = 1618194.715375066, H0 = 294594.9422097675, Tlimit = 1000, alow = {-99659.88380000001, 1739.278534, -7.89842082, 0.0429489432, -4.49997388e-005, 2.717105086e-008, -7.026117590000001e-012}, blow = {-1461.161333, 68.52508274}, ahigh = {2923231.393, -12337.92258, 23.24477222, -0.002411565845, 4.622157170000001e-007, -4.74060124e-011, 2.010639467e-015}, bhigh = {80585.65550000001, -129.2249102}, R_s = R_NASA_2002/CH3CN.MM);
          constant IdealGases.Common.DataRecord CH3CO_acetyl(name = "CH3CO_acetyl", MM = 0.04304462, Hf = -232317.0700542832, H0 = 302859.3817299352, Tlimit = 1000, alow = {-71938.94130000001, 1464.465167, -6.63227613, 0.04108468379999999, -4.22625664e-005, 2.485766819e-008, -6.29255848e-012}, blow = {-9309.37081, 64.22897619999999}, ahigh = {2485388.15, -11207.14204, 22.77525438, -0.00231426055, 4.53618917e-007, -4.74263555e-011, 2.044663903e-015}, bhigh = {63800.8841, -121.5350925}, R_s = R_NASA_2002/CH3CO_acetyl.MM);
          constant IdealGases.Common.DataRecord C2H4(name = "C2H4", MM = 0.02805316, Hf = 1871446.924339362, H0 = 374955.5843263291, Tlimit = 1000, alow = {-116360.5836, 2554.85151, -16.09746428, 0.0662577932, -7.885081859999999e-005, 5.12522482e-008, -1.370340031e-011}, blow = {-6176.19107, 109.3338343}, ahigh = {3408763.67, -13748.47903, 23.65898074, -0.002423804419, 4.43139566e-007, -4.35268339e-011, 1.775410633e-015}, bhigh = {88204.2938, -137.1278108}, R_s = R_NASA_2002/C2H4.MM);
          constant IdealGases.Common.DataRecord C2H4O_ethylen_o(name = "C2H4O_ethylen_o", MM = 0.04405256, Hf = -1194816.373895183, H0 = 245856.6539606325, Tlimit = 1000, alow = {-172823.3345, 3816.6788, -26.29851977, 0.1014103162, -0.0001240578373, 8.03404035e-008, -2.120942544e-011}, blow = {-24375.19333, 165.4885056}, ahigh = {3151809.957, -14236.46316, 27.08080476, -0.002606238456, 4.853891929999999e-007, -4.85214476e-011, 2.011778721e-015}, bhigh = {76625.61440000001, -156.3952401}, R_s = R_NASA_2002/C2H4O_ethylen_o.MM);
          constant IdealGases.Common.DataRecord CH3CHO_ethanal(name = "CH3CHO_ethanal", MM = 0.04405256, Hf = -3772538.98524853, H0 = 292757.4697134514, Tlimit = 1000, alow = {-137390.4369, 2559.937679, -13.40470172, 0.05922128619999999, -6.24000605e-005, 3.70332441e-008, -9.34269741e-012}, blow = {-33187.3131, 100.7417652}, ahigh = {3321176.59, -14497.19957, 27.08421279, -0.002879320054, 5.55630992e-007, -5.73267488e-011, 2.443965239e-015}, bhigh = {65077.5564, -153.6236027}, R_s = R_NASA_2002/CH3CHO_ethanal.MM);
          constant IdealGases.Common.DataRecord CH3COOH(name = "CH3COOH", MM = 0.06005196, Hf = -7197917.270310578, H0 = 226427.097466927, Tlimit = 1000, alow = {-32191.9198, 1196.329795, -8.70582402, 0.0569625759, -5.75788716e-005, 3.35211522e-008, -8.614438229999999e-012}, blow = {-58401.12869999999, 72.82413919999999}, ahigh = {2103514.223, -14678.22192, 33.8280283, -0.00569485868, 1.343221353e-006, -1.606041158e-010, 7.652794250000001e-015}, bhigh = {29242.28407, -193.527885}, R_s = R_NASA_2002/CH3COOH.MM);
          constant IdealGases.Common.DataRecord OHCH2COOH(name = "OHCH2COOH", MM = 0.07605136, Hf = -7665872.115896415, H0 = 223625.7050498505, Tlimit = 1000, alow = {-313897.858, 5693.06877, -36.8516029, 0.1563502811, -0.0002039487993, 1.340232412e-007, -3.50913026e-011}, blow = {-98016.40089999999, 226.9492355}, ahigh = {1946628.253, -9804.020200000001, 28.44111243, -0.000787640475, 6.416275950000001e-008, 1.069321262e-012, -3.23717828e-016}, bhigh = {-16946.5047, -147.4109363}, R_s = R_NASA_2002/OHCH2COOH.MM);
          constant IdealGases.Common.DataRecord C2H5(name = "C2H5", MM = 0.0290611, Hf = 4083060.861426443, H0 = 419296.7919314823, Tlimit = 1000, alow = {-141131.2551, 2714.285088, -15.34977725, 0.06451672580000001, -7.259143960000001e-005, 4.59911601e-008, -1.218367535e-011}, blow = {598.141884, 109.096652}, ahigh = {4169220.4, -16629.82142, 27.95442134, -0.003051715761, 5.685160040000001e-007, -5.6828636e-011, 2.355648561e-015}, bhigh = {113701.0087, -163.9357995}, R_s = R_NASA_2002/C2H5.MM);
          constant IdealGases.Common.DataRecord C2H5Br(name = "C2H5Br", MM = 0.1089651, Hf = -583673.1210268242, H0 = 124526.1097360531, Tlimit = 1000, alow = {-137417.2662, 2861.429418, -18.24108956, 0.08566230600000001, -0.0001047174473, 6.906074570000001e-008, -1.862276022e-011}, blow = {-21984.80205, 125.8435579}, ahigh = {2378649.403, -12670.33647, 27.77558646, -0.002010898783, 4.43608341e-007, -5.34819809e-011, 2.63983585e-015}, bhigh = {64140.6205, -152.8277085}, R_s = R_NASA_2002/C2H5Br.MM);
          constant IdealGases.Common.DataRecord C2H6(name = "C2H6", MM = 0.03006904, Hf = -2788633.890539904, H0 = 395476.3437741943, Tlimit = 1000, alow = {-186204.4161, 3406.19186, -19.51705092, 0.0756583559, -8.20417322e-005, 5.0611358e-008, -1.319281992e-011}, blow = {-27029.3289, 129.8140496}, ahigh = {5025782.13, -20330.22397, 33.2255293, -0.00383670341, 7.23840586e-007, -7.3191825e-011, 3.065468699e-015}, bhigh = {111596.395, -203.9410584}, R_s = R_NASA_2002/C2H6.MM);
          constant IdealGases.Common.DataRecord CH3N2CH3(name = "CH3N2CH3", MM = 0.05808244, Hf = 2560143.134482642, H0 = 284509.3801155737, Tlimit = 1000, alow = {-373849.232, 5880.45313, -29.86398524, 0.1087380861, -0.0001167950177, 6.916894889999999e-008, -1.719950055e-011}, blow = {-11899.84084, 194.8246321}, ahigh = {4993357.09, -21609.96161, 39.6444992, -0.00419645011, 8.023361980000001e-007, -8.212260020000001e-011, 3.47723744e-015}, bhigh = {144996.261, -237.2109745}, R_s = R_NASA_2002/CH3N2CH3.MM);
          constant IdealGases.Common.DataRecord C2H5OH(name = "C2H5OH", MM = 0.04606844, Hf = -5100020.751733725, H0 = 315659.1801241805, Tlimit = 1000, alow = {-234279.1392, 4479.18055, -27.44817302, 0.1088679162, -0.0001305309334, 8.437346399999999e-008, -2.234559017e-011}, blow = {-50222.29, 176.4829211}, ahigh = {4694817.65, -19297.98213, 34.4758404, -0.00323616598, 5.78494772e-007, -5.56460027e-011, 2.2262264e-015}, bhigh = {86016.22709999999, -203.4801732}, R_s = R_NASA_2002/C2H5OH.MM);
          constant IdealGases.Common.DataRecord CH3OCH3(name = "CH3OCH3", MM = 0.04606844, Hf = -3996445.288792067, H0 = 311588.1284454173, Tlimit = 1000, alow = {-269310.3242, 4300.709709999999, -21.52788028, 0.08131833390000001, -8.29567132e-005, 4.80191151e-008, -1.188699808e-011}, blow = {-44102.3709, 146.7666934}, ahigh = {4933577.19, -20830.94065, 36.2905061, -0.004108351640000001, 7.90322031e-007, -8.13143563e-011, 3.45816611e-015}, bhigh = {101330.1012, -218.5447466}, R_s = R_NASA_2002/CH3OCH3.MM);
          constant IdealGases.Common.DataRecord CH3O2CH3(name = "CH3O2CH3", MM = 0.06206784, Hf = -2021981.109701901, H0 = 276365.9247687692, Tlimit = 1000, alow = {-228578.4757, 3820.14257, -19.76647823, 0.0884074386, -9.641284560000001e-005, 5.90720083e-008, -1.526491225e-011}, blow = {-34920.1696, 138.6769151}, ahigh = {5316368.47, -22212.67874, 40.3433509, -0.00461274809, 8.792987200000001e-007, -9.068221189999999e-011, 3.865664890000001e-015}, bhigh = {116159.6028, -239.5296055}, R_s = R_NASA_2002/CH3O2CH3.MM);
          constant IdealGases.Common.DataRecord CCN(name = "CCN", MM = 0.0380281, Hf = 21157945.62441983, H0 = 290272.8245692001, Tlimit = 1000, alow = {-16962.81385, 98.3789163, 3.81266294, 0.00534689423, -2.473598508e-006, -3.73056422e-010, 4.48175686e-013}, blow = {94800.72570000001, 5.553165572}, ahigh = {79486.74890000001, -1344.786906, 8.309986459999999, -0.0002220105361, 1.753683113e-008, 2.545998719e-012, -2.645649117e-016}, bhigh = {102318.7495, -22.5979394}, R_s = R_NASA_2002/CCN.MM);
          constant IdealGases.Common.DataRecord CNC(name = "CNC", MM = 0.0380281, Hf = 18010748.86728498, H0 = 298637.3497492644, Tlimit = 1000, alow = {-70751.9271, 1007.523898, -1.576789967, 0.02052532634, -2.278935009e-005, 1.283362343e-008, -2.933174091e-012}, blow = {76133.2485, 34.87094132}, ahigh = {-90313.13559999999, -831.32365, 8.11473595, -0.0002447691991, 5.39750877e-008, -6.18398486e-012, 2.865172411e-016}, bhigh = {84518.33600000001, -21.02937255}, R_s = R_NASA_2002/CNC.MM);
          constant IdealGases.Common.DataRecord OCCN(name = "OCCN", MM = 0.05402754, Hf = 3886906.566539954, H0 = 251618.9150940428, Tlimit = 1000, alow = {24288.01276, -552.586462, 8.58783817, -0.00337938777, 1.119841826e-005, -1.008408077e-008, 3.086448824e-012}, blow = {25996.20072, -16.59592359}, ahigh = {935913.1680000001, -4441.082289999999, 13.68959297, -0.001647530917, 3.81987344e-007, -3.945161e-011, 1.509598839e-015}, bhigh = {49512.2278, -54.1708968}, R_s = R_NASA_2002/OCCN.MM);
          constant IdealGases.Common.DataRecord C2N2(name = "C2N2", MM = 0.0520348, Hf = 5940255.367561709, H0 = 244358.6407558019, Tlimit = 1000, alow = {108240.4484, -1928.137871, 15.53891898, -0.01821159329, 2.77884084e-005, -1.899434373e-008, 4.94967772e-012}, blow = {44490.9759, -60.90964741}, ahigh = {793442.372, -3997.37627, 13.1449743, -0.0008747782000000001, 2.059156733e-007, -2.200469389e-011, 9.97448577e-016}, bhigh = {58636.323, -54.73201251}, R_s = R_NASA_2002/C2N2.MM);
          constant IdealGases.Common.DataRecord C2O(name = "C2O", MM = 0.0400208, Hf = 7272185.113740855, H0 = 262006.7065126135, Tlimit = 1000, alow = {-3959.92942, -111.7516348, 4.59396006, 0.00371060202, -7.01476018e-007, -1.371129839e-009, 7.123853999999999e-013}, blow = {34101.0974, 0.4622805600000001}, ahigh = {-634805.659, 1184.133091, 4.87917334, 0.001757538773, -3.95755227e-007, 3.98917994e-011, -1.546043135e-015}, bhigh = {24898.03938, 0.980904059}, R_s = R_NASA_2002/C2O.MM);
          constant IdealGases.Common.DataRecord C3(name = "C3", MM = 0.0360321, Hf = 23311121.08370037, H0 = 336065.5082551392, Tlimit = 1000, alow = {-43546.1448, 666.018322, 1.451033157, 0.00743451312, -3.81015299e-006, -2.336961396e-011, 4.40705453e-013}, blow = {96351.70199999999, 20.25173297}, ahigh = {4508098.93, -14610.33761, 22.81974644, -0.008544340610000001, 2.146069341e-006, -2.103867761e-010, 6.351589060000001e-015}, bhigh = {191197.6065, -127.1869723}, R_s = R_NASA_2002/C3.MM);
          constant IdealGases.Common.DataRecord C3H3_1_propynl(name = "C3H3_1_propynl", MM = 0.03905592, Hf = 11521940.84789195, H0 = 317493.4811419114, Tlimit = 1000, alow = {-65058.5935, 1350.858921, -5.82543393, 0.0375661048, -3.73490334e-005, 2.117676603e-008, -5.139113250000001e-012}, blow = {46565.1053, 57.8147755}, ahigh = {4550654.87, -16405.74172, 27.12605991, -0.00447460038, 1.037712415e-006, -1.250211369e-010, 6.02658205e-015}, bhigh = {153408.7662, -156.5931809}, R_s = R_NASA_2002/C3H3_1_propynl.MM);
          constant IdealGases.Common.DataRecord C3H3_2_propynl(name = "C3H3_2_propynl", MM = 0.03905592, Hf = 8495511.051845662, H0 = 338745.0609280232, Tlimit = 1000, alow = {61885.78320000001, -890.957867, 6.34755882, 0.01633173115, -1.949975695e-005, 1.417349778e-008, -4.19986632e-012}, blow = {42717.8583, -12.31400729}, ahigh = {2989723.833, -11189.54446, 22.22225052, -0.002068106902, 4.12188364e-007, -4.43898059e-011, 1.970824701e-015}, bhigh = {106187.8289, -118.6744583}, R_s = R_NASA_2002/C3H3_2_propynl.MM);
          constant IdealGases.Common.DataRecord C3H4_allene(name = "C3H4_allene", MM = 0.04006386, Hf = 4765392.051589637, H0 = 314611.9470265721, Tlimit = 1000, alow = {-16451.55745, 962.945781, -7.53232668, 0.05518219110000001, -6.73358512e-005, 4.53270905e-008, -1.251837614e-011}, blow = {17724.94269, 61.5196976}, ahigh = {3479355.1, -14304.12453, 27.02534756, -0.002557412369, 4.70664675e-007, -4.65168807e-011, 1.908219044e-015}, bhigh = {107231.2354, -154.8846158}, R_s = R_NASA_2002/C3H4_allene.MM);
          constant IdealGases.Common.DataRecord C3H4_propyne(name = "C3H4_propyne", MM = 0.04006386, Hf = 4615131.941854829, H0 = 325243.6485151456, Tlimit = 1000, alow = {-35638.844, 832.81391, -4.07375944, 0.04113929609999999, -4.47044495e-005, 2.847458197e-008, -7.69529824e-012}, blow = {17102.06236, 45.1672095}, ahigh = {3710441.42, -14891.45507, 27.32397127, -0.00264526477, 4.858300350000001e-007, -4.79412848e-011, 1.964338121e-015}, bhigh = {110489.8462, -156.7992462}, R_s = R_NASA_2002/C3H4_propyne.MM);
          constant IdealGases.Common.DataRecord C3H4_cyclo(name = "C3H4_cyclo", MM = 0.04006386, Hf = 6916457.875002559, H0 = 283888.3472536096, Tlimit = 1000, alow = {-19695.20627, 1505.379338, -14.18206573, 0.07642632960000001, -9.765583660000001e-005, 6.61200382e-008, -1.811251145e-011}, blow = {26256.31782, 96.0463189}, ahigh = {3168399.58, -13710.44699, 26.64303646, -0.00242040805, 4.42799413e-007, -4.3518202e-011, 1.775948955e-015}, bhigh = {113368.3702, -152.2619086}, R_s = R_NASA_2002/C3H4_cyclo.MM);
          constant IdealGases.Common.DataRecord C3H5_allyl(name = "C3H5_allyl", MM = 0.04107180000000001, Hf = 3983131.97863254, H0 = 310157.4072721429, Tlimit = 1000, alow = {-43159.9614, 1441.600907, -11.97014426, 0.0731979646, -9.066357849999999e-005, 6.077059450000001e-008, -1.658826363e-011}, blow = {12321.5746, 85.63173239999999}, ahigh = {4094570.59, -16766.76186, 31.23006342, -0.002885449982, 5.21134354e-007, -5.05828422e-011, 2.039932554e-015}, bhigh = {118572.0481, -182.3070197}, R_s = R_NASA_2002/C3H5_allyl.MM);
          constant IdealGases.Common.DataRecord C3H6_propylene(name = "C3H6_propylene", MM = 0.04207974, Hf = 475288.1077687267, H0 = 322020.9535515191, Tlimit = 1000, alow = {-191246.2174, 3542.07424, -21.14878626, 0.0890148479, -0.0001001429154, 6.267959389999999e-008, -1.637870781e-011}, blow = {-15299.61824, 140.7641382}, ahigh = {5017620.34, -20860.84035, 36.4415634, -0.00388119117, 7.27867719e-007, -7.321204500000001e-011, 3.052176369e-015}, bhigh = {126124.5355, -219.5715757}, R_s = R_NASA_2002/C3H6_propylene.MM);
          constant IdealGases.Common.DataRecord C3H6_cyclo(name = "C3H6_cyclo", MM = 0.04207974, Hf = 1266642.807203657, H0 = 271151.4139583562, Tlimit = 1000, alow = {-156578.777, 4111.12987, -32.3344746, 0.1306337881, -0.0001645563833, 1.095708326e-007, -2.956394783e-011}, blow = {-12452.71686, 193.1559109}, ahigh = {4785000.67, -20421.18175, 36.3149578, -0.00356131944, 6.47624124e-007, -6.328430100000001e-011, 2.568705857e-015}, bhigh = {126827.4126, -222.3729099}, R_s = R_NASA_2002/C3H6_cyclo.MM);
          constant IdealGases.Common.DataRecord C3H6O_propylox(name = "C3H6O_propylox", MM = 0.05807914, Hf = -1613660.25736607, H0 = 248031.4446804825, Tlimit = 1000, alow = {-229280.8804, 4495.75054, -29.41117945, 0.1213113827, -0.0001440060464, 9.202051750000001e-008, -2.416278343e-011}, blow = {-33176.9721, 184.6878218}, ahigh = {4789729.989999999, -21068.95971, 39.5464773, -0.00391092998, 7.32553151e-007, -7.35708597e-011, 3.0606185e-015}, bhigh = {112034.454, -237.2004192}, R_s = R_NASA_2002/C3H6O_propylox.MM);
          constant IdealGases.Common.DataRecord C3H6O_acetone(name = "C3H6O_acetone", MM = 0.05807914, Hf = -3738857.014756073, H0 = 278812.5478442002, Tlimit = 1000, alow = {-227780.2525, 4215.28001, -24.15785316, 0.0990748332, -0.0001084940903, 6.583355959999999e-008, -1.676046146e-011}, blow = {-47262.4394, 160.7926432}, ahigh = {5001601.92, -21701.55542, 39.6449399, -0.00417994505, 7.96242953e-007, -8.122558050000001e-011, 3.42878096e-015}, bhigh = {101514.5028, -236.8533477}, R_s = R_NASA_2002/C3H6O_acetone.MM);
          constant IdealGases.Common.DataRecord C3H6O_propanal(name = "C3H6O_propanal", MM = 0.05807914, Hf = -3202526.759177219, H0 = 298339.0594282216, Tlimit = 1000, alow = {-265578.1702, 4250.64045, -21.09249262, 0.09194256120000001, -0.0001004653044, 6.13331482e-008, -1.576298535e-011}, blow = {-44503.7105, 145.6678605}, ahigh = {4830933.489999999, -20754.51152, 39.2485518, -0.004095514, 7.88169216e-007, -8.107684080000001e-011, 3.43710543e-015}, bhigh = {99449.37879999999, -231.6690627}, R_s = R_NASA_2002/C3H6O_propanal.MM);
          constant IdealGases.Common.DataRecord C3H7_n_propyl(name = "C3H7_n_propyl", MM = 0.04308768, Hf = 2332453.267384088, H0 = 344879.5108021598, Tlimit = 1000, alow = {-189533.7073, 3949.51726, -26.06216089, 0.1121920441, -0.0001365292213, 9.02366272e-008, -2.44105699e-011}, blow = {-7227.87744, 167.3705556}, ahigh = {5646512.94, -22910.87136, 39.8727518, -0.004106232870000001, 7.56255777e-007, -7.47826302e-011, 3.068983677e-015}, bhigh = {148300.6853, -240.378119}, R_s = R_NASA_2002/C3H7_n_propyl.MM);
          constant IdealGases.Common.DataRecord C3H7_i_propyl(name = "C3H7_i_propyl", MM = 0.04308768, Hf = 2165352.137780452, H0 = 343652.9188853984, Tlimit = 1000, alow = {-295206.3445, 5294.4323, -31.05287013, 0.1143871563, -0.0001291752393, 8.05784376e-008, -2.093908432e-011}, blow = {-14768.15514, 198.808236}, ahigh = {5807002.520000001, -24112.19997, 40.852884, -0.00451785133, 8.499427170000001e-007, -8.573514339999999e-011, 3.58338396e-015}, bhigh = {154650.405, -248.7098372}, R_s = R_NASA_2002/C3H7_i_propyl.MM);
          constant IdealGases.Common.DataRecord C3H8(name = "C3H8", MM = 0.04409562, Hf = -2373931.923397381, H0 = 334301.1845620949, Tlimit = 1000, alow = {-243314.4337, 4656.27081, -29.39466091, 0.1188952745, -0.0001376308269, 8.814823909999999e-008, -2.342987994e-011}, blow = {-35403.3527, 184.1749277}, ahigh = {6420731.680000001, -26597.91134, 45.3435684, -0.00502066392, 9.471216939999999e-007, -9.57540523e-011, 4.00967288e-015}, bhigh = {145558.2459, -281.8374734}, R_s = R_NASA_2002/C3H8.MM);
          constant IdealGases.Common.DataRecord C3H8O_1propanol(name = "C3H8O_1propanol", MM = 0.06009502, Hf = -4246608.121604752, H0 = 291517.6498818038, Tlimit = 1000, alow = {-261697.3337, 5192.37666, -32.9648116, 0.1354568128, -0.0001593156164, 1.01949816e-007, -2.688552974e-011}, blow = {-56128.5435, 208.5024431}, ahigh = {6308672.12, -26422.10376, 47.1511259, -0.004642511930000001, 8.59346536e-007, -8.68209182e-011, 3.64222401e-015}, bhigh = {125500.3155, -285.9463804}, R_s = R_NASA_2002/C3H8O_1propanol.MM);
          constant IdealGases.Common.DataRecord C3H8O_2propanol(name = "C3H8O_2propanol", MM = 0.06009502, Hf = -4537813.615837053, H0 = 287291.2763819697, Tlimit = 1000, alow = {-338651.024, 6106.048000000001, -37.9141804, 0.1530494531, -0.0001864354461, 1.213257738e-007, -3.22043349e-011}, blow = {-62799.5935, 233.432261}, ahigh = {6001074.75, -25058.7683, 46.22096120000001, -0.00427246631, 7.69367877e-007, -7.45058484e-011, 2.998959935e-015}, bhigh = {114851.8732, -279.6132222}, R_s = R_NASA_2002/C3H8O_2propanol.MM);
          constant IdealGases.Common.DataRecord CNCOCN(name = "CNCOCN", MM = 0.08004498, Hf = 3092011.516524834, H0 = 214226.5261356802, Tlimit = 1000, alow = {113105.2075, -1978.834961, 16.26886206, -0.008330803440000001, 1.884127045e-005, -1.530681289e-008, 4.4181253e-012}, blow = {36802.6174, -59.6332728}, ahigh = {700052.2440000001, -5086.002009999999, 19.4675349, -0.001302852727, 2.75360075e-007, -3.056290852e-011, 1.382140838e-015}, bhigh = {55393.3888, -86.2755086}, R_s = R_NASA_2002/CNCOCN.MM);
          constant IdealGases.Common.DataRecord C3O2(name = "C3O2", MM = 0.06803090000000001, Hf = -1376403.957613379, H0 = 221737.2252902725, Tlimit = 1000, alow = {157987.3382, -2529.493506, 18.01761578, -0.01786032042, 2.978671986e-005, -2.182900022e-008, 6.013797219999999e-012}, blow = {-1121.054014, -72.77721170000001}, ahigh = {696869.9889999999, -4624.73319, 16.63905725, -0.001175486554, 2.478106444e-007, -2.745165984e-011, 1.239566766e-015}, bhigh = {12525.80069, -72.75968780000001}, R_s = R_NASA_2002/C3O2.MM);
          constant IdealGases.Common.DataRecord C4(name = "C4", MM = 0.0480428, Hf = 21520472.20395147, H0 = 273042.8284779405, Tlimit = 1000, alow = {39037.805, -894.8280779999999, 10.50952925, -0.00655289446, 1.243940464e-005, -8.645341370000001e-009, 2.263638846e-012}, blow = {126642.5869, -30.77594475}, ahigh = {920068.513, -1530.3118, 6.0500692, 0.00525274367, -1.779154772e-006, 2.589873632e-010, -1.385553481e-014}, bhigh = {133438.9611, -7.26114882}, R_s = R_NASA_2002/C4.MM);
          constant IdealGases.Common.DataRecord C4H2_butadiyne(name = "C4H2_butadiyne", MM = 0.05005868, Hf = 8989449.98150171, H0 = 287539.743357196, Tlimit = 1000, alow = {246754.2569, -3897.85564, 23.66080456, -0.02208077805, 2.78110114e-005, -1.57734001e-008, 3.42316546e-012}, blow = {70869.0782, -110.917356}, ahigh = {2328179.913, -8925.186090000001, 21.14326883, -0.001368871276, 2.327503159e-007, -2.124517624e-011, 8.053313019999999e-016}, bhigh = {105778.8416, -108.8313574}, R_s = R_NASA_2002/C4H2_butadiyne.MM);
          constant IdealGases.Common.DataRecord C4H4_1_3minuscyclo(name = "C4H4_1_3minuscyclo", MM = 0.05207456, Hf = 7393245.377397331, H0 = 232427.0046640816, Tlimit = 1000, alow = {-27784.28049, 1768.176915, -17.57895171, 0.09383512919999999, -0.0001195524281, 7.97808619e-008, -2.1527511e-011}, blow = {38116.2712, 112.8478124}, ahigh = {2991498.949, -14167.81502, 30.01978876, -0.002579200423, 4.78999045e-007, -4.77532971e-011, 1.974923662e-015}, bhigh = {127466.692, -172.7532057}, R_s = R_NASA_2002/C4H4_1_3minuscyclo.MM);
          constant IdealGases.Common.DataRecord C4H6_butadiene(name = "C4H6_butadiene", MM = 0.05409044, Hf = 2033631.081573749, H0 = 279716.7114928257, Tlimit = 1000, alow = {-91811.30530000001, 3312.57053, -29.85828611, 0.1479201147, -0.0002056618326, 1.466496826e-007, -4.14528573e-011}, blow = {-2077.309444, 178.0687329}, ahigh = {-23619031.88, 56513.2337, -32.7573832, 0.02293070572, -2.297106441e-006, 4.29259621e-011, 4.23676604e-015}, bhigh = {-367135.862, 301.3437302}, R_s = R_NASA_2002/C4H6_butadiene.MM);
          constant IdealGases.Common.DataRecord C4H6_1butyne(name = "C4H6_1butyne", MM = 0.05409044, Hf = 3054144.133418031, H0 = 296170.635698286, Tlimit = 1000, alow = {-55970.3997, 1433.191711, -9.691210720000001, 0.0715000239, -8.1579678e-005, 5.29036497e-008, -1.435655372e-011}, blow = {11849.87013, 76.6022536}, ahigh = {6364402.7, -23920.87731, 40.7375041, -0.00317672649, 1.199856984e-007, 3.20180251e-011, -2.854392633e-015}, bhigh = {163433.5546, -246.0284791}, R_s = R_NASA_2002/C4H6_1butyne.MM);
          constant IdealGases.Common.DataRecord C4H6_2butyne(name = "C4H6_2butyne", MM = 0.05409044, Hf = 2693636.805320866, H0 = 307632.9199762472, Tlimit = 1000, alow = {-265075.6405, 4490.72869, -24.00723889, 0.0981957955, -0.0001079717182, 6.675555770000001e-008, -1.740766886e-011}, blow = {-5328.36371, 159.5035268}, ahigh = {3981304.33, -18730.32899, 36.5456149, -0.002369686378, 3.99021181e-007, -3.69870727e-011, 1.442072006e-015}, bhigh = {126146.0214, -215.5866205}, R_s = R_NASA_2002/C4H6_2butyne.MM);
          constant IdealGases.Common.DataRecord C4H6_cyclo(name = "C4H6_cyclo", MM = 0.05409044, Hf = 2896999.913478241, H0 = 232158.6587204689, Tlimit = 1000, alow = {-204670.7734, 4919.47057, -37.5327816, 0.1497293031, -0.0001860139375, 1.219909019e-007, -3.25407359e-011}, blow = {-3915.95054, 223.3282138}, ahigh = {4517367.819999999, -20973.11985, 40.0803917, -0.00394979398, 7.44848499e-007, -7.52975417e-011, 3.153253502e-015}, bhigh = {140646.9848, -243.4836999}, R_s = R_NASA_2002/C4H6_cyclo.MM);
          constant IdealGases.Common.DataRecord C4H8_1_butene(name = "C4H8_1_butene", MM = 0.05610631999999999, Hf = -9624.584182316718, H0 = 305134.9651875226, Tlimit = 1000, alow = {-272149.2014, 5100.079250000001, -31.8378625, 0.1317754442, -0.0001527359339, 9.714761109999999e-008, -2.56020447e-011}, blow = {-25230.96386, 200.6932108}, ahigh = {6257948.609999999, -26603.76305, 47.6492005, -0.00438326711, 7.12883844e-007, -5.991020839999999e-011, 2.051753504e-015}, bhigh = {156925.2657, -291.3869761}, R_s = R_NASA_2002/C4H8_1_butene.MM);
          constant IdealGases.Common.DataRecord C4H8_cis2_buten(name = "C4H8_cis2_buten", MM = 0.05610631999999999, Hf = -131892.4499058217, H0 = 299431.5078942979, Tlimit = 1000, alow = {-277387.0877, 5382.38404, -33.751881, 0.1322980623, -0.0001490975922, 9.277722e-008, -2.408282948e-011}, blow = {-27158.84347, 211.4462085}, ahigh = {6461018.35, -27753.76432, 48.6353236, -0.00486238635, 8.412626100000001e-007, -7.63389037e-011, 2.861702826e-015}, bhigh = {163085.6187, -300.3105998}, R_s = R_NASA_2002/C4H8_cis2_buten.MM);
          constant IdealGases.Common.DataRecord C4H8_isobutene(name = "C4H8_isobutene", MM = 0.05610631999999999, Hf = -304778.4991066961, H0 = 303174.4017429766, Tlimit = 1000, alow = {-232720.5032, 3941.99424, -22.24581184, 0.1012790864, -0.0001073194065, 6.45469691e-008, -1.646330345e-011}, blow = {-22337.66063, 147.9597621}, ahigh = {6484970.99, -27325.04764, 48.3632108, -0.00476800405, 8.23387584e-007, -7.449252999999999e-011, 2.782303056e-015}, bhigh = {159594.1773, -298.2986237}, R_s = R_NASA_2002/C4H8_isobutene.MM);
          constant IdealGases.Common.DataRecord C4H8_cyclo(name = "C4H8_cyclo", MM = 0.05610631999999999, Hf = 506181.8347736941, H0 = 241223.5020938818, Tlimit = 1000, alow = {-304765.5983, 6519.48273, -46.6298759, 0.1743593052, -0.0002090964176, 1.343528679e-007, -3.5427274e-011}, blow = {-27000.31171, 273.8348195}, ahigh = {4456213.810000001, -23010.18492, 44.9244846, -0.003080145176, 5.317165260000001e-007, -5.08107938e-011, 2.048919092e-015}, bhigh = {135548.7603, -277.1801965}, R_s = R_NASA_2002/C4H8_cyclo.MM);
          constant IdealGases.Common.DataRecord C4H9_n_butyl(name = "C4H9_n_butyl", MM = 0.05711426, Hf = 1164857.95316266, H0 = 346620.9664626662, Tlimit = 1000, alow = {-223956.0407, 4676.554099999999, -29.85424449, 0.1345493704, -0.000160066035, 1.045338096e-007, -2.812951048e-011}, blow = {-15252.97704, 190.1651559}, ahigh = {7198686.94, -29592.41524, 52.4204281, -0.00544157244, 9.917758369999999e-007, -9.464455870000001e-011, 3.72948704e-015}, bhigh = {183456.6472, -321.420917}, R_s = R_NASA_2002/C4H9_n_butyl.MM);
          constant IdealGases.Common.DataRecord C4H9_i_butyl(name = "C4H9_i_butyl", MM = 0.05711426, Hf = 1003602.252747387, H0 = 320707.9983177581, Tlimit = 1000, alow = {-239946.1281, 4697.44454, -30.8747256, 0.1391655831, -0.0001670233968, 1.092423088e-007, -2.936209962e-011}, blow = {-16381.51036, 193.6662372}, ahigh = {6752936.06, -28374.23721, 51.4068761, -0.00498239901, 8.80150663e-007, -8.12573869e-011, 3.099140009e-015}, bhigh = {174344.848, -314.9940745}, R_s = R_NASA_2002/C4H9_i_butyl.MM);
          constant IdealGases.Common.DataRecord C4H9_s_butyl(name = "C4H9_s_butyl", MM = 0.05711426, Hf = 1243122.120465187, H0 = 307062.5269416079, Tlimit = 1000, alow = {-335106.289, 6312.945949999999, -40.0302526, 0.1563875047, -0.0001842331788, 1.182727848e-007, -3.131156589e-011}, blow = {-22160.45659, 248.1295714}, ahigh = {7224744.35, -30352.91099, 52.8855183, -0.00565208355, 1.060032692e-006, -1.066129835e-010, 4.443810960000001e-015}, bhigh = {188349.4279, -325.571988}, R_s = R_NASA_2002/C4H9_s_butyl.MM);
          constant IdealGases.Common.DataRecord C4H9_t_butyl(name = "C4H9_t_butyl", MM = 0.05711426, Hf = 905203.0088457768, H0 = 297818.3556961081, Tlimit = 1000, alow = {-472346.195, 8090.198770000001, -46.8367534, 0.1575300095, -0.0001686559436, 9.98104013e-008, -2.487608823e-011}, blow = {-33193.6741, 289.4838706}, ahigh = {7151064.95, -31712.2441, 54.4251032, -0.006392331160000001, 1.241097612e-006, -1.2872483e-010, 5.51261874e-015}, bhigh = {193450.6997, -339.9325290000001}, R_s = R_NASA_2002/C4H9_t_butyl.MM);
          constant IdealGases.Common.DataRecord C4H10_n_butane(name = "C4H10_n_butane", MM = 0.0581222, Hf = -2164233.28779709, H0 = 330832.0228759407, Tlimit = 1000, alow = {-317587.254, 6176.331819999999, -38.9156212, 0.1584654284, -0.0001860050159, 1.199676349e-007, -3.20167055e-011}, blow = {-45403.63390000001, 237.9488665}, ahigh = {7682322.45, -32560.5151, 57.3673275, -0.00619791681, 1.180186048e-006, -1.221893698e-010, 5.250635250000001e-015}, bhigh = {177452.656, -358.791876}, R_s = R_NASA_2002/C4H10_n_butane.MM);
          constant IdealGases.Common.DataRecord C4H10_isobutane(name = "C4H10_isobutane", MM = 0.0581222, Hf = -2322520.482707124, H0 = 308599.8121199817, Tlimit = 1000, alow = {-383446.933, 7000.03964, -44.400269, 0.1746183447, -0.0002078195348, 1.339792433e-007, -3.55168163e-011}, blow = {-50340.18889999999, 265.8966497}, ahigh = {7528018.92, -32025.1706, 57.00161, -0.00606001309, 1.143975809e-006, -1.157061835e-010, 4.84604291e-015}, bhigh = {172850.0802, -357.617689}, R_s = R_NASA_2002/C4H10_isobutane.MM);
          constant IdealGases.Common.DataRecord C4N2(name = "C4N2", MM = 0.0760562, Hf = 6958012.627504397, H0 = 234029.5860166561, Tlimit = 1000, alow = {158780.2866, -2987.184206, 23.48081602, -0.02607502448, 4.04283003e-005, -2.804912444e-008, 7.39765205e-012}, blow = {75052.9947, -101.757825}, ahigh = {1167686.152, -6198.644179999999, 20.62070093, -0.001518619449, 3.16236168e-007, -3.4699228e-011, 1.555154128e-015}, bhigh = {96674.09389999999, -96.69734738000001}, R_s = R_NASA_2002/C4N2.MM);
          constant IdealGases.Common.DataRecord C5(name = "C5", MM = 0.0600535, Hf = 17499801.5436236, H0 = 269623.4357697719, Tlimit = 1000, alow = {-12008.01119, -555.3702910000001, 11.23828271, -0.00434788452, 1.73898749e-005, -1.707945418e-008, 5.57454191e-012}, blow = {126240.4627, -32.6230899}, ahigh = {217205.5356, -2958.510027, 15.61080967, -0.0008200361920000001, 1.776898025e-007, -2.009853583e-011, 9.222677770000001e-016}, bhigh = {139520.8064, -64.33077179999999}, R_s = R_NASA_2002/C5.MM);
          constant IdealGases.Common.DataRecord C5H6_1_3cyclo(name = "C5H6_1_3cyclo", MM = 0.06610114, Hf = 2031735.004872836, H0 = 204769.9782484841, Tlimit = 1000, alow = {-188625.9728, 4738.22087, -38.8895801, 0.1667438533, -0.0002141149581, 1.438132328e-007, -3.90647811e-011}, blow = {-5667.022010000001, 227.9898557}, ahigh = {4428478.19, -21235.47976, 43.0981901, -0.003914783460000001, 7.31184701e-007, -7.32724119e-011, 3.044403403e-015}, bhigh = {138254.2782, -260.5959678}, R_s = R_NASA_2002/C5H6_1_3cyclo.MM);
          constant IdealGases.Common.DataRecord C5H8_cyclo(name = "C5H8_cyclo", MM = 0.06811702, Hf = 497672.9751242788, H0 = 218112.5803800577, Tlimit = 1000, alow = {-263111.4588, 5987.75349, -45.222446, 0.1804626339, -0.0002177216062, 1.402022671e-007, -3.6990943e-011}, blow = {-23795.04749, 266.0136401}, ahigh = {4569848.1, -24060.18294, 48.8100646, -0.00341305498, 6.04700166e-007, -5.927495780000001e-011, 2.44786539e-015}, bhigh = {141398.3093, -298.9533527}, R_s = R_NASA_2002/C5H8_cyclo.MM);
          constant IdealGases.Common.DataRecord C5H10_1_pentene(name = "C5H10_1_pentene", MM = 0.07013290000000001, Hf = -303423.9279995551, H0 = 309127.3852927798, Tlimit = 1000, alow = {-534054.813, 9298.917380000001, -56.6779245, 0.2123100266, -0.000257129829, 1.666834304e-007, -4.43408047e-011}, blow = {-47906.8218, 339.60364}, ahigh = {3744014.97, -21044.85321, 47.3612699, -0.00042442012, -3.89897505e-008, 1.367074243e-011, -9.31319423e-016}, bhigh = {115409.1373, -278.6177449000001}, R_s = R_NASA_2002/C5H10_1_pentene.MM);
          constant IdealGases.Common.DataRecord C5H10_cyclo(name = "C5H10_cyclo", MM = 0.07013290000000001, Hf = -1099341.393269065, H0 = 214212.4024530569, Tlimit = 1000, alow = {-414111.971, 8627.5928, -62.0295998, 0.2259910921, -0.000268230333, 1.706289935e-007, -4.46405092e-011}, blow = {-49315.2214, 358.391623}, ahigh = {7501938.73, -35058.6485, 63.2248075, -0.00694035658, 1.337306593e-006, -1.377905033e-010, 5.86735764e-015}, bhigh = {195492.5511, -402.65509}, R_s = R_NASA_2002/C5H10_cyclo.MM);
          constant IdealGases.Common.DataRecord C5H11_pentyl(name = "C5H11_pentyl", MM = 0.07114084, Hf = 643933.9203754131, H0 = 343290.8579656918, Tlimit = 1000, alow = {-465371.592, 8564.22042, -52.9524289, 0.2094288859, -0.0002561602906, 1.692755961e-007, -4.596788110000001e-011}, blow = {-36417.0427, 319.686224}, ahigh = {5697252.899999999, -28917.06175, 58.1102968, -0.00359399501, 4.41996763e-007, -1.509664551e-011, -6.62696443e-016}, bhigh = {171700.955, -352.247712}, R_s = R_NASA_2002/C5H11_pentyl.MM);
          constant IdealGases.Common.DataRecord C5H11_t_pentyl(name = "C5H11_t_pentyl", MM = 0.07114084, Hf = 458245.9245631623, H0 = 276124.417423241, Tlimit = 1000, alow = {-515218.198, 9144.32783, -56.0239789, 0.1998204194, -0.0002239112591, 1.375455547e-007, -3.52383305e-011}, blow = {-40362.6661, 340.2811}, ahigh = {8602108.26, -38052.05770000001, 66.4969037, -0.007533860630000001, 1.451612787e-006, -1.495593207e-010, 6.368022329999999e-015}, bhigh = {228185.8805, -416.940855}, R_s = R_NASA_2002/C5H11_t_pentyl.MM);
          constant IdealGases.Common.DataRecord C5H12_n_pentane(name = "C5H12_n_pentane", MM = 0.07214878, Hf = -2034130.029641527, H0 = 335196.2430965569, Tlimit = 1000, alow = {-276889.4625, 5834.28347, -36.1754148, 0.1533339707, -0.0001528395882, 8.191092e-008, -1.792327902e-011}, blow = {-46653.7525, 226.5544053}, ahigh = {-2530779.286, -8972.59326, 45.3622326, -0.002626989916, 3.135136419e-006, -5.31872894e-010, 2.886896868e-014}, bhigh = {14846.16529, -251.6550384}, R_s = R_NASA_2002/C5H12_n_pentane.MM);
          constant IdealGases.Common.DataRecord C5H12_i_pentane(name = "C5H12_i_pentane", MM = 0.07214878, Hf = -2130320.152329672, H0 = 305036.3429568733, Tlimit = 1000, alow = {-423190.339, 6497.1891, -36.8112697, 0.1532424729, -0.0001548790714, 8.74989712e-008, -2.07054771e-011}, blow = {-51554.1659, 230.9518218}, ahigh = {11568885.94, -45562.4687, 74.9544363, -0.007845415580000001, 1.444393314e-006, -1.464370213e-010, 6.230285000000001e-015}, bhigh = {254492.7135, -480.198578}, R_s = R_NASA_2002/C5H12_i_pentane.MM);
          constant IdealGases.Common.DataRecord CH3C_CH3_2CH3(name = "CH3C_CH3_2CH3", MM = 0.07214878, Hf = -2327412.882102788, H0 = 321266.6936294696, Tlimit = 1000, alow = {-8973222.270000001, 128922.5617, -719.934483, 2.056862183, -0.002953159699, 2.158893146e-006, -6.26831877e-010}, blow = {-639493.2019999999, 4020.80636}, ahigh = {16847055.2, -59794.3057, 86.85451479999999, -0.0096219176, 1.653363091e-006, -1.674727926e-010, 7.37211936e-015}, bhigh = {345849.682, -576.046697}, R_s = R_NASA_2002/CH3C_CH3_2CH3.MM);
          constant IdealGases.Common.DataRecord C6D5_phenyl(name = "C6D5_phenyl", MM = 0.08213471, Hf = 3844172.579412528, H0 = 193816.6823746014, Tlimit = 1000, alow = {201283.7008, -1979.349332, 2.6282675, 0.0595186526, -6.08128045e-005, 3.38139165e-008, -8.125429080000001e-012}, blow = {46972.47489999999, 0.335470098}, ahigh = {1411628.125, -13625.69472, 40.2898494, -0.00349098927, 7.37961213e-007, -8.19224405e-011, 3.70533097e-015}, bhigh = {108807.3731, -229.3621057}, R_s = R_NASA_2002/C6D5_phenyl.MM);
          constant IdealGases.Common.DataRecord C6D6(name = "C6D6", MM = 0.084148812, Hf = 691125.3601536288, H0 = 193997.8190066427, Tlimit = 1000, alow = {276291.1236, -2865.868902, 5.39507043, 0.05939315170000001, -6.02363118e-005, 3.38139857e-008, -8.306046370000001e-012}, blow = {20470.83778, -20.11790696}, ahigh = {1758057.871, -15721.21558, 44.6816249, -0.004003361919999999, 8.4454344e-007, -9.36055698e-011, 4.22847553e-015}, bhigh = {89620.45359999999, -261.5332268}, R_s = R_NASA_2002/C6D6.MM);
          constant IdealGases.Common.DataRecord C6H2(name = "C6H2", MM = 0.07408007999999999, Hf = 9044266.690856706, H0 = 264682.6785284249, Tlimit = 1000, alow = {290372.2964, -4929.7515, 31.8932321, -0.03119447315, 4.32576368e-005, -2.732517022e-008, 6.67444611e-012}, blow = {101189.8682, -153.0593012}, ahigh = {2592848.577, -10833.61978, 28.47459495, -0.001876727704, 3.41213428e-007, -3.33739289e-011, 1.356853889e-015}, bhigh = {141851.7294, -149.4853494}, R_s = R_NASA_2002/C6H2.MM);
          constant IdealGases.Common.DataRecord C6H5_phenyl(name = "C6H5_phenyl", MM = 0.07710389999999999, Hf = 4373319.637528064, H0 = 183578.6905720723, Tlimit = 1000, alow = {-121127.8245, 3529.04558, -31.16903422, 0.146755063, -0.0001831398296, 1.192576957e-007, -3.14926586e-011}, blow = {24209.72928, 186.8799946}, ahigh = {3670279.23, -18946.01209, 41.8058182, -0.00350391415, 6.56182174e-007, -6.594714449999999e-011, 2.748094212e-015}, bhigh = {147674.4628, -247.5301142}, R_s = R_NASA_2002/C6H5_phenyl.MM);
          constant IdealGases.Common.DataRecord C6H5O_phenoxy(name = "C6H5O_phenoxy", MM = 0.0931033, Hf = 512334.1492729044, H0 = 174087.2128055611, Tlimit = 1000, alow = {-129226.4217, 3406.74068, -29.11367361, 0.1459180378, -0.0001780202758, 1.138615885e-007, -2.967142152e-011}, blow = {-10550.26758, 177.0682011}, ahigh = {3678640.34, -19729.80806, 45.4118441, -0.00375106439, 7.11445078e-007, -7.233328850000001e-011, 3.045637067e-015}, bhigh = {116359.5961, -268.1058539}, R_s = R_NASA_2002/C6H5O_phenoxy.MM);
          constant IdealGases.Common.DataRecord C6H6(name = "C6H6", MM = 0.07811184, Hf = 1061042.730525872, H0 = 181735.4577743912, Tlimit = 1000, alow = {-167734.0902, 4404.50004, -37.1737791, 0.1640509559, -0.0002020812374, 1.307915264e-007, -3.4442841e-011}, blow = {-10354.55401, 216.9853345}, ahigh = {4538575.72, -22605.02547, 46.940073, -0.004206676830000001, 7.90799433e-007, -7.9683021e-011, 3.32821208e-015}, bhigh = {139146.4686, -286.8751333}, R_s = R_NASA_2002/C6H6.MM);
          constant IdealGases.Common.DataRecord C6H5OH_phenol(name = "C6H5OH_phenol", MM = 0.09411124, Hf = -1024309.104842312, H0 = 185915.0936700016, Tlimit = 1000, alow = {-120941.8144, 3378.29227, -29.91846148, 0.1567802942, -0.0001970937198, 1.291815064e-007, -3.42435126e-011}, blow = {-27793.87017, 179.9708977}, ahigh = {4462081.569999999, -21655.21026, 48.1501505, -0.00356828243, 6.32717573e-007, -6.039905720000001e-011, 2.399168678e-015}, bhigh = {111372.6204, -286.0454446}, R_s = R_NASA_2002/C6H5OH_phenol.MM);
          constant IdealGases.Common.DataRecord C6H10_cyclo(name = "C6H10_cyclo", MM = 0.08214360000000001, Hf = -55999.49356979728, H0 = 210251.1212072517, Tlimit = 1000, alow = {-375028.221, 7643.87675, -55.1043476, 0.2166231405, -0.0002545452198, 1.607607304e-007, -4.18524841e-011}, blow = {-36610.7301, 320.240946}, ahigh = {7510128.98, -35568.5821, 67.03034940000001, -0.00704535187, 1.3581664e-006, -1.400074492e-010, 5.964551700000001e-015}, bhigh = {206027.4332, -423.819766}, R_s = R_NASA_2002/C6H10_cyclo.MM);
          constant IdealGases.Common.DataRecord C6H12_1_hexene(name = "C6H12_1_hexene", MM = 0.08415948000000001, Hf = -498458.4030224521, H0 = 311788.9986962847, Tlimit = 1000, alow = {-666883.165, 11768.64939, -72.70998330000001, 0.2709398396, -0.00033332464, 2.182347097e-007, -5.85946882e-011}, blow = {-62157.8054, 428.682564}, ahigh = {733290.696, -14488.48641, 46.7121549, 0.00317297847, -5.24264652e-007, 4.28035582e-011, -1.472353254e-015}, bhigh = {66977.4041, -262.3643854}, R_s = R_NASA_2002/C6H12_1_hexene.MM);
          constant IdealGases.Common.DataRecord C6H12_cyclo(name = "C6H12_cyclo", MM = 0.08415948000000001, Hf = -1465075.5921971, H0 = 208471.0361803566, Tlimit = 1000, alow = {-567998.704, 10342.38704, -68.0004125, 0.2387797658, -0.0002511890049, 1.425293184e-007, -3.40783319e-011}, blow = {-64046.3516, 393.480821}, ahigh = {5225149.47, -33641.9458, 71.74607469999999, -0.006698979119999999, 1.318443254e-006, -1.390794789e-010, 6.06010224e-015}, bhigh = {173253.7609, -454.681417}, R_s = R_NASA_2002/C6H12_cyclo.MM);
          constant IdealGases.Common.DataRecord C6H13_n_hexyl(name = "C6H13_n_hexyl", MM = 0.08516742000000001, Hf = 294713.635801108, H0 = 340306.1875069128, Tlimit = 1000, alow = {-1427278.22, 22488.28093, -129.749224, 0.427979733, -0.000555601318, 3.79125694e-007, -1.048462404e-010}, blow = {-106026.1015, 749.718676}, ahigh = {5967938.62, -32990.2316, 68.6907344, -0.00422500906, 5.496523820000001e-007, -2.292851471e-011, -5.08634189e-016}, bhigh = {190697.8683, -418.5362}, R_s = R_NASA_2002/C6H13_n_hexyl.MM);
          constant IdealGases.Common.DataRecord C6H14_n_hexane(name = "C6H14_n_hexane", MM = 0.08617535999999999, Hf = -1936980.593988816, H0 = 333065.0431863586, Tlimit = 1000, alow = {-581592.67, 10790.97724, -66.3394703, 0.2523715155, -0.0002904344705, 1.802201514e-007, -4.617223680000001e-011}, blow = {-72715.4457, 393.828354}, ahigh = {-3106625.684, -7346.087920000001, 46.94131760000001, 0.001693963977, 2.068996667e-006, -4.21214168e-010, 2.452345845e-014}, bhigh = {523.750312, -254.9967718}, R_s = R_NASA_2002/C6H14_n_hexane.MM);
          constant IdealGases.Common.DataRecord C7H7_benzyl(name = "C7H7_benzyl", MM = 0.09113048, Hf = 2309874.808077385, H0 = 203607.9695838319, Tlimit = 1000, alow = {-183676.4826, 4102.46566, -32.024061, 0.1588249575, -0.0001894466924, 1.203649671e-007, -3.136589637e-011}, blow = {5266.33323, 193.875172}, ahigh = {5297322.16, -25999.09398, 55.0975079, -0.00497766147, 9.46315243e-007, -9.639008860000001e-011, 4.06447042e-015}, bhigh = {173838.2912, -334.382955}, R_s = R_NASA_2002/C7H7_benzyl.MM);
          constant IdealGases.Common.DataRecord C7H8(name = "C7H8", MM = 0.09213842, Hf = 544506.8409030674, H0 = 194710.794910527, Tlimit = 1000, alow = {-287796.222, 6133.941519999999, -45.74706759999999, 0.1936895724, -0.0002304305304, 1.459301178e-007, -3.7907961e-011}, blow = {-23084.02499, 269.3915042}, ahigh = {6184538.350000001, -29902.84056, 59.8200597, -0.00569698396, 1.080748416e-006, -1.098702235e-010, 4.62474022e-015}, bhigh = {178204.7857, -369.808225}, R_s = R_NASA_2002/C7H8.MM);
          constant IdealGases.Common.DataRecord C7H8O_cresol_mx(name = "C7H8O_cresol_mx", MM = 0.10813782, Hf = -1223420.261292488, H0 = 201949.1792973078, Tlimit = 1000, alow = {-244141.7503, 5080.87784, -37.8904804, 0.186494507, -0.0002269511868, 1.458989279e-007, -3.82240335e-011}, blow = {-40936.57829999999, 228.1352234}, ahigh = {6017373.45, -28498.82774, 60.81543070000001, -0.004996807109999999, 9.13427995e-007, -8.979444109999999e-011, 3.66775697e-015}, bhigh = {147221.84, -367.485014}, R_s = R_NASA_2002/C7H8O_cresol_mx.MM);
          constant IdealGases.Common.DataRecord C7H14_1_heptene(name = "C7H14_1_heptene", MM = 0.09818605999999999, Hf = -639194.6066478277, H0 = 313588.3036756949, Tlimit = 1000, alow = {-744940.284, 13321.79893, -82.81694379999999, 0.3108065994, -0.000378677992, 2.446841042e-007, -6.488763869999999e-011}, blow = {-72178.8501, 485.667149}, ahigh = {-1927608.174, -9125.024420000002, 47.4817797, 0.00606766053, -8.684859080000001e-007, 5.81399526e-011, -1.473979569e-015}, bhigh = {26009.14656, -256.2880707}, R_s = R_NASA_2002/C7H14_1_heptene.MM);
          constant IdealGases.Common.DataRecord C7H15_n_heptyl(name = "C7H15_n_heptyl", MM = 0.099194, Hf = 44256.70907514567, H0 = 338155.5336008226, Tlimit = 1000, alow = {-1671733.521, 26400.1025, -152.6867707, 0.5027121410000001, -0.000652101403, 4.44348811e-007, -1.227815006e-010}, blow = {-127375.4623, 878.3933319999999}, ahigh = {5444527.57, -34568.2929, 76.38651949999999, -0.003298972, 2.343496957e-007, 2.467674021e-011, -3.162012849e-015}, bhigh = {193907.9354, -464.142466}, R_s = R_NASA_2002/C7H15_n_heptyl.MM);
          constant IdealGases.Common.DataRecord C7H16_n_heptane(name = "C7H16_n_heptane", MM = 0.10020194, Hf = -1874015.612871368, H0 = 331540.487140269, Tlimit = 1000, alow = {-612743.289, 11840.85437, -74.87188599999999, 0.2918466052, -0.000341679549, 2.159285269e-007, -5.65585273e-011}, blow = {-80134.0894, 440.721332}, ahigh = {9135632.469999999, -39233.1969, 78.8978085, -0.00465425193, 2.071774142e-006, -3.4425393e-010, 1.976834775e-014}, bhigh = {205070.8295, -485.110402}, R_s = R_NASA_2002/C7H16_n_heptane.MM);
          constant IdealGases.Common.DataRecord C7H16_2_methylh(name = "C7H16_2_methylh", MM = 0.10020194, Hf = -1942078.167348856, H0 = 308576.8598891399, Tlimit = 1000, alow = {-710477.777, 11912.5112, -73.45339440000001, 0.2902952369, -0.000346276768, 2.260184498e-007, -6.12881392e-011}, blow = {-82021.477, 432.004229}, ahigh = {1289912.969, -1784.340963, 10.83537673, 0.05270609239999999, -1.886832314e-005, 2.432255843e-009, -1.135553789e-013}, bhigh = {-16375.29884, -29.8186241}, R_s = R_NASA_2002/C7H16_2_methylh.MM);
          constant IdealGases.Common.DataRecord C8H8_styrene(name = "C8H8_styrene", MM = 0.10414912, Hf = 1423919.85645198, H0 = 201057.8677957144, Tlimit = 1000, alow = {-268693.052, 6167.99947, -48.3605494, 0.2182873229, -0.0002738561832, 1.810084981e-007, -4.86775027e-011}, blow = {-11406.39978, 281.7679014}, ahigh = {-6629183.62, 15145.94166, 1.609822364, 0.033833186, -1.093737395e-005, 1.338825116e-009, -6.03253492e-014}, bhigh = {-89973.2415, 43.1128279}, R_s = R_NASA_2002/C8H8_styrene.MM);
          constant IdealGases.Common.DataRecord C8H10_ethylbenz(name = "C8H10_ethylbenz", MM = 0.106165, Hf = 281825.4603682946, H0 = 209862.0072528611, Tlimit = 1000, alow = {-469494, 9307.16836, -65.2176947, 0.2612080237, -0.000318175348, 2.051355473e-007, -5.40181735e-011}, blow = {-40738.7021, 378.090436}, ahigh = {5551564.100000001, -28313.80598, 60.6124072, 0.001042112857, -1.327426719e-006, 2.166031743e-010, -1.142545514e-014}, bhigh = {164224.1062, -369.176982}, R_s = R_NASA_2002/C8H10_ethylbenz.MM);
          constant IdealGases.Common.DataRecord C8H16_1_octene(name = "C8H16_1_octene", MM = 0.11221264, Hf = -744924.9924072726, H0 = 315026.8989304592, Tlimit = 1000, alow = {-928190.522, 16409.74476, -101.5939534, 0.374800141, -0.00045908294, 2.96533534e-007, -7.84044521e-011}, blow = {-89524.2608, 590.759427}, ahigh = {-4409336.07, -4383.678800000001, 49.39154259999999, 0.007912339629999999, -7.88866951e-007, 9.97021235e-012, 1.913144872e-015}, bhigh = {-11226.19342, -257.7650649}, R_s = R_NASA_2002/C8H16_1_octene.MM);
          constant IdealGases.Common.DataRecord C8H17_n_octyl(name = "C8H17_n_octyl", MM = 0.11322058, Hf = -144143.4057306543, H0 = 336537.7566516617, Tlimit = 1000, alow = {-1934340.995, 30549.7983, -176.7903454, 0.5801596649999999, -0.000751741401, 5.11246903e-007, -1.410193662e-010}, blow = {-149889.4706, 1013.724329}, ahigh = {5632173.390000001, -38211.4367, 86.37927500000001, -0.00360893158, 2.544260445e-007, 2.908638837e-011, -3.67954974e-015}, bhigh = {210313.547, -526.242283}, R_s = R_NASA_2002/C8H17_n_octyl.MM);
          constant IdealGases.Common.DataRecord C8H18_n_octane(name = "C8H18_n_octane", MM = 0.11422852, Hf = -1827477.060895125, H0 = 330740.51909278, Tlimit = 1000, alow = {-698664.715, 13385.01096, -84.1516592, 0.327193666, -0.000377720959, 2.339836988e-007, -6.01089265e-011}, blow = {-90262.2325, 493.922214}, ahigh = {6365406.949999999, -31053.64657, 69.6916234, 0.01048059637, -4.12962195e-006, 5.543226319999999e-010, -2.651436499e-014}, bhigh = {150096.8785, -416.989565}, R_s = R_NASA_2002/C8H18_n_octane.MM);
          constant IdealGases.Common.DataRecord C8H18_isooctane(name = "C8H18_isooctane", MM = 0.11422852, Hf = -1961068.916939482, H0 = 281628.440953275, Tlimit = 1000, alow = {-168875.8565, 3126.903227, -21.23502828, 0.1489151508, -0.0001151180135, 4.47321617e-008, -5.55488207e-012}, blow = {-44680.6062, 141.7455793}, ahigh = {13527650.32, -46633.7034, 77.95313179999999, 0.01423729984, -5.073593909999999e-006, 7.24823297e-010, -3.81919011e-014}, bhigh = {254117.8017, -493.388719}, R_s = R_NASA_2002/C8H18_isooctane.MM);
          constant IdealGases.Common.DataRecord C9H19_n_nonyl(name = "C9H19_n_nonyl", MM = 0.12724716, Hf = -291008.4594422383, H0 = 335284.496722756, Tlimit = 1000, alow = {-2194880.612, 34685.6578, -200.9261419, 0.658050311, -0.000852593001, 5.79463896e-007, -1.597637099e-010}, blow = {-172319.4608, 1149.114017}, ahigh = {5277361.74, -40257.0196, 94.57296720000001, -0.002940301447, 6.97810699e-009, 6.80525024e-011, -5.90709533e-015}, bhigh = {216532.0614, -575.44495}, R_s = R_NASA_2002/C9H19_n_nonyl.MM);
          constant IdealGases.Common.DataRecord C10H8_naphthale(name = "C10H8_naphthale", MM = 0.12817052, Hf = 1174841.141317052, H0 = 161605.6172667475, Tlimit = 1000, alow = {-260284.5316, 6237.40957, -52.2609504, 0.2397692776, -0.0002912244803, 1.854944401e-007, -4.81661927e-011}, blow = {-11147.0088, 297.2139517}, ahigh = {5906172.11, -31632.2924, 70.3034203, -0.00601886554, 1.142052144e-006, -1.161605689e-010, 4.89284402e-015}, bhigh = {196256.7046, -434.7848950000001}, R_s = R_NASA_2002/C10H8_naphthale.MM);
          constant IdealGases.Common.DataRecord C10H21_n_decyl(name = "C10H21_n_decyl", MM = 0.14127374, Hf = -408710.0688351565, H0 = 334273.0220067792, Tlimit = 1000, alow = {-2446511.152, 38700.813, -224.4388176, 0.734362497, -0.00095135256, 6.46297033e-007, -1.781502862e-010}, blow = {-194163.3889, 1280.987834}, ahigh = {4967237.76, -42424.6844, 102.8853417, -0.00232484818, -2.2842339e-007, 1.056127364e-010, -8.0680659e-015}, bhigh = {223542.989, -625.5191159999999}, R_s = R_NASA_2002/C10H21_n_decyl.MM);
          constant IdealGases.Common.DataRecord C12H9_o_bipheny(name = "C12H9_o_bipheny", MM = 0.15319986, Hf = 2791973.830785485, H0 = 173559.8648719392, Tlimit = 1000, alow = {-359584.082, 7661.37856, -58.7329046, 0.2697557882, -0.000322975668, 2.0329071e-007, -5.23131672e-011}, blow = {14584.14642, 339.268711}, ahigh = {6736469.42, -36321.9435, 82.102396, -0.00750234286, 1.456251733e-006, -1.507145019e-010, 6.43647043e-015}, bhigh = {255552.4521, -504.246297}, R_s = R_NASA_2002/C12H9_o_bipheny.MM);
          constant IdealGases.Common.DataRecord C12H10_biphenyl(name = "C12H10_biphenyl", MM = 0.1542078, Hf = 1181068.66189648, H0 = 173684.6190659617, Tlimit = 1000, alow = {-367103.405, 8128.41259, -63.9099457, 0.2901422744, -0.000350959074, 2.230989996e-007, -5.78847029e-011}, blow = {-16792.63066, 363.346419}, ahigh = {7480385.359999999, -39280.8723, 86.61482219999999, -0.007946398570000001, 1.531868544e-006, -1.576450171e-010, 6.70060273e-015}, bhigh = {243805.0641, -538.138149}, R_s = R_NASA_2002/C12H10_biphenyl.MM);
          constant IdealGases.Common.DataRecord Ca(name = "Ca", MM = 0.040078, Hf = 4436349.119217526, H0 = 154634.1633814063, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {20638.92786, 4.38454833}, ahigh = {7547341.239999999, -21486.42662, 25.30849567, -0.01103773705, 2.293249636e-006, -1.209075383e-010, -4.015333268e-015}, bhigh = {158586.2323, -160.9512955}, R_s = R_NASA_2002/Ca.MM);
          constant IdealGases.Common.DataRecord Caplus(name = "Caplus", MM = 0.0400774514, Hf = 19308306.81513845, H0 = 154636.2800904052, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {92324.1779, 5.07767498}, ahigh = {3747070.82, -11747.07738, 16.72546969, -0.00833479771, 2.394593294e-006, -2.988243468e-010, 1.356563002e-014}, bhigh = {166432.9088, -95.8282126}, R_s = R_NASA_2002/Caplus.MM);
          constant IdealGases.Common.DataRecord CaBr(name = "CaBr", MM = 0.119982, Hf = -207270.0988481606, H0 = 82146.64699704957, Tlimit = 1000, alow = {569.3832620000001, -125.7513537, 5.00150833, -0.001039868753, 1.377594927e-006, -8.94901396e-010, 2.395658928e-013}, blow = {-3728.10398, 1.784864847}, ahigh = {2783236.402, -8458.203729999999, 14.3175656, -0.00543078168, 1.522218659e-006, -1.831824807e-010, 7.86428866e-015}, bhigh = {49312.7068, -65.37001100000001}, R_s = R_NASA_2002/CaBr.MM);
          constant IdealGases.Common.DataRecord CaBr2(name = "CaBr2", MM = 0.199886, Hf = -1937090.641665749, H0 = 78060.49448185465, Tlimit = 1000, alow = {1572.504318, -223.8551236, 8.38845789, -0.001944164774, 2.397926088e-006, -1.55657235e-009, 4.12430958e-013}, blow = {-47721.0661, -10.74965233}, ahigh = {-22198.46426, -4.46315533, 7.50375511, -1.641654626e-006, 3.87942806e-010, -4.68342426e-014, 2.259325541e-018}, bhigh = {-48854.3682, -5.59032425}, R_s = R_NASA_2002/CaBr2.MM);
          constant IdealGases.Common.DataRecord CaCL(name = "CaCL", MM = 0.075531, Hf = -1373911.175543816, H0 = 127035.4556407303, Tlimit = 1000, alow = {6395.335260000001, -224.9042269, 5.28327839, -0.001447983237, 1.643742771e-006, -9.43010428e-010, 2.237516133e-013}, blow = {-12701.69, -1.391964289}, ahigh = {1629182.545, -4766.22302, 9.65892977, -0.002523044131, 5.83354216e-007, -4.10172699e-011, 8.813177639999999e-017}, bhigh = {16625.99241, -33.98731174}, R_s = R_NASA_2002/CaCL.MM);
          constant IdealGases.Common.DataRecord CaCLplus(name = "CaCLplus", MM = 0.0755304514, Hf = 6185459.034606007, H0 = 123938.2636603705, Tlimit = 1000, alow = {2285.284542, -200.2872721, 4.93699019, -0.000386097303, 8.686661880000001e-008, 1.47020568e-010, -7.68931587e-014}, blow = {55882.7795, -0.6359815341}, ahigh = {177028.0396, -589.137239, 5.1033688, -0.0002356761168, 5.48373287e-008, 2.137973112e-014, -5.57288731e-016}, bhigh = {58534.17249999999, -2.191253644}, R_s = R_NASA_2002/CaCLplus.MM);
          constant IdealGases.Common.DataRecord CaCL2(name = "CaCL2", MM = 0.110984, Hf = -4372193.081885677, H0 = 133866.3501045195, Tlimit = 1000, alow = {11068.0203, -424.910825, 9.13471186, -0.00349718531, 4.242184629999999e-006, -2.719673231e-009, 7.13826863e-013}, blow = {-58503.4676, -18.08678294}, ahigh = {-35957.6878, -8.796495630000001, 7.50725691, -3.129465934e-006, 7.322886480000001e-010, -8.776403220000001e-014, 4.21048604e-018}, bhigh = {-60667.7966, -8.553523451}, R_s = R_NASA_2002/CaCL2.MM);
          constant IdealGases.Common.DataRecord CaF(name = "CaF", MM = 0.0590764032, Hf = -4678751.159989374, H0 = 154581.3472950229, Tlimit = 1000, alow = {31842.354, -491.8235089999999, 5.70112089, -0.001465138218, 9.09293081e-007, -1.367585222e-010, -5.10632338e-014}, blow = {-31976.9411, -5.99666226}, ahigh = {519588.2669999999, -1512.321567, 5.86927625, -0.000388252448, -2.484582298e-008, 3.74991596e-011, -3.47097645e-015}, bhigh = {-24888.14584, -8.6146637}, R_s = R_NASA_2002/CaF.MM);
          constant IdealGases.Common.DataRecord CaFplus(name = "CaFplus", MM = 0.0590758546, Hf = 4412371.344688089, H0 = 152399.1156955688, Tlimit = 1000, alow = {41583.408, -562.766166, 5.68752215, -0.001264710572, 6.66908648e-007, -6.92675282e-011, -3.97871462e-014}, blow = {33051.195, -6.97448501}, ahigh = {-139867.0845, 219.1526375, 4.21432434, 0.0002142798048, -5.7786726e-008, 9.98575631e-012, -6.05962188e-016}, bhigh = {28416.05897, 2.740342729}, R_s = R_NASA_2002/CaFplus.MM);
          constant IdealGases.Common.DataRecord CaF2(name = "CaF2", MM = 0.0780748064, Hf = -10129111.36722332, H0 = 164093.7914640798, Tlimit = 1000, alow = {59093.5229, -1019.733042, 10.13165309, -0.00550350644, 5.62931998e-006, -3.115401465e-009, 7.205525940000001e-013}, blow = {-91926.08189999999, -26.3950595}, ahigh = {-82804.0944, -31.15950071, 7.02357737, -9.521000020000001e-006, 2.118160895e-009, -2.440713888e-013, 1.135135468e-017}, bhigh = {-97294.66770000001, -7.54624334}, R_s = R_NASA_2002/CaF2.MM);
          constant IdealGases.Common.DataRecord CaH(name = "CaH", MM = 0.04108594, Hf = 5583640.169848858, H0 = 211875.5223806489, Tlimit = 1000, alow = {-45137.8223, 762.942921, -1.280874223, 0.01318774659, -1.481595334e-005, 8.53657322e-009, -1.989958945e-012}, blow = {23003.78814, 30.53421525}, ahigh = {-2696952.529, 8607.05975, -7.02745482, 0.007467916309999999, -2.318610699e-006, 3.42307242e-010, -1.892679792e-014}, bhigh = {-27738.19107, 78.45822010000001}, R_s = R_NASA_2002/CaH.MM);
          constant IdealGases.Common.DataRecord CaI(name = "CaI", MM = 0.16698247, Hf = 72961.67076699728, H0 = 59995.04019793216, Tlimit = 1000, alow = {-826.179018, -85.08975899999999, 4.86417169, -0.000786316965, 1.100493506e-006, -7.34803061e-010, 2.010892767e-013}, blow = {523.675344, 3.58539168}, ahigh = {1771071.309, -5683.64373, 11.53857476, -0.0041940202, 1.291359961e-006, -1.730043579e-010, 8.38076235e-015}, bhigh = {35832.932, -44.0591757}, R_s = R_NASA_2002/CaI.MM);
          constant IdealGases.Common.DataRecord CaI2(name = "CaI2", MM = 0.29388694, Hf = -882378.4581921197, H0 = 54616.22418471539, Tlimit = 1000, alow = {-1097.851401, -145.9821761, 8.08934184, -0.001305332923, 1.624199331e-006, -1.061194001e-009, 2.825551217e-013}, blow = {-32726.9298, -6.98171494}, ahigh = {-16237.27104, -2.859530722, 7.50243219, -1.071178707e-006, 2.544559095e-010, -3.083631004e-014, 1.491836724e-018}, bhigh = {-33463.4117, -3.56730574}, R_s = R_NASA_2002/CaI2.MM);
          constant IdealGases.Common.DataRecord CaO(name = "CaO", MM = 0.0560774, Hf = 677729.4953047038, H0 = 159656.2608109506, Tlimit = 1000, alow = {38897.3307, -483.567735, 5.07771325, 0.000307623525, -1.159759897e-006, 8.493433339999999e-010, -1.495333366e-013}, blow = {5937.643480000001, -3.95532073}, ahigh = {-49131061.7, 149586.595, -168.1654149, 0.09381950259999999, -2.455529428e-005, 3.07498072e-009, -1.485914237e-013}, bhigh = {-946151.172, 1235.694769}, R_s = R_NASA_2002/CaO.MM);
          constant IdealGases.Common.DataRecord CaOplus(name = "CaOplus", MM = 0.0560768514, Hf = 12665431.88977975, H0 = 163402.7191476731, Tlimit = 1000, alow = {109806.0332, -1459.992448, 9.88077794, -0.009157564600000001, 8.707582560000001e-006, -4.39041108e-009, 9.264854659999999e-013}, blow = {91500.57350000001, -30.09947701}, ahigh = {939784.313, -2993.362243, 8.33619182, -0.002303295087, 7.37396753e-007, -1.052888279e-010, 5.25713841e-015}, bhigh = {102809.8401, -24.61547836}, R_s = R_NASA_2002/CaOplus.MM);
          constant IdealGases.Common.DataRecord CaOH(name = "CaOH", MM = 0.05708534000000001, Hf = -3035934.444815429, H0 = 193564.5298775482, Tlimit = 1000, alow = {46200.289, -928.567282, 9.175828770000001, -0.0039628288, 2.505447308e-006, 3.85206821e-011, -3.35277847e-013}, blow = {-17980.09717, -25.3370485}, ahigh = {1979972.994, -5598.88099, 11.51348706, -0.001668264707, 3.31257391e-007, -1.789056647e-011, -3.58071641e-016}, bhigh = {13401.96822, -46.46084260000001}, R_s = R_NASA_2002/CaOH.MM);
          constant IdealGases.Common.DataRecord CaOHplus(name = "CaOHplus", MM = 0.0570847914, Hf = 6533055.317427332, H0 = 194407.6299103372, Tlimit = 1000, alow = {48843.4266, -983.2415100000001, 9.61018295, -0.00520436066, 4.26304982e-006, -1.197590878e-009, 9.028411889999999e-015}, blow = {47950.56340000001, -28.27077334}, ahigh = {863761.537, -2347.302046, 7.9819112, 0.0001003160947, -6.24007417e-008, 1.019540904e-011, -5.69892528e-016}, bhigh = {58305.80119999999, -21.52181937}, R_s = R_NASA_2002/CaOHplus.MM);
          constant IdealGases.Common.DataRecord Ca_OH_2(name = "Ca_OH_2", MM = 0.07409268000000001, Hf = -8075546.315776401, H0 = 223939.5443652463, Tlimit = 1000, alow = {83892.57539999999, -1791.902135, 16.21891031, -0.00784085717, 5.09511161e-006, -6.95548755e-011, -6.13215264e-013}, blow = {-66004.0563, -60.7091392}, ahigh = {1721854.884, -4702.21767, 13.96947691, 0.0001983791405, -1.243050592e-007, 2.033402404e-011, -1.137157819e-015}, bhigh = {-44437.6135, -52.8744486}, R_s = R_NASA_2002/Ca_OH_2.MM);
          constant IdealGases.Common.DataRecord CaS(name = "CaS", MM = 0.072143, Hf = 1683812.885519038, H0 = 129743.8836754779, Tlimit = 1000, alow = {23209.90615, -451.8446080000001, 6.17233375, -0.00359885202, 4.823731709999999e-006, -3.63173354e-009, 1.212849867e-012}, blow = {15545.97691, -7.686936462}, ahigh = {-15683532.14, 52938.5581, -63.2246724, 0.0402772638, -1.114855081e-005, 1.464389344e-009, -7.37607897e-014}, bhigh = {-317202.267, 479.9606012}, R_s = R_NASA_2002/CaS.MM);
          constant IdealGases.Common.DataRecord Ca2(name = "Ca2", MM = 0.08015600000000001, Hf = 4263752.382853436, H0 = 140639.9520934178, Tlimit = 1000, alow = {-85822.2862, 158.818896, 11.03952055, -0.0333319676, 5.34593881e-005, -4.011573239999999e-008, 1.160486682e-011}, blow = {37703.508, -23.97744561}, ahigh = {240596.6267, 57.7580382, 2.347436675, 0.0001199275034, -4.32915031e-008, 7.01530269e-012, -3.70566032e-016}, bhigh = {40818.754, 18.95399607}, R_s = R_NASA_2002/Ca2.MM);
          constant IdealGases.Common.DataRecord Cd(name = "Cd", MM = 0.112411, Hf = 994564.5888747543, H0 = 55131.86431932818, Tlimit = 1000, alow = {-0.0001081751543, 1.816433041e-006, 2.499999989, 3.129989231e-011, -4.60071016e-014, 3.40704874e-017, -9.989497436e-021}, blow = {12700.99766, 5.93154976}, ahigh = {-269975.7467, 786.600114, 1.628169079, 0.000459412329, -1.150420443e-007, 1.074836707e-011, 8.790199554999999e-017}, bhigh = {7675.14826, 12.20006052}, R_s = R_NASA_2002/Cd.MM);
          constant IdealGases.Common.DataRecord Cdplus(name = "Cdplus", MM = 0.1124104514, Hf = 8769240.899961371, H0 = 55132.13338097137, Tlimit = 1000, alow = {0.000409834494, -4.34358162e-006, 2.500000019, -4.389036810000001e-011, 5.5639692e-014, -3.63822826e-017, 9.607881994999999e-021}, blow = {117812.9439, 6.62468945}, ahigh = {14848.80812, -46.6915368, 2.557883006, -3.6247017e-005, 1.21374757e-008, -2.072802814e-012, 1.420665367e-016}, bhigh = {118107.0109, 6.21641448}, R_s = R_NASA_2002/Cdplus.MM);
          constant IdealGases.Common.DataRecord CL(name = "CL", MM = 0.03545300000000001, Hf = 3421459.396948072, H0 = 176898.6545567371, Tlimit = 1000, alow = {22762.15854, -216.8413293, 2.745185115, 0.002451101694, -5.45801199e-006, 4.41798688e-009, -1.288134004e-012}, blow = {15013.57068, 3.102963457}, ahigh = {-169793.293, 608.172646, 2.12866409, 0.0001307367034, -2.644883596e-008, 2.842504775e-012, -1.252911731e-016}, bhigh = {9934.3874, 8.844772103}, R_s = R_NASA_2002/CL.MM);
          constant IdealGases.Common.DataRecord CLplus(name = "CLplus", MM = 0.0354524514, Hf = 38891517.52705033, H0 = 180138.0369426302, Tlimit = 1000, alow = {103469.7859, -1293.758873, 8.186702690000001, -0.0099160146, 9.20847237e-006, -4.50742624e-009, 9.18212788e-013}, blow = {171475.878, -27.66417931}, ahigh = {40564.0948, -49.6016572, 3.10165363, -0.000586873829, 2.252039316e-007, -3.29970302e-011, 1.708780842e-015}, bhigh = {165298.2337, 2.574942598}, R_s = R_NASA_2002/CLplus.MM);
          constant IdealGases.Common.DataRecord CLminus(name = "CLminus", MM = 0.0354535486, Hf = -6599000.135066875, H0 = 174804.1661477012, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {-28883.89093, 4.200642023}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {-28883.89093, 4.200642023}, R_s = R_NASA_2002/CLminus.MM);
          constant IdealGases.Common.DataRecord CLCN(name = "CLCN", MM = 0.06147039999999999, Hf = 2183164.580025509, H0 = 173563.8941669487, Tlimit = 1000, alow = {72740.43429999999, -1297.344947, 11.07676527, -0.01108430216, 1.614009477e-005, -1.088916772e-008, 2.830952246e-012}, blow = {20843.88986, -35.97370046}, ahigh = {346757.312, -1957.85737, 8.807806149999999, -0.0004388362779999999, 1.024761895e-007, -1.110675026e-011, 4.98617942e-016}, bhigh = {25819.23944, -26.36885363}, R_s = R_NASA_2002/CLCN.MM);
          constant IdealGases.Common.DataRecord CLF(name = "CLF", MM = 0.0544514032, Hf = -1022948.71622335, H0 = 163597.3818210069, Tlimit = 1000, alow = {33522.1081, -368.83119, 4.27228862, 0.002549434508, -4.45683089e-006, 3.41385412e-009, -9.8386852e-013}, blow = {-5839.36969, 0.2318014199}, ahigh = {3045867.173, -9979.32826, 16.84162254, -0.007465850620000001, 2.336213612e-006, -3.36586546e-010, 1.763082415e-014}, bhigh = {54471.20800000001, -87.07987094000001}, R_s = R_NASA_2002/CLF.MM);
          constant IdealGases.Common.DataRecord CLF3(name = "CLF3", MM = 0.0924482096, Hf = -1780456.330221889, H0 = 148498.8087860168, Tlimit = 1000, alow = {128517.5171, -2140.445721, 14.93096474, -0.00604247104, 3.71896861e-006, -8.0532011e-010, -7.98560053e-014}, blow = {-11384.5964, -55.94838353}, ahigh = {-229495.6235, -122.0741, 10.09124644, -3.64972475e-005, 8.05891075e-009, -9.23084995e-013, 4.27256949e-017}, bhigh = {-22828.40447, -25.11605479}, R_s = R_NASA_2002/CLF3.MM);
          constant IdealGases.Common.DataRecord CLF5(name = "CLF5", MM = 0.130445016, Hf = -1824523.521849237, H0 = 137455.5851179473, Tlimit = 1000, alow = {245970.3939, -4315.34807, 27.27005972, -0.01670193839, 1.421668208e-005, -6.426479740000001e-009, 1.183099799e-012}, blow = {-10714.23726, -126.7466837}, ahigh = {-426932.7449999999, -205.805739, 16.15465278, -6.21268818e-005, 1.376637959e-008, -1.581335709e-012, 7.33642249e-017}, bhigh = {-33614.666, -57.57531175}, R_s = R_NASA_2002/CLF5.MM);
          constant IdealGases.Common.DataRecord CLO(name = "CLO", MM = 0.0514524, Hf = 1975051.018028314, H0 = 185066.4886380422, Tlimit = 1000, alow = {-16872.68145, 257.3812247, 2.17584612, 0.006432061130000001, -8.568249500000001e-006, 5.764971250000001e-009, -1.545771209e-012}, blow = {9829.518979999999, 13.86010503}, ahigh = {409376.052, -1765.985112, 7.08790063, -0.001828450169, 7.1038181e-007, -1.209332942e-010, 7.07644104e-015}, bhigh = {21518.91784, -16.68645548}, R_s = R_NASA_2002/CLO.MM);
          constant IdealGases.Common.DataRecord CLO2(name = "CLO2", MM = 0.06745180000000001, Hf = 1556667.131195906, H0 = 160123.9107036432, Tlimit = 1000, alow = {-11272.77696, 390.303203, -0.384301853, 0.02108677947, -2.793137755e-005, 1.841289286e-008, -4.83977915e-012}, blow = {9756.93367, 29.132627}, ahigh = {-163379.3802, -316.148067, 7.00978726, 0.0002837971144, -1.179925338e-007, 2.920383252e-011, -2.024030202e-015}, bhigh = {11849.46452, -10.91168827}, R_s = R_NASA_2002/CLO2.MM);
          constant IdealGases.Common.DataRecord CL2(name = "CL2", MM = 0.07090600000000001, Hf = 0, H0 = 129482.8364313316, Tlimit = 1000, alow = {34628.1517, -554.7126520000001, 6.20758937, -0.002989632078, 3.17302729e-006, -1.793629562e-009, 4.260043590000001e-013}, blow = {1534.069331, -9.438331107}, ahigh = {6092569.42, -19496.27662, 28.54535795, -0.01449968764, 4.46389077e-006, -6.35852586e-010, 3.32736029e-014}, bhigh = {121211.7724, -169.0778824}, R_s = R_NASA_2002/CL2.MM);
          constant IdealGases.Common.DataRecord CL2O(name = "CL2O", MM = 0.08690539999999999, Hf = 909034.4213363037, H0 = 134577.1609129007, Tlimit = 1000, alow = {77988.554, -1182.537879, 9.52651466, -0.002596163176, 8.696781310000001e-007, 4.484098269999999e-010, -3.044511967e-013}, blow = {13767.29572, -24.84690718}, ahigh = {-127174.3461, -67.4196322, 7.05002245, -1.988084386e-005, 4.366209050000001e-009, -4.978580680000001e-013, 2.295679186e-017}, bhigh = {7387.2893, -8.797477254}, R_s = R_NASA_2002/CL2O.MM);
          constant IdealGases.Common.DataRecord Co(name = "Co", MM = 0.0589332, Hf = 7269953.099441402, H0 = 107914.8595358813, Tlimit = 1000, alow = {-2598.939184, 246.1989844, -0.610605837, 0.01393005772, -2.210012979e-005, 1.623755261e-008, -4.534904351e-012}, blow = {49846.1376, 22.57584199}, ahigh = {1381841.305, -3756.03668, 6.65713065, -0.001269246675, 1.464092329e-007, 6.57494657e-012, -1.102384178e-015}, bhigh = {74944.42909999999, -22.58500836}, R_s = R_NASA_2002/Co.MM);
          constant IdealGases.Common.DataRecord Coplus(name = "Coplus", MM = 0.05893265139999999, Hf = 20243503.02691455, H0 = 106757.5758181482, Tlimit = 1000, alow = {102849.416, -874.473126, 4.27950028, 0.002225857835, -7.45727457e-006, 7.27922195e-009, -2.347541963e-012}, blow = {147489.5959, -5.67901922}, ahigh = {2907386.174, -8619.705749999999, 11.88134934, -0.00351064742, 5.74800468e-007, -2.534065135e-011, 2.976607469e-016}, bhigh = {197741.9221, -60.9653344}, R_s = R_NASA_2002/Coplus.MM);
          constant IdealGases.Common.DataRecord Cominus(name = "Cominus", MM = 0.0589337486, Hf = 6081648.978968902, H0 = 107014.6079253475, Tlimit = 1000, alow = {34594.9376, -135.5041712, 1.116330898, 0.009042761829999999, -1.454296726e-005, 9.99494063e-009, -2.595633259e-012}, blow = {43370.3782, 12.70494975}, ahigh = {-574139.417, 1763.109207, 1.415561988, 0.000377686969, -7.53417998e-008, 7.99570154e-012, -3.49044e-016}, bhigh = {30834.93114, 16.34360353}, R_s = R_NASA_2002/Cominus.MM);
          constant IdealGases.Common.DataRecord Cr(name = "Cr", MM = 0.0519961, Hf = 7644419.485307553, H0 = 119190.2469608298, Tlimit = 1000, alow = {1335.658217, -21.02424026, 2.631908173, -0.000424626325, 7.43919416e-007, -6.76393163e-010, 2.507855625e-013}, blow = {47158.6664, 6.00542545}, ahigh = {-11202207.89, 34011.63690000001, -36.5706217, 0.02110296902, -5.51818014e-006, 7.17360171e-010, -3.505127367e-014}, bhigh = {-168899.344, 286.4481267}, R_s = R_NASA_2002/Cr.MM);
          constant IdealGases.Common.DataRecord Crplus(name = "Crplus", MM = 0.0519955514, Hf = 20319944.67895959, H0 = 119191.5045255199, Tlimit = 1000, alow = {181.9187467, -2.188843517, 2.510676511, -2.706791825e-005, 3.76849263e-008, -2.736784742e-011, 8.115389931999999e-015}, blow = {126338.0825, 6.50627617}, ahigh = {3342330.79, -10642.61051, 15.57884307, -0.00770897148, 2.158300274e-006, -2.36810811e-010, 8.952805604e-015}, bhigh = {193299.767, -86.0435667}, R_s = R_NASA_2002/Crplus.MM);
          constant IdealGases.Common.DataRecord Crminus(name = "Crminus", MM = 0.0519966486, Hf = 6289317.423431017, H0 = 119188.989422676, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {38586.2787, 6.56683537}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {38586.2787, 6.56683537}, R_s = R_NASA_2002/Crminus.MM);
          constant IdealGases.Common.DataRecord CrN(name = "CrN", MM = 0.0660028, Hf = 7651323.883229196, H0 = 132991.1609810493, Tlimit = 1000, alow = {-8239.129220000001, 300.8144202, 0.514787492, 0.01129636791, -1.515183504e-005, 1.010997229e-008, -2.68777575e-012}, blow = {58456.2812, 22.98028696}, ahigh = {1110672.49, -3690.47854, 8.59905668, -0.002125587223, 5.28235848e-007, -4.92113915e-011, 1.404331106e-015}, bhigh = {82548.04580000001, -27.99968411}, R_s = R_NASA_2002/CrN.MM);
          constant IdealGases.Common.DataRecord CrO(name = "CrO", MM = 0.0679955, Hf = 2744024.501621431, H0 = 144849.5562206323, Tlimit = 1000, alow = {9373.33411, 136.9743818, 1.621443428, 0.008814095959999999, -1.23284536e-005, 8.497960940000001e-009, -2.315804197e-012}, blow = {20909.48871, 17.81935787}, ahigh = {1092367.332, -3749.75865, 9.00787021, -0.002545445236, 6.928051680000001e-007, -6.390831950000001e-011, 1.659741645e-015}, bhigh = {44470.9821, -29.42600453}, R_s = R_NASA_2002/CrO.MM);
          constant IdealGases.Common.DataRecord CrO2(name = "CrO2", MM = 0.0839949, Hf = -1286307.085311132, H0 = 127315.6941671459, Tlimit = 1000, alow = {35486.299, -229.8628537, 2.286289393, 0.01616929338, -2.34519891e-005, 1.631365714e-008, -4.44426962e-012}, blow = {-12789.1284, 14.42954956}, ahigh = {-432710.914, 191.5584657, 7.18824737, -0.000569484619, 3.54636613e-007, -5.65512306e-011, 2.908946349e-015}, bhigh = {-17433.39545, -10.0642472}, R_s = R_NASA_2002/CrO2.MM);
          constant IdealGases.Common.DataRecord CrO3(name = "CrO3", MM = 0.09999429999999999, Hf = -3220554.411601461, H0 = 130408.1532647361, Tlimit = 1000, alow = {41830.2006, -505.934885, 4.43271567, 0.01995079387, -2.920597649e-005, 2.03933028e-008, -5.580086630000001e-012}, blow = {-37697.024, 0.8653827279999999}, ahigh = {-628331.401, 692.8158179999999, 8.971274599999999, 0.000682336564, -2.235048825e-007, 3.36678579e-011, -1.614026492e-015}, bhigh = {-47238.802, -19.45305345}, R_s = R_NASA_2002/CrO3.MM);
          constant IdealGases.Common.DataRecord CrO3minus(name = "CrO3minus", MM = 0.09999484859999999, Hf = -6328834.473579072, H0 = 134244.3054611516, Tlimit = 1000, alow = {187345.5703, -2300.722991, 13.43953022, -0.001663085846, -1.443973096e-006, 2.045898933e-009, -6.8375553e-013}, blow = {-66301.1158, -49.306442}, ahigh = {-649968.203, 452.201762, 9.9805759, -0.000421413673, 2.631277945e-007, -4.594543650000001e-011, 2.659097549e-015}, bhigh = {-83500.1973, -24.648109}, R_s = R_NASA_2002/CrO3minus.MM);
          constant IdealGases.Common.DataRecord Cs(name = "Cs", MM = 0.13290545, Hf = 575597.1632465035, H0 = 46630.35263038498, Tlimit = 1000, alow = {54.6658407, -0.827934604, 2.50494221, -1.49462069e-005, 2.425976774e-008, -2.013172322e-011, 6.704271991e-015}, blow = {8459.321389999999, 6.848825772}, ahigh = {6166040.899999999, -18961.75522, 24.83229903, -0.01251977234, 3.30901739e-006, -3.35401202e-010, 9.626500908000001e-015}, bhigh = {128511.1231, -152.2942188}, R_s = R_NASA_2002/Cs.MM);
          constant IdealGases.Common.DataRecord Csplus(name = "Csplus", MM = 0.1329049014, Hf = 3449096.483058675, H0 = 46630.54510945222, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {54387.3782, 6.182757992}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {54387.3782, 6.182757992}, R_s = R_NASA_2002/Csplus.MM);
          constant IdealGases.Common.DataRecord Csminus(name = "Csminus", MM = 0.1329059986, Hf = 186577.1918589685, H0 = 46630.16015290675, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {2237.029001, 6.182770382}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {2237.029001, 6.182770382}, R_s = R_NASA_2002/Csminus.MM);
          constant IdealGases.Common.DataRecord CsBO2(name = "CsBO2", MM = 0.17571525, Hf = -3909176.386227149, H0 = 82326.91243361063, Tlimit = 1000, alow = {41936.0958, -666.4237400000001, 8.134835880000001, 0.002902960302, -7.88146792e-007, -8.327694539999999e-010, 4.44171911e-013}, blow = {-81223.2007, -11.21622595}, ahigh = {89755.79890000001, -1656.134283, 11.16468934, -0.000447636699, 9.621091809999999e-008, -1.081470115e-011, 4.93844674e-016}, bhigh = {-76104.79670000001, -30.36616012}, R_s = R_NASA_2002/CsBO2.MM);
          constant IdealGases.Common.DataRecord CsBr(name = "CsBr", MM = 0.21280945, Hf = -971897.0421661255, H0 = 48898.79185346327, Tlimit = 1000, alow = {1639.263647, -69.4747797, 4.86005872, -0.0008587780150000001, 1.37517755e-006, -9.89176698e-010, 2.895433432e-013}, blow = {-25895.50471, 4.46535569}, ahigh = {-152832.9963, 1259.712657, 1.704268408, 0.002776255318, -1.228389838e-006, 2.698111786e-010, -1.98353448e-014}, bhigh = {-33278.4203, 24.84116659}, R_s = R_NASA_2002/CsBr.MM);
          constant IdealGases.Common.DataRecord CsCL(name = "CsCL", MM = 0.16835845, Hf = -1438768.757968489, H0 = 60175.90444673255, Tlimit = 1000, alow = {-25381.65292, 297.2839326, 2.667813848, 0.00558327241, -8.52900509e-006, 6.595191390000001e-009, -1.989715823e-012}, blow = {-31892.5145, 15.11365709}, ahigh = {-3674923.48, 11861.52941, -10.63287842, 0.009804117919999999, -3.27779746e-006, 5.53423339e-010, -3.4012315e-014}, bhigh = {-104865.8658, 111.4096064}, R_s = R_NASA_2002/CsCL.MM);
          constant IdealGases.Common.DataRecord CsF(name = "CsF", MM = 0.1519038532, Hf = -2397667.184389764, H0 = 63494.87387460162, Tlimit = 1000, alow = {18436.85799, -404.240939, 6.38317886, -0.00467432337, 6.63013401e-006, -4.76090553e-009, 1.374569797e-012}, blow = {-43184.8959, -7.22659323}, ahigh = {-1850863.231, 5625.298800000001, -2.250022212, 0.00410924354, -1.250243837e-006, 1.941483152e-010, -1.071166179e-014}, bhigh = {-80798.2779, 51.3555945}, R_s = R_NASA_2002/CsF.MM);
          constant IdealGases.Common.DataRecord CsH(name = "CsH", MM = 0.13391339, Hf = 865858.9406182609, H0 = 66058.4128293668, Tlimit = 1000, alow = {16205.44411, -70.8701628, 2.480847135, 0.00702198599, -1.007126309e-005, 7.09063903e-009, -1.950395735e-012}, blow = {13427.77328, 9.89424717}, ahigh = {-911214.6649999999, 3576.47275, -1.258058765, 0.00431485515, -1.407820502e-006, 2.154598897e-010, -1.254525606e-014}, bhigh = {-9158.717270000001, 39.0880003}, R_s = R_NASA_2002/CsH.MM);
          constant IdealGases.Common.DataRecord CsI(name = "CsI", MM = 0.25980992, Hf = -586274.2769791085, H0 = 40607.09845105222, Tlimit = 1000, alow = {-4072.68565, 23.30073667, 4.38727769, 0.000341208429, -2.175588153e-007, 8.906786999999999e-011, -2.182639837e-015}, blow = {-19787.66885, 8.074657820000001}, ahigh = {4511259.05, -13417.06362, 19.80984712, -0.008359855550000002, 2.348201245e-006, -2.874285248e-010, 1.20808775e-014}, bhigh = {65734.3913, -102.1032592}, R_s = R_NASA_2002/CsI.MM);
          constant IdealGases.Common.DataRecord CsLi(name = "CsLi", MM = 0.13984645, Hf = 1159459.707414811, H0 = 73946.27464622805, Tlimit = 1000, alow = {1368.709568, -74.5129706, 4.84562093, -0.0005573667210000001, 4.95332676e-007, 4.36906891e-010, -4.60814577e-013}, blow = {18505.77392, 2.112012017}, ahigh = {7481630.23, -28852.97839, 46.3110499, -0.02784288108, 8.78741349e-006, -1.264901197e-009, 6.72018628e-014}, bhigh = {194513.7819, -285.7846194}, R_s = R_NASA_2002/CsLi.MM);
          constant IdealGases.Common.DataRecord CsNO2(name = "CsNO2", MM = 0.17891095, Hf = -1175667.716257725, H0 = 89319.13893476056, Tlimit = 1000, alow = {-71060.1044, 1272.448257, -2.447362349, 0.03064441948, -3.69922594e-005, 2.259121812e-008, -5.58063591e-012}, blow = {-33133.7092, 49.54693336}, ahigh = {-163350.3154, -846.8879579999999, 10.62853461, -0.0002508799215, 5.54125577e-008, -6.35559195e-012, 2.946880031e-016}, bhigh = {-24030.40739, -24.43488888}, R_s = R_NASA_2002/CsNO2.MM);
          constant IdealGases.Common.DataRecord CsNO3(name = "CsNO3", MM = 0.19491035, Hf = -1634014.76627588, H0 = 84980.65905684332, Tlimit = 1000, alow = {-26772.19779, 901.169269, -3.26534082, 0.04298377699999999, -5.38675138e-005, 3.38452752e-008, -8.56522366e-012}, blow = {-44053.0414, 51.18862689}, ahigh = {-314751.7676, -1367.011655, 14.01012848, -0.000401864713, 8.8536147e-008, -1.013466457e-011, 4.69175873e-016}, bhigh = {-35490.2667, -45.00692791}, R_s = R_NASA_2002/CsNO3.MM);
          constant IdealGases.Common.DataRecord CsNa(name = "CsNa", MM = 0.15589522, Hf = 807640.7281762712, H0 = 68649.50060688198, Tlimit = 1000, alow = {25217.38609, -429.5362489999999, 7.22309474, -0.008460463000000001, 1.443905157e-005, -1.143624855e-008, 3.18372193e-012}, blow = {15790.99265, -8.838790299999999}, ahigh = {3879556.79, -17801.67288, 34.913558, -0.02320080793, 7.861975840000001e-006, -1.171011257e-009, 6.323927369999999e-014}, bhigh = {119577.6556, -200.1754433}, R_s = R_NASA_2002/CsNa.MM);
          constant IdealGases.Common.DataRecord CsO(name = "CsO", MM = 0.14890485, Hf = 252425.0754760506, H0 = 66049.68206206849, Tlimit = 1000, alow = {8683.95881, 425.027817, -3.4840553, 0.0380196983, -6.651927559999999e-005, 5.17347219e-008, -1.512567066e-011}, blow = {1969.690015, 42.4079614}, ahigh = {837554.4350000001, -2418.205772, 8.908065349999999, -0.00337818004, 1.312755917e-006, -2.150508925e-010, 1.21913898e-014}, bhigh = {18094.93447, -24.6085858}, R_s = R_NASA_2002/CsO.MM);
          constant IdealGases.Common.DataRecord CsOH(name = "CsOH", MM = 0.14991279, Hf = -1707659.499899908, H0 = 78943.82460629277, Tlimit = 1000, alow = {9386.960789999999, -500.935426, 8.30135198, -0.00323559684, 2.612406777e-006, -4.95061341e-010, -1.038364927e-013}, blow = {-30257.22427, -17.42194837}, ahigh = {896717.113, -2323.978587, 7.95964487, 0.0001101149275, -6.466013969999999e-008, 1.045968201e-011, -5.82251417e-016}, bhigh = {-17362.58234, -18.64239624}, R_s = R_NASA_2002/CsOH.MM);
          constant IdealGases.Common.DataRecord CsRb(name = "CsRb", MM = 0.21837325, Hf = 510489.8699817858, H0 = 50244.85370804345, Tlimit = 1000, alow = {-4910.92268, -9.20901555, 5.19337789, -0.00439024699, 1.254790436e-005, -1.414878514e-008, 5.10144131e-012}, blow = {12004.98171, 5.36154293}, ahigh = {-13286933.78, 34145.7947, -23.73696406, 0.0070704654, 3.86345097e-007, -3.158132986e-010, 2.667747207e-014}, bhigh = {-212400.8997, 223.9970251}, R_s = R_NASA_2002/CsRb.MM);
          constant IdealGases.Common.DataRecord Cs2(name = "Cs2", MM = 0.2658109, Hf = 411587.083148208, H0 = 41492.40305796338, Tlimit = 1000, alow = {-46741.5873, 595.201951, 1.895333975, 0.00408206581, 2.531487119e-006, -9.085139030000001e-009, 4.29017993e-012}, blow = {8857.282570000001, 23.91592727}, ahigh = {-25927395.9, 75398.1891, -74.840868, 0.0369286679, -8.08249724e-006, 8.171850729999999e-010, -3.0892859e-014}, bhigh = {-471504.572, 586.093375}, R_s = R_NASA_2002/Cs2.MM);
          constant IdealGases.Common.DataRecord Cs2Br2(name = "Cs2Br2", MM = 0.4256189, Hf = -1329426.08751632, H0 = 51955.23507062304, Tlimit = 1000, alow = {-6321.28518, -12.13153529, 10.04967112, -0.0001102100044, 1.365293456e-007, -8.85695707e-011, 2.339447704e-014}, blow = {-70997.71709999999, -7.53942479}, ahigh = {-7545.84665, -0.2087093009, 10.00018042, -8.03426073e-008, 1.923604258e-011, -2.34469814e-015, 1.139365834e-019}, bhigh = {-71058.8354, -7.25179304}, R_s = R_NASA_2002/Cs2Br2.MM);
          constant IdealGases.Common.DataRecord Cs2CO3(name = "Cs2CO3", MM = 0.3258198, Hf = -2475134.841406201, H0 = 65002.37554623753, Tlimit = 1000, alow = {-46731.3, 943.6549060000001, -0.2374670436, 0.0416848461, -5.09437221e-005, 3.132078394e-008, -7.78042167e-012}, blow = {-103916.2411, 40.55853980000001}, ahigh = {-303714.9985, -1517.0784, 17.11941656, -0.000444970012, 9.798325240000001e-008, -1.121256063e-011, 5.189734780000001e-016}, bhigh = {-94204.1477, -56.8200626}, R_s = R_NASA_2002/Cs2CO3.MM);
          constant IdealGases.Common.DataRecord Cs2CL2(name = "Cs2CL2", MM = 0.3367169, Hf = -1914541.260031796, H0 = 62202.73470087186, Tlimit = 1000, alow = {-10779.56357, -53.4610695, 10.21710683, -0.000478968703, 5.90894653e-007, -3.82141652e-010, 1.006995985e-013}, blow = {-80295.1517, -12.07856486}, ahigh = {-16251.43966, -0.900613735, 10.00077173, -3.41619408e-007, 8.14496808e-011, -9.897475279999999e-015, 4.79833081e-019}, bhigh = {-80565.13219999999, -10.81977337}, R_s = R_NASA_2002/Cs2CL2.MM);
          constant IdealGases.Common.DataRecord Cs2F2(name = "Cs2F2", MM = 0.3038077064, Hf = -2935601.985111462, H0 = 63818.65762968019, Tlimit = 1000, alow = {-9942.67748, -253.6723355, 11.00684073, -0.002185640152, 2.664791874e-006, -1.708229209e-009, 4.47115198e-013}, blow = {-109058.2601, -20.00699602}, ahigh = {-36779.4642, -4.35575348, 10.00366687, -1.603814186e-006, 3.79146974e-010, -4.57868743e-014, 2.209385787e-018}, bhigh = {-110345.6448, -14.15086452}, R_s = R_NASA_2002/Cs2F2.MM);
          constant IdealGases.Common.DataRecord Cs2I2(name = "Cs2I2", MM = 0.5196198399999999, Hf = -873779.3710879093, H0 = 43464.2815024153, Tlimit = 1000, alow = {-4449.28697, -5.32179366, 10.02183919, -4.85337485e-005, 6.019338399999999e-008, -3.90822639e-011, 1.032981014e-014}, blow = {-57578.2338, -5.27126709}, ahigh = {-4983.37601, -0.09461179879999999, 10.00008229, -3.68096204e-008, 8.844660910000001e-012, -1.081178562e-015, 5.26614198e-020}, bhigh = {-57605.01040000001, -5.14486489}, R_s = R_NASA_2002/Cs2I2.MM);
          constant IdealGases.Common.DataRecord Cs2O(name = "Cs2O", MM = 0.2818103, Hf = -506920.240317689, H0 = 49997.65799901566, Tlimit = 1000, alow = {19105.33804, -496.218153, 8.7596063, -0.00351162279, 4.01647983e-006, -2.450899853e-009, 6.17240489e-013}, blow = {-16776.64956, -11.59258822}, ahigh = {-41191.4741, -10.79255391, 7.00850047, -3.54295578e-006, 8.08169912e-010, -9.499419930000001e-014, 4.48912254e-018}, bhigh = {-19343.7785, -1.20397045}, R_s = R_NASA_2002/Cs2O.MM);
          constant IdealGases.Common.DataRecord Cs2Oplus(name = "Cs2Oplus", MM = 0.2818097514, Hf = 1006707.271805216, H0 = 51267.65815670069, Tlimit = 1000, alow = {683.705609, -243.5575007, 7.78303747, -0.001414552725, 1.470799739e-006, -8.218821330000001e-010, 1.911749489e-013}, blow = {33241.9487, -4.75042356}, ahigh = {-31530.85844, -5.77155903, 7.00448263, -1.848241331e-006, 4.1808823e-010, -4.88237627e-014, 2.295419936e-018}, bhigh = {31962.2731, -0.0543435069}, R_s = R_NASA_2002/Cs2Oplus.MM);
          constant IdealGases.Common.DataRecord Cs2O2(name = "Cs2O2", MM = 0.2978097, Hf = -829620.7410302619, H0 = 58515.54197193711, Tlimit = 1000, alow = {22745.0518, -566.7912570000001, 10.01728332, 0.002547081016, -4.90921669e-006, 3.84878891e-009, -1.124566008e-012}, blow = {-29473.3436, -18.41275291}, ahigh = {-119003.2094, -92.6107526, 10.06915777, -2.766227147e-005, 6.11075296e-009, -7.003595480000001e-013, 3.24374252e-017}, bhigh = {-32556.1074, -17.24868948}, R_s = R_NASA_2002/Cs2O2.MM);
          constant IdealGases.Common.DataRecord Cs2O2H2(name = "Cs2O2H2", MM = 0.29982558, Hf = -2177932.916864532, H0 = 79837.59424396011, Tlimit = 1000, alow = {-10859.81041, -688.306842, 16.43543354, -0.00403922058, 2.331117156e-006, 8.43965163e-010, -6.85930973e-013}, blow = {-79394.7623, -49.0619681}, ahigh = {1802857.941, -4656.35475, 16.93566597, 0.0002117402535, -1.272249096e-007, 2.066555839e-011, -1.152390667e-015}, bhigh = {-51908.1369, -58.4971916}, R_s = R_NASA_2002/Cs2O2H2.MM);
          constant IdealGases.Common.DataRecord Cs2SO4(name = "Cs2SO4", MM = 0.3618735, Hf = -3088515.279510658, H0 = 66288.81639578473, Tlimit = 1000, alow = {61536.3787, -638.137433, 6.89477209, 0.0396018291, -5.529862010000001e-005, 3.73633252e-008, -9.973241829999999e-012}, blow = {-133976.031, -1.284432588}, ahigh = {-522339.752, -944.415525, 19.70476453, -0.000282122599, 6.240792279999999e-008, -7.16346407e-012, 3.32266719e-016}, bhigh = {-136417.9983, -68.20406795}, R_s = R_NASA_2002/Cs2SO4.MM);
          constant IdealGases.Common.DataRecord Cu(name = "Cu", MM = 0.06354600000000001, Hf = 5309539.54615554, H0 = 97526.64211752116, Tlimit = 1000, alow = {77.1313315, -1.169236206, 2.506987803, -2.116434879e-005, 3.44171471e-008, -2.862608999e-011, 9.559250991000001e-015}, blow = {39839.8121, 5.73081322}, ahigh = {2308090.411, -8503.261, 14.67859102, -0.00846713652, 2.887821016e-006, -4.27065918e-010, 2.304265084e-014}, bhigh = {92075.3562, -78.5470156}, R_s = R_NASA_2002/Cu.MM);
          constant IdealGases.Common.DataRecord Cuplus(name = "Cuplus", MM = 0.06354545139999999, Hf = 17138594.56508637, H0 = 97527.48408362082, Tlimit = 1000, alow = {-0.002452340093, 2.606893531e-005, 2.49999989, 2.351922485e-010, -2.669362382e-013, 1.510315123e-016, -3.278224814e-020}, blow = {130240.0621, 5.07594077}, ahigh = {-2181443.016, 7217.85819, -6.94115475, 0.00620824892, -2.139340497e-006, 3.56643144e-010, -2.081198501e-014}, bhigh = {85164.56659999999, 71.16800670000001}, R_s = R_NASA_2002/Cuplus.MM);
          constant IdealGases.Common.DataRecord Cuminus(name = "Cuminus", MM = 0.0635465486, Hf = 3347445.812344244, H0 = 97525.80016595896, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {24838.64954, 5.07596603}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {24838.64954, 5.07596603}, R_s = R_NASA_2002/Cuminus.MM);
          constant IdealGases.Common.DataRecord CuCL(name = "CuCL", MM = 0.09899899999999999, Hf = 920110.3041444863, H0 = 95669.40070101718, Tlimit = 1000, alow = {14698.47736, -339.316725, 5.72345959, -0.002417296132, 2.858019864e-006, -1.757900548e-009, 4.455047290000001e-013}, blow = {11317.14015, -4.527352594}, ahigh = {-25771.2241, -7.10634606, 4.50562318, 5.39454827e-005, 5.38641796e-010, -6.348482770000001e-014, 3.006622062e-018}, bhigh = {9566.192870000001, 2.680067564}, R_s = R_NASA_2002/CuCL.MM);
          constant IdealGases.Common.DataRecord CuF(name = "CuF", MM = 0.08254440320000001, Hf = -152039.3813932136, H0 = 110038.847552053, Tlimit = 1000, alow = {37613.8541, -546.8104900000001, 5.83235172, -0.001695312068, 1.21815088e-006, -3.71328528e-010, 2.002276589e-014}, blow = {58.6514072, -7.15693009}, ahigh = {509415.483, -1415.00987, 5.63234938, -0.000162912841, -1.156611499e-007, 5.06603408e-011, -4.15320511e-015}, bhigh = {6305.506600000001, -7.40777361}, R_s = R_NASA_2002/CuF.MM);
          constant IdealGases.Common.DataRecord CuF2(name = "CuF2", MM = 0.1015428064, Hf = -2628842.056506328, H0 = 118727.3665897026, Tlimit = 1000, alow = {65733.1128, -896.243084, 7.91756094, 0.001345667904, -4.16240001e-006, 3.71618109e-009, -1.155537597e-012}, blow = {-29168.87325, -15.87076153}, ahigh = {-1650355.082, 3775.36212, 3.88911655, 0.000682191264, 1.875979026e-007, -5.67736811e-011, 3.82324873e-015}, bhigh = {-59533.717, 15.22659664}, R_s = R_NASA_2002/CuF2.MM);
          constant IdealGases.Common.DataRecord CuO(name = "CuO", MM = 0.0795454, Hf = 3850254.068745647, H0 = 122583.317199989, Tlimit = 1000, alow = {4689.76224, -118.4808464, 4.56615524, 0.000430905802, -8.309886399999999e-007, 6.94663802e-010, -2.108693366e-013}, blow = {36151.9068, 1.733847344}, ahigh = {358228.017, -913.9366409999999, 5.13689867, 6.240577240000001e-005, -1.558613495e-007, 5.23680312e-011, -4.026745619999999e-015}, bhigh = {41507.9286, -2.63407096}, R_s = R_NASA_2002/CuO.MM);
          constant IdealGases.Common.DataRecord Cu2(name = "Cu2", MM = 0.127092, Hf = 3818808.422245302, H0 = 78133.58826676737, Tlimit = 1000, alow = {-852.918348, -97.2004493, 4.8822337, -0.00073713694, 1.000575401e-006, -6.391989439999999e-010, 1.668655797e-013}, blow = {57493.0702, 1.105391325}, ahigh = {-86993.995, 320.910387, 3.97380288, 0.000508080967, -1.707470385e-007, 3.21910819e-011, -1.958830868e-015}, bhigh = {55060.9019, 6.91450217}, R_s = R_NASA_2002/Cu2.MM);
          constant IdealGases.Common.DataRecord Cu3CL3(name = "Cu3CL3", MM = 0.296997, Hf = -870614.854695502, H0 = 96713.73784920386, Tlimit = 1000, alow = {4487.88532, -873.6644439999999, 19.36189091, -0.00713744786, 8.56045487e-006, -5.419978740000001e-009, 1.40517535e-012}, blow = {-31626.8996, -59.76797945000001}, ahigh = {-91885.59679999999, -15.7193643, 16.0129417, -5.57299237e-006, 1.302748507e-009, -1.560175322e-013, 7.48082757e-018}, bhigh = {-36087.6074, -40.13211395}, R_s = R_NASA_2002/Cu3CL3.MM);
          constant IdealGases.Common.DataRecord D(name = "D", MM = 0.002014102, Hf = 110083912.3341321, H0 = 3077017.946459514, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {25921.287, 0.591714338}, ahigh = {60.50019210000001, -0.1810766064, 2.500210817, -1.220711706e-007, 3.71517217e-011, -5.66068021e-015, 3.393920393e-019}, bhigh = {25922.43752, 0.590212537}, R_s = R_NASA_2002/D.MM);
          constant IdealGases.Common.DataRecord Dplus(name = "Dplus", MM = 0.0020135534, Hf = 764978136.6612874, H0 = 3077856.291270944, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {184512.0037, -0.1018414521}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {184512.0037, -0.1018414521}, R_s = R_NASA_2002/Dplus.MM);
          constant IdealGases.Common.DataRecord Dminus(name = "Dminus", MM = 0.0020146506, Hf = 70857312.92562591, H0 = 3076180.058219525, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {16423.73393, -0.1010243437}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {16423.73393, -0.1010243437}, R_s = R_NASA_2002/Dminus.MM);
          constant IdealGases.Common.DataRecord DBr(name = "DBr", MM = 0.08191810200000001, Hf = -452116.1391166021, H0 = 105814.2680112388, Tlimit = 1000, alow = {-19182.82458, 202.0175399, 3.044629038, -0.00148815745, 6.8708978e-006, -6.59116028e-009, 2.093769216e-012}, blow = {-6560.0744, 8.008690039999999}, ahigh = {665400.044, -2594.092228, 6.8858794, -0.001103284901, 2.894201105e-007, -3.152037514e-011, 1.011011776e-015}, bhigh = {10378.1314, -19.73703653}, R_s = R_NASA_2002/DBr.MM);
          constant IdealGases.Common.DataRecord DCL(name = "DCL", MM = 0.037467102, Hf = -2496777.119297884, H0 = 231165.5702648153, Tlimit = 1000, alow = {10464.21033, -231.3813446, 5.42069326, -0.007508012650000001, 1.398672495e-005, -1.066249569e-008, 3.011167635e-012}, blow = {-11284.03374, -6.711842349}, ahigh = {411728.4899999999, -1764.535217, 5.6688771, -0.000347596417, 5.88268803e-008, 3.76025313e-013, -5.16460056e-016}, bhigh = {-1541.258092, -12.75659404}, R_s = R_NASA_2002/DCL.MM);
          constant IdealGases.Common.DataRecord DF(name = "DF", MM = 0.0210125052, Hf = -13145866.87169505, H0 = 411093.4854164842, Tlimit = 1000, alow = {57213.7075, -731.17338, 7.22087087, -0.00942396935, 1.208025139e-005, -6.94181269e-009, 1.538525476e-012}, blow = {-30692.30024, -19.32760992}, ahigh = {800117.2800000001, -2438.386832, 5.62066445, -0.0002020416838, 1.714418979e-008, 2.697462563e-012, -2.88829741e-016}, bhigh = {-18574.47029, -14.73004444}, R_s = R_NASA_2002/DF.MM);
          constant IdealGases.Common.DataRecord DOCL(name = "DOCL", MM = 0.053466502, Hf = -1487635.865910959, H0 = 193108.0884999733, Tlimit = 1000, alow = {68528.3429, -767.344455, 5.93397014, 0.002868820667, -5.207166370000001e-006, 4.927572739999999e-009, -1.709526276e-012}, blow = {-6824.03505, -7.757833983}, ahigh = {604306.633, -2646.500381, 8.61247421, -0.0005532268239999999, 1.086845232e-007, -1.13738129e-011, 4.90429552e-016}, bhigh = {4845.79518, -25.88861801}, R_s = R_NASA_2002/DOCL.MM);
          constant IdealGases.Common.DataRecord DO2(name = "DO2", MM = 0.034012902, Hf = 190731.8581637051, H0 = 295927.2337303062, Tlimit = 1000, alow = {-21114.79735, 602.337175, -1.294877674, 0.0181294797, -2.161807666e-005, 1.391729127e-008, -3.69774028e-012}, blow = {-2976.943856, 32.7283448}, ahigh = {-1267224.927, 2799.947016, 2.325174609, 0.00272632507, -6.31450732e-007, 6.7292892e-011, -2.765192818e-015}, bhigh = {-19594.11733, 17.89922833}, R_s = R_NASA_2002/DO2.MM);
          constant IdealGases.Common.DataRecord DO2minus(name = "DO2minus", MM = 0.0340134506, Hf = -3081002.019830355, H0 = 296350.11509241, Tlimit = 1000, alow = {104870.5051, -890.6236769999999, 5.66655356, 0.001904603784, -1.21526321e-006, 6.57751333e-010, -2.147376147e-013}, blow = {-8942.37725, -7.7972192}, ahigh = {552766.192, -2796.895783, 8.772206669999999, -0.0006291116630000001, 1.272331622e-007, -1.364440687e-011, 6.00519944e-016}, bhigh = {2512.066767, -28.90020381}, R_s = R_NASA_2002/DO2minus.MM);
          constant IdealGases.Common.DataRecord D2(name = "D2", MM = 0.004028204, Hf = 0, H0 = 2127276.324634999, Tlimit = 1000, alow = {21257.90482, -299.6945907, 5.13031498, -0.004172970890000001, 5.014345719999999e-006, -2.126389969e-009, 2.386536969e-013}, blow = {394.49859, -11.64191209}, ahigh = {821516.856, -2365.623159, 5.34297451, 6.92814599e-005, -8.52367102e-008, 2.456447415e-011, -1.960597698e-015}, bhigh = {14342.14587, -17.12600356}, R_s = R_NASA_2002/D2.MM);
          constant IdealGases.Common.DataRecord D2plus(name = "D2plus", MM = 0.004027655400000001, Hf = 372069647.517511, H0 = 2147899.743359374, Tlimit = 1000, alow = {-96409.59090000001, 1243.052385, -2.557714366, 0.01343064234, -1.285600289e-005, 6.46342167e-009, -1.337616868e-012}, blow = {173096.6171, 33.5631492}, ahigh = {925595.135, -4505.21994, 11.03203365, -0.00470608903, 1.83806846e-006, -3.135924623e-010, 1.857684975e-014}, bhigh = {205829.889, -52.8391224}, R_s = R_NASA_2002/D2plus.MM);
          constant IdealGases.Common.DataRecord D2minus(name = "D2minus", MM = 0.004028752599999999, Hf = 58370578.77418436, H0 = 2162915.389741232, Tlimit = 1000, alow = {-4365.33206, 311.2987057, 0.548195003, 0.009956988109999999, -1.167000612e-005, 6.97565641e-009, -1.682718179e-012}, blow = {25978.97625, 14.42223161}, ahigh = {-57988.05190000001, -312.2959355, 4.73038828, 5.6959008e-005, 2.01897543e-008, -2.311492448e-012, 1.070266527e-016}, bhigh = {28512.00896, -9.15752792}, R_s = R_NASA_2002/D2minus.MM);
          constant IdealGases.Common.DataRecord D2O(name = "D2O", MM = 0.020027604, Hf = -12443325.72183872, H0 = 497314.4565870186, Tlimit = 1000, alow = {6958.27847, -12.80889437, 3.59587887, 0.001502093683, 3.59467505e-007, 5.3404172e-010, -5.18194127e-013}, blow = {-31019.44566, 2.895556576}, ahigh = {1544193.253, -5474.238899999999, 10.17542424, -0.0009619415540000001, 2.036545675e-007, -2.050566442e-011, 8.510770689999999e-016}, bhigh = {2983.24898, -44.6501157}, R_s = R_NASA_2002/D2O.MM);
          constant IdealGases.Common.DataRecord D2O2(name = "D2O2", MM = 0.036027004, Hf = -4005328.891628069, H0 = 321026.9441222478, Tlimit = 1000, alow = {29577.11324, -68.9303757, 2.043905473, 0.01570281822, -1.935478714e-005, 1.384941336e-008, -4.1041849e-012}, blow = {-18025.02679, 13.47156482}, ahigh = {1147867.936, -5225.76093, 13.11088701, -0.001179811896, 2.729336904e-007, -2.961433535e-011, 1.310306129e-015}, bhigh = {12195.80532, -56.905382}, R_s = R_NASA_2002/D2O2.MM);
          constant IdealGases.Common.DataRecord D2S(name = "D2S", MM = 0.036093204, Hf = -665126.5983479882, H0 = 279513.9217898196, Tlimit = 1000, alow = {3988.38648, -66.2079256, 4.39335445, -0.002325113084, 1.189503465e-005, -1.146524521e-008, 3.62619045e-012}, blow = {-3787.38555, 0.9238754374999999}, ahigh = {423581.463, -2823.776231, 8.96282184, -0.000646923123, 1.634615644e-007, -1.797991376e-011, 8.16093957e-016}, bhigh = {12046.03509, -31.91047376}, R_s = R_NASA_2002/D2S.MM);
          constant IdealGases.Common.DataRecord eminus(name = "eminus", MM = 5.48579903e-007, Hf = 0, H0 = 11297220270.20738, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {-745.375, -11.72081224}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {-745.375, -11.72081224}, R_s = R_NASA_2002/eminus.MM);
          constant IdealGases.Common.DataRecord F(name = "F", MM = 0.0189984032, Hf = 4178245.885422623, H0 = 343105.677428722, Tlimit = 1000, alow = {1137.409088, -145.3392797, 4.07740361, -0.004303360139999999, 5.72889774e-006, -3.8193129e-009, 1.018322509e-012}, blow = {9311.110120000001, -3.55898265}, ahigh = {14735.06226, 81.4992736, 2.444371819, 2.120210026e-005, -4.54691862e-009, 5.10952873e-013, -2.333894647e-017}, bhigh = {8388.37465, 5.47871064}, R_s = R_NASA_2002/F.MM);
          constant IdealGases.Common.DataRecord Fplus(name = "Fplus", MM = 0.0189978546, Hf = 93000834.52581009, H0 = 353236.3070091083, Tlimit = 1000, alow = {-38716.8019, 321.881566, 2.200920452, -0.0002455492688, 7.85835506e-007, -6.43598792e-010, 1.839793564e-013}, blow = {209883.0937, 7.81699924}, ahigh = {16496.35664, 133.7351478, 2.332522942, 0.0001215277877, -4.8010377e-008, 9.027225149999999e-012, -5.47066494e-016}, bhigh = {211074.5327, 6.62581709}, R_s = R_NASA_2002/Fplus.MM);
          constant IdealGases.Common.DataRecord Fminus(name = "Fminus", MM = 0.0189989518, Hf = -13426639.25280341, H0 = 326198.4169042421, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {-31425.72443, 3.26488271}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {-31425.72443, 3.26488271}, R_s = R_NASA_2002/Fminus.MM);
          constant IdealGases.Common.DataRecord FCN(name = "FCN", MM = 0.0450158032, Hf = 762573.3977795602, H0 = 225008.9808460865, Tlimit = 1000, alow = {39844.5412, -698.865536, 7.05883966, -0.001404863382, 3.96465251e-006, -3.045609294e-009, 7.9230459e-013}, blow = {6172.627570000001, -15.05643174}, ahigh = {398187.355, -2302.971079, 9.027081389999999, -0.000522871026, 1.191059272e-007, -1.280287231e-011, 5.73380719e-016}, bhigh = {15884.49451, -29.84971982}, R_s = R_NASA_2002/FCN.MM);
          constant IdealGases.Common.DataRecord FCO(name = "FCO", MM = 0.0470085032, Hf = -3816716.929629871, H0 = 220980.3395739688, Tlimit = 1000, alow = {11326.62744, -53.979185, 2.966927601, 0.00755995935, -6.21177358e-006, 2.40378155e-009, -3.36950775e-013}, blow = {-22403.69579, 10.92652142}, ahigh = {-60858.5158, -1022.397533, 7.52732256, -0.0001057942328, -1.365311093e-009, 2.484612871e-012, -9.9979168e-017}, bhigh = {-18050.98416, -16.30331278}, R_s = R_NASA_2002/FCO.MM);
          constant IdealGases.Common.DataRecord FO(name = "FO", MM = 0.0349978032, Hf = 3114826.932908749, H0 = 268245.4080432112, Tlimit = 1000, alow = {-39121.8244, 796.703694, -1.634777767, 0.01601810071, -2.095210771e-005, 1.382740666e-008, -3.66452495e-012}, blow = {8375.525229999999, 33.83325720000001}, ahigh = {-1597940.503, 4377.376380000001, -0.489750764, 0.002682336321, -6.90080485e-007, 7.24647968e-011, -2.726912632e-015}, bhigh = {-16442.48211, 35.5992361}, R_s = R_NASA_2002/FO.MM);
          constant IdealGases.Common.DataRecord FO2_FOO(name = "FO2_FOO", MM = 0.0509972032, Hf = 498066.529264099, H0 = 220714.2998775274, Tlimit = 1000, alow = {5821.564, -234.7363967, 5.43733876, 0.002165855252, 3.67147219e-007, -2.071530827e-009, 9.43106685e-013}, blow = {2694.856027, -1.168202057}, ahigh = {-1213166.895, 2493.397189, 4.46506574, 0.0009416104040000001, -6.426472259999999e-008, -1.085643277e-011, 1.216995394e-015}, bhigh = {-15968.00286, 8.65519318}, R_s = R_NASA_2002/FO2_FOO.MM);
          constant IdealGases.Common.DataRecord FO2_OFO(name = "FO2_OFO", MM = 0.0509972032, Hf = 7423936.534621569, H0 = 206646.2734960336, Tlimit = 1000, alow = {-77341.064, 1663.800209, -9.61281516, 0.04989156870000001, -6.94621713e-005, 4.7077878e-008, -1.258890729e-011}, blow = {36970.9273, 77.9594304}, ahigh = {-621186.7340000001, 936.947459, 6.40155875, 0.0002136110846, -4.33797765e-008, 4.66731224e-012, -2.059767432e-016}, bhigh = {36383.5727, -6.15026433}, R_s = R_NASA_2002/FO2_OFO.MM);
          constant IdealGases.Common.DataRecord F2(name = "F2", MM = 0.0379968064, Hf = 0, H0 = 232259.1511269747, Tlimit = 1000, alow = {10181.76308, 22.74241183, 1.97135304, 0.008151604010000001, -1.14896009e-005, 7.95865253e-009, -2.167079526e-012}, blow = {-958.6943, 11.30600296}, ahigh = {-2941167.79, 9456.5977, -7.73861615, 0.00764471299, -2.241007605e-006, 2.915845236e-010, -1.425033974e-014}, bhigh = {-60710.0561, 84.23835080000001}, R_s = R_NASA_2002/F2.MM);
          constant IdealGases.Common.DataRecord F2O(name = "F2O", MM = 0.0539962064, Hf = 453735.5794684124, H0 = 202079.4001557858, Tlimit = 1000, alow = {30829.19995, -229.9506259, 2.603805825, 0.01586111264, -2.345633734e-005, 1.679619314e-008, -4.70356033e-012}, blow = {3055.185332, 10.50933022}, ahigh = {-188537.4518, -210.0729689, 7.15123916, 0.0001327687906, 1.804705706e-008, -1.416973671e-012, 6.489389390000001e-017}, bhigh = {1449.129965, -12.57858336}, R_s = R_NASA_2002/F2O.MM);
          constant IdealGases.Common.DataRecord F2O2(name = "F2O2", MM = 0.06999560639999999, Hf = 274302.9311051158, H0 = 196847.3981246915, Tlimit = 1000, alow = {56122.70460000001, -998.595223, 8.98064939, 0.00642190087, -9.88851602e-006, 6.85806101e-009, -1.842137493e-012}, blow = {5298.71259, -22.39292195}, ahigh = {-219056.3532, -391.092081, 10.29107144, -0.0001163345202, 2.570922521e-008, -2.949199983e-012, 1.367386916e-016}, bhigh = {827.8020939999999, -27.56752555}, R_s = R_NASA_2002/F2O2.MM);
          constant IdealGases.Common.DataRecord FS2F(name = "FS2F", MM = 0.1021268064, Hf = -3294286.895472725, H0 = 142913.5063994325, Tlimit = 1000, alow = {114446.228, -1853.247564, 13.94098518, -0.00404368937, 1.370970316e-006, 6.7119031e-010, -4.624954960000001e-013}, blow = {-33510.6833, -48.49215357}, ahigh = {-207709.7921, -109.4539831, 10.08136946, -3.23953791e-005, 7.12522527e-009, -8.13478741e-013, 3.75502241e-017}, bhigh = {-43494.4606, -23.46916058}, R_s = R_NASA_2002/FS2F.MM);
          constant IdealGases.Common.DataRecord Fe(name = "Fe", MM = 0.055845, Hf = 7439717.07404423, H0 = 122666.7920136091, Tlimit = 1000, alow = {67908.2266, -1197.218407, 9.84339331, -0.01652324828, 1.917939959e-005, -1.149825371e-008, 2.832773807e-012}, blow = {54669.9594, -33.8394626}, ahigh = {-1954923.682, 6737.161099999999, -5.48641097, 0.004378803450000001, -1.116286672e-006, 1.544348856e-010, -8.023578182e-015}, bhigh = {7137.37006, 65.0497986}, R_s = R_NASA_2002/Fe.MM);
          constant IdealGases.Common.DataRecord Feplus(name = "Feplus", MM = 0.0558444514, Hf = 21205649.25094779, H0 = 124197.6387290645, Tlimit = 1000, alow = {-56912.3162, 184.713439, 4.19697212, -0.00597827597, 1.054267912e-005, -8.059804319999999e-009, 2.256925874e-012}, blow = {140120.6571, -0.360254258}, ahigh = {-817645.009, 1925.359408, 1.717387154, 0.000338533898, -9.813533120000001e-008, 2.228179208e-011, -1.483964439e-015}, bhigh = {128635.2466, 15.00256262}, R_s = R_NASA_2002/Feplus.MM);
          constant IdealGases.Common.DataRecord Fe_CO_5(name = "Fe_CO_5", MM = 0.1958955, Hf = -3715501.377009681, H0 = 169199.3894704064, Tlimit = 1000, alow = {379780.571, -7285.92816, 54.0023618, -0.06935400750000001, 0.0001026705717, -7.20737313e-008, 1.958981996e-011}, blow = {-58545.8048, -260.4377836}, ahigh = {1116600.852, -8067.07473, 36.5294241, -0.0020471903, 4.44196775e-007, -4.93250713e-011, 2.235704865e-015}, bhigh = {-48606.6125, -175.4566113}, R_s = R_NASA_2002/Fe_CO_5.MM);
          constant IdealGases.Common.DataRecord FeCL(name = "FeCL", MM = 0.091298, Hf = 2749676.882297531, H0 = 113662.435102631, Tlimit = 1000, alow = {11173.40353, -54.0214429, 3.48605792, 0.00687983714, -1.273679557e-005, 1.025321859e-008, -3.051544011e-012}, blow = {29286.8199, 9.428962979}, ahigh = {528870.022, -1282.897413, 5.79844169, -0.0002896589776, 3.34390381e-008, -1.469606582e-013, -1.213444602e-016}, bhigh = {37261.9673, -4.075134191}, R_s = R_NASA_2002/FeCL.MM);
          constant IdealGases.Common.DataRecord FeCL2(name = "FeCL2", MM = 0.126751, Hf = -1112423.570622717, H0 = 112640.8312360455, Tlimit = 1000, alow = {23011.21607, -585.804406, 9.322903480000001, -0.003006298824, 2.590788666e-006, -1.080178662e-009, 2.341239608e-013}, blow = {-16210.41276, -18.16752393}, ahigh = {164412.3697, 692.800269, 4.63827014, 0.002754339782, -8.624218250000001e-007, 1.170827576e-010, -5.93806195e-015}, bhigh = {-22197.21855, 11.16897701}, R_s = R_NASA_2002/FeCL2.MM);
          constant IdealGases.Common.DataRecord FeCL3(name = "FeCL3", MM = 0.162204, Hf = -6529458.509038001, H0 = 112291.1457177382, Tlimit = 1000, alow = {4284.772099999999, -574.170537, 12.20667256, -0.00468043412, 5.609500470000001e-006, -3.5495995e-009, 9.198543490000001e-013}, blow = {-127568.8456, -28.87584081}, ahigh = {-59157.40590000001, -10.33382228, 10.00849967, -3.65765187e-006, 8.545873639999999e-010, -1.023070527e-013, 4.90406364e-018}, bhigh = {-130501.205, -15.98494171}, R_s = R_NASA_2002/FeCL3.MM);
          constant IdealGases.Common.DataRecord FeO(name = "FeO", MM = 0.07184439999999999, Hf = 3494218.060141083, H0 = 123002.363440992, Tlimit = 1000, alow = {15692.82213, -64.6018888, 2.45892547, 0.00701604736, -1.021405947e-005, 7.179297870000001e-009, -1.978966365e-012}, blow = {29645.72665, 13.26115545}, ahigh = {-119597.148, -362.486478, 5.51888075, -0.0009978856889999999, 4.37691383e-007, -6.79062946e-011, 3.63929268e-015}, bhigh = {30379.85806, -3.63365542}, R_s = R_NASA_2002/FeO.MM);
          constant IdealGases.Common.DataRecord Fe_OH_2(name = "Fe_OH_2", MM = 0.08985968, Hf = -3678357.189787456, H0 = 158129.4413690323, Tlimit = 1000, alow = {444302.72, -6795.14089, 38.9472621, -0.0597300568, 7.046165430000001e-005, -4.087859510000001e-008, 9.368766340000001e-012}, blow = {-9051.42086, -193.1304058}, ahigh = {1612519.19, -6533.24199, 18.42922816, -0.002073249635, 4.26587436e-007, -4.56406313e-011, 1.990105746e-015}, bhigh = {-2992.568633, -84.45940589999999}, R_s = R_NASA_2002/Fe_OH_2.MM);
          constant IdealGases.Common.DataRecord Fe2CL4(name = "Fe2CL4", MM = 0.253502, Hf = -1701644.957436233, H0 = 117747.3984426158, Tlimit = 1000, alow = {1501.308814, -661.709651, 18.26924882, -0.00418149466, 4.196535049999999e-006, -2.188670747e-009, 5.395194700000001e-013}, blow = {-53400.5758, -49.3564068}, ahigh = {140245.0973, 693.606441, 13.1380041, 0.00275433307, -8.623996010000001e-007, 1.170782491e-010, -5.93777808e-015}, bhigh = {-59741.72730000001, -17.52491511}, R_s = R_NASA_2002/Fe2CL4.MM);
          constant IdealGases.Common.DataRecord Fe2CL6(name = "Fe2CL6", MM = 0.324408, Hf = -2017143.843555029, H0 = 124682.0485314789, Tlimit = 1000, alow = {-10345.44447, -823.48766, 25.20090594, -0.00684579679, 8.25582075e-006, -5.24896566e-009, 1.365242237e-012}, blow = {-81318.4719, -80.10768938}, ahigh = {-99991.17999999999, -14.57716085, 22.0120846, -5.22948113e-006, 1.226831608e-009, -1.473195806e-013, 7.07827233e-018}, bhigh = {-85514.9619, -61.43757198}, R_s = R_NASA_2002/Fe2CL6.MM);
          constant IdealGases.Common.DataRecord Ga(name = "Ga", MM = 0.06972299999999999, Hf = 3901151.700299758, H0 = 93959.16698937224, Tlimit = 1000, alow = {238794.789, -3121.634631, 16.30171272, -0.02347922342, 1.932327565e-005, -7.31631187e-009, 8.857387735e-013}, blow = {47327.1738, -75.47172759999999}, ahigh = {-55441.8652, 880.8624419999999, 1.760717716, 0.000299325946, -5.61082731e-008, 2.682832239e-012, 3.132134914e-016}, bhigh = {26843.51822, 12.52212023}, R_s = R_NASA_2002/Ga.MM);
          constant IdealGases.Common.DataRecord Gaplus(name = "Gaplus", MM = 0.0697224514, Hf = 12287124.31645799, H0 = 88887.12137278639, Tlimit = 1000, alow = {0.000409834494, -4.34358162e-006, 2.500000019, -4.389036810000001e-011, 5.5639692e-014, -3.63822826e-017, 9.607881994999999e-021}, blow = {102289.9726, 5.21509046}, ahigh = {35666.0714, -110.8845546, 2.635517951, -8.33897352e-005, 2.734243614e-008, -4.55567374e-012, 3.035050101e-016}, bhigh = {102989.743, 4.25707541}, R_s = R_NASA_2002/Gaplus.MM);
          constant IdealGases.Common.DataRecord GaBr(name = "GaBr", MM = 0.149627, Hf = -120084.4767321406, H0 = 66379.18958476746, Tlimit = 1000, alow = {-2185.275415, -76.72232969999999, 4.77080567, -0.000449788106, 5.5798536e-007, -3.065156457e-010, 7.042946040000001e-014}, blow = {-3138.004818, 2.948144294}, ahigh = {335980.503, -840.683668, 5.14508473, -3.265526e-005, -7.67102275e-008, 3.63512382e-011, -3.35817783e-015}, bhigh = {2035.179445, -0.427789408}, R_s = R_NASA_2002/GaBr.MM);
          constant IdealGases.Common.DataRecord GaBr2(name = "GaBr2", MM = 0.229531, Hf = -649938.1434316061, H0 = 61102.63101716108, Tlimit = 1000, alow = {7081.68162, -370.57661, 8.418425360000001, -0.003001930915, 3.59547767e-006, -2.276883735e-009, 5.91322177e-013}, blow = {-18211.16655, -9.512572049999999}, ahigh = {-330229.436, 476.672265, 7.1047254, -0.0005522771210000001, 3.159876015e-007, -5.51363715e-011, 3.17329323e-015}, bhigh = {-23656.8362, -1.162714892}, R_s = R_NASA_2002/GaBr2.MM);
          constant IdealGases.Common.DataRecord GaBr3(name = "GaBr3", MM = 0.309435, Hf = -946766.4065151, H0 = 61522.89495370594, Tlimit = 1000, alow = {6363.80734, -514.204045, 11.96065138, -0.00413463765, 4.933978330000001e-006, -3.111868526e-009, 8.04363148e-013}, blow = {-35704.155, -25.56896053}, ahigh = {-51030.6375, -9.39520969, 10.00768765, -3.2959543e-006, 7.679838140000001e-010, -9.175147259999999e-014, 4.39118694e-018}, bhigh = {-38334.0215, -14.10315914}, R_s = R_NASA_2002/GaBr3.MM);
          constant IdealGases.Common.DataRecord GaCL(name = "GaCL", MM = 0.105176, Hf = -661951.7760705864, H0 = 91362.24994295275, Tlimit = 1000, alow = {6417.143, -225.7949147, 5.31167369, -0.001562280975, 1.836579731e-006, -1.100421873e-009, 2.725812445e-013}, blow = {-8593.892329999999, -1.695911735}, ahigh = {-486484.224, 1452.870183, 2.719542959, 0.001144285628, -3.43145286e-007, 5.47044048e-011, -3.019622103e-015}, bhigh = {-18950.84035, 15.70926145}, R_s = R_NASA_2002/GaCL.MM);
          constant IdealGases.Common.DataRecord GaCL2(name = "GaCL2", MM = 0.140629, Hf = -1571360.878623897, H0 = 96092.49159135029, Tlimit = 1000, alow = {22254.81851, -604.621844, 9.220388910000001, -0.00455440079, 5.32485518e-006, -3.30860557e-009, 8.462235559999999e-013}, blow = {-25645.50386, -16.85409262}, ahigh = {-344540.53, 471.443716, 7.10877548, -0.000553943356, 3.16363824e-007, -5.51802393e-011, 3.17535303e-015}, bhigh = {-32309.3616, -3.74484074}, R_s = R_NASA_2002/GaCL2.MM);
          constant IdealGases.Common.DataRecord GaCL3(name = "GaCL3", MM = 0.176082, Hf = -2456950.47193921, H0 = 98677.01979759432, Tlimit = 1000, alow = {47849.484, -1162.678125, 14.08954213, -0.008106134290000001, 9.21943016e-006, -5.59971055e-009, 1.4048526e-012}, blow = {-49159.0973, -42.82179383}, ahigh = {-94669.1731, -25.61468254, 10.02010048, -8.35407307e-006, 1.901439055e-009, -2.231168493e-013, 1.052949609e-017}, bhigh = {-55182.0143, -18.64958383}, R_s = R_NASA_2002/GaCL3.MM);
          constant IdealGases.Common.DataRecord GaF(name = "GaF", MM = 0.08872140319999999, Hf = -2621785.528748265, H0 = 102355.3356063241, Tlimit = 1000, alow = {36703.9801, -533.6572219999999, 5.75929192, -0.001506128492, 9.509038450000001e-007, -1.83094113e-010, -3.135959193e-014}, blow = {-26470.7569, -6.58932188}, ahigh = {-298339.2279, 722.5157870000001, 3.63955743, 0.000554673676, -1.46490145e-007, 2.177385396e-011, -1.031058874e-015}, bhigh = {-34085.2871, 7.55396}, R_s = R_NASA_2002/GaF.MM);
          constant IdealGases.Common.DataRecord GaF2(name = "GaF2", MM = 0.1077198064, Hf = -4796819.250503221, H0 = 112473.8282114105, Tlimit = 1000, alow = {68425.3953, -889.761774, 7.70745549, 0.00207215089, -5.28998193e-006, 4.56412742e-009, -1.406942753e-012}, blow = {-59198.5615, -13.41142116}, ahigh = {410025.1359999999, -1723.259472, 8.95132922, -0.001059205682, 2.745755154e-007, -2.907681311e-011, 1.084834142e-015}, bhigh = {-53765.716, -21.13835528}, R_s = R_NASA_2002/GaF2.MM);
          constant IdealGases.Common.DataRecord GaF3(name = "GaF3", MM = 0.1267182096, Hf = -7271859.237190485, H0 = 120132.8289600455, Tlimit = 1000, alow = {95932.66699999999, -1355.507494, 10.97760197, 0.00346157172, -8.469551949999999e-006, 7.22246893e-009, -2.213328653e-012}, blow = {-106147.9087, -32.1265185}, ahigh = {-209696.176, -143.1211274, 10.10568378, -4.18493682e-005, 9.16475945e-009, -1.042661957e-012, 4.79916345e-017}, bhigh = {-113667.8134, -23.9253933}, R_s = R_NASA_2002/GaF3.MM);
          constant IdealGases.Common.DataRecord GaH(name = "GaH", MM = 0.07073094000000001, Hf = 3030122.376431021, H0 = 122621.0764341602, Tlimit = 1000, alow = {-43918.762, 625.445712, 0.327686289, 0.0064966415, -3.80297001e-006, 2.852103704e-010, 3.62680913e-013}, blow = {21712.60108, 22.24032244}, ahigh = {3257993.99, -11090.99502, 18.01126796, -0.008167719110000001, 2.601293566e-006, -3.81345935e-010, 2.028049649e-014}, bhigh = {93697.78240000001, -98.2090022}, R_s = R_NASA_2002/GaH.MM);
          constant IdealGases.Common.DataRecord GaI(name = "GaI", MM = 0.19662747, Hf = 228203.7296212986, H0 = 51412.56203927151, Tlimit = 1000, alow = {-3661.85503, -32.0692418, 4.59996192, -8.899475459999999e-005, 1.162792633e-007, -1.812351457e-011, -7.584619639999999e-015}, blow = {4198.64937, 4.92896465}, ahigh = {1498356.654, -4551.96724, 9.803005349999999, -0.002943735609, 8.658040509999999e-007, -1.106638204e-010, 5.00783686e-015}, bhigh = {32918.1191, -32.2735977}, R_s = R_NASA_2002/GaI.MM);
          constant IdealGases.Common.DataRecord GaI2(name = "GaI2", MM = 0.32353194, Hf = -89496.46517125944, H0 = 44727.99501650439, Tlimit = 1000, alow = {-983.13959, -215.2621259, 7.84431876, -0.001819797849, 2.210706958e-006, -1.416110855e-009, 3.71376293e-013}, blow = {-4534.090230000001, -4.25051681}, ahigh = {-320287.975, 479.650233, 7.10233396, -0.000551265783, 3.157543452e-007, -5.51087194e-011, 3.17197773e-015}, bhigh = {-9180.919610000001, 0.727520488}, R_s = R_NASA_2002/GaI2.MM);
          constant IdealGases.Common.DataRecord GaI3(name = "GaI3", MM = 0.45043641, Hf = -257255.4914022159, H0 = 44673.91967714155, Tlimit = 1000, alow = {-5663.47265, -242.5937116, 10.95451119, -0.002059175489, 2.499117622e-006, -1.596502506e-009, 4.16764406e-013}, blow = {-15767.22832, -16.46129942}, ahigh = {-31640.4013, -4.20866283, 10.00352001, -1.53265018e-006, 3.61153154e-010, -4.35097887e-014, 2.095704875e-018}, bhigh = {-17000.58453, -10.90291552}, R_s = R_NASA_2002/GaI3.MM);
          constant IdealGases.Common.DataRecord GaO(name = "GaO", MM = 0.08572239999999999, Hf = 1712779.938499156, H0 = 104116.3919815591, Tlimit = 1000, alow = {73255.4391, -980.4269509999999, 7.84412276, -0.00717107285, 7.87278051e-006, -2.401464112e-009, -2.594919458e-013}, blow = {21405.81724, -17.99742951}, ahigh = {2937313.804, -11183.14112, 18.59366773, -0.00685475345, 1.665399251e-006, -1.887560878e-010, 7.97268692e-015}, bhigh = {85302.48080000001, -99.04040480000001}, R_s = R_NASA_2002/GaO.MM);
          constant IdealGases.Common.DataRecord GaOH(name = "GaOH", MM = 0.08673034, Hf = -1656058.249051024, H0 = 122028.9001518961, Tlimit = 1000, alow = {69631.0187, -1247.828695, 10.22001611, -0.00592253439, 4.6433874e-006, -1.215936978e-009, -2.945243614e-014}, blow = {-12753.97794, -32.17063}, ahigh = {842905.101, -2372.324595, 8.009071090000001, 8.77723071e-005, -5.94306891e-008, 9.841943439999999e-012, -5.53155279e-016}, bhigh = {-3751.78825, -21.71053719}, R_s = R_NASA_2002/GaOH.MM);
          constant IdealGases.Common.DataRecord Ga2Br2(name = "Ga2Br2", MM = 0.299254, Hf = -457683.7469173344, H0 = 69483.80974022068, Tlimit = 1000, alow = {-11171.83241, -74.7147162, 10.30246084, -0.0006657929850000001, 8.20051585e-007, -5.29702152e-010, 1.394553192e-013}, blow = {-19132.97856, -13.17110316}, ahigh = {-18853.73131, -1.263621802, 10.00108034, -4.774975660000001e-007, 1.137227648e-010, -1.380820486e-014, 6.69024243e-019}, bhigh = {-19510.53843, -11.41667594}, R_s = R_NASA_2002/Ga2Br2.MM);
          constant IdealGases.Common.DataRecord Ga2Br4(name = "Ga2Br4", MM = 0.459062, Hf = -905803.647437601, H0 = 66639.72622434443, Tlimit = 1000, alow = {-13155.45939, -413.655302, 17.62849229, -0.00351465216, 4.26693773e-006, -2.726515882e-009, 7.11892449e-013}, blow = {-52831.0181, -44.2752069}, ahigh = {-57421.6721, -7.16013737, 16.00598947, -2.60818227e-006, 6.14645595e-010, -7.40543865e-014, 3.56712663e-018}, bhigh = {-54933.8976, -34.79271660000001}, R_s = R_NASA_2002/Ga2Br4.MM);
          constant IdealGases.Common.DataRecord Ga2Br6(name = "Ga2Br6", MM = 0.61887, Hf = -1088578.75159565, H0 = 66494.20072066832, Tlimit = 1000, alow = {-6725.11689, -806.752655, 25.11671424, -0.00663651457, 7.9775557e-006, -5.05968521e-009, 1.313546388e-012}, blow = {-83706.352, -75.8527872}, ahigh = {-95261.73, -14.4468188, 22.01192546, -5.14500674e-006, 1.204348449e-009, -1.443806473e-013, 6.928270740000001e-018}, bhigh = {-87822.23300000001, -57.6589512}, R_s = R_NASA_2002/Ga2Br6.MM);
          constant IdealGases.Common.DataRecord Ga2CL2(name = "Ga2CL2", MM = 0.210352, Hf = -1050490.064273218, H0 = 92646.73024264089, Tlimit = 1000, alow = {-9246.1337, -259.2159934, 11.02847129, -0.002231983927, 2.720723456e-006, -1.743798624e-009, 4.56366604e-013}, blow = {-28340.59821, -20.67773272}, ahigh = {-36689.542, -4.43458068, 10.00373051, -1.630793333e-006, 3.85375332e-010, -4.65252773e-014, 2.244498791e-018}, bhigh = {-29656.33085, -14.69535817}, R_s = R_NASA_2002/Ga2CL2.MM);
          constant IdealGases.Common.DataRecord Ga2CL4(name = "Ga2CL4", MM = 0.281258, Hf = -2141545.584481152, H0 = 97118.63129226546, Tlimit = 1000, alow = {16373.43702, -1140.637354, 20.30139827, -0.0089977462, 1.067254867e-005, -6.700290619999999e-009, 1.725749144e-012}, blow = {-71623.85010000001, -66.663619}, ahigh = {-112711.0409, -21.38517542, 16.01738077, -7.41556464e-006, 1.721694751e-009, -2.051361953e-013, 9.797311499999999e-018}, bhigh = {-77468.53380000001, -41.4728087}, R_s = R_NASA_2002/Ga2CL4.MM);
          constant IdealGases.Common.DataRecord Ga2CL6(name = "Ga2CL6", MM = 0.352164, Hf = -2732998.069081451, H0 = 103246.7799093604, Tlimit = 1000, alow = {60894.69839999999, -2104.456302, 29.59653878, -0.01537809796, 1.779096808e-005, -1.095619429e-008, 2.779706493e-012}, blow = {-111840.0535, -112.1945814}, ahigh = {-189844.5426, -44.1365524, 22.03505047, -1.470071128e-005, 3.36951281e-009, -3.9754628e-013, 1.884231868e-017}, bhigh = {-122696.9998, -67.45332883}, R_s = R_NASA_2002/Ga2CL6.MM);
          constant IdealGases.Common.DataRecord Ga2F2(name = "Ga2F2", MM = 0.1774428064, Hf = -3416488.705850406, H0 = 96638.77813871186, Tlimit = 1000, alow = {29781.3065, -1013.97552, 13.74933053, -0.00772805096, 9.06400733e-006, -5.64119322e-009, 1.443106716e-012}, blow = {-70860.8337, -41.09833949999999}, ahigh = {-87732.34929999999, -19.8377587, 10.0159403, -6.744402830000001e-006, 1.556129063e-009, -1.845316975e-013, 8.780884020000001e-018}, bhigh = {-76073.6863, -19.08325521}, R_s = R_NASA_2002/Ga2F2.MM);
          constant IdealGases.Common.DataRecord Ga2F4(name = "Ga2F4", MM = 0.2154396128, Hf = -6150229.016750257, H0 = 105148.9171632971, Tlimit = 1000, alow = {142207.9998, -2798.829941, 23.95904235, -0.01293904774, 1.223101326e-005, -6.25120982e-009, 1.334919195e-012}, blow = {-149601.371, -97.34153640000001}, ahigh = {-270436.609, -104.9957196, 16.07903965, -3.17889592e-005, 7.04958272e-009, -8.10237952e-013, 3.76054053e-017}, bhigh = {-164416.9589, -48.9659173}, R_s = R_NASA_2002/Ga2F4.MM);
          constant IdealGases.Common.DataRecord Ga2F6(name = "Ga2F6", MM = 0.2534364192, Hf = -7961065.143552976, H0 = 118891.6576990526, Tlimit = 1000, alow = {240904.5572, -4142.3798, 31.9577372, -0.0129791429, 8.95928219e-006, -2.733621068e-009, 1.554030994e-013}, blow = {-227278.524, -139.8403732}, ahigh = {-436866.48, -212.8208368, 22.15886373, -6.34628791e-005, 1.399738556e-008, -1.601732039e-012, 7.407584420000001e-017}, bhigh = {-249429.8707, -77.87635830000001}, R_s = R_NASA_2002/Ga2F6.MM);
          constant IdealGases.Common.DataRecord Ga2I2(name = "Ga2I2", MM = 0.39325494, Hf = 34382.14151867996, H0 = 54666.69280746988, Tlimit = 1000, alow = {-8960.25267, -31.7205721, 10.12930491, -0.0002860191165, 3.53533301e-007, -2.289632389e-010, 6.04008536e-014}, blow = {-1233.174068, -9.80196838}, ahigh = {-12190.56501, -0.528755447, 10.00045392, -2.011599344e-007, 4.79946781e-011, -5.83478108e-015, 2.829565069e-019}, bhigh = {-1393.258606, -9.052614910000001}, R_s = R_NASA_2002/Ga2I2.MM);
          constant IdealGases.Common.DataRecord Ga2I4(name = "Ga2I4", MM = 0.64706388, Hf = -246139.5109861487, H0 = 50356.40839664856, Tlimit = 1000, alow = {-17694.95991, -135.4871509, 16.54625333, -0.001199014713, 1.473754848e-006, -9.504796569999999e-010, 2.499380837e-013}, blow = {-23334.05795, -33.2571289}, ahigh = {-31712.9976, -2.287068836, 16.00194812, -8.58896438e-007, 2.041966602e-010, -2.476145769e-014, 1.198551944e-018}, bhigh = {-24019.40505, -30.08672521}, R_s = R_NASA_2002/Ga2I4.MM);
          constant IdealGases.Common.DataRecord Ga2I6(name = "Ga2I6", MM = 0.90087282, Hf = -352208.0097832234, H0 = 48367.95719955232, Tlimit = 1000, alow = {-21108.91458, -369.540416, 23.46811836, -0.00318917821, 3.89033904e-006, -2.494830378e-009, 6.53200728e-013}, blow = {-43011.8809, -60.148115}, ahigh = {-60156.9815, -6.32920923, 22.0053304, -2.332008629e-006, 5.51386848e-010, -6.659445350000001e-014, 3.21367043e-018}, bhigh = {-44886.9938, -51.6100875}, R_s = R_NASA_2002/Ga2I6.MM);
          constant IdealGases.Common.DataRecord Ga2O(name = "Ga2O", MM = 0.1554454, Hf = -639822.4521278854, H0 = 78243.51830288963, Tlimit = 1000, alow = {56971.9718, -807.4085990000001, 7.73306154, 0.001478450874, -4.097743430000001e-006, 3.58115892e-009, -1.107073202e-012}, blow = {-9512.216820000002, -12.56149299}, ahigh = {-119387.4986, -87.19341610000001, 7.0646782, -2.571524542e-005, 5.65110849e-009, -6.44819054e-013, 2.975374645e-017}, bhigh = {-13936.94796, -6.9428013}, R_s = R_NASA_2002/Ga2O.MM);
          constant IdealGases.Common.DataRecord Ge(name = "Ge", MM = 0.07264, Hf = 5063325.991189428, H0 = 101852.7533039648, Tlimit = 1000, alow = {-20592.15242, -143.2022103, 4.50600233, 0.00154718784, -8.518296550000001e-006, 8.24382446e-009, -2.566167305e-012}, blow = {43630.7086, -6.224648889}, ahigh = {-856541.384, 3917.95866, -1.809888212, 0.002276482224, -5.36562755e-007, 5.984958090000001e-011, -2.541700646e-015}, bhigh = {19565.18798, 38.41408752}, R_s = R_NASA_2002/Ge.MM);
          constant IdealGases.Common.DataRecord Geplus(name = "Geplus", MM = 0.0726394514, Hf = 15624903.03994779, H0 = 85432.70743919742, Tlimit = 1000, alow = {-345366.643, 4008.44971, -15.22395737, 0.0362603002, -3.35136726e-005, 1.431059219e-008, -2.236976459e-012}, blow = {115705.8042, 109.0158182}, ahigh = {-2244860.57, 5165.53114, -0.386751651, 0.000852873094, -1.386040003e-007, 1.155945775e-011, -3.784413134e-016}, bhigh = {100682.3985, 29.65845411}, R_s = R_NASA_2002/Geplus.MM);
          constant IdealGases.Common.DataRecord Geminus(name = "Geminus", MM = 0.07264054860000001, Hf = 3378313.417638478, H0 = 96102.52310236543, Tlimit = 1000, alow = {2989.142308, 86.5741723, 2.191868507, 0.0005900795269999999, -6.37580058e-007, 3.66113215e-010, -8.689778450000001e-014}, blow = {28356.9519, 9.417623637}, ahigh = {13520.40246, -0.504851878, 2.500140247, -3.65294416e-009, -6.7167222e-012, 1.378119925e-015, -8.475212940000001e-020}, bhigh = {28817.39757, 7.577953867}, R_s = R_NASA_2002/Geminus.MM);
          constant IdealGases.Common.DataRecord GeBr(name = "GeBr", MM = 0.152544, Hf = 900973.6141703377, H0 = 64664.09036081393, Tlimit = 1000, alow = {-56807.7463, 917.336126, -2.224809366, 0.02171239242, -3.035490868e-005, 2.011776305e-008, -5.20291504e-012}, blow = {11041.92901, 41.07865983}, ahigh = {225675.0476, -731.071546, 6.26328381, -0.001198085447, 4.00037777e-007, -5.42993788e-011, 2.510481953e-015}, bhigh = {19428.63606, -6.106507844}, R_s = R_NASA_2002/GeBr.MM);
          constant IdealGases.Common.DataRecord GeBr2(name = "GeBr2", MM = 0.232448, Hf = -262264.6656456497, H0 = 61060.80929928413, Tlimit = 1000, alow = {-1649.285325, -229.6262116, 7.90014468, -0.001936685504, 2.345776175e-006, -1.496279368e-009, 3.9014535e-013}, blow = {-8316.62421, -6.918156136}, ahigh = {-26366.55245, -3.99050902, 7.00332744, -1.445749787e-006, 3.40159136e-010, -4.09345703e-014, 1.969987842e-018}, bhigh = {-9484.999249999999, -1.673617098}, R_s = R_NASA_2002/GeBr2.MM);
          constant IdealGases.Common.DataRecord GeBr3(name = "GeBr3", MM = 0.312352, Hf = -381080.665403135, H0 = 59386.49984632723, Tlimit = 1000, alow = {2725.568677, -518.621326, 11.99957754, -0.00425102453, 5.10362972e-006, -3.23370625e-009, 8.38835886e-013}, blow = {-14779.88251, -25.34555678}, ahigh = {-54339.267, -9.28032795, 10.00765019, -3.29732215e-006, 7.71292926e-010, -9.24157185e-014, 4.43287623e-018}, bhigh = {-17426.97092, -13.66946296}, R_s = R_NASA_2002/GeBr3.MM);
          constant IdealGases.Common.DataRecord GeBr4(name = "GeBr4", MM = 0.392256, Hf = -741862.4571708272, H0 = 61090.76215532714, Tlimit = 1000, alow = {5431.940390000001, -677.7748800000001, 15.60015305, -0.00550778888, 6.59476429e-006, -4.17014614e-009, 1.080116643e-012}, blow = {-35576.064, -42.09122927}, ahigh = {-69777.5791, -11.79873115, 13.00953955, -4.02493875e-006, 9.203567209999999e-010, -1.076853369e-013, 5.0409548e-018}, bhigh = {-39041.4816, -26.8943607}, R_s = R_NASA_2002/GeBr4.MM);
          constant IdealGases.Common.DataRecord GeCL(name = "GeCL", MM = 0.108093, Hf = 638615.960330456, H0 = 88804.2241403236, Tlimit = 1000, alow = {10697.24739, -22.41238266, 1.98737107, 0.01368270905, -2.358294414e-005, 1.78675602e-008, -5.10250325e-012}, blow = {7440.68339, 15.05837189}, ahigh = {-378419.325, 1429.309204, 3.19485464, 0.0008119939119999999, -2.652459954e-007, 5.15195788e-011, -3.53421457e-015}, bhigh = {-2087.046335, 13.8503382}, R_s = R_NASA_2002/GeCL.MM);
          constant IdealGases.Common.DataRecord GeCL2(name = "GeCL2", MM = 0.143546, Hf = -1191255.764702604, H0 = 92491.54278071142, Tlimit = 1000, alow = {18385.36673, -582.720534, 9.161404660000001, -0.00446478603, 5.24487355e-006, -3.26806721e-009, 8.36757542e-013}, blow = {-19757.98598, -17.3432163}, ahigh = {-48901.28920000001, -11.26210418, 7.00906353, -3.83918073e-006, 8.86563357e-010, -1.05200054e-013, 5.00842222e-018}, bhigh = {-22752.54424, -4.656641298}, R_s = R_NASA_2002/GeCL2.MM);
          constant IdealGases.Common.DataRecord GeCL3(name = "GeCL3", MM = 0.178999, Hf = -1491352.404203376, H0 = 98097.96144112539, Tlimit = 1000, alow = {19358.59579, -834.202, 13.1270253, -0.006511390020000001, 7.69627748e-006, -4.81854173e-009, 1.238399959e-012}, blow = {-30972.18753, -35.52547183999999}, ahigh = {-75744.9982, -15.7921342, 10.01278835, -5.44173831e-006, 1.260936724e-009, -1.500137106e-013, 7.15640081e-018}, bhigh = {-35251.3172, -17.19719944}, R_s = R_NASA_2002/GeCL3.MM);
          constant IdealGases.Common.DataRecord GeCL4(name = "GeCL4", MM = 0.214452, Hf = -2331524.070654505, H0 = 98561.09991979557, Tlimit = 1000, alow = {65028.7041, -1652.48276, 18.81327, -0.0115242681, 1.31080998e-005, -7.96195611e-009, 1.99750504e-012}, blow = {-55700.5239, -67.54438135}, ahigh = {-137626.121, -36.037695, 13.0281667, -1.16495696e-005, 2.63619338e-009, -3.07292672e-013, 1.43980875e-017}, bhigh = {-64262.8178, -33.18158305}, R_s = R_NASA_2002/GeCL4.MM);
          constant IdealGases.Common.DataRecord GeF(name = "GeF", MM = 0.0916384032, Hf = -770342.8642894556, H0 = 99784.69376035572, Tlimit = 1000, alow = {50170.9782, -439.555252, 2.990864513, 0.01252766738, -2.337593226e-005, 1.841631179e-008, -5.398492260000001e-012}, blow = {-7093.5164, 7.064248931}, ahigh = {-515048.058, 1659.711777, 2.999610299, 0.0008198511679999999, -2.271982948e-007, 3.62418386e-011, -2.133840473e-015}, bhigh = {-20515.29487, 13.7315423}, R_s = R_NASA_2002/GeF.MM);
          constant IdealGases.Common.DataRecord GeF2(name = "GeF2", MM = 0.1106368064, Hf = -5188146.862489335, H0 = 106542.1660616552, Tlimit = 1000, alow = {75430.9708, -1108.456469, 9.07889827, -0.001445630636, -6.57532232e-007, 1.475344103e-009, -5.81122027e-013}, blow = {-65106.8555, -22.00457134}, ahigh = {-127532.7716, -71.6259135, 7.05300237, -2.101910441e-005, 4.6078937e-009, -5.24639467e-013, 2.416218951e-017}, bhigh = {-71126.3763, -8.483841439000001}, R_s = R_NASA_2002/GeF2.MM);
          constant IdealGases.Common.DataRecord GeF3(name = "GeF3", MM = 0.1296352096, Hf = -6220014.111042869, H0 = 113226.8543807716, Tlimit = 1000, alow = {111412.1569, -1776.90803, 13.52166477, -0.002983622949, -3.61274975e-008, 1.621528436e-009, -7.19901178e-013}, blow = {-90382.62960000002, -45.68760023}, ahigh = {-206958.0129, -111.0233803, 10.08234122, -3.27167626e-005, 7.1838967e-009, -8.19038812e-013, 3.77632244e-017}, bhigh = {-99997.4909, -23.0346594}, R_s = R_NASA_2002/GeF3.MM);
          constant IdealGases.Common.DataRecord GeF4(name = "GeF4", MM = 0.1486336128, Hf = -8007273.574123873, H0 = 116346.6639492194, Tlimit = 1000, alow = {111981.8968, -1636.85963, 12.31371005, 0.01025446325, -1.893783072e-005, 1.476849261e-008, -4.32517411e-012}, blow = {-137426.5128, -41.04202391000001}, ahigh = {-325303.268, -253.8279448, 13.18792173, -7.46005855e-005, 1.637384721e-008, -1.866482733e-012, 8.605530500000001e-017}, bhigh = {-146617.6526, -41.22237561}, R_s = R_NASA_2002/GeF4.MM);
          constant IdealGases.Common.DataRecord GeH4(name = "GeH4", MM = 0.07667176000000001, Hf = 1184177.85114102, H0 = 0, Tlimit = 1000, alow = {-256839.8191, -41.3281145, 7.75511628, 0.002129640783, 7.255053610000001e-007, -5.09631401e-010, 1.431608261e-013}, blow = {7881.53804, -20.30107999}, ahigh = {-3809805.88, 10931.67093, -5.14967541, 0.009485931369999999, -1.649459859e-006, 1.419674126e-010, -5.00463975e-015}, bhigh = {-61585.1852, 71.68961272999999}, R_s = R_NASA_2002/GeH4.MM);
          constant IdealGases.Common.DataRecord GeI(name = "GeI", MM = 0.19954447, Hf = 1057253.653784542, H0 = 50139.80091755988, Tlimit = 1000, alow = {-74383.08219999999, 1033.759595, -1.520491112, 0.01555125152, -1.683415215e-005, 8.383557809999999e-009, -1.550875391e-012}, blow = {19129.20413, 39.59395473}, ahigh = {-213314.8437, -295.3079008, 6.87660736, -0.002102579132, 8.59629938e-007, -1.44769276e-010, 8.401042789999999e-015}, bhigh = {24523.26136, -8.549783749}, R_s = R_NASA_2002/GeI.MM);
          constant IdealGases.Common.DataRecord GeO(name = "GeO", MM = 0.08863939999999999, Hf = -425254.5369215045, H0 = 99076.77624171645, Tlimit = 1000, alow = {-6781.22563, 279.1946972, 0.619895286, 0.01111378013, -1.501027092e-005, 1.006783003e-008, -2.687101932e-012}, blow = {-6711.84743, 21.56441027}, ahigh = {-1044508.485, 2734.866048, 1.298071298, 0.001832638634, -5.06098635e-007, 6.37495802e-011, -2.172371872e-015}, bhigh = {-23621.04658, 23.50906051}, R_s = R_NASA_2002/GeO.MM);
          constant IdealGases.Common.DataRecord GeO2(name = "GeO2", MM = 0.1046388, Hf = -1014652.289590477, H0 = 107589.1734232426, Tlimit = 1000, alow = {-3824.17383, 156.3451633, 1.694198285, 0.01756205059, -2.418270032e-005, 1.632388154e-008, -4.36895786e-012}, blow = {-14775.3488, 15.56926515}, ahigh = {-172734.7526, -296.1154443, 7.72072625, -8.82493339e-005, 1.949874702e-008, -2.235834829e-012, 1.036128507e-016}, bhigh = {-13879.83288, -16.69845695}, R_s = R_NASA_2002/GeO2.MM);
          constant IdealGases.Common.DataRecord GeS(name = "GeS", MM = 0.104705, Hf = 883674.2275918056, H0 = 87303.47165846905, Tlimit = 1000, alow = {36610.1843, -565.9653500000001, 6.15293641, -0.002746908039, 2.733435196e-006, -1.460209187e-009, 3.27870947e-013}, blow = {12741.75754, -7.70565946}, ahigh = {-2351367.441, 7211.58186, -4.36252631, 0.00545173775, -1.721002774e-006, 2.632908084e-010, -1.39437404e-014}, bhigh = {-35833.1725, 65.05566890999999}, R_s = R_NASA_2002/GeS.MM);
          constant IdealGases.Common.DataRecord GeS2(name = "GeS2", MM = 0.13677, Hf = 868741.9097755356, H0 = 95546.03348687578, Tlimit = 1000, alow = {55436.836, -1024.826697, 10.57594552, -0.00528788391, 5.29580308e-006, -2.87252953e-009, 6.51902755e-013}, blow = {17355.79668, -29.91719536}, ahigh = {-89709.8036, -33.64377, 7.52543372, -1.026368137e-005, 2.282230718e-009, -2.62874877e-013, 1.222218614e-017}, bhigh = {11952.32103, -11.35170616}, R_s = R_NASA_2002/GeS2.MM);
          constant IdealGases.Common.DataRecord Ge2(name = "Ge2", MM = 0.14528, Hf = 3245449.676486785, H0 = 73624.23595814979, Tlimit = 1000, alow = {216197.8929, -3079.621733, 18.88047728, -0.02604825861, 2.27915135e-005, -9.02835127e-009, 1.146806387e-012}, blow = {70324.02549999999, -79.01095968}, ahigh = {1969461.258, -5248.6871, 10.58277303, -0.00333655151, 1.052745838e-006, -1.484534793e-010, 7.475431760000001e-015}, bhigh = {89256.65990000001, -37.50233948}, R_s = R_NASA_2002/Ge2.MM);
          constant IdealGases.Common.DataRecord H(name = "H", MM = 0.00100794, Hf = 216281552.4733615, H0 = 6148608.052066591, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {25473.70801, -0.446682853}, ahigh = {60.78774250000001, -0.1819354417, 2.500211817, -1.226512864e-007, 3.73287633e-011, -5.68774456e-015, 3.410210197e-019}, bhigh = {25474.86398, -0.448191777}, R_s = R_NASA_2002/H.MM);
          constant IdealGases.Common.DataRecord Hplus(name = "Hplus", MM = 0.0010073914, Hf = 1524974233.450872, H0 = 6151956.429248851, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {184021.4877, -1.140646644}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {184021.4877, -1.140646644}, R_s = R_NASA_2002/Hplus.MM);
          constant IdealGases.Common.DataRecord Hminus(name = "Hminus", MM = 0.0010084886, Hf = 137861080.4326395, H0 = 6145263.317800519, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {15976.15494, -1.139013868}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {15976.15494, -1.139013868}, R_s = R_NASA_2002/Hminus.MM);
          constant IdealGases.Common.DataRecord HALO(name = "HALO", MM = 0.043988878, Hf = 41399.41918955059, H0 = 225857.476974066, Tlimit = 1000, alow = {26686.71568, -466.321459, 5.38380021, 0.002902425002, -2.24367761e-007, -1.516294323e-009, 6.95173766e-013}, blow = {1235.914473, -6.50883752}, ahigh = {78474.67049999999, -1515.62885, 8.572776230000001, -0.0004142611439999999, 8.9350817e-008, -1.007036446e-011, 4.60801725e-016}, bhigh = {6663.24189, -26.72948642}, R_s = R_NASA_2002/HALO.MM);
          constant IdealGases.Common.DataRecord HALO2(name = "HALO2", MM = 0.059988278, Hf = -5925716.870886008, H0 = 199715.7511339132, Tlimit = 1000, alow = {3544.59891, 115.9819104, 0.863797069, 0.02460875785, -3.42316012e-005, 2.373182987e-008, -6.46760883e-012}, blow = {-44495.06140000001, 20.12317065}, ahigh = {698570.544, -2864.935042, 10.86721494, -5.3683127e-005, -2.836877559e-008, 6.29164119e-012, -3.88903311e-016}, bhigh = {-27643.92495, -37.7588634}, R_s = R_NASA_2002/HALO2.MM);
          constant IdealGases.Common.DataRecord HBO(name = "HBO", MM = 0.02781834, Hf = -7571307.454003366, H0 = 329527.139290123, Tlimit = 1000, alow = {63609.7503, -800.1557590000001, 6.21881613, -0.000780167998, 3.141286759e-006, -2.031853478e-009, 3.73855289e-013}, blow = {-22402.8291, -13.26952393}, ahigh = {886186.0229999999, -3913.06805, 9.8886448, -0.0008222269139999999, 1.621530554e-007, -1.703550237e-011, 7.372740020000001e-016}, bhigh = {-3161.852029, -40.3681272}, R_s = R_NASA_2002/HBO.MM);
          constant IdealGases.Common.DataRecord HBOplus(name = "HBOplus", MM = 0.0278177914, Hf = 42247053.76861803, H0 = 326935.6962681085, Tlimit = 1000, alow = {65244.7147, -704.733736, 5.29427187, 0.001308494598, 2.088343622e-006, -2.564100339e-009, 8.198981249999999e-013}, blow = {143929.3436, -6.81674923}, ahigh = {18360.83606, -1212.975446, 6.82290196, 0.0009142272500000001, -2.665355457e-007, 3.29704981e-011, -1.530684082e-015}, bhigh = {146361.7504, -16.99646159}, R_s = R_NASA_2002/HBOplus.MM);
          constant IdealGases.Common.DataRecord HBO2(name = "HBO2", MM = 0.04381774, Hf = -12785005.63926848, H0 = 249170.8152907932, Tlimit = 1000, alow = {6225.08747, 75.6615369, 1.253406833, 0.01748006535, -1.982688351e-005, 1.22965646e-008, -3.153609847e-012}, blow = {-68785.8878, 17.67793507}, ahigh = {1049369.185, -4479.145479999999, 11.97755861, -0.00047357434, 6.08020714e-008, -3.64156544e-012, 6.15597317e-017}, bhigh = {-42211.4947, -49.11366819999999}, R_s = R_NASA_2002/HBO2.MM);
          constant IdealGases.Common.DataRecord HBS(name = "HBS", MM = 0.04388394, Hf = 1144108.755959469, H0 = 211609.5090823659, Tlimit = 1000, alow = {56499.66209999999, -546.640995, 3.63645839, 0.009963657670000001, -1.395090386e-005, 1.032834167e-008, -3.047186722e-012}, blow = {7919.86053, 1.182455314}, ahigh = {-202183.6183, -505.202662, 6.41521828, 0.001049432932, -3.68314669e-007, 5.34296831e-011, -2.154140451e-015}, bhigh = {6485.47562, -13.31379864}, R_s = R_NASA_2002/HBS.MM);
          constant IdealGases.Common.DataRecord HBSplus(name = "HBSplus", MM = 0.0438833914, Hf = 25737731.99762314, H0 = 230975.5394155794, Tlimit = 1000, alow = {148950.9163, -1847.661736, 11.4745802, -0.009476828369999999, 1.110746739e-005, -6.175558610000001e-009, 1.336853512e-012}, blow = {143782.2395, -41.13512498}, ahigh = {661065.836, -2791.498527, 9.131267640000001, -0.000506379529, 7.751213140000001e-008, -4.19113293e-012, 2.687149095e-017}, bhigh = {151073.4114, -30.81426166}, R_s = R_NASA_2002/HBSplus.MM);
          constant IdealGases.Common.DataRecord HCN(name = "HCN", MM = 0.02702534, Hf = 4924358.398451231, H0 = 341733.4620026983, Tlimit = 1000, alow = {90982.86930000001, -1238.657512, 8.72130787, -0.00652824294, 8.87270083e-006, -4.808886669999999e-009, 9.317898499999999e-013}, blow = {20989.1545, -27.46678076}, ahigh = {1236889.278, -4446.732410000001, 9.73887485, -0.000585518264, 1.07279144e-007, -1.013313244e-011, 3.34824798e-016}, bhigh = {42215.1377, -40.05774072000001}, R_s = R_NASA_2002/HCN.MM);
          constant IdealGases.Common.DataRecord HCO(name = "HCO", MM = 0.02901804, Hf = 1461085.931372346, H0 = 344249.6460822303, Tlimit = 1000, alow = {-11898.51887, 215.1536111, 2.730224028, 0.001806516108, 4.98430057e-006, -5.81456792e-009, 1.869689894e-012}, blow = {2905.75564, 11.3677254}, ahigh = {694960.6120000001, -3656.22338, 9.604731170000001, -0.001117129278, 2.875328019e-007, -3.62624774e-011, 1.808329595e-015}, bhigh = {25437.0444, -35.8247372}, R_s = R_NASA_2002/HCO.MM);
          constant IdealGases.Common.DataRecord HCOplus(name = "HCOplus", MM = 0.0290174914, Hf = 28707995.06810571, H0 = 311742.7304553281, Tlimit = 1000, alow = {157344.2506, -1867.692159, 10.99235423, -0.01211637888, 1.659091514e-005, -1.016592642e-008, 2.391234771e-012}, blow = {108493.028, -40.7826162}, ahigh = {1219060.653, -4714.29489, 10.21192493, -0.000885451707, 1.667408026e-007, -1.683285548e-011, 7.04005178e-016}, bhigh = {127798.9027, -43.5115846}, R_s = R_NASA_2002/HCOplus.MM);
          constant IdealGases.Common.DataRecord HCCN(name = "HCCN", MM = 0.03903604, Hf = 15637616.62299762, H0 = 303968.6146443133, Tlimit = 1000, alow = {2994.114377, -440.466068, 6.94003641, 0.00384630496, -1.264728529e-006, -3.63923513e-010, 2.748929104e-013}, blow = {73708.7864, -13.15302591}, ahigh = {939562.031, -4091.06775, 12.72233302, -0.000687440531, 1.231169968e-007, -1.186956238e-011, 4.76061035e-016}, bhigh = {95851.6482, -52.48695794}, R_s = R_NASA_2002/HCCN.MM);
          constant IdealGases.Common.DataRecord HCCO(name = "HCCO", MM = 0.04102874, Hf = 4303522.360179718, H0 = 284312.7524754599, Tlimit = 1000, alow = {69596.12700000001, -1164.594402, 9.456616260000001, -0.002331240632, 5.1618736e-006, -3.52616997e-009, 8.59914323e-013}, blow = {25350.03992, -27.26355351}, ahigh = {1093922.002, -4498.228209999999, 12.46446433, -0.00063433174, 1.108549019e-007, -1.125488678e-011, 5.68915194e-016}, bhigh = {46522.803, -50.9907043}, R_s = R_NASA_2002/HCCO.MM);
          constant IdealGases.Common.DataRecord HCL(name = "HCL", MM = 0.03646094, Hf = -2531750.415650282, H0 = 236968.7671244899, Tlimit = 1000, alow = {20625.88287, -309.3368855, 5.27541885, -0.00482887422, 6.1957946e-006, -3.040023782e-009, 4.916790029999999e-013}, blow = {-10677.82299, -7.309305408}, ahigh = {915774.951, -2770.550211, 5.97353979, -0.000362981006, 4.73552919e-008, 2.810262054e-012, -6.65610422e-016}, bhigh = {5674.95805, -16.42825822}, R_s = R_NASA_2002/HCL.MM);
          constant IdealGases.Common.DataRecord HD(name = "HD", MM = 0.003022042, Hf = 106981.3060175868, H0 = 2815679.596775955, Tlimit = 1000, alow = {25191.20338, -276.1004999, 4.64444129, -0.002082376844, 1.418070803e-006, 2.839893835e-010, -3.20233103e-013}, blow = {391.361643, -9.395396119999999}, ahigh = {845583.0000000001, -1956.578537, 4.40437387, 0.000575168109, -2.131983152e-007, 4.03612668e-011, -2.727170705e-015}, bhigh = {12272.54163, -10.84742878}, R_s = R_NASA_2002/HD.MM);
          constant IdealGases.Common.DataRecord HDplus(name = "HDplus", MM = 0.0030214934, Hf = 495381726.7977484, H0 = 2850908.097300494, Tlimit = 1000, alow = {-80700.73049999999, 879.643258, 0.0596893216, 0.005418181009999999, -2.021515155e-006, -4.94526165e-010, 4.09293565e-013}, blow = {174499.2497, 19.34281193}, ahigh = {1340083.03, -5730.069570000001, 12.13836576, -0.00524333812, 1.976302344e-006, -3.30657353e-010, 1.937902763e-014}, bhigh = {213534.8051, -61.2875839}, R_s = R_NASA_2002/HDplus.MM);
          constant IdealGases.Common.DataRecord HDO(name = "HDO", MM = 0.019021442, Hf = -12894946.50300435, H0 = 521817.5888032044, Tlimit = 1000, alow = {-27377.95356, 431.0503899999999, 1.558479899, 0.005764969149999999, -4.85512936e-006, 3.38299017e-009, -1.040863879e-012}, blow = {-32732.2645, 14.87751891}, ahigh = {1711376.798, -5322.8723, 9.124351519999999, -0.000340066415, 4.152343519999999e-008, -4.78076857e-014, -1.46803517e-016}, bhigh = {3245.22468, -37.7460068}, R_s = R_NASA_2002/HDO.MM);
          constant IdealGases.Common.DataRecord HDO2(name = "HDO2", MM = 0.035020842, Hf = -4004519.223152887, H0 = 323663.4059226788, Tlimit = 1000, alow = {-32164.7665, 749.2334460000001, -1.957676212, 0.02412802791, -2.915946684e-005, 1.930016324e-008, -5.22698631e-012}, blow = {-21510.59175, 36.7240674}, ahigh = {1313180.619, -5175.63712, 12.16490975, -0.000613669948, 1.227560176e-007, -1.079624939e-011, 3.87401372e-016}, bhigh = {13032.0967, -50.85276870000001}, R_s = R_NASA_2002/HDO2.MM);
          constant IdealGases.Common.DataRecord HF(name = "HF", MM = 0.0200063432, Hf = -13660667.38273289, H0 = 429818.8286603021, Tlimit = 1000, alow = {-3192.09897, 59.8680772, 3.055113902, 0.001684673783, -3.28739483e-006, 3.095923617e-009, -9.76469161e-013}, blow = {-34184.4316, 3.29490412}, ahigh = {725708.904, -1484.797741, 3.85552747, 0.000713898985, -2.106757333e-007, 3.050092453e-011, -1.639495583e-015}, bhigh = {-23554.5666, -3.20385683}, R_s = R_NASA_2002/HF.MM);
          constant IdealGases.Common.DataRecord HI(name = "HI", MM = 0.12791241, Hf = 206070.7010367485, H0 = 67675.21618895305, Tlimit = 1000, alow = {18728.8173, -343.178884, 5.95671243, -0.008543439599999999, 1.454780274e-005, -1.049104164e-008, 2.839734003e-012}, blow = {3682.95072, -8.14975609}, ahigh = {472492.145, -1923.465741, 5.75804897, -0.000406626638, 9.474332049999999e-008, -1.033534431e-011, 4.61161479e-016}, bhigh = {13948.57037, -11.82487652}, R_s = R_NASA_2002/HI.MM);
          constant IdealGases.Common.DataRecord HNC(name = "HNC", MM = 0.02702534, Hf = 7192439.429069164, H0 = 370049.8865139163, Tlimit = 1000, alow = {48706.2064, -989.1456249999999, 9.72215389, -0.01113593916, 1.668862707e-005, -1.113940941e-008, 2.893600868e-012}, blow = {26646.79758, -31.04826344}, ahigh = {1198791.66, -3918.94186, 9.11802009, -0.00034177611, 3.31480968e-008, -5.70157474e-013, -7.789455389999999e-017}, bhigh = {46588.103, -34.68575882}, R_s = R_NASA_2002/HNC.MM);
          constant IdealGases.Common.DataRecord HNCO(name = "HNCO", MM = 0.04302474, Hf = -2743921.962108313, H0 = 254879.5413987394, Tlimit = 1000, alow = {75424.6008, -955.0937770000001, 6.72570587, 0.0047056875, -4.95947551e-006, 3.69425512e-009, -1.164859121e-012}, blow = {-10681.49742, -13.65584762}, ahigh = {1253216.926, -5021.091539999999, 12.47789314, -0.000689165525, 1.097738448e-007, -9.3064038e-012, 3.24260695e-016}, bhigh = {14531.55559, -53.06419819}, R_s = R_NASA_2002/HNCO.MM);
          constant IdealGases.Common.DataRecord HNO(name = "HNO", MM = 0.03101404, Hf = 3289888.224816889, H0 = 320560.6235111581, Tlimit = 1000, alow = {-68547.6486, 955.16272, -0.600072021, 0.007995176749999999, -6.54707916e-007, -3.6705134e-009, 1.783392519e-012}, blow = {6435.35126, 30.48166179}, ahigh = {-5795614.98, 19454.57427, -21.52568374, 0.01797428992, -4.97604067e-006, 6.397924169999999e-010, -3.142619368e-014}, bhigh = {-110419.2372, 181.8650338}, R_s = R_NASA_2002/HNO.MM);
          constant IdealGases.Common.DataRecord HNO2(name = "HNO2", MM = 0.04701344, Hf = -1668712.648978675, H0 = 246680.2046393542, Tlimit = 1000, alow = {8591.985060000001, 120.3644046, 0.9412979119999999, 0.01942891839, -2.253174194e-005, 1.384587594e-008, -3.47355046e-012}, blow = {-11063.37202, 20.73967331}, ahigh = {878790.4129999999, -3990.45503, 11.87349269, -0.000488190061, 7.13363679e-008, -5.37630334e-012, 1.581778986e-016}, bhigh = {12463.43241, -46.08874688}, R_s = R_NASA_2002/HNO2.MM);
          constant IdealGases.Common.DataRecord HNO3(name = "HNO3", MM = 0.06301284, Hf = -2125167.965766977, H0 = 188475.7138386399, Tlimit = 1000, alow = {9202.86901, 109.3774496, -0.452104245, 0.02984914503, -3.1906355e-005, 1.720931528e-008, -3.78264983e-012}, blow = {-17640.48507, 27.46644879}, ahigh = {-94978.0964, -2733.024468, 14.49426995, -0.000782186805, 1.702693665e-007, -1.930543961e-011, 8.870455120000001e-016}, bhigh = {-4882.51778, -59.28392985000001}, R_s = R_NASA_2002/HNO3.MM);
          constant IdealGases.Common.DataRecord HOCL(name = "HOCL", MM = 0.05246034, Hf = -1443757.932182674, H0 = 194902.0155035213, Tlimit = 1000, alow = {-9739.307430000001, 354.756952, 0.1539514254, 0.01617051795, -2.179693631e-005, 1.509103049e-008, -4.12538351e-012}, blow = {-11763.23791, 24.73257759}, ahigh = {853045.781, -2847.760552, 7.94832904, -0.0001048782013, -1.482405043e-008, 4.59167827e-012, -3.060073987e-016}, bhigh = {7250.964950000001, -22.4983169}, R_s = R_NASA_2002/HOCL.MM);
          constant IdealGases.Common.DataRecord HOF(name = "HOF", MM = 0.0360057432, Hf = -2691187.915821163, H0 = 280189.6059737493, Tlimit = 1000, alow = {-36968.883, 780.900666, -2.077685317, 0.02038690173, -2.586919999e-005, 1.713797538e-008, -4.55128187e-012}, blow = {-16317.20064, 36.450525}, ahigh = {881201.823, -3120.013169, 8.223710069999999, -0.0002298036315, 1.459115709e-008, 1.095883303e-012, -1.404445608e-016}, bhigh = {6300.54671, -25.90150427}, R_s = R_NASA_2002/HOF.MM);
          constant IdealGases.Common.DataRecord HO2(name = "HO2", MM = 0.03300674, Hf = 364168.0456779433, H0 = 0, Tlimit = 1000, alow = {-75988.8254, 1329.383918, -4.67738824, 0.02508308202, -3.006551588e-005, 1.895600056e-008, -4.82856739e-012}, blow = {-5.873350960e+003, 5.193602140e+001}, ahigh = {-1810669.724, 4963.19203, -1.039498992, 0.004560148530000001, -1.061859447e-006, 1.144567878e-010, -4.763064160e-015}, bhigh = {-3.200817190e+004, 4.066850920e+001}, R_s = R_NASA_2002/HO2.MM);
          constant IdealGases.Common.DataRecord HO2minus(name = "HO2minus", MM = 0.0330072886, Hf = -2966710.813077812, H0 = 0, Tlimit = 1000, alow = {110383.9835, -1047.963653, 6.36001399, 0.002942520461, -6.284141339999999e-006, 5.43825424e-009, -1.64730582e-012}, blow = {-7.417741590e+003, -1.251878002e+001}, ahigh = {793330.6, -2503.312417, 7.54896233, 8.308390149999999e-005, -5.96973091e-008, 9.955377000000001e-012, -5.606477280e-016}, bhigh = {2.512079084e+003, -2.070065846e+001}, R_s = R_NASA_2002/HO2minus.MM);
          constant IdealGases.Common.DataRecord HPO(name = "HPO", MM = 0.04798110100000001, Hf = -1185232.473093937, H0 = 209777.241251717, Tlimit = 1000, alow = {-38163.1412, 792.764187, -1.889940652, 0.01800907425, -1.857631793e-005, 1.018768867e-008, -2.355583619e-012}, blow = {-11576.4124, 36.9292591}, ahigh = {384245.945, -2434.951707, 8.582173920000001, -0.000405844857, -1.66948874e-008, 2.253640566e-011, -1.943063011e-015}, bhigh = {5761.63212, -26.49097544}, R_s = R_NASA_2002/HPO.MM);
          constant IdealGases.Common.DataRecord HSO3F(name = "HSO3F", MM = 0.1000695432, Hf = -7525966.202272021, H0 = 150037.3991914055, Tlimit = 1000, alow = {6896.24213, -93.05810749999999, 1.570331788, 0.0378082075, -4.87272078e-005, 3.160796011e-008, -8.189782929999999e-012}, blow = {-91802.40820000001, 17.16315977}, ahigh = {554404.708, -3974.42432, 17.78869264, -0.000440932203, 5.94441139e-008, -3.92701581e-012, 8.891284000000001e-017}, bhigh = {-71534.3827, -76.13127849}, R_s = R_NASA_2002/HSO3F.MM);
          constant IdealGases.Common.DataRecord H2(name = "H2", MM = 0.00201588, Hf = 0, H0 = 4200697.462150524, Tlimit = 1000, alow = {40783.2321, -800.918604, 8.21470201, -0.01269714457, 1.753605076e-005, -1.20286027e-008, 3.36809349e-012}, blow = {2682.484665, -30.43788844}, ahigh = {560812.801, -837.150474, 2.975364532, 0.001252249124, -3.74071619e-007, 5.936625200000001e-011, -3.6069941e-015}, bhigh = {5339.82441, -2.202774769}, R_s = R_NASA_2002/H2.MM);
          constant IdealGases.Common.DataRecord H2plus(name = "H2plus", MM = 0.0020153314, Hf = 741650941.3786734, H0 = 4258904.01945804, Tlimit = 1000, alow = {-31208.8606, 230.4622909, 3.33556442, -0.002419056763, 7.006022340000001e-006, -5.61001066e-009, 1.564169746e-012}, blow = {177410.4638, -0.8278523760000001}, ahigh = {1672225.964, -6595.18499, 12.79321925, -0.00550934526, 2.030669412e-006, -3.35102748e-010, 1.946089104e-014}, bhigh = {218999.9548, -67.9271078}, R_s = R_NASA_2002/H2plus.MM);
          constant IdealGases.Common.DataRecord H2minus(name = "H2minus", MM = 0.0020164286, Hf = 116626178.5812798, H0 = 4275178.402052024, Tlimit = 1000, alow = {-97535.65670000001, 1221.166236, -2.264588838, 0.01237202227, -1.12710002e-005, 5.36723995e-009, -1.04942016e-012}, blow = {21213.99948, 30.50556136}, ahigh = {95992.7562, -914.4682879999999, 5.14941881, -0.0001016559478, 5.446919560000001e-008, -6.155174449999999e-012, 2.822451181e-016}, bhigh = {32341.0518, -14.4078098}, R_s = R_NASA_2002/H2minus.MM);
          constant IdealGases.Common.DataRecord HBOH(name = "HBOH", MM = 0.02882628, Hf = -1690275.817760738, H0 = 379533.3979965504, Tlimit = 1000, alow = {-61596.4419, 1223.483035, -5.46037051, 0.0355538868, -4.67502014e-005, 3.23600885e-008, -8.98605332e-012}, blow = {-12636.59051, 54.2235229}, ahigh = {1534611.049, -5753.66643, 12.70893665, -0.000705962825, 1.027679375e-007, -7.67092674e-012, 2.211854768e-016}, bhigh = {27793.70419, -56.0886008}, R_s = R_NASA_2002/HBOH.MM);
          constant IdealGases.Common.DataRecord HCOOH(name = "HCOOH", MM = 0.04602538, Hf = -8225244.419492028, H0 = 237426.589416535, Tlimit = 1000, alow = {-29062.79097, 765.837888, -3.32841413, 0.02817542991, -2.370050804e-005, 1.166063663e-008, -2.79137317e-012}, blow = {-50064.4347, 43.8709423}, ahigh = {487233.645, -7632.238079999999, 21.32788153, -0.004402546540000001, 1.102001695e-006, -1.364343517e-010, 6.64842975e-015}, bhigh = {-5781.43191, -111.1790688}, R_s = R_NASA_2002/HCOOH.MM);
          constant IdealGases.Common.DataRecord H2F2(name = "H2F2", MM = 0.0400126864, Hf = -14243576.95713228, H0 = 346625.8141567821, Tlimit = 1000, alow = {52592.1471, -991.3544890000001, 10.43577115, -0.002407796033, -6.376956159999999e-007, 2.7357849e-009, -1.10434859e-012}, blow = {-65724.60829999999, -30.38432132}, ahigh = {1464995.601, -3335.07492, 9.187487040000001, 0.001051127249, -3.27860557e-007, 4.45604623e-011, -2.281370136e-015}, bhigh = {-48254.42090000001, -26.39128168}, R_s = R_NASA_2002/H2F2.MM);
          constant IdealGases.Common.DataRecord H2O(name = "H2O", MM = 0.01801528, Hf = -13423382.81725291, H0 = 549760.6476280135, Tlimit = 1000, alow = {-39479.6083, 575.573102, 0.931782653, 0.00722271286, -7.34255737e-006, 4.95504349e-009, -1.336933246e-012}, blow = {-33039.7431, 17.24205775}, ahigh = {1034972.096, -2412.698562, 4.64611078, 0.002291998307, -6.836830479999999e-007, 9.426468930000001e-011, -4.82238053e-015}, bhigh = {-13842.86509, -7.97814851}, R_s = R_NASA_2002/H2O.MM);
          constant IdealGases.Common.DataRecord H2Oplus(name = "H2Oplus", MM = 0.0180147314, Hf = 54488837.17466918, H0 = 551463.4539596855, Tlimit = 1000, alow = {-1753.89272, 224.9850054, 1.989400675, 0.00611789516, -7.09543664e-006, 5.54765947e-009, -1.704344789e-012}, blow = {115958.5952, 11.35409642}, ahigh = {622871.426, -2864.257487, 7.71756556, -0.000902780167, 6.17743686e-007, -1.201457479e-010, 7.407709940000001e-015}, bhigh = {134208.6651, -26.3661792}, R_s = R_NASA_2002/H2Oplus.MM);
          constant IdealGases.Common.DataRecord H2O2(name = "H2O2", MM = 0.03401468, Hf = -3994745.79799075, H0 = 328059.3849479107, Tlimit = 1000, alow = {-92795.3358, 1564.748385, -5.97646014, 0.0327074452, -3.93219326e-005, 2.509255235e-008, -6.46504529e-012}, blow = {-24940.04728, 58.7717418}, ahigh = {1489428.027, -5170.82178, 11.2820497, -8.04239779e-005, -1.818383769e-008, 6.94726559e-012, -4.8278319e-016}, bhigh = {14182.51038, -46.50855660000001}, R_s = R_NASA_2002/H2O2.MM);
          constant IdealGases.Common.DataRecord H2S(name = "H2S", MM = 0.03408088, Hf = -604444.4861752396, H0 = 292199.6439059085, Tlimit = 1000, alow = {9543.80881, -68.7517508, 4.05492196, -0.0003014557336, 3.76849775e-006, -2.239358925e-009, 3.086859108e-013}, blow = {-3278.45728, 1.415194691}, ahigh = {1430040.22, -5284.02865, 10.16182124, -0.000970384996, 2.154003405e-007, -2.1696957e-011, 9.318163070000001e-016}, bhigh = {29086.96214, -43.49160391}, R_s = R_NASA_2002/H2S.MM);
          constant IdealGases.Common.DataRecord H2SO4(name = "H2SO4", MM = 0.09807848, Hf = -7470871.500047717, H0 = 168320.1962346888, Tlimit = 1000, alow = {-41291.5005, 668.158989, -2.632753507, 0.0541538248, -7.067502229999999e-005, 4.68461142e-008, -1.236791238e-011}, blow = {-93156.60120000001, 39.61096201}, ahigh = {1437877.914, -6614.90253, 21.57662058, -0.000480625597, 3.010775121e-008, 2.334842469e-012, -2.946330375e-016}, bhigh = {-52590.92950000001, -102.3603724}, R_s = R_NASA_2002/H2SO4.MM);
          constant IdealGases.Common.DataRecord H2BOH(name = "H2BOH", MM = 0.02983422, Hf = -9708110.284096584, H0 = 356044.3678433691, Tlimit = 1000, alow = {-86867.6678, 1820.335089, -10.32373881, 0.0492280106, -5.97861991e-005, 3.94606273e-008, -1.068442257e-011}, blow = {-44152.3815, 79.86177289999999}, ahigh = {2294795.193, -9382.923559999999, 17.98228329, -0.001506116214, 2.635641095e-007, -2.483163637e-011, 9.736759120000001e-016}, bhigh = {20397.38953, -94.48201210000001}, R_s = R_NASA_2002/H2BOH.MM);
          constant IdealGases.Common.DataRecord HB_OH_2(name = "HB_OH_2", MM = 0.04583362000000001, Hf = -14060393.30954003, H0 = 265253.5845957617, Tlimit = 1000, alow = {-20670.44022, 953.4459160000001, -8.08895652, 0.0597242529, -8.071336320000001e-005, 5.61211835e-008, -1.553607566e-011}, blow = {-82642.70809999999, 65.3957164}, ahigh = {2122674.609, -8615.948939999998, 19.6617952, -0.00081484115, 8.955082040000001e-008, -3.34483051e-012, -6.919578139999999e-017}, bhigh = {-27887.90377, -99.8355961}, R_s = R_NASA_2002/HB_OH_2.MM);
          constant IdealGases.Common.DataRecord H3BO3(name = "H3BO3", MM = 0.06183302, Hf = -16243108.32626322, H0 = 219299.6234050998, Tlimit = 1000, alow = {25689.01843, 113.8029495, -4.04509658, 0.0592452168, -8.148028410000001e-005, 5.65859329e-008, -1.54927705e-011}, blow = {-122170.205, 41.3222014}, ahigh = {2297369.132, -8933.57179, 21.93496552, -0.000309478349, -5.06405299e-008, 1.482296684e-011, -9.7644209e-016}, bhigh = {-69702.9847, -112.2292829}, R_s = R_NASA_2002/H3BO3.MM);
          constant IdealGases.Common.DataRecord H3B3O3(name = "H3B3O3", MM = 0.08345502000000001, Hf = -14424069.24113133, H0 = 186966.8355480593, Tlimit = 1000, alow = {-198528.4188, 4104.13209, -28.27215617, 0.1269639253, -0.0001558505781, 9.96630407e-008, -2.60367765e-011}, blow = {-164849.4375, 176.3917407}, ahigh = {1286220.713, -10932.58784, 32.1351867, -0.002595402269, 5.35376647e-007, -5.833567379999999e-011, 2.600757913e-015}, bhigh = {-87528.5689, -177.0847815}, R_s = R_NASA_2002/H3B3O3.MM);
          constant IdealGases.Common.DataRecord H3B3O6(name = "H3B3O6", MM = 0.13145322, Hf = -17220480.49488632, H0 = 180268.3342408805, Tlimit = 1000, alow = {-20670.31503, 708.339154, -7.12382095, 0.1025049979, -0.0001295004602, 8.322737589999999e-008, -2.145746724e-011}, blow = {-277804.9216, 60.6359763}, ahigh = {1952433.352, -11549.32896, 38.9267611, -0.00111385228, 1.280317726e-007, -5.72846482e-012, -2.214529572e-017}, bhigh = {-212092.7136, -207.5566801}, R_s = R_NASA_2002/H3B3O6.MM);
          constant IdealGases.Common.DataRecord H3F3(name = "H3F3", MM = 0.0600190296, Hf = -14723276.86550934, H0 = 254303.0452461697, Tlimit = 1000, alow = {98885.62650000001, -1380.21288, 8.98045847, 0.01871609057, -3.127862508e-005, 2.589436165e-008, -8.04037227e-012}, blow = {-101366.1491, -25.85302557}, ahigh = {2515790.373, -8789.42332, 20.23933445, -0.001131704646, 1.692779921e-007, -1.308662105e-011, 3.978322e-016}, bhigh = {-54717.1365, -99.07787640000001}, R_s = R_NASA_2002/H3F3.MM);
          constant IdealGases.Common.DataRecord H3Oplus(name = "H3Oplus", MM = 0.0190226714, Hf = 31436173.57549476, H0 = 528129.1354273196, Tlimit = 1000, alow = {-64476.4015, 1181.817922, -3.80189306, 0.02220628313, -2.445343237e-005, 1.573297747e-008, -4.15883641e-012}, blow = {65306.1332, 42.8272313}, ahigh = {2955126.2, -9185.669409999999, 13.41398696, -0.000559033921, 1.138387119e-008, 7.25992721e-012, -6.13373436e-016}, bhigh = {129053.4257, -70.2182818}, R_s = R_NASA_2002/H3Oplus.MM);
          constant IdealGases.Common.DataRecord H4F4(name = "H4F4", MM = 0.08002537279999999, Hf = -14831950.09870669, H0 = 270590.1796186322, Tlimit = 1000, alow = {131510.9024, -1840.36156, 12.64093152, 0.0249540736, -4.17039461e-005, 3.45252384e-008, -1.07203436e-011}, blow = {-136400.3454, -41.2291353}, ahigh = {3354037.99, -11719.2204, 27.65243565, -0.001508934621, 2.257027572e-007, -1.744867255e-011, 5.304351740000001e-016}, bhigh = {-74202.13160000001, -138.8603332}, R_s = R_NASA_2002/H4F4.MM);
          constant IdealGases.Common.DataRecord H5F5(name = "H5F5", MM = 0.100031716, Hf = -14897154.03862511, H0 = 280362.4602421096, Tlimit = 1000, alow = {164136.1897, -2300.510396, 16.30140545, 0.03119205422, -5.21292635e-005, 4.31561124e-008, -1.340031413e-011}, blow = {-171434.5408, -56.8215738}, ahigh = {4192290.73, -14649.03043, 35.0655492, -0.001886170471, 2.821289954e-007, -2.181090984e-011, 6.63047416e-016}, bhigh = {-93687.042, -178.8592044}, R_s = R_NASA_2002/H5F5.MM);
          constant IdealGases.Common.DataRecord H6F6(name = "H6F6", MM = 0.1200380592, Hf = -15041438.88224411, H0 = 286030.0577068977, Tlimit = 1000, alow = {195688.6618, -2753.90988, 19.75625055, 0.0380771701, -6.341218879999999e-005, 5.21923329e-008, -1.612185649e-011}, blow = {-207926.941, -71.13607980000001}, ahigh = {5024520.319999999, -17428.17868, 42.148705, -0.002084564791, 2.930051519e-007, -2.052079159e-011, 5.2069373e-016}, bhigh = {-115449.7653, -216.3947001}, R_s = R_NASA_2002/H6F6.MM);
          constant IdealGases.Common.DataRecord H7F7(name = "H7F7", MM = 0.1400444024, Hf = -14993094.60440098, H0 = 291530.7809546553, Tlimit = 1000, alow = {229386.7477, -3220.80786, 23.62235212, 0.0436680188, -7.29799034e-005, 6.041786420000001e-008, -1.876025627e-011}, blow = {-241863.7479, -88.38812259999999}, ahigh = {5868789.83, -20508.63473, 49.8917611, -0.002640634895, 3.94979633e-007, -3.053515088e-011, 9.28260178e-016}, bhigh = {-133017.7809, -259.2385142}, R_s = R_NASA_2002/H7F7.MM);
          constant IdealGases.Common.DataRecord He(name = "He", MM = 0.004002602, Hf = 0, H0 = 1548349.798456104, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {-745.375, 0.9287239740000001}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {-745.375, 0.9287239740000001}, R_s = R_NASA_2002/He.MM);
          constant IdealGases.Common.DataRecord Heplus(name = "Heplus", MM = 0.0040020534, Hf = 594325271.3719412, H0 = 1548562.045673853, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {285323.3739, 1.621665557}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {285323.3739, 1.621665557}, R_s = R_NASA_2002/Heplus.MM);
          constant IdealGases.Common.DataRecord Hg(name = "Hg", MM = 0.20059, Hf = 305997.3079415724, H0 = 30895.99680941224, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {6636.90008, 6.80020154}, ahigh = {51465.7351, -168.1269855, 2.718343098, -0.0001445026192, 5.15897766e-008, -9.47248501e-012, 7.034797406e-016}, bhigh = {7688.68493, 5.27123609}, R_s = R_NASA_2002/Hg.MM);
          constant IdealGases.Common.DataRecord Hgplus(name = "Hgplus", MM = 0.2005894514, Hf = 5357425.928928983, H0 = 30896.08130809215, Tlimit = 1000, alow = {0.000409834494, -4.34358162e-006, 2.500000019, -4.389036810000001e-011, 5.5639692e-014, -3.63822826e-017, 9.607881994999999e-021}, blow = {128503.7483, 7.4933445}, ahigh = {-12299.84728, 27.32269908, 2.48418216, -4.42679761e-006, 7.489685859999999e-009, -2.549887287e-012, 2.819873366e-016}, bhigh = {128318.8257, 7.62524457}, R_s = R_NASA_2002/Hgplus.MM);
          constant IdealGases.Common.DataRecord HgBr2(name = "HgBr2", MM = 0.3603980000000001, Hf = -253363.2706063851, H0 = 43447.47751097397, Tlimit = 1000, alow = {-1991.826537, -190.2186083, 8.246401260000001, -0.001607089392, 1.947654549e-006, -1.242873546e-009, 3.24181831e-013}, blow = {-12307.23096, -8.7166593}, ahigh = {-22436.4929, -3.31265227, 7.50276517, -1.202360213e-006, 2.830526999e-010, -3.4076867e-014, 1.640497921e-018}, bhigh = {-13274.83366, -4.3685556}, R_s = R_NASA_2002/HgBr2.MM);
          constant IdealGases.Common.DataRecord I(name = "I", MM = 0.12690447, Hf = 841262.7230545938, H0 = 48835.37987274995, Tlimit = 1000, alow = {169.8199675, -2.716437233, 2.517385557, -5.73069207e-005, 1.031716184e-007, -9.670641930000001e-011, 3.706471651e-014}, blow = {12107.5009, 7.40582313}, ahigh = {-778586.0569999999, 2303.279568, 0.002886686091, 0.001180878463, -2.264074866e-007, 1.963511339e-011, -6.243525940999999e-016}, bhigh = {-2616.792742, 25.58922997}, R_s = R_NASA_2002/I.MM);
          constant IdealGases.Common.DataRecord Iplus(name = "Iplus", MM = 0.1269039214, Hf = 8836220.470016144, H0 = 48835.59098592204, Tlimit = 1000, alow = {-801.496901, 8.13905261, 2.47017476, 4.16139382e-005, 7.133397859999999e-009, -7.10595014e-011, 4.873766102e-014}, blow = {134079.4213, 7.90342009}, ahigh = {-778838.5329999999, 2404.962651, -0.1791751142, 0.001227311979, -1.80149403e-007, 9.923983959999999e-012, -9.775286439000001e-017}, bhigh = {118853.1631, 27.10544347}, R_s = R_NASA_2002/Iplus.MM);
          constant IdealGases.Common.DataRecord Iminus(name = "Iminus", MM = 0.1269050186, Hf = -1533395.401905721, H0 = 48835.1687614031, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {-24149.70936, 6.11346538}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {-24149.70936, 6.11346538}, R_s = R_NASA_2002/Iminus.MM);
          constant IdealGases.Common.DataRecord IF5(name = "IF5", MM = 0.221896486, Hf = -3790055.512641151, H0 = 90331.04742361714, Tlimit = 1000, alow = {202618.453, -3598.18317, 25.30349738, -0.01348602458, 1.105687229e-005, -4.70793951e-009, 7.86441147e-013}, blow = {-87001.4725, -111.2719941}, ahigh = {-362050.626, -163.9236093, 16.12272743, -4.91443155e-005, 1.086015052e-008, -1.244672691e-012, 5.76359362e-017}, bhigh = {-106164.2293, -53.9877336}, R_s = R_NASA_2002/IF5.MM);
          constant IdealGases.Common.DataRecord IF7(name = "IF7", MM = 0.2598932924, Hf = -3699595.288208369, H0 = 92820.14467257561, Tlimit = 1000, alow = {299985.3564, -5501.55413, 36.2713398, -0.02095765818, 1.76197268e-005, -7.82914233e-009, 1.405939372e-012}, blow = {-93313.0766, -175.421615}, ahigh = {-561442.264, -264.6288326, 22.19879891, -7.984221469999999e-005, 1.768835964e-008, -2.031523755e-012, 9.423767390000001e-017}, bhigh = {-122524.5322, -87.74010730000001}, R_s = R_NASA_2002/IF7.MM);
          constant IdealGases.Common.DataRecord I2(name = "I2", MM = 0.25380894, Hf = 245933.0234782116, H0 = 39857.23276729338, Tlimit = 1000, alow = {-5087.96877, -12.4958521, 4.50421909, 0.0001370962533, -1.390523014e-007, 1.174813853e-010, -2.337541043e-014}, blow = {6213.469810000001, 5.58383694}, ahigh = {-5632594.16, 17939.6156, -17.23055169, 0.0124421408, -3.33276858e-006, 4.12547794e-010, -1.960461713e-014}, bhigh = {-106850.5292, 160.0531883}, R_s = R_NASA_2002/I2.MM);
          constant IdealGases.Common.DataRecord In(name = "In", MM = 0.114818, Hf = 2096361.197721611, H0 = 53986.73552927241, Tlimit = 1000, alow = {51495.1805, -917.799902, 8.93868795, -0.02224112602, 3.82388194e-005, -2.890116948e-008, 8.047481221e-012}, blow = {32390.3162, -27.64567028}, ahigh = {-1683608.899, 2210.473186, 3.47221937, -0.001082267422, 3.47969998e-007, -5.15809241e-011, 3.183043089e-015}, bhigh = {10959.65206, 2.557189088}, R_s = R_NASA_2002/In.MM);
          constant IdealGases.Common.DataRecord Inplus(name = "Inplus", MM = 0.1148174514, Hf = 60935.2055344437, H0 = 53976.35920701163, Tlimit = 1000, alow = {0.2150488908, -0.002523854672, 2.500011877, -2.869063919e-008, 3.7538704e-011, -2.525942419e-014, 6.84293266e-018}, blow = {96.1093017, 5.9632544}, ahigh = {45369.9514, -144.5142103, 2.681812441, -0.000115748006, 3.94771481e-008, -6.87924362e-012, 4.81920492e-016}, bhigh = {1004.26144, 4.68375918}, R_s = R_NASA_2002/Inplus.MM);
          constant IdealGases.Common.DataRecord InBr(name = "InBr", MM = 0.194722, Hf = -277913.5331395528, H0 = 51787.27108390423, Tlimit = 1000, alow = {-2540.851435, -52.94704710000001, 4.71743809, -0.000434466949, 6.51351364e-007, -4.40399515e-010, 1.234046209e-013}, blow = {-7607.59428, 4.258881}, ahigh = {794837.442, -2318.183711, 7.03288958, -0.001245920568, 3.27669335e-007, -3.003771106e-011, 5.85319277e-016}, bhigh = {6957.627289999999, -12.7350266}, R_s = R_NASA_2002/InBr.MM);
          constant IdealGases.Common.DataRecord InBr2(name = "InBr2", MM = 0.274626, Hf = -545210.7921318448, H0 = 52523.58116128844, Tlimit = 1000, alow = {-66.19878900000001, -236.589731, 7.92654516, -0.001994547959, 2.420414153e-006, -1.548924922e-009, 4.05814839e-013}, blow = {-18953.55588, -5.33886754}, ahigh = {-321716.203, 479.2682100000001, 7.10264948, -0.000551401978, 3.157862421e-007, -5.51125451e-011, 3.17216139e-015}, bhigh = {-23709.23659, 0.1193263347}, R_s = R_NASA_2002/InBr2.MM);
          constant IdealGases.Common.DataRecord InBr3(name = "InBr3", MM = 0.35453, Hf = -723739.2237610358, H0 = 56166.56700420276, Tlimit = 1000, alow = {-4990.1153, -280.5930452, 11.1035606, -0.002379995808, 2.887825281e-006, -1.844500707e-009, 4.81439587e-013}, blow = {-32505.0491, -18.71748987}, ahigh = {-35057.831, -4.85872132, 10.00406131, -1.767620958e-006, 4.16401606e-010, -5.01552887e-014, 2.415414123e-018}, bhigh = {-33931.7924, -12.29069868}, R_s = R_NASA_2002/InBr3.MM);
          constant IdealGases.Common.DataRecord InCL(name = "InCL", MM = 0.150271, Hf = -480118.4726261222, H0 = 64896.86632816712, Tlimit = 1000, alow = {6430.71303, -217.8267726, 5.4188309, -0.0020480051, 2.702295936e-006, -1.795319798e-009, 4.84746909e-013}, blow = {-8959.84107, -1.202999253}, ahigh = {-274575.1636, 894.0986909999999, 3.26811839, 0.0009180277780000001, -3.083262431e-007, 5.74545881e-011, -3.64527575e-015}, bhigh = {-15616.0343, 12.66880374}, R_s = R_NASA_2002/InCL.MM);
          constant IdealGases.Common.DataRecord InCL2(name = "InCL2", MM = 0.185724, Hf = -1084853.955331567, H0 = 75145.82929508302, Tlimit = 1000, alow = {9935.164869999999, -417.210186, 8.58849491, -0.00334838561, 3.99786664e-006, -2.525301853e-009, 6.54449033e-013}, blow = {-24264.80269, -11.64521725}, ahigh = {-332871.984, 475.769161, 7.10544369, -0.000552578696, 3.160567738e-007, -5.51445368e-011, 3.17368038e-015}, bhigh = {-29950.95917, -2.294555511}, R_s = R_NASA_2002/InCL2.MM);
          constant IdealGases.Common.DataRecord InCL3(name = "InCL3", MM = 0.221177, Hf = -1671481.333954254, H0 = 82769.78618934158, Tlimit = 1000, alow = {26147.43044, -841.460456, 13.1178479, -0.00643528247, 7.55487475e-006, -4.70507856e-009, 1.204213663e-012}, blow = {-43264.6958, -35.0008094}, ahigh = {-71140.4363, -16.28425068, 10.01309622, -5.54452888e-006, 1.279877732e-009, -1.518261505e-013, 7.22656277e-018}, bhigh = {-47589.7417, -16.69761011}, R_s = R_NASA_2002/InCL3.MM);
          constant IdealGases.Common.DataRecord InF(name = "InF", MM = 0.1338164032, Hf = -1445413.150964142, H0 = 68878.7830160421, Tlimit = 1000, alow = {31901.2332, -529.525426, 6.17288626, -0.002986035832, 3.23377803e-006, -1.856975575e-009, 4.46502497e-013}, blow = {-21871.76282, -7.59121662}, ahigh = {-468900.12, 1321.019051, 2.881329353, 0.001041591078, -3.090754867e-007, 4.92664656e-011, -2.699156425e-015}, bhigh = {-33083.6981, 13.96688303}, R_s = R_NASA_2002/InF.MM);
          constant IdealGases.Common.DataRecord InF2(name = "InF2", MM = 0.1528148064, Hf = -2991770.462367971, H0 = 82379.29489010562, Tlimit = 1000, alow = {75224.8021, -1088.616881, 9.481705209999999, -0.002893229367, 1.516224649e-006, -7.98951781e-011, -1.466781026e-013}, blow = {-51243.36150000001, -21.4666609}, ahigh = {431896.034, -1688.47242, 8.925863010000001, -0.001049188835, 2.72393419e-007, -2.882959902e-011, 1.073493779e-015}, bhigh = {-46736.91940000001, -19.32464363}, R_s = R_NASA_2002/InF2.MM);
          constant IdealGases.Common.DataRecord InF3(name = "InF3", MM = 0.1718132096, Hf = -5023359.775475611, H0 = 94989.40179277113, Tlimit = 1000, alow = {107160.8336, -1660.071901, 13.95972813, -0.00501869326, 3.22636753e-006, -7.823385970000001e-010, -3.7269998e-014}, blow = {-97952.1499, -46.06353470000001}, ahigh = {-165685.5506, -79.6588929, 10.05913347, -2.350816639e-005, 5.16351293e-009, -5.88804881e-013, 2.715090697e-017}, bhigh = {-106868.2627, -21.32968218}, R_s = R_NASA_2002/InF3.MM);
          constant IdealGases.Common.DataRecord InH(name = "InH", MM = 0.11582594, Hf = 1856379.529490544, H0 = 74975.46749890395, Tlimit = 1000, alow = {-51528.2872, 781.3792590000001, -0.8433385339999999, 0.01044471274, -9.761074819999999e-006, 4.540635199999999e-009, -8.169906900000001e-013}, blow = {21100.48908, 29.39346222}, ahigh = {779740.666, -3646.88208, 9.54296735, -0.00348128172, 1.304805603e-006, -2.182950701e-010, 1.274009748e-014}, bhigh = {46432.9546, -36.5932923}, R_s = R_NASA_2002/InH.MM);
          constant IdealGases.Common.DataRecord InI(name = "InI", MM = 0.24172247, Hf = 109287.0017421219, H0 = 42491.39105685955, Tlimit = 1000, alow = {-468.634874, -56.8553099, 4.78184969, -0.000661936831, 1.027666742e-006, -7.27059207e-010, 2.077991102e-013}, blow = {2095.570254, 4.88551513}, ahigh = {1529221.772, -4690.373680000001, 10.04593462, -0.00314043411, 9.460834390000001e-007, -1.253862848e-010, 5.94980564e-015}, bhigh = {31524.78143, -32.9769749}, R_s = R_NASA_2002/InI.MM);
          constant IdealGases.Common.DataRecord InI2(name = "InI2", MM = 0.36862694, Hf = -107047.637375608, H0 = 40454.87559862011, Tlimit = 1000, alow = {-4513.8906, -118.372687, 7.47311008, -0.00103447409, 1.271465534e-006, -8.2278203e-010, 2.178307019e-013}, blow = {-6278.53604, -0.66672975}, ahigh = {-313067.1665, 481.38107, 7.10091418, -0.000550655992, 3.156120735e-007, -5.50917054e-011, 3.17116283e-015}, bhigh = {-10430.1275, 2.141662307}, R_s = R_NASA_2002/InI2.MM);
          constant IdealGases.Common.DataRecord InI3(name = "InI3", MM = 0.49553141, Hf = -212773.4223749813, H0 = 42080.25077562692, Tlimit = 1000, alow = {-8728.397169999998, -126.5914859, 10.5065912, -0.001106109314, 1.354335766e-006, -8.709453460000001e-010, 2.28518635e-013}, blow = {-15082.69063, -12.11411745}, ahigh = {-21967.42567, -2.151167521, 10.001822, -8.002214699999999e-007, 1.897343164e-010, -2.29625246e-014, 1.109838196e-018}, bhigh = {-15724.06335, -9.17088869}, R_s = R_NASA_2002/InI3.MM);
          constant IdealGases.Common.DataRecord InO(name = "InO", MM = 0.1308174, Hf = 1116006.807962855, H0 = 69120.07882743428, Tlimit = 1000, alow = {-115472.7169, 1753.668703, -6.96503381, 0.02961698958, -3.123332334e-005, 1.43724472e-008, -2.235519898e-012}, blow = {8188.67959, 66.0862126}, ahigh = {-805213.0950000001, 1693.064203, 4.76086358, -0.00073407184, 3.22959776e-007, -4.58015038e-011, 1.954611725e-015}, bhigh = {4005.51981, 3.50074246}, R_s = R_NASA_2002/InO.MM);
          constant IdealGases.Common.DataRecord InOH(name = "InOH", MM = 0.13182534, Hf = -944032.0351155552, H0 = 81447.45919107813, Tlimit = 1000, alow = {61234.6302, -1195.863129, 10.41427981, -0.0068700025, 6.21412878e-006, -2.408203181e-009, 3.17764178e-013}, blow = {-10798.5217, -31.8989084}, ahigh = {852512.8929999999, -2350.317172, 7.98451514, 9.91581562e-005, -6.21238545e-008, 1.016169575e-011, -5.682557639999999e-016}, bhigh = {-1536.21361, -20.43107643}, R_s = R_NASA_2002/InOH.MM);
          constant IdealGases.Common.DataRecord In2Br2(name = "In2Br2", MM = 0.389444, Hf = -504065.321329896, H0 = 55039.85938928319, Tlimit = 1000, alow = {-9221.1883, -36.1667703, 10.14728771, -0.00032557752, 4.02232748e-007, -2.604080237e-010, 6.86768955e-014}, blow = {-26448.83479, -10.00360073}, ahigh = {-12907.81804, -0.607540124, 10.00052163, -2.312058331e-007, 5.51731572e-011, -6.708620190000001e-015, 3.25384165e-019}, bhigh = {-26631.36878, -9.149949469999999}, R_s = R_NASA_2002/In2Br2.MM);
          constant IdealGases.Common.DataRecord In2Br4(name = "In2Br4", MM = 0.549252, Hf = -794732.9877724615, H0 = 57893.49333275072, Tlimit = 1000, alow = {-14255.55379, -286.6009341, 17.13866292, -0.002473506655, 3.017273071e-006, -1.93490043e-009, 5.06587425e-013}, blow = {-55937.5306, -38.3710598}, ahigh = {-44534.6371, -4.91152398, 16.00413764, -1.810579975e-006, 4.28171574e-010, -5.17199802e-014, 2.496142837e-018}, bhigh = {-57391.7541, -31.7490639}, R_s = R_NASA_2002/In2Br4.MM);
          constant IdealGases.Common.DataRecord In2Br6(name = "In2Br6", MM = 0.7090599999999999, Hf = -886643.4857416863, H0 = 60780.08631145462, Tlimit = 1000, alow = {-17589.40752, -485.903448, 23.91654505, -0.00414206149, 5.03384932e-006, -3.21910365e-009, 8.410220069999999e-013}, blow = {-79888.4446, -64.3787188}, ahigh = {-69450.3948, -8.402368170000001, 22.00703884, -3.068251799e-006, 7.23596573e-010, -8.722870580000001e-014, 4.20346991e-018}, bhigh = {-82357.59850000001, -53.221928}, R_s = R_NASA_2002/In2Br6.MM);
          constant IdealGases.Common.DataRecord In2CL2(name = "In2CL2", MM = 0.300542, Hf = -772528.8811547139, H0 = 67291.41018559803, Tlimit = 1000, alow = {-11428.48747, -141.6015827, 10.56853314, -0.00124425344, 1.526076784e-006, -9.82640281e-010, 2.58076699e-013}, blow = {-30263.27087, -15.6510496}, ahigh = {-26166.06332, -2.401955489, 10.00203984, -8.97519003e-007, 2.130755553e-010, -2.5811409e-014, 1.248404822e-018}, bhigh = {-30980.16735, -12.34946505}, R_s = R_NASA_2002/In2CL2.MM);
          constant IdealGases.Common.DataRecord In2CL4(name = "In2CL4", MM = 0.371448, Hf = -1559103.443819862, H0 = 79301.88074777628, Tlimit = 1000, alow = {9814.08308, -848.895901, 19.2341036, -0.00681567424, 8.129220730000001e-006, -5.12507685e-009, 1.324324755e-012}, blow = {-70276.8814, -55.82665695}, ahigh = {-85037.7179, -15.52464614, 16.01269668, -5.44154987e-006, 1.267594997e-009, -1.514110365e-013, 7.24540454e-018}, bhigh = {-74619.21740000001, -36.91150615}, R_s = R_NASA_2002/In2CL4.MM);
          constant IdealGases.Common.DataRecord In2CL6(name = "In2CL6", MM = 0.442354, Hf = -1994646.886882452, H0 = 86861.3418212563, Tlimit = 1000, alow = {30046.63159, -1585.621359, 27.9648947, -0.01245506052, 1.475341213e-005, -9.2526892e-009, 2.381233885e-012}, blow = {-104882.83, -97.88404639999999}, ahigh = {-149940.0484, -29.88680816, 22.02425362, -1.033652301e-005, 2.397911922e-009, -2.855307516e-013, 1.363051661e-017}, bhigh = {-113011.0233, -62.93985679999999}, R_s = R_NASA_2002/In2CL6.MM);
          constant IdealGases.Common.DataRecord In2F2(name = "In2F2", MM = 0.2676328064, Hf = -1988673.612772758, H0 = 67405.41356890992, Tlimit = 1000, alow = {7255.7171, -644.826565, 12.47539512, -0.00524608962, 6.28361621e-006, -3.97434234e-009, 1.029559356e-012}, blow = {-63848.92449999999, -31.08004586}, ahigh = {-64097.1544, -11.63740672, 10.00956511, -4.11408691e-006, 9.60882832e-010, -1.150013486e-013, 5.511437479999999e-018}, bhigh = {-67142.7785, -16.61718474}, R_s = R_NASA_2002/In2F2.MM);
          constant IdealGases.Common.DataRecord In2F4(name = "In2F4", MM = 0.3056296128, Hf = -4203742.282135299, H0 = 81023.15012323308, Tlimit = 1000, alow = {122521.3611, -2444.998374, 23.42425457, -0.0129142712, 1.308700476e-005, -7.18167393e-009, 1.648386404e-012}, blow = {-146694.2111, -89.43560050000001}, ahigh = {-220597.7486, -78.2208377, 16.05923872, -2.39402324e-005, 5.32958279e-009, -6.14460957e-013, 2.859099598e-017}, bhigh = {-159571.6347, -44.6957458}, R_s = R_NASA_2002/In2F4.MM);
          constant IdealGases.Common.DataRecord In2F6(name = "In2F6", MM = 0.3436264192, Hf = -5703868.767026397, H0 = 97684.86974356599, Tlimit = 1000, alow = {182549.0583, -3552.11171, 32.75425230000001, -0.01868064635, 1.892443162e-005, -1.038916311e-008, 2.386637271e-012}, blow = {-223964.876, -136.3626758}, ahigh = {-317096.638, -116.7440973, 22.08847456, -3.57773393e-005, 7.96895904e-009, -9.191681699999999e-013, 4.278494150000001e-017}, bhigh = {-242666.1118, -71.5532856}, R_s = R_NASA_2002/In2F6.MM);
          constant IdealGases.Common.DataRecord In2I2(name = "In2I2", MM = 0.48344494, Hf = -57531.93734947356, H0 = 45627.69030119541, Tlimit = 1000, alow = {-6681.92501, -14.49103222, 10.05929122, -0.0001314921486, 1.628373589e-007, -1.056087811e-010, 2.788963879e-014}, blow = {-6279.602599999999, -7.29113098}, ahigh = {-8148.157299999999, -0.2444544443, 10.00021086, -9.37678925e-008, 2.24298818e-011, -2.732299303e-015, 1.327135699e-019}, bhigh = {-6352.6515, -6.94772542}, R_s = R_NASA_2002/In2I2.MM);
          constant IdealGases.Common.DataRecord In2I4(name = "In2I4", MM = 0.73725388, Hf = -270114.7954623175, H0 = 45396.81635856565, Tlimit = 1000, alow = {-15010.28064, -97.447979, 16.3938395, -0.000865938021, 1.065671801e-006, -6.87925268e-010, 1.810240886e-013}, blow = {-28303.88443, -29.86294828}, ahigh = {-25056.99251, -1.642155234, 16.00140149, -6.18706628e-007, 1.472308565e-010, -1.786593333e-014, 8.652338779999999e-019}, bhigh = {-28796.55333, -27.57790375}, R_s = R_NASA_2002/In2I4.MM);
          constant IdealGases.Common.DataRecord In2I6(name = "In2I6", MM = 0.99106282, Hf = -322603.2028928297, H0 = 45494.71445210709, Tlimit = 1000, alow = {-22326.40607, -200.0786874, 22.80417927, -0.001761331313, 2.161510393e-006, -1.392400447e-009, 3.65817188e-013}, blow = {-44125.4768, -52.7380203}, ahigh = {-43119.0585, -3.39035059, 22.00288128, -1.268348706e-006, 3.0121219e-010, -3.64967671e-014, 1.765530622e-018}, bhigh = {-45138.2027, -48.0686837}, R_s = R_NASA_2002/In2I6.MM);
          constant IdealGases.Common.DataRecord In2O(name = "In2O", MM = 0.2456354, Hf = -141525.6392197542, H0 = 52095.52043394397, Tlimit = 1000, alow = {50656.535, -807.036367, 8.64206727, -0.001533035446, 2.866419382e-007, 4.98113497e-010, -2.554320291e-013}, blow = {-1924.908459, -14.90718759}, ahigh = {-92327.8636, -52.0112728, 7.03872362, -1.543821179e-005, 3.39970087e-009, -3.8854571e-013, 1.79512527e-017}, bhigh = {-6270.9268, -4.42182041}, R_s = R_NASA_2002/In2O.MM);
          constant IdealGases.Common.DataRecord K(name = "K", MM = 0.0390983, Hf = 2276313.803924979, H0 = 158508.8865756312, Tlimit = 1000, alow = {9.665143929999999, -0.1458059455, 2.500865861, -2.601219276e-006, 4.187306579999999e-009, -3.43972211e-012, 1.131569009e-015}, blow = {9959.493490000001, 5.03582226}, ahigh = {-3566422.36, 10852.89825, -10.54134898, 0.00800980135, -2.696681041e-006, 4.71529415e-010, -2.97689735e-014}, bhigh = {-58753.3701, 97.3855124}, R_s = R_NASA_2002/K.MM);
          constant IdealGases.Common.DataRecord Kplus(name = "Kplus", MM = 0.0390977514, Hf = 13146728.63769859, H0 = 158511.1106926727, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {61075.1686, 4.34740444}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {61075.1686, 4.34740444}, R_s = R_NASA_2002/Kplus.MM);
          constant IdealGases.Common.DataRecord Kminus(name = "Kminus", MM = 0.0390988486, Hf = 880284.9503859814, H0 = 158506.6625210033, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {3394.15071, 4.34744653}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {3394.15071, 4.34744653}, R_s = R_NASA_2002/Kminus.MM);
          constant IdealGases.Common.DataRecord KALF4(name = "KALF4", MM = 0.1420734508, Hf = -13428665.32245868, H0 = 150776.8754779904, Tlimit = 1000, alow = {119932.7246, -2156.457352, 18.15348004, 0.003115762809, -9.51199167e-006, 8.43175623e-009, -2.615583061e-012}, blow = {-222254.5809, -68.23299969999999}, ahigh = {-343513.537, -242.0680834, 16.1802925, -7.19381768e-005, 1.585712708e-008, -1.814017733e-012, 8.388391179999999e-017}, bhigh = {-233965.8121, -52.338987}, R_s = R_NASA_2002/KALF4.MM);
          constant IdealGases.Common.DataRecord KBO2(name = "KBO2", MM = 0.08190810000000001, Hf = -8155765.998722958, H0 = 172030.641658151, Tlimit = 1000, alow = {42963.08650000001, -720.961643, 8.34963935, 0.002407820401, -1.680003427e-007, -1.231930486e-009, 5.479951640000001e-013}, blow = {-78685.2347, -14.76077068}, ahigh = {88907.266, -1671.432436, 11.1748393, -0.000451376026, 9.69900346e-008, -1.09002769e-011, 4.9768458e-016}, bhigh = {-73753.36080000001, -32.7474937}, R_s = R_NASA_2002/KBO2.MM);
          constant IdealGases.Common.DataRecord KBr(name = "KBr", MM = 0.1190023, Hf = -1506280.786169679, H0 = 84948.96317130004, Tlimit = 1000, alow = {9203.30919, -213.7880361, 5.58850915, -0.002753854319, 4.013672610000001e-006, -2.856323127e-009, 8.13520974e-013}, blow = {-21883.87013, -1.707501588}, ahigh = {1562614.367, -4384.89478, 9.045464600000001, -0.0020456809, 4.40192385e-007, -1.448178289e-011, -2.27333876e-015}, bhigh = {5315.34201, -28.64647026}, R_s = R_NASA_2002/KBr.MM);
          constant IdealGases.Common.DataRecord KCN(name = "KCN", MM = 0.0651157, Hf = 1220842.285347466, H0 = 191295.4018769667, Tlimit = 1000, alow = {17986.27669, -630.055897, 9.988695, -0.01076486132, 1.75101498e-005, -1.265592431e-008, 3.46976281e-012}, blow = {10580.25371, -25.94060289}, ahigh = {361566.387, -1749.018011, 8.680702670000001, -0.000440235004, 9.249499710000001e-008, -1.021916855e-011, 4.604767189999999e-016}, bhigh = {18137.34856, -22.81619241}, R_s = R_NASA_2002/KCN.MM);
          constant IdealGases.Common.DataRecord KCL(name = "KCL", MM = 0.0745513, Hf = -2878217.831211528, H0 = 132594.8575008082, Tlimit = 1000, alow = {9058.35151, -245.6801212, 5.68069619, -0.002900127425, 4.13098306e-006, -2.907340629e-009, 8.22385087e-013}, blow = {-25973.04884, -3.677976854}, ahigh = {-212294.5722, 934.61589, 2.866264958, 0.001468386693, -5.83426078e-007, 1.255777709e-010, -9.150147999999999e-015}, bhigh = {-32737.8764, 14.01864636}, R_s = R_NASA_2002/KCL.MM);
          constant IdealGases.Common.DataRecord KF(name = "KF", MM = 0.0580967032, Hf = -5653416.939500278, H0 = 162747.8579541842, Tlimit = 1000, alow = {14357.04906, -339.184823, 5.72790672, -0.002518371562, 3.26591564e-006, -2.21011086e-009, 6.21204205e-013}, blow = {-39142.5442, -5.81099962}, ahigh = {-1483743.237, 4550.04804, -1.081464319, 0.00350396588, -1.093902537e-006, 1.771028824e-010, -1.029032783e-014}, bhigh = {-69633.2981, 40.8863592}, R_s = R_NASA_2002/KF.MM);
          constant IdealGases.Common.DataRecord KH(name = "KH", MM = 0.04010624, Hf = 3126673.205964957, H0 = 219295.2019436377, Tlimit = 1000, alow = {223.778215, 179.3554623, 1.130735415, 0.009966112559999999, -1.341218171e-005, 9.034529940000001e-009, -2.40988777e-012}, blow = {13382.50358, 15.52739897}, ahigh = {-3752276.52, 11727.78444, -10.14137678, 0.008854548899999998, -2.517188074e-006, 3.34407236e-010, -1.701157835e-014}, bhigh = {-60251.033, 101.030459}, R_s = R_NASA_2002/KH.MM);
          constant IdealGases.Common.DataRecord KI(name = "KI", MM = 0.16600277, Hf = -773817.6718376447, H0 = 61710.55458893849, Tlimit = 1000, alow = {-457.281174, -63.31769730000001, 4.82329242, -0.0007876668320000001, 1.336737911e-006, -1.000530992e-009, 3.004503956e-013}, blow = {-16503.40769, 3.55259482}, ahigh = {3293747.78, -10028.24194, 16.29302044, -0.00669639675, 2.001412089e-006, -2.677673023e-010, 1.273359646e-014}, bhigh = {46763.4867, -78.5912337}, R_s = R_NASA_2002/KI.MM);
          constant IdealGases.Common.DataRecord KLi(name = "KLi", MM = 0.0460393, Hf = 3707752.355053183, H0 = 221487.3597122459, Tlimit = 1000, alow = {-3426.04369, -19.86063081, 4.48760705, 0.0005249535550000001, -1.207990165e-006, 1.705161047e-009, -7.879994210000001e-013}, blow = {19278.68247, 1.912285942}, ahigh = {12112968.43, -40810.0487, 56.8379212, -0.03128695515, 8.975062200000001e-006, -1.189303691e-009, 5.88012918e-014}, bhigh = {273879.2595, -366.96936}, R_s = R_NASA_2002/KLi.MM);
          constant IdealGases.Common.DataRecord KNO2(name = "KNO2", MM = 0.08510380000000001, Hf = -2261913.028560417, H0 = 180281.0920311431, Tlimit = 1000, alow = {-72462.36930000001, 1226.722811, -2.258926457, 0.03019643903, -3.64025995e-005, 2.219135205e-008, -5.471654230000001e-012}, blow = {-30772.6896, 45.37172549}, ahigh = {-168941.4093, -851.5973150000001, 10.63209586, -0.000252325481, 5.57364441e-008, -6.39318592e-012, 2.964484049e-016}, bhigh = {-21877.01436, -27.55200432}, R_s = R_NASA_2002/KNO2.MM);
          constant IdealGases.Common.DataRecord KNO3(name = "KNO3", MM = 0.1011032, Hf = -3123866.386029324, H0 = 157434.304749998, Tlimit = 1000, alow = {-25961.12303, 820.060661, -2.886015624, 0.042072889, -5.27032309e-005, 3.30856173e-008, -8.36586037e-012}, blow = {-43350.5447, 46.03187331}, ahigh = {-318368.287, -1375.234449, 14.01587531, -0.000404066008, 8.90084778e-008, -1.018771993e-011, 4.71598202e-016}, bhigh = {-35138.5322, -48.04256439}, R_s = R_NASA_2002/KNO3.MM);
          constant IdealGases.Common.DataRecord KNa(name = "KNa", MM = 0.06208807, Hf = 2132524.444712164, H0 = 170308.5149852459, Tlimit = 1000, alow = {25424.05292, -411.920741, 6.84108795, -0.00625048138, 8.86101314e-006, -4.922415349999999e-009, 6.493212469999999e-013}, blow = {16525.9989, -9.13616691}, ahigh = {6260326.62, -25635.93614, 43.7333545, -0.0267265511, 8.23270579e-006, -1.12850359e-009, 5.66326489e-014}, bhigh = {169727.4909, -266.4117219}, R_s = R_NASA_2002/KNa.MM);
          constant IdealGases.Common.DataRecord KO(name = "KO", MM = 0.05509770000000001, Hf = 1174882.327211481, H0 = 172078.2174210539, Tlimit = 1000, alow = {14625.62908, -338.476565, 5.71660764, -0.002363265083, 2.848716276e-006, -1.739858233e-009, 4.431006520000001e-013}, blow = {8141.83538, -4.02210152}, ahigh = {696010.338, -3304.83529, 10.05743444, -0.004331112, 1.747281632e-006, -3.012370548e-010, 1.79082787e-014}, bhigh = {26049.72496, -34.4878152}, R_s = R_NASA_2002/KO.MM);
          constant IdealGases.Common.DataRecord KOH(name = "KOH", MM = 0.05610564, Hf = -4135056.653840862, H0 = 208083.3584644966, Tlimit = 1000, alow = {17706.84196, -615.320522, 8.684075719999999, -0.00396284951, 3.40865059e-006, -9.60197222e-010, 8.494054970000001e-015}, blow = {-26779.03261, -21.74495666}, ahigh = {891727.195, -2334.179072, 7.97257871, 0.0001038863156, -6.315893469999999e-008, 1.027938106e-011, -5.73668582e-016}, bhigh = {-14436.96469, -20.76401416}, R_s = R_NASA_2002/KOH.MM);
          constant IdealGases.Common.DataRecord K2(name = "K2", MM = 0.07819660000000001, Hf = 1618309.862577145, H0 = 137360.5629912298, Tlimit = 1000, alow = {15241.69293, -330.178936, 7.07079595, -0.00976707246, 2.021535863e-005, -1.886092452e-008, 6.11297464e-012}, blow = {15334.02849, -9.1010358}, ahigh = {-27344707.45, 65621.80009999999, -44.7635044, 0.008938859150000001, 2.984557092e-006, -1.064158914e-009, 8.334936929999999e-014}, bhigh = {-422624.383, 386.714251}, R_s = R_NASA_2002/K2.MM);
          constant IdealGases.Common.DataRecord K2plus(name = "K2plus", MM = 0.07819605140000001, Hf = 6709555.298594016, H0 = 138896.1565903314, Tlimit = 1000, alow = {51960.3657, -611.338253, 7.26499054, -0.00581063482, 6.5674965e-006, -2.378020865e-009, -1.318637581e-013}, blow = {64798.2027, -10.42370517}, ahigh = {11079507.39, -41774.8382, 64.48659840000001, -0.0402499803, 1.360587923e-005, -2.361920107e-009, 1.67343061e-013}, bhigh = {317761.205, -410.50631}, R_s = R_NASA_2002/K2plus.MM);
          constant IdealGases.Common.DataRecord K2Br2(name = "K2Br2", MM = 0.2380046, Hf = -2263587.31301832, H0 = 88031.0968779595, Tlimit = 1000, alow = {-10930.40504, -48.5665148, 10.19754923, -0.00043631571, 5.38717366e-007, -3.4861165e-010, 9.19070295e-014}, blow = {-67580.73239999999, -12.94944706}, ahigh = {-15892.29976, -0.810137946, 10.00069442, -3.074491521e-007, 7.33102416e-011, -8.908944780000001e-015, 4.319245429999999e-019}, bhigh = {-67825.9544, -11.80425726}, R_s = R_NASA_2002/K2Br2.MM);
          constant IdealGases.Common.DataRecord K2CO3(name = "K2CO3", MM = 0.1382055, Hf = -5872770.352844134, H0 = 141208.8303287496, Tlimit = 1000, alow = {-44074.067, 706.981544, 0.693148247, 0.0396783132, -4.8509583e-005, 2.976635787e-008, -7.374761529999999e-012}, blow = {-103391.3232, 29.80651689}, ahigh = {-326426.316, -1521.168973, 17.12283562, -0.000446458071, 9.83337963e-008, -1.125478371e-011, 5.21006912e-016}, bhigh = {-94882.75099999999, -62.1522063}, R_s = R_NASA_2002/K2CO3.MM);
          constant IdealGases.Common.DataRecord K2C2N2(name = "K2C2N2", MM = 0.1302314, Hf = -64254.85712355085, H0 = 190324.6221725329, Tlimit = 1000, alow = {4627.78948, -972.9810620000001, 19.9666591, -0.01953015081, 3.27533046e-005, -2.39398512e-008, 6.59654824e-012}, blow = {-777.4411259999999, -67.55613632000001}, ahigh = {726959.95, -3492.10868, 18.35676822, -0.000878547514, 1.845532919e-007, -2.038717568e-011, 9.18542099e-016}, bhigh = {15826.00773, -67.28484052}, R_s = R_NASA_2002/K2C2N2.MM);
          constant IdealGases.Common.DataRecord K2CL2(name = "K2CL2", MM = 0.1491026, Hf = -4127316.780525624, H0 = 133890.6766213332, Tlimit = 1000, alow = {-13285.26456, -124.1832429, 10.5003573, -0.001097776004, 1.348871402e-006, -8.69721512e-010, 2.28658408e-013}, blow = {-76443.6315, -17.90150052}, ahigh = {-26146.11331, -2.096229095, 10.00178456, -7.864803710000001e-007, 1.869281152e-010, -2.266272348e-014, 1.096790704e-018}, bhigh = {-77071.8933, -14.99720802}, R_s = R_NASA_2002/K2CL2.MM);
          constant IdealGases.Common.DataRecord K2F2(name = "K2F2", MM = 0.1161934064, Hf = -7400381.034013649, H0 = 155995.3061157522, Tlimit = 1000, alow = {-1611.833856, -513.564489, 11.99922511, -0.004280109549999999, 5.16538754e-006, -3.2858149e-009, 8.549648749999999e-013}, blow = {-103924.8602, -30.39925079}, ahigh = {-57408.9253, -9.04618211, 10.00750685, -3.25076484e-006, 7.63006459e-010, -9.165649529999999e-014, 4.40504844e-018}, bhigh = {-106541.3546, -18.7403762}, R_s = R_NASA_2002/K2F2.MM);
          constant IdealGases.Common.DataRecord K2I2(name = "K2I2", MM = 0.33200554, Hf = -1261772.475242431, H0 = 64627.07821080335, Tlimit = 1000, alow = {-8977.75244, -27.76460169, 10.11331014, -0.0002508421994, 3.102352114e-007, -2.010096209e-010, 5.30443715e-014}, blow = {-53262.0839, -10.32092509}, ahigh = {-11796.34729, -0.472476155, 10.00040695, -1.807689054e-007, 4.32056097e-011, -5.259699430000001e-015, 2.553419144e-019}, bhigh = {-53402.10230000001, -9.6644405}, R_s = R_NASA_2002/K2I2.MM);
          constant IdealGases.Common.DataRecord K2O(name = "K2O", MM = 0.094196, Hf = -786518.5570512548, H0 = 147121.93723725, Tlimit = 1000, alow = {23920.44068, -544.535839, 8.82640323, -0.00348142943, 3.83454207e-006, -2.268494189e-009, 5.56921225e-013}, blow = {-8234.29168, -16.63099064}, ahigh = {-46114.6458, -13.63119524, 7.01053044, -4.32365826e-006, 9.747788419999999e-010, -1.135283694e-013, 5.325860600000001e-018}, bhigh = {-11072.22244, -5.76871872}, R_s = R_NASA_2002/K2O.MM);
          constant IdealGases.Common.DataRecord K2Oplus(name = "K2Oplus", MM = 0.09419545139999999, Hf = 3910914.12084894, H0 = 150093.4576974701, Tlimit = 1000, alow = {7201.10273, -333.65264, 8.05073035, -0.001869353797, 1.921291874e-006, -1.064020951e-009, 2.457514799e-013}, blow = {43899.8636, -10.7320415}, ahigh = {-37800.335, -8.84953739, 7.00684789, -2.815510856e-006, 6.3550015e-010, -7.408551990000001e-014, 3.478334960000001e-018}, bhigh = {42145.19680000001, -4.41827661}, R_s = R_NASA_2002/K2Oplus.MM);
          constant IdealGases.Common.DataRecord K2O2(name = "K2O2", MM = 0.1101954, Hf = -1738423.754530588, H0 = 147826.5245191723, Tlimit = 1000, alow = {48108.7061, -1003.601504, 11.54229002, -0.000454633252, -1.516606209e-006, 1.79942609e-009, -6.12833729e-013}, blow = {-20571.5192, -31.8119979}, ahigh = {-147607.3073, -102.193204, 10.07664713, -3.076517991e-005, 6.81525281e-009, -7.82865445e-013, 3.6325061e-017}, bhigh = {-25920.56324, -21.62287184}, R_s = R_NASA_2002/K2O2.MM);
          constant IdealGases.Common.DataRecord K2O2H2(name = "K2O2H2", MM = 0.11221128, Hf = -5712438.179120673, H0 = 199489.1511798101, Tlimit = 1000, alow = {8174.78837, -1130.63068, 18.15303256, -0.00773743108, 6.83761401e-006, -2.054691111e-009, 7.67287751e-014}, blow = {-75749.6517, -63.9175947}, ahigh = {1773523.196, -4665.292469999999, 16.94308128, 0.0002085297143, -1.264714762e-007, 2.057506565e-011, -1.148042134e-015}, bhigh = {-50512.63310000001, -63.3477392}, R_s = R_NASA_2002/K2O2H2.MM);
          constant IdealGases.Common.DataRecord K2SO4(name = "K2SO4", MM = 0.1742592, Hf = -6288627.06244491, H0 = 127877.7763240047, Tlimit = 1000, alow = {62714.9231, -815.204992, 7.45541372, 0.0384990978, -5.40063098e-005, 3.6546568e-008, -9.760223570000001e-012}, blow = {-130469.2568, -10.3463477}, ahigh = {-544612.564, -959.0667229999999, 19.71591285, -0.0002866586009, 6.342480639999999e-008, -7.281462539999999e-012, 3.37788693e-016}, bhigh = {-133787.3384, -73.99103550999999}, R_s = R_NASA_2002/K2SO4.MM);
          constant IdealGases.Common.DataRecord Kr(name = "Kr", MM = 0.0838, Hf = 0, H0 = 73954.98806682577, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {-745.375, 5.49095651}, ahigh = {264.3639057, -0.7910050820000001, 2.500920585, -5.32816411e-007, 1.620730161e-010, -2.467898017e-014, 1.47858504e-018}, bhigh = {-740.348894, 5.48439815}, R_s = R_NASA_2002/Kr.MM);
          constant IdealGases.Common.DataRecord Krplus(name = "Krplus", MM = 0.08379945139999999, Hf = 16192873.52518396, H0 = 73955.472219237, Tlimit = 1000, alow = {-5650.40286, 69.3074081, 2.157028132, 0.0008711228930000001, -1.18160973e-006, 7.86219863e-010, -1.832589387e-013}, blow = {162116.4118, 8.81824226}, ahigh = {-221656.7015, 1166.16784, 0.486965532, 0.001429223599, -3.94962861e-007, 4.98285351e-011, -2.406719258e-015}, bhigh = {155600.2861, 20.59230986}, R_s = R_NASA_2002/Krplus.MM);
          constant IdealGases.Common.DataRecord Li(name = "Li", MM = 0.006941, Hf = 22950583.48941075, H0 = 892872.4967583921, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {18413.90197, 2.447622965}, ahigh = {1125610.652, -3463.53673, 6.56661192, -0.002260983356, 5.92228916e-007, -6.2816351e-011, 2.884948238e-015}, bhigh = {40346.374, -26.55918195}, R_s = R_NASA_2002/Li.MM);
          constant IdealGases.Common.DataRecord Liplus(name = "Liplus", MM = 0.0069404514, Hf = 98800407.70835166, H0 = 892943.0728381731, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {81727.24550000001, 1.754357228}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {81727.24550000001, 1.754357228}, R_s = R_NASA_2002/Liplus.MM);
          constant IdealGases.Common.DataRecord Liminus(name = "Liminus", MM = 0.0069415486, Hf = 13465976.16560662, H0 = 892801.9318340579, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {10496.98659, 1.754594332}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {10496.98659, 1.754594332}, R_s = R_NASA_2002/Liminus.MM);
          constant IdealGases.Common.DataRecord LiALF4(name = "LiALF4", MM = 0.1099161508, Hf = -16897315.00313783, H0 = 177720.8249908984, Tlimit = 1000, alow = {176152.936, -2999.300134, 20.7973957, -0.001742914656, -4.266642090000001e-006, 5.362829770000001e-009, -1.866817087e-012}, blow = {-211794.7828, -87.6272589}, ahigh = {-402070.0930000001, -278.3355146, 16.20791185, -8.316341570000001e-005, 1.83690569e-008, -2.104932808e-012, 9.74725302e-017}, bhigh = {-227869.6416, -55.9730484}, R_s = R_NASA_2002/LiALF4.MM);
          constant IdealGases.Common.DataRecord LiBO2(name = "LiBO2", MM = 0.0497508, Hf = -13112397.71018758, H0 = 269899.6599049664, Tlimit = 1000, alow = {65189.8757, -1060.320845, 9.54804996, -5.46957607e-005, 2.658687599e-006, -2.931603694e-009, 9.66302973e-013}, blow = {-75062.0411, -24.90883998}, ahigh = {85544.04520000001, -1731.920898, 11.2146209, -0.000465916217, 9.999875689999999e-008, -1.122880592e-011, 5.12352946e-016}, bhigh = {-71547.4382, -36.1239729}, R_s = R_NASA_2002/LiBO2.MM);
          constant IdealGases.Common.DataRecord LiBr(name = "LiBr", MM = 0.08684500000000001, Hf = -1740605.561632794, H0 = 105626.2306407968, Tlimit = 1000, alow = {38056.2047, -612.961499, 6.57736955, -0.00421989176, 5.391423370000001e-006, -3.69314481e-009, 1.049158761e-012}, blow = {-16374.87617, -11.28654012}, ahigh = {63801.9142, -259.7050764, 4.65676887, 0.0001022867706, -5.178252340000001e-008, 2.058203991e-011, -1.942190308e-015}, bhigh = {-17933.63752, -0.2290806613}, R_s = R_NASA_2002/LiBr.MM);
          constant IdealGases.Common.DataRecord LiCL(name = "LiCL", MM = 0.042394, Hf = -4570927.277444921, H0 = 213712.0583101382, Tlimit = 1000, alow = {49643.995, -718.734662, 6.78514703, -0.00452214546, 5.748483700000001e-006, -3.96625567e-009, 1.137911398e-012}, blow = {-20910.14703, -14.06383901}, ahigh = {-235276.9705, 612.004692, 3.63429373, 0.0006810973320000001, -2.174238799e-007, 4.22040361e-011, -2.848628426e-015}, bhigh = {-28623.58494, 5.618511135}, R_s = R_NASA_2002/LiCL.MM);
          constant IdealGases.Common.DataRecord LiF(name = "LiF", MM = 0.0259394032, Hf = -13143898.93133702, H0 = 340335.7406464926, Tlimit = 1000, alow = {29125.3732, -253.1413159, 3.53972798, 0.00369591704, -4.82946615e-006, 2.944090711e-009, -6.83879474e-013}, blow = {-40648.4966, 2.325294408}, ahigh = {-378424.649, 766.806246, 3.5854734, 0.0006031084350000001, -1.588764206e-007, 2.569397177e-011, -1.406798386e-015}, bhigh = {-47564.6945, 4.38516329}, R_s = R_NASA_2002/LiF.MM);
          constant IdealGases.Common.DataRecord LiH(name = "LiH", MM = 0.00794894, Hf = 17519833.33626873, H0 = 1092737.396432732, Tlimit = 1000, alow = {-49137.31570000001, 775.6092190000001, -1.011102377, 0.01145479597, -1.151038734e-005, 5.87506896e-009, -1.196789735e-012}, blow = {12048.5891, 25.68801877}, ahigh = {-2633686.357, 6996.429169999999, -3.23353306, 0.00403393598, -9.09957964e-007, 8.775909869999999e-011, -2.889490251e-015}, bhigh = {-29900.43016, 49.71984499999999}, R_s = R_NASA_2002/LiH.MM);
          constant IdealGases.Common.DataRecord LiI(name = "LiI", MM = 0.13384547, Hf = -637077.1308136167, H0 = 69409.2373839772, Tlimit = 1000, alow = {40719.7637, -666.7289470000001, 7.06425753, -0.00548004102, 6.90579016e-006, -4.53716852e-009, 1.226373296e-012}, blow = {-8235.487020000001, -12.96236234}, ahigh = {1616342.632, -4877.71708, 9.987186550000001, -0.002889137815, 8.03731377e-007, -9.028172610000001e-011, 3.078321954e-015}, bhigh = {19377.18764, -37.2927631}, R_s = R_NASA_2002/LiI.MM);
          constant IdealGases.Common.DataRecord LiN(name = "LiN", MM = 0.0209477, Hf = 15978842.5459597, H0 = 429600.7676260401, Tlimit = 1000, alow = {37649.592, -488.345763, 5.18737345, 0.0002275252171, -1.416337564e-006, 1.450236258e-009, -4.79001433e-013}, blow = {41619.1531, -5.952157244}, ahigh = {-59934.8998, -40.3113455, 4.52962421, 8.744156930000001e-005, 2.557428364e-009, -2.9057518e-013, 1.336125922e-017}, bhigh = {38948.3113, -1.214952896}, R_s = R_NASA_2002/LiN.MM);
          constant IdealGases.Common.DataRecord LiNO2(name = "LiNO2", MM = 0.0529465, Hf = -3815761.343998187, H0 = 252496.2367673028, Tlimit = 1000, alow = {-31337.73859, 538.9940809999999, -0.02059877081, 0.02610777454, -3.20923504e-005, 1.974344044e-008, -4.89219916e-012}, blow = {-28382.14963, 27.10019529}, ahigh = {-219667.116, -861.004271, 10.63956465, -0.0002554392587, 5.64447854e-008, -6.47614005e-012, 3.003536591e-016}, bhigh = {-23135.47535, -32.38277103}, R_s = R_NASA_2002/LiNO2.MM);
          constant IdealGases.Common.DataRecord LiNO3(name = "LiNO3", MM = 0.06894589999999999, Hf = -4519263.291943394, H0 = 201829.6229362443, Tlimit = 1000, alow = {19672.05518, 90.52795259999999, -0.51097704, 0.0375660595, -4.78273865e-005, 3.029277805e-008, -7.70801315e-012}, blow = {-39075.6399, 27.46873033}, ahigh = {-355940.245, -1447.644737, 14.06684061, -0.000423637128, 9.320824509999999e-008, -1.065894872e-011, 4.93078062e-016}, bhigh = {-34348.2746, -52.75382697000001}, R_s = R_NASA_2002/LiNO3.MM);
          constant IdealGases.Common.DataRecord LiO(name = "LiO", MM = 0.0229404, Hf = 3178423.785112727, H0 = 408105.9179438893, Tlimit = 1000, alow = {36270.2976, -349.936323, 4.39493318, 0.001079712984, -8.72403881e-007, 5.60796297e-010, -2.054288457e-013}, blow = {9533.330530000001, -0.9058149609999999}, ahigh = {1612392.133, -5551.31234, 11.20573851, -0.00343722688, 9.133194659999999e-007, -1.027902258e-010, 3.822991e-015}, bhigh = {42015.7547, -48.5735458}, R_s = R_NASA_2002/LiO.MM);
          constant IdealGases.Common.DataRecord LiOF(name = "LiOF", MM = 0.0419388032, Hf = -2194817.042370918, H0 = 258170.5288147088, Tlimit = 1000, alow = {55101.10690000001, -577.068817, 4.42495493, 0.01102425422, -1.710493381e-005, 1.234361201e-008, -3.453693e-012}, blow = {-9278.986980000002, 0.1238830687}, ahigh = {-183356.3281, -211.0049301, 7.15681817, -6.24946201e-005, 1.376567002e-008, -1.574099067e-012, 7.277167140000001e-017}, bhigh = {-12545.30277, -12.72130479}, R_s = R_NASA_2002/LiOF.MM);
          constant IdealGases.Common.DataRecord LiOH(name = "LiOH", MM = 0.02394834, Hf = -9562249.408518503, H0 = 473392.3520377612, Tlimit = 1000, alow = {4574.19012, -103.0949027, 4.27240737, 0.008465219230000001, -1.386148524e-005, 1.101099795e-008, -3.29124821e-012}, blow = {-28487.28855, -0.8775745779999999}, ahigh = {850075.137, -2430.540791, 8.055314620000001, 6.895680879999999e-005, -5.527207459999999e-008, 9.368054029999999e-012, -5.31378568e-016}, bhigh = {-13658.94396, -24.57598093}, R_s = R_NASA_2002/LiOH.MM);
          constant IdealGases.Common.DataRecord LiON(name = "LiON", MM = 0.0369471, Hf = 4869448.48174823, H0 = 305869.1751179389, Tlimit = 1000, alow = {-9412.67267, 100.93323, 3.006187607, 0.0098904622, -1.128294343e-005, 6.41029174e-009, -1.466806373e-012}, blow = {19783.48318, 10.16334813}, ahigh = {-97406.29139999999, -511.1560940000001, 7.37849387, -0.0001508777884, 3.32991498e-008, -3.81751429e-012, 1.769558455e-016}, bhigh = {22110.06635, -14.5410504}, R_s = R_NASA_2002/LiON.MM);
          constant IdealGases.Common.DataRecord Li2(name = "Li2", MM = 0.013882, Hf = 15552514.04696729, H0 = 696954.0412044374, Tlimit = 1000, alow = {6778.481580000001, -224.6205832, 5.29603744, -0.001272412017, 1.205843729e-006, -9.81854459e-011, -2.416702607e-013}, blow = {25736.38186, -6.86925758}, ahigh = {37676454, -118574.7185, 148.2167789, -0.0837853211, 2.424919798e-005, -3.27582024e-009, 1.652000081e-013}, bhigh = {772307.201, -1021.697298}, R_s = R_NASA_2002/Li2.MM);
          constant IdealGases.Common.DataRecord Li2plus(name = "Li2plus", MM = 0.0138814514, Hf = 51983859.55520473, H0 = 719601.9862879757, Tlimit = 1000, alow = {-10400.56453, 26.75405642, 4.24727175, 0.001057450777, -1.281715096e-006, 1.067477239e-009, -2.759413508e-013}, blow = {85298.11309999999, 0.529818996}, ahigh = {12799310.73, -34928.6139, 38.4478536, -0.01380635397, 2.53139425e-006, -2.197815991e-010, 7.08766925e-015}, bhigh = {311796.445, -250.9543641}, R_s = R_NASA_2002/Li2plus.MM);
          constant IdealGases.Common.DataRecord Li2Br2(name = "Li2Br2", MM = 0.17369, Hf = -2854703.920778398, H0 = 97590.39668374689, Tlimit = 1000, alow = {27863.12863, -1005.641437, 13.70963066, -0.0076336633, 8.94290592e-006, -5.56113509e-009, 1.421736784e-012}, blow = {-57628.4584, -41.2184376}, ahigh = {-89009.8336, -19.88916335, 10.01596418, -6.74913405e-006, 1.556299963e-009, -1.844693069e-013, 8.774879919999999e-018}, bhigh = {-62799.8996, -19.43063525}, R_s = R_NASA_2002/Li2Br2.MM);
          constant IdealGases.Common.DataRecord Li2F2(name = "Li2F2", MM = 0.05187880640000001, Hf = -18029001.4536649, H0 = 265349.7826040963, Tlimit = 1000, alow = {144316.6185, -2466.874678, 17.0286329, -0.0114554121, 1.086098792e-005, -5.569754279999999e-009, 1.193819664e-012}, blow = {-102607.0133, -70.0038661}, ahigh = {-218893.1683, -92.5981453, 10.06970757, -2.803632163e-005, 6.217549520000001e-009, -7.14626702e-013, 3.3168573e-017}, bhigh = {-115661.1527, -27.29853181}, R_s = R_NASA_2002/Li2F2.MM);
          constant IdealGases.Common.DataRecord Li2I2(name = "Li2I2", MM = 0.26769094, Hf = -1355299.320178711, H0 = 65966.56577170672, Tlimit = 1000, alow = {10148.72266, -712.042101, 12.7039296, -0.00568553681, 6.770340380000001e-006, -4.26330489e-009, 1.100658186e-012}, blow = {-43130.6386, -33.03950980000001}, ahigh = {-69735.8706, -13.16825508, 10.01074855, -4.60020378e-006, 1.070510527e-009, -1.277717768e-013, 6.11061224e-018}, bhigh = {-46774.7005, -17.21894034}, R_s = R_NASA_2002/Li2I2.MM);
          constant IdealGases.Common.DataRecord Li2O(name = "Li2O", MM = 0.0298814, Hf = -5600103.074153152, H0 = 428095.0691734658, Tlimit = 1000, alow = {26366.01597, -179.8629279, 4.05111522, 0.01189981375, -1.730095793e-005, 1.20558455e-008, -3.29273388e-012}, blow = {-20619.07963, 1.60599561}, ahigh = {726148.7039999999, -9543.783720000001, 28.87491643, -0.01959494099, 8.086339840000001e-006, -1.370211764e-009, 8.11172719e-014}, bhigh = {29907.26399, -156.4517822}, R_s = R_NASA_2002/Li2O.MM);
          constant IdealGases.Common.DataRecord Li2Oplus(name = "Li2Oplus", MM = 0.0298808514, Hf = 14694865.38793871, H0 = 436021.3444252797, Tlimit = 1000, alow = {108104.4623, -1261.961355, 9.69201129, -0.001793477428, 3.3803269e-007, 4.14339515e-010, -1.990530222e-013}, blow = {57549.7604, -29.15719946}, ahigh = {-130216.6086, -146.6759528, 7.61072945, -4.46942669e-005, 9.947160640000001e-009, -1.147038806e-012, 5.33924147e-017}, bhigh = {50987.6231, -15.28011047}, R_s = R_NASA_2002/Li2Oplus.MM);
          constant IdealGases.Common.DataRecord Li2O2(name = "Li2O2", MM = 0.0458808, Hf = -6089649.439416925, H0 = 295287.1789506722, Tlimit = 1000, alow = {139261.973, -1764.036747, 10.29649198, 0.00760594995, -1.538519312e-005, 1.238199941e-008, -3.68543157e-012}, blow = {-26380.56746, -34.3771056}, ahigh = {-293923.2153, -235.9107937, 10.17463402, -6.931624359999999e-005, 1.521202834e-008, -1.733841909e-012, 7.99315462e-017}, bhigh = {-36184.8191, -29.04221044}, R_s = R_NASA_2002/Li2O2.MM);
          constant IdealGases.Common.DataRecord Li2O2H2(name = "Li2O2H2", MM = 0.04789668, Hf = -15387287.80366405, H0 = 325263.4629373059, Tlimit = 1000, alow = {189441.3579, -2779.117524, 15.30234911, 0.01070738317, -2.510075145e-005, 2.224910575e-008, -6.94935958e-012}, blow = {-77027.7692, -65.1411694}, ahigh = {1215377.492, -3982.05744, 15.85877373, 0.000750914568, -2.585218184e-007, 3.6468417e-011, -1.904139406e-015}, bhigh = {-67387.4838, -66.472084}, R_s = R_NASA_2002/Li2O2H2.MM);
          constant IdealGases.Common.DataRecord Li2SO4(name = "Li2SO4", MM = 0.1099446, Hf = -9475826.916465202, H0 = 178749.4610922228, Tlimit = 1000, alow = {100631.8702, -1543.457217, 9.670054909999999, 0.0339075738, -4.82348381e-005, 3.26736892e-008, -8.702518510000001e-012}, blow = {-120193.9538, -29.11716635}, ahigh = {-603875.0870000001, -1064.550976, 19.79557349, -0.000318897825, 7.062411120000001e-008, -8.11443907e-012, 3.76683021e-016}, bhigh = {-126890.8595, -80.14316674}, R_s = R_NASA_2002/Li2SO4.MM);
          constant IdealGases.Common.DataRecord Li3plus(name = "Li3plus", MM = 0.0208224514, Hf = 36335339.26749855, H0 = 638224.9978501572, Tlimit = 1000, alow = {-6873.222290000001, -282.0780467, 7.92269748, -0.001687949474, 1.771718993e-006, -9.972535399999999e-010, 2.332934849e-013}, blow = {90279.63650000001, -16.19319856}, ahigh = {-43550.9806, -6.05643275, 7.00472289, -1.953320933e-006, 4.429152229999999e-010, -5.18198319e-014, 2.439894871e-018}, bhigh = {88799.02870000001, -10.66880792}, R_s = R_NASA_2002/Li3plus.MM);
          constant IdealGases.Common.DataRecord Li3Br3(name = "Li3Br3", MM = 0.260535, Hf = -3165176.245034256, H0 = 99935.92799431937, Tlimit = 1000, alow = {64319.66250000001, -1823.743601, 22.43492856, -0.0127941826, 1.459200355e-005, -8.884688150000001e-009, 2.23370805e-012}, blow = {-94806.7767, -82.06864420000001}, ahigh = {-158467.0201, -40.4136094, 16.03177633, -1.322713911e-005, 3.014221791e-009, -3.54029216e-013, 1.672030783e-017}, bhigh = {-104247.0448, -44.05478160000001}, R_s = R_NASA_2002/Li3Br3.MM);
          constant IdealGases.Common.DataRecord Li3CL3(name = "Li3CL3", MM = 0.127182, Hf = -7674884.189586578, H0 = 193113.3808243305, Tlimit = 1000, alow = {98674.28999999999, -2324.074851, 23.78484564, -0.014835224, 1.634495612e-005, -9.675366520000001e-009, 2.377033859e-012}, blow = {-110383.9177, -94.74114379}, ahigh = {-200593.0356, -59.3940019, 16.04590929, -1.885890854e-005, 4.25351737e-009, -4.95556094e-013, 2.325408214e-017}, bhigh = {-122492.7071, -48.44413629}, R_s = R_NASA_2002/Li3CL3.MM);
          constant IdealGases.Common.DataRecord Li3F3(name = "Li3F3", MM = 0.07781820960000001, Hf = -19591775.93312298, H0 = 263906.5342875737, Tlimit = 1000, alow = {182387.4443, -3163.78624, 22.87811928, -0.007544903889999999, 3.44679023e-006, 2.690705228e-010, -5.25084096e-013}, blow = {-171244.6093, -99.7365499}, ahigh = {-361866.499, -193.7051395, 16.14457133, -5.7756285e-005, 1.274057038e-008, -1.458168875e-012, 6.744850030000001e-017}, bhigh = {-188208.1974, -56.3361288}, R_s = R_NASA_2002/Li3F3.MM);
          constant IdealGases.Common.DataRecord Li3I3(name = "Li3I3", MM = 0.40153641, Hf = -1525284.611176356, H0 = 67821.2319525395, Tlimit = 1000, alow = {36117.6469, -1392.033487, 21.10791892, -0.01046866587, 1.222589173e-005, -7.58413543e-009, 1.93519918e-012}, blow = {-71530.8458, -70.9388203}, ahigh = {-126669.6511, -27.83891914, 16.02228068, -9.399364930000001e-006, 2.163919735e-009, -2.561731922e-013, 1.217394107e-017}, bhigh = {-78695.5068, -40.9172406}, R_s = R_NASA_2002/Li3I3.MM);
          constant IdealGases.Common.DataRecord Mg(name = "Mg", MM = 0.024305, Hf = 6052252.622917095, H0 = 254985.7231022423, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {16946.58761, 3.63433014}, ahigh = {-536483.155, 1973.709576, -0.36337769, 0.002071795561, -7.738051719999999e-007, 1.359277788e-010, -7.766898397000001e-015}, bhigh = {4829.188109999999, 23.39104998}, R_s = R_NASA_2002/Mg.MM);
          constant IdealGases.Common.DataRecord Mgplus(name = "Mgplus", MM = 0.0243044514, Hf = 36661884.90886899, H0 = 254991.4786391763, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {106422.3354, 4.32744346}, ahigh = {-19147.58821, 48.7734792, 2.457662661, 1.218104674e-005, 1.897261686e-009, -1.580433756e-012, 2.135732238e-016}, bhigh = {106102.2394, 4.64644286}, R_s = R_NASA_2002/Mgplus.MM);
          constant IdealGases.Common.DataRecord MgBr(name = "MgBr", MM = 0.104209, Hf = 59143.78796457119, H0 = 92008.51174082852, Tlimit = 1000, alow = {7361.41914, -239.5789881, 5.36056042, -0.001667141829, 1.981137765e-006, -1.201637202e-009, 3.032148099e-013}, blow = {591.563444, -1.421771179}, ahigh = {24776.04216, -641.7687520000001, 6.01993209, -0.001391004302, 6.44333096e-007, -1.197734078e-010, 7.421644240000001e-015}, bhigh = {2824.060334, -6.26443992}, R_s = R_NASA_2002/MgBr.MM);
          constant IdealGases.Common.DataRecord MgBr2(name = "MgBr2", MM = 0.184113, Hf = -1666059.534090477, H0 = 80153.38949449523, Tlimit = 1000, alow = {21484.77999, -515.45289, 9.27325875, -0.00347004904, 3.92184079e-006, -2.377174864e-009, 5.967025559999999e-013}, blow = {-36524.4385, -17.91077763}, ahigh = {-43268.9901, -12.83036001, 7.5100243, -4.1523324e-006, 9.42649918e-010, -1.103873928e-013, 5.20110431e-018}, bhigh = {-39198.8602, -7.40916803}, R_s = R_NASA_2002/MgBr2.MM);
          constant IdealGases.Common.DataRecord MgCL(name = "MgCL", MM = 0.05975800000000001, Hf = -915440.3929181029, H0 = 156683.8414940259, Tlimit = 1000, alow = {20439.9528, -407.215516, 5.8803723, -0.002594175042, 2.945953528e-006, -1.750648628e-009, 4.337959330000001e-013}, blow = {-5851.44495, -6.02354575}, ahigh = {1041328.453, -3380.15833, 8.637775469999999, -0.002447789643, 7.84196944e-007, -1.12640938e-010, 5.81062073e-015}, bhigh = {13271.88977, -27.03802395}, R_s = R_NASA_2002/MgCL.MM);
          constant IdealGases.Common.DataRecord MgCLplus(name = "MgCLplus", MM = 0.0597574514, Hf = 10816045.81282394, H0 = 159239.2543032717, Tlimit = 1000, alow = {8182.385119999999, -262.225376, 5.41986343, -0.001774129606, 2.185811127e-006, -1.418143432e-009, 3.91889858e-013}, blow = {77704.0371, -3.78093884}, ahigh = {-12683919.21, 34788.2454, -30.0422295, 0.01481739497, -2.470965605e-006, 1.424433718e-010, 2.789613105e-016}, bhigh = {-148701.374, 255.2015117}, R_s = R_NASA_2002/MgCLplus.MM);
          constant IdealGases.Common.DataRecord MgCL2(name = "MgCL2", MM = 0.095211, Hf = -4192476.667611936, H0 = 145997.8783964038, Tlimit = 1000, alow = {36378.2468, -730.784496, 9.66103051, -0.00366021294, 3.61081935e-006, -1.928769286e-009, 4.309912350000001e-013}, blow = {-46469.1457, -23.60112274}, ahigh = {-68352.1701, -24.90899393, 7.5187832, -7.56451826e-006, 1.67929377e-009, -1.931706275e-013, 8.971657820000001e-018}, bhigh = {-50326.8691, -10.53268382}, R_s = R_NASA_2002/MgCL2.MM);
          constant IdealGases.Common.DataRecord MgF(name = "MgF", MM = 0.0433034032, Hf = -5363707.580377886, H0 = 207122.473921403, Tlimit = 1000, alow = {38230.0162, -480.331039, 5.06846894, 0.00052120293, -1.874026347e-006, 1.759241129e-009, -5.60940319e-013}, blow = {-26591.14296, -3.76896921}, ahigh = {-169588.3782, 358.875763, 3.93600165, 0.000481304414, -1.658385409e-007, 3.33605229e-011, -2.270104205e-015}, bhigh = {-31693.2399, 4.4105659}, R_s = R_NASA_2002/MgF.MM);
          constant IdealGases.Common.DataRecord MgFplus(name = "MgFplus", MM = 0.0433028546, Hf = 11936113.21411591, H0 = 207131.2638128019, Tlimit = 1000, alow = {641329.384, -8518.53261, 48.1421691, -0.1163071535, 0.0001622560562, -1.06348459e-007, 2.634809398e-011}, blow = {102430.848, -245.0074295}, ahigh = {-10568523.62, 20771.22379, -6.11952356, 0.002245834831, -9.51573861e-008, -2.263502341e-011, 2.284524246e-015}, bhigh = {-83315.4988, 87.2710238}, R_s = R_NASA_2002/MgFplus.MM);
          constant IdealGases.Common.DataRecord MgF2(name = "MgF2", MM = 0.0623018064, Hf = -11805405.05162624, H0 = 202601.5091594519, Tlimit = 1000, alow = {43384.2955, -661.651177, 7.45344852, 0.00352081405, -6.95576458e-006, 5.61992348e-009, -1.688028906e-012}, blow = {-86871.8367, -15.4547679}, ahigh = {-124441.9584, -86.87343749999999, 7.56358123, -2.499267978e-005, 5.44012914e-009, -6.15824576e-013, 2.822792666e-017}, bhigh = {-90600.19439999999, -14.2079699}, R_s = R_NASA_2002/MgF2.MM);
          constant IdealGases.Common.DataRecord MgF2plus(name = "MgF2plus", MM = 0.0623012578, Hf = 9352815.409771709, H0 = 199274.6926531554, Tlimit = 1000, alow = {78322.2026, -1176.632752, 10.25829767, -0.00375527289, 3.016621585e-006, -1.327098871e-009, 2.465289749e-013}, blow = {74132.2855, -29.90883551}, ahigh = {-150231.687, 77.2528956, 7.27156936, 0.000223752977, -1.003070865e-007, 1.996274309e-011, -1.233278721e-015}, bhigh = {66991.175, -10.94528006}, R_s = R_NASA_2002/MgF2plus.MM);
          constant IdealGases.Common.DataRecord MgH(name = "MgH", MM = 0.02531294, Hf = 9077811.743716849, H0 = 342990.7391239421, Tlimit = 1000, alow = {-49586.7915, 750.027865, -0.64420475, 0.00982630101, -8.789822439999999e-006, 3.82335352e-009, -6.00372576e-013}, blow = {23022.79383, 26.57165344}, ahigh = {-100574.8598, 1952.890106, -1.317191549, 0.0056036658, -2.13733498e-006, 3.3248805e-010, -1.824672746e-014}, bhigh = {15985.82755, 34.3123316}, R_s = R_NASA_2002/MgH.MM);
          constant IdealGases.Common.DataRecord MgI(name = "MgI", MM = 0.15120947, Hf = 404778.3316745968, H0 = 64421.34212890238, Tlimit = 1000, alow = {2943.889099, -169.0248574, 5.14725183, -0.001321186997, 1.623056505e-006, -1.005114222e-009, 2.567337785e-013}, blow = {6845.89027, 0.859313225}, ahigh = {-2370562.811, 6916.45248, -3.18389449, 0.00405155114, -9.774290750000001e-007, 1.0233294e-010, -3.79030487e-015}, bhigh = {-38185.5111, 59.9310438}, R_s = R_NASA_2002/MgI.MM);
          constant IdealGases.Common.DataRecord MgI2(name = "MgI2", MM = 0.27811394, Hf = -617394.5434018878, H0 = 54993.54329380253, Tlimit = 1000, alow = {15947.39709, -416.041272, 9.01063832, -0.003090359024, 3.62126426e-006, -2.260138392e-009, 5.80905555e-013}, blow = {-20804.414, -14.12175736}, ahigh = {-33402.9918, -9.34351178, 7.50746854, -3.14770789e-006, 7.241336470000001e-010, -8.56766495e-014, 4.0696917e-018}, bhigh = {-22945.55505, -5.24127259}, R_s = R_NASA_2002/MgI2.MM);
          constant IdealGases.Common.DataRecord MgN(name = "MgN", MM = 0.0383117, Hf = 7535452.616302591, H0 = 234624.9579110298, Tlimit = 1000, alow = {37595.3864, -485.316428, 5.16305424, 0.0002591539493, -1.518993975e-006, 1.522840476e-009, -4.992531450000001e-013}, blow = {36072.9461, -3.813908776}, ahigh = {-60185.891, -40.1086478, 4.52949895, 4.76049091e-005, 2.547271298e-009, -2.894058118e-013, 1.330639131e-017}, bhigh = {33412.857, 0.7925250209}, R_s = R_NASA_2002/MgN.MM);
          constant IdealGases.Common.DataRecord MgO(name = "MgO", MM = 0.0403044, Hf = 800441.3165808199, H0 = 221045.5186034279, Tlimit = 1000, alow = {351365.974, -5287.19716, 33.8206006, -0.08400489629999999, 0.000121001616, -7.630795020000001e-008, 1.701022862e-011}, blow = {27906.79519, -162.4886199}, ahigh = {-15867383.67, 34204.681, -17.74087677, 0.00700496305, -1.104138249e-006, 8.957488529999999e-011, -3.052513649e-015}, bhigh = {-230050.4434, 173.8984472}, R_s = R_NASA_2002/MgO.MM);
          constant IdealGases.Common.DataRecord MgOH(name = "MgOH", MM = 0.04131234, Hf = -3205555.047232862, H0 = 269272.6676823439, Tlimit = 1000, alow = {38398.5162, -736.7383640000001, 7.92066446, -0.000595094059, -2.112941162e-006, 3.22828211e-009, -1.214159329e-012}, blow = {-13923.26188, -19.16078109}, ahigh = {664866.475, -1770.750355, 7.26999927, 0.000533684276, -1.980894443e-007, 3.025677088e-011, -1.554849476e-015}, bhigh = {-6149.11456, -16.71027009}, R_s = R_NASA_2002/MgOH.MM);
          constant IdealGases.Common.DataRecord MgOHplus(name = "MgOHplus", MM = 0.0413117914, Hf = 14905414.38975217, H0 = 246621.3556645719, Tlimit = 1000, alow = {117022.4573, -1735.933343, 11.64059613, -0.008449876219999999, 7.35171374e-006, -2.790223071e-009, 3.51498213e-013}, blow = {81188.07670000001, -42.7117437}, ahigh = {829633.954, -2459.700177, 8.11873202, 3.5005791e-005, -4.67057475e-008, 8.312358260000001e-012, -4.80283622e-016}, bhigh = {88016.61709999999, -24.38155217}, R_s = R_NASA_2002/MgOHplus.MM);
          constant IdealGases.Common.DataRecord Mg_OH_2(name = "Mg_OH_2", MM = 0.05831968, Hf = -9465000.631004833, H0 = 293752.6063243146, Tlimit = 1000, alow = {52458.9467, -1289.056383, 13.89327642, -0.000780669367, -4.15125723e-006, 6.10947304e-009, -2.274138833e-012}, blow = {-62950.8915, -50.1535334}, ahigh = {1713709.254, -4730.00535, 14.48925967, 0.0001907819857, -1.226834131e-007, 2.015343753e-011, -1.128993279e-015}, bhigh = {-38877.2467, -58.4049812}, R_s = R_NASA_2002/Mg_OH_2.MM);
          constant IdealGases.Common.DataRecord MgS(name = "MgS", MM = 0.05637, Hf = 2140310.643959553, H0 = 163812.5066524748, Tlimit = 1000, alow = {-9565.78809, 144.3637798, 1.813794717, 0.01147168775, -2.220170412e-005, 1.995344981e-008, -6.09068874e-012}, blow = {12765.01517, 14.61333093}, ahigh = {26507943.28, -77113.5586, 84.63771680000001, -0.0364425068, 8.403084420000002e-006, -9.53988217e-010, 4.264658029999999e-014}, bhigh = {507893.117, -583.4656096}, R_s = R_NASA_2002/MgS.MM);
          constant IdealGases.Common.DataRecord Mg2(name = "Mg2", MM = 0.04861, Hf = 5894122.917095248, H0 = 196299.423986834, Tlimit = 1000, alow = {4545.195589999999, 411.585004, 0.484119617, 0.00489196965, -6.39553684e-006, 4.29976455e-009, -1.164624418e-012}, blow = {31816.4179, 26.40432143}, ahigh = {30382.24994, 59.4524046, 2.352706666, 0.0001378537924, -5.89569204e-008, 1.104045317e-011, -6.558868290000001e-016}, bhigh = {33510.3656, 15.88177377}, R_s = R_NASA_2002/Mg2.MM);
          constant IdealGases.Common.DataRecord Mg2F4(name = "Mg2F4", MM = 0.1246036128, Hf = -13790683.60367798, H0 = 169684.5984228156, Tlimit = 1000, alow = {151195.6137, -3122.595912, 25.17715088, -0.01558723757, 1.552195619e-005, -8.40872905e-009, 1.911618525e-012}, blow = {-195307.8883, -108.5103537}, ahigh = {-298061.0166, -120.1299868, 16.09110864, -3.68745629e-005, 8.22031705e-009, -9.48886978e-013, 4.41979533e-017}, bhigh = {-211734.969, -53.08655469999999}, R_s = R_NASA_2002/Mg2F4.MM);
          constant IdealGases.Common.DataRecord Mn(name = "Mn", MM = 0.054938049, Hf = 5140335.434918703, H0 = 112807.5734906421, Tlimit = 1000, alow = {0.1034061359, -0.001551537349, 2.500009148, -2.723162066e-008, 4.33389743e-011, -3.51109389e-014, 1.136032201e-017}, blow = {33219.3519, 6.649325463}, ahigh = {5855.15582, 883.8588440000001, -0.0364866258, 0.002703720687, -1.324971998e-006, 2.87260329e-010, -1.92363357e-014}, bhigh = {28678.03487, 22.92541198}, R_s = R_NASA_2002/Mn.MM);
          constant IdealGases.Common.DataRecord Mnplus(name = "Mnplus", MM = 0.0549375004, Hf = 18309375.57544937, H0 = 112808.6999749992, Tlimit = 1000, alow = {345.80177, -4.25115133, 2.521281028, -5.56508728e-005, 8.03716221e-008, -6.09355097e-011, 1.900014268e-014}, blow = {120253.3602, 6.683468162}, ahigh = {647131.41, -2403.796253, 5.93771575, -0.002341014594, 7.46416564e-007, -9.075969730000001e-011, 4.467879847e-015}, bhigh = {134990.2108, -17.02666341}, R_s = R_NASA_2002/Mnplus.MM);
          constant IdealGases.Common.DataRecord Mo(name = "Mo", MM = 0.09594, Hf = 6863664.790494058, H0 = 64596.91473837815, Tlimit = 1000, alow = {76.46367910000001, -1.159269043, 2.506929462, -2.099249725e-005, 3.41477943e-008, -2.841269591e-011, 9.492443320999999e-015}, blow = {78458.99799999999, 7.60183566}, ahigh = {5573271, -16623.65811, 21.35147077, -0.01003069377, 2.409784357e-006, -1.811267352e-010, 1.034189087e-015}, bhigh = {184264.6473, -127.5326434}, R_s = R_NASA_2002/Mo.MM);
          constant IdealGases.Common.DataRecord Moplus(name = "Moplus", MM = 0.0959394514, Hf = 14061086.53233346, H0 = 64597.28411580224, Tlimit = 1000, alow = {129.8236623, -1.560279908, 2.507600281, -1.923789063e-005, 2.673316651e-008, -1.937174292e-011, 5.729735412e-015}, blow = {161510.3759, 7.44254346}, ahigh = {12988911.2, -39482.7623, 48.6659978, -0.02605352326, 7.21543192e-006, -8.719164960000001e-010, 3.78842304e-014}, bhigh = {411894.857, -321.679103}, R_s = R_NASA_2002/Moplus.MM);
          constant IdealGases.Common.DataRecord Mominus(name = "Mominus", MM = 0.0959405486, Hf = 6048794.138331621, H0 = 64596.54536517837, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {69051.2369, 7.48565954}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {69051.2369, 7.48565954}, R_s = R_NASA_2002/Mominus.MM);
          constant IdealGases.Common.DataRecord MoO(name = "MoO", MM = 0.1119394, Hf = 3198206.556404626, H0 = 91595.30067161338, Tlimit = 1000, alow = {-28011.52706, 513.988348, 1.075385931, 0.008681048470000001, -1.111118984e-005, 7.23434933e-009, -1.893138381e-012}, blow = {39413.7408, 22.72230239}, ahigh = {1573131.992, -5241.48358, 11.02656868, -0.00390299662, 1.147334134e-006, -1.358975691e-010, 5.77526858e-015}, bhigh = {74489.72, -42.5361293}, R_s = R_NASA_2002/MoO.MM);
          constant IdealGases.Common.DataRecord MoO2(name = "MoO2", MM = 0.1279388, Hf = -121605.6348816778, H0 = 83688.64644658228, Tlimit = 1000, alow = {32471.8322, -190.4783783, 2.120771647, 0.01650280086, -2.381696822e-005, 1.652371586e-008, -4.49445243e-012}, blow = {-1862.932837, 16.40582056}, ahigh = {309614.3654, -1932.750274, 9.428673180000001, -0.001630508855, 5.752760170000001e-007, -7.59045747e-011, 3.46133778e-015}, bhigh = {7327.72518, -25.33315948}, R_s = R_NASA_2002/MoO2.MM);
          constant IdealGases.Common.DataRecord MoO3(name = "MoO3", MM = 0.1439382, Hf = -2531727.99854382, H0 = 91655.89815629208, Tlimit = 1000, alow = {59773.8536, -768.455783, 5.88184444, 0.01686119817, -2.582485043e-005, 1.850382718e-008, -5.15224985e-012}, blow = {-41558.7239, -6.52916216}, ahigh = {-409759.727, 237.9066513, 9.3111008, 0.000657933891, -2.895307725e-007, 5.69263726e-011, -3.48965731e-015}, bhigh = {-49237.38720000001, -21.14864892}, R_s = R_NASA_2002/MoO3.MM);
          constant IdealGases.Common.DataRecord MoO3minus(name = "MoO3minus", MM = 0.1439387486, Hf = -4552231.469101435, H0 = 94207.31479111943, Tlimit = 1000, alow = {182161.7352, -2224.65697, 13.20405967, -0.001249800352, -1.864166983e-006, 2.27657947e-009, -7.366564570000001e-013}, blow = {-69389.86, -46.9937721}, ahigh = {-488109.872, 18.48536991, 10.42644941, -0.000626555791, 3.020554347e-007, -4.73319589e-011, 2.527517727e-015}, bhigh = {-83378.155, -27.01522825}, R_s = R_NASA_2002/MoO3minus.MM);
          constant IdealGases.Common.DataRecord Mo2O6(name = "Mo2O6", MM = 0.2878764, Hf = -3992848.364784332, H0 = 89495.00202170099, Tlimit = 1000, alow = {156837.5811, -2159.930184, 15.22500503, 0.031941989, -5.06387715e-005, 3.68937182e-008, -1.037872908e-011}, blow = {-130993.1161, -54.089185}, ahigh = {-631223.816, -664.282755, 22.4938357, -0.0001968470329, 4.33674061e-008, -4.959777990000001e-012, 2.293212733e-016}, bhigh = {-143057.325, -86.69628539999999}, R_s = R_NASA_2002/Mo2O6.MM);
          constant IdealGases.Common.DataRecord Mo3O9(name = "Mo3O9", MM = 0.4318146, Hf = -4404740.712796649, H0 = 94448.21689678858, Tlimit = 1000, alow = {148338.6187, -1863.895133, 17.38405871, 0.0623301232, -9.32844135e-005, 6.61363879e-008, -1.830607518e-011}, blow = {-224894.5631, -58.2666947}, ahigh = {-923029.054, -1076.171759, 34.8000726, -0.00031896338, 7.02839704e-008, -8.03964264e-012, 3.71787953e-016}, bhigh = {-235742.2166, -144.8769485}, R_s = R_NASA_2002/Mo3O9.MM);
          constant IdealGases.Common.DataRecord Mo4O12(name = "Mo4O12", MM = 0.5757528, Hf = -4560163.273196414, H0 = 95342.7408429451, Tlimit = 1000, alow = {223487.6437, -2996.203728, 26.82458827, 0.0759734572, -0.0001155247012, 8.25647257e-008, -2.296764551e-011}, blow = {-308461.9476, -106.5236386}, ahigh = {-1225283.388, -1368.141197, 47.0168781, -0.00040529102, 8.928472389999999e-008, -1.021091158e-011, 4.721091689999999e-016}, bhigh = {-325647.777, -204.7486535}, R_s = R_NASA_2002/Mo4O12.MM);
          constant IdealGases.Common.DataRecord Mo5O15(name = "Mo5O15", MM = 0.7196910000000001, Hf = -4625746.934448255, H0 = 95759.62739564618, Tlimit = 1000, alow = {276890.3251, -3757.9331, 34.0819776, 0.09485414959999999, -0.00014426721, 1.0311639e-007, -2.868600013e-011}, blow = {-391350.703, -142.6449143}, ahigh = {-1535389.516, -1710.367122, 59.2712578, -0.0005066836290000001, 1.116223706e-007, -1.276562233e-011, 5.90231891e-016}, bhigh = {-412897.2380000001, -265.1287167}, R_s = R_NASA_2002/Mo5O15.MM);
          constant IdealGases.Common.DataRecord N(name = "N", MM = 0.0140067, Hf = 33746706.93311058, H0 = 442461.6790535958, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {56104.6378, 4.193905036}, ahigh = {88765.0138, -107.12315, 2.362188287, 0.0002916720081, -1.7295151e-007, 4.01265788e-011, -2.677227571e-015}, bhigh = {56973.5133, 4.865231506}, R_s = R_NASA_2002/N.MM);
          constant IdealGases.Common.DataRecord Nplus(name = "Nplus", MM = 0.0140061514, Hf = 134378643.3723685, H0 = 508099.891023597, Tlimit = 1000, alow = {5237.07921, 2.299958315, 2.487488821, 2.737490756e-005, -3.134447576e-008, 1.850111332e-011, -4.447350984e-015}, blow = {225628.4738, 5.076830786}, ahigh = {290497.0374, -855.7908610000001, 3.47738929, -0.000528826719, 1.352350307e-007, -1.389834122e-011, 5.046166279e-016}, bhigh = {231080.9984, -1.994146545}, R_s = R_NASA_2002/Nplus.MM);
          constant IdealGases.Common.DataRecord Nminus(name = "Nminus", MM = 0.0140072486, Hf = 33806606.74502486, H0 = 463927.2983275246, Tlimit = 1000, alow = {1445.682471, 7.33520511, 2.476680939, 4.22786918e-005, -4.42629332e-008, 2.490985431e-011, -5.83160809e-015}, blow = {56176.25, 5.145753977}, ahigh = {2404.189576, 0.2954965336, 2.499789368, 8.30756497e-008, -1.82994277e-011, 2.100136461e-015, -9.754986710000001e-020}, bhigh = {56214.13890000001, 5.006484157}, R_s = R_NASA_2002/Nminus.MM);
          constant IdealGases.Common.DataRecord NCO(name = "NCO", MM = 0.04201680000000001, Hf = 3137964.837874374, H0 = 242718.2698349232, Tlimit = 1000, alow = {11365.03036, -244.4613367, 4.6713761, 0.002309387548, 2.798649599e-006, -4.54635738e-009, 1.692880931e-012}, blow = {15776.49188, -0.2171476903}, ahigh = {108944.5289, -1735.459316, 8.65561033, -0.000405322926, 7.59971641e-008, -7.25380415e-012, 3.24487241e-016}, bhigh = {23657.92776, -26.1953297}, R_s = R_NASA_2002/NCO.MM);
          constant IdealGases.Common.DataRecord ND(name = "ND", MM = 0.016020802, Hf = 22204805.78937309, H0 = 539798.1948718922, Tlimit = 1000, alow = {22901.55757, -395.738851, 6.17901033, -0.00884780697, 1.44158297e-005, -1.006647227e-008, 2.654403586e-012}, blow = {43559.13430000001, -11.80414072}, ahigh = {543965.796, -2084.583507, 5.83408972, -0.000418939336, 9.768929529999999e-008, -1.056317654e-011, 4.68307921e-016}, bhigh = {54666.3341, -14.80810939}, R_s = R_NASA_2002/ND.MM);
          constant IdealGases.Common.DataRecord ND2(name = "ND2", MM = 0.018034904, Hf = 10248824.72343629, H0 = 552391.3517920583, Tlimit = 1000, alow = {19352.22164, -213.0631713, 4.8440176, -0.002516949288, 7.61638154e-006, -5.46450177e-009, 1.292736999e-012}, blow = {22119.98374, -3.171712417}, ahigh = {1631308.357, -6564.63749, 12.80547961, -0.003094456779, 9.181660230000001e-007, -1.241119284e-010, 6.22629986e-015}, bhigh = {61089.2958, -61.24502693}, R_s = R_NASA_2002/ND2.MM);
          constant IdealGases.Common.DataRecord ND3(name = "ND3", MM = 0.020049006, Hf = -2730913.742057836, H0 = 510449.2462120068, Tlimit = 1000, alow = {10451.2037, 161.0166943, 0.857496323, 0.01319688794, -1.153090144e-005, 7.14249556e-009, -2.109194351e-012}, blow = {-8220.948899999999, 16.75921299}, ahigh = {2599516.958, -10134.20124, 17.98028169, -0.0035826098, 1.009922e-006, -1.537638609e-010, 9.106175650000001e-015}, bhigh = {53972.0566, -98.10988569}, R_s = R_NASA_2002/ND3.MM);
          constant IdealGases.Common.DataRecord NF(name = "NF", MM = 0.0330051032, Hf = 7059226.525914937, H0 = 264750.1190058391, Tlimit = 1000, alow = {-35049.2775, 667.450299, -1.201665982, 0.01452074253, -1.822873148e-005, 1.160136864e-008, -2.973416333e-012}, blow = {23954.14002, 30.89260431}, ahigh = {800298.733, -3237.69658, 8.703408870000001, -0.002701025798, 9.15004211e-007, -1.36525663e-010, 7.23462441e-015}, bhigh = {46428.19450000001, -30.19933248}, R_s = R_NASA_2002/NF.MM);
          constant IdealGases.Common.DataRecord NF2(name = "NF2", MM = 0.0520035064, Hf = 661906.270997142, H0 = 203478.6831220289, Tlimit = 1000, alow = {15118.31104, 91.9638994, 0.494730179, 0.02001847323, -2.767712684e-005, 1.872924867e-008, -5.020318040000001e-012}, blow = {2839.279606, 22.7051567}, ahigh = {-194501.0078, -353.603407, 7.26349436, -8.4023804e-005, 2.326721111e-008, -2.667577562e-012, 1.236070614e-016}, bhigh = {3435.44059, -13.36102511}, R_s = R_NASA_2002/NF2.MM);
          constant IdealGases.Common.DataRecord NF3(name = "NF3", MM = 0.07100190960000001, Hf = -1854879.689038673, H0 = 166960.4531312493, Tlimit = 1000, alow = {87571.49280000001, -903.1832890000001, 4.02741727, 0.02314439555, -3.41510647e-005, 2.409483651e-008, -6.63346419e-012}, blow = {-12372.32074, 0.3026430713}, ahigh = {-349626.876, -497.372867, 10.36866128, 8.90068765e-005, 5.88265436e-008, -3.157737664e-012, 1.714329953e-016}, bhigh = {-17131.83352, -30.98920858}, R_s = R_NASA_2002/NF3.MM);
          constant IdealGases.Common.DataRecord NH(name = "NH", MM = 0.01501464, Hf = 23778925.16903503, H0 = 572847.7672458348, Tlimit = 1000, alow = {13596.5132, -190.0296604, 4.51849679, -0.002432776899, 2.377587464e-006, -2.592797084e-010, -2.659680792e-013}, blow = {42809.7219, -3.886561616}, ahigh = {1958141.991, -5782.861300000001, 9.33574202, -0.002292910311, 6.07609248e-007, -6.647942750000001e-011, 2.384234783e-015}, bhigh = {78989.1234, -41.169704}, R_s = R_NASA_2002/NH.MM);
          constant IdealGases.Common.DataRecord NHplus(name = "NHplus", MM = 0.0150140914, Hf = 110948299.8085385, H0 = 632413.493899471, Tlimit = 1000, alow = {4253.656849999999, -245.8222206, 6.70891949, -0.0103848943, 1.509008623e-005, -9.58051219e-009, 2.333206758e-012}, blow = {200107.7797, -13.95057632}, ahigh = {1405709.438, -4136.21571, 7.63201448, -0.001228325778, 2.721187746e-007, -2.010098289e-011, 3.71719018e-017}, bhigh = {225897.596, -27.86785234}, R_s = R_NASA_2002/NHplus.MM);
          constant IdealGases.Common.DataRecord NHF(name = "NHF", MM = 0.0340130432, Hf = 3292854.43062031, H0 = 294878.8775242552, Tlimit = 1000, alow = {-51106.59820000001, 961.225643, -2.706446594, 0.0203656268, -2.425558952e-005, 1.551553017e-008, -4.05845826e-012}, blow = {7909.62834, 40.99317124}, ahigh = {901390.2720000001, -3463.39705, 8.705804860000001, -0.0004018963409999999, 2.322774501e-008, 6.28048733e-012, -6.28309569e-016}, bhigh = {33370.6534, -29.00483634}, R_s = R_NASA_2002/NHF.MM);
          constant IdealGases.Common.DataRecord NHF2(name = "NHF2", MM = 0.0530114464, Hf = -1942976.602124933, H0 = 203869.9136494416, Tlimit = 1000, alow = {-56261.1342, 1205.756556, -6.01752942, 0.0376002769, -4.6191986e-005, 2.94247557e-008, -7.59873236e-012}, blow = {-18970.14374, 59.01714907}, ahigh = {739427.899, -4004.47177, 12.2132232, -0.000697043773, 1.271073981e-007, -1.247136898e-011, 5.08651759e-016}, bhigh = {9134.195979999999, -48.67843963}, R_s = R_NASA_2002/NHF2.MM);
          constant IdealGases.Common.DataRecord NH2(name = "NH2", MM = 0.01602258, Hf = 11804260.79944678, H0 = 620241.371863957, Tlimit = 1000, alow = {-31182.40659, 475.424339, 1.372395176, 0.006306429719999999, -5.98789356e-006, 4.49275234e-009, -1.414073548e-012}, blow = {19289.39662, 15.40126885}, ahigh = {2111053.74, -6880.62723, 11.32305924, -0.001829236741, 5.64389009e-007, -7.88645248e-011, 4.078593449999999e-015}, bhigh = {65037.7856, -53.59155744}, R_s = R_NASA_2002/NH2.MM);
          constant IdealGases.Common.DataRecord NH2F(name = "NH2F", MM = 0.0350209832, Hf = -2141573.226876166, H0 = 288540.6141310162, Tlimit = 1000, alow = {-109237.476, 1844.91978, -7.6738716, 0.0322953344, -3.38810867e-005, 1.97187155e-008, -4.81020515e-012}, blow = {-18783.1896, 68.61483738999999}, ahigh = {1927205.34, -7500.447160000001, 13.9558958, -0.00118480442, 2.05067867e-007, -1.90876131e-011, 7.38923621e-016}, bhigh = {35529.2734, -67.31185490999999}, R_s = R_NASA_2002/NH2F.MM);
          constant IdealGases.Common.DataRecord NH3(name = "NH3", MM = 0.01703052, Hf = -2697510.117130892, H0 = 589713.1150428759, Tlimit = 1000, alow = {-76812.26149999999, 1270.951578, -3.89322913, 0.02145988418, -2.183766703e-005, 1.317385706e-008, -3.33232206e-012}, blow = {-12648.86413, 43.66014588}, ahigh = {2452389.535, -8040.89424, 12.71346201, -0.000398018658, 3.55250275e-008, 2.53092357e-012, -3.32270053e-016}, bhigh = {43861.91959999999, -64.62330602}, R_s = R_NASA_2002/NH3.MM);
          constant IdealGases.Common.DataRecord NH2OH(name = "NH2OH", MM = 0.03302992, Hf = -1513779.022171413, H0 = 340169.7006835016, Tlimit = 1000, alow = {-56175.8667, 1209.290057, -6.17959906, 0.0405311644, -5.19010554e-005, 3.59454458e-008, -9.933681639999999e-012}, blow = {-12658.88352, 57.27932928000001}, ahigh = {4878285.05, -15336.04636, 22.2723999, -0.002514583678, 3.33958973e-007, -1.881744532e-011, 1.918174365e-016}, bhigh = {89230.2071, -126.9053624}, R_s = R_NASA_2002/NH2OH.MM);
          constant IdealGases.Common.DataRecord NH4plus(name = "NH4plus", MM = 0.0180379114, Hf = 35752750.45424605, H0 = 553211.0552444559, Tlimit = 1000, alow = {-266831.5752, 3763.02069, -15.71327725, 0.0454882021, -4.37996212e-005, 2.464478293e-008, -5.96153233e-012}, blow = {58232.8472, 111.2087156}, ahigh = {4141889, -14420.72042, 20.11893564, -0.001971492619, 3.112721421e-007, -2.602979969e-011, 8.894342129999999e-016}, bhigh = {166419.6236, -120.1535761}, R_s = R_NASA_2002/NH4plus.MM);
          constant IdealGases.Common.DataRecord NO(name = "NO", MM = 0.0300061, Hf = 3041758.509103149, H0 = 305908.1320131574, Tlimit = 1000, alow = {-11439.16503, 153.6467592, 3.43146873, -0.002668592368, 8.48139912e-006, -7.685111050000001e-009, 2.386797655e-012}, blow = {9098.214410000001, 6.72872549}, ahigh = {223901.8716, -1289.651623, 5.43393603, -0.00036560349, 9.880966450000001e-008, -1.416076856e-011, 9.380184619999999e-016}, bhigh = {17503.17656, -8.50166909}, R_s = R_NASA_2002/NO.MM);
          constant IdealGases.Common.DataRecord NOCL(name = "NOCL", MM = 0.06545910000000001, Hf = 805064.9642295723, H0 = 173612.0417176527, Tlimit = 1000, alow = {23088.35209, -549.598384, 7.73046336, -0.0050739109, 1.062996184e-005, -8.7932497e-009, 2.648180166e-012}, blow = {7389.89839, -13.18393021}, ahigh = {-613341.333, -391.929883, 9.13891722, -0.002605664613, 1.295687247e-006, -2.215378352e-010, 1.280394898e-014}, bhigh = {4517.32842, -23.07323335}, R_s = R_NASA_2002/NOCL.MM);
          constant IdealGases.Common.DataRecord NOF(name = "NOF", MM = 0.0490045032, Hf = -1326408.712577255, H0 = 218760.9362398352, Tlimit = 1000, alow = {47550.2426, -725.3904170000001, 7.21399636, -0.002532427181, 6.3777439e-006, -5.51830588e-009, 1.681935713e-012}, blow = {-5609.72252, -12.89663616}, ahigh = {1889069.274, -6731.02266, 14.19018767, -0.00369312462, 9.93857514e-007, -1.080748188e-010, 4.21035443e-015}, bhigh = {32099.0078, -63.70266962}, R_s = R_NASA_2002/NOF.MM);
          constant IdealGases.Common.DataRecord NOF3(name = "NOF3", MM = 0.08700130959999999, Hf = -2149392.932816267, H0 = 157441.9174030456, Tlimit = 1000, alow = {148836.0135, -2241.049812, 13.02355027, 0.00546397668, -8.641865250000001e-006, 5.91365903e-009, -1.577009169e-012}, blow = {-13283.42568, -48.77320739}, ahigh = {-278562.5217, -1252.321663, 13.90824337, -0.00035666875, 7.78501106e-008, -8.85041197e-012, 4.07598003e-016}, bhigh = {-20256.51446, -51.06881858999999}, R_s = R_NASA_2002/NOF3.MM);
          constant IdealGases.Common.DataRecord NO2(name = "NO2", MM = 0.0460055, Hf = 743237.6346306421, H0 = 221890.3174620426, Tlimit = 1000, alow = {-56420.3878, 963.308572, -2.434510974, 0.01927760886, -1.874559328e-005, 9.145497730000001e-009, -1.777647635e-012}, blow = {-1547.925037, 40.6785121}, ahigh = {721300.157, -3832.6152, 11.13963285, -0.002238062246, 6.54772343e-007, -7.6113359e-011, 3.32836105e-015}, bhigh = {25024.97403, -43.0513004}, R_s = R_NASA_2002/NO2.MM);
          constant IdealGases.Common.DataRecord NO2minus(name = "NO2minus", MM = 0.0460060486, Hf = -4348028.07646471, H0 = 221210.2388641132, Tlimit = 1000, alow = {-12820.67858, 699.013818, -2.812596273, 0.02412894252, -2.831606689e-005, 1.670509365e-008, -3.98333013e-012}, blow = {-28099.15579, 40.6327151}, ahigh = {132571.0335, -1557.032129, 8.12672192, -0.000272862678, -4.7075418e-008, 2.826729008e-011, -2.353985481e-015}, bhigh = {-17157.95217, -22.28576043}, R_s = R_NASA_2002/NO2minus.MM);
          constant IdealGases.Common.DataRecord NO2CL(name = "NO2CL", MM = 0.0814585, Hf = 153452.3714529484, H0 = 149828.9190201145, Tlimit = 1000, alow = {8508.370340000001, -180.5383762, 3.78538856, 0.01414934934, -1.423946765e-005, 7.02822618e-009, -1.374688214e-012}, blow = {915.6246469999999, 6.958904458}, ahigh = {-108677.3327, -1452.231167, 11.05656962, -0.000400009928, 9.101543039999999e-008, -1.036656913e-011, 4.78166481e-016}, bhigh = {6294.26732, -35.21239681}, R_s = R_NASA_2002/NO2CL.MM);
          constant IdealGases.Common.DataRecord NO2F(name = "NO2F", MM = 0.06500390319999999, Hf = -1676822.385028719, H0 = 174552.3028838675, Tlimit = 1000, alow = {56678.5695, -653.825195, 4.47277152, 0.01368870672, -1.460533236e-005, 7.779227940000001e-009, -1.689355106e-012}, blow = {-11021.79443, 0.329207431}, ahigh = {-100857.7842, -1704.722752, 11.22954945, -0.000468521597, 1.047692566e-007, -1.189150595e-011, 5.470307120000001e-016}, bhigh = {-6891.71918, -38.49788492}, R_s = R_NASA_2002/NO2F.MM);
          constant IdealGases.Common.DataRecord NO3(name = "NO3", MM = 0.0620049, Hf = 1147135.145770738, H0 = 176742.7090439627, Tlimit = 1000, alow = {34053.9841, 226.6670652, -3.79308163, 0.041707327, -5.709913270000001e-005, 3.83415811e-008, -1.021969284e-011}, blow = {7088.112200000001, 42.73091713}, ahigh = {-394387.271, -824.426353, 10.61325843, -0.0002448749816, 5.40606032e-008, -6.19546675e-012, 2.870000149e-016}, bhigh = {8982.01173, -34.44666597}, R_s = R_NASA_2002/NO3.MM);
          constant IdealGases.Common.DataRecord NO3minus(name = "NO3minus", MM = 0.0620054486, Hf = -5012132.611197655, H0 = 173744.4892867044, Tlimit = 1000, alow = {92048.1361, -391.117115, -0.2354356764, 0.02836042108, -3.46132408e-005, 2.08178746e-008, -5.02160127e-012}, blow = {-35764.115, 22.99942308}, ahigh = {-311000.5758, -1369.087552, 11.01342913, -0.000403687882, 8.90208647e-008, -1.01973348e-011, 4.72333079e-016}, bhigh = {-33643.2109, -38.78432657}, R_s = R_NASA_2002/NO3minus.MM);
          constant IdealGases.Common.DataRecord NO3F(name = "NO3F", MM = 0.0810033032, Hf = 185177.6335955643, H0 = 178315.6418243448, Tlimit = 1000, alow = {64728.3203, -821.3134309999999, 6.19491744, 0.01805438628, -1.99669324e-005, 1.124482018e-008, -2.680013077e-012}, blow = {4206.66179, -7.016104301}, ahigh = {-341179.33, -2353.908798, 16.28114887, -0.001910415273, 4.69087356e-007, -5.68604014e-011, 2.720906921e-015}, bhigh = {9760.583979999999, -65.58153684}, R_s = R_NASA_2002/NO3F.MM);
          constant IdealGases.Common.DataRecord N2(name = "N2", MM = 0.0280134, Hf = 0, H0 = 309498.4543111511, Tlimit = 1000, alow = {22103.71497, -381.846182, 6.08273836, -0.00853091441, 1.384646189e-005, -9.62579362e-009, 2.519705809e-012}, blow = {710.846086, -10.76003744}, ahigh = {587712.406, -2239.249073, 6.06694922, -0.00061396855, 1.491806679e-007, -1.923105485e-011, 1.061954386e-015}, bhigh = {12832.10415, -15.86640027}, R_s = R_NASA_2002/N2.MM);
          constant IdealGases.Common.DataRecord N2plus(name = "N2plus", MM = 0.0280128514, Hf = 53886282.4938985, H0 = 309540.07059774, Tlimit = 1000, alow = {-34740.4747, 269.6222703, 3.16491637, -0.002132239781, 6.730476399999999e-006, -5.63730497e-009, 1.621756e-012}, blow = {179000.4424, 6.832974166}, ahigh = {-2845599.002, 7058.89303, -2.884886385, 0.003068677059, -4.36165231e-007, 2.102514545e-011, 5.41199647e-016}, bhigh = {134038.8483, 50.90897022}, R_s = R_NASA_2002/N2plus.MM);
          constant IdealGases.Common.DataRecord N2minus(name = "N2minus", MM = 0.0280139486, Hf = 5289624.969184102, H0 = 309641.5333609915, Tlimit = 1000, alow = {-81462.2711, 906.360079, -0.1520054079, 0.00602319084, -2.897138445e-006, -4.12910668e-011, 3.20698977e-013}, blow = {12188.08548, 26.38068855}, ahigh = {216963.7706, -1275.098516, 5.3910957, -0.000319890751, 7.311051349999999e-008, -8.202017370000001e-012, 3.7400447e-016}, bhigh = {24249.64308, -9.014934294}, R_s = R_NASA_2002/N2minus.MM);
          constant IdealGases.Common.DataRecord NCN(name = "NCN", MM = 0.0400241, Hf = 12503880.73685604, H0 = 254351.178415005, Tlimit = 1000, alow = {-56346.80699999999, 732.380458, -0.782140184, 0.01838552441, -1.950836491e-005, 1.035712021e-008, -2.208158483e-012}, blow = {55397.897, 29.05308985}, ahigh = {-164188.0975, -776.784075, 7.99998187, -0.0001659081508, 2.983403318e-008, -3.120157047e-012, 1.99269872e-016}, bhigh = {61844.24479999999, -21.4910882}, R_s = R_NASA_2002/NCN.MM);
          constant IdealGases.Common.DataRecord N2D2_cis(name = "N2D2_cis", MM = 0.032041604, Hf = 6331060.392607061, H0 = 321707.8957720095, Tlimit = 1000, alow = {-27437.33656, 714.980883, -2.22324762, 0.02088722282, -1.821711897e-005, 8.84407994e-009, -1.918010649e-012}, blow = {20111.15649, 36.37100195}, ahigh = {879807.471, -5299.36204, 13.55007485, -0.001316635227, 2.755816197e-007, -3.036294387e-011, 1.365324117e-015}, bhigh = {53563.11889999999, -62.71215875}, R_s = R_NASA_2002/N2D2_cis.MM);
          constant IdealGases.Common.DataRecord N2F2(name = "N2F2", MM = 0.06601020640000001, Hf = 944907.6044700869, H0 = 194951.0038193124, Tlimit = 1000, alow = {15438.9315, -218.363513, 3.89028425, 0.0167401774, -2.05639309e-005, 1.25869211e-008, -3.11049829e-012}, blow = {7052.0387, 5.265866442}, ahigh = {-182488.386, -953.402996, 10.6979548, -0.00027599687, 6.0554397e-008, -6.91121508e-012, 3.19258723e-016}, bhigh = {9283.46696, -32.46968772}, R_s = R_NASA_2002/N2F2.MM);
          constant IdealGases.Common.DataRecord N2F4(name = "N2F4", MM = 0.1040070128, Hf = -211524.1982990593, H0 = 171253.5580100807, Tlimit = 1000, alow = {116291.4512, -1538.660418, 9.054033049999999, 0.02862113563, -4.33228699e-005, 3.067642499e-008, -8.45547411e-012}, blow = {2865.277526, -24.76493006}, ahigh = {-518859.471, -670.225651, 16.50109262, -0.0002006404436, 4.43675251e-008, -5.08980888e-012, 2.359374159e-016}, bhigh = {-5281.4889, -60.40513435}, R_s = R_NASA_2002/N2F4.MM);
          constant IdealGases.Common.DataRecord N2H2(name = "N2H2", MM = 0.03002928, Hf = 7055072.782297812, H0 = 332907.1159881289, Tlimit = 1000, alow = {-150400.5163, 2346.687716, -9.40543029, 0.032842998, -3.121920401e-005, 1.72128319e-008, -4.014537220000001e-012}, blow = {13193.84041, 78.32382629999999}, ahigh = {6217567.87, -17539.52096, 20.22730509, -0.000975729766, -4.20841674e-007, 1.117921171e-010, -7.627102210000001e-015}, bhigh = {137415.2574, -119.9559168}, R_s = R_NASA_2002/N2H2.MM);
          constant IdealGases.Common.DataRecord NH2NO2(name = "NH2NO2", MM = 0.06202808, Hf = -419164.9975301508, H0 = 196102.3620270045, Tlimit = 1000, alow = {-45730.3506, 1201.365987, -8.10598411, 0.054027152, -6.43807445e-005, 4.02509792e-008, -1.02515419e-011}, blow = {-9615.78516, 68.67353357}, ahigh = {1654040.575, -8125.220880000001, 20.21742772, -0.001244291821, 2.122804183e-007, -1.948359653e-011, 7.43935136e-016}, bhigh = {42308.2258, -101.6190179}, R_s = R_NASA_2002/NH2NO2.MM);
          constant IdealGases.Common.DataRecord N2H4(name = "N2H4", MM = 0.03204516, Hf = 2970183.328777263, H0 = 357286.5293854048, Tlimit = 1000, alow = {-166075.6354, 3035.416736, -17.36889823, 0.0715983402, -8.8667993e-005, 5.79897028e-008, -1.530037218e-011}, blow = {-3731.92723, 119.0002218}, ahigh = {3293486.7, -11998.50628, 21.04406814, -0.001399381724, 1.933173351e-007, -1.318016127e-011, 3.16640017e-016}, bhigh = {83484.337, -115.5751024}, R_s = R_NASA_2002/N2H4.MM);
          constant IdealGases.Common.DataRecord N2O(name = "N2O", MM = 0.0440128, Hf = 1854006.107314236, H0 = 217685.1961247637, Tlimit = 1000, alow = {42882.2597, -644.011844, 6.03435143, 0.0002265394436, 3.47278285e-006, -3.62774864e-009, 1.137969552e-012}, blow = {11794.05506, -10.0312857}, ahigh = {343844.804, -2404.557558, 9.125636220000001, -0.000540166793, 1.315124031e-007, -1.4142151e-011, 6.38106687e-016}, bhigh = {21986.32638, -31.47805016}, R_s = R_NASA_2002/N2O.MM);
          constant IdealGases.Common.DataRecord N2Oplus(name = "N2Oplus", MM = 0.04401225139999999, Hf = 30286033.19756553, H0 = 241373.8598248578, Tlimit = 1000, alow = {-56241.4708, 669.621161, 0.0878145619, 0.01524476027, -1.527290811e-005, 7.827237389999999e-009, -1.646739623e-012}, blow = {155729.5192, 25.62354785}, ahigh = {-29835.53254, -1179.455967, 8.30018669, -0.0002887267217, 5.70510501e-008, -5.95888512e-012, 2.835725557e-016}, bhigh = {164602.1769, -22.87356617}, R_s = R_NASA_2002/N2Oplus.MM);
          constant IdealGases.Common.DataRecord N2O3(name = "N2O3", MM = 0.0760116, Hf = 1139702.295439117, H0 = 225240.029153445, Tlimit = 1000, alow = {-92044.44170000001, 929.552015, 3.20366481, 0.01356473078, -6.26296607e-006, -1.402915559e-009, 1.43162093e-012}, blow = {3313.62208, 18.44430953}, ahigh = {778388.186, -4483.02466, 16.66668024, -0.002062143878, 5.309541710000001e-007, -6.19045122e-011, 2.692956658e-015}, bhigh = {33609.1245, -67.39212388}, R_s = R_NASA_2002/N2O3.MM);
          constant IdealGases.Common.DataRecord N2O4(name = "N2O4", MM = 0.092011, Hf = 120756.4204279923, H0 = 181948.1475041028, Tlimit = 1000, alow = {-38047.5144, 561.2828890000001, -0.2083648324, 0.0388708782, -4.42241226e-005, 2.49881231e-008, -5.67910238e-012}, blow = {-3310.79473, 29.6392484}, ahigh = {-458284.3760000001, -1604.749805, 16.74102133, -0.0005091385080000001, 1.14363467e-007, -1.316288176e-011, 5.976316620000001e-016}, bhigh = {4306.90052, -65.69450380000001}, R_s = R_NASA_2002/N2O4.MM);
          constant IdealGases.Common.DataRecord N2O5(name = "N2O5", MM = 0.1080104, Hf = 123136.2905794257, H0 = 192550.2081281062, Tlimit = 1000, alow = {40078.2817, -876.9675120000001, 10.55932981, 0.01394613859, -8.884346920000001e-006, 8.500431150000001e-010, 7.79155091e-013}, blow = {3038.962037, -23.8683186}, ahigh = {-53255.7896, -3109.277389, 20.36088958, -0.000995990114, 2.401398635e-007, -3.057161911e-011, 1.495915511e-015}, bhigh = {13369.57281, -82.98623341000001}, R_s = R_NASA_2002/N2O5.MM);
          constant IdealGases.Common.DataRecord N3(name = "N3", MM = 0.0420201, Hf = 10375986.73016009, H0 = 227769.7102101138, Tlimit = 1000, alow = {33374.0679, -296.5683604, 3.31427915, 0.00672168536, -4.18112639e-006, 8.61844236e-010, 6.88335253e-014}, blow = {52988.4062, 5.312776486}, ahigh = {252926.4658, -2362.876591, 9.135267130000001, -0.000621287085, 1.324094351e-007, -1.47898964e-011, 6.721230470000001e-016}, bhigh = {64126.95389999999, -31.35825973}, R_s = R_NASA_2002/N3.MM);
          constant IdealGases.Common.DataRecord N3H(name = "N3H", MM = 0.04302804, Hf = 6832753.711300817, H0 = 254419.745821562, Tlimit = 1000, alow = {3242.57606, 66.9266489, 1.766142217, 0.01487411419, -1.53908644e-005, 9.172303550000001e-009, -2.337205474e-012}, blow = {33920.697, 15.13752057}, ahigh = {1170469.241, -5102.45199, 12.7828891, -0.000840948716, 1.592142834e-007, -1.512289051e-011, 6.102906629999999e-016}, bhigh = {64283.4447, -55.13119107999999}, R_s = R_NASA_2002/N3H.MM);
          constant IdealGases.Common.DataRecord Na(name = "Na", MM = 0.02298977, Hf = 4675992.843773557, H0 = 269573.2928167615, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {12183.82949, 4.24402818}, ahigh = {952572.3380000001, -2623.807254, 5.16259662, -0.001210218586, 2.306301844e-007, -1.249597843e-011, 7.226771190000001e-016}, bhigh = {29129.63564, -15.19717061}, R_s = R_NASA_2002/Na.MM);
          constant IdealGases.Common.DataRecord Naplus(name = "Naplus", MM = 0.0229892214, Hf = 26514291.9542286, H0 = 269579.7257405159, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {72565.3707, 3.55084508}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {72565.3707, 3.55084508}, R_s = R_NASA_2002/Naplus.MM);
          constant IdealGases.Common.DataRecord Naminus(name = "Naminus", MM = 0.0229903186, Hf = 2107557.917879398, H0 = 269566.8602000148, Tlimit = 1000, alow = {0, 0, 2.500000001, 0, 0, 0, 0}, blow = {5082.19967, 3.55091679}, ahigh = {0, 0, 2.500000001, 0, 0, 0, 0}, bhigh = {5082.19967, 3.55091679}, R_s = R_NASA_2002/Naminus.MM);
          constant IdealGases.Common.DataRecord NaALF4(name = "NaALF4", MM = 0.1259649208, Hf = -14748880.35653812, H0 = 165194.1418916051, Tlimit = 1000, alow = {131535.9536, -2394.685695, 19.09539612, 0.001044339733, -6.949754129999999e-006, 6.769098139999999e-009, -2.176199098e-012}, blow = {-215051.2366, -75.0510213}, ahigh = {-357117.793, -249.6543879, 16.18634511, -7.449049300000001e-005, 1.644510872e-008, -1.883696066e-012, 8.719877450000001e-017}, bhigh = {-227953.3538, -53.7066514}, R_s = R_NASA_2002/NaALF4.MM);
          constant IdealGases.Common.DataRecord NaBO2(name = "NaBO2", MM = 0.06579957, Hf = -9626952.425372992, H0 = 207944.6719788594, Tlimit = 1000, alow = {50468.6736, -869.99706, 8.942208239999999, 0.001092655824, 1.440608828e-006, -2.254633535e-009, 8.12331285e-013}, blow = {-73783.1836, -19.51815135}, ahigh = {85958.14049999999, -1691.902222, 11.18847517, -0.000456420231, 9.80450516e-008, -1.101655008e-011, 5.02917276e-016}, bhigh = {-69492.9206, -34.1635313}, R_s = R_NASA_2002/NaBO2.MM);
          constant IdealGases.Common.DataRecord NaBr(name = "NaBr", MM = 0.10289377, Hf = -1418247.985276465, H0 = 95449.10250640052, Tlimit = 1000, alow = {-14668.27136, 76.22282870000001, 3.92116347, 0.001793780908, -2.457391648e-006, 1.739334522e-009, -4.79670138e-013}, blow = {-19264.91755, 6.40438286}, ahigh = {897851.3019999999, -2697.899721, 7.54537716, -0.001566692184, 4.47039274e-007, -4.83281021e-011, 1.4239613e-015}, bhigh = {-1750.862247, -18.56478949}, R_s = R_NASA_2002/NaBr.MM);
          constant IdealGases.Common.DataRecord NaCN(name = "NaCN", MM = 0.04900717, Hf = 1923514.457170247, H0 = 247432.6103710947, Tlimit = 1000, alow = {24461.6541, -753.601997, 10.44966241, -0.01168769048, 1.849279385e-005, -1.319387974e-008, 3.58976656e-012}, blow = {12978.20493, -29.88519681}, ahigh = {366557.029, -1782.094358, 8.69962263, -0.0004463297, 9.36222931e-008, -1.03307132e-011, 4.650466810000001e-016}, bhigh = {20109.26347, -24.19276094}, R_s = R_NASA_2002/NaCN.MM);
          constant IdealGases.Common.DataRecord NaCL(name = "NaCL", MM = 0.05844277000000001, Hf = -3106370.283270283, H0 = 164521.9075002776, Tlimit = 1000, alow = {43623.78350000001, -758.303446, 8.259173000000001, -0.009640915140000001, 1.358854616e-005, -9.667032249999999e-009, 2.74626129e-012}, blow = {-19504.09477, -19.36687551}, ahigh = {331449.8760000001, -896.831565, 5.27728738, -0.0001475674008, -1.491128988e-008, 2.465673596e-011, -2.730355213e-015}, bhigh = {-17362.77667, -3.99828856}, R_s = R_NASA_2002/NaCL.MM);
          constant IdealGases.Common.DataRecord NaF(name = "NaF", MM = 0.0419881732, Hf = -7029524.423320232, H0 = 219707.3675022375, Tlimit = 1000, alow = {39598.8744, -653.4626069999999, 6.9411732, -0.00530781493, 6.97972066e-006, -4.82042573e-009, 1.364849175e-012}, blow = {-33529.4089, -14.03212229}, ahigh = {-1092926.912, 3293.30364, 0.413591984, 0.00263499447, -8.384295630000001e-007, 1.417053025e-010, -8.600270160000001e-015}, bhigh = {-57728.8463, 29.09489906}, R_s = R_NASA_2002/NaF.MM);
          constant IdealGases.Common.DataRecord NaH(name = "NaH", MM = 0.02399771, Hf = 5868689.345775076, H0 = 363830.757184748, Tlimit = 1000, alow = {-32222.0641, 623.762201, -0.9216277509999999, 0.01360765851, -1.659249878e-005, 1.033284544e-008, -2.589726392e-012}, blow = {13073.81654, 26.41418597}, ahigh = {-4756184.75, 14520.47626, -13.27563485, 0.01055828277, -2.990041189e-006, 3.90532288e-010, -1.923931194e-014}, bhigh = {-76329.2227, 122.207006}, R_s = R_NASA_2002/NaH.MM);
          constant IdealGases.Common.DataRecord NaI(name = "NaI", MM = 0.14989424, Hf = -604678.8722501947, H0 = 66394.27905968903, Tlimit = 1000, alow = {12288.68506, -285.71928, 5.961057, -0.00379253258, 5.56688131e-006, -4.045013680000001e-009, 1.172998933e-012}, blow = {-10882.50556, -3.99073992}, ahigh = {2281549.408, -7093.15663, 13.04994968, -0.00501349233, 1.581735155e-006, -2.285837754e-010, 1.19588995e-014}, bhigh = {32538.9362, -56.4002332}, R_s = R_NASA_2002/NaI.MM);
          constant IdealGases.Common.DataRecord NaLi(name = "NaLi", MM = 0.02993077, Hf = 5967047.289461648, H0 = 333874.4709875489, Tlimit = 1000, alow = {-6569.99276, -5.25394043, 4.32938426, 0.001097919189, -1.965726597e-006, 2.086472026e-009, -8.19598811e-013}, blow = {20162.24293, 1.413253322}, ahigh = {10916648.6, -34800.1064, 46.14311919999999, -0.02260951051, 5.68532437e-006, -6.458143299999999e-010, 2.696508992e-014}, bhigh = {239443.1755, -296.1780126}, R_s = R_NASA_2002/NaLi.MM);
          constant IdealGases.Common.DataRecord NaNO2(name = "NaNO2", MM = 0.06899527000000001, Hf = -2410205.496695643, H0 = 214612.1176132798, Tlimit = 1000, alow = {-69344.60610000001, 1115.43267, -1.816284973, 0.02916366016, -3.50578852e-005, 2.128602855e-008, -5.226211990000001e-012}, blow = {-27072.75053, 41.21853253}, ahigh = {-176555.7495, -863.521295, 10.6410594, -0.0002559465044, 5.65446563e-008, -6.48671032e-012, 3.008171243e-016}, bhigh = {-18684.35672, -29.21304474}, R_s = R_NASA_2002/NaNO2.MM);
          constant IdealGases.Common.DataRecord NaNO3(name = "NaNO3", MM = 0.08499466999999999, Hf = -3359371.958265148, H0 = 181202.997787979, Tlimit = 1000, alow = {-20438.52507, 691.709341, -2.397485012, 0.04100386430000001, -5.141702579999999e-005, 3.22862247e-008, -8.1646916e-012}, blow = {-39064.0132, 41.74749459}, ahigh = {-322559.219, -1396.782195, 14.03092409, -0.000409816177, 9.023845720000001e-008, -1.032543966e-011, 4.77867155e-016}, bhigh = {-31388.89875, -49.59121431}, R_s = R_NASA_2002/NaNO3.MM);
          constant IdealGases.Common.DataRecord NaO(name = "NaO", MM = 0.03898917, Hf = 2731664.126217614, H0 = 250149.387637644, Tlimit = 1000, alow = {18577.48013, -337.149732, 5.64456002, -0.003136926368, 6.33077539e-006, -5.42946247e-009, 1.68718377e-012}, blow = {13203.32678, -4.99613115}, ahigh = {256974.4011, -2269.334161, 9.22439762, -0.0036512691, 1.446811119e-006, -2.443068386e-010, 1.428508328e-014}, bhigh = {24132.39357, -29.89159486}, R_s = R_NASA_2002/NaO.MM);
          constant IdealGases.Common.DataRecord NaOH(name = "NaOH", MM = 0.03999711, Hf = -4775345.0186776, H0 = 284962.3635307651, Tlimit = 1000, alow = {34420.3674, -792.321818, 8.9979323, -0.00407984452, 3.065783937e-006, -5.11918934e-010, -1.541016409e-013}, blow = {-20869.51091, -25.1059009}, ahigh = {875378.776, -2342.514649, 7.97846989, 0.0001016451512, -6.26853195e-008, 1.022715136e-011, -5.71328641e-016}, bhigh = {-9509.90171, -22.02310401}, R_s = R_NASA_2002/NaOH.MM);
          constant IdealGases.Common.DataRecord NaOHplus(name = "NaOHplus", MM = 0.0399965614, Hf = 17098029.10707219, H0 = 292396.9109004455, Tlimit = 1000, alow = {22780.39363, -667.219422, 8.921593120000001, -0.004481263270000001, 3.95188392e-006, -1.173341234e-009, 2.041806631e-014}, blow = {83633.8219, -22.58912262}, ahigh = {881541.365, -2363.159755, 8.053203930000001, 7.27127974e-005, -5.89741789e-008, 1.007487881e-011, -5.47440621e-016}, bhigh = {95844.41650000001, -20.79484012}, R_s = R_NASA_2002/NaOHplus.MM);
          constant IdealGases.Common.DataRecord Na2(name = "Na2", MM = 0.04597954, Hf = 3095705.720413906, H0 = 226255.5258273571, Tlimit = 1000, alow = {6848.62868, -153.0836599, 5.32523039, -0.001944906088, 2.657477888e-006, -9.096841120000001e-010, -2.44875673e-013}, blow = {16491.70574, -2.653564394}, ahigh = {19299407.58, -62692.8012, 82.67682110000001, -0.0456513781, 1.259515667e-005, -1.560445735e-009, 7.02467717e-014}, bhigh = {409082.08, -550.997089}, R_s = R_NASA_2002/Na2.MM);
          constant IdealGases.Common.DataRecord Na2Br2(name = "Na2Br2", MM = 0.20578754, Hf = -2336625.691720694, H0 = 95202.78535814169, Tlimit = 1000, alow = {-13849.46731, -157.3241177, 10.63192589, -0.001383418339, 1.697156537e-006, -1.092992547e-009, 2.87098802e-013}, blow = {-60103.9182, -18.61473856}, ahigh = {-30217.30975, -2.65923278, 10.00225819, -9.935490630000001e-007, 2.358676253e-010, -2.857194816e-014, 1.381909879e-018}, bhigh = {-60900.3992, -14.94517863}, R_s = R_NASA_2002/Na2Br2.MM);
          constant IdealGases.Common.DataRecord Na2CL2(name = "Na2CL2", MM = 0.11688554, Hf = -4828670.706402178, H0 = 159979.8144406913, Tlimit = 1000, alow = {-10829.5525, -313.9528641, 11.24411332, -0.002697665795, 3.28635948e-006, -2.105377639e-009, 5.508056609999999e-013}, blow = {-69386.7543, -25.11011582}, ahigh = {-44121.0523, -5.39349128, 10.00453407, -1.981155641e-006, 4.6801882e-010, -5.64894068e-014, 2.724721177e-018}, bhigh = {-70980.6341, -17.87230397}, R_s = R_NASA_2002/Na2CL2.MM);
          constant IdealGases.Common.DataRecord Na2F2(name = "Na2F2", MM = 0.0839763464, Hf = -9932115.551052362, H0 = 198655.1060525777, Tlimit = 1000, alow = {23515.80802, -1000.737062, 13.75845076, -0.007838346979999999, 9.2762887e-006, -5.81361297e-009, 1.49535482e-012}, blow = {-98358.31880000001, -43.8114809}, ahigh = {-90307.50689999999, -18.93938035, 10.01535518, -6.53967545e-006, 1.516333603e-009, -1.804877459e-013, 8.61347492e-018}, bhigh = {-103489.6664, -21.78860202}, R_s = R_NASA_2002/Na2F2.MM);
          constant IdealGases.Common.DataRecord Na2I2(name = "Na2I2", MM = 0.29978848, Hf = -1190405.755417953, H0 = 67534.50966494776, Tlimit = 1000, alow = {-13050.63983, -89.9250668, 10.36367976, -0.0008000070190000001, 9.84877798e-007, -6.35937312e-010, 1.673774775e-013}, blow = {-45514.6549, -14.87509548}, ahigh = {-22312.36397, -1.515570558, 10.00129413, -5.71503538e-007, 1.360287207e-010, -1.650916036e-014, 7.996149680000001e-019}, bhigh = {-45969.2175, -12.76523965}, R_s = R_NASA_2002/Na2I2.MM);
          constant IdealGases.Common.DataRecord Na2O(name = "Na2O", MM = 0.06197894, Hf = -267184.7888976482, H0 = 232501.0721383747, Tlimit = 1000, alow = {39011.49290000001, -726.620789, 9.62371078, -0.00355641864, 3.47070435e-006, -1.835177736e-009, 4.06213471e-013}, blow = {-459.307325, -23.49565832}, ahigh = {-66005.2516, -25.69021634, 7.51938542, -7.81163524e-006, 1.73501589e-009, -1.996634558e-013, 9.27643355e-018}, bhigh = {-4297.33965, -10.63530214}, R_s = R_NASA_2002/Na2O.MM);
          constant IdealGases.Common.DataRecord Na2Oplus(name = "Na2Oplus", MM = 0.0619783914, Hf = 8403476.699461419, H0 = 235671.9442060253, Tlimit = 1000, alow = {26479.69755, -596.906216, 9.294129529999999, -0.003080702005, 3.080460653e-006, -1.669452593e-009, 3.78978414e-013}, blow = {63473.10249999999, -20.25274459}, ahigh = {-57409.0933, -19.89178143, 7.51529526, -6.25833323e-006, 1.407321045e-009, -1.635833952e-013, 7.66244513e-018}, bhigh = {60329.77469999999, -9.42652674}, R_s = R_NASA_2002/Na2Oplus.MM);
          constant IdealGases.Common.DataRecord Na2O2(name = "Na2O2", MM = 0.07797834000000001, Hf = -1589291.911061456, H0 = 199609.9814384353, Tlimit = 1000, alow = {73824.5892, -1355.12534, 12.55579861, -0.002112046045, 4.92035352e-008, 1.003950603e-009, -4.44773207e-013}, blow = {-10588.58918, -40.2181178}, ahigh = {-173229.5239, -113.7561118, 10.08529143, -3.42209894e-005, 7.577721890000001e-009, -8.70125673e-013, 4.03606139e-017}, bhigh = {-17803.00574, -23.8678919}, R_s = R_NASA_2002/Na2O2.MM);
          constant IdealGases.Common.DataRecord Na2O2H2(name = "Na2O2H2", MM = 0.07999422000000001, Hf = -7800563.59071943, H0 = 241844.2357460327, Tlimit = 1000, alow = {108941.4289, -2634.822704, 23.06608858, -0.01689310193, 1.67348319e-005, -7.821166009999999e-009, 1.47503447e-012}, blow = {-65931.37330000001, -98.0298758}, ahigh = {1675713.839, -4704.921170000001, 16.97343934, 0.0001961487616, -1.236951748e-007, 2.025311778e-011, -1.132991623e-015}, bhigh = {-48562.4557, -68.1348098}, R_s = R_NASA_2002/Na2O2H2.MM);
          constant IdealGases.Common.DataRecord Na2SO4(name = "Na2SO4", MM = 0.14204214, Hf = -7322702.276944011, H0 = 147644.1991087997, Tlimit = 1000, alow = {83442.8321, -1210.880769, 8.742353, 0.0360079663, -5.11764596e-005, 3.48156904e-008, -9.321931219999999e-012}, blow = {-121738.7045, -20.61505785}, ahigh = {-575448.311, -981.7060339999999, 19.73310397, -0.000293639552, 6.498708169999999e-008, -7.462479400000001e-012, 3.46249166e-016}, bhigh = {-127059.7762, -76.67871596000001}, R_s = R_NASA_2002/Na2SO4.MM);
          constant IdealGases.Common.DataRecord Na3CL3(name = "Na3CL3", MM = 0.17532831, Hf = -5205517.061106674, H0 = 168125.4841274635, Tlimit = 1000, alow = {-12542.1667, -550.216046, 18.16110649, -0.00465651526, 5.64643822e-006, -3.60476032e-009, 9.405556239999999e-013}, blow = {-111927.0172, -52.9010496}, ahigh = {-71602.9797, -9.57349381, 16.00799614, -3.47835697e-006, 8.190943689999999e-010, -9.86321003e-014, 4.74900535e-018}, bhigh = {-114725.2948, -40.31342160000001}, R_s = R_NASA_2002/Na3CL3.MM);
          constant IdealGases.Common.DataRecord Na3F3(name = "Na3F3", MM = 0.1259645196, Hf = -10701548.26359533, H0 = 203249.8840252791, Tlimit = 1000, alow = {52470.3035, -1775.597273, 22.50927609, -0.01333033615, 1.555790239e-005, -9.64601146e-009, 2.460254271e-012}, blow = {-158073.6389, -85.80122369999999}, ahigh = {-155399.5698, -35.5197019, 16.02841159, -1.198056094e-005, 2.75724873e-009, -3.26330097e-013, 1.550483212e-017}, bhigh = {-167214.1773, -47.5378068}, R_s = R_NASA_2002/Na3F3.MM);
          constant IdealGases.Common.DataRecord Nb(name = "Nb", MM = 0.09290638, Hf = 7783244.799765098, H0 = 89919.54050948923, Tlimit = 1000, alow = {78896.60669999999, -1212.813914, 10.34579819, -0.01676630056, 1.979119979e-005, -1.218224409e-008, 3.058098336e-012}, blow = {91653.1514, -35.9474285}, ahigh = {-1096553.196, 2546.650713, 2.236054882, -0.001280029198, 8.464237990000001e-007, -1.486269508e-010, 8.714309406000001e-015}, bhigh = {68791.24550000001, 13.9816903}, R_s = R_NASA_2002/Nb.MM);
          constant IdealGases.Common.DataRecord Nbplus(name = "Nbplus", MM = 0.0929058314, Hf = 15000185.17675092, H0 = 92449.25609696444, Tlimit = 1000, alow = {131444.7859, -2000.135035, 15.05024212, -0.02996583942, 3.72986863e-005, -2.269869569e-008, 5.449089902e-012}, blow = {176005.4029, -62.2459552}, ahigh = {-1077639.646, 2159.046421, 2.310604767, -0.0005363991760000001, 5.05791509e-007, -1.032401533e-010, 6.629241279999999e-015}, bhigh = {151794.5546, 12.10678502}, R_s = R_NASA_2002/Nbplus.MM);
          constant IdealGases.Common.DataRecord Nbminus(name = "Nbminus", MM = 0.09290692859999999, Hf = 6792324.507001301, H0 = 93144.91535134014, Tlimit = 1000, alow = {-72209.2485, 525.950125, 3.47046839, -0.00495050553, 7.40185903e-006, -5.01630207e-009, 1.314100719e-012}, blow = {71788.28870000001, 5.15551007}, ahigh = {111745.8019, 134.0072834, 2.391474129, 4.52481343e-005, -1.025345e-008, 1.195577988e-012, -5.606330449999999e-017}, bhigh = {74739.9675, 9.67531561}, R_s = R_NASA_2002/Nbminus.MM);
          constant IdealGases.Common.DataRecord NbCL5(name = "NbCL5", MM = 0.27017138, Hf = -2603273.522162118, H0 = 97505.37973341218, Tlimit = 1000, alow = {73482.7797, -1919.172996, 22.90799567, -0.01404352774, 1.638106985e-005, -1.018941843e-008, 2.612266639e-012}, blow = {-79741.1881, -84.39637087}, ahigh = {-156381.6638, -44.5052128, 16.0354463, -1.489949737e-005, 3.42077792e-009, -4.04112442e-013, 1.917266128e-017}, bhigh = {-89628.15120000001, -43.74582607}, R_s = R_NASA_2002/NbCL5.MM);
          constant IdealGases.Common.DataRecord NbO(name = "NbO", MM = 0.10890578, Hf = 1937350.855023489, H0 = 80621.12038497864, Tlimit = 1000, alow = {-6797.834360000001, 283.9767438, 0.56457084, 0.01134928619, -1.549821141e-005, 1.047624988e-008, -2.762937835e-012}, blow = {23179.93893, 23.65708974}, ahigh = {553225.878, -1287.669306, 4.98006604, 0.0001116014163, 4.03183868e-008, 1.04877371e-011, -1.893595022e-015}, bhigh = {32684.5779, -1.868958549}, R_s = R_NASA_2002/NbO.MM);
          constant IdealGases.Common.DataRecord NbOCL3(name = "NbOCL3", MM = 0.21526478, Hf = -3494765.841397743, H0 = 95840.10909727082, Tlimit = 1000, alow = {-110848.2359, 117.3066983, 11.65558433, 0.001287422064, -1.659778281e-006, 1.102107826e-009, -2.949903264e-013}, blow = {-95040.2392, -23.86450092}, ahigh = {-151555.1427, 53.0554523, 12.28915282, -0.0001527366571, 6.778576440000001e-008, -9.36517065e-012, 4.67003693e-016}, bhigh = {-94907.68120000001, -27.45263834}, R_s = R_NASA_2002/NbOCL3.MM);
          constant IdealGases.Common.DataRecord NbO2(name = "NbO2", MM = 0.12490518, Hf = -1611356.326454996, H0 = 85299.52080450147, Tlimit = 1000, alow = {17390.46582, 38.8102944, 0.902429912, 0.01909523319, -2.667013583e-005, 1.813901051e-008, -4.872365880000001e-012}, blow = {-25285.18558, 22.89323379}, ahigh = {-685185.99, 911.224932, 6.33919984, -8.2300803e-005, 1.984439605e-007, -3.26117149e-011, 1.602430854e-015}, bhigh = {-33250.2732, -3.55955655}, R_s = R_NASA_2002/NbO2.MM);
          constant IdealGases.Common.DataRecord Ne(name = "Ne", MM = 0.0201797, Hf = 0, H0 = 307111.9986917546, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {-745.375, 3.35532272}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {-745.375, 3.35532272}, R_s = R_NASA_2002/Ne.MM);
          constant IdealGases.Common.DataRecord Neplus(name = "Neplus", MM = 0.0201791514, Hf = 103421888.4942803, H0 = 312412.2454425909, Tlimit = 1000, alow = {72815.5148, -869.5697989999999, 6.10864697, -0.00584135693, 5.041044170000001e-006, -2.293759207e-009, 4.33906568e-013}, blow = {254599.689, -16.73449355}, ahigh = {-111274.2658, 476.569797, 2.196650531, 0.0001102593151, -2.287564425e-008, 2.510218183e-012, -1.126646096e-016}, bhigh = {247253.6944, 7.46614054}, R_s = R_NASA_2002/Neplus.MM);
          constant IdealGases.Common.DataRecord Ni(name = "Ni", MM = 0.0586934, Hf = 7328193.715136625, H0 = 116282.4610603577, Tlimit = 1000, alow = {-32358.1055, 601.526462, -1.079270657, 0.01089505519, -1.369578748e-005, 8.317725790000001e-009, -2.019206968e-012}, blow = {48138.1081, 27.188292}, ahigh = {-493826.221, 1092.909991, 2.410485014, -1.599071827e-005, -1.047414069e-008, 4.62479521e-012, -4.448865218e-017}, bhigh = {43360.7217, 9.677195599999999}, R_s = R_NASA_2002/Ni.MM);
          constant IdealGases.Common.DataRecord Niplus(name = "Niplus", MM = 0.0586928514, Hf = 19978490.48104008, H0 = 105733.0296956743, Tlimit = 1000, alow = {-89693.86030000002, 1173.6015, -3.41062041, 0.01390739137, -1.501714923e-005, 7.8963379e-009, -1.648686761e-012}, blow = {134558.95, 40.3149516}, ahigh = {-3961999.32, 10170.84853, -6.02933129, 0.002770858029, -8.9020777e-008, -5.54100058e-011, 5.235342833e-015}, bhigh = {73403.9512, 71.37503100000001}, R_s = R_NASA_2002/Niplus.MM);
          constant IdealGases.Common.DataRecord Niminus(name = "Niminus", MM = 0.0586939486, Hf = 5311695.062887626, H0 = 105754.6331105078, Tlimit = 1000, alow = {-84376.2475, 1135.476552, -3.38061583, 0.01423003786, -1.582586302e-005, 8.608840410000001e-009, -1.875316029e-012}, blow = {31243.0759, 39.980613}, ahigh = {-543342.48, 1182.64533, 2.12644124, 3.73045594e-005, 6.95360843e-009, -1.945719381e-012, 1.271571579e-016}, bhigh = {28547.59122, 10.43462235}, R_s = R_NASA_2002/Niminus.MM);
          constant IdealGases.Common.DataRecord NiCL(name = "NiCL", MM = 0.09414640000000001, Hf = 1933201.906817467, H0 = 100534.0724658617, Tlimit = 1000, alow = {-23579.97085, 220.549163, 2.714260287, 0.00445359847, -2.849162229e-006, -1.691898007e-010, 5.15669926e-013}, blow = {19572.2949, 14.23643068}, ahigh = {-3905769.19, 9961.53399, -3.83943234, 0.002767979391, -7.00595938e-008, -5.74140366e-011, 5.3076358e-015}, bhigh = {-45053.9705, 67.69402548000001}, R_s = R_NASA_2002/NiCL.MM);
          constant IdealGases.Common.DataRecord NiCL2(name = "NiCL2", MM = 0.1295994, Hf = -570457.8879223206, H0 = 109618.9179888179, Tlimit = 1000, alow = {71099.7653, -1218.958288, 12.08750596, -0.00867440314, 1.043608104e-005, -6.298493009999999e-009, 1.485857653e-012}, blow = {-5006.998710000001, -34.99472036}, ahigh = {158588.9817, -1161.488738, 9.608015379999999, -0.0009461224509999999, 2.608172043e-007, -3.26463725e-011, 1.525950893e-015}, bhigh = {-4578.98554, -22.12397347}, R_s = R_NASA_2002/NiCL2.MM);
          constant IdealGases.Common.DataRecord NiO(name = "NiO", MM = 0.0746928, Hf = 3977143.713985819, H0 = 118707.1444637234, Tlimit = 1000, alow = {23206.30462, -190.7136094, 3.19017862, 0.00529138349, -8.080210429999999e-006, 5.83981276e-009, -1.639499596e-012}, blow = {35767.1112, 7.84126567}, ahigh = {-72340.9194, -80.3555427, 4.55922102, 2.30515451e-005, 5.139832819999999e-009, -5.85347491e-013, 2.697077329e-017}, bhigh = {34611.4385, 1.209414814}, R_s = R_NASA_2002/NiO.MM);
          constant IdealGases.Common.DataRecord NiS(name = "NiS", MM = 0.09075839999999999, Hf = 3938136.85565193, H0 = 101572.1630174177, Tlimit = 1000, alow = {-12724.88974, 143.2801381, 2.471951556, 0.00550527112, -3.41835528e-006, -3.099052241e-010, 6.26815467e-013}, blow = {41177.1608, 15.17981835}, ahigh = {-735812.898, 1178.231095, 4.83786558, -0.000393120139, 1.341974852e-007, -1.569591708e-011, 6.67704506e-016}, bhigh = {32755.6594, 3.690652283}, R_s = R_NASA_2002/NiS.MM);
          constant IdealGases.Common.DataRecord O(name = "O", MM = 0.0159994, Hf = 15574021.71331425, H0 = 420353.4507544033, Tlimit = 1000, alow = {-7953.611300000001, 160.7177787, 1.966226438, 0.00101367031, -1.110415423e-006, 6.5175075e-010, -1.584779251e-013}, blow = {28403.62437, 8.404241819999999}, ahigh = {261902.0262, -729.872203, 3.31717727, -0.000428133436, 1.036104594e-007, -9.438304329999999e-012, 2.725038297e-016}, bhigh = {33924.2806, -0.667958535}, R_s = R_NASA_2002/O.MM);
          constant IdealGases.Common.DataRecord Oplus(name = "Oplus", MM = 0.0159988514, Hf = 98056240.96239808, H0 = 387367.0581126842, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {187935.2842, 4.39337676}, ahigh = {-216651.3208, 666.545615, 1.702064364, 0.000471499281, -1.427131823e-007, 2.016595903e-011, -9.107157761999999e-016}, bhigh = {183719.1966, 10.05690382}, R_s = R_NASA_2002/Oplus.MM);
          constant IdealGases.Common.DataRecord Ominus(name = "Ominus", MM = 0.0159999486, Hf = 6365407.448871429, H0 = 410675.8192960695, Tlimit = 1000, alow = {-5695.857110000001, 109.9287334, 2.184719661, 0.0005326359799999999, -5.298878440000001e-007, 2.870216236e-010, -6.52469274e-014}, blow = {10932.87498, 6.72986386}, ahigh = {9769.363179999999, 7.15960478, 2.494961726, 1.968240938e-006, -4.30417485e-010, 4.912083080000001e-014, -2.271600083e-018}, bhigh = {11495.54438, 4.83703644}, R_s = R_NASA_2002/Ominus.MM);
          constant IdealGases.Common.DataRecord OD(name = "OD", MM = 0.018013502, Hf = 1952535.825626799, H0 = 0, Tlimit = 1000, alow = {2.118691536e+004, -2.785982360e+002, 5.456210120e+000, -6.148119830e-003, 9.117670560e-006, -5.527812710e-009, 1.239794711e-012}, blow = {4.464878250e+003, -7.616618910e+000}, ahigh = {7.832473160e+005, -2.532992554e+003, 5.952124650e+000, -3.743595280e-004, 4.959527620e-008, 3.454454730e-012, -7.380626800e-016}, bhigh = {1.930492973e+004, -1.568898441e+001}, R_s = R_NASA_2002/OD.MM);
          constant IdealGases.Common.DataRecord ODminus(name = "ODminus", MM = 0.0180140506, Hf = -8191266.876978795, H0 = 0, Tlimit = 1000, alow = {5.606128320e+004, -7.514156150e+002, 7.544188470e+000, -1.092083064e-002, 1.503688938e-005, -9.351665840e-009, 2.246466046e-012}, blow = {-1.515707370e+004, -2.106498377e+001}, ahigh = {3.029467029e+005, -1.079684654e+003, 4.211417380e+000, 6.260830070e-004, -2.411665054e-007, 4.248425540e-011, -2.387099102e-015}, bhigh = {-1.188935343e+004, -4.724898790e+000}, R_s = R_NASA_2002/ODminus.MM);
          constant IdealGases.Common.DataRecord OH(name = "OH", MM = 0.01700734, Hf = 2191889.266634288, H0 = 518194.2620068747, Tlimit = 1000, alow = {-1998.85899, 93.0013616, 3.050854229, 0.001529529288, -3.157890998e-006, 3.31544618e-009, -1.138762683e-012}, blow = {2991.214235, 4.67411079}, ahigh = {1017393.379, -2509.957276, 5.11654786, 0.000130529993, -8.284322259999999e-008, 2.006475941e-011, -1.556993656e-015}, bhigh = {20196.40206, -11.01282337}, R_s = R_NASA_2002/OH.MM);
          constant IdealGases.Common.DataRecord OHplus(name = "OHplus", MM = 0.0170067914, Hf = 76393787.19021624, H0 = 505862.7931427441, Tlimit = 1000, alow = {60316.3086, -757.35203, 7.30775293, -0.00950688167, 1.202555795e-005, -6.8290261e-009, 1.501588659e-012}, blow = {158926.2158, -19.50106996}, ahigh = {504072.91, -1380.052958, 4.1254622, 0.000833194884, -3.44285629e-007, 6.792853949999999e-011, -4.36387213e-015}, bhigh = {164383.9235, -3.99705849}, R_s = R_NASA_2002/OHplus.MM);
          constant IdealGases.Common.DataRecord OHminus(name = "OHminus", MM = 0.0170078886, Hf = -8540519.015393833, H0 = 506006.6068400753, Tlimit = 1000, alow = {29108.80827, -321.690494, 4.85102905, -0.002579035357, 2.004980024e-006, -7.956852959999999e-011, -2.320495634e-013}, blow = {-16888.86234, -7.1215913}, ahigh = {471133.117, -857.233669, 3.16618121, 0.001233581296, -3.99924458e-007, 6.23908167e-011, -3.35434322e-015}, bhigh = {-12248.49139, 1.48773626}, R_s = R_NASA_2002/OHminus.MM);
          constant IdealGases.Common.DataRecord O2(name = "O2", MM = 0.0319988, Hf = 0, H0 = 271263.4223783392, Tlimit = 1000, alow = {-34255.6342, 484.700097, 1.119010961, 0.00429388924, -6.83630052e-007, -2.0233727e-009, 1.039040018e-012}, blow = {-3391.45487, 18.4969947}, ahigh = {-1037939.022, 2344.830282, 1.819732036, 0.001267847582, -2.188067988e-007, 2.053719572e-011, -8.193467050000001e-016}, bhigh = {-16890.10929, 17.38716506}, R_s = R_NASA_2002/O2.MM);
          constant IdealGases.Common.DataRecord O2plus(name = "O2plus", MM = 0.0319982514, Hf = 36621639.76872811, H0 = 290988.1506837588, Tlimit = 1000, alow = {-86072.0545, 1051.875934, -0.543238047, 0.00657116654, -3.27426375e-006, 5.940645339999999e-011, 3.23878479e-013}, blow = {134554.4668, 29.0270975}, ahigh = {73846.5488, -845.955954, 4.98516416, -0.000161101089, 6.42708399e-008, -1.504939874e-011, 1.578465409e-015}, bhigh = {144632.1044, -5.81123065}, R_s = R_NASA_2002/O2plus.MM);
          constant IdealGases.Common.DataRecord O2minus(name = "O2minus", MM = 0.0319993486, Hf = -1500903.084008404, H0 = 292181.2914654145, Tlimit = 1000, alow = {18838.74344, 114.9551768, 1.518876821, 0.00801611138, -9.850571029999999e-006, 6.04419621e-009, -1.486439845e-012}, blow = {-7101.53876, 15.0121038}, ahigh = {-56552.0805, -236.7815862, 4.67583367, -2.1972453e-005, 1.71150928e-008, -1.757645062e-012, 8.24817279e-017}, bhigh = {-5960.17775, -2.436885556}, R_s = R_NASA_2002/O2minus.MM);
          constant IdealGases.Common.DataRecord O3(name = "O3", MM = 0.0479982, Hf = 2954277.45207112, H0 = 215972.786479493, Tlimit = 1000, alow = {-12823.14507, 589.8216640000001, -2.547496763, 0.02690121526, -3.52825834e-005, 2.312290922e-008, -6.04489327e-012}, blow = {13483.68701, 38.5221858}, ahigh = {-38696624.8, 102334.4994, -89.615516, 0.0370614497, -4.13763874e-006, -2.725018591e-010, 5.24818811e-014}, bhigh = {-651791.818, 702.9109520000001}, R_s = R_NASA_2002/O3.MM);
          constant IdealGases.Common.DataRecord P(name = "P", MM = 0.030973761, Hf = 10218326.40860114, H0 = 200086.389250566, Tlimit = 1000, alow = {50.4086657, -0.7639418649999999, 2.504563992, -1.381689958e-005, 2.245585515e-008, -1.866399889e-011, 6.227063395e-015}, blow = {37324.2191, 5.359303481}, ahigh = {1261794.642, -4559.83819, 8.91807931, -0.00438140146, 1.454286224e-006, -2.030782763e-010, 1.021022887e-014}, bhigh = {65417.23959999999, -39.15974795}, R_s = R_NASA_2002/P.MM);
          constant IdealGases.Common.DataRecord Pplus(name = "Pplus", MM = 0.0309732124, Hf = 43148687.41222335, H0 = 262867.7934614235, Tlimit = 1000, alow = {-73169.0811, 962.7979140000001, -0.369393805, 0.004766778340000001, -4.57476858e-006, 2.371262331e-009, -5.131314899999999e-013}, blow = {154940.6849, 23.76640762}, ahigh = {-559424.936, 1722.576545, 0.8430381089999999, 0.0006287368940000001, -6.317195459999999e-008, -1.810842484e-012, 4.31811257e-016}, bhigh = {149049.3431, 18.45275207}, R_s = R_NASA_2002/Pplus.MM);
          constant IdealGases.Common.DataRecord Pminus(name = "Pminus", MM = 0.0309743096, Hf = 7710479.041637784, H0 = 217853.6047176335, Tlimit = 1000, alow = {-10089.49093, 182.6468403, 1.962456304, 0.0009197377539999999, -9.21499863e-007, 5.012872360000001e-010, -1.142677121e-013}, blow = {27030.82432, 9.478137822000001}, ahigh = {15434.88016, 9.495009339999999, 2.493170861, 2.700167711e-006, -5.94921039e-010, 6.82376629e-014, -3.16695991e-018}, bhigh = {27975.72693, 6.246793872}, R_s = R_NASA_2002/Pminus.MM);
          constant IdealGases.Common.DataRecord PCL(name = "PCL", MM = 0.066426761, Hf = 2026519.28189002, H0 = 139870.0141348153, Tlimit = 1000, alow = {34888.617, -560.3119340000001, 6.26456848, -0.00318336437, 3.49532684e-006, -2.091034291e-009, 5.4187586e-013}, blow = {17746.53764, -8.074572148}, ahigh = {-347168.151, 993.555793, 3.39943027, 0.00040197117, 8.295588390000001e-008, -3.090212484e-011, 2.106384858e-015}, bhigh = {8433.59115, 10.64902238}, R_s = R_NASA_2002/PCL.MM);
          constant IdealGases.Common.DataRecord PCL2(name = "PCL2", MM = 0.101879761, Hf = -532906.1676931104, H0 = 120227.5788613207, Tlimit = 1000, alow = {51900.845, -1060.9042, 10.5854994, -0.00687991753, 7.62077318e-006, -4.53011547e-009, 1.11667166e-012}, blow = {-3220.33118, -27.53518359}, ahigh = {-83498.33970000001, -26.2524947, 7.02036181, -8.388768680000001e-006, 1.89678474e-009, -2.21487992e-013, 1.04165355e-017}, bhigh = {-8742.99368, -6.23402319}, R_s = R_NASA_2002/PCL2.MM);
          constant IdealGases.Common.DataRecord PCL2minus(name = "PCL2minus", MM = 0.1018803096, Hf = -3497096.292687356, H0 = 122234.0906588686, Tlimit = 1000, alow = {49348.3277, -960.159054, 9.8847697, -0.00495020295, 4.94621787e-006, -2.678675201e-009, 6.07672361e-013}, blow = {-39980.724, -24.13131695}, ahigh = {-85649.8676, -31.8555594, 7.02449496, -1.002251172e-005, 2.253747944e-009, -2.619657192e-013, 1.227059658e-017}, bhigh = {-45038.1143, -6.721522361}, R_s = R_NASA_2002/PCL2minus.MM);
          constant IdealGases.Common.DataRecord PCL3(name = "PCL3", MM = 0.137332761, Hf = -2108018.493853772, H0 = 116013.585425549, Tlimit = 1000, alow = {77177.4547, -1617.65086, 15.3608047, -0.0101107705, 1.10340834e-005, -6.47612102e-009, 1.57915114e-012}, blow = {-29558.9364, -52.44338688}, ahigh = {-133307.693, -41.4588321, 10.0318606, -1.30194616e-005, 2.92291689e-009, -3.39186924e-013, 1.58642553e-017}, bhigh = {-38003.3668, -20.50737678}, R_s = R_NASA_2002/PCL3.MM);
          constant IdealGases.Common.DataRecord PCL5(name = "PCL5", MM = 0.208238761, Hf = -1805619.6559871, H0 = 111917.0412274975, Tlimit = 1000, alow = {102907.02, -2515.70746, 24.3011497, -0.0156461069, 1.70987303e-005, -1.00601143e-008, 2.46015879e-012}, blow = {-37225.8237, -98.16335170000001}, ahigh = {-225590.689, -69.38542820000001, 16.0535963, -2.20215696e-005, 4.97139229e-009, -5.79986005e-013, 2.72597077e-017}, bhigh = {-50342.3422, -48.7245487}, R_s = R_NASA_2002/PCL5.MM);
          constant IdealGases.Common.DataRecord PF(name = "PF", MM = 0.0499721642, Hf = -959429.9900263273, H0 = 177921.1915740883, Tlimit = 1000, alow = {22278.66728, -172.7508706, 3.085366934, 0.00548971823, -8.247972539999999e-006, 5.86888291e-009, -1.617252113e-012}, blow = {-5809.27965, 7.70971885}, ahigh = {-1132572.282, 3200.03855, 0.778050237, 0.001969518902, -4.36581897e-007, 5.243648570000001e-011, -2.618755712e-015}, bhigh = {-27667.73009, 27.59312302}, R_s = R_NASA_2002/PF.MM);
          constant IdealGases.Common.DataRecord PFplus(name = "PFplus", MM = 0.0499716156, Hf = 18040601.43294627, H0 = 188704.0850446308, Tlimit = 1000, alow = {-17791.38157, 390.999127, 1.257434156, 0.007861363749999999, -9.34231268e-006, 5.630915650000001e-009, -1.370669924e-012}, blow = {105487.3882, 19.01676576}, ahigh = {-40115.2518, -159.7504413, 4.62139748, -2.378072183e-005, 1.431831329e-008, -2.300109157e-012, 1.694069882e-016}, bhigh = {107863.3756, -0.04072343949999999}, R_s = R_NASA_2002/PFplus.MM);
          constant IdealGases.Common.DataRecord PFminus(name = "PFminus", MM = 0.0499727128, Hf = -3282711.520115834, H0 = 190416.7788145374, Tlimit = 1000, alow = {7705.21095, -115.2432706, 4.25495231, 0.001163521526, -1.627947259e-006, 1.084382815e-009, -2.809490132e-013}, blow = {-20355.58966, 2.217923793}, ahigh = {-130379.3388, 271.5526386, 4.13761981, 0.0002728610614, -7.64441625e-008, 1.182073001e-011, -6.083906640000001e-016}, bhigh = {-22907.99827, 3.7485261}, R_s = R_NASA_2002/PFminus.MM);
          constant IdealGases.Common.DataRecord PFCL(name = "PFCL", MM = 0.0854251642, Hf = -3314996.484373161, H0 = 136147.0136922488, Tlimit = 1000, alow = {54901.8853, -865.867948, 7.94446765, 0.0009503779099999999, -3.33909021e-006, 3.023977817e-009, -9.45037754e-013}, blow = {-31328.43217, -14.40426886}, ahigh = {-128214.3211, -97.3904355, 7.07266166, -2.903614134e-005, 6.408504490000001e-009, -7.33899377e-013, 3.39672317e-017}, bhigh = {-36006.4926, -7.626493035}, R_s = R_NASA_2002/PFCL.MM);
          constant IdealGases.Common.DataRecord PFCLminus(name = "PFCLminus", MM = 0.0854257128, Hf = -6195665.094877616, H0 = 137462.042927197, Tlimit = 1000, alow = {89343.3685, -1266.972513, 9.912194530000001, -0.0038779283, 3.036692411e-006, -1.29655938e-009, 2.32422658e-013}, blow = {-58945.0571, -26.1705046}, ahigh = {-123156.515, -97.6586111, 7.07402957, -2.997070692e-005, 6.685280620000001e-009, -7.7222622e-013, 3.5993823e-017}, bhigh = {-65588.1722, -8.208878059}, R_s = R_NASA_2002/PFCLminus.MM);
          constant IdealGases.Common.DataRecord PFCL2(name = "PFCL2", MM = 0.1208781642, Hf = -4235052.239484623, H0 = 122997.8970842114, Tlimit = 1000, alow = {82665.60560000001, -1512.138928, 13.03404207, -0.002903247162, 7.83665297e-007, 6.45834066e-010, -3.73764182e-013}, blow = {-56442.3787, -41.00905668}, ahigh = {-186458.9813, -114.8004379, 10.08599754, -3.44745652e-005, 7.62797201e-009, -8.75309743e-013, 4.05778835e-017}, bhigh = {-64504.7219, -21.74054563}, R_s = R_NASA_2002/PFCL2.MM);
          constant IdealGases.Common.DataRecord PFCL4(name = "PFCL4", MM = 0.1917841642, Hf = -3311099.44686455, H0 = 113324.5807372035, Tlimit = 1000, alow = {141207.1573, -2882.47108, 23.87345233, -0.01239510207, 1.141290085e-005, -5.705483820000001e-009, 1.195229703e-012}, blow = {-66134.7865, -98.5969355}, ahigh = {-295437.588, -132.5154294, 16.1000538, -4.03535917e-005, 8.971130739999999e-009, -1.03328881e-012, 4.80446835e-017}, bhigh = {-81357.19399999999, -50.62403920000001}, R_s = R_NASA_2002/PFCL4.MM);
          constant IdealGases.Common.DataRecord PF2(name = "PF2", MM = 0.06897056739999999, Hf = -7439458.284056397, H0 = 160669.2161271099, Tlimit = 1000, alow = {55247.6572, -628.05178, 5.13743792, 0.009120673350000001, -1.46877376e-005, 1.08126845e-008, -3.06494449e-012}, blow = {-59775.4147, -1.689589472}, ahigh = {-170846.712, -169.205154, 7.1254916, -4.990852849999999e-005, 1.09733523e-008, -1.25287026e-012, 5.78479114e-017}, bhigh = {-63382.9584, -10.41715673}, R_s = R_NASA_2002/PF2.MM);
          constant IdealGases.Common.DataRecord PF2minus(name = "PF2minus", MM = 0.068971116, Hf = -10284565.30991901, H0 = 160133.0185812856, Tlimit = 1000, alow = {140479.3057, -1699.945753, 10.36823971, -0.00359958769, 1.9619258e-006, -3.82932987e-010, -3.37554952e-014}, blow = {-78104.34510000001, -32.17375182}, ahigh = {-165397.6056, -164.0604822, 7.12409152, -5.0154314e-005, 1.117302152e-008, -1.289308601e-012, 6.00470667e-017}, bhigh = {-87002.23319999999, -11.09074866}, R_s = R_NASA_2002/PF2minus.MM);
          constant IdealGases.Common.DataRecord PF2CL(name = "PF2CL", MM = 0.1044235674, Hf = -7039375.308681516, H0 = 132884.9257452202, Tlimit = 1000, alow = {83975.9016, -1318.075883, 10.17203515, 0.005571231219999999, -1.100920478e-005, 8.72638318e-009, -2.567714099e-012}, blow = {-83816.56169999999, -27.66012951}, ahigh = {-240928.1185, -203.348467, 10.15150769, -6.04836731e-005, 1.333942001e-008, -1.526772528e-012, 7.063339179999999e-017}, bhigh = {-91011.1059, -24.17825549}, R_s = R_NASA_2002/PF2CL.MM);
          constant IdealGases.Common.DataRecord PF2CL3(name = "PF2CL3", MM = 0.1753295674, Hf = -5011961.045881188, H0 = 115013.3334555869, Tlimit = 1000, alow = {184209.9543, -3334.40239, 23.88510873, -0.01030943175, 7.356504219999999e-006, -2.498621785e-009, 2.513997646e-013}, blow = {-92795.49890000001, -102.7991502}, ahigh = {-365527.254, -202.969416, 16.15238015, -6.11879657e-005, 1.355610375e-008, -1.55712964e-012, 7.22435997e-017}, bhigh = {-110494.1533, -53.87308191}, R_s = R_NASA_2002/PF2CL3.MM);
          constant IdealGases.Common.DataRecord PF3(name = "PF3", MM = 0.0879689706, Hf = -10883383.00959952, H0 = 147057.4557342837, Tlimit = 1000, alow = {84809.84480000001, -1102.340691, 7.16071511, 0.01438278338, -2.318137222e-005, 1.702244315e-008, -4.81099195e-012}, blow = {-111183.7495, -14.57652362}, ahigh = {-295704.0675, -299.7689931, 10.22297023, -8.890263450000001e-005, 1.958901359e-008, -2.240491075e-012, 1.035952523e-016}, bhigh = {-117374.3464, -27.77419177}, R_s = R_NASA_2002/PF3.MM);
          constant IdealGases.Common.DataRecord PF3CL2(name = "PF3CL2", MM = 0.1588749706, Hf = -7062301.328916815, H0 = 119887.8837117469, Tlimit = 1000, alow = {182249.7206, -3089.610245, 20.67710388, -0.001168732391, -5.02054074e-006, 5.80457335e-009, -1.965367906e-012}, blow = {-122812.0667, -86.27977355}, ahigh = {-422383.8050000001, -320.796522, 16.24013, -9.62365531e-005, 2.129279712e-008, -2.443515401e-012, 1.13290435e-016}, bhigh = {-139264.2151, -55.31285745}, R_s = R_NASA_2002/PF3CL2.MM);
          constant IdealGases.Common.DataRecord PF4CL(name = "PF4CL", MM = 0.1424203738, Hf = -9583666.708505718, H0 = 128637.5292465354, Tlimit = 1000, alow = {180424.0323, -2741.096618, 16.80192838, 0.00991931525, -2.025636171e-005, 1.617979147e-008, -4.77261152e-012}, blow = {-153238.2587, -66.79119965}, ahigh = {-478114.004, -426.481283, 16.31812121, -0.0001271374903, 2.806715254e-008, -3.2151663e-012, 1.488512118e-016}, bhigh = {-168048.8362, -57.35844805}, R_s = R_NASA_2002/PF4CL.MM);
          constant IdealGases.Common.DataRecord PF5(name = "PF5", MM = 0.125965777, Hf = -12648673.61553289, H0 = 131286.5239580112, Tlimit = 1000, alow = {185577.8473, -2436.979828, 12.01012406, 0.02339343049, -3.81394441e-005, 2.796136412e-008, -7.87070488e-012}, blow = {-181456.6568, -44.8648874}, ahigh = {-566872.784, -667.791791, 16.49789569, -0.000199009944, 4.3950071e-008, -5.03684954e-012, 2.332945909e-016}, bhigh = {-194432.1623, -62.61721040000001}, R_s = R_NASA_2002/PF5.MM);
          constant IdealGases.Common.DataRecord PH(name = "PH", MM = 0.031981701, Hf = 7215129.176525038, H0 = 270407.881056733, Tlimit = 1000, alow = {22736.33198, -397.267406, 6.23369766, -0.0091817846, 1.523328123e-005, -1.085888585e-008, 2.929760547e-012}, blow = {28527.68404, -10.95191197}, ahigh = {781473.0649999999, -3038.451204, 7.46748102, -0.001837522255, 7.1659477e-007, -1.142128853e-010, 6.175410560000001e-015}, bhigh = {45362.6018, -24.6729814}, R_s = R_NASA_2002/PH.MM);
          constant IdealGases.Common.DataRecord PH2(name = "PH2", MM = 0.032989641, Hf = 3623970.021377317, H0 = 302566.8269624395, Tlimit = 1000, alow = {15552.68372, -184.1602025, 4.89589604, -0.0034954366, 1.053418945e-005, -8.377562920000002e-009, 2.27076615e-012}, blow = {14098.39468, -2.210564792}, ahigh = {1127884.913, -4715.238249999999, 10.214983, -0.00116757382, 2.150542671e-007, -1.624213739e-011, 3.76622524e-016}, bhigh = {41830.7463, -42.3162325}, R_s = R_NASA_2002/PH2.MM);
          constant IdealGases.Common.DataRecord PH2minus(name = "PH2minus", MM = 0.0329901896, Hf = -280853.735984591, H0 = 301910.4200601502, Tlimit = 1000, alow = {69506.84490000001, -771.916291, 7.38353762, -0.00852294721, 1.474476507e-005, -9.84716081e-009, 2.413107871e-012}, blow = {1582.29585, -17.61306419}, ahigh = {1382525.815, -5213.40067, 10.21694832, -0.001116316349, 2.215004171e-007, -2.338005187e-011, 1.015580932e-015}, bhigh = {29906.83733, -43.78711584999999}, R_s = R_NASA_2002/PH2minus.MM);
          constant IdealGases.Common.DataRecord PH3(name = "PH3", MM = 0.033997581, Hf = 159981.9704819587, H0 = 298157.1541810578, Tlimit = 1000, alow = {-6384.32534, 405.756741, -0.1565680086, 0.01338380613, -8.27539143e-006, 3.024360831e-009, -6.421764630000001e-013}, blow = {-2159.842124, 23.85561888}, ahigh = {1334801.106, -6725.46352, 14.45857073, -0.001639736883, 3.40921857e-007, -3.73627208e-011, 1.672947506e-015}, bhigh = {39103.2571, -71.9878119}, R_s = R_NASA_2002/PH3.MM);
          constant IdealGases.Common.DataRecord PN(name = "PN", MM = 0.044980461, Hf = 3812484.380718108, H0 = 193464.1132290752, Tlimit = 1000, alow = {-51032.0384, 820.2926679999999, -1.392772765, 0.01287989789, -1.401425371e-005, 7.775633459999999e-009, -1.75153933e-012}, blow = {15732.2652, 32.51070633}, ahigh = {-249562.5593, 176.043883, 4.14412196, 0.0002478018097, -5.674896300000001e-008, 4.263645119999999e-012, 3.063920924e-016}, bhigh = {17703.17267, 1.325517397}, R_s = R_NASA_2002/PN.MM);
          constant IdealGases.Common.DataRecord PO(name = "PO", MM = 0.046973161, Hf = -593055.4045532512, H0 = 199903.7918695742, Tlimit = 1000, alow = {-68457.54059999999, 1141.295708, -2.77955606, 0.01678458047, -1.974879516e-005, 1.19260232e-008, -2.927460912e-012}, blow = {-9847.74504, 41.84328297}, ahigh = {-336666.744, 622.9355840000001, 3.56560546, 0.0006516620719999999, -2.061770841e-007, 3.18441323e-011, -1.573691908e-015}, bhigh = {-8939.79039, 6.954859188}, R_s = R_NASA_2002/PO.MM);
          constant IdealGases.Common.DataRecord POminus(name = "POminus", MM = 0.0469737096, Hf = -2981818.876829775, H0 = 186872.743812424, Tlimit = 1000, alow = {54343.46320000001, -412.362355, 3.74648388, 0.00385863647, -5.96334304e-006, 4.278286360000001e-009, -1.139722989e-012}, blow = {-15558.10937, 3.404436468}, ahigh = {-848.0294779999999, 347.054487, 2.877890167, 0.001622182445, -4.87019099e-007, 6.64575227e-011, -3.39570376e-015}, bhigh = {-19872.0954, 10.75444355}, R_s = R_NASA_2002/POminus.MM);
          constant IdealGases.Common.DataRecord POCL3(name = "POCL3", MM = 0.153332161, Hf = -3706984.864056015, H0 = 115539.7268548246, Tlimit = 1000, alow = {47937.8816, -1270.38828, 13.6771646, 0.0010826721, -1.73610406e-006, 8.460890640000001e-010, -1.17466133e-013}, blow = {-65075.7188, -43.14705941}, ahigh = {-218593.797, -508.026968, 13.3778465, -0.000151073105, 3.34098678e-008, -3.83532976e-012, 1.77932988e-016}, bhigh = {-70093.15090000001, -39.84746301}, R_s = R_NASA_2002/POCL3.MM);
          constant IdealGases.Common.DataRecord POFCL2(name = "POFCL2", MM = 0.1368775642, Hf = -5799995.906122357, H0 = 120210.9936436172, Tlimit = 1000, alow = {46940.6156, -1069.2426, 10.71284279, 0.009491183299999999, -1.306412424e-005, 8.426906020000001e-009, -2.140294969e-012}, blow = {-92748.94989999999, -28.15077719}, ahigh = {-270764.7503, -655.650227, 13.48668421, -0.0001942765035, 4.29118449e-008, -4.9218448e-012, 2.282079808e-016}, bhigh = {-96543.92140000001, -41.64963494}, R_s = R_NASA_2002/POFCL2.MM);
          constant IdealGases.Common.DataRecord POF2CL(name = "POF2CL", MM = 0.1204229674, Hf = -8491794.06618741, H0 = 123700.323298959, Tlimit = 1000, alow = {52264.3816, -969.1037700000001, 7.96363598, 0.01755599796, -2.398693997e-005, 1.572376747e-008, -4.079746e-012}, blow = {-120265.6893, -15.93967075}, ahigh = {-334708.659, -817.6104810000001, 13.6066432, -0.0002420426112, 5.34371272e-008, -6.126461349999999e-012, 2.839570116e-016}, bhigh = {-123340.1194, -44.96103437000001}, R_s = R_NASA_2002/POF2CL.MM);
          constant IdealGases.Common.DataRecord POF3(name = "POF3", MM = 0.1039683706, Hf = -12042123.89570718, H0 = 136256.3337123223, Tlimit = 1000, alow = {29660.3071, -427.670575, 3.6691461, 0.0283949378, -3.768318e-005, 2.44910454e-008, -6.34197287e-012}, blow = {-150112.453, 5.160417996}, ahigh = {-369060.242, -1005.55254, 13.7452994, -0.000297103711, 6.55452664e-008, -7.50998733e-012, 3.47896991e-016}, bhigh = {-149976.173, -48.82214181000001}, R_s = R_NASA_2002/POF3.MM);
          constant IdealGases.Common.DataRecord PO2(name = "PO2", MM = 0.062972561, Hf = -4470633.439856448, H0 = 166943.5994511959, Tlimit = 1000, alow = {-63726.9822, 1036.741044, -2.877797967, 0.02278134083, -2.567920328e-005, 1.465060412e-008, -3.3879967e-012}, blow = {-39935.4472, 44.2530938}, ahigh = {492621.0990000001, -2605.465745, 9.51760561, -0.001180371565, 2.532912819e-007, -1.789964539e-011, 1.800381054e-016}, bhigh = {-20288.84763, -29.69743125}, R_s = R_NASA_2002/PO2.MM);
          constant IdealGases.Common.DataRecord PO2minus(name = "PO2minus", MM = 0.06297310960000001, Hf = -9490141.979585521, H0 = 168544.1463414727, Tlimit = 1000, alow = {27024.23135, 29.39956284, 1.162686114, 0.01599897972, -1.979229263e-005, 1.208847527e-008, -2.95664048e-012}, blow = {-72859.4627, 19.63118182}, ahigh = {1628679.152, -5989.19998, 13.69318836, -0.00362384379, 9.488198340000001e-007, -1.040308759e-010, 4.01903366e-015}, bhigh = {-36859.595, -59.5679622}, R_s = R_NASA_2002/PO2minus.MM);
          constant IdealGases.Common.DataRecord PS(name = "PS", MM = 0.063038761, Hf = 2386330.467377048, H0 = 152542.9092745018, Tlimit = 1000, alow = {-768.9786800000001, -46.3782407, 4.10464917, 0.001555262273, -2.315757288e-006, 1.661425178e-009, -4.6312384e-013}, blow = {17078.75808, 4.230652171}, ahigh = {-270272.9081, 888.354822, 3.16919012, 0.001022480817, -3.80374048e-007, 7.019861879999999e-011, -4.26912231e-015}, bhigh = {11215.10462, 11.47334049}, R_s = R_NASA_2002/PS.MM);
          constant IdealGases.Common.DataRecord P2(name = "P2", MM = 0.061947522, Hf = 2324548.187738647, H0 = 143736.2902102848, Tlimit = 1000, alow = {30539.2251, -324.617759, 4.02246381, 0.00323209479, -5.511052450000001e-006, 4.19557293e-009, -1.21503218e-012}, blow = {17969.1087, 1.645350331}, ahigh = {-780693.649, 2307.91087, 1.41174313, 0.00210823742, -7.36085662e-007, 1.25936012e-010, -7.07975249e-015}, bhigh = {1329.82474, 21.69741365}, R_s = R_NASA_2002/P2.MM);
          constant IdealGases.Common.DataRecord P2O3(name = "P2O3", MM = 0.109945722, Hf = -6227120.633215725, H0 = 146389.3338205556, Tlimit = 1000, alow = {-66457.5389, 758.090055, 0.988843677, 0.0285987873, -3.23114211e-005, 1.83452517e-008, -4.2124893e-012}, blow = {-88200.3674, 26.89914458}, ahigh = {-217534.411, -1369.902, 14.0114296, -0.000402385696, 8.86834578e-008, -1.01565728e-011, 4.70435606e-016}, bhigh = {-79227.56999999999, -47.39487232000001}, R_s = R_NASA_2002/P2O3.MM);
          constant IdealGases.Common.DataRecord P2O4(name = "P2O4", MM = 0.125945122, Hf = -7413980.090471467, H0 = 137564.5179810934, Tlimit = 1000, alow = {-43760.9126, 490.510283, 0.964364937, 0.0388607358, -4.67550922e-005, 2.81262563e-008, -6.8244061e-012}, blow = {-116899.779, 23.79582767}, ahigh = {-367011.486, -1638.42373, 17.2118861, -0.000482658015, 1.0644619e-007, -1.21961007e-011, 5.65065458e-016}, bhigh = {-109043.593, -67.14276593}, R_s = R_NASA_2002/P2O4.MM);
          constant IdealGases.Common.DataRecord P2O5(name = "P2O5", MM = 0.141944522, Hf = -7921195.817616688, H0 = 155341.7116019454, Tlimit = 1000, alow = {-29991.5922, -45.9450659, 6.98748683, 0.0288330297, -3.10450953e-005, 1.64386868e-008, -3.4679423e-012}, blow = {-138190.14, -3.400572711}, ahigh = {-324708.016, -2016.97508, 20.4869934, -0.000591064115, 1.30199302e-007, -1.49068294e-011, 6.90357341e-016}, bhigh = {-130629.016, -80.31642952}, R_s = R_NASA_2002/P2O5.MM);
          constant IdealGases.Common.DataRecord P3(name = "P3", MM = 0.09292128300000001, Hf = 2259977.404745907, H0 = 129201.8535732013, Tlimit = 1000, alow = {46933.5895, -864.358932, 8.734247529999999, 1.09453456e-005, -1.99857332e-006, 2.09675051e-009, -6.92288971e-013}, blow = {27748.4734, -20.63587261}, ahigh = {-125351.306, -83.0673462, 7.56195677, -2.47440395e-005, 5.45727693e-009, -6.24466057e-013, 2.88772422e-017}, bhigh = {23087.2228, -12.28310621}, R_s = R_NASA_2002/P3.MM);
          constant IdealGases.Common.DataRecord P3O6(name = "P3O6", MM = 0.188917683, Hf = -8340569.310285264, H0 = 124071.403098883, Tlimit = 1000, alow = {201449.3813, -3053.488073, 16.02114098, 0.043168899, -6.37654426e-005, 4.42286792e-008, -1.200020334e-011}, blow = {-177650.3811, -65.5626789}, ahigh = {-878796.8100000001, -1651.988071, 27.72258397, -0.00048593267, 1.067867708e-007, -1.218015776e-011, 5.61491196e-016}, bhigh = {-190916.5548, -122.0665277}, R_s = R_NASA_2002/P3O6.MM);
          constant IdealGases.Common.DataRecord P4(name = "P4", MM = 0.123895044, Hf = 475402.3897840498, H0 = 113875.8060411198, Tlimit = 1000, alow = {120514.185, -2345.71179, 17.7394655, -0.0145631497, 1.58759409e-005, -9.314710310000001e-009, 2.27149167e-012}, blow = {16088.4648, -70.88590647000001}, ahigh = {-185870.586, -62.8454689, 10.0484488, -1.98766885e-005, 4.482408440000001e-009, -5.22610367e-013, 2.45579129e-017}, bhigh = {3848.21092, -24.77297797}, R_s = R_NASA_2002/P4.MM);
          constant IdealGases.Common.DataRecord P4O6(name = "P4O6", MM = 0.219891444, Hf = -7303603.863731961, H0 = 112771.659273837, Tlimit = 1000, alow = {376089.475, -5685.83262, 29.1422545, 0.0225153212, -4.51026963e-005, 3.58831269e-008, -1.05757206e-011}, blow = {-168856.248, -145.1359851}, ahigh = {-1008997.24, -887.275399, 28.6606483, -0.000263601894, 5.81094072e-008, -6.64808696e-012, 3.07439193e-016}, bhigh = {-199713.89, -128.1853821}, R_s = R_NASA_2002/P4O6.MM);
          constant IdealGases.Common.DataRecord P4O7(name = "P4O7", MM = 0.235890844, Hf = -8412569.183906095, H0 = 111798.8157268198, Tlimit = 1000, alow = {321858.696, -4871.44473, 24.54417068, 0.0401550955, -6.52419715e-005, 4.75655418e-008, -1.332975491e-011}, blow = {-218451.7427, -118.1504792}, ahigh = {-1102947.375, -1511.077128, 32.109795, -0.000437180376, 9.516639610000001e-008, -1.075204176e-011, 4.91102568e-016}, bhigh = {-242909.654, -147.3140859}, R_s = R_NASA_2002/P4O7.MM);
          constant IdealGases.Common.DataRecord P4O8(name = "P4O8", MM = 0.251890244, Hf = -9139750.874988236, H0 = 110946.4803249784, Tlimit = 1000, alow = {271932.6942, -4118.600390000001, 20.28714235, 0.0568541699, -8.40073963e-005, 5.823389060000001e-008, -1.57864716e-011}, blow = {-260453.9703, -94.0716207}, ahigh = {-1173177.311, -2200.632995, 35.6301013, -0.000648984974, 1.429623989e-007, -1.635821725e-011, 7.571070759999999e-016}, bhigh = {-278384.3144, -167.963696}, R_s = R_NASA_2002/P4O8.MM);
          constant IdealGases.Common.DataRecord P4O9(name = "P4O9", MM = 0.267889644, Hf = -9757671.375307065, H0 = 110199.6873010888, Tlimit = 1000, alow = {219991.6395, -3336.46494, 15.86413106, 0.07402452330000001, -0.0001034835052, 6.94443832e-008, -1.84073345e-011}, blow = {-301874.2692, -69.9796767}, ahigh = {-1233696.783, -2917.032808, 39.1775711, -0.000873640298, 1.937914895e-007, -2.230510118e-011, 1.037248818e-015}, bhigh = {-312963.7516, -189.717642}, R_s = R_NASA_2002/P4O9.MM);
          constant IdealGases.Common.DataRecord P4O10(name = "P4O10", MM = 0.283889044, Hf = -10237180.71698463, H0 = 109537.7002291078, Tlimit = 1000, alow = {167014.2268, -2540.2433, 11.36853403, 0.09137812159999999, -0.0001231990626, 8.08103223e-008, -2.106787011e-011}, blow = {-341015.191, -46.4343134}, ahigh = {-1337201.132, -3516.38233, 42.6040331, -0.001037406404, 2.287613089e-007, -2.620219946e-011, 1.213529528e-015}, bhigh = {-345951.505, -211.5498906}, R_s = R_NASA_2002/P4O10.MM);
          constant IdealGases.Common.DataRecord Pb(name = "Pb", MM = 0.2072, Hf = 942084.942084942, H0 = 29910.36679536679, Tlimit = 1000, alow = {1213.382285, -19.06116019, 2.619299546, -0.000382951961, 6.68818045e-007, -6.06123108e-010, 2.240022429e-013}, blow = {22820.96238, 6.2013692}, ahigh = {-9084313.07, 26726.7318, -26.26244039, 0.01358282305, -2.685523566e-006, 2.3524328e-010, -7.324114532e-015}, bhigh = {-148165.0666, 215.4011624}, R_s = R_NASA_2002/Pb.MM);
          constant IdealGases.Common.DataRecord Pbplus(name = "Pbplus", MM = 0.2071994514, Hf = 4425670.636693588, H0 = 29910.44598875806, Tlimit = 1000, alow = {9.48668904, -0.1134955793, 2.500549799, -1.382464681e-006, 1.906022991e-009, -1.368396828e-012, 4.003528117e-016}, blow = {109543.8901, 7.5388559}, ahigh = {1320690.183, -4096.04801, 7.38910151, -0.002807751909, 7.83099165e-007, -9.31060091e-011, 4.016371727e-015}, bhigh = {135434.7306, -27.22020908}, R_s = R_NASA_2002/Pbplus.MM);
          constant IdealGases.Common.DataRecord Pbminus(name = "Pbminus", MM = 0.2072005486, Hf = 742671.4313245792, H0 = 29910.28760239489, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {17762.2614, 8.2351321}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {17762.2614, 8.2351321}, R_s = R_NASA_2002/Pbminus.MM);
          constant IdealGases.Common.DataRecord PbBr(name = "PbBr", MM = 0.287104, Hf = 225776.4503455194, H0 = 35339.53549933125, Tlimit = 1000, alow = {-2393.487988, -45.7659121, 4.69260828, -0.000384529063, 5.8882135e-007, -4.08479289e-010, 1.202515201e-013}, blow = {6662.43477, 5.99170551}, ahigh = {-2581831.67, 7143.49076, -2.65819364, 0.00310772226, -4.63138154e-007, 1.095529211e-011, 1.508555088e-015}, bhigh = {-39704.4098, 59.5923865}, R_s = R_NASA_2002/PbBr.MM);
          constant IdealGases.Common.DataRecord PbBr2(name = "PbBr2", MM = 0.367008, Hf = -283122.0654590636, H0 = 40930.81622198971, Tlimit = 1000, alow = {-6172.76636, -67.8320763, 7.27315614, -0.000599059612, 7.35863461e-007, -4.74360481e-010, 1.246922291e-013}, blow = {-14278.90796, -0.698799215}, ahigh = {-13204.21479, -1.143074947, 7.00097254, -4.28447161e-007, 1.018044861e-010, -1.234016791e-014, 5.97133765e-019}, bhigh = {-14622.1375, 0.8868582650000001}, R_s = R_NASA_2002/PbBr2.MM);
          constant IdealGases.Common.DataRecord PbBr3(name = "PbBr3", MM = 0.446912, Hf = -232732.5222862667, H0 = 44681.37575182587, Tlimit = 1000, alow = {-11644.2425, -155.5151665, 10.62317321, -0.001361947117, 1.668738791e-006, -1.073686019e-009, 2.81825034e-013}, blow = {-14782.08304, -14.43758579}, ahigh = {-27879.30766, -2.633265111, 10.00223199, -9.80776141e-007, 2.326232632e-010, -2.81599446e-014, 1.361283735e-018}, bhigh = {-15569.81182, -10.81765474}, R_s = R_NASA_2002/PbBr3.MM);
          constant IdealGases.Common.DataRecord PbBr4(name = "PbBr4", MM = 0.5268160000000001, Hf = -346298.3489491587, H0 = 49109.15575836725, Tlimit = 1000, alow = {-11764.58199, -256.7166983, 14.02223292, -0.002224117068, 2.716201994e-006, -1.743340164e-009, 4.567359749999999e-013}, blow = {-24621.25551, -28.8202075}, ahigh = {-38802.1603, -4.38293377, 13.00369823, -1.620061335e-006, 3.83413088e-010, -4.63396718e-014, 2.237427066e-018}, bhigh = {-25923.27065, -22.87710636}, R_s = R_NASA_2002/PbBr4.MM);
          constant IdealGases.Common.DataRecord PbCL(name = "PbCL", MM = 0.242653, Hf = 36344.56610880558, H0 = 40333.80176630827, Tlimit = 1000, alow = {-2902.700749, -82.93459710000001, 4.71482448, -0.0001931473228, 9.10557902e-008, 5.419385229999999e-011, -3.2849697e-014}, blow = {125.4460217, 4.323194455}, ahigh = {-385428.553, 692.21975, 4.50997124, -0.0006853421299999999, 5.0873955e-007, -9.772753809999999e-011, 5.807471579999999e-015}, bhigh = {-5269.68472, 6.646491015}, R_s = R_NASA_2002/PbCL.MM);
          constant IdealGases.Common.DataRecord PbCL2(name = "PbCL2", MM = 0.278106, Hf = -631225.0400926265, H0 = 50349.61129928876, Tlimit = 1000, alow = {2830.580143, -313.4256659, 8.21282729, -0.002585096173, 3.109456077e-006, -1.972978208e-009, 5.12354248e-013}, blow = {-21675.69042, -9.219412244000001}, ahigh = {-31491.92744, -5.56547758, 7.00459954, -1.986025455e-006, 4.65171959e-010, -5.57913701e-014, 2.67814357e-018}, bhigh = {-23274.39309, -2.140739285}, R_s = R_NASA_2002/PbCL2.MM);
          constant IdealGases.Common.DataRecord PbCL3(name = "PbCL3", MM = 0.313559, Hf = -566571.2258299076, H0 = 58220.91855121364, Tlimit = 1000, alow = {862.3588970000001, -525.315275, 12.03336337, -0.00433518498, 5.21569835e-006, -3.31002238e-009, 8.596970609999999e-013}, blow = {-21805.76379, -26.94206962}, ahigh = {-56644.1279, -9.329514789999999, 10.00771099, -3.32972757e-006, 7.79933081e-010, -9.3546061e-014, 4.4905897e-018}, bhigh = {-24485.08643, -15.0749087}, R_s = R_NASA_2002/PbCL3.MM);
          constant IdealGases.Common.DataRecord PbCL4(name = "PbCL4", MM = 0.349012, Hf = -938163.6218811962, H0 = 67188.05657112076, Tlimit = 1000, alow = {17394.05796, -890.213932, 16.37565058, -0.00708899226, 8.43256734e-006, -5.30530939e-009, 1.368671294e-012}, blow = {-38882.1562, -48.50133784}, ahigh = {-82666.7956, -16.39486405, 13.01336711, -5.7161414e-006, 1.32936839e-009, -1.585922492e-013, 7.58176361e-018}, bhigh = {-43439.84220000001, -28.74559263}, R_s = R_NASA_2002/PbCL4.MM);
          constant IdealGases.Common.DataRecord PbF(name = "PbF", MM = 0.2261984032, Hf = -437084.3807972558, H0 = 40973.37058478404, Tlimit = 1000, alow = {26848.64255, -475.172564, 6.01964437, -0.002718531008, 2.942882954e-006, -1.687543009e-009, 4.08612208e-013}, blow = {-10790.38653, -4.98304884}, ahigh = {-473420.275, 1027.785283, 3.88865873, -0.0001649813448, 2.93116326e-007, -5.76645965e-011, 3.24748619e-015}, bhigh = {-20261.65076, 9.319483890000001}, R_s = R_NASA_2002/PbF.MM);
          constant IdealGases.Common.DataRecord PbF2(name = "PbF2", MM = 0.2451968064, Hf = -1808454.997886954, H0 = 51275.5862712574, Tlimit = 1000, alow = {59205.5228, -1052.529292, 10.28969284, -0.00587634627, 6.10233313e-006, -3.42479264e-009, 8.024025419999999e-013}, blow = {-49990.50000000001, -25.25115478}, ahigh = {-85058.99769999999, -30.74244334, 7.02334604, -9.455183590000001e-006, 2.108489027e-009, -2.434212002e-013, 1.133872429e-017}, bhigh = {-55522.3677, -5.49607322}, R_s = R_NASA_2002/PbF2.MM);
          constant IdealGases.Common.DataRecord PbF3(name = "PbF3", MM = 0.2641952096, Hf = -1853071.498689279, H0 = 58801.39546633173, Tlimit = 1000, alow = {85530.9087, -1731.036694, 15.5659615, -0.01022225919, 1.089984998e-005, -6.269998819999999e-009, 1.502616508e-012}, blow = {-53003.3567, -53.3573348}, ahigh = {-145970.4258, -48.2039643, 10.03685845, -1.501095764e-005, 3.36247499e-009, -3.89602071e-013, 1.820152103e-017}, bhigh = {-62068.6959, -20.06978661}, R_s = R_NASA_2002/PbF3.MM);
          constant IdealGases.Common.DataRecord PbF4(name = "PbF4", MM = 0.2831936128, Hf = -2824658.243845816, H0 = 69303.21205323456, Tlimit = 1000, alow = {130996.3563, -2307.299499, 19.4520144, -0.01024522729, 9.39587496e-006, -4.62689415e-009, 9.450881430000001e-013}, blow = {-88041.47459999999, -75.24645820000001}, ahigh = {-213261.6322, -85.7862195, 13.06428551, -2.575563598e-005, 5.69332459e-009, -6.526219550000001e-013, 3.02234196e-017}, bhigh = {-100290.8979, -35.9024028}, R_s = R_NASA_2002/PbF4.MM);
          constant IdealGases.Common.DataRecord PbI(name = "PbI", MM = 0.33410447, Hf = 325958.8954317193, H0 = 30945.78171911319, Tlimit = 1000, alow = {-2717.33406, -15.42541996, 4.5653279, -0.0001061215818, 2.414841342e-007, -1.876070301e-010, 6.460614269999999e-014}, blow = {11818.64978, 7.66980267}, ahigh = {-3901070.25, 11479.76718, -8.17610902, 0.0065234547, -1.522611682e-006, 1.626692202e-010, -6.55332888e-015}, bhigh = {-61544.3369, 99.38404970000001}, R_s = R_NASA_2002/PbI.MM);
          constant IdealGases.Common.DataRecord PbI2(name = "PbI2", MM = 0.46100894, Hf = -22239.54702483644, H0 = 33073.91392453257, Tlimit = 1000, alow = {-5904.98672, -48.3330703, 7.19543803, -0.000429860009, 5.29141207e-007, -3.41640282e-010, 8.99134192e-014}, blow = {-3107.780155, 1.324773678}, ahigh = {-10883.39477, -0.816441837, 7.0006973, -3.079876763e-007, 7.331718140000001e-011, -8.89919388e-015, 4.3107125e-019}, bhigh = {-3352.09638, 2.458605463}, R_s = R_NASA_2002/PbI2.MM);
          constant IdealGases.Common.DataRecord PbI3(name = "PbI3", MM = 0.58791341, Hf = 37004.44934569531, H0 = 35830.12675284954, Tlimit = 1000, alow = {-10149.96331, -59.380782, 10.24073798, -0.000530469453, 6.538623030000001e-007, -4.22589572e-010, 1.113029818e-013}, blow = {-113.8482403, -8.975540499999999}, ahigh = {-16242.29573, -1.002945584, 10.00085839, -3.79667974e-007, 9.04675172e-011, -1.098840054e-014, 5.325388290000001e-019}, bhigh = {-413.825893, -7.57941711}, R_s = R_NASA_2002/PbI3.MM);
          constant IdealGases.Common.DataRecord PbI4(name = "PbI4", MM = 0.7148178799999999, Hf = -57674.07356962029, H0 = 38500.07361315585, Tlimit = 1000, alow = {-12170.96972, -72.2631744, 13.29294204, -0.00064546609, 7.95576185e-007, -5.14163283e-010, 1.354188031e-013}, blow = {-8528.148679999998, -20.10457498}, ahigh = {-19584.77744, -1.223385179, 13.00104732, -4.63329569e-007, 1.104213978e-010, -1.341397771e-014, 6.50170611e-019}, bhigh = {-8893.193200000002, -18.40570345}, R_s = R_NASA_2002/PbI4.MM);
          constant IdealGases.Common.DataRecord PbO(name = "PbO", MM = 0.2231994, Hf = 305274.6019926577, H0 = 40152.92155803287, Tlimit = 1000, alow = {34240.25, -419.805011, 4.72030641, 0.001451061751, -3.20603546e-006, 2.713956273e-009, -8.333275609999999e-013}, blow = {9253.186469999999, 0.448289121}, ahigh = {242699.685, -110.7731354, 3.18068449, 0.001991815065, -1.079782025e-006, 2.540990941e-010, -1.834652493e-014}, bhigh = {8339.391539999999, 10.50920926}, R_s = R_NASA_2002/PbO.MM);
          constant IdealGases.Common.DataRecord PbO2(name = "PbO2", MM = 0.2391988, Hf = 569203.2485112802, H0 = 51216.53620335888, Tlimit = 1000, alow = {70710.58289999999, -1076.757462, 9.401711730000001, -0.001003861584, -1.233815617e-006, 1.858386979e-009, -6.83462121e-013}, blow = {19996.45981, -25.03976748}, ahigh = {-130779.667, -73.1436145, 7.55408341, -2.143421561e-005, 4.696463999999999e-009, -5.34497218e-013, 2.460760535e-017}, bhigh = {14133.86101, -12.52684909}, R_s = R_NASA_2002/PbO2.MM);
          constant IdealGases.Common.DataRecord PbS(name = "PbS", MM = 0.239265, Hf = 534743.1216433662, H0 = 39412.83932041879, Tlimit = 1000, alow = {15298.40503, -343.974635, 5.68063064, -0.002232931917, 2.504608209e-006, -1.470427328e-009, 3.57752719e-013}, blow = {15785.51202, -2.628900926}, ahigh = {2105441.649, -5520.41358, 9.36924926, -0.001410262019, -1.642683362e-007, 1.451447577e-010, -1.393564925e-014}, bhigh = {50093.3453, -32.17417657}, R_s = R_NASA_2002/PbS.MM);
          constant IdealGases.Common.DataRecord PbS2(name = "PbS2", MM = 0.27133, Hf = 899454.5571812922, H0 = 51675.83754100174, Tlimit = 1000, alow = {24463.7588, -665.485546, 9.920201179999999, -0.00492419438, 5.71690629e-006, -3.52948883e-009, 8.971138350000001e-013}, blow = {30443.1013, -22.95765552}, ahigh = {-54167.003, -13.43600342, 7.51070036, -4.497318629999999e-006, 1.032444494e-009, -1.219580043e-013, 5.78580465e-018}, bhigh = {27012.29533, -8.714618097000001}, R_s = R_NASA_2002/PbS2.MM);
          constant IdealGases.Common.DataRecord Rb(name = "Rb", MM = 0.0854678, Hf = 946555.3108890132, H0 = 72511.8465667772, Tlimit = 1000, alow = {13.52856616, -0.2042232679, 2.501213823, -3.6506199e-006, 5.88472267e-009, -4.84227472e-012, 1.596211946e-015}, blow = {8985.56921, 6.20700548}, ahigh = {-1138274.064, 3804.04194, -2.750899258, 0.0038914607, -1.632296823e-006, 3.51189314e-010, -2.521064422e-014}, bhigh = {-14664.54849, 42.53442370000001}, R_s = R_NASA_2002/Rb.MM);
          constant IdealGases.Common.DataRecord Rbplus(name = "Rbplus", MM = 0.0854672514, Hf = 5734700.952369694, H0 = 72512.3120081992, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {58203.2736, 5.52050692}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {58203.2736, 5.52050692}, R_s = R_NASA_2002/Rbplus.MM);
          constant IdealGases.Common.DataRecord Rbminus(name = "Rbminus", MM = 0.08546834859999999, Hf = 325483.3918716899, H0 = 72511.3811313303, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {2600.405796, 5.52052617}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {2600.405796, 5.52052617}, R_s = R_NASA_2002/Rbminus.MM);
          constant IdealGases.Common.DataRecord RbBO2(name = "RbBO2", MM = 0.1282776, Hf = -5293030.91108658, H0 = 111731.8846002731, Tlimit = 1000, alow = {41986.5775, -679.944833, 8.18515101, 0.002772536733, -6.17577047e-007, -9.42613625e-010, 4.72241424e-013}, blow = {-80203.3959, -12.39198887}, ahigh = {91544.63399999999, -1668.328341, 11.17268757, -0.000450553353, 9.68133059e-008, -1.088037652e-011, 4.96773366e-016}, bhigh = {-75079.0325, -31.31951149}, R_s = R_NASA_2002/RbBO2.MM);
          constant IdealGases.Common.DataRecord RbBr(name = "RbBr", MM = 0.1653718, Hf = -1158062.474980619, H0 = 62399.53849447124, Tlimit = 1000, alow = {-5703.8597, 20.92281597, 4.37060737, 0.000449460478, -4.835438840000001e-007, 3.5260686e-010, -9.88653832e-014}, blow = {-24491.12515, 6.4274317}, ahigh = {1609092.474, -4466.77459, 9.06409206, -0.001995333358, 4.01663352e-007, -4.1630914e-012, -3.092443341e-015}, bhigh = {4427.46769, -27.57714089}, R_s = R_NASA_2002/RbBr.MM);
          constant IdealGases.Common.DataRecord RbCL(name = "RbCL", MM = 0.1209208, Hf = -1846852.476993206, H0 = 83171.14177213515, Tlimit = 1000, alow = {-5740.809579999999, -15.28835285, 4.5152009, 0.0001067270745, -6.38594559e-009, -1.301381692e-011, 1.641459742e-014}, blow = {-28142.43986, 4.190115141}, ahigh = {-1143043.004, 4003.86188, -1.096156782, 0.00403358128, -1.454151464e-006, 2.719263762e-010, -1.81046398e-014}, bhigh = {-52976.86040000001, 43.11317822}, R_s = R_NASA_2002/RbCL.MM);
          constant IdealGases.Common.DataRecord RbF(name = "RbF", MM = 0.1044662032, Hf = -3192533.803123803, H0 = 91781.98026057867, Tlimit = 1000, alow = {32873.6019, -608.090746, 7.40662236, -0.00727786472, 1.013930727e-005, -7.141372500000001e-009, 2.014332982e-012}, blow = {-38498.3413, -13.75750778}, ahigh = {-854481.1149999999, 2633.756505, 1.216216506, 0.002136494067, -6.72842608e-007, 1.134905135e-010, -6.825624440000001e-015}, bhigh = {-58101.7911, 25.88118896}, R_s = R_NASA_2002/RbF.MM);
          constant IdealGases.Common.DataRecord RbH(name = "RbH", MM = 0.08647574, Hf = 1379856.431410705, H0 = 101995.1491597528, Tlimit = 1000, alow = {8908.270610000001, 46.498704, 1.833967623, 0.00844427914, -1.167538647e-005, 8.01038942e-009, -2.162578321e-012}, blow = {13282.48009, 12.79544976}, ahigh = {-2937703.53, 9379.81726, -7.54256346, 0.007493226800000001, -2.159228887e-006, 2.871300173e-010, -1.459981256e-014}, bhigh = {-45955.18829999999, 83.65664320000001}, R_s = R_NASA_2002/RbH.MM);
          constant IdealGases.Common.DataRecord RbI(name = "RbI", MM = 0.21237227, Hf = -652066.6469308824, H0 = 49249.01918692116, Tlimit = 1000, alow = {-769.30528, -29.68608844, 4.64874584, -0.0002962415236, 5.97813534e-007, -4.351255250000001e-010, 1.313617336e-013}, blow = {-17866.10717, 5.81240983}, ahigh = {4297424.85, -12969.11161, 19.58730402, -0.008458425589999999, 2.463480035e-006, -3.19157573e-010, 1.458455589e-014}, bhigh = {64329.4804, -100.9499336}, R_s = R_NASA_2002/RbI.MM);
          constant IdealGases.Common.DataRecord RbK(name = "RbK", MM = 0.1245661, Hf = 963450.9710105718, H0 = 86766.2229129755, Tlimit = 1000, alow = {24946.95429, -455.306066, 7.68618995, -0.01108112244, 2.093398586e-005, -1.824445366e-008, 5.61764536e-012}, blow = {15161.3616, -10.63563675}, ahigh = {-4175391.07, 5918.588510000001, 9.20264942, -0.010609336, 4.96482606e-006, -8.716698790000001e-010, 5.22188796e-014}, bhigh = {-32727.6904, -13.72401997}, R_s = R_NASA_2002/RbK.MM);
          constant IdealGases.Common.DataRecord RbLi(name = "RbLi", MM = 0.0924088, Hf = 1776684.947753893, H0 = 111202.8724537057, Tlimit = 1000, alow = {-2263.413044, -28.8849691, 4.55582654, 0.000362566753, -9.598002220000001e-007, 1.631010244e-009, -8.159825980000001e-013}, blow = {18534.5525, 2.831743182}, ahigh = {10855151.94, -38051.0697, 55.1655504, -0.03128845612, 9.26165025e-006, -1.264671408e-009, 6.43166205e-014}, bhigh = {254396.4131, -352.075871}, R_s = R_NASA_2002/RbLi.MM);
          constant IdealGases.Common.DataRecord RbNO2(name = "RbNO2", MM = 0.1314733, Hf = -1427132.178168495, H0 = 119950.0050580612, Tlimit = 1000, alow = {-71994.2003, 1265.802595, -2.415715742, 0.0305464142, -3.68400405e-005, 2.247716481e-008, -5.54752743e-012}, blow = {-30373.81667, 48.14256904}, ahigh = {-164499.4453, -849.944344, 10.63080575, -0.0002517893988, 5.56142012e-008, -6.378805599999999e-012, 2.957679896e-016}, bhigh = {-21285.90982, -25.68367325}, R_s = R_NASA_2002/RbNO2.MM);
          constant IdealGases.Common.DataRecord RbNO3(name = "RbNO3", MM = 0.1474727, Hf = -2135801.968771169, H0 = 110986.7589052075, Tlimit = 1000, alow = {-26646.69172, 880.763479, -3.159459457, 0.0427122902, -5.35102921e-005, 3.36096975e-008, -8.503290509999999e-012}, blow = {-43535.95460000001, 49.43052899}, ahigh = {-314741.3867, -1371.457846, 14.01319759, -0.000403027502, 8.878332289999999e-008, -1.016221214e-011, 4.704254090000001e-016}, bhigh = {-35043.3994, -46.19379241}, R_s = R_NASA_2002/RbNO3.MM);
          constant IdealGases.Common.DataRecord RbNa(name = "RbNa", MM = 0.10845757, Hf = 1212182.127997151, H0 = 98334.56530512347, Tlimit = 1000, alow = {29744.55567, -508.279059, 7.73403352, -0.0101300684, 1.745455325e-005, -1.39872547e-008, 3.96810677e-012}, blow = {16823.79436, -12.4008529}, ahigh = {4297114.27, -18310.13588, 34.543942, -0.02230134993, 7.33987453e-006, -1.064784996e-009, 5.61759846e-014}, bhigh = {124261.0951, -199.366198}, R_s = R_NASA_2002/RbNa.MM);
          constant IdealGases.Common.DataRecord RbO(name = "RbO", MM = 0.1014672, Hf = 517303.3650283047, H0 = 101876.5078764369, Tlimit = 1000, alow = {190008.1316, -3428.22899, 24.80251273, -0.0505165458, 6.476338760000001e-005, -4.198012420000001e-008, 1.093889043e-011}, blow = {20838.9845, -109.755915}, ahigh = {617075.688, -2175.08962, 8.29041221, -0.002996487663, 1.233144275e-006, -2.115810631e-010, 1.24260743e-014}, bhigh = {18281.64827, -21.17386042}, R_s = R_NASA_2002/RbO.MM);
          constant IdealGases.Common.DataRecord RbOH(name = "RbOH", MM = 0.10247514, Hf = -2322514.514251945, H0 = 114771.2703783572, Tlimit = 1000, alow = {12138.32721, -544.141159, 8.459814639999999, -0.00356152656, 2.99287239e-006, -7.2802674e-010, -4.55384718e-014}, blow = {-27872.62486, -19.13421991}, ahigh = {895858.313, -2332.339, 7.97119248, 0.0001044439355, -6.32825775e-008, 1.029358824e-011, -5.74327779e-016}, bhigh = {-15155.68947, -19.50051629}, R_s = R_NASA_2002/RbOH.MM);
          constant IdealGases.Common.DataRecord Rb2Br2(name = "Rb2Br2", MM = 0.3307436, Hf = -1668366.169443641, H0 = 65599.35248936033, Tlimit = 1000, alow = {-8005.5254, -21.11968088, 10.08629404, -0.000191193609, 2.36605949e-007, -1.53372238e-010, 4.04872506e-014}, blow = {-69273.136, -9.622434630000001}, ahigh = {-10145.35336, -0.360155032, 10.00031058, -1.380745805e-007, 3.30206795e-011, -4.02158182e-015, 1.953006729e-019}, bhigh = {-69379.6088, -9.12256236}, R_s = R_NASA_2002/Rb2Br2.MM);
          constant IdealGases.Common.DataRecord Rb2CL2(name = "Rb2CL2", MM = 0.2418416, Hf = -2556936.176406375, H0 = 85947.05790897844, Tlimit = 1000, alow = {-11250.39522, -67.56953990000001, 10.27381915, -0.000603184899, 7.43332478e-007, -4.803372160000001e-010, 1.264973638e-013}, blow = {-77067.575, -13.63652575}, ahigh = {-18188.75133, -1.13790358, 10.00097318, -4.3021564e-007, 1.024725787e-010, -1.244291058e-014, 6.02891239e-019}, bhigh = {-77408.9767, -12.04843385}, R_s = R_NASA_2002/Rb2CL2.MM);
          constant IdealGases.Common.DataRecord Rb2F2(name = "Rb2F2", MM = 0.2089324064, Hf = -4091817.840662175, H0 = 90410.85739392509, Tlimit = 1000, alow = {-8178.3471, -333.473354, 11.31540799, -0.002842914926, 3.45495958e-006, -2.209373419e-009, 5.77207327e-013}, blow = {-104223.0504, -23.68991587}, ahigh = {-43765.7439, -5.76145204, 10.00482691, -2.104159548e-006, 4.96241627e-010, -5.98217497e-014, 2.882751742e-018}, bhigh = {-105917.6154, -16.03254014}, R_s = R_NASA_2002/Rb2F2.MM);
          constant IdealGases.Common.DataRecord Rb2I2(name = "Rb2I2", MM = 0.42474454, Hf = -1019333.837699244, H0 = 52307.95432944236, Tlimit = 1000, alow = {-5839.66355, -9.5275379, 10.03904495, -8.668754e-005, 1.074384368e-007, -6.97212223e-011, 1.842065721e-014}, blow = {-55027.8096, -7.17411332}, ahigh = {-6799.83464, -0.1642527699, 10.000142, -6.321420729999999e-008, 1.51281117e-011, -1.843027189e-015, 8.951244179999999e-020}, bhigh = {-55075.7962, -6.94804539}, R_s = R_NASA_2002/Rb2I2.MM);
          constant IdealGases.Common.DataRecord Rb2O(name = "Rb2O", MM = 0.186935, Hf = -582712.8199641587, H0 = 76046.64188086768, Tlimit = 1000, alow = {19712.76138, -462.750886, 8.58829313, -0.003085559728, 3.45198014e-006, -2.068570368e-009, 5.132480499999999e-013}, blow = {-12848.54711, -12.64891828}, ahigh = {-38463.6009, -10.82831019, 7.00842189, -3.47622812e-006, 7.86978506e-010, -9.195683850000001e-014, 4.325201520000001e-018}, bhigh = {-15253.73768, -3.23038878}, R_s = R_NASA_2002/Rb2O.MM);
          constant IdealGases.Common.DataRecord Rb2O2(name = "Rb2O2", MM = 0.2029344, Hf = -1063636.662882192, H0 = 83017.6254001293, Tlimit = 1000, alow = {32605.5323, -757.816472, 10.70815124, 0.001148004329, -3.29124367e-006, 2.853106637e-009, -8.72159068e-013}, blow = {-24753.17258, -24.3427646}, ahigh = {-131856.7396, -96.47737790000001, 10.07222726, -2.894921706e-005, 6.4056391e-009, -7.35141939e-013, 3.40856171e-017}, bhigh = {-28821.79733, -19.10948823}, R_s = R_NASA_2002/Rb2O2.MM);
          constant IdealGases.Common.DataRecord Rb2O2H2(name = "Rb2O2H2", MM = 0.20495028, Hf = -3117829.358418052, H0 = 114210.036697681, Tlimit = 1000, alow = {-4577.07653, -841.7631, 17.04083828, -0.00535788254, 3.95177877e-006, -2.051775094e-010, -4.08541691e-013}, blow = {-76949.8217, -54.3541278}, ahigh = {1792711.652, -4659.406599999999, 16.93822422, 0.0002106246492, -1.26961747e-007, 2.063382927e-011, -1.150861507e-015}, bhigh = {-50241.1763, -60.27054920000001}, R_s = R_NASA_2002/Rb2O2H2.MM);
          constant IdealGases.Common.DataRecord Rb2SO4(name = "Rb2SO4", MM = 0.2669982, Hf = -4107114.025487812, H0 = 87348.70871788649, Tlimit = 1000, alow = {60948.54930000001, -688.97059, 7.03424218, 0.0393394547, -5.49892051e-005, 3.71634108e-008, -9.919863380000001e-012}, blow = {-131187.7657, -4.450168488}, ahigh = {-530289.831, -951.543545, 19.71013517, -0.0002842916301, 6.289142939999999e-008, -7.2193243e-012, 3.34871819e-016}, bhigh = {-133871.3151, -70.56246881999999}, R_s = R_NASA_2002/Rb2SO4.MM);
          constant IdealGases.Common.DataRecord Rn(name = "Rn", MM = 0.2220176, Hf = 0, H0 = 27914.12933028733, Tlimit = 1000, alow = {3.38943209e-006, -1.311675533e-007, 2.500000001, -2.978593139e-012, 4.33705073e-015, -3.18204022e-018, 9.24778703e-022}, blow = {-745.374999, 6.95244198}, ahigh = {27301.90029, -82.84672620000001, 2.598178483, -5.81372985e-005, 1.819136527e-008, -2.866656182e-012, 1.789322176e-016}, bhigh = {-220.280934, 6.25500571}, R_s = R_NASA_2002/Rn.MM);
          constant IdealGases.Common.DataRecord Rnplus(name = "Rnplus", MM = 0.2220170514, Hf = 4699054.678103881, H0 = 27914.19830558113, Tlimit = 1000, alow = {-0.09697148970000001, 0.001106742047, 2.499994937, 1.189388239e-008, -1.515895754e-011, 9.95893481e-015, -2.640751817e-018}, blow = {124730.476, 8.338761699999999}, ahigh = {-19982.85319, 59.3067566, 2.432476003, 3.71602592e-005, -1.012057848e-008, 1.192256661e-012, -3.18452198e-017}, bhigh = {124352.8478, 8.821997789999999}, R_s = R_NASA_2002/Rnplus.MM);
          constant IdealGases.Common.DataRecord S(name = "S", MM = 0.032065, Hf = 8644004.366131296, H0 = 207622.7974426945, Tlimit = 1000, alow = {-317.484182, -192.4704923, 4.68682593, -0.0058413656, 7.53853352e-006, -4.86358604e-009, 1.256976992e-012}, blow = {33235.9218, -5.718523969}, ahigh = {-485424.479, 1438.830408, 1.258504116, 0.000379799043, 1.630685864e-009, -9.547095849999999e-012, 8.041466646e-016}, bhigh = {23349.9527, 15.59554855}, R_s = R_NASA_2002/S.MM);
          constant IdealGases.Common.DataRecord Splus(name = "Splus", MM = 0.03206445140000001, Hf = 39997454.25240614, H0 = 193280.337863507, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {153502.6117, 5.43622334}, ahigh = {1346218.684, -4056.87151, 7.15343655, -0.002523562352, 6.42953961e-007, -6.43167216e-011, 2.141387919e-015}, bhigh = {179282.3835, -27.86935079}, R_s = R_NASA_2002/Splus.MM);
          constant IdealGases.Common.DataRecord Sminus(name = "Sminus", MM = 0.0320655486, Hf = 2194520.539093474, H0 = 201615.2937423937, Tlimit = 1000, alow = {-2596.051473, -142.2398653, 4.00782567, -0.00360885591, 4.23623e-006, -2.520987604e-009, 6.07947976e-013}, blow = {8197.79307, -2.582377345}, ahigh = {2730.311692, 141.4072078, 2.403340775, 3.69357753e-005, -7.94408044e-009, 8.95220838e-013, -4.09966282e-017}, bhigh = {6931.1957, 6.574986902}, R_s = R_NASA_2002/Sminus.MM);
          constant IdealGases.Common.DataRecord SCL(name = "SCL", MM = 0.067518, Hf = 2317382.031458278, H0 = 145430.122337747, Tlimit = 1000, alow = {16130.51454, -560.624955, 8.06493113, -0.0091863264, 1.224205395e-005, -8.209562019999999e-009, 2.205087197e-012}, blow = {19977.3928, -16.9335441}, ahigh = {-94051.23449999999, 362.976085, 4.06995936, 0.0003034029742, -8.24830139e-008, 1.252700734e-011, -6.41746365e-016}, bhigh = {15231.11069, 6.014528409}, R_s = R_NASA_2002/SCL.MM);
          constant IdealGases.Common.DataRecord SCL2(name = "SCL2", MM = 0.102971, Hf = -170659.7003039691, H0 = 120862.4272853522, Tlimit = 1000, alow = {57923.1183, -1062.447681, 10.37694738, -0.00613022902, 6.463485999999999e-006, -3.67903805e-009, 8.73193165e-013}, blow = {1262.475821, -26.91769492}, ahigh = {-234103.9963, 428.7569580000001, 6.47141539, 0.000317947674, -9.74748308e-008, 1.39331857e-011, -6.39479517e-016}, bhigh = {-7210.4737, -2.774273151}, R_s = R_NASA_2002/SCL2.MM);
          constant IdealGases.Common.DataRecord SCL2plus(name = "SCL2plus", MM = 0.1029704514, Hf = 8753805.919510614, H0 = 120940.0059015377, Tlimit = 1000, alow = {49348.7687, -960.1641020000001, 9.88479278, -0.004950257170000001, 4.94628697e-006, -2.678720604e-009, 6.07684403e-013}, blow = {111281.2037, -23.42664942}, ahigh = {-233940.3605, 551.628326, 6.12521216, 0.000677105632, -2.674382769e-007, 4.93593888e-011, -2.955831247e-015}, bhigh = {102678.7381, 0.1365611954}, R_s = R_NASA_2002/SCL2plus.MM);
          constant IdealGases.Common.DataRecord SD(name = "SD", MM = 0.034079102, Hf = 4063806.962988637, H0 = 272731.4528416858, Tlimit = 1000, alow = {-32955.7499, 164.7104687, 4.97898455, -0.008031585710000001, 1.653766397e-005, -1.345197981e-008, 4.00043153e-012}, blow = {14358.62329, -1.997334017}, ahigh = {245673.249, -1180.034105, 5.28469005, -0.0002384319882, 6.009960290000001e-008, -7.13116364e-012, 4.0358587e-016}, bhigh = {22655.45124, -8.350483655}, R_s = R_NASA_2002/SD.MM);
          constant IdealGases.Common.DataRecord SF(name = "SF", MM = 0.0510634032, Hf = 302478.0964853514, H0 = 185457.9484823683, Tlimit = 1000, alow = {12064.56774, -291.027077, 5.48010157, -0.001975880235, 2.47368599e-006, -1.610904623e-009, 4.31003854e-013}, blow = {1991.337574, -4.544138975}, ahigh = {763458.075, -2423.63843, 7.35219871, -0.001598026079, 4.86851502e-007, -6.47800053e-011, 2.98029731e-015}, bhigh = {15774.61591, -19.02584835}, R_s = R_NASA_2002/SF.MM);
          constant IdealGases.Common.DataRecord SFplus(name = "SFplus", MM = 0.0510628546, Hf = 19477372.06998999, H0 = 173596.2094058094, Tlimit = 1000, alow = {65783.0367, -698.669997, 5.62129224, -0.000690927411, -1.28239278e-007, 4.02132042e-010, -1.424033453e-013}, blow = {122175.1247, -6.682377715}, ahigh = {-937494.39, 2377.21424, 2.052929113, 0.001081609837, -1.535468024e-007, 8.2226919e-012, 3.25974688e-017}, bhigh = {102684.9122, 18.87705768}, R_s = R_NASA_2002/SFplus.MM);
          constant IdealGases.Common.DataRecord SFminus(name = "SFminus", MM = 0.0510639518, Hf = -4530532.495920145, H0 = 173803.7634603909, Tlimit = 1000, alow = {50198.7928, -532.154931, 4.90484901, 0.0009915307419999999, -2.270841545e-006, 1.844749756e-009, -5.3570572e-013}, blow = {-26113.88646, -3.637468065}, ahigh = {206892.3125, -1324.372811, 6.64621124, -0.001641781588, 6.78388312e-007, -1.198331099e-010, 7.12173954e-015}, bhigh = {-21509.94816, -14.70239183}, R_s = R_NASA_2002/SFminus.MM);
          constant IdealGases.Common.DataRecord SF2(name = "SF2", MM = 0.0700618064, Hf = -4184715.597056031, H0 = 157694.6637219448, Tlimit = 1000, alow = {68708.71130000001, -843.241825, 6.2694964, 0.00648414245, -1.145126533e-005, 8.770291560000001e-009, -2.542611601e-012}, blow = {-32299.807, -8.80002578}, ahigh = {-170261.2287, -149.7038204, 7.11093414, -4.4077416e-005, 9.68220831e-009, -1.104468959e-012, 5.09530878e-017}, bhigh = {-37042.8949, -10.9525396}, R_s = R_NASA_2002/SF2.MM);
          constant IdealGases.Common.DataRecord SF2plus(name = "SF2plus", MM = 0.07006125780000001, Hf = 10077122.83749493, H0 = 160347.9633789846, Tlimit = 1000, alow = {131164.8923, -1552.127914, 9.803424720000001, -0.002488118587, 7.501565130000001e-007, 3.135384495e-010, -1.986281446e-013}, blow = {91377.5839, -27.92300566}, ahigh = {-384753.102, 532.789302, 6.2819089, 0.000452279012, -1.426421096e-007, 2.079708115e-011, -9.69170989e-016}, bhigh = {78842.1381, -4.21611053}, R_s = R_NASA_2002/SF2plus.MM);
          constant IdealGases.Common.DataRecord SF2minus(name = "SF2minus", MM = 0.07006235499999999, Hf = -5634908.504003327, H0 = 173058.3421011184, Tlimit = 1000, alow = {52845.7248, -1032.342905, 10.06404631, -0.00520950325, 5.16838137e-006, -2.783420867e-009, 6.28641008e-013}, blow = {-44233.03780000001, -26.9926697}, ahigh = {-93766.18949999999, -36.3899527, 7.02794282, -1.142143365e-005, 2.566295898e-009, -2.981125977e-013, 1.395700722e-017}, bhigh = {-49670.5033, -8.483087898999999}, R_s = R_NASA_2002/SF2minus.MM);
          constant IdealGases.Common.DataRecord SF3(name = "SF3", MM = 0.0890602096, Hf = -5660231.401476514, H0 = 152124.7823337708, Tlimit = 1000, alow = {128400.8253, -2084.871223, 14.23421102, -0.00401503219, 9.152258039999999e-007, 1.109809721e-009, -5.98860272e-013}, blow = {-52395.1734, -51.87194724}, ahigh = {-241128.346, -141.8950375, 10.10590548, -4.231526910000001e-005, 9.336120599999999e-009, -1.068727665e-012, 4.9443426e-017}, bhigh = {-63584.4586, -24.89561796}, R_s = R_NASA_2002/SF3.MM);
          constant IdealGases.Common.DataRecord SF3plus(name = "SF3plus", MM = 0.08905966100000001, Hf = 4419323.760956152, H0 = 139335.2260795154, Tlimit = 1000, alow = {215763.3857, -2564.488498, 13.23216044, -0.0001749580869, -3.71295871e-006, 3.58068842e-009, -1.084376153e-012}, blow = {58760.8842, -50.24130184}, ahigh = {-377826.075, -162.1770252, 9.96026597, 0.0001237729568, -6.442207889999999e-008, 1.300856025e-011, -7.915106980000001e-016}, bhigh = {44154.26809999999, -26.7390077}, R_s = R_NASA_2002/SF3plus.MM);
          constant IdealGases.Common.DataRecord SF3minus(name = "SF3minus", MM = 0.08906075819999999, Hf = -8871743.548664289, H0 = 154084.6190550397, Tlimit = 1000, alow = {154650.0675, -2469.768526, 16.57548496, -0.01020137434, 9.36800846e-006, -4.7256726e-009, 1.009661431e-012}, blow = {-85001.579, -65.32166474}, ahigh = {-225386.0964, -130.8890242, 10.0997238, -4.05234553e-005, 9.064565220000001e-009, -1.049320641e-012, 4.89920126e-017}, bhigh = {-98002.272, -25.24368023}, R_s = R_NASA_2002/SF3minus.MM);
          constant IdealGases.Common.DataRecord SF4(name = "SF4", MM = 0.1080586128, Hf = -7033220.03037966, H0 = 142356.8339570615, Tlimit = 1000, alow = {163618.3265, -2531.316261, 15.59106568, 0.00332670431, -1.054935525e-005, 9.39136305e-009, -2.914816694e-012}, blow = {-81155.5892, -61.31532958}, ahigh = {-377712.516, -293.7595659, 13.21902007, -8.74766945e-005, 1.929905265e-008, -2.209423506e-012, 1.022335559e-016}, bhigh = {-94831.7534, -42.43061278}, R_s = R_NASA_2002/SF4.MM);
          constant IdealGases.Common.DataRecord SF4plus(name = "SF4plus", MM = 0.1080580642, Hf = 3850818.215934689, H0 = 152747.0172836948, Tlimit = 1000, alow = {230958.7324, -3383.77767, 21.01756367, -0.01106529555, 9.038097280000001e-006, -4.05591264e-009, 7.71257518e-013}, blow = {64253.7515, -89.38224908000001}, ahigh = {-418917.275, 40.0288964, 12.83873264, 0.0001340235036, -4.81813518e-008, 7.574595959999999e-012, -3.69667078e-016}, bhigh = {44699.4423, -37.60378598}, R_s = R_NASA_2002/SF4plus.MM);
          constant IdealGases.Common.DataRecord SF4minus(name = "SF4minus", MM = 0.1080591614, Hf = -8212763.346505111, H0 = 171020.3999417675, Tlimit = 1000, alow = {100552.3355, -2267.351994, 19.7928456, -0.01163761842, 1.161792139e-005, -6.28889547e-009, 1.426371272e-012}, blow = {-98955.9743, -79.16366078}, ahigh = {320882.208, -1710.416599, 14.94425485, -0.001057207329, 2.74284692e-007, -2.905761211e-011, 1.084482543e-015}, bhigh = {-100523.1225, -51.64256578}, R_s = R_NASA_2002/SF4minus.MM);
          constant IdealGases.Common.DataRecord SF5(name = "SF5", MM = 0.127057016, Hf = -7104395.455029419, H0 = 148055.4131697851, Tlimit = 1000, alow = {222417.685, -4043.99175, 27.07196786, -0.01744176604, 1.604198715e-005, -7.99724302e-009, 1.667968061e-012}, blow = {-92200.7827, -123.2426279}, ahigh = {-389242.637, -182.5826536, 16.13765057, -5.54483423e-005, 1.231433706e-008, -1.417173409e-012, 6.5848894e-017}, bhigh = {-113567.1054, -55.77524201}, R_s = R_NASA_2002/SF5.MM);
          constant IdealGases.Common.DataRecord SF5plus(name = "SF5plus", MM = 0.1270564674, Hf = 1358797.466456241, H0 = 128662.0377106439, Tlimit = 1000, alow = {377713.562, -5646.07512, 30.4940427, -0.02176488368, 1.941993792e-005, -9.55620114e-009, 2.000077302e-012}, blow = {45922.0481, -148.9889627}, ahigh = {-981434.232, 720.881739, 15.64386818, -0.0002452519972, 2.241690996e-007, -3.99003589e-011, 2.279087545e-015}, bhigh = {9090.95319, -55.31460631}, R_s = R_NASA_2002/SF5plus.MM);
          constant IdealGases.Common.DataRecord SF5minus(name = "SF5minus", MM = 0.1270575646, Hf = -9480917.494305568, H0 = 149931.356389307, Tlimit = 1000, alow = {209503.1134, -3930.08114, 27.02127215, -0.01792973203, 1.718122152e-005, -9.00056019e-009, 1.988018147e-012}, blow = {-129181.6581, -123.1672857}, ahigh = {-373321.92, -179.3729521, 16.13699748, -5.57753997e-005, 1.249477046e-008, -1.448104799e-012, 6.7674623e-017}, bhigh = {-149855.4401, -56.31439391}, R_s = R_NASA_2002/SF5minus.MM);
          constant IdealGases.Common.DataRecord SF6(name = "SF6", MM = 0.1460554192, Hf = -8348885.694752777, H0 = 115983.830608868, Tlimit = 1000, alow = {330952.674, -4737.68505, 22.47738068, 0.01046954309, -2.560641961e-005, 2.153716967e-008, -6.51609896e-012}, blow = {-125536.0583, -109.1760145}, ahigh = {-730672.65, -636.705655, 19.47442853, -0.0001894325671, 4.17872283e-008, -4.78374495e-012, 2.213516129e-016}, bhigh = {-151060.9837, -81.47574587}, R_s = R_NASA_2002/SF6.MM);
          constant IdealGases.Common.DataRecord SF6minus(name = "SF6minus", MM = 0.1460559678, Hf = -9187409.821127487, H0 = 119753.504519245, Tlimit = 1000, alow = {498580.921, -6934.44574, 34.4131833, -0.0198403236, 1.497871222e-005, -6.133234650000001e-009, 1.045159581e-012}, blow = {-129706.9066, -174.7984495}, ahigh = {-681807.3509999999, -594.742996, 19.45009842, -0.0001820212649, 4.05707957e-008, -4.683820930000001e-012, 2.182263999e-016}, bhigh = {-165890.2452, -79.65845887}, R_s = R_NASA_2002/SF6minus.MM);
          constant IdealGases.Common.DataRecord SH(name = "SH", MM = 0.03307294, Hf = 4297631.507812732, H0 = 275092.2355254779, Tlimit = 1000, alow = {6389.43468, -374.796092, 7.54814577, -0.01288875477, 1.907786343e-005, -1.265033728e-008, 3.23515869e-012}, blow = {17429.02395, -17.60761843}, ahigh = {1682631.601, -5177.15221, 9.198168519999999, -0.002323550224, 6.543914779999999e-007, -8.468470419999999e-011, 3.86474155e-015}, bhigh = {48992.14490000001, -37.70400275}, R_s = R_NASA_2002/SH.MM);
          constant IdealGases.Common.DataRecord SHminus(name = "SHminus", MM = 0.0330734886, Hf = -2617628.186946085, H0 = 261420.9859917832, Tlimit = 1000, alow = {38780.7076, -574.25906, 6.89854446, -0.01001352412, 1.486460572e-005, -9.7503689e-009, 2.446909813e-012}, blow = {-8735.38898, -16.15966489}, ahigh = {1198715.402, -3894.84682, 7.66042233, -0.00135523759, 3.34237024e-007, -3.35072231e-011, 9.05508478e-016}, bhigh = {13174.77387, -28.18370616}, R_s = R_NASA_2002/SHminus.MM);
          constant IdealGases.Common.DataRecord SN(name = "SN", MM = 0.0460717, Hf = 5803743.143838843, H0 = 203880.3213252387, Tlimit = 1000, alow = {-68354.1235, 1147.567483, -2.877802574, 0.0172486432, -2.058999904e-005, 1.26136964e-008, -3.139030141e-012}, blow = {25641.43612, 42.24006964}, ahigh = {-483728.446, 1058.07559, 3.086198804, 0.000911136078, -2.764061722e-007, 4.157370109999999e-011, -2.128351755e-015}, bhigh = {23793.45477, 10.33222139}, R_s = R_NASA_2002/SN.MM);
          constant IdealGases.Common.DataRecord SO(name = "SO", MM = 0.0480644, Hf = 99040.16278160134, H0 = 183048.2852173334, Tlimit = 1000, alow = {-33427.57, 640.38625, -1.006641228, 0.01381512705, -1.704486364e-005, 1.06129493e-008, -2.645796205e-012}, blow = {-3371.29219, 30.93861963}, ahigh = {-1443410.557, 4113.87436, -0.538369578, 0.002794153269, -6.63335226e-007, 7.838221189999999e-011, -3.56050907e-015}, bhigh = {-27088.38059, 36.15358329}, R_s = R_NASA_2002/SO.MM);
          constant IdealGases.Common.DataRecord SOminus(name = "SOminus", MM = 0.0480649486, Hf = -2204685.307829498, H0 = 196965.0291064703, Tlimit = 1000, alow = {8420.196969999999, -69.1658668, 3.83766661, 0.002166482062, -2.811222562e-006, 1.793426453e-009, -4.52179595e-013}, blow = {-13541.62531, 4.316141603}, ahigh = {176715.6147, -663.398736, 5.17727981, -0.0002853461125, 7.21442153e-008, -3.67646949e-012, -2.910092894e-016}, bhigh = {-9984.43801, -3.951456757}, R_s = R_NASA_2002/SOminus.MM);
          constant IdealGases.Common.DataRecord SOF2(name = "SOF2", MM = 0.08606120640000001, Hf = -6796933.687882859, H0 = 146696.1192865639, Tlimit = 1000, alow = {61145.7965, -908.1119669999999, 6.88362326, 0.01192459695, -1.67100641e-005, 1.110723646e-008, -2.910788226e-012}, blow = {-67429.3584, -11.25458745}, ahigh = {-251055.5779, -607.4439609999999, 10.45046709, -0.0001796384979, 3.96416973e-008, -4.54305524e-012, 2.104969923e-016}, bhigh = {-70720.71710000001, -29.04334504}, R_s = R_NASA_2002/SOF2.MM);
          constant IdealGases.Common.DataRecord SO2(name = "SO2", MM = 0.0640638, Hf = -4633037.690552231, H0 = 164650.3485587805, Tlimit = 1000, alow = {-53108.4214, 909.031167, -2.356891244, 0.02204449885, -2.510781471e-005, 1.446300484e-008, -3.36907094e-012}, blow = {-41137.52080000001, 40.45512519}, ahigh = {-112764.0116, -825.226138, 7.61617863, -0.000199932761, 5.65563143e-008, -5.45431661e-012, 2.918294102e-016}, bhigh = {-33513.0869, -16.55776085}, R_s = R_NASA_2002/SO2.MM);
          constant IdealGases.Common.DataRecord SO2minus(name = "SO2minus", MM = 0.0640643486, Hf = -6378057.030614996, H0 = 167791.1542832732, Tlimit = 1000, alow = {94609.01659999999, -856.269105, 5.36007422, 0.00760957674, -1.092005659e-005, 7.20254773e-009, -1.85013822e-012}, blow = {-45800.9481, -3.929956604}, ahigh = {-179340.0005, -366.316876, 7.27444105, -0.0001101944663, 2.443328132e-008, -2.809735019e-012, 1.305160431e-016}, bhigh = {-49730.7261, -12.61421156}, R_s = R_NASA_2002/SO2minus.MM);
          constant IdealGases.Common.DataRecord SO2CL2(name = "SO2CL2", MM = 0.1349698, Hf = -2628759.915181026, H0 = 118757.7072797026, Tlimit = 1000, alow = {6821.59239, -584.9569200000001, 8.59675691, 0.01197228675, -1.3337607e-005, 7.126128999999999e-009, -1.496150016e-012}, blow = {-42307.8381, -16.52458363}, ahigh = {-237663.9109, -964.7740410000001, 13.71469904, -0.0002850327057, 6.29350962e-008, -7.21784426e-012, 3.34684022e-016}, bhigh = {-41900.7299, -44.81942574999999}, R_s = R_NASA_2002/SO2CL2.MM);
          constant IdealGases.Common.DataRecord SO2FCL(name = "SO2FCL", MM = 0.1185152032, Hf = -4695363.843412791, H0 = 124042.9970422563, Tlimit = 1000, alow = {36845.613, -803.8358949999999, 7.52618688, 0.01620141782, -1.97059527e-005, 1.16625033e-008, -2.759241465e-012}, blow = {-65035.9819, -12.99745646}, ahigh = {-291540.2438, -1107.134423, 13.81845158, -0.000325851446, 7.184741e-008, -8.230625200000001e-012, 3.81292562e-016}, bhigh = {-65524.7269, -47.09166446}, R_s = R_NASA_2002/SO2FCL.MM);
          constant IdealGases.Common.DataRecord SO2F2(name = "SO2F2", MM = 0.1020606064, Hf = -7446555.794714541, H0 = 132180.7842991613, Tlimit = 1000, alow = {55331.5353, -807.463968, 5.28717216, 0.02294547775, -2.891025299e-005, 1.785631907e-008, -4.4189195e-012}, blow = {-88994.28820000001, -4.124256607}, ahigh = {-340390.445, -1309.288764, 13.96601541, -0.000384008815, 8.456688780000001e-008, -9.678246870000001e-012, 4.48001428e-016}, bhigh = {-89019.9414, -51.0927005}, R_s = R_NASA_2002/SO2F2.MM);
          constant IdealGases.Common.DataRecord SO3(name = "SO3", MM = 0.0800632, Hf = -4944843.573576874, H0 = 145990.9046852986, Tlimit = 1000, alow = {-39528.5529, 620.857257, -1.437731716, 0.02764126467, -3.144958662e-005, 1.792798e-008, -4.12638666e-012}, blow = {-51841.0617, 33.91331216}, ahigh = {-216692.3781, -1301.022399, 10.96287985, -0.000383710002, 8.466889039999999e-008, -9.70539929e-012, 4.49839754e-016}, bhigh = {-43982.83990000001, -36.55217314}, R_s = R_NASA_2002/SO3.MM);
          constant IdealGases.Common.DataRecord S2(name = "S2", MM = 0.06412999999999999, Hf = 2005301.730859192, H0 = 142399.9688133479, Tlimit = 1000, alow = {35280.9178, -422.215658, 4.67743349, 0.001724046361, -3.86220821e-006, 3.33615634e-009, -9.93066154e-013}, blow = {16547.67715, -0.7957279032}, ahigh = {-15881.28788, 631.548088, 2.449628069, 0.001986240565, -6.50792724e-007, 1.002813651e-010, -5.59699005e-015}, bhigh = {10855.08427, 14.58544515}, R_s = R_NASA_2002/S2.MM);
          constant IdealGases.Common.DataRecord S2minus(name = "S2minus", MM = 0.0641305486, Hf = -579012.4333974589, H0 = 149649.6632183807, Tlimit = 1000, alow = {10255.58251, -616.6128249999999, 8.182052840000001, -0.008311203580000001, 9.72027416e-006, -5.77547678e-009, 1.393690695e-012}, blow = {-3063.559874, -19.06068041}, ahigh = {483020.403, -1319.171302, 6.03177848, -0.0007965560690000001, 2.28224169e-007, -2.504364698e-011, 7.28055078e-016}, bhigh = {2660.25849, -9.010480318999999}, R_s = R_NASA_2002/S2minus.MM);
          constant IdealGases.Common.DataRecord S2CL2(name = "S2CL2", MM = 0.135036, Hf = -123937.3204182589, H0 = 122343.382505406, Tlimit = 1000, alow = {79749.74740000001, -1636.770024, 15.83744686, -0.01186906072, 1.413008027e-005, -8.48490393e-009, 1.981743887e-012}, blow = {3276.87242, -52.93745205}, ahigh = {632881.6, -3442.7058, 15.1963735, -0.002960877176, 6.88828437e-007, -7.990692529999999e-011, 3.69246606e-015}, bhigh = {15266.72656, -54.53315445000001}, R_s = R_NASA_2002/S2CL2.MM);
          constant IdealGases.Common.DataRecord S2F2(name = "S2F2", MM = 0.1021268064, Hf = -3930535.127357121, H0 = 134322.1479605574, Tlimit = 1000, alow = {125290.4041, -1941.243874, 13.25382183, -0.001341525124, -2.772465632e-006, 3.65816929e-009, -1.299531209e-012}, blow = {-40672.0825, -45.60828617}, ahigh = {-259175.7719, -105.9653069, 10.06588551, -2.274618148e-005, 5.41234314e-009, -9.91138714e-013, 9.621861440000001e-017}, bhigh = {-51476.75180000001, -23.7566614}, R_s = R_NASA_2002/S2F2.MM);
          constant IdealGases.Common.DataRecord S2O(name = "S2O", MM = 0.0801294, Hf = -699312.5494512626, H0 = 138882.320346839, Tlimit = 1000, alow = {10927.0331, -95.23099869999999, 3.14452543, 0.011768542, -1.58026684e-005, 1.03764504e-008, -2.70862226e-012}, blow = {-7500.4719, 11.04169896}, ahigh = {-144213.979, -327.643013, 7.24428611, -9.7765383e-005, 2.1627127e-008, -2.48278222e-012, 1.15177875e-016}, bhigh = {-7438.55393, -10.85180744}, R_s = R_NASA_2002/S2O.MM);
          constant IdealGases.Common.DataRecord S3(name = "S3", MM = 0.09619499999999999, Hf = 1504634.627579396, H0 = 124479.733873902, Tlimit = 1000, alow = {72453.9574, -1162.146759, 9.95541368, -0.00415802622, 3.24177839e-006, -1.264648239e-009, 1.777450535e-013}, blow = {21462.75475, -25.87525865}, ahigh = {-111780.5401, -51.97908390000001, 7.03876084, -1.546804022e-005, 3.40834041e-009, -3.89686236e-013, 1.800860389e-017}, bhigh = {15254.06485, -7.610045099}, R_s = R_NASA_2002/S3.MM);
          constant IdealGases.Common.DataRecord S4(name = "S4", MM = 0.12826, Hf = 1057479.596132855, H0 = 111338.944331826, Tlimit = 1000, alow = {119866.4135, -2040.786521, 15.10235054, -0.0070411043, 5.350405e-006, -2.002348038e-009, 2.569940995e-013}, blow = {24109.09409, -55.03153238}, ahigh = {-206833.3537, -96.96151430000001, 10.0724321, -2.895047053e-005, 6.38780619e-009, -7.31176743e-013, 3.38226529e-017}, bhigh = {13211.0953, -23.44872237}, R_s = R_NASA_2002/S4.MM);
          constant IdealGases.Common.DataRecord S5(name = "S5", MM = 0.160325, Hf = 829523.4929050366, H0 = 118842.0645563699, Tlimit = 1000, alow = {136137.0439, -2955.476536, 26.33358816, -0.0412580653, 7.05681403e-005, -5.611095330000001e-008, 1.6594572e-011}, blow = {26753.07046, -106.9711067}, ahigh = {-4038495.16, 8601.80388, 7.4437809, 0.001533393812, -2.532718676e-007, 2.145210795e-011, -7.213102680000001e-016}, bhigh = {-46869.2542, 11.04229196}, R_s = R_NASA_2002/S5.MM);
          constant IdealGases.Common.DataRecord S6(name = "S6", MM = 0.19239, Hf = 526613.5454025677, H0 = 118442.6373512137, Tlimit = 1000, alow = {97803.07210000001, -2568.47013, 24.67025557, -0.01619983175, 1.712334526e-005, -9.74629674e-009, 2.486964867e-012}, blow = {20378.88389, -101.4410309}, ahigh = {3686845.06, -7695.0179, 18.60721995, 0.002290382548, -1.219834021e-006, 2.060780798e-010, -1.190354318e-014}, bhigh = {60324.8648, -74.90245718}, R_s = R_NASA_2002/S6.MM);
          constant IdealGases.Common.DataRecord S7(name = "S7", MM = 0.224455, Hf = 498498.0018266468, H0 = 117058.5106145998, Tlimit = 1000, alow = {123365.5613, -3200.54364, 30.15678887, -0.02197472483, 2.487892075e-005, -1.506049557e-008, 3.76892599e-012}, blow = {23900.05896, -127.5978171}, ahigh = {-272639.6041, -73.7321522, 19.05771987, -2.394575885e-005, 5.4426713e-009, -6.379663479999999e-013, 3.008212993e-017}, bhigh = {7308.458830000001, -61.59112428}, R_s = R_NASA_2002/S7.MM);
          constant IdealGases.Common.DataRecord S8(name = "S8", MM = 0.25652, Hf = 394811.7963511617, H0 = 123082.4964915017, Tlimit = 1000, alow = {314562.5719, -6116.51016, 48.7532754, -0.0624179465, 7.421831750000001e-005, -3.72644931e-008, 5.79942988e-012}, blow = {35738.9084, -228.8701977}, ahigh = {-8727921.130000001, 12216.27968, 22.09959617, -0.00349406483, 1.397604162e-006, -2.169815281e-010, 1.212304364e-014}, bhigh = {-86581.10819999999, -64.35742508}, R_s = R_NASA_2002/S8.MM);
          constant IdealGases.Common.DataRecord Sc(name = "Sc", MM = 0.04495591, Hf = 8401570.761219159, H0 = 155758.3641394424, Tlimit = 1000, alow = {-3700.80594, 169.2506026, 1.842242597, 0.001364835821, -1.580085847e-006, 9.61311115e-010, -2.392381918e-013}, blow = {43852.1524, 10.72781921}, ahigh = {8810382.649999999, -27112.32975, 34.7658866, -0.01861104581, 5.290283900000001e-006, -6.58540806e-010, 2.997850429e-014}, bhigh = {216246.0097, -222.5618519}, R_s = R_NASA_2002/Sc.MM);
          constant IdealGases.Common.DataRecord Scplus(name = "Scplus", MM = 0.0449553614, Hf = 22625671.11739424, H0 = 159311.8546256421, Tlimit = 1000, alow = {-5884.93016, 147.9044408, 2.009576456, 0.000738956697, -6.61796482e-007, 6.84107376e-010, -2.164125532e-013}, blow = {120843.9139, 10.2657062}, ahigh = {1973658.531, -4954.3841, 6.36062735, -0.000716878592, 2.464991123e-008, 9.632373790000001e-012, -8.544709642000001e-016}, bhigh = {154342.3764, -22.61925782}, R_s = R_NASA_2002/Scplus.MM);
          constant IdealGases.Common.DataRecord Scminus(name = "Scminus", MM = 0.0449564586, Hf = 7842228.65810876, H0 = 137854.0079222344, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {41657.4639, 8.270420720000001}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {41657.4639, 8.270420720000001}, R_s = R_NASA_2002/Scminus.MM);
          constant IdealGases.Common.DataRecord ScO(name = "ScO", MM = 0.06095531, Hf = -903371.5684490819, H0 = 144156.5304154798, Tlimit = 1000, alow = {-3136.784613, 227.1981685, 0.885075732, 0.01052430774, -1.431954596e-005, 9.652351069999999e-009, -2.586210633e-012}, blow = {-8550.798769999999, 20.12706847}, ahigh = {1224192.443, -3918.91572, 8.679848809999999, -0.001995893306, 4.06698985e-007, -1.504459913e-011, -8.4729989e-016}, bhigh = {16773.22594, -29.51656272}, R_s = R_NASA_2002/ScO.MM);
          constant IdealGases.Common.DataRecord ScOplus(name = "ScOplus", MM = 0.0609547614, Hf = 9206991.432830053, H0 = 143993.1155238678, Tlimit = 1000, alow = {45885.6027, -336.711437, 3.5272064, 0.0039888503, -5.568985429999999e-006, 3.65028119e-009, -9.356491500000001e-013}, blow = {68383.5079, 4.3398127}, ahigh = {-1814357.141, 5853.42532, -3.65710121, 0.00573436451, -2.092878161e-006, 3.69564502e-010, -2.214038347e-014}, bhigh = {29553.64078, 56.6088941}, R_s = R_NASA_2002/ScOplus.MM);
          constant IdealGases.Common.DataRecord ScO2(name = "ScO2", MM = 0.07695471000000001, Hf = -5375248.207679556, H0 = 139720.2718326143, Tlimit = 1000, alow = {47947.00960000001, -429.835859, 3.4172065, 0.01361338544, -2.047465023e-005, 1.455906041e-008, -4.03808769e-012}, blow = {-48610.4953, 7.67001333}, ahigh = {-190390.2542, -231.558882, 7.17210491, -6.85920964e-005, 1.510998557e-008, -1.727951588e-012, 7.9889805e-017}, bhigh = {-51129.74750000001, -10.90764597}, R_s = R_NASA_2002/ScO2.MM);
          constant IdealGases.Common.DataRecord Sc2O(name = "Sc2O", MM = 0.10591122, Hf = -217580.4225463553, H0 = 110562.827998771, Tlimit = 1000, alow = {25500.02615, -307.7608607, 4.67121504, 0.008696142249999999, -1.283873116e-005, 8.988966810000001e-009, -2.461994147e-012}, blow = {-2614.951944, 2.92001718}, ahigh = {-135088.0396, -185.4540692, 7.13829408, -5.52943214e-005, 1.221589315e-008, -1.400490463e-012, 6.48885811e-017}, bhigh = {-4240.235140000001, -9.37271095}, R_s = R_NASA_2002/Sc2O.MM);
          constant IdealGases.Common.DataRecord Sc2O2(name = "Sc2O2", MM = 0.12191062, Hf = -4024022.02531658, H0 = 107732.8619934834, Tlimit = 1000, alow = {3468.44549, 261.7988314, -0.3052099624, 0.0307610407, -4.18347836e-005, 2.794218425e-008, -7.41267205e-012}, blow = {-61440.1321, 29.15248555}, ahigh = {-297734.8677, -580.367792, 10.43318377, -0.0001734165462, 3.83608979e-008, -4.403078029999999e-012, 2.042208922e-016}, bhigh = {-59648.6628, -28.55828369}, R_s = R_NASA_2002/Sc2O2.MM);
          constant IdealGases.Common.DataRecord Si(name = "Si", MM = 0.0280855, Hf = 16022502.71492407, H0 = 268831.1762297271, Tlimit = 1000, alow = {98.36140810000001, 154.6544523, 1.87643667, 0.001320637995, -1.529720059e-006, 8.95056277e-010, -1.95287349e-013}, blow = {52635.1031, 9.69828888}, ahigh = {-616929.885, 2240.683927, -0.444861932, 0.001710056321, -4.10771416e-007, 4.55888478e-011, -1.889515353e-015}, bhigh = {39535.5876, 26.79668061}, R_s = R_NASA_2002/Si.MM);
          constant IdealGases.Common.DataRecord Siplus(name = "Siplus", MM = 0.0280849514, Hf = 44241060.89070889, H0 = 261454.7874916387, Tlimit = 1000, alow = {-43297.9188, 679.5894490000001, 0.2257046144, 0.004118600490000001, -4.234881599999999e-006, 2.327995626e-009, -5.318388059e-013}, blow = {145203.9813, 19.3465051}, ahigh = {59193.9023, -48.5673095, 2.556312024, -3.50339716e-005, 1.190298787e-008, -2.082923821e-012, 1.471452049e-016}, bhigh = {149143.1392, 5.24426714}, R_s = R_NASA_2002/Siplus.MM);
          constant IdealGases.Common.DataRecord Siminus(name = "Siminus", MM = 0.0280860486, Hf = 10995406.73727952, H0 = 220658.5941747605, Tlimit = 1000, alow = {-794.014667, 5.56741842, 2.499837183, -9.48139446e-005, 3.17124693e-007, -4.19132318e-010, 2.03592438e-013}, blow = {36364.4338, 5.27011984}, ahigh = {-6162070.100000001, 18833.10402, -18.9930245, 0.01111021657, -2.535790208e-006, 2.699962923e-010, -1.105062911e-014}, bhigh = {-83140.8931, 159.5298253}, R_s = R_NASA_2002/Siminus.MM);
          constant IdealGases.Common.DataRecord SiBr(name = "SiBr", MM = 0.1079895, Hf = 1621985.665273013, H0 = 92926.82158913597, Tlimit = 1000, alow = {7370.283350000001, -505.106296, 8.280591039999999, -0.0100538392, 1.35705092e-005, -9.1154499e-009, 2.447477685e-012}, blow = {21844.05475, -16.62032657}, ahigh = {1317799.94, -3669.79502, 8.51168612, -0.001987602041, 5.03541489e-007, -4.49012019e-011, 8.23567007e-016}, bhigh = {43328.5155, -24.67075472}, R_s = R_NASA_2002/SiBr.MM);
          constant IdealGases.Common.DataRecord SiBr2(name = "SiBr2", MM = 0.1878935, Hf = -271430.3581550187, H0 = 70876.11333015778, Tlimit = 1000, alow = {23866.16151, -641.569347, 9.34587911, -0.00479290414, 5.58253847e-006, -3.45531238e-009, 8.80033894e-013}, blow = {-5014.75702, -17.40767596}, ahigh = {-51473.4394, -12.77719997, 7.01020224, -4.29633186e-006, 9.877651970000001e-010, -1.168133105e-013, 5.54668138e-018}, bhigh = {-8319.54225, -3.61182661}, R_s = R_NASA_2002/SiBr2.MM);
          constant IdealGases.Common.DataRecord SiBr3(name = "SiBr3", MM = 0.2677975, Hf = -586263.8747561124, H0 = 65203.89473389407, Tlimit = 1000, alow = {39728.0686, -1066.475023, 13.80836232, -0.00764111472, 8.77586583e-006, -5.37243085e-009, 1.356453455e-012}, blow = {-16517.95623, -37.8405537}, ahigh = {-88880.24740000001, -22.67879074, 10.01791167, -7.48115075e-006, 1.70924269e-009, -2.011596627e-013, 9.51553415e-018}, bhigh = {-22030.26938, -15.37574366}, R_s = R_NASA_2002/SiBr3.MM);
          constant IdealGases.Common.DataRecord SiBr4(name = "SiBr4", MM = 0.3477015, Hf = -1195853.33971812, H0 = 64174.93453436353, Tlimit = 1000, alow = {68210.8674, -1520.370776, 18.1045336, -0.00973468842, 1.072367466e-005, -6.34385829e-009, 1.5572282e-012}, blow = {-46165.8521, -59.7612063}, ahigh = {-127140.9281, -37.6808795, 13.02910642, -1.194958251e-005, 2.693843051e-009, -3.137193207e-013, 1.471642663e-017}, bhigh = {-54089.9883, -29.4038433}, R_s = R_NASA_2002/SiBr4.MM);
          constant IdealGases.Common.DataRecord SiC(name = "SiC", MM = 0.04009620000000001, Hf = 18329570.88202872, H0 = 229874.9258034427, Tlimit = 1000, alow = {-6223.330889999999, 314.1790457, 0.389313083, 0.0118750754, -1.639277197e-005, 1.131808223e-008, -3.045324231e-012}, blow = {86062.2773, 23.10166717}, ahigh = {-62688.06030000001, 720.983692, 2.162879732, 0.002201299585, -6.569466590000001e-007, 9.177110259999999e-011, -4.96916674e-015}, bhigh = {83212.2585, 16.01675317}, R_s = R_NASA_2002/SiC.MM);
          constant IdealGases.Common.DataRecord SiC2(name = "SiC2", MM = 0.05210690000000001, Hf = 12116647.46895325, H0 = 224258.3803680511, Tlimit = 1000, alow = {-41196.2899, 686.9747180000001, 0.02361343691, 0.01532939217, -1.435588838e-005, 6.37522874e-009, -1.059204957e-012}, blow = {71308.9071, 28.28850316}, ahigh = {7026893.09, -24661.48437, 39.15453030000001, -0.02002884068, 6.30735369e-006, -8.84838351e-010, 4.53054985e-014}, bhigh = {226732.5155, -236.6622024}, R_s = R_NASA_2002/SiC2.MM);
          constant IdealGases.Common.DataRecord SiCL(name = "SiCL", MM = 0.0635385, Hf = 2240581.993594435, H0 = 155561.100749939, Tlimit = 1000, alow = {12485.08319, -204.4170347, 4.97707085, -0.0005160756260000001, 2.931980374e-007, -3.66661523e-012, -3.39303713e-014}, blow = {16865.28019, -0.226395724}, ahigh = {376729.456, -1147.956509, 5.73540843, -0.0005784890810000001, 1.517304648e-007, -1.291391394e-011, 1.55462842e-016}, bhigh = {23062.78401, -6.098515228}, R_s = R_NASA_2002/SiCL.MM);
          constant IdealGases.Common.DataRecord SiCL2(name = "SiCL2", MM = 0.0989915, Hf = -1647305.950510903, H0 = 126569.392321563, Tlimit = 1000, alow = {53055.5097, -1015.842786, 10.32848185, -0.00621226752, 6.7158254e-006, -3.90880164e-009, 9.46173215e-013}, blow = {-16502.18093, -26.49925756}, ahigh = {-80508.7157, -26.61025523, 7.02041472, -8.335824719999999e-006, 1.871092411e-009, -2.171552767e-013, 1.015849895e-017}, bhigh = {-21812.94885, -6.638764238}, R_s = R_NASA_2002/SiCL2.MM);
          constant IdealGases.Common.DataRecord SiCL3(name = "SiCL3", MM = 0.1344445, Hf = -2501193.20611851, H0 = 116906.7310302764, Tlimit = 1000, alow = {86917.08459999999, -1677.556857, 15.1151906, -0.008937031, 9.097353529999999e-006, -5.01457996e-009, 1.155962016e-012}, blow = {-34774.773, -50.87215506}, ahigh = {-147718.0114, -53.3520098, 10.04043521, -1.63512106e-005, 3.64194011e-009, -4.20060059e-013, 1.955201587e-017}, bhigh = {-43605.7165, -20.06632444}, R_s = R_NASA_2002/SiCL3.MM);
          constant IdealGases.Common.DataRecord SiCL4(name = "SiCL4", MM = 0.1698975, Hf = -3897644.16780706, H0 = 114512.797421975, Tlimit = 1000, alow = {117164.6285, -2185.821461, 19.08250496, -0.00963633572, 8.836847690000002e-006, -4.3600424e-009, 8.94023243e-013}, blow = {-72128.0211, -73.01532221000001}, ahigh = {-210033.0761, -84.76107710000001, 13.06364027, -2.55402042e-005, 5.65381847e-009, -6.48875267e-013, 3.008025543e-017}, bhigh = {-83722.6813, -35.92584781}, R_s = R_NASA_2002/SiCL4.MM);
          constant IdealGases.Common.DataRecord SiF(name = "SiF", MM = 0.0470839032, Hf = -535908.9685665653, H0 = 200835.3886854478, Tlimit = 1000, alow = {14782.23768, 13.57998649, 2.324182643, 0.00713285118, -1.022951215e-005, 7.14839647e-009, -1.964689785e-012}, blow = {-3995.38065, 12.31128121}, ahigh = {-365363.788, 872.2860040000001, 3.37721827, 0.000750815243, -2.308898619e-007, 3.7667818e-011, -2.143080403e-015}, bhigh = {-10116.97664, 8.968132819999999}, R_s = R_NASA_2002/SiF.MM);
          constant IdealGases.Common.DataRecord SiFCL(name = "SiFCL", MM = 0.0825369032, Hf = -4577667.701978914, H0 = 143364.7682579882, Tlimit = 1000, alow = {41769.5464, -592.6575380000001, 6.40977071, 0.00464168261, -7.978461910000001e-006, 6.00872837e-009, -1.720953157e-012}, blow = {-43982.9607, -6.259737448}, ahigh = {-128469.8945, -124.7550173, 7.09289385, -3.70731177e-005, 8.175173009999999e-009, -9.35643521e-013, 4.32854434e-017}, bhigh = {-47233.0972, -8.337392707999999}, R_s = R_NASA_2002/SiFCL.MM);
          constant IdealGases.Common.DataRecord SiF2(name = "SiF2", MM = 0.0660823064, Hf = -8971207.881448884, H0 = 169553.2527599551, Tlimit = 1000, alow = {40532.3665, -399.763756, 4.05530388, 0.01153423049, -1.757586754e-005, 1.260369111e-008, -3.51710522e-012}, blow = {-70477.7046, 3.87985442}, ahigh = {-167520.0202, -184.621209, 7.13698635, -5.45076986e-005, 1.199012961e-008, -1.369470187e-012, 6.32488999e-017}, bhigh = {-72874.0102, -11.17933348}, R_s = R_NASA_2002/SiF2.MM);
          constant IdealGases.Common.DataRecord SiF3(name = "SiF3", MM = 0.08508070960000001, Hf = -11711662.74569953, H0 = 153014.1680905774, Tlimit = 1000, alow = {57553.6998, -717.959577, 5.37939694, 0.01813065142, -2.738373356e-005, 1.94651947e-008, -5.39079056e-012}, blow = {-117763.1169, -3.44290204}, ahigh = {-290328.3702, -342.787694, 10.25536335, -0.000101979669, 2.250326132e-008, -2.577117181e-012, 1.192923177e-016}, bhigh = {-121808.8967, -27.25261142}, R_s = R_NASA_2002/SiF3.MM);
          constant IdealGases.Common.DataRecord SiF4(name = "SiF4", MM = 0.1040791128, Hf = -15524536.638825, H0 = 147634.9344899489, Tlimit = 1000, alow = {10696.70784, -95.69638640000001, 2.513988593, 0.0330978103, -4.57304408e-005, 3.091834452e-008, -8.26930405e-012}, blow = {-195625.2529, 11.33722022}, ahigh = {-384589.232, -656.997991, 13.4892572, -5.10047136e-005, 5.34632958e-008, -4.95959811e-012, 2.299314375e-016}, bhigh = {-195728.4479, -46.7389465}, R_s = R_NASA_2002/SiF4.MM);
          constant IdealGases.Common.DataRecord SiH(name = "SiH", MM = 0.02909344, Hf = 12670767.36198951, H0 = 314335.809034614, Tlimit = 1000, alow = {-6426.676299999999, 74.17251210000001, 3.9734916, -0.00414940888, 1.022918384e-005, -8.592386360000002e-009, 2.567093743e-012}, blow = {42817.45800000001, 2.24693715}, ahigh = {404208.649, -2364.796524, 7.62749914, -0.002496591233, 1.10843641e-006, -1.943991955e-010, 1.136251507e-014}, bhigh = {57047.3768, -24.48054429}, R_s = R_NASA_2002/SiH.MM);
          constant IdealGases.Common.DataRecord SiHplus(name = "SiHplus", MM = 0.0290928914, Hf = 39448508.27030551, H0 = 297469.951714734, Tlimit = 1000, alow = {-43071.5717, 388.495824, 2.546166863, -0.0006686325980000001, 5.186277020000001e-006, -4.81856974e-009, 1.44570264e-012}, blow = {134907.9707, 9.027950089999999}, ahigh = {171169.2033, -1045.807287, 4.83864824, 0.0001277940891, -6.883872450000001e-008, 1.41884348e-011, -7.85531696e-016}, bhigh = {143172.145, -7.55329914}, R_s = R_NASA_2002/SiHplus.MM);
          constant IdealGases.Common.DataRecord SiHBr3(name = "SiHBr3", MM = 0.26880544, Hf = -1126919.157588478, H0 = 66306.05764526196, Tlimit = 1000, alow = {132281.1122, -2205.365507, 17.75084194, -0.01047794569, 1.286821723e-005, -7.743124260000001e-009, 1.819060891e-012}, blow = {-28349.92682, -63.3119954}, ahigh = {219997.3526, -2024.458552, 14.35781007, -0.000503701584, 1.054049755e-007, -1.160828765e-011, 5.21725768e-016}, bhigh = {-28420.86214, -45.3643717}, R_s = R_NASA_2002/SiHBr3.MM);
          constant IdealGases.Common.DataRecord SiHCL(name = "SiHCL", MM = 0.06454644000000001, Hf = 851261.7117225983, H0 = 165236.2701955367, Tlimit = 1000, alow = {59096.73050000001, -878.006403, 7.99968793, -0.00466314127, 8.594986e-006, -6.608073550000001e-009, 1.868076396e-012}, blow = {9567.57034, -16.90014311}, ahigh = {101215.289, -1163.239598, 7.37636655, 0.0001874151313, -1.661351093e-007, 3.96441404e-011, -2.64058008e-015}, bhigh = {11410.64087, -15.07678798}, R_s = R_NASA_2002/SiHCL.MM);
          constant IdealGases.Common.DataRecord SiHCL3(name = "SiHCL3", MM = 0.13545244, Hf = -3663440.835764937, H0 = 119241.912511875, Tlimit = 1000, alow = {165956.5586, -2552.498122, 17.50117375, -0.007885728660000001, 8.092567490000001e-006, -3.9804206e-009, 7.05917332e-013}, blow = {-49513.16600000001, -67.58519052999999}, ahigh = {172864.4072, -2116.727327, 14.41802307, -0.000525524962, 1.098826178e-007, -1.209327059e-011, 5.432187049999999e-016}, bhigh = {-51303.5194, -50.36360893000001}, R_s = R_NASA_2002/SiHCL3.MM);
          constant IdealGases.Common.DataRecord SiHF(name = "SiHF", MM = 0.0480918432, Hf = -3382219.482076328, H0 = 212722.7887160707, Tlimit = 1000, alow = {21925.98671, -61.7522908, 2.127372739, 0.01123538312, -1.322503985e-005, 8.30730739e-009, -2.010545971e-012}, blow = {-20169.94845, 13.67184876}, ahigh = {4049752.24, -9295.526819999999, 10.71754366, 0.00186812422, -1.129820372e-006, 1.9602501e-010, -1.144682011e-014}, bhigh = {41332.252, -47.363176}, R_s = R_NASA_2002/SiHF.MM);
          constant IdealGases.Common.DataRecord SiHF3(name = "SiHF3", MM = 0.0860886496, Hf = -13948505.47173643, H0 = 157333.5632854439, Tlimit = 1000, alow = {83258.7939, -817.8594459999999, 4.04171724, 0.02726104628, -3.78783148e-005, 2.630589305e-008, -7.2895825e-012}, blow = {-141614.6961, 1.382806532}, ahigh = {78201.008, -2592.742261, 14.75104214, -0.00065310472, 1.372428937e-007, -1.516371051e-011, 6.83249715e-016}, bhigh = {-133661.1887, -58.5145095}, R_s = R_NASA_2002/SiHF3.MM);
          constant IdealGases.Common.DataRecord SiHI3(name = "SiHI3", MM = 0.40980685, Hf = -181731.9549441402, H0 = 46693.76317160145, Tlimit = 1000, alow = {111384.0054, -1974.457175, 17.91396249, -0.01219208519, 1.613169233e-005, -1.038096942e-008, 2.613287761e-012}, blow = {-2256.377425, -59.9545513}, ahigh = {227942.4252, -1898.603142, 14.28134804, -0.000477602695, 1.003097496e-007, -1.107859145e-011, 4.990338200000001e-016}, bhigh = {-1614.547674, -41.2294307}, R_s = R_NASA_2002/SiHI3.MM);
          constant IdealGases.Common.DataRecord SiH2(name = "SiH2", MM = 0.03010138, Hf = 9080398.639530813, H0 = 332812.05047742, Tlimit = 1000, alow = {-20638.63564, 330.58622, 2.099271145, 0.00354253937, 3.37887667e-006, -5.38384562e-009, 2.081191273e-012}, blow = {30117.84298, 12.8233357}, ahigh = {4624039.37, -11434.3611, 12.6488087, 0.00091148995, -8.766611539999999e-007, 1.646297357e-010, -9.965090370000001e-015}, bhigh = {107247.5101, -66.0607807}, R_s = R_NASA_2002/SiH2.MM);
          constant IdealGases.Common.DataRecord SiH2Br2(name = "SiH2Br2", MM = 0.18990938, Hf = -1002436.003950937, H0 = 75152.80182579713, Tlimit = 1000, alow = {165152.8003, -2468.145554, 16.08639427, -0.0094138409, 1.407423872e-005, -9.240751449999999e-009, 2.255641666e-012}, blow = {-12764.82614, -59.4537432}, ahigh = {566585.144, -3973.91962, 15.67387912, -0.0009943802290000002, 2.084856022e-007, -2.299521351e-011, 1.034736283e-015}, bhigh = {-2990.69018, -61.9047652}, R_s = R_NASA_2002/SiH2Br2.MM);
          constant IdealGases.Common.DataRecord SiH2CL2(name = "SiH2CL2", MM = 0.10100738, Hf = -3172976.073629472, H0 = 132514.5548770793, Tlimit = 1000, alow = {189428.1754, -2650.960252, 15.49874174, -0.006533130749999999, 9.306098260000001e-006, -5.63969867e-009, 1.213664264e-012}, blow = {-27209.12007, -60.06331649}, ahigh = {540020.458, -4062.33729, 15.73118788, -0.001015038389, 2.127060243e-007, -2.345079226e-011, 1.054871984e-015}, bhigh = {-18230.98225, -65.44540499}, R_s = R_NASA_2002/SiH2CL2.MM);
          constant IdealGases.Common.DataRecord SiH2F2(name = "SiH2F2", MM = 0.0680981864, Hf = -11612291.63072102, H0 = 176042.9555286953, Tlimit = 1000, alow = {127218.8427, -1241.72431, 4.89943589, 0.02123882008, -2.7257087e-005, 1.860857446e-008, -5.22660433e-012}, blow = {-89804.66919999999, -5.1118155}, ahigh = {472653.4080000001, -4388.51769, 15.96032597, -0.001102993658, 2.315838331e-007, -2.556974559e-011, 1.151499711e-015}, bhigh = {-73161.8446, -70.9898927}, R_s = R_NASA_2002/SiH2F2.MM);
          constant IdealGases.Common.DataRecord SiH2I2(name = "SiH2I2", MM = 0.28391032, Hf = -134105.7274705618, H0 = 52542.17599416605, Tlimit = 1000, alow = {153996.3319, -2414.436989, 16.84409354, -0.0121203758, 1.808453226e-005, -1.207740133e-008, 3.040799276e-012}, blow = {5073.07325, -60.9872082}, ahigh = {594239.083, -3924.81448, 15.63850289, -0.0009805706340000001, 2.054871384e-007, -2.265587199e-011, 1.019168663e-015}, bhigh = {15136.27352, -59.4081252}, R_s = R_NASA_2002/SiH2I2.MM);
          constant IdealGases.Common.DataRecord SiH3(name = "SiH3", MM = 0.03110932, Hf = 6569007.80859241, H0 = 330350.8080536636, Tlimit = 1000, alow = {4341.14282, 227.7185085, 0.650825035, 0.01221438558, -4.34760427e-006, -1.774916828e-009, 1.184191367e-012}, blow = {22599.93826, 19.68347482}, ahigh = {605632.122, -4721.254059999999, 13.29129523, -0.001256824868, 2.68828594e-007, -3.010741582e-011, 1.370945857e-015}, bhigh = {49744.2064, -61.405031}, R_s = R_NASA_2002/SiH3.MM);
          constant IdealGases.Common.DataRecord SiH3Br(name = "SiH3Br", MM = 0.11101332, Hf = -704789.2991579749, H0 = 106017.7103071956, Tlimit = 1000, alow = {152106.5525, -1987.744479, 11.31460743, -0.001806099407, 7.76926247e-006, -6.233478169999999e-009, 1.585331846e-012}, blow = {-924.886888, -38.4646369}, ahigh = {927928.578, -5917.93579, 16.99209298, -0.001487507364, 3.123451161e-007, -3.44907147e-011, 1.553431675e-015}, bhigh = {22415.60128, -79.4861159}, R_s = R_NASA_2002/SiH3Br.MM);
          constant IdealGases.Common.DataRecord SiH3CL(name = "SiH3CL", MM = 0.06656231999999999, Hf = -2130905.292964548, H0 = 171879.615974924, Tlimit = 1000, alow = {163338.8301, -2030.302118, 10.68016138, 0.0004942370140000001, 4.30517476e-006, -3.74832727e-009, 8.89350421e-013}, blow = {-8180.71498, -36.88956824}, ahigh = {908778.094, -5958.94956, 17.02076016, -0.001498450667, 3.146813781e-007, -3.47516846e-011, 1.565281681e-015}, bhigh = {14937.93206, -81.27277864}, R_s = R_NASA_2002/SiH3CL.MM);
          constant IdealGases.Common.DataRecord SiH3F(name = "SiH3F", MM = 0.0501077232, Hf = -7515009.183255008, H0 = 218162.4169265787, Tlimit = 1000, alow = {126783.629, -1177.593516, 4.49918896, 0.01658543011, -1.678598921e-005, 1.019153931e-008, -2.803920232e-012}, blow = {-40103.9297, -4.48108092}, ahigh = {862431.317, -6103.37057, 17.12733597, -0.001540724131, 3.23962872e-007, -3.58105689e-011, 1.61415138e-015}, bhigh = {-12614.87616, -83.99227209999999}, R_s = R_NASA_2002/SiH3F.MM);
          constant IdealGases.Common.DataRecord SiH3I(name = "SiH3I", MM = 0.15801379, Hf = -13239.35081868488, H0 = 76437.81596530277, Tlimit = 1000, alow = {145938.4799, -1982.982746, 11.96516737, -0.00393750595, 1.087991733e-005, -8.43313592e-009, 2.196078188e-012}, blow = {8063.20831, -40.6455332}, ahigh = {936114.918, -5859.72029, 16.95376698, -0.00147349713, 3.094475885e-007, -3.41746247e-011, 1.539334807e-015}, bhigh = {31274.99231, -78.01700080000001}, R_s = R_NASA_2002/SiH3I.MM);
          constant IdealGases.Common.DataRecord SiH4(name = "SiH4", MM = 0.03211726, Hf = 1080415.950800286, H0 = 328016.8046713823, Tlimit = 1000, alow = {78729.9329, -552.608705, 2.498944303, 0.01442118274, -8.467107309999999e-006, 2.726164641e-009, -5.43675437e-013}, blow = {6269.66906, 4.96546183}, ahigh = {1290378.74, -7813.39978, 18.28851664, -0.001975620946, 4.15650215e-007, -4.59674561e-011, 2.072777131e-015}, bhigh = {47668.8795, -98.0169746}, R_s = R_NASA_2002/SiH4.MM);
          constant IdealGases.Common.DataRecord SiI(name = "SiI", MM = 0.15498997, Hf = 1696583.462787947, H0 = 64140.40856966423, Tlimit = 1000, alow = {94920.8134, -1573.960062, 12.37908109, -0.0159386482, 1.692049005e-005, -9.215558319999999e-009, 2.046186848e-012}, blow = {37797.3567, -40.6640785}, ahigh = {852940.2790000001, -2442.039471, 7.72297752, -0.001985601243, 6.542866629999999e-007, -9.49415829e-011, 4.89004137e-015}, bhigh = {45781.6094, -17.33975081}, R_s = R_NASA_2002/SiI.MM);
          constant IdealGases.Common.DataRecord SiI2(name = "SiI2", MM = 0.28189444, Hf = 328016.4021681308, H0 = 48927.9426724415, Tlimit = 1000, alow = {11633.52403, -451.448217, 8.707978130000001, -0.00358066493, 4.25371443e-006, -2.673478266e-009, 6.89155898e-013}, blow = {11262.47142, -11.55818335}, ahigh = {10021.68907, 14.33017148, 6.70133055, 0.00039607699, -2.073866165e-007, 4.5534571e-011, -3.01679828e-015}, bhigh = {9007.368100000002, 0.2887336913}, R_s = R_NASA_2002/SiI2.MM);
          constant IdealGases.Common.DataRecord SiN(name = "SiN", MM = 0.0420922, Hf = 9590100.707494499, H0 = 207547.6454069876, Tlimit = 1000, alow = {-14646.72152, 137.4993497, 3.67850858, -0.0061584992, 2.309417067e-005, -2.294461481e-008, 7.39566568e-012}, blow = {46732.1299, 6.494564115}, ahigh = {-2932685.132, 5853.68859, 1.321451677, 0.001258329284, -3.77388636e-007, 6.88776104e-011, -4.18984259e-015}, bhigh = {6527.14881, 25.53145732}, R_s = R_NASA_2002/SiN.MM);
          constant IdealGases.Common.DataRecord SiO(name = "SiO", MM = 0.0440849, Hf = -2242092.371764482, H0 = 197689.1180426858, Tlimit = 1000, alow = {-47227.7105, 806.3137640000001, -1.636976133, 0.01454275546, -1.723202046e-005, 1.04239734e-008, -2.559365273e-012}, blow = {-16665.85903, 33.557957}, ahigh = {-176513.4162, -31.9917709, 4.47744193, 4.59176471e-006, 3.55814315e-008, -1.327012559e-011, 1.613253297e-015}, bhigh = {-13508.4236, -0.838695733}, R_s = R_NASA_2002/SiO.MM);
          constant IdealGases.Common.DataRecord SiO2(name = "SiO2", MM = 0.0600843, Hf = -5360359.977564856, H0 = 175462.1922865041, Tlimit = 1000, alow = {-33629.4878, 473.407892, 0.2309770671, 0.01850230806, -2.242786671e-005, 1.364981554e-008, -3.35193503e-012}, blow = {-42264.8749, 22.95803206}, ahigh = {-146403.1193, -626.144106, 7.96456371, -0.0001854119096, 4.09521467e-008, -4.69720676e-012, 2.17805428e-016}, bhigh = {-37918.3477, -20.45285414}, R_s = R_NASA_2002/SiO2.MM);
          constant IdealGases.Common.DataRecord SiS(name = "SiS", MM = 0.0601505, Hf = 1798728.306497868, H0 = 148495.9726020565, Tlimit = 1000, alow = {35994.4929, -423.9723299999999, 4.65401442, 0.001588470782, -3.31025436e-006, 2.706096479e-009, -8.113517820000001e-013}, blow = {14115.15571, -1.183201858}, ahigh = {-2102323.897, 6228.83618, -3.004120882, 0.004495499930000001, -1.368821364e-006, 1.998097253e-010, -9.882035800000001e-015}, bhigh = {-27955.38166, 54.05828786}, R_s = R_NASA_2002/SiS.MM);
          constant IdealGases.Common.DataRecord SiS2(name = "SiS2", MM = 0.09221550000000001, Hf = 76155.49446676533, H0 = 132333.6857686614, Tlimit = 1000, alow = {43977.4566, -743.001312, 7.94158836, 0.00203808373, -4.6463376e-006, 3.84801436e-009, -1.157260149e-012}, blow = {2801.077853, -17.36888325}, ahigh = {-126648.9071, -97.7423522, 7.57280368, -2.905413928e-005, 6.40558784e-009, -7.329273340000001e-013, 3.38981978e-017}, bhigh = {-1244.672263, -13.52710463}, R_s = R_NASA_2002/SiS2.MM);
          constant IdealGases.Common.DataRecord Si2(name = "Si2", MM = 0.056171, Hf = 10329093.73164088, H0 = 183299.6386035499, Tlimit = 1000, alow = {12375.96221, -102.4904376, 4.35484852, 0.001281063335, -2.531991623e-006, 2.265694244e-009, -7.001290140000001e-013}, blow = {69069.4285, 3.2511252}, ahigh = {1370060.657, -4207.06004, 9.337432890000001, -0.002749217168, 9.586345959999999e-007, -1.372449748e-010, 6.765028100000001e-015}, bhigh = {95108.84539999999, -31.6838519}, R_s = R_NASA_2002/Si2.MM);
          constant IdealGases.Common.DataRecord Si2C(name = "Si2C", MM = 0.06818170000000001, Hf = 8126724.678322773, H0 = 169874.7024494842, Tlimit = 1000, alow = {-4553.3662, 131.4796415, 2.469106923, 0.0127652068, -1.656910776e-005, 1.065289663e-008, -2.739192976e-012}, blow = {64700.4992, 14.6883898}, ahigh = {-125382.9442, -341.427779, 7.25436533, -0.0001017635503, 2.250902158e-008, -2.584074852e-012, 1.198884876e-016}, bhigh = {66080.0938, -11.46216579}, R_s = R_NASA_2002/Si2C.MM);
          constant IdealGases.Common.DataRecord Si2F6(name = "Si2F6", MM = 0.1701614192, Hf = -14006054.31715863, H0 = 156876.2891465118, Tlimit = 1000, alow = {15807.6745, -297.5292881, 7.5125915, 0.0455279623, -6.42187684e-005, 4.357408730000001e-008, -1.166762282e-011}, blow = {-288670.7444, -7.72178477}, ahigh = {-918630.314, 157.3948683, 21.41256129, -0.0002681898667, 7.21228011e-008, -9.18425266e-012, 4.53723836e-016}, bhigh = {-296617.6753, -78.4902247}, R_s = R_NASA_2002/Si2F6.MM);
          constant IdealGases.Common.DataRecord Si2N(name = "Si2N", MM = 0.0701777, Hf = 5663907.480581439, H0 = 168460.7503523199, Tlimit = 1000, alow = {23182.71938, -367.484379, 5.4096586, 0.008176389399999999, -1.220312934e-005, 8.5806091e-009, -2.354927059e-012}, blow = {48092.7803, -3.042205654}, ahigh = {-280502.6986, 250.2366876, 7.0924561, 0.0002853120795, -9.79210181e-008, 1.552154244e-011, -8.03626045e-016}, bhigh = {43420.1479, -10.0957091}, R_s = R_NASA_2002/Si2N.MM);
          constant IdealGases.Common.DataRecord Si3(name = "Si3", MM = 0.0842565, Hf = 7451856.901247975, H0 = 148591.4202465092, Tlimit = 1000, alow = {-11142.08177, 157.5785843, 2.486135003, 0.01631637255, -2.208240021e-005, 1.372008287e-008, -3.2623307e-012}, blow = {73282.53850000001, 15.88081347}, ahigh = {-1699395.561, 4697.81538, 2.618198124, 0.001959082075, -2.581160603e-007, 6.10344486e-012, 6.08630924e-016}, bhigh = {42779.1681, 25.86540384}, R_s = R_NASA_2002/Si3.MM);
          constant IdealGases.Common.DataRecord Sn(name = "Sn", MM = 0.11871, Hf = 2537275.713924691, H0 = 52352.05964114227, Tlimit = 1000, alow = {-124869.2263, 1618.84119, -4.60239735, 0.01045433308, 2.99826555e-006, -1.068699386e-008, 4.32342131e-012}, blow = {27483.64008, 48.0506723}, ahigh = {-5145695.64, 11405.75108, -4.17963206, 0.002236390679, -3.60321977e-007, 2.440237836e-011, -2.937628285e-016}, bhigh = {-42150.1357, 59.81450930000001}, R_s = R_NASA_2002/Sn.MM);
          constant IdealGases.Common.DataRecord Snplus(name = "Snplus", MM = 0.1187094514, Hf = 8558290.144705359, H0 = 52206.6939650603, Tlimit = 1000, alow = {-5571.29778, 122.2323189, 1.566361415, 0.00339706141, -6.31292229e-006, 5.58545208e-009, -1.68902134e-012}, blow = {120902.412, 11.62634765}, ahigh = {4622916.850000001, -11859.58712, 12.37026473, -0.002773624217, 3.09851349e-007, -5.362951439999999e-012, -8.663474691e-016}, bhigh = {199432.2977, -68.3710828}, R_s = R_NASA_2002/Snplus.MM);
          constant IdealGases.Common.DataRecord Snminus(name = "Snminus", MM = 0.1187105486, Hf = 1512047.169496444, H0 = 54674.57674608034, Tlimit = 1000, alow = {272279.6, -3369.9358, 17.43906405, -0.02810527618, 2.790684767e-005, -1.442400675e-008, 3.070159757e-012}, blow = {37532.2775, -80.0785697}, ahigh = {-64477.1322, 743.05551, 1.921380256, 0.0002361623997, -5.28066836e-008, 6.10233938e-012, -2.843422486e-016}, bhigh = {16457.39414, 12.65436865}, R_s = R_NASA_2002/Snminus.MM);
          constant IdealGases.Common.DataRecord SnBr(name = "SnBr", MM = 0.198614, Hf = 380859.4560302899, H0 = 50279.03370356571, Tlimit = 1000, alow = {25641.93542, -525.912233, 7.68741069, -0.009654205420000001, 1.482863248e-005, -9.94223698e-009, 2.475051091e-012}, blow = {10204.83889, -11.26550396}, ahigh = {1815578.541, -6728.26458, 13.32464516, -0.0046081023, 1.236439537e-006, -1.528863587e-010, 6.971513500000001e-015}, bhigh = {49255.8309, -56.4096278}, R_s = R_NASA_2002/SnBr.MM);
          constant IdealGases.Common.DataRecord SnBr2(name = "SnBr2", MM = 0.278518, Hf = -427170.2080296426, H0 = 52403.82309222384, Tlimit = 1000, alow = {-4995.75306, -136.6498896, 7.54356385, -0.001181772507, 1.442445852e-006, -9.254217260000001e-010, 2.423731634e-013}, blow = {-15755.06969, -3.59558402}, ahigh = {-19408.94091, -2.335607932, 7.00196926, -8.622241869999999e-007, 2.039869794e-010, -2.464780359e-014, 1.189850894e-018}, bhigh = {-16448.28122, -0.434935475}, R_s = R_NASA_2002/SnBr2.MM);
          constant IdealGases.Common.DataRecord SnBr3(name = "SnBr3", MM = 0.358422, Hf = -442820.0445285167, H0 = 53792.60759663191, Tlimit = 1000, alow = {-8050.41647, -289.7962523, 11.14443355, -0.002475383807, 3.01005135e-006, -1.92569532e-009, 5.032605089999999e-013}, blow = {-20700.66649, -18.95965383}, ahigh = {-38930.0453, -4.99084417, 10.00418437, -1.82499691e-006, 4.30564666e-010, -5.19188793e-014, 2.502455595e-018}, bhigh = {-22172.99473, -12.29854098}, R_s = R_NASA_2002/SnBr3.MM);
          constant IdealGases.Common.DataRecord SnBr4(name = "SnBr4", MM = 0.4383260000000001, Hf = -739670.8887905348, H0 = 57133.31629882781, Tlimit = 1000, alow = {-5832.84092, -427.019847, 14.67466525, -0.00360426323, 4.366686289999999e-006, -2.78587513e-009, 7.26508787e-013}, blow = {-40829.1645, -34.4710436}, ahigh = {-51768.1292, -7.42612695, 13.00619502, -2.692587978e-006, 6.3367598e-010, -7.62708719e-014, 3.671112e-018}, bhigh = {-43001.6634, -24.71455118}, R_s = R_NASA_2002/SnBr4.MM);
          constant IdealGases.Common.DataRecord SnCL(name = "SnCL", MM = 0.154163, Hf = 224819.2886749739, H0 = 62557.91597205554, Tlimit = 1000, alow = {33515.4973, -683.220862, 8.39391773, -0.01164434373, 1.812159499e-005, -1.26199917e-008, 3.29521347e-012}, blow = {6051.79089, -16.67834578}, ahigh = {774160.568, -3602.04848, 9.749059819999999, -0.002596198909, 6.36771216e-007, -6.75429557e-011, 2.484167602e-015}, bhigh = {24424.47662, -32.25454098}, R_s = R_NASA_2002/SnCL.MM);
          constant IdealGases.Common.DataRecord SnCL2(name = "SnCL2", MM = 0.189616, Hf = -1068729.869842207, H0 = 72154.86562315417, Tlimit = 1000, alow = {9524.6659, -432.984564, 8.64472028, -0.00345840961, 4.11785203e-006, -2.592639269e-009, 6.6923636e-013}, blow = {-24329.21127, -12.99143851}, ahigh = {-39035.88490000001, -7.94796268, 7.00648762, -2.776594714e-006, 6.461341420000001e-010, -7.1190674e-015, 3.68813118e-018}, bhigh = {-26545.29653, -3.368081174}, R_s = R_NASA_2002/SnCL2.MM);
          constant IdealGases.Common.DataRecord SnCL3(name = "SnCL3", MM = 0.225069, Hf = -1299034.76267278, H0 = 77994.05959950059, Tlimit = 1000, alow = {17600.76813, -814.280548, 13.06326984, -0.00639559619, 7.57462457e-006, -4.74971146e-009, 1.222182656e-012}, blow = {-34134.3096, -34.5767967}, ahigh = {-74829.66399999999, -15.28523914, 10.01240305, -5.28558124e-006, 1.226095111e-009, -1.459895108e-013, 6.96887978e-018}, bhigh = {-38308.7827, -16.63063137}, R_s = R_NASA_2002/SnCL3.MM);
          constant IdealGases.Common.DataRecord SnCL4(name = "SnCL4", MM = 0.260522, Hf = -1836566.466555608, H0 = 86265.38641650225, Tlimit = 1000, alow = {42459.6787, -1280.574318, 17.68445328, -0.00957477952, 1.115620323e-005, -6.90722927e-009, 1.759652856e-012}, blow = {-55040.09039999999, -58.27352999}, ahigh = {-107833.6862, -25.54305872, 13.02040391, -8.5951259e-006, 1.976570888e-009, -2.337929994e-013, 1.110287624e-017}, bhigh = {-61635.6203, -30.72702622}, R_s = R_NASA_2002/SnCL4.MM);
          constant IdealGases.Common.DataRecord SnF(name = "SnF", MM = 0.1377084032, Hf = -689987.5954701362, H0 = 66343.88162014502, Tlimit = 1000, alow = {60985.03520000001, -986.0306290000001, 8.994731209999999, -0.01223012156, 1.840583578e-005, -1.267926607e-008, 3.29133102e-012}, blow = {-7882.61448, -22.21921734}, ahigh = {25897.15476, -1484.478214, 7.37851893, -0.00132424444, 2.847634043e-007, -2.360371345e-011, 6.11678371e-016}, bhigh = {-4776.68897, -16.81202516}, R_s = R_NASA_2002/SnF.MM);
          constant IdealGases.Common.DataRecord SnF2(name = "SnF2", MM = 0.1567068064, Hf = -3260591.947077035, H0 = 78127.10424810239, Tlimit = 1000, alow = {70423.9185, -1137.505955, 10.08659352, -0.00472285593, 4.13570292e-006, -1.921143972e-009, 3.64076028e-013}, blow = {-57566.7082, -25.71566624}, ahigh = {-102775.8772, -44.5175162, 7.03326876, -1.329882797e-005, 2.934271938e-009, -3.35841592e-013, 1.553358669e-017}, bhigh = {-63621.2588, -6.81008452}, R_s = R_NASA_2002/SnF2.MM);
          constant IdealGases.Common.DataRecord SnF3(name = "SnF3", MM = 0.1757052096, Hf = -3680200.948350254, H0 = 84230.4051979572, Tlimit = 1000, alow = {109555.5529, -1950.557979, 15.41407832, -0.008546518770000001, 7.80055182e-006, -3.82594222e-009, 7.78774776e-013}, blow = {-70567.9492, -54.9463948}, ahigh = {-182931.9689, -75.5735868, 10.05671455, -2.275132668e-005, 5.03469582e-009, -5.77653096e-013, 2.67721417e-017}, bhigh = {-80918.97590000001, -21.91673972}, R_s = R_NASA_2002/SnF3.MM);
          constant IdealGases.Common.DataRecord SnF4(name = "SnF4", MM = 0.1947036128, Hf = -5263213.672632991, H0 = 96567.20144845716, Tlimit = 1000, alow = {139044.1119, -2168.784371, 16.91802917, -0.002318608529, -2.045847976e-006, 3.4300879e-009, -1.28922886e-012}, blow = {-115356.3396, -63.7060475}, ahigh = {-263569.2764, -144.5469969, 13.10690681, -4.23775579e-005, 9.28687195e-009, -1.057062694e-012, 4.86710868e-017}, bhigh = {-127153.9967, -38.039219}, R_s = R_NASA_2002/SnF4.MM);
          constant IdealGases.Common.DataRecord SnI(name = "SnI", MM = 0.24561447, Hf = 703236.3443407874, H0 = 41435.35191554471, Tlimit = 1000, alow = {26702.12235, -500.602635, 7.49067315, -0.008746346550000001, 1.289688397e-005, -8.211344929999999e-009, 1.936120475e-012}, blow = {21772.49172, -9.354806849999999}, ahigh = {-55549.91850000001, -1530.457453, 7.93260139, -0.002108885464, 7.8098036e-007, -1.348104887e-010, 8.207184700000001e-015}, bhigh = {27448.64953, -16.26822892}, R_s = R_NASA_2002/SnI.MM);
          constant IdealGases.Common.DataRecord SnI2(name = "SnI2", MM = 0.37251894, Hf = -21654.5687583026, H0 = 39953.03701873522, Tlimit = 1000, alow = {-5739.25489, -94.3502445, 7.37795666, -0.0008258348939999999, 1.01168704e-006, -6.5084516e-010, 1.7081866e-013}, blow = {-2622.6445, -0.960581496}, ahigh = {-15594.5339, -1.594789414, 7.00135116, -5.93532424e-007, 1.407432564e-010, -1.703457321e-014, 8.23361171e-019}, bhigh = {-3100.608319, 1.235038509}, R_s = R_NASA_2002/SnI2.MM);
          constant IdealGases.Common.DataRecord SnI3(name = "SnI3", MM = 0.49942341, Hf = -16053.59268200904, H0 = 40665.61477364467, Tlimit = 1000, alow = {-10699.78099, -138.769354, 10.55637633, -0.001216435658, 1.490873499e-006, -9.594499629999999e-010, 2.518810438e-013}, blow = {-3314.22988, -12.49558209}, ahigh = {-25175.3487, -2.34828289, 10.0019913, -8.752764839999999e-007, 2.07646498e-010, -2.514060336e-014, 1.215482266e-018}, bhigh = {-4017.05561, -9.26390846}, R_s = R_NASA_2002/SnI3.MM);
          constant IdealGases.Common.DataRecord SnI4(name = "SnI4", MM = 0.6263278800000001, Hf = -189763.2961828236, H0 = 42702.80447997939, Tlimit = 1000, alow = {-12831.46793, -145.9885093, 13.58634885, -0.001283554646, 1.574557147e-006, -1.013990168e-009, 2.66337043e-013}, blow = {-17511.78045, -23.67973168}, ahigh = {-28018.40706, -2.474699366, 13.00210215, -9.250962339999999e-007, 2.196515817e-010, -2.661071614e-014, 1.287167546e-018}, bhigh = {-18250.83832, -20.27484281}, R_s = R_NASA_2002/SnI4.MM);
          constant IdealGases.Common.DataRecord SnO(name = "SnO", MM = 0.1347094, Hf = 162654.2319986579, H0 = 65875.92996479831, Tlimit = 1000, alow = {25477.88022, -229.3583066, 3.42159353, 0.00471330004, -7.36597132e-006, 5.37973887e-009, -1.519277855e-012}, blow = {2853.047679, 6.67396527}, ahigh = {-2555955.548, 7870.0535, -5.43976873, 0.00630781918, -2.06887137e-006, 3.30707488e-010, -1.848169716e-014}, bhigh = {-48416.6391, 71.75952460000001}, R_s = R_NASA_2002/SnO.MM);
          constant IdealGases.Common.DataRecord SnO2(name = "SnO2", MM = 0.1507088, Hf = 77501.64555752551, H0 = 78268.02416315438, Tlimit = 1000, alow = {47076.7408, -611.456867, 6.11743391, 0.00751401466, -1.238371787e-005, 9.22091599e-009, -2.632417597e-012}, blow = {2981.068066, -8.14492641}, ahigh = {-157355.8926, -142.7316788, 7.60570076, -4.19800853e-005, 9.218742430000002e-009, -1.051372983e-012, 4.84957927e-017}, bhigh = {-523.453187, -14.28360169}, R_s = R_NASA_2002/SnO2.MM);
          constant IdealGases.Common.DataRecord SnS(name = "SnS", MM = 0.150775, Hf = 736853.0061349694, H0 = 61688.68844304427, Tlimit = 1000, alow = {27248.77813, -492.412638, 6.22165473, -0.00340940696, 3.98491368e-006, -2.470702874e-009, 6.33934146e-013}, blow = {14524.95307, -6.791285229}, ahigh = {-1797985.129, 6141.73632, -4.01950488, 0.005993829179999999, -2.188735204e-006, 3.899542e-010, -2.40656363e-014}, bhigh = {-26113.49815, 62.56820705}, R_s = R_NASA_2002/SnS.MM);
          constant IdealGases.Common.DataRecord SnS2(name = "SnS2", MM = 0.18284, Hf = 818451.0774447605, H0 = 74573.91708597681, Tlimit = 1000, alow = {38771.4541, -848.695394, 10.4208399, -0.005686902670000001, 6.37382977e-006, -3.8251581e-009, 9.50248096e-013}, blow = {20060.27952, -27.23724769}, ahigh = {-67640.84050000001, -19.70189679, 7.51533387, -6.33255918e-006, 1.434207625e-009, -1.676383081e-013, 7.886911900000001e-018}, bhigh = {15650.53629, -9.922744838}, R_s = R_NASA_2002/SnS2.MM);
          constant IdealGases.Common.DataRecord Sn2(name = "Sn2", MM = 0.23742, Hf = 1774676.678460113, H0 = 47903.02838850982, Tlimit = 1000, alow = {-132966.6654, 1639.179787, -1.902868972, 0.01290431677, -1.120542242e-005, 4.50299386e-009, -6.05623777e-013}, blow = {40974.5271, 44.35408029999999}, ahigh = {-4275783.04, 12364.21656, -8.43833617, 0.00708805629, -1.712012737e-006, 1.805262952e-010, -7.058656809999999e-015}, bhigh = {-30014.1872, 100.5138538}, R_s = R_NASA_2002/Sn2.MM);
          constant IdealGases.Common.DataRecord Sr(name = "Sr", MM = 0.08762, Hf = 1831773.567678612, H0 = 70730.74640493038, Tlimit = 1000, alow = {4.19064984, -0.0630443758, 2.500373027, -1.115455943e-006, 1.785248643e-009, -1.456209589e-012, 4.750132981e-016}, blow = {18558.52648, 5.55577284}, ahigh = {14894144.1, -43753.3505, 51.3726628, -0.02592566025, 6.58299e-006, -6.949611799999999e-010, 2.417779662e-014}, bhigh = {297754.5522, -345.489077}, R_s = R_NASA_2002/Sr.MM);
          constant IdealGases.Common.DataRecord Srplus(name = "Srplus", MM = 0.08761945140000001, Hf = 8173599.772162005, H0 = 70731.18926193139, Tlimit = 1000, alow = {11.27287678, -0.134695187, 2.500651495, -1.635163061e-006, 2.249493149e-009, -1.610827539e-012, 4.698612333e-016}, blow = {85389.81180000001, 6.24725924}, ahigh = {3145095.058, -9514.756889999999, 13.50086948, -0.00605971712, 1.594068746e-006, -1.718800946e-010, 6.322256169e-015}, bhigh = {145799.1907, -72.3641693}, R_s = R_NASA_2002/Srplus.MM);
          constant IdealGases.Common.DataRecord SrBr(name = "SrBr", MM = 0.167524, Hf = -381543.4087056183, H0 = 60332.38222583033, Tlimit = 1000, alow = {-754.9812420000001, -73.5953201, 4.82803581, -0.000716058465, 1.028527433e-006, -6.88837072e-010, 1.880257878e-013}, blow = {-8686.168450000001, 4.15115309}, ahigh = {3009976.114, -9193.19224, 15.26033745, -0.00600925395, 1.692611858e-006, -2.039438429e-010, 8.807775840000001e-015}, bhigh = {49228.06129999999, -70.6825383}, R_s = R_NASA_2002/SrBr.MM);
          constant IdealGases.Common.DataRecord SrBr2(name = "SrBr2", MM = 0.247428, Hf = -1643814.972436426, H0 = 66017.78699257966, Tlimit = 1000, alow = {-4632.45866, -72.4493864, 7.80021716, -0.000677212531, 8.53778024e-007, -5.63235174e-010, 1.510568795e-013}, blow = {-50822.3833, -5.28507476}, ahigh = {-11861.73059, -1.404383013, 7.50121557, -5.415983190000001e-007, 1.296969275e-010, -1.580911652e-014, 7.68158227e-019}, bhigh = {-51185.75210000001, -3.55203711}, R_s = R_NASA_2002/SrBr2.MM);
          constant IdealGases.Common.DataRecord SrCL(name = "SrCL", MM = 0.123073, Hf = -1038959.658089102, H0 = 79628.49690833896, Tlimit = 1000, alow = {3555.34632, -172.9385697, 5.21345102, -0.001542910668, 2.025835568e-006, -1.327076633e-009, 3.54717596e-013}, blow = {-15882.88066, 0.4818144784}, ahigh = {2070217.324, -6199.89173, 11.50315072, -0.00367568546, 9.46173235e-007, -9.203765750000001e-011, 2.707242192e-015}, bhigh = {22714.71632, -45.61058514}, R_s = R_NASA_2002/SrCL.MM);
          constant IdealGases.Common.DataRecord SrCLplus(name = "SrCLplus", MM = 0.1230724514, Hf = 3316031.795560708, H0 = 77862.77018936505, Tlimit = 1000, alow = {1689.043529, -174.9284676, 5.06532864, -0.0009857327839999999, 1.071655138e-006, -5.988127129999999e-010, 1.395650932e-013}, blow = {48611.9026, 0.2492001711}, ahigh = {-21324.75783, -4.05794827, 4.50314939, 3.82620238e-005, 2.67695151e-009, 5.667610500000001e-014, 1.613288103e-018}, bhigh = {47693.2603, 3.637722496}, R_s = R_NASA_2002/SrCLplus.MM);
          constant IdealGases.Common.DataRecord SrCL2(name = "SrCL2", MM = 0.158526, Hf = -3058261.118050036, H0 = 90938.38234737518, Tlimit = 1000, alow = {1913.170011, -268.1156951, 8.0813343, -0.002393329295, 2.976397494e-006, -1.943902862e-009, 5.17430771e-013}, blow = {-59101.1185, -8.457827543000001}, ahigh = {-25927.16099, -5.26378585, 7.00447524, -1.970397814e-006, 4.6796712e-010, -5.67021588e-014, 2.742892387e-018}, bhigh = {-60453.9953, -2.192202775}, R_s = R_NASA_2002/SrCL2.MM);
          constant IdealGases.Common.DataRecord SrF(name = "SrF", MM = 0.1066184032, Hf = -2847095.612851947, H0 = 87068.57091628248, Tlimit = 1000, alow = {27250.08615, -485.001972, 6.1126972, -0.003008469209, 3.3684658e-006, -1.987813072e-009, 4.88416109e-013}, blow = {-35368.9039, -6.68373918}, ahigh = {870234.0489999999, -2589.81877, 7.20026422, -0.001173446296, 1.996165066e-007, 1.103842667e-011, -2.343183859e-015}, bhigh = {-21336.71699, -16.67390309}, R_s = R_NASA_2002/SrF.MM);
          constant IdealGases.Common.DataRecord SrFplus(name = "SrFplus", MM = 0.1066178546, Hf = 1964664.481252842, H0 = 85415.44973087461, Tlimit = 1000, alow = {40096.242, -594.494608, 6.18233033, -0.00271615975, 2.641369127e-006, -1.383123292e-009, 3.052935853e-013}, blow = {26971.49351, -8.313659449999999}, ahigh = {-47520.8206, -25.26802345, 4.51929528, 2.55642675e-005, 3.38254183e-009, -1.511394636e-013, 9.53749118e-018}, bhigh = {23838.61417, 1.892197325}, R_s = R_NASA_2002/SrFplus.MM);
          constant IdealGases.Common.DataRecord SrF2(name = "SrF2", MM = 0.1256168064, Hf = -6247522.266256246, H0 = 105635.5545112792, Tlimit = 1000, alow = {41707.5965, -850.0132410000001, 10.02806064, -0.00609848519, 7.05626133e-006, -4.35937431e-009, 1.11130831e-012}, blow = {-92178.59849999999, -23.25100053}, ahigh = {-61262.6543, -19.64060822, 7.01555775, -6.51252678e-006, 1.490473613e-009, -1.75643704e-013, 8.317093849999999e-018}, bhigh = {-96567.0125, -5.40230876}, R_s = R_NASA_2002/SrF2.MM);
          constant IdealGases.Common.DataRecord SrH(name = "SrH", MM = 0.08862793999999999, Hf = 2473566.518639608, H0 = 98423.87174969881, Tlimit = 1000, alow = {-43177.9689, 767.64297, -1.594398638, 0.01500711077, -1.826296898e-005, 1.136757659e-008, -2.855588359e-012}, blow = {21796.85693, 33.2467423}, ahigh = {-226982.5428, 1345.209458, 1.152194421, 0.003109555289, -1.188080968e-006, 2.073091147e-010, -1.300839287e-014}, bhigh = {17355.47062, 21.12916944}, R_s = R_NASA_2002/SrH.MM);
          constant IdealGases.Common.DataRecord SrI(name = "SrI", MM = 0.21452447, Hf = -36600.37477309698, H0 = 47934.50369554578, Tlimit = 1000, alow = {-2467.498501, -25.35495809, 4.60329848, -0.0001613676212, 2.694294049e-007, -1.564795762e-010, 3.82648228e-014}, blow = {-2175.538291, 6.41148188}, ahigh = {2201136.857, -7082.2307, 13.32597928, -0.00530586442, 1.63607115e-006, -2.205540591e-010, 1.078496824e-014}, bhigh = {42190.77170000001, -55.308332}, R_s = R_NASA_2002/SrI.MM);
          constant IdealGases.Common.DataRecord SrI2(name = "SrI2", MM = 0.34142894, Hf = -814866.0216090645, H0 = 48916.93715242767, Tlimit = 1000, alow = {-4391.84969, -37.5726735, 7.6569935, -0.00035617213, 4.508689010000001e-007, -2.983230473e-010, 8.01865866e-014}, blow = {-35533.0346, -2.598281578}, ahigh = {-8090.381920000001, -0.734826323, 7.50064006, -2.863515042e-007, 6.87655697e-011, -8.398807359999999e-015, 4.08696816e-019}, bhigh = {-35721.0642, -1.693119087}, R_s = R_NASA_2002/SrI2.MM);
          constant IdealGases.Common.DataRecord SrO(name = "SrO", MM = 0.1036194, Hf = -137114.1986925228, H0 = 87243.40229725321, Tlimit = 1000, alow = {42248.9167, -591.3517869999999, 5.964363, -0.002105712736, 2.028373972e-006, -1.197885492e-009, 3.46628992e-013}, blow = {101.8053721, -7.51142747}, ahigh = {-51729330.5, 151082.1, -161.4513515, 0.08516051790000001, -2.091669402e-005, 2.452307103e-009, -1.108841292e-013}, bhigh = {-968782.9519999999, 1197.846971}, R_s = R_NASA_2002/SrO.MM);
          constant IdealGases.Common.DataRecord SrOH(name = "SrOH", MM = 0.10462734, Hf = -1855019.213907187, H0 = 105581.0651403352, Tlimit = 1000, alow = {46400.06559999999, -993.868554, 9.78494896, -0.00577437762, 5.126164110000001e-006, -1.833418356e-009, 1.92601341e-013}, blow = {-20227.21196, -27.40670981}, ahigh = {2545648.379, -7416.19598, 13.81956204, -0.003096481934, 7.72389421e-007, -7.921280320000001e-011, 2.740829111e-015}, bhigh = {22313.02058, -61.4878113}, R_s = R_NASA_2002/SrOH.MM);
          constant IdealGases.Common.DataRecord SrOHplus(name = "SrOHplus", MM = 0.1046267914, Hf = 2964533.279188374, H0 = 106135.0429599431, Tlimit = 1000, alow = {38573.6694, -903.024233, 9.451103249999999, -0.00504251628, 4.190101890000001e-006, -1.196920603e-009, 1.606318743e-014}, blow = {39950.67720000001, -26.0148611}, ahigh = {867969.566, -2340.609538, 7.97682975, 0.0001023752569, -6.28603233e-008, 1.024851502e-011, -5.72368392e-016}, bhigh = {50731.5772, -20.27046917}, R_s = R_NASA_2002/SrOHplus.MM);
          constant IdealGases.Common.DataRecord Sr_OH_2(name = "Sr_OH_2", MM = 0.12163468, Hf = -4905628.666100819, H0 = 139860.7781925352, Tlimit = 1000, alow = {72050.90300000001, -1789.465226, 17.29429139, -0.01169280781, 1.106702894e-005, -4.49014609e-009, 6.603997460000001e-013}, blow = {-66053.94040000001, -63.88681219999999}, ahigh = {1750013.518, -4681.6015, 13.95548402, 0.000203501956, -1.253496115e-007, 2.044549432e-011, -1.142004855e-015}, bhigh = {-44271.7024, -50.5145685}, R_s = R_NASA_2002/Sr_OH_2.MM);
          constant IdealGases.Common.DataRecord SrS(name = "SrS", MM = 0.119685, Hf = 871882.9845009816, H0 = 79676.77653841332, Tlimit = 1000, alow = {12564.40807, -315.0436559, 5.72172251, -0.002630479718, 3.38469975e-006, -2.296256846e-009, 6.512086680000001e-013}, blow = {12772.9516, -3.693874943}, ahigh = {-13794329.47, 39213.3158, -36.0286638, 0.01818513386, -3.27585816e-006, 2.324312746e-010, -3.6145557e-015}, bhigh = {-241024.6179, 299.1679642}, R_s = R_NASA_2002/SrS.MM);
          constant IdealGases.Common.DataRecord Sr2(name = "Sr2", MM = 0.17524, Hf = 1755137.736818078, H0 = 64854.6964163433, Tlimit = 1000, alow = {-110885.9753, 592.760401, 8.43968855, -0.02652801112, 4.43582597e-005, -3.39991549e-008, 9.965546679999999e-012}, blow = {31576.15033, -7.03396665}, ahigh = {209844.5682, 103.865013, 2.30933233, 0.0001330517507, -4.42643339e-008, 6.71141915e-012, -3.374128e-016}, bhigh = {36366.4269, 21.68088517}, R_s = R_NASA_2002/Sr2.MM);
          constant IdealGases.Common.DataRecord Ta(name = "Ta", MM = 0.1809479, Hf = 4324552.194305654, H0 = 34262.00580388057, Tlimit = 1000, alow = {-11509.07339, 47.8073043, 3.18558839, -0.00536652816, 1.288379705e-005, -1.045798666e-008, 3.050617695e-012}, blow = {92997.97630000001, 5.33605661}, ahigh = {1689726.898, -5986.85466, 9.565039670000001, -0.002511649459, 6.44303117e-007, -7.189237249999999e-011, 3.11335207e-015}, bhigh = {130671.0983, -43.3509627}, R_s = R_NASA_2002/Ta.MM);
          constant IdealGases.Common.DataRecord Taplus(name = "Taplus", MM = 0.1809473514, Hf = 8564255.420209482, H0 = 35025.85117142533, Tlimit = 1000, alow = {286971.2865, -3084.920994, 14.30679704, -0.01984772164, 1.951445133e-005, -8.97094603e-009, 1.501974665e-012}, blow = {201382.8712, -63.0642783}, ahigh = {3656142.13, -12540.73524, 18.65022579, -0.007943274660000001, 2.151786937e-006, -2.816764844e-010, 1.413722944e-014}, bhigh = {263687.6455, -106.5864286}, R_s = R_NASA_2002/Taplus.MM);
          constant IdealGases.Common.DataRecord Taminus(name = "Taminus", MM = 0.1809484486, Hf = 4119789.004922146, H0 = 35458.32555980256, Tlimit = 1000, alow = {187398.2301, -1681.268679, 6.48004015, -0.0002254355782, 2.028434876e-006, -4.67980143e-009, 1.997027996e-012}, blow = {97934.96019999999, -20.49618155}, ahigh = {-4235467.48, 11010.56361, -4.73691107, 0.002503562129, -4.82185169e-007, 4.88640803e-011, -2.030547835e-015}, bhigh = {15746.99408, 64.918027}, R_s = R_NASA_2002/Taminus.MM);
          constant IdealGases.Common.DataRecord TaCL5(name = "TaCL5", MM = 0.3582129, Hf = -2135140.86176126, H0 = 75008.74479953123, Tlimit = 1000, alow = {63064.8329, -1771.221442, 22.55083356, -0.01360238041, 1.613009806e-005, -1.016307761e-008, 2.631917453e-012}, blow = {-87927.37109999999, -80.97864282000001}, ahigh = {-142644.4545, -38.9434032, 16.0314237, -1.333676355e-005, 3.084307611e-009, -3.66393006e-013, 1.745841795e-017}, bhigh = {-97012.9717, -42.56986372}, R_s = R_NASA_2002/TaCL5.MM);
          constant IdealGases.Common.DataRecord TaO(name = "TaO", MM = 0.1969473, Hf = 1231470.068388853, H0 = 44509.90188745923, Tlimit = 1000, alow = {-13957.38049, 394.523699, -0.0630169641, 0.01308595441, -1.86233973e-005, 1.366155583e-008, -3.92455123e-012}, blow = {26451.95419, 27.41671469}, ahigh = {6106591.12, -19841.35246, 28.15797433, -0.01330045882, 3.87680749e-006, -5.068872769999999e-010, 2.443666035e-014}, bhigh = {152581.4433, -165.8307106}, R_s = R_NASA_2002/TaO.MM);
          constant IdealGases.Common.DataRecord TaO2(name = "TaO2", MM = 0.2129467, Hf = -815518.6532592428, H0 = 50243.08430231603, Tlimit = 1000, alow = {15163.56303, 70.58414759999999, 0.691851699, 0.02020605733, -2.928317413e-005, 2.081417374e-008, -5.751106690000001e-012}, blow = {-22121.99468, 24.846625}, ahigh = {1297565.964, -4149.217430000001, 10.41680373, -0.001045478838, 2.754904271e-007, -3.29704313e-011, 1.356249074e-015}, bhigh = {3418.98567, -33.9264279}, R_s = R_NASA_2002/TaO2.MM);
          constant IdealGases.Common.DataRecord Ti(name = "Ti", MM = 0.047867, Hf = 9881546.785885891, H0 = 157501.8488729187, Tlimit = 1000, alow = {-45701.79399999999, 660.809202, 0.429525749, 0.00361502991, -3.54979281e-006, 1.759952494e-009, -3.052720871e-013}, blow = {52709.4793, 20.26149738}, ahigh = {-170478.6714, 1073.852803, 1.181955014, 0.0002245246352, 3.091697848e-007, -5.74002728e-011, 2.927371014e-015}, bhigh = {49780.69910000001, 17.40431368}, R_s = R_NASA_2002/Ti.MM);
          constant IdealGases.Common.DataRecord Tiplus(name = "Tiplus", MM = 0.0478664514, Hf = 23766625.59531204, H0 = 165038.9525219745, Tlimit = 1000, alow = {170745.7044, -1727.524602, 9.615885329999999, -0.0108965506, 8.20180965e-006, -2.871464413e-009, 3.420382976e-013}, blow = {144789.7558, -34.6314366}, ahigh = {-768546.308, 2545.8681, 0.342386278, 0.000709990136, 2.706231875e-008, -2.3716601e-011, 1.895443077e-015}, bhigh = {119882.1489, 24.8479915}, R_s = R_NASA_2002/Tiplus.MM);
          constant IdealGases.Common.DataRecord Timinus(name = "Timinus", MM = 0.0478675486, Hf = 9593217.689865155, H0 = 157990.4177503671, Tlimit = 1000, alow = {-3006.48499, 204.0911689, 1.822638976, 0.001245254812, -1.309239865e-006, 7.37214322e-010, -1.724319779e-013}, blow = {53467.7205, 12.05926588}, ahigh = {23411.1764, 2.580413872, 2.497754577, 9.76907204e-007, -2.280024955e-010, 2.717202291e-014, -1.295670294e-018}, bhigh = {54546.62179999999, 7.99982395}, R_s = R_NASA_2002/Timinus.MM);
          constant IdealGases.Common.DataRecord TiCL(name = "TiCL", MM = 0.08331999999999999, Hf = 1810500.792126741, H0 = 116186.1017762842, Tlimit = 1000, alow = {-17141.77839, 310.3259047, 0.892093598, 0.01383436793, -1.885370354e-005, 1.212085912e-008, -3.032162427e-012}, blow = {15580.66453, 22.44778384}, ahigh = {-963322.542, 2868.829781, 1.973820676, 0.001752668011, -4.25543436e-007, 5.0491034e-011, -2.304720715e-015}, bhigh = {-1811.011561, 23.19450287}, R_s = R_NASA_2002/TiCL.MM);
          constant IdealGases.Common.DataRecord TiCL2(name = "TiCL2", MM = 0.118773, Hf = -1997339.462672493, H0 = 114043.343184057, Tlimit = 1000, alow = {13243.54656, -576.282932, 9.64004729, -0.00447512095, 5.398794869999999e-006, -3.52580049e-009, 9.74600455e-013}, blow = {-27920.66683, -22.18347625}, ahigh = {-3190012.95, 10157.63826, -4.84079477, 0.00682200634, -1.70075327e-006, 2.118106588e-010, -1.041245457e-014}, bhigh = {-94809.82980000001, 78.23195948}, R_s = R_NASA_2002/TiCL2.MM);
          constant IdealGases.Common.DataRecord TiCL3(name = "TiCL3", MM = 0.154226, Hf = -3496946.04022668, H0 = 99691.01837563056, Tlimit = 1000, alow = {124328.2268, -2320.728253, 17.79895274, -0.01160889348, 1.006643154e-005, -4.81194069e-009, 1.006186828e-012}, blow = {-56096.0251, -67.32754065}, ahigh = {-94087.92310000002, -125.5351109, 10.66923972, -0.0002637456897, 7.95916935e-008, -1.176740054e-011, 6.41622348e-016}, bhigh = {-67691.1468, -23.69164216}, R_s = R_NASA_2002/TiCL3.MM);
          constant IdealGases.Common.DataRecord TiCL4(name = "TiCL4", MM = 0.189679, Hf = -4023429.056458543, H0 = 113947.9910796662, Tlimit = 1000, alow = {81871.96800000001, -1758.32385, 18.92512121, -0.01133495876, 1.251952037e-005, -7.422681329999999e-009, 1.825440187e-012}, blow = {-86729.23109999999, -67.69594291}, ahigh = {-143256.2278, -43.1677485, 13.03337752, -1.371365738e-005, 3.093403483e-009, -3.60424516e-013, 1.691384523e-017}, bhigh = {-95889.46999999999, -32.47541011}, R_s = R_NASA_2002/TiCL4.MM);
          constant IdealGases.Common.DataRecord TiO(name = "TiO", MM = 0.0638664, Hf = 775112.0307391679, H0 = 150205.9768516779, Tlimit = 1000, alow = {-11681.5246, 454.256565, -0.1139144613, 0.01275432333, -1.727656935e-005, 1.187369403e-008, -3.23657937e-012}, blow = {2924.306353, 27.02903947}, ahigh = {2330644.03, -7415.79386, 12.81799311, -0.004344555950000001, 1.186303111e-006, -1.367644275e-010, 5.70321225e-015}, bhigh = {51448.4136, -57.9399424}, R_s = R_NASA_2002/TiO.MM);
          constant IdealGases.Common.DataRecord TiOplus(name = "TiOplus", MM = 0.06386585139999999, Hf = 10730632.97485454, H0 = 144257.2329036547, Tlimit = 1000, alow = {36912.5625, -149.2825538, 2.624977257, 0.00581862713, -7.52966211e-006, 4.74415435e-009, -1.186916989e-012}, blow = {82415.51169999999, 10.95428726}, ahigh = {342132.953, -2161.85106, 8.02517566, -0.002708700692, 1.004583805e-006, -1.50576685e-010, 8.04565811e-015}, bhigh = {93626.4699, -22.61587887}, R_s = R_NASA_2002/TiOplus.MM);
          constant IdealGases.Common.DataRecord TiOCL(name = "TiOCL", MM = 0.0993194, Hf = -2459358.393224285, H0 = 122259.1054718413, Tlimit = 1000, alow = {35458.5651, -629.528714, 7.3701763, 0.00330201914, -6.12145875e-006, 4.73588025e-009, -1.374690357e-012}, blow = {-27970.87903, -12.94470159}, ahigh = {-127305.9873, -111.111885, 7.58288808, -3.3128718e-005, 7.31401409e-009, -8.37882226e-013, 3.87927506e-017}, bhigh = {-31393.56857, -12.47104274}, R_s = R_NASA_2002/TiOCL.MM);
          constant IdealGases.Common.DataRecord TiOCL2(name = "TiOCL2", MM = 0.1347724, Hf = -4047950.470571125, H0 = 123986.8845549979, Tlimit = 1000, alow = {32890.5246, -738.918859, 10.55976857, 0.001577742341, -3.9071821e-006, 3.29057653e-009, -9.949471750000001e-013}, blow = {-64484.107, -24.17469934}, ahigh = {-132295.1633, -96.91212050000002, 10.07240769, -2.897248531e-005, 6.40177504e-009, -7.3384526e-013, 3.39928267e-017}, bhigh = {-68474.09640000001, -19.75043469}, R_s = R_NASA_2002/TiOCL2.MM);
          constant IdealGases.Common.DataRecord TiO2(name = "TiO2", MM = 0.07986579999999999, Hf = -3824290.246889157, H0 = 142134.5557172156, Tlimit = 1000, alow = {-1710.545601, 272.1435528, 0.596137896, 0.01925463599, -2.665500165e-005, 1.811109197e-008, -4.87671047e-012}, blow = {-39122.4177, 24.08605889}, ahigh = {154629.9764, -1046.25688, 7.78898583, -0.0001546805714, -7.05993595e-008, 3.100244802e-011, -2.49472543e-015}, bhigh = {-32663.3675, -15.9153466}, R_s = R_NASA_2002/TiO2.MM);
          constant IdealGases.Common.DataRecord U(name = "U", MM = 0.23802891, Hf = 2247626.139194605, H0 = 27304.64127235637, Tlimit = 1000, alow = {69657.3775, -1070.351517, 8.075842310000001, -0.01060034069, 9.25654801e-006, -3.21989976e-009, 4.058048809e-013}, blow = {68665.137, -22.40521678}, ahigh = {-4092498.96, 12748.88349, -12.18707506, 0.00725810568, -7.78777507e-007, -3.84435385e-011, 7.066508567e-015}, bhigh = {-16993.72664, 115.5026301}, R_s = R_NASA_2002/U.MM);
          constant IdealGases.Common.DataRecord UF(name = "UF", MM = 0.2570273132, Hf = -191616.7444884609, H0 = 36521.65555143032, Tlimit = 1000, alow = {172553.3463, -1698.985561, 5.90292643, 0.01841977309, -4.633174310000001e-005, 4.376657200000001e-008, -1.451876566e-011}, blow = {2086.455917, -11.86592944}, ahigh = {-5325439.37, 15339.67086, -11.75044398, 0.00964721093, -2.49877819e-006, 3.155572896e-010, -1.544694839e-014}, bhigh = {-105719.6525, 122.0828149}, R_s = R_NASA_2002/UF.MM);
          constant IdealGases.Common.DataRecord UFplus(name = "UFplus", MM = 0.2570267646, Hf = 2167318.908857323, H0 = 36958.66854482439, Tlimit = 1000, alow = {1622640.597, -19173.26611, 87.5946122, -0.1699915707, 0.0001861251683, -1.036176702e-007, 2.324287412e-011}, blow = {161670.9643, -480.6891249}, ahigh = {539509.184, -2923.962095, 10.08511948, -0.002425945123, 5.92872548e-007, -6.79584554e-011, 3.152666445e-015}, bhigh = {82672.91220000001, -33.07089704}, R_s = R_NASA_2002/UFplus.MM);
          constant IdealGases.Common.DataRecord UFminus(name = "UFminus", MM = 0.2570278618, Hf = -605689.9509250013, H0 = 35622.62447300179, Tlimit = 1000, alow = {3692.32786, -149.1979606, 4.03398852, 0.002857429445, -5.17170256e-006, 3.98537911e-009, -9.47035544e-013}, blow = {-19152.81695, 6.059243838}, ahigh = {-4311143.56, 19748.17938, -27.60304763, 0.02276806261, -6.88874172e-006, 9.483511059999999e-010, -4.9106881e-014}, bhigh = {-138080.129, 224.0758537}, R_s = R_NASA_2002/UFminus.MM);
          constant IdealGases.Common.DataRecord UF2(name = "UF2", MM = 0.2760257164, Hf = -1938358.21523476, H0 = 54894.85616638001, Tlimit = 1000, alow = {-38824.9202, 445.493086, 4.71800919, 0.00164891148, 8.696243010000001e-006, -1.207439921e-008, 4.53679391e-012}, blow = {-68553.29330000001, 11.59725423}, ahigh = {-471677.682, 322.423686, 8.214090629999999, -0.000140741378, 6.54117805e-009, 1.818915497e-012, -2.287963719e-016}, bhigh = {-69952.3505, -9.648963156000001}, R_s = R_NASA_2002/UF2.MM);
          constant IdealGases.Common.DataRecord UF2plus(name = "UF2plus", MM = 0.2760251678, Hf = 255214.1442806506, H0 = 52303.66170979283, Tlimit = 1000, alow = {5439.01016, -150.7096256, 6.87348519, 0.001530973969, -3.31669431e-006, 2.949453335e-009, -8.28170654e-013}, blow = {7256.01491, -2.205491833}, ahigh = {-3779149.61, 12987.37504, -10.27930641, 0.01048838051, -2.651047812e-006, 3.116973593e-010, -1.417216291e-014}, bhigh = {-74334.402, 118.9131079}, R_s = R_NASA_2002/UF2plus.MM);
          constant IdealGases.Common.DataRecord UF2minus(name = "UF2minus", MM = 0.2760262650000001, Hf = -2457132.820313313, H0 = 47652.49060628342, Tlimit = 1000, alow = {806049.1730000001, -9404.254659999999, 44.4839277, -0.0686855877, 6.777809920000001e-005, -3.33882768e-008, 6.60485162e-012}, blow = {-36033.0613, -226.1594249}, ahigh = {10382318.55, -28401.13518, 34.9853337, -0.01053216396, 1.92462047e-006, -1.69874957e-010, 5.70985889e-015}, bhigh = {100157.2794, -209.4039075}, R_s = R_NASA_2002/UF2minus.MM);
          constant IdealGases.Common.DataRecord UF3(name = "UF3", MM = 0.2950241196, Hf = -3596175.792130048, H0 = 63191.657093246, Tlimit = 1000, alow = {30710.27207, -634.078947, 11.14030799, -0.0002937554125, -1.865390371e-006, 2.37181947e-009, -7.44675407e-013}, blow = {-127183.8141, -23.48962529}, ahigh = {-3828876.42, 12968.91783, -7.26555429, 0.01048289752, -2.649840687e-006, 3.115594509e-010, -1.4165794e-014}, bhigh = {-211361.5913, 105.4464687}, R_s = R_NASA_2002/UF3.MM);
          constant IdealGases.Common.DataRecord UF3plus(name = "UF3plus", MM = 0.295023571, Hf = -965161.6277127904, H0 = 63245.35336873134, Tlimit = 1000, alow = {-398415.589, 3480.89244, -2.519603507, 0.02283749282, -2.16884478e-005, 1.11126579e-008, -2.350882012e-012}, blow = {-55508.892, 58.53815975}, ahigh = {-1196316.388, 3972.78507, 4.53590711, 0.00413341615, -1.097960689e-006, 1.319641252e-010, -6.10112918e-015}, bhigh = {-61995.4174, 21.37623045}, R_s = R_NASA_2002/UF3plus.MM);
          constant IdealGases.Common.DataRecord UF3minus(name = "UF3minus", MM = 0.2950246682, Hf = -4021496.840378447, H0 = 65615.96736336911, Tlimit = 1000, alow = {-231518.73, 2534.197822, -3.18071459, 0.02932741422, -2.85691226e-005, 1.345804152e-008, -2.465442912e-012}, blow = {-158038.7746, 59.73605435}, ahigh = {-191005.3149, -506.918131, 11.81482258, -0.0001711879404, -9.38483918e-008, 2.242009537e-011, -1.42819528e-015}, bhigh = {-143862.8681, -27.74680411}, R_s = R_NASA_2002/UF3minus.MM);
          constant IdealGases.Common.DataRecord UF4(name = "UF4", MM = 0.3140225228, Hf = -5114784.136114202, H0 = 69716.59804778818, Tlimit = 1000, alow = {-50078.5238, -969.349355, 20.69596355, -0.02564852637, 4.19586012e-005, -3.20101339e-008, 9.422076860000001e-012}, blow = {-193162.6334, -71.72362935}, ahigh = {-1230291.173, 3876.46379, 7.62162591, 0.004094525220000001, -1.088530094e-006, 1.308042117e-010, -6.04439087e-015}, bhigh = {-221414.292, 6.270300658}, R_s = R_NASA_2002/UF4.MM);
          constant IdealGases.Common.DataRecord UF4plus(name = "UF4plus", MM = 0.3140219742, Hf = -2042976.405184323, H0 = 64687.5622374837, Tlimit = 1000, alow = {38489.5633, -1343.282151, 16.46334809, -0.00719607986, 1.147165041e-005, -8.70587798e-009, 2.501076195e-012}, blow = {-74050.482, -52.95285534999999}, ahigh = {-1617630.159, 3765.93477, 9.16613853, 0.002426641067, -5.695320299999999e-007, 6.021096599999999e-011, -2.438874329e-015}, bhigh = {-106191.0645, -4.162641042}, R_s = R_NASA_2002/UF4plus.MM);
          constant IdealGases.Common.DataRecord UF4minus(name = "UF4minus", MM = 0.3140230714, Hf = -5503846.766081914, H0 = 69666.13918674002, Tlimit = 1000, alow = {72031.7969, -1374.343862, 16.40877729, -0.00436306627, 2.460407959e-006, -1.498144731e-010, -1.239417075e-013}, blow = {-204517.4023, -51.72250795}, ahigh = {-4639200.11, 16268.24426, -9.59529105, 0.01441556535, -4.008173850000001e-006, 5.140230790000001e-010, -2.511687821e-014}, bhigh = {-312514.0933, 127.4038784}, R_s = R_NASA_2002/UF4minus.MM);
          constant IdealGases.Common.DataRecord UF5(name = "UF5", MM = 0.333020926, Hf = -5854959.048429288, H0 = 70875.07167642673, Tlimit = 1000, alow = {161576.9193, -2976.611537, 25.3754242, -0.0193010567, 2.561852107e-005, -1.747402896e-008, 4.73205938e-012}, blow = {-223908.9616, -102.4264836}, ahigh = {-1695373.88, 3735.42535, 12.1874804, 0.002418608203, -5.67852616e-007, 6.00276561e-011, -2.430740809e-015}, bhigh = {-264510.7342, -18.83137475}, R_s = R_NASA_2002/UF5.MM);
          constant IdealGases.Common.DataRecord UF5plus(name = "UF5plus", MM = 0.3330203774, Hf = -2563258.286668436, H0 = 70903.04258360378, Tlimit = 1000, alow = {162651.9713, -2915.370389, 24.36168077, -0.01382199656, 1.339849041e-005, -7.07857269e-009, 1.57340404e-012}, blow = {-92264.0485, -98.30243935}, ahigh = {-262847.8263, -117.4047323, 16.08988291, -3.66551671e-005, 8.221494970000001e-009, -9.53716052e-013, 4.46014508e-017}, bhigh = {-107629.3931, -47.63374165000001}, R_s = R_NASA_2002/UF5plus.MM);
          constant IdealGases.Common.DataRecord UF5minus(name = "UF5minus", MM = 0.3330214746, Hf = -6874725.540597317, H0 = 75649.66502613644, Tlimit = 1000, alow = {-314213.0934, 2020.611008, 7.50849182, 0.01640034396, -1.562795472e-005, 7.99024601e-009, -1.671674534e-012}, blow = {-290764.7496, 4.690020575}, ahigh = {-1331518.187, 3905.51686, 10.58727667, 0.00411250727, -1.09327793e-006, 1.314215436e-010, -6.07577827e-015}, bhigh = {-304950.6955, -7.977511665}, R_s = R_NASA_2002/UF5minus.MM);
          constant IdealGases.Common.DataRecord UF6(name = "UF6", MM = 0.3520193292, Hf = -6103760.418165129, H0 = 75630.36967459797, Tlimit = 1000, alow = {191567.406, -3426.39161, 28.0039589, -0.01326392086, 1.107123764e-005, -4.821754109999999e-009, 8.32513245e-013}, blow = {-246104.5194, -121.1612947}, ahigh = {-340902.792, -145.8950046, 19.10902533, -4.358451129999999e-005, 9.617604659999999e-009, -1.100915551e-012, 5.09264508e-017}, bhigh = {-264364.5561, -65.79130395999999}, R_s = R_NASA_2002/UF6.MM);
          constant IdealGases.Common.DataRecord UF6minus(name = "UF6minus", MM = 0.3520198778, Hf = -7645324.368668365, H0 = 78775.65657174375, Tlimit = 1000, alow = {156923.0858, -3027.27994, 27.01442427, -0.01136860992, 8.29857616e-006, -2.582889593e-009, 2.790817248e-013}, blow = {-313530.7376, -112.8934794}, ahigh = {2699676.848, -6574.45967, 22.41731997, 0.000605779971, -4.51749171e-007, 7.821820469999999e-011, -4.56033472e-015}, bhigh = {-285566.7984, -91.82896336}, R_s = R_NASA_2002/UF6minus.MM);
          constant IdealGases.Common.DataRecord UO(name = "UO", MM = 0.25402831, Hf = 120020.4378795419, H0 = 37548.13390680748, Tlimit = 1000, alow = {1007249.615, -12871.90666, 59.93123920000001, -0.1003445164, 8.529345550000001e-005, -2.634105066e-008, -5.350649790000001e-013}, blow = {66274.4252, -322.6786779}, ahigh = {-2458660.003, 3942.65216, 5.01603072, -0.0005450639469999999, 2.096321351e-007, -2.654652526e-011, 1.361108472e-015}, bhigh = {-26651.49645, 5.580598689}, R_s = R_NASA_2002/UO.MM);
          constant IdealGases.Common.DataRecord UOplus(name = "UOplus", MM = 0.2540277614, Hf = 2287041.084793814, H0 = 34737.25450859325, Tlimit = 1000, alow = {15628.34007, -122.4921454, 3.32414616, 0.002467496097, -6.851856739999999e-007, 5.55207319e-011, -5.89301203e-014}, blow = {69529.99740000001, 9.583869879}, ahigh = {-106371.4748, -1793.716133, 8.024449049999999, -0.001565116442, 5.06603391e-007, -7.37397747e-011, 4.07476643e-015}, bhigh = {77890.8584, -21.1528425}, R_s = R_NASA_2002/UOplus.MM);
          constant IdealGases.Common.DataRecord UOF(name = "UOF", MM = 0.2730267132, Hf = -1985823.063411511, H0 = 51297.01718871954, Tlimit = 1000, alow = {386.124847, 51.62286899999999, 4.88896252, 0.00726563356, -1.134176875e-005, 8.50904175e-009, -2.354655485e-012}, blow = {-67198.1338, 8.269521875000001}, ahigh = {-3805936.01, 12952.07909, -10.25373631, 0.01047841671, -2.648894949e-006, 3.114551623e-010, -1.416111895e-014}, bhigh = {-147897.6701, 118.4570601}, R_s = R_NASA_2002/UOF.MM);
          constant IdealGases.Common.DataRecord UOF2(name = "UOF2", MM = 0.2920251164, Hf = -3819912.060139495, H0 = 61009.94400630945, Tlimit = 1000, alow = {-91066.1831, -101.4150169, 13.71057013, -0.01659931694, 3.082352584e-005, -2.490530206e-008, 7.580617639999999e-012}, blow = {-137468.6016, -34.70029665}, ahigh = {-1198944.06, 3852.17341, 4.63910975, 0.00408773844, -1.087067018e-006, 1.306398384e-010, -6.03690152e-015}, bhigh = {-161263.7583, 20.18237189}, R_s = R_NASA_2002/UOF2.MM);
          constant IdealGases.Common.DataRecord UOF3(name = "UOF3", MM = 0.3110235196, Hf = -4856989.72522334, H0 = 63748.10826364272, Tlimit = 1000, alow = {124925.6374, -2111.719498, 18.44931536, -0.01041493583, 1.469002962e-005, -1.049770051e-008, 2.922353602e-012}, blow = {-174384.4024, -66.49285435}, ahigh = {-1658296.049, 3714.43468, 9.20242554, 0.002412862293, -5.66624172e-007, 5.98906211e-011, -2.42453481e-015}, bhigh = {-210549.1714, -5.670532802}, R_s = R_NASA_2002/UOF3.MM);
          constant IdealGases.Common.DataRecord UOF4(name = "UOF4", MM = 0.3300219228, Hf = -5410584.593442651, H0 = 68912.79769248105, Tlimit = 1000, alow = {143716.4405, -2496.730363, 21.04827038, -0.00469256133, 8.741718649999999e-007, 1.517555623e-009, -7.76879974e-013}, blow = {-206128.4178, -82.46219615}, ahigh = {-299619.0288, -167.7276501, 16.12494871, -4.98441446e-005, 1.098253497e-008, -1.255803231e-012, 5.80448098e-017}, bhigh = {-219545.926, -50.24484645}, R_s = R_NASA_2002/UOF4.MM);
          constant IdealGases.Common.DataRecord UO2(name = "UO2", MM = 0.27002771, Hf = -1769521.73908374, H0 = 49847.09532218007, Tlimit = 1000, alow = {-112965.0727, 427.073027, 8.41369401, -0.00976428, 2.199903691e-005, -1.907665954e-008, 6.02988991e-012}, blow = {-62514.433, -13.00704863}, ahigh = {-1190542.635, 3832.18635, 2.153236312, 0.00408235191, -1.085924847e-006, 1.305134065e-010, -6.03121575e-015}, bhigh = {-83676.1801, 25.90742388}, R_s = R_NASA_2002/UO2.MM);
          constant IdealGases.Common.DataRecord UO2plus(name = "UO2plus", MM = 0.2700271614, Hf = 190699.0346194115, H0 = 42871.68350020659, Tlimit = 1000, alow = {44880.2338, -648.923642, 6.87424356, 0.002281949316, 1.859218752e-007, -1.849509036e-009, 8.14996533e-013}, blow = {7891.74023, -10.28257233}, ahigh = {-1589957.42, 3657.74607, 3.74678542, 0.002394401448, -5.62410144e-007, 5.93945164e-011, -2.401047056e-015}, bhigh = {-20485.58817, 14.64015614}, R_s = R_NASA_2002/UO2plus.MM);
          constant IdealGases.Common.DataRecord UO2minus(name = "UO2minus", MM = 0.2700282586, Hf = -2124592.529590901, H0 = 51021.98959261074, Tlimit = 1000, alow = {63419.7131, -719.61185, 8.30824162, 0.000962645545, -3.58373398e-006, 3.47355458e-009, -1.02279312e-012}, blow = {-67181.69869999999, -16.0603012}, ahigh = {-273825.164, 3228.53442, -0.2805114576, 0.006607310710000001, -2.070291015e-006, 2.851708013e-010, -1.466578192e-014}, bhigh = {-88934.3618, 41.45760316}, R_s = R_NASA_2002/UO2minus.MM);
          constant IdealGases.Common.DataRecord UO2F(name = "UO2F", MM = 0.2890261132, Hf = -3452749.75659189, H0 = 54679.34307051395, Tlimit = 1000, alow = {83217.92390000001, -1327.082127, 12.4012539, -0.00408415101, 7.33159348e-006, -5.98740488e-009, 1.787869209e-012}, blow = {-115752.6888, -34.15298625}, ahigh = {-1614277.202, 3712.77186, 6.20330882, 0.002412618055, -5.665888019999999e-007, 5.98882352e-011, -2.424485602e-015}, bhigh = {-147835.7384, 8.736139132}, R_s = R_NASA_2002/UO2F.MM);
          constant IdealGases.Common.DataRecord UO2F2(name = "UO2F2", MM = 0.3080245164, Hf = -4396507.2742502, H0 = 61904.07576271744, Tlimit = 1000, alow = {99598.74299999999, -1530.010701, 13.58992177, 0.0053706558, -1.141444341e-005, 9.301197039999999e-009, -2.781220538e-012}, blow = {-158031.0734, -41.96260275}, ahigh = {-263655.2036, -203.2835065, 13.15092994, -6.00648683e-005, 1.321137913e-008, -1.508668985e-012, 6.96618275e-017}, bhigh = {-166444.4818, -35.66258175}, R_s = R_NASA_2002/UO2F2.MM);
          constant IdealGases.Common.DataRecord UO3(name = "UO3", MM = 0.28602711, Hf = -2794278.524857312, H0 = 52948.63483394984, Tlimit = 1000, alow = {66376.77039999999, -758.2646579999999, 7.11284471, 0.01322149697, -2.106191042e-005, 1.545856318e-008, -4.37856629e-012}, blow = {-94133.69349999999, -8.588030428}, ahigh = {-1097362.721, 2808.784061, 5.96612147, 0.002861871152, -1.05284381e-006, 1.849985929e-010, -1.102849619e-014}, bhigh = {-117336.0017, 6.672828312}, R_s = R_NASA_2002/UO3.MM);
          constant IdealGases.Common.DataRecord UO3minus(name = "UO3minus", MM = 0.2860276586, Hf = -4563036.051786915, H0 = 53935.6301258063, Tlimit = 1000, alow = {100014.3902, -1448.443754, 12.17532415, -0.002944956748, 5.675227999999999e-006, -4.91671042e-009, 1.525185713e-012}, blow = {-151925.3376, -34.71731375}, ahigh = {-1632938.634, 3667.49541, 6.24003065, 0.002396952522, -5.62949023e-007, 5.94541313e-011, -2.403730982e-015}, bhigh = {-184592.7385, 7.032059012}, R_s = R_NASA_2002/UO3minus.MM);
          constant IdealGases.Common.DataRecord V(name = "V", MM = 0.0509415, Hf = 10154138.84553851, H0 = 155218.5153558494, Tlimit = 1000, alow = {-55353.7602, 559.333851, 2.675543482, -0.00624304963, 1.565902337e-005, -1.372845314e-008, 4.16838881e-012}, blow = {58206.6436, 9.524567490000001}, ahigh = {1200390.3, -5027.0053, 10.58830594, -0.005044326100000001, 1.488547375e-006, -1.785922508e-010, 8.113013866e-015}, bhigh = {91707.40909999999, -47.6833632}, R_s = R_NASA_2002/V.MM);
          constant IdealGases.Common.DataRecord Vplus(name = "Vplus", MM = 0.0509409514, Hf = 23041293.47297585, H0 = 155038.5452753833, Tlimit = 1000, alow = {75688.3446, -841.527382, 7.55923271, -0.01441722656, 2.038356397e-005, -1.289073883e-008, 3.065656561e-012}, blow = {144447.8191, -19.91067645}, ahigh = {2347072.054, -9021.197190000001, 14.77349798, -0.00689189688, 1.968884877e-006, -2.539798544e-010, 1.226783122e-014}, bhigh = {195835.1444, -78.5559293}, R_s = R_NASA_2002/Vplus.MM);
          constant IdealGases.Common.DataRecord Vminus(name = "Vminus", MM = 0.0509420486, Hf = 9037446.974600077, H0 = 154651.4758733122, Tlimit = 1000, alow = {-3799.27356, 231.3840448, 1.72560819, 0.001429275357, -1.506038188e-006, 8.491815170000001e-010, -1.987980413e-013}, blow = {53474.0292, 12.61900982}, ahigh = {26001.0043, 2.096334097, 2.498006548, 8.991278839999999e-007, -2.139749508e-010, 2.581021334e-014, -1.240812796e-018}, bhigh = {54700.0708, 7.97790024}, R_s = R_NASA_2002/Vminus.MM);
          constant IdealGases.Common.DataRecord VCL4(name = "VCL4", MM = 0.1927535, Hf = -2734365.290383832, H0 = 113010.129517752, Tlimit = 1000, alow = {77198.3471, -1702.85404, 18.82697965, -0.01130896832, 1.266950765e-005, -7.625019339999999e-009, 1.907582465e-012}, blow = {-58637.4854, -65.59171105999999}, ahigh = {-1717776.251, 4550.441049999999, 8.164464799999999, 0.002224875998, -4.094111780000001e-007, 3.2717875e-011, -8.8586908e-016}, bhigh = {-96906.20060000001, 4.348293098}, R_s = R_NASA_2002/VCL4.MM);
          constant IdealGases.Common.DataRecord VN(name = "VN", MM = 0.0649482, Hf = 8052571.125912651, H0 = 135488.6509556847, Tlimit = 1000, alow = {-15817.37285, 486.816542, -1.045200388, 0.01685261043, -2.334616543e-005, 1.58871005e-008, -4.27908088e-012}, blow = {59814.814, 31.44995263}, ahigh = {1018619.667, -3932.30557, 9.856823609999999, -0.00328922171, 1.005181767e-006, -1.243211436e-010, 5.48677656e-015}, bhigh = {85573.18339999999, -35.52830762}, R_s = R_NASA_2002/VN.MM);
          constant IdealGases.Common.DataRecord VO(name = "VO", MM = 0.0669409, Hf = 2219610.223346266, H0 = 131057.4850353073, Tlimit = 1000, alow = {-13116.19784, 374.781697, 0.0930083486, 0.01244977714, -1.688540028e-005, 1.142443381e-008, -3.04058932e-012}, blow = {15237.8992, 25.36811755}, ahigh = {2986190.283, -10113.44974, 17.18161749, -0.00787670503, 2.562279547e-006, -3.54740035e-010, 1.770268056e-014}, bhigh = {79612.5488, -87.89993010000001}, R_s = R_NASA_2002/VO.MM);
          constant IdealGases.Common.DataRecord VO2(name = "VO2", MM = 0.0829403, Hf = -2805604.211704081, H0 = 128073.4335419573, Tlimit = 1000, alow = {-6678.58586, 391.159758, -1.028549847, 0.02401523419, -3.33737881e-005, 2.283623543e-008, -6.1991431e-012}, blow = {-30746.09276, 32.7791238}, ahigh = {121063.2401, -1627.832993, 9.252713099999999, -0.001572703139, 5.23143016e-007, -6.476071140000001e-011, 2.847226026e-015}, bhigh = {-20973.06345, -25.47380687}, R_s = R_NASA_2002/VO2.MM);
          constant IdealGases.Common.DataRecord V4O10(name = "V4O10", MM = 0.36376, Hf = -7766561.705520123, H0 = 101154.6981526281, Tlimit = 1000, alow = {338573.916, -5353.92926, 29.93220131, 0.0581883652, -9.69634016e-005, 7.27475699e-008, -2.091628357e-011}, blow = {-318934.937, -146.6398396}, ahigh = {-1360273.27, -1341.69286, 40.9913859, -0.000393226553, 8.62849412e-008, -9.83594409e-012, 4.53563729e-016}, bhigh = {-348461.612, -190.7911348}, R_s = R_NASA_2002/V4O10.MM);
          constant IdealGases.Common.DataRecord W(name = "W", MM = 0.18384, Hf = 4630349.902088773, H0 = 33814.87162750217, Tlimit = 1000, alow = {159522.3922, -2673.843928, 20.60469727, -0.0625231523, 0.0001105654838, -8.45351161e-008, 2.336187771e-011}, blow = {113964.8616, -90.118369}, ahigh = {-8048745.96, 14657.00424, -0.2508531501, -0.002596486992, 1.409225475e-006, -2.233011706e-010, 1.262640862e-014}, bhigh = {-3091.130919, 39.5582219}, R_s = R_NASA_2002/W.MM);
          constant IdealGases.Common.DataRecord Wplus(name = "Wplus", MM = 0.1838394514, Hf = 8854687.895353457, H0 = 33840.75046255279, Tlimit = 1000, alow = {-196928.4929, 2670.137332, -11.31686913, 0.0330818373, -3.6290355e-005, 2.066142971e-008, -4.808285562e-012}, blow = {182095.0862, 85.5210448}, ahigh = {6387743.399999999, -20618.11463, 27.59291576, -0.01244535845, 3.27120049e-006, -4.065463720000001e-010, 1.912595872e-014}, bhigh = {324517.443, -171.6919194}, R_s = R_NASA_2002/Wplus.MM);
          constant IdealGases.Common.DataRecord Wminus(name = "Wminus", MM = 0.1838405486, Hf = 4168783.948026143, H0 = 33710.8872182728, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {91429.8137, 8.46116967}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {91429.8137, 8.46116967}, R_s = R_NASA_2002/Wminus.MM);
          constant IdealGases.Common.DataRecord WCL6(name = "WCL6", MM = 0.396558, Hf = -1244993.166195109, H0 = 77645.5272620903, Tlimit = 1000, alow = {33393.9167, -1697.36608, 25.60612352, -0.01425247881, 1.739682668e-005, -1.120537864e-008, 2.95152289e-012}, blow = {-56730.59239999999, -97.41466299000001}, ahigh = {-151673.5473, -34.5137925, 19.02867176, -1.242486969e-005, 2.917675103e-009, -3.50598144e-013, 1.685355887e-017}, bhigh = {-65357.79790000001, -58.94914959000001}, R_s = R_NASA_2002/WCL6.MM);
          constant IdealGases.Common.DataRecord WO(name = "WO", MM = 0.1998394, Hf = 2010292.820134568, H0 = 46332.76020644578, Tlimit = 1000, alow = {-19337.58411, 493.669084, -0.4116148220000001, 0.01307976507, -1.689145619e-005, 1.092748066e-008, -2.820593541e-012}, blow = {45110.179, 30.02592661}, ahigh = {1262156.956, -4177.263120000001, 9.35828647, -0.00288761222, 8.89393396e-007, -8.955318699999999e-011, 2.504359614e-015}, bhigh = {73133.8064, -31.4488229}, R_s = R_NASA_2002/WO.MM);
          constant IdealGases.Common.DataRecord WOCL4(name = "WOCL4", MM = 0.3416514000000001, Hf = -1678591.101924359, H0 = 65187.43666790184, Tlimit = 1000, alow = {26588.12693, -933.6913239999999, 13.21377385, 0.01270930811, -1.964716509e-005, 1.405106974e-008, -3.89938214e-012}, blow = {-67922.90790000001, -35.94869683}, ahigh = {-304902.8285, -353.942586, 16.26432703, -0.0001058245461, 2.340548846e-008, -2.685852021e-012, 1.245412684e-016}, bhigh = {-72725.46739999999, -49.91761253}, R_s = R_NASA_2002/WOCL4.MM);
          constant IdealGases.Common.DataRecord WO2(name = "WO2", MM = 0.2158388, Hf = 134645.5966211821, H0 = 49642.82603498537, Tlimit = 1000, alow = {3120.918919, 241.3883468, -0.3024119184, 0.02324333417, -3.37881268e-005, 2.380934019e-008, -6.421592880000001e-012}, blow = {1442.005265, 29.57655179}, ahigh = {-753740.6680000001, 3204.64305, 0.6701965600000001, 0.00448823887, -8.858328459999999e-007, 6.24517175e-011, -9.046613900000001e-016}, bhigh = {-17694.2023, 34.0572401}, R_s = R_NASA_2002/WO2.MM);
          constant IdealGases.Common.DataRecord WO2CL2(name = "WO2CL2", MM = 0.2867448, Hf = -2341915.180327594, H0 = 68018.03206195892, Tlimit = 1000, alow = {430.015448, -243.8547856, 7.97630699, 0.01715005722, -2.487975176e-005, 1.737644163e-008, -4.7719284e-012}, blow = {-82328.124, -7.844771421}, ahigh = {-240479.173, -306.8379644, 13.22814502, -9.10022071e-005, 2.00658102e-008, -2.296837607e-012, 1.062829386e-016}, bhigh = {-83674.93059999999, -34.91556626}, R_s = R_NASA_2002/WO2CL2.MM);
          constant IdealGases.Common.DataRecord WO3(name = "WO3", MM = 0.2318382, Hf = -1379087.712896321, H0 = 57229.32200129228, Tlimit = 1000, alow = {7262.46146, 34.2939109, 1.573061955, 0.02754971099, -3.99482731e-005, 2.809371537e-008, -7.77754573e-012}, blow = {-40017.3327, 18.57409963}, ahigh = {1732203.64, -6284.719779999999, 16.81358864, -0.00347208936, 8.079935799999999e-007, -6.589378720000001e-011, 1.142928957e-015}, bhigh = {-2473.075565, -74.0747409}, R_s = R_NASA_2002/WO3.MM);
          constant IdealGases.Common.DataRecord WO3minus(name = "WO3minus", MM = 0.2318387486, Hf = -2805725.811271913, H0 = 59155.9395606572, Tlimit = 1000, alow = {163099.9684, -1967.609682, 12.01970914, 0.001681260779, -5.859360060000001e-006, 5.02861633e-009, -1.434012198e-012}, blow = {-70092.03989999999, -39.3690104}, ahigh = {463783.251, -1347.089334, 9.773637559999999, 0.001071395459, -3.84240366e-007, 5.7375319e-011, -3.157605982e-015}, bhigh = {-72395.1557, -23.91116343}, R_s = R_NASA_2002/WO3minus.MM);
          constant IdealGases.Common.DataRecord Xe(name = "Xe", MM = 0.131293, Hf = 0, H0 = 47203.03443443291, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {-745.375, 6.164454205}, ahigh = {4025.22668, -12.09507521, 2.514153347, -8.248102080000001e-006, 2.530232618e-009, -3.89233323e-013, 2.360439138e-017}, bhigh = {-668.5800730000001, 6.063710715}, R_s = R_NASA_2002/Xe.MM);
          constant IdealGases.Common.DataRecord Xeplus(name = "Xeplus", MM = 0.1312924514, Hf = 8961309.042935578, H0 = 47203.23167033196, Tlimit = 1000, alow = {100.292362, -1.218753648, 2.506016493, -1.547411334e-005, 2.191372741e-008, -1.623684074e-011, 4.929132670000001e-015}, blow = {140766.5368, 7.516712465}, ahigh = {-12416.83887, -150.0654643, 2.964678293, -0.000469339666, 1.959138719e-007, -3.037761925e-011, 1.637361082e-015}, bhigh = {141496.6808, 4.565685735}, R_s = R_NASA_2002/Xeplus.MM);
          constant IdealGases.Common.DataRecord Zn(name = "Zn", MM = 0.06539, Hf = 1994188.713870623, H0 = 94776.38782688484, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {14938.05072, 5.11886101}, ahigh = {-175559.1489, 498.413924, 1.969386292, 0.0002608808787, -5.62719508e-008, 2.723336049e-012, 4.266685808e-016}, bhigh = {11737.73458, 8.961085649999999}, R_s = R_NASA_2002/Zn.MM);
          constant IdealGases.Common.DataRecord Znplus(name = "Znplus", MM = 0.06538945139999999, Hf = 15950586.91683717, H0 = 94777.18297541796, Tlimit = 1000, alow = {0.000409834494, -4.34358162e-006, 2.500000019, -4.389036810000001e-011, 5.5639692e-014, -3.63822826e-017, 9.607881994999999e-021}, blow = {124697.9918, 5.8119955}, ahigh = {-343617.946, 956.7355239999999, 1.511478952, 0.000461346796, -8.786800980000001e-008, 7.558567779999999e-013, 1.168827311e-015}, bhigh = {118532.1933, 13.0074267}, R_s = R_NASA_2002/Znplus.MM);
          constant IdealGases.Common.DataRecord Zr(name = "Zr", MM = 0.091224, Hf = 6569747.116986759, H0 = 74712.91546084364, Tlimit = 1000, alow = {67158.9996, -943.5981740000001, 6.35975618, -0.0009790119730000001, -7.60822415e-006, 9.30871743e-009, -3.124675586e-012}, blow = {75880.19469999999, -16.65770522}, ahigh = {6006771.84, -15669.60605, 17.9698235, -0.00676340965, 1.733678968e-006, -2.064699786e-010, 9.334092610000001e-015}, bhigh = {173463.6249, -105.1117377}, R_s = R_NASA_2002/Zr.MM);
          constant IdealGases.Common.DataRecord Zrplus(name = "Zrplus", MM = 0.0912234514, Hf = 13661468.32721131, H0 = 81907.57842779889, Tlimit = 1000, alow = {173984.2193, -2224.598466, 14.00787829, -0.02378785396, 2.641058912e-005, -1.442565487e-008, 3.135982142e-012}, blow = {159821.0714, -58.1672881}, ahigh = {729813.716, -2017.117556, 5.0374983, -0.000550337195, 1.023753499e-007, -1.261537793e-011, 7.092401041999999e-016}, bhigh = {162088.4945, -9.820640859999999}, R_s = R_NASA_2002/Zrplus.MM);
          constant IdealGases.Common.DataRecord Zrminus(name = "Zrminus", MM = 0.09122454860000001, Hf = 6061442.961198715, H0 = 84949.69960311757, Tlimit = 1000, alow = {30466.62367, -807.427721, 9.21300611, -0.01614342054, 1.908653551e-005, -1.138888914e-008, 2.745019116e-012}, blow = {69030.3403, -28.62644371}, ahigh = {84718.61159999999, 317.543934, 2.251491246, 0.0001018645389, -2.285208242e-008, 2.647293502e-012, -1.235813604e-016}, bhigh = {64223.376, 10.81261057}, R_s = R_NASA_2002/Zrminus.MM);
          constant IdealGases.Common.DataRecord ZrN(name = "ZrN", MM = 0.1052307, Hf = 6779124.342991162, H0 = 84223.2352345846, Tlimit = 1000, alow = {22591.09156, -180.2590198, 3.130058377, 0.00542770928, -8.264614840000001e-006, 5.95843822e-009, -1.670274535e-012}, blow = {85788.81490000001, 8.470724779999999}, ahigh = {-72557.9089, -81.267966, 4.5599244, 1.29116165e-005, 5.203830769999999e-009, -5.92743667e-013, 2.731548854e-017}, bhigh = {84686.48390000001, 1.493633264}, R_s = R_NASA_2002/ZrN.MM);
          constant IdealGases.Common.DataRecord ZrO(name = "ZrO", MM = 0.1072234, Hf = 782690.2336616821, H0 = 83658.11940304076, Tlimit = 1000, alow = {-509176.14, 8652.77009, -52.9474015, 0.1728961761, -0.0002457230895, 1.672135156e-007, -4.423012380000001e-011}, blow = {-30951.29818, 313.2576719}, ahigh = {464809.831, 344.231447, 4.81577918, -0.000466063314, 2.140489079e-007, -2.054364483e-011, 4.08466776e-016}, bhigh = {7317.3407, 1.502933548}, R_s = R_NASA_2002/ZrO.MM);
          constant IdealGases.Common.DataRecord ZrOplus(name = "ZrOplus", MM = 0.1072228514, Hf = 6720713.957808437, H0 = 88265.83024446596, Tlimit = 1000, alow = {10329.11549, 73.0466122, 2.606345299, 0.005099300290000001, -6.25033876e-006, 3.79746002e-009, -9.198416899999999e-013}, blow = {85332.33779999999, 12.67311019}, ahigh = {-493716.656, 669.990076, 4.57535347, -0.00069232379, 4.28060094e-007, -7.54766022e-011, 4.41427986e-015}, bhigh = {80188.80660000001, 2.928943704}, R_s = R_NASA_2002/ZrOplus.MM);
          constant IdealGases.Common.DataRecord ZrO2(name = "ZrO2", MM = 0.1232228, Hf = -2572922.681516732, H0 = 97451.63232778349, Tlimit = 1000, alow = {36376.49, -262.0658297, 3.69286687, 0.01214524156, -1.822445342e-005, 1.299215204e-008, -3.61590011e-012}, blow = {-38019.9088, 8.290857600000001}, ahigh = {2854363.887, -8738.589889999999, 16.21315114, -0.004417922830000001, 8.959096920000001e-007, -4.054667109999999e-011, -2.147732083e-015}, bhigh = {15275.10023, -74.8199549}, R_s = R_NASA_2002/ZrO2.MM);
        end SingleGasesData;
      end Common;
    end IdealGases;
  end Media;

  package Thermal "Library of thermal system components to model heat transfer and simple thermo-fluid pipe flow"
    extends Modelica.Icons.Package;
    import Modelica.Units.SI;

    package HeatTransfer "Library of 1-dimensional heat transfer with lumped elements"
      extends Modelica.Icons.Package;

      package Sensors "Thermal sensors"
        extends Modelica.Icons.SensorsPackage;

        model HeatFlowSensor "Heat flow rate sensor"
          extends Modelica.Icons.RoundSensor;
          Modelica.Blocks.Interfaces.RealOutput Q_flow(unit = "W") "Heat flow from port_a to port_b as output signal";
          Interfaces.HeatPort_a port_a;
          Interfaces.HeatPort_b port_b;
        equation
          port_a.T = port_b.T;
          port_a.Q_flow + port_b.Q_flow = 0;
          Q_flow = port_a.Q_flow;
        end HeatFlowSensor;
      end Sensors;

      package Sources "Thermal sources"
        extends Modelica.Icons.SourcesPackage;

        model PrescribedHeatFlow "Prescribed heat flow boundary condition"
          parameter SI.Temperature T_ref = 293.15 "Reference temperature";
          parameter SI.LinearTemperatureCoefficient alpha = 0 "Temperature coefficient of heat flow rate";
          Modelica.Blocks.Interfaces.RealInput Q_flow(unit = "W");
          Interfaces.HeatPort_b port;
        equation
          port.Q_flow = -Q_flow*(1 + alpha*(port.T - T_ref));
        end PrescribedHeatFlow;
      end Sources;

      package Interfaces "Connectors and partial models"
        extends Modelica.Icons.InterfacesPackage;

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
      end Interfaces;
    end HeatTransfer;
  end Thermal;

  package Math "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices"
    extends Modelica.Icons.Package;

    package BooleanVectors "Library of functions operating on Boolean vectors"
      extends Modelica.Icons.Package;

      function allTrue "Returns true, if Boolean input vector is non-empty and all elements are true ('and')"
        extends Modelica.Icons.Function;
        input Boolean b[:] "Boolean vector";
        output Boolean result = size(b, 1) > 0 and min(b) "= true, if all elements of b are true";
      algorithm
        annotation(Inline = true);
      end allTrue;
    end BooleanVectors;

    package Matrices "Library of functions operating on matrices"
      extends Modelica.Icons.Package;

      function leastSquares "Solve linear equation A*x = b (exactly if possible, or otherwise in a least square sense; A may be non-square and may be rank deficient)"
        extends Modelica.Icons.Function;
        input Real A[:, :] "Matrix A";
        input Real b[size(A, 1)] "Vector b";
        input Real rcond = 100*Modelica.Constants.eps "Reciprocal condition number to estimate the rank of A";
        output Real x[size(A, 2)] "Vector x such that min|A*x-b|^2 if size(A,1) >= size(A,2) or min|x|^2 and A*x=b, if size(A,1) < size(A,2)";
        output Integer rank "Rank of A";
      protected
        Integer info;
        Real xx[max(size(A, 1), size(A, 2))];
      algorithm
        if min(size(A)) > 0 then
          (xx, info, rank) := LAPACK.dgelsy_vec(A, b, rcond);
          x := xx[1:size(A, 2)];
          assert(info == 0, "Solving an overdetermined or underdetermined linear system\n" + "of equations with function \"Matrices.leastSquares\" failed.");
        else
          x := fill(0.0, size(A, 2));
        end if;
      end leastSquares;

      package LAPACK "Interface to LAPACK library (should usually not directly be used but only indirectly via Modelica.Math.Matrices)"
        extends Modelica.Icons.FunctionsPackage;

        pure function dgelsy_vec "Compute the minimum-norm solution to a real linear least squares problem with rank deficient A"
          extends Modelica.Icons.Function;
          input Real A[:, :];
          input Real b[size(A, 1)];
          input Real rcond = 0.0 "Reciprocal condition number to estimate rank";
          output Real x[max(size(A, 1), size(A, 2))] = cat(1, b, zeros(max(nrow, ncol) - nrow)) "solution is in first size(A,2) rows";
          output Integer info;
          output Integer rank "Effective rank of A";
        protected
          Integer nrow = size(A, 1);
          Integer ncol = size(A, 2);
          Integer nrhs = 1;
          Integer nx = max(nrow, ncol);
          Integer lwork = max(min(nrow, ncol) + 3*ncol + 1, 2*min(nrow, ncol) + 1);
          Real work[max(min(size(A, 1), size(A, 2)) + 3*size(A, 2) + 1, 2*min(size(A, 1), size(A, 2)) + 1)];
          Real Awork[size(A, 1), size(A, 2)] = A;
          Integer jpvt[size(A, 2)] = zeros(ncol);
          external "FORTRAN 77" dgelsy(nrow, ncol, nrhs, Awork, nrow, x, nx, jpvt, rcond, rank, work, lwork, info) annotation(Library = "lapack");
        end dgelsy_vec;

        pure function dhseqr "Compute eigenvalues of a matrix H using lapack routine DHSEQR for Hessenberg form matrix"
          extends Modelica.Icons.Function;
          input Real H[:, size(H, 1)] "Matrix H with Hessenberg form";
          input Boolean eigenValuesOnly = true "= true, if only eigenvalues are computed, otherwise compute the Schur form too";
          input String compz = "N" "Specifies the computation of the Schur vectors";
          input Real Z[:, :] = H "Matrix Z";
          output Real alphaReal[size(H, 1)] "Real part of alpha (eigenvalue=(alphaReal+i*alphaImag))";
          output Real alphaImag[size(H, 1)] "Imaginary part of alpha (eigenvalue=(alphaReal+i*alphaImag))";
          output Integer info;
          output Real Ho[:, :] = H "Schur decomposition (if eigenValuesOnly==false, unspecified else)";
          output Real Zo[:, :] = Z;
          output Real work[3*max(1, size(H, 1))];
        protected
          Integer n = size(H, 1);
          String job = if eigenValuesOnly then "E" else "S";
          Integer ilo = 1;
          Integer ihi = n;
          Integer ldh = max(n, 1);
          Integer lwork = 3*max(1, size(H, 1)) "Dimension of the dwork array used in dhseqr";
          external "FORTRAN 77" dhseqr(job, compz, n, ilo, ihi, Ho, ldh, alphaReal, alphaImag, Zo, ldh, work, lwork, info) annotation(Library = {"lapack"});
        end dhseqr;
      end LAPACK;

      package Utilities "Utility functions that should not be directly utilized by the user"
        extends Modelica.Icons.UtilitiesPackage;

        function eigenvaluesHessenberg "Compute eigenvalues of an upper Hessenberg form matrix"
          extends Modelica.Icons.Function;
          import Modelica.Math.Matrices.LAPACK;
          input Real H[:, size(H, 1)] "Hessenberg matrix H";
          output Real ev[size(H, 1), 2] "Eigenvalues";
          output Integer info = 0;
        protected
          Real alphaReal[size(H, 1)] "Real part of alpha (eigenvalue=(alphaReal+i*alphaImag))";
          Real alphaImag[size(H, 1)] "Imaginary part of alpha (eigenvalue=(alphaReal+i*alphaImag))";
        algorithm
          if size(H, 1) > 0 then
            (alphaReal, alphaImag, info) := LAPACK.dhseqr(H);
          else
            alphaReal := fill(0, size(H, 1));
            alphaImag := fill(0, size(H, 1));
          end if;
          ev := [alphaReal, alphaImag];
        end eigenvaluesHessenberg;
      end Utilities;
    end Matrices;

    package Polynomials "Library of functions operating on polynomials (including polynomial fitting)"
      extends Modelica.Icons.FunctionsPackage;

      function evaluate "Evaluate polynomial at a given abscissa value"
        extends Modelica.Icons.Function;
        input Real p[:] "Polynomial coefficients (p[1] is coefficient of highest power)";
        input Real u "Abscissa value";
        output Real y "Value of polynomial at u";
      algorithm
        y := p[1];
        for j in 2:size(p, 1) loop
          y := p[j] + u*y;
        end for;
        annotation(derivative(zeroDerivative = p) = evaluate_der);
      end evaluate;

      function evaluate_der "Evaluate derivative of polynomial at a given abscissa value"
        extends Modelica.Icons.Function;
        input Real p[:] "Polynomial coefficients (p[1] is coefficient of highest power)";
        input Real u "Abscissa value";
        input Real du "Delta of abscissa value";
        output Real dy "Value of derivative of polynomial at u";
      protected
        Integer n = size(p, 1);
      algorithm
        dy := p[1]*(n - 1);
        for j in 2:size(p, 1) - 1 loop
          dy := p[j]*(n - j) + u*dy;
        end for;
        dy := dy*du;
      end evaluate_der;

      encapsulated function roots "Compute zeros of a polynomial where the highest coefficient is assumed as not to be zero"
        import Modelica.Math.Matrices;
        import Modelica;
        extends Modelica.Icons.Function;
        input Real p[:] "Vector with polynomial coefficients p[1]*x^n + p[2]*x^(n-1) + p[n]*x +p[n-1]";
        output Real roots[max(0, size(p, 1) - 1), 2] = fill(0, max(0, size(p, 1) - 1), 2) "roots[:,1] and roots[:,2] are the real and imaginary parts of the roots of polynomial p";
      protected
        Integer np = size(p, 1);
        Integer n = size(p, 1) - 1;
        Real A[max(size(p, 1) - 1, 0), max(size(p, 1) - 1, 0)] "Companion matrix";
        Real ev[max(size(p, 1) - 1, 0), 2] "Eigenvalues";
      algorithm
        if n > 0 then
          assert(abs(p[1]) > 0, "Computing the roots of a polynomial with function \"Modelica.Math.Polynomials.roots\"\n" + "failed because the first element of the coefficient vector is zero, but should not be.");
          A[1, :] := -p[2:np]/p[1];
          A[2:n, :] := [identity(n - 1), zeros(n - 1)];
          roots := Matrices.Utilities.eigenvaluesHessenberg(A);
        else
        end if;
      end roots;
    end Polynomials;

    package Icons "Icons for Math"
      extends Modelica.Icons.IconsPackage;

      partial function AxisLeft "Basic icon for mathematical function with y-axis on left side" end AxisLeft;

      partial function AxisCenter "Basic icon for mathematical function with y-axis in the center" end AxisCenter;
    end Icons;

    function asin "Inverse sine (-1 <= u <= 1)"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u "Independent variable";
      output Modelica.Units.SI.Angle y "Dependent variable y=asin(u)";
    algorithm
      y := .asin(u);
      annotation(Inline = true);
    end asin;

    function exp "Exponential, base e"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u "Independent variable";
      output Real y "Dependent variable y=exp(u)";
    algorithm
      y := .exp(u);
      annotation(Inline = true);
    end exp;

    function log "Natural (base e) logarithm (u shall be > 0)"
      extends Modelica.Math.Icons.AxisLeft;
      input Real u "Independent variable";
      output Real y "Dependent variable y=ln(u)";
    algorithm
      y := .log(u);
      annotation(Inline = true);
    end log;
  end Math;

  package Utilities "Library of utility functions dedicated to scripting (operating on files, streams, strings, system)"
    extends Modelica.Icons.UtilitiesPackage;

    package Streams "Read from files and write to files"
      extends Modelica.Icons.FunctionsPackage;

      impure function print "Print string to terminal or file"
        extends Modelica.Icons.Function;
        input String string = "" "String to be printed";
        input String fileName = "" "File where to print (empty string is the terminal)";
        external "C" ModelicaInternal_print(string, fileName) annotation(IncludeDirectory = "modelica://Modelica/Resources/C-Sources", Include = "#include \"ModelicaInternal.h\"", Library = "ModelicaExternalC");
      end print;

      pure function error "Print error message and cancel all actions - in case of an unrecoverable error"
        extends Modelica.Icons.Function;
        input String string "String to be printed to error message window";
      algorithm
        assert(false, string);
      end error;
    end Streams;

    package Strings "Operations on strings"
      extends Modelica.Icons.FunctionsPackage;

      pure function compare "Compare two strings lexicographically"
        extends Modelica.Icons.Function;
        input String string1;
        input String string2;
        input Boolean caseSensitive = true "= false, if case of letters is ignored";
        output Modelica.Utilities.Types.Compare result "Result of comparison";
        external "C" result = ModelicaStrings_compare(string1, string2, caseSensitive) annotation(IncludeDirectory = "modelica://Modelica/Resources/C-Sources", Include = "#include \"ModelicaStrings.h\"", Library = "ModelicaExternalC");
      end compare;

      function isEqual "Determine whether two strings are identical"
        extends Modelica.Icons.Function;
        input String string1;
        input String string2;
        input Boolean caseSensitive = true "= false, if lower and upper case are ignored for the comparison";
        output Boolean identical "True, if string1 is identical to string2";
      algorithm
        identical := compare(string1, string2, caseSensitive) == Types.Compare.Equal;
      end isEqual;
    end Strings;

    package Types "Type definitions used in package Modelica.Utilities"
      extends Modelica.Icons.TypesPackage;
      type Compare = enumeration(Less "String 1 is lexicographically less than string 2", Equal "String 1 is identical to string 2", Greater "String 1 is lexicographically greater than string 2") "Enumeration defining comparison of two strings";
    end Types;
  end Utilities;

  package Constants "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)"
    extends Modelica.Icons.Package;
    import Modelica.Units.SI;
    import Modelica.Units.NonSI;
    final constant Real pi = 2*Modelica.Math.asin(1.0);
    final constant Real eps = ModelicaServices.Machine.eps "The difference between 1 and the least value greater than 1 that is representable in the given floating point type";
    final constant Real small = ModelicaServices.Machine.small "Minimum normalized positive floating-point number";
    final constant Real inf = ModelicaServices.Machine.inf "Maximum representable finite floating-point number";
    final constant SI.Velocity c = 299792458 "Speed of light in vacuum";
    final constant SI.ElectricCharge q = 1.602176634e-19 "Elementary charge";
    final constant Real h(final unit = "J.s") = 6.62607015e-34 "Planck constant";
    final constant Real k(final unit = "J/K") = 1.380649e-23 "Boltzmann constant";
    final constant Real R(final unit = "J/(mol.K)") = k*N_A "Molar gas constant";
    final constant Real N_A(final unit = "1/mol") = 6.02214076e23 "Avogadro constant";
    final constant SI.Permeability mu_0 = 1.25663706212e-6 "Magnetic constant";
    final constant NonSI.Temperature_degC T_zero = -273.15 "Absolute zero temperature";
  end Constants;

  package Icons "Library of icons"
    extends Icons.Package;

    partial package ExamplesPackage "Icon for packages containing runnable examples"
      extends Modelica.Icons.Package;
    end ExamplesPackage;

    partial model Example "Icon for runnable examples" end Example;

    partial package Package "Icon for standard packages" end Package;

    partial package BasesPackage "Icon for packages containing base classes"
      extends Modelica.Icons.Package;
    end BasesPackage;

    partial package VariantsPackage "Icon for package containing variants"
      extends Modelica.Icons.Package;
    end VariantsPackage;

    partial package InterfacesPackage "Icon for packages containing interfaces"
      extends Modelica.Icons.Package;
    end InterfacesPackage;

    partial package SourcesPackage "Icon for packages containing sources"
      extends Modelica.Icons.Package;
    end SourcesPackage;

    partial package SensorsPackage "Icon for packages containing sensors"
      extends Modelica.Icons.Package;
    end SensorsPackage;

    partial package UtilitiesPackage "Icon for utility packages"
      extends Modelica.Icons.Package;
    end UtilitiesPackage;

    partial package TypesPackage "Icon for packages containing type definitions"
      extends Modelica.Icons.Package;
    end TypesPackage;

    partial package FunctionsPackage "Icon for packages containing functions"
      extends Modelica.Icons.Package;
    end FunctionsPackage;

    partial package IconsPackage "Icon for packages containing icons"
      extends Modelica.Icons.Package;
    end IconsPackage;

    partial package MaterialPropertiesPackage "Icon for package containing property classes"
      extends Modelica.Icons.Package;
    end MaterialPropertiesPackage;

    partial class RoundSensor "Icon representing a round measurement device" end RoundSensor;

    partial class RectangularSensor "Icon representing a linear measurement device" end RectangularSensor;

    partial function Function "Icon for functions" end Function;

    partial record Record "Icon for records" end Record;
  end Icons;

  package Units "Library of type and unit definitions"
    extends Modelica.Icons.Package;

    package SI "Library of SI unit definitions"
      extends Modelica.Icons.Package;
      type Angle = Real(final quantity = "Angle", final unit = "rad", displayUnit = "deg");
      type Volume = Real(final quantity = "Volume", final unit = "m3");
      type Time = Real(final quantity = "Time", final unit = "s");
      type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
      type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
      type Mass = Real(quantity = "Mass", final unit = "kg", min = 0);
      type Density = Real(final quantity = "Density", final unit = "kg/m3", displayUnit = "g/cm3", min = 0.0);
      type Pressure = Real(final quantity = "Pressure", final unit = "Pa", displayUnit = "bar");
      type AbsolutePressure = Pressure(min = 0.0, nominal = 1e5);
      type PressureDifference = Pressure;
      type DynamicViscosity = Real(final quantity = "DynamicViscosity", final unit = "Pa.s", min = 0);
      type Energy = Real(final quantity = "Energy", final unit = "J");
      type Power = Real(final quantity = "Power", final unit = "W");
      type EnthalpyFlowRate = Real(final quantity = "EnthalpyFlowRate", final unit = "W");
      type Efficiency = Real(final quantity = "Efficiency", final unit = "1", min = 0);
      type MassFlowRate = Real(quantity = "MassFlowRate", final unit = "kg/s");
      type VolumeFlowRate = Real(final quantity = "VolumeFlowRate", final unit = "m3/s");
      type ThermodynamicTemperature = Real(final quantity = "ThermodynamicTemperature", final unit = "K", min = 0.0, start = 288.15, nominal = 300, displayUnit = "degC") "Absolute temperature (use type TemperatureDifference for relative temperatures)" annotation(absoluteValue = true);
      type Temperature = ThermodynamicTemperature;
      type TemperatureDifference = Real(final quantity = "ThermodynamicTemperature", final unit = "K") annotation(absoluteValue = false);
      type LinearTemperatureCoefficient = Real(final quantity = "LinearTemperatureCoefficient", final unit = "1/K");
      type Compressibility = Real(final quantity = "Compressibility", final unit = "1/Pa");
      type IsothermalCompressibility = Compressibility;
      type HeatFlowRate = Real(final quantity = "Power", final unit = "W");
      type ThermalConductivity = Real(final quantity = "ThermalConductivity", final unit = "W/(m.K)");
      type HeatCapacity = Real(final quantity = "HeatCapacity", final unit = "J/K");
      type SpecificHeatCapacity = Real(final quantity = "SpecificHeatCapacity", final unit = "J/(kg.K)");
      type SpecificEntropy = Real(final quantity = "SpecificEntropy", final unit = "J/(kg.K)");
      type SpecificEnergy = Real(final quantity = "SpecificEnergy", final unit = "J/kg");
      type SpecificEnthalpy = SpecificEnergy;
      type DerDensityByPressure = Real(final unit = "s2/m2");
      type DerDensityByTemperature = Real(final unit = "kg/(m3.K)");
      type ElectricCharge = Real(final quantity = "ElectricCharge", final unit = "C");
      type Permeability = Real(final quantity = "Permeability", final unit = "V.s/(A.m)");
      type MolarMass = Real(final quantity = "MolarMass", final unit = "kg/mol", min = 0);
      type MolarVolume = Real(final quantity = "MolarVolume", final unit = "m3/mol", min = 0);
      type MassFraction = Real(final quantity = "MassFraction", final unit = "1", min = 0, max = 1);
      type MoleFraction = Real(final quantity = "MoleFraction", final unit = "1", min = 0, max = 1);
      type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
    end SI;

    package NonSI "Type definitions of non SI and other units"
      extends Modelica.Icons.Package;
      type Temperature_degC = Real(final quantity = "ThermodynamicTemperature", final unit = "degC") "Absolute temperature in degree Celsius (for relative temperature use Modelica.Units.SI.TemperatureDifference)" annotation(absoluteValue = true);
      type Pressure_bar = Real(final quantity = "Pressure", final unit = "bar") "Absolute pressure in bar";
    end NonSI;

    package Conversions "Conversion functions to/from non SI units and type definitions of non SI units"
      extends Modelica.Icons.Package;

      function to_degC "Convert from kelvin to degree Celsius"
        extends Modelica.Units.Icons.Conversion;
        input SI.Temperature Kelvin "Value in kelvin";
        output Modelica.Units.NonSI.Temperature_degC Celsius "Value in degree Celsius";
      algorithm
        Celsius := Kelvin + Modelica.Constants.T_zero;
        annotation(Inline = true);
      end to_degC;

      function from_degC "Convert from degree Celsius to kelvin"
        extends Modelica.Units.Icons.Conversion;
        input Modelica.Units.NonSI.Temperature_degC Celsius "Value in degree Celsius";
        output SI.Temperature Kelvin "Value in kelvin";
      algorithm
        Kelvin := Celsius - Modelica.Constants.T_zero;
        annotation(Inline = true);
      end from_degC;

      function to_bar "Convert from Pascal to bar"
        extends Modelica.Units.Icons.Conversion;
        input SI.Pressure Pa "Value in Pascal";
        output Modelica.Units.NonSI.Pressure_bar bar "Value in bar";
      algorithm
        bar := Pa/1e5;
        annotation(Inline = true);
      end to_bar;
    end Conversions;

    package Icons "Icons for Units"
      extends Modelica.Icons.IconsPackage;

      partial function Conversion "Base icon for conversion functions" end Conversion;
    end Icons;
  end Units;
  annotation(version = "4.1.0", versionDate = "2025-05-23", dateModified = "2025-05-23 15:00:00Z");
end Modelica;

package Buildings "Library with models for building energy and control systems"
  extends Modelica.Icons.Package;

  package Fluid "Package with models for fluid flow systems"
    extends Modelica.Icons.Package;

    package Delays "Package with delay models"
      extends Modelica.Icons.Package;

      model DelayFirstOrder "Delay element, approximated by a first order differential equation"
        extends Buildings.Fluid.MixingVolumes.MixingVolume(final V = V_nominal, final massDynamics = energyDynamics, final mSenFac = 1);
        parameter Modelica.Units.SI.Time tau = 60 "Time constant at nominal flow";
      protected
        parameter Modelica.Units.SI.Volume V_nominal = m_flow_nominal*tau/rho_default "Volume of delay element";
      end DelayFirstOrder;
    end Delays;

    package FixedResistances "Package with models for fixed flow resistances"
      extends Modelica.Icons.Package;

      model PressureDrop "Fixed flow resistance with dp and m_flow as parameter"
        extends Buildings.Fluid.BaseClasses.PartialResistance(final m_flow_turbulent = if computeFlowResistance then deltaM*m_flow_nominal_pos else 0);
        parameter Real deltaM(min = 1E-6) = 0.3 "Fraction of nominal mass flow rate where transition to turbulent occurs" annotation(Evaluate = true);
        final parameter Real k = if computeFlowResistance then m_flow_nominal_pos/sqrt(dp_nominal_pos) else 0 "Flow coefficient, k=m_flow/sqrt(dp), with unit=(kg.m)^(1/2)";
      protected
        parameter Boolean disableComputeFlowResistance_internal = false "=false to disable computation of flow resistance" annotation(Evaluate = true);
        final parameter Boolean computeFlowResistance = (dp_nominal_pos > Modelica.Constants.eps) and not disableComputeFlowResistance_internal "Flag to enable/disable computation of flow resistance" annotation(Evaluate = true);
        final parameter Real coeff = if linearized and computeFlowResistance then if from_dp then k^2/m_flow_nominal_pos else m_flow_nominal_pos/k^2 else 0 "Precomputed coefficient to avoid division by parameter";
      initial equation
        if computeFlowResistance then
          assert(m_flow_turbulent > 0, "m_flow_turbulent must be bigger than zero.");
        end if;
        assert(m_flow_nominal_pos > 0, "m_flow_nominal_pos must be non-zero. Check parameters.");
      equation
        if computeFlowResistance then
          if linearized then
            if from_dp then
              m_flow = dp*coeff;
            else
              dp = m_flow*coeff;
            end if;
          else
            if homotopyInitialization then
              if from_dp then
                m_flow = homotopy(actual = Buildings.Fluid.BaseClasses.FlowModels.basicFlowFunction_dp(dp = dp, k = k, m_flow_turbulent = m_flow_turbulent), simplified = m_flow_nominal_pos*dp/dp_nominal_pos);
              else
                dp = homotopy(actual = Buildings.Fluid.BaseClasses.FlowModels.basicFlowFunction_m_flow(m_flow = m_flow, k = k, m_flow_turbulent = m_flow_turbulent), simplified = dp_nominal_pos*m_flow/m_flow_nominal_pos);
              end if;
            else
              if from_dp then
                m_flow = Buildings.Fluid.BaseClasses.FlowModels.basicFlowFunction_dp(dp = dp, k = k, m_flow_turbulent = m_flow_turbulent);
              else
                dp = Buildings.Fluid.BaseClasses.FlowModels.basicFlowFunction_m_flow(m_flow = m_flow, k = k, m_flow_turbulent = m_flow_turbulent);
              end if;
            end if;
          end if;
        else
          dp = 0;
        end if;
      end PressureDrop;
    end FixedResistances;

    package MixingVolumes "Package with mixing volumes"
      extends Modelica.Icons.Package;

      model MixingVolume "Mixing volume with inlet and outlet ports (flow reversal is allowed)"
        extends Buildings.Fluid.MixingVolumes.BaseClasses.PartialMixingVolume(final initialize_p = not Medium.singleState, steBal(final use_C_flow = use_C_flow), dynBal(final use_C_flow = use_C_flow));
        parameter Boolean use_C_flow = false "Set to true to enable input connector for trace substance" annotation(Evaluate = true);
        Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort(T(start = T_start)) "Heat port for heat exchange with the control volume";
        Modelica.Blocks.Interfaces.RealInput C_flow[Medium.nC] if use_C_flow "Trace substance mass flow rate added to the medium";
      equation
        connect(heaFloSen.port_a, heatPort);
        connect(C_flow, steBal.C_flow);
        connect(C_flow, dynBal.C_flow);
      end MixingVolume;

      package BaseClasses "Package with base classes for Buildings.Fluid.MixingVolumes"
        extends Modelica.Icons.BasesPackage;

        model PartialMixingVolume "Partial mixing volume with inlet and outlet ports (flow reversal is allowed)"
          extends Buildings.Fluid.Interfaces.LumpedVolumeDeclarations;
          parameter Boolean initialize_p = not Medium.singleState "= true to set up initial equations for pressure" annotation(HideResult = true, Evaluate = true);
          constant Boolean prescribedHeatFlowRate = false "Set to true if the model has a prescribed heat flow at its heatPort. If the heat flow rate at the heatPort is only based on temperature difference, then set to false";
          constant Boolean simplify_mWat_flow = true "Set to true to cause port_a.m_flow + port_b.m_flow = 0 even if mWat_flow is non-zero";
          parameter Modelica.Units.SI.MassFlowRate m_flow_nominal(min = 0) "Nominal mass flow rate";
          parameter Integer nPorts = 0 "Number of ports" annotation(Evaluate = true);
          parameter Modelica.Units.SI.MassFlowRate m_flow_small(min = 0) = 1E-4*abs(m_flow_nominal) "Small mass flow rate for regularization of zero flow";
          parameter Boolean allowFlowReversal = true "= false to simplify equations, assuming, but not enforcing, no flow reversal. Used only if model has two ports." annotation(Evaluate = true);
          parameter Modelica.Units.SI.Volume V "Volume";
          Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b ports[nPorts](redeclare each package Medium = Medium, each h_outflow(nominal = Medium.h_default), each Xi_outflow(each nominal = 0.01)) "Fluid inlets and outlets";
          Medium.Temperature T = Medium.temperature_phX(p = p, h = hOut_internal, X = if Medium.reducedX then cat(1, Xi, {1 - sum(Xi)}) else Xi) "Temperature of the fluid";
          Modelica.Blocks.Interfaces.RealOutput U(unit = "J") "Internal energy of the component";
          Modelica.Units.SI.Pressure p = if nPorts > 0 then ports[1].p else p_start "Pressure of the fluid";
          Modelica.Blocks.Interfaces.RealOutput m(unit = "kg") "Mass of the component";
          Modelica.Units.SI.MassFraction Xi[Medium.nXi] = XiOut_internal "Species concentration of the fluid";
          Modelica.Blocks.Interfaces.RealOutput mXi[Medium.nXi](each unit = "kg") "Species mass of the component";
          Medium.ExtraProperty C[Medium.nC](nominal = C_nominal) = COut_internal "Trace substance mixture content";
          Modelica.Blocks.Interfaces.RealOutput mC[Medium.nC](each unit = "kg") "Trace substance mass of the component";
        protected
          Buildings.Fluid.Interfaces.StaticTwoPortConservationEquation steBal(final simplify_mWat_flow = simplify_mWat_flow, redeclare final package Medium = Medium, final m_flow_nominal = m_flow_nominal, final allowFlowReversal = allowFlowReversal, final m_flow_small = m_flow_small, final prescribedHeatFlowRate = prescribedHeatFlowRate, hOut(start = Medium.specificEnthalpy_pTX(p = p_start, T = T_start, X = X_start))) if useSteadyStateTwoPort "Model for steady-state balance if nPorts=2";
          Buildings.Fluid.Interfaces.ConservationEquation dynBal(final simplify_mWat_flow = simplify_mWat_flow, redeclare final package Medium = Medium, final energyDynamics = energyDynamics, final massDynamics = massDynamics, final p_start = p_start, final T_start = T_start, final X_start = X_start, final C_start = C_start, final C_nominal = C_nominal, final fluidVolume = V, final initialize_p = initialize_p, m(start = V*rho_start), nPorts = nPorts, final mSenFac = mSenFac) if not useSteadyStateTwoPort "Model for dynamic energy balance";
          parameter Modelica.Units.SI.Density rho_start = Medium.density(state = state_start) "Density, used to compute start and guess values";
          final parameter Medium.ThermodynamicState state_default = Medium.setState_pTX(T = Medium.T_default, p = Medium.p_default, X = Medium.X_default[1:Medium.nXi]) "Medium state at default values";
          final parameter Modelica.Units.SI.Density rho_default = Medium.density(state = state_default) "Density, used to compute fluid mass";
          final parameter Medium.ThermodynamicState state_start = Medium.setState_pTX(T = T_start, p = p_start, X = X_start[1:Medium.nXi]) "Medium state at start values";
          final parameter Boolean useSteadyStateTwoPort = (nPorts == 2) and (prescribedHeatFlowRate or (not allowFlowReversal)) and (energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState) and (massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState) and (substanceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState) and (traceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState) "Flag, true if the model has two ports only and uses a steady state balance" annotation(Evaluate = true);
          Modelica.Blocks.Interfaces.RealOutput hOut_internal(unit = "J/kg") "Internal connector for leaving temperature of the component";
          Modelica.Blocks.Interfaces.RealOutput XiOut_internal[Medium.nXi](each unit = "1") "Internal connector for leaving species concentration of the component";
          Modelica.Blocks.Interfaces.RealOutput COut_internal[Medium.nC](each unit = "1") "Internal connector for leaving trace substances of the component";
          Buildings.HeatTransfer.Sources.PrescribedTemperature preTem(port(T(start = T_start))) "Port temperature";
          Modelica.Blocks.Sources.RealExpression portT(y = T) "Port temperature";
          Modelica.Thermal.HeatTransfer.Sensors.HeatFlowSensor heaFloSen(port_a(T(start = T_start)), port_b(T(start = T_start))) "Heat flow sensor";
        equation
          if not allowFlowReversal then
            assert(ports[1].m_flow > -m_flow_small, "In " + getInstanceName() + ": Model has flow reversal,
          but the parameter allowFlowReversal is set to false.
          m_flow_small    = " + String(m_flow_small) + "
          ports[1].m_flow = " + String(ports[1].m_flow) + "
            ");
          end if;
          if useSteadyStateTwoPort then
            connect(steBal.port_a, ports[1]);
            connect(steBal.port_b, ports[2]);
            U = 0;
            mXi = zeros(Medium.nXi);
            m = 0;
            mC = zeros(Medium.nC);
            connect(hOut_internal, steBal.hOut);
            connect(XiOut_internal, steBal.XiOut);
            connect(COut_internal, steBal.COut);
          else
            connect(dynBal.ports, ports);
            connect(U, dynBal.UOut);
            connect(mXi, dynBal.mXiOut);
            connect(m, dynBal.mOut);
            connect(mC, dynBal.mCOut);
            connect(hOut_internal, dynBal.hOut);
            connect(XiOut_internal, dynBal.XiOut);
            connect(COut_internal, dynBal.COut);
          end if;
          connect(portT.y, preTem.T);
          connect(heaFloSen.port_b, preTem.port);
          connect(heaFloSen.Q_flow, steBal.Q_flow);
          connect(heaFloSen.Q_flow, dynBal.Q_flow);
        end PartialMixingVolume;
      end BaseClasses;
    end MixingVolumes;

    package Movers "Package with fan and pump models"
      extends Modelica.Icons.Package;

      model FlowControlled_m_flow "Fan or pump with ideally controlled mass flow rate as input signal"
        extends Buildings.Fluid.Movers.BaseClasses.PartialFlowMachine(final preVar = Buildings.Fluid.Movers.BaseClasses.Types.PrescribedVariable.FlowRate, final computePowerUsingSimilarityLaws = per.havePressureCurve, final stageInputs(each final unit = "kg/s") = massFlowRates, final constInput(final unit = "kg/s") = constantMassFlowRate, final _m_flow_nominal = m_flow_nominal, motSpe(Rising = m_flow_nominal/riseTime, Falling = -m_flow_nominal/riseTime, final y_start = m_flow_start, u(final unit = "kg/s", nominal = m_flow_nominal), y(final unit = "kg/s", nominal = m_flow_nominal)), eff(per(final pressure = if per.havePressureCurve then per.pressure else Buildings.Fluid.Movers.BaseClasses.Characteristics.flowParameters(V_flow = {i/(nOri - 1)*2.0*m_flow_nominal/rho_default for i in 0:(nOri - 1)}, dp = {i/(nOri - 1)*2.0*dp_nominal for i in (nOri - 1):-1:0}), final etaHydMet = if (per.etaHydMet == Buildings.Fluid.Movers.BaseClasses.Types.HydraulicEfficiencyMethod.Power_VolumeFlowRate or per.etaHydMet == Buildings.Fluid.Movers.BaseClasses.Types.HydraulicEfficiencyMethod.EulerNumber) and not per.havePressureCurve then Buildings.Fluid.Movers.BaseClasses.Types.HydraulicEfficiencyMethod.NotProvided else per.etaHydMet, final etaMotMet = if (per.etaMotMet == Buildings.Fluid.Movers.BaseClasses.Types.MotorEfficiencyMethod.Efficiency_MotorPartLoadRatio or per.etaMotMet == Buildings.Fluid.Movers.BaseClasses.Types.MotorEfficiencyMethod.GenericCurve) and (not per.haveWMot_nominal and not per.havePressureCurve) then Buildings.Fluid.Movers.BaseClasses.Types.MotorEfficiencyMethod.NotProvided else per.etaMotMet), r_N(start = if abs(m_flow_nominal) > 1E-8 then m_flow_start/m_flow_nominal else 0)), preSou(m_flow_start = m_flow_start));
        parameter Modelica.Units.SI.MassFlowRate m_flow_nominal(final min = Modelica.Constants.small) "Nominal mass flow rate";
        parameter Modelica.Units.SI.PressureDifference dp_nominal(final min = Modelica.Constants.small, displayUnit = "Pa") = if rho_default < 500 then 500 else 10000 "Nominal pressure raise, used for default pressure curve if not specified in record per";
        parameter Modelica.Units.SI.MassFlowRate m_flow_start(min = 0) = 0 "Initial value of mass flow rate";
        parameter Modelica.Units.SI.MassFlowRate constantMassFlowRate = m_flow_nominal "Constant pump mass flow rate, used when inputType=Constant";
        parameter Modelica.Units.SI.MassFlowRate massFlowRates[:] = m_flow_nominal*{per.speeds[i]/per.speeds[end] for i in 1:size(per.speeds, 1)} "Vector of mass flow rate set points, used when inputType=Stage";
        parameter Modelica.Units.SI.Pressure dpMax(min = 0, displayUnit = "Pa") = 2*max(eff.per.pressure.dp) "Maximum pressure allowed to operate the model, if exceeded, the simulation stops with an error";
        Modelica.Blocks.Interfaces.RealInput m_flow_in(final unit = "kg/s", nominal = m_flow_nominal) if inputType == Buildings.Fluid.Types.InputType.Continuous "Prescribed mass flow rate";
        Modelica.Blocks.Interfaces.RealOutput m_flow_actual(final unit = "kg/s", nominal = m_flow_nominal) "Actual mass flow rate";
      equation
        assert(-dp <= dpMax, "In " + getInstanceName() + ": Model operates with head -dp = " + String(-dp) + " Pa,
          exceeding the pressure allowed by the parameter " + getInstanceName() + ".dpMax.
          This can happen if the model forces a high mass flow rate through a closed actuator,
          or if the performance record is unreasonable. Please verify your model, and
          consider using one of the other pump or fan models.");
        if use_riseTime then
          connect(motSpe.y, preSou.m_flow_in);
        else
          connect(inputSwitch.y, preSou.m_flow_in);
        end if;
        connect(inputSwitch.u, m_flow_in);
        connect(eff.m_flow, senMasFlo.m_flow);
        connect(senMasFlo.m_flow, m_flow_actual);
      end FlowControlled_m_flow;

      package Data "Package containing data for real pumps/fans"
        extends Modelica.Icons.MaterialPropertiesPackage;

        record Generic "Generic data record for movers"
          extends Modelica.Icons.Record;
          parameter Buildings.Fluid.Movers.BaseClasses.Characteristics.flowParameters pressure(V_flow = {0, 0}, dp = {0, 0}) "Volume flow rate vs. total pressure rise" annotation(Evaluate = true);
          final parameter Modelica.Units.SI.VolumeFlowRate V_flow_max = if havePressureCurve then (pressure.V_flow[end] - (pressure.V_flow[end] - pressure.V_flow[end - 1])/(pressure.dp[end] - pressure.dp[end - 1])*pressure.dp[end]) else 0 "Volume flow rate on the curve when pressure rise is zero";
          final parameter Modelica.Units.SI.PressureDifference dpMax(displayUnit = "Pa") = if havePressureCurve then (pressure.dp[1] - (pressure.dp[1] - pressure.dp[2])/(pressure.V_flow[1] - pressure.V_flow[2])*pressure.V_flow[1]) else 0 "Pressure rise on the curve when flow rate is zero";
          parameter Buildings.Fluid.Movers.BaseClasses.Types.HydraulicEfficiencyMethod etaHydMet = if havePressureCurve then Buildings.Fluid.Movers.BaseClasses.Types.HydraulicEfficiencyMethod.EulerNumber else Buildings.Fluid.Movers.BaseClasses.Types.HydraulicEfficiencyMethod.NotProvided "Efficiency computation method for the hydraulic efficiency etaHyd";
          parameter Buildings.Fluid.Movers.BaseClasses.Types.MotorEfficiencyMethod etaMotMet = if powerOrEfficiencyIsHydraulic and havePressureCurve then Buildings.Fluid.Movers.BaseClasses.Types.MotorEfficiencyMethod.GenericCurve else Buildings.Fluid.Movers.BaseClasses.Types.MotorEfficiencyMethod.NotProvided "Efficiency computation method for the motor efficiency etaMot";
          parameter Boolean powerOrEfficiencyIsHydraulic = true "=true if hydraulic power or efficiency is provided, instead of total";
          parameter Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters efficiency(V_flow = {0}, eta = {0.7}) "Total or hydraulic efficiency vs. volumetric flow rate";
          parameter Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters motorEfficiency(V_flow = {0}, eta = {0.7}) "Motor efficiency vs. volumetric flow rate";
          parameter Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters_yMot motorEfficiency_yMot(y = {0}, eta = {0.7}) "Motor efficiency vs. part load ratio yMot, where yMot = WHyd/WMot_nominal";
          parameter Buildings.Fluid.Movers.BaseClasses.Characteristics.powerParameters power(V_flow = {0}, P = {0}) "Power (either consumed or hydraulic) vs. volumetric flow rate";
          parameter Buildings.Fluid.Movers.BaseClasses.Euler.peak peak(V_flow = peak_internal.V_flow, dp = peak_internal.dp, eta = peak_internal.eta) "Volume flow rate, pressure rise, and efficiency (either total or hydraulic) at peak condition";
          final parameter Buildings.Fluid.Movers.BaseClasses.Euler.peak peak_internal = if etaHydMet == Buildings.Fluid.Movers.BaseClasses.Types.HydraulicEfficiencyMethod.EulerNumber then Buildings.Fluid.Movers.BaseClasses.Euler.getPeak(pressure = pressure, power = power) else Buildings.Fluid.Movers.BaseClasses.Euler.peak(V_flow = V_flow_max/2, dp = dpMax/2, eta = max(efficiency.eta)) "Internal peak variable";
          parameter Boolean motorCooledByFluid = true "If true, then motor heat is added to fluid stream";
          parameter Modelica.Units.SI.Power WMot_nominal = if max(power.P) > Modelica.Constants.eps then if powerOrEfficiencyIsHydraulic then max(power.P)*1.2 else max(power.P) else if havePressureCurve then if powerOrEfficiencyIsHydraulic then V_flow_max/2*dpMax/2/peak.eta*1.2 else V_flow_max/2*dpMax/2/0.7*1.2 else 0 "Rated motor power";
          parameter Modelica.Units.SI.Efficiency etaMot_max(max = 1) = 0.7 "Maximum motor efficiency";
          final parameter Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters_yMot motorEfficiency_yMot_generic = Buildings.Fluid.Movers.BaseClasses.Characteristics.motorEfficiencyCurve(P_nominal = WMot_nominal, eta_max = etaMot_max) "Motor efficiency  vs. part load ratio";
          final parameter Boolean haveWMot_nominal = WMot_nominal > Modelica.Constants.eps "= true, if the rated motor power is provided";
          parameter Real speed_nominal(final min = 0, final unit = "1") = 1 "Nominal rotational speed for flow characteristic";
          parameter Real constantSpeed(final min = 0, final unit = "1") = 1 "Normalized speed set point, used if inputType = Buildings.Fluid.Types.InputType.Constant";
          parameter Real speeds[:](each final min = 0, each final unit = "1") = {1} "Vector of normalized speed set points, used if inputType = Buildings.Fluid.Types.InputType.Stages";
          final parameter Boolean havePressureCurve = sum(pressure.V_flow) > Modelica.Constants.eps and sum(pressure.dp) > Modelica.Constants.eps "= true, if default record values are being used";
          annotation(defaultComponentPrefixes = "parameter");
        end Generic;

        package Fans "Package of fan performance data"
          extends Modelica.Icons.Package;

          package Greenheck "Package with performance data for fans of Greenheck"
            extends Modelica.Icons.Package;

            record BIDW12 "Fan data for Greenheck 12 BIDW fan"
              extends Generic(final powerOrEfficiencyIsHydraulic = true, etaHydMet = Buildings.Fluid.Movers.BaseClasses.Types.HydraulicEfficiencyMethod.Power_VolumeFlowRate, power(V_flow = {0.941802252816019, 1.41392017800028, 1.88603810318454, 2.36058962592129, 2.82784035600056, 3.30239187873731, 3.77450980392156, 4.17118620497844}, P = {5309.384, 6323.536, 7188.548, 7673.253, 7889.506, 8090.845, 7785.108, 7740.366}), pressure(V_flow = {0.941802252816019, 1.41392017800028, 1.88603810318454, 2.36058962592129, 2.82784035600056, 3.30239187873731, 3.77450980392156, 4.17118620497844}, dp = {2684.68468468468, 2671.17117117117, 2536.03603603603, 2186.93693693693, 1698.19819819819, 1191.44144144144, 581.081081081081, 0}));
              annotation(defaultComponentPrefixes = "parameter");
            end BIDW12;
          end Greenheck;
        end Fans;
      end Data;

      package BaseClasses "Package with base classes for Buildings.Fluid.Movers"
        extends Modelica.Icons.BasesPackage;

        model FlowMachineInterface "Partial model with performance curves for fans or pumps"
          extends Modelica.Blocks.Icons.Block;
          constant Boolean homotopyInitialization = true "= true, use homotopy method" annotation(HideResult = true);
          parameter Buildings.Fluid.Movers.Data.Generic per "Record with performance data" annotation(choicesAllMatching = true);
          parameter Buildings.Fluid.Movers.BaseClasses.Types.PrescribedVariable preVar = Buildings.Fluid.Movers.BaseClasses.Types.PrescribedVariable.Speed "Type of prescribed variable";
          parameter Boolean computePowerUsingSimilarityLaws "= true, compute power exactly, using similarity laws. Otherwise approximate.";
          final parameter Modelica.Units.SI.VolumeFlowRate V_flow_nominal = per.pressure.V_flow[nOri] "Nominal volume flow rate, used for homotopy";
          parameter Modelica.Units.SI.Density rho_default "Fluid density at medium default state";
          final parameter Boolean haveVMax = (abs(per.pressure.dp[nOri]) < Modelica.Constants.eps) "Flag, true if user specified data that contain V_flow_max";
          final parameter Modelica.Units.SI.VolumeFlowRate V_flow_max = if per.V_flow_max > Modelica.Constants.eps then per.V_flow_max else V_flow_nominal "Maximum volume flow rate, used for smoothing";
          parameter Integer nOri(min = 1) "Number of data points for pressure curve" annotation(Evaluate = true);
          Modelica.Blocks.Interfaces.RealInput y_in(final unit = "1") if preSpe "Prescribed mover speed";
          Modelica.Blocks.Interfaces.RealOutput y_out(final unit = "1") "Mover speed (prescribed or computed)";
          Modelica.Blocks.Interfaces.RealInput m_flow(final quantity = "MassFlowRate", final unit = "kg/s") "Mass flow rate";
          Modelica.Blocks.Interfaces.RealInput rho(final quantity = "Density", final unit = "kg/m3", min = 0.0) "Medium density";
          Modelica.Blocks.Interfaces.RealOutput V_flow(quantity = "VolumeFlowRate", final unit = "m3/s") "Volume flow rate";
          Modelica.Blocks.Interfaces.RealInput dp_in(quantity = "PressureDifference", final unit = "Pa") if prePre "Prescribed pressure increase";
          Modelica.Blocks.Interfaces.RealOutput dp(quantity = "Pressure", final unit = "Pa") if not prePre "Pressure increase (computed or prescribed)";
          Modelica.Blocks.Interfaces.RealOutput WFlo(quantity = "Power", final unit = "W") "Flow work";
          Modelica.Blocks.Interfaces.RealOutput WHyd(quantity = "Power", final unit = "W") "Hydraulic work (shaft work, brake horsepower)";
          Modelica.Blocks.Interfaces.RealOutput PEle(quantity = "Power", final unit = "W") "Electrical power consumed";
          Modelica.Blocks.Interfaces.RealOutput eta(final quantity = "Efficiency", final unit = "1", start = 0.49) "Overall efficiency";
          Modelica.Blocks.Interfaces.RealOutput etaHyd(final quantity = "Efficiency", final unit = "1", start = 0.7) "Hydraulic efficiency";
          Modelica.Blocks.Interfaces.RealOutput etaMot(final quantity = "Efficiency", final unit = "1", start = 0.7) "Motor efficiency";
          Modelica.Blocks.Interfaces.RealOutput r_N(unit = "1") "Ratio N_actual/N_nominal";
          Real r_V(start = 1, unit = "1") "Ratio V_flow/V_flow_max";
        protected
          final parameter Boolean preSpe = preVar == Buildings.Fluid.Movers.BaseClasses.Types.PrescribedVariable.Speed "True if speed is a prescribed variable of this block";
          final parameter Boolean prePre = preVar == Buildings.Fluid.Movers.BaseClasses.Types.PrescribedVariable.PressureDifference or preVar == Buildings.Fluid.Movers.BaseClasses.Types.PrescribedVariable.FlowRate "True if pressure head is a prescribed variable of this block";
          final parameter Real etaDer[size(per.efficiency.V_flow, 1)] = if not per.etaHydMet == Buildings.Fluid.Movers.BaseClasses.Types.HydraulicEfficiencyMethod.Efficiency_VolumeFlowRate then zeros(size(per.efficiency.V_flow, 1)) elseif (size(per.efficiency.V_flow, 1) == 1) then {0} else Buildings.Utilities.Math.Functions.splineDerivatives(x = per.efficiency.V_flow, y = per.efficiency.eta, ensureMonotonicity = Buildings.Utilities.Math.Functions.isMonotonic(x = per.efficiency.eta, strict = false)) "Coefficients for cubic spline of total or hydraulic efficiency vs. volume flow rate";
          final parameter Real motDer[size(per.motorEfficiency.V_flow, 1)] = if not per.etaMotMet == Buildings.Fluid.Movers.BaseClasses.Types.MotorEfficiencyMethod.Efficiency_VolumeFlowRate then zeros(size(per.motorEfficiency.V_flow, 1)) elseif (size(per.motorEfficiency.V_flow, 1) == 1) then {0} else Buildings.Utilities.Math.Functions.splineDerivatives(x = per.motorEfficiency.V_flow, y = per.motorEfficiency.eta, ensureMonotonicity = Buildings.Utilities.Math.Functions.isMonotonic(x = per.motorEfficiency.eta, strict = false)) "Coefficients for cubic spline of motor efficiency vs. volume flow rate";
          final parameter Real motDer_yMot[size(per.motorEfficiency_yMot.y, 1)] = if not per.etaMotMet == Buildings.Fluid.Movers.BaseClasses.Types.MotorEfficiencyMethod.Efficiency_MotorPartLoadRatio then zeros(size(per.motorEfficiency_yMot.y, 1)) elseif (size(per.motorEfficiency_yMot.y, 1) == 1) then {0} else Buildings.Utilities.Math.Functions.splineDerivatives(x = per.motorEfficiency_yMot.y, y = per.motorEfficiency_yMot.eta, ensureMonotonicity = Buildings.Utilities.Math.Functions.isMonotonic(x = per.motorEfficiency_yMot.eta, strict = false)) "Coefficients for cubic spline of motor efficiency vs. motor PLR";
          final parameter Real motDer_yMot_generic[9] = if per.etaMotMet == Buildings.Fluid.Movers.BaseClasses.Types.MotorEfficiencyMethod.GenericCurve or (per.etaMotMet == Buildings.Fluid.Movers.BaseClasses.Types.MotorEfficiencyMethod.NotProvided and per.haveWMot_nominal) then Buildings.Utilities.Math.Functions.splineDerivatives(x = per.motorEfficiency_yMot_generic.y, y = per.motorEfficiency_yMot_generic.eta, ensureMonotonicity = true) else zeros(9) "Coefficients for cubic spline of motor efficiency vs. motor PLR with generic curves";
          final parameter Modelica.Units.SI.PressureDifference dpMax(displayUnit = "Pa") = per.dpMax "Maximum head";
          parameter Real delta = 0.05 "Small value used to for regularization and to approximate an internal flow resistance of the fan";
          parameter Real kRes(min = 0, unit = "kg/(s.m4)") = dpMax/V_flow_max*delta^2/10 "Coefficient for internal pressure drop of the fan or pump";
          parameter Integer curve = if (haveVMax and haveDPMax) or (nOri == 2) then 1 elseif haveVMax or haveDPMax then 2 else 3 "Flag, used to pick the right representation of the fan or pump's pressure curve";
          final parameter Buildings.Fluid.Movers.BaseClasses.Characteristics.flowParametersInternal pCur1(final n = nOri, final V_flow = if (haveVMax and haveDPMax) or (nOri == 2) then {per.pressure.V_flow[i] for i in 1:nOri} else zeros(nOri), final dp = if (haveVMax and haveDPMax) or (nOri == 2) then {(per.pressure.dp[i] + per.pressure.V_flow[i]*kRes) for i in 1:nOri} else zeros(nOri)) "Volume flow rate vs. total pressure rise with correction for fan or pump's resistance added";
          parameter Buildings.Fluid.Movers.BaseClasses.Characteristics.flowParametersInternal pCur2(final n = nOri + 1, V_flow = if (haveVMax and haveDPMax) or (nOri == 2) then zeros(nOri + 1) elseif haveVMax then cat(1, {0}, {per.pressure.V_flow[i] for i in 1:nOri})
           elseif haveDPMax then cat(1, {per.pressure.V_flow[i] for i in 1:nOri}, {V_flow_max}) else zeros(nOri + 1), dp = if (haveVMax and haveDPMax) or (nOri == 2) then zeros(nOri + 1) elseif haveVMax then cat(1, {dpMax}, {per.pressure.dp[i] + per.pressure.V_flow[i]*kRes for i in 1:nOri})
           elseif haveDPMax then cat(1, {per.pressure.dp[i] + per.pressure.V_flow[i]*kRes for i in 1:nOri}, {0}) else zeros(nOri + 1)) "Volume flow rate vs. total pressure rise with correction for fan or pump's resistance added";
          parameter Buildings.Fluid.Movers.BaseClasses.Characteristics.flowParametersInternal pCur3(final n = nOri + 2, V_flow = if (haveVMax and haveDPMax) or (nOri == 2) then zeros(nOri + 2) elseif haveVMax or haveDPMax then zeros(nOri + 2) else cat(1, {0}, {per.pressure.V_flow[i] for i in 1:nOri}, {V_flow_max}), dp = if (haveVMax and haveDPMax) or (nOri == 2) then zeros(nOri + 2) elseif haveVMax or haveDPMax then zeros(nOri + 2) else cat(1, {dpMax}, {per.pressure.dp[i] + per.pressure.V_flow[i]*kRes for i in 1:nOri}, {0})) "Volume flow rate vs. total pressure rise with correction for fan or pump's resistance added";
          parameter Real preDer1[nOri](each fixed = false) "Derivatives of flow rate vs. pressure at the support points";
          parameter Real preDer2[nOri + 1](each fixed = false) "Derivatives of flow rate vs. pressure at the support points";
          parameter Real preDer3[nOri + 2](each fixed = false) "Derivatives of flow rate vs. pressure at the support points";
          parameter Real powDer[size(per.power.V_flow, 1)] = if per.etaHydMet == Buildings.Fluid.Movers.BaseClasses.Types.HydraulicEfficiencyMethod.Power_VolumeFlowRate then Buildings.Utilities.Math.Functions.splineDerivatives(x = per.power.V_flow, y = per.power.P, ensureMonotonicity = Buildings.Utilities.Math.Functions.isMonotonic(x = per.power.P, strict = false)) else zeros(size(per.power.V_flow, 1)) "Coefficients for polynomial of power vs. flow rate";
          final parameter Buildings.Fluid.Movers.BaseClasses.Euler.powerWithDerivative powEu_internal = if (curve == 1) then Buildings.Fluid.Movers.BaseClasses.Euler.power(peak = per.peak, pressure = pCur1) elseif (curve == 2) then Buildings.Fluid.Movers.BaseClasses.Euler.power(peak = per.peak, pressure = pCur2) else Buildings.Fluid.Movers.BaseClasses.Euler.power(peak = per.peak, pressure = pCur3) "Intermediate parameter";
          final parameter Buildings.Fluid.Movers.BaseClasses.Characteristics.powerParameters powEu(V_flow = powEu_internal.V_flow, P = powEu_internal.P) "Power vs. volumetric flow rate computed from Euler number";
          final parameter Real powEuDer[:] = powEu_internal.d "Power derivative with respect to volumetric flow rate computed from Euler number";
          parameter Boolean haveMinimumDecrease = if nOri < 2 then false else Modelica.Math.BooleanVectors.allTrue({(per.pressure.dp[i + 1] - per.pressure.dp[i])/(per.pressure.V_flow[i + 1] - per.pressure.V_flow[i]) < -kRes for i in 1:nOri - 1}) "Flag used for reporting";
          parameter Boolean haveDPMax = (abs(per.pressure.V_flow[1]) < Modelica.Constants.eps) "Flag, true if user specified data that contain dpMax";
          Modelica.Blocks.Interfaces.RealOutput dp_internal "If dp is prescribed, use dp_in and solve for r_N, otherwise compute dp using r_N";
          Modelica.Units.SI.Efficiency eta_internal "Either eta or etaHyd";
          Modelica.Units.SI.Power P_internal "Either PEle or WHyd";
          parameter Real deltaP = 1E-4*V_flow_max*dpMax "Small value for regularisation of power";
          Real yMot(final min = 0, final start = 0.833) = if per.haveWMot_nominal then WHyd/per.WMot_nominal else 1 "Motor part load ratio";

          function getArrayAsString
            input Real array[:] "Array to be printed";
            input String varName "Variable name";
            input Integer minimumLength = 6 "Minimum width of result";
            input Integer significantDigits = 6 "Number of significant digits";
            output String str "String representation";
          algorithm
            str := "";
            for i in 1:size(array, 1) loop
              str := str + "  " + varName + "[" + String(i) + "]=" + String(array[i], minimumLength = minimumLength, significantDigits = significantDigits) + "\n";
            end for;
          end getArrayAsString;
        initial equation
          assert(nOri > 1, "Must have at least two data points for pressure.V_flow.");
          assert(Buildings.Utilities.Math.Functions.isMonotonic(x = per.pressure.V_flow, strict = true) and per.pressure.V_flow[1] > -Modelica.Constants.eps, "The fan pressure rise must be a strictly decreasing sequence with respect to the volume flow rate,
          with the first element for the fan pressure raise being non-zero.
        The following performance data have been entered:
          " + getArrayAsString(per.pressure.V_flow, "pressure.V_flow"));
          if not haveVMax then
            assert(nOri >= 2, "When the maximum flow is not specified,
              at least two points are needed for the power curve.");
            if nOri >= 2 then
              assert((per.pressure.V_flow[nOri] - per.pressure.V_flow[nOri - 1])/((per.pressure.dp[nOri] - per.pressure.dp[nOri - 1])) < 0, "The last two pressure points for the fan or pump's performance curve must be decreasing.
        Received
              " + getArrayAsString(per.pressure.dp, "dp"));
            end if;
          end if;
          if (not haveMinimumDecrease) then
            Modelica.Utilities.Streams.print("
        Warning:
        ========
        It is recommended that the volume flow rate versus pressure relation
        of the fan or pump satisfy the minimum decrease condition

                (per.pressure.dp[i+1]-per.pressure.dp[i])
        d[i] = ------------------------------------------------- < " + String(-kRes) + "
               (per.pressure.V_flow[i+1]-per.pressure.V_flow[i])

         is
            " + getArrayAsString({(per.pressure.dp[i + 1] - per.pressure.dp[i])/(per.pressure.V_flow[i + 1] - per.pressure.V_flow[i]) for i in 1:nOri - 1}, "d") + "
        Otherwise, a solution to the equations may not exist if the fan or pump's speed is reduced.
        In this situation, the solver will fail due to non-convergence and
        the simulation stops.");
          end if;
          if curve == 1 then
            preDer1 = Buildings.Utilities.Math.Functions.splineDerivatives(x = pCur1.V_flow, y = pCur1.dp);
            preDer2 = zeros(nOri + 1);
            preDer3 = zeros(nOri + 2);
          elseif curve == 2 then
            preDer1 = zeros(nOri);
            preDer2 = Buildings.Utilities.Math.Functions.splineDerivatives(x = pCur2.V_flow, y = pCur2.dp);
            preDer3 = zeros(nOri + 2);
          else
            preDer1 = zeros(nOri);
            preDer2 = zeros(nOri + 1);
            preDer3 = Buildings.Utilities.Math.Functions.splineDerivatives(x = pCur3.V_flow, y = pCur3.dp);
          end if;
          assert(not ((per.etaMotMet == Buildings.Fluid.Movers.BaseClasses.Types.MotorEfficiencyMethod.Efficiency_MotorPartLoadRatio or per.etaMotMet == Buildings.Fluid.Movers.BaseClasses.Types.MotorEfficiencyMethod.GenericCurve) and not per.haveWMot_nominal), "In " + getInstanceName() + ": etaMotMet is set to
                 .Efficiency_MotorPartLoadRatio or .GenericCurve which requires
                 the motor's rated power, but per.WMot_nominal is not assigned or
                 cannot be estimated because no power curve is provided.");
          assert(max(per.power.P) < 1E-6 or per.WMot_nominal > max(per.power.P)*0.99, "In " + getInstanceName() + ": The rated motor power provided in
                 per.WMot_nominal is smaller than the maximum power provided in per.power.
                 Use a larger value for per.WMot_nominal or leave it blank to allow the
                 model to assume a default value.");
          assert(homotopyInitialization, "In " + getInstanceName() + ": The constant homotopyInitialization has been modified from its default
                 value. This constant will be removed in future releases.", AssertionLevel.warning);
        equation
          connect(dp_internal, dp);
          connect(dp_internal, dp_in);
          connect(r_N, y_in);
          y_out = r_N;
          V_flow = m_flow/rho;
          r_V = V_flow/V_flow_max;
          if (computePowerUsingSimilarityLaws == false) and preVar <> Buildings.Fluid.Movers.BaseClasses.Types.PrescribedVariable.Speed then
            r_N = 1;
          else
            if (curve == 1) then
              if homotopyInitialization then
                V_flow*kRes + dp_internal = homotopy(actual = Buildings.Fluid.Movers.BaseClasses.Characteristics.pressure(V_flow = V_flow, r_N = r_N, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer1, per = pCur1), simplified = r_N*(Buildings.Fluid.Movers.BaseClasses.Characteristics.pressure(V_flow = V_flow_nominal, r_N = 1, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer1, per = pCur1) + (V_flow - V_flow_nominal)*(Buildings.Fluid.Movers.BaseClasses.Characteristics.pressure(V_flow = (1 + delta)*V_flow_nominal, r_N = 1, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer1, per = pCur1) - Buildings.Fluid.Movers.BaseClasses.Characteristics.pressure(V_flow = (1 - delta)*V_flow_nominal, r_N = 1, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer1, per = pCur1))/(2*delta*V_flow_nominal)));
              else
                V_flow*kRes + dp_internal = Buildings.Fluid.Movers.BaseClasses.Characteristics.pressure(V_flow = V_flow, r_N = r_N, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer1, per = pCur1);
              end if;
            elseif (curve == 2) then
              if homotopyInitialization then
                V_flow*kRes + dp_internal = homotopy(actual = Buildings.Fluid.Movers.BaseClasses.Characteristics.pressure(V_flow = V_flow, r_N = r_N, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer2, per = pCur2), simplified = r_N*(Buildings.Fluid.Movers.BaseClasses.Characteristics.pressure(V_flow = V_flow_nominal, r_N = 1, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer2, per = pCur2) + (V_flow - V_flow_nominal)*(Buildings.Fluid.Movers.BaseClasses.Characteristics.pressure(V_flow = (1 + delta)*V_flow_nominal, r_N = 1, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer2, per = pCur2) - Buildings.Fluid.Movers.BaseClasses.Characteristics.pressure(V_flow = (1 - delta)*V_flow_nominal, r_N = 1, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer2, per = pCur2))/(2*delta*V_flow_nominal)));
              else
                V_flow*kRes + dp_internal = Buildings.Fluid.Movers.BaseClasses.Characteristics.pressure(V_flow = V_flow, r_N = r_N, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer2, per = pCur2);
              end if;
            else
              if homotopyInitialization then
                V_flow*kRes + dp_internal = homotopy(actual = Buildings.Fluid.Movers.BaseClasses.Characteristics.pressure(V_flow = V_flow, r_N = r_N, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer3, per = pCur3), simplified = r_N*(Buildings.Fluid.Movers.BaseClasses.Characteristics.pressure(V_flow = V_flow_nominal, r_N = 1, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer3, per = pCur3) + (V_flow - V_flow_nominal)*(Buildings.Fluid.Movers.BaseClasses.Characteristics.pressure(V_flow = (1 + delta)*V_flow_nominal, r_N = 1, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer3, per = pCur3) - Buildings.Fluid.Movers.BaseClasses.Characteristics.pressure(V_flow = (1 - delta)*V_flow_nominal, r_N = 1, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer3, per = pCur3))/(2*delta*V_flow_nominal)));
              else
                V_flow*kRes + dp_internal = Buildings.Fluid.Movers.BaseClasses.Characteristics.pressure(V_flow = V_flow, r_N = r_N, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer3, per = pCur3);
              end if;
            end if;
          end if;
          WFlo = Buildings.Utilities.Math.Functions.smoothMax(x1 = dp_internal*V_flow, x2 = 0, deltaX = deltaP/2);
          if per.powerOrEfficiencyIsHydraulic then
            eta = etaHyd*etaMot;
          else
            etaHyd = Buildings.Utilities.Math.Functions.smoothMin(x1 = eta/etaMot, x2 = 1, deltaX = 1E-3);
          end if;
          if per.powerOrEfficiencyIsHydraulic then
            P_internal = WHyd;
            eta_internal = etaHyd;
            PEle = WFlo/Buildings.Utilities.Math.Functions.smoothMax(x1 = eta, x2 = 1E-2, deltaX = 1E-3);
          else
            P_internal = PEle;
            eta_internal = eta;
            WHyd = WFlo/Buildings.Utilities.Math.Functions.smoothMax(x1 = etaHyd, x2 = 1E-2, deltaX = 1E-3);
          end if;
          if per.etaHydMet == Buildings.Fluid.Movers.BaseClasses.Types.HydraulicEfficiencyMethod.Power_VolumeFlowRate then
            if homotopyInitialization then
              P_internal = homotopy(actual = Buildings.Fluid.Movers.BaseClasses.Characteristics.power(per = per.power, V_flow = V_flow, r_N = r_N, d = powDer, delta = delta), simplified = V_flow/V_flow_nominal*Buildings.Fluid.Movers.BaseClasses.Characteristics.power(per = per.power, V_flow = V_flow_nominal, r_N = 1, d = powDer, delta = delta));
            else
              P_internal = (rho/rho_default)*Buildings.Fluid.Movers.BaseClasses.Characteristics.power(per = per.power, V_flow = V_flow, r_N = r_N, d = powDer, delta = delta);
            end if;
            eta_internal = WFlo/Buildings.Utilities.Math.Functions.smoothMax(x1 = P_internal, x2 = deltaP, deltaX = deltaP/2);
          elseif per.etaHydMet == Buildings.Fluid.Movers.BaseClasses.Types.HydraulicEfficiencyMethod.EulerNumber then
            if homotopyInitialization then
              P_internal = homotopy(actual = Buildings.Fluid.Movers.BaseClasses.Characteristics.power(per = powEu, V_flow = V_flow, r_N = r_N, d = powEuDer, delta = delta), simplified = V_flow/V_flow_nominal*Buildings.Fluid.Movers.BaseClasses.Characteristics.power(per = powEu, V_flow = V_flow_nominal, r_N = 1, d = powEuDer, delta = delta));
            else
              P_internal = (rho/rho_default)*Buildings.Fluid.Movers.BaseClasses.Characteristics.power(per = powEu, V_flow = V_flow, r_N = r_N, d = powEuDer, delta = delta);
            end if;
            eta_internal = WFlo/Buildings.Utilities.Math.Functions.smoothMax(x1 = P_internal, x2 = deltaP, deltaX = deltaP/2);
          elseif per.etaHydMet == Buildings.Fluid.Movers.BaseClasses.Types.HydraulicEfficiencyMethod.Efficiency_VolumeFlowRate then
            if homotopyInitialization then
              eta_internal = homotopy(actual = Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiency(per = per.efficiency, V_flow = V_flow, d = etaDer, r_N = r_N, delta = delta), simplified = Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiency(per = per.efficiency, V_flow = V_flow_max, d = etaDer, r_N = r_N, delta = delta));
            else
              eta_internal = Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiency(per = per.efficiency, V_flow = V_flow, d = etaDer, r_N = r_N, delta = delta);
            end if;
            P_internal = WFlo/Buildings.Utilities.Math.Functions.smoothMax(x1 = eta_internal, x2 = 1E-2, deltaX = 1E-3);
          else
            if per.powerOrEfficiencyIsHydraulic then
              eta_internal = 0.7;
            else
              eta_internal = 0.49;
            end if;
            P_internal = WFlo/eta_internal;
          end if;
          if per.etaMotMet == Buildings.Fluid.Movers.BaseClasses.Types.MotorEfficiencyMethod.Efficiency_VolumeFlowRate then
            if homotopyInitialization then
              etaMot = homotopy(actual = Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiency(per = per.motorEfficiency, V_flow = V_flow, d = motDer, r_N = r_N, delta = delta), simplified = Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiency(per = per.motorEfficiency, V_flow = V_flow_max, d = motDer, r_N = r_N, delta = delta));
            else
              etaMot = Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiency(per = per.motorEfficiency, V_flow = V_flow, d = motDer, r_N = r_N, delta = delta);
            end if;
          elseif per.etaMotMet == Buildings.Fluid.Movers.BaseClasses.Types.MotorEfficiencyMethod.Efficiency_MotorPartLoadRatio then
            if homotopyInitialization then
              etaMot = homotopy(actual = Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiency_yMot(per = per.motorEfficiency_yMot, y = yMot, d = motDer_yMot), simplified = Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiency_yMot(per = per.motorEfficiency_yMot, y = 1, d = motDer_yMot));
            else
              etaMot = Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiency_yMot(per = per.motorEfficiency_yMot, y = yMot, d = motDer_yMot);
            end if;
          elseif per.etaMotMet == Buildings.Fluid.Movers.BaseClasses.Types.MotorEfficiencyMethod.GenericCurve then
            if homotopyInitialization then
              etaMot = homotopy(actual = Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiency_yMot(per = per.motorEfficiency_yMot_generic, y = yMot, d = motDer_yMot_generic), simplified = Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiency_yMot(per = per.motorEfficiency_yMot_generic, y = 1, d = motDer_yMot_generic));
            else
              etaMot = Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiency_yMot(per = per.motorEfficiency_yMot_generic, y = yMot, d = motDer_yMot_generic);
            end if;
          else
            etaMot = 0.7;
          end if;
        end FlowMachineInterface;

        model IdealSource "Base class for pressure and mass flow source with optional power input"
          extends Buildings.Fluid.Interfaces.PartialTwoPortTransport(show_T = false);
          parameter Boolean control_m_flow "if true, then the mass flow rate is equal to the value of m_flow_in" annotation(Evaluate = true);
          parameter Boolean control_dp = not control_m_flow "if true, then the head is equal to the value of dp_in" annotation(Evaluate = true);
          Modelica.Blocks.Interfaces.RealInput m_flow_in(unit = "kg/s") if control_m_flow "Prescribed mass flow rate";
          Modelica.Blocks.Interfaces.RealInput dp_in(unit = "Pa") if control_dp "Prescribed pressure difference port_a.p-port_b.p";
        protected
          Modelica.Blocks.Interfaces.RealInput m_flow_internal(unit = "kg/s") "Needed to connect to conditional connector";
          Modelica.Blocks.Interfaces.RealInput dp_internal(unit = "Pa") "Needed to connect to conditional connector";
        equation
          if control_m_flow then
            m_flow = m_flow_internal;
          else
            m_flow_internal = 0;
          end if;
          if control_dp then
            dp = dp_internal;
          else
            dp_internal = 0;
          end if;
          connect(dp_internal, dp_in);
          connect(m_flow_internal, m_flow_in);
          port_a.h_outflow = if allowFlowReversal then inStream(port_b.h_outflow) else Medium.h_default;
          port_b.h_outflow = inStream(port_a.h_outflow);
        end IdealSource;

        partial model PartialFlowMachine "Partial model to interface fan or pump models with the medium"
          extends Buildings.Fluid.Interfaces.LumpedVolumeDeclarations(final massDynamics = energyDynamics, final mSenFac = 1);
          extends Buildings.Fluid.Interfaces.PartialTwoPort(port_a(p(start = Medium.p_default), h_outflow(start = h_outflow_start)), port_b(p(start = p_start), h_outflow(start = h_outflow_start)));
          replaceable parameter Buildings.Fluid.Movers.Data.Generic per constrainedby Buildings.Fluid.Movers.Data.Generic;
          parameter Buildings.Fluid.Types.InputType inputType = Buildings.Fluid.Types.InputType.Continuous "Control input type";
          parameter Real constInput = 0 "Constant input set point";
          parameter Real stageInputs[:] "Vector of input set points corresponding to stages";
          parameter Boolean computePowerUsingSimilarityLaws "= true, compute power exactly, using similarity laws. Otherwise approximate.";
          parameter Boolean addPowerToMedium = true "Set to false to avoid any power (=heat and flow work) being added to medium (may give simpler equations)";
          parameter Boolean nominalValuesDefineDefaultPressureCurve = false "Set to true to avoid warning if m_flow_nominal and dp_nominal are used to construct the default pressure curve";
          parameter Modelica.Units.SI.Time tau = 1 "Time constant of fluid volume for nominal flow, used if energy or mass balance is dynamic";
          parameter Boolean use_riseTime = true "Set to true to continuously change motor speed";
          parameter Modelica.Units.SI.Time riseTime = 30 "Time needed to change motor speed between zero and full speed";
          parameter Modelica.Blocks.Types.Init init = Modelica.Blocks.Types.Init.InitialOutput "Type of initialization (no init/steady state/initial state/initial output)";
          Modelica.Blocks.Interfaces.IntegerInput stage if inputType == Buildings.Fluid.Types.InputType.Stages "Stage input signal for the pressure head";
          Modelica.Blocks.Interfaces.RealOutput y_actual(final unit = "1") "Actual normalised fan or pump speed that is used for computations";
          Modelica.Blocks.Interfaces.RealOutput P(quantity = "Power", final unit = "W") "Electrical power consumed";
          Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort(T(start = 293.15)) "Heat dissipation to environment";
          Modelica.Units.SI.VolumeFlowRate VMachine_flow(start = _VMachine_flow) = eff.V_flow "Volume flow rate";
          Modelica.Units.SI.PressureDifference dpMachine(displayUnit = "Pa") = -preSou.dp "Pressure difference";
          Real eta(unit = "1", final quantity = "Efficiency") = eff.eta "Global efficiency";
          Real etaHyd(unit = "1", final quantity = "Efficiency") = eff.etaHyd "Hydraulic efficiency";
          Real etaMot(unit = "1", final quantity = "Efficiency") = eff.etaMot "Motor efficiency";
          parameter Modelica.Units.SI.MassFlowRate m_flow_small(min = 0) = 1E-4*abs(_m_flow_nominal) "Small mass flow rate for regularization of zero flow";
          parameter Boolean show_T = false "= true, if actual temperature at port is computed" annotation(HideResult = true);
          Modelica.Units.SI.MassFlowRate m_flow(start = _m_flow_start) = port_a.m_flow "Mass flow rate from port_a to port_b (m_flow > 0 is design flow direction)";
          Modelica.Units.SI.PressureDifference dp(start = _dp_start, displayUnit = "Pa") = port_a.p - port_b.p "Pressure difference between port_a and port_b";
          Medium.ThermodynamicState sta_a = if allowFlowReversal then Medium.setState_phX(port_a.p, noEvent(actualStream(port_a.h_outflow)), noEvent(actualStream(port_a.Xi_outflow))) else Medium.setState_phX(port_a.p, noEvent(inStream(port_a.h_outflow)), noEvent(inStream(port_a.Xi_outflow))) if show_T "Medium properties in port_a";
          Medium.ThermodynamicState sta_b = if allowFlowReversal then Medium.setState_phX(port_b.p, noEvent(actualStream(port_b.h_outflow)), noEvent(actualStream(port_b.Xi_outflow))) else Medium.setState_phX(port_b.p, noEvent(port_b.h_outflow), noEvent(port_b.Xi_outflow)) if show_T "Medium properties in port_b";
        protected
          parameter Modelica.Units.SI.MassFlowRate _m_flow_nominal = max(eff.per.pressure.V_flow)*rho_default "Nominal mass flow rate";
          final parameter Modelica.Units.SI.MassFlowRate _m_flow_start = 0 "Start value for m_flow, used to avoid a warning if not set in m_flow, and to avoid m_flow.start in parameter window";
          final parameter Modelica.Units.SI.PressureDifference _dp_start(displayUnit = "Pa") = 0 "Start value for dp, used to avoid a warning if not set in dp, and to avoid dp.start in parameter window";
          final parameter Modelica.Units.SI.VolumeFlowRate _VMachine_flow = 0 "Start value for VMachine_flow, used to avoid a warning if not specified";
          parameter Buildings.Fluid.Movers.BaseClasses.Types.PrescribedVariable preVar "Type of prescribed variable";
          final parameter Boolean speedIsInput = (preVar == Buildings.Fluid.Movers.BaseClasses.Types.PrescribedVariable.Speed) "Parameter that is true if speed is the controlled variables";
          final parameter Integer nOri = size(per.pressure.V_flow, 1) "Number of data points for pressure curve" annotation(Evaluate = true);
          final parameter Boolean haveVMax = eff.haveVMax "Flag, true if user specified data that contain V_flow_max";
          final parameter Modelica.Units.SI.VolumeFlowRate V_flow_max = eff.V_flow_max;
          final parameter Modelica.Units.SI.Density rho_default = Medium.density_pTX(p = Medium.p_default, T = Medium.T_default, X = Medium.X_default) "Default medium density";
          final parameter Medium.ThermodynamicState sta_start = Medium.setState_pTX(T = T_start, p = p_start, X = X_start) "Medium state at start values";
          final parameter Modelica.Units.SI.SpecificEnthalpy h_outflow_start = Medium.specificEnthalpy(sta_start) "Start value for outflowing enthalpy";
          Modelica.Blocks.Sources.Constant stageValues[size(stageInputs, 1)](final k = stageInputs) if inputType == Buildings.Fluid.Types.InputType.Stages "Stage input values";
          Modelica.Blocks.Sources.Constant setConst(final k = constInput) if inputType == Buildings.Fluid.Types.InputType.Constant "Constant input set point";
          Extractor extractor(final nin = size(stageInputs, 1)) if inputType == Buildings.Fluid.Types.InputType.Stages "Stage input extractor";
          Modelica.Blocks.Routing.RealPassThrough inputSwitch "Dummy connection for easy connection of input options";
          Buildings.Fluid.Delays.DelayFirstOrder vol(redeclare final package Medium = Medium, final tau = tau, final energyDynamics = energyDynamics, final T_start = T_start, final X_start = X_start, final C_start = C_start, final m_flow_nominal = _m_flow_nominal, final m_flow_small = m_flow_small, final p_start = p_start, final prescribedHeatFlowRate = true, final allowFlowReversal = allowFlowReversal, nPorts = 2) "Fluid volume for dynamic model";
          Modelica.Blocks.Nonlinear.SlewRateLimiter motSpe(Rising = 1/riseTime, Falling = -1/riseTime, Td = 0.001*riseTime, initType = init, strict = true) if use_riseTime "Dynamics of motor speed";
          Buildings.Fluid.Movers.BaseClasses.IdealSource preSou(redeclare final package Medium = Medium, final m_flow_small = m_flow_small, final allowFlowReversal = allowFlowReversal, final control_m_flow = (preVar == Buildings.Fluid.Movers.BaseClasses.Types.PrescribedVariable.FlowRate)) "Pressure source";
          Buildings.Fluid.Movers.BaseClasses.PowerInterface heaDis(final motorCooledByFluid = per.motorCooledByFluid, final delta_V_flow = 1E-3*V_flow_max) if addPowerToMedium "Heat dissipation into medium";
          Modelica.Blocks.Math.Add PToMed(final k1 = 1, final k2 = 1) if addPowerToMedium "Heat and work input into medium";
          Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow prePow(final alpha = 0, port(T(start = 293.15))) if addPowerToMedium "Prescribed power (=heat and flow work) flow for dynamic model";
          Modelica.Blocks.Sources.RealExpression rho_inlet(y = Medium.density(Medium.setState_phX(port_a.p, inStream(port_a.h_outflow), inStream(port_a.Xi_outflow)))) "Density of the inflowing fluid";
          Buildings.Fluid.Sensors.MassFlowRate senMasFlo(redeclare final package Medium = Medium) "Mass flow rate sensor";
          Buildings.Fluid.Sensors.RelativePressure senRelPre(redeclare final package Medium = Medium) "Head of mover";
          Buildings.Fluid.Movers.BaseClasses.FlowMachineInterface eff(per(final powerOrEfficiencyIsHydraulic = per.powerOrEfficiencyIsHydraulic, final efficiency = per.efficiency, final motorEfficiency = per.motorEfficiency, final motorEfficiency_yMot = per.motorEfficiency_yMot, final motorCooledByFluid = per.motorCooledByFluid, final speed_nominal = 0, final constantSpeed = 0, final speeds = {0}, final power = per.power, final peak = per.peak), final nOri = nOri, final rho_default = rho_default, final computePowerUsingSimilarityLaws = computePowerUsingSimilarityLaws, r_V(start = _m_flow_nominal/rho_default), final preVar = preVar) "Flow machine";

          block Extractor "Extract scalar signal out of signal vector dependent on IntegerRealInput index"
            extends Modelica.Blocks.Interfaces.MISO;
            Modelica.Blocks.Interfaces.IntegerInput index "Integer input for control input";
          equation
            y = sum({if index == i then u[i] else 0 for i in 1:nin});
          end Extractor;
        initial algorithm
          assert(nominalValuesDefineDefaultPressureCurve or per.havePressureCurve or (preVar == Buildings.Fluid.Movers.BaseClasses.Types.PrescribedVariable.Speed), "*** Warning in " + getInstanceName() + ": Mover is flow or pressure controlled and uses default pressure curve.
        This leads to an approximate power consumption.
        Set nominalValuesDefineDefaultPressureCurve=true to suppress this warning.", AssertionLevel.warning);
          assert(nominalValuesDefineDefaultPressureCurve or (per.havePressureCurve or (preVar == Buildings.Fluid.Movers.BaseClasses.Types.PrescribedVariable.Speed)) or per.etaHydMet <> Buildings.Fluid.Movers.BaseClasses.Types.HydraulicEfficiencyMethod.Power_VolumeFlowRate, "*** Warning in " + getInstanceName() + ": Mover is flow or pressure controlled, uses default pressure curve and
        has per.etaHydMet=.Power_VolumeFlowRate.
        As this can cause wrong power consumption, the model overrides this setting by using per.etaHydMet=.NotProvided.
        Set nominalValuesDefineDefaultPressureCurve=true to suppress this warning.", AssertionLevel.warning);
          assert(per.havePressureCurve or not (per.etaHydMet == Buildings.Fluid.Movers.BaseClasses.Types.HydraulicEfficiencyMethod.Power_VolumeFlowRate or per.etaHydMet == Buildings.Fluid.Movers.BaseClasses.Types.HydraulicEfficiencyMethod.EulerNumber), "*** Warning in " + getInstanceName() + ": Mover has per.etaHydMet=.Power_VolumeFlowRate or per.etaHydMet=.EulerNumber.
        This requires per.pressure to be provided.
        Because it is not, the model overrides this setting by using per.etaHydMet=.NotProvided.
        Also consider using models under Movers.Preconfigured which autopopulate a pressure curve.", AssertionLevel.warning);
          assert(per.havePressureCurve or per.haveWMot_nominal or not (per.etaMotMet == Buildings.Fluid.Movers.BaseClasses.Types.MotorEfficiencyMethod.Efficiency_MotorPartLoadRatio or per.etaMotMet == Buildings.Fluid.Movers.BaseClasses.Types.MotorEfficiencyMethod.GenericCurve), "*** Warning in " + getInstanceName() + ": Mover has per.etaMotMet=.Efficiency_MotorPartLoadRatio or per.etaMotMet=.GenericCurve.
        This requires per.WMot_nominal or per.pressure to be provided. Because neither is provided,
        the model overrides this setting and by using per.etaMotMet=.NotProvided.
        Also consider using models under Movers.Preconfigured which autopopulate a pressure curve.", AssertionLevel.warning);
          assert(per.powerOrEfficiencyIsHydraulic or not (per.etaMotMet == Buildings.Fluid.Movers.BaseClasses.Types.MotorEfficiencyMethod.Efficiency_MotorPartLoadRatio or per.etaMotMet == Buildings.Fluid.Movers.BaseClasses.Types.MotorEfficiencyMethod.GenericCurve), "*** Warning in " + getInstanceName() + ": Mover has per.etaMotMet=.Efficiency_MotorPartLoadRatio or per.etaMotMet=.GenericCurve
        and provides information for total electric power instead of hydraulic power.
        This forms an algebraic loop. If simulation fails to converge,
        see the \"Motor efficiency\" section in the users guide for how to correct it.", AssertionLevel.warning);
        equation
          connect(prePow.port, vol.heatPort);
          connect(vol.heatPort, heatPort);
          connect(preSou.port_b, port_b);
          connect(stageValues.y, extractor.u);
          connect(extractor.y, inputSwitch.u);
          connect(setConst.y, inputSwitch.u);
          connect(extractor.index, stage);
          connect(PToMed.y, prePow.Q_flow);
          connect(PToMed.u1, heaDis.Q_flow);
          connect(senRelPre.port_b, preSou.port_a);
          connect(senRelPre.port_a, preSou.port_b);
          connect(heaDis.V_flow, eff.V_flow);
          connect(eff.PEle, heaDis.PEle);
          connect(eff.WFlo, heaDis.WFlo);
          connect(rho_inlet.y, eff.rho);
          connect(eff.m_flow, senMasFlo.m_flow);
          connect(eff.WFlo, PToMed.u2);
          connect(inputSwitch.y, motSpe.u);
          connect(senRelPre.p_rel, eff.dp_in);
          connect(eff.y_out, y_actual);
          connect(port_a, vol.ports[1]);
          connect(vol.ports[2], senMasFlo.port_a);
          connect(senMasFlo.port_b, preSou.port_a);
          connect(eff.WHyd, heaDis.WHyd);
          connect(eff.PEle, P);
        end PartialFlowMachine;

        model PowerInterface "Partial model to compute power draw and heat dissipation of fans and pumps"
          extends Modelica.Blocks.Icons.Block;
          constant Boolean homotopyInitialization = true "= true, use homotopy method" annotation(HideResult = true);
          parameter Boolean motorCooledByFluid "Flag, true if the motor is cooled by the fluid stream";
          parameter Modelica.Units.SI.VolumeFlowRate delta_V_flow "Factor used for setting heat input into medium to zero at very small flows";
          Modelica.Blocks.Interfaces.RealInput V_flow(final quantity = "VolumeFlowRate", final unit = "m3/s") "Volume flow rate";
          Modelica.Blocks.Interfaces.RealInput WFlo(final quantity = "Power", final unit = "W") "Flow work";
          Modelica.Blocks.Interfaces.RealInput WHyd(final quantity = "Power", final unit = "W") "Hydraulic work (converted to flow work and heat)";
          Modelica.Blocks.Interfaces.RealInput PEle(final quantity = "Power", final unit = "W") "Electrical power consumed";
          Modelica.Blocks.Interfaces.RealOutput Q_flow(quantity = "Power", final unit = "W") "Heat input from fan or pump to medium";
        protected
          Modelica.Units.SI.HeatFlowRate QThe_flow "Heat input from fan or pump to medium";
          Modelica.Units.SI.Efficiency etaHyd "Hydraulic efficiency";
        initial equation
          assert(homotopyInitialization, "In " + getInstanceName() + ": The constant homotopyInitialization has been modified from its default value. This constant will be removed in future releases.", AssertionLevel.warning);
        equation
          etaHyd = WFlo/Buildings.Utilities.Math.Functions.smoothMax(x1 = WHyd, x2 = 1E-5, deltaX = 1E-6);
          QThe_flow + WFlo = if motorCooledByFluid then PEle else WHyd;
          Q_flow = if homotopyInitialization then homotopy(actual = Buildings.Utilities.Math.Functions.regStep(y1 = QThe_flow, y2 = 0, x = noEvent(abs(V_flow)) - 2*delta_V_flow, x_small = delta_V_flow), simplified = 0) else Buildings.Utilities.Math.Functions.regStep(y1 = QThe_flow, y2 = 0, x = noEvent(abs(V_flow)) - 2*delta_V_flow, x_small = delta_V_flow);
        end PowerInterface;

        package Characteristics "Functions for fan or pump characteristics"
          function efficiency "Flow vs. efficiency characteristics for fan or pump"
            extends Modelica.Icons.Function;
            input Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters per "Efficiency performance data";
            input Modelica.Units.SI.VolumeFlowRate V_flow "Volumetric flow rate";
            input Real d[:] "Derivatives at support points for spline interpolation";
            input Real r_N(unit = "1") "Relative speed";
            input Real delta "Small value for switching implementation around zero speed";
            output Real eta(unit = "1", final quantity = "Efficiency") "Efficiency";
          protected
            Integer n = size(per.V_flow, 1) "Number of data points";
            Real rat "Ratio of V_flow/r_N";
            Integer i "Integer to select data interval";
          algorithm
            if n == 1 then
              eta := per.eta[1];
            else
              rat := V_flow/Buildings.Utilities.Math.Functions.smoothMax(x1 = r_N, x2 = 0.1, deltaX = delta);
              i := 1;
              for j in 1:n - 1 loop
                if rat > per.V_flow[j] then
                  i := j;
                else
                end if;
              end for;
              eta := Buildings.Utilities.Math.Functions.cubicHermiteLinearExtrapolation(x = rat, x1 = per.V_flow[i], x2 = per.V_flow[i + 1], y1 = per.eta[i], y2 = per.eta[i + 1], y1d = d[i], y2d = d[i + 1]);
            end if;
            annotation(smoothOrder = 1);
          end efficiency;

          function efficiency_yMot "Efficiency vs. motor PLR characteristics for fan or pump"
            extends Modelica.Icons.Function;
            input Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters_yMot per "Efficiency performance data";
            input Real y "Motor part load ratio, y = PEle/PEle_nominal";
            input Real d[:] "Derivatives at support points for spline interpolation";
            output Real eta(unit = "1", final quantity = "Efficiency") "Efficiency";
          protected
            Integer n = size(per.y, 1) "Number of data points";
            Integer i "Integer to select data interval";
          algorithm
            if n == 1 then
              eta := per.eta[1];
            else
              i := 1;
              for j in 1:n - 1 loop
                if y > per.y[j] then
                  i := j;
                else
                end if;
              end for;
              eta := Buildings.Utilities.Math.Functions.cubicHermiteLinearExtrapolation(x = y, x1 = per.y[i], x2 = per.y[i + 1], y1 = per.eta[i], y2 = per.eta[i + 1], y1d = d[i], y2d = d[i + 1]);
            end if;
            annotation(smoothOrder = 1);
          end efficiency_yMot;

          function motorEfficiencyCurve "This function generates the generic curve for motor efficiency based on rated motor power"
            extends Modelica.Icons.Function;
            input Modelica.Units.SI.Power P_nominal "Rated input power of the motor";
            input Modelica.Units.SI.Efficiency eta_max "Maximum motor efficiency";
            output Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters_yMot motorEfficiency_yMot(y = {0, 0.1, 0.2, 0.3, 0.4, 0.6, 0.8, 1, 1.2}, eta = zeros(nPoi)) "Motor efficiency vs. motor part load ratio";
          protected
            constant Modelica.Units.SI.Power u2[nSiz] = {700, 2500, 7500, 15000, 35000, 70000, 80000, 90000} "Rated motor input power";
            constant Integer nSiz = 8 "Number of motor sizes";
            constant Integer nPoi = 9 "Size";
            constant Real tab[nPoi, nSiz] = [1E-6, 1E-6, 1E-6, 1E-6, 1E-6, 1E-6, 1E-6, 1E-6; 0.319836509737628, 0.329886760993909, 0.458027464511497, 0.576112127457564, 0.643957112752703, 0.724359122802955, 1, 1; 0.551721742352314, 0.613279531297038, 0.752726767477942, 0.843179028784475, 0.903480536322164, 0.962525762452817, 1, 1; 0.716480140443274, 0.804199438688888, 0.886622050343885, 0.936873306625292, 0.956973809137855, 0.987124562906699, 1, 1; 0.816999745270129, 0.922527383461084, 0.950165574415858, 0.980316328184702, 1, 1, 1, 1; 0.906409929833499, 1, 1, 1, 1, 1, 1, 1; 0.956863812148299, 1, 1, 1, 1, 1, 1, 1; 1, 1, 1, 1, 1, 1, 1, 1; 1, 1, 1, 1, 1, 1, 1, 1] "Generic motor efficiency table (eta / eta_max)";
          algorithm
            if P_nominal > 1E-6 then
              for j in 1:nPoi loop
                motorEfficiency_yMot.eta[j] := eta_max*Buildings.Utilities.Math.Functions.smoothInterpolation(x = P_nominal, xSup = u2, ySup = tab[j, :], ensureMonotonicity = true);
              end for;
            else
              motorEfficiency_yMot.eta := 0.7*ones(nPoi);
            end if;
          end motorEfficiencyCurve;

          function power "Flow vs. electrical power characteristics for fan or pump"
            extends Modelica.Icons.Function;
            input Buildings.Fluid.Movers.BaseClasses.Characteristics.powerParameters per "Pressure performance data";
            input Modelica.Units.SI.VolumeFlowRate V_flow "Volumetric flow rate";
            input Real r_N(unit = "1") "Relative speed";
            input Real d[:] "Derivatives at support points for spline interpolation";
            input Real delta "Small value for switching implementation around zero speed";
            output Modelica.Units.SI.Power P "Power consumption";
          protected
            Integer n = size(per.V_flow, 1) "Dimension of data vector";
            Modelica.Units.SI.VolumeFlowRate rat "Ratio of V_flow/r_N";
            Integer i "Integer to select data interval";
          algorithm
            if n == 1 then
              P := r_N^3*per.P[1];
            else
              i := 1;
              rat := V_flow/Buildings.Utilities.Math.Functions.smoothMax(x1 = r_N, x2 = 0.1, deltaX = delta);
              for j in 1:n - 1 loop
                if rat > per.V_flow[j] then
                  i := j;
                else
                end if;
              end for;
              P := r_N^3*Buildings.Utilities.Math.Functions.cubicHermiteLinearExtrapolation(x = rat, x1 = per.V_flow[i], x2 = per.V_flow[i + 1], y1 = per.P[i], y2 = per.P[i + 1], y1d = d[i], y2d = d[i + 1]);
            end if;
            annotation(smoothOrder = 1);
          end power;

          function pressure "Pump or fan head away from the origin without correction for mover flow resistance"
            extends Modelica.Icons.Function;
            input Modelica.Units.SI.VolumeFlowRate V_flow "Volumetric flow rate";
            input Real r_N(unit = "1") "Relative revolution, r_N=N/N_nominal";
            input Real d[:] "Derivatives of flow rate vs. pressure at the support points";
            input Modelica.Units.SI.PressureDifference dpMax(displayUnit = "Pa") "Maximum pressure drop at nominal speed, for regularisation";
            input Modelica.Units.SI.VolumeFlowRate V_flow_max "Maximum flow rate at nominal speed, for regularisation";
            input Buildings.Fluid.Movers.BaseClasses.Characteristics.flowParametersInternal per "Pressure performance data";
            output Modelica.Units.SI.PressureDifference dp(displayUnit = "Pa") "Pressure raise";
          protected
            constant Real delta = 0.05 "Small number for r_N below which we don't care about the affinity laws";
            constant Real delta2 = delta/2 "= delta/2";
            Real r_R(unit = "1") "Relative revolution, bounded below by delta";
            Integer i "Integer to select data interval";
            Modelica.Units.SI.VolumeFlowRate rat "Ratio of V_flow/r_R";
          algorithm
            if r_N > delta then
              r_R := r_N;
            elseif r_N < 0 then
              r_R := delta2;
            else
              r_R := Modelica.Fluid.Utilities.cubicHermite(x = r_N, x1 = 0, x2 = delta, y1 = delta2, y2 = delta, y1d = 0, y2d = 1);
            end if;
            i := 1;
            rat := V_flow/r_R;
            for j in 1:size(d, 1) - 1 loop
              if rat > per.V_flow[j] then
                i := j;
              else
              end if;
            end for;
            if r_N >= 0 then
              dp := r_N^2*Buildings.Utilities.Math.Functions.cubicHermiteLinearExtrapolation(x = rat, x1 = per.V_flow[i], x2 = per.V_flow[i + 1], y1 = per.dp[i], y2 = per.dp[i + 1], y1d = d[i], y2d = d[i + 1]);
            else
              dp := -r_N^2*(dpMax - dpMax/V_flow_max*V_flow);
            end if;
            annotation(smoothOrder = 1);
          end pressure;

          record efficiencyParameters "Record for efficiency parameters vs. volumetric flow rate"
            extends Modelica.Icons.Record;
            parameter Modelica.Units.SI.VolumeFlowRate V_flow[:](each min = 0) "Volumetric flow rate at user-selected operating points";
            parameter Modelica.Units.SI.Efficiency eta[size(V_flow, 1)](each max = 1) "Fan or pump efficiency at these flow rates";
          end efficiencyParameters;

          record efficiencyParameters_yMot "Record for efficiency parameters vs. motor part load ratio"
            extends Modelica.Icons.Record;
            parameter Real y[:](each min = 0) "Part load ratio, y = PEle/PEle_nominal";
            parameter Modelica.Units.SI.Efficiency eta[size(y, 1)](each max = 1) "Fan or pump efficiency at these part load ratios";
          end efficiencyParameters_yMot;

          record flowParameters "Record for flow parameters"
            extends Modelica.Icons.Record;
            parameter Modelica.Units.SI.VolumeFlowRate V_flow[:](each min = 0) "Volume flow rate at user-selected operating points";
            parameter Modelica.Units.SI.PressureDifference dp[size(V_flow, 1)](each min = 0, each displayUnit = "Pa") "Fan or pump total pressure at these flow rates";
          end flowParameters;

          record flowParametersInternal "Record for flow parameters with prescribed size"
            extends Modelica.Icons.Record;
            parameter Integer n "Number of elements in each array" annotation(Evaluate = true);
            parameter Modelica.Units.SI.VolumeFlowRate V_flow[n](each min = 0) "Volume flow rate at user-selected operating points";
            parameter Modelica.Units.SI.PressureDifference dp[n](each min = 0, each displayUnit = "Pa") "Fan or pump total pressure at these flow rates";
          end flowParametersInternal;

          record powerParameters "Record for electrical power parameters"
            extends Modelica.Icons.Record;
            parameter Modelica.Units.SI.VolumeFlowRate V_flow[:](each min = 0) "Volume flow rate at user-selected operating points";
            parameter Modelica.Units.SI.Power P[size(V_flow, 1)](each min = 0) "Fan or pump electrical power at these flow rates";
          end powerParameters;
        end Characteristics;

        package Euler "Functions and data record templates for Euler number"
          function correlation "Correlation of static efficiency ratio vs log of Euler number ratio"
            extends Modelica.Icons.Function;
            input Real x "log10(Eu/Eu_peak)";
            output Real y "eta/eta_peak";
          protected
            Real a "Polynomial coefficient";
            Real b "Polynomial coefficient";
            Real c "Polynomial coefficient";
            Real d "Polynomial coefficient";
            Real y1 "eta/eta_peak";
          algorithm
            if x < -0.5 then
              a := 0.05687322707407;
              b := 0.493231336746;
              c := 1.433531254001;
              d := 1.407887300933;
            elseif x > 0.5 then
              a := -8.5494313567465000E-3;
              b := 1.2957001502368300E-1;
              c := -6.5997315029278200E-1;
              d := 1.13993003013131;
            else
              a := 0.37824577860088;
              b := -0.75988502317361;
              c := -0.060614519563716;
              d := 1.01426507307139;
            end if;
            y1 := (a*x^3 + b*x^2 + c*x + d)/1.01545;
            y := if y1 > 0.002 then y1 else Buildings.Utilities.Math.Functions.smoothMax(x1 = y1, x2 = 0.001, deltaX = 0.0005);
            annotation(smoothOrder = 1);
          end correlation;

          function efficiency "Computes efficiency with the Euler number correlation"
            extends Modelica.Icons.Function;
            input Buildings.Fluid.Movers.BaseClasses.Euler.peak peak "Operation point with maximum efficiency";
            input Modelica.Units.SI.PressureDifference dp "Pressure rise";
            input Modelica.Units.SI.VolumeFlowRate V_flow "Volumetric flow rate";
            input Real V_flow_dp_small(final unit = "m3.Pa/s", min = Modelica.Constants.eps) "Small number for regularisation";
            output Modelica.Units.SI.Efficiency eta "Efficiency";
          protected
            Real log_r_Eu "Log10 of Eu/Eu_peak";
          algorithm
            log_r_Eu := log10(Buildings.Utilities.Math.Functions.smoothMax(x1 = dp*peak.V_flow^2, x2 = V_flow_dp_small, deltaX = V_flow_dp_small/2)/Buildings.Utilities.Math.Functions.smoothMax(x1 = peak.dp*V_flow^2, x2 = V_flow_dp_small, deltaX = V_flow_dp_small/2));
            eta := peak.eta*Buildings.Fluid.Movers.BaseClasses.Euler.correlation(x = log_r_Eu);
            annotation(smoothOrder = 1);
          end efficiency;

          function getPeak "Find peak condition from power characteristics"
            extends Modelica.Icons.Function;
            input Buildings.Fluid.Movers.BaseClasses.Characteristics.flowParameters pressure "Pressure vs. flow rate";
            input BaseClasses.Characteristics.powerParameters power "Power vs. flow rate";
            output Buildings.Fluid.Movers.BaseClasses.Euler.peak peak "Operation point at maximum efficiency";
          protected
            parameter Integer nPre = size(pressure.V_flow, 1) "Size of the pressure array";
            parameter Integer nPow = size(power.V_flow, 1) "Size of the power array";
            parameter Integer n = max(nPre, nPow) "Bigger of the two arrays";
            parameter Modelica.Units.SI.VolumeFlowRate V_flow_hal = if max(pressure.V_flow) < 1E-6 then 0 else (pressure.V_flow[nPre] - (pressure.V_flow[nPre] - pressure.V_flow[nPre - 1])/(pressure.dp[nPre] - pressure.dp[nPre - 1])*pressure.dp[nPre])/2 "Half of max flow, max flow is where dp=0";
            parameter Modelica.Units.SI.PressureDifference dpHalFlo = if max(pressure.V_flow) < 1E-6 then 0 else Buildings.Utilities.Math.Functions.smoothInterpolation(x = V_flow_hal, xSup = pressure.V_flow, ySup = pressure.dp, ensureMonotonicity = true) "Pressure rise at half flow";
            Modelica.Units.SI.VolumeFlowRate V_flow[n] "Flow rate";
            Modelica.Units.SI.PressureDifference dp[n] "Pressure rise";
            Modelica.Units.SI.Power P[n] "Power";
            Real eta[n] "Efficiency series";
            Boolean etaLes "Efficiency series has less than four points";
            Boolean etaMon "Efficiency series is monotonic";
            Real A[n, 5] "Design matrix";
            Real b[5] "Parameter vector";
            Real r[3, 2] "Roots";
          algorithm
            if max(pressure.V_flow) < 1E-6 and max(pressure.dp) < 1E-6 then
              peak.V_flow := 0;
              peak.dp := 0;
              peak.eta := 0.7;
            elseif max(power.P) < 1E-6 then
              peak.V_flow := V_flow_hal;
              peak.dp := dpHalFlo;
              peak.eta := 0.7;
            else
              if nPre == nPow then
                V_flow := pressure.V_flow;
                dp := pressure.dp;
                P := power.P;
              else
                if nPre > nPow then
                  V_flow := pressure.V_flow;
                  dp := pressure.dp;
                  for i in 1:n loop
                    P[i] := Buildings.Utilities.Math.Functions.smoothInterpolation(x = V_flow[i], xSup = power.V_flow, ySup = power.P, ensureMonotonicity = false);
                  end for;
                else
                  V_flow := power.V_flow;
                  P := power.P;
                  for i in 1:n loop
                    dp[i] := Buildings.Utilities.Math.Functions.smoothInterpolation(x = V_flow[i], xSup = pressure.V_flow, ySup = pressure.dp, ensureMonotonicity = true);
                  end for;
                end if;
              end if;
              eta := V_flow.*dp./P;
              etaLes := n < 4;
              etaMon := Buildings.Utilities.Math.Functions.isMonotonic(x = eta, strict = false);
              if etaLes or etaMon then
                peak.eta := Buildings.Utilities.Math.Functions.smoothInterpolation(x = V_flow_hal, xSup = V_flow, ySup = eta, ensureMonotonicity = Buildings.Utilities.Math.Functions.isMonotonic(eta, strict = false));
                if peak.eta > max(eta) then
                  peak.V_flow := V_flow_hal;
                  peak.dp := dpHalFlo;
                else
                  peak.eta := max(eta);
                  for i in 1:n loop
                    if abs(eta[i] - peak.eta) < 1E-6 then
                      peak.V_flow := V_flow[i];
                      peak.dp := dp[i];
                    else
                    end if;
                  end for;
                end if;
              else
                A[:, 1] := ones(n);
                for i in 2:5 loop
                  A[:, i] := V_flow[:].^(i - 1);
                end for;
                b := Modelica.Math.Matrices.leastSquares(A, eta);
                r := Modelica.Math.Polynomials.roots({b[5]*4, b[4]*3, b[3]*2, b[2]});
                for i in 1:3 loop
                  if abs(r[i, 2]) <= 1E-6 and r[i, 1] > V_flow[1] and r[i, 1] < V_flow[n] then
                    peak.V_flow := r[i, 1];
                  else
                  end if;
                end for;
                peak.eta := Buildings.Utilities.Math.Functions.smoothInterpolation(x = peak.V_flow, xSup = V_flow, ySup = eta, ensureMonotonicity = false);
                peak.dp := Buildings.Utilities.Math.Functions.smoothInterpolation(x = peak.V_flow, xSup = V_flow, ySup = dp, ensureMonotonicity = false);
              end if;
            end if;
          end getPeak;

          function power "Computes power as well as its derivative with respect to flow rate using Euler number"
            extends Modelica.Icons.Function;
            input Buildings.Fluid.Movers.BaseClasses.Euler.peak peak "Peak operation point";
            input Buildings.Fluid.Movers.BaseClasses.Characteristics.flowParametersInternal pressure "Pressure curve with both max flow rate and max pressure";
            output Buildings.Fluid.Movers.BaseClasses.Euler.powerWithDerivative power(V_flow = zeros(11), P = zeros(11), d = zeros(11)) "Power and its derivative vs. flow rate";
          protected
            Modelica.Units.SI.VolumeFlowRate V_flow[11] "Volumetric flow rate";
            Modelica.Units.SI.PressureDifference dp[11] "Pressure rise";
            Real V_flow_dp_small(final unit = "m3.Pa/s", min = Modelica.Constants.eps) "Small value for regularisation";
          algorithm
            V_flow := {pressure.V_flow[end]*i*0.1 for i in 0:10};
            for i in 1:11 loop
              dp[i] := Buildings.Utilities.Math.Functions.smoothInterpolation(x = V_flow[i], xSup = pressure.V_flow, ySup = pressure.dp, ensureMonotonicity = false);
            end for;
            power.V_flow := V_flow;
            V_flow_dp_small := 1E-4*max(pressure.V_flow)*max(pressure.dp);
            for i in 2:10 loop
              power.P[i] := V_flow[i]*dp[i]/Buildings.Fluid.Movers.BaseClasses.Euler.efficiency(peak = peak, dp = dp[i], V_flow = V_flow[i], V_flow_dp_small = V_flow_dp_small/2);
            end for;
            power.d[2:10] := Buildings.Utilities.Math.Functions.splineDerivatives(x = V_flow[2:10], y = power.P[2:10], ensureMonotonicity = false);
            power.d[1] := power.d[2];
            power.d[11] := power.d[10];
            power.P[1] := power.P[2] - power.d[2]*V_flow[2];
            power.P[11] := power.P[10] + power.d[10]*(V_flow[11] - V_flow[10]);
            annotation(smoothOrder = 1);
          end power;

          record peak "Record for the operation condition at peak efficiency"
            extends Modelica.Icons.Record;
            parameter Modelica.Units.SI.VolumeFlowRate V_flow(min = 0) "Volume flow rate at peak efficiency";
            parameter Modelica.Units.SI.PressureDifference dp(min = 0, displayUnit = "Pa") "Pressure rise at peak efficiency";
            parameter Modelica.Units.SI.Efficiency eta = 0.7 "Peak efficiency";
          end peak;

          record powerWithDerivative "Record for electrical power and its derivative with respect to flow rate"
            extends Modelica.Icons.Record;
            parameter Modelica.Units.SI.VolumeFlowRate V_flow[11](each min = 0) "Volume flow rate at user-selected operating points";
            parameter Modelica.Units.SI.Power P[11](each min = 0) "Fan or pump electrical power at these flow rates";
            parameter Real d[11](each unit = "J/m3") "Derivative of power with respect to volume flow rate";
          end powerWithDerivative;
        end Euler;

        package Types "Package with type definitions"
          extends Modelica.Icons.TypesPackage;
          type PrescribedVariable = enumeration(Speed "Speed is prescribed", FlowRate "Flow rate is prescribed", PressureDifference "Pressure difference is prescribed") "Enumeration to choose what variable is prescribed";
          type HydraulicEfficiencyMethod = enumeration(NotProvided "Not provided, computed from other efficiency terms", Efficiency_VolumeFlowRate "Array of efficiency vs. volumetric flow rate", Power_VolumeFlowRate "Array of power vs. volumetric flow rate", EulerNumber "One peak point to be used for the Euler number") "Enumeration to choose the computation method for total efficiency and hydraulic efficiency";
          type MotorEfficiencyMethod = enumeration(NotProvided "Not provided, computed from other efficiency terms", Efficiency_VolumeFlowRate "Array of efficiency vs. volumetric flow rate", Efficiency_MotorPartLoadRatio "Rated input and array of efficiency vs. motor part load ratio yMot=WHyd/WMot_nominal", GenericCurve "Rated input and maximum efficiency to be used for generic curves") "Enumeration to choose the computation method for motor efficiency";
        end Types;
      end BaseClasses;
    end Movers;

    package Sensors "Package with sensor models"
      extends Modelica.Icons.SensorsPackage;

      model MassFlowRate "Ideal sensor for mass flow rate"
        extends Buildings.Fluid.Sensors.BaseClasses.PartialFlowSensor(final m_flow_nominal = 0, final m_flow_small = 0);
        extends Modelica.Icons.RoundSensor;
        Modelica.Blocks.Interfaces.RealOutput m_flow(quantity = "MassFlowRate", final unit = "kg/s") "Mass flow rate from port_a to port_b";
      equation
        m_flow = port_a.m_flow;
      end MassFlowRate;

      model RelativePressure "Ideal relative pressure sensor"
        extends Modelica.Icons.RectangularSensor;
        replaceable package Medium = Modelica.Media.Interfaces.PartialMedium "Medium in the sensor";
        Modelica.Fluid.Interfaces.FluidPort_a port_a(m_flow(min = 0), p(start = Medium.p_default), redeclare package Medium = Medium) "Fluid connector of stream a";
        Modelica.Fluid.Interfaces.FluidPort_b port_b(m_flow(min = 0), p(start = Medium.p_default), redeclare package Medium = Medium) "Fluid connector of stream b";
        Modelica.Blocks.Interfaces.RealOutput p_rel(final quantity = "PressureDifference", final unit = "Pa", displayUnit = "Pa") "Relative pressure of port_a minus port_b";
      equation
        port_a.m_flow = 0;
        port_b.m_flow = 0;
        port_a.h_outflow = 0;
        port_b.h_outflow = 0;
        port_a.Xi_outflow = zeros(Medium.nXi);
        port_b.Xi_outflow = zeros(Medium.nXi);
        port_a.C_outflow = zeros(Medium.nC);
        port_b.C_outflow = zeros(Medium.nC);
        p_rel = port_a.p - port_b.p;
      end RelativePressure;

      package BaseClasses "Package with base classes for Buildings.Fluid.Sensors"
        extends Modelica.Icons.BasesPackage;

        partial model PartialFlowSensor "Partial component to model sensors that measure flow properties"
          extends Buildings.Fluid.Interfaces.PartialTwoPort;
          parameter Modelica.Units.SI.MassFlowRate m_flow_nominal(min = 0) "Nominal mass flow rate, used for regularization near zero flow";
          parameter Modelica.Units.SI.MassFlowRate m_flow_small(min = 0) = 1E-4*m_flow_nominal "For bi-directional flow, temperature is regularized in the region |m_flow| < m_flow_small (m_flow_small > 0 required)";
        equation
          port_b.m_flow = -port_a.m_flow;
          port_a.p = port_b.p;
          port_a.h_outflow = if allowFlowReversal then inStream(port_b.h_outflow) else Medium.h_default;
          port_b.h_outflow = inStream(port_a.h_outflow);
          port_a.Xi_outflow = if allowFlowReversal then inStream(port_b.Xi_outflow) else Medium.X_default[1:Medium.nXi];
          port_b.Xi_outflow = inStream(port_a.Xi_outflow);
          port_a.C_outflow = if allowFlowReversal then inStream(port_b.C_outflow) else zeros(Medium.nC);
          port_b.C_outflow = inStream(port_a.C_outflow);
        end PartialFlowSensor;
      end BaseClasses;
    end Sensors;

    package Sources "Package with boundary condition models"
      extends Modelica.Icons.SourcesPackage;

      model Boundary_pT "Boundary with prescribed pressure, temperature, composition and trace substances"
        extends Buildings.Fluid.Sources.BaseClasses.PartialSource_Xi_C;
        parameter Boolean use_p_in = false "Get the pressure from the input connector" annotation(Evaluate = true);
        parameter Medium.AbsolutePressure p = Medium.p_default "Fixed value of pressure";
        parameter Boolean use_T_in = false "Get the temperature from the input connector" annotation(Evaluate = true);
        parameter Medium.Temperature T = Medium.T_default "Fixed value of temperature";
        Modelica.Blocks.Interfaces.RealInput p_in(final unit = "Pa") if use_p_in "Prescribed boundary pressure";
        Modelica.Blocks.Interfaces.RealInput T_in(final unit = "K", displayUnit = "degC") if use_T_in "Prescribed boundary temperature";
      protected
        constant Boolean checkWaterPressure = Medium.mediumName == "SimpleLiquidWater" "Evaluates to true if the pressure should be checked";
        constant Boolean checkAirPressure = Medium.mediumName == "Air" "Evaluates to true if the pressure should be checked";
        Modelica.Blocks.Interfaces.RealInput T_in_internal(final unit = "K", displayUnit = "degC") "Needed to connect to conditional connector";
        Modelica.Blocks.Interfaces.RealInput h_internal = Medium.specificEnthalpy(Medium.setState_pTX(p_in_internal, T_in_internal, X_in_internal)) "Internal connector for enthalpy";
      initial equation
        if not use_p_in then
          if checkWaterPressure then
            assert(p_in_internal > 1e4, "In " + getInstanceName() + ": The parameter value p=" + String(p_in_internal) + " is low for water. This is likely an error.");
          end if;
          if checkAirPressure then
            assert(p_in_internal > 5e4 and p_in_internal < 1.5e5, "In " + getInstanceName() + ": The parameter value p=" + String(p_in_internal) + " is not within a realistic range for air. This is likely an error.");
          end if;
        end if;
      equation
        if use_p_in then
          if checkWaterPressure then
            assert(p_in_internal > 1e4, "In " + getInstanceName() + ": The value of p_in=" + String(p_in_internal) + " is low for water. This is likely an error.");
          end if;
          if checkAirPressure then
            assert(p_in_internal > 5e4 and p_in_internal < 1.5e5, "In " + getInstanceName() + ": The value of p_in=" + String(p_in_internal) + " is not within a realistic range for air. This is likely an error.");
          end if;
        end if;
        connect(p_in, p_in_internal);
        if not use_p_in then
          p_in_internal = p;
        end if;
        for i in 1:nPorts loop
          ports[i].p = p_in_internal;
        end for;
        connect(T_in, T_in_internal);
        if not use_T_in then
          T_in_internal = T;
        end if;
        for i in 1:nPorts loop
          ports[i].h_outflow = h_internal;
        end for;
        connect(medium.h, h_internal);
      end Boundary_pT;

      package BaseClasses "Package with base classes for Buildings.Fluid.Sources"
        extends Modelica.Icons.BasesPackage;

        partial model PartialSource "Partial component source with one fluid connector"
          replaceable package Medium = Modelica.Media.Interfaces.PartialMedium "Medium in the component";
          parameter Integer nPorts = 0 "Number of ports";
          parameter Boolean verifyInputs = false "Set to true to stop the simulation with an error if the medium temperature is outside its allowable range" annotation(Evaluate = true);
          Modelica.Fluid.Interfaces.FluidPorts_b ports[nPorts](redeclare each package Medium = Medium, each m_flow(max = if flowDirection == Modelica.Fluid.Types.PortFlowDirection.Leaving then 0 else +Modelica.Constants.inf, min = if flowDirection == Modelica.Fluid.Types.PortFlowDirection.Entering then 0 else -Modelica.Constants.inf), each h_outflow(nominal = Medium.h_default), each Xi_outflow(each nominal = 0.01)) "Fluid ports";
        protected
          parameter Modelica.Fluid.Types.PortFlowDirection flowDirection = Modelica.Fluid.Types.PortFlowDirection.Bidirectional "Allowed flow direction" annotation(Evaluate = true);
          Modelica.Blocks.Interfaces.RealInput p_in_internal(final unit = "Pa") "Needed to connect to conditional connector";
          Medium.BaseProperties medium if verifyInputs "Medium in the source";
          Modelica.Blocks.Interfaces.RealInput Xi_in_internal[Medium.nXi](each final unit = "kg/kg") "Needed to connect to conditional connector";
          Modelica.Blocks.Interfaces.RealInput X_in_internal[Medium.nX](each final unit = "kg/kg") "Needed to connect to conditional connector";
          Modelica.Blocks.Interfaces.RealInput C_in_internal[Medium.nC](final quantity = Medium.extraPropertiesNames) "Needed to connect to conditional connector";
        initial equation
          for i in 1:nPorts loop
            assert(cardinality(ports[i]) <= 1, "
        Each ports[i] of boundary shall at most be connected to one component.
        If two or more connections are present, ideal mixing takes
        place in these connections, which is usually not the intention
        of the modeller. Increase nPorts to add an additional port.
            ");
          end for;
        equation
          connect(medium.p, p_in_internal);
        end PartialSource;

        partial model PartialSource_Xi_C "Partial component source with parameter definitions for Xi and C"
          extends Buildings.Fluid.Sources.BaseClasses.PartialSource;
          parameter Boolean use_X_in = false "Get the composition (all fractions) from the input connector" annotation(Evaluate = true);
          parameter Boolean use_Xi_in = false "Get the composition (independent fractions) from the input connector" annotation(Evaluate = true);
          parameter Boolean use_C_in = false "Get the trace substances from the input connector" annotation(Evaluate = true);
          parameter Medium.MassFraction X[Medium.nX](final quantity = Medium.substanceNames) = Medium.X_default "Fixed value of composition";
          parameter Medium.ExtraProperty C[Medium.nC](final quantity = Medium.extraPropertiesNames) = fill(0, Medium.nC) "Fixed values of trace substances";
          Modelica.Blocks.Interfaces.RealInput X_in[Medium.nX](each final unit = "kg/kg", final quantity = Medium.substanceNames) if use_X_in "Prescribed boundary composition";
          Modelica.Blocks.Interfaces.RealInput Xi_in[Medium.nXi](each final unit = "kg/kg", final quantity = Medium.substanceNames[1:Medium.nXi]) if use_Xi_in "Prescribed boundary composition";
          Modelica.Blocks.Interfaces.RealInput C_in[Medium.nC](final quantity = Medium.extraPropertiesNames) if use_C_in "Prescribed boundary trace substances";
        initial equation
          assert(not use_X_in or not use_Xi_in, "Cannot use both X and Xi inputs, choose either use_X_in or use_Xi_in.");
          if not use_X_in and not use_Xi_in then
            Modelica.Fluid.Utilities.checkBoundary(Medium.mediumName, Medium.substanceNames, Medium.singleState, true, X_in_internal, "Boundary_pT");
          end if;
        equation
          if use_X_in or use_Xi_in then
            Modelica.Fluid.Utilities.checkBoundary(Medium.mediumName, Medium.substanceNames, Medium.singleState, true, X_in_internal, "Boundary_pT");
          end if;
          connect(X_in, X_in_internal);
          connect(Xi_in, Xi_in_internal);
          if use_Xi_in then
            X_in_internal[1:Medium.nXi] = Xi_in_internal[1:Medium.nXi];
            if Medium.reducedX then
              X_in_internal[Medium.nX] = 1 - sum(Xi_in_internal);
            end if;
          elseif use_X_in then
            X_in_internal[1:Medium.nXi] = Xi_in_internal[1:Medium.nXi];
          else
            X_in_internal = X;
            Xi_in_internal = X[1:Medium.nXi];
          end if;
          connect(C_in, C_in_internal);
          if not use_C_in then
            C_in_internal = C;
          end if;
          for i in 1:nPorts loop
            ports[i].Xi_outflow = Xi_in_internal;
            ports[i].C_outflow = C_in_internal;
          end for;
        end PartialSource_Xi_C;
      end BaseClasses;
    end Sources;

    package Types "Package with type definitions"
      extends Modelica.Icons.TypesPackage;
      type InputType = enumeration(Constant "Use parameter to set stage", Stages "Use integer input to select stage", Continuous "Use continuous, real input") "Input options for movers";
    end Types;

    package Interfaces "Package with interfaces for fluid models"
      extends Modelica.Icons.InterfacesPackage;

      model ConservationEquation "Lumped volume with mass and energy balance"
        extends Buildings.Fluid.Interfaces.LumpedVolumeDeclarations;
        parameter Boolean initialize_p = not Medium.singleState "= true to set up initial equations for pressure" annotation(HideResult = true, Evaluate = true);
        constant Boolean simplify_mWat_flow = true "Set to true to cause port_a.m_flow + port_b.m_flow = 0 even if mWat_flow is non-zero. Used only if Medium.nX > 1";
        parameter Integer nPorts = 0 "Number of ports" annotation(Evaluate = true);
        parameter Boolean use_mWat_flow = false "Set to true to enable input connector for moisture mass flow rate" annotation(Evaluate = true);
        parameter Boolean use_C_flow = false "Set to true to enable input connector for trace substance" annotation(Evaluate = true);
        Modelica.Blocks.Interfaces.RealInput Q_flow(unit = "W") "Sensible plus latent heat flow rate transferred into the medium";
        Modelica.Blocks.Interfaces.RealInput mWat_flow(final quantity = "MassFlowRate", unit = "kg/s") if use_mWat_flow "Moisture mass flow rate added to the medium";
        Modelica.Blocks.Interfaces.RealInput C_flow[Medium.nC] if use_C_flow "Trace substance mass flow rate added to the medium";
        Modelica.Blocks.Interfaces.RealOutput hOut(unit = "J/kg", start = hStart, nominal = Medium.h_default) "Leaving specific enthalpy of the component";
        Modelica.Blocks.Interfaces.RealOutput XiOut[Medium.nXi](each unit = "1", each min = 0, each max = 1) "Leaving species concentration of the component";
        Modelica.Blocks.Interfaces.RealOutput COut[Medium.nC](each min = 0) "Leaving trace substances of the component";
        Modelica.Blocks.Interfaces.RealOutput UOut(unit = "J") "Internal energy of the component";
        Modelica.Blocks.Interfaces.RealOutput mXiOut[Medium.nXi](each min = 0, each unit = "kg") "Species mass of the component";
        Modelica.Blocks.Interfaces.RealOutput mOut(min = 0, unit = "kg") "Mass of the component";
        Modelica.Blocks.Interfaces.RealOutput mCOut[Medium.nC](each min = 0, each unit = "kg") "Trace substance mass of the component";
        Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b ports[nPorts](redeclare each final package Medium = Medium, each h_outflow(nominal = Medium.h_default), each Xi_outflow(each nominal = 0.01)) "Fluid inlets and outlets";
        Medium.BaseProperties medium(p(start = p_start), h(start = hStart), T(start = T_start), Xi(each stateSelect = if medium.preferredMediumStates then StateSelect.prefer else StateSelect.default, start = X_start[1:Medium.nXi]), X(start = X_start), d(start = rho_start)) "Medium properties";
        Modelica.Units.SI.Energy U(start = fluidVolume*rho_start*Medium.specificInternalEnergy(Medium.setState_pTX(T = T_start, p = p_start, X = X_start[1:Medium.nXi])) + (T_start - Medium.reference_T)*CSen, nominal = 1E5) "Internal energy of fluid";
        Modelica.Units.SI.Mass m(start = fluidVolume*rho_start, stateSelect = if massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then StateSelect.default else StateSelect.prefer) "Mass of fluid";
        Modelica.Units.SI.Mass mXi[Medium.nXi](each stateSelect = StateSelect.never, start = fluidVolume*rho_start*X_start[1:Medium.nXi]) "Masses of independent components in the fluid";
        Modelica.Units.SI.Mass mC[Medium.nC](start = fluidVolume*rho_start*C_start) "Masses of trace substances in the fluid";
        Medium.ExtraProperty C[Medium.nC](nominal = C_nominal) "Trace substance mixture content";
        Modelica.Units.SI.MassFlowRate mb_flow "Mass flows across boundaries";
        Modelica.Units.SI.MassFlowRate mbXi_flow[Medium.nXi] "Substance mass flows across boundaries";
        Medium.ExtraPropertyFlowRate mbC_flow[Medium.nC] "Trace substance mass flows across boundaries";
        Modelica.Units.SI.EnthalpyFlowRate Hb_flow "Enthalpy flow across boundaries or energy source/sink";
        parameter Modelica.Units.SI.Volume fluidVolume "Volume";
        final parameter Modelica.Units.SI.HeatCapacity CSen = (mSenFac - 1)*rho_default*cp_default*fluidVolume "Aditional heat capacity for implementing mFactor";
      protected
        Medium.EnthalpyFlowRate ports_H_flow[nPorts];
        Modelica.Units.SI.MassFlowRate ports_mXi_flow[nPorts, Medium.nXi];
        Medium.ExtraPropertyFlowRate ports_mC_flow[nPorts, Medium.nC];
        parameter Modelica.Units.SI.SpecificHeatCapacity cp_default = Medium.specificHeatCapacityCp(state = state_default) "Heat capacity, to compute additional dry mass";
        parameter Modelica.Units.SI.Density rho_start = Medium.density(Medium.setState_pTX(T = T_start, p = p_start, X = X_start[1:Medium.nXi])) "Density, used to compute fluid mass";
        final parameter Boolean computeCSen = abs(mSenFac - 1) > Modelica.Constants.eps annotation(Evaluate = true);
        final parameter Medium.ThermodynamicState state_default = Medium.setState_pTX(T = Medium.T_default, p = Medium.p_default, X = Medium.X_default[1:Medium.nXi]) "Medium state at default values";
        final parameter Modelica.Units.SI.Density rho_default = Medium.density(state = state_default) "Density, used to compute fluid mass";
        final parameter Real s[Medium.nXi] = {if Modelica.Utilities.Strings.isEqual(string1 = Medium.substanceNames[i], string2 = "Water", caseSensitive = false) then 1 else 0 for i in 1:Medium.nXi} "Vector with zero everywhere except where species is";
        parameter Modelica.Units.SI.SpecificEnthalpy hStart = Medium.specificEnthalpy_pTX(p_start, T_start, X_start) "Start value for specific enthalpy";
        constant Boolean _simplify_mWat_flow = simplify_mWat_flow and Medium.nX > 1 "If true, then port_a.m_flow + port_b.m_flow = 0 even if mWat_flow is non-zero, and equations are simplified";
        Modelica.Blocks.Interfaces.RealInput mWat_flow_internal(unit = "kg/s") "Needed to connect to conditional connector";
        Modelica.Blocks.Interfaces.RealInput C_flow_internal[Medium.nC] "Needed to connect to conditional connector";
      initial equation
        if use_mWat_flow then
          assert(Medium.nXi == 0 or abs(sum(s) - 1) < 1e-5, "In " + getInstanceName() + ":
               If Medium.nXi > 1, then substance 'water' must be present for one component of '" + Medium.mediumName + "'.
               Check medium model.");
        end if;
        if energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then
          assert(massDynamics == energyDynamics, "In " + getInstanceName() + ":
               If 'massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState', then it is
               required that 'energyDynamics==Modelica.Fluid.Types.Dynamics.SteadyState'.
               Otherwise, the system of equations may not be consistent.
               You need to select other parameter values.");
        end if;
        if energyDynamics == Modelica.Fluid.Types.Dynamics.FixedInitial then
          medium.T = T_start;
        else
          if energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyStateInitial then
            der(medium.T) = 0;
          end if;
        end if;
        if massDynamics == Modelica.Fluid.Types.Dynamics.FixedInitial then
          if initialize_p then
            medium.p = p_start;
          end if;
        else
          if massDynamics == Modelica.Fluid.Types.Dynamics.SteadyStateInitial then
            if initialize_p then
              der(medium.p) = 0;
            end if;
          end if;
        end if;
        if substanceDynamics == Modelica.Fluid.Types.Dynamics.FixedInitial then
          medium.Xi = X_start[1:Medium.nXi];
        else
          if substanceDynamics == Modelica.Fluid.Types.Dynamics.SteadyStateInitial then
            der(medium.Xi) = zeros(Medium.nXi);
          end if;
        end if;
        if traceDynamics == Modelica.Fluid.Types.Dynamics.FixedInitial then
          C = C_start[1:Medium.nC];
        else
          if traceDynamics == Modelica.Fluid.Types.Dynamics.SteadyStateInitial then
            der(C) = zeros(Medium.nC);
          end if;
        end if;
      equation
        connect(mWat_flow, mWat_flow_internal);
        if not use_mWat_flow then
          mWat_flow_internal = 0;
        end if;
        connect(C_flow, C_flow_internal);
        if not use_C_flow then
          C_flow_internal = zeros(Medium.nC);
        end if;
        if massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then
          m = fluidVolume*rho_start;
        else
          if _simplify_mWat_flow then
            m = fluidVolume*Medium.density(Medium.setState_phX(p = medium.p, h = hOut, X = Medium.X_default));
          else
            m = fluidVolume*medium.d;
          end if;
        end if;
        mXi = m*medium.Xi;
        if computeCSen then
          U = m*medium.u + CSen*(medium.T - Medium.reference_T);
        else
          U = m*medium.u;
        end if;
        mC = m*C;
        hOut = medium.h;
        XiOut = medium.Xi;
        COut = C;
        for i in 1:nPorts loop
          ports_H_flow[i] = semiLinear(ports[i].m_flow, inStream(ports[i].h_outflow), ports[i].h_outflow) "Enthalpy flow";
          for j in 1:Medium.nXi loop
            ports_mXi_flow[i, j] = semiLinear(ports[i].m_flow, inStream(ports[i].Xi_outflow[j]), ports[i].Xi_outflow[j]) "Component mass flow";
          end for;
          for j in 1:Medium.nC loop
            ports_mC_flow[i, j] = semiLinear(ports[i].m_flow, inStream(ports[i].C_outflow[j]), ports[i].C_outflow[j]) "Trace substance mass flow";
          end for;
        end for;
        for i in 1:Medium.nXi loop
          mbXi_flow[i] = sum(ports_mXi_flow[:, i]);
        end for;
        for i in 1:Medium.nC loop
          mbC_flow[i] = sum(ports_mC_flow[:, i]);
        end for;
        mb_flow = sum(ports.m_flow);
        Hb_flow = sum(ports_H_flow);
        if energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then
          0 = Hb_flow + Q_flow;
        else
          der(U) = Hb_flow + Q_flow;
        end if;
        if massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then
          0 = mb_flow + (if simplify_mWat_flow then 0 else mWat_flow_internal);
        else
          der(m) = mb_flow + (if simplify_mWat_flow then 0 else mWat_flow_internal);
        end if;
        if substanceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then
          zeros(Medium.nXi) = mbXi_flow + mWat_flow_internal*s;
        else
          der(medium.Xi) = (mbXi_flow + mWat_flow_internal*s)/m;
        end if;
        if traceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then
          zeros(Medium.nC) = mbC_flow + C_flow_internal;
        else
          der(mC) = mbC_flow + C_flow_internal;
        end if;
        for i in 1:nPorts loop
          ports[i].p = medium.p;
          ports[i].h_outflow = medium.h;
          ports[i].Xi_outflow = medium.Xi;
          ports[i].C_outflow = C;
        end for;
        UOut = U;
        mXiOut = mXi;
        mOut = m;
        mCOut = mC;
      end ConservationEquation;

      block LumpedVolumeDeclarations "Declarations for lumped volumes"
        replaceable package Medium = Modelica.Media.Interfaces.PartialMedium "Medium in the component";
        parameter Modelica.Fluid.Types.Dynamics energyDynamics = Modelica.Fluid.Types.Dynamics.DynamicFreeInitial "Type of energy balance: dynamic (3 initialization options) or steady state" annotation(Evaluate = true);
        parameter Modelica.Fluid.Types.Dynamics massDynamics = energyDynamics "Type of mass balance: dynamic (3 initialization options) or steady state, must be steady state if energyDynamics is steady state" annotation(Evaluate = true);
        final parameter Modelica.Fluid.Types.Dynamics substanceDynamics = energyDynamics "Type of independent mass fraction balance: dynamic (3 initialization options) or steady state" annotation(Evaluate = true);
        final parameter Modelica.Fluid.Types.Dynamics traceDynamics = energyDynamics "Type of trace substance balance: dynamic (3 initialization options) or steady state" annotation(Evaluate = true);
        parameter Medium.AbsolutePressure p_start = Medium.p_default "Start value of pressure";
        parameter Medium.Temperature T_start = Medium.T_default "Start value of temperature";
        parameter Medium.MassFraction X_start[Medium.nX](quantity = Medium.substanceNames) = Medium.X_default "Start value of mass fractions m_i/m";
        parameter Medium.ExtraProperty C_start[Medium.nC](quantity = Medium.extraPropertiesNames) = fill(0, Medium.nC) "Start value of trace substances";
        parameter Medium.ExtraProperty C_nominal[Medium.nC](quantity = Medium.extraPropertiesNames) = fill(1E-2, Medium.nC) "Nominal value of trace substances. (Set to typical order of magnitude.)";
        parameter Real mSenFac(min = 1) = 1 "Factor for scaling the sensible thermal mass of the volume";
      protected
        final parameter Boolean wrongEnergyMassBalanceConfiguration = not (energyDynamics <> Modelica.Fluid.Types.Dynamics.SteadyState or massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState) "True if configuration of energy and mass balance is wrong." annotation(Evaluate = true);
      initial equation
        if wrongEnergyMassBalanceConfiguration then
          assert(not wrongEnergyMassBalanceConfiguration, "In " + getInstanceName() + ": energyDynamics is selected as steady state, and therefore massDynamics must also be steady-state.");
        end if;
      end LumpedVolumeDeclarations;

      partial model PartialTwoPort "Partial component with two ports"
        replaceable package Medium = Modelica.Media.Interfaces.PartialMedium "Medium in the component";
        parameter Boolean allowFlowReversal = true "= false to simplify equations, assuming, but not enforcing, no flow reversal" annotation(Evaluate = true);
        Modelica.Fluid.Interfaces.FluidPort_a port_a(redeclare final package Medium = Medium, m_flow(min = if allowFlowReversal then -Modelica.Constants.inf else 0), h_outflow(start = Medium.h_default, nominal = Medium.h_default), Xi_outflow(each nominal = 0.01)) "Fluid connector a (positive design flow direction is from port_a to port_b)";
        Modelica.Fluid.Interfaces.FluidPort_b port_b(redeclare final package Medium = Medium, m_flow(max = if allowFlowReversal then +Modelica.Constants.inf else 0), h_outflow(start = Medium.h_default, nominal = Medium.h_default), Xi_outflow(each nominal = 0.01)) "Fluid connector b (positive design flow direction is from port_a to port_b)";
      end PartialTwoPort;

      partial model PartialTwoPortInterface "Partial model with two ports and declaration of quantities that are used by many models"
        extends Buildings.Fluid.Interfaces.PartialTwoPort(port_a(p(start = Medium.p_default)), port_b(p(start = Medium.p_default)));
        parameter Modelica.Units.SI.MassFlowRate m_flow_nominal "Nominal mass flow rate";
        parameter Modelica.Units.SI.MassFlowRate m_flow_small(min = 0) = 1E-4*abs(m_flow_nominal) "Small mass flow rate for regularization of zero flow";
        parameter Boolean show_T = false "= true, if actual temperature at port is computed" annotation(HideResult = true);
        Modelica.Units.SI.MassFlowRate m_flow(start = _m_flow_start) = port_a.m_flow "Mass flow rate from port_a to port_b (m_flow > 0 is design flow direction)";
        Modelica.Units.SI.PressureDifference dp(start = _dp_start, displayUnit = "Pa") = port_a.p - port_b.p "Pressure difference between port_a and port_b";
        Medium.ThermodynamicState sta_a = if allowFlowReversal then Medium.setState_phX(port_a.p, noEvent(actualStream(port_a.h_outflow)), noEvent(actualStream(port_a.Xi_outflow))) else Medium.setState_phX(port_a.p, noEvent(inStream(port_a.h_outflow)), noEvent(inStream(port_a.Xi_outflow))) if show_T "Medium properties in port_a";
        Medium.ThermodynamicState sta_b = if allowFlowReversal then Medium.setState_phX(port_b.p, noEvent(actualStream(port_b.h_outflow)), noEvent(actualStream(port_b.Xi_outflow))) else Medium.setState_phX(port_b.p, noEvent(port_b.h_outflow), noEvent(port_b.Xi_outflow)) if show_T "Medium properties in port_b";
      protected
        final parameter Modelica.Units.SI.MassFlowRate _m_flow_start = 0 "Start value for m_flow, used to avoid a warning if not set in m_flow, and to avoid m_flow.start in parameter window";
        final parameter Modelica.Units.SI.PressureDifference _dp_start(displayUnit = "Pa") = 0 "Start value for dp, used to avoid a warning if not set in dp, and to avoid dp.start in parameter window";
      end PartialTwoPortInterface;

      partial model PartialTwoPortTransport "Partial element transporting fluid between two ports without storage of mass or energy"
        extends Buildings.Fluid.Interfaces.PartialTwoPort;
        parameter Modelica.Units.SI.PressureDifference dp_start(displayUnit = "Pa") = 0 "Guess value of dp = port_a.p - port_b.p";
        parameter Medium.MassFlowRate m_flow_start = 0 "Guess value of m_flow = port_a.m_flow";
        parameter Medium.MassFlowRate m_flow_small "Small mass flow rate for regularization of zero flow";
        parameter Boolean show_T = true "= true, if temperatures at port_a and port_b are computed" annotation(HideResult = true);
        parameter Boolean show_V_flow = true "= true, if volume flow rate at inflowing port is computed" annotation(HideResult = true);
        Medium.MassFlowRate m_flow(min = if allowFlowReversal then -Modelica.Constants.inf else 0, start = m_flow_start) "Mass flow rate in design flow direction";
        Modelica.Units.SI.PressureDifference dp(start = dp_start, displayUnit = "Pa") "Pressure difference between port_a and port_b (= port_a.p - port_b.p)";
        Modelica.Units.SI.VolumeFlowRate V_flow = m_flow/Modelica.Fluid.Utilities.regStep(m_flow, Medium.density(Medium.setState_phX(p = port_a.p, h = inStream(port_a.h_outflow), X = inStream(port_a.Xi_outflow))), Medium.density(Medium.setState_phX(p = port_b.p, h = inStream(port_b.h_outflow), X = inStream(port_b.Xi_outflow))), m_flow_small) if show_V_flow "Volume flow rate at inflowing port (positive when flow from port_a to port_b)";
        Medium.Temperature port_a_T = Modelica.Fluid.Utilities.regStep(port_a.m_flow, Medium.temperature(Medium.setState_phX(p = port_a.p, h = inStream(port_a.h_outflow), X = inStream(port_a.Xi_outflow))), Medium.temperature(Medium.setState_phX(port_a.p, port_a.h_outflow, port_a.Xi_outflow)), m_flow_small) if show_T "Temperature close to port_a, if show_T = true";
        Medium.Temperature port_b_T = Modelica.Fluid.Utilities.regStep(port_b.m_flow, Medium.temperature(Medium.setState_phX(p = port_b.p, h = inStream(port_b.h_outflow), X = inStream(port_b.Xi_outflow))), Medium.temperature(Medium.setState_phX(port_b.p, port_b.h_outflow, port_b.Xi_outflow)), m_flow_small) if show_T "Temperature close to port_b, if show_T = true";
      equation
        dp = port_a.p - port_b.p;
        m_flow = port_a.m_flow;
        assert(m_flow > -m_flow_small or allowFlowReversal, "Reverting flow occurs even though allowFlowReversal is false");
        port_a.m_flow + port_b.m_flow = 0;
        port_a.Xi_outflow = if allowFlowReversal then inStream(port_b.Xi_outflow) else Medium.X_default[1:Medium.nXi];
        port_b.Xi_outflow = inStream(port_a.Xi_outflow);
        port_a.C_outflow = if allowFlowReversal then inStream(port_b.C_outflow) else zeros(Medium.nC);
        port_b.C_outflow = inStream(port_a.C_outflow);
      end PartialTwoPortTransport;

      model StaticTwoPortConservationEquation "Partial model for static energy and mass conservation equations"
        extends Buildings.Fluid.Interfaces.PartialTwoPortInterface;
        constant Boolean simplify_mWat_flow = true "Set to true to cause port_a.m_flow + port_b.m_flow = 0 even if mWat_flow is non-zero";
        constant Boolean prescribedHeatFlowRate = false "Set to true if the heat flow rate is not a function of a temperature difference to the fluid temperature";
        parameter Boolean use_mWat_flow = false "Set to true to enable input connector for moisture mass flow rate" annotation(Evaluate = true);
        parameter Boolean use_C_flow = false "Set to true to enable input connector for trace substance" annotation(Evaluate = true);
        Modelica.Blocks.Interfaces.RealInput Q_flow(unit = "W") "Sensible plus latent heat flow rate transferred into the medium";
        Modelica.Blocks.Interfaces.RealInput mWat_flow(final quantity = "MassFlowRate", unit = "kg/s") if use_mWat_flow "Moisture mass flow rate added to the medium";
        Modelica.Blocks.Interfaces.RealInput C_flow[Medium.nC] if use_C_flow "Trace substance mass flow rate added to the medium";
        Modelica.Blocks.Interfaces.RealOutput hOut(final unit = "J/kg") "Leaving specific enthalpy of the component";
        Modelica.Blocks.Interfaces.RealOutput XiOut[Medium.nXi](each unit = "1", each min = 0, each max = 1, nominal = 0.01*ones(Medium.nXi)) "Leaving species concentration of the component";
        Modelica.Blocks.Interfaces.RealOutput COut[Medium.nC](each min = 0) "Leaving trace substances of the component";
      protected
        final parameter Boolean use_m_flowInv = (prescribedHeatFlowRate or use_mWat_flow or use_C_flow) "Flag, true if m_flowInv is used in the model" annotation(Evaluate = true);
        final parameter Real s[Medium.nXi] = {if Modelica.Utilities.Strings.isEqual(string1 = Medium.substanceNames[i], string2 = "Water", caseSensitive = false) then 1 else 0 for i in 1:Medium.nXi} "Vector with zero everywhere except where species is";
        Real m_flowInv(unit = "s/kg") "Regularization of 1/m_flow of port_a";
        Modelica.Units.SI.MassFlowRate mXi_flow[Medium.nXi] "Mass flow rates of independent substances added to the medium";
        final parameter Real deltaReg = m_flow_small/1E3 "Smoothing region for inverseXRegularized";
        final parameter Real deltaInvReg = 1/deltaReg "Inverse value of delta for inverseXRegularized";
        final parameter Real aReg = -15*deltaInvReg "Polynomial coefficient for inverseXRegularized";
        final parameter Real bReg = 119*deltaInvReg^2 "Polynomial coefficient for inverseXRegularized";
        final parameter Real cReg = -361*deltaInvReg^3 "Polynomial coefficient for inverseXRegularized";
        final parameter Real dReg = 534*deltaInvReg^4 "Polynomial coefficient for inverseXRegularized";
        final parameter Real eReg = -380*deltaInvReg^5 "Polynomial coefficient for inverseXRegularized";
        final parameter Real fReg = 104*deltaInvReg^6 "Polynomial coefficient for inverseXRegularized";
        final parameter Medium.ThermodynamicState state_default = Medium.setState_pTX(T = Medium.T_default, p = Medium.p_default, X = Medium.X_default[1:Medium.nXi]) "Medium state at default values";
        final parameter Modelica.Units.SI.SpecificHeatCapacity cp_default = Medium.specificHeatCapacityCp(state = state_default) "Specific heat capacity, used to verify energy conservation";
        constant Modelica.Units.SI.TemperatureDifference dTMax(min = 1) = 200 "Maximum temperature difference across the StaticTwoPortConservationEquation";
        Modelica.Blocks.Interfaces.RealInput mWat_flow_internal(unit = "kg/s") "Needed to connect to conditional connector";
        Modelica.Blocks.Interfaces.RealInput C_flow_internal[Medium.nC] "Needed to connect to conditional connector";
      initial equation
        if use_mWat_flow then
          assert(Medium.nXi == 0 or abs(sum(s) - 1) < 1e-5, "If Medium.nXi > 1, then substance 'water' must be present for one component.'" + Medium.mediumName + "'.\n" + "Check medium model.");
        end if;
      equation
        connect(mWat_flow, mWat_flow_internal);
        if not use_mWat_flow then
          mWat_flow_internal = 0;
        end if;
        connect(C_flow, C_flow_internal);
        if not use_C_flow then
          C_flow_internal = zeros(Medium.nC);
        end if;
        mXi_flow = mWat_flow_internal*s;
        if use_m_flowInv then
          m_flowInv = Buildings.Utilities.Math.Functions.inverseXRegularized(x = port_a.m_flow, delta = deltaReg, deltaInv = deltaInvReg, a = aReg, b = bReg, c = cReg, d = dReg, e = eReg, f = fReg);
        else
          m_flowInv = 0;
        end if;
        if prescribedHeatFlowRate then
          assert(noEvent(abs(Q_flow) < dTMax*cp_default*max(m_flow_small/1E3, abs(m_flow))), "In " + getInstanceName() + ":
         The heat flow rate equals " + String(Q_flow) + " W and the mass flow rate equals " + String(m_flow) + " kg/s,
         which results in a temperature difference " + String(abs(Q_flow)/(cp_default*max(m_flow_small/1E3, abs(m_flow)))) + " K > dTMax=" + String(dTMax) + " K.
         This may indicate that energy is not conserved for small mass flow rates.
         The implementation may require prescribedHeatFlowRate = false.");
        end if;
        if allowFlowReversal then
          hOut = Buildings.Utilities.Math.Functions.regStep(y1 = port_b.h_outflow, y2 = port_a.h_outflow, x = port_a.m_flow, x_small = m_flow_small/1E3);
          XiOut = Buildings.Utilities.Math.Functions.regStep(y1 = port_b.Xi_outflow, y2 = port_a.Xi_outflow, x = port_a.m_flow, x_small = m_flow_small/1E3);
          COut = Buildings.Utilities.Math.Functions.regStep(y1 = port_b.C_outflow, y2 = port_a.C_outflow, x = port_a.m_flow, x_small = m_flow_small/1E3);
        else
          hOut = port_b.h_outflow;
          XiOut = port_b.Xi_outflow;
          COut = port_b.C_outflow;
        end if;
        port_a.m_flow + port_b.m_flow = if simplify_mWat_flow then 0 else -mWat_flow_internal;
        if use_m_flowInv then
          port_b.Xi_outflow = inStream(port_a.Xi_outflow) + mXi_flow*m_flowInv;
        else
          assert(use_mWat_flow == false, "In " + getInstanceName() + ": Wrong implementation for forward flow.");
          port_b.Xi_outflow = inStream(port_a.Xi_outflow);
        end if;
        if allowFlowReversal then
          if use_m_flowInv then
            port_a.Xi_outflow = inStream(port_b.Xi_outflow) - mXi_flow*m_flowInv;
          else
            assert(use_mWat_flow == false, "In " + getInstanceName() + ": Wrong implementation for reverse flow.");
            port_a.Xi_outflow = inStream(port_b.Xi_outflow);
          end if;
        else
          port_a.Xi_outflow = Medium.X_default[1:Medium.nXi];
        end if;
        if prescribedHeatFlowRate then
          port_b.h_outflow = inStream(port_a.h_outflow) + Q_flow*m_flowInv;
          if allowFlowReversal then
            port_a.h_outflow = inStream(port_b.h_outflow) - Q_flow*m_flowInv;
          else
            port_a.h_outflow = Medium.h_default;
          end if;
        else
          port_a.m_flow*(inStream(port_a.h_outflow) - port_b.h_outflow) = -Q_flow;
          if allowFlowReversal then
            port_a.m_flow*(inStream(port_b.h_outflow) - port_a.h_outflow) = +Q_flow;
          else
            port_a.h_outflow = Medium.h_default;
          end if;
        end if;
        if use_m_flowInv and use_C_flow then
          port_b.C_outflow = inStream(port_a.C_outflow) + C_flow_internal*m_flowInv;
        else
          assert(not use_C_flow, "In " + getInstanceName() + ": Wrong implementation of trace substance balance for forward flow.");
          port_b.C_outflow = inStream(port_a.C_outflow);
        end if;
        if allowFlowReversal then
          if use_C_flow then
            port_a.C_outflow = inStream(port_b.C_outflow) - C_flow_internal*m_flowInv;
          else
            port_a.C_outflow = inStream(port_b.C_outflow);
          end if;
        else
          port_a.C_outflow = zeros(Medium.nC);
        end if;
        port_a.p = port_b.p;
      end StaticTwoPortConservationEquation;
    end Interfaces;

    package BaseClasses "Package with base classes for Buildings.Fluid"
      extends Modelica.Icons.BasesPackage;

      partial model PartialResistance "Partial model for a hydraulic resistance"
        extends Buildings.Fluid.Interfaces.PartialTwoPortInterface(show_T = false, dp(nominal = if dp_nominal_pos > Modelica.Constants.eps then dp_nominal_pos else 1), m_flow(nominal = if m_flow_nominal_pos > Modelica.Constants.eps then m_flow_nominal_pos else 1), final m_flow_small = 1E-4*abs(m_flow_nominal));
        constant Boolean homotopyInitialization = true "= true, use homotopy method" annotation(HideResult = true);
        parameter Boolean from_dp = false "= true, use m_flow = f(dp) else dp = f(m_flow)" annotation(Evaluate = true);
        parameter Modelica.Units.SI.PressureDifference dp_nominal(displayUnit = "Pa") "Pressure drop at nominal mass flow rate";
        parameter Boolean linearized = false "= true, use linear relation between m_flow and dp for any flow rate" annotation(Evaluate = true);
        parameter Modelica.Units.SI.MassFlowRate m_flow_turbulent(min = 0) "Turbulent flow if |m_flow| >= m_flow_turbulent";
      protected
        parameter Medium.ThermodynamicState sta_default = Medium.setState_pTX(T = Medium.T_default, p = Medium.p_default, X = Medium.X_default);
        parameter Modelica.Units.SI.DynamicViscosity eta_default = Medium.dynamicViscosity(sta_default) "Dynamic viscosity, used to compute transition to turbulent flow regime";
        final parameter Modelica.Units.SI.MassFlowRate m_flow_nominal_pos = abs(m_flow_nominal) "Absolute value of nominal flow rate";
        final parameter Modelica.Units.SI.PressureDifference dp_nominal_pos(displayUnit = "Pa") = abs(dp_nominal) "Absolute value of nominal pressure difference";
      initial equation
        assert(homotopyInitialization, "In " + getInstanceName() + ": The constant homotopyInitialization has been modified from its default value. This constant will be removed in future releases.", AssertionLevel.warning);
      equation
        port_a.h_outflow = if allowFlowReversal then inStream(port_b.h_outflow) else Medium.h_default;
        port_b.h_outflow = inStream(port_a.h_outflow);
        port_a.m_flow + port_b.m_flow = 0;
        port_a.Xi_outflow = if allowFlowReversal then inStream(port_b.Xi_outflow) else Medium.X_default[1:Medium.nXi];
        port_b.Xi_outflow = inStream(port_a.Xi_outflow);
        port_a.C_outflow = if allowFlowReversal then inStream(port_b.C_outflow) else zeros(Medium.nC);
        port_b.C_outflow = inStream(port_a.C_outflow);
      end PartialResistance;

      package FlowModels "Flow models for pressure drop calculations"
        extends Modelica.Icons.BasesPackage;

        function basicFlowFunction_dp "Function that computes mass flow rate for given pressure drop"
          input Modelica.Units.SI.PressureDifference dp(displayUnit = "Pa") "Pressure difference between port_a and port_b (= port_a.p - port_b.p)";
          input Real k(min = 0, unit = "") "Flow coefficient, k=m_flow/sqrt(dp), with unit=(kg.m)^(1/2)";
          input Modelica.Units.SI.MassFlowRate m_flow_turbulent(min = 0) "Mass flow rate where transition to turbulent flow occurs";
          output Modelica.Units.SI.MassFlowRate m_flow "Mass flow rate in design flow direction";
        protected
          Modelica.Units.SI.PressureDifference dp_turbulent = (m_flow_turbulent/k)^2 "Pressure where flow changes to turbulent";
          Real dpNorm = dp/dp_turbulent "Normalised pressure difference";
          Real dpNormSq = dpNorm^2 "Square of normalised pressure difference";
        algorithm
          m_flow := smooth(2, if noEvent(abs(dp) > dp_turbulent) then sign(dp)*k*sqrt(abs(dp)) else (1.40625 + (0.15625*dpNormSq - 0.5625)*dpNormSq)*m_flow_turbulent*dpNorm);
          annotation(Inline = false, smoothOrder = 2, derivative(order = 1, zeroDerivative = k, zeroDerivative = m_flow_turbulent) = Buildings.Fluid.BaseClasses.FlowModels.basicFlowFunction_dp_der, inverse(dp = Buildings.Fluid.BaseClasses.FlowModels.basicFlowFunction_m_flow(m_flow = m_flow, k = k, m_flow_turbulent = m_flow_turbulent)));
        end basicFlowFunction_dp;

        function basicFlowFunction_dp_der "1st derivative of function that computes mass flow rate for given pressure drop"
          extends Modelica.Icons.Function;
          input Modelica.Units.SI.PressureDifference dp(displayUnit = "Pa") "Pressure difference between port_a and port_b (= port_a.p - port_b.p)";
          input Real k(min = 0, unit = "") "Flow coefficient, k=m_flow/sqrt(dp), with unit=(kg.m)^(1/2)";
          input Modelica.Units.SI.MassFlowRate m_flow_turbulent(min = 0) "Mass flow rate where transition to turbulent flow occurs";
          input Real dp_der "Derivative of pressure difference between port_a and port_b (= port_a.p - port_b.p)";
          output Real m_flow_der "Derivative of mass flow rate in design flow direction";
        protected
          Modelica.Units.SI.PressureDifference dp_turbulent = (m_flow_turbulent/k)^2 "Pressure where flow changes to turbulent";
          Real dpNormSq = (dp/dp_turbulent)^2 "Square of normalised pressure difference";
        algorithm
          m_flow_der := (if noEvent(abs(dp) > dp_turbulent) then 0.5*k/sqrt(abs(dp)) else (1.40625 + (0.78125*dpNormSq - 1.6875)*dpNormSq)*m_flow_turbulent/dp_turbulent)*dp_der;
          annotation(Inline = false, smoothOrder = 1, derivative(order = 2, zeroDerivative = k, zeroDerivative = m_flow_turbulent) = Buildings.Fluid.BaseClasses.FlowModels.basicFlowFunction_dp_der2);
        end basicFlowFunction_dp_der;

        function basicFlowFunction_dp_der2 "2nd derivative of function that computes mass flow rate for given pressure drop"
          extends Modelica.Icons.Function;
          input Modelica.Units.SI.PressureDifference dp(displayUnit = "Pa") "Pressure difference between port_a and port_b (= port_a.p - port_b.p)";
          input Real k(min = 0, unit = "") "Flow coefficient, k=m_flow/sqrt(dp), with unit=(kg.m)^(1/2)";
          input Modelica.Units.SI.MassFlowRate m_flow_turbulent(min = 0) "Mass flow rate where transition to turbulent flow occurs";
          input Real dp_der "1st derivative of pressure difference between port_a and port_b (= port_a.p - port_b.p)";
          input Real dp_der2 "2nd derivative of pressure difference between port_a and port_b (= port_a.p - port_b.p)";
          output Real m_flow_der2 "2nd derivative of mass flow rate in design flow direction";
        protected
          Modelica.Units.SI.PressureDifference dp_turbulent = (m_flow_turbulent/k)^2 "Pressure where flow changes to turbulent";
          Real dpNorm = dp/dp_turbulent "Normalised pressure difference";
          Real dpNormSq = dpNorm^2 "Square of normalised pressure difference";
        algorithm
          m_flow_der2 := if noEvent(abs(dp) > dp_turbulent) then 0.5*k/sqrt(abs(dp))*(-0.5/dp*dp_der^2 + dp_der2) else m_flow_turbulent/dp_turbulent*((1.40625 + (0.78125*dpNormSq - 1.6875)*dpNormSq)*dp_der2 + (-3.375 + 3.125*dpNormSq)*dpNorm/dp_turbulent*dp_der^2);
          annotation(smoothOrder = 0, Inline = false);
        end basicFlowFunction_dp_der2;

        function basicFlowFunction_m_flow "Function that computes pressure drop for given mass flow rate"
          input Modelica.Units.SI.MassFlowRate m_flow "Mass flow rate in design flow direction";
          input Real k(unit = "") "Flow coefficient, k=m_flow/sqrt(dp), with unit=(kg.m)^(1/2)";
          input Modelica.Units.SI.MassFlowRate m_flow_turbulent(min = 0) "Mass flow rate where transition to turbulent flow occurs";
          output Modelica.Units.SI.PressureDifference dp(displayUnit = "Pa") "Pressure difference between port_a and port_b (= port_a.p - port_b.p)";
        protected
          Modelica.Units.SI.PressureDifference dp_turbulent = (m_flow_turbulent/k)^2 "Pressure where flow changes to turbulent";
          Real m_flowNorm = m_flow/m_flow_turbulent "Normalised mass flow rate";
          Real m_flowNormSq = m_flowNorm^2 "Square of normalised mass flow rate";
        algorithm
          dp := smooth(2, if noEvent(abs(m_flow) > m_flow_turbulent) then sign(m_flow)*(m_flow/k)^2 else (0.375 + (0.75 - 0.125*m_flowNormSq)*m_flowNormSq)*dp_turbulent*m_flowNorm);
          annotation(Inline = false, smoothOrder = 2, derivative(order = 1, zeroDerivative = k, zeroDerivative = m_flow_turbulent) = Buildings.Fluid.BaseClasses.FlowModels.basicFlowFunction_m_flow_der, inverse(m_flow = Buildings.Fluid.BaseClasses.FlowModels.basicFlowFunction_dp(dp = dp, k = k, m_flow_turbulent = m_flow_turbulent)));
        end basicFlowFunction_m_flow;

        function basicFlowFunction_m_flow_der "1st derivative of function that computes pressure drop for given mass flow rate"
          extends Modelica.Icons.Function;
          input Modelica.Units.SI.MassFlowRate m_flow "Mass flow rate in design flow direction";
          input Real k(unit = "") "Flow coefficient, k=m_flow/sqrt(dp), with unit=(kg.m)^(1/2)";
          input Modelica.Units.SI.MassFlowRate m_flow_turbulent(min = 0) "Mass flow rate where transition to turbulent flow occurs";
          input Real m_flow_der "Derivative of mass flow rate in design flow direction";
          output Real dp_der "Derivative of pressure difference between port_a and port_b (= port_a.p - port_b.p)";
        protected
          Modelica.Units.SI.PressureDifference dp_turbulent = (m_flow_turbulent/k)^2 "Pressure where flow changes to turbulent";
          Real m_flowNormSq = (m_flow/m_flow_turbulent)^2 "Square of normalised mass flow rate";
        algorithm
          dp_der := (if noEvent(abs(m_flow) > m_flow_turbulent) then sign(m_flow)*2*m_flow/k^2 else (0.375 + (2.25 - 0.625*m_flowNormSq)*m_flowNormSq)*dp_turbulent/m_flow_turbulent)*m_flow_der;
          annotation(Inline = false, smoothOrder = 1, derivative(order = 2, zeroDerivative = k, zeroDerivative = m_flow_turbulent) = Buildings.Fluid.BaseClasses.FlowModels.basicFlowFunction_m_flow_der2);
        end basicFlowFunction_m_flow_der;

        function basicFlowFunction_m_flow_der2 "2nd derivative of function that computes pressure drop for given mass flow rate"
          extends Modelica.Icons.Function;
          input Modelica.Units.SI.MassFlowRate m_flow "Mass flow rate in design flow direction";
          input Real k(unit = "") "Flow coefficient, k=m_flow/sqrt(dp), with unit=(kg.m)^(1/2)";
          input Modelica.Units.SI.MassFlowRate m_flow_turbulent(min = 0) "Mass flow rate where transition to turbulent flow occurs";
          input Real m_flow_der "1st derivative of mass flow rate in design flow direction";
          input Real m_flow_der2 "2nd derivative of mass flow rate in design flow direction";
          output Real dp_der2 "2nd derivative of pressure difference between port_a and port_b (= port_a.p - port_b.p)";
        protected
          Modelica.Units.SI.PressureDifference dp_turbulent = (m_flow_turbulent/k)^2 "Pressure where flow changes to turbulent";
          Real m_flowNorm = m_flow/m_flow_turbulent "Normalised mass flow rate";
          Real m_flowNormSq = m_flowNorm^2 "Square of normalised mass flow rate";
        algorithm
          dp_der2 := if noEvent(abs(m_flow) > m_flow_turbulent) then sign(m_flow)*2/k^2*(m_flow_der^2 + m_flow*m_flow_der2) else dp_turbulent/m_flow_turbulent*((0.375 + (2.25 - 0.625*m_flowNormSq)*m_flowNormSq)*m_flow_der2 + (4.5 - 2.5*m_flowNormSq)*m_flowNorm/m_flow_turbulent*m_flow_der^2);
          annotation(smoothOrder = 0, Inline = false);
        end basicFlowFunction_m_flow_der2;
      end FlowModels;
    end BaseClasses;
  end Fluid;

  package HeatTransfer "Package with heat transfer models"
    extends Modelica.Icons.Package;

    package Sources "Thermal sources"
      extends Modelica.Icons.SourcesPackage;

      model PrescribedTemperature "Variable temperature boundary condition in Kelvin"
        Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b port;
        Modelica.Blocks.Interfaces.RealInput T;
      equation
        port.T = T;
      end PrescribedTemperature;
    end Sources;
  end HeatTransfer;

  package Media "Package with medium models"
    extends Modelica.Icons.Package;

    package Air "Package with moist air model that decouples pressure and temperature"
      extends Modelica.Media.Interfaces.PartialCondensingGases(mediumName = "Air", final substanceNames = {"water", "air"}, final reducedX = true, final singleState = false, reference_X = {0.01, 0.99}, final fluidConstants = {Modelica.Media.IdealGases.Common.FluidData.H2O, Modelica.Media.IdealGases.Common.FluidData.N2}, reference_T = 273.15, reference_p = 101325, AbsolutePressure(start = p_default), Temperature(start = T_default));
      extends Modelica.Icons.Package;
      constant Integer Water = 1 "Index of water (in substanceNames, massFractions X, etc.)";
      constant Integer Air = 2 "Index of air (in substanceNames, massFractions X, etc.)";
      constant GasProperties dryair(R = Modelica.Media.IdealGases.Common.SingleGasesData.Air.R_s, MM = Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM, cp = Buildings.Utilities.Psychrometrics.Constants.cpAir, cv = Buildings.Utilities.Psychrometrics.Constants.cpAir - Modelica.Media.IdealGases.Common.SingleGasesData.Air.R_s) "Dry air properties";
      constant GasProperties steam(R = Modelica.Media.IdealGases.Common.SingleGasesData.H2O.R_s, MM = Modelica.Media.IdealGases.Common.SingleGasesData.H2O.MM, cp = Buildings.Utilities.Psychrometrics.Constants.cpSte, cv = Buildings.Utilities.Psychrometrics.Constants.cpSte - Modelica.Media.IdealGases.Common.SingleGasesData.H2O.R_s) "Steam properties";
      constant Modelica.Units.SI.MolarMass MMX[2] = {steam.MM, dryair.MM} "Molar masses of components";
      constant AbsolutePressure pStp = reference_p "Pressure for which fluid density is defined";
      constant Density dStp = 1.2 "Fluid density at pressure pStp";

      redeclare record extends ThermodynamicState "ThermodynamicState record for moist air" end ThermodynamicState;

      redeclare replaceable model BaseProperties "Base properties (p, d, T, h, u, R, MM and X and Xi) of a medium"
        parameter Boolean preferredMediumStates = false "= true if StateSelect.prefer shall be used for the independent property variables of the medium" annotation(Evaluate = true);
        final parameter Boolean standardOrderComponents = true "If true, and reducedX = true, the last element of X will be computed from the other ones";
        InputAbsolutePressure p "Absolute pressure of medium";
        InputMassFraction Xi[1](start = reference_X[1:1], nominal = {0.01}, each stateSelect = if preferredMediumStates then StateSelect.prefer else StateSelect.default) "Structurally independent mass fractions";
        InputSpecificEnthalpy h "Specific enthalpy of medium";
        Modelica.Media.Interfaces.Types.Density d "Density of medium";
        Modelica.Media.Interfaces.Types.Temperature T(stateSelect = if preferredMediumStates then StateSelect.prefer else StateSelect.default) "Temperature of medium";
        Modelica.Media.Interfaces.Types.MassFraction X[2](start = reference_X, nominal = {0.01, 1}) "Mass fractions (= (component mass)/total mass  m_i/m)";
        Modelica.Media.Interfaces.Types.SpecificInternalEnergy u "Specific internal energy of medium";
        Modelica.Media.Interfaces.Types.SpecificHeatCapacity R_s "Gas constant (of mixture if applicable)";
        Modelica.Media.Interfaces.Types.MolarMass MM "Molar mass (of mixture or single fluid)";
        ThermodynamicState state(X(nominal = {0.01, 1})) "Thermodynamic state record for optional functions";
        Modelica.Units.NonSI.Temperature_degC T_degC = Modelica.Units.Conversions.to_degC(T) "Temperature of medium in [degC]";
        Modelica.Units.NonSI.Pressure_bar p_bar = Modelica.Units.Conversions.to_bar(p) "Absolute pressure of medium in [bar]";
        connector InputAbsolutePressure = input Modelica.Units.SI.AbsolutePressure "Pressure as input signal connector";
        connector InputSpecificEnthalpy = input Modelica.Units.SI.SpecificEnthalpy "Specific enthalpy as input signal connector";
        connector InputMassFraction = input Modelica.Units.SI.MassFraction "Mass fraction as input signal connector";
      protected
        Modelica.Units.SI.TemperatureDifference dT(start = T_default - reference_T) "Temperature difference used to compute enthalpy";
      equation
        MM = 1/(X[1]/steam.MM + (X[2])/dryair.MM);
        dT = T - reference_T;
        h = dT*dryair.cp*X[2] + (dT*steam.cp + h_fg)*X[1];
        R_s = dryair.R*X[2] + steam.R*X[1];
        u = h - pStp/dStp;
        d/dStp = p/pStp;
        state.p = p;
        state.T = T;
        state.X = X;
        X[1] = Xi[1];
        X[2] = 1 - X[1];
        assert(noEvent(X[1] >= -1.e-5) and noEvent(X[1] <= 1 + 1.e-5), "Mass fraction X[1] = " + String(X[1]) + " of substance water" + "\nof medium \"Buildings.Media.Air\" is not in the range 0..1");
        assert(noEvent(T >= 200.0), "In " + getInstanceName() + ": Temperature T exceeded its minimum allowed value of -73.15 degC (200 Kelvin)
      as required from medium model \"Buildings.Media.Air\".");
        assert(noEvent(T <= 423.15), "In " + getInstanceName() + ": Temperature T exceeded its maximum allowed value of 150 degC (423.15 Kelvin)
      as required from medium model \"Buildings.Media.Air\".");
        assert(noEvent(p >= 0.0), "Pressure (= " + String(p) + " Pa) of medium \"Buildings.Media.Air\" is negative\n(Temperature = " + String(T) + " K)");
      end BaseProperties;

      redeclare function density "Gas density"
        extends Modelica.Icons.Function;
        input ThermodynamicState state;
        output Density d "Density";
      algorithm
        d := state.p*dStp/pStp;
        annotation(smoothOrder = 5, Inline = true);
      end density;

      redeclare function extends dynamicViscosity "Return the dynamic viscosity of dry air"
      algorithm
        eta := 4.89493640395e-08*state.T + 3.88335940547e-06;
        annotation(smoothOrder = 99, Inline = true);
      end dynamicViscosity;

      redeclare function enthalpyOfCondensingGas "Enthalpy of steam per unit mass of steam"
        extends Modelica.Icons.Function;
        input Temperature T "temperature";
        output SpecificEnthalpy h "steam enthalpy";
      algorithm
        h := (T - reference_T)*steam.cp + h_fg;
        annotation(smoothOrder = 5, Inline = true, derivative = der_enthalpyOfCondensingGas);
      end enthalpyOfCondensingGas;

      redeclare replaceable function extends enthalpyOfGas "Enthalpy of gas mixture per unit mass of gas mixture"
      algorithm
        h := enthalpyOfCondensingGas(T)*X[Water] + enthalpyOfDryAir(T)*(1.0 - X[Water]);
        annotation(Inline = true);
      end enthalpyOfGas;

      redeclare replaceable function extends enthalpyOfLiquid "Enthalpy of liquid (per unit mass of liquid) which is linear in the temperature"
      algorithm
        h := (T - reference_T)*cpWatLiq;
        annotation(smoothOrder = 5, Inline = true, derivative = der_enthalpyOfLiquid);
      end enthalpyOfLiquid;

      redeclare function extends enthalpyOfVaporization "Enthalpy of vaporization of water"
      algorithm
        r0 := h_fg;
        annotation(Inline = true);
      end enthalpyOfVaporization;

      redeclare function extends gasConstant "Return ideal gas constant as a function from thermodynamic state, only valid for phi<1"
      algorithm
        R_s := dryair.R*(1 - state.X[Water]) + steam.R*state.X[Water];
        annotation(smoothOrder = 2, Inline = true);
      end gasConstant;

      redeclare function extends pressure "Returns pressure of ideal gas as a function of the thermodynamic state record"
      algorithm
        p := state.p;
        annotation(smoothOrder = 2, Inline = true);
      end pressure;

      redeclare function extends isobaricExpansionCoefficient "Isobaric expansion coefficient beta"
      algorithm
        beta := 0;
        annotation(smoothOrder = 5, Inline = true);
      end isobaricExpansionCoefficient;

      redeclare function extends isothermalCompressibility "Isothermal compressibility factor"
      algorithm
        kappa := -1/state.p;
        annotation(smoothOrder = 5, Inline = true);
      end isothermalCompressibility;

      redeclare function extends saturationPressure "Saturation curve valid for 223.16 <= T <= 373.16 (and slightly outside with less accuracy)"
      algorithm
        psat := Buildings.Utilities.Psychrometrics.Functions.saturationPressure(Tsat);
        annotation(smoothOrder = 5, Inline = true);
      end saturationPressure;

      redeclare function extends specificEntropy "Return the specific entropy, only valid for phi<1"
      protected
        Modelica.Units.SI.MoleFraction Y[2] "Molar fraction";
      algorithm
        Y := massToMoleFractions(state.X, {steam.MM, dryair.MM});
        s := specificHeatCapacityCp(state)*Modelica.Math.log(state.T/reference_T) - Modelica.Constants.R*sum(state.X[i]/MMX[i]*Modelica.Math.log(max(Y[i], Modelica.Constants.eps)*state.p/reference_p) for i in 1:2);
        annotation(Inline = true);
      end specificEntropy;

      redeclare function extends density_derp_T "Return the partial derivative of density with respect to pressure at constant temperature"
      algorithm
        ddpT := dStp/pStp;
        annotation(Inline = true);
      end density_derp_T;

      redeclare function extends density_derT_p "Return the partial derivative of density with respect to temperature at constant pressure"
      algorithm
        ddTp := 0;
        annotation(smoothOrder = 99, Inline = true);
      end density_derT_p;

      redeclare function extends density_derX "Return the partial derivative of density with respect to mass fractions at constant pressure and temperature"
      algorithm
        dddX := fill(0, nX);
        annotation(smoothOrder = 99, Inline = true);
      end density_derX;

      redeclare replaceable function extends specificHeatCapacityCp "Specific heat capacity of gas mixture at constant pressure"
      algorithm
        cp := dryair.cp*(1 - state.X[Water]) + steam.cp*state.X[Water];
        annotation(smoothOrder = 99, Inline = true, derivative = der_specificHeatCapacityCp);
      end specificHeatCapacityCp;

      redeclare replaceable function extends specificHeatCapacityCv "Specific heat capacity of gas mixture at constant volume"
      algorithm
        cv := dryair.cv*(1 - state.X[Water]) + steam.cv*state.X[Water];
        annotation(smoothOrder = 99, Inline = true, derivative = der_specificHeatCapacityCv);
      end specificHeatCapacityCv;

      redeclare function extends setState_phX "Return thermodynamic state as function of pressure p, specific enthalpy h and composition X"
      algorithm
        state := if size(X, 1) == nX then ThermodynamicState(p = p, T = temperature_phX(p, h, X), X = X) else ThermodynamicState(p = p, T = temperature_phX(p, h, X), X = cat(1, X, {1 - sum(X)}));
        annotation(smoothOrder = 2, Inline = true);
      end setState_phX;

      redeclare function extends setState_pTX "Return thermodynamic state as function of p, T and composition X or Xi"
      algorithm
        state := if size(X, 1) == nX then ThermodynamicState(p = p, T = T, X = X) else ThermodynamicState(p = p, T = T, X = cat(1, X, {1 - sum(X)}));
        annotation(smoothOrder = 2, Inline = true);
      end setState_pTX;

      redeclare function extends setState_psX "Return the thermodynamic state as function of p, s and composition X or Xi"
      protected
        Modelica.Units.SI.MassFraction X_int[2] "Mass fraction";
        Modelica.Units.SI.MoleFraction Y[2] "Molar fraction";
        Modelica.Units.SI.Temperature T "Temperature";
      algorithm
        if size(X, 1) == nX then
          X_int := X;
        else
          X_int := cat(1, X, {1 - sum(X)});
        end if;
        Y := massToMoleFractions(X_int, {steam.MM, dryair.MM});
        T := 273.15*Modelica.Math.exp((s + Modelica.Constants.R*sum(X_int[i]/MMX[i]*Modelica.Math.log(max(Y[i], Modelica.Constants.eps)) for i in 1:2))/specificHeatCapacityCp(setState_pTX(p = p, T = 273.15, X = X_int)));
        state := ThermodynamicState(p = p, T = T, X = X_int);
        annotation(Inline = true);
      end setState_psX;

      redeclare replaceable function extends specificEnthalpy "Compute specific enthalpy from pressure, temperature and mass fraction"
      algorithm
        h := (state.T - reference_T)*dryair.cp*(1 - state.X[Water]) + ((state.T - reference_T)*steam.cp + h_fg)*state.X[Water];
        annotation(smoothOrder = 5, Inline = true);
      end specificEnthalpy;

      redeclare replaceable function specificEnthalpy_pTX "Specific enthalpy"
        extends Modelica.Icons.Function;
        input Modelica.Units.SI.Pressure p "Pressure";
        input Modelica.Units.SI.Temperature T "Temperature";
        input Modelica.Units.SI.MassFraction X[:] "Mass fractions of moist air";
        output Modelica.Units.SI.SpecificEnthalpy h "Specific enthalpy at p, T, X";
      algorithm
        h := specificEnthalpy(setState_pTX(p, T, X));
        annotation(smoothOrder = 5, Inline = true, inverse(T = temperature_phX(p, h, X)));
      end specificEnthalpy_pTX;

      redeclare replaceable function extends specificGibbsEnergy "Specific Gibbs energy"
      algorithm
        g := specificEnthalpy(state) - state.T*specificEntropy(state);
        annotation(Inline = true);
      end specificGibbsEnergy;

      redeclare replaceable function extends specificHelmholtzEnergy "Specific Helmholtz energy"
      algorithm
        f := specificEnthalpy(state) - gasConstant(state)*state.T - state.T*specificEntropy(state);
        annotation(Inline = true);
      end specificHelmholtzEnergy;

      redeclare function extends isentropicEnthalpy "Return the isentropic enthalpy"
      algorithm
        h_is := specificEnthalpy(setState_psX(p = p_downstream, s = specificEntropy(refState), X = refState.X));
        annotation(Inline = true);
      end isentropicEnthalpy;

      redeclare function extends specificInternalEnergy "Specific internal energy"
        extends Modelica.Icons.Function;
      algorithm
        u := specificEnthalpy(state) - pStp/dStp;
        annotation(Inline = true);
      end specificInternalEnergy;

      redeclare function extends temperature "Return temperature of ideal gas as a function of the thermodynamic state record"
      algorithm
        T := state.T;
        annotation(smoothOrder = 2, Inline = true);
      end temperature;

      redeclare function extends molarMass "Return the molar mass"
      algorithm
        MM := 1/(state.X[Water]/MMX[Water] + (1.0 - state.X[Water])/MMX[Air]);
        annotation(Inline = true, smoothOrder = 99);
      end molarMass;

      redeclare replaceable function temperature_phX "Compute temperature from specific enthalpy and mass fraction"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEnthalpy h "specific enthalpy";
        input MassFraction X[:] "mass fractions of composition";
        output Temperature T "temperature";
      algorithm
        T := reference_T + (h - h_fg*X[Water])/((1 - X[Water])*dryair.cp + X[Water]*steam.cp);
        annotation(smoothOrder = 5, Inline = true, inverse(h = specificEnthalpy_pTX(p, T, X)));
      end temperature_phX;

      redeclare function extends thermalConductivity "Thermal conductivity of dry air as a polynomial in the temperature"
      algorithm
        lambda := Modelica.Math.Polynomials.evaluate({(-4.8737307422969E-008), 7.67803133753502E-005, 0.0241814385504202}, Modelica.Units.Conversions.to_degC(state.T));
        annotation(LateInline = true);
      end thermalConductivity;

    protected
      record GasProperties "Coefficient data record for properties of perfect gases"
        extends Modelica.Icons.Record;
        Modelica.Units.SI.MolarMass MM "Molar mass";
        Modelica.Units.SI.SpecificHeatCapacity R "Gas constant";
        Modelica.Units.SI.SpecificHeatCapacity cp "Specific heat capacity at constant pressure";
        Modelica.Units.SI.SpecificHeatCapacity cv = cp - R "Specific heat capacity at constant volume";
      end GasProperties;

      constant Modelica.Units.SI.SpecificEnergy h_fg = Buildings.Utilities.Psychrometrics.Constants.h_fg "Latent heat of evaporation of water";
      constant Modelica.Units.SI.SpecificHeatCapacity cpWatLiq = Buildings.Utilities.Psychrometrics.Constants.cpWatLiq "Specific heat capacity of liquid water";

      replaceable function der_enthalpyOfLiquid "Temperature derivative of enthalpy of liquid per unit mass of liquid"
        extends Modelica.Icons.Function;
        input Temperature T "Temperature";
        input Real der_T "Temperature derivative";
        output Real der_h "Derivative of liquid enthalpy";
      algorithm
        der_h := cpWatLiq*der_T;
        annotation(Inline = true);
      end der_enthalpyOfLiquid;

      function der_enthalpyOfCondensingGas "Derivative of enthalpy of steam per unit mass of steam"
        extends Modelica.Icons.Function;
        input Temperature T "Temperature";
        input Real der_T "Temperature derivative";
        output Real der_h "Derivative of steam enthalpy";
      algorithm
        der_h := steam.cp*der_T;
        annotation(Inline = true);
      end der_enthalpyOfCondensingGas;

      replaceable function enthalpyOfDryAir "Enthalpy of dry air per unit mass of dry air"
        extends Modelica.Icons.Function;
        input Temperature T "Temperature";
        output SpecificEnthalpy h "Dry air enthalpy";
      algorithm
        h := (T - reference_T)*dryair.cp;
        annotation(smoothOrder = 5, Inline = true, derivative = der_enthalpyOfDryAir);
      end enthalpyOfDryAir;

      replaceable function der_enthalpyOfDryAir "Derivative of enthalpy of dry air per unit mass of dry air"
        extends Modelica.Icons.Function;
        input Temperature T "Temperature";
        input Real der_T "Temperature derivative";
        output Real der_h "Derivative of dry air enthalpy";
      algorithm
        der_h := dryair.cp*der_T;
        annotation(Inline = true);
      end der_enthalpyOfDryAir;

      replaceable function der_specificHeatCapacityCp "Derivative of specific heat capacity of gas mixture at constant pressure"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state";
        input ThermodynamicState der_state "Derivative of thermodynamic state";
        output Real der_cp(unit = "J/(kg.K.s)") "Derivative of specific heat capacity";
      algorithm
        der_cp := (steam.cp - dryair.cp)*der_state.X[Water];
        annotation(Inline = true);
      end der_specificHeatCapacityCp;

      replaceable function der_specificHeatCapacityCv "Derivative of specific heat capacity of gas mixture at constant volume"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state";
        input ThermodynamicState der_state "Derivative of thermodynamic state";
        output Real der_cv(unit = "J/(kg.K.s)") "Derivative of specific heat capacity";
      algorithm
        der_cv := (steam.cv - dryair.cv)*der_state.X[Water];
        annotation(Inline = true);
      end der_specificHeatCapacityCv;
    end Air;
  end Media;

  package Utilities "Package with utility functions such as for I/O"
    extends Modelica.Icons.Package;

    package Math "Library with functions such as for smoothing"
      extends Modelica.Icons.Package;

      package Functions "Package with mathematical functions"
        extends Modelica.Icons.VariantsPackage;

        function cubicHermiteLinearExtrapolation "Interpolate using a cubic Hermite spline with linear extrapolation"
          extends Modelica.Icons.Function;
          input Real x "Abscissa value";
          input Real x1 "Lower abscissa value";
          input Real x2 "Upper abscissa value";
          input Real y1 "Lower ordinate value";
          input Real y2 "Upper ordinate value";
          input Real y1d "Lower gradient";
          input Real y2d "Upper gradient";
          output Real y "Interpolated ordinate value";
        algorithm
          if (x > x1 and x < x2) then
            y := Modelica.Fluid.Utilities.cubicHermite(x = x, x1 = x1, x2 = x2, y1 = y1, y2 = y2, y1d = y1d, y2d = y2d);
          elseif x <= x1 then
            y := y1 + (x - x1)*y1d;
          else
            y := y2 + (x - x2)*y2d;
          end if;
          annotation(smoothOrder = 1);
        end cubicHermiteLinearExtrapolation;

        function inverseXRegularized "Function that approximates 1/x by a twice continuously differentiable function"
          extends Modelica.Icons.Function;
          input Real x "Abscissa value";
          input Real delta(min = Modelica.Constants.eps) "Abscissa value below which approximation occurs";
          input Real deltaInv = 1/delta "Inverse value of delta";
          input Real a = -15*deltaInv "Polynomial coefficient";
          input Real b = 119*deltaInv^2 "Polynomial coefficient";
          input Real c = -361*deltaInv^3 "Polynomial coefficient";
          input Real d = 534*deltaInv^4 "Polynomial coefficient";
          input Real e = -380*deltaInv^5 "Polynomial coefficient";
          input Real f = 104*deltaInv^6 "Polynomial coefficient";
          output Real y "Function value";
        algorithm
          y := if (x > delta or x < -delta) then 1/x elseif (x < delta/2 and x > -delta/2) then x/(delta*delta) else Buildings.Utilities.Math.Functions.BaseClasses.smoothTransition(x = x, delta = delta, deltaInv = deltaInv, a = a, b = b, c = c, d = d, e = e, f = f);
          annotation(smoothOrder = 2, derivative(order = 1, zeroDerivative = delta, zeroDerivative = deltaInv, zeroDerivative = a, zeroDerivative = b, zeroDerivative = c, zeroDerivative = d, zeroDerivative = e, zeroDerivative = f) = Buildings.Utilities.Math.Functions.BaseClasses.der_inverseXRegularized, Inline = true);
        end inverseXRegularized;

        function isMonotonic "Returns true if the argument is a monotonic sequence"
          extends Modelica.Icons.Function;
          input Real x[:] "Sequence to be tested";
          input Boolean strict = false "Set to true to test for strict monotonicity";
          output Boolean monotonic "True if x is monotonic increasing or decreasing";
        protected
          Integer n = size(x, 1) "Number of data points";
        algorithm
          if n == 1 then
            monotonic := true;
          else
            monotonic := true;
            if strict then
              if (x[1] >= x[n]) then
                for i in 1:n - 1 loop
                  if (not x[i] > x[i + 1]) then
                    monotonic := false;
                  else
                  end if;
                end for;
              else
                for i in 1:n - 1 loop
                  if (not x[i] < x[i + 1]) then
                    monotonic := false;
                  else
                  end if;
                end for;
              end if;
            else
              if (x[1] >= x[n]) then
                for i in 1:n - 1 loop
                  if (not x[i] >= x[i + 1]) then
                    monotonic := false;
                  else
                  end if;
                end for;
              else
                for i in 1:n - 1 loop
                  if (not x[i] <= x[i + 1]) then
                    monotonic := false;
                  else
                  end if;
                end for;
              end if;
            end if;
          end if;
        end isMonotonic;

        function regStep "Approximation of a general step, such that the approximation is continuous and differentiable"
          extends Modelica.Icons.Function;
          input Real x "Abscissa value";
          input Real y1 "Ordinate value for x > 0";
          input Real y2 "Ordinate value for x < 0";
          input Real x_small(min = 0) = 1e-5 "Approximation of step for -x_small <= x <= x_small; x_small >= 0 required";
          output Real y "Ordinate value to approximate y = if x > 0 then y1 else y2";
        algorithm
          y := smooth(1, if x > x_small then y1 else if x < -x_small then y2 else if x_small > 0 then (x/x_small)*((x/x_small)^2 - 3)*(y2 - y1)/4 + (y1 + y2)/2 else (y1 + y2)/2);
          annotation(Inline = true);
        end regStep;

        function smoothInterpolation "Interpolate using a cubic Hermite spline with linear extrapolation for a vector xSup[], ySup[] and independent variable x"
          extends Modelica.Icons.Function;
          input Real x "Abscissa value";
          input Real xSup[:] "Support points (strictly increasing)";
          input Real ySup[size(xSup, 1)] "Function values at xSup";
          input Boolean ensureMonotonicity = isMonotonic(ySup, strict = false) "Set to true to ensure monotonicity of the cubic hermite";
          output Real yInt "Interpolated ordinate value";
        protected
          Integer n = size(xSup, 1) "Number of support points";
          Real dy_dx[size(xSup, 1)] "Derivative at xSup";
          Integer i "Integer to select data interval";
        algorithm
          if n > 2 then
            dy_dx := Buildings.Utilities.Math.Functions.splineDerivatives(x = xSup, y = ySup, ensureMonotonicity = ensureMonotonicity);
            i := 1;
            for j in 1:n - 1 loop
              if x > xSup[j] then
                i := j;
              else
              end if;
            end for;
            assert(xSup[i] < xSup[i + 1], "Support points xSup must be increasing.");
            yInt := cubicHermiteLinearExtrapolation(x = x, x1 = xSup[i], x2 = xSup[i + 1], y1 = ySup[i], y2 = ySup[i + 1], y1d = dy_dx[i], y2d = dy_dx[i + 1]);
          elseif n == 2 then
            yInt := ySup[1] + (x - xSup[1])*(ySup[2] - ySup[1])/(xSup[2] - xSup[1]);
          else
            yInt := ySup[1];
          end if;
          annotation(smoothOrder = 1);
        end smoothInterpolation;

        function smoothMax "Once continuously differentiable approximation to the maximum function"
          extends Modelica.Icons.Function;
          input Real x1 "First argument";
          input Real x2 "Second argument";
          input Real deltaX "Width of transition interval";
          output Real y "Result";
        algorithm
          y := Buildings.Utilities.Math.Functions.regStep(y1 = x1, y2 = x2, x = x1 - x2, x_small = deltaX);
          annotation(Inline = true, smoothOrder = 1);
        end smoothMax;

        function smoothMin "Once continuously differentiable approximation to the minimum function"
          extends Modelica.Icons.Function;
          input Real x1 "First argument";
          input Real x2 "Second argument";
          input Real deltaX "Width of transition interval";
          output Real y "Result";
        algorithm
          y := Buildings.Utilities.Math.Functions.regStep(y1 = x1, y2 = x2, x = x2 - x1, x_small = deltaX);
          annotation(Inline = true, smoothOrder = 1);
        end smoothMin;

        function splineDerivatives "Function to compute the derivatives for cubic hermite spline interpolation"
          extends Modelica.Icons.Function;
          input Real x[:] "Support point, strictly increasing";
          input Real y[size(x, 1)] "Function values at x";
          input Boolean ensureMonotonicity = isMonotonic(y, strict = false) "Set to true to ensure monotonicity of the cubic hermite";
          output Real d[size(x, 1)] "Derivative at the support points";
        protected
          Integer n = size(x, 1) "Number of data points";
          Real delta[n - 1] "Slope of secant line between data points";
          Real alpha "Coefficient to ensure monotonicity";
          Real beta "Coefficient to ensure monotonicity";
          Real tau "Coefficient to ensure monotonicity";
        algorithm
          if (n > 1) then
            assert(x[1] < x[n], "x must be strictly increasing.
          Received x[1] = " + String(x[1]) + "
                   x[" + String(n) + "] = " + String(x[n]));
            assert(isMonotonic(x, strict = true), "x-values must be strictly increasing or decreasing.");
            if ensureMonotonicity then
              assert(isMonotonic(y, strict = false), "If ensureMonotonicity=true, y-values must be strictly increasing or decreasing.");
            else
            end if;
          else
          end if;
          if n == 1 then
            d[1] := 0;
          elseif n == 2 then
            d[1] := (y[2] - y[1])/(x[2] - x[1]);
            d[2] := d[1];
          else
            for i in 1:n - 1 loop
              delta[i] := (y[i + 1] - y[i])/(x[i + 1] - x[i]);
            end for;
            d[1] := delta[1];
            d[n] := delta[n - 1];
            for i in 2:n - 1 loop
              d[i] := (delta[i - 1] + delta[i])/2;
            end for;
          end if;
          if n > 2 and ensureMonotonicity then
            for i in 1:n - 1 loop
              if (abs(delta[i]) < Modelica.Constants.small) then
                d[i] := 0;
                d[i + 1] := 0;
              else
                alpha := d[i]/delta[i];
                beta := d[i + 1]/delta[i];
                if (alpha^2 + beta^2) > 9 then
                  tau := 3/(alpha^2 + beta^2)^(1/2);
                  d[i] := delta[i]*alpha*tau;
                  d[i + 1] := delta[i]*beta*tau;
                else
                end if;
              end if;
            end for;
          else
          end if;
        end splineDerivatives;

        package BaseClasses "Package with base classes for Buildings.Utilities.Math.Functions"
          extends Modelica.Icons.BasesPackage;

          function der_2_smoothTransition "Second order derivative of smoothTransition with respect to x"
            extends Modelica.Icons.Function;
            input Real x "Abscissa value";
            input Real delta(min = Modelica.Constants.eps) "Abscissa value below which approximation occurs";
            input Real deltaInv "Inverse value of delta";
            input Real a "Polynomial coefficient";
            input Real b "Polynomial coefficient";
            input Real c "Polynomial coefficient";
            input Real d "Polynomial coefficient";
            input Real e "Polynomial coefficient";
            input Real f "Polynomial coefficient";
            input Real x_der "Derivative of x";
            input Real x_der2 "Second order derivative of x";
            output Real y_der2 "Second order derivative of function value";
          protected
            Real aX "Absolute value of x";
            Real ex "Intermediate expression";
          algorithm
            aX := abs(x);
            ex := 2*c + aX*(6*d + aX*(12*e + aX*20*f));
            y_der2 := (b + aX*(2*c + aX*(3*d + aX*(4*e + aX*5*f))))*x_der2 + x_der*x_der*(if x > 0 then ex else -ex);
          end der_2_smoothTransition;

          function der_inverseXRegularized "Derivative of inverseXRegularised function"
            extends Modelica.Icons.Function;
            input Real x "Abscissa value";
            input Real delta(min = Modelica.Constants.eps) "Abscissa value below which approximation occurs";
            input Real deltaInv = 1/delta "Inverse value of delta";
            input Real a = -15*deltaInv "Polynomial coefficient";
            input Real b = 119*deltaInv^2 "Polynomial coefficient";
            input Real c = -361*deltaInv^3 "Polynomial coefficient";
            input Real d = 534*deltaInv^4 "Polynomial coefficient";
            input Real e = -380*deltaInv^5 "Polynomial coefficient";
            input Real f = 104*deltaInv^6 "Polynomial coefficient";
            input Real x_der "Abscissa value";
            output Real y_der "Function value";
          algorithm
            y_der := if (x > delta or x < -delta) then -x_der/x/x elseif (x < delta/2 and x > -delta/2) then x_der/(delta*delta) else Buildings.Utilities.Math.Functions.BaseClasses.der_smoothTransition(x = x, x_der = x_der, delta = delta, deltaInv = deltaInv, a = a, b = b, c = c, d = d, e = e, f = f);
          end der_inverseXRegularized;

          function der_smoothTransition "First order derivative of smoothTransition with respect to x"
            extends Modelica.Icons.Function;
            input Real x "Abscissa value";
            input Real delta(min = Modelica.Constants.eps) "Abscissa value below which approximation occurs";
            input Real deltaInv "Inverse value of delta";
            input Real a "Polynomial coefficient";
            input Real b "Polynomial coefficient";
            input Real c "Polynomial coefficient";
            input Real d "Polynomial coefficient";
            input Real e "Polynomial coefficient";
            input Real f "Polynomial coefficient";
            input Real x_der "Derivative of x";
            output Real y_der "Derivative of function value";
          protected
            Real aX "Absolute value of x";
          algorithm
            aX := abs(x);
            y_der := (b + aX*(2*c + aX*(3*d + aX*(4*e + aX*5*f))))*x_der;
            annotation(smoothOrder = 1, derivative(order = 2, zeroDerivative = delta, zeroDerivative = deltaInv, zeroDerivative = a, zeroDerivative = b, zeroDerivative = c, zeroDerivative = d, zeroDerivative = e, zeroDerivative = f) = Buildings.Utilities.Math.Functions.BaseClasses.der_2_smoothTransition);
          end der_smoothTransition;

          function smoothTransition "Twice continuously differentiable transition between the regions"
            extends Modelica.Icons.Function;
            input Real x "Abscissa value";
            input Real delta(min = Modelica.Constants.eps) "Abscissa value below which approximation occurs";
            input Real deltaInv = 1/delta "Inverse value of delta";
            input Real a = -15*deltaInv "Polynomial coefficient";
            input Real b = 119*deltaInv^2 "Polynomial coefficient";
            input Real c = -361*deltaInv^3 "Polynomial coefficient";
            input Real d = 534*deltaInv^4 "Polynomial coefficient";
            input Real e = -380*deltaInv^5 "Polynomial coefficient";
            input Real f = 104*deltaInv^6 "Polynomial coefficient";
            output Real y "Function value";
          protected
            Real aX "Absolute value of x";
          algorithm
            aX := abs(x);
            y := (if x >= 0 then 1 else -1)*(a + aX*(b + aX*(c + aX*(d + aX*(e + aX*f)))));
            annotation(smoothOrder = 2, derivative(order = 1, zeroDerivative = delta, zeroDerivative = deltaInv, zeroDerivative = a, zeroDerivative = b, zeroDerivative = c, zeroDerivative = d, zeroDerivative = e, zeroDerivative = f) = Buildings.Utilities.Math.Functions.BaseClasses.der_smoothTransition);
          end smoothTransition;
        end BaseClasses;
      end Functions;
    end Math;

    package Psychrometrics "Library with psychrometric functions"
      extends Modelica.Icons.VariantsPackage;

      package Constants "Library of constants for psychometric functions"
        extends Modelica.Icons.Package;
        constant Modelica.Units.SI.SpecificHeatCapacity cpAir = 1006 "Specific heat capacity of air";
        constant Modelica.Units.SI.SpecificHeatCapacity cpSte = 1860 "Specific heat capacity of water vapor";
        constant Modelica.Units.SI.SpecificHeatCapacity cpWatLiq = 4184 "Specific heat capacity of liquid water";
        constant Modelica.Units.SI.SpecificEnthalpy h_fg = 2501014.5 "Enthalpy of evaporation of water at the reference temperature";
      end Constants;

      package Functions "Package with psychrometric functions"
        extends Modelica.Icons.Package;

        function saturationPressure "Saturation curve valid for 223.16 <= T <= 373.16 (and slightly outside with less accuracy)"
          extends Modelica.Icons.Function;
          input Modelica.Units.SI.Temperature TSat(displayUnit = "degC", nominal = 300) "Saturation temperature";
          output Modelica.Units.SI.AbsolutePressure pSat(displayUnit = "Pa", nominal = 1000) "Saturation pressure";
        algorithm
          pSat := Buildings.Utilities.Math.Functions.regStep(y1 = Buildings.Utilities.Psychrometrics.Functions.saturationPressureLiquid(TSat), y2 = Buildings.Utilities.Psychrometrics.Functions.sublimationPressureIce(TSat), x = TSat - 273.16, x_small = 1.0);
          annotation(Inline = true, smoothOrder = 1);
        end saturationPressure;

        function saturationPressureLiquid "Return saturation pressure of water as a function of temperature T in the range of 273.16 to 373.16 K"
          extends Modelica.Icons.Function;
          input Modelica.Units.SI.Temperature TSat(displayUnit = "degC", nominal = 300) "Saturation temperature";
          output Modelica.Units.SI.AbsolutePressure pSat(displayUnit = "Pa", nominal = 1000) "Saturation pressure";
        algorithm
          pSat := 611.657*Modelica.Math.exp(17.2799 - 4102.99/(TSat - 35.719));
          annotation(smoothOrder = 99, derivative = Buildings.Utilities.Psychrometrics.Functions.BaseClasses.der_saturationPressureLiquid, Inline = true);
        end saturationPressureLiquid;

        function sublimationPressureIce "Return sublimation pressure of water as a function of temperature T between 190 and 273.16 K"
          extends Modelica.Icons.Function;
          input Modelica.Units.SI.Temperature TSat(displayUnit = "degC", nominal = 300) "Saturation temperature";
          output Modelica.Units.SI.AbsolutePressure pSat(displayUnit = "Pa", nominal = 1000) "Saturation pressure";
        protected
          Modelica.Units.SI.Temperature TTriple = 273.16 "Triple point temperature";
          Modelica.Units.SI.AbsolutePressure pTriple = 611.657 "Triple point pressure";
          Real r1 = TSat/TTriple "Common subexpression";
          Real a[2] = {-13.9281690, 34.7078238} "Coefficients a[:]";
          Real n[2] = {-1.5, -1.25} "Coefficients n[:]";
        algorithm
          pSat := exp(a[1] - a[1]*r1^n[1] + a[2] - a[2]*r1^n[2])*pTriple;
          annotation(Inline = false, smoothOrder = 5, derivative = Buildings.Utilities.Psychrometrics.Functions.BaseClasses.der_sublimationPressureIce);
        end sublimationPressureIce;

        package BaseClasses "Package with base classes for Buildings.Utilities.Psychrometrics.Functions"
          extends Modelica.Icons.BasesPackage;

          function der_saturationPressureLiquid "Derivative of the function saturationPressureLiquid"
            extends Modelica.Icons.Function;
            input Modelica.Units.SI.Temperature TSat "Saturation temperature";
            input Real dTSat(unit = "K/s") "Saturation temperature derivative";
            output Real psat_der(unit = "Pa/s") "Differential of saturation pressure";
          algorithm
            psat_der := 611.657*Modelica.Math.exp(17.2799 - 4102.99/(TSat - 35.719))*4102.99*dTSat/(TSat - 35.719)^2;
            annotation(Inline = false, smoothOrder = 98);
          end der_saturationPressureLiquid;

          function der_sublimationPressureIce "Derivative of function sublimationPressureIce"
            extends Modelica.Icons.Function;
            input Modelica.Units.SI.Temperature TSat(displayUnit = "degC", nominal = 300) "Saturation temperature";
            input Real dTSat(unit = "K/s") "Sublimation temperature derivative";
            output Real psat_der(unit = "Pa/s") "Sublimation pressure derivative";
          protected
            Modelica.Units.SI.Temperature TTriple = 273.16 "Triple point temperature";
            Modelica.Units.SI.AbsolutePressure pTriple = 611.657 "Triple point pressure";
            Real r1 = TSat/TTriple "Common subexpression 1";
            Real r1_der = dTSat/TTriple "Derivative of common subexpression 1";
            Real a[2] = {-13.9281690, 34.7078238} "Coefficients a[:]";
            Real n[2] = {-1.5, -1.25} "Coefficients n[:]";
          algorithm
            psat_der := exp(a[1] - a[1]*r1^n[1] + a[2] - a[2]*r1^n[2])*pTriple*(-(a[1]*(r1^(n[1] - 1)*n[1]*r1_der)) - (a[2]*(r1^(n[2] - 1)*n[2]*r1_der)));
            annotation(Inline = false, smoothOrder = 5);
          end der_sublimationPressureIce;
        end BaseClasses;
      end Functions;
    end Psychrometrics;
  end Utilities;
  annotation(version = "13.0.0", versionDate = "2025-05-29", dateModified = "2025-05-29");
end Buildings;

model Example2_total
  extends BL.Examples.Basic.Example2;
end Example2_total;
