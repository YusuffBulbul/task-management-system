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
        IMAGE_TAG = "1.0.${BUILD_NUMBER}"
        OPENSHIFT_NAMESPACE = 'yusuffbulbul-dev'
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

        stage('Notification Service Test') {
            steps {
                dir('notification-service') {
                    sh '''
                        mvn clean test \
                          -Dspring.kafka.listener.auto-startup=false
                    '''
                }
            }
        }

        stage('Analytics Service Test') {
            steps {
                dir('analytics-service') {
                    sh '''
                        mvn clean test \
                          -Dspring.kafka.listener.auto-startup=false
                    '''
                }
            }
        }

        stage('API Gateway Test') {
            steps {
                dir('api-gateway') {
                    sh 'mvn clean test'
                }
            }
        }

        stage('Frontend Test and Build') {
            steps {
                dir('frontend') {
                    sh '''
                        npm ci
                        npm run lint
                        npm run build
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
                      --tag ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/task-service:${IMAGE_TAG} \
                      task-service
                '''
            }
        }

        stage('Build Notification Service Image') {
            steps {
                sh '''
                    docker build \
                      --load \
                      --file notification-service/Containerfile \
                      --tag ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/notification-service:${IMAGE_TAG} \
                      notification-service
                '''
            }
        }

        stage('Build Analytics Service Image') {
            steps {
                sh '''
                    docker build \
                      --load \
                      --file analytics-service/Containerfile \
                      --tag ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/analytics-service:${IMAGE_TAG} \
                      analytics-service
                '''
            }
        }

        stage('Build API Gateway Image') {
            steps {
                sh '''
                    docker build \
                      --load \
                      --file api-gateway/Containerfile \
                      --tag ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/api-gateway:${IMAGE_TAG} \
                      api-gateway
                '''
            }
        }

        stage('Build Frontend Image') {
            steps {
                sh '''
                    docker build \
                      --load \
                      --file frontend/Containerfile \
                      --tag ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/task-management-frontend:${IMAGE_TAG} \
                      frontend
                '''
            }
        }

        stage('Push Images to Docker Hub') {
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
                          ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/task-service:${IMAGE_TAG}

                        docker push \
                          ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/notification-service:${IMAGE_TAG}

                        docker push \
                          ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/analytics-service:${IMAGE_TAG}

                        docker push \
                          ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/api-gateway:${IMAGE_TAG}

                        docker push \
                          ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/task-management-frontend:${IMAGE_TAG}
                    '''
                }
            }
        }

        stage('Deploy to OpenShift') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'openshift-token',
                        variable: 'OPENSHIFT_TOKEN'
                    ),
                    string(
                        credentialsId: 'openshift-server',
                        variable: 'OPENSHIFT_SERVER'
                    )
                ]) {
                    sh '''
                        oc login \
                          --server="$OPENSHIFT_SERVER" \
                          --token="$OPENSHIFT_TOKEN"

                        oc project "$OPENSHIFT_NAMESPACE"

                        oc set image deployment/task-service \
                          task-service=${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/task-service:${IMAGE_TAG}

                        oc set image deployment/notification-service \
                          notification-service=${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/notification-service:${IMAGE_TAG}

                        oc set image deployment/analytics-service \
                          analytics-service=${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/analytics-service:${IMAGE_TAG}

                        oc set image deployment/api-gateway \
                          api-gateway=${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/api-gateway:${IMAGE_TAG}

                        oc set image deployment/frontend \
                          frontend=${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/task-management-frontend:${IMAGE_TAG}

                        oc rollout status deployment/task-service \
                          --timeout=300s

                        oc rollout status deployment/notification-service \
                          --timeout=300s

                        oc rollout status deployment/analytics-service \
                          --timeout=300s

                        oc rollout status deployment/api-gateway \
                          --timeout=300s

                        oc rollout status deployment/frontend \
                          --timeout=300s
                    '''
                }
            }
        }
    }

    post {
        success {
            echo """
                CI/CD pipeline completed successfully.

                Version: ${IMAGE_TAG}

                Docker Hub images:
                ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/task-service:${IMAGE_TAG}
                ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/notification-service:${IMAGE_TAG}
                ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/analytics-service:${IMAGE_TAG}
                ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/api-gateway:${IMAGE_TAG}
                ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/task-management-frontend:${IMAGE_TAG}

                OpenShift project:
                ${OPENSHIFT_NAMESPACE}
            """
        }

        failure {
            echo 'Pipeline failed. Check the failed stage logs.'
        }

        always {
            sh '''
                docker logout "$DOCKER_REGISTRY" || true
                oc logout || true
            '''

            deleteDir()
        }
    }
}