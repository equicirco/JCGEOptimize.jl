"""Interface for interchangeable outer-search backends."""
abstract type AbstractSearchBackend end

"""
    GridSearch(axes)

Evaluate the Cartesian product of one nonempty axis per decision. The initial
candidate is evaluated first and is not repeated if it also occurs on the grid.
This deterministic backend provides a comparison for heuristic searches.
"""
struct GridSearch <: AbstractSearchBackend
    axes::Vector{Vector{Float64}}
    function GridSearch(axes)
        values = [unique(Float64.(collect(axis))) for axis in axes]
        all(!isempty(axis) && all(isfinite, axis) for axis in values) ||
            throw(ArgumentError("Grid axes must be nonempty and finite"))
        new(values)
    end
end

"""
    MetaheuristicsBackend(algorithm_factory; seed=1, max_evaluations=1000, failure_penalty=1e6)

Optional Metaheuristics.jl search backend. Import `Metaheuristics` to activate it.
The factory receives the configured `Metaheuristics.Options` and must use those
options, for example `options -> Metaheuristics.ECA(N=20, options=options)`.

The initial candidate and all failed evaluations count towards the hard model
evaluation budget. Each call creates a new algorithm with its own seeded RNG.
Rejected evaluations are passed to the algorithm using the finite positive
`failure_penalty` for scaled minimization objectives and constraint violations.
This prevents undefined arithmetic in algorithms using fitness-weighted averages.
The original failure records are retained and can never qualify as feasible.
"""
struct MetaheuristicsBackend{F} <: AbstractSearchBackend
    algorithm_factory::F
    seed::Int
    max_evaluations::Int
    failure_penalty::Float64
    function MetaheuristicsBackend(factory::F; seed::Integer = 1,
        max_evaluations::Integer = 1000, failure_penalty::Real = 1e6) where F
        seed >= 0 || throw(ArgumentError("Seed must be nonnegative"))
        max_evaluations >= 2 || throw(ArgumentError("At least two evaluations are required"))
        penalty = Float64(failure_penalty)
        isfinite(penalty) && penalty > 0 ||
            throw(ArgumentError("Failure penalty must be finite and positive"))
        new{F}(factory, Int(seed), Int(max_evaluations), penalty)
    end
end

"""
    OptimizationResult

Search results containing the problem, all evaluation records, termination reason,
and backend metadata. `best` is the best feasible evaluated candidate for one
objective, or `nothing` when none is feasible or several objectives were declared.
`pareto` contains feasible nondominated candidates. These are search results, not
certificates of global optimality or equilibrium uniqueness.
"""
struct OptimizationResult{P,M}
    problem::P
    evaluations::Vector{EvaluationRecord}
    best::Union{Nothing,EvaluationRecord}
    pareto::Vector{EvaluationRecord}
    stop_reason::String
    metadata::M
end

function search_result(problem, evaluations, reason, metadata)
    feasible = filter(record -> record.feasible, evaluations)
    best = nothing
    pareto = EvaluationRecord[]
    if !isempty(feasible)
        if length(problem.objectives) == 1
            best = feasible[argmin([only(minimized_objectives(problem, record)) for record in feasible])]
            push!(pareto, best)
        else
            targets = [minimized_objectives(problem, record) for record in feasible]
            for (i, record) in enumerate(feasible)
                dominated = any(all(other .<= targets[i]) && any(other .< targets[i])
                    for other in targets)
                dominated || push!(pareto, record)
            end
        end
    end
    return OptimizationResult(problem, evaluations, best, pareto, String(reason), metadata)
end

"""
    optimize(problem, backend; callback=record->nothing) -> OptimizationResult

Run an outer search. `callback` receives each completed evaluation in order.
Only candidates passing both model validation and outcome constraints enter the
reported optimum or nondominated set.
"""
function optimize(problem::OptimizationProblem, backend::AbstractSearchBackend; callback = record -> nothing)
    if backend isa MetaheuristicsBackend
        throw(ArgumentError("Import Metaheuristics to activate its JCGEOptimize extension"))
    end
    throw(ArgumentError("No optimize method for backend $(typeof(backend))"))
end

function optimize(problem::OptimizationProblem, backend::GridSearch; callback = record -> nothing)
    length(backend.axes) == length(problem.decisions) || throw(DimensionMismatch("Wrong grid axis count"))
    for (axis, variable) in zip(backend.axes, problem.decisions)
        all(variable.lower <= value <= variable.upper for value in axis) ||
            throw(ArgumentError("Grid axis exceeds decision bounds"))
    end
    records = EvaluationRecord[]
    initial = Tuple(variable.initial for variable in problem.decisions)
    function record!(point)
        record = evaluate(problem, collect(point); id = length(records) + 1)
        push!(records, record)
        callback(record)
    end
    record!(initial)
    for point in Iterators.product(backend.axes...)
        point == initial || record!(point)
    end
    return search_result(problem, records, "Grid exhausted", (backend = :grid,))
end

struct EvaluationLimit <: Exception end
