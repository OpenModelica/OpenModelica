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

#include "OMC.h"
#include <string>
#include <iostream>
#include "meta/meta_modelica.h"

int main(int argc, const char* argv[])
{
    std::cout << "Test OMC C-API dll ..." << std::endl;
    OMCData omcPtr = {0};
    int status = 0;

    string omhome;
    if (argc > 0)
        omhome = argv[0];
    /*----------------------------------------*/
    std::cout << "Intialize OMC, use gcc compiler" << std::endl;
    status = InitOMC(&omcPtr, "gcc", omhome);
    if (status > 0)
        std::cout << "..ok" << std::endl;
    else
        std::cout << "..failed" << std::endl;
    /*----------------------------------------*/


    /*----------------------------------------*/
    std::cout << "Get version of OMC" << std::endl;
    char* version = 0;
    status = GetOMCVersion(omcPtr, & version);
    if (status > 0)
        std::cout << "..ok " << version << std::endl;
    else
        std::cout << "..failed" << std::endl;
    /*------------------------------------------*/


    /*------------------------------------------*/
    std::cout << "load wrong library" << std::endl;
    status = LoadModel(omcPtr, "NoName");
    if (status < 0)
        std::cout << "..ok " << std::endl;
    else
        std::cout << "..failed" << std::endl;

    char* errorMsg = 0;
    status = GetError(omcPtr, &errorMsg);
    if (status > 0)
        std::cout << "..Errors/warnings: " << errorMsg << std::endl;
    else
        std::cout << "..failed" << std::endl;
    /*------------------------------------------*/


    /*------------------------------------------*/
    std::cout << "load MSL" << std::endl;
    status = LoadModel(omcPtr, "Modelica");
    if (status > 0)
        std::cout << "..ok " << std::endl;
    else
        std::cout << "..failed" << std::endl;
    status = GetError(omcPtr, &errorMsg);
    if (status > 0)
        std::cout << "..Errors/warnings: " << errorMsg << std::endl;
    else
        std::cout << "..failed" << std::endl;
    /*------------------------------------------*/


    /*------------------------------------------*/
    std::cout << "Simulate MSL example Modelica.Blocks.Examples.PID_Controller" << std::endl;
    std::string simulateModel = "simulate(Modelica.Blocks.Examples.PID_Controller)";
    char* simulateResult = 0;
    status = SendCommand(omcPtr, simulateModel.c_str(), &simulateResult);
    if (status > 0)
        std::cout << "..ok " << simulateResult << std::endl;
    else
        std::cout << "..failed" << std::endl;

    char* errorMsg2 = 0;
    status = GetError(omcPtr, &errorMsg2);
    std::cout << "..Errors/warnings: " << errorMsg2 << std::endl;


    /*------------------------------------------*/
    FreeOMC(omcPtr);
}
