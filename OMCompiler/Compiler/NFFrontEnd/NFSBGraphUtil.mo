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

encapsulated package NFSBGraphUtil

protected
  import Dimension = NFDimension;
  import Error;
  import SBInterval;
  import SBMultiInterval;
  import Vector;

public
  function multiIntervalFromDimensions
    input list<Dimension> dims;
    input Vector<Integer> vCount;
    output SBMultiInterval multiInt;
  protected
    Vector<Integer> new_vCount;
    Integer vc, dim_size, index;
    array<SBInterval> ints;
    SBInterval int;
  algorithm
    if listEmpty(dims) then
      vc := Vector.get(vCount, 1);
      Vector.update(vCount, 1, vc + 1);

      multiInt := SBMultiInterval.fromArray(arrayCreate(Vector.size(vCount), SBInterval.new(vc, 1, vc)));
    else
      ints := arrayCreate(Vector.size(vCount), SBInterval.newEmpty());
      new_vCount := Vector.copy(vCount);
      index := 1;

      for dim in dims loop
        if not Dimension.isKnown(dim) then
          Error.assertion(false, getInstanceName() + ": unknown dimension " + Dimension.toString(dim),
                                 sourceInfo());
        end if;

        dim_size := Dimension.size(dim);
        vc := Vector.get(vCount, index);
        int := SBInterval.new(vc, 1, vc + dim_size - 1);

        if SBInterval.isEmpty(int) then
          ints := listArray({});
          break;
        else
          ints[index] := int;
          Vector.update(new_vCount, index, vc + dim_size);
        end if;

        index := index + 1;
      end for;

      for i in listLength(dims)+1:Vector.size(vCount) loop
        vc := Vector.get(vCount, 1);
        ints[i] := SBInterval.new(vc, 1, vc);
      end for;

      multiInt := SBMultiInterval.fromArray(ints);

      if not SBMultiInterval.isEmpty(multiInt) then
        Vector.swap(new_vCount, vCount);
      end if;
    end if;
end multiIntervalFromDimensions;

  annotation(__OpenModelica_Interface="frontend");
end NFSBGraphUtil;