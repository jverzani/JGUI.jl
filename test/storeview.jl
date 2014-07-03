
store = Store(Int, Float64, String)
push!(store, (1, 1.0, "one"))
push!(store, (2, 2.0, "two"))
push!(store, (3, 3.0, "three"))

w = window(size=[300, 300])
sv = storeview(w, store)
sv[:names] = ["Column one", "column two", "column three"]
push!(sv)           
raise(w)


