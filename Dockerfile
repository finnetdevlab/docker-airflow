ARG ARG_PYTHON_VERSION=3.7-alpine3.11
FROM python:${ARG_PYTHON_VERSION} AS base

FROM base AS builder

# Install build dependencies
RUN apk add \
            --no-cache \
            --upgrade \
            --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
        alpine-sdk \
        libffi-dev \
        postgresql-dev

# Install Apache Airflow
ARG ARG_AIRFLOW_VERSION="1.10.9"
ARG ARG_AIRFLOW_DEPENDENCIES="crypto,celery,postgres,redis,jdbc,ssh,hive"
RUN pip install \
            --user \
            --no-cache-dir \
        apache-airflow[${ARG_AIRFLOW_DEPENDENCIES}]==${ARG_AIRFLOW_VERSION}

FROM base

ARG ARG_AIRFLOW_HOME="/home/airflow"
ENV AIRFLOW_HOME=${ARG_AIRFLOW_HOME}

# Add runtime packages
RUN apk add --no-cache \
            --upgrade \
            --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
        libpq && \
    adduser -D --home ${ARG_AIRFLOW_HOME} airflow

# Copy installed pip packages
COPY --from=builder --chown=airflow /root/.local /home/airflow/.local
ENV PATH=/home/airflow/.local/bin:$PATH

COPY config/airflow.cfg ${ARG_AIRFLOW_HOME}/airflow.cfg
COPY script/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080 5555 8793

USER airflow
WORKDIR ${ARG_AIRFLOW_HOME}
ENTRYPOINT ["/entrypoint.sh"]
CMD ["webserver"]