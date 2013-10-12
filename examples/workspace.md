This example shows a simple workspace browser using the `storeview` widget. The store view widget displays records which are instances of a composite type. In this example, the type holds the variable name and a short summary. 

```
type Summary 
    nm::String
    descr::String
end
```


To begin we define a means to identify different values and describe a summary:

```
unique_id(v::Symbol, m::Module) = isdefined(m,v) ? unique_id(eval(m,v)) : ""
unique_id(x) = string(object_id(x))

short_summary(x) = summary(x)
short_summary(x::String) = "A string"
```



The bulk of the work is do maintain a `Store` with each item representing an object in the workspace. As objects can be renamed, we need to check each time we update the state. The bulk of the work below is the `update` method which does several things.


```
using JGUI

type State 
    nms::Vector{Symbol}
    ids::Vector{ASCIIString}
    re
    m::Module
    store
    update::Function
    
    function State()
        self = new()
        self.m = Main
        self.re = r"^__"
        self.nms = Symbol[]
        self.ids = ASCIIString[]
        self.store = Store{Summary}()

        function update()
            new_nms = names(self.m)
            ## filter values here: XXX generalize
            sort!(new_nms)
            filter!(u -> !ismatch(self.re, string(u)), new_nms) # by __name
#            filter!(u -> !isa(self.m(u), Union(Module, Nothing)), new_nms) # by module type
            new_ids = map(u -> unique_id(u, self.m), new_nms)
            
            ## update changes
            for i in 1:length(self.nms)
                nm, id = self.nms[i], self.ids[i]
                if id != unique_id(nm, self.m)
                    item = self.store.items[i]
                    item.descr = short_summary(self.m.(nm))
                    replace!(self.store, i, item)
                end
            end

            drop_these = setdiff(self.nms, new_nms)
            inds = findin(self.nms, drop_these)
            if length(inds) > 0
                for i in reverse(inds)
                    nm = self.nms[i]
                    if nm in drop_these
                        splice!(self.store, i)
                    end
                end
            end
            
            ## insert new -- if any
            new_nms = sort(filter(u -> !ismatch(self.re, string(u)), names(self.m)))
            addthese = setdiff(new_nms, self.nms)
            sort!(addthese)
            
            if length(addthese) > 0


                if length(self.nms) > 0
                    at_end = filter(u -> u > self.nms[end], addthese)
                    in_between = setdiff(addthese, at_end)
                else
                    at_end = addthese
                    in_between = Symbol[]
                end
                
                for nm in at_end
                    item = Summary(string(nm), short_summary(self.m.(nm)))
                    push!(self.store, item)
                end
                
                k = length(self.nms)
                for nm in reverse(in_between)
                    item = Summary(string(nm), short_summary(self.m.(nm)))
                    while string(nm) <= string(self.nms[k])
                        k = k - 1
                        k < 0 && error("k is < 0")
                    end
                    insert!(self.store, k+1, item)
                end
            end
            
            self.nms = new_nms
            self.ids = new_ids
            nothing
        end
        self.update = update
        self.update()

        self
    end
end
```

The basic object is just an instance of `State`. The key method of this object is `update`, as in `state.udpate()`.

```
state = State()
```

Our GUI is very simple here, we just use a store view to display the store created in `state`.

```
w = window()
sv = storeview(w, state.store)
push!(sv)
raise(w)
w[:size] = [300, 400]
```

To integrate this, one needs to call `state.udpate` either through a time or through an event driven manner.

