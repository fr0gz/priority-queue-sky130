#!/usr/bin/env bash
#
# ============================================================================
# capture_priority_queue_sky130_environment.sh
# ============================================================================
#
# Reproducibility snapshot for the priority-queue SKY130 project.
#
# Current project stage:
#     C++ behavioral implementation, baseline characterization and validation.
#
# IMPORTANT:
#     The project currently has no RTL flow.
#     This script therefore captures the software/analysis environment that
#     affects the current experimental results without assuming the existence
#     of an RTL, synthesis or physical-design flow.
#
# Project:
#     priority-queue-sky130
#
# Main workspace:
#     /foss/designs/priority-queue-sky130
#
# Current experimental workspace:
#     /foss/designs/priority-queue-sky130/cpp
#
# Current analysis workspace:
#     /foss/designs/priority-queue-sky130/cpp/analysis
#
# Purpose:
#     Capture the execution environment used for:
#
#       - C++ compilation
#       - priority queue behavioral experiments
#       - deterministic baseline generation
#       - directed tests
#       - multipush characterization
#       - statistical analysis
#       - output validation
#
# Status terminology:
#
#     VERIFIED       -> directly observed from the environment
#     NOT_AVAILABLE  -> command/tool could not be queried
#     NOT_DEFINED    -> environment variable is not defined
#     NOT_FOUND      -> expected file/directory does not exist
#     DECLARED       -> supplied by project configuration
#
# The script does NOT modify:
#
#     - source files
#     - analysis results
#     - baseline files
#     - Git history
#     - Docker images
#     - PDK files
#
# Output:
#     cpp/reproducibility/environment_<timestamp>.txt
#
# Optional:
#     ./capture_priority_queue_sky130_environment.sh <output_file>
#
# ============================================================================

set -u
set -o pipefail

# ============================================================================
# 0. PROJECT CONFIGURATION
# ============================================================================

PROJECT_NAME="priority-queue-sky130"

PROJECT_ROOT="${PROJECT_ROOT:-/foss/designs/priority-queue-sky130}"
CPP_ROOT="${CPP_ROOT:-${PROJECT_ROOT}/cpp}"
ANALYSIS_ROOT="${ANALYSIS_ROOT:-${CPP_ROOT}/analysis}"

TIMESTAMP="$(date '+%Y-%m-%dT%H:%M:%S%z')"
TIMESTAMP_FILE="$(date '+%Y%m%d_%H%M%S')"

OUTPUT_DIR="${CPP_ROOT}/reproducibility"
OUTPUT_FILE="${1:-${OUTPUT_DIR}/environment_${TIMESTAMP_FILE}.txt}"

mkdir -p "${OUTPUT_DIR}"

# ============================================================================
# HELPERS
# ============================================================================

section()
{
    echo
    echo "============================================================================"
    echo "$1"
    echo "============================================================================"
}

subsection()
{
    echo
    echo "--- $1 ---"
}

status()
{
    printf "%-40s: %s\n" "$1" "$2"
}

command_exists()
{
    command -v "$1" >/dev/null 2>&1
}

print_env()
{
    local var="$1"

    if [ -n "${!var+x}" ]; then
        printf "%-40s: %s\n" "$var" "${!var}"
    else
        printf "%-40s: NOT_DEFINED\n" "$var"
    fi
}

hash_file()
{
    local file="$1"

    if [ -f "$file" ] && command_exists sha256sum; then
        sha256sum "$file" | awk '{print $1}'
    else
        echo "NOT_AVAILABLE"
    fi
}

inspect_file()
{
    local file="$1"

    echo "Path        : ${file}"

    if [ -f "${file}" ]; then
        echo "Status      : VERIFIED"
        echo "Type        : regular file"
        echo "Size        : $(wc -c < "${file}") bytes"
        echo "SHA256      : $(hash_file "${file}")"
    elif [ -e "${file}" ]; then
        echo "Status      : VERIFIED"
        echo "Type        : non-regular file"
    else
        echo "Status      : NOT_FOUND"
    fi
}

inspect_directory()
{
    local dir="$1"

    if [ -d "${dir}" ]; then
        status "${dir}" "VERIFIED"
    else
        status "${dir}" "NOT_FOUND"
    fi
}

print_tool_version()
{
    local tool="$1"

    if command_exists "${tool}"; then
        echo "Executable : $(command -v "${tool}")"
        echo "Resolved   : $(readlink -f "$(command -v "${tool}")" 2>/dev/null || command -v "${tool}")"

        "${tool}" --version 2>&1 | head -n 5 || true
    else
        echo "Status     : NOT_AVAILABLE"
    fi
}

# ============================================================================
# BEGIN REPORT
# ============================================================================

{
    echo "PRIORITY-QUEUE SKY130 REPRODUCIBILITY ENVIRONMENT SNAPSHOT"
    echo "==========================================================="
    echo
    echo "Project                     : ${PROJECT_NAME}"
    echo "Capture timestamp            : ${TIMESTAMP}"
    echo "Project root                : ${PROJECT_ROOT}"
    echo "C++ root                    : ${CPP_ROOT}"
    echo "Analysis root               : ${ANALYSIS_ROOT}"
    echo "Report                      : ${OUTPUT_FILE}"
    echo
    echo "CURRENT PROJECT STAGE"
    echo
    echo "The current project stage is C++ behavioral implementation,"
    echo "baseline characterization and validation."
    echo
    echo "RTL is NOT currently part of the project state captured by this script."
    echo
    echo "STATUS DEFINITIONS"
    echo "  VERIFIED       = directly observed"
    echo "  NOT_AVAILABLE  = tool/information unavailable"
    echo "  NOT_DEFINED    = environment variable not defined"
    echo "  NOT_FOUND      = expected path does not exist"
    echo "  DECLARED       = supplied by project configuration"
    echo

    # ========================================================================
    # 1. PROJECT IDENTITY
    # ========================================================================

    section "1. PROJECT IDENTITY"

    status "Project name" "${PROJECT_NAME}"
    status "Project root" "${PROJECT_ROOT}"
    status "C++ root" "${CPP_ROOT}"
    status "Analysis root" "${ANALYSIS_ROOT}"
    status "Capture time" "${TIMESTAMP}"

    inspect_directory "${PROJECT_ROOT}"
    inspect_directory "${CPP_ROOT}"
    inspect_directory "${ANALYSIS_ROOT}"

    # ========================================================================
    # 2. CURRENT PROJECT STAGE
    # ========================================================================

    section "2. CURRENT PROJECT STAGE"

    status "RTL present in current scope" "NOT_ASSUMED"

    if find "${CPP_ROOT}" \
        -type f \
        \( -iname '*.v' -o -iname '*.sv' -o -iname '*.vhd' -o -iname '*.vhdl' \) \
        2>/dev/null |
        grep -q .
    then
        status "RTL source files detected" "YES"
    else
        status "RTL source files detected" "NO"
    fi

    echo
    echo "Current reproducibility scope:"
    echo "  - C++ implementation"
    echo "  - deterministic baselines"
    echo "  - directed tests"
    echo "  - multipush experiments"
    echo "  - characterization"
    echo "  - statistical summaries"
    echo "  - output validation"

    # ========================================================================
    # 3. OPERATING SYSTEM / KERNEL / ARCHITECTURE
    # ========================================================================

    section "3. OPERATING SYSTEM / KERNEL / ARCHITECTURE"

    if [ -f /etc/os-release ]; then
        echo "[/etc/os-release]"
        cat /etc/os-release
    else
        status "OS release" "NOT_AVAILABLE"
    fi

    echo
    status "Kernel" "$(uname -srv 2>/dev/null || echo NOT_AVAILABLE)"
    status "Kernel release" "$(uname -r 2>/dev/null || echo NOT_AVAILABLE)"
    status "Architecture" "$(uname -m 2>/dev/null || echo NOT_AVAILABLE)"
    status "Machine" "$(uname -p 2>/dev/null || echo NOT_AVAILABLE)"

    if command_exists lscpu; then
        subsection "CPU information"
        lscpu 2>/dev/null || true
    fi

    # ========================================================================
    # 4. DATE / TIME / LOCALE
    # ========================================================================

    section "4. DATE / TIME / LOCALE"

    status "Capture timestamp" "${TIMESTAMP}"
    status "Timezone" "$(date '+%Z (%z)' 2>/dev/null || echo NOT_AVAILABLE)"
    status "UTC time" "$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo NOT_AVAILABLE)"

    echo
    locale 2>/dev/null || true

    # ========================================================================
    # 5. EXECUTION ENVIRONMENT
    # ========================================================================

    section "5. EXECUTION ENVIRONMENT"

    if [ -f /.dockerenv ]; then
        status "Docker container detection" "VERIFIED"
    else
        status "Docker container detection" "NOT_DETECTED"
    fi

    print_env "container"
    print_env "HOSTNAME"

    if [ -n "${HOSTNAME:-}" ]; then
        status "Hostname" "${HOSTNAME}"
    fi

    # ========================================================================
    # 6. DOCKER / IIC-OSIC-TOOLS
    # ========================================================================

    section "6. DOCKER / IIC-OSIC-TOOLS"

    if command_exists docker; then

        status "Docker executable" "$(command -v docker)"

        echo
        docker --version 2>&1 || true

        echo
        if docker info >/dev/null 2>&1; then
            status "Docker daemon" "AVAILABLE"

            docker info \
                --format='ServerVersion={{.ServerVersion}}' \
                2>/dev/null || true
        else
            status "Docker daemon" "NOT_ACCESSIBLE"
        fi

        echo
        subsection "Relevant local images"

        docker images \
            --format='{{.Repository}}:{{.Tag}} | ID={{.ID}} | Created={{.CreatedAt}}' \
            2>/dev/null |
            grep -Ei \
            'iic|osic|eda|sky130|open_pdks' \
            || echo "No matching images found."

        echo
        subsection "IIC-OSIC-TOOLS latest image"

        if docker image inspect hpretl/iic-osic-tools:latest \
            >/dev/null 2>&1
        then

            docker inspect hpretl/iic-osic-tools:latest \
                --format='Repository=hpretl/iic-osic-tools:latest
ImageID={{.Id}}
Created={{.Created}}
Architecture={{.Architecture}}
OS={{.Os}}' \
                2>/dev/null || true

        else
            echo "hpretl/iic-osic-tools:latest: NOT_AVAILABLE"
        fi

    else
        status "Docker" "NOT_AVAILABLE"
    fi

    # ========================================================================
    # 7. GIT SOURCE TRACEABILITY
    # ========================================================================

    section "7. GIT REPOSITORY / SOURCE TRACEABILITY"

    if command_exists git; then

        git --version 2>&1 || true

        if git -C "${PROJECT_ROOT}" rev-parse \
            --is-inside-work-tree >/dev/null 2>&1
        then

            status "Git repository" "VERIFIED"

            echo
            echo "Repository root:"
            git -C "${PROJECT_ROOT}" \
                rev-parse --show-toplevel 2>/dev/null || true

            echo
            echo "Branch:"
            git -C "${PROJECT_ROOT}" \
                branch --show-current 2>/dev/null || true

            echo
            echo "HEAD:"
            git -C "${PROJECT_ROOT}" \
                rev-parse HEAD 2>/dev/null || true

            echo
            echo "HEAD short:"
            git -C "${PROJECT_ROOT}" \
                rev-parse --short HEAD 2>/dev/null || true

            echo
            echo "HEAD metadata:"
            git -C "${PROJECT_ROOT}" log -1 \
                --date=iso-strict \
                --format='commit=%H%nparent=%P%nauthor=%an <%ae>%ndate=%ad%nsubject=%s' \
                2>/dev/null || true

            echo
            echo "Repository status:"
            git -C "${PROJECT_ROOT}" status --short 2>/dev/null || true

            echo
            echo "Working tree:"
            if git -C "${PROJECT_ROOT}" diff --quiet 2>/dev/null; then
                echo "CLEAN"
            else
                echo "MODIFIED"
            fi

            echo
            echo "Staged changes:"
            if git -C "${PROJECT_ROOT}" diff --cached --quiet 2>/dev/null; then
                echo "NONE"
            else
                echo "PRESENT"
            fi

            echo
            echo "Untracked files:"
            git -C "${PROJECT_ROOT}" \
                ls-files --others --exclude-standard \
                2>/dev/null || true

            echo
            echo "Remotes:"
            git -C "${PROJECT_ROOT}" \
                remote -v 2>/dev/null || true

        else
            status "Git repository" "NOT_DETECTED"
        fi

    else
        status "Git" "NOT_AVAILABLE"
    fi

    # ========================================================================
    # 8. C++ TOOLCHAIN
    # ========================================================================

    section "8. C++ TOOLCHAIN"

    subsection "g++"

    print_tool_version g++

    if command_exists g++; then
        echo
        echo "Target information:"
        g++ -dumpmachine 2>/dev/null || true

        echo
        echo "Compiler predefined macros:"
        g++ -dM -E -x c++ /dev/null 2>/dev/null |
            grep -E \
            '__cplusplus|__GNUC__|__GNUC_MINOR__|__GNUC_PATCHLEVEL__|__GLIBCXX__' \
            || true
    fi

    subsection "gcc"

    print_tool_version gcc

    subsection "clang++"

    print_tool_version clang++

    subsection "clang"

    print_tool_version clang

    subsection "make"

    print_tool_version make

    subsection "cmake"

    print_tool_version cmake

    # ========================================================================
    # 9. C++ BUILD ENVIRONMENT
    # ========================================================================

    section "9. C++ BUILD ENVIRONMENT"

    echo "Relevant build-related environment variables:"

    for var in \
        CC \
        CXX \
        CFLAGS \
        CXXFLAGS \
        CPPFLAGS \
        LDFLAGS \
        MAKEFLAGS \
        CMAKE_PREFIX_PATH
    do
        print_env "${var}"
    done

    echo
    echo "Compiler resolution:"

    if command_exists "${CXX:-g++}"; then
        echo "CXX executable:"
        command -v "${CXX:-g++}"
    else
        echo "CXX executable: NOT_AVAILABLE"
    fi

    # ========================================================================
    # 10. PYTHON ANALYSIS ENVIRONMENT
    # ========================================================================

    section "10. PYTHON ANALYSIS ENVIRONMENT"

    if command_exists python3; then

        echo "Executable:"
        command -v python3

        echo
        python3 --version 2>&1 || true

        echo
        echo "Python executable:"
        python3 -c \
            'import sys; print(sys.executable)' \
            2>/dev/null || true

        echo
        echo "Python version:"
        python3 -c \
            'import sys; print(sys.version.replace("\n"," "))' \
            2>/dev/null || true

        echo
        echo "Python platform:"
        python3 -c \
            'import platform; print(platform.platform())' \
            2>/dev/null || true

        echo
        echo "Installed analysis packages:"

        python3 -m pip list \
            --format=freeze \
            2>/dev/null || \
            echo "pip package listing unavailable."

    else
        echo "Python3: NOT_AVAILABLE"
    fi

    # ========================================================================
    # 11. PROJECT STRUCTURE
    # ========================================================================

    section "11. PROJECT STRUCTURE"

    if [ -d "${CPP_ROOT}" ]; then

        subsection "Top-level C++ directories"

        find "${CPP_ROOT}" \
            -maxdepth 1 \
            -mindepth 1 \
            -type d \
            -printf '%f/\n' \
            2>/dev/null |
            sort

        subsection "Top-level C++ files"

        find "${CPP_ROOT}" \
            -maxdepth 1 \
            -mindepth 1 \
            -type f \
            -printf '%f\n' \
            2>/dev/null |
            sort

    else
        status "C++ project structure" "NOT_AVAILABLE"
    fi

    # ========================================================================
    # 12. ANALYSIS STRUCTURE
    # ========================================================================

    section "12. ANALYSIS DIRECTORY STRUCTURE"

    if [ -d "${ANALYSIS_ROOT}" ]; then

        echo "Directories:"
        find "${ANALYSIS_ROOT}" \
            -type d \
            -printf '%p/\n' \
            2>/dev/null |
            sort

        echo
        echo "Files:"
        find "${ANALYSIS_ROOT}" \
            -type f \
            -printf '%p\n' \
            2>/dev/null |
            sort

    else
        echo "Analysis directory: NOT_FOUND"
    fi

    # ========================================================================
    # 13. CRITICAL ANALYSIS SCRIPTS
    # ========================================================================

    section "13. CRITICAL ANALYSIS SCRIPTS"

    for file in \
        "${ANALYSIS_ROOT}/check_baseline.py" \
        "${ANALYSIS_ROOT}/compare_output.py" \
        "${ANALYSIS_ROOT}/summarize_phase_stats.py"
    do

        echo
        inspect_file "${file}"

    done

    # ========================================================================
    # 14. BASELINE INVENTORY
    # ========================================================================

    section "14. BASELINE INVENTORY"

    BASELINE_DIR="${ANALYSIS_ROOT}/baseline"

    if [ -d "${BASELINE_DIR}" ]; then

        echo "Baseline files:"
        find "${BASELINE_DIR}" \
            -type f \
            -printf '%p | %s bytes\n' \
            2>/dev/null |
            sort

        echo
        echo "Baseline SHA256:"
        while IFS= read -r file; do
            echo "$(hash_file "${file}")  ${file}"
        done < <(
            find "${BASELINE_DIR}" \
                -type f \
                2>/dev/null |
                sort
        )

    else
        echo "Baseline directory: NOT_FOUND"
    fi

    # ========================================================================
    # 15. DIRECTED TEST INVENTORY
    # ========================================================================

    section "15. DIRECTED TEST INVENTORY"

    DIRECTED_DIR="${BASELINE_DIR}/directed"

    if [ -d "${DIRECTED_DIR}" ]; then

        find "${DIRECTED_DIR}" \
            -type f \
            -printf '%p | %s bytes | SHA256=%s\n' \
            2>/dev/null |
            while IFS='|' read -r path rest; do
                file="$(echo "${path}" | sed 's/[[:space:]]*$//')"

                if [ -f "${file}" ]; then
                    printf "%s | %s\n" \
                        "${file}" \
                        "$(hash_file "${file}")"
                fi
            done

    else
        echo "Directed baseline directory: NOT_FOUND"
    fi

    # ========================================================================
    # 16. STATISTICAL BASELINES
    # ========================================================================

    section "16. STATISTICAL BASELINES"

    STATS_DIR="${BASELINE_DIR}/stats"

    if [ -d "${STATS_DIR}" ]; then

        echo "Statistics files:"
        find "${STATS_DIR}" \
            -type f \
            -printf '%p | %s bytes\n' \
            2>/dev/null |
            sort

        echo
        echo "Statistics file hashes:"
        while IFS= read -r file; do
            echo "$(hash_file "${file}")  ${file}"
        done < <(
            find "${STATS_DIR}" \
                -type f \
                2>/dev/null |
                sort
        )

    else
        echo "Statistics directory: NOT_FOUND"
    fi

    # ========================================================================
    # 17. MULTIPUSH EXPERIMENT
    # ========================================================================

    section "17. MULTIPUSH EXPERIMENT"

    MULTIPUSH_DIR="${ANALYSIS_ROOT}/multipush"

    inspect_directory "${MULTIPUSH_DIR}"

    if [ -d "${MULTIPUSH_DIR}" ]; then

        echo
        echo "Multipush directories:"
        find "${MULTIPUSH_DIR}" \
            -maxdepth 1 \
            -mindepth 1 \
            -type d \
            -printf '%f/\n' \
            2>/dev/null |
            sort

        echo
        echo "Multipush files:"
        find "${MULTIPUSH_DIR}" \
            -type f \
            -printf '%p | %s bytes\n' \
            2>/dev/null |
            sort

    fi

    # ========================================================================
    # 18. MULTIPUSH CHARACTERIZATION
    # ========================================================================

    section "18. MULTIPUSH CHARACTERIZATION"

    CHARACTERIZATION_DIR="${MULTIPUSH_DIR}/characterization"

    if [ -d "${CHARACTERIZATION_DIR}" ]; then

        find "${CHARACTERIZATION_DIR}" \
            -type f \
            -printf '%p | %s bytes\n' \
            2>/dev/null |
            sort

        echo
        echo "SHA256:"
        while IFS= read -r file; do
            echo "$(hash_file "${file}")  ${file}"
        done < <(
            find "${CHARACTERIZATION_DIR}" \
                -type f \
                2>/dev/null |
                sort
        )

    else
        echo "Characterization directory: NOT_FOUND"
    fi

    # ========================================================================
    # 19. MULTIPUSH VALIDATION
    # ========================================================================

    section "19. MULTIPUSH VALIDATION"

    VALIDATION_DIR="${MULTIPUSH_DIR}/validation"

    if [ -d "${VALIDATION_DIR}" ]; then

        echo "Validation files:"
        find "${VALIDATION_DIR}" \
            -type f \
            -printf '%p | %s bytes\n' \
            2>/dev/null |
            sort

        echo
        echo "Validation SHA256:"
        while IFS= read -r file; do
            echo "$(hash_file "${file}")  ${file}"
        done < <(
            find "${VALIDATION_DIR}" \
                -type f \
                2>/dev/null |
                sort
        )

    else
        echo "Validation directory: NOT_FOUND"
    fi

    # ========================================================================
    # 20. TEST RESULT FORMAT
    # ========================================================================

    section "20. TEST RESULT FORMAT"

    echo "Current validation scripts indicate the expected result format:"
    echo
    echo "  POP_RESULT <priority> <value>"
    echo
    echo "The comparison utility:"
    echo "  - parses POP_RESULT records;"
    echo "  - compares expected and actual sequences;"
    echo "  - reports the first mismatch;"
    echo "  - reports output-length mismatches."

    echo
    echo "Validation script:"
    inspect_file "${ANALYSIS_ROOT}/compare_output.py"

    # ========================================================================
    # 21. BASELINE PARAMETER EXTRACTION
    # ========================================================================

    section "21. BASELINE PARAMETER / SEED INVENTORY"

    if [ -d "${ANALYSIS_ROOT}" ]; then

        echo "Candidate parameters detected from filenames:"

        find "${ANALYSIS_ROOT}" \
            -type f \
            -name '*.txt' \
            2>/dev/null |
            sort |
            sed -n \
            -E \
            's/.*(baseline_[^/]+|phase_[^/]+|seed[0-9]+).*/\1/p' |
            sort -u || true

        echo
        echo "Seed references:"
        grep -RhoE \
            'seed[=_-]?[0-9]+' \
            "${ANALYSIS_ROOT}" \
            2>/dev/null |
            sort -u || true

    fi

    # ========================================================================
    # 22. ANALYSIS SCRIPT SOURCE SNAPSHOT
    # ===============================================================
    # ========================================================================
    # 22. ANALYSIS SCRIPT SOURCE SNAPSHOT
    # ========================================================================

    section "22. ANALYSIS SCRIPT SOURCE SNAPSHOT"

    echo "Critical analysis scripts and SHA256:"
    echo

    for file in \
        "${ANALYSIS_ROOT}/check_baseline.py" \
        "${ANALYSIS_ROOT}/compare_output.py" \
        "${ANALYSIS_ROOT}/summarize_phase_stats.py"
    do

        if [ -f "${file}" ]; then
            echo "FILE: ${file}"
            echo "SIZE: $(wc -c < "${file}") bytes"
            echo "SHA256: $(hash_file "${file}")"
            echo
        else
            echo "FILE: ${file}"
            echo "STATUS: NOT_FOUND"
            echo
        fi

    done

    # ========================================================================
    # 23. PROJECT SOURCE INVENTORY
    # ========================================================================

    section "23. PROJECT SOURCE INVENTORY"

    echo "C++ source files:"
    find "${CPP_ROOT}" \
        -type f \
        \( \
            -iname '*.cpp' \
            -o -iname '*.cc' \
            -o -iname '*.cxx' \
            -o -iname '*.h' \
            -o -iname '*.hpp' \
        \) \
        2>/dev/null |
        sort

    echo
    echo "C++ source SHA256:"
    while IFS= read -r file; do
        echo "$(hash_file "${file}")  ${file}"
    done < <(
        find "${CPP_ROOT}" \
            -type f \
            \( \
                -iname '*.cpp' \
                -o -iname '*.cc' \
                -o -iname '*.cxx' \
                -o -iname '*.h' \
                -o -iname '*.hpp' \
            \) \
            2>/dev/null |
            sort
    )

    # ========================================================================
    # 24. MAKE / BUILD FILES
    # ========================================================================

    section "24. BUILD CONFIGURATION"

    for file in \
        "${CPP_ROOT}/Makefile" \
        "${CPP_ROOT}/makefile" \
        "${CPP_ROOT}/CMakeLists.txt"
    do

        if [ -e "${file}" ]; then
            echo
            inspect_file "${file}"
        fi

    done

    # ========================================================================
    # 25. ANALYSIS SCRIPT INVENTORY
    # ========================================================================

    section "25. ANALYSIS SCRIPT INVENTORY"

    if [ -d "${ANALYSIS_ROOT}" ]; then

        find "${ANALYSIS_ROOT}" \
            -type f \
            \( \
                -iname '*.py' \
                -o -iname '*.sh' \
            \) \
            -printf '%p | %s bytes\n' \
            2>/dev/null |
            sort

        echo
        echo "Analysis script SHA256:"

        while IFS= read -r file; do
            echo "$(hash_file "${file}")  ${file}"
        done < <(
            find "${ANALYSIS_ROOT}" \
                -type f \
                \( \
                    -iname '*.py' \
                    -o -iname '*.sh' \
                \) \
                2>/dev/null |
                sort
        )

    else
        echo "Analysis directory: NOT_FOUND"
    fi

    # ========================================================================
    # 26. EXPERIMENTAL DATA SUMMARY
    # ========================================================================

    section "26. EXPERIMENTAL DATA SUMMARY"

    echo "Baseline:"
    if [ -d "${BASELINE_DIR}" ]; then
        find "${BASELINE_DIR}" \
            -type f \
            -name '*.txt' \
            2>/dev/null |
            wc -l
    else
        echo "NOT_FOUND"
    fi

    echo
    echo "Multipush:"
    if [ -d "${MULTIPUSH_DIR}" ]; then
        find "${MULTIPUSH_DIR}" \
            -type f \
            -name '*.txt' \
            2>/dev/null |
            wc -l
    else
        echo "NOT_FOUND"
    fi

    echo
    echo "Validation:"
    if [ -d "${VALIDATION_DIR}" ]; then
        find "${VALIDATION_DIR}" \
            -type f \
            -name '*.txt' \
            2>/dev/null |
            wc -l
    else
        echo "NOT_FOUND"
    fi

    # ========================================================================
    # 27. STATISTICS SUMMARY
    # ========================================================================

    section "27. STATISTICS SUMMARY"

    SUMMARY_SCRIPT="${ANALYSIS_ROOT}/summarize_phase_stats.py"

    if [ -f "${SUMMARY_SCRIPT}" ] && command_exists python3; then

        echo "Running statistics summarizer:"
        echo

        (
            cd "${CPP_ROOT}" || exit 0
            python3 "${SUMMARY_SCRIPT}"
        ) 2>&1 || true

    else

        if [ ! -f "${SUMMARY_SCRIPT}" ]; then
            echo "summarize_phase_stats.py: NOT_FOUND"
        fi

        if ! command_exists python3; then
            echo "python3: NOT_AVAILABLE"
        fi

    fi

    # ========================================================================
    # 28. REPRODUCIBILITY ARTIFACTS
    # ========================================================================

    section "28. REPRODUCIBILITY ARTIFACTS"

    if [ -d "${OUTPUT_DIR}" ]; then

        echo "Existing environment snapshots:"
        find "${OUTPUT_DIR}" \
            -maxdepth 1 \
            -type f \
            -printf '%p | %s bytes\n' \
            2>/dev/null |
            sort

    else
        echo "Reproducibility directory: NOT_FOUND"
    fi

    # ========================================================================
    # 29. ENVIRONMENT VARIABLES
    # ========================================================================

    section "29. RELEVANT ENVIRONMENT VARIABLES"

    for var in \
        CC \
        CXX \
        CFLAGS \
        CXXFLAGS \
        CPPFLAGS \
        LDFLAGS \
        MAKEFLAGS \
        CMAKE_PREFIX_PATH \
        PATH \
        LD_LIBRARY_PATH \
        PYTHONPATH \
        LANG \
        LC_ALL \
        TZ
    do
        print_env "${var}"
    done

    # ========================================================================
    # 30. REPRODUCIBILITY SUMMARY
    # ========================================================================

    section "30. REPRODUCIBILITY SUMMARY"

    echo "PROJECT"
    status "Name" "${PROJECT_NAME}"
    status "Workspace" "${CPP_ROOT}"
    status "Analysis workspace" "${ANALYSIS_ROOT}"

    echo
    echo "PROJECT STAGE"
    status "Current stage" \
        "C++ behavioral implementation / characterization / validation"

    status "RTL source files" \
        "$(
            if find "${CPP_ROOT}" \
                -type f \
                \( -iname '*.v' -o -iname '*.sv' -o -iname '*.vhd' -o -iname '*.vhdl' \) \
                2>/dev/null |
                grep -q .
            then
                echo DETECTED
            else
                echo NOT_PRESENT
            fi
        )"

    echo
    echo "TOOLCHAIN"

    if command_exists g++; then
        status "g++" "VERIFIED"
        status "g++ path" "$(command -v g++)"
    else
        status "g++" "NOT_AVAILABLE"
    fi

    if command_exists python3; then
        status "Python3" "VERIFIED"
        status "Python3 path" "$(command -v python3)"
    else
        status "Python3" "NOT_AVAILABLE"
    fi

    if command_exists git; then
        status "Git" "VERIFIED"
    else
        status "Git" "NOT_AVAILABLE"
    fi

    echo
    echo "SOURCE CONTROL"

    if git -C "${PROJECT_ROOT}" rev-parse HEAD >/dev/null 2>&1; then
        status "Git HEAD" \
            "$(git -C "${PROJECT_ROOT}" rev-parse HEAD)"

        status "Git branch" \
            "$(git -C "${PROJECT_ROOT}" branch --show-current)"
    else
        status "Git HEAD" "NOT_AVAILABLE"
    fi

    echo
    echo "ANALYSIS"

    status "Baseline directory" \
        "$([ -d "${BASELINE_DIR}" ] && echo VERIFIED || echo NOT_FOUND)"

    status "Multipush directory" \
        "$([ -d "${MULTIPUSH_DIR}" ] && echo VERIFIED || echo NOT_FOUND)"

    status "Validation directory" \
        "$([ -d "${VALIDATION_DIR}" ] && echo VERIFIED || echo NOT_FOUND)"

    status "Characterization directory" \
        "$([ -d "${CHARACTERIZATION_DIR}" ] && echo VERIFIED || echo NOT_FOUND)"

    echo
    echo "CRITICAL ANALYSIS SCRIPTS"

    for file in \
        "${ANALYSIS_ROOT}/check_baseline.py" \
        "${ANALYSIS_ROOT}/compare_output.py" \
        "${ANALYSIS_ROOT}/summarize_phase_stats.py"
    do

        if [ -f "${file}" ]; then
            status "$(basename "${file}")" \
                "VERIFIED SHA256=$(hash_file "${file}")"
        else
            status "$(basename "${file}")" \
                "NOT_FOUND"
        fi

    done

    echo
    echo "IMPORTANT REPRODUCIBILITY NOTE"
    echo
    echo "This snapshot describes the environment and experimental artifacts"
    echo "available at capture time."
    echo
    echo "The current project does NOT contain an RTL implementation."
    echo "Therefore this report intentionally does not assume:"
    echo
    echo "  - RTL simulation"
    echo "  - synthesis"
    echo "  - timing analysis"
    echo "  - place and route"
    echo "  - GDS generation"
    echo "  - physical verification"
    echo
    echo "For the current behavioral/algorithmic stage, preserve together:"
    echo
    echo "  1. this environment snapshot;"
    echo "  2. the Git commit;"
    echo "  3. the C++ source files;"
    echo "  4. the compiler and build configuration;"
    echo "  5. deterministic baseline files;"
    echo "  6. directed test outputs;"
    echo "  7. multipush characterization;"
    echo "  8. validation outputs;"
    echo "  9. statistical summaries;"
    echo " 10. random seeds and experiment parameters."
    echo
    echo "No source, result, baseline or PDK files were modified by this"
    echo "environment-capture script."

    # ========================================================================
    # 31. CAPTURE METADATA
    # ========================================================================

    section "31. CAPTURE METADATA"

    echo "Script name                 : $(basename "$0")"
    echo "Project                     : ${PROJECT_NAME}"
    echo "Capture timestamp            : ${TIMESTAMP}"
    echo "Project root                : ${PROJECT_ROOT}"
    echo "C++ root                    : ${CPP_ROOT}"
    echo "Analysis root               : ${ANALYSIS_ROOT}"
    echo "Output                      : ${OUTPUT_FILE}"
    echo
    echo "END OF ENVIRONMENT SNAPSHOT"

} | tee "${OUTPUT_FILE}"

echo
echo "=========================================================================="
echo "Environment snapshot generated:"
echo "${OUTPUT_FILE}"
echo "=========================================================================="
