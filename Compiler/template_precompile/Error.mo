/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Link�pings University,
 * Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
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
 * from Link�pings University, either from the above address,
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

package Error
"
  file:	       Error.mo
  package:     Error
  description: Error handling (stub for TemplCG)

  RCS: $Id: Error.mo 3863 2009-02-13 18:56:21Z sjoelund.se $

  This file contains the Error handling for the Compiler."

import Print;
import Util;

public 
type ErrorID = Integer "Unique error id. Used to 
			  look up message string and type and severity";
public
type MessageTokens = list<String>;

public constant ErrorID TEMPLCG_INVALID_TEMPLATE = 111;
public constant ErrorID TEMPLCG_FAILED_TO_APPLY_TEMPLATE = 112;

public function addMessage
  input ErrorID inErrorID;
  input MessageTokens inMessageTokens;
algorithm
  _ := Util.listMap(inMessageTokens, Print.printBuf2);
end addMessage;

end Error;

