Manipulate makes it easy to create animations. Basically, one creates an expression to be evaluated and specifies ranges on the unbound variables. For example:

```
ENV["Toolkit"] = "Gtk"		# or Tk
using JGUI

ex = quote
using Winston
  x(t) = (R+r)*cos(t) + p*cos((R+r)*t/r)
  y(t) = (R+r)*sin(t) + p*sin((R+r)*t/r)
  t = linspace(0, 25*(R+r)/r* pi, 1000)
  plot(x(t), y(t))
end

manipulate(ex, (:R, 1:.01:3), (:r, 1:.01:3), (:p, .05:0.5:2))
```

Other controls besides sliders are possible. For example, this specifies an integer and combobox:

 
```
using JGUI

ex = quote
using Winston
  t = linspace(0, n*(R+r)/r* pi, N)
  x = (R+r)*cos(t) + p*cos((R+r)*t/r)
  y = (R+r)*sin(t) + p*sin((R+r)*t/r)
  plot(x, y)
end

manipulate(ex, (:R, 1:.01:3), (:r, 1:.01:3), (:p, .05:0.5:2),
	       (:n, 25), (:N, [100, 500, 1000, 10_000])
	       )
```
