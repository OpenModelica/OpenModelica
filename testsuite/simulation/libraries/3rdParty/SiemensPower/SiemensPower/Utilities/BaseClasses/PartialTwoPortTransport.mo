within SiemensPower.Utilities.BaseClasses;
partial model PartialTwoPortTransport
  "Base class for components with two fluid ports"
  import SI = Modelica.SIunits;

  Medium.SpecificEnthalpy hIn(start=hIn_start) "actual state at portIn";
  Medium.SpecificEnthalpy hOut(start=hOut_start) "actual state at portOut";

// Medium
  replaceable package Medium = Modelica.Media.Water.WaterIF97_ph
    constrainedby Modelica.Media.Interfaces.PartialMedium
           annotation (choicesAllMatching = true);

// Initializatin parameters
 parameter Modelica.SIunits.MassFlowRate m_flow_start=1
    "Guess value for mass flow rate"                                                 annotation(Dialog(tab="Initialization"));

  parameter Medium.AbsolutePressure pIn_start = Medium.reference_p
    "Start value of inlet pressure"
    annotation(Dialog(tab = "Initialization"));
  parameter Medium.AbsolutePressure pOut_start = Medium.reference_p
    "Start value of outlet pressure"
    annotation(Dialog(tab = "Initialization"));

 parameter Boolean useTemperatureStartValue = false
    "Use T_start if true, otherwise h_start"
    annotation(Dialog(tab = "Initialization"), Evaluate=true);

  parameter Medium.SpecificEnthalpy hIn_start=
    if useTemperatureStartValue then Medium.specificEnthalpy_pTX(pIn_start, TIn_start,XIn_start) else Medium.h_default
    "Start value of specific enthalpy"
    annotation(Dialog(tab = "Initialization", enable = not useTemperatureStartValue));
  parameter Medium.SpecificEnthalpy hOut_start=
    if useTemperatureStartValue then Medium.specificEnthalpy_pTX(pOut_start, TOut_start,XOut_start) else Medium.h_default
    "Start value of specific outlet enthalpy"
    annotation(Dialog(tab = "Initialization", enable = not useTemperatureStartValue));

  parameter Medium.Temperature TIn_start=
    if useTemperatureStartValue then Medium.reference_T else Medium.temperature_phX(pIn_start,hIn_start,XIn_start)
    "Start value of temperature"
    annotation(Dialog(tab = "Initialization", enable = useTemperatureStartValue));
  parameter Medium.Temperature TOut_start=
    if useTemperatureStartValue then Medium.reference_T else Medium.temperature_phX(pOut_start,hOut_start,XOut_start)
    "Start value of  outlet temperature"
    annotation(Dialog(tab = "Initialization", enable = useTemperatureStartValue));

  parameter Medium.MassFraction XIn_start[Medium.nX] = Medium.reference_X
    "Start value of mass fractions m_i/m"
    annotation (Dialog(tab="Initialization", enable=Medium.nXi > 0));
  parameter Medium.MassFraction XOut_start[Medium.nX] = Medium.reference_X
    "Start value of mass fractions m_i/m"
    annotation (Dialog(tab="Initialization", enable=Medium.nXi > 0));

  Modelica.Fluid.Interfaces.FluidPort_a portIn(redeclare package Medium = Medium, m_flow(start=m_flow_start), h_outflow(start=hIn_start), p(start=pIn_start),Xi_outflow(start=XIn_start[1:Medium.nXi]))
    "Inlet port" annotation (Placement(transformation(extent={{-120,-20},{-80,
            20}}, rotation=0), iconTransformation(extent={{-120,-20},{-80,20}})));

  Modelica.Fluid.Interfaces.FluidPort_b portOut(redeclare package Medium = Medium, m_flow(start=-m_flow_start), h_outflow(start=hOut_start), p(start=pOut_start),Xi_outflow(start=XOut_start[1:Medium.nXi]))
    "Outlet port" annotation (Placement(transformation(extent={{120,-20},{80,20}},
          rotation=0), iconTransformation(extent={{120,-20},{80,20}})));

  SI.Pressure dp(start=pIn_start-pOut_start);

protected
  Medium.ThermodynamicState state_from_a(p(start=pIn_start), T(start=TIn_start))
    "state for medium inflowing through portIn";
  Medium.ThermodynamicState state_from_b(p(start=pOut_start), T(start=TOut_start))
    "state for medium inflowing through portOut";

equation
// medium states
  state_from_a = Medium.setState_phX(portIn.p, inStream(portIn.h_outflow), inStream(portIn.Xi_outflow));
  state_from_b = Medium.setState_phX(portOut.p, inStream(portOut.h_outflow), inStream(portOut.Xi_outflow));
  if noEvent(portIn.m_flow>=0) then
    hIn = inStream(portIn.h_outflow);
  else
    hIn = portIn.h_outflow;
  end if;
  if noEvent(portOut.m_flow>=0) then
    hOut =  inStream(portOut.h_outflow);
  else
    hOut = portOut.h_outflow;
  end if;

  dp = portIn.p - portOut.p;

  portIn.C_outflow = inStream(portOut.C_outflow);
  portOut.C_outflow = inStream(portIn.C_outflow);

  annotation (Icon(coordinateSystem(preserveAspectRatio=true,  extent={{-100,
            -100},{100,100}}), graphics),
    Documentation(info="<HTML>
<p>This base class describes the geometry and most important variables for the fluid flow without storing substance.<br>
In the derived class, the following quantities/equations have to be set:<br>
<ul>
<li> pressure loss dp (e.g. momentum balance)
<li> mass flow rate (e.g. mass balance)
<li> outflow enthalpies (e.g. energy balance)
<li>
</ul>
<p>
</HTML>

<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                               <td><a href=\"mailto:haiko.steuer@siemens.com\">Haiko Steuer</a> </td>
                        <td><a href=\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\">SCD</a> </td>
                       </tr>
                <tr>
                           <td><b>Checked by:</b>   </td>
                           <td>            </td>
                </tr>
                <tr>
                           <td><b>Protection class:</b>    </td>
                           <td>public </td>
                </tr>
           </table>
         <p><b><font style=\"font-size: 10pt; \">License, Copyright and Disclaimer</font></b> </p>
<p>
<blockquote><br/>Licensed by Siemens AG under the Siemens Modelica License 2</blockquote>
<blockquote><br/>Copyright  2007-2012 Siemens AG. All rights reserved.</blockquote>
<blockquote><br/>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Siemens Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"../Documents/SiemensModelicaLicense2.html\">Siemens Modelica License 2 </a>.</blockquote>
        </p>
</HTML>",
      revisions="<html>
<ul>
<li> Feb 2009, added by Haiko Steuer
</ul>
</HTML>"),
    Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
            100}}), graphics));
end PartialTwoPortTransport;
