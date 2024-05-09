FROM python:3.10.8

RUN apt-get clean all
RUN apt-get update && DEBIAN_FRONTEND="noninteractive" TZ="America/New_York" apt-get install -y tzdata

# Set local UTF-8
RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8

# Install Ruby
RUN apt-get install ruby-full -y
RUN gem install bundler -v 1.17.3

# Others
RUN apt-get update
RUN apt-get install curl -y
RUN apt-get update
RUN apt-get install git rsync -y

# Terraform
RUN \
    # Update
    apt-get update -y && \
    # Install Unzip
    apt-get install unzip -y && \
    # need wget
    apt-get install wget -y
RUN wget https://releases.hashicorp.com/terraform/0.11.11/terraform_0.11.11_linux_amd64.zip
# Unzip
RUN unzip terraform_0.11.11_linux_amd64.zip
# Move to local bin
RUN mv terraform /usr/local/bin/

RUN mkdir /mnt/deployer
WORKDIR /mnt/deployer

COPY Gemfile Gemfile.lock /mnt/deployer/

RUN gem install rexml -v '3.2.5' --source 'https://rubygems.org/'

RUN bundle install --clean --force

COPY requirements.python.txt requirements.ansible.yml requirements.ansible.private.yml /mnt/deployer/

RUN python3 -m pip install -r requirements.python.txt

RUN curl -O https://raw.githubusercontent.com/ansible-collections/azure/dev/requirements.txt
RUN python3 -m pip install -r requirements.txt

# Install Ansible dependencies
RUN ansible-galaxy role install -r requirements.ansible.yml && \
    ansible-galaxy collection install -r requirements.ansible.yml

# Install optional private dependencies
# Build with `--secret id=ssh_private_key,src=/path/to/ssh_private_key` to install private dependencies
RUN mkdir -p -m 0600 /root/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts
RUN --mount=type=secret,id=ssh_private_key \
    if test -f /run/secrets/ssh_private_key; then \
    mkdir -p /root/.ssh && \
    chmod 0700 /root/.ssh && \
    ssh-keyscan github.com > /root/.ssh/known_hosts && \
    cat /run/secrets/ssh_private_key > /root/.ssh/id_rsa && \
    chmod 600 /root/.ssh/id_rsa && \
    eval `ssh-agent -s` && \
    ssh-add /root/.ssh/id_rsa && \
    ansible-galaxy collection install -r requirements.ansible.private.yml  && \
    rm -rf /root/.ssh; \
    fi


COPY . /mnt/deployer/
# CMD [ "ruby", "--version"]
# CMD [ "python", "--version"]
# CMD [ "rake"]

ENTRYPOINT [ "ruby", "main.rb" ]
