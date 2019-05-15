#pragma once
/** @addtogroup coreSolver
 *
 *  @{
 */


/*****************************************************************************/
/**
Allgemeine Klasse zur Kapselung der Parameter (Einstellungen) für einen linearen Solver
Hier werden default-Einstellungen entsprechend der allgemeinen Simulations-
einstellungen gemacht, diese können überprüft und ev. Fehleinstellungen korrigiert
werden.
*****************************************************************************/

class ILinSolverSettings
{
public:
  virtual ~ILinSolverSettings(){};

  virtual bool getUseSparseFormat() = 0;
  virtual void setUseSparseFormat(bool value) = 0;
  virtual void load(std::string) = 0;
};
 /** @} */ // end of coreSolver
