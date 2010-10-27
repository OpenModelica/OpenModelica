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

#define RML_TRUE ((void*)1)
#define RML_FALSE ((void*)0)
#include "modelica.h"
#define mk_scon(X) X

#include "errorext.cpp"

extern "C" {

void Error_addMessage(int errorID, const char* msg_type, const char* severity, const char* message, modelica_metatype tokenlst)
{
  std::list<std::string> tokens;
  if (error_on) {
    while(MMC_GETHDR(tokenlst) != MMC_NILHDR) {
      tokens.push_back(string(MMC_STRINGDATA(MMC_CAR(tokenlst))));
      tokenlst=MMC_CDR(tokenlst);
    }
    add_message(errorID,msg_type,severity,message,tokens);
    printf(" Adding message, size: %ld, %s\n",errorMessageQueue.size(),message);
  }
}

}
