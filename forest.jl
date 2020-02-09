module RandomForest

using Random

export Forest,Feature

struct Feature
    key
    index::Unsigned
end

Feature(x) = Feature(x,x)

struct Sample
    key
    index::Unsigned
end

Sample(x) = Sample(x,x)

struct Split
    feature::Feature
    value::Float64
end



struct Node
    split::Union{Split,Nothing}
    children::Union{Tuple{Node,Node},Nothing}
    samples::Union{Array{Sample},Nothing}
end

Node(forest) = Node(nothing,nothing,nothing,forest)
Node(forest,samples::Array{Sample}) = Node(nothing,nothing,samples)

struct Tree
    root::Node
end

Tree(prototype::Node) = Tree(prototype,prototype.forest)

struct Parameters
    sample_subsample::Unsigned
    input_subsample::Unsigned
    output_subsample::Unsigned

end

mutable struct Forest
    prototype::Node
    trees::Array{Tree}
    input_matrix::AbstractMatrix
    output_matrix::AbstractMatrix
    input_features::Array{Feature}
    output_features::Array{Feature}
    samples::Array{Sample}
end

function Forest(input;output=nothing,input_features=nothing,output_features=nothing,samples=nothing)
    input_matrix = convert(AbstractMatrix,input)
    if output === nothing
        output_matrix = convert(AbstractMatrix,input)
    else
        output_matrix = convert(AbstractMatrix,output)
    end
    if input_features === nothing
        input_features = 1:(size(input_matrix)[2]) |> (x) -> map(Feature,x) |> collect
    end
    if output_features === nothing
        output_features = 1:(size(output_matrix)[2]) |> (x) -> map(Feature,x) |> collect
    end
    @assert ((size(input_matrix)[1]) == (size(output_matrix)[1]))
    if samples === nothing
        samples = 1:(size(output_matrix)[1]) |> (x) -> map(Sample,x) |> collect
    end
    return Forest(
        Node(forest,copy(samples)),
        [],
        input_matrix,
        output_matrix,
        input_features,
        output_features,
        samples
    )

end
#
# function generate!(forest::Forest,n=100)
#     forest.trees =
#         (1:n) .|>
#         (i) -> generate!(forest.prototype)
#
# end

function generate!(forest::Forest,sub=100)::Tree

    sample_subsample = Random.rand(forest.samples,sub)
    input_feature_subsample = Random.rand(forest.input_features,sub)
    output_feature_subsample = Random.rand(forest.output_features,sub)

    Tree(forest.prototype)
end

function derive(prototpye::Node,sample_sub::Array{Sample},input_feature_sub::Array{Feature},output_feature_sub::Array{Feature})

end

function trial_input()
    (1:100) |> Array |> (x) -> reshape(x,(50,2))
end

function random_trial_input()
    collect(zip((1:1000),rand(1000)))
end

end
