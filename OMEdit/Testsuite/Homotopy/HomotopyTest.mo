package HomotopyTest

  model M1 "Fails at lambda = 0"
    Real x;
  equation
    homotopy(x^2 + 0.1*sin(x) + 1,
             x^2 + 0.2*sin(x) + 1) = 0;
    annotation(__OpenModelica_simulationFlags(lv="LOG_NLS_V"));
  end M1;

  model M2 "Fails at lambda = 0"
    extends M1;
    annotation(__OpenModelica_simulationFlags(lv="LOG_NLS_V,LOG_INIT_HOMOTOPY"));
  end M2;

  model M3 "Fails at lambda = 0"
    extends M1;
    annotation(__OpenModelica_simulationFlags(lv="LOG_NLS_V,LOG_INIT_V"));
  end M3;

  model M4 "Fails at 0 < lambda < 1"
    Real x;
  equation
    homotopy(x^2 + 2*sin(x) + 1,
             2*x + 1) = 0;
    annotation(__OpenModelica_simulationFlags(lv="LOG_NLS_V", ils="10"));
  end M4;

  model M5 "Fails at 0 < lambda < 1"
    extends M4;
    annotation(__OpenModelica_simulationFlags(lv="LOG_NLS_V,LOG_INIT_HOMOTOPY", ils="10"));
  end M5;

  model M6 "Fails at 0 < lambda < 1"
    extends M4;
    annotation(__OpenModelica_simulationFlags(lv="LOG_NLS_V,LOG_INIT_V", ils="10"));
  end M6;

end HomotopyTest;
