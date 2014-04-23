#ifndef MTLSDCA_SDCA_USOLVER_H
#define MTLSDCA_SDCA_USOLVER_H

#include "svmsolver.h"

namespace sdca {

template <typename T>
class USolver
{
public:
  inline static T DefaultC() { return static_cast<T>(1); }
  inline static T DefaultEpsilon() { return static_cast<T>(1e-2); }
  inline static SdcaSize DefaultMaxNumEpoch() { return 1e+5; }
  inline static SdcaSize DefaultCheckGapFrequency() { return 5; }
  inline static SdcaSize DefaultSeed() { return 1; }

  USolver(const SdcaSize num_examples, const SdcaSize num_tasks,
    const SdcaSize *Y, const T *K, const T *M, T *A,
    T *AMt, T *KAMt, SdcaSize *indexes, SdcaSize *indexes_t);
  ~USolver();

  void Train();

  void C(const T value);
  T C() const;

  void mu(const T value);
  T mu() const;

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
  inline bool BeginTask(SdcaSize t);
  inline void EndTask();
  inline void BeginEpoch();
  inline bool EndEpoch();
  bool CheckRelativeGap();
  inline void UpdateVariable(SdcaSize i);
  inline void UpdateKAMt(T alpha);
  inline void ComputeAMt();
  inline void ComputeKAMt();
  inline T AtKAMt();

  inline double cpu_time_now() const;

  // Problem specification
  const SdcaSize num_examples_; // N
  const SdcaSize num_tasks_;    // T
  const SdcaSize num_elements_; // N * T
  const SdcaSize *Y_; // class labels; N-by-1; values must be in [0,T-1]
  const T *K_;        // Gram matrix; K = X' * X; N-by-N
  const T *M_;        // M = W' * W; T-by-T
  T *A_;              // dual variables; N-by-T

  // Temporary memory buffers
  T *AMt_;
  const bool free_AMt_;         // N
  T *KAMt_;
  const bool free_KAMt_;        // N
  SdcaSize *indexes_;
  const bool free_indexes_;     // N
  SdcaSize *indexes_t_;
  const bool free_indexes_t_;   // T

  // Solver parameters
  T C_;
  T mu_;
  T epsilon_;
  SdcaSize max_num_epoch_;
  SdcaSize check_gap_frequency_;
  SdcaSize seed_;

  // Solution details/statistics
  T primal_loss_;
  T dual_loss_;
  T regularizer_;
  SolverStatus status_;
  std::clock_t cpu_time_;

  // Current progress
  SdcaSize epoch_;
  SdcaSize task_;

  // Helper temporary vars
  bool recompute_gap_;
  bool force_check_gap_;
  bool variables_changed_;
  const T *Ki_;
  const T *Mt_;
  T Mtt_;
  T *At_;
  T h_;
  T dual_objective_old_;

  // Precomputed BLAS constants
  BLAS_CONST T zero_;
  BLAS_CONST T one_;
  BLAS_CONST BlasInt dim_n_;
  BLAS_CONST BlasInt dim_t_;

};


template <typename T>
USolver<T>::USolver(const SdcaSize num_examples, const SdcaSize num_tasks,
  const SdcaSize *Y, const T *Kx, const T *Kw, T *A, T *AMt = NULL,
  T *KAMt = NULL, SdcaSize *indexes = NULL, SdcaSize *indexes_t = NULL)
    : num_examples_(num_examples), num_tasks_(num_tasks),
      num_elements_(num_examples * num_tasks),
      Y_(Y), K_(Kx), M_(Kw), A_(A),
      AMt_(AMt), free_AMt_(AMt == NULL),
      KAMt_(KAMt), free_KAMt_(KAMt == NULL),
      indexes_(indexes), free_indexes_(indexes == NULL),
      indexes_t_(indexes_t), free_indexes_t_(indexes_t == NULL),
      zero_(0), one_(1), dim_n_(num_examples), dim_t_(num_tasks) {

  if (free_AMt_) AMt_ = new T[num_examples_];
  if (free_KAMt_) KAMt_ = new T[num_examples_];
  if (free_indexes_) indexes_ = new SdcaSize[num_examples_];
  if (free_indexes_t_) indexes_t_ = new SdcaSize[num_tasks_];

  C(DefaultC());
  epsilon(DefaultEpsilon());
  max_num_epoch(DefaultMaxNumEpoch());
  check_gap_frequency(DefaultCheckGapFrequency());
  seed(DefaultSeed());

  primal_loss_ = + std::numeric_limits<T>::infinity();
  dual_loss_ = - std::numeric_limits<T>::infinity();
  regularizer_ = static_cast<T>(0);
  status_ = SolverStatus::kNone;
  cpu_time_ = static_cast<std::clock_t>(0);

  epoch_ = static_cast<SdcaSize>(0);
  task_ = static_cast<SdcaSize>(0);
}

template <typename T>
USolver<T>::~USolver() {
  if (free_indexes_t_) delete[] indexes_t_;
  if (free_indexes_) delete[] indexes_;
  if (free_KAMt_) delete[] KAMt_;
  if (free_AMt_) delete[] AMt_;
}

template <typename T>
void USolver<T>::Train() {

  BeginTraining();

  for (epoch_ = 0; epoch_ < max_num_epoch_; ++epoch_) {

    BeginEpoch();

    for (SdcaSize t = 0; t < num_tasks_; ++t) {

      if (BeginTask(indexes_t_[t])) continue;

      for (SdcaSize i = 0; i < num_examples_; ++i) {
        UpdateVariable(indexes_[i]);
      }

      EndTask();
    }

    if (EndEpoch()) break;
  }

  EndTraining();
}

template <typename T>
inline void USolver<T>::BeginTraining() {
#ifdef VERBOSE
  std::cout << "USDCA::Start(" << std::scientific << std::setprecision(16) <<
    "num_examples: " << num_examples() << ", "
    "num_tasks: " << num_tasks() << ", "
    "C: " << C() << ", "
    "mu: " << mu() << ", "
    "epsilon: " << epsilon() << ", "
    "max_num_epoch: " << max_num_epoch() << ", "
    "check_gap_frequency: " << check_gap_frequency() << ", "
    "seed: " << seed() << ")" << std::endl;
#endif

  dual_objective_old_ = -std::numeric_limits<T>::infinity();
  primal_loss_ = static_cast<T>(0);
  dual_loss_ = static_cast<T>(0);
  regularizer_ = static_cast<T>(0);
  status_ = SolverStatus::kTraining;
  cpu_time_ = std::clock();

  for (SdcaSize i = 0; i < num_examples_; ++i) {
    indexes_[i] = i;
  }
  for (SdcaSize t = 0; t < num_tasks_; ++t) {
    indexes_t_[t] = t;
  }
}

template <typename T>
inline void USolver<T>::EndTraining() {
  if (status_ == SolverStatus::kTraining && epoch_ >= max_num_epoch_) {
    status_ = SolverStatus::kMaxNumEpoch;
    if (epoch_ > 0) --epoch_; // correct to the last executed epoch
  }
  if (recompute_gap_) CheckRelativeGap();

  cpu_time_ = std::clock() - cpu_time_;

#ifdef VERBOSE
  std::cout << "USDCA::End("
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
inline bool USolver<T>::BeginTask(SdcaSize t) {
  task_ = t;
  At_ = A_ + num_examples_ * task_;
  Mt_ = M_ + num_tasks_ * task_;
  Mtt_ = Mt_[task_];

  if (Mtt_ <= static_cast<T>(0)) return true;

  ComputeAMt();
  ComputeKAMt();
  rand_permute(indexes_, num_examples_);

  return false;
}

template <typename T>
inline void USolver<T>::EndTask() {}

template <typename T>
inline void USolver<T>::BeginEpoch() {
  force_check_gap_ = false;
  variables_changed_ = false;
  rand_permute(indexes_t_, num_tasks_);
}

template <typename T>
inline bool USolver<T>::EndEpoch() {
  if (variables_changed_) {
    recompute_gap_ = true;
  } else {
    status_ = SolverStatus::kNoProgress;
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
bool USolver<T>::CheckRelativeGap() {
  recompute_gap_ = false;

  primal_loss_ = static_cast<T>(0);
  dual_loss_ = static_cast<T>(0);
  regularizer_ = static_cast<T>(0);

  T primal_c = static_cast<T>(0);     // Compensation variables,
  T dual_c = static_cast<T>(0);       // see Kahan summation algorithm
  T primal_y = static_cast<T>(0);
  T dual_y = static_cast<T>(0);
  T primal_t = static_cast<T>(0);
  T dual_t = static_cast<T>(0);

  for (task_ = 0; task_ < num_tasks_; ++task_) {

    Mt_ = M_ + num_tasks_ * task_;
    At_ = A_ + num_examples_ * task_;

    ComputeAMt();
    ComputeKAMt();

    regularizer_ += AtKAMt();

    for (SdcaSize i = 0; i < num_examples_; ++i) {
      if (Y_[i] != task_) {
        // Y = -1
        h_ = static_cast<T>(1) + KAMt_[i];
        dual_y = - At_[i] - dual_c;
      } else {
        // Y = +1
        h_ = static_cast<T>(1) - KAMt_[i];
        dual_y = + At_[i] - dual_c;
      }

      dual_t = dual_loss_ + dual_y;
      dual_c = (dual_t - dual_loss_) - dual_y;
      dual_loss_ = dual_t;

      if (h_ > static_cast<T>(0)) {
        primal_y = h_ - primal_c;
        primal_t = primal_loss_ + primal_y;
        primal_c = (primal_t - primal_loss_) - primal_y;
        primal_loss_ = primal_t;
      }
    }
  }

#ifdef VERBOSE
  std::cout << "  "
    "epoch: " << epoch() << ", "
    "primal_loss: " << primal_loss() << ", "
    "dual_loss: " << dual_loss() << ", "
    "regularizer: " << regularizer() << ", "
    "primal: " << primal_objective() << ", "
    "dual: " << dual_objective() << ", "
    "absolute_gap: " << absolute_gap() << ", "
    "relative_gap: " << relative_gap() << ", "
    "cpu_time: " << cpu_time_now() << std::endl;
#endif

  T diff = absolute_gap();
  T max = std::max(std::abs(primal_objective()), std::abs(dual_objective()));

  if (diff < epsilon_ * max) {
    status_ = SolverStatus::kConverged;
    return true;
  } else if (diff <= std::numeric_limits<T>::epsilon() * max) {
    status_ = SolverStatus::kConvergedMachinePrecision;
    return true;
  }

  // (Theoretically) the dual objective should not decrease
  if (dual_objective() < dual_objective_old_
      - std::numeric_limits<T>::epsilon() * std::abs(dual_objective())) {
#ifdef VERBOSE
    std::cout << "  "
      "Warning: the dual objective decreased by: " <<
      dual_objective_old_ - dual_objective() << std::endl;
#endif
    status_ = SolverStatus::kNumericalProblems;
    return true;
  }

  dual_objective_old_ = dual_objective();
  return false;
}

template <typename T>
inline void USolver<T>::UpdateVariable(SdcaSize i) {
  T alpha = static_cast<T>(0);
  if (Y_[i] != task_) {
    // Y = -1
    if (KAMt_[i] > static_cast<T>(-1)) {
      if (At_[i] <= - C_) return;
    } else {
      if (At_[i] >= static_cast<T>(0)) return;
    }

    Ki_ = K_ + num_examples_ * i;
    if (Ki_[i] * Mtt_ <= static_cast<T>(0)) return;

    h_ = (static_cast<T>(1) + KAMt_[i]) / (Ki_[i] * Mtt_);
    alpha = std::max(-C_, std::min(static_cast<T>(0), At_[i] - h_));
  } else {
    // Y = +1
    if (KAMt_[i] < static_cast<T>(1)) {
      if (At_[i] >= C_) return;
    } else {
      if (At_[i] <= static_cast<T>(0)) return;
    }

    Ki_ = K_ + num_examples_ * i;
    if (Ki_[i] * Mtt_ <= static_cast<T>(0)) return;

    h_ = (static_cast<T>(1) - KAMt_[i]) / (Ki_[i] * Mtt_);
    alpha = std::max(static_cast<T>(0), std::min(C_, At_[i] + h_));
  }

  if (At_[i] != alpha) {
    variables_changed_ = true;
    h_ = (alpha - At_[i]) * Mtt_;
    T max = std::max(std::abs(alpha), std::abs(At_[i])) * Mtt_;
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
      ComputeAMt();
      ComputeKAMt();
      force_check_gap_ = true;
    } else {
      UpdateKAMt(h_);
    }
  }
}


template <>
inline void USolver<float>::UpdateKAMt(float alpha) {
  saxpy(&dim_n_, &alpha, const_cast<float *>(Ki_), &kIncrement,
    KAMt_, &kIncrement);
}

template <>
inline void USolver<double>::UpdateKAMt(double alpha) {
  daxpy(&dim_n_, &alpha, const_cast<double *>(Ki_), &kIncrement,
    KAMt_, &kIncrement);
}

template <>
inline void USolver<float>::ComputeAMt() {
  sgemv(&kNoTranspose, &dim_n_, &dim_t_, &one_, A_, &dim_n_,
    const_cast<float *>(Mt_), &kIncrement, &zero_, AMt_, &kIncrement);
}

template <>
inline void USolver<double>::ComputeAMt() {
  dgemv(&kNoTranspose, &dim_n_, &dim_t_, &one_, A_, &dim_n_,
    const_cast<double *>(Mt_), &kIncrement, &zero_, AMt_, &kIncrement);
}

template <>
inline void USolver<float>::ComputeKAMt() {
  sgemv(&kNoTranspose, &dim_n_, &dim_n_, &one_, const_cast<float *>(K_),
    &dim_n_, AMt_, &kIncrement, &zero_, KAMt_, &kIncrement);
}

template <>
inline void USolver<double>::ComputeKAMt() {
  dgemv(&kNoTranspose, &dim_n_, &dim_n_, &one_, const_cast<double *>(K_),
    &dim_n_, AMt_, &kIncrement, &zero_, KAMt_, &kIncrement);
}

template <>
inline float USolver<float>::AtKAMt() {
  return sdot(&dim_n_, At_, &kIncrement, KAMt_, &kIncrement);
}

template <>
inline double USolver<double>::AtKAMt() {
  return ddot(&dim_n_, At_, &kIncrement, KAMt_, &kIncrement);
}


template <typename T>
void USolver<T>::C(const T value) {
  C_ = value;
  mu_ = static_cast<T>(1) / (static_cast<T>(num_elements_) * value);
}

template <typename T>
T USolver<T>::C() const { return C_; }

template <typename T>
void USolver<T>::mu(const T value) {
  mu_ = value;
  C_ = static_cast<T>(1) / (static_cast<T>(num_elements_) * value);
}

template <typename T>
T USolver<T>::mu() const { return mu_; }

template <typename T>
void USolver<T>::epsilon(const T value) { epsilon_ = value; }

template <typename T>
T USolver<T>::epsilon() const { return epsilon_; }

template <typename T>
void USolver<T>::max_num_epoch(const SdcaSize value) {
  max_num_epoch_ = value;
}

template <typename T>
SdcaSize USolver<T>::max_num_epoch() const { return max_num_epoch_; }

template <typename T>
void USolver<T>::check_gap_frequency(const SdcaSize value) {
  check_gap_frequency_ = value;
}

template <typename T>
SdcaSize USolver<T>::check_gap_frequency() const {
  return check_gap_frequency_;
}

template <typename T>
void USolver<T>::seed(const SdcaSize value) {
  seed_ = value;
  init_genrand(static_cast<unsigned long>(value));
}

template <typename T>
SdcaSize USolver<T>::seed() const { return seed_; }

template <typename T>
SdcaSize USolver<T>::num_examples() const { return num_examples_; }

template <typename T>
SdcaSize USolver<T>::num_tasks() const { return num_tasks_; }

template <typename T>
SdcaSize USolver<T>::epoch() const { return epoch_ + 1; }

template <typename T>
SolverStatus USolver<T>::status() const { return status_; }

template <typename T>
double USolver<T>::cpu_time() const {
  return static_cast<double>(cpu_time_) / CLOCKS_PER_SEC;
}

template <typename T>
inline double USolver<T>::cpu_time_now() const {
  return static_cast<double>(std::clock() - cpu_time_) / CLOCKS_PER_SEC;
}

template <typename T>
inline T USolver<T>::absolute_gap() const {
  return primal_loss_ / static_cast<T>(num_elements_)
    + mu_ * (regularizer_ - dual_loss_);
}

template <typename T>
inline T USolver<T>::relative_gap() const {
  return absolute_gap() / std::max(
    std::abs(primal_objective()), std::abs(dual_objective()));
}

template <typename T>
inline T USolver<T>::primal_objective() const {
  return primal_loss_ / static_cast<T>(num_elements_)
    + mu_ * regularizer_ / static_cast<T>(2);
}

template <typename T>
inline T USolver<T>::dual_objective() const {
  return mu_ * (dual_loss_ - regularizer_ / static_cast<T>(2));
}

template <typename T>
inline T USolver<T>::primal_loss() const {
  return primal_loss_;
}

template <typename T>
inline T USolver<T>::dual_loss() const {
  return dual_loss_;
}

template <typename T>
inline T USolver<T>::regularizer() const {
  return regularizer_;
}

}

#endif // MTLSDCA_SDCA_USOLVER_H
