require 'rubygems'
require 'bundler/setup'

# DEPENDENCIES
require 'yaml'

load 'usermanager.rb'

$dbc = {}
$config = {}
$db = {}
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

if File.exist?('userdb.yml')
  $db = YAML.load(File.read('userdb.yml'))
else
  puts "WARNING: Couldn't find userdb.yml! Did we suffer a data loss?"
end


def sensure(what)
  abort("FAILED ensure: #{what} on $config!") if $config[:"#{what}"].nil?
end

sensure('token')
sensure('clid')
sensure('owner')
sensure('permitted')
sensure('tracked')

puts 'SECURE_CONFIG_ENSURE successful!'
puts 'Launching Bot...'

# DEPENDENCIES
require 'ruby-progressbar'
require 'discordrb'
require 'similar_text'

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
  # TODO: Integrate error messages

  break if e.user.bot_account == true
  msg = e.message.content
  $db[:"#{e.user.id.to_s}"] = User.new(e.user.id) if ($db[:"#{e.user.id.to_s}"] == nil) # Construct User Elemements


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
      msg = 'nil'
    end

    if msg.start_with?('rmwarn')
      msg = msg.sub('rmwarn <@', '').sub('>', '')
      msg = msg.split(' ')
      puts msg # DEBUG
      userID = msg[0].to_i
      warnID = msg[1].to_i - 1
      puts "userID = #{userID.to_s}; warnID = #{warnID.to_s}"
      if $db[:"#{userID.to_s}"].undowarn(warnID) == true
        e.channel.send_embed('', constructembed('BoomBot2.0 | Remove Warning', '00ff00', "The warning has been successfully removed from <@#{userID}>!", e))
      else
        e.channel.send_embed('', constructembed('BoomBot2.0 | Remove Warning', 'ff0000', "ERROR: OutOfIndexException: <@#{userID}> does not have a warning on this index!", e))
      end
      msg = 'nil'
    end

    if msg.start_with?('warnlist')
      msg = msg.sub('warnlist ', '').sub('<@', '').sub('>', '').to_i

      uWarns = $db[:"#{msg}"].getwarns
      if uWarns.length == 0
        e.channel.send_embed('', constructembed("BoomBot2.0 | Warns for #{msg}", '00ff00', 'No warns on record. All good here :slight_smile:', e))
      else
        # TODO: Prevent overload!
        uWarnsProc = []
        for i in (1..uWarns.length)
          uWarnsProc.push("#{i.to_s}): #{uWarns[(i-1)][0]}: #{uWarns[(i-1)][1]} ")
        end
        e.channel.send_embed('', constructembed("BoomBot2.0 | Warns for #{msg}", '00ff00', "Total warns on record: #{uWarns.length.to_s}\n\n#{uWarnsProc.join("\n")}", e))
      end

      msg = 'nil'
    end

    if msg.start_with?('warn')
      msg = msg.sub('warn ', '').sub('<@', '').sub('>', '').split(' ')
      warnusr = msg[0]
      msg.delete_at(0) # Can't be included into code; returns value which should be voided
      warnmsg = msg.join(' ')
      $db[:"#{warnusr}"].warn(warnmsg)
      e.channel.send_embed('', constructembed("BoomBot2.0 | Warned #{warnusr}!", '00ff00', 'DASH has been informed about this incident. A warning has been created.', e))
      msg = 'nil'
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
      msg = 'nil'
    end

    if msg.start_with?('tempban')
      if $config[:permitted].any? { |o| e.user.roles.any? { |r| r.id == o.to_i } }
        msg = msg.sub('tempban ', '')
        a = msg.split(' ')
        if a[0].include?('h')
          bandur = Time.now + (a[0].to_i * 3600)
        else
          bandur = Time.now + (a[0].to_i * 3600 * 24)
        end
        banusr = a[1].sub('<@', '').sub('>', '')
        e.respond "TICKING RESPONSE: TIMED BAN FOR #{banusr}; DURATION: UNTIL UNIX #{bandur.to_s}"
      else
        e.respond 'TICKING RESPONSE: NOPERM_PERM'
      end
      msg = 'nil'
    end

    if msg.start_with?('permban')
      if $config[:permitted].any? { |o| e.user.roles.any? { |r| r.id == o.to_i } }
        msg = msg.sub('permban ', '')
        banusr = msg.sub('<@', '').sub('>', '')
        e.respond "TICKING RESPONSE: PERMABAN FOR #{banusr}"
      else
        e.respond 'TICKING RESPONSE: NOPERM_PERM'
      end
      msg = 'nil'
    end

    if msg.start_with?('permrole')
      if $config[:permitted].any? { |o| e.user.roles.any? { |r| r.id == o.to_i } }
        msg = msg.sub('permrole ', '').sub('<@', '').sub('>', '').split(' ')
        e.respond "TICKING RESPONSE: PERM ASSIGN ROLE #{msg[1]} to #{msg[0]}"
      else
        e.respond 'TICKING RESPONSE: NOPERM_PERM'
      end
      msg = 'nil'
    end

    if msg.start_with?('temprole')
      if $config[:permitted].any? { |o| e.user.roles.any? { |r| r.id == o.to_i } }
        msg = msg.sub('temp ', '').sub('<@', '').sub('>', '').split(' ')
        if msg[2].include?('h')
          time = Time.now + (msg[2].to_i * 3600)
        else
          time = Time.now + (msg[2].to_i * 3600 * 24)
        end
        e.respond "TICKING RESPONSE: TEMP ASSIGN ROLE #{msg[1]} TO #{msg[0]} UNTIL UNIX #{time.to_s}"
      else
        e.respond 'TICKING RESPONSE: NOPERM_PERM'
      end
      msg = 'nil'
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
      msg = 'nil'
    end

    if msg.start_with?('help')
      e.respond "**__WAIT WAIT WAIT!__** This command is going to be added when the full release comes. Here's a quick overview tho:\nCommands:
brsetprefix n - Sets the prefix to N. | Requires Owner Perms

# = Placeholder for prefix
#ping - Working: Tries to calculate the Pseudo-Ping
#warn @x y - Skeleton: Warns the user @x because of reason y
#warnlist @x - Skeleton: Obtain a list of all warns against @x
#setup a r - Working: Populate Database Vectors with values, ex. role IDs for later assignment.
#tempban @x duration - Skeleton: Tempbans user @x for duration
#permban @x - Skeleton: Bans user @x permanently
#permrole @x role - Skeleton: Assigns role role to @x
#temprole @x role duration - Skeleton: Assignes role role to @x for a limited amount of time
#roles @x a r - Skeleton: Allows you to see others roles and with proper permission modify these."
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

boom.message(start_with: 'dbrsetprefix ') do |e|
  if $config[:owner].any? { |o| o.to_i == e.user.id.to_i }
    a = e.message.content.sub('brsetprefix ', '')
    $prefix = a
    File.open('currentprefix.txt', 'w') { |f| f.print $prefix }
    e.respond "**WARNING!**\n__BRPREFIX__ has super-cow-permissions!\n\nThe prefix has been updated to `#{$prefix}`!\n"
  else
    e.respond "**PERMISSION ERROR!**\n\nI'm sorry, #{e.user.mention}, but you don't seem to be permitted to use recovery commands!"
  end
  msg = 'nil'
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

  boom.ready do
    if File.exist?('broadcast.txt')
      # Planned to inform about updates

      # Delete after broadcasting so it doesn't get broadcasted again
      # File.delete('broadcast.txt')
    end

    loop do
      runbar = ProgressBar.create title: 'Running!', total: 600
      60.times do
        boom.game = ['BoomBot2.0!', 'OVERWATCH (of a server)', 'Eternal Server Game', "#{$prefix}help", 'Selling Bass...', 'Distributing some secrets...', 'Discord Studio 20', 'Something about Basslines', 'Bassfield 1'].sample
        10.times {runbar.increment; sleep 1}
      end
      puts
      print "Saving"
      File.open('userdb.yml', 'w') {|f| f.puts YAML.dump $db}
      puts "... Sucess!"
      runbar.finish
    end
  end

  boom.member_join do |event|
    # Database Scan for previous entries
    # Add roles
  end

boom.run
