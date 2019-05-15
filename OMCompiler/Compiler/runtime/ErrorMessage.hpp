/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifndef ERRORMESSAGE_HPP
#define ERRORMESSAGE_HPP

#include <vector>
#include <string>
#include "errorext.h"

class ErrorMessage {

public:
  typedef std::vector<std::string> TokenList;

  ErrorMessage(long errorID,
         ErrorType type,
         ErrorLevel severity,
         const std::string &message,
         const TokenList &tokens);

  ErrorMessage(long errorID,
         ErrorType type,
         ErrorLevel severity,
         const std::string &message,
         const TokenList &tokens,
         long startLineNo,
         long startColumnNo,
         long endLineNo,
         long endColumnNo,
         bool isReadOnly,
         const std::string &filename);

  long getID() const { return errorID_; };

  ErrorType getType() const { return messageType_; };

  ErrorLevel getSeverity() const { return severity_; };

  // Returns the expanded message with inserted tokens.
  std::string getShortMessage() const {return veryshort_msg;};

  // Returns the expanded message with inserted tokens.
  std::string getMessage(int warningsAsErrors) {if (!warningsAsErrors) {return shortMessage;} else {return getMessage_(warningsAsErrors);}};

  // Returns the complete message in string format corresponding to a Modeica vector.
  std::string getFullMessage() const {return fullMessage;};

  long getLineNo() const { return startLineNo_; };
  long getColumnNo() const { return startColumnNo_; };
  /* adrpo added these new ones */
  long getStartLineNo() const { return startLineNo_; };
  long getStartColumnNo() const { return startColumnNo_; };
  long getEndLineNo() const { return endLineNo_; };
  long getEndColumnNo() const { return endColumnNo_; };
  bool getIsFileReadOnly() const { return isReadOnly_; };
  std::string getFileName() const { return filename_; };
  TokenList getTokens() const { return tokens_; };
private:
  long errorID_;
  ErrorType messageType_;
  ErrorLevel severity_;
  std::string message_;
  TokenList tokens_;
  std::string shortMessage;
  std::string veryshort_msg;
  std::string fullMessage;

  /* adrpo 2006-02-05 changed the ones below */
  long startLineNo_;
  long startColumnNo_;
  long endLineNo_;
  long endColumnNo_;
  bool isReadOnly_;
  std::string filename_;

  std::string getShortMessage_();
  std::string getMessage_(int warningsAsErrors);
  std::string getFullMessage_();

};


#endif
