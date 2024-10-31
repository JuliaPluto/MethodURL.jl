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


# Context

Julia has a function `Base.url(::Method)`, but this function only works for methods from Base. It worked on non-Base methods in previous Julia versions, but this functionality disappeared (see https://github.com/JuliaLang/julia/issues/47709). This package aims to reimplement that functionality for modern Julia versions.

# Work in progress
This package is still being worked on. When it is finished, we want to use it in Pluto.jl stack frames, see https://github.com/fonsp/Pluto.jl/pull/2813


