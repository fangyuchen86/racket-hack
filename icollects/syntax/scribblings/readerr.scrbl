#lang scribble/doc
@(require "common.ss"
          (for-label syntax/readerr))

@title[#:tag "readerr"]{Raising @scheme[exn:fail:read]}

@defmodule[syntax/readerr]

@defproc[(raise-read-error [msg-string string?] 
                           [source any/c]
                           [line (or/c number? false/c)]
                           [col (or/c number? false/c)]
                           [pos (or/c number? false/c)]
                           [span (or/c number? false/c)]) 
         any]{

Creates and raises an @scheme[exn:fail:read] exception, using
@scheme[msg-string] as the base error message.

Source-location information is added to the error message using the
last five arguments (if the @scheme[error-print-source-location]
parameter is set to @scheme[#t]). The @scheme[source] argument is an
arbitrary value naming the source location---usually a file path
string. Each of the @scheme[line], @scheme[pos] arguments is
@scheme[#f] or a positive exact integer representing the location
within @scheme[source-name] (as much as known), @scheme[col] is a
non-negative exact integer for the source column (if known), and
@scheme[span] is @scheme[#f] or a non-negative exact integer for an
item range starting from the indicated position.

The usual location values should point at the beginning of whatever it
is you were reading, and the span usually goes to the point the error
was discovered.}

@defproc[(raise-read-eof-error [msg-string string?] 
                               [source any/c]
                               [line (or/c number? false/c)]
                               [col (or/c number? false/c)]
                               [pos (or/c number? false/c)]
                               [span (or/c number? false/c)]) 
         any]{

Like @scheme[raise-read-error], but raises @scheme[exn:fail:read:eof]
instead of @scheme[exn:fail:read].}
