#include "zhelpers.hpp"
#include <string>
#include <vector>
#include <thread>
#include <memory>
#include <functional>
#include <iostream>
#include <string>
#include "OMC.h"
#define GC_THREADS
#include "gc.h"

using std::string;
static std::exception_ptr globalSimulationExceptionPtr = nullptr;
static std::exception_ptr globalZeroMQTaskExceptionPtr = nullptr;