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
using Pkg: Pkg

# Package to test URLs on
using LinearAlgebra: det # vendored stdlib on Julia >= 1.12
using Statistics: mean # upgradable stdlib with standalone repository
using Plots: Plots # monorepo with sub-packages and package extensions
using Unitful: Unitful # triggers the Plots extension UnitfulExt
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
                        MethodURL;
                        ignore = (
                            :UUID,
                            :inbase,
                            :fixup_stdlib_path,
                            :env_project_file,
                            :project_file_manifest_path,
                            :parsed_toml,
                            :project_names,
                        ),
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
        @testset "Base submodule" begin
            m = @which Iterators.take([1], 1)
            u = first(@inferred url(m))
            @test contains(u, "/base/")
            @test url_exists(u)
        end
        @testset "Core" begin
            # `parentmodule` of methods in boot.jl is Core, which is not `inbase`
            m = first(methods(Core.eval))
            u = first(@inferred url(m))
            @test contains(u, "/base/boot.jl")
            @test url_exists(u)
        end
        @testset verbose = true "Stdlib" begin
            @testset "within julialang/julia" begin
                m = @which @test true
                u = first(@inferred url(m))
                @test url_exists(u)
            end
            @testset "vendored stdlib" begin
                # LinearAlgebra is part of the julia repository up to Julia 1.11
                # and vendored from JuliaLang/LinearAlgebra.jl starting with Julia 1.12.
                # Since LinearAlgebra.jl publishes no version tags,
                # URLs have to point to the exact vendored commit.
                m = @which det(rand(2, 2))
                u = first(@inferred url(m))
                if VERSION >= v"1.12"
                    @test contains(u, "LinearAlgebra.jl/blob/")
                end
                @test url_exists(u)
            end
            @testset "standalone repository" begin
                # Statistics is an upgradable stdlib with a standalone repository.
                # When loaded from the stdlib directory (e.g. on Julia 1.10), the URL
                # points to the exact vendored commit, which always exists (unlike
                # version tags, e.g. the missing tag for Statistics.jl v1.10.0).
                # When upgraded through the registry, it points to the version tag.
                m = @which mean(rand(5))
                u = first(@inferred url(m))
                @test contains(u, "Statistics.jl/blob/")
                @test url_exists(u)
            end
        end

        @testset verbose = true "External" begin
            @testset "GitHub" begin
                m = @which Aqua.test_all(MethodURL)
                u = first(@inferred url(m))
                @test url_exists(u)
            end
            @testset "GitHub monorepo" begin
                # Plots.jl (>= v1.41.5) is a monorepo: the registry lists
                # Plots with `subdir = "Plots"`, and sub-package releases are
                # tagged `<name>-v<version>` following the TagBot convention.
                m = @which Plots.plot(1:2)
                u = first(@inferred url(m))
                @test contains(u, "/Plots.jl/blob/Plots-v")
                @test contains(u, "/Plots/src/")
                @test url_exists(u)
            end
            @testset "GitHub monorepo, version predating the monorepo" begin
                # RecipesBase v1.3.4 was released from the standalone repository
                # JuliaPlots/RecipesBase.jl before the package was moved into the
                # Plots.jl monorepo. The registry only stores the current repository
                # and subdirectory of a package, not historic ones, so URLs for
                # versions released before such a move cannot be constructed.
                m = first(methods(Plots.RecipesBase.create_kw_body))
                u = first(@inferred url(m))
                @test contains(u, "/Plots.jl/blob/RecipesBase-v")
                @test contains(u, "/RecipesBase/src/")
                if pkgversion(Plots.RecipesBase) <= v"1.3.4"
                    @test_broken url_exists(u) # no RecipesBase tags in Plots.jl
                else
                    @test url_exists(u)
                end
            end
            @testset "Package extension" begin
                # Methods of package extensions live in the repository
                # of the parent package.
                ext = Base.get_extension(Plots, :UnitfulExt)
                @test ext isa Module
                m = first(methods(ext.fixaxis!))
                u = first(@inferred url(m))
                @test contains(u, "/ext/UnitfulExt.jl")
                @test url_exists(u)
            end
            @testset "GitLab" begin
                m = @which arXiv"1234.5678"
                u = first(@inferred url(m))
                @test contains(u, "https://gitlab.com/")
                @test contains(u, "/-/blob/")
                @test_broken url_exists(u) # no tags in Arxiv.jl
            end
            @testset "Sourcehut" begin
                m = first(methods(gnll))
                u = first(@inferred url(m))
                @test contains(u, "https://git.sr.ht/")
                @test contains(u, "/tree/") && contains(u, "/item/")
                @test_broken url_exists(u) # no tags in GPMaxlik.jl
            end
        end

        @testset "Local package tracked by path" begin
            # During testing, MethodURL itself is tracked by a local path,
            # so its URLs point to local files.
            m = @which url(@which sqrt(1.0))
            u = first(@inferred url(m))
            @test startswith(u, "file://")
            local_path = replace(chopprefix(u, "file://"), r"#L\d+$" => "", "%20" => " ")
            @test isfile(local_path)
        end

        @testset "Package added by URL" begin
            old_project = dirname(Base.active_project())
            try
                mktempdir() do dir
                    Pkg.activate(dir; io = devnull)
                    Pkg.add(;
                        url = "https://github.com/JuliaLang/Example.jl",
                        rev = "master",
                        io = devnull,
                    )
                    # `Base.require` instead of `import` to avoid accessing the
                    # global binding `Main.Example` in an older world age
                    Example = Base.require(
                        Base.PkgId(
                            Base.UUID("7876af07-990d-54b4-ab0e-23690620f79a"), "Example"
                        ),
                    )
                    m = first(methods(Example.hello))
                    u = first(@inferred url(m))
                    @test u ==
                        "https://github.com/JuliaLang/Example.jl/blob/master/src/Example.jl#L$(m.line)"
                    @test url_exists(u)
                end
            finally
                Pkg.activate(old_project; io = devnull)
            end
        end

        @testset verbose = true "Errors" begin
            @testset "Method defined in Main" begin
                f_in_main() = 1
                m = first(methods(f_in_main))
                @test_throws ArgumentError url(m)
            end
            @testset "Anonymous function defined in Main" begin
                m = first(methods(x -> x^2))
                @test_throws ArgumentError url(m)
            end
            @testset "Method eval'd into a package" begin
                # Parsing from a string gives the method the file "none",
                # which is not an absolute path to a file in the package
                Core.eval(MethodURL, Meta.parse("__dummy_method_for_testing() = 1"))
                m = first(methods(MethodURL.__dummy_method_for_testing))
                @test m.file === :none
                @test_throws ArgumentError url(m)
            end
            @testset "Unknown git forge" begin
                @test_throws ArgumentError MethodURL.forge_url(
                    "https://example.com/owner/Package.jl.git", "v1.0.0", :tag, "src/foo.jl", 1
                )
            end
        end

        @testset "File URL construction" begin
            @test MethodURL.file_url("/home/user/pkg/src/foo.jl", 3) ==
                "file:///home/user/pkg/src/foo.jl#L3"
            # Spaces are percent-encoded
            @test MethodURL.file_url("/home/us er/pkg/src/foo.jl", 3) ==
                "file:///home/us%20er/pkg/src/foo.jl#L3"
            if Sys.iswindows()
                # Windows paths use forward slashes and a leading slash before the drive
                @test MethodURL.file_url("C:\\Users\\u\\pkg\\src\\foo.jl", 3) ==
                    "file:///C:/Users/u/pkg/src/foo.jl#L3"
            end
            # Relative paths cannot be turned into file URLs
            @test_throws ArgumentError MethodURL.file_url("none", 1)
        end

        @testset "URL construction for git forges" begin
            for (repo, expected) in [
                    "https://github.com/owner/Package.jl.git" =>
                        "https://github.com/owner/Package.jl/blob/v1.0.0/src/foo.jl#L42",
                    "https://gitlab.com/owner/Package.jl.git" =>
                        "https://gitlab.com/owner/Package.jl/-/blob/v1.0.0/src/foo.jl#L42",
                    "https://git.sr.ht/~owner/Package.jl" =>
                        "https://git.sr.ht/~owner/Package.jl/tree/v1.0.0/item/src/foo.jl#L42",
                    "https://bitbucket.org/owner/Package.jl.git" =>
                        "https://bitbucket.org/owner/Package.jl/src/v1.0.0/src/foo.jl#lines-42",
                    "https://codeberg.org/owner/Package.jl.git" =>
                        "https://codeberg.org/owner/Package.jl/src/tag/v1.0.0/src/foo.jl#L42",
                    # scp-like ssh remotes are normalized to HTTPS
                    "git@github.com:owner/Package.jl.git" =>
                        "https://github.com/owner/Package.jl/blob/v1.0.0/src/foo.jl#L42",
                ]
                @test MethodURL.forge_url(repo, "v1.0.0", :tag, "src/foo.jl", 42) == expected
            end
            # Codeberg (Forgejo) URLs distinguish the type of git ref
            @test MethodURL.forge_url(
                "https://codeberg.org/owner/Package.jl", "0123456789abcdef", :commit, "src/foo.jl", 42
            ) == "https://codeberg.org/owner/Package.jl/src/commit/0123456789abcdef/src/foo.jl#L42"
            @test MethodURL.forge_url(
                "https://codeberg.org/owner/Package.jl", "main", :branch, "src/foo.jl", 42
            ) == "https://codeberg.org/owner/Package.jl/src/branch/main/src/foo.jl#L42"
        end
    end
end
