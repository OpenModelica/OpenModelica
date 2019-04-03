within SiemensPower.Utilities.Structures;
record PropertiesMetal "Metal property parameters"
  import SI = Modelica.SIunits;

  parameter SI.SpecificHeatCapacity cp=540 "Specific heat capacity";
  parameter SI.ThermalConductivity lambda=44 "Thermal conductivity";
  parameter SI.Density rho=7850 "Mass density";

  //parameters for Tension calculation
  parameter Real Rm = 600 "Tension strength [MPa]"
                                                  annotation (Dialog(group="For tension calculation only"));
  parameter Real Rp02 = 440 "Elastic limit [MPa]"
                                                 annotation (Dialog(group="For tension calculation only"));

 annotation (Documentation(info="<HTML>
<p>These parameters are needed to specify the medium properties of a metal, e.g. in a tube' wall.
   Here, the properties are fixed, i.e. they do <b>not</b> depend on the metal temperature.
  Note that for the wall aggregate, just the <b>product</b> of rho and cp (i.e. the heat capacity per volume) will enter the physics.
</HTML><HTML>
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
<li> January 2007, added by Haiko Steuer
</ul>
</HTML>"));
end PropertiesMetal;
