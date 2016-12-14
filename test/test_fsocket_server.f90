program test_fsocket_server

! Calculate a bunch of primes of 9 digit primes using unmanaged client processes 
! Server
 
   use fsocket

   ! network constants
   integer, parameter :: REQUEST_INTEGER = 0
   integer, parameter :: REPORT_PRIME = 1

   ! number of primes to calculate
   integer, parameter :: NPRIMES = 1000

   integer :: server, socket, port = 4321
   integer :: prime, primes(NPRIMES) = 0
   integer :: iprimes = 0
   integer :: counter = 100000001
   integer :: icmd, ierr
   character(1024) :: str

   ! Start listening to port (blocking)
   server = listen( port, .true. )
   if( server == -1 ) then
      call explain( str )
      write(*,*) 'Error: ', str
      stop
   endif

   ! Start main server loop
   do while( .TRUE. )

      ! Check if we are finished
      if( count( primes /= 0 ) >= NPRIMES ) exit

      ! Wait for connection requests (blocking)
      socket = accept( server )
      if( socket == -1 ) cycle

      ! Get communication command from the client (blocking)
      ierr = recv( socket, icmd ) 
      if( ierr == -1 ) cycle
      
      ! Handle the received command
      select case( icmd )

         ! If a client requests a number, send the current 
         ! one and increment the counter 
         case( REQUEST_INTEGER )
            ierr = send( socket, counter )
            if( ierr < 0 ) cycle 
            counter = counter + 1

         ! If a client wishes to report a prime, get it 
         ! and update the primes array
         case( REPORT_PRIME )
            ierr = recv( socket, prime )
            if( ierr < 0 ) cycle
            primes( minloc(primes) ) = prime

      end select
      
      ! Close the socket      
      ierr = disconnect(socket)

   enddo

   write(*,*) 'Found primes' 
   write(*,'(i10)') primes

end program test_fsocket_server

