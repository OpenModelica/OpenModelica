/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#pragma once
/** @addtogroup solverNewton
 *
 *  @{
 */

#include <Core/Solver/INonLinSolverSettings.h>

class NewtonSettings : public INonLinSolverSettings
{
public:
    NewtonSettings();

    virtual ~NewtonSettings();
    /*max. Anzahl an Newtonititerationen pro Schritt (default: 50)*/
    virtual long int getNewtMax();
    virtual void setNewtMax(long int);
    /* Relative Toleranz für die Newtoniteration (default: 1e-6)*/
    virtual double getRtol();
    virtual void setRtol(double);
    /*Absolute Toleranz für die Newtoniteration (default: 1e-6)*/
    virtual double getAtol();
    virtual void setAtol(double);
    /*Dämpfungsfaktor (default: 0.9)*/
    virtual double getDelta();
    virtual void setDelta(double);
    virtual void load(string);

    virtual void setContinueOnError(bool);
    virtual bool getContinueOnError();
private:
    long int _iNewt_max; ///< max. Anzahl an Newtonititerationen pro Schritt (default: 25)

    double _dRtol; ///< Relative Toleranz für die Newtoniteration (default: 1e-6)
    double _dAtol; ///< Absolute Toleranz für die Newtoniteration (default: 1e-6)
    double _dDelta; ///< Dämpfungsfaktor (default: 0.9)
    bool _continueOnError;
};

/** @} */ // end of solverNewton
