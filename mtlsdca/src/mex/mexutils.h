#ifndef MTLSDCA_MEX_MEXUTILS_H_
#define MTLSDCA_MEX_MEXUTILS_H_

#include <strings.h>
#include <cstddef>

#include "mex.h"

#include "sdca/types.h"


const char *errInvalidArgument = "SDCA:invalidArgument";
const char *errOutOfMemory = "SDCA:outOfMemory";
const char *errSolverError = "SDCA:solverError";

template <typename T>
mxArray *mxCreatePrecisionString();

template <>
mxArray *mxCreatePrecisionString<float>() {
  return mxCreateString("float");
}

template <>
mxArray *mxCreatePrecisionString<double>() {
  return mxCreateString("double");
}

sdca::SdcaSize *mxCreateLabelsVector(const mxArray *mxY,
  sdca::SdcaSize *min_label, sdca::SdcaSize *max_label) {
  if (!mxIsDouble(mxY)) {
    mexErrMsgIdAndTxt(errInvalidArgument, "Y must be double.");
  }
  if (mxGetM(mxY) != 1 && mxGetN(mxY) != 1) {
    mexErrMsgIdAndTxt(errInvalidArgument, "Y must be a vector.");
  }

  size_t N = mxGetM(mxY) > mxGetN(mxY) ? mxGetM(mxY) : mxGetN(mxY);
  sdca::SdcaSize *Y = static_cast<sdca::SdcaSize *>(mxMalloc(N * sizeof(*Y)));
  if (Y == NULL) {
    mexErrMsgIdAndTxt(errOutOfMemory, "Failed to allocate memory for Y.");
  }

  *min_label = 1;
  *max_label = 0;
  double *y = mxGetPr(mxY);
  for (size_t i = 0; i < N; ++i) {
    if (y[i] < 1.0) {
      mexErrMsgIdAndTxt(errInvalidArgument, "Labels must be in the range 1:T.");
    } else {
      Y[i] = static_cast<sdca::SdcaSize>(y[i] - 1);
      if (Y[i] < *min_label) *min_label = Y[i];
      if (Y[i] > *max_label) *max_label = Y[i];
    }
  }

  return Y;
}


mxArray *mxCreateScalar(double x) {
  mxArray *array = mxCreateDoubleMatrix(1, 1, mxREAL);
  *mxGetPr(array) = x;
  return array;
}

mxArray *mxCreateEye(size_t n, mxClassID classid) {
  mxArray *array = mxCreateNumericMatrix(n, n, classid, mxREAL);
  if (array) {
    if (classid == mxSINGLE_CLASS) {
      float *a = (float*) mxGetData(array);
      for (size_t i = 0; i < n; i++) {
        a[i*(n+1)] = 1.0f;
      }
    } else if (classid == mxDOUBLE_CLASS) {
      double *a = (double*) mxGetData(array);
      for (size_t i = 0; i < n; i++) {
        a[i*(n+1)] = 1.0;
      }
    } else {
      mxDestroyArray(array); array = NULL;
      mexErrMsgIdAndTxt(errInvalidArgument, "ClassID not supported.");
    }
  }
  return array;
}

int mxIsString(const mxArray *array, long int length) {
  std::size_t M = mxGetM(array);
  std::size_t N = mxGetN(array);

  return mxIsChar(array)
    && mxGetNumberOfDimensions(array) == 2
    && (M == 1 || (M == 0 && N == 0))
    && (length < 0 || N == (std::size_t) length);
}

void mxVerifySparseNotEmpty(const mxArray *x, const char *name) {
  if (!mxIsSparse(x)) {
    mexErrMsgIdAndTxt(errInvalidArgument, "%s must be sparse.", name);
  }
  if (mxIsEmpty(x)) {
    mexErrMsgIdAndTxt(errInvalidArgument, "%s must be non-empty.", name);
  }
}

void mxVerifyNotSparseNotEmpty(const mxArray *x, const char *name) {
  if (mxIsSparse(x)) {
    mexErrMsgIdAndTxt(errInvalidArgument, "%s must be full.", name);
  }
  if (mxIsEmpty(x)) {
    mexErrMsgIdAndTxt(errInvalidArgument, "%s must be non-empty.", name);
  }
}

void mxVerifySingleOrDouble(const mxArray *x, const char *name) {
  if (!(mxIsSingle(x) || mxIsDouble(x))) {
    mexErrMsgIdAndTxt(errInvalidArgument, "%s must be single or double.", name);
  }
}

void mxVerifyFunctionHandle(const mxArray *x, const char *name) {
  if (!mxIsFunctionHandle(x)) {
    mexErrMsgIdAndTxt(errInvalidArgument,
      "%s must be a function handle.", name);
  }
}

void mxVerifySameClass(const mxArray *x, const mxArray *y,
                       const char *nx, const char *ny) {
  if (mxGetClassID(x) != mxGetClassID(y)) {
    mexErrMsgIdAndTxt(errInvalidArgument,
      "%s and %s must be of the same type.", nx, ny);
  }
}

void mxVerifyVectorDimension(const mxArray *x, std::size_t n, const char *nx) {
  if (!( (mxGetM(x) == n && mxGetN(x) == 1)
      || (mxGetM(x) == 1 && mxGetN(x) == n) )) {
    mexErrMsgIdAndTxt(errInvalidArgument, "%s must be a %u dim vector.", nx, n);
  }
}

void mxVerifyMatrixDimensions(const mxArray *x, std::size_t m, std::size_t n,
                        const char *nx) {
  if (m > 0 && mxGetM(x) != m) {
    mexErrMsgIdAndTxt(errInvalidArgument, "%s must have %u row(s).", nx, m);
  }
  if (n > 0 && mxGetN(x) != n) {
    mexErrMsgIdAndTxt(errInvalidArgument, "%s must have %u column(s).", nx, n);
  }
}

double mxGetPositiveScalar(mxArray const *src, const char *name) {
  if (src) {
    double value = mxGetScalar(src);
    if (!(value > 0)) {
      mexErrMsgIdAndTxt(errInvalidArgument, "%s is not positive.", name);
    } else {
      return value;
    }
  }
  mexErrMsgIdAndTxt(errInvalidArgument, "%s is NULL.", name);
  return 0.0;
}

void mxSetPositiveScalar(mxArray const *src, const char *name, double *tgt) {
  if (src) {
    double value = mxGetScalar(src);
    if (!(value > 0)) {
      mexErrMsgIdAndTxt(errInvalidArgument, "%s is not positive.", name);
    } else {
      *tgt = value;
    }
  }
  mexErrMsgIdAndTxt(errInvalidArgument, "%s is NULL.", name);
}

double mxGetNonNegativeScalar(mxArray const *src, const char *name) {
  if (src) {
    double value = mxGetScalar(src);
    if (value < 0) {
      mexErrMsgIdAndTxt(errInvalidArgument, "%s is negative.", name);
    } else {
      return value;
    }
  }
  mexErrMsgIdAndTxt(errInvalidArgument, "%s is NULL.", name);
  return 0.0;
}

void mxSetNonNegativeScalar(mxArray const *src, const char *name,
                            double *tgt) {
  if (src) {
    double value = mxGetScalar(src);
    if (value < 0) {
      mexErrMsgIdAndTxt(errInvalidArgument, "%s is negative.", name);
    } else {
      *tgt = value;
    }
  }
  mexErrMsgIdAndTxt(errInvalidArgument, "%s is NULL.", name);
}

mxArray * createScalarStructArray(void const **fields) {
  void const **iter;
  char const **niter;
  char const **names;
  int numFields = 0;
  mxArray *s;
  mwSize dims [] = {1, 1};

  for (iter = fields; *iter; iter += 2) {
    numFields++;
  }

  names = static_cast<const char **>(
    mxCalloc((std::size_t) numFields, sizeof(char const*)));

  for (iter = fields, niter = names; *iter; iter += 2, niter++) {
    *niter = static_cast<const char *>(*iter);
  }

  s = mxCreateStructArray(2, dims, numFields, names);
  for (iter = fields, niter = names; *iter; iter += 2, niter++) {
    mxSetField(s, 0, *niter, (mxArray*)(*(iter+1))) ;
  }
  return s ;
}


/* ---------------------------------------------------------------- */
/*                        Options handling                          */
/* ---------------------------------------------------------------- */

typedef struct mxOption_ {
  const char *name;
  int has_arg;
  int value;
} mxOption;

int mxNextOption(
  mxArray const *args[],
  int nargs,
  mxOption  const *options,
  int *next,
  mxArray const **optarg
  ) {
  char name [1024];
  int opt = -1, i;

  if (*next >= nargs) {
    return opt;
  }

  /* check the array is a string */
  if (!mxIsString(args[*next], -1)) {
    mexErrMsgIdAndTxt(errInvalidArgument,
      "The option name is not a string (argument number %d)", *next + 1);
  }

  /* retrieve option name */
  if (mxGetString(args[*next], name, sizeof(name))) {
    mexErrMsgIdAndTxt(errInvalidArgument,
      "The option name is too long (argument number %d)", *next + 1);
  }

  /* advance argument list */
  ++(*next);

  /* now lookup the string in the option table */
  for (i = 0; options[i].name != 0; ++i) {
    if (strcasecmp(name, options[i].name) == 0) {
      opt = options[i].value;
      break;
    }
  }

  /* unknown argument */
  if (opt < 0) {
    mexErrMsgIdAndTxt(errInvalidArgument, "Unknown option '%s'.", name);
  }

  /* no argument */
  if (!options[i].has_arg) {
    if (optarg) *optarg = 0;
    return opt;
  }

  /* argument */
  if (*next >= nargs) {
    mexErrMsgIdAndTxt(errInvalidArgument,
      "Option '%s' requires an argument.", options[i].name);
  }

  if (optarg) *optarg = args[*next];
  ++(*next);
  return opt;
}

#endif // MTLSDCA_MEX_MEXUTILS_H_
