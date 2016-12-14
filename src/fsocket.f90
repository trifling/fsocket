!
! fsocket, fortran interface to sockets
! Copyright (C) 2014 Daniel Pena 
!
! This program is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with this program. If not, see <http://www.gnu.org/licenses/>.
!

module fsocket
   use iso_c_binding

   implicit none

   private

   integer, parameter :: READY_RECV = 1
   integer, parameter :: READY_SEND = 2
   integer, parameter :: READY_ERR  = 3
   character(32) :: errfn
   integer       :: errno

   public :: send, recv, listen, select, accept, connect, disconnect, explain, lerrno
   public :: READY_RECV, READY_SEND, READY_ERR
   public :: lookup

   interface 

      function fsocket_connect( addr, port, efn, eno ) bind(C,name="fsocket_connect")
         use iso_c_binding
         character(c_char)     :: addr(*)
         integer(c_int), value :: port
         integer(c_int)        :: efn, eno
         integer(c_int)        :: fsocket_connect
      end function fsocket_connect
      
      function fsocket_disconnect( sckt ) bind(C,name="fsocket_close")
         use iso_c_binding
         integer(c_int), value :: sckt 
         integer(c_int)        :: fsocket_disconnect
      end function fsocket_disconnect

      function fsocket_select( nsockets, sockets, mask, secs, usecs )  bind(C,name="fsocket_select")
         use iso_c_binding
         integer(c_int), value :: nsockets, secs, usecs
         integer(c_int) :: sockets(nsockets), mask(nsockets)
         integer(c_int) :: fsocket_select
      end function fsocket_select
 
      function fsocket_explain( siz, str ) bind(C,name="fsocket_explain")
         use iso_c_binding
         integer(c_int), value :: siz 
         character(c_char)     :: str(*)
         integer :: fsocket_explain
      end function fsocket_explain

      function fsocket_listen( port, blocking, addr, efn, eno )  bind(C,name="fsocket_listen")
         use iso_c_binding
         integer(c_int), value :: port, blocking
         character(c_char)     :: addr(*)
         integer(c_int)        :: efn, eno
         integer(c_int)        :: fsocket_listen 
      end function fsocket_listen
 
      function fsocket_accept( sckt )  bind(C,name="fsocket_accept")
         use iso_c_binding
         integer(c_int), value :: sckt
         integer(c_int)        :: fsocket_accept
      end function fsocket_accept

      function fsocket_send( sckt, siz, dat ) bind(C,name="fsocket_send")
         use iso_c_binding
         integer(c_int), value    :: sckt
         integer(c_size_t), value :: siz
         type(c_ptr), value       :: dat
         integer(c_int)           :: fsocket_send
      end function fsocket_send

      function fsocket_recv( sckt, siz, dat ) bind(C,name="fsocket_recv")
         use iso_c_binding
         integer(c_int), value    :: sckt
         integer(c_size_t), value :: siz
         type(c_ptr), value       :: dat
         integer(c_int)           :: fsocket_recv
      end function fsocket_recv

      function fsocket_send_str( sckt, n, dat ) bind(C,name="fsocket_send_str")
         use iso_c_binding
         integer(c_int), value :: sckt
         integer(c_int), value :: n
         !type(c_ptr), value    :: dat
         character(c_char)     :: dat(*)
         integer(c_int)        :: fsocket_send_str
      end function fsocket_send_str

      function fsocket_recv_str( sckt, n, dat ) bind(C,name="fsocket_recv_str")
         use iso_c_binding
         integer(c_int), value :: sckt 
         integer(c_int), value :: n 
         !type(c_ptr), value    :: dat
         character(c_char)     :: dat(*)
         integer(c_int)        :: fsocket_recv_str
      end function fsocket_recv_str

      function fsocket_lookup( hostname, n, ip ) bind(C,name="fsocket_lookup")
         use iso_c_binding
         character(c_char)     :: hostname(*)
         character(c_char)     :: ip(*)
         integer(c_int), value :: n 
         integer(c_int)        :: fsocket_lookup
      end function fsocket_lookup

      function fsocket_get_localhost_ip( n, ip ) bind(C,name="fsocket_get_localhost_ip")
         use iso_c_binding
         character(c_char)     :: ip(*)
         integer(c_int), value :: n 
         integer(c_int)        :: fsocket_get_localhost_ip 
      end function fsocket_get_localhost_ip

   end interface

   interface send 
      module procedure sdp0, sdp1, sdp2, sdp3, sdp4, sdp5, sdp6, sdp7
      module procedure si0,  si1,  si2,  si3,  si4,  si5,  si6,  si7
      module procedure send_str
   end interface send

   interface recv 
      module procedure rdp0, rdp1, rdp2, rdp3, rdp4, rdp5, rdp6, rdp7
      module procedure ri0,  ri1,  ri2,  ri3,  ri4,  ri5,  ri6,  ri7
      module procedure recv_str
   end interface recv

contains

   integer function connect( address, port ) 
!B Attempt to make a connection and return a socket 
!
!D The IP address can be obtained from a hostname using the lookup function.
!
!R On success: a non-negative integer, the socket for the newly established connection. 
!R On error: -1. Sets errno.
      character(*), intent(in) :: address
         !P The IP address to connect to
      integer, intent(in)      :: port
         !P The port to connect to.

      integer :: efn, eno
      connect = fsocket_connect( address, port, efn, eno )
      if( connect == -1 ) then
         select case(efn)
         case(6) 
            errfn = 'socket: '
         case(7) 
            errfn = 'connect: '
         case(8) 
            errfn = 'poll: '
         case(9) 
            errfn = 'getsockopt: '
         case default
            errfn = 'unknown: '
         end select
      endif
   end function connect

   integer function disconnect( socket ) 
!B Close a connected socket
!
!R On success: 0. 
!R On error: -1. Sets errno.
      integer, intent(in) :: socket
         !P The socket to be closed
      disconnect = fsocket_disconnect( socket )
      errfn = 'close'
   end function disconnect

   integer function accept( socket ) 
!B Accept a new connection on a socket 
!
!R On success: a non-negative socket for the newly established connection. 
!R On error: -1. Sets errno. 
      integer, intent(in) :: socket
         !P The listening socket
      accept = fsocket_accept( socket )
      errfn = 'accept'
   end function accept

   integer function select( sockets, timeout_msecs, mask )
      integer, intent(in)  :: sockets(:)
      integer, intent(in)  :: timeout_msecs
      integer, intent(out) :: mask(:)

      integer :: secs, usecs, n

      secs  = timeout_msecs / 1000
      usecs = mod(timeout_msecs,1000) * 1000

      n = size(sockets)

      select = fsocket_select( n, sockets, mask, secs, usecs )
      
      errfn = 'select'
   end function select

   integer function lerrno()
!B Obtain the POSIX numeric code for the last error.
!
!R The current value of errno variable.
      lerrno = errno
   end function lerrno

   subroutine explain( str, err )
!B Provide a user-friendly explanation of the last error, and optionally the current value of errno. 
      character(*), intent(out) :: str 
         !P On exit, the error explanation 
      integer, intent(out), optional :: err 
         !P On exit, the POSIX error number 
      
      integer :: ierr
      character(len=len(str)) :: tmp

      ierr = fsocket_explain( len(tmp), tmp )
      str  = trim(errfn) // ' ' // tmp
      if( present(err) ) then
         err = errno
      endif
   end subroutine explain

   integer function listen( port, blocking, addr ) 
!B Create a new socket and listen for connections.
!
!D This function is not just and interface to the POSIX *listen* function. It 
!D creates a new AF_INET stream socket, sets the socket option for blocking or 
!D non-blocking operation as requested, binds the socket to a port and optionally 
!D to an ip address, and starts listening. 
!
!R On success: a non-negative integer, the socket file descriptor being listened to. 
!R On error: -1. Sets errno. 
      integer, intent(in) :: port                
         !P the port to bind the socket to (ports below 1024 require root)
      logical, intent(in), optional :: blocking  
         !P set to .false. to put the socket in non-blocking mode (default: .true.)
      character(*), intent(in), optional :: addr 
         !P the ip address to bind the socket to. By default it binds to all
         !P network interfaces. This can also be achieved passing the "0.0.0.0" address. 

      character(33) :: a
      integer :: b, efn, eno

      if( present(addr) ) then
         a = trim(addr(1:len(a)-1))//C_NULL_CHAR 
      else
         a = C_NULL_CHAR
      endif
      if( present(blocking) ) then
         if( blocking ) then
            b = 1
         else
            b = 0 
         endif
      else
         b = 1
      endif
      listen = fsocket_listen( port, b, a, efn, eno )
      if( listen == -1 ) then
         select case(efn)
         case(1) 
            errfn = 'socket: '
         case(2) 
            errfn = 'setsockopt: '
         case(3) 
            errfn = 'bind: '
         case(4) 
            errfn = 'fcntl: '
         case(5) 
            errfn = 'listen: '
         case default
            errfn = 'unknown: '
         end select
      endif
   end function listen

   integer function lookup( hostname, ip )
!B Lookup the IP for the given hostname
!
!D If passed "localhost" as hostname, it will try to 
!D connect to a global IP to get an external-facing IP
!D instead of the customary 127.0.0.1
!D Otherwise it will use a standard DNS lookup.
!
!R On success: 0. 
!R On error: -1. Does not set errno.
      character(*), intent(in) :: hostname
         !P The hostname whose IP needs to be looked up
      character(*), intent(out) :: ip
         !P The IP of said hostname on success, or the error description on error.

      integer :: n
      if( trim(hostname) == 'localhost' ) then
         lookup = fsocket_get_localhost_ip( len(ip), ip )
      else
         n = len(ip)
         lookup = fsocket_lookup( trim(hostname)//C_NULL_CHAR, n, ip )
      endif
   end function lookup






   integer function rdp0( sckt, dat ) 
      integer                   :: sckt
      double precision, target  :: dat
      integer(c_size_t)         :: n

      n    = sizeof(0.0D0)
      rdp0 = fsocket_recv( sckt, n, c_loc(dat) )
   end function rdp0
   integer function rdp1( sckt, dat ) 
      integer                   :: sckt
      double precision, target  :: dat(:)
      integer(c_size_t)         :: n

      n    = product(shape(dat))*sizeof(0.0D0)
      rdp1 = fsocket_recv( sckt, n, c_loc(dat) )
   end function rdp1
   integer function rdp2( sckt, dat ) 
      integer                   :: sckt
      double precision, target  :: dat(:,:)
      integer(c_size_t)         :: n

      n    = product(shape(dat))*sizeof(0.0D0)
      rdp2 = fsocket_recv( sckt, n, c_loc(dat) )
   end function rdp2
   integer function rdp3( sckt, dat ) 
      integer                   :: sckt
      double precision, target  :: dat(:,:,:)
      integer(c_size_t)         :: n

      n    = product(shape(dat))*sizeof(0.0D0)
      rdp3 = fsocket_recv( sckt, n, c_loc(dat) )
   end function rdp3
   integer function rdp4( sckt, dat ) 
      integer                   :: sckt
      double precision, target  :: dat(:,:,:,:)
      integer(c_size_t)         :: n

      n    = product(shape(dat))*sizeof(0.0D0)
      rdp4 = fsocket_recv( sckt, n, c_loc(dat) )
   end function rdp4
   integer function rdp5( sckt, dat ) 
      integer                   :: sckt
      double precision, target  :: dat(:,:,:,:,:)
      integer(c_size_t)         :: n

      n    = product(shape(dat))*sizeof(0.0D0)
      rdp5 = fsocket_recv( sckt, n, c_loc(dat) )
   end function rdp5
   integer function rdp6( sckt, dat ) 
      integer                   :: sckt
      double precision, target  :: dat(:,:,:,:,:,:)
      integer(c_size_t)         :: n

      n    = product(shape(dat))*sizeof(0.0D0)
      rdp6 = fsocket_recv( sckt, n, c_loc(dat) )
   end function rdp6
   integer function rdp7( sckt, dat ) 
      integer                   :: sckt
      double precision, target  :: dat(:,:,:,:,:,:,:)
      integer(c_size_t)         :: n

      n    = product(shape(dat))*sizeof(0.0D0)
      rdp7 = fsocket_recv( sckt, n, c_loc(dat) )
   end function rdp7




   integer function ri0( sckt, dat ) 
      integer           :: sckt
      integer, target   :: dat
      integer(c_size_t) :: n

      n   = sizeof(0)
      ri0 = fsocket_recv( sckt, n, c_loc(dat) )
   end function ri0
   integer function ri1( sckt, dat ) 
      integer           :: sckt
      integer, target   :: dat(:)
      integer(c_size_t) :: n

      n   = product(shape(dat))*sizeof(0)
      ri1 = fsocket_recv( sckt, n, c_loc(dat) )
   end function ri1
   integer function ri2( sckt, dat ) 
      integer           :: sckt
      integer, target   :: dat(:,:)
      integer(c_size_t) :: n

      n   = product(shape(dat))*sizeof(0)
      ri2 = fsocket_recv( sckt, n, c_loc(dat) )
   end function ri2
   integer function ri3( sckt, dat ) 
      integer           :: sckt
      integer, target   :: dat(:,:,:)
      integer(c_size_t) :: n

      n   = product(shape(dat))*sizeof(0)
      ri3 = fsocket_recv( sckt, n, c_loc(dat) )
   end function ri3
   integer function ri4( sckt, dat ) 
      integer           :: sckt
      integer, target   :: dat(:,:,:,:)
      integer(c_size_t) :: n

      n   = product(shape(dat))*sizeof(0)
      ri4 = fsocket_recv( sckt, n, c_loc(dat) )
   end function ri4
   integer function ri5( sckt, dat ) 
      integer           :: sckt
      integer, target   :: dat(:,:,:,:,:)
      integer(c_size_t) :: n

      n   = product(shape(dat))*sizeof(0)
      ri5 = fsocket_recv( sckt, n, c_loc(dat) )
   end function ri5
   integer function ri6( sckt, dat ) 
      integer           :: sckt
      integer, target   :: dat(:,:,:,:,:,:)
      integer(c_size_t) :: n

      n   = product(shape(dat))*sizeof(0)
      ri6 = fsocket_recv( sckt, n, c_loc(dat) )
   end function ri6
   integer function ri7( sckt, dat ) 
      integer           :: sckt
      integer, target   :: dat(:,:,:,:,:,:,:)
      integer(c_size_t) :: n

      n   = product(shape(dat))*sizeof(0)
      ri7 = fsocket_recv( sckt, n, c_loc(dat) )
   end function ri7

   function recv_str( sckt, str )
      integer              :: sckt
      character(*), target :: str
      integer              :: recv_str
      integer              :: n

      n   = len(str) 
      str = ''
      recv_str = fsocket_recv_str( sckt, n, str )
   end function recv_str

    integer function recv_raw( sckt, n, dat )
      integer                   :: sckt
      integer(c_size_t)         :: n
      character(c_char), target :: dat(:)
      recv_raw = fsocket_recv( sckt, n, c_loc(dat) )
   end function recv_raw



   integer function sdp0( sckt, dat ) 
      integer                   :: sckt
      double precision, target  :: dat
      integer(c_size_t)         :: n

      n    = sizeof(0.0D0)
      sdp0 = fsocket_send( sckt, n, c_loc(dat) )
   end function sdp0
   integer function sdp1( sckt, dat ) 
      integer                   :: sckt
      double precision, target  :: dat(:)
      integer(c_size_t)         :: n

      n    = product(shape(dat))*sizeof(0.0D0)
      sdp1 = fsocket_send( sckt, n, c_loc(dat) )
   end function sdp1
   integer function sdp2( sckt, dat ) 
      integer                   :: sckt
      double precision, target  :: dat(:,:)
      integer(c_size_t)         :: n

      n    = product(shape(dat))*sizeof(0.0D0)
      sdp2 = fsocket_send( sckt, n, c_loc(dat) )
   end function sdp2
   integer function sdp3( sckt, dat ) 
      integer                   :: sckt
      double precision, target  :: dat(:,:,:)
      integer(c_size_t)         :: n

      n    = product(shape(dat))*sizeof(0.0D0)
      sdp3 = fsocket_send( sckt, n, c_loc(dat) )
   end function sdp3
   integer function sdp4( sckt, dat ) 
      integer                   :: sckt
      double precision, target  :: dat(:,:,:,:)
      integer(c_size_t)         :: n

      n    = product(shape(dat))*sizeof(0.0D0)
      sdp4 = fsocket_send( sckt, n, c_loc(dat) )
   end function sdp4
   integer function sdp5( sckt, dat ) 
      integer                   :: sckt
      double precision, target  :: dat(:,:,:,:,:)
      integer(c_size_t)         :: n

      n    = product(shape(dat))*sizeof(0.0D0)
      sdp5 = fsocket_send( sckt, n, c_loc(dat) )
   end function sdp5
   integer function sdp6( sckt, dat ) 
      integer                   :: sckt
      double precision, target  :: dat(:,:,:,:,:,:)
      integer(c_size_t)         :: n

      n    = product(shape(dat))*sizeof(0.0D0)
      sdp6 = fsocket_send( sckt, n, c_loc(dat) )
   end function sdp6
   integer function sdp7( sckt, dat ) 
      integer                   :: sckt
      double precision, target  :: dat(:,:,:,:,:,:,:)
      integer(c_size_t)         :: n

      n    = product(shape(dat))*sizeof(0.0D0)
      sdp7 = fsocket_send( sckt, n, c_loc(dat) )
   end function sdp7





   integer function si0( sckt, dat ) 
      integer           :: sckt
      integer, target   :: dat
      integer(c_size_t) :: n

      n   = sizeof(0)
      si0 = fsocket_send( sckt, n, c_loc(dat) )
   end function si0
   integer function si1( sckt, dat ) 
      integer           :: sckt
      integer, target   :: dat(:)
      integer(c_size_t) :: n

      n   = product(shape(dat))*sizeof(0)
      si1 = fsocket_send( sckt, n, c_loc(dat) )
   end function si1
   integer function si2( sckt, dat ) 
      integer           :: sckt
      integer, target   :: dat(:,:)
      integer(c_size_t) :: n

      n   = product(shape(dat))*sizeof(0)
      si2 = fsocket_send( sckt, n, c_loc(dat) )
   end function si2
   integer function si3( sckt, dat ) 
      integer           :: sckt
      integer, target   :: dat(:,:,:)
      integer(c_size_t) :: n

      n   = product(shape(dat))*sizeof(0)
      si3 = fsocket_send( sckt, n, c_loc(dat) )
   end function si3
   integer function si4( sckt, dat ) 
      integer           :: sckt
      integer, target   :: dat(:,:,:,:)
      integer(c_size_t) :: n

      n   = product(shape(dat))*sizeof(0)
      si4 = fsocket_send( sckt, n, c_loc(dat) )
   end function si4
   integer function si5( sckt, dat ) 
      integer           :: sckt
      integer, target   :: dat(:,:,:,:,:)
      integer(c_size_t) :: n

      n   = product(shape(dat))*sizeof(0)
      si5 = fsocket_send( sckt, n, c_loc(dat) )
   end function si5
   integer function si6( sckt, dat ) 
      integer           :: sckt
      integer, target   :: dat(:,:,:,:,:,:)
      integer(c_size_t) :: n

      n   = product(shape(dat))*sizeof(0)
      si6 = fsocket_send( sckt, n, c_loc(dat) )
   end function si6
   integer function si7( sckt, dat ) 
      integer           :: sckt
      integer, target   :: dat(:,:,:,:,:,:,:)
      integer(c_size_t) :: n

      n   = product(shape(dat))*sizeof(0)
      si7 = fsocket_send( sckt, n, c_loc(dat) )
   end function si7

   function send_str( sckt, str )
      integer              :: sckt
      character(*), target :: str
      integer              :: send_str
      integer              :: n

      n = len_trim(str)
      send_str = fsocket_send_str( sckt, n, str )
   end function send_str

   integer function send_raw( sckt, dat ) 
      integer                   :: sckt
      integer(c_size_t)         :: n
      character(c_char), target :: dat(:)
      n = size(dat)*sizeof(c_char)
      send_raw = fsocket_send( sckt, n, c_loc(dat) )
   end function send_raw

end module fsocket

