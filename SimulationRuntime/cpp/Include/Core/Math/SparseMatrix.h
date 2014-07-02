#pragma once


#include "Modelica.h"
#ifdef USE_UMFPACK
#include "umfpack.h"
#endif

using std::map;
using std::pair;
using std::make_pair;

struct sparse_inserter {
    struct t2 {
        int i;
        int j;
        map< pair<int,int>, double> & content;
        t2(int i, int j, map< pair<int,int>, double> & c): i(i), j(j), content(c) {}
        void operator=(double t) {
            content[make_pair(j,i)]=t;
        }
    };

    struct t1 {
        int i;
        map< pair<int,int>, double> & content;
        t1(int i,map< pair<int,int>, double> & c): i(i), content(c) {}
        t2 operator[](size_t j) {
            t2 res(i,j,content);
            return res;
        }
    };


    map< pair<int,int>, double> content;
    t1 operator[](size_t i) {
        t1 res(i,content);
        return res;
    }

};

struct sparse_matrix {
    std::vector<int> Ap;
    std::vector<int> Ai;
    std::vector<double> Ax;
    int n;
    sparse_matrix(int n=-1): n(n) {}

    void build(sparse_inserter& ins);
    int solve(const double* b,double* x);
};

