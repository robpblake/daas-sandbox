#!/usr/bin/env bash

configure() {
    local index_js="${DAAS_HOME}/modeler/backend/dist/index.js"
    if [ -f "${index_js}" ]; then

        local modeler_hooks_dir="${DAAS_HOME}/modeler/hooks"
        local modeler_projects_dir="${DAAS_HOME}/modeler/projects"
        mkdir -p ${modeler_hooks_dir}
        mkdir -p ${modeler_projects_dir}

        sed -i "s,MODELER_SERVER_HOOKSDIR,${modeler_hooks_dir}/,g" ${index_js}
        sed -i "s,MODELER_SERVER_PROJECTSDIR,${modeler_projects_dir}/,g" ${index_js}
        sed -i "s,MODELER_SERVER_PORT,9090,g" ${index_js}

        source ${DAAS_HOME}/launch/application-utils.sh
        local app_name=$(get_application_name)
        local app_dir=$(get_application_directory)

        local git_repo_dir="${modeler_projects_dir}/${app_name}.git"
        if [ ! -d "${git_repo_dir}" ]; then
            pushd . &> /dev/null

            mkdir -p ${git_repo_dir}
            cd ${git_repo_dir}

            git config --global user.email "daas@kiegroup.org"
            git config --global user.name "DaaS"

            # init the repo
            git init --bare
            # add git hook
            cat <<EOF > hooks/post-receive
#!/bin/sh

unset GIT_INDEX_FILE
export GIT_WORK_TREE="${app_dir}/src/main/resources/"
export GIT_DIR="${git_repo_dir}"
git checkout -f

# source ${DAAS_HOME}/launch/application-utils.sh
# replace_application_xmlns_in_dir ${app_dir}/src/main/resources
EOF
            chmod 775 hooks/post-receive

            # we need to add at least one file to it
            local git_temp_dir="/tmp/git_${app_name}"
            git clone "${git_repo_dir}" "${git_temp_dir}"
            cd ${git_temp_dir}
            mkdir -p src/main/resources
            touch src/main/resources/.gitkeep
            git add src/main/resources/.gitkeep
            git commit -m 'Initial commit'
            git push
            cd ..
            rm -rf ${git_temp_dir}

            popd &> /dev/null
        fi
    fi
}