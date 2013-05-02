/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package Reference
" file:  Reference.mo
  package:     Reference
  description: Reference is a reference to an instance with a modification (a link).

  RCS: $Id: Reference.mo 8980 2011-05-13 09:12:21Z adrpo $

  The Reference is defined here."

public
import Absyn;
import SCode;

constant Integer highPriority   = 100;
constant Integer mediumPriority = 50;
constant Integer lowPriority    = 0;

uniontype Status
  record RESOLVED "to an node with contents instance"
    Integer iID "the id of the instance";
  end RESOLVED;

  record UNRESOLVED "unresolved yet"
    Integer priority "how much do we need to resolve this reference";
  end UNRESOLVED;
end Status;

uniontype Modifier
  record IM "instance modifier"
    SCode.Mod       mod "the modifications for this instance";
    Absyn.ArrayDim  ad  "the array dimensions for this instance";
    list<Reference> modReferences "all crefs in mod as references to be resolved";
    list<Reference> adReferences "all crefs in ad as references to be resolved";
  end IM;

  record IS "instance selection in an array instance"
    list<Absyn.Subscript> subs;
    list<Reference> subsReferences "all crefs in subs as references to be resolved";
  end IS;

  record IU "instance unmodified"
  end IU;
end Modifier;

uniontype Identifier
  record ID
    Integer  rID     "the reference node id";
    Modifier mod     "the modifers that should be applied to the resolved instance";
    Status   status  "the status of this instance: resolved or unresolved";
  end ID;
end Identifier;

uniontype Reference
"an instance reference.
 there are composite references (qualified) in which the list is more than one identifier.
 there are simple references (ident) in which the list is one identifier only.
 To resolve a composite reference you need to resolve all the reference nodes in it.
 The modifiers are either instance modifiers (for types) and component selection (for array
 components).
 Examples:
   composite type reference: Modelica.SIunit.Voltage(mods) {(id1,IU,U),(id2,IU,U),(id3,IM(mods),U)}
   composite comp reference: x[1].y.z                {(id1,IS(1),U),(id2,IU,U),(id3,IU,U)}
 Note: the names of the ids are in the Scopes pointed by Node.scopeId (and is always a full path).
       all reference nodes are added to the graph but only the top one in a composite reference
       is pointed by the instance nodes.
 "
  record R "reference"
    list<Identifier> reference "a reference is a list of identifiers with a nodeId, modifications and a status";
  end R;
end Reference;

end Reference;

