/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package BaseModelica
protected
  import Flags;

public
  type ScalarizeMode = enumeration(
    SCALARIZED,
    PARTIALLY_SCALARIZED,
    NOT_SCALARIZED
  );

  type RecordMode = enumeration(
    WITH_RECORDS,
    WITHOUT_RECORDS
  );

  uniontype OutputFormat
    record OUTPUT_FORMAT
      ScalarizeMode scalarizeMode;
      RecordMode recordMode;
      Boolean moveBindings;
    end OUTPUT_FORMAT;
  end OutputFormat;

  constant OutputFormat defaultFormat = OutputFormat.OUTPUT_FORMAT(
      ScalarizeMode.PARTIALLY_SCALARIZED,
      RecordMode.WITH_RECORDS,
      false
  );

  function formatFromFlags
    output OutputFormat format = defaultFormat;
  algorithm
    if not Flags.isSet(Flags.NF_SCALARIZE) then
      format.scalarizeMode := ScalarizeMode.NOT_SCALARIZED;
    elseif Flags.isConfigFlagSet(Flags.BASE_MODELICA_OPTIONS, "scalarize") then
      format.scalarizeMode := ScalarizeMode.SCALARIZED;
      format.recordMode := RecordMode.WITHOUT_RECORDS;
    end if;

    for option in Flags.getConfigStringList(Flags.BASE_MODELICA_FORMAT) loop
      () := match option
        case "scalarized"          algorithm format.scalarizeMode := ScalarizeMode.SCALARIZED; then ();
        case "partiallyScalarized" algorithm format.scalarizeMode := ScalarizeMode.PARTIALLY_SCALARIZED; then ();
        case "nonScalarized"       algorithm format.scalarizeMode := ScalarizeMode.NOT_SCALARIZED; then ();
        case "withRecords"         algorithm format.recordMode := RecordMode.WITH_RECORDS; then ();
        case "withoutRecords"      algorithm format.recordMode := RecordMode.WITHOUT_RECORDS; then ();
        else ();
      end match;
    end for;

    format.moveBindings := Flags.isConfigFlagSet(Flags.BASE_MODELICA_OPTIONS, "moveBindings");
  end formatFromFlags;

  function inlineFunctions
    output Boolean enabled = Flags.isConfigFlagSet(Flags.BASE_MODELICA_OPTIONS, "inlineFunctions");
  end inlineFunctions;

annotation(__OpenModelica_Interface="frontend");
end BaseModelica;
