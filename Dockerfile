FROM ghcr.io/cirruslabs/android-sdk:34

RUN apt update && apt install -y ruby-full unzip git curl build-essential libxml2-dev libxslt1-dev

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN gem install bundler && bundle install

COPY . .

EXPOSE 4567

CMD ["bundle", "exec", "ruby", "src/main.rb"]