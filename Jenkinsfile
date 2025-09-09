pipeline {
  agent any

  environment {
    DOCKERHUB_CRED = 'dockerhub-creds'
    DOCKERHUB_USER = 'evanjali1468'
    DEV_REPO = "${DOCKERHUB_USER}/dev"
    PROD_REPO = "${DOCKERHUB_USER}/prod"
    DEPLOY_USER = 'ubuntu'
    DEPLOY_HOST = '13.201.92.185'      // <-- change to your Elastic IP if different
    DEPLOY_SSH_CRED = 'ec2-ssh-key'
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
          BR = env.BRANCH_NAME ?: 'dev'
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
        // ensure docker is available in the agent/container
        sh "docker build -t ${IMAGE} ."
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

    stage('Deploy to EC2 (main only)') {
      when {
        anyOf { branch 'main'; branch 'master' }
      }
      steps {
        // this uses sshUserPrivateKey to create a temporary key file available as $SSH_KEYFILE
        withCredentials([sshUserPrivateKey(credentialsId: env.DEPLOY_SSH_CRED, keyFileVariable: 'SSH_KEYFILE', usernameVariable: 'SSH_USER')]) {
          sh """
            chmod +x ./deploy.sh
            # copy deploy script
            scp -o StrictHostKeyChecking=no -i \$SSH_KEYFILE ./deploy.sh ${DEPLOY_USER}@${DEPLOY_HOST}:/tmp/deploy.sh
            # run deploy script remotely passing image & container name
            ssh -o StrictHostKeyChecking=no -i \$SSH_KEYFILE ${DEPLOY_USER}@${DEPLOY_HOST} 'bash -xe /tmp/deploy.sh ${IMAGE} ${APP_CONTAINER_NAME}'
          """.stripIndent()
        }
      }
    }
  }

  post {
    success { echo "✅ Pipeline succeeded for branch ${BR}" }
    failure { echo "❌ Pipeline failed for branch ${BR}" }
  }
}

