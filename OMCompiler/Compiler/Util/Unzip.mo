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

encapsulated package Unzip

function unzipPath
  input String fileName;
  input String pathToExtract;
  input String destinationPath;
  output Boolean success;
  external "C" success = om_unzip(fileName, pathToExtract, destinationPath);
end unzipPath;

function unzipAll
  "Extracts every entry of fileName below destinationPath under its stored name."
  input String fileName;
  input String destinationPath;
  output Boolean success;
  external "C" success = om_unzip_all(fileName, destinationPath);
end unzipAll;

function zipPath
  "Creates zipFileName with path stored under entryName: a file as that entry,
   a directory recursively below it. An empty entryName puts the contents of a
   directory at the root of the archive."
  input String zipFileName;
  input String path;
  input String entryName;
  output Boolean success;
  external "C" success = om_zip(zipFileName, path, entryName);
end zipPath;

function zipPaths
  "Creates zipFileName with each of names below directory (a file, or a
   directory recursively) stored under its name."
  input String zipFileName;
  input String directory;
  input list<String> names;
  output Boolean success;
  external "C" success = om_zip_paths(zipFileName, directory, names);
end zipPaths;

annotation(__OpenModelica_Interface="script_util");
end Unzip;
