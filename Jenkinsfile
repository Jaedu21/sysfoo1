pipeline {
    agent any
    environment {
        APP_IMAGE = "sysfoo1:latest"
        // Definimos el perfil aquí para que sea fácil de cambiar si es necesario
        SPRING_PROFILES_ACTIVE = "prod"
    }

    stages {
        stage('Deploy with Profile and Env Vars') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'db-credentials', 
                                                 passwordVariable: 'DB_PASS', 
                                                 usernameVariable: 'DB_USER')]) {
                    
                    script {
                        echo "Desplegando sysfoo1 en modo: ${SPRING_PROFILES_ACTIVE}"
                        
                        // Detener contenedor previo si existe para evitar conflictos
                        sh "docker stop sysfoo-app || true && docker rm sysfoo-app || true"

                        // Ejecución inyectando el perfil y las credenciales
                        sh """
                        docker run -d \
                          --name sysfoo-app \
                          -e SPRING_PROFILES_ACTIVE=${SPRING_PROFILES_ACTIVE} \
                          -e SPRING_DATASOURCE_URL=jdbc:postgresql://db-prod:5432/sysfoo \
                          -e SPRING_DATASOURCE_USERNAME=${DB_USER} \
                          -e SPRING_DATASOURCE_PASSWORD=${DB_PASS} \
                          ${APP_IMAGE}
                        """
                    }
                }
            }
        }
    }
    environment {
        // Configuración de Docker
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_CREDENTIALS_ID = 'docker-hub-credentials'
        IMAGE_NAME = 'sysfoo-app'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        
        // Configuración de SonarQube
        SONAR_PROJECT_KEY = 'sysfoo'
        SONAR_HOST_URL = 'http://sonarqube:9000'
        
        // Configuración de Kubernetes
        KUBECONFIG_CREDENTIALS_ID = 'kubeconfig'
        K8S_NAMESPACE = 'sysfoo'
        
        // Configuración de Git
        GIT_REPO = 'https://github.com/Jaedu21/sysfoo1.git'
    }
    
    tools {
        maven 'Maven-3.9'
        jdk 'JDK-17'
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo 'Clonando repositorio...'
                    git branch: 'main',
                        url: "${GIT_REPO}"
                }
            }
        }
        
        stage('Build & Unit Tests') {
            steps {
                script {
                    echo 'Compilando aplicación y ejecutando tests unitarios...'
                    sh 'mvn clean compile test'
                }
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                    jacoco(
                        execPattern: '**/target/jacoco.exec',
                        classPattern: '**/target/classes',
                        sourcePattern: '**/src/main/java'
                    )
                }
            }
        }
        
        stage('Code Quality Analysis') {
            parallel {
                stage('SonarQube Analysis') {
                    steps {
                        script {
                            echo 'Analizando calidad de código con SonarQube...'
                            withSonarQubeEnv('SonarQube') {
                                sh '''
                                    mvn sonar:sonar \
                                    -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                                    -Dsonar.host.url=${SONAR_HOST_URL}
                                '''
                            }
                        }
                    }
                }
                
                stage('Dependency Check') {
                    steps {
                        script {
                            echo 'Verificando dependencias vulnerables...'
                            sh 'mvn dependency-check:check'
                        }
                    }
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                script {
                    echo 'Esperando resultado del Quality Gate...'
                    timeout(time: 5, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
        }
        
        stage('Package') {
            steps {
                script {
                    echo 'Empaquetando aplicación...'
                    sh 'mvn package -DskipTests'
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: '**/target/*.jar', fingerprint: true
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo 'Construyendo imagen Docker...'
                    dockerImage = docker.build("${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}")
                    docker.build("${DOCKER_REGISTRY}/${IMAGE_NAME}:latest")
                }
            }
        }
        
        stage('Security Scan - Trivy') {
            steps {
                script {
                    echo 'Escaneando imagen con Trivy...'
                    sh """
                        trivy image --severity HIGH,CRITICAL \
                        --exit-code 0 \
                        --format json \
                        --output trivy-report.json \
                        ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    """
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-report.json', allowEmptyArchive: true
                }
            }
        }
        
        stage('Push to Registry') {
            steps {
                script {
                    echo 'Publicando imagen en Docker Registry...'
                    docker.withRegistry("https://${DOCKER_REGISTRY}", "${DOCKER_CREDENTIALS_ID}") {
                        dockerImage.push("${IMAGE_TAG}")
                        dockerImage.push("latest")
                    }
                }
            }
        }
        
        stage('Deploy to Dev') {
            steps {
                script {
                    echo 'Desplegando en ambiente de desarrollo...'
                    withKubeConfig([credentialsId: "${KUBECONFIG_CREDENTIALS_ID}"]) {
                        sh """
                            kubectl set image deployment/sysfoo-app \
                            sysfoo-app=${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} \
                            -n ${K8S_NAMESPACE}-dev
                            
                            kubectl rollout status deployment/sysfoo-app \
                            -n ${K8S_NAMESPACE}-dev \
                            --timeout=5m
                        """
                    }
                }
            }
        }
        
        stage('Integration Tests') {
            steps {
                script {
                    echo 'Ejecutando tests de integración...'
                    sh 'mvn verify -DskipUnitTests'
                }
            }
            post {
                always {
                    junit '**/target/failsafe-reports/*.xml'
                }
            }
        }
        
        stage('Deploy to Staging') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo 'Desplegando en ambiente de staging...'
                    withKubeConfig([credentialsId: "${KUBECONFIG_CREDENTIALS_ID}"]) {
                        sh """
                            kubectl set image deployment/sysfoo-app \
                            sysfoo-app=${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} \
                            -n ${K8S_NAMESPACE}-staging
                            
                            kubectl rollout status deployment/sysfoo-app \
                            -n ${K8S_NAMESPACE}-staging \
                            --timeout=5m
                        """
                    }
                }
            }
        }
        
        stage('Approval for Production') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo 'Esperando aprobación para producción...'
                    input message: '¿Desplegar en producción?',
                          ok: 'Desplegar',
                          submitter: 'admin,devops-team'
                }
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo 'Desplegando en producción...'
                    withKubeConfig([credentialsId: "${KUBECONFIG_CREDENTIALS_ID}"]) {
                        sh """
                            # Actualizar imagen en ArgoCD
                            argocd app set sysfoo-prod \
                            --parameter image.tag=${IMAGE_TAG}
                            
                            # Sincronizar aplicación
                            argocd app sync sysfoo-prod
                            
                            # Esperar a que el despliegue complete
                            argocd app wait sysfoo-prod --timeout 600
                        """
                    }
                }
            }
        }
        
        stage('Smoke Tests') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo 'Ejecutando smoke tests en producción...'
                    sh '''
                        # Verificar que la aplicación responde
                        curl -f http://sysfoo-prod.example.com/actuator/health || exit 1
                        
                        # Verificar endpoint principal
                        curl -f http://sysfoo-prod.example.com/ || exit 1
                    '''
                }
            }
        }
    }
    
    post {
        always {
            echo 'Limpiando workspace...'
            cleanWs()
        }
        success {
            echo 'Pipeline ejecutado exitosamente!'
            emailext(
                subject: "SUCCESS: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: """
                    <p>Pipeline ejecutado exitosamente!</p>
                    <p>Job: ${env.JOB_NAME}</p>
                    <p>Build Number: ${env.BUILD_NUMBER}</p>
                    <p>Build URL: ${env.BUILD_URL}</p>
                """,
                to: 'devops-team@example.com'
            )
        }
        failure {
            echo 'Pipeline falló!'
            emailext(
                subject: "FAILURE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: """
                    <p>Pipeline falló!</p>
                    <p>Job: ${env.JOB_NAME}</p>
                    <p>Build Number: ${env.BUILD_NUMBER}</p>
                    <p>Build URL: ${env.BUILD_URL}</p>
                    <p>Por favor revisa los logs.</p>
                """,
                to: 'devops-team@example.com'
            )
        }
    }
}
