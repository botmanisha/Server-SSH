FROM ubuntu:latest
RUN apt-get update && \
    apt-get install -y openssh-server && \
    apt-get clean
RUN mkdir /var/run/sshd
EXPOSE 22
RUN useradd -m -s /bin/bash usuario && \
    echo 'usuario:contraseña' | chpasswd && \
    adduser usuario sudo
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "AllowUsers usuario" >> /etc/ssh/sshd_config
CMD ["/usr/sbin/sshd", "-D"]
