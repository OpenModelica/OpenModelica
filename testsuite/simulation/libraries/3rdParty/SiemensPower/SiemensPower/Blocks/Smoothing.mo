within SiemensPower.Blocks;
model Smoothing "u is y with smooth derivative"

  Modelica.Blocks.Interfaces.RealInput u annotation (Placement(transformation(
          extent={{-100,-10},{-80,10}}, rotation=0)));
  Modelica.Blocks.Interfaces.RealOutput y annotation (Placement(transformation(
          extent={{40,-10},{60,10}}, rotation=0)));
  parameter Modelica.SIunits.Time timeDelay=0.01;

initial equation
  u=y;

equation
  der(y)=(u-y)/timeDelay;

  annotation (Diagram(graphics),
                       Icon(coordinateSystem(preserveAspectRatio=false, extent=
            {{-100,-100},{100,100}}), graphics={Rectangle(
          extent={{-80,20},{40,-20}},
          lineColor={0,0,0},
          pattern=LinePattern.None,
          fillPattern=FillPattern.VerticalCylinder,
          fillColor={0,61,121}), Text(
          extent={{-78,18},{40,-18}},
          lineColor={0,0,0},
          pattern=LinePattern.None,
          fillPattern=FillPattern.VerticalCylinder,
          fillColor={170,213,255},
          textString=
               "%name")}),
Documentation(info="<html>
<p>This block guarantees an output signal with smooth time derivative.</p>
<p>It represents a simple time delay (PT1) with time constant T </p>

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
end Smoothing;
