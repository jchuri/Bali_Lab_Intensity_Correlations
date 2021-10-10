import Base: string, parse, -, +

"""

Creates a Timestamp type with the following elements:

    * zero (is there a zero?) :: Bool
    * channel (what channel does this occur on) :: Int
    * time (timestamp in clock cycles) :: UInt

Using this struct allows to deconstruct the data from the FPGA while maintaining 
the data provided.

"""
struct Timestamp
    zero::Bool
    channel::Int
    time::UInt
end

-(a::Int, ::Nothing)::Int = a
+(x::Timestamp, y::Int) = Timestamp(x.zero, x.channel, x.time + y)
parse(type) = x -> parse(type, x);
parse(type; base=10) = x -> parse(type, x; base=base);
string(;base::Integer=10, pad::Integer=1) = x -> string(x; base=base, pad=pad);


"""

Converts a string into a Timestamp type. The string must be an big endian
encoded 32 bit value in order to obtain useful results. The structure of the value 
will be as follows from the [NIST Simple and Inexpensive FPGA-based Fast Multichannel 
Acquisition Board](https://www.nist.gov/system/files/documents/2017/04/28/Stats.pdf):

    * Bit 32 : Counter cleared (zero)
    * Bit 30 : Channel 4
    * Bit 29 : Channel 3
    * Bit 28 : Channel 2
    * Bit 27 : Channel 1
    * Bits 26-0 : time in clock cycles

"""
function parse(::Type{Timestamp}, s::String)::Timestamp
    bstring = s.|> parse(UInt32, base=16) .|> ntoh .|> string(base=2, pad=32);
    ch = findfirst('1', bstring[2:5]);
    Timestamp(bstring[1] == '1' ? true : false, 5 - ch , parse(UInt, bstring[6:end], base=2))
end


"""
The get_channel function selects the Timestamp functions that match the channel value
that is inputted. This will simply filter out the unwanted channels from the dataset
and keep the channel we want and the zero postitions. 

# Arguments
- `ts::AbstractVector{Timestamp}` : Array of Timestamp types as an input 
- `ch::Int` : The channel that you want to obtain

# Examples
```julia-repl
julia> x = [Timestamp(0, 2, 0x35), Timestamp(0, 1, 0x30), Timestamp(1, 0, 0)];
julia> y = get_channel(x, 1)
[Timestamp(0, 1, 0x30), Timestamp(1, 0, 0)]
``` 
"""
function get_channel(ts::AbstractVector{Timestamp}, ch::Int)::AbstractVector{Timestamp}
    filter(t -> (t.channel== ch) || t.zero , ts)
end

"""
# Description
This function will read in the data from the FPGA output file and convert it into a
Vector of type Timestamp. This achieves this by applying the xxd command to the file 
path then broadcasts the parse function dispatched to Timestamp. The xxd function is 
a Linux hexdump function. You can find out more about this function and the provided 
arguments by looking at the Linux man page for xxd. 

# Arguments
- `file_path::String` : The file you wish to read

"""
function read_data(file_path::String)::AbstractVector{Timestamp}
    parse.(Timestamp, readlines(`xxd -c 4 -b -g 4 -ps $file_path`))
end

    
function steady_state_zero_behavior(times::AbstractVector{Timestamp})::AbstractVector{Timestamp}
    zero_locs = findall(t -> t == true, getproperty.(times, :zero));
    Δts = map(t -> sum(t .>= zero_locs) * (2^27 - 1), 1:length(times));
    times .+ Δts
end
    


