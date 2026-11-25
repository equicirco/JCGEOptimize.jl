"""
    JCGEOptimize

Optimization around JCGE equilibrium models for policy design and parameter
optimization, with multiple objectives, constraints, and interchangeable backends.

Model evaluators delegate equilibrium calculations to JCGERuntime and return
model outcomes to this package. Search backends share decision, objective,
constraint, validation, and evaluation-history interfaces.
"""
module JCGEOptimize

export DecisionVariable, Objective, OutcomeConstraint, OptimizationProblem
export EvaluationRecord, evaluate, evaluation_rows
export AbstractSearchBackend, GridSearch, MetaheuristicsBackend
export OptimizationResult, optimize

include("problems.jl")
include("evaluation.jl")
include("search.jl")

end # module JCGEOptimize
