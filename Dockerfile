#
# Copyright 2018-2019 IBM Corp. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

FROM raspbian/stretch

#ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
#ENV PATH /opt/conda/bin:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils
RUN apt-get -qq update && apt-get -qq -y install curl bzip2 \
    && curl -sSL https://github.com/jjhelmus/berryconda/releases/download/v2.0.0/Berryconda3-2.0.0-Linux-armv7l.sh -o /tmp/berryconda.sh \
    && bash /tmp/berryconda.sh -bfp /usr/local \
    && rm -rf /tmp/berryconda.sh \
    && conda install -y python=3 \
    && conda update conda \
    && apt-get -qq -y install libatlas-base-dev \ 
    && apt-get -qq -y install python-pip \
    && pip install tensorflow \
    && apt-get -qq -y remove curl bzip2 \
    && apt-get -qq -y autoremove \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* /var/log/dpkg.log \
    && conda clean --all --yes

ENV PATH /opt/conda/bin:$PATH

WORKDIR /workspace
RUN mkdir assets

COPY requirements.txt /workspace
RUN pip install --upgrade pip
RUN pip install --upgrade six
RUN pip install --upgrade tensorflow
RUN pip install -r requirements.txt

COPY . /workspace
#FROM codait/max-base:v1.1.3

ARG model_bucket=https://max-assets-prod.s3.us-south.cloud-object-storage.appdomain.cloud/max-object-detector/1.0.1
ARG model_file=model.tar.gz
ARG data_file=data.tar.gz
ARG use_pre_trained_model=true

WORKDIR /workspace

RUN if [ "$use_pre_trained_model" = "true" ] ; then\
    wget -nv --show-progress --progress=bar:force:noscroll ${model_bucket}/${model_file} --output-document=assets/${model_file} && \
           tar -x -C assets/ -f assets/${model_file} -v && rm assets/${model_file} && \
    wget -nv --show-progress --progress=bar:force:noscroll ${model_bucket}/${data_file} --output-document=assets/${data_file} && \
           tar -x -C assets/ -f assets/${data_file} -v && rm assets/${data_file}; fi

RUN wget -nv --show-progress --progress=bar:force:noscroll https://github.com/IBM/MAX-Object-Detector-Web-App/archive/v1.2.tar.gz && \
  tar -xf v1.2.tar.gz && rm v1.2.tar.gz

RUN mv ./MAX-Object-Detector-Web-App-1.2/static static

#COPY requirements.txt /workspace
#RUN pip install -r requirements.txt

COPY . /workspace

RUN if [ "$use_pre_trained_model" = "true" ] ; then \
      # validate downloaded pre-trained model assets
      md5sum -c md5sums.txt ; \
    else \
      # rename the directory that contains the custom-trained model artifacts
      if [ -d "./custom_assets/" ] ; then \
        rm -rf ./assets && ln -s ./custom_assets ./assets ; \
      fi \
    fi

EXPOSE 5000

CMD python app.py
