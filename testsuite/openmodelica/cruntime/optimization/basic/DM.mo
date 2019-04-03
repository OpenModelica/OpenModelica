optimization diesel_model (objective = cost1,
       objectiveIntegrand = cost2)

//see: Martin Sivertsson and Lars Eriksson Optimal power response of a diesel-electric powertrain.
//Submitted to ECOSM’12, Paris, France, 2012.

/*output */
output Real cost1 = (w_ice - 0.515309170685596)^2
                      + (p_im - 0.547055854225991)^2
                      + (p_em - 0.381048005791294)^2
                      + (w_tc - 0.271443000537680)^2;
output Real cost2 =dot_m_f;
/* States in the diesel engine model
-----------------------------------------------------------------------------*/
Real w_ice(start=2.4989941562646081e-01, min = 4/state_norm1, max =220/state_norm1, fixed=true);
Real p_im(start=5.0614999999999999e-01, min = 0.8*p_amb/state_norm2, max=2*p_amb/state_norm2, fixed=true);
Real p_em(start=3.3926666666666666e-01, min = p_amb/state_norm3, max=3*p_amb/state_norm3, fixed=true);
Real w_tc(start=6.8099999999999994e-02, min = 300/state_norm4, max=10000/state_norm4, fixed=true);

/* Control inputs
-----------------------------------------------------------------------------*/
input Real u_f(start=0.5, min=0.0, max = 250/control_norm1);
input Real u_wg(start=0.5, min=0.0, max = 1.0);

/* Constants
-----------------------------------------------------------------------------*/
protected
  constant Real pi = 3.141592653589793;
  constant Real p_amb = 1.0111134146341463e+005;
  constant Real T_amb = 2.9846362195121958e+002;
  constant Real gamma_a = 1.3964088397790055e+000;
  constant Real R_a = 2.8700000000000000e+002;
  constant Real cp_a = 1.0110000000000000e+003;
  constant Real cv_a = 7.2400000000000000e+002;
  constant Real p_es = 1.0111134146341463e+005;
  constant Real gamma_e = 1.2734225621414914e+000;
  constant Real R_e = 2.8600000000000000e+002;
  constant Real cp_e = 1.3320000000000000e+003;
  constant Real Hlhv = 4.2900000000000000e+007;
  constant Real AFs = 1.4570000000000000e+001;
  constant Real gamma_cyl = 1.3500000000000001e+000;
  constant Real T_im = 3.0061857317073162e+002;
  constant Real x_r0 = 0.0000000000000000e+000;
  constant Real T_10 = 3.0064178823529403e+002;
  constant Real n_cyl = 6.0000000000000000e+000;
  constant Real V_D = 1.2699999999999999e-002;
  constant Real r_c = 1.7300000000000001e+001;
  constant Real A_wg_eff = 8.8357293382212933e-004;
  constant Real J_genset = 3.5000000000000000e+000;
  constant Real d_pipe = 1.0000000000000001e-001;
  constant Real n_pipe = 2.0000000000000000e+000;
  constant Real l_pipe = 1.0000000000000000e+000;
  constant Real R_c = 4.0000000000000001e-002;
  constant Real V_is = 2.1302555405064521e-002;
  constant Real V_em = 2.0024706650635410e-002;
  constant Real R_t = 4.0000000000000001e-002;
  constant Real J_tc = 1.9777955929704147e-004;
  constant Real state_norm1 = 2.2000000000000000e+002;
  constant Real state_norm2 = 2.0000000000000000e+005;
  constant Real state_norm3 = 3.0000000000000000e+005;
  constant Real state_norm4 = 1.0000000000000000e+004;
  constant Real control_norm1 = 2.5000000000000000e+002;
  constant Real control_norm2 = 1.0000000000000000e+000;
  constant Real control_norm3 = 2.5400000000000000e+005;
  constant Real Psi_max = 1.4374756793329366e+000;
  constant Real dot_m_c_corr_max = 5.2690636559024850e-001;
  constant Real eta_igch = 6.8768988621327665e-001;
  constant Real c_fr1 = 7.1957840228405290e-001;
  constant Real c_fr2 = -1.4144357053459333e-001;
  constant Real c_fr3 = 3.5904197283929118e-001;
  constant Real eta_sc = 1.0515746242284574e+000;
  constant Real x_cv = 5.7966369236798054e-001;
  constant Real A_t_eff = 9.9877716035454514e-004;
  constant Real eta_c = 5.2227332577901808e-001;
  constant Real eta_t = 6.8522930965034778e-001;
  constant Real eta_vol = 8.9059680994120261e-001;
  constant Real w_fric = 2.4723010996875069e-005;

/* States and controls
-----------------------------------------------------------------------------*/
protected
  Real W_ICE;
  Real P_IM;
  Real P_EM;
  Real W_TC;
  Real U_F;

/* Compressor Massflow
-----------------------------------------------------------------------------*/
  Real Pi_c;
  Real w_tc_corr;
  Real Pi_c_max;
  Real Cm_temp; //must be greater than 0
  Real dot_m_c;
  Real P_c;

/* Cylinder Airflow
-----------------------------------------------------------------------------*/
  Real dot_m_ci;

/* Cylinder Fuelflow
-----------------------------------------------------------------------------*/
  Real dot_m_f;

/* Cylinder Torque
-----------------------------------------------------------------------------*/
  Real eta_ig;
  Real T_pump;
  Real T_ig;
  Real T_fric;
  Real T_ice;

/* Cylinder Temperature Out
-----------------------------------------------------------------------------*/
  Real Pi_e;
  Real q_in;
  Real x_p;
  Real T_eo;

/* Turbine Massflow
-----------------------------------------------------------------------------*/
  Real Pi_t;
  Real Pi_ts_low;
  Real Pi_ts;
  Real Psi_t;
  Real dot_m_t;

/* Turbine Power
-----------------------------------------------------------------------------*/
  Real P_t;

  /* Wastegate Massflow
-----------------------------------------------------------------------------*/
  Real Pi_wg;
  Real Pi_wgs;
  Real Psi_wg;
  Real dot_m_wg;
  Real P_ICE;

equation
  W_ICE = state_norm1*w_ice;
  P_IM = state_norm2*p_im;
  P_EM = state_norm3*p_em;
  W_TC = state_norm4*w_tc;
  U_F = control_norm1*u_f;

  // Compressor Massflow----
  Pi_c = P_IM/p_amb;
  w_tc_corr = state_norm4*w_tc/sqrt(T_amb/T_amb);
  Pi_c_max = (((((w_tc_corr^2)*(R_c^2)*Psi_max)/((2*cp_a*T_amb)))+1)^(gamma_a/(gamma_a-1)));
  Cm_temp = 1-((Pi_c/Pi_c_max)^2); ////Måste vara större en 0
  dot_m_c = (dot_m_c_corr_max*sqrt(Cm_temp))*(p_amb/p_amb)/sqrt(T_amb/T_amb);
  P_c = dot_m_c*cp_a*T_amb*((Pi_c^((gamma_a-1)/gamma_a))-1)/eta_c;

  // Cylinder Airflow------------------------
  dot_m_ci = eta_vol*P_IM*W_ICE*V_D/(4*pi*R_a*T_im);

  // Cylinder Fuelflow---------------------------
  dot_m_f = U_F*W_ICE*n_cyl*(1e-6)/(4*pi);

  // Cylinder Torque---------------------------
  eta_ig = eta_igch*(1-(1/(r_c^(gamma_cyl-1))));
  T_pump = V_D*(P_EM-P_IM);
  T_ig = n_cyl*Hlhv*eta_ig*u_f*control_norm1*(1e-6);
  T_fric = V_D*(10^5)*(c_fr1*((W_ICE*60/(2*pi*1000))^2)+c_fr2*(W_ICE*60/(2*pi*1000))+c_fr3);
  T_ice = (T_ig-T_fric-T_pump)/(4*pi);

  // Cylinder Temperature Out---------------------------
  Pi_e = P_EM/P_IM;
  q_in = dot_m_f*Hlhv/(dot_m_f+dot_m_ci);
  x_p = 1+q_in*x_cv/(cv_a*T_im*(r_c^(gamma_a-1)));
  T_eo = eta_sc*(Pi_e^(1-1/gamma_a))*(r_c^(1-gamma_a))*(x_p^(1/gamma_a-1))*(q_in*((1-x_cv)/cp_a+x_cv/cv_a)+T_im*(r_c^(gamma_a-1)));

  // Turbine Massflow-------
  Pi_t = p_es/P_EM;
  Pi_ts_low = ((2/(gamma_e+1))^(gamma_e/(gamma_e-1)));
  Pi_ts = sqrt(Pi_t);
  Psi_t = sqrt((2*gamma_e/(gamma_e-1))*((Pi_ts^(2/gamma_e))-(Pi_ts^((gamma_e+1)/gamma_e))));
  dot_m_t = P_EM*Psi_t*A_t_eff/(sqrt(T_eo*R_e));

  // Turbine Power--------
  P_t = dot_m_t*cp_e*T_eo*eta_t*(1-(Pi_t^((gamma_e-1)/gamma_e)));

  // Wastegate Massflow-------------------------------------
  Pi_wg = p_amb/P_EM;
  Pi_wgs = Pi_wg;
  Psi_wg = sqrt(2*gamma_e/(gamma_e-1)*((Pi_wgs^(2/gamma_e))-(Pi_wgs^((gamma_e+1)/gamma_e))));
  dot_m_wg = P_EM*Psi_wg*A_wg_eff*u_wg/(sqrt(T_eo*R_e));

  // Limit equations---------------------------
  P_ICE = T_ice*W_ICE/control_norm3;

  // DIFFERENTIAL EQUATION---------------------
  der(w_ice) = 0.0012987012987013*(T_ice);
  der(p_im) = 20.2505119361145*((0.526906365590249*sqrt(Cm_temp))-dot_m_ci);
  der(p_em) = 0.0476078551344513*(T_eo*(dot_m_ci+dot_m_f-dot_m_t-dot_m_wg));
  der(w_tc) = 0.0001*((P_t-P_c)/(0.000197779559297041*W_TC)-2.47230109968751E-005*W_TC*W_TC);

end diesel_model;
