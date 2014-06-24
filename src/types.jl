## Following Qt

abstract Object


abstract Widget <: Object


abstract Observable <: Object
abstract AbstractModel <: Observable



abstract Container <: Widget
abstract Layout <: Object


abstract Control <: Widget
abstract WidgetModel <: Control
abstract WidgetVectorModel <: WidgetModel
abstract Style <: Widget



## imlement these?
abstract AbstractButton <: Widget
abstract AbstractSlider <: Widget
abstract AbstractSpinBox <: Widget



## Some methods

## For using a react value
getReact(o::WidgetModel) = o.react
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

