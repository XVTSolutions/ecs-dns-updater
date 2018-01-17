FROM python:3.6

RUN pip install awscli
COPY ecs-dns-updater.sh /usr/local/bin/ecs-dns-updater.sh
CMD /bin/bash /usr/local/bin/ecs-dns-updater.sh
