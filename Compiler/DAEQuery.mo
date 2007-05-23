package DAEQuery

public 
import DAELow;  

protected
import System;
import Util;
import Exp;
import Absyn;
import DAE;
import Algorithm;
  
public function writeIncidenceMatrix
  input DAELow.DAELow dlow;
  input String fileNamePrefix;
  output String fileName;
algorithm
  fileName := matchcontinue(dlow, fileNamePrefix)
    local 
      String file, strIMatrix, strVariables;
      list<Integer>[:] m;
    case (dlow, fileNamePrefix)
      equation
        file = stringAppend(fileNamePrefix, "_imatrix.m");
        m = DAELow.incidenceMatrix(dlow);
        strIMatrix = getIncidenceMatrix(m);
        strVariables = getVariables(dlow);
        strIMatrix = Util.stringAppendList({strIMatrix, "\n", strVariables});
        System.writeFile(file, strIMatrix);
      then
        file;
  end matchcontinue;   
end writeIncidenceMatrix;
  
  
protected function getIncidenceMatrix "function: getIncidenceMatrix
  gets the incidence matrix as a string
"
  input DAELow.IncidenceMatrix m;
  output String strIMatrix;
  Integer mlen;
  String mlen_str;
  list<list<Integer>> m_1;
  String mstr;
algorithm 
  mlen := arrayLength(m);
  mlen_str := intString(mlen);  
  m_1 := arrayList(m);
  mstr := getIncidenceMatrix2(m_1,1);  
  strIMatrix := Util.stringAppendList({"% Incidence Matrix\n", 
    "% ====================================\n", "% number of rows: ", mlen_str, "\n", 
    "IM={", mstr, "}"});
end getIncidenceMatrix;
  
protected function getIncidenceMatrix2 "function: getIncidenceMatrix2
  author: adrpo 
  Helper function to getIncidenceMatrix (+_t).
"
  input list<list<Integer>> inIntegerLstLst;
  input Integer rowIndex;
  output String strIMatrix;
algorithm 
  strIMatrix :=
  matchcontinue (inIntegerLstLst,rowIndex)
    local
      list<Integer> row;
      list<list<Integer>> rows;
      String str, str1, str2;
    case ({},_) then ""; 
    case ((row :: {}),rowIndex)
      equation 
        str1 = getIncidenceRow(row);
        str = Util.stringAppendList({"[", str1, "]"});
      then
        str;      
    case ((row :: rows),rowIndex)
      equation 
        str1 = getIncidenceRow(row);
        str2 = getIncidenceMatrix2(rows,rowIndex+1);
        str = Util.stringAppendList({"[", str1, "],",  str2});
      then
        str;
  end matchcontinue;
end getIncidenceMatrix2;

protected function getIncidenceRow "function: getIncidenceRow
  author: adrpo
  Helper function to getIncidenceMatrix2.
"
  input list<Integer> inIntegerLst;
  output String strRow;
algorithm 
  strRow :=
  matchcontinue (inIntegerLst)
    local
      String s, s1, s2;
      Integer x;
      list<Integer> xs;
    case ({}) then "";
    case ((x :: {}))
      equation 
        s = intString(x);
      then
        s;
    case ((x :: xs))
      equation 
        s1 = intString(x);
        s2 = getIncidenceRow(xs);
        s = Util.stringAppendList({s1, ",", s2});
      then
        s;
  end matchcontinue;
end getIncidenceRow;


public function getVariables "function: getVariables
  This function returns the variables
"
  input DAELow.DAELow inDAELow;
  output String strVars;
algorithm 
  strVars:=
  matchcontinue (inDAELow)
    local
      list<DAELow.Var> vars,knvars,extvars;
      Integer varlen,eqnlen;
      String varlen_str,eqnlen_str,s;
      list<DAELow.Equation> eqnsl,reqnsl,ieqnsl;
      list<String> ss;
      list<DAELow.MultiDimEquation> ae_lst;
      DAELow.Variables vars1,vars2,vars3;
      DAELow.EquationArray eqns,reqns,ieqns;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] algs;
      list<DAELow.ZeroCrossing> zc;
      DAELow.ExternalObjectClasses extObjCls;
    case (DAELow.DAELOW(vars1,vars2,vars3,eqns,reqns,ieqns,ae,algs,DAELow.EVENT_INFO(zeroCrossingLst = zc),extObjCls))
      equation 
        vars = varList(vars1);
        s = dumpVars(vars);
        s = "VL = {" +& s +& "}";
      then
        s;
  end matchcontinue;
end getVariables;

public function varList "function: varList
  Takes Variables and returns a list of \'DAELow.Var\', useful for e.g. dumping.
"
  input DAELow.Variables inVariables;
  output list<DAELow.Var> outVarLst;
algorithm 
  outVarLst:=
  matchcontinue (inVariables)
    local
      list<DAELow.Var> varlst;
      DAELow.VariableArray vararr;
    case (DAELow.VARIABLES(varArr = vararr))
      equation 
        varlst = DAELow.vararrayList(vararr);
      then
        varlst;
  end matchcontinue;
end varList;


public function vararrayList "function: vararrayList
 
  Transforms a VariableArray to a DAELow.Var list
"
  input DAELow.VariableArray inVariableArray;
  output list<DAELow.Var> outVarLst;
algorithm 
  outVarLst:=
  matchcontinue (inVariableArray)
    local
      Option<DAELow.Var>[:] arr;
      DAELow.Var elt;
      Integer lastpos,n,size;
      list<DAELow.Var> lst;
    case (DAELow.VARIABLE_ARRAY(numberOfElements = 0,varOptArr = arr)) then {}; 
    case (DAELow.VARIABLE_ARRAY(numberOfElements = 1,varOptArr = arr))
      equation 
        SOME(elt) = arr[0 + 1];
      then
        {elt};
    case (DAELow.VARIABLE_ARRAY(numberOfElements = n,arrSize = size,varOptArr = arr))
      equation 
        lastpos = n - 1;
        lst = vararrayList2(arr, 0, lastpos);
      then
        lst;
  end matchcontinue;
end vararrayList;

protected function vararrayList2 "function: vararrayList2
 
  Helper function to vararray_list
"
  input Option<DAELow.Var>[:] inVarOptionArray1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<DAELow.Var> outVarLst;
algorithm 
  outVarLst:=
  matchcontinue (inVarOptionArray1,inInteger2,inInteger3)
    local
      DAELow.Var v;
      Option<DAELow.Var>[:] arr;
      Integer pos,lastpos,pos_1;
      list<DAELow.Var> res;
    case (arr,pos,lastpos)
      equation 
        (pos == lastpos) = true;
        SOME(v) = arr[pos + 1];
      then
        {v};
    case (arr,pos,lastpos)
      equation 
        pos_1 = pos + 1;
        SOME(v) = arr[pos + 1];
        res = vararrayList2(arr, pos_1, lastpos);
      then
        (v :: res);
  end matchcontinue;
end vararrayList2;

public function dumpVars "function: dumpVars
  Helper function to dump.
"
  input list<DAELow.Var> vars;
  output String strVars;
algorithm 
  strVars := dumpVars2(vars, 1);
end dumpVars;

protected function dumpVars2 "function: dumpVars2
  Helper function to dump_vars.
"
  input list<DAELow.Var> inVarLst;
  input Integer inInteger;
  output String strVars;
algorithm 
  strVars :=
  matchcontinue (inVarLst,inInteger)
    local
      String varnostr,dirstr,str,path_str,comment_str,s,indx_str,str1,str2;
      list<String> paths_lst,path_strs;
      Integer varno_1,indx,varno;
      DAELow.Var v;
      Exp.ComponentRef cr,old_name;
      DAELow.VarKind kind;
      DAE.VarDirection dir;
      Option<Exp.Exp> e;
      list<Absyn.Path> paths;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      DAE.Flow flow_;
      list<DAELow.Var> xs;
      DAE.Type var_type;
    case ({},_) then ""; 
    case (((v as DAELow.VAR(varName = cr,varKind = kind,varDirection = dir,varType = var_type,bindExp = e,
      index = indx,origVarName = old_name,className = paths,values = dae_var_attr,comment = comment,flow_ = flow_)) :: xs),varno)
      equation 
        varnostr = intString(varno);
        dirstr = DAE.dumpDirectionStr(dir);
        str1 = Exp.printComponentRefStr(cr);
        /*        
        paths_lst = Util.listMap(paths, Absyn.pathString);
        path_str = Util.stringDelimitList(paths_lst, ", ");
        comment_str = Dump.unparseCommentOption(comment);
        print("= ");
        s = Exp.printExpStr(e);
        print(s);
        print(" ");
        print(path_str);
        indx_str = intString(indx);
        str = DAE.dumpTypeStr(var_type);print( " type: "); print(str); 
        
        print(" indx = ");
        print(indx_str);

        print("fixed:");print(Util.boolString(varFixed(v)));
        print("\n");
        */
        varno_1 = varno + 1;        
        str2 = dumpVars2(xs, varno_1);
        str = Util.stringAppendList({"'", str1, "',", str2});
      then
        str;
    case (((v as DAELow.VAR(varName = cr,varKind = kind,varDirection = dir,varType = var_type,bindExp = e,
      index = indx,origVarName = old_name,className = paths,values = dae_var_attr,comment = comment,flow_ = flow_)) :: {}),varno)
      equation 
        varnostr = intString(varno);
        dirstr = DAE.dumpDirectionStr(dir);
        str1 = Exp.printComponentRefStr(cr);
        /*        
        paths_lst = Util.listMap(paths, Absyn.pathString);
        path_str = Util.stringDelimitList(paths_lst, ", ");
        comment_str = Dump.unparseCommentOption(comment);
        print("= ");
        s = Exp.printExpStr(e);
        print(s);
        print(" ");
        print(path_str);
        indx_str = intString(indx);
        str = DAE.dumpTypeStr(var_type);print( " type: "); print(str); 
        
        print(" indx = ");
        print(indx_str);
        varno_1 = varno + 1;
        print("fixed:");print(Util.boolString(varFixed(v)));
        print("\n");
        */
        str = Util.stringAppendList({"'", str1, "'"});
      then
        str;
  end matchcontinue;
end dumpVars2;

end DAEQuery;