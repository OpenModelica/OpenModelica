#pragma once
/** @addtogroup coreSolver
 *
 *  @{
 */
/*****************************************************************************/
/**
Allgemeine Klasse zur Kapselung der Parameter (Einstellungen) für einen nicht linearen Solver
Hier werden default-Einstellungen entsprechend der allgemeinen Simulations-
einstellungen gemacht, diese können überprüft und ev. Fehleinstellungen korrigiert
werden.
*****************************************************************************/

class INonLinSolverSettings
{
public:
  virtual ~INonLinSolverSettings() {};

  virtual long int getNewtMax() = 0;
  virtual void setNewtMax(long int) = 0;
  virtual double getRtol() = 0;
  virtual void setRtol(double) = 0;
  virtual double getAtol() = 0;
  virtual void setAtol(double) = 0;
  virtual double getDelta() = 0;
  virtual void setDelta(double) = 0;
  virtual void load(string) = 0;
  virtual void setContinueOnError(bool) = 0;
  virtual bool getContinueOnError() = 0;
};
 /** @} */ // end of coreSolver
