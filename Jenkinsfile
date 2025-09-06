// Jenkinsfile - Multibranch Pipeline for React Ecom
// Required Jenkins credentials (IDs):
// - dockerhub-creds   : Docker Hub username/password
// - github-ssh-key    : GitHub SSH private key (for cloning) — configured in Branch Source
// - ec2-ssh-key       : EC2 SSH private key (for deployment)

pipeline {
  agent any

  environment {
    DOCKERHUB_CRED = 'dockerhub-creds'
    DOCKERHUB_USER = 'evanjali1468'
    DEV_REPO = "${DOCKERHUB_USER}/dev"
    PROD_REPO = "${DOCKERHUB_USER}/prod"
    DEPLOY_USER = 'ubuntu'              // change to ec2-user if using Amazon Linux
    DEPLOY_HOST = '13.201.92.185'       // your EC2 Public IP
    DEPLOY_SSH_CRED = 'ec2-ssh-key'
    APP_CONTAINER_NAME = 'react-ecom'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        sh 'ls -la'
      }
    }

    stage('Determine Image') {
      steps {
        script {
          BR = env.BRANCH_NAME ?: env.GIT_BRANCH ?: 'dev'
          TAG = "latest"
          if (BR ==~ /(?i)main|master/) {
            IMAGE = "${PROD_REPO}:${TAG}"
          } else {
            IMAGE = "${DEV_REPO}:${TAG}"
          }
          echo "Branch: ${BR} -> Image: ${IMAGE}"
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        sh "docker build -t ${IMAGE} ."
      }
    }

    stage('Push to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CRED}", usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
          sh '''
            echo "$DH_PASS" | docker login --username "$DH_USER" --password-stdin
          '''
          sh "docker push ${IMAGE}"
        }
      }
    }

    stage('Deploy to EC2 (only on main)') {
      when {
        anyOf {
          branch 'main'
          branch 'master'
        }
      }
      steps {
        sshagent (credentials: ["${DEPLOY_SSH_CRED}"]) {
          sh "scp -o StrictHostKeyChecking=no deploy.sh ${DEPLOY_USER}@${DEPLOY_HOST}:~/deploy.sh"
          sh "ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} 'chmod +x ~/deploy.sh && ~/deploy.sh ${IMAGE} ${APP_CONTAINER_NAME}'"
        }
      }
    }
  }

  post {
    success {
      echo "✅ Pipeline succeeded for branch ${BR}"
    }
    failure {
      echo "❌ Pipeline failed for branch ${BR}"
    }
  }
}
