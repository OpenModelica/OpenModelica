within SiemensPower.Boundaries;
model GasSinkP "Pressure sink for gas flows"
  // removed Media
//  replaceable package Medium = Modelica.Media.Air.SimpleAir constrainedby
//   Modelica.Media.Interfaces.PartialMedium "Medium model"

  parameter SiemensPower.Units.Pressure p_start=101325 "Pressure";
  parameter SiemensPower.Units.Temperature T_start= 300
    "Temperature for reverse flow";
//  parameter Medium.MassFraction Xi_start[Medium.nX]=Medium.reference_X
//    "Gas composition for reverse flow";
  parameter Boolean use_p_In = false;
  parameter Boolean use_T_In = false;
 // parameter Boolean use_Xi_In = false;

  SiemensPower.Interfaces.portGasIn portGas
    annotation (Placement(transformation(extent={{-120,-20},{-80,20}}, rotation=
           0)));
  Modelica.Blocks.Interfaces.RealInput p_In if use_p_In
    annotation (Placement(transformation(
        origin={-60,60},
        extent={{-20,-20},{20,20}},
        rotation=270)));
  Modelica.Blocks.Interfaces.RealInput T_In if use_T_In
    annotation (Placement(transformation(
        origin={0,90},
        extent={{-20,-20},{20,20}},
        rotation=270)));

 // Medium.BaseProperties gas(
 //   p(start=p_start),
 //   T(start=T_start),
 //   Xi(start=Xi_start[1:Medium.nXi]));

 SiemensPower.Units.Temperature T(start = T_start);
 SiemensPower.Units.Pressure p(start = p_start);
 SiemensPower.Units.SpecificEnthalpy h;
//  SiemensPower.Units.SpecificHeatCapacity cp;

protected
  Modelica.Blocks.Interfaces.RealInput p_In_internal
    annotation (Placement(transformation(
        origin={-60,60},
        extent={{-20,-20},{20,20}},
        rotation=270)));
  Modelica.Blocks.Interfaces.RealInput T_In_internal
    annotation (Placement(transformation(
        origin={0,90},
        extent={{-20,-20},{20,20}},
        rotation=270)));
 // Modelica.Blocks.Interfaces.RealInput Xi_In_internal[Medium.nX]
 //   annotation (Placement(transformation(
 //       origin={0,90},
 //       extent={{-20,-20},{20,20}},
 //       rotation=270)));

equation
  connect(p_In, p_In_internal);
  connect(T_In, T_In_internal);
  //connect(Xi_In, Xi_In_internal);

  if not use_p_In then
    p_In_internal = p_start;
  end if;
  if not use_T_In then
    T_In_internal = T_start;
  end if;

  portGas.p = p;

  T = T_In_internal;
  p = p_In_internal;

  portGas.h_outflow  = h;

 // TPortActual=noEvent(Medium.temperature_phX(portGas.p, actualStream(portGas.h_outflow), actualStream(portGas.Xi_outflow)));
 //TPortActual=noEvent(Medium.temperature_phX(port.p, actualStream(port.h_outflow), actualStream(port.Xi_outflow)));

// T = (h) / cp;
// T-670 = (h-4e5) / cp;
   h = SiemensPower.Utilities.Functions.hT_FDBR82(T);
                                                                                                      annotation (
      choicesAllMatching=true,
              Icon(coordinateSystem(preserveAspectRatio=true,  extent={{-100,
            -100},{100,100}}), graphics={
        Text(extent={{-114,72},{-64,42}}, textString="p"),
        Text(extent={{-48,102},{2,72}}, textString="T"),
        Text(extent={{64,72},{114,42}}, textString="X"),
        Ellipse(
          extent={{-80,74},{80,-86}},
          lineColor={128,128,128},
          fillColor={159,159,223},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{-20,28},{28,-32}},
          lineColor={255,255,255},
          textString="P"),
        Text(
          extent={{-88,-82},{90,-132}},
          lineColor={0,0,0},
          textString="%name")}),                   Documentation(info="<html>
<p>This is a model for a fluid boundary condition with fixed </p>
<p><ul>
<li>pressure </li>
<li>temperature </li>
<li>composition </li>
</ul></p>
<p><h4>Modelling options</h4></p>
<p>The actual gas used in the component is determined by the replaceable <code>Medium</code> package. In the case of multiple component, variable composition gases, the nominal gas composition is given by <code>Xi_start</code>, whose default value is <code>Medium.reference_X</code> . </p>
<p>If <code>R</code> is set to zero, the pressure sink is ideal; otherwise, the inlet pressure increases proportionally to the outgoing flowrate.</p>
<p>If the <code>p_In</code> connector is wired, then the source pressure is given by the corresponding signal, otherwise it is fixed to <code>p_start</code>.</p>
<p>If the <code>T_In</code> connector is wired, then the source temperature is given by the corresponding signal, otherwise it is fixed to <code>T_start</code>.</p>
<p>If the <code>Xi_In</code> connector is wired, then the source massfraction is given by the corresponding signal, otherwise it is fixed to <code>Xi_start</code>.</p>

</html>
<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                                 <td><a href=\"mailto:kilian.link@siemens.com\">Kilian Link</a> </td>
                        <td><a href=\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\">SCD</a> </td>
                       </tr>
                <tr>
                           <td><b>Checked by:</b>   </td>
                           <td>            </td>
                </tr>
                <tr>
                           <td><b>Protection class:</b>    </td>
                           <td> </td>
                </tr>
                <tr>
                           <td><b>Used Dymola version:</b>    </td>
                           <td> </td>
                  </tr>
           </table>
                Copyright &copy  2007 Siemens AG, PG EIP12. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
           For details see <a href=\"../Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
</HTML>",
      revisions="<html>
<ul>
<li> December 2006, added to SiemensPower by Haiko Steuer
<li><i>August 26, 2005</i>
    by <a href=\"mailto:jonas.eborn@modelon.se\">Jonas Eborn</a>:<br>
       First release.</li>
</ul>
</html>"),
    Diagram(graphics));
end GasSinkP;
