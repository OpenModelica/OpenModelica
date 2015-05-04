within SiemensPower.Utilities.Structures;
record PropertiesMetal "Metal property parameters"
  import SI = Modelica.SIunits;

  parameter SI.SpecificHeatCapacity cp=540 "Specific heat capacity";
  parameter SI.ThermalConductivity lambda=44 "Thermal conductivity";
  parameter SI.Density rho=7850 "Mass density";

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
<li> January 2007, added by Haiko Steuer
</ul>
</HTML>"));
end PropertiesMetal;
