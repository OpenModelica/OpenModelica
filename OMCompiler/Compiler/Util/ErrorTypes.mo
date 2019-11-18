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

encapsulated package ErrorTypes
"
  file:        ErrorTypes.mo
  package:     ErrorTypes
  description: Types used by the error handling
"

import Gettext;

uniontype Severity "severity of message"
  record INTERNAL "Error because of a failure in the tool" end INTERNAL;

  record ERROR "Error when tool can not succeed in translation because of a user error" end ERROR;

  record WARNING "Warning when tool succeeds but with warning" end WARNING;

  record NOTIFICATION "Additional information to user, e.g. what
             actions tool has taken to succeed in translation" end NOTIFICATION;
end Severity;

uniontype MessageType "runtime scripting /interpretation error"
  record SYNTAX "syntax errors" end SYNTAX;

  record GRAMMAR "grammar errors" end GRAMMAR;

  record TRANSLATION "instantiation errors: up to
           flat modelica" end TRANSLATION;

  record SYMBOLIC "Symbolic manipulation error,
           simcodegen, up to .exe file" end SYMBOLIC;

  record SIMULATION "Runtime simulation error" end SIMULATION;

  record SCRIPTING "runtime scripting /interpretation error" end SCRIPTING;

end MessageType;

type ErrorID = Integer "Unique error id. Used to
        look up message string and type and severity";

uniontype Message
  record MESSAGE
    ErrorID id;
    MessageType ty;
    Severity severity;
    Gettext.TranslatableContent message;
  end MESSAGE;
end Message;

uniontype TotalMessage
  record TOTALMESSAGE
    Message msg;
    SourceInfo info;
  end TOTALMESSAGE;
end TotalMessage;

type MessageTokens = list<String>   "\"Tokens\" to insert into message at
            positions identified by
            - %s for string
            - %n for string number n" ;

annotation(__OpenModelica_Interface="util");
end ErrorTypes;
