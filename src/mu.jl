## Example of how to parse mustache template to insert
## graphic. This could be part of mustache bit
## wish there were a way to *easily* get markup in the text buffer...
using Mustache, Gtk, Winston

tpl = mt"""
This is a mustache
template bold
complete with lots of stuff
what is --> {{x}} <--?
and 
{{p}}
and whatever
"""

x = "this is x"
p = plot(sin, 0, 2pi);


## show tpl
w = window()
tv = textedit(w); push!(w, tv)

function add_tpl(tpl)
    ## how to show a mustache template
    for (t, l, b, e) in tpl.tokens
        if t == "text"
            push!(tv, l)
        else ## if type == "name"
            ## look up and render accordingly
            obj = Main.(symbol(l))
            if isa(obj, Winston.FramedPlot)
                c = cairographic(w)
                display(c, obj)
                push!(tv, c)
            else
                push!(tv, string(obj))
            end
        end
    end
end
