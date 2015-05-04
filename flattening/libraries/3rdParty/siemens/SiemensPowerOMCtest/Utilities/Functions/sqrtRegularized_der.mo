within SiemensPowerOMCtest.Utilities.Functions;
function sqrtRegularized_der "Time derivative of sqrtReg"
  extends Modelica.Icons.Function;
  input Real x;
  input Real delta=0.01 "Range of significant deviation from sqrt(x)";
  input Real dx "Derivative of x";
  output Real dy;
algorithm
  dy := dx*0.5*(x*x+2*delta*delta)/((x*x+delta*delta)^1.25);
annotation (Documentation(info="<html>
Computing the time derivative of the sqrt approximation sqrtReg
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
<li> December 2006, added to SiemensPower by Haiko Steuer
<li><i>15 Mar 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Created. </li>
</ul>
</html>"));
end sqrtRegularized_der;
