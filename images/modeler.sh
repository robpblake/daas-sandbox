#!/bin/sh

# This script is only here temporarily to build the online editor frontend and
# background zips manually, which then get uploaded to dropbox for use in the
# build (see modules.sh). When the artifacts are complete and ready for our
# purposes, this can be removed, and new urls in module.yaml can be used.

set -e

os_has_cmd() {
    local cmd=${1}
    if (which "${cmd}" > /dev/null 2>&1); then
        return 0
    else
        return 1
    fi
}

clone_kogito_tooling() {
    pushd . &> /dev/null

    git clone https://github.com/kelvah/kogito-tooling
    cd kogito-tooling
    git checkout DAAS-POC

    popd &> /dev/null
}

config_online_editor() {
    local editor_src_dir="packages/online-editor/src"
    cat <<EOF > ${editor_src_dir}/config.ts
export const config = {
  development: {
    server: {
      backendUrl: "MODELER_SERVER_BACKENDURL",
      projectName: "MODELER_SERVER_PROJECTNAME",
      saveDirectory: "MODELER_SERVER_SAVEDIRECTORY"
    },
    openApi: {
      url: "MODELER_OPENAPI_URL",
      specPath: "MODELER_OPENAPI_SPECPATH"
    },
    explainability: {
      serviceUrl: "MODELER_EXPLAINABILITY_SERVICEURL",
      auditUIUrl: "MODELER_EXPLAINABILITY_AUDITUIURL"
    },
    publish: {
      url: "MODELER_PUBLISH_URL",
      appName: "MODELER_PUBLISH_APPNAME",
      envName: "MODELER_PUBLISH_ENVNAME"
    }
  }
};
EOF
}

config_online_editor_backend() {
    cat <<EOF > packages/online-editor-backend/src/config.ts
export const config = {
  development: {
    server: {
      hooksDir: "MODELER_SERVER_HOOKSDIR",
      projectsDir: "MODELER_SERVER_PROJECTSDIR",
      port: "MODELER_SERVER_PORT"
    }
  }
};
EOF
}

build_kogito_tooling() {
    pushd . &> /dev/null

    cd kogito-tooling
    rm -rf packages/chrome-extension*
    rm -rf packages/hub
    rm -rf packages/pmml-editor*
    rm -rf packages/vscode-extension*

    config_online_editor
    config_online_editor_backend

    yarn run init
    yarn run build:fast -- -- --mode production --devtool none

    popd &> /dev/null
}

package_kogito_tooling() {
    # package frontend
    (cd kogito-tooling/packages/online-editor; \
        zip -q -r ../../../kogito-tooling_online-editor.zip dist)
    # package backend
    (cd kogito-tooling/packages/online-editor-backend; \
        zip -q -r ../../../kogito-tooling_online-editor-backend.zip dist node_modules)
}

main() {
    for cmd in git java mvn node npm yarn ; do
        if ! os_has_cmd ${cmd} ; then
            echo "Missing command: ${cmd}"
            return 1
        fi
    done

    pushd . &> /dev/null

    local build_dir="/tmp/daas"
    if [ -d "${build_dir}" ]; then
        rm -rf ${build_dir}
    fi
    mkdir -p ${build_dir}
    cd ${build_dir}

    clone_kogito_tooling
    build_kogito_tooling
    package_kogito_tooling

    rm -rf /tmp/yarn--*

    popd &> /dev/null
}

main ${@}
