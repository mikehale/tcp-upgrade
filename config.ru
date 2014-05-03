STDOUT.sync = true

run lambda { |env|
  if env[Puma::Const::HIJACK_P] &&
      env['HTTP_CONNECTION'] =~ /upgrade/i &&
      env['HTTP_UPGRADE'] =~ /tcp/i
    puts "tcp!"

    io = env[Puma::Const::HIJACK].call
    io.puts "HTTP/1.1 101 Switching Protocols\r\nConnection: Upgrade\r\nUpgrade: tcp\r\n\r\n"
    io.flush

    loop do
      begin
        ready = IO.select([io],[], [], 1)
        readables = ready[0] if ready

        if readables && readables[0]
          puts counter = Integer(io.recv_nonblock(1024).chomp)
          io.puts counter + 1
        end
      rescue => e
        puts e.inspect
        io.close
        break
      end
    end

    [-1, {}, []]
  else
    puts "http :|"
    [200,{},[]]
  end
}
