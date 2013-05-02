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

encapsulated package RTOptsData
" file:   RTOptsData.mo
  package:     RTOpts
  description: Data structures for RTOpts

  RCS: $Id$

  This package contains data structures used by RTOpts, which can't be defined
  in RTOpts since RML doesn't generate header files for packages which only
  contain external functions.
"

protected import RTOpts;

public uniontype LanguageStandard
  "Defines the various modelica language versions that OMC can use. DO NOT add
  anything in these records, because the external functions that use these might
  break if the records are not empty due to some RML weirdness."
  record MODELICA_1_X end MODELICA_1_X;
  record MODELICA_2_X end MODELICA_2_X;
  record MODELICA_3_0 end MODELICA_3_0;
  record MODELICA_3_1 end MODELICA_3_1;
  record MODELICA_3_2 end MODELICA_3_2;
  record MODELICA_3_3 end MODELICA_3_3;
  record MODELICA_LATEST end MODELICA_LATEST;
end LanguageStandard;

public function languageStandardAtLeast
  input LanguageStandard inStandard;
  output Boolean outRes;
protected
  LanguageStandard std;
algorithm
  std := RTOpts.getLanguageStandard();
  outRes := intGe(languageStandardInt(std), languageStandardInt(inStandard));
end languageStandardAtLeast;

public function languageStandardAtMost
  input LanguageStandard inStandard;
  output Boolean outRes;
protected
  LanguageStandard std;
algorithm
  std := RTOpts.getLanguageStandard();
  outRes := intLe(languageStandardInt(std), languageStandardInt(inStandard));
end languageStandardAtMost;

protected function languageStandardInt
  input LanguageStandard inStandard;
  output Integer outValue;
algorithm
  outValue := match(inStandard)
    case MODELICA_1_X() then 10;
    case MODELICA_2_X() then 20;
    case MODELICA_3_0() then 30;
    case MODELICA_3_1() then 31;
    case MODELICA_3_2() then 32;
    case MODELICA_3_3() then 33;
    case MODELICA_LATEST() then 1000;
  end match;
end languageStandardInt;

public function languageStandardString
  input LanguageStandard inStandard;
  output String outString;
algorithm
  outString := match(inStandard)
    case MODELICA_1_X() then "1.x";
    case MODELICA_2_X() then "2.x";
    case MODELICA_3_0() then "3.0";
    case MODELICA_3_1() then "3.1";
    case MODELICA_3_2() then "3.2";
    case MODELICA_3_3() then "3.3";
    // Change this to latest version if you add more version!
    case MODELICA_LATEST() then "3.3";
  end match;
end languageStandardString;

end RTOptsData;
