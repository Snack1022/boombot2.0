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
  end

  ##
  # Adds a role permanently to the user on specified server.
  # If the name parsed is invalid, BB20 will try to select the closest match.
  #
  # Stalemate resolval will be implemented on BB20's side.
  def permrole(serverid, name)
    @roles.push([serverid, name, 'perm'])
  end

  ##
  # Adds a role temporarily to the user on specified server.
  # If the name parsed is invalid, BB20 will try to select the closest match.
  #
  # Stalemate resolval will be implemented on BB20's side.
  def temprole(serverid, name, iDuration)
    iDuration = iDuration * 3600 + Time.now
    @roles.push([serverid, name, iDuration])
  end

  ##
  # Removes said role from specified server.
  # The role name needs to be accurate; BB20 will NOT look for the closest match when unroling (performance reasons)
  def unrole(serverid, name)
    @roles.each do |r|
      if r[1] == name && r[0] == serverid
        @roles.delete(r)
      end
    end
  end

  ##
  # DOC TODO:
  def tempban(serverid, iDuration)
    iDuration = iDuration * 3600 + Time.now
    @tempban.push([iDuration, serverid])
  end

  ##
  # DOC TODO:
  def roles()
    return @roles
  end

  ##
  # DOC TODO:
  def banstatus()
    return @tempban
  end

  ##
  # DOC TODO:
  def warn(msg, serverid)
    @warnings.push([Time.now.strftime("%d/%m/%Y"), msg, serverid, @warnings.length])
  end

  ##
  # DOC TODO:
  def getwarns(serverid)
    arr = []
    @warnings.each do |e|
      if e[2] == serverid
        arr.push e
      end
    end
    return arr
  end

  def undowarn(id)
    begin
      @warnings.delete_at(id)
    rescue
      return false
    end
    return true
  end

  ##
  # Updates the userdata. Returns true if userdata needs to be updated on server.
  def update
    requireupdate = false
    # Check Roles
    newr = []
    @roles.each do |r|
      if r[2] > Time.now || r[2] == 'perm'
        newr.push r
      end
    end
    if newr != @roles
      requireupdate = true 
      # Check what exactly changed, return later for performance optimization of bot.
    end
    @roles = newr

    # Check bans

    @tempban.each do |t|
      # Normally skip for performance reasons
      if t[0] < Time.now
        requireupdate = true
      end
    end

  return requireupdate
  end
end
