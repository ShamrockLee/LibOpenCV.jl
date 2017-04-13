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

import Base.Filesystem
using DocStringExtensions
using Cxx

Libdl.dlopen(libopencv_core, Libdl.RTLD_GLOBAL)

const libdir = dirname(libopencv_core)
const libext = splitext(libopencv_core)[2]


"""
$(SIGNATURES)

It tries to search the specified library by name. Not exported, but meant to be
used by other opencv packages.

**Parameters**

- `mod` : Module name
- `libdirs` : library seach directries (default is dir of `libopencv_highgui`)
- `ext` : library extention name (e.g. `.so`)

**Retures**

- `libpath` : library path if found, othrewise return `C_NULL`

**Examples**

From the [CVHighGUI.jl](@ref) package,

```julia
libopencv_highgui = LibOpenCV.find_library_e("libopencv_highgui")
try
    Libdl.dlopen(libopencv_highgui, Libdl.RTLD_GLOBAL)
catch e
    warn("You might need to set DYLD_LIBRARY_PATH to load dependencies proeprty.")
    rethrow(e)
end
```
"""
function find_library_e(mod, libdirs=[libdir], ext=libext)
    for libdir in libdirs
        libpath = joinpath(libdir, string(mod, ext))
        if isfile(libpath)
            return libpath
        end
    end
    C_NULL
end

# Split the library directory in folders.
folder_path = split(libdir, Base.Filesystem.path_separator);
# Change the last "lib" part to "include". This is a wild guess, but quite
# robust.
lib_ids = find(folder_path .== "lib")
@assert (size(lib_ids, 1) > 0) "Include path could not be guessed!"
folder_path[lib_ids[end]] = "include";
const incdir = join(folder_path, Base.Filesystem.path_separator);
@assert isdir(incdir) "Include path could not be guessed: $(incdir)!"

opencvhpp = joinpath(incdir, "opencv2", "opencv.hpp")
if !isfile(opencvhpp)
    error("Cannot find $(opencvhpp)")
end

# Add libraries first as user include (-I), then as well as system includes.
# The former is necessary to get preference over the system installed OpenCV if
# necessary, the latter is necessary to have the internal OpenCV include with
# quotes (<>) work.
addHeaderDir(incdir, kind=C_User)
addHeaderDir(joinpath(incdir, "opencv2"), kind=C_User)
addHeaderDir(incdir, kind=C_System)
addHeaderDir(joinpath(incdir, "opencv2"), kind=C_System)

cxxinclude(opencvhpp)

end # module
