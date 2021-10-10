using Distributed
@everywhere using StatsBase, DataStructures, IterTools, SharedArrays

@everywhere @views correlate(ts, i; max_correlation_length=300) = takewhile(<=(max_correlation_length), imap(t -> t - ts[i], ts[i:end]));
@everywhere @views correlate(ts; max_correlation_length=300) = idx -> correlate(ts, idx; max_correlation_length=max_correlation_length);
# ts = SharedArray{UInt}(parse.(UInt, readlines("./channels/ch0.txt")));
@everywhere ⊎ = merge!

y(ts) = Iterators.accumulate(⊎ , imap(counter ∘ correlate(ts), 1:length(ts)))

G₂(times, n::Int; max_correlation_length=300)::Accumulator{UInt, UInt} = @distributed (⊎) for i ∈ 1:n
                @views (counter ∘ correlate(times, max_correlation_length=max_correlation_length))(i)
                end

g₂(times::SharedArray{UInt}, n::Int)::Dict{UInt, Float64} = begin
    G2 = G₂(times, n);
    norm(G2)
end

norm(x) = Dict{Any, Float64}(Pair.(keys(x), values(x) ./ mean(values(x))))

bin(dict, size_of_bin) = Dict(Pair(i, sum(get(dict, j, (mean∘ values)(dict)) for j in i:i+size_of_bin)) for i in 3:size_of_bin:(length(dict)))

