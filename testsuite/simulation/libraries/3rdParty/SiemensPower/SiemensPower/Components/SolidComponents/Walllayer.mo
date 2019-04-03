within SiemensPower.Components.SolidComponents;
model Walllayer "Cylindrical metal tube (single layer)"
  import SI = Modelica.SIunits;

  constant Real pi=Modelica.Constants.pi;
  parameter Integer numberOfNodes(min=1)=2 "Number of nodes";
  parameter Boolean assumePlainHeatTransfer=false "no logarithmic correction"
                                annotation (Dialog(enable=considerConductivity));
  parameter SiemensPower.Utilities.Structures.PropertiesMetal metal
    "Wall metal properties"                                                      annotation (Dialog(enable=userdefinedmaterial, group="Material"));
  parameter Integer numberOfParallelTubes(min=1)=1 "Number of parallel tubes";
  parameter SI.Length length=1 "Tube length";
  parameter SI.Length diameterInner=0.08 "Internal diameter (single tube)";
  parameter SI.Length wallThickness=0.008 "Wall thickness";
  parameter Boolean useDynamicEquations=true
    "switch off for steady-state simulations" annotation (evaluate=true);

  parameter Boolean considerConductivity=true
    "Wall conduction resistance accounted for"                                           annotation (Evaluate=true);
  parameter Boolean considerAxialHeatTransfer=false
    "With heat transfer in the wall parallel to the flow direction"
          annotation (Evaluate=true, Dialog(enable=considerConductivity));
  parameter String initOpt="steadyState" "Initialisation option" annotation (Dialog(group="Initialization"),
  choices(
    choice="noInit" "No initial equations",
    choice="steadyState" "Steady-state initialization",
    choice="fixedTemperature" "Fixed-temperatures initialization"));

  parameter SI.Temperature T_start[numberOfNodes] "Temperature start values"       annotation (Dialog(group="Initialization"));

  Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a[numberOfNodes] port_ext(T(start = T_start))
    "Outer heat port"
    annotation (Placement(transformation(extent={{-16,20},{16,48}}, rotation=0)));                                                          //(T(start = linspace(Tstart1,TstartN,numberOfNodes)))
  Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b[numberOfNodes] port_int(T(start = T_start))
    "Inner heat port"
    annotation (Placement(transformation(extent={{-14,-48},{16,-20}}, rotation=
            0)));

  SI.Area Am "Area of the metal tube cross-section";
  SI.Temperature T[numberOfNodes](start=T_start) "Node temperatures";
  SI.Length rint;
  SI.Length rext;
  SI.Mass Tube_mass;
  SI.HeatCapacity HeatCap "HeatCapacity of a Tube part";

initial equation

    der(T) = zeros(numberOfNodes);

equation
  rint=diameterInner*0.5;
  rext=diameterInner*0.5+wallThickness;

 Tube_mass=(metal.rho*Am*length/numberOfNodes)* numberOfParallelTubes;
 HeatCap=metal.cp*Tube_mass;

  //  Energy balance
  for i in 1:numberOfNodes loop
     HeatCap*der(T[i]) = port_int[i].Q_flow + port_ext[i].Q_flow;
     port_int[i].Q_flow = metal.lambda*2*pi*length/numberOfNodes*numberOfParallelTubes*(port_int[i].T-T[i])*2/(rext/rint-1);
     port_ext[i].Q_flow = metal.lambda*2*pi*length/numberOfNodes*numberOfParallelTubes*(port_ext[i].T -T[i])*2/(1-rint/rext);
  end for;

  Am = (rext^2-rint^2)*pi "Area of the metal cross section of single tube";

  annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
            -100},{100,100}}), graphics={
        Rectangle(
          extent={{-80,20},{80,-20}},
          lineColor={0,0,0},
          fillColor={128,128,128},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{-84,-22},{-32,-50}},
          lineColor={0,0,0},
          fillColor={128,128,128},
          fillPattern=FillPattern.Forward,
          textString="Int"),
        Text(
          extent={{-82,50},{-34,24}},
          lineColor={0,0,0},
          fillColor={128,128,128},
          fillPattern=FillPattern.Forward,
          textString="Ext"),
        Text(
          extent={{-100,-60},{100,-88}},
          lineColor={191,95,0},
          textString="%name")}),
                           Documentation(info="<HTML>
<p>This is the model of a cylindrical tube layer of solid material.
<p>The heat capacity (which is lumped at the center of the tube thickness) is accounted for, as well as the thermal resistance due to the finite heat conduction coefficient. Longitudinal heat conduction is neglected.
<p><b>Modelling options</b></p>
<p>The following options are available to specify the valve flow coefficient in fully open conditions:
<ul>
<li><tt>considerConductivity = false</tt>: the thermal resistance of the tube wall is neglected.
<li><tt>considerConductivity = true</tt>: the thermal resistance of the tube wall is accounted for.
</ul>
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
                           <td>internal </td>
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
<li> December 2006, adapted to SiemensPower by Haiko Steuer
<li><i>30 May 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Initialisation support added.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>
"));
end Walllayer;
