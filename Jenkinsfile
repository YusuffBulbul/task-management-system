pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
        timestamps()
    }

    parameters {
        choice(
            name: 'DEPLOY_ENV',
            choices: ['dev', 'test', 'prod'],
            description: 'Helm yapılandırmasının çalıştırılacağı ortam'
        )
    }

    environment {
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_NAMESPACE = 'yusuffbulbul'
        IMAGE_TAG = "1.0.${BUILD_NUMBER}"
        HELM_CHART_PATH = 'helm/task-management'
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

        stage('Configure Environment') {
            steps {
                script {
                    switch (params.DEPLOY_ENV) {
                        case 'dev':
                            env.OPENSHIFT_NAMESPACE = 'yusuffbulbul-dev'
                            env.HELM_RELEASE_NAME = 'task-management'
                            env.HELM_VALUES_FILE =
                                'helm/task-management/values-dev.yaml'
                            env.DEPLOY_ENABLED = 'true'
                            break

                        case 'test':
                            env.OPENSHIFT_NAMESPACE = 'yusuffbulbul-test'
                            env.HELM_RELEASE_NAME = 'task-management-test'
                            env.HELM_VALUES_FILE =
                                'helm/task-management/values-test.yaml'
                            env.DEPLOY_ENABLED = 'false'
                            break

                        case 'prod':
                            env.OPENSHIFT_NAMESPACE = 'yusuffbulbul-prod'
                            env.HELM_RELEASE_NAME = 'task-management-prod'
                            env.HELM_VALUES_FILE =
                                'helm/task-management/values-prod.yaml'
                            env.DEPLOY_ENABLED = 'false'
                            break

                        default:
                            error(
                                "Unsupported environment: ${params.DEPLOY_ENV}"
                            )
                    }

                    echo """
                        Selected environment: ${params.DEPLOY_ENV}
                        Helm values file: ${env.HELM_VALUES_FILE}
                        Target namespace: ${env.OPENSHIFT_NAMESPACE}
                        Deployment enabled: ${env.DEPLOY_ENABLED}
                    """
                }
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

        stage('Auth Service Test') {
            steps {
                dir('auth-service') {
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

        stage('Validate Helm Chart') {
            steps {
                sh '''
                    helm lint "${HELM_CHART_PATH}" \
                      --values "${HELM_VALUES_FILE}" \
                      --set-string global.imageTag="${IMAGE_TAG}"

                    helm template "${HELM_RELEASE_NAME}" \
                      "${HELM_CHART_PATH}" \
                      --namespace "${OPENSHIFT_NAMESPACE}" \
                      --values "${HELM_VALUES_FILE}" \
                      --set-string global.imageTag="${IMAGE_TAG}" \
                      > task-management-rendered.yaml

                    echo "Helm ${DEPLOY_ENV} profile validation completed successfully."
                '''
            }
        }

        stage('Build Task Service Image') {
            when {
                expression {
                    env.DEPLOY_ENABLED == 'true'
                }
            }
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
            when {
                expression {
                    env.DEPLOY_ENABLED == 'true'
                }
            }
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
            when {
                expression {
                    env.DEPLOY_ENABLED == 'true'
                }
            }
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
            when {
                expression {
                    env.DEPLOY_ENABLED == 'true'
                }
            }
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

        stage('Build Auth Service Image') {
            when {
                expression {
                    env.DEPLOY_ENABLED == 'true'
                }
            }
            steps {
                sh '''
                    docker build \
                      --load \
                      --file auth-service/Containerfile \
                      --tag ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/auth-service:${IMAGE_TAG} \
                      auth-service
                '''
            }
        }

        stage('Build Frontend Image') {
            when {
                expression {
                    env.DEPLOY_ENABLED == 'true'
                }
            }
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
            when {
                expression {
                    env.DEPLOY_ENABLED == 'true'
                }
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKERHUB_USERNAME',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    )
                ]) {
                    sh '''
                        set +x
                        printf '%s' "$DOCKERHUB_TOKEN" |
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
                          ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/auth-service:${IMAGE_TAG}

                        docker push \
                          ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/task-management-frontend:${IMAGE_TAG}
                    '''
                }
            }
        }

        stage('Deploy to OpenShift with Helm') {
            when {
                expression {
                    env.DEPLOY_ENABLED == 'true'
                }
            }
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
                        set +x
                        oc login \
                          --server="$OPENSHIFT_SERVER" \
                          --token="$OPENSHIFT_TOKEN"

                        oc project "$OPENSHIFT_NAMESPACE"

                        # Read only the rendered Secret reference, never Secret data.
                        helm template "$HELM_RELEASE_NAME" "$HELM_CHART_PATH" \
                          --namespace "$OPENSHIFT_NAMESPACE" \
                          --values "$HELM_VALUES_FILE" \
                          --set-string global.imageTag="$IMAGE_TAG" \
                          --show-only templates/auth-service.yaml \
                          > auth-service-rendered.yaml

                        JWT_REFERENCE=$(oc create --dry-run=client --validate=false \
                          --namespace "$OPENSHIFT_NAMESPACE" \
                          --filename auth-service-rendered.yaml \
                          -o go-template='{{if eq .kind "Deployment"}}{{range .spec.template.spec.containers}}{{range .env}}{{if eq .name "JWT_SECRET"}}{{.valueFrom.secretKeyRef.name}}:{{.valueFrom.secretKeyRef.key}}{{end}}{{end}}{{end}}{{end}}')
                        JWT_SECRET_NAME=${JWT_REFERENCE%:*}
                        JWT_SECRET_KEY=${JWT_REFERENCE#*:}

                        if [ -z "$JWT_SECRET_NAME" ] || [ "$JWT_SECRET_KEY" != 'JWT_SECRET' ]; then
                            echo "ERROR: $HELM_VALUES_FILE must define an existing JWT Secret with key JWT_SECRET." >&2
                            exit 1
                        fi

                        # The Go template compares key names and emits only a fixed marker.
                        if ! JWT_KEY_PRESENT=$(oc get secret "$JWT_SECRET_NAME" \
                          --namespace "$OPENSHIFT_NAMESPACE" \
                          -o go-template='{{range $key, $ignored := .data}}{{if eq $key "JWT_SECRET"}}present{{end}}{{end}}'); then
                            echo "ERROR: JWT Secret '$JWT_SECRET_NAME' is missing or inaccessible in namespace '$OPENSHIFT_NAMESPACE'. Create it with key JWT_SECRET and grant the deployer permission to get it before deployment." >&2
                            exit 1
                        fi

                        if [ "$JWT_KEY_PRESENT" != 'present' ]; then
                            echo "ERROR: JWT Secret '$JWT_SECRET_NAME' in namespace '$OPENSHIFT_NAMESPACE' is missing key JWT_SECRET. Add the key before deployment." >&2
                            exit 1
                        fi

                        helm upgrade --install "$HELM_RELEASE_NAME" \
                          "$HELM_CHART_PATH" \
                          --namespace "$OPENSHIFT_NAMESPACE" \
                          --values "$HELM_VALUES_FILE" \
                          --set-string global.imageTag="$IMAGE_TAG" \
                          --take-ownership \
                          --wait \
                          --wait-for-jobs \
                          --timeout 15m

                        oc rollout status deployment/auth-service \
                          --namespace "$OPENSHIFT_NAMESPACE" \
                          --timeout=5m

                        echo "Helm deployment completed successfully."

                        helm status "$HELM_RELEASE_NAME" \
                          --namespace "$OPENSHIFT_NAMESPACE"

                        oc get deployments \
                          --namespace "$OPENSHIFT_NAMESPACE"

                        oc get pods \
                          --namespace "$OPENSHIFT_NAMESPACE"

                        oc get jobs \
                          --namespace "$OPENSHIFT_NAMESPACE"

                        oc get routes \
                          --namespace "$OPENSHIFT_NAMESPACE"
                    '''
                }
            }
        }
    }

    post {
        success {
            script {
                echo """
                    Pipeline completed successfully.

                    Selected environment:
                    ${params.DEPLOY_ENV}

                    Helm release:
                    ${env.HELM_RELEASE_NAME}

                    Helm values profile:
                    ${env.HELM_VALUES_FILE}

                    Target namespace:
                    ${env.OPENSHIFT_NAMESPACE}

                    Deployment enabled:
                    ${env.DEPLOY_ENABLED}

                    Image version:
                    ${env.IMAGE_TAG}
                """

                if (env.DEPLOY_ENABLED == 'true') {
                    echo """
                        Docker Hub images:
                        ${env.DOCKER_REGISTRY}/${env.DOCKER_NAMESPACE}/task-service:${env.IMAGE_TAG}
                        ${env.DOCKER_REGISTRY}/${env.DOCKER_NAMESPACE}/notification-service:${env.IMAGE_TAG}
                        ${env.DOCKER_REGISTRY}/${env.DOCKER_NAMESPACE}/analytics-service:${env.IMAGE_TAG}
                        ${env.DOCKER_REGISTRY}/${env.DOCKER_NAMESPACE}/api-gateway:${env.IMAGE_TAG}
                        ${env.DOCKER_REGISTRY}/${env.DOCKER_NAMESPACE}/auth-service:${env.IMAGE_TAG}
                        ${env.DOCKER_REGISTRY}/${env.DOCKER_NAMESPACE}/task-management-frontend:${env.IMAGE_TAG}

                        OpenShift deployment:
                        Completed successfully.
                    """
                } else {
                    echo """
                        Validation-only mode completed.

                        Images were not built or pushed.
                        OpenShift deployment was not performed because
                        a separate ${params.DEPLOY_ENV} namespace is not available.
                    """
                }
            }
        }

        failure {
            echo """
                Pipeline failed.

                Selected environment:
                ${params.DEPLOY_ENV}

                Check the failed Jenkins stage and its console logs.
                If OpenShift login failed, renew the openshift-token credential.
            """
        }

        always {
            sh '''
                docker logout "$DOCKER_REGISTRY" >/dev/null 2>&1 || true
                oc logout >/dev/null 2>&1 || true
            '''

            deleteDir()
        }
    }
}
