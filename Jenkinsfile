pipeline { 
    agent any
    environment { 
        BRANCH = 'main' 
    } 
    stages { 
        stage('Checkout') { 
            steps { 
                checkout([$class: 'GitSCM', branches: [[name: "${BRANCH}"]], extensions: [[$class: 'CleanBeforeCheckout', deleteUntrackedNestedRepositories: true]],  
                userRemoteConfigs: [[credentialsId: 'DemoDeployDotnetCore',  
                url: 'https://github.com/giao5fs/DemoDeployDotnetCore.git']]]) 
            }   
        } 
        stage('Build') { 
            steps { 
                sh "dotnet restore"
                sh "dotnet build"
                sh "dotnet publish"
                sh """
                    echo "Remove zip file... in Jenkins"
                    rm -Rf publish.zip
                    zip -r publish.zip bin/Debug/net6.0/publish/
                """
            } 
        } 
        stage('Deploy WebServer-1') { 
            steps { 
                sh """
                    scp -i /home/jenkins/webserver1.pem publish.zip jenkins@3.219.237.254:/home/jenkins/
                    echo "Login to WebServer-1..."
                    ssh -T -i /home/jenkins/webserver1.pem jenkins@3.219.237.254 '
                    rm -Rf DemoDeployDotnetCore
                    unzip publish.zip
                    cp -Rf bin/Debug/net6.0/publish/ DemoDeployDotnetCore
                    rm -Rf publish.zip
                    rm -Rf bin
                    sudo service webapp restart
                    sudo service webapp status
                    exit'
                """
            } 
        }   
        stage('Deploy WebServer-2') { 
            steps { 
                sh """
                    scp -i /home/jenkins/webserver2.pem publish.zip jenkins@44.193.226.49:/home/jenkins/
                    echo "Login to WebServer-2..."
                    ssh -T -i /home/jenkins/webserver2.pem jenkins@44.193.226.49 '
                    rm -Rf DemoDeployDotnetCore
                    unzip publish.zip
                    cp -Rf bin/Debug/net6.0/publish/ DemoDeployDotnetCore
                    rm -Rf publish.zip
                    rm -Rf bin
                    sudo service webapp restart
                    sudo service webapp status'
                """
            } 
        }   
    } 
} 