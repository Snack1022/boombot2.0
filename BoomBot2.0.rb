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

if File.exist?('configdb.yml')
  $dbc = YAML.load(File.read('configdb.yml'))
else
  puts "WARNING: Couldn't find configdb.yml! Is the bot properly configured?"
end

def sensure(what)
  abort("FAILED ensure: #{what} on $config!") if $config[:"#{what}"].nil?
end

sensure('token')
sensure('clid')
sensure('owner')
sensure('permitted')

puts 'SECURE_CONFIG_ENSURE successful!'
puts 'Launching Bot...'

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
  embed
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
        m.edit('', constructembed('BOOMBOT2.0 | ping', '00ff00', "Ping calculation finished: Heartbeat was acked with `#{pingtime} ms`", e))
      else
        m.edit('', constructembed('BOOMBOT2.0 | ping', 'ff0000', "Ping calculation finished: Heartbeat was acked with `#{pingtime} ms`", e))
      end
    end

    if msg.start_with?('warn')
      msg = msg.sub('warn ', '').sub('<@', '').sub('>', '').split(' ')
      rm = e.respond "TICKING RESPONSE: WARN #{msg[0]} FOR #{msg[1]}"
    end

    if msg.start_with?('warnlist')
      msg = msg.sub('warnlist ', '').sub('<@', '').sub('>').to_i
      e.respond "TICKING RESPONSE: WARN LIST FOR #{msg}"
    end

    if msg.start_with?('setup')

      if $config[:owner].any? { |o| o.to_i == e.user.id.to_i }
        msg = msg.sub('setup ', '')
        a = msg.split(' ')

        $dbc[:"#{a[0]}"] = a[1]
        rm = e.respond("**CONFIG:** Populated database element #{a[0]} with value #{a[1]}! Saving...")
        sleep 3
        File.open('configdb.yml', 'w') { |f| f.print YAML.dump $dbc }
        rm.edit('**CONFIGDB UPDATED!**')
        sleep 5
        rm.delete
      else
        e.respond 'TICKING RESPONSE: NOPERM_OWNER'
      end
    end

    if msg.start_with?('tempban')
      if $config[:permitted].any? { |o| e.user.roles.any? { |r| r.id == o.to_i } }
        msg = msg.sub('tempban ', '')
        a = msg.split(' ')
        bandur = a[0].to_i
        banusr = a[1].sub('<@', '').sub('>', '')
        e.respond "TICKING RESPONSE: TIMED BAN FOR #{banusr}; DURATION: #{bandur} DAYS"
      else
        e.respond 'TICKING RESPONSE: NOPERM_PERM'
      end
    end

    if msg.start_with?('permban')
      if $config[:permitted].any? { |o| e.user.roles.any? { |r| r.id == o.to_i } }
        msg = msg.sub('permban ', '')
        banusr = msg.sub('<@', '').sub('>', '')
        e.respond "TICKING RESPONSE: PERMABAN FOR #{banusr}"
      else
        e.respond 'TICKING RESPONSE: NOPERM_PERM'
      end
    end

    if msg.start_with?('permrole')
      if $config[:permitted].any? { |o| e.user.roles.any? { |r| r.id == o.to_i } }
        msg = msg.sub('permrole ', '').sub('<@', '').sub('>', '').split(' ')
        e.respond "TICKING RESPONSE: PERM ASSIGN ROLE #{msg[1]} to #{msg[0]}"
      else
        e.respond 'TICKING RESPONSE: NOPERM_PERM'
      end
    end

    if msg.start_with?('temprole')
      if $config[:permitted].any? { |o| e.user.roles.any? { |r| r.id == o.to_i } }
        msg = msg.sub('permrole ', '').sub('<@', '').sub('>', '').split(' ')
        time = msg[2]
        e.respond "TICKING RESPONSE: TEMP ASSIGN ROLE #{msg[1]} to #{msg[0]} for #{msg[2]}"
      else
        e.respond 'TICKING RESPONSE: NOPERM_PERM'
      end
    end

    if msg.start_with?('roles')
      if msg == 'roles'
        e.respond "TICKING RESPONSE: ROLES OF #{e.user.id}"
      else
        msg = msg.sub('roles ', '').sub('<@', '').sub('>', '').split(' ')
        if msg.length != 1
          if $config[:permitted].any? { |o| e.user.roles.any? { |r| r.id == o.to_i } }
            e.respond "TICKING RESPONSE: #{msg[1]} FOR #{msg[0]}; AFFECTING #{msg[2]}"
          else
            e.respond 'TICKING RESPONSE: NOPERM_PERM'
          end
        else
          e.respond "TICKING RESPONSE: ROLES OF #{msg[0]}"
        end
      end
    end


    # # Created for role assignment test
    #     if msg.start_with?('tmr')
    #       msg = msg.sub('tmr ', '')
    #       msg = msg.sub('<@', '')
    #       msg = msg.sub('>', '')
    #       user = msg.to_i
    #       e.server.member(user).add_role(e.server.role($dbc[:test]))
    #     end

  end
end

boom.message(start_with: 'brsetprefix ') do |e|
  if $config[:owner].any? { |o| o.to_i == e.user.id.to_i }
    a = e.message.content.sub('brsetprefix ', '')
    $prefix = a
    File.open('currentprefix.txt', 'w') { |f| f.print $prefix }
    e.respond "**WARNING!**\n__BRPREFIX__ has super-cow-permissions!\n\nThe prefix has been updated to `#{$prefix}`!\n"
  else
    e.respond "**PERMISSION ERROR!**\n\nI'm sorry, #{e.user.mention}, but you don't seem to be permitted to use recovery commands!"
  end
end

=begin
# Disabled for security purposes
boom.message(start_with: 'brgrabroles') do |e|
  e.server.roles.each do |r|
    puts "Role name: #{r.name} | Role ID: #{r.id}"
  end
  e.respond 'Please view console for details!'
end
=end
boom.run
