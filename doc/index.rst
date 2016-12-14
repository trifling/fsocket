
.. _`GPL-3.0`: https://opensource.org/licenses/GPL-3.0
.. _fsocket-1.1.zip: https://github.com/trifling/fsocket/archive/v1.0.zip
.. _github: https://github.com/trifling/fsocket

Introduction
============

FSocket provides a high level easy to use Fortran 90 interface to POSIX stream
sockets in blocking or non-blocking mode, and allows for an effortless
implementation of low-level network communication in Fortran programs. 

Functions are provided for listening, selecting and connecting, sending and
receiving integer and double arrays and strings, and ip lookup by hostname.


Motivation 
==========

FSocket was originally written to be used implementing parallel scientific
codes, but it can be used by any program that needs stream sockets. 

Most often Fortran parallel scientific codes are implemented with MPI or OpenMP
as the parallelization paradigm. In general, this is the most straightforward
and painless way to go, but there are circumstances where a direct
client/server or cloud paradigm might be preferable, or special circumstances
demand custom solutions.  

For example, the FSocket library has been used in a thousand-node minimization
code that needed to run in a busy supercomputer for weeks. At each step of the
minimization a set of heterogeneous quantities needed to be computed. With the
ad-hoc parallelization implemented with the help of FSocket, it was easy to add
or remove processes to a pool of workers that was automatically managed using
the standard batch queue system of the supercomputers where it run. This code
could go on unattended for weeks, asking for resources and adapting to its
environment, with process-level fault tolerance built-in.

A solution with the same degree of fault-tolerance is relatively tricky to
achieve using MPI, for example. And not only because of MPI itself, but for the
environment where the code is to be run: most job schedulers at supercomputers
require the number of processes to be declared in advance for MPI runs, and it
is not possible to change it once the program has been launched. Also, many
batch systems are designed in such a way that it is much easier to get
computing time launching many self-declared short-lived single-cpu processes as
resources become free, than big MPI runs.

Download
========
The latest FSocket is version 1.1, and can be downloaded here: `fsocket-1.1.zip`_. 

The source repository is hosted at `github`_.

Licensing 
=========
FSocket is released under the GPL-3, but if you need it under other licensing 
terms, please feel free to `email me <mailto:trifling.github@gmail.com>`_.

Getting started
===============

Installing FSocket 
------------------

FSocket uses cmake, so it should be easy and fairly automatic to build. For example,
to build and install a dynamic version in /usr/local do:

.. highlight:: bash

.. code-block:: bash

   $ mkdir bld 
   $ cd bld 
   $ cmake -DCMAKE_INSTALL_PREFIX=/usr/local ../ 
   $ make 
   $ make install 

Using FSocket
-------------

FSocket provides all its functionality via the inclusion of one Fortran 90 module, so it's enough to

.. code-block:: fortran

   use fsocket

at the beginning of every Fortran source file that uses FSocket. 

To link a program against FSocket, simply do:

.. code-block:: bash

   f90 -o prog prog.c -lclosest -lm


Code Example
============

In a client/server paradigm, the server would look something like:

.. code-block:: fortran

   use fsocket
   
   integer :: server, port, socket, ierr
   integer :: idata(10)
   real(8) :: rdata(20)
   
   ...

   ! Listen to incoming connections to the `port` port using
   ! any of the available network interfaces 
   server = listen( port )

   ! Main server loop
   do while( .TRUE. )
      
      ...

      ! Wait for connection requests (blocking)
      socket = accept( server )

      ! Receive some data (blocking)
      ierr = recv( socket, idata ) 
      
      ! Send some data (blocking)
      ierr = recv( socket, rdata ) 
      
      ! Close the socket      
      ierr = disconnect(socket)

      ...

   enddo

   ...


And the client that communicates with it:

.. code-block:: fortran

   use fsocket
   
   integer :: server, port, socket, ierr
   integer :: idata(10)
   real(8) :: rdata(20)
   character(256) :: hostname
   character(32) :: ip
   
   ...


   ! Get server IP from hostname
   ierr = lookup( hostname, ip )

   ! Connect to the server 
   socket = connect( ip, port )

   ! Send some data
   ierr = send( socket, idata )

   ! Receive some data
   ierr = recv( socket, rdata )

   ! Close the socket      
   ierr = disconnect(socket)
   
   ...

 
There is a complete example included with the sources, a client/server
implementation of a naive prime number search. Two different server examples
are included, one blocking and the other one using select.  The server waits
for connections from clients and hands down numbers for the clients to check if
they are primes.  When a client establishes that the number received is a prime,
reports it back to the server. Otherwise, it requests another number. The
server exits when the specified number of primes has been calculated.  The
client exist as soon as there is a connection error (due to network errors,
or because the server is not running).

API Reference
=============

You need to 'use fsocket' to be able to access the public fsocket API. A decent understanding
of the underlying POSIX functions is recommended, but not needed to effectively use fsocket.
All of the functions return -1 on error. A description of the last error can be obtained with 
the *explain* function, which is a shallow interface to the strerror POSIX function. Also, the
POSIX errno can be obtained using the *lerrno* function. 

To learn how to use the API, please see the included test_fsocket_server.f90 and, 
test_fsocket_client.f90 and test_fsocket_select.f90.

FSocket provides the following functions:

.. f:function:: integer function listen( port [, blocking, addr ] )
   
   Create a new socket and listen for connections.
 
   This function is not just and interface to the POSIX *listen* function. It 
   creates a new AF_INET stream socket, sets the socket option for blocking or 
   non-blocking operation as requested, binds the socket to a port and optionally 
   to an ip address, and starts listening. 
 
   :o integer port [in]: The port to bind the socket to (ports below 1024 require root)
   :o logical blocking [default=.true.] [in]: Set to .false. to put the socket in non-blocking mode 
   :o character(*) addr [in]: The ip address to bind the socket to. By default it binds to all
   :r socket: On success, a non-negative integer, the socket file descriptor being listened to. On error -1 and sets errno.


.. f:function:: integer function accept( socket ) 
   
   Accept a new connection on a socket 
 
   :o socket [in]: The listening socket (as returned by successful call to listen)
   :r socket: On success, a non-negative socket for the newly established connection. On error -1 and sets errno.
 
.. f:function:: integer function connect( address, port ) 
   
   Attempt to make a connection and return a socket 
 
   This is a shallow interface to the POSIX *connect* function.
   The IP address can be obtained from a hostname using the lookup function.
 
   :o address [in]: The IP address to connect to
   :o port [in]: The port to connect to
   :r socket: On success, a non-negative integer, the socket for the newly established connection. On error: -1 and sets errno.

.. f:function:: integer function disconnect( socket ) 
   
   Close a connected socket
  
   :o socket [in]: The socket to close
   :r integer: On success: 0. On error: -1 and sets errno.

.. f:function:: integer function send( socket, data )

   Send a message on a connected socket
 
   A call to send on one end of a socket should be matched with the
   equivalent recv on the other end. Equivalent sends and recvs are those
   that are the same size in bytes (but not necessarily the same shape or
   data type). It is the callers responsibility to make sure that the 
   send/recv calls match, fsocket will not make any checks except for 
   available space on recv. 
   :o socket [in]: The socket to send the data to
   :o data [in]: one of: an integer, a double precission, an array from 1 to 7 dimensions of integers or double precisions, or a character string
   :r integer: On success: the number of bytes sent. On error: -1 and sets errno.

.. f:function:: integer function recv( socket, data )

   Recv a message from the connected socket
 
   A call to send on one end of a socket should be matched with the
   equivalent recv on the other end. Equivalent sends and recvs are those
   that are the same size in bytes (but not necessarily the same shape or
   data type). It is the callers responsibility to make sure that the 
   send/recv calls match, fsocket will not make any checks except for 
   available space on recv. 

   :o socket [in]: The socket to received the data from
   :o data [out]: one of: an integer, a double precission, an array from 1 to 7 dimensions of integers or double precisions, or a character string
   :r integer: On success: the number of bytes received. On error: -1 and sets errno.

.. f:function:: integer function select( sockets, timeout_msecs, mask )

   Synchronous I/O multiplexing
   Examing the given sockets and check if they are ready for reading (incoming data),
   writing (when links are not fully duplex), or have an exceptional condition pending.
 
   :o sockets(:) [in]: The sockets that should be checked
   :o timeout_msecs [in]: The call to select will block for this many miliseconds (pass a negative number to block indifinitely)
   :o mask(:) [out]: A bitmask that informs the caller the status of each of the sockets. For example, after the select call, to check for available data on the i-th socket, do
.. code-block: fortran
   if( btest( mask(i), READY_RECV ) ) then ...

   To check for errors on the j-th do

   if( btest( mask(j), READY_ERR ) ) then ...

   The constants READY_RECV, READY_SEND and READY_ERR 
   are defined in the fsocket module.

   :r integer: On success: a non-negative integer. On error: -1 and sets errno.


.. f:function:: integer function lerrno()

   Obtain the POSIX numeric code for the last error.

   :r integer: The last error


.. f:subroutine:: subroutine explain( str [, err ] )
   
   Provide a user-friendly explanation of the last error, and optionally the current value of errno. 
 
   :o str [out]: A description of the last error
   :o err [out,optional]: The POSIX error number 


.. f:function:: integer function lookup( hostname, ip )

   Lookup the IP for the given hostname
 
   If passed "localhost" as hostname, it will try to 
   connect to a global IP to get an external-facing IP
   instead of the customary 127.0.0.1
   Otherwise it will use a standard DNS lookup.

   :o hostname [in]: The hostname whose IP needs to be looked up
   :o ip [out]: On exit, the IP of said hostname on success, or the error description on error.
   :r integer: On success: 0. On error: -1. Does not set errno.

