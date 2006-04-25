package Settings "
This file is part of OpenModelica.

Copyright (c) 1998-2005, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

 Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

 Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

 Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

  
  file:	 Settings.rml
  module:      Settings
  description: This file contains settings for omc which are implemented in 
  C.
 
  RCS: $Id: Settings.rml 2066 2006-02-02 09:04:10Z kajny $
 
 
  
"

public function setCompileCommand
  input String inString;

  external "C" ;
end setCompileCommand;

public function getCompileCommand
  output String outString;

  external "C" ;
end getCompileCommand;

public function setTempDirectoryPath
  input String inString;

  external "C" ;
end setTempDirectoryPath;

public function getTempDirectoryPath
  output String outString;

  external "C" ;
end getTempDirectoryPath;

public function setInstallationDirectoryPath
  input String inString;

  external "C" ;
end setInstallationDirectoryPath;

public function getInstallationDirectoryPath
  output String outString;

  external "C" ;
end getInstallationDirectoryPath;

public function setPlotCommand
  input String inString;

  external "C" ;
end setPlotCommand;

public function getPlotCommand
  output String outString;

  external "C" ;
end getPlotCommand;

public function setModelicaPath
  input String inString;

  external "C" ;
end setModelicaPath;

public function getModelicaPath
  output String outString;

  external "C" ;
end getModelicaPath;

public function getEcho
  output Integer echo;

  external "C" ;
end getEcho;

public function setEcho
  input Integer echo;

  external "C" ;
end setEcho;

public function dumpSettings

  external "C" ;
end dumpSettings;
end Settings;

