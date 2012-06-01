local ffi = require "ffi"
local dns = require "ffi_dns"
local socket = require "ffi_socket"
local urlparse = require "socket.url".parse

local function request ( url , e , cb )
	url = urlparse ( url )
	dns.lookup_async ( url.host , url.port or 80 , e , function ( addrinfo )
			print ( "Connecting to " .. table.concat({dns.addrinfo_to_string ( addrinfo )}," ") )

			local sock = socket.new_tcp ( addrinfo.ai_family )
			sock:connect ( addrinfo , e , function ( sock , err )
					assert ( sock , err )
					local req = table.concat ( {
						"GET " .. ( url.path or "/" ) .. " HTTP/1.0" ;
						"Host: " .. url.host ;
						"\r\n" ;
					} , "\r\n" )
					sock:write ( req , nil , e , function ( sock , err )
							assert ( sock , err )
							local len = 2^20
							local buff = ffi.new("char[?]",len)
							local have = 0
							e:add_fd ( sock.fd , {
									read = function ( fd )
										local c = ffi.C.read ( fd.fd , buff+have , len-have )
										if c == -1 then
											error ( ffi.string ( ffi.C.strerror ( ffi.errno ( ) ) ) )
										end
										have = have + c
									end ;
									close = function ( fd )
										cb ( ffi.string ( buff , have ) )
									end ;
								} )
						end )
				end )
		end )
end

return {
	request = request ;
}