using MethodURL
using Test
using JuliaFormatter: JuliaFormatter
using Aqua: Aqua
using JET: JET

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
    end
    # Write your tests here.
end
