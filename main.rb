puts 'Preparing to launch BoomBot2.0...'

puts 'Preparing Handler...'
is_running = true

loop do 
  f = File.open('handler.log', 'a')
  f.puts '=================================================='
  f.puts "[Handler] [#{Time.now.strftime("%c")}] Setting up new session."
  f.puts "[Handler] [#{Time.now.strftime("%c")}] Launch time: #{Time.now.strftime("%c")}"
  f.close

  puts 'Preparing launch...'
  puts 'BoomBot2.0 is lanching, please stand by.'
  t = Thread.new { load 'bb20.rb' }
  is_running = true
  puts 'Now checking every 60 seconds whether bot updated Handler file.'
  puts 'First check is delayed by additional 30 seconds.'
  timer = Time.now.to_i + 90
  
  while is_running 
    while (timer > Time.now.to_i)
      sleep 1
    end
    heartbeat = Time.at(File.read('handler.comms').to_i)
    if (heartbeat < Time.now - 60)
      File.open('handler.log', 'a') {|f| f.puts "[Handler] [#{Time.now.strftime("%c")}] Bot did not ack the most recent heartbeat (should be newer than #{(Time.now - 60).strftime("%c")}), but is #{Time.at(heartbeat).strftime("%c")}). \nRebooting in progress..."}
      print 'Killing bot... '
      t.kill
      print 'Done!'
    else
      timer = Time.now.to_i + 60
      File.open('handler.log', 'a') {|f| f.puts "[Handler] [#{Time.now.strftime("%c")}] Found most recent heartbeat at #{heartbeat.strftime("%c")}."}
    end
  end
end