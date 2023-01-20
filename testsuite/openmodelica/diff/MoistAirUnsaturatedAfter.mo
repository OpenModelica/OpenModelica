within;

package MoistAirUnsaturated
  redeclare function extends thermalConductivity
    algorithm
      lambda := Modelica.Math.Polynomials.evaluate(Modelica.Units.Conversions.to_degC(state.T));
  end thermalConductivity;

end MoistAirUnsaturated;