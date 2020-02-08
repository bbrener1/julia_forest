module FeatureVector

mutable struct Element
    key::Union{Any,Nothing}
    value::Union{Any,Nothing}
    previous::Element
    next::Element
    function Element()::Element
        e = new()
        e.value = nothing
        e
    end
end

function Element(v)
    e = Element()
    e.value = v
    e.key = nothing
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
    endcap_left = Element()
    endcap_right = Element()
    endcap_left.previous = endcap_left
    endcap_left.next = endcap_right
    endcap_right.next = endcap_right
    endcap_right.previous = endcap_left
    Segment(Dict([]),endcap_left,endcap_right)
end

function Segment()::Segment
    endcap_left = Element()
    endcap_right = Element()
    endcap_left.previous = endcap_left
    endcap_left.next = endcap_right
    endcap_right.next = endcap_right
    endcap_right.previous = endcap_left
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
    for (key,value) in enumerate(kv)
        push_right!(segment,key,value)
    end
    segment
end


function length(segment::Segment)
    length(segment.arena)
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
    segment.arena[elment.key] = element
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
        (1:length(segment.arena)) .|>
        (x) -> (element = element.next;
        element.value)
    output

end


mutable struct MedianVector
    segments::(Segment,Segment,Segment)
    sums::(Any,Any)
end

function shift_right(vector::MedianVector)
    if length(vector.segments[2]) == 1
        element = pop_left!(vector.segments[3])
        push_right!(vector.segments[2],element)
    elif length(vector.segments[2]) == 2
        
end

function balance!(vector::MedianVector)
    if length(vector.segments[1]) > length(vector.segments[3])

end

mutable struct MADVector
    segments::(Segment,Segment,Segment,Segment)
    sums::(Any,Any,Any,Any)
end

mutable struct EntropyVector
    segments::Array{Segment}
    sums::Array{Segment}
end

end