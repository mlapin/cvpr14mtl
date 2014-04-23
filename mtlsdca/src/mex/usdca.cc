/******************************************************************************
* USDCA algorithm
*
* Inputs:
*   Y       N-by-1 vector of labels in the range 1:T
*             where T is the number of tasks/classes
*
*   K       N-by-N Gram matrix; K = X' * X
*             type: full float/double matrix
*
*   M       T-by-T Gram matrix = W' * W
*             type: full float/double matrix (same type as K)
*
*   mu      1-by-1 scalar regularization parameter
*             must be positive
*
* Outputs:
*   A       N-by-T matrix of dual variables
*             type: full float/double matrix (same type as K)
*             note: the D-by-T matrix U is given by
*               U = X * A * W';
*
*   info    structure with the solver parameters and solution information
*
******************************************************************************/

#include "mex.h"

#include "mexutils.h"
#include "sdca/usolver.h"

void printUsage() {
  mexPrintf("Usage: A = usdca(Y,K,M,mu);\n"
            "       [A,info] = usdca(Y,K,M,mu,<options>);\n\n"
            "Options with arguments (default):\n"
            "  Epsilon (%g)\n"
            "  MaxNumEpoch (%d)\n"
            "  CheckGapFrequency (%d)\n"
            "  Seed (%d)\n"
            "Options without arguments:\n"
            "  SkipLabelsCheck\n"
            "The D-by-T matrix U is given by:\n"
            "  U = X * A * W';\n"
            "\n",
            sdca::USolver<double>::DefaultEpsilon(),
            sdca::USolver<double>::DefaultMaxNumEpoch(),
            sdca::USolver<double>::DefaultCheckGapFrequency(),
            sdca::USolver<double>::DefaultSeed());
}

/* option codes */
enum {
  opt_epsilon,
  opt_max_num_epoch,
  opt_check_gap_frequency,
  opt_seed,
  opt_skip_labels_check
};

/* options */
mxOption  options [] = {
  {"Epsilon",                   1, opt_epsilon},
  {"MaxNumEpoch",               1, opt_max_num_epoch},
  {"CheckGapFrequency",         1, opt_check_gap_frequency},
  {"Seed",                      1, opt_seed},
  {"SkipLabelsCheck",           0, opt_skip_labels_check},
  {0,                           0, 0}
};

/* info struct */
template <typename T>
mxArray * createInfoStruct(sdca::USolver<T> &solver) {
  void const *fields [] = {
    "Solver", mxCreateString("USDCA"),
    "Status", mxCreateScalar(static_cast<double>(solver.status())),
    "StatusName", mxCreateString(sdca::status_to_string(solver.status())),
    "CpuTime", mxCreateScalar(static_cast<double>(solver.cpu_time())),
    "NumExamples", mxCreateScalar(static_cast<double>(solver.num_examples())),
    "NumTasks", mxCreateScalar(static_cast<double>(solver.num_tasks())),
    "C", mxCreateScalar(static_cast<double>(solver.C())),
    "Mu", mxCreateScalar(static_cast<double>(solver.mu())),
    "PrimalLoss", mxCreateScalar(static_cast<double>(solver.primal_loss())),
    "DualLoss", mxCreateScalar(static_cast<double>(solver.dual_loss())),
    "Regularizer", mxCreateScalar(static_cast<double>(solver.regularizer())),
    "Primal", mxCreateScalar(static_cast<double>(solver.primal_objective())),
    "Dual", mxCreateScalar(static_cast<double>(solver.dual_objective())),
    "AbsoluteGap", mxCreateScalar(static_cast<double>(solver.absolute_gap())),
    "RelativeGap", mxCreateScalar(static_cast<double>(solver.relative_gap())),
    "Epsilon", mxCreateScalar(static_cast<double>(solver.epsilon())),
    "Epoch", mxCreateScalar(static_cast<double>(solver.epoch())),
    "MaxNumEpoch", mxCreateScalar(static_cast<double>(solver.max_num_epoch())),
    "CheckGapFrequency", mxCreateScalar(
      static_cast<double>(solver.check_gap_frequency())),
    "Seed", mxCreateScalar(static_cast<double>(solver.seed())),
    "Precision", mxCreatePrecisionString<T>(),
    0, 0
  };
  return createScalarStructArray(fields);
}

template <typename Q>
void run(const int nin, const mxArray* in[], const int in_next,
  const int nout, const mxArray *mxY, const mxArray *mxK, const mxArray *mxM,
  const double mu, mxArray **pA, mxArray **pInfo) {

  // Dimensions
  size_t N = mxGetM(mxK);
  size_t T = mxGetM(mxM);

  mxVerifyVectorDimension(mxY, N, "Y");
  mxVerifyMatrixDimensions(mxK, N, N, "K");
  mxVerifyMatrixDimensions(mxM, T, T, "M");
  mxVerifySameClass(mxK, mxM, "K", "M");

  // Create labels vector
  sdca::SdcaSize min_label, max_label;
  sdca::SdcaSize *Y = mxCreateLabelsVector(mxY, &min_label, &max_label);

  /*
   * Allocate memory for output data
   */
  mwSize mxDims[2] = {N, T};
  mxArray *mxA = mxCreateNumericArray(
    (mwSize) 2, mxDims, mxGetClassID(mxK), mxREAL);
  if (mxA == NULL) {
    mexErrMsgIdAndTxt(errOutOfMemory, "Failed to allocate memory for A.");
  }

  sdca::USolver<Q> solver(static_cast<sdca::SdcaSize>(N),
    static_cast<sdca::SdcaSize>(T), Y, static_cast<Q*>(mxGetData(mxK)),
    static_cast<Q*>(mxGetData(mxM)), static_cast<Q*>(mxGetData(mxA)));

  solver.mu(static_cast<Q>(mu));

  /*
   * Parse optional arguments
   */
  bool skip_labels_check = false;
  int opt = 0, next = in_next;
  mxArray const *optarg = NULL;
  while ((opt = mxNextOption(in, nin, options, &next, &optarg)) >= 0) {
    switch (opt) {
      case opt_epsilon:
        solver.epsilon(static_cast<Q>(
          mxGetNonNegativeScalar(optarg, "Epsilon")));
        break;
      case opt_max_num_epoch:
        solver.max_num_epoch(static_cast<sdca::SdcaSize>(
          mxGetNonNegativeScalar(optarg, "MaxNumEpoch")));
        break;
      case opt_check_gap_frequency:
        solver.check_gap_frequency(static_cast<sdca::SdcaSize>(
          mxGetNonNegativeScalar(optarg, "CheckGapFrequency")));
        break;
      case opt_seed:
        solver.seed(static_cast<sdca::SdcaSize>(
          mxGetNonNegativeScalar(optarg, "Seed")));
        break;
      case opt_skip_labels_check:
        skip_labels_check = true;
        break;
    }
  }

  // Check labels range
  if (!skip_labels_check) {
    if (min_label != 0 || max_label != T - 1) {
      mexErrMsgIdAndTxt(errInvalidArgument,
        "Labels must be in the range [1:T]; current range: [%d:%d].",
        min_label + 1, max_label + 1);
    }
  }

  if (nout > 0) {
    // Compute mxA
    solver.Train();
    *pA = mxA;
  }
  if (nout > 1) {
    // Compute mxInfo
    mxArray *mxInfo = createInfoStruct<Q>(solver);
    *pInfo = mxInfo;
  }

  mxFree(Y);
}

void mexFunction(int nout, mxArray* out[], int nin, const mxArray* in[]) {

  enum {IN_Y = 0, IN_K, IN_M, IN_MU, IN_END};
  enum {OUT_A = 0, OUT_INFO, OUT_END};

  if (nin < IN_END) {
    printUsage();
    mexErrMsgIdAndTxt(errInvalidArgument, "Too few input arguments.");
  }
  if (nout > OUT_END) {
    printUsage();
    mexErrMsgIdAndTxt(errInvalidArgument, "Too many output arguments.");
  }

  // Y
  mxArray const *mxY = in[IN_Y];
  mxVerifyNotSparseNotEmpty(mxY, "Y");

  // K
  mxArray const *mxK = in[IN_K];
  mxVerifyNotSparseNotEmpty(mxK, "K");
  mxVerifySingleOrDouble(mxK, "K");

  // M
  mxArray const *mxM = in[IN_M];
  mxVerifyNotSparseNotEmpty(mxM, "M");
  mxVerifySingleOrDouble(mxM, "M");

  // mu
  if (mxIsEmpty(in[IN_MU])) {
    mexErrMsgIdAndTxt(errInvalidArgument, "Mu must not be empty.");
  }
  double mu = mxGetScalar(in[IN_MU]);
  if (!(mu > 0.0)) {
    mexErrMsgIdAndTxt(errInvalidArgument, "Mu must be positive.");
  }

  mxArray *mxA = NULL;
  mxArray *mxInfo = NULL;
  try {
    if (mxIsSingle(mxK)) {
      run<float>(nin, in, IN_END, nout, mxY, mxK, mxM, mu, &mxA, &mxInfo);
    } else {
      run<double>(nin, in, IN_END, nout, mxY, mxK, mxM, mu, &mxA, &mxInfo);
    }
  } catch (std::exception &ex) {
      mexErrMsgIdAndTxt(errSolverError, "USDCA: %s", ex.what());
  } catch(...) {
    mexErrMsgIdAndTxt(errSolverError, "USDCA: exception occurred.");
  }

  if (nout >= OUT_A + 1) {
    out[OUT_A] = mxA;
  }
  if (nout >= OUT_INFO + 1) {
    out[OUT_INFO] = mxInfo;
  }
}
