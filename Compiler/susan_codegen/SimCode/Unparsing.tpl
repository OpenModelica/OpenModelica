package Unparsing

import interface UnparsingTV;

template programExternalHeader(SCode.Program program)
::=
  <<
  /* Automatically generated header for external MetaModelica functions */
  <%program |> cl => classExternalHeader(cl,"")%>
  >>
end programExternalHeader;

template classExternalHeader(SCode.Class cl, String pack)
::=
match cl case c as SCode.CLASS(classDef=p as SCode.PARTS(__)) then (p.elementLst |> elt => elementExternalHeader(elt,c.name))
end classExternalHeader;

template elementExternalHeader(SCode.Element elt, String pack)
::=
match elt
  case SCode.CLASSDEF(classDef=c as SCode.CLASS(restriction=r as SCode.R_METARECORD(__),classDef=p as SCode.PARTS(__)))
    then
      let fields=(p.elementLst |> SCode.COMPONENT(__) => component; separator=",")
      let fieldsStr=(p.elementLst |> SCode.COMPONENT(__) => '"<%component%>"'; separator=",")
      let omcname='<%pack%>_<%pathString(r.name)%>_<%c.name%>'
      let nElts=listLength(p.elementLst)
      /* <%omcname%> (index=<%r.index%>) */
      <<
      // TODO: Fix OMC generation of uniontypes to a separate C-file at the end
      const char* <%omcname%>__desc__fields_2[<%nElts%>] = {<%fieldsStr%>};
      struct record_description <%omcname%>__desc_2 = {
        "<%pack%>_<%pathString(r.name)%>_<%stringReplace(c.name,"_","__")%>",
        "<%pack%>.<%pathString(r.name)%>.<%c.name%>",
        <%omcname%>__desc__fields_2
      };
      #define <%pack%>__<%stringReplace(c.name,"_","_5f")%>_3dBOX<%nElts%> <%intAdd(3,r.index)%>
      #define <%pack%>__<%stringReplace(c.name,"_","_5f")%><%if p.elementLst then '(<%fields%>)'%> (mmc_mk_box<%intAdd(1,listLength(p.elementLst))%>(<%intAdd(3,r.index)%>,&<%omcname%>__desc_2<%if p.elementLst then ',<%fields%>'%>))<%\n%>>>

  case SCode.CLASSDEF(__) then classExternalHeader(classDef,pack)
end elementExternalHeader;

end Unparsing;

// vim: filetype=susan sw=2 sts=2
