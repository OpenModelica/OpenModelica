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
        : dHcpl               (1e-3)
    , dErrTol             (0.0)
        , dK                  (-0.25)
        , dC                  (1.0)
        , dCmax               (1.5)
        , dCmin               (0.5)
        , dHuplim             ((globalSettings->getEndTime()-globalSettings->getStartTime())/100)
        , dHlowlim            (10.0 * UROUND)
        , dSingleStepTol      (1e-5)
        , dTendTol            (1e-6)
    , iMaxRejSteps        (50)
    , iSingleSteps        (0)
    , bDynCouplingStepSize  (false)
        , bCouplingOutput    (true)
    , _globalSettings       (globalSettings)
    {
    };

    double
        dHcpl,                 ///< Koppelschrittweite (=Intervalllänge nach der Daten zwischen gekoppelten System ausgetauscht werden, default: 100 Schritte [1/s])
        dErrTol,                ///< Gibt an, wieviel größer als 1.0 der Fehler sein darf, damit der Schritt akzeptiert wird (vorteilhaft, wenn sich wenig ändert) (default: 0.0)
        dK,                    ///< Faktor für Schrittweitensteuerung (k-ten Wurzel des Fehlers) (dK <= 0, default: -0.25, kleinerer Wert = größere Schrittweite)
        dC,                      ///< Savety Faktor für Schrittweitensteuerung (default: 1.0)
        dCmax,                  ///< Upscale Faktor für Schrittweitensteuerung (default: 1.5)
        dCmin,                  ///< Downscale Faktor für Schrittweitensteuerung (default: 0.5)
        dHuplim,                ///< Maximale Koppelschrittweite
        dHlowlim,               ///< Minimale Koppelschrittweite
        dSingleStepTol,         ///< Fehlertoleranz zur Aussetzung der Doppelschritt-Technik (default: 1e-5)
        dTendTol;               ///< Toleranz mit der Endzeit erreicht werden soll (default: 1e-6)

    int
        iMaxRejSteps,          ///< Max. Anzahl nacheinander verworfener Schritte (default: 50)
        iSingleSteps;           ///< Anzahl Schritte ohne Doppelschritt-Technik (ACHTUNG: nur bei genauer Kenntniss über Kopplungsgrad verwenden) (default: 0)

    bool
        bDynCouplingStepSize,   ///< Aquidistante oder dynamische gesteuerte Koppelschrittweite ([false,true]; default: false)
        bCouplingOutput;        ///< SimManagerSettings-spezifische Ausgaben ([false,true]; default: false)

    IGlobalSettings*
        _globalSettings;        ///< Zeiger auf Globale Simulations Einstellungen
};
/** @} */ // end of coreSimulationSettings