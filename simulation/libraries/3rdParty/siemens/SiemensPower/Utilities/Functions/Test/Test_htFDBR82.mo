within SiemensPower.Utilities.Functions.Test;
model Test_htFDBR82
  "Comparison of FlueGas and FlueGasSingleComponent as well as cp functions"
  import SI = Modelica.SIunits;
  extends Modelica.Icons.Example;
  package Gas =SiemensPower.Media.FlueGas "Flue gas with 6 components";

  parameter Gas.AbsolutePressure p = 1e5 "Gas pressure";
 // parameter Gas.SpecificEnthalpy hInitial = 200e3 "Begin of t range";
 // parameter Gas.SpecificEnthalpy hFinal = 1000e3 "End of t range";
  parameter SI.Time period=100 "time for t-range";

  parameter Gas.Temperature TInitial = 273.15 "Begin of t range";
  parameter Gas.Temperature TFinal = 1773.15 "End of t range";

  SiemensPower.Units.SpecificEnthalpy hT_FDBR82;
  SiemensPower.Units.Temperature T;
  SiemensPower.Units.SpecificEnthalpy hMedia;
  Real cp_FDBR82;
  SiemensPower.Units.SpecificEnthalpy h_cp;

equation
 // flueGas.p = p;
  T = TInitial + (TFinal-TInitial)*time/period;

 // flueGas.Xi=Gas.reference_X;

  // 6 components gas computations
 // rhoNASA = flueGas.d;
 // cpNASA = Gas.specificHeatCapacityCp(flueGas.state);

  // other heat capacity computations for comparison
 // cpFDBR82 = SiemensPower.Utilities.Functions.cp_FDBR82(flueGas.T);
  hMedia = SiemensPower.Media.FlueGas.h_TX(T, {0.0122996, 0.0579690, 0.0532280, 0.7349500, 0.1415570, 0.000});
                          //   substanceNames={"Argon","Carbone dioxide","Water","Nitrogen","Oxygen","Sulphur dioxide"},
                          //   reference_X={0.011677, 0.214410, 0.040151, 0.696555, 0.035638, 0.001569});
 // hCp = flueGas.T * cpFDBR82;
  //hT_FDBR82 = hInitial + (hFinal-hInitial)*time/period;
 /*
 input Real XGas[6]={0.0579690,0.0,0.7349500,0.0532280,0.1415570,0.0122996}
    "Gas composition: CO2, SO2, N2, H2O, O2, Ar [kg/kg]";
 */
  cp_FDBR82 = SiemensPower.Utilities.Functions.cp_FDBR82(T);
  h_cp = cp_FDBR82*T;
  hT_FDBR82 = SiemensPower.Utilities.Functions.hT_FDBR82(T);
  //hT_FDBR82 = SiemensPower.Utilities.Functions.hT_FDBR82(T);
annotation (
    Documentation(
 info="<HTML>
                    <p>This test compares some results of FlueGas functions with the FlueGasSingleComponent results<br>
                       In addition, the specific heat capacities according to
                      <ul>
                             <li> FDBR82 (Krawal modular, Dynaplant II)
                             <li> NASA (Modelica's IdealGasMixtures, e.g. FlueGas)
                             <li> FDBRold (DynaplantOld, SIMIT routine)
                       </ul>

                      are compared.
                    </p><p>
                   Note that the enthalpy offset in FlueGasSingleComponent is such that T=0 degC at h=0.
                  <br> The specific heat capacities from NASA and FDBR82 differs less then 0.1 per cent for typical flue gases.</p>
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
           </table>
                Copyright &copy  2007 Siemens AG, PG EIP12. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
           For details see <a href=\"../Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
</HTML>",
    revisions="<html>
<p><ul>
<li>May 2011, FDBR acc. Defos added to test</li>
<li>December 2006 by Haiko Steuer </li>
</ul></p>
</html>"),                         experiment(StopTime=100),
    Commands(file="Scripts/tests/FlueGas_test.mos" "FlueGas_test"));
end Test_htFDBR82;
