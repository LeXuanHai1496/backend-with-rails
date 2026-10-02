# syntax=docker/dockerfile:1

# Dockerfile cho môi trường DEVELOPMENT (dùng với docker-compose.yml).
# Cài ĐẦY ĐỦ gem group development/test (debug, web-console, brakeman,
# capybara, selenium-webdriver...), không precompile gì cả — code được mount
# từ host vào nên sửa là thấy ngay, không cần rebuild image.
#
# LƯU Ý: file này KHÔNG phù hợp để build image production/Kamal (thiếu asset
# precompile, non-root user, Thruster, ENTRYPOINT db:prepare...). Nếu sau
# này cần deploy bằng Kamal (config/deploy.yml), sẽ cần dựng lại một
# Dockerfile production riêng lúc đó.
ARG RUBY_VERSION=3.3.12
FROM docker.io/library/ruby:$RUBY_VERSION-slim

WORKDIR /rails

# build-essential + libpq-dev: compile native extension (bcrypt, pg).
# git: một số gem trong Gemfile.lock có thể fetch từ git source.
# libjemalloc2 + curl: đồng bộ với Dockerfile production, không bắt buộc
# nhưng để môi trường dev/production gần giống nhau nhất có thể.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential curl git libjemalloc2 libpq-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Chỉ copy Gemfile trước để tận dụng layer cache của Docker — bundle install
# chỉ chạy lại khi Gemfile/Gemfile.lock đổi, không phải mỗi khi sửa code.
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy code lần đầu lúc build image; lúc chạy thật docker-compose sẽ mount
# thư mục project đè lên đây (xem volumes trong docker-compose.yml) nên COPY
# này chủ yếu để image có thể chạy độc lập nếu không mount volume.
COPY . .

EXPOSE 3000

CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
