/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
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

package Convert
" file:	 Convert.mo
  package:      Convert
  description: This file is part of a work-around implemented for the
  valueblock construct in order to avoid ciruclar file dependencies.
  It converts uniontypes located in Exp to similiar uniontypes located in DAE
  and vise versa.

  RCS: $Id$"

public import Absyn;
public import DAE;

public function fromDAEeqsToAbsynAlg "function: fromDAEeqsToAbsynAlg"
  input list<DAE.Element> ld;
  input list<Absyn.AlgorithmItem> accList1;
  input list<DAE.Element> accList2;
  output list<Absyn.AlgorithmItem> outList;
  output list<DAE.Element> outLd;
algorithm
  (outList,outLd) :=
  matchcontinue (ld,accList1,accList2)
    local
      list<Absyn.AlgorithmItem> localAccList1;
      list<DAE.Element> restLd,localAccList2;
    case ({},localAccList1,localAccList2) then (localAccList1,localAccList2);
    case (DAE.EQUATION(exp1,exp2) :: restLd,localAccList1,localAccList2)
      local
        list<Absyn.AlgorithmItem> stmt;
        DAE.Exp exp1,exp2;
        Absyn.Exp left,right;
      equation
        left = fromExpExpToAbsynExp(exp1);
        right = fromExpExpToAbsynExp(exp2);
        stmt = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(left,right),NONE())};
        localAccList1 = listAppend(localAccList1,stmt);
        (localAccList1,localAccList2) = fromDAEeqsToAbsynAlg(restLd,localAccList1,localAccList2);
      then (localAccList1,localAccList2);
    case (firstLd :: restLd,localAccList1,localAccList2)
      local
        DAE.Element firstLd;
      equation
        localAccList2 = listAppend(localAccList2,{firstLd});
        (localAccList1,localAccList2) = fromDAEeqsToAbsynAlg(restLd,localAccList1,localAccList2);
      then (localAccList1,localAccList2);
  end matchcontinue;
end fromDAEeqsToAbsynAlg;

// More expressions have to be added?
public function fromExpExpToAbsynExp "function: fromExpExpToAbsynExp"
  input DAE.Exp exp1;
  output Absyn.Exp expOut;
algorithm
  expOut :=
  matchcontinue (exp1)
    case (DAE.ICONST(i)) local Integer i; equation then Absyn.INTEGER(i);
    case (DAE.RCONST(r)) local Real r; equation then Absyn.REAL(r);
    case (DAE.SCONST(s)) local String s; equation then Absyn.STRING(s);
    case (DAE.BCONST(b)) local Boolean b; equation then Absyn.BOOL(b);
    case (DAE.CREF(cr,_))
      local
        DAE.ComponentRef cr;
        Absyn.ComponentRef c;
      equation
        c = fromExpCrefToAbsynCref(cr);
      then Absyn.CREF(c);
  end matchcontinue;
end fromExpExpToAbsynExp;

public function fromExpCrefToAbsynCref
  input DAE.ComponentRef cIn;
  output Absyn.ComponentRef cOut;
algorithm
  cOut := matchcontinue (cIn)
      local
        DAE.Ident id;
        list<DAE.Subscript> subScriptList;
        list<Absyn.Subscript> subScriptList2;
        DAE.ComponentRef cRef;
        Absyn.ComponentRef elem,cRef2;  
    case (DAE.CREF_QUAL(id,_,subScriptList,cRef))
      equation
        cRef2 = fromExpCrefToAbsynCref(cRef);
        subScriptList2 = fromExpSubsToAbsynSubs(subScriptList,{});
        elem = Absyn.CREF_QUAL(id,subScriptList2,cRef2);
      then elem;
    case (DAE.CREF_IDENT(id,_,subScriptList))
      equation
        subScriptList2 = fromExpSubsToAbsynSubs(subScriptList,{});
        elem = Absyn.CREF_IDENT(id,subScriptList2);
      then elem;
  end matchcontinue;
  end fromExpCrefToAbsynCref;

public function fromExpSubsToAbsynSubs
  input list<DAE.Subscript> inList;
  input list<Absyn.Subscript> accList;
  output list<Absyn.Subscript> outList;
algorithm
  outList :=
  matchcontinue (inList,accList)
    local
      list<Absyn.Subscript> localAccList;
    case ({},localAccList) then localAccList;
    case (DAE.INDEX(e) :: restList,localAccList)
      local
        DAE.Exp e;
        Absyn.Exp e2;
        Absyn.Subscript elem;
        list<DAE.Subscript> restList;
      equation
        e2 = fromExpExpToAbsynExp(e);
        elem = Absyn.SUBSCRIPT(e2);
        localAccList = listAppend(localAccList,{elem});
        localAccList = fromExpSubsToAbsynSubs(restList,localAccList);
      then localAccList;
  end matchcontinue;
end fromExpSubsToAbsynSubs;

end Convert;





