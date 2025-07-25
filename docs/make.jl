using
  Documenter,
  DocumenterCitations,
  Literate,
  CairoMakie,  # so that Literate.jl does not capture precompilation output
  FourierFlows

#####
##### Generate examples
#####

bib_filepath = joinpath(@__DIR__, "src/references.bib")
bib = CitationBibliography(bib_filepath, style=:authoryear)

const EXAMPLES_DIR = joinpath(@__DIR__, "..", "examples")
const OUTPUT_DIR   = joinpath(@__DIR__, "src/literated")

examples = [
  "OneDShallowWaterGeostrophicAdjustment.jl",
]

for example in examples
  example_filepath = joinpath(EXAMPLES_DIR, example)
  withenv("GITHUB_REPOSITORY" => "FourierFlows/FourierFlowsDocumentation") do
    Literate.markdown(example_filepath, OUTPUT_DIR; flavor = Literate.DocumenterFlavor())
    Literate.notebook(example_filepath, OUTPUT_DIR)
    Literate.script(example_filepath, OUTPUT_DIR)
  end
end

#####
##### Build and deploy docs
#####

format = Documenter.HTML(
    collapselevel = 2,
       prettyurls = get(ENV, "CI", nothing) == "true",
        canonical = "https://fourierflows.github.io/FourierFlowsDocumentation/stable",
)

pages = [
    "Home" => "index.md",
    "Installation Instructions" => "installation_instructions.md",
    "Code Basics" => "basics.md",
    "Grids" => "grids.md",
    "Aliasing" => "aliasing.md",
    "Problem" => "problem.md",
    "Time stepping" => "timestepping.md",
    "Diagnostics" => "diagnostics.md",
    "Output" => "output.md",
    "GPU" => "gpu.md",
    "Examples" => [ 
      "literated/OneDShallowWaterGeostrophicAdjustment.md",
      ],
    "Contributor's guide" => "contributing.md",
    "Library" => [ 
      "Contents" => "library/outline.md",
      "Public" => "library/public.md",
      "Private" => "library/internals.md",
      "Function index" => "library/function_index.md",
      ],
    "References" => "references.md",
]

makedocs(sitename = "FourierFlows.jl",
          authors = "Gregory L. Wagner, Navid C. Constantinou, and contributors",
          modules = [FourierFlows],
           format = format,
            pages = pages,
          plugins = [bib],
          doctest = true,
         warnonly = [:cross_references],
            clean = true,
        checkdocs = :exports)

@info "Cleaning up temporary .jld2 and .nc files created by doctests or literated examples..."

"""
    recursive_find(directory, pattern)

Return list of filepaths within `directory` that contains the `pattern::Regex`.
"""
recursive_find(directory, pattern) =
    mapreduce(vcat, walkdir(directory)) do (root, dirs, files)
        joinpath.(root, filter(contains(pattern), files))
    end

files = []
for pattern in [r"\.jld2", r"\.nc"]
  global files = vcat(files, recursive_find(@__DIR__, pattern))
end

for file in files
  rm(file)
end

# Replace with below once https://github.com/JuliaDocs/Documenter.jl/pull/2692 is merged and available.
#  deploydocs(repo = "github.com/FourierFlows/FourierFlows.jl",
#    deploy_repo = "github.com/FourierFlows/FourierFlowsDocumentation",
#    devbranch = "main",
#    forcepush = true,
#    push_preview = true,
#    versions = ["stable" => "v^", "dev" => "dev", "v#.#.#"])

if get(ENV, "GITHUB_EVENT_NAME", "") == "pull_request"
    deploydocs(repo = "github.com/FourierFlows/FourierFlows.jl",
               repo_previews = "github.com/FourierFlows/FourierFlowsDocumentation",
               devbranch = "main",
               forcepush = true,
               push_preview = true,
               versions = ["stable" => "v^", "dev" => "dev", "v#.#.#"])
else
    repo = "github.com/FourierFlows/FourierFlowsDocumentation"
    withenv("GITHUB_REPOSITORY" => repo) do
        deploydocs(; repo,
                     devbranch = "main",
                     versions = ["stable" => "v^", "dev" => "dev", "v#.#.#"],
                     forcepush = true)
    end
end
