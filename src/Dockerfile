# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM google/cloud-sdk:alpine
COPY main.sh .
COPY pageviews.sh .
COPY sweep.sh .
COPY update.sh .
COPY entities.sh .
COPY load.sh .
COPY startup.sh .
#ARG CLOUD_SDK_VERSION=270.0.0
ARG CLOUD_SDK_VERSION=323.0.0
ENV PATH /google-cloud-sdk/bin:$PATH
RUN apk --no-cache add curl wget python3 py-crcmod bash libc6-compat && \
    curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    tar xzf google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    rm google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    ln -s /lib /lib64 && \
    gcloud components install beta -q
ENTRYPOINT ["./main.sh"]
