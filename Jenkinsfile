pipeline {
  agent any

  environment {
    DOCKERHUB_CRED = 'dockerhub-creds'
    DOCKERHUB_USER = 'evanjali1468'
    APP_CONTAINER_NAME = 'react-ecom'
    TAG = 'latest'
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
          def BR = env.BRANCH_NAME ?: 'dev'
          def DEV_REPO = "${env.DOCKERHUB_USER}/dev"
          def PROD_REPO = "${env.DOCKERHUB_USER}/prod"
          def imageName = (BR ==~ /(?i)main|master/) ? "${PROD_REPO}:${env.TAG}" : "${DEV_REPO}:${env.TAG}"

          env.IMAGE = imageName
          env.BR = BR

          echo "Branch: ${BR} -> Image: ${env.IMAGE}"
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        sh "docker build -t ${env.IMAGE} ."
      }
    }

    stage('Push to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: env.DOCKERHUB_CRED, usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
          sh '''
            echo "$DH_PASS" | docker login --username "$DH_USER" --password-stdin
            docker push ${IMAGE}
          '''.stripIndent()
        }
      }
    }

    stage('Deploy (local)') {
      steps {
        // run the deploy script locally on the Jenkins host (make sure deploy.sh is executable)
        sh '''
          chmod +x ./deploy.sh
          ./deploy.sh ${IMAGE} ${APP_CONTAINER_NAME} 80:80
        '''.stripIndent()
      }
    }

    stage('Verify') {
      steps {
        // show container status
        sh "docker ps --filter name=${APP_CONTAINER_NAME} --format 'table {{.Names}}\\t{{.Image}}\\t{{.Status}}'"
      }
    }
  }

  post {
    success {
      echo "✅ Pipeline succeeded for branch ${env.BR} and image ${env.IMAGE}"
    }
    failure {
      echo "❌ Pipeline failed for branch ${env.BR} and image ${env.IMAGE}"
    }
  }
}
