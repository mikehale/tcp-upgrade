STDOUT.sync = true

run lambda { |env, socket|
  client= Puma::Client.new(socket, env)
  client.reset
  p http_env = client.env

  if http_env
    if http_env['HTTP_CONNECTION'] =~ /upgrade/i && http_env['HTTP_UPGRADE'] =~ /tcp/i
      response = <<-'RES'.gsub(/^\s+/,'')
               HTTP/1.1 101
               Connection: Upgrade
               Upgrade: tcp


               RES
      socket.write(response)
      puts socket.read
    else
      headers = http_env.select {|k,v| k.start_with? 'HTTP_'}
      .collect {|pair| [pair[0].sub(/^HTTP_/, ''), pair[1]]}
      .collect {|pair| pair.join(": ") }
      .sort
      puts headers
      [200, {'Content-Type' => 'text/plain'}, ['Hello World']]
    end
  end
}
