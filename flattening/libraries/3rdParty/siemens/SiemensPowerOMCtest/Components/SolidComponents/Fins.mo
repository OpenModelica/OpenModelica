within SiemensPowerOMCtest.Components.SolidComponents;
model Fins "Outer fins of heated pipes"
  import SI = Modelica.SIunits;

  constant Real pi=Modelica.Constants.pi;

  parameter Integer numberOfNodes(min=1)=2 "Number of nodes";
  parameter SiemensPowerOMCtest.Utilities.Structures.Fins geoFins
    "Geometry of outer wall fins"   annotation (Dialog(group="Geometry"));
  parameter SiemensPowerOMCtest.Utilities.Structures.PipeGeo geoPipe
    "Geometry of tube"                                                           annotation(Dialog(group="Geometry"));
  parameter SiemensPowerOMCtest.Utilities.Structures.PropertiesMetal metal
    "Metal properties";
  parameter SI.Temperature T_start[numberOfNodes] = ones(numberOfNodes)*300
    "Temperature start values"                                                                                annotation (Dialog(tab="Initialization"));
  parameter Boolean useDynamicEquations=true
    "switch off for steady-state simulations" annotation (evaluate=true);

  Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a[numberOfNodes]
    heatportsGas(T(start=T_start)) "Outer heat port"
    annotation (Placement(transformation(extent={{-16,30},{16,58}}, rotation=0),
        iconTransformation(extent={{-16,30},{16,58}})));
  Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b[numberOfNodes]
    heatportsTube(T(start=T_start)) "Inner heat port"
    annotation (Placement(transformation(extent={{-14,-38},{16,-10}}, rotation=
            0), iconTransformation(extent={{-14,-38},{16,-10}})));

  SI.Temperature T[numberOfNodes](start=T_start) "Fin temperatures";
  SI.Volume V "Fin volume of a single tube";
  SI.Mass M "Fin mass of all tubes per node";
  SI.HeatCapacity Cp "Total fins Cp per node";

initial equation
   if (useDynamicEquations and geoFins.finned) then
      der(T) = zeros(numberOfNodes);
   end if;

equation

  // fin volume computation (see Dynaplant user manual)
  if (geoFins.finned) then
    if (geoFins.serrated) then
      V = geoPipe.L*geoFins.n*geoFins.s*geoFins.h*pi*geoPipe.d_out;
    else
      V = geoPipe.L*geoFins.n*geoFins.s*geoFins.h*pi*(geoPipe.d_out+geoFins.h);
    end if;
  else
    V = 0.0;
  end if;

  M=V*metal.rho*geoPipe.Nt/numberOfNodes;
  Cp=metal.cp*M;

  for i in 1:numberOfNodes loop
     if (useDynamicEquations and geoFins.finned) then
           Cp*der(T[i]) = heatportsTube[i].Q_flow + heatportsGas[i].Q_flow;
     else
           0.0  = heatportsTube[i].Q_flow + heatportsGas[i].Q_flow;
     end if;
  end for;

  // no heat conductivity considered, since its influence is part of heat transfer correlations
  heatportsTube.T = T;
  heatportsGas.T = T;

  annotation (Diagram(graphics), Icon(graphics={
        Text(
          extent={{-80,60},{-24,34}},
          lineColor={0,0,0},
          fillColor={128,128,128},
          fillPattern=FillPattern.Forward,
          textString="Gas"),
        Rectangle(
          extent={{-84,10},{84,-10}},
          fillColor={128,128,128},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None),
        Text(
          extent={{-82,-12},{-22,-40}},
          lineColor={0,0,0},
          fillColor={128,128,128},
          fillPattern=FillPattern.Forward,
          textString="Tube"),
        Text(
          extent={{-100,-40},{100,-80}},
          lineColor={191,95,0},
          textString="%name"),
        Rectangle(
          extent={{-84,30},{-76,10}},
          fillColor={128,128,128},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None),
        Rectangle(
          extent={{76,30},{84,10}},
          fillColor={128,128,128},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None),
        Rectangle(
          extent={{56,30},{64,10}},
          fillColor={128,128,128},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None),
        Rectangle(
          extent={{14,30},{22,10}},
          fillColor={128,128,128},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None),
        Rectangle(
          extent={{34,30},{42,10}},
          fillColor={128,128,128},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None),
        Rectangle(
          extent={{-24,30},{-16,10}},
          fillColor={128,128,128},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None),
        Rectangle(
          extent={{-4,30},{4,10}},
          fillColor={128,128,128},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None),
        Rectangle(
          extent={{-64,30},{-56,10}},
          fillColor={128,128,128},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None),
        Rectangle(
          extent={{-44,30},{-36,10}},
          fillColor={128,128,128},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None)}),
                                Documentation(info="<html>
<p> This is a model for the outer fins of heated tubes. It takes the heat capacity of the fins into account.
</p>
<p> Main task of the model is to compute the fin's volume, which is done according to the Dynaplant user manual [1]. <br>
    The fin's heat capacity Cp is then computed assuming the specific heat capacity cp of the metal record rather than the fin material.
</p>
<p> For <b>usage example</b> see SiemensPowerOMCtest.Components.FlueGasZones.FlueGasZoneSingleTube
</p>
<p>
Major model restrictions are:
                <ul>
                        <li> no heating resistance since the fin's thermal conductivity is already considered in heat transfer models.</li>
                </ul>
</p>
<p>
References
                <ul>
                        <li> [1] <a href=\"https://diagnostics-cvs2.ww007.siemens.net/archiv/Dynaplant/DYNAPLANT2/Manual/DynaplantManual.pdf\"> H. Steuer, Dynaplant 2.6.2 (revision 211) user manual</a>, chapter 2.10.6 </li>
                </ul>
</p>
<p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\"mailto:haiko.steuer@siemens.com\">Haiko Steuer</a> </td>
                        <td><a href=\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\">SCD</a> </td>
                       </tr>
                <tr>
                           <td><b>Checked by:</b>   </td>
                           <td><p> </p></td>
                       <td><p> </p></td>
                </tr>
                <tr>
                           <td><b>Protection class:</b>    </td>
                           <td>free </td>
                </tr>
                <tr>
                           <td><b>Used Dymola version:</b>    </td>
                           <td>7.4 </td>
                  </tr>
           </table>
                Copyright &copy  2011 Siemens AG. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
           For details see <a href=\"./Documents/Disclaimer.html\">disclaimer</a> <br>
</p>
</html>", revisions="<html>
<p><ul>
<li>August 2011, added by Haiko Steuer</li>
</ul></p>
</html>"));
end Fins;
