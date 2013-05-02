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

encapsulated package Visited
" file:  Visited.mo
  package:     Visited
  description: Visited is a relation Integer <-> Integer.

  RCS: $Id: Visited.mo 8980 2011-05-13 09:12:21Z adrpo $

  The Visited relation."

import Pool;

type Visited = Pool.Pool<Integer>  "an array of unique scope ids visited during lookup, the integer points to the previous scope";

constant Integer defaultPoolSizeVisited   = 1000;

public function pool
  output Visited outVisited;
algorithm
  outVisited := Pool.create("Visited", defaultPoolSizeVisited);
end pool;

public function get
  input Visited inVisited;
  input Integer inID;
  output Integer outInteger;
algorithm
  outInteger := Pool.get(inVisited, inID);
end get;

end Visited;

