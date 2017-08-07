struct CardinalDict{K,V} <: Associative{K,V}
    valued::BitArray{1}
    values::Vector{V}
    
    function CardinalDict{V}(n::K) where K<:Integer where V
        valued = falses(n)
        values = Vector{V}(n)
        T = type_for_indexing(n)
        return new{T,V}(valued, values)
    end
end

function CardinalDict(values::Vector{T}) where T
    n = length(values)
    dict = CardinalDict{T}(n)
    for i in 1:n
        @inbounds dict[i] = values[i]
    end
    return dict
end

const SInt = Union{Int8, Int16, Int32, Int64, Int128}

# this allows eval(parse(string(dict::CardinalDict))) to work
function CardinalDict(pairs::Vector{T}) where T<:AbstractArray{P,1} where P<:Pair{I,V} where I<:SInt where V
    n = length(pairs)
    thekeys = map(first, pairs)
    thevalues = map(last, pairs)
    thekeymax = maximum(thekeys)
    dict = CardinalDict(thekeymax)
    for i in 1:n
        @inbounds dict[thekeys[i]] = thevalues[i]
    end
    return dict
end

@inline function Base.haskey(dict::CardinalDict{K,V}, key::K) where {K,V}
   return getindex(dict.valued, key)
end
@inline Base.haskey(dict::CardinalDict{K,V}, key::J) where {J,K,V} =
    haskey(dict, key%K)

function Base.getindex(dict::CardinalDict{K,V}, key::K) where {K,V}
    haskey(dict, key) || throw(ErrorException("Key (index) $(key) has not been given a value"))
    @inbounds return getindex(dict.values, key)
end
@inline Base.getindex(dict::CardinalDict{K,V}, key::J) where {J,K,V} =
    getindex(dict, key%K)

function Base.setindex!(dict::CardinalDict{K,V}, value::V, key::K) where {K,V}
    0 < key <= keymax(dict) || throw(ErrorException("Key (index) $(key) is outside of the domain 1:$(keymax(dict))."))
    @inbounds begin
        setindex!(dict.valued, true, key)
        setindex!(dict.values, value, key)
    end
    return dict
end
@inline Base.setindex!(dict::CardinalDict{K,V}, value::V, key::J) where J where K where V =
    setindex!(dict, value, key%K)
