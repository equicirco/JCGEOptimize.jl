# Design

## Role in JCGE

JCGEOptimize is designed as an optional layer around equilibrium models. A search
algorithm proposes candidate decisions, the model computes their equilibrium
outcomes, and the optimization layer evaluates the objectives and constraints
before proposing further candidates.

The architecture is general: policy design, parameter optimization, and
single-objective or multi-objective problems share this separation between
candidate decisions and equilibrium calculations.

## Responsibilities

The optimization component defines and coordinates:

- Decision variables, their bounds, and their mapping to model inputs.
- Objectives and constraints computed from model outcomes.
- Interchangeable optimization backends: deterministic grid search and an optional
  Metaheuristics.jl extension.
- Evaluation records, solver-failure handling, and reproducible search histories.
- Results representing an optimum candidate or trade-offs among objectives.

The user supplies an evaluator that maps named decisions to a compact outcome.
For a JCGE model, this evaluator calls JCGERuntime, checks solve status and
residuals, and extracts the quantities needed by the objectives and constraints.
JCGEOptimize accepts that outcome through an explicit validity callback. Economic
equations and closures remain defined by the model and its JCGE blocks.

Optimization histories are returned as flat named-tuple rows for tabular export.
The model application can use JCGEOutput to collect and report individual
equilibrium results; the generic search code has no mandatory dependency on a
particular model, solver, or reporting package.

## Validity, feasibility, and search results

Model validity and policy feasibility are separate. A candidate can satisfy the
equilibrium equations but violate a revenue requirement. Conversely, a failed
equilibrium cannot qualify for the optimum even if its tentative indicators look
attractive. Every attempted model evaluation remains in the history.

Constraint tolerances use the original outcome units. Scales normalize the
residuals passed to the backend, while reported objective and constraint values
retain their original units. Unexpected evaluator exceptions propagate by
default; applications may explicitly choose to record them as failed evaluations.
Interrupts always propagate.

Single-objective searches report the best feasible evaluated candidate. Searches
with several objectives report feasible nondominated candidates without assigning
unstated weights. A heuristic result does not certify global optimality or the
uniqueness of the equilibria used to evaluate it.

## Backends

`GridSearch` provides a deterministic comparison over declared axes.
`MetaheuristicsBackend` receives an algorithm factory so applications can select
the appropriate single-objective or multi-objective algorithm. The optional
extension uses a fixed seed and a hard model-evaluation budget, including the
initial point and failed evaluations. Candidate evaluation is currently serial.

Algorithms receive finite penalties for rejected evaluations. Infinities can
produce undefined arithmetic in fitness-weighted calculations, including ECA's
population centres. `failure_penalty` defaults to `1e6` in the scaled minimization
objectives and constraint residuals passed to the algorithm. Applications can
choose another finite positive value appropriate to their normalized objectives
and constraints. This is a numerical search setting: failure records retain
their original status and unavailable outcomes, and failed candidates are
excluded from the reported optimum regardless of the penalty.
