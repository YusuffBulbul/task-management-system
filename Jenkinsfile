pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
        timestamps()
    }

    environment {
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_NAMESPACE = 'yusuffbulbul'
        IMAGE_NAME = 'task-service'
        IMAGE_TAG = "1.0.${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/YusuffBulbul/task-management-system.git',
                        credentialsId: 'github-pat'
                    ]],
                    extensions: [[
                        $class: 'SubmoduleOption',
                        disableSubmodules: false,
                        parentCredentials: true,
                        recursiveSubmodules: true,
                        trackingSubmodules: false
                    ]]
                ])
            }
        }

        stage('Task Service Test') {
            steps {
                dir('task-service') {
                    sh '''
                        mvn clean test \
                          -Dspring.kafka.listener.auto-startup=false
                    '''
                }
            }
        }

        stage('Build Task Service Image') {
            steps {
                sh '''
                    docker build \
                      --load \
                      --file task-service/Containerfile \
                      --tag ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/${IMAGE_NAME}:${IMAGE_TAG} \
                      task-service
                '''
            }
        }

        stage('Push Task Service Image') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKERHUB_USERNAME',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    )
                ]) {
                    sh '''
                        echo "$DOCKERHUB_TOKEN" |
                          docker login "$DOCKER_REGISTRY" \
                            --username "$DOCKERHUB_USERNAME" \
                            --password-stdin

                        docker push \
                          ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/${IMAGE_NAME}:${IMAGE_TAG}
                    '''
                }
            }
        }
    }

    post {
        success {
            echo """
                Task Service image successfully pushed:
                ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/${IMAGE_NAME}:${IMAGE_TAG}
            """
        }

        failure {
            echo 'Pipeline failed. Check the failed stage logs.'
        }

        always {
            sh '''
                docker logout "$DOCKER_REGISTRY" || true
            '''

            deleteDir()
        }
    }
}