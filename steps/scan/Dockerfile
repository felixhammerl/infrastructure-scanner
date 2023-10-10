FROM node:lts-alpine

RUN apk add --update --no-cache aws-cli bash git openssh

WORKDIR /
RUN git clone https://github.com/aquasecurity/cloudsploit.git
WORKDIR /cloudsploit
RUN npm install

ENV ACCOUNT "placeholder"
ENV S3_BUCKET "placeholder"

ADD scan.sh /cloudsploit

RUN ["chmod", "+x", "/cloudsploit/scan.sh"]
RUN ["chmod", "+x", "/cloudsploit/index.js"]

ENTRYPOINT []
CMD /cloudsploit/scan.sh
