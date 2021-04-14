FROM quay.io/fundingcircle/alpine-ruby-builder:2.5 as builder

RUN apk --no-cache add \
  cmake \
  nodejs \
  sqlite-dev \
  libgit2-dev \
  libssh2-dev

WORKDIR /tmp
COPY Gemfile* ./
RUN bundle config build.rugged --use-system-libraries \
 && bundle install --deployment --without dockerignore development test

ARG RAILS_ENV=production

COPY Rakefile ./
COPY lib/tasks/env.rake lib/tasks/
COPY lib/prometheus_client.rb lib/

COPY \
 config/application.rb \
 config/boot.rb \
 config/environment.rb \
 config/

COPY config/environments/production.rb config/environments/

COPY app/assets app/assets
COPY vendor/assets vendor/assets
COPY .env.assets .

RUN bundle exec rake assets:precompile

FROM quay.io/fundingcircle/alpine-ruby:2.5
LABEL maintainer="Funding Circle Engineering <engineering@fundingcircle.com>"

RUN apk --no-cache add \
  nodejs \
  postgresql-client \
  sqlite-dev \
  tzdata \
  zlib \
  libgit2 \
  libssh2

RUN addgroup -g 1101 -S shipment_tracker && \
  adduser -S -u 1101 -h /app -G shipment_tracker shipment_tracker

USER root

WORKDIR /app

COPY --from=builder --chown=shipment_tracker:shipment_tracker /tmp .
COPY --chown=shipment_tracker:shipment_tracker docker/entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY --chown=shipment_tracker:shipment_tracker dropzone.yaml /usr/local/deploy/dropzone.yaml
COPY --chown=shipment_tracker:shipment_tracker . .

ENTRYPOINT ["/sbin/tini", "--", "docker-entrypoint.sh"]

ARG REVISION=unknown
ENV REVISION=$REVISION
ARG NAME=shipment_tracker
ARG SOURCE=https://github.com/FundingCircle/shipment_tracker
ARG URL
ARG CREATED
ARG MANAGER
LABEL name=$NAME version=$REVISION
LABEL org.opencontainers.image.url=$URL
LABEL org.opencontainers.image.source=$SOURCE
LABEL org.opencontainers.image.created=$CREATED
LABEL org.opencontainers.image.revision=$REVISION
LABEL org.fundingcircle.image.manager=$MANAGER
RUN echo "$REVISION" > REVISION
