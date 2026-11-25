# Usage

## Load the development package

From a local checkout:

```sh
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. -e 'using JCGEOptimize'
```

## Define a search problem

The evaluator receives a named tuple of decisions and returns model outcomes.
For example, this analytical problem demonstrates a constrained maximization:

```julia
using JCGEOptimize

problem = OptimizationProblem(
    [DecisionVariable(:x; lower=0.0, upper=1.0)],
    decisions -> (benefit=decisions.x, cost=decisions.x^2);
    objectives=[Objective(:benefit, outcome -> outcome.benefit; sense=:max)],
    constraints=[OutcomeConstraint(:cost, outcome -> outcome.cost; upper=0.36)],
)

result = optimize(problem, GridSearch([0.0:0.1:1.0]))
result.best.decisions
evaluation_rows(result)
```

For an equilibrium application, the evaluator runs the model and extracts compact
outcomes. Supply `isvalid=outcome -> outcome.valid` using a `valid` field computed
from the actual solve status and residual checks. `on_error=:record` is available
when an application deliberately treats ordinary evaluator exceptions as failed
candidates; the default propagates them.

## Use Metaheuristics.jl

In an environment containing both packages:

```julia
import Metaheuristics

backend = MetaheuristicsBackend(
    options -> Metaheuristics.DE(N=24, options=options);
    seed=11, max_evaluations=400,
)
result = optimize(problem, backend)
result.best
result.stop_reason
```

The backend uses `failure_penalty=1e6` for rejected evaluations, in scaled
objective and constraint units. This finite numerical penalty avoids undefined
arithmetic in algorithms that calculate fitness-weighted averages. It is
configurable when constructing `MetaheuristicsBackend`; select a value large
relative to the normalized valid objectives and violations. Failed evaluations
remain marked as failures in the history and are excluded from reported optima.

For multiple objectives, provide several `Objective` definitions and an
appropriate algorithm such as `Metaheuristics.NSGA2`. Inspect `result.pareto`;
`result.best` is `nothing` when several objectives were declared. It is also
`nothing` when a single-objective search found no feasible candidate.

The [StandardCGE policy optimization example](https://github.com/equicirco/JCGEExamples.jl/tree/main/examples/StandardCGEPolicyOptimization)
maximizes household utility subject to a government-revenue floor. Its separate
development environment loads local JCGEExamples and JCGEOptimize checkouts and
compares the heuristic result with a grid search.

## Run package checks

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

These checks cover problem definitions, original-unit constraints, failed model
evaluations, objective directions, nondominated results, evaluation budgets,
seeded reproducibility, and package metadata.

## Build the documentation

From the repository root:

```sh
julia --project=docs -e 'using Pkg; Pkg.instantiate()'
julia --project=docs docs/make.jl
```

The documentation environment uses the package in the current checkout. Generated
documentation is written to `docs/build/`. CI builds and deploys it when the
`main` branch or a version tag is pushed.
