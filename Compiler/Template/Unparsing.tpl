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

template classExternalHeader(SCode.Element cl, String pack)
::=
match cl case c as SCode.CLASS(classDef=p as SCode.PARTS(__)) then (p.elementLst |> elt => elementExternalHeader(elt,c.name))
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

annotation(__OpenModelica_Interface="backend");
end Unparsing;

// vim: filetype=susan sw=2 sts=2
