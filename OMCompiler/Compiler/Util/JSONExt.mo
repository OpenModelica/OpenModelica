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

encapsulated package JSONExt
" file:        JSONExt.mo
  package:     JSONExt
  description: JSONExt functions

"

protected

public function serialize<T>
"@author: adrpo
 this function will serialize anything you give it in JSON format
 and will filter out any with the names given in the filter"
  input T any;
  input list<String> filter;
  output String s = "";
protected
  String name;
  list<String> components, lst;
  Integer no = 1;
algorithm
  if isInteger(any) then
    s := intString(getInteger(any));
    return;
  end if;

  if isReal(any) then
    s := realString(getReal(any));
    return;
  end if;

  if isString(any) then
    s := "\"" + getString(any) + "\"";
    return;
  end if;

  if isRecord(any) then
    // get the records and the component names
    components := getRecordNames(any);
    name::components := components;
    s := "{\"" + name + "\":{";
    no := 1;
    lst := {};
    for c in components loop
      // if is not in the filter output it
      if not listMember(c, filter) then
        lst := "\"" + c + "\":" + serialize(getRecordComponent(any, no), filter) :: lst;
      end if;
      no := no + 1;
    end for;
    lst := listReverse(lst);
    s := s + stringDelimitList(lst, ",") + "}}";
    return;
  end if;

  if isNil(any) then
    s := "[]";
    return;
  end if;

  if isCons(any) then
    s := s + "[";
    no := 1;
    lst := {};
    for c in getList(any) loop
      lst := serialize(c, filter) :: lst;
    end for;
    lst := listReverse(lst);
    s := s + stringDelimitList(lst, ",") + "]";
    return;
  end if;

  if isNONE(any) then
    s := s + "[]";
    return;
  end if;

  if isSOME(any) then
    s := s + "[" + serialize(getSome(any), filter) + "]";
    return;
  end if;

  if isTuple(any) then
    s := s + "{\"Tuple\":{";
    no := 1;
    lst := {};
    for i in 1:getTupleSize(any) loop
      lst := "\"" + intString(i) + "\":" + serialize(getListElement(any, no), filter) :: lst;
    end for;
    lst := listReverse(lst);
    s := s + stringDelimitList(lst, ",") + "}} ";
    return;
  end if;

  s := "UNKNOWN(" + anyString(any) + ")";
end serialize;

public function isInteger<T>
  input T any;
  output Boolean b;
  external "C" b = omc_is_integer(any) annotation(Include="
int omc_is_integer(modelica_metatype any)
{
  return MMC_IS_INTEGER(any);
}
");
end isInteger;

public function isReal<T>
  input T any;
  output Boolean b;
  external "C" b = omc_is_real(any) annotation(Include="
int omc_is_real(modelica_metatype any)
{
  return (MMC_GETHDR(any) == MMC_REALHDR);
}
");
end isReal;

public function isString<T>
  input T any;
  output Boolean b;
  external "C" b = omc_is_string(any) annotation(Include="
int omc_is_string(modelica_metatype any)
{
  return (MMC_HDRISSTRING(MMC_GETHDR(any)));
}
");
end isString;

public function isArray<T>
  input T any;
  output Boolean b;
  external "C" b = omc_is_array(any) annotation(Include="
int omc_is_array(modelica_metatype any)
{
  mmc_uint_t hdr;
  mmc_sint_t numslots;
  mmc_uint_t ctor;
  hdr = MMC_GETHDR(any);
  numslots = MMC_HDRSLOTS(hdr);
  ctor = MMC_HDRCTOR(hdr);
  return (numslots >= 0 && ctor == MMC_ARRAY_TAG);
}
");
end isArray;

public function isRecord<T>
  input T any;
  output Boolean b;
  external "C" b = omc_is_record(any) annotation(Include="
int omc_is_record(modelica_metatype any)
{
  mmc_uint_t hdr;
  mmc_sint_t numslots;
  mmc_uint_t ctor;
  hdr = MMC_GETHDR(any);
  numslots = MMC_HDRSLOTS(hdr);
  ctor = MMC_HDRCTOR(hdr);
  return (numslots > 0 && ctor > 1);
}
");
end isRecord;

public function isTuple<T>
  input T any;
  output Boolean b;
  external "C" b = omc_is_tuple(any) annotation(Include="
int omc_is_tuple(modelica_metatype any)
{
  mmc_uint_t hdr;
  mmc_sint_t numslots;
  mmc_uint_t ctor;
  hdr = MMC_GETHDR(any);
  numslots = MMC_HDRSLOTS(hdr);
  ctor = MMC_HDRCTOR(hdr);
  return (numslots > 0 && ctor == 0);
}
");
end isTuple;

public function isNONE<T>
  input T any;
  output Boolean b;
  external "C" b = omc_is_none(any) annotation(Include="
int omc_is_none(modelica_metatype any)
{
  mmc_uint_t hdr;
  mmc_sint_t numslots;
  mmc_uint_t ctor;
  hdr = MMC_GETHDR(any);
  numslots = MMC_HDRSLOTS(hdr);
  ctor = MMC_HDRCTOR(hdr);
  return (numslots == 0 && ctor == 1);
}
");
end isNONE;

public function isSOME<T>
  input T any;
  output Boolean b;
  external "C" b = omc_is_some(any) annotation(Include="
int omc_is_some(modelica_metatype any)
{
  mmc_uint_t hdr;
  mmc_sint_t numslots;
  mmc_uint_t ctor;
  hdr = MMC_GETHDR(any);
  numslots = MMC_HDRSLOTS(hdr);
  ctor = MMC_HDRCTOR(hdr);
  return (numslots == 1 && ctor == 1);
}
");
end isSOME;

public function isNil<T>
  input T any;
  output Boolean b;
  external "C" b = omc_is_nil(any) annotation(Include="
int omc_is_nil(modelica_metatype any)
{
  return (MMC_GETHDR(any) == MMC_NILHDR);
}
");
end isNil;

public function isCons<T>
  input T any;
  output Boolean b;
  external "C" b = omc_is_cons(any) annotation(Include="
int omc_is_cons(modelica_metatype any)
{
  mmc_uint_t hdr;
  mmc_sint_t numslots;
  mmc_uint_t ctor;
  hdr = MMC_GETHDR(any);
  numslots = MMC_HDRSLOTS(hdr);
  ctor = MMC_HDRCTOR(hdr);
  return (numslots == 2 && ctor == 1);
}
");
end isCons;

public function getRecordNames<T>
  input T any;
  output list<String> nameAndComponentsNames = listReverse(getRecordNamesHelper(any));
end getRecordNames;

protected function getRecordNamesHelper<T>
  input T any;
  output list<String> nameAndComponentsNames;
  external "C" nameAndComponentsNames = omc_get_record_names(any) annotation(Include="
modelica_metatype omc_get_record_names(modelica_metatype any)
{
  mmc_uint_t hdr;
  mmc_sint_t numslots;
  mmc_uint_t ctor;
  mmc_sint_t i;
  modelica_metatype lst = mmc_mk_nil();
  hdr = MMC_GETHDR(any);
  numslots = MMC_HDRSLOTS(hdr);
  ctor = MMC_HDRCTOR(hdr);
  if (numslots > 0 && ctor > 1)
  {
     struct record_description * desc = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),1));
     /* add the record name */
     lst = mmc_mk_cons(mmc_mk_scon(desc->name), lst);
     /* add the component names */
     for (i = 2; i <= numslots; i++)
       lst = mmc_mk_cons(mmc_mk_scon(desc->fieldNames[i-2]), lst);
  }
  return lst;
}
");
end getRecordNamesHelper;

public function getRecordComponent<TIN, TOUT>
  input TIN iany;
  input Integer offset;
  output TOUT oany;
  external "C" oany = omc_get_record_component(iany, offset) annotation(Include="
modelica_metatype omc_get_record_component(modelica_metatype any, modelica_integer offset)
{
  mmc_uint_t hdr;
  mmc_sint_t numslots;
  mmc_uint_t ctor;
  mmc_sint_t i;
  modelica_metatype out = mmc_mk_nil();
  hdr = MMC_GETHDR(any);
  numslots = MMC_HDRSLOTS(hdr);
  ctor = MMC_HDRCTOR(hdr);
  if (numslots > 0 && ctor > 1)
  {
     out = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),offset+1));
  }
  return out;
}
");
end getRecordComponent;

protected function getInteger<T>
  input T a;
  output Integer i;
external "C" i = omc_cast_int(a) annotation(Include="
modelica_integer omc_cast_int(modelica_metatype a)
{
  return MMC_UNTAGFIXNUM(a);
}");
end getInteger;

protected function getReal<T>
  input T a;
  output Real r;
external "C" r = omc_cast_real(a) annotation(Include="
modelica_real omc_cast_real(modelica_metatype a)
{
  return (double) mmc_prim_get_real(a);
}");
end getReal;

protected function getString<T>
  input T a;
  output String s;
external "C" s = omc_cast_string(a) annotation(Include="
modelica_string omc_cast_string(modelica_metatype a)
{
  return MMC_STRINGDATA(a);
}");
end getString;

protected function getSome<TIN, TOUT>
  input TIN a;
  output TOUT o;
external "C" o = omc_get_some(a) annotation(Include="
modelica_metatype omc_get_some(modelica_metatype any)
{
  return (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(any),1)));
}");
end getSome;

public function getTupleSize<T>
  input T any;
  output Integer sz;
  external "C" sz = omc_get_tuple_size(any) annotation(Include="
modelica_integer omc_get_tuple_size(modelica_metatype any)
{
  mmc_sint_t numslots = MMC_HDRSLOTS(MMC_GETHDR(any));
  return numslots;
}
");
end getTupleSize;

public function getList<TIN, TOUT>
  input TIN iany;
  output list<TOUT> oany;
  external "C" oany = omc_get_list(iany) annotation(Include="
modelica_metatype omc_get_list(modelica_metatype any)
{
  return any;
}
");
end getList;

public function getListElement<TIN, TOUT>
  input TIN iany;
  input Integer offset;
  output TOUT oany;
  external "C" oany = omc_get_list_element(iany, offset) annotation(Include="
modelica_metatype omc_get_list_element(modelica_metatype any, modelica_integer offset)
{
  return boxptr_listGet(NULL, any, mmc_mk_icon(offset));
}
");
end getListElement;

annotation(__OpenModelica_Interface="util");
end JSONExt;
