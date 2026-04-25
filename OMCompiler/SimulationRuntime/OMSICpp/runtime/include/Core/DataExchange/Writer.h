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
/** @addtogroup dataexchange

*
*  @{
*/

/**
* Operator class to return value of output variable
*/
template <typename T>
struct WriteOutputVar
{
    /**
     return value of output variable
     @param val pointer to output variable
     @param negate if output variable is a negate alias variable
     */
    const double operator()(const T* val, bool negate)
    {
        //if output variable is a negate alias variable, then negate output value
        if (negate)
            return -*val;
        else
            return *val;
    }
};

/**
* specialized bool Operator class to return value of a boolean variable
*/
template <>
struct WriteOutputVar<bool>
{
    /**
     return value of output variable
     @param val pointer to output variable
     @param negate if output variable is a negate alias variable
     */
    const double operator()(const bool* val, bool negate)
    {
        //if output variable is a negate alias variable, then negate output value
        if (negate)
            return !*val;
        else
            return *val;
    }
};

class Writer
{
public:
    Writer()
    {
    }

    virtual ~Writer()
    {
    }

    virtual void write(const all_vars_time_t& v_list, const neg_all_vars_t& neg_v_list) = 0;
};

/** @} */ // end of dataexchange
