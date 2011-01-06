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

template classExternalHeader(SCode.Class cl, String pack)
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

template elementExternalHeader(SCode.Element elt, String pack)
::=
match elt
  case SCode.CLASSDEF(classDef=c as SCode.CLASS(restriction=r as SCode.R_METARECORD(__),classDef=p as SCode.PARTS(__)))
    then
      let fields=(p.elementLst |> SCode.COMPONENT(__) => component; separator=",")
      let fieldsStr=(p.elementLst |> SCode.COMPONENT(__) => '"<%component%>"'; separator=",")
      let omcname='<%pack%>_<%pathString(r.name)%>_<%stringReplace(c.name,"_","__")%>'
      let nElts=listLength(p.elementLst)
      let fullname='<%pack%>__<%stringReplace(c.name,"_","_5f")%>'
      let ctor=intAdd(3,r.index)
      <<
      #ifdef ADD_METARECORD_DEFINTIONS
      #ifndef <%omcname%>__desc_added
      #define <%omcname%>__desc_added
      const char* <%omcname%>__desc__fields[<%nElts%>] = {<%fieldsStr%>};
      struct record_description <%omcname%>__desc = {
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
        #define <%fullname%>(<%fields%>) (mmc_mk_box<%intAdd(1,listLength(p.elementLst))%>(<%ctor%>,&<%omcname%>__desc,<%fields%>))<%\n%>
        >>
        else
        <<
        static const MMC_DEFSTRUCTLIT(<%fullname%>__struct,1,<%ctor%>) {&<%omcname%>__desc}};
        static void *<%fullname%> = MMC_REFSTRUCTLIT(<%fullname%>__struct);<%\n%>
        >>
      %>
      >>
  case SCode.CLASSDEF(__) then classExternalHeader(classDef,pack)
end elementExternalHeader;

end Unparsing;

// vim: filetype=susan sw=2 sts=2
