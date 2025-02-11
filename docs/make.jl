using Documenter
using PowerSystems
using StorageSystemsSimulations
using DataStructures

pages = OrderedDict(
    "Welcome Page" => "index.md",
    "Quick Start Guide" => "quick_start_guide.md",
    "Tutorials" => Any[
        "Single State Model" => "tutorials/single_stage_model.md",
        "Simulation Model" => "tutorials/simulation_tutorial.md",
    ],
    "Explanation" => "explanation/stub.md",
    "How-to-Guides" => "how_to/stub.md",
    "Reference" => Any[
        "Formulation Library" => "reference/formulation_library/StorageDispatchWithReserves.md",
        "Developers" => "reference/developers/code_base_developer_guide/developer.md",
        "API" => "reference/api/StorageSystemsSimulations.md",
    ],
)

makedocs(;
    modules=[StorageSystemsSimulations],
    format=Documenter.HTML(; prettyurls=haskey(ENV, "GITHUB_ACTIONS")),
    sitename="StorageSystemsSimulations.jl",
    authors="Jose Daniel Lara, Rodrigo Henriquez-Auba, Sourabh Dalvi",
    pages=Any[p for p in pages],
)

deploydocs(;
    repo="github.com/NREL-Sienna/StorageSystemsSimulations.jl.git",
    target="build",
    branch="gh-pages",
    devbranch="main",
    devurl="dev",
    push_preview=true,
    versions=["stable" => "v^", "v#.#"],
)
