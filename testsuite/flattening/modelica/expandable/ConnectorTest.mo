package ConnectorTest
  expandable connector A
    Real ax;
  end A;

  expandable connector B
    Real bx[2];
  end B;

  model Bsource
    output B bout;
    Real genx[2](each start = 1.0);
  equation
    connect(genx,bout.bx);
    genx[1] = sin(time);
    genx[2] = genx[1]*genx[1];
  end Bsource;

  model Busage
    input B bin;
    Real bx[2],bx2[2];
  equation
    connect(bx,bin.bx);
    bx2[1] = 2.0 * bx[1];
    bx2[2] = 3.0 * bx[2];
  end Busage;

  model Asource
    output A aout;
    Real ax;
  equation
    connect(ax,aout.ax);
    ax = cos(time);
  end Asource;

  model Ausage
    input A ain;
    Real ax,ax2;
  equation
    connect(ain.ax,ax);
    ax2 = 2.0 * ax;
  end Ausage;

  model Test
    Bsource Bs;
    Busage  Bu;
    Asource As;
    Ausage  Au;
    B       Bcon;
  equation
    connect(Bs.bout,Bcon);
    connect(As.aout,Bcon);
    connect(Bcon,Bu.bin);
    connect(Bcon,Au.ain);
  end Test;
end ConnectorTest;
