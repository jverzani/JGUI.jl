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
getReact(o::WidgetModel) = o.react
getReact(o::Any) = o

function connect_react(obj::WidgetModel, react::Signal)
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
function setValue(obj::WidgetModel, value::Signal) 
    lift(Any, value) do x
        if !isa(x, Nothing)
            obj[:value] = x
        end
    end
    nothing
end
setValue(obj::WidgetModel, value::WidgetModel) = setValue(obj, value[:react])
## give react.jl methods
push!(obj::WidgetModel, value) = push!(obj[:react], value)

React.lift(f::Function, obj::WidgetModel, objs::Union(Signal, WidgetModel)...) = lift(f, Any, obj[:react], map(getReact, objs)...)
React.merge(obj::WidgetModel, xs...) = merge(obj[:react], map(x->x[:react], xs)...)
