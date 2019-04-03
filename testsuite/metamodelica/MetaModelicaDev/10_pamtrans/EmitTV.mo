interface package EmitTV

package Mcode
type Id = String;

uniontype MBinOp
  record MADD end MADD;

  record MSUB end MSUB;

  record MMULT end MMULT;

  record MDIV end MDIV;

end MBinOp;

uniontype MCondJmp
  record MJNP end MJNP;

  record MJP end MJP;

  record MJN end MJN;

  record MJNZ end MJNZ;

  record MJPZ end MJPZ;

  record MJZ end MJZ;

end MCondJmp;

uniontype MOperand
  record I
    Id id;
  end I;

  record N
    Integer integer;
  end N;

  record T
    Integer integer;
  end T;

  record L
    Integer datatype;
  end L;

end MOperand;

uniontype MCode
  record MB
    MBinOp mBinOp;
    MOperand binary;
  end MB;

  record MJ
    MCondJmp mCondJmp;
    MOperand conditional;
  end MJ;

  record MJMP
    MOperand mOperand;
  end MJMP;

  record MLOAD
    MOperand mOperand;
  end MLOAD;

  record MSTO
    MOperand mOperand;
  end MSTO;

  record MGET
    MOperand mOperand;
  end MGET;

  record MPUT
    MOperand mOperand;
  end MPUT;

  record MLABEL
    MOperand mOperand;
  end MLABEL;

  record MHALT end MHALT;

end MCode;
end Mcode;
end EmitTV;
