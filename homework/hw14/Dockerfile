  
FROM alpine:3.12
LABEL maintainer="Andrii Trofymchuk <expert.it.andrey@gmail.com>"
RUN apk update && apk upgrade && apk add nginx
RUN adduser -D -g 'www' www
RUN mkdir /www && chown -R www:www /var/lib/nginx && chown -R www:www /www
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./index.html /www
RUN ln -sf /dev/stdout /var/log/nginx/access.log && ln -sf /dev/stderr /var/log/nginx/error.log
RUN mkdir -p /run/nginx
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
