within SiemensPower.Media.IntH2O;
function T_rhoh "T(rho,h)"
  import SI = Modelica.SIunits;

  input SI.Density rho "Density";
  input SI.SpecificEnthalpy h "Specific enthalpy";

  output Real T "Temperature";

protected
SI.Density p_rho=rho;
SI.SpecificEnthalpy p_h=h;

external "C" T = H2O_T_Rh(p_rho,p_h);

 annotation (
    Documentation(
 info="<HTML>
                    <p>This function returns the temperature as function of rho and h. The water/steam functions are computed according to inth2o.
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
                              <li> December 2006 by Kilian Link
                       </ul>
                        </html>"),
           Library={"intH2O98"});
end T_rhoh;
