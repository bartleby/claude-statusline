#!/bin/bash
# Claude Skin Selector
# Usage: claude-skin.sh          - show gallery
#        claude-skin.sh <name>   - apply theme globally
#        claude-skin.sh here <name|off> - set/clear skin for the current folder (SKIN_CWD or $PWD)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${HOME}/.claude/current_skin"
DIRS_FILE="${HOME}/.claude/skin_dirs"
TARGET_DIR="${SKIN_CWD:-$PWD}"

# Ensure config directory exists
mkdir -p "${HOME}/.claude"

# Source themes
source "${SCRIPT_DIR}/themes.sh"

# Show gallery
show_gallery() {
    RST='\033[0m'
    C_BORDER='\033[38;5;240m'
    border="${C_BORDER}│${RST}"

    COLUMN=16
    CENTER_OFFSET=4

    print_names() {
        local n1="$1" n2="$2" n3="$3"
        local len1=${#n1} len2=${#n2} len3=${#n3}
        local c1=4 c2=20 c3=36
        local p1=$((c1 - len1/2))
        local p2=$((c2 - len2/2))
        local p3=$((c3 - len3/2))

        local out="" i=0
        while ((i < p1)); do out+=" "; ((i++)); done
        out+="$n1"; ((i+=len1))
        while ((i < p2)); do out+=" "; ((i++)); done
        out+="$n2"; ((i+=len2))
        while ((i < p3)); do out+=" "; ((i++)); done
        out+="$n3"

        printf '%b %s\n' "$border" "$out"
    }

    echo ""
    echo "Available Skins:"
    echo ""

    gap="       "

    # Row 1: KRATOS, SPIDERMAN, CAPTAIN
    load_theme kratos;    k1="$logo1";  k2="$logo2";  k3="$logo3"
    load_theme spiderman; sp1="$logo1"; sp2="$logo2"; sp3="$logo3"
    load_theme captain;   ca1="$logo1"; ca2="$logo2"; ca3="$logo3"

    printf '%b %b%s%b%s%b\n' "$border" "$k1" "$gap" "$sp1" "$gap" "$ca1"
    printf '%b %b%s%b%s%b\n' "$border" "$k2" "$gap" "$sp2" "$gap" "$ca2"
    printf '%b %b%s%b%s%b\n' "$border" "$k3" "$gap" "$sp3" "$gap" "$ca3"
    print_names "KRATOS" "SPIDERMAN" "CAPTAIN"
    echo ""

    # Row 2: SHADOW, OCEAN, GOOSE
    load_theme shadow; s1="$logo1"; s2="$logo2"; s3="$logo3"
    load_theme ocean;  o1="$logo1"; o2="$logo2"; o3="$logo3"
    load_theme goose;  go1="$logo1"; go2="$logo2"; go3="$logo3"

    printf '%b %b%s%b%s%b\n' "$border" "$s1" "$gap" "$o1" "$gap" "$go1"
    printf '%b %b%s%b%s%b\n' "$border" "$s2" "$gap" "$o2" "$gap" "$go2"
    printf '%b %b%s%b%s%b\n' "$border" "$s3" "$gap" "$o3" "$gap" "$go3"
    print_names "SHADOW" "OCEAN" "GOOSE"
    echo ""

    # Row 3: MATRIX, SAKURA, AURORA
    load_theme matrix; m1="$logo1"; m2="$logo2"; m3="$logo3"
    load_theme sakura; sa1="$logo1"; sa2="$logo2"; sa3="$logo3"
    load_theme aurora; a1="$logo1";  a2="$logo2";  a3="$logo3"

    printf '%b %b%s%b%s%b\n' "$border" "$m1" "$gap" "$sa1" "$gap" "$a1"
    printf '%b %b%s%b%s%b\n' "$border" "$m2" "$gap" "$sa2" "$gap" "$a2"
    printf '%b %b%s%b%s%b\n' "$border" "$m3" "$gap" "$sa3" "$gap" "$a3"
    print_names "MATRIX" "SAKURA" "AURORA"
    echo ""

    # Row 4: EMBER, FROST, ODI
    load_theme ember; e1="$logo1"; e2="$logo2"; e3="$logo3"
    load_theme frost; fr1="$logo1"; fr2="$logo2"; fr3="$logo3"
    load_theme odi;   od1="$logo1"; od2="$logo2"; od3="$logo3"

    printf '%b %b%s%b%s%b\n' "$border" "$e1" "$gap" "$fr1" "$gap" "$od1"
    printf '%b %b%s%b%s%b\n' "$border" "$e2" "$gap" "$fr2" "$gap" "$od2"
    printf '%b %b%s%b%s%b\n' "$border" "$e3" "$gap" "$fr3" "$gap" "$od3"
    print_names "EMBER" "FROST" "ODI"
    echo ""

    # Row 5: CYBERPUNK, LAVENDER, GOLD
    load_theme cyberpunk; cy1="$logo1"; cy2="$logo2"; cy3="$logo3"
    load_theme lavender;  la1="$logo1"; la2="$logo2"; la3="$logo3"
    load_theme gold;      go1="$logo1"; go2="$logo2"; go3="$logo3"

    printf '%b %b%s%b%s%b\n' "$border" "$cy1" "$gap" "$la1" "$gap" "$go1"
    printf '%b %b%s%b%s%b\n' "$border" "$cy2" "$gap" "$la2" "$gap" "$go2"
    printf '%b %b%s%b%s%b\n' "$border" "$cy3" "$gap" "$la3" "$gap" "$go3"
    print_names "CYBERPUNK" "LAVENDER" "GOLD"
    echo ""

    # Row 6: INFERNO, AMETHYST, BUBBLEGUM
    load_theme inferno;   in1="$logo1"; in2="$logo2"; in3="$logo3"
    load_theme amethyst;  am1="$logo1"; am2="$logo2"; am3="$logo3"
    load_theme bubblegum; bu1="$logo1"; bu2="$logo2"; bu3="$logo3"

    printf '%b %b%s%b%s%b\n' "$border" "$in1" "$gap" "$am1" "$gap" "$bu1"
    printf '%b %b%s%b%s%b\n' "$border" "$in2" "$gap" "$am2" "$gap" "$bu2"
    printf '%b %b%s%b%s%b\n' "$border" "$in3" "$gap" "$am3" "$gap" "$bu3"
    print_names "INFERNO" "AMETHYST" "BUBBLEGUM"
    echo ""

    # Show current skin
    if [[ -f "$CONFIG_FILE" ]]; then
        current=$(cat "$CONFIG_FILE")
        echo "Current: $current"
    fi
    if [[ -f "$DIRS_FILE" ]]; then
        here=$(awk -F'\t' -v cwd="$TARGET_DIR" '
            (cwd == $1 || index(cwd, $1 "/") == 1) && length($1) > best { best = length($1); line = $1 " -> " $2 }
            END { print line }' "$DIRS_FILE")
        [[ -n "$here" ]] && echo "Folder: $here"
    fi
    echo "Usage: /skin <name>  |  /skin here <name>  |  /skin here off"
    echo "Press Shift+Tab to refresh statusline after applying"
    echo ""
}

# Apply theme
apply_theme() {
    local name="$1"
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]')

    # Validate theme exists
    if ! echo "$THEMES" | grep -qw "$name"; then
        echo "Unknown skin: $name"
        echo "Available: $THEMES"
        return 1
    fi

    # Save to config
    echo "$name" > "$CONFIG_FILE"
    echo "Skin applied: $name"
    echo "Press Shift+Tab to refresh statusline"
}

# Remove the exact TARGET_DIR entry from the folder map
clear_dir() {
    [[ -f "$DIRS_FILE" ]] || return 0
    awk -F'\t' -v d="$TARGET_DIR" '$1 != d' "$DIRS_FILE" > "${DIRS_FILE}.tmp" && mv "${DIRS_FILE}.tmp" "$DIRS_FILE"
}

# Bind a theme to TARGET_DIR (and its subfolders)
apply_dir_theme() {
    local name="$1"
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]')

    if [[ -z "$name" ]]; then
        echo "Usage: /skin here <name>  |  /skin here off"
        return 1
    fi

    if [[ "$name" == "off" ]]; then
        clear_dir
        echo "Folder skin removed: $TARGET_DIR"
        echo "Press Shift+Tab to refresh statusline"
        return 0
    fi

    if ! echo "$THEMES" | grep -qw "$name"; then
        echo "Unknown skin: $name"
        echo "Available: $THEMES"
        return 1
    fi

    clear_dir
    printf '%s\t%s\n' "$TARGET_DIR" "$name" >> "$DIRS_FILE"
    echo "Skin applied to $TARGET_DIR: $name"
    echo "Press Shift+Tab to refresh statusline"
}

# Main
if [[ $# -eq 0 ]]; then
    show_gallery
elif [[ "$1" == "here" ]]; then
    apply_dir_theme "$2"
else
    apply_theme "$1"
fi
