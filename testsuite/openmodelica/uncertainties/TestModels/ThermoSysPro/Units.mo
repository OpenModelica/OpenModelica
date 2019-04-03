within ThermoSysPro;
package Units "Additional SI and non-SI units"
  type Time_minute= Real(final quantity="Time", final unit="min");
  type Angle_deg= Real(final quantity="Angle", final unit="deg") annotation(Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
  type RotationVelocity= Real(final quantity="Rotation velocity", final unit="1/min") annotation(Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
  type PressureLossCoefficient= Real(final quantity="Pressure loss coefficient", final unit="m-4") annotation(Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
  type Temperature_degC= Real(final quantity="ThermodynamicTemperature", final unit="degC") annotation(Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
  type DerEnergyByTemperature= Real(final quantity="Derivative of the specific energy wrt. the temperature", final unit="J/(kg.K)") annotation(Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
  type DerDensityByEnthalpy= Real(final unit="kg2/(m3.J)");
  type DerDensityByEntropy= Real(final quantity="DerDensityByEntropy", final unit="kg2.K/(m3.J)");
  type DerEnergyByPressure= Real(final quantity="DerEnergyByPressure", final unit="J/Pa");
  type DerEntropyByTemperature= Real(final quantity="DerEntropyByTemperature", final unit="J/K2");
  type DerEntropyByPressure= Real(final quantity="DerEntropyByPressure", final unit="J/(K.Pa)");
  type DerPressureByDensity= Real(final quantity="DerPressureByDensity", final unit="Pa.m3/kg");
  type DerPressureBySpecificVolume= Real(final quantity="DerPressureBySpecificVolume", final unit="Pa.kg/m3");
  type DerPressureByTemperature= Real(final quantity="DerPressureByTemperature", final unit="Pa/K");
  type DerVolumeByTemperature= Real(final quantity="DerVolumeByTemperature", final unit="m3/K");
  type DerVolumeByPressure= Real(final quantity="DerVolumeByPressure", final unit="m3/Pa");
  type MassFraction= Real(final quantity="Mass fraction", final unit="1");
  type AbsoluteTemperature= Modelica.SIunits.Temperature(nominal=500, start=300, min=200, max=6000);
  type AbsolutePressure= Modelica.SIunits.AbsolutePressure(nominal=1000000.0, start=100000.0, min=100, max=1000000000.0);
  type SpecificEnthalpy= Modelica.SIunits.SpecificEnthalpy(nominal=1500000.0, start=1000000.0, min=-1000000.0, max=100000000.0);
  type Cv= Real(final quantity="Cv U.S.", final unit="m4/(s.N5)") annotation(Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,-100},{80,50}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{100,70},{100,-80},{80,-100},{80,50},{100,70}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{-120,135},{120,70}}, textString="%name", fillColor={255,0,0}),Text(lineColor={0,0,255}, extent={{-90,40},{70,10}}, textString="Unites", fillColor={160,160,160}),Rectangle(extent={{-32,-6},{16,-35}}, lineColor={0,0,0}),Rectangle(extent={{-32,-56},{16,-85}}, lineColor={0,0,0}),Line(points={{16,-20},{49,-20},{49,-71},{16,-71}}, color={0,0,0}),Line(points={{-32,-72},{-64,-72},{-64,-21},{-32,-21}}, color={0,0,0})}), Documentation(info="<html>
</html>"));
  type Pressure_bar= Real(final quantity="Pressure", final unit="bar");
  type DifferentialPressure= Modelica.SIunits.AbsolutePressure(nominal=100000.0, start=100000.0, min=-1000000000.0, max=1000000000.0);
  type DifferentialTemperature= Modelica.SIunits.Temperature(nominal=100, start=0, min=-6000, max=6000);
end Units;
