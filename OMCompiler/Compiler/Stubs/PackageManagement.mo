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

encapsulated package PackageManagement

encapsulated package AvailableLibraries
  function listKeys
    input output list<String> lst;
  end listKeys;
end AvailableLibraries;

function versionsThatProvideTheWanted
  input String id;
  input String version;
  input Boolean printError;
  output list<String> result;
algorithm
  result := {};
end versionsThatProvideTheWanted;

function getInstalledLibraries
  output list<String> lst;
end getInstalledLibraries;

function installPackage
  input String str1, str2;
  input Boolean b;
  output Boolean res;
algorithm
  res := false;
end installPackage;

function updateIndex
  output Boolean res;
algorithm
  res := false;
end updateIndex;

function upgradeInstalledPackages
  input Boolean b;
  output Boolean res;
algorithm
  res := false;
end upgradeInstalledPackages;

function installCachedPackages
end installCachedPackages;

annotation(__OpenModelica_Interface="frontend");
end PackageManagement;
