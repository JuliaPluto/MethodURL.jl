using MethodURL
using Test
using Aqua
using JET

@testset "MethodURL.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(MethodURL)
    end
    @testset "Code linting (JET.jl)" begin
        JET.test_package(MethodURL; target_defined_modules = true)
    end
    # Write your tests here.
end
