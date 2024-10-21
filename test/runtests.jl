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
                @test isnothing(check_all_explicit_imports_are_public(MethodURL))
            end
            @testset "Improper qualified accesses" begin
                @test isnothing(check_all_qualified_accesses_via_owners(MethodURL))
                @test isnothing(check_no_self_qualified_accesses(MethodURL))
                @test isnothing(check_all_qualified_accesses_are_public(MethodURL))
            end
        end
    end
end
