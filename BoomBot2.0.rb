require 'rubygems'
require 'bundler/setup'

# DEPENDENCIES
require 'yaml'

$dbc = {}
$config = {}
$prefix = File.read('currentprefix.txt').sub("\n", '')

if File.exist?('config.yml')
  $config = YAML.load(File.read('config.yml'))
else
  abort 'CRIT: Missing config.yml. Aborting!'
end

if File.exists?('configdb.yml')
  $dbc = YAML.load(File.read('configdb.yml'))
else
  puts "WARNING: Couldn't find configdb.yml! Is the bot properly configured?"
end

def sensure(what)
  abort("FAILED ensure: #{what} on $config!") if $config[:"#{what}"] == nil
end

sensure('token')
sensure('clid')
sensure('owner')
sensure('permitted')

puts "SECURE_CONFIG_ENSURE successful!"
puts "Launching Bot..."

# DEPENDENCIES
require 'ruby-progressbar'
require 'discordrb'

def constructembed(title, color, description, author)
  embed = Discordrb::Webhooks::Embed.new
  embed.color = color
  embed.title = title
  embed.description = description
  embed.timestamp = Time.now
  embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "BOOMBOT2.0: Reply to #{author.user.name}", url: 'https://bit.ly/zer0bot', icon_url: author.user.avatar_url)
  return embed
end

boom = Discordrb::Bot.new token: $config[:token]

boom.message do |e|
  msg = e.message.content
  if msg.start_with?($prefix)
    msg = msg.sub($prefix, '')

    if msg.start_with?('ping')
      m = e.respond 'Calculation of ping started...'
      pingtime = Time.now.to_i - e.timestamp.to_i
      if pingtime < 2000
        m.edit('', constructembed('BOOMBOT2.0 | ping', '00ff00', "Ping calculation finished: Heartbeat was acked with `#{pingtime.to_s} ms`", e))
      else
        m.edit('', constructembed('BOOMBOT2.0 | ping', 'ff0000', "Ping calculation finished: Heartbeat was acked with `#{pingtime.to_s} ms`", e))
      end
    end

    if msg.start_with?('warn')
      msg = msg.sub('warn ', '')
      msg = msg.gsub('<@', '')
      msg = msg.gsub('>', '')
      msg = msg.split(' ')
      rm = e.respond "TICKING RESPONSE: WARNMENU FOR #{msg[0]}"
    end

    if msg.start_with?('setup')
      msg = msg.sub('setup ', '')
      a = msg.split(' ')

      $dbc[:"#{a[0]}"] = a[1]
      rm = e.respond("**CONFIG:** Populated database element #{a[0]} with value #{a[1]}! Saving...")
      sleep 3
      File.open('configdb.yml', 'w') {|f| f.print YAML.dump $dbc}
      rm.edit("**CONFIGDB UPDATED!**")
      sleep 5
      rm.delete
    end

=begin

# Created for role assignment test
    if msg.start_with?('tmr')
      msg = msg.sub('tmr ', '')
      msg = msg.sub('<@', '')
      msg = msg.sub('>', '')
      user = msg.to_i
      e.server.member(user).add_role(e.server.role($dbc[:test]))
    end
=end

    if msg.start_with?('getdb')
      e.respond "RAW DB: #{$dbc}"
    end



  end
end

boom.message(start_with: 'brsetprefix ') do |e|
  if $config[:owner].any? {|o| o.to_i == e.user.id.to_i }
    a = e.message.content.sub('brsetprefix ', '')
    $prefix = a
    File.open('currentprefix.txt', 'w') {|f| f.print $prefix}
    e.respond "**WARNING!**\n__BRPREFIX__ has super-cow-permissions!\n\nThe prefix has been updated to `#{$prefix}`!\n"
  else
    e.respond "**PERMISSION ERROR!**\n\nI'm sorry, #{e.user.mention}, but you don't seem to be permitted to use recovery commands!"
  end
end

boom.run
