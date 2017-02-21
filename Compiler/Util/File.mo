/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package File

class File
  extends ExternalObject;
  function constructor<T> "File constructor."
    input Option<Integer> fromID = noReference() "Never pass this an actual Option<Integer>. Only use File.getReference(file) or File.noReference(). Determines if we should restore from another File object or create a new File.";
    output File file;
  external "C" file=om_file_new(fromID) annotation(IncludeDirectory="modelica://File/", Include="#include \"omc_file.h\"");
  end constructor;

  function destructor
    input File file;
  external "C" om_file_free(file) annotation(IncludeDirectory="modelica://File/", Include="#include \"omc_file.h\"");
  end destructor;
end File;

type Mode = enumeration(Read,Write);

function open
  input File file;
  input String filename;
  input Mode mode = Mode.Read;
external "C" om_file_open(file,filename,mode) annotation(IncludeDirectory="modelica://File/", Include="#include \"omc_file.h\"");
end open;

function write
  input File file;
  input String data;
external "C" om_file_write(file,data) annotation(IncludeDirectory="modelica://File/", Include="#include \"omc_file.h\"");
end write;

function writeInt
  input File file;
  input Integer data;
  input String format="%d";
external "C" om_file_write_int(file,data,format) annotation(IncludeDirectory="modelica://File/", Include="#include \"omc_file.h\"");
end writeInt;

function writeReal
  input File file;
  input Real data;
  input String format="%.15g";
external "C" om_file_write_real(file,data,format) annotation(IncludeDirectory="modelica://File/", Include="#include \"omc_file.h\"");
end writeReal;

type Escape = enumeration(None "No escape string",
                          C "Escapes C strings (minimally): \\n and \"",
                          JSON "Escapes JSON strings (quotes and control characters)",
                          XML "Escapes strings to XML text");

function writeEscape
  input File file;
  input String data;
  input Escape escape;
external "C" om_file_write_escape(file,data,escape) annotation(IncludeDirectory="modelica://File/", Include="#include \"omc_file.h\"");
end writeEscape;

type Whence = enumeration(Set "SEEK_SET 0=start of file",Current "SEEK_CUR 0=current byte",End "SEEK_END 0=end of file");

function seek
  input File file;
  input Integer offset;
  input Whence whence = Whence.Set;
  output Boolean success;
external "C" success = om_file_seek(file,offset,whence) annotation(IncludeDirectory="modelica://File/", Include="#include \"omc_file.h\"");
end seek;

function tell
  input File file;
  output Integer pos;
external "C" pos = om_file_tell(file) annotation(IncludeDirectory="modelica://File/", Include="#include \"omc_file.h\"");
end tell;

function getFilename
  input Option<Integer> file;
  output String fileName;
external "C" fileName = om_file_get_filename(file) annotation(IncludeDirectory="modelica://File/", Include="#include \"omc_file.h\"");
end getFilename;

function noReference "Returns NULL (an opaque pointer; not actually Option<Integer>)"
  output Option<Integer> reference;
external "C" reference = om_file_no_reference() annotation(IncludeDirectory="modelica://File/", Include="#include \"omc_file.h\"");
end noReference;

function getReference "Returns an opaque pointer (not actually Option<Integer>)"
  input File file;
  output Option<Integer> reference;
external "C" reference = om_file_get_reference(file) annotation(IncludeDirectory="modelica://File/", Include="#include \"omc_file.h\"");
end getReference;

function releaseReference
  input File file;
external "C" om_file_release_reference(file) annotation(IncludeDirectory="modelica://File/", Include="#include \"omc_file.h\"");
end releaseReference;

function writeSpace
  input File file;
  input Integer n;
algorithm
  for i in 1:n loop
    File.write(file, " ");
  end for;
end writeSpace;

package Examples

  model WriteToFile
    File file = File();
  initial algorithm
    open(file,"abc.txt",Mode.Write);
    write(file,"def.fafaf\n");
    writeEscape(file,"xx<def.\"\nfaf>af\n",escape=Escape.JSON);
  annotation(experiment(StopTime=0));
  end WriteToFile;

end Examples;

annotation(__OpenModelica_Interface="util");
end File;
