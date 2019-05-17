#pragma once
#include "omp.h"
#include <vector>
#define BOOST_UBLAS_SHALLOW_ARRAY_ADAPTOR
#include <Core/Utils/numeric/bindings/umfpack/umfpack.hpp>
#include <Core/Utils/numeric/bindings/ublas/vector.hpp>
#include <Core/Utils/numeric/bindings/ublas.hpp>
#include <boost/numeric/ublas/io.hpp>
namespace uBlas = boost::numeric::ublas;
namespace umf = boost::numeric::bindings::umfpack;

typedef uBlas::compressed_matrix<double, uBlas::column_major, 0, uBlas::unbounded_array<int>, uBlas::unbounded_array<double> > sparsematrix_t;
typedef uBlas::shallow_array_adaptor<double> adaptor_t;
typedef uBlas::vector<double, adaptor_t> shared_vector_t;

typedef int (*UC_fp)(const int *, const double *, const double *, const double *, int *, double *, void *);
typedef int (*S_fp)(const double *,const double *,const double *, double*, double *, int *, void *);
typedef int (*P_fp)(int *, double *, double *, double *, double *, double *, double *, double *, double *, int *, double *, double *, int *, void *);
typedef int (*J_fp)(S_fp, int *, int *, double *, double *, double *, double *, double *, double *, double *, double *, double *, int *, int *, void *);
typedef int (*Ja_fp)(double *, int *, int *, double *, double *, double *, double *, double *, double *, double *, double *, double *, int *, int *, void *);
typedef int (*Nl_fp)(double *, double *, double *, int *, S_fp, Ja_fp, P_fp, double *, double *, int *, int *, void *, double *, double *, double *, double *, double *, double *, int *, double *, double *, double *, double *, double *, double *, double *, double *, double *, int *, int *, int *, int *, int *, int *);
typedef int (*Jd_fp)(double *, double *, double *, double *, double *, void *);

class dassl {
    public:
        dassl() : num_threads(1), sparse(false), rtol(1e-6), atol(1e-6), loglevel(0), Symbolic(NULL), Numeric(NULL), A(NULL), init(false), reverseJacobi(false) {
            info.resize(20,0);
        }
        dassl(unsigned int num_threads) : num_threads(num_threads), sparse(false), rtol(1e-6), atol(1e-6), loglevel(0), Symbolic(NULL), Numeric(NULL), A(NULL), init(false), reverseJacobi(false) {
            info.resize(20,0);
        }
        dassl(unsigned int num_threads, bool sparse) : num_threads(num_threads), sparse(sparse), rtol(1e-6), atol(1e-6), loglevel(0), Symbolic(NULL), Numeric(NULL), A(NULL), init(false), reverseJacobi(false) {
            info.resize(20,0);
        }
        ~dassl() {
            if(Symbolic)
                delete Symbolic;
            if(Numeric)
                delete Numeric;
            if(A)
                delete A;
        }
        void setNumThreads(unsigned int num) {
            num_threads=num;
        }
        void setLogLevel(unsigned int num) {
            loglevel=num;
        }
        void setSparse(bool sparse) {
            this->sparse=sparse;
        }
        void setATol(double atol) {
            this->atol=atol;
        }
        void setRTol(double rtol) {
            this->rtol=rtol;
        }
        void setDenseOutput(bool dense) {
            if(dense) {
                info[2]=1;
            } else {
                info[2]=0;
            }
        }
        void setReverseJacobi(bool val) {
            reverseJacobi=val;
        }
        int solve(S_fp res, int& _dimSys, double& t, double *y, double *yprime, double& tout, void *par, Ja_fp jac, P_fp psol, UC_fp rt, int& nrt, int* jroot, bool cont);
    private:
        int ddaskr_(S_fp res, int *neq, double *t, double *y, double *yprime, double *tout, int *info, double *rtol, double *atol, int *idid, double *rwork, int *lrw, int *iwork, int *liw, void *par, Ja_fp jac, P_fp psol, UC_fp rt, int *nrt, int *jroot);
        int dmatd_(int *neq, double *x, double *y, double *yprime, double *delta, double *cj, double * h__, int *ier, double *ewt, double *e, double *wm, int *iwm, S_fp res, int *ires, double *uround, Jd_fp jacd, void *par);
        int dinvwt_(int *neq, double *wt, int *ier);
        int ddatrp_(double *, double *, double *, double *, int *, int *, double *, double *);
        int dhels_(double *, int *, int *, double*, double *);
        int dheqr_(double *, int *, int *, double *, int *, int *);
        int dorth_(double *vnew, double *v, double *hes, int *n, int *ll, int *ldhes, int *kmp, double * snormw);
        int ddasid_(double *x, double *y, double *yprime, int *neq, int *icopt, int *id, S_fp res, Jd_fp jacd, double *pdum, double *h__, double *tscale, double *wt, int *jsdum, void *par, double *dumsvr, double *delta, double *r__, double *yic, double *ypic,
             double *dumpwk, double *wm, int *iwm, double *cj, double *uround, double *dume, double *dums, double * dumr, double *epcon, double *ratemx, double *stptol, int *jfdum, int *icnflg, int *icnstr, int *iernls);
        int ddasik_(double *x, double *y, double *yprime, int *neq, int *icopt, int *id, S_fp res, J_fp jack, P_fp psol, double *h__, double *tscale, double *wt, int * jskip,  void *par, double *savr, double * delta, double *r__, double *yic, double *ypic,
                     double *pwk, double *wm, int *iwm, double *cj, double * uround, double *epli, double *sqrtn, double *rsqrtn, double *epcon, double *ratemx, double *stptol, int * jflg, int *icnflg, int *icnstr, int *iernls);
        int dnedd_(double *x, double *y, double *yprime, int *neq, S_fp res, Jd_fp jacd, double *pdum, double *h__, double *wt, int *jstart, int *idid,  void *par, double *phi, double *gamma, double *savr, double *delta, double *e, double *wm, int *iwm, double *cj, double *cjold, double *cjlast, double *s, double *uround, double *dume, double *dums, double * dumr, double *epcon, int *jcalc, int *jfdum, int *kp1, int *nonneg, int *ntype, int *iernls);
        int dnedk_(double *x, double *y, double *yprime, int *neq, S_fp res, J_fp  jack, P_fp psol,    double *h__, double *wt, int *jstart, int *idid,  void *par, double *phi, double *gamma, double *savr, double *delta, double *e, double *wm, int *iwm, double *cj, double *cjold, double *cjlast, double *s, double *uround, double *epli, double *sqrtn, double * rsqrtn, double *epcon, int *jcalc, int *jflg, int * kp1, int *nonneg, int *ntype, int *iernls);

        int ddstp_(double *x, double *y, double *yprime, int *neq, S_fp res, Ja_fp jac, P_fp psol, double *h__, double *wt, double *vt, int *jstart, int *idid, void *par, double *phi, double *savr, double *delta, double *e, double *wm, int *iwm,
                    double *alpha, double *beta, double *gamma, double * psi, double *sigma, double *cj, double *cjold, double *hold, double *s, double *hmin, double *uround, double *epli, double *sqrtn, double *rsqrtn, double * epcon, int *iphase, int *jcalc,
                    int *jflg, int *k, int *kold, int *ns, int *nonneg, int *ntype);
        int dcnst0_(int *neq, double *y, int *icnstr, int *iret);
        int ddasic_(double *x, double *y, double *yprime, int *neq, int *icopt, int *id, S_fp res, Ja_fp jac, P_fp psol, double *h__, double *tscale, double *wt, int * nic, int *idid, void *par, double *phi, double *savr, double *delta, double *e, double *yic,
                    double *ypic, double *pwk, double *wm, int *iwm, double *uround, double *epli, double *sqrtn, double *rsqrtn, double *epconi, double *stptol, int *jflg, int *icnflg, int *icnstr);
        int drchek_(int *job, UC_fp rt, int *nrt, int *neq, double *tn, double *tout, double *y, double *yp, double *phi, double *psi, int *kold, double *r0, double *r1, double *rx, int *jroot, int *irt, double *uround, int *info3, double *rwork, int *iwork,
                    void *par);
        int datv_(int *neq, double *y, double *tn, double *yprime, double *savr, double *v, double *wght, double *yptem, S_fp res, int *ires, P_fp psol, double * z__, double *vtem, double *wp, int *iwp, double *cj,
                    double *eplin, int *ier, int *nre, int *npsl, void *par);
        int ddawts_(int *neq, int *iwt, double *rtol, double *atol, double *y, double *wt, void *par);
        int dslvd_(int *neq, double *delta, double *wm, int *iwm);
        int dlinsd_(int *neq, double *y, double *t, double *yprime, double *cj, double *tscale, double *p, double *pnrm, double *wt, int *lsoff, double *stptol, int *iret, S_fp res, int *ires, double *wm, int *iwm, double *fnrm, int *icopt, int *id, double *r__,
                    double *ynew, double *ypnew, int *icnflg, int *icnstr, double *rlx, void *par);
        int dfnrmd_(int *neq, double *y, double *t, double *yprime, double *r__, double *cj, double * tscale, double *wt, S_fp res, int *ires, double *fnorm, double *wm, int *iwm, void *par);
        int dcnstr_(int *neq, double *y, double *ynew, int *icnstr, double *tau, double *rlx, int *iret, int *ivar);
        int dspigm_(int *neq, double *tn, double *y, double *yprime, double *savr, double *r__, double * wght, int *maxl, int *maxlp1, int *kmp, double *eplin, double *cj, S_fp res, int *ires, int *nre, P_fp psol, int *npsl, double *z__, double *v, double *hes,
            double *q, int *lgmr, double *wp, int *iwp, double *wk, double *dl, double *rhok, int *iflag, int *irst, int *nrsts, void *par);
        int droots_(int *nrt, double *hmin, int *jflag, double *x0, double *x1, double *r0, double *r1, double *rx, double *x, int *jroot);
        int dnsid_(double *x, double *y, double *yprime, int *neq, int *icopt, int *id, S_fp res, double *wt, void *par, double *delta, double *r__, double *yic, double *ypic, double *wm, int *iwm, double *cj, double *tscale, double *epcon, double *
            ratemx, int *maxit, double *stptol, int *icnflg, int * icnstr, int *iernew);
        int dnsd_(double *x, double *y, double *yprime, int *neq, S_fp res, double *pdum, double *wt, void *par, double *dumsvr, double *delta, double *e, double *wm, int *iwm, double *cj, double *dums, double *dumr, double *dume, double * epcon,
                    double *s, double *confac, double *tolnew, int *muldel, int *maxit, int *ires, int *idum, int * iernew);
        int dnsik_(double *x, double *y, double *yprime, int *neq, int *icopt, int *id, S_fp res, P_fp psol, double *wt, void *par, double *savr, double *delta, double *r__, double *yic, double *ypic, double *pwk, double *wm, int *iwm, double *cj,
                    double *tscale, double *sqrtn, double *rsqrtn, double *eplin, double *epcon, double *ratemx, int *maxit, double *stptol, int *icnflg, int *icnstr, int *iernew);
        int dslvk_(int *neq, double *y, double *tn, double *yprime, double *savr, double *x, double *ewt, double *wm, int *iwm, S_fp res, int *ires, P_fp psol, int *iersl, double *cj, double *eplin, double *sqrtn, double *rsqrtn, double *rhok, void *par);
        int dfnrmk_(int *neq, double *y, double *t, double *yprime, double *savr, double *r__, double *cj, double *tscale, double *wt, double *sqrtn, double * rsqrtn, S_fp res, int *ires, P_fp psol, int *irin, int * ier, double *fnorm, double *eplin, double *wp,
                    int *iwp, double *pwk, void *par);
        int dlinsk_(int *neq, double *y, double *t, double *yprime, double *savr, double *cj, double * tscale, double *p, double *pnrm, double *wt, double *sqrtn, double *rsqrtn, int *lsoff, double *stptol, int *iret, S_fp res, int *ires, P_fp psol, double *wm,
                    int *iwm, double *rhok, double *fnrm, int *icopt, int *id, double *wp, int *iwp, double *r__, double *eplin, double *ynew, double *ypnew, double *pwk, int *icnflg, int *icnstr, double *rlx, void * par);
        int dnsk_(double *x, double *y, double *yprime, int *neq, S_fp res, P_fp psol, double *wt, void *par, double *savr, double *delta, double *e, double *wm, int *iwm, double *cj, double *sqrtn, double *rsqrtn, double *eplin, double *epcon, double *s, double *confac, double *tolnew, int *muldel, int *maxit, int *ires, int *iersl, int *iernew);
        double ddwnrm_(int *, double *, double *, void *);
        int dyypnw_(int *neq, double *y, double *yprime, double *cj, double *rl, double *p, int *icopt,	int *id, double *ynew, double *ypnew);
        int xerrwd_(int *nerr, int *level, int *ni, int *i1, int *i2, int *nr, double *r1, double *r2, int msg_len);
        std::vector<int> info;
        std::vector<int> iwork;
        std::vector<double> rwork;
        int lrw;
        int liw;
        int idid;
        double rtol;
        double atol;
        unsigned int num_threads;
        unsigned int loglevel;
        bool sparse;
        umf::symbolic_type<double>* Symbolic;
        umf::numeric_type<double>* Numeric;
        sparsematrix_t* A;
        bool init;
        bool reverseJacobi;
};
