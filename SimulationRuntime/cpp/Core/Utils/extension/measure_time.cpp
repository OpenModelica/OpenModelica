#include "Core/Utils/extension/measure_time.hpp"

RDTSC_MeasureTime * MeasureTime::instance = 0;

MeasureTime* MeasureTime::getInstance()
{
  return instance;
}

void MeasureTime::deinitialize()
{
  if (instance != 0)
    delete instance;
}

unsigned long long MeasureTime::getTime()
{
//  if (instance == 0)
//    return 0;

  std::cerr << "hallo welt" << std::endl;
  unsigned long long val = instance->getTimeP();

  return val;
}

void MeasureTime::writeTimeToJason(std::string model_name, std::vector<data> times)
{
  std::stringstream date;
  date.str("");
  time_t sec = time(NULL);
  tm * date_t = localtime(&sec);
  date << date_t->tm_year + 1900 << "-" << date_t->tm_mon + 1 << "-" << date_t->tm_mday << " " << date_t->tm_hour << ":" << date_t->tm_min << ":" << date_t->tm_sec;
  std::ofstream os;
  os.open((model_name + std::string("_prof.json")).c_str());
  os << "{\n\"name\":\"" << model_name << "\",\n";
  os << "\"prefix\":\"" << model_name << "\",\n";
  os << "\"date\":\"" << date.str() << "\",\n";

  os << "\"functions\":[\n],\n";
  os << "\"profileBlocks\":[\n";

  for (unsigned i = 0; i < times.size(); ++i)
  {
    os << "{\"id\":" << i << ",\"ncall\":" << times[i].num_calcs << ",\"time\":" << times[i].sum_time << ",\"maxTime\":" << times[i].max_time << "},\n";
  }
  os << "]\n}";
  os.close();
}

unsigned long long RDTSC_MeasureTime::getTimeP()
{
  return RDTSC();
}

void RDTSC_MeasureTime::initialize()
{
  instance = new RDTSC_MeasureTime();
}

#if defined(_MSC_VER)

#if defined(__i386__) || defined(__x86_64__)
unsigned long long RDTSC_MeasureTime::RDTSC()
{
  return _rdtsc();
}
#else
unsigned long long RDTSC_MeasureTime::RDTSC()
{
  throw std::runtime_error("No time measurement for this processor arch.");
  return 0;
}
#endif // defined(__i386__) || defined(__x86_64__)
#else
#if defined(__i386__)
unsigned long long RDTSC_MeasureTime::RDTSC()
{
  unsigned long long res;
  asm volatile (".byte 0x0f, 0x31" : "=A" (res));
  return res;
}

#elif defined(__x86_64__)
unsigned long long RDTSC_MeasureTime::RDTSC()
{
  unsigned hi, lo;
  __asm__ __volatile__ ("rdtsc" : "=a"(lo), "=d"(hi));
  return ((unsigned long long) lo) | (((unsigned long long) hi) << 32);
}

#else
unsigned long long RDTSC_MeasureTime::RDTSC()
{
  throw std::runtime_error("No time measurement for this processor arch.");
  return 0;
}

#endif //defined(__i386__)

#endif //defined(_MSC_VER)
