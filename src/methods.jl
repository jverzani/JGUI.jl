## object methods

show(io::IO, o::Object) = println(io, "Object of type $(typeof(o))")



## Use o[:symbol] for properties (will also use o[:integer] for containers and children)
## We make it so o[:symbol] calls getSymbol (if present), else it looks in o.attrs[:symbol]
## Similarly, o[:symbol] = value will look for setSymbol (if present). This makes it easy to
## overload the assignment.
function getindex(o::Object, i::Symbol)
    getProp(o, i)
end

function getProp(o::Object, i::Symbol)
    ## do we have a function?
    aname = string(i)
    aname = uppercase(aname[1:1]) * aname[2:end]
    fname = "get" * aname
    try
        JGUI.(symbol(fname))(o)
    catch e
        if haskey(o.attrs, i)
            o.attrs[i]
        else
            nothing
        end
    end
end

## By default, we look for a method getPropname, if that is defined we use it
## otherwise we look for the key in attrs Dict.
function getProp(o::Object, i::Symbol, default) 
    val = getProp(o, i)
    isa(val, Nothing) ? default : val
end

function setindex!(o::Object, value, i::Symbol)
    setProp(o, i, value)
end

function setProp(o::Object, i::Symbol, value) 
    aname = string(i)
    aname = uppercase(aname[1:1]) * aname[2:end]
    fname = "set" * aname
    try
        JGUI.(symbol(fname))(o, value)
    catch e
        println(e)
        o.attrs[i] = value
    end
    o
end

## A means to document inheritance of properties
## SOmething like `list_props(::@PROP("WidgetType")) = {:prop => "description"}`
## is there a cleaner way? This is cribbed from MIME
## This allows us to dispatch on a DataType
immutable PROP{atype} end
PROP(s) = PROP{symbol(s)}()
macro PROP(s)
    quote 
        PROP{symbol($s)}
    end
end

## list properties
function properties(o::Object)
    d = Dict()
    s = typeof(o)
    while s != Any
        try 
            d[string(s)] = list_props(PROP(string(s)))
        catch e
            nothing
        end
        s = super(s)
    end
    d
end