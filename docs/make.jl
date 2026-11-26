using Documenter
using JCGEOptimize

makedocs(
    sitename = "JCGEOptimize",
    modules = [JCGEOptimize],
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        assets = [
            "assets/favicon.ico",
            "assets/logo.css",
            "assets/logo-theme.js",
        ],
    ),
    pages = [
        "Home" => "index.md",
        "Design" => "design.md",
        "Usage" => "usage.md",
        "API" => "api.md",
        "Citation" => "citation.md",
    ],
)

if get(ENV, "GITHUB_EVENT_NAME", "") != "pull_request"
    deploydocs(
        repo = "github.com/equicirco/JCGEOptimize.jl",
        cname = "optimize.jcge.org",
        devbranch = "main",
        versions = ["stable" => "v^", "v#.#", "dev" => "dev"],
    )
end
