within SiemensPower.Components.Junctions;
model SplitterMixer "Splitter/mixer with N ports"

  import SI = SiemensPower.Units;
  //replaceable package Medium = Modelica.Media.Water.WaterIF97_ph constrainedby
  //  Modelica.Media.Interfaces.PartialMedium "Medium in the component"  annotation (
  //    choicesAllMatching =      true);

  parameter Integer numberOfPortsSplit(min=1)=2
    "Number of inlets(mixer) / outlets(splitter)";

  parameter SI.AbsolutePressure p_start=1e5 "Pressure"
                                               annotation(Dialog(tab="Initialization"));
  parameter Boolean useTemperatureStartValue=false
    "Use temperature instead of specific enthalpy"                                   annotation(Dialog(tab="Initialization"));
  // parameter Medium.SpecificEnthalpy h_start=if useTemperatureStartValue then Medium.specificEnthalpy_pTX(p_start, T_start, Medium.reference_X) else 300e3
 parameter SI.SpecificEnthalpy h_start = 300e3 "Specific enthalpy"
  annotation(Dialog(tab="Initialization", enable= not useTemperatureStartValue));
 // parameter Medium.Temperature T_start=
 //     if useTemperatureStartValue then 300 else Medium.temperature_phX(p_start,h_start,Medium.reference_X)
   parameter SI.Temperature T_start=300 "Guess value of temperature"
   annotation(Dialog(tab = "Initialization", enable = useTemperatureStartValue));
  //parameter SI.MassFraction X_start[Medium.nX] = Medium.reference_X
  //  "Start value of mass fractions m_i/m"
  //  annotation (Dialog(tab="Initialization", enable=Medium.nXi > 0));

  parameter SI.MassFlowRate m_flow_start=1
    "Mass flow rate trough outlet(mixer, negative!) / inlet(splitter)"                                   annotation(Dialog(tab="Initialization"));
  parameter SI.MassFlowRate[numberOfPortsSplit] m_flowOpposite_start = -ones(numberOfPortsSplit)*m_flow_start/numberOfPortsSplit
    "Mass flow rate trough inlets(mixer) / outlets(splitter, negative!)"                                   annotation(Dialog(tab="Initialization"));

  parameter Boolean initializeSteadyMassBalance=true "ma=sum(mb)" annotation(Dialog(tab="Initialization",group="Initial equations in case of volume > 0", enable=hasVolume));
  parameter Boolean initializeSteadyEnthalpyBalance=true
    "der(h)=0, may be too much in case of mixer"
                 annotation(Dialog(tab="Initialization",group="Initial equations in case of volume > 0", enable=hasVolume));
  parameter Boolean initializeFixedPressure=false "p=p_start" annotation(Dialog(tab="Initialization",group="Initial equations in case of volume > 0", enable=hasVolume));
  parameter Boolean initializeFixedEnthalpy=false "h=h_start" annotation(Dialog(tab="Initialization",group="Initial equations in case of volume > 0", enable=hasVolume));

  parameter Boolean hasVolume=false annotation(evaluate=true, Dialog(group="Volume"));
  parameter SI.Volume V=0.1 annotation(Dialog(group="Volume", enable=hasVolume));
  parameter Boolean hasPressureDrop=false
    "may be necessary in case of a splitter"                                         annotation(evaluate=true, Dialog(group="Pressure loss"));
  parameter Modelica.Fluid.Types.HydraulicResistance resistanceHydraulic=2
    "Hydraulic resistance" annotation(Dialog(group="Pressure loss", enable=hasPressureDrop));

  SI.SpecificEnthalpy h( start = h_start);
  SI.Pressure p( start = p_start);
  SI.Density d;

  SiemensPower.Interfaces.FluidPort_a portMix(
    m_flow(start=m_flow_start),
    p(start=p_start),
    h_outflow(start=h_start)) "inlet(splitter) / outlet(mixer)"                                              annotation (Placement(
        transformation(extent={{-10,-100},{10,-80}}, rotation=0)));
  //  redeclare package Medium = Medium,

  SiemensPower.Interfaces.FluidPorts_b portsSplit[numberOfPortsSplit](
    m_flow(start=m_flowOpposite_start),
    each p(start=p_start),
    each h_outflow(start=h_start)) "outlets(splitter) / inlets(mixer)"
    annotation (Placement(transformation(extent={{-8,16},{12,96}}),
        iconTransformation(
        extent={{-10,-40},{10,40}},
        rotation=90,
        origin={0,90})));
  //  redeclare package Medium = Medium,

//  Medium.BaseProperties medium(h(start=h_start), p(start=p_start), X(start=X_start));

  SI.MassFlowRate m_flowFromPortMix;
  SI.MassFlowRate m_flowFromPortsSplit[ numberOfPortsSplit];

initial equation

if hasVolume then
   if (initializeSteadyEnthalpyBalance) then
     der(h) = 0;
   end if;
   if  initializeSteadyMassBalance then
      portMix.m_flow   + sum(portsSplit[i].m_flow   for i in 1:numberOfPortsSplit) = 0;
   end if;
   if (initializeFixedPressure) then
      p = p_start;
   end if;
   if (initializeFixedEnthalpy) then
      h = h_start;
   end if;
end if;

equation

  d = SiemensPower.Media.TTSE.Utilities.rho_ph(p, h);
  if hasVolume then
    portMix.m_flow   + sum(portsSplit[i].m_flow   for i in 1:numberOfPortsSplit) = V*der(d);
  else
    portMix.m_flow   + sum(portsSplit[i].m_flow   for i in 1:numberOfPortsSplit) = 0;
  end if;

  if hasVolume then
     m_flowFromPortMix*(inStream(portMix.h_outflow)- h)  + sum(m_flowFromPortsSplit [i]*(inStream(portsSplit[i].h_outflow)- h)   for i in 1:numberOfPortsSplit) = V*d*der(h);
  else
     m_flowFromPortMix*(inStream(portMix.h_outflow)- h)   + sum(m_flowFromPortsSplit [i]*(inStream(portsSplit[i].h_outflow)- h)   for i in 1:numberOfPortsSplit) = 0;
  end if;

//  if hasVolume then
//     m_flowFromPortMix*(inStream(portMix.Xi_outflow)-medium.Xi) + sum(m_flowFromPortsSplit [i]*(inStream(portsSplit[i].Xi_outflow)-medium.Xi) for i in 1:numberOfPortsSplit) = V*d*der(medium.Xi);
//  else
//     m_flowFromPortMix*(inStream(portMix.Xi_outflow)-medium.Xi) + sum(m_flowFromPortsSplit [i]*(inStream(portsSplit[i].Xi_outflow)-medium.Xi) for i in 1:numberOfPortsSplit) = zeros(Medium.nXi);
//  end if;

  portMix.p = p;
  portMix.h_outflow   = h;
//  portMix.Xi_outflow = medium.Xi;

  m_flowFromPortMix=max(0,portMix.m_flow);

  for i in 1:numberOfPortsSplit loop
      if (hasPressureDrop) then
          portsSplit[i].p - p =resistanceHydraulic*portsSplit[i].m_flow;
      else
          portsSplit[i].p = p;
      end if;
      portsSplit[i].h_outflow = h;
    //  portsSplit[i].Xi_outflow = medium.Xi;
      m_flowFromPortsSplit [i]=max(0,portsSplit[i].m_flow);
  end for;

  annotation (Documentation(
 info="<HTML>
This splitter/mixer hasa variable number N of ports. It can be an ideal splitter/mixer (hasVolume=false and hasPressureDrop=false)
or can be modeled with a volume and/or pressure losses in the N outlets/inlets.
<p>
In case of using this component as a mixer you must use the portsSplit[numberOfPortsSplit] as inlets and portMix as the outlet.
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
           <td>free </td>
        </tr>
        <tr>
           <td><b>Used Dymola version:</b>    </td>
           <td>6.1 </td>
        </tr>

        </table>
     Copyright &copy  2007 Siemens AG, PG EIP12 , All rights reserved.<br>
 <br>   This model is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY. For details <a href=\"../Documents/Disclaimer.html\">see</a> <br>
</HTML>",
    revisions="<html>
                      <ul>
                              <li> Feb 2009 adapted for stream connector by Haiko Steuer
                              <li> November 2007, generalized for other media
                              <li> June 2007 by Haiko Steuer (for water/steam)
                       </ul>
                        </html>"),
    Diagram(coordinateSystem(preserveAspectRatio=true,  extent={{-100,-100},{100,
            100}}),     graphics),
    Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
            100}}), graphics={Polygon(
          points={{-20,-80},{20,-80},{20,-20},{76,-20},{76,80},{46,80},{46,20},
              {16,20},{16,80},{-16,80},{-16,20},{-44,20},{-44,80},{-76,80},{-76,
              -20},{-20,-20},{-20,-80}},
          smooth=Smooth.None,
          pattern=LinePattern.None,
          lineColor={0,0,0},
          fillColor={0,128,255},
          fillPattern=FillPattern.Solid)}));
end SplitterMixer;
