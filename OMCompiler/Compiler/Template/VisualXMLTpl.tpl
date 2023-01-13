// This file defines template-extensions for transforming Modelica code into parallel hpcom-code.
//
// There are one root template intended to be called from the code generator:
// translateModel. These template do not return any
// result but instead write the result to files. All other templates return
// text and are used by the root templates (most of them indirectly).

package VisualXMLTpl

import interface VisualXMLTplTV;

//------------------------------------
// Section for Visualization XML Dump
//------------------------------------

template dumpVisXML(array<VisualXML.Visualization> vis, String fileName)
::=
  let()= textFile(dumpVisXML1(vis), fileName)
  ""
end dumpVisXML;

template dumpVisXML1(array<VisualXML.Visualization> visArr)
::=
  let visDump = arrayList(visArr) |> vis => dumpVisualization(vis) ; separator="\n"
  <<
  <?xml version="1.0" encoding="UTF-8" standalone="no"?>
  <visualization>
  <%visDump%>
  </visualization>
  >>
end dumpVisXML1;

template dumpVisualization(VisualXML.Visualization vis)
::=
    match vis
        case vis as SHAPE(shapeType = sT as DAE.SCONST(string = svalue)) then
          let TDump = arrayList(T) |> T0 => <<
          <%dumpVecExp(T0)%>
          >> ; separator="\n"
          let rDump = dumpVecExp(arrayList(r))
          let r_shapeDump = dumpVecExp(arrayList(r_shape))
          let lDirDump = dumpVecExp(arrayList(lengthDir))
          let wDirDump = dumpVecExp(arrayList(widthDir))
          let colorDump = dumpVecExp(arrayList(color))
            <<
              <shape>
                  <ident><%ComponentReference.printComponentRefStr(ident)%></ident>
                  <type><%svalue%></type>
                  <T>
                      <%TDump%>
                  </T>
                  <r>
                      <%rDump%>
                  </r>
                  <r_shape>
                      <%r_shapeDump%>
                  </r_shape>
                  <lengthDir>
                      <%lDirDump%>
                  </lengthDir>
                  <widthDir>
                      <%wDirDump%>
                  </widthDir>
                  <length><%dumpExp(length)%></length>
                  <width><%dumpExp(width)%></width>
                  <height><%dumpExp(height)%></height>
                  <extra><%dumpExp(extra)%></extra>
                  <color>
                      <%colorDump%>
                  </color>
                  <specCoeff><%dumpExp(specularCoeff)%></specCoeff>
              </shape>
            >>

        case vis as VECTOR() then
          let TDump = arrayList(T) |> T0 => <<
          <%dumpVecExp(T0)%>
          >> ; separator="\n"
          let rDump = dumpVecExp(arrayList(r))
          let coordDump = dumpVecExp(arrayList(coordinates))
          let colorDump = dumpVecExp(arrayList(color))
            <<
              <vector>
                  <ident><%ComponentReference.printComponentRefStr(ident)%></ident>
                  <T>
                      <%TDump%>
                  </T>
                  <r>
                      <%rDump%>
                  </r>
                  <coordinates>
                      <%coordDump%>
                  </coordinates>
                  <color>
                      <%colorDump%>
                  </color>
                  <specCoeff><%dumpExp(specularCoeff)%></specCoeff>
                  <quantity><%dumpExp(quantity)%></quantity>
                  <headAtOrigin><%dumpExp(headAtOrigin)%></headAtOrigin>
                  <twoHeadedArrow><%dumpExp(twoHeadedArrow)%></twoHeadedArrow>
              </vector>
            >>

        case vis as SURFACE() then
          let TDump = arrayList(T) |> T0 => <<
          <%dumpVecExp(T0)%>
          >> ; separator="\n"
          let r_0Dump = dumpVecExp(arrayList(r_0))
          let colorDump = dumpVecExp(arrayList(color))
            <<
              <surface>
                  <ident><%ComponentReference.printComponentRefStr(ident)%></ident>
                  <T>
                      <%TDump%>
                  </T>
                  <r>
                      <%r_0Dump%>
                  </r>
                  <nu><%dumpExp(nu)%></nu>
                  <nv><%dumpExp(nv)%></nv>
                  <wireframe><%dumpExp(wireframe)%></wireframe>
                  <multiColored><%dumpExp(multiColored)%></multiColored>
                  <color>
                      <%colorDump%>
                  </color>
                  <specCoeff><%dumpExp(specularCoeff)%></specCoeff>
                  <transparency><%dumpExp(transparency)%></transparency>
              </surface>
            >>
    end match
end dumpVisualization;

template dumpVecExp (list<DAE.Exp> vector)
::=
let vecDump = vector |> vec => <<<%dumpExp(vec)%>>> ; separator="\n"
    <<
    <%vecDump%>>>
end dumpVecExp;

template dumpExp (DAE.Exp expIn)
::=
    match expIn
        case expIn as ENUM_LITERAL(__) then
            <<
            <enum><%intString(index)%></enum>
            >>
        case expIn as BCONST(__) then
            <<
            <bconst><%ExpressionDump.printExpStr(expIn)%></bconst>
            >>
        case expIn as CREF(__) then
            <<
            <cref><%ExpressionDump.printExpStr(expIn)%></cref>
            >>
        case expIn as BINARY(__) then
            <<<binary>
            <%dumpExp(exp1)%>
                <op><%dumpOperator(operator)%></op>
            <%dumpExp(exp2)%>
            </binary>
            >>
        case expIn as UNARY(__) then
            <<<unary>
                <op><%dumpOperator(operator)%></op>
            <%dumpExp(exp)%>
            </unary>
            >>
        case expIn as LBINARY(__) then
            <<<lbinary>
                <%dumpExp(exp1)%>
                <op><%dumpOperator(operator)%></op>
                <%dumpExp(exp2)%>
            </lbinary>
            >>
        case expIn as LUNARY(__) then
            <<<lunary>
                <op><%dumpOperator(operator)%></op>
            <%dumpExp(exp)%>
            </lunary>
            >>
        case expIn as RELATION(__) then
            <<<relation>
                <exp1><%dumpExp(exp1)%></exp1>
                <op><%dumpOperator(operator)%></op>
                <exp2><%dumpExp(exp2)%></exp2>
            </relation>
            >>
        case expIn as IFEXP(__) then
            <<<ifexp>
                <cond><%dumpExp(expCond)%></cond>
                <then><%dumpExp(expThen)%></then>
                <else><%dumpExp(expElse)%></else>
            </ifexp>
            >>
        case expIn as CALL(__) then
            let elist = expLst |> e => <<<%dumpExp(e)%>>> ; separator="\n"
            <<<call>
                <path><%pathString(path)%></path>
                <expLst><%elist%></expLst>
            </call>
            >>
        else
            <<
            <exp><%ExpressionDump.printExpStr(expIn)%></exp>
            >>
    end match
end dumpExp;

template dumpOperator (DAE.Operator op)
::=
    match op
        case op as ADD() then
            <<add>>
        case op as SUB() then
            <<sub>>
        case op as MUL() then
            <<mul>>
        case op as DIV() then
            <<div>>
        case op as POW() then
            <<pow>>
        case op as UMINUS() then
            <<uminus>>
        case op as UMINUS_ARR() then
            <<uminus_arr>>
        case op as ADD_ARR() then
            <<add_arr>>
        case op as SUB_ARR() then
            <<sub_arr>>
        case op as MUL_ARR() then
            <<mul_arr>>
        case op as DIV_ARR() then
            <<siv_arr>>
        case op as MUL_ARRAY_SCALAR() then
            <<mul_array_scalar>>
        case op as ADD_ARRAY_SCALAR() then
            <<add_array_scalar>>
        case op as SUB_SCALAR_ARRAY() then
            <<sub_scalar_array>>
        case op as MUL_SCALAR_PRODUCT() then
            <<mul_scalar_product>>
        case op as MUL_MATRIX_PRODUCT() then
            <<mul_matrix_product>>
        case op as DIV_ARRAY_SCALAR() then
            <<div_array_scalar>>
        case op as DIV_SCALAR_ARRAY() then
            <<siv_scalar_array>>
        case op as POW_ARRAY_SCALAR() then
            <<pow_array_scalar>>
        case op as POW_SCALAR_ARRAY() then
            <<pow_scalar_array>>
        case op as POW_ARR() then
            <<pow_arr>>
        case op as POW_ARR2() then
            <<por_arr2>>
        case op as AND() then
            <<and>>
        case op as OR() then
            <<or>>
        case op as NOT() then
            <<not>>
        case op as LESS() then
            <<less>>
        case op as LESSEQ() then
            <<lesseq>>
        case op as GREATER() then
            <<greater>>
        case op as GREATEREQ() then
            <<greatereq>>
        case op as EQUAL() then
            <<equal>>
        case op as NEQUAL() then
            <<nequal>>
        case op as USERDEFINED() then
            <<userdefined>>
        else
          <<-unknown operator->>
    end match
end dumpOperator;

annotation(__OpenModelica_Interface="backend");
end VisualXMLTpl;
