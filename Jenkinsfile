pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        // Replace with your real JFrog registry later
        JFROG_REGISTRY = 'acme.jfrog.io'
        JFROG_REPO = 'docker-local'
        IMAGE_NAME = 'github-runner'
        AWS_DEFAULT_REGION = 'ap-south-1'
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

                    docker build --pull \
                      -t ${JFROG_REGISTRY}/${JFROG_REPO}/${IMAGE_NAME}:${IMAGE_TAG} .
                '''
            }
        }

        stage('Login and Push to JFrog') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-platform-creds'
                ]]) {
                    sh '''
                        set -euo pipefail

                        source build.env

                        SECRET_JSON=$(aws secretsmanager get-secret-value \
                          --secret-id cicd/jfrog/docker-push \
                          --query SecretString \
                          --output text)

                        JFROG_USER=$(echo "${SECRET_JSON}" | jq -r '.username')
                        JFROG_TOKEN=$(echo "${SECRET_JSON}" | jq -r '.token')

                        echo "${JFROG_TOKEN}" | docker login "${JFROG_REGISTRY}" \
                          --username "${JFROG_USER}" \
                          --password-stdin

                        docker push ${JFROG_REGISTRY}/${JFROG_REPO}/${IMAGE_NAME}:${IMAGE_TAG}

                        echo "Runner image pushed:"
                        echo "${JFROG_REGISTRY}/${JFROG_REPO}/${IMAGE_NAME}:${IMAGE_TAG}"
                    '''
                }
            }
        }
    }
}
