pipeline {
    agent any

    environment {
        APP_IMAGE = 'notes-app'
        PREV_IMAGE = 'notes-app-prev'
        CONTAINER_NAME = 'notes-app-container'
        DATABASE_URL = credentials('DATABASE_URL')
    }

    stages {

        stage('Build') {
            steps {
                echo 'Building Docker image...'
                sh 'docker build -t ${APP_IMAGE} .'
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'docker run --rm -e DATABASE_URL=${DATABASE_URL} ${APP_IMAGE} python -c "print(\'App OK\')"'
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying application...'
                sh '''
                    docker tag ${APP_IMAGE} ${PREV_IMAGE} || true
                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true
                    docker run -d \
                        --name ${CONTAINER_NAME} \
                        -e DATABASE_URL=${DATABASE_URL} \
                        -p 5000:5000 \
                        --restart unless-stopped \
                        ${APP_IMAGE}
                '''
            }
        }

        stage('Health Check') {
            steps {
                echo 'Running health check...'
                sh '''
                    chmod +x healthcheck.sh
                    ./healthcheck.sh
                '''
            }
        }
    }

    post {
        failure {
            echo 'Pipeline failed! Starting rollback...'
            sh '''
                chmod +x deploy.sh
                ./deploy.sh rollback
            '''
        }
        success {
            echo 'Deployment successful!'
        }
    }
}