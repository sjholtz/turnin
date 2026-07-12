# To use these functions, they need to be sourced, either (the first
# option is fast and short!)
# . t
# source t

# These functions are designed to be used from <server>.

li() {
    declare -A number_assigns
    number_assigns["L"]=7  # Number of Lab-type assignments
    number_assigns["P"]=7  # Number of Project-type assignments

    # Must have 2 arguments
    if [ "$#" -ne 2 ]; then
        printf "Usage: li <type> <num>\n\n"
        printf "\tWhere:\n"
        printf "\t\t<type>: L or P (for lab or project) - can be lowercase.\n"
        printf "\t\t<num>: 1-${number_assigns[L]} labs and 1-${number_assigns[P]} projects.\n\n"
        return 1
    fi

    local type="$1"
    local number="$2"

    # Key into 'number_assigns' associative array: must be uppercase
    # "L" or "P"
    local index="$(echo ${type} | tr [:lower:] [:upper:])"

    # If this is a "lab"-type assignment
    if [[ "${type}" == "l" ]] || [[ "${type}" == "L" ]]; then
        type="lL"
    elif [[ "${type}" == "p" ]] || [[ "${type}" == "P" ]]; then
        type="pP"
    else
        printf "Illegal assignment type... must be L, l, P, or p ... exiting.\n\n"
        return 2
    fi

    # This course has $number_assigns["$index"] labs or projects
    if [[ ! "${number}" =~ ^[1-${number_assigns[${index}]}]+$ ]]; then
        printf "Illegal assignment number... must be 1-${number_assigns[${index}]} ... exiting.\n\n"
        return 3
    fi

    # List all timestamped directories in decreasing time order (most
    # recent first)
    find . -maxdepth 2 -mindepth 2 -type d | \
        sort -bnr -t='-' -k=6.1,6.2 | \
        sort -sbnr -t='-' -k=5,5 | \
        sort -sbnr -t='-' -k=4,4 | \
        sort -sbnr -t='-' -k=3,3 | \
        sort -sbnr -t='-' -k=2,2 | \
        sort -ds -t='/' -k=2,2 | \
        grep --color=never "^.*/.*/.*[${type}].*${number}.*$"

    # Synopsis of the above:
    # 1. Find directories only, 2 nested directories deep.
    # 2–6. Sort output, one field at a time: "s"=stable sort–do not
    #      change the order of items with the same value; "b"=remove
    #      leading field separator–the '-' in this case (see option
    #      't'); "n"=numeric sort; "r"=reverse (descending) order–puts
    #      the most recent at the top; "t='-'"=field separator is '-';
    #      "k=6.1,6.2"=sort from 6th field’s first character to the
    #      6th field’s 2 character; "k=n,n"=sort the n^th field.
    # 7. Sort, "d"=dictionary order; "s", "t", and "k" same as above,
    #    with "t" set to '/' instead of '-'.
    # 8. grep, "color=never"=no color, because the color codes make
    #    the output unusable for our use case; match only those
    #    directories that start with a [lL] (lab) or [pP] (project)
    #    followed by the assignment number.

    return 0
}

# Build function
# - Moves to argument <path>
# - Checks for presence of a CMakeLists.txt file in the CWD
# - Creates a build directory in the CWD and moves to it
# - Build the executable - runs cmake and make
#
# Note that the user in in the 'build' directory after execution.
#
# Usage: b <path>
b() {
    # Must pass a single argument
    if [ "$#" -ne 1 ]; then
        printf "Must pass in the path to the directory holding the CMakeLists.txt file ... exiting.\n\n"
        return 1
    fi

    local dir="$1"

    # Change into given directory
    cd "${dir}" 2>/dev/null || return 1

    # Check if CMakeLists.txt exists in CWD
    if [[ ! -f CMakeLists.txt ]]; then
        printf "There is no CMakeLists.txt file to build from in %s ... exiting\n\n" "${dir}"
        return 2
    fi

    # Create build directory with proper permissions
    mkdir -m 755 build 2>/dev/null || return 3

    # Move into that build directory
    cd build 2>/dev/null || return 4

    # Create the build system
    cmake .. 2>/dev/null || return 5

    # Build the executable
    make 2>/dev/null || return 6

    printf "\nExecute 'c' to clean-up after test execution.\n\n"

    return 0
}

# Clean-up function:
# - Makes sure we're in a directory that has a CMake build system in it
# - Move to parent directory
# - Make sure that a directory named build in present
# - Remove that directory
c() {
    if [ ! -f "cmake_install.cmake" ]; then
        printf "This can only be called in a build directory created by cmake ... exiting.\n\n"
        return 1
    fi

    # Back out to parent directory
    cd .. 2>/dev/null || return 2

    # Verify that there is a 'build' directory in ., else report no
    # 'build' and exit:
    if [[ ! -d build ]]; then
        printf "There is no build directory here ... exiting.\n\n"
        return 3
    fi

    # Remove the 'build' directory
    rm -rf build 2>/dev/null || return 4

    # Back out to the directory that 'b()' was initially called in
    cd ../../ 2>/dev/null || return 5

    printf "All cleaned up.\n\n"

    return 0
}
