#pragma once

template<typename T>
/**
 * An array-wrapper that will align the array along full cache lines.
 */
/*
#ifdef RUNTIME_STATIC_LINKING
class AlignedArray
#else
 */
class BOOST_EXTENSION_SIMVARS_DECL AlignedArray
/*#endif*/
{
  private:
    T *array;
  public:
    AlignedArray(int numberOfElements)
    {
      array = new T[numberOfElements];
    }

    ~AlignedArray()
    {
      delete[] array;
    }

    void* operator new(size_t size)
    {
      //see: http://stackoverflow.com/questions/12504776/aligned-malloc-in-c
      void *p1;
      void **p2;
      size_t alignment = 64;
      int offset = alignment - 1 + sizeof(void*);
      p1 = malloc(size + offset);
      p2 = (void**) (((size_t) (p1) + offset) & ~(alignment - 1));
      p2[-1] = p1; //line 6

      if (((size_t) p2) % 64 != 0)
        throw std::runtime_error("Memory was not aligned correctly!");

      return p2;
    }

    void operator delete(void *p)
    {
      void* p1 = ((void**) p)[-1];         // get the pointer to the buffer we allocated
      free(p1);
    }

    FORCE_INLINE T* get()
    {
      return array;
    }
};

/**
 *  SimVars class, implements ISimVars interface
 *  SimVars stores all model variable in continuous block of memory
 */
 /*
#ifdef RUNTIME_STATIC_LINKING
class SimVars: public ISimVars
#else*/
class BOOST_EXTENSION_SIMVARS_DECL SimVars: public ISimVars
/*#endif*/
{
  public:
    SimVars(size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_pre_vars, size_t dim_state_vars, size_t state_index);
    virtual ~SimVars();
    virtual double& initRealVar(size_t i);
    virtual int& initIntVar(size_t i);
    virtual bool& initBoolVar(size_t i);
    virtual double* getStateVector();
    virtual double* getDerStateVector();
    virtual double* getRealVarsVector() const;
    virtual int* getIntVarsVector() const;
    virtual bool* getBoolVarsVector() const;
    virtual void setRealVarsVector(const double* vars);
    virtual void setIntVarsVector(const int* vars);
    virtual void setBoolVarsVector(const bool* vars);

    virtual double* initRealArrayVar(size_t size, size_t start_index);
    virtual int* initIntArrayVar(size_t size, size_t start_index);
    virtual bool* initBoolArrayVar(size_t size, size_t start_index);
    virtual void initRealAliasArray(int indices[], size_t n, double* ref_data[]);
    virtual void initIntAliasArray(int indices[], size_t n, int* ref_data[]);
    virtual void initBoolAliasArray(int indices[], size_t n, bool* ref_data[]);
    virtual void initRealAliasArray(std::vector<int> indices, double* ref_data[]);
    virtual void initIntAliasArray(std::vector<int> indices, int* ref_data[]);
    virtual void initBoolAliasArray(std::vector<int> indices, bool* ref_data[]);
    virtual void savePreVariables();
    virtual void initPreVariables();
    virtual double& getPreVar(const double& var);
    virtual double& getPreVar(const int& var);
    virtual double& getPreVar(const bool& var);
    virtual void setPreVar(double& var);
    virtual void setPreVar(int& var);
    virtual void setPreVar(bool& var);

  protected:
    //see: http://stackoverflow.com/questions/12504776/aligned-malloc-in-c
    void *alignedMalloc(size_t required_bytes, size_t alignment) {
        void *p1;
        void **p2;

        int offset = alignment - 1 + sizeof(void*);
        p1 = malloc(required_bytes + offset);               // the line you are missing
        p2=(void**)(((size_t)(p1)+offset)&~(alignment-1));  //line 5
        p2[-1]=p1; //line 6
        return p2;
    }

    void alignedFree( void* p ) {
        void* p1 = ((void**)p)[-1];         // get the pointer to the buffer we allocated
        free( p1 );
    }

  private:
    double* getRealVar(size_t i);
    int* getIntVar(size_t i);
    bool* getBoolVar(size_t i);
    size_t _dim_real;  //number of all real variables (real algebraic vars,discrete algebraic vars, state vars, der state vars)
    size_t _dim_int;  // number of all integer variables (integer algebraic vars)
    size_t _dim_bool;  // number of all bool variables (boolean algebraic vars)
    size_t _dim_pre_vars;  //number of all pre variables (real algebraic vars,discrete algebraic vars, boolean algebraic vars, integer algebraic vars, state vars, der state vars)
    size_t _dim_z;  // number of all state variables
    size_t _z_i;  //start index of state vector in real_vars list
    double *_real_vars;  //array for all model real variables of size dim_real
    int* _int_vars;    //array for all model int variables of size dim_int
    bool* _bool_vars;  //array for all model bool variables of size dim_bool
    //Stores all variables indices (maps a model variable address to an index in the simvars memory)
    boost::unordered_map<const double*, unsigned int> _pre_real_vars_idx;
    boost::unordered_map<const int*, unsigned int> _pre_int_vars_idx;
    boost::unordered_map<const bool*, unsigned int> _pre_bool_vars_idx;
    //Stores all variables occurred before an event
    double* _pre_vars;
};
