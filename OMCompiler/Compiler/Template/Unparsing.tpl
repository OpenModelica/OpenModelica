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

package Unparsing

import interface SimCodeTV;

template programExternalHeader(SCode.Program program)
::=
  <<
  /* Automatically generated header for external MetaModelica functions */
  #ifdef __cplusplus
  extern "C" {
  #endif
  <%program |> cl => classExternalHeader(cl,"")%>
  #ifdef __cplusplus
  }
  #endif

  >>
  /* adrpo: leave a newline at the end of file to get rid of the C warnings */
end programExternalHeader;

template programExternalHeaderFromTypes(list<DAE.Type> tys)
::=
  <<
  /* Automatically generated header for bootstrapping MetaModelica */
  #ifdef __cplusplus
  extern "C" {
  #endif
  <%tys |> ty as T_METARECORD(__) =>
      let fieldsStr=(ty.fields |> var as TYPES_VAR(__) => '"<%var.name%>"'; separator=",")
      let omcname='<%stringReplace(stringReplace(AbsynUtil.pathString(path, "$", false, false),"_","__"), "$", "_")%>'
      let nElts = listLength(ty.fields)
      /* adrpo 2011-03-14 make MSVC happy, no arrays of 0 size! */
      let fieldsDescription =
           match nElts
           case "0" then
             'ADD_METARECORD_DEFINITIONS const char* <%omcname%>__desc__fields[1] = {"no fields"};'
           case _ then
             'ADD_METARECORD_DEFINITIONS const char* <%omcname%>__desc__fields[<%nElts%>] = {<%fieldsStr%>};'
      <<
      #ifdef ADD_METARECORD_DEFINITIONS
      #ifndef <%omcname%>__desc_added
      #define <%omcname%>__desc_added
      <%fieldsDescription%>
      ADD_METARECORD_DEFINITIONS struct record_description <%omcname%>__desc = {
        "<%omcname%>",
        "<%AbsynUtil.pathString(path, ".", false, false)%>",
        <%omcname%>__desc__fields
      };
      #endif
      #else /* Only use the file as a header */
      extern struct record_description <%omcname%>__desc;
      #endif
      >>
      ; separator = "\n"
  %>
  #ifdef __cplusplus
  }
  #endif

  >>
  /* adrpo: leave a newline at the end of file to get rid of the C warnings */
end programExternalHeaderFromTypes;

template classExternalHeader(SCode.Element cl, String pack)
::=
match cl
  case c as SCode.CLASS(restriction = SCode.R_METARECORD(moved = true, name = Absyn.IDENT(name = name))) then elementExternalHeader(cl, name)
  case c as SCode.CLASS(classDef=p as SCode.PARTS(__)) then (p.elementLst |> elt => elementExternalHeader(elt,c.name))
end classExternalHeader;

template pathString(Absyn.Path path)
::=
match path
  case IDENT(__) then name
  case QUALIFIED(__) then '<%name%>.<%pathString(path)%>'
  case FULLYQUALIFIED(__) then pathString(path)
end pathString;

template metaHelperBoxStart(Integer numVariables)
 "Helper to determine how mmc_mk_box should be called."
::=
  match numVariables
  case 0
  case 1
  case 2
  case 3
  case 4
  case 5
  case 6
  case 7
  case 8
  case 9 then '<%numVariables%>('
  else '(<%numVariables%>, '
end metaHelperBoxStart;

template elementExternalHeader(SCode.Element elt, String pack)
::=
match elt
  case c as SCode.CLASS(restriction=r as SCode.R_METARECORD(moved = true),classDef=p as SCode.PARTS(__))
    then
      let fields=(p.elementLst |> SCode.COMPONENT(__) => name; separator=",")
      let fieldsStr=(p.elementLst |> SCode.COMPONENT(__) => '"<%name%>"'; separator=",")
      let omcname='<%pack%>_<%pathString(r.name)%>_<%stringReplace(c.name,"_","__")%>'
      let nElts=listLength(p.elementLst)
      let fullname='<%pack%>__<%stringReplace(c.name,"_","_5f")%>'
      let ctor=intAdd(3,r.index)
      /* adrpo 2011-03-14 make MSVC happy, no arrays of 0 size! */
      let fieldsDescription =
           match nElts
           case "0" then
             'ADD_METARECORD_DEFINITIONS const char* <%omcname%>__desc__fields[1] = {"no fields"};'
           case _ then
             'ADD_METARECORD_DEFINITIONS const char* <%omcname%>__desc__fields[<%nElts%>] = {<%fieldsStr%>};'
      <<
      #ifdef ADD_METARECORD_DEFINITIONS
      #ifndef <%omcname%>__desc_added
      #define <%omcname%>__desc_added
      <%fieldsDescription%>
      ADD_METARECORD_DEFINITIONS struct record_description <%omcname%>__desc = {
        "<%omcname%>",
        "<%pack%>.<%pathString(r.name)%>.<%c.name%>",
        <%omcname%>__desc__fields
      };
      #endif
      #else /* Only use the file as a header */
      extern struct record_description <%omcname%>__desc;
      #endif
      #define <%fullname%>_3dBOX<%nElts%> <%ctor%>
      <% if p.elementLst then
        <<
        #define <%fullname%>(<%fields%>) (mmc_mk_box<%metaHelperBoxStart(intAdd(1,listLength(p.elementLst)))%><%ctor%>,&<%omcname%>__desc,<%fields%>))<%\n%>
        >>
        else
        <<
        static const MMC_DEFSTRUCTLIT(<%fullname%>__struct,1,<%ctor%>) {&<%omcname%>__desc}};
        static void *<%fullname%> = MMC_REFSTRUCTLIT(<%fullname%>__struct);<%\n%>
        >>
      %>
      >>
  case SCode.CLASS(__) then classExternalHeader(elt,pack)
end elementExternalHeader;

annotation(__OpenModelica_Interface="backend_tools");
end Unparsing;

// vim: filetype=susan sw=2 sts=2
