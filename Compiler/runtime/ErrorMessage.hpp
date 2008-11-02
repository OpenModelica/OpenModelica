/*
Copyright (c) 1998-2006, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

* Neither the name of Linköpings universitet nor the names of its
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
*/

#ifndef ERRORMESSAGE_HPP
#define ERRORMESSAGE_HPP

#include <list>
#include <string>

class ErrorMessage {

public:
  ErrorMessage(long errorID,
	       std::string type,
	       std::string severity,
	       std::string message,
	       std::list<std::string> &tokens);

  ErrorMessage(long errorID,
	       std::string type,
	       std::string severity,
	       std::string message,
	       std::list<std::string> &tokens,
	       long startLineNo,
	       long startColumnNo,
	       long endLineNo,
	       long endColumnNo,
	       bool isReadOnly,
	       std::string filename);

  long getID() { return errorID_; };

  std::string getType() { return messageType_; };

  std::string getSeverity() { return severity_; };

  // Returns the expanded message with inserted tokens.
  std::string getMessage();

  // Returns the complete message in string format corresponding to a Modeica vector.
  std::string getFullMessage();

  long getLineNo() { return startLineNo_; };
  long getColumnNo() { return startColumnNo_; };
  /* adrpo added these new ones */
  long getStartLineNo() { return startLineNo_; };
  long getStartColumnNo() { return startColumnNo_; };
  long getEndLineNo() { return endLineNo_; };
  long getEndColumnNo() { return endColumnNo_; };
  bool getIsFileReadOnly() { return isReadOnly_; };
  std::string getFileName() { return filename_; };
private:
  long errorID_;
  std::string messageType_;
  std::string severity_;
  std::string message_;
  std::list<std::string> tokens_;

  /* adrpo 2006-02-05 changed the ones below */
  long startLineNo_;
  long startColumnNo_;
  long endLineNo_;
  long endColumnNo_;
  bool isReadOnly_;
  std::string filename_;

};


#endif
