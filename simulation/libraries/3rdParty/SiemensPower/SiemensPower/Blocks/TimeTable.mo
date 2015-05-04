within SiemensPower.Blocks;
model TimeTable
  "Time table with signal, which has a continous derivative (if desired)"
extends Modelica.Blocks.Interfaces.SO;
    parameter Real table[:, 2]=[0, 0; 1, 1; 2, 4]
    "Table matrix (time = first column)";
  parameter Modelica.SIunits.Time timeDelay=0.01 "Delay time";
  Modelica.Blocks.Sources.TimeTable originalTable(table=table)
    annotation (Placement(transformation(extent={{-32,-10},{-12,10}}, rotation=
            0)));
  SiemensPower.Blocks.Smoothing C1signal(timeDelay=timeDelay)
                       annotation (Placement(transformation(extent={{22,-10},{
            42,10}}, rotation=0)));
  Modelica.Blocks.Interfaces.RealOutput yOriginal
    "original time table function"
    annotation (Placement(transformation(extent={{100,-92},{120,-72}}, rotation=
           0)));
equation
   connect(originalTable.y, C1signal.u)
    annotation (Line(points={{-11,0},{23,0}}, color={0,0,127}));
  connect(C1signal.y, y)
    annotation (Line(points={{37,0},{110,0}}, color={0,0,127}));
  connect(originalTable.y, yOriginal) annotation (Line(points={{-11,0},{4,0},{4,
          -82},{110,-82}}, color={0,0,127}));

annotation (Diagram(graphics),
                     Icon(graphics={
        Line(points={{-70,-50},{-70,70},{30,70},{30,-50},{-70,-50},{-70,-20},{
              30,-20},{30,10},{-70,10},{-70,40},{30,40},{30,70},{-20,70},{-20,-51}},
            color={0,0,0}),
        Line(points={{-81,82},{-81,-66}}, color={192,192,192}),
        Line(points={{-83,-62},{39,-62}}, color={192,192,192}),
        Polygon(
          points={{58,-62},{36,-54},{36,-70},{58,-62}},
          lineColor={192,192,192},
          fillColor={192,192,192},
          fillPattern=FillPattern.Solid),
        Polygon(
          points={{-80,96},{-88,74},{-72,74},{-80,96}},
          lineColor={192,192,192},
          fillColor={192,192,192},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{30,18},{98,-14}},
          lineColor={0,0,255},
          textString="delayed"),
        Text(
          extent={{20,-66},{88,-98}},
          lineColor={0,0,255},
          textString="original")}),
Documentation(info="<html>
<p>This is a block giving signals with continous derivative from a time table.</p><p>The original time table function is delayed in time with time constant Tdel, which should be small compared to typical time scales of the table.</p><p>The second output gives the original time table signal in case you dont want any delay. </p>

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
                           <td>public</td>
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
<li> December 2006, added by Haiko Steuer
</ul>
</html>"));
end TimeTable;
