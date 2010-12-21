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
			     std::string type,
			     std::string severity,
			     std::string message,
			     std::list<std::string>& tokens)
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
  shortMessage = getMessage_();
  fullMessage = getFullMessage_();
}

ErrorMessage::ErrorMessage(long errorID,
			   std::string type,
			   std::string severity,
			   std::string message,
			   std::list<std::string> &tokens,
			   long startLineNo,
			   long startColumnNo,
			   long endLineNo,
			   long endColumnNo,
			   bool isReadOnly,
			   std::string filename)
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
  shortMessage = getMessage_();
  fullMessage = getFullMessage_();
}

/*
 * adrpo, 2006-02-05 changed position handling
 */
std::string ErrorMessage::getMessage_()
{
  std::list<std::string>::iterator tok;
  std::string::size_type str_pos;
  for (tok=tokens_.begin(); tok != tokens_.end(); tok++) {
    str_pos=message_.find("%s");
    if (str_pos < message_.size())
    {
      message_.replace(str_pos,2,*tok);
    }
    else
    {
      std::cerr << "Internal error in error handling, no %s left to replace "<< *tok << " with." << std::endl;
    }
  }
  std::stringstream str;
  str << "["<< filename_ << ":" << startLineNo_ << ":" << startColumnNo_ << "-" <<
  endLineNo_ << ":" << endColumnNo_ << ":" << (isReadOnly_?"readonly":"writable") << "] " << severity_ << ": ";
  std::string positionInfo = str.str();
  if (filename_ == "" && startLineNo_ == 0 && startColumnNo_ == 0 &&
      endLineNo_ == 0 && endColumnNo_ == 0 /*&& isReadOnly_ == false*/)
  {
    return severity_+": "+message_;
  }
  else
  {
    return positionInfo + message_;
  }
}

std::string ErrorMessage::getFullMessage_()
{
  std::stringstream strbuf;

  strbuf << "{\"" << shortMessage << "\", \"" <<
    messageType_ << "\", \"" <<
    severity_ << "\", \"" <<
    errorID_ <<  "\"}";

  return strbuf.str();
}
