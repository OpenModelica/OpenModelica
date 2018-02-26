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

#include <list>
#include <string>
#include <sstream>
#include <iostream>

#include "ErrorMessage.hpp"

  /* Implementation of ErrorMessage class. */


  ErrorMessage::ErrorMessage(long errorID,
           ErrorType type,
           ErrorLevel severity,
           const std::string &message,
           const TokenList &tokens)
    : errorID_(errorID),
      messageType_(type),
      severity_(severity),
      message_(message),
      tokens_(tokens)

{
  startLineNo_ = 0;
  startColumnNo_ = 0;
  endLineNo_ = 0;
  endColumnNo_ = 0;
  isReadOnly_ = false;
  filename_ = std::string("");
  shortMessage = getMessage_(0);
  fullMessage = getFullMessage_();
}

ErrorMessage::ErrorMessage(long errorID,
         ErrorType type,
         ErrorLevel severity,
         const std::string &message,
         const TokenList &tokens,
         long startLineNo,
         long startColumnNo,
         long endLineNo,
         long endColumnNo,
         bool isReadOnly,
         const std::string &filename)
    :
    errorID_(errorID),
    messageType_(type),
    severity_(severity),
    startLineNo_(startLineNo),
    startColumnNo_(startColumnNo),
    endLineNo_(endLineNo),
    endColumnNo_(endColumnNo),
    isReadOnly_(isReadOnly),
    filename_(filename),
    message_(message),
    tokens_(tokens)
{
  shortMessage = getMessage_(0);
  fullMessage = getFullMessage_();
}

std::string ErrorMessage::getMessage_(int warningsAsErrors)
{
  std::string::size_type str_pos = 0;
  TokenList::iterator tok = tokens_.begin();
  char index_symbol;
  int index;

  while((str_pos = message_.find('%', str_pos)) != std::string::npos) {
    index_symbol = message_[str_pos + 1];

    if(index_symbol == 's') {
      if(tok == tokens_.end()) {
        std::cerr << "Internal error: no tokens left to replace %s with.\n";
        std::cerr << "Given message was: " << message_ << "\n";
        return "";
      }
      message_.replace(str_pos, 2, *tok);
      str_pos += tok->size();
      *tok++;
    } else if(index_symbol >= '0' && index_symbol <= '9') {
      index = index_symbol - '0' - 1;

      if(index >= tokens_.size() || index < 0) {
        std::cerr << "Internal error: Invalid positional index %" << index + 1
          << " in error message.\n";
        std::cerr << "Given message was: " << message_ << "\n";
        return "";
      }

      message_.replace(str_pos, 2, tokens_[index]);
      str_pos += tokens_[index].size();
    } else {
      ++str_pos;
    }
  }
  veryshort_msg = message_;

  std::string ret_msg;
  const char* severityStr = ErrorLevel_toStr(warningsAsErrors && severity_ == ErrorLevel_warning ? ErrorLevel_error : severity_);

  if(filename_ == "" && startLineNo_ == 0 && startColumnNo_ == 0 &&
      endLineNo_ == 0 && endColumnNo_ == 0) {
    ret_msg = severityStr + (": " + message_);
  } else {
    std::stringstream str;
    str << "[" << filename_ << ":" << startLineNo_ << ":" << startColumnNo_ <<
      "-" << endLineNo_ << ":" << endColumnNo_ << ":" <<
      (isReadOnly_ ? "readonly" : "writable") << "] " << severityStr << ": ";
    std::string positionInfo = str.str();
    ret_msg = positionInfo + message_;
  }
  // trim trailing whitespace
  ret_msg.erase(ret_msg.find_last_not_of(" \n\r\t")+1);
  return ret_msg;
}

std::string ErrorMessage::getFullMessage_()
{
  std::stringstream strbuf;

  strbuf << "{\"" << shortMessage << "\", \"" <<
    ErrorType_toStr(messageType_) << "\", \"" <<
    ErrorLevel_toStr(severity_) << "\", \"" <<
    errorID_ <<  "\"}";

  return strbuf.str();
}
