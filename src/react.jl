## Add in interface akin to React.jl
## This is grafted on -- not integrated, so will have some warts.
##
## Basic ideas:
##
## Reactive objects, well, react when their values are changed. This reaction involves signal
## which can be "lifted" up to call a functionm passing in the changed value.
## 
## * For basic widgets, the react object is returned by `obj[:react]`
## * `setValue` can be used to connect output of one with input of another. This will synchronize.
##
##   obj1[:value] = obj2
##
## * one can call `lift` to call a function when a value changes: lift(f::Function, w::Widget)
## * one can merge many widgets together, then lift: lift(f::Function, merge(w1, ws, ...))
##
## For example, this synchronizes a slider and a label
##
## w = window(); f = vbox(w), push!(f)
## sl = slider(f, 1:20)
## l = label(f, "")
## l[:value] = sl
## append!(f, [sl, l])


## For using a react value
getReact(o::WidgetReact) = o.react
getReact(o::Any) = o

function connect_react(obj::WidgetReact, react::React.Signal)
    connect(obj, :valueChanged) do x
        if !isa(x, Nothing) 
            push!(react, x)
        end
    end
    lift(Any, react) do x
        if !isa(x, Nothing) 
            obj[:value] = x
        end
    end
end
function setValue(obj::WidgetReact, value::React.Signal; signal::Bool=true) 
    lift(Any, value) do x
        if !isa(x, Nothing)
            obj[:value] = x
        end
    end
    nothing
end
setValue(obj::WidgetReact, value::WidgetReact; signal::Bool=true) = setValue(obj, value[:react]; signal=signal)
## give react.jl methods
push!(obj::WidgetReact, value) = push!(obj[:react], value)

React.lift(f::Function, obj::WidgetReact, objs::Union(React.Signal, WidgetReact)...) = lift(f, Any, obj[:react], map(getReact, objs)...)
React.merge(obj::WidgetReact, xs...) = merge(obj[:react], map(x->x[:react], xs)...)



## The `@lift` macro from `React` for the reactive widgets
## The call `@manipulate ex` will find widget in `ex` and replace them with their value
##
## example:
## w = window()
## f = formlayout(w); push!(w,f)
## sl = slider(f, 1:10); push!(f, sl, "sl")
## sl1 = slider(f, 1:10); push!(f, sl1,"sl1")
## raise(w)
##
## @manipulate println(sl * sl1)
React.signal(x::WidgetReact) = x
macro wlift(ex)
    ex = React.sub_val(ex, current_module())
    ex, sigs = React.extract_signals(ex, current_module())
    args = Symbol[]
    vals = Any[]
    for (k, v) in sigs
        push!(args, v)
        push!(vals, JGUI.getReact(k))
    end

    Expr(:call, :lift,
         Expr(:->, Expr(:tuple, args...), ex),
         vals)
end

