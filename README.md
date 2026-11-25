# JCGEOptimize

Policy design and parameter optimization for JCGE models, supporting multiple
objectives, constraints, and interchangeable optimization backends.

JCGEOptimize is designed as an optional optimization layer in the
[JCGE](https://jcge.org) framework. It delegates equilibrium calculations to
JCGERuntime and reporting to JCGEOutput.

Version **0.0.1 is unreleased** and currently provides the package scaffold.
The optimization interfaces and backend integrations are under development.

## Repository contents

- `src/`: Julia package source.
- `test/`: package loading and metadata checks.
- `docs/`: Documenter documentation covering design, usage, API, and citation.
- `.github/workflows/`: package tests and documentation deployment.
- `Project.toml`: package definition and Julia compatibility.
- `CHANGELOG.md`: version history and unreleased changes.
- `CITATION.cff`: machine-readable citation metadata.

See the [documentation sources](docs/src/index.md) for the package design and
development instructions.

## License and citation

JCGEOptimize is licensed under the [Apache License 2.0](LICENSE).
Citation information is provided in [CITATION.cff](CITATION.cff) and the
[citation guide](docs/src/citation.md).
