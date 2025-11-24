using MethodURL

# Linting tests
using Test
using Aqua: Aqua
using JET: JET
using ExplicitImports:
    check_no_implicit_imports,
    check_no_stale_explicit_imports,
    check_all_explicit_imports_via_owners,
    check_all_explicit_imports_are_public,
    check_no_self_qualified_accesses,
    check_all_qualified_accesses_via_owners,
    check_all_qualified_accesses_are_public

# Packages used for testing
using HTTP: request
using InteractiveUtils: @which

# Package to test URLs on
using LinearAlgebra: det
using Statistics: mean
using Plots: Plots # has sub-repositories
using Arxiv: @arXiv_str # hosted on GitLab
using GPMaxlik: gnll # hosted on sourcehut

function url_exists(url)
    url = replace(url, r"#.*$" => "") # strip line number
    response = request("GET", url; status_exception = false, redirect = true, retry = true)
    if 200 ≤ response.status < 400
        return true
    else
        @warn "Failed to request URL" url response.status response
        return false
    end
end

@testset verbose = true "MethodURL.jl" begin
    @testset verbose = true "Linting" begin
        @testset "Aqua.jl" begin
            Aqua.test_all(MethodURL)
        end
        if VERSION > v"1.11" # JET v0.11 requires Julia v1.12
            @testset "JET tests" begin
                JET.test_package(MethodURL; target_defined_modules = true)
            end
        end

        @testset "ExplicitImports.jl" begin
            @testset "Improper implicit imports" begin
                @test isnothing(check_no_implicit_imports(MethodURL))
            end
            @testset "Improper explicit imports" begin
                @test isnothing(check_no_stale_explicit_imports(MethodURL))
                @test isnothing(check_all_explicit_imports_via_owners(MethodURL))
                @test isnothing(
                    check_all_explicit_imports_are_public(
                        MethodURL; ignore = (:PkgId, :UUID, :inbase)
                    ),
                )
            end
            @testset "Improper qualified accesses" begin
                @test isnothing(check_all_qualified_accesses_via_owners(MethodURL))
                @test isnothing(check_no_self_qualified_accesses(MethodURL))
                @test isnothing(
                    check_all_qualified_accesses_are_public(
                        MethodURL; ignore = (:GIT_VERSION_INFO,)
                    ),
                )
            end
        end
    end
    @testset verbose = true "URL" begin
        @testset "Base" begin
            m = @which sqrt(0.0)
            u = first(@inferred url(m))
            @test url_exists(u)
        end
        @testset "Stdlib" begin
            @testset "within julialang/julia" begin
                m = @which @test true
                u = first(@inferred url(m))
                @test url_exists(u)

                m = @which det(rand(2, 2))
                u = first(@inferred url(m))
                @test url_exists(u)
            end
            @testset "standalone repository" begin
                m = @which mean(rand(5))
                u = first(@inferred url(m))
                if VERSION >= v"1.11" # no tag for Statistics.jl v1.10.0
                    @test url_exists(u)
                end
            end
        end

        @testset "External" begin
            @testset "GitHub" begin
                m = @which Aqua.test_all(MethodURL)
                u = first(@inferred url(m))
                @test url_exists(u)
            end
            # @testset "GitHub monorepo" begin
            #     m = first(methods(Plots.RecipesBase.create_kw_body))
            #     u = first(@inferred url(m))
            #     @test url_exists(u)
            # end
            @testset "GitLab" begin
                m = @which arXiv"1234.5678"
                u = first(@inferred url(m))
                @test_broken url_exists(u) # no tags in Arxiv.jl
            end
            @testset "Sourcehut" begin
                m = first(methods(gnll))
                u = first(@inferred url(m))
                @test_broken url_exists(u) # no tags in GPMaxlik.jl
            end
        end
        # @testset "Local" begin
        #     m = @which url(@which sqrt(1.0))
        #     u = first(@inferred url(m))
        #     @test_broken url_exists(u)
        # end
    end
end
