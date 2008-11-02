#ifndef _PARALLELOPTIONS_H
#define _PARALLELOPTIONS_H
#include <iostream>
using namespace std;

/* Class for handling of parallel options, like number of processors,
   latency and bandwith characteristics, etc.
*/

class ParallelOptions
{
public:
  ParallelOptions(int nproc,double latency=10.0,double bandwidth=1.0)
    : m_nproc(nproc), m_latency(latency), m_bandwidth(bandwidth) { };

  ParallelOptions() : m_nproc(0), m_latency(0), m_bandwidth(0) { };

  friend ostream& operator << (ostream&os,ParallelOptions &opt) {
    os << "ParallelOptions: "<< endl << "  number_of_processors: " << opt.get_nproc() << endl;
    os << "  latency: " << opt.get_latency() << endl;
    os << "  bandwidth: " << opt.get_bandwidth() << endl;
    return os;
  };

  int get_nproc() { return m_nproc;};
  double get_latency() { return m_latency; };
  double get_bandwidth() { return m_bandwidth; };
private:
  int m_nproc;
  double m_latency; // latency in microseconds
  double m_bandwidth; // Bandwidth in Mb/s
};

#endif
