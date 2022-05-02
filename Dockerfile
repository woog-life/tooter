FROM racket/racket:8.5

WORKDIR /usr/app

COPY info.rkt .
COPY src/tooter.rkt .
COPY src/compiled .

RUN raco pkg install --no-cache --deps search-auto gregor
RUN raco pkg install --no-cache --deps search-auto request
RUN raco pkg install --no-cache --deps search-auto tjson
RUN raco exe tooter.rkt

CMD ./tooter
