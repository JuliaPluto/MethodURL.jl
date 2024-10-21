using MethodURL
using Documenter

DocMeta.setdocmeta!(MethodURL, :DocTestSetup, :(using MethodURL); recursive=true)

makedocs(;
    modules=[MethodURL],
    authors="Adrian Hill <gh@adrianhill.de>",
    sitename="MethodURL.jl",
    format=Documenter.HTML(;
        canonical="https://adrhill.github.io/MethodURL.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/adrhill/MethodURL.jl",
    devbranch="main",
)
