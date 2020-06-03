/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-2020, Open Source Modelica Consortium (OSMC),
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
encapsulated uniontype NBVariableReplacements
"file:        NBVariableReplacements.mo
 package:     NBVariableReplacements
 description:
  VariableReplacements consists of a mapping between variables and expressions, the first binary tree of this type.
  To eliminate a variable from an equation system a replacement rule varname->expression is added to this
  datatype.
  To be able to update these replacement rules incrementally a backward lookup mechanism is also required.
  For instance, having a rule a->b and adding a rule b->c requires to find the first rule a->b and update it to
  a->c. This is what the second binary tree is used for.
"

protected
  // rename self import
  import VariableReplacements = NBVariableReplacements;

  // NF imports
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import HashSet = NFHashSet;
  import HashTableCrToExp = NFHashTableCrToExp;
  import HashTableCrToLst = NFHashTable3;

  // Util imports
  import BaseHashTable;


public
  record REPLACEMENTS
    HashTableCrToExp.HashTable hashTable        "src -> dst, used for replacing. src is variable, dst is expression.";
    //HashTableCrToLst.HashTable invHashTable     "dst -> list of sources. dst is a variable, sources are variables.";
    //HashSet.HashSet extendHashSet               "src -> nothing, used for extend arrays and records.";
    //list<String> iterationVars                  "this are the implicit declerate iteration variables for for and range expressions";
    //Option<HashTableCrToExp.HashTable> derConst "this is used if states are constant to replace der(state) with 0.0";
  end REPLACEMENTS;

  function empty
    "Returns an empty set of replacement rules"
    output VariableReplacements variableReplacements;
    input Integer size = BaseHashTable.defaultBucketSize;
  protected
    HashTableCrToExp.HashTable hashTable;
  algorithm
    // ToDo: remove all those sized calls, they are just duplicate functions
    hashTable := HashTableCrToExp.emptyHashTableSized(size);
    variableReplacements := REPLACEMENTS(hashTable);
  end empty;

  function add
    input output VariableReplacements replacements;
    input ComponentRef src;
    input Expression dst;
  algorithm
    replacements := match replacements
      local
        HashTableCrToExp.HashTable hashTable;
      case REPLACEMENTS(hashTable = hashTable)
        algorithm
          hashTable := BaseHashTable.add((src, dst), hashTable);
      then REPLACEMENTS(hashTable);
      else fail();
    end match;
  end add;

  function addList
    input output VariableReplacements replacements;
    input list<tuple<ComponentRef, Expression>> tpl_lst;
  protected
    ComponentRef src;
    Expression dst;
  algorithm
    for tpl in tpl_lst loop
      (src, dst) := tpl;
      replacements := add(replacements, src, dst);
    end for;
  end addList;
/*
  public function add
    "Adds a replacement rule to the set of replacement rules given as argument.
    If a replacement rule a->b already exists and we add a new rule b->c then
    the rule a->b is updated to a->c. This is done using the make_transitive
    function."
    input VariableReplacements replacements;
    input ComponentRef src;
    input Expression dst;
    //input Option<FuncTypeExp_ExpToBoolean> inFuncTypeExpExpToBooleanOption;
    output VariableReplacements outRepl;
  algorithm
    outRepl:= match (repl,inSrc,inDst,inFuncTypeExpExpToBooleanOption)
      local
        DAE.ComponentRef src,src_1;
        DAE.Exp dst,dst_1;
        HashTable2.HashTable ht,ht_1,eht,eht_1;
        HashTable3.HashTable invHt,invHt_1;
        list<DAE.Ident> iv;
        String s;
        Option<HashTable2.HashTable> derConst;

      case ((repl as REPLACEMENTS(ht,invHt)),src,dst)
        algorithm
          olddst = BaseHashTable.get(src, ht) "if rule a->b exists, fail";
       then fail();

      case (_,src,dst,_)
        equation
          (REPLACEMENTS(ht,invHt,eht,iv,derConst),src_1,dst_1) = makeTransitive(repl, src, dst, inFuncTypeExpExpToBooleanOption);
          ht_1 = BaseHashTable.add((src_1, dst_1),ht);
          invHt_1 = addReplacementInv(invHt, src_1, dst_1);
          eht_1 = addExtendReplacement(eht,src_1,NONE());
        then
          REPLACEMENTS(ht_1,invHt_1,eht_1,iv,derConst);
      case (_,_,_,_)
        equation
          s = ComponentReference.printComponentRefStr(inSrc);
          print("-BackendVarTransform.addReplacement failed for " + s);
        then
          fail();
    end match;
  end add;
*/
/*
  function remove
    "removes the replacement for a given key using BaseHashTable.delete
    the extendhashSet is not updated"
    input VariableReplacements replacements   "replacements object";
    input ComponentRef src                    "cref to remove";
  algorithm
    _ := match replacements
      local
        Expression dst;
        HashTableCrToExp.HashTable hashTable;
        HashTableCrToLst.HashTable invHashTable;
      case REPLACEMENTS(hashTable = hashTable, invHashTable = invHashTable)
        algorithm
          if BaseHashTable.hasKey(src, hashTable) then
            dst := BaseHashTable.get(src, hashTable);
            BaseHashTable.delete(src, hashTable);
            removeInv(invHashTable, dst);
          end if;
      then ();

      else algorithm
        Error.addInternalError(getInstanceName() + " failed for " + ComponentRef.toString(src) +"\n", sourceInfo());
      then fail();
    end match;
  end remove;

  function removeList
    input VariableReplacements replacements "replacements object";
    input list<ComponentRef> src_lst        "cref list to remove";
  algorithm
    for src in src_lst loop
      remove(replacements, src);
    end for;
  end removeList;

protected
  function removeInv
    "Helper function to remove
    removes the inverse rule of a replacement in the second binary tree
    of VariableReplacements."
    input HashTableCrToLst.HashTable invHashTable;
    input Expression dst;
  algorithm
    for exp in Expression.extract(dst, Expression.isCref) loop
      BaseHashTable.delete(Expression.toCref(exp), invHashTable);
    end for;
  end removeInv;
*/

  annotation(__OpenModelica_Interface="backend");
end NBVariableReplacements;
