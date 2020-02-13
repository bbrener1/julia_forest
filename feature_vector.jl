module FeatureVector

using Statistics,Random
using BenchmarkTools

# Basic element of the linked list, contains a value and links

mutable struct Element
    key::Union{Any,Nothing}
    value::Union{Any,Nothing}
    squared_value::Union{Any,Nothing}
    previous::Element
    next::Element
    function Element()::Element
        e = new()
        e.value = nothing
        e.squared_value = nothing
        e.key = nothing
        e
    end
end

function Element(v)
    e = Element()
    e.value = v
    e.squared_value = v^2
    e.key = nothing
end

# This creates two endcap elements that are linked to each other and have a closed loop link onto themselves
# These should not be accessible to the user under normal operation, only internally

function endcaps()::Tuple{Element,Element}
    endcap_left = Element()
    endcap_right = Element()
    endcap_left.previous = endcap_left
    endcap_left.next = endcap_right
    endcap_right.next = endcap_right
    endcap_right.previous = endcap_left
    (endcap_left,endcap_right)
end

function Element(k,v,p::Element,n::Element)::Element
    e = Element()
    e.key = k
    e.value = v
    e.squared_value = v^2
    e.previous = p
    e.next = n
    e
end

# A segment is doubly-ended linked list resting in a Dict arena. Elements make up the list, and are also accessible by
# indexing into the Dict.

mutable struct Segment
    arena::Dict{Any,Element}
    sum::Any
    squared_sum::Any
    left::Element
    right::Element
end

# A blank segment containing only the endcaps.

function Segment()::Segment
    (endcap_left,endcap_right) = endcaps()
    Segment(Dict([]),0,0,endcap_left,endcap_right)
end

# Creates a linked list from sorted values, using integers as keys for the Dict

function link_sorted(sorted)
    if !issorted(sorted)
        throw(DomainError("unsorted values"))
    end
    segment = Segment()
    for (index,element) in enumerate(sorted)
        push_right!(segment,index,element)
    end
    segment

end

# Creates a Segment out of a sorted list of key-value pairs

function Segment(kv)
    segment = Segment()
    for (key,value) in kv
        push_right!(segment,key,value)
    end
    segment
end


function length(segment::Segment)
    Base.length(segment.arena)
end

# Pops an Element out of a Segment
# Re-links the neighboring elements to preserve the ability to traverse the segment
# Returns the element object, in case it needs to be re-inserted into another Segment
function pop!(segment::Segment,key)
    target = Base.pop!(segment.arena,key)
    segment.sum -= target.value
    segment.squared_sum -= target.squared_value
    left = target.previous
    right = target.next
    left.next = right
    right.previous = left
    target
end

# Pops the leftmost (usually smallest) element of the Segment, and re-establishes
# a different element as leftmost
function pop_left!(segment::Segment)
    target_key = segment.left.next.key
    pop!(segment,target_key)
end

# As above, but the rightmost element
function pop_right!(segment::Segment)
    target_key = segment.right.previous.key
    pop!(segment,target_key)
end

# Pushes an element onto the right side of the list
function push_left!(segment::Segment,element::Element)
    left = segment.left
    right = left.next
    segment.arena[element.key] = element
    segment.sum += element.value
    segment.squared_sum += element.squared_value
    element.previous = left
    element.next = right
    left.next = element
    right.previous = element
end

# Creates an element out of a key-value pair, then
# pushes a it onto the left side of the list
function push_left!(segment::Segment,key,value)
    left = segment.left
    right = left.next
    element = Element(key,value,left,right)
    segment.arena[key] = element
    segment.sum += element.value
    segment.squared_sum += element.squared_value
    left.next = element
    right.previous = element
end

# As above
function push_right!(segment::Segment,element::Element)
    right = segment.right
    left = right.previous
    segment.arena[element.key] = element
    segment.sum += element.value
    segment.squared_sum += element.squared_value
    element.previous = left
    element.next = right
    left.next = element
    right.previous = element
end

# As above
function push_right!(segment::Segment,key,value)
    right = segment.right
    left = right.previous
    element = Element(key,value,left,right)
    segment.arena[key] = element
    segment.sum += element.value
    segment.squared_sum += element.squared_value
    left.next = element
    right.previous = element
end

# Reads the elements in a Segment in the order in which they are linked
function read_ordered(segment::Segment)::Array
    element = segment.left
    output =
        (1:length(segment)) .|>
        (x) -> (element = element.next;
        element.value)
    output

end

# An abstract representation of linked lists composed of multiple segments
# Usually such lists will take the shape of a "finger" structure, where an element
# popped from one list is inserted into another in order to traverse the list
abstract type SegmentedVector end

function pop!(vector::SegmentedVector,key)
    for segment in vector.segments
        if haskey(segment.arena,key)
            pop!(segment,key)
            balance!(vector)
            return
        end
    end
    print(vector.segments .|> (s) -> s.arena)
    throw(KeyError(key))
end

function length(vector::SegmentedVector)
    vector.segments .|> length |> sum
end

mutable struct MedianVector <: SegmentedVector
    segments::Tuple{Segment,Segment,Segment}
end

# A median vector maintains an awareness of the median of all elements that it contains,
# as well as the sum and sum of squares of all elements left and right of the median.

# This allows us to request an O(1) computation of the Sum of Absolute Deviations from the Median
# and similar statistics

# Segment #2 always contains 1 or 2 elements, and the mean of its elements
# is the median of the elements in the Median Vector


# Key/value constructor for the Median Vector. Basically just passes off the relevant key/value
# pairs to Segments, as seen above

function MedianVector(kv)
    sorted = sort(kv,by= (x) -> x[2])
    split_l = round(Int,((Base.length(sorted)+1)/2),RoundDown)
    split_r = round(Int,((Base.length(sorted)+1)/2),RoundUp)
    println(sorted)
    println(split_l,split_r)
    seg_1 = Segment(sorted[1:(split_l-1)])
    seg_2 = Segment(sorted[split_l:split_r])
    seg_3 = Segment(sorted[split_r+1:end])
    println(read_ordered((seg_1)))
    println(read_ordered((seg_2)))
    println(read_ordered((seg_3)))
    mv = MedianVector(
        (seg_1,seg_2,seg_3),
    )
    balance!(mv)
    mv
end

# As above but skips the sorting step on input that is already sorted

function mv_link_sorted(sorted)
    split_l = round(Int,((Base.length(sorted)+1)/2),RoundDown)
    split_r = round(Int,((Base.length(sorted)+1)/2),RoundUp)
    seg_1 = Segment(sorted[1:(split_l-1)])
    seg_2 = Segment(sorted[split_l:split_r])
    seg_3 = Segment(sorted[split_r+1:end])
    mv = MedianVector(
        (seg_1,seg_2,seg_3),
    )
    balance!(mv)
    mv
end

# Shifts the location of the "median" segment right

function shift_right!(vector::MedianVector)
    if length(vector.segments[2]) == 1
        element = pop_left!(vector.segments[3])
        # println("Shifting element right:$(element.value)")
        push_right!(vector.segments[2],element)
    elseif length(vector.segments[2]) == 2
        element = pop_left!(vector.segments[2])
        # println("Shifting element right:$(element.value)")
        push_right!(vector.segments[1],element)
    end
end

# As above but left

function shift_left!(vector::MedianVector)
    if length(vector.segments[2]) == 1
        element = pop_right!(vector.segments[1])
        # println("Shifting element left:$(element.value)")
        push_left!(vector.segments[2],element)
    elseif length(vector.segments[2]) == 2
        element = pop_right!(vector.segments[2])
        # println("Shifting element left:$(element.value)")
        push_left!(vector.segments[3],element)
    end
end

# Returns the median of all elements in the vector.
function median(vector::MedianVector)
    vector.segments[2].sum / max(length(vector.segments[2]),1)
end

# Returns all values contained in the Median Vector in their linkage order
function read_ordered(vector::MedianVector)
    vcat((vector.segments .|> read_ordered)...)
end

# Sum of absolute difference between each element and the median
function sme(vector::MedianVector)
    md = median(vector)
    left_sum = vector.segments[1].sum
    left_elements = length(vector.segments[1])
    right_sum = vector.segments[3].sum
    right_elements = length(vector.segments[1])
    if length(vector.segments[2]) == 2
        left_sum += vector.segments[2].left.next.value
        left_elements += 1
        right_sum += vector.segments[2].right.previous.squared_value
        right_elements += 1
    end

    return abs((left_elements * md) - left_sum) + abs(right_sum - (right_elements*md))


end

# Sum of the square of the difference between each element and the median
function ssme(vector::MedianVector)
    md = median(vector)
    squared_sum = vector.segments[1].squared_sum + vector.segments[3].squared_sum
    sum = vector.segments[1].sum + vector.segments[3].sum
    elements = length(vector.segments[1]) + length(vector.segments[1])
    if length(vector.segments[2]) == 2
        squared_sum += vector.segments[2].squared_sum
        sum += vector.segments[2].sum
        elements += 2
    end
    return squared_sum - (2*md*sum) + (elements*(md^2))
end

# This function updates the vector to make sure it maintains the correct position
# of the median after an element is removed.
function balance!(vector::MedianVector)

    # First we check if the number of the elements in the median segment is correct

    ll = length(vector.segments[1])
    lr = length(vector.segments[3])
    lm = length(vector.segments[2])
    if lm < 1
        if ll > lr
            element = pop_right!(vector.segments[1])
            push_left!(vector.segments[2],element)
        elseif lr > ll
            element = pop_left!(vector.segments[3])
            push_right!(vector.segments[2],element)
        elseif ll > 0
            element = pop_right!(vector.segments[1])
            push_left!(vector.segments[2],element)
        elseif lr > 0
            element = pop_left!(vector.segments[3])
            push_right!(vector.segments[2],element)
        end
    elseif lm > 2
        throw(DomainError("median zone too large"))
    end

    # After this we must ensure that the number of elements in the segments left and right
    # of the median is equal. If both conditions are true, then the vector knows its median.

    ll = length(vector.segments[1])
    lr = length(vector.segments[3])
    lm = length(vector.segments[2])
    while ll != lr
        ll = length(vector.segments[1])
        lr = length(vector.segments[3])
        lm = length(vector.segments[2])
        if ll > lr
            shift_left!(vector)
        elseif ll < lr
            shift_right!(vector)
        end
    end
    # println("Balanced")
    # ll = length(vector.segments[1])
    # lr = length(vector.segments[3])
    # lm = length(vector.segments[2])
    # println("$ll,$lm,$lr")


end

# These functions are used to check whether the Median Vector is returning correct
# results.
function slow_ssme(vec)
    vec = Array{Float64}(vec)
    median = Statistics.median(vec)
    println("Slow median:$median")
    differences = vec .- median
    sum(differences.^2)
end

function slow_sme(vec)
    median = Statistics.median(vec)
    differences = vec .- median
    differences .|> abs |> sum
end


function RandomMedianTest(kv)
    vec = MedianVector(kv)
    draw_order = Random.randperm(Base.length(kv))

    vec_copy = deepcopy(vec)
    for i in draw_order
        println(i)
        println(vec_copy.segments .|> length)
        println(vec_copy.segments .|> (x)->x.sum)
        println(vec_copy.segments .|> (x)->x.squared_sum)
        fss = ssme(vec_copy)
        sss = slow_ssme(read_ordered(vec_copy))
        fs = sme(vec_copy)
        ss = slow_sme(read_ordered(vec_copy))
        println("$fss,$sss")
        if fss - sss > .00001
            println(i)
            println(vec_copy.segments .|> length)
            println(vec_copy.segments .|> (x)->x.sum)
            println(vec_copy.segments .|> (x)->x.squared_sum)
            println("SSME ERROR")
            print("$fss,$sss")
            return vec_copy
        end
        if fs - ss > .00001
            println(i)
            println("SME ERROR")
            print("$fs,$ss")
            return vec_copy
            # error("$fs,$ss")
        end
        pop!(vec_copy,i)
    end
end

Base.show(io::IO,mv::MedianVector) = (_) -> ()

function RandomMedianTiming(kv)
    # This function tests the main task that vectors in this library will be used for:

    # Fast estimation of the descriptive statistics of a set of elements, recomputed online
    # as elements are removed from the collection in a random order.

    sorted = sort(kv,by=(x) -> x[1]);
    vec = MedianVector(kv);
    draw_order = Random.randperm(length(vec));
    function test(vec,draw_order)
        vec_copy = deepcopy(vec)
        for i in draw_order
            pop!(vec_copy,i)
            ssme(vec_copy)
        end
    end
    # @time test(vec,draw_order)
    @benchmark test($vec,$draw_order)
end




## TODO LATER
# mutable struct MADVector
#     segments::Tuple{Segment,Segment,Segment,Segment}
# end
#
# mutable struct EntropyVector
#     segments::Array{Segment}
# end


end
