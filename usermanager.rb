##
# User-Class for BoomBot2.0
# Containing methods:
#
# Constructor:
#   #init(id) >> void
#
# Roles:
#   #permrole(int Server ID, str Role Name) >> void
#   #temprole(int Server ID, str Role Name) >> void
#   #unrole(int Server ID, str Role Name) >> void
#   #roles >> Array of Roles assigned in UDB
#
# Bans:
#   #tempban(int Server ID, int Duration (in hours)) >> void
#   #banstatus >> Array with formatting: [bannedUntil, serverIDofban]; could contain some outdated bans.
class User
  ##
  # Constructor. Requires User ID for DB.
  def initialize(id)
    @userid = id # For DB reasons
    @roles = []
    @tempban = []
    @lastupdatestat = [@roles, @tempban]
    @warnings = []
    @roles_rm = []
  end

  def ctime(input)
    if input == 'perm'
      Float::INFINITY
    else
      input.to_i
    end
  end

  ##
  # Adds a role permanently to the user on specified server.
  # If the name parsed is invalid, BB20 will try to select the closest match.
  #
  # Stalemate resolval will be implemented on BB20's side.
  def permrole(serverid, name, roleid)
    @roles.push([serverid, name, 'perm', roleid])
  end

  ##
  # Adds a role temporarily to the user on specified server.
  # If the name parsed is invalid, BB20 will try to select the closest match.
  #
  # Stalemate resolval will be implemented on BB20's side.
  def temprole(serverid, name, iDuration, roleid)
    iDuration = iDuration * 3600 + Time.now.to_i
    @roles.push([serverid, name, iDuration, roleid])
  end

  ##
  # Removes said role from specified server.
  # The role name needs to be accurate; BB20 will NOT look for the closest match when unroling (performance reasons)
  def unrole(serverid, name)
    @roles.each do |r|
      @roles.delete(r) if r[1] == name && r[0] == serverid
    end
  end

  ##
  # DOC TODO:
  def tempban(serverid, iDuration)
    iDuration = iDuration * 3600 + Time.now.to_i
    @tempban.push([iDuration, serverid])
  end

  ##
  # DOC TODO:
  attr_reader :roles

  def uid
    @userid
  end

  ##
  # DOC TODO:
  def banstatus
    @tempban
  end

  ##
  # DOC TODO:
  def warn(msg, serverid)
    @warnings.push([Time.now.strftime('%d/%m/%Y'), msg, serverid, @warnings.length])
  end

  ##
  # DOC TODO:
  def getwarns(serverid)
    arr = []
    @warnings.each do |e|
      arr.push e if e[2] == serverid
    end
    arr
  end

  def undowarn(id)
    begin
      @warnings.delete_at(id)
    rescue StandardError
      return false
    end
    true
  end

  ##
  # Updates the userdata. Returns true and list of changes if userdata needs to be updated on server.
  def update
    requireupdate = false
    update = [[], []]

    # Merge roles
    # [serverid, name, time, roleid]
    mr = []
    @roles.each do |r|
      if mr.any? { |a| a[3] == r[3] }
        mr.each do |a|
          # Select Obj
          next unless a[3] == r[3]
          next unless self.ctime(r[2]) > self.ctime(a[2])

          mr.delete(a)
          mr.push(r)
          # No else-Statement required as this will NEVER happen
        end
      else
        # Fast-FWD
        mr.push(r)
      end
    end
    @roles = mr

    # Update only contains 'remove'-instructions.
    @roles.each do |r|
      if self.ctime(r[2]) < Time.now.to_i
        update[0].push(r)
        @roles_rm.push(r)
        requireupdate = true
      end
    end

    # Check bans
    @tempban.each do |t|
      # Normally skip for performance reasons
      if t[0] < Time.now.to_i
        requireupdate = true
        update[1].push(t[1])
      end
    end

    [requireupdate, @userid, update]
  end

  def update!
    a = @roles.dup
    a.each do |r|
      if @roles_rm.any?{|rm| r == rm }
        @roles.delete(r)
      end
    end
  end

end
