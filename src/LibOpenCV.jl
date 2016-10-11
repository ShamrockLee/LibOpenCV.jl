"""
A special package that manages opencv binary depedencies

```julia
Pkg.build("LibOpenCV")
```

try to search your system opencv libraries and its dependencies, and throws errors
if any issues. If opencv librarires are not found, it will install fresh opencv
libraries into `deps` directrory, but not recommended unless if you have perfect
requiremsnts to build opencv.
"""
module LibOpenCV

# Load dependency
deps = joinpath(Pkg.dir("LibOpenCV"), "deps", "deps.jl")
if isfile(deps)
    include(deps)
else
    error("LibOpenCV not properly installed. Please run Pkg.build(\"LibOpenCV\")")
end

using Cxx

Libdl.dlopen(libopencv_core, Libdl.RTLD_GLOBAL)

const libdir = dirname(libopencv_core)
const libext = splitext(libopencv_core)[2]

function find_library_e(mod, libdirs=[libdir], ext=libext)
    for libdir in libdirs
        libpath = joinpath(libdir, string(mod, ext))
        if isfile(libpath)
            return libpath
        end
    end
    C_NULL
end

const incdir = replace(libdir, "\/lib", "\/include")
@assert isdir(incdir)

opencvhpp = joinpath(incdir, "opencv2", "opencv.hpp")
if !isfile(opencvhpp)
    error("Cannot find $(opencvhpp)")
end

addHeaderDir(incdir, kind=C_System)
addHeaderDir(joinpath(incdir, "opencv2"), kind=C_System)

cxxinclude(opencvhpp)

end # module
