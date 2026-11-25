# Usage

## Load the development package

From a local checkout:

```sh
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. -e 'using JCGEOptimize'
```

This unreleased version provides the package scaffold. The current entry point
loads the module; the optimization interfaces are under development.

## Run package checks

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

These checks cover package loading, its module documentation, and consistency of
the package version with the changelog and citation metadata.

## Build the documentation

From the repository root:

```sh
julia --project=docs -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()'
julia --project=docs docs/make.jl
```

The documentation environment uses the package in the current checkout. Generated
documentation is written to `docs/build/`. CI checks the documentation on pull
requests and deploys it from the `main` branch and version tags.
