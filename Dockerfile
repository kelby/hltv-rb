# FROM ruby:2.6.5
# 
# RUN apt-get update -qq && apt-get install -y build-essential
# 
# # throw errors if Gemfile has been modified since Gemfile.lock
# RUN bundle config --global frozen 1
# 
# WORKDIR /usr/src/app
# 
# COPY Gemfile Gemfile.lock ./
# RUN bundle install
# 
# COPY . .
# 
# EXPOSE 3005
# CMD ["./app.rb"]

FROM ruby:2.5

RUN apt-get update -qq && apt-get install -y build-essential

RUN \
  gem update --system --quiet && \
  gem install bundler -v '~> 2.1'

# ENV SYSTEM_UPDATE=1
ENV BUNDLER_VERSION 2.1
ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ADD Gemfile* $APP_HOME/
# ADD hltv.gemspec $APP_HOME/
RUN bundle install # --without development test

# RUN gem update --system --quiet

#RUN \
#  gem update --system --quiet && \
#  gem install bundler -v '~> 2.1' && \
#  gem install rake -v '10.5.0' && \
#  gem install amq-protocol && \
#  gem install bunny -v '2.14.3' && \
#  gem install coderay -v '1.1.2' && \
#  gem install ffi -v '1.12.2'

# RUN bundle config --global frozen 1

# ENV BUNDLER_VERSION 2.0.2

ADD . $APP_HOME

EXPOSE 4567

# CMD ["bundle", "exec", "ruby", "app.rb"]
# CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "-p", "4567"]
# CMD ["bundle", "exec", "rackup", "config.ru", "-p", "80", "-s", "thin", "-o", "0.0.0.0"]
# 
CMD ["ruby", "./app.rb"]
