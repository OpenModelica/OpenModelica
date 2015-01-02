optimization opt_diesel_model (objective = cost1,
       objectiveIntegrand = cost2)

extends  diesel_model;

/*output */
Real cost1 = (w_ice - 0.515309170685596)^2
                      + (p_im - 0.547055854225991)^2
                      + (p_em - 0.381048005791294)^2
                      + (w_tc - 0.271443000537680)^2;
Real cost2 =dot_m_f;

end opt_diesel_model;
