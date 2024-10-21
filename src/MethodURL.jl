# Based on code by Kristoffer Carlsson:
# https://github.com/JuliaLang/julia/issues/47709#issuecomment-2388629772

module MethodURL

using RegistryInstances: reachable_registries, registry_info
using URIs: URI
using Base: PkgId

function repo_and_path_to_url(repo, version, path, line)
    repo = chopsuffix(repo, ".git")
    # TODO: Handle more git forges
    if startswith(repo, "https://github.com")
        return join([repo, "blob", "v" * version, path * "#L$line"], "/")
    else
        error("failed to handle $repo")
    end
end

function repos_package(uuid)
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

# TODO: If package is devved use local path
# TODO: If package is added by URL, use that
function url(m::Method)
    M = parentmodule(m)
    uuid = PkgId(M).uuid
    line = m.line

    pkg_splitpath = splitpath(pkgdir(M))
    file_splitpath = splitpath(String(m.file))
    while !isempty(pkg_splitpath) && first(pkg_splitpath) == first(file_splitpath)
        popfirst!(pkg_splitpath)
        popfirst!(file_splitpath)
    end
    local_dir = join(file_splitpath, "/")

    v = string(pkgversion(M))
    urls = String[]
    for repo in repos_package(uuid)
        url = repo_and_path_to_url(repo, v, local_dir, line)
        push!(urls, url)
    end
    return urls
end

end # module
