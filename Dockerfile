FROM public.ecr.aws/lambda/python:3.11

# Define build-time arguments
ARG GUARDRAILS_TOKEN

# Set the environment variables
ENV GUARDRAILS_TOKEN=${GUARDRAILS_TOKEN}
ENV AWS_DEFAULT_REGION=us-east-2

# Copy the directory containing setup.py (and the rest of your application)
COPY . ${LAMBDA_TASK_ROOT}

# Clean YUM cache and Install the specified packages and Git
RUN yum -y install git && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    pip install -e .

# Run guardrails configure with token input
RUN echo ${GUARDRAILS_TOKEN} | guardrails configure

# Run guardrails hub installs
RUN guardrails hub install hub://guardrails/detect_prompt_injection

# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
CMD [ "lambda_function.handler" ]