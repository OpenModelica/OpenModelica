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
/** @addtogroup coreSimulationSettings
 *
 *  @{
 */

/* Klasse zur Kapselung der Parameter (Einstellungen) für den SimManagerSettings.*/

#include <Core/Math/Constants.h>

class ISimControllerSettings
{
public:
    ISimControllerSettings(IGlobalSettings* globalSettings)
        : dHcpl(1e-3)
          , dErrTol(0.0)
          , dK(-0.25)
          , dC(1.0)
          , dCmax(1.5)
          , dCmin(0.5)
          , dHuplim((globalSettings->getEndTime() - globalSettings->getStartTime()) / 100)
          , dHlowlim(10.0 * UROUND)
          , dSingleStepTol(1e-5)
          , dTendTol(1e-6)
          , iMaxRejSteps(50)
          , iSingleSteps(0)
          , bDynCouplingStepSize(false)
          , bCouplingOutput(true)
          , _globalSettings(globalSettings)
    {
    };

    double
        dHcpl,
        ///< Koppelschrittweite (=Intervalllänge nach der Daten zwischen gekoppelten System ausgetauscht werden, default: 100 Schritte [1/s])
        dErrTol,
        ///< Gibt an, wieviel größer als 1.0 der Fehler sein darf, damit der Schritt akzeptiert wird (vorteilhaft, wenn sich wenig ändert) (default: 0.0)
        dK,
        ///< Faktor für Schrittweitensteuerung (k-ten Wurzel des Fehlers) (dK <= 0, default: -0.25, kleinerer Wert = größere Schrittweite)
        dC, ///< Savety Faktor für Schrittweitensteuerung (default: 1.0)
        dCmax, ///< Upscale Faktor für Schrittweitensteuerung (default: 1.5)
        dCmin, ///< Downscale Faktor für Schrittweitensteuerung (default: 0.5)
        dHuplim, ///< Maximale Koppelschrittweite
        dHlowlim, ///< Minimale Koppelschrittweite
        dSingleStepTol, ///< Fehlertoleranz zur Aussetzung der Doppelschritt-Technik (default: 1e-5)
        dTendTol; ///< Toleranz mit der Endzeit erreicht werden soll (default: 1e-6)

    int
        iMaxRejSteps, ///< Max. Anzahl nacheinander verworfener Schritte (default: 50)
        iSingleSteps;
    ///< Anzahl Schritte ohne Doppelschritt-Technik (ACHTUNG: nur bei genauer Kenntniss über Kopplungsgrad verwenden) (default: 0)

    bool
        bDynCouplingStepSize,
        ///< Aquidistante oder dynamische gesteuerte Koppelschrittweite ([false,true]; default: false)
        bCouplingOutput; ///< SimManagerSettings-spezifische Ausgaben ([false,true]; default: false)

    IGlobalSettings*
    _globalSettings; ///< Zeiger auf Globale Simulations Einstellungen
};

/** @} */ // end of coreSimulationSettings
