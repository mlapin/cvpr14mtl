/******************************************************************************
* L2 normalize a matrix columnwise (in place)
*
* Inputs:
*   X       M-by-N matrix to normalize
*
* Outputs:
*   X       M-by-N normalized matrix
*
******************************************************************************/

#include "mex.h"

#include "mexutils.h"
#include "sdca/types.h"

void printUsage() {
  mexPrintf("Usage: norm2(X);\n"
            "       [Xnorm] = norm2(X,d);\n\n");
}

void mexFunction(int nout, mxArray* out[], int nin, const mxArray* in[]) {

  enum {IN_X = 0, IN_END};
  enum {OUT_X = 0, OUT_END};

  if (nin < IN_END) {
    printUsage();
    mexErrMsgIdAndTxt(errInvalidArgument, "Too few input arguments.");
  }
  if (nout > OUT_END) {
    printUsage();
    mexErrMsgIdAndTxt(errInvalidArgument, "Too many output arguments.");
  }

  // X
  mxArray *mxX = (mxArray*) in[IN_X];
  if (mxIsSparse(mxX)) {
    mexErrMsgIdAndTxt(errInvalidArgument, "X must not be sparse.");
  }
  if (nout >= OUT_X + 1) {
    mxX = mxDuplicateArray(mxX);
    out[OUT_X] = mxX;
  }

  size_t D = mxGetM(mxX);
  if (nin > IN_END) {
    if (mxIsEmpty(in[IN_END])) {
      mexErrMsgIdAndTxt(errInvalidArgument, "D must not be empty.");
    }
    D = (size_t) mxGetScalar(in[IN_END]);
    if (D <= 0) {
      mexErrMsgIdAndTxt(errInvalidArgument, "D must be positive.");
    }
    if (D > mxGetM(mxX)) {
      mexErrMsgIdAndTxt(errInvalidArgument, "D is too large.");
    }
  }

  sdca::BlasInt m = static_cast<sdca::BlasInt>(mxGetM(mxX));
  sdca::BlasInt n = static_cast<sdca::BlasInt>(mxGetN(mxX));
  sdca::BlasInt d = static_cast<sdca::BlasInt>(D);
  if (mxIsSingle(mxX)) {
    float *A = static_cast<float*>(mxGetData(mxX));
    float norm, *last = A + m * n;
    while (A != last) {
      norm = sdca::snrm2(&d, A, &sdca::kIncrement);
      if (norm > 0.0f) {
        norm = 1.0f / norm;
        sdca::sscal(&d, &norm, A, &sdca::kIncrement);
      }
      A += m;
    }
  } else if (mxIsDouble(mxX)) {
    double *A = static_cast<double*>(mxGetData(mxX));
    double norm, *last = A + m * n;
    while (A != last) {
      norm = sdca::dnrm2(&d, A, &sdca::kIncrement);
      if (norm > 0.0) {
        norm = 1.0 / norm;
        sdca::dscal(&d, &norm, A, &sdca::kIncrement);
      }
      A += m;
    }
  } else {
    mexErrMsgIdAndTxt(errInvalidArgument, "X must be single or double.");
  }
}
