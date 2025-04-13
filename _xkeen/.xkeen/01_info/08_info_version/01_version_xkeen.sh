info_version_xkeen() {
    url="https://raw.githubusercontent.com/Skrill0/XKeen/main/_xkeen/01_info/01_info_variable.sh"
    version_line=$(curl -s $url | grep "XKEEN_CURRENT_VERSION=")

    if echo "$version_line" | grep -q "XKEEN_CURRENT_VERSION=\"[0-9]\+\.[0-9]\+\""; then
        XKEEN_GITHUB_VERSION=$(echo "$version_line" | sed -n 's/XKEEN_CURRENT_VERSION="\([0-9]\+\.[0-9]\+\)"/\1/p')
    fi
}