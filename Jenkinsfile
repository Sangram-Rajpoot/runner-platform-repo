pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        JFROG_REGISTRY = 'jfrogtrial2166.jfrog.io'
        JFROG_REPO = 'docker-local'
        IMAGE_NAME = 'github-runner'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Runner Image') {
            steps {
                sh '''
                    set -euo pipefail

                    SHORT_SHA=$(git rev-parse --short=8 HEAD)
                    IMAGE_TAG="${BUILD_NUMBER}-${SHORT_SHA}"

                    echo "IMAGE_TAG=${IMAGE_TAG}" > build.env
                    echo "FULL_IMAGE=${JFROG_REGISTRY}/${JFROG_REPO}/${IMAGE_NAME}:${IMAGE_TAG}" >> build.env

                    docker build --pull \
                      -t ${JFROG_REGISTRY}/${JFROG_REPO}/${IMAGE_NAME}:${IMAGE_TAG} .
                '''
            }
        }

        stage('Login to JFrog') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'jfrog-docker-creds',
                    usernameVariable: 'JFROG_USERNAME',
                    passwordVariable: 'JFROG_TOKEN'
                )]) {
                    sh '''
                        set -euo pipefail

                        echo "${JFROG_TOKEN}" | docker login "${JFROG_REGISTRY}" \
                          --username "${JFROG_USERNAME}" \
                          --password-stdin
                    '''
                }
            }
        }

       stage('Push Runner Image') {
    steps {
        sh '''
            set -eu
            . ./build.env

            docker push "${FULL_IMAGE}"

            echo "Runner image pushed:"
            echo "${FULL_IMAGE}"
        '''
    }
}
    }

    post {
        always {
            sh '''
                docker logout "${JFROG_REGISTRY}" || true
            '''
        }
    }
}
