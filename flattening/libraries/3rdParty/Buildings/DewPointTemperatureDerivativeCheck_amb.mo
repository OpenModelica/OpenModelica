//name: DewPointTemperatureDerivativeCheck_amb [BUG: #2853]
//keyword: Buildings and Annex60 library
//status: correct
//
// instantiate example
//

package Buildings
  extends Modelica.Icons.Package;

  package Utilities
    extends Modelica.Icons.Package;

    package Psychrometrics
      extends Modelica.Icons.VariantsPackage;

      package Functions
        extends Modelica.Icons.Package;

        function pW_TDewPoi_amb
          extends Buildings.Utilities.Psychrometrics.Functions.BaseClasses.pW_TDewPoi_amb;
          input Modelica.SIunits.Temperature T;
          output Modelica.SIunits.Pressure p_w(displayUnit = "Pa", min = 100);
        algorithm
          p_w := Modelica.Math.exp(a1 + a2 * T);
        end pW_TDewPoi_amb;

        package BaseClasses
          extends Modelica.Icons.BasesPackage;

          function der_pW_TDewPoi_amb
            extends Buildings.Utilities.Psychrometrics.Functions.BaseClasses.pW_TDewPoi_amb;
            input Modelica.SIunits.Temperature T;
            input Real dT;
            output Real dp_w;
          algorithm
            dp_w := a2 * Modelica.Math.exp(a1 + a2 * T) * dT;
          end der_pW_TDewPoi_amb;

          partial function pW_TDewPoi_amb
            extends Modelica.Icons.Function;
          protected
            constant Modelica.SIunits.Temperature T1 = 283.15;
            constant Modelica.SIunits.Temperature T2 = 293.15;
            constant Modelica.SIunits.Pressure p1 = 1227.97;
            constant Modelica.SIunits.Pressure p2 = 2338.76;
            constant Real a1 = (Modelica.Math.log(p2) - Modelica.Math.log(p1) * T2 / T1) / (1 - T2 / T1);
            constant Real a2(unit = "1/K") = (Modelica.Math.log(p1) - a1) / T1;
          end pW_TDewPoi_amb;

          package Examples
            extends Modelica.Icons.ExamplesPackage;

            model DewPointTemperatureDerivativeCheck_amb
              extends Modelica.Icons.Example;
              Real x;
              Real y;
              parameter Real uniCon(unit = "K/s") = 1;
            initial equation
              y = x;
            equation
              x = Buildings.Utilities.Psychrometrics.Functions.pW_TDewPoi_amb(T = time * uniCon);
              der(y) = der(x);
              assert(abs(x - y) < 1E-2, "Model has an error");
            end DewPointTemperatureDerivativeCheck_amb;
          end Examples;
        end BaseClasses;
      end Functions;
    end Psychrometrics;
  end Utilities;
end Buildings;

package Modelica
  extends Modelica.Icons.Package;

  package Math
    extends Modelica.Icons.Package;

    package Icons
      extends Modelica.Icons.IconsPackage;

      partial function AxisLeft  end AxisLeft;

      partial function AxisCenter  end AxisCenter;
    end Icons;

    function exp
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output Real y;
      external "builtin" y = exp(u);
    end exp;

    function log
      extends Modelica.Math.Icons.AxisLeft;
      input Real u;
      output Real y;
      external "builtin" y = log(u);
    end log;
  end Math;

  package Icons
    extends Icons.Package;

    partial package ExamplesPackage
      extends Modelica.Icons.Package;
    end ExamplesPackage;

    partial model Example  end Example;

    partial package Package  end Package;

    partial package BasesPackage
      extends Modelica.Icons.Package;
    end BasesPackage;

    partial package VariantsPackage
      extends Modelica.Icons.Package;
    end VariantsPackage;

    partial package IconsPackage
      extends Modelica.Icons.Package;
    end IconsPackage;

    partial function Function  end Function;
  end Icons;

  package SIunits
    extends Modelica.Icons.Package;
    type Pressure = Real(final quantity = "Pressure", final unit = "Pa", displayUnit = "bar");
    type ThermodynamicTemperature = Real(final quantity = "ThermodynamicTemperature", final unit = "K", min = 0.0, start = 288.15, nominal = 300, displayUnit = "degC");
    type Temperature = ThermodynamicTemperature;
  end SIunits;
end Modelica;

model DewPointTemperatureDerivativeCheck_amb
  extends Buildings.Utilities.Psychrometrics.Functions.BaseClasses.Examples.DewPointTemperatureDerivativeCheck_amb;
  annotation(__Dymola_Commands(file = "modelica://Buildings/Resources/Scripts/Dymola/Utilities/Psychrometrics/Functions/BaseClasses/Examples/DewPointTemperatureDerivativeCheck_amb.mos"), experiment(StartTime = 273.15, StopTime = 323.15));
end DewPointTemperatureDerivativeCheck_amb;

// Result:
// function Buildings.Utilities.Psychrometrics.Functions.pW_TDewPoi_amb
//   protected constant Real T1(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = 283.15;
//   protected constant Real T2(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = 293.15;
//   protected constant Real p1(quantity = "Pressure", unit = "Pa", displayUnit = "bar") = 1227.97;
//   protected constant Real p2(quantity = "Pressure", unit = "Pa", displayUnit = "bar") = 2338.76;
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   output Real p_w(quantity = "Pressure", unit = "Pa", displayUnit = "Pa", min = 100.0);
//   protected constant Real a1 = -11.12906103909587;
//   protected constant Real a2(unit = "1/K") = 0.06442584749262621;
// algorithm
//   p_w := exp(-11.12906103909587 + 0.06442584749262621 * T);
// end Buildings.Utilities.Psychrometrics.Functions.pW_TDewPoi_amb;
//
// class DewPointTemperatureDerivativeCheck_amb
//   Real x;
//   Real y;
//   parameter Real uniCon(unit = "K/s") = 1.0;
// initial equation
//   y = x;
// equation
//   x = Buildings.Utilities.Psychrometrics.Functions.pW_TDewPoi_amb(time * uniCon);
//   der(y) = der(x);
//   assert(abs(x - y) < 0.01, "Model has an error");
// end DewPointTemperatureDerivativeCheck_amb;
// endResult
