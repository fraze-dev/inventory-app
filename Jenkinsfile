pipeline {
    agent any

    environment {
        DOCKERHUB_CREDS  = credentials('dockerhub-creds')
        APP_SERVER_IP    = credentials('app-server-ip')
        IMAGE_NAME       = "frazedcoker/inventory-app"
        IMAGE_TAG        = "build-${env.BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                echo "Checking out branch: ${env.GIT_BRANCH}"
                echo "Commit: ${env.GIT_COMMIT}"
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo "Building Docker image ${IMAGE_NAME}:${IMAGE_TAG}"
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:latest ./app"
            }
        }

        stage('Verify') {
            steps {
                echo "Running container smoke test"
                sh """
                    docker run -d --name test-container -p 5001:5000 \
                        -e MONGO_URI=mongodb://dummy:27017 \
                        ${IMAGE_NAME}:${IMAGE_TAG}
                    sleep 5
                    docker ps | grep test-container
                    docker stop test-container
                    docker rm test-container
                """
            }
        }

        stage('Deploy') {
            steps {
                echo "Pushing image to Docker Hub"
                sh """
                    echo ${DOCKERHUB_CREDS_PSW} | docker login -u ${DOCKERHUB_CREDS_USR} --password-stdin
                    docker push ${IMAGE_NAME}:${IMAGE_TAG}
                    docker push ${IMAGE_NAME}:latest
                """

                echo "Deploying to app server ${APP_SERVER_IP}"
                sshagent(['app-server-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ec2-user@${APP_SERVER_IP} '
                            docker pull frazedcoker/inventory-app:latest
                            docker stop inventory-app || true
                            docker rm inventory-app || true
                            docker run -d \
                                --name inventory-app \
                                --restart always \
                                -p 5000:5000 \
                                -e MONGO_URI="mongodb://admin:ChangeMe123@172.31.83.68:27017/?authSource=admin" \
                                frazedcoker/inventory-app:latest
                        '
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline succeeded — app deployed to http://${APP_SERVER_IP}:5000"
        }
        failure {
            echo "Pipeline failed — check logs above"
        }
    }
}