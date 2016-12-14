
.. _`GPL-3.0`: https://opensource.org/licenses/GPL-3.0

FSocket README
==============
 
A Fortran 90 interface to POSIX stream sockets.

FSocket is licensed under the `GPL-3.0`_ (see the LICENSE file for details).

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
implementation of a naive prime number search.

   
Compilation and installation
============================

FSocket uses cmake as build system. To build and install a dynamic version of FSocket in /usr/local:

.. code-block:: bash
   $ mkdir bld 
   $ cd bld 
   $ cmake -DCMAKE_INSTALL_PREFIX=/usr/local ../ 
   $ make 
   $ make install


Documentation
-------------

Documentation is available at http://trifling-matters.com/fsocket.html.

The documentation source is in the ``doc/`` subdirectory, requires 
Sphinx and is built automatically when compiling. To view it, point your to 
browser to ``doc/bld/index.html`` from your build directory. 

