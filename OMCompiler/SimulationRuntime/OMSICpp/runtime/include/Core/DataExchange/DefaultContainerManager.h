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
#include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>

/**
 * A container manager that is designed for single threaded write output. It has just one container that can
 * be filled with values and written directly.
 */
class DefaultContainerManager : public Writer
{
private:
    write_data_t _container;

protected:
    /**
     * Write the given container to the result file.
     * @param container The container that should be written.
     */
    void writeContainer(const write_data_t& container)
    {
        write(get < 0 > (container), get < 1 > (container));
    }

public:
    DefaultContainerManager() :
        _container()
    {
    }

    virtual ~DefaultContainerManager()
    {
    }

    /**
     * Get the internal container. It is always the same.
     * @return A reference to the internal container that can be filled with values.
     */
    virtual write_data_t& getFreeContainer()
    {
        return _container;
    };

    /**
     * Write the given container to the result file.
     * @param container The container that should be written.
     */
    virtual void addContainerToWriteQueue(const write_data_t& container)
    {
        writeContainer(container);
    };
};

/** @} */ // end of dataexchange
