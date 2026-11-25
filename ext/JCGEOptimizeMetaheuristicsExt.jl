module JCGEOptimizeMetaheuristicsExt

import JCGEOptimize as O
import Metaheuristics as M
using Random

function O.optimize(problem::O.OptimizationProblem, backend::O.MetaheuristicsBackend;
    callback = record -> nothing)
    records = O.EvaluationRecord[]
    options = M.Options(seed = backend.seed, f_calls_limit = backend.max_evaluations - 1,
        iterations = backend.max_evaluations, h_tol = 0.0, rng = Random.Xoshiro(backend.seed))
    algorithm = backend.algorithm_factory(options)
    algorithm isa M.AbstractAlgorithm || throw(ArgumentError("Factory must return a Metaheuristics algorithm"))
    algorithm.options === options || throw(ArgumentError("Algorithm factory must use the supplied options"))
    options.parallel_evaluation && throw(ArgumentError("This backend evaluates candidates serially"))

    function payload(x)
        length(records) < backend.max_evaluations || throw(O.EvaluationLimit())
        record = O.evaluate(problem, x; id = length(records) + 1)
        push!(records, record)
        callback(record)
        values = record.status == :valid ? O.minimized_objectives(problem, record) :
            fill(backend.failure_penalty, length(problem.objectives))
        objective = length(values) == 1 ? only(values) : values
        residuals = record.status == :valid ? O.constraint_residuals(problem, record.constraints) :
            fill(backend.failure_penalty,
                max(1, sum(isfinite(c.lower) + isfinite(c.upper) for c in problem.constraints; init = 0)))
        return objective, isempty(residuals) ? [0.0] : residuals, [0.0]
    end

    initial = [variable.initial for variable in problem.decisions]
    reason = "Evaluation budget reached"
    try
        M.set_user_solutions!(algorithm, initial, payload(initial); verbose = false)
        bounds = [variable.lower for variable in problem.decisions]'
        bounds = vcat(bounds, [variable.upper for variable in problem.decisions]')
        state = M.optimize(payload, bounds, algorithm)
        reason = M.termination_status_message(state)
    catch error
        error isa O.EvaluationLimit || rethrow()
    end
    return O.search_result(problem, records, reason,
        (backend = :metaheuristics, algorithm = string(typeof(algorithm.parameters)),
         seed = backend.seed, max_evaluations = backend.max_evaluations,
         failure_penalty = backend.failure_penalty,
         backend_version = string(pkgversion(M))))
end

end # module
