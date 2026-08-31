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
//#include "../../System/Interfaces/IDAESystem.h"

class Ranking
{
public:
    Ranking(shared_ptr<IMixedSystem> system, IReduceDAESettings* settings);
    ~Ranking(void);
    virtual label_list_type DoRanking(ublas::matrix<double>& R, ublas::matrix<double>& dR, ublas::matrix<double>& Re,
                                      vector<double>& time_values);
    label_list_type residuenRanking(ublas::matrix<double>& R, ublas::matrix<double>& dR, ublas::matrix<double>& Re,
                                    vector<double>& time_values);
    label_list_type perfectRanking(ublas::matrix<double>& Ro, shared_ptr<IMixedSystem> _system,
                                   IReduceDAESettings* _settings, SimSettings simsettings,
                                   string modelKey, vector<string> output_names, double timeout,
                                   ISimController* sim_controller);
private:
    //methods:
    IReduceDAESettings* _settings;
    shared_ptr<IMixedSystem> _system;
    double* _zeroVal;
    double* _zeroValOld;
};

/*
Helper class to select the index of the label tuple  and return it
*/
class Li
{
public:
    typedef std::tuple_element<0, label_type>::type result_type;

    result_type operator()(const label_type& u) const
    {
        return get < 0 > (u);
    }
};
