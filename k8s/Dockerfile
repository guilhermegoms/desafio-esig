FROM tomcat:latest

# Copie o arquivo WAR do Jenkins
COPY jenkins.war /usr/local/tomcat/webapps/

# Instale o Jolokia
RUN apt-get update && apt-get install -y --no-install-recommends wget && rm -rf /var/lib/apt/lists/*
RUN wget https://search.maven.org/remotecontent?filepath=org/jolokia/jolokia-war/1.7.1/jolokia-war-1.7.1.war -O /usr/local/tomcat/webapps/jolokia.war

# Exponha a porta
EXPOSE 8080

# Comando para manter o Tomcat em execução
CMD ["catalina.sh", "run"]