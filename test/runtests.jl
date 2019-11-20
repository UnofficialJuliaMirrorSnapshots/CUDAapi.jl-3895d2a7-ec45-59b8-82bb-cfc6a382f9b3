using CUDAapi

using Test

import Libdl


@testset "library types" begin
    @test CUDAapi.PATCH_LEVEL == CUDAapi.libraryPropertyType(2)
    @test CUDAapi.C_32U == CUDAapi.cudaDataType(Complex{UInt32})
end

@testset "properties" begin
    CUDAapi.devices_for_cuda(v"8.0")
    CUDAapi.devices_for_llvm(v"5.0")
    CUDAapi.isas_for_cuda(v"8.0")
    CUDAapi.isas_for_llvm(v"5.0")
end

# helper macro to test for non-nothingness
macro test_something(ex)
    quote
        local rv = $(esc(ex))
        @test rv !== nothing
        rv
    end
end

@testset "discovery" begin
    CUDAapi.find_binary([Sys.iswindows() ? "CHKDSK" : "true"])
    CUDAapi.find_library([Sys.iswindows() ? "NTDLL" : "c"])

    dirs = find_toolkit()
    @test !isempty(dirs)

    ver = find_toolkit_version(dirs)

    @testset "CUDA tools and libraries" begin
        @test_something find_cuda_binary("nvcc", dirs)
        @test_something find_cuda_library("cudart", dirs)
        @test_something find_cuda_library("nvtx", dirs)
        @test_something find_libdevice([v"3.0"], dirs)
        @test_something find_libcudadevrt(dirs)
    end

    if haskey(ENV, "CI")
        # CI deals with plenty of CUDA versions, which makes discovery tricky.
        # dump a relevant tree of files to help debugging
        function traverse(dir, level=0)
            for entry in readdir(dir)
                print("  "^level)
                path = joinpath(dir, entry)
                if isdir(path)
                    println("└ $entry")
                    traverse(path, level+1)
                else
                    println("├ $entry")
                end
            end
        end
        for dir in dirs
            println("File tree of toolkit directory $dir:")
            traverse(dir)
        end
    end
end

@testset "availability" begin
    @test isa(has_cuda(), Bool)
    @test isa(has_cuda_gpu(), Bool)
end

@testset "call" begin
    # ccall throws if the lib doesn't exist, even if not called
    foo(x) = (x && ccall((:whatever, "nonexisting"), Cvoid, ()); 42)
    @test_throws ErrorException foo(false)

    # @runtime_ccall prevents that
    bar(x) = (x && @runtime_ccall((:whatever, "nonexisting"), Cvoid, ()); 42)
    @test bar(false) == 42
    # but should still error nicely if actually calling the library
    @test_throws ErrorException bar(true)
end
