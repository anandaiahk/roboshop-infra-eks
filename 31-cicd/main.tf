resource "aws_instance" "jenkins" {
  count = var.jenkins ? 1 : 0
  ami           = local.ami_id
  instance_type = "t3.small"
  subnet_id = local.public_subnet_id
  vpc_security_group_ids = [local.jenkins_sg_id]
  user_data = file("jenkins.sh")

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    tags = merge(
      {
          Name = "${var.project}-${var.environment}-jenkins"
      },
    local.common_tags
    )
  }

  tags = merge(
    {
        Name = "${var.project}-${var.environment}-jenkins"
    },
    local.common_tags
  )
}


resource "aws_instance" "jenkins_agent" {
  count = var.jenkins ? 1 : 0
  ami           = local.ami_id
  instance_type = "t3.micro"
  subnet_id = local.public_subnet_id
  vpc_security_group_ids = [ local.jenkins_agent_sg_id ]
  user_data = file("jenkins-agent.sh")

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    tags = merge(
      {
          Name = "${var.project}-${var.environment}-jenkins-agent"
      },
    local.common_tags
    )
  }

  tags = merge(
    {
        Name = "${var.project}-${var.environment}-jenkins-agent"
    },
    local.common_tags
  )
}

resource "aws_instance" "runner" {
  count = var.runner ? 1 : 0
  ami           = local.ami_id
  instance_type = "t3.micro"
  subnet_id = local.public_subnet_id
  vpc_security_group_ids = [ local.runner_sg_id ]
  user_data = file("runner.sh")

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    tags = merge(
      {
          Name = "${var.project}-${var.environment}-runner"
      },
    local.common_tags
    )
  }

  tags = merge(
    {
        Name = "${var.project}-${var.environment}-runner"
    },
    local.common_tags
  )
}

resource "aws_instance" "sonarqube" {
  count = var.sonar ? 1 : 0
  ami           = data.aws_ami.sonarqube.id
  instance_type = "t3.large"
  vpc_security_group_ids = [local.sonar_sg_id]
  subnet_id = local.public_subnet_id #replace your Subnet in default VPC
  key_name = "daws-88s"
  # need more for terraform
  root_block_device {
    volume_size = 20
    volume_type = "gp3" # or "gp2", depending on your preference
  }
    user_data = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -y
    apt-get install -y openjdk-17-jdk wget unzip

    # SonarQube requirement
    echo "vm.max_map_count=524288" >> /etc/sysctl.conf
    echo "fs.file-max=131072" >> /etc/sysctl.conf
    sysctl -p

    # SonarQube Install
    cd /opt
    wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.4.1.88267.zip
    unzip sonarqube-10.4.1.88267.zip
    mv sonarqube-10.4.1.88267 sonarqube

    useradd -r -s /bin/false sonarqube
    chown -R sonarqube:sonarqube /opt/sonarqube

    cat > /etc/systemd/system/sonarqube.service <<'SERVICE'
    [Unit]
    Description=SonarQube
    After=network.target

    [Service]
    Type=forking
    User=sonarqube
    Group=sonarqube
    ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
    ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
    Restart=always

    [Install]
    WantedBy=multi-user.target
    SERVICE

    systemctl daemon-reload
    systemctl enable sonarqube
    systemctl start sonarqube
  EOF
  
  tags = merge(
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-sonar"
    }
  )
}