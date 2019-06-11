#pragma once



struct BOOST_EXTENSION_EXPORT_DECL sparse_inserter  {
    struct t2 {
        int i;
        int j;
        map< pair<int,int>, double> & content;
        t2(int i, int j, map< pair<int,int>, double> & c): i(i), j(j), content(c) {}
        inline void operator=(double t) {
            content[make_pair(j,i)]=t;
        }
    };

    struct t1 {
        int i;
        map< pair<int,int>, double> & content;
        t1(int i,map< pair<int,int>, double> & c): i(i), content(c) {}
        inline t2 operator[](size_t j) {
            t2 res(i,j,content);
            return res;
        }
    };


    map< pair<int,int>, double> content;
    inline t1 operator[](size_t i) {
        t1 res(i,content);
        return res;
    }

    inline t2 operator()(const unsigned int  i, const unsigned int j)
    {
      t2 res(i-1,j-1,content);
      return res;
    }

};

struct BOOST_EXTENSION_EXPORT_DECL sparse_matrix {
    std::vector<int> Ap;
    std::vector<int> Ai;
    std::vector<double> Ax;
    int n;
    sparse_matrix(int n=-1): n(n) {}

    void build(sparse_inserter& ins);
    int solve(const double* b,double* x);
};

