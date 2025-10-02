FROM jrei/systemd-ubuntu:22.04

# Install SSH and sudo
RUN apt-get update && \
    apt-get install -y openssh-server sudo && \
    apt-get clean

# Create ubuntu user with sudo privileges
RUN useradd -m -s /bin/bash -G sudo ubuntu && \
    echo 'ubuntu:ubuntu' | chpasswd

# Configure SSH
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    systemctl enable ssh

# Create systemd service to remove nologin file on boot
RUN echo '[Unit]\n\
    Description=Remove nologin file\n\
    After=systemd-user-sessions.service\n\
    Before=getty@tty1.service\n\
    \n\
    [Service]\n\
    Type=oneshot\n\
    ExecStart=/bin/rm -f /run/nologin /var/run/nologin\n\
    \n\
    [Install]\n\
    WantedBy=multi-user.target' > /etc/systemd/system/remove-nologin.service && \
    systemctl enable remove-nologin.service

# Expose SSH port
EXPOSE 22

CMD ["/lib/systemd/systemd"]
