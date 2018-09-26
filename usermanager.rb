class User
  def initialize(id)
    @userid = id # For DB reasons
    @roles = []
    @tempban = [false, 0]
    @lastupdatestat = [@roles, @tempban]
    @warnings = []
  end

  def permrole(name)
    @roles.push([name, 'perm'])
  end

  def temprole(name, iDuration)
    iDuration = iDuration * 3600 + Time.now
    @roles.push([name, iDuration])
  end

  def unrole(name)
    @roles.each do |r|
      if r[0] == name
        @roles.delete(r)
      end
    end
  end

  def tempban(iDuration)
    iDuration = iDuration * 3600 + Time.now
    @tempban = [true, iDuration]
  end

  def roles()
    return @roles
  end

  def banstatus()
    return @tempban
  end

  def warn(msg)
    @warnings.push([Time.now, msg])
  end

  def getwarns
    return @warnings
  end

  def undowarn(id)
    begin
      @warnings.delete_at(id)
    rescue
      return false
    end
    return true
  end

  def update
    requireupdate = false
    # Check Roles
    newr = []
    @roles.each do |r|
      if r[1] > Time.now || r[1] == 'perm'
        newr.push
      end
    end
    requireupdate = true if newr != @roles
    @roles = newr

    # Check bans

    if @tempban[0] == true
      # Normally skip for performance reasons
      if @tempban[1] < Time.now
        requireupdate = true
        @tempban[0] = false
      end
    end

  return requireupdate
  end
end
