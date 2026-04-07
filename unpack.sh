#!/bin/bash

# ==========================================
# 1. INITIALIZE VARIABLES & HELP FUNCTION
# ==========================================
# Flags act as booleans (0=false, 1=true)
VERBOSE=0
RECURSIVE=0

# Counters track the exact number of successful and failed extractions
SUCCESS_COUNT=0
FAILED_COUNT=0

# Help function to display usage information
usage() {
    echo "Usage: unpack [-r] [-v] file [files...]"
    echo "Options:"
    echo "  -v    Verbose mode: Echo each file being decompressed and warn for ignored files"
    echo "  -r    Recursive mode: Traverse directories recursively"
    exit 1
}

# ==========================================
# 2. PARSE FLAGS (-v, -r)
# ==========================================
# Parse script flags using getopts: -v for verbose output, -r for recursive scanning.
while getopts "vr" opt; do
    case $opt in
        v) VERBOSE=1 ;;
        r) RECURSIVE=1 ;;
        \?) usage ;; # Invalid option triggers the usage function
    esac
done

# Remove the processed flags from the arguments list.
# This ensures that $@ only contains the actual target files and directories.
shift $((OPTIND -1))

# Check if no files or directories were provided after the flags
if [ $# -eq 0 ]; then
    usage
fi
 
# ==========================================
# 3. DECOMPRESSION ENGINE (FUNCTIONS)
# ==========================================
process_file() {
    # Define local variables to prevent scope pollution across loop iterations
    local f="$1"
    local filename=$(basename "$f")
    local dir=$(dirname "$f")
    
    # Use 'file -b' to determine file type based on Magic Bytes, completely ignoring extensions
    local file_type=$(file -b "$f") 

    case "$file_type" in
        
        # ---------------------------------------------------------
        # ZIP Archives
        # ---------------------------------------------------------
        *"Zip archive data"*)
            [ $VERBOSE -eq 1 ] && echo "Unpacking $filename..."
            # -o overwrites existing files. -d extracts directly to the source directory.
            # || return 1 ensures we exit early with an error if the extraction fails.
            unzip -o "$f" -d "$dir" &>/dev/null || return 1
            ;;
            
        # ---------------------------------------------------------
        # GZIP Archives
        # ---------------------------------------------------------
        *"gzip compressed data"*)
            [ $VERBOSE -eq 1 ] && echo "Unpacking $filename..."
            # -c outputs to stdout. We redirect (>) to a new ".unpacked" file.
            # This crucial step ensures the original archive remains completely intact.
            gunzip -c "$f" > "${f}.unpacked" 2>/dev/null || return 1
            ;;
            
        # ---------------------------------------------------------
        # BZIP2 Archives
        # ---------------------------------------------------------
        *"bzip2 compressed data"*)
            [ $VERBOSE -eq 1 ] && echo "Unpacking $filename..."
            bunzip2 -c "$f" > "${f}.unpacked" 2>/dev/null || return 1
            ;;
            
        # ---------------------------------------------------------
        # Legacy COMPRESS Archives
        # ---------------------------------------------------------
        *"compress'd data"*)
            [ $VERBOSE -eq 1 ] && echo "Unpacking $filename..."
            uncompress -c "$f" > "${f}.unpacked" 2>/dev/null || return 1
            ;;
            
        # ---------------------------------------------------------
        # Default Fallback (Unsupported or Plain Text files)
        # ---------------------------------------------------------
        *)
            [ $VERBOSE -eq 1 ] && echo "Ignoring $filename"
            # Not a valid archive. Exit the function with an error status (1) to increment FAILED_COUNT
            return 1
            ;;
    esac

    # If the script reaches this line, the extraction was fully successful.
    return 0
}

# Wrapper function (DRY principle) to process a file and update the global counters
counter_func() {
    if process_file "$1"; then
        ((SUCCESS_COUNT++))
    else
        ((FAILED_COUNT++))
    fi
}

# ==========================================
# 4. MAIN EXECUTION LOOP
# ==========================================
for item in "$@"; do
    
    # Handle single files
    if [ -f "$item" ]; then
        counter_func "$item"
        
    # Handle directories
    elif [ -d "$item" ]; then
        if [ $RECURSIVE -eq 1 ]; then
            # Recursive: Process all files in the directory and all subdirectories
            # Using -print0 in find and -d $'\0' in read to safely handle filenames with spaces/newlines
            while IFS= read -r -d $'\0' current_file; do
                counter_func "$current_file"
            done < <(find "$item" -type f -print0)
            
        else
            # Not Recursive: Process only top-level files (-maxdepth 1)
            while IFS= read -r -d $'\0' current_file; do
                counter_func "$current_file"
            done < <(find "$item" -maxdepth 1 -type f -print0)
        fi
        
    else 
        # Item doesn't exist or is an unsupported file type (like a symlink)
        ((FAILED_COUNT++))
    fi
done

# ==========================================
# 5. FINAL OUTPUT & EXIT CODE
# ==========================================
# The exit code matches the amount of files NOT decompressed, per the requirements.
echo "Decompressed $SUCCESS_COUNT archive(s)"
exit $FAILED_COUNT