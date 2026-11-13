within;
package MoistAirUnsaturated
redeclare function extends thermalConductivity
algorithm
  lambda := Modelica.Media.Incompressible.TableBased.Polynomials_Temp.evaluate(Modelica.SIunits.Conversions.to_degC(state.T));
end thermalConductivity;
end MoistAirUnsaturated;
