pipeline {
  agent any
  environment {
    DOCKERHUB_CRED = 'dockerhub-cred'          // set in Jenkins
    DOCKER_IMAGE = 'tsaisreekar/spring-petclinic'  // replace before pushing or set env in Jenkins
    APP_SSH_CRED = 'app-server-ssh'            // Jenkins credential ID for SSH
    APP_HOST = 'ubuntu@44.252.99.35'               // replace with your app-server public IP
  }
  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }
    stage('Build JAR') {
      steps {
        sh '''
          if [ -f mvnw ]; then
            chmod +x ./mvnw
            ./mvnw -B -DskipTests clean package
          else
            mvn -B -DskipTests clean package
          fi
        '''
      }
    }
    stage('Build Docker image') {
      steps {
        sh "docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} ."
      }
    }
    stage('Push to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: "${env.DOCKERHUB_CRED}", usernameVariable: 'DU', passwordVariable: 'DP')]) {
          sh '''
            echo "$DP" | docker login -u "$DU" --password-stdin
            docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
            docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_IMAGE}:latest
            docker push ${DOCKER_IMAGE}:latest
          '''
        }
      }
    }
    stage('Deploy to minikube on app-server') {
      steps {
        sshagent (credentials: ["${env.APP_SSH_CRED}"]) {
          sh """
            ssh -o StrictHostKeyChecking=no ${APP_HOST} '
              set -e
              # ensure kubectl context is minikube on app-server
              kubectl -n default get deploy || true
              # update image
              kubectl set image deployment/petclinic petclinic=${DOCKER_IMAGE}:latest --record || true
              # if deployment doesn't exist, apply manifests
              if ! kubectl get deploy petclinic >/dev/null 2>&1; then
                # replace placeholder in manifest and apply
                sed -i \"s|DOCKERHUB_USER/petclinic:latest|${DOCKER_IMAGE}:latest|g\" /home/ubuntu/k8s/deployment.yaml || true
                kubectl apply -f /home/ubuntu/k8s/deployment.yaml
                kubectl apply -f /home/ubuntu/k8s/service-nodeport.yaml
              fi
            '
          """
        }
      }
    }
}
