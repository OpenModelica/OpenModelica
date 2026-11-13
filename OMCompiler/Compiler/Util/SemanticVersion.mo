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

encapsulated package SemanticVersion
  "Version numbers of Modelica libraries, implemented in
   OpenModelica.rs/openmodelica_version: numbers with prerelease and build
   metadata (4.0.0-beta.1+maint.om), and names such as master, which are older
   than any number."

function compare
  "-1, 0 or 1 if v1 is older than, the same as or newer than v2. A release is
   newer than its prereleases."
  input String v1, v2;
  input Boolean comparePrerelease = true;
  input Boolean compareBuildInformation = false;
  output Integer c;
  external "C" c = om_semver_compare(v1, v2, comparePrerelease, compareBuildInformation) annotation(Library = "omcruntime");
end compare;

function normalize
  "The version with up to three numbers padded to three: 3.2 as 3.2.0."
  input String v;
  output String out;
  external "C" out = om_semver_normalize(v) annotation(Library = "omcruntime");
end normalize;

function isSemVer
  "Whether v is a version number, not a name such as master."
  input String v;
  output Boolean b;
  external "C" b = om_semver_is_semver(v) annotation(Library = "omcruntime");
end isSemVer;

annotation(__OpenModelica_Interface="util");
end SemanticVersion;
