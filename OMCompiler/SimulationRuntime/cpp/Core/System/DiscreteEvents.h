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
/** @addtogroup coreSystem
 *
 *  @{
 */
/*
#ifdef RUNTIME_STATIC_LINKING
class DiscreteEvents
#else*/
class BOOST_EXTENSION_EVENTHANDLING_DECL DiscreteEvents
/*#endif*/
{
public:
  DiscreteEvents(shared_ptr<ISimVars> sim_vars);
  virtual ~DiscreteEvents( );
  //Inits the event variables
  void initialize();


  //saves a variable in _pre_vars vector
  void save(double& var,double value);
  void save(int& var,double value);
  void save(bool& var,double value);
  void save(std::string& var,const std::string& value);
  //void savePreVars(double vars [], unsigned int n);


  //Implementation of the Modelica pre  operator
  double& pre(const double& var);
  int& pre(const int& var);
  bool& pre(const bool& var);
  std::string& pre(const std::string& var);
  template<typename T>
  WrapArray<T> pre(const BaseArray<T>& arr) {
    return _sim_vars->getPreArr(arr);
  }
  //Implementation of the Modelica edge  operator
  bool edge(double& var);
  bool edge(int& var);
  bool edge(bool& var);
  //Implementation of the Modelica change  operator
  bool change(int& var);
  bool change(bool& var);
  bool change(double& var);


  bool changeDiscreteVar(double& var);
  bool changeDiscreteVar(int& var);
  bool changeDiscreteVar(bool& var);
  bool changeDiscreteVar(std::string& var);
  //getCondition_type getCondition;

private:
   shared_ptr<ISimVars> _sim_vars;
};

/**
 * Operator class to get pre values of an array
 */
template<typename T>
class PreArray2CArray
{
  DiscreteEvents *_discrete_events;

 public:
  PreArray2CArray(shared_ptr<DiscreteEvents>& discrete_events) {
    _discrete_events = discrete_events.get();
  }

  const T operator()(const T& val) const {
    return _discrete_events->pre(val);
  }
};
/** @} */ // end of coreSystem
