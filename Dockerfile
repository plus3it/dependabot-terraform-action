FROM golang:1.14.2-buster AS golang

# "hack" to avoid having to re-host terraform-config-inspect and avoid dependence on the native dependabot-core terraform/helper script
# TODO: 
# terraform-config-inspect should probably be vendered
# https://stackoverflow.com/questions/30188499/how-to-do-go-get-on-a-specific-tag-of-a-github-repository
RUN apt-get install wget -y && \
mkdir tf_helpers && \
wget -O tf_helpers/json2hcl https://github.com/kvz/json2hcl/releases/download/v0.0.6/json2hcl_v0.0.6_linux_amd64 && \
wget -O tf_helpers/hcl2json https://github.com/tmccombs/hcl2json/releases/download/0.2.1/hcl2json_0.2.1_linux_amd64 && \
GO111MODULE=on go get -v github.com/hashicorp/terraform-config-inspect

FROM ruby:2.6.6-slim AS ruby

LABEL "maintainer"="Plus3IT" \
      "repository"="https://github.com/plus3it/dependabot-terraform-action" \
      "homepage"="https://github.com/plus3it/dependabot-terraform-action" \
      "com.github.actions.name"="dependabot-terraform-action" \
      "com.github.actions.description"="Run dependabot for terraform and terragrunt as github action" \
      "com.github.actions.icon"="check-circle" \
      "com.github.actions.color"="package"

WORKDIR /usr/src/app
ENV DEPENDABOT_NATIVE_HELPERS_PATH="/usr/src/app/native-helpers"
ENV TF_HELPERS_PATH ="$DEPENDABOT_NATIVE_HELPERS_PATH/terraform/bin"
ENV PATH="$TF_HELPERS_PATH:$PATH"

COPY ./src /usr/src/app
COPY ./src/run-action /usr/local/bin/run-action

RUN apt-get update && \
    apt-get install -y libxml2 libxml2-dev libxslt1-dev build-essential  && \
    apt-get install -y git wget && \
    bundle install && \
    mkdir -p $DEPENDABOT_NATIVE_HELPERS_PATH/terraform && \
    apt-get remove -y  build-essential patch perl perl-modules-5.28 && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /tmp/*

COPY --from=golang /go/bin $TF_HELPERS_PATH
COPY --from=golang /go/tf_helpers $TF_HELPERS_PATH

RUN chmod -R +x $TF_HELPERS_PATH

CMD ["run-action"]