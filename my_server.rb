require 'socket'
require 'uri'
require_relative 'constants.rb'

def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end

def red(text); colorize(text, 31); end
def green(text); colorize(text, 32); end

port = 2345
if ARGV.include?('-p')
	p = ARGV.index('-p') + 1
	port = ARGV[p]
end

def content_type(path)
	ext = File.extname(path).split(".").last
	CONTENT_TYPE_MAPPING.fetch(ext, DEFAULT_CONTENT_TYPE)
end


def requested_file(request_line)
	request_uri = request_line.split(" ")[1]
	path = URI.unescape(URI(request_uri).path)
	clean = []
	parts = path.split("/")

	parts.each do |part|
		next if part.empty? || part == '.'
		part == '..' ? clean.pop : clean << part
	end

	File.join(WEB_ROOT, path)
end

server = TCPServer.new('localhost', port)
puts "Start my server on port #{port}."

trap "SIGINT" do
  puts "\rClosing server"
  exit 130
end

loop do 
	begin
	socket = server.accept
	request_line = socket.gets
	http_method = request_line.split(" ")[0]
  headers = {}
  while line = socket.gets.split(' ', 2)              # Collect HTTP headers
    break if line[0] == ""                            # Blank line means no more headers
    headers[line[0].chop] = line[1].strip             # Hash headers by type
  end
	STDERR.puts request_line

	path = requested_file(request_line)

	path = File.join(path, 'index.html') if File.directory?(path)
	if http_method == 'GET'

		if File.exist?(path) && !File.directory?(path)
			File.open(path, "rb") do |file|
				socket.print "HTTP/1.1 200 OK\r\n" + "Content-Type: #{content_type(file)}\r\n" + "Content-Length: #{file.size}\r\n" + "Connection: close\r\n"
				socket.print "\r\n"
				IO.copy_stream(file, socket)
				puts green("200 OK")
			end
		else
			give_error(socket, ERROR[404])
		end

	elsif http_method == 'HEAD'
		if File.exist?(path) && !File.directory?(path)
			File.open(path, "rb") do |file|
				socket.print "HTTP/1.1 204 No Content\r\n" + "Content-Type: #{content_type(file)}\r\n" + "Content-Length: #{file.size}\r\n" + "Connection: close\r\n"
				socket.print "\r\n"
				puts "204 No Content"
			end
		else
			give_error(socket, ERROR[404])
    end

  elsif http_method == 'POST'
    p socket.read(headers["Content-Length"].to_i)
    if File.exist?(path) && !File.directory?(path)
      File.open(path, "rb") do |file|
        socket.print "HTTP/1.1 200 OK\r\n" + "Content-Type: #{content_type(file)}\r\n" + "Content-Length: #{file.size}\r\n" + "Connection: close\r\n"
        socket.print "\r\n"
        IO.copy_stream(file, socket)
        puts green("200 OK")
      end
    else
      give_error(socket, ERROR[404])
    end
	end

	socket.close
rescue
	message = "Internal Server Error\n"
	socket.print "HTTP/1.1 500 internal server error\r\n" + "Content-Type: text/plain\r\n" + "Content-Length: #{message.size}\r\n" + "Connection: close\r\n"
	socket.print "\r\n"
	socket.print message
	puts "500 internal server error"
	socket.close
end

  def give_error(socket, error)
    message = "#{error[:status]}\n"
    socket.print "HTTP/1.1 #{error[:code]} #{error[:status]}\r\n" + "Content-Type: text/plain\r\n" + "Content-Length: #{message.size}\r\n" + "Connection: close\r\n"
    socket.print "\r\n"
    socket.print message
    puts red("#{error[:code]} #{error[:status]}")
  end
end

