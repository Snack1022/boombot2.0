require 'rubygems'
require 'bundler/setup'

# DEPENDENCIES
require 'yaml'

load 'usermanager.rb'

$dbc = {}
$config = {}
$db = {}
$prefix = File.read('currentprefix.txt').sub("\n", '')
$reminders = []

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

if File.exist?('reminders.yml')
  $reminders = YAML.load(File.read('reminders.yml'))
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

def constructembed(title, color, description, author = 'none')
  embed = Discordrb::Webhooks::Embed.new
  embed.color = color
  embed.title = title
  embed.description = description
  embed.timestamp = Time.now
  if author != 'none'
    embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "BOOMBOT2.0: Reply to #{author.user.name}", url: 'https://cubuzz.de', icon_url: author.user.avatar_url)
  end
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
      warnID = msg[1].to_i
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

      uWarns = $db[:"#{msg}"].getwarns(e.server.id)
      if uWarns.length == 0
        e.channel.send_embed('', constructembed("BoomBot2.0 | Warns for #{msg}", '00ff00', 'No warns on record. All good here :slight_smile:', e))
      else
        # TODO: Prevent overload!
        uWarnsProc = []
        # DEBUG:
        # puts uWarns
        # DEBUG END!
        for i in (1..uWarns.length)
          uWarnsProc.push("#{uWarns[(i-1)][3].to_s}): #{uWarns[(i-1)][0]}: #{uWarns[(i-1)][1]}")
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
      $db[:"#{warnusr}"].warn(warnmsg, e.server.id)
      e.channel.send_embed('', constructembed("BoomBot2.0 | Warned #{warnusr}!", '00ff00', 'User has been warned.', e))
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
        e.channel.send_embed('', constructembed('BoomBot2.0 | NO PERMISSION', 'ff0000', 'You\'re lacking permission to do that. If you believe this is an error, contact `admin@cubuzz.de`.', e))
      end
      msg = 'nil'
    end

    if msg.start_with?('tempban')
      if $config[:permitted].any? { |o| e.user.roles.any? { |r| r.id == o.to_i } }
        msg = msg.sub('tempban ', '')
        a = msg.split(' ')
        if a[0].include?('h')
          bandur = Time.now + (a[0].to_i)
        else
          bandur = Time.now + (a[0].to_i * 24)
        end
        banusr = a[1].sub('<@', '').sub('>', '')
        e.respond "TICKING RESPONSE: TIMED BAN FOR #{banusr}; DURATION: UNTIL UNIX #{bandur.to_s * 3600}"
      else
        e.channel.send_embed('', constructembed('BoomBot2.0 | NO PERMISSION', 'ff0000', 'You\'re lacking permission to do that. If you believe this is an error, contact `admin@cubuzz.de`.', e))
      end
      msg = 'nil'
    end

    if msg.start_with?('permban')
      if $config[:permitted].any? { |o| e.user.roles.any? { |r| r.id == o.to_i } }
        msg = msg.sub('permban ', '')
        banusr = msg.sub('<@', '').sub('>', '')
        e.respond "TICKING RESPONSE: PERMABAN FOR #{banusr}"
      else
        e.channel.send_embed('', constructembed('BoomBot2.0 | NO PERMISSION', 'ff0000', 'You\'re lacking permission to do that. If you believe this is an error, contact `admin@cubuzz.de`.', e))
      end
      msg = 'nil'
    end

    if msg.start_with?('permrole')
      if $config[:permitted].any? { |o| e.user.roles.any? { |r| r.id == o.to_i } }
        msg = msg.sub('permrole ', '').sub('<@', '').sub('>', '').split(' ')
        e.respond "TICKING RESPONSE: PERM ASSIGN ROLE #{msg[1]} to #{msg[0]}"
      else
        e.channel.send_embed('', constructembed('BoomBot2.0 | NO PERMISSION', 'ff0000', 'You\'re lacking permission to do that. If you believe this is an error, contact `admin@cubuzz.de`.', e))
      end
      msg = 'nil'# Database Scan for previous entries
      # Add roles
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
        e.channel.send_embed('', constructembed('BoomBot2.0 | NO PERMISSION', 'ff0000', 'You\'re lacking permission to do that. If you believe this is an error, contact `admin@cubuzz.de`.', e))
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
            e.channel.send_embed('', constructembed('BoomBot2.0 | NO PERMISSION', 'ff0000', 'You\'re lacking permission to do that. If you believe this is an error, contact `admin@cubuzz.de`.', e))
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
#ping - Tries to calculate the Pseudo-Ping
#warn @x y - Warns the user @x because of reason y
#warnlist @x - Obtain a list of all warns against @x
#setup a r - Populate Database Vectors with values, ex. role IDs for later assignment. DEV ONLY!
#tempban @x duration - Skeleton: Tempbans user @x for duration
#permban @x - Skeleton: Bans user @x permanently
#permrole @x role - Skeleton: Assigns role role to @x
#temprole @x role duration - Skeleton: Assignes role role to @x for a limited amount of time
#roles @x a r - Skeleton: Allows you to see others roles and with proper permission modify these.

A detailed documentation will be created soon."
    end

    # # Created for role assignment test
    #     if msg.start_with?('tmr')
    #       msg = msg.sub('tmr ', '')
    #       msg = msg.sub('<@', '')
    #       msg = msg.sub('>', '')
    #       user = msg.to_i
    #       e.server.member(user).add_role(e.server.role($dbc[:test]))
    #     end

    if msg.start_with?('remind')
      msg = msg.gsub('remind ', '')
      txt = msg.split(' ')
      time = txt.shift
      time = time.split(';')
      target = Time.now
      time.each do |t|
        if t.include?('s')
          target += t.to_i
        elsif t.include?('m')
          target += t.to_i * 60
        elsif t.include?('h')
          target += t.to_i * 60 * 60
        elsif t.include?('d')
          target += t.to_i * 60 * 60 * 24
        end
      end
      e.channel.send_embed('', constructembed('BoomBot2.0 | Reminder', '00ff00', "The reminder `#{txt.join(' ')}` has been set for #{Time.at(target).strftime('%c')}."))
      puts "DEBUG: Remind #{txt.join(" ")} at #{target}"
      $reminders.push([target, e.channel.id, txt.join(" ")])
      puts "DEBUG: $reminders = #{$reminders}"
    end
  end
end

boom.message(start_with: 'brsetprefix ') do |e|
  if $config[:owner].any? { |o| o.to_i == e.user.id.to_i }
    a = e.message.content.sub('brsetprefix ', '')
    $prefix = a
    File.open('currentprefix.txt', 'w') { |f| f.print $prefix }
    e.respond "**WARNING!**\n__BRSETPREFIX__ has super-cow-permissions!\n\nThe prefix has been updated to `#{$prefix}`!\n"
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
    loop do
      runbar = ProgressBar.create title: 'Running!', total: 120
      12.times do
        boom.game = ['BoomBot2.0!', 'OVERWATCH (of a server)', 'Eternal Server Game', "#{$prefix}help", 'Selling Bass...', 'Distributing some secrets...', 'Discord Studio 20', 'Something about Basslines', 'Bassfield 1'].sample
        10.times {runbar.increment; sleep 1}
      end

      puts
      print "Updating."
      uupdate = []
      $db.each do |k, v|
        if v.update() != false
          uupdate.push(k)
        end
      end
      print '.'

      puts
      print 'Running reminder tasks...'

      $reminders.each do |r|
        puts "DEBUG: Inspecting #{r}"
        # Formatting: [Time, e.channel.id, Message]
        if r[0] < Time.now
          puts "#{r} is up to deploy!"
          boom.channel(r[1]).send_message("**REMINDER:** Hey there! A reminder has been set for #{r[0].strftime('%D, %r')}, which has just been acked: \n#{r[2]}")
          $reminders.delete(r)
        end
      end


      puts
      print "Saving"
      File.open('userdb.yml', 'w') {|f| f.puts YAML.dump $db}
      File.open('reminders.yml', 'w') {|f| f.puts YAML.dump $reminders}
      puts "... Sucess!"
      runbar.finish
    end
  end

  boom.member_join do |e|
    if $db[:"#{e.user.id.to_s}"] == nil
      $db[:"#{e.user.id.to_s}"] = User.new(e.user.id)
      e.user.dm("**WELCOME!**\nWe're happy to have you arround here. Please take a look, read the rules and follow the instructions. Enjoy your stay!")
    else
      e.user.dm("**WELCOME BACK!**")
    end
  end

boom.run
