# Mainly based on:
# https://github.com/diethardsteiner/diethardsteiner.github.io/tree/master/sample-files/pdi/docker-pdi

FROM java:8-jre

# Set required environment vars
# Using version 9 from Pentaho
ENV PDI_RELEASE=9.1 \
    PDI_VERSION=9.1.0.0-324 \
    CARTE_PORT=8181 \
    PENTAHO_JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
    PENTAHO_HOME=/home/pentaho

# Create user
RUN mkdir ${PENTAHO_HOME} && \
    groupadd -r pentaho && \
    useradd -s /bin/bash -d ${PENTAHO_HOME} -r -g pentaho pentaho && \
    chown pentaho:pentaho ${PENTAHO_HOME}

# Add files
RUN mkdir $PENTAHO_HOME/docker-entrypoint.d $PENTAHO_HOME/templates $PENTAHO_HOME/scripts

COPY carte-*.config.xml $PENTAHO_HOME/templates/

COPY docker-entrypoint.sh $PENTAHO_HOME/scripts/

RUN chown -R pentaho:pentaho $PENTAHO_HOME
 
RUN chmod +x $PENTAHO_HOME/templates/*.xml && \
    chmod +x $PENTAHO_HOME/scripts/docker-entrypoint.sh

# Switch to the pentaho user
USER pentaho

# Download PDI
RUN /usr/bin/wget \
    --progress=dot:giga \
    https://sourceforge.net/projects/pentaho/files/Pentaho%20${PDI_RELEASE}/client-tools/pdi-ce-${PDI_VERSION}.zip/download \
    -O /tmp/pdi-ce-${PDI_VERSION}.zip && \
    /usr/bin/unzip -q /tmp/pdi-ce-${PDI_VERSION}.zip -d  $PENTAHO_HOME && \
    rm /tmp/pdi-ce-${PDI_VERSION}.zip

# We can only add KETTLE_HOME to the PATH variable now
# as the path gets eveluated - so it must already exist
ENV KETTLE_HOME=$PENTAHO_HOME/data-integration \
    PATH=$KETTLE_HOME:$PATH

# Expose Carte Server
EXPOSE ${CARTE_PORT}

# As we cannot use env variable with the entrypoint and cmd instructions
# we set the working directory here to a convenient location
# We set it to KETTLE_HOME so we can start carte easily
WORKDIR $KETTLE_HOME

ENTRYPOINT ["../scripts/docker-entrypoint.sh"]

# Run Carte - these parameters are passed to the entrypoint
CMD ["carte.sh", "carte.config.xml"]
