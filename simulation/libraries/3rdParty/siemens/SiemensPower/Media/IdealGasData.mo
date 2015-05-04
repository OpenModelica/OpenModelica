within SiemensPower.Media;
package IdealGasData "Ideal gas data based on the NASA Glenn coefficients"
  extends Modelica.Icons.Library;

   constant Modelica.Media.IdealGases.Common.DataRecord FlueGasSingleComponent(
    name="Simple Flue Gas",
    MM=0.0299435,
    Hf=2263.289e3,
    H0=2000e3,
    Tlimit=2500,
    alow={0,0,3.29882, 0.00130972, -2.55024e-7, 0, 0},
    blow={0,4.256},
    ahigh={0,0,3.29882, 0.00130972, -2.55024e-7, 0, 0},
    bhigh={0,4.256},
    R=277.672);

  constant Modelica.Media.IdealGases.Common.SingleGasNasa.FluidConstants
    FlueGasSingleComponentConstants(
                       chemicalFormula =        "unknown",
                       iupacName =              "unknown",
                       structureFormula =       "unknown",
                       casRegistryNumber =      "unknown",
                       meltingPoint =            63.15,
                       normalBoilingPoint =      77.35,
                       criticalTemperature =    126.20,
                       criticalPressure =        33.98e5,
                       criticalMolarVolume =     90.10e-6,
                       acentricFactor =           0.037,
                       dipoleMoment =             0.0,
                       molarMass =              FlueGasSingleComponent.MM,
                       hasDipoleMoment =       true,
                       hasIdealGasHeatCapacity=true,
                       hasCriticalData =       true,
                       hasAcentricFactor =     true);

  constant Modelica.Media.IdealGases.Common.DataRecord
    ExhaustGasSingleComponent(
    name="Simple Exhaust Gas",
    MM=0.0284251,
    Hf=2269.175e3,
    H0=2000e3,
    Tlimit=2500,
    alow={0,0,3.2236, 0.0011013, -2.01923e-7, 0, 0},
    blow={0,4.61},
    ahigh={0,0,3.2236, 0.0011013, -2.01923e-7, 0, 0},
    bhigh={0,4.61},
    R=292.505);

  constant Modelica.Media.IdealGases.Common.SingleGasNasa.FluidConstants
    ExhaustGasSingleComponentConstants(
                       chemicalFormula =        "unknown",
                       iupacName =              "unknown",
                       structureFormula =       "unknown",
                       casRegistryNumber =      "unknown",
                       meltingPoint =            63.15,
                       normalBoilingPoint =      77.35,
                       criticalTemperature =    126.20,
                       criticalPressure =        33.98e5,
                       criticalMolarVolume =     90.10e-6,
                       acentricFactor =           0.037,
                       dipoleMoment =             0.0,
                       molarMass =              ExhaustGasSingleComponent.MM,
                       hasDipoleMoment =       true,
                       hasIdealGasHeatCapacity=true,
                       hasCriticalData =       true,
                       hasAcentricFactor =     true);

annotation (
      Documentation(
   info="<HTML>
                    <p>This package contains data for simple ideal gases<br>
                    </p>
                   </HTML>

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
           For details see <a href=\"../Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
</HTML>",
      revisions="<html>
                      <ul>
                             <li> December 2006 by Haiko Steuer
                       </ul>
                        </html>"));

end IdealGasData;
