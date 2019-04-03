package Emit

import interface EmitTV;

template emitAssembly(list<MCode> lst) "Print out the MCode in textual assembly format
  Note: this is not really part of the specification of PAM semantics
"
::=
  lst |> instruction => emitInstr(instruction)
end emitAssembly;

template emitInstr(MCode code) "Print an MCode instruction"
  ::= match code
    case Mcode.MB(__)
      then emitOpOperand(mbinopToStr(mBinOp), binary)
    case Mcode.MJ(__)
      then emitOpOperand(mjmpopToStr(mCondJmp), conditional)
    case Mcode.MJMP(__)
      then emitOpOperand("J", mOperand)
    case Mcode.MLOAD(__)
      then emitOpOperand("LOAD", mOperand)
    case Mcode.MSTO(__)
      then emitOpOperand("STO", mOperand)
    case Mcode.MGET(__)
      then emitOpOperand("GET", mOperand)
    case Mcode.MPUT(__)
      then emitOpOperand("PUT", mOperand)
    case Mcode.MLABEL(__)
      then '<%emitMoperand(mOperand)%><%\t%>LAB<%\n%>'
    case Mcode.MHALT()
      then '<%\t%>HALT<%\n%>'
end emitInstr;

template emitOpOperand(String opstr, MOperand op)
::=
  '<%\t%><%opstr%><%\t%><%emitMoperand(op)%><%\n%>'
end emitOpOperand;

template emitMoperand(MOperand op)
  ::=
  match op
    case Mcode.I(__) then id
    case Mcode.N(__) then integer
    case Mcode.L(__) then 'L<%datatype%>'
    case Mcode.T(__) then 'T<%integer%>'
end emitMoperand;

template mbinopToStr(MBinOp op)
 ::= match op
    case Mcode.MADD(__) then "ADD"
    case Mcode.MSUB(__) then "SUB"
    case Mcode.MMULT(__) then "MULT"
    case Mcode.MDIV(__) then "DIV"
end mbinopToStr;

template mjmpopToStr(MCondJmp jmp)
 ::= match jmp
    case Mcode.MJNP(__) then "JNP"
    case Mcode.MJP(__) then "JP"
    case Mcode.MJN(__) then "JN"
    case Mcode.MJNZ(__) then "JNZ"
    case Mcode.MJPZ(__) then "JPZ"
    case Mcode.MJZ(__) then "JZ"
end mjmpopToStr;

end Emit;
