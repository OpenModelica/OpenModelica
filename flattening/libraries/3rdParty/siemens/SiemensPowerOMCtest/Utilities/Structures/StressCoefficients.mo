within SiemensPowerOMCtest.Utilities.Structures;
record StressCoefficients
  "Parameters for stress thermal and mechanical stress computation"
  import SI = Modelica.SIunits;
  parameter Real eta=0.3 "Poisson's ratio";
  parameter Real alpha_t=2 "stress concentration factor";
  parameter Real alpha_m=2 "tangential stress concentration factor";
  parameter Real beta(unit="1/K")=14e-6 "thermal expansion coefficient";
  parameter SI.Pressure E=180e9 "Young's modulus";
 annotation (Documentation(info="<HTML>
<p>These parameters are needed to compute the thermal and tangential stress in a wall.
They are used in the <b>SiemensPowerOMCtest.Components.Wall_with_tension</b> model.
In fact, most of the parameters are temperature dependent, such that fixed parameters can only give a rough estimation of the stress behavior.
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
           For details see <a href=\"./Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
</HTML>",
      revisions="<html>
<ul>
<li> January 2007, added by Haiko Steuer
</ul>
</HTML>"));
end StressCoefficients;
