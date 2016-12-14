/*
  fsocket, fortran interface to sockets
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
*/

#include<stdio.h>
#include<stdlib.h>
#include<unistd.h>
#include<sys/socket.h>
#include<sys/select.h>
#include<arpa/inet.h> //inet_addr
#include<string.h>    //strcpy
#include<netdb.h>     //hostent
#include<fcntl.h>
#include<errno.h>
#include<poll.h>

/* macro to Retry Calls Interrupted by Signals */
#ifndef _RCIS_
#define _RCIS_( _expression_ ) \
  (( { long int _result_;                            \
       do {                                          \
          _result_ = (long int) (_expression_);      \
       } while( _result_ == -1L && errno == EINTR ); \
       _result_;                                     \
     }                                               \
   ))
#endif

int fsocket_explain( int n, char *str ) {
   strncpy( str, strerror(errno), n-1 );
   return 0;
} 

int fsocket_listen( int port, int blocking, char *addr, int *efn, int *eno ) {
   int sck;
   struct sockaddr_in server;
   int n; 
   socklen_t slen; 
   
   *efn = 0;
   *eno = 0;

   sck = socket( AF_INET, SOCK_STREAM, 0 );
   if( sck < 0 ) {
      *efn = 1;
      *eno = errno;
      return -1;
   }

   /* set reuse address option */
   n = 1;
   slen = sizeof(n);
   if( setsockopt( sck, SOL_SOCKET, SO_REUSEADDR, &n, slen ) == -1 ) {
      *efn = 2;
      *eno = errno;
      return -1;
   }

   /* prepare the sockaddr_in structure */
   server.sin_family      = AF_INET;
   if( addr == NULL ) {
      server.sin_addr.s_addr = INADDR_ANY;
   } else {
      inet_aton( addr, &server.sin_addr );
   }
   server.sin_port = htons( port );
     
   /* bind it */
   if( bind( sck, (struct sockaddr *)&server, sizeof(server) ) < 0 ) {
      *efn = 3;
      *eno = errno;
      return -1;
   }

   /* set non-blocking operation if requested */
   if( !blocking ) {
      if( fcntl( sck, F_SETFL, fcntl( sck, F_GETFL, 0 ) | O_NONBLOCK ) < 0 ) {
         *efn = 4;
         *eno = errno;
         return -1;
      }
   }

   /* accepting conns */
   if( listen( sck, SOMAXCONN ) < 0 ) {
      *efn = 5;
      *eno = errno;
      return -1;
   }
   return sck;
}

int fsocket_connect( char *addr, int port, int *efn, int *eno ) {
   int sck;
   struct sockaddr_in server;
   struct pollfd pfd;
   int n;
   socklen_t slen; 
   
   *efn = 0;
   *eno = 0;

   sck = socket(AF_INET, SOCK_STREAM, 0);
   if( sck == -1 ) {
      *efn = 6;
      *eno = errno;
      return -1;
   }

   server.sin_addr.s_addr = inet_addr( addr );
   server.sin_family      = AF_INET;
   server.sin_port        = htons( port );

   /* Start with sck just returned by socket(), blocking, SOCK_STREAM... */
   /* taken from http://www.madore.org/~david/computers/connect-intr.html */
   if( connect ( sck, (struct sockaddr *)&server , sizeof(server) ) == -1 ) {
      if ( errno != EINTR /* && errno != EINPROGRESS */ ) {
         *efn = 7;
         *eno = errno;
         return -1;
      }
      pfd.fd     = sck;
      pfd.events = POLLOUT;
      while ( poll (&pfd, 1, -1) == -1 )
         if ( errno != EINTR ) {
            *efn = 8;
            *eno = errno;
            return -1;
         }
      
      /* check if there was an error */
      slen = sizeof(n);
      if( getsockopt (sck, SOL_SOCKET, SO_ERROR, &n, &slen ) == -1 ) {
         *efn = 9;
         *eno = errno;
         return -1;
      }
      if( n != 0 ) {
         *efn = 10;
         *eno = errno;
         return -1;
      }
   }
   return sck;
}





int fsocket_select( int nsockets, int *sockets, int *mask, int timeout_secs, int timeout_usecs ) {
   fd_set sr, sw, se;
   struct timeval tv;
   int ret, k;

   FD_ZERO(&sr);
   FD_ZERO(&sw);
   FD_ZERO(&se);

   for( int i = 0; i < nsockets; ++i ) {
      if( sockets[i] >= 0 ) {
         FD_SET( sockets[i], &sr );
         FD_SET( sockets[i], &sw );
         FD_SET( sockets[i], &se );
      }
   }

   if( timeout_secs < 0 || timeout_usecs < 0 ) {
      ret = select( FD_SETSIZE, &sr, &sw, &se, NULL ); 
   } else {
      memset(&tv, 0, sizeof(struct timeval));
      tv.tv_sec  = timeout_secs; 
      tv.tv_usec = timeout_usecs; 
      ret = select( FD_SETSIZE, &sr, &sw, &se, &tv ); 
   }

   memset( mask, 0, nsockets );
   for( int i = 0; i < nsockets; ++i ) {
      if( FD_ISSET( sockets[i], &sr ) ) 
         mask[i] |= 1 << 1;
      if( FD_ISSET( sockets[i], &sw ) ) 
         mask[i] |= 1 << 2;
      if( FD_ISSET( sockets[i], &se ) ) 
         mask[i] |= 1 << 3;
      /*printf("-> %d %d %d\n", read[i], FD_ISSET( read[i], &sr ) != -1 );*/
      /*if( read[i] >= 0 && FD_ISSET( read[i], &sr ) ) */
         /*read_mask[i] = 1;*/
   }

   return( ret );
}


int fsocket_close( int sck ) {
   return close(sck);
}

int fsocket_send( int sck, size_t len, void *dat ) {
   return _RCIS_( send( sck, dat, len, MSG_NOSIGNAL ) ); 
}

int fsocket_recv( int sck, size_t len, void *dat ) {
   return _RCIS_( recv( sck, dat, len, MSG_WAITALL ) ); 
}

int fsocket_send_str( int sck, int len, char *dat ) {
   int ret;
   int n = len;
   
   ret = _RCIS_( send( sck,   &n, (size_t) 1*sizeof(int),  MSG_NOSIGNAL ) );
   if( ret < 0 ) {
      perror("send_str int");
      return ret;
   }
   
   ret = _RCIS_( send( sck,  dat, (size_t) n*sizeof(char), MSG_NOSIGNAL ) );
   if( ret < 0 ) {
      perror("send_str str");
      return ret;
   }
   
   return 0;
}

int fsocket_recv_str( int sck, int len, char *dat ) {
   int  n, i, ret;
   char *str;
   int ierr; 
   struct pollfd ufds[1];

   ret = _RCIS_( recv( sck,  &n, (size_t)   1*sizeof(int),  MSG_WAITALL ) );
   if( ret < 0 ) {
      perror( "recv_str int");
      return ret;
   }
   
   str = malloc( n*sizeof(char) );
   if( str == NULL ) return -2;

   ret = _RCIS_( recv( sck, str, (size_t)   n*sizeof(char), MSG_WAITALL ) );
   if( ret < 0 ) {
      perror( "recv_str str");
      free( str );
      return ret;
   }

   strncpy( dat, str, len < n? len : n ); 
   free( str );
   
   return 0;
}

int fsocket_get_localhost_ip( int len, char *ip ) {
   struct sockaddr_in local;
   struct sockaddr_in server;
   socklen_t local_len; 
   size_t alen;
   int sck;
  
   sck = socket(AF_INET, SOCK_DGRAM, 0);
   if( sck == -1 ) 
      return -1;

   server.sin_addr.s_addr = inet_addr( "1.1.1.1" ); // instead of 0.0.0.0 to get out-facing IP, not 127.0.0.1
   server.sin_family      = AF_INET;
   server.sin_port        = htons( 53 );

   if( connect( sck, (struct sockaddr *)&server , sizeof(server)) < 0 ) 
      return -2;

   /* get local socket info */
   local_len = sizeof(local);

   if( getsockname( sck, (struct sockaddr*)&local, &local_len) < 0 ) {
      close(sck);
      return -3;
   }

   /* get the ip address */
   if( inet_ntop( local.sin_family, &(local.sin_addr), ip, len ) == NULL ) {
      return -4;
   }

   /* set excess ip space to blanks spaces */
   alen = strnlen(ip,(size_t)len);
   memset( ip+alen, atoi(" "), len - alen ); 
   return 0;
}

int fsocket_lookup(char *hostname, int len, char *ip) {
   int sockfd;  
   struct addrinfo hints, *servinfo, *p;
   struct sockaddr_in *h;
   size_t alen;
   int rv;

   memset(&hints, 0, sizeof hints);
   hints.ai_family   = AF_UNSPEC;   // use AF_INET6 to force IPv6
   hints.ai_socktype = SOCK_STREAM; // TCP/IP
   
   if ( (rv = getaddrinfo( hostname, NULL, &hints , &servinfo)) != 0) {
      strncpy( ip, gai_strerror(rv), (size_t)len );
      return -1;
   }

   // get the first possible result
   for(p = servinfo; p != NULL; p = p->ai_next) {
      h = (struct sockaddr_in *) p->ai_addr;
      strncpy(ip , inet_ntoa( h->sin_addr ), (size_t)len );
      alen = strnlen(ip,(size_t)len);
      memset( ip+alen, atoi(" "), len - alen ); 
      if( alen > 0 ) break;
   }
   freeaddrinfo(servinfo); 
   return 0;
}


/* checks for incoming connections and returns accepted connection socket */
int fsocket_accept( int sck ) {
   struct sockaddr_in client;
   int n;

   /* non-blocking context ! */
   n = sizeof(struct sockaddr_in);

   /* < 0 indicates error */
   return accept( sck, (struct sockaddr *)&client, (socklen_t*)&n );
}

