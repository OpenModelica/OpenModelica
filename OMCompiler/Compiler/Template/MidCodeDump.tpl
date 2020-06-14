package MidCodeDump
"
 Dumps MidCode IR to a human readble format.
"

import interface MidCodeTV;
import interface SimCodeTV;
import DAEDumpTpl;

template dumpProgram(MidCode.Program p)
::=
  match p
  case MidCode.PROGRAM(__) then
  <<
  PROGRAM:
    <% records |> r => dumpRecord(r) ; separator="\n\n"%>
    #<% functions |> fn => dumpFunction(fn) ; separator="\n\n"%>
  >>
  end match
end dumpProgram;

template dumpFunction(MidCode.Function fn)
 "Dumperates the body for a Modelica/MetaModelica function."
::=
  match fn
  case MidCode.FUNCTION(__) then
    let arguments = {
      (inputs |> i => <<<%dumpVarType(i)%> <%dumpVarName(i)%>>> ; separator="\n")
    } ; separator="\n"

    let outputArguments = {
      (List.restOrEmpty(outputs) |> o => <<<%dumpVarType(o)%> <%dumpVarName(o)%>>> ; separator="\n")
    } ; separator="\n"
    <<
    FUNCTION <%underscorePath(name)%>
       INPUTS:
         <%arguments%>
       OUTPUTS:
         <%outputArguments%>
       LOCAL DECLARATIONS:
         <%dumpLocalDecls(fn, locals, localBufs, localBufPtrs)%>
       ENTRY:
         <%dumpEntry(fn)%>
       BASIC BLOCKS:
         <% dumpBlocks(fn,body) %>
       EXIT:
         <%dumpExit(fn)%>
    >>
  end match
end dumpFunction;

template dumpRecord(MidCode.Record r)
::=
    match r
      case MidCode.RECORD_DECLARATION(__) then
        <<
          RECORD_DECLARATION
           <%definitionPath%>
           <%encodedPath%>
           <%fieldNames |> fieldName => fieldName; separator="\n\n"%>
          end RECORD_DECLARATION;
        >>
end dumpRecord;

template dumpLocalDecls(MidCode.Function fn, list<MidCode.Var> locals, list<MidCode.VarBuf> localBufs, list<MidCode.VarBufPtr> localBufPtrs)
::=
  <<
  LOCALS:
    <% locals |> local => dumpLocalDecl(fn,local) ; separator="\n" %>
  LOCAL_BUFS:
    <% localBufs |> local => dumpLocalBufDecl(fn,local) ; separator="\n" %>
  LOCAL_BUF_PTRS:
    <% localBufPtrs |> local => dumpLocalBufPtrDecl(fn,local) ; separator="\n" %>
  >>
end dumpLocalDecls;

template dumpLocalDecl(MidCode.Function fn, MidCode.Var var)
::=
  <<
  <% match var case MidCode.VAR(volatile=true) then "VOLATILE " end match %><% dumpVarType(var) %> <% dumpVarName(var) %>;
  >>
end dumpLocalDecl;

template dumpLocalBufDecl(MidCode.Function fn, MidCode.VarBuf var)
::=
  <<
  VarBuf <% dumpVarBufName(var) %>
  >>
end dumpLocalBufDecl;

template dumpLocalBufPtrDecl(MidCode.Function fn, MidCode.VarBufPtr var)
::=
  <<
  VarBufPtr <% dumpVarBufPtrName(var) %>
  >>
end dumpLocalBufPtrDecl;

template dumpEntry(MidCode.Function fn)
 ""
::=
  match fn
  case FUNCTION(__) then
    <<
    ENTRY <% dumpLabel(entryId) %>
    >>
  end match
end dumpEntry;

template dumpExit(MidCode.Function fn)
 ""
::=
  match fn
  case FUNCTION(__) then
    <<
    <%dumpLabel(exitId) %>%>
    RETURN

    >>
  end match
end dumpExit;

template dumpBlocks(MidCode.Function fn, list<MidCode.Block> body)
 ""
::=
  body |> block => dumpBlock(fn, block) ; separator="\n"
end dumpBlocks;

template dumpBlock(MidCode.Function fn, MidCode.Block block)
 ""
::=
  match block
  case BLOCK(__) then
    <<
    <% dumpLabel(id) %>:
      <% stmts |> stmt => dumpStmt(fn, stmt) ; separator="\n" %>
      <% dumpTerminator(fn, terminator) %>
    >>
  end match
end dumpBlock;

template dumpLabel(Integer i)
::=
  <<
  LABEL: <%i%>
  >>
end dumpLabel;

template dumpVarName(MidCode.Var v)
::=
  match v
    case MidCode.VAR(__) then name
end dumpVarName;

template dumpVarBufName(MidCode.VarBuf v)
::=
  match v
  case MidCode.VARBUF(__) then name
end dumpVarBufName;

template dumpVarBufPtrName(MidCode.VarBufPtr v)
::=
  match v
    case MidCode.VARBUFPTR(__) then name
end dumpVarBufPtrName;

template dumpStmt(MidCode.Function fn, MidCode.Stmt stmt)
 ""
::=
  match stmt
  case MidCode.NOP(__) then
    <<
    NOP
    >>
  case MidCode.ASSIGN(
     dest=MidCode.VAR(name=dest_name,ty=_)
    ,src=rvalue
    ) then
      <<
      <%dest_name%> = <%dumpRValue(rvalue)%>
      >>
  end match
end dumpStmt;

template dumpRValue(MidCode.RValue rvalue)
 ""
::=
  match rvalue
  case MidCode.VARIABLE(src=src as MidCode.VAR(name=src_name, ty=_)) then
    <<
    <%src_name%>
    >>
  case MidCode.BINARYOP(
     op=op
    ,lsrc=lsrc as MidCode.VAR(name=lsrc_name,ty=DAE.T_STRING(__))
    ,rsrc=rsrc as MidCode.VAR(name=rsrc_name,ty=DAE.T_STRING(__))
    ) then
      dumpStringBinaryop(op,lsrc,rsrc)
  case MidCode.BINARYOP(
     op=MidCode.POW()
    ,lsrc=MidCode.VAR(name=lsrc_name, ty=_)
    ,rsrc=MidCode.VAR(name=rsrc_name, ty=_)) then
      <<
      <%lsrc_name%> ^ <%rsrc_name%>
      >>
  case MidCode.BINARYOP(  // c binary ops
     op=op
    ,lsrc=MidCode.VAR(name=lsrc_name, ty=_)
    ,rsrc=MidCode.VAR(name=rsrc_name, ty=_)) then
      <<
      <%lsrc_name%> <%binaryopToString(op)%> <%rsrc_name%>
      >>
  case MidCode.UNARYOP(op=MidCode.BOX(), src=src) then
    varBox(src)
  case MidCode.UNARYOP(op=MidCode.UNBOX(), src=src) then
    varUnbox(src)
  case MidCode.UNARYOP(op=op, src=src) then
    <<
    (<%dumpVarType(src)%>) <%unaryopToString(op)%> <%dumpVarName(src)%>
    >>
  case MidCode.LITERALINTEGER(value=value) then
    <<
    <%value%>
    >>
    case MidCode.LITERALBOOLEAN(value=value) then
    <<
    <%if value then 1 else 0%>
    >>
  case MidCode.LITERALREAL(value=value) then
    <<
    <%value%>
    >>
  case MidCode.LITERALSTRING(value=value) then
    <<
    mmc_mk_scon("<%Util.escapeModelicaStringToCString(value)%>")
    >>
  case MidCode.LITERALMETATYPE(elements=elements,ty=ty) then
    let metatypeSlots = listLength(elements)
    let metatypeCtor = dumpTypeCtorIndex(elements, ty)
    let elementargs = (elements |> element => <<<%dumpVarName(element)%>>> ; separator=", ")

    match ty
    case DAE.T_METARECORD(__) then
      let arguments = {
        (<<<%metatypeSlots%>+1>>),
        (metatypeCtor),
        (<<&<%dumpTypeUnderscorePath(ty)%>__desc>>),
        elementargs
        } ; separator=", "
      <<mmc_mk_box(<%arguments%>)>>
    else
      let arguments = {
        (<<<%metatypeSlots%>>>),
        (metatypeCtor),
        elementargs
        } ; separator=", "
      <<mmc_mk_box(<%arguments%>)>>

  case MidCode.METAFIELD(src=src, index=index, ty=ty) then
    <<MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(<%dumpVarName(src)%>),<%intAdd(index,1)%>))>>
  case MidCode.UNIONTYPEVARIANT() then
    <<(MMC_HDRCTOR(MMC_GETHDR(<%dumpVarName(src)%>)) - 3)>>
  case MidCode.ISSOME(src=src) then
    <<(0==MMC_HDRSLOTS(MMC_GETHDR(<%dumpVarName(src)%>)) ? 0 : 1)>>
  case MidCode.ISCONS(src=src) then
    <<(MMC_GETHDR(<%dumpVarName(src)%>) == MMC_CONSHDR)>>
  else "notimplemented"
  end match
end dumpRValue;

template binaryopToString(MidCode.BinaryOp op)
::=
  match op
  case MidCode.ADD() then "+"
  case MidCode.SUB() then "-"
  case MidCode.MUL() then "*"
  case MidCode.DIV() then "/"
  // pow
  case MidCode.LESS() then "<"
  case MidCode.LESSEQ() then "<="
  case MidCode.GREATER() then ">"
  case MidCode.GREATEREQ() then ">="
  case MidCode.EQUAL() then "=="
  case MidCode.NEQUAL() then "!="
  else "notimplemented"
  end match
end binaryopToString;

template unaryopToString(MidCode.UnaryOp op)
::=
  match op
  case MidCode.MOVE()   then ""
  case MidCode.UMINUS() then "-"
  case MidCode.NOT() then "!"
  else "notimplemented"
  end match
end unaryopToString;

template dumpStringBinaryop(MidCode.BinaryOp op, MidCode.Var lsrc, MidCode.Var rsrc)
::=
  match op
  case MidCode.ADD() then
    <<
    <%dumpVarName(lsrc)%> + <%dumpVarName(rsrc)%>
    >>
  else
    // TODO:
    //   error checking. sub,mul
    //   could optimise equality? CodedumpCFunctions.tpl:5163
    <<
      dumpVarName(lsrc)%> == <%dumpVarName(rsrc)%>
    >>
  end match
end dumpStringBinaryop;


template dumpTerminator(MidCode.Function fn, MidCode.Terminator terminator)
 ""
::=
  match fn case FUNCTION(locals=_,inputs=_,outputs=_,body=_,entryId=_,exitId=exitId) then
    // big match expression I guess
    match terminator
    case MidCode.RETURN() then
      <<
      RETURN:  <% dumpLabel(exitId) %>
      END OF BLOCK
      >>
    case MidCode.GOTO(next=label) then
      <<
      GOTO:  <% dumpLabel(label) %>
      END OF BLOCK
      >>
    case MidCode.BRANCH(condition=condition,onTrue=labelTrue, onFalse=labelFalse) then
      <<
      BRANCH: (<%dumpVarName(condition)%>)
        onTrue <% dumpLabel(labelTrue) %>
        onFalse <% dumpLabel(labelFalse) %>
      END OF BLOCK
      >>
    case MidCode.SWITCH(condition=condition, cases=cases) then
      <<
      SWITCH (<%dumpVarName(condition)%>):
        <% cases |> (from,to) =>
          <<
          CASE <%from%>: <%dumpLabel(to)%>;
          >>
          ; separator="\n" %>
      END OF BLOCK
      >>
    case MidCode.CALL(func=func,builtin=builtin,inputs=inputs,outputs=outputs,next=next) then
      let returnAssignment = match outputs
        case {} then ""
        case MidCode.OUT_WILD() :: _ then ""
        case MidCode.OUT_VAR(var=var) :: _ then <<<%dumpVarName(var)%> = >>

      let arguments = {
        (inputs |> i => dumpVarName(i) ; separator=", "),
        (List.restOrEmpty(outputs) |> o => match o case MidCode.OUT_VAR(var=var) then <<&<%dumpVarName(var)%>>> else "NULL" ; separator=", ")
      } ; separator=",\n    "
      <<
      CALL:
      <%if builtin then "BUILTIN CALL:" %>
        <%returnAssignment%> <%underscorePath(func)%> (<%arguments%>)
      END OF BLOCK
      >>
    case MidCode.LONGJMP() then
      // old codedump does fail-goto substitution here
      // INFO: not allowed to throw to same function
      <<
      LONGJMP()
      END OF BLOCK
      >>
    case MidCode.PUSHJMP(__) then
      <<
      PUSHJMP:
        PUSH<%dumpVarBufPtrName(old_buf)%>
        SET_JMP(dumpVarBufName(new_buf))
      END OF BLOCK
      >>
    case MidCode.POPJMP(__) then
      <<
      POPJMP:
        POP(old_buf)
      END OF BLOCK
      >>
  else "notimplemented"
  end match
end dumpTerminator;

template dumpVarType(Var var)
  "Dumperate the c type for a variable."
::=
  let &attr = buffer ""
  match var case VAR(name=_,ty=ty) then
     DAEDumpTpl.dumpType(ty, &attr)
    end match
end dumpVarType;

template dumpTypeCtorIndex(list<MidCode.Var> elements, DAE.Type ty)
  "Dump the c-tag that indicates which record of a uniontype we have."
::=
  match ty
    case DAE.T_METARECORD(__) then intAdd(index,3)
    case DAE.T_METAARRAY(__) then 2
    case DAE.T_METATUPLE(__) then 0
    case DAE.T_METAOPTION(__) then 1
    case DAE.T_METALIST(__) then (if listLength(elements) then 1 else 0)
   else -100
  end match
end dumpTypeCtorIndex;

template dumpTypeUnderscorePath(DAE.Type ty)
  "dumperate underscored path from type"
::=
  match ty
  case T_METARECORD(path=path)
  then underscorePath(path)
  case T_COMPLEX(complexClassType = RECORD(path = path), varLst = _)
  then underscorePath(path)
  else "error: dumpTypeUnderscorePath"
  end match
end dumpTypeUnderscorePath;

template varBoxType(MidCode.Var var)
::=
  match var case VAR(name=_,ty=ty) then
    match ty
    case T_INTEGER(__)
    case T_ENUMERATION(__)
    case T_BOOL(__)
    case T_REAL(__) then 'VAR_BOX'
    end match
  end match
end varBoxType;

template varBox(MidCode.Var var)
::=
  match var case VAR(name=name,ty=ty) then
    match ty
    case T_INTEGER(__)
    case T_ENUMERATION(__) then 'T_ENUMERATION_BOX(<%name%>)'
    case T_BOOL(__) then 'T_BOOL_BOX(<%name%>)'
    case T_REAL(__) then 'T_REAL_BOX(<%name%>)'
    case T_STRING(__) then 'T_STRING_BOX(<%name%>)'
    case T_COMPLEX(__) then 'T_COMPLEX_BOX(<%name%>)'
    else name
    end match
  end match
end varBox;

template varUnbox(MidCode.Var var)
::=
  match var case VAR(name=name,ty=ty) then
    match ty
    case T_METABOXED(ty=T_INTEGER(__))
    case T_METABOXED(ty=T_ENUMERATION(__))then 'META_UNBOX_INTEGER(<%name%>)'
    case T_METABOXED(ty=T_BOOL(__)) then 'META_UNBOX_INTEGER(<%name%>)'
    case T_METABOXED(ty=T_REAL(__)) then 'META_UNBOX_REAL(<%name%>)'
    case T_STRING(__) then 'mmc_unbox_string(<%name%>)'
    else name
    end match
  end match
end varUnbox;

template varUnbox2(MidCode.Var var)
::=
  match var case VAR(name=name,ty=ty) then
    match ty
    case T_INTEGER(__)
    case T_ENUMERATION(__) then 'UNBOX_INTEGER(<%name%>)'
    case T_BOOL(__) then 'UNBOX_INTEGER(<%name%>)'
    case T_REAL(__) then 'UNBOX_REAL(<%name%>)'
    case T_STRING(__) then 'UNBOX_STRING(<%name%>)'
    else name
    end match
  end match
end varUnbox2;

template varModelicaRead(MidCode.Var var)
::=
  match var case VAR(name=name,ty=ty) then
    match ty
    case T_INTEGER(__) then 'read_modelica_integer(&inArgs, &<%name%>)'
    case T_BOOL(__) then 'read_modelica_integer(&inArgs, &<%name%>)'
    case T_REAL(__) then 'read_modelica_real(&inArgs, &<%name%>)'
    case T_STRING(__) then 'read_modelica_string(&inArgs, &<%name%>)'
    case T_ENUMERATION(__) then 'read_modelica_integer(&inArgs, &<%name%>)'
    case T_COMPLEX(__) then 'read_modelica_metatype(&inArgs, &<%name%>)' //?
    case T_METAUNIONTYPE(__)
    case T_METALIST(__)
    case T_METAARRAY(__)
    case T_METAOPTION(__)
    case T_METATUPLE(__) then 'read_modelica_metatype(&inArgs, &<%name%>)'
    end match
  end match
end varModelicaRead;

template varModelicaWrite(MidCode.Var var)
::=
  match var case VAR(name=name,ty=ty) then
    match ty
    case T_INTEGER(__) then 'write_modelica_integer(outVar, &<%name%>)'
    case T_BOOL(__) then 'write_modelica_integer(outVar, &<%name%>)'
    case T_REAL(__) then 'write_modelica_real(outVar, &<%name%>)'
    case T_STRING(__) then 'write_modelica_string(outVar, &<%name%>)'
    case T_ENUMERATION(__) then 'write_modelica_integer(outVar, &<%name%>)'
    case T_COMPLEX(__) then 'write_modelica_metatype(outVar, &<%name%>)' //?
    case T_METAUNIONTYPE(__)
    case T_METALIST(__)
    case T_METAARRAY(__)
    case T_METAOPTION(__)
    case T_METATUPLE(__) then 'write_modelica_metatype(outVar, &<%name%>)'
    end match
  end match
end varModelicaWrite;

template identName(Absyn.Path path)
::=
  match path
  case Absyn.IDENT(__) then name
end identName;

template replaceDotAndUnderscore(String str)
 "Replace _ with __ and dot in identifiers with _"
::=
  match str
  case name then
    let str_dots = System.stringReplace(name,".", "_")
    let str_underscores = System.stringReplace(str_dots, "_", "__")
    System.unquoteIdentifier(str_underscores)
end replaceDotAndUnderscore;


template underscorePath(Absyn.Path path)
 "Dump paths with components separated by underscores.
  Replaces also the . in identifiers with _.
  The dot might happen for world.gravityAccleration"
::=
  match path
  case Absyn.QUALIFIED(__) then
    '<%replaceDotAndUnderscore(name)%>_<%underscorePath(path)%>'
  case Absyn.IDENT(__) then
    replaceDotAndUnderscore(name)
  case Absyn.FULLYQUALIFIED(__) then
    underscorePath(path)
end underscorePath;

annotation(__OpenModelica_Interface="backend");
end MidCodeDump;
