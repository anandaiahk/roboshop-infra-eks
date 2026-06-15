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
  ami           = data.aws_ami.sonarqube.id
  instance_type = "t3.medium"  # minimum t3.medium కావాలి SonarQube కి
  key_name               = "bat-88s" 
  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # System Update
    apt-get update -y
    apt-get upgrade -y

    # Java Install (SonarQube కి కావాలి)
    apt-get install -y openjdk-17-jdk

    # PostgreSQL Install
    apt-get install -y postgresql postgresql-contrib

    # PostgreSQL Setup
    sudo -u postgres psql <<PSQL
      CREATE USER sonar WITH ENCRYPTED PASSWORD 'sonar@123';
      CREATE DATABASE sonarqube OWNER sonar;
      GRANT ALL PRIVILEGES ON DATABASE sonarqube TO sonar;
PSQL

    # System Settings (SonarQube కి తప్పనిసరి)
    echo "vm.max_map_count=524288" >> /etc/sysctl.conf
    echo "fs.file-max=131072" >> /etc/sysctl.conf
    sysctl -p

    echo "sonarqube   -   nofile   131072" >> /etc/security/limits.conf
    echo "sonarqube   -   nproc    8192" >> /etc/security/limits.conf

    # SonarQube Download & Install
    cd /opt
    wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.4.1.88267.zip
    apt-get install -y unzip
    unzip sonarqube-10.4.1.88267.zip
    mv sonarqube-10.4.1.88267 sonarqube

    # SonarQube User Create
    useradd -r -s /bin/false sonarqube
    chown -R sonarqube:sonarqube /opt/sonarqube

    # DB Config
    cat >> /opt/sonarqube/conf/sonar.properties <<CONF
sonar.jdbc.username=sonar
sonar.jdbc.password=sonar@123
sonar.jdbc.url=jdbc:postgresql://localhost:5432/sonarqube
sonar.web.host=0.0.0.0
sonar.web.port=9000
CONF

    # Systemd Service Create
    cat > /etc/systemd/system/sonarqube.service <<SERVICE
[Unit]
Description=SonarQube Service
After=network.target postgresql.service

[Service]
Type=forking
User=sonarqube
Group=sonarqube
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
Restart=always
LimitNOFILE=131072
LimitNPROC=8192

[Install]
WantedBy=multi-user.target
SERVICE

    # Service Start
    systemctl daemon-reload
    systemctl enable sonarqube
    systemctl start sonarqube

    echo "✅ SonarQube Installation Complete!"
  EOF

  tags = {
    Name = "SonarQube-Server"
  }
}
