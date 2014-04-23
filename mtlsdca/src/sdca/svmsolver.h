#ifndef MTLSDCA_SDCA_SVMSOLVER_H
#define MTLSDCA_SDCA_SVMSOLVER_H

#include <ctime>
#include <limits>
#include <iostream>
#include <iomanip>
#include <cmath>

#include "types.h"
#include "mt19937ar.h"

namespace sdca {

template <typename T>
class SvmSolver
{
public:
  inline static T DefaultC() { return static_cast<T>(1); }
  inline static T DefaultEpsilon() { return static_cast<T>(1e-2); }
  inline static SdcaSize DefaultMaxNumEpoch() { return 1e+6; }
  inline static SdcaSize DefaultCheckGapFrequency() { return 10; }
  inline static SdcaSize DefaultSeed() { return 0; }

  SvmSolver(const SdcaSize num_examples, const SdcaSize num_tasks,
    const SdcaSize *Y, const T *K, T *A, T *KAt, SdcaSize *indexes);
  ~SvmSolver();

  void Train();

  void C(const T value);
  T C() const;

  void lambda(const T value);
  T lambda() const;

  void epsilon(const T value);
  T epsilon() const;

  void max_num_epoch(const SdcaSize value);
  SdcaSize max_num_epoch() const;

  void check_gap_frequency(const SdcaSize value);
  SdcaSize check_gap_frequency() const;

  void seed(const SdcaSize value);
  SdcaSize seed() const;

  SdcaSize num_examples() const;

  SdcaSize num_tasks() const;

  SdcaSize epoch() const;

  SolverStatus status() const;

  double cpu_time() const;

  inline T absolute_gap() const;

  inline T relative_gap() const;

  inline T primal_objective() const;

  inline T dual_objective() const;

  inline T primal_loss() const;

  inline T dual_loss() const;

  inline T regularizer() const;

protected:
  inline void BeginTraining();
  inline void EndTraining();
  inline void BeginTask();
  inline void EndTask();
  inline void BeginEpoch();
  inline bool EndEpoch();
  bool CheckRelativeGap();
  inline void UpdateVariable(SdcaSize i);
  inline void UpdateKAt(T alpha);
  inline void ComputeKAt();
  inline T AtDotKAt();

  inline T absolute_gap_task() const;
  inline T relative_gap_task() const;
  inline T primal_objective_task() const;
  inline T dual_objective_task() const;
  inline T primal_loss_task() const;
  inline T dual_loss_task() const;
  inline T regularizer_task() const;
  inline SdcaSize epoch_task() const;
  inline SolverStatus status_task() const;
  inline double cpu_time_now() const;

  // Problem specification
  const SdcaSize num_examples_; // N
  const SdcaSize num_tasks_;    // T
  const SdcaSize num_elements_; // N * T
  const SdcaSize *Y_; // class labels; N-by-1; values must be in [0,T-1]
  const T *K_;        // Gram matrix; N-by-N
  T *A_;              // dual variables; N-by-T

  // Temporary memory buffers
  T *KAt_;                      // N
  const bool free_KAt_;
  SdcaSize *indexes_;           // N
  const bool free_indexes_;

  // Solver parameters
  T C_;
  T lambda_;
  T epsilon_;
  SdcaSize max_num_epoch_;
  SdcaSize check_gap_frequency_;
  SdcaSize seed_;

  // Solution details/statistics
  T primal_loss_;
  T dual_loss_;
  T regularizer_;
  SdcaSize max_epoch_;
  SolverStatus status_;
  std::clock_t cpu_time_;

  // Current progress
  SdcaSize epoch_;
  SdcaSize task_;

  // Helper temporary variables
  bool recompute_gap_;
  bool force_check_gap_;
  bool variables_changed_;
  const T *Ki_;
  T *At_;
  T h_;
  T dual_objective_old_;
  T primal_loss_t_;
  T dual_loss_t_;
  T regularizer_t_;
  SolverStatus status_t_;

  // Precomputed BLAS constants
  BLAS_CONST T zero_;
  BLAS_CONST T one_;
  BLAS_CONST BlasInt dim_n_;

};


template <typename T>
SvmSolver<T>::SvmSolver(const SdcaSize num_examples, const SdcaSize num_tasks,
  const SdcaSize *Y, const T *K, T *A,
  T *KAt = NULL, SdcaSize *indexes = NULL)
    : num_examples_(num_examples), num_tasks_(num_tasks),
      num_elements_(num_examples * num_tasks),
      Y_(Y), K_(K), A_(A),
      KAt_(KAt), free_KAt_(KAt == NULL),
      indexes_(indexes), free_indexes_(indexes == NULL),
      zero_(0), one_(1), dim_n_(num_examples) {

  if (free_KAt_) KAt_ = new T[num_examples_];
  if (free_indexes_) indexes_ = new SdcaSize[num_examples_];

  C(DefaultC());
  epsilon(DefaultEpsilon());
  max_num_epoch(DefaultMaxNumEpoch());
  check_gap_frequency(DefaultCheckGapFrequency());
  seed(DefaultSeed());

  primal_loss_ = + std::numeric_limits<T>::infinity();
  dual_loss_ = - std::numeric_limits<T>::infinity();
  regularizer_ = static_cast<T>(0);
  max_epoch_ = static_cast<SdcaSize>(0);
  status_ = SolverStatus::kNone;
  cpu_time_ = static_cast<std::clock_t>(0);

  epoch_ = static_cast<SdcaSize>(0);
  task_ = static_cast<SdcaSize>(0);
}

template <typename T>
SvmSolver<T>::~SvmSolver() {
  if (free_indexes_) delete[] indexes_;
  if (free_KAt_) delete[] KAt_;
}

template <typename T>
void SvmSolver<T>::Train() {

  BeginTraining();

  for (task_ = 0; task_ < num_tasks_; ++task_) {

    BeginTask();

    for (epoch_ = 0; epoch_ < max_num_epoch_; ++epoch_) {

      BeginEpoch();

      for (SdcaSize i = 0; i < num_examples_; ++i) {
        UpdateVariable(indexes_[i]);
      }

      if (EndEpoch()) break;
    }

    EndTask();
  }

  EndTraining();
}

template <typename T>
inline void SvmSolver<T>::BeginTraining() {
#ifdef VERBOSE
  std::cout << "SVMSDCA::Start(" << std::scientific << std::setprecision(16) <<
    "num_examples: " << num_examples() << ", "
    "num_tasks: " << num_tasks() << ", "
    "C: " << C() << ", "
    "lambda: " << lambda() << ", "
    "epsilon: " << epsilon() << ", "
    "max_num_epoch: " << max_num_epoch() << ", "
    "check_gap_frequency: " << check_gap_frequency() << ", "
    "seed: " << seed() << ")" << std::endl;
#endif

  primal_loss_ = static_cast<T>(0);
  dual_loss_ = static_cast<T>(0);
  regularizer_ = static_cast<T>(0);
  max_epoch_ = static_cast<SdcaSize>(0);
  status_ = SolverStatus::kTraining;
  cpu_time_ = std::clock();

  for (SdcaSize i = 0; i < num_examples_; ++i) {
    indexes_[i] = i;
  }
}

template <typename T>
inline void SvmSolver<T>::EndTraining() {
  if (status_ == SolverStatus::kTraining) {
    status_ = SolverStatus::kConverged;
  }

  cpu_time_ = std::clock() - cpu_time_;

#ifdef VERBOSE
  std::cout << "SVMSDCA::End("
    "status: " << status_to_string(status()) << ", "
    "epoch: " << epoch() << ", "
    "primal_loss: " << primal_loss() << ", "
    "dual_loss: " << dual_loss() << ", "
    "regularizer: " << regularizer() << ", "
    "primal: " << primal_objective() << ", "
    "dual: " << dual_objective() << ", "
    "absolute_gap: " << absolute_gap() << ", "
    "relative_gap: " << relative_gap() << ", "
    "cpu_time: " << cpu_time() << ")" << std::endl;
#endif
}

template <typename T>
inline void SvmSolver<T>::BeginTask() {
  status_t_ = SolverStatus::kTraining;
  At_ = A_ + num_examples_ * task_;
  ComputeKAt();

  dual_objective_old_ = -std::numeric_limits<T>::infinity();
}

template <typename T>
inline void SvmSolver<T>::EndTask() {
  if (status_t_ == SolverStatus::kTraining && epoch_ >= max_num_epoch_) {
    status_t_ = SolverStatus::kMaxNumEpoch;
    if (epoch_ > 0) --epoch_; // correct to the last executed epoch
  }
  if (recompute_gap_) CheckRelativeGap();
  if (epoch_ > max_epoch_) max_epoch_ = epoch_;
  if (status_t_ != SolverStatus::kConverged) {
    status_ = status_t_;
  }

#ifdef VERBOSE
  std::cout << "  "
    "task: " << task_ + 1 << ", "
    "status: " << status_to_string(status_task()) << ", "
    "epoch: " << epoch_task() << ", "
    "primal_loss: " << primal_loss_task() << ", "
    "dual_loss: " << dual_loss_task() << ", "
    "regularizer: " << regularizer_task() << ", "
    "primal: " << primal_objective_task() << ", "
    "dual: " << dual_objective_task() << ", "
    "absolute_gap: " << absolute_gap_task() << ", "
    "relative_gap: " << relative_gap_task() << ", "
    "cpu_time: " << cpu_time_now() << std::endl;
#endif

  primal_loss_ += primal_loss_t_;
  dual_loss_ += dual_loss_t_;
  regularizer_ += regularizer_t_;
}

template <typename T>
inline void SvmSolver<T>::BeginEpoch() {
  force_check_gap_ = false;
  variables_changed_ = false;
  rand_permute(indexes_, num_examples_);
}

template <typename T>
inline bool SvmSolver<T>::EndEpoch() {
  if (variables_changed_) {
    recompute_gap_ = true;
  } else {
    status_t_ = SolverStatus::kNoProgress;
    return true;
  }

  // Check duality gap every 'check_gap_frequency_' epoch
  bool check_now = check_gap_frequency_ > 0
                   && epoch_ % check_gap_frequency_ == check_gap_frequency_ - 1;
  if (check_now || force_check_gap_) {
    if (CheckRelativeGap()) return true;
    force_check_gap_ = false;
  }

  return false;
}

template <typename T>
bool SvmSolver<T>::CheckRelativeGap() {
  recompute_gap_ = false;

  regularizer_t_ = AtDotKAt();

  primal_loss_t_ = static_cast<T>(0);
  dual_loss_t_ = static_cast<T>(0);

  T primal_c = static_cast<T>(0);     // Compensation variables,
  T dual_c = static_cast<T>(0);       // see Kahan summation algorithm
  T primal_y = static_cast<T>(0);
  T dual_y = static_cast<T>(0);
  T primal_t = static_cast<T>(0);
  T dual_t = static_cast<T>(0);

  for (SdcaSize i = 0; i < num_examples_; ++i) {
    if (Y_[i] != task_) {
      // Y = -1
      h_ = static_cast<T>(1) + KAt_[i];
      dual_y = - At_[i] - dual_c;
    } else {
      // Y = +1
      h_ = static_cast<T>(1) - KAt_[i];
      dual_y = + At_[i] - dual_c;
    }

    dual_t = dual_loss_t_ + dual_y;
    dual_c = (dual_t - dual_loss_t_) - dual_y;
    dual_loss_t_ = dual_t;

    if (h_ > static_cast<T>(0)) {
      primal_y = h_ - primal_c;
      primal_t = primal_loss_t_ + primal_y;
      primal_c = (primal_t - primal_loss_t_) - primal_y;
      primal_loss_t_ = primal_t;
    }
  }

  T diff = absolute_gap_task();
  T max = std::max(
          std::abs(primal_objective_task()), std::abs(dual_objective_task()));

  if (diff < epsilon_ * max) {
    status_t_ = SolverStatus::kConverged;
    return true;
  } else if (diff <= std::numeric_limits<T>::epsilon() * max) {
    status_t_ = SolverStatus::kConvergedMachinePrecision;
    return true;
  }

  // (Theoretically) the dual objective should not decrease
  if (dual_objective_task() < dual_objective_old_
      - std::numeric_limits<T>::epsilon() * std::abs(dual_objective_task())) {
#ifdef VERBOSE
    std::cout << "  "
      "Warning: the dual objective decreased by: " <<
      dual_objective_old_ - dual_objective_task() << std::endl;
#endif
    status_t_ = SolverStatus::kNumericalProblems;
    return true;
  }

  dual_objective_old_ = dual_objective_task();
  return false;
}

template <typename T>
inline void SvmSolver<T>::UpdateVariable(SdcaSize i) {
  T alpha = static_cast<T>(0);
  if (Y_[i] != task_) {
    // Y = -1
    if (KAt_[i] > static_cast<T>(-1)) {
      if (At_[i] <= - C_) return;
    } else {
      if (At_[i] >= static_cast<T>(0)) return;
    }

    Ki_ = K_ + num_examples_ * i;
    if (Ki_[i] <= static_cast<T>(0)) return;

    h_ = (static_cast<T>(1) + KAt_[i]) / Ki_[i];
    alpha = std::max(-C_, std::min(static_cast<T>(0), At_[i] - h_));
  } else {
    // Y = +1
    if (KAt_[i] < static_cast<T>(1)) {
      if (At_[i] >= C_) return;
    } else {
      if (At_[i] <= static_cast<T>(0)) return;
    }

    Ki_ = K_ + num_examples_ * i;
    if (Ki_[i] <= static_cast<T>(0)) return;

    h_ = (static_cast<T>(1) - KAt_[i]) / Ki_[i];
    alpha = std::max(static_cast<T>(0), std::min(C_, At_[i] + h_));
  }

  if (At_[i] != alpha) {
    variables_changed_ = true;
    h_ = alpha - At_[i];
    T max = std::max(std::abs(alpha), std::abs(At_[i]));
    At_[i] = alpha;
    if (std::abs(h_) < std::numeric_limits<T>::epsilon() * max) {
#ifdef VERBOSE2
      std::cout << "  "
        "Info: small delta: " <<
        "epoch: " << epoch_ + 1 << ", "
        "task: " << task_ + 1 << ", "
        "example: " << i + 1 << ", "
        "delta: " << h_ << std::endl;
#endif
      ComputeKAt();
      force_check_gap_ = true;
    } else {
      UpdateKAt(h_);
    }
  }
}


template <>
inline void SvmSolver<float>::UpdateKAt(float alpha) {
  saxpy(&dim_n_, &alpha, const_cast<float *>(Ki_), &kIncrement,
    KAt_, &kIncrement);
}

template <>
inline void SvmSolver<double>::UpdateKAt(double alpha) {
  daxpy(&dim_n_, &alpha, const_cast<double *>(Ki_), &kIncrement,
    KAt_, &kIncrement);
}

template <>
inline void SvmSolver<float>::ComputeKAt() {
  sgemv(&kNoTranspose, &dim_n_, &dim_n_, &one_, const_cast<float *>(K_),
    &dim_n_, At_, &kIncrement, &zero_, KAt_, &kIncrement);
}

template <>
inline void SvmSolver<double>::ComputeKAt() {
  dgemv(&kNoTranspose, &dim_n_, &dim_n_, &one_, const_cast<double *>(K_),
    &dim_n_, At_, &kIncrement, &zero_, KAt_, &kIncrement);
}

template <>
inline float SvmSolver<float>::AtDotKAt() {
  return sdot(&dim_n_, At_, &kIncrement, KAt_, &kIncrement);
}

template <>
inline double SvmSolver<double>::AtDotKAt() {
  return ddot(&dim_n_, At_, &kIncrement, KAt_, &kIncrement);
}


template <typename T>
void SvmSolver<T>::C(const T value) {
  C_ = value;
  lambda_ = static_cast<T>(1) / (static_cast<T>(num_examples_) * value);
}

template <typename T>
T SvmSolver<T>::C() const { return C_; }

template <typename T>
void SvmSolver<T>::lambda(const T value) {
  lambda_ = value;
  C_ = static_cast<T>(1) / (static_cast<T>(num_examples_) * value);
}

template <typename T>
T SvmSolver<T>::lambda() const { return lambda_; }

template <typename T>
void SvmSolver<T>::epsilon(const T value) { epsilon_ = value; }

template <typename T>
T SvmSolver<T>::epsilon() const { return epsilon_; }

template <typename T>
void SvmSolver<T>::max_num_epoch(const SdcaSize value) {
  max_num_epoch_ = value;
}

template <typename T>
SdcaSize SvmSolver<T>::max_num_epoch() const { return max_num_epoch_; }

template <typename T>
void SvmSolver<T>::check_gap_frequency(const SdcaSize value) {
  check_gap_frequency_ = value;
}

template <typename T>
SdcaSize SvmSolver<T>::check_gap_frequency() const {
  return check_gap_frequency_;
}

template <typename T>
void SvmSolver<T>::seed(const SdcaSize value) {
  seed_ = value;
  init_genrand(static_cast<unsigned long>(value));
}

template <typename T>
SdcaSize SvmSolver<T>::seed() const { return seed_; }

template <typename T>
SdcaSize SvmSolver<T>::num_examples() const { return num_examples_; }

template <typename T>
SdcaSize SvmSolver<T>::num_tasks() const { return num_tasks_; }

template <typename T>
SdcaSize SvmSolver<T>::epoch() const { return max_epoch_ + 1; }

template <typename T>
SolverStatus SvmSolver<T>::status() const { return status_; }

template <typename T>
double SvmSolver<T>::cpu_time() const {
  return static_cast<double>(cpu_time_) / CLOCKS_PER_SEC;
}

template <typename T>
inline T SvmSolver<T>::absolute_gap() const {
  return (primal_loss_ / static_cast<T>(num_examples_)
    + lambda_ * (regularizer_ - dual_loss_)) / static_cast<T>(num_tasks_);
}

template <typename T>
inline T SvmSolver<T>::relative_gap() const {
  return absolute_gap() / std::max(
    std::abs(primal_objective()), std::abs(dual_objective()));
}

template <typename T>
inline T SvmSolver<T>::primal_objective() const {
  return (primal_loss_ / static_cast<T>(num_examples_)
    + lambda_ * regularizer_ / static_cast<T>(2)) / static_cast<T>(num_tasks_);
}

template <typename T>
inline T SvmSolver<T>::dual_objective() const {
  return lambda_ * (dual_loss_ - regularizer_ / static_cast<T>(2))
    / static_cast<T>(num_tasks_);
}

template <typename T>
inline T SvmSolver<T>::primal_loss() const {
  return primal_loss_;
}

template <typename T>
inline T SvmSolver<T>::dual_loss() const {
  return dual_loss_;
}

template <typename T>
inline T SvmSolver<T>::regularizer() const {
  return regularizer_;
}

template <typename T>
inline T SvmSolver<T>::absolute_gap_task() const {
  return primal_loss_t_ / static_cast<T>(num_examples_)
    + lambda_ * (regularizer_t_ - dual_loss_t_);
}

template <typename T>
inline T SvmSolver<T>::relative_gap_task() const {
  return absolute_gap_task() / std::max(
    std::abs(primal_objective_task()), std::abs(dual_objective_task()));
}

template <typename T>
inline T SvmSolver<T>::primal_objective_task() const {
  return primal_loss_t_ / static_cast<T>(num_examples_)
    + lambda_ * regularizer_t_ / static_cast<T>(2);
}

template <typename T>
inline T SvmSolver<T>::dual_objective_task() const {
  return lambda_ * (dual_loss_t_ - regularizer_t_ / static_cast<T>(2));
}

template <typename T>
inline T SvmSolver<T>::primal_loss_task() const {
  return primal_loss_t_;
}

template <typename T>
inline T SvmSolver<T>::dual_loss_task() const {
  return dual_loss_t_;
}

template <typename T>
inline T SvmSolver<T>::regularizer_task() const {
  return regularizer_t_;
}

template <typename T>
inline SdcaSize SvmSolver<T>::epoch_task() const { return epoch_ + 1; }

template <typename T>
inline SolverStatus SvmSolver<T>::status_task() const { return status_t_; }

template <typename T>
inline double SvmSolver<T>::cpu_time_now() const {
  return static_cast<double>(std::clock() - cpu_time_) / CLOCKS_PER_SEC;
}

}

#endif // MTLSDCA_SDCA_SVMSOLVER_H
