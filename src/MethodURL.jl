# Based on code by Kristoffer Carlsson:
# https://github.com/JuliaLang/julia/issues/47709#issuecomment-2388629772

module MethodURL

using Base: PkgId, UUID, inbase
using RegistryInstances: reachable_registries, registry_info

export url

function repo_and_path_to_url(repo, version, path, line)
    repo = chopsuffix(repo, ".git")
    # TODO: Handle more git forges
    if startswith(repo, "https://github.com")
        return join([repo, "blob", "v" * version, path * "#L$line"], "/")
    else
        error("Failed to construct URL for repository $repo.")
    end
end

# Find repository in reachable registries by looking up UUID
function repos_package(uuid::UUID)
    repos = String[]
    for reg in reachable_registries()
        entry = get(reg, uuid, nothing)
        if entry !== nothing
            info = registry_info(entry)
            push!(repos, info.repo)
        end
    end
    return repos
end

# Return errors instead of `nothing`
function _uuid(M::Module)
    uuid = PkgId(M).uuid
    isnothing(uuid) && error("Failed to find UUID of package $M.")
    return uuid
end

# Return errors instead of `nothing`
function _pkgdir(M::Module)
    dir = pkgdir(M)
    isnothing(dir) && error("Failed to find directory of package $M.")
    return dir
end

# TODO: If package is devved use local path
# TODO: If package is added by URL, use that
function url(m::Method)
    M = parentmodule(m)
    file = String(m.file)
    line = m.line

    urls = String[]
    if inbase(M)
        # adapted from https://github.com/JuliaLang/julia/blob/8f5b7ca12ad48c6d740e058312fc8cf2bbe67848/base/methodshow.jl#L382-L388
        commit = Base.GIT_VERSION_INFO.commit
        if isempty(commit)
            url = "https://github.com/JuliaLang/julia/tree/v$VERSION/base/$file#L$line"
        else
            url = "https://github.com/JuliaLang/julia/tree/$commit/base/$file#L$line"
        end
        push!(urls, url)
    else
        uuid = _uuid(M)
        pkg_splitpath = splitpath(_pkgdir(M))
        file_splitpath = splitpath(file)
        while !isempty(pkg_splitpath) && first(pkg_splitpath) == first(file_splitpath)
            popfirst!(pkg_splitpath)
            popfirst!(file_splitpath)
        end
        local_dir = join(file_splitpath, "/")
        # @info M file uuid _pkgdir(M) local_dir

        v = string(pkgversion(M))
        for repo in repos_package(uuid)
            url = repo_and_path_to_url(repo, v, local_dir, line)
            push!(urls, url)
        end
    end
    return urls
end

end # module
