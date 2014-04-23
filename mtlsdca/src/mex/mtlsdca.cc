/******************************************************************************
* MTLSDCA algorithm
*
* Inputs:
*   Y       N-by-1 vector of labels in the range 1:T
*             where T is the number of tasks/classes
*
*   Kx      N-by-N Gram matrix (full dimensional features); Kx = X' * X
*             type: full float/double matrix
*
*   Kz      N-by-N Gram matrix (lower dimensional features); Kz = Z' * Z
*             type: full float/double matrix (same type as Kx)
*
*   lambda,
*   mu      1-by-1 scalar regularization parameters
*             must be positive
*
* Outputs:
*   A       N-by-T matrix of dual variables corresponding to the matrix U
*             type: full float/double matrix (same type as Kx)
*
*   Kw      T-by-T Gram matrix; Kw = W' * W
*             type: full float/double matrix (same type as Kx)
*
*   info    structure with the solver parameters and solution information
*
*   Kz      N-by-N Gram matrix (lower dimensional features) - updated
*             type: full float/double matrix (same type as Kx)
*
*   B       N-by-T matrix of dual variables corresponding to the matrix W
*             type: full float/double matrix (same type as K)
*
* Note:
*           Z = U' * X
*           U = X * A * W';
*           W = Z * B;
*
* Prediction scores (T-by-Ntst):
*           S = W' * U' * Xtst
*             = W' * W * A' * X' * Xtst
*             = Kw * A' * Ktst
*
******************************************************************************/

#include "mex.h"

#include "mexutils.h"
#include "sdca/mtlsolver.h"

void printUsage() {
  mexPrintf("Usage: [A,Kw] = mtlsdca(Y,Kx,Kz,lambda,mu);\n"
            "       [A,Kw,info,Kz,B] = mtlsdca(Y,Kx,Kz,lambda,mu,<options>);\n"
            "\n"
            "Options with arguments (default):\n"
            "  Epsilon (%g)\n"
            "  MaxNumIterations (%d)\n"
            "  Seed (%d)\n"
            "  SvmEpsilon (%g)\n"
            "  SvmMaxNumEpoch (%d)\n"
            "  SvmCheckGapFrequency (%d)\n"
            "  UEpsilon (%g)\n"
            "  UMaxNumEpoch (%d)\n"
            "  UCheckGapFrequency (%d)\n"
            "Options without arguments:\n"
            "  SkipLabelsCheck\n"
            "Prediction scores (T-by-Ntst):\n"
            "  S = Kw * A' * Ktst;\n"
            "\n",
            sdca::MtlSolver<double>::DefaultEpsilon(),
            sdca::MtlSolver<double>::DefaultMaxNumIter(),
            sdca::MtlSolver<double>::DefaultSeed(),
            sdca::SvmSolver<double>::DefaultEpsilon(),
            sdca::SvmSolver<double>::DefaultMaxNumEpoch(),
            sdca::SvmSolver<double>::DefaultCheckGapFrequency(),
            sdca::USolver<double>::DefaultEpsilon(),
            sdca::USolver<double>::DefaultMaxNumEpoch(),
            sdca::USolver<double>::DefaultCheckGapFrequency());
}

/* option codes */
enum {
  opt_epsilon,
  opt_max_num_iter,
  opt_seed,
  opt_svm_epsilon,
  opt_svm_max_num_epoch,
  opt_svm_check_gap_frequency,
  opt_u_epsilon,
  opt_u_max_num_epoch,
  opt_u_check_gap_frequency,
  opt_skip_labels_check
};

/* options */
mxOption  options [] = {
  {"Epsilon",                   1, opt_epsilon},
  {"MaxNumIterations",          1, opt_max_num_iter},
  {"Seed",                      1, opt_seed},
  {"SvmEpsilon",                1, opt_svm_epsilon},
  {"SvmMaxNumEpoch",            1, opt_svm_max_num_epoch},
  {"SvmCheckGapFrequency",      1, opt_svm_check_gap_frequency},
  {"UEpsilon",                  1, opt_u_epsilon},
  {"UMaxNumEpoch",              1, opt_u_max_num_epoch},
  {"UCheckGapFrequency",        1, opt_u_check_gap_frequency},
  {"SkipLabelsCheck",           0, opt_skip_labels_check},
  {0,                           0, 0}
};

/* info struct */
template <typename T>
mxArray * createInfoStruct(sdca::MtlSolver<T> &solver) {
  void const *fields [] = {
    "Solver", mxCreateString("MTLSDCA"),
    "Status", mxCreateScalar(static_cast<double>(solver.status())),
    "StatusName", mxCreateString(sdca::status_to_string(solver.status())),
    "CpuTime", mxCreateScalar(static_cast<double>(solver.cpu_time())),
    "NumExamples", mxCreateScalar(static_cast<double>(solver.num_examples())),
    "NumTasks", mxCreateScalar(static_cast<double>(solver.num_tasks())),
    "Lambda", mxCreateScalar(static_cast<double>(solver.svm_solver().lambda())),
    "Mu", mxCreateScalar(static_cast<double>(solver.u_solver().mu())),
    "RMSE", mxCreateScalar(static_cast<double>(solver.rmse())),
    "Objective", mxCreateScalar(static_cast<double>(solver.objective())),
    "Epsilon", mxCreateScalar(static_cast<double>(solver.epsilon())),
    "Iteration", mxCreateScalar(static_cast<double>(solver.iter())),
    "MaxNumIterations", mxCreateScalar(
      static_cast<double>(solver.max_num_iter())),
    "Seed", mxCreateScalar(static_cast<double>(solver.seed())),
    "Precision", mxCreatePrecisionString<T>(),

    "SvmStatus", mxCreateScalar(static_cast<double>(
      solver.svm_solver().status())),
    "SvmStatusName", mxCreateString(sdca::status_to_string(
      solver.svm_solver().status())),
    "SvmPrimalLoss", mxCreateScalar(static_cast<double>(
      solver.svm_solver().primal_loss())),
    "SvmDualLoss", mxCreateScalar(static_cast<double>(
      solver.svm_solver().dual_loss())),
    "SvmRegularizer", mxCreateScalar(static_cast<double>(
      solver.svm_solver().regularizer())),
    "SvmPrimal", mxCreateScalar(static_cast<double>(
      solver.svm_solver().primal_objective())),
    "SvmDual", mxCreateScalar(static_cast<double>(
      solver.svm_solver().dual_objective())),
    "SvmAbsoluteGap", mxCreateScalar(static_cast<double>(
      solver.svm_solver().absolute_gap())),
    "SvmRelativeGap", mxCreateScalar(static_cast<double>(
      solver.svm_solver().relative_gap())),
    "SvmEpsilon", mxCreateScalar(static_cast<double>(
      solver.svm_solver().epsilon())),
    "SvmEpoch", mxCreateScalar(static_cast<double>(
      solver.svm_solver().epoch())),
    "SvmMaxNumEpoch", mxCreateScalar(static_cast<double>(
      solver.svm_solver().max_num_epoch())),
    "SvmCheckGapFrequency", mxCreateScalar(static_cast<double>(
      solver.svm_solver().check_gap_frequency())),

    "UStatus", mxCreateScalar(static_cast<double>(
      solver.u_solver().status())),
    "UStatusName", mxCreateString(sdca::status_to_string(
      solver.u_solver().status())),
    "UPrimalLoss", mxCreateScalar(static_cast<double>(
      solver.u_solver().primal_loss())),
    "UDualLoss", mxCreateScalar(static_cast<double>(
      solver.u_solver().dual_loss())),
    "URegularizer", mxCreateScalar(static_cast<double>(
      solver.u_solver().regularizer())),
    "UPrimal", mxCreateScalar(static_cast<double>(
      solver.u_solver().primal_objective())),
    "UDual", mxCreateScalar(static_cast<double>(
      solver.u_solver().dual_objective())),
    "UAbsoluteGap", mxCreateScalar(static_cast<double>(
      solver.u_solver().absolute_gap())),
    "URelativeGap", mxCreateScalar(static_cast<double>(
      solver.u_solver().relative_gap())),
    "UEpsilon", mxCreateScalar(static_cast<double>(
      solver.u_solver().epsilon())),
    "UEpoch", mxCreateScalar(static_cast<double>(
      solver.u_solver().epoch())),
    "UMaxNumEpoch", mxCreateScalar(static_cast<double>(
      solver.u_solver().max_num_epoch())),
    "UCheckGapFrequency", mxCreateScalar(static_cast<double>(
      solver.u_solver().check_gap_frequency())),

    0, 0
  };
  return createScalarStructArray(fields);
}

template <typename Q>
void run(const int nin, const mxArray* in[], const int in_next, const int nout,
  const mxArray *mxY, const mxArray *mxKx, const mxArray *mxKz,
  const double lambda, const double mu, mxArray **pA, mxArray **pKw,
  mxArray **pInfo, mxArray **pKzz, mxArray **pB) {

  // Dimensions
  size_t N = mxGetM(mxKx);
  size_t T = 0; // will be inferred from the contents of the vector Y

  mxVerifyVectorDimension(mxY, N, "Y");
  mxVerifyMatrixDimensions(mxKx, N, N, "Kx");
  mxVerifyMatrixDimensions(mxKz, N, N, "Kz");
  mxVerifySameClass(mxKx, mxKz, "Kx", "Kz");

  // Create labels vector
  sdca::SdcaSize min_label, max_label;
  sdca::SdcaSize *Y = mxCreateLabelsVector(mxY, &min_label, &max_label);
  T = max_label + 1;

  /*
   * Allocate memory for output data
   */
  mwSize mxDims[2] = {N, T};
  mxArray *mxA = mxCreateNumericArray(
    (mwSize) 2, mxDims, mxGetClassID(mxKx), mxREAL);
  if (mxA == NULL) {
    mexErrMsgIdAndTxt(errOutOfMemory, "Failed to allocate memory for A.");
  }

  mxDims = {T, T};
  mxArray *mxKw = mxCreateNumericArray(
    (mwSize) 2, mxDims, mxGetClassID(mxKx), mxREAL);
  if (mxKw == NULL) {
    mexErrMsgIdAndTxt(errOutOfMemory, "Failed to allocate memory for Kw.");
  }

  mxArray *mxKzz = mxDuplicateArray(mxKz);
  if (mxKzz == NULL) {
    mexErrMsgIdAndTxt(errOutOfMemory, "Failed to allocate memory for Kz.");
  }

  mxDims = {N, T};
  mxArray *mxB = mxCreateNumericArray(
    (mwSize) 2, mxDims, mxGetClassID(mxKx), mxREAL);
  if (mxB == NULL) {
    mexErrMsgIdAndTxt(errOutOfMemory, "Failed to allocate memory for B.");
  }

  sdca::MtlSolver<Q> solver(static_cast<sdca::SdcaSize>(N),
    static_cast<sdca::SdcaSize>(T), Y, static_cast<Q*>(mxGetData(mxKx)),
    static_cast<Q*>(mxGetData(mxKzz)), static_cast<Q*>(mxGetData(mxKw)),
    static_cast<Q*>(mxGetData(mxA)), static_cast<Q*>(mxGetData(mxB)));

  solver.svm_solver().lambda(static_cast<Q>(lambda));
  solver.u_solver().mu(static_cast<Q>(mu));

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
      case opt_max_num_iter:
        solver.max_num_iter(static_cast<sdca::SdcaSize>(
          mxGetNonNegativeScalar(optarg, "MaxNumIterations")));
        break;
      case opt_seed:
        solver.seed(static_cast<sdca::SdcaSize>(
          mxGetNonNegativeScalar(optarg, "Seed")));
        break;
      case opt_svm_epsilon:
        solver.svm_solver().epsilon(static_cast<Q>(
          mxGetNonNegativeScalar(optarg, "SvmEpsilon")));
        break;
      case opt_svm_max_num_epoch:
        solver.svm_solver().max_num_epoch(static_cast<sdca::SdcaSize>(
          mxGetNonNegativeScalar(optarg, "SvmMaxNumEpoch")));
        break;
      case opt_svm_check_gap_frequency:
        solver.svm_solver().check_gap_frequency(static_cast<sdca::SdcaSize>(
          mxGetNonNegativeScalar(optarg, "SvmCheckGapFrequency")));
        break;
      case opt_u_epsilon:
        solver.u_solver().epsilon(static_cast<Q>(
          mxGetNonNegativeScalar(optarg, "UEpsilon")));
        break;
      case opt_u_max_num_epoch:
        solver.u_solver().max_num_epoch(static_cast<sdca::SdcaSize>(
          mxGetNonNegativeScalar(optarg, "UMaxNumEpoch")));
        break;
      case opt_u_check_gap_frequency:
        solver.u_solver().check_gap_frequency(static_cast<sdca::SdcaSize>(
          mxGetNonNegativeScalar(optarg, "UCheckGapFrequency")));
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

  *pKw = mxKw;
  *pKzz = mxKzz;
  *pB = mxB;
  if (nout > 0) {
    // Compute mxA
    solver.Train();
    *pA = mxA;
  }
  if (nout > 2) {
    // Compute mxInfo
    mxArray *mxInfo = createInfoStruct<Q>(solver);
    *pInfo = mxInfo;
  }

  mxFree(Y);
}

void mexFunction(int nout, mxArray* out[], int nin, const mxArray* in[]) {

  enum {IN_Y = 0, IN_KX, IN_KZ, IN_LAMBDA, IN_MU, IN_END};
  enum {OUT_A = 0, OUT_KW, OUT_INFO, OUT_KZ, OUT_B, OUT_END};

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

  // Kx
  mxArray const *mxKx = in[IN_KX];
  mxVerifyNotSparseNotEmpty(mxKx, "Kx");
  mxVerifySingleOrDouble(mxKx, "Kx");

  // Kz
  mxArray const *mxKz = in[IN_KZ];
  mxVerifyNotSparseNotEmpty(mxKz, "Kz");
  mxVerifySingleOrDouble(mxKz, "Kz");

  // lambda
  if (mxIsEmpty(in[IN_LAMBDA])) {
    mexErrMsgIdAndTxt(errInvalidArgument, "Lambda must not be empty.");
  }
  double lambda = mxGetScalar(in[IN_LAMBDA]);
  if (!(lambda > 0.0)) {
    mexErrMsgIdAndTxt(errInvalidArgument, "Lambda must be positive.");
  }

  // mu
  if (mxIsEmpty(in[IN_MU])) {
    mexErrMsgIdAndTxt(errInvalidArgument, "Mu must not be empty.");
  }
  double mu = mxGetScalar(in[IN_MU]);
  if (!(mu > 0.0)) {
    mexErrMsgIdAndTxt(errInvalidArgument, "Mu must be positive.");
  }

  mxArray *mxA = NULL;
  mxArray *mxKw = NULL;
  mxArray *mxInfo = NULL;
  mxArray *mxB = NULL;
  mxArray *mxKzz = NULL;
  try {
    if (mxIsSingle(mxKx)) {
      run<float>(nin, in, IN_END, nout, mxY, mxKx, mxKz, lambda, mu,
        &mxA, &mxKw, &mxInfo, &mxKzz, &mxB);
    } else {
      run<double>(nin, in, IN_END, nout, mxY, mxKx, mxKz, lambda, mu,
        &mxA, &mxKw, &mxInfo, &mxKzz, &mxB);
    }
  } catch (std::exception &ex) {
      mexErrMsgIdAndTxt(errSolverError, "MTLSDCA: %s", ex.what());
  } catch(...) {
    mexErrMsgIdAndTxt(errSolverError, "MTLSDCA: exception occurred.");
  }

  if (nout >= OUT_A + 1) {
    out[OUT_A] = mxA;
  }
  if (nout >= OUT_KW + 1) {
    out[OUT_KW] = mxKw;
  }
  if (nout >= OUT_INFO + 1) {
    out[OUT_INFO] = mxInfo;
  }
  if (nout >= OUT_KZ + 1) {
    out[OUT_KZ] = mxKzz;
  }
  if (nout >= OUT_B + 1) {
    out[OUT_B] = mxB;
  }
}

