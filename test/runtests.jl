using JCGEOptimize
using Test
using TOML

@testset "JCGEOptimize package scaffold" begin
    @test nameof(JCGEOptimize) == :JCGEOptimize
    @test haskey(Base.Docs.meta(JCGEOptimize),
        Base.Docs.Binding(JCGEOptimize, :JCGEOptimize))

    root = dirname(@__DIR__)
    project = TOML.parsefile(joinpath(root, "Project.toml"))
    version = project["version"]
    @test pkgversion(JCGEOptimize) == VersionNumber(version)
    @test occursin("v$(version) -", read(joinpath(root, "CITATION.cff"), String))
    @test occursin("## [$(version)]", read(joinpath(root, "CHANGELOG.md"), String))
end
