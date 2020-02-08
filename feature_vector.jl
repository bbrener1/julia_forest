module FeatureVector

mutable struct Element
    key::Union{Any,Nothing}
    value::Union{Any,Nothing}
    previous::Element
    next::Element
    function Element()::Element
        e = new()
        e.value = nothing
        e.key = nothing
        e
    end
end

function Element(v)
    e = Element()
    e.value = v
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
    e.previous = p
    e.next = n
    e
end

mutable struct Segment
    arena::Dict{Any,Element}
    left::Element
    right::Element
end

function Segment()::Segment
    (endcap_left,endcap_right) = endcaps()
    Segment(Dict([]),endcap_left,endcap_right)
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
    left.next = element
    right.previous = element
end


function push_right!(segment::Segment,element::Element)
    right = segment.right
    left = right.previous
    segment.arena[element.key] = element
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


mutable struct MedianVector
    segments::Tuple{Segment,Segment,Segment}
    sums::Array{Any}
end

function MedianVector(kv)
    sorted = sort(kv,by= (x) -> x[2])
    split = round(Int,((Base.length(sorted)-1)/2),RoundDown)
    println(sorted)
    println(split)
    seg_1 = Segment(sorted[1:split])
    seg_2 = Segment(sorted[split+1:(end-split-1)])
    seg_3 = Segment(sorted[end-split:end])
    println(read_ordered((seg_1)))
    println(read_ordered((seg_2)))
    println(read_ordered((seg_3)))
    sum_1 = sum(read_ordered(seg_1))
    sum_2 = sum(read_ordered(seg_3))
    MedianVector(
        (seg_1,seg_2,seg_3),
        [sum_1,sum_2]
    )
    balance!(MedianVector())
end

function shift_right!(vector::MedianVector)
    if length(vector.segments[2]) == 1
        element = pop_left!(vector.segments[3])
        push_right!(vector.segments[2],element)
        vector.sums[1] += vector.segments[2].left.next.value
    elseif length(vector.segments[2]) == 2
        element = pop_left!(vector.segments[2])
        vector.sums[1] += element.value
        vector.sums[2] -= vector.segments[2].right.previous.value
        push_right!(vector.segments[1],element)
    end
end

function shift_left!(vector::MedianVector)
    if length(vector.segments[2]) == 1
        element = pop_right!(vector.segments[1])
        push_left!(vector.segments[2],element)
        vector.sums[2] += vector.segments[2].right.previous.value
    elseif length(vector.segments[2]) == 2
        element = pop_right!(vector.segments[2])
        vector.sums[2] += element.value
        vector.sums[1] -= vector.segments[2].left.next.value
        push_right!(vector.segments[3],element)
    end
end

function median(vector::MedianVector)
    sum(read_ordered(vector.segments[2])) / max(length(vector.segments[2]),1)
end

#### TO DO: INTEGRITY TEST/ASSERT

function balance!(vector::MedianVector)
    while length(vector.segments[1]) != length(vector.segments[3])
        println("Balancing")
        println(length(vector.segments[1]))
        println(length(vector.segments[2]))
        println(length(vector.segments[3]))
        if length(vector.segments[1]) > length(vector.segments[3])
            shift_left!(vector)
        elseif length(vector.segments[1]) < length(vector.segments[3])
            shift_right!(vector)
        end
    end
end



mutable struct MADVector
    segments::Tuple{Segment,Segment,Segment,Segment}
    sums::Array{Any}
end

mutable struct EntropyVector
    segments::Array{Segment}
    sums::Array{Any}
end

end
