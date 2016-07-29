program test_fsocket_select

! Calculate a bunch of primes of 9 digit primes using unmanaged client processes 
! Server using select
 
   use fsocket

   ! network constants
   integer, parameter :: REQUEST_INTEGER = 0
   integer, parameter :: REPORT_PRIME = 1
   integer, parameter :: NMAXSOCKETS = 1000

   ! number of primes to calculate
   integer, parameter :: NPRIMES = 1000

   integer :: server, socket, port = 4321
   integer :: prime, primes(NPRIMES) = 0
   integer :: iprimes = 0
   integer :: counter = 100000001
   integer :: icmd, ierr
   integer :: sockets(NMAXSOCKETS)
   integer :: mask(NMAXSOCKETS)
   integer :: idx(1), i

   ! Set up
   sockets = -1
   mask = 0

   ! Start listening to port (non-blocking)
   server = listen( port, .false. )
   sockets(1) = server

   ! Start main server loop
   do while( .TRUE. )

      ! Check if we are finished
      if( count( primes /= 0 ) >= NPRIMES ) exit

      ! Select on all sockets, block
      ierr = select( sockets, -1, mask ) 

      ! Check if listening socket needs attention
      if( mask(1) /= 0 ) then

         ! Accept connection
         socket = accept( server )
         
         ! Find free read and write position in select sockets array
         idx = minloc( sockets )
         sockets(idx(1)) = socket

      endif

      ! Check for incoming data 
      do i = 2, NMAXSOCKETS

         if( mask(i) == 0 ) cycle
         
         socket = sockets(i)

         if( btest(mask(i),READY_RECV) ) then

            ! Get communication command from the client
            ierr = recv( socket, icmd ) 
            if( ierr == 0 ) then ! socket closed 
               ierr = disconnect(socket)
               sockets(i) = -1
               cycle
            else if( ierr < 0 ) then ! error, retry
               cycle
            endif 

            ! Handle the received command
            select case( icmd )

               ! If a client requests a number, send the current 
               ! one and increment the counter 
               case( REQUEST_INTEGER )
                  ierr = send( socket, counter )
                  if( ierr < 0 ) then
                     cycle 
                  endif
                  counter = counter + 1

               ! If a client wishes to report a prime, get it 
               ! and update the primes array
               case( REPORT_PRIME )
                  ierr = recv( socket, prime )
                  if( ierr < 0 ) cycle
                  primes( minloc(primes) ) = prime

            end select
         
         endif

      enddo

   enddo

   write(*,*) 'Found primes' 
   write(*,'(i10)') primes

end program test_fsocket_select

