/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
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
    end OUTPUT_FORMAT;
  end OutputFormat;

  constant OutputFormat defaultFormat = OutputFormat.OUTPUT_FORMAT(ScalarizeMode.PARTIALLY_SCALARIZED, RecordMode.WITH_RECORDS);

  function formatFromFlags
    output OutputFormat format = defaultFormat;
  algorithm
    if not Flags.isSet(Flags.NF_SCALARIZE) then
      format.scalarizeMode := ScalarizeMode.NOT_SCALARIZED;
    end if;

    format.recordMode := RecordMode.WITH_RECORDS;

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
  end formatFromFlags;

annotation(__OpenModelica_Interface="frontend");
end BaseModelica;
