@testset "grid optimum and evaluation history" begin
    variables = [DecisionVariable(:x; lower = -1, upper = 1, initial = 0),
        DecisionVariable(:y; lower = -1, upper = 1, initial = 0)]
    problem = OptimizationProblem(variables, d -> (d.x - 0.5)^2 + (d.y + 0.5)^2;
        objectives = [Objective(:loss, identity; scale = 10)])
    seen = Int[]
    result = optimize(problem, GridSearch([[-1, 0, 0.5, 1], [-1, -0.5, 0, 1]]);
        callback = record -> push!(seen, record.id))
    @test result.best.decisions == (x = 0.5, y = -0.5)
    @test result.best.objectives == [0.0]
    @test seen == collect(1:16)
    rows = evaluation_rows(result)
    @test length(rows) == 16 && rows[1].decision_x == 0
    @test rows[1].objective_loss == 0.5
    @test result.pareto == [result.best]
    @test_throws DimensionMismatch optimize(problem, GridSearch([[0, 1]]))
    @test_throws ArgumentError optimize(problem, GridSearch([[0, 2], [0, 1]]))
    @test_throws ArgumentError GridSearch([Float64[]])

    constrained = OptimizationProblem([variables[1]], d -> (score = d.x, valid = d.x < 1);
        objectives = [Objective(:score, o -> o.score; sense = :max)],
        constraints = [OutcomeConstraint(:ceiling, o -> o.score; upper = 0.5)],
        isvalid = o -> o.valid)
    limited = optimize(constrained, GridSearch([[-1, 0, 0.5, 1]]))
    @test limited.best.decisions.x == 0.5
    @test any(row.status == "invalid" && !row.feasible for row in evaluation_rows(limited))
    @test hasproperty(first(evaluation_rows(limited)), :violation_ceiling)
    impossible = OptimizationProblem([variables[1]], d -> d.x;
        objectives = [Objective(:score, identity)], isvalid = _ -> false)
    failed = optimize(impossible, GridSearch([[0, 1]]))
    @test failed.best === nothing && isempty(failed.pareto)
end

@testset "multiple objectives retain feasible nondominated decisions" begin
    problem = OptimizationProblem([DecisionVariable(:x; lower = 0, upper = 1)], identity;
        objectives = [Objective(:distance_left, d -> d.x^2),
            Objective(:closeness_right, d -> -(1 - d.x)^2; sense = :max)])
    result = optimize(problem, GridSearch([[0, 0.5, 1]]))
    @test result.best === nothing
    @test length(result.pareto) == 3
    dominated = OptimizationProblem([DecisionVariable(:x; lower = 0, upper = 1)], identity;
        objectives = [Objective(:first, d -> d.x), Objective(:second, d -> d.x)])
    result = optimize(dominated, GridSearch([[0, 0.5, 1]]))
    @test length(result.pareto) == 1 && only(result.pareto).decisions.x == 0
end
