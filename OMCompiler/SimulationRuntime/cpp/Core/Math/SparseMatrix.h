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

