within SiemensPower.Media.TTSE.Utilities;
function p_rhoh_dh "drho(p,h)/dh"
  import SI = Modelica.SIunits;
    input SI.Density rho "Density";
    input SI.SpecificEnthalpy h "Specific Enthalpy";
    output Real dp_dh "Partial derivative drho/dh";

    external "C" dp_dh=TTSE_d1_p_rhoh_dh(
         rho,
          h);
    annotation (Library={"TTSEmoI", "TTSE"}, Documentation(info="<html>
<p>This function returns the partial derivative of p wrt h versus rho and h according to TTSE. </p>
</html>

<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\"mailto:\"julien.bonifay@siemens.com>Julien Bonifay</a> </td>
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
                Copyright &copy  2007 Siemens AG. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
           For details see <a href=\"../Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
</HTML>",
      revisions="<html>
<ul>
<li> May 2011 by Julien Bonifay
</ul>
</html>"));

end p_rhoh_dh;
