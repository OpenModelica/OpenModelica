#pragma once

/** @defgroup dataexchange Core.DataExchange
 *  Data storage module for simulation variables
 *  @{
 */

/*****************************************************************************/
/**

Abstract dataexchange interface for dae system

\date     June, 1st, 2011
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
class IHistory
{
public:
  /**
  Returns simvalues for a time entry
  */
     virtual void getSimResults(const double time,ublas::vector<double>& v,ublas::vector<double>& dv) =0;
  /**
  Returns all simulation results for all Variables (R matrix) and rhs(dR)
  */
  virtual void getSimResults(ublas::matrix<double>& R,ublas::matrix<double>& dR) =0;
  /**
  Returns all simulation results for all Variables (R matrix), rhs(dR) and residues (Re)
  */
  virtual void getSimResults(ublas::matrix<double>& R,ublas::matrix<double>& dR,ublas::matrix<double>& Re) =0;

  virtual void getOutputNames(vector<string >& output_names) = 0;

  /**
  Returns all output variables results
  */
  virtual void getOutputResults(ublas::matrix<double>& OR)=0;
  /**
  Retunrs all time entries
  */
  virtual vector<double> getTimeEntries() =0;
  /**
  Returns numer of all time entries
  */
  virtual unsigned long getSize()=0;
  /**
  Returns number of variabels (state-,algebraic variables)
  */
  virtual unsigned long getDimR()=0;
  /**
  Retunrs number of state variables
  */
  virtual unsigned long getDimdR()=0;
  /**
  Returns number of residues
  */
  virtual unsigned long getDimRe()=0;
  /**
  Clears simulation buffer
  */
  virtual void clear()=0;
  virtual ~IHistory()  {};
};
/** @} */ // end of dataexchange