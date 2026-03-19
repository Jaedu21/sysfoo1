FROM jenkins/jenkins:2.541.3-jdk17

USER root

# Instalar dependencias adicionales
RUN apt-get update && apt-get install -y \
    curl \
    git \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Instalar Maven 3.9.6
    
ENV MAVEN_VERSION=3.9.6
ENV MAVEN_HOME=/opt/maven
ENV PATH=${MAVEN_HOME}/bin:${PATH}

RUN curl -fsSL https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz -o /tmp/maven.tar.gz \
    && tar -xzf /tmp/maven.tar.gz -C /opt \
    && mv /opt/apache-maven-${MAVEN_VERSION} ${MAVEN_HOME} \
    && rm /tmp/maven.tar.gz

# Verificar instalación de Maven
RUN mvn -version

# Volver al usuario jenkins
USER jenkins

# Habilitar wizard de configuración inicial para instalar plugins sugeridos
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=true"

# Nota: Durante el primer inicio, selecciona "Install suggested plugins"
# Esto instalará automáticamente todos los plugins necesarios de forma compatible
# 
# Plugins esenciales que se instalan automáticamente:
# ✅ Git plugin (para GitHub/GitLab)
# ✅ Pipeline plugins (workflow-aggregator)
# ✅ Maven Integration
# ✅ Credentials Binding
# ✅ SSH, Email, y más...
# 
# Plugins opcionales (instalar manualmente después si se necesitan):
# - Blue Ocean (interfaz moderna, requiere Jenkins > 2.479.3)
# - Docker Pipeline
# - SonarQube Scanner
# 
# Ver GUIA-PLUGINS.md para instalación manual de plugins adicionales
