#include <cstdlib>
#include <iostream>
#include <sstream>
#include <cstring>
#include <errno.h>
#include "socket.h"

template<typename T>
std::string to_string(T n)
{
  std::stringstream ss;
  ss << n;
	return ss.str();
}

Socket::Socket()
	: m_sock(0)
{
}

Socket::~Socket()
{
	if(is_valid()) ::close(m_sock);
}

bool Socket::create()
{
	if((m_sock = socket(AF_INET, SOCK_STREAM, 0)) < 0)
	{
		std::cerr << "Failed to create TCP socket: " << strerror(errno) << std::endl;
		exit(1);
	}
	
	m_socket_type = SOCK_STREAM;
	return true;
}

bool Socket::UDP_create()
{
	if((m_sock = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
	{
		std::cerr << "Failed to create UDP socket: " << strerror(errno) << std::endl;
		exit(1);
	}

	m_socket_type = SOCK_DGRAM;
}

bool Socket::bind(const int port)
{
	if(!is_valid()) return false;

	m_addr.sin_family = AF_INET;
	m_addr.sin_addr.s_addr = INADDR_ANY;
	m_addr.sin_port = htons(port);

	return ::bind(m_sock, (struct sockaddr*)&m_addr, sizeof(m_addr)) != -1;
}

bool Socket::listen() const
{
	if(!is_valid()) return false;

	return ::listen(m_sock, MAXCONNECTIONS) != -1;
}	

bool Socket::accept(Socket &new_socket) const
{
	socklen_t addr_length = sizeof(m_addr);
	new_socket.m_sock = ::accept(m_sock, (sockaddr*)&m_addr, &addr_length);	

	return new_socket.m_sock != -1;
}

bool Socket::connect(const std::string &host, const int port)
{
	addrinfo hints, *res;

	memset(&hints, 0, sizeof(hints));
	hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = m_socket_type;

	getaddrinfo(host.c_str(), to_string(port).c_str(), &hints, &res);
	
	if(::connect(m_sock, res->ai_addr, res->ai_addrlen) == -1)
	{
		std::cerr << "Failed to connect to " << host << " on port " << port << ": "
			<< strerror(errno) << std::endl;
		return false;
	}
	return true;
}

bool Socket::send(const std::string &s) const
{
	return ::send(m_sock, s.c_str(), s.size(), 0) != -1;	
}

int Socket::recv(std::string &s) const
{
	char buf[MAXRECV + 1];

	memset(buf, 0, MAXRECV + 1);

	int bytes_sent = ::recv(m_sock, buf, MAXRECV, 0);

	if(bytes_sent <= 0)
	{
		std::cerr << "Error in Socket::recv: " << strerror(errno) << std::endl;
		exit(1);
		return 0;
	}

	s = buf;
	return bytes_sent;
}

bool Socket::UDP_send(const std::string &addr, const std::string &s,
		const int port) const
{
	struct addrinfo hints, *res;

	memset(&hints, 0, sizeof(hints));
	hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = SOCK_DGRAM;

	getaddrinfo(addr.c_str(), to_string(port).c_str(), &hints, &res);
	
	if(sendto(m_sock, s.c_str(), s.size(), 0, res->ai_addr, res->ai_addrlen) < 0)
	{
		std::cerr << "Couldn't send UDP package to " << addr << " on port " 
			<< port << ": " << strerror(errno) << std::endl;
		exit(1);
	}

	return true;
}	

int Socket::UDP_recv(std::string &s) const
{
	struct sockaddr_in addr_recvfrom;
	socklen_t len;
	int n;
	char buf[MAXRECV + 1];

	memset(buf, 0, MAXRECV + 1);
	len = sizeof(addr_recvfrom);
	n = ::recvfrom(m_sock, buf, MAXRECV, 0, (struct sockaddr*)&addr_recvfrom, &len);

	if(n <= 0)
	{
		std::cerr << "Error in Socket::UDP_recv: " << strerror(errno) << std::endl;
		exit(1);
		return 0;
	}

	s = buf;
	return n;
}

void Socket::cleanup() const
{
}

bool Socket::close() const
{
	::close(m_sock);
	return true;
}
