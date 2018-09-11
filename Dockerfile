#######################
# pause builder image #
#######################
FROM ubuntu:18.04 

RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
COPY pause.c /tmp/pause.c
RUN gcc pause.c -o pause

#################
# Toolbox image #
#################
FROM ubuntu:18.04

ENV VERSION=0.0.1
ENV CHANNEL=alpha

WORKDIR /tmp

COPY --from=0 /tmp/pause /usr/local/bin/pause

RUN apt-get update && apt-get upgrade -y

RUN apt-get install -y \
    bash \
    bash-completion \
    bzip2 \
    curl \
    git \
    git-crypt \
    gnupg \
    gzip \
    jq \
    keychain \
    openssl \
    openssh-client \
    pass \
    pinentry-curses \
    pinentry-tty \
    pipsi \
    python \
    python-virtualenv \
    scdaemon \
    tar \
    tmux \
    unzip \
    vim \
    && apt-get clean all && rm -rf /var/lib/apt/lists/*

# Out of band tools version
ENV TERRAGRUNT_VERSION=0.16.8 \
    TERRAGRUNT_SHA256=8701d63a94df4fbd9435f27cec95ac23bf0100127d7af00ca9443bd567a702b7 \
    TERRAFORM_VERSION=0.11.8 \
    TERRAFORM_SHA256=84ccfb8e13b5fce63051294f787885b76a1fedef6bdbecf51c5e586c9e20c9b7 \
    TERRAFORM_DOCS_VERSION=0.3.0 \
    TERRAFORM_DOCS_SHA256=339c157dfbabc1ad22091b07d5793902611eee6c3c5e95c5fc7c6b55540c542a \
    TERRAFORM_CT_PROVIDER_VERSION=0.3.0 \
    TERRAFORM_CT_PROVIDER_SHA256=3d023545e08a90f792714998866ae8f8bab60bfbd583932c1c978133886d344c \
    KUBECTL_VERSION=1.10.5 \
    KUBECTL_SHA256=a9e7f82e516aa8a652bc485620483ea964eb940787cabf890d7eab96eaac294d \
    BASH_UNIT_VERSION=1.6.1 \
    BASH_UNIT_SHA256=596c2bcbcebcc5611e3f2e1458b0f4be1adad8f91498b20e97c9f7634416950f \
    STERN_VERSION=1.8.0 \
    STERN_SHA256=091aceef4e4655c06c519f58fb05ea290bd6aae7a1cf660c62aad0c030794e65

# terraform
RUN set -e \
    && curl -L https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o /tmp/terraform.zip \
    && echo "$TERRAFORM_SHA256  terraform.zip" | sha256sum -c \
    && unzip terraform.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/terraform \
    && rm -f terraform.zip

# terraform-docs
RUN set -e \
    && curl -L https://github.com/segmentio/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/terraform-docs_linux_amd64 -o /tmp/terraform-docs \
    && echo "$TERRAFORM_DOCS_SHA256  terraform-docs" | sha256sum -c \
    && mv terraform-docs /usr/local/bin \
    && chmod +x /usr/local/bin/terraform-docs

# stern
RUN set -e \
    && curl -L https://github.com/wercker/stern/releases/download/${STERN_VERSION}/stern_linux_amd64 -o /tmp/stern \
    && echo "$STERN_SHA256  stern" | sha256sum -c \
    && mv stern /usr/local/bin \
    && chmod +x /usr/local/bin/stern

# terragrunt
RUN set -e \
    && curl -L https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 -o /tmp/terragrunt \
    && echo "$TERRAGRUNT_SHA256  terragrunt" | sha256sum -c \
    && mv /tmp/terragrunt /usr/local/bin \
    && chmod +x /usr/local/bin/terragrunt

# terraform-ct-provider
RUN set -e \
    && curl -L https://github.com/coreos/terraform-provider-ct/releases/download/v${TERRAFORM_CT_PROVIDER_VERSION}/terraform-provider-ct-v${TERRAFORM_CT_PROVIDER_VERSION}-linux-amd64.tar.gz -o /tmp/terraform-ct-provider.tar.gz \
    && echo "$TERRAFORM_CT_PROVIDER_SHA256  terraform-ct-provider.tar.gz" | sha256sum -c \
    && tar zxvf /tmp/terraform-ct-provider.tar.gz  -C /tmp \
    && mv /tmp/terraform-provider-ct-v${TERRAFORM_CT_PROVIDER_VERSION}-linux-amd64/terraform-provider-ct /usr/local/bin \
    && rm -f /tmp/terraform-ct-provider.tar.gz

# bash_unit
RUN set -e \
    && curl -L https://github.com/pgrange/bash_unit/archive/v${BASH_UNIT_VERSION}.tar.gz -o /tmp/bash_unit.tar.gz \
    && echo "$BASH_UNIT_SHA256  bash_unit.tar.gz" | sha256sum -c \
    && tar zxvf /tmp/bash_unit.tar.gz  -C /tmp \
    && mv /tmp/bash_unit-${BASH_UNIT_VERSION}/bash_unit /usr/local/bin \
    && chmod a+x /usr/local/bin \
    && rm -f /tmp/bash_unit.tar.gz

# kubectl
RUN set -e \
    && curl -L https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /tmp/kubectl \
    && chmod +x /tmp/kubectl \
    && echo "$KUBECTL_SHA256  kubectl" | sha256sum -c \
    && mv /tmp/kubectl /usr/local/bin

# Customize rootfs
COPY rootfs/ /

# Setup User Environment
RUN groupadd --gid 1000 satoshi \
    && useradd --comment "Satoshi User" --home-dir /home/satoshi --gid satoshi --no-create-home --no-user-group --shell /bin/bash --uid 1000 satoshi \
    && mkdir /home/satoshi \
    && chown 1000:1000 /home/satoshi

WORKDIR /home/satoshi
USER 1000

# Set multiple labels 
LABEL vendor="Mintel" \
      com.mintel.team="satoshi" \
      com.mintel.version="${VERSION}" \
      com.mintel.channel="${CHANNEL}"

ENTRYPOINT [ "/usr/local/bin/pause" ]


