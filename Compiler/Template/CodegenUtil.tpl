// This file defines util functions for templates for transforming Modelica/MetaModelica code to C like
// code. They are used in the code generator phase of the compiler to write
// target code.
//
// There are two root templates intended to be called from the code generator:
// translateModel and translateFunctions. These templates do not return any
// result but instead write the result to files. All other templates return
// text and are used by the root templates (most of them indirectly).
//
// To future maintainers of this file:
//
// - A line like this
//     # var = "" /*BUFD*/
//   declares a text buffer that you can later append text to. It can also be
//   passed to other templates that in turn can append text to it. In the new
//   version of Susan it should be written like this instead:
//     let &var = buffer ""
//
// - A line like this
//     ..., Text var /*BUFP*/, ...
//   declares that a template takes a text buffer as input parameter. In the
//   new version of Susan it should be written like this instead:
//     ..., Text &var, ...
//
// - A line like this:
//     ..., var /*BUFC*/, ...
//   passes a text buffer to a template. In the new version of Susan it should
//   be written like this instead:
//     ..., &var, ...
//
// - Style guidelines:
//
//   - Try (hard) to limit each row to 80 characters
//
//   - Code for a template should be indented with 2 spaces
//
//     - Exception to this rule is if you have only a single case, then that
//       single case can be written using no indentation
//
//       This single case can be seen as a clarification of the input to the
//       template
//
//   - Code after a case should be indented with 2 spaces if not written on the
//     same line

package CodegenUtil

import interface SimCodeTV;

template crefStr(ComponentRef cr)
 "Generates the name of a variable for variable name array."
::=
  match cr
  case CREF_IDENT(__) then '<%ident%><%subscriptsStr(subscriptLst)%>'
  // Are these even needed? Function context should only have CREF_IDENT :)
  case CREF_QUAL(ident = "$DER") then 'der(<%crefStr(componentRef)%>)'
  case CREF_QUAL(__) then '<%ident%><%subscriptsStr(subscriptLst)%>.<%crefStr(componentRef)%>'
  else "CREF_NOT_IDENT_OR_QUAL"
end crefStr;

template subscriptsStr(list<Subscript> subscripts)
 "Generares subscript part of the name."
::=
  if subscripts then
    '[<%subscripts |> s => subscriptStr(s) ;separator=","%>]'
end subscriptsStr;

template subscriptStr(Subscript subscript)
 "Generates a single subscript.
  Only works for constant integer indicies."

::=
  match subscript
  case INDEX(exp=ICONST(integer=i)) then i
  case INDEX(exp=ENUM_LITERAL(name=n)) then dotPath(n)
  case SLICE(exp=ICONST(integer=i)) then i
  case WHOLEDIM(__) then "WHOLEDIM"
  else "UNKNOWN_SUBSCRIPT"
end subscriptStr;

template initValXml(Exp initialValue)
::=
  match initialValue
  case ICONST(__) then integer
  case RCONST(__) then real
  case SCONST(__) then '<%Util.escapeModelicaStringToXmlString(string)%>'
  case BCONST(__) then if bool then "true" else "false"
  case ENUM_LITERAL(__) then '<%index%> /*ENUM:<%dotPath(name)%>*/'
  else error(sourceInfo(), 'initial value of unknown type: <%printExpStr(initialValue)%>')
end initValXml;

/*********************************************************************
 *********************************************************************
 *                       Paths
 *********************************************************************
 *********************************************************************/

template dotPath(Path path)
 "Generates paths with components separated by dots."
::=
  match path
  case QUALIFIED(__)      then '<%name%>.<%dotPath(path)%>'
  case IDENT(__)          then name
  case FULLYQUALIFIED(__) then dotPath(path)
end dotPath;


/*********************************************************************
 *********************************************************************
 *                       Error
 *********************************************************************
 *********************************************************************/

template error(Absyn.Info srcInfo, String errMessage)
"Example source template error reporting template to be used together with the sourceInfo() magic function.
Usage: error(sourceInfo(), <<message>>) "
::=
let() = Tpl.addSourceTemplateError(errMessage, srcInfo)
<<

#error "<% Error.infoStr(srcInfo) %> <% errMessage %>"<%\n%>
>>
end error;

//for completeness; although the error() template above is preferable
template errorMsg(String errMessage)
"Example template error reporting template
 that is reporting only the error message without the usage of source infotmation."
::=
let() = Tpl.addTemplateError(errMessage)
<<

#error "<% errMessage %>"<%\n%>
>>
end errorMsg;

end CodegenUtil;

// vim: filetype=susan sw=2 sts=2
