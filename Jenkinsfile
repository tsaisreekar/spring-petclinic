pipeline {
    agent any

    tools {
        jdk 'Java17'
        maven 'Maven3'
    }

    environment {
        DOCKERHUB_CRED = 'dockerhub-cred'
        DOCKER_IMAGE = 'tsaisreekar/spring-petclinic'
        APP_SSH_CRED = 'app-server-ssh'  // Jenkins SSH credential with OpenSSH key
        APP_HOST = 'ubuntu@44.252.99.35'
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

        stage('Build Docker Image') {
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

       stage('Deploy to EKS Cluster') {
              steps {
                sshagent (credentials: ['app-server-ssh']) {
                  sh """
                  ssh -o StrictHostKeyChecking=no ${APP_HOST} '
                  set -e
            
                  # Install git if not present
                  which git || sudo apt-get update && sudo apt-get install -y git
            
                  # Clone (or pull) your repo with k8s manifests
                  if [ ! -d ~/spring-petclinic ]; then
                    git clone https://github.com/tsaisreekar/spring-petclinic.git ~/spring-petclinic
                  else
                    cd ~/spring-petclinic && git pull
                  fi
            
                  # Ensure kubeconfig is set for EKS
                  mkdir -p ~/.kube
                  aws eks --region ${AWS_REGION} update-kubeconfig --name ${EKS_CLUSTER_NAME} --kubeconfig ~/.kube/config
            
                  export KUBECONFIG=$HOME/.kube/config
            
                  # Update image in existing deployment
                  kubectl -n default get deploy petclinic >/dev/null 2>&1 && \
                  kubectl set image deployment/petclinic petclinic=${DOCKER_IMAGE}:latest --record || true
            
                  # If deployment doesn’t exist, apply manifests
                  if ! kubectl get deploy petclinic >/dev/null 2>&1; then
                    kubectl apply -f ~/spring-petclinic/k8s/deployment.yaml
                    kubectl apply -f ~/spring-petclinic/k8s/service-loadbalancer.yaml
                  fi
                  '
                  """
                }
              }
}


        stage('Smoke Test') {
            steps {
                echo "Waiting 15s for pods to stabilize..."
                sleep 15
                sshagent([env.APP_SSH_CRED]) {
                    sh "ssh -o StrictHostKeyChecking=no ${APP_HOST} 'curl -sS http://localhost:30080/actuator/health || true'"
                }
            }
        }

        stage('Health Check') {
            steps {
                echo "Checking service availability via NodePort..."
                sshagent([env.APP_SSH_CRED]) {
                    sh "ssh -o StrictHostKeyChecking=no ${APP_HOST} 'curl -f http://localhost:30080 || exit 1'"
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully."
        }
        failure {
            echo "Pipeline failed - check console logs."
        }
    }
}
