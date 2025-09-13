Application Deployment

This project is about deploying a given ReactJS application into a production-ready state using Docker, Jenkins, AWS, and monitoring tools. Below are the detailed steps I followed.

1. Application

I cloned the given repo for the ReactJS application.

git clone https://github.com/sriram-R-krishnan/devops-build
cd devops-build


I deployed the application to run on port 80.

2. Docker

I created a Dockerfile using Nginx to serve the React build.

I created a docker-compose.yml file to manage the container.

Example commands:

docker build -t react-app .
docker run -d -p 80:80 react-app

3. Bash Scripting

I wrote two scripts:

build.sh
deploy.sh

I made them executable:

chmod +x build.sh deploy.sh

4. Version Control

I initialized a new GitHub repo:

git init
git remote add origin https://github.com/Evanjalicloud1/Reactjs-E-commerce-Application
I added .gitignore and .dockerignore to ignore unnecessary files.

I pushed the code to the dev branch using CLI only:

git checkout -b dev
git add .
git commit -m "initial commit with docker, scripts"
git push origin dev

5. Docker Hub

I created two repositories in Docker Hub:

evanjali1468/dev (public)

evanjali1468/prod (private)

Dev images are pushed automatically from the dev branch.

Prod images are pushed when I merge dev → main.

6. Jenkins

I installed and configured Jenkins on AWS EC2.

I set up a Multibranch Pipeline connected to my GitHub repo using PAT (Personal Access Token).

I configured pipeline stages in Jenkinsfile:

Build → build Docker image

Push → push image to Docker Hub

Deploy → deploy to container on port 80

Verify → check container is running

Branch rules:

On dev branch push → image goes to evanjali1468/dev:latest

On main branch merge → image goes to evanjali1468/prod:latest
Example:

Dev pipeline succeeded  → evanjali1468/dev:latest pushed
Main pipeline succeeded  → evanjali1468/prod:latest pushed

7. AWS

I launched a t3.medium EC2 instance (Ubuntu).

I installed Docker & Jenkins inside the instance.

I deployed the app container to run on port 80.

I configured Security Groups:

Allowed inbound HTTP (80) from anywhere.

Allowed inbound SSH (22) only from my IP.

8. Monitoring

I set up Uptime Kuma (open-source monitoring tool).

I used Docker to run Uptime Kuma:

docker run -d --restart=always -p 3001:3001 --name uptime-kuma louislam/uptime-kuma

I added a monitor for my deployed app URL:

http://13.235.212.210

It checks every 60 seconds.

It sends me an alert if the site goes down.

9. Submission

Repo URL
https://github.com/Evanjalicloud1/Reactjs-E-commerce-Application

Deployed Site URL
http://13.235.212.210

Docker Images

evanjali1468/dev:latest (Public)

evanjali1468/prod:latest (Private)

With these steps, I have deployed the given ReactJS application in a production-ready state with Docker, Jenkins, AWS, and monitoring.
   
