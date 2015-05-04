within SiemensPower.Components.SolidComponents;
model Wall "Cylindrical metal tube with variable number of wall layers Nwall"
  import SI = Modelica.SIunits;

  parameter Integer numberOfNodes(min=1)=2 "Number of nodes";
  parameter Integer numberOfWallLayers(min=1)=3 "Number of wall layers"
                                                                       annotation(choices(choice=1, choice=2, choice=3, choice=4, choice=5, choice=6));

   parameter SiemensPower.Utilities.Structures.PropertiesMetal metal
    "Wall metal properties"                                                      annotation (Dialog(enable=userdefinedmaterial, group="Material"));
  parameter Integer numberOfParallelTubes(min=1)=1 "Number of parallel tubes";
  parameter SI.Length length=1 "Tube length";
  parameter SI.Length diameterInner=0.08 "Internal diameter (single tube)";
  parameter SI.Length wallThickness=0.008 "Wall thickness";
  parameter SI.Temperature T_start[numberOfNodes] = fill(300,numberOfNodes)
    "Temperature start values for inner layer";

 // final parameter SI.HeatCapacity C_total = metal.cp*metal.rho*lengthTube*numberOfParallelTubes*Modelica.Constants.pi*wallThickness*(diameterInner+wallThickness);

  SiemensPower.Components.SolidComponents.Walllayer layer[
                                          numberOfWallLayers](
    each numberOfNodes = numberOfNodes,
    diameterInner =       if (numberOfWallLayers == 1) then diameterInner*ones(1) else
       linspace(
        diameterInner,
        diameterInner + 2*wallThickness - 2*wallThickness/numberOfWallLayers,
        numberOfWallLayers),
    each numberOfParallelTubes =    numberOfParallelTubes,
    each length =    length,
    each wallThickness =   wallThickness/numberOfWallLayers,
    each T_start = T_start,
    each metal = metal);

  Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a[numberOfNodes] port_ext
    "Outer heat port"
    annotation (Placement(transformation(extent={{-14,36},{14,62}}, rotation=0)));
  Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b[numberOfNodes] port_int
    "Inner heat port"
    annotation (Placement(transformation(extent={{-14,-58},{12,-34}}, rotation=
            0)));

equation
  connect(layer[1].port_int, port_int);
  for j in 2:numberOfWallLayers loop
     connect(layer[j-1].port_ext,layer[j].port_int);
  end for;
  connect(layer[numberOfWallLayers].port_ext, port_ext);

  annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
            -100},{100,100}}),
                      graphics),
                       Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
            -100},{100,100}}), graphics={
        Rectangle(
          extent={{-92,36},{90,-34}},
          lineColor={0,0,0},
          pattern=LinePattern.None,
          fillPattern=FillPattern.VerticalCylinder,
          fillColor={215,215,215}),
        Text(
          extent={{-86,32},{80,-26}},
          lineColor={0,0,0},
          pattern=LinePattern.None,
          fillColor={175,175,175},
          fillPattern=FillPattern.Solid,
          textString="%name"),
        Text(
          extent={{-44,-38},{-16,-50}},
          lineColor={0,0,0},
          fillColor={175,175,175},
          fillPattern=FillPattern.Solid,
          textString="int"),
        Text(
          extent={{-46,54},{-16,40}},
          lineColor={0,0,0},
          fillColor={175,175,175},
          fillPattern=FillPattern.Solid,
          textString="ext")}),
    Documentation(info="<html>
This model is based on the Walllayer model which represents a cylindrical metal tube wall with a single layer.
The parameter numberOfWallLayers says how many layers will be accounted for in that wall. The counting of layers begins at the inner side, i.e. layer[numberOfNodes] is the outside layer.
</html>
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
</HTML>", revisions="<html>
<ul>
<li> December 2006  by Haiko Steuer
</ul>
</html>"));
end Wall;
