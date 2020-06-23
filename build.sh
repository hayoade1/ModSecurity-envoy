#!/bin/bash

if [ ! -f envoy/VERSION ]; then
    echo "Downloading submodule"
    git suubmoduule update --init
    echo "Done"
fi

case $1 in
    list-versions )
        cd envoy
        git ls-remote --tags 2> /dev/null | grep -o "refs/tags/.*" | sort -rV | grep -o '[^\/]*$'
        ;;
    version )
        cd envoy
        git describe --tags
        ;;
    set-version )
        cd envoy
        git checkout $2
        ;;
    build )
        if ! realpath modsecurity/include 2&>1 > /dev/null; then
            echo "Not found ModSecurity headers"
            exit 1
        fi

        if ! realpath modsecurity/libmodsecurity.a 2&>1 > /dev/null; then
            echo "Build ModSecurity first"
            exit 1
        fi

        # show version to build
        ENVOY_VER=$(cat envoy/VERSION)
        echo "Build with envoy v${ENVOY_VER}"

        # generate workspace
        echo "Write workspace file"
        cat <<EOL > WORKSPACE
workspace(name = "envoy_filter_modsecurity")

local_repository(
    name = "envoy",
    path = "envoy",
)
EOL
        # patch envoy workspace
        cat envoy/WORKSPACE | sed -e '1d' | sed -e 's|//bazel|@envoy//bazel|g' >> WORKSPACE

        echo "Start build"
        bazel build //:envoy
        ;;
    help|*)
        echo "$0 <command [args...]>"
        echo
        echo "Commands:"
        echo "    list-versions      List online envoy versions"
        echo "    version            Get current envoy version"
        echo "    set-version <ver>  Set envoy version"
        echo "    build              Start build"
        echo "    help               This message"
        ;;
esac
