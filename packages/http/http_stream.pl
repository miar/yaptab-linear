/*  $Id$

    Part of SWI-Prolog

    Author:        Jan Wielemaker
    E-mail:        wielemak@science.uva.nl
    WWW:           http://www.swi-prolog.org
    Copyright (C): 1985-2007, University of Amsterdam

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

    As a special exception, if you link this library with other files,
    compiled with a Free Software compiler, to produce an executable, this
    library does not by itself cause the resulting executable to be covered
    by the GNU General Public License. This exception does not however
    invalidate any other reasons why the executable file might be covered by
    the GNU General Public License.
*/

:- module(http_stream,
	  [ http_chunked_open/3,	% +Stream, -DataStream, +Options
	    stream_range_open/3,	% +Stream, -DataStream, +Options
					% CGI Stream interaction
	    cgi_open/4,			% +Stream, -DataStream, :Hook, +Options
	    cgi_property/2,		% +Stream, -Property
	    cgi_set/2,			% +Stream, -Property
	    cgi_discard/1,		% +Stream
	    is_cgi_stream/1		% +Stream
	  ]).

:- expects_dialect(swi).
:- assert(system:swi_io).

:- use_module(library(shlib)).

:- use_foreign_library(foreign(http_stream)).

/** <module> HTTP Streams

This module realises  encoding  and   decoding  filters,  implemented as
Prolog streams that read/write to an  underlying stream. This allows for
sequences of streams acting as an in-process pipeline.

The predicate http_chunked_open/3 realises encoding  and decoding of the
HTTP _Chunked_ encoding. This encoding is an obligatory part of the HTTP
1.1 specification. Messages are split into chunks, each preceeded by the
length of the chunk. Chunked  encoding   allows  sending messages over a
serial link (typically a TCP/IP stream) for  which the reader knows when
the message is ended. Unlike standard HTTP   though, the sender does not
need to know the message length  in   advance.  The  protocol allows for
sending short chunks. This is  supported   totally  transparent  using a
flush on the output stream.

The predicate stream_range_open/3 handles the Content-length on an input
stream for handlers that are designed  to   process  an entire file. The
filtering stream claims end-of-file after reading  a specified number of
bytes, dispite the fact that the underlying stream may be longer.

@see	The HTTP 1.1 protocol http://www.w3.org/Protocols/rfc2616/rfc2616.html
@author Jan Wielemaker
*/

%%	http_chunked_open(+RawStream, -DataStream, +Options) is det.
%
%	Create a stream to realise HTTP   chunked  encoding or decoding.
%	The technique is similar to library(zlib), using a Prolog stream
%	as a filter on another stream.  Options:
%
%		* close_parent(+Bool)
%		If =true= (default =false=), the parent stream is closed
%		if DataStream is closed.
%
%		* max_chunk_size(+PosInt)
%		Define the maximum size of a chunk.  Default is the
%		default buffer size of fully buffered streams (4096).
%		Larger values may improve throughput.  It is also
%		allowed to use =|set_stream(DataStream, buffer(line))|=
%		on the data stream to get line-buffered output. See
%		set_stream/2 for details. Switching buffering to =false=
%		is supported.
%
%	Here is example code to write a chunked data to a stream
%
%	==
%		http_chunked_open(Out, S, []),
%		format(S, 'Hello world~n', []),
%		close(S).
%	==
%
%	If a stream is known to contain chunked data, we can extract
%	this data using
%
%	==
%		http_chunked_open(In, S, []),
%		read_stream_to_codes(S, Codes),
%		close(S).
%	==
%
%	The current implementation does not  generate chunked extensions
%	or an HTTP trailer. If such extensions  appear on the input they
%	are silently ignored. This  is  compatible   with  the  HTTP 1.1
%	specifications. Although a filtering  stream   is  an  excellent
%	mechanism for encoding and decoding   the core chunked protocol,
%	it does not well support out-of-band data.
%
%	After http_chunked_open/3, the encoding  of   DataStream  is the
%	same as the  encoding  of  RawStream,   while  the  encoding  of
%	RawStream is =octet=, the only value   allowed  for HTTP chunked
%	streams. Closing the DataStream  restores   the  old encoding on
%	RawStream.
%
%	@error	io_error(read, Stream) where the message context provides
%		an indication of the problem.  This error is raised if
%		the input is not valid HTTP chunked data.

%%	stream_range_open(+RawStream, -DataStream, +Options) is det.
%
%	DataStream is a stream  whose  size   is  defined  by the option
%	size(ContentLength).   Closing   DataStream   does   not   close
%	RawStream.

:- meta_predicate cgi_open(+, -, :, +).


%%	cgi_open(+OutStream, -CGIStream, :Hook, +Options) is det.
%
%	Process CGI output. OutStream is   normally the socket returning
%	data to the HTTP client. CGIStream   is  the stream the (Prolog)
%	code writes to. The CGIStream provides the following functions:
%
%	    * At the end of the header, it calls Hook using
%	    call(Hook, header, Stream), where Stream is a stream holding
%	    the buffered header.
%
%	    * If the stream is closed, it calls Hook using
%	    call(Hook, data, Stream), where Stream holds the buffered
%	    data.
%
%	The stream calls Hook, adding  the   event  and CGIStream to the
%	closure. Defined events are:
%
%	    * header
%	    Called  if  the  header  is   complete.  Typically  it  uses
%	    cgi_property/2 to extract the collected  header and combines
%	    these with the request and policies   to decide on encoding,
%	    transfer-encoding, connection parameters and   the  complete
%	    header (as a Prolog term). Typically   it  uses cgi_set/2 to
%	    associate these with the stream.
%
%	    * send_header
%	    Called if the HTTP header must  be sent. This is immediately
%	    after setting the transfer encoding to =chunked= or when the
%	    CGI stream is closed.  Typically   it  requests  the current
%	    header, optionally the content-length and   sends the header
%	    to the original (client) stream.
%
%	    * close
%	    Called from close/1 on the CGI   stream  after everything is
%	    complete.
%
%	The predicates cgi_property/2  and  cgi_set/2   can  be  used to
%	control the stream and store status   info.  Terms are stored as
%	Prolog records and can thus be transferred between threads.

%%	cgi_property(+CGIStream, ?Property) is det.
%
%	Inquire the status of the CGI stream.  Defined properties are:
%
%	    * request(-Term)
%	    The original request
%	    * header(-Term)
%	    Term is the header term as registered using cgi_set/2
%	    * client(-Stream)
%	    Stream is the original output stream used to create
%	    this stream.
%	    * thread(-ThreadID)
%	    ThreadID is the identifier of the `owning thread'
%	    * transfer_encoding(-Tranfer)
%	    One of =chunked= or =none=.
%	    * connection(-Connection)
%	    One of =Keep-Alife= or =close=
%	    * content_length(-ContentLength)
%	    Total byte-size of the content.  Available in the close
%	    handler if the transfer_encoding is =none=.
%	    * header_codes(-Codes)
%	    Codes represents the header collected.  Available in the
%	    header handler.
%	    * state(-State)
%	    One of =header=, =data= or =discarded=

%%	cgi_set(+CGIStream, ?Property) is det.
%
%	Change one of the properies.  Supported properties are:
%
%	    * request(+Term)
%	    Associate a request to the stream.
%	    * header(+Term)
%	    Register a reply header.  This header is normally retrieved
%	    from the =send_header= hook to send the reply header to the
%	    client.
%	    * connection(-Connection)
%	    One of =Keep-Alife= or =close=.
%	    * transfer_encoding(-Tranfer)
%	    One of =chunked= or =none=.  Initially set to =none=.  When
%	    switching to =chunked= from the =header= hook, it calls the
%	    =send_header= hook and if there is data queed this is send
%	    as first chunk.  Each subsequent write to the CGI stream
%	    emits a chunk.

%%	cgi_discard(+CGIStream) is det.
%
%	Discard content produced sofar. It sets   the  state property to
%	=discarded=, causing close to omit the   writing  the data. This
%	must be to use an alternate output   (e.g. an error page) if the
%	page generator fails.

%%	is_cgi_stream(+Stream) is semidet.
%
%	True if Stream is a CGI stream created using cgi_open/4.

:- multifile
	http:encoding_filter/3.		% +Encoding, +In0,  -In
:- multifile
	http:current_transfer_encoding/1. % ?Encoding

%	http:encoding_filter(+Encoding, +In0, -In) is semidet.
%
%	Install a filter to deal with =chunked= encoded messages.

http:encoding_filter(chunked, In0, In) :-
	http_chunked_open(In0, In,
			  [ close_parent(true)
			  ]).

%	http:current_transfer_encoding(?Encoding) is semidet.
%
%	True if Encoding is supported

http:current_transfer_encoding(chunked).

:- retract(system:swi_io).
