program test_fsocket_client
   
   use fsocket

   ! network constants
   integer, parameter :: REQUEST_INTEGER = 0
   integer, parameter :: REPORT_PRIME = 1

   character(32)  :: ip 
   character(256) :: hostname = 'localhost'
   integer :: socket, port = 4321
   integer :: icmd, ierr
   integer :: number

   ! Get hostname from the arguments
   if( command_argument_count() < 1 ) then
      write(*,*) 'Assuming "'//trim(hostname)//'" as hostname' 
   else
      call get_command_argument( 1, hostname )
   endif

   ! Get IP from hostname
   ierr = lookup( hostname, ip )
   if( ierr < 0 ) then
      stop 'Unknown hostname'
   endif

   ! Start main client loop
   do while( .TRUE. )

      ! Connect to the server and request an integer, retry on error
      socket = connect( ip, port )
      if( socket < 0 ) exit

      ierr = send( socket, REQUEST_INTEGER )
      if( ierr < 0 ) cycle

      ierr = recv( socket, number )
      if( ierr < 0 ) cycle

      ierr = disconnect(socket)

      ! Check if the number is prime
      if( is_prime( number ) ) then

         ! If it is, then inform the server
         socket = connect( ip, port )
         if( socket < 0 ) exit

         ierr = send( socket, REPORT_PRIME )
         if( ierr < 0 ) cycle

         ierr = send( socket, number )
         if( ierr < 0 ) cycle
         
         ierr = disconnect(socket)

         write(*,*) 'Found Prime: ', number
      endif

   enddo

contains

   logical function is_prime(n)
      integer, intent(in) :: n
      integer :: i

      is_prime = .false.
      if( n <= 1 ) return 
      if( n == 2 .or. n == 3 ) goto 10
      
      ! check if divisible by 2
      if( mod(n,2) == 0) return
      
      ! check if divisible by 3, 5, ..., n/2-1
      do i = 3, n/2-1, 2
         if( mod(n,i) == 0) return
      enddo
   10 is_prime = .true.
   end function is_prime

end program test_fsocket_client
