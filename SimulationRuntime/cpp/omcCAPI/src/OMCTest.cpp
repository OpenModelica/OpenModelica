
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

  GC_stack_base sb;
  GC_get_stack_base(&sb);
  GC_register_my_thread(&sb);

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

  GC_unregister_my_thread();
}

#define MAX_THREADS 4

int main(int argc, const char* argv[])
{
  std::thread threads[MAX_THREADS];
  int i = 0;

  std::cout << "Test OMC C-API dll ..." << std::endl;
  InitMetaOMC();
  GC_allow_register_threads();

  for (i = 0; i < MAX_THREADS; i++)
  {
    std::string dir = std::string("./tmp") + std::to_string(i);
    threads[i] = std::thread(runTest, dir, "");
  }

  for (i = 0; i < MAX_THREADS; i++)
    if (threads[i].joinable())
      threads[i].join();
}

