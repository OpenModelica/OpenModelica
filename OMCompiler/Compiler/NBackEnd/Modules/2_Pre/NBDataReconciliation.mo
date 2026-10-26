/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package NBDataReconciliation
" file:         NBDataReconciliation.mo
  package:      NBDataReconciliation
  description:  Extraction algorithm for data reconciliation, computes the
                auxiliary conditions (SET-C) and intermediate equations (SET-S).
"

protected
  import Module = NBModule;

  import BackendDAE = NBackendDAE;

  // Util
  import Flags;
  import List;

public
  constant String UNDERLINE = "==========================================================================";

  function main extends Module.wrapper;
    input String fileNamePrefix;
  algorithm
    print("\nModelInfo: " + fileNamePrefix + "\n" + UNDERLINE + "\n\n");
  end main;

  function isEnabled
    output Boolean b = List.isMemberOnTrue("dataReconciliation", Flags.getConfigStringList(Flags.PRE_OPT_MODULES), stringEq)
                    or List.isMemberOnTrue("dataReconciliation", Flags.getConfigStringList(Flags.PRE_OPT_MODULES_ADD), stringEq);
  end isEnabled;

  annotation(__OpenModelica_Interface="nbackend");
end NBDataReconciliation;
