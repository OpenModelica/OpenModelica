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
#include <thread>

#define GC_THREADS
#include "gc.h"

/*
#include <boost/thread.hpp>
#include <boost/chrono.hpp>
*/

void runTest(std::string testfolder, std::string omhome)
{

  InitMetaOMC();
  /*threads test disabled:
  GC_stack_base sb;
  GC_get_stack_base(&sb);
  GC_register_my_thread(&sb);
  */
  int status = 0;
  char *change_dir_results = 0, *mkDirResults = 0, *version = 0, *errorMsg2 = 0, *simulateResult = 0, *clear = 0;

  OMCData *omcData;
  std::cout << "Initialize OMC, use gcc compiler on folder: " << testfolder << std::endl;
  // if you send in 1 here it will crash on Windows, i need do debug more why this happens
  status = InitOMC(&omcData, "gcc", "");
  if(status > 0)
    std::cout << "..ok" << std::endl;
  else
    std::cout << "..failed" << std::endl;
  /*----------------------------------------*/


  // create the test folder
  std::cout << "Create working directory of OMC: " << testfolder << std::endl;
  std::string mkDir = "mkdir(\"" + testfolder + "\")";
  status = SendCommand(omcData, mkDir.c_str(), &mkDirResults);
  if(status > 0)
    std::cout << "..ok " << mkDirResults << std::endl;
  else
    std::cout << "..failed" << std::endl;

  std::cout << "Set working directory of OMC:" << testfolder << std::endl;
  status = SetWorkingDirectory(omcData, testfolder.c_str(), &change_dir_results);
  if(status > 0)
    std::cout << "..ok " << change_dir_results << std::endl;
  else
    std::cout << "..failed" << std::endl;

  /*----------------------------------------*/
  std::cout << "Get version of OMC" << std::endl;
  status = GetOMCVersion(omcData, &version);
  if(status > 0)
    std::cout << "..ok " << version << std::endl;
  else
    std::cout << "..failed" << std::endl;
  /*------------------------------------------*/


  /*------------------------------------------*/
  std::cout << "load wrong library" << std::endl;
  status = LoadModel(omcData, "NoName");
  if(status < 0)
    std::cout << "..ok "  << std::endl;
  else
    std::cout << "..failed" << std::endl;

  char* errorMsg=0;
  status = GetError(omcData, &errorMsg);
  if(status > 0)
    std::cout << "..Errors/warnings: "<< errorMsg << std::endl;
  else
    std::cout << "..failed" << std::endl;
  /*------------------------------------------*/


  /*------------------------------------------*/
  std::cout << "load MSL" << std::endl;
  status = LoadModel(omcData, "Modelica");
  if(status > 0)
    std::cout << "..ok "  << std::endl;
  else
    std::cout << "..failed" << std::endl;

  status = GetError(omcData, &errorMsg);
  if(status > 0)
    std::cout << "..Errors/warnings: "<< errorMsg << std::endl;
  else
    std::cout << "..failed" << std::endl;
  /*------------------------------------------*/


  /*------------------------------------------*/
  std::cout << "Simulate MSL example Modelica.Blocks.Examples.PID_Controller" << std::endl;
  std::string simulateModel = "simulate(Modelica.Blocks.Examples.PID_Controller)";
  status = SendCommand(omcData, simulateModel.c_str(), &simulateResult);
  if(status > 0)
    std::cout << "..ok " << simulateResult << std::endl;
  else
    std::cout << "..failed" << std::endl;

  status = GetError(omcData, &errorMsg2);
  std::cout << "..Errors/warnings: "<< errorMsg2 << std::endl;

  std::string dir2 = "..";
  status = SetWorkingDirectory(omcData, dir2.c_str(), &change_dir_results);
  if(status > 0)
    std::cout << "..ok " << change_dir_results << std::endl;
  else
    std::cout << "..failed" << std::endl;

  std::cout << "send clear() to the compiler" << std::endl;
  status = SendCommand(omcData, "clear()", &clear);
  if(status > 0)
    std::cout << "..ok " << clear << std::endl;
  else
    std::cout << "..failed" << std::endl;

  /*threads test disabled: GC_unregister_my_thread(); */

}

#define MAX_THREADS 4

int main(int argc, const char* argv[])
{

  //threads test disabled: std::thread threads[MAX_THREADS];
  int i = 0;

  std::cout << "Test OMC C-API dll ..." << std::endl;
  InitMetaOMC();
  //threads test disabled: GC_allow_register_threads();

  /*threads test disabled:
  for (i = 0; i < MAX_THREADS; i++)
  {
    std::string dir = std::string("./tmp") + std::to_string(i);
    threads[i] = std::thread(runTest, dir, "");
  }

  for (i = 0; i < MAX_THREADS; i++)
    if (threads[i].joinable())
      threads[i].join();
  
  */
  runTest("./tmp", "");

}
