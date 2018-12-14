require 'rubygems'
require 'bundler/setup'

# DEPENDENCIES
require 'yaml'
require 'pry'

load 'usermanager.rb'

$dbc = {}
$config = {}
$db = {}
$prefix = File.read('currentprefix.txt').sub("\n", '') if File.exist?('currentprefix.txt')
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

if File.exist?('games.txt')
  $games = File.read('games.txt').split("\n")
else
  $games = ['BoomBot2.0!', 'OVERWATCH (of a server)', 'Eternal Server Game', "#{$prefix}help", 'Selling Bass...', 'Distributing some secrets...', 'Discord Studio 20', 'Something about Basslines', 'Bassfield 1']
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

  $db[:"#{e.user.id.to_s}"] = User.new(e.user.id) if $db[:"#{e.user.id.to_s}"].nil? # Construct User Elemements
  break if $prefix.nil?

  begin
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
        msg = 'nil'
      end

=begin
      if msg.start_with?('rmwarn')
        msg = msg.sub('rmwarn <@', '').sub('>', '')
        msg = msg.split(' ')
        userID = msg[0].to_i
        warnID = msg[1].to_i
        if $db[:"#{userID.to_s}"].undowarn(warnID) == true
          e.channel.send_embed('', constructembed('BoomBot2.0 | Remove Warning', '00ff00', "The warning has been successfully removed from <@#{userID}>!", e))
        else
          e.channel.send_embed('', constructembed('BoomBot2.0 | Remove Warning', 'ff0000', "ERROR: OutOfIndexException: <@#{userID}> does not have a warning on this index!", e))
        end
        msg = 'nil'
      end

      if msg.start_with?('warnlist')
        msg = msg.sub('warnlist ', '').sub('<@!', '').sub('<@', '').sub('>', '').to_i

        uWarns = $db[:"#{msg}"].getwarns(e.server.id)
        if uWarns.empty?
          e.channel.send_embed('', constructembed("BoomBot2.0 | Warns for #{msg}", '00ff00', 'No warns on record. All good here :slight_smile:', e))
        else
          # TODO: Prevent overload!
          uWarnsProc = []
          (1..uWarns.length).each do |i|
            uWarnsProc.push("#{uWarns[(i - 1)][3]}): #{uWarns[(i - 1)][0]}: #{uWarns[(i - 1)][1]}")
          end
          e.channel.send_embed('', constructembed("BoomBot2.0 | Warns for #{msg}", '00ff00', "Total warns on record: #{uWarns.length}\n\n#{uWarnsProc.join("\n")}", e))
        end

        msg = 'nil'
      end

      if msg.start_with?('warn')
        msg = msg.sub('warn ', '').sub('<@!', '').sub('<@', '').sub('>', '').split(' ')
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
          bandur = if a[0].include?('h')
                     Time.now + a[0].to_i
                   else
                     Time.now + (a[0].to_i * 24)
                   end
          banusr = a[1].sub('<@!', '').sub('<@', '').sub('>', '')
          e.respond "TICKING RESPONSE: TIMED BAN FOR #{banusr}; DURATION: UNTIL UNIX #{bandur.to_s * 3600}"
        else
          e.channel.send_embed('', constructembed('BoomBot2.0 | NO PERMISSION', 'ff0000', 'You\'re lacking permission to do that. If you believe this is an error, contact `admin@cubuzz.de`.', e))
        end
        msg = 'nil'
      end

      if msg.start_with?('permban')
        if $config[:permitted].any? { |o| e.user.roles.any? { |r| r.id == o.to_i } }
          msg = msg.sub('permban ', '')
          banusr = msg.sub('<@!', '').sub('<@', '').sub('>', '')
          e.respond "TICKING RESPONSE: PERMABAN FOR #{banusr}"
        else
          e.channel.send_embed('', constructembed('BoomBot2.0 | NO PERMISSION', 'ff0000', 'You\'re lacking permission to do that. If you believe this is an error, contact `admin@cubuzz.de`.', e))
        end
        msg = 'nil'
      end
=end

      if msg.start_with?('permrole')
        if $config[:permitted].any? { |o| e.user.roles.any? { |r| r.id == o.to_i } }
          msg = msg.sub('permrole ', '').sub('<@!', '').sub('<@', '').sub('>', '').split(' ')
          if msg[0].to_i == 0
            user = msg[0]

            # When a user name got passed

            # Pseudo:
            # Download all server members
            # AutoCorrect through the list
            # Set user to the most corresponding ID

            # Copy-Paste from AutoCorrect for roles:
            # max = [0, 111, 'rolename']
            # e.server.roles.each do |r|
            # max = [r.name.similar(role), r.id, r.name] if r.name.similar(role) > max[0]
            # end

            usrmax = [0, 111, 'username']
            e.server.members.each do |m|
              usrmax = [m.display_name.similar(user), m.id, m.display_name] if m.display_name.similar(user) > usrmax[0]
            end
            msg[0] = usrmax[1]

          end

          $db[:"#{msg[0].to_s}"] = User.new(msg[0].to_i) if $db[:"#{msg[0].to_s}"].nil?

          max = [0, 111, 'rolename']
          e.server.roles.each do |r|
            max = [r.name.similar(msg[1]), r.id, r.name] if r.name.similar(msg[1]) > max[0]
          end
          $db[:"#{msg[0].to_s}"].permrole(e.server.id, max[2], max[1])
          e.server.member(msg[0].to_i).add_role(e.server.role(max[1].to_i))
          e.channel.send_embed('', constructembed('BoomBot2.0 | permrole', '00ff00', "Assigned role #{max[2]} to <@#{msg[0]}> permanently!", e))
        else
          e.channel.send_embed('', constructembed('BoomBot2.0 | NO PERMISSION', 'ff0000', 'You\'re lacking permission to do that. If you believe this is an error, contact `admin@cubuzz.de`.', e))
        end
        msg = 'nil'
      end

      if msg.start_with?('temprole')
        if $config[:permitted].any? { |o| e.user.roles.any? { |r| r.id == o.to_i } }
          msg = msg.sub('temprole ', '').sub('<@!', '').sub('<@', '').sub('>', '').split(' ')
          time = if msg[2].include?('h')
                   msg[2].to_i
                 else
                   msg[2].to_i * 24
                 end

          max = [0, 111, 'rolename']
          e.server.roles.each do |r|
            max = [r.name.similar(msg[1]), r.id, r.name] if r.name.similar(msg[1]) > max[0]
          end

          if msg[0].to_i == 0
            user = msg[0]
            # When a user name got passed

            # Pseudo:
            # Download all server members
            # AutoCorrect through the list
            # Set user to the most corresponding ID

            # Copy-Paste from AutoCorrect for roles:
            # max = [0, 111, 'rolename']
            # e.server.roles.each do |r|
            # max = [r.name.similar(role), r.id, r.name] if r.name.similar(role) > max[0]
            # end

            usrmax = [0, 111, 'username']
            e.server.members.each do |m|
              usrmax = [m.display_name.similar(user), m.id, m.display_name] if m.display_name.similar(user) > usrmax[0]
            end
            msg[0] = usrmax[1]
          end
          $db[:"#{msg[0].to_s}"] = User.new(msg[0].to_i) if $db[:"#{msg[0].to_s}"].nil?
          $db[:"#{msg[0].to_s}"].temprole(e.server.id, max[2], time, max[1])
          e.server.member(msg[0].to_i).add_role(e.server.role(max[1].to_i))
          e.channel.send_embed('', constructembed('BoomBot2.0 | temprole', '00ff00', "Assigned role #{max[2]} to <@#{msg[0]}> for #{time / 24} days and #{time % 24} hours!", e))
        else
          e.channel.send_embed('', constructembed('BoomBot2.0 | NO PERMISSION', 'ff0000', 'You\'re lacking permission to do that. If you believe this is an error, contact `admin@cubuzz.de`.', e))
        end
        msg = 'nil'
      end

      if msg.start_with?('roles')
        msg = msg.sub('roles ', '').sub('roles', '').sub('<@!', '').sub('<@', '').sub('>', '')
        user =  if msg == ''
                  e.user.id.to_i # No Message Passed
                elsif msg.to_i == 0
                  # Autocorrect

                  user = msg
                  # When a user name got passed

                  # Pseudo:
                  # Download all server members
                  # AutoCorrect through the list
                  # Set user to the most corresponding ID

                  # Copy-Paste from AutoCorrect for roles:
                  # max = [0, 111, 'rolename']
                  # e.server.roles.each do |r|
                  # max = [r.name.similar(role), r.id, r.name] if r.name.similar(role) > max[0]
                  # end

                  usrmax = [0, 111, 'username']
                  e.server.members.each do |m|
                    usrmax = [m.display_name.similar(user), m.id, m.display_name] if m.display_name.similar(user) > usrmax[0]
                  end
                  usrmax[1]
                else
                  msg.to_i
                end
        counter = 0
        rmsg = []
        $db[:"#{user.to_s}"] = User.new(user.to_i) if $db[:"#{user.to_s}"].nil?
        r = $db[:"#{user.to_s}"].roles
        if r.none? { |role| role[0] == e.server.id }
          rmsg.push("<@#{user}> does not have any staged roles.")
        else
          r.each do |ri|
            next unless ri[0] == e.server.id

            counter += 1
            if ri[2] == 'perm'
              rmsg.push("#{counter}) `#{ri[1]}`, expires: `never`")
            else
              time_total = Time.at(ri[2]).to_i - Time.now.to_i
              time_days = time_total / 86_400
              time_hours = (time_total % 86_400) / 3600
              rmsg.push("#{counter}) `#{ri[1]}`, expires in: `#{time_days}` days and `#{time_hours}` hours.")
            end
          end
      end
        counter = 0
        temparr = []
        ur = boom.server(e.server.id).member(user).roles
        ur.each do |urole|
          if r.any? { |ri| ri[3] != urole.id } || r == []
            counter += 1
            temparr.push("#{counter}) `#{urole.name}`, is unstaged.")
          end
        end
        rmsg.push("\n<@#{user}> has #{counter} unstaged roles:")
        rmsg.push(temparr.join("\n"))
        e.channel.send_embed('', constructembed('BoomBot2.0 | roles', '0000ff', "<@#{user}>'s roles:\n#{rmsg.join("\n")}", e))
        msg = 'nil'
      end

      if msg.start_with?('roleadd', 'addrole')
        if $config[:permitted].any? { |o| e.user.roles.any? { |r| r.id == o.to_i } }
          txt = msg.sub('roleadd ', '').sub('addrole ', '').split(' ')
          user = txt.shift.sub('<@!', '').sub('<@', '').sub('>', '')
          if user.to_i == 0
            # When a user name got passed

            # Pseudo:
            # Download all server members
            # AutoCorrect through the list
            # Set user to the most corresponding ID

            # Copy-Paste from AutoCorrect for roles:
            # max = [0, 111, 'rolename']
            # e.server.roles.each do |r|
            # max = [r.name.similar(role), r.id, r.name] if r.name.similar(role) > max[0]
            # end

            usrmax = [0, 111, 'username']
            e.server.members.each do |m|
              usrmax = [m.display_name.similar(user), m.id, m.display_name] if m.display_name.similar(user) > usrmax[0]
            end
            user = usrmax[1]
          end
          $db[:"#{user.to_s}"] = User.new(user.to_i) if $db[:"#{user.to_s}"].nil?
          role = txt.shift
          max = [0, 111, 'rolename']
          e.server.roles.each do |r|
            max = [r.name.similar(role), r.id, r.name] if r.name.similar(role) > max[0]
          end
          e.server.member(user.to_i).add_role(e.server.role(max[1].to_i))
          e.channel.send_embed('', constructembed('BoomBot2.0 | roleadd', '00ff00', "The role `#{max[2]}` has been assigned to <@#{user}>. \n AutoCorrect: #{max[0]}%", e))
        else
          e.channel.send_embed('', constructembed('BoomBot2.0 | NO PERMISSION', 'ff0000', 'You\'re lacking permission to do that. If you believe this is an error, contact `admin@cubuzz.de`.', e))
        end
        msg = 'nil'
      end

      if msg.start_with?('rolerm', 'rmrole', 'removerole')
        if $config[:permitted].any? { |o| e.user.roles.any? { |r| r.id == o.to_i } }
          txt = msg.sub('rolerm ', '').sub('rmrole ', '').sub('removerole ', '').split(' ')
          user = txt.shift.sub('<@!', '').sub('<@', '').sub('>', '')

          if user.to_i == 0
            # When a user name got passed

            # Pseudo:
            # Download all server members
            # AutoCorrect through the list
            # Set user to the most corresponding ID

            # Copy-Paste from AutoCorrect for roles:
            # max = [0, 111, 'rolename']
            # e.server.roles.each do |r|
            # max = [r.name.similar(role), r.id, r.name] if r.name.similar(role) > max[0]
            # end

            usrmax = [0, 111, 'username']
            e.server.members.each do |m|
              usrmax = [m.display_name.similar(user), m.id, m.display_name] if m.display_name.similar(user) > usrmax[0]
            end
            user = usrmax[1]
          end

          $db[:"#{user.to_s}"] = User.new(user.to_i) if $db[:"#{user.to_s}"].nil?
          role = txt.shift
          max = [0, 111, 'rolename']
          e.server.roles.each do |r|
            max = [r.name.similar(role), r.id, r.name] if r.name.similar(role) > max[0]
          end
          e.server.member(user.to_i).remove_role(e.server.role(max[1].to_i))

          rmsg = []
          rmsg.push("The role `#{max[2]}` has been removed from <@#{user}>.")
          counter = 0

          userroles = $db[:"#{user.to_s}"].roles
          # binding.pry
          userroles.dup.each do |usercache|
            if usercache[1] == max[2] && usercache[0] == e.server.id
              $db[:"#{user.to_s}"].unrole(e.server.id, max[2])
              counter += 1
            end
          end

          if counter > 0
            rmsg.push("Additionally, #{counter} database records have been removed.")
          end

          e.channel.send_embed('', constructembed('BoomBot2.0 | rolerm', '00ff00', rmsg.join("\n").to_s, e))
        else
          e.channel.send_embed('', constructembed('BoomBot2.0 | NO PERMISSION', 'ff0000', 'You\'re lacking permission to do that. If you believe this is an error, contact `admin@cubuzz.de`.', e))
        end
        msg = 'nil'
      end

      if msg.start_with?('help')
        e.channel.send_embed('', constructembed('BoomBot2.0 | help', '0000ff', "The following commands are available:\n\n__**Everyone**__:\n`#{$prefix}ping` - This will attempt to calculate the pseudo-ping of the bot\n`#{$prefix}roles <@User>` - This will allow you to see which roles a user has. Alternatively supply with an ID instead of a tag.\n\n__**STAFF ONLY**__\n`#{$prefix}temprole <@User> <Role> <Time>` - Add a role temporarily to specified user. Default for time is days, use `h` in the time argument for hours\n`#{$prefix}permrole <@User> <Role>` - Add a role permanently to specified user. This role will stick with them even if they re-join the server.\n`#{$prefix}addrole <@User> <Role>` - *Alternatively `roleadd <@User> <role>`* Will add the specified role to specified user. Just a plain role.\n`#{$prefix}rmrole <@User> <Role>` - *Alternatively `rolerm <@User> <Role>` or `removerole <@User> <Role>`* Removes a role from specified user. Can be used to remove timed and permanent roles.\n**IMPORTANT: All role-commands come with an AutoCorrect feature to make life easier.**\n\n__**OWNER ONLY**__\n`brsetprefix <new prefix>` - Updates the prefix of the bot. Can only be used if you're permitted to do so in the manual config files.\n`#{$prefix}setgame <new game status>` - Updates the 'Playing'-Game. Use an `&` infront of the game to add it to a shuffled list, use the command without the & to set it.", e))
      end

      if msg.start_with?('setgame')
        if $config[:owner].any? { |o| o.to_i == e.user.id.to_i }
          msg = msg.sub('setgame ', '')
          if msg.start_with?('&')
            $games.push(msg.sub('&', ''))
          else
            $games = [msg]
          end
          File.open('games.txt', 'w') { |f| $games.each { |d| f.puts d } }
          e.channel.send_embed('', constructembed('BoomBot2.0 | SetGame', '00ff00', "The playing games list has been updated! It does now consist of the following:\n`#{YAML.dump $games}`", e))
        else
          e.respond "**PERMISSION ERROR!**\n\nI'm sorry, #{e.user.mention}, but you don't seem to be permitted to use recovery commands!"
        end
        msg = 'nil'
      end

      if msg.start_with?('rar')
        msg = msg.sub('rar ', '').sub('<@!', '').sub('<@', '').sub('>', '')
        if msg.to_i != 0
          user = msg.to_i
        elsif msg == ''
          user = e.user.id
        else
          user = msg
          # When a user name got passed

          # Pseudo:
          # Download all server members
          # AutoCorrect through the list
          # Set user to the most corresponding ID

          # Copy-Paste from AutoCorrect for roles:
          # max = [0, 111, 'rolename']
          # e.server.roles.each do |r|
          # max = [r.name.similar(role), r.id, r.name] if r.name.similar(role) > max[0]
          # end

          usrmax = [0, 111, 'username']
          e.server.members.each do |m|
            usrmax = [m.display_name.similar(user), m.id, m.display_name] if m.display_name.similar(user) > usrmax[0]
          end
          user = usrmax[1]

        end
        $db[:"#{user.to_s}"] = User.new(user.to_i) if $db[:"#{user.to_s}"].nil?

        $db[:"#{user.to_s}"].roles.each do |dbr|
          e.server.member(e.user.id).add_role(dbr[3]) if dbr[0] == e.server.id
        end
        e.channel.send_embed('', constructembed('BoomBot2.0 | Re-assign roles', '00ff00', "Re-Assigning the roles of <@#{user}> was successful!", e))
        msg = 'nil'
      end
      # # Created for role assignment test
      #     if msg.start_with?('tmr')
      #       msg = msg.sub('tmr ', '')
      #       msg = msg.sub('<@', '')
      #       msg = msg.sub('>', '')
      #       user = msg.to_i
      #       e.server.member(user).add_role(e.server.role($dbc[:test]))
      #     end

      ##
      # Disabled Reminder Feature. Requires rework.
      #     if msg.start_with?('remind')
      #       msg = msg.gsub('remind ', '')
      #       txt = msg.split(' ')
      #       time = txt.shift
      #       time = time.split(';')
      #       target = Time.now
      #       time.each do |t|
      #         if t.include?('s')
      #           target += t.to_i
      #         elsif t.include?('m')
      #           target += t.to_i * 60
      #         elsif t.include?('h')
      #           target += t.to_i * 60 * 60
      #         elsif t.include?('d')
      #           target += t.to_i * 60 * 60 * 24
      #         end
      #       end
      #       e.channel.send_embed('', constructembed('BoomBot2.0 | Reminder', '00ff00', "The reminder `#{txt.join(' ')}` has been set for #{Time.at(target).strftime('%c')}.", e))
      #       puts "DEBUG: Remind #{txt.join(' ')} at #{target}"
      #       $reminders.push([target, e.channel.id, txt.join(' ')])
      #       puts "DEBUG: $reminders = #{$reminders}"
      #     end
      raise 'Test error has been created!' if msg.start_with?('causeErrorFE')

      $backenderror = 1 if msg.start_with?('causeErrorBE')
    end
  rescue  => boomerror
    msg = []
    boomerror.backtrace.each do |msgp|
      msg.push "At: #{msgp}"
    end
    e.channel.send_embed('', constructembed('BOOMBOT2.0 | ERROR!', 'ff0000', "An error has occured. A bug report has been created and saved. Here's what happened: ```md\n#{boomerror.message}```Backtrace: ```md\n#{msg.join("\n")}```"))
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

# #Disable for security purposes
boom.message(start_with: 'brgrabroles') do |e|
  break unless $config[:owner].any? { |o| o.to_i == e.user.id.to_i }

  e.server.roles.each do |r|
    puts "Role name: #{r.name} | Role ID: #{r.id}"
  end
  # e.respond 'Please view console for details!'
end

boom.ready do
  puts "Connection successfully established! Let's get this bread!"
end

boom.member_join do |e|
  begin
    if $db[:"#{e.user.id.to_s}"].nil? # Database: Check whether user did join server already.
      $db[:"#{e.user.id.to_s}"] = User.new(e.user.id)
    end

    $db[:"#{e.user.id.to_s}"].roles.each do |dbr|
      e.server.member(e.user.id).add_role(dbr[3]) if dbr[0] == e.server.id
    end
  rescue => boomerror
    msg = []
    boomerror.backtrace.each do |msgp|
      msg.push "At: #{msgp}"
    end
    boom.server(489_866_634_849_157_120).channels.each do |ch|
      if ch.id == 516_194_712_248_385_546
        ch.send_embed('', constructembed('Backend Error!', 'ff0000', "An error has occured in the backend. Here's what happened: ```md\n#{boomerror.message}```Backtrace: ```md\n#{msg.join("\n")}```"))
      end
    end
  end
end

boom.run :async

sleep 5
puts 'Backend is now active.'
# runbar = ProgressBar.create title: 'Running!', total: nil, format: '%t |%b>>%i<<| %a'
loops = 0
$backenderror = 0
errstate = 0
loop do
  begin
    errstate = 'Game Loop...'
    if $backenderror == 1
      $backenderror = 0
      raise 'Yikes! Test Backend Error!'
    end

    loops += 1
    1.times do
      errstate = 'Setting game...'
      boom.game = $games.sample
      # 10.times { runbar.increment; sleep 1 }
      sleep 10
    end

    puts
    puts 'Updating...'
    errstate = 'Updating Database'
    uupdate = []
    $db.each do |_k, v|
      a = v.update
      uupdate.push(a) if a[0] != false
    end
    puts YAML.dump(uupdate)
    errstate = 'Updating each user...'
    uupdate.each do |g|
      userid = g[1]
      g[2].each do |r|
        errstate = "Updating #{YAML.dump g}"
        next if r == []

        r.each do |l|
          serverid = l[0]
          roleid = l[3]
          puts "DEBUG: RM #{roleid} on #{serverid} from #{userid}"
          boom.server(serverid).member(userid).remove_role(roleid)
        end
      end
    end

    # If we get here, there were no errors during the updating process
    $db.each { |_k, v| v.update! }

    errstate = 'Reminding you of stuff...'
    puts
    print 'Running reminder tasks...'

    $reminders.each do |r|
      # Formatting: [Time, e.channel.id, Message]
      next unless r[0] < Time.now

      puts "#{r} triggered!"
      boom.channel(r[1]).send_message("**REMINDER:** Hey there! A reminder has been set for #{r[0].strftime('%D, %r')}, which has just been acked: \n#{r[2]}")
      $reminders.delete(r)
    end
    errstate = 'Saving...'
    puts
    print 'Saving'
    File.open('userdb.yml', 'w') { |f| f.puts YAML.dump $db }
    File.open('reminders.yml', 'w') { |f| f.puts YAML.dump $reminders }
    puts '... Sucess!'

    if loops > 180
      puts 'Attempting to reassign roles to everyone...'
      $db.each do |_k, v|
        v.roles.each do |vrole|
          boom.server(vrole[0]).member(v.uid).add_role(vrole[3])
        end
      end
      puts 'Re-assigned roles!'
      loops = 0
    end
  rescue  => boomerror
    msg = []
    boomerror.backtrace.each do |msgp|
      msg.push "At: #{msgp}"
    end
    boom.server(489_866_634_849_157_120).channels.each do |ch|
      if ch.id == 516_194_712_248_385_546
        case boomerror.message
        when "A gateway connection is necessary to call this method! You'll have to do it inside any event (e.g. `ready`) or after `bot.run :async`."
          puts 'Failed updating game. Connection has been lost.'
        else
          ch.send_embed('', constructembed('Backend Error!', 'ff0000', "An error has occured in the backend. Here's what happened: ```md\n#{boomerror.message}```Backtrace: ```md\n#{msg.join("\n")}``` Errstate = #{errstate}"))
        end
      end
    end
    next
  end
end
