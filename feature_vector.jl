module FeatureVector

using Statistics

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

mutable struct Segment
    arena::Dict{Any,Element}
    sum::Any
    squared_sum::Any
    left::Element
    right::Element
end

function Segment()::Segment
    (endcap_left,endcap_right) = endcaps()
    Segment(Dict([]),0,0,endcap_left,endcap_right)
end

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

function pop_left!(segment::Segment)
    target_key = segment.left.next.key
    pop!(segment,target_key)
end

function pop_right!(segment::Segment)
    target_key = segment.left.next.key
    pop!(segment,target_key)
end


function push_left!(segment::Segment,element::Element)
    left = segment.left
    right = left.next
    segment.arena[element.key] = element
    segment.sum += element.value
    segment.squared_sum += element.value
    element.previous = left
    element.next = right
    left.next = element
    right.previous = element
end

function push_left!(segment::Segment,key,value)
    left = segment.left
    right = left.next
    element = Element(key,value,left,right)
    segment.arena[key] = element
    segment.sum += element.value
    segment.squared_sum += element.value
    left.next = element
    right.previous = element
end


function push_right!(segment::Segment,element::Element)
    right = segment.right
    left = right.previous
    segment.arena[element.key] = element
    segment.sum += element.value
    segment.squared_sum += element.value
    element.previous = left
    element.next = right
    left.next = element
    right.previous = element
end

function push_right!(segment::Segment,key,value)
    right = segment.right
    left = right.previous
    element = Element(key,value,left,right)
    segment.arena[key] = element
    segment.sum += element.value
    segment.squared_sum += element.value
    left.next = element
    right.previous = element
end

function read_ordered(segment::Segment)::Array
    element = segment.left
    output =
        (1:length(segment)) .|>
        (x) -> (element = element.next;
        element.value)
    output

end

abstract type SegmentedVector end

function pop!(vector::SegmentedVector,key)
    for segment in vector.segments
        if haskey(segment.arena,key)
            pop!(segment,key)
            balance!(vector)
            return
        end
    end
    throw(KeyError(key))
end


mutable struct MedianVector <: SegmentedVector
    segments::Tuple{Segment,Segment,Segment}
end

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

function shift_right!(vector::MedianVector)
    if length(vector.segments[2]) == 1
        element = pop_left!(vector.segments[3])
        push_right!(vector.segments[2],element)
    elseif length(vector.segments[2]) == 2
        element = pop_left!(vector.segments[2])
        push_right!(vector.segments[1],element)
    end
end

function shift_left!(vector::MedianVector)
    if length(vector.segments[2]) == 1
        element = pop_right!(vector.segments[1])
        push_left!(vector.segments[2],element)
    elseif length(vector.segments[2]) == 2
        element = pop_right!(vector.segments[2])
        push_right!(vector.segments[3],element)
    end
end

function median(vector::MedianVector)
    vector.segments[2].sum / max(length(vector.segments[2]),1)
end

function sme(vector::MedianVector)
    median = median(vector)
    left_sum = vector.segments[1].sum
    left_elements = legnth(vector.segments[1])
    right_sum = vector.segments[3].sum
    right_elements = legnth(vector.segments[1])
    if length(vector.segments[2]) == 2
        left_sum += vector.segments[2].left.next.value
        left_elements += 1
        right_sum += vector.segmenets[2].right.previous.squared_value
        right_elements += 1
    end

    return abs((left_elements * median) - left_sum) + abs(right_sum - (right_elements*median))


end

function ssme(vector::MedianVector)
    median = median(vector)
    squared_sum = vector.segments[1].squared_sum + vector.segments[3].squared_sum
    sum = vector.segments[1].sum + vector.segments[3].sum
    elements = legnth(vector.segments[1]) + legnth(vector.segments[1])
    if length(vector.segments[2]) == 2
        squared_sum += vector.segments[2].squared_sum
        sum += vector.segments[2].sum
        elements += 2
    end
    return squared_sum + (2*median*sum) + (elements*median)
end


#### TO DO: INTEGRITY TEST/ASSERT

function balance!(vector::MedianVector)
    ll = length(vector.segments[1])
    lr = length(vector.segments[3])
    lm = length(vector.segments[2])
    while ll != lr
        ll = length(vector.segments[1])
        lr = length(vector.segments[3])
        lm = length(vector.segments[2])
        println("Balancing")
        if lm < 1
            if ll > lr
                element = pop_right!(vector.segments[1])
                push_left!(vector.segments[2],element)
            elseif lr > ll
                element = pop_left!(vector.segments[3])
                push_right!(vector.segments[2],element)
            end
        elseif lm > 2
            throw(DomainError("median zone too large"))
        end
        if ll > lr
            shift_left!(vector)
        elseif ll < lr
            shift_right!(vector)
        end
    end
end

function RandomMedianTest()
end

function slow_ssme(vec)
    median = Statistics.median(vec)
    differences = vec - median
    sum(differences^2)
end

function slow_sme(vec)
    median = Statistics.median(vec)
    differences = vec - median
    sum(abs(differences))
end

mutable struct MADVector
    segments::Tuple{Segment,Segment,Segment,Segment}
end

mutable struct EntropyVector
    segments::Array{Segment}
end


end
