within SiemensPower.Utilities.HeatTransfer;
model HeatTransfer_constAlpha
  extends SiemensPower.Utilities.HeatTransfer.HeatTransferBaseClass;

   parameter Real heatingSurfaceFactor_set= 1.0 "factor for A_h";

equation
 alpha = alpha_start*ones(numberOfNodes);
 heatingSurfaceFactor = heatingSurfaceFactor_set;
 Psi = 1.0;
  annotation(Documentation(info="<html>
Simple heat transfer correlation with constant heat transfer coefficient, used as default component in <a distributed pipe models.
</html><HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\"mailto:kilian.link@siemens.com\">Kilian Link</a> </td>
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
</HTML>"));
end HeatTransfer_constAlpha;
