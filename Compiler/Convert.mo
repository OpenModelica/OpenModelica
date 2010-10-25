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

package Convert
" file:	 Convert.mo
  package:      Convert
  description: This file is part of a work-around implemented for the
  valueblock construct in order to avoid ciruclar file dependencies.
  It converts uniontypes located in Exp to similiar uniontypes located in DAE
  and vise versa.

  RCS: $Id$"

public import Absyn;
public import ComponentReference;
public import DAE;
public import Exp;

public function fromDAEEqsToAbsynAlg "function: fromDAEEqsToAbsynAlgElts"
  input DAE.DAElist ld;
  output list<Absyn.AlgorithmItem> outList;
  output DAE.DAElist outLd;
algorithm
  (outList,outLd) := matchcontinue (ld)
    local
      list<DAE.Element> elts;
      DAE.FunctionTree funcs;
    case(DAE.DAE(elts))
      equation
        (outList, elts) = fromDAEEqsToAbsynAlgElts(elts,{},{});
      then (outList,DAE.DAE(elts));
 end matchcontinue;
end fromDAEEqsToAbsynAlg;

public function fromDAEEqsToAbsynAlgElts "function: fromDAEEqsToAbsynAlgElts"
  input list<DAE.Element> ld;
  input list<Absyn.AlgorithmItem> accList1;
  input list<DAE.Element> accList2;
  output list<Absyn.AlgorithmItem> outList;
  output list<DAE.Element> outLd;
algorithm
  (outList,outLd) := matchcontinue (ld,accList1,accList2)
    local
      list<Absyn.AlgorithmItem> localAccList1;
      list<DAE.Element> restLd,localAccList2;
      DAE.FunctionTree funcs;
    case ({},localAccList1,localAccList2) then (listReverse(localAccList1),listReverse(localAccList2));
    case (DAE.EQUATION(exp1,exp2,_) :: restLd,localAccList1,localAccList2)
      local
        Absyn.AlgorithmItem stmt;
        DAE.Exp exp1,exp2;
        Absyn.Exp left,right;
      equation
        left = fromExpExpToAbsynExp(exp1);
        right = fromExpExpToAbsynExp(exp2);
        stmt = Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(left,right),NONE(),Absyn.dummyInfo /* TODO: Use the elementsource from the DAE.EQUATION? */);
        localAccList1 = stmt::localAccList1;
        (localAccList1,localAccList2) = fromDAEEqsToAbsynAlgElts(restLd,localAccList1,localAccList2);
      then (localAccList1,localAccList2);
    case (firstLd :: restLd,localAccList1,localAccList2)
      local
        DAE.Element firstLd;
      equation
        localAccList2 = firstLd::localAccList2;
        (localAccList1,localAccList2) = fromDAEEqsToAbsynAlgElts(restLd,localAccList1,localAccList2);
      then (localAccList1,localAccList2);
  end matchcontinue;
end fromDAEEqsToAbsynAlgElts;

// More expressions have to be added?
public function fromExpExpToAbsynExp "function: fromExpExpToAbsynExp"
  input DAE.Exp exp1;
  output Absyn.Exp expOut;
algorithm
  expOut := Exp.unelabExp(exp1);
end fromExpExpToAbsynExp;

public function fromExpCrefToAbsynCref
  input DAE.ComponentRef cIn;
  output Absyn.ComponentRef cOut;
algorithm
  cOut := ComponentReference.unelabCref(cIn);
end fromExpCrefToAbsynCref;

end Convert;





