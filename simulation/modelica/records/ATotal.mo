package Modelica "Modelica Standard Library - Version 3.2.1 (Build 2)"
  extends Modelica.Icons.Package;
  package Electrical "Library of electrical models (analog, digital, machines, multi-phase)"
    extends Modelica.Icons.Package;
    package Spice3 "Library for components of the Berkeley SPICE3 simulator"
      import SI = Modelica.SIunits;
      extends Modelica.Icons.Package;
      package Types "Additional Spice3 type definitions"
        extends Modelica.Icons.TypesPackage;
        type VoltageSquare = Real(final quantity = "ElectricalPotential2", final unit = "V2");
        type GapEnergyPerTemperature = Real(final quantity = "Energy per Temperature", final unit = "eV/K");
        type PerVolume = Real(final quantity = "PerVolume", final unit = "1/m3");
        annotation(Documentation(info = "<html>
<p>This package Types contains units that are needed in the models of the Spice3 package.</p>
</html>"));
      end Types;
      package Internal "Collection of functions and records derived from the C++ Spice library"
        extends Modelica.Icons.InternalPackage;
        record ModelcardMOS "Record with technological parameters (.model)"
          extends Modelica.Icons.Record;
          parameter SI.Voltage VTO = -1e+40 "Zero-bias threshold voltage, default 0";
          parameter SI.Transconductance KP = -1e+40 "Transconductance parameter, default 2e-5";
          parameter Real GAMMA = -1e+40 "Bulk threshold parameter, default 0";
          parameter SI.Voltage PHI = -1e+40 "Surface potential, default 0.6";
          //Substrate Sperrschicht Potential
          parameter SI.InversePotential LAMBDA = 0 "Channel-length modulation, default 0";
          parameter SI.Resistance RD = -1e+40 "Drain ohmic resistance, default 0";
          parameter SI.Resistance RS = -1e+40 "Source ohmic resistance, default 0";
          parameter SI.Capacitance CBD = -1e+40 "Zero-bias B-D junction capacitance, default 0";
          parameter SI.Capacitance CBS = -1e+40 "Zero-bias B-S junction capacitance, default 0";
          parameter SI.Current IS = 1e-14 "Bulk junction saturation current";
          parameter SI.Voltage PB = 0.8 "Bulk junction potential";
          parameter SI.Permittivity CGSO = 0.0 "Gate-source overlap capacitance per meter channel width";
          parameter SI.Permittivity CGDO = 0.0 "Gate-drain overlap capacitance per meter channel width";
          parameter SI.Permittivity CGBO = 0.0 "Gate-bulk overlap capacitance per meter channel width";
          parameter SI.Resistance RSH = 0.0 "Drain and source diffusion sheet resistance";
          parameter SI.CapacitancePerArea CJ = 0.0 "Zero-bias bulk junction bottom cap. per sq-meter of junction area";
          parameter Real MJ = 0.5 "Bulk junction bottom grading coefficient";
          parameter SI.Permittivity CJSW = 0.0 "Zero-bias junction sidewall cap. per meter of junction perimeter";
          parameter Real MJSW = 0.5 "Bulk junction sidewall grading coefficient";
          parameter SI.CurrentDensity JS = 0.0 "Bulk junction saturation current per sq-meter of junction area";
          parameter SI.Length TOX = -1e+40 "Oxide thickness, default 1e-7";
          parameter Real NSUB = -1e+40 "Substrate doping, default 0";
          parameter SI.Conversions.NonSIunits.PerArea_cm NSS = 0.0 "Surface state density";
          parameter Real TPG = 1.0 "Type of gate material: +1 opp. to substrate, -1 same as substrate, 0 Al gate";
          parameter SI.Length LD = 0.0 "Lateral diffusion";
          parameter SI.Conversions.NonSIunits.Area_cmPerVoltageSecond UO = 600 "Surface mobility";
          parameter Real KF = 0 "Flicker noise coefficient";
          parameter Real AF = 1.0 "Flicker noise exponent";
          parameter Real FC = 0.5 "Coefficient for forward-bias depletion capacitance formula";
          parameter SI.Temp_C TNOM = 27 "Parameter measurement temperature, default 27";
          constant Integer LEVEL = 1 "Model level: Shichman-Hodges";
          annotation(Documentation(info = "<html>
<p>Modelcard parameters for MOSFET model, both N and P channel, LEVEL 1: Shichman-Hodges</p>
<p>The package Repository is not for user access. There all function, records and data are stored, that are needed for the semiconductor models of the package Semiconductors.</p>
</html>"));
        end ModelcardMOS;
        record SpiceConstants "General constants of SPICE simulator"
          extends Modelica.Icons.Record;
          constant Real EPSSIL = 11.7 * 8.854214871e-12;
          constant Real EPSOX = 3.453133e-11;
          constant SI.Charge CHARGE = 1.6021918e-19;
          constant SI.Temp_K CONSTCtoK = 273.15;
          constant SI.HeatCapacity CONSTboltz = 1.3806226e-23;
          // J/K
          constant SI.Temp_K REFTEMP = 300.15;
          /* 27 deg C */
          constant Real CONSTroot2 = sqrt(2.0);
          constant Real CONSTvt0(final unit = "(J/K)/(A.s)") = Modelica.Constants.k * Modelica.SIunits.Conversions.from_degC(27) / CHARGE;
          // deg C
          constant Real CONSTKoverQ(final unit = "(J/K)/(A.s)") = Modelica.Constants.k / CHARGE;
          constant Real CONSTe = exp(1.0);
          // options
          constant SI.Conductance CKTgmin = 1e-12;
          constant SI.Temp_K CKTnomTemp = 300.15;
          constant SI.Temp_K CKTtemp = 300.15;
          constant SI.Area CKTdefaultMosAD = 0.0;
          constant SI.Area CKTdefaultMosAS = 0.0;
          constant SI.Length CKTdefaultMosL = 0.0001;
          constant SI.Length CKTdefaultMosW = 0.0001;
          constant Real CKTreltol = 1e-10;
          constant Real CKTabstol = 1e-15;
          constant Real CKTvolttol = 1e-10;
          constant Real CKTtemptol = 0.001;
          annotation(Documentation(info = "<html>
<p>General constants used by SPICE</p>
<p>The package Internal is not for user access. There all function, records and data are stored, that are needed for the semiconductor models of the package Semiconductors.</p>
</html>"));
        end SpiceConstants;
        record MaterialParameters
          extends Modelica.Icons.Record;
          // energy gap for silicon
          constant SI.GapEnergy EnergyGapSi = 1.16;
          // first band correction factor of silicon
          constant Types.GapEnergyPerTemperature FirstBandCorrFactorSi = 0.000702;
          // second band correction factor of silicon
          constant SI.Temperature SecondBandCorrFactorSi = 1108;
          // band correction factor for T = 300K
          constant SI.GapEnergy BandCorrFactorT300 = 1.1150877;
          // intrinsic conduction carrier density
          constant Types.PerVolume IntCondCarrDensity = 1.45e+16;
          annotation(Documentation(info = "<html>
<p>Definition of Material parameters</p>
<p>The package Repository is not for user access. There all function, records and data are stored, that are needed for the semiconductor models of the package Semiconductors.</p>
</html>"));
        end MaterialParameters;
        package Functions "Equations for semiconductor calculation"
          extends Modelica.Icons.InternalPackage;
          function junctionPotDepTemp "Temperature dependency of junction potential"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Voltage phi0;
            input Modelica.SIunits.Temp_K temp "Device Temperature";
            input Modelica.SIunits.Temp_K tnom "Nominal Temperature";
            output Modelica.SIunits.Voltage ret "Output voltage";
          protected
            Modelica.SIunits.Voltage phibtemp;
            Modelica.SIunits.Voltage phibtnom;
            Modelica.SIunits.Voltage vt;
          algorithm
            phibtemp:=Modelica.Electrical.Spice3.Internal.Functions.energyGapDepTemp(temp);
            phibtnom:=Modelica.Electrical.Spice3.Internal.Functions.energyGapDepTemp(tnom);
            vt:=Spice3.Internal.SpiceConstants.CONSTKoverQ * temp;
            ret:=(phi0 - phibtnom) * temp / tnom + phibtemp + vt * 3 * Modelica.Math.log(tnom / temp);
            annotation(Documentation(info = "<html>
<p>This internal function calculates the temperature dependent junction potential based on the actual and the nominal temperature.</p>
</html>"));
          end junctionPotDepTemp;
          function saturationCurDepTempSPICE3MOSFET "Temperature dependency of saturation current"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Current satcur0 "Saturation current";
            input Modelica.SIunits.Temp_K temp "Device Temperature";
            input Modelica.SIunits.Temp_K tnom "Nominal Temperature";
            output Real ret "Output current";
            //unit Current
          protected
            Modelica.SIunits.Voltage vt;
            Modelica.SIunits.Voltage vtnom;
            Modelica.SIunits.Voltage energygaptnom;
            Modelica.SIunits.Voltage energygaptemp;
          algorithm
            vt:=Spice3.Internal.SpiceConstants.CONSTKoverQ * temp;
            vtnom:=Spice3.Internal.SpiceConstants.CONSTKoverQ * tnom;
            energygaptnom:=Modelica.Electrical.Spice3.Internal.Functions.energyGapDepTemp(tnom);
            energygaptemp:=Modelica.Electrical.Spice3.Internal.Functions.energyGapDepTemp(temp);
            ret:=satcur0 * exp(energygaptnom / vtnom - energygaptemp / vt);
            annotation(Documentation(info = "<html>
<p>This internal function calculates the temperature dependent saturation current based on the actual and the nominal temperature.</p>
</html>"));
          end saturationCurDepTempSPICE3MOSFET;
          function junctionVCrit "Voltage limitation"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Temp_K temp "temperature";
            input Real ncoeff;
            input Modelica.SIunits.Current satcur "Saturation current";
            output Real ret "Output value";
          protected
            Modelica.SIunits.Voltage vte;
          algorithm
            vte:=Spice3.Internal.SpiceConstants.CONSTKoverQ * temp * ncoeff;
            ret:=vte * Modelica.Math.log(vte / (sqrt(2) * satcur));
            ret:=if ret > 10000000000.0 then 10000000000.0 else ret;
            annotation(Documentation(info = "<html>
<p>This internal function limits the junction voltage. If it increases 1.e10, it is hold to be constant at that value.</p>
</html>"));
          end junctionVCrit;
          function junctionParamDepTempSPICE3 "Temperature dependency of junction parameters"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Voltage phi0;
            input Real cap0;
            input Real mcoeff;
            input Modelica.SIunits.Temp_K temp "Device temperature";
            input Modelica.SIunits.Temp_K tnom "Nominal temperature";
            output Modelica.SIunits.Voltage junctionpot "Junction potential";
            output Real jucntioncap "Junction capacitance";
          protected
            Modelica.SIunits.Voltage phibtemp;
            Modelica.SIunits.Voltage phibtnom;
            Modelica.SIunits.Voltage vt;
            Modelica.SIunits.Voltage vtnom;
            Real arg;
            Real fact2;
            Real pbfact;
            Real arg1;
            Real fact1;
            Real pbfact1;
            Real pbo;
            Real gmaold;
            Real gmanew;
          algorithm
            phibtemp:=Modelica.Electrical.Spice3.Internal.Functions.energyGapDepTemp(temp);
            phibtnom:=Modelica.Electrical.Spice3.Internal.Functions.energyGapDepTemp(tnom);
            vt:=Spice3.Internal.SpiceConstants.CONSTKoverQ * temp;
            vtnom:=Spice3.Internal.SpiceConstants.CONSTKoverQ * tnom;
            arg:=-phibtemp / (2 * Modelica.Constants.k * temp) + 1.1150877 / (Modelica.Constants.k * 2 * Spice3.Internal.SpiceConstants.REFTEMP);
            fact2:=temp / Spice3.Internal.SpiceConstants.REFTEMP;
            pbfact:=-2 * vt * (1.5 * Modelica.Math.log(fact2) + Spice3.Internal.SpiceConstants.CHARGE * arg);
            arg1:=-phibtnom / (Modelica.Constants.k * 2 * tnom) + 1.1150877 / (2 * Modelica.Constants.k * Spice3.Internal.SpiceConstants.REFTEMP);
            fact1:=tnom / Spice3.Internal.SpiceConstants.REFTEMP;
            pbfact1:=-2 * vtnom * (1.5 * Modelica.Math.log(fact1) + Spice3.Internal.SpiceConstants.CHARGE * arg1);
            pbo:=(phi0 - pbfact1) / fact1;
            junctionpot:=pbfact + fact2 * pbo;
            gmaold:=(phi0 - pbo) / pbo;
            gmanew:=(junctionpot - pbo) / pbo;
            jucntioncap:=cap0 / (1 + mcoeff * (0.0004 * (tnom - Spice3.Internal.SpiceConstants.REFTEMP) - gmaold)) * (1 + mcoeff * (0.0004 * (temp - Spice3.Internal.SpiceConstants.REFTEMP) - gmanew));
            annotation(Documentation(info = "<html>
<p>This internal function calculates several temperature dependent junction parameters based on the actual and the nominal temperature.</p>
</html>"));
          end junctionParamDepTempSPICE3;
          function junctionCapCoeffs "Coefficient calculation"
            extends Modelica.Icons.Function;
            input Real mj;
            input Real fc;
            input Modelica.SIunits.Voltage phij;
            output Modelica.SIunits.Voltage f1;
            output Real f2;
            output Real f3;
          protected
            Real xfc;
          algorithm
            xfc:=Modelica.Math.log(1 - fc);
            f1:=phij * (1 - exp((1 - mj) * xfc)) / (1 - mj);
            f2:=exp((1 + mj) * xfc);
            f3:=1 - fc * (1 + mj);
            annotation(Documentation(info = "<html>
<p>This internal auxiliary function calculates some coefficients which are necessary for the calculation of junction capacities.</p>
</html>"));
          end junctionCapCoeffs;
          function junction2SPICE3MOSFET "Junction current and conductance calculation, obsolete, use junction2SPICE3MOSFETRevised"
            extends Modelica.Icons.Function;
            extends Modelica.Icons.ObsoleteModel;
            input Modelica.SIunits.Current current "Input current";
            input Modelica.SIunits.Conductance cond "Input conductance";
            input Modelica.SIunits.Voltage voltage "Input voltage";
            input Modelica.SIunits.Temp_K temp "Device Temperature";
            input Real ncoeff;
            input Modelica.SIunits.Current satcur "Saturation current";
            output Modelica.SIunits.Current out_current "Calculated current";
            output Modelica.SIunits.Conductance out_cond "Calculated conductance";
          protected
            Modelica.SIunits.Voltage vte;
            Real max_exponent;
            Real evbd;
            Real evd;
            constant Real max_exp = 50.0;
            constant Modelica.SIunits.Current max_current = 10000.0;
          algorithm
            out_current:=current;
            out_cond:=cond;
            if satcur > 1e-101 then
              vte:=Spice3.Internal.SpiceConstants.CONSTKoverQ * temp * ncoeff;
              max_exponent:=Modelica.Math.log(max_current / satcur);
              max_exponent:=min(max_exp, max_exponent);
              if voltage <= 0 then
                out_cond:=satcur / vte;
                out_current:=out_cond * voltage;
                out_cond:=out_cond + Spice3.Internal.SpiceConstants.CKTgmin;
              elseif voltage >= max_exponent * vte then
                evd:=exp(max_exponent);
                out_cond:=satcur * evd / vte;
                out_current:=satcur * (evd - 1) + out_cond * (voltage - max_exponent * vte);
              else
                evbd:=exp(voltage / vte);
                out_cond:=satcur * evbd / vte + Spice3.Internal.SpiceConstants.CKTgmin;
                out_current:=satcur * (evbd - 1);
              end if;
            else
              out_current:=0.0;
              out_cond:=0.0;
            end if;
            annotation(Documentation(info = "<html>
<p>This internal function calculates both the junction current and the junction conductance dependent from the given voltage.</p>
</html>"));
          end junction2SPICE3MOSFET;
          function junctionCap "Junction capacity, obsolete, use JunctionCapRevised"
            extends Modelica.Icons.Function;
            extends Modelica.Icons.ObsoleteModel;
            input Modelica.SIunits.Capacitance capin "Input capacitance";
            input Modelica.SIunits.Voltage voltage "Input voltage";
            input Modelica.SIunits.Voltage depcap;
            input Real mj;
            input Real phij;
            input Modelica.SIunits.Voltage f1;
            input Real f2;
            input Real f3;
            output Modelica.SIunits.Capacitance capout "Output capacitance";
            output Modelica.SIunits.Charge charge "Output charge";
          protected
            Real arg;
            Real sarg;
            Real czof2;
          algorithm
            if voltage < depcap then
              arg:=1 - voltage / phij;
              if mj == 0.5 then
                sarg:=1 / sqrt(arg);
              else
                sarg:=exp(-1 * mj * Modelica.Math.log(arg));
              end if;
              capout:=capin * sarg;
              charge:=phij * capin * (1 - arg * sarg) / (1 - mj);
            else
              czof2:=capin / f2;
              capout:=czof2 * (f3 + mj * voltage / phij);
              charge:=capin * f1 + czof2 * (f3 * (voltage - depcap) + mj / (2 * phij) * (voltage ^ 2 - depcap ^ 2));
            end if;
            annotation(Documentation(info = "<html>
<p>This internal function calculates the charge and the capacitance of the junction capacity dependent from the given voltage.</p>
</html>"));
          end junctionCap;
          function energyGapDepTemp "Temperature dependency of energy gap"
            extends Modelica.Icons.Function;
            input SI.Temp_K temp "Temperature";
            output SI.Voltage ret "Output voltage";
          algorithm
            ret:=Spice3.Internal.MaterialParameters.EnergyGapSi - Spice3.Internal.MaterialParameters.FirstBandCorrFactorSi * temp * temp / (temp + Spice3.Internal.MaterialParameters.SecondBandCorrFactorSi);
            annotation(Documentation(info = "<html>
<p>This internal function calculates the temperature dependent energy gap based on the actual temperature, and two coefficients given as input to the function.</p>
</html>"));
          end energyGapDepTemp;
          function energyGapDepTemp_old "Temperature dependency of energy gap"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Temp_K temp "Temperature";
            output Modelica.SIunits.Voltage ret "Output voltage";
          protected
            Modelica.SIunits.Voltage gap0 = 1.16;
            Real coeff1(final unit = "V/K") = 0.000702;
            Modelica.SIunits.Temp_K coeff2 = 1108.0;
          algorithm
            ret:=gap0 - coeff1 * temp * temp / (temp + coeff2);
            annotation(Documentation(info = "<html>
<p>This internal function calculates the temperature dependent energy gap based on the actual temperature, and two coefficients given as input to the function.</p>
</html>"));
          end energyGapDepTemp_old;
          annotation(Documentation(info = "<html>
<p>The package Equation contains functions that are needed to model the semiconductor models. Some of these functions are used by several semiconductor models.</p>
</html>"));
        end Functions;
        package SpiceRoot "Basic records and functions"
          extends Modelica.Icons.InternalPackage;
          function useInitialConditions "Initial condition handling"
            extends Modelica.Icons.Function;
            output Boolean ret;
          algorithm
            ret:=false;
            annotation(Documentation(info = "<html>
<p>This function useInitialConditions appoints whether the initial conditions that are given in the description are used or not.</p>
</html>"));
          end useInitialConditions;
          function initJunctionVoltages "Choice of junction voltage handling, obsolete, use initJunctionVoltageRevised"
            extends Modelica.Icons.Function;
            extends Modelica.Icons.ObsoleteModel;
            output Boolean ret;
          algorithm
            ret:=false;
            annotation(Documentation(info = "<html>
<p>This internal function is provided to choose the junction voltage handling which is at the current library version fixed to false.</p>
</html>"));
          end initJunctionVoltages;
          annotation(Documentation(info = "<html>
<p>The package SpiceRoot contains basic records and functions that are needed in SPICE3.</p>
</html>"));
        end SpiceRoot;
        package Model "Device Temperature"
          extends Modelica.Icons.InternalPackage;
          record Model "Device Temperature"
            extends Modelica.Icons.Record;
            Modelica.SIunits.Temp_K m_dTemp(start = SpiceConstants.CKTnomTemp) "TEMP, Device Temperature";
            annotation(Documentation(info = "<html>
<p>The record Model includes the device temperature which has a default value of 27&deg;C.</p>
</html>"));
          end Model;
          annotation(Documentation(info = "<html>
<p>The package Model contains the record Model that includes the device temperature.</p>
</html>"));
        end Model;
        package Mosfet "Functions and records for MOSFETs"
          extends Modelica.Icons.InternalPackage;
          record Mosfet "Record for Mosfet parameters"
            extends Spice3.Internal.Model.Model;
            Modelica.SIunits.Length m_len(start = 0.0001) "L, length of channel region";
            Modelica.SIunits.Length m_width(start = 0.0001) "W, width of channel region";
            Modelica.SIunits.Area m_drainArea(start = Spice3.Internal.SpiceConstants.CKTdefaultMosAD) "AD, area of drain diffusion";
            Modelica.SIunits.Area m_sourceArea(start = Spice3.Internal.SpiceConstants.CKTdefaultMosAS) "AS, area of source diffusion";
            Real m_drainSquares(start = 1.0) "NRD, length of drain in squares";
            Real m_sourceSquares(start = 1.0) "NRS, length of source in squares";
            Modelica.SIunits.Length m_drainPerimeter(start = 0.0) "PD, Drain perimeter";
            Modelica.SIunits.Length m_sourcePerimeter(start = 0.0) "PS, Source perimeter";
            Modelica.SIunits.Voltage m_dICVDS(start = 0.0) "IC_VDS, Initial D-S voltage";
            Real m_dICVDSIsGiven "IC_VDS, IsGivenValue";
            Modelica.SIunits.Voltage m_dICVGS(start = 0.0) "IC_VGS, Initial G-S voltage";
            Real m_dICVGSIsGiven "IC_VGS, IsGivenValue";
            Modelica.SIunits.Voltage m_dICVBS(start = 0.0) "IC_VBS, Initial B-S voltage";
            Real m_dICVBSIsGiven "IC_VBS, IsGivenValue";
            Integer m_off(start = 0) "Device initially off, non-zero to indicate device is off for dc analysis";
            //----------------------obsolete-----------------------------------
            Integer m_bPMOS(start = 0) "P type MOSFET model";
            Integer m_nLevel(start = 1) "MOS model level";
            Modelica.SIunits.Length m_drainPerimiter(start = 0.0) "PD, Drain perimeter";
            Modelica.SIunits.Length m_sourcePerimiter(start = 0.0) "PS, Source perimeter";
            //-----------------------------------------------------------------
            Boolean m_uic;
            annotation(Documentation(info = "<html>
<p>This record Mosfet contains parameters that are used for all types of Mosfet transistors in SPICE3.</p>
</html>"));
          end Mosfet;
          record MosfetModelLineParams "Record for Mosfet model line parameters"
            extends Modelica.Icons.Record;
            Real m_jctSatCurDensity(start = 0.0) "JS, Bulk jct. sat. current density, input - use tSatCurDens";
            Modelica.SIunits.Resistance m_sheetResistance(start = 0.0) "RSH, Sheet resistance";
            Real m_bulkJctPotential(start = 0.8) "PB, Bulk junction potential, input - use tBulkPot";
            Modelica.SIunits.LinearTemperatureCoefficient m_bulkJctBotGradingCoeff(start = 0.5) "MJ, Bottom grading coefficient";
            //unit checked by maj
            Modelica.SIunits.LinearTemperatureCoefficient m_bulkJctSideGradingCoeff(start = 0.5) "MJSW, Side grading coefficient";
            //unit checked by maj
            Real m_oxideThickness(start = 1e-07) "TOX, Oxide thickness unit: micron";
            //--------------------------obsolete------------------------
            Real m_oxideThicknessIsGiven "TOX, IsGiven value";
            //-----------------------------------------------------------
            Real m_gateSourceOverlapCapFactor(start = 0.0) "CGS0, Gate-source overlap cap";
            Real m_gateDrainOverlapCapFactor(start = 0.0) "CGD0, Gate-drain overlap cap";
            Real m_gateBulkOverlapCapFactor(start = 0.0) "CGB0, Gate-bulk overlap cap";
            Real m_fNcoef(start = 0.0) "KF, Flicker noise coefficient";
            Real m_fNexp(start = 1.0) "AF, Flicker noise exponent";
            Real m_mjswIsGiven "MJSW, IsGivenValue";
            Real m_cgsoIsGiven "CGSO, IsGivenValue";
            Real m_cgdoIsGiven "CGDO, IsGivenValue";
            Real m_cgboIsGiven "CGBO, IsGivenValue";
            Real m_pbIsGiven "PB, IsGivenValue";
            annotation(Documentation(info = "<html>
<p>This record MosfetModelLineParams contains the model line parameters that are used for all kinds of Mosfet transistors in SPICE3.</p>
</html>"));
          end MosfetModelLineParams;
          record MosfetCalc "Mosfet Variables"
            extends Modelica.Icons.Record;
            Modelica.SIunits.Voltage m_vds "Vds, Drain-Source voltage";
            Modelica.SIunits.Voltage m_vgs "Vgs, Gate-Source voltage";
            Modelica.SIunits.Voltage m_vbs "Vbs, Bulk-Source voltage";
            Modelica.SIunits.Current m_cbs "Ibs, B-S junction current";
            Modelica.SIunits.Conductance m_gbs "Gbs, Bulk-Source conductance";
            Modelica.SIunits.Current m_cbd "Ibd, B-D junction current";
            Modelica.SIunits.Conductance m_gbd "Gbd, Bulk-Drain conductance";
            Modelica.SIunits.Current m_cdrain "Ids";
            Modelica.SIunits.Conductance m_gds "Gds, Drain-Source conductance";
            Modelica.SIunits.Transconductance m_gm "Gm, Transconductance";
            Modelica.SIunits.Transconductance m_gmbs "Gmbs, Bulk-Source transconductance";
            Modelica.SIunits.Capacitance m_capbsb "Cbsb";
            Modelica.SIunits.Charge m_chargebsb "Qbsb";
            Modelica.SIunits.Capacitance m_capbss "Cbss";
            Modelica.SIunits.Charge m_chargebss "Qbss";
            Modelica.SIunits.Capacitance m_capbdb "Cbdb";
            Modelica.SIunits.Charge m_chargebdb "Qbdb";
            Modelica.SIunits.Capacitance m_capbds "Cbds";
            Modelica.SIunits.Charge m_chargebds "Qbds";
            Real m_Beta "Beta";
            Modelica.SIunits.Capacitance m_capGSovl "Cgso, Gate-source overlap cap.";
            Modelica.SIunits.Capacitance m_capGDovl "Cgdo, Gate-drain overlap cap.";
            Modelica.SIunits.Capacitance m_capGBovl "Cgbo, Gate-bulk overlap cap.";
            Modelica.SIunits.Capacitance m_capOx "Cox";
            Modelica.SIunits.Voltage m_von "Von, Turn-on voltage";
            Modelica.SIunits.Voltage m_vdsat "Vdsat";
            Integer m_mode(start = 1) "Mode";
            Modelica.SIunits.Length m_lEff;
            Modelica.SIunits.Resistance m_sourceResistance "Rs";
            Modelica.SIunits.Resistance m_drainResistance "Rd";
            annotation(Documentation(info = "<html>
<p>This record MosfetCalc contains variables that are needed for calculation within modeling the semiconductor models.</p>
</html>"));
          end MosfetCalc;
          annotation(Documentation(info = "<html>
<p>The package Mosfet contains all functions and records that are used for all types of Mosfet transistors in SPICE3.</p>
</html>"));
        end Mosfet;
        package Mos "Records and functions for MOSFETs level 1,2,3,6"
          extends Modelica.Icons.InternalPackage;
          record MosModelLineParams "Record for Mosfet model line parameters (for level 1, 2, 3 and 6)"
            extends Spice3.Internal.Mosfet.MosfetModelLineParams;
            Real m_oxideCapFactor(start = 0.0);
            Modelica.SIunits.Voltage m_vt0(start = 0.0) "VTO, Threshold voltage";
            Real m_vtOIsGiven "VTO IsGivenValue";
            Modelica.SIunits.Capacitance m_capBD(start = 0.0) "CBD, B-D junction capacitance";
            Real m_capBDIsGiven "CapBD IsGivenValue";
            Modelica.SIunits.Capacitance m_capBS(start = 0.0) "CBS, B-S junction capacitance";
            Real m_capBSIsGiven "CapBS IsGivenValue";
            Modelica.SIunits.CapacitancePerArea m_bulkCapFactor(start = 0.0) "CJ, Bottom junction cap per area";
            Real m_bulkCapFactorIsGiven "Bulk cap factor IsGivenValue";
            Modelica.SIunits.Permittivity m_sideWallCapFactor(start = 0.0) "CJSW, Side grading coefficient";
            Real m_fwdCapDepCoeff(start = 0.5) "FC, Forward bias junction fit parameter";
            Modelica.SIunits.Voltage m_phi(start = 0.6) "PHI, Surface potential";
            Real m_phiIsGiven "Phi IsGivenValue";
            Modelica.SIunits.Voltage m_gamma(start = 0.0) "GAMMA, Bulk threshold parameter";
            Real m_gammaIsGiven "Gamma IsGivenValue";
            Modelica.SIunits.InversePotential m_lambda "Channel-length modulation";
            Real m_substrateDoping(start = 0.0) "NSUB, Substrate doping";
            Real m_substrateDopingIsGiven "Substrate doping IsGivenValue";
            Real m_gateType(start = 1.0) "TPG, Gate type";
            Modelica.SIunits.Conversions.NonSIunits.PerArea_cm m_surfaceStateDensity(start = 0.0) "NSS, Gate type";
            //-----------------obsolete--------------------------------------------
            Real m_surfaceStateDensityIsGiven(start = 0) "surfaceStateDensityIsGivenValue";
            //---------------------------------------------------------------------
            Modelica.SIunits.Conversions.NonSIunits.Area_cmPerVoltageSecond m_surfaceMobility(start = 600.0) "UO, Surface mobility";
            Modelica.SIunits.Length m_latDiff(start = 0.0) "LD, Lateral diffusion";
            Modelica.SIunits.Current m_jctSatCur(start = 1e-14) "IS, Bulk junction sat. current";
            Modelica.SIunits.Resistance m_drainResistance(start = 0) "RD, Drain ohmic resistance";
            Real m_drainResistanceIsGiven "Drain resistance IsGivenValue";
            Modelica.SIunits.Resistance m_sourceResistance(start = 0) "RS, Source ohmic resistance";
            Real m_sourceResistanceIsGiven "Source resistance IsGivenValue";
            Modelica.SIunits.Transconductance m_transconductance "input - use tTransconductance";
            Real m_transconductanceIsGiven "Transconductance IsGivenValue";
            Modelica.SIunits.Temp_K m_tnom(start = Spice3.Internal.SpiceConstants.CKTnomTemp) "TNOM, Parameter measurement temperature";
            annotation(Documentation(info = "<html>
<p>This record MosModelLineParams contains the model line parameters that are used for the MOSFET transistors level 1, 2, 3 and 6 in SPICE3.</p>
</html>"));
          end MosModelLineParams;
          record MosModelLineVariables "Record for Mosfet model line variables (for level 1)"
            extends Modelica.Icons.Record;
            Real m_oxideCapFactor;
            Modelica.SIunits.Voltage m_vt0;
            Modelica.SIunits.Voltage m_phi;
            Real m_gamma;
            Modelica.SIunits.Transconductance m_transconductance;
            annotation(Documentation(info = "<html>
<p>This record MosModelLineVariables contains the model line variables that are used for the MOSFET transistors level 1 SPICE3.</p>
</html>"));
          end MosModelLineVariables;
          record MosCalc "Further MOSFET variables (for level 1, 2, 3 and 6)"
            extends Spice3.Internal.Mosfet.MosfetCalc;
            SI.Transconductance m_tTransconductance(start = 0.0);
            SI.Conversions.NonSIunits.Area_cmPerVoltageSecond m_tSurfMob(start = 0.0);
            SI.Voltage m_tPhi(start = 0.7);
            SI.Voltage m_tVto(start = 1.0);
            SI.CurrentDensity m_tSatCurDens(start = 0.0);
            SI.Current m_tDrainSatCur(start = 0.0);
            SI.Current m_tSourceSatCur(start = 0.0);
            SI.Capacitance m_tCBDb(start = 0.0);
            SI.Capacitance m_tCBDs(start = 0.0);
            SI.Capacitance m_tCBSb(start = 0.0);
            SI.Capacitance m_tCBSs(start = 0.0);
            SI.CapacitancePerArea m_tCj(start = 0.0);
            SI.Permittivity m_tCjsw(start = 0.0);
            SI.Voltage m_tBulkPot(start = 0.7);
            SI.Voltage m_tDepCap(start = 0.35);
            SI.Voltage m_tVbi(start = 1.0);
            SI.Voltage m_VBScrit(start = 0.7);
            SI.Voltage m_VBDcrit(start = 0.7);
            SI.Voltage m_f1b(start = 0.0);
            Real m_f2b(start = 0.0);
            Real m_f3b(start = 0.0);
            SI.Voltage m_f1s(start = 0.0);
            Real m_f2s(start = 0.0);
            Real m_f3s(start = 0.0);
            SI.Voltage m_dVt(start = 0.0);
            SI.Capacitance m_capgd(start = 0.0);
            SI.Capacitance m_capgs(start = 0.0);
            SI.Capacitance m_capgb(start = 0.0);
            SI.Charge m_qgs(start = 0.0);
            SI.Charge m_qgd(start = 0.0);
            SI.Charge m_qgb(start = 0.0);
            annotation(Documentation(info = "<html>
<pre>This record MosCalc contains further MOSFET variables (for level 1, 2, 3 and 6).</pre>
</html>"));
          end MosCalc;
          record DEVqmeyer "Meyer capacities and charge"
            extends Modelica.Icons.Record;
            Modelica.SIunits.Capacitance qm_capgb(start = 0);
            Modelica.SIunits.Capacitance qm_capgs(start = 0);
            Modelica.SIunits.Capacitance qm_capgd(start = 0);
            Modelica.SIunits.Charge qm_qgs(start = 0);
            Modelica.SIunits.Charge qm_qgb(start = 0);
            Modelica.SIunits.Charge qm_qgd(start = 0);
            Modelica.SIunits.Voltage qm_vgs(start = 0);
            Modelica.SIunits.Voltage qm_vgb(start = 0);
            Modelica.SIunits.Voltage qm_vgd(start = 0);
            annotation(Documentation(info = "<html>
<p>This record DEVqmeyer contains values that are needed for the calculation of the Meyer capacities and charge.</p>
</html>"));
          end DEVqmeyer;
          record CurrrentsCapacitances "Currents and Capacities"
            extends Modelica.Icons.Record;
            Modelica.SIunits.Current idrain(start = 0);
            Modelica.SIunits.Current iBD(start = 0);
            Modelica.SIunits.Current iBS(start = 0);
            Modelica.SIunits.Capacitance cGS(start = 0);
            Modelica.SIunits.Capacitance cGB(start = 0);
            Modelica.SIunits.Capacitance cGD(start = 0);
            Modelica.SIunits.Capacitance cBS(start = 0);
            Modelica.SIunits.Capacitance cBD(start = 0);
            Modelica.SIunits.Capacitance m_capgd;
            annotation(Documentation(info = "<html>
<p>This record CurrentsCapacities contains values for the currents and the capacities inside the MOSFET models level 1, 2, 3 and 6.</p>
</html>"));
          end CurrrentsCapacitances;
          function mosCalcInitEquations "Mosfet initial precalculations (level 1)"
            extends Modelica.Icons.Function;
            input Spice3.Internal.Mos1.Mos1ModelLineParams in_p "Input record model line parameters for MOS1";
            input Spice3.Internal.SpiceConstants in_C "Input record SPICE constants";
            input MosModelLineVariables in_vp "Input record model line variables";
            input Spice3.Internal.Mosfet.Mosfet in_m "Input record MOSFET parameters";
            output Spice3.Internal.Mos1.Mos1Calc out_c "Output record Mos1 calculated values";
          algorithm
            out_c.m_drainResistance:=if in_p.m_drainResistanceIsGiven > 0.5 then in_p.m_drainResistance else in_p.m_sheetResistance * in_m.m_drainSquares;
            out_c.m_sourceResistance:=if in_p.m_sourceResistanceIsGiven > 0.5 then in_p.m_sourceResistance else in_p.m_sheetResistance * in_m.m_sourceSquares;
            out_c.m_lEff:=in_m.m_len - 2 * in_p.m_latDiff;
            if abs(out_c.m_lEff) < 1e-18 then
              out_c.m_lEff:=1e-06;
            else

            end if;
            out_c.m_capGSovl:=in_p.m_gateSourceOverlapCapFactor * in_m.m_width;
            out_c.m_capGDovl:=in_p.m_gateDrainOverlapCapFactor * in_m.m_width;
            out_c.m_capGBovl:=in_p.m_gateBulkOverlapCapFactor * out_c.m_lEff;
            out_c.m_capOx:=in_vp.m_oxideCapFactor * out_c.m_lEff * in_m.m_width;
            out_c.m_tTransconductance:=0;
            out_c.m_tSurfMob:=0;
            out_c.m_tPhi:=0.7;
            out_c.m_tVto:=1.0;
            out_c.m_tSatCurDens:=0;
            out_c.m_tDrainSatCur:=0;
            out_c.m_tSourceSatCur:=0;
            out_c.m_tCBDb:=0;
            out_c.m_tCBDs:=0;
            out_c.m_tCBSb:=0;
            out_c.m_tCBSs:=0;
            out_c.m_tCj:=0;
            out_c.m_tCjsw:=0;
            out_c.m_tBulkPot:=0.7;
            out_c.m_tDepCap:=0.35;
            out_c.m_tVbi:=1.0;
            out_c.m_VBScrit:=0.7;
            out_c.m_VBDcrit:=0.7;
            out_c.m_f1b:=0;
            out_c.m_f2b:=0;
            out_c.m_f3b:=0;
            out_c.m_f1s:=0;
            out_c.m_f2s:=0;
            out_c.m_f3s:=0;
            out_c.m_dVt:=0;
            out_c.m_capgd:=0;
            out_c.m_capgs:=0;
            out_c.m_capgb:=0;
            out_c.m_qgs:=0;
            out_c.m_qgd:=0;
            out_c.m_qgb:=0;
            out_c.m_vds:=0;
            out_c.m_vgs:=0;
            out_c.m_vbs:=0;
            out_c.m_cbs:=0;
            out_c.m_gbs:=0;
            out_c.m_cbd:=0;
            out_c.m_gbd:=0;
            out_c.m_cdrain:=0;
            out_c.m_gds:=0;
            out_c.m_gm:=0;
            out_c.m_gmbs:=0;
            out_c.m_capbsb:=0;
            out_c.m_chargebsb:=0;
            out_c.m_capbss:=0;
            out_c.m_chargebss:=0;
            out_c.m_capbdb:=0;
            out_c.m_chargebdb:=0;
            out_c.m_capbds:=0;
            out_c.m_chargebds:=0;
            out_c.m_Beta:=0;
            out_c.m_von:=0;
            out_c.m_vdsat:=0;
            out_c.m_mode:=1;
            annotation(Documentation(info = "<html>
<p>This function mosCalcInitEquations does the initial precalculation of the MOSFET parameters (level 1).</p>
</html>"));
          end mosCalcInitEquations;
          function mosCalcCalcTempDependencies "Precalculation relating to temperature"
            extends Modelica.Icons.Function;
            input Spice3.Internal.Mos1.Mos1ModelLineParams in_p "Input record model line parameters for MOS1";
            input Spice3.Internal.SpiceConstants in_C "Input record SPICE constants";
            input MosModelLineVariables in_vp "Input record model line variables";
            input Spice3.Internal.Mosfet.Mosfet in_m "Input record MOSFET parameters";
            input Spice3.Internal.Mos1.Mos1Calc in_c "Input record Mos1Calc";
            input Integer in_m_type "Type of MOS transistor";
            output Spice3.Internal.Mos1.Mos1Calc out_c "Output record with calculated values";
          protected
            Real ratio;
            Real ratio4;
            Real res;
          algorithm
            out_c:=in_c;
            ratio:=in_m.m_dTemp / in_p.m_tnom;
            ratio4:=ratio * sqrt(ratio);
            out_c.m_tTransconductance:=in_vp.m_transconductance / ratio4;
            out_c.m_Beta:=out_c.m_tTransconductance * in_m.m_width / out_c.m_lEff;
            out_c.m_tSurfMob:=in_p.m_surfaceMobility / ratio4;
            out_c.m_tPhi:=Spice3.Internal.Functions.junctionPotDepTemp(in_vp.m_phi, in_m.m_dTemp, in_p.m_tnom);
            out_c.m_tVbi:=in_vp.m_vt0 - in_m_type * in_vp.m_gamma * sqrt(in_vp.m_phi) + 0.5 * (Spice3.Internal.Functions.energyGapDepTemp_old(in_p.m_tnom) - Spice3.Internal.Functions.energyGapDepTemp_old(in_m.m_dTemp)) + in_m_type * 0.5 * (out_c.m_tPhi - in_vp.m_phi);
            out_c.m_tVto:=out_c.m_tVbi + in_m_type * in_vp.m_gamma * sqrt(out_c.m_tPhi);
            out_c.m_tBulkPot:=Spice3.Internal.Functions.junctionPotDepTemp(in_p.m_bulkJctPotential, in_m.m_dTemp, in_p.m_tnom);
            out_c.m_tDepCap:=in_p.m_fwdCapDepCoeff * out_c.m_tBulkPot;
            if in_p.m_jctSatCurDensity == 0.0 or in_m.m_sourceArea == 0.0 or in_m.m_drainArea == 0.0 then
              out_c.m_tDrainSatCur:=Spice3.Internal.Functions.saturationCurDepTempSPICE3MOSFET(in_p.m_jctSatCur, in_m.m_dTemp, in_p.m_tnom);
              out_c.m_tSourceSatCur:=out_c.m_tDrainSatCur;
              out_c.m_VBScrit:=Spice3.Internal.Functions.junctionVCrit(in_m.m_dTemp, 1.0, out_c.m_tSourceSatCur);
              out_c.m_VBDcrit:=out_c.m_VBScrit;
            else
              out_c.m_tSatCurDens:=Spice3.Internal.Functions.saturationCurDepTempSPICE3MOSFET(in_p.m_jctSatCurDensity, in_m.m_dTemp, in_p.m_tnom);
              out_c.m_tDrainSatCur:=out_c.m_tSatCurDens * in_m.m_drainArea;
              out_c.m_tSourceSatCur:=out_c.m_tSatCurDens * in_m.m_sourceArea;
              out_c.m_VBScrit:=Spice3.Internal.Functions.junctionVCrit(in_m.m_dTemp, 1.0, out_c.m_tSourceSatCur);
              out_c.m_VBDcrit:=Spice3.Internal.Functions.junctionVCrit(in_m.m_dTemp, 1.0, out_c.m_tDrainSatCur);
            end if;
            if not in_p.m_capBDIsGiven > 0.5 or not in_p.m_capBSIsGiven > 0.5 then
              (res,out_c.m_tCj):=Spice3.Internal.Functions.junctionParamDepTempSPICE3(in_p.m_bulkJctPotential, in_p.m_bulkCapFactor, in_p.m_bulkJctBotGradingCoeff, in_m.m_dTemp, in_p.m_tnom);
              (res,out_c.m_tCjsw):=Spice3.Internal.Functions.junctionParamDepTempSPICE3(in_p.m_bulkJctPotential, in_p.m_sideWallCapFactor, in_p.m_bulkJctSideGradingCoeff, in_m.m_dTemp, in_p.m_tnom);
              (out_c.m_f1s,out_c.m_f2s,out_c.m_f3s):=Spice3.Internal.Functions.junctionCapCoeffs(in_p.m_bulkJctSideGradingCoeff, in_p.m_fwdCapDepCoeff, out_c.m_tBulkPot);
            else

            end if;
            if in_p.m_capBDIsGiven > 0.5 then
              (res,out_c.m_tCBDb):=Spice3.Internal.Functions.junctionParamDepTempSPICE3(in_p.m_bulkJctPotential, in_p.m_capBD, in_p.m_bulkJctBotGradingCoeff, in_m.m_dTemp, in_p.m_tnom);
              out_c.m_tCBDs:=0.0;
            else
              out_c.m_tCBDb:=out_c.m_tCj * in_m.m_drainArea;
              out_c.m_tCBDs:=out_c.m_tCjsw * in_m.m_drainPerimeter;
            end if;
            if in_p.m_capBSIsGiven > 0.5 then
              (res,out_c.m_tCBSb):=Spice3.Internal.Functions.junctionParamDepTempSPICE3(in_p.m_bulkJctPotential, in_p.m_capBS, in_p.m_bulkJctBotGradingCoeff, in_m.m_dTemp, in_p.m_tnom);
              out_c.m_tCBSs:=0.0;
            else
              out_c.m_tCBSb:=out_c.m_tCj * in_m.m_sourceArea;
              out_c.m_tCBSs:=out_c.m_tCjsw * in_m.m_sourcePerimeter;
            end if;
            (out_c.m_f1b,out_c.m_f2b,out_c.m_f3b):=Spice3.Internal.Functions.junctionCapCoeffs(in_p.m_bulkJctBotGradingCoeff, in_p.m_fwdCapDepCoeff, out_c.m_tBulkPot);
            out_c.m_dVt:=in_m.m_dTemp * Spice3.Internal.SpiceConstants.CONSTKoverQ;
            annotation(Documentation(info = "<html>
<p>This function mosCalcCalcTempDependencies does precalculation relating to the temperature (level 1).</p>
</html>"));
          end mosCalcCalcTempDependencies;
          function mosCalcNoBypassCode "Calculation of currents and capacities (level 1)"
            extends Modelica.Icons.Function;
            input Spice3.Internal.Mosfet.Mosfet in_m "Input record MOSFET parameters";
            input Integer in_m_type "Type of MOS transistor";
            input Spice3.Internal.Mos1.Mos1Calc in_c "Input record Mos1Calc";
            input Spice3.Internal.Mos1.Mos1ModelLineParams in_p "Input record model line parameters for MOS1";
            input Spice3.Internal.SpiceConstants in_C "Input record SPICE constants";
            input MosModelLineVariables in_vp "Input record model line variables";
            input Boolean in_m_bInit;
            input Modelica.SIunits.Voltage[4] in_m_pVoltageValues;
            /* gate bulk drain source */
            output CurrrentsCapacitances out_cc;
          protected
            Modelica.SIunits.Voltage vbd;
            Modelica.SIunits.Voltage vgd;
            Modelica.SIunits.Voltage vgb;
            Modelica.SIunits.Current cur;
            Integer n;
            DEVqmeyer qm;
            Spice3.Internal.Mos1.Mos1Calc int_c;
            Real hlp;
          algorithm
            int_c:=in_c;
            out_cc.m_capgd:=0;
            int_c.m_vgs:=in_m_type * (in_m_pVoltageValues[1] - in_m_pVoltageValues[4]);
            // ( G , SP)
            int_c.m_vbs:=in_m_type * (in_m_pVoltageValues[2] - in_m_pVoltageValues[4]);
            // ( B , SP)
            int_c.m_vds:=in_m_type * (in_m_pVoltageValues[3] - in_m_pVoltageValues[4]);
            // ( DP, SP)
            if Spice3.Internal.SpiceRoot.useInitialConditions() and in_m.m_dICVBSIsGiven > 0.5 then
              int_c.m_vbs:=in_m_type * in_m.m_dICVBS;
            elseif Spice3.Internal.SpiceRoot.initJunctionVoltages() then
              int_c.m_vbs:=if in_m.m_off > 0.5 then 0.0 else int_c.m_VBScrit;
            else

            end if;
            if Spice3.Internal.SpiceRoot.useInitialConditions() and in_m.m_dICVDSIsGiven > 0.5 then
              int_c.m_vds:=in_m_type * in_m.m_dICVDS;
            elseif Spice3.Internal.SpiceRoot.initJunctionVoltages() then
              int_c.m_vds:=if in_m.m_off > 0.5 then 0.0 else int_c.m_VBDcrit - int_c.m_VBScrit;
            else

            end if;
            if Spice3.Internal.SpiceRoot.useInitialConditions() and in_m.m_dICVGSIsGiven > 0.5 then
              int_c.m_vgs:=in_m_type * in_m.m_dICVGS;
            elseif Spice3.Internal.SpiceRoot.initJunctionVoltages() then
              if in_m.m_off > 0.5 then
                int_c.m_vgs:=0.0;
              else

              end if;
            else

            end if;
            vbd:=int_c.m_vbs - int_c.m_vds;
            vgd:=int_c.m_vgs - int_c.m_vds;
            if int_c.m_vds >= 0 then
              vbd:=int_c.m_vbs - int_c.m_vds;
            else
              int_c.m_vbs:=vbd + int_c.m_vds;
            end if;
            vgb:=int_c.m_vgs - int_c.m_vbs;
            (int_c.m_cbd,int_c.m_gbd):=Spice3.Internal.Functions.junction2SPICE3MOSFET(int_c.m_cbd, int_c.m_gbd, vbd, in_m.m_dTemp, 1.0, int_c.m_tDrainSatCur);
            out_cc.iBD:=in_m_type * int_c.m_cbd;
            (int_c.m_cbs,int_c.m_gbs):=Spice3.Internal.Functions.junction2SPICE3MOSFET(int_c.m_cbs, int_c.m_gbs, int_c.m_vbs, in_m.m_dTemp, 1.0, int_c.m_tSourceSatCur);
            out_cc.iBS:=in_m_type * int_c.m_cbs;
            int_c.m_mode:=if int_c.m_vds >= 0 then 1 else -1;
            // 1: normal mode, -1: inverse mode
            if int_c.m_mode == 1 then
              int_c:=Spice3.Internal.Mos1.drainCur(int_c.m_vbs, int_c.m_vgs, int_c.m_vds, int_c, in_p, in_C, in_vp, in_m_type);
            else
              int_c:=Spice3.Internal.Mos1.drainCur(vbd, vgd, -int_c.m_vds, int_c, in_p, in_C, in_vp, in_m_type);
            end if;
            n:=if int_c.m_mode == 1 then 6 else 5;
            out_cc.idrain:=in_m_type * int_c.m_cdrain * int_c.m_mode;
            int_c.m_capbss:=0.0;
            int_c.m_chargebss:=0.0;
            int_c.m_capbds:=0.0;
            int_c.m_chargebds:=0.0;
            (int_c.m_capbsb,int_c.m_chargebsb):=Spice3.Internal.Functions.junctionCap(int_c.m_tCBSb, int_c.m_vbs, int_c.m_tDepCap, in_p.m_bulkJctBotGradingCoeff, int_c.m_tBulkPot, int_c.m_f1b, int_c.m_f2b, int_c.m_f3b);
            (int_c.m_capbdb,int_c.m_chargebdb):=Spice3.Internal.Functions.junctionCap(int_c.m_tCBDb, vbd, int_c.m_tDepCap, in_p.m_bulkJctBotGradingCoeff, int_c.m_tBulkPot, int_c.m_f1b, int_c.m_f2b, int_c.m_f3b);
            if not in_p.m_capBSIsGiven > 0.5 then
              (int_c.m_capbss,int_c.m_chargebss):=Spice3.Internal.Functions.junctionCap(int_c.m_tCBSs, int_c.m_vbs, int_c.m_tDepCap, in_p.m_bulkJctSideGradingCoeff, int_c.m_tBulkPot, int_c.m_f1s, int_c.m_f2s, int_c.m_f3s);
            else

            end if;
            if not in_p.m_capBDIsGiven > 0.5 then
              (int_c.m_capbds,int_c.m_chargebds):=Spice3.Internal.Functions.junctionCap(int_c.m_tCBDs, vbd, int_c.m_tDepCap, in_p.m_bulkJctSideGradingCoeff, int_c.m_tBulkPot, int_c.m_f1s, int_c.m_f2s, int_c.m_f3s);
            else

            end if;
            out_cc.cBS:=if in_m_bInit then 1e-15 else int_c.m_capbsb + int_c.m_capbss;
            out_cc.cBD:=if in_m_bInit then 1e-15 else int_c.m_capbdb + int_c.m_capbds;
            if int_c.m_mode > 0 then
              qm:=mosCalcDEVqmeyer(int_c.m_vgs, vgd, vgb, int_c);
            else
              qm:=mosCalcDEVqmeyer(vgd, int_c.m_vgs, vgb, int_c);
              hlp:=qm.qm_capgd;
              qm.qm_capgd:=qm.qm_capgs;
              qm.qm_capgs:=hlp;
            end if;
            int_c.m_capgd:=2 * qm.qm_capgd + int_c.m_capGDovl;
            int_c.m_capgs:=2 * qm.qm_capgs + int_c.m_capGSovl;
            int_c.m_capgb:=2 * qm.qm_capgb + int_c.m_capGBovl;
            out_cc.cGB:=if in_m_bInit then -1e+40 else int_c.m_capgb;
            out_cc.cGD:=if in_m_bInit then -1e+40 else int_c.m_capgd;
            out_cc.cGS:=if in_m_bInit then -1e+40 else int_c.m_capgs;
            annotation(Documentation(info = "<html>
<p>This function NoBypassCode calculates the currents (and the capacitances) that are necessary for the currents sum in the toplevelmodel (level 1).</p>
</html>"));
          end mosCalcNoBypassCode;
          function mosCalcDEVqmeyer "Calculation of Meyer capacities"
            extends Modelica.Icons.Function;
            input SI.Voltage vgs;
            input SI.Voltage vgd;
            input SI.Voltage vgb;
            input MosCalc in_c "Input variable set";
            output DEVqmeyer out_qm "Qmeyer values";
          protected
            SI.Voltage vds;
            SI.Voltage vddif;
            SI.Voltage vddif1;
            Types.VoltageSquare vddif2;
            SI.Voltage vgst;
          algorithm
            vgst:=vgs - in_c.m_von;
            if vgst <= (-in_c.m_tPhi) then
              out_qm.qm_capgb:=in_c.m_capOx / 2.0;
              out_qm.qm_capgs:=0.0;
              out_qm.qm_capgd:=0.0;
            elseif vgst <= (-in_c.m_tPhi / 2.0) then
              out_qm.qm_capgb:=-vgst * in_c.m_capOx / (2.0 * in_c.m_tPhi);
              out_qm.qm_capgs:=0.0;
              out_qm.qm_capgd:=0.0;

            elseif vgst <= 0.0 then
              out_qm.qm_capgb:=-vgst * in_c.m_capOx / (2.0 * in_c.m_tPhi);
              out_qm.qm_capgs:=vgst * in_c.m_capOx / (1.5 * in_c.m_tPhi) + in_c.m_capOx / 3.0;
              out_qm.qm_capgd:=0.0;
            else
              vds:=vgs - vgd;
              if in_c.m_vdsat <= vds then
                out_qm.qm_capgs:=in_c.m_capOx / 3.0;
                out_qm.qm_capgd:=0.0;
                out_qm.qm_capgb:=0.0;
              else
                vddif:=2.0 * in_c.m_vdsat - vds;
                vddif1:=in_c.m_vdsat - vds;
                vddif2:=vddif * vddif;
                out_qm.qm_capgd:=in_c.m_capOx * (1.0 - in_c.m_vdsat * in_c.m_vdsat / vddif2) / 3.0;
                out_qm.qm_capgs:=in_c.m_capOx * (1.0 - vddif1 * vddif1 / vddif2) / 3.0;
                out_qm.qm_capgb:=0.0;
              end if;
            end if;
            out_qm.qm_qgs:=0.0;
            out_qm.qm_qgb:=0.0;
            out_qm.qm_qgd:=0.0;
            out_qm.qm_vgs:=0.0;
            out_qm.qm_vgb:=0.0;
            out_qm.qm_vgd:=0.0;
            annotation(Documentation(info = "<html>
<p>This function mosCalcDEVqmeyer calculates the Meyer capacities and charge for the Meyer model.</p>
</html>"));
          end mosCalcDEVqmeyer;
          annotation(Documentation(info = "<html>
<p>This package Mos contains functions and records with data of the MOSFET models level 1, 2, 3 and 6.</p>
</html>"));
        end Mos;
        package Mos1 "Records and functions for MOSFETs level 1"
          extends Modelica.Icons.InternalPackage;
          record Mos1ModelLineParams "Record for Mosfet model line parameters (for level 1)"
            extends Mos.MosModelLineParams(m_lambda(start = 0.0), m_transconductance(start = 2e-05));
            annotation(Documentation(info = "<html>
<p>This record Mos1ModelLineParams contains the model line parameters that are used for the MOSFET transistors level 1 in SPICE3.</p>
</html>"));
          end Mos1ModelLineParams;
          record Mos1Calc "Further MOSFET variables (for level 1)"
            extends Mos.MosCalc;
            annotation(Documentation(info = "<html>
<p>This record Mos1Calc contains further MOSFET variables (for level 1) that are needed for the calculations.</p>
</html>"));
          end Mos1Calc;
          function mos1ModelLineParamsInitEquations "Initial precalculation"
            extends Modelica.Icons.Function;
            input Mos1ModelLineParams in_p "Input record model line parameters for MOS1";
            input SpiceConstants in_C "Spice constants";
            input Integer in_m_type "Type of MOS transistor";
            output Mos.MosModelLineVariables out_v "Output record model line variables";
          protected
            Modelica.SIunits.Voltage vtnom;
            Modelica.SIunits.Voltage fermis;
            Real fermig;
            Real wkfng;
            Real wkfngs;
            Real egfet1;
            Real vfb;
          algorithm
            out_v.m_oxideCapFactor:=in_p.m_oxideCapFactor;
            out_v.m_transconductance:=in_p.m_transconductance;
            out_v.m_phi:=in_p.m_phi;
            out_v.m_gamma:=in_p.m_gamma;
            out_v.m_vt0:=in_p.m_vt0;
            vtnom:=in_p.m_tnom * SpiceConstants.CONSTKoverQ;
            egfet1:=1.16 - 0.000702 * in_p.m_tnom * in_p.m_tnom / (in_p.m_tnom + 1108);
            if not in_p.m_oxideThicknessIsGiven > 0.5 or in_p.m_oxideThickness == 0 then
              if in_p.m_oxideThickness == 0 then
                out_v.m_oxideCapFactor:=0;
              else

              end if;
            else
              out_v.m_oxideCapFactor:=3.9 * 8.854214871e-12 / in_p.m_oxideThickness;
              if out_v.m_oxideCapFactor <> 0 then
                if not in_p.m_transconductanceIsGiven > 0.5 then
                  out_v.m_transconductance:=in_p.m_surfaceMobility * out_v.m_oxideCapFactor * 0.0001;
                else

                end if;
                if in_p.m_substrateDopingIsGiven > 0.5 then
                  if in_p.m_substrateDoping * 1000000.0 > 1.45e+16 then
                    if not in_p.m_phiIsGiven > 0.5 then
                      out_v.m_phi:=2 * vtnom * Modelica.Math.log(in_p.m_substrateDoping * 1000000.0 / 1.45e+16);
                      out_v.m_phi:=max(0.1, out_v.m_phi);
                    else

                    end if;
                    fermis:=in_m_type * 0.5 * out_v.m_phi;
                    wkfng:=3.2;
                    if in_p.m_gateType <> 0 then
                      fermig:=in_m_type * in_p.m_gateType * 0.5 * egfet1;
                      wkfng:=3.25 + 0.5 * egfet1 - fermig;
                    else

                    end if;
                    wkfngs:=wkfng - (3.25 + 0.5 * egfet1 + fermis);
                    if not in_p.m_gammaIsGiven > 0.5 then
                      out_v.m_gamma:=sqrt(2 * 11.7 * 8.854214871e-12 * SpiceConstants.CHARGE * in_p.m_substrateDoping * 1000000.0 / out_v.m_oxideCapFactor);
                    else

                    end if;
                    if not in_p.m_vtOIsGiven > 0.5 then
                      vfb:=wkfngs - in_p.m_surfaceStateDensity * 10000.0 * SpiceConstants.CHARGE / out_v.m_oxideCapFactor;
                      out_v.m_vt0:=vfb + in_m_type * (out_v.m_gamma * sqrt(out_v.m_phi) + out_v.m_phi);
                    else

                    end if;
                  else

                  end if;
                else

                end if;
              else

              end if;
            end if;
            // (m**2/cm**2)
            // (cm**3/m**3)
            // (cm**3/m**3)
            // (cm**3/m**3)
            // (cm**2/m**2)
            annotation(Documentation(info = "<html>
<p>This function mos1ModelLineParamsInitEquation does the initial precalculation of the MOSFET model line parameters for level 1.</p>
</html>"));
          end mos1ModelLineParamsInitEquations;
          function drainCur "Drain current calculation"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Voltage vb;
            input Modelica.SIunits.Voltage vg;
            input Modelica.SIunits.Voltage vds;
            input Mos1Calc in_c "Input record Mos1Calc";
            input Mos1ModelLineParams in_p "Input record model line parameters for MOS1";
            input SpiceConstants in_C "Spice constants";
            input Mos.MosModelLineVariables in_vp "Input record model line variables";
            input Integer in_m_type "Type of Mos transistor";
            output Mos1Calc out_c "Output record Mos1Calc";
          protected
            Real arg;
            Real betap;
            Real sarg;
            Modelica.SIunits.Voltage vgst;
          algorithm
            out_c:=in_c;
            if vb <= 0 then
              sarg:=sqrt(out_c.m_tPhi - vb);
            else
              sarg:=sqrt(out_c.m_tPhi);
              sarg:=sarg - vb / (sarg + sarg);
              sarg:=max(0.0, sarg);
            end if;
            out_c.m_von:=out_c.m_tVbi * in_m_type + in_vp.m_gamma * sarg;
            vgst:=vg - out_c.m_von;
            out_c.m_vdsat:=max(vgst, 0.0);
            arg:=if sarg <= 0 then 0 else in_vp.m_gamma / (sarg + sarg);
            if vgst <= 0 then
              out_c.m_cdrain:=0;
              out_c.m_gm:=0;
              out_c.m_gds:=0;
              out_c.m_gmbs:=0;
            else
              betap:=out_c.m_Beta * (1 + in_p.m_lambda * vds);
              if vgst <= vds then
                out_c.m_cdrain:=betap * vgst * vgst * 0.5;
                out_c.m_gm:=betap * vgst;
                out_c.m_gds:=in_p.m_lambda * out_c.m_Beta * vgst * vgst * 0.5;
                out_c.m_gmbs:=out_c.m_gm * arg;
              else
                out_c.m_cdrain:=betap * vds * (vgst - 0.5 * vds);
                out_c.m_gm:=betap * vds;
                out_c.m_gds:=betap * (vgst - vds) + in_p.m_lambda * out_c.m_Beta * vds * (vgst - 0.5 * vds);
                out_c.m_gmbs:=out_c.m_gm * arg;
              end if;
            end if;
            /* cutoff region */
            /* saturation region */
            /* linear region */
            annotation(Documentation(info = "<html>
<p>This function drainCur calculates the main currents that flows from drain node to source node (level 1).</p>
</html>"));
          end drainCur;
          function mos1RenameParameters "Parameter renaming to internal names"
            extends Modelica.Icons.Function;
            input ModelcardMOS ex "Modelcard with technologieparameters";
            input SpiceConstants con "Spice constants";
            output Mos.MosModelLineParams intern "Output record model line parameters";
          algorithm
            intern.m_cgboIsGiven:=0;
            intern.m_cgdoIsGiven:=0;
            intern.m_cgsoIsGiven:=0;
            intern.m_mjswIsGiven:=0;
            intern.m_pbIsGiven:=0;
            intern.m_surfaceStateDensityIsGiven:=0;
            intern.m_oxideCapFactor:=0;
            intern.m_vtOIsGiven:=if ex.VTO > (-1e+40) then 1 else 0;
            intern.m_vt0:=if ex.VTO > (-1e+40) then ex.VTO else 0;
            intern.m_capBDIsGiven:=if ex.CBD > (-1e+40) then 1 else 0;
            intern.m_capBD:=if ex.CBD > (-1e+40) then ex.CBD else 0;
            intern.m_capBSIsGiven:=if ex.CBS > (-1e+40) then 1 else 0;
            intern.m_capBS:=if ex.CBS > (-1e+40) then ex.CBS else 0;
            intern.m_bulkCapFactorIsGiven:=if ex.CJ > (-1e+40) then 1 else 0;
            intern.m_bulkCapFactor:=if ex.CJ > (-1e+40) then ex.CJ else 0;
            intern.m_sideWallCapFactor:=ex.CJSW "F/m zero-bias junction sidewall cap. per meter of junction perimeter (default 0)";
            intern.m_fwdCapDepCoeff:=ex.FC "Coefficient for forward-bias depletion capacitance formula (default 0.5)";
            intern.m_phiIsGiven:=if ex.PHI > (-1e+40) then 1 else 0;
            intern.m_phi:=if ex.PHI > (-1e+40) then ex.PHI else 0.6;
            intern.m_gammaIsGiven:=if ex.GAMMA > (-1e+40) then 1 else 0;
            intern.m_gamma:=if ex.GAMMA > (-1e+40) then ex.GAMMA else 0;
            intern.m_lambda:=ex.LAMBDA "1/V channel-length modulation (default 0)";
            intern.m_substrateDopingIsGiven:=if ex.NSUB > (-1e+40) then 1 else 0;
            intern.m_substrateDoping:=if ex.NSUB > (-1e+40) then ex.NSUB else 0;
            intern.m_gateType:=ex.TPG "Type of gate material: +1 opp. to substrate, -1 same as substrate, 0 Al gate (default 1)";
            intern.m_surfaceStateDensity:=ex.NSS "IN 1/(cm*cm) surface state density (default 0)";
            intern.m_surfaceMobility:=ex.UO "In (cm*cm)/(Vs) surface mobility (default 600)";
            intern.m_latDiff:=ex.LD "In m lateral diffusion (default 0)";
            intern.m_jctSatCur:=ex.IS "A bulk junction saturation current (default 1e-14)";
            intern.m_drainResistanceIsGiven:=if ex.RD > (-1e+40) then 1 else 0;
            intern.m_drainResistance:=if ex.RD > (-1e+40) then ex.RD else 0;
            intern.m_sourceResistanceIsGiven:=if ex.RS > (-1e+40) then 1 else 0;
            intern.m_sourceResistance:=if ex.RS > (-1e+40) then ex.RS else 0;
            intern.m_transconductanceIsGiven:=if ex.KP > (-1e+40) then 1 else 0;
            intern.m_transconductance:=if ex.KP > (-1e+40) then ex.KP else 2e-05;
            intern.m_tnom:=if ex.TNOM > (-1e+40) then ex.TNOM + SpiceConstants.CONSTCtoK else 300.15 "parameter measurement temperature (default 27 deg C)";
            intern.m_jctSatCurDensity:=ex.JS "A/(m*m) bulk junction saturation current per sq-meter of junction area (default 0)";
            intern.m_sheetResistance:=ex.RSH "Ohm drain and source diffusion sheet resistance (default 0)";
            intern.m_bulkJctPotential:=ex.PB "V bulk junction potential (default 0.8)";
            intern.m_bulkJctBotGradingCoeff:=ex.MJ "bulk junction bottom grading coeff. (default 0.5)";
            intern.m_bulkJctSideGradingCoeff:=ex.MJSW "bulk junction sidewall grading coeff. (default 0.5)";
            intern.m_oxideThicknessIsGiven:=if ex.TOX > (-1e+40) then 1 else 0;
            intern.m_oxideThickness:=if ex.TOX > (-1e+40) then ex.TOX else 0;
            intern.m_gateSourceOverlapCapFactor:=ex.CGSO "F/m gate-source overlap capacitance per meter channel width (default 0)";
            intern.m_gateDrainOverlapCapFactor:=ex.CGDO "F/m gate-drain overlap capacitance per meter channel width (default 0)";
            intern.m_gateBulkOverlapCapFactor:=ex.CGBO "F/m gate-bulk overlap capacitance per meter channel width (default 0)";
            intern.m_fNcoef:=ex.KF "Flicker-noise coefficient (default 0)";
            intern.m_fNexp:=ex.AF "Flicker-noise exponent (default 1)";
            annotation(Documentation(info = "<html>
<p>This function mos1RenameParameters assigns the external (given by the user, e.g., RD) technology parameters
to the internal parameters (e.g., m_drainResistance). It also does the analysis of the IsGiven values (level 1).</p>
</html>"));
          end mos1RenameParameters;
          function mos1RenameParametersDev "Device parameter renaming to internal names"
            extends Modelica.Icons.Function;
            input ModelcardMOS ex;
            input Integer mtype;
            input Modelica.SIunits.Length W "Channel Width";
            input Modelica.SIunits.Length L "Channel Length";
            input Modelica.SIunits.Area AD "Area of the drain diffusion";
            input Modelica.SIunits.Area AS "Area of the source diffusion";
            input Modelica.SIunits.Length PD "Perimeter of the drain junction";
            input Modelica.SIunits.Length PS "Perimeter of the source junction";
            input Real NRD "Number of squares of the drain diffusions";
            input Real NRS "Number of squares of the source diffusions";
            input Integer OFF "Optional initial condition: 0 - IC not used, 1 - IC used, not implemented yet";
            input Real IC "Initial condition values, not implemented yet";
            input Modelica.SIunits.Temp_C TEMP "Temperature";
            output Mosfet.Mosfet dev "Output record Mosfet";
          algorithm
            /*device parameters*/
            dev.m_len:=L "L, length of channel region";
            dev.m_width:=W "W, width of channel region";
            dev.m_drainArea:=AD "AD, area of drain diffusion";
            dev.m_sourceArea:=AS "AS, area of source diffusion";
            dev.m_drainSquares:=NRD "NRD, length of drain in squares";
            dev.m_sourceSquares:=NRS "NRS, length of source in squares";
            dev.m_drainPerimeter:=PD "PD, Drain perimeter";
            dev.m_sourcePerimeter:=PS "PS, Source perimeter";
            dev.m_dICVDSIsGiven:=if IC > (-1e+40) then 1 else 0 "ICVDS IsGivenValue";
            dev.m_dICVDS:=if IC > (-1e+40) then IC else 0 "Initial condition of VDS";
            dev.m_dICVGSIsGiven:=if IC > (-1e+40) then 1 else 0 "ICVGS IsGivenValue";
            dev.m_dICVGS:=if IC > (-1e+40) then IC else 0 "Initial condition of VGS";
            dev.m_dICVBSIsGiven:=if IC > (-1e+40) then 1 else 0 "ICVBS IsGivenValue";
            dev.m_dICVBS:=if IC > (-1e+40) then IC else 0 "Initial condition of VBS";
            dev.m_off:=OFF "Non-zero to indicate device is off for dc analysis";
            dev.m_bPMOS:=mtype "P type MOSFET model";
            dev.m_nLevel:=ex.LEVEL "Level";
            assert(ex.LEVEL == 1, "only MOS Level1 implemented");
            dev.m_dTemp:=TEMP + SpiceConstants.CONSTCtoK "Device temperature";
            dev.m_drainPerimiter:=0;
            dev.m_sourcePerimiter:=0;
            dev.m_uic:=false;
            annotation(Documentation(info = "<html>
<p>This function mos1RenameParametersDev assigns the external (given by the user) device parameters to the internal parameters. It also does the analysis of the IsGiven values (level 1).</p>
</html>"));
          end mos1RenameParametersDev;
          annotation(Documentation(info = "<html>
<p>This package Mos1 contains functions and record with data of the MOSFET model level 1.</p>
</html>"));
        end Mos1;
      end Internal;
      annotation(Documentation(info = "<html>
<p>This package contains all function, parameters and data of semiconductor models, that are transformed from SPICE3 into Modelica. The models of the package semiconductors access to repository models. This package should not be used via direct access by a user of the Spice-Library for Modelica. It is restricted to the development.</p>
</html>"), Icon(graphics = {Line(points = {{-20,40},{-20,-40}}, color = {0,0,0}),Line(points = {{-90,0},{-20,0}}, color = {0,0,0}),Line(points = {{0,0},{90,0}}, color = {0,0,0}),Line(points = {{20,90},{20,40},{0,40},{0,-40},{20,-40},{20,-90}}, color = {0,0,0})}));
    end Spice3;
    annotation(Documentation(info = "<html>
<p>
This library contains electrical components to build up analog and digital circuits,
as well as machines to model electrical motors and generators,
especially three phase induction machines such as an asynchronous motor.
</p>

</html>"), Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100.0,-100.0},{100.0,100.0}}), graphics = {Rectangle(origin = {20.3125,82.8571}, extent = {{-45.3125,-57.8571},{4.6875,-27.8571}}),Line(origin = {8.0,48.0}, points = {{32.0,-58.0},{72.0,-58.0}}),Line(origin = {9.0,54.0}, points = {{31.0,-49.0},{71.0,-49.0}}),Line(origin = {-2.0,55.0}, points = {{-83.0,-50.0},{-33.0,-50.0}}),Line(origin = {-3.0,45.0}, points = {{-72.0,-55.0},{-42.0,-55.0}}),Line(origin = {1.0,50.0}, points = {{-61.0,-45.0},{-61.0,-10.0},{-26.0,-10.0}}),Line(origin = {7.0,50.0}, points = {{18.0,-10.0},{53.0,-10.0},{53.0,-45.0}}),Line(origin = {6.2593,48.0}, points = {{53.7407,-58.0},{53.7407,-93.0},{-66.2593,-93.0},{-66.2593,-58.0}})}));
  end Electrical;
  package Math "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices"
    import SI = Modelica.SIunits;
    extends Modelica.Icons.Package;
    package Icons "Icons for Math"
      extends Modelica.Icons.IconsPackage;
      partial function AxisLeft "Basic icon for mathematical function with y-axis on left side"
        annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100,-100},{100,100}}), graphics = {Rectangle(extent = {{-100,100},{100,-100}}, lineColor = {0,0,0}, fillColor = {255,255,255}, fillPattern = FillPattern.Solid),Line(points = {{-80,-80},{-80,68}}, color = {192,192,192}),Polygon(points = {{-80,90},{-88,68},{-72,68},{-80,90}}, lineColor = {192,192,192}, fillColor = {192,192,192}, fillPattern = FillPattern.Solid),Text(extent = {{-150,150},{150,110}}, textString = "%name", lineColor = {0,0,255})}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100,-100},{100,100}}), graphics = {Line(points = {{-80,80},{-88,80}}, color = {95,95,95}),Line(points = {{-80,-80},{-88,-80}}, color = {95,95,95}),Line(points = {{-80,-90},{-80,84}}, color = {95,95,95}),Text(extent = {{-75,104},{-55,84}}, lineColor = {95,95,95}, textString = "y"),Polygon(points = {{-80,98},{-86,82},{-74,82},{-80,98}}, lineColor = {95,95,95}, fillColor = {95,95,95}, fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
<p>
Icon for a mathematical function, consisting of an y-axis on the left side.
It is expected, that an x-axis is added and a plot of the function.
</p>
</html>"));
      end AxisLeft;
      partial function AxisCenter "Basic icon for mathematical function with y-axis in the center"
        annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100,-100},{100,100}}), graphics = {Rectangle(extent = {{-100,100},{100,-100}}, lineColor = {0,0,0}, fillColor = {255,255,255}, fillPattern = FillPattern.Solid),Line(points = {{0,-80},{0,68}}, color = {192,192,192}),Polygon(points = {{0,90},{-8,68},{8,68},{0,90}}, lineColor = {192,192,192}, fillColor = {192,192,192}, fillPattern = FillPattern.Solid),Text(extent = {{-150,150},{150,110}}, textString = "%name", lineColor = {0,0,255})}), Diagram(graphics = {Line(points = {{0,80},{-8,80}}, color = {95,95,95}),Line(points = {{0,-80},{-8,-80}}, color = {95,95,95}),Line(points = {{0,-90},{0,84}}, color = {95,95,95}),Text(extent = {{5,104},{25,84}}, lineColor = {95,95,95}, textString = "y"),Polygon(points = {{0,98},{-6,82},{6,82},{0,98}}, lineColor = {95,95,95}, fillColor = {95,95,95}, fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
<p>
Icon for a mathematical function, consisting of an y-axis in the middle.
It is expected, that an x-axis is added and a plot of the function.
</p>
</html>"));
      end AxisCenter;
    end Icons;
    function asin "Inverse sine (-1 <= u <= 1)"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output SI.Angle y;

      external "builtin" y = asin(u) ;
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100,-100},{100,100}}), graphics = {Line(points = {{-90,0},{68,0}}, color = {192,192,192}),Polygon(points = {{90,0},{68,8},{68,-8},{90,0}}, lineColor = {192,192,192}, fillColor = {192,192,192}, fillPattern = FillPattern.Solid),Line(points = {{-80,-80},{-79.2,-72.8},{-77.6,-67.5},{-73.6,-59.4},{-66.3,-49.8},{-53.5,-37.3},{-30.2,-19.7},{37.4,24.8},{57.5,40.8},{68.7,52.7},{75.2,62.2},{77.6,67.5},{80,80}}, color = {0,0,0}),Text(extent = {{-88,78},{-16,30}}, lineColor = {192,192,192}, textString = "asin")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100,-100},{100,100}}), graphics = {Text(extent = {{-40,-72},{-15,-88}}, textString = "-pi/2", lineColor = {0,0,255}),Text(extent = {{-38,88},{-13,72}}, textString = " pi/2", lineColor = {0,0,255}),Text(extent = {{68,-9},{88,-29}}, textString = "+1", lineColor = {0,0,255}),Text(extent = {{-90,21},{-70,1}}, textString = "-1", lineColor = {0,0,255}),Line(points = {{-100,0},{84,0}}, color = {95,95,95}),Polygon(points = {{98,0},{82,6},{82,-6},{98,0}}, lineColor = {95,95,95}, fillColor = {95,95,95}, fillPattern = FillPattern.Solid),Line(points = {{-80,-80},{-79.2,-72.8},{-77.6,-67.5},{-73.6,-59.4},{-66.3,-49.8},{-53.5,-37.3},{-30.2,-19.7},{37.4,24.8},{57.5,40.8},{68.7,52.7},{75.2,62.2},{77.6,67.5},{80,80}}, color = {0,0,255}, thickness = 0.5),Text(extent = {{82,24},{102,4}}, lineColor = {95,95,95}, textString = "u"),Line(points = {{0,80},{86,80}}, color = {175,175,175}, smooth = Smooth.None),Line(points = {{80,86},{80,-10}}, color = {175,175,175}, smooth = Smooth.None)}), Documentation(info = "<html>
<p>
This function returns y = asin(u), with -1 &le; u &le; +1:
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Math/asin.png\">
</p>
</html>"));
    end asin;
    function exp "Exponential, base e"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output Real y;

      external "builtin" y = exp(u) ;
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100,-100},{100,100}}), graphics = {Line(points = {{-90,-80.3976},{68,-80.3976}}, color = {192,192,192}),Polygon(points = {{90,-80.3976},{68,-72.3976},{68,-88.3976},{90,-80.3976}}, lineColor = {192,192,192}, fillColor = {192,192,192}, fillPattern = FillPattern.Solid),Line(points = {{-80,-80},{-31,-77.9},{-6.03,-74},{10.9,-68.4},{23.7,-61},{34.2,-51.6},{43,-40.3},{50.3,-27.8},{56.7,-13.5},{62.3,2.23},{67.1,18.6},{72,38.2},{76,57.6},{80,80}}, color = {0,0,0}),Text(extent = {{-86,50},{-14,2}}, lineColor = {192,192,192}, textString = "exp")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100,-100},{100,100}}), graphics = {Line(points = {{-100,-80.3976},{84,-80.3976}}, color = {95,95,95}),Polygon(points = {{98,-80.3976},{82,-74.3976},{82,-86.3976},{98,-80.3976}}, lineColor = {95,95,95}, fillColor = {95,95,95}, fillPattern = FillPattern.Solid),Line(points = {{-80,-80},{-31,-77.9},{-6.03,-74},{10.9,-68.4},{23.7,-61},{34.2,-51.6},{43,-40.3},{50.3,-27.8},{56.7,-13.5},{62.3,2.23},{67.1,18.6},{72,38.2},{76,57.6},{80,80}}, color = {0,0,255}, thickness = 0.5),Text(extent = {{-31,72},{-11,88}}, textString = "20", lineColor = {0,0,255}),Text(extent = {{-92,-81},{-72,-101}}, textString = "-3", lineColor = {0,0,255}),Text(extent = {{66,-81},{86,-101}}, textString = "3", lineColor = {0,0,255}),Text(extent = {{2,-69},{22,-89}}, textString = "1", lineColor = {0,0,255}),Text(extent = {{78,-54},{98,-74}}, lineColor = {95,95,95}, textString = "u"),Line(points = {{0,80},{88,80}}, color = {175,175,175}, smooth = Smooth.None),Line(points = {{80,84},{80,-84}}, color = {175,175,175}, smooth = Smooth.None)}), Documentation(info = "<html>
<p>
This function returns y = exp(u), with -&infin; &lt; u &lt; &infin;:
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Math/exp.png\">
</p>
</html>"));
    end exp;
    function log "Natural (base e) logarithm (u shall be > 0)"
      extends Modelica.Math.Icons.AxisLeft;
      input Real u;
      output Real y;

      external "builtin" y = log(u) ;
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100,-100},{100,100}}), graphics = {Line(points = {{-90,0},{68,0}}, color = {192,192,192}),Polygon(points = {{90,0},{68,8},{68,-8},{90,0}}, lineColor = {192,192,192}, fillColor = {192,192,192}, fillPattern = FillPattern.Solid),Line(points = {{-80,-80},{-79.2,-50.6},{-78.4,-37},{-77.6,-28},{-76.8,-21.3},{-75.2,-11.4},{-72.8,-1.31},{-69.5,8.08},{-64.7,17.9},{-57.5,28},{-47,38.1},{-31.8,48.1},{-10.1,58},{22.1,68},{68.7,78.1},{80,80}}, color = {0,0,0}),Text(extent = {{-6,-24},{66,-72}}, lineColor = {192,192,192}, textString = "log")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100,-100},{100,100}}), graphics = {Line(points = {{-100,0},{84,0}}, color = {95,95,95}),Polygon(points = {{100,0},{84,6},{84,-6},{100,0}}, lineColor = {95,95,95}, fillColor = {95,95,95}, fillPattern = FillPattern.Solid),Line(points = {{-78,-80},{-77.2,-50.6},{-76.4,-37},{-75.6,-28},{-74.8,-21.3},{-73.2,-11.4},{-70.8,-1.31},{-67.5,8.08},{-62.7,17.9},{-55.5,28},{-45,38.1},{-29.8,48.1},{-8.1,58},{24.1,68},{70.7,78.1},{82,80}}, color = {0,0,255}, thickness = 0.5),Text(extent = {{-105,72},{-85,88}}, textString = "3", lineColor = {0,0,255}),Text(extent = {{60,-3},{80,-23}}, textString = "20", lineColor = {0,0,255}),Text(extent = {{-78,-7},{-58,-27}}, textString = "1", lineColor = {0,0,255}),Text(extent = {{84,26},{104,6}}, lineColor = {95,95,95}, textString = "u"),Text(extent = {{-100,9},{-80,-11}}, textString = "0", lineColor = {0,0,255}),Line(points = {{-80,80},{84,80}}, color = {175,175,175}, smooth = Smooth.None),Line(points = {{82,82},{82,-6}}, color = {175,175,175}, smooth = Smooth.None)}), Documentation(info = "<html>
<p>
This function returns y = log(10) (the natural logarithm of u),
with u &gt; 0:
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Math/log.png\">
</p>
</html>"));
    end log;
    annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100,-100},{100,100}}), graphics = {Line(points = {{-80,0},{-68.7,34.2},{-61.5,53.1},{-55.1,66.4},{-49.4,74.6},{-43.8,79.1},{-38.2,79.8},{-32.6,76.6},{-26.9,69.7},{-21.3,59.4},{-14.9,44.1},{-6.83,21.2},{10.1,-30.8},{17.3,-50.2},{23.7,-64.2},{29.3,-73.1},{35,-78.4},{40.6,-80},{46.2,-77.6},{51.9,-71.5},{57.5,-61.9},{63.9,-47.2},{72,-24.8},{80,0}}, color = {0,0,0}, smooth = Smooth.Bezier)}), Documentation(info = "<HTML>
<p>
This package contains <b>basic mathematical functions</b> (such as sin(..)),
as well as functions operating on
<a href=\"modelica://Modelica.Math.Vectors\">vectors</a>,
<a href=\"modelica://Modelica.Math.Matrices\">matrices</a>,
<a href=\"modelica://Modelica.Math.Nonlinear\">nonlinear functions</a>, and
<a href=\"modelica://Modelica.Math.BooleanVectors\">Boolean vectors</a>.
</p>

<dl>
<dt><b>Main Authors:</b>
<dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and
    Marcus Baur<br>
    Deutsches Zentrum f&uuml;r Luft und Raumfahrt e.V. (DLR)<br>
    Institut f&uuml;r Robotik und Mechatronik<br>
    Postfach 1116<br>
    D-82230 Wessling<br>
    Germany<br>
    email: <A HREF=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</A><br>
</dl>

<p>
Copyright &copy; 1998-2013, Modelica Association and DLR.
</p>
<p>
<i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
</p>
</html>", revisions = "<html>
<ul>
<li><i>October 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Function tempInterpol2 added.</li>
<li><i>Oct. 24, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Icons for icon and diagram level introduced.</li>
<li><i>June 30, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.</li>
</ul>

</html>"));
  end Math;
  package Constants "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)"
    import SI = Modelica.SIunits;
    import NonSI = Modelica.SIunits.Conversions.NonSIunits;
    extends Modelica.Icons.Package;
    // Mathematical constants
    final constant Real e = Modelica.Math.exp(1.0);
    final constant Real pi = 2 * Modelica.Math.asin(1.0);
    // 3.14159265358979;
    final constant Real D2R = pi / 180 "Degree to Radian";
    final constant Real R2D = 180 / pi "Radian to Degree";
    final constant Real gamma = 0.577215664901533 "see http://en.wikipedia.org/wiki/Euler_constant";
    // Machine dependent constants
    final constant Real eps = ModelicaServices.Machine.eps "Biggest number such that 1.0 + eps = 1.0";
    final constant Real small = ModelicaServices.Machine.small "Smallest number such that small and -small are representable on the machine";
    final constant Real inf = ModelicaServices.Machine.inf "Biggest Real number such that inf and -inf are representable on the machine";
    final constant Integer Integer_inf = ModelicaServices.Machine.Integer_inf "Biggest Integer number such that Integer_inf and -Integer_inf are representable on the machine";
    // Constants of nature
    // (name, value, description from http://physics.nist.gov/cuu/Constants/)
    final constant SI.Velocity c = 299792458 "Speed of light in vacuum";
    final constant SI.Acceleration g_n = 9.80665 "Standard acceleration of gravity on earth";
    final constant Real G(final unit = "m3/(kg.s2)") = 6.6742e-11 "Newtonian constant of gravitation";
    final constant SI.FaradayConstant F = 96485.3399 "Faraday constant, C/mol";
    final constant Real h(final unit = "J.s") = 6.6260693e-34 "Planck constant";
    final constant Real k(final unit = "J/K") = 1.3806505e-23 "Boltzmann constant";
    final constant Real R(final unit = "J/(mol.K)") = 8.314472 "Molar gas constant";
    final constant Real sigma(final unit = "W/(m2.K4)") = 5.6704e-08 "Stefan-Boltzmann constant";
    final constant Real N_A(final unit = "1/mol") = 6.0221415e+23 "Avogadro constant";
    final constant Real mue_0(final unit = "N/A2") = 4 * pi * 1e-07 "Magnetic constant";
    final constant Real epsilon_0(final unit = "F/m") = 1 / (mue_0 * c * c) "Electric constant";
    final constant NonSI.Temperature_degC T_zero = -273.15 "Absolute zero temperature";
    annotation(Documentation(info = "<html>
<p>
This package provides often needed constants from mathematics, machine
dependent constants and constants from nature. The latter constants
(name, value, description) are from the following source:
</p>

<dl>
<dt>Peter J. Mohr and Barry N. Taylor (1999):</dt>
<dd><b>CODATA Recommended Values of the Fundamental Physical Constants: 1998</b>.
    Journal of Physical and Chemical Reference Data, Vol. 28, No. 6, 1999 and
    Reviews of Modern Physics, Vol. 72, No. 2, 2000. See also <a href=
\"http://physics.nist.gov/cuu/Constants/\">http://physics.nist.gov/cuu/Constants/</a></dd>
</dl>

<p>CODATA is the Committee on Data for Science and Technology.</p>

<dl>
<dt><b>Main Author:</b></dt>
<dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a><br>
    Deutsches Zentrum f&uuml;r Luft und Raumfahrt e. V. (DLR)<br>
    Oberpfaffenhofen<br>
    Postfach 11 16<br>
    D-82230 We&szlig;ling<br>
    email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a></dd>
</dl>

<p>
Copyright &copy; 1998-2013, Modelica Association and DLR.
</p>
<p>
<i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
</p>
</html>", revisions = "<html>
<ul>
<li><i>Nov 8, 2004</i>
       by <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Constants updated according to 2002 CODATA values.</li>
<li><i>Dec 9, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Constants updated according to 1998 CODATA values. Using names, values
       and description text from this source. Included magnetic and
       electric constant.</li>
<li><i>Sep 18, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Constants eps, inf, small introduced.</li>
<li><i>Nov 15, 1997</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.</li>
</ul>
</html>"), Icon(coordinateSystem(extent = {{-100.0,-100.0},{100.0,100.0}}), graphics = {Polygon(origin = {-9.2597,25.6673}, fillColor = {102,102,102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{48.017,11.336},{48.017,11.336},{10.766,11.336},{-25.684,10.95},{-34.944,-15.111},{-34.944,-15.111},{-32.298,-15.244},{-32.298,-15.244},{-22.112,0.168},{11.292,0.234},{48.267,-0.097},{48.267,-0.097}}, smooth = Smooth.Bezier),Polygon(origin = {-19.9923,-8.3993}, fillColor = {102,102,102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{3.239,37.343},{3.305,37.343},{-0.399,2.683},{-16.936,-20.071},{-7.808,-28.604},{6.811,-22.519},{9.986,37.145},{9.986,37.145}}, smooth = Smooth.Bezier),Polygon(origin = {23.753,-11.5422}, fillColor = {102,102,102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-10.873,41.478},{-10.873,41.478},{-14.048,-4.162},{-9.352,-24.8},{7.912,-24.469},{16.247,0.27},{16.247,0.27},{13.336,0.071},{13.336,0.071},{7.515,-9.983},{-3.134,-7.271},{-2.671,41.214},{-2.671,41.214}}, smooth = Smooth.Bezier)}));
  end Constants;
  package Icons "Library of icons"
    extends Icons.Package;
    partial package Package "Icon for standard packages"
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100,-100},{100,100}}), graphics = {Rectangle(lineColor = {200,200,200}, fillColor = {248,248,248}, fillPattern = FillPattern.HorizontalCylinder, extent = {{-100.0,-100.0},{100.0,100.0}}, radius = 25.0),Rectangle(lineColor = {128,128,128}, fillPattern = FillPattern.None, extent = {{-100.0,-100.0},{100.0,100.0}}, radius = 25.0)}), Documentation(info = "<html>
<p>Standard package icon.</p>
</html>"));
    end Package;
    partial package TypesPackage "Icon for packages containing type definitions"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100,-100},{100,100}}), graphics = {Polygon(origin = {-12.167,-23}, fillColor = {128,128,128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{12.167,65},{14.167,93},{36.167,89},{24.167,20},{4.167,-30},{14.167,-30},{24.167,-30},{24.167,-40},{-5.833,-50},{-15.833,-30},{4.167,20},{12.167,65}}, smooth = Smooth.Bezier, lineColor = {0,0,0}),Polygon(origin = {2.7403,1.6673}, fillColor = {128,128,128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{49.2597,22.3327},{31.2597,24.3327},{7.2597,18.3327},{-26.7403,10.3327},{-46.7403,14.3327},{-48.7403,6.3327},{-32.7403,0.3327},{-6.7403,4.3327},{33.2597,14.3327},{49.2597,14.3327},{49.2597,22.3327}}, smooth = Smooth.Bezier)}));
    end TypesPackage;
    partial package IconsPackage "Icon for packages containing icons"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100,-100},{100,100}}), graphics = {Polygon(origin = {-8.167,-17}, fillColor = {128,128,128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-15.833,20.0},{-15.833,30.0},{14.167,40.0},{24.167,20.0},{4.167,-30.0},{14.167,-30.0},{24.167,-30.0},{24.167,-40.0},{-5.833,-50.0},{-15.833,-30.0},{4.167,20.0},{-5.833,20.0}}, smooth = Smooth.Bezier, lineColor = {0,0,0}),Ellipse(origin = {-0.5,56.5}, fillColor = {128,128,128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-12.5,-12.5},{12.5,12.5}}, lineColor = {0,0,0})}));
    end IconsPackage;
    partial package InternalPackage "Icon for an internal package (indicating that the package should not be directly utilized by user)"
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100,-100},{100,100}}), graphics = {Rectangle(lineColor = {215,215,215}, fillColor = {255,255,255}, fillPattern = FillPattern.HorizontalCylinder, extent = {{-100,-100},{100,100}}, radius = 25),Rectangle(lineColor = {215,215,215}, fillPattern = FillPattern.None, extent = {{-100,-100},{100,100}}, radius = 25),Ellipse(extent = {{-80,80},{80,-80}}, lineColor = {215,215,215}, fillColor = {215,215,215}, fillPattern = FillPattern.Solid),Ellipse(extent = {{-55,55},{55,-55}}, lineColor = {255,255,255}, fillColor = {255,255,255}, fillPattern = FillPattern.Solid),Rectangle(extent = {{-60,14},{60,-14}}, lineColor = {215,215,215}, fillColor = {215,215,215}, fillPattern = FillPattern.Solid, origin = {0,0}, rotation = 45)}), Documentation(info = "<html>

<p>
This icon shall be used for a package that contains internal classes not to be
directly utilized by a user.
</p>
</html>"));
    end InternalPackage;
    partial function Function "Icon for functions"
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100,-100},{100,100}}), graphics = {Text(lineColor = {0,0,255}, extent = {{-150,105},{150,145}}, textString = "%name"),Ellipse(lineColor = {108,88,49}, fillColor = {255,215,136}, fillPattern = FillPattern.Solid, extent = {{-100,-100},{100,100}}),Text(lineColor = {108,88,49}, extent = {{-90.0,-90.0},{90.0,90.0}}, textString = "f")}), Documentation(info = "<html>
<p>This icon indicates Modelica functions.</p>
</html>"));
    end Function;
    partial record Record "Icon for records"
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100,-100},{100,100}}), graphics = {Text(lineColor = {0,0,255}, extent = {{-150,60},{150,100}}, textString = "%name"),Rectangle(origin = {0.0,-25.0}, lineColor = {64,64,64}, fillColor = {255,215,136}, fillPattern = FillPattern.Solid, extent = {{-100.0,-75.0},{100.0,75.0}}, radius = 25.0),Line(points = {{-100.0,0.0},{100.0,0.0}}, color = {64,64,64}),Line(origin = {0.0,-50.0}, points = {{-100.0,0.0},{100.0,0.0}}, color = {64,64,64}),Line(origin = {0.0,-25.0}, points = {{0.0,75.0},{0.0,-75.0}}, color = {64,64,64})}), Documentation(info = "<html>
<p>
This icon is indicates a record.
</p>
</html>"));
    end Record;
    partial class ObsoleteModel "Icon for classes that are obsolete and will be removed in later versions"
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100,-100},{100,100}}), graphics = {Rectangle(extent = {{-102,102},{102,-102}}, lineColor = {255,0,0}, pattern = LinePattern.Dash, lineThickness = 0.5)}), Documentation(info = "<html>
<p>
This partial class is intended to provide a <u>default icon
for an obsolete model</u> that will be removed from the
corresponding library in a future release.
</p>
</html>"));
    end ObsoleteModel;
    annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100,-100},{100,100}}), graphics = {Polygon(origin = {-8.167,-17}, fillColor = {128,128,128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-15.833,20.0},{-15.833,30.0},{14.167,40.0},{24.167,20.0},{4.167,-30.0},{14.167,-30.0},{24.167,-30.0},{24.167,-40.0},{-5.833,-50.0},{-15.833,-30.0},{4.167,20.0},{-5.833,20.0}}, smooth = Smooth.Bezier, lineColor = {0,0,0}),Ellipse(origin = {-0.5,56.5}, fillColor = {128,128,128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-12.5,-12.5},{12.5,12.5}}, lineColor = {0,0,0})}), Documentation(info = "<html>
<p>This package contains definitions for the graphical layout of components which may be used in different libraries. The icons can be utilized by inheriting them in the desired class using &quot;extends&quot; or by directly copying the &quot;icon&quot; layer. </p>

<h4>Main Authors:</h4>

<dl>
<dt><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a></dt>
    <dd>Deutsches Zentrum fuer Luft und Raumfahrt e.V. (DLR)</dd>
    <dd>Oberpfaffenhofen</dd>
    <dd>Postfach 1116</dd>
    <dd>D-82230 Wessling</dd>
    <dd>email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a></dd>
<dt>Christian Kral</dt>
    <dd><a href=\"http://www.ait.ac.at/\">Austrian Institute of Technology, AIT</a></dd>
    <dd>Mobility Department</dd><dd>Giefinggasse 2</dd>
    <dd>1210 Vienna, Austria</dd>
    <dd>email: <a href=\"mailto:dr.christian.kral@gmail.com\">dr.christian.kral@gmail.com</a></dd>
<dt>Johan Andreasson</dt>
    <dd><a href=\"http://www.modelon.se/\">Modelon AB</a></dd>
    <dd>Ideon Science Park</dd>
    <dd>22370 Lund, Sweden</dd>
    <dd>email: <a href=\"mailto:johan.andreasson@modelon.se\">johan.andreasson@modelon.se</a></dd>
</dl>

<p>Copyright &copy; 1998-2013, Modelica Association, DLR, AIT, and Modelon AB. </p>
<p><i>This Modelica package is <b>free</b> software; it can be redistributed and/or modified under the terms of the <b>Modelica license</b>, see the license conditions and the accompanying <b>disclaimer</b> in <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a>.</i> </p>
</html>"));
  end Icons;
  package SIunits "Library of type and unit definitions based on SI units according to ISO 31-1992"
    extends Modelica.Icons.Package;
    package Icons "Icons for SIunits"
      extends Modelica.Icons.IconsPackage;
      partial function Conversion "Base icon for conversion functions"
        annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100,-100},{100,100}}), graphics = {Rectangle(extent = {{-100,100},{100,-100}}, lineColor = {191,0,0}, fillColor = {255,255,255}, fillPattern = FillPattern.Solid),Line(points = {{-90,0},{30,0}}, color = {191,0,0}),Polygon(points = {{90,0},{30,20},{30,-20},{90,0}}, lineColor = {191,0,0}, fillColor = {191,0,0}, fillPattern = FillPattern.Solid),Text(extent = {{-115,155},{115,105}}, textString = "%name", lineColor = {0,0,255})}));
      end Conversion;
    end Icons;
    package Conversions "Conversion functions to/from non SI units and type definitions of non SI units"
      extends Modelica.Icons.Package;
      package NonSIunits "Type definitions of non SI units"
        extends Modelica.Icons.Package;
        type Temperature_degC = Real(final quantity = "ThermodynamicTemperature", final unit = "degC") "Absolute temperature in degree Celsius (for relative temperature use SIunits.TemperatureDifference)" annotation(absoluteValue = true);
        type PerArea_cm = Real(final quantity = "PerArea", final unit = "1/cm2") "Per Area in cm";
        type Area_cmPerVoltageSecond = Real(final quantity = "AreaPerVoltageSecond", final unit = "cm2/(V.s)") "Area in cm per voltage second";
        annotation(Documentation(info = "<HTML>
<p>
This package provides predefined types, such as <b>Angle_deg</b> (angle in
degree), <b>AngularVelocity_rpm</b> (angular velocity in revolutions per
minute) or <b>Temperature_degF</b> (temperature in degree Fahrenheit),
which are in common use but are not part of the international standard on
units according to ISO 31-1992 \"General principles concerning quantities,
units and symbols\" and ISO 1000-1992 \"SI units and recommendations for
the use of their multiples and of certain other units\".</p>
<p>If possible, the types in this package should not be used. Use instead
types of package Modelica.SIunits. For more information on units, see also
the book of Francois Cardarelli <b>Scientific Unit Conversion - A
Practical Guide to Metrication</b> (Springer 1997).</p>
<p>Some units, such as <b>Temperature_degC/Temp_C</b> are both defined in
Modelica.SIunits and in Modelica.Conversions.NonSIunits. The reason is that these
definitions have been placed erroneously in Modelica.SIunits although they
are not SIunits. For backward compatibility, these type definitions are
still kept in Modelica.SIunits.</p>
</html>"), Icon(coordinateSystem(extent = {{-100,-100},{100,100}}), graphics = {Text(origin = {15.0,51.8518}, extent = {{-105.0,-86.8518},{75.0,-16.8518}}, lineColor = {0,0,0}, textString = "[km/h]")}));
      end NonSIunits;
      function from_degC "Convert from degCelsius to Kelvin"
        extends Modelica.SIunits.Icons.Conversion;
        input NonSIunits.Temperature_degC Celsius "Celsius value";
        output Temperature Kelvin "Kelvin value";
      algorithm
        Kelvin:=Celsius - Modelica.Constants.T_zero;
        annotation(Inline = true, Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100,-100},{100,100}}), graphics = {Text(extent = {{-20,100},{-100,20}}, lineColor = {0,0,0}, textString = "degC"),Text(extent = {{100,-20},{20,-100}}, lineColor = {0,0,0}, textString = "K")}));
      end from_degC;
      annotation(Documentation(info = "<HTML>
<p>This package provides conversion functions from the non SI Units
defined in package Modelica.SIunits.Conversions.NonSIunits to the
corresponding SI Units defined in package Modelica.SIunits and vice
versa. It is recommended to use these functions in the following
way (note, that all functions have one Real input and one Real output
argument):</p>
<pre>
  <b>import</b> SI = Modelica.SIunits;
  <b>import</b> Modelica.SIunits.Conversions.*;
     ...
  <b>parameter</b> SI.Temperature     T   = from_degC(25);   // convert 25 degree Celsius to Kelvin
  <b>parameter</b> SI.Angle           phi = from_deg(180);   // convert 180 degree to radian
  <b>parameter</b> SI.AngularVelocity w   = from_rpm(3600);  // convert 3600 revolutions per minutes
                                                      // to radian per seconds
</pre>

</html>"));
    end Conversions;
    // Space and Time (chapter 1 of ISO 31-1992)
    type Angle = Real(final quantity = "Angle", final unit = "rad", displayUnit = "deg");
    type Length = Real(final quantity = "Length", final unit = "m");
    type Area = Real(final quantity = "Area", final unit = "m2");
    type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
    type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
    // Periodic and related phenomens (chapter 2 of ISO 31-1992)
    // For compatibility reasons only
    // added to ISO-chapter
    // Mechanics (chapter 3 of ISO 31-1992)
    // added to ISO-chapter 3
    // Heat (chapter 4 of ISO 31-1992)
    type ThermodynamicTemperature = Real(final quantity = "ThermodynamicTemperature", final unit = "K", min = 0.0, start = 288.15, nominal = 300, displayUnit = "degC") "Absolute temperature (use type TemperatureDifference for relative temperatures)" annotation(absoluteValue = true);
    type Temp_K = ThermodynamicTemperature;
    type Temperature = ThermodynamicTemperature;
    type Temp_C = SIunits.Conversions.NonSIunits.Temperature_degC;
    type LinearTemperatureCoefficient = Real(final quantity = "LinearTemperatureCoefficient", final unit = "1/K");
    type HeatCapacity = Real(final quantity = "HeatCapacity", final unit = "J/K");
    // added to ISO-chapter 4
    // Electricity and Magnetism (chapter 5 of ISO 31-1992)
    type ElectricCurrent = Real(final quantity = "ElectricCurrent", final unit = "A");
    type Current = ElectricCurrent;
    type ElectricCharge = Real(final quantity = "ElectricCharge", final unit = "C");
    type Charge = ElectricCharge;
    type ElectricPotential = Real(final quantity = "ElectricPotential", final unit = "V");
    type Voltage = ElectricPotential;
    type Capacitance = Real(final quantity = "Capacitance", final unit = "F", min = 0);
    type CapacitancePerArea = Real(final quantity = "CapacitancePerArea", final unit = "F/m2") "Capacitance per area";
    type Permittivity = Real(final quantity = "Permittivity", final unit = "F/m", min = 0);
    type CurrentDensity = Real(final quantity = "CurrentDensity", final unit = "A/m2");
    type Resistance = Real(final quantity = "Resistance", final unit = "Ohm");
    type Conductance = Real(final quantity = "Conductance", final unit = "S");
    // added to ISO-chapter 5
    type Transconductance = Real(final quantity = "Transconductance", final unit = "A/V2");
    type InversePotential = Real(final quantity = "InversePotential", final unit = "1/V");
    // Light and Related Electromagnetic Radiations (chapter 6 of ISO 31-1992)"
    // Acoustics (chapter 7 of ISO 31-1992)
    // Physical chemistry and molecular physics (chapter 8 of ISO 31-1992)
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
    // Atomic and Nuclear Physics (chapter 9 of ISO 31-1992)
    // Nuclear Reactions and Ionizing Radiations (chapter 10 of ISO 31-1992)
    // chapter 11 is not defined in ISO 31-1992
    // Characteristic Numbers (chapter 12 of ISO 31-1992)
    // The Biot number (Bi) is used when
    // the Nusselt number is reserved
    // for convective transport of heat.
    // Solid State Physics (chapter 13 of ISO 31-1992)
    type GapEnergy = Real(final quantity = "Energy", final unit = "eV");
    // Other types not defined in ISO 31-1992
    // Complex types for electrical systems (not defined in ISO 31-1992)
    annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100,-100},{100,100}}), graphics = {Line(points = {{-66,78},{-66,-40}}, color = {64,64,64}, smooth = Smooth.None),Ellipse(extent = {{12,36},{68,-38}}, lineColor = {64,64,64}, fillColor = {175,175,175}, fillPattern = FillPattern.Solid),Rectangle(extent = {{-74,78},{-66,-40}}, lineColor = {64,64,64}, fillColor = {175,175,175}, fillPattern = FillPattern.Solid),Polygon(points = {{-66,-4},{-66,6},{-16,56},{-16,46},{-66,-4}}, lineColor = {64,64,64}, smooth = Smooth.None, fillColor = {175,175,175}, fillPattern = FillPattern.Solid),Polygon(points = {{-46,16},{-40,22},{-2,-40},{-10,-40},{-46,16}}, lineColor = {64,64,64}, smooth = Smooth.None, fillColor = {175,175,175}, fillPattern = FillPattern.Solid),Ellipse(extent = {{22,26},{58,-28}}, lineColor = {64,64,64}, fillColor = {255,255,255}, fillPattern = FillPattern.Solid),Polygon(points = {{68,2},{68,-46},{64,-60},{58,-68},{48,-72},{18,-72},{18,-64},{46,-64},{54,-60},{58,-54},{60,-46},{60,-26},{64,-20},{68,-6},{68,2}}, lineColor = {64,64,64}, smooth = Smooth.Bezier, fillColor = {175,175,175}, fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
<p>This package provides predefined types, such as <i>Mass</i>,
<i>Angle</i>, <i>Time</i>, based on the international standard
on units, e.g.,
</p>

<pre>   <b>type</b> Angle = Real(<b>final</b> quantity = \"Angle\",
                     <b>final</b> unit     = \"rad\",
                     displayUnit    = \"deg\");
</pre>

<p>
as well as conversion functions from non SI-units to SI-units
and vice versa in subpackage
<a href=\"modelica://Modelica.SIunits.Conversions\">Conversions</a>.
</p>

<p>
For an introduction how units are used in the Modelica standard library
with package SIunits, have a look at:
<a href=\"modelica://Modelica.SIunits.UsersGuide.HowToUseSIunits\">How to use SIunits</a>.
</p>

<p>
Copyright &copy; 1998-2013, Modelica Association and DLR.
</p>
<p>
<i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
</p>
</html>", revisions = "<html>
<ul>
<li><i>May 25, 2011</i> by Stefan Wischhusen:<br/>Added molar units for energy and enthalpy.</li>
<li><i>Jan. 27, 2010</i> by Christian Kral:<br/>Added complex units.</li>
<li><i>Dec. 14, 2005</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Add User&#39;;s Guide and removed &quot;min&quot; values for Resistance and Conductance.</li>
<li><i>October 21, 2002</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br/>Added new package <b>Conversions</b>. Corrected typo <i>Wavelenght</i>.</li>
<li><i>June 6, 2000</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Introduced the following new types<br/>type Temperature = ThermodynamicTemperature;<br/>types DerDensityByEnthalpy, DerDensityByPressure, DerDensityByTemperature, DerEnthalpyByPressure, DerEnergyByDensity, DerEnergyByPressure<br/>Attribute &quot;final&quot; removed from min and max values in order that these values can still be changed to narrow the allowed range of values.<br/>Quantity=&quot;Stress&quot; removed from type &quot;Stress&quot;, in order that a type &quot;Stress&quot; can be connected to a type &quot;Pressure&quot;.</li>
<li><i>Oct. 27, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>New types due to electrical library: Transconductance, InversePotential, Damping.</li>
<li><i>Sept. 18, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Renamed from SIunit to SIunits. Subpackages expanded, i.e., the SIunits package, does no longer contain subpackages.</li>
<li><i>Aug 12, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Type &quot;Pressure&quot; renamed to &quot;AbsolutePressure&quot; and introduced a new type &quot;Pressure&quot; which does not contain a minimum of zero in order to allow convenient handling of relative pressure. Redefined BulkModulus as an alias to AbsolutePressure instead of Stress, since needed in hydraulics.</li>
<li><i>June 29, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Bug-fix: Double definition of &quot;Compressibility&quot; removed and appropriate &quot;extends Heat&quot; clause introduced in package SolidStatePhysics to incorporate ThermodynamicTemperature.</li>
<li><i>April 8, 1998</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and Astrid Jaschinski:<br/>Complete ISO 31 chapters realized.</li>
<li><i>Nov. 15, 1997</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>:<br/>Some chapters realized.</li>
</ul>
</html>"));
  end SIunits;
  annotation(__Wolfram(totalModelPart = true, totalModelId = "df0df591-b2fc-48fd-98a5-c152097c5298"), preferredView = "info", version = "3.2.1", versionBuild = 2, versionDate = "2013-08-14", dateModified = "2013-08-14 08:44:41Z", revisionId = "$Id:: package.mo 6931 2013-08-14 11:38:51Z #$", uses(Complex(version = "3.2.1"), ModelicaServices(version = "3.2.1")), conversion(noneFromVersion = "3.2", noneFromVersion = "3.1", noneFromVersion = "3.0.1", noneFromVersion = "3.0", from(version = "2.1", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2.1", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2.2", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos")), Icon(coordinateSystem(extent = {{-100.0,-100.0},{100.0,100.0}}), graphics = {Polygon(origin = {-6.9888,20.048}, fillColor = {0,0,0}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-93.0112,10.3188},{-93.0112,10.3188},{-73.011,24.6},{-63.011,31.221},{-51.219,36.777},{-39.842,38.629},{-31.376,36.248},{-25.819,29.369},{-24.232,22.49},{-23.703,17.463},{-15.501,25.135},{-6.24,32.015},{3.02,36.777},{15.191,39.423},{27.097,37.306},{32.653,29.633},{35.035,20.108},{43.501,28.046},{54.085,35.19},{65.991,39.952},{77.897,39.688},{87.422,33.338},{91.126,21.696},{90.068,9.525},{86.099,-1.058},{79.749,-10.054},{71.283,-21.431},{62.816,-33.337},{60.964,-32.808},{70.489,-16.14},{77.368,-2.381},{81.072,10.054},{79.749,19.05},{72.605,24.342},{61.758,23.019},{49.587,14.817},{39.003,4.763},{29.214,-6.085},{21.012,-16.669},{13.339,-26.458},{5.401,-36.777},{-1.213,-46.037},{-6.24,-53.446},{-8.092,-52.387},{-0.684,-40.746},{5.401,-30.692},{12.81,-17.198},{19.424,-3.969},{23.658,7.938},{22.335,18.785},{16.514,23.283},{8.047,23.019},{-1.478,19.05},{-11.267,11.113},{-19.734,2.381},{-29.259,-8.202},{-38.519,-19.579},{-48.044,-31.221},{-56.511,-43.392},{-64.449,-55.298},{-72.386,-66.939},{-77.678,-74.612},{-79.53,-74.083},{-71.857,-61.383},{-62.861,-46.037},{-52.278,-28.046},{-44.869,-15.346},{-38.784,-2.117},{-35.344,8.731},{-36.403,19.844},{-42.488,23.813},{-52.013,22.49},{-60.744,16.933},{-68.947,10.054},{-76.884,2.646},{-93.0112,-12.1707},{-93.0112,-12.1707}}, smooth = Smooth.Bezier),Ellipse(origin = {40.8208,-37.7602}, fillColor = {161,0,4}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-17.8562,-17.8563},{17.8563,17.8562}})}), Documentation(info = "<HTML>
<p>
Package <b>Modelica&reg;</b> is a <b>standardized</b> and <b>free</b> package
that is developed together with the Modelica&reg; language from the
Modelica Association, see
<a href=\"https://www.Modelica.org\">https://www.Modelica.org</a>.
It is also called <b>Modelica Standard Library</b>.
It provides model components in many domains that are based on
standardized interface definitions. Some typical examples are shown
in the next figure:
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/UsersGuide/ModelicaLibraries.png\">
</p>

<p>
For an introduction, have especially a look at:
</p>
<ul>
<li> <a href=\"modelica://Modelica.UsersGuide.Overview\">Overview</a>
  provides an overview of the Modelica Standard Library
  inside the <a href=\"modelica://Modelica.UsersGuide\">User's Guide</a>.</li>
<li><a href=\"modelica://Modelica.UsersGuide.ReleaseNotes\">Release Notes</a>
 summarizes the changes of new versions of this package.</li>
<li> <a href=\"modelica://Modelica.UsersGuide.Contact\">Contact</a>
  lists the contributors of the Modelica Standard Library.</li>
<li> The <b>Examples</b> packages in the various libraries, demonstrate
  how to use the components of the corresponding sublibrary.</li>
</ul>

<p>
This version of the Modelica Standard Library consists of
</p>
<ul>
<li><b>1360</b> models and blocks, and</li>
<li><b>1280</b> functions</li>
</ul>
<p>
that are directly usable (= number of public, non-partial classes). It is fully compliant
to <a href=\"https://www.modelica.org/documents/ModelicaSpec32Revision2.pdf\">Modelica Specification Version 3.2 Revision 2</a>
and it has been tested with Modelica tools from different vendors.
</p>

<p>
<b>Licensed by the Modelica Association under the Modelica License 2</b><br>
Copyright &copy; 1998-2013, ABB, AIT, T.&nbsp;B&ouml;drich, DLR, Dassault Syst&egrave;mes AB, Fraunhofer, A.Haumer, ITI, Modelon,
TU Hamburg-Harburg, Politecnico di Milano, XRG Simulation.
</p>

<p>
<i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
</p>

<p>
<b>Modelica&reg;</b> is a registered trademark of the Modelica Association.
</p>
</html>"));
end Modelica;
package ModelicaServices "ModelicaServices (Default implementation) - Models and functions used in the Modelica Standard Library requiring a tool specific implementation"
  extends Modelica.Icons.Package;
  constant String target = "Default" "Target of this ModelicaServices implementation";
  package Machine
    // Machine dependent constants
    extends Modelica.Icons.Package;
    final constant Real eps = 1e-15 "Biggest number such that 1.0 + eps = 1.0";
    final constant Real small = 1e-60 "Smallest number such that small and -small are representable on the machine";
    final constant Real inf = 1e+60 "Biggest Real number such that inf and -inf are representable on the machine";
    final constant Integer Integer_inf = 1073741823 "Biggest Integer number such that Integer_inf and -Integer_inf are representable on the machine";
    annotation(Documentation(info = "<html>
<p>
Package in which processor specific constants are defined that are needed
by numerical algorithms. Typically these constants are not directly used,
but indirectly via the alias definition in
<a href=\"modelica://Modelica.Constants\">Modelica.Constants</a>.
</p>
</html>"));
  end Machine;
  annotation(__Wolfram(totalModelPart = true, totalModelId = "df0df591-b2fc-48fd-98a5-c152097c5298"), Protection(access = Access.hide), preferredView = "info", version = "3.2.1", versionBuild = 2, versionDate = "2013-08-14", dateModified = "2013-08-14 08:44:41Z", revisionId = "$Id:: package.mo 6931 2013-08-14 11:38:51Z #$", uses(Modelica(version = "3.2.1")), conversion(noneFromVersion = "1.0", noneFromVersion = "1.1", noneFromVersion = "1.2"), Documentation(info = "<html>
<p>
This package contains a set of functions and models to be used in the
Modelica Standard Library that requires a tool specific implementation.
These are:
</p>

<ul>
<li> <a href=\"modelica://ModelicaServices.Animation.Shape\">Shape</a>
     provides a 3-dim. visualization of elementary
     mechanical objects. It is used in
<a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape</a>
     via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.Animation.Surface\">Surface</a>
     provides a 3-dim. visualization of
     moveable parameterized surface. It is used in
<a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Surface\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Surface</a>
     via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.ExternalReferences.loadResource\">loadResource</a>
     provides a function to return the absolute path name of an URI or a local file name. It is used in
<a href=\"modelica://Modelica.Utilities.Files.loadResource\">Modelica.Utilities.Files.loadResource</a>
     via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.Machine\">ModelicaServices.Machine</a>
     provides a package of machine constants. It is used in
<a href=\"modelica://Modelica.Constants\">Modelica.Constants</a>.</li>

<li> <a href=\"modelica://ModelicaServices.Types.SolverMethod\">Types.SolverMethod</a>
     provides a string defining the integration method to solve differential equations in
     a clocked discretized continuous-time partition (see Modelica 3.3 language specification).
     It is not yet used in the Modelica Standard Library, but in the Modelica_Synchronous library
     that provides convenience blocks for the clock operators of Modelica version &ge; 3.3.</li>
</ul>

<p>
This is the default implementation, if no tool-specific implementation is available.
This ModelicaServices package provides only \"dummy\" models that do nothing.
</p>

<p>
<b>Licensed by DLR and Dassault Syst&egrave;mes AB under the Modelica License 2</b><br>
Copyright &copy; 2009-2013, DLR and Dassault Syst&egrave;mes AB.
</p>

<p>
<i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
</p>

</html>"));
end ModelicaServices;
model A
  import SI = Modelica.SIunits;
  constant SI.Length L = 0.0001 "Length";
  constant SI.Length W = 0.0001 "Width";
  constant SI.Area AD = 0 "Area of the drain diffusion";
  constant SI.Area AS = 0 "Area of the source diffusion";
  constant SI.Length PD = 0 "Perimeter of the drain junction";
  constant SI.Length PS = 0 "Perimeter of the source junction";
  constant Real NRD = 1 "Number of squares of the drain diffusions";
  constant Real NRS = 1 "Number of squares of the source diffusions";
  constant Integer OFF = 0 "Optional initial condition: 0 - IC not used, 1 - IC used, not implemented yet";
  constant SI.Voltage IC = -1e+40 "Initial condition values, not implemented yet";
  constant SI.Temp_C TEMP = 27 "Operating temperature of the device";
  constant Modelica.Electrical.Spice3.Internal.ModelcardMOS modelcard;
  constant Modelica.Electrical.Spice3.Internal.SpiceConstants C;
  constant Integer m_type = 1;
  constant Boolean m_bInit = false;
  constant Modelica.Electrical.Spice3.Internal.Mos1.Mos1ModelLineParams p = Modelica.Electrical.Spice3.Internal.Mos1.mos1RenameParameters(modelcard, C) "Model line parameters";
  constant Modelica.Electrical.Spice3.Internal.Mosfet.Mosfet m = Modelica.Electrical.Spice3.Internal.Mos1.mos1RenameParametersDev(modelcard, m_type, W, L, AS, AS, PD, PS, NRD, NRS, OFF, IC, TEMP) "Renamed parameters";
  //constant Integer m_type = if m.m_bPMOS > 0.5 then -1 else 1 "Type of the transistor";
  constant Modelica.Electrical.Spice3.Internal.Mos.MosModelLineVariables vp = Modelica.Electrical.Spice3.Internal.Mos1.mos1ModelLineParamsInitEquations(p, C, m_type) "Model line variables";
  constant Modelica.Electrical.Spice3.Internal.Mos1.Mos1Calc c1 = Modelica.Electrical.Spice3.Internal.Mos.mosCalcInitEquations(p, C, vp, m) "Precalculated parameters";
  constant Modelica.Electrical.Spice3.Internal.Mos1.Mos1Calc c2 = Modelica.Electrical.Spice3.Internal.Mos.mosCalcCalcTempDependencies(p, C, vp, m, c1, m_type) "Precalculated parameters";
  constant Modelica.Electrical.Spice3.Internal.Mos.CurrrentsCapacitances cc = Modelica.Electrical.Spice3.Internal.Mos.mosCalcNoBypassCode(m, m_type, c2, p, C, vp, m_bInit, {1.0,1.0,1.0,1.0});
  annotation(__Wolfram(totalModelMain = true, totalModelId = "df0df591-b2fc-48fd-98a5-c152097c5298"), Diagram(coordinateSystem(extent = {{-148.5,-105},{148.5,105}}, preserveAspectRatio = true, initialScale = 0.1, grid = {5,5})));
end A;

