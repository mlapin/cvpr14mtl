#ifndef MTLSDCA_SDCA_MTLSOLVER_H
#define MTLSDCA_SDCA_MTLSOLVER_H

#include <cmath>

#include "usolver.h"

namespace sdca {

template <typename T>
class MtlSolver
{
public:
  inline static T DefaultEpsilon() { return static_cast<T>(1e-2); }
  inline static SdcaSize DefaultMaxNumIter() { return 1e+2; }
  inline static SdcaSize DefaultSeed() { return 0; }

  MtlSolver(const SdcaSize num_examples, const SdcaSize num_tasks,
    const SdcaSize *Y, const T *Kx, T *Kz, T *Kw, T *A, T *B);
  ~MtlSolver();

  void Train();

  SdcaSize num_examples() const;

  SdcaSize num_tasks() const;

  SvmSolver<T> & svm_solver() const;

  USolver<T> & u_solver() const;

  void epsilon(const T value);
  T epsilon() const;

  void max_num_iter(const SdcaSize value);
  SdcaSize max_num_iter() const;

  void seed(const SdcaSize value);
  SdcaSize seed() const;

  SdcaSize iter() const;

  SolverStatus status() const;

  T rmse() const;

  T objective() const;

  double cpu_time() const;

protected:
  inline void BeginTraining();
  inline void EndTraining();
  inline void SetBufferToKzB();
  inline void SetKwToBtKzB();
  inline void ComputeKxA();
  inline void SetBufferToKxAKw();
  inline void SetKzToKxAKwAtKx();
  inline bool CheckRMSE();
  inline void Subtract(T *x, T *y);
  inline void Copy(T *x, T *y);
  inline T Norm22(T *x);

  inline double cpu_time_now() const;

  // Problem specification
  const SdcaSize num_examples_; // N
  const SdcaSize num_tasks_;    // T
  const SdcaSize num_elements_; // N * T
  const SdcaSize *Y_; // class labels; N-by-1; values must be in [0,T-1]
  const T *Kx_;       // Gram matrix; Kx = X' * X; N-by-N
  T *Kz_;             // Kz = Z' * Z, where Z = U' * X; N-by-N
  T *Kw_;             // Kw = W' * W; T-by-T
  T *A_;              // dual vars for U = X * A * W'; N-by-T
  T *B_;              // dual vars for W = Z * B; N-by-T

  // Temporary memory buffers
  T *A_old_;          // previous iteration dual vars; N-by-T
  T *B_old_;          // previous iteration dual vars; N-by-T
  T *buffer_;         // shared memory buffer; N-by-T
  T *KxA_;            // additional memory buffer for Kx * A; N-by-T
  SdcaSize *indexes_; // N-by-1

  // Subproblem solvers
  SvmSolver<T> *svm_solver_;
  USolver<T> *u_solver_;

  // Master solver parameters
  T epsilon_;
  SdcaSize max_num_iter_;
  SdcaSize seed_;

  // Solution details/statistics
  T rmse_;
  SolverStatus status_;
  std::clock_t cpu_time_;

  // Current progress
  SdcaSize iter_;

  // Helper temporary variables
  bool variables_changed_;
  T objective_before_;
  T objective_after_;

  // Precomputed BLAS constants
  BLAS_CONST T zero_;
  BLAS_CONST T one_;
  BLAS_CONST T m_one_;
  BLAS_CONST BlasInt dim_n_;
  BLAS_CONST BlasInt dim_t_;
  BLAS_CONST BlasInt dim_nt_;

};


template <typename T>
MtlSolver<T>::MtlSolver(const SdcaSize num_examples, const SdcaSize num_tasks,
    const SdcaSize *Y, const T *Kx, T *Kz, T *Kw, T *A, T *B)
    : num_examples_(num_examples), num_tasks_(num_tasks),
      num_elements_(num_examples * num_tasks),
      Y_(Y), Kx_(Kx), Kz_(Kz), Kw_(Kw), A_(A), B_(B),
      zero_(0), one_(1), m_one_(-1), dim_n_(num_examples), dim_t_(num_tasks),
      dim_nt_(num_examples * num_tasks) {

  A_old_ = new T[num_elements_];
  B_old_ = new T[num_elements_];
  buffer_ = new T[num_elements_];
  KxA_ = new T[num_elements_];
  indexes_ = new SdcaSize[num_examples_];

  svm_solver_ = new SvmSolver<T>(num_examples_, num_tasks_, Y_, Kz_, B_,
    buffer_, indexes_);
  u_solver_ = new USolver<T>(num_examples_, num_tasks_, Y_, Kx_, Kw_, A_,
    buffer_, KxA_, indexes_);

  epsilon(DefaultEpsilon());
  max_num_iter(DefaultMaxNumIter());
  seed(DefaultSeed());

  rmse_ = std::numeric_limits<T>::infinity();
  status_ = SolverStatus::kNone;
  cpu_time_ = static_cast<std::clock_t>(0);

  iter_ = static_cast<SdcaSize>(0);
}

template <typename T>
MtlSolver<T>::~MtlSolver() {
  delete u_solver_;
  delete svm_solver_;
  delete[] indexes_;
  delete[] KxA_;
  delete[] buffer_;
  delete[] B_old_;
  delete[] A_old_;
}

template <typename T>
void MtlSolver<T>::Train() {

  BeginTraining();

  for (iter_ = 0; ; ) {

    variables_changed_ = false;

    svm_solver_->Train();     // Update B (W = Z * B)

    objective_after_ = objective();

    bool no_progress = svm_solver_->epoch() <= static_cast<SdcaSize>(1)
                       && svm_solver_->status() == SolverStatus::kNoProgress;
    bool objective_increased = objective_before_ < objective_after_;

    if (no_progress || objective_increased) {
#ifdef VERBOSE
      std::cout << "  Discard an update to B: "
        "no_progress: " << no_progress << ", "
        "objective_increased: " << objective_after_ - objective_before_
        << std::endl;
#endif

      Copy(B_old_, B_);       // Discard the update

    } else {                  // Keep the B update

      SetBufferToKzB();       // Kz * B
      SetKwToBtKzB();         // Kw = B' * Kz * B
      objective_before_ = objective_after_;
      variables_changed_ = true;

    }

    u_solver_->Train();       // Update A (U = X * A * W')

    objective_after_ = objective();

    no_progress = u_solver_->epoch() <= static_cast<SdcaSize>(1)
                  && u_solver_->status() == SolverStatus::kNoProgress;
    objective_increased = objective_before_ < objective_after_;

    if (no_progress || objective_increased) {
#ifdef VERBOSE
      std::cout << "  Discard an update to A: "
        "no_progress: " << no_progress << ", "
        "objective_increased: " << objective_after_ - objective_before_
        << std::endl;
#endif

      Copy(A_old_, A_);       // Discard the update

    } else {

      variables_changed_ = true;

    }

    if (CheckRMSE()) break;

    if (++iter_ >= max_num_iter_) break;

    if (!(no_progress || objective_increased)) {  // Keep the A update

      ComputeKxA();           // Kx * A
      SetBufferToKxAKw();     // Kx * A * Kw
      SetKzToKxAKwAtKx();     // Kz = Kx * A * Kw * A' * Kx
      objective_before_ = objective_after_;

    }

    Copy(A_, A_old_);         // A_old = A
    Copy(B_, B_old_);         // B_old = B
  }

  EndTraining();
}

template <typename T>
inline void MtlSolver<T>::BeginTraining() {
#ifdef VERBOSE
  std::cout << "MTLSDCA::Start(" << std::scientific << std::setprecision(16) <<
    "num_examples: " << num_examples() << ", "
    "num_tasks: " << num_tasks() << ", "
    "epsilon: " << epsilon() << ", "
    "max_num_iter: " << max_num_iter() << ")" << std::endl;
#endif

  cpu_time_ = std::clock();
  status_ = SolverStatus::kTraining;
  objective_before_ = std::numeric_limits<T>::infinity();
  objective_after_ = std::numeric_limits<T>::infinity();
  for (SdcaSize i = 0; i < num_elements_; ++i) {
    A_old_[i] = static_cast<T>(0);
    B_old_[i] = static_cast<T>(0);
  }
}

template <typename T>
inline void MtlSolver<T>::EndTraining() {
  if (status_ == SolverStatus::kTraining && iter_ >= max_num_iter_) {
    status_ = SolverStatus::kMaxNumIterations;
    if (iter_ > 0) --iter_; // correct to the last executed iteration
  }

  cpu_time_ = std::clock() - cpu_time_;

#ifdef VERBOSE
  std::cout << "MTLSDCA::End("
    "status: " << status_to_string(status()) << ", "
    "iter: " << iter() << ", "
    "rmse: " << rmse() << ", "
    "objective: " << objective() << ", "
    "cpu_time: " << cpu_time() << ")" << std::endl;
#endif
}

template <typename T>
inline bool MtlSolver<T>::CheckRMSE() {

  if (!variables_changed_) {
    status_ = SolverStatus::kNoProgress;
    return true;
  }

  rmse_ = static_cast<T>(0);

  Subtract(A_, A_old_);     // A_old -= A
  rmse_ += Norm22(A_old_);

  Subtract(B_, B_old_);     // B_old -= B
  rmse_ += Norm22(B_old_);

  rmse_ /= static_cast<T>(2 * num_elements_);
  rmse_ = std::sqrt(rmse_);

#ifdef VERBOSE
  std::cout << std::endl << "  "
    "iter: " << iter() << ", "
    "rmse: " << rmse() << ", "
    "objective: " << objective() << ", "
    "cpu_time: " << cpu_time_now() << std::endl << std::endl;
#endif

  if (rmse_ < epsilon_) {
    status_ = SolverStatus::kConverged;
    return true;
  }

  return false;
}


template <>
inline void MtlSolver<float>::SetBufferToKzB() {
  sgemm(&kNoTranspose, &kNoTranspose, &dim_n_, &dim_t_, &dim_n_,
    &one_, Kz_, &dim_n_, B_, &dim_n_, &zero_, buffer_, &dim_n_);
}

template <>
inline void MtlSolver<double>::SetBufferToKzB() {
  dgemm(&kNoTranspose, &kNoTranspose, &dim_n_, &dim_t_, &dim_n_,
    &one_, Kz_, &dim_n_, B_, &dim_n_, &zero_, buffer_, &dim_n_);
}

template <>
inline void MtlSolver<float>::SetKwToBtKzB() {
  sgemm(&kTranspose, &kNoTranspose, &dim_t_, &dim_t_, &dim_n_,
    &one_, B_, &dim_n_, buffer_, &dim_n_, &zero_, Kw_, &dim_t_);
}

template <>
inline void MtlSolver<double>::SetKwToBtKzB() {
  dgemm(&kTranspose, &kNoTranspose, &dim_t_, &dim_t_, &dim_n_,
    &one_, B_, &dim_n_, buffer_, &dim_n_, &zero_, Kw_, &dim_t_);
}

template <>
inline void MtlSolver<float>::ComputeKxA() {
  sgemm(&kNoTranspose, &kNoTranspose, &dim_n_, &dim_t_, &dim_n_, &one_,
    const_cast<float *>(Kx_), &dim_n_, A_, &dim_n_, &zero_, KxA_, &dim_n_);
}

template <>
inline void MtlSolver<double>::ComputeKxA() {
  dgemm(&kNoTranspose, &kNoTranspose, &dim_n_, &dim_t_, &dim_n_, &one_,
    const_cast<double *>(Kx_), &dim_n_, A_, &dim_n_, &zero_, KxA_, &dim_n_);
}

template <>
inline void MtlSolver<float>::SetBufferToKxAKw() {
  sgemm(&kNoTranspose, &kNoTranspose, &dim_n_, &dim_t_, &dim_t_,
    &one_, KxA_, &dim_n_, Kw_, &dim_t_, &zero_, buffer_, &dim_n_);
}

template <>
inline void MtlSolver<double>::SetBufferToKxAKw() {
  dgemm(&kNoTranspose, &kNoTranspose, &dim_n_, &dim_t_, &dim_t_,
    &one_, KxA_, &dim_n_, Kw_, &dim_t_, &zero_, buffer_, &dim_n_);
}

template <>
inline void MtlSolver<float>::SetKzToKxAKwAtKx() {
  sgemm(&kNoTranspose, &kTranspose, &dim_n_, &dim_n_, &dim_t_,
    &one_, buffer_, &dim_n_, KxA_, &dim_n_, &zero_, Kz_, &dim_n_);
}

template <>
inline void MtlSolver<double>::SetKzToKxAKwAtKx() {
  dgemm(&kNoTranspose, &kTranspose, &dim_n_, &dim_n_, &dim_t_,
    &one_, buffer_, &dim_n_, KxA_, &dim_n_, &zero_, Kz_, &dim_n_);
}

template <>
inline void MtlSolver<float>::Subtract(float *x, float *y) {
  saxpy(&dim_nt_, &m_one_, x, &kIncrement, y, &kIncrement);
}

template <>
inline void MtlSolver<double>::Subtract(double *x, double *y) {
  daxpy(&dim_nt_, &m_one_, x, &kIncrement, y, &kIncrement);
}

template <>
inline void MtlSolver<float>::Copy(float *x, float *y) {
  scopy(&dim_nt_, x, &kIncrement, y, &kIncrement);
}

template <>
inline void MtlSolver<double>::Copy(double *x, double *y) {
  dcopy(&dim_nt_, x, &kIncrement, y, &kIncrement);
}

template <>
inline float MtlSolver<float>::Norm22(float *x) {
  float nrm = snrm2(&dim_nt_, x, &kIncrement);
  return nrm * nrm;
}

template <>
inline double MtlSolver<double>::Norm22(double *x) {
  double nrm = dnrm2(&dim_nt_, x, &kIncrement);
  return nrm * nrm;
}


template <typename T>
SdcaSize MtlSolver<T>::num_examples() const { return num_examples_; }

template <typename T>
SdcaSize MtlSolver<T>::num_tasks() const { return num_tasks_; }

template <typename T>
SvmSolver<T> & MtlSolver<T>::svm_solver() const { return *svm_solver_; }

template <typename T>
USolver<T> & MtlSolver<T>::u_solver() const { return *u_solver_; }

template <typename T>
void MtlSolver<T>::epsilon(const T value) { epsilon_ = value; }

template <typename T>
T MtlSolver<T>::epsilon() const { return epsilon_; }

template <typename T>
void MtlSolver<T>::max_num_iter(const SdcaSize value) {
  max_num_iter_ = value;
}

template <typename T>
SdcaSize MtlSolver<T>::max_num_iter() const { return max_num_iter_; }

template <typename T>
void MtlSolver<T>::seed(const SdcaSize value) {
  seed_ = value;
  init_genrand(static_cast<unsigned long>(value));
}

template <typename T>
SdcaSize MtlSolver<T>::seed() const { return seed_; }

template <typename T>
SdcaSize MtlSolver<T>::iter() const { return iter_ + 1; }

template <typename T>
SolverStatus MtlSolver<T>::status() const { return status_; }

template <typename T>
T MtlSolver<T>::rmse() const { return rmse_; }

template <typename T>
T MtlSolver<T>::objective() const {
  return u_solver().primal_objective() + svm_solver_->regularizer()
    * svm_solver_->lambda() / static_cast<T>(2) / static_cast<T>(num_tasks_);
}

template <typename T>
double MtlSolver<T>::cpu_time() const {
  return static_cast<double>(cpu_time_) / CLOCKS_PER_SEC;
}

template <typename T>
inline double MtlSolver<T>::cpu_time_now() const {
  return static_cast<double>(std::clock() - cpu_time_) / CLOCKS_PER_SEC;
}

}

#endif // MTLSDCA_SDCA_MTLSOLVER_H
