FROM ruby:2.7
ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ADD Gemfile* $APP_HOME/
RUN bundle config set without 'development test'
RUN bundle install

ADD . $APP_HOME

EXPOSE 4567

CMD ["bundle", "exec", "ruby", "lib/onair.rb"]