require './src/infrastructure/definitions/aws/aws_resource'

module Infrastructure
  module Definitions
    module Aws
      class Ec2Resource < AwsResource

        def initialize (id, credential, size, user_name, tags, cpu_credit_specification=nil, instance_role=nil)
          super(id, "ec2", credential, AwsResource::EC2_GROUP_ID)

          @size = size
          @user_name = user_name
          @ami_name = "amzn2-ami-hvm-2.0.????????.?-x86_64-gp2"
          @is_windows = false
          @tags = tags
          @cpu_credit_specification = cpu_credit_specification
          @instance_role = instance_role
        end

        def get_size()
          return @size
        end

        def get_user_name()
          return @user_name
        end

        def get_ami_name()
          return @ami_name
        end
        def set_ami_name(ami_name)
          @ami_name = ami_name
        end

        def is_windows?()
          return @is_windows == true
        end
        def set_windows(is_windows)
          @is_windows = is_windows
        end

        def get_tags()
          return @tags.merge({})
        end

        def get_cpu_credit_specification()
          return @cpu_credit_specification
        end

        def get_instance_role()
          return @instance_role
        end

        def get_user_data()
          if is_windows?()
            return "<powershell>
            Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force\n
            $url = \"https://raw.githubusercontent.com/ansible/ansible-documentation/devel/examples/scripts/ConfigureRemotingForAnsible.ps1\"\n
            $file = \"$env:temp\\ConfigureRemotingForAnsible.ps1\"\n
            [Net.ServicePointManager]::SecurityProtocol = \"tls12, tls\"\n
            (New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)\n
            powershell.exe -ExecutionPolicy ByPass -File $file\n
            # Install and start SSM agent\n
            $ssmAgentUrl = \"https://amazon-ssm-$region.s3.amazonaws.com/latest/windows_amd64/AmazonSSMAgentSetup.exe\"\n
            $ssmAgentPath = \"$env:temp\\AmazonSSMAgentSetup.exe\"\n
            (New-Object -TypeName System.Net.WebClient).DownloadFile($ssmAgentUrl, $ssmAgentPath)\n
            Start-Process -FilePath $ssmAgentPath -ArgumentList \"/S\" -Wait\n
            Start-Service AmazonSSMAgent\n
          </powershell>"
          else
            # Linux user data to ensure SSM agent is installed and running
            return "#!/bin/bash
            # Update system and install SSM agent if not present
            
            # Function to install SSM agent
            install_ssm_agent() {
              # Detect OS and install accordingly
              if [ -f /etc/os-release ]; then
                . /etc/os-release
                OS=$ID
                VER=$VERSION_ID
              elif type lsb_release >/dev/null 2>&1; then
                OS=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
                VER=$(lsb_release -sr)
              else
                OS=$(uname -s)
              fi
              
              case $OS in
                # Amazon Linux 2
                amzn|\"amzn\")
                  yum update -y
                  yum install -y amazon-ssm-agent
                  systemctl enable amazon-ssm-agent
                  systemctl start amazon-ssm-agent
                  ;;
                  
                # Ubuntu/Debian
                ubuntu|debian)
                  apt-get update -y
                  snap install amazon-ssm-agent --classic || {
                    # Fallback for older Ubuntu versions without snap
                    wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
                    dpkg -i amazon-ssm-agent.deb
                  }
                  systemctl enable amazon-ssm-agent
                  systemctl start amazon-ssm-agent
                  ;;
                  
                # RHEL/CentOS/Fedora/Oracle Linux
                rhel|centos|fedora|ol|\"rhel\"|\"centos\"|\"fedora\"|\"ol\")
                  yum update -y || dnf update -y
                  yum install -y amazon-ssm-agent || {
                    # Download and install manually if not in repo
                    wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
                    rpm -ivh amazon-ssm-agent.rpm
                  }
                  systemctl enable amazon-ssm-agent
                  systemctl start amazon-ssm-agent
                  ;;
                  
                # SUSE/openSUSE
                sles|opensuse*|suse|\"sles\"|\"opensuse\")
                  zypper refresh
                  # Download and install SSM agent manually for SUSE
                  wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
                  rpm -ivh amazon-ssm-agent.rpm || zypper install -y ./amazon-ssm-agent.rpm
                  systemctl enable amazon-ssm-agent
                  systemctl start amazon-ssm-agent
                  ;;
                  
                # Alpine Linux
                alpine)
                  apk update
                  # SSM agent not officially supported on Alpine, but we can try
                  wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.tar.gz
                  tar -xzf amazon-ssm-agent.tar.gz
                  # Manual installation would be complex for Alpine
                  echo \"Warning: SSM agent installation on Alpine Linux may require manual setup\"
                  ;;
                  
                # Arch Linux
                arch)
                  pacman -Syu --noconfirm
                  # Install from AUR or manual installation
                  wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.tar.gz
                  tar -xzf amazon-ssm-agent.tar.gz
                  # Would need custom installation for Arch
                  echo \"Warning: SSM agent installation on Arch Linux may require manual setup\"
                  ;;
                  
                *)
                  echo \"Unknown OS: $OS. Attempting generic installation...\"
                  # Generic fallback - try to download and install manually
                  if command -v wget >/dev/null 2>&1; then
                    wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
                    rpm -ivh amazon-ssm-agent.rpm 2>/dev/null || {
                      # Try tar.gz version
                      wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.tar.gz
                      tar -xzf amazon-ssm-agent.tar.gz
                      echo \"Manual SSM agent setup may be required for this OS\"
                    }
                  fi
                  ;;
              esac
            }
            
            # Check if SSM agent is already running
            if ! systemctl is-active --quiet amazon-ssm-agent 2>/dev/null; then
              echo \"Installing SSM agent...\"
              install_ssm_agent
            else
              echo \"SSM agent is already running\"
            fi
            
            # Final check and restart if needed
            sleep 10
            systemctl enable amazon-ssm-agent 2>/dev/null || true
            systemctl restart amazon-ssm-agent 2>/dev/null || true
            
            echo \"SSM agent installation completed\""
          end
        end

      end
    end
  end
end
