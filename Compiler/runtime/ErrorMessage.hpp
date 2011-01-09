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

  long getID() const { return errorID_; };
  
  std::string getType() const { return messageType_; };
  
  std::string getSeverity() const { return severity_; };

  // Returns the expanded message with inserted tokens.
  std::string getMessage() const {return shortMessage;};

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
  std::list<std::string> getTokens() const { return tokens_; };
private:
  long errorID_;
  std::string messageType_;
  std::string severity_;
  std::string message_;
  std::list<std::string> tokens_;
  std::string shortMessage;
  std::string fullMessage;
  
  /* adrpo 2006-02-05 changed the ones below */
  long startLineNo_;
  long startColumnNo_;
  long endLineNo_;
  long endColumnNo_;
  bool isReadOnly_;
  std::string filename_;

  std::string getMessage_();
  std::string getFullMessage_();

};


#endif
