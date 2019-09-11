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
      let omcname='<%stringReplace(stringReplace(AbsynUtil.pathString(path,"$",false),"_","__"), "$", "_")%>'
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
        "<%AbsynUtil.pathString(path,".",false)%>",
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


template programExternalHeaderJulia(SCode.Program program)
::=
  let &buf1 = buffer ""
  let &buf2 = buffer ""
  let res = program |> cl => classExternalHeaderJulia(&buf1,&buf2,cl,"")
  <<
  /* Automatically generated header for external MetaModelica functions */
  #include <julia.h>
  #ifdef __cplusplus
  extern "C" {
  #endif
  #ifdef ADD_METARECORD_DEFINITIONS
  <%buf1%>
  void OpenModelica_initAbsynReferences()
  {
    /* Note: These values may be garbage collected away? Call this before each file is parsed? */
    jl_eval_string("import Absyn");
    <%buf2%>
  }
  #else
  void OpenModelica_initAbsynReferences();
  #endif
  <%res%>
  #ifdef __cplusplus
  }
  #endif

  >>
  /* adrpo: leave a newline at the end of file to get rid of the C warnings */
end programExternalHeaderJulia;

template classExternalHeaderJulia(Text &buf1, Text &buf2, SCode.Element cl, String pack)
::=
match cl case c as SCode.CLASS(classDef=p as SCode.PARTS(__)) then (p.elementLst |> elt => elementExternalHeaderJulia(&buf1,&buf2,elt,c.name))
end classExternalHeaderJulia;

template elementExternalHeaderJulia(Text &buf1, Text &buf2, SCode.Element elt, String pack)
::=
match elt
  case c as SCode.CLASS(restriction=r as SCode.R_METARECORD(moved = true),classDef=p as SCode.PARTS(__))
    then
      let fields1=(p.elementLst |> SCode.COMPONENT(__) => name; separator=",")
      let fields2=(p.elementLst |> SCode.COMPONENT(__) => ', <%name%>')
      let fieldsWithType=(p.elementLst |> SCode.COMPONENT(__) => 'jl_value_t *<%name%>'; separator=",")
      let funcName = '<%pack%>.<%pathString(r.name)%>'
      let omcname='<%pack%>_<%pathString(r.name)%>_<%stringReplace(c.name,"_","__")%>'
      let fullname='<%pack%>__<%stringReplace(c.name,"_","_5f")%>'
      let &buf1 +=
        <<
        extern jl_function_t *<%omcname%> = NULL;
        extern jl_value_t *<%omcname%>_type = NULL;
        <%\n%>
        >>
      let &buf2 +=
        <<
        <%omcname%> = jl_get_function(jl_base_module, "<%funcName%>");
        <%omcname%>_type = jl_get_global(jl_base_module, symbol("<%funcName%>"));<%\n%>
        >>
      <<
      extern jl_function_t *<%omcname%>;
      extern jl_function_t *<%omcname%>_type;
      <% match listLength(p.elementLst)
      case 0 then '#define <%fullname%> jl_call0(<%omcname%>)'
      case 1
      case 2
      case 3 then
        <<
        static inline jl_value_t* <%fullname%>(<%fieldsWithType%>) {
          return jl_call<%listLength(p.elementLst)%>(<%omcname%><%fields2%>);
        }
        >>
      else
        <<
        static inline jl_value_t* <%fullname%>(<%fieldsWithType%>) {
          jl_value_t *values[<%listLength(p.elementLst)%>] = {<%fields1%>};
          return jl_call(<%omcname%>, values, <%listLength(p.elementLst)%>);
        }
        >>
      %>
      <%\n%>
      >>
  case SCode.CLASS(__) then classExternalHeaderJulia(&buf1,&buf2,elt,pack)
end elementExternalHeaderJulia;

annotation(__OpenModelica_Interface="backend");
end Unparsing;

// vim: filetype=susan sw=2 sts=2
