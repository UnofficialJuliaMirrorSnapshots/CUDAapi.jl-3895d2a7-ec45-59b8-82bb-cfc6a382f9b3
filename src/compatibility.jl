## auxiliary

const lowest = v"0"
const highest = v"999"

# some version comparisons need to ignore part of the version number
strip_patch(ver) = VersionNumber(ver.major, ver.minor)
strip_minor(ver) = VersionNumber(ver.major)


## GCC compilers supported by the CUDA toolkit

# Source: CUDA/include/host_config.h or include/crt/host_config.h on 9.0+
const cuda_gcc_db = Dict(
    v"5.5"  => lowest:v"4.8",  # (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ > 8)) && #error
    v"6.0"  => lowest:v"4.8",  # (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ > 8)) && #error
    v"6.5"  => lowest:v"4.8",  # (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ > 8)) && #error
    v"7.0"  => lowest:v"4.9",  # (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ > 9)) && #error
    v"7.5"  => lowest:v"4.9",  # (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ > 9)) && #error
    v"8.0"  => lowest:v"6-",   # (__GNUC__ > 5)                                          && #error
    v"9.0"  => lowest:v"7-",   # (__GNUC__ > 6)                                          && #error
    v"9.1"  => lowest:v"7-",   # (__GNUC__ > 6)                                          && #error
    v"9.2"  => lowest:v"8-",   # (__GNUC__ > 7)                                          && #error
    v"10.0" => lowest:v"8-",   # (__GNUC__ > 7)                                          && #error
    v"10.1" => lowest:v"9-",   # (__GNUC__ > 8)                                          && #error
)

function gcc_supported(gcc::VersionNumber, toolkit::VersionNumber)
    gcc_range = get(cuda_gcc_db, strip_patch(toolkit)) do
        error("no support for CUDA $toolkit")
    end

    return in(strip_patch(gcc), gcc_range)
end


## MSVC compilers supported by the CUDA toolkit

# Source: CUDA/include/host_config.h or include/crt/host_config.h on 9.0+
#
# NOTE: plain integers, because from MSVC 14.1 on the number increases monotonically
#       https://blogs.msdn.microsoft.com/vcblog/2016/10/05/visual-c-compiler-version/
const cuda_msvc_db = Dict(
    v"5.5"     => 1500:1700,  # (_MSC_VER < 1500 || _MSC_VER > 1700) && #error
    v"6.0"     => 1500:1700,  # (_MSC_VER < 1500 || _MSC_VER > 1700) && #error
    v"6.5"     => 1600:1800,  # (_MSC_VER < 1600 || _MSC_VER > 1800) && #error
    v"7.0"     => 1600:1800,  # (_MSC_VER < 1600 || _MSC_VER > 1800) && #error
    v"7.5"     => 1600:1800,  # (_MSC_VER < 1600 || _MSC_VER > 1800) && #error
    v"8.0"     => 1600:1900,  # (_MSC_VER < 1600 || _MSC_VER > 1900) && #error
    v"9.0"     => 1600:1910,  # (_MSC_VER < 1600 || _MSC_VER > 1910) && #error
    v"9.0.176" => 1600:1911,  # (_MSC_VER < 1600 || _MSC_VER > 1911) && #error
    v"9.1"     => 1600:1911,  # (_MSC_VER < 1600 || _MSC_VER > 1911) && #error
    v"9.2"     => 1600:1913,  # (_MSC_VER < 1600 || _MSC_VER > 1913) && #error
    v"10.0"    => 1700:1920,  # (_MSC_VER < 1700 || _MSC_VER > 1920) && #error
    v"10.1"    => 1700:1930,  # (_MSC_VER < 1700 || _MSC_VER > 1930) && #error
)

function msvc_supported(msvc::VersionNumber, toolkit::VersionNumber)
    msvc_range = get(cuda_msvc_db, toolkit) do
        get(cuda_msvc_db, strip_patch(toolkit)) do
            error("no support for CUDA $toolkit")
        end
    end

    msvc_num = msvc.major * 100 + msvc.minor
    return in(msvc_num, msvc_range)
end


## devices supported by the CUDA toolkit

# Source:
# - https://en.wikipedia.org/wiki/CUDA#GPUs_supported
# - ptxas |& grep -A 10 '\--gpu-name'
const dev_cuda_db = Dict(
    v"1.0" => lowest:v"6.5",
    v"1.1" => lowest:v"6.5",
    v"1.2" => lowest:v"6.5",
    v"1.3" => lowest:v"6.5",
    v"2.0" => lowest:v"8.0",
    v"2.1" => lowest:v"8.0",
    v"3.0" => v"4.2":highest,
    v"3.2" => v"6.0":highest,
    v"3.5" => v"5.0":highest,
    v"3.7" => v"6.5":highest,
    v"5.0" => v"6.0":highest,
    v"5.2" => v"7.0":highest,
    v"5.3" => v"7.5":highest,
    v"6.0" => v"8.0":highest,
    v"6.1" => v"8.0":highest,
    v"6.2" => v"8.0":highest,
    v"7.0" => v"9.0":highest,
    v"7.2" => v"9.2":highest,
    v"7.5" => v"10.0":highest,
)

function devices_for_cuda(ver::VersionNumber)
    caps = Set{VersionNumber}()
    for (cap,r) in dev_cuda_db
        if strip_patch(ver) in r
            push!(caps, cap)
        end
    end
    return caps
end


## PTX ISAs supported by the CUDA toolkit

# Source:
# - PTX ISA document, Release History table
const isa_cuda_db = Dict(
    v"1.0" => v"1.0":highest,
    v"1.1" => v"1.1":highest,
    v"1.2" => v"2.0":highest,
    v"1.3" => v"2.1":highest,
    v"1.4" => v"2.2":highest,
    v"1.5" => v"2.2":highest,
    v"2.0" => v"3.0":highest,
    v"2.1" => v"3.1":highest,
    v"2.2" => v"3.2":highest,
    v"2.3" => v"4.2":highest,
    v"3.0" => v"4.1":highest,
    v"3.1" => v"5.0":highest,
    v"3.2" => v"5.5":highest,
    v"4.0" => v"6.0":highest,
    v"4.1" => v"6.5":highest,
    v"4.2" => v"7.0":highest,
    v"4.3" => v"7.5":highest,
    v"5.0" => v"8.0":highest,
    v"6.0" => v"9.0":highest,
    v"6.1" => v"9.1":highest,
    v"6.2" => v"9.2":highest,
    v"6.3" => v"10.0":highest,
    v"6.4" => v"10.1":highest,
)

function isas_for_cuda(ver::VersionNumber)
    caps = Set{VersionNumber}()
    for (cap,r) in isa_cuda_db
        if strip_patch(ver) in r
            push!(caps, cap)
        end
    end
    return caps
end


## devices supported by the LLVM NVPTX back-end

# Source: LLVM/lib/Target/NVPTX/NVPTX.td
const dev_llvm_db = Dict(
    v"2.0" => v"3.2":highest,
    v"2.1" => v"3.2":highest,
    v"3.0" => v"3.2":highest,
    v"3.2" => v"3.7":highest,
    v"3.5" => v"3.2":highest,
    v"3.7" => v"3.7":highest,
    v"5.0" => v"3.5":highest,
    v"5.2" => v"3.7":highest,
    v"5.3" => v"3.7":highest,
    v"6.0" => v"3.9":highest,
    v"6.1" => v"3.9":highest,
    v"6.2" => v"3.9":highest,
    v"7.0" => v"6.0":highest,
    v"7.2" => v"7.0":highest,
    v"7.5" => v"8.0":highest,
)

function devices_for_llvm(ver::VersionNumber)
    caps = Set{VersionNumber}()
    for (cap,r) in dev_llvm_db
        if strip_patch(ver) in r
            push!(caps, cap)
        end
    end
    return caps
end


## PTX ISAs supported by the LVM NVPTX back-end

# Source: LLVM/lib/Target/NVPTX/NVPTX.td
const isa_llvm_db = Dict(
    v"3.0" => v"3.2":v"3.5",
    v"3.1" => v"3.2":v"3.5",
    v"3.2" => v"3.5":highest,
    v"4.0" => v"3.5":highest,
    v"4.1" => v"3.7":highest,
    v"4.2" => v"3.7":highest,
    v"4.3" => v"3.9":highest,
    v"5.0" => v"3.9":highest,
    v"6.0" => v"6.0":highest,
    v"6.1" => v"7.0":highest,
    v"6.3" => v"8.0":highest,
)

function isas_for_llvm(ver::VersionNumber)
    caps = Set{VersionNumber}()
    for (cap,r) in isa_llvm_db
        if strip_patch(ver) in r
            push!(caps, cap)
        end
    end
    return caps
end


## other

shader(cap::VersionNumber) = "sm_$(cap.major)$(cap.minor)"
