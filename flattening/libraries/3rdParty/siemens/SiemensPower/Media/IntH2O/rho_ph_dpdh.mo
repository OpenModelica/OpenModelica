within SiemensPower.Media.IntH2O;
function rho_ph_dpdh "rho, drdp and drdh as function of p and h"
  import SI = Modelica.SIunits;
  input SI.Pressure p "Pressure";
  input SI.SpecificEnthalpy h "Specific enthalpy";

  output SI.Density rho "Density";
  output Real drhodp( unit = "kg/(m3.Pa)") "partial derivative of rho wrt p";
  output Real drhodh( unit = "(kg.kg)/(m3.J)")
    "partial derivative of rho wrt h";
protected
Real p_drhodp[1]( unit = "kg/(m3.Pa)");
Real p_drhodh[1]( unit = "(kg.kg)/(m3.J)");

algorithm
  (rho,p_drhodp,p_drhodh):=drho_p_dp_p_dh(p,h);
  drhodp:=p_drhodp[1];
  drhodh:=p_drhodh[1];

protected
function drho_p_dp_p_dh
  input SI.Pressure p;
  input SI.SpecificEnthalpy h;

  output SI.Density rho;
  output Real drho_dp[1]( unit = "kg/(m3.Pa)");
  output Real drho_dh[1](  unit = "(kg.kg)/(m3.J)");

  protected
  SI.SpecificEnthalpy p_h = h;
  SI.Pressure p_p=p;

  external "C" rho= dH2O_R_ph(p_p,p_h,drho_dp,drho_dh);

  annotation(Library={"intH2O98"});
end drho_p_dp_p_dh;

annotation (
    Documentation(
 info="<HTML>
                    <p>This function returns the density as function of p and h
                  including partial derivatives. The water/steam functions are computed according to inth2o.
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
                        </html>"));

end rho_ph_dpdh;
