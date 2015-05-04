within SiemensPower.Media;
package IntH2O "Water/steam table functions according to intH2O"
annotation(Documentation(
 info="<HTML>
                    <p>Water-steam table functions from inth2o
                    </p>
<b>Important note:</b>
                    From the IntH2O/library folder
                    <ul>
                      <li> the library file inth2O98.lib has to be copied to C:/Dymola/work
                            (if you want to chose another location, you have to modify the corresponding library-annotations in the models)
                      <li> the header file inth2O.h has to be present in your working directory.
</ul>

<p>
<b>For information only:</b> The following inth2o functions are called:
<ul>
<li>double  H2O_p_Rh (double*,double*);
<li>double dH2O_p_Rh (double*,double*,double*,double*);
<li>double  H2O_T_Rh (double*,double*);
<li>double dH2O_T_Rh (double*,double*,double*,double*);
<li>double  H2O_R_ph (double*,double*);
<li>double dH2O_R_ph (double*,double*,double*,double*);
</ul>

                   </HTML>

<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td> <td><a href=\"mailto:haiko.steuer@siemens.com\">Haiko Steuer</a> </td>
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
end IntH2O;
