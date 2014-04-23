#ifndef MTLSDCA_SDCA_TYPES_H_
#define MTLSDCA_SDCA_TYPES_H_

namespace sdca {

#ifndef BLAS_INT_DEFINED
#define BLAS_INT_DEFINED

  #ifdef BLAS_INTEL_MKL

    #include "mkl_blas.h"
    typedef MKL_INT BlasInt;
    typedef BlasInt * BlasIntPtr;

    #define BLAS_CONST const

  #else // MATLAB MKL

    #include "blas.h"
    typedef ptrdiff_t BlasInt;
    typedef BlasInt * BlasIntPtr;

    #define BLAS_CONST

  #endif

#endif

BLAS_CONST char kTranspose = 'T';
BLAS_CONST char kNoTranspose = 'N';
BLAS_CONST BlasInt kIncrement = 1;

typedef unsigned int SdcaSize;

enum class SolverStatus {
  kNone = -100,
  kTraining = -1,
  kConverged = 0,
  kConvergedMachinePrecision = 1,
  kNoProgress = 2,
  kMaxNumEpoch = 3,
  kMaxNumIterations = 4,
  kNumericalProblems = 5
};

const char * status_to_string(const SolverStatus status) {
  switch (status) {
    case SolverStatus::kTraining:
      return "Training";
    case SolverStatus::kConverged:
      return "Converged";
    case SolverStatus::kConvergedMachinePrecision:
      return "ConvergedMachinePrecision";
    case SolverStatus::kNoProgress:
      return "NoProgress";
    case SolverStatus::kMaxNumEpoch:
      return "MaxNumEpoch";
    case SolverStatus::kMaxNumIterations:
      return "MaxNumIterations";
    case SolverStatus::kNumericalProblems:
      return "NumericalProblems";
    default:
      return "None";
    }
}

}

#endif // MTLSDCA_SDCA_TYPES_H_
