package Buildings  "Library with models for building energy and control systems"
  extends Modelica.Icons.Package;

  package BoundaryConditions  "Package with models for boundary conditions"
    extends Modelica.Icons.Package;

    package SkyTemperature  "Package with models to compute the sky temperature"
      extends Modelica.Icons.VariantsPackage;

      block BlackBody  "Calculate black body sky temperature"
        extends Modelica.Blocks.Icons.Block;
        parameter Buildings.BoundaryConditions.Types.SkyTemperatureCalculation calTSky = .Buildings.BoundaryConditions.Types.SkyTemperatureCalculation.TemperaturesAndSkyCover "Computation of black-body sky temperature" annotation(choicesAllMatching = true, Evaluate = true);
        Modelica.Blocks.Interfaces.RealInput TDryBul(final quantity = "ThermodynamicTemperature", final unit = "K", displayUnit = "degC") "Dry bulb temperature at ground level";
        Modelica.Blocks.Interfaces.RealInput TDewPoi(final quantity = "ThermodynamicTemperature", final unit = "K", displayUnit = "degC") "Dew point temperature";
        Modelica.Blocks.Interfaces.RealInput nOpa(min = 0, max = 1, unit = "1") "Opaque sky cover [0, 1]";
        Modelica.Blocks.Interfaces.RealOutput TBlaSky(final quantity = "ThermodynamicTemperature", displayUnit = "degC", final unit = "K") "Black-body sky temperature";
        Modelica.Blocks.Interfaces.RealInput HHorIR(unit = "W/m2", min = 0, nominal = 100) "Horizontal infrared irradiation";
      protected
        Modelica.SIunits.Temperature TDewPoiK "Dewpoint temperature";
        Modelica.SIunits.Emissivity epsSky "Black-body absorptivity of sky";
        Real nOpa10(min = 0, max = 10) "Opaque sky cover in [0, 10]";
      equation
        if calTSky == Buildings.BoundaryConditions.Types.SkyTemperatureCalculation.TemperaturesAndSkyCover then
          TDewPoiK = Buildings.Utilities.Math.Functions.smoothMin(TDryBul, TDewPoi, 0.1);
          nOpa10 = 10 * nOpa "Input nOpa is scaled to [0,1] instead of [0,10]";
          epsSky = (0.787 + 0.764 * Modelica.Math.log(-TDewPoiK / Modelica.Constants.T_zero)) * (1 + 0.0224 * nOpa10 - 0.0035 * nOpa10 ^ 2 + 0.00028 * nOpa10 ^ 3);
          TBlaSky = TDryBul * epsSky ^ 0.25;
        else
          TDewPoiK = 273.15;
          nOpa10 = 0.0;
          epsSky = 0.0;
          TBlaSky = (HHorIR / Modelica.Constants.sigma) ^ 0.25;
        end if;
      end BlackBody;
    end SkyTemperature;

    package SolarGeometry  "Package with models to compute solar geometry"
      extends Modelica.Icons.VariantsPackage;

      package BaseClasses  "Package with base classes for Buildings.BoundaryConditions.SolarGeometry"
        extends Modelica.Icons.BasesPackage;

        block AltitudeAngle  "Solar altitude angle"
          extends Modelica.Blocks.Icons.Block;
          Modelica.Blocks.Interfaces.RealInput zen(quantity = "Angle", unit = "rad") "Zenith angle";
          Modelica.Blocks.Interfaces.RealOutput alt(final quantity = "Angle", final unit = "rad", displayUnit = "deg") "Solar altitude angle";
        equation
          alt = Modelica.Constants.pi / 2 - zen;
        end AltitudeAngle;

        block Declination  "Declination angle"
          extends Modelica.Blocks.Icons.Block;
          Modelica.Blocks.Interfaces.RealInput nDay(quantity = "Time", unit = "s") "Day number with units of seconds";
          Modelica.Blocks.Interfaces.RealOutput decAng(final quantity = "Angle", final unit = "rad", displayUnit = "deg") "Solar declination angle";
        protected
          constant Real k1 = sin(23.45 * 2 * Modelica.Constants.pi / 360) "Constant";
          constant Real k2 = 2 * Modelica.Constants.pi / 365.25 "Constant";
        equation
          decAng = Modelica.Math.asin(-k1 * Modelica.Math.cos((nDay / 86400 + 10) * k2)) "(A4.5)";
        end Declination;

        block SolarHourAngle  "Solar hour angle"
          extends Modelica.Blocks.Icons.Block;
          Modelica.Blocks.Interfaces.RealInput solTim(quantity = "Time", unit = "s") "Solar time";
          Modelica.Blocks.Interfaces.RealOutput solHouAng(final quantity = "Angle", final unit = "rad", displayUnit = "deg") "Solar hour angle";
        equation
          solHouAng = (solTim / 3600 - 12) * 2 * Modelica.Constants.pi / 24 "Our unit is s instead of h in (A4.6)";
        end SolarHourAngle;

        block ZenithAngle  "Zenith angle"
          extends Modelica.Blocks.Icons.Block;
          parameter Modelica.SIunits.Angle lat "Latitude";
          Modelica.Blocks.Interfaces.RealInput solHouAng(quantity = "Angle", unit = "rad") "Solar hour angle";
          Modelica.Blocks.Interfaces.RealInput decAng(quantity = "Angle", unit = "rad") "Solar declination angle";
          Modelica.Blocks.Interfaces.RealOutput zen(final quantity = "Angle", final unit = "rad", displayUnit = "deg") "Zenith angle";
        equation
          zen = Modelica.Math.acos(Modelica.Math.cos(lat) * Modelica.Math.cos(decAng) * Modelica.Math.cos(solHouAng) + Modelica.Math.sin(lat) * Modelica.Math.sin(decAng)) "(A4.8)";
        end ZenithAngle;
      end BaseClasses;
    end SolarGeometry;

    package WeatherData  "Weather data reader"
      extends Modelica.Icons.VariantsPackage;

      expandable connector Bus  "Data bus that stores weather data"
        extends Modelica.Icons.SignalBus;
      end Bus;

      block ReaderTMY3  "Reader for TMY3 weather data"
        parameter Boolean computeWetBulbTemperature = true "If true, then this model computes the wet bulb temperature" annotation(Evaluate = true);
        parameter Buildings.BoundaryConditions.Types.DataSource pAtmSou = Buildings.BoundaryConditions.Types.DataSource.Parameter "Atmospheric pressure" annotation(Evaluate = true);
        parameter Modelica.SIunits.Pressure pAtm = 101325 "Atmospheric pressure (used if pAtmSou=Parameter)";
        Modelica.Blocks.Interfaces.RealInput pAtm_in(final quantity = "Pressure", final unit = "Pa", displayUnit = "Pa") if pAtmSou == Buildings.BoundaryConditions.Types.DataSource.Input "Input pressure";
        parameter Buildings.BoundaryConditions.Types.DataSource ceiHeiSou = Buildings.BoundaryConditions.Types.DataSource.File "Ceiling height" annotation(Evaluate = true);
        parameter Real ceiHei(final quantity = "Height", final unit = "m", displayUnit = "m") = 20000 "Ceiling height (used if ceiHei=Parameter)";
        Modelica.Blocks.Interfaces.RealInput ceiHei_in(final quantity = "Height", final unit = "m", displayUnit = "m") if ceiHeiSou == Buildings.BoundaryConditions.Types.DataSource.Input "Input ceiling height";
        parameter Buildings.BoundaryConditions.Types.DataSource totSkyCovSou = Buildings.BoundaryConditions.Types.DataSource.File "Total sky cover" annotation(Evaluate = true);
        parameter Real totSkyCov(min = 0, max = 1, unit = "1") = 0.5 "Total sky cover (used if totSkyCov=Parameter). Use 0 <= totSkyCov <= 1";
        Modelica.Blocks.Interfaces.RealInput totSkyCov_in(min = 0, max = 1, unit = "1") if totSkyCovSou == Buildings.BoundaryConditions.Types.DataSource.Input "Input total sky cover";
        parameter Buildings.BoundaryConditions.Types.DataSource opaSkyCovSou = Buildings.BoundaryConditions.Types.DataSource.File "Opaque sky cover" annotation(Evaluate = true);
        parameter Real opaSkyCov(min = 0, max = 1, unit = "1") = 0.5 "Opaque sky cover (used if opaSkyCov=Parameter). Use 0 <= opaSkyCov <= 1";
        Modelica.Blocks.Interfaces.RealInput opaSkyCov_in(min = 0, max = 1, unit = "1") if opaSkyCovSou == Buildings.BoundaryConditions.Types.DataSource.Input "Input opaque sky cover";
        parameter Buildings.BoundaryConditions.Types.DataSource TDryBulSou = Buildings.BoundaryConditions.Types.DataSource.File "Dry bulb temperature" annotation(Evaluate = true);
        parameter Modelica.SIunits.Temperature TDryBul(displayUnit = "degC") = 293.15 "Dry bulb temperature (used if TDryBul=Parameter)";
        Modelica.Blocks.Interfaces.RealInput TDryBul_in(final quantity = "ThermodynamicTemperature", final unit = "K", displayUnit = "degC") if TDryBulSou == Buildings.BoundaryConditions.Types.DataSource.Input "Input dry bulb temperature";
        parameter Buildings.BoundaryConditions.Types.DataSource TDewPoiSou = Buildings.BoundaryConditions.Types.DataSource.File "Dew point temperature" annotation(Evaluate = true);
        parameter Modelica.SIunits.Temperature TDewPoi(displayUnit = "degC") = 283.15 "Dew point temperature (used if TDewPoi=Parameter)";
        Modelica.Blocks.Interfaces.RealInput TDewPoi_in(final quantity = "ThermodynamicTemperature", final unit = "K", displayUnit = "degC") if TDewPoiSou == Buildings.BoundaryConditions.Types.DataSource.Input "Input dew point temperature";
        parameter Buildings.BoundaryConditions.Types.DataSource TBlaSkySou = Buildings.BoundaryConditions.Types.DataSource.File "Black-body sky temperature" annotation(Evaluate = true);
        parameter Modelica.SIunits.Temperature TBlaSky = 273.15 "Black-body sky temperature (used if TBlaSkySou=Parameter)";
        Modelica.Blocks.Interfaces.RealInput TBlaSky_in(final quantity = "ThermodynamicTemperature", displayUnit = "degC", final unit = "K") if TBlaSkySou == Buildings.BoundaryConditions.Types.DataSource.Input "Black-body sky temperature";
        parameter Buildings.BoundaryConditions.Types.DataSource relHumSou = Buildings.BoundaryConditions.Types.DataSource.File "Relative humidity" annotation(Evaluate = true);
        parameter Real relHum(min = 0, max = 1, unit = "1") = 0.5 "Relative humidity (used if relHum=Parameter)";
        Modelica.Blocks.Interfaces.RealInput relHum_in(min = 0, max = 1, unit = "1") if relHumSou == Buildings.BoundaryConditions.Types.DataSource.Input "Input relative humidity";
        parameter Buildings.BoundaryConditions.Types.DataSource winSpeSou = Buildings.BoundaryConditions.Types.DataSource.File "Wind speed" annotation(Evaluate = true);
        parameter Modelica.SIunits.Velocity winSpe(min = 0) = 1 "Wind speed (used if winSpe=Parameter)";
        Modelica.Blocks.Interfaces.RealInput winSpe_in(final quantity = "Velocity", final unit = "m/s", min = 0) if winSpeSou == Buildings.BoundaryConditions.Types.DataSource.Input "Input wind speed";
        parameter Buildings.BoundaryConditions.Types.DataSource winDirSou = Buildings.BoundaryConditions.Types.DataSource.File "Wind direction" annotation(Evaluate = true);
        parameter Modelica.SIunits.Angle winDir = 1.0 "Wind direction (used if winDir=Parameter)";
        Modelica.Blocks.Interfaces.RealInput winDir_in(final quantity = "Angle", final unit = "rad", displayUnit = "deg") if winDirSou == Buildings.BoundaryConditions.Types.DataSource.Input "Input wind direction";
        parameter Buildings.BoundaryConditions.Types.DataSource HInfHorSou = Buildings.BoundaryConditions.Types.DataSource.File "Infrared horizontal radiation" annotation(Evaluate = true);
        parameter Modelica.SIunits.HeatFlux HInfHor = 0.0 "Infrared horizontal radiation (used if HInfHorSou=Parameter)";
        Modelica.Blocks.Interfaces.RealInput HInfHor_in(final quantity = "RadiantEnergyFluenceRate", final unit = "W/m2") if HInfHorSou == Buildings.BoundaryConditions.Types.DataSource.Input "Input infrared horizontal radiation";
        parameter Buildings.BoundaryConditions.Types.RadiationDataSource HSou = Buildings.BoundaryConditions.Types.RadiationDataSource.File "Global, diffuse, and direct normal radiation" annotation(Evaluate = true);
        Modelica.Blocks.Interfaces.RealInput HGloHor_in(final quantity = "RadiantEnergyFluenceRate", final unit = "W/m2") if HSou == Buildings.BoundaryConditions.Types.RadiationDataSource.Input_HGloHor_HDifHor or HSou == Buildings.BoundaryConditions.Types.RadiationDataSource.Input_HDirNor_HGloHor "Input global horizontal radiation";
        Modelica.Blocks.Interfaces.RealInput HDifHor_in(final quantity = "RadiantEnergyFluenceRate", final unit = "W/m2") if HSou == Buildings.BoundaryConditions.Types.RadiationDataSource.Input_HGloHor_HDifHor or HSou == Buildings.BoundaryConditions.Types.RadiationDataSource.Input_HDirNor_HDifHor "Input diffuse horizontal radiation";
        Modelica.Blocks.Interfaces.RealInput HDirNor_in(final quantity = "RadiantEnergyFluenceRate", final unit = "W/m2") if HSou == Buildings.BoundaryConditions.Types.RadiationDataSource.Input_HDirNor_HDifHor or HSou == Buildings.BoundaryConditions.Types.RadiationDataSource.Input_HDirNor_HGloHor "Input direct normal radiation";
        parameter String filNam = "" "Name of weather data file";
        final parameter Modelica.SIunits.Angle lon(displayUnit = "deg") = BaseClasses.getLongitudeTMY3(absFilNam) "Longitude";
        final parameter Modelica.SIunits.Angle lat(displayUnit = "deg") = BaseClasses.getLatitudeTMY3(absFilNam) "Latitude";
        final parameter Modelica.SIunits.Time timZon(displayUnit = "h") = BaseClasses.getTimeZoneTMY3(absFilNam) "Time zone";
        Bus weaBus "Weather data bus";
        parameter Buildings.BoundaryConditions.Types.SkyTemperatureCalculation calTSky = Buildings.BoundaryConditions.Types.SkyTemperatureCalculation.TemperaturesAndSkyCover "Computation of black-body sky temperature" annotation(choicesAllMatching = true, Evaluate = true);
        constant Real epsCos = 1e-6 "Small value to avoid division by 0";
        constant Modelica.SIunits.HeatFlux solCon = 1367.7 "Solar constant";
      protected
        final parameter String absFilNam = BaseClasses.getAbsolutePath(filNam) "Absolute path of the file";
        Modelica.Blocks.Tables.CombiTable1Ds datRea(verboseRead = false, final tableOnFile = true, final tableName = "tab1", final fileName = absFilNam, final smoothness = Modelica.Blocks.Types.Smoothness.ContinuousDerivative, final columns = {2, 3, 4, 5, 6, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30}) "Data reader";
        Buildings.BoundaryConditions.WeatherData.BaseClasses.CheckTemperature cheTemDryBul "Check dry bulb temperature ";
        Buildings.BoundaryConditions.WeatherData.BaseClasses.CheckTemperature cheTemDewPoi "Check dew point temperature";
        Buildings.BoundaryConditions.WeatherData.BaseClasses.ConvertRelativeHumidity conRelHum "Convert the relative humidity from percentage to [0, 1] ";
        BaseClasses.CheckPressure chePre "Check the air pressure";
        BaseClasses.CheckSkyCover cheTotSkyCov "Check the total sky cover";
        BaseClasses.CheckSkyCover cheOpaSkyCov "Check the opaque sky cover";
        BaseClasses.CheckRadiation cheGloHorRad "Check the global horizontal radiation";
        BaseClasses.CheckRadiation cheDifHorRad "Check the diffuse horizontal radiation";
        BaseClasses.CheckRadiation cheDirNorRad "Check the direct normal radiation";
        BaseClasses.CheckCeilingHeight cheCeiHei "Check the ceiling height";
        BaseClasses.CheckWindSpeed cheWinSpe "Check the wind speed";
        BaseClasses.CheckIRRadiation cheHorRad "Check the horizontal infrared irradiation";
        BaseClasses.CheckWindDirection cheWinDir "Check the wind direction";
        SkyTemperature.BlackBody TBlaSkyCom(final calTSky = calTSky) if not (TBlaSkySou == Buildings.BoundaryConditions.Types.DataSource.Parameter or TBlaSkySou == Buildings.BoundaryConditions.Types.DataSource.Input) "Computation of the black-body sky temperature";
        Utilities.Time.ModelTime modTim "Model time";
        Modelica.Blocks.Math.Add add "Add 30 minutes to time to shift weather data reader";
        Modelica.Blocks.Sources.Constant con30mins(final k = 1800) "Constant used to shift weather data reader";
        Buildings.BoundaryConditions.WeatherData.BaseClasses.LocalCivilTime locTim(final lon = lon, final timZon = timZon) "Local civil time";
        Modelica.Blocks.Tables.CombiTable1Ds datRea1(verboseRead = false, final tableOnFile = true, final tableName = "tab1", final fileName = absFilNam, final smoothness = Modelica.Blocks.Types.Smoothness.ContinuousDerivative, final columns = 8:11) "Data reader";
        Buildings.BoundaryConditions.WeatherData.BaseClasses.ConvertTime conTim1 "Convert simulation time to calendar time";
        BaseClasses.ConvertTime conTim "Convert simulation time to calendar time";
        BaseClasses.EquationOfTime eqnTim "Equation of time";
        BaseClasses.SolarTime solTim "Solar time";
        Modelica.Blocks.Interfaces.RealInput pAtm_in_internal(final quantity = "Pressure", final unit = "Pa", displayUnit = "bar") "Needed to connect to conditional connector";
        Modelica.Blocks.Interfaces.RealInput ceiHei_in_internal(final quantity = "Height", final unit = "m", displayUnit = "m") "Needed to connect to conditional connector";
        Modelica.Blocks.Interfaces.RealInput totSkyCov_in_internal(final quantity = "1", min = 0, max = 1) "Needed to connect to conditional connector";
        Modelica.Blocks.Interfaces.RealInput opaSkyCov_in_internal(final quantity = "1", min = 0, max = 1) "Needed to connect to conditional connector";
        Modelica.Blocks.Interfaces.RealInput TDryBul_in_internal(final quantity = "ThermodynamicTemperature", final unit = "K", displayUnit = "degC") "Needed to connect to conditional connector";
        Modelica.Blocks.Interfaces.RealInput TDewPoi_in_internal(final quantity = "ThermodynamicTemperature", final unit = "K", displayUnit = "degC") "Needed to connect to conditional connector";
        Modelica.Blocks.Interfaces.RealInput TBlaSky_in_internal(final quantity = "ThermodynamicTemperature", final unit = "K", displayUnit = "degC") "Needed to connect to conditional connector";
        Modelica.Blocks.Interfaces.RealInput relHum_in_internal(final quantity = "1", min = 0, max = 1) "Needed to connect to conditional connector";
        Modelica.Blocks.Interfaces.RealInput winSpe_in_internal(final quantity = "Velocity", final unit = "m/s") "Needed to connect to conditional connector";
        Modelica.Blocks.Interfaces.RealInput winDir_in_internal(final quantity = "Angle", final unit = "rad", displayUnit = "deg") "Needed to connect to conditional connector";
        Modelica.Blocks.Interfaces.RealInput HGloHor_in_internal(final quantity = "RadiantEnergyFluenceRate", final unit = "W/m2") "Needed to connect to conditional connector";
        Modelica.Blocks.Interfaces.RealInput HDifHor_in_internal(final quantity = "RadiantEnergyFluenceRate", final unit = "W/m2") "Needed to connect to conditional connector";
        Modelica.Blocks.Interfaces.RealInput HDirNor_in_internal(final quantity = "RadiantEnergyFluenceRate", final unit = "W/m2") "Needed to connect to conditional connector";
        Modelica.Blocks.Interfaces.RealInput HInfHor_in_internal(final quantity = "RadiantEnergyFluenceRate", final unit = "W/m2") "Needed to connect to conditional connector";
        Modelica.Blocks.Math.UnitConversions.From_deg conWinDir "Convert the wind direction unit from [deg] to [rad]";
        Modelica.Blocks.Math.UnitConversions.From_degC conTDryBul;
        BaseClasses.ConvertRadiation conHorRad;
        Modelica.Blocks.Math.UnitConversions.From_degC conTDewPoi "Convert the dew point temperature form [degC] to [K]";
        BaseClasses.ConvertRadiation conDirNorRad;
        BaseClasses.ConvertRadiation conGloHorRad;
        BaseClasses.ConvertRadiation conDifHorRad;
        BaseClasses.CheckRelativeHumidity cheRelHum;
        SolarGeometry.BaseClasses.AltitudeAngle altAng "Solar altitude angle";
        SolarGeometry.BaseClasses.ZenithAngle zenAng(final lat = lat) "Zenith angle";
        SolarGeometry.BaseClasses.Declination decAng "Declination angle";
        SolarGeometry.BaseClasses.SolarHourAngle solHouAng;
        Latitude latitude(final latitude = lat) "Latitude";
        Longitude longitude(final longitude = lon) "Longitude";
        Buildings.Utilities.Psychrometrics.TWetBul_TDryBulPhi tWetBul_TDryBulXi(redeclare package Medium = Buildings.Media.Air, TDryBul(displayUnit = "degC")) if computeWetBulbTemperature;
        Modelica.Blocks.Math.Gain conTotSkyCov(final k = 0.1) if totSkyCovSou == Buildings.BoundaryConditions.Types.DataSource.File "Convert sky cover from [0...10] to [0...1]";
        Modelica.Blocks.Math.Gain conOpaSkyCov(final k = 0.1) if opaSkyCovSou == Buildings.BoundaryConditions.Types.DataSource.File "Convert sky cover from [0...10] to [0...1]";
        Buildings.BoundaryConditions.WeatherData.BaseClasses.CheckBlackBodySkyTemperature cheTemBlaSky(TMin = 0) "Check black body sky temperature";

        block Latitude  "Generate constant signal of type Real"
          extends Modelica.Blocks.Icons.Block;
          parameter Modelica.SIunits.Angle latitude "Latitude";
          Modelica.Blocks.Interfaces.RealOutput y(unit = "rad", displayUnit = "deg") "Latitude of the location";
        equation
          y = latitude;
        end Latitude;

        block Longitude  "Generate constant signal of type Real"
          extends Modelica.Blocks.Icons.Block;
          parameter Modelica.SIunits.Angle longitude "Longitude";
          Modelica.Blocks.Interfaces.RealOutput y(unit = "rad", displayUnit = "deg") "Longitude of the location";
        equation
          y = longitude;
        end Longitude;
      equation
        if pAtmSou == Buildings.BoundaryConditions.Types.DataSource.Parameter then
          pAtm_in_internal = pAtm;
        elseif pAtmSou == Buildings.BoundaryConditions.Types.DataSource.File then
          connect(datRea.y[4], pAtm_in_internal);
        else
          connect(pAtm_in, pAtm_in_internal);
        end if;
        connect(pAtm_in_internal, chePre.PIn);
        if ceiHeiSou == Buildings.BoundaryConditions.Types.DataSource.Parameter then
          ceiHei_in_internal = ceiHei;
        elseif ceiHeiSou == Buildings.BoundaryConditions.Types.DataSource.Input then
          connect(ceiHei_in, ceiHei_in_internal);
        else
          connect(datRea.y[16], ceiHei_in_internal);
        end if;
        connect(ceiHei_in_internal, cheCeiHei.ceiHeiIn);
        if totSkyCovSou == Buildings.BoundaryConditions.Types.DataSource.Parameter then
          totSkyCov_in_internal = totSkyCov;
        elseif totSkyCovSou == Buildings.BoundaryConditions.Types.DataSource.Input then
          connect(totSkyCov_in, totSkyCov_in_internal);
        else
          connect(conTotSkyCov.u, datRea.y[13]);
          connect(conTotSkyCov.y, totSkyCov_in_internal);
        end if;
        connect(totSkyCov_in_internal, cheTotSkyCov.nIn);
        if opaSkyCovSou == Buildings.BoundaryConditions.Types.DataSource.Parameter then
          opaSkyCov_in_internal = opaSkyCov;
        elseif opaSkyCovSou == Buildings.BoundaryConditions.Types.DataSource.Input then
          connect(opaSkyCov_in, opaSkyCov_in_internal);
        else
          connect(conOpaSkyCov.u, datRea.y[14]);
          connect(conOpaSkyCov.y, opaSkyCov_in_internal);
        end if;
        connect(opaSkyCov_in_internal, cheOpaSkyCov.nIn);
        if TDewPoiSou == Buildings.BoundaryConditions.Types.DataSource.Parameter then
          TDewPoi_in_internal = TDewPoi;
        elseif TDewPoiSou == Buildings.BoundaryConditions.Types.DataSource.Input then
          connect(TDewPoi_in, TDewPoi_in_internal);
        else
          connect(conTDewPoi.y, TDewPoi_in_internal);
        end if;
        connect(TDewPoi_in_internal, cheTemDewPoi.TIn);
        if TDryBulSou == Buildings.BoundaryConditions.Types.DataSource.Parameter then
          TDryBul_in_internal = TDryBul;
        elseif TDryBulSou == Buildings.BoundaryConditions.Types.DataSource.Input then
          connect(TDryBul_in, TDryBul_in_internal);
        else
          connect(conTDryBul.y, TDryBul_in_internal);
        end if;
        connect(TDryBul_in_internal, cheTemDryBul.TIn);
        if TBlaSkySou == Buildings.BoundaryConditions.Types.DataSource.Parameter then
          TBlaSky_in_internal = TBlaSky;
        elseif TBlaSkySou == Buildings.BoundaryConditions.Types.DataSource.Input then
          connect(TBlaSky_in, TBlaSky_in_internal);
        else
          connect(TBlaSkyCom.TBlaSky, TBlaSky_in_internal);
        end if;
        connect(TBlaSky_in_internal, cheTemBlaSky.TIn);
        if relHumSou == Buildings.BoundaryConditions.Types.DataSource.Parameter then
          relHum_in_internal = relHum;
        elseif relHumSou == Buildings.BoundaryConditions.Types.DataSource.Input then
          connect(relHum_in, relHum_in_internal);
        else
          connect(conRelHum.relHumOut, relHum_in_internal);
        end if;
        connect(relHum_in_internal, cheRelHum.relHumIn);
        if winSpeSou == Buildings.BoundaryConditions.Types.DataSource.Parameter then
          winSpe_in_internal = winSpe;
        elseif winSpeSou == Buildings.BoundaryConditions.Types.DataSource.Input then
          connect(winSpe_in, winSpe_in_internal);
        else
          connect(datRea.y[12], winSpe_in_internal);
        end if;
        connect(winSpe_in_internal, cheWinSpe.winSpeIn);
        if winDirSou == Buildings.BoundaryConditions.Types.DataSource.Parameter then
          winDir_in_internal = winDir;
        elseif winDirSou == Buildings.BoundaryConditions.Types.DataSource.Input then
          connect(winDir_in, winDir_in_internal);
        else
          connect(conWinDir.y, winDir_in_internal);
        end if;
        connect(winDir_in_internal, cheWinDir.nIn);
        if HSou == Buildings.BoundaryConditions.Types.RadiationDataSource.Input_HGloHor_HDifHor or HSou == Buildings.BoundaryConditions.Types.RadiationDataSource.Input_HDirNor_HGloHor then
          connect(HGloHor_in, HGloHor_in_internal) "Get HGloHor using user input file";
        elseif HSou == Buildings.BoundaryConditions.Types.RadiationDataSource.Input_HDirNor_HDifHor then
          HDirNor_in_internal * cos(zenAng.zen) + HDifHor_in_internal = HGloHor_in_internal "Calculate the HGloHor using HDirNor and HDifHor according to (A.4.14) and (A.4.15)";
        else
          connect(conGloHorRad.HOut, HGloHor_in_internal) "Get HGloHor using weather data file";
        end if;
        connect(HGloHor_in_internal, cheGloHorRad.HIn);
        if HSou == Buildings.BoundaryConditions.Types.RadiationDataSource.Input_HGloHor_HDifHor or HSou == Buildings.BoundaryConditions.Types.RadiationDataSource.Input_HDirNor_HDifHor then
          connect(HDifHor_in, HDifHor_in_internal) "Get HDifHor using user input file";
        elseif HSou == Buildings.BoundaryConditions.Types.RadiationDataSource.Input_HDirNor_HGloHor then
          HGloHor_in_internal - HDirNor_in_internal * cos(zenAng.zen) = HDifHor_in_internal "Calculate the HGloHor using HDirNor and HDifHor according to (A.4.14) and (A.4.15)";
        else
          connect(conDifHorRad.HOut, HDifHor_in_internal) "Get HDifHor using weather data file";
        end if;
        connect(HDifHor_in_internal, cheDifHorRad.HIn);
        if HSou == Buildings.BoundaryConditions.Types.RadiationDataSource.Input_HDirNor_HGloHor or HSou == Buildings.BoundaryConditions.Types.RadiationDataSource.Input_HDirNor_HDifHor then
          connect(HDirNor_in, HDirNor_in_internal) "Get HDirNor using user input file";
        elseif HSou == Buildings.BoundaryConditions.Types.RadiationDataSource.Input_HGloHor_HDifHor then
          Buildings.Utilities.Math.Functions.smoothMin(solCon, (HGloHor_in_internal - HDifHor_in_internal) * Buildings.Utilities.Math.Functions.spliceFunction(x = cos(zenAng.zen), pos = Buildings.Utilities.Math.Functions.inverseXRegularized(cos(zenAng.zen), epsCos), neg = 0, deltax = epsCos), 0.1) = HDirNor_in_internal "Calculate the HDirNor using HGloHor and HDifHor according to (A.4.14) and (A.4.15)";
        else
          connect(conDirNorRad.HOut, HDirNor_in_internal) "Get HDirNor using weather data file";
        end if;
        connect(HDirNor_in_internal, cheDirNorRad.HIn);
        if HInfHorSou == Buildings.BoundaryConditions.Types.DataSource.Parameter then
          HInfHor_in_internal = HInfHor;
        elseif HInfHorSou == Buildings.BoundaryConditions.Types.DataSource.Input then
          connect(HInfHor_in, HInfHor_in_internal);
        else
          connect(conHorRad.HOut, HInfHor_in_internal);
        end if;
        connect(HInfHor_in_internal, cheHorRad.HIn);
        connect(chePre.POut, weaBus.pAtm) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
        connect(cheTotSkyCov.nOut, weaBus.nTot) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
        connect(cheOpaSkyCov.nOut, weaBus.nOpa) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
        connect(cheGloHorRad.HOut, weaBus.HGloHor) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
        connect(cheDifHorRad.HOut, weaBus.HDifHor) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
        connect(cheDirNorRad.HOut, weaBus.HDirNor) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
        connect(cheCeiHei.ceiHeiOut, weaBus.celHei) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
        connect(cheWinSpe.winSpeOut, weaBus.winSpe) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
        connect(cheHorRad.HOut, weaBus.HHorIR) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
        connect(cheWinDir.nOut, weaBus.winDir) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
        connect(cheOpaSkyCov.nOut, TBlaSkyCom.nOpa);
        connect(cheHorRad.HOut, TBlaSkyCom.HHorIR);
        connect(modTim.y, weaBus.cloTim) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
        connect(modTim.y, add.u2);
        connect(con30mins.y, add.u1);
        connect(add.y, conTim1.modTim);
        connect(conTim1.calTim, datRea1.u);
        connect(modTim.y, locTim.cloTim);
        connect(modTim.y, conTim.modTim);
        connect(conTim.calTim, datRea.u);
        connect(modTim.y, eqnTim.nDay);
        connect(eqnTim.eqnTim, solTim.equTim);
        connect(locTim.locTim, solTim.locTim);
        connect(solTim.solTim, weaBus.solTim) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
        connect(datRea.y[11], conWinDir.u);
        connect(datRea1.y[1], conHorRad.HIn);
        connect(cheTemDryBul.TOut, TBlaSkyCom.TDryBul);
        connect(datRea.y[1], conTDryBul.u);
        connect(datRea.y[2], conTDewPoi.u);
        connect(cheTemDewPoi.TOut, weaBus.TDewPoi) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
        connect(TBlaSkyCom.TDewPoi, cheTemDewPoi.TOut);
        connect(datRea1.y[3], conDirNorRad.HIn);
        connect(datRea1.y[2], conGloHorRad.HIn);
        connect(datRea1.y[4], conDifHorRad.HIn);
        connect(conRelHum.relHumIn, datRea.y[3]);
        connect(cheRelHum.relHumOut, weaBus.relHum) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
        connect(cheTemDryBul.TOut, weaBus.TDryBul) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
        connect(decAng.decAng, zenAng.decAng);
        connect(solHouAng.solHouAng, zenAng.solHouAng);
        connect(solHouAng.solTim, solTim.solTim);
        connect(decAng.nDay, modTim.y);
        connect(zenAng.zen, altAng.zen);
        connect(chePre.POut, tWetBul_TDryBulXi.p);
        connect(tWetBul_TDryBulXi.TWetBul, weaBus.TWetBul) annotation(Text(string = "%second", index = 1, extent = {{6, 3}, {6, 3}}));
        connect(cheTemDryBul.TOut, tWetBul_TDryBulXi.TDryBul);
        connect(cheRelHum.relHumOut, tWetBul_TDryBulXi.phi);
        connect(altAng.alt, weaBus.solAlt);
        connect(zenAng.zen, weaBus.solZen);
        connect(decAng.decAng, weaBus.solDec);
        connect(solHouAng.solHouAng, weaBus.solHouAng);
        connect(longitude.y, weaBus.lon);
        connect(latitude.y, weaBus.lat);
        connect(cheTemBlaSky.TOut, weaBus.TBlaSky);
      end ReaderTMY3;

      package Examples  "Collection of models that illustrate model use and test models"
        extends Modelica.Icons.ExamplesPackage;

        model ReaderTMY3  "Test model for reading weather data"
          extends Modelica.Icons.Example;
          Buildings.BoundaryConditions.WeatherData.ReaderTMY3 weaDat(filNam = "modelica://Buildings/Resources/weatherdata/USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.mos") "Weather data reader";
          Buildings.BoundaryConditions.WeatherData.ReaderTMY3 weaDatInpCon(filNam = "modelica://Buildings/Resources/weatherdata/USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.mos", HSou = Buildings.BoundaryConditions.Types.RadiationDataSource.Input_HGloHor_HDifHor) "Weather data reader with radiation data obtained from input connector";
          Modelica.Blocks.Sources.Constant HDifHor(k = 0) "Diffuse horizontal radiation";
          Modelica.Blocks.Sources.Constant HGloHor(k = 0) "Horizontal global radiation";
        equation
          connect(HGloHor.y, weaDatInpCon.HGloHor_in);
          connect(HDifHor.y, weaDatInpCon.HDifHor_in);
          annotation(experiment(StopTime = 8640000), __Dymola_Commands(file = "modelica://Buildings/Resources/Scripts/Dymola/BoundaryConditions/WeatherData/Examples/ReaderTMY3.mos"));
        end ReaderTMY3;
      end Examples;

      package BaseClasses  "Package with base classes for Buildings.BoundaryConditions.WeatherData"
        extends Modelica.Icons.BasesPackage;

        block CheckBlackBodySkyTemperature  "Check the validity of the black-body sky temperature data"
          extends Modelica.Blocks.Icons.Block;
          Modelica.Blocks.Interfaces.RealInput TIn(final quantity = "ThermodynamicTemperature", final unit = "K", displayUnit = "degC") "Black-body sky temperature";
          Modelica.Blocks.Interfaces.RealOutput TOut(final quantity = "ThermodynamicTemperature", final unit = "K", displayUnit = "degC") "Black-body sky temperature";
          parameter Modelica.SIunits.Temperature TMin(displayUnit = "degC") = 203.15 "Minimum allowed temperature";
          parameter Modelica.SIunits.Temperature TMax(displayUnit = "degC") = 343.15 "Maximum allowed temperature";
        equation
          TOut = TIn;
          assert(TOut > TMin, "Temperature out of bounds.\n" + "   TOut = " + String(TOut));
          assert(TOut < TMax, "Temperature out of bounds.\n" + "   TOut = " + String(TOut));
        end CheckBlackBodySkyTemperature;

        block CheckCeilingHeight  "Ensures that the ceiling height is above a lower bound"
          extends Modelica.Blocks.Icons.Block;
          Modelica.Blocks.Interfaces.RealInput ceiHeiIn(final quantity = "Height", final unit = "m") "Input ceiling height";
          Modelica.Blocks.Interfaces.RealOutput ceiHeiOut(final quantity = "Height", final unit = "m") "Ceiling height";
          constant Modelica.SIunits.Height ceiHeiMin = 0 "Minimum allowed ceiling height";
        equation
          ceiHeiOut = Buildings.Utilities.Math.Functions.smoothMax(ceiHeiIn, ceiHeiMin, 0.1);
        end CheckCeilingHeight;

        block CheckIRRadiation  "Ensure that the radiation is not smaller than 0"
          extends Modelica.Blocks.Icons.Block;
          Modelica.Blocks.Interfaces.RealInput HIn(final quantity = "RadiantEnergyFluenceRate", final unit = "W/m2") "Input horizontal infrared irradiation";
          Modelica.Blocks.Interfaces.RealOutput HOut(final quantity = "RadiantEnergyFluenceRate", final unit = "W/m2") "Horizontal infrared irradiation";
          constant Modelica.SIunits.RadiantEnergyFluenceRate HMin = 0.0001 "Minimum value for radiation";
        equation
          HOut = Buildings.Utilities.Math.Functions.smoothMax(x1 = HIn, x2 = HMin, deltaX = HMin / 10);
        end CheckIRRadiation;

        block CheckPressure  "Ensures that the interpolated pressure is between prescribed bounds"
          extends Modelica.Blocks.Icons.Block;
          Modelica.Blocks.Interfaces.RealInput PIn(final quantity = "Pressure", final unit = "Pa") "Input pressure";
          Modelica.Blocks.Interfaces.RealOutput POut(final quantity = "Pressure", final unit = "Pa") "Atmospheric pressure";
          constant Modelica.SIunits.Pressure PMin = 3100 "Minimum allowed pressure";
          constant Modelica.SIunits.Pressure PMax = 120000 "Maximum allowed pressure";
        equation
          assert(PIn > PMin, "Pressure out of bounds.\n" + "   PIn = " + String(PIn));
          assert(PIn < PMax, "Pressure out of bounds.\n" + "   PIn = " + String(PIn));
          POut = PIn;
        end CheckPressure;

        block CheckRadiation  "Ensure that the radiation is not smaller than 0"
          extends Modelica.Blocks.Icons.Block;
          Modelica.Blocks.Interfaces.RealInput HIn(final quantity = "RadiantEnergyFluenceRate", final unit = "W/m2") "Input radiation";
          Modelica.Blocks.Interfaces.RealOutput HOut(final quantity = "RadiantEnergyFluenceRate", final unit = "W/m2") "Radiation";
          constant Modelica.SIunits.RadiantEnergyFluenceRate HMin = 0.0001 "Minimum value for radiation";
        equation
          HOut = Buildings.Utilities.Math.Functions.smoothMax(x1 = HIn, x2 = HMin, deltaX = HMin / 10);
        end CheckRadiation;

        block CheckRelativeHumidity  "Check the validity of relative humidity"
          extends Modelica.Blocks.Icons.Block;
          Modelica.Blocks.Interfaces.RealInput relHumIn(final unit = "1") "Input relative humidity";
          Modelica.Blocks.Interfaces.RealOutput relHumOut(final unit = "1") "Relative humidity";
          constant Real delta = 0.01 "Smoothing parameter";
        protected
          constant Real relHumMin = delta "Lower bound";
          constant Real relHumMax = 1 - delta "Upper bound";
        equation
          relHumOut = Buildings.Utilities.Math.Functions.smoothLimit(relHumIn, relHumMin, relHumMax, delta / 10);
        end CheckRelativeHumidity;

        block CheckSkyCover  "Constrains the sky cover to [0, 1]"
          extends Modelica.Blocks.Icons.Block;
          Modelica.Blocks.Interfaces.RealInput nIn(min = 0, max = 1) "Input sky cover [0, 10]";
          Modelica.Blocks.Interfaces.RealOutput nOut(min = 0, max = 1, unit = "1") "Sky cover [0, 1]";
          constant Real delta = 0.01 "Smoothing parameter";
        protected
          constant Real nMin = delta "Lower bound";
          constant Real nMax = 10 - delta "Upper bound";
        equation
          nOut = Buildings.Utilities.Math.Functions.smoothLimit(nIn, nMin, nMax, delta / 10);
        end CheckSkyCover;

        block CheckTemperature  "Check the validity of temperature data"
          extends Modelica.Blocks.Icons.Block;
          Modelica.Blocks.Interfaces.RealInput TIn(final quantity = "ThermodynamicTemperature", final unit = "K", displayUnit = "degC") "Input Temperature";
          Modelica.Blocks.Interfaces.RealOutput TOut(final quantity = "ThermodynamicTemperature", final unit = "K", displayUnit = "degC") "Output temperature";
          parameter Modelica.SIunits.Temperature TMin(displayUnit = "degC") = 203.15 "Minimum allowed temperature";
          parameter Modelica.SIunits.Temperature TMax(displayUnit = "degC") = 343.15 "Maximum allowed temperature";
        equation
          TOut = TIn;
          assert(TOut > TMin, "Temperature out of bounds.\n" + "   TOut = " + String(TOut));
          assert(TOut < TMax, "Temperature out of bounds.\n" + "   TOut = " + String(TOut));
        end CheckTemperature;

        block CheckWindDirection  "Constrains the wind direction to [0, 2*pi] degree"
          extends Modelica.Blocks.Icons.Block;
          Modelica.Blocks.Interfaces.RealInput nIn(final quantity = "Angle", final unit = "rad", displayUnit = "deg") "Input wind direction";
          Modelica.Blocks.Interfaces.RealOutput nOut(final quantity = "Angle", final unit = "rad", displayUnit = "deg") "Wind direction";
          constant Real delta = 0.01 "Smoothing parameter";
        protected
          constant Real nMin = 0 "Lower bound";
          constant Real nMax = 2 * Modelica.Constants.pi "Upper bound";
        equation
          nOut = Buildings.Utilities.Math.Functions.smoothLimit(nIn, nMin, nMax, delta / 10);
        end CheckWindDirection;

        block CheckWindSpeed  "Ensures that the wind speed is non-negative"
          extends Modelica.Blocks.Icons.Block;
          Modelica.Blocks.Interfaces.RealInput winSpeIn(final quantity = "Velocity", final unit = "m/s") "Input wind speed";
          Modelica.Blocks.Interfaces.RealOutput winSpeOut(final quantity = "Velocity", final unit = "m/s") "Wind speed";
          constant Modelica.SIunits.Velocity winSpeMin = 1e-6 "Minimum allowed wind speed";
        equation
          winSpeOut = Buildings.Utilities.Math.Functions.smoothMax(x1 = winSpeIn, x2 = winSpeMin, deltaX = winSpeMin / 10);
        end CheckWindSpeed;

        block ConvertRadiation  "Convert the unit of solar radiation received from the TMY3 data file"
          extends Modelica.Blocks.Icons.Block;
          Modelica.Blocks.Interfaces.RealInput HIn(final unit = "W.h/m2") "Input radiation";
          Modelica.Blocks.Interfaces.RealOutput HOut(final quantity = "RadiantEnergyFluenceRate", final unit = "W/m2") "Radiation";
        protected
          constant Modelica.SIunits.Time Hou = 3600 "1 hour";
        equation
          HOut = HIn / Modelica.SIunits.Conversions.to_hour(Hou);
        end ConvertRadiation;

        block ConvertRelativeHumidity  "Convert the relative humidity from percentage to real"
          extends Modelica.Blocks.Icons.Block;
          Modelica.Blocks.Interfaces.RealInput relHumIn(unit = "1") "Value of relative humidity in percentage";
          Modelica.Blocks.Interfaces.RealOutput relHumOut(unit = "1") "Relative humidity between 0 and 1";
        equation
          relHumOut = relHumIn / 100;
        end ConvertRelativeHumidity;

        block ConvertTime  "Converts the simulation time to calendar time in scale of 1 year (365 days)"
          extends Modelica.Blocks.Icons.Block;
          Modelica.Blocks.Interfaces.RealInput modTim(final quantity = "Time", final unit = "s") "Simulation time";
          Modelica.Blocks.Interfaces.RealOutput calTim(final quantity = "Time", final unit = "s") "Calendar time";
        protected
          constant Modelica.SIunits.Time year = 31536000 "Number of seconds in a year";
          discrete Modelica.SIunits.Time tStart "Start time of period";
        initial equation
          tStart = integer(modTim / year) * year;
        equation
          when modTim - pre(tStart) > year then
            tStart = integer(modTim / year) * year;
          end when;
          calTim = modTim - tStart;
        end ConvertTime;

        block EquationOfTime  "Equation of time"
          extends Modelica.Blocks.Icons.Block;
          Modelica.Blocks.Interfaces.RealInput nDay(quantity = "Time", unit = "s") "Zero-based day number in seconds (January 1=0, January 2=86400)";
          Modelica.Blocks.Interfaces.RealOutput eqnTim(final quantity = "Time", final unit = "s", displayUnit = "min") "Equation of time";
        protected
          Real Bt "Intermediate variable";
        equation
          Bt = Modelica.Constants.pi * ((nDay + 86400) / 86400 - 81) / 182 "Our unit is s instead of day in (A.4.2b)";
          eqnTim = 60 * (9.87 * Modelica.Math.sin(2 * Bt) - 7.53 * Modelica.Math.cos(Bt) - 1.5 * Modelica.Math.sin(Bt)) "Our unit is s instead of min in (A.4.2a)";
        end EquationOfTime;

        block LocalCivilTime  "Converts the clock time to local civil time."
          extends Modelica.Blocks.Icons.Block;
          Modelica.Blocks.Interfaces.RealInput cloTim(final quantity = "Time", final unit = "s") "Clock time";
          parameter Modelica.SIunits.Time timZon(displayUnit = "h") "Time zone";
          parameter Modelica.SIunits.Angle lon(displayUnit = "deg") "Longitude";
          Modelica.Blocks.Interfaces.RealOutput locTim(final quantity = "Time", final unit = "s") "Local civil time";
        protected
          final parameter Modelica.SIunits.Time diff = (-timZon) + lon * 43200 / Modelica.Constants.pi "Difference between local and clock time";
        equation
          locTim = cloTim + diff;
        end LocalCivilTime;

        block SolarTime  "Solar time"
          extends Modelica.Blocks.Icons.Block;
          Modelica.Blocks.Interfaces.RealInput locTim(quantity = "Time", unit = "s") "Local time";
          Modelica.Blocks.Interfaces.RealInput equTim(quantity = "Time", unit = "s") "Equation of time";
          Modelica.Blocks.Interfaces.RealOutput solTim(final quantity = "Time", final unit = "s", displayUnit = "s") "Solar time";
        equation
          solTim = locTim + equTim "Our unit is s in stead of h in (A.4.3)";
        end SolarTime;

        function getAbsolutePath  "Gets the absolute path of a URI"
          input String uri "A URI";
          output String path "The absolute path of the file pointed to by the URI";
        algorithm
          path := Modelica.Utilities.Files.loadResource(uri);
          assert(Modelica.Utilities.Files.exist(path), "File '" + uri + "' does not exist.");
        end getAbsolutePath;

        function getHeaderElementTMY3  "Gets an element from the header of a TMY3 weather data file"
          input String filNam "Name of weather data file";
          input String start "Start of the string that contains the elements";
          input String name "Name of data element, used in error reporting";
          input Integer position(min = 1) "Position of the element on the line that contains 'start'";
          output String element "Element at position 'pos' of the line that starts with 'start'";
        protected
          String lin "Line that is used in parser";
          Integer iLin "Line number";
          Integer index = 0 "Index of string #LOCATION";
          Integer staInd "Start index used when parsing a real number";
          Integer nexInd "Next index used when parsing a real number";
          Boolean found "Flag, true if #LOCATION has been found";
          Boolean EOF "Flag, true if EOF has been reached";
          String fouDel "Found delimiter";
        algorithm
          iLin := 0;
          EOF := false;
          while not EOF and index == 0 loop
            iLin := iLin + 1;
            (lin, EOF) := Modelica.Utilities.Streams.readLine(fileName = filNam, lineNumber = iLin);
            index := Modelica.Utilities.Strings.find(string = lin, searchString = start, startIndex = 1, caseSensitive = false);
          end while;
          assert(not EOF, "Error: Did not find '" + start + "' when scanning the weather file." + "\n   Check for correct weather file syntax.");
          nexInd := 1;
          for i in 1:position - 1 loop
            nexInd := Modelica.Utilities.Strings.find(string = lin, searchString = ",", startIndex = nexInd + 1);
            assert(nexInd > 0, "Error when scanning weather file. Not enough tokens to find " + name + "." + "\n   Check for correct file syntax." + "\n   The scanned line is '" + lin + "'.");
          end for;
          staInd := nexInd;
          nexInd := Modelica.Utilities.Strings.find(string = lin, searchString = ",", startIndex = nexInd + 1);
          assert(nexInd > 0, "Error when scanning weather file. Not enough tokens to find " + name + "." + "\n   Check for correct file syntax." + "\n   The scanned line is '" + lin + "'.");
          element := Modelica.Utilities.Strings.substring(lin, startIndex = staInd + 1, endIndex = nexInd - 1);
          annotation(Inline = false);
        end getHeaderElementTMY3;

        function getLatitudeTMY3  "Gets the latitude from a TMY3 weather data file"
          input String filNam "Name of weather data file";
          output Modelica.SIunits.Angle lat "Latitude from the weather file";
        protected
          Integer nexInd "Next index, used for error handling";
          String element "String representation of the returned element";
        algorithm
          element := Buildings.BoundaryConditions.WeatherData.BaseClasses.getHeaderElementTMY3(filNam = filNam, start = "#LOCATION", name = "longitude", position = 7);
          (nexInd, lat) := Modelica.Utilities.Strings.Advanced.scanReal(string = element, startIndex = 1, unsigned = false);
          assert(nexInd > 1, "Error when converting the latitude '" + element + "' from a String to a Real.");
          lat := lat * Modelica.Constants.pi / 180;
          assert(abs(lat) <= Modelica.Constants.pi + Modelica.Constants.eps, "Wrong value for latitude. Received lat = " + String(lat) + " (= " + String(lat * 180 / Modelica.Constants.pi) + " degrees).");
        end getLatitudeTMY3;

        function getLongitudeTMY3  "Gets the longitude from a TMY3 weather data file"
          input String filNam "Name of weather data file";
          output Modelica.SIunits.Angle lon "Longitude from the weather file";
        protected
          Integer nexInd "Next index, used for error handling";
          String element "String representation of the returned element";
        algorithm
          element := Buildings.BoundaryConditions.WeatherData.BaseClasses.getHeaderElementTMY3(filNam = filNam, start = "#LOCATION", name = "longitude", position = 8);
          (nexInd, lon) := Modelica.Utilities.Strings.Advanced.scanReal(string = element, startIndex = 1, unsigned = false);
          assert(nexInd > 1, "Error when converting the longitude '" + element + "' from a String to a Real.");
          lon := lon * Modelica.Constants.pi / 180;
          assert(abs(lon) < 2 * Modelica.Constants.pi, "Wrong value for longitude. Received lon = " + String(lon) + " (= " + String(lon * 180 / Modelica.Constants.pi) + " degrees).");
        end getLongitudeTMY3;

        function getTimeZoneTMY3  "Gets the time zone from a TMY3 weather data file"
          input String filNam "Name of weather data file";
          output Modelica.SIunits.Time timZon "Time zone from the weather file";
        protected
          Integer nexInd "Next index, used for error handling";
          String element "String representation of the returned element";
        algorithm
          element := Buildings.BoundaryConditions.WeatherData.BaseClasses.getHeaderElementTMY3(filNam = filNam, start = "#LOCATION", name = "longitude", position = 9);
          (nexInd, timZon) := Modelica.Utilities.Strings.Advanced.scanReal(string = element, startIndex = 1, unsigned = false);
          assert(nexInd > 1, "Error when converting the time zone '" + element + "' from a String to a Real.");
          timZon := timZon * 3600;
          assert(abs(timZon) < 24 * 3600, "Wrong value for time zone. Received timZon = " + String(timZon) + " (= " + String(timZon / 3600) + " hours).");
        end getTimeZoneTMY3;
      end BaseClasses;
    end WeatherData;

    package Types  "Package with type definitions"
      extends Modelica.Icons.TypesPackage;
      type DataSource = enumeration(File "Use data from file", Parameter "Use parameter", Input "Use input connector") "Enumeration to define data source";
      type RadiationDataSource = enumeration(File "Use data from file", Input_HGloHor_HDifHor "Global horizontal and diffuse horizontal radiation from connector", Input_HDirNor_HDifHor "Direct normal and diffuse horizontal radiation from connector", Input_HDirNor_HGloHor "Direct normal and global horizontal radiation from connector") "Enumeration to define solar radiation data source";
      type SkyTemperatureCalculation = enumeration(HorizontalRadiation "Use horizontal irradiation", TemperaturesAndSkyCover "Use dry-bulb and dew-point temperatures and sky cover") "Enumeration for computation of sky temperature";
    end Types;
  end BoundaryConditions;

  package Media  "Package with medium models"
    extends Modelica.Icons.Package;

    package Air  "Package with moist air model that decouples pressure and temperature"
      extends Modelica.Media.Interfaces.PartialCondensingGases(mediumName = "Air", final substanceNames = {"water", "air"}, final reducedX = true, final singleState = false, reference_X = {0.01, 0.99}, final fluidConstants = {Modelica.Media.IdealGases.Common.FluidData.H2O, Modelica.Media.IdealGases.Common.FluidData.N2}, reference_T = 273.15, reference_p = 101325, AbsolutePressure(start = p_default), Temperature(start = T_default));
      extends Modelica.Icons.Package;
      constant Integer Water = 1 "Index of water (in substanceNames, massFractions X, etc.)";
      constant Integer Air = 2 "Index of air (in substanceNames, massFractions X, etc.)";
      constant AbsolutePressure pStp = reference_p "Pressure for which fluid density is defined";
      constant Density dStp = 1.2 "Fluid density at pressure pStp";

      redeclare record extends ThermodynamicState  "ThermodynamicState record for moist air" end ThermodynamicState;

      redeclare replaceable model extends BaseProperties(Xi(each stateSelect = if preferredMediumStates then StateSelect.prefer else StateSelect.default), T(stateSelect = if preferredMediumStates then StateSelect.prefer else StateSelect.default), final standardOrderComponents = true)  "Base properties"
      protected
        constant Modelica.SIunits.MolarMass[2] MMX = {steam.MM, dryair.MM} "Molar masses of components";
        MassFraction X_steam "Mass fraction of steam water";
        MassFraction X_air "Mass fraction of air";
        Modelica.SIunits.TemperatureDifference dT(start = T_default - reference_T) "Temperature difference used to compute enthalpy";
      equation
        assert(T >= 200.0 and T <= 423.15, "
      Temperature T is not in the allowed range
      200.0 K <= (T =" + String(T) + " K) <= 423.15 K
      required from medium model \"" + mediumName + "\".");
        MM = 1 / (Xi[Water] / MMX[Water] + (1.0 - Xi[Water]) / MMX[Air]);
        X_steam = Xi[Water];
        X_air = 1 - Xi[Water];
        dT = T - reference_T;
        h = dT * dryair.cp * X_air + (dT * steam.cp + h_fg) * X_steam;
        R = dryair.R * X_air + steam.R * X_steam;
        u = h - pStp / dStp;
        d / dStp = p / pStp;
        state.p = p;
        state.T = T;
        state.X = X;
      end BaseProperties;

      redeclare function density  "Gas density"
        extends Modelica.Icons.Function;
        input ThermodynamicState state;
        output Density d "Density";
      algorithm
        d := state.p * dStp / pStp;
        annotation(smoothOrder = 5, Inline = true);
      end density;

      redeclare function extends dynamicViscosity  "Return the dynamic viscosity of dry air"
      algorithm
        eta := 4.89493640395e-08 * state.T + 3.88335940547e-06;
        annotation(smoothOrder = 99, Inline = true);
      end dynamicViscosity;

      redeclare function enthalpyOfCondensingGas  "Enthalpy of steam per unit mass of steam"
        extends Modelica.Icons.Function;
        input Temperature T "temperature";
        output SpecificEnthalpy h "steam enthalpy";
      algorithm
        h := (T - reference_T) * steam.cp + h_fg;
        annotation(smoothOrder = 5, Inline = true, derivative = der_enthalpyOfCondensingGas);
      end enthalpyOfCondensingGas;

      redeclare replaceable function extends enthalpyOfGas  "Enthalpy of gas mixture per unit mass of gas mixture"
      algorithm
        h := enthalpyOfCondensingGas(T) * X[Water] + enthalpyOfDryAir(T) * (1.0 - X[Water]);
        annotation(Inline = true);
      end enthalpyOfGas;

      redeclare replaceable function extends enthalpyOfLiquid  "Enthalpy of liquid (per unit mass of liquid) which is linear in the temperature"
      algorithm
        h := (T - reference_T) * cpWatLiq;
        annotation(smoothOrder = 5, Inline = true, derivative = der_enthalpyOfLiquid);
      end enthalpyOfLiquid;

      redeclare function extends enthalpyOfVaporization  "Enthalpy of vaporization of water"
      algorithm
        r0 := h_fg;
        annotation(Inline = true);
      end enthalpyOfVaporization;

      redeclare function extends gasConstant  "Return ideal gas constant as a function from thermodynamic state, only valid for phi<1"
      algorithm
        R := dryair.R * (1 - state.X[Water]) + steam.R * state.X[Water];
        annotation(smoothOrder = 2, Inline = true);
      end gasConstant;

      redeclare function extends pressure  "Returns pressure of ideal gas as a function of the thermodynamic state record"
      algorithm
        p := state.p;
        annotation(smoothOrder = 2, Inline = true);
      end pressure;

      redeclare function extends isobaricExpansionCoefficient  "Isobaric expansion coefficient beta"
      algorithm
        beta := 0;
        annotation(smoothOrder = 5, Inline = true);
      end isobaricExpansionCoefficient;

      redeclare function extends isothermalCompressibility  "Isothermal compressibility factor"
      algorithm
        kappa := -1 / state.p;
        annotation(smoothOrder = 5, Inline = true);
      end isothermalCompressibility;

      redeclare function extends saturationPressure  "Saturation curve valid for 223.16 <= T <= 373.16 (and slightly outside with less accuracy)"
      algorithm
        psat := Buildings.Utilities.Psychrometrics.Functions.saturationPressure(Tsat);
        annotation(smoothOrder = 5, Inline = true);
      end saturationPressure;

      redeclare function extends specificEntropy  "Return the specific entropy, only valid for phi<1"
      protected
        Modelica.SIunits.MoleFraction[2] Y "Molar fraction";
      algorithm
        Y := massToMoleFractions(state.X, {steam.MM, dryair.MM});
        s := specificHeatCapacityCp(state) * Modelica.Math.log(state.T / reference_T) - Modelica.Constants.R * sum(state.X[i] / MMX[i] * Modelica.Math.log(max(Y[i], Modelica.Constants.eps) * state.p / reference_p) for i in 1:2);
        annotation(Inline = true);
      end specificEntropy;

      redeclare function extends density_derp_T  "Return the partial derivative of density with respect to pressure at constant temperature"
      algorithm
        ddpT := dStp / pStp;
        annotation(Inline = true);
      end density_derp_T;

      redeclare function extends density_derT_p  "Return the partial derivative of density with respect to temperature at constant pressure"
      algorithm
        ddTp := 0;
        annotation(smoothOrder = 99, Inline = true);
      end density_derT_p;

      redeclare function extends density_derX  "Return the partial derivative of density with respect to mass fractions at constant pressure and temperature"
      algorithm
        dddX := fill(0, nX);
        annotation(smoothOrder = 99, Inline = true);
      end density_derX;

      redeclare replaceable function extends specificHeatCapacityCp  "Specific heat capacity of gas mixture at constant pressure"
      algorithm
        cp := dryair.cp * (1 - state.X[Water]) + steam.cp * state.X[Water];
        annotation(smoothOrder = 99, Inline = true, derivative = der_specificHeatCapacityCp);
      end specificHeatCapacityCp;

      redeclare replaceable function extends specificHeatCapacityCv  "Specific heat capacity of gas mixture at constant volume"
      algorithm
        cv := dryair.cv * (1 - state.X[Water]) + steam.cv * state.X[Water];
        annotation(smoothOrder = 99, Inline = true, derivative = der_specificHeatCapacityCv);
      end specificHeatCapacityCv;

      redeclare function setState_dTX  "Return thermodynamic state as function of density d, temperature T and composition X"
        extends Modelica.Icons.Function;
        input Density d "Density";
        input Temperature T "Temperature";
        input MassFraction[:] X = reference_X "Mass fractions";
        output ThermodynamicState state "Thermodynamic state";
      algorithm
        state := if size(X, 1) == nX then ThermodynamicState(p = d * pStp / dStp, T = T, X = X) else ThermodynamicState(p = d * pStp / dStp, T = T, X = cat(1, X, {1 - sum(X)}));
        annotation(smoothOrder = 2, Inline = true);
      end setState_dTX;

      redeclare function extends setState_phX  "Return thermodynamic state as function of pressure p, specific enthalpy h and composition X"
      algorithm
        state := if size(X, 1) == nX then ThermodynamicState(p = p, T = temperature_phX(p, h, X), X = X) else ThermodynamicState(p = p, T = temperature_phX(p, h, X), X = cat(1, X, {1 - sum(X)}));
        annotation(smoothOrder = 2, Inline = true);
      end setState_phX;

      redeclare function extends setState_pTX  "Return thermodynamic state as function of p, T and composition X or Xi"
      algorithm
        state := if size(X, 1) == nX then ThermodynamicState(p = p, T = T, X = X) else ThermodynamicState(p = p, T = T, X = cat(1, X, {1 - sum(X)}));
        annotation(smoothOrder = 2, Inline = true);
      end setState_pTX;

      redeclare function extends setState_psX  "Return the thermodynamic state as function of p, s and composition X or Xi"
      protected
        Modelica.SIunits.MassFraction[2] X_int = if size(X, 1) == nX then X else cat(1, X, {1 - sum(X)}) "Mass fraction";
        Modelica.SIunits.MoleFraction[2] Y "Molar fraction";
        Modelica.SIunits.Temperature T "Temperature";
      algorithm
        Y := massToMoleFractions(X_int, {steam.MM, dryair.MM});
        T := 273.15 * Modelica.Math.exp((s + Modelica.Constants.R * sum(X_int[i] / MMX[i] * Modelica.Math.log(max(Y[i], Modelica.Constants.eps)) for i in 1:2)) / specificHeatCapacityCp(setState_pTX(p = p, T = 273.15, X = X_int)));
        state := ThermodynamicState(p = p, T = T, X = X_int);
        annotation(Inline = true);
      end setState_psX;

      redeclare replaceable function extends specificEnthalpy  "Compute specific enthalpy from pressure, temperature and mass fraction"
      algorithm
        h := (state.T - reference_T) * dryair.cp * (1 - state.X[Water]) + ((state.T - reference_T) * steam.cp + h_fg) * state.X[Water];
        annotation(smoothOrder = 5, Inline = true);
      end specificEnthalpy;

      redeclare replaceable function specificEnthalpy_pTX  "Specific enthalpy"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "Pressure";
        input Modelica.SIunits.Temperature T "Temperature";
        input Modelica.SIunits.MassFraction[:] X "Mass fractions of moist air";
        output Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy at p, T, X";
      algorithm
        h := specificEnthalpy(setState_pTX(p, T, X));
        annotation(smoothOrder = 5, Inline = true, inverse(T = temperature_phX(p, h, X)));
      end specificEnthalpy_pTX;

      redeclare replaceable function extends specificGibbsEnergy  "Specific Gibbs energy"
      algorithm
        g := specificEnthalpy(state) - state.T * specificEntropy(state);
        annotation(Inline = true);
      end specificGibbsEnergy;

      redeclare replaceable function extends specificHelmholtzEnergy  "Specific Helmholtz energy"
      algorithm
        f := specificEnthalpy(state) - gasConstant(state) * state.T - state.T * specificEntropy(state);
        annotation(Inline = true);
      end specificHelmholtzEnergy;

      redeclare function extends isentropicEnthalpy  "Return the isentropic enthalpy"
      algorithm
        h_is := specificEnthalpy(setState_psX(p = p_downstream, s = specificEntropy(refState), X = refState.X));
        annotation(Inline = true);
      end isentropicEnthalpy;

      redeclare function extends specificInternalEnergy  "Specific internal energy"
        extends Modelica.Icons.Function;
      algorithm
        u := specificEnthalpy(state) - pStp / dStp;
        annotation(Inline = true);
      end specificInternalEnergy;

      redeclare function extends temperature  "Return temperature of ideal gas as a function of the thermodynamic state record"
      algorithm
        T := state.T;
        annotation(smoothOrder = 2, Inline = true);
      end temperature;

      redeclare function extends molarMass  "Return the molar mass"
      algorithm
        MM := 1 / (state.X[Water] / MMX[Water] + (1.0 - state.X[Water]) / MMX[Air]);
        annotation(Inline = true, smoothOrder = 99);
      end molarMass;

      redeclare replaceable function temperature_phX  "Compute temperature from specific enthalpy and mass fraction"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEnthalpy h "specific enthalpy";
        input MassFraction[:] X "mass fractions of composition";
        output Temperature T "temperature";
      algorithm
        T := reference_T + (h - h_fg * X[Water]) / ((1 - X[Water]) * dryair.cp + X[Water] * steam.cp);
        annotation(smoothOrder = 5, Inline = true, inverse(h = specificEnthalpy_pTX(p, T, X)));
      end temperature_phX;

      redeclare function extends thermalConductivity  "Thermal conductivity of dry air as a polynomial in the temperature"
      algorithm
        lambda := Modelica.Media.Incompressible.TableBased.Polynomials_Temp.evaluate({-4.8737307422969E-008, 7.67803133753502E-005, 0.0241814385504202}, Modelica.SIunits.Conversions.to_degC(state.T));
        annotation(LateInline = true);
      end thermalConductivity;

    protected
      record GasProperties  "Coefficient data record for properties of perfect gases"
        extends Modelica.Icons.Record;
        Modelica.SIunits.MolarMass MM "Molar mass";
        Modelica.SIunits.SpecificHeatCapacity R "Gas constant";
        Modelica.SIunits.SpecificHeatCapacity cp "Specific heat capacity at constant pressure";
        Modelica.SIunits.SpecificHeatCapacity cv = cp - R "Specific heat capacity at constant volume";
      end GasProperties;

      constant GasProperties dryair(R = Modelica.Media.IdealGases.Common.SingleGasesData.Air.R, MM = Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM, cp = Buildings.Utilities.Psychrometrics.Constants.cpAir, cv = Buildings.Utilities.Psychrometrics.Constants.cpAir - Modelica.Media.IdealGases.Common.SingleGasesData.Air.R) "Dry air properties";
      constant GasProperties steam(R = Modelica.Media.IdealGases.Common.SingleGasesData.H2O.R, MM = Modelica.Media.IdealGases.Common.SingleGasesData.H2O.MM, cp = Buildings.Utilities.Psychrometrics.Constants.cpSte, cv = Buildings.Utilities.Psychrometrics.Constants.cpSte - Modelica.Media.IdealGases.Common.SingleGasesData.H2O.R) "Steam properties";
      constant Modelica.SIunits.MolarMass[2] MMX = {steam.MM, dryair.MM} "Molar masses of components";
      constant Modelica.SIunits.SpecificEnergy h_fg = Buildings.Utilities.Psychrometrics.Constants.h_fg "Latent heat of evaporation of water";
      constant Modelica.SIunits.SpecificHeatCapacity cpWatLiq = Buildings.Utilities.Psychrometrics.Constants.cpWatLiq "Specific heat capacity of liquid water";

      replaceable function der_enthalpyOfLiquid  "Temperature derivative of enthalpy of liquid per unit mass of liquid"
        extends Modelica.Icons.Function;
        input Temperature T "Temperature";
        input Real der_T "Temperature derivative";
        output Real der_h "Derivative of liquid enthalpy";
      algorithm
        der_h := cpWatLiq * der_T;
        annotation(Inline = true);
      end der_enthalpyOfLiquid;

      function der_enthalpyOfCondensingGas  "Derivative of enthalpy of steam per unit mass of steam"
        extends Modelica.Icons.Function;
        input Temperature T "Temperature";
        input Real der_T "Temperature derivative";
        output Real der_h "Derivative of steam enthalpy";
      algorithm
        der_h := steam.cp * der_T;
        annotation(Inline = true);
      end der_enthalpyOfCondensingGas;

      replaceable function enthalpyOfDryAir  "Enthalpy of dry air per unit mass of dry air"
        extends Modelica.Icons.Function;
        input Temperature T "Temperature";
        output SpecificEnthalpy h "Dry air enthalpy";
      algorithm
        h := (T - reference_T) * dryair.cp;
        annotation(smoothOrder = 5, Inline = true, derivative = der_enthalpyOfDryAir);
      end enthalpyOfDryAir;

      replaceable function der_enthalpyOfDryAir  "Derivative of enthalpy of dry air per unit mass of dry air"
        extends Modelica.Icons.Function;
        input Temperature T "Temperature";
        input Real der_T "Temperature derivative";
        output Real der_h "Derivative of dry air enthalpy";
      algorithm
        der_h := dryair.cp * der_T;
        annotation(Inline = true);
      end der_enthalpyOfDryAir;

      replaceable function der_specificHeatCapacityCp  "Derivative of specific heat capacity of gas mixture at constant pressure"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state";
        input ThermodynamicState der_state "Derivative of thermodynamic state";
        output Real der_cp(unit = "J/(kg.K.s)") "Derivative of specific heat capacity";
      algorithm
        der_cp := (steam.cp - dryair.cp) * der_state.X[Water];
        annotation(Inline = true);
      end der_specificHeatCapacityCp;

      replaceable function der_specificHeatCapacityCv  "Derivative of specific heat capacity of gas mixture at constant volume"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state";
        input ThermodynamicState der_state "Derivative of thermodynamic state";
        output Real der_cv(unit = "J/(kg.K.s)") "Derivative of specific heat capacity";
      algorithm
        der_cv := (steam.cv - dryair.cv) * der_state.X[Water];
        annotation(Inline = true);
      end der_specificHeatCapacityCv;
    end Air;
  end Media;

  package Utilities  "Package with utility functions such as for I/O"
    extends Modelica.Icons.Package;

    package Math  "Library with functions such as for smoothing"
      extends Modelica.Icons.Package;

      package Functions  "Package with mathematical functions"
        extends Modelica.Icons.VariantsPackage;

        function inverseXRegularized  "Function that approximates 1/x by a twice continuously differentiable function"
          input Real x "Abscissa value";
          input Real delta(min = Modelica.Constants.eps) "Abscissa value below which approximation occurs";
          input Real deltaInv = 1 / delta "Inverse value of delta";
          input Real a = -15 * deltaInv "Polynomial coefficient";
          input Real b = 119 * deltaInv ^ 2 "Polynomial coefficient";
          input Real c = -361 * deltaInv ^ 3 "Polynomial coefficient";
          input Real d = 534 * deltaInv ^ 4 "Polynomial coefficient";
          input Real e = -380 * deltaInv ^ 5 "Polynomial coefficient";
          input Real f = 104 * deltaInv ^ 6 "Polynomial coefficient";
          output Real y "Function value";
        algorithm
          y := if x > delta or x < (-delta) then 1 / x elseif x < delta / 2 and x > (-delta / 2) then x / (delta * delta) else BaseClasses.smoothTransition(x = x, delta = delta, deltaInv = deltaInv, a = a, b = b, c = c, d = d, e = e, f = f);
          annotation(smoothOrder = 2, derivative(order = 1, zeroDerivative = delta, zeroDerivative = deltaInv, zeroDerivative = a, zeroDerivative = b, zeroDerivative = c, zeroDerivative = d, zeroDerivative = e, zeroDerivative = f) = Buildings.Utilities.Math.Functions.BaseClasses.der_inverseXRegularized, Inline = true);
        end inverseXRegularized;

        function regStep  "Approximation of a general step, such that the approximation is continuous and differentiable"
          extends Modelica.Icons.Function;
          input Real x "Abscissa value";
          input Real y1 "Ordinate value for x > 0";
          input Real y2 "Ordinate value for x < 0";
          input Real x_small(min = 0) = 1e-5 "Approximation of step for -x_small <= x <= x_small; x_small >= 0 required";
          output Real y "Ordinate value to approximate y = if x > 0 then y1 else y2";
        algorithm
          y := smooth(1, if x > x_small then y1 else if x < (-x_small) then y2 else if x_small > 0 then x / x_small * ((x / x_small) ^ 2 - 3) * (y2 - y1) / 4 + (y1 + y2) / 2 else (y1 + y2) / 2);
          annotation(Inline = true);
        end regStep;

        function smoothLimit  "Once continuously differentiable approximation to the limit function"
          input Real x "Variable";
          input Real l "Low limit";
          input Real u "Upper limit";
          input Real deltaX "Width of transition interval";
          output Real y "Result";
        protected
          Real cor;
        algorithm
          cor := deltaX / 10;
          y := Buildings.Utilities.Math.Functions.smoothMax(x, l + deltaX, cor);
          y := Buildings.Utilities.Math.Functions.smoothMin(y, u - deltaX, cor);
          annotation(smoothOrder = 1);
        end smoothLimit;

        function smoothMax  "Once continuously differentiable approximation to the maximum function"
          input Real x1 "First argument";
          input Real x2 "Second argument";
          input Real deltaX "Width of transition interval";
          output Real y "Result";
        algorithm
          y := Buildings.Utilities.Math.Functions.regStep(y1 = x1, y2 = x2, x = x1 - x2, x_small = deltaX);
          annotation(Inline = true, smoothOrder = 1);
        end smoothMax;

        function smoothMin  "Once continuously differentiable approximation to the minimum function"
          input Real x1 "First argument";
          input Real x2 "Second argument";
          input Real deltaX "Width of transition interval";
          output Real y "Result";
        algorithm
          y := Buildings.Utilities.Math.Functions.regStep(y1 = x1, y2 = x2, x = x2 - x1, x_small = deltaX);
          annotation(Inline = true, smoothOrder = 1);
        end smoothMin;

        function spliceFunction
          input Real pos "Argument of x > 0";
          input Real neg "Argument of x < 0";
          input Real x "Independent value";
          input Real deltax "Half width of transition interval";
          output Real out "Smoothed value";
        protected
          Real scaledX1;
          Real y;
          constant Real asin1 = Modelica.Math.asin(1);
        algorithm
          scaledX1 := x / deltax;
          if scaledX1 <= (-0.999999999) then
            out := neg;
          elseif scaledX1 >= 0.999999999 then
            out := pos;
          else
            y := (Modelica.Math.tanh(Modelica.Math.tan(scaledX1 * asin1)) + 1) / 2;
            out := pos * y + (1 - y) * neg;
          end if;
          annotation(smoothOrder = 1, derivative = BaseClasses.der_spliceFunction);
        end spliceFunction;

        package BaseClasses  "Package with base classes for Buildings.Utilities.Math.Functions"
          extends Modelica.Icons.BasesPackage;

          function der_2_smoothTransition  "Second order derivative of smoothTransition with respect to x"
            input Real x "Abscissa value";
            input Real delta(min = Modelica.Constants.eps) "Abscissa value below which approximation occurs";
            input Real deltaInv "Inverse value of delta";
            input Real a "Polynomial coefficient";
            input Real b "Polynomial coefficient";
            input Real c "Polynomial coefficient";
            input Real d "Polynomial coefficient";
            input Real e "Polynomial coefficient";
            input Real f "Polynomial coefficient";
            input Real x_der "Derivative of x";
            input Real x_der2 "Second order derivative of x";
            output Real y_der2 "Second order derivative of function value";
          protected
            Real aX "Absolute value of x";
            Real ex "Intermediate expression";
          algorithm
            aX := abs(x);
            ex := 2 * c + aX * (6 * d + aX * (12 * e + aX * 20 * f));
            y_der2 := (b + aX * (2 * c + aX * (3 * d + aX * (4 * e + aX * 5 * f)))) * x_der2 + x_der * x_der * (if x > 0 then ex else -ex);
          end der_2_smoothTransition;

          function der_inverseXRegularized  "Derivative of inverseXRegularised function"
            input Real x "Abscissa value";
            input Real delta(min = Modelica.Constants.eps) "Abscissa value below which approximation occurs";
            input Real deltaInv = 1 / delta "Inverse value of delta";
            input Real a = -15 * deltaInv "Polynomial coefficient";
            input Real b = 119 * deltaInv ^ 2 "Polynomial coefficient";
            input Real c = -361 * deltaInv ^ 3 "Polynomial coefficient";
            input Real d = 534 * deltaInv ^ 4 "Polynomial coefficient";
            input Real e = -380 * deltaInv ^ 5 "Polynomial coefficient";
            input Real f = 104 * deltaInv ^ 6 "Polynomial coefficient";
            input Real x_der "Abscissa value";
            output Real y_der "Function value";
          algorithm
            y_der := if x > delta or x < (-delta) then -x_der / x / x elseif x < delta / 2 and x > (-delta / 2) then x_der / (delta * delta) else Buildings.Utilities.Math.Functions.BaseClasses.der_smoothTransition(x = x, x_der = x_der, delta = delta, deltaInv = deltaInv, a = a, b = b, c = c, d = d, e = e, f = f);
          end der_inverseXRegularized;

          function der_smoothTransition  "First order derivative of smoothTransition with respect to x"
            input Real x "Abscissa value";
            input Real delta(min = Modelica.Constants.eps) "Abscissa value below which approximation occurs";
            input Real deltaInv "Inverse value of delta";
            input Real a "Polynomial coefficient";
            input Real b "Polynomial coefficient";
            input Real c "Polynomial coefficient";
            input Real d "Polynomial coefficient";
            input Real e "Polynomial coefficient";
            input Real f "Polynomial coefficient";
            input Real x_der "Derivative of x";
            output Real y_der "Derivative of function value";
          protected
            Real aX "Absolute value of x";
          algorithm
            aX := abs(x);
            y_der := (b + aX * (2 * c + aX * (3 * d + aX * (4 * e + aX * 5 * f)))) * x_der;
            annotation(smoothOrder = 1, derivative(order = 2, zeroDerivative = delta, zeroDerivative = deltaInv, zeroDerivative = a, zeroDerivative = b, zeroDerivative = c, zeroDerivative = d, zeroDerivative = e, zeroDerivative = f) = Buildings.Utilities.Math.Functions.BaseClasses.der_2_smoothTransition);
          end der_smoothTransition;

          function der_spliceFunction  "Derivative of splice function"
            input Real pos;
            input Real neg;
            input Real x;
            input Real deltax = 1;
            input Real dpos;
            input Real dneg;
            input Real dx;
            input Real ddeltax = 0;
            output Real out;
          protected
            Real scaledX;
            Real scaledX1;
            Real dscaledX1;
            Real y;
            constant Real asin1 = Modelica.Math.asin(1);
          algorithm
            scaledX1 := x / deltax;
            if scaledX1 <= (-0.99999999999) then
              out := dneg;
            elseif scaledX1 >= 0.9999999999 then
              out := dpos;
            else
              scaledX := scaledX1 * asin1;
              dscaledX1 := (dx - scaledX1 * ddeltax) / deltax;
              y := (Modelica.Math.tanh(Modelica.Math.tan(scaledX)) + 1) / 2;
              out := dpos * y + (1 - y) * dneg;
              out := out + (pos - neg) * dscaledX1 * asin1 / 2 / (Modelica.Math.cosh(Modelica.Math.tan(scaledX)) * Modelica.Math.cos(scaledX)) ^ 2;
            end if;
          end der_spliceFunction;

          function smoothTransition  "Twice continuously differentiable transition between the regions"
            input Real x "Abscissa value";
            input Real delta(min = Modelica.Constants.eps) "Abscissa value below which approximation occurs";
            input Real deltaInv = 1 / delta "Inverse value of delta";
            input Real a = -15 * deltaInv "Polynomial coefficient";
            input Real b = 119 * deltaInv ^ 2 "Polynomial coefficient";
            input Real c = -361 * deltaInv ^ 3 "Polynomial coefficient";
            input Real d = 534 * deltaInv ^ 4 "Polynomial coefficient";
            input Real e = -380 * deltaInv ^ 5 "Polynomial coefficient";
            input Real f = 104 * deltaInv ^ 6 "Polynomial coefficient";
            output Real y "Function value";
          protected
            Real aX "Absolute value of x";
          algorithm
            aX := abs(x);
            y := a + aX * (b + aX * (c + aX * (d + aX * (e + aX * f))));
            if x < 0 then
              y := -y;
            else
            end if;
            annotation(smoothOrder = 2, derivative(order = 1, zeroDerivative = delta, zeroDerivative = deltaInv, zeroDerivative = a, zeroDerivative = b, zeroDerivative = c, zeroDerivative = d, zeroDerivative = e, zeroDerivative = f) = Buildings.Utilities.Math.Functions.BaseClasses.der_smoothTransition);
          end smoothTransition;
        end BaseClasses;
      end Functions;
    end Math;

    package Psychrometrics  "Library with psychrometric functions"
      extends Modelica.Icons.VariantsPackage;

      package Constants  "Library of constants for psychometric functions"
        extends Modelica.Icons.Package;
        constant Modelica.SIunits.Temperature T_ref = 273.15 "Reference temperature for psychrometric calculations";
        constant Modelica.SIunits.SpecificHeatCapacity cpAir = 1006 "Specific heat capacity of air";
        constant Modelica.SIunits.SpecificHeatCapacity cpSte = 1860 "Specific heat capacity of water vapor";
        constant Modelica.SIunits.SpecificHeatCapacity cpWatLiq = 4184 "Specific heat capacity of liquid water";
        constant Modelica.SIunits.SpecificEnthalpy h_fg = 2501014.5 "Enthalpy of evaporation of water at the reference temperature";
      end Constants;

      block TWetBul_TDryBulPhi  "Model to compute the wet bulb temperature based on relative humidity"
        extends Modelica.Blocks.Icons.Block;
        replaceable package Medium = Modelica.Media.Interfaces.PartialCondensingGases "Medium model" annotation(choicesAllMatching = true);
        parameter Boolean approximateWetBulb = false "Set to true to approximate wet bulb temperature" annotation(Evaluate = true);
        Modelica.Blocks.Interfaces.RealInput TDryBul(start = Medium.T_default, final quantity = "ThermodynamicTemperature", final unit = "K", min = 0) "Dry bulb temperature";
        Modelica.Blocks.Interfaces.RealInput phi(min = 0, max = 1) "Relative air humidity";
        Modelica.Blocks.Interfaces.RealInput p(final quantity = "Pressure", final unit = "Pa", min = 0) "Pressure";
        Modelica.Blocks.Interfaces.RealOutput TWetBul(start = Medium.T_default - 2, final quantity = "ThermodynamicTemperature", final unit = "K", min = 0) "Wet bulb temperature";
      protected
        Modelica.SIunits.Conversions.NonSIunits.Temperature_degC TDryBul_degC "Dry bulb temperature in degree Celsius";
        Real rh_per(min = 0) "Relative humidity in percentage";
        Modelica.SIunits.MassFraction XiDryBul "Water vapor mass fraction at dry bulb state";
        Modelica.SIunits.MassFraction XiSat "Water vapor mass fraction at saturation";
        Modelica.SIunits.MassFraction XiSatRefIn "Water vapor mass fraction at saturation, referenced to inlet mass flow rate";
      equation
        if approximateWetBulb then
          TDryBul_degC = TDryBul - 273.15;
          rh_per = 100 * phi;
          TWetBul = 273.15 + TDryBul_degC * Modelica.Math.atan(0.151977 * sqrt(rh_per + 8.313659)) + Modelica.Math.atan(TDryBul_degC + rh_per) - Modelica.Math.atan(rh_per - 1.676331) + 0.00391838 * rh_per ^ 1.5 * Modelica.Math.atan(0.023101 * rh_per) - 4.686035;
          XiSat = 0;
          XiDryBul = 0;
          XiSatRefIn = 0;
        else
          XiSatRefIn = (1 - XiDryBul) * XiSat / (1 - XiSat);
          XiSat = Functions.X_pSatpphi(pSat = Functions.saturationPressureLiquid(TWetBul), p = p, phi = 1);
          XiDryBul = Functions.X_pSatpphi(p = p, pSat = Functions.saturationPressureLiquid(TDryBul), phi = phi);
          (TWetBul - Constants.T_ref) * ((1 - XiDryBul) * Constants.cpAir + XiSatRefIn * Constants.cpSte + (XiDryBul - XiSatRefIn) * Constants.cpWatLiq) = (TDryBul - Constants.T_ref) * ((1 - XiDryBul) * Constants.cpAir + XiDryBul * Constants.cpSte) + (XiDryBul - XiSatRefIn) * Constants.h_fg;
          TDryBul_degC = 0;
          rh_per = 0;
        end if;
      end TWetBul_TDryBulPhi;

      package Functions  "Package with psychrometric functions"
        extends Modelica.Icons.Package;

        function X_pSatpphi  "Humidity ratio for given water vapor pressure"
          extends Modelica.Icons.Function;
          input Modelica.SIunits.AbsolutePressure pSat "Saturation pressure";
          input Modelica.SIunits.Pressure p "Pressure of the fluid";
          input Real phi(min = 0, max = 1) "Relative humidity";
          output Modelica.SIunits.MassFraction X_w(min = 0, max = 1, nominal = 0.01) "Water vapor concentration per total mass of air";
        protected
          constant Real k = 0.621964713077499 "Ratio of molar masses";
        algorithm
          X_w := phi * k / (k * phi + p / pSat - phi);
          annotation(smoothOrder = 99, Inline = true);
        end X_pSatpphi;

        function saturationPressure  "Saturation curve valid for 223.16 <= T <= 373.16 (and slightly outside with less accuracy)"
          extends Modelica.Icons.Function;
          input Modelica.SIunits.Temperature TSat(displayUnit = "degC", nominal = 300) "Saturation temperature";
          output Modelica.SIunits.AbsolutePressure pSat(displayUnit = "Pa", nominal = 1000) "Saturation pressure";
        algorithm
          pSat := Buildings.Utilities.Math.Functions.regStep(y1 = Buildings.Utilities.Psychrometrics.Functions.saturationPressureLiquid(TSat), y2 = Buildings.Utilities.Psychrometrics.Functions.sublimationPressureIce(TSat), x = TSat - 273.16, x_small = 1.0);
          annotation(Inline = true, smoothOrder = 1);
        end saturationPressure;

        function saturationPressureLiquid  "Return saturation pressure of water as a function of temperature T in the range of 273.16 to 373.16 K"
          extends Modelica.Icons.Function;
          input Modelica.SIunits.Temperature TSat(displayUnit = "degC", nominal = 300) "Saturation temperature";
          output Modelica.SIunits.AbsolutePressure pSat(displayUnit = "Pa", nominal = 1000) "Saturation pressure";
        algorithm
          pSat := 611.657 * Modelica.Math.exp(17.2799 - 4102.99 / (TSat - 35.719));
          annotation(smoothOrder = 99, derivative = Buildings.Utilities.Psychrometrics.Functions.BaseClasses.der_saturationPressureLiquid, Inline = true);
        end saturationPressureLiquid;

        function sublimationPressureIce  "Return sublimation pressure of water as a function of temperature T between 190 and 273.16 K"
          extends Modelica.Icons.Function;
          input Modelica.SIunits.Temperature TSat(displayUnit = "degC", nominal = 300) "Saturation temperature";
          output Modelica.SIunits.AbsolutePressure pSat(displayUnit = "Pa", nominal = 1000) "Saturation pressure";
        protected
          Modelica.SIunits.Temperature TTriple = 273.16 "Triple point temperature";
          Modelica.SIunits.AbsolutePressure pTriple = 611.657 "Triple point pressure";
          Real r1 = TSat / TTriple "Common subexpression";
          Real[2] a = {-13.9281690, 34.7078238} "Coefficients a[:]";
          Real[2] n = {-1.5, -1.25} "Coefficients n[:]";
        algorithm
          pSat := exp(a[1] - a[1] * r1 ^ n[1] + a[2] - a[2] * r1 ^ n[2]) * pTriple;
          annotation(Inline = false, smoothOrder = 5, derivative = Buildings.Utilities.Psychrometrics.Functions.BaseClasses.der_sublimationPressureIce);
        end sublimationPressureIce;

        package BaseClasses  "Package with base classes for Buildings.Utilities.Psychrometrics.Functions"
          extends Modelica.Icons.BasesPackage;

          function der_saturationPressureLiquid  "Derivative of the function saturationPressureLiquid"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Temperature Tsat "Saturation temperature";
            input Real dTsat(unit = "K/s") "Saturation temperature derivative";
            output Real psat_der(unit = "Pa/s") "Differential of saturation pressure";
          algorithm
            psat_der := 611.657 * Modelica.Math.exp(17.2799 - 4102.99 / (Tsat - 35.719)) * 4102.99 * dTsat / (Tsat - 35.719) ^ 2;
            annotation(Inline = false, smoothOrder = 5);
          end der_saturationPressureLiquid;

          function der_sublimationPressureIce  "Derivative of function sublimationPressureIce"
            extends Modelica.Icons.Function;
            input Modelica.SIunits.Temperature TSat(displayUnit = "degC", nominal = 300) "Saturation temperature";
            input Real dTsat(unit = "K/s") "Sublimation temperature derivative";
            output Real psat_der(unit = "Pa/s") "Sublimation pressure derivative";
          protected
            Modelica.SIunits.Temperature TTriple = 273.16 "Triple point temperature";
            Modelica.SIunits.AbsolutePressure pTriple = 611.657 "Triple point pressure";
            Real r1 = TSat / TTriple "Common subexpression 1";
            Real r1_der = dTsat / TTriple "Derivative of common subexpression 1";
            Real[2] a = {-13.9281690, 34.7078238} "Coefficients a[:]";
            Real[2] n = {-1.5, -1.25} "Coefficients n[:]";
          algorithm
            psat_der := exp(a[1] - a[1] * r1 ^ n[1] + a[2] - a[2] * r1 ^ n[2]) * pTriple * ((-a[1] * (r1 ^ (n[1] - 1) * n[1] * r1_der)) - a[2] * (r1 ^ (n[2] - 1) * n[2] * r1_der));
            annotation(Inline = false, smoothOrder = 5);
          end der_sublimationPressureIce;
        end BaseClasses;
      end Functions;
    end Psychrometrics;

    package Time  "Package with models for time"
      extends Modelica.Icons.Package;

      block ModelTime  "Model time"
        extends Modelica.Blocks.Interfaces.SO;
      equation
        y = time;
      end ModelTime;
    end Time;
  end Utilities;
  annotation(version = "4.0.0", versionDate = "2016-03-29", dateModified = "2016-03-29");
end Buildings;

model ReaderTMY3_total  "Test model for reading weather data"
  extends Buildings.BoundaryConditions.WeatherData.Examples.ReaderTMY3;
 annotation(experiment(StopTime = 8640000), __Dymola_Commands(file = "modelica://Buildings/Resources/Scripts/Dymola/BoundaryConditions/WeatherData/Examples/ReaderTMY3.mos"));
end ReaderTMY3_total;
