

#include <Core/Modelica.h>

//template class   shared_ptr<IAlgLoopSolver>;
//template class   shared_ptr<IAlgLoop>;
//template class   shared_ptr<IAlgLoopSolverFactory>;
//template class   shared_ptr<ISimData>;
template class   boost::multi_array<double,2>;
template class   boost::multi_array<double,1>;
template class   boost::multi_array<int,2>;
template class   boost::multi_array<int,1>;
template class   ublas::vector<double>;
template class   ublas::vector<int>;
template class   uBlas::compressed_matrix<double, uBlas::column_major, 0, uBlas::unbounded_array<int>, uBlas::unbounded_array<double> > ;
template class   std::vector<int>;
template class   std::vector<double>;
template class   unordered_map<string,unsigned int>;
template class   map<unsigned int,string>;
template class   vector<string>;
template class   boost::circular_buffer<double>;
template class   map<unsigned int,boost::circular_buffer<double> >;
template class   vector<unsigned int>;
template class  boost::function<bool (unsigned int)>;
template class  boost::function<void (unordered_map<string,unsigned int>&,unordered_map<string,unsigned int>&)>;
//template class  ublas::shallow_array_adaptor<double>;
//template class  ublas::vector<double, adaptor_t>;
//template class  ublas::matrix<double, adaptor_t> shared_matrix_t;