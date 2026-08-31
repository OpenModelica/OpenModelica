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
/** @addtogroup dataexchangePolicies
 *
 *  @{
 */

#include <Core/DataExchange/FactoryPolicy.h>
#include <fstream>

/**
 Policy class to write simulation results
*/

class DefaultWriter : public ContainerManager
{
public:
    DefaultWriter(unsigned long size, string output_path, string file_name)
        : ContainerManager()

    {
    }

    ~DefaultWriter()
    {
    }

    void init(std::string output_path, std::string file_name, size_t dim)
    {
    }

    void read(ublas::matrix<double>& R, ublas::matrix<double>& dR)
    {
    }

    void read(ublas::matrix<double>& R, ublas::matrix<double>& dR, ublas::matrix<double>& Re)
    {
    }

    void read(const double& time, ublas::vector<double>& dv, ublas::vector<double>& v)
    {
    }

    void read(ublas::matrix<double>& R)
    {
    }

    /*writes pramater values to results file
     @v_list values of parameter
     @start_time
     @end_time
     */
    virtual void write(const all_vars_t& v_list,  const neg_all_vars_t& neg_v_list, double start_time, double end_time)
    {
        //not supported for file output
    }

    /*
     writes header of results file with the variable names
     @s_list name of variables
     @s_desc_list description of variables
     @s_parameter_list name of parameter
     @s_desc_parameter_list description of parameter
     */
    virtual void write(const all_names_t& s_list, const all_description_t& s_desc_list,
                       const all_names_t& s_parameter_list, const all_description_t& s_desc_parameter_list)
    {
    }

    void write(const char c)
    {
    }

    /*
     writes simulation results for a time step
     @v_list variables and state vars
     @v2_list derivatives vars
     @time
     */
    virtual void write(const all_vars_time_t& v_list, const neg_all_vars_t& neg_v_list)
    {
    }

    void getTime(std::vector<double>& time)
    {
        //not supported for file output
    }

    unsigned long size()
    {
        //not supported for file output
        return 0;
    }

    void eraseAll()
    {
    }

protected:
    vector<string> _var_outputs;
};

/** @} */ // end of dataexchangePolicies
