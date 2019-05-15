package CodegenMidToC

// import CodegenUtil.*;
import interface MidCodeTV;
import interface SimCodeTV;

/*
maybe do
- make a genGoto that generates empty statement if target is next block
*/

template genProgram(MidCode.Program p)
::=
  match p
  case MidCode.PROGRAM(__) then
  <<
  // number of functions: <% listLength(functions) %>
  #include "<%name%>.h"
  #include "util/modelica.h"

  #include "<%name%>_includes.h"

  <% functions |> fn => genFunction(fn) ; separator="\n\n"%>
  >>
  end match
end genProgram;

/*
template genGlobalDef(Literal lit)
::=
  match lit
  case LITSTRING(var=var,value_=value_) then
    let name = genVarName(var)
    let dataName = <<_OMC_LIT_DATA_<%name%>>> //<<_OMC_LIT<%name%>_data>>
    let structName = <<_OMC_LIT_STRUCT_<%name%>>>//<<_OMC_LIT_STRUCT<%name%>>>
    let escaped = Util.escapeModelicaStringToCString(value_)
    let escapedLength = System.unescapedStringLength(escaped) // =listLength(value_)?
    <<
    #define <%dataName%> "<%escaped%>"
    static const MMC_DEFSTRINGLIT(<%structName%>,<%escapedLength%>,<%dataName%>);
    #define <%name%> MMC_REFSTRINGLIT(<%structName%>)

    >>
  case LITRECORD(var=var,args=args) then
    match var case  MidCode.VAR(name=_,ty =ty as DAE.T_METARECORD(__)) then
      let name = genVarName(var)
      let dataName = <<_OMC_LIT_DATA_<%name%>>>
      let structName = <<_OMC_LIT_STRUCT_<%name%>>>
      <<
      static const MMC_DEFSTRUCTLIT(<%structName%>,<%ty.index%>,<%listLength(args)%>) {<%args |> arg => genVarName(arg) ; separator=","%>}};
      #define <%name%> MMC_REFSTRUCTLIT(<%structName%>)

      >>
    end match
  else "notimplemented"
  end match
end genGlobalDef;
*/

template genFunction(MidCode.Function fn)
 "Generates the body for a Modelica/MetaModelica function."
::=
  /*
  The function should accept a thread_data argument.
  The inputs are normal arguments.
  The first output is the return value of the function.
  The rest of the outputs are passed as pointers to the funtion.
  If there is no output return void?
  */
  match fn
  case MidCode.FUNCTION(__) then
    let returnType = if listEmpty(outputs) then "void" else genVarType(listHead(outputs))

    let arguments = {
      ("threadData_t *threadData"),
      (inputs |> i => <<<%genVarType(i)%> <%genVarName(i)%>>> ; separator=", "),
      (List.restOrEmpty(outputs) |> o => <<<%genVarType(o)%> *outPtr_<%genVarName(o)%>>> ; separator=", ") // TODO: this might not be a great way to pointerify a type
    } ; separator=",\n    "

    <<
    <%returnType%> omc_<%underscorePath(name)%>(<%arguments%>)
    {
       <% genLocalDecls(fn, locals, localBufs, localBufPtrs)%>
       <% genEntry(fn) %>
       <% genBlocks(fn,body) %>
       <% genExit(fn) %>
    }

    <%genInFunction(fn)%>
    <%genBoxPtrFunction(fn)%>

    >>

  end match
end genFunction;

template genInFunction(MidCode.Function fn)
::=
  match fn
  case MidCode.FUNCTION(__) then
    let inputDefs = (inputs |> i => <<<%genVarType(i)%> <%genVarName(i)%>;>>; separator="\n")
    let outputDefs = (outputs |> o => <<<%genVarType(o)%> <%genVarName(o)%>;>>; separator="\n")
    let inputLines = (inputs |> i => <<if(<%varModelicaRead(i)%>) return 1;>>; separator="\n")
    let outputLines = (outputs |> o => <<<%varModelicaWrite(o)%>;>>; separator="\n")
    let callretval = if not listEmpty(outputs) then <<<%genVarName(listHead(outputs))%> = >>
    let callargs = {
      ("threadData"),
      (inputs |> i => <<<%genVarName(i)%>>> ; separator=", "),
      (List.restOrEmpty(outputs) |> o => <<&<%genVarName(o)%>>> ; separator=", ")
    } ; separator=",\n    "
    <<
    int in_<%underscorePath(name)%>(threadData_t *threadData, type_description *inArgs, type_description *outVar)
    {
      <%inputDefs%>
      <%outputDefs%>
      <%inputLines%>
      MMC_TRY_TOP_INTERNAL()
      <%callretval%>omc_<%underscorePath(name)%>(<%callargs%>);
      MMC_CATCH_TOP(return 1)
      <%outputLines%>
      <%if listEmpty(outputs) then "write_noretcall(outVar);"%>
      fflush(NULL);
      return 0;
    }
    >>
  end match
end genInFunction;

template genBoxPtrFunction(MidCode.Function fn)
::=
  match fn
  case MidCode.FUNCTION(__) then
    let returnType = if listEmpty(outputs) then "void" else "modelica_metatype"

    let arguments = {
        ("threadData_t *threadData"),
        (inputs |> i => <<modelica_metatype <%genVarName(i)%>>> ; separator=", "),
        (List.restOrEmpty(outputs) |> o => <<modelica_metatype *out_<%genVarName(o)%>>> ; separator=", ")
      } ; separator=",\n    "

    let unboxDefs = ( inputs |> i =>
      if varBoxType(i) then <<<%genVarType(i)%> unbox_<%genVarName(i)%>;>> ; separator="\n")

    let callOutDefs = ( outputs |> o =>
      if varBoxType(o) then <<<%genVarType(o)%> <%genVarName(o)%>;>> ; separator="\n")

    let boxDefs = if not listEmpty(outputs) then <<modelica_metatype out_<%genVarName(listHead(outputs))%>;<%"\n"%>>>

    let unboxes = ( inputs |> i =>
      if varBoxType(i) then <<unbox_<%genVarName(i)%> = <%varUnbox2(i)%>;>> ; separator="\n")

    let callretval = if not listEmpty(outputs) then <<<%if not varBoxType(listHead(outputs)) then "out_"%><%genVarName(listHead(outputs))%> = >>
    let callvars = {
      ("threadData"),
      (inputs |> i => <<<%if varBoxType(i) then "unbox_"%><%genVarName(i)%>>> ; separator=", "),
      (List.restOrEmpty(outputs) |> o => <<<%if varBoxType(o) then "&" else "out_"%><%genVarName(o)%>>> ; separator=", ")
    } ; separator=",\n    "

    let boxes = {
      (if not listEmpty(outputs) then (if varBoxType(listHead(outputs)) then <<out_<%genVarName(listHead(outputs))%> = <%varBox(listHead(outputs))%>;>>)),
      (List.restOrEmpty(outputs) |> o =>
      if varBoxType(o) then <<if(out_<%genVarName(o)%>) *out_<%genVarName(o)%> = <%varBox(o)%>;>> )
    } ; separator="\n"

    <<
    #undef boxptr_<%underscorePath(name)%>
    <%returnType%> boxptr_<%underscorePath(name)%>(<%arguments%>)
    {
        <%unboxDefs%>
        <%callOutDefs%>
        <%boxDefs%>
        <%unboxes%>
        <%callretval%>omc_<%underscorePath(name)%>(<%callvars%>);
        <%boxes%>
        <% if listEmpty(outputs) then "return;" else "return out_" + genVarName(listHead(outputs)) + ";" %>
    }
    >>
  end match
end genBoxPtrFunction;

template genLocalDecls(MidCode.Function fn, list<MidCode.Var> locals, list<MidCode.VarBuf> localBufs, list<MidCode.VarBufPtr> localBufPtrs)
::=
  <<
  <% locals |> local => genLocalDecl(fn,local) ; separator="\n" %>
  <% localBufs |> local => genLocalBufDecl(fn,local) ; separator="\n" %>
  <% localBufPtrs |> local => genLocalBufPtrDecl(fn,local) ; separator="\n" %>
  >>
end genLocalDecls;

template genLocalDecl(MidCode.Function fn, MidCode.Var var)
::=
  <<
  <% match var case MidCode.VAR(volatile=true) then "volatile " end match %><% genVarType(var) %> <% genVarName(var) %>;
  >>
end genLocalDecl;

template genLocalBufDecl(MidCode.Function fn, MidCode.VarBuf var)
::=
  <<
  jmp_buf <% genVarBufName(var) %>;
  >>
end genLocalBufDecl;

template genLocalBufPtrDecl(MidCode.Function fn, MidCode.VarBufPtr var)
::=
  <<
  jmp_buf *<% genVarBufPtrName(var) %>;
  >>
end genLocalBufPtrDecl;

template genEntry(MidCode.Function fn)
 ""
::=
  match fn
  case FUNCTION(__) then
    <<
    goto <% genLabel(entryId) %>;
    >>
  end match
end genEntry;

template genExit(MidCode.Function fn)
 ""
::=
  match fn
  case FUNCTION(__) then
    let returnString = if listEmpty(outputs) then "" else genVarName(listHead(outputs))
    <<
    <% genLabel(exitId) %>: // exit block
      <% List.restOrEmpty(outputs) |> v =>
        let outPtrName = "outPtr_"+ genVarName(v)
        <<
        if (<%outPtrName%> != NULL)
          *<%outPtrName%> = <%genVarName(v)%>;
        >> ; separator="\n"
      %>
      return <%returnString%>;
    >>
  end match
end genExit;

template genBlocks(MidCode.Function fn, list<MidCode.Block> body)
 ""
::=
  body |> block => genBlock(fn, block) ; separator="\n"
end genBlocks;

template genBlock(MidCode.Function fn, MidCode.Block block)
 ""
::=
  match block
  case BLOCK(__) then
    <<
    <% genLabel(id) %>:
      <% stmts |> stmt => genStmt(fn, stmt) ; separator="\n" %>
      <% genTerminator(fn, terminator) %>
    >>
  end match
end genBlock;

template genLabel(Integer i)
::=
  <<
  label_<% i %>
  >>
end genLabel;

template genVarName(MidCode.Var v)
::=
  match v
  case MidCode.VAR(__)
  then name
end genVarName;

template genVarBufName(MidCode.VarBuf v)
::=
  match v
  case MidCode.VARBUF(__)
  then name
end genVarBufName;

template genVarBufPtrName(MidCode.VarBufPtr v)
::=
  match v
  case MidCode.VARBUFPTR(__)
  then name
end genVarBufPtrName;

template genStmt(MidCode.Function fn, MidCode.Stmt stmt)
 ""
::=
  match stmt
  case MidCode.NOP(__) then
    <<
    ; // NOP
    >>
  case MidCode.ASSIGN(
     dest=MidCode.VAR(name=dest_name,ty=_)
    ,src=rvalue
    ) then
      <<
      <%dest_name%> = <%genRValue(rvalue)%>;
      >>
  end match
end genStmt;

template genRValue(MidCode.RValue rvalue)
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
      genStringBinaryop(op,lsrc,rsrc)
  case MidCode.BINARYOP(
     op=MidCode.POW()
    ,lsrc=MidCode.VAR(name=lsrc_name, ty=_)
    ,rsrc=MidCode.VAR(name=rsrc_name, ty=_)) then
      // TODO: use custom pow for modelica semantics CodegenCFunctions.tpl:4889
      <<
      pow(<%lsrc_name%>, <%rsrc_name%>)
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
    (<%genVarType(src)%>) <%unaryopToString(op)%> <%genVarName(src)%>
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
    let metatypeCtor = genTypeCtorIndex(elements, ty)
    let elementargs = (elements |> element => <<<%genVarName(element)%>>> ; separator=", ")

    match ty
    case DAE.T_METARECORD(__) then
      let arguments = {
        (<<<%metatypeSlots%>+1>>),
        (metatypeCtor),
        (<<&<%genTypeUnderscorePath(ty)%>__desc>>),
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
    <<MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(<%genVarName(src)%>),<%intAdd(index,1)%>))>>
  case MidCode.UNIONTYPEVARIANT() then
    <<(MMC_HDRCTOR(MMC_GETHDR(<%genVarName(src)%>)) - 3)>>
  case MidCode.ISSOME(src=src) then
    <<(0==MMC_HDRSLOTS(MMC_GETHDR(<%genVarName(src)%>)) ? 0 : 1)>>
  case MidCode.ISCONS(src=src) then
    <<(MMC_GETHDR(<%genVarName(src)%>) == MMC_CONSHDR)>>
  else "notimplemented"
  end match
end genRValue;

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

template genStringBinaryop(MidCode.BinaryOp op, MidCode.Var lsrc, MidCode.Var rsrc)
::=
  match op
  case MidCode.ADD() then
    <<
    stringAppend(<%genVarName(lsrc)%>, <%genVarName(rsrc)%>)
    >>
  else
    // TODO:
    //   error checking. sub,mul
    //   could optimise equality? CodegenCFunctions.tpl:5163
    <<
    0 <%binaryopToString(op)%> stringCompare(<%genVarName(lsrc)%>, <%genVarName(rsrc)%>)
    >>
  end match
end genStringBinaryop;


template genTerminator(MidCode.Function fn, MidCode.Terminator terminator)
 ""
::=
  match fn case FUNCTION(locals=_,inputs=_,outputs=_,body=_,entryId=_,exitId=exitId) then
    // big match expression I guess
    match terminator
    case MidCode.RETURN() then
      <<
      goto <% genLabel(exitId) %>; // exit label
      >>
    case MidCode.GOTO(next=label) then
      <<
      goto <% genLabel(label) %>;
      >>
    case MidCode.BRANCH(condition=condition,onTrue=labelTrue, onFalse=labelFalse) then
      <<
      if (<%genVarName(condition)%>)
        goto <% genLabel(labelTrue) %>;
      else
        goto <% genLabel(labelFalse) %>;
      >>
    case MidCode.SWITCH(condition=condition, cases=cases) then
      <<
      switch (<%genVarName(condition)%>){
        <% cases |> (from,to) =>
          <<
          case <%from%>: goto <%genLabel(to)%>;
          >>
          ; separator="\n" %>
      }
      >>
    case MidCode.CALL(func=func,builtin=builtin,inputs=inputs,outputs=outputs,next=next) then
      let returnAssignment = match outputs
        case {} then ""
        case MidCode.OUT_WILD() :: _ then ""
        case MidCode.OUT_VAR(var=var) :: _ then <<<%genVarName(var)%> = >>

      let arguments = {
        (if not builtin then "threadData"),
        (inputs |> i => genVarName(i) ; separator=", "),
        (List.restOrEmpty(outputs) |> o => match o case MidCode.OUT_VAR(var=var) then <<&<%genVarName(var)%>>> else "NULL" ; separator=", ")
      } ; separator=",\n    "

      <<
      <%returnAssignment%><%if not builtin then ("omc_" + underscorePath(func)) else identBuiltinCall(func)%>(<%arguments%>);
      goto <%genLabel(next)%>;
      >>
    /* SimulationRuntime/c/meta/meta_modelica_data.h
    */
    case MidCode.LONGJMP() then
      // old codegen does fail-goto substitution here
      // INFO: not allowed to throw to same function
      <<
      longjmp(*threadData->mmc_jumper,1);
      >>
    case MidCode.PUSHJMP(__) then
      <<
      // PUSHJMP
      <% genVarBufPtrName(old_buf) %> = threadData->mmc_jumper;
      threadData->mmc_jumper = &<% genVarBufName(new_buf) %>;
      setjmp(&<% genVarBufName(new_buf) %>);
      goto <%genLabel(next)%>;
      >>
    case MidCode.POPJMP(__) then
      <<
      // POPJMP
      threadData->mmc_jumper = <% genVarBufPtrName(old_buf) %>;
      goto <%genLabel(next)%>;
      >>
  else "notimplemented"
  end match
end genTerminator;

template genVarType(Var var)
  "Generate the c type for a variable."
::=
  match var case VAR(name=_,ty=ty) then
    match ty
    case DAE.T_INTEGER(__)
    case DAE.T_ENUMERATION(__) then
      "modelica_integer"
    case DAE.T_BOOL(__) then
      "modelica_boolean"
    case DAE.T_REAL(__) then
      "modelica_real"
    case DAE.T_STRING(__) then
      "modelica_string"
    case DAE.T_METABOXED(__)
    case DAE.T_METARECORD(__)
    case DAE.T_METATYPE(__)
    case DAE.T_METAOPTION(__)
    case DAE.T_METAARRAY(__)
    case DAE.T_METATUPLE(__)
    case DAE.T_METAUNIONTYPE(__)
    case DAE.T_METALIST(__) then
      "modelica_metatype"
    case DAE.T_UNKNOWN() then
      "unknown" //TODO: fail?
    case DAE.T_METAPOLYMORPHIC(__) then
      "error_ metapolymorphic"
    case DAE.T_METAUNIONTYPE(__) then
      "error_ metauniontype"
    case DAE.T_ANYTYPE(__) then
      "error_anytype"
    case DAE.T_TUPLE(__) then
      "error_tuple"
    else "notimplemented"
    end match
  end match
end genVarType;

template genTypeCtorIndex(list<MidCode.Var> elements, DAE.Type ty)
  "Generate the c-tag that indicates which record of a uniontype we have."
::=
  match ty

  case DAE.T_METARECORD(__) then intAdd(index,3)
  case DAE.T_METAARRAY(__) then 2
  case DAE.T_METATUPLE(__) then 0
  case DAE.T_METAOPTION(__) then 1
  case DAE.T_METALIST(__) then (if listLength(elements) then 1 else 0)
  else 0
  end match
end genTypeCtorIndex;



template genTypeUnderscorePath(DAE.Type ty)
  "generate underscored path from type"
::=
  //
  match ty
  case T_METARECORD(path=path)
  then underscorePath(path)
  case T_COMPLEX(complexClassType = RECORD(path = path), varLst = _)
  then underscorePath(path)
  else "error: genTypeUnderscorePath"
  end match
end genTypeUnderscorePath;

template varBoxType(MidCode.Var var)
::=
  match var case VAR(name=_,ty=ty) then
    match ty
    case T_INTEGER(__)
    case T_ENUMERATION(__)
    case T_BOOL(__)
    case T_REAL(__) then 'modelica_metatype'
    end match
  end match
end varBoxType;

template varBox(MidCode.Var var)
::=
  match var case VAR(name=name,ty=ty) then
    match ty
    case T_INTEGER(__)
    case T_ENUMERATION(__) then 'mmc_mk_icon(<%name%>)'
    case T_BOOL(__) then 'mmc_mk_icon(<%name%>)'
    case T_REAL(__) then 'mmc_mk_rcon(<%name%>)'
    case T_STRING(__) then 'mmc_mk_string(<%name%>)'
    case T_COMPLEX(__) then 'mmc_mk_box(<%name%>)' //?
    else name
    end match
  end match
end varBox;


//TODO: split into two functions
//non-metaboxed case only necessary for boxptr/in functions
//other should be used for normal code
template varUnbox(MidCode.Var var)
::=
  match var case VAR(name=name,ty=ty) then
    match ty
    case T_METABOXED(ty=T_INTEGER(__))
    case T_METABOXED(ty=T_ENUMERATION(__))then 'mmc_unbox_integer(<%name%>)'
    case T_METABOXED(ty=T_BOOL(__)) then 'mmc_unbox_integer(<%name%>)'
    case T_METABOXED(ty=T_REAL(__)) then 'mmc_unbox_real(<%name%>)'
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
    case T_ENUMERATION(__) then 'mmc_unbox_integer(<%name%>)'
    case T_BOOL(__) then 'mmc_unbox_integer(<%name%>)'
    case T_REAL(__) then 'mmc_unbox_real(<%name%>)'
    case T_STRING(__) then 'mmc_unbox_string(<%name%>)'
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

template identBuiltinCall(Absyn.Path path)
::=
  match path
  case Absyn.IDENT(name="clock") then "mmc_clock"
  case Absyn.IDENT(name="anyString") then "mmc_anyString"
  case Absyn.IDENT(name="fail") then "MMC_THROW_INTERNAL"
  case Absyn.IDENT(name="intMod") then "modelica_mod_integer"
  //TODO: print -> puts(MMC_STRINGDATA(...))
  //TODO: mmc_get_field (usual macro solution)
  //TODO: bitwise operators (could be done in DAEToMid instead)
  //TODO: mod, div, max, min?
  //needs some more advanced expression generation with arguments as input

  case Absyn.IDENT(__) then name

end identBuiltinCall;



/*
  ++++++++++++++++++++++++++++++++++++++++
Copied from
CodegenUtil.tpl

Don't know how to import across directories.
*/

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
 "Generate paths with components separated by underscores.
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


//++++++++++++++++++++++++++++++++++++++++

annotation(__OpenModelica_Interface="backend");
end CodegenMidToC;
