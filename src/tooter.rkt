#lang racket
(require tjson)
(require request)
(require gregor)

(define client-key (getenv "MASTODON_CLIENT_KEY"))
(define client-secret (getenv "MASTODON_CLIENT_SECRET"))
(define mastodon-code (getenv "MASTODON_CODE"))
(define redirect-uri "urn:ietf:wg:oauth:2.0:oob")
(define grant-type "client_credentials")
(define woog-lake-id "69c8438b-5aef-442f-a70d-e0d783ea2b38")
(define toot-time-format "HH:mm dd.MM.YYYY")

(define mastodon-api-base-path "api/v1")
; String -> String
(define (make-api-url path) (string-append-immutable mastodon-api-base-path "/" path))

(define wooglife-client (make-domain-requester "api.woog.life" (make-https-requester http-requester)))
(define mastodon-client (make-domain-requester "mastodon.social" (make-https-requester http-requester)))

(define lake-response (get wooglife-client "lake"))

(define lake-json (string->json (http-response-body lake-response)))
(define lakes (hash-ref lake-json 'lakes))
(define woog-lake-output (list-ref (filter (lambda (item) (equal? woog-lake-id (hash-ref item 'id))) lakes) 0))

(define lake-url (string-append-immutable "lake/" (hash-ref woog-lake-output 'id)))
(define-values (response-lake) (get wooglife-client lake-url))
(define json-lake (string->json (http-response-body response-lake)))

(define woog (hash-ref json-lake 'data))
(define woog-temperature (hash-ref woog 'preciseTemperature))
(define woog-datetime (iso8601->datetime (hash-ref woog 'time)))
(define woog-time (~t woog-datetime toot-time-format))
(define toot (string-append-immutable "Der Woog hat eine Temperatur von " woog-temperature "°C (" woog-time ") #woog #wooglife #darmstadt"))

(define url-form-string (string-append-immutable "client_id=" client-key "&client_secret=" client-secret "&redirect_uri=" redirect-uri "&grant_type=" grant-type "&scope=read+write:statuses" "&code=" mastodon-code))
(define url (string-append-immutable "oauth/token?" url-form-string))

; (define-values (mastodon-token-response) (post mastodon-client url (bytes)))
; (define json-mastodon-token (string->json (http-response-body mastodon-token-response)))
; (define mastodon-token (hash-ref json-mastodon-token 'access_token))
(define fixed-mastodon-token (getenv "MASTODON_TOKEN"))

(define idempotency-header (string-append-immutable "Idempotency-Key: " woog-lake-id))
(define mastodon-headers (list (string-append-immutable "Authorization:" "Bearer " fixed-mastodon-token) "Content-Type: application/json" "Accept: application/json" idempotency-header))

(define mastodon-statuses-url (make-api-url "statuses"))

(define mastodon-post-statuses-body (string->bytes/utf-8 (string-append-immutable "{\"status\": \"" toot "\"}")))
(displayln mastodon-post-statuses-body)

(define mastodon-post-statuses-response (post mastodon-client mastodon-statuses-url mastodon-post-statuses-body #:headers mastodon-headers))
(define json-mastodon-status-response (http-response-body mastodon-post-statuses-response))
(displayln mastodon-post-statuses-response)
(displayln mastodon-statuses-url)