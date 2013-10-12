This directory has a few annotated examples. They can be read as markdown files. To execute them, the `Gadfly` `weave` function can be used. For example:

```
using Gadfly
Gadfly.weave(Pkg.dir("JGUI", "examples", "menu.md"), "markdown", "json")
```
