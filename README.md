# MethodURL

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://adrhill.github.io/MethodURL.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://adrhill.github.io/MethodURL.jl/dev/)
[![Build Status](https://github.com/adrhill/MethodURL.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/adrhill/MethodURL.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/adrhill/MethodURL.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/adrhill/MethodURL.jl)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

This package gives a URL to github/gitlab/etc where a method from a package is defined. 

# Example

```julia
julia> import MethodURL, Example

julia> MethodURL.url(
          methods(Example.hello)[1]
       )
1-element Vector{String}:
 "https://github.com/JuliaLang/Example.jl/blob/v0.5.5/src/Example.jl#L9"

```

URLs are constructed according to the origin of the method:

- Methods from `Base`, `Core` and stdlibs link to the matching release in the [JuliaLang/julia](https://github.com/JuliaLang/julia) repository.
  Stdlibs that are vendored from their own repository (e.g. Pkg.jl, LinearAlgebra.jl on Julia ≥ 1.12) link to the exact vendored commit in that repository.
- Methods from packages tracked by a local path (e.g. via `Pkg.develop`) link to the local file via a `file://` URL.
- Methods from packages added by URL link to that repository at the tracked revision.
- Methods from registered packages link to the repository listed in the registry at the version tag of the loaded package, including packages in monorepo subdirectories and package extensions.
  One URL is returned per registry the package is found in.

Supported git forges: GitHub, GitLab (including self-hosted instances), sourcehut, Bitbucket and Codeberg.
An error is thrown if no URL can be constructed.

Note that a constructed URL can still point to a non-existent page,
e.g. if a package release was never tagged in its repository.

# Context

Julia has a function `Base.url(::Method)`, but this function only works for methods from Base. It worked on non-Base methods in previous Julia versions, but this functionality disappeared (see https://github.com/JuliaLang/julia/issues/47709). This package aims to reimplement that functionality for modern Julia versions.

# Work in progress
This package is still being worked on. When it is finished, we want to use it in Pluto.jl stack frames, see https://github.com/fonsp/Pluto.jl/pull/2813


