using MethodURL

using Test
using JuliaFormatter: JuliaFormatter
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

using HTTP: request

function url_exists(url)
    response = request("GET", url; status_exception=false, redirect=true, retry=true)
    if 200 ≤ response.status < 400
        return true
    else
        @warn "Failed to request URL" url response.status response
        return false
    end
end

@testset verbose = true "MethodURL.jl" begin
    @testset verbose = true "Linting" begin
        @testset "Code formatting (JuliaFormatter.jl)" begin
            @test JuliaFormatter.format(MethodURL; verbose=false, overwrite=false)
        end
        @testset "Code quality (Aqua.jl)" begin
            Aqua.test_all(MethodURL)
        end
        @testset "Code linting (JET.jl)" begin
            JET.test_package(MethodURL; target_defined_modules=true)
        end

        @testset "Code imports (ExplicitImports.jl)" begin
            @testset "Improper implicit imports" begin
                @test isnothing(check_no_implicit_imports(MethodURL))
            end
            @testset "Improper explicit imports" begin
                @test isnothing(check_no_stale_explicit_imports(MethodURL))
                @test isnothing(check_all_explicit_imports_via_owners(MethodURL))
                @test isnothing(
                    check_all_explicit_imports_are_public(
                        MethodURL; ignore=(:PkgId, :inbase)
                    ),
                )
            end
            @testset "Improper qualified accesses" begin
                @test isnothing(check_all_qualified_accesses_via_owners(MethodURL))
                @test isnothing(check_no_self_qualified_accesses(MethodURL))
                @test isnothing(
                    check_all_qualified_accesses_are_public(
                        MethodURL; ignore=(:GIT_VERSION_INFO,)
                    ),
                )
            end
        end
    end
    @testset verbose = true "URL" begin
        @testset "Base" begin
            m1 = @which sqrt(1.0)
            u1 = first(@inferred url(m1))
            # @test url_exists(u1)
        end
        # @testset "Stdlib" begin
        #     m2 = @which @test true
        #     u2 = first(@inferred url(m2))
        #     # @test url_exists(u2)
        # end
        # @testset "Local" begin
        #     _m = @which sqrt(1.0)
        #     m3 = @which url(_m)
        #     u3 = first(@inferred url(m3))
        #     # @test url_exists(u3)
        # end
        @testset "External" begin
            m4 = @which Aqua.test_all(MethodURL)
            u4 = first(@inferred url(m4))
            # @test url_exists(u4)
        end
    end
end
