# FROM ubuntu:18.04
ARG REPO_LOCATION=''
FROM ${REPO_LOCATION}ubuntu:18.04
ARG USE_PROXY=none
RUN bash -c 'if [ $USE_PROXY = "ti" ]; then echo "Acquire::http::proxy \"http://webproxy.ext.ti.com:80\";" > /etc/apt/apt.conf; fi'
RUN bash -c 'if [ $USE_PROXY = "ti" ];then echo -e "export ftp_proxy=http://webproxy.ext.ti.com:80\nexport http_proxy=http://webproxy.ext.ti.com:80\nexport https_proxy=http://webproxy.ext.ti.com:80\nno_proxy=ti.com " > ~/.bashrc;fi'
 
# baseline
RUN apt-get update
RUN apt-get install -y python3 python3-pip python3-setuptools

# ubuntu package dependencies
# libsm6 libxext6 libxrender1 : needed by opencv
# cmake protobuf-compiler libprotoc-dev : needed by onnx
# graphviz : needed by tvm
# swig : needed by model selection tool
# curl vim git wget gdb : needeed by baseline dev
RUN apt install -y libsm6 libxext6 libxrender1 cmake libprotobuf-dev protobuf-compiler libprotoc-dev graphviz swig curl vim git wget gdb nano zip gcc-5 g++-5 pkg-config libgtk-3-dev libyaml-cpp-dev

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh
COPY requirements_pc.txt /requirements_pc.txt
RUN  pip3 install -r /requirements_pc.txt

# RUN  echo "#!/bin/bash" > /dev_entrypoint.sh
# RUN  echo "echo Starting Dev Container" >> /dev_entrypoint.sh
# RUN  chmod +x /dev_entrypoint.sh
# ARG MODE=test

# RUN bash -c 'if [ $MODE = "dev" ]; then cp /dev_entrypoint.sh /curr_entrypoint.sh; else cp  /entrypoint.sh /curr_entrypoint.sh; fi'

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/root/edgeai-tidl-tools/entrypoint.sh"]
