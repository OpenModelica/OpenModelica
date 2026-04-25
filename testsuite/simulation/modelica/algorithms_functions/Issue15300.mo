package Buildings "Library with models for building energy and control systems"
  extends Modelica.Icons.Package;

  package Utilities "Package with utility functions such as for I/O"
    extends Modelica.Icons.Package;

    package IO "Input and output"
      extends Modelica.Icons.Package;

      package Files "Reports package"
        extends Modelica.Icons.Package;

        model CSVWriter "Model for writing results to a .csv file"
          extends Buildings.Utilities.IO.Files.BaseClasses.FileWriter(final isCombiTimeTable = false);
        initial algorithm
          if writeHeader then
            str := str + "time" + delimiter;
            for i in 1:nin - 1 loop
              str := str + headerNames[i] + delimiter;
              if mod(i + 1, 10) == 0 then
                writeLine(filWri, str, 1);
                str := "";
              else
              end if;
            end for;
            str := str + headerNames[nin] + "\n";
            writeLine(filWri, str, 1);
          else
          end if;
        end CSVWriter;

        package BaseClasses "Package with base classes for Buildings.Utilities.IO.Files"
          extends Modelica.Icons.BasesPackage;

          model FileWriter "Partial model for writing results to a .csv file"
            extends Modelica.Blocks.Icons.DiscreteBlock;
            parameter Integer nin "Number of inputs" annotation(Evaluate = true);
            parameter String fileName = getInstanceName() + ".csv" "File name, including extension";
            parameter Modelica.Units.SI.Time samplePeriod "Sample period: equidistant interval for which the inputs are saved";
            parameter String delimiter = "\t" "Delimiter for csv file";
            parameter Boolean writeHeader = true "=true, to write header with variable names, otherwise no header will be written";
            parameter String headerNames[nin] = {"col" + String(i) for i in 1:nin} "Header names, indices by default";
            parameter Integer significantDigits(min = 1, max = 15) = 6 "Number of significant digits that are used for converting inputs into string format";
            Modelica.Blocks.Interfaces.RealVectorInput u[nin] "Variables that are saved";
          protected
            parameter Boolean isCombiTimeTable = false "=true, if CombiTimeTable header should be prepended upon destruction" annotation(Evaluate = true);
            parameter Modelica.Units.SI.Time t0(fixed = false) "First sample time instant";
            parameter String insNam = getInstanceName() "Instance name";
            Buildings.Utilities.IO.Files.BaseClasses.FileWriterObject filWri = Buildings.Utilities.IO.Files.BaseClasses.FileWriterObject(insNam, fileName, nin + 1, isCombiTimeTable) "File writer object";
            discrete String str "Intermediate variable for constructing a single line";
            output Boolean sampleTrigger "True, if sample time instant";

            function writeLine "Prepend a string to an existing text file"
              extends Modelica.Icons.Function;
              input Buildings.Utilities.IO.Files.BaseClasses.FileWriterObject id "ID of the file writer";
              input String string "Written string";
              input Integer isMetaData "=1, if line should not be included for row count of combiTimeTable";
              external "C" writeLine(id, string, isMetaData) annotation(Include = "#include \"fileWriterStructure.h\"", IncludeDirectory = "modelica://Buildings/Resources/C-Sources");
            end writeLine;
          initial equation
            t0 = time;
          equation
            sampleTrigger = sample(t0, samplePeriod);
          algorithm
            when sampleTrigger then
              str := String(time, significantDigits = significantDigits) + delimiter;
              for i in 1:nin - 1 loop
                str := str + String(u[i], significantDigits = significantDigits) + delimiter;
                if mod(i + 1, 10) == 0 then
                  writeLine(filWri, str, 1);
                  str := "";
                else
                end if;
              end for;
              str := str + String(u[nin], significantDigits = significantDigits) + "\n";
              writeLine(filWri, str, 0);
            end when;
          end FileWriter;

          class FileWriterObject "Class used to ensure that each CSV writer writes to a unique file"
            extends ExternalObject;

            function constructor "Construct an extendable array that can be used to store double valuesCreate empty file"
              extends Modelica.Icons.Function;
              input String instanceName "Instance name of the file write";
              input String fileName "Name of the file, including extension";
              input Integer numColumns "Number of columns that are written to file";
              input Boolean isCombiTimeTable "Flag to indicate whether combiTimeTable header should be prepended upon destruction";
              output FileWriterObject fileWriter "Pointer to the file writer";
              external "C" fileWriter = fileWriterInit(instanceName, fileName, numColumns, isCombiTimeTable) annotation(Include = "#include <fileWriterInit.c>", IncludeDirectory = "modelica://Buildings/Resources/C-Sources");
            end constructor;

            function destructor "Release storage and close the external object"
              input FileWriterObject fileWriter "Pointer to file writer object";
              external "C" fileWriterFree(fileWriter) annotation(Include = " #include <fileWriterFree.c>", IncludeDirectory = "modelica://Buildings/Resources/C-Sources");
            end destructor;
          end FileWriterObject;
        end BaseClasses;
      end Files;
    end IO;
  end Utilities;
  annotation(version = "12.1.0", versionDate = "2025-05-29", dateModified = "2025-05-29");
end Buildings;

model zyb_immobilization_rates
  Modelica.Blocks.Interfaces.RealOutput ava_out;
  Modelica.Blocks.Interfaces.RealOutput avn_out;
  Modelica.Blocks.Interfaces.RealOutput v30;
  Modelica.Blocks.Interfaces.RealOutput v37;
  Modelica.Blocks.Interfaces.RealOutput v31;
  Modelica.Blocks.Interfaces.RealInput ava_in;
  Modelica.Blocks.Interfaces.RealInput avn_in;
  Modelica.Blocks.Interfaces.RealInput requin;
  Modelica.Blocks.Interfaces.RealInput v22;
  Modelica.Blocks.Interfaces.RealInput v24;
  imm_rates_update imm_rates_update1;
  ava_update ava_update1;
  Modelica.Blocks.Math.Max max;
  Modelica.Blocks.Sources.RealExpression realExpression;
  Modelica.Blocks.Math.Add add(k2 = -1);
  Modelica.Blocks.Math.Add add1(k1 = -1);
  Modelica.Blocks.Routing.Multiplex mux(n = 4);
  Modelica.Blocks.Routing.Multiplex mux1(n = 3);
  Modelica.Blocks.Routing.DeMultiplex demux(n = 4);
  Modelica.Blocks.Routing.DeMultiplex demux1(n = 4);
  Modelica.Blocks.Routing.DeMultiplex demux2(n = 3);
  Modelica.Blocks.Routing.DeMultiplex demux3(n = 3);
equation
  connect(ava_in, mux.u[1]);
  connect(avn_in, mux.u[2]);
  connect(v22, mux.u[3]);
  connect(v24, mux.u[4]);
  connect(mux.y, demux.u);
  connect(demux.y[1], imm_rates_update1.ava);
  connect(demux.y[2], imm_rates_update1.avn);
  connect(demux.y[3], imm_rates_update1.v22);
  connect(demux.y[4], imm_rates_update1.v24);
  connect(requin, imm_rates_update1.requin);
  connect(mux.y, demux1.u);
  connect(demux1.y[1], ava_update1.ava_in);
  connect(demux1.y[2], ava_update1.avn_in);
  connect(demux1.y[3], ava_update1.v22);
  connect(demux1.y[4], ava_update1.v24);
  connect(imm_rates_update1.v30, mux1.u[1]);
  connect(imm_rates_update1.v31, mux1.u[2]);
  connect(imm_rates_update1.v37, mux1.u[3]);
  connect(mux1.y, demux2.u);
  connect(demux2.y[1], ava_update1.v30);
  connect(demux2.y[2], ava_update1.v31);
  connect(demux2.y[3], ava_update1.v37);
  connect(ava_update1.avn_out, avn_out);
  connect(ava_update1.ava_out, max.u1);
  connect(realExpression.y, max.u2);
  connect(max.y, ava_out);
  connect(max.y, add.u1);
  connect(ava_update1.ava_out, add.u2);
  connect(add.y, add1.u1);
  connect(mux1.y, demux3.u);
  connect(demux3.y[1], add1.u2);
  connect(demux3.y[2], v31);
  connect(demux3.y[3], v37);
  connect(add1.y, v30);
  annotation(version = "");
end zyb_immobilization_rates;

model ava_update
  Modelica.Blocks.Interfaces.RealInput ava_in;
  Modelica.Blocks.Interfaces.RealInput v22;
  Modelica.Blocks.Interfaces.RealInput v24;
  Modelica.Blocks.Interfaces.RealInput v31;
  Modelica.Blocks.Interfaces.RealInput v37;
  Modelica.Blocks.Interfaces.RealInput avn_in;
  Modelica.Blocks.Interfaces.RealOutput ava_out;
  Modelica.Blocks.Interfaces.RealOutput avn_out;
  Modelica.Blocks.Routing.Multiplex mux(n = 5);
  Modelica.Blocks.Math.Sum sum1(nin = 5);
  Modelica.Blocks.Math.Add add(k2 = -1);
  Modelica.Blocks.Interfaces.RealInput v30;
  Modelica.Blocks.Math.Gain gain(k = -1);
equation
  connect(mux.y, sum1.u);
  connect(sum1.y, ava_out);
  connect(avn_in, add.u1);
  connect(v31, add.u2);
  connect(add.y, avn_out);
  connect(v30, gain.u);
  connect(ava_in, mux.u[1]);
  connect(v22, mux.u[2]);
  connect(v24, mux.u[3]);
  connect(gain.y, mux.u[4]);
  connect(v37, mux.u[5]);
  annotation(version = "");
end ava_update;

model imm_rates_update
  Modelica.Blocks.Interfaces.RealInput requin;
  Modelica.Blocks.Interfaces.RealInput ava;
  Modelica.Blocks.Interfaces.RealInput avn;
  Modelica.Blocks.Interfaces.RealInput v22;
  Modelica.Blocks.Interfaces.RealInput v24;
  Modelica.Blocks.Interfaces.RealOutput v30;
  Modelica.Blocks.Interfaces.RealOutput v31;
  Modelica.Blocks.Interfaces.RealOutput v37;
  Modelica.Blocks.Math.Max max;
  Modelica.Blocks.Math.Min min;
  Modelica.Blocks.Sources.Constant const(k = 0);
  Modelica.Blocks.Sources.Constant const1(k = 0);
  Modelica.Blocks.Math.Gain gain(k = -1);
  imm_rates_part imm_rates_part1;
  Modelica.Blocks.Routing.Multiplex mux(n = 3);
  Modelica.Blocks.Math.Sum sum1(nin = 3);
equation
  connect(imm_rates_part1.v31, v31);
  connect(imm_rates_part1.v30, mux.u[1]);
  connect(v22, mux.u[2]);
  connect(v24, mux.u[3]);
  connect(mux.y, sum1.u);
  connect(sum1.y, max.u1);
  connect(const.y, max.u2);
  connect(max.y, v30);
  connect(sum1.y, min.u1);
  connect(const1.y, min.u2);
  connect(min.y, gain.u);
  connect(gain.y, v37);
  connect(avn, imm_rates_part1.avn);
  connect(ava, imm_rates_part1.ava);
  connect(requin, imm_rates_part1.requin);
  annotation(version = "");
end imm_rates_update;

model imm_rates_part
  Modelica.Blocks.Interfaces.RealInput requin;
  Modelica.Blocks.Interfaces.RealInput ava;
  Modelica.Blocks.Interfaces.RealInput avn;
  Modelica.Blocks.Interfaces.RealOutput v30;
  Modelica.Blocks.Interfaces.RealOutput v31;
algorithm
  if requin > 0 then
    v30 := min(requin, ava);
    v31 := min(requin - v30, avn);
  else
    v30 := requin;
    v31 := 0;
  end if;
  annotation(version = "");
end imm_rates_part;

package ModelicaServices "ModelicaServices (OpenModelica implementation) - Models and functions used in the Modelica Standard Library requiring a tool specific implementation"
  extends Modelica.Icons.Package;

  package Machine "Machine dependent constants"
    extends Modelica.Icons.Package;
    final constant Real eps = 2.2204460492503131e-016 "The difference between 1 and the least value greater than 1 that is representable in the given floating point type";
    final constant Real small = 2.2250738585072014e-308 "Minimum normalized positive floating-point number";
    final constant Real inf = 1e60 "Maximum representable finite floating-point number";
    final constant Integer Integer_inf = OpenModelica.Internal.Architecture.integerMax() "Biggest Integer number such that Integer_inf and -Integer_inf are representable on the machine";
  end Machine;
  annotation(version = "4.1.0", versionDate = "2025-05-23", dateModified = "2025-05-23 15:00:00Z");
end ModelicaServices;

package Modelica "Modelica Standard Library"
  extends Modelica.Icons.Package;

  package Blocks "Library of basic input/output control blocks (continuous, discrete, logical, table blocks)"
    extends Modelica.Icons.Package;
    import Modelica.Units.SI;

    package Interfaces "Library of connectors and partial models for input/output blocks"
      extends Modelica.Icons.InterfacesPackage;
      connector RealInput = input Real "'input Real' as connector";
      connector RealOutput = output Real "'output Real' as connector";
      connector RealVectorInput = input Real "Real input connector used for vector of connectors";
      connector RealVectorOutput = output Real "Real output connector used for vector of connectors";

      partial block SO "Single Output continuous control block"
        extends Modelica.Blocks.Icons.Block;
        RealOutput y "Connector of Real output signal";
      end SO;

      partial block MO "Multiple Output continuous control block"
        extends Modelica.Blocks.Icons.Block;
        parameter Integer nout(min = 1) = 1 "Number of outputs";
        RealOutput y[nout] "Connector of Real output signals";
      end MO;

      partial block SI2SO "2 Single Input / 1 Single Output continuous control block"
        extends Modelica.Blocks.Icons.Block;
        RealInput u1 "Connector of Real input signal 1";
        RealInput u2 "Connector of Real input signal 2";
        RealOutput y "Connector of Real output signal";
      end SI2SO;

      partial block MISO "Multiple Input Single Output continuous control block"
        extends Modelica.Blocks.Icons.Block;
        parameter Integer nin = 1 "Number of inputs";
        RealInput u[nin] "Connector of Real input signals";
        RealOutput y "Connector of Real output signal";
      end MISO;
    end Interfaces;

    package Math "Library of Real mathematical functions as input/output blocks"
      import Modelica.Blocks.Interfaces;
      extends Modelica.Icons.Package;

      block Gain "Output the product of a gain value with the input signal"
        parameter Real k(start = 1) "Gain value multiplied with input signal";
        Interfaces.RealInput u "Input signal connector";
        Interfaces.RealOutput y "Output signal connector";
      equation
        y = k*u;
      end Gain;

      block Sum "Output the sum of the elements of the input vector"
        extends Interfaces.MISO;
        parameter Real k[nin] = ones(nin) "Optional: sum coefficients";
      equation
        y = k*u;
      end Sum;

      block Add "Output the sum of the two inputs"
        extends Interfaces.SI2SO;
        parameter Real k1 = +1 "Gain of input signal 1";
        parameter Real k2 = +1 "Gain of input signal 2";
      equation
        y = k1*u1 + k2*u2;
      end Add;

      block Max "Pass through the largest signal"
        extends Interfaces.SI2SO;
      equation
        y = max(u1, u2);
      end Max;

      block Min "Pass through the smallest signal"
        extends Interfaces.SI2SO;
      equation
        y = min(u1, u2);
      end Min;
    end Math;

    package Routing "Library of blocks to combine and extract signals"
      extends Modelica.Icons.Package;

      block Multiplex "Multiplexer block for arbitrary number of input connectors"
        extends Modelica.Blocks.Icons.Block;
        parameter Integer n(min = 0) = 0 "Dimension of input signal connector" annotation(HideResult = true);
        Modelica.Blocks.Interfaces.RealVectorInput u[n] "Connector of Real input signals";
        Modelica.Blocks.Interfaces.RealOutput y[n + 0] "Connector of Real output signals";
      equation
        y = u;
      end Multiplex;

      block DeMultiplex "DeMultiplexer block for arbitrary number of output connectors"
        extends Modelica.Blocks.Icons.Block;
        parameter Integer n(min = 0) = 0 "Dimension of output signal connector" annotation(HideResult = true);
        Modelica.Blocks.Interfaces.RealInput u[n + 0] "Connector of Real input signals";
        Modelica.Blocks.Interfaces.RealVectorOutput y[n] "Connector of Real output signals";
      equation
        y = u;
      end DeMultiplex;
    end Routing;

    package Sources "Library of signal source blocks generating Real, Integer and Boolean signals"
      import Modelica.Blocks.Interfaces;
      extends Modelica.Icons.SourcesPackage;

      block RealExpression "Set output signal to a time varying Real expression"
        Modelica.Blocks.Interfaces.RealOutput y = 0.0 "Value of Real output";
      end RealExpression;

      block Constant "Generate constant signal of type Real"
        parameter Real k(start = 1) "Constant output value";
        extends Interfaces.SO;
      equation
        y = k;
      end Constant;

      block CombiTimeTable "Table look-up with respect to time and various interpolation and extrapolation methods (data from matrix/file)"
        import Modelica.Blocks.Tables.Internal;
        extends Modelica.Blocks.Interfaces.MO(final nout = max([size(columns, 1); size(offset, 1)]));
        parameter Boolean tableOnFile = false "= true, if table is defined on file or in function usertab";
        parameter Real table[:, :] = fill(0.0, 0, 2) "Table matrix (time = first column; e.g., table=[0, 0; 1, 1; 2, 4])";
        parameter String tableName = "NoName" "Table name on file or in function usertab (see docu)";
        parameter String fileName = "NoName" "File where matrix is stored";
        parameter String delimiter = "," "Column delimiter character for CSV file";
        parameter Integer nHeaderLines = 0 "Number of header lines to ignore for CSV file";
        parameter Boolean verboseRead = true "= true, if info message that file is loading is to be printed";
        parameter Integer columns[:] = 2:size(table, 2) "Columns of table to be interpolated";
        parameter Modelica.Blocks.Types.Smoothness smoothness = Modelica.Blocks.Types.Smoothness.LinearSegments "Smoothness of table interpolation";
        parameter Modelica.Blocks.Types.Extrapolation extrapolation = Modelica.Blocks.Types.Extrapolation.LastTwoPoints "Extrapolation of data outside the definition range";
        parameter SI.Time timeScale(min = Modelica.Constants.eps) = 1 "Time scale of first table column" annotation(Evaluate = true);
        parameter Real offset[:] = {0} "Offsets of output signals";
        parameter SI.Time startTime = 0 "Output = offset for time < startTime";
        parameter SI.Time shiftTime = startTime "Shift time of first table column";
        parameter Modelica.Blocks.Types.TimeEvents timeEvents = Modelica.Blocks.Types.TimeEvents.Always "Time event handling of table interpolation";
        parameter Boolean verboseExtrapolation = false "= true, if warning messages are to be printed if time is outside the table definition range";
        final parameter SI.Time t_min = t_minScaled*timeScale "Minimum abscissa value defined in table";
        final parameter SI.Time t_max = t_maxScaled*timeScale "Maximum abscissa value defined in table";
        final parameter Real t_minScaled = Internal.getTimeTableTmin(tableID) "Minimum (scaled) abscissa value defined in table";
        final parameter Real t_maxScaled = Internal.getTimeTableTmax(tableID) "Maximum (scaled) abscissa value defined in table";
      protected
        final parameter Real p_offset[nout] = (if size(offset, 1) == 1 then ones(nout)*offset[1] else offset) "Offsets of output signals";
        parameter Modelica.Blocks.Types.ExternalCombiTimeTable tableID = Modelica.Blocks.Types.ExternalCombiTimeTable(if tableOnFile then if isCsvExt then "Values" else tableName else "NoName", if tableOnFile and fileName <> "NoName" and not Modelica.Utilities.Strings.isEmpty(fileName) then fileName else "NoName", table, startTime/timeScale, columns, smoothness, extrapolation, shiftTime/timeScale, if smoothness == Modelica.Blocks.Types.Smoothness.LinearSegments then timeEvents elseif smoothness == Modelica.Blocks.Types.Smoothness.ConstantSegments then Modelica.Blocks.Types.TimeEvents.Always else Modelica.Blocks.Types.TimeEvents.NoTimeEvents, if tableOnFile then verboseRead else false, delimiter, nHeaderLines) "External table object";
        discrete SI.Time nextTimeEvent(start = 0, fixed = true) "Next time event instant";
        discrete Real nextTimeEventScaled(start = 0, fixed = true) "Next scaled time event instant";
        Real timeScaled "Scaled time";
        final parameter Boolean isCsvExt = if tableOnFile then Modelica.Utilities.Strings.findLast(fileName, ".csv", caseSensitive = false) + 3 == Modelica.Utilities.Strings.length(fileName) else false;
      equation
        if tableOnFile then
          assert(tableName <> "NoName" or isCsvExt, "tableOnFile = true and no table name given");
        else
          assert(size(table, 1) > 0 and size(table, 2) > 0, "tableOnFile = false and parameter table is an empty matrix");
        end if;
        if verboseExtrapolation and (extrapolation == Modelica.Blocks.Types.Extrapolation.LastTwoPoints or extrapolation == Modelica.Blocks.Types.Extrapolation.HoldLastPoint) then
          assert(noEvent(time >= t_min + shiftTime), "
      Extrapolation warning: Time must be greater or equal
      than the shifted minimum abscissa value defined in the table.
          ", AssertionLevel.warning);
          assert(noEvent(time <= t_max + shiftTime), "
      Extrapolation warning: Time must be less or equal
      than the shifted maximum abscissa value defined in the table.
          ", AssertionLevel.warning);
        end if;
        timeScaled = time/timeScale;
        when {time >= pre(nextTimeEvent), initial()} then
          nextTimeEventScaled = Internal.getNextTimeEvent(tableID, timeScaled);
          nextTimeEvent = if nextTimeEventScaled < Modelica.Constants.inf then nextTimeEventScaled*timeScale else Modelica.Constants.inf;
        end when;
        if smoothness == Modelica.Blocks.Types.Smoothness.ConstantSegments then
          for i in 1:nout loop
            y[i] = p_offset[i] + Internal.getTimeTableValueNoDer(tableID, i, timeScaled, nextTimeEventScaled, pre(nextTimeEventScaled));
          end for;
        elseif smoothness == Modelica.Blocks.Types.Smoothness.LinearSegments then
          for i in 1:nout loop
            y[i] = p_offset[i] + Internal.getTimeTableValueNoDer2(tableID, i, timeScaled, nextTimeEventScaled, pre(nextTimeEventScaled));
          end for;
        else
          for i in 1:nout loop
            y[i] = p_offset[i] + Internal.getTimeTableValue(tableID, i, timeScaled, nextTimeEventScaled, pre(nextTimeEventScaled));
          end for;
        end if;
      end CombiTimeTable;
    end Sources;

    package Tables "Library of blocks to interpolate in one and two-dimensional tables"
      extends Modelica.Icons.Package;

      package Internal "Internal external object definitions for table functions that should not be directly utilized by the user"
        extends Modelica.Icons.InternalPackage;

        pure function getTimeTableValue "Interpolate 1-dim. table where first column is time"
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTimeTable tableID "External table object";
          input Integer icol "Column number";
          input Real timeIn "(Scaled) time value";
          input Real nextTimeEvent "(Scaled) next time event in table";
          input Real pre_nextTimeEvent "Pre-value of (scaled) next time event in table";
          output Real y "Interpolated value";
          external "C" y = ModelicaStandardTables_CombiTimeTable_getValue(tableID, icol, timeIn, nextTimeEvent, pre_nextTimeEvent) annotation(IncludeDirectory = "modelica://Modelica/Resources/C-Sources", Library = {"ModelicaStandardTables", "ModelicaIO", "ModelicaMatIO", "zlib"});
          annotation(derivative(noDerivative = nextTimeEvent, noDerivative = pre_nextTimeEvent) = getDerTimeTableValue);
        end getTimeTableValue;

        pure function getTimeTableValueNoDer "Interpolate 1-dim. table where first column is time (but do not provide a derivative function)"
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTimeTable tableID "External table object";
          input Integer icol "Column number";
          input Real timeIn "(Scaled) time value";
          input Real nextTimeEvent "(Scaled) next time event in table";
          input Real pre_nextTimeEvent "Pre-value of (scaled) next time event in table";
          output Real y "Interpolated value";
          external "C" y = ModelicaStandardTables_CombiTimeTable_getValue(tableID, icol, timeIn, nextTimeEvent, pre_nextTimeEvent) annotation(IncludeDirectory = "modelica://Modelica/Resources/C-Sources", Library = {"ModelicaStandardTables", "ModelicaIO", "ModelicaMatIO", "zlib"});
        end getTimeTableValueNoDer;

        pure function getTimeTableValueNoDer2 "Interpolate 1-dim. table where first column is time (but do not provide a second derivative function)"
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTimeTable tableID "External table object";
          input Integer icol "Column number";
          input Real timeIn "(Scaled) time value";
          input Real nextTimeEvent "(Scaled) next time event in table";
          input Real pre_nextTimeEvent "Pre-value of (scaled) next time event in table";
          output Real y "Interpolated value";
          external "C" y = ModelicaStandardTables_CombiTimeTable_getValue(tableID, icol, timeIn, nextTimeEvent, pre_nextTimeEvent) annotation(IncludeDirectory = "modelica://Modelica/Resources/C-Sources", Library = {"ModelicaStandardTables", "ModelicaIO", "ModelicaMatIO", "zlib"});
          annotation(derivative(noDerivative = nextTimeEvent, noDerivative = pre_nextTimeEvent) = getDerTimeTableValueNoDer);
        end getTimeTableValueNoDer2;

        pure function getDerTimeTableValue "Derivative of interpolated 1-dim. table where first column is time"
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTimeTable tableID "External table object";
          input Integer icol "Column number";
          input Real timeIn "(Scaled) time value";
          input Real nextTimeEvent "(Scaled) next time event in table";
          input Real pre_nextTimeEvent "Pre-value of (scaled) next time event in table";
          input Real der_timeIn "Derivative of (scaled) time value";
          output Real der_y "Derivative of interpolated value";
          external "C" der_y = ModelicaStandardTables_CombiTimeTable_getDerValue(tableID, icol, timeIn, nextTimeEvent, pre_nextTimeEvent, der_timeIn) annotation(IncludeDirectory = "modelica://Modelica/Resources/C-Sources", Library = {"ModelicaStandardTables", "ModelicaIO", "ModelicaMatIO", "zlib"});
          annotation(derivative(order = 2, noDerivative = nextTimeEvent, noDerivative = pre_nextTimeEvent) = getDer2TimeTableValue);
        end getDerTimeTableValue;

        pure function getDerTimeTableValueNoDer "Derivative of interpolated 1-dim. table where first column is time (but do not provide a derivative function)"
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTimeTable tableID "External table object";
          input Integer icol "Column number";
          input Real timeIn "(Scaled) time value";
          input Real nextTimeEvent "(Scaled) next time event in table";
          input Real pre_nextTimeEvent "Pre-value of (scaled) next time event in table";
          input Real der_timeIn "Derivative of (scaled) time value";
          output Real der_y "Derivative of interpolated value";
          external "C" der_y = ModelicaStandardTables_CombiTimeTable_getDerValue(tableID, icol, timeIn, nextTimeEvent, pre_nextTimeEvent, der_timeIn) annotation(IncludeDirectory = "modelica://Modelica/Resources/C-Sources", Library = {"ModelicaStandardTables", "ModelicaIO", "ModelicaMatIO", "zlib"});
        end getDerTimeTableValueNoDer;

        pure function getDer2TimeTableValue "Second derivative of interpolated 1-dim. table where first column is time"
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTimeTable tableID "External table object";
          input Integer icol "Column number";
          input Real timeIn "(Scaled) time value";
          input Real nextTimeEvent "(Scaled) next time event in table";
          input Real pre_nextTimeEvent "Pre-value of (scaled) next time event in table";
          input Real der_timeIn "Derivative of (scaled) time value";
          input Real der2_timeIn "Second derivative of (scaled) time value";
          output Real der2_y "Second derivative of interpolated value";
          external "C" der2_y = ModelicaStandardTables_CombiTimeTable_getDer2Value(tableID, icol, timeIn, nextTimeEvent, pre_nextTimeEvent, der_timeIn, der2_timeIn) annotation(IncludeDirectory = "modelica://Modelica/Resources/C-Sources", Library = {"ModelicaStandardTables", "ModelicaIO", "ModelicaMatIO", "zlib"});
        end getDer2TimeTableValue;

        pure function getTimeTableTmin "Return minimum abscissa value of 1-dim. table where first column is time"
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTimeTable tableID "External table object";
          output Real timeMin "Minimum abscissa value in table";
          external "C" timeMin = ModelicaStandardTables_CombiTimeTable_minimumTime(tableID) annotation(IncludeDirectory = "modelica://Modelica/Resources/C-Sources", Library = {"ModelicaStandardTables", "ModelicaIO", "ModelicaMatIO", "zlib"});
        end getTimeTableTmin;

        pure function getTimeTableTmax "Return maximum abscissa value of 1-dim. table where first column is time"
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTimeTable tableID "External table object";
          output Real timeMax "Maximum abscissa value in table";
          external "C" timeMax = ModelicaStandardTables_CombiTimeTable_maximumTime(tableID) annotation(IncludeDirectory = "modelica://Modelica/Resources/C-Sources", Library = {"ModelicaStandardTables", "ModelicaIO", "ModelicaMatIO", "zlib"});
        end getTimeTableTmax;

        pure function getNextTimeEvent "Return next time event value of 1-dim. table where first column is time"
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTimeTable tableID "External table object";
          input Real timeIn "(Scaled) time value";
          output Real nextTimeEvent "(Scaled) next time event in table";
          external "C" nextTimeEvent = ModelicaStandardTables_CombiTimeTable_nextTimeEvent(tableID, timeIn) annotation(IncludeDirectory = "modelica://Modelica/Resources/C-Sources", Library = {"ModelicaStandardTables", "ModelicaIO", "ModelicaMatIO", "zlib"});
        end getNextTimeEvent;
      end Internal;
    end Tables;

    package Types "Library of constants, external objects and types with choices, especially to build menus"
      extends Modelica.Icons.TypesPackage;
      type Smoothness = enumeration(LinearSegments "Linear interpolation of table points", ContinuousDerivative "Akima spline interpolation of table points (such that the first derivative is continuous)", ConstantSegments "Piecewise constant interpolation of table points (the value from the previous abscissa point is returned)", MonotoneContinuousDerivative1 "Fritsch-Butland spline interpolation (such that the monotonicity is preserved and the first derivative is continuous)", MonotoneContinuousDerivative2 "Steffen spline interpolation of table points (such that the monotonicity is preserved and the first derivative is continuous)", ModifiedContinuousDerivative "Modified Akima spline interpolation of table points (such that the first derivative is continuous and shortcomings of the original Akima method are avoided)") "Enumeration defining the smoothness of table interpolation";
      type Extrapolation = enumeration(HoldLastPoint "Hold the first/last table point outside of the table scope", LastTwoPoints "Extrapolate by using the derivative at the first/last table points outside of the table scope", Periodic "Repeat the table scope periodically", NoExtrapolation "Extrapolation triggers an error") "Enumeration defining the extrapolation of table interpolation";
      type TimeEvents = enumeration(Always "Always generate time events at interval boundaries", AtDiscontinuities "Generate time events at discontinuities (defined by duplicated sample points)", NoTimeEvents "No time events at interval boundaries") "Enumeration defining the time event handling of time table interpolation";

      class ExternalCombiTimeTable "External object of 1-dim. table where first column is time"
        extends ExternalObject;

        function constructor "Initialize 1-dim. table where first column is time"
          extends Modelica.Icons.Function;
          input String tableName "Table name";
          input String fileName "File name";
          input Real table[:, :];
          input Real startTime;
          input Integer columns[:];
          input Modelica.Blocks.Types.Smoothness smoothness;
          input Modelica.Blocks.Types.Extrapolation extrapolation;
          input Real shiftTime = 0.0;
          input Modelica.Blocks.Types.TimeEvents timeEvents = Modelica.Blocks.Types.TimeEvents.Always;
          input Boolean verboseRead = true "= true: Print info message; = false: No info message";
          input String delimiter = "," "Column delimiter character for CSV file";
          input Integer nHeaderLines = 0 "Number of header lines to ignore for CSV file";
          output ExternalCombiTimeTable externalCombiTimeTable;
          external "C" externalCombiTimeTable = ModelicaStandardTables_CombiTimeTable_init3(fileName, tableName, table, size(table, 1), size(table, 2), startTime, columns, size(columns, 1), smoothness, extrapolation, shiftTime, timeEvents, verboseRead, delimiter, nHeaderLines) annotation(IncludeDirectory = "modelica://Modelica/Resources/C-Sources", Library = {"ModelicaStandardTables", "ModelicaIO", "ModelicaMatIO", "zlib"});
        end constructor;

        function destructor "Terminate 1-dim. table where first column is time"
          extends Modelica.Icons.Function;
          input ExternalCombiTimeTable externalCombiTimeTable;
          external "C" ModelicaStandardTables_CombiTimeTable_close(externalCombiTimeTable) annotation(IncludeDirectory = "modelica://Modelica/Resources/C-Sources", Library = {"ModelicaStandardTables", "ModelicaIO", "ModelicaMatIO", "zlib"});
        end destructor;
      end ExternalCombiTimeTable;
    end Types;

    package Icons "Icons for Blocks"
      extends Modelica.Icons.IconsPackage;

      partial block Block "Basic graphical layout of input/output block" end Block;

      partial block DiscreteBlock "Graphical layout of discrete block component icon" end DiscreteBlock;
    end Icons;
  end Blocks;

  package Math "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices"
    extends Modelica.Icons.Package;

    package Icons "Icons for Math"
      extends Modelica.Icons.IconsPackage;

      partial function AxisCenter "Basic icon for mathematical function with y-axis in the center" end AxisCenter;
    end Icons;

    function asin "Inverse sine (-1 <= u <= 1)"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u "Independent variable";
      output Modelica.Units.SI.Angle y "Dependent variable y=asin(u)";
    algorithm
      y := .asin(u);
      annotation(Inline = true);
    end asin;

    function exp "Exponential, base e"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u "Independent variable";
      output Real y "Dependent variable y=exp(u)";
    algorithm
      y := .exp(u);
      annotation(Inline = true);
    end exp;
  end Math;

  package Utilities "Library of utility functions dedicated to scripting (operating on files, streams, strings, system)"
    extends Modelica.Icons.UtilitiesPackage;

    package Strings "Operations on strings"
      extends Modelica.Icons.FunctionsPackage;

      pure function length "Return length of string"
        extends Modelica.Icons.Function;
        input String string;
        output Integer result "Number of characters of string";
        external "C" result = ModelicaStrings_length(string) annotation(IncludeDirectory = "modelica://Modelica/Resources/C-Sources", Include = "#include \"ModelicaStrings.h\"", Library = "ModelicaExternalC");
      end length;

      pure function substring "Return a substring defined by start and end index"
        extends Modelica.Icons.Function;
        input String string "String from which a substring is inquired";
        input Integer startIndex(min = 1) "Character position of substring begin (index=1 is first character in string)";
        input Integer endIndex "Character position of substring end";
        output String result "String containing substring string[startIndex:endIndex]";
        external "C" result = ModelicaStrings_substring(string, startIndex, endIndex) annotation(IncludeDirectory = "modelica://Modelica/Resources/C-Sources", Include = "#include \"ModelicaStrings.h\"", Library = "ModelicaExternalC");
      end substring;

      pure function compare "Compare two strings lexicographically"
        extends Modelica.Icons.Function;
        input String string1;
        input String string2;
        input Boolean caseSensitive = true "= false, if case of letters is ignored";
        output Modelica.Utilities.Types.Compare result "Result of comparison";
        external "C" result = ModelicaStrings_compare(string1, string2, caseSensitive) annotation(IncludeDirectory = "modelica://Modelica/Resources/C-Sources", Include = "#include \"ModelicaStrings.h\"", Library = "ModelicaExternalC");
      end compare;

      function isEqual "Determine whether two strings are identical"
        extends Modelica.Icons.Function;
        input String string1;
        input String string2;
        input Boolean caseSensitive = true "= false, if lower and upper case are ignored for the comparison";
        output Boolean identical "True, if string1 is identical to string2";
      algorithm
        identical := compare(string1, string2, caseSensitive) == Types.Compare.Equal;
      end isEqual;

      function isEmpty "Return true if a string is empty (has only white space characters)"
        extends Modelica.Icons.Function;
        input String string;
        output Boolean result "True, if string is empty";
      protected
        Integer nextIndex;
        Integer len;
      algorithm
        nextIndex := Strings.Advanced.skipWhiteSpace(string);
        len := Strings.length(string);
        if len < 1 or nextIndex > len then
          result := true;
        else
          result := false;
        end if;
      end isEmpty;

      function findLast "Find last occurrence of a string within another string"
        extends Modelica.Icons.Function;
        input String string "String that is analyzed";
        input String searchString "String that is searched for in string";
        input Integer startIndex(min = 0) = 0 "Start search at index startIndex. If startIndex = 0, start at length(string)";
        input Boolean caseSensitive = true "= false, if lower and upper case are ignored for the search";
        output Integer index "Index of the beginning of the last occurrence of 'searchString' within 'string', or zero if not present";
      protected
        Integer lenString = length(string);
        Integer lenSearchString = length(searchString);
        Integer iMax = lenString - lenSearchString + 1;
        Integer i;
      algorithm
        i := if startIndex == 0 or startIndex > iMax then iMax else startIndex;
        index := 0;
        while i >= 1 loop
          if isEqual(substring(string, i, i + lenSearchString - 1), searchString, caseSensitive) then
            index := i;
            i := 0;
          else
            i := i - 1;
          end if;
        end while;
      end findLast;

      package Advanced "Advanced scanning functions"
        extends Modelica.Icons.FunctionsPackage;

        pure function skipWhiteSpace "Scan white space"
          extends Modelica.Icons.Function;
          input String string;
          input Integer startIndex(min = 1) = 1;
          output Integer nextIndex;
          external "C" nextIndex = ModelicaStrings_skipWhiteSpace(string, startIndex) annotation(IncludeDirectory = "modelica://Modelica/Resources/C-Sources", Include = "#include \"ModelicaStrings.h\"", Library = "ModelicaExternalC");
        end skipWhiteSpace;
      end Advanced;
    end Strings;

    package Types "Type definitions used in package Modelica.Utilities"
      extends Modelica.Icons.TypesPackage;
      type Compare = enumeration(Less "String 1 is lexicographically less than string 2", Equal "String 1 is identical to string 2", Greater "String 1 is lexicographically greater than string 2") "Enumeration defining comparison of two strings";
    end Types;
  end Utilities;

  package Constants "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)"
    extends Modelica.Icons.Package;
    import Modelica.Units.SI;
    import Modelica.Units.NonSI;
    final constant Real pi = 2*Modelica.Math.asin(1.0);
    final constant Real eps = ModelicaServices.Machine.eps "The difference between 1 and the least value greater than 1 that is representable in the given floating point type";
    final constant Real inf = ModelicaServices.Machine.inf "Maximum representable finite floating-point number";
    final constant SI.Velocity c = 299792458 "Speed of light in vacuum";
    final constant SI.ElectricCharge q = 1.602176634e-19 "Elementary charge";
    final constant Real h(final unit = "J.s") = 6.62607015e-34 "Planck constant";
    final constant Real k(final unit = "J/K") = 1.380649e-23 "Boltzmann constant";
    final constant Real N_A(final unit = "1/mol") = 6.02214076e23 "Avogadro constant";
    final constant SI.Permeability mu_0 = 1.25663706212e-6 "Magnetic constant";
  end Constants;

  package Icons "Library of icons"
    extends Icons.Package;

    partial package Package "Icon for standard packages" end Package;

    partial package BasesPackage "Icon for packages containing base classes"
      extends Modelica.Icons.Package;
    end BasesPackage;

    partial package InterfacesPackage "Icon for packages containing interfaces"
      extends Modelica.Icons.Package;
    end InterfacesPackage;

    partial package SourcesPackage "Icon for packages containing sources"
      extends Modelica.Icons.Package;
    end SourcesPackage;

    partial package UtilitiesPackage "Icon for utility packages"
      extends Modelica.Icons.Package;
    end UtilitiesPackage;

    partial package TypesPackage "Icon for packages containing type definitions"
      extends Modelica.Icons.Package;
    end TypesPackage;

    partial package FunctionsPackage "Icon for packages containing functions"
      extends Modelica.Icons.Package;
    end FunctionsPackage;

    partial package IconsPackage "Icon for packages containing icons"
      extends Modelica.Icons.Package;
    end IconsPackage;

    partial package InternalPackage "Icon for an internal package (indicating that the package should not be directly utilized by user)" end InternalPackage;

    partial function Function "Icon for functions" end Function;
  end Icons;

  package Units "Library of type and unit definitions"
    extends Modelica.Icons.Package;

    package SI "Library of SI unit definitions"
      extends Modelica.Icons.Package;
      type Angle = Real(final quantity = "Angle", final unit = "rad", displayUnit = "deg");
      type Time = Real(final quantity = "Time", final unit = "s");
      type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
      type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
      type ElectricCharge = Real(final quantity = "ElectricCharge", final unit = "C");
      type Permeability = Real(final quantity = "Permeability", final unit = "V.s/(A.m)");
      type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
    end SI;

    package NonSI "Type definitions of non SI and other units"
      extends Modelica.Icons.Package;
      type Temperature_degC = Real(final quantity = "ThermodynamicTemperature", final unit = "degC") "Absolute temperature in degree Celsius (for relative temperature use Modelica.Units.SI.TemperatureDifference)" annotation(absoluteValue = true);
    end NonSI;
  end Units;
  annotation(version = "4.1.0", versionDate = "2025-05-23", dateModified = "2025-05-23 15:00:00Z");
end Modelica;

model Issue15300
  Modelica.Blocks.Sources.CombiTimeTable combiTimeTable(tableOnFile = true, tableName = "immobilization_input", fileName = "input/immobilization_input.txt", columns = 2:6);
  Modelica.Blocks.Routing.DeMultiplex demux(n = 5);
  Buildings.Utilities.IO.Files.CSVWriter csvWriter(nin = 5, fileName = "output/immobilization_output.csv", samplePeriod = 1, delimiter = ";", writeHeader = true, headerNames = {"ava_out", "avn_out", "v30", "v31", "v37"}, significantDigits = 16);
  zyb_immobilization_rates zyb_immobilization_rates1;
equation
  connect(combiTimeTable.y, demux.u);
  connect(demux.y[1], zyb_immobilization_rates1.ava_in);
  connect(demux.y[2], zyb_immobilization_rates1.avn_in);
  connect(demux.y[3], zyb_immobilization_rates1.requin);
  connect(demux.y[4], zyb_immobilization_rates1.v22);
  connect(demux.y[5], zyb_immobilization_rates1.v24);
  connect(zyb_immobilization_rates1.ava_out, csvWriter.u[1]);
  connect(zyb_immobilization_rates1.avn_out, csvWriter.u[2]);
  connect(zyb_immobilization_rates1.v30, csvWriter.u[3]);
  connect(zyb_immobilization_rates1.v31, csvWriter.u[4]);
  connect(zyb_immobilization_rates1.v37, csvWriter.u[5]);
end Issue15300;