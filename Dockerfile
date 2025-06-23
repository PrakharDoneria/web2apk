FROM ghcr.io/cirruslabs/android-sdk:33

RUN apt update && apt install -y ruby-full unzip git curl && \
    gem install sinatra rubyzip zip rackup puma

WORKDIR /app
COPY . /app

EXPOSE 4567
CMD ["ruby", "main.rb", "-o", "0.0.0.0"]