typedef  double modelica_real ;
typedef  int modelica_integer;
typedef  bool modelica_boolean;
typedef  bool  edge_rettype;
typedef  bool sample_rettype;
typedef double cos_rettype;
typedef double cosh_rettype;
typedef double sin_rettype;
typedef double sinh_rettype;
typedef double log_rettype;
typedef double tan_rettype;
typedef double atan_rettype;
typedef double tanh_rettype;
typedef double exp_rettype;
typedef double sqrt_rettype;
typedef double abs_rettype;
typedef double max_rettype;
typedef double min_rettype;
typedef double arctan_rettype;
typedef double floorRetType;
typedef double asinRetType;
typedef double tan_rettype;
typedef double tanhRetType;
typedef double acosRetType;
typedef double logRetType;
typedef double coshRetType;



#if !defined(_MSC_VER)
//extern template class  boost::shared_ptr<IAlgLoopSolver>;
//extern template class  boost::shared_ptr<IAlgLoop>;
//extern template class  boost::shared_ptr<IAlgLoopSolverFactory>;
//extern template class  boost::shared_ptr<ISimData>;
extern template class  boost::multi_array<double,2>;
extern template class  boost::multi_array<double,1>;
extern template class  boost::multi_array<int,2>; 
extern template class  boost::multi_array<int,1>;
extern template class  ublas::vector<double>;
extern template class  ublas::vector<int>; 
extern template class  uBlas::compressed_matrix<double, uBlas::column_major, 0, uBlas::unbounded_array<int>, uBlas::unbounded_array<double> > ;
extern template class  std::vector<int>; 
extern template class  std::vector<double>; 
extern template class  unordered_map<string,unsigned int>;
extern template class  map<unsigned int,string>;
extern template class  vector<string>;
extern template class  vector<unsigned int>;
extern template class boost::unordered_map<std::string, boost::any>;
extern template class boost::circular_buffer<double>;
extern template class map<unsigned int,boost::circular_buffer<double> >;
extern template class  boost::function<bool (unsigned int)>;
extern template class  boost::function<void (unordered_map<string,unsigned int>&,unordered_map<string,unsigned int>&)>;
//extern template class  ublas::shallow_array_adaptor<double>;
//extern template class  ublas::vector<double, adaptor_t>;
//extern template class  ublas::matrix<double, adaptor_t> shared_matrix_t;
#endif