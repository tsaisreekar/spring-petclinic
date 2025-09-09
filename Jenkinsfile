pipeline {
    agent any

    tools {
        maven 'Maven3'      // Jenkins tool name for Maven
        jdk 'Java17'        // Jenkins tool name for JDK
    }

    environment {
        DOCKER_USER = 'tsaisreekar'  // Your Docker Hub username
        IMAGE_NAME = "${DOCKER_USER}/orders-app:latest"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/tsaisreekar/spring-petclinic.git'
            }
        }

        stage('Build & Test') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Docker Build & Push') {
            steps {
                sh "docker build -t ${IMAGE_NAME} ."
                withCredentials([string(credentialsId: 'dockerhub-pass', variable: 'DOCKER_PASS')]) {
                    sh "echo \$DOCKER_PASS | docker login -u ${DOCKER_USER} --password-stdin"
                    sh "docker push ${IMAGE_NAME}"
                    sh 'docker logout'
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh 'kubectl apply -f k8s/deployment.yaml'
                sh 'kubectl apply -f k8s/service.yaml'
            }
        }

        stage('Health Check') {
            steps {
                // Replace <K8s-Service-IP> with the external IP or LoadBalancer URL of your service
                sh 'curl -f http://35.166.171.0:8080 || exit 1'
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
