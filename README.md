# fsocket

A Fortran interface to POSIX stream sockets.

## Synopsis

The fsocket library provides a high level easy to use Fortran 90 interface to
POSIX stream sockets in blocking or non-blocking mode, which allows for an
effortless implementation of network communication in Fortran programs. 

Functions are provided for listening, selecting and connecting, sending and
receiving integer and double arrays and strings, and ip lookup by hostname.

## Motivation 

fsocket was originally written to be used implementing parallel scientific
codes, but it can be used by any program that needs stream sockets. 

Most often Fortran parallel scientific codes are implemented with MPI or OpenMP
as the parallelization paradigm. In general, this is the most straightforward
and painless way to go, but there are circumstances where a direct
client/server or cloud paradigm might be preferable, or special circumstances
demand especial measures.  

For example, the fsocket library has been used in a minimization code that
needed to run in a busy supercomputer for weeks. At each step of the
minimization a set of heterogeneous quantities needed to be computed. With the
ad-hoc parallelization implemented with the help of fsocket, it was easy to add
or remove processes to a pool of workers that was automatically managed using
the standard batch queue system of the supercomputers where it run. This code
could go on unattended for weeks, asking for resources and adapting to its
environment, with process-level fault tolerance built-in.

A solution with the same degree of fault-tolerance built-in is relatively
tricky to achieve using MPI, for example. And not only because of MPI itself,
but for the environment where the code is to be run: most job schedulers at
supercomputers require the number of processes to be declared in advance for
MPI runs, and it is not possible to change it once the program has been
launched. Also, many batch systems are designed in such a way that it is much
easier to get computing time launching many self-declared short-lived
single-cpu processes as resources become free, than big MPI runs.

## Code Example

In a client/server paradigm, the server would look something like:
```fortran

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

```

And the client that communicates with it:
```fortran

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

```
 
There is a complete example included with the sources, a client/server
implementation of a naive prime number search. Two different server examples
are included, one blocking and the other one using select.  The server waits
for connections from clients and hands down numbers for the clients to check if
they are primes.  When a client establishes that the number received is a prime,
reports it back to the server. Otherwise, it requests another number. The
server exits when the specified number of primes has been calculated.  The
client exist as soon as there is a connection error (due to network errors,
or because the server is not running).

## Usage and installation

fsocket can be built into a static or dynamic library using cmake.

For example, to build and install a dynamic version of fsocket in the user's $HOME directory:

```bash
$ mkdir bld && cd bld && cmake -DCMAKE_INSTALL_PREFIX=$HOME ../ && make && make install && cd ..
``` 

This will install libfsocket.so into $HOME/lib, a module file fsocket.mod into $HOME/include, and
the example programs into $HOME/bin.

## API Reference

You need to 'use fsocket' to be able to access the public fsocket API. A decent understanding
of the underlying POSIX functions is recommended, but not needed to effectively use fsocket.
All of the functions return -1 on error. A description of the last error can be obtained with 
the *explain* function, which is a shallow interface to the strerror POSIX function. Also, the
POSIX errno can be obtained using the *lerrno* function. 

To learn how to use the API, please see the included test_fsocket_server.f90 and, 
test_fsocket_client.f90 and test_fsocket_select.f90.

fsocket provides the following functions:

```fortran
integer function listen( port, blocking, addr ) 

! DESCRIPTION
!  Create a new socket and listen for connections.
!
!  This function is not just and interface to the POSIX *listen* function. It 
!  creates a new AF_INET stream socket, sets the socket option for blocking or 
!  non-blocking operation as requested, binds the socket to a port and optionally 
!  to an ip address, and starts listening. 
 
! PARAMETERS
   integer, intent(in) :: port                ! The port to bind the socket to (ports below 1024 require root)
   logical, intent(in), optional :: blocking  ! OPTIONAL: Set to .false. to put the socket in non-blocking mode (default: .true.)
   character(*), intent(in), optional :: addr ! OPTIONAL: The ip address to bind the socket to. By default it binds to all

! RETURNS
!  On success: a non-negative integer, the socket file descriptor being listened to. 
!  On error: -1. Sets errno. 
```

```fortran
integer function accept( socket ) 

! DESCRIPTION 
! Accept a new connection on a socket 
 
! PARAMETERS   
   integer, intent(in) :: socket ! The listening socket (as returned by successful call to listen)
 
! RETURNS
!  On success: a non-negative socket for the newly established connection. 
!  On error: -1. Sets errno. 
```

```fortran
integer function connect( address, port ) 

! DESCRIPTION 
! Attempt to make a connection and return a socket 
!
! This is a shallow interface to the POSIX *connect* function.
! The IP address can be obtained from a hostname using the lookup function.
 
! PARAMETERS
   character(*), intent(in) :: address ! The IP address to connect to
   integer, intent(in)      :: port    ! The port to connect to
  
! RETURNS
! On success: a non-negative integer, the socket for the newly established connection. 
! On error: -1. Sets errno.
```

```fortran
integer function disconnect( socket ) 

! DESCRIPTION 
! Close a connected socket
  
! PARAMETERS   
   integer, intent(in) :: socket ! The socket to close
 
! RETURNS
!  On success: 0. 
!  On error: -1. Sets errno.
```

```fortran
integer function send( socket, data )

! DESCRIPTION
!  Send a message on a connected socket
!
!  A call to send on one end of a socket should be matched with the
!  equivalent recv on the other end. Equivalent sends and recvs are those
!  that are the same size in bytes (but not necessarily the same shape or
!  data type). It is the callers resposability to make sure that the 
!  send/recv calls match, fsocket will not make any checks except for 
!  available space on recv. 

! PARAMETERS  
   integer, intent(in) :: socket ! The socket to send the data to

!  data shall be one of: an integer, a double precission, an array from 1 to 7
!  dimensions of integers or double precisions, or a character string

! RETURNS
!  On success: the number of bytes sent
!  On error: -1. Sets errno
```

```fortran
integer function recv( socket, data )

! DESCRIPTION
!  Recv a message from the connected socket
!
!  A call to send on one end of a socket should be matched with the
!  equivalent recv on the other end. Equivalent sends and recvs are those
!  that are the same size in bytes (but not necessarily the same shape or
!  data type). It is the callers responsibility to make sure that the 
!  send/recv calls match, fsocket will not make any checks except for 
!  available space on recv. 

! PARAMETERS  
   integer, intent(in) :: socket ! The socket to received the data from

!  data shall be one of: an integer, a double precission, an array from 1 to 7
!  dimensions of integers or double precisions, or a character string

! RETURNS
!  On success: the number of bytes received 
!  On error: -1. Sets errno
```

```fortran
integer function select( sockets, timeout_msecs, mask )

! DESCRIPTION
! Synchronous I/O multiplexing
! Examing the given sockets and check if they are ready for reading (incoming data),
! writing (when links are not fully duplex), or have an exceptional condition pending.
 
! PARAMETERS   
   integer, intent(in)  :: sockets(:)     ! The sockets that should be checked
   integer, intent(in)  :: timeout_msecs  ! The call to select will block for this many miliseconds 
                                          ! (pass a negative number to block indifinitely)
   integer, intent(out) :: mask(:)        ! A bitmask that informs the caller the status of each of the 
                                          ! sockets. For example, after the select call, to check for 
                                          ! available data on the i-th socket, do
                                          ! 
                                          ! if( btest( mask(i), READY_RECV ) ) then ...
                                          ! 
                                          ! To check for errors on the j-th do
                                          !
                                          ! if( btest( mask(j), READY_ERR ) ) then ...
                                          !
                                          ! The constants READY_RECV, READY_SEND and READY_ERR 
                                          ! are defined in the fsocket module.

! RETURNS
!  On success: a non-negative integer. 
!  On error: -1. Sets errno. 
```

```fortran
integer function lerrno()

! DESCRIPTION
!  Obtain the POSIX numeric code for the last error.
 
! RETURNS
!  The last error
```

```fortran
subroutine explain( str, err )

! DESCRIPTION
!  Provide a user-friendly explanation of the last error, and optionally the current value of errno. 
 
! PARAMETERS
   character(*), intent(out) :: str        ! On exit, a description of the last error
   integer, intent(out), optional :: err   ! On exit, the POSIX error number 
```

```fortran
integer function lookup( hostname, ip )

! DESCRIPTION
!  Lookup the IP for the given hostname
!
!  If passed "localhost" as hostname, it will try to 
!  connect to a global IP to get an external-facing IP
!  instead of the customary 127.0.0.1
!  Otherwise it will use a standard DNS lookup.

! PARAMETERS
   character(*), intent(in) :: hostname ! The hostname whose IP needs to be looked up
   character(*), intent(out) :: ip      ! On exit, the IP of said hostname on success, or the error description on error.
 
! RETURNS
!  On success: 0. 
!  On error: -1. Does not set errno.
```


## GNU General Public License

fsocket, a Fortran interface to POSIX stream sockets 

Copyright (C) 2014 Daniel Pena 

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

