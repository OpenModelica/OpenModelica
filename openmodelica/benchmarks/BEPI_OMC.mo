package BEPI_OMC
  import Modelica.SIunits.*;
  import Modelica.Constants.*;
  import SI = Modelica.SIunits;
  import CONST = Modelica.Constants;

  package Units "Units defined for the development of library models"
    type ComprimibilityCoeff = Real(final quantity = "ComprimibilityCoeff", final unit = "kg/J");
    type ThermalExpansionCoeff = Real(final quantity = "ThermalExpansionCoeff", final unit = "kg/(K.m3)");
    type FrictionCoeff = Real(final quantity = "FrictionCoeff", final unit = "Pa.s/m");
    type ForcePerVolume = Real(final quantity = "ForcePerVolume", final unit = "N/m3");
    type Method = enumeration(Diff, FV, FVpatankar , FVbook ) "Method employed for the discretisation";
    type IntScheme = enumeration(Upwind, CD, Hybrid, PowerLaw , QUICK ) "Method employed for the integration of terms";
    type Face = enumeration(left, right, front, rear, top , bottom ) "face of the volume/room";
  end Units;

  // Parameterized models for easy testing.
  model Room2D_3x3 = Room2D(I = 3, K = 3);
  model Room2D_5x5 = Room2D(I = 5, K = 5);
  model Room2D_10x10 = Room2D(I = 10, K = 10);

  model Room2D
    parameter Distance roomWidth = 3 "|Geometry| width of the room";
    parameter Distance roomHeight = 2.5 "|Geometry| height of the room";
    parameter Distance roomBase = 3 "|Geometry| base of the room";
    parameter Integer I "|Grid| number of volumes along x-direction";
    parameter Integer J = 1 "|Grid| Number of volumes along y-direction FIXED";
    parameter Integer K "|Grid| number of volumes along z-direction";
    parameter Distance X_frac[I] = 1 / I * ones(I) "|Grid| fraction of base assigned to each volume (the sum must be one)";
    parameter Distance Y_frac[J] = ones(J) "|Grid| fraction along y FIXED TO BE 1";
    parameter Distance Z_frac[K] = 1 / K * ones(K) "|Grid| fraction of width assigned to each volume (the sum must be one)";
    parameter Temperature Tstart = 273.15 + 20 "|Initial conditions| air initial temperature";
    parameter DynamicViscosity mu = 0.0000183 "|Air properties| air viscosity within laminar framework";
    parameter Real Kturb = 0.03874 "|Air properties| Coefficient of th eturbulence model";
    parameter String lengthWall = "Xu" "|Air properties| Method for the wall distance";
    parameter ThermalConductivity gamma = 0.026 "|Air properties| air thermal conductivity";
    parameter Temperature Twall_left = 273.15 + 12 "|Boundaries| Temperature of left wall";
    parameter Temperature Twall_right = 273.15 + 28 "|Boundaries| Temperature of right wall";
    parameter Temperature Twall_cei = 273.15 + 15 "|Boundaries| Ceiling temperature";
    parameter Temperature Twall_floor = 273.15 + 18 "|Boundaries| Floor temperature";
    parameter Distance Dturb = 1 "Distance for turbulence model";
    Mass Mtot "mass of air contained within the room";
    Energy Etot "Energy contained within the room";
    Power FluxLeft;
    Power FluxRight;
    Power FluxFloor;
    Power FluxCeiling;
    Temperature T[I + 2,J,K + 2](each start = Tstart);
    Density rho[I + 2,J,K + 2](each stateSelect = StateSelect.always);
    Velocity Vx[I + 1,J,K + 2](each start = 0);
    Velocity Vz[I + 2,J,K + 1](each start = 0);
    Pressure P[I,J,K];
    Mass m[I,J,K];
    SpecificEnergy e[I,J,K];
    DynamicViscosity MUx[I + 1,J,K + 2](each start = mu);
    DynamicViscosity MUz[I + 2,J,K + 1](each start = mu);
    /////////////////////////////////////////////////////////////////
    // convective heat transfer
    parameter CoefficientOfHeatTransfer h_left = 4 "convetive heat transfer";
    parameter CoefficientOfHeatTransfer h_right = 4 "convetive heat transfer";
    parameter CoefficientOfHeatTransfer h_cei = 4 "convetive heat transfer";
    parameter CoefficientOfHeatTransfer h_floor = 4 "convetive heat transfer";
  protected
    Real De_M[I,J,K];
    Real Dw_M[I,J,K];
    Real Ds_M[I,J,K];
    Real Dn_M[I,J,K];
    Real Pe_M[I,J,K];
    Real Pw_M[I,J,K];
    Real Ps_M[I,J,K];
    Real Pn_M[I,J,K];
    Real Fe_M[I,J,K];
    Real Fw_M[I,J,K];
    Real Fs_M[I,J,K];
    Real Fn_M[I,J,K];
    Real aE_M[I,J,K];
    Real aW_M[I,J,K];
    Real aS_M[I,J,K];
    Real aN_M[I,J,K];
    Real aP_M[I,J,K];
    ///////////////////////////////////////
    // quantities for computing momentum X
    Real De_x[I + 1,J,K + 2];
    Real Dw_x[I + 1,J,K + 2];
    Real Ds_x[I + 1,J,K + 2];
    Real Dn_x[I + 1,J,K + 2];
    Real Pe_x[I + 1,J,K + 2];
    Real Pw_x[I + 1,J,K + 2];
    Real Ps_x[I + 1,J,K + 2];
    Real Pn_x[I + 1,J,K + 2];
    Real Fe_x[I + 1,J,K + 2];
    Real Fw_x[I + 1,J,K + 2];
    Real Fs_x[I + 1,J,K + 2];
    Real Fn_x[I + 1,J,K + 2];
    Real aE_x[I + 1,J,K + 2];
    Real aW_x[I + 1,J,K + 2];
    Real aS_x[I + 1,J,K + 2];
    Real aN_x[I + 1,J,K + 2];
    Real aP_x[I + 1,J,K + 2];
    ///////////////////////////////////////
    ///////////////////////////////////////
    // quantities for computing momentum Z
    Real De_z[I + 2,J,K + 1];
    Real Dw_z[I + 2,J,K + 1];
    Real Ds_z[I + 2,J,K + 1];
    Real Dn_z[I + 2,J,K + 1];
    Real Pe_z[I + 2,J,K + 1];
    Real Pw_z[I + 2,J,K + 1];
    Real Ps_z[I + 2,J,K + 1];
    Real Pn_z[I + 2,J,K + 1];
    Real Fe_z[I + 2,J,K + 1];
    Real Fw_z[I + 2,J,K + 1];
    Real Fs_z[I + 2,J,K + 1];
    Real Fn_z[I + 2,J,K + 1];
    Real aE_z[I + 2,J,K + 1];
    Real aW_z[I + 2,J,K + 1];
    Real aS_z[I + 2,J,K + 1];
    Real aN_z[I + 2,J,K + 1];
    Real aP_z[I + 2,J,K + 1];
    ////////////////////////////////////////
    parameter Acceleration g = CONST.g_n "constant gravity acceleration";
    parameter Units.ComprimibilityCoeff ComprCoeff = 1 / (R * To) "air comprimibility coefficient";
    parameter Units.ThermalExpansionCoeff ThermalExpCoeff = Po / (R * To ^ 2) "air thermal expansion coefficient";
    parameter Density rho_o = Po / (R * To) "Density initial value";
    parameter SpecificHeatCapacity R = (CONST.R * 1000) / 28.97 "ideal gases constant specific for air";
    parameter SpecificHeatCapacity cv = 1006 "air specific heat at constant volume";
    parameter Pressure Po = 101325 "Pressure linearization value" annotation(displayUnit = "Pa");
    parameter Temperature To = 298.15 "Temperature linearization value";
    parameter Length height[I,J,K] = Functions.CubeHeights2d(I, K, dz[:]) "height above the floor of each volume";
    parameter Distance dy = roomWidth "width along y-direction FIXED";
    parameter Distance dx[I] = roomBase * X_frac[:];
    parameter Distance dz[K] = roomHeight * Z_frac[:];
    parameter Distance dzx[K + 1] = Functions.Dzx(K, dz[:]) "distance between x-velocity along z direction";
    parameter Distance dxz[I + 1] = Functions.Dxz(I, dx[:]) "distance between z-velocity along x direction";
    parameter Distance y_left = dx[1] / 2 "distance for the boundary layer (left)";
    parameter Distance y_right = dx[I] / 2 "distance for the boundary layer (right)";
    parameter Distance y_floor = dz[1] / 2 "distance for the boundary layer (floor)";
    parameter Distance y_cei = dz[K] / 2 "distance for the boundary layer (ceiling)";
  initial equation
    for i in 2:I + 1 loop
    for k in 2:K + 1 loop
    rho[i,J,k] = rho_o + ComprCoeff * rho[i,J,k] * g * height[i - 1,J,k - 1] - ThermalExpCoeff * (Tstart - To);
    P[i - 1,J,k - 1] = rho[i,J,k] * g * height[i - 1,J,k - 1];

    end for;

    end for;
    for i in 2:I - 1 loop
    for k in 2:K + 1 loop
    Vx[i,J,k] = 0;

    end for;

    end for;
    for i in 2:I + 1 loop
    for k in 2:K - 1 loop
    Vz[i,J,k] = 0;

    end for;

    end for;
  equation
    FluxLeft = sum(Dw_M[1,J,k] * (T[1,J,k + 1] - T[2,J,k + 1]) for k in 1:K);
    FluxRight = sum(De_M[I,J,k] * (T[I + 2,J,k + 1] - T[I + 1,J,k + 1]) for k in 1:K);
    FluxFloor = sum(Ds_M[i,J,1] * (T[i + 1,J,1] - T[i + 1,J,2]) for i in 1:I);
    FluxCeiling = sum(Dn_M[i,J,K] * (T[i + 1,J,K + 2] - T[i + 1,J,K + 1]) for i in 1:I);
    Mtot = sum(m);
    Etot = sum(sum(sum(m[i,j,k] * e[i,j,k] for i in 1:I) for j in 1:J) for k in 1:K);
    for k in 1:K loop
    Vx[1,J,k + 1] = 0;
    Vx[I + 1,J,k + 1] = 0;
    De_x[1,J,k + 1] = 0;
    Dw_x[1,J,k + 1] = 0;
    Ds_x[1,J,k + 1] = 0;
    Dn_x[1,J,k + 1] = 0;
    Pe_x[1,J,k + 1] = 0;
    Pw_x[1,J,k + 1] = 0;
    Ps_x[1,J,k + 1] = 0;
    Pn_x[1,J,k + 1] = 0;
    Fe_x[1,J,k + 1] = 0;
    Fw_x[1,J,k + 1] = 0;
    Fs_x[1,J,k + 1] = 0;
    Fn_x[1,J,k + 1] = 0;
    aE_x[1,J,k + 1] = 0;
    aW_x[1,J,k + 1] = 0;
    aN_x[1,J,k + 1] = 0;
    aS_x[1,J,k + 1] = 0;
    aP_x[1,J,k + 1] = 0;
    De_x[I + 1,J,k + 1] = 0;
    Dw_x[I + 1,J,k + 1] = 0;
    Ds_x[I + 1,J,k + 1] = 0;
    Dn_x[I + 1,J,k + 1] = 0;
    Pe_x[I + 1,J,k + 1] = 0;
    Pw_x[I + 1,J,k + 1] = 0;
    Ps_x[I + 1,J,k + 1] = 0;
    Pn_x[I + 1,J,k + 1] = 0;
    Fe_x[I + 1,J,k + 1] = 0;
    Fw_x[I + 1,J,k + 1] = 0;
    Fs_x[I + 1,J,k + 1] = 0;
    Fn_x[I + 1,J,k + 1] = 0;
    aE_x[I + 1,J,k + 1] = 0;
    aW_x[I + 1,J,k + 1] = 0;
    aS_x[I + 1,J,k + 1] = 0;
    aN_x[I + 1,J,k + 1] = 0;
    aP_x[I + 1,J,k + 1] = 0;

    end for;
    for i in 1:I loop
    Vz[i + 1,J,1] = 0;
    Vz[i + 1,J,K + 1] = 0;
    De_z[i + 1,J,1] = 0;
    Dw_z[i + 1,J,1] = 0;
    Ds_z[i + 1,J,1] = 0;
    Dn_z[i + 1,J,1] = 0;
    Pe_z[i + 1,J,1] = 0;
    Pw_z[i + 1,J,1] = 0;
    Ps_z[i + 1,J,1] = 0;
    Pn_z[i + 1,J,1] = 0;
    Fe_z[i + 1,J,1] = 0;
    Fw_z[i + 1,J,1] = 0;
    Fs_z[i + 1,J,1] = 0;
    Fn_z[i + 1,J,1] = 0;
    aE_z[i + 1,J,1] = 0;
    aW_z[i + 1,J,1] = 0;
    aS_z[i + 1,J,1] = 0;
    aN_z[i + 1,J,1] = 0;
    aP_z[i + 1,J,1] = 0;
    De_z[i + 1,J,K + 1] = 0;
    Dw_z[i + 1,J,K + 1] = 0;
    Ds_z[i + 1,J,K + 1] = 0;
    Dn_z[i + 1,J,K + 1] = 0;
    Pe_z[i + 1,J,K + 1] = 0;
    Pw_z[i + 1,J,K + 1] = 0;
    Ps_z[i + 1,J,K + 1] = 0;
    Pn_z[i + 1,J,K + 1] = 0;
    Fe_z[i + 1,J,K + 1] = 0;
    Fw_z[i + 1,J,K + 1] = 0;
    Fs_z[i + 1,J,K + 1] = 0;
    Fn_z[i + 1,J,K + 1] = 0;
    aE_z[i + 1,J,K + 1] = 0;
    aW_z[i + 1,J,K + 1] = 0;
    aS_z[i + 1,J,K + 1] = 0;
    aN_z[i + 1,J,K + 1] = 0;
    aP_z[i + 1,J,K + 1] = 0;

    end for;
    for k in 1:K + 1 loop
    Vz[1,J,k] = 0;
    Vz[I + 2,J,k] = 0;
    De_z[1,J,k] = 0;
    Dw_z[1,J,k] = 0;
    Ds_z[1,J,k] = 0;
    Dn_z[1,J,k] = 0;
    Pe_z[1,J,k] = 0;
    Pw_z[1,J,k] = 0;
    Ps_z[1,J,k] = 0;
    Pn_z[1,J,k] = 0;
    Fe_z[1,J,k] = 0;
    Fw_z[1,J,k] = 0;
    Fs_z[1,J,k] = 0;
    Fn_z[1,J,k] = 0;
    aE_z[1,J,k] = 0;
    aW_z[1,J,k] = 0;
    aS_z[1,J,k] = 0;
    aN_z[1,J,k] = 0;
    aP_z[1,J,k] = 0;
    De_z[I + 2,J,k] = 0;
    Dw_z[I + 2,J,k] = 0;
    Ds_z[I + 2,J,k] = 0;
    Dn_z[I + 2,J,k] = 0;
    Pe_z[I + 2,J,k] = 0;
    Pw_z[I + 2,J,k] = 0;
    Ps_z[I + 2,J,k] = 0;
    Pn_z[I + 2,J,k] = 0;
    Fe_z[I + 2,J,k] = 0;
    Fw_z[I + 2,J,k] = 0;
    Fs_z[I + 2,J,k] = 0;
    Fn_z[I + 2,J,k] = 0;
    aE_z[I + 2,J,k] = 0;
    aW_z[I + 2,J,k] = 0;
    aS_z[I + 2,J,k] = 0;
    aN_z[I + 2,J,k] = 0;
    aP_z[I + 2,J,k] = 0;

    end for;
    for i in 1:I + 1 loop
    Vx[i,J,1] = 0;
    Vx[i,J,K + 2] = 0;
    De_x[i,J,1] = 0;
    Dw_x[i,J,1] = 0;
    Ds_x[i,J,1] = 0;
    Dn_x[i,J,1] = 0;
    Pe_x[i,J,1] = 0;
    Pw_x[i,J,1] = 0;
    Ps_x[i,J,1] = 0;
    Pn_x[i,J,1] = 0;
    Fe_x[i,J,1] = 0;
    Fw_x[i,J,1] = 0;
    Fs_x[i,J,1] = 0;
    Fn_x[i,J,1] = 0;
    aE_x[i,J,1] = 0;
    aW_x[i,J,1] = 0;
    aS_x[i,J,1] = 0;
    aN_x[i,J,1] = 0;
    aP_x[i,J,1] = 0;
    De_x[i,J,K + 2] = 0;
    Dw_x[i,J,K + 2] = 0;
    Ds_x[i,J,K + 2] = 0;
    Dn_x[i,J,K + 2] = 0;
    Pe_x[i,J,K + 2] = 0;
    Pw_x[i,J,K + 2] = 0;
    Ps_x[i,J,K + 2] = 0;
    Pn_x[i,J,K + 2] = 0;
    Fe_x[i,J,K + 2] = 0;
    Fw_x[i,J,K + 2] = 0;
    Fs_x[i,J,K + 2] = 0;
    Fn_x[i,J,K + 2] = 0;
    aE_x[i,J,K + 2] = 0;
    aW_x[i,J,K + 2] = 0;
    aS_x[i,J,K + 2] = 0;
    aN_x[i,J,K + 2] = 0;
    aP_x[i,J,K + 2] = 0;

    end for;
    T[1,J,1] = 0;
    T[I + 2,J,1] = 0;
    T[1,J,K + 2] = 0;
    T[I + 2,J,K + 2] = 0;
    rho[1,J,1] = 0;
    rho[I + 2,J,1] = 0;
    rho[1,J,K + 2] = 0;
    rho[I + 2,J,K + 2] = 0;
    for i in 2:I + 1 loop
    rho[i,J,1] = rho_o;
    rho[i,J,K + 2] = rho_o;
    T[i,J,1] = Twall_floor;
    T[i,J,K + 2] = Twall_cei;

    end for;
    for k in 2:K + 1 loop
    rho[1,J,k] = rho_o;
    rho[I + 2,J,k] = rho_o;
    T[1,J,k] = Twall_left;
    T[I + 2,J,k] = Twall_right;

    end for;
    De_M[1,J,1] = (dy * dz[1] * gamma) / (dx[1] * 0.5 + dx[2] * 0.5);
    Dw_M[1,J,1] = (dy * dz[1] * h_left) / (dx[1] * 0.5);
    Dn_M[1,J,1] = (dy * dx[1] * gamma) / (dz[2] * 0.5 + dz[2] * 0.5);
    Ds_M[1,J,1] = (dy * dx[1] * h_floor) / (dz[1] * 0.5);
    De_M[I,J,1] = (dy * dz[1] * h_right) / (dx[I] * 0.5);
    Dw_M[I,J,1] = (dy * dz[1] * gamma) / (dx[I - 1] * 0.5 + dx[I] * 0.5);
    Dn_M[I,J,1] = (dy * dx[I] * gamma) / (dz[1] * 0.5 + dz[2] * 0.5);
    Ds_M[I,J,1] = (dy * dx[I] * h_floor) / (dz[1] * 0.5);
    De_M[1,J,K] = (dy * dz[K] * gamma) / (dx[1] * 0.5 + dx[2] * 0.5);
    Dw_M[1,J,K] = (dy * dz[K] * h_left) / (dx[1] * 0.5);
    Dn_M[1,J,K] = (dy * dx[1] * h_cei) / (dz[K] * 0.5);
    Ds_M[1,J,K] = (dy * dx[1] * gamma) / (dz[K] * 0.5 + dz[K - 1] * 0.5);
    De_M[I,J,K] = (dy * dz[K] * h_right) / (dx[I] * 0.5);
    Dw_M[I,J,K] = (dy * dz[K] * gamma) / (dx[I] * 0.5 + dx[I - 1] * 0.5);
    Dn_M[I,J,K] = (dy * dx[I] * h_cei) / (dz[K] * 0.5);
    Ds_M[I,J,K] = (dy * dx[I] * gamma) / (dz[K] * 0.5 + dz[K - 1] * 0.5);
    for k in 2:K - 1 loop
    De_M[I,J,k] = (dy * dz[k] * h_right) / (dx[I] * 0.5);
    Dw_M[I,J,k] = (dy * dz[k] * gamma) / (dx[I] * 0.5 + dx[I - 1] * 0.5);
    Dn_M[I,J,k] = (dy * dx[I] * gamma) / (dz[k] * 0.5 + dz[k + 1] * 0.5);
    Ds_M[I,J,k] = (dy * dx[I] * gamma) / (dz[k] * 0.5 + dz[k - 1] * 0.5);
    De_M[1,J,k] = (dy * dz[k] * gamma) / (dx[1] * 0.5 + dx[2] * 0.5);
    Dw_M[1,J,k] = (dy * dz[k] * h_left) / (dx[1] * 0.5);
    Dn_M[1,J,k] = (dy * dx[1] * gamma) / (dz[k] * 0.5 + dz[k + 1] * 0.5);
    Ds_M[1,J,k] = (dy * dx[1] * gamma) / (dz[k] * 0.5 + dz[k - 1] * 0.5);

    end for;
    for i in 2:I - 1 loop
    De_M[i,J,K] = (dy * dz[K] * gamma) / (dx[i] * 0.5 + dx[i + 1] * 0.5);
    Dw_M[i,J,K] = (dy * dz[K] * gamma) / (dx[i] * 0.5 + dx[i - 1] * 0.5);
    Dn_M[i,J,K] = (dy * dx[i] * h_cei) / (dz[K] * 0.5);
    Ds_M[i,J,K] = (dy * dx[i] * gamma) / (dz[K] * 0.5 + dz[K - 1] * 0.5);
    De_M[i,J,1] = (dy * dz[1] * gamma) / (dx[i] * 0.5 + dx[i + 1] * 0.5);
    Dw_M[i,J,1] = (dy * dz[1] * gamma) / (dx[i] * 0.5 + dx[i - 1] * 0.5);
    Dn_M[i,J,1] = (dy * dx[i] * gamma) / (dz[1] * 0.5 + dz[2] * 0.5);
    Ds_M[i,J,1] = (dy * dx[i] * h_floor) / (dz[1] * 0.5);

    end for;
    for i in 2:I - 1 loop
    for k in 2:K - 1 loop
    De_M[i,J,k] = (dy * dz[k] * gamma) / (dx[i] * 0.5 + dx[i + 1] * 0.5);
    Dw_M[i,J,k] = (dy * dz[k] * gamma) / (dx[i] * 0.5 + dx[i - 1] * 0.5);
    Dn_M[i,J,k] = (dy * dx[i] * gamma) / (dz[k] * 0.5 + dz[k + 1] * 0.5);
    Ds_M[i,J,k] = (dy * dx[i] * gamma) / (dz[k] * 0.5 + dz[k - 1] * 0.5);

    end for;

    end for;
    for i in 2:I + 1 loop
    for k in 2:K + 1 loop
    Fe_M[i - 1,J,k - 1] = dy * dz[k - 1] * Vx[i,J,k] * (if noEvent(Vx[i,J,k] > 0) then rho[i,J,k] else rho[i + 1,J,k]);
    Fw_M[i - 1,J,k - 1] = dy * dz[k - 1] * Vx[i - 1,J,k] * (if noEvent(Vx[i - 1,J,k] > 0) then rho[i - 1,J,k] else rho[i,J,k]);
    Fn_M[i - 1,J,k - 1] = dy * dx[i - 1] * Vz[i,J,k] * (if noEvent(Vz[i,J,k] > 0) then rho[i,J,k] else rho[i,J,k + 1]);
    Fs_M[i - 1,J,k - 1] = dy * dx[i - 1] * Vz[i,J,k - 1] * (if noEvent(Vz[i,J,k - 1] > 0) then rho[i,J,k - 1] else rho[i,J,k]);
    Pe_M[i - 1,J,k - 1] = if noEvent(abs(De_M[i - 1,J,k - 1]) < eps) then 1 else Fe_M[i - 1,J,k - 1] / De_M[i - 1,J,k - 1];
    Pw_M[i - 1,J,k - 1] = if noEvent(abs(Dw_M[i - 1,J,k - 1]) < eps) then 1 else Fw_M[i - 1,J,k - 1] / Dw_M[i - 1,J,k - 1];
    Pn_M[i - 1,J,k - 1] = if noEvent(abs(Dn_M[i - 1,J,k - 1]) < eps) then 1 else Fn_M[i - 1,J,k - 1] / Dn_M[i - 1,J,k - 1];
    Ps_M[i - 1,J,k - 1] = if noEvent(abs(Ds_M[i - 1,J,k - 1]) < eps) then 1 else Fs_M[i - 1,J,k - 1] / Ds_M[i - 1,J,k - 1];
    aE_M[i - 1,J,k - 1] = De_M[i - 1,J,k - 1] + (cv + R) * max(-Fe_M[i - 1,J,k - 1], 0);
    aW_M[i - 1,J,k - 1] = Dw_M[i - 1,J,k - 1] + (cv + R) * max(Fw_M[i - 1,J,k - 1], 0);
    aS_M[i - 1,J,k - 1] = Ds_M[i - 1,J,k - 1] + (cv + R) * max(Fs_M[i - 1,J,k - 1], 0);
    aN_M[i - 1,J,k - 1] = Dn_M[i - 1,J,k - 1] + (cv + R) * max(-Fn_M[i - 1,J,k - 1], 0);
    aP_M[i - 1,J,k - 1] = aE_M[i - 1,J,k - 1] + aW_M[i - 1,J,k - 1] + aS_M[i - 1,J,k - 1] + aN_M[i - 1,J,k - 1] + (cv + R) * (Fe_M[i - 1,J,k - 1] - Fw_M[i - 1,J,k - 1] + Fn_M[i - 1,J,k - 1] - Fs_M[i - 1,J,k - 1]);
    rho[i,J,k] = rho_o + ComprCoeff * P[i - 1,J,k - 1] - ThermalExpCoeff * (T[i,J,k] - To);
    m[i - 1,J,k - 1] = rho[i,J,k] * dx[i - 1] * dz[k - 1] * dy;
    der(m[i - 1,J,k - 1]) = Fw_M[i - 1,J,k - 1] - Fe_M[i - 1,J,k - 1] + Fs_M[i - 1,J,k - 1] - Fn_M[i - 1,J,k - 1];
    e[i - 1,J,k - 1] = cv * T[i,J,k];
    rho_o * cv * dx[i - 1] * dz[k - 1] * dy * der(T[i,J,k]) = -aP_M[i - 1,J,k - 1] * T[i,J,k] + aE_M[i - 1,J,k - 1] * T[i + 1,J,k] + aW_M[i - 1,J,k - 1] * T[i - 1,J,k] + aN_M[i - 1,J,k - 1] * T[i,J,k + 1] + aS_M[i - 1,J,k - 1] * T[i,J,k - 1];

    end for;

    end for;
    for i in 1:I + 1 loop
    MUx[i,J,1] = mu + Kturb * Functions.sqrtReg(Vx[i,J,1] ^ 2, 0.00000001) * rho_o * Dturb;

    end for;
    for i in 1:I + 1 loop
    MUx[i,J,2] = max(mu, Kturb * Functions.sqrtReg(Vx[i,J,2] ^ 2, 0.00000001) * rho_o * Dturb);

    end for;
    for i in 1:I + 1 loop
    for k in 3:K loop
    MUx[i,J,k] = mu + Kturb * Functions.sqrtReg(Vx[i,J,k] ^ 2, 0.00000001) * rho_o * Dturb;

    end for;

    end for;
    for i in 1:I + 1 loop
    MUx[i,J,K + 1] = max(mu, Kturb * Functions.sqrtReg(Vx[i,J,K + 1] ^ 2, 0.00000001) * rho_o * Dturb);

    end for;
    for i in 1:I + 1 loop
    MUx[i,J,K + 2] = mu + Kturb * Functions.sqrtReg(Vx[i,J,K + 2] ^ 2, 0.00000001) * rho_o * Dturb;

    end for;
    for k in 1:K + 1 loop
    MUz[1,J,k] = mu + Kturb * Functions.sqrtReg(Vz[1,J,k] ^ 2, 0.00000001) * rho_o * Dturb;

    end for;
    for k in 1:K + 1 loop
    MUz[2,J,k] = max(mu, Kturb * Functions.sqrtReg(Vz[2,J,k] ^ 2, 0.00000001) * rho_o * Dturb);

    end for;
    for i in 3:I loop
    for k in 1:K + 1 loop
    MUz[i,J,k] = mu + Kturb * Functions.sqrtReg(Vz[i,J,k] ^ 2, 0.00000001) * rho_o * Dturb;

    end for;

    end for;
    for k in 1:K + 1 loop
    MUz[I + 1,J,k] = max(mu, Kturb * Functions.sqrtReg(Vz[I + 1,J,k] ^ 2, 0.00000001) * rho_o * Dturb);

    end for;
    for k in 1:K + 1 loop
    MUz[I + 2,J,k] = mu + Kturb * Functions.sqrtReg(Vz[I + 2,J,k] ^ 2, 0.00000001) * rho_o * Dturb;

    end for;
    for i in 2:I loop
    for k in 2:K + 1 loop
    De_x[i,J,k] = (dy * dz[k - 1] * (0.5 * MUx[i,J,k] + 0.5 * MUx[i + 1,J,k])) / dx[i];
    Dw_x[i,J,k] = (dy * dz[k - 1] * (0.5 * MUx[i,J,k] + 0.5 * MUx[i - 1,J,k])) / dx[i - 1];
    Dn_x[i,J,k] = (dy * (0.5 * dx[i] + 0.5 * dx[i - 1]) * (0.5 * MUx[i,J,k] + 0.5 * MUx[i,J,k + 1])) / dzx[k];
    Ds_x[i,J,k] = (dy * (0.5 * dx[i] + 0.5 * dx[i - 1]) * (0.5 * MUx[i,J,k] + 0.5 * MUx[i,J,k - 1])) / dzx[k - 1];
    Fe_x[i,J,k] = (Fw_M[i,J,k - 1] + Fe_M[i,J,k - 1]) / 2;
    Fw_x[i,J,k] = (Fw_M[i - 1,J,k - 1] + Fe_M[i - 1,J,k - 1]) / 2;
    Fn_x[i,J,k] = (dx[i - 1] * Fn_M[i - 1,J,k - 1] + dx[i] * Fn_M[i,J,k - 1]) / (dx[i - 1] + dx[i]);
    Fs_x[i,J,k] = (dx[i - 1] * Fs_M[i - 1,J,k - 1] + dx[i] * Fs_M[i,J,k - 1]) / (dx[i - 1] + dx[i]);
    Pe_x[i,J,k] = Fe_x[i,J,k] / De_x[i,J,k];
    Pw_x[i,J,k] = Fw_x[i,J,k] / Dw_x[i,J,k];
    Pn_x[i,J,k] = Fn_x[i,J,k] / Dn_x[i,J,k];
    Ps_x[i,J,k] = Fs_x[i,J,k] / Ds_x[i,J,k];
    aE_x[i,J,k] = De_x[i,J,k] + max(-Fe_x[i,J,k], 0);
    aW_x[i,J,k] = Dw_x[i,J,k] + max(Fw_x[i,J,k], 0);
    aS_x[i,J,k] = Ds_x[i,J,k] + max(Fs_x[i,J,k], 0);
    aN_x[i,J,k] = Dn_x[i,J,k] + max(-Fn_x[i,J,k], 0);
    aP_x[i,J,k] = aE_x[i,J,k] + aW_x[i,J,k] + aS_x[i,J,k] + aN_x[i,J,k];
    (dx[i - 1] * 0.5 + dx[i] * 0.5) * dy * dz[k - 1] * rho_o * der(Vx[i,J,k]) + aP_x[i,J,k] * Vx[i,J,k] = +aE_x[i,J,k] * Vx[i + 1,J,k] + aW_x[i,J,k] * Vx[i - 1,J,k] + aN_x[i,J,k] * Vx[i,J,k + 1] + aS_x[i,J,k] * Vx[i,J,k - 1] + (P[i - 1,J,k - 1] - P[i,J,k - 1]) * dy * dz[k - 1];

    end for;

    end for;
    for i in 2:I + 1 loop
    for k in 2:K loop
    De_z[i,J,k] = (dy * (dz[k - 1] * 0.5 + dz[k] * 0.5) * (0.5 * MUz[i,J,k] + 0.5 * MUz[i + 1,J,k])) / dxz[i];
    Dw_z[i,J,k] = (dy * (dz[k - 1] * 0.5 + dz[k] * 0.5) * (0.5 * MUz[i,J,k] + 0.5 * MUz[i - 1,J,k])) / dxz[i - 1];
    Dn_z[i,J,k] = (dy * dx[i - 1] * (0.5 * MUz[i,J,k] + 0.5 * MUz[i,J,k + 1])) / dz[k];
    Ds_z[i,J,k] = (dy * dx[i - 1] * (0.5 * MUz[i,J,k] + 0.5 * MUz[i,J,k - 1])) / dz[k - 1];
    Fe_z[i,J,k] = (dz[k - 1] * Fe_M[i - 1,J,k] + dz[k] * Fe_M[i - 1,J,k - 1]) / (dz[k - 1] + dz[k]);
    Fw_z[i,J,k] = (dz[k - 1] * Fw_M[i - 1,J,k] + dz[k] * Fw_M[i - 1,J,k - 1]) / (dz[k - 1] + dz[k]);
    Fn_z[i,J,k] = (Fs_M[i - 1,J,k] + Fn_M[i - 1,J,k]) / 2;
    Fs_z[i,J,k] = (Fs_M[i - 1,J,k - 1] + Fn_M[i - 1,J,k - 1]) / 2;
    Pe_z[i,J,k] = Fe_z[i,J,k] / De_z[i,J,k];
    Pw_z[i,J,k] = Fw_z[i,J,k] / Dw_z[i,J,k];
    Pn_z[i,J,k] = Fn_z[i,J,k] / Dn_z[i,J,k];
    Ps_z[i,J,k] = Fs_z[i,J,k] / Ds_z[i,J,k];
    aE_z[i,J,k] = De_z[i,J,k] + max(-Fe_z[i,J,k], 0);
    aW_z[i,J,k] = Dw_z[i,J,k] + max(Fw_z[i,J,k], 0);
    aS_z[i,J,k] = Ds_z[i,J,k] + max(Fs_z[i,J,k], 0);
    aN_z[i,J,k] = Dn_z[i,J,k] + max(-Fn_z[i,J,k], 0);
    aP_z[i,J,k] = aE_z[i,J,k] + aW_z[i,J,k] + aS_z[i,J,k] + aN_z[i,J,k];
    (dz[k - 1] * 0.5 + dz[k] * 0.5) * dy * dx[i - 1] * rho_o * der(Vz[i,J,k]) + aP_z[i,J,k] * Vz[i,J,k] = +aE_z[i,J,k] * Vz[i + 1,J,k] + aW_z[i,J,k] * Vz[i - 1,J,k] + aN_z[i,J,k] * Vz[i,J,k + 1] + aS_z[i,J,k] * Vz[i,J,k - 1] + (P[i - 1,J,k - 1] - P[i - 1,J,k]) * dy * dx[i - 1] - (rho[i,J,k] + rho[i,J,k + 1]) / 2 * (dz[k - 1] * 0.5 + dz[k] * 0.5) * dy * dx[i - 1] * g;

    end for;

    end for;
  end Room2D;

  package Functions
    function sqrtReg
      input Real x;
      input Real delta = 0.001 "Range of significant deviation from sqrt(x)";
      output Real y;
    algorithm
      y:=x / sqrt(sqrt(x * x + delta * delta));
    end sqrtReg;
    function CubeHeights2d "function that instantiate a 3d matrix with the same value except for
one element that has a different value "
      input Integer I "size on i-axis";
      input Integer K "size on k-axis";
      input Length dz[K] "relative height of each volume";
      output Length h[I,1,K] "output value";
    protected
      Length H[K];
      Length Htot;
    algorithm
      H[1]:=dz[1] / 2;
      Htot:=dz[1];
      for k in 2:K loop
              H[k]:=dz[k] / 2 + Htot;
        Htot:=Htot + dz[k];

      end for;
      for k in 1:K loop
              for i in 1:I loop
                  h[i,1,k]:=Htot - H[k];

        end for;

      end for;
    end CubeHeights2d;
    function Dzx
      input Integer K;
      input Distance dz[:];
      output Distance z[K + 1];
    algorithm
      z[1]:=dz[1] / 2;
      for k in 2:K loop
              z[k]:=(dz[k - 1] + dz[k]) / 2;

      end for;
      z[K + 1]:=dz[K] / 2;
    end Dzx;
    function Dxz
      input Integer I;
      input Distance dx[:];
      output Distance x[I + 1];
    algorithm
      x[1]:=dx[1] / 2;
      for i in 2:I loop
              x[i]:=(dx[i - 1] + dx[i]) / 2;

      end for;
      x[I + 1]:=dx[I] / 2;
    end Dxz;
  end Functions;

  annotation (Documentation(info="<html>
<h4>Modelica package for NS equations</h4>
<p><br/>Licensed by Marco Bonvini Modelica License 2 Copyright &copy; 2010-2012
<br/><br/><b>Version: </b>1.0.0<br/></p>
</html>"));

end BEPI_OMC;

