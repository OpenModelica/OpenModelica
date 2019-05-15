package NFInstDumpTpl

import interface NFInstDumpTV;
import AbsynDumpTpl;
import ExpressionDumpTpl;

template dumpModel(String name, Class cls)
::=
<<
class <%name%>
<%dumpClass(cls)%>
end <%name%>
>>
end dumpModel;

template dumpComponent(Component component)
::=
match component
  case UNTYPED_COMPONENT(__) then
    let name_str = AbsynDumpTpl.dumpPath(name)
    let bind_str = dumpBinding(binding)
    let ty_str = ExpressionDumpTpl.dumpType(baseType)
    let dims_str = NFInstDump.dumpUntypedComponentDims(component)
    '{<%ty_str%><%dims_str%>} <%name_str%><%bind_str%>;'
  case TYPED_COMPONENT(__) then
    let name_str = AbsynDumpTpl.dumpPath(name)
    let bind_str = dumpBinding(binding)
    let ty_str = ExpressionDumpTpl.dumpType(ty)
    '<%ty_str%> <%name_str%><%bind_str%>;'
  case CONDITIONAL_COMPONENT(__) then
    let name_str = AbsynDumpTpl.dumpPath(name)
    'conditional <%name_str%>;'
  case DELETED_COMPONENT(__) then
    let name_str = AbsynDumpTpl.dumpPath(name)
    'deleted <%name_str%>;'
  case OUTER_COMPONENT(innerName = SOME(in)) then
    let outer_str = AbsynDumpTpl.dumpPath(name)
    let inner_str = AbsynDumpTpl.dumpPath(in)
    'outer <%outer_str%> -> <%inner_str%>;'
  case OUTER_COMPONENT(__) then
    let outer_str = AbsynDumpTpl.dumpPath(name)
    'outer <%outer_str%>;'
end dumpComponent;

template dumpElement(Element element)
::=
match element
  case ELEMENT(__) then
    let comp_str = dumpComponent(component)
    let cls_str = dumpClass(cls)
    let sep_str = if cls_str then "\n"
    '<%comp_str%><%sep_str%><%cls_str%>'
  case CONDITIONAL_ELEMENT(__) then
    let comp_str = dumpComponent(component)
    '<%comp_str%>'
  case EXTENDED_ELEMENTS(__) then
    let cls_str = dumpClass(cls)
    '<%cls_str%>'
end dumpElement;

template dumpClass(Class cls)
::=
match cls
  case COMPLEX_CLASS(__) then
    let comp_str = (components |> comp => dumpElement(comp) ;separator="\n")
    let ieq_str = (initialEquations |> ieq => dumpEquation(ieq) ;separator="\n")
    let eq_str = (equations |> eq => dumpEquation(eq) ;separator="\n")
    let comp_seq_str = if comp_str then
    <<
      <%comp_str%>
    >>
    let ieq_seq_str = if ieq_str then
    <<

    initial equation
      <%ieq_str%>
    <%if eq_str then '' else 'end equation;'%>
    >>
    let eq_seq_str = if eq_str then
    <<

    equation
      <%eq_str%>
    end equation;
    >>
    '<%comp_seq_str%><%ieq_seq_str%><%eq_seq_str%>'
end dumpClass;

template dumpExp(DAE.Exp exp)
::= ExpressionDumpTpl.dumpExp(exp, "\"")
end dumpExp;

template dumpEquation(Equation equation)
::=
match equation
  case EQUALITY_EQUATION(__) then
    let lhs_str = dumpExp(lhs)
    let rhs_str = dumpExp(rhs)
    let lhs_ty_str = ExpressionDumpTpl.dumpType(Expression.typeof(lhs))
    let rhs_ty_str = ExpressionDumpTpl.dumpType(Expression.typeof(rhs))
    '<%lhs_str%> {<%lhs_ty_str%>} = {<%rhs_ty_str%>} <%rhs_str%>;'
  //case CONNECT_EQUATION(__) then
  //  let lhs_str = ExpressionDumpTpl.dumpCref(lhs)
  //  let rhs_str = ExpressionDumpTpl.dumpCref(rhs)
  //  let lhs_face_str = dumpFace(lhsFace)
  //  let rhs_face_str = dumpFace(rhsFace)
  //  'connect(<%lhs_str%> <<%lhs_face_str%>>, <%rhs_str%> <<%rhs_face_str%>>);'
  case FOR_EQUATION(__) then
    let ty_str = ExpressionDumpTpl.dumpType(indexType)
    let range_str = match range case SOME(range_exp) then
      ' in <%dumpExp(range_exp)%>'
    let eql_str = (body |> eq => dumpEquation(eq) ;separator="\n")
    <<
    for {<%ty_str%>} <%name%> /* index <%index%> */<%range_str%> loop
      <%eql_str%>
    end for;
    >>
  case IF_EQUATION(__) then
    'if equation;'
  case ASSERT_EQUATION(__) then
    let cond_str = dumpExp(condition)
    let msg_str = dumpExp(message)
    'assert(<%cond_str%>, <%msg_str%>);'
  case TERMINATE_EQUATION(__) then
    let msg_str = dumpExp(message)
    'terminate(<%msg_str%>);'
  case REINIT_EQUATION(__) then
    let cref_str = ExpressionDumpTpl.dumpCref(cref)
    let exp_str = dumpExp(reinitExp)
    'reinit(<%cref_str%>, <%exp_str%>)'
  case NORETCALL_EQUATION(__) then dumpExp(exp)
  else 'dumpEquation: IMPLEMENT ME'
end dumpEquation;

template dumpBinding(Binding binding)
::=
match binding
  case RAW_BINDING(bindingExp = aexp) then
    let exp_str = AbsynDumpTpl.dumpExp(aexp)
    ' = <RAW> <%exp_str%>'
  case UNTYPED_BINDING(__) then
    let exp_str = dumpExp(bindingExp)
    ' = <%exp_str%>'
  case TYPED_BINDING(__) then
    let exp_str = dumpExp(bindingExp)
    let ty_str = ExpressionDumpTpl.dumpType(bindingType)
    ' = (<%ty_str%>) <%exp_str%>'
end dumpBinding;

template dumpPrefix(Prefix prefix)
::=
match prefix
  case PREFIX(__) then
    let dims_str = if dims then '[<%ExpressionDumpTpl.dumpDimensions(dims)%>]'
    let rest_str = dumpPrefix(restPrefix)
    let pre_str = if rest_str then '<%rest_str%>.'
    '<%pre_str%><%name%><%dims_str%>'
end dumpPrefix;

//template dumpConnections(Connections conn)
//::=
//match conn
//  case CONNECTIONS(__) then
//    let conn_str = (connections |> c => dumpConnection(c) ;separator="\n")
//    '<%conn_str%>'
//end dumpConnections;
//
//template dumpConnection(Connection connection)
//::=
//match connection
//  case CONNECTION(__) then
//    let lhs_str = dumpConnector(lhs)
//    let rhs_str = dumpConnector(rhs)
//    'connect(<%lhs_str%>, <%rhs_str%>)'
//end dumpConnection;
//
//template dumpConnector(Connector connector)
//::=
//match connector
//  case CONNECTOR(__) then
//    let name_str = ExpressionDumpTpl.dumpCref(name)
//    let face_str = dumpFace(face)
//    '<%name_str%> <<%face_str%>>'
//end dumpConnector;
//
//template dumpFace(Face face)
//::=
//match face
//  case INSIDE() then 'inside'
//  case OUTSIDE() then 'outside'
//  case NO_FACE() then 'no_face'
//end dumpFace;

template dumpDimension(NFInstTypes.Dimension dim)
::=
match dim
  case UNTYPED_DIMENSION(__) then ExpressionDumpTpl.dumpDimension(dimension)
  case TYPED_DIMENSION(__) then ExpressionDumpTpl.dumpDimension(dimension)
end dumpDimension;

template errorMsg(String errMessage)
::=
let() = Tpl.addTemplateError(errMessage)
<<
<%errMessage%>
>>
end errorMsg;

annotation(__OpenModelica_Interface="frontend");
end NFInstDumpTpl;
// vim: filetype=susan sw=2 sts=2
