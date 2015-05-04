within SiemensPower.Fluid;
partial model PartialFlowSensor
  "Partial component to model sensors that measure flow properties"
  extends SiemensPower.Fluid.PartialTwoPort;

equation
  // mass balance
  0 = port_a.m_flow + port_b.m_flow;

  // momentum equation (no pressure loss)
  port_a.p = port_b.p;

  // isenthalpic state transformation (no storage and no loss of energy)
  port_a.h_outflow = inStream(port_b.h_outflow);
  port_b.h_outflow = inStream(port_a.h_outflow);

  annotation (Documentation(info="<html>
<p>
Partial component to model a <b>sensor</b> that measures any intensive properties
of a flow, e.g., to get temperature or density in the flow
between fluid connectors.<br>
The model includes zero-volume balance equations. Sensor models inheriting from
this partial class should add a medium instance to calculate the measured property.
</p>
</html>"),
    Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={1,1}), graphics));
end PartialFlowSensor;
