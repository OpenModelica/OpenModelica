function [dmf,dwice,dpim]=engine_model(W_ice,P_im,U_mf,T_load)

%W_ice engine speed ,[round/sec],                  range  60<W_ice<200
%P_im  intake manifold pressure, [Pa],             range 100e3<P_im<300e3
%U_mf  fuel injection per woking cycle [kg/cycle], range 0<U_mf<260
%T_load load on engine [N.m],                      range 0<T_load<2000  


%constants
I_ice = 3;         
nr = 2;
Q_lhv = 42.9e6;    
n_cyl = 6;
cfr1 = 7.195e-1;
cfr2 = -1.414e-1;
cfr3 = 3.59e-1;
Vd = 12.7e-3;      
Eta_igch = 0.6877;
gamma_cyl = 1.35004;
rc = 17.3;
Eta_ig = Eta_igch*(1-(1/(rc^(gamma_cyl-1))));
c_pim = [-0.328,-121.519,0.057,971791.699];
c_tau = [38.5857,-0.6869];
P_atm = 101574.2;
pi = 3.141; 
%model
T_fric=(Vd*100000/4/pi)*( cfr1*(W_ice*60/2000/pi)^2 + cfr2*(W_ice*60/2000/pi) + cfr3 );
T_ig = U_mf*1e-6*n_cyl*Q_lhv*Eta_ig/(2*pi*nr);
T_ice = (T_ig - T_fric);
pim_model = (c_pim(1).*(W_ice).^2 + c_pim(2).*(T_ice) + c_pim(3)*(T_ice).*(W_ice).^2  + c_pim(4))*1e-1; %[Pa],[rps],[Nm]
pim_model= max(P_atm,pim_model);
tau_model = c_tau(1)*W_ice^(c_tau(2));  
dmf = 1e-6*U_mf*W_ice*n_cyl/4/pi;%dmf mass of fuel, kg

%differential equations for engine states
dwice = (T_ice-T_load)/I_ice;
dpim = (1/tau_model)*(pim_model-P_im);

end