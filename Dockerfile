FROM thecatlady/webhook:latest

## create user to run app in non-root mode
# custom name and uid for app user
ARG USERNAME="app"
# adjust ID numbers to match host run user
ARG USER_ID=1000
ARG GROUP_ID=1000

RUN addgroup -g ${GROUP_ID} ${USERNAME} && \
    adduser -D -u ${USER_ID} -G ${USERNAME} ${USERNAME}

RUN apk add --update --no-cache skopeo

RUN chown --changes --silent --no-dereference --recursive \
    ${USERNAME}:${USERNAME} \
    /config

# Set the default user
USER ${USERNAME}

VOLUME /config
WORKDIR /config

LABEL org.opencontainers.image.authors="https://github.com/tomdess"
